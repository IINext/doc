"""H11 費用申請單（車馬費）。

對應 Home 專案：
    #1160 費用申請單（列表）、#1161 H11.費用申請單(H)（編輯）、#1162 H11.費用申請單(D)（明細）、
    #1163 費用申請送簽

資料存放（和舊系統相同）：
    FIL0030   異動單主檔（表頭；「匯率日期」借放帳款年月、「稅別」借放費用類別）
    FIL0040   異動單明細（一人一筆；「產品編號」借放申請人、「異動數量」借放金額、「備註說明」借放備註）

原程式的表頭畫面沒有備註欄位（備註只在清單顯示），這裡另外開放填寫，方便使用；見 README。
"""
from dataclasses import dataclass, field
from datetime import date, datetime
from decimal import Decimal, InvalidOperation

from flask import Blueprint, abort, current_app, flash, g, redirect, render_template, request, url_for

from . import db, edb, flow
from .auth import login_required
from .formdocs import STATUS_TEXT, closing_date
from .formdocs import is_doc_manager as _is_doc_manager
from .magic import add_months, from_date, to_date, to_time, utc_guid
from .numbering import next_doc_no

bp = Blueprint('expense', __name__, url_prefix='/hr/expense')

DOC_TYPE = 'H11'
DOC_NAME = '費用申請單'
CATEGORIES = {'1': '車馬費一', '2': '車馬費二'}                   # OL: IF(OK='1','車馬費一','車馬費二')

flow.register_form(DOC_TYPE, DOC_NAME, 'expense.edit')


def is_doc_manager(emp_no):
    return _is_doc_manager(DOC_TYPE, emp_no)


# ── 查詢 ────────────────────────────────────────────────────────


def load(no):
    return db.one('SELECT * FROM viewfilh023 WHERE "單別" = %s AND "單號" = %s', (DOC_TYPE, no))


def details(no):
    return db.query('SELECT * FROM viewfilh024 WHERE "單別" = %s AND "單號" = %s ORDER BY "序號"', (DOC_TYPE, no))


# ── 檢查、存檔 ──────────────────────────────────────────────────


@dataclass
class Row:
    applicant: str
    amount: str                                                # 存字串，檢查時再轉數字（讓錯誤訊息看得到原始輸入）
    note: str


@dataclass
class ExpenseForm:
    period: str                                                 # 帳款年月，'YYYY-MM'
    category: str
    note: str
    rows: list = field(default_factory=list)
    errors: list = field(default_factory=list)

    @classmethod
    def from_request(cls, form):
        applicants = form.getlist('applicant')
        amounts = form.getlist('amount')
        notes = form.getlist('note')
        rows = [Row(a.strip(), m.strip(), n.strip()) for a, m, n in zip(applicants, amounts, notes)
                if a.strip() or m.strip() or n.strip()]
        return cls(period=form.get('period', '').strip(), category=form.get('category', '').strip(),
                   note=form.get('header_note', '').strip(), rows=rows)


def check(f):
    """UE_ErrCheck + Add/Modify 的檢查。回傳 (帳款年月的日期, [(申請人, 金額 Decimal, 備註), ...])；有錯時放在 f.errors。"""
    try:
        period = date.fromisoformat(f.period + '-01')
    except ValueError:
        f.errors.append('請選擇帳款年月')
        period = None
    if f.category not in CATEGORIES:
        f.errors.append('請選擇費用類別')
    if period:
        close = closing_date()
        if close and period <= close:
            f.errors.append('已關帳,請修正帳款年月！')
    if not f.rows:
        f.errors.append('至少要有一筆明細')
    parsed = []
    for r in f.rows:
        emp = db.one('SELECT "員工編號" FROM fil0010 WHERE "員工編號" = %s', (r.applicant,)) if r.applicant else None
        if emp is None:
            f.errors.append(f'申請人錯誤：{r.applicant or "（空白）"}')
            continue
        try:
            amount = Decimal(r.amount)
        except InvalidOperation:
            f.errors.append(f'{r.applicant} 的金額請輸入數字')
            continue
        parsed.append((r.applicant, amount, r.note))
    if f.errors:
        return None, None
    return period, parsed


def check_editable(doc):
    if doc['簽核狀態'] > '0':
        return '已送簽,無法異動'
    close = closing_date()
    if close and to_date(doc['申請日期']) <= close:
        return '已關帳,不提供修改'
    if not can_edit(doc):
        return '非填表人'
    return None


def can_edit(doc):
    return doc['填表人'].strip() == g.user['員工編號'] or is_doc_manager(g.user['員工編號'])


def can_view(doc):
    """填表人、單據管理員、以及簽核流程上的人可以查看。"""
    if can_edit(doc):
        return True
    return db.one('SELECT 1 FROM a01_2 WHERE serial_num = %s AND (assignedto = %s OR signedby = %s)',
                  (doc['流水編號'], g.user['serial_num'], g.user['serial_num'])) is not None


def is_requester(doc):
    return g.user['員工編號'] == doc['填表人'].strip()


def flow_values(doc):
    return {'費用類別': doc['費用類別'].strip()}


def save(f, period, rows, doc=None):
    """寫入 FIL0030、FIL0040。回傳單號。"""
    user = g.user
    now = datetime.now()
    if doc is None:
        today = date.today()
        no = next_doc_no(DOC_TYPE, today, user['公司代碼'])
        serial = DOC_TYPE + utc_guid()
        app = current_app.config['SIGNING_APP_NAME']
        db.insert('fil0030', {
            '單據類別': DOC_TYPE, '單據編號': no, '單據日期': from_date(period), '公司代碼': user['公司代碼'],
            '簽核系統': f'{DOC_TYPE}.{app}', '簽核系統_結案': f'CLOSE.{DOC_TYPE}.{app}', '流水編號': serial,
            '填表人': user['員工編號'], '填表日': now, '部門編號': user['部門編號'],
            '匯率日期': from_date(period), '稅別': f.category, '備註': f.note or ' ',
            '最後更新者': user['員工編號'], '最後更新日': now})
    else:
        no, serial = doc['單號'], doc['流水編號']
        db.update('fil0030', {'匯率日期': from_date(period), '稅別': f.category, '備註': f.note or ' ',
                              '單據日期': from_date(period),
                              '最後更新者': user['員工編號'], '最後更新日': now},
                  '"單據類別" = %s AND "單據編號" = %s', (DOC_TYPE, no))
    db.execute('DELETE FROM fil0040 WHERE "單據類別" = %s AND "單據編號" = %s', (DOC_TYPE, no))
    for seq, (applicant, amount, note) in enumerate(rows, start=1):
        db.insert('fil0040', {'單據類別': DOC_TYPE, '單據編號': no, '單據序號': seq,
                              '產品編號': applicant, '異動數量': amount, '備註說明': note or ' ',
                              '流水編號': DOC_TYPE + utc_guid(),
                              '最後更新者': user['員工編號'], '最後更新日': now})
    return no


# ── 畫面 ────────────────────────────────────────────────────────


def _arg_date(name, default):
    try:
        return date.fromisoformat(request.args.get(name, ''))
    except ValueError:
        return default


@bp.route('/')
@login_required
def index():
    me = g.user['員工編號']
    manager = is_doc_manager(me)
    today = date.today()
    date_from = _arg_date('date_from', add_months(today, -1))
    date_to = _arg_date('date_to', today)
    sql = ["""SELECT h.*, coalesce(t."金額", 0) AS "合計金額" FROM viewfilh023 h
             LEFT JOIN viewfilh025 t ON t."單別" = h."單別" AND t."單號" = h."單號"
             WHERE h."申請日期" BETWEEN %s AND %s"""]
    params = [from_date(date_from), from_date(date_to)]
    if request.args.get('no'):
        sql.append('AND h."單號" LIKE %s')
        params.append(request.args['no'].strip() + '%')
    if request.args.get('status'):
        sql.append('AND h."簽核狀態" = %s')
        params.append(request.args['status'])
    if not manager:
        sql.append("""AND (h."填表人" = %s OR EXISTS (
                          SELECT 1 FROM a01_2 f WHERE f.serial_num = h."流水編號"
                          AND (f.assignedto = %s OR f.signedby = %s)))""")
        params += [me, g.user['serial_num'], g.user['serial_num']]
    rows = db.query(' '.join(sql) + ' ORDER BY h."單號" DESC LIMIT 500', params)
    return render_template('expense/index.html', rows=rows, status_text=STATUS_TEXT, date_from=date_from,
                           date_to=date_to, to_date=to_date, categories=CATEGORIES)


def _render_form(f, doc=None, rows=None):
    editable = doc is None or check_editable(doc) is None
    flow_info = {}
    if doc is not None:
        me = g.user['serial_num']
        status = doc['簽核狀態']
        flow_info = {
            'history': edb.history(doc['流水編號']),
            'my_turn': edb.my_turn(doc['流水編號'], me),
            'can_cancel_reject': edb.cancelable_reject(doc['流水編號'], me) is not None,
            'can_withdraw': status in ('I', 'D') and is_requester(doc),
            'can_void': status in ('I', 'D') and is_requester(doc),
        }
    return render_template('expense/form.html', f=f, doc=doc, rows=rows or [], editable=editable,
                           categories=CATEGORIES, flow=flow_info, result_text={'0': '未簽', '1': '同意', '2': '退回'},
                           to_date=to_date, to_time=to_time, status_text=STATUS_TEXT)


@bp.route('/new', methods=('GET', 'POST'))
@login_required
def create():
    if request.method == 'GET':
        f = ExpenseForm(period=date.today().strftime('%Y-%m'), category='1', note='', rows=[Row('', '', '')])
        return _render_form(f)
    f = ExpenseForm.from_request(request.form)
    period, rows = check(f)
    if f.errors:
        for e in f.errors:
            flash(e, 'danger')
        return _render_form(f)
    no = save(f, period, rows)
    db.commit()
    flash(f'已存檔 {no}', 'success')
    return redirect(url_for('expense.edit', no=no))


@bp.route('/<no>', methods=('GET', 'POST'))
@login_required
def edit(no):
    doc = load(no)
    if doc is None or not can_view(doc):
        abort(404)
    if request.method == 'GET':
        rows = details(no)
        f = ExpenseForm(period=to_date(doc['申請日期']).strftime('%Y-%m'), category=doc['費用類別'].strip(),
                        note=doc['備註'].strip(), rows=[Row(r['申請人'].strip(), '%g' % r['金額'], r['備註'].strip())
                                                       for r in rows] or [Row('', '', '')])
        return _render_form(f, doc=doc, rows=rows)
    error = check_editable(doc)
    if error:
        flash(error, 'danger')
        return redirect(url_for('expense.edit', no=no))
    f = ExpenseForm.from_request(request.form)
    period, rows = check(f)
    if f.errors:
        for e in f.errors:
            flash(e, 'danger')
        return _render_form(f, doc=doc, rows=details(no))
    save(f, period, rows, doc=doc)
    db.commit()
    flash(f'已存檔 {no}', 'success')
    return redirect(url_for('expense.edit', no=no))


@bp.route('/<no>/delete', methods=('POST',))
@login_required
def delete(no):
    doc = load(no)
    if doc is None or not can_view(doc):
        abort(404)
    error = check_editable(doc)
    if error:
        flash(error, 'danger')
        return redirect(url_for('expense.edit', no=no))
    db.execute('DELETE FROM fil0040 WHERE "單據類別" = %s AND "單據編號" = %s', (DOC_TYPE, no))
    db.execute('DELETE FROM fil0030 WHERE "單據類別" = %s AND "單據編號" = %s', (DOC_TYPE, no))
    db.commit()
    flash(f'已刪除 {no}', 'success')
    return redirect(url_for('expense.index'))


@bp.route('/<no>/submit', methods=('POST',))
@login_required
def submit(no):
    doc = load(no)
    if doc is None:
        abort(404)
    error = None
    if doc['填表人'].strip() != g.user['員工編號']:
        error = '非填表人無法送簽'
    elif edb.flow_status(doc['流水編號']) > '0':
        error = '已送簽,無法異動'
    if error:
        flash(error, 'danger')
        return redirect(url_for('expense.edit', no=no))

    serial = doc['流水編號']
    edb.create_object(serial, doc['主旨'], g.user['serial_num'])
    try:
        ok, messages = edb.submit(serial, signing_category=doc['費用類別'].strip(), values=flow_values(doc))
    except edb.EdbError as e:
        db.get_db().rollback()
        flash(str(e), 'danger')
        return redirect(url_for('expense.edit', no=no))
    if ok:
        db.commit()
        flash('已送簽', 'success')
    else:
        db.get_db().rollback()
    for m in messages:
        flash(m, 'warning' if ok else 'danger')
    return redirect(url_for('expense.edit', no=no))


def _flow_action(no, action, done_message):
    doc = load(no)
    if doc is None or not can_view(doc):
        abort(404)
    try:
        result = action(doc)
    except edb.EdbError as e:
        db.get_db().rollback()
        flash(str(e), 'danger')
        return redirect(url_for('expense.edit', no=no))
    db.commit()
    flash(done_message(result) if callable(done_message) else done_message, 'success')
    return redirect(url_for('expense.edit', no=no))


@bp.route('/<no>/approve', methods=('POST',))
@login_required
def approve(no):
    return _flow_action(
        no, lambda doc: edb.approve(doc['流水編號'], g.user['serial_num'], request.form.get('comment', ''),
                                    values=flow_values(doc), add_signer=request.form.get('add_signer', '')),
        lambda status: '已同意，簽核完成' if status == 'E' else '已同意')


@bp.route('/<no>/reject', methods=('POST',))
@login_required
def reject(no):
    return _flow_action(no, lambda doc: edb.reject(doc['流水編號'], g.user['serial_num'],
                                                   request.form.get('reason', '')), '已退回')


@bp.route('/<no>/hold', methods=('POST',))
@login_required
def hold(no):
    return _flow_action(no, lambda doc: edb.hold(doc['流水編號'], g.user['serial_num']), '已歸入待處理')


@bp.route('/<no>/cancel-reject', methods=('POST',))
@login_required
def cancel_reject(no):
    return _flow_action(no, lambda doc: edb.cancel_reject(doc['流水編號'], g.user['serial_num']),
                        '已取消退回，單據回到簽核中')


@bp.route('/<no>/withdraw', methods=('POST',))
@login_required
def withdraw(no):
    return _flow_action(no, lambda doc: edb.withdraw(doc['流水編號'], g.user['serial_num']), '已取回，可以修改後重新送簽')


@bp.route('/<no>/void', methods=('POST',))
@login_required
def void(no):
    return _flow_action(no, lambda doc: edb.void(doc['流水編號'], g.user['serial_num']), '已作廢')

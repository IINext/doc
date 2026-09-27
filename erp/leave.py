"""H01 請假申請單。

對應 Home 專案：
    #1122 請假申請單（列表）、#1123 H01.請假申請單(H)（編輯）、#1124 H01.請假明細(D)、
    #1125 預排特休檢查、#1126 請假單送簽、#1128 檢查是否超時

資料存放（和舊系統相同，新舊系統可以並行）：
    FIL0030   異動單主檔（表頭；「折讓」欄位借放第一天的請假時數）
    HRFIL1031 請假單
    FIL0040   異動單明細（每日一筆；異動數量 = 時數、TIME1 = 起始時間）
舊系統借用欄位存資料：FIL0010.party = 班別代碼、FIL0010.possition = 性別。
"""
from dataclasses import dataclass, field
from datetime import date, datetime, time, timedelta
from decimal import Decimal, InvalidOperation

from flask import Blueprint, abort, current_app, flash, g, redirect, render_template, request, url_for

from . import db, edb, flow
from .auth import login_required
from .formdocs import closing_date, is_doc_manager as _is_doc_manager
from .leave_rules import (Shift, allowed_hours, first_day_and_end, min_hours_message, plan_details,
                          time_errors)
from .magic import add_months, from_date, from_time, to_date, to_time, utc_guid
from .numbering import next_doc_no

bp = Blueprint('leave', __name__, url_prefix='/hr/leave')

DOC_TYPE = 'H01'
DOC_NAME = '請假卡'
ANNUAL_LEAVE = '08'           # Main Program：G_特休假代碼
MONTHS = ['一月', '二月', '三月', '四月', '五月', '六月', '七月', '八月', '九月', '十月', '十一月', '十二月']
STATUS_TEXT = {'I': '簽核中', 'E': '已簽', 'D': '退回', 'A': '作廢'}   # GFn_SignedStatusCHN，其他是草稿

flow.register_form(DOC_TYPE, DOC_NAME, 'leave.edit')


def _sec(t):
    return t.hour * 3600 + t.minute * 60 + t.second


def _time(sec):
    sec %= 86400
    return time(sec // 3600, sec % 3600 // 60, sec % 60)


# ── 查詢 ────────────────────────────────────────────────────────


def is_doc_manager(emp_no):
    return _is_doc_manager(DOC_TYPE, emp_no)


def leave_types():
    return db.query('SELECT * FROM viewfil3801 ORDER BY "代碼"')


def employee_info(emp_no):
    return db.one("""SELECT e."員工編號", e."員工姓名", e.serial_num, e."部門編號", e."公司代碼",
                            e.party AS "班別代碼", e.possition AS "性別",
                            s."上班起時", s."上班迄時", s."休息起時", s."休息迄時"
                     FROM fil0010 e LEFT JOIN fil0025 s ON s."代碼" = e.party
                     WHERE e."員工編號" = %s""", (emp_no,))


def shift_of(emp):
    if not emp or emp['上班起時'] is None:
        return None
    return Shift(*(_sec(to_time(emp[k])) for k in ('上班起時', '上班迄時', '休息起時', '休息迄時')))


def next_workday(d, include_holidays):
    """「取下一個日期」：行事曆（ViewFIL3805）中 d 當天或之後第一天；
    假別不含假日時只取「休假」為 0～1 的日子。行事曆沒有資料時沿用 d（和原程式相同）。"""
    sql = 'SELECT "日期" FROM viewfil3805 WHERE "日期" >= %s'
    if not include_holidays:
        sql += ' AND "休假" BETWEEN 0 AND 1'
    found = db.scalar(sql + ' ORDER BY "日期" LIMIT 1', (from_date(d),))
    return to_date(found) or d


def load(no):
    return db.one('SELECT * FROM viewfilh001 WHERE "單別" = %s AND "單號" = %s', (DOC_TYPE, no))


def details(no):
    return db.query("""SELECT "單據序號", "異動日期", "異動數量", time1 FROM fil0040
                       WHERE "單據類別" = %s AND "單據編號" = %s ORDER BY "單據序號" """, (DOC_TYPE, no))


def signing_category(emp):
    """簽核類別：個人（FIL0010A）沒有設定時用部門的。"""
    personal = db.scalar('SELECT "請假" FROM fil0010a WHERE "流水編號" = %s', (emp['serial_num'],))
    if personal and personal.strip():
        return personal.strip()
    dept = db.scalar("""SELECT a."請假" FROM viewfil0012 d JOIN fil0010a a ON a."流水編號" = d."流水編號"
                        WHERE d."部門編號" = %s""", (emp['部門編號'],))
    return (dept or '').strip()


def overtime_day(applicant, start, end):
    """#1128 檢查是否超時：期間內某天請假（含未核准）超過 8 小時。"""
    return db.one("""SELECT "異動日期", "請假時數" FROM viewfilh012a
                     WHERE "申請人" = %s AND "異動日期" BETWEEN %s AND %s AND "請假時數" >= 8.1
                     ORDER BY "異動日期" LIMIT 1""", (applicant, from_date(start), from_date(end)))


# ── 表單 ────────────────────────────────────────────────────────


@dataclass
class LeaveForm:
    applicant: str = ''
    leave_type: str = ''
    start_date: date = None
    start_time: time = None
    days: int = 0
    hours: Decimal = Decimal(0)
    agent: str = ''
    reason: str = ''
    errors: list = field(default_factory=list)

    @classmethod
    def from_request(cls, form):
        f = cls(applicant=form.get('applicant', '').strip().upper(), leave_type=form.get('leave_type', '').strip(),
                agent=form.get('agent', '').strip().upper(), reason=form.get('reason', '').strip())
        try:
            f.start_date = date.fromisoformat(form.get('start_date', ''))
        except ValueError:
            f.errors.append('起始日期格式錯誤')
        try:
            f.start_time = time.fromisoformat(form.get('start_time', ''))
        except ValueError:
            f.errors.append('起始時間格式錯誤')
        try:
            f.days = int(form.get('days') or 0)
            f.hours = Decimal(form.get('hours') or 0)
            if f.days < 0 or f.hours < 0:
                raise ValueError
        except (ValueError, InvalidOperation):
            f.errors.append('天數、時數格式錯誤')
        return f

    @classmethod
    def from_record(cls, r):
        return cls(applicant=r['申請人'].strip(), leave_type=r['請假假別'].strip(), start_date=to_date(r['起始日期']),
                   start_time=to_time(r['起始時間']), days=r['天數'], hours=Decimal(r['時數']),
                   agent=r['代理人'].strip(), reason=(r['請假事由'] or '').strip())

    @property
    def total(self):
        return self.days * 8 + self.hours


@dataclass
class Plan:
    """檢查通過後要寫入的內容。"""
    applicant: dict
    first_day_hours: Decimal
    end_date: date
    end_time: int
    rows: list
    warnings: list


def check(f, doc_no=None):
    """UE_ErrCheck + GUE_ErrCheck 中存檔前能檢查的規則。回傳 Plan；有錯誤時放在 f.errors。"""
    if f.errors:
        return None
    applicant = employee_info(f.applicant) if f.applicant else None
    if applicant is None:
        f.errors.append('申請人錯誤')
    kind = next((t for t in leave_types() if t['代碼'].strip() == f.leave_type), None)
    if kind is None:
        f.errors.append('選擇假別')
    if f.errors:
        return None
    shift = shift_of(applicant)
    if shift is None:
        f.errors.append('申請人沒有設定班別')
        return None

    start = _sec(f.start_time)
    first, end_time = first_day_and_end(start, f.days, f.hours, shift)
    rows, end_date = plan_details(f.start_date, start, f.days, f.hours, first, shift,
                                  lambda d: next_workday(d, bool(kind['天數含假日'])))
    errors = f.errors
    close = closing_date()
    if close and f.start_date <= close:
        errors.append('已關帳,請修正請假日期！')
    errors += time_errors(start, end_time, shift)
    if f.total == 0:
        errors.append('輸入請假時數')
    if f.hours not in allowed_hours(Decimal(kind['至少小時'])) and f.hours != 0:
        errors.append('時數不符合假別的最小單位')
    if kind['事由必打'] and not f.reason:
        errors.append('輸入請假事由')
    if f.total < Decimal(kind['至少小時']):
        errors.append(min_hours_message(kind['名稱'], kind['至少小時']))
    # 年度已核准時數 + 本次，超過假別的年度限請天數
    limit = Decimal(kind['年度限請天數'])
    if limit:
        used = db.scalar("""SELECT coalesce(sum("請假時數"), 0) FROM viewfilh011
                            WHERE "年度" = %s AND "申請人" = %s AND "假別" = %s""",
                         (str(f.start_date.year), f.applicant, f.leave_type))
        if (Decimal(used) + f.total) / 8 > limit:
            errors.append('請假天數超過法定天數')
    today = date.today()
    if f.start_date < today - timedelta(days=5):
        errors.append('起始日期必須是五天內')
    if end_date > add_months(today, 12):
        errors.append('截止日期必須是一年內')
    if f.leave_type == ANNUAL_LEAVE:                           # #1125 預排特休檢查
        errors += annual_leave_errors(f.applicant, rows)
    warnings = []
    if kind['名稱'].strip() == '調補':
        warnings += compensatory_warnings(f.applicant, f.leave_type, rows, doc_no)
    if errors:
        return None
    return Plan(applicant, first, end_date, end_time, rows, warnings)


def annual_leave_errors(applicant, rows):
    """特休：每個月請的時數不能超過員工排休表（ViewFILH003）該月的天數 × 8。

    原程式是用上一次存檔的明細檢查（第一次存檔時沒有明細就不會檢查）；這裡用這次要寫入的明細。
    """
    errors = []
    by_month = {}
    for r in rows:
        by_month.setdefault(r['日期'].strftime('%Y%m'), Decimal(0))
        by_month[r['日期'].strftime('%Y%m')] += r['時數']
    for ym, hours in sorted(by_month.items()):
        col = MONTHS[int(ym[4:]) - 1]
        planned = db.scalar(f'SELECT "{col}" FROM viewfilh003 WHERE "申請人" = %s AND "年度" = %s LIMIT 1',
                            (applicant, int(ym[:4]))) or 0
        if hours > Decimal(planned) * 8:
            errors.append(f'{ym}請假時數:{hours:.1f}小時>預排時數:{Decimal(planned) * 8:.1f}小時')
    return errors


def compensatory_warnings(applicant, leave_type, rows, doc_no):
    """調補：本月請假時數超過本月加班可調補時數時提醒（不擋存檔）。"""
    month = rows[0]['日期'].strftime('%Y%m') if rows else None
    if not month:
        return []
    used = db.scalar("""SELECT coalesce(sum(d."異動數量"), 0) FROM fil0040 d
                        JOIN hrfil1031 h ON h."單別" = d."單據類別" AND h."單號" = d."單據編號"
                        WHERE d."單據類別" = %s AND h."申請人" = %s AND h."假別" = %s
                          AND substr(d."異動日期", 1, 6) = %s AND d."單據編號" <> %s""",
                     (DOC_TYPE, applicant, leave_type, month, doc_no or ''))
    available = db.scalar('SELECT "調補時數" FROM viewfilh017 WHERE "申請人" = %s AND "加班年月" = %s',
                          (applicant, month)) or 0
    mine = sum((r['時數'] for r in rows if r['日期'].strftime('%Y%m') == month), Decimal(0))
    return ['本月加班時數不足調補'] if Decimal(used) + mine > Decimal(available) else []


def save(f, plan, doc=None):
    """寫入 FIL0030、HRFIL1031、FIL0040。回傳單號。"""
    user = g.user
    now = datetime.now()
    if doc is None:
        today = date.today()
        no = next_doc_no(DOC_TYPE, today, user['公司代碼'])
        serial = DOC_TYPE + utc_guid()
        app = current_app.config['SIGNING_APP_NAME']
        db.insert('fil0030', {
            '單據類別': DOC_TYPE, '單據編號': no, '單據日期': from_date(today), '公司代碼': user['公司代碼'],
            '簽核系統': f'{DOC_TYPE}.{app}', '簽核系統_結案': f'CLOSE.{DOC_TYPE}.{app}', '流水編號': serial,
            '填表人': user['員工編號'], '填表日': now, '部門編號': plan.applicant['部門編號'],
            '折讓': plan.first_day_hours, '最後更新者': user['員工編號'], '最後更新日': now})
        db.insert('hrfil1031', {'流水編號': serial, '單別': DOC_TYPE, '單號': no, '填寫人': user['員工編號'],
                                '填寫日期': from_date(today)})
    else:
        no, serial = doc['單號'], doc['流水編號']
        db.update('fil0030', {'部門編號': plan.applicant['部門編號'], '折讓': plan.first_day_hours,
                              '最後更新者': user['員工編號'], '最後更新日': now},
                  '"單據類別" = %s AND "單據編號" = %s', (DOC_TYPE, no))
    db.update('hrfil1031', {
        '申請人': f.applicant, '請假假別': f.leave_type, '假別': f.leave_type,
        '起始日期': from_date(f.start_date), '起始時間': from_time(f.start_time),
        '截止日期': from_date(plan.end_date), '截止時間': from_time(_time(plan.end_time)),
        '天數': f.days, '時數': f.hours, '代理人': f.agent or ' ', '請假事由': f.reason},
        '"流水編號" = %s', (serial,))
    db.execute('DELETE FROM fil0040 WHERE "單據類別" = %s AND "單據編號" = %s', (DOC_TYPE, no))
    for r in plan.rows:
        db.insert('fil0040', {'單據類別': DOC_TYPE, '單據編號': no, '單據序號': r['序號'],
                              '異動日期': from_date(r['日期']), '異動數量': r['時數'],
                              'time1': from_time(_time(r['起始時間'])), '最後更新者': user['員工編號'],
                              '最後更新日': now})
    # 寫入後才能檢查的規則（GUE_ErrCheck）
    over = overtime_day(f.applicant, f.start_date, plan.end_date)
    if over:
        f.errors.append(f'當日請假超過8小時:{to_date(over["異動日期"]):%Y/%m/%d},共請假:{over["請假時數"]:g}小時')
    split = db.scalar('SELECT "請假時數" FROM viewfilh013 WHERE "單據編號" = %s', (no,)) or 0
    if Decimal(split) != f.total:
        f.errors.append('請假時數與分拆時不合')
    return no


def can_view(doc):
    """填寫人、申請人、單據管理員、以及簽核流程上的人可以查看（原程式 V_合乎條件）。"""
    me = g.user['員工編號']
    if can_edit(doc) or doc['申請人'].strip() == me:
        return True
    return db.one('SELECT 1 FROM a01_2 WHERE serial_num = %s AND (assignedto = %s OR signedby = %s)',
                  (doc['流水編號'], g.user['serial_num'], g.user['serial_num'])) is not None


def can_edit(doc):
    return doc['填寫人'].strip() == g.user['員工編號'] or is_doc_manager(g.user['員工編號'])


def check_editable(doc):
    if doc['簽核狀態'] == 'D':
        return '已退回，請先取回修正'
    if doc['簽核狀態'] > '0':
        return '已送簽,無法異動'
    close = closing_date()
    if close and (to_date(doc['填寫日期']) <= close or to_date(doc['起始日期']) <= close):
        return '已關帳,不提供修改'
    if not can_edit(doc):
        return '非填表人'
    return None


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
    date_from = _arg_date('date_from', add_months(today, -1))   # 原程式預設查一個月內
    date_to = _arg_date('date_to', today)
    sql = ['SELECT * FROM viewfilh001 WHERE "填寫日期" BETWEEN %s AND %s']
    params = [from_date(date_from), from_date(date_to)]
    if request.args.get('no'):
        sql.append('AND "單號" LIKE %s')
        params.append(request.args['no'].strip() + '%')
    if request.args.get('status'):
        sql.append('AND "簽核狀態" = %s')
        params.append(request.args['status'])
    if not manager:           # 填寫人、申請人、或簽核過這張單的人
        sql.append("""AND ("填寫人" = %s OR "申請人" = %s OR EXISTS (
                          SELECT 1 FROM a01_2 f WHERE f.serial_num = viewfilh001."流水編號"
                          AND (f.assignedto = %s OR f.signedby = %s)))""")
        params += [me, me, g.user['serial_num'], g.user['serial_num']]
    rows = db.query(' '.join(sql) + ' ORDER BY "單號" DESC LIMIT 500', params)
    return render_template('leave/index.html', rows=rows, status_text=STATUS_TEXT, date_from=date_from,
                           date_to=date_to, to_date=to_date, to_time=to_time)


def _render_form(f, doc=None, rows=None):
    kinds = leave_types()
    editable = doc is None or check_editable(doc) is None
    flow_info = {}
    if doc is not None:
        me = g.user['serial_num']
        status = doc['簽核狀態']
        flow_info = {
            'history': edb.history(doc['流水編號']),
            'my_turn': edb.my_turn(doc['流水編號'], me),
            'can_cancel_reject': edb.cancelable_reject(doc['流水編號'], me) is not None,
            # 開單人或申請人：簽核中、退回可以取回修正；還沒結案可以作廢
            'can_withdraw': status in ('I', 'D') and is_requester(doc),
            'can_void': status in ('I', 'D') and is_requester(doc),
        }
    return render_template('leave/form.html', f=f, doc=doc, kinds=kinds, rows=rows or [], editable=editable,
                           flow=flow_info, result_text={'0': '未簽', '1': '同意', '2': '退回'},
                           hour_options={k['代碼'].strip(): [str(h) for h in allowed_hours(Decimal(k['至少小時']))]
                                         for k in kinds},
                           to_date=to_date, to_time=to_time, status_text=STATUS_TEXT)


@bp.route('/new', methods=('GET', 'POST'))
@login_required
def create():
    if request.method == 'GET':
        now = datetime.now()
        return _render_form(LeaveForm(applicant=g.user['員工編號'], start_date=now.date(), start_time=time(8, 0)))
    f = LeaveForm.from_request(request.form)
    plan = check(f)
    if plan:
        no = save(f, plan)
        if not f.errors:
            db.commit()
            for w in plan.warnings:
                flash(w, 'warning')
            flash('存檔完成', 'success')
            return redirect(url_for('leave.edit', no=no))
        db.get_db().rollback()
    for e in f.errors:
        flash(e, 'danger')
    return _render_form(f)


@bp.route('/<no>', methods=('GET', 'POST'))
@login_required
def edit(no):
    doc = load(no)
    if doc is None or not can_view(doc):
        abort(404)
    if request.method == 'POST':
        error = check_editable(doc)
        f = LeaveForm.from_request(request.form)
        if error:
            f.errors.append(error)
            plan = None
        else:
            plan = check(f, no)
        if plan:
            save(f, plan, doc)
            if not f.errors:
                db.commit()
                for w in plan.warnings:
                    flash(w, 'warning')
                flash('存檔完成', 'success')
                return redirect(url_for('leave.edit', no=no))
            db.get_db().rollback()
        for e in f.errors:
            flash(e, 'danger')
        return _render_form(f, doc, details(no))
    return _render_form(LeaveForm.from_record(doc), doc, details(no))


@bp.route('/<no>/delete', methods=('POST',))
@login_required
def delete(no):
    doc = load(no)
    if doc is None:
        abort(404)
    if doc['簽核狀態'] > '0':
        flash('已送簽,無法異動', 'danger')
    elif not can_edit(doc):
        flash('非填表人', 'danger')
    else:
        db.execute('DELETE FROM fil0040 WHERE "單據類別" = %s AND "單據編號" = %s', (DOC_TYPE, no))
        db.execute('DELETE FROM hrfil1031 WHERE "流水編號" = %s', (doc['流水編號'],))
        db.execute('DELETE FROM fil0030 WHERE "單據類別" = %s AND "單據編號" = %s', (DOC_TYPE, no))
        for table in ('a01_2', 'a01_3', 'a01_4', 'a01'):
            db.execute(f'DELETE FROM {table} WHERE serial_num = %s', (doc['流水編號'],))
        db.commit()
        flash(f'已刪除 {no}', 'success')
        return redirect(url_for('leave.index'))
    return redirect(url_for('leave.edit', no=no))


def flow_values(doc):
    """流程節點的條件可以用的欄位（原程式用 VarCurrN 依名稱從畫面上取值）。"""
    return {'假別': doc['假別'].strip(), '請假假別': doc['請假假別'].strip(), '天數': doc['天數'],
            '時數': doc['時數'], '請假時數': doc['請假時數'], '部門編號': doc['部門編號'].strip(),
            '申請人': doc['申請人'].strip(), '填寫人': doc['填寫人'].strip(),
            '簽核類別': signing_category(employee_info(doc['申請人'].strip()))}


def is_requester(doc):
    """開單人（填寫人）或申請人。"""
    return g.user['員工編號'] in (doc['填寫人'].strip(), doc['申請人'].strip())


@bp.route('/<no>/submit', methods=('POST',))
@login_required
def submit(no):
    """#1126 請假單送簽 + Main Program 的 GUE_送簽。"""
    doc = load(no)
    if doc is None:
        abort(404)
    error = None
    start, end = to_date(doc['起始日期']), to_date(doc['截止日期'])
    over = overtime_day(doc['申請人'], start, end)
    if over:
        error = f'無法送簽:{to_date(over["異動日期"]):%Y/%m/%d}請假超時,共{over["請假時數"]:g}小時'
    elif doc['填寫人'].strip() != g.user['員工編號']:
        error = '非填表人無法送簽'
    elif Decimal(doc['請假時數']) != Decimal(doc['每日時數合計']):
        error = '每日時數合計與請假時數不符'
    elif edb.flow_status(doc['流水編號']) > '0':
        error = '單據已送簽,無法異動 !!'
    if error:
        flash(error, 'danger')
        return redirect(url_for('leave.edit', no=no))

    applicant = employee_info(doc['申請人'].strip())
    serial = doc['流水編號']
    edb.create_object(serial, doc['主旨'], g.user['serial_num'], applicant['serial_num'])
    try:
        ok, messages = edb.submit(serial, signing_category=signing_category(applicant), values=flow_values(doc))
    except edb.EdbError as e:
        db.get_db().rollback()
        flash(str(e), 'danger')
        return redirect(url_for('leave.edit', no=no))
    if ok:
        db.commit()
        flash('已送簽', 'success')
    else:
        db.get_db().rollback()
    for m in messages:
        flash(m, 'warning' if ok else 'danger')
    return redirect(url_for('leave.edit', no=no))


def _flow_action(no, action, done_message):
    """簽核動作的共用流程：找單、執行、commit；EdbError 時回復並顯示訊息。"""
    doc = load(no)
    if doc is None or not can_view(doc):
        abort(404)
    try:
        result = action(doc)
    except edb.EdbError as e:
        db.get_db().rollback()
        flash(str(e), 'danger')
        return redirect(url_for('leave.edit', no=no))
    db.commit()
    flash(done_message(result) if callable(done_message) else done_message, 'success')
    return redirect(url_for('leave.edit', no=no))


@bp.route('/<no>/approve', methods=('POST',))
@login_required
def approve(no):
    """同意（Home #94 WorkflowSign），可以同時加簽。"""
    return _flow_action(
        no, lambda doc: edb.approve(doc['流水編號'], g.user['serial_num'], request.form.get('comment', ''),
                                    values=flow_values(doc), add_signer=request.form.get('add_signer', '')),
        lambda status: '已同意，簽核完成' if status == 'E' else '已同意')


@bp.route('/<no>/reject', methods=('POST',))
@login_required
def reject(no):
    """退回（Home #94 WorkflowDrawback），通知開單人。"""
    return _flow_action(no, lambda doc: edb.reject(doc['流水編號'], g.user['serial_num'],
                                                   request.form.get('reason', '')), '已退回')


@bp.route('/<no>/hold', methods=('POST',))
@login_required
def hold(no):
    """歸入待處理（Home #94 WorkflowHold）。"""
    return _flow_action(no, lambda doc: edb.hold(doc['流水編號'], g.user['serial_num']), '已歸入待處理')


@bp.route('/<no>/cancel-reject', methods=('POST',))
@login_required
def cancel_reject(no):
    """取消退回（Home #94 WorkflowCancelDB），只有退回的人可以執行。"""
    return _flow_action(no, lambda doc: edb.cancel_reject(doc['流水編號'], g.user['serial_num']),
                        '已取消退回，單據回到簽核中')


@bp.route('/<no>/withdraw', methods=('POST',))
@login_required
def withdraw(no):
    """取回修正：刪除簽核流程、回到草稿，修改後可以重新送簽。"""
    return _flow_action(no, lambda doc: edb.withdraw(doc['流水編號'], g.user['serial_num']), '已取回，可以修改後重新送簽')


@bp.route('/<no>/void', methods=('POST',))
@login_required
def void(no):
    """作廢。"""
    return _flow_action(no, lambda doc: edb.void(doc['流水編號'], g.user['serial_num']), '已作廢')

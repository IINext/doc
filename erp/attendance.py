"""H05 出勤調整單：人資直接登打、存檔即核定的請假／扣薪紀錄。

對應 Home 專案：#1158 出勤調整單（列表）、#1159 H05.出勤調整單(H)

和 H01 請假申請單共用同一張假別代碼、同一張 HRFIL1031（請假單）、同一張 FIL0040 明細
（單別 = 'H05'），差異：
    - 只有一筆明細（不像 H01 依天拆開成好幾筆），起訖日期、天數、時數都是人資直接填寫，
      不會像 H01 一樣依班別自動算截止時間。
    - 存檔當下就直接核定（原程式「自動核定」：Raise Event User:CreateObject(..., 'E', ...)），
      不經過 A20 的簽核流程；ViewFILH010／ViewFILH011 的假別統計已經把 H01、H05 都算在一起。
    - 存檔後不能再修改、刪除（原程式：簽核狀態一旦 > '0' 就不能異動，而存檔當下已經是 'E'）。
    - 原程式「新增」只有 H01 的單據管理員（人資）看得到；一般員工只能看自己填的或自己是申請人的單。
      這裡沿用同一個判斷，新增功能限定給人資使用。
"""
from dataclasses import dataclass, field
from datetime import date, datetime, time
from decimal import Decimal, InvalidOperation

from flask import Blueprint, abort, current_app, flash, g, redirect, render_template, request, url_for

from . import db, edb
from .auth import login_required
from .formdocs import closing_date
from .leave import employee_info, is_doc_manager, leave_types
from .leave_rules import allowed_hours
from .magic import add_months, from_date, from_time, to_date, to_time, utc_guid
from .numbering import next_doc_no

bp = Blueprint('attendance', __name__, url_prefix='/hr/attendance')

DOC_TYPE = 'H05'
DOC_NAME = '出勤調整單'
STATUS_TEXT = {'E': '已核定'}


def load(no):
    return db.one('SELECT * FROM viewfilh018 WHERE "單別" = %s AND "單號" = %s', (DOC_TYPE, no))


def can_view(doc):
    me = g.user['員工編號']
    return is_doc_manager(me) or me in (doc['填寫人'].strip(), doc['申請人'].strip())


@dataclass
class AdjustForm:
    applicant: str = ''
    leave_type: str = ''
    start_date: date = None
    start_time: time = None
    end_date: date = None
    end_time: time = None
    days: int = 0
    hours: Decimal = Decimal(0)
    agent: str = ''
    reason: str = ''
    errors: list = field(default_factory=list)

    @classmethod
    def from_request(cls, form):
        f = cls(applicant=form.get('applicant', '').strip(), leave_type=form.get('leave_type', '').strip(),
                agent=form.get('agent', '').strip(), reason=form.get('reason', '').strip())
        try:
            f.start_date = date.fromisoformat(form.get('start_date', ''))
            f.end_date = date.fromisoformat(form.get('end_date', ''))
        except ValueError:
            f.errors.append('日期格式錯誤')
        try:
            f.start_time = time.fromisoformat(form.get('start_time', ''))
            f.end_time = time.fromisoformat(form.get('end_time', ''))
        except ValueError:
            f.errors.append('時間格式錯誤')
        try:
            f.days = int(form.get('days') or 0)
            f.hours = Decimal(form.get('hours') or 0)
            if f.days < 0 or f.hours < 0:
                raise ValueError
        except (ValueError, InvalidOperation):
            f.errors.append('天數、時數格式錯誤')
        return f

    @property
    def total_hours(self):
        return self.days * 8 + self.hours


def check(f):
    """#1159 UE_ErrCheck。有錯時放在 f.errors，回傳申請人資料。"""
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
    if f.total_hours == 0:
        f.errors.append('輸入請假時數')
    close = closing_date()
    if close and f.start_date <= close:
        f.errors.append('已關帳,請修正日期！')
    limit = Decimal(kind['年度限請天數'])
    if limit:
        used = db.scalar("""SELECT coalesce(sum("請假時數"), 0) FROM viewfilh011
                            WHERE "年度" = %s AND "申請人" = %s AND "假別" = %s""",
                         (str(f.start_date.year), f.applicant, f.leave_type))
        if (Decimal(used) + f.total_hours) / 8 > limit:
            f.errors.append('請假天數超過法定天數')
    return None if f.errors else applicant


def save(f, applicant):
    """寫入 FIL0030、HRFIL1031、FIL0040（一筆），並直接核定（EDB #54 status = 'E'）。回傳單號。"""
    user = g.user
    now = datetime.now()
    today = date.today()
    no = next_doc_no(DOC_TYPE, today, user['公司代碼'])
    serial = DOC_TYPE + utc_guid()
    app = current_app.config['SIGNING_APP_NAME']
    db.insert('fil0030', {
        '單據類別': DOC_TYPE, '單據編號': no, '單據日期': from_date(today), '公司代碼': user['公司代碼'],
        '簽核系統': f'{DOC_TYPE}.{app}', '簽核系統_結案': f'CLOSE.{DOC_TYPE}.{app}', '流水編號': serial,
        '填表人': user['員工編號'], '填表日': now, '部門編號': applicant['部門編號'],
        '最後更新者': user['員工編號'], '最後更新日': now})
    db.insert('hrfil1031', {'流水編號': serial, '單別': DOC_TYPE, '單號': no, '填寫人': user['員工編號'],
                            '申請人': f.applicant, '假別': f.leave_type, '請假假別': f.leave_type,
                            '填寫日期': from_date(today), '起始日期': from_date(f.start_date),
                            '起始時間': from_time(f.start_time), '截止日期': from_date(f.end_date),
                            '截止時間': from_time(f.end_time), '天數': f.days, '時數': f.hours,
                            '代理人': f.agent or ' ', '請假事由': f.reason})
    db.insert('fil0040', {'單據類別': DOC_TYPE, '單據編號': no, '單據序號': 0,
                          '異動日期': from_date(f.start_date), '異動數量': f.total_hours,
                          '最後更新者': user['員工編號'], '最後更新日': now})
    edb.create_object(serial, f'{no}({DOC_TYPE})', user['serial_num'], applicant['serial_num'], status='E')
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
    sql = ['SELECT * FROM viewfilh018 WHERE "填寫日期" BETWEEN %s AND %s']
    params = [from_date(date_from), from_date(date_to)]
    if not manager:
        sql.append('AND ("填寫人" = %s OR "申請人" = %s)')
        params += [me, me]
    rows = db.query(' '.join(sql) + ' ORDER BY "單號" DESC LIMIT 500', params)
    return render_template('attendance/index.html', rows=rows, date_from=date_from, date_to=date_to,
                           to_date=to_date, to_time=to_time, manager=manager)


@bp.route('/new', methods=('GET', 'POST'))
@login_required
def create():
    if not is_doc_manager(g.user['員工編號']):
        abort(403)
    kinds = leave_types()
    hour_options = {k['代碼'].strip(): [str(h) for h in allowed_hours(Decimal(k['至少小時']))] for k in kinds}
    if request.method == 'GET':
        return render_template('attendance/form.html', f=AdjustForm(), kinds=kinds, hour_options=hour_options)
    f = AdjustForm.from_request(request.form)
    applicant = check(f)
    if f.errors:
        for e in f.errors:
            flash(e, 'danger')
        return render_template('attendance/form.html', f=f, kinds=kinds, hour_options=hour_options)
    no = save(f, applicant)
    db.commit()
    flash(f'已存檔並核定 {no}', 'success')
    return redirect(url_for('attendance.view', no=no))


@bp.route('/<no>')
@login_required
def view(no):
    doc = load(no)
    if doc is None or not can_view(doc):
        abort(404)
    return render_template('attendance/view.html', doc=doc, to_date=to_date, to_time=to_time,
                           status_text=STATUS_TEXT)

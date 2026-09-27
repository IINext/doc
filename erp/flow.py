"""待簽清單（Home #79 別人給我的文件夾）；歸入待處理的（資料夾 3）另外列出。

只列出新系統已經支援的表單；其他表單仍在舊系統簽核（看不到內容的單不應該在這裡核准）。
表單模組用 register_form() 登記：表單代碼（單據流水號前三碼）→ 單據頁面的 endpoint。
"""
from flask import Blueprint, g, render_template, url_for

from . import db, edb
from .auth import login_required
from .magic import to_date

bp = Blueprint('flow', __name__, url_prefix='/flow')

FORMS = {}   # 表單代碼 → (名稱, endpoint)；endpoint 接收單號參數 no


def register_form(code, name, endpoint):
    FORMS[code] = (name, endpoint)


def document_url(serial):
    """單據流水號 → 新系統的單據頁面。"""
    form = FORMS.get(serial[:3])
    if form is None:
        return None
    no = db.scalar('SELECT "單據編號" FROM fil0030 WHERE "流水編號" = %s', (serial,))
    return url_for(form[1], no=no) if no else None


def pending_count():
    """導覽列的待簽數量；歸入「待處理」（資料夾 3）的不算。"""
    if g.get('user') is None:
        return 0
    if 'pending_count' not in g:
        g.pending_count = sum(1 for r in edb.pending(g.user['serial_num'], FORMS.keys()) if r['folder'] != '3')
    return g.pending_count


@bp.route('/')
@login_required
def index():
    rows = edb.pending(g.user['serial_num'], FORMS.keys())
    names = {r['serialno']: r['empname'] for r in db.query(
        'SELECT serialno, empname FROM viewofemp WHERE serialno = ANY(%s)',
        ([r['applyby'].strip() or r['owner'] for r in rows],))} if rows else {}
    items = [{**r, 'url': document_url(r['serial_num']), 'form': FORMS[r['form_code']][0],
              'applicant': names.get(r['applyby'].strip() or r['owner'], ''),
              'created': to_date(r['createdate'])} for r in rows]
    return render_template('flow/index.html', items=[i for i in items if i['folder'] != '3'],
                           held=[i for i in items if i['folder'] == '3'])

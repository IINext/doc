"""登入、登出、改密碼。

對應舊系統 Home #3「登入.手動登入」，但有這些不同：
- 密碼只存雜湊（erp_auth），不讀 FIL0010 的明文「個人密碼」，也沒有萬用密碼。
- 連續輸錯 5 次鎖定 15 分鐘。
帳號停用規則沿用舊系統：離職日期已到，或「停止使用」。
"""
import functools
import secrets
from datetime import date, datetime, timedelta, timezone

from flask import (Blueprint, abort, flash, g, redirect, render_template, request, session, url_for)
from werkzeug.security import check_password_hash, generate_password_hash

from . import db
from .magic import to_date

bp = Blueprint('auth', __name__)

MAX_FAILED = 5
LOCK_MINUTES = 15
MIN_PASSWORD = 8
_DUMMY_HASH = generate_password_hash(secrets.token_hex(16))


def load_employee(emp_no):
    return db.one('SELECT "員工編號", "員工姓名", "serial_num", "部門編號", "公司代碼", "離職日期", "停止使用" '
                  'FROM fil0010 WHERE "員工編號" = %s', (emp_no,))


def is_disabled(emp, today=None):
    """舊系統：(Date() >= 離職日期 AND 離職日期 <> 0) OR 停止使用。"""
    left = to_date(emp['離職日期'])
    return bool(emp['停止使用']) or (left is not None and (today or date.today()) >= left)


def set_password(emp_no, password, must_change=False):
    db.execute("""INSERT INTO erp_auth ("員工編號", password_hash, must_change, failed_count, locked_until, updated_at)
                  VALUES (%s, %s, %s, 0, NULL, now())
                  ON CONFLICT ("員工編號") DO UPDATE
                  SET password_hash = EXCLUDED.password_hash, must_change = EXCLUDED.must_change,
                      failed_count = 0, locked_until = NULL, updated_at = now()""",
               (emp_no, generate_password_hash(password), must_change))


def check_login(emp_no, password):
    """回傳 (員工資料, 錯誤訊息)。成功時錯誤訊息為 None。"""
    emp = load_employee(emp_no)
    auth = db.one('SELECT * FROM erp_auth WHERE "員工編號" = %s FOR UPDATE', (emp_no,)) if emp else None
    if not emp or not auth:
        check_password_hash(_DUMMY_HASH, password)   # 讓回應時間一致，避免從時間差猜出帳號是否存在
        return None, '帳號或密碼錯誤'
    now = datetime.now(timezone.utc)
    if auth['locked_until'] and auth['locked_until'] > now:
        return None, f'輸入錯誤次數過多，請 {LOCK_MINUTES} 分鐘後再試'
    if not check_password_hash(auth['password_hash'], password):
        failed = auth['failed_count'] + 1
        locked = now + timedelta(minutes=LOCK_MINUTES) if failed >= MAX_FAILED else None
        db.execute('UPDATE erp_auth SET failed_count = %s, locked_until = %s WHERE "員工編號" = %s',
                   (0 if locked else failed, locked, emp_no))
        db.commit()
        return None, '帳號或密碼錯誤'
    if is_disabled(emp):
        return None, '帳號已停用'
    db.execute('UPDATE erp_auth SET failed_count = 0, locked_until = NULL WHERE "員工編號" = %s', (emp_no,))
    db.commit()
    return {**emp, 'must_change': auth['must_change']}, None


@bp.before_app_request
def load_user():
    g.user = None
    emp_no = session.get('emp_no')
    if emp_no:
        emp = load_employee(emp_no)
        if emp and not is_disabled(emp):
            g.user = emp
        else:
            session.clear()


@bp.before_app_request
def csrf_protect():
    """所有 POST 都要帶 session 裡的 csrf_token。"""
    if request.method == 'POST':
        token = session.get('csrf_token')
        if not token or not secrets.compare_digest(token, request.form.get('csrf_token', '')):
            abort(400, 'CSRF token 錯誤，請重新整理頁面後再試')


def csrf_token():
    if 'csrf_token' not in session:
        session['csrf_token'] = secrets.token_urlsafe(32)
    return session['csrf_token']


def login_required(view):
    @functools.wraps(view)
    def wrapped(*args, **kwargs):
        if g.user is None:
            return redirect(url_for('auth.login', next=request.full_path))
        if session.get('must_change') and request.endpoint != 'auth.change_password':
            return redirect(url_for('auth.change_password'))
        return view(*args, **kwargs)
    return wrapped


def _safe_next(target):
    return target if target and target.startswith('/') and not target.startswith('//') else url_for('index')


@bp.route('/login', methods=('GET', 'POST'))
def login():
    if request.method == 'POST':
        emp_no = request.form.get('emp_no', '').strip().upper()
        emp, error = check_login(emp_no, request.form.get('password', ''))
        if error:
            flash(error, 'danger')
        else:
            session.clear()
            session['emp_no'] = emp['員工編號']
            session['must_change'] = emp['must_change']
            return redirect(_safe_next(request.args.get('next')))
    return render_template('login.html')


@bp.route('/logout', methods=('POST',))
def logout():
    session.clear()
    return redirect(url_for('auth.login'))


@bp.route('/password', methods=('GET', 'POST'))
@login_required
def change_password():
    if request.method == 'POST':
        current = request.form.get('current', '')
        new = request.form.get('new', '')
        auth = db.one('SELECT password_hash FROM erp_auth WHERE "員工編號" = %s', (g.user['員工編號'],))
        if not auth or not check_password_hash(auth['password_hash'], current):
            flash('目前密碼錯誤', 'danger')
        elif new != request.form.get('confirm', ''):
            flash('兩次輸入的新密碼不一致', 'danger')
        elif len(new) < MIN_PASSWORD:
            flash(f'新密碼至少 {MIN_PASSWORD} 個字元', 'danger')
        elif new.upper() == g.user['員工編號'] or new == current:
            flash('新密碼不能和員工編號或目前密碼相同', 'danger')
        else:
            set_password(g.user['員工編號'], new, must_change=False)
            db.commit()
            session['must_change'] = False
            flash('密碼已更新', 'success')
            return redirect(url_for('index'))
    return render_template('change_password.html')

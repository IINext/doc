# ============================================================
# 文件管理系統 app.py
# ============================================================
import os
import io
import uuid
import sqlite3
from datetime import date, datetime
from functools import wraps

from flask import (Flask, render_template, request, redirect, url_for,
                   session, flash, g, send_file, jsonify, abort)
from werkzeug.security import generate_password_hash, check_password_hash
from werkzeug.utils import secure_filename

try:
    import openpyxl
    from openpyxl.styles import Font, PatternFill, Alignment
    EXCEL_AVAILABLE = True
except ImportError:
    EXCEL_AVAILABLE = False

try:
    from reportlab.pdfgen import canvas as rl_canvas
    from reportlab.lib.pagesizes import A4
    from reportlab.pdfbase import pdfmetrics
    from reportlab.pdfbase.ttfonts import TTFont
    REPORTLAB_AVAILABLE = True
except ImportError:
    REPORTLAB_AVAILABLE = False

try:
    from pypdf import PdfWriter, PdfReader
    PYPDF_AVAILABLE = True
except ImportError:
    PYPDF_AVAILABLE = False

# ── App Config ────────────────────────────────────────────────
app = Flask(__name__)
app.secret_key = os.environ.get('SECRET_KEY', 'doc-manager-secret-2024')

BASE_DIR    = os.path.dirname(os.path.abspath(__file__))
SHARED_DIR  = os.path.join(os.path.dirname(BASE_DIR), '共用資料庫')
DATABASE    = os.path.join(SHARED_DIR, 'shared.db')
UPLOAD_FOLDER = os.path.join(BASE_DIR, 'uploads')
COMPANY_NAME = '企業'

# 可透過 LibreOffice 轉換成 PDF 的副檔名（查詢下載時才加浮水印）
CONVERTIBLE_EXTS = {
    '.doc', '.docx', '.odt', '.rtf',          # Word 類
    '.xls', '.xlsx', '.ods', '.csv',           # Excel 類
    '.ppt', '.pptx', '.odp',                   # PowerPoint 類
    '.txt',                                    # 純文字
}

os.makedirs(UPLOAD_FOLDER, exist_ok=True)

# ── Chinese Font for PDF ──────────────────────────────────────
CHINESE_FONT = 'Helvetica'
if REPORTLAB_AVAILABLE:
    for _fp in [
        r'C:\Windows\Fonts\msjh.ttc',
        r'C:\Windows\Fonts\mingliu.ttc',
        r'C:\Windows\Fonts\kaiu.ttf',
    ]:
        if os.path.exists(_fp):
            try:
                pdfmetrics.registerFont(TTFont('ChineseFont', _fp))
                CHINESE_FONT = 'ChineseFont'
            except Exception:
                pass
            break

# ── DB Helpers ────────────────────────────────────────────────
def get_db():
    db = getattr(g, '_database', None)
    if db is None:
        db = g._database = sqlite3.connect(DATABASE)
        db.row_factory = sqlite3.Row
        db.execute('PRAGMA foreign_keys = ON')
    return db


@app.teardown_appcontext
def close_db(exc):
    db = getattr(g, '_database', None)
    if db is not None:
        db.close()


def query_db(sql, args=(), one=False):
    cur = get_db().execute(sql, args)
    rv = cur.fetchall()
    return (rv[0] if rv else None) if one else rv


def execute_db(sql, args=()):
    db = get_db()
    cur = db.execute(sql, args)
    db.commit()
    return cur.lastrowid


def init_db():
    from werkzeug.security import check_password_hash as _chk
    with app.app_context():
        db = get_db()
        schema_path = os.path.join(BASE_DIR, 'schema.sql')
        with open(schema_path, encoding='utf-8') as f:
            db.executescript(f.read())
        db.commit()
        # Ensure the admin placeholder hash is replaced with a real one
        row = db.execute('SELECT password_hash FROM users WHERE username=?', ('admin',)).fetchone()
        if row and not _chk(row[0], 'admin123'):
            new_hash = generate_password_hash('admin123')
            db.execute('UPDATE users SET password_hash=? WHERE username=?', (new_hash, 'admin'))
            db.commit()

# ── Auth Decorators ───────────────────────────────────────────
def login_required(f):
    @wraps(f)
    def decorated(*args, **kwargs):
        if 'user_id' not in session:
            return redirect(url_for('login'))
        return f(*args, **kwargs)
    return decorated


def admin_required(f):
    @wraps(f)
    def decorated(*args, **kwargs):
        if 'user_id' not in session:
            return redirect(url_for('login'))
        u = query_db('SELECT is_admin FROM users WHERE id=?', [session['user_id']], one=True)
        if not u or not u['is_admin']:
            flash('需要管理員權限', 'danger')
            return redirect(url_for('index'))
        return f(*args, **kwargs)
    return decorated


def current_user():
    if 'user_id' not in session:
        return None
    return query_db('SELECT * FROM users WHERE id=?', [session['user_id']], one=True)

# ── File Helpers ──────────────────────────────────────────────
def save_file(file_obj):
    """Save uploaded file. Returns (original_name, stored_name)."""
    original = file_obj.filename
    ext = os.path.splitext(original)[1] if '.' in original else ''
    stored = str(uuid.uuid4()) + ext
    file_obj.save(os.path.join(UPLOAD_FOLDER, stored))
    return original, stored


def gen_doc_number():
    """Auto-generate document number: YYYYMM + 4-digit seq."""
    prefix = datetime.now().strftime('%Y%m')
    row = query_db("SELECT COUNT(*) AS c FROM documents WHERE doc_number LIKE ?",
                   [prefix + '%'], one=True)
    seq = (row['c'] + 1) if row else 1
    return f'{prefix}{seq:04d}'

# ── Folder Helpers ────────────────────────────────────────────
def get_folder_tree(tab_id, parent_id=None):
    folders = query_db(
        'SELECT * FROM folders WHERE tab_id=? AND parent_id IS ? ORDER BY order_no, name',
        [tab_id, parent_id]
    )
    result = []
    for f in folders:
        item = dict(f)
        item['children'] = get_folder_tree(tab_id, f['id'])
        result.append(item)
    return result


def get_all_subfolder_ids(folder_id):
    children = query_db('SELECT id FROM folders WHERE parent_id=?', [folder_id])
    ids = []
    for ch in children:
        ids.append(ch['id'])
        ids.extend(get_all_subfolder_ids(ch['id']))
    return ids


def get_folder_breadcrumb(folder_id):
    parts = []
    fid = folder_id
    while fid:
        folder = query_db('SELECT * FROM folders WHERE id=?', [fid], one=True)
        if not folder:
            break
        parts.insert(0, folder['name'])
        fid = folder['parent_id']
    if folder_id:
        row = query_db(
            'SELECT t.name FROM folders f JOIN tabs t ON f.tab_id=t.id WHERE f.id=?',
            [folder_id], one=True
        )
        if row:
            parts.insert(0, row['name'])
    return ' / '.join(parts)

# ── PDF Watermark Helpers ──────────────────────────────────────
def _build_watermark_page(user_name):
    """以 reportlab 建立一頁僅含浮水印文字的 PDF BytesIO。"""
    buf = io.BytesIO()
    if not REPORTLAB_AVAILABLE:
        return buf
    c = rl_canvas.Canvas(buf, pagesize=A4)
    w, h = A4
    wm = f'{COMPANY_NAME}  {user_name}  {datetime.now().strftime("%Y-%m-%d %H:%M")}'
    c.setFillColorRGB(0.75, 0.75, 0.75, alpha=0.45)
    c.setFont(CHINESE_FONT, 20)
    for y in range(80, int(h) + 80, 150):
        c.saveState()
        c.translate(w / 2, y)
        c.rotate(45)
        c.drawCentredString(0, 0, wm)
        c.restoreState()
    c.showPage()
    c.save()
    buf.seek(0)
    return buf


def _overlay_watermark(src_pdf_path, user_name):
    """將浮水印疊加到現有 PDF 的每一頁，回傳 BytesIO。
    需要 pypdf；失敗時回傳空 BytesIO。"""
    out = io.BytesIO()
    if not (REPORTLAB_AVAILABLE and PYPDF_AVAILABLE):
        return out
    try:
        wm_buf = _build_watermark_page(user_name)
        wm_reader = PdfReader(wm_buf)
        wm_page  = wm_reader.pages[0]

        reader = PdfReader(src_pdf_path)
        writer = PdfWriter()
        for page in reader.pages:
            page.merge_page(wm_page)
            writer.add_page(page)
        writer.write(out)
        out.seek(0)
    except Exception:
        out.seek(0)
    return out


def _libreoffice_to_pdf(src_path):
    """呼叫 LibreOffice headless 將 src_path 轉成 PDF，回傳 PDF 路徑或 None。"""
    import subprocess, tempfile, shutil
    soffice = shutil.which('soffice') or shutil.which('libreoffice')
    if not soffice:
        # Windows 常見安裝位置
        for candidate in [
            r'C:\Program Files\LibreOffice\program\soffice.exe',
            r'C:\Program Files (x86)\LibreOffice\program\soffice.exe',
        ]:
            if os.path.exists(candidate):
                soffice = candidate
                break
    if not soffice:
        return None
    out_dir = tempfile.mkdtemp()
    try:
        result = subprocess.run(
            [soffice, '--headless', '--convert-to', 'pdf', '--outdir', out_dir, src_path],
            timeout=60, capture_output=True
        )
        if result.returncode == 0:
            base = os.path.splitext(os.path.basename(src_path))[0]
            pdf_path = os.path.join(out_dir, base + '.pdf')
            if os.path.exists(pdf_path):
                return pdf_path
    except Exception:
        pass
    return None


def download_for_shared_user(doc, user_name):
    """分享者（查詢）下載邏輯：
    - 可轉 PDF 的 Office 類型 → LibreOffice 轉 PDF + 浮水印疊加
    - PDF 原檔 → 直接疊加浮水印
    - 其他（圖片、壓縮檔…）→ 直接給原檔，不加浮水印
    """
    src_path = os.path.join(UPLOAD_FOLDER, doc['stored_filename'])
    if not os.path.exists(src_path):
        return None

    ext = os.path.splitext(doc['original_filename'])[1].lower()

    if ext == '.pdf':
        # 直接疊加浮水印
        buf = _overlay_watermark(src_path, user_name)
        if buf.getbuffer().nbytes > 0:
            return send_file(buf, mimetype='application/pdf',
                             download_name=f"{doc['doc_number']}_浮水印.pdf",
                             as_attachment=True)
        # 疊加失敗 → 原檔
        return send_file(src_path, download_name=doc['original_filename'], as_attachment=True)

    if ext in CONVERTIBLE_EXTS:
        # 先轉 PDF，再疊加浮水印
        pdf_path = _libreoffice_to_pdf(src_path)
        if pdf_path:
            buf = _overlay_watermark(pdf_path, user_name)
            if buf.getbuffer().nbytes > 0:
                return send_file(buf, mimetype='application/pdf',
                                 download_name=f"{doc['doc_number']}_浮水印.pdf",
                                 as_attachment=True)
        # 轉換失敗 → 原檔
        return send_file(src_path, download_name=doc['original_filename'], as_attachment=True)

    # 不可轉換的類型（圖片、ZIP 等）→ 原檔，不加浮水印
    return send_file(src_path, download_name=doc['original_filename'], as_attachment=True)

# ════════════════════════════════════════════════════════════════
# Auth Routes
# ════════════════════════════════════════════════════════════════
@app.route('/login', methods=['GET', 'POST'])
def login():
    if 'user_id' in session:
        return redirect(url_for('index'))
    if request.method == 'POST':
        username = request.form.get('username', '').strip()
        password = request.form.get('password', '')
        user = query_db('SELECT * FROM users WHERE username=?', [username], one=True)
        if user and check_password_hash(user['password_hash'], password):
            session['user_id'] = user['id']
            session['user_name'] = user['name']
            session['is_admin'] = bool(user['is_admin'])
            return redirect(url_for('index'))
        flash('帳號或密碼錯誤', 'danger')
    return render_template('login.html')


@app.route('/logout')
def logout():
    session.clear()
    return redirect(url_for('login'))


# ════════════════════════════════════════════════════════════════
# Main Page
# ════════════════════════════════════════════════════════════════
@app.route('/')
@login_required
def index():
    user = current_user()
    public_tabs = query_db("SELECT * FROM tabs WHERE tab_type='public' ORDER BY order_no, name")
    personal_tabs = query_db(
        "SELECT * FROM tabs WHERE tab_type='personal' AND owner_id=? ORDER BY order_no, name",
        [user['id']]
    )
    return render_template('index.html', user=user,
                           public_tabs=[dict(t) for t in public_tabs],
                           personal_tabs=[dict(t) for t in personal_tabs])


# ── AJAX ─────────────────────────────────────────────────────
@app.route('/api/folders/<int:tab_id>')
@login_required
def api_folders(tab_id):
    tree = get_folder_tree(tab_id)
    return jsonify(tree)


@app.route('/api/documents/<int:folder_id>')
@login_required
def api_documents(folder_id):
    user = current_user()
    uid = user['id']
    is_admin = bool(user['is_admin'])

    sort_col = request.args.get('sort', 'created_at')
    sort_dir = request.args.get('dir', 'DESC').upper()
    valid_cols = {'doc_number', 'subject', 'version', 'issue_date', 'created_at', 'sign_status'}
    if sort_col not in valid_cols:
        sort_col = 'created_at'
    if sort_dir not in {'ASC', 'DESC'}:
        sort_dir = 'DESC'

    all_ids = get_all_subfolder_ids(folder_id)
    all_ids.append(folder_id)
    ph = ','.join('?' * len(all_ids))

    if is_admin:
        where_perm = '1=1'
        extra_args = []
    else:
        where_perm = f'''(
            d.owner_id = ?
            OR EXISTS (SELECT 1 FROM folders f2
                       JOIN tabs t2 ON f2.tab_id=t2.id
                       WHERE f2.id=d.folder_id AND t2.tab_type='public')
            OR (d.is_locked = 0 AND (
                EXISTS (SELECT 1 FROM document_permissions dp
                        WHERE dp.document_id=d.id AND dp.user_id=?)
                OR EXISTS (SELECT 1 FROM document_permissions dp
                           JOIN group_members gm ON dp.group_id=gm.group_id
                           WHERE dp.document_id=d.id AND gm.user_id=?)
            ))
        )'''
        extra_args = [uid, uid, uid]

    sql = f'''
        SELECT d.*, ft.name AS file_type_name, u.name AS owner_name,
               f.name AS folder_name
        FROM documents d
        LEFT JOIN file_types ft ON d.file_type_id=ft.id
        LEFT JOIN users u ON d.owner_id=u.id
        LEFT JOIN folders f ON d.folder_id=f.id
        WHERE d.folder_id IN ({ph}) AND d.is_deleted=0
          AND {where_perm}
        ORDER BY d.{sort_col} {sort_dir}
    '''
    docs = query_db(sql, all_ids + extra_args)
    result = []
    for d in docs:
        row = dict(d)
        is_owner = (d['owner_id'] == uid)
        row['is_owner'] = is_owner
        row['locked_by_me'] = (d['locked_by'] == uid)
        if is_owner or is_admin:
            row['can_edit']   = True
            row['can_delete'] = True
        else:
            p = get_shared_perm(d['id'], uid)
            row['can_edit']   = p['can_edit']
            row['can_delete'] = p['can_delete']
        result.append(row)
    return jsonify(result)


@app.route('/api/shared_owners')
@login_required
def api_shared_owners():
    """回傳有分享文件給我的使用者清單（id, name）。"""
    user = current_user()
    uid = user['id']
    owners = query_db('''
        SELECT DISTINCT u.id, u.name
        FROM documents d
        JOIN document_permissions dp ON dp.document_id=d.id
        LEFT JOIN group_members gm ON dp.group_id=gm.group_id
        JOIN users u ON d.owner_id=u.id
        WHERE d.is_deleted=0 AND d.owner_id!=?
          AND (dp.user_id=? OR gm.user_id=?)
        ORDER BY u.name
    ''', [uid, uid, uid])
    return jsonify([dict(o) for o in owners])


@app.route('/api/shared_docs')
@login_required
def api_shared_docs():
    user = current_user()
    uid = user['id']
    # 可依分享者過濾
    owner_id = request.args.get('owner_id', type=int)
    extra_where = 'AND d.owner_id=?' if owner_id else ''
    extra_args  = [owner_id] if owner_id else []

    docs = query_db(f'''
        SELECT DISTINCT d.*, ft.name AS file_type_name, u.name AS owner_name,
               f.name AS folder_name, t.name AS tab_name
        FROM documents d
        JOIN document_permissions dp ON dp.document_id=d.id
        LEFT JOIN group_members gm ON dp.group_id=gm.group_id
        LEFT JOIN file_types ft ON d.file_type_id=ft.id
        LEFT JOIN users u ON d.owner_id=u.id
        LEFT JOIN folders f ON d.folder_id=f.id
        LEFT JOIN tabs t ON f.tab_id=t.id
        WHERE d.is_deleted=0 AND d.owner_id!=?
          AND (dp.user_id=? OR gm.user_id=?)
          {extra_where}
        ORDER BY d.created_at DESC
    ''', [uid, uid, uid] + extra_args)
    result = [dict(d) for d in docs]
    for r in result:
        r['is_owner'] = False
        r['locked_by_me'] = (r.get('locked_by') == uid)
        p = get_shared_perm(r['id'], uid)
        r['can_edit']   = p['can_edit']
        r['can_delete'] = p['can_delete']
    return jsonify(result)


@app.route('/api/folder_info/<int:folder_id>')
@login_required
def api_folder_info(folder_id):
    folder = query_db('SELECT * FROM folders WHERE id=?', [folder_id], one=True)
    if not folder:
        return jsonify({})
    breadcrumb = get_folder_breadcrumb(folder_id)
    return jsonify({'id': folder_id, 'name': folder['name'], 'breadcrumb': breadcrumb})


@app.route('/api/users')
@login_required
def api_users():
    users = query_db('SELECT id, name, username, department FROM users ORDER BY name')
    return jsonify([dict(u) for u in users])


@app.route('/api/groups')
@login_required
def api_groups():
    groups = query_db('SELECT id, name FROM groups_tbl ORDER BY name')
    return jsonify([dict(g) for g in groups])


# ════════════════════════════════════════════════════════════════
# Tab Management
# ════════════════════════════════════════════════════════════════
@app.route('/tab/new', methods=['POST'])
@login_required
def tab_new():
    user = current_user()
    name = request.form.get('name', '').strip()
    if not name:
        return jsonify({'success': False, 'msg': '名稱不能為空'})
    tid = execute_db(
        "INSERT INTO tabs (name, owner_id, tab_type) VALUES (?, ?, 'personal')",
        [name, user['id']]
    )
    return jsonify({'success': True, 'id': tid, 'name': name})


@app.route('/tab/<int:tab_id>/edit', methods=['POST'])
@login_required
def tab_edit(tab_id):
    user = current_user()
    tab = query_db('SELECT * FROM tabs WHERE id=?', [tab_id], one=True)
    if not tab or (tab['owner_id'] != user['id'] and not user['is_admin']):
        return jsonify({'success': False, 'msg': '無權限'})
    name = request.form.get('name', '').strip()
    if not name:
        return jsonify({'success': False, 'msg': '名稱不能為空'})
    execute_db('UPDATE tabs SET name=? WHERE id=?', [name, tab_id])
    return jsonify({'success': True})


@app.route('/tab/<int:tab_id>/delete', methods=['POST'])
@login_required
def tab_delete(tab_id):
    user = current_user()
    tab = query_db('SELECT * FROM tabs WHERE id=?', [tab_id], one=True)
    if not tab:
        return jsonify({'success': False, 'msg': '頁籤不存在'})
    if tab['tab_type'] == 'public':
        return jsonify({'success': False, 'msg': '無法刪除公共頁籤'})
    if tab['owner_id'] != user['id'] and not user['is_admin']:
        return jsonify({'success': False, 'msg': '無權限'})
    execute_db('DELETE FROM tabs WHERE id=?', [tab_id])
    return jsonify({'success': True})


# ════════════════════════════════════════════════════════════════
# Folder Management
# ════════════════════════════════════════════════════════════════
@app.route('/folder/new', methods=['POST'])
@login_required
def folder_new():
    user = current_user()
    name = request.form.get('name', '').strip()
    description = request.form.get('description', '').strip()
    tab_id = request.form.get('tab_id', type=int)
    parent_id = request.form.get('parent_id', type=int)

    if not name or not tab_id:
        return jsonify({'success': False, 'msg': '名稱及頁籤不能為空'})

    tab = query_db('SELECT * FROM tabs WHERE id=?', [tab_id], one=True)
    if tab and tab['tab_type'] == 'public' and not user['is_admin']:
        return jsonify({'success': False, 'msg': '公共頁籤的資料夾需要管理員權限'})

    fid = execute_db(
        'INSERT INTO folders (name, description, tab_id, parent_id, owner_id) VALUES (?,?,?,?,?)',
        [name, description, tab_id, parent_id, user['id']]
    )
    return jsonify({'success': True, 'id': fid, 'name': name})


@app.route('/folder/<int:folder_id>/edit', methods=['POST'])
@login_required
def folder_edit(folder_id):
    user = current_user()
    folder = query_db('SELECT * FROM folders WHERE id=?', [folder_id], one=True)
    if not folder:
        return jsonify({'success': False, 'msg': '資料夾不存在'})
    if _is_public_folder(folder_id) and not user['is_admin']:
        return jsonify({'success': False, 'msg': '公共頁籤的資料夾需要管理員權限'})
    if folder['owner_id'] != user['id'] and not user['is_admin']:
        return jsonify({'success': False, 'msg': '無權限'})
    name = request.form.get('name', '').strip()
    description = request.form.get('description', '').strip()
    if not name:
        return jsonify({'success': False, 'msg': '名稱不能為空'})
    execute_db('UPDATE folders SET name=?, description=? WHERE id=?',
               [name, description, folder_id])
    return jsonify({'success': True})


@app.route('/folder/<int:folder_id>/delete', methods=['POST'])
@login_required
def folder_delete(folder_id):
    user = current_user()
    folder = query_db('SELECT * FROM folders WHERE id=?', [folder_id], one=True)
    if not folder:
        return jsonify({'success': False, 'msg': '資料夾不存在'})
    if _is_public_folder(folder_id) and not user['is_admin']:
        return jsonify({'success': False, 'msg': '公共頁籤的資料夾需要管理員權限'})
    if folder['owner_id'] != user['id'] and not user['is_admin']:
        return jsonify({'success': False, 'msg': '無權限'})
    doc_cnt = query_db(
        'SELECT COUNT(*) AS c FROM documents WHERE folder_id=? AND is_deleted=0',
        [folder_id], one=True
    )
    if doc_cnt and doc_cnt['c'] > 0:
        return jsonify({'success': False, 'msg': '資料夾內有文件，請先移除文件'})
    child_cnt = query_db('SELECT COUNT(*) AS c FROM folders WHERE parent_id=?',
                         [folder_id], one=True)
    if child_cnt and child_cnt['c'] > 0:
        return jsonify({'success': False, 'msg': '資料夾內有子資料夾，請先刪除'})
    execute_db('DELETE FROM folders WHERE id=?', [folder_id])
    return jsonify({'success': True})


@app.route('/folder/<int:folder_id>/share', methods=['POST'])
@login_required
def folder_share(folder_id):
    user = current_user()
    folder = query_db('SELECT * FROM folders WHERE id=?', [folder_id], one=True)
    if not folder or (folder['owner_id'] != user['id'] and not user['is_admin']):
        return jsonify({'success': False, 'msg': '無權限'})

    action = request.form.get('action', 'add')
    user_id = request.form.get('user_id', type=int)
    group_id = request.form.get('group_id', type=int)

    if action == 'remove':
        if user_id:
            execute_db('DELETE FROM folder_permissions WHERE folder_id=? AND user_id=?',
                       [folder_id, user_id])
        elif group_id:
            execute_db('DELETE FROM folder_permissions WHERE folder_id=? AND group_id=?',
                       [folder_id, group_id])
    else:
        if user_id:
            ex = query_db('SELECT id FROM folder_permissions WHERE folder_id=? AND user_id=?',
                          [folder_id, user_id], one=True)
            if not ex:
                execute_db('INSERT INTO folder_permissions (folder_id, user_id) VALUES (?,?)',
                           [folder_id, user_id])
        elif group_id:
            ex = query_db('SELECT id FROM folder_permissions WHERE folder_id=? AND group_id=?',
                          [folder_id, group_id], one=True)
            if not ex:
                execute_db('INSERT INTO folder_permissions (folder_id, group_id) VALUES (?,?)',
                           [folder_id, group_id])

    perms = query_db('''
        SELECT fp.*, u.name AS user_name, g.name AS group_name
        FROM folder_permissions fp
        LEFT JOIN users u ON fp.user_id=u.id
        LEFT JOIN groups_tbl g ON fp.group_id=g.id
        WHERE fp.folder_id=?
    ''', [folder_id])
    return jsonify({'success': True, 'permissions': [dict(p) for p in perms]})


# ── 文件授權查詢 helper ───────────────────────────────────────
def get_shared_perm(doc_id, user_id):
    """回傳該使用者對此文件的授權（合併直接授權與群組授權，取 OR）。"""
    direct = query_db('''
        SELECT can_read, can_edit, can_delete FROM document_permissions
        WHERE document_id=? AND user_id=?
    ''', [doc_id, user_id], one=True)

    grp = query_db('''
        SELECT MAX(dp.can_read)   AS can_read,
               MAX(dp.can_edit)   AS can_edit,
               MAX(dp.can_delete) AS can_delete
        FROM document_permissions dp
        JOIN group_members gm ON dp.group_id = gm.group_id
        WHERE dp.document_id=? AND gm.user_id=?
    ''', [doc_id, user_id], one=True)

    return {
        'can_read':   bool((direct and direct['can_read'])   or (grp and grp['can_read'])),
        'can_edit':   bool((direct and direct['can_edit'])   or (grp and grp['can_edit'])),
        'can_delete': bool((direct and direct['can_delete']) or (grp and grp['can_delete'])),
    }


# ════════════════════════════════════════════════════════════════
# Document CRUD
# ════════════════════════════════════════════════════════════════
@app.route('/doc/new', methods=['GET', 'POST'])
@login_required
def doc_new():
    user = current_user()
    if request.method == 'GET':
        folder_id = request.args.get('folder_id', type=int)
        file_types = query_db('SELECT * FROM file_types ORDER BY name')
        folders = _accessible_folders(user)
        return render_template('doc_form.html', user=user, doc=None,
                               doc_number=gen_doc_number(),
                               folder_id=folder_id,
                               file_types=file_types,
                               folders=folders,
                               folder_readonly=False,
                               folder_display='',
                               view_only=False,
                               today=date.today().isoformat())

    # POST
    doc_number = request.form.get('doc_number', '').strip()
    subject = request.form.get('subject', '').strip()
    version = request.form.get('version', '1') or '1'
    issue_date = request.form.get('issue_date') or date.today().isoformat()
    file_type_id = request.form.get('file_type_id') or None
    department = request.form.get('department', user['department']).strip()
    remarks = request.form.get('remarks', '').strip()
    is_encrypted = 1 if request.form.get('is_encrypted') else 0
    encrypt_password = request.form.get('encrypt_password', '').strip()
    folder_id = request.form.get('folder_id', type=int)

    if not doc_number or not subject or not folder_id:
        flash('案號、主旨、資料夾為必填', 'danger')
        return redirect(request.referrer or url_for('doc_new'))

    if _is_public_folder(folder_id) and not user['is_admin']:
        flash('公共頁籤的文件需要管理員權限', 'danger')
        return redirect(request.referrer or url_for('doc_new'))

    if query_db('SELECT id FROM documents WHERE doc_number=?', [doc_number], one=True):
        flash(f'案號 {doc_number} 已存在，請重新取號', 'danger')
        return redirect(request.referrer or url_for('doc_new'))

    original_filename = ''
    stored_filename = ''
    if 'file' in request.files and request.files['file'].filename:
        f = request.files['file']
        original_filename, stored_filename = save_file(f)
        if not request.form.get('subject'):
            subject = os.path.splitext(original_filename)[0]

    execute_db('''
        INSERT INTO documents
            (doc_number, version, subject, issue_date, file_type_id,
             department, remarks, is_encrypted, encrypt_password,
             original_filename, stored_filename, folder_id, owner_id)
        VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?)
    ''', [doc_number, int(version), subject, issue_date, file_type_id,
          department, remarks, is_encrypted, encrypt_password,
          original_filename, stored_filename, folder_id, user['id']])

    flash('文件新增成功', 'success')
    return redirect(url_for('index'))


@app.route('/doc/<int:doc_id>/edit', methods=['GET', 'POST'])
@login_required
def doc_edit(doc_id):
    user = current_user()
    doc = query_db('SELECT * FROM documents WHERE id=? AND is_deleted=0', [doc_id], one=True)
    if not doc:
        abort(404)
    is_owner = (doc['owner_id'] == user['id'])
    perm = get_shared_perm(doc_id, user['id'])

    # ── 查詢模式（?view=1） ────────────────────────────────────
    if request.method == 'GET' and request.args.get('view') == '1':
        # 查詢只需能看到文件即可（擁有者、管理員、被分享者、公共頁籤皆可）
        in_public = bool(query_db(
            '''SELECT 1 FROM folders f JOIN tabs t ON f.tab_id=t.id
               WHERE f.id=? AND t.tab_type='public' ''',
            [doc['folder_id']], one=True))
        if not is_owner and not user['is_admin'] and not perm['can_read'] and not in_public:
            flash('無權限查詢此文件', 'danger')
            return redirect(url_for('index'))
        # 查詢模式不鎖定文件
        file_types = query_db('SELECT * FROM file_types ORDER BY name')
        fld = query_db('''SELECT f.name, t.name AS tab_name
                          FROM folders f JOIN tabs t ON f.tab_id=t.id
                          WHERE f.id=?''', [doc['folder_id']], one=True)
        folder_display = f"{fld['tab_name']} / {fld['name']}" if fld else ''
        return render_template('doc_form.html', user=user, doc=dict(doc),
                               doc_number=doc['doc_number'],
                               folder_id=doc['folder_id'],
                               file_types=file_types, folders=[],
                               folder_readonly=True,
                               folder_display=folder_display,
                               view_only=True,
                               today=date.today().isoformat())

    if not is_owner and not user['is_admin'] and not perm['can_edit']:
        flash('無權限修改此文件', 'danger')
        return redirect(url_for('index'))

    # 鎖定檢查：文件已被他人鎖定時拒絕進入
    if doc['is_locked'] and doc['locked_by'] and doc['locked_by'] != user['id']:
        locker = query_db('SELECT name FROM users WHERE id=?', [doc['locked_by']], one=True)
        locker_name = locker['name'] if locker else '他人'
        flash(f'文件正在被「{locker_name}」修改中，請稍後再試', 'warning')
        return redirect(url_for('index'))

    if request.method == 'GET':
        # 開啟修改頁面 → 自動上鎖
        execute_db('UPDATE documents SET is_locked=1, locked_by=? WHERE id=?',
                   [user['id'], doc_id])
        file_types = query_db('SELECT * FROM file_types ORDER BY name')
        folders = _accessible_folders(user)
        # 非擁有者（被分享者）修改時，資料夾欄位唯讀
        folder_readonly = not is_owner and not user['is_admin']
        folder_display = ''
        if folder_readonly:
            fld = query_db('''SELECT f.name, t.name AS tab_name
                              FROM folders f JOIN tabs t ON f.tab_id=t.id
                              WHERE f.id=?''', [doc['folder_id']], one=True)
            if fld:
                folder_display = f"{fld['tab_name']} / {fld['name']}"
        return render_template('doc_form.html', user=user, doc=dict(doc),
                               doc_number=doc['doc_number'],
                               folder_id=doc['folder_id'],
                               file_types=file_types, folders=folders,
                               folder_readonly=folder_readonly,
                               folder_display=folder_display,
                               view_only=False,
                               today=date.today().isoformat())

    # POST
    subject = request.form.get('subject', doc['subject']).strip()
    issue_date = request.form.get('issue_date', doc['issue_date'])
    file_type_id = request.form.get('file_type_id') or None
    department = request.form.get('department', doc['department']).strip()
    remarks = request.form.get('remarks', doc['remarks']).strip()
    is_encrypted = 1 if request.form.get('is_encrypted') else 0
    encrypt_password = request.form.get('encrypt_password', doc['encrypt_password']).strip()
    folder_id = request.form.get('folder_id', type=int) or doc['folder_id']
    version_bump = bool(request.form.get('version_bump'))

    # 非管理員不得將文件存入公共頁籤資料夾
    if _is_public_folder(folder_id) and not user['is_admin']:
        flash('公共頁籤的文件需要管理員權限', 'danger')
        return redirect(request.referrer or url_for('index'))

    new_version = doc['version']
    if version_bump:
        # Archive current version
        execute_db('''
            INSERT INTO document_versions
                (document_id, version, original_filename, stored_filename, created_by)
            VALUES (?,?,?,?,?)
        ''', [doc_id, doc['version'], doc['original_filename'], doc['stored_filename'], user['id']])
        new_version = doc['version'] + 1

    original_filename = doc['original_filename']
    stored_filename = doc['stored_filename']
    if 'file' in request.files and request.files['file'].filename:
        f = request.files['file']
        original_filename, stored_filename = save_file(f)

    execute_db('''
        UPDATE documents
        SET version=?, subject=?, issue_date=?, file_type_id=?,
            department=?, remarks=?, is_encrypted=?, encrypt_password=?,
            original_filename=?, stored_filename=?, folder_id=?,
            is_locked=0, locked_by=NULL,
            updated_at=CURRENT_TIMESTAMP
        WHERE id=?
    ''', [new_version, subject, issue_date, file_type_id,
          department, remarks, is_encrypted, encrypt_password,
          original_filename, stored_filename, folder_id, doc_id])

    flash('文件更新成功', 'success')
    return redirect(url_for('index'))


def _is_public_folder(folder_id):
    """判斷資料夾是否屬於公共頁籤。"""
    row = query_db('''SELECT t.tab_type FROM folders f
                      JOIN tabs t ON f.tab_id=t.id WHERE f.id=?''',
                   [folder_id], one=True)
    return row and row['tab_type'] == 'public'


def _accessible_folders(user):
    """回傳使用者可選擇存放文件的資料夾清單。
    管理員：所有資料夾。
    一般使用者：僅自己個人頁籤下的資料夾（公共頁籤唯讀，不可新增/修改文件）。
    """
    if user['is_admin']:
        return query_db('''
            SELECT f.*, t.name AS tab_name FROM folders f
            JOIN tabs t ON f.tab_id=t.id
            ORDER BY t.name, f.name
        ''')
    return query_db('''
        SELECT f.*, t.name AS tab_name FROM folders f
        JOIN tabs t ON f.tab_id=t.id
        WHERE f.owner_id=? AND t.tab_type='personal'
        ORDER BY t.name, f.name
    ''', [user['id']])


@app.route('/doc/<int:doc_id>/delete', methods=['POST'])
@login_required
def doc_delete(doc_id):
    user = current_user()
    doc = query_db('SELECT * FROM documents WHERE id=?', [doc_id], one=True)
    if not doc:
        return jsonify({'success': False, 'msg': '文件不存在'})
    is_owner = (doc['owner_id'] == user['id'])
    perm = get_shared_perm(doc_id, user['id'])
    if not is_owner and not user['is_admin'] and not perm['can_delete']:
        return jsonify({'success': False, 'msg': '無刪除權限'})
    if doc['sign_status'] == 'pending':
        return jsonify({'success': False, 'msg': '已送簽的文件無法刪除'})
    execute_db('UPDATE documents SET is_deleted=1, updated_at=CURRENT_TIMESTAMP WHERE id=?',
               [doc_id])
    return jsonify({'success': True})


# ════════════════════════════════════════════════════════════════
# Document Actions
# ════════════════════════════════════════════════════════════════
@app.route('/doc/<int:doc_id>/lock', methods=['POST'])
@login_required
def doc_lock(doc_id):
    user = current_user()
    doc = query_db('SELECT * FROM documents WHERE id=?', [doc_id], one=True)
    if not doc or (doc['owner_id'] != user['id'] and not user['is_admin']):
        return jsonify({'success': False, 'msg': '無權限'})
    execute_db('UPDATE documents SET is_locked=1, locked_by=? WHERE id=?',
               [user['id'], doc_id])
    return jsonify({'success': True})


@app.route('/doc/<int:doc_id>/unlock', methods=['POST'])
@login_required
def doc_unlock(doc_id):
    user = current_user()
    doc = query_db('SELECT * FROM documents WHERE id=?', [doc_id], one=True)
    if not doc:
        return jsonify({'success': False, 'msg': '文件不存在'})
    # 只有鎖定者本人或管理員可解鎖
    if doc['locked_by'] != user['id'] and not user['is_admin']:
        return jsonify({'success': False, 'msg': '只有鎖定者本人或管理員才能解鎖'})
    execute_db('UPDATE documents SET is_locked=0, locked_by=NULL WHERE id=?', [doc_id])
    return jsonify({'success': True})


@app.route('/doc/<int:doc_id>/download')
@login_required
def doc_download(doc_id):
    user = current_user()
    doc = query_db('SELECT * FROM documents WHERE id=? AND is_deleted=0', [doc_id], one=True)
    if not doc:
        abort(404)

    uid = user['id']
    is_owner = (doc['owner_id'] == uid) or bool(user['is_admin'])

    if not is_owner:
        # 公共頁籤文件：所有登入使用者皆可下載
        in_public = query_db('''
            SELECT 1 FROM folders f JOIN tabs t ON f.tab_id=t.id
            WHERE f.id=? AND t.tab_type='public'
        ''', [doc['folder_id']], one=True)
        if not in_public:
            has_perm = query_db('''
                SELECT 1 FROM document_permissions dp
                LEFT JOIN group_members gm ON dp.group_id=gm.group_id
                WHERE dp.document_id=? AND (dp.user_id=? OR gm.user_id=?)
                LIMIT 1
            ''', [doc_id, uid, uid], one=True)
            if not has_perm:
                abort(403)

    if doc['is_encrypted'] and doc['encrypt_password']:
        pw = request.args.get('password', '')
        if pw != doc['encrypt_password'] and not user['is_admin']:
            return_url = request.referrer or url_for('index')
            return render_template('enter_password.html', user=user,
                                   doc_id=doc_id, subject=doc['subject'],
                                   return_url=return_url)

    fp = os.path.join(UPLOAD_FOLDER, doc['stored_filename'])
    if not os.path.exists(fp):
        flash('實體檔案不存在', 'danger')
        return redirect(url_for('index'))

    # ── 下載稽核紀錄 ──────────────────────────────────────────
    _dl_path = get_folder_breadcrumb(doc['folder_id'])
    execute_db(
        '''INSERT INTO download_logs
               (doc_id, doc_number, subject, doc_path, user_id, user_name)
           VALUES (?, ?, ?, ?, ?, ?)''',
        [doc['id'], doc['doc_number'], doc['subject'],
         _dl_path, user['id'], user['name']]
    )
    # ─────────────────────────────────────────────────────────

    if is_owner:
        # 擁有者（修改模式）→ 原檔直接下載
        return send_file(fp, download_name=doc['original_filename'], as_attachment=True)
    else:
        # 分享者（查詢模式）→ 依副檔名決定是否轉 PDF 加浮水印
        resp = download_for_shared_user(doc, user['name'])
        if resp is None:
            flash('實體檔案不存在', 'danger')
            return redirect(url_for('index'))
        return resp


@app.route('/doc/<int:doc_id>/history')
@login_required
def doc_history(doc_id):
    user = current_user()
    doc = query_db('SELECT * FROM documents WHERE id=?', [doc_id], one=True)
    if not doc:
        abort(404)
    versions = query_db('''
        SELECT dv.*, u.name AS creator_name
        FROM document_versions dv
        LEFT JOIN users u ON dv.created_by=u.id
        WHERE dv.document_id=?
        ORDER BY dv.version DESC
    ''', [doc_id])
    return render_template('history.html', user=user,
                           doc=dict(doc), versions=[dict(v) for v in versions])


@app.route('/doc/<int:doc_id>/version/<int:ver_id>/download')
@login_required
def version_download(doc_id, ver_id):
    user = current_user()
    doc = query_db('SELECT * FROM documents WHERE id=?', [doc_id], one=True)
    if not doc or (doc['owner_id'] != user['id'] and not user['is_admin']):
        abort(403)
    ver = query_db('SELECT * FROM document_versions WHERE id=? AND document_id=?',
                   [ver_id, doc_id], one=True)
    if not ver:
        abort(404)
    fp = os.path.join(UPLOAD_FOLDER, ver['stored_filename'])
    if not os.path.exists(fp):
        flash('版本檔案不存在', 'danger')
        return redirect(url_for('doc_history', doc_id=doc_id))
    return send_file(fp, download_name=ver['original_filename'], as_attachment=True)


@app.route('/doc/<int:doc_id>/properties')
@login_required
def doc_properties(doc_id):
    doc = query_db('''
        SELECT d.*, ft.name AS file_type_name, u.name AS owner_name,
               f.name AS folder_name, t.name AS tab_name
        FROM documents d
        LEFT JOIN file_types ft ON d.file_type_id=ft.id
        LEFT JOIN users u ON d.owner_id=u.id
        LEFT JOIN folders f ON d.folder_id=f.id
        LEFT JOIN tabs t ON f.tab_id=t.id
        WHERE d.id=?
    ''', [doc_id], one=True)
    if not doc:
        abort(404)
    return jsonify(dict(doc))


@app.route('/doc/<int:doc_id>/share', methods=['POST'])
@login_required
def doc_share(doc_id):
    user = current_user()
    doc = query_db('SELECT * FROM documents WHERE id=?', [doc_id], one=True)
    if not doc or (doc['owner_id'] != user['id'] and not user['is_admin']):
        return jsonify({'success': False, 'msg': '無權限'})

    action   = request.form.get('action', 'add')
    user_id  = request.form.get('user_id',  type=int)
    group_id = request.form.get('group_id', type=int)
    perm_id  = request.form.get('perm_id',  type=int)
    can_read   = 1 if request.form.get('can_read',   '0') == '1' else 0
    can_edit   = 1 if request.form.get('can_edit',   '0') == '1' else 0
    can_delete = 1 if request.form.get('can_delete', '0') == '1' else 0

    if action == 'remove':
        if perm_id:
            execute_db('DELETE FROM document_permissions WHERE id=? AND document_id=?',
                       [perm_id, doc_id])
        elif user_id:
            execute_db('DELETE FROM document_permissions WHERE document_id=? AND user_id=?',
                       [doc_id, user_id])
        elif group_id:
            execute_db('DELETE FROM document_permissions WHERE document_id=? AND group_id=?',
                       [doc_id, group_id])
    elif action == 'update' and perm_id:
        execute_db('''UPDATE document_permissions
                      SET can_read=?, can_edit=?, can_delete=?
                      WHERE id=? AND document_id=?''',
                   [can_read, can_edit, can_delete, perm_id, doc_id])
    else:  # add
        if user_id:
            ex = query_db('SELECT id FROM document_permissions WHERE document_id=? AND user_id=?',
                          [doc_id, user_id], one=True)
            if not ex:
                execute_db('''INSERT INTO document_permissions
                              (document_id, user_id, can_read, can_edit, can_delete)
                              VALUES (?,?,?,?,?)''',
                           [doc_id, user_id, can_read, can_edit, can_delete])
            else:
                execute_db('''UPDATE document_permissions
                              SET can_read=?, can_edit=?, can_delete=?
                              WHERE document_id=? AND user_id=?''',
                           [can_read, can_edit, can_delete, doc_id, user_id])
        elif group_id:
            ex = query_db('SELECT id FROM document_permissions WHERE document_id=? AND group_id=?',
                          [doc_id, group_id], one=True)
            if not ex:
                execute_db('''INSERT INTO document_permissions
                              (document_id, group_id, can_read, can_edit, can_delete)
                              VALUES (?,?,?,?,?)''',
                           [doc_id, group_id, can_read, can_edit, can_delete])
            else:
                execute_db('''UPDATE document_permissions
                              SET can_read=?, can_edit=?, can_delete=?
                              WHERE document_id=? AND group_id=?''',
                           [can_read, can_edit, can_delete, doc_id, group_id])

    return _doc_share_result(doc_id)


@app.route('/doc/<int:doc_id>/share_list')
@login_required
def doc_share_list(doc_id):
    user = current_user()
    doc = query_db('SELECT * FROM documents WHERE id=?', [doc_id], one=True)
    if not doc or (doc['owner_id'] != user['id'] and not user['is_admin']):
        return jsonify({'success': False, 'msg': '無權限'})
    return _doc_share_result(doc_id)


def _doc_share_result(doc_id):
    perms = query_db('''
        SELECT dp.*, u.name AS user_name, g.name AS group_name
        FROM document_permissions dp
        LEFT JOIN users u ON dp.user_id=u.id
        LEFT JOIN groups_tbl g ON dp.group_id=g.id
        WHERE dp.document_id=?
    ''', [doc_id])
    return jsonify({'success': True, 'permissions': [dict(p) for p in perms]})


@app.route('/doc/<int:doc_id>/change_owner', methods=['POST'])
@login_required
def doc_change_owner(doc_id):
    user = current_user()
    doc = query_db('SELECT * FROM documents WHERE id=?', [doc_id], one=True)
    if not doc or (doc['owner_id'] != user['id'] and not user['is_admin']):
        return jsonify({'success': False, 'msg': '無權限'})
    new_owner_id = request.form.get('new_owner_id', type=int)
    if not new_owner_id:
        return jsonify({'success': False, 'msg': '請選擇新擁有人'})
    if not query_db('SELECT id FROM users WHERE id=?', [new_owner_id], one=True):
        return jsonify({'success': False, 'msg': '使用者不存在'})
    execute_db('UPDATE documents SET owner_id=?, updated_at=CURRENT_TIMESTAMP WHERE id=?',
               [new_owner_id, doc_id])
    return jsonify({'success': True})


@app.route('/doc/<int:doc_id>/send_sign', methods=['POST'])
@login_required
def doc_send_sign(doc_id):
    user = current_user()
    doc = query_db('SELECT * FROM documents WHERE id=?', [doc_id], one=True)
    if not doc or (doc['owner_id'] != user['id'] and not user['is_admin']):
        return jsonify({'success': False, 'msg': '無權限'})
    execute_db("UPDATE documents SET sign_status='pending', updated_at=CURRENT_TIMESTAMP WHERE id=?",
               [doc_id])
    return jsonify({'success': True, 'msg': '單據已送簽'})


# ════════════════════════════════════════════════════════════════
# Search & Export
# ════════════════════════════════════════════════════════════════
@app.route('/search')
@login_required
def search():
    user = current_user()
    q = request.args.get('q', '').strip()
    results = []
    if q:
        uid = user['id']
        is_admin = bool(user['is_admin'])
        if is_admin:
            where_perm = '1=1'
            extra = []
        else:
            where_perm = '''(
                d.owner_id=?
                OR EXISTS (SELECT 1 FROM folders f2
                           JOIN tabs t2 ON f2.tab_id=t2.id
                           WHERE f2.id=d.folder_id AND t2.tab_type='public')
                OR (d.is_locked=0 AND (
                    EXISTS (SELECT 1 FROM document_permissions dp
                            WHERE dp.document_id=d.id AND dp.user_id=?)
                    OR EXISTS (SELECT 1 FROM document_permissions dp
                               JOIN group_members gm ON dp.group_id=gm.group_id
                               WHERE dp.document_id=d.id AND gm.user_id=?)
                ))
            )'''
            extra = [uid, uid, uid]

        results = query_db(f'''
            SELECT d.*, ft.name AS file_type_name, u.name AS owner_name,
                   f.name AS folder_name, t.name AS tab_name
            FROM documents d
            LEFT JOIN file_types ft ON d.file_type_id=ft.id
            LEFT JOIN users u ON d.owner_id=u.id
            LEFT JOIN folders f ON d.folder_id=f.id
            LEFT JOIN tabs t ON f.tab_id=t.id
            WHERE d.is_deleted=0 AND {where_perm}
              AND (d.doc_number LIKE ? OR d.subject LIKE ?
                   OR d.remarks LIKE ? OR f.name LIKE ?)
            ORDER BY d.created_at DESC LIMIT 300
        ''', extra + [f'%{q}%', f'%{q}%', f'%{q}%', f'%{q}%'])

    return render_template('search.html', user=user, q=q,
                           results=[dict(r) for r in results])


@app.route('/export', methods=['POST'])
@login_required
def export_excel():
    if not EXCEL_AVAILABLE:
        flash('openpyxl 未安裝，無法匯出 Excel', 'danger')
        return redirect(url_for('index'))

    user = current_user()
    doc_ids_raw = request.form.get('doc_ids', '')
    if not doc_ids_raw:
        flash('沒有可匯出的資料', 'warning')
        return redirect(url_for('index'))

    doc_ids = [int(x) for x in doc_ids_raw.split(',') if x.strip().isdigit()]
    if not doc_ids:
        flash('沒有可匯出的資料', 'warning')
        return redirect(url_for('index'))

    ph = ','.join('?' * len(doc_ids))
    docs = query_db(f'''
        SELECT d.*, ft.name AS file_type_name, u.name AS owner_name,
               f.name AS folder_name, t.name AS tab_name
        FROM documents d
        LEFT JOIN file_types ft ON d.file_type_id=ft.id
        LEFT JOIN users u ON d.owner_id=u.id
        LEFT JOIN folders f ON d.folder_id=f.id
        LEFT JOIN tabs t ON f.tab_id=t.id
        WHERE d.id IN ({ph}) AND d.is_deleted=0
        ORDER BY d.created_at DESC
    ''', doc_ids)

    wb = openpyxl.Workbook()
    ws = wb.active
    ws.title = '文件清單'

    headers = ['案號', '主旨', '版本', '類型', '部門', '發行日期',
               '擁有人', '資料夾', '頁籤', '狀態', '備註', '建立時間']
    hf = Font(bold=True, color='FFFFFF')
    hfill = PatternFill('solid', fgColor='4472C4')
    ha = Alignment(horizontal='center')

    for ci, h in enumerate(headers, 1):
        cell = ws.cell(row=1, column=ci, value=h)
        cell.font = hf
        cell.fill = hfill
        cell.alignment = ha

    status_map = {'': '草稿', 'pending': '待簽核', 'signed': '已簽核'}
    for ri, d in enumerate(docs, 2):
        vals = [d['doc_number'], d['subject'], d['version'],
                d['file_type_name'] or '', d['department'], d['issue_date'],
                d['owner_name'], d['folder_name'] or '', d['tab_name'] or '',
                status_map.get(d['sign_status'] or '', ''),
                d['remarks'], d['created_at']]
        for ci, v in enumerate(vals, 1):
            ws.cell(row=ri, column=ci, value=v)

    for col in ws.columns:
        ml = max((len(str(c.value or '')) for c in col), default=0)
        ws.column_dimensions[col[0].column_letter].width = min(ml + 4, 40)

    buf = io.BytesIO()
    wb.save(buf)
    buf.seek(0)
    fn = f'文件清單_{datetime.now().strftime("%Y%m%d%H%M%S")}.xlsx'
    return send_file(buf,
                     mimetype='application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
                     download_name=fn, as_attachment=True)


# ════════════════════════════════════════════════════════════════
# Batch Import
# ════════════════════════════════════════════════════════════════
@app.route('/batch_import', methods=['GET', 'POST'])
@login_required
def batch_import():
    user = current_user()
    folders = _accessible_folders(user)
    file_types = query_db('SELECT * FROM file_types ORDER BY name')

    if request.method == 'POST':
        folder_id = request.form.get('folder_id', type=int)
        file_type_id = request.form.get('file_type_id') or None
        department = request.form.get('department', user['department']).strip()
        files = request.files.getlist('files')

        if not folder_id:
            flash('請選擇目標資料夾', 'danger')
            return redirect(request.url)

        count = 0
        for f in files:
            if f and f.filename:
                original_filename, stored_filename = save_file(f)
                subject = os.path.splitext(original_filename)[0]
                execute_db('''
                    INSERT INTO documents
                        (doc_number, version, subject, issue_date, file_type_id,
                         department, original_filename, stored_filename, folder_id, owner_id)
                    VALUES (?,1,?,?,?,?,?,?,?,?)
                ''', [gen_doc_number(), subject, date.today().isoformat(),
                      file_type_id, department,
                      original_filename, stored_filename, folder_id, user['id']])
                count += 1

        flash(f'成功轉入 {count} 個文件', 'success')
        return redirect(url_for('index'))

    return render_template('batch_import.html', user=user,
                           folders=folders, file_types=file_types)


# ════════════════════════════════════════════════════════════════
# Recycle Bin
# ════════════════════════════════════════════════════════════════
@app.route('/recycle')
@login_required
def recycle():
    user = current_user()
    if user['is_admin']:
        docs = query_db('''
            SELECT d.*, u.name AS owner_name, f.name AS folder_name
            FROM documents d
            LEFT JOIN users u ON d.owner_id=u.id
            LEFT JOIN folders f ON d.folder_id=f.id
            WHERE d.is_deleted=1 ORDER BY d.updated_at DESC
        ''')
    else:
        docs = query_db('''
            SELECT d.*, u.name AS owner_name, f.name AS folder_name
            FROM documents d
            LEFT JOIN users u ON d.owner_id=u.id
            LEFT JOIN folders f ON d.folder_id=f.id
            WHERE d.is_deleted=1 AND d.owner_id=?
            ORDER BY d.updated_at DESC
        ''', [user['id']])
    return render_template('recycle.html', user=user, docs=[dict(d) for d in docs])


@app.route('/recycle/<int:doc_id>/restore', methods=['POST'])
@login_required
def recycle_restore(doc_id):
    user = current_user()
    doc = query_db('SELECT * FROM documents WHERE id=? AND is_deleted=1', [doc_id], one=True)
    if not doc or (doc['owner_id'] != user['id'] and not user['is_admin']):
        return jsonify({'success': False, 'msg': '無權限'})
    execute_db('UPDATE documents SET is_deleted=0, updated_at=CURRENT_TIMESTAMP WHERE id=?',
               [doc_id])
    return jsonify({'success': True})


@app.route('/recycle/<int:doc_id>/purge', methods=['POST'])
@login_required
def recycle_purge(doc_id):
    user = current_user()
    doc = query_db('SELECT * FROM documents WHERE id=? AND is_deleted=1', [doc_id], one=True)
    if not doc or (doc['owner_id'] != user['id'] and not user['is_admin']):
        return jsonify({'success': False, 'msg': '無權限'})
    for fp_col in ['stored_filename']:
        sf = doc[fp_col]
        if sf:
            fp = os.path.join(UPLOAD_FOLDER, sf)
            if os.path.exists(fp):
                os.remove(fp)
    for ver in query_db('SELECT stored_filename FROM document_versions WHERE document_id=?', [doc_id]):
        if ver['stored_filename']:
            fp = os.path.join(UPLOAD_FOLDER, ver['stored_filename'])
            if os.path.exists(fp):
                os.remove(fp)
    execute_db('DELETE FROM document_versions WHERE document_id=?', [doc_id])
    execute_db('DELETE FROM document_permissions WHERE document_id=?', [doc_id])
    execute_db('DELETE FROM documents WHERE id=?', [doc_id])
    return jsonify({'success': True})


# ════════════════════════════════════════════════════════════════
# Admin
# ════════════════════════════════════════════════════════════════
@app.route('/admin/settings')
@admin_required
def admin_settings():
    user = current_user()
    return render_template('admin/settings.html', user=user)


@app.route('/admin/file_types', methods=['GET', 'POST'])
@admin_required
def admin_file_types():
    user = current_user()
    if request.method == 'POST':
        action = request.form.get('action')
        if action == 'add':
            code = request.form.get('code', '').strip()
            name = request.form.get('name', '').strip()
            desc = request.form.get('description', '').strip()
            if code and name:
                try:
                    execute_db('INSERT INTO file_types (code, name, description) VALUES (?,?,?)',
                               [code, name, desc])
                    flash('新增成功', 'success')
                except Exception:
                    flash('代碼已存在', 'danger')
        elif action == 'edit':
            fid = request.form.get('id', type=int)
            name = request.form.get('name', '').strip()
            desc = request.form.get('description', '').strip()
            execute_db('UPDATE file_types SET name=?, description=? WHERE id=?', [name, desc, fid])
            flash('更新成功', 'success')
        elif action == 'delete':
            fid = request.form.get('id', type=int)
            execute_db('DELETE FROM file_types WHERE id=?', [fid])
            flash('刪除成功', 'success')
        return redirect(url_for('admin_file_types'))
    file_types = query_db('SELECT * FROM file_types ORDER BY code')
    return render_template('admin/file_types.html', user=user, file_types=file_types)


@app.route('/admin/groups', methods=['GET', 'POST'])
@admin_required
def admin_groups():
    user = current_user()
    if request.method == 'POST':
        action = request.form.get('action')
        if action == 'add':
            name = request.form.get('name', '').strip()
            desc = request.form.get('description', '').strip()
            if name:
                execute_db('INSERT INTO groups_tbl (name, description) VALUES (?,?)', [name, desc])
                flash('群組新增成功', 'success')
        elif action == 'edit':
            gid = request.form.get('id', type=int)
            name = request.form.get('name', '').strip()
            desc = request.form.get('description', '').strip()
            execute_db('UPDATE groups_tbl SET name=?, description=? WHERE id=?', [name, desc, gid])
            flash('更新成功', 'success')
        elif action == 'delete':
            gid = request.form.get('id', type=int)
            execute_db('DELETE FROM group_members WHERE group_id=?', [gid])
            execute_db('DELETE FROM groups_tbl WHERE id=?', [gid])
            flash('刪除成功', 'success')
        elif action == 'add_member':
            gid = request.form.get('group_id', type=int)
            uid = request.form.get('user_id', type=int)
            ex = query_db('SELECT 1 FROM group_members WHERE group_id=? AND user_id=?',
                          [gid, uid], one=True)
            if not ex:
                execute_db('INSERT INTO group_members (group_id, user_id) VALUES (?,?)', [gid, uid])
                flash('成員新增成功', 'success')
            else:
                flash('已是成員', 'info')
        elif action == 'remove_member':
            gid = request.form.get('group_id', type=int)
            uid = request.form.get('user_id', type=int)
            execute_db('DELETE FROM group_members WHERE group_id=? AND user_id=?', [gid, uid])
            flash('成員移除成功', 'success')
        return redirect(url_for('admin_groups'))

    groups = query_db('SELECT * FROM groups_tbl ORDER BY name')
    group_list = []
    for g in groups:
        members = query_db('''
            SELECT u.id, u.name, u.username, u.department
            FROM users u JOIN group_members gm ON u.id=gm.user_id
            WHERE gm.group_id=?
        ''', [g['id']])
        item = dict(g)
        item['members'] = [dict(m) for m in members]
        group_list.append(item)
    all_users = query_db('SELECT id, name, username, department FROM users ORDER BY name')
    return render_template('admin/groups.html', user=user,
                           groups=group_list, all_users=all_users)


@app.route('/admin/change_owner', methods=['GET', 'POST'])
@admin_required
def admin_change_owner():
    user = current_user()
    if request.method == 'POST':
        from_uid = request.form.get('from_user_id', type=int)
        to_uid = request.form.get('to_user_id', type=int)
        if from_uid and to_uid and from_uid != to_uid:
            cnt = query_db('SELECT COUNT(*) AS c FROM documents WHERE owner_id=? AND is_deleted=0',
                           [from_uid], one=True)
            execute_db('UPDATE documents SET owner_id=? WHERE owner_id=?', [to_uid, from_uid])
            execute_db('UPDATE folders SET owner_id=? WHERE owner_id=?', [to_uid, from_uid])
            execute_db('UPDATE tabs SET owner_id=? WHERE owner_id=?', [to_uid, from_uid])
            flash(f'已移轉 {cnt["c"]} 筆文件給新擁有人', 'success')
        else:
            flash('請選擇兩個不同的使用者', 'danger')
        return redirect(url_for('admin_change_owner'))
    all_users = query_db('SELECT id, name, username, department FROM users ORDER BY name')
    return render_template('admin/change_owner.html', user=user, all_users=all_users)


@app.route('/admin/users')
@admin_required
def admin_users():
    user = current_user()
    users = query_db('SELECT * FROM users ORDER BY name')
    return render_template('admin/users.html', user=user, users=users)


@app.route('/admin/users/new', methods=['GET', 'POST'])
@admin_required
def admin_user_new():
    user = current_user()
    if request.method == 'POST':
        username = request.form.get('username', '').strip()
        password = request.form.get('password', '').strip()
        name = request.form.get('name', '').strip()
        department = request.form.get('department', '').strip()
        email = request.form.get('email', '').strip()
        is_admin = 1 if request.form.get('is_admin') else 0
        if not username or not password or not name:
            flash('帳號、密碼、姓名為必填', 'danger')
        else:
            try:
                execute_db(
                    'INSERT INTO users (username, password_hash, name, department, email, is_admin) VALUES (?,?,?,?,?,?)',
                    [username, generate_password_hash(password), name, department, email, is_admin]
                )
                flash('使用者新增成功', 'success')
                return redirect(url_for('admin_users'))
            except Exception:
                flash('帳號已存在', 'danger')
    return render_template('admin/user_form.html', user=user, edit_user=None)


@app.route('/admin/users/<int:uid>/edit', methods=['GET', 'POST'])
@admin_required
def admin_user_edit(uid):
    user = current_user()
    edit_user = query_db('SELECT * FROM users WHERE id=?', [uid], one=True)
    if not edit_user:
        abort(404)
    if request.method == 'POST':
        name = request.form.get('name', '').strip()
        department = request.form.get('department', '').strip()
        email = request.form.get('email', '').strip()
        is_admin = 1 if request.form.get('is_admin') else 0
        password = request.form.get('password', '').strip()
        if password:
            execute_db(
                'UPDATE users SET name=?, department=?, email=?, is_admin=?, password_hash=? WHERE id=?',
                [name, department, email, is_admin, generate_password_hash(password), uid]
            )
        else:
            execute_db(
                'UPDATE users SET name=?, department=?, email=?, is_admin=? WHERE id=?',
                [name, department, email, is_admin, uid]
            )
        flash('使用者更新成功', 'success')
        return redirect(url_for('admin_users'))
    return render_template('admin/user_form.html', user=user, edit_user=dict(edit_user))


# ════════════════════════════════════════════════════════════════
# Admin — 下載稽核紀錄
# ════════════════════════════════════════════════════════════════
@app.route('/admin/download_logs')
@admin_required
def admin_download_logs():
    user = current_user()
    filter_user      = request.args.get('user_name',  '').strip()
    filter_doc       = request.args.get('subject',    '').strip()
    filter_date_from = request.args.get('date_from',  '').strip()
    filter_date_to   = request.args.get('date_to',    '').strip()

    sql    = 'SELECT * FROM download_logs WHERE 1=1'
    params = []
    if filter_user:
        sql += ' AND user_name LIKE ?'
        params.append(f'%{filter_user}%')
    if filter_doc:
        sql += ' AND (subject LIKE ? OR doc_number LIKE ?)'
        params.extend([f'%{filter_doc}%', f'%{filter_doc}%'])
    if filter_date_from:
        sql += ' AND DATE(downloaded_at) >= ?'
        params.append(filter_date_from)
    if filter_date_to:
        sql += ' AND DATE(downloaded_at) <= ?'
        params.append(filter_date_to)
    sql += ' ORDER BY downloaded_at DESC LIMIT 500'

    logs      = query_db(sql, params)
    all_users = query_db('SELECT DISTINCT user_name FROM download_logs ORDER BY user_name')

    return render_template('admin/download_logs.html',
        user=user, logs=[dict(l) for l in logs],
        all_users=[r['user_name'] for r in all_users],
        filter_user=filter_user, filter_doc=filter_doc,
        filter_date_from=filter_date_from, filter_date_to=filter_date_to)


# ════════════════════════════════════════════════════════════════
# Enter Password (for encrypted files)
# ════════════════════════════════════════════════════════════════
@app.route('/doc/<int:doc_id>/enter_password')
@login_required
def enter_password(doc_id):
    user = current_user()
    doc = query_db('SELECT * FROM documents WHERE id=?', [doc_id], one=True)
    if not doc:
        abort(404)
    return render_template('enter_password.html', user=user, doc_id=doc_id,
                           subject=doc['subject'])


# ════════════════════════════════════════════════════════════════
# Init & Run
# ════════════════════════════════════════════════════════════════
if __name__ == '__main__':
    init_db()   # idempotent — uses IF NOT EXISTS; also fixes admin hash if needed
    app.run(debug=True, host='0.0.0.0', port=5100)

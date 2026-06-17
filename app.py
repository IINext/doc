# ============================================================
# 文件管理系統 app.py
# ============================================================
import os
import io
import uuid
import threading
import urllib.request
import urllib.error
import json as _json
from datetime import date, datetime
from functools import wraps

import psycopg2
import psycopg2.extras

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

try:
    import fitz  # PyMuPDF
    PYMUPDF_AVAILABLE = True
except ImportError:
    PYMUPDF_AVAILABLE = False

# ── App Config ────────────────────────────────────────────────
app = Flask(__name__)
app.secret_key = os.environ.get('SECRET_KEY', 'doc-manager-secret-2024')

BASE_DIR    = os.path.dirname(os.path.abspath(__file__))
UPLOAD_FOLDER = os.path.join(BASE_DIR, 'uploads')
COMPANY_NAME = '企業'

PG_DSN = os.environ.get(
    'PG_DSN',
    'host=localhost port=5432 dbname=company_db user=postgres password=Ron@ld7057'
)

# 可透過 LibreOffice 轉換成 PDF 的副檔名（查詢下載時才加浮水印）
CONVERTIBLE_EXTS = {
    '.doc', '.docx', '.odt', '.rtf',          # Word 類
    '.xls', '.xlsx', '.ods', '.csv',           # Excel 類
    '.ppt', '.pptx', '.odp',                   # PowerPoint 類
    '.txt',                                    # 純文字
}

# 查詢權限下載時需轉 PDF 並加浮水印的副檔名（Word / PowerPoint）
WATERMARK_EXTS = {
    '.doc', '.docx', '.odt', '.rtf',          # Word 類
    '.ppt', '.pptx', '.pps', '.ppsx', '.odp', # PowerPoint 類
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
def _pg_sql(sql):
    """將 SQLite 的 ? 佔位符轉換為 PostgreSQL 的 %s。"""
    return sql.replace('?', '%s')


def get_db():
    db = getattr(g, '_database', None)
    if db is not None:
        # 檢查連線是否仍然有效（closed=0 表示正常）
        if db.closed:
            db = None
        else:
            try:
                db.cursor().execute('SELECT 1')
            except Exception:
                try:
                    db.close()
                except Exception:
                    pass
                db = None
    if db is None:
        db = g._database = psycopg2.connect(
            PG_DSN,
            cursor_factory=psycopg2.extras.RealDictCursor
        )
        db.autocommit = False
    return db


@app.teardown_appcontext
def close_db(exc):
    db = getattr(g, '_database', None)
    if db is not None:
        if exc:
            db.rollback()
        db.close()


def _normalize_row(row):
    """將 psycopg2 RealDictRow 中的 datetime/date 轉為字串，供 Jinja2 template [:16] 切片使用。"""
    from datetime import datetime as _dt, date as _d
    if row is None:
        return None
    d = dict(row)
    for k, v in d.items():
        if isinstance(v, _dt):
            d[k] = v.strftime('%Y-%m-%d %H:%M:%S')
        elif isinstance(v, _d):
            d[k] = v.isoformat()
    return d


def query_db(sql, args=(), one=False):
    cur = get_db().cursor()
    cur.execute(_pg_sql(sql), args)
    rv = [_normalize_row(r) for r in cur.fetchall()]
    return (rv[0] if rv else None) if one else rv


def execute_db(sql, args=()):
    db = get_db()
    cur = db.cursor()
    sql_pg = _pg_sql(sql).strip()
    # INSERT 語句加 RETURNING id 以取得自動產生的主鍵
    if sql_pg.upper().startswith('INSERT') and 'RETURNING' not in sql_pg.upper():
        sql_pg += ' RETURNING id'
        cur.execute(sql_pg, args)
        row = cur.fetchone()
        db.commit()
        return row['id'] if row else None
    else:
        cur.execute(sql_pg, args)
        db.commit()
        return None


# ════════════════════════════════════════════════════════════════
# 即時通 通知 API 設定
# ════════════════════════════════════════════════════════════════
CHAT_API_URL    = os.environ.get('CHAT_API_URL',    'https://localhost:5003/api/v1/send')
CHAT_API_KEY    = os.environ.get('CHAT_API_KEY',    'sk_uNsAbqRTx2tPwTxZj56ZCUcSFg-AMVS7OqrkYyOQ2DE')
PUBLIC_BASE_URL = os.environ.get('PUBLIC_BASE_URL', 'https://doc.mobime.tw')


def _workflow_url(doc_id: int) -> str:
    """回傳可從外部瀏覽器開啟的簽核頁面網址。"""
    return f'{PUBLIC_BASE_URL.rstrip("/")}/doc/{doc_id}/workflow'


def _do_notify(target_username: str, message: str):
    """背景執行緒送出即時通通知，失敗不影響主流程。"""
    import ssl as _ssl
    try:
        payload = _json.dumps({
            'target_type':    'user',
            'target_username': target_username,
            'message':        message,
            'sender_name':    '文件管理系統',
        }).encode('utf-8')
        req = urllib.request.Request(
            CHAT_API_URL,
            data=payload,
            headers={'Content-Type': 'application/json', 'X-API-Key': CHAT_API_KEY},
            method='POST',
        )
        # 即時通使用自簽憑證，跳過 TLS 驗證
        ctx = _ssl.create_default_context()
        ctx.check_hostname = False
        ctx.verify_mode = _ssl.CERT_NONE
        urllib.request.urlopen(req, timeout=5, context=ctx)
    except Exception as e:
        app.logger.warning(f'[notify] 無法送出通知給 {target_username}：{e}')


def notify(target_username: str, message: str):
    """非同步發送即時通通知（不阻塞請求）。"""
    if not target_username:
        return
    threading.Thread(target=_do_notify, args=(target_username, message), daemon=True).start()


def _row_to_dict(row):
    """將 psycopg2 RealDictRow 轉為純 dict，並把 datetime/date 物件轉為 ISO 字串。"""
    from datetime import datetime, date
    if row is None:
        return None
    d = dict(row)
    for k, v in d.items():
        if isinstance(v, datetime):
            d[k] = v.strftime('%Y-%m-%d %H:%M:%S')
        elif isinstance(v, date):
            d[k] = v.isoformat()
    return d


# ════════════════════════════════════════════════════════════════
# ISO 9001:2015 — 稽核日誌常數與輔助函式
# ════════════════════════════════════════════════════════════════
ACTION = {
    'CREATE':        'doc_created',
    'EDIT':          'doc_edited',
    'DELETE':        'doc_deleted',
    'RESTORE':       'doc_restored',
    'DOWNLOAD':      'doc_downloaded',
    'LOCK':          'doc_locked',
    'UNLOCK':        'doc_unlocked',
    'VERSION_BUMP':  'doc_version_bump',
    'WF_SUBMIT':     'workflow_submitted',
    'WF_REVIEW':     'workflow_reviewed',
    'WF_APPROVE':    'workflow_approved',
    'WF_REJECT':     'workflow_rejected',
    'WF_WITHDRAW':   'workflow_withdrawn',
    'STATUS_CHANGE': 'doc_status_changed',
    'SUPERSEDE':     'doc_superseded',
    'ARCHIVE':       'doc_archived',
    'PERM_CHANGE':   'permission_changed',
}

DOC_STATUS_LABEL = {
    'draft':       '草稿',
    'in_review':   '審核中',
    'released':    '已發行',
    'superseded':  '已取代',
    'archived':    '已封存',
}


def log_action(action, doc=None, details=''):
    """寫入一筆稽核日誌到 audit_log 表。"""
    try:
        user_id   = session.get('user_id', 0)
        user_name = session.get('user_name', '')
        doc_id     = doc['id']     if doc else None
        doc_number = doc['doc_number'] if doc else ''
        ip = ''
        try:
            ip = request.remote_addr or ''
        except RuntimeError:
            pass
        execute_db(
            '''INSERT INTO audit_log
                   (doc_id, doc_number, action, actor_id, actor_name, details, ip_address)
               VALUES (?,?,?,?,?,?,?)''',
            [doc_id, doc_number, action, user_id, user_name, details, ip]
        )
    except Exception:
        pass  # 稽核日誌失敗不應中斷主流程


def init_db():
    """確保 PostgreSQL schema 存在（冪等）。"""
    with app.app_context():
        schema_path = os.path.join(os.path.dirname(BASE_DIR), '共用資料庫', 'pg_schema.sql')
        if not os.path.exists(schema_path):
            return  # schema 已由 migrate_to_pg.py 建立
        db = get_db()
        cur = db.cursor()
        with open(schema_path, encoding='utf-8') as f:
            cur.execute(f.read())
        db.commit()


def migrate_db():
    """執行增量 schema 變更（冪等）。使用獨立 psycopg2 連線，不依賴 Flask request context。"""
    try:
        conn = psycopg2.connect(PG_DSN)
        conn.autocommit = False
        cur = conn.cursor()

        # 1. 加 default_template_id 欄位到 file_types
        try:
            cur.execute(
                'ALTER TABLE file_types ADD COLUMN default_template_id INTEGER REFERENCES workflow_templates(id) ON DELETE SET NULL'
            )
            conn.commit()
        except Exception:
            conn.rollback()  # 欄位已存在，忽略

        # 2. 把舊的 workflow_templates.file_type_id 資料遷移過來
        try:
            cur.execute('''
                UPDATE file_types ft
                SET default_template_id = sub.wt_id
                FROM (
                    SELECT wt.file_type_id AS ft_id, MIN(wt.id) AS wt_id
                    FROM workflow_templates wt
                    WHERE wt.file_type_id IS NOT NULL AND wt.is_active = TRUE
                    GROUP BY wt.file_type_id
                ) sub
                WHERE ft.id = sub.ft_id AND ft.default_template_id IS NULL
            ''')
            conn.commit()
        except Exception:
            conn.rollback()

        conn.close()
    except Exception:
        pass

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
    # PostgreSQL 不支援 `col IS %s`（只有 IS NULL / IS NOT NULL）
    # 須依 parent_id 是否為 None 分別使用不同 SQL
    if parent_id is None:
        folders = query_db(
            'SELECT * FROM folders WHERE tab_id=? AND parent_id IS NULL ORDER BY order_no, name',
            [tab_id]
        )
    else:
        folders = query_db(
            'SELECT * FROM folders WHERE tab_id=? AND parent_id=? ORDER BY order_no, name',
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
def _build_watermark_page(user_name, width=None, height=None):
    """以 reportlab 建立一頁僅含浮水印文字的 PDF BytesIO（pypdf fallback 用）。"""
    buf = io.BytesIO()
    if not REPORTLAB_AVAILABLE:
        return buf
    if width is None or height is None:
        width, height = A4
    c = rl_canvas.Canvas(buf, pagesize=(width, height))
    w, h = width, height
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


def _find_cjk_font():
    """搜尋系統上可用的中文 TTF/TTC 字型路徑。"""
    candidates = [
        r'C:\Windows\Fonts\msyh.ttc',       # 微軟正黑體
        r'C:\Windows\Fonts\msjh.ttc',
        r'C:\Windows\Fonts\simsun.ttc',      # 新細明體
        r'C:\Windows\Fonts\mingliu.ttc',
        r'C:\Windows\Fonts\kaiu.ttf',        # 標楷體
        r'/usr/share/fonts/opentype/noto/NotoSansCJK-Regular.ttc',
        r'/usr/share/fonts/truetype/arphic/uming.ttc',
        r'/System/Library/Fonts/PingFang.ttc',
    ]
    for fp in candidates:
        if os.path.exists(fp):
            return fp
    return None


def _overlay_watermark(src_pdf_path, user_name):
    """將浮水印疊加到現有 PDF 的每一頁，回傳 BytesIO。

    方案 A（PyMuPDF + reportlab）：
      - PyMuPDF 負責逐頁輸出，show_pdf_page 疊加；
        reportlab 負責建立中文浮水印頁（透明底色 + 中文字）。
      - 可正確處理旋轉頁、複雜排版，不受 pypdf merge_page 限制。
    方案 B（pypdf + reportlab fallback）：
      - 未安裝 PyMuPDF 時使用。
    """
    # ── 方案 A：PyMuPDF + reportlab ──────────────────────────────
    if PYMUPDF_AVAILABLE and REPORTLAB_AVAILABLE:
        out = io.BytesIO()
        try:
            src_doc = fitz.open(src_pdf_path)
            out_doc = fitz.open()

            for pno in range(len(src_doc)):
                sp   = src_doc[pno]
                pw   = sp.rect.width       # PyMuPDF rect 已考慮旋轉，是實際顯示尺寸
                ph   = sp.rect.height

                # 建立同尺寸輸出頁
                op = out_doc.new_page(width=pw, height=ph)

                # 第一層：原始頁面
                op.show_pdf_page(op.rect, src_doc, pno)

                # 第二層：浮水印（reportlab 產生，透明底色 + 中文字）
                wm_buf = _build_watermark_page(user_name, pw, ph)
                wm_doc = fitz.open(stream=wm_buf.getvalue(), filetype='pdf')
                op.show_pdf_page(op.rect, wm_doc, 0, overlay=True)
                wm_doc.close()

            pdf_bytes = out_doc.tobytes(garbage=4, deflate=True)
            out = io.BytesIO(pdf_bytes)
            out.seek(0)
            src_doc.close()
            out_doc.close()
        except Exception:
            out = io.BytesIO()
        return out

    # ── 方案 B：pypdf + reportlab（fallback）────────────────────
    out = io.BytesIO()
    if not (REPORTLAB_AVAILABLE and PYPDF_AVAILABLE):
        return out
    try:
        reader = PdfReader(src_pdf_path)
        writer = PdfWriter()
        for page in reader.pages:
            try:
                pw = float(page.mediabox.width)
                ph = float(page.mediabox.height)
                wm_buf = _build_watermark_page(user_name, pw, ph)
                wm_page = PdfReader(wm_buf).pages[0]
                page.merge_page(wm_page)
            except Exception:
                pass
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
    - Word / PowerPoint → LibreOffice 轉 PDF + 浮水印疊加
    - PDF 原檔 → 直接疊加浮水印
    - 其他（Excel、圖片、壓縮檔…）→ 直接給原檔，不加浮水印
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

    if ext in WATERMARK_EXTS:
        # Word / PowerPoint：先轉 PDF，再疊加浮水印
        pdf_path = _libreoffice_to_pdf(src_path)
        if pdf_path:
            buf = _overlay_watermark(pdf_path, user_name)
            if buf.getbuffer().nbytes > 0:
                return send_file(buf, mimetype='application/pdf',
                                 download_name=f"{doc['doc_number']}_浮水印.pdf",
                                 as_attachment=True)
        # 轉換失敗 → 原檔
        return send_file(src_path, download_name=doc['original_filename'], as_attachment=True)

    # Excel、圖片、ZIP 等其他類型 → 原檔，不加浮水印
    return send_file(src_path, download_name=doc['original_filename'], as_attachment=True)

# ════════════════════════════════════════════════════════════════
# Landing Page
# ════════════════════════════════════════════════════════════════
@app.route('/landing')
def landing():
    return render_template('landing.html')


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
        pw_ok = False
        if user:
            h = user['password_hash'] or ''
            try:
                pw_ok = check_password_hash(h, password)
            except (ValueError, Exception):
                # 相容即時通產生的 bcrypt 格式 ($2b$...)
                if h.startswith('$2b$') or h.startswith('$2a$'):
                    try:
                        from passlib.context import CryptContext
                        _bcrypt_ctx = CryptContext(schemes=['bcrypt'], deprecated='auto')
                        pw_ok = _bcrypt_ctx.verify(password, h)
                    except Exception:
                        pw_ok = False
        if pw_ok:
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
    valid_cols = {'doc_number', 'subject', 'version', 'issue_date', 'created_at',
                  'sign_status', 'doc_status'}
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
        return jsonify({'success': False, 'msg': '無權限，只能刪除自己建立的資料夾'})
    # 不允許刪除有作用中文件的資料夾
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
    # 永久清除此資料夾回收夾中的文件（is_deleted=1），解除 FK 約束後再刪資料夾
    trashed = query_db(
        'SELECT stored_filename FROM documents WHERE folder_id=? AND is_deleted=1',
        [folder_id]
    )
    for doc in trashed:
        fn = doc['stored_filename']
        if fn:
            fp = os.path.join(UPLOAD_FOLDER, fn)
            if os.path.exists(fp):
                try:
                    os.remove(fp)
                except OSError:
                    pass
    execute_db('DELETE FROM documents WHERE folder_id=? AND is_deleted=1', [folder_id])
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

    new_id = execute_db('''
        INSERT INTO documents
            (doc_number, version, subject, issue_date, file_type_id,
             department, remarks, is_encrypted, encrypt_password,
             original_filename, stored_filename, folder_id, owner_id,
             doc_status)
        VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,'draft')
    ''', [doc_number, int(version), subject, issue_date, file_type_id,
          department, remarks, is_encrypted, encrypt_password,
          original_filename, stored_filename, folder_id, user['id']])

    new_doc = query_db('SELECT * FROM documents WHERE id=?', [new_id], one=True)
    log_action(ACTION['CREATE'], doc=new_doc)
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

    # ISO 狀態保護：已發行/已封存/已取代的文件不得直接修改
    doc_status = doc['doc_status'] if 'doc_status' in doc.keys() else 'draft'
    if doc_status in ('released', 'superseded', 'archived') and not user['is_admin']:
        flash('已發行／封存的文件無法直接修改，請聯絡管理員退回草稿', 'warning')
        return redirect(url_for('doc_edit', doc_id=doc_id, view=1))
    if doc_status == 'in_review' and not user['is_admin']:
        flash('文件審核中，無法修改；如需變更請先撤回送審', 'warning')
        return redirect(url_for('doc_workflow', doc_id=doc_id))

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

    # POST — 審核中文件禁止修改（管理員除外）
    post_status = doc['doc_status'] if 'doc_status' in doc.keys() else 'draft'
    if post_status == 'in_review' and not user['is_admin']:
        flash('文件審核中，無法修改；如需變更請先撤回送審', 'warning')
        return redirect(url_for('doc_workflow', doc_id=doc_id))

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

    review_due_date = request.form.get('review_due_date') or None
    expiry_date = request.form.get('expiry_date') or None

    was_released = (doc['doc_status'] if 'doc_status' in doc.keys() else 'draft') == 'released'

    new_version = doc['version']
    change_summary_val = request.form.get('change_summary', '').strip()
    if version_bump:
        # 升版時必須填寫變更摘要（ISO 7.5 — 識別變更）
        if not change_summary_val:
            flash('升版時必須填寫「變更摘要」', 'danger')
            execute_db('UPDATE documents SET is_locked=0, locked_by=NULL WHERE id=?', [doc_id])
            return redirect(url_for('doc_edit', doc_id=doc_id))
        # 封存目前版本
        execute_db('''
            INSERT INTO document_versions
                (document_id, version, original_filename, stored_filename, created_by, change_summary)
            VALUES (?,?,?,?,?,?)
        ''', [doc_id, doc['version'], doc['original_filename'], doc['stored_filename'],
              user['id'], change_summary_val])
        new_version = doc['version'] + 1
        log_action(ACTION['VERSION_BUMP'], doc=doc, details=f'版本 {doc["version"]} → {new_version}：{change_summary_val}')

    original_filename = doc['original_filename']
    stored_filename = doc['stored_filename']
    if 'file' in request.files and request.files['file'].filename:
        f = request.files['file']
        original_filename, stored_filename = save_file(f)

    # 升版後若文件原本已發行，新版本需重新核准 → 退回草稿
    new_status = doc['doc_status'] if 'doc_status' in doc.keys() else 'draft'
    if version_bump and was_released:
        new_status = 'draft'
        log_action(ACTION['STATUS_CHANGE'], doc=doc, details='released → draft（升版，待重新送審）')

    execute_db('''
        UPDATE documents
        SET version=?, subject=?, issue_date=?, file_type_id=?,
            department=?, remarks=?, is_encrypted=?, encrypt_password=?,
            original_filename=?, stored_filename=?, folder_id=?,
            review_due_date=?, expiry_date=?,
            doc_status=?,
            is_locked=0, locked_by=NULL,
            updated_at=CURRENT_TIMESTAMP
        WHERE id=?
    ''', [new_version, subject, issue_date, file_type_id,
          department, remarks, is_encrypted, encrypt_password,
          original_filename, stored_filename, folder_id,
          review_due_date, expiry_date, new_status, doc_id])

    log_action(ACTION['EDIT'], doc=doc)

    # 升版且原本已發行 → 提示重新送審
    if version_bump and was_released:
        flash(f'文件已升版至 V{new_version}，因原版本已發行，新版本需重新送審才能生效。', 'warning')
        return redirect(url_for('doc_edit', doc_id=doc_id, view=1))

    flash('文件更新成功', 'success')
    return redirect(url_for('index'))


def _is_public_folder(folder_id):
    """判斷資料夾是否屬於公共頁籤。"""
    row = query_db('''SELECT t.tab_type FROM folders f
                      JOIN tabs t ON f.tab_id=t.id WHERE f.id=?''',
                   [folder_id], one=True)
    return row and row['tab_type'] == 'public'


def _accessible_folders(user):
    """回傳使用者可選擇存放文件的資料夾清單（含父資料夾名稱，用於下拉選單顯示完整路徑）。
    管理員：所有資料夾。
    一般使用者：僅自己個人頁籤下的資料夾（公共頁籤唯讀，不可新增/修改文件）。
    """
    if user['is_admin']:
        return query_db('''
            SELECT f.*, t.name AS tab_name, p.name AS parent_name
            FROM folders f
            JOIN tabs t ON f.tab_id=t.id
            LEFT JOIN folders p ON f.parent_id=p.id
            ORDER BY t.name, COALESCE(p.name,''), f.name
        ''')
    return query_db('''
        SELECT f.*, t.name AS tab_name, p.name AS parent_name
        FROM folders f
        JOIN tabs t ON f.tab_id=t.id
        LEFT JOIN folders p ON f.parent_id=p.id
        WHERE f.owner_id=? AND t.tab_type='personal'
        ORDER BY t.name, COALESCE(p.name,''), f.name
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
    doc_status = doc['doc_status'] if 'doc_status' in doc.keys() else 'draft'
    if doc_status == 'in_review':
        return jsonify({'success': False, 'msg': '審核中的文件無法刪除，請先撤回送審'})
    if doc_status == 'released':
        return jsonify({'success': False, 'msg': '已發行的文件無法刪除，請先封存'})
    if doc['sign_status'] == 'pending':
        return jsonify({'success': False, 'msg': '已送簽的文件無法刪除'})
    execute_db('UPDATE documents SET is_deleted=1, updated_at=CURRENT_TIMESTAMP WHERE id=?',
               [doc_id])
    log_action(ACTION['DELETE'], doc=doc)
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


def _build_sign_record_pdf(doc, workflows):
    """
    用 ReportLab 產生「簽核記錄頁」的 BytesIO PDF。
    包含文件基本資訊 + 所有工作流程的審核步驟明細。
    """
    from reportlab.lib.pagesizes import A4
    from reportlab.lib import colors
    from reportlab.lib.units import mm
    from reportlab.platypus import (SimpleDocTemplate, Table, TableStyle,
                                    Paragraph, Spacer, HRFlowable)
    from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
    from reportlab.lib.enums import TA_CENTER, TA_LEFT

    buf = io.BytesIO()

    # ── 字型設定 ─────────────────────────────────────────────
    font_name = CHINESE_FONT  # 全域已初始化（含中文字型或 Helvetica）

    styles = getSampleStyleSheet()
    title_style = ParagraphStyle('Title', fontName=font_name, fontSize=16,
                                  alignment=TA_CENTER, spaceAfter=4)
    sub_style   = ParagraphStyle('Sub',   fontName=font_name, fontSize=9,
                                  alignment=TA_CENTER, textColor=colors.grey, spaceAfter=12)
    label_style = ParagraphStyle('Label', fontName=font_name, fontSize=9,
                                  textColor=colors.grey)
    normal_style= ParagraphStyle('Normal', fontName=font_name, fontSize=10)
    note_style  = ParagraphStyle('Note',   fontName=font_name, fontSize=8,
                                  textColor=colors.grey, alignment=TA_CENTER)

    story = []

    # ── 標題 ─────────────────────────────────────────────────
    story.append(Paragraph('簽 核 記 錄', title_style))
    story.append(Paragraph(f'ISO 9001:2015 Clause 7.5 — 文件管制稽核用', sub_style))
    story.append(HRFlowable(width='100%', thickness=1, color=colors.HexColor('#dee2e6')))
    story.append(Spacer(1, 6*mm))

    # ── 文件基本資訊 ──────────────────────────────────────────
    status_label = DOC_STATUS_LABEL.get(doc.get('doc_status', 'draft'), doc.get('doc_status', ''))
    info_data = [
        ['案號',   doc['doc_number'],  '版本', str(doc.get('version', 1))],
        ['主旨',   doc['subject'],      '狀態', status_label],
        ['部門',   doc.get('department') or '—',
         '發行日期', str(doc.get('issue_date') or '—')],
    ]
    info_table = Table(info_data, colWidths=[22*mm, 75*mm, 22*mm, 50*mm])
    info_table.setStyle(TableStyle([
        ('FONTNAME',    (0,0), (-1,-1), font_name),
        ('FONTSIZE',    (0,0), (-1,-1), 9),
        ('TEXTCOLOR',   (0,0), (0,-1), colors.grey),
        ('TEXTCOLOR',   (2,0), (2,-1), colors.grey),
        ('FONTNAME',    (0,0), (0,-1), font_name),
        ('FONTNAME',    (2,0), (2,-1), font_name),
        ('BACKGROUND',  (0,0), (0,-1), colors.HexColor('#f8f9fa')),
        ('BACKGROUND',  (2,0), (2,-1), colors.HexColor('#f8f9fa')),
        ('BOX',         (0,0), (-1,-1), 0.5, colors.HexColor('#dee2e6')),
        ('INNERGRID',   (0,0), (-1,-1), 0.3, colors.HexColor('#dee2e6')),
        ('VALIGN',      (0,0), (-1,-1), 'MIDDLE'),
        ('TOPPADDING',  (0,0), (-1,-1), 4),
        ('BOTTOMPADDING',(0,0),(-1,-1), 4),
        ('LEFTPADDING', (0,0), (-1,-1), 6),
    ]))
    story.append(info_table)
    story.append(Spacer(1, 8*mm))

    # ── 各工作流程 ────────────────────────────────────────────
    if not workflows:
        story.append(Paragraph('（本文件尚無簽核記錄）', normal_style))
    else:
        for wf_idx, wf in enumerate(workflows, 1):
            # 流程標頭
            wf_status_map = {'open': '進行中', 'approved': '已核准',
                             'rejected': '已退回', 'withdrawn': '已撤回'}
            wf_status = wf_status_map.get(wf['status'], wf['status'])
            wf_color  = {'approved': colors.HexColor('#d1e7dd'),
                         'rejected': colors.HexColor('#f8d7da'),
                         'withdrawn':colors.HexColor('#fff3cd')}.get(
                             wf['status'], colors.HexColor('#cfe2ff'))

            wf_title = (f'第 {wf_idx} 次送審　'
                        f'送審人：{wf.get("initiator_name","—")}　'
                        f'送審時間：{str(wf.get("initiated_at",""))[:16]}　'
                        f'結果：{wf_status}')
            if wf.get('closed_at'):
                wf_title += f'　結案時間：{str(wf["closed_at"])[:16]}'

            wf_hdr = Table([[wf_title]],
                           colWidths=[169*mm])
            wf_hdr.setStyle(TableStyle([
                ('FONTNAME',     (0,0), (-1,-1), font_name),
                ('FONTSIZE',     (0,0), (-1,-1), 9),
                ('BACKGROUND',   (0,0), (-1,-1), wf_color),
                ('TOPPADDING',   (0,0), (-1,-1), 5),
                ('BOTTOMPADDING',(0,0), (-1,-1), 5),
                ('LEFTPADDING',  (0,0), (-1,-1), 8),
            ]))
            story.append(wf_hdr)

            # 步驟明細表頭
            step_header = ['步驟', '類型', '審核人', '決定', '時間', '意見']
            step_rows   = [step_header]
            steps = wf.get('steps', [])
            if steps:
                for s in steps:
                    stype  = '初審' if s.get('step_type') == 'review' else '核准'
                    status_map = {'pending': '待審', 'approved': '通過', 'rejected': '退回', 'skipped': '略過'}
                    sdecision  = status_map.get(s.get('status',''), s.get('status',''))
                    stime      = str(s.get('acted_at') or '—')[:16]
                    scomment   = s.get('comments') or '—'
                    step_rows.append([
                        str(s.get('step_order', '')),
                        stype,
                        s.get('assignee_name', '—'),
                        sdecision,
                        stime,
                        scomment,
                    ])
            else:
                step_rows.append(['—', '—', '—', '—', '—', '（無步驟記錄）'])

            step_table = Table(step_rows,
                               colWidths=[12*mm, 16*mm, 30*mm, 16*mm, 36*mm, 59*mm])
            step_style = TableStyle([
                ('FONTNAME',     (0,0), (-1,-1), font_name),
                ('FONTSIZE',     (0,0), (-1,-1), 8.5),
                ('BACKGROUND',   (0,0), (-1,0),  colors.HexColor('#e9ecef')),
                ('FONTSIZE',     (0,0), (-1,0),  8.5),
                ('ALIGN',        (0,0), (3,-1),  'CENTER'),
                ('ALIGN',        (4,0), (4,-1),  'CENTER'),
                ('VALIGN',       (0,0), (-1,-1), 'MIDDLE'),
                ('TOPPADDING',   (0,0), (-1,-1), 4),
                ('BOTTOMPADDING',(0,0), (-1,-1), 4),
                ('LEFTPADDING',  (0,0), (-1,-1), 5),
                ('BOX',          (0,0), (-1,-1), 0.5, colors.HexColor('#dee2e6')),
                ('INNERGRID',    (0,0), (-1,-1), 0.3, colors.HexColor('#dee2e6')),
                ('ROWBACKGROUNDS',(0,1),(-1,-1), [colors.white, colors.HexColor('#f8f9fa')]),
            ])
            # 決定欄著色
            for row_i, s in enumerate(steps, 1):
                if s.get('status') == 'approved':
                    step_style.add('TEXTCOLOR', (3, row_i), (3, row_i), colors.HexColor('#146c43'))
                elif s.get('status') == 'rejected':
                    step_style.add('TEXTCOLOR', (3, row_i), (3, row_i), colors.HexColor('#842029'))
            step_table.setStyle(step_style)
            story.append(step_table)
            story.append(Spacer(1, 6*mm))

    # ── 頁尾 ─────────────────────────────────────────────────
    story.append(HRFlowable(width='100%', thickness=0.5, color=colors.HexColor('#dee2e6')))
    story.append(Spacer(1, 3*mm))
    gen_time = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
    story.append(Paragraph(
        f'本記錄由文件管理系統自動產生　產生時間：{gen_time}　'
        f'符合 ISO 9001:2015 第 7.5 條文件化資訊要求',
        note_style))

    doc_obj = SimpleDocTemplate(
        buf, pagesize=A4,
        leftMargin=20*mm, rightMargin=20*mm,
        topMargin=18*mm, bottomMargin=18*mm,
    )
    doc_obj.build(story)
    buf.seek(0)
    return buf


def _append_pdf_pages(base_pdf_path, append_buf):
    """
    將 append_buf（BytesIO PDF）附加到 base_pdf_path 的後面，
    回傳合併後的 BytesIO。若 base 不是有效 PDF 則只回傳 append_buf。
    """
    out = io.BytesIO()
    try:
        if PYMUPDF_AVAILABLE:
            base_doc   = fitz.open(base_pdf_path)
            append_doc = fitz.open(stream=append_buf.read(), filetype='pdf')
            base_doc.insert_pdf(append_doc)
            out.write(base_doc.tobytes(garbage=4, deflate=True))
            base_doc.close()
            append_doc.close()
            out.seek(0)
            return out
        if PYPDF_AVAILABLE:
            writer  = PdfWriter()
            reader1 = PdfReader(base_pdf_path)
            reader2 = PdfReader(append_buf)
            for p in reader1.pages:
                writer.add_page(p)
            for p in reader2.pages:
                writer.add_page(p)
            writer.write(out)
            out.seek(0)
            return out
    except Exception:
        pass
    append_buf.seek(0)
    return append_buf


@app.route('/doc/<int:doc_id>/sign_record_pdf')
@login_required
def doc_sign_record_pdf(doc_id):
    """匯出含簽核記錄的 PDF（稽核用）。"""
    if not REPORTLAB_AVAILABLE:
        flash('ReportLab 未安裝，無法產生 PDF', 'danger')
        return redirect(url_for('doc_workflow', doc_id=doc_id))

    user = current_user()
    doc  = query_db('SELECT * FROM documents WHERE id=? AND is_deleted=0', [doc_id], one=True)
    if not doc:
        abort(404)

    # ── 取得所有歷史工作流程（含步驟） ───────────────────────
    wfs = query_db('''
        SELECT aw.*, u.name AS initiator_name
        FROM approval_workflows aw
        JOIN users u ON aw.initiated_by = u.id
        WHERE aw.document_id = ?
        ORDER BY aw.id
    ''', [doc_id])

    workflows = []
    for wf in wfs:
        steps = query_db('''
            SELECT ws.*, u.name AS assignee_name
            FROM workflow_steps ws
            JOIN users u ON ws.assignee_id = u.id
            WHERE ws.workflow_id = ?
            ORDER BY ws.step_order
        ''', [wf['id']])
        item = dict(wf)
        item['steps'] = [dict(s) for s in steps]
        workflows.append(item)

    # ── 產生簽核記錄 PDF ──────────────────────────────────────
    sign_pdf_buf = _build_sign_record_pdf(dict(doc), workflows)

    # ── 若原檔是 PDF，合併；否則只回傳簽核記錄頁 ─────────────
    doc_path = os.path.join(UPLOAD_FOLDER, doc['stored_filename']) if doc['stored_filename'] else None
    ext      = os.path.splitext(doc['original_filename'] or '')[1].lower()

    if doc_path and os.path.exists(doc_path) and ext == '.pdf':
        combined = _append_pdf_pages(doc_path, sign_pdf_buf)
        filename = f"{doc['doc_number']}_v{doc['version']}_含簽核記錄.pdf"
    else:
        combined = sign_pdf_buf
        filename = f"{doc['doc_number']}_v{doc['version']}_簽核記錄.pdf"

    log_action(ACTION['DOWNLOAD'], doc=doc, details='匯出含簽核記錄 PDF')
    return send_file(combined, mimetype='application/pdf',
                     as_attachment=True, download_name=filename)


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
    log_action(ACTION['DOWNLOAD'], doc=doc, details=_dl_path)
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
        SELECT dv.*, u.name AS creator_name, ua.name AS approved_by_name
        FROM document_versions dv
        LEFT JOIN users u  ON dv.created_by=u.id
        LEFT JOIN users ua ON dv.approved_by=ua.id
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

    log_action(ACTION['PERM_CHANGE'], doc=doc, details=f'action={action}')
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
# ISO 9001:2015 — 審核工作流程
# ════════════════════════════════════════════════════════════════

def _release_document(doc_id, workflow_id):
    """將文件狀態設為已發行，並自動取代同一文件的舊發行版本。"""
    doc = query_db('SELECT * FROM documents WHERE id=?', [doc_id], one=True)
    if not doc:
        return
    # 將目前最新版本的 approved_by/approved_at 填入
    approver_id = session.get('user_id')
    execute_db('''
        UPDATE document_versions
        SET approved_by=?, approved_at=CURRENT_TIMESTAMP
        WHERE document_id=? AND version=?
    ''', [approver_id, doc_id, doc['version']])
    # 更新文件狀態為已發行
    execute_db('''
        UPDATE documents SET doc_status='released', updated_at=CURRENT_TIMESTAMP WHERE id=?
    ''', [doc_id])
    # 關閉工作流程
    execute_db('''
        UPDATE approval_workflows SET status='approved', closed_at=CURRENT_TIMESTAMP WHERE id=?
    ''', [workflow_id])
    log_action(ACTION['WF_APPROVE'], doc=doc, details='文件已核准發行')
    log_action(ACTION['STATUS_CHANGE'], doc=doc, details='draft/in_review → released')


@app.route('/doc/<int:doc_id>/submit_workflow', methods=['POST'])
@login_required
def doc_submit_workflow(doc_id):
    """送審：草稿 → 審核中，建立工作流程與步驟。"""
    user = current_user()
    doc = query_db('SELECT * FROM documents WHERE id=? AND is_deleted=0', [doc_id], one=True)
    if not doc:
        return jsonify({'success': False, 'msg': '文件不存在'})
    if doc['owner_id'] != user['id'] and not user['is_admin']:
        return jsonify({'success': False, 'msg': '無權限送審'})

    doc_status = doc['doc_status'] if 'doc_status' in doc.keys() else 'draft'
    if doc_status not in ('draft',):
        return jsonify({'success': False, 'msg': f'文件目前狀態（{DOC_STATUS_LABEL.get(doc_status, doc_status)}）無法送審'})

    # 已有進行中工作流程時拒絕
    open_wf = query_db(
        "SELECT id FROM approval_workflows WHERE document_id=? AND status='open'",
        [doc_id], one=True
    )
    if open_wf:
        return jsonify({'success': False, 'msg': '已有進行中的審核流程'})

    # 必填驗證（ISO 7.5.1）
    missing = []
    if not doc['subject']:          missing.append('主旨')
    if not doc['issue_date']:       missing.append('發行日期')
    if not doc['file_type_id']:     missing.append('文件類型')
    if not doc['department']:       missing.append('部門')
    if not doc['stored_filename']:  missing.append('附加檔案')
    if missing:
        return jsonify({'success': False,
                        'msg': f'送審前請完善以下欄位：{", ".join(missing)}'})

    # 取得步驟來源：指定範本 → 文件類型對應範本 → 全域預設範本 → 全域角色池
    template_id = request.form.get('template_id', type=int)
    steps_src = []  # list of (step_type, user_id)

    if not template_id:
        doc_file_type_id = doc['file_type_id']
        if doc_file_type_id:
            # 優先找檔案類型設定的預設範本
            type_tmpl = query_db(
                '''SELECT wt.id FROM file_types ft
                   JOIN workflow_templates wt ON ft.default_template_id = wt.id
                   WHERE ft.id=? AND wt.is_active=1''',
                [doc_file_type_id], one=True
            )
            if type_tmpl:
                template_id = type_tmpl['id']
        if not template_id:
            # 再找全域預設範本（is_default=1 且無綁定文件類型）
            default_tmpl = query_db(
                "SELECT id FROM workflow_templates WHERE is_default=1 AND is_active=1 AND file_type_id IS NULL LIMIT 1",
                one=True
            )
            if not default_tmpl:
                # 最後找任一 is_default=1
                default_tmpl = query_db(
                    "SELECT id FROM workflow_templates WHERE is_default=1 AND is_active=1 LIMIT 1",
                    one=True
                )
            if default_tmpl:
                template_id = default_tmpl['id']

    if template_id:
        tmpl = query_db(
            'SELECT * FROM workflow_templates WHERE id=? AND is_active=1',
            [template_id], one=True
        )
        if not tmpl:
            return jsonify({'success': False, 'msg': '指定的簽核範本不存在或已停用'})
        tmpl_steps = query_db(
            'SELECT * FROM workflow_template_steps WHERE template_id=? ORDER BY step_order',
            [template_id]
        )
        if not tmpl_steps:
            return jsonify({'success': False, 'msg': '此簽核範本尚未設定步驟，請至管理設定補充'})
        steps_src = [(s['step_type'], s['user_id']) for s in tmpl_steps]
    else:
        # 回退：使用全域角色池
        reviewers = query_db(
            "SELECT user_id FROM approver_roles WHERE role_type='reviewer' ORDER BY id", []
        )
        approvers = query_db(
            "SELECT user_id FROM approver_roles WHERE role_type='approver' ORDER BY id", []
        )
        if not reviewers and not approvers:
            admins = query_db('SELECT id FROM users WHERE is_admin=1 AND id!=?', [user['id']])
            if not admins:
                return jsonify({'success': False, 'msg': '尚未設定審核人員，亦未選擇簽核範本'})
            approvers = [{'user_id': a['id']} for a in admins]
        steps_src  = [('review', r['user_id']) for r in reviewers]
        steps_src += [('approve', a['user_id']) for a in approvers]

    # 建立工作流程
    wf_id = execute_db(
        'INSERT INTO approval_workflows (document_id, initiated_by, template_id) VALUES (?,?,?)',
        [doc_id, user['id'], template_id]
    )

    for order, (stype, uid) in enumerate(steps_src, 1):
        execute_db(
            '''INSERT INTO workflow_steps (workflow_id, step_order, step_type, assignee_id)
               VALUES (?,?,?,?)''',
            [wf_id, order, stype, uid]
        )

    # 更新文件狀態
    execute_db(
        "UPDATE documents SET doc_status='in_review', updated_at=CURRENT_TIMESTAMP WHERE id=?",
        [doc_id]
    )
    log_action(ACTION['WF_SUBMIT'], doc=doc)
    log_action(ACTION['STATUS_CHANGE'], doc=doc, details='draft → in_review')
    # 通知第一關審核人員
    first_assignees = query_db(
        'SELECT u.username FROM workflow_steps ws JOIN users u ON ws.assignee_id=u.id '
        'WHERE ws.workflow_id=? AND ws.step_order=1', [wf_id]
    )
    doc_title = doc['subject'] or doc['doc_number']
    wf_url = _workflow_url(doc_id)
    for a in first_assignees:
        notify(a['username'], f'【待審核】{doc_title}（{doc["doc_number"]}）需要您審核，請點此開啟簽核畫面：{wf_url}')
    return jsonify({'success': True, 'msg': '已送審，等待審核人員處理'})


@app.route('/doc/<int:doc_id>/workflow')
@login_required
def doc_workflow(doc_id):
    """顯示文件目前的審核工作流程狀態。"""
    user = current_user()
    doc = query_db('SELECT * FROM documents WHERE id=?', [doc_id], one=True)
    if not doc:
        abort(404)

    # 目前進行中的工作流程
    active_wf = query_db(
        "SELECT * FROM approval_workflows WHERE document_id=? AND status='open' ORDER BY id DESC LIMIT 1",
        [doc_id], one=True
    )
    active_steps = []
    if active_wf:
        active_steps = query_db('''
            SELECT ws.*, u.name AS assignee_name
            FROM workflow_steps ws
            JOIN users u ON ws.assignee_id=u.id
            WHERE ws.workflow_id=?
            ORDER BY ws.step_order
        ''', [active_wf['id']])

    # 歷史工作流程
    past_wfs = query_db('''
        SELECT aw.*, u.name AS initiator_name
        FROM approval_workflows aw
        JOIN users u ON aw.initiated_by=u.id
        WHERE aw.document_id=? AND aw.status!='open'
        ORDER BY aw.id DESC
    ''', [doc_id])
    past_wf_list = []
    for wf in past_wfs:
        steps = query_db('''
            SELECT ws.*, u.name AS assignee_name
            FROM workflow_steps ws
            JOIN users u ON ws.assignee_id=u.id
            WHERE ws.workflow_id=?
            ORDER BY ws.step_order
        ''', [wf['id']])
        item = _row_to_dict(wf)
        item['steps'] = [_row_to_dict(s) for s in steps]
        past_wf_list.append(item)

    initiator = None
    if active_wf:
        initiator = query_db('SELECT name FROM users WHERE id=?',
                             [active_wf['initiated_by']], one=True)

    return render_template('workflow.html',
                           user=user,
                           doc=_row_to_dict(doc),
                           active_wf=_row_to_dict(active_wf) if active_wf else None,
                           active_steps=[_row_to_dict(s) for s in active_steps],
                           initiator=initiator['name'] if initiator else '',
                           past_wfs=past_wf_list,
                           doc_status_label=DOC_STATUS_LABEL)


@app.route('/doc/<int:doc_id>/workflow/<int:step_id>/act', methods=['POST'])
@login_required
def doc_workflow_act(doc_id, step_id):
    """審核人員執行審核決定（approve 或 reject）。"""
    user = current_user()
    doc = query_db('SELECT * FROM documents WHERE id=?', [doc_id], one=True)
    if not doc:
        return jsonify({'success': False, 'msg': '文件不存在'})

    step = query_db('SELECT * FROM workflow_steps WHERE id=? ', [step_id], one=True)
    if not step:
        return jsonify({'success': False, 'msg': '步驟不存在'})
    if step['assignee_id'] != user['id']:
        return jsonify({'success': False, 'msg': '僅被指定的審核人員可操作此步驟'})
    if step['status'] != 'pending':
        return jsonify({'success': False, 'msg': '此步驟已處理完畢'})

    # 確認前置步驟都已完成（前一關未通過不得操作後一關）
    prior_pending = query_db('''
        SELECT COUNT(*) AS c FROM workflow_steps
        WHERE workflow_id=? AND step_order < ? AND status='pending'
    ''', [step['workflow_id'], step['step_order']], one=True)
    if prior_pending and prior_pending['c'] > 0:
        return jsonify({'success': False, 'msg': '前置審核步驟尚未完成'})

    action_type = request.form.get('action', '')  # 'approve' or 'reject'
    comments = request.form.get('comments', '').strip()
    if action_type not in ('approve', 'reject'):
        return jsonify({'success': False, 'msg': '無效的動作'})

    wf = query_db('SELECT * FROM approval_workflows WHERE id=?',
                  [step['workflow_id']], one=True)
    if not wf or wf['document_id'] != doc_id:
        return jsonify({'success': False, 'msg': '工作流程不符'})

    # 更新此步驟（approve→approved, reject→rejected）
    new_status = 'approved' if action_type == 'approve' else 'rejected'
    execute_db('''
        UPDATE workflow_steps
        SET status=?, comments=?, acted_at=CURRENT_TIMESTAMP
        WHERE id=?
    ''', [new_status, comments, step_id])

    if action_type == 'reject':
        # 拒絕：工作流程關閉，文件退回草稿
        execute_db('''
            UPDATE approval_workflows SET status='rejected', closed_at=CURRENT_TIMESTAMP
            WHERE id=?
        ''', [wf['id']])
        execute_db('''
            UPDATE documents SET doc_status='draft', updated_at=CURRENT_TIMESTAMP WHERE id=?
        ''', [doc_id])
        log_action(ACTION['WF_REJECT'], doc=doc, details=comments)
        log_action(ACTION['STATUS_CHANGE'], doc=doc, details='in_review → draft（拒絕）')
        # 通知申請人
        initiator = query_db('SELECT username FROM users WHERE id=?', [wf['initiated_by']], one=True)
        doc_title = doc['subject'] or doc['doc_number']
        reason = f'（原因：{comments}）' if comments else ''
        if initiator:
            wf_url = _workflow_url(doc_id)
            notify(initiator['username'], f'【審核退回】{doc_title}（{doc["doc_number"]}）已被退回草稿{reason}，請點此查看：{wf_url}')
        return jsonify({'success': True, 'msg': '已退回，文件回到草稿狀態'})

    # 核准：檢查此層是否全數通過，再決定是否推進或發行
    current_order = step['step_order']
    # 同層其他步驟
    same_level = query_db(
        'SELECT * FROM workflow_steps WHERE workflow_id=? AND step_order=?',
        [wf['id'], current_order]
    )
    all_approved = all(s['status'] == 'approved' for s in same_level)

    if not all_approved:
        log_action(ACTION['WF_REVIEW'], doc=doc, details=f'步驟 {current_order} 部分核准')
        return jsonify({'success': True, 'msg': '已核准，等待同層其他審核人員'})

    # 找下一層
    next_step = query_db('''
        SELECT * FROM workflow_steps
        WHERE workflow_id=? AND step_order>? AND status='pending'
        ORDER BY step_order LIMIT 1
    ''', [wf['id'], current_order], one=True)

    doc_title = doc['subject'] or doc['doc_number']
    if next_step:
        log_action(ACTION['WF_REVIEW'], doc=doc, details=f'步驟 {current_order} 全數通過，進入下一步驟')
        # 通知下一關的審核人員
        next_assignees = query_db(
            'SELECT u.username FROM workflow_steps ws JOIN users u ON ws.assignee_id=u.id '
            'WHERE ws.workflow_id=? AND ws.step_order=?', [wf['id'], next_step['step_order']]
        )
        wf_url = _workflow_url(doc_id)
        for a in next_assignees:
            notify(a['username'], f'【待審核】{doc_title}（{doc["doc_number"]}）已通過前置審核，輪到您進行審核，請點此開啟簽核畫面：{wf_url}')
        return jsonify({'success': True, 'msg': '已核准，進入下一審核步驟'})
    else:
        # 所有步驟完成 → 發行文件
        _release_document(doc_id, wf['id'])
        # 通知申請人
        initiator = query_db('SELECT username FROM users WHERE id=?', [wf['initiated_by']], one=True)
        if initiator:
            wf_url = _workflow_url(doc_id)
            notify(initiator['username'], f'【審核通過】{doc_title}（{doc["doc_number"]}）已完成全部審核，文件正式發行。請點此查看：{wf_url}')
        return jsonify({'success': True, 'msg': '審核完成，文件已正式發行'})


@app.route('/doc/<int:doc_id>/workflow/withdraw', methods=['POST'])
@login_required
def doc_workflow_withdraw(doc_id):
    """撤回送審中的工作流程。"""
    user = current_user()
    doc = query_db('SELECT * FROM documents WHERE id=?', [doc_id], one=True)
    if not doc:
        return jsonify({'success': False, 'msg': '文件不存在'})
    if doc['owner_id'] != user['id'] and not user['is_admin']:
        return jsonify({'success': False, 'msg': '無權限'})

    if doc['doc_status'] != 'in_review':
        return jsonify({'success': False, 'msg': '文件不在審核中狀態'})

    wf = query_db(
        "SELECT * FROM approval_workflows WHERE document_id=? AND status='open'",
        [doc_id], one=True
    )
    if wf:
        execute_db('''
            UPDATE approval_workflows SET status='withdrawn', closed_at=CURRENT_TIMESTAMP
            WHERE id=?
        ''', [wf['id']])
    execute_db('''
        UPDATE documents SET doc_status='draft', updated_at=CURRENT_TIMESTAMP WHERE id=?
    ''', [doc_id])
    log_action(ACTION['WF_WITHDRAW'], doc=doc)
    log_action(ACTION['STATUS_CHANGE'], doc=doc, details='in_review → draft（撤回）')
    # 通知尚未處理的審核人員：案件已撤回
    if wf:
        pending_assignees = query_db(
            'SELECT u.username FROM workflow_steps ws JOIN users u ON ws.assignee_id=u.id '
            'WHERE ws.workflow_id=? AND ws.status=\'pending\'', [wf['id']]
        )
        doc_title = doc['subject'] or doc['doc_number']
        for a in pending_assignees:
            notify(a['username'], f'【送審撤回】{doc_title}（{doc["doc_number"]}）已由申請人撤回，無需審核。')
    return jsonify({'success': True, 'msg': '已撤回，文件回到草稿狀態'})



@app.route('/doc/<int:doc_id>/archive', methods=['POST'])
@login_required
def doc_archive(doc_id):
    """封存文件（管理員或擁有者）。"""
    user = current_user()
    doc = query_db('SELECT * FROM documents WHERE id=? AND is_deleted=0', [doc_id], one=True)
    if not doc:
        return jsonify({'success': False, 'msg': '文件不存在'})
    if doc['owner_id'] != user['id'] and not user['is_admin']:
        return jsonify({'success': False, 'msg': '無權限'})
    execute_db('''
        UPDATE documents SET doc_status='archived', updated_at=CURRENT_TIMESTAMP WHERE id=?
    ''', [doc_id])
    log_action(ACTION['ARCHIVE'], doc=doc)
    log_action(ACTION['STATUS_CHANGE'], doc=doc, details='→ archived')
    return jsonify({'success': True, 'msg': '文件已封存'})


@app.route('/doc/<int:doc_id>/notify_expiry', methods=['POST'])
@admin_required
def doc_notify_expiry(doc_id):
    """管理員通知文件擁有者文件即將到期。"""
    doc = query_db('''
        SELECT d.*, u.username AS owner_username, u.name AS owner_name
        FROM documents d LEFT JOIN users u ON d.owner_id=u.id
        WHERE d.id=? AND d.is_deleted=0
    ''', [doc_id], one=True)
    if not doc:
        return jsonify({'success': False, 'msg': '文件不存在'})
    if not doc['owner_username']:
        return jsonify({'success': False, 'msg': '找不到擁有者帳號'})
    expiry = str(doc['expiry_date'] or '')[:10]
    wf_url = _workflow_url(doc_id)
    doc_url = f'{PUBLIC_BASE_URL.rstrip("/")}/doc/{doc_id}/workflow'
    notify(doc['owner_username'],
           f'【到期提醒】文件「{doc["subject"] or doc["doc_number"]}」'
           f'（{doc["doc_number"]}）將於 {expiry} 到期，請儘速處理或封存。'
           f' 查看文件：{doc_url}')
    return jsonify({'success': True, 'msg': f'已通知 {doc["owner_name"]}'})


@app.route('/api/my_pending_count')
@login_required
def api_my_pending_count():
    """回傳目前使用者待審步驟數量（navbar 角標用）。"""
    user = current_user()
    row = query_db('''
        SELECT COUNT(*) AS c
        FROM workflow_steps ws
        JOIN approval_workflows aw ON ws.workflow_id=aw.id
        WHERE ws.assignee_id=? AND ws.status='pending' AND aw.status='open'
    ''', [user['id']], one=True)
    return jsonify({'count': row['c'] if row else 0})


@app.route('/my/tasks')
@login_required
def my_tasks():
    """我的待審任務收件匣。"""
    user = current_user()
    tasks = query_db('''
        SELECT ws.*, aw.document_id, d.doc_number, d.subject, d.doc_status,
               u.name AS initiator_name, aw.initiated_at
        FROM workflow_steps ws
        JOIN approval_workflows aw ON ws.workflow_id=aw.id
        JOIN documents d ON aw.document_id=d.id
        JOIN users u ON aw.initiated_by=u.id
        WHERE ws.assignee_id=? AND ws.status='pending' AND aw.status='open'
        ORDER BY aw.initiated_at ASC
    ''', [user['id']])
    return render_template('my_tasks.html', user=user,
                           tasks=[dict(t) for t in tasks],
                           doc_status_label=DOC_STATUS_LABEL)


# ════════════════════════════════════════════════════════════════
# ISO 9001:2015 — 稽核軌跡
# ════════════════════════════════════════════════════════════════

ACTION_LABEL = {
    'doc_created':        '建立文件',
    'doc_edited':         '修改文件',
    'doc_deleted':        '刪除文件',
    'doc_restored':       '還原文件',
    'doc_downloaded':     '下載文件',
    'doc_locked':         '鎖定文件',
    'doc_unlocked':       '解鎖文件',
    'doc_version_bump':   '升版',
    'workflow_submitted': '送審',
    'workflow_reviewed':  '審核通過（步驟）',
    'workflow_approved':  '最終核准發行',
    'workflow_rejected':  '退回（拒絕）',
    'workflow_withdrawn': '撤回送審',
    'doc_status_changed': '狀態變更',
    'doc_superseded':     '文件被取代',
    'doc_archived':       '封存文件',
    'permission_changed': '授權設定變更',
}


@app.route('/doc/<int:doc_id>/audit_trail')
@login_required
def doc_audit_trail(doc_id):
    """單一文件的稽核軌跡頁面。"""
    user = current_user()
    doc = query_db('SELECT * FROM documents WHERE id=?', [doc_id], one=True)
    if not doc:
        abort(404)
    logs = query_db('''
        SELECT * FROM audit_log WHERE doc_id=?
        ORDER BY logged_at DESC LIMIT 500
    ''', [doc_id])
    return render_template('audit_trail.html',
                           user=user, doc=dict(doc),
                           logs=[dict(l) for l in logs],
                           action_label=ACTION_LABEL)


@app.route('/admin/audit_log')
@admin_required
def admin_audit_log():
    """管理員完整稽核日誌。"""
    user = current_user()
    filter_user   = request.args.get('actor', '').strip()
    filter_doc    = request.args.get('doc', '').strip()
    filter_action = request.args.get('action', '').strip()
    filter_from   = request.args.get('date_from', '').strip()
    filter_to     = request.args.get('date_to', '').strip()
    page          = request.args.get('page', 1, type=int)
    per_page      = 50

    sql    = 'SELECT * FROM audit_log WHERE 1=1'
    params = []
    if filter_user:
        sql += ' AND actor_name LIKE ?'; params.append(f'%{filter_user}%')
    if filter_doc:
        sql += ' AND (doc_number LIKE ? OR doc_id IN (SELECT id FROM documents WHERE subject LIKE ?))'
        params.extend([f'%{filter_doc}%', f'%{filter_doc}%'])
    if filter_action:
        sql += ' AND action=?'; params.append(filter_action)
    if filter_from:
        sql += ' AND DATE(logged_at)>=?'; params.append(filter_from)
    if filter_to:
        sql += ' AND DATE(logged_at)<=?'; params.append(filter_to)

    total_row = query_db(f'SELECT COUNT(*) AS c FROM ({sql})', params, one=True)
    total = total_row['c'] if total_row else 0
    sql += f' ORDER BY logged_at DESC LIMIT {per_page} OFFSET {(page-1)*per_page}'
    logs = query_db(sql, params)

    return render_template('admin/audit_log.html',
                           user=user,
                           logs=[dict(l) for l in logs],
                           action_label=ACTION_LABEL,
                           all_actions=list(ACTION_LABEL.keys()),
                           total=total, page=page, per_page=per_page,
                           filter_user=filter_user, filter_doc=filter_doc,
                           filter_action=filter_action,
                           filter_from=filter_from, filter_to=filter_to)


@app.route('/admin/audit_log/export')
@admin_required
def admin_audit_log_export():
    """匯出稽核日誌為 Excel。"""
    if not EXCEL_AVAILABLE:
        flash('openpyxl 未安裝，無法匯出', 'danger')
        return redirect(url_for('admin_audit_log'))
    logs = query_db('SELECT * FROM audit_log ORDER BY logged_at DESC LIMIT 10000')
    wb = openpyxl.Workbook()
    ws = wb.active
    ws.title = '稽核日誌'
    headers = ['時間', '案號', '動作', '操作者', 'IP', '說明']
    hf = Font(bold=True, color='FFFFFF')
    hfill = PatternFill('solid', fgColor='4472C4')
    for ci, h in enumerate(headers, 1):
        cell = ws.cell(row=1, column=ci, value=h)
        cell.font = hf; cell.fill = hfill
    for ri, l in enumerate(logs, 2):
        ws.cell(row=ri, column=1, value=str(l['logged_at']))
        ws.cell(row=ri, column=2, value=l['doc_number'])
        ws.cell(row=ri, column=3, value=ACTION_LABEL.get(l['action'], l['action']))
        ws.cell(row=ri, column=4, value=l['actor_name'])
        ws.cell(row=ri, column=5, value=l['ip_address'])
        ws.cell(row=ri, column=6, value=l['details'])
    buf = io.BytesIO()
    wb.save(buf); buf.seek(0)
    fn = f'稽核日誌_{datetime.now().strftime("%Y%m%d%H%M%S")}.xlsx'
    return send_file(buf,
                     mimetype='application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
                     download_name=fn, as_attachment=True)


# ════════════════════════════════════════════════════════════════
# ISO 9001:2015 — 審核人員管理
# ════════════════════════════════════════════════════════════════

@app.route('/admin/approvers', methods=['GET', 'POST'])
@admin_required
def admin_approvers():
    user = current_user()
    if request.method == 'POST':
        action   = request.form.get('action', '')
        uid      = request.form.get('user_id', type=int)
        role     = request.form.get('role_type', '')
        if action == 'add' and uid and role in ('reviewer', 'approver'):
            try:
                execute_db(
                    'INSERT INTO approver_roles (user_id, role_type) VALUES (?,?) ON CONFLICT DO NOTHING',
                    [uid, role]
                )
                flash('新增成功', 'success')
            except Exception:
                flash('新增失敗', 'danger')
        elif action == 'remove':
            rid = request.form.get('role_id', type=int)
            execute_db('DELETE FROM approver_roles WHERE id=?', [rid])
            flash('已移除', 'success')
        return redirect(url_for('admin_approvers'))

    reviewers = query_db('''
        SELECT ar.id, ar.role_type, u.id AS user_id, u.name, u.department
        FROM approver_roles ar JOIN users u ON ar.user_id=u.id
        WHERE ar.role_type='reviewer' ORDER BY u.name
    ''')
    approvers = query_db('''
        SELECT ar.id, ar.role_type, u.id AS user_id, u.name, u.department
        FROM approver_roles ar JOIN users u ON ar.user_id=u.id
        WHERE ar.role_type='approver' ORDER BY u.name
    ''')
    all_users = query_db('SELECT id, name, department FROM users ORDER BY name')
    return render_template('admin/approvers.html',
                           user=user,
                           reviewers=[dict(r) for r in reviewers],
                           approvers=[dict(a) for a in approvers],
                           all_users=all_users)


# ════════════════════════════════════════════════════════════════
# ISO 9001:2015 — 簽核流程範本管理
# ════════════════════════════════════════════════════════════════

@app.route('/api/workflow_templates')
@login_required
def api_workflow_templates():
    """回傳啟用中的簽核範本清單（含步驟），供前端選擇用。"""
    tmpls = query_db('SELECT * FROM workflow_templates WHERE is_active=1 ORDER BY name')
    result = []
    for t in tmpls:
        steps = query_db('''
            SELECT wts.*, u.name AS user_name, u.department
            FROM workflow_template_steps wts
            JOIN users u ON wts.user_id=u.id
            WHERE wts.template_id=? ORDER BY wts.step_order
        ''', [t['id']])
        item = dict(t)
        item['steps'] = [dict(s) for s in steps]
        result.append(item)
    return jsonify(result)


@app.route('/admin/workflow_templates', methods=['GET', 'POST'])
@admin_required
def admin_workflow_templates():
    user = current_user()
    if request.method == 'POST':
        action = request.form.get('action', '')

        # ── 範本 CRUD ──
        if action == 'add_template':
            name = request.form.get('name', '').strip()
            desc = request.form.get('description', '').strip()
            if name:
                execute_db(
                    'INSERT INTO workflow_templates (name, description) VALUES (?,?)',
                    [name, desc]
                )
                flash('範本新增成功', 'success')
            else:
                flash('範本名稱不能為空', 'danger')

        elif action == 'set_default':
            tid = request.form.get('template_id', type=int)
            execute_db('UPDATE workflow_templates SET is_default=0', [])
            execute_db('UPDATE workflow_templates SET is_default=1 WHERE id=?', [tid])
            flash('預設範本已設定', 'success')

        elif action == 'edit_template':
            tid  = request.form.get('template_id', type=int)
            name = request.form.get('name', '').strip()
            desc = request.form.get('description', '').strip()
            active = 1 if request.form.get('is_active') else 0
            execute_db(
                'UPDATE workflow_templates SET name=?, description=?, is_active=? WHERE id=?',
                [name, desc, active, tid]
            )
            flash('範本更新成功', 'success')

        elif action == 'delete_template':
            tid = request.form.get('template_id', type=int)
            execute_db('DELETE FROM workflow_templates WHERE id=?', [tid])
            flash('範本已刪除', 'success')

        # ── 步驟 CRUD ──
        elif action == 'add_step':
            tid       = request.form.get('template_id', type=int)
            step_type = request.form.get('step_type', '')
            uid       = request.form.get('user_id', type=int)
            if tid and step_type in ('review', 'approve') and uid:
                # 步驟序號 = 目前最大值 + 1
                row = query_db(
                    'SELECT MAX(step_order) AS m FROM workflow_template_steps WHERE template_id=?',
                    [tid], one=True
                )
                next_order = (row['m'] or 0) + 1
                execute_db(
                    '''INSERT INTO workflow_template_steps
                           (template_id, step_order, step_type, user_id)
                       VALUES (?,?,?,?)''',
                    [tid, next_order, step_type, uid]
                )
                flash('步驟新增成功', 'success')

        elif action == 'delete_step':
            sid = request.form.get('step_id', type=int)
            # 取得所屬範本及 step_order 以重新排序
            step = query_db('SELECT * FROM workflow_template_steps WHERE id=?', [sid], one=True)
            if step:
                execute_db('DELETE FROM workflow_template_steps WHERE id=?', [sid])
                # 重新排序剩餘步驟
                remaining = query_db(
                    'SELECT id FROM workflow_template_steps WHERE template_id=? ORDER BY step_order',
                    [step['template_id']]
                )
                for i, r in enumerate(remaining, 1):
                    execute_db(
                        'UPDATE workflow_template_steps SET step_order=? WHERE id=?',
                        [i, r['id']]
                    )
                flash('步驟已刪除', 'success')

        elif action == 'move_step':
            sid       = request.form.get('step_id', type=int)
            direction = request.form.get('direction', '')  # 'up' or 'down'
            step = query_db('SELECT * FROM workflow_template_steps WHERE id=?', [sid], one=True)
            if step and direction in ('up', 'down'):
                target_order = step['step_order'] + (-1 if direction == 'up' else 1)
                swap = query_db(
                    '''SELECT id FROM workflow_template_steps
                       WHERE template_id=? AND step_order=?''',
                    [step['template_id'], target_order], one=True
                )
                if swap:
                    execute_db(
                        'UPDATE workflow_template_steps SET step_order=? WHERE id=?',
                        [step['step_order'], swap['id']]
                    )
                    execute_db(
                        'UPDATE workflow_template_steps SET step_order=? WHERE id=?',
                        [target_order, sid]
                    )
            flash('順序已調整', 'success')

        return redirect(url_for('admin_workflow_templates'))

    # GET：讀取所有範本及其步驟
    tmpls = query_db('''
        SELECT wt.*, ft.name AS file_type_name
        FROM workflow_templates wt
        LEFT JOIN file_types ft ON wt.file_type_id=ft.id
        ORDER BY wt.name
    ''')
    template_list = []
    for t in tmpls:
        steps = query_db('''
            SELECT wts.*, u.name AS user_name, u.department
            FROM workflow_template_steps wts
            JOIN users u ON wts.user_id=u.id
            WHERE wts.template_id=? ORDER BY wts.step_order
        ''', [t['id']])
        item = dict(t)
        item['steps'] = [dict(s) for s in steps]
        template_list.append(item)

    all_users = query_db('SELECT id, name, department FROM users ORDER BY name')
    file_types = query_db('SELECT id, name FROM file_types ORDER BY name')
    return render_template('admin/workflow_templates.html',
                           user=user,
                           templates=template_list,
                           all_users=all_users,
                           file_types=file_types)


# ════════════════════════════════════════════════════════════════
# ISO 9001:2015 — 到期文件預警
# ════════════════════════════════════════════════════════════════

@app.route('/api/file_type_template')
@login_required
def api_file_type_template():
    """回傳指定檔案類型的預設簽核範本 id（供送審 Modal 自動預選）。"""
    ft_id = request.args.get('file_type_id', type=int)
    if not ft_id:
        return jsonify({'template_id': None})
    row = query_db(
        'SELECT default_template_id FROM file_types WHERE id=?', [ft_id], one=True
    )
    return jsonify({'template_id': row['default_template_id'] if row else None})


@app.route('/api/expiry_count')
@login_required
def api_expiry_count():
    """回傳 30 天內到期文件數量（navbar 角標，管理員用）。"""
    row = query_db('''
        SELECT COUNT(*) AS c FROM documents
        WHERE expiry_date IS NOT NULL
          AND expiry_date::date <= CURRENT_DATE + (30 * INTERVAL '1 day')
          AND doc_status NOT IN ('archived', 'superseded')
          AND is_deleted=0
    ''', one=True)
    return jsonify({'count': row['c'] if row else 0})


@app.route('/admin/expiry_review')
@admin_required
def admin_expiry_review():
    """列出即將到期的文件（預設 30 天，可調整）。"""
    user = current_user()
    days = request.args.get('days', 30, type=int)
    days = max(1, min(days, 365))
    docs = query_db('''
        SELECT d.*, u.name AS owner_name, u.username AS owner_username,
               f.name AS folder_name,
               (d.expiry_date::date - CURRENT_DATE) AS days_left
        FROM documents d
        LEFT JOIN users u ON d.owner_id=u.id
        LEFT JOIN folders f ON d.folder_id=f.id
        WHERE d.expiry_date IS NOT NULL
          AND d.expiry_date::date <= CURRENT_DATE + (? * INTERVAL '1 day')
          AND d.doc_status NOT IN ('archived', 'superseded')
          AND d.is_deleted=0
        ORDER BY d.expiry_date ASC
    ''', [days])
    # 也撈出已逾期（days_left < 0）
    overdue = [d for d in docs if (d['days_left'] or 0) < 0]
    upcoming = [d for d in docs if (d['days_left'] or 0) >= 0]
    return render_template('admin/expiry_review.html',
                           user=user,
                           overdue=overdue,
                           upcoming=upcoming,
                           days=days,
                           doc_status_label=DOC_STATUS_LABEL)


# ════════════════════════════════════════════════════════════════
# ISO 9001:2015 — 舊資料一次性遷移
# ════════════════════════════════════════════════════════════════

@app.route('/admin/migrate_legacy_status', methods=['POST'])
@admin_required
def admin_migrate_legacy_status():
    """將 sign_status 欄位的舊狀態對應到新 doc_status。執行一次即可。"""
    cnt_released = query_db(
        "SELECT COUNT(*) AS c FROM documents WHERE sign_status='signed' AND is_deleted=0",
        [], one=True
    )
    cnt_review = query_db(
        "SELECT COUNT(*) AS c FROM documents WHERE sign_status='pending' AND is_deleted=0",
        [], one=True
    )
    execute_db(
        "UPDATE documents SET doc_status='released' WHERE sign_status='signed' AND is_deleted=0"
    )
    execute_db(
        "UPDATE documents SET doc_status='in_review' WHERE sign_status='pending' AND is_deleted=0"
    )
    r = cnt_released['c'] if cnt_released else 0
    v = cnt_review['c'] if cnt_review else 0
    flash(f'遷移完成：{r} 筆設為已發行，{v} 筆設為審核中', 'success')
    return redirect(url_for('admin_settings'))


# ════════════════════════════════════════════════════════════════
# Search & Export
# ════════════════════════════════════════════════════════════════
@app.route('/search')
@login_required
def search():
    user = current_user()
    q    = request.args.get('q', '').strip()
    dept = request.args.get('dept', '').strip()
    ftype= request.args.get('ftype', '').strip()
    status_f = request.args.get('status', '').strip()
    results  = []
    file_types_list = query_db('SELECT id, name FROM file_types ORDER BY name')

    if q or dept or ftype or status_f:
        uid      = user['id']
        is_admin = bool(user['is_admin'])

        # ── 權限過濾 ──────────────────────────────────────────
        if is_admin:
            where_perm = '1=1'
            params = []
        else:
            where_perm = '''(
                d.owner_id=%s
                OR EXISTS (SELECT 1 FROM folders f2
                           JOIN tabs t2 ON f2.tab_id=t2.id
                           WHERE f2.id=d.folder_id AND t2.tab_type='public')
                OR (d.is_locked=0 AND (
                    EXISTS (SELECT 1 FROM document_permissions dp
                            WHERE dp.document_id=d.id AND dp.user_id=%s)
                    OR EXISTS (SELECT 1 FROM document_permissions dp
                               JOIN group_members gm ON dp.group_id=gm.group_id
                               WHERE dp.document_id=d.id AND gm.user_id=%s)
                ))
            )'''
            params = [uid, uid, uid]

        # ── 全文搜尋條件 ──────────────────────────────────────
        # 策略：ILIKE 做子字串匹配（中文最佳）
        # 注意：params 順序必須對應 SQL 中 %s 出現的位置
        #       SELECT ts_rank %s → WHERE perm %s × n → WHERE search %s
        search_cond   = ''
        search_rank   = '0'
        params_select = []   # SELECT 子句用到的 %s 參數（最先）
        params_search = []   # WHERE search 條件用到的 %s 參數（最後）
        like_val      = f'%{q}%' if q else None

        if q:
            search_cond = '''AND (
                (coalesce(d.doc_number,'') || ' ' || coalesce(d.subject,'') || ' ' ||
                 coalesce(d.remarks,'') || ' ' || coalesce(d.department,'') || ' ' ||
                 coalesce(f.name,'') || ' ' || coalesce(u.name,''))
                ILIKE %s
            )'''
            search_rank   = '1'   # 不用 ts_rank，避免 search_vector 欄位依賴
            params_search = [like_val]

        params = params_select + params + params_search

        # ── 篩選條件 ──────────────────────────────────────────
        filter_cond = ''
        if dept:
            filter_cond += ' AND d.department = %s'
            params.append(dept)
        if ftype:
            filter_cond += ' AND d.file_type_id = %s'
            params.append(ftype)
        if status_f:
            filter_cond += ' AND d.doc_status = %s'
            params.append(status_f)

        results = query_db(f'''
            SELECT d.*,
                   ft.name AS file_type_name,
                   u.name  AS owner_name,
                   f.name  AS folder_name,
                   t.name  AS tab_name,
                   {search_rank} AS relevance
            FROM documents d
            LEFT JOIN file_types ft ON d.file_type_id = ft.id
            LEFT JOIN users      u  ON d.owner_id     = u.id
            LEFT JOIN folders    f  ON d.folder_id    = f.id
            LEFT JOIN tabs       t  ON f.tab_id        = t.id
            WHERE d.is_deleted = 0
              AND {where_perm}
              {search_cond}
              {filter_cond}
            ORDER BY relevance DESC, d.updated_at DESC
            LIMIT 500
        ''', params)

    return render_template('search.html', user=user, q=q,
                           dept=dept, ftype=ftype, status_f=status_f,
                           file_types=file_types_list,
                           doc_status_label=DOC_STATUS_LABEL,
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
               '擁有人', '資料夾', '頁籤', '文件狀態', '備註', '建立時間']
    hf = Font(bold=True, color='FFFFFF')
    hfill = PatternFill('solid', fgColor='4472C4')
    ha = Alignment(horizontal='center')

    for ci, h in enumerate(headers, 1):
        cell = ws.cell(row=1, column=ci, value=h)
        cell.font = hf
        cell.fill = hfill
        cell.alignment = ha

    for ri, d in enumerate(docs, 2):
        raw_status = d['doc_status'] if 'doc_status' in d.keys() else ''
        status_label = DOC_STATUS_LABEL.get(raw_status, raw_status or '草稿')
        vals = [d['doc_number'], d['subject'], d['version'],
                d['file_type_name'] or '', d['department'], d['issue_date'],
                d['owner_name'], d['folder_name'] or '', d['tab_name'] or '',
                status_label,
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
    log_action(ACTION['RESTORE'], doc=doc)
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


@app.route('/admin/dashboard')
@admin_required
def admin_dashboard():
    """月報儀表板：文件健康狀況總覽。"""
    user = current_user()

    # ── 整體統計 ──────────────────────────────────────────
    total = query_db("SELECT COUNT(*) AS c FROM documents WHERE is_deleted=0", one=True)['c']
    by_status = query_db("""
        SELECT COALESCE(doc_status,'draft') AS s, COUNT(*) AS c
        FROM documents WHERE is_deleted=0
        GROUP BY s ORDER BY c DESC
    """)
    pending_review = query_db("""
        SELECT COUNT(*) AS c FROM workflow_steps ws
        JOIN approval_workflows aw ON ws.workflow_id=aw.id
        WHERE ws.status='pending' AND aw.status='open'
    """, one=True)['c']
    expiry_30 = query_db("""
        SELECT COUNT(*) AS c FROM documents
        WHERE expiry_date IS NOT NULL
          AND expiry_date::date <= CURRENT_DATE + (30 * INTERVAL '1 day')
          AND doc_status NOT IN ('archived','superseded') AND is_deleted=0
    """, one=True)['c']
    expiry_overdue = query_db("""
        SELECT COUNT(*) AS c FROM documents
        WHERE expiry_date IS NOT NULL
          AND expiry_date::date < CURRENT_DATE
          AND doc_status NOT IN ('archived','superseded') AND is_deleted=0
    """, one=True)['c']

    # ── 本月活動 ──────────────────────────────────────────
    month_created = query_db("""
        SELECT COUNT(*) AS c FROM documents
        WHERE DATE_TRUNC('month', created_at) = DATE_TRUNC('month', CURRENT_DATE)
          AND is_deleted=0
    """, one=True)['c']
    month_released = query_db("""
        SELECT COUNT(*) AS c FROM approval_workflows
        WHERE status='approved'
          AND DATE_TRUNC('month', closed_at) = DATE_TRUNC('month', CURRENT_DATE)
    """, one=True)['c']
    month_rejected = query_db("""
        SELECT COUNT(*) AS c FROM approval_workflows
        WHERE status='rejected'
          AND DATE_TRUNC('month', closed_at) = DATE_TRUNC('month', CURRENT_DATE)
    """, one=True)['c']

    # ── 各部門文件數 ───────────────────────────────────────
    by_dept = query_db("""
        SELECT COALESCE(department,'（未填）') AS dept, COUNT(*) AS c
        FROM documents WHERE is_deleted=0 AND doc_status NOT IN ('archived','superseded')
        GROUP BY dept ORDER BY c DESC LIMIT 10
    """)

    # ── 近 6 個月發行趨勢 ──────────────────────────────────
    monthly_trend = query_db("""
        SELECT TO_CHAR(DATE_TRUNC('month', closed_at), 'YYYY-MM') AS ym,
               COUNT(*) AS c
        FROM approval_workflows
        WHERE status='approved'
          AND closed_at >= CURRENT_DATE - INTERVAL '6 months'
        GROUP BY ym ORDER BY ym
    """)

    # ── 待審最久的文件（Top 5） ────────────────────────────
    stale_reviews = query_db("""
        SELECT d.doc_number, d.subject, aw.initiated_at,
               u.name AS initiator_name,
               (CURRENT_DATE - aw.initiated_at::date) AS days_pending
        FROM approval_workflows aw
        JOIN documents d ON aw.document_id=d.id
        JOIN users u ON aw.initiated_by=u.id
        WHERE aw.status='open'
        ORDER BY aw.initiated_at ASC LIMIT 5
    """)

    return render_template('admin/dashboard.html',
        user=user,
        total=total, by_status=by_status,
        pending_review=pending_review,
        expiry_30=expiry_30, expiry_overdue=expiry_overdue,
        month_created=month_created, month_released=month_released,
        month_rejected=month_rejected,
        by_dept=by_dept,
        monthly_trend=monthly_trend,
        stale_reviews=stale_reviews,
        doc_status_label=DOC_STATUS_LABEL,
        status_badge={'draft':'secondary','in_review':'info','released':'success',
                      'superseded':'warning','archived':'dark'}
    )


@app.route('/admin/dashboard/export')
@admin_required
def admin_dashboard_export():
    """月報 Excel 匯出。"""
    import openpyxl
    from openpyxl.styles import Font, PatternFill, Alignment, Border, Side
    from openpyxl.utils import get_column_letter

    wb = openpyxl.Workbook()
    now_str = datetime.now().strftime('%Y-%m-%d %H:%M')
    thin = Side(style='thin')
    border = Border(left=thin, right=thin, top=thin, bottom=thin)

    def header_style(cell, color='4472C4'):
        cell.font = Font(bold=True, color='FFFFFF')
        cell.fill = PatternFill('solid', fgColor=color)
        cell.alignment = Alignment(horizontal='center')
        cell.border = border

    # ── 工作表1：整體統計 ──────────────────────────────────
    ws1 = wb.active
    ws1.title = '整體統計'
    ws1.append([f'文件管理系統月報 — {now_str}'])
    ws1['A1'].font = Font(bold=True, size=14)
    ws1.append([])

    by_status = query_db("SELECT COALESCE(doc_status,'draft') AS s, COUNT(*) AS c FROM documents WHERE is_deleted=0 GROUP BY s ORDER BY c DESC")
    status_label = DOC_STATUS_LABEL
    ws1.append(['文件狀態', '數量'])
    for cell in ws1[ws1.max_row]: header_style(cell)
    for r in by_status:
        ws1.append([status_label.get(r['s'], r['s']), r['c']])

    ws1.append([])
    ws1.append(['指標', '數值'])
    for cell in ws1[ws1.max_row]: header_style(cell, '70AD47')
    pending = query_db("SELECT COUNT(*) AS c FROM workflow_steps ws JOIN approval_workflows aw ON ws.workflow_id=aw.id WHERE ws.status='pending' AND aw.status='open'", one=True)['c']
    exp30 = query_db("SELECT COUNT(*) AS c FROM documents WHERE expiry_date IS NOT NULL AND expiry_date::date <= CURRENT_DATE+(30*INTERVAL '1 day') AND doc_status NOT IN ('archived','superseded') AND is_deleted=0", one=True)['c']
    ws1.append(['待審文件數', pending])
    ws1.append(['30天內到期', exp30])
    for col in ws1.columns:
        ws1.column_dimensions[get_column_letter(col[0].column)].width = 20

    # ── 工作表2：本月送審記錄 ────────────────────────────────
    ws2 = wb.create_sheet('本月送審記錄')
    ws2.append(['文件案號', '主旨', '送審人', '送審時間', '狀態', '結束時間'])
    for cell in ws2[1]: header_style(cell)
    records = query_db("""
        SELECT d.doc_number, d.subject, u.name AS initiator, aw.initiated_at, aw.status, aw.closed_at
        FROM approval_workflows aw
        JOIN documents d ON aw.document_id=d.id
        JOIN users u ON aw.initiated_by=u.id
        WHERE DATE_TRUNC('month', aw.initiated_at) = DATE_TRUNC('month', CURRENT_DATE)
        ORDER BY aw.initiated_at DESC
    """)
    status_map = {'open':'進行中','approved':'已核准','rejected':'已退回','withdrawn':'已撤回'}
    for r in records:
        ws2.append([r['doc_number'], r['subject'], r['initiator'],
                    str(r['initiated_at'] or '')[:16],
                    status_map.get(r['status'], r['status']),
                    str(r['closed_at'] or '')[:16]])
    for col in ws2.columns:
        ws2.column_dimensions[get_column_letter(col[0].column)].width = 22

    # ── 工作表3：30天到期文件 ────────────────────────────────
    ws3 = wb.create_sheet('30天到期文件')
    ws3.append(['案號', '主旨', '狀態', '到期日', '剩餘天數', '部門', '擁有者'])
    for cell in ws3[1]: header_style(cell, 'ED7D31')
    expiry_docs = query_db("""
        SELECT d.doc_number, d.subject, d.doc_status, d.expiry_date,
               (d.expiry_date::date - CURRENT_DATE) AS days_left,
               d.department, u.name AS owner_name
        FROM documents d LEFT JOIN users u ON d.owner_id=u.id
        WHERE d.expiry_date IS NOT NULL
          AND d.expiry_date::date <= CURRENT_DATE + (30 * INTERVAL '1 day')
          AND d.doc_status NOT IN ('archived','superseded') AND d.is_deleted=0
        ORDER BY d.expiry_date ASC
    """)
    for r in expiry_docs:
        ws3.append([r['doc_number'], r['subject'],
                    status_label.get(r['doc_status'] or 'draft', r['doc_status']),
                    str(r['expiry_date'] or '')[:10], r['days_left'],
                    r['department'] or '', r['owner_name'] or ''])
    for col in ws3.columns:
        ws3.column_dimensions[get_column_letter(col[0].column)].width = 20

    buf = io.BytesIO()
    wb.save(buf); buf.seek(0)
    fn = f'文件管理月報_{datetime.now().strftime("%Y%m%d")}.xlsx'
    return send_file(buf, mimetype='application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
                     download_name=fn, as_attachment=True)


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
        elif action == 'set_template':
            fid = request.form.get('id', type=int)
            tid = request.form.get('template_id', type=int) or None
            # 直接更新 file_types 的 default_template_id（不影響其他列）
            execute_db('UPDATE file_types SET default_template_id=? WHERE id=?', [tid, fid])
        return redirect(url_for('admin_file_types'))
    try:
        file_types = query_db('''
            SELECT ft.*,
                   ft.default_template_id AS tmpl_id,
                   wt.name                AS tmpl_name
            FROM file_types ft
            LEFT JOIN workflow_templates wt ON ft.default_template_id = wt.id
            ORDER BY ft.code
        ''')
    except Exception:
        # default_template_id 欄位尚未建立（migrate_db 尚未執行）→ 先執行遷移再重試
        migrate_db()
        file_types = query_db('''
            SELECT ft.*,
                   ft.default_template_id AS tmpl_id,
                   wt.name                AS tmpl_name
            FROM file_types ft
            LEFT JOIN workflow_templates wt ON ft.default_template_id = wt.id
            ORDER BY ft.code
        ''')
    templates = query_db(
        'SELECT id, name FROM workflow_templates WHERE is_active=1 ORDER BY name'
    )
    return render_template('admin/file_types.html', user=user,
                           file_types=file_types, templates=templates)


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
        username = request.form.get('new_uname', '').strip()
        password = request.form.get('new_pwd', '').strip()
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


@app.route('/admin/users/<int:uid>/delete', methods=['POST'])
@admin_required
def admin_user_delete(uid):
    user = current_user()
    if uid == user['id']:
        return jsonify({'success': False, 'msg': '無法刪除自己的帳號'})
    target = query_db('SELECT * FROM users WHERE id=?', [uid], one=True)
    if not target:
        return jsonify({'success': False, 'msg': '使用者不存在'})
    # 防止刪除最後一個管理員
    if target['is_admin']:
        admin_cnt = query_db('SELECT COUNT(*) AS c FROM users WHERE is_admin=1', one=True)
        if admin_cnt and admin_cnt['c'] <= 1:
            return jsonify({'success': False, 'msg': '無法刪除唯一的管理員帳號'})

    aid = user['id']   # 目前管理員 id（承接擁有權）

    # ── 1. 可設 NULL 的欄位 ───────────────────────────────────
    execute_db('UPDATE audit_log         SET actor_id=NULL    WHERE actor_id=?',    [uid])
    execute_db('UPDATE chat_messages     SET sender_id=NULL   WHERE sender_id=?',   [uid])
    execute_db('UPDATE document_versions SET approved_by=NULL WHERE approved_by=?', [uid])
    execute_db('UPDATE work_logs         SET reviewed_by=NULL WHERE reviewed_by=?', [uid])

    # ── 2. 轉移給管理員（NOT NULL 欄位） ─────────────────────
    execute_db('UPDATE documents              SET owner_id=?    WHERE owner_id=?',    [aid, uid])
    execute_db('UPDATE folders                SET owner_id=?    WHERE owner_id=?',    [aid, uid])
    execute_db('UPDATE tabs                   SET owner_id=?    WHERE owner_id=?',    [aid, uid])
    execute_db('UPDATE approval_workflows     SET initiated_by=? WHERE initiated_by=?', [aid, uid])
    execute_db('UPDATE chat_rooms             SET created_by=?  WHERE created_by=?',  [aid, uid])
    execute_db('UPDATE chat_sticker_packs     SET owner_id=?    WHERE owner_id=?',    [aid, uid])
    execute_db('UPDATE document_versions      SET created_by=?  WHERE created_by=?',  [aid, uid])
    execute_db('UPDATE download_logs          SET user_id=?     WHERE user_id=?',     [aid, uid])
    # work_logs 有 (user_id, log_date) 唯一索引，無法轉移，直接刪除
    execute_db('DELETE FROM work_logs WHERE user_id=?', [uid])
    execute_db('UPDATE workflow_steps         SET assignee_id=? WHERE assignee_id=?', [aid, uid])
    execute_db('UPDATE workflow_template_steps SET user_id=?   WHERE user_id=?',     [aid, uid])

    # ── 3. 直接刪除（個人資料） ───────────────────────────────
    execute_db('DELETE FROM approver_roles          WHERE user_id=?', [uid])
    execute_db('DELETE FROM attendance              WHERE user_id=?', [uid])
    execute_db('DELETE FROM chat_push_subscriptions WHERE user_id=?', [uid])
    execute_db('DELETE FROM chat_room_members       WHERE user_id=?', [uid])
    execute_db('DELETE FROM document_permissions    WHERE user_id=?', [uid])
    execute_db('DELETE FROM folder_permissions      WHERE user_id=?', [uid])
    execute_db('DELETE FROM group_members           WHERE user_id=?', [uid])
    execute_db('DELETE FROM reminders               WHERE user_id=?', [uid])

    # ── 4. 最後刪除使用者 ─────────────────────────────────────
    execute_db('DELETE FROM users WHERE id=?', [uid])
    return jsonify({'success': True})


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
    init_db()     # 建立基礎資料表（IF NOT EXISTS）
    migrate_db()  # ISO 合規欄位與資料表遷移（冪等）
    ssl_context = None
    if os.path.exists('cert.pem') and os.path.exists('key.pem'):
        import ssl
        ssl_context = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
        ssl_context.load_cert_chain('cert.pem', 'key.pem')
        print(' * SSL enabled (cert.pem / key.pem)')
    app.run(debug=False, host='0.0.0.0', port=5100, ssl_context=ssl_context)

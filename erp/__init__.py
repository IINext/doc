"""ERP 系統（由 Magic xpa 的 Home 專案轉換）。

和 repo 根目錄的文件管理系統完全獨立：各自的登入、各自的設定。

設定（環境變數）：
    ERP_DATABASE_URL  PostgreSQL 連線字串，例如 postgresql://erp:密碼@localhost/erp
    ERP_SECRET_KEY    session 加密金鑰（正式環境必填，請用長亂數）
    ERP_SIGNING_APP_NAME  簽核系統名稱的後綴，和舊系統的 G_app.Name 相同（預設 Home）；
                      FIL0030 的「簽核系統」= 單據類別 + '.' + 這個名稱

執行：
    flask --app erp init-db              # 建立 ERP 自己的資料表（erp_auth）
    flask --app erp import-passwords     # 把舊系統的密碼轉成雜湊（一次性）
    flask --app erp run                  # 開發用
    python -m erp.serve                  # 正式執行（waitress）
"""
import os
import secrets
from pathlib import Path

import click
from flask import Flask, redirect, url_for

from . import auth, db, expense, flow, leave


def create_app(test_config=None):
    app = Flask(__name__)
    app.config.from_mapping(
        SECRET_KEY=os.environ.get('ERP_SECRET_KEY') or secrets.token_hex(32),
        DATABASE_URL=os.environ.get('ERP_DATABASE_URL', ''),
        SIGNING_APP_NAME=os.environ.get('ERP_SIGNING_APP_NAME', 'Home'),
        SESSION_COOKIE_HTTPONLY=True,
        SESSION_COOKIE_SAMESITE='Lax',
    )
    if test_config:
        app.config.update(test_config)

    db.init_app(app)
    app.register_blueprint(auth.bp)
    app.register_blueprint(leave.bp)
    app.register_blueprint(expense.bp)
    app.register_blueprint(flow.bp)
    app.jinja_env.globals['csrf_token'] = auth.csrf_token
    app.jinja_env.globals['pending_count'] = flow.pending_count

    @app.route('/')
    @auth.login_required
    def index():
        return redirect(url_for('leave.index'))

    @app.cli.command('init-db')
    def init_db():
        """建立 ERP 自己的資料表。"""
        db.execute((Path(__file__).parent / 'schema.sql').read_text(encoding='utf-8'))
        db.commit()
        click.echo('完成')

    @app.cli.command('import-passwords')
    def import_passwords():
        """把 FIL0010 的明文密碼轉成雜湊存到 erp_auth（已有的帳號不覆蓋）。首次登入必須改密碼。"""
        rows = db.query("""SELECT "員工編號", "個人密碼" FROM fil0010 f
                           WHERE trim("個人密碼") <> ''
                             AND NOT EXISTS (SELECT 1 FROM erp_auth a WHERE a."員工編號" = f."員工編號")""")
        for r in rows:
            auth.set_password(r['員工編號'], r['個人密碼'].strip(), must_change=True)
        db.commit()
        click.echo(f'匯入 {len(rows)} 個帳號；舊系統停用後，建議清空 FIL0010."個人密碼"')

    @app.cli.command('set-password')
    @click.argument('emp_no')
    @click.password_option()
    def set_password(emp_no, password):
        """設定某位員工的密碼（下次登入必須改密碼）。"""
        if not auth.load_employee(emp_no.upper()):
            raise click.ClickException('找不到這位員工')
        auth.set_password(emp_no.upper(), password, must_change=True)
        db.commit()
        click.echo('完成')

    return app

"""PostgreSQL 連線與共用查詢函數。

資料表沿用 Oracle 轉過來的結構（magic2py/schema/postgresql.sql），欄位名稱多為中文，
SQL 裡請一律用雙引號包住，例如 SELECT "員工姓名" FROM fil0010。
"""
import psycopg2
import psycopg2.extras
from flask import current_app, g


def get_db():
    """每個 request 一個連線；不自動 commit，寫入後要呼叫 commit()。"""
    if 'db' not in g:
        g.db = psycopg2.connect(current_app.config['DATABASE_URL'],
                                cursor_factory=psycopg2.extras.RealDictCursor)
    return g.db


def close_db(exc=None):
    db = g.pop('db', None)
    if db is not None:
        db.rollback()          # 沒有 commit 的變更一律放棄
        db.close()


def init_app(app):
    app.teardown_appcontext(close_db)


def query(sql, params=()):
    with get_db().cursor() as cur:
        cur.execute(sql, params)
        return cur.fetchall()


def one(sql, params=()):
    with get_db().cursor() as cur:
        cur.execute(sql, params)
        return cur.fetchone()


def scalar(sql, params=()):
    row = one(sql, params)
    return next(iter(row.values())) if row else None


def execute(sql, params=()):
    with get_db().cursor() as cur:
        cur.execute(sql, params)
        return cur.rowcount


def commit():
    get_db().commit()


def _ident(name):
    return '"' + name.replace('"', '""') + '"'


def _blank_value(data_type, length):
    """Magic 寫入時每個欄位都有值；沒有預設值的 NOT NULL 欄位用 Magic 的空白值補上。"""
    if data_type in ('character varying', 'character', 'text'):
        return '00000000' if length == 8 and data_type == 'character' else ' '
    if data_type in ('smallint', 'integer', 'bigint', 'numeric', 'double precision', 'real'):
        return 0
    return None


def _required_columns(table):
    """沒有預設值的 NOT NULL 欄位（依表快取）。"""
    cache = g.setdefault('_required_columns', {})
    if table not in cache:
        rows = query("""SELECT column_name, data_type, character_maximum_length
                        FROM information_schema.columns
                        WHERE table_schema = current_schema() AND table_name = %s
                          AND is_nullable = 'NO' AND column_default IS NULL""", (table,))
        cache[table] = {r['column_name']: _blank_value(r['data_type'], r['character_maximum_length'])
                        for r in rows}
    return cache[table]


def insert(table, values):
    """新增一筆。沒給值、又沒有預設值的 NOT NULL 欄位自動補空白值（' '、0、'00000000'）。"""
    row = {k: v for k, v in _required_columns(table).items() if v is not None}
    row.update(values)
    cols = ', '.join(_ident(c) for c in row)
    marks = ', '.join(['%s'] * len(row))
    execute(f'INSERT INTO {_ident(table)} ({cols}) VALUES ({marks})', list(row.values()))


def update(table, values, where, where_params):
    sets = ', '.join(f'{_ident(c)} = %s' for c in values)
    return execute(f'UPDATE {_ident(table)} SET {sets} WHERE {where}', list(values.values()) + list(where_params))

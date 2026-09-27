"""整合測試需要一個「可以清空」的 PostgreSQL 測試資料庫：

    ERP_TEST_DATABASE_URL=postgresql://postgres@localhost/erp_test python -m pytest erp/tests

測試會清空這個資料庫的 public schema，重建 magic2py/schema 的資料表與 View。請不要指向正式資料庫。
沒有設定時只跑不需要資料庫的測試。
"""
import os
from datetime import date, timedelta
from pathlib import Path

import psycopg2
import pytest

from erp import create_app, db
from erp.auth import set_password
from erp.magic import from_date

ROOT = Path(__file__).resolve().parents[2]
DSN = os.environ.get('ERP_TEST_DATABASE_URL')
SCHEMA_FILES = [ROOT / 'magic2py/schema/postgresql.sql', ROOT / 'magic2py/oracle_compat.sql',
                ROOT / 'magic2py/schema/postgresql_views.sql', ROOT / 'erp/schema.sql']
SEEDED_TABLES = ['erp_auth', 'fil0010', 'fil0010a', 'fil0024', 'fil0025', 'fil1014', 'fil1019', 'hrfil1002a',
                 'a30', 'a40', 'a50', 'a60_7', 'a60_8', 'a20', 'a20_1', 'a01', 'a01_2', 'a01_3', 'a01_4',
                 'fil0030', 'fil0040', 'fil0050', 'hrfil1031', 'messages']
PASSWORD = 'correct horse 1'


@pytest.fixture(scope='session')
def database():
    if not DSN:
        pytest.skip('沒有設定 ERP_TEST_DATABASE_URL，略過資料庫測試')
    conn = psycopg2.connect(DSN)
    conn.autocommit = True
    with conn.cursor() as cur:
        cur.execute('DROP SCHEMA public CASCADE; CREATE SCHEMA public;'
                    'DROP SCHEMA IF EXISTS dbms_lob CASCADE; DROP SCHEMA IF EXISTS utl_raw CASCADE;')
        for f in SCHEMA_FILES:
            cur.execute(f.read_text(encoding='utf-8'))
    conn.close()
    return DSN


def next_monday(today=None):
    today = today or date.today()
    return today + timedelta(days=7 - today.weekday())


def seed():
    """測試資料：08:00–17:00 的班別、兩位員工（E002 是 E001 部門的主管）、假別、行事曆、請假單簽核流程。"""
    db.execute('TRUNCATE ' + ', '.join(SEEDED_TABLES))
    db.insert('fil0025', {'代碼': 'A', '名稱': '日班', '上班起時': '080000', '上班迄時': '170000',
                          '休息起時': '120000', '休息迄時': '130000'})
    for no, name, serial, posi in (('E001', '王小明', 'S-E001', 'P-STAFF'), ('E002', '陳主管', 'S-E002', 'P-MGR'),
                                   ('E003', '李離職', 'S-E003', 'P-STAFF')):
        db.insert('fil0010', {'serial_num': serial, '員工編號': no, '員工姓名': name, '公司代碼': '1',
                              '部門編號': 'D01', 'depserial': 'G-D01', 'compserial': 'C-1', 'flowposi': posi,
                              'party': 'A', 'replaceby': ' ', 'entryid': ' ',
                              '停止使用': 1 if no == 'E003' else 0})
        set_password(no, PASSWORD, must_change=False)
    db.insert('a30', {'serial_num': 'G-D01', 'groupid': 'D01', 'groupname': '生管課', 'guname': '生管課'})
    db.insert('a40', {'serial_num': 'P-MGR', 'psoiid': 'MGR', 'guname': '課長'})
    db.insert('a60_8', {'serial_num': 'S-E002', 'serial_num_seq': 1, 'depid': 'G-D01', 'recordid': 'R-S-E002'})   # E002 管轄 D01
    for code, name, min_hours, limit, holidays, reason in (('01', '事假', 1, 14, 0, 1), ('03', '病假', '0.5', 30, 0, 0),
                                                           ('09', '婚假', 8, 8, 1, 0)):
        db.insert('fil1014', {'代碼類別': '假別代碼', '系統代碼': code, '代碼名稱': name, '數字參數': min_hours,
                              '數字參數二': limit, '邏輯值': holidays, '邏輯值一': reason})
    db.insert('fil1014', {'代碼類別': '單據類別', '系統代碼': 'H01', '代碼名稱': '請假卡', '文字參數一': 'E009'})
    db.insert('hrfil1002a', {'syskey': 'EMP', '關帳年月': '20000101'})
    # 行事曆：週六、週日休假（休假 = 2）
    start = date.today() - timedelta(days=date.today().weekday() + 21)
    for w in range(20):
        sunday = start + timedelta(days=7 * w - 1)
        row = {'年月': int(sunday.strftime('%Y%m')), '週': w + 1}
        for i, key in enumerate(['日', '一', '二', '三', '四', '五', '六']):
            d = sunday + timedelta(days=i)
            row[key] = from_date(d)
            row['休假' + key] = 2 if key in ('日', '六') else 0
        db.insert('fil1019', row)
    # 請假單的簽核流程：申請人部門的課長簽
    db.insert('a20', {'serial_num': 'F-H01', 'job_type': 'H01', 'guname': '請假卡', 'visible': 0,
                      '流程獨立否': 0, '同人合併': 1})
    db.insert('a20_1', {'serial_num': 'F-H01', 'compid': 'C-1', 'level_': 0, 'serial_num_seq': 10,
                        'posiid': 'P-MGR', 'signorcc': 1, '指定人員': ' ', 'appdept': ' ', 'flowdept': ' '})
    db.commit()


@pytest.fixture
def app(database):
    app = create_app({'TESTING': True, 'DATABASE_URL': database, 'SECRET_KEY': 'test'})
    with app.app_context():
        seed()
    return app


@pytest.fixture
def client(app):
    return app.test_client()


def csrf(client):
    with client.session_transaction() as s:
        s.setdefault('csrf_token', 'test-token')
        return s['csrf_token']


def login(client, emp_no='E001', password=PASSWORD):
    return client.post('/login', data={'emp_no': emp_no, 'password': password, 'csrf_token': csrf(client)})

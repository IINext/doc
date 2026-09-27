"""整合測試：費用申請單新增/修改/刪除/送簽（簽核共用 edb.py 同一套流程引擎）。需要 ERP_TEST_DATABASE_URL。"""
from datetime import date

from erp import db
from erp.magic import roc_date7

from .conftest import csrf, login

NO = roc_date7(date.today()) + '001'


def register_flow(app):
    """H11 的簽核流程：申請人部門的課長簽（和 conftest 幫 H01 註冊的一樣）。"""
    with app.app_context():
        db.insert('a20', {'serial_num': 'F-H11', 'job_type': 'H11', 'job_id': 'H11', 'guname': '費用申請單',
                          'visible': 0, '流程獨立否': 0, '同人合併': 1})
        db.insert('a20_1', {'serial_num': 'F-H11', 'compid': 'C-1', 'level_': 0, 'serial_num_seq': 10,
                            'posiid': 'P-MGR', 'signorcc': 1, '指定人員': ' ', 'appdept': ' ', 'flowdept': ' '})
        db.commit()


def expense_form(client, **kw):
    data = {'period': date.today().strftime('%Y-%m'), 'category': '1', 'header_note': '出差',
            'applicant': ['E001'], 'amount': ['1200'], 'note': ['計程車'], 'csrf_token': csrf(client)}
    data.update(kw)
    return data


def create(client, **kw):
    return client.post('/hr/expense/new', data=expense_form(client, **kw))


def flashed(resp):
    return resp.get_data(as_text=True)


class TestExpense:
    def test_create(self, client, app):
        login(client)
        resp = create(client)
        assert resp.status_code == 302 and resp.headers['Location'].endswith('/hr/expense/' + NO)
        with app.app_context():
            head = db.one('SELECT * FROM fil0030 WHERE "單據編號" = %s', (NO,))
            assert head['單據類別'] == 'H11' and head['流水編號'].startswith('H11')
            assert head['簽核系統'] == 'H11.Home' and head['稅別'] == '1' and head['備註'].strip() == '出差'
            rows = db.query('SELECT "產品編號", "異動數量", "備註說明" FROM fil0040 WHERE "單據編號" = %s '
                            'ORDER BY "單據序號"', (NO,))
            assert [(r['產品編號'].strip(), r['異動數量'], r['備註說明'].strip()) for r in rows] == \
                [('E001', 1200, '計程車')]
        page = client.get('/hr/expense/').get_data(as_text=True)
        assert NO in page and '車馬費一' in page and '1200' in page

    def test_multiple_rows(self, client, app):
        login(client)
        create(client, applicant=['E001', 'E002'], amount=['1200', '300'], note=['計程車', '油錢'])
        with app.app_context():
            rows = db.query('SELECT "產品編號", "異動數量" FROM fil0040 ORDER BY "單據序號"')
            assert [(r['產品編號'].strip(), r['異動數量']) for r in rows] == [('E001', 1200), ('E002', 300)]
        page = client.get(f'/hr/expense/{NO}').get_data(as_text=True)
        assert 'E002' in page and '300' in page

    def test_validation(self, client):
        login(client)
        assert '至少要有一筆明細' in flashed(create(client, applicant=[''], amount=[''], note=['']))
        assert '請選擇帳款年月' in flashed(create(client, period=''))
        assert '申請人錯誤' in flashed(create(client, applicant=['NOBODY']))
        assert '金額請輸入數字' in flashed(create(client, amount=['abc']))

    def test_closed_period(self, client, app):
        with app.app_context():
            db.execute("UPDATE hrfil1002a SET \"關帳年月\" = %s WHERE syskey = 'EMP'",
                      (date.today().strftime('%Y%m01'),))
            db.commit()
        login(client)
        assert '已關帳' in flashed(create(client))

    def test_edit_replaces_rows(self, client, app):
        login(client)
        create(client)
        client.post(f'/hr/expense/{NO}', data=expense_form(client, applicant=['E002'], amount=['500'], note=['']))
        with app.app_context():
            rows = db.query('SELECT "產品編號", "異動數量" FROM fil0040 WHERE "單據編號" = %s', (NO,))
            assert [(r['產品編號'].strip(), r['異動數量']) for r in rows] == [('E002', 500)]

    def test_other_user_cannot_see(self, client):
        login(client)
        create(client)
        client.post('/logout', data={'csrf_token': csrf(client)})
        login(client, emp_no='E002')
        assert client.get('/hr/expense/' + NO).status_code == 404
        assert NO not in client.get('/hr/expense/').get_data(as_text=True)

    def test_delete(self, client, app):
        login(client)
        create(client)
        client.post(f'/hr/expense/{NO}/delete', data={'csrf_token': csrf(client)})
        with app.app_context():
            assert db.scalar('SELECT count(*) FROM fil0030') == 0
            assert db.scalar('SELECT count(*) FROM fil0040') == 0


class TestExpenseFlow:
    def test_submit_and_approve(self, client, app):
        register_flow(app)
        login(client)
        create(client)
        resp = client.post(f'/hr/expense/{NO}/submit', data={'csrf_token': csrf(client)})
        assert resp.status_code == 302
        with app.app_context():
            serial = db.scalar('SELECT "流水編號" FROM fil0030 WHERE "單據編號" = %s', (NO,))
            flow = db.query('SELECT * FROM a01_2 WHERE serial_num = %s', (serial,))
            assert [(f['assignedto'], f['serial_num_seq']) for f in flow] == [('S-E002', 10)]
        assert '已送簽,無法異動' in flashed(client.post(f'/hr/expense/{NO}', data=expense_form(client), follow_redirects=True))

        client.post('/logout', data={'csrf_token': csrf(client)})
        login(client, emp_no='E002')
        assert NO in client.get('/flow/').get_data(as_text=True)
        page = client.get(f'/hr/expense/{NO}').get_data(as_text=True)
        assert '輪到您簽核' in page
        resp = client.post(f'/hr/expense/{NO}/approve', data={'csrf_token': csrf(client), 'comment': '准了'},
                           follow_redirects=True)
        assert '簽核完成' in resp.get_data(as_text=True)
        with app.app_context():
            assert db.scalar("SELECT flowstatus FROM a01 WHERE serial_num = %s", (serial,)) == 'E'

    def test_submit_without_flow(self, client, app):
        login(client)
        create(client)
        resp = client.post(f'/hr/expense/{NO}/submit', data={'csrf_token': csrf(client)}, follow_redirects=True)
        assert '送簽失敗: 尚未設定流程' in resp.get_data(as_text=True)
        with app.app_context():
            assert db.scalar('SELECT count(*) FROM a01') == 0

    def test_only_filler_can_submit(self, client, app):
        register_flow(app)
        login(client)
        create(client)
        client.post('/logout', data={'csrf_token': csrf(client)})
        login(client, emp_no='E002')
        resp = client.post(f'/hr/expense/{NO}/submit', data={'csrf_token': csrf(client)})
        assert resp.status_code == 302
        with client.session_transaction() as sess:
            assert any('非填表人無法送簽' in m for _, m in sess.get('_flashes', []))
        with app.app_context():
            assert db.scalar('SELECT count(*) FROM a01') == 0

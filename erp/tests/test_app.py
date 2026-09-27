"""整合測試：登入、請假單新增/修改/檢查/刪除、送簽。需要 ERP_TEST_DATABASE_URL（見 conftest.py）。"""
from datetime import date, timedelta

from erp import db
from erp.magic import roc_date7

from .conftest import PASSWORD, csrf, login, next_monday

MON = next_monday()


def leave_form(client, **kw):
    data = {'applicant': 'E001', 'leave_type': '01', 'start_date': MON.isoformat(), 'start_time': '08:00',
            'days': '1', 'hours': '4', 'agent': 'E002', 'reason': '家中有事', 'csrf_token': csrf(client)}
    data.update(kw)
    return data


def create(client, **kw):
    return client.post('/hr/leave/new', data=leave_form(client, **kw))


def flashed(resp):
    return resp.get_data(as_text=True)


class TestAuth:
    def test_login_and_logout(self, client):
        assert client.get('/').status_code == 302
        resp = login(client)
        assert resp.status_code == 302
        assert '王小明' in client.get('/hr/leave/').get_data(as_text=True)
        client.post('/logout', data={'csrf_token': csrf(client)})
        assert client.get('/hr/leave/').status_code == 302

    def test_wrong_password(self, client):
        assert '帳號或密碼錯誤' in flashed(login(client, password='wrong'))

    def test_no_master_password(self, client, app):
        # 舊系統的萬用密碼（以及 FIL0010 的明文密碼）都不能登入
        with app.app_context():
            db.execute('UPDATE fil0010 SET "個人密碼" = %s WHERE "員工編號" = %s', ('plain123', 'E001'))
            db.commit()
        assert '帳號或密碼錯誤' in flashed(login(client, password='plain123'))

    def test_disabled_account(self, client):
        assert '帳號已停用' in flashed(login(client, emp_no='E003'))

    def test_lockout(self, client):
        for _ in range(5):
            login(client, password='wrong')
        assert '輸入錯誤次數過多' in flashed(login(client))

    def test_csrf_required(self, client):
        assert client.post('/login', data={'emp_no': 'E001', 'password': PASSWORD}).status_code == 400

    def test_must_change_password(self, client, app):
        with app.app_context():
            db.execute('UPDATE erp_auth SET must_change = true WHERE "員工編號" = %s', ('E001',))
            db.commit()
        login(client)
        assert client.get('/hr/leave/').headers['Location'].endswith('/password')
        resp = client.post('/password', data={'current': PASSWORD, 'new': 'new password 9',
                                              'confirm': 'new password 9', 'csrf_token': csrf(client)})
        assert resp.status_code == 302
        assert client.get('/hr/leave/').status_code == 200


class TestLeave:
    def test_create(self, client, app):
        login(client)
        resp = create(client)
        no = roc_date7(date.today()) + '001'
        assert resp.status_code == 302 and resp.headers['Location'].endswith('/hr/leave/' + no)
        with app.app_context():
            head = db.one('SELECT * FROM fil0030 WHERE "單據編號" = %s', (no,))
            assert head['單據類別'] == 'H01' and head['流水編號'].startswith('H01') and head['折讓'] == 8
            assert head['簽核系統'] == 'H01.Home'
            leave = db.one('SELECT * FROM hrfil1031 WHERE "單號" = %s', (no,))
            assert (leave['截止日期'], leave['截止時間']) == ((MON + timedelta(days=1)).strftime('%Y%m%d'), '120000')
            rows = db.query('SELECT "異動日期", "異動數量", time1 FROM fil0040 WHERE "單據編號" = %s '
                            'ORDER BY "單據序號"', (no,))
            assert [(r['異動日期'], r['異動數量'], r['time1']) for r in rows] == [
                (MON.strftime('%Y%m%d'), 8, '080000'), ((MON + timedelta(days=1)).strftime('%Y%m%d'), 4, '080000')]
        page = client.get('/hr/leave/').get_data(as_text=True)
        assert no in page and '事假' in page

    def test_pages_render(self, client):
        login(client)
        page = client.get('/hr/leave/new').get_data(as_text=True)
        assert '請假申請單' in page and '事假' in page
        create(client)
        no = roc_date7(date.today()) + '001'
        page = client.get('/hr/leave/' + no).get_data(as_text=True)
        assert '每日明細' in page and '送簽' in page and '12:00' in page

    def test_numbering(self, client):
        login(client)
        create(client)
        resp = create(client, start_date=(MON + timedelta(days=7)).isoformat())
        assert resp.headers['Location'].endswith(roc_date7(date.today()) + '002')

    def test_skips_weekend(self, client, app):
        login(client)
        fri = MON + timedelta(days=4)
        create(client, start_date=fri.isoformat(), start_time='13:00', days='0', hours='8')
        with app.app_context():
            dates = [r['異動日期'] for r in db.query('SELECT "異動日期" FROM fil0040 ORDER BY "單據序號"')]
        assert dates == [fri.strftime('%Y%m%d'), (MON + timedelta(days=7)).strftime('%Y%m%d')]

    def test_validation(self, client):
        login(client)
        assert '輸入請假事由' in flashed(create(client, reason=''))
        assert '起始日期必須是五天內' in flashed(create(client, start_date=(date.today() - timedelta(days=6)).isoformat()))
        assert '起始時間不能介於休息時間' in flashed(create(client, start_time='12:30', days='0', hours='2'))
        assert '起始時間必須介於班別時間' in flashed(create(client, start_time='07:00', days='0', hours='2'))
        resp = flashed(create(client, leave_type='09', days='0', hours='0'))
        # 原程式的訊息公式：至少小時剛好 8 時，天數和小時兩段都不顯示
        assert '輸入請假時數' in resp and '婚假至少要請' in resp
        assert '申請人錯誤' in flashed(create(client, applicant='NOBODY'))
        assert '請假天數超過法定天數' in flashed(create(client, days='15', hours='0'))

    def test_more_than_8_hours_a_day(self, client):
        login(client)
        create(client, days='0', hours='8')
        resp = create(client, start_time='13:00', days='0', hours='4')
        assert '當日請假超過8小時' in flashed(resp)

    def test_edit_regenerates_details(self, client, app):
        login(client)
        create(client)
        no = roc_date7(date.today()) + '001'
        client.post('/hr/leave/' + no, data=leave_form(client, days='0', hours='4'))
        with app.app_context():
            assert db.scalar('SELECT count(*) FROM fil0040 WHERE "單據編號" = %s', (no,)) == 1
            assert db.scalar('SELECT "截止時間" FROM hrfil1031 WHERE "單號" = %s', (no,)) == '120000'

    def test_other_user_cannot_see(self, client):
        login(client)
        create(client)
        no = roc_date7(date.today()) + '001'
        client.post('/logout', data={'csrf_token': csrf(client)})
        login(client, emp_no='E002')
        assert client.get('/hr/leave/' + no).status_code == 404
        assert no not in client.get('/hr/leave/').get_data(as_text=True)

    def test_delete(self, client, app):
        login(client)
        create(client)
        no = roc_date7(date.today()) + '001'
        client.post(f'/hr/leave/{no}/delete', data={'csrf_token': csrf(client)})
        with app.app_context():
            assert db.scalar('SELECT count(*) FROM fil0030') == 0
            assert db.scalar('SELECT count(*) FROM hrfil1031') == 0
            assert db.scalar('SELECT count(*) FROM fil0040') == 0


class TestSubmit:
    def test_submit_creates_flow(self, client, app):
        login(client)
        create(client)
        no = roc_date7(date.today()) + '001'
        resp = client.post(f'/hr/leave/{no}/submit', data={'csrf_token': csrf(client)})
        assert resp.status_code == 302
        with app.app_context():
            serial = db.scalar('SELECT "流水編號" FROM fil0030 WHERE "單據編號" = %s', (no,))
            obj = db.one('SELECT * FROM a01 WHERE serial_num = %s', (serial,))
            assert obj['flowstatus'] == 'I' and obj['owner'] == 'S-E001' and obj['locked'] == 1
            flow = db.query('SELECT * FROM a01_2 WHERE serial_num = %s', (serial,))
            assert [(f['assignedto'], f['serial_num_seq'], f['signedtype']) for f in flow] == [('S-E002', 10, '0')]
            assert db.scalar('SELECT activity FROM a01_3 WHERE serial_num = %s', (serial,)) == 'O'
            assert db.scalar('SELECT count(*) FROM a01_4 WHERE serial_num = %s', (serial,)) == 1
        page = client.get('/hr/leave/').get_data(as_text=True)
        assert '簽核中' in page

        # 送簽後不能再改、不能刪、不能重送
        assert '已送簽,無法異動' in flashed(client.post('/hr/leave/' + no, data=leave_form(client)))
        client.post(f'/hr/leave/{no}/delete', data={'csrf_token': csrf(client)})
        with app.app_context():
            assert db.scalar('SELECT count(*) FROM fil0030') == 1
        resp = client.post(f'/hr/leave/{no}/submit', data={'csrf_token': csrf(client)}, follow_redirects=True)
        assert '單據已送簽' in resp.get_data(as_text=True)

        # 簽核人看得到這張單
        client.post('/logout', data={'csrf_token': csrf(client)})
        login(client, emp_no='E002')
        assert no in client.get('/hr/leave/').get_data(as_text=True)
        page = client.get('/hr/leave/' + no).get_data(as_text=True)     # 可以查看，但不能修改
        assert '家中有事' in page and '存檔' not in page

    def test_submit_without_flow(self, client, app):
        with app.app_context():
            db.execute('TRUNCATE a20_1')
            db.commit()
        login(client)
        create(client)
        no = roc_date7(date.today()) + '001'
        resp = client.post(f'/hr/leave/{no}/submit', data={'csrf_token': csrf(client)}, follow_redirects=True)
        assert '送簽失敗: 尚未設定流程' in resp.get_data(as_text=True)
        with app.app_context():
            assert db.scalar('SELECT count(*) FROM a01') == 0      # 失敗時整筆回復

    def test_agent_replaces_approver(self, client, app):
        with app.app_context():
            db.execute("UPDATE fil0010 SET replaceby = 'S-E009' WHERE \"員工編號\" = 'E002'")
            db.commit()
        login(client)
        create(client)
        no = roc_date7(date.today()) + '001'
        client.post(f'/hr/leave/{no}/submit', data={'csrf_token': csrf(client)})
        with app.app_context():
            assert db.scalar('SELECT assignedto FROM a01_2') == 'S-E009'

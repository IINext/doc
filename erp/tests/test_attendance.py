"""整合測試：H05 出勤調整單（人資登打、存檔即核定）。需要 ERP_TEST_DATABASE_URL。"""
from datetime import date

from erp import db
from erp.auth import set_password
from erp.magic import roc_date7

from .conftest import PASSWORD, csrf, login

NO = roc_date7(date.today()) + '001'


def add_manager(app):
    """conftest 的 fil1014（單據類別=H01）指定 E009 是單據管理員。"""
    with app.app_context():
        db.insert('fil0010', {'serial_num': 'S-E009', '員工編號': 'E009', '員工姓名': '林人資', '公司代碼': '1',
                              '部門編號': 'D01', 'depserial': 'G-D01', 'compserial': 'C-1', 'flowposi': 'P-STAFF',
                              'party': 'A', 'replaceby': ' ', 'entryid': ' '})
        set_password('E009', PASSWORD, must_change=False)
        db.commit()


def adjust_form(client, **kw):
    data = {'applicant': 'E001', 'leave_type': '01', 'start_date': date.today().isoformat(), 'start_time': '08:00',
            'end_date': date.today().isoformat(), 'end_time': '12:00', 'days': '0', 'hours': '4',
            'agent': '', 'reason': '人資登打', 'csrf_token': csrf(client)}
    data.update(kw)
    return data


def create(client, **kw):
    return client.post('/hr/attendance/new', data=adjust_form(client, **kw))


def flashed(resp):
    return resp.get_data(as_text=True)


class TestAttendance:
    def test_only_manager_can_create(self, client):
        login(client)
        assert client.get('/hr/attendance/new').status_code == 403
        assert create(client).status_code == 403

    def test_create_auto_approved(self, client, app):
        add_manager(app)
        login(client, emp_no='E009')
        resp = create(client)
        assert resp.status_code == 302 and resp.headers['Location'].endswith('/hr/attendance/' + NO)
        with app.app_context():
            head = db.one('SELECT * FROM fil0030 WHERE "單據編號" = %s', (NO,))
            assert head['單據類別'] == 'H05' and head['流水編號'].startswith('H05')
            leave = db.one('SELECT * FROM hrfil1031 WHERE "單號" = %s', (NO,))
            assert leave['申請人'].strip() == 'E001' and leave['假別'].strip() == '01'
            row = db.one('SELECT * FROM fil0040 WHERE "單據編號" = %s', (NO,))
            assert row['單據序號'] == 0 and row['異動數量'] == 4
            obj = db.one('SELECT * FROM a01 WHERE serial_num = %s', (leave['流水編號'],))
            assert obj['flowstatus'] == 'E' and obj['applyby'] == 'S-E001'
            assert db.scalar('SELECT count(*) FROM a01_2') == 0        # 沒有經過簽核流程
        page = client.get('/hr/attendance/' + NO).get_data(as_text=True)
        assert '已核定' in page and NO in page

    def test_validation(self, client, app):
        add_manager(app)
        login(client, emp_no='E009')
        assert '申請人錯誤' in flashed(create(client, applicant='NOBODY'))
        assert '選擇假別' in flashed(create(client, leave_type=''))
        assert '輸入請假時數' in flashed(create(client, days='0', hours='0'))
        assert '請假天數超過法定天數' in flashed(create(client, days='15', hours='0'))

    def test_closed_period(self, client, app):
        add_manager(app)
        with app.app_context():
            db.execute("UPDATE hrfil1002a SET \"關帳年月\" = %s WHERE syskey = 'EMP'",
                      (date.today().strftime('%Y%m01'),))
            db.commit()
        login(client, emp_no='E009')
        assert '已關帳' in flashed(create(client))

    def test_other_employee_cannot_view(self, client, app):
        add_manager(app)
        login(client, emp_no='E009')
        create(client)
        client.post('/logout', data={'csrf_token': csrf(client)})
        login(client, emp_no='E002')
        assert client.get('/hr/attendance/' + NO).status_code == 404
        assert NO not in client.get('/hr/attendance/').get_data(as_text=True)

    def test_applicant_can_view(self, client, app):
        add_manager(app)
        login(client, emp_no='E009')
        create(client)
        client.post('/logout', data={'csrf_token': csrf(client)})
        login(client)                                          # E001 是申請人
        assert NO in client.get('/hr/attendance/').get_data(as_text=True)
        assert '已核定' in client.get('/hr/attendance/' + NO).get_data(as_text=True)

    def test_counts_toward_annual_limit_with_leave(self, client, app):
        """H05、H01 共用同一張年度統計 View，兩種單據要一起算限額。"""
        add_manager(app)
        login(client, emp_no='E009')
        create(client, leave_type='09', days='4', hours='0')      # 婚假限 8 天，先用 4 天
        client.post('/logout', data={'csrf_token': csrf(client)})
        login(client)
        from .test_app import create as create_leave
        resp = create_leave(client, leave_type='09', days='5', hours='0')
        assert '請假天數超過法定天數' in flashed(resp)

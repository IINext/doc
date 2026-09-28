"""示範資料（flask --app erp seed-demo）：建立後應該可以直接登入、送簽、核准。需要 ERP_TEST_DATABASE_URL。

conftest 的 app fixture 會先跑一份測試用資料（見 conftest.seed），這裡先清空再灌示範資料，
確保測的是 demo.seed() 自己、不是 conftest 的資料。
"""
from datetime import date, timedelta

from erp import db, demo
from erp.tests.conftest import SEEDED_TABLES, csrf, login


def reseed_with_demo(app):
    with app.app_context():
        db.execute('TRUNCATE ' + ', '.join(SEEDED_TABLES))
        db.commit()
        assert not demo.already_seeded()
        demo.seed()
        db.commit()
        assert demo.already_seeded()


def next_monday():
    today = date.today()
    return today + timedelta(days=7 - today.weekday())


def test_seed_creates_working_demo(client, app):
    reseed_with_demo(app)
    mon = next_monday().isoformat()

    login(client, emp_no='E001', password=demo.PASSWORD)
    resp = client.post('/hr/leave/new', data={
        'applicant': 'E001', 'leave_type': '01', 'start_date': mon, 'start_time': '08:00',
        'days': '0', 'hours': '4', 'agent': '', 'reason': '試用', 'csrf_token': csrf(client)})
    assert resp.status_code == 302
    no = resp.headers['Location'].rsplit('/', 1)[-1]
    resp = client.post(f'/hr/leave/{no}/submit', data={'csrf_token': csrf(client)}, follow_redirects=True)
    assert '已送簽' in resp.get_data(as_text=True)

    # 課長（E002）待簽清單看得到，同意後換經理（E004）
    client.post('/logout', data={'csrf_token': csrf(client)})
    login(client, emp_no='E002', password=demo.PASSWORD)
    assert no in client.get('/flow/').get_data(as_text=True)
    resp = client.post(f'/hr/leave/{no}/approve', data={'csrf_token': csrf(client)}, follow_redirects=True)
    assert '已同意' in resp.get_data(as_text=True)

    client.post('/logout', data={'csrf_token': csrf(client)})
    login(client, emp_no='E004', password=demo.PASSWORD)
    assert no in client.get('/flow/').get_data(as_text=True)
    resp = client.post(f'/hr/leave/{no}/approve', data={'csrf_token': csrf(client)}, follow_redirects=True)
    assert '簽核完成' in resp.get_data(as_text=True)

    # 人資（E009）是 H01 的單據管理員，可以新增出勤調整單
    client.post('/logout', data={'csrf_token': csrf(client)})
    login(client, emp_no='E009', password=demo.PASSWORD)
    assert client.get('/hr/attendance/new').status_code == 200


def test_seed_twice_refuses(app):
    reseed_with_demo(app)
    with app.app_context():
        try:
            demo.seed()
            assert False, '應該要拒絕重複執行'
        except RuntimeError as e:
            assert 'E001' in str(e)

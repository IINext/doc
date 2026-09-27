"""簽核整合測試：核准、依序多關、退回與取回、作廢、會簽、副本、加簽、待處理、取消退回。需要 ERP_TEST_DATABASE_URL。"""
from datetime import date

import pytest

from erp import db, edb
from erp.auth import set_password
from erp.magic import roc_date7

from .conftest import PASSWORD, csrf, login
from .test_app import create, leave_form

NO = roc_date7(date.today()) + '001'


def add_employee(app, no, name, serial, posi, manages=None):
    with app.app_context():
        db.insert('fil0010', {'serial_num': serial, '員工編號': no, '員工姓名': name, '公司代碼': '1',
                              '部門編號': 'D01', 'depserial': 'G-D01', 'compserial': 'C-1', 'flowposi': posi,
                              'party': 'A', 'replaceby': ' ', 'entryid': ' '})
        set_password(no, PASSWORD, must_change=False)
        if manages:
            db.insert('a60_8', {'serial_num': serial, 'serial_num_seq': 1, 'depid': manages, 'recordid': 'R-' + serial})
        db.commit()


def add_node(app, seq, **kw):
    with app.app_context():
        db.insert('a20_1', {'serial_num': 'F-H01', 'compid': 'C-1', 'level_': 0, 'serial_num_seq': seq,
                            'posiid': ' ', 'signorcc': 1, '指定人員': ' ', 'appdept': ' ', 'flowdept': ' ', **kw})
        db.commit()


def switch(client, emp_no):
    client.post('/logout', data={'csrf_token': csrf(client)})
    login(client, emp_no=emp_no)


def submitted(client):
    """E001 建立並送簽一張請假單。"""
    login(client)
    create(client)
    client.post(f'/hr/leave/{NO}/submit', data={'csrf_token': csrf(client)})


def post(client, action, **data):
    return client.post(f'/hr/leave/{NO}/{action}', data={'csrf_token': csrf(client), **data}, follow_redirects=True)


def status(app):
    with app.app_context():
        return db.scalar('SELECT "簽核狀態" FROM viewfilh001 WHERE "單號" = %s', (NO,))


def flows(app):
    with app.app_context():
        return [(r['serial_num_seq'], r['assignedto'], r['signedtype'], r['signorcc'])
                for r in db.query('SELECT * FROM a01_2 ORDER BY signorcc DESC, serial_num_seq')]


def test_approve_single_step(client, app):
    submitted(client)
    switch(client, 'E002')
    assert NO in client.get('/flow/').get_data(as_text=True)
    page = client.get(f'/hr/leave/{NO}').get_data(as_text=True)
    assert '輪到您簽核' in page
    resp = post(client, 'approve', comment='准假')
    assert '簽核完成' in resp.get_data(as_text=True)
    assert status(app) == 'E'
    with app.app_context():
        row = db.one('SELECT * FROM a01_2')
        assert (row['signedtype'], row['signedby'], row['folder'], row['註解']) == ('1', 'S-E002', 'E', '准假')
    assert NO not in client.get('/flow/').get_data(as_text=True)
    assert '輪到您簽核' not in client.get(f'/hr/leave/{NO}').get_data(as_text=True)


def test_two_steps_in_order(client, app):
    add_employee(app, 'E004', '林經理', 'S-E004', 'P-DIR', manages='G-D01')
    add_node(app, 20, posiid='P-DIR')
    submitted(client)
    assert [f[:3] for f in flows(app)] == [(10, 'S-E002', '0'), (20, 'S-E004', '0')]

    switch(client, 'E004')                                   # 還沒輪到第二關
    assert NO not in client.get('/flow/').get_data(as_text=True)
    assert '目前不是輪到您簽核' in post(client, 'approve').get_data(as_text=True)

    switch(client, 'E002')
    post(client, 'approve')
    assert status(app) == 'I'

    switch(client, 'E004')
    assert NO in client.get('/flow/').get_data(as_text=True)
    post(client, 'approve')
    assert status(app) == 'E'


def test_requester_cannot_approve(client):
    submitted(client)
    assert '目前不是輪到您簽核' in post(client, 'approve').get_data(as_text=True)


def test_reject_withdraw_and_resubmit(client, app):
    submitted(client)
    switch(client, 'E002')
    assert '請輸入退回原因' in post(client, 'reject', reason='  ').get_data(as_text=True)
    post(client, 'reject', reason='日期寫錯')
    assert status(app) == 'D'
    with app.app_context():
        msg = db.one('SELECT * FROM messages')
        assert msg['messageto'] == 'S-E001' and '日期寫錯' in msg['message'] and msg['createby'] == 'S-E002'

    switch(client, 'E001')
    page = client.get(f'/hr/leave/{NO}').get_data(as_text=True)
    assert '日期寫錯' in page and '取回修正' in page
    assert '已退回，請先取回修正' in client.post(f'/hr/leave/{NO}', data=leave_form(client),
                                              follow_redirects=True).get_data(as_text=True)
    post(client, 'withdraw')
    assert status(app) == '0' and flows(app) == []
    client.post(f'/hr/leave/{NO}', data=leave_form(client, days='0', hours='4'))
    post(client, 'submit')
    assert status(app) == 'I' and [f[:3] for f in flows(app)] == [(10, 'S-E002', '0')]


def test_void(client, app):
    submitted(client)
    post(client, 'void')
    assert status(app) == 'A'
    switch(client, 'E002')
    assert '目前不是輪到您簽核' in post(client, 'approve').get_data(as_text=True)


def test_only_requester_can_withdraw(client, app):
    submitted(client)
    switch(client, 'E002')
    assert '只有開單人或申請人可以執行' in post(client, 'withdraw').get_data(as_text=True)
    assert status(app) == 'I'


def test_countersign_all_must_agree(client, app):
    add_employee(app, 'E005', '張會簽', 'S-E005', 'P-STAFF')
    with app.app_context():
        db.execute('TRUNCATE a20_1')
        db.commit()
    add_node(app, 10, **{'會簽判定': 1, '會簽方式': '2'})           # 會簽主項：全部同意
    add_node(app, 11, level_=10, posiid='P-MGR')                    # 子關卡：課長
    add_node(app, 12, level_=10, **{'指定人員': 'S-E005'})          # 子關卡：指定人員（序號 12 + 1）
    submitted(client)
    assert [f[:3] for f in flows(app)] == [(10, ' ', '0'), (11, 'S-E002', '0'), (13, 'S-E005', '0')]

    switch(client, 'E002')
    post(client, 'approve')
    assert status(app) == 'I' and flows(app)[0][2] == '0'           # 還有人沒簽，主項未定

    switch(client, 'E005')
    assert NO in client.get('/flow/').get_data(as_text=True)
    post(client, 'approve')
    assert flows(app)[0][2] == '1' and status(app) == 'E'


def test_countersign_one_reject_fails(client, app):
    add_employee(app, 'E005', '張會簽', 'S-E005', 'P-STAFF')
    with app.app_context():
        db.execute('TRUNCATE a20_1')
        db.commit()
    add_node(app, 10, **{'會簽判定': 1, '會簽方式': '2'})
    add_node(app, 11, level_=10, posiid='P-MGR')
    add_node(app, 12, level_=10, **{'指定人員': 'S-E005'})
    submitted(client)
    switch(client, 'E002')
    post(client, 'reject', reason='不同意')
    assert flows(app)[0][2] == '2' and status(app) == 'D'


def test_copies_created_on_close(client, app):
    add_employee(app, 'E005', '張人事', 'S-E005', 'P-HR')
    add_node(app, 90, signorcc=0, **{'指定人員': 'S-E005'})          # 副本給人事
    submitted(client)
    assert [f for f in flows(app) if f[3] == 0] == []                # 送簽時還沒有副本
    switch(client, 'E002')
    post(client, 'approve')
    assert status(app) == 'E'
    assert [(f[1], f[3]) for f in flows(app) if f[3] == 0] == [('S-E005', 0)]


def test_pending_badge(client):
    submitted(client)
    switch(client, 'E002')
    assert 'bg-danger">1</span>' in client.get('/flow/').get_data(as_text=True)


# ── 加簽、待處理、取消退回 ─────────────────────────────────────────

def allow_add(app):
    with app.app_context():
        db.execute('UPDATE a20_1 SET addflow = 1')
        db.commit()


def test_add_signer_on_approve(client, app):
    add_employee(app, 'E005', '張專員', 'S-E005', 'P-STAFF')
    allow_add(app)
    submitted(client)
    switch(client, 'E002')
    assert 'add_signer' in client.get(f'/hr/leave/{NO}').get_data(as_text=True)
    resp = post(client, 'approve', comment='請專員確認', add_signer='E005')
    assert '已同意' in resp.get_data(as_text=True) and status(app) == 'I'
    assert [f[:3] for f in flows(app)] == [(10, 'S-E002', '1'), (11, 'S-E005', '0')]
    with app.app_context():
        added = db.one('SELECT * FROM a01_2 WHERE serial_num_seq = 11')
        first = db.one('SELECT * FROM a01_2 WHERE serial_num_seq = 10')
        assert added['addflow'] == 1 and added['processfor'] == '加簽人:陳主管'
        assert added['fromid'] == first['recordid'] != ' ' and first['folder'] == '7'

    switch(client, 'E005')
    assert NO in client.get('/flow/').get_data(as_text=True)
    assert '簽核完成' in post(client, 'approve').get_data(as_text=True)
    assert status(app) == 'E'


def test_add_signer_before_next_step(client, app):
    add_employee(app, 'E004', '林經理', 'S-E004', 'P-DIR', manages='G-D01')
    add_employee(app, 'E005', '張專員', 'S-E005', 'P-STAFF')
    add_node(app, 20, posiid='P-DIR')
    allow_add(app)
    submitted(client)
    switch(client, 'E002')
    post(client, 'approve', add_signer='E005')
    switch(client, 'E004')                                   # 加簽人還沒簽，第二關還沒輪到
    assert NO not in client.get('/flow/').get_data(as_text=True)
    switch(client, 'E005')
    post(client, 'approve')
    switch(client, 'E004')
    assert NO in client.get('/flow/').get_data(as_text=True)


def test_add_signer_checks(client, app):
    submitted(client)
    switch(client, 'E002')
    assert 'add_signer' not in client.get(f'/hr/leave/{NO}').get_data(as_text=True)   # 節點不能加簽
    assert '這一關不能加簽' in post(client, 'approve', add_signer='E001').get_data(as_text=True)
    allow_add(app)
    with app.app_context():
        db.execute('UPDATE a01_2 SET addflow = 1')
        db.commit()
    assert '員工編號不能選自己' in post(client, 'approve', add_signer='E002').get_data(as_text=True)
    assert '或已停用' in post(client, 'approve', add_signer='E003').get_data(as_text=True)
    assert '或已停用' in post(client, 'approve', add_signer='X999').get_data(as_text=True)
    assert status(app) == 'I' and [f[:3] for f in flows(app)] == [(10, 'S-E002', '0')]   # 失敗時沒有簽下去


def test_add_signer_sequence_taken(client, app):
    add_employee(app, 'E004', '林經理', 'S-E004', 'P-DIR', manages='G-D01')
    add_employee(app, 'E005', '張專員', 'S-E005', 'P-STAFF')
    add_node(app, 11, posiid='P-DIR')
    allow_add(app)
    submitted(client)
    switch(client, 'E002')
    assert '下一個流程序號已經有關卡' in post(client, 'approve', add_signer='E005').get_data(as_text=True)
    assert flows(app)[0][2] == '0'


def test_hold(client, app):
    submitted(client)
    switch(client, 'E002')
    post(client, 'hold')
    with app.app_context():
        assert db.scalar('SELECT folder FROM a01_2') == '3'
    page = client.get('/flow/').get_data(as_text=True)
    assert '待處理' in page and NO in page and 'bg-danger">1</span>' not in page   # 不算在待簽數量
    form = client.get(f'/hr/leave/{NO}').get_data(as_text=True)
    assert '輪到您簽核' in form and 'leave/' + NO + '/hold' not in form               # 已在待處理
    post(client, 'approve')
    assert status(app) == 'E'


def test_hold_only_my_turn(client, app):
    submitted(client)
    assert '目前不是輪到您簽核' in post(client, 'hold').get_data(as_text=True)


def test_cancel_reject(client, app):
    submitted(client)
    switch(client, 'E002')
    post(client, 'reject', reason='日期寫錯')
    assert '取消退回' in client.get(f'/hr/leave/{NO}').get_data(as_text=True)
    post(client, 'cancel-reject')
    assert status(app) == 'I'
    with app.app_context():
        row = db.one('SELECT * FROM a01_2')
        assert (row['signedtype'], row['signedby'], row['folder'], row['signbackto']) == ('0', ' ', '2', ' ')
        assert '已取消退回' in row['註解']
        msgs = [m['message'] for m in db.query('SELECT * FROM messages WHERE messageto = %s ORDER BY createtime',
                                                ('S-E001',))]
        assert any('已取消退回' in m for m in msgs)
    assert NO in client.get('/flow/').get_data(as_text=True)
    post(client, 'approve')
    assert status(app) == 'E'


def test_cancel_reject_only_rejector(client, app):
    add_employee(app, 'E005', '張專員', 'S-E005', 'P-STAFF')
    submitted(client)
    switch(client, 'E002')
    post(client, 'reject', reason='日期寫錯')
    switch(client, 'E001')                                   # 開單人不能取消別人的退回
    assert '找不到可以取消的退回' in post(client, 'cancel-reject').get_data(as_text=True)
    switch(client, 'E005')                                   # 不在流程上的人看不到這張單
    assert post(client, 'cancel-reject').status_code == 404
    assert status(app) == 'D'


def test_cancel_reject_after_withdraw(client, app):
    submitted(client)
    switch(client, 'E002')
    post(client, 'reject', reason='日期寫錯')
    switch(client, 'E001')
    post(client, 'withdraw')
    switch(client, 'E002')                                   # 流程已刪除，簽核人也看不到這張單了
    assert post(client, 'cancel-reject').status_code == 404
    with app.app_context():
        with pytest.raises(edb.EdbError, match='找不到可以取消的退回'):
            edb.cancel_reject(db.scalar('SELECT serial_num FROM a01'), 'S-E002')
    assert status(app) == '0'


def test_cancel_countersign_reject(client, app):
    add_employee(app, 'E005', '張會簽', 'S-E005', 'P-STAFF')
    with app.app_context():
        db.execute('TRUNCATE a20_1')
        db.commit()
    add_node(app, 10, **{'會簽判定': 1, '會簽方式': '2'})
    add_node(app, 11, level_=10, posiid='P-MGR')
    add_node(app, 12, level_=10, **{'指定人員': 'S-E005'})
    submitted(client)
    switch(client, 'E002')
    post(client, 'reject', reason='不同意')
    assert status(app) == 'D' and flows(app)[0][2] == '2'
    post(client, 'cancel-reject')
    assert status(app) == 'I' and flows(app)[0][2] == '0'           # 主項重新計算
    post(client, 'approve')
    switch(client, 'E005')
    post(client, 'approve')
    assert status(app) == 'E'

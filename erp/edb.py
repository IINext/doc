"""電子簽核引擎（由 Magic 的 EDB 專案轉換）。

- create_object()：EDB #54 ObjProperties(Batch)，建立單據的簽核物件（A01）與授權（A01_4）
- submit()：EDB #7 表單送簽(正本)，依 A20_1 的流程設定產生簽核流程（A01_2）
- create_activity()：EDB #55 CreateActivity，寫活動記錄（A01_3）
- approve()／reject()／hold()／cancel_reject()：Home #94 SignDocument 的同意（含加簽）、退回、待處理、取消退回
- withdraw()／void()：開單人取回修正、作廢

EDB 資料表在 Oracle 用英文欄位名稱，這裡照資料庫的名稱寫，註解標示 Magic 的名稱。
狀態碼（A01.flowstatus）：'0' 草稿、'I' 簽核中、'E' 結案、'A' 作廢、'D' 退回。
"""
import secrets
import uuid
from datetime import datetime
from decimal import Decimal, InvalidOperation

from . import db
from .magic import add_months, from_date, from_time


class EdbError(Exception):
    pass


def _now():
    return datetime.now()


def employee(serial):
    return db.one('SELECT * FROM viewofemp WHERE serialno = %s', (serial,))


def employee_by_no(emp_no):
    return db.one('SELECT * FROM viewofemp WHERE empid = %s', (emp_no,))


def flow_status(serial):
    """GFn_JobFlowStatus：A01.flowstatus，還沒有簽核物件時是 ''。"""
    return db.scalar('SELECT flowstatus FROM a01 WHERE serial_num = %s', (serial,)) or ''


def create_activity(serial, activity, actor_serial, version=0, seq=0, ref=' '):
    """EDB #55：activity 欄位只有 1 個字元，原程式傳 'Open'、'Abandon' 實際存成 'O'、'A'。"""
    last = db.scalar('SELECT max(activity_seqno) FROM a01_3 WHERE serial_num = %s AND version = %s '
                     'AND serial_num_seq = %s', (serial, version, seq)) or 0
    now = _now()
    db.insert('a01_3', {'serial_num': serial, 'version': version, 'serial_num_seq': seq,
                        'activity_seqno': last + 1, 'activity': activity[:1], 'date_': from_date(now.date()),
                        'time_': from_time(now.time()), 'employeeid': actor_serial, 'refdocid': ref})


def create_object(serial, name, owner_serial, applicant_serial='', status='', urgent=False, special=False):
    """EDB #54 ObjProperties(Batch)：建立或更新 A01，並授權開單人與申請人。"""
    now = _now()
    owner = employee(owner_serial)
    if owner is None:
        raise EdbError('找不到開單人')
    flow = 'E' if status == 'E' else '0'
    values = {
        'name': name,                                         # 單據名稱
        'owner': owner_serial,                                # 開單人流水號
        'status': flow,                                       # 狀態
        'flowstatus': flow,                                   # 簽核狀態
        'applyby': applicant_serial or owner_serial,          # 申請人流水號
        'companyid': owner['compserial'],                     # 公司流水號
        'deptid': owner['depserial'],                         # 部門流水號
        'costdeptid': owner['depserial'],                     # 成本歸屬部門
        'urgency': int(urgent), 'special': int(special),
        'duedate': from_date(add_months(now.date(), 12)),     # 簽核期限：開單日加一年
        'connectid': secrets.randbelow(10 ** 8),
    }
    exists = db.one('SELECT createdate, createtime FROM a01 WHERE serial_num = %s', (serial,))
    if exists:
        db.update('a01', values, 'serial_num = %s', (serial,))
    else:
        db.insert('a01', {'serial_num': serial, 'createdate': from_date(now.date()),
                          'createtime': from_time(now.time()), **values})
    for person in dict.fromkeys([owner_serial, applicant_serial or owner_serial]):
        db.execute("""INSERT INTO a01_4 (serial_num, toid, write, read) VALUES (%s, %s, 1, 1)
                      ON CONFLICT (serial_num, toid) DO UPDATE SET write = 1, read = 1""", (serial, person))


def _compare(value, op, content):
    """GetCndValue：CASE(條件式, '>', 值>內容, …, 值=內容)。兩邊都是數字時比數值，否則比文字。"""
    try:
        left, right = Decimal(str(value).strip()), Decimal(str(content).strip())
    except (InvalidOperation, ValueError):
        left, right = str(value).rstrip(), str(content).rstrip()
    return {'>': left > right, '<': left < right, '>=': left >= right, '<=': left <= right,
            '<>': left != right}.get(op.strip(), left == right)


def _node_applies(node, values):
    """流程節點的條件（條件欄位 cndfield、條件式 cndexpression、條件內容 cndcontent）。
    條件欄位是表單上的欄位名稱，原程式用 VarCurrN 依名稱取值；這裡從 values 取。"""
    field = node['cndfield'].strip()
    if not field or not node['cndexpression'].strip():
        return True
    if field not in values:
        raise EdbError(f'流程條件用到的欄位「{field}」沒有提供')
    return _compare(values[field], node['cndexpression'], node['cndcontent'])


def _has_assignee(serial, person):
    return db.one('SELECT 1 FROM a01_2 WHERE serial_num = %s AND assignedto = %s', (serial, person)) is not None


def _record_id(serial):
    """EDB #4 新增序號(ole)：單據流水號 + GUID。"""
    return serial.strip() + str(uuid.uuid4()).upper()


def _add_flow(serial, node, seq, assignee, urgent, in_progress=True):
    """新增一筆 A01_2（單據流程）。

    原程式用 Link Write 寫入：流程序號已經存在時會覆蓋那一筆（例如同一職位有多人，序號和下一個節點重疊），
    這裡照同樣的行為先刪除再寫入。
    """
    now = _now()
    db.execute('DELETE FROM a01_2 WHERE serial_num = %s AND serial_num_seq = %s', (serial, seq))
    free = bool(node['freesign'])                             # 免簽：直接記為已簽
    db.insert('a01_2', {
        'serial_num': serial, 'version': node['level_'], 'serial_num_seq': seq,
        'assignedto': assignee,                               # 應簽核人員
        'signedtype': '0',                                    # 簽核結果：未簽
        'signorcc': node['signorcc'],                         # 正副本
        'folder': '1' if urgent else '2',                     # 資料夾
        'addflow': node['addflow'], '加簽通知': node['加簽通知'],
        'free2sign': node['freesign'], 'assigncostdept': node['assigncostdept'], 'dataedit': node['dataedit'],
        'signedby': assignee if free else ' ',
        'signeddate': from_date(now.date()) if free else '00000000',
        'signedtime': from_time(now.time()) if free else '000000',
        '會簽判定': node['會簽判定'], '會簽方式': node['會簽方式'],
        'singature_line': node['singature_line'], 'singature_seq': node['singature_seq'],
        'recordid': _record_id(serial),
    })
    if in_progress:
        db.execute("UPDATE a01 SET flowstatus = 'I' WHERE serial_num = %s", (serial,))


def _approvers_by_position(posiid, dept_serial=None, jurisdiction_of=None):
    """依流程職位找人：flowposi = 節點職稱代碼，
    並且「管轄申請人部門」（A60_8）或「屬於指定部門」。有代理人（replaceby）時由代理人簽。"""
    if jurisdiction_of is not None:
        rows = db.query("""SELECT e.serialno, e.replaceby FROM viewofemp e
                           JOIN a60_8 j ON j.serial_num = e.serialno AND j.depid = %s
                           WHERE e.flowposi = %s ORDER BY e.serialno""", (jurisdiction_of, posiid))
    else:
        rows = db.query('SELECT serialno, replaceby FROM viewofemp WHERE flowposi = %s AND depserial = %s '
                        'ORDER BY serialno', (posiid, dept_serial))
    return [r['replaceby'].strip() or r['serialno'] for r in rows]


def _generate(serial, obj, reg, emp, values, designated=(), designated_dept='', copies=False):
    """依 A20_1 的流程節點產生 A01_2。copies=False 產生正本（送簽），True 產生副本（結案時，EDB #11）。
    回傳 (有成立的節點, 訊息清單)。"""
    messages = []
    applicant = obj['applyby'].strip()
    dept, comp = emp['depserial'], emp['compserial']
    exclude_applicant = bool(reg['流程獨立否'])               # 申請人免簽
    merge_same = bool(reg['同人合併'])
    nodes = db.query("""SELECT * FROM a20_1
                        WHERE serial_num = %s AND compid = %s AND signorcc = %s
                          AND (appdept = ' ' OR appdept = %s)
                        ORDER BY serial_num_seq""", (reg['serial_num'], comp, 0 if copies else 1, dept))
    if not nodes and not copies:
        messages.append('員工歸屬公司的流程尚未設定')
    ok = False
    for node in nodes:
        if not _node_applies(node, values):
            continue
        if not ok and not copies:                             # 設定核銷人員（第一個成立的節點時）
            verifier_posi = reg['屬性中類名稱'].strip()         # 簽核後程式：核銷人員的職位
            people = _approvers_by_position(verifier_posi, jurisdiction_of=dept) if verifier_posi else []
            if people:
                db.execute('UPDATE a01 SET verifiedby = %s WHERE serial_num = %s', (people[-1], serial))
        ok = True
        base = node['serial_num_seq']
        add = lambda seq, person: _add_flow(serial, node, seq, person, obj['urgency'],  # noqa: E731
                                            in_progress=not copies)
        if node['會簽判定']:                                   # 會簽主項（沒有指定人員）
            add(base, ' ')
            continue
        if node['bycomp']:                                    # 指定欄位
            raise EdbError('流程節點使用「指定欄位」，新系統尚未支援，請洽系統管理員')
        if node['指定人員'].strip():
            people = [p.strip() for p in designated if p.strip()] if node['指定人員'].strip() == '#' \
                else [node['指定人員'].strip()]
            if node['指定人員'].strip() == '#' and not people:
                messages.append('程式應而未指定簽核人員')
            for i, person in enumerate(people, 1):
                if _has_assignee(serial, person) or (exclude_applicant and person == applicant):
                    continue
                add(base + i, person)
            continue
        flowdept = node['flowdept'].strip()                   # 簽核部門欄位
        if flowdept:
            people = _approvers_by_position(node['posiid'],
                                            dept_serial=designated_dept if flowdept == '#' else flowdept)
        else:
            people = _approvers_by_position(node['posiid'], jurisdiction_of=dept)
        if not people:
            messages.append(f'沒有該部門職稱人員：{node["posiid"]}')
        for i, person in enumerate(people):
            if merge_same and _has_assignee(serial, person):
                continue
            if exclude_applicant and person == applicant:
                continue
            add(base + i, person)
    # 刪除沒有人員的流程（會簽主項除外）
    db.execute("DELETE FROM a01_2 WHERE serial_num = %s AND trim(assignedto) = '' AND \"會簽判定\" = 0", (serial,))
    if merge_same and not copies:                             # 同一人重複出現：後面的改為免簽
        db.execute("""UPDATE a01_2 f SET free2sign = 1
                      WHERE f.serial_num = %s AND f.version = 0 AND f.signorcc = 1
                        AND EXISTS (SELECT 1 FROM a01_2 p
                                    WHERE p.serial_num = f.serial_num AND p.version = 0 AND p.signorcc = 1
                                      AND p.serial_num_seq < f.serial_num_seq AND p.assignedto = f.assignedto)""",
                   (serial,))
    return ok, messages


def _context(serial, form_code=None):
    """送簽需要的資料：A01（鎖定）、申請人、表單的元件註冊（A20）。"""
    obj = db.one('SELECT * FROM a01 WHERE serial_num = %s FOR UPDATE', (serial,))
    if obj is None:
        raise EdbError('單據尚未建立簽核物件')
    emp = employee(obj['applyby'].strip() or obj['owner'])
    reg = db.one('SELECT * FROM a20 WHERE job_type = %s LIMIT 1', (form_code or serial[:3],))
    return obj, emp, reg


def submit(serial, signing_category='', designated=(), designated_dept='', values=None, form_code=None):
    """EDB #7 表單送簽(正本)。回傳 (成功否, 訊息清單)。

    signing_category：簽核類別（流程條件常用的欄位）
    designated：程式指定的簽核人員（流程節點的指定人員為 '#' 時使用）
    designated_dept：程式指定部門（流程節點的簽核部門欄位為 '#' 時使用）
    values：流程條件可以用的表單欄位值（欄位名稱 → 值）
    """
    values = {'簽核類別': signing_category, **(values or {})}
    obj, emp, reg = _context(serial, form_code)
    messages = []
    if reg is None:
        messages.append(f'元件代碼(單據前三碼)尚未註冊：{form_code or serial[:3]}')
    ok = False
    if emp is not None and reg is not None:
        if reg['visible']:                                    # 免送簽核
            db.execute("UPDATE a01 SET status = %s, flowstatus = 'E' WHERE serial_num = %s",
                       (reg['laststatus'], serial))
            ok = True
        else:
            ok, messages = _generate(serial, obj, reg, emp, values, designated, designated_dept)
        create_activity(serial, 'Open', obj['applyby'].strip() or obj['owner'])
    if ok:
        db.execute('UPDATE a01 SET locked = 1 WHERE serial_num = %s', (serial,))   # 已送簽
    else:
        messages.append('送簽失敗: 尚未設定流程 !!')
    return ok, messages


# ── 簽核（Home #94 SignDocument、#79 別人給我的文件夾、EDB #26 MyGenRecords） ─────────
#
# A01_2 的資料夾（folder）：'1' 急件待簽、'2' 一般待簽、'3' 待處理、'6' 已退回、'7' 已簽、'E' 結案
# 簽核結果（signedtype）：'0' 未簽、'1' 同意、'2' 退回
# 會簽：會簽主項（會簽判定 = 1）底下的子關卡 version = 主項的序號

PENDING_FOLDERS = ('1', '2', '3')

# 輪到這一關的條件（EDB #26 MyGenRecords）：
# - 最上層關卡：緊鄰的上一個最上層正本、非免簽關卡已同意（或沒有上一關）
# - 會簽子關卡：會簽主項還沒有結果，而且主項之前的最上層關卡已同意
# - 後面的關卡都還沒有人簽過
# 原程式找「上一關」不分層級，前一關是會簽時會卡在某個子關卡；這裡只看最上層。
_TURN_SQL = """
    f.signorcc = 1 AND f.free2sign = 0 AND f.signedtype = '0' AND f.folder IN ('1', '2', '3')
    AND o.flowstatus = 'I'
    AND (f.version = 0 OR EXISTS (SELECT 1 FROM a01_2 m WHERE m.serial_num = f.serial_num
                                  AND m.serial_num_seq = f.version AND m.signedtype = '0'))
    AND coalesce((SELECT p.signedtype FROM a01_2 p
                  WHERE p.serial_num = f.serial_num AND p.version = 0 AND p.signorcc = 1 AND p.free2sign = 0
                    AND p.serial_num_seq < CASE WHEN f.version = 0 THEN f.serial_num_seq ELSE f.version END
                  ORDER BY p.serial_num_seq DESC LIMIT 1), '1') = '1'
    AND NOT EXISTS (SELECT 1 FROM a01_2 n WHERE n.serial_num = f.serial_num
                    AND n.serial_num_seq > f.serial_num_seq AND n.signedtype >= '1')
"""


def pending(user_serial, form_codes=None):
    """輪到 user_serial 簽的關卡。form_codes 限定表單代碼（單據流水號前三碼）。"""
    sql = f"""SELECT f.*, o.name, o.owner, o.applyby, o.flowstatus, o.urgency, o.createdate, o.createtime,
                     substr(f.serial_num, 1, 3) AS form_code, a.guname AS form_name
              FROM a01_2 f JOIN a01 o ON o.serial_num = f.serial_num
              LEFT JOIN a20 a ON a.job_type = substr(f.serial_num, 1, 3)
              WHERE f.assignedto = %s AND {_TURN_SQL}"""
    params = [user_serial]
    if form_codes is not None:
        sql += ' AND substr(f.serial_num, 1, 3) = ANY(%s)'
        params.append(list(form_codes))
    return db.query(sql + ' ORDER BY o.urgency DESC, f.serial_num, f.serial_num_seq', params)


def my_turn(serial, user_serial):
    """user_serial 在這張單上目前可以簽的關卡（沒有就回傳 None）。"""
    return db.one(f"""SELECT f.* FROM a01_2 f JOIN a01 o ON o.serial_num = f.serial_num
                      WHERE f.serial_num = %s AND f.assignedto = %s AND {_TURN_SQL}
                      ORDER BY f.serial_num_seq LIMIT 1""", (serial, user_serial))


def history(serial):
    """簽核歷程（正本、副本），附人員姓名。"""
    return db.query("""SELECT f.*, a.empname AS assignee_name, s.empname AS signer_name
                       FROM a01_2 f
                       LEFT JOIN viewofemp a ON a.serialno = f.assignedto
                       LEFT JOIN viewofemp s ON s.serialno = f.signedby
                       WHERE f.serial_num = %s ORDER BY f.signorcc DESC, f.serial_num_seq""", (serial,))


def create_message(ref_serial, to_serial, text, sender_serial, kind='N'):
    """EDB #38 CreateMessageBatch：寫一則訊息（Messages）。kind：Q 問、R 答、N 通知。截止日期為一個月後。"""
    from .magic import utc_guid
    now = _now()
    db.insert('messages', {'serial_num': 'MSG' + utc_guid(), 'createby': sender_serial, 'messageto': to_serial,
                           'refdocument': ref_serial, '類型': kind, 'createdate': from_date(now.date()),
                           'createtime': from_time(now.time()), 'message': text,
                           'invaliddate': from_date(add_months(now.date(), 1))})


def _append_note(old, text):
    old = (old or '').strip()
    return f'{old},{text}' if old and text else (old or text)


def _lock_turn(serial, user_serial):
    obj = db.one('SELECT * FROM a01 WHERE serial_num = %s FOR UPDATE', (serial,))
    if obj is None:
        raise EdbError('找不到這張單的簽核資料')
    row = my_turn(serial, user_serial)
    if row is None:
        raise EdbError('目前不是輪到您簽核這張單')
    return obj, row


def _countersign(serial, parent_seq):
    """會簽：依子關卡的結果決定會簽主項的結果（Home #94 子任務「會簽」）。
    會簽方式：1 過半同意、2 全部同意、3 一人同意、4 三分之二同意、5 一人讀取即可。"""
    parent = db.one('SELECT * FROM a01_2 WHERE serial_num = %s AND serial_num_seq = %s AND "會簽判定" = 1',
                    (serial, parent_seq))
    if parent is None:
        return
    kids = db.query('SELECT signedtype, read, free2sign FROM a01_2 WHERE serial_num = %s AND version = %s',
                    (serial, parent_seq))
    total = len(kids)
    yes = sum(1 for k in kids if k['signedtype'] == '1' or k['free2sign'])
    no = sum(1 for k in kids if k['signedtype'] == '2')
    seen = sum(1 for k in kids if k['signedtype'] in ('1', '2') or k['read'] or k['free2sign'])
    way = parent['會簽方式'].strip()
    result = '0'
    if (way == '1' and yes >= total / 2) or (way == '2' and yes == total) or (way == '3' and yes >= 1) \
            or (way == '4' and yes >= total / 3 * 2) or (way == '5' and seen >= 1):
        result = '1'
    if (way == '1' and no >= total / 2) or (way == '2' and no >= 1) or (way == '3' and yes == 0 and no != 0) \
            or (way == '4' and no >= total / 3 * 2):
        result = '2'
    now = _now()
    db.execute("""UPDATE a01_2 SET signedtype = %s, folder = '2', read = %s,
                  signeddate = %s, signedtime = %s WHERE serial_num = %s AND serial_num_seq = %s""",
               (result, int(result != '0'), from_date(now.date()) if result != '0' else '00000000',
                from_time(now.time()) if result != '0' else '000000', serial, parent_seq))
    if result == '2':
        db.execute("UPDATE a01 SET flowstatus = 'D' WHERE serial_num = %s", (serial,))


def _all_approved(serial):
    """結案判斷：最上層的正本、非免簽關卡都已同意。"""
    return db.one("""SELECT 1 FROM a01_2 WHERE serial_num = %s AND version = 0 AND signorcc = 1
                     AND free2sign = 0 AND signedtype <> '1' LIMIT 1""", (serial,)) is None


def _close(serial, obj, values):
    """結案：狀態改為 E，並依流程設定產生副本（EDB #11 表單送簽(副本)）。"""
    db.execute("UPDATE a01 SET flowstatus = 'E' WHERE serial_num = %s", (serial,))
    emp = employee(obj['applyby'].strip() or obj['owner'])
    reg = db.one('SELECT * FROM a20 WHERE job_type = %s LIMIT 1', (serial[:3],))
    if emp is not None and reg is not None:
        _generate(serial, obj, reg, emp, values or {}, copies=True)


def _signer_to_add(emp_no, user_serial, row):
    """加簽對象的檢查（Home #96 加簽）。回傳員工資料。"""
    from .auth import is_disabled
    if not row['addflow']:
        raise EdbError('這一關不能加簽')
    emp = db.one('SELECT * FROM fil0010 WHERE "員工編號" = %s', (emp_no.strip(),))
    if emp is None or is_disabled(emp):
        raise EdbError(f'找不到加簽的員工 {emp_no.strip()}，或已停用')
    if emp['serial_num'] == user_serial:
        raise EdbError('員工編號不能選自己')
    return emp


def _add_signer(serial, obj, row, emp, user_serial):
    """Home #94 子任務「簽核」→ Create加簽：在目前這一關的下一個序號插入加簽人，同一層（父階序號相同）。

    原程式固定用「流程序號 + 1」，序號已被使用時寫入會失敗；這裡同樣不覆蓋，改為顯示錯誤。
    """
    seq = row['serial_num_seq'] + 1
    if db.one('SELECT 1 FROM a01_2 WHERE serial_num = %s AND serial_num_seq = %s', (serial, seq)):
        raise EdbError('下一個流程序號已經有關卡，無法在這一關加簽，請洽系統管理員調整流程序號')
    me = employee(user_serial)
    db.insert('a01_2', {
        'serial_num': serial, 'version': row['version'], 'serial_num_seq': seq,
        'assignedto': emp['serial_num'], 'signedtype': '0', 'signorcc': 1,
        'folder': '1' if obj['urgency'] else '2',
        'addflow': 1,                                          # 加簽（加簽人也可以再加簽）
        'processfor': f'加簽人:{(me or {}).get("empname", "").strip()}'[:60],     # 執行說明
        'fromid': row['fromid'] if row['fromid'].strip() else row['recordid'],   # 來源或加簽人
        'recordid': _record_id(serial),
    })
    return seq


def approve(serial, user_serial, comment='', values=None, add_signer=None):
    """同意（Home #94 WorkflowSign）。回傳單據的簽核狀態（'I' 簽核中、'E' 結案、'D' 退回）。
    values：結案時產生副本用的流程條件值（同送簽）。
    add_signer：加簽的員工編號，加簽人排在這一關之後，要等他同意才會往下（或結案）。"""
    obj, row = _lock_turn(serial, user_serial)
    if add_signer and add_signer.strip():
        _add_signer(serial, obj, row, _signer_to_add(add_signer, user_serial, row), user_serial)
    now = _now()
    has_next = db.one("""SELECT 1 FROM a01_2 WHERE serial_num = %s AND version = %s AND signorcc = 1
                         AND free2sign = 0 AND serial_num_seq > %s LIMIT 1""",
                      (serial, row['version'], row['serial_num_seq'])) is not None
    closing = not has_next and row['version'] == 0
    db.execute("""UPDATE a01_2 SET signedtype = '1', signedby = %s, signeddate = %s, signedtime = %s,
                  read = 1, actioncompleted = 1, folder = %s, "註解" = %s
                  WHERE serial_num = %s AND serial_num_seq = %s""",
               (user_serial, from_date(now.date()), from_time(now.time()), 'E' if closing else '7',
                _append_note(row['註解'], comment.strip()), serial, row['serial_num_seq']))
    _touch(serial, now)
    if row['version'] != 0:                                   # 會簽子關卡：重新計算主項
        _countersign(serial, row['version'])
    status = db.scalar('SELECT flowstatus FROM a01 WHERE serial_num = %s', (serial,))
    if status == 'I' and _all_approved(serial):
        _close(serial, obj, values)
        status = 'E'
    return status


def _touch(serial, now):
    db.execute('UPDATE a01 SET "異動日期" = %s, "異動時間" = %s WHERE serial_num = %s',
               (from_date(now.date()), from_time(now.time()), serial))


def hold(serial, user_serial):
    """待處理（Home #94 WorkflowHold）：資料夾改為 '3'，仍然輪到自己簽，只是從待簽數量移到「待處理」。"""
    _, row = _lock_turn(serial, user_serial)
    db.execute("""UPDATE a01_2 SET folder = '3', signedtype = '0' WHERE serial_num = %s AND serial_num_seq = %s""",
               (serial, row['serial_num_seq']))


def cancelable_reject(serial, user_serial):
    """user_serial 退回、而且還可以取消的關卡（單據仍是退回或簽核中，開單人還沒取回）。"""
    return db.one("""SELECT f.* FROM a01_2 f JOIN a01 o ON o.serial_num = f.serial_num
                     WHERE f.serial_num = %s AND f.signedby = %s AND f.signedtype = '2' AND f.signorcc = 1
                       AND o.flowstatus IN ('D', 'I')
                     ORDER BY f.serial_num_seq DESC LIMIT 1""", (serial, user_serial))


def cancel_reject(serial, user_serial):
    """取消退回（Home #94 WorkflowCancelDB）：退回的人把自己的退回撤銷，這一關回到未簽、單據回到簽核中。

    原程式只有簽核人本人可以執行（MnuShow B = 簽核人員）。新系統另外通知開單人退回已取消，
    避免開單人依照先前的退回通知去取回修正。"""
    obj = db.one('SELECT * FROM a01 WHERE serial_num = %s FOR UPDATE', (serial,))
    row = cancelable_reject(serial, user_serial) if obj else None
    if row is None:
        raise EdbError('找不到可以取消的退回（開單人可能已經取回修正）')
    now = _now()
    db.execute("""UPDATE a01_2 SET signedtype = '0', signedby = ' ', signeddate = '00000000', signedtime = '000000',
                  folder = %s, read = 0, actioncompleted = 0, signbackto = ' ', "註解" = %s
                  WHERE serial_num = %s AND serial_num_seq = %s""",
               ('1' if obj['urgency'] else '2', _append_note(row['註解'], '（已取消退回）'),
                serial, row['serial_num_seq']))
    db.execute("UPDATE a01 SET flowstatus = 'I' WHERE serial_num = %s", (serial,))
    _touch(serial, now)
    if row['version'] != 0:                                   # 會簽子關卡：重新計算主項（其他人的退回仍然算）
        _countersign(serial, row['version'])
    back_to = row['signbackto'].strip() or obj['owner']
    create_message(serial, back_to, f'{obj["name"].strip()} 已取消退回，回到簽核中', user_serial)
    return db.scalar('SELECT flowstatus FROM a01 WHERE serial_num = %s', (serial,))


def reject(serial, user_serial, reason, back_to=None):
    """退回（Home #94 WorkflowDrawback）：結果 '2'、資料夾 '6'、單據狀態 'D'，並通知被退回的人（預設開單人）。"""
    reason = (reason or '').strip()
    if not reason:
        raise EdbError('請輸入退回原因')
    obj, row = _lock_turn(serial, user_serial)
    back_to = back_to or obj['owner']
    now = _now()
    db.execute("""UPDATE a01_2 SET signedtype = '2', signedby = %s, signeddate = %s, signedtime = %s,
                  read = 1, folder = '6', signbackto = %s, "註解" = %s
                  WHERE serial_num = %s AND serial_num_seq = %s""",
               (user_serial, from_date(now.date()), from_time(now.time()), back_to,
                _append_note(row['註解'], reason), serial, row['serial_num_seq']))
    if row['version'] != 0:
        _countersign(serial, row['version'])
    else:
        db.execute("UPDATE a01 SET flowstatus = 'D' WHERE serial_num = %s", (serial,))
    _touch(serial, now)
    create_message(serial, back_to, f'{obj["name"].strip()} 退回：{reason}', user_serial, kind='Q')
    return db.scalar('SELECT flowstatus FROM a01 WHERE serial_num = %s', (serial,))


def _owner_or_applicant(obj, user_serial):
    if user_serial not in (obj['owner'].strip(), obj['applyby'].strip()):
        raise EdbError('只有開單人或申請人可以執行')


def withdraw(serial, user_serial):
    """取回修正（Home #94 WorkflowBackToDraft → EDB #14 簽退取回、#17 退回草稿）：
    刪除簽核流程，單據回到草稿，可以修改後重新送簽。"""
    obj = db.one('SELECT * FROM a01 WHERE serial_num = %s FOR UPDATE', (serial,))
    if obj is None:
        raise EdbError('找不到這張單的簽核資料')
    _owner_or_applicant(obj, user_serial)
    if obj['flowstatus'] not in ('I', 'D'):
        raise EdbError('只有簽核中或退回的單可以取回')
    create_activity(serial, 'eRedo', user_serial)
    db.execute('DELETE FROM a01_2 WHERE serial_num = %s', (serial,))
    db.execute("UPDATE a01 SET status = '0', flowstatus = '0', locked = 0 WHERE serial_num = %s", (serial,))


def void(serial, user_serial):
    """作廢（Home #94 WorkflowTrash、EDB #15 表單報廢）。"""
    obj = db.one('SELECT * FROM a01 WHERE serial_num = %s FOR UPDATE', (serial,))
    if obj is None:
        raise EdbError('找不到這張單的簽核資料')
    _owner_or_applicant(obj, user_serial)
    if obj['flowstatus'] in ('E', 'A'):
        raise EdbError('已結案或已作廢的單不能作廢')
    db.execute("UPDATE a01 SET flowstatus = 'A' WHERE serial_num = %s", (serial,))
    create_activity(serial, 'Abandon', user_serial)

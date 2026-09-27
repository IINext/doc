"""電子簽核引擎（由 Magic 的 EDB 專案轉換）。

- create_object()：EDB #54 ObjProperties(Batch)，建立單據的簽核物件（A01）與授權（A01_4）
- submit()：EDB #7 表單送簽(正本)，依 A20_1 的流程設定產生簽核流程（A01_2）
- create_activity()：EDB #55 CreateActivity，寫活動記錄（A01_3）

EDB 資料表在 Oracle 用英文欄位名稱，這裡照資料庫的名稱寫，註解標示 Magic 的名稱。
狀態碼（A01.flowstatus）：'0' 草稿、'I' 簽核中、'E' 結案、'A' 作廢、'D' 退回。
"""
import secrets
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


def _add_flow(serial, node, seq, assignee, urgent):
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
    })
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


def submit(serial, signing_category='', designated=(), designated_dept='', values=None, form_code=None):
    """EDB #7 表單送簽(正本)。回傳 (成功否, 訊息清單)。

    signing_category：簽核類別（流程條件常用的欄位）
    designated：程式指定的簽核人員（流程節點的指定人員為 '#' 時使用）
    designated_dept：程式指定部門（流程節點的簽核部門欄位為 '#' 時使用）
    values：流程條件可以用的表單欄位值（欄位名稱 → 值）
    """
    values = {'簽核類別': signing_category, **(values or {})}
    form_code = form_code or serial[:3]
    messages = []
    obj = db.one('SELECT * FROM a01 WHERE serial_num = %s FOR UPDATE', (serial,))
    if obj is None:
        raise EdbError('單據尚未建立簽核物件')
    applicant = obj['applyby'].strip()
    emp = employee(applicant or obj['owner'])
    reg = db.one('SELECT * FROM a20 WHERE job_type = %s LIMIT 1', (form_code,))
    if reg is None:
        messages.append(f'元件代碼(單據前三碼)尚未註冊：{form_code}')
    ok = False
    if emp is not None and reg is not None:
        dept, comp = emp['depserial'], emp['compserial']
        exclude_applicant = bool(reg['流程獨立否'])           # 申請人免簽
        merge_same = bool(reg['同人合併'])
        if reg['visible']:                                    # 免送簽核
            db.execute("UPDATE a01 SET status = %s, flowstatus = 'E' WHERE serial_num = %s",
                       (reg['laststatus'], serial))
            ok = True
        else:
            nodes = db.query("""SELECT * FROM a20_1
                                WHERE serial_num = %s AND compid = %s AND signorcc = 1
                                  AND (appdept = ' ' OR appdept = %s)
                                ORDER BY serial_num_seq""", (reg['serial_num'], comp, dept))
            if not nodes:
                messages.append('員工歸屬公司的流程尚未設定')
            first = True
            for node in nodes:
                if not _node_applies(node, values):
                    continue
                ok = True
                verifier_posi = reg['屬性中類名稱'].strip()     # 簽核後程式：核銷人員的職位
                if first and verifier_posi:                   # 設定核銷人員（第一個成立的節點時）
                    people = _approvers_by_position(verifier_posi, jurisdiction_of=dept)
                    if people:
                        db.execute('UPDATE a01 SET verifiedby = %s WHERE serial_num = %s', (people[-1], serial))
                first = False
                base = node['serial_num_seq']
                if node['會簽判定']:                           # 會簽主項（沒有指定人員）
                    _add_flow(serial, node, base, ' ', obj['urgency'])
                    continue
                if node['bycomp']:                            # 指定欄位
                    raise EdbError('流程節點使用「指定欄位」，新系統尚未支援，請洽系統管理員')
                if node['指定人員'].strip():
                    people = [p.strip() for p in designated if p.strip()] if node['指定人員'].strip() == '#' \
                        else [node['指定人員'].strip()]
                    if node['指定人員'].strip() == '#' and not people:
                        messages.append('程式應而未指定簽核人員')
                    for i, person in enumerate(people, 1):
                        if _has_assignee(serial, person) or (exclude_applicant and person == applicant):
                            continue
                        _add_flow(serial, node, base + i, person, obj['urgency'])
                    continue
                flowdept = node['flowdept'].strip()           # 簽核部門欄位
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
                    _add_flow(serial, node, base + i, person, obj['urgency'])
        # 刪除沒有人員的流程（會簽主項除外）
        db.execute("DELETE FROM a01_2 WHERE serial_num = %s AND trim(assignedto) = '' AND \"會簽判定\" = 0",
                   (serial,))
        if merge_same:                                        # 同一人重複出現：後面的改為免簽
            db.execute("""UPDATE a01_2 f SET free2sign = 1
                          WHERE f.serial_num = %s AND f.version = 0 AND f.signorcc = 1
                            AND EXISTS (SELECT 1 FROM a01_2 p
                                        WHERE p.serial_num = f.serial_num AND p.version = 0 AND p.signorcc = 1
                                          AND p.serial_num_seq < f.serial_num_seq AND p.assignedto = f.assignedto)""",
                       (serial,))
        create_activity(serial, 'Open', applicant or obj['owner'])
    if ok:
        db.execute('UPDATE a01 SET locked = 1 WHERE serial_num = %s', (serial,))   # 已送簽
    else:
        messages.append('送簽失敗: 尚未設定流程 !!')
    return ok, messages

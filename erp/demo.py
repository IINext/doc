"""示範資料：讓第一次試用的人可以馬上登入、送簽、核准，不用自己一筆一筆建組織資料。

不是正式資料！只建議在專門拿來試用的資料庫執行一次（`flask --app erp seed-demo`）。
正式上線前這些示範帳號、部門、簽核流程都要清掉，改成從舊系統搬過來的真實資料
（用 `erp.env.bat` 換一個乾淨的資料庫是最簡單的做法）。

建立的東西：
    - 部門「生管課」、4 個示範帳號（見 EMPLOYEES），密碼都是 demo1234（正式使用請改密碼）
    - 假別（事假、病假、婚假）、前後各兩個月的行事曆（週末算休假）
    - H01 請假卡兩關簽核（課長 → 經理，第二關可以加簽）、H11 費用申請單一關簽核（課長）
    - E009 是 H01／H05 的單據管理員（人資），可以新增出勤調整單、看到所有請假單
"""
from datetime import date, timedelta

from . import db
from .auth import set_password
from .magic import from_date

PASSWORD = 'demo1234'

EMPLOYEES = [
    ('E001', '王小明', 'S-E001', 'P-STAFF'),   # 一般員工
    ('E002', '陳主管', 'S-E002', 'P-MGR'),     # 課長，D01 部門主管，H01/H11 的第一關
    ('E004', '林經理', 'S-E004', 'P-DIR'),     # 經理，H01 的第二關
    ('E009', '林人資', 'S-E009', 'P-HR'),      # 人資，H01/H05 的單據管理員
]

LEAVE_TYPES = [('01', '事假', 1, 14, 0, 1), ('03', '病假', '0.5', 30, 0, 0), ('09', '婚假', 8, 8, 1, 0)]


def already_seeded():
    return db.one("SELECT 1 FROM fil0010 WHERE \"員工編號\" = 'E001'") is not None


def seed():
    if already_seeded():
        raise RuntimeError('已經有示範資料了（E001 已存在），不要重複執行；'
                          '要重來的話請換一個乾淨的資料庫，重新載入結構。')

    db.insert('fil0025', {'代碼': 'A', '名稱': '日班', '上班起時': '080000', '上班迄時': '170000',
                          '休息起時': '120000', '休息迄時': '130000'})
    db.insert('a30', {'serial_num': 'G-D01', 'groupid': 'D01', 'groupname': '生管課', 'guname': '生管課'})
    for posi, code, name in (('P-MGR', 'MGR', '課長'), ('P-DIR', 'DIR', '經理'), ('P-STAFF', 'STF', '組員'),
                             ('P-HR', 'HR', '人資')):
        db.insert('a40', {'serial_num': posi, 'psoiid': code, 'guname': name})
    for no, name, serial, posi in EMPLOYEES:
        db.insert('fil0010', {'serial_num': serial, '員工編號': no, '員工姓名': name, '公司代碼': '1',
                              '部門編號': 'D01', 'depserial': 'G-D01', 'compserial': 'C-1', 'flowposi': posi,
                              'party': 'A', 'replaceby': ' ', 'entryid': ' '})
        set_password(no, PASSWORD, must_change=False)
    db.insert('a60_8', {'serial_num': 'S-E002', 'serial_num_seq': 1, 'depid': 'G-D01', 'recordid': 'R-S-E002'})
    db.insert('a60_8', {'serial_num': 'S-E004', 'serial_num_seq': 1, 'depid': 'G-D01', 'recordid': 'R2-S-E004'})

    for code, name, min_hours, limit, holidays, reason in LEAVE_TYPES:
        db.insert('fil1014', {'代碼類別': '假別代碼', '系統代碼': code, '代碼名稱': name, '數字參數': min_hours,
                              '數字參數二': limit, '邏輯值': holidays, '邏輯值一': reason})
    db.insert('fil1014', {'代碼類別': '單據類別', '系統代碼': 'H01', '代碼名稱': '請假卡', '文字參數一': 'E009'})
    db.insert('hrfil1002a', {'syskey': 'EMP', '關帳年月': '20000101'})   # 沒有關帳，示範資料不會被擋

    # 行事曆：往前兩個月到往後兩個月，週六日算休假
    today = date.today()
    start = (today.replace(day=1) - timedelta(days=62))
    start -= timedelta(days=start.weekday() + 1)              # 往前抓到最近的星期日
    for w in range(20):
        sunday = start + timedelta(days=7 * w)
        row = {'年月': int(sunday.strftime('%Y%m')), '週': w + 1}
        for i, key in enumerate(['日', '一', '二', '三', '四', '五', '六']):
            d = sunday + timedelta(days=i)
            row[key] = from_date(d)
            row['休假' + key] = 2 if key in ('日', '六') else 0
        db.insert('fil1019', row)

    # 簽核流程：H01 請假卡兩關（課長→經理，經理這關可以加簽），H11 費用申請單一關（課長）
    db.insert('a20', {'serial_num': 'F-H01', 'job_type': 'H01', 'job_id': 'H01', 'guname': '請假卡', 'visible': 0,
                      '流程獨立否': 0, '同人合併': 1})
    db.insert('a20_1', {'serial_num': 'F-H01', 'compid': 'C-1', 'level_': 0, 'serial_num_seq': 10,
                        'posiid': 'P-MGR', 'signorcc': 1, '指定人員': ' ', 'appdept': ' ', 'flowdept': ' '})
    db.insert('a20_1', {'serial_num': 'F-H01', 'compid': 'C-1', 'level_': 0, 'serial_num_seq': 20,
                        'posiid': 'P-DIR', 'signorcc': 1, '指定人員': ' ', 'appdept': ' ', 'flowdept': ' ',
                        'addflow': 1})
    db.insert('a20', {'serial_num': 'F-H11', 'job_type': 'H11', 'job_id': 'H11', 'guname': '費用申請單',
                      'visible': 0, '流程獨立否': 0, '同人合併': 1})
    db.insert('a20_1', {'serial_num': 'F-H11', 'compid': 'C-1', 'level_': 0, 'serial_num_seq': 10,
                        'posiid': 'P-MGR', 'signorcc': 1, '指定人員': ' ', 'appdept': ' ', 'flowdept': ' '})

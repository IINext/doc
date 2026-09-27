"""各張表單共用的小工具（FIL0030 為主檔的單據都用得到）。"""
from . import db
from .magic import end_of_month, to_date

STATUS_TEXT = {'I': '簽核中', 'E': '已簽', 'D': '退回', 'A': '作廢'}   # GFn_SignedStatusCHN，其他是草稿


def is_doc_manager(doc_type, emp_no):
    """單據管理員（ViewFIL0020 的單據管理員代號一～三）可以看所有人的單、代為修改。"""
    return db.one("""SELECT 1 FROM viewfil0020 WHERE "單據類別" = %s
                     AND %s IN ("單據管理員代號", "單據管理員代號二", "單據管理員代號三")""",
                  (doc_type, emp_no)) is not None


def closing_date():
    """人資關帳年月（HRFil1002a，SysKey = 'EMP'）的月底；沒有設定時回傳 None。"""
    d = to_date(db.scalar('SELECT "關帳年月" FROM hrfil1002a WHERE syskey = %s', ('EMP',)))
    return end_of_month(d) if d else None

"""Magic 資料格式的轉換。

舊系統的日期多半存成 char(8) 的 'YYYYMMDD'，空日期是 '00000000'；
時間存成 char(6) 的 'HHMMSS'。新程式內部一律用 date / time，進出資料庫時轉換。
"""
import secrets
from datetime import date, datetime, time, timedelta, timezone

BLANK_DATE = '00000000'


def to_date(s):
    """'20250102' -> date(2025, 1, 2)；'00000000'、空白 -> None。"""
    s = (s or '').strip()
    if not s or s == BLANK_DATE:
        return None
    return datetime.strptime(s, '%Y%m%d').date()


def from_date(d):
    return d.strftime('%Y%m%d') if d else BLANK_DATE


def to_time(s):
    """'083000' -> time(8, 30)；舊資料有 4 碼的 'HHMM'。空白或全 0 回傳 time(0, 0)。"""
    s = (s or '').strip()
    if not s:
        return time(0, 0)
    s = s.ljust(6, '0')
    return time(int(s[:2]) % 24, int(s[2:4]), int(s[4:6]))


def from_time(t):
    return t.strftime('%H%M%S') if t else '000000'


def roc_date7(d):
    """民國年月日 7 碼：2025/01/02 -> '1140102'（Magic：Str(Val(DStr(d,'YYYYMMDD'))-19110000,'7P0')）。"""
    return f'{int(d.strftime("%Y%m%d")) - 19110000:07d}'


def utc_guid(now=None):
    """Utility #8 get GUID - UTC：YYMMDD + 當日毫秒數 + 4 位亂數，取前 17 碼。"""
    now = now or datetime.now(timezone.utc)
    ms = (now.hour * 3600 + now.minute * 60 + now.second) * 1000 + now.microsecond // 1000
    return (now.strftime('%y%m%d') + str(ms) + f'{secrets.randbelow(10000):04d}')[:17]


def end_of_month(d):
    """Magic EOM()。"""
    first_next = (d.replace(day=1) + timedelta(days=32)).replace(day=1)
    return first_next - timedelta(days=1)


def add_months(d, n):
    """Magic AddDate(d, 0, n, 0)：月底會調整到該月最後一天。"""
    month = d.month - 1 + n
    year = d.year + month // 12
    month = month % 12 + 1
    return date(year, month, min(d.day, end_of_month(date(year, month, 1)).day))

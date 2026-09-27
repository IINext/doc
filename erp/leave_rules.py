"""請假單的計算規則（不碰資料庫，方便測試）。

對應 Home #1123「H01.請假申請單(H)」：
- first_day_and_end()：Handler UE_計算截止時間
- plan_details()：存檔按鈕的「分柝明細」迴圈
- time_errors()：UE_ErrCheck 中班別、休息時間的檢查

時間一律用「當天從 0 點起算的秒數」表示；時數用 Decimal（例如 Decimal('0.5')）。
"""
from dataclasses import dataclass
from datetime import timedelta
from decimal import ROUND_DOWN, Decimal

DAY = 86400
HOURS_PER_DAY = 8


@dataclass
class Shift:
    """班別（FIL0025）：上班起迄、休息起迄，單位秒。上班迄 < 上班起 表示跨夜班。"""
    start: int
    end: int
    rest_start: int
    rest_end: int

    @property
    def rest(self):
        return self.rest_end - self.rest_start

    @property
    def overnight(self):
        return self.end < self.start


def _hours_to_sec(h):
    return int(Decimal(h) * 3600)


def _trunc1(x):
    """Magic Fix(x, 2, 1)：無條件捨去到小數 1 位。"""
    return Decimal(x).quantize(Decimal('0.1'), rounding=ROUND_DOWN)


def first_day_and_end(start_sec, days, hours, shift):
    """回傳 (第一天時數, 截止時間秒數)。

    第一天時數：從起始時間到下班可以請的時數（扣掉休息時間，最多 8 小時）；
    只請幾小時（天數 0）時取「可請時數」和「請假時數」較小者。
    舊系統把它存在 FIL0030 的「折讓」欄位。
    """
    days, hours = Decimal(days), Decimal(hours)
    # DifDateTime：起始時間到當天（跨夜班是隔天）下班的時間差，取秒數部分
    total = (DAY if shift.overnight else 0) + shift.end - start_sec
    seconds = total % DAY
    available = seconds - (shift.rest if start_sec <= shift.rest_start else 0)
    first = min(Decimal(HOURS_PER_DAY), _trunc1(Decimal(available) / 3600))
    if days == 0:
        first = min(first, hours)
    # 最後一天剩下的時數
    if days == 0:
        remain = hours - first if hours > first else first
    else:
        remain = (days * HOURS_PER_DAY + hours - first) % HOURS_PER_DAY

    def from_shift_start(h):
        end = shift.start + _hours_to_sec(h)
        return end + shift.rest if end > shift.rest_start else end

    if remain == 0:
        end = shift.end
    elif days == 0 and hours <= first:                 # 當天請完
        end = start_sec + _hours_to_sec(remain)
        if end > shift.rest_start and start_sec <= shift.rest_start:
            end += shift.rest
    else:                                              # 跨到後面的日子，從上班時間起算
        end = from_shift_start(remain)
    if end > DAY:
        end -= DAY
        if end > shift.rest_start and start_sec <= shift.rest_start:
            end += shift.rest
    return first, end


def plan_details(start_date, start_sec, days, hours, first, shift, next_workday):
    """拆成每日明細（FIL0040）。回傳 (明細清單, 截止日期)。

    明細是 dict：序號、日期、時數、起始時間（秒）。
    next_workday(date) 回傳 date 當天或之後第一個可請假的日期（依行事曆與假別是否含假日）。
    第一天從起始時間開始，其他天從上班時間開始；每天最多 8 小時。
    """
    total = Decimal(days) * HOURS_PER_DAY + Decimal(hours)
    day = start_date
    rows = []
    end_date = start_date

    def add(d, h):
        nonlocal end_date
        t1 = start_sec if d == start_date else shift.start
        rows.append({'序號': len(rows) + 1, '日期': d, '時數': h, '起始時間': t1})
        end_date = d + timedelta(days=1) if t1 + _hours_to_sec(h) > DAY else d

    if first < HOURS_PER_DAY:
        day = next_workday(day)
        add(day, first)
        total -= first
        day += timedelta(days=1)
    for _ in range(int(total // HOURS_PER_DAY)):
        day = next_workday(day)
        add(day, Decimal(HOURS_PER_DAY))
        day += timedelta(days=1)
    if total % HOURS_PER_DAY > 0:
        day = next_workday(day)
        add(day, total % HOURS_PER_DAY)
    return rows, end_date


def time_errors(start_sec, end_sec, shift):
    """班別與休息時間的檢查（UE_ErrCheck）。"""
    errors = []
    in_rest = lambda t: shift.rest_start < t < shift.rest_end  # noqa: E731
    if in_rest(start_sec) or in_rest(end_sec):
        errors.append('起始時間不能介於休息時間！')
    if shift.end > shift.start:
        inside = shift.start <= start_sec <= shift.end
    else:
        inside = shift.start <= start_sec <= DAY - 1 or 0 <= start_sec <= shift.end
    if not inside:
        errors.append('起始時間必須介於班別時間')
    return errors


def allowed_hours(min_hours):
    """「時數」下拉選單可選的值，依假別的「至少小時」（原程式 V_小時字串）。"""
    if min_hours == Decimal('0.5'):
        return [Decimal(i) / 2 for i in range(17)]
    if min_hours == 1:
        return [Decimal(i) for i in range(9)]
    if min_hours == 4:
        return [Decimal(0), Decimal(4)]
    return [Decimal(0)]


def min_hours_message(name, min_hours):
    """原程式：Trim(名稱)&'至少要請'&IF(至少小時>8, n天,'')&IF(至少小時 MOD 8=0,'', n小時)。"""
    min_hours = Decimal(min_hours)
    text = f'{name.strip()}至少要請'
    if min_hours > 8:
        text += f'{int(min_hours // 8)}天 '
    if min_hours % 8:
        text += f'{min_hours % 8:g}小時'
    return text

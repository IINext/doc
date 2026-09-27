"""不需要資料庫的規則測試：請假時數計算、每日明細、Magic 格式轉換、單號編碼。"""
from datetime import date, time, timedelta
from decimal import Decimal as D

from erp.leave_rules import Shift, allowed_hours, first_day_and_end, min_hours_message, plan_details, time_errors
from erp.magic import add_months, end_of_month, from_date, roc_date7, to_date, to_time, utc_guid
from erp.numbering import _decode, _encode

H = 3600
DAY_SHIFT = Shift(8 * H, 17 * H, 12 * H, 13 * H)          # 08:00–17:00，休息 12:00–13:00
NIGHT_SHIFT = Shift(20 * H, 5 * H, 0, 1 * H)              # 20:00–隔天 05:00，休息 00:00–01:00

MON = date(2025, 3, 3)                                    # 星期一


def weekdays_only(d):
    while d.weekday() >= 5:
        d += timedelta(days=1)
    return d


class TestFirstDayAndEnd:
    def test_full_day_plus_half(self):
        # 08:00 起請 1 天 4 小時：第一天 8 小時，最後一天從 08:00 起 4 小時到 12:00
        assert first_day_and_end(8 * H, 1, D(4), DAY_SHIFT) == (D(8), 12 * H)

    def test_afternoon_half_day(self):
        assert first_day_and_end(13 * H, 0, D(4), DAY_SHIFT) == (D(4), 17 * H)

    def test_skips_rest_time(self):
        # 10:00 起 4 小時：10–12、13–15
        assert first_day_and_end(10 * H, 0, D(4), DAY_SHIFT) == (D(4), 15 * H)

    def test_spills_to_next_day(self):
        # 13:00 起請 8 小時：當天只剩 4 小時，隔天 08:00 起再 4 小時到 12:00
        assert first_day_and_end(13 * H, 0, D(8), DAY_SHIFT) == (D(4), 12 * H)

    def test_whole_days_end_at_shift_end(self):
        assert first_day_and_end(8 * H, 2, D(0), DAY_SHIFT) == (D(8), 17 * H)

    def test_half_hour(self):
        assert first_day_and_end(8 * H, 0, D('0.5'), DAY_SHIFT) == (D('0.5'), 8 * H + 1800)

    def test_night_shift_keeps_original_behaviour(self):
        # 22:00 起 4 小時，實際應該到 03:00（00–01 休息）。
        # 原程式只在「起始時間早於休息開始」時扣休息時間，跨午夜的休息不會扣，所以算出 02:00；
        # 目前照原程式的結果，方便新舊系統比對。要修正時改 leave_rules.first_day_and_end。
        assert first_day_and_end(22 * H, 0, D(4), NIGHT_SHIFT) == (D(4), 2 * H)


class TestPlanDetails:
    def test_split_over_days(self):
        rows, end = plan_details(MON, 8 * H, 1, D(4), D(8), DAY_SHIFT, weekdays_only)
        assert [(r['日期'], r['時數'], r['起始時間']) for r in rows] == [
            (MON, D(8), 8 * H), (MON + timedelta(days=1), D(4), 8 * H)]
        assert end == MON + timedelta(days=1)

    def test_partial_first_day_and_weekend(self):
        fri = MON + timedelta(days=4)
        rows, end = plan_details(fri, 13 * H, 0, D(8), D(4), DAY_SHIFT, weekdays_only)
        assert [(r['序號'], r['日期'], r['時數'], r['起始時間']) for r in rows] == [
            (1, fri, D(4), 13 * H), (2, MON + timedelta(days=7), D(4), 8 * H)]
        assert end == MON + timedelta(days=7)

    def test_start_on_holiday_moves_to_workday(self):
        sat = MON + timedelta(days=5)
        rows, _ = plan_details(sat, 8 * H, 1, D(0), D(8), DAY_SHIFT, weekdays_only)
        assert [(r['日期'], r['起始時間']) for r in rows] == [(MON + timedelta(days=7), 8 * H)]

    def test_total_matches(self):
        rows, _ = plan_details(MON, 10 * H, 3, D('2.5'), D(6), DAY_SHIFT, weekdays_only)
        assert sum(r['時數'] for r in rows) == D('26.5')


class TestTimeErrors:
    def test_ok(self):
        assert time_errors(8 * H, 12 * H, DAY_SHIFT) == []

    def test_in_rest(self):
        assert '起始時間不能介於休息時間！' in time_errors(12 * H + 1800, 16 * H, DAY_SHIFT)

    def test_outside_shift(self):
        assert '起始時間必須介於班別時間' in time_errors(7 * H, 11 * H, DAY_SHIFT)

    def test_night_shift_after_midnight(self):
        assert time_errors(2 * H, 4 * H, NIGHT_SHIFT) == []


def test_allowed_hours():
    assert allowed_hours(D('0.5'))[:3] == [D(0), D('0.5'), D(1)]
    assert allowed_hours(D(1)) == [D(i) for i in range(9)]
    assert allowed_hours(D(4)) == [D(0), D(4)]
    assert allowed_hours(D(8)) == [D(0)]


def test_min_hours_message():
    assert min_hours_message('婚假 ', D(24)) == '婚假至少要請3天 '
    assert min_hours_message('事假', D(4)) == '事假至少要請4小時'


class TestMagic:
    def test_dates(self):
        assert to_date('20250102') == date(2025, 1, 2)
        assert to_date('00000000') is None and to_date('        ') is None
        assert from_date(None) == '00000000'
        assert roc_date7(date(2025, 1, 2)) == '1140102'

    def test_times(self):
        assert to_time('083000') == time(8, 30)
        assert to_time('0830') == time(8, 30)       # 舊資料有 4 碼的時間

    def test_months(self):
        assert end_of_month(date(2024, 2, 10)) == date(2024, 2, 29)
        assert add_months(date(2025, 1, 31), 1) == date(2025, 2, 28)
        assert add_months(date(2024, 2, 29), 12) == date(2025, 2, 28)
        assert add_months(date(2025, 3, 15), -3) == date(2024, 12, 15)

    def test_guid(self):
        g = utc_guid()
        assert len(g) <= 17 and g.isdigit()


class TestDocNumberEncoding:
    def test_three_digits(self):
        assert _encode(7, 3) == '007' and _decode('007', 3) == 7
        assert _encode(1000, 3) == 'A00' and _decode('A00', 3) == 1000
        assert _encode(1234, 3) == 'C34' and _decode('C34', 3) == 1234

    def test_two_digits(self):
        assert _encode(99, 2) == '99' and _encode(100, 2) == 'A0' and _decode('A5', 2) == 105

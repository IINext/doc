"""amount_to_chinese 的測試。

預期值是依照 Magic 原程式 #14 的邏輯推算的結果；
正式上線前，請在 Magic 上用同樣的數字執行一次，把實際結果填入 MAGIC_VERIFIED。
"""
import unittest

from amount_to_chinese import amount_to_chinese

CASES = {
    0: '零元整',
    1: '壹元整',
    10: '壹拾元整',
    100: '壹佰元整',
    101: '壹佰零壹元整',
    110: '壹佰壹拾元整',
    1001: '壹仟零壹元整',
    1010: '壹仟零壹拾元整',
    9999: '玖仟玖佰玖拾玖元整',
    10000: '壹萬元整',
    12345: '壹萬貳仟參佰肆拾伍元整',
    100000: '壹拾萬元整',
    1000000: '壹佰萬元整',
    7104000: '柒佰壹拾萬肆仟元整',   # 原程式中被停用的測試值
    10000000: '壹仟萬元整',
    10010000: '壹仟零壹萬元整',
    12345678: '壹仟貳佰參拾肆萬伍仟陸佰柒拾捌元整',
    99999999: '玖仟玖佰玖拾玖萬玖仟玖佰玖拾玖元整',
    # 以下是原程式的特殊行為，刻意保留
    10000500: '壹仟萬伍佰元整',       # 沒有補「零」
    -500: '元整',                     # 負數
}

# 在 Magic 上實際執行確認過的案例，格式同 CASES
MAGIC_VERIFIED = {}


class AmountToChineseTest(unittest.TestCase):
    def test_cases(self):
        for n, expected in {**CASES, **MAGIC_VERIFIED}.items():
            with self.subTest(n=n):
                self.assertEqual(amount_to_chinese(n), expected)

    def test_decimal_truncated(self):
        self.assertEqual(amount_to_chinese(123.9), amount_to_chinese(123))


if __name__ == '__main__':
    unittest.main()

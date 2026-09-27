"""數值金額轉換中文(含元整)

由 Magic xpa 程式 #14「數值金額轉換中文(含元整)」轉換而來（Batch 任務，1 個參數，回傳 BN）。
刻意保留 Magic 原本的行為，包括它的限制（見 amount_to_chinese 的說明），
這樣新舊系統的輸出才能逐筆比對。

Magic 變數對照：
    BM  P_數值        參數，N10（整數）
    BN  V_回傳字串    回傳值
    BO  V_中文大寫    '零,壹,貳,參,肆,伍,陸,柒,捌,玖'
    BQ  V_Part I      Fix(BM/10000,4,0)   萬以上
    BR  V_Part II     BM MOD 10000        萬以下
    BS..BZ            Str(BM,'8') 的第 1~8 位數字
    CA  V_中文敘述 I
    CB  V_中文敘述 II
"""

DIGITS = '零壹貳參肆伍陸柒捌玖'

# Record Suffix 中依序執行的 RepStr，順序不可調換
_PART1_RULES = [
    ('零仟零佰零拾', ''),
    ('零佰零拾零萬', ''),
    ('零仟零佰', ''),
    ('零佰零拾', '零'),
    ('零拾零萬', ''),
    ('零仟', ''),
    ('零佰', '零'),
    ('零拾', '零'),
    ('零萬', ''),
]
_PART2_RULES = [
    ('零仟零佰零拾', ''),
    ('零佰零拾零元', ''),
    ('零仟零佰', ''),
    ('零佰零拾', '零'),
    ('零拾零元', ''),
    ('零仟', ''),
    ('零佰', '零'),
    ('零拾', '零'),
    ('零元', ''),
]


def _magic_fix(x, whole, dec=0):
    """Magic Fix(x, whole, dec)：截斷（不四捨五入），只保留右邊 whole 位整數。"""
    sign = -1 if x < 0 else 1
    ip = int(abs(x)) % (10 ** whole)
    return sign * ip


def _magic_mod(a, b):
    """Magic MOD：結果正負號跟被除數相同（與 Python 的 % 不同）。"""
    r = abs(a) % abs(b)
    return -r if a < 0 else r


def _digits8(n):
    """Val(MID(Str(BM,'8'),i,1),'1')，i = 1..8。

    Str(n,'8') 為 8 位靠右、左補空白，空白經 Val 後為 0，所以等同左補 0。
    Picture '8' 沒有 N，負號不顯示。超過 8 位時 Magic 會輸出 '*'，Val 後同樣為 0。
    """
    s = str(abs(int(n)))
    if len(s) > 8:
        return [0] * 8
    return [int(c) for c in s.rjust(8, '0')]


def _apply(text, rules):
    for old, new in rules:
        text = text.replace(old, new)
    return text


def amount_to_chinese(amount):
    """把整數金額轉成中文大寫，例如 12345 -> '壹萬貳仟參佰肆拾伍元整'。

    與 Magic 原程式相同的行為（轉換時刻意保留）：
    - 參數是 N10 整數欄位，小數會被捨去。
    - 有效範圍是 0 ~ 99,999,999；超過時結果不正確。
    - 負數回傳 '元整'。
    - 萬位和千位之間的「零」不會補上，例如 10000500 -> '壹仟萬伍佰元整'
      （一般寫法是 '壹仟萬零伍佰元整'）。
    """
    bm = int(amount)                      # N10，無小數
    if bm == 0:
        return '零元整'

    bq = _magic_fix(bm / 10000, 4, 0)
    br = _magic_mod(bm, 10000)
    d = _digits8(bm)

    ca = ''
    if bq > 0:
        ca = (DIGITS[d[0]] + '仟' + DIGITS[d[1]] + '佰' +
              DIGITS[d[2]] + '拾' + DIGITS[d[3]] + '萬')
    cb = ''
    if br > 0:
        cb = (DIGITS[d[4]] + '仟' + DIGITS[d[5]] + '佰' +
              DIGITS[d[6]] + '拾' + DIGITS[d[7]] + '元')

    if bq > 0:
        if ca == '零仟零佰零拾零萬':
            ca = ''
        ca = _apply(ca, _PART1_RULES)
        if '萬' not in ca:
            ca = ca.strip() + '萬'

    cb = _apply(cb, _PART2_RULES)
    if '元' not in cb:
        cb = cb.rstrip() + '元'

    return ca.strip() + cb.strip() + '整'


if __name__ == '__main__':
    import sys
    for arg in sys.argv[1:] or ['12345']:
        print(arg, amount_to_chinese(int(arg)))

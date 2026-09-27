"""單據編號。對應 Home #1432「表單.編製單號尾碼YYYMMDD###」。

單號 = [公司代碼為 A 時加 'A'] + 民國年月日 7 碼 + 當日序號。
序號一般 3 碼（001–999，超過後用英文字母：1000 → A00）；公司 A 是 2 碼（01–99，超過後 100 → A0）。
當日目前序號記在 FIL0050（單據編號檔），同時參考 FIL0030 裡當日最大的單號，取較大者再加 1。
"""
from . import db
from .magic import from_date, roc_date7


def _decode(tail, width):
    """'007' -> 7；'A05' -> 1005（width 3）；'A5' -> 105（width 2）。"""
    if not tail:
        return 0
    if tail[0] < 'A':
        return int(tail) if tail.isdigit() else 0
    return (ord(tail[0]) - 55) * (10 if width == 2 else 100) + int(tail[1:] or 0)


def _encode(n, width):
    limit = 10 ** width - 1
    if n <= limit:
        return f'{n:0{width}d}'
    unit = 10 if width == 2 else 100
    return chr(n // unit % 100 + 55) + f'{n % unit:0{width - 1}d}'


def next_doc_no(doc_type, doc_date, company):
    """取得下一個單號並更新 FIL0050。要在寫入單據的同一個交易裡呼叫。"""
    width = 2 if company == 'A' else 3
    counter_key = doc_type.strip() + ('A' if company == 'A' else '')
    prefix = ('A' if company == 'A' else '') + roc_date7(doc_date)
    day = from_date(doc_date)

    # 鎖住當日的計數列，避免兩個人同時取到同一號
    db.execute('INSERT INTO fil0050 ("單據類別", "日期", "序號") VALUES (%s, %s, 0) ON CONFLICT DO NOTHING',
               (counter_key, day))
    counter = db.scalar('SELECT "序號" FROM fil0050 WHERE "單據類別" = %s AND "日期" = %s FOR UPDATE',
                        (counter_key, day))
    last = db.scalar("""SELECT "單據編號" FROM fil0030
                        WHERE "單據類別" = %s AND "單據編號" LIKE %s
                        ORDER BY "單據編號" DESC LIMIT 1""", (doc_type, prefix + '%'))
    # 原程式：尾碼是英文字母時沒有和 FIL0050 的計數比較大小；這裡一律取較大者，避免重號
    current = max(_decode((last or '').strip()[-width:] if last else '', width), counter or 0)
    n = current + 1
    db.execute('UPDATE fil0050 SET "序號" = %s WHERE "單據類別" = %s AND "日期" = %s', (n, counter_key, day))
    return prefix + _encode(n, width)

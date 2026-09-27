# Magic xpa → Python 轉換

來源：`Project.xml`（Magic xpa 3.3，匯出日期 2025/03）。原始 XML 沒有放進這個 repo。

## 檔案

| 檔案 | 說明 |
|---|---|
| `magic_dump.py` | 解析 Magic 專案 XML，輸出可讀的程式清單（變數、Logic Unit、Operation、Expression 都會展開） |
| `amount_to_chinese.py` | 範例：程式 #14「數值金額轉換中文(含元整)」轉成 Python |
| `test_amount_to_chinese.py` | 範例的測試（`python -m unittest test_amount_to_chinese`） |

```
python magic_dump.py Project.xml        # 列出 68 支程式
python magic_dump.py Project.xml 14     # 展開第 14 支程式
```

## 專案盤點

這個專案是**共用函式庫**，不是完整的業務系統：

- 68 支程式，其中 12 支是分隔用的空程式（`==GUID`、`==eMail`…），實際要轉的約 56 支。
- Main Program 定義了 23 個全域函數（`GFunc_GUID`、`GFunc_CDOW`、`GFunc_PrintCDateYYY`…）。
- 自己定義的資料表只有 7 個（多為 Memory 暫存表）。
- **業務資料表定義在 `Files.ecf` 元件裡**（528 個 DataObject），這個檔案只有它們的名稱和編號，沒有欄位定義。

### 依轉換方式分類

| 類別 | 程式 | 轉成 Python 的方式 | 難度 |
|---|---|---|---|
| 純邏輯 | 8, 13, 14, 15, 43, 52, 65, 68；Main Program 的 GFunc_* | 直接改寫成函數 | 低 |
| 有現成套件可取代的 .NET 功能 | 42, 47, 48（簡繁轉換 → `opencc`）、44, 45, 46（條碼/QR → `python-barcode`、`qrcode`、`pyzbar`）、57（農曆 → `lunardate`）、41（語音） | 改用 Python 套件 | 低 |
| GUID | 5, 6, 7, 8 | `uuid.uuid4()` 一行取代 | 低 |
| 讀寫資料表 | 10, 11, 17, 20, 26, 27, 53, 54, 55, 56, 58, 66 | SQLAlchemy 或 SQL；需要先有 `Files.ecf` 的表格定義 | 中 |
| Email | 22, 23, 29 | `smtplib` / `email` | 中 |
| Excel（DDE） | 35, 36 | `openpyxl`（DDE 在 Python 沒有對應，改讀檔案） | 中 |
| 依賴 Magic 執行期的功能 | 18（欄位異動記錄，用到 `VarCurr`/`VarPrev`/`VarMod`）、12, 61–64（`DataViewToHTML` 等資料匯出/列印） | 要重新設計：異動記錄改用 ORM 事件，匯出改用通用的 CSV/Excel/HTML 輸出 | 高 |
| 畫面 / Client 端 | 3, 28, 30, 31, 32, 38, 39, 40, 49, 50, 59, 67 | 網頁或桌面介面重做 | 高 |
| 已停止的服務 | 33 Line Notify | LINE Notify 已於 2025/3/31 停止服務，需改用 LINE Messaging API 或其他通知管道 | — |

## 範例轉換說明（#14）

`amount_to_chinese.py` 刻意**保留原程式的行為**，方便新舊系統逐筆比對。
轉換過程中發現原程式有這些限制：

1. 萬位和千位中間的「零」不會補上：`10000500` → `壹仟萬伍佰元整`（一般寫法是 `壹仟萬零伍佰元整`）。
2. 有效範圍只有 0 ~ 99,999,999（參數是 N10，但只取 8 位數字）。
3. 負數回傳 `元整`。

要不要修正這些行為，等確認新系統上線方式後再決定。

**需要在 Magic 上確認的一點**：小數參數（例如 123.9）傳進 N10 參數時，Magic 是截斷還是四捨五入。
目前的 Python 版本是截斷。

## 下一步需要的資料

1. `Files` 元件的原始專案匯出（`Files.eci` 對應的專案 XML），才能取得資料表欄位定義。
2. 實際使用這個函式庫的業務專案 XML。
3. 幾組在 Magic 上實際跑出來的結果，填進 `test_amount_to_chinese.py` 的 `MAGIC_VERIFIED`。

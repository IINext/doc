# Magic xpa → Python 轉換

來源：`Project.xml`（共用函式庫專案）與 `Files.xml`（資料表元件），Magic xpa 3.3。原始 XML 沒有放進這個 repo。

## 檔案

| 檔案 | 說明 |
|---|---|
| `magic_dump.py` | 解析 Magic 專案 XML，輸出可讀的程式清單（變數、Logic Unit、Operation、Expression 都會展開） |
| `amount_to_chinese.py` | 範例：程式 #14「數值金額轉換中文(含元整)」轉成 Python |
| `test_amount_to_chinese.py` | 範例的測試 |
| `magic_schema.py` | 從 `Files.xml` 產生 PostgreSQL 建表 SQL 和欄位字典 |
| `test_magic_schema.py` | 型態對應規則的測試 |
| `schema/postgresql.sql` | 產生的建表 SQL（195 個資料表、397 個索引） |
| `schema/tables.csv`、`schema/columns.csv` | 資料表清單與欄位字典，可直接用 Excel 開 |

測試：`python -m unittest`

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

## 資料表結構（Files.xml）

```
python magic_schema.py Files.xml schema/                  # 保留原本的儲存方式（預設）
python magic_schema.py Files.xml schema/ --native-types   # 日期/時間/邏輯改用 date/time/boolean
```

`Files.xml` 共 864 個 DataObject，資料庫是 **Oracle**：

| 種類 | 數量 | 處理方式 |
|---|---|---|
| 資料表（Default 資料庫） | 195 | 產生 CREATE TABLE |
| View（Default 資料庫） | 606 | 只列在 `tables.csv`；View 的 SQL 在 Oracle 裡，Magic 沒有存 |
| Materialized View（`MV_` 開頭） | 3 | 同上 |
| 其他資料來源（SQLite、Mobile、Memory、Log、AI…） | 23 | 只列在 `tables.csv` |
| 分隔用的空項目 | 37 | 略過 |

`postgresql.sql` 已在 PostgreSQL 16 上實際執行過，兩種模式都沒有錯誤。

### 型態對應

| Magic | 預設 | `--native-types` |
|---|---|---|
| Alpha / Unicode | `varchar(n)`（Unicode 的長度是 Size ÷ 2） | 同左 |
| Numeric 整數 | `smallint` / `integer` | 同左 |
| Numeric 小數 | `numeric(p,s)`，依 Oracle SqlType 或 Picture | 同左 |
| Date（字串 YYYYMMDD） | `char(8)` | `date` |
| Time（字串 HHMMSS） | `char(6)` | `time` |
| Date＋Time 對應同一個 Oracle DATE 欄位 | `timestamp(0)` | 同左 |
| Logical | `smallint`（0/1） | `boolean` |
| BLOB | Unicode → `text`、Binary → `bytea` | 同左 |

### 轉換時發現的情況

- **日期＋時間共用一個欄位**：像「最後更新日／最後更新時」，Magic 用兩個欄位對應 Oracle 的同一個 `DATE` 欄位。
  PostgreSQL 合併成一個 `timestamp(0)`，欄位註解會寫出兩個 Magic 欄位名稱。Python 程式要分開取日期和時間。
- **運算欄位 18 個**：Magic 欄位的 DB 名稱其實是 SQL 運算式（例如 `異動日期||異動時間`、子查詢、`DBMS_LOB.GETLENGTH(圖檔)`），
  不建立實體欄位，轉換程式時要改寫成查詢或 Python 計算。`columns.csv` 備註欄有標示。
  其中 `DECODE`、`NVL`、`TO_CHAR` 是 Oracle 語法，要改成 PostgreSQL 的 `CASE`、`COALESCE`、`to_char`。
- **38 個欄位的型態是推測的**：Magic 沒有寫 Oracle 的實際型態（沒有 SqlType），`columns.csv` 備註欄標示「推測」。
  請在 Oracle 執行下面的查詢確認：

  ```sql
  SELECT table_name, column_name, data_type, data_length, data_precision, data_scale, nullable
  FROM user_tab_columns
  ORDER BY table_name, column_id;
  ```

- **95 個資料表沒有主鍵**：Magic 不一定需要主鍵，但 Python 的 ORM（例如 SQLAlchemy）需要。
  轉換到這些表時要決定用哪個唯一索引當主鍵，或補一個流水號欄位。
- **4 個欄位 Magic 沒有定義長度**（`人事異動` 表），產生為不限長度的 `varchar`。
- ASCII 的表名和欄位名稱轉成小寫（Oracle 的 `FIL0010` → `fil0010`），中文欄位名稱保持原樣。

### 搬資料要注意

- 預設模式下欄位型態和 Oracle 幾乎一致，可以直接搬。
- 使用 `--native-types` 時，字串日期 `'00000000'`、空白要轉成 `NULL`，其他轉成 `date`；時間同理。
- Magic 的 Alpha 欄位在 Oracle 可能帶尾端空白，搬到 `varchar` 時建議 `rtrim`，並確認程式比對時不依賴空白。

## 下一步需要的資料

1. 實際使用這些資料表的業務專案 XML（例如訂單、生產、HR 各模組）。
2. Oracle 的 View 定義（`SELECT view_name, text FROM user_views`），606 個 View 要轉成 PostgreSQL 語法。
3. 上面那段 `user_tab_columns` 查詢結果，用來確認推測的欄位型態。
4. 幾組在 Magic 上實際跑出來的結果，填進 `test_amount_to_chinese.py` 的 `MAGIC_VERIFIED`。

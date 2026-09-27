# Magic xpa → Python 轉換

## 來源專案

Magic xpa 3.3，共 8 個專案，都連到同一個 **Oracle** 資料庫（原始 XML 沒有放進這個 repo）：

| 專案檔 | 專案名稱 | 內容 | 說明文件 |
|---|---|---|---|
| `Home.xml` | Home | **主系統（ERP）**，2,559 支程式，其中實際業務程式約 1,634 支 | [`HOME.md`](HOME.md) |
| `Project.xml` | Utility | 共用函式庫（`Utility.ecf`），68 支程式 | 本文件「Utility 盤點」 |
| `Files.xml` | Files | 資料表元件（`Files.ecf`；在 PLC 專案裡叫「PLC」元件），864 個資料表／View | 本文件「資料表結構」 |
| `EDB.xml` | edb | 電子表單簽核引擎（`edb.ecf`），141 支程式 | [`EDB.md`](EDB.md) |
| `Doc.xml` | DOC | 文件管理系統，63 支程式 | 待整理（與 repo 的 Flask 系統功能相近） |
| `PLC.xml` | PLC | 製袋機台資料、倉庫儲位、感測器監控，53 支程式 | 待整理 |
| `Chart.xml` | Chart | 圖表元件（.NET LiveCharts、MS Chart），11 支程式 | 網頁版改用 Chart.js／ECharts，不需逐支轉換 |
| `UserFunctionality.xml` | UserFunctionality | Magic 內建的 Range／Locate／排序／列印畫面，44 支程式 | 網頁版以篩選、排序、匯出功能取代，不需逐支轉換 |

元件關係：Home 使用 Utility、Files、EDB、DOC、PLC、UserFunctionality；PLC 使用 Utility、Files、EDB、Chart。

⚠️ 原始程式有寫死的萬用密碼等安全問題，轉換時不可保留，位置整理在 [`HOME.md`](HOME.md#安全問題)。

## 檔案

| 檔案 | 說明 |
|---|---|
| `magic_dump.py` | 解析 Magic 專案 XML，輸出可讀的程式清單（資料表、欄位、Logic Unit、Operation、Expression、SQL 都會展開） |
| `export_oracle_dictionary.sql` | 在能連到 Oracle 的電腦上用 SQL*Plus 執行，匯出資料字典（欄位、View、索引、筆數） |
| `oracle_schema.py` | **以 Oracle 資料字典為準**產生 PostgreSQL 建表 SQL，並和 Magic 定義比對 |
| `magic_views.py` | 把 Oracle View 轉成 PostgreSQL，並實際建立、查詢驗證 |
| `oracle_compat.sql` | Oracle 相容函數（`TO_NUMBER`、`SUBSTR`、`DBMS_LOB`、日期加減天數…），建立 View 前先執行 |
| `magic_schema.py` | 從 Magic 專案 XML 整理資料表與欄位字典（Magic 名稱、Picture 等），供 `oracle_schema.py` 補說明 |
| `amount_to_chinese.py` | 範例：Utility #14「數值金額轉換中文(含元整)」轉成 Python |
| `HOME.md`、`EDB.md` | 各專案的盤點與分析 |
| `schema/postgresql.sql` | 建表 SQL（282 個資料表，以 Oracle 為準） |
| `schema/postgresql_views.sql` | 轉換後的 View（659 個，依相依順序） |
| `schema/oracle_views.sql` | Oracle 原始 View 定義（683 個） |
| `schema/oracle_tables.csv` | Oracle 資料表分類與筆數 |
| `schema/oracle_vs_magic.csv` | Oracle 和 Magic 定義不同的地方 |
| `schema/views.csv` | 每個 View 的轉換結果與錯誤 |
| `schema/tables.csv`、`columns.csv`、`conflicts.csv`、`magic_postgresql.sql` | 依 Magic 定義整理的資料（參考用） |

CSV 檔都可以直接用 Excel 開。

測試：`python -m unittest`（需要 `pip install sqlglot`；驗證 View 另外需要 `psycopg2`）

## 讀程式：magic_dump.py

```
python magic_dump.py Project.xml                     # 程式清單
python magic_dump.py Project.xml 14                  # 展開第 14 支程式
python magic_dump.py Home.xml --out dump/home --with Files.xml --with EDB.xml --with Project.xml \
    --with Doc.xml --with PLC.xml --with UserFunctionality.xml --with Chart.xml
                                                     # 整個專案每支程式一個檔案，另附 index.txt
```

`--with` 載入元件的專案檔，才能顯示元件裡資料表的欄位名稱、元件程式與事件的名稱。

輸出的讀法：

- `BM: Real 單據流水號   Locate: E` — 變數代號、種類、欄位名稱，後面是 Init／Range／Locate 條件。
- `Link Query 單據屬性 (A01)` — Magic 表名和 Oracle 實體名稱；Link 種類有 Query、Write、Create、Inner Join、Left Outer Join。
- `=== 刪除流程  [Batch, Mode=Delete]` — 任務的初始模式。**Delete 模式的 Batch 任務會刪除所有符合 Range 的記錄**，
  就算沒有任何邏輯行也一樣。
- `Call [子任務] …`／`Call [程式 #55] …`／`Call [元件] Utility #11 …` — 呼叫子任務、同專案程式、元件程式。
  括號內是參數，`-` 表示略過。
- `Handler (User:Utility:GUE_PushButton)` — 使用者事件，前面有元件名稱的是元件定義的事件。
- `Invoke UDF`、`Call By Name`、`Invoke .NET`、`Invoke OS Command` — 外部 DLL、依名稱呼叫、內嵌 .NET、作業系統指令。

解析規則（寫在程式註解裡，這裡列出重點）：Virtual／Parameter 依任務欄位清單的**位置**對應名稱，
Real 依資料表欄位的 **id** 對應；元件的資料表、程式、事件都依元件清單中的**位置**對應，
元件事件的 `comp` 是「有事件的元件」中的第幾個。

## 資料表結構

### 1. 匯出 Oracle 資料字典

在能連到 Oracle 的電腦上執行（只讀取資料字典，不會修改資料）：

```
set NLS_LANG=AMERICAN_AMERICA.AL32UTF8
sqlplus apk@app @export_oracle_dictionary.sql
```

會產生 `oracle_columns.csv`、`oracle_views.csv`、`oracle_indexes.csv`、`oracle_tables.csv`。

### 2. 產生建表 SQL

```
python magic_schema.py schema/ Files.xml EDB.xml Doc.xml Home.xml PLC.xml UserFunctionality.xml Chart.xml \
    --db Default --db Master              # 先整理 Magic 的中文名稱與預設值
python oracle_schema.py schema/ oracle_columns.csv oracle_indexes.csv oracle_tables.csv
```

欄位型態、NOT NULL、索引、主鍵都**以 Oracle 為準**；欄位的中文說明（Magic 欄位名稱）和預設值取自 Magic 定義。

Oracle（APK schema）的現況：

| 分類 | 資料表 | 筆數 | 處理 |
|---|---|---|---|
| 業務資料表 | 282 | 約 1,434 萬 | 產生 DDL |
| Magic 暫存表 `TEMP_數字` | 3,931 | 約 1.5 萬 | 不產生；Magic 執行時建立後沒有清掉，現行 Oracle 也可以清理 |

最大的表：FIL300B（168 萬筆）、FIL0040（130 萬）、FIL0041（119 萬）、FIL004A（95 萬）、FIL1018（87 萬）。

型態對應：

| Oracle | PostgreSQL |
|---|---|
| `VARCHAR2`、`NVARCHAR2` | `varchar(n)`（字數） |
| `CHAR`、`NCHAR` | `char(n)`；Magic 的字串日期 `YYYYMMDD` 是 `char(8)` |
| `NUMBER(p,0)` | `smallint`（p ≤ 4）、`integer`（p ≤ 9）、`bigint`（p ≤ 18） |
| `NUMBER(p,s)`、`NUMBER` | `numeric(p,s)`、`numeric` |
| `DATE` | `timestamp(0)`（Oracle 的 DATE 含時間） |
| `NCLOB`、`CLOB` | `text` |
| `BLOB`、`RAW` | `bytea` |

**日期保持 `char(8)` 字串**：Oracle 的 View 大量把日期當字串處理（例如 `SUBSTR(日期, 1, 6)` 取年月），
改成 `date` 型態的話很多 View 要改寫。

### Oracle 和 Magic 定義的差異（`oracle_vs_magic.csv`）

| 差異 | 數量 | 說明 |
|---|---|---|
| Oracle 沒有這個資料表 | 31 | 大多是 HR 相關表（學歷、經歷、人事異動、離職單…，`HRFIL00xx`／`HRFIL10xx`），可能在其他 schema 或資料庫，**請確認** |
| Oracle 沒有這個欄位 | 24 | Magic 定義了但 Oracle 沒有，例如 `FIL004KA` 的熟成相關欄位（Oracle 裡是冷鏈欄位） |
| Magic 沒有定義這個欄位 | 13 | 例如 `FIL0020.製程代碼`、`FIL004KA` 的冷鏈欄位、`FIL0012.登入密碼` |
| 型態類別不同 | 12 | 其中 8 個是之前推測的型態，7 個猜錯（實際是 Oracle `DATE`）；`A01.DueDate` 實際是 `CHAR(8)`、`A50.TaxRate` 是 `NUMBER(3,1)` |

另外還有這些情況：

- **日期＋時間共用一個欄位**：像「最後更新日／最後更新時」，Magic 用兩個欄位對應 Oracle 的同一個 `DATE` 欄位，
  PostgreSQL 是一個 `timestamp(0)`，程式要分開取日期和時間。
- **Magic 的運算欄位**：有些 Magic 欄位的 DB 名稱其實是 SQL 運算式（例如 `異動日期||異動時間`、子查詢），
  轉換程式時要改寫成查詢或 Python 計算，`columns.csv` 備註欄有標示。
- **有主鍵的資料表不多**：Python 的 ORM（例如 SQLAlchemy）需要主鍵，轉換到沒有主鍵的表時要決定用哪個唯一索引。
- **兩個遞減索引略過**：`MESSAGES.MESGKEY7`、`WKFIL2022.WKFIL2022KEY04` 的欄位是運算式，匯出資料看不到，要另外查 `user_ind_expressions`。
- 所有名稱的英文字母轉成小寫（Oracle 不分大小寫；`FIL0010` → `fil0010`），中文不變。

### 搬資料要注意

- 欄位型態和 Oracle 一致，可以直接搬；筆數約 1,434 萬，最大的表 168 萬筆。
- Magic 的字串欄位在 Oracle 可能帶尾端空白，搬到 `varchar` 時建議 `rtrim`，並確認程式比對時不依賴空白。

## View：magic_views.py

```
psql -f schema/postgresql.sql -f oracle_compat.sql      # 先建資料表和相容函數（請用測試資料庫）
python magic_views.py schema/ oracle_views.csv --columns oracle_columns.csv \
    --pg "host=... dbname=... user=..." --smoke
```

用 [sqlglot](https://github.com/tobymao/sqlglot) 把 Oracle 語法轉成 PostgreSQL，再到資料庫實際建立。
Oracle 的 `user_views` 只有查詢本身，View 的欄位名稱從 `oracle_columns.csv` 補上。
`--smoke` 會在每個資料表放一筆測試資料、實際查詢每個 View，抓出建立時看不出來的執行錯誤，最後 ROLLBACK。
（沒有 Oracle 匯出時，也可以改給 Magic 專案 XML，從 Home「View」資料夾的程式裡抽出定義。）

**結果：Oracle 的 683 個 View，659 個（96.5%）建立成功並通過實際查詢。**

除了 sqlglot 本身的轉換，工具另外處理了這些 Oracle 和 PostgreSQL 行為不同的地方，確保**結果一致**，而不只是能執行：

| Oracle | 問題 | 處理 |
|---|---|---|
| `'A' \|\| NULL` = `'A'` | PostgreSQL 的 `\|\|` 遇到 NULL 整個變 NULL；LEFT JOIN 後串接名稱很常見 | 改用 `CONCAT()` |
| `SUBSTR(s, 0, n)`、負數起點、負數長度 | PostgreSQL 的結果不同或直接報錯 | 改用 `ora_substr()`，完全照 Oracle 規則 |
| `TO_NUMBER(x)` | sqlglot 會轉成浮點數，金額會失去精度、空白字串會出錯 | 改用 `to_number()`，回傳 `numeric` |
| `TRUNC(日期, 'MM')` | 轉出的 `DATE_TRUNC('MM', …)` 執行時才出錯 | 換成 `month` 等單位 |
| 日期 ± 數字（天數） | PostgreSQL 不支援 | `oracle_compat.sql` 定義運算子 |
| 同一層 FROM 兩個表用相同別名 | PostgreSQL 不允許 | 依實際欄位判斷歸屬後改名 |
| `FORCE EDITIONABLE`、`"APK".` 前綴、全形括號、`GROUP BY` 常數 | PostgreSQL 不支援 | 移除或修正，`views.csv` 的「自動修正」欄有記錄 |

**未完成的 24 個**：

- 4 個在 **Oracle 裡本身就已失效**（欄位型態是 `UNDEFINED`）：VIEWFIL4049A、VIEWFIL41012、VIEWFIL41013、VIEWFIL4105，不需要轉。
- 4 個是依賴下面這些 View 而連帶失敗，修好後就會成功。
- **16 個需要人工改寫**，`views.csv` 有每一個的錯誤訊息：

| 原因 | View |
|---|---|
| Oracle 舊式外部連結 `(+)` | VIEWOFOBJFLOW、VIEWOFOBJFLOWSIGNED（EDB 的簽核流程查詢，重要） |
| 階層查詢 `CONNECT BY`／`START WITH` | VIEWDOC_OBJPATH、VIEWFILR014（改寫成 `WITH RECURSIVE`） |
| 文字和數字混用（Oracle 會自動轉型） | VIEWFIL2061M、VIEWFIL4040、VIEWFIL404B1A、VIEWFIL404C1A、VIEWFIL404ED、VIEWFIL404FC、VIEWFIL404GC |
| 重複別名但無法自動判斷 | VIEWFIL404DC、VIEWFILE033 |
| 其他 | VIEWFIL1024B（`ROWID`）、VIEWFILM018H（`IGNORE NULLS`）、VIEWFIL4A4C（FULL JOIN 條件） |

## Utility 盤點

`Project.xml` 是**共用函式庫**：68 支程式（12 支是分隔用的空程式），Main Program 定義了 23 個全域函數（`GFunc_*`）。

| 類別 | 程式 | 轉成 Python 的方式 | 難度 |
|---|---|---|---|
| 純邏輯 | 8, 13, 14, 15, 43, 52, 65, 68；Main Program 的 GFunc_* | 直接改寫成函數 | 低 |
| 有現成套件可取代的 .NET 功能 | 42, 47, 48（簡繁轉換 → `opencc`）、44, 45, 46（條碼/QR → `python-barcode`、`qrcode`、`pyzbar`）、57（農曆 → `lunardate`）、41（語音） | 改用 Python 套件 | 低 |
| GUID | 5, 6, 7, 8 | `uuid.uuid4()` 一行取代 | 低 |
| 讀寫資料表 | 10, 11, 17, 20, 26, 27, 53, 54, 55, 56, 58, 66 | SQLAlchemy 或 SQL | 中 |
| Email | 22, 23, 29 | `smtplib` / `email` | 中 |
| Excel（DDE） | 35, 36 | `openpyxl`（DDE 在 Python 沒有對應，改讀檔案） | 中 |
| 依賴 Magic 執行期的功能 | 18（欄位異動記錄，用到 `VarCurr`/`VarPrev`/`VarMod`）、12, 61–64（`DataViewToHTML` 等資料匯出/列印） | 要重新設計：異動記錄改用 ORM 事件，匯出改用通用的 CSV/Excel/HTML 輸出 | 高 |
| 畫面 / Client 端 | 3, 28, 30, 31, 32, 38, 39, 40, 49, 50, 59, 67 | 網頁介面重做 | 高 |
| 已停止的服務 | 33 Line Notify | LINE Notify 已於 2025/3/31 停止服務，需改用 LINE Messaging API 或其他通知管道 | — |

### 範例轉換（#14 數值金額轉換中文）

`amount_to_chinese.py` 刻意**保留原程式的行為**，方便新舊系統逐筆比對。原程式的限制：

1. 萬位和千位中間的「零」不會補上：`10000500` → `壹仟萬伍佰元整`（一般寫法是 `壹仟萬零伍佰元整`）。
2. 有效範圍只有 0 ~ 99,999,999。
3. 負數回傳 `元整`。

需要在 Magic 上確認：小數參數（例如 123.9）傳進 N10 參數時是截斷還是四捨五入（目前 Python 版是截斷）。

## 下一步

1. 確認那 31 個 HR 相關資料表在哪個 schema 或資料庫。
2. 處理需要人工改寫的 16 個 View。
3. 用 repo 的 Flask 系統，把 Home 的 H01 請假申請單從畫面、資料到送簽完整轉一次，建立共用寫法。
4. 在 Magic 上跑幾組 #14 的結果，填進 `test_amount_to_chinese.py` 的 `MAGIC_VERIFIED`。

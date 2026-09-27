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
| `magic_schema.py` | 從多個專案 XML 產生合併後的 PostgreSQL 建表 SQL 和欄位字典 |
| `magic_views.py` | 從專案 XML 抽出 Oracle View 定義，轉成 PostgreSQL 並實際建立驗證 |
| `oracle_compat.sql` | Oracle 相容函數（`TO_NUMBER`、`SUBSTR`、`DBMS_LOB`、日期加減天數…），建立 View 前先執行 |
| `amount_to_chinese.py` | 範例：Utility #14「數值金額轉換中文(含元整)」轉成 Python |
| `HOME.md`、`EDB.md` | 各專案的盤點與分析 |
| `schema/postgresql.sql` | 建表 SQL（276 個資料表） |
| `schema/postgresql_views.sql` | 轉換後的 View（631 個，依相依順序） |
| `schema/oracle_views.sql` | 原始 Oracle View 定義（663 個） |
| `schema/tables.csv`、`columns.csv`、`views.csv`、`conflicts.csv` | 資料表清單、欄位字典、View 轉換結果、定義衝突，可直接用 Excel 開 |

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

## 資料表結構：magic_schema.py

```
python magic_schema.py schema/ Files.xml EDB.xml Doc.xml Home.xml PLC.xml UserFunctionality.xml Chart.xml \
    --db Default --db Master                  # 保留原本的儲存方式（建議）
... --native-types                            # 日期/時間/邏輯改用 date/time/boolean
```

同一個 Oracle 在各專案裡的資料來源名稱不同（`Default`、`Master`），用 `--db` 全部列出。
同名資料表合併成一個：欄位取聯集，定義不一致時採用有寫明 Oracle 型態（SqlType）的那一邊，衝突記錄在 `conflicts.csv`：

| 資料表.欄位 | Files | EDB | 採用 |
|---|---|---|---|
| A01.DueDate（簽核期限） | `numeric(10,0)` | `char(8)` | `char(8)`（EDB 有 SqlType） |
| A01.AccMonth（帳月） | `numeric(10,0)` | `char(8)` | `char(8)`（EDB 有 SqlType） |
| A50.TaxRate（公司稅率） | `varchar(1)` | `numeric(3,1)` | `varchar(1)`，**請用 Oracle 確認** |

合併結果：276 個資料表（Files 195、EDB 58、Doc 14、Home 9），131 個有主鍵，另有 433 個索引。
已在 PostgreSQL 16 上實際建立，兩種模式都沒有錯誤。

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

**建議用預設模式**：Oracle 的 View 大量把日期當字串處理（例如 `SUBSTR(日期, 1, 6)` 取年月），
預設模式下 631 個 View 可以建立，`--native-types` 只剩 399 個。

### 轉換時發現的情況

- **日期＋時間共用一個欄位**：像「最後更新日／最後更新時」，Magic 用兩個欄位對應 Oracle 的同一個 `DATE` 欄位。
  PostgreSQL 合併成一個 `timestamp(0)`，欄位註解會寫出兩個 Magic 欄位名稱。
- **運算欄位 23 個**：Magic 欄位的 DB 名稱其實是 SQL 運算式（例如 `異動日期||異動時間`、子查詢），
  不建立實體欄位，轉換程式時要改寫成查詢或 Python 計算。`columns.csv` 備註欄有標示。
- **50 個欄位的型態是推測的**（Files 38、Home 10、EDB 2）：Magic 沒有寫 Oracle 的實際型態，`columns.csv` 備註欄標示「推測」。
- **Magic 沒定義、但 Oracle 裡有的欄位**：例如 `FIL0020.製程代碼`、`冷鏈狀態`，是從 View 的錯誤發現的。
- **145 個資料表沒有主鍵**：Python 的 ORM（例如 SQLAlchemy）需要主鍵，轉換到這些表時要決定用哪個唯一索引或補流水號。
- 所有名稱的英文字母轉成小寫（Oracle 不分大小寫；`FIL0010` → `fil0010`、`Y牢固完整度` → `y牢固完整度`），中文不變。

後兩項都需要 Oracle 的實際欄位清單來確認：

```sql
SELECT table_name, column_name, data_type, data_length, data_precision, data_scale, nullable
FROM user_tab_columns
ORDER BY table_name, column_id;
```

### 搬資料要注意

- 預設模式下欄位型態和 Oracle 幾乎一致，可以直接搬。
- Magic 的 Alpha 欄位在 Oracle 可能帶尾端空白，搬到 `varchar` 時建議 `rtrim`，並確認程式比對時不依賴空白。

## View：magic_views.py

Home 的「View」資料夾裡有用 SQL 建立 View 的程式，這支工具把所有 `CREATE VIEW` 抽出來（每個 View 取最後修改的版本），
用 [sqlglot](https://github.com/tobymao/sqlglot) 轉成 PostgreSQL，再到資料庫實際建立：

```
psql -f schema/postgresql.sql -f oracle_compat.sql      # 先建資料表和相容函數（請用測試資料庫）
python magic_views.py schema/ Home.xml Doc.xml EDB.xml Files.xml --pg "host=... dbname=... user=..." --smoke
```

`--smoke` 會在每個資料表放一筆測試資料、實際查詢每個 View，抓出建立時看不出來的執行錯誤，最後 ROLLBACK。

**結果：663 個 View，631 個（95%）建立成功並通過實際查詢。**

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

**需要人工處理的 21 個**（另有 11 個是依賴它們而連帶失敗），`views.csv` 有每一個的錯誤訊息：

| 原因 | View |
|---|---|
| Oracle 舊式外部連結 `(+)` | ViewOfObjFlow、ViewOfObjFlowSigned（EDB 的簽核流程查詢，重要） |
| 階層查詢 `CONNECT BY`／`START WITH` | ViewDoc_ObjPath、ViewFILR014（改寫成 `WITH RECURSIVE`） |
| Magic 沒定義的欄位 | ViewFIL0012、ViewFIL4090（製程代碼）、ViewFIL404C4AB、ViewFIL404C5A_V1（冷鏈狀態） |
| 文字和數字混用（Oracle 會自動轉型） | ViewFIL2061M、ViewFIL4040、ViewFIL404B1A、ViewFIL404C1A、ViewFIL404ED、ViewFIL404FC、ViewFIL404GC |
| 重複別名但無法自動判斷 | ViewFIL404DC、ViewFILE033 |
| 其他 | ViewFIL1024B（`ROWID`）、VIEWFILM018H（`IGNORE NULLS`）、ViewFIL4A4C（FULL JOIN 條件）、ViewLog001（執行時組出的動態 SQL） |

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

1. 用 Oracle 的 `user_tab_columns` 查詢結果，確認推測的欄位型態和 Magic 沒定義的欄位。
2. 處理需要人工改寫的 21 個 View。
3. 挑一種單據（例如 Home 的 H01 請假申請單）從畫面、資料到送簽完整轉一次，建立共用寫法。
4. 在 Magic 上跑幾組 #14 的結果，填進 `test_amount_to_chinese.py` 的 `MAGIC_VERIFIED`。

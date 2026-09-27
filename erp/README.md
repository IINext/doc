# ERP（由 Magic xpa 的 Home 專案轉換）

Flask + PostgreSQL。和 repo 根目錄的文件管理系統**完全獨立**：各自的登入、設定、port（ERP 預設 8100）。

資料表沿用 Oracle 轉過來的結構（`magic2py/schema/`），欄位名稱和舊系統相同，**新舊系統可以共用同一份資料並行一段時間**。

## 目前完成

| 功能 | 對應舊程式 | 狀態 |
|---|---|---|
| 登入、登出、改密碼 | Home #3 登入.手動登入 | ✅ |
| H01 請假申請單：列表、新增、修改、刪除 | Home #1122、#1123、#1124 | ✅ |
| 請假檢查規則、拆分每日明細、截止時間計算 | #1123 UE_ErrCheck、UE_計算截止時間、分柝明細 | ✅ |
| 預排特休檢查、當日超過 8 小時檢查 | #1125、#1128 | ✅ |
| 送簽：建立簽核物件、依流程設定產生簽核人 | Main Program GUE_送簽、EDB #54、#7 | ✅ |
| **簽核人核准／退回** | EDB 簽核程式 | ❌ 下一步 |
| 照片管理、列印、資料導出、修改記錄 | #1461、單據列印、GUE_資料導出 | ❌ 尚未轉換 |

## 安裝

需要 Python 3.10 以上、PostgreSQL 14 以上。

1. 建立資料庫並載入結構（在 repo 根目錄執行）：

   ```
   psql -d erp -f magic2py/schema/postgresql.sql
   psql -d erp -f magic2py/oracle_compat.sql
   psql -d erp -f magic2py/schema/postgresql_views.sql
   ```

   再把 Oracle 的資料搬進來（搬資料工具之後提供）。

2. 設定：複製 `erp/erp.env.example.bat` 為 `erp/erp.env.bat`，填入資料庫連線和金鑰。
   `erp.env.bat` 已列在 `.gitignore`，不會被提交。

   | 環境變數 | 說明 |
   |---|---|
   | `ERP_DATABASE_URL` | PostgreSQL 連線字串 |
   | `ERP_SECRET_KEY` | session 金鑰，用 `python -c "import secrets; print(secrets.token_hex(32))"` 產生 |
   | `ERP_SIGNING_APP_NAME` | 舊系統的 `G_app.Name`，「簽核系統」欄位 = `H01.` + 這個值（預設 `Home`），**請確認舊系統的實際值** |
   | `ERP_PORT` | 預設 8100 |

3. 建立 ERP 自己的資料表、匯入密碼（只要做一次）：

   ```
   erp\erp.env.bat
   flask --app erp init-db
   flask --app erp import-passwords
   ```

   `import-passwords` 會把 `FIL0010."個人密碼"` 的明文轉成雜湊存到 `erp_auth`，員工可以用原本的密碼登入，
   **第一次登入必須改密碼**。舊系統停用後，建議清空 `FIL0010."個人密碼"`。
   個別設定密碼：`flask --app erp set-password E001`。

4. 啟動：執行 `erp\start_erp.bat`（waitress，正式使用），或開發時 `flask --app erp run --port 8100`。

## 和舊系統不同的地方

### 安全性（刻意修改）

- **沒有萬用密碼**：舊系統任何帳號輸入同一組固定密碼就能登入，新系統沒有這個機制。
- 密碼只存雜湊，不讀 `FIL0010` 的明文密碼；連續輸錯 5 次鎖定 15 分鐘。
- 所有表單都有 CSRF 防護；所有 SQL 都用參數化查詢。

### 行為（和原程式不同，都有註明在程式裡）

| 項目 | 原程式 | 新系統 |
|---|---|---|
| 預排特休檢查 | 用**上一次存檔**的明細檢查，第一次存檔時不會檢查 | 用這次要寫入的明細檢查 |
| 單號尾碼超過 999 | 英文字母編碼時沒有和計數比大小 | 一律取較大者，避免重號 |
| 流程節點「指定欄位」 | 依欄位取簽核人 | **尚未支援**，遇到時顯示錯誤，請洽系統管理員 |
| 代開單據通知（開單人 ≠ 申請人時通知申請人） | 寫入訊息 | 尚未轉換 |
| 寫入系統記錄 | 刪除表單時寫入 | 尚未轉換 |

### 照原程式保留、但可能需要修正的地方

- **夜班跨午夜的休息時間不會扣**：原程式只在「起始時間早於休息開始」時扣休息時間。
  例如 20:00–05:00 的班、休息 00:00–01:00，22:00 起請 4 小時，算出截止 02:00（實際應該 03:00）。
  見 `tests/test_rules.py` 的 `test_night_shift_keeps_original_behaviour`。
- **至少小時剛好 8 的假別**，錯誤訊息只顯示「○○至少要請」，沒有天數。
- `A01_3.activity` 只有 1 個字元，送簽活動記錄成 `'O'`（原程式傳 `'Open'`，Oracle 也會截斷）。

## 舊系統借用欄位存資料

轉換時要特別注意，這些欄位的名稱和內容不同：

| 資料表.欄位 | 實際內容 |
|---|---|
| `FIL0010.party` | 班別代碼 |
| `FIL0010.possition` | 性別 |
| `FIL0030."折讓"` | 請假單第一天的請假時數 |
| `A20.visible` | 免送簽核 |
| `A20."流程獨立否"` | 申請人免簽 |
| `A20."屬性中類名稱"` | 簽核後程式（核銷人員的職位） |
| `A20_1.bycomp` | 指定欄位 |
| `A01_2.version` | 父階序號 |

## 測試

```
pip install -r erp/requirements-dev.txt
python -m pytest erp/tests                                   # 只跑規則測試（不需要資料庫）
ERP_TEST_DATABASE_URL=postgresql://postgres@localhost/erp_test python -m pytest erp/tests
```

整合測試會**清空** `ERP_TEST_DATABASE_URL` 指定的資料庫，重建全部資料表與 View，請用專門的測試資料庫。
目前 42 個測試：請假時數計算、每日明細、登入安全性、請假單的各項檢查、送簽產生簽核流程。

## 程式結構

| 檔案 | 內容 |
|---|---|
| `__init__.py` | app 建立、管理指令（init-db、import-passwords、set-password） |
| `db.py` | 資料庫連線；`insert()` 會替沒給值的 NOT NULL 欄位補 Magic 的空白值（`' '`、`0`、`'00000000'`） |
| `magic.py` | Magic 資料格式轉換：`'YYYYMMDD'` 日期、`'HHMMSS'` 時間、民國年、流水編號 |
| `auth.py` | 登入、CSRF |
| `numbering.py` | 單號（民國年月日 + 當日序號） |
| `edb.py` | 簽核引擎：建立簽核物件、送簽產生流程 |
| `leave_rules.py` | 請假計算規則（不碰資料庫） |
| `leave.py` | 請假申請單畫面與存檔 |

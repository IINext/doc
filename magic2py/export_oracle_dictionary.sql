-- 匯出 Oracle 的資料字典（欄位、View 定義、索引、資料筆數），給 magic2py 核對用。
-- 只讀取資料字典，不會修改任何資料。
--
-- 在能連到 Oracle 的電腦上執行（需要 SQL*Plus 12.2 以上）：
--
--   Windows 命令提示字元：
--     set NLS_LANG=AMERICAN_AMERICA.AL32UTF8
--     sqlplus apk@app @export_oracle_dictionary.sql
--
--   密碼執行時再輸入，不要寫在指令或檔案裡。
--   執行後在目前資料夾產生 4 個 CSV：
--     oracle_columns.csv   所有資料表／View 的欄位與型態
--     oracle_views.csv     所有 View 的 SQL 定義
--     oracle_indexes.csv   索引與主鍵
--     oracle_tables.csv    資料表清單與筆數（最後一次統計的數字）

SET MARKUP CSV ON QUOTE ON
SET FEEDBACK OFF
SET TERMOUT OFF
SET TRIMSPOOL ON
SET LONG 2000000
SET LONGCHUNKSIZE 2000000

SPOOL oracle_columns.csv
SELECT c.table_name, c.column_id, c.column_name, c.data_type, c.data_length, c.char_length,
       c.data_precision, c.data_scale, c.nullable, o.object_type
FROM user_tab_columns c
JOIN user_objects o ON o.object_name = c.table_name AND o.object_type IN ('TABLE', 'VIEW', 'MATERIALIZED VIEW')
ORDER BY c.table_name, c.column_id;
SPOOL OFF

SPOOL oracle_views.csv
SELECT view_name, text FROM user_views ORDER BY view_name;
SPOOL OFF

SPOOL oracle_indexes.csv
SELECT i.table_name, i.index_name, i.uniqueness,
       (SELECT 'Y' FROM user_constraints k
         WHERE k.constraint_type = 'P' AND k.index_name = i.index_name AND ROWNUM = 1) AS is_primary,
       ic.column_position, ic.column_name, ic.descend
FROM user_indexes i
JOIN user_ind_columns ic ON ic.index_name = i.index_name
ORDER BY i.table_name, i.index_name, ic.column_position;
SPOOL OFF

SPOOL oracle_tables.csv
SELECT table_name, num_rows, last_analyzed FROM user_tables ORDER BY table_name;
SPOOL OFF

EXIT

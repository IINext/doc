-- Oracle 相容函數：讓 Oracle 寫法的 View 可以在 PostgreSQL 執行。
-- 在建立 View（postgresql_views.sql）之前執行一次。
-- 新寫的程式請直接用 PostgreSQL 的寫法，不要依賴這些函數。

-- ROUND(浮點數, 位數)：PostgreSQL 只有 numeric 版本
CREATE OR REPLACE FUNCTION round(double precision, integer) RETURNS numeric
    LANGUAGE sql IMMUTABLE AS $$ SELECT round($1::numeric, $2) $$;

-- TO_NUMBER(文字)：Oracle 可以不給格式
CREATE OR REPLACE FUNCTION to_number(text) RETURNS numeric
    LANGUAGE sql IMMUTABLE AS $$ SELECT nullif(trim($1), '')::numeric $$;

-- TO_NCHAR(值)
CREATE OR REPLACE FUNCTION to_nchar(anyelement) RETURNS text
    LANGUAGE sql IMMUTABLE AS $$ SELECT $1::text $$;
CREATE OR REPLACE FUNCTION to_nchar(text) RETURNS text
    LANGUAGE sql IMMUTABLE AS $$ SELECT $1 $$;

-- DBMS_LOB 套件
CREATE SCHEMA IF NOT EXISTS dbms_lob;
CREATE OR REPLACE FUNCTION dbms_lob.getlength(bytea) RETURNS integer
    LANGUAGE sql IMMUTABLE AS $$ SELECT octet_length($1) $$;
CREATE OR REPLACE FUNCTION dbms_lob.getlength(text) RETURNS integer
    LANGUAGE sql IMMUTABLE AS $$ SELECT length($1) $$;
CREATE OR REPLACE FUNCTION dbms_lob.substr(text, integer DEFAULT 32767, integer DEFAULT 1) RETURNS text
    LANGUAGE sql IMMUTABLE AS $$ SELECT substr($1, $3, $2) $$;
CREATE OR REPLACE FUNCTION dbms_lob.substr(bytea, integer DEFAULT 32767, integer DEFAULT 1) RETURNS bytea
    LANGUAGE sql IMMUTABLE AS $$ SELECT substr($1, $3, $2) $$;

-- UTL_RAW 套件
CREATE SCHEMA IF NOT EXISTS utl_raw;
CREATE OR REPLACE FUNCTION utl_raw.cast_to_varchar2(bytea) RETURNS text
    LANGUAGE sql IMMUTABLE AS $$ SELECT convert_from($1, 'UTF8') $$;
CREATE OR REPLACE FUNCTION utl_raw.cast_to_varchar2(text) RETURNS text
    LANGUAGE sql IMMUTABLE AS $$ SELECT $1 $$;
-- Oracle 常用 CAST_TO_RAW + LISTAGG + CAST_TO_NVARCHAR2 串接 NVARCHAR 文字；
-- PostgreSQL 的文字本來就是 UTF-8，不需要轉成二進位，直接回傳文字
CREATE OR REPLACE FUNCTION utl_raw.cast_to_raw(text) RETURNS text
    LANGUAGE sql IMMUTABLE AS $$ SELECT $1 $$;
CREATE OR REPLACE FUNCTION utl_raw.cast_to_nvarchar2(text) RETURNS text
    LANGUAGE sql IMMUTABLE AS $$ SELECT $1 $$;

-- 日期 ± 天數：Oracle 的 DATE 加減數字代表天數
DO $$
DECLARE t text; n text; r text;
BEGIN
    FOREACH t IN ARRAY ARRAY['timestamp', 'timestamptz', 'date'] LOOP
        r := CASE WHEN t = 'timestamptz' THEN 'timestamptz' ELSE 'timestamp' END;
        FOREACH n IN ARRAY ARRAY['double precision', 'numeric', 'integer'] LOOP
            IF t = 'date' AND n = 'integer' THEN
                CONTINUE;  -- date ± integer PostgreSQL 本來就支援
            END IF;
            EXECUTE format('CREATE OR REPLACE FUNCTION ora_add_days(%s, %s) RETURNS %s LANGUAGE sql IMMUTABLE '
                           'AS $f$ SELECT $1 + $2 * interval ''1 day'' $f$', t, n, r);
            EXECUTE format('CREATE OR REPLACE FUNCTION ora_sub_days(%s, %s) RETURNS %s LANGUAGE sql IMMUTABLE '
                           'AS $f$ SELECT $1 - $2 * interval ''1 day'' $f$', t, n, r);
            IF NOT EXISTS (SELECT 1 FROM pg_operator
                           WHERE oprname = '+' AND oprleft = t::regtype AND oprright = n::regtype) THEN
                EXECUTE format('CREATE OPERATOR + (LEFTARG = %s, RIGHTARG = %s, FUNCTION = ora_add_days)', t, n);
            END IF;
            IF NOT EXISTS (SELECT 1 FROM pg_operator
                           WHERE oprname = '-' AND oprleft = t::regtype AND oprright = n::regtype) THEN
                EXECUTE format('CREATE OPERATOR - (LEFTARG = %s, RIGHTARG = %s, FUNCTION = ora_sub_days)', t, n);
            END IF;
        END LOOP;
    END LOOP;
END $$;

-- TO_NUMBER(數字)：Oracle 對數字呼叫 TO_NUMBER 會直接回傳
CREATE OR REPLACE FUNCTION to_number(numeric) RETURNS numeric
    LANGUAGE sql IMMUTABLE AS $$ SELECT $1 $$;

-- TO_NCHAR(數字, 格式) = TO_CHAR
CREATE OR REPLACE FUNCTION to_nchar(numeric, text) RETURNS text
    LANGUAGE sql IMMUTABLE AS $$ SELECT to_char($1, $2) $$;

-- TO_CHAR(文字, 格式)：Oracle 對文字呼叫 TO_CHAR 會直接回傳
CREATE OR REPLACE FUNCTION to_char(text, text) RETURNS text
    LANGUAGE sql IMMUTABLE AS $$ SELECT $1 $$;

-- UTL_RAW.CAST_TO_NVARCHAR2
CREATE OR REPLACE FUNCTION utl_raw.cast_to_nvarchar2(bytea) RETURNS text
    LANGUAGE sql IMMUTABLE AS $$ SELECT convert_from($1, 'UTF8') $$;

-- ADD_MONTHS(日期, 月數)
CREATE OR REPLACE FUNCTION add_months(timestamptz, integer) RETURNS timestamptz
    LANGUAGE sql IMMUTABLE AS $$ SELECT $1 + $2 * interval '1 month' $$;
CREATE OR REPLACE FUNCTION add_months(timestamp, integer) RETURNS timestamp
    LANGUAGE sql IMMUTABLE AS $$ SELECT $1 + $2 * interval '1 month' $$;
CREATE OR REPLACE FUNCTION add_months(date, integer) RETURNS timestamp
    LANGUAGE sql IMMUTABLE AS $$ SELECT $1 + $2 * interval '1 month' $$;

-- TRUNC(數字, 位數)：PostgreSQL 只有 numeric 版本
CREATE OR REPLACE FUNCTION trunc(double precision, integer) RETURNS numeric
    LANGUAGE sql IMMUTABLE AS $$ SELECT trunc($1::numeric, $2) $$;

-- SUBSTR：照 Oracle 的規則，和 PostgreSQL 的 substring 有三點不同
--   起點 0 視為 1；起點為負數時從字尾往回數；長度小於 1 回傳 NULL（PostgreSQL 會報錯）
CREATE OR REPLACE FUNCTION ora_substr(s text, p numeric, l numeric DEFAULT NULL) RETURNS text
    LANGUAGE sql IMMUTABLE AS $$
    SELECT CASE
        WHEN s IS NULL OR p IS NULL THEN NULL
        WHEN l IS NOT NULL AND trunc(l) < 1 THEN NULL
        WHEN abs(trunc(p)) > length(s) THEN NULL
        ELSE substr(s,
                    (CASE WHEN trunc(p) = 0 THEN 1
                          WHEN p < 0 THEN length(s) + trunc(p)::int + 1
                          ELSE trunc(p)::int END),
                    coalesce(trunc(l)::int, length(s)))
    END
$$;

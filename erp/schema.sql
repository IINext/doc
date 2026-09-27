-- ERP 自己的資料表（業務資料表沿用 magic2py/schema/postgresql.sql）
-- 可重複執行

-- 登入密碼：只存雜湊。舊系統 FIL0010."個人密碼" 是明文，ERP 不讀取它登入。
CREATE TABLE IF NOT EXISTS erp_auth (
    "員工編號"     varchar(10) PRIMARY KEY,
    password_hash  text        NOT NULL,
    must_change    boolean     NOT NULL DEFAULT true,   -- 下次登入必須改密碼
    failed_count   integer     NOT NULL DEFAULT 0,
    locked_until   timestamptz,
    updated_at     timestamptz NOT NULL DEFAULT now()
);

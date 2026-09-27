-- 由 magic_schema.py 從 Files、EDB 產生，請勿手動修改
-- 型態衝突：A01.DueDate Files=numeric(10,0)、EDB=char(8)，採用 char(8)（EDB 有 SqlType）
-- 型態衝突：A01.AccMonth Files=numeric(10,0)、EDB=char(8)，採用 char(8)（EDB 有 SqlType）
-- 型態衝突：A50.TaxRate Files=varchar(1)、EDB=numeric(3,1)，採用 varchar(1)（都沒有 SqlType，請用 Oracle 確認）

-- Files：0.員工資料檔
CREATE TABLE "fil0010" (
    "serial_num" varchar(60) DEFAULT ' ' NOT NULL,
    "員工編號" varchar(10) DEFAULT ' ' NOT NULL,
    "員工姓名" varchar(20) DEFAULT ' ' NOT NULL,
    "英文姓名" varchar(40) DEFAULT ' ' NOT NULL,
    "出生日期" char(8) DEFAULT '00000000' NOT NULL,
    "就職日期" char(8) DEFAULT '00000000' NOT NULL,
    "離職日期" char(8) DEFAULT '00000000' NOT NULL,
    "聯絡電話" varchar(20) DEFAULT ' ' NOT NULL,
    "emailaddress" varchar(70) DEFAULT ' ' NOT NULL,
    "郵遞區號" varchar(8) DEFAULT ' ' NOT NULL,
    "通訊地址" varchar(70) DEFAULT ' ' NOT NULL,
    "個人密碼" varchar(20) DEFAULT ' ' NOT NULL,
    "公司代碼" varchar(1) DEFAULT ' ' NOT NULL,
    "部門編號" varchar(10) DEFAULT ' ' NOT NULL,
    "身份證號" varchar(40) DEFAULT ' ' NOT NULL,
    "停止使用" smallint DEFAULT 0 NOT NULL,
    "主管編號" varchar(10) DEFAULT ' ' NOT NULL,
    "職稱代碼" varchar(60) DEFAULT ' ' NOT NULL,
    "開放時間_起" char(6) DEFAULT '000000' NOT NULL,
    "開放時間_迄" char(6) DEFAULT '000000' NOT NULL,
    "密碼變更日" char(8) DEFAULT '00000000' NOT NULL,
    "empstatus" varchar(1) DEFAULT ' ' NOT NULL,
    "compserial" varchar(60) DEFAULT ' ' NOT NULL,
    "depserial" varchar(60) DEFAULT ' ' NOT NULL,
    "offphone" varchar(16) DEFAULT ' ' NOT NULL,
    "voice" varchar(10) DEFAULT ' ' NOT NULL,
    "homphone" varchar(16) DEFAULT ' ' NOT NULL,
    "pager1" varchar(50) DEFAULT ' ' NOT NULL,
    "pager2" varchar(50) DEFAULT ' ' NOT NULL,
    "dateoflr" char(8) DEFAULT '00000000' NOT NULL,
    "dateofnr" char(8) DEFAULT '00000000' NOT NULL,
    "empblog" varchar(100) DEFAULT ' ' NOT NULL,
    "bloodtype" varchar(4) DEFAULT ' ' NOT NULL,
    "birthplace" varchar(10) DEFAULT ' ' NOT NULL,
    "married" varchar(4) DEFAULT ' ' NOT NULL,
    "nation" varchar(20) DEFAULT ' ' NOT NULL,
    "military" varchar(4) DEFAULT ' ' NOT NULL,
    "party" varchar(10) DEFAULT ' ' NOT NULL,
    "jobetitle" varchar(20) DEFAULT ' ' NOT NULL,
    "entryid" varchar(30) NOT NULL,
    "salaryposi" varchar(60) DEFAULT ' ' NOT NULL,
    "flowposi" varchar(60) DEFAULT ' ' NOT NULL,
    "assignee" varchar(60) DEFAULT ' ' NOT NULL,
    "replaceby" varchar(60) NOT NULL,
    "imheader" varchar(256) DEFAULT ' ' NOT NULL,
    "imstatus" varchar(1) DEFAULT 'O' NOT NULL,
    "photo" varchar(10) DEFAULT ' ' NOT NULL,
    "language" varchar(1) DEFAULT 'T' NOT NULL,
    "possition" varchar(20) DEFAULT ' ' NOT NULL,
    "留職停薪年數" smallint DEFAULT 0 NOT NULL,
    "留職停薪月數" smallint DEFAULT 0 NOT NULL,
    "生產部門禁" smallint DEFAULT 0 NOT NULL,
    "notes" text,
    "guname" varchar(100) DEFAULT ' ' NOT NULL,
    "最後更新者" varchar(10) DEFAULT ' ' NOT NULL,
    "最後更新日" char(8) DEFAULT '00000000' NOT NULL,
    "最後更新時" char(6) DEFAULT '000000'
);
CREATE UNIQUE INDEX "fil0010_01" ON "fil0010" ("員工編號");
CREATE INDEX "fil0010_02" ON "fil0010" ("員工姓名");
CREATE UNIQUE INDEX "fil0010_03" ON "fil0010" ("部門編號", "員工編號");
CREATE UNIQUE INDEX "fil0010_04" ON "fil0010" ("主管編號", "員工編號");
CREATE INDEX "fil0010_05" ON "fil0010" ("entryid");
CREATE INDEX "fil0010_06" ON "fil0010" ("serial_num");
COMMENT ON TABLE "fil0010" IS '0.員工資料檔';
COMMENT ON COLUMN "fil0010"."serial_num" IS '流水編號';
COMMENT ON COLUMN "fil0010"."開放時間_起" IS '開放時間(起)';
COMMENT ON COLUMN "fil0010"."開放時間_迄" IS '開放時間(迄)';
COMMENT ON COLUMN "fil0010"."empstatus" IS '薪資類別';
COMMENT ON COLUMN "fil0010"."compserial" IS '公司流水號';
COMMENT ON COLUMN "fil0010"."depserial" IS '部門流水號';
COMMENT ON COLUMN "fil0010"."offphone" IS '辦公室電話';
COMMENT ON COLUMN "fil0010"."voice" IS '聲母';
COMMENT ON COLUMN "fil0010"."homphone" IS '家裡電話';
COMMENT ON COLUMN "fil0010"."pager1" IS '銀行帳號一';
COMMENT ON COLUMN "fil0010"."pager2" IS '銀行帳號二';
COMMENT ON COLUMN "fil0010"."dateoflr" IS '留職停薪日期起';
COMMENT ON COLUMN "fil0010"."dateofnr" IS '留職停薪日期迄';
COMMENT ON COLUMN "fil0010"."empblog" IS '部落格';
COMMENT ON COLUMN "fil0010"."bloodtype" IS '血型';
COMMENT ON COLUMN "fil0010"."birthplace" IS '出生地';
COMMENT ON COLUMN "fil0010"."married" IS '結婚';
COMMENT ON COLUMN "fil0010"."nation" IS '國藉';
COMMENT ON COLUMN "fil0010"."military" IS '兵役';
COMMENT ON COLUMN "fil0010"."party" IS '班別代碼';
COMMENT ON COLUMN "fil0010"."jobetitle" IS '職位英文名稱';
COMMENT ON COLUMN "fil0010"."entryid" IS '指定程式';
COMMENT ON COLUMN "fil0010"."salaryposi" IS '薪資職位';
COMMENT ON COLUMN "fil0010"."flowposi" IS '簽核職位';
COMMENT ON COLUMN "fil0010"."assignee" IS '指定代理人流水號';
COMMENT ON COLUMN "fil0010"."replaceby" IS '本國姓名';
COMMENT ON COLUMN "fil0010"."imstatus" IS '手機畫面';
COMMENT ON COLUMN "fil0010"."photo" IS '系統帳號';
COMMENT ON COLUMN "fil0010"."language" IS '語系';
COMMENT ON COLUMN "fil0010"."possition" IS '性別';
COMMENT ON COLUMN "fil0010"."notes" IS '備註';

-- Files：0.簽核類別設定
CREATE TABLE "fil0010a" (
    "流水編號" varchar(60) DEFAULT ' ' NOT NULL,
    "請假" varchar(1) NOT NULL,
    "加班" varchar(1) NOT NULL
);
CREATE UNIQUE INDEX "fil0010a_01" ON "fil0010a" ("流水編號");
COMMENT ON TABLE "fil0010a" IS '0.簽核類別設定';
COMMENT ON COLUMN "fil0010a"."請假" IS '請假簽核類別';
COMMENT ON COLUMN "fil0010a"."加班" IS '加班簽核類別';

-- Files：0.廠客資料檔
CREATE TABLE "fil0011" (
    "廠客" smallint DEFAULT 0 NOT NULL,
    "編號" varchar(10) DEFAULT ' ' NOT NULL,
    "全名" varchar(100) DEFAULT ' ' NOT NULL,
    "簡稱" varchar(40) DEFAULT ' ' NOT NULL,
    "關係人代號" varchar(10) DEFAULT ' ' NOT NULL,
    "負責人" varchar(40) DEFAULT ' ' NOT NULL,
    "聯絡人一" varchar(40) DEFAULT ' ' NOT NULL,
    "電話一" varchar(40) DEFAULT ' ' NOT NULL,
    "分機一" varchar(10) DEFAULT ' ' NOT NULL,
    "最常職務" varchar(40) DEFAULT ' ' NOT NULL,
    "最常手機" varchar(40) DEFAULT ' ' NOT NULL,
    "聯絡人二" varchar(40) DEFAULT ' ' NOT NULL,
    "電話二" varchar(40) DEFAULT ' ' NOT NULL,
    "分機二" varchar(10) DEFAULT ' ' NOT NULL,
    "發票職務" varchar(40) DEFAULT ' ' NOT NULL,
    "聯絡人三" varchar(40) DEFAULT ' ' NOT NULL,
    "聯絡人三分機" varchar(10) DEFAULT ' ' NOT NULL,
    "傳真" varchar(40) DEFAULT ' ' NOT NULL,
    "email" varchar(100) DEFAULT ' ' NOT NULL,
    "統一編號" varchar(20) DEFAULT ' ' NOT NULL,
    "資本額" numeric(16,4) DEFAULT 0 NOT NULL,
    "員工數" integer DEFAULT 0 NOT NULL,
    "總公司" varchar(10) DEFAULT ' ' NOT NULL,
    "總公司收款" smallint DEFAULT 0 NOT NULL,
    "交易幣別" varchar(3) DEFAULT ' ' NOT NULL,
    "採購人員" varchar(10) DEFAULT ' ' NOT NULL,
    "代理人" varchar(10) DEFAULT ' ' NOT NULL,
    "開業日" char(8) DEFAULT '00000000' NOT NULL,
    "訂金比率" numeric(5,2) DEFAULT 0 NOT NULL,
    "價格條件" varchar(40) DEFAULT ' ' NOT NULL,
    "收付類別" varchar(1) DEFAULT ' ' NOT NULL,
    "收付方式" varchar(10) DEFAULT ' ' NOT NULL,
    "稅額計算方式" varchar(1) DEFAULT ' ' NOT NULL,
    "單身多稅率" smallint DEFAULT 0 NOT NULL,
    "發票類別" varchar(2) DEFAULT ' ' NOT NULL,
    "稅別代碼" varchar(10) DEFAULT ' ' NOT NULL,
    "課稅別" varchar(1) DEFAULT ' ' NOT NULL,
    "單據發送方式" varchar(1) DEFAULT ' ' NOT NULL,
    "票據寄領" varchar(1) DEFAULT ' ' NOT NULL,
    "隨貨附發票" smallint DEFAULT 0 NOT NULL,
    "區域代號" varchar(10) DEFAULT ' ' NOT NULL,
    "國別代號" varchar(10) DEFAULT ' ' NOT NULL,
    "匯至EBC" smallint DEFAULT 0 NOT NULL,
    "EBC申請代號" varchar(20) DEFAULT ' ' NOT NULL,
    "結帳日" smallint DEFAULT 0 NOT NULL,
    "匯款總行" varchar(20) DEFAULT ' ' NOT NULL,
    "匯款銀行" varchar(20) DEFAULT ' ' NOT NULL,
    "匯款帳號" varchar(20) DEFAULT ' ' NOT NULL,
    "應收付款科目" varchar(10) DEFAULT ' ' NOT NULL,
    "應收付票科目" varchar(10) DEFAULT ' ' NOT NULL,
    "備註" varchar(100) DEFAULT ' ' NOT NULL,
    "交易條件" varchar(1) DEFAULT ' ' NOT NULL,
    "版次" smallint DEFAULT 0 NOT NULL,
    "核准日期" char(8) DEFAULT '00000000' NOT NULL,
    "登入密碼" varchar(20) DEFAULT ' ' NOT NULL,
    "x1" varchar(1) DEFAULT ' ' NOT NULL,
    "憑證列印格式" varchar(1) DEFAULT ' ' NOT NULL,
    "核准狀況" varchar(1) DEFAULT ' ' NOT NULL,
    "會計傳真" varchar(40) DEFAULT ' ' NOT NULL,
    "交易項目" varchar(100) DEFAULT ' ' NOT NULL,
    "廠商分類" varchar(10) DEFAULT ' ' NOT NULL,
    "允許分批交貨" smallint DEFAULT 0 NOT NULL,
    "加工費用科目" varchar(10) DEFAULT ' ' NOT NULL,
    "ABC等級" varchar(1) DEFAULT ' ' NOT NULL,
    "交貨評等" varchar(20) DEFAULT ' ' NOT NULL,
    "品質評等" varchar(20) DEFAULT ' ' NOT NULL,
    "個月逢" smallint DEFAULT 0 NOT NULL,
    "x2" varchar(1) DEFAULT ' ' NOT NULL,
    "年營業額" numeric(12,0) DEFAULT 0 NOT NULL,
    "英文名稱" varchar(100) DEFAULT ' ' NOT NULL,
    "帳單收件人" varchar(60) DEFAULT ' ' NOT NULL,
    "發票號碼依總公司控管" smallint DEFAULT 0 NOT NULL,
    "合約訂單是否歸屬總公司" smallint DEFAULT 0 NOT NULL,
    "分店數" smallint DEFAULT 0 NOT NULL,
    "部門別" varchar(10) DEFAULT ' ' NOT NULL,
    "收款業務" varchar(10) DEFAULT ' ' NOT NULL,
    "歇業日" char(8) DEFAULT '00000000' NOT NULL,
    "信用額度依總公司控管" smallint DEFAULT 0 NOT NULL,
    "信用額度管制" smallint DEFAULT 0 NOT NULL,
    "信用額度" numeric(10,0) DEFAULT 0 NOT NULL,
    "可超出率" numeric(4,2) DEFAULT 0 NOT NULL,
    "訂單信用查核方式" varchar(1) DEFAULT ' ' NOT NULL,
    "出貨通知信用查核方式" varchar(1) DEFAULT ' ' NOT NULL,
    "銷貨信用查核方式" varchar(1) DEFAULT ' ' NOT NULL,
    "暫出單信用查核方式" varchar(1) DEFAULT ' ' NOT NULL,
    "通關方式" varchar(1) DEFAULT ' ' NOT NULL,
    "客戶型態" varchar(10) DEFAULT ' ' NOT NULL,
    "取價順序" varchar(5) DEFAULT ' ' NOT NULL,
    "折扣率" numeric(5,2) DEFAULT 0 NOT NULL,
    "折扣率預設" smallint DEFAULT 0 NOT NULL,
    "付款總行二" varchar(20) DEFAULT ' ' NOT NULL,
    "付款總行三" varchar(20) DEFAULT ' ' NOT NULL,
    "付款銀行二" varchar(20) DEFAULT ' ' NOT NULL,
    "付款銀行三" varchar(20) DEFAULT ' ' NOT NULL,
    "銀行帳號二" varchar(20) DEFAULT ' ' NOT NULL,
    "銀行帳號三" varchar(20) DEFAULT ' ' NOT NULL,
    "運輸方式" varchar(10) DEFAULT ' ' NOT NULL,
    "x3" varchar(1) DEFAULT ' ' NOT NULL,
    "報價自動回覆" smallint DEFAULT 0 NOT NULL,
    "報價聯絡人" varchar(40) DEFAULT ' ' NOT NULL,
    "報價email" varchar(100) DEFAULT ' ' NOT NULL,
    "驗報自動回覆" smallint DEFAULT 0 NOT NULL,
    "驗報聯絡人" varchar(40) DEFAULT ' ' NOT NULL,
    "驗報email" varchar(100) DEFAULT ' ' NOT NULL,
    "設計圖自動回覆" smallint DEFAULT 0 NOT NULL,
    "設計圖聯絡人" varchar(40) DEFAULT ' ' NOT NULL,
    "設計圖email" varchar(100) DEFAULT ' ' NOT NULL,
    "x4" varchar(1) DEFAULT ' ' NOT NULL,
    "登記郵區一" varchar(10) DEFAULT ' ' NOT NULL,
    "登記地址一" varchar(100) DEFAULT ' ' NOT NULL,
    "登記郵區二" varchar(10) DEFAULT ' ' NOT NULL,
    "登記地址二" varchar(100) DEFAULT ' ' NOT NULL,
    "登記電話" varchar(40) DEFAULT ' ' NOT NULL,
    "製造場所" varchar(40) DEFAULT ' ' NOT NULL,
    "商業登記" varchar(40) DEFAULT ' ' NOT NULL,
    "聯絡郵區一" varchar(10) DEFAULT ' ' NOT NULL,
    "聯絡地址一" varchar(100) DEFAULT ' ' NOT NULL,
    "聯絡郵區二" varchar(10) DEFAULT ' ' NOT NULL,
    "聯絡地址二" varchar(100) DEFAULT ' ' NOT NULL,
    "送貨郵區一" varchar(10) DEFAULT ' ' NOT NULL,
    "送貨地址一" varchar(100) DEFAULT ' ' NOT NULL,
    "送貨郵區二" varchar(10) DEFAULT ' ' NOT NULL,
    "送貨地址二" varchar(100) DEFAULT ' ' NOT NULL,
    "帳單郵區一" varchar(10) DEFAULT ' ' NOT NULL,
    "帳單地址一" varchar(100) DEFAULT ' ' NOT NULL,
    "帳單郵區二" varchar(10) DEFAULT ' ' NOT NULL,
    "帳單地址二" varchar(100) DEFAULT ' ' NOT NULL,
    "發票郵區一" varchar(10) DEFAULT ' ' NOT NULL,
    "發票地址一" varchar(100) DEFAULT ' ' NOT NULL,
    "發票郵區二" varchar(10) DEFAULT ' ' NOT NULL,
    "發票地址二" varchar(100) DEFAULT ' ' NOT NULL,
    "文件郵區一" varchar(10) DEFAULT ' ' NOT NULL,
    "文件地址一" varchar(100) DEFAULT ' ' NOT NULL,
    "文件郵區二" varchar(10) DEFAULT ' ' NOT NULL,
    "文件地址二" varchar(100) DEFAULT ' ' NOT NULL,
    "流水編號" varchar(60) DEFAULT ' ' NOT NULL,
    "建立員工" varchar(10) DEFAULT ' ' NOT NULL,
    "建立日期" timestamp(0),
    "最後更新者" varchar(10) DEFAULT ' ' NOT NULL,
    "最後更新日" timestamp(0),
    PRIMARY KEY ("編號")
);
CREATE UNIQUE INDEX "fil0011_02" ON "fil0011" ("廠客", "編號");
COMMENT ON TABLE "fil0011" IS '0.廠客資料檔';
COMMENT ON COLUMN "fil0011"."聯絡人一" IS '最常聯絡人';
COMMENT ON COLUMN "fil0011"."電話一" IS '最常電話';
COMMENT ON COLUMN "fil0011"."分機一" IS '最常分機';
COMMENT ON COLUMN "fil0011"."聯絡人二" IS '發票聯絡人';
COMMENT ON COLUMN "fil0011"."電話二" IS '發票電話';
COMMENT ON COLUMN "fil0011"."分機二" IS '發票分機';
COMMENT ON COLUMN "fil0011"."總公司" IS '總公司(總店號)';
COMMENT ON COLUMN "fil0011"."總公司收款" IS '總公司收款(請款)';
COMMENT ON COLUMN "fil0011"."採購人員" IS '採購人員(業務)';
COMMENT ON COLUMN "fil0011"."訂金比率" IS '訂金比率%';
COMMENT ON COLUMN "fil0011"."收付類別" IS '收付類別(方式)';
COMMENT ON COLUMN "fil0011"."收付方式" IS '收付方式(條件)';
COMMENT ON COLUMN "fil0011"."發票類別" IS '發票類別(聯數)';
COMMENT ON COLUMN "fil0011"."匯款總行" IS '匯(付)款總行';
COMMENT ON COLUMN "fil0011"."匯款銀行" IS '匯(付)款銀行';
COMMENT ON COLUMN "fil0011"."匯款帳號" IS '匯(付)款帳號';
COMMENT ON COLUMN "fil0011"."x1" IS 'x1===================以下廠商用';
COMMENT ON COLUMN "fil0011"."x2" IS 'x2===================以下客戶用';
COMMENT ON COLUMN "fil0011"."合約訂單是否歸屬總公司" IS '不用回簽報價單';
COMMENT ON COLUMN "fil0011"."可超出率" IS '可超出率%';
COMMENT ON COLUMN "fil0011"."折扣率" IS '折扣率%';
COMMENT ON COLUMN "fil0011"."折扣率預設" IS '採購印總標籤';
COMMENT ON COLUMN "fil0011"."x3" IS 'x3=============================';
COMMENT ON COLUMN "fil0011"."x4" IS 'x4=============================';
COMMENT ON COLUMN "fil0011"."建立日期" IS '建立日期 / 建立時間';
COMMENT ON COLUMN "fil0011"."最後更新日" IS '最後更新日 / 最後更新時';

-- Files：0.品號資料檔
CREATE TABLE "fil0012" (
    "產品編號" varchar(20) DEFAULT ' ' NOT NULL,
    "產品類別" varchar(1) DEFAULT ' ' NOT NULL,
    "物料大類" varchar(10) DEFAULT ' ' NOT NULL,
    "品名" varchar(100) DEFAULT ' ' NOT NULL,
    "規格" varchar(100) DEFAULT ' ' NOT NULL,
    "客戶成品尺寸" varchar(100) DEFAULT ' ' NOT NULL,
    "客戶最終名稱" varchar(100) DEFAULT ' ' NOT NULL,
    "貨號" varchar(30) DEFAULT ' ' NOT NULL,
    "版次" smallint DEFAULT 0 NOT NULL,
    "單位代碼" varchar(10) DEFAULT ' ' NOT NULL,
    "包裝數量" numeric(14,4) DEFAULT 0 NOT NULL,
    "包裝單位" varchar(10) DEFAULT ' ' NOT NULL,
    "新品號核准日期" char(8) DEFAULT '00000000' NOT NULL,
    "修改品名規格" smallint DEFAULT 0 NOT NULL,
    "財務" varchar(10) DEFAULT ' ' NOT NULL,
    "主要庫別" varchar(10) DEFAULT ' ' NOT NULL,
    "採購單位" varchar(10) DEFAULT ' ' NOT NULL,
    "銷售單位" varchar(10) DEFAULT ' ' NOT NULL,
    "稅則" varchar(20) DEFAULT ' ' NOT NULL,
    "條碼編號" varchar(40) DEFAULT ' ' NOT NULL,
    "庫存管理" smallint DEFAULT 0 NOT NULL,
    "批號管理" smallint DEFAULT 0 NOT NULL,
    "進價管制" smallint DEFAULT 0 NOT NULL,
    "單價上限率" numeric(14,4) DEFAULT 0 NOT NULL,
    "售價管制" smallint DEFAULT 0 NOT NULL,
    "單價下限率" numeric(14,4) DEFAULT 0 NOT NULL,
    "超交管理" smallint DEFAULT 0 NOT NULL,
    "超交率" numeric(5,2) DEFAULT 0 NOT NULL,
    "品號屬性" varchar(1) DEFAULT ' ' NOT NULL,
    "低階碼" varchar(2) DEFAULT ' ' NOT NULL,
    "備註" varchar(300) DEFAULT ' ' NOT NULL,
    "標準途程品號" varchar(20) DEFAULT ' ' NOT NULL,
    "採購人" varchar(10) DEFAULT ' ' NOT NULL,
    "主供應商" varchar(10) DEFAULT ' ' NOT NULL,
    "補貨政策" varchar(1) DEFAULT ' ' NOT NULL,
    "固定前置天數" smallint DEFAULT 0 NOT NULL,
    "變動前置天數" smallint DEFAULT 0 NOT NULL,
    "批量" integer DEFAULT 0 NOT NULL,
    "承認碼" varchar(1) DEFAULT ' ' NOT NULL,
    "最低補量" integer DEFAULT 0 NOT NULL,
    "補貨倍量" integer DEFAULT 0 NOT NULL,
    "領用倍量" integer DEFAULT 0 NOT NULL,
    "轉撥倍量" integer DEFAULT 0 NOT NULL,
    "檢驗方式" varchar(1) DEFAULT ' ' NOT NULL,
    "領料代碼" varchar(1) DEFAULT ' ' NOT NULL,
    "超收率" numeric(5,2) DEFAULT 0 NOT NULL,
    "標準進價" numeric(14,4) DEFAULT 0 NOT NULL,
    "標準售價" numeric(14,4) DEFAULT 0 NOT NULL,
    "零售價" numeric(14,4) DEFAULT 0 NOT NULL,
    "售價定價一" numeric(14,4) DEFAULT 0 NOT NULL,
    "營業稅率" numeric(5,2) DEFAULT 0 NOT NULL,
    "重量單位" varchar(10) DEFAULT ' ' NOT NULL,
    "熟成溫度1" varchar(20) DEFAULT ' ' NOT NULL,
    "熟成時間1" varchar(20) DEFAULT ' ' NOT NULL,
    "熟成溫度2" varchar(20) DEFAULT ' ' NOT NULL,
    "熟成時間2" varchar(20) DEFAULT ' ' NOT NULL,
    "英文品名" varchar(100) DEFAULT ' ' NOT NULL,
    "材質結構1" varchar(20) DEFAULT ' ' NOT NULL,
    "材質結構2" varchar(20) DEFAULT ' ' NOT NULL,
    "材質結構3" varchar(20) DEFAULT ' ' NOT NULL,
    "失效日期" char(8) DEFAULT '00000000' NOT NULL,
    "安全存量" numeric(14,4) DEFAULT 0 NOT NULL,
    "進貨報價類別" varchar(20) DEFAULT ' ' NOT NULL,
    "qrcode" bytea,
    "最佳製袋PLC" varchar(60) DEFAULT ' ' NOT NULL,
    "盤點日期" char(8) DEFAULT '00000000' NOT NULL,
    "盤存數量" numeric(14,4) DEFAULT 0 NOT NULL,
    "流水編號" varchar(60) DEFAULT ' ' NOT NULL,
    "建立員工" varchar(10) DEFAULT ' ' NOT NULL,
    "建立日期" timestamp(0),
    "建立日" timestamp(0),
    "最後更新者" varchar(10) DEFAULT ' ' NOT NULL,
    "最後更新日" timestamp(0),
    PRIMARY KEY ("產品編號")
);
CREATE UNIQUE INDEX "fil0012_02" ON "fil0012" ("產品類別", "產品編號");
CREATE UNIQUE INDEX "fil0012_03" ON "fil0012" ("產品類別", "物料大類", "產品編號");
CREATE UNIQUE INDEX "fil0012_04" ON "fil0012" ("物料大類", "產品編號");
CREATE INDEX "fil0012_05" ON "fil0012" ("流水編號");
CREATE INDEX "fil0012_06" ON "fil0012" ("最佳製袋PLC");
COMMENT ON TABLE "fil0012" IS '0.品號資料檔';
COMMENT ON COLUMN "fil0012"."產品編號" IS 'F.產品/M.原物料編號';
COMMENT ON COLUMN "fil0012"."產品類別" IS '成品/原物料';
COMMENT ON COLUMN "fil0012"."物料大類" IS 'M.物料大類';
COMMENT ON COLUMN "fil0012"."品名" IS 'F/M.品名';
COMMENT ON COLUMN "fil0012"."規格" IS 'F.成品尺寸(喜美)/M.規格';
COMMENT ON COLUMN "fil0012"."客戶成品尺寸" IS 'F.客戶成品尺寸';
COMMENT ON COLUMN "fil0012"."客戶最終名稱" IS 'F.客戶最終名稱';
COMMENT ON COLUMN "fil0012"."貨號" IS 'F.客戶貨號/M.廠商貨號';
COMMENT ON COLUMN "fil0012"."版次" IS 'xx版次';
COMMENT ON COLUMN "fil0012"."單位代碼" IS 'F/M.庫存單位';
COMMENT ON COLUMN "fil0012"."包裝數量" IS '每捲長度';
COMMENT ON COLUMN "fil0012"."包裝單位" IS 'F/M.代理人';
COMMENT ON COLUMN "fil0012"."新品號核准日期" IS 'F/M.新品號核准日期';
COMMENT ON COLUMN "fil0012"."修改品名規格" IS 'xx修改品名規格?';
COMMENT ON COLUMN "fil0012"."財務" IS 'F/M.財務';
COMMENT ON COLUMN "fil0012"."主要庫別" IS 'M.主要庫別';
COMMENT ON COLUMN "fil0012"."採購單位" IS 'M.採購單位(包裝單位)';
COMMENT ON COLUMN "fil0012"."銷售單位" IS 'F.銷售單位';
COMMENT ON COLUMN "fil0012"."稅則" IS 'xx稅則';
COMMENT ON COLUMN "fil0012"."條碼編號" IS 'F.條碼編號';
COMMENT ON COLUMN "fil0012"."庫存管理" IS 'xx庫存管理?';
COMMENT ON COLUMN "fil0012"."批號管理" IS '批號管理?';
COMMENT ON COLUMN "fil0012"."進價管制" IS 'xx進價管制?';
COMMENT ON COLUMN "fil0012"."單價上限率" IS 'xx單價上限率%';
COMMENT ON COLUMN "fil0012"."售價管制" IS 'xx售價管制?';
COMMENT ON COLUMN "fil0012"."單價下限率" IS 'M.重量';
COMMENT ON COLUMN "fil0012"."超交管理" IS 'F.超交管理?';
COMMENT ON COLUMN "fil0012"."超交率" IS 'F.超交率%';
COMMENT ON COLUMN "fil0012"."品號屬性" IS 'F/M.品號屬性';
COMMENT ON COLUMN "fil0012"."低階碼" IS 'xx低階碼';
COMMENT ON COLUMN "fil0012"."備註" IS 'F/M.備註';
COMMENT ON COLUMN "fil0012"."標準途程品號" IS 'F.客戶/M.次要供應商';
COMMENT ON COLUMN "fil0012"."採購人" IS 'F/M.採購人';
COMMENT ON COLUMN "fil0012"."主供應商" IS 'M.主供應商';
COMMENT ON COLUMN "fil0012"."補貨政策" IS 'F.內外銷';
COMMENT ON COLUMN "fil0012"."固定前置天數" IS 'xx固定前置天數';
COMMENT ON COLUMN "fil0012"."變動前置天數" IS 'xx變動前置天數';
COMMENT ON COLUMN "fil0012"."批量" IS 'xx批量';
COMMENT ON COLUMN "fil0012"."承認碼" IS 'xx承認碼';
COMMENT ON COLUMN "fil0012"."最低補量" IS 'xx最低補量';
COMMENT ON COLUMN "fil0012"."補貨倍量" IS 'xx補貨倍量';
COMMENT ON COLUMN "fil0012"."領用倍量" IS 'xx領用倍量';
COMMENT ON COLUMN "fil0012"."轉撥倍量" IS 'xx轉撥倍量';
COMMENT ON COLUMN "fil0012"."檢驗方式" IS 'M.檢驗方式';
COMMENT ON COLUMN "fil0012"."領料代碼" IS 'M.領料代碼';
COMMENT ON COLUMN "fil0012"."超收率" IS 'M.超收率%';
COMMENT ON COLUMN "fil0012"."標準進價" IS 'M.標準進價';
COMMENT ON COLUMN "fil0012"."標準售價" IS 'M.標準售價';
COMMENT ON COLUMN "fil0012"."零售價" IS 'M.零售價';
COMMENT ON COLUMN "fil0012"."售價定價一" IS 'M.售價定價一';
COMMENT ON COLUMN "fil0012"."營業稅率" IS 'M.營業稅率%';
COMMENT ON COLUMN "fil0012"."重量單位" IS 'M.重量單位';
COMMENT ON COLUMN "fil0012"."熟成溫度1" IS 'F.熟成溫度1';
COMMENT ON COLUMN "fil0012"."熟成時間1" IS 'F.熟成時間1';
COMMENT ON COLUMN "fil0012"."熟成溫度2" IS 'F.熟成溫度2';
COMMENT ON COLUMN "fil0012"."熟成時間2" IS 'F.熟成時間2';
COMMENT ON COLUMN "fil0012"."英文品名" IS 'F/M.英文品名';
COMMENT ON COLUMN "fil0012"."材質結構1" IS 'F.材質結構1/M.對應代號一';
COMMENT ON COLUMN "fil0012"."材質結構2" IS 'F.材質結構2/M.對應代號二';
COMMENT ON COLUMN "fil0012"."材質結構3" IS 'F.材質結構3';
COMMENT ON COLUMN "fil0012"."失效日期" IS 'F/M.失效日期';
COMMENT ON COLUMN "fil0012"."盤存數量" IS '庫存數量';
COMMENT ON COLUMN "fil0012"."建立日" IS '建立時間';
COMMENT ON COLUMN "fil0012"."最後更新日" IS '最後更新日 / 最後更新時';

-- Files：0.廠別資料檔
CREATE TABLE "fil0013" (
    "廠別編號" varchar(4) DEFAULT ' ' NOT NULL,
    "廠別名稱" varchar(100) DEFAULT ' ' NOT NULL,
    "建立員工" varchar(10) DEFAULT ' ' NOT NULL,
    "建立日期" timestamp(0),
    "建立日" timestamp(0),
    "最後更新者" varchar(10) DEFAULT ' ' NOT NULL,
    "最後更新日" timestamp(0),
    PRIMARY KEY ("廠別編號")
);
COMMENT ON TABLE "fil0013" IS '0.廠別資料檔';
COMMENT ON COLUMN "fil0013"."建立日" IS '建立時間';
COMMENT ON COLUMN "fil0013"."最後更新日" IS '最後更新日 / 最後更新時';

-- Files：0.廠客其它聯絡人
CREATE TABLE "fil0014" (
    "廠客編號" varchar(10) DEFAULT ' ' NOT NULL,
    "序號" smallint DEFAULT 0 NOT NULL,
    "聯絡人" varchar(40) DEFAULT ' ' NOT NULL,
    "電話" varchar(40) DEFAULT ' ' NOT NULL,
    "分機" varchar(10) DEFAULT ' ' NOT NULL,
    "職務" varchar(20) DEFAULT ' ' NOT NULL,
    "email" varchar(100) DEFAULT ' ' NOT NULL,
    "行動電話" varchar(40) DEFAULT ' ' NOT NULL,
    "備註" varchar(100) DEFAULT ' ' NOT NULL,
    PRIMARY KEY ("廠客編號", "序號")
);
COMMENT ON TABLE "fil0014" IS '0.廠客其它聯絡人';

-- Files：0.廠客送貨地址
CREATE TABLE "fil0015" (
    "廠客編號" varchar(10) DEFAULT ' ' NOT NULL,
    "序號" smallint DEFAULT 0 NOT NULL,
    "收貨人" varchar(40) DEFAULT ' ' NOT NULL,
    "地址" varchar(100) DEFAULT ' ' NOT NULL,
    "電話" varchar(40) DEFAULT ' ' NOT NULL,
    PRIMARY KEY ("廠客編號", "序號")
);
COMMENT ON TABLE "fil0015" IS '0.廠客送貨地址';

-- Files：0.請假資料檔
CREATE TABLE "fil0016" (
    "單據類別" varchar(10) DEFAULT ' ' NOT NULL,
    "單據編號" varchar(20) DEFAULT ' ' NOT NULL,
    "單據日期" char(8) DEFAULT '00000000' NOT NULL,
    "員工編號" varchar(10) DEFAULT ' ' NOT NULL,
    "請假日期_起" char(8) DEFAULT '00000000' NOT NULL,
    "請假日期_迄" char(8) DEFAULT '00000000' NOT NULL,
    "請假時間_起" char(6) DEFAULT '000000' NOT NULL,
    "請假時間_迄" char(6) DEFAULT '000000' NOT NULL,
    "請假假別代碼" varchar(2) DEFAULT ' ' NOT NULL,
    "假別代碼" varchar(2) DEFAULT ' ' NOT NULL,
    "事由" varchar(100) DEFAULT ' ' NOT NULL,
    "填表人" varchar(10) DEFAULT ' ' NOT NULL,
    "填表日" timestamp(0),
    "最後更新者" varchar(10) DEFAULT ' ' NOT NULL,
    "最後更新日" timestamp(0),
    PRIMARY KEY ("單據類別", "單據編號")
);
CREATE INDEX "fil0016_02" ON "fil0016" ("員工編號", "單據日期");
CREATE INDEX "fil0016_03" ON "fil0016" ("員工編號", "請假時間_迄");
COMMENT ON TABLE "fil0016" IS '0.請假資料檔';
COMMENT ON COLUMN "fil0016"."請假日期_起" IS '請假日期(起)';
COMMENT ON COLUMN "fil0016"."請假日期_迄" IS '請假日期(迄)';
COMMENT ON COLUMN "fil0016"."請假時間_起" IS '請假時間(起)';
COMMENT ON COLUMN "fil0016"."請假時間_迄" IS '請假時間(迄)';
COMMENT ON COLUMN "fil0016"."假別代碼" IS '扣薪假別代碼';
COMMENT ON COLUMN "fil0016"."填表日" IS '填表日 / 填表時';
COMMENT ON COLUMN "fil0016"."最後更新日" IS '最後更新日 / 最後更新時';

-- Files：0.單位換算檔
CREATE TABLE "fil0017" (
    "從" varchar(10) DEFAULT ' ' NOT NULL,
    "到" varchar(10) DEFAULT ' ' NOT NULL,
    "換算率" numeric(16,6) DEFAULT 0 NOT NULL,
    "最後更新者" varchar(10) DEFAULT ' ' NOT NULL,
    "最後更新日" timestamp(0),
    "最後更新時" timestamp(0),
    PRIMARY KEY ("從", "到")
);
COMMENT ON TABLE "fil0017" IS '0.單位換算檔';

-- Files：0.科目代碼檔
CREATE TABLE "fil0018" (
    "科目代碼" varchar(10) DEFAULT ' ' NOT NULL,
    "科目名稱" varchar(60) DEFAULT ' ' NOT NULL,
    "建立員工" varchar(10) DEFAULT ' ' NOT NULL,
    "建立日期" timestamp(0),
    "建立日" timestamp(0),
    "最後更新者" varchar(10) DEFAULT ' ' NOT NULL,
    "最後更新日" timestamp(0),
    PRIMARY KEY ("科目代碼")
);
COMMENT ON TABLE "fil0018" IS '0.科目代碼檔';
COMMENT ON COLUMN "fil0018"."建立日" IS '建立時間';
COMMENT ON COLUMN "fil0018"."最後更新日" IS '最後更新日 / 最後更新時';

-- Files：0.採購單價檔
CREATE TABLE "fil0019" (
    "物料編號" varchar(20) DEFAULT ' ' NOT NULL,
    "廠商編號" varchar(10) DEFAULT ' ' NOT NULL,
    "廠商料號" varchar(40) DEFAULT ' ' NOT NULL,
    "幣別代碼" varchar(3) DEFAULT ' ' NOT NULL,
    "價格條件" varchar(40) DEFAULT ' ' NOT NULL,
    "採購單位" varchar(10) DEFAULT ' ' NOT NULL,
    "單價" numeric(14,4) DEFAULT 0 NOT NULL,
    "最大供量" numeric(14,4) DEFAULT 0 NOT NULL,
    "建立員工" varchar(10) DEFAULT ' ' NOT NULL,
    "建立日期" timestamp(0),
    "建立日" timestamp(0),
    "最後更新者" varchar(10) DEFAULT ' ' NOT NULL,
    "最後更新日" timestamp(0),
    PRIMARY KEY ("物料編號", "廠商編號")
);
CREATE UNIQUE INDEX "fil0019_02" ON "fil0019" ("廠商編號", "物料編號");
COMMENT ON TABLE "fil0019" IS '0.採購單價檔';
COMMENT ON COLUMN "fil0019"."建立日" IS '建立時間';
COMMENT ON COLUMN "fil0019"."最後更新日" IS '最後更新日 / 最後更新時';

-- Files：0.部門資料檔
CREATE TABLE "fil0020" (
    "部門編號" varchar(10) DEFAULT ' ' NOT NULL,
    "部門名稱" varchar(40) DEFAULT ' ' NOT NULL,
    "英文名稱" varchar(100) DEFAULT ' ' NOT NULL,
    "出勤津貼" numeric(10,0) DEFAULT 0 NOT NULL,
    "停止使用" smallint DEFAULT 0 NOT NULL,
    "所屬公司" varchar(1) DEFAULT ' ' NOT NULL,
    "上階部門" varchar(10) DEFAULT ' ' NOT NULL,
    "製程" varchar(100) DEFAULT ' ' NOT NULL,
    "製程名稱" varchar(100) DEFAULT ' ' NOT NULL,
    "最後更新者" varchar(10) DEFAULT ' ' NOT NULL,
    "最後更新日" timestamp(0),
    PRIMARY KEY ("部門編號")
);
COMMENT ON TABLE "fil0020" IS '0.部門資料檔';
COMMENT ON COLUMN "fil0020"."製程" IS '製程代碼';
COMMENT ON COLUMN "fil0020"."最後更新日" IS '最後更新日 / 最後更新時';

-- Files：0.銀行資料檔
CREATE TABLE "fil0021" (
    "銀行類別" varchar(4) DEFAULT ' ' NOT NULL,
    "類別名稱" varchar(40) DEFAULT ' ' NOT NULL,
    "總機構代碼" varchar(20) DEFAULT ' ' NOT NULL,
    "分支機構代碼" varchar(20) DEFAULT ' ' NOT NULL,
    "機構名稱" varchar(100) DEFAULT ' ' NOT NULL,
    "地址" varchar(200) DEFAULT ' ' NOT NULL,
    "電話" varchar(100) DEFAULT ' ' NOT NULL,
    "負責人" varchar(40) DEFAULT ' ' NOT NULL,
    "網址" varchar(200) DEFAULT ' ' NOT NULL,
    "最後更新者" varchar(10) DEFAULT ' ' NOT NULL,
    "最後更新日" timestamp(0),
    PRIMARY KEY ("銀行類別", "總機構代碼", "分支機構代碼")
);
CREATE INDEX "fil0021_02" ON "fil0021" ("總機構代碼", "分支機構代碼");
CREATE INDEX "fil0021_03" ON "fil0021" ("分支機構代碼");
COMMENT ON TABLE "fil0021" IS '0.銀行資料檔';
COMMENT ON COLUMN "fil0021"."最後更新日" IS '最後更新日 / 最後更新時';

-- Files：0.匯率資料檔
CREATE TABLE "fil0022" (
    "幣別代碼" varchar(3) DEFAULT ' ' NOT NULL,
    "匯率日期" char(8) DEFAULT '00000000' NOT NULL,
    "現鈔匯率" numeric(8,5) DEFAULT 0 NOT NULL,
    "一般匯率" numeric(8,5) DEFAULT 0 NOT NULL,
    "出口匯率" numeric(8,5) DEFAULT 0 NOT NULL,
    "進口匯率" numeric(8,5) DEFAULT 0 NOT NULL,
    "啟用" smallint DEFAULT 0 NOT NULL,
    "即期買入" numeric(8,5) DEFAULT 0 NOT NULL,
    "即期賣出" numeric(8,5) DEFAULT 0 NOT NULL,
    "平均匯率" numeric(8,5) DEFAULT 0 NOT NULL,
    "月平均匯率" numeric(8,5) DEFAULT 0 NOT NULL,
    "海關買進" numeric(8,5) DEFAULT 0 NOT NULL,
    "海關賣出" numeric(8,5) DEFAULT 0 NOT NULL,
    "最後更新者" varchar(10) DEFAULT ' ' NOT NULL,
    "最後更新日" timestamp(0),
    PRIMARY KEY ("幣別代碼", "匯率日期")
);
CREATE UNIQUE INDEX "fil0022_02" ON "fil0022" ("匯率日期" DESC, "幣別代碼");
COMMENT ON TABLE "fil0022" IS '0.匯率資料檔';
COMMENT ON COLUMN "fil0022"."現鈔匯率" IS 'xx現鈔匯率';
COMMENT ON COLUMN "fil0022"."一般匯率" IS 'xx一般匯率';
COMMENT ON COLUMN "fil0022"."出口匯率" IS 'xx出口匯率';
COMMENT ON COLUMN "fil0022"."進口匯率" IS 'xx進口匯率';
COMMENT ON COLUMN "fil0022"."即期買入" IS '即期買入(A)';
COMMENT ON COLUMN "fil0022"."即期賣出" IS '即期賣出(B)';
COMMENT ON COLUMN "fil0022"."平均匯率" IS '平均匯率(C)';
COMMENT ON COLUMN "fil0022"."月平均匯率" IS 'xx月平均匯率';
COMMENT ON COLUMN "fil0022"."海關買進" IS '海關買進(E)';
COMMENT ON COLUMN "fil0022"."海關賣出" IS '海關賣出(F)';
COMMENT ON COLUMN "fil0022"."最後更新日" IS '最後更新日 / 最後更新時';

-- Files：0.費用項目檔
CREATE TABLE "fil0023" (
    "費用代碼" varchar(10) DEFAULT ' ' NOT NULL,
    "費用名稱" varchar(60) DEFAULT ' ' NOT NULL,
    "幣別代碼" varchar(3) DEFAULT ' ' NOT NULL,
    "金額" numeric(14,4) DEFAULT 0 NOT NULL,
    "稅額" numeric(14,4) DEFAULT 0 NOT NULL,
    "付款條件" varchar(10) DEFAULT ' ' NOT NULL,
    "建立員工" varchar(10) DEFAULT ' ' NOT NULL,
    "建立日期" timestamp(0),
    "建立日" timestamp(0),
    "最後更新者" varchar(10) DEFAULT ' ' NOT NULL,
    "最後更新日" timestamp(0),
    PRIMARY KEY ("費用代碼")
);
COMMENT ON TABLE "fil0023" IS '0.費用項目檔';
COMMENT ON COLUMN "fil0023"."建立日" IS '建立時間';
COMMENT ON COLUMN "fil0023"."最後更新日" IS '最後更新日 / 最後更新時';

-- Files：0.員工製程檔
CREATE TABLE "fil0024" (
    "員工編號" varchar(10) DEFAULT ' ' NOT NULL,
    "c31a" smallint DEFAULT 0 NOT NULL,
    "c31b" smallint DEFAULT 0 NOT NULL,
    "c31c" smallint DEFAULT 0 NOT NULL,
    "c31d" smallint DEFAULT 0 NOT NULL,
    "c31e" smallint DEFAULT 0 NOT NULL,
    "c31f" smallint DEFAULT 0 NOT NULL,
    "c31g" smallint DEFAULT 0 NOT NULL,
    "c31h" smallint DEFAULT 0 NOT NULL,
    "c31i" smallint DEFAULT 0 NOT NULL,
    "c31k" smallint DEFAULT 0 NOT NULL,
    "c32d" smallint DEFAULT 0 NOT NULL,
    "c32e" smallint DEFAULT 0 NOT NULL,
    "內定工站一" varchar(10) DEFAULT ' ' NOT NULL,
    PRIMARY KEY ("員工編號")
);
COMMENT ON TABLE "fil0024" IS '0.員工製程檔';
COMMENT ON COLUMN "fil0024"."c31a" IS 'C31A.印刷';
COMMENT ON COLUMN "fil0024"."c31b" IS 'C31B.淋膜';
COMMENT ON COLUMN "fil0024"."c31c" IS 'C31C.積層';
COMMENT ON COLUMN "fil0024"."c31d" IS 'C31D.裁切';
COMMENT ON COLUMN "fil0024"."c31e" IS 'C31E.製袋';
COMMENT ON COLUMN "fil0024"."c31f" IS 'C31F.氣閥';
COMMENT ON COLUMN "fil0024"."c31g" IS 'C31G.鐵條';
COMMENT ON COLUMN "fil0024"."c31h" IS 'C31H.印刷檢品';
COMMENT ON COLUMN "fil0024"."c31i" IS 'C31I.成捲包裝';
COMMENT ON COLUMN "fil0024"."c31k" IS 'C31K.裁切檢品';
COMMENT ON COLUMN "fil0024"."c32d" IS 'C32D上臘';
COMMENT ON COLUMN "fil0024"."c32e" IS 'C32E版銅';

-- Files：0.班別代碼檔
CREATE TABLE "fil0025" (
    "代碼" varchar(1) DEFAULT ' ' NOT NULL,
    "名稱" varchar(20) DEFAULT ' ' NOT NULL,
    "上班起時" char(6) DEFAULT '000000' NOT NULL,
    "上班迄時" char(6) DEFAULT '000000' NOT NULL,
    "休息起時" char(6) DEFAULT '000000' NOT NULL,
    "休息迄時" char(6) DEFAULT '000000' NOT NULL,
    "彈性上班" smallint DEFAULT 0 NOT NULL,
    "遲到時間" char(6) DEFAULT '000000' NOT NULL,
    PRIMARY KEY ("代碼")
);
COMMENT ON TABLE "fil0025" IS '0.班別代碼檔';

-- Files：0.異動單主檔
CREATE TABLE "fil0030" (
    "單據類別" varchar(10) DEFAULT ' ' NOT NULL,
    "單據編號" varchar(20) DEFAULT ' ' NOT NULL,
    "單據日期" char(8) DEFAULT '00000000' NOT NULL,
    "訂單號碼" varchar(20) DEFAULT ' ' NOT NULL,
    "採購單號" varchar(20) DEFAULT ' ' NOT NULL,
    "歸屬類別" varchar(10) DEFAULT ' ' NOT NULL,
    "歸屬編號" varchar(20) DEFAULT ' ' NOT NULL,
    "歸屬序號" smallint DEFAULT 0 NOT NULL,
    "公司代碼" varchar(1) DEFAULT ' ' NOT NULL,
    "簽核系統" varchar(40) DEFAULT ' ' NOT NULL,
    "簽核系統_結案" varchar(40) DEFAULT ' ' NOT NULL,
    "廠客編號" varchar(10) DEFAULT ' ' NOT NULL,
    "幣別代碼" varchar(3) DEFAULT ' ' NOT NULL,
    "稅別" varchar(1) DEFAULT ' ' NOT NULL,
    "稅率" numeric(8,5) DEFAULT 0 NOT NULL,
    "匯率" numeric(8,5) DEFAULT 0 NOT NULL,
    "匯率日期" char(8) DEFAULT '00000000' NOT NULL,
    "匯率類別" varchar(1) DEFAULT ' ' NOT NULL,
    "廠客單號" varchar(40) DEFAULT ' ' NOT NULL,
    "廠別編號" varchar(4) DEFAULT ' ' NOT NULL,
    "部門編號" varchar(10) DEFAULT ' ' NOT NULL,
    "收付方式" varchar(10) DEFAULT ' ' NOT NULL,
    "折讓" numeric(14,4) DEFAULT 0 NOT NULL,
    "備註" varchar(2000) DEFAULT ' ' NOT NULL,
    "業務員" varchar(10) DEFAULT ' ' NOT NULL,
    "確認碼" varchar(1) DEFAULT ' ' NOT NULL,
    "倉庫代碼" varchar(10) DEFAULT ' ' NOT NULL,
    "邏輯值一" smallint DEFAULT 0 NOT NULL,
    "流水編號" varchar(60) DEFAULT ' ' NOT NULL,
    "填表人" varchar(10) DEFAULT ' ' NOT NULL,
    "填表日" timestamp(0),
    "最後更新者" varchar(10) DEFAULT ' ' NOT NULL,
    "最後更新日" timestamp(0),
    "其它日期" char(8) DEFAULT '00000000' NOT NULL,
    PRIMARY KEY ("單據類別", "單據編號")
);
CREATE UNIQUE INDEX "fil0030_02" ON "fil0030" ("簽核系統", "單據編號");
CREATE UNIQUE INDEX "fil0030_03" ON "fil0030" ("歸屬類別", "歸屬編號", "單據類別", "單據編號");
CREATE INDEX "fil0030_04" ON "fil0030" ("廠客編號", "單據類別", "單據日期");
CREATE UNIQUE INDEX "fil0030_05" ON "fil0030" ("單據日期", "單據類別", "單據編號");
CREATE INDEX "fil0030_06" ON "fil0030" ("填表人", "單據日期");
CREATE INDEX "fil0030_07" ON "fil0030" ("公司代碼", "單據日期");
CREATE INDEX "fil0030_08" ON "fil0030" ("廠客單號");
CREATE INDEX "fil0030_09" ON "fil0030" ("流水編號");
COMMENT ON TABLE "fil0030" IS '0.異動單主檔';
COMMENT ON COLUMN "fil0030"."稅別" IS '稅別/製令類別';
COMMENT ON COLUMN "fil0030"."收付方式" IS '付款條件';
COMMENT ON COLUMN "fil0030"."折讓" IS '折讓/報廢(表頭)';
COMMENT ON COLUMN "fil0030"."業務員" IS '業務員/採購員';
COMMENT ON COLUMN "fil0030"."確認碼" IS '確認碼(改版:Y)';
COMMENT ON COLUMN "fil0030"."填表日" IS '填表日 / 填表時';
COMMENT ON COLUMN "fil0030"."最後更新日" IS '最後更新日 / 最後更新時';

-- Files：0.特殊欄位主檔
CREATE TABLE "fil0031" (
    "單別" varchar(10) DEFAULT ' ' NOT NULL,
    "單號" varchar(20) DEFAULT ' ' NOT NULL,
    "類別" varchar(10) DEFAULT ' ' NOT NULL,
    "交貨日期_天" smallint DEFAULT 0 NOT NULL,
    "交貨日期" char(8) DEFAULT '00000000' NOT NULL,
    "交貨日期_次批" varchar(1) DEFAULT ' ' NOT NULL,
    "訂金" numeric(14,4) DEFAULT 0 NOT NULL,
    "票期" smallint DEFAULT 0 NOT NULL,
    "回簽" smallint DEFAULT 0 NOT NULL,
    "價格條件" varchar(100) DEFAULT ' ' NOT NULL,
    "材積單位" varchar(10) DEFAULT ' ' NOT NULL,
    "貿易條件" varchar(10) DEFAULT ' ' NOT NULL,
    "運輸方式" varchar(1) DEFAULT ' ' NOT NULL,
    "付款方式" varchar(1) DEFAULT ' ' NOT NULL,
    "送貨地址序號" integer DEFAULT 0 NOT NULL,
    "聯絡人序號" integer DEFAULT 0 NOT NULL,
    "製程代碼" varchar(10) DEFAULT ' ' NOT NULL,
    "工站代碼" varchar(10) DEFAULT ' ' NOT NULL,
    "機台代碼" varchar(10) DEFAULT ' ' NOT NULL,
    "數量" numeric(14,4) DEFAULT 0 NOT NULL,
    "材料編號一" varchar(20) DEFAULT ' ' NOT NULL,
    "材料編號二" varchar(20) DEFAULT ' ' NOT NULL,
    "材料編號三" varchar(20) DEFAULT ' ' NOT NULL,
    "時間一" char(6) DEFAULT '000000' NOT NULL,
    "時間二" char(6) DEFAULT '000000' NOT NULL,
    "時間三" char(6) DEFAULT '000000' NOT NULL,
    "時間四" char(6) DEFAULT '000000' NOT NULL,
    "時間五" char(6) DEFAULT '000000' NOT NULL,
    "時間六" char(6) DEFAULT '000000' NOT NULL,
    "數值1" numeric(14,4) DEFAULT 0 NOT NULL,
    "數值2" numeric(14,4) DEFAULT 0 NOT NULL,
    "數值3" numeric(14,4) DEFAULT 0 NOT NULL,
    "數值4" numeric(14,4) DEFAULT 0 NOT NULL,
    "數值5" numeric(14,4) DEFAULT 0 NOT NULL,
    "數值6" numeric(14,4) DEFAULT 0 NOT NULL,
    "數值7" numeric(14,4) DEFAULT 0 NOT NULL,
    "數值8" numeric(14,4) DEFAULT 0 NOT NULL,
    "數值9" numeric(14,4) DEFAULT 0 NOT NULL,
    "數值10" numeric(14,4) DEFAULT 0 NOT NULL,
    "數值11" numeric(14,4) DEFAULT 0 NOT NULL,
    "數值12" numeric(14,4) DEFAULT 0 NOT NULL,
    "數值13" numeric(14,4) DEFAULT 0 NOT NULL,
    "數值14" numeric(14,4) DEFAULT 0 NOT NULL,
    "數值15" numeric(14,4) DEFAULT 0 NOT NULL,
    "數值16" numeric(14,4) DEFAULT 0 NOT NULL,
    "數值17" numeric(14,4) DEFAULT 0 NOT NULL,
    "數值18" numeric(14,4) DEFAULT 0 NOT NULL,
    "數值19" numeric(14,4) DEFAULT 0 NOT NULL,
    "數值20" numeric(14,4) DEFAULT 0 NOT NULL,
    "數值21" numeric(14,4) DEFAULT 0 NOT NULL,
    "文字1" varchar(500) DEFAULT ' ' NOT NULL,
    "文字2" varchar(500) DEFAULT ' ' NOT NULL,
    "文字3" varchar(500) DEFAULT ' ' NOT NULL,
    "文字4" varchar(100) DEFAULT ' ' NOT NULL,
    "文字5" varchar(20) DEFAULT ' ' NOT NULL,
    "文字6" varchar(20) DEFAULT ' ' NOT NULL,
    "logical1" smallint DEFAULT 0 NOT NULL,
    "logical2" smallint DEFAULT 0 NOT NULL,
    "logical3" smallint DEFAULT 0 NOT NULL,
    "logical4" smallint DEFAULT 0 NOT NULL,
    "logical5" smallint DEFAULT 0 NOT NULL,
    "logical6" smallint DEFAULT 0 NOT NULL,
    "logical7" smallint DEFAULT 0 NOT NULL,
    "logical8" smallint DEFAULT 0 NOT NULL,
    "logical9" smallint DEFAULT 0 NOT NULL,
    "logical10" smallint DEFAULT 0 NOT NULL,
    "logical11" smallint DEFAULT 0 NOT NULL,
    "logical12" smallint DEFAULT 0 NOT NULL,
    "logical13" smallint DEFAULT 0 NOT NULL,
    "文數字1" varchar(40) DEFAULT ' ' NOT NULL,
    "文數字2" varchar(40) DEFAULT ' ' NOT NULL,
    "文數字3" varchar(40) DEFAULT ' ' NOT NULL,
    "文數字4" varchar(40) DEFAULT ' ' NOT NULL,
    "文數字5" varchar(40) DEFAULT ' ' NOT NULL,
    "文數字6" varchar(40) DEFAULT ' ' NOT NULL,
    "文數字7" varchar(40) DEFAULT ' ' NOT NULL,
    "文數字8" varchar(40) DEFAULT ' ' NOT NULL,
    "文數字9" varchar(40) DEFAULT ' ' NOT NULL,
    "文數字10" varchar(40) DEFAULT ' ' NOT NULL,
    "文數字11" varchar(40) DEFAULT ' ' NOT NULL,
    "文數字12" varchar(40) DEFAULT ' ' NOT NULL,
    "文數字13" varchar(40) DEFAULT ' ' NOT NULL,
    "文數字14" varchar(40) DEFAULT ' ' NOT NULL,
    "文數字15" varchar(40) DEFAULT ' ' NOT NULL,
    "流水編號" varchar(60) DEFAULT ' ' NOT NULL,
    PRIMARY KEY ("單別", "單號")
);
CREATE INDEX "fil0031_02" ON "fil0031" ("製程代碼", "機台代碼", "單別", "單號");
CREATE INDEX "fil0031_03" ON "fil0031" ("流水編號");
COMMENT ON TABLE "fil0031" IS '0.特殊欄位主檔';
COMMENT ON COLUMN "fil0031"."交貨日期_天" IS '交貨日期(天)';
COMMENT ON COLUMN "fil0031"."交貨日期" IS '交貨日期(製造日期)';
COMMENT ON COLUMN "fil0031"."交貨日期_次批" IS '一次分批/看色人員';
COMMENT ON COLUMN "fil0031"."票期" IS '票期/色數';
COMMENT ON COLUMN "fil0031"."回簽" IS '回簽/試刷';
COMMENT ON COLUMN "fil0031"."價格條件" IS '價格條件/其他看色人員';
COMMENT ON COLUMN "fil0031"."材積單位" IS '材積單位/磅秤機';
COMMENT ON COLUMN "fil0031"."貿易條件" IS '貿易條件/標籤機';
COMMENT ON COLUMN "fil0031"."運輸方式" IS '運輸方式/頭出尾出';
COMMENT ON COLUMN "fil0031"."付款方式" IS '付款方式/印刷面';
COMMENT ON COLUMN "fil0031"."送貨地址序號" IS '送貨地址序號/版銅圓周';
COMMENT ON COLUMN "fil0031"."聯絡人序號" IS '聯絡人序號/加工速度';
COMMENT ON COLUMN "fil0031"."數量" IS '數量/米數';
COMMENT ON COLUMN "fil0031"."logical2" IS 'Logical2/單頭不限熟成時間';

-- Files：0.產品條件主檔
CREATE TABLE "fil0032" (
    "製令單別" varchar(10) DEFAULT ' ' NOT NULL,
    "製令單號" varchar(20) DEFAULT ' ' NOT NULL,
    "產品編號" varchar(30) NOT NULL,
    "產品名稱" varchar(100) DEFAULT ' ' NOT NULL,
    "前置單別" varchar(10) DEFAULT ' ' NOT NULL,
    "前置單號" varchar(20) DEFAULT ' ' NOT NULL,
    "訂購數量" numeric(14,4) DEFAULT 0 NOT NULL,
    "成品尺寸" varchar(100) DEFAULT ' ' NOT NULL,
    "成品尺寸_高" smallint DEFAULT 0 NOT NULL,
    "成品尺寸_底" smallint DEFAULT 0 NOT NULL,
    "成品尺寸_寬" smallint DEFAULT 0 NOT NULL,
    "展開尺寸" varchar(10) DEFAULT ' ' NOT NULL,
    "總厚度" varchar(10) DEFAULT ' ' NOT NULL,
    "包裝方式" varchar(10) DEFAULT ' ' NOT NULL,
    "用版規格_圓周" smallint DEFAULT 0 NOT NULL,
    "用版規格_版長" smallint DEFAULT 0 NOT NULL,
    "印刷面_裡刷" smallint DEFAULT 0 NOT NULL,
    "印刷面_表刷" smallint DEFAULT 0 NOT NULL,
    "印刷面_霧化" smallint DEFAULT 0 NOT NULL,
    "印刷米數" smallint DEFAULT 0 NOT NULL,
    "印刷單位" varchar(10) DEFAULT ' ' NOT NULL,
    "印刷基材" varchar(20) DEFAULT ' ' NOT NULL,
    "印刷色順一" varchar(10) DEFAULT ' ' NOT NULL,
    "印刷色順二" varchar(10) DEFAULT ' ' NOT NULL,
    "印刷色順三" varchar(10) DEFAULT ' ' NOT NULL,
    "印刷色順四" varchar(10) DEFAULT ' ' NOT NULL,
    "印刷色順五" varchar(10) DEFAULT ' ' NOT NULL,
    "印刷色順六" varchar(10) DEFAULT ' ' NOT NULL,
    "印刷色順七" varchar(10) DEFAULT ' ' NOT NULL,
    "印刷色順八" varchar(10) DEFAULT ' ' NOT NULL,
    "印刷色順九" varchar(10) DEFAULT ' ' NOT NULL,
    "印刷色順十" varchar(10) DEFAULT ' ' NOT NULL,
    "紙張_細面" smallint DEFAULT 0 NOT NULL,
    "紙張_粗面" smallint DEFAULT 0 NOT NULL,
    "油墨種類" varchar(10) DEFAULT ' ' NOT NULL,
    "熟成_溫度起" smallint DEFAULT 0 NOT NULL,
    "熟成_溫度迄" smallint DEFAULT 0 NOT NULL,
    "熟成_時間起" smallint DEFAULT 0 NOT NULL,
    "熟成_時間迄" smallint DEFAULT 0 NOT NULL,
    "鋁箔貼合面_光面" smallint DEFAULT 0 NOT NULL,
    "鋁箔貼合面_霧面" smallint DEFAULT 0 NOT NULL,
    "鋁箔貼合面_三合一" smallint DEFAULT 0 NOT NULL,
    "鋁箔貼合面_四合一" smallint DEFAULT 0 NOT NULL,
    "開窗尺寸1" smallint DEFAULT 0 NOT NULL,
    "開窗尺寸2" smallint DEFAULT 0 NOT NULL,
    "位於" varchar(100) DEFAULT ' ' NOT NULL,
    "裁切規格_起" smallint DEFAULT 0 NOT NULL,
    "裁切規格_迄" smallint DEFAULT 0 NOT NULL,
    "裁切規格_M" smallint DEFAULT 0 NOT NULL,
    "條數" smallint DEFAULT 0 NOT NULL,
    "側底紙_mm" smallint DEFAULT 0 NOT NULL,
    "側底紙_M" smallint DEFAULT 0 NOT NULL,
    "成捲數" smallint DEFAULT 0 NOT NULL,
    "裁切方向" varchar(1) DEFAULT ' ' NOT NULL,
    "灑粉" smallint DEFAULT 0 NOT NULL,
    "製袋型態" varchar(3) DEFAULT ' ' NOT NULL,
    "製袋型態說明" varchar(100) DEFAULT ' ' NOT NULL,
    "加工項目_圓孔6" smallint DEFAULT 0 NOT NULL,
    "加工項目_圓孔8" smallint DEFAULT 0 NOT NULL,
    "加工項目_圓孔" varchar(2) DEFAULT ' ' NOT NULL,
    "加工項目_圓孔mm" smallint DEFAULT 0 NOT NULL,
    "加工項目_圓孔說明" varchar(40) DEFAULT ' ' NOT NULL,
    "加工項目_夾鍊mm" smallint DEFAULT 0 NOT NULL,
    "加工項目_夾鍊說明" varchar(40) DEFAULT ' ' NOT NULL,
    "加工項目_夾鍊_正面" smallint DEFAULT 0 NOT NULL,
    "加工項目_夾鍊_背面" smallint DEFAULT 0 NOT NULL,
    "加工項目_夾鍊代碼" varchar(20) DEFAULT ' ' NOT NULL,
    "加工項目_夾鍊mm二" smallint DEFAULT 0 NOT NULL,
    "加工項目_夾鍊說明二" varchar(40) DEFAULT ' ' NOT NULL,
    "加工項目_夾鍊_正面二" smallint DEFAULT 0 NOT NULL,
    "加工項目_夾鍊_背面二" smallint DEFAULT 0 NOT NULL,
    "加工項目_夾鍊代碼二" varchar(20) DEFAULT ' ' NOT NULL,
    "加工項目_K模" smallint DEFAULT 0 NOT NULL,
    "加工項目_K模說明" varchar(40) DEFAULT ' ' NOT NULL,
    "加工項目_提把" smallint DEFAULT 0 NOT NULL,
    "加工項目_提把說明" varchar(40) DEFAULT ' ' NOT NULL,
    "加工項目_墨西哥帽" smallint DEFAULT 0 NOT NULL,
    "加工項目_墨西哥帽mm" smallint DEFAULT 0 NOT NULL,
    "加工項目_墨西哥帽說明" varchar(40) DEFAULT ' ' NOT NULL,
    "加工項目_氣閥" smallint DEFAULT 0 NOT NULL,
    "加工項目_氣閥說明" varchar(40) DEFAULT ' ' NOT NULL,
    "加工項目_氣閥mm" smallint DEFAULT 0 NOT NULL,
    "加工項目_氣閥_正面" smallint DEFAULT 0 NOT NULL,
    "加工項目_氣閥_背面" smallint DEFAULT 0 NOT NULL,
    "加工項目_氣閥代碼" varchar(20) DEFAULT ' ' NOT NULL,
    "加工項目_圓角" varchar(1) DEFAULT ' ' NOT NULL,
    "加工項目_圓角說明" varchar(40) DEFAULT ' ' NOT NULL,
    "加工項目_蝴蝶孔" smallint DEFAULT 0 NOT NULL,
    "加工項目_蝴蝶孔mm" smallint DEFAULT 0 NOT NULL,
    "加工項目_蝴蝶孔說明" varchar(40) DEFAULT ' ' NOT NULL,
    "加工項目_鐵條" smallint DEFAULT 0 NOT NULL,
    "加工項目_鐵條說明" varchar(40) DEFAULT ' ' NOT NULL,
    "加工項目_鐵條mm" smallint DEFAULT 0 NOT NULL,
    "加工項目_鐵條_正面" smallint DEFAULT 0 NOT NULL,
    "加工項目_鐵條_背面" smallint DEFAULT 0 NOT NULL,
    "加工項目_鐵條代碼" varchar(20) DEFAULT ' ' NOT NULL,
    "加工項目_打角" smallint DEFAULT 0 NOT NULL,
    "加工項目_打角mm" smallint DEFAULT 0 NOT NULL,
    "加工項目_打角說明" varchar(40) DEFAULT ' ' NOT NULL,
    "成袋數" numeric(14,4) DEFAULT 0 NOT NULL,
    "成袋數正負差" varchar(1) DEFAULT '±' NOT NULL,
    "成袋差異比" numeric(4,1) DEFAULT 0 NOT NULL,
    "每束幾袋" integer DEFAULT 0 NOT NULL,
    "每箱幾袋" integer DEFAULT 0 NOT NULL,
    "紙箱代碼" varchar(20) DEFAULT ' ' NOT NULL,
    "每束幾袋_氣閥" integer DEFAULT 0 NOT NULL,
    "每箱幾袋_氣閥" integer DEFAULT 0 NOT NULL,
    "紙箱代碼_氣閥" varchar(20) DEFAULT ' ' NOT NULL,
    "封刀" varchar(1) DEFAULT ' ' NOT NULL,
    "開口處" varchar(1) DEFAULT ' ' NOT NULL,
    "封邊_上下" varchar(1) DEFAULT ' ' NOT NULL,
    "封邊_上下mm" smallint DEFAULT 0 NOT NULL,
    "封邊_上下mm二" smallint DEFAULT 0 NOT NULL,
    "封邊_背邊側" varchar(1) DEFAULT ' ' NOT NULL,
    "封邊_背邊側mm" smallint DEFAULT 0 NOT NULL,
    "封邊_背邊側mm二" smallint DEFAULT 0 NOT NULL,
    "封邊說明一" varchar(40) DEFAULT ' ' NOT NULL,
    "封邊說明二" varchar(40) DEFAULT ' ' NOT NULL,
    "撥夾鍵" varchar(1) DEFAULT ' ' NOT NULL,
    "送貨地址" varchar(100) DEFAULT ' ' NOT NULL,
    "底紙" smallint DEFAULT 0 NOT NULL,
    "報價材質" varchar(100) DEFAULT ' ' NOT NULL,
    "氣閥加工單價" numeric(14,4) DEFAULT 0.25 NOT NULL,
    "鐵條加工單價" numeric(14,4) DEFAULT 0.15 NOT NULL,
    "難易度" smallint NOT NULL,
    "包裝對應客戶標籤" smallint DEFAULT 0 NOT NULL,
    PRIMARY KEY ("製令單別", "製令單號")
);
CREATE UNIQUE INDEX "fil0032_02" ON "fil0032" ("前置單別", "前置單號", "製令單別", "製令單號");
COMMENT ON TABLE "fil0032" IS '0.產品條件主檔';
COMMENT ON COLUMN "fil0032"."製令單別" IS '製令單別(C11)';
COMMENT ON COLUMN "fil0032"."製令單號" IS '製令單號(C11)';
COMMENT ON COLUMN "fil0032"."前置單別" IS '前置單別(C11)';
COMMENT ON COLUMN "fil0032"."前置單號" IS '前置單號(C11)';
COMMENT ON COLUMN "fil0032"."訂購數量" IS '每捲長度';
COMMENT ON COLUMN "fil0032"."成品尺寸" IS '3D網址';
COMMENT ON COLUMN "fil0032"."用版規格_圓周" IS '用版規格：圓周mm';
COMMENT ON COLUMN "fil0032"."用版規格_版長" IS '用版規格：版長mm';
COMMENT ON COLUMN "fil0032"."印刷面_裡刷" IS '印刷面：裡刷';
COMMENT ON COLUMN "fil0032"."印刷面_表刷" IS '印刷面：表刷';
COMMENT ON COLUMN "fil0032"."印刷面_霧化" IS '印刷面：霧化';
COMMENT ON COLUMN "fil0032"."紙張_細面" IS '紙張：細面';
COMMENT ON COLUMN "fil0032"."紙張_粗面" IS '紙張：粗面';
COMMENT ON COLUMN "fil0032"."熟成_溫度起" IS '熟成：溫度起(度)';
COMMENT ON COLUMN "fil0032"."熟成_溫度迄" IS '熟成：溫度迄(度)';
COMMENT ON COLUMN "fil0032"."熟成_時間起" IS '熟成：時間起(小時)';
COMMENT ON COLUMN "fil0032"."熟成_時間迄" IS '熟成：時間迄(小時)';
COMMENT ON COLUMN "fil0032"."鋁箔貼合面_光面" IS '鋁箔貼合面：光面';
COMMENT ON COLUMN "fil0032"."鋁箔貼合面_霧面" IS '鋁箔貼合面：霧面';
COMMENT ON COLUMN "fil0032"."鋁箔貼合面_三合一" IS '鋁箔貼合面：三合一';
COMMENT ON COLUMN "fil0032"."鋁箔貼合面_四合一" IS '鋁箔貼合面：四合一';
COMMENT ON COLUMN "fil0032"."開窗尺寸1" IS '開窗尺寸1(mm)';
COMMENT ON COLUMN "fil0032"."開窗尺寸2" IS '開窗尺寸2(mm)';
COMMENT ON COLUMN "fil0032"."裁切規格_起" IS '裁切規格：起';
COMMENT ON COLUMN "fil0032"."裁切規格_迄" IS '裁切規格：迄';
COMMENT ON COLUMN "fil0032"."裁切規格_M" IS '裁切規格：M';
COMMENT ON COLUMN "fil0032"."側底紙_mm" IS '側／底紙mm';
COMMENT ON COLUMN "fil0032"."側底紙_M" IS '側／底紙：M';
COMMENT ON COLUMN "fil0032"."成捲數" IS '成捲數(捲)';
COMMENT ON COLUMN "fil0032"."加工項目_圓孔6" IS 'xx加工項目：圓孔6';
COMMENT ON COLUMN "fil0032"."加工項目_圓孔8" IS 'xx加工項目：圓孔8';
COMMENT ON COLUMN "fil0032"."加工項目_圓孔" IS '加工項目：圓孔6/8/10';
COMMENT ON COLUMN "fil0032"."加工項目_圓孔mm" IS '加工項目：圓孔mm';
COMMENT ON COLUMN "fil0032"."加工項目_圓孔說明" IS '加工項目：圓孔說明';
COMMENT ON COLUMN "fil0032"."加工項目_夾鍊mm" IS '加工項目：夾鍊mm';
COMMENT ON COLUMN "fil0032"."加工項目_夾鍊說明" IS '加工項目：夾鍊說明';
COMMENT ON COLUMN "fil0032"."加工項目_夾鍊_正面" IS '加工項目：夾鍊(正面)';
COMMENT ON COLUMN "fil0032"."加工項目_夾鍊_背面" IS '加工項目：夾鍊(背面)';
COMMENT ON COLUMN "fil0032"."加工項目_夾鍊代碼" IS '加工項目：夾鍊代碼';
COMMENT ON COLUMN "fil0032"."加工項目_夾鍊mm二" IS '加工項目：夾鍊mm二';
COMMENT ON COLUMN "fil0032"."加工項目_夾鍊說明二" IS '加工項目：夾鍊說明二';
COMMENT ON COLUMN "fil0032"."加工項目_夾鍊_正面二" IS '加工項目：夾鍊(正面)二';
COMMENT ON COLUMN "fil0032"."加工項目_夾鍊_背面二" IS '加工項目：夾鍊(背面)二';
COMMENT ON COLUMN "fil0032"."加工項目_夾鍊代碼二" IS '加工項目：夾鍊代碼二';
COMMENT ON COLUMN "fil0032"."加工項目_K模" IS '加工項目：K模';
COMMENT ON COLUMN "fil0032"."加工項目_K模說明" IS '加工項目：K模說明';
COMMENT ON COLUMN "fil0032"."加工項目_提把" IS '加工項目：提把';
COMMENT ON COLUMN "fil0032"."加工項目_提把說明" IS '加工項目：提把說明';
COMMENT ON COLUMN "fil0032"."加工項目_墨西哥帽" IS '加工項目：墨西哥帽';
COMMENT ON COLUMN "fil0032"."加工項目_墨西哥帽mm" IS '加工項目：墨西哥帽mm';
COMMENT ON COLUMN "fil0032"."加工項目_墨西哥帽說明" IS '加工項目：墨西哥帽說明';
COMMENT ON COLUMN "fil0032"."加工項目_氣閥" IS '加工項目：氣閥';
COMMENT ON COLUMN "fil0032"."加工項目_氣閥說明" IS '加工項目：氣閥說明';
COMMENT ON COLUMN "fil0032"."加工項目_氣閥mm" IS '加工項目：氣閥mm';
COMMENT ON COLUMN "fil0032"."加工項目_氣閥_正面" IS '加工項目：氣閥(正面)';
COMMENT ON COLUMN "fil0032"."加工項目_氣閥_背面" IS '加工項目：氣閥(背面)';
COMMENT ON COLUMN "fil0032"."加工項目_氣閥代碼" IS '加工項目：氣閥代碼';
COMMENT ON COLUMN "fil0032"."加工項目_圓角" IS '加工項目：圓角';
COMMENT ON COLUMN "fil0032"."加工項目_圓角說明" IS '加工項目：圓角說明';
COMMENT ON COLUMN "fil0032"."加工項目_蝴蝶孔" IS '加工項目：蝴蝶孔';
COMMENT ON COLUMN "fil0032"."加工項目_蝴蝶孔mm" IS '加工項目：蝴蝶孔mm';
COMMENT ON COLUMN "fil0032"."加工項目_蝴蝶孔說明" IS '加工項目：蝴蝶孔說明';
COMMENT ON COLUMN "fil0032"."加工項目_鐵條" IS '加工項目：鐵條';
COMMENT ON COLUMN "fil0032"."加工項目_鐵條說明" IS '加工項目：鐵條說明';
COMMENT ON COLUMN "fil0032"."加工項目_鐵條mm" IS '加工項目：鐵條mm';
COMMENT ON COLUMN "fil0032"."加工項目_鐵條_正面" IS '加工項目：鐵條(正面)';
COMMENT ON COLUMN "fil0032"."加工項目_鐵條_背面" IS '加工項目：鐵條(背面)';
COMMENT ON COLUMN "fil0032"."加工項目_鐵條代碼" IS '加工項目：鐵條代碼';
COMMENT ON COLUMN "fil0032"."加工項目_打角" IS '加工項目：打角';
COMMENT ON COLUMN "fil0032"."加工項目_打角mm" IS '加工項目：打角mm';
COMMENT ON COLUMN "fil0032"."加工項目_打角說明" IS '加工項目：打角說明';
COMMENT ON COLUMN "fil0032"."每束幾袋" IS '每束幾袋_無氣閥';
COMMENT ON COLUMN "fil0032"."每箱幾袋" IS '每箱幾袋_無氣閥';
COMMENT ON COLUMN "fil0032"."紙箱代碼" IS '紙箱代碼_無氣閥';
COMMENT ON COLUMN "fil0032"."封邊_上下" IS '封邊：上下';
COMMENT ON COLUMN "fil0032"."封邊_上下mm" IS '封邊：上下mm';
COMMENT ON COLUMN "fil0032"."封邊_上下mm二" IS '封邊：上下mm二';
COMMENT ON COLUMN "fil0032"."封邊_背邊側" IS '封邊：背邊側';
COMMENT ON COLUMN "fil0032"."封邊_背邊側mm" IS '封邊：背邊測mm';
COMMENT ON COLUMN "fil0032"."封邊_背邊側mm二" IS '封邊：背邊測mm二';

-- Files：0.產品條件副檔一
CREATE TABLE "fil0033" (
    "製令單別" varchar(10) DEFAULT ' ' NOT NULL,
    "製令單號" varchar(20) DEFAULT ' ' NOT NULL,
    "加工別" varchar(1) DEFAULT 'A' NOT NULL,
    "用版規格_圓周" smallint DEFAULT 0 NOT NULL,
    "用版規格_版長" smallint DEFAULT 0 NOT NULL,
    "印刷面_裡刷" smallint DEFAULT 0 NOT NULL,
    "印刷面_表刷" smallint DEFAULT 0 NOT NULL,
    "印刷面_霧化" smallint DEFAULT 0 NOT NULL,
    "印刷米數" numeric(4,1) DEFAULT 0 NOT NULL,
    "印刷單位" varchar(10) DEFAULT ' ' NOT NULL,
    "印刷基材" varchar(20) DEFAULT ' ' NOT NULL,
    "印刷色順一" varchar(20) DEFAULT ' ' NOT NULL,
    "印刷色順二" varchar(20) DEFAULT ' ' NOT NULL,
    "印刷色順三" varchar(20) DEFAULT ' ' NOT NULL,
    "印刷色順四" varchar(20) DEFAULT ' ' NOT NULL,
    "印刷色順五" varchar(20) DEFAULT ' ' NOT NULL,
    "印刷色順六" varchar(20) DEFAULT ' ' NOT NULL,
    "印刷色順七" varchar(20) DEFAULT ' ' NOT NULL,
    "印刷色順八" varchar(20) DEFAULT ' ' NOT NULL,
    "印刷色順九" varchar(20) DEFAULT ' ' NOT NULL,
    "印刷色順十" varchar(20) DEFAULT ' ' NOT NULL,
    "印刷色順十一" varchar(20) DEFAULT ' ' NOT NULL,
    "印刷色順十二" varchar(20) DEFAULT ' ' NOT NULL,
    "看色人員_客戶員工" varchar(1) DEFAULT ' ' NOT NULL,
    "看色人員編號" varchar(10) DEFAULT ' ' NOT NULL,
    "紙張_細面" smallint DEFAULT 0 NOT NULL,
    "紙張_粗面" smallint DEFAULT 0 NOT NULL,
    "油墨種類" varchar(10) DEFAULT ' ' NOT NULL,
    "熟成_溫度起" smallint DEFAULT 0 NOT NULL,
    "熟成_溫度迄" smallint DEFAULT 0 NOT NULL,
    "熟成_時間起" smallint DEFAULT 0 NOT NULL,
    "熟成_時間迄" smallint DEFAULT 0 NOT NULL,
    "鋁箔貼合面_光面" smallint DEFAULT 0 NOT NULL,
    "鋁箔貼合面_霧面" smallint DEFAULT 0 NOT NULL,
    "鋁箔貼合面_待確認人" varchar(10) DEFAULT ' ' NOT NULL,
    "鋁箔貼合面_三合一" smallint DEFAULT 0 NOT NULL,
    "鋁箔貼合面_四合一" smallint DEFAULT 0 NOT NULL,
    "開窗尺寸1" numeric(4,1) DEFAULT 0 NOT NULL,
    "開窗尺寸2" numeric(4,1) DEFAULT 0 NOT NULL,
    "位於" varchar(100) DEFAULT ' ' NOT NULL,
    "裁切規格_起" numeric(5,1) DEFAULT 0 NOT NULL,
    "裁切規格_迄" numeric(5,1) DEFAULT 0 NOT NULL,
    "裁切規格_M" smallint DEFAULT 0 NOT NULL,
    "裁切米數說明" varchar(40) DEFAULT ' ' NOT NULL,
    "條數" smallint DEFAULT 0 NOT NULL,
    "裁切條數說明" varchar(40) DEFAULT ' ' NOT NULL,
    "側底紙mm" smallint DEFAULT 0 NOT NULL,
    "側底紙_M" smallint DEFAULT 0 NOT NULL,
    "成捲數" smallint DEFAULT 0 NOT NULL,
    "成捲數正負差" varchar(1) DEFAULT '±' NOT NULL,
    "成捲差異比" numeric(4,1) DEFAULT 0 NOT NULL,
    "每箱幾捲" smallint DEFAULT 0 NOT NULL,
    "裁切方向" varchar(1) DEFAULT ' ' NOT NULL,
    "灑粉" smallint DEFAULT 0 NOT NULL,
    "灑粉說明" varchar(40) DEFAULT ' ' NOT NULL,
    "壓紋" varchar(10) DEFAULT ' ' NOT NULL,
    "壓紋說明" varchar(40) DEFAULT ' ' NOT NULL,
    "開窗尺寸21" numeric(4,1) DEFAULT 0 NOT NULL,
    "開窗尺寸22" numeric(4,1) DEFAULT 0 NOT NULL,
    "位於2" varchar(100) DEFAULT ' ' NOT NULL,
    "上臘" smallint DEFAULT 0 NOT NULL,
    "上臘材料編號" varchar(20) DEFAULT ' ' NOT NULL,
    "幾目" integer DEFAULT 0 NOT NULL,
    "基材投入製程" varchar(10) DEFAULT ' ' NOT NULL,
    "基材投入說明" varchar(40) DEFAULT ' ' NOT NULL,
    "共版" smallint DEFAULT 0 NOT NULL,
    "共版產品編號" varchar(20) DEFAULT ' ' NOT NULL,
    "展開尺寸1" numeric(6,2) DEFAULT 0 NOT NULL,
    "展開尺寸2" numeric(6,2) DEFAULT 0 NOT NULL,
    "紙箱代碼" varchar(20) DEFAULT ' ' NOT NULL,
    "厚度1" smallint DEFAULT 0 NOT NULL,
    "厚度2" smallint DEFAULT 0 NOT NULL,
    "包裝一箱幾捲" smallint DEFAULT 0 NOT NULL,
    "內標籤幾份" smallint DEFAULT 0 NOT NULL,
    "製袋最後箱號" integer DEFAULT 0 NOT NULL,
    "數位印刷" smallint DEFAULT 0 NOT NULL,
    "印製後裁修" smallint DEFAULT 0 NOT NULL,
    "鋁箔貼合面_三合一上" smallint DEFAULT 0 NOT NULL,
    "裁修條件" varchar(10) DEFAULT ' ' NOT NULL,
    PRIMARY KEY ("製令單別", "製令單號", "加工別")
);
COMMENT ON TABLE "fil0033" IS '0.產品條件副檔一';
COMMENT ON COLUMN "fil0033"."製令單別" IS '製令單別(C11)';
COMMENT ON COLUMN "fil0033"."製令單號" IS '製令單號(C11)';
COMMENT ON COLUMN "fil0033"."用版規格_圓周" IS '用版規格：圓周mm';
COMMENT ON COLUMN "fil0033"."用版規格_版長" IS '用版規格：版長mm';
COMMENT ON COLUMN "fil0033"."印刷面_裡刷" IS '印刷面：裡刷';
COMMENT ON COLUMN "fil0033"."印刷面_表刷" IS '印刷面：表刷';
COMMENT ON COLUMN "fil0033"."印刷面_霧化" IS '印刷面：霧化';
COMMENT ON COLUMN "fil0033"."紙張_細面" IS '紙張：細面';
COMMENT ON COLUMN "fil0033"."紙張_粗面" IS '紙張：粗面';
COMMENT ON COLUMN "fil0033"."熟成_溫度起" IS '熟成：溫度起(度)';
COMMENT ON COLUMN "fil0033"."熟成_溫度迄" IS '熟成：溫度迄(度)';
COMMENT ON COLUMN "fil0033"."熟成_時間起" IS '熟成：時間起(小時)';
COMMENT ON COLUMN "fil0033"."熟成_時間迄" IS '熟成：時間迄(小時)';
COMMENT ON COLUMN "fil0033"."鋁箔貼合面_光面" IS '鋁箔貼合面：光面';
COMMENT ON COLUMN "fil0033"."鋁箔貼合面_霧面" IS '鋁箔貼合面：霧面';
COMMENT ON COLUMN "fil0033"."鋁箔貼合面_待確認人" IS '鋁箔貼合面：待確認人';
COMMENT ON COLUMN "fil0033"."鋁箔貼合面_三合一" IS '鋁箔貼合面：三合一平';
COMMENT ON COLUMN "fil0033"."鋁箔貼合面_四合一" IS '鋁箔貼合面：四合一';
COMMENT ON COLUMN "fil0033"."開窗尺寸1" IS '開窗尺寸1(mm)';
COMMENT ON COLUMN "fil0033"."開窗尺寸2" IS '開窗尺寸2(mm)';
COMMENT ON COLUMN "fil0033"."位於" IS '位於1';
COMMENT ON COLUMN "fil0033"."裁切規格_起" IS '裁切規格：起';
COMMENT ON COLUMN "fil0033"."裁切規格_迄" IS '裁切規格：迄';
COMMENT ON COLUMN "fil0033"."裁切規格_M" IS '裁切規格：M';
COMMENT ON COLUMN "fil0033"."側底紙mm" IS '側／底紙mm';
COMMENT ON COLUMN "fil0033"."側底紙_M" IS '側／底紙:M';
COMMENT ON COLUMN "fil0033"."成捲數" IS '成捲數(捲)';
COMMENT ON COLUMN "fil0033"."開窗尺寸21" IS '開窗尺寸21(mm)';
COMMENT ON COLUMN "fil0033"."開窗尺寸22" IS '開窗尺寸22(mm)';
COMMENT ON COLUMN "fil0033"."鋁箔貼合面_三合一上" IS '鋁箔貼合面：三合一上';

-- Files：0.製袋箱號
CREATE TABLE "fil0033a" (
    "製令單別" varchar(10) DEFAULT ' ' NOT NULL,
    "製令單號" varchar(20) DEFAULT ' ' NOT NULL,
    "製袋箱號" integer DEFAULT 0 NOT NULL,
    "來源單別" varchar(10) DEFAULT ' ' NOT NULL,
    "來源單號" varchar(20) DEFAULT ' ' NOT NULL,
    "來源序號" integer DEFAULT 0 NOT NULL,
    PRIMARY KEY ("製令單別", "製令單號", "製袋箱號")
);
COMMENT ON TABLE "fil0033a" IS '0.製袋箱號';
COMMENT ON COLUMN "fil0033a"."製令單別" IS '製令單別(C11)';
COMMENT ON COLUMN "fil0033a"."製令單號" IS '製令單號(C11)';

-- Files：0.成捲箱號
CREATE TABLE "fil0033b" (
    "製令單別" varchar(10) DEFAULT ' ' NOT NULL,
    "製令單號" varchar(20) DEFAULT ' ' NOT NULL,
    "成捲箱號" integer DEFAULT 0 NOT NULL,
    "來源單別" varchar(10) DEFAULT ' ' NOT NULL,
    "來源單號" varchar(20) DEFAULT ' ' NOT NULL,
    "來源序號" integer DEFAULT 0 NOT NULL,
    PRIMARY KEY ("製令單別", "製令單號", "成捲箱號")
);
COMMENT ON TABLE "fil0033b" IS '0.成捲箱號';
COMMENT ON COLUMN "fil0033b"."製令單別" IS '製令單別(C11)';
COMMENT ON COLUMN "fil0033b"."製令單號" IS '製令單號(C11)';

-- Files：0.產品條件製程檔
CREATE TABLE "fil0033c" (
    "單據類別" varchar(10) DEFAULT ' ' NOT NULL,
    "單據編號" varchar(20) DEFAULT ' ' NOT NULL,
    "c31a" smallint DEFAULT 0 NOT NULL,
    "c31b" smallint DEFAULT 0 NOT NULL,
    "c31c" smallint DEFAULT 0 NOT NULL,
    "c31d" smallint DEFAULT 0 NOT NULL,
    "c31e" smallint DEFAULT 0 NOT NULL,
    "c31f" smallint DEFAULT 0 NOT NULL,
    "c31g" smallint DEFAULT 0 NOT NULL,
    "c31h" smallint DEFAULT 0 NOT NULL,
    "c31i" smallint DEFAULT 0 NOT NULL,
    "c31k" smallint DEFAULT 0 NOT NULL,
    "c32d" smallint DEFAULT 0 NOT NULL,
    "c32e" smallint DEFAULT 0 NOT NULL,
    PRIMARY KEY ("單據類別", "單據編號")
);
COMMENT ON TABLE "fil0033c" IS '0.產品條件製程檔';
COMMENT ON COLUMN "fil0033c"."單據類別" IS '製令單別(C11)';
COMMENT ON COLUMN "fil0033c"."單據編號" IS '製令單號(C11)';
COMMENT ON COLUMN "fil0033c"."c31a" IS 'C31A.印刷';
COMMENT ON COLUMN "fil0033c"."c31b" IS 'C31B.淋膜';
COMMENT ON COLUMN "fil0033c"."c31c" IS 'C31C.積層';
COMMENT ON COLUMN "fil0033c"."c31d" IS 'C31D.裁切';
COMMENT ON COLUMN "fil0033c"."c31e" IS 'C31E.製袋';
COMMENT ON COLUMN "fil0033c"."c31f" IS 'C31F.氣閥';
COMMENT ON COLUMN "fil0033c"."c31g" IS 'C31G.鐵條';
COMMENT ON COLUMN "fil0033c"."c31h" IS 'C31H.印刷檢品';
COMMENT ON COLUMN "fil0033c"."c31i" IS 'C31I.成捲包裝';
COMMENT ON COLUMN "fil0033c"."c31k" IS 'C31K.裁切檢品';
COMMENT ON COLUMN "fil0033c"."c32d" IS 'C32D上臘';
COMMENT ON COLUMN "fil0033c"."c32e" IS 'C32E版銅';

-- Files：0.產品條件材料
CREATE TABLE "fil0034" (
    "製令單別" varchar(10) DEFAULT ' ' NOT NULL,
    "製令單號" varchar(20) DEFAULT ' ' NOT NULL,
    "加工類別" varchar(1) DEFAULT ' ' NOT NULL,
    "材料序號" numeric(10,0) DEFAULT 0 NOT NULL,
    "材料代碼" varchar(20) DEFAULT ' ' NOT NULL,
    "組合材質結構" smallint DEFAULT 0 NOT NULL,
    "熟成_溫度區間" varchar(10) DEFAULT ' ' NOT NULL,
    "熟成_時間區間" varchar(10) DEFAULT ' ' NOT NULL,
    "膠水材料代碼" varchar(20) DEFAULT ' ' NOT NULL,
    "膠水材料代碼2" varchar(20) DEFAULT ' ' NOT NULL,
    "塑膠粒材料代碼" varchar(20) DEFAULT ' ' NOT NULL,
    "排在基材前面" smallint DEFAULT 0 NOT NULL,
    "排在材料前面" smallint DEFAULT 0 NOT NULL,
    "厚度" varchar(10) DEFAULT ' ' NOT NULL,
    "材料說明" varchar(40) DEFAULT ' ' NOT NULL,
    "膠水說明" varchar(40) DEFAULT ' ' NOT NULL,
    "塑膠粒說明" varchar(40) DEFAULT ' ' NOT NULL,
    "版目" integer DEFAULT 0 NOT NULL,
    "冷鏈_溫度區間" varchar(10) DEFAULT ' ' NOT NULL,
    "冷鏈_時間區間" varchar(10) DEFAULT ' ' NOT NULL,
    PRIMARY KEY ("製令單別", "製令單號", "加工類別", "材料序號")
);
COMMENT ON TABLE "fil0034" IS '0.產品條件材料';
COMMENT ON COLUMN "fil0034"."製令單別" IS '製令單別(C11)';
COMMENT ON COLUMN "fil0034"."製令單號" IS '製令單號(C11)';
COMMENT ON COLUMN "fil0034"."熟成_溫度區間" IS '熟成：溫度區間';
COMMENT ON COLUMN "fil0034"."熟成_時間區間" IS '熟成：時間區間';
COMMENT ON COLUMN "fil0034"."冷鏈_溫度區間" IS '冷鏈：溫度區間';
COMMENT ON COLUMN "fil0034"."冷鏈_時間區間" IS '冷鏈：時間區間';

-- Files：0.產品條件變更
CREATE TABLE "fil0035" (
    "單別" varchar(10) DEFAULT ' ' NOT NULL,
    "單號" varchar(20) DEFAULT ' ' NOT NULL,
    "變更別_材料變更" smallint DEFAULT 0 NOT NULL,
    "變更別_廠商" varchar(10) DEFAULT ' ' NOT NULL,
    "變更別_規格變更" smallint DEFAULT 0 NOT NULL,
    "變更別_其他變更" smallint DEFAULT 0 NOT NULL,
    "變更別_製程變更" smallint DEFAULT 0 NOT NULL,
    "變更別_單位_製程" varchar(10) DEFAULT ' ' NOT NULL,
    "變更別_交期變更" smallint DEFAULT 0 NOT NULL,
    "變更別_單位_交期" varchar(10) DEFAULT ' ' NOT NULL,
    "變更事項" varchar(100) DEFAULT ' ' NOT NULL,
    "變更原因" varchar(1000) DEFAULT ' ' NOT NULL,
    "主管意見" varchar(1000) DEFAULT ' ' NOT NULL,
    "主管批示" varchar(1000) DEFAULT ' ' NOT NULL,
    "知會單位_營業課" varchar(10) DEFAULT ' ' NOT NULL,
    "知會單位_印刷課" varchar(10) DEFAULT ' ' NOT NULL,
    "知會單位_加工課" varchar(10) DEFAULT ' ' NOT NULL,
    "知會單位_會計課" varchar(10) DEFAULT ' ' NOT NULL,
    "知會單位_總務課" varchar(10) DEFAULT ' ' NOT NULL,
    "知會單位_積層課" varchar(10) DEFAULT ' ' NOT NULL,
    "知會單位_製袋課" varchar(10) DEFAULT ' ' NOT NULL,
    "知會單位_廠務課" varchar(10) DEFAULT ' ' NOT NULL,
    "知會單位_其他單位" varchar(10) DEFAULT ' ' NOT NULL,
    "知會單位_營業課_承辦人" varchar(10) DEFAULT ' ' NOT NULL,
    "知會單位_印刷課_承辦人" varchar(10) DEFAULT ' ' NOT NULL,
    "知會單位_加工課_承辦人" varchar(10) DEFAULT ' ' NOT NULL,
    "知會單位_會計課_承辦人" varchar(10) DEFAULT ' ' NOT NULL,
    "知會單位_總務課_承辦人" varchar(10) DEFAULT ' ' NOT NULL,
    "知會單位_積層課_承辦人" varchar(10) DEFAULT ' ' NOT NULL,
    "知會單位_製袋課_承辦人" varchar(10) DEFAULT ' ' NOT NULL,
    "知會單位_廠務課_承辦人" varchar(10) DEFAULT ' ' NOT NULL,
    "知會單位_其他單位_承辦人" varchar(10) DEFAULT ' ' NOT NULL,
    "確認_營業課" smallint DEFAULT 0 NOT NULL,
    "確認_印刷課" smallint DEFAULT 0 NOT NULL,
    "確認_加工課" smallint DEFAULT 0 NOT NULL,
    "確認_會計課" smallint DEFAULT 0 NOT NULL,
    "確認_總務課" smallint DEFAULT 0 NOT NULL,
    "確認_積層課" smallint DEFAULT 0 NOT NULL,
    "確認_製袋課" smallint DEFAULT 0 NOT NULL,
    "確認_廠務課" smallint DEFAULT 0 NOT NULL,
    "確認_其他單位" smallint DEFAULT 0 NOT NULL,
    "確認_營業課_承辦人" varchar(10) DEFAULT ' ' NOT NULL,
    "確認_印刷課_承辦人" varchar(10) DEFAULT ' ' NOT NULL,
    "確認_加工課_承辦人" varchar(10) DEFAULT ' ' NOT NULL,
    "確認_會計課_承辦人" varchar(10) DEFAULT ' ' NOT NULL,
    "確認_總務課_承辦人" varchar(10) DEFAULT ' ' NOT NULL,
    "確認_積層課_承辦人" varchar(10) DEFAULT ' ' NOT NULL,
    "確認_製袋課_承辦人" varchar(10) DEFAULT ' ' NOT NULL,
    "確認_廠務課_承辦人" varchar(10) DEFAULT ' ' NOT NULL,
    "確認_其他單位_承辦人" varchar(10) DEFAULT ' ' NOT NULL,
    PRIMARY KEY ("單別", "單號")
);
COMMENT ON TABLE "fil0035" IS '0.產品條件變更';
COMMENT ON COLUMN "fil0035"."單別" IS '單別(C21)';
COMMENT ON COLUMN "fil0035"."單號" IS '單號(C21)';
COMMENT ON COLUMN "fil0035"."變更別_材料變更" IS '變更別：材料變更';
COMMENT ON COLUMN "fil0035"."變更別_廠商" IS '變更別：廠商';
COMMENT ON COLUMN "fil0035"."變更別_規格變更" IS '變更別：規格變更';
COMMENT ON COLUMN "fil0035"."變更別_其他變更" IS '變更別：其他變更';
COMMENT ON COLUMN "fil0035"."變更別_製程變更" IS '變更別：製程變更';
COMMENT ON COLUMN "fil0035"."變更別_單位_製程" IS '變更別：單位(製程)';
COMMENT ON COLUMN "fil0035"."變更別_交期變更" IS '變更別：交期變更';
COMMENT ON COLUMN "fil0035"."變更別_單位_交期" IS '變更別：單位(交期)';
COMMENT ON COLUMN "fil0035"."知會單位_營業課" IS '知會單位：營業課';
COMMENT ON COLUMN "fil0035"."知會單位_印刷課" IS '知會單位：印刷課';
COMMENT ON COLUMN "fil0035"."知會單位_加工課" IS '知會單位：加工課';
COMMENT ON COLUMN "fil0035"."知會單位_會計課" IS '知會單位：會計課';
COMMENT ON COLUMN "fil0035"."知會單位_總務課" IS '知會單位：總務課';
COMMENT ON COLUMN "fil0035"."知會單位_積層課" IS '知會單位：積層課';
COMMENT ON COLUMN "fil0035"."知會單位_製袋課" IS '知會單位：製袋課';
COMMENT ON COLUMN "fil0035"."知會單位_廠務課" IS '知會單位：廠務課';
COMMENT ON COLUMN "fil0035"."知會單位_其他單位" IS '知會單位：其他單位';
COMMENT ON COLUMN "fil0035"."知會單位_營業課_承辦人" IS '知會單位：營業課(承辦人)';
COMMENT ON COLUMN "fil0035"."知會單位_印刷課_承辦人" IS '知會單位：印刷課(承辦人)';
COMMENT ON COLUMN "fil0035"."知會單位_加工課_承辦人" IS '知會單位：加工課(承辦人)';
COMMENT ON COLUMN "fil0035"."知會單位_會計課_承辦人" IS '知會單位：會計課(承辦人)';
COMMENT ON COLUMN "fil0035"."知會單位_總務課_承辦人" IS '知會單位：總務課(承辦人)';
COMMENT ON COLUMN "fil0035"."知會單位_積層課_承辦人" IS '知會單位：積層課(承辦人)';
COMMENT ON COLUMN "fil0035"."知會單位_製袋課_承辦人" IS '知會單位：製袋課(承辦人)';
COMMENT ON COLUMN "fil0035"."知會單位_廠務課_承辦人" IS '知會單位：廠務課(承辦人)';
COMMENT ON COLUMN "fil0035"."知會單位_其他單位_承辦人" IS '知會單位：其他單位(承辦人)';
COMMENT ON COLUMN "fil0035"."確認_營業課" IS '確認：營業課';
COMMENT ON COLUMN "fil0035"."確認_印刷課" IS '確認：印刷課';
COMMENT ON COLUMN "fil0035"."確認_加工課" IS '確認：加工課';
COMMENT ON COLUMN "fil0035"."確認_會計課" IS '確認：會計課';
COMMENT ON COLUMN "fil0035"."確認_總務課" IS '確認：總務課';
COMMENT ON COLUMN "fil0035"."確認_積層課" IS '確認：積層課';
COMMENT ON COLUMN "fil0035"."確認_製袋課" IS '確認：製袋課';
COMMENT ON COLUMN "fil0035"."確認_廠務課" IS '確認：廠務課';
COMMENT ON COLUMN "fil0035"."確認_其他單位" IS '確認：其他單位';
COMMENT ON COLUMN "fil0035"."確認_營業課_承辦人" IS '確認：營業課(承辦人)';
COMMENT ON COLUMN "fil0035"."確認_印刷課_承辦人" IS '確認：印刷課(承辦人)';
COMMENT ON COLUMN "fil0035"."確認_加工課_承辦人" IS '確認：加工課(承辦人)';
COMMENT ON COLUMN "fil0035"."確認_會計課_承辦人" IS '確認：會計課(承辦人)';
COMMENT ON COLUMN "fil0035"."確認_總務課_承辦人" IS '確認：總務課(承辦人)';
COMMENT ON COLUMN "fil0035"."確認_積層課_承辦人" IS '確認：積層課(承辦人)';
COMMENT ON COLUMN "fil0035"."確認_製袋課_承辦人" IS '確認：製袋課(承辦人)';
COMMENT ON COLUMN "fil0035"."確認_廠務課_承辦人" IS '確認：廠務課(承辦人)';
COMMENT ON COLUMN "fil0035"."確認_其他單位_承辦人" IS '確認：其他單位(承辦人)';

-- Files：0.製稿工作指示
CREATE TABLE "fil0036" (
    "單別" varchar(10) DEFAULT ' ' NOT NULL,
    "單號" varchar(20) DEFAULT ' ' NOT NULL,
    "指示單別" varchar(1) DEFAULT 0 NOT NULL,
    "接稿日期" char(8) DEFAULT '00000000' NOT NULL,
    "發版日期" char(8) DEFAULT '00000000' NOT NULL,
    "設計製稿" varchar(10) DEFAULT ' ' NOT NULL,
    "客戶說明" varchar(100) DEFAULT ' ' NOT NULL,
    "產品說明" varchar(100) DEFAULT ' ' NOT NULL,
    "製稿規格_成品H" smallint DEFAULT 0 NOT NULL,
    "製稿規格_成品W" smallint DEFAULT 0 NOT NULL,
    "製稿規格_成品G" smallint DEFAULT 0 NOT NULL,
    "製稿規格_成品A" smallint DEFAULT 0 NOT NULL,
    "製稿規格_成品B" smallint DEFAULT 0 NOT NULL,
    "表刷" smallint DEFAULT 0 NOT NULL,
    "裡刷" smallint DEFAULT 0 NOT NULL,
    "附色樣" smallint DEFAULT 0 NOT NULL,
    "共幾色" smallint DEFAULT 0 NOT NULL,
    "顏色1" varchar(10) DEFAULT ' ' NOT NULL,
    "顏色2" varchar(10) DEFAULT ' ' NOT NULL,
    "顏色3" varchar(10) DEFAULT ' ' NOT NULL,
    "顏色4" varchar(10) DEFAULT ' ' NOT NULL,
    "顏色5" varchar(10) DEFAULT ' ' NOT NULL,
    "顏色6" varchar(10) DEFAULT ' ' NOT NULL,
    "顏色7" varchar(10) DEFAULT ' ' NOT NULL,
    "顏色8" varchar(10) DEFAULT ' ' NOT NULL,
    "顏色9" varchar(10) DEFAULT ' ' NOT NULL,
    "顏色10" varchar(10) DEFAULT ' ' NOT NULL,
    "改支數" smallint DEFAULT 0 NOT NULL,
    "共版支數" smallint DEFAULT 0 NOT NULL,
    "白滿版" smallint DEFAULT 0 NOT NULL,
    "連續版" smallint DEFAULT 0 NOT NULL,
    "圖案頭出" smallint DEFAULT 0 NOT NULL,
    "圖案尾出" smallint DEFAULT 0 NOT NULL,
    "電眼尺寸" varchar(40) DEFAULT ' ' NOT NULL,
    "電眼尺寸_單邊" smallint DEFAULT 0 NOT NULL,
    "電眼尺寸_雙邊" smallint DEFAULT 0 NOT NULL,
    "電眼尺寸_四邊" smallint DEFAULT 0 NOT NULL,
    "電眼尺寸_其他" smallint DEFAULT 0 NOT NULL,
    "袋型" varchar(40) DEFAULT ' ' NOT NULL,
    "打角" smallint DEFAULT 0 NOT NULL,
    "夾縫" smallint DEFAULT 0 NOT NULL,
    "打孔" smallint DEFAULT 0 NOT NULL,
    "其他" varchar(40) DEFAULT ' ' NOT NULL,
    "正" smallint DEFAULT 0 NOT NULL,
    "底" smallint DEFAULT 0 NOT NULL,
    "寬" smallint DEFAULT 0 NOT NULL,
    "高" smallint DEFAULT 0 NOT NULL,
    "開口_上" smallint DEFAULT 0 NOT NULL,
    "開口_下" smallint DEFAULT 0 NOT NULL,
    "開口_左" smallint DEFAULT 0 NOT NULL,
    "開口_右" smallint DEFAULT 0 NOT NULL,
    "背封" smallint DEFAULT 0 NOT NULL,
    "邊封" smallint DEFAULT 0 NOT NULL,
    "seal" smallint DEFAULT 0 NOT NULL,
    "上封" smallint DEFAULT 0 NOT NULL,
    "下封" smallint DEFAULT 0 NOT NULL,
    "pitch" smallint DEFAULT 0 NOT NULL,
    "上底" smallint DEFAULT 0 NOT NULL,
    "下底" smallint DEFAULT 0 NOT NULL,
    "以下為備註事項" varchar(1) DEFAULT ' ' NOT NULL,
    "頭出左" smallint DEFAULT 0 NOT NULL,
    "頭出右" smallint DEFAULT 0 NOT NULL,
    "尾出左" smallint DEFAULT 0 NOT NULL,
    "尾出右" smallint DEFAULT 0 NOT NULL,
    "合版方式" smallint DEFAULT 0 NOT NULL,
    "合版方式說明" varchar(100) DEFAULT ' ' NOT NULL,
    "拼法參照" smallint DEFAULT 0 NOT NULL,
    "拼法參照說明" varchar(100) DEFAULT ' ' NOT NULL,
    "可參照" varchar(40) DEFAULT ' ' NOT NULL,
    "共版支" smallint DEFAULT 0 NOT NULL,
    "共版色1" varchar(20) DEFAULT ' ' NOT NULL,
    "共版色說明1" varchar(30) DEFAULT ' ' NOT NULL,
    "共版色2" varchar(20) DEFAULT ' ' NOT NULL,
    "共版色說明2" varchar(30) DEFAULT ' ' NOT NULL,
    "客戶指示" varchar(1) DEFAULT ' ' NOT NULL,
    "材質結構1" varchar(20) DEFAULT ' ' NOT NULL,
    "材質結構2" varchar(20) DEFAULT ' ' NOT NULL,
    "材質結構3" varchar(20) DEFAULT ' ' NOT NULL,
    PRIMARY KEY ("單別", "單號")
);
COMMENT ON TABLE "fil0036" IS '0.製稿工作指示';
COMMENT ON COLUMN "fil0036"."單別" IS '單別(B21)';
COMMENT ON COLUMN "fil0036"."單號" IS '單號(B21)';
COMMENT ON COLUMN "fil0036"."製稿規格_成品H" IS '製稿規格(成品)H';
COMMENT ON COLUMN "fil0036"."製稿規格_成品W" IS '製稿規格(成品)W';
COMMENT ON COLUMN "fil0036"."製稿規格_成品G" IS '製稿規格(成品)G';
COMMENT ON COLUMN "fil0036"."製稿規格_成品A" IS '製稿規格(展開)A';
COMMENT ON COLUMN "fil0036"."製稿規格_成品B" IS '製稿規格(展開)B';
COMMENT ON COLUMN "fil0036"."共幾色" IS '共幾色?';
COMMENT ON COLUMN "fil0036"."改支數" IS '改支數?';
COMMENT ON COLUMN "fil0036"."共版支數" IS '共版支數?';
COMMENT ON COLUMN "fil0036"."電眼尺寸_單邊" IS '電眼尺寸：單邊';
COMMENT ON COLUMN "fil0036"."電眼尺寸_雙邊" IS '電眼尺寸：雙邊';
COMMENT ON COLUMN "fil0036"."電眼尺寸_四邊" IS '電眼尺寸：四邊';
COMMENT ON COLUMN "fil0036"."電眼尺寸_其他" IS '電眼尺寸：其他';
COMMENT ON COLUMN "fil0036"."打角" IS '打角(mm)';
COMMENT ON COLUMN "fil0036"."夾縫" IS '夾縫(mm)';
COMMENT ON COLUMN "fil0036"."打孔" IS '打孔(mm)';
COMMENT ON COLUMN "fil0036"."正" IS '正(mm)';
COMMENT ON COLUMN "fil0036"."底" IS '底(mm)';
COMMENT ON COLUMN "fil0036"."寬" IS '寬(mm)';
COMMENT ON COLUMN "fil0036"."高" IS '高(mm)';
COMMENT ON COLUMN "fil0036"."開口_上" IS '開口：上';
COMMENT ON COLUMN "fil0036"."開口_下" IS '開口：下';
COMMENT ON COLUMN "fil0036"."開口_左" IS '開口：左';
COMMENT ON COLUMN "fil0036"."開口_右" IS '開口：右';
COMMENT ON COLUMN "fil0036"."seal" IS 'Seal(mm)';
COMMENT ON COLUMN "fil0036"."上封" IS '上封(mm)';
COMMENT ON COLUMN "fil0036"."下封" IS '下封(mm)';
COMMENT ON COLUMN "fil0036"."pitch" IS 'Pitch(mm)';
COMMENT ON COLUMN "fil0036"."上底" IS '上底(mm)';
COMMENT ON COLUMN "fil0036"."下底" IS '下底(mm)';
COMMENT ON COLUMN "fil0036"."以下為備註事項" IS '==以下為備註事項';
COMMENT ON COLUMN "fil0036"."共版支" IS '共版支?';

-- Files：0.備註副檔二
CREATE TABLE "fil0037" (
    "製令單別" varchar(10) DEFAULT ' ' NOT NULL,
    "製令單號" varchar(20) DEFAULT ' ' NOT NULL,
    "材料序號" numeric(10,0) DEFAULT 0 NOT NULL,
    "屬性" varchar(20) DEFAULT ' ' NOT NULL,
    "序號" smallint DEFAULT 0 NOT NULL,
    "代碼" varchar(40) DEFAULT ' ' NOT NULL,
    "備註" varchar(100) DEFAULT ' ' NOT NULL,
    "越文" smallint DEFAULT 0 NOT NULL,
    "數字一" numeric(14,4) DEFAULT 0 NOT NULL,
    "圖檔" bytea,
    "建檔人" varchar(10) DEFAULT ' ' NOT NULL,
    "檔名" varchar(100) DEFAULT ' ' NOT NULL,
    "相關單別" varchar(10) DEFAULT ' ' NOT NULL,
    "相關單號" varchar(20) DEFAULT ' ' NOT NULL,
    "製程代碼" varchar(10) DEFAULT ' ' NOT NULL,
    PRIMARY KEY ("製令單別", "製令單號", "材料序號", "屬性", "序號")
);
CREATE UNIQUE INDEX "fil0037_02" ON "fil0037" ("屬性", "材料序號", "製令單別", "製令單號", "序號");
COMMENT ON TABLE "fil0037" IS '0.備註副檔二';
COMMENT ON COLUMN "fil0037"."製令單別" IS '單別';
COMMENT ON COLUMN "fil0037"."製令單號" IS '單號';
COMMENT ON COLUMN "fil0037"."製程代碼" IS '製程單號';

-- Files：0.行事曆說明
CREATE TABLE "fil0037a" (
    "單據類別" varchar(10) DEFAULT ' ' NOT NULL,
    "單據編號" varchar(20) DEFAULT ' ' NOT NULL,
    "序號" integer DEFAULT 0 NOT NULL,
    "主旨" varchar(20) DEFAULT ' ' NOT NULL,
    "日期" char(8) DEFAULT '00000000' NOT NULL,
    "時間" char(6) DEFAULT '000000' NOT NULL,
    "地點" varchar(20) DEFAULT ' ' NOT NULL
);
CREATE UNIQUE INDEX "fil0037akey1" ON "fil0037a" ("單據類別", "單據編號", "序號");
COMMENT ON TABLE "fil0037a" IS '0.行事曆說明';

-- Files：0.客戶看色記錄
CREATE TABLE "fil0037b" (
    "製令單別" varchar(10) DEFAULT ' ' NOT NULL,
    "製令單號" varchar(20) DEFAULT ' ' NOT NULL,
    "序號" smallint DEFAULT 0 NOT NULL,
    "圖檔" bytea,
    "開始看色日期" char(8) DEFAULT '00000000' NOT NULL,
    "開始看色時間" char(6) DEFAULT '000000' NOT NULL,
    "結束看色日期" char(8) DEFAULT '00000000' NOT NULL,
    "結束看色時間" char(6) DEFAULT '000000' NOT NULL,
    "建檔人員" varchar(10) DEFAULT ' ' NOT NULL,
    PRIMARY KEY ("製令單別", "製令單號", "序號")
);
COMMENT ON TABLE "fil0037b" IS '0.客戶看色記錄';
COMMENT ON COLUMN "fil0037b"."製令單別" IS '單別';
COMMENT ON COLUMN "fil0037b"."製令單號" IS '單號';

-- Files：0.其它說明主檔
CREATE TABLE "fil0038" (
    "單別" varchar(10) DEFAULT ' ' NOT NULL,
    "單號" varchar(20) DEFAULT ' ' NOT NULL,
    "說明一" varchar(100) DEFAULT ' ' NOT NULL,
    "說明二" varchar(100) DEFAULT ' ' NOT NULL,
    "說明三" varchar(100) DEFAULT ' ' NOT NULL,
    "說明四" varchar(100) DEFAULT ' ' NOT NULL,
    "說明五" varchar(100) DEFAULT ' ' NOT NULL,
    "數字一" numeric(14,4) DEFAULT 0 NOT NULL,
    "數字二" numeric(14,4) DEFAULT 0 NOT NULL,
    "流水編號" varchar(60) DEFAULT ' ' NOT NULL,
    PRIMARY KEY ("流水編號")
);
CREATE INDEX "fil0038_01" ON "fil0038" ("單別", "單號");
COMMENT ON TABLE "fil0038" IS '0.其它說明主檔';

-- Files：0.產品條件製程
CREATE TABLE "fil0039" (
    "製令單號" varchar(20) DEFAULT ' ' NOT NULL,
    "節點" varchar(60) DEFAULT ' ' NOT NULL,
    "父節點" varchar(20) DEFAULT ' ' NOT NULL,
    "製程代碼" varchar(10) DEFAULT ' ' NOT NULL,
    "機台代碼" varchar(10) DEFAULT ' ' NOT NULL,
    "工作代碼" varchar(10) DEFAULT ' ' NOT NULL,
    "AB底側" varchar(50) DEFAULT ' ' NOT NULL,
    "AB底側二" varchar(50) DEFAULT ' ' NOT NULL,
    "AB底側三" varchar(50) DEFAULT ' ' NOT NULL,
    "AB底側四" varchar(50) DEFAULT ' ' NOT NULL,
    "使用半成品" varchar(50) DEFAULT ' ' NOT NULL,
    "使用半成品二" varchar(50) DEFAULT ' ' NOT NULL,
    "使用半成品三" varchar(50) DEFAULT ' ' NOT NULL,
    "使用半成品四" varchar(50) DEFAULT ' ' NOT NULL,
    "物料編號" varchar(20) DEFAULT ' ' NOT NULL,
    "物料編號二" varchar(20) DEFAULT ' ' NOT NULL,
    "物料編號三" varchar(20) DEFAULT ' ' NOT NULL,
    "物料編號四" varchar(20) DEFAULT ' ' NOT NULL,
    "控制點一" varchar(20) DEFAULT ' ' NOT NULL,
    "控制點二" smallint NOT NULL,
    "半成品名稱" varchar(50) DEFAULT ' ' NOT NULL,
    "說明" varchar(100) NOT NULL,
    "流水編號" varchar(60) DEFAULT ' ' NOT NULL,
    "更新人員" varchar(20) DEFAULT ' ' NOT NULL,
    "預計投產日" char(8) DEFAULT '00000000' NOT NULL,
    "實際投產日" char(8) DEFAULT '00000000' NOT NULL
);
CREATE UNIQUE INDEX "fil0039_01" ON "fil0039" ("製令單號", "節點");
CREATE INDEX "fil0039_02" ON "fil0039" ("工作代碼");
CREATE INDEX "fil0039_03" ON "fil0039" ("製令單號", "工作代碼");
COMMENT ON TABLE "fil0039" IS '0.產品條件製程';
COMMENT ON COLUMN "fil0039"."AB底側" IS 'AB底側一';
COMMENT ON COLUMN "fil0039"."使用半成品" IS '使用半成品一';
COMMENT ON COLUMN "fil0039"."物料編號" IS '物料編號一';

-- Files：0.產品條件產編
CREATE TABLE "fil003a" (
    "單據類別" varchar(10) DEFAULT ' ' NOT NULL,
    "單據編號" varchar(20) DEFAULT ' ' NOT NULL,
    "單據序號" numeric(10,0) NOT NULL,
    "產品編號" varchar(20) DEFAULT ' ' NOT NULL
);
CREATE UNIQUE INDEX "fil003a_01" ON "fil003a" ("單據類別", "單據編號", "單據序號");
CREATE UNIQUE INDEX "fil003a_02" ON "fil003a" ("單據類別", "單據編號", "產品編號");
COMMENT ON TABLE "fil003a" IS '0.產品條件產編';

-- Files：0.產品條件半成品編碼
CREATE TABLE "fil003a1" (
    "單據類別" varchar(10) DEFAULT 'C11' NOT NULL,
    "單據編號" varchar(20) DEFAULT ' ' NOT NULL,
    "半成品編號" varchar(20) NOT NULL,
    "回數" numeric(10,0) NOT NULL,
    "條數" numeric(10,0) NOT NULL,
    "製造日期" char(8) DEFAULT '00000000' NOT NULL,
    "有效日期" char(8) DEFAULT '00000000' NOT NULL
);
CREATE UNIQUE INDEX "fil003a1key1" ON "fil003a1" ("單據類別", "單據編號", "半成品編號");
CREATE UNIQUE INDEX "fil003a1key2" ON "fil003a1" ("單據類別", "單據編號", "回數", "條數");
CREATE INDEX "fil003a1key3" ON "fil003a1" ("半成品編號");
COMMENT ON TABLE "fil003a1" IS '0.產品條件半成品編碼';

-- Files：0.產品條件共用製令
CREATE TABLE "fil003a2" (
    "單據類別" varchar(10) DEFAULT ' ' NOT NULL,
    "單據編號" varchar(20) DEFAULT ' ' NOT NULL,
    "單據序號" numeric(10,0) NOT NULL,
    "製令單號" varchar(20) DEFAULT ' ' NOT NULL
);
CREATE UNIQUE INDEX "fil003a2_01" ON "fil003a2" ("單據類別", "單據編號", "單據序號");
CREATE UNIQUE INDEX "fil003a2_02" ON "fil003a2" ("單據類別", "單據編號", "製令單號");
COMMENT ON TABLE "fil003a2" IS '0.產品條件共用製令';

-- Files：0.產品條件客戶要求
CREATE TABLE "fil003a3" (
    "單據類別" varchar(10) DEFAULT ' ' NOT NULL,
    "單據編號" varchar(20) DEFAULT ' ' NOT NULL,
    "半成品編號" varchar(20) DEFAULT ' ' NOT NULL,
    "直徑" numeric(14,4) DEFAULT 0 NOT NULL,
    "重量" numeric(14,4) DEFAULT 0 NOT NULL,
    "製造日期" char(8) DEFAULT '00000000' NOT NULL,
    "有效日期" char(8) DEFAULT '00000000' NOT NULL
);
CREATE UNIQUE INDEX "fil003a2key1" ON "fil003a3" ("單據類別", "單據編號", "半成品編號");
COMMENT ON TABLE "fil003a3" IS '0.產品條件客戶要求';

-- Files：0.產品條件製程用料
CREATE TABLE "fil003b" (
    "單據類別" varchar(10) DEFAULT ' ' NOT NULL,
    "單據編號" varchar(20) DEFAULT ' ' NOT NULL,
    "用途" varchar(10) DEFAULT ' ' NOT NULL,
    "加工類別" varchar(1) DEFAULT ' ' NOT NULL,
    "序號" smallint DEFAULT 0 NOT NULL,
    "材料代碼" varchar(20) DEFAULT ' ' NOT NULL,
    "節點" varchar(60) DEFAULT ' ' NOT NULL,
    "用量" numeric(14,4) DEFAULT 0 NOT NULL,
    "單位" varchar(10) DEFAULT ' ' NOT NULL,
    "備註" varchar(100) DEFAULT ' ' NOT NULL
);
CREATE UNIQUE INDEX "fil003b_key1" ON "fil003b" ("單據類別", "單據編號", "用途", "加工類別", "序號");
COMMENT ON TABLE "fil003b" IS '0.產品條件製程用料';

-- Files：0.產品條件共版
CREATE TABLE "fil003c" (
    "單據類別" varchar(10) DEFAULT ' ' NOT NULL,
    "單據編號" varchar(20) DEFAULT ' ' NOT NULL,
    "加工別" varchar(1) DEFAULT ' ' NOT NULL,
    "色順" numeric(10,0) NOT NULL,
    "產品編號" varchar(20) DEFAULT ' ' NOT NULL,
    "版銅編號" varchar(50) NOT NULL,
    "母版色順" numeric(10,0) DEFAULT 0 NOT NULL,
    "母版色順代碼" varchar(3) DEFAULT ' ' NOT NULL
);
CREATE UNIQUE INDEX "fil003c_01" ON "fil003c" ("單據類別", "單據編號", "加工別", "色順");
CREATE INDEX "fil003c_key2" ON "fil003c" ("版銅編號");
COMMENT ON TABLE "fil003c" IS '0.產品條件共版';

-- Files：0.產品條件送貨地址
CREATE TABLE "fil003d" (
    "單據類別" varchar(10) DEFAULT ' ' NOT NULL,
    "單據編號" varchar(20) DEFAULT ' ' NOT NULL,
    "序號" smallint DEFAULT 0 NOT NULL,
    "收貨人" varchar(40) DEFAULT ' ' NOT NULL,
    "地址" varchar(100) DEFAULT ' ' NOT NULL,
    "電話" varchar(40) DEFAULT ' ' NOT NULL,
    "備註" varchar(50) NOT NULL,
    "勾選" smallint DEFAULT 0 NOT NULL
);
CREATE UNIQUE INDEX "fil003d_key1" ON "fil003d" ("單據類別", "單據編號", "序號");
COMMENT ON TABLE "fil003d" IS '0.產品條件送貨地址';

-- Files：0.成品檢驗記錄表/出廠檢驗報告
CREATE TABLE "fil003e" (
    "主檔流水編號" varchar(60) DEFAULT ' ' NOT NULL,
    "檢驗數量" numeric(10,0) DEFAULT 0 NOT NULL,
    "檢驗單位" varchar(10) DEFAULT ' ' NOT NULL,
    "不良數量" numeric(10,0) DEFAULT 0 NOT NULL,
    "不良單位" varchar(10) DEFAULT ' ' NOT NULL,
    "交貨日期" char(8) DEFAULT '00000000' NOT NULL,
    "交貨數量" numeric(10,0) DEFAULT 0 NOT NULL,
    "檢驗項目" varchar(1) DEFAULT ' ' NOT NULL,
    "尺寸" varchar(100) DEFAULT ' ' NOT NULL,
    "厚度1" integer DEFAULT 0 NOT NULL,
    "厚度2" integer DEFAULT 0 NOT NULL,
    "厚度3" integer DEFAULT 0 NOT NULL,
    "圖稿" smallint DEFAULT 0 NOT NULL,
    "成品外觀" smallint DEFAULT 0 NOT NULL,
    "淋膜_貼合" smallint DEFAULT 0 NOT NULL,
    "裁切平整性" smallint DEFAULT 0 NOT NULL,
    "圖文清晰度" smallint DEFAULT 0 NOT NULL,
    "紙箱清潔度" smallint DEFAULT 0 NOT NULL,
    "外標籤" smallint DEFAULT 0 NOT NULL,
    "N圖稿" smallint DEFAULT 0 NOT NULL,
    "N成品外觀" smallint DEFAULT 0 NOT NULL,
    "N淋膜_貼合" smallint DEFAULT 0 NOT NULL,
    "N裁切平整性" smallint DEFAULT 0 NOT NULL,
    "N圖文清晰度" smallint DEFAULT 0 NOT NULL,
    "N紙箱清潔度" smallint DEFAULT 0 NOT NULL,
    "N外標籤" smallint DEFAULT 0 NOT NULL,
    "製袋成品檢驗項目" varchar(1) DEFAULT ' ' NOT NULL,
    "撕角位置" integer DEFAULT 0 NOT NULL,
    "夾鏈位置" integer DEFAULT 0 NOT NULL,
    "邊封口寬度_上下" varchar(1) DEFAULT ' ' NOT NULL,
    "邊封口寬度_上下mm" integer DEFAULT 0 NOT NULL,
    "邊封口寬度_背邊側" varchar(1) DEFAULT ' ' NOT NULL,
    "邊封口寬度_背邊側mm" integer DEFAULT 0 NOT NULL,
    "氣閥" integer DEFAULT 0 NOT NULL,
    "鐵條" integer DEFAULT 0 NOT NULL,
    "切口平整性" smallint DEFAULT 0 NOT NULL,
    "測漏試驗" smallint DEFAULT 0 NOT NULL,
    "開口測試" smallint DEFAULT 0 NOT NULL,
    "熱封強度測試" smallint DEFAULT 0 NOT NULL,
    "N切口平整性" smallint DEFAULT 0 NOT NULL,
    "N測漏試驗" smallint DEFAULT 0 NOT NULL,
    "N開口測試" smallint DEFAULT 0 NOT NULL,
    "N熱封強度測試" smallint DEFAULT 0 NOT NULL,
    "成卷成品檢驗項目" varchar(1) DEFAULT ' ' NOT NULL,
    "電眼間距" integer DEFAULT 0 NOT NULL,
    "電眼間距二" integer DEFAULT 0 NOT NULL,
    "出紙方向" varchar(1) DEFAULT ' ' NOT NULL,
    "紙管" smallint DEFAULT 0 NOT NULL,
    "外包裝" smallint DEFAULT 0 NOT NULL,
    "成捲鬆緊度" smallint DEFAULT 0 NOT NULL,
    "紙管完整度" smallint DEFAULT 0 NOT NULL,
    "N紙管" smallint DEFAULT 0 NOT NULL,
    "N外包裝" smallint DEFAULT 0 NOT NULL,
    "N成捲鬆緊度" smallint DEFAULT 0 NOT NULL,
    "N紙管完整度" smallint DEFAULT 0 NOT NULL,
    "備註" varchar(200) DEFAULT ' ' NOT NULL,
    "其他" varchar(1) DEFAULT ' ' NOT NULL,
    "判定" varchar(1) DEFAULT ' ' NOT NULL,
    "判定其他說明" varchar(40) DEFAULT ' ' NOT NULL,
    "作業人員1" varchar(10) DEFAULT ' ' NOT NULL,
    "作業人員2" varchar(10) DEFAULT ' ' NOT NULL,
    "作業人員3" varchar(10) DEFAULT ' ' NOT NULL,
    "作業人員4" varchar(10) DEFAULT ' ' NOT NULL,
    "作業人員5" varchar(10) DEFAULT ' ' NOT NULL,
    "作業人員6" varchar(10) DEFAULT ' ' NOT NULL,
    "產品名稱" varchar(100) DEFAULT ' ' NOT NULL,
    "氣閥巡檢單別" varchar(10) DEFAULT ' ' NOT NULL,
    "氣閥巡檢單號" varchar(20) DEFAULT ' ' NOT NULL,
    "鐵條巡檢單別" varchar(10) DEFAULT ' ' NOT NULL,
    "鐵條巡檢單號" varchar(20) DEFAULT ' ' NOT NULL,
    "製令單別" varchar(10) DEFAULT ' ' NOT NULL,
    "製令單號" varchar(20) DEFAULT ' ' NOT NULL,
    "製造日期" char(8) DEFAULT '00000000' NOT NULL,
    "生產數量" numeric(14,4) DEFAULT 0 NOT NULL,
    "標籤類別" varchar(2) DEFAULT ' ' NOT NULL,
    "標準厚度" integer DEFAULT 0 NOT NULL,
    "標準尺寸" varchar(100) DEFAULT ' ' NOT NULL,
    "標準電眼間距" integer DEFAULT 0 NOT NULL,
    "標準撕角位置" integer DEFAULT 0 NOT NULL,
    "標準夾鏈位置" integer DEFAULT 0 NOT NULL,
    "標準邊封口寬度_上下" varchar(1) DEFAULT ' ' NOT NULL,
    "標準邊封口寬度_上下mm" integer DEFAULT 0 NOT NULL,
    "標準邊封口寬度_背邊側" varchar(1) DEFAULT ' ' NOT NULL,
    "標準邊封口寬度_背邊側mm" integer DEFAULT 0 NOT NULL,
    "標準氣閥" integer DEFAULT 0 NOT NULL,
    "標準鐵條" integer DEFAULT 0 NOT NULL,
    PRIMARY KEY ("主檔流水編號")
);
COMMENT ON TABLE "fil003e" IS '0.成品檢驗記錄表/出廠檢驗報告';
COMMENT ON COLUMN "fil003e"."檢驗項目" IS '==檢驗項目';
COMMENT ON COLUMN "fil003e"."尺寸" IS '尺寸(±2mm)';
COMMENT ON COLUMN "fil003e"."圖稿" IS 'y圖稿';
COMMENT ON COLUMN "fil003e"."成品外觀" IS 'y成品外觀';
COMMENT ON COLUMN "fil003e"."淋膜_貼合" IS 'y淋膜/貼合';
COMMENT ON COLUMN "fil003e"."裁切平整性" IS 'y裁切平整性';
COMMENT ON COLUMN "fil003e"."圖文清晰度" IS 'y圖文清晰度';
COMMENT ON COLUMN "fil003e"."紙箱清潔度" IS 'y紙箱清潔度';
COMMENT ON COLUMN "fil003e"."外標籤" IS 'y外標籤';
COMMENT ON COLUMN "fil003e"."N圖稿" IS 'n圖稿';
COMMENT ON COLUMN "fil003e"."N成品外觀" IS 'n成品外觀';
COMMENT ON COLUMN "fil003e"."N淋膜_貼合" IS 'n淋膜/貼合';
COMMENT ON COLUMN "fil003e"."N裁切平整性" IS 'n裁切平整性';
COMMENT ON COLUMN "fil003e"."N圖文清晰度" IS 'n圖文清晰度';
COMMENT ON COLUMN "fil003e"."N紙箱清潔度" IS 'n紙箱清潔度';
COMMENT ON COLUMN "fil003e"."N外標籤" IS 'n外標籤';
COMMENT ON COLUMN "fil003e"."製袋成品檢驗項目" IS '==製袋成品檢驗項目';
COMMENT ON COLUMN "fil003e"."撕角位置" IS '撕角位置(±2mm)';
COMMENT ON COLUMN "fil003e"."夾鏈位置" IS '夾鏈位置(±2mm)';
COMMENT ON COLUMN "fil003e"."邊封口寬度_上下" IS '邊封口寬度(上/下)';
COMMENT ON COLUMN "fil003e"."邊封口寬度_上下mm" IS '邊封口寬度(上/下±2mm)';
COMMENT ON COLUMN "fil003e"."邊封口寬度_背邊側" IS '邊封口寬度(背/邊/側)';
COMMENT ON COLUMN "fil003e"."邊封口寬度_背邊側mm" IS '邊封口寬度(背/邊/側±2mm)';
COMMENT ON COLUMN "fil003e"."氣閥" IS '氣閥(±2mm)';
COMMENT ON COLUMN "fil003e"."鐵條" IS '鐵條(±2mm)';
COMMENT ON COLUMN "fil003e"."切口平整性" IS 'y切口平整性';
COMMENT ON COLUMN "fil003e"."測漏試驗" IS 'y測漏試驗';
COMMENT ON COLUMN "fil003e"."開口測試" IS 'y開口測試';
COMMENT ON COLUMN "fil003e"."熱封強度測試" IS 'y熱封強度測試';
COMMENT ON COLUMN "fil003e"."N切口平整性" IS 'n切口平整性';
COMMENT ON COLUMN "fil003e"."N測漏試驗" IS 'n測漏試驗';
COMMENT ON COLUMN "fil003e"."N開口測試" IS 'n開口測試';
COMMENT ON COLUMN "fil003e"."N熱封強度測試" IS 'n熱封強度測試';
COMMENT ON COLUMN "fil003e"."成卷成品檢驗項目" IS '==成卷成品檢驗項目';
COMMENT ON COLUMN "fil003e"."電眼間距" IS '電眼間距(±2mm)';
COMMENT ON COLUMN "fil003e"."紙管" IS 'y紙管';
COMMENT ON COLUMN "fil003e"."外包裝" IS 'y外包裝';
COMMENT ON COLUMN "fil003e"."成捲鬆緊度" IS 'y成捲鬆緊度(出廠檢驗)';
COMMENT ON COLUMN "fil003e"."紙管完整度" IS 'y紙管完整度(出廠檢驗)';
COMMENT ON COLUMN "fil003e"."N紙管" IS 'n紙管';
COMMENT ON COLUMN "fil003e"."N外包裝" IS 'n外包裝';
COMMENT ON COLUMN "fil003e"."N成捲鬆緊度" IS 'n成捲鬆緊度(出廠檢驗)';
COMMENT ON COLUMN "fil003e"."N紙管完整度" IS 'n紙管完整度(出廠檢驗)';
COMMENT ON COLUMN "fil003e"."其他" IS '==其他';
COMMENT ON COLUMN "fil003e"."標準撕角位置" IS '標準撕角位置(±2mm)';
COMMENT ON COLUMN "fil003e"."標準夾鏈位置" IS '標準夾鏈位置(±2mm)';
COMMENT ON COLUMN "fil003e"."標準邊封口寬度_上下" IS '標準邊封口寬度(上/下)';
COMMENT ON COLUMN "fil003e"."標準邊封口寬度_上下mm" IS '標準邊封口寬度(上/下±2mm)';
COMMENT ON COLUMN "fil003e"."標準邊封口寬度_背邊側" IS '標準邊封口寬度(背/邊/側)';
COMMENT ON COLUMN "fil003e"."標準邊封口寬度_背邊側mm" IS '標準邊封口寬度(背/邊/側±2mm)';
COMMENT ON COLUMN "fil003e"."標準氣閥" IS '標準氣閥(±2mm)';
COMMENT ON COLUMN "fil003e"."標準鐵條" IS '標準鐵條(±2mm)';

-- Files：0.產品條件標籤
CREATE TABLE "fil003f" (
    "單據類別" varchar(10) DEFAULT ' ' NOT NULL,
    "單據編號" varchar(20) DEFAULT ' ' NOT NULL,
    "單據序號" smallint DEFAULT 0 NOT NULL,
    "類別" varchar(2) DEFAULT 'D1' NOT NULL,
    "張數" integer DEFAULT 0 NOT NULL,
    "已取箱號" integer DEFAULT 0 NOT NULL,
    "已印箱數" integer DEFAULT 0 NOT NULL,
    "無氣閥產品編號" varchar(20) DEFAULT ' ' NOT NULL,
    "無氣閥有鐵條編號" varchar(20) DEFAULT ' ' NOT NULL,
    "有氣閥產品編號" varchar(20) DEFAULT ' ' NOT NULL,
    "有氣閥有鐵條編號" varchar(20) DEFAULT ' ' NOT NULL,
    "title" varchar(100) DEFAULT ' ' NOT NULL,
    "po" varchar(20) DEFAULT ' ' NOT NULL,
    "cartonlabel" varchar(20) DEFAULT ' ' NOT NULL,
    "item" varchar(25) DEFAULT ' ' NOT NULL,
    "客戶名稱" varchar(20) DEFAULT ' ' NOT NULL,
    "保存期限" smallint NOT NULL,
    "儲存溫度" varchar(10) DEFAULT '常溫' NOT NULL,
    "儲存濕度" varchar(10) DEFAULT '常濕' NOT NULL,
    "製造廠商" varchar(20) DEFAULT ' ' NOT NULL,
    "title_2" varchar(100) DEFAULT ' ' NOT NULL,
    "po_2" varchar(20) DEFAULT ' ' NOT NULL,
    "cartonlabel_2" varchar(20) DEFAULT ' ' NOT NULL,
    "item_2" varchar(25) DEFAULT ' ' NOT NULL,
    "客戶名稱_2" varchar(20) DEFAULT ' ' NOT NULL,
    "保存期限_2" smallint NOT NULL,
    "儲存溫度_2" varchar(10) DEFAULT '常溫' NOT NULL,
    "儲存濕度_2" varchar(10) DEFAULT '常濕' NOT NULL,
    "製造廠商_2" varchar(20) DEFAULT ' ' NOT NULL,
    "title_3" varchar(100) DEFAULT ' ' NOT NULL,
    "po_3" varchar(20) DEFAULT ' ' NOT NULL,
    "cartonlabel_3" varchar(20) DEFAULT ' ' NOT NULL,
    "item_3" varchar(25) DEFAULT ' ' NOT NULL,
    "客戶名稱_3" varchar(20) DEFAULT ' ' NOT NULL,
    "保存期限_3" smallint NOT NULL,
    "儲存溫度_3" varchar(10) DEFAULT '常溫' NOT NULL,
    "儲存濕度_3" varchar(10) DEFAULT '常濕' NOT NULL,
    "製造廠商_3" varchar(20) DEFAULT ' ' NOT NULL,
    "title_4" varchar(100) DEFAULT ' ' NOT NULL,
    "po_4" varchar(20) DEFAULT ' ' NOT NULL,
    "cartonlabel_4" varchar(20) DEFAULT ' ' NOT NULL,
    "item_4" varchar(25) DEFAULT ' ' NOT NULL,
    "客戶名稱_4" varchar(20) DEFAULT ' ' NOT NULL,
    "保存期限_4" smallint NOT NULL,
    "儲存溫度_4" varchar(10) DEFAULT '常溫' NOT NULL,
    "儲存濕度_4" varchar(10) DEFAULT '常濕' NOT NULL,
    "製造廠商_4" varchar(20) DEFAULT ' ' NOT NULL,
    "材質一" varchar(10) DEFAULT ' ' NOT NULL,
    "u一" smallint DEFAULT 0 NOT NULL,
    "材質二" varchar(10) DEFAULT ' ' NOT NULL,
    "u二" smallint DEFAULT 0 NOT NULL,
    "材質三" varchar(10) DEFAULT ' ' NOT NULL,
    "u三" smallint DEFAULT 0 NOT NULL,
    "材質四" varchar(10) DEFAULT ' ' NOT NULL,
    "u四" smallint DEFAULT 0 NOT NULL,
    "材質五" varchar(10) DEFAULT ' ' NOT NULL,
    "u五" smallint DEFAULT 0 NOT NULL,
    "材質六" varchar(10) DEFAULT ' ' NOT NULL,
    "u六" smallint DEFAULT 0 NOT NULL,
    "材質七" varchar(10) DEFAULT ' ' NOT NULL,
    "u七" smallint DEFAULT 0 NOT NULL,
    "材質" varchar(40) DEFAULT ' ' NOT NULL,
    "材質溫度" varchar(50) DEFAULT ' ' NOT NULL,
    "溫度" varchar(50) DEFAULT ' ' NOT NULL,
    "備註" varchar(50) DEFAULT ' ' NOT NULL,
    "廠商地址" varchar(100) DEFAULT ' ' NOT NULL,
    "廠商電話" varchar(40) DEFAULT ' ' NOT NULL
);
CREATE UNIQUE INDEX "fil003f_01" ON "fil003f" ("單據類別", "單據編號", "單據序號", "類別");
COMMENT ON TABLE "fil003f" IS '0.產品條件標籤';
COMMENT ON COLUMN "fil003f"."無氣閥產品編號" IS '1.無氣閥無鐵條編號';
COMMENT ON COLUMN "fil003f"."無氣閥有鐵條編號" IS '3.無氣閥有鐵條編號';
COMMENT ON COLUMN "fil003f"."有氣閥產品編號" IS '2.有氣閥無鐵條編號';
COMMENT ON COLUMN "fil003f"."有氣閥有鐵條編號" IS '4.有氣閥有鐵條編號';
COMMENT ON COLUMN "fil003f"."title" IS 'TITLE(產品名稱)';
COMMENT ON COLUMN "fil003f"."po" IS 'PO(客戶訂單)';
COMMENT ON COLUMN "fil003f"."cartonlabel" IS 'CartonLabel(客戶料號)';
COMMENT ON COLUMN "fil003f"."item" IS 'ITEM(客戶品號)';
COMMENT ON COLUMN "fil003f"."保存期限" IS '保存期限(月數)';
COMMENT ON COLUMN "fil003f"."title_2" IS 'TITLE(產品名稱)_2';
COMMENT ON COLUMN "fil003f"."po_2" IS 'PO(客戶訂單)_2';
COMMENT ON COLUMN "fil003f"."cartonlabel_2" IS 'CartonLabel(客戶料號)_2';
COMMENT ON COLUMN "fil003f"."item_2" IS 'ITEM(客戶品號)_2';
COMMENT ON COLUMN "fil003f"."保存期限_2" IS '保存期限(月數)_2';
COMMENT ON COLUMN "fil003f"."title_3" IS 'TITLE(產品名稱)_3';
COMMENT ON COLUMN "fil003f"."po_3" IS 'PO(客戶訂單)_3';
COMMENT ON COLUMN "fil003f"."cartonlabel_3" IS 'CartonLabel(客戶料號)_3';
COMMENT ON COLUMN "fil003f"."item_3" IS 'ITEM(客戶品號)_3';
COMMENT ON COLUMN "fil003f"."保存期限_3" IS '保存期限(月數)_3';
COMMENT ON COLUMN "fil003f"."title_4" IS 'TITLE(產品名稱)_4';
COMMENT ON COLUMN "fil003f"."po_4" IS 'PO(客戶訂單)_4';
COMMENT ON COLUMN "fil003f"."cartonlabel_4" IS 'CartonLabel(客戶料號)_4';
COMMENT ON COLUMN "fil003f"."item_4" IS 'ITEM(客戶品號)_4';
COMMENT ON COLUMN "fil003f"."保存期限_4" IS '保存期限(月數)_4';

-- Files：0.產品裁切標籤
CREATE TABLE "fil003f1" (
    "單據類別" varchar(10) DEFAULT ' ' NOT NULL,
    "單據編號" varchar(20) DEFAULT ' ' NOT NULL,
    "單據序號" smallint DEFAULT 0 NOT NULL,
    "類別" varchar(2) DEFAULT ' ' NOT NULL,
    "客戶料號" varchar(20) DEFAULT ' ' NOT NULL,
    "客戶訂單" varchar(20) DEFAULT ' ' NOT NULL,
    "產品編號" varchar(20) DEFAULT ' ' NOT NULL,
    "產品名稱" varchar(100) DEFAULT ' ' NOT NULL,
    "產品規格" varchar(30) DEFAULT ' ' NOT NULL,
    "作業員" varchar(10) DEFAULT ' ' NOT NULL,
    "材質結構" varchar(50) DEFAULT ' ' NOT NULL,
    "儲存溫度" varchar(10) DEFAULT '常溫' NOT NULL,
    "儲存濕度" varchar(10) DEFAULT '常濕' NOT NULL,
    "訂單數量" varchar(20) DEFAULT ' ' NOT NULL,
    "產地" varchar(10) DEFAULT '台灣' NOT NULL,
    "包裝數量" numeric(10,0) NOT NULL,
    "製造日期" char(8) DEFAULT '00000000' NOT NULL,
    "有效日期" char(8) DEFAULT '00000000' NOT NULL,
    "廠商" varchar(20) DEFAULT ' ' NOT NULL,
    "備註" varchar(50) DEFAULT ' ' NOT NULL,
    "內管分條數" integer DEFAULT 0 NOT NULL,
    "內管備註" varchar(50) DEFAULT ' ' NOT NULL,
    "材質一" varchar(10) DEFAULT ' ' NOT NULL,
    "u一" smallint DEFAULT 0 NOT NULL,
    "材質二" varchar(10) DEFAULT ' ' NOT NULL,
    "u二" smallint DEFAULT 0 NOT NULL,
    "材質三" varchar(10) DEFAULT ' ' NOT NULL,
    "u三" smallint DEFAULT 0 NOT NULL,
    "材質四" varchar(10) DEFAULT ' ' NOT NULL,
    "u四" smallint DEFAULT 0 NOT NULL,
    "材質五" varchar(10) DEFAULT ' ' NOT NULL,
    "u五" smallint DEFAULT 0 NOT NULL,
    "材質六" varchar(10) DEFAULT ' ' NOT NULL,
    "u六" smallint DEFAULT 0 NOT NULL,
    "材質七" varchar(10) DEFAULT ' ' NOT NULL,
    "u七" smallint DEFAULT 0 NOT NULL,
    "材質溫度" varchar(50) DEFAULT ' ' NOT NULL,
    "溫度" varchar(50) DEFAULT ' ' NOT NULL,
    "保存期限" smallint DEFAULT 0 NOT NULL,
    "客戶名稱" varchar(20) DEFAULT ' ' NOT NULL,
    "客戶品號" varchar(25) DEFAULT ' ' NOT NULL,
    "廠商地址" varchar(100) DEFAULT ' ' NOT NULL,
    "廠商電話" varchar(40) DEFAULT ' ' NOT NULL
);
CREATE UNIQUE INDEX "fil003f1_01" ON "fil003f1" ("單據類別", "單據編號", "單據序號", "類別");
COMMENT ON TABLE "fil003f1" IS '0.產品裁切標籤';

-- Files：0.製袋線上巡檢記錄表
CREATE TABLE "fil003g" (
    "主檔流水編號" varchar(60) DEFAULT ' ' NOT NULL,
    "機台代碼" varchar(10) DEFAULT ' ' NOT NULL,
    "作業速率" integer DEFAULT 0 NOT NULL,
    "檢驗時間" char(6) DEFAULT '000000' NOT NULL,
    "箱號" integer DEFAULT 0 NOT NULL,
    "備註" varchar(100) DEFAULT ' ' NOT NULL,
    "檢驗項目" varchar(1) DEFAULT ' ' NOT NULL,
    "尺寸" varchar(100) DEFAULT ' ' NOT NULL,
    "厚度1" integer DEFAULT 0 NOT NULL,
    "厚度2" integer DEFAULT 0 NOT NULL,
    "厚度3" integer DEFAULT 0 NOT NULL,
    "圖稿" smallint DEFAULT 0 NOT NULL,
    "成品外觀" smallint DEFAULT 0 NOT NULL,
    "淋膜_貼合" smallint DEFAULT 0 NOT NULL,
    "裁切平整性" smallint DEFAULT 0 NOT NULL,
    "圖文清晰度" smallint DEFAULT 0 NOT NULL,
    "紙箱清潔度" smallint DEFAULT 0 NOT NULL,
    "外標籤" smallint DEFAULT 0 NOT NULL,
    "N圖稿" smallint DEFAULT 0 NOT NULL,
    "N成品外觀" smallint DEFAULT 0 NOT NULL,
    "N淋膜_貼合" smallint DEFAULT 0 NOT NULL,
    "N裁切平整性" smallint DEFAULT 0 NOT NULL,
    "N圖文清晰度" smallint DEFAULT 0 NOT NULL,
    "N紙箱清潔度" smallint DEFAULT 0 NOT NULL,
    "N外標籤" smallint DEFAULT 0 NOT NULL,
    "製袋成品檢驗項目" varchar(1) DEFAULT ' ' NOT NULL,
    "撕角位置" integer DEFAULT 0 NOT NULL,
    "夾鏈位置" integer DEFAULT 0 NOT NULL,
    "邊封口寬度_上下" varchar(1) DEFAULT ' ' NOT NULL,
    "邊封口寬度_上下mm" integer DEFAULT 0 NOT NULL,
    "邊封口寬度_背邊側" varchar(1) DEFAULT ' ' NOT NULL,
    "邊封口寬度_背邊側mm" integer DEFAULT 0 NOT NULL,
    "氣閥" integer DEFAULT 0 NOT NULL,
    "鐵條" integer DEFAULT 0 NOT NULL,
    "切口平整性" smallint DEFAULT 0 NOT NULL,
    "測漏試驗" smallint DEFAULT 0 NOT NULL,
    "開口測試" smallint DEFAULT 0 NOT NULL,
    "熱封強度測試" smallint DEFAULT 0 NOT NULL,
    "N切口平整性" smallint DEFAULT 0 NOT NULL,
    "N測漏試驗" smallint DEFAULT 0 NOT NULL,
    "N開口測試" smallint DEFAULT 0 NOT NULL,
    "N熱封強度測試" smallint DEFAULT 0 NOT NULL,
    "標準厚度" integer DEFAULT 0 NOT NULL,
    "機台狀態" varchar(1) DEFAULT ' ' NOT NULL,
    "追加欄位" varchar(1) DEFAULT ' ' NOT NULL,
    "標準尺寸" varchar(100) DEFAULT ' ' NOT NULL,
    "標準電眼間距" integer DEFAULT 0 NOT NULL,
    "標準撕角位置" integer DEFAULT 0 NOT NULL,
    "標準夾鏈位置" integer DEFAULT 0 NOT NULL,
    "標準邊封口寬度_上下" varchar(1) DEFAULT ' ' NOT NULL,
    "標準邊封口寬度_上下mm" integer DEFAULT 0 NOT NULL,
    "標準邊封口寬度_背邊側" varchar(1) DEFAULT ' ' NOT NULL,
    "標準邊封口寬度_背邊側mm" integer DEFAULT 0 NOT NULL,
    "標準氣閥" integer DEFAULT 0 NOT NULL,
    "標準鐵條" integer DEFAULT 0 NOT NULL,
    PRIMARY KEY ("主檔流水編號")
);
CREATE INDEX "fil003g_02" ON "fil003g" ("機台代碼");
COMMENT ON TABLE "fil003g" IS '0.製袋線上巡檢記錄表';
COMMENT ON COLUMN "fil003g"."檢驗項目" IS '==檢驗項目';
COMMENT ON COLUMN "fil003g"."尺寸" IS '尺寸(±2mm)';
COMMENT ON COLUMN "fil003g"."圖稿" IS 'y圖稿';
COMMENT ON COLUMN "fil003g"."成品外觀" IS 'y成品外觀';
COMMENT ON COLUMN "fil003g"."淋膜_貼合" IS 'y淋膜/貼合';
COMMENT ON COLUMN "fil003g"."裁切平整性" IS 'y裁切平整性';
COMMENT ON COLUMN "fil003g"."圖文清晰度" IS 'y圖文清晰度';
COMMENT ON COLUMN "fil003g"."紙箱清潔度" IS 'y紙箱清潔度';
COMMENT ON COLUMN "fil003g"."外標籤" IS 'y外標籤';
COMMENT ON COLUMN "fil003g"."N圖稿" IS 'n圖稿';
COMMENT ON COLUMN "fil003g"."N成品外觀" IS 'n成品外觀';
COMMENT ON COLUMN "fil003g"."N淋膜_貼合" IS 'n淋膜/貼合';
COMMENT ON COLUMN "fil003g"."N裁切平整性" IS 'n裁切平整性';
COMMENT ON COLUMN "fil003g"."N圖文清晰度" IS 'n圖文清晰度';
COMMENT ON COLUMN "fil003g"."N紙箱清潔度" IS 'n紙箱清潔度';
COMMENT ON COLUMN "fil003g"."N外標籤" IS 'n外標籤';
COMMENT ON COLUMN "fil003g"."製袋成品檢驗項目" IS '==製袋成品檢驗項目';
COMMENT ON COLUMN "fil003g"."撕角位置" IS '撕角位置(±2mm)';
COMMENT ON COLUMN "fil003g"."夾鏈位置" IS '夾鏈位置(±2mm)';
COMMENT ON COLUMN "fil003g"."邊封口寬度_上下" IS '邊封口寬度(上/下)';
COMMENT ON COLUMN "fil003g"."邊封口寬度_上下mm" IS '邊封口寬度(上/下±2mm)';
COMMENT ON COLUMN "fil003g"."邊封口寬度_背邊側" IS '邊封口寬度(背/邊/側)';
COMMENT ON COLUMN "fil003g"."邊封口寬度_背邊側mm" IS '邊封口寬度(背/邊/側±2mm)';
COMMENT ON COLUMN "fil003g"."氣閥" IS '氣閥(±2mm)';
COMMENT ON COLUMN "fil003g"."鐵條" IS '鐵條(±2mm)';
COMMENT ON COLUMN "fil003g"."切口平整性" IS 'y切口平整性';
COMMENT ON COLUMN "fil003g"."測漏試驗" IS 'y測漏試驗';
COMMENT ON COLUMN "fil003g"."開口測試" IS 'y開口測試';
COMMENT ON COLUMN "fil003g"."熱封強度測試" IS 'y熱封強度測試';
COMMENT ON COLUMN "fil003g"."N切口平整性" IS 'n切口平整性';
COMMENT ON COLUMN "fil003g"."N測漏試驗" IS 'n測漏試驗';
COMMENT ON COLUMN "fil003g"."N開口測試" IS 'n開口測試';
COMMENT ON COLUMN "fil003g"."N熱封強度測試" IS 'n熱封強度測試';
COMMENT ON COLUMN "fil003g"."追加欄位" IS '==追加欄位';
COMMENT ON COLUMN "fil003g"."標準撕角位置" IS '標準撕角位置(±2mm)';
COMMENT ON COLUMN "fil003g"."標準夾鏈位置" IS '標準夾鏈位置(±2mm)';
COMMENT ON COLUMN "fil003g"."標準邊封口寬度_上下" IS '標準邊封口寬度(上/下)';
COMMENT ON COLUMN "fil003g"."標準邊封口寬度_上下mm" IS '標準邊封口寬度(上/下±2mm)';
COMMENT ON COLUMN "fil003g"."標準邊封口寬度_背邊側" IS '標準邊封口寬度(背/邊/側)';
COMMENT ON COLUMN "fil003g"."標準邊封口寬度_背邊側mm" IS '標準邊封口寬度(背/邊/側±2mm)';
COMMENT ON COLUMN "fil003g"."標準氣閥" IS '標準氣閥(±2mm)';
COMMENT ON COLUMN "fil003g"."標準鐵條" IS '標準鐵條(±2mm)';

-- Files：0.氣閥鐵條線上巡檢表
CREATE TABLE "fil003h" (
    "主檔流水編號" varchar(60) DEFAULT ' ' NOT NULL,
    "巡檢項目" varchar(10) DEFAULT ' ' NOT NULL,
    "機台代碼" varchar(10) DEFAULT ' ' NOT NULL,
    "作業位置" numeric(7,2) DEFAULT 0 NOT NULL,
    "出袋距離_左" numeric(7,2) DEFAULT 0 NOT NULL,
    "出袋距離_右" numeric(7,2) DEFAULT 0 NOT NULL,
    "檢驗時間" char(6) DEFAULT '000000' NOT NULL,
    "箱號" integer DEFAULT 0 NOT NULL,
    "Y牢固完整度" smallint DEFAULT 0 NOT NULL,
    "N牢固完整度" smallint DEFAULT 0 NOT NULL,
    "作業員" varchar(10) DEFAULT ' ' NOT NULL,
    "備註" varchar(100) DEFAULT ' ' NOT NULL,
    "機台狀態" varchar(1) DEFAULT ' ' NOT NULL,
    PRIMARY KEY ("主檔流水編號")
);
CREATE INDEX "fil003h_02" ON "fil003h" ("巡檢項目");
CREATE INDEX "fil003h_03" ON "fil003h" ("機台代碼");
COMMENT ON TABLE "fil003h" IS '0.氣閥鐵條線上巡檢表';
COMMENT ON COLUMN "fil003h"."Y牢固完整度" IS 'y牢固完整度';
COMMENT ON COLUMN "fil003h"."N牢固完整度" IS 'n牢固完整度';

-- Files：0.估價單主檔
CREATE TABLE "fil003i" (
    "單別" varchar(10) DEFAULT ' ' NOT NULL,
    "單號" varchar(20) DEFAULT ' ' NOT NULL,
    "產品名稱" varchar(50) DEFAULT ' ' NOT NULL,
    "成捲製袋" varchar(1) DEFAULT ' ' NOT NULL,
    "袋型" varchar(10) DEFAULT ' ' NOT NULL,
    "夾鏈" varchar(10) DEFAULT ' ' NOT NULL,
    "樣式" varchar(10) DEFAULT ' ' NOT NULL,
    "高" numeric(6,2) DEFAULT 0 NOT NULL,
    "寬" numeric(6,2) DEFAULT 0 NOT NULL,
    "長" numeric(6,2) DEFAULT 0 NOT NULL,
    "多少M" numeric(6,2) DEFAULT 0 NOT NULL,
    "購買數量" numeric(10,0) DEFAULT 0 NOT NULL,
    "展開尺寸A" numeric(6,2) DEFAULT 0 NOT NULL,
    "展開尺寸B" numeric(6,2) DEFAULT 0 NOT NULL,
    "尺寸倍率" numeric(4,1) DEFAULT 1 NOT NULL,
    "原料第一層" varchar(20) DEFAULT ' ' NOT NULL,
    "原料第二層" varchar(20) DEFAULT ' ' NOT NULL,
    "原料第三層" varchar(20) DEFAULT ' ' NOT NULL,
    "原料第四層" varchar(20) DEFAULT ' ' NOT NULL,
    "原料第五層" varchar(20) DEFAULT ' ' NOT NULL,
    "原料第六層" varchar(20) DEFAULT ' ' NOT NULL,
    "原料厚度第一層" numeric(6,2) DEFAULT 0 NOT NULL,
    "原料厚度第二層" numeric(6,2) DEFAULT 0 NOT NULL,
    "原料厚度第三層" numeric(6,2) DEFAULT 0 NOT NULL,
    "原料厚度第四層" numeric(6,2) DEFAULT 0 NOT NULL,
    "原料厚度第五層" numeric(6,2) DEFAULT 0 NOT NULL,
    "原料厚度第六層" numeric(6,2) DEFAULT 0 NOT NULL,
    "進貨價格倍率" numeric(3,1) DEFAULT 0 NOT NULL,
    "原料第一層價格" numeric(6,2) DEFAULT 0 NOT NULL,
    "原料第二層價格" numeric(6,2) DEFAULT 0 NOT NULL,
    "原料第三層價格" numeric(6,2) DEFAULT 0 NOT NULL,
    "原料第四層價格" numeric(6,2) DEFAULT 0 NOT NULL,
    "原料第五層價格" numeric(6,2) DEFAULT 0 NOT NULL,
    "原料第六層價格" numeric(6,2) DEFAULT 0 NOT NULL,
    "原料加價" numeric(6,2) DEFAULT 0 NOT NULL,
    "貼合第一層" smallint NOT NULL,
    "貼合第二層" smallint NOT NULL,
    "貼合第三層" smallint NOT NULL,
    "貼合第四層" smallint NOT NULL,
    "貼合第五層" smallint NOT NULL,
    "貼合第六層" smallint NOT NULL,
    "膠水第一層" varchar(20) DEFAULT ' ' NOT NULL,
    "膠水第二層" varchar(20) DEFAULT ' ' NOT NULL,
    "膠水第三層" varchar(20) DEFAULT ' ' NOT NULL,
    "膠水第四層" varchar(20) DEFAULT ' ' NOT NULL,
    "膠水第五層" varchar(20) DEFAULT ' ' NOT NULL,
    "膠水第六層" varchar(20) DEFAULT ' ' NOT NULL,
    "貼合第一層價格" numeric(6,2) DEFAULT 0 NOT NULL,
    "貼合第二層價格" numeric(6,2) DEFAULT 0 NOT NULL,
    "貼合第三層價格" numeric(6,2) DEFAULT 0 NOT NULL,
    "貼合第四層價格" numeric(6,2) DEFAULT 0 NOT NULL,
    "貼合第五層價格" numeric(6,2) DEFAULT 0 NOT NULL,
    "貼合第六層價格" numeric(6,2) DEFAULT 0 NOT NULL,
    "貼合每層價格" smallint DEFAULT 0 NOT NULL,
    "貼合加價" numeric(6,2) DEFAULT 0 NOT NULL,
    "貼合工資" numeric(6,2) DEFAULT 0 NOT NULL,
    "淋膜第一層" smallint NOT NULL,
    "淋膜第二層" smallint NOT NULL,
    "淋膜第三層" smallint NOT NULL,
    "淋膜第四層" smallint NOT NULL,
    "淋膜第五層" smallint NOT NULL,
    "淋膜第六層" smallint NOT NULL,
    "塑料第一層" varchar(20) DEFAULT ' ' NOT NULL,
    "塑料第二層" varchar(20) DEFAULT ' ' NOT NULL,
    "塑料第三層" varchar(20) DEFAULT ' ' NOT NULL,
    "塑料第四層" varchar(20) DEFAULT ' ' NOT NULL,
    "塑料第五層" varchar(20) DEFAULT ' ' NOT NULL,
    "塑料第六層" varchar(20) DEFAULT ' ' NOT NULL,
    "塑料厚度第一層" numeric(6,2) DEFAULT 0 NOT NULL,
    "塑料厚度第二層" numeric(6,2) DEFAULT 0 NOT NULL,
    "塑料厚度第三層" numeric(6,2) DEFAULT 0 NOT NULL,
    "塑料厚度第四層" numeric(6,2) DEFAULT 0 NOT NULL,
    "塑料厚度第五層" numeric(6,2) DEFAULT 0 NOT NULL,
    "塑料厚度第六層" numeric(6,2) DEFAULT 0 NOT NULL,
    "塑料密度第一層" numeric(8,4) DEFAULT 0 NOT NULL,
    "塑料密度第二層" numeric(8,4) DEFAULT 0 NOT NULL,
    "塑料密度第三層" numeric(8,4) DEFAULT 0 NOT NULL,
    "塑料密度第四層" numeric(8,4) DEFAULT 0 NOT NULL,
    "塑料密度第五層" numeric(8,4) DEFAULT 0 NOT NULL,
    "塑料密度第六層" numeric(8,4) DEFAULT 0 NOT NULL,
    "塑膠粒每層加價" numeric(6,2) DEFAULT 0 NOT NULL,
    "塑料第一層價格" numeric(6,2) DEFAULT 0 NOT NULL,
    "塑料第二層價格" numeric(6,2) DEFAULT 0 NOT NULL,
    "塑料第三層價格" numeric(6,2) DEFAULT 0 NOT NULL,
    "塑料第四層價格" numeric(6,2) DEFAULT 0 NOT NULL,
    "塑料第五層價格" numeric(6,2) DEFAULT 0 NOT NULL,
    "塑料第六層價格" numeric(6,2) DEFAULT 0 NOT NULL,
    "淋膜加價" numeric(6,2) DEFAULT 0 NOT NULL,
    "價格第一層" numeric(6,2) DEFAULT 0 NOT NULL,
    "價格第二層" numeric(6,2) DEFAULT 0 NOT NULL,
    "價格第三層" numeric(6,2) DEFAULT 0 NOT NULL,
    "價格第四層" numeric(6,2) DEFAULT 0 NOT NULL,
    "價格第五層" numeric(6,2) DEFAULT 0 NOT NULL,
    "價格第六層" numeric(6,2) DEFAULT 0 NOT NULL,
    "第一色" varchar(20) DEFAULT ' ' NOT NULL,
    "第二色" varchar(20) DEFAULT ' ' NOT NULL,
    "第三色" varchar(20) DEFAULT ' ' NOT NULL,
    "第四色" varchar(20) DEFAULT ' ' NOT NULL,
    "第五色" varchar(20) DEFAULT ' ' NOT NULL,
    "第六色" varchar(20) DEFAULT ' ' NOT NULL,
    "第七色" varchar(20) DEFAULT ' ' NOT NULL,
    "第八色" varchar(20) DEFAULT ' ' NOT NULL,
    "第九色" varchar(20) DEFAULT ' ' NOT NULL,
    "第十色" varchar(20) DEFAULT ' ' NOT NULL,
    "第一色滿版" smallint DEFAULT 0 NOT NULL,
    "第二色滿版" smallint DEFAULT 0 NOT NULL,
    "第三色滿版" smallint DEFAULT 0 NOT NULL,
    "第四色滿版" smallint DEFAULT 0 NOT NULL,
    "第五色滿版" smallint DEFAULT 0 NOT NULL,
    "第六色滿版" smallint DEFAULT 0 NOT NULL,
    "第七色滿版" smallint DEFAULT 0 NOT NULL,
    "第八色滿版" smallint DEFAULT 0 NOT NULL,
    "第九色滿版" smallint DEFAULT 0 NOT NULL,
    "第十色滿版" smallint DEFAULT 0 NOT NULL,
    "第一色倍率" numeric(3,0) DEFAULT 100 NOT NULL,
    "第二色倍率" numeric(3,0) DEFAULT 100 NOT NULL,
    "第三色倍率" numeric(3,0) DEFAULT 100 NOT NULL,
    "第四色倍率" numeric(3,0) DEFAULT 100 NOT NULL,
    "第五色倍率" numeric(3,0) DEFAULT 100 NOT NULL,
    "第六色倍率" numeric(3,0) DEFAULT 100 NOT NULL,
    "第七色倍率" numeric(3,0) DEFAULT 100 NOT NULL,
    "第八色倍率" numeric(3,0) DEFAULT 100 NOT NULL,
    "第九色倍率" numeric(3,0) DEFAULT 100 NOT NULL,
    "第十色倍率" numeric(3,0) DEFAULT 100 NOT NULL,
    "每色價格" numeric(6,2) DEFAULT 0 NOT NULL,
    "滿版價格" numeric(6,2) DEFAULT 0 NOT NULL,
    "印刷加價" numeric(6,2) NOT NULL,
    "印刷工資" numeric(6,2) DEFAULT 0 NOT NULL,
    "數印加價" numeric(6,2) DEFAULT 0 NOT NULL,
    "加工費" numeric(6,2) DEFAULT 0 NOT NULL,
    "夾鏈料號" varchar(20) DEFAULT ' ' NOT NULL,
    "氣閥料號" varchar(20) DEFAULT ' ' NOT NULL,
    "鐵條料號" varchar(20) DEFAULT ' ' NOT NULL,
    "色數" smallint DEFAULT 0 NOT NULL,
    "每色製版費" numeric(8,2) DEFAULT 0 NOT NULL,
    "製版費" numeric(8,2) DEFAULT 0 NOT NULL,
    "燙金費" numeric(8,2) DEFAULT 0 NOT NULL,
    "雷射費" numeric(8,2) DEFAULT 0 NOT NULL,
    "倍率" numeric(5,2) DEFAULT 1 NOT NULL,
    "單價" numeric(6,2) DEFAULT 0 NOT NULL,
    "未稅總金額" numeric(10,0) DEFAULT 0 NOT NULL,
    "流水編號" varchar(60) DEFAULT ' ' NOT NULL,
    "最後更新者" varchar(10) DEFAULT ' ' NOT NULL,
    "最後更新日" timestamp(0),
    PRIMARY KEY ("單別", "單號")
);
CREATE UNIQUE INDEX "fil003i_02" ON "fil003i" ("流水編號");
COMMENT ON TABLE "fil003i" IS '0.估價單主檔';
COMMENT ON COLUMN "fil003i"."單別" IS '單別(B01)';
COMMENT ON COLUMN "fil003i"."單號" IS '單號(B01)';
COMMENT ON COLUMN "fil003i"."最後更新日" IS '最後更新日 / 最後更新時';

-- Files：0.估價單袋型
CREATE TABLE "fil003j" (
    "流水編號" varchar(60) DEFAULT ' ' NOT NULL,
    "序號" smallint DEFAULT 0 NOT NULL,
    "袋型" varchar(40) DEFAULT ' ' NOT NULL,
    "價格" smallint DEFAULT 0 NOT NULL,
    "選擇" smallint DEFAULT 0 NOT NULL,
    "最後更新者" varchar(10) DEFAULT ' ' NOT NULL,
    "最後更新日" timestamp(0),
    PRIMARY KEY ("流水編號", "序號")
);
COMMENT ON TABLE "fil003j" IS '0.估價單袋型';
COMMENT ON COLUMN "fil003j"."價格" IS '價格(元)';
COMMENT ON COLUMN "fil003j"."最後更新日" IS '最後更新日 / 最後更新時';

-- Files：0.估價單燙金
CREATE TABLE "fil003j1" (
    "流水編號" varchar(60) DEFAULT ' ' NOT NULL,
    "單據序號" integer NOT NULL,
    "序號" integer DEFAULT 0 NOT NULL,
    "名稱" varchar(20) DEFAULT ' ' NOT NULL,
    "長" numeric(12,2) DEFAULT 0 NOT NULL,
    "寬" numeric(12,2) DEFAULT 0 NOT NULL,
    "版費單價" numeric(12,2) DEFAULT 0 NOT NULL,
    "版費" numeric(12,2) DEFAULT 0 NOT NULL,
    "面積" numeric(5,0) DEFAULT 0 NOT NULL,
    "顏色代碼" varchar(10) DEFAULT ' ' NOT NULL,
    "基本色" smallint DEFAULT 0 NOT NULL,
    "材料單價" numeric(14,4) DEFAULT 0 NOT NULL,
    "材料費" numeric(12,2) DEFAULT 0 NOT NULL,
    "最後更新者" varchar(10) DEFAULT ' ' NOT NULL,
    "最後更新日" timestamp(0),
    PRIMARY KEY ("流水編號", "單據序號", "序號")
);
COMMENT ON TABLE "fil003j1" IS '0.估價單燙金';
COMMENT ON COLUMN "fil003j1"."最後更新日" IS '最後更新日 / 最後更新時';

-- Files：0.客訴單主檔
CREATE TABLE "fil003k1" (
    "單別" varchar(10) DEFAULT ' ' NOT NULL,
    "單號" varchar(20) DEFAULT ' ' NOT NULL,
    "異常別_進料" smallint DEFAULT 0 NOT NULL,
    "異常別_製程" smallint DEFAULT 0 NOT NULL,
    "異常別_庫存" smallint DEFAULT 0 NOT NULL,
    "異常別_檢驗" smallint DEFAULT 0 NOT NULL,
    "異常別_其他" smallint DEFAULT 0 NOT NULL,
    "異常別_其他說明" varchar(50) DEFAULT ' ' NOT NULL,
    "異常別_進料_廠商" varchar(10) DEFAULT ' ' NOT NULL,
    "異常別_製程_單位" varchar(10) DEFAULT ' ' NOT NULL,
    "異常別_檢驗_單位" varchar(10) DEFAULT ' ' NOT NULL,
    "異常別權責單位" varchar(10) DEFAULT ' ' NOT NULL,
    "摘要" varchar(30) DEFAULT ' ' NOT NULL,
    "詳述" varchar(400) DEFAULT ' ' NOT NULL,
    "原因探討" varchar(400) DEFAULT ' ' NOT NULL,
    "原因探討權責單位" varchar(10) DEFAULT ' ' NOT NULL,
    "改善對策" varchar(400) NOT NULL,
    "改善對策權責單位" varchar(10) DEFAULT ' ' NOT NULL,
    "流水編號" varchar(60) DEFAULT ' ' NOT NULL,
    "最後更新者" varchar(10) DEFAULT ' ' NOT NULL,
    "最後更新日" timestamp(0),
    PRIMARY KEY ("單別", "單號")
);
CREATE UNIQUE INDEX "fil003k1_02" ON "fil003k1" ("流水編號");
COMMENT ON TABLE "fil003k1" IS '0.客訴單主檔';
COMMENT ON COLUMN "fil003k1"."單別" IS '單別(R01)';
COMMENT ON COLUMN "fil003k1"."單號" IS '單號(R01)';
COMMENT ON COLUMN "fil003k1"."異常別權責單位" IS '異常別：權責單位';
COMMENT ON COLUMN "fil003k1"."原因探討權責單位" IS '原因探討：權責單位';
COMMENT ON COLUMN "fil003k1"."改善對策權責單位" IS '改善對策：權責單位';
COMMENT ON COLUMN "fil003k1"."最後更新日" IS '最後更新日 / 最後更新時';

-- Files：0.品質異常單主檔
CREATE TABLE "fil003l1" (
    "單別" varchar(10) DEFAULT ' ' NOT NULL,
    "單號" varchar(20) DEFAULT ' ' NOT NULL,
    "異常大類" varchar(2) DEFAULT ' ' NOT NULL,
    "異常原因分類" varchar(2) DEFAULT ' ' NOT NULL,
    "異常原因分類二" varchar(2) DEFAULT ' ' NOT NULL,
    "異常原因分類三" varchar(2) DEFAULT ' ' NOT NULL,
    "異常單位" varchar(10) DEFAULT ' ' NOT NULL,
    "異常現象_作業者" varchar(100) DEFAULT ' ' NOT NULL,
    "異常現象_作業者姓名" varchar(200) DEFAULT ' ' NOT NULL,
    "異常現象_摘要" varchar(100) DEFAULT ' ' NOT NULL,
    "異常現象_詳述" varchar(500) DEFAULT ' ' NOT NULL,
    "異常現象_填表人" varchar(10) DEFAULT ' ' NOT NULL,
    "異常原因_摘要" varchar(100) DEFAULT ' ' NOT NULL,
    "異常原因分析" varchar(500) DEFAULT ' ' NOT NULL,
    "矯正措施_摘要1" varchar(100) DEFAULT ' ' NOT NULL,
    "矯正措施_摘要2" varchar(500) DEFAULT ' ' NOT NULL,
    "矯正措施_填表人" varchar(10) DEFAULT ' ' NOT NULL,
    "再發防止措施_摘要" varchar(100) DEFAULT ' ' NOT NULL,
    "再發防止措施" varchar(500) DEFAULT ' ' NOT NULL,
    "再發防止措施_作業人員" varchar(10) DEFAULT ' ' NOT NULL,
    "追蹤確認" varchar(500) DEFAULT ' ' NOT NULL,
    "追蹤確認_品管人員" varchar(10) DEFAULT ' ' NOT NULL,
    "流水編號" varchar(60) DEFAULT ' ' NOT NULL,
    "最後更新者" varchar(10) DEFAULT ' ' NOT NULL,
    "最後更新日" timestamp(0),
    PRIMARY KEY ("單別", "單號")
);
CREATE UNIQUE INDEX "fil003l1_02" ON "fil003l1" ("流水編號");
CREATE INDEX "fil003l1_03" ON "fil003l1" ("異常單位");
CREATE INDEX "fil003l1_04" ON "fil003l1" ("異常現象_填表人");
COMMENT ON TABLE "fil003l1" IS '0.品質異常單主檔';
COMMENT ON COLUMN "fil003l1"."單別" IS '單別(R02)';
COMMENT ON COLUMN "fil003l1"."單號" IS '單號(R02)';
COMMENT ON COLUMN "fil003l1"."最後更新日" IS '最後更新日 / 最後更新時';

-- Files：0.銷退處理記錄表主檔
CREATE TABLE "fil003m1" (
    "單別" varchar(10) DEFAULT ' ' NOT NULL,
    "單號" varchar(20) DEFAULT ' ' NOT NULL,
    "退貨日期" char(8) DEFAULT '00000000' NOT NULL,
    "退貨方式" varchar(1) DEFAULT ' ' NOT NULL,
    "退貨件數" integer DEFAULT 0 NOT NULL,
    "退貨方式說明" varchar(20) DEFAULT ' ' NOT NULL,
    "退貨原因" varchar(100) DEFAULT ' ' NOT NULL,
    "處理數量_入庫" varchar(50) DEFAULT ' ' NOT NULL,
    "處理數量_銷毀" varchar(50) DEFAULT ' ' NOT NULL,
    "處理數量_其他" varchar(50) DEFAULT ' ' NOT NULL,
    "處理數量_其他說明" varchar(50) DEFAULT ' ' NOT NULL,
    "後續處理" varchar(500) DEFAULT ' ' NOT NULL,
    "品管課負責人" varchar(10) DEFAULT ' ' NOT NULL,
    "流水編號" varchar(60) DEFAULT ' ' NOT NULL,
    "最後更新者" varchar(10) DEFAULT ' ' NOT NULL,
    "最後更新日" timestamp(0),
    PRIMARY KEY ("單別", "單號")
);
CREATE UNIQUE INDEX "fil003m1_02" ON "fil003m1" ("流水編號");
COMMENT ON TABLE "fil003m1" IS '0.銷退處理記錄表主檔';
COMMENT ON COLUMN "fil003m1"."單別" IS '單別(R03)';
COMMENT ON COLUMN "fil003m1"."單號" IS '單號(R03)';
COMMENT ON COLUMN "fil003m1"."最後更新日" IS '最後更新日 / 最後更新時';

-- Files：0.特採申請單主檔
CREATE TABLE "fil003n1" (
    "單別" varchar(10) DEFAULT ' ' NOT NULL,
    "單號" varchar(20) DEFAULT ' ' NOT NULL,
    "特採類別" varchar(1) DEFAULT ' ' NOT NULL,
    "進料批號" varchar(40) DEFAULT ' ' NOT NULL,
    "進料數量" numeric(14,4) DEFAULT 0 NOT NULL,
    "進料單位" varchar(10) DEFAULT ' ' NOT NULL,
    "進料日期" char(8) DEFAULT '00000000' NOT NULL,
    "原物料名稱" varchar(100) DEFAULT ' ' NOT NULL,
    "製造日期" char(8) DEFAULT '00000000' NOT NULL,
    "作業人員" varchar(100) NOT NULL,
    "作業人員姓名" varchar(200) NOT NULL,
    "特採日期" char(8) DEFAULT '00000000' NOT NULL,
    "特採數量" numeric(14,4) DEFAULT 0 NOT NULL,
    "特採單位" varchar(10) DEFAULT ' ' NOT NULL,
    "流水編號" varchar(60) DEFAULT ' ' NOT NULL,
    "最後更新者" varchar(10) DEFAULT ' ' NOT NULL,
    "最後更新日" timestamp(0),
    PRIMARY KEY ("單別", "單號")
);
CREATE UNIQUE INDEX "fil003n1_02" ON "fil003n1" ("流水編號");
COMMENT ON TABLE "fil003n1" IS '0.特採申請單主檔';
COMMENT ON COLUMN "fil003n1"."單別" IS '單別(R04)';
COMMENT ON COLUMN "fil003n1"."單號" IS '單號(R04)';
COMMENT ON COLUMN "fil003n1"."最後更新日" IS '最後更新日 / 最後更新時';

-- Files：0.生產日報附加欄位
CREATE TABLE "fil003o" (
    "單據類別" varchar(10) DEFAULT ' ' NOT NULL,
    "單據編號" varchar(20) DEFAULT ' ' NOT NULL,
    "垃圾袋" numeric(14,4) DEFAULT 0 NOT NULL,
    "邊料" numeric(14,4) DEFAULT 0 NOT NULL
);
CREATE UNIQUE INDEX "fil003okey1" ON "fil003o" ("單據類別", "單據編號");
COMMENT ON TABLE "fil003o" IS '0.生產日報附加欄位';

-- Files：0.報價條文
CREATE TABLE "fil003p" (
    "單據類別" varchar(10) DEFAULT ' ' NOT NULL,
    "單據編號" varchar(20) DEFAULT ' ' NOT NULL,
    "條文代碼" varchar(10) DEFAULT ' ' NOT NULL,
    "選入" smallint DEFAULT 0 NOT NULL,
    "報價選入" smallint DEFAULT 0 NOT NULL,
    "條文" varchar(300) DEFAULT ' ' NOT NULL,
    "參數" varchar(50) DEFAULT ' ' NOT NULL
);
CREATE UNIQUE INDEX "fil003pkey1" ON "fil003p" ("單據類別", "單據編號", "條文代碼");
COMMENT ON TABLE "fil003p" IS '0.報價條文';
COMMENT ON COLUMN "fil003p"."選入" IS '估價選入';

-- Files：0.異動單明細
CREATE TABLE "fil0040" (
    "單據類別" varchar(10) DEFAULT ' ' NOT NULL,
    "單據編號" varchar(20) DEFAULT ' ' NOT NULL,
    "單據序號" smallint DEFAULT 0 NOT NULL,
    "異動類別" varchar(1) DEFAULT ' ' NOT NULL,
    "異動日期" char(8) DEFAULT '00000000' NOT NULL,
    "異動數量" numeric(14,4) DEFAULT 0 NOT NULL,
    "贈品數量" numeric(14,4) DEFAULT 0 NOT NULL,
    "異動單價" numeric(14,4) DEFAULT 0 NOT NULL,
    "異動金額" numeric(14,4) DEFAULT 0 NOT NULL,
    "異動稅額" numeric(14,4) DEFAULT 0 NOT NULL,
    "產品編號" varchar(70) DEFAULT ' ' NOT NULL,
    "廠客品號" varchar(40) DEFAULT ' ' NOT NULL,
    "單位代碼" varchar(10) DEFAULT ' ' NOT NULL,
    "倉庫代碼" varchar(10) DEFAULT ' ' NOT NULL,
    "折扣率" numeric(5,2) DEFAULT 0 NOT NULL,
    "毛重" numeric(14,4) DEFAULT 0 NOT NULL,
    "材積" numeric(14,4) DEFAULT 0 NOT NULL,
    "折讓" numeric(14,4) DEFAULT 0 NOT NULL,
    "預交日" char(8) DEFAULT '00000000' NOT NULL,
    "前置單別" varchar(10) DEFAULT ' ' NOT NULL,
    "前置單號" varchar(20) DEFAULT ' ' NOT NULL,
    "備註說明" varchar(400) DEFAULT ' ' NOT NULL,
    "結案碼" varchar(1) DEFAULT ' ' NOT NULL,
    "製版費" numeric(14,4) DEFAULT 0 NOT NULL,
    "燙金費" numeric(14,4) DEFAULT 0 NOT NULL,
    "雷射費" numeric(14,4) DEFAULT 0 NOT NULL,
    "夾鏈費" numeric(14,4) DEFAULT 0 NOT NULL,
    "氣閥費" numeric(14,4) DEFAULT 0 NOT NULL,
    "鐵條費" numeric(14,4) DEFAULT 0 NOT NULL,
    "logical1" smallint DEFAULT 0 NOT NULL,
    "logical2" smallint DEFAULT 0 NOT NULL,
    "logical3" smallint DEFAULT 0 NOT NULL,
    "logical4" smallint DEFAULT 0 NOT NULL,
    "logical5" smallint DEFAULT 0 NOT NULL,
    "數值1" numeric(14,4) DEFAULT 0 NOT NULL,
    "數值2" numeric(14,4) DEFAULT 0 NOT NULL,
    "數值3" numeric(14,4) DEFAULT 0 NOT NULL,
    "數值4" numeric(14,4) DEFAULT 0 NOT NULL,
    "數值5" numeric(14,4) DEFAULT 0 NOT NULL,
    "數值6" numeric(14,4) DEFAULT 0 NOT NULL,
    "數值7" numeric(14,4) DEFAULT 0 NOT NULL,
    "文數字1" varchar(60) DEFAULT ' ' NOT NULL,
    "相關代碼1" varchar(20) DEFAULT ' ' NOT NULL,
    "相關代碼2" varchar(20) DEFAULT ' ' NOT NULL,
    "相關代碼3" varchar(20) DEFAULT ' ' NOT NULL,
    "time1" char(6) DEFAULT '000000' NOT NULL,
    "qrno" numeric(10,0) DEFAULT 0 NOT NULL,
    "其它日期" char(8) DEFAULT '00000000' NOT NULL,
    "前製程編號" varchar(20) DEFAULT ' ' NOT NULL,
    "合併編號" varchar(20) DEFAULT ' ' NOT NULL,
    "退庫數量" numeric(14,4) DEFAULT 0 NOT NULL,
    "入料註記" smallint DEFAULT 0 NOT NULL,
    "退料註記" smallint DEFAULT 0 NOT NULL,
    "領料註記" smallint DEFAULT 0 NOT NULL,
    "接頭數" smallint DEFAULT 0 NOT NULL,
    "圓周" numeric(5,1) NOT NULL,
    "流水編號" varchar(60) DEFAULT ' ' NOT NULL,
    "最後更新者" varchar(10) DEFAULT ' ' NOT NULL,
    "最後更新日" timestamp(0),
    PRIMARY KEY ("單據類別", "單據編號", "單據序號")
);
CREATE INDEX "fil0040_02" ON "fil0040" ("異動日期", "產品編號", "倉庫代碼");
CREATE INDEX "fil0040_03" ON "fil0040" ("產品編號", "異動日期");
CREATE INDEX "fil0040_04" ON "fil0040" ("產品編號", "倉庫代碼", "異動日期");
CREATE INDEX "fil0040_05" ON "fil0040" ("前置單別", "前置單號", "產品編號", "異動日期");
CREATE INDEX "fil0040_06" ON "fil0040" ("文數字1", "異動日期");
CREATE INDEX "fil0040_07" ON "fil0040" ("流水編號");
CREATE INDEX "fil0040_08" ON "fil0040" ("廠客品號", "異動數量", "異動日期");
CREATE INDEX "fil0040_09" ON "fil0040" ("單據類別", "文數字1");
CREATE INDEX "預交日" ON "fil0040" ("單據類別", "預交日");
COMMENT ON TABLE "fil0040" IS '0.異動單明細';
COMMENT ON COLUMN "fil0040"."異動數量" IS '異動數量(採購:ex.RS)';
COMMENT ON COLUMN "fil0040"."毛重" IS '毛重(kg)';
COMMENT ON COLUMN "fil0040"."折讓" IS '折讓(明細)';
COMMENT ON COLUMN "fil0040"."logical1" IS 'Logical1/待補';
COMMENT ON COLUMN "fil0040"."數值4" IS '數值4(採購:ex.米)';
COMMENT ON COLUMN "fil0040"."最後更新日" IS '最後更新日 / 最後更新時';

-- Files：0.異動單明細中繼檔
CREATE TABLE "fil0040_a" (
    "單據類別" varchar(10) DEFAULT ' ' NOT NULL,
    "單據編號" varchar(20) DEFAULT ' ' NOT NULL,
    "單據序號" smallint DEFAULT 0 NOT NULL,
    "異動類別" varchar(1) DEFAULT ' ' NOT NULL,
    "異動日期" char(8) DEFAULT '00000000' NOT NULL,
    "異動數量" numeric(14,4) DEFAULT 0 NOT NULL,
    "贈品數量" numeric(14,4) DEFAULT 0 NOT NULL,
    "異動單價" numeric(14,4) DEFAULT 0 NOT NULL,
    "異動金額" numeric(14,4) DEFAULT 0 NOT NULL,
    "產品編號" varchar(70) DEFAULT ' ' NOT NULL,
    "廠客品號" varchar(40) DEFAULT ' ' NOT NULL,
    "單位代碼" varchar(10) DEFAULT ' ' NOT NULL,
    "倉庫代碼" varchar(10) DEFAULT ' ' NOT NULL,
    "折扣率" numeric(5,2) DEFAULT 0 NOT NULL,
    "毛重" numeric(14,4) DEFAULT 0 NOT NULL,
    "材積" numeric(14,4) DEFAULT 0 NOT NULL,
    "折讓" numeric(14,4) DEFAULT 0 NOT NULL,
    "預交日" char(8) DEFAULT '00000000' NOT NULL,
    "前置單別" varchar(10) DEFAULT ' ' NOT NULL,
    "前置單號" varchar(20) DEFAULT ' ' NOT NULL,
    "備註說明" varchar(400) DEFAULT ' ' NOT NULL,
    "結案碼" varchar(1) DEFAULT ' ' NOT NULL,
    "製版費" numeric(14,4) DEFAULT 0 NOT NULL,
    "燙金費" numeric(14,4) DEFAULT 0 NOT NULL,
    "雷射費" numeric(14,4) DEFAULT 0 NOT NULL,
    "夾鏈費" numeric(14,4) DEFAULT 0 NOT NULL,
    "氣閥費" numeric(14,4) DEFAULT 0 NOT NULL,
    "鐵條費" numeric(14,4) DEFAULT 0 NOT NULL,
    "logical1" smallint DEFAULT 0 NOT NULL,
    "logical2" smallint DEFAULT 0 NOT NULL,
    "logical3" smallint DEFAULT 0 NOT NULL,
    "logical4" smallint DEFAULT 0 NOT NULL,
    "logical5" smallint DEFAULT 0 NOT NULL,
    "數值1" numeric(14,4) DEFAULT 0 NOT NULL,
    "數值2" numeric(14,4) DEFAULT 0 NOT NULL,
    "數值3" numeric(14,4) DEFAULT 0 NOT NULL,
    "數值4" numeric(14,4) DEFAULT 0 NOT NULL,
    "數值5" numeric(14,4) DEFAULT 0 NOT NULL,
    "文數字1" varchar(60) DEFAULT ' ' NOT NULL,
    "相關代碼1" varchar(20) DEFAULT ' ' NOT NULL,
    "相關代碼2" varchar(20) DEFAULT ' ' NOT NULL,
    "相關代碼3" varchar(20) DEFAULT ' ' NOT NULL,
    "time1" char(6) DEFAULT '000000' NOT NULL,
    "qrno" numeric(10,0) DEFAULT 0 NOT NULL,
    "其它日期" char(8) DEFAULT '00000000' NOT NULL,
    "前製程編號" varchar(20) DEFAULT ' ' NOT NULL,
    "合併編號" varchar(20) DEFAULT ' ' NOT NULL,
    "領料註記" smallint DEFAULT 0 NOT NULL,
    "退料註記" smallint DEFAULT 0 NOT NULL,
    "流水編號" varchar(60) DEFAULT ' ' NOT NULL,
    "最後更新者" varchar(10) DEFAULT ' ' NOT NULL,
    "最後更新日" timestamp(0),
    "已復原" smallint DEFAULT 0 NOT NULL,
    PRIMARY KEY ("單據類別", "單據編號", "單據序號")
);
COMMENT ON TABLE "fil0040_a" IS '0.異動單明細中繼檔';
COMMENT ON COLUMN "fil0040_a"."毛重" IS '毛重(kg)';
COMMENT ON COLUMN "fil0040_a"."折讓" IS '折讓(明細)';
COMMENT ON COLUMN "fil0040_a"."最後更新日" IS '最後更新日 / 最後更新時';

-- Files：0.異動單刪除註記
CREATE TABLE "fil0040_b" (
    "單據類別" varchar(10) DEFAULT ' ' NOT NULL,
    "單據編號" varchar(20) DEFAULT ' ' NOT NULL,
    "單據序號" smallint DEFAULT 0 NOT NULL,
    "刪除次數" smallint DEFAULT 0 NOT NULL,
    "刪除日期" char(8) DEFAULT ' ' NOT NULL,
    "刪除時間" char(6) DEFAULT ' ' NOT NULL,
    "刪除人員" varchar(10) DEFAULT ' ' NOT NULL
);
CREATE UNIQUE INDEX "fil0040_b_key1" ON "fil0040_b" ("單據類別", "單據編號", "單據序號", "刪除次數");
COMMENT ON TABLE "fil0040_b" IS '0.異動單刪除註記';

-- Files：0.異動單切分
CREATE TABLE "fil00401" (
    "單別" varchar(10) DEFAULT ' ' NOT NULL,
    "單號" varchar(20) DEFAULT ' ' NOT NULL,
    "序號" smallint DEFAULT 0 NOT NULL,
    "細分" smallint DEFAULT 0 NOT NULL,
    "文字一" varchar(40) DEFAULT ' ' NOT NULL,
    "文字二" varchar(40) DEFAULT ' ' NOT NULL,
    "文字三" varchar(40) DEFAULT ' ' NOT NULL,
    "文字四" varchar(20) DEFAULT ' ' NOT NULL,
    "文字五" varchar(40) DEFAULT ' ' NOT NULL,
    "文字六" varchar(40) DEFAULT ' ' NOT NULL,
    "文字七" varchar(40) DEFAULT ' ' NOT NULL,
    "數字一" numeric(14,4) DEFAULT 0 NOT NULL,
    "數字二" numeric(14,4) DEFAULT 0 NOT NULL,
    "數字三" numeric(14,4) DEFAULT 0 NOT NULL,
    "數字四" numeric(14,4) DEFAULT 0 NOT NULL,
    "數字五" numeric(14,4) DEFAULT 0 NOT NULL,
    "邏輯一" smallint DEFAULT 0 NOT NULL,
    "邏輯二" smallint DEFAULT 0 NOT NULL,
    "報廢" smallint DEFAULT 0 NOT NULL,
    "重整" smallint DEFAULT 0 NOT NULL,
    "日期一" char(8) DEFAULT '00000000' NOT NULL,
    "日期二" char(8) DEFAULT '00000000' NOT NULL,
    "日期三" char(8) DEFAULT '00000000' NOT NULL,
    "時間一" char(6) DEFAULT '000000' NOT NULL,
    "時間二" char(6) DEFAULT '000000' NOT NULL,
    "時間三" char(6) DEFAULT '000000' NOT NULL,
    "備註" varchar(100) DEFAULT ' ' NOT NULL,
    "運送方式" varchar(20) DEFAULT ' ' NOT NULL
);
CREATE UNIQUE INDEX "fil00401key1" ON "fil00401" ("單別", "單號", "序號", "細分");
CREATE INDEX "fil00401key2" ON "fil00401" ("文字一");
CREATE INDEX "fil00401key3" ON "fil00401" ("文字一", "單別", "單號", "序號");
CREATE INDEX "fil00401key4" ON "fil00401" ("文字五");
COMMENT ON TABLE "fil00401" IS '0.異動單切分';
COMMENT ON COLUMN "fil00401"."文字五" IS '文字五(喜美批號)';
COMMENT ON COLUMN "fil00401"."數字一" IS '數字一(採購:支數)';
COMMENT ON COLUMN "fil00401"."數字二" IS '數字二(採購:庫存數(米)';
COMMENT ON COLUMN "fil00401"."數字三" IS '數字三(採購:單價)';
COMMENT ON COLUMN "fil00401"."數字四" IS '數字四(採購:採購數(RS)';
COMMENT ON COLUMN "fil00401"."數字五" IS '數字五(採購:出貨規格)';

-- Files：0.特殊欄位明細
CREATE TABLE "fil0041" (
    "單別" varchar(10) DEFAULT ' ' NOT NULL,
    "單號" varchar(20) DEFAULT ' ' NOT NULL,
    "序號" smallint DEFAULT 0 NOT NULL,
    "印刷" varchar(100) DEFAULT ' ' NOT NULL,
    "批號" varchar(40) DEFAULT ' ' NOT NULL,
    "小單位" varchar(10) DEFAULT ' ' NOT NULL,
    "包裝數量" numeric(14,4) DEFAULT 0 NOT NULL,
    "包裝單位" varchar(10) DEFAULT ' ' NOT NULL,
    "專案代號" varchar(40) DEFAULT ' ' NOT NULL,
    "客戶報價品名" varchar(100) DEFAULT ' ' NOT NULL,
    "客戶報價規格" varchar(100) DEFAULT ' ' NOT NULL,
    "客戶報價材質結構1" varchar(20) DEFAULT ' ' NOT NULL,
    "客戶報價材質結構2" varchar(20) DEFAULT ' ' NOT NULL,
    "客戶報價材質結構3" varchar(20) DEFAULT ' ' NOT NULL,
    "檢附COA" smallint DEFAULT 0 NOT NULL,
    "檢驗外觀" varchar(1) DEFAULT ' ' NOT NULL,
    "檢驗清潔度" varchar(1) DEFAULT ' ' NOT NULL,
    "檢驗顏色" varchar(1) DEFAULT ' ' NOT NULL,
    "檢驗尺寸" varchar(1) DEFAULT ' ' NOT NULL,
    "檢驗厚度" varchar(1) DEFAULT ' ' NOT NULL,
    "檢驗滑度" varchar(1) DEFAULT ' ' NOT NULL,
    "檢驗人員" varchar(10) DEFAULT ' ' NOT NULL,
    "檢驗判定" smallint DEFAULT 0 NOT NULL,
    "檢驗特採" smallint DEFAULT 0 NOT NULL,
    "time1" char(6) DEFAULT '000000' NOT NULL,
    "time2" char(6) DEFAULT '000000' NOT NULL,
    "time3" char(6) DEFAULT '000000' NOT NULL,
    "time4" char(6) DEFAULT '000000' NOT NULL,
    "time5" char(6) DEFAULT '000000' NOT NULL,
    "time6" char(6) DEFAULT '000000' NOT NULL,
    "手動品名" varchar(100) DEFAULT ' ' NOT NULL,
    "手動規格" varchar(100) DEFAULT ' ' NOT NULL,
    "數值1" numeric(14,4) DEFAULT 0 NOT NULL,
    "數值2" numeric(14,4) DEFAULT 0 NOT NULL,
    "數值3" numeric(14,4) DEFAULT 0 NOT NULL,
    "數值4" numeric(14,4) DEFAULT 0 NOT NULL,
    "數值5" numeric(14,4) DEFAULT 0 NOT NULL,
    "數值6" numeric(14,4) DEFAULT 0 NOT NULL,
    "數值7" numeric(14,4) DEFAULT 0 NOT NULL,
    "數值8" numeric(14,4) DEFAULT 0 NOT NULL,
    "數值9" numeric(14,4) DEFAULT 0 NOT NULL,
    "數值10" numeric(14,4) DEFAULT 0 NOT NULL,
    "數值11" numeric(14,4) DEFAULT 0 NOT NULL,
    "數值12" numeric(14,4) DEFAULT 0 NOT NULL,
    "數值13" numeric(14,4) DEFAULT 0 NOT NULL,
    "數值14" numeric(14,4) DEFAULT 0 NOT NULL,
    "數值15" numeric(14,4) DEFAULT 0 NOT NULL,
    "數值16" numeric(14,4) DEFAULT 0 NOT NULL,
    "數值17" numeric(14,4) DEFAULT 0 NOT NULL,
    "數值18" numeric(14,4) DEFAULT 0 NOT NULL,
    "數值19" numeric(14,4) DEFAULT 0 NOT NULL,
    "數值20" numeric(14,4) DEFAULT 0 NOT NULL,
    "數值21" numeric(14,4) DEFAULT 0 NOT NULL,
    "數值22" numeric(14,4) DEFAULT 0 NOT NULL,
    "數值23" numeric(14,4) DEFAULT 0 NOT NULL,
    "文數字1" varchar(40) DEFAULT ' ' NOT NULL,
    "文數字2" varchar(40) DEFAULT ' ' NOT NULL,
    "文數字3" varchar(40) DEFAULT ' ' NOT NULL,
    "文數字4" varchar(40) DEFAULT ' ' NOT NULL,
    "文數字5" varchar(40) DEFAULT ' ' NOT NULL,
    "文數字6" varchar(40) DEFAULT ' ' NOT NULL,
    "文數字7" varchar(40) DEFAULT ' ' NOT NULL,
    "文數字8" varchar(40) DEFAULT ' ' NOT NULL,
    "文數字9" varchar(40) DEFAULT ' ' NOT NULL,
    "logical1" smallint DEFAULT 0 NOT NULL,
    "logical2" smallint DEFAULT 0 NOT NULL,
    "logical3" smallint DEFAULT 0 NOT NULL,
    "logical4" smallint DEFAULT 0 NOT NULL,
    "logical5" smallint DEFAULT 0 NOT NULL,
    "logical6" smallint DEFAULT 0 NOT NULL,
    "logical7" smallint DEFAULT 0 NOT NULL,
    "logical8" smallint DEFAULT 0 NOT NULL,
    "logical9" smallint DEFAULT 0 NOT NULL,
    "文字1" varchar(500) DEFAULT ' ' NOT NULL,
    "文字2" varchar(300) DEFAULT ' ' NOT NULL,
    "標籤列印次數" integer DEFAULT 0 NOT NULL,
    "標籤列印日期" char(8) DEFAULT '00000000' NOT NULL,
    "標籤類別" varchar(2) DEFAULT ' ' NOT NULL,
    "標籤列印次數二" integer DEFAULT 0 NOT NULL,
    "標籤列印日期一" char(8) DEFAULT '00000000' NOT NULL,
    "標籤列印時間一" char(6) DEFAULT '000000' NOT NULL,
    PRIMARY KEY ("單別", "單號", "序號")
);
CREATE INDEX "fil0041_02" ON "fil0041" ("批號", "單別", "單號", "序號");
COMMENT ON TABLE "fil0041" IS '0.特殊欄位明細';
COMMENT ON COLUMN "fil0041"."文數字4" IS '文數字4(unicode)';
COMMENT ON COLUMN "fil0041"."文數字5" IS '文數字5(unicode)';
COMMENT ON COLUMN "fil0041"."文數字6" IS '文數字6(unicode)';
COMMENT ON COLUMN "fil0041"."文數字7" IS '文數字7(unicode)';
COMMENT ON COLUMN "fil0041"."文數字8" IS '文數字8(unicode)';
COMMENT ON COLUMN "fil0041"."文數字9" IS '文數字9(unicode)';

-- Files：0.特殊欄位明細中繼檔
CREATE TABLE "fil0041_a" (
    "單別" varchar(10) DEFAULT ' ' NOT NULL,
    "單號" varchar(20) DEFAULT ' ' NOT NULL,
    "序號" smallint DEFAULT 0 NOT NULL,
    "印刷" varchar(100) DEFAULT ' ' NOT NULL,
    "批號" varchar(40) DEFAULT ' ' NOT NULL,
    "小單位" varchar(10) DEFAULT ' ' NOT NULL,
    "包裝數量" numeric(14,4) DEFAULT 0 NOT NULL,
    "包裝單位" varchar(10) DEFAULT ' ' NOT NULL,
    "專案代號" varchar(40) DEFAULT ' ' NOT NULL,
    "客戶報價品名" varchar(100) DEFAULT ' ' NOT NULL,
    "客戶報價規格" varchar(100) DEFAULT ' ' NOT NULL,
    "客戶報價材質結構1" varchar(20) DEFAULT ' ' NOT NULL,
    "客戶報價材質結構2" varchar(20) DEFAULT ' ' NOT NULL,
    "客戶報價材質結構3" varchar(20) DEFAULT ' ' NOT NULL,
    "檢附COA" smallint DEFAULT 0 NOT NULL,
    "檢驗外觀" varchar(1) DEFAULT ' ' NOT NULL,
    "檢驗清潔度" varchar(1) DEFAULT ' ' NOT NULL,
    "檢驗顏色" varchar(1) DEFAULT ' ' NOT NULL,
    "檢驗尺寸" varchar(1) DEFAULT ' ' NOT NULL,
    "檢驗厚度" varchar(1) DEFAULT ' ' NOT NULL,
    "檢驗滑度" varchar(1) DEFAULT ' ' NOT NULL,
    "檢驗人員" varchar(10) DEFAULT ' ' NOT NULL,
    "檢驗判定" smallint DEFAULT 0 NOT NULL,
    "檢驗特採" smallint DEFAULT 0 NOT NULL,
    "time1" char(6) DEFAULT '000000' NOT NULL,
    "time2" char(6) DEFAULT '000000' NOT NULL,
    "time3" char(6) DEFAULT '000000' NOT NULL,
    "time4" char(6) DEFAULT '000000' NOT NULL,
    "time5" char(6) DEFAULT '000000' NOT NULL,
    "time6" char(6) DEFAULT '000000' NOT NULL,
    "手動品名" varchar(100) DEFAULT ' ' NOT NULL,
    "手動規格" varchar(100) DEFAULT ' ' NOT NULL,
    "數值1" numeric(14,4) DEFAULT 0 NOT NULL,
    "數值2" numeric(14,4) DEFAULT 0 NOT NULL,
    "數值3" numeric(14,4) DEFAULT 0 NOT NULL,
    "數值4" numeric(14,4) DEFAULT 0 NOT NULL,
    "數值5" numeric(14,4) DEFAULT 0 NOT NULL,
    "數值6" numeric(14,4) DEFAULT 0 NOT NULL,
    "數值7" numeric(14,4) DEFAULT 0 NOT NULL,
    "數值8" numeric(14,4) DEFAULT 0 NOT NULL,
    "數值9" numeric(14,4) DEFAULT 0 NOT NULL,
    "數值10" numeric(14,4) DEFAULT 0 NOT NULL,
    "數值11" numeric(14,4) DEFAULT 0 NOT NULL,
    "數值12" numeric(14,4) DEFAULT 0 NOT NULL,
    "數值13" numeric(14,4) DEFAULT 0 NOT NULL,
    "數值14" numeric(14,4) DEFAULT 0 NOT NULL,
    "數值15" numeric(14,4) DEFAULT 0 NOT NULL,
    "數值16" numeric(14,4) DEFAULT 0 NOT NULL,
    "數值17" numeric(14,4) DEFAULT 0 NOT NULL,
    "數值18" numeric(14,4) DEFAULT 0 NOT NULL,
    "數值19" numeric(14,4) DEFAULT 0 NOT NULL,
    "數值20" numeric(14,4) DEFAULT 0 NOT NULL,
    "文數字1" varchar(40) DEFAULT ' ' NOT NULL,
    "文數字2" varchar(40) DEFAULT ' ' NOT NULL,
    "文數字3" varchar(40) DEFAULT ' ' NOT NULL,
    "文數字4" varchar(40) DEFAULT ' ' NOT NULL,
    "文數字5" varchar(40) DEFAULT ' ' NOT NULL,
    "文數字6" varchar(40) DEFAULT ' ' NOT NULL,
    "文數字7" varchar(40) DEFAULT ' ' NOT NULL,
    "文數字8" varchar(40) DEFAULT ' ' NOT NULL,
    "文數字9" varchar(40) DEFAULT ' ' NOT NULL,
    "logical1" smallint DEFAULT 0 NOT NULL,
    "logical2" smallint DEFAULT 0 NOT NULL,
    "logical3" smallint DEFAULT 0 NOT NULL,
    "logical4" smallint DEFAULT 0 NOT NULL,
    "logical5" smallint DEFAULT 0 NOT NULL,
    "logical6" smallint DEFAULT 0 NOT NULL,
    "logical7" smallint DEFAULT 0 NOT NULL,
    "logical8" smallint DEFAULT 0 NOT NULL,
    "logical9" smallint DEFAULT 0 NOT NULL,
    "文字1" varchar(500) DEFAULT ' ' NOT NULL,
    "文字2" varchar(300) DEFAULT ' ' NOT NULL,
    "標籤列印次數" integer DEFAULT 0 NOT NULL,
    "標籤類別" varchar(2) DEFAULT ' ' NOT NULL,
    "標籤列印次數二" integer DEFAULT 0 NOT NULL,
    "標籤列印日期一" char(8) DEFAULT '00000000' NOT NULL,
    "標籤列印時間一" char(6) DEFAULT '000000' NOT NULL,
    PRIMARY KEY ("單別", "單號", "序號")
);
COMMENT ON TABLE "fil0041_a" IS '0.特殊欄位明細中繼檔';
COMMENT ON COLUMN "fil0041_a"."文數字4" IS '文數字4(unicode)';
COMMENT ON COLUMN "fil0041_a"."文數字5" IS '文數字5(unicode)';
COMMENT ON COLUMN "fil0041_a"."文數字6" IS '文數字6(unicode)';
COMMENT ON COLUMN "fil0041_a"."文數字7" IS '文數字7(unicode)';
COMMENT ON COLUMN "fil0041_a"."文數字8" IS '文數字8(unicode)';
COMMENT ON COLUMN "fil0041_a"."文數字9" IS '文數字9(unicode)';

-- Files：0.熟成室管制表
CREATE TABLE "fil0041_b" (
    "單別" varchar(10) DEFAULT ' ' NOT NULL,
    "單號" varchar(20) DEFAULT ' ' NOT NULL,
    "序號" smallint DEFAULT 0 NOT NULL,
    "入庫日期" char(8) DEFAULT '00000000' NOT NULL,
    "入庫時間" char(6) DEFAULT '000000' NOT NULL,
    "入庫人員" varchar(10) DEFAULT ' ' NOT NULL,
    "出庫日期" char(8) DEFAULT '00000000' NOT NULL,
    "出庫時間" char(6) DEFAULT '000000' NOT NULL,
    "出庫人員" varchar(10) DEFAULT ' ' NOT NULL,
    "熟成室位置" varchar(40) DEFAULT ' ' NOT NULL,
    "重覆入庫" smallint DEFAULT 0 NOT NULL,
    "入庫時間2" char(6) DEFAULT '000000' NOT NULL,
    "出庫時間2" char(6) DEFAULT '000000' NOT NULL,
    "可提早出庫" smallint DEFAULT 0 NOT NULL,
    "放行人員" varchar(10) DEFAULT ' ' NOT NULL,
    "不限出庫" smallint DEFAULT 0 NOT NULL,
    "不限出庫人員" varchar(10) DEFAULT ' ' NOT NULL,
    "IP位址2" varchar(40) DEFAULT ' ' NOT NULL,
    PRIMARY KEY ("單別", "單號", "序號")
);
COMMENT ON TABLE "fil0041_b" IS '0.熟成室管制表';

-- Files：0.冷鏈室管制表
CREATE TABLE "fil0041_ba" (
    "單別" varchar(10) DEFAULT ' ' NOT NULL,
    "單號" varchar(20) DEFAULT ' ' NOT NULL,
    "序號" smallint DEFAULT 0 NOT NULL,
    "入庫日期" char(8) DEFAULT '00000000' NOT NULL,
    "入庫時間" char(6) DEFAULT '000000' NOT NULL,
    "入庫人員" varchar(10) DEFAULT ' ' NOT NULL,
    "出庫日期" char(8) DEFAULT '00000000' NOT NULL,
    "出庫時間" char(6) DEFAULT '000000' NOT NULL,
    "出庫人員" varchar(10) DEFAULT ' ' NOT NULL,
    "冷鏈室位置" varchar(40) DEFAULT ' ' NOT NULL,
    "重覆入庫" smallint DEFAULT 0 NOT NULL,
    "入庫時間2" char(6) DEFAULT '000000' NOT NULL,
    "出庫時間2" char(6) DEFAULT '000000' NOT NULL,
    "可提早出庫" smallint DEFAULT 0 NOT NULL,
    "放行人員" varchar(10) DEFAULT ' ' NOT NULL,
    "不限出庫" smallint DEFAULT 0 NOT NULL,
    "不限出庫人員" varchar(10) DEFAULT ' ' NOT NULL,
    "IP位址2" varchar(40) DEFAULT ' ' NOT NULL,
    PRIMARY KEY ("單別", "單號", "序號")
);
COMMENT ON TABLE "fil0041_ba" IS '0.冷鏈室管制表';

-- Files：0.費用明細檔
CREATE TABLE "fil0042" (
    "單據類別" varchar(10) DEFAULT ' ' NOT NULL,
    "單據編號" varchar(20) DEFAULT ' ' NOT NULL,
    "單據序號" smallint DEFAULT 0 NOT NULL,
    "代碼" varchar(10) DEFAULT ' ' NOT NULL,
    "日期" char(8) DEFAULT '00000000' NOT NULL,
    "幣別" varchar(3) DEFAULT ' ' NOT NULL,
    "金額" numeric(14,4) DEFAULT 0 NOT NULL,
    "稅額" numeric(14,4) DEFAULT 0 NOT NULL,
    "備註" varchar(100) DEFAULT ' ' NOT NULL,
    "付款條件" varchar(10) DEFAULT ' ' NOT NULL,
    "流水編號" varchar(60) DEFAULT ' ' NOT NULL,
    "最後更新者" varchar(10) DEFAULT ' ' NOT NULL,
    "最後更新日" timestamp(0),
    PRIMARY KEY ("單據類別", "單據編號", "單據序號")
);
COMMENT ON TABLE "fil0042" IS '0.費用明細檔';
COMMENT ON COLUMN "fil0042"."最後更新日" IS '最後更新日 / 最後更新時';

-- Files：0.條碼管理檔
CREATE TABLE "fil0043" (
    "條碼" varchar(40) NOT NULL,
    "單別" varchar(10) DEFAULT ' ' NOT NULL,
    "單號" varchar(20) DEFAULT ' ' NOT NULL,
    "序號" smallint DEFAULT 0 NOT NULL,
    "qrno" smallint DEFAULT 0 NOT NULL,
    "廠客" varchar(10) DEFAULT ' ' NOT NULL,
    "日期" char(8) DEFAULT '00000000' NOT NULL,
    "料號" varchar(30) DEFAULT ' ' NOT NULL,
    "幅寬" varchar(30) DEFAULT ' ' NOT NULL,
    "接頭數" integer DEFAULT 0 NOT NULL,
    "公司代碼" varchar(1) DEFAULT ' ' NOT NULL,
    "驗收倉" varchar(10) DEFAULT ' ' NOT NULL,
    "選擇" smallint DEFAULT 0 NOT NULL,
    "廠商料號" varchar(40) DEFAULT ' ' NOT NULL,
    "廠商規格" varchar(40) DEFAULT ' ' NOT NULL,
    "廠商批號" varchar(40) DEFAULT ' ' NOT NULL,
    "guid" varchar(60) DEFAULT ' ' NOT NULL,
    "數量" numeric(14,4) DEFAULT 0 NOT NULL,
    "單位" varchar(10) DEFAULT ' ' NOT NULL,
    "庫存異動數" numeric(14,4) DEFAULT 0 NOT NULL,
    "製造日期" char(8) DEFAULT '00000000' NOT NULL,
    "標籤類別" varchar(2) DEFAULT ' ' NOT NULL,
    "批次匯入" smallint DEFAULT 0 NOT NULL,
    "結算日期" char(8) DEFAULT '00000000' NOT NULL,
    "庫存結算數" numeric(14,4) DEFAULT 0 NOT NULL,
    "填表人" varchar(10) DEFAULT ' ' NOT NULL,
    "填表日" timestamp(0),
    "最後更新者" varchar(10) DEFAULT ' ' NOT NULL,
    "最後更新日" timestamp(0),
    PRIMARY KEY ("條碼")
);
CREATE UNIQUE INDEX "fil0043_02" ON "fil0043" ("日期", "條碼");
CREATE INDEX "fil0043_03" ON "fil0043" ("單別", "單號", "序號", "qrno");
CREATE UNIQUE INDEX "fil0043_04" ON "fil0043" ("廠客", "日期", "條碼");
CREATE UNIQUE INDEX "fil0043_05" ON "fil0043" ("料號", "條碼");
COMMENT ON TABLE "fil0043" IS '0.條碼管理檔';
COMMENT ON COLUMN "fil0043"."日期" IS '收料日期';
COMMENT ON COLUMN "fil0043"."guid" IS '臨時編號';
COMMENT ON COLUMN "fil0043"."數量" IS '起始採購數量(ex.RS)';
COMMENT ON COLUMN "fil0043"."庫存異動數" IS '起始庫存異動數(ex.米)';
COMMENT ON COLUMN "fil0043"."庫存結算數" IS '庫存結算數(ex.米)';
COMMENT ON COLUMN "fil0043"."填表日" IS '填表日 / 填表時';
COMMENT ON COLUMN "fil0043"."最後更新日" IS '最後更新日 / 最後更新時';

-- Files：0.條碼異動檔
CREATE TABLE "fil0044" (
    "條碼" varchar(40) NOT NULL,
    "序號" smallint DEFAULT 0 NOT NULL,
    "單據類別" varchar(10) DEFAULT ' ' NOT NULL,
    "單據號碼" varchar(20) DEFAULT ' ' NOT NULL,
    "單據序號" smallint DEFAULT 0 NOT NULL,
    "庫位" varchar(40) DEFAULT ' ' NOT NULL,
    "異動數量" numeric(14,4) DEFAULT 0 NOT NULL,
    "異動日期" char(8) DEFAULT '00000000' NOT NULL,
    "異動時間" char(6) DEFAULT '000000' NOT NULL,
    "異動人代號" varchar(10) DEFAULT ' ' NOT NULL,
    "來源" varchar(1) DEFAULT ' ' NOT NULL,
    "其它單號" varchar(20) DEFAULT ' ' NOT NULL,
    "其它單號1" varchar(20) DEFAULT ' ' NOT NULL,
    "其它單號2" varchar(20) DEFAULT ' ' NOT NULL,
    "請領料號" varchar(30) DEFAULT ' ' NOT NULL,
    "其它日期1" char(8) DEFAULT '00000000' NOT NULL,
    "備註" varchar(50) DEFAULT ' ' NOT NULL
);
CREATE UNIQUE INDEX "fil0044_01" ON "fil0044" ("條碼", "序號");
CREATE INDEX "fil0044_02" ON "fil0044" ("單據類別", "單據號碼", "單據序號", "條碼", "異動日期", "異動時間");
CREATE INDEX "fil0044_03" ON "fil0044" ("條碼", "庫位", "異動日期", "異動時間");
CREATE INDEX "fil0044_04" ON "fil0044" ("異動人代號", "異動日期", "異動時間");
COMMENT ON TABLE "fil0044" IS '0.條碼異動檔';
COMMENT ON COLUMN "fil0044"."異動數量" IS '數量(ex.RS)';
COMMENT ON COLUMN "fil0044"."其它單號" IS '請領單號';
COMMENT ON COLUMN "fil0044"."其它單號1" IS '製令單號';
COMMENT ON COLUMN "fil0044"."其它單號2" IS '日報單號';

-- Files：0.條碼列印記錄
CREATE TABLE "fil0044a" (
    "條碼" varchar(40) DEFAULT ' ' NOT NULL,
    "序號" smallint DEFAULT 0 NOT NULL,
    "列印日期" char(8) DEFAULT '00000000' NOT NULL,
    "列印時間" char(6) DEFAULT '000000' NOT NULL,
    "列印人代號" varchar(10) DEFAULT ' ' NOT NULL,
    "廠商規格" varchar(40) DEFAULT ' ' NOT NULL,
    "廠商批號" varchar(40) DEFAULT ' ' NOT NULL,
    "來源" varchar(1) DEFAULT ' ' NOT NULL,
    "細分" smallint DEFAULT 0 NOT NULL,
    "開立" smallint DEFAULT 0 NOT NULL,
    "列印批號" varchar(60) DEFAULT ' ' NOT NULL
);
CREATE UNIQUE INDEX "fil0044a_01" ON "fil0044a" ("條碼", "序號");
CREATE UNIQUE INDEX "fil0044akey2" ON "fil0044a" ("列印批號", "條碼", "序號");
COMMENT ON TABLE "fil0044a" IS '0.條碼列印記錄';

-- Files：0.總標籤位置
CREATE TABLE "fil0044b" (
    "產品標籤" varchar(46) DEFAULT ' ' NOT NULL,
    "最後總標籤" varchar(40) DEFAULT ' ' NOT NULL
);
CREATE UNIQUE INDEX "fil0044bkey1" ON "fil0044b" ("產品標籤");
COMMENT ON TABLE "fil0044b" IS '0.總標籤位置';

-- Files：xx0.半成品領用
CREATE TABLE "fil0045" (
    "流水編號" varchar(60) DEFAULT ' ' NOT NULL,
    "領用編號" varchar(60) DEFAULT ' ' NOT NULL,
    "領用日期" char(8) DEFAULT '00000000' NOT NULL,
    "庫別代碼" varchar(10) DEFAULT ' ' NOT NULL,
    "領用數量" numeric(14,4) DEFAULT 0 NOT NULL,
    "最後更新者" varchar(10) DEFAULT ' ' NOT NULL,
    "最後更新日" timestamp(0),
    PRIMARY KEY ("流水編號", "領用編號")
);
COMMENT ON TABLE "fil0045" IS 'xx0.半成品領用';
COMMENT ON COLUMN "fil0045"."領用編號" IS '領用編號(條碼)';
COMMENT ON COLUMN "fil0045"."最後更新日" IS '最後更新日 / 最後更新時';

-- Files：xx0.油墨領用檔
CREATE TABLE "fil0046" (
    "流水編號" varchar(60) DEFAULT ' ' NOT NULL,
    "批號" varchar(40) DEFAULT ' ' NOT NULL,
    "物料編號" varchar(20) DEFAULT ' ' NOT NULL,
    "領用日期" char(8) DEFAULT '00000000' NOT NULL,
    "領用數量" numeric(14,4) DEFAULT 0 NOT NULL,
    "單位代碼" varchar(10) DEFAULT ' ' NOT NULL,
    "庫別代碼" varchar(10) DEFAULT ' ' NOT NULL,
    "最後更新者" varchar(10) DEFAULT ' ' NOT NULL,
    "最後更新日" timestamp(0),
    PRIMARY KEY ("流水編號", "物料編號")
);
COMMENT ON TABLE "fil0046" IS 'xx0.油墨領用檔';
COMMENT ON COLUMN "fil0046"."最後更新日" IS '最後更新日 / 最後更新時';

-- Files：0.加熱器名稱
CREATE TABLE "fil0047" (
    "加熱器序號" numeric(10,0) DEFAULT 0 NOT NULL,
    "製程代碼" varchar(10) DEFAULT ' ' NOT NULL,
    "機台代碼" varchar(10) DEFAULT ' ' NOT NULL,
    "機台序號" smallint DEFAULT 0 NOT NULL,
    "名稱" varchar(20) DEFAULT ' ' NOT NULL,
    "最後更新者" varchar(10) DEFAULT ' ' NOT NULL,
    "最後更新日" timestamp(0),
    PRIMARY KEY ("加熱器序號")
);
CREATE INDEX "fil0047_02" ON "fil0047" ("製程代碼", "機台代碼", "機台序號");
COMMENT ON TABLE "fil0047" IS '0.加熱器名稱';
COMMENT ON COLUMN "fil0047"."最後更新日" IS '最後更新日 / 最後更新時';

-- Files：0.加熱器溫度
CREATE TABLE "fil0048" (
    "單別" varchar(10) DEFAULT ' ' NOT NULL,
    "單號" varchar(20) DEFAULT ' ' NOT NULL,
    "序號" numeric(10,0) DEFAULT 0 NOT NULL,
    "時間" char(6) DEFAULT '000000' NOT NULL,
    "加熱器序號" numeric(10,0) DEFAULT 0 NOT NULL,
    "加熱器溫度" smallint DEFAULT 0 NOT NULL,
    "最後更新者" varchar(10) DEFAULT ' ' NOT NULL,
    "最後更新日" timestamp(0),
    PRIMARY KEY ("單別", "單號", "時間", "加熱器序號")
);
CREATE UNIQUE INDEX "fil0048_02" ON "fil0048" ("單別", "單號", "序號", "時間", "加熱器序號");
COMMENT ON TABLE "fil0048" IS '0.加熱器溫度';
COMMENT ON COLUMN "fil0048"."單別" IS '單別(C41)';
COMMENT ON COLUMN "fil0048"."單號" IS '單號(C41)';
COMMENT ON COLUMN "fil0048"."最後更新日" IS '最後更新日 / 最後更新時';

-- Files：0.自主檢查檔
CREATE TABLE "fil0049" (
    "單別" varchar(10) DEFAULT ' ' NOT NULL,
    "單號" varchar(20) DEFAULT ' ' NOT NULL,
    "序號" smallint DEFAULT 0 NOT NULL,
    "時間" char(6) DEFAULT '000000' NOT NULL,
    "執行測漏試驗_至少連續五個" smallint,
    "執行熱封強度測試" smallint,
    "袋內無粉與無沾粘異物" smallint,
    "袋子無雙頭封" smallint,
    "夾邊左右無大小邊與尺寸正確" smallint,
    "碗公或K模高低位置平均" smallint,
    "切刀鋒利無毛邊與開口性佳" smallint,
    "打角完整無毛邊與斷屑完全" smallint,
    "夾鏈緊密牢度佳與無破裂" smallint,
    "封邊上下" integer DEFAULT 0 NOT NULL,
    "封邊背邊側" integer DEFAULT 0 NOT NULL,
    "打角" integer DEFAULT 0 NOT NULL,
    "夾鏈" integer DEFAULT 0 NOT NULL,
    "圓孔" integer DEFAULT 0 NOT NULL,
    "透氣孔" integer DEFAULT 0 NOT NULL,
    "最後更新者" varchar(10) DEFAULT ' ' NOT NULL,
    "最後更新日" timestamp(0),
    PRIMARY KEY ("單別", "單號", "時間")
);
CREATE UNIQUE INDEX "fil0049_02" ON "fil0049" ("單別", "單號", "序號", "時間");
COMMENT ON TABLE "fil0049" IS '0.自主檢查檔';
COMMENT ON COLUMN "fil0049"."單別" IS '單別(C41)';
COMMENT ON COLUMN "fil0049"."單號" IS '單號(C41)';
COMMENT ON COLUMN "fil0049"."最後更新日" IS '最後更新日 / 最後更新時';

-- Files：0.標籤列印記錄
CREATE TABLE "fil004a" (
    "單據類別" varchar(10) DEFAULT ' ' NOT NULL,
    "單據編號" varchar(20) DEFAULT ' ' NOT NULL,
    "單據序號" smallint DEFAULT 0 NOT NULL,
    "標籤類別" varchar(2) NOT NULL,
    "標籤機代碼" varchar(20) DEFAULT ' ' NOT NULL,
    "流水編號" varchar(60) DEFAULT ' ' NOT NULL,
    "最後更新者" varchar(10) DEFAULT ' ' NOT NULL,
    "最後更新日" timestamp(0),
    "製令單號" varchar(20) DEFAULT ' ' NOT NULL,
    "箱號" smallint DEFAULT 0 NOT NULL,
    "製造日期" char(8) DEFAULT '00000000' NOT NULL,
    "有效日期" char(8) DEFAULT '00000000' NOT NULL,
    "數量" numeric(14,4) DEFAULT 0 NOT NULL,
    "重量" numeric(14,4) DEFAULT 0 NOT NULL,
    "細分" smallint DEFAULT 0 NOT NULL,
    "料號" varchar(60) DEFAULT ' ' NOT NULL,
    "退庫" smallint DEFAULT 0 NOT NULL
);
CREATE INDEX "fil004a_01" ON "fil004a" ("單據類別", "單據編號", "單據序號", "最後更新日");
CREATE UNIQUE INDEX "fil004a_02" ON "fil004a" ("流水編號");
CREATE INDEX "fil004a_03" ON "fil004a" ("製令單號", "製造日期");
COMMENT ON TABLE "fil004a" IS '0.標籤列印記錄';
COMMENT ON COLUMN "fil004a"."最後更新日" IS '最後更新日 / 最後更新時';

-- Files：0.製成品屬性
CREATE TABLE "fil004b" (
    "製令單號" varchar(20) DEFAULT ' ' NOT NULL,
    "箱號" numeric(14,4) NOT NULL,
    "成品編號" varchar(20) DEFAULT ' ' NOT NULL,
    "製袋" smallint DEFAULT 0 NOT NULL,
    "氣閥" smallint DEFAULT 0 NOT NULL,
    "鐵條" smallint DEFAULT 0 NOT NULL,
    "檢品" smallint DEFAULT 0 NOT NULL,
    "重工" smallint DEFAULT 0 NOT NULL,
    "氣閥重量" numeric(13,3) DEFAULT 0 NOT NULL,
    "條鐵重量" numeric(13,3) DEFAULT 0 NOT NULL
);
CREATE UNIQUE INDEX "fil004b_01" ON "fil004b" ("製令單號", "箱號");
COMMENT ON TABLE "fil004b" IS '0.製成品屬性';
COMMENT ON COLUMN "fil004b"."條鐵重量" IS '鐵條重量';

-- Files：0.檢驗水準
CREATE TABLE "fil004c" (
    "生產數量起" numeric(10,0) DEFAULT 0 NOT NULL,
    "抽樣數量" numeric(10,0) DEFAULT 0 NOT NULL,
    "允收數" numeric(10,0) DEFAULT 0 NOT NULL,
    "拒收數" numeric(10,0) DEFAULT 0 NOT NULL
);
CREATE UNIQUE INDEX "fil004c_01" ON "fil004c" ("生產數量起");
COMMENT ON TABLE "fil004c" IS '0.檢驗水準';

-- Files：0.版銅入庫檔
CREATE TABLE "fil004d" (
    "版銅代碼" varchar(20) NOT NULL,
    "入庫日期" char(8) DEFAULT '00000000' NOT NULL,
    "入庫時間" char(6) DEFAULT '000000' NOT NULL,
    "庫別代碼" varchar(10) DEFAULT ' ' NOT NULL,
    "歸屬流水編號" varchar(60) DEFAULT ' ' NOT NULL,
    "送修" smallint DEFAULT 0 NOT NULL,
    "回廠" smallint DEFAULT 0 NOT NULL,
    "回廠日期" timestamp(0),
    "流水編號" varchar(60) DEFAULT ' ' NOT NULL,
    "最後更新者" varchar(10) DEFAULT ' ' NOT NULL,
    "最後更新日" timestamp(0),
    PRIMARY KEY ("版銅代碼", "入庫日期", "入庫時間")
);
CREATE INDEX "fil004d_02" ON "fil004d" ("歸屬流水編號");
COMMENT ON TABLE "fil004d" IS '0.版銅入庫檔';
COMMENT ON COLUMN "fil004d"."歸屬流水編號" IS '歸屬流水編號(送修出庫)';
COMMENT ON COLUMN "fil004d"."回廠日期" IS '回廠日期 / 回廠時間';
COMMENT ON COLUMN "fil004d"."最後更新日" IS '最後更新日 / 最後更新時';

-- Files：0.版銅異動檔
CREATE TABLE "fil004e" (
    "序號" numeric(10,0) DEFAULT 0 NOT NULL,
    "版銅代碼" varchar(20) DEFAULT ' ' NOT NULL,
    "類別" varchar(1) DEFAULT ' ' NOT NULL,
    "歸屬代碼" varchar(60) DEFAULT ' ' NOT NULL,
    "最後更新者" varchar(10) DEFAULT ' ' NOT NULL,
    "最後更新日" timestamp(0),
    PRIMARY KEY ("序號")
);
CREATE UNIQUE INDEX "fil004e_02" ON "fil004e" ("版銅代碼", "序號");
CREATE UNIQUE INDEX "fil004e_03" ON "fil004e" ("歸屬代碼", "序號");
COMMENT ON TABLE "fil004e" IS '0.版銅異動檔';
COMMENT ON COLUMN "fil004e"."最後更新日" IS '最後更新日 / 最後更新時';

-- Files：0.裁切OPRP檢查
CREATE TABLE "fil004f" (
    "單別" varchar(10) DEFAULT ' ' NOT NULL,
    "單號" varchar(20) DEFAULT ' ' NOT NULL,
    "序號" numeric(10,0) DEFAULT 0 NOT NULL,
    "日期" char(8) DEFAULT '00000000' NOT NULL,
    "時間" char(6) DEFAULT '000000' NOT NULL,
    "平刀" smallint DEFAULT 0 NOT NULL,
    "平刀數量" numeric(10,0) DEFAULT 0 NOT NULL,
    "圓刀" smallint DEFAULT 0 NOT NULL,
    "圓刀數量" numeric(10,0) DEFAULT 0 NOT NULL,
    "完整度" varchar(10) DEFAULT ' ' NOT NULL,
    "合格" smallint DEFAULT 1 NOT NULL,
    "最後更新者" varchar(10) DEFAULT ' ' NOT NULL,
    "最後更新日" timestamp(0)
);
CREATE UNIQUE INDEX "fil004fkey1" ON "fil004f" ("單別", "單號", "序號");
COMMENT ON TABLE "fil004f" IS '0.裁切OPRP檢查';
COMMENT ON COLUMN "fil004f"."單別" IS '單別(C41)';
COMMENT ON COLUMN "fil004f"."單號" IS '單號(C41)';
COMMENT ON COLUMN "fil004f"."最後更新日" IS '最後更新日 / 最後更新時';

-- Files：0.報價對應估價明細
CREATE TABLE "fil004g" (
    "單別" varchar(10) DEFAULT ' ' NOT NULL,
    "單號" varchar(20) DEFAULT ' ' NOT NULL,
    "序號" numeric(4,0) DEFAULT 0 NOT NULL,
    "類別" varchar(1) DEFAULT ' ' NOT NULL,
    "價格倍率" numeric(5,2) DEFAULT 0 NOT NULL,
    "合計價格" numeric(14,4) DEFAULT 0 NOT NULL,
    "單價" numeric(14,4) DEFAULT 0 NOT NULL,
    "購買數量" numeric(14,4) DEFAULT 0 NOT NULL,
    "總價" numeric(14,4) DEFAULT 0 NOT NULL,
    "色數" numeric(14,4) DEFAULT 0 NOT NULL,
    "每色製版費" numeric(14,4) DEFAULT 0 NOT NULL,
    "製版費" numeric(14,4) DEFAULT 0 NOT NULL,
    "燙金費" numeric(14,4) DEFAULT 0 NOT NULL,
    "雷射開窗" numeric(14,4) DEFAULT 0 NOT NULL,
    "夾鏈費" numeric(14,4) DEFAULT 0 NOT NULL,
    "氣閥費" numeric(14,4) DEFAULT 0 NOT NULL,
    "鐵條費" numeric(14,4) DEFAULT 0 NOT NULL,
    "未稅金額" numeric(14,4),
    "應稅金額" numeric(14,4) DEFAULT 0 NOT NULL,
    "備註" varchar(400) DEFAULT ' ' NOT NULL,
    "估價流水編號" varchar(60) DEFAULT ' ' NOT NULL,
    "最後更新者" varchar(10) DEFAULT ' ' NOT NULL,
    "更新者姓名" varchar(20) DEFAULT ' ',
    "最後更新日" timestamp(0)
);
CREATE UNIQUE INDEX "fil004gkey1" ON "fil004g" ("單別", "單號", "序號");
COMMENT ON TABLE "fil004g" IS '0.報價對應估價明細';
COMMENT ON COLUMN "fil004g"."最後更新日" IS '最後更新日 / 最後更新日_time';

-- Files：0.成品批號庫存
CREATE TABLE "fil004h" (
    "批號" varchar(40) DEFAULT ' ' NOT NULL,
    "製袋" smallint DEFAULT 0 NOT NULL,
    "氣閥" smallint DEFAULT 0 NOT NULL,
    "鐵條" smallint DEFAULT 0 NOT NULL,
    "異動" smallint DEFAULT 0 NOT NULL,
    "重工" smallint DEFAULT 0 NOT NULL,
    "品檢" smallint DEFAULT 0 NOT NULL,
    "成品編號" varchar(20) DEFAULT ' ' NOT NULL,
    "生產日期" char(8) NOT NULL,
    "結存數量" numeric(14,4) DEFAULT 0 NOT NULL,
    "製袋重量" numeric(14,4) DEFAULT 0 NOT NULL,
    "氣閥重量" numeric(14,4) DEFAULT 0 NOT NULL,
    "鐵條重量" numeric(14,4) DEFAULT 0 NOT NULL,
    "紙箱重量" numeric(14,4) DEFAULT 0 NOT NULL,
    "結存重量" numeric(14,4) DEFAULT 0 NOT NULL,
    "結算日期" char(8) DEFAULT '00000000' NOT NULL,
    "結算時間" char(6) DEFAULT '000000' NOT NULL,
    PRIMARY KEY ("批號")
);
COMMENT ON TABLE "fil004h" IS '0.成品批號庫存';

-- Files：0.積層CCP檢查
CREATE TABLE "fil004i" (
    "單別" varchar(10) DEFAULT ' ' NOT NULL,
    "單號" varchar(20) DEFAULT ' ' NOT NULL,
    "序號" numeric(10,0) DEFAULT 0 NOT NULL,
    "日期" char(8) DEFAULT '00000000' NOT NULL,
    "時間" char(6) DEFAULT '000000' NOT NULL,
    "烘箱1" numeric(11,1) DEFAULT 0 NOT NULL,
    "烘箱2" numeric(11,1) DEFAULT 0 NOT NULL,
    "烘箱3" numeric(11,1) DEFAULT 0 NOT NULL,
    "烘箱4" numeric(11,1) DEFAULT 0 NOT NULL,
    "烘箱5" numeric(11,1) DEFAULT 0 NOT NULL,
    "烘箱6" numeric(11,1) DEFAULT 0 NOT NULL,
    "烘箱7" numeric(11,1) DEFAULT 0 NOT NULL,
    "烘箱8" numeric(11,1) DEFAULT 0 NOT NULL,
    "烘箱9" numeric(11,1) DEFAULT 0 NOT NULL,
    "烘箱10" numeric(11,1) DEFAULT 0 NOT NULL,
    "烘箱11" numeric(11,1) DEFAULT 0 NOT NULL,
    "logical1" smallint DEFAULT 0 NOT NULL,
    "logical2" smallint DEFAULT 0 NOT NULL,
    "logical3" smallint DEFAULT 0 NOT NULL,
    "logical4" smallint DEFAULT 0 NOT NULL,
    "logical5" smallint DEFAULT 0 NOT NULL,
    "logical6" smallint DEFAULT 0 NOT NULL,
    "logical7" smallint DEFAULT 0 NOT NULL,
    "logical8" smallint DEFAULT 0 NOT NULL,
    "logical9" smallint DEFAULT 0 NOT NULL,
    "logical10" smallint DEFAULT 0 NOT NULL,
    "logical11" smallint DEFAULT 0 NOT NULL,
    "最後更新者" varchar(10) DEFAULT ' ' NOT NULL,
    "最後更新日" timestamp(0)
);
CREATE UNIQUE INDEX "fil004ikey1" ON "fil004i" ("單別", "單號", "序號");
COMMENT ON TABLE "fil004i" IS '0.積層CCP檢查';
COMMENT ON COLUMN "fil004i"."單別" IS '單別(C41)';
COMMENT ON COLUMN "fil004i"."單號" IS '單號(C41)';
COMMENT ON COLUMN "fil004i"."最後更新日" IS '最後更新日 / 最後更新時';

-- Files：0.熟成室管制歷履
CREATE TABLE "fil004j" (
    "單別" varchar(10) DEFAULT ' ' NOT NULL,
    "單號" varchar(20) DEFAULT ' ' NOT NULL,
    "序號" numeric(4,0) DEFAULT 0 NOT NULL,
    "製程" varchar(10) DEFAULT ' ' NOT NULL,
    "製令類別" varchar(10) DEFAULT ' ' NOT NULL,
    "製令單號" varchar(20) DEFAULT ' ' NOT NULL,
    "產品編號" varchar(30) DEFAULT ' ' NOT NULL,
    "產品名稱" varchar(100) DEFAULT ' ' NOT NULL,
    "熟成入庫日期" char(8) DEFAULT '00000000' NOT NULL,
    "熟成入庫時間" char(6) DEFAULT '000000' NOT NULL,
    "入庫人員姓名" varchar(20) DEFAULT ' ' NOT NULL,
    "熟成出庫日期" char(8) DEFAULT '00000000' NOT NULL,
    "熟成出庫時間" char(6) DEFAULT '000000' NOT NULL,
    "出庫人員姓名" varchar(20) DEFAULT ' ' NOT NULL,
    "應入庫日時" char(8) NOT NULL,
    "應入庫日期" char(6) DEFAULT ' ' NOT NULL,
    "應出庫日時起" timestamp(0) NOT NULL,
    "應出庫日時迄" timestamp(0) NOT NULL,
    "本製程編號" varchar(70) DEFAULT ' ' NOT NULL,
    "PLC抓取米數" numeric(14,4) DEFAULT 0 NOT NULL,
    "庫存數" numeric(14,4) DEFAULT 0 NOT NULL,
    "製品厚度" numeric(14,4) DEFAULT 0 NOT NULL,
    "熟成條件" varchar(100) DEFAULT ' ' NOT NULL,
    "熟成狀態" varchar(1) DEFAULT ' ' NOT NULL,
    "入庫狀態" varchar(1) DEFAULT ' ' NOT NULL,
    "出庫狀態" varchar(1) DEFAULT ' ' NOT NULL,
    "可提早出庫" smallint DEFAULT 0 NOT NULL,
    "放行人員姓名" varchar(20) DEFAULT ' ' NOT NULL,
    "不限出庫設定姓名" varchar(20) DEFAULT ' ' NOT NULL,
    "不限出庫時間" smallint DEFAULT 0 NOT NULL,
    "IP位址" varchar(40) DEFAULT ' ' NOT NULL,
    "IP位址2" varchar(40) DEFAULT ' ' NOT NULL,
    "熟成室位置" varchar(20) DEFAULT ' ' NOT NULL,
    "加工別" varchar(1) DEFAULT ' ' NOT NULL,
    "單頭流水編號" varchar(60) DEFAULT ' ' NOT NULL,
    "超時未入庫" smallint DEFAULT 0 NOT NULL,
    "異常" smallint DEFAULT 0 NOT NULL,
    "流水編號" varchar(60) DEFAULT ' ' NOT NULL,
    "異動日期" char(8) DEFAULT '00000000' NOT NULL,
    "異動時間" char(6) DEFAULT '000000' NOT NULL,
    "異動人員" varchar(10) DEFAULT ' ' NOT NULL
);
CREATE UNIQUE INDEX "fil004j_key1" ON "fil004j" ("流水編號");
CREATE INDEX "fil004j_key2" ON "fil004j" ("單別", "單號", "序號");
COMMENT ON TABLE "fil004j" IS '0.熟成室管制歷履';
COMMENT ON COLUMN "fil004j"."應入庫日時" IS '應入庫日期';
COMMENT ON COLUMN "fil004j"."應入庫日期" IS '應入庫時間';
COMMENT ON COLUMN "fil004j"."應出庫日時起" IS '應出庫日期起 / 應出庫時間起';
COMMENT ON COLUMN "fil004j"."應出庫日時迄" IS '應出庫日期迄 / 應出庫時間迄';

-- Files：0.冷鏈室管制歷履
CREATE TABLE "fil004ja" (
    "單別" varchar(10) DEFAULT ' ' NOT NULL,
    "單號" varchar(20) DEFAULT ' ' NOT NULL,
    "序號" numeric(4,0) DEFAULT 0 NOT NULL,
    "製程" varchar(10) DEFAULT ' ' NOT NULL,
    "製令類別" varchar(10) DEFAULT ' ' NOT NULL,
    "製令單號" varchar(20) DEFAULT ' ' NOT NULL,
    "產品編號" varchar(30) DEFAULT ' ' NOT NULL,
    "產品名稱" varchar(100) DEFAULT ' ' NOT NULL,
    "冷鏈入庫日期" char(8) DEFAULT '00000000' NOT NULL,
    "冷鏈入庫時間" char(6) DEFAULT '000000' NOT NULL,
    "入庫人員姓名" varchar(20) DEFAULT ' ' NOT NULL,
    "冷鏈出庫日期" char(8) DEFAULT '00000000' NOT NULL,
    "冷鏈出庫時間" char(6) DEFAULT '000000' NOT NULL,
    "出庫人員姓名" varchar(20) DEFAULT ' ' NOT NULL,
    "應入庫日時" char(8) NOT NULL,
    "應入庫日期" char(6) DEFAULT ' ' NOT NULL,
    "應出庫日時起" timestamp(0) NOT NULL,
    "應出庫日時迄" timestamp(0) NOT NULL,
    "本製程編號" varchar(70) DEFAULT ' ' NOT NULL,
    "PLC抓取米數" numeric(14,4) DEFAULT 0 NOT NULL,
    "庫存數" numeric(14,4) DEFAULT 0 NOT NULL,
    "製品厚度" numeric(14,4) DEFAULT 0 NOT NULL,
    "冷鏈條件" varchar(100) DEFAULT ' ' NOT NULL,
    "冷鏈狀態" varchar(1) DEFAULT ' ' NOT NULL,
    "入庫狀態" varchar(1) DEFAULT ' ' NOT NULL,
    "出庫狀態" varchar(1) DEFAULT ' ' NOT NULL,
    "可提早出庫" smallint DEFAULT 0 NOT NULL,
    "放行人員姓名" varchar(20) DEFAULT ' ' NOT NULL,
    "不限出庫設定姓名" varchar(20) DEFAULT ' ' NOT NULL,
    "不限出庫時間" smallint DEFAULT 0 NOT NULL,
    "IP位址" varchar(40) DEFAULT ' ' NOT NULL,
    "IP位址2" varchar(40) DEFAULT ' ' NOT NULL,
    "冷鏈室位置" varchar(20) DEFAULT ' ' NOT NULL,
    "加工別" varchar(1) DEFAULT ' ' NOT NULL,
    "單頭流水編號" varchar(60) DEFAULT ' ' NOT NULL,
    "超時未入庫" smallint DEFAULT 0 NOT NULL,
    "異常" smallint DEFAULT 0 NOT NULL,
    "流水編號" varchar(60) DEFAULT ' ' NOT NULL,
    "異動日期" char(8) DEFAULT '00000000' NOT NULL,
    "異動時間" char(6) DEFAULT '000000' NOT NULL,
    "異動人員" varchar(10) DEFAULT ' ' NOT NULL
);
CREATE UNIQUE INDEX "fil004ja_key1" ON "fil004ja" ("流水編號");
CREATE INDEX "fil004ja_key2" ON "fil004ja" ("單別", "單號", "序號");
COMMENT ON TABLE "fil004ja" IS '0.冷鏈室管制歷履';
COMMENT ON COLUMN "fil004ja"."應入庫日時" IS '應入庫日期';
COMMENT ON COLUMN "fil004ja"."應入庫日期" IS '應入庫時間';
COMMENT ON COLUMN "fil004ja"."應出庫日時起" IS '應出庫日期起 / 應出庫時間起';
COMMENT ON COLUMN "fil004ja"."應出庫日時迄" IS '應出庫日期迄 / 應出庫時間迄';

-- Files：0.熟成室其它製程轉入
CREATE TABLE "fil004k" (
    "單別" varchar(10) DEFAULT ' ' NOT NULL,
    "單號" varchar(20) DEFAULT ' ' NOT NULL,
    "序號" numeric(4,0) DEFAULT 0 NOT NULL,
    "製程代碼" varchar(10) DEFAULT ' ' NOT NULL,
    "製令類別" varchar(10) DEFAULT ' ' NOT NULL,
    "製令單號" varchar(20) DEFAULT ' ' NOT NULL,
    "熟成入庫日期" char(8) DEFAULT '00000000' NOT NULL,
    "熟成入庫時間" char(6) DEFAULT '000000' NOT NULL,
    "熟成入庫時間2" char(6) DEFAULT '000000' NOT NULL,
    "入庫人員" varchar(10) DEFAULT ' ' NOT NULL,
    "熟成出庫日期" char(8) DEFAULT '00000000' NOT NULL,
    "熟成出庫時間" char(6) DEFAULT '000000' NOT NULL,
    "熟成出庫時間2" char(6) DEFAULT '000000' NOT NULL,
    "出庫人員" varchar(10) DEFAULT ' ' NOT NULL,
    "應入庫日時" char(8) NOT NULL,
    "應入庫日期" char(6) DEFAULT ' ' NOT NULL,
    "應出庫日時起" timestamp(0) NOT NULL,
    "應出庫日時迄" timestamp(0) NOT NULL,
    "本製程編號" varchar(70) DEFAULT ' ' NOT NULL,
    "PLC抓取米數" numeric(14,4) DEFAULT 0 NOT NULL,
    "庫存數" numeric(14,4) DEFAULT 0 NOT NULL,
    "製品厚度" numeric(14,4) DEFAULT 0 NOT NULL,
    "熟成條件" varchar(100) DEFAULT ' ' NOT NULL,
    "熟成狀態" varchar(1) DEFAULT ' ' NOT NULL,
    "入庫狀態" varchar(1) DEFAULT ' ' NOT NULL,
    "出庫狀態" varchar(1) DEFAULT ' ' NOT NULL,
    "可提早出庫" smallint DEFAULT 0 NOT NULL,
    "放行人員" varchar(20) DEFAULT ' ' NOT NULL,
    "不限出庫設定人員" varchar(20) DEFAULT ' ' NOT NULL,
    "不限出庫時間" smallint DEFAULT 0 NOT NULL,
    "IP位址" varchar(40) DEFAULT ' ' NOT NULL,
    "IP位址2" varchar(40) DEFAULT ' ' NOT NULL,
    "加工別" varchar(1) DEFAULT ' ' NOT NULL,
    "單頭流水編號" varchar(60) DEFAULT ' ' NOT NULL,
    "超時未入庫" smallint DEFAULT 0 NOT NULL,
    "異常" smallint DEFAULT 0 NOT NULL,
    "重覆入庫" smallint DEFAULT 0 NOT NULL,
    "異動日期" char(8) DEFAULT '00000000' NOT NULL,
    "異動時間" char(6) DEFAULT '000000' NOT NULL,
    "異動人員" varchar(10) DEFAULT ' ' NOT NULL
);
CREATE UNIQUE INDEX "fil004k_key1" ON "fil004k" ("單別", "單號", "序號");
COMMENT ON TABLE "fil004k" IS '0.熟成室其它製程轉入';
COMMENT ON COLUMN "fil004k"."應入庫日時" IS '應入庫日期';
COMMENT ON COLUMN "fil004k"."應入庫日期" IS '應入庫時間';
COMMENT ON COLUMN "fil004k"."應出庫日時起" IS '應出庫日期起 / 應出庫時間起';
COMMENT ON COLUMN "fil004k"."應出庫日時迄" IS '應出庫日期迄 / 應出庫時間迄';

-- Files：0.冷鏈室其它製程轉入
CREATE TABLE "fil004ka" (
    "單別" varchar(10) DEFAULT ' ' NOT NULL,
    "單號" varchar(20) DEFAULT ' ' NOT NULL,
    "序號" numeric(4,0) DEFAULT 0 NOT NULL,
    "製程代碼" varchar(10) DEFAULT ' ' NOT NULL,
    "製令類別" varchar(10) DEFAULT ' ' NOT NULL,
    "製令單號" varchar(20) DEFAULT ' ' NOT NULL,
    "熟成入庫日期" char(8) DEFAULT '00000000' NOT NULL,
    "熟成入庫時間" char(6) DEFAULT '000000' NOT NULL,
    "熟成入庫時間2" char(6) DEFAULT '000000' NOT NULL,
    "入庫人員" varchar(10) DEFAULT ' ' NOT NULL,
    "熟成出庫日期" char(8) DEFAULT '00000000' NOT NULL,
    "熟成出庫時間" char(6) DEFAULT '000000' NOT NULL,
    "熟成出庫時間2" char(6) DEFAULT '000000' NOT NULL,
    "出庫人員" varchar(10) DEFAULT ' ' NOT NULL,
    "應入庫日時" char(8) NOT NULL,
    "應入庫日期" char(6) DEFAULT ' ' NOT NULL,
    "應出庫日時起" timestamp(0) NOT NULL,
    "應出庫日時迄" timestamp(0) NOT NULL,
    "本製程編號" varchar(70) DEFAULT ' ' NOT NULL,
    "PLC抓取米數" numeric(14,4) DEFAULT 0 NOT NULL,
    "庫存數" numeric(14,4) DEFAULT 0 NOT NULL,
    "製品厚度" numeric(14,4) DEFAULT 0 NOT NULL,
    "熟成條件" varchar(100) DEFAULT ' ' NOT NULL,
    "熟成狀態" varchar(1) DEFAULT ' ' NOT NULL,
    "入庫狀態" varchar(1) DEFAULT ' ' NOT NULL,
    "出庫狀態" varchar(1) DEFAULT ' ' NOT NULL,
    "可提早出庫" smallint DEFAULT 0 NOT NULL,
    "放行人員" varchar(20) DEFAULT ' ' NOT NULL,
    "不限出庫設定人員" varchar(20) DEFAULT ' ' NOT NULL,
    "不限出庫時間" smallint DEFAULT 0 NOT NULL,
    "IP位址" varchar(40) DEFAULT ' ' NOT NULL,
    "IP位址2" varchar(40) DEFAULT ' ' NOT NULL,
    "加工別" varchar(1) DEFAULT ' ' NOT NULL,
    "單頭流水編號" varchar(60) DEFAULT ' ' NOT NULL,
    "超時未入庫" smallint DEFAULT 0 NOT NULL,
    "異常" smallint DEFAULT 0 NOT NULL,
    "重覆入庫" smallint DEFAULT 0 NOT NULL,
    "異動日期" char(8) DEFAULT '00000000' NOT NULL,
    "異動時間" char(6) DEFAULT '000000' NOT NULL,
    "異動人員" varchar(10) DEFAULT ' ' NOT NULL
);
CREATE UNIQUE INDEX "fil004ka_key1" ON "fil004ka" ("單別", "單號", "序號");
COMMENT ON TABLE "fil004ka" IS '0.冷鏈室其它製程轉入';
COMMENT ON COLUMN "fil004ka"."熟成入庫日期" IS '冷鏈入庫日期';
COMMENT ON COLUMN "fil004ka"."熟成入庫時間" IS '冷鏈入庫時間';
COMMENT ON COLUMN "fil004ka"."熟成入庫時間2" IS '冷鏈入庫時間2';
COMMENT ON COLUMN "fil004ka"."熟成出庫日期" IS '冷鏈出庫日期';
COMMENT ON COLUMN "fil004ka"."熟成出庫時間" IS '冷鏈出庫時間';
COMMENT ON COLUMN "fil004ka"."熟成出庫時間2" IS '冷鏈出庫時間2';
COMMENT ON COLUMN "fil004ka"."應入庫日時" IS '應入庫日期';
COMMENT ON COLUMN "fil004ka"."應入庫日期" IS '應入庫時間';
COMMENT ON COLUMN "fil004ka"."應出庫日時起" IS '應出庫日期起 / 應出庫時間起';
COMMENT ON COLUMN "fil004ka"."應出庫日時迄" IS '應出庫日期迄 / 應出庫時間迄';
COMMENT ON COLUMN "fil004ka"."熟成條件" IS '冷鏈條件';
COMMENT ON COLUMN "fil004ka"."熟成狀態" IS '冷鏈狀態';

-- Files：0.製程批號異動明細
CREATE TABLE "fil004l" (
    "批號" varchar(40) DEFAULT ' ' NOT NULL,
    "單別" varchar(10) DEFAULT ' ' NOT NULL,
    "單號" varchar(20) DEFAULT ' ' NOT NULL,
    "序號" integer NOT NULL,
    "異動日期" char(8) DEFAULT '00000000' NOT NULL,
    "數量" numeric(14,4) DEFAULT 0 NOT NULL,
    "製袋重量" numeric(14,4) DEFAULT 0 NOT NULL,
    "氣閥重量" numeric(14,4) DEFAULT 0 NOT NULL,
    "鐵條重量" numeric(14,4) DEFAULT 0 NOT NULL,
    "紙箱重量" numeric(14,4) DEFAULT 0 NOT NULL,
    "作業日期" char(8) DEFAULT '00000000' NOT NULL,
    "作業員一姓名" varchar(10) DEFAULT ' ' NOT NULL,
    "作業員二姓名" varchar(10) DEFAULT ' ' NOT NULL,
    "作業員三姓名" varchar(10) DEFAULT ' ' NOT NULL,
    "來源" varchar(10) DEFAULT ' ' NOT NULL,
    "填表人" varchar(10) DEFAULT ' ' NOT NULL,
    "最後更新日時" varchar(14) DEFAULT ' ' NOT NULL,
    "單據數量" numeric(14,4) NOT NULL,
    "單據重量" numeric(14,4) NOT NULL,
    "流水編號" varchar(60) DEFAULT ' ' NOT NULL
);
CREATE UNIQUE INDEX "fil004lkey0" ON "fil004l" ("流水編號");
CREATE INDEX "fil004lkey1" ON "fil004l" ("單別", "單號", "序號");
CREATE INDEX "fil004lkey2" ON "fil004l" ("批號", "作業日期", "最後更新日時");
CREATE INDEX "fil004lkey3" ON "fil004l" ("批號", "來源", "作業日期", "最後更新日時");
COMMENT ON TABLE "fil004l" IS '0.製程批號異動明細';

-- Files：0.原物料異動明細(批號)
CREATE TABLE "fil004m" (
    "批號" varchar(40) DEFAULT ' ' NOT NULL,
    "單別" varchar(10) DEFAULT ' ' NOT NULL,
    "單號" varchar(20) DEFAULT ' ' NOT NULL,
    "序號" integer NOT NULL,
    "物料編號" varchar(20) DEFAULT ' ' NOT NULL,
    "異動日期" char(8) DEFAULT '00000000' NOT NULL,
    "數量" numeric(14,4) DEFAULT 0 NOT NULL,
    "庫存異動數" numeric(14,4) NOT NULL,
    "來源" varchar(10) DEFAULT ' ' NOT NULL,
    "填表人" varchar(10) DEFAULT ' ' NOT NULL,
    "最後更新日時" varchar(14) DEFAULT ' ' NOT NULL,
    "流水編號" varchar(60) DEFAULT ' ' NOT NULL
);
CREATE UNIQUE INDEX "fil004mkey0" ON "fil004m" ("流水編號");
CREATE INDEX "fil004mkey1" ON "fil004m" ("單別", "單號", "序號");
CREATE INDEX "fil004mkey2" ON "fil004m" ("批號", "最後更新日時");
CREATE INDEX "fil004mkey3" ON "fil004m" ("物料編號", "最後更新日時");
COMMENT ON TABLE "fil004m" IS '0.原物料異動明細(批號)';

-- Files：0.原物料異動明細
CREATE TABLE "fil004n" (
    "單別" varchar(10) NOT NULL,
    "單號" varchar(20) NOT NULL,
    "序號" numeric(4,0) NOT NULL,
    "異動日期" varchar(8) NOT NULL,
    "年月" varchar(12),
    "料號" varchar(70) NOT NULL,
    "最後更新日" timestamp(0),
    "異動數" numeric(13,3),
    "異動單價" numeric(13,3),
    "異動金額" numeric(13,3),
    "來源" varchar(20) NOT NULL
);
CREATE UNIQUE INDEX "fil004nkey1" ON "fil004n" ("單別", "單號", "序號", "來源");
COMMENT ON TABLE "fil004n" IS '0.原物料異動明細';
COMMENT ON COLUMN "fil004n"."最後更新日" IS '最後更新日 / 最後更新日_time';

-- Files：0.客供品異動明細
CREATE TABLE "fil004o" (
    "單別" varchar(10) NOT NULL,
    "單號" varchar(20) NOT NULL,
    "序號" numeric(4,0) NOT NULL,
    "異動日期" varchar(8) NOT NULL,
    "年月" varchar(12),
    "料號" varchar(70) NOT NULL,
    "最後更新日" timestamp(0),
    "異動數" numeric(13,3),
    "異動單價" numeric(13,3),
    "異動金額" numeric(13,3),
    "來源" varchar(20) NOT NULL
);
CREATE UNIQUE INDEX "fil004okey1" ON "fil004o" ("單別", "單號", "序號", "來源");
COMMENT ON TABLE "fil004o" IS '0.客供品異動明細';
COMMENT ON COLUMN "fil004o"."最後更新日" IS '最後更新日 / 最後更新日_time';

-- Files：0.單據編號檔
CREATE TABLE "fil0050" (
    "單據類別" varchar(10) DEFAULT ' ' NOT NULL,
    "日期" char(8) DEFAULT '00000000' NOT NULL,
    "序號" smallint DEFAULT 0 NOT NULL,
    PRIMARY KEY ("單據類別", "日期")
);
COMMENT ON TABLE "fil0050" IS '0.單據編號檔';

-- Files：0.臨時單號檔
CREATE TABLE "fil0051" (
    "單據類別" varchar(10) DEFAULT ' ' NOT NULL,
    "日期" char(8) DEFAULT '00000000' NOT NULL,
    "序號" numeric(10,0) DEFAULT 0 NOT NULL,
    PRIMARY KEY ("單據類別", "日期")
);
COMMENT ON TABLE "fil0051" IS '0.臨時單號檔';

-- Files：0.表單確認檔
CREATE TABLE "fil0060" (
    "ctxid" varchar(40) DEFAULT ' ' NOT NULL,
    "單據類別" varchar(10) DEFAULT ' ' NOT NULL,
    "單據編號" varchar(20) DEFAULT ' ' NOT NULL,
    "選擇" smallint DEFAULT 0 NOT NULL,
    PRIMARY KEY ("ctxid", "單據類別", "單據編號")
);
CREATE UNIQUE INDEX "fil0060_02" ON "fil0060" ("選擇", "ctxid", "單據類別", "單據編號");
COMMENT ON TABLE "fil0060" IS '0.表單確認檔';

-- Files：0.表單送簽檔
CREATE TABLE "fil0070" (
    "類別" varchar(1) DEFAULT ' ' NOT NULL,
    "ctxid" varchar(40) DEFAULT ' ' NOT NULL,
    "單據類別" varchar(10) DEFAULT ' ' NOT NULL,
    "單據編號" varchar(20) DEFAULT ' ' NOT NULL,
    "選擇" smallint DEFAULT 0 NOT NULL,
    PRIMARY KEY ("類別", "ctxid", "單據類別", "單據編號")
);
CREATE UNIQUE INDEX "fil0070_02" ON "fil0070" ("類別", "選擇", "ctxid", "單據類別", "單據編號");
COMMENT ON TABLE "fil0070" IS '0.表單送簽檔';

-- Files：0.表單簽核檔
CREATE TABLE "fil0080" (
    "類別" varchar(1) DEFAULT ' ' NOT NULL,
    "ctxid" varchar(40) DEFAULT ' ' NOT NULL,
    "簽核編號" numeric(10,0) DEFAULT 0 NOT NULL,
    "序號" smallint DEFAULT 0 NOT NULL,
    "選擇" smallint DEFAULT 0 NOT NULL,
    "意見" varchar(200) DEFAULT ' ' NOT NULL,
    PRIMARY KEY ("類別", "ctxid", "簽核編號", "序號")
);
CREATE UNIQUE INDEX "fil0080_02" ON "fil0080" ("類別", "選擇", "ctxid", "簽核編號", "序號");
COMMENT ON TABLE "fil0080" IS '0.表單簽核檔';

-- Files：0.相片資料檔
CREATE TABLE "fil0090" (
    "groupid" varchar(50) DEFAULT ' ' NOT NULL,
    "remark" varchar(100) DEFAULT ' ' NOT NULL,
    "建檔日期" char(8) DEFAULT '00000000' NOT NULL,
    "最後更新者" varchar(10) DEFAULT ' ' NOT NULL,
    "最後更新日" timestamp(0),
    PRIMARY KEY ("groupid")
);
CREATE UNIQUE INDEX "fil0090_02" ON "fil0090" ("建檔日期", "groupid");
COMMENT ON TABLE "fil0090" IS '0.相片資料檔';
COMMENT ON COLUMN "fil0090"."groupid" IS '流水編號';
COMMENT ON COLUMN "fil0090"."remark" IS '備註說明';
COMMENT ON COLUMN "fil0090"."最後更新日" IS '最後更新日 / 最後更新時';

-- Files：0.相片明細檔
CREATE TABLE "fil0100" (
    "groupid" varchar(50) DEFAULT ' ' NOT NULL,
    "seqno" smallint DEFAULT 0 NOT NULL,
    "remark" varchar(100) DEFAULT ' ' NOT NULL,
    "photo" bytea,
    "phototype" varchar(10) DEFAULT ' ' NOT NULL,
    "filename" varchar(200) DEFAULT ' ' NOT NULL,
    "modifydate" timestamp(0),
    PRIMARY KEY ("groupid", "seqno")
);
COMMENT ON TABLE "fil0100" IS '0.相片明細檔';
COMMENT ON COLUMN "fil0100"."groupid" IS '流水編號';
COMMENT ON COLUMN "fil0100"."modifydate" IS 'ModifyDate / ModifyTime';

-- Files：0.資料匯入暫存
CREATE TABLE "fil0120" (
    "流水編號" varchar(60) DEFAULT ' ' NOT NULL,
    "序號" integer NOT NULL,
    "匯入日期" char(8) DEFAULT '00000000' NOT NULL,
    "匯入時間" char(6) DEFAULT '000000' NOT NULL,
    "欄位1" varchar(50) DEFAULT ' ' NOT NULL,
    "欄位2" varchar(50) DEFAULT ' ' NOT NULL,
    "欄位3" varchar(50) DEFAULT ' ' NOT NULL,
    "欄位4" varchar(50) DEFAULT ' ' NOT NULL,
    "欄位5" varchar(50) DEFAULT ' ' NOT NULL,
    "欄位6" varchar(50) DEFAULT ' ' NOT NULL,
    "欄位7" varchar(50) DEFAULT ' ' NOT NULL,
    "欄位8" varchar(50) DEFAULT ' ' NOT NULL,
    "欄位9" varchar(50) DEFAULT ' ' NOT NULL,
    "欄位10" varchar(50) DEFAULT ' ' NOT NULL,
    "欄位11" varchar(50) DEFAULT ' ' NOT NULL,
    "欄位12" varchar(50) DEFAULT ' ' NOT NULL,
    "欄位13" varchar(50) DEFAULT ' ' NOT NULL,
    "欄位14" varchar(50) DEFAULT ' ' NOT NULL,
    "欄位15" varchar(50) DEFAULT ' ' NOT NULL,
    "欄位16" varchar(50) DEFAULT ' ' NOT NULL,
    "欄位17" varchar(50) DEFAULT ' ' NOT NULL,
    "欄位18" varchar(50) DEFAULT ' ' NOT NULL,
    "欄位19" varchar(50) DEFAULT ' ' NOT NULL,
    "欄位20" varchar(50) DEFAULT ' ' NOT NULL,
    "備註" varchar(100) DEFAULT ' ' NOT NULL
);
CREATE UNIQUE INDEX "fil0120key1" ON "fil0120" ("流水編號", "序號");
CREATE UNIQUE INDEX "fil0120key2" ON "fil0120" ("匯入日期", "流水編號", "序號");
COMMENT ON TABLE "fil0120" IS '0.資料匯入暫存';

-- Files：1.功能表選單
CREATE TABLE "fil1000" (
    "序號" integer DEFAULT 0 NOT NULL,
    "父階" varchar(10) DEFAULT ' ' NOT NULL,
    "子階" varchar(12) DEFAULT ' ' NOT NULL,
    "node" smallint DEFAULT 0 NOT NULL,
    "說明" varchar(100) DEFAULT ' ' NOT NULL,
    "cabinet" varchar(100) DEFAULT ' ' NOT NULL,
    "publicname" varchar(100) DEFAULT ' ' NOT NULL,
    "啟用" smallint DEFAULT 0 NOT NULL,
    "隱藏" smallint DEFAULT 0 NOT NULL,
    "不需授權" smallint DEFAULT 0 NOT NULL,
    "權限組合" varchar(100) DEFAULT ' ' NOT NULL,
    "單據類別" varchar(10) DEFAULT ' ' NOT NULL,
    "流程代碼" varchar(10) DEFAULT ' ' NOT NULL,
    "特殊管制" smallint DEFAULT 0 NOT NULL,
    "人事管制" smallint DEFAULT 0 NOT NULL,
    PRIMARY KEY ("序號")
);
CREATE INDEX "fil1000_02" ON "fil1000" ("publicname");
CREATE INDEX "fil1000_03" ON "fil1000" ("單據類別");
CREATE INDEX "fil1000_04" ON "fil1000" ("子階");
COMMENT ON TABLE "fil1000" IS '1.功能表選單';
COMMENT ON COLUMN "fil1000"."node" IS 'Node?';

-- Files：1.外部合併檔
CREATE TABLE "fil1001" (
    "類別" varchar(20) DEFAULT ' ' NOT NULL,
    "序號" smallint DEFAULT 0 NOT NULL,
    "說明" varchar(40) DEFAULT ' ' NOT NULL,
    "格式" varchar(5) DEFAULT ' ' NOT NULL,
    "母版" bytea,
    PRIMARY KEY ("類別", "序號")
);
COMMENT ON TABLE "fil1001" IS '1.外部合併檔';

-- Files：1.發佈新聞檔
CREATE TABLE "fil1002" (
    "系統別" varchar(20) DEFAULT ' ' NOT NULL,
    "序號" numeric(10,0) DEFAULT 0 NOT NULL,
    "發佈起日" char(8) DEFAULT '00000000' NOT NULL,
    "發佈迄日" char(8) DEFAULT '00000000' NOT NULL,
    "主旨" varchar(20) DEFAULT ' ' NOT NULL,
    "內容" varchar(100) DEFAULT ' ' NOT NULL,
    "最後更新者" varchar(10) DEFAULT ' ' NOT NULL,
    "最後更新日" timestamp(0),
    PRIMARY KEY ("系統別", "序號")
);
CREATE UNIQUE INDEX "fil1002_02" ON "fil1002" ("系統別", "發佈起日", "序號");
COMMENT ON TABLE "fil1002" IS '1.發佈新聞檔';
COMMENT ON COLUMN "fil1002"."最後更新日" IS '最後更新日 / 最後更新時';

-- Files：1.工作記錄檔
CREATE TABLE "fil1003" (
    "pid" varchar(100) DEFAULT ' ' NOT NULL,
    "publicname" varchar(100) DEFAULT ' ' NOT NULL,
    "單號" varchar(20) DEFAULT ' ' NOT NULL,
    "參數" varchar(100) DEFAULT ' ' NOT NULL,
    "id" varchar(10) DEFAULT ' ' NOT NULL,
    "建立日期" timestamp(0),
    PRIMARY KEY ("pid")
);
CREATE UNIQUE INDEX "fil1003_02" ON "fil1003" ("建立日期", "pid");
COMMENT ON TABLE "fil1003" IS '1.工作記錄檔';
COMMENT ON COLUMN "fil1003"."建立日期" IS '建立日期 / 建立時間';

-- Files：1.登入記錄檔
CREATE TABLE "fil1004" (
    "id" varchar(10) DEFAULT ' ' NOT NULL,
    "登入日期" char(8) DEFAULT '00000000' NOT NULL,
    "登入時間" char(6) DEFAULT '000000' NOT NULL,
    "序號" numeric(10,0) DEFAULT 0 NOT NULL,
    "電腦名稱" varchar(40) DEFAULT ' ' NOT NULL,
    "系統別" varchar(10) DEFAULT ' ' NOT NULL,
    "remote_addr" varchar(60) DEFAULT ' ' NOT NULL,
    PRIMARY KEY ("id", "登入日期", "登入時間", "序號")
);
CREATE UNIQUE INDEX "fil1004_02" ON "fil1004" ("登入日期", "登入時間", "序號", "id");
COMMENT ON TABLE "fil1004" IS '1.登入記錄檔';

-- Files：1.使用者角色
CREATE TABLE "fil1005" (
    "員工編號" varchar(10) DEFAULT ' ' NOT NULL,
    "權限金鑰" varchar(20) DEFAULT ' ' NOT NULL,
    "授權代號" varchar(10) DEFAULT ' ' NOT NULL,
    "授權日期" timestamp(0),
    PRIMARY KEY ("員工編號", "權限金鑰")
);
CREATE UNIQUE INDEX "fil1005_02" ON "fil1005" ("權限金鑰", "員工編號");
COMMENT ON TABLE "fil1005" IS '1.使用者角色';
COMMENT ON COLUMN "fil1005"."授權日期" IS '授權日期 / 授權時間';

-- Files：1.系統使用記錄
CREATE TABLE "fil1006" (
    "西元日期" char(8) DEFAULT '00000000' NOT NULL,
    "時間" char(6) DEFAULT '000000' NOT NULL,
    "序號" numeric(10,0) DEFAULT 0 NOT NULL,
    "類別" varchar(100) DEFAULT ' ' NOT NULL,
    "對應編號" varchar(100) DEFAULT ' ' NOT NULL,
    "記錄內容" varchar(100) DEFAULT ' ' NOT NULL,
    "員工編號" varchar(10) DEFAULT ' ' NOT NULL,
    "裝置位址" varchar(30) DEFAULT ' ' NOT NULL,
    PRIMARY KEY ("西元日期", "時間", "序號")
);
CREATE UNIQUE INDEX "fil1006_02" ON "fil1006" ("類別", "對應編號", "西元日期", "時間", "序號");
CREATE UNIQUE INDEX "fil1006_03" ON "fil1006" ("類別", "西元日期", "時間", "序號");
COMMENT ON TABLE "fil1006" IS '1.系統使用記錄';

-- Files：1.使用者權限
CREATE TABLE "fil1007" (
    "員工編號" varchar(10) DEFAULT ' ' NOT NULL,
    "publicname" varchar(100) DEFAULT ' ' NOT NULL,
    "權限" varchar(100) DEFAULT ' ' NOT NULL,
    "隱藏" smallint DEFAULT 0 NOT NULL,
    "獨立執行" smallint DEFAULT 0 NOT NULL,
    "密碼執行" smallint DEFAULT 0 NOT NULL,
    "最後更新者" varchar(10) DEFAULT ' ' NOT NULL,
    "最後更新日" timestamp(0),
    PRIMARY KEY ("員工編號", "publicname")
);
CREATE UNIQUE INDEX "fil1007_02" ON "fil1007" ("publicname", "員工編號");
COMMENT ON TABLE "fil1007" IS '1.使用者權限';
COMMENT ON COLUMN "fil1007"."最後更新日" IS '最後更新日 / 最後更新時';

-- Files：1.特殊權限檔
CREATE TABLE "fil1008" (
    "權限金鑰" varchar(10) DEFAULT ' ' NOT NULL,
    "權限說明" varchar(100) DEFAULT ' ' NOT NULL,
    PRIMARY KEY ("權限金鑰")
);
COMMENT ON TABLE "fil1008" IS '1.特殊權限檔';

-- Files：1.簽核發送檔
CREATE TABLE "fil1009" (
    "簽核編號" numeric(10,0) DEFAULT 0 NOT NULL,
    "簽核系統" varchar(40) DEFAULT ' ' NOT NULL,
    "單號" varchar(20) DEFAULT ' ' NOT NULL,
    "發函人" varchar(10) DEFAULT ' ' NOT NULL,
    "發函日期" char(8) DEFAULT '00000000' NOT NULL,
    "發函時間" char(6) DEFAULT '000000' NOT NULL,
    "簽核群組" varchar(40) DEFAULT ' ' NOT NULL,
    "最後簽核流程順序" smallint DEFAULT 0 NOT NULL,
    "簽核狀態" varchar(1) DEFAULT ' ' NOT NULL,
    "刪除退回人" varchar(10) DEFAULT ' ' NOT NULL,
    "刪除退回日" timestamp(0),
    "發函代理人" varchar(10) DEFAULT ' ' NOT NULL,
    PRIMARY KEY ("簽核編號")
);
CREATE UNIQUE INDEX "fil1009_02" ON "fil1009" ("簽核系統", "單號", "簽核編號");
CREATE UNIQUE INDEX "fil1009_03" ON "fil1009" ("簽核狀態", "簽核系統", "單號", "簽核編號");
COMMENT ON TABLE "fil1009" IS '1.簽核發送檔';
COMMENT ON COLUMN "fil1009"."刪除退回日" IS '刪除退回日 / 刪除退回時';

-- Files：1.簽核流程檔
CREATE TABLE "fil1010" (
    "簽核編號" numeric(10,0) DEFAULT 0 NOT NULL,
    "序號" smallint DEFAULT 0 NOT NULL,
    "簽核人" varchar(10) DEFAULT ' ' NOT NULL,
    "簽核流程順序" smallint DEFAULT 0 NOT NULL,
    "執行碼" varchar(1) DEFAULT ' ' NOT NULL,
    "執行日" char(8) DEFAULT '00000000' NOT NULL,
    "執行時" char(6) DEFAULT '000000' NOT NULL,
    "意見" varchar(200) DEFAULT ' ' NOT NULL,
    "移轉簽核人" varchar(10) DEFAULT ' ' NOT NULL,
    "代簽人" varchar(10) DEFAULT ' ' NOT NULL,
    "guid" varchar(60) DEFAULT ' ' NOT NULL,
    PRIMARY KEY ("簽核編號", "序號")
);
CREATE UNIQUE INDEX "fil1010_02" ON "fil1010" ("簽核人", "執行碼", "簽核編號", "序號");
CREATE UNIQUE INDEX "fil1010_03" ON "fil1010" ("簽核編號", "簽核流程順序", "序號");
CREATE INDEX "fil1010_04" ON "fil1010" ("guid");
COMMENT ON TABLE "fil1010" IS '1.簽核流程檔';

-- Files：1.簽核附件檔
CREATE TABLE "fil1011" (
    "簽核系統" varchar(40) DEFAULT ' ' NOT NULL,
    "單號" varchar(30) DEFAULT ' ' NOT NULL,
    "序號" numeric(10,0) DEFAULT 0 NOT NULL,
    "附件" bytea,
    "格式" varchar(5) DEFAULT ' ' NOT NULL,
    "說明" varchar(60) DEFAULT ' ' NOT NULL,
    "大小" numeric(8,2) DEFAULT 0 NOT NULL,
    "關鍵字" varchar(100) DEFAULT ' ' NOT NULL,
    "客供類別" varchar(2) DEFAULT ' ' NOT NULL,
    "附件類別" varchar(2) DEFAULT ' ' NOT NULL,
    "附件流水號" varchar(60) DEFAULT ' ' NOT NULL,
    "更新者" varchar(10) DEFAULT ' ' NOT NULL,
    "更新日" timestamp(0),
    "建檔人" varchar(10) DEFAULT ' ' NOT NULL,
    "建檔日" char(8) DEFAULT '00000000' NOT NULL,
    "建檔時" char(6) DEFAULT '000000' NOT NULL,
    PRIMARY KEY ("簽核系統", "單號", "序號")
);
COMMENT ON TABLE "fil1011" IS '1.簽核附件檔';
COMMENT ON COLUMN "fil1011"."附件" IS '附件(作廢)';
COMMENT ON COLUMN "fil1011"."更新日" IS '更新日 / 更新時';

-- Files：1.簽核組別檔
CREATE TABLE "fil1012" (
    "簽核系統" varchar(40) DEFAULT ' ' NOT NULL,
    "組別" varchar(40) DEFAULT ' ' NOT NULL,
    "組別名稱" varchar(30) DEFAULT ' ' NOT NULL,
    "最後更新者" varchar(10) DEFAULT ' ' NOT NULL,
    "最後更新日" timestamp(0),
    PRIMARY KEY ("簽核系統", "組別")
);
COMMENT ON TABLE "fil1012" IS '1.簽核組別檔';
COMMENT ON COLUMN "fil1012"."最後更新日" IS '最後更新日 / 最後更新時';

-- Files：1.簽核人員檔
CREATE TABLE "fil1013" (
    "簽核系統" varchar(40) DEFAULT ' ' NOT NULL,
    "組別" varchar(40) DEFAULT ' ' NOT NULL,
    "簽核順序" smallint DEFAULT 0 NOT NULL,
    "員工編號" varchar(10) DEFAULT ' ' NOT NULL,
    "開始日期" char(8) DEFAULT '00000000' NOT NULL,
    "結束日期" char(8) DEFAULT '00000000' NOT NULL,
    "類別" varchar(1) DEFAULT ' ' NOT NULL,
    "啟用" smallint DEFAULT 0 NOT NULL,
    "最後更新者" varchar(10) DEFAULT ' ' NOT NULL,
    "最後更新日" timestamp(0),
    PRIMARY KEY ("簽核系統", "組別", "簽核順序", "員工編號")
);
CREATE UNIQUE INDEX "fil1013_02" ON "fil1013" ("員工編號", "簽核系統", "組別", "簽核順序");
COMMENT ON TABLE "fil1013" IS '1.簽核人員檔';
COMMENT ON COLUMN "fil1013"."最後更新日" IS '最後更新日 / 最後更新時';

-- Files：1.系統代碼檔
CREATE TABLE "fil1014" (
    "代碼類別" varchar(20) DEFAULT ' ' NOT NULL,
    "系統代碼" varchar(20) DEFAULT ' ' NOT NULL,
    "代碼名稱" varchar(50) DEFAULT ' ' NOT NULL,
    "文字參數" varchar(500) DEFAULT ' ' NOT NULL,
    "數字參數" numeric(16,6) DEFAULT 0 NOT NULL,
    "數字參數二" numeric(16,6) DEFAULT 0 NOT NULL,
    "數字參數三" numeric(16,6) DEFAULT 0 NOT NULL,
    "數字參數四" numeric(16,6) DEFAULT 0 NOT NULL,
    "數字參數五" numeric(16,6) DEFAULT 0 NOT NULL,
    "數字參數六" numeric(16,6) DEFAULT 0 NOT NULL,
    "數字參數七" numeric(16,6) DEFAULT 0 NOT NULL,
    "數字參數八" numeric(16,6) DEFAULT 0 NOT NULL,
    "數字參數九" numeric(16,6) DEFAULT 0 NOT NULL,
    "數字參數十" numeric(16,6) DEFAULT 0 NOT NULL,
    "英數參數" varchar(500) DEFAULT ' ' NOT NULL,
    "文字參數一" varchar(40) DEFAULT ' ' NOT NULL,
    "文字參數二" varchar(40) DEFAULT ' ' NOT NULL,
    "文字參數三" varchar(60) DEFAULT ' ' NOT NULL,
    "文字參數四" varchar(30) DEFAULT ' ' NOT NULL,
    "文字參數五" varchar(30) DEFAULT ' ' NOT NULL,
    "日期" char(8) DEFAULT '00000000' NOT NULL,
    "日期一" char(8) DEFAULT '00000000' NOT NULL,
    "時間" char(6) DEFAULT 000000 NOT NULL,
    "時間一" char(6) DEFAULT 000000 NOT NULL,
    "時間二" char(6) DEFAULT 000000 NOT NULL,
    "時間三" char(6) DEFAULT 000000 NOT NULL,
    "時間四" char(6) DEFAULT 000000 NOT NULL,
    "邏輯值" smallint DEFAULT 0 NOT NULL,
    "邏輯值一" smallint DEFAULT 0 NOT NULL,
    "邏輯值二" smallint DEFAULT 0 NOT NULL,
    "邏輯值三" smallint DEFAULT 0 NOT NULL,
    "邏輯值四" smallint DEFAULT 0 NOT NULL,
    "最後更新者" varchar(10) DEFAULT ' ' NOT NULL,
    "最後更新日" timestamp(0),
    "最後更新日期" char(6) DEFAULT 0,
    PRIMARY KEY ("代碼類別", "系統代碼")
);
COMMENT ON TABLE "fil1014" IS '1.系統代碼檔';
COMMENT ON COLUMN "fil1014"."最後更新日期" IS '最後更新時';

-- Files：1.系統代碼檔明細
CREATE TABLE "fil1014a" (
    "代碼類別" varchar(20) DEFAULT ' ' NOT NULL,
    "系統代碼" varchar(20) DEFAULT ' ' NOT NULL,
    "系統序號" integer NOT NULL,
    "數字參數一" numeric(16,6) DEFAULT 0 NOT NULL,
    "數字參數二" numeric(16,6) DEFAULT 0 NOT NULL,
    "數字參數三" numeric(16,6) DEFAULT 0 NOT NULL,
    "文字參數一" varchar(40) DEFAULT ' ' NOT NULL,
    "文字參數二" varchar(40) DEFAULT ' ' NOT NULL,
    "文字參數三" varchar(40) DEFAULT ' ' NOT NULL,
    "日期一" char(8) DEFAULT '00000000' NOT NULL,
    "日期二" char(8) DEFAULT '00000000' NOT NULL,
    "時間一" char(6) DEFAULT 000000 NOT NULL,
    "時間二" char(6) DEFAULT 000000 NOT NULL,
    "邏輯值一" smallint DEFAULT 0 NOT NULL,
    "邏輯值二" smallint DEFAULT 0 NOT NULL,
    "最後更新者" varchar(10) DEFAULT ' ' NOT NULL,
    "最後更新日" timestamp(0),
    "最後更新日期" char(6) DEFAULT 0
);
CREATE UNIQUE INDEX "fil1014akey1" ON "fil1014a" ("代碼類別", "系統代碼", "系統序號");
CREATE INDEX "fil1014akey2" ON "fil1014a" ("代碼類別", "系統代碼", "日期一", "系統序號");
COMMENT ON TABLE "fil1014a" IS '1.系統代碼檔明細';
COMMENT ON COLUMN "fil1014a"."最後更新日期" IS '最後更新時';

-- Files：1.月曆資料檔
CREATE TABLE "fil1016" (
    "員工編號" varchar(10) DEFAULT ' ' NOT NULL,
    "年月" integer DEFAULT 0 NOT NULL,
    "週" smallint DEFAULT 0 NOT NULL,
    "日" char(8) DEFAULT '00000000' NOT NULL,
    "一" char(8) DEFAULT '00000000' NOT NULL,
    "二" char(8) DEFAULT '00000000' NOT NULL,
    "三" char(8) DEFAULT '00000000' NOT NULL,
    "四" char(8) DEFAULT '00000000' NOT NULL,
    "五" char(8) DEFAULT '00000000' NOT NULL,
    "六" char(8) DEFAULT '00000000' NOT NULL,
    "日陰曆" char(8) DEFAULT '00000000' NOT NULL,
    "一陰曆" char(8) DEFAULT '00000000' NOT NULL,
    "二陰曆" char(8) DEFAULT '00000000' NOT NULL,
    "三陰曆" char(8) DEFAULT '00000000' NOT NULL,
    "四陰曆" char(8) DEFAULT '00000000' NOT NULL,
    "五陰曆" char(8) DEFAULT '00000000' NOT NULL,
    "六陰曆" char(8) DEFAULT '00000000' NOT NULL,
    "日休假" smallint NOT NULL,
    "一休假" smallint NOT NULL,
    "二休假" smallint NOT NULL,
    "三休假" smallint NOT NULL,
    "四休假" smallint NOT NULL,
    "五休假" smallint NOT NULL,
    "六休假" smallint NOT NULL,
    PRIMARY KEY ("員工編號", "年月", "週")
);
CREATE INDEX "fil1016_02" ON "fil1016" ("年月", "週");
COMMENT ON TABLE "fil1016" IS '1.月曆資料檔';
COMMENT ON COLUMN "fil1016"."日陰曆" IS '日.陰曆';
COMMENT ON COLUMN "fil1016"."一陰曆" IS '一.陰曆';
COMMENT ON COLUMN "fil1016"."二陰曆" IS '二.陰曆';
COMMENT ON COLUMN "fil1016"."三陰曆" IS '三.陰曆';
COMMENT ON COLUMN "fil1016"."四陰曆" IS '四.陰曆';
COMMENT ON COLUMN "fil1016"."五陰曆" IS '五.陰曆';
COMMENT ON COLUMN "fil1016"."六陰曆" IS '六.陰曆';
COMMENT ON COLUMN "fil1016"."日休假" IS '日.休假';
COMMENT ON COLUMN "fil1016"."一休假" IS '一.休假';
COMMENT ON COLUMN "fil1016"."二休假" IS '二.休假';
COMMENT ON COLUMN "fil1016"."三休假" IS '三.休假';
COMMENT ON COLUMN "fil1016"."四休假" IS '四.休假';
COMMENT ON COLUMN "fil1016"."五休假" IS '五.休假';
COMMENT ON COLUMN "fil1016"."六休假" IS '六.休假';

-- Files：1.通知記錄檔
CREATE TABLE "fil1017" (
    "寄件者" varchar(10) DEFAULT ' ' NOT NULL,
    "序號" numeric(10,0) DEFAULT 0 NOT NULL,
    "收件者" varchar(10) DEFAULT ' ' NOT NULL,
    "主旨" varchar(200) DEFAULT ' ' NOT NULL,
    "本文" text,
    "提醒日" char(8) DEFAULT '00000000' NOT NULL,
    "寄件日" timestamp(0),
    "發送" smallint DEFAULT 0 NOT NULL,
    "已讀" smallint DEFAULT 0 NOT NULL,
    "隱藏" smallint DEFAULT 0 NOT NULL,
    "通知" smallint DEFAULT 0 NOT NULL,
    "簽核系統" varchar(40) DEFAULT ' ' NOT NULL,
    PRIMARY KEY ("寄件者", "序號")
);
CREATE INDEX "fil1017_02" ON "fil1017" ("隱藏", "收件者", "提醒日");
CREATE INDEX "fil1017_03" ON "fil1017" ("發送", "寄件者", "提醒日");
CREATE UNIQUE INDEX "fil1017_04" ON "fil1017" ("簽核系統", "寄件者", "序號");
COMMENT ON TABLE "fil1017" IS '1.通知記錄檔';
COMMENT ON COLUMN "fil1017"."寄件日" IS '寄件日 / 寄件時';

-- Files：1.修改記錄檔
CREATE TABLE "fil1018" (
    "單據類別" varchar(10) DEFAULT ' ' NOT NULL,
    "單據編號" varchar(20) DEFAULT ' ' NOT NULL,
    "序號" numeric(10,0) DEFAULT 0 NOT NULL,
    "說明" varchar(100) DEFAULT ' ' NOT NULL,
    "狀態" varchar(1) DEFAULT ' ' NOT NULL,
    "修改人" varchar(10) DEFAULT ' ' NOT NULL,
    "修改日" timestamp(0),
    PRIMARY KEY ("單據類別", "單據編號", "序號")
);
COMMENT ON TABLE "fil1018" IS '1.修改記錄檔';
COMMENT ON COLUMN "fil1018"."修改日" IS '修改日 / 修改時';

-- Files：1.工作行事曆
CREATE TABLE "fil1019" (
    "年月" integer DEFAULT 0 NOT NULL,
    "週" smallint DEFAULT 0 NOT NULL,
    "日" char(8) DEFAULT '00000000' NOT NULL,
    "一" char(8) DEFAULT '00000000' NOT NULL,
    "二" char(8) DEFAULT '00000000' NOT NULL,
    "三" char(8) DEFAULT '00000000' NOT NULL,
    "四" char(8) DEFAULT '00000000' NOT NULL,
    "五" char(8) DEFAULT '00000000' NOT NULL,
    "六" char(8) DEFAULT '00000000' NOT NULL,
    "陰曆日" char(8) DEFAULT '00000000' NOT NULL,
    "陰曆一" char(8) DEFAULT '00000000' NOT NULL,
    "陰曆二" char(8) DEFAULT '00000000' NOT NULL,
    "陰曆三" char(8) DEFAULT '00000000' NOT NULL,
    "陰曆四" char(8) DEFAULT '00000000' NOT NULL,
    "陰曆五" char(8) DEFAULT '00000000' NOT NULL,
    "陰曆六" char(8) DEFAULT '00000000' NOT NULL,
    "休假日" smallint NOT NULL,
    "休假一" smallint NOT NULL,
    "休假二" smallint NOT NULL,
    "休假三" smallint NOT NULL,
    "休假四" smallint NOT NULL,
    "休假五" smallint NOT NULL,
    "休假六" smallint NOT NULL,
    "說明日" varchar(30) DEFAULT ' ' NOT NULL,
    "說明一" varchar(30) DEFAULT ' ' NOT NULL,
    "說明二" varchar(30) DEFAULT ' ' NOT NULL,
    "說明三" varchar(30) DEFAULT ' ' NOT NULL,
    "說明四" varchar(30) DEFAULT ' ' NOT NULL,
    "說明五" varchar(30) DEFAULT ' ' NOT NULL,
    "說明六" varchar(30) DEFAULT ' ' NOT NULL,
    "最後更新者" varchar(10) DEFAULT ' ' NOT NULL,
    "最後更新日" timestamp(0),
    PRIMARY KEY ("年月", "週")
);
COMMENT ON TABLE "fil1019" IS '1.工作行事曆';
COMMENT ON COLUMN "fil1019"."最後更新日" IS '最後更新日 / 最後更新時';

-- Files：1.通知記錄檔(外部)
CREATE TABLE "fil1020" (
    "guid" varchar(60) DEFAULT ' ' NOT NULL,
    "序號" numeric(10,0) DEFAULT 0 NOT NULL,
    "寄件者" varchar(10) DEFAULT ' ' NOT NULL,
    "收件者" varchar(2000) DEFAULT ' ' NOT NULL,
    "主旨" varchar(200) DEFAULT ' ' NOT NULL,
    "本文" text,
    "寄件日" timestamp(0),
    "發送" smallint DEFAULT 0 NOT NULL,
    PRIMARY KEY ("guid", "序號")
);
CREATE INDEX "fil1020_02" ON "fil1020" ("發送", "guid", "序號");
COMMENT ON TABLE "fil1020" IS '1.通知記錄檔(外部)';
COMMENT ON COLUMN "fil1020"."寄件日" IS '寄件日 / 寄件時';

-- Files：1.ISO編號對照
CREATE TABLE "fil1021" (
    "publicname" varchar(100) DEFAULT ' ' NOT NULL,
    "ISO編號" varchar(30) DEFAULT ' ' NOT NULL,
    "版次" varchar(10) DEFAULT ' ' NOT NULL,
    "裝定日期" char(8) DEFAULT ' ' NOT NULL,
    "修定日期" char(8) DEFAULT ' ' NOT NULL,
    "自修定摘要" varchar(100) DEFAULT ' ' NOT NULL,
    "參照" varchar(100) DEFAULT ' ' NOT NULL
);
CREATE UNIQUE INDEX "fil1021key1" ON "fil1021" ("publicname");
COMMENT ON TABLE "fil1021" IS '1.ISO編號對照';
COMMENT ON COLUMN "fil1021"."ISO編號" IS 'ISO文件編號';

-- Files：1.ISO編號變更明細
CREATE TABLE "fil1022" (
    "publicname" varchar(100) DEFAULT ' ' NOT NULL,
    "ISO編號" varchar(30) DEFAULT ' ' NOT NULL,
    "版次" varchar(10) DEFAULT ' ' NOT NULL,
    "裝定日期" char(8) DEFAULT ' ' NOT NULL,
    "修定日期" char(8) DEFAULT ' ' NOT NULL,
    "自修定摘要" varchar(100) DEFAULT ' ' NOT NULL,
    "參照" varchar(100) DEFAULT ' ' NOT NULL
);
CREATE UNIQUE INDEX "fil1022key1" ON "fil1022" ("publicname", "版次");
COMMENT ON TABLE "fil1022" IS '1.ISO編號變更明細';
COMMENT ON COLUMN "fil1022"."ISO編號" IS 'ISO文件編號';

-- Files：1.製程成本月彙總
CREATE TABLE "fil1051" (
    "年月" varchar(6) DEFAULT ' ' NOT NULL,
    "製程代碼" varchar(10) DEFAULT ' ' NOT NULL,
    "直接人工時數" numeric(14,4) DEFAULT 0 NOT NULL,
    "直接人工費用" numeric(14,4) DEFAULT 0 NOT NULL,
    "直接材料費用" numeric(14,4) DEFAULT 0 NOT NULL,
    "製造費用" numeric(14,4) DEFAULT 0 NOT NULL
);
CREATE UNIQUE INDEX "fil1051key1" ON "fil1051" ("年月", "製程代碼");
CREATE UNIQUE INDEX "fil1051key2" ON "fil1051" ("製程代碼", "年月");
COMMENT ON TABLE "fil1051" IS '1.製程成本月彙總';

-- Files：2.字詞對照檔
CREATE TABLE "fil2001" (
    "pagecode" varchar(5) DEFAULT ' ' NOT NULL,
    "localname" varchar(100) DEFAULT ' ' NOT NULL,
    "translateto" varchar(100) DEFAULT ' ' NOT NULL,
    "uploaded" smallint DEFAULT 0 NOT NULL
);
CREATE UNIQUE INDEX "fil2001_01" ON "fil2001" ("pagecode", "localname", "translateto");
COMMENT ON TABLE "fil2001" IS '2.字詞對照檔';

-- Files：3.機台.管制
CREATE TABLE "fil3009" (
    "機台號碼" varchar(10) DEFAULT ' ' NOT NULL,
    "序號" numeric(10,0) NOT NULL,
    "工卡號碼" varchar(20) DEFAULT ' ' NOT NULL,
    "排序" numeric(10,0) DEFAULT 0 NOT NULL,
    "缸煉" smallint DEFAULT 0 NOT NULL,
    "最後更新日期" timestamp(0)
);
CREATE INDEX "fil3009_01" ON "fil3009" ("機台號碼", "工卡號碼");
CREATE INDEX "fil3009_02" ON "fil3009" ("機台號碼", "序號");
CREATE UNIQUE INDEX "fil3009_03" ON "fil3009" ("工卡號碼");
CREATE INDEX "fil3009_04" ON "fil3009" ("機台號碼", "排序");
COMMENT ON TABLE "fil3009" IS '3.機台.管制';
COMMENT ON COLUMN "fil3009"."最後更新日期" IS '最後更新日期 / 最後更新時間';

-- Files：3.機台.管制歷史
CREATE TABLE "fil3009h" (
    "機台號碼" varchar(10) DEFAULT ' ' NOT NULL,
    "序號" numeric(10,0) NOT NULL,
    "工卡號碼" varchar(20) DEFAULT ' ' NOT NULL,
    "排序" numeric(10,0) DEFAULT 0 NOT NULL,
    "缸煉" smallint DEFAULT 0 NOT NULL,
    "最後更新日期" timestamp(0),
    "記錄日期" char(8) NOT NULL
);
CREATE UNIQUE INDEX "fil3009_01h" ON "fil3009h" ("記錄日期", "機台號碼", "工卡號碼");
CREATE INDEX "fil3009_02h" ON "fil3009h" ("記錄日期", "機台號碼", "序號");
CREATE UNIQUE INDEX "fil3009_03h" ON "fil3009h" ("記錄日期", "工卡號碼");
CREATE INDEX "fil3009_04h" ON "fil3009h" ("記錄日期", "機台號碼", "排序");
COMMENT ON TABLE "fil3009h" IS '3.機台.管制歷史';
COMMENT ON COLUMN "fil3009h"."最後更新日期" IS '最後更新日期 / 最後更新時間';

-- Files：3.機台.PLCDataOracle
CREATE TABLE "fil300b" (
    "機台代碼" varchar(10) DEFAULT ' ' NOT NULL,
    "位置" varchar(1) DEFAULT ' ' NOT NULL,
    "序號" numeric(10,0) DEFAULT 0 NOT NULL,
    "PLC代碼" varchar(10) DEFAULT ' ' NOT NULL,
    "PLC數值" numeric(10,0) DEFAULT 0 NOT NULL,
    "讀取日期" timestamp(0),
    "變更日期" timestamp(0),
    "製令單號" varchar(20) DEFAULT ' ' NOT NULL,
    "行" varchar(10) DEFAULT ' ' NOT NULL,
    "列" varchar(10) DEFAULT ' ' NOT NULL,
    "讀取日時" varchar(20) NOT NULL,
    "類別" varchar(1) DEFAULT ' ' NOT NULL,
    "相關單號" varchar(20) DEFAULT ' ' NOT NULL,
    "異動日時" varchar(20) DEFAULT ' ' NOT NULL
);
CREATE UNIQUE INDEX "fil300b_01" ON "fil300b" ("機台代碼", "位置", "序號");
CREATE INDEX "fil300b_02" ON "fil300b" ("機台代碼", "位置", "讀取日期");
CREATE INDEX "fil300b_03" ON "fil300b" ("機台代碼", "位置", "讀取日期" DESC, "序號", "PLC代碼");
CREATE INDEX "fil300b_04" ON "fil300b" ("機台代碼", "變更日期", "位置", "序號");
CREATE INDEX "fil300b_05" ON "fil300b" ("製令單號", "讀取日時", "位置");
CREATE INDEX "fil300b_06" ON "fil300b" ("相關單號", "機台代碼");
COMMENT ON TABLE "fil300b" IS '3.機台.PLCDataOracle';
COMMENT ON COLUMN "fil300b"."讀取日期" IS '讀取日期 / 讀取時間';
COMMENT ON COLUMN "fil300b"."變更日期" IS '變更日期 / 變更時間';
COMMENT ON COLUMN "fil300b"."行" IS 'ROW';
COMMENT ON COLUMN "fil300b"."列" IS 'COL';
COMMENT ON COLUMN "fil300b"."讀取日時" IS '變更日時';

-- Files：3.機台.PLCDataCode
CREATE TABLE "fil300c" (
    "中文說明" varchar(100) NOT NULL,
    "英文說明" varchar(100) NOT NULL,
    "資料結構" varchar(100) NOT NULL,
    "代碼" varchar(10) NOT NULL,
    "機型一" varchar(50) NOT NULL,
    "機型二" varchar(50) NOT NULL,
    "機型三" varchar(50) NOT NULL,
    "機型四" varchar(50) NOT NULL,
    "機型五" varchar(50) NOT NULL,
    "機型六" varchar(50) NOT NULL,
    "機型七" varchar(50) NOT NULL,
    "機型八" varchar(50) NOT NULL,
    "機型九" varchar(50) NOT NULL,
    "機型十" varchar(50) NOT NULL,
    "備註" varchar(512) NOT NULL
);
CREATE UNIQUE INDEX "fil300c_01" ON "fil300c" ("代碼");
COMMENT ON TABLE "fil300c" IS '3.機台.PLCDataCode';

-- Files：3.機台.裁切PLC_DATA_Oracle
CREATE TABLE "fil300d" (
    "vsprimarykey" varchar(25) DEFAULT ' ' NOT NULL,
    "no_order" varchar(10) DEFAULT ' ',
    "process" varchar(10) DEFAULT ' ',
    "no_mc" varchar(10) DEFAULT ' ',
    "no_roll" numeric(10,0) DEFAULT 0,
    "data_01" numeric(10,0) DEFAULT 0,
    "data_02" numeric(10,0) DEFAULT 0,
    "data_03" numeric(10,0) DEFAULT 0,
    "data_04" numeric(10,0) DEFAULT 0,
    "data_05" numeric(10,0) DEFAULT 0,
    "data_06" numeric(10,0) DEFAULT 0,
    "data_07" numeric(10,0) DEFAULT 0,
    "data_08" numeric(10,0) DEFAULT 0,
    "data_09" numeric(10,0) DEFAULT 0,
    "data_10" numeric(10,0) DEFAULT 0,
    "data_11" numeric(10,0) DEFAULT 0,
    "data_12" numeric(10,0) DEFAULT 0,
    "data_13" numeric(10,0) DEFAULT 0,
    "data_14" numeric(10,0) DEFAULT 0,
    "data_15" numeric(10,0) DEFAULT 0,
    "data_16" numeric(10,0) DEFAULT 0,
    "data_17" numeric(10,0) DEFAULT 0,
    "data_18" numeric(10,0) DEFAULT 0,
    "data_19" numeric(10,0) DEFAULT 0,
    "最佳條件" smallint DEFAULT 0 NOT NULL,
    "0" smallint NOT NULL,
    "備註" varchar(50) NOT NULL
);
CREATE UNIQUE INDEX "fil300dkey1" ON "fil300d" ("vsprimarykey");
CREATE INDEX "fil300dkey3" ON "fil300d" ("no_order", "process");
COMMENT ON TABLE "fil300d" IS '3.機台.裁切PLC_DATA_Oracle';
COMMENT ON COLUMN "fil300d"."no_order" IS '訂單編號';
COMMENT ON COLUMN "fil300d"."process" IS '製程編號';
COMMENT ON COLUMN "fil300d"."no_mc" IS '機器編號';
COMMENT ON COLUMN "fil300d"."no_roll" IS '捲數';
COMMENT ON COLUMN "fil300d"."data_01" IS '目前速度';
COMMENT ON COLUMN "fil300d"."data_02" IS '備用';
COMMENT ON COLUMN "fil300d"."data_03" IS '收捲上目前米數';
COMMENT ON COLUMN "fil300d"."data_04" IS '收捲下目前米數';
COMMENT ON COLUMN "fil300d"."data_05" IS '放料張力設定';
COMMENT ON COLUMN "fil300d"."data_06" IS '放料實際張力';
COMMENT ON COLUMN "fil300d"."data_07" IS '收捲上張力設定';
COMMENT ON COLUMN "fil300d"."data_08" IS '收捲上實際張力';
COMMENT ON COLUMN "fil300d"."data_09" IS '收捲下張力設定';
COMMENT ON COLUMN "fil300d"."data_10" IS '收捲下實際張力';
COMMENT ON COLUMN "fil300d"."data_11" IS '放捲預備力設定';
COMMENT ON COLUMN "fil300d"."data_12" IS '放捲張力遞減設定';
COMMENT ON COLUMN "fil300d"."data_13" IS '放捲張力控制輸出';
COMMENT ON COLUMN "fil300d"."data_14" IS '收捲上預備力設定';
COMMENT ON COLUMN "fil300d"."data_15" IS '收捲上張力遞減設定';
COMMENT ON COLUMN "fil300d"."data_16" IS '收捲上張力控制輸出';
COMMENT ON COLUMN "fil300d"."data_17" IS '收捲下預備力設定';
COMMENT ON COLUMN "fil300d"."data_18" IS '收捲下張力遞減設定';
COMMENT ON COLUMN "fil300d"."data_19" IS '收捲下張力控制輸出';
COMMENT ON COLUMN "fil300d"."0" IS '單據序號';

-- Files：3.機台.拉力機封口測試記錄表
CREATE TABLE "fil3011" (
    "guid" varchar(60) DEFAULT ' ' NOT NULL,
    "日期" char(8) DEFAULT '00000000' NOT NULL,
    "廠客編號" varchar(10) DEFAULT ' ' NOT NULL,
    "製令單號" varchar(20) DEFAULT ' ' NOT NULL,
    "材料結構" varchar(400) DEFAULT ' ' NOT NULL,
    "內厚度" numeric(14,4) NOT NULL,
    "袋型" varchar(3) DEFAULT ' ' NOT NULL,
    "測1" numeric(14,4) NOT NULL,
    "測2" numeric(14,4) NOT NULL,
    "測3" numeric(14,4) NOT NULL,
    "測4" numeric(14,4) NOT NULL,
    "測5" numeric(14,4) NOT NULL,
    "平均" numeric(14,4) NOT NULL,
    "封底" numeric(14,4) NOT NULL,
    "判定" varchar(1) NOT NULL,
    "檢測員" varchar(10) DEFAULT ' ' NOT NULL,
    "備註" varchar(50) NOT NULL,
    "最後更新者" varchar(10) DEFAULT ' ' NOT NULL,
    "最後更新日" timestamp(0)
);
CREATE UNIQUE INDEX "fil3011_key1" ON "fil3011" ("guid");
CREATE UNIQUE INDEX "fil3011_key2" ON "fil3011" ("日期", "guid");
COMMENT ON TABLE "fil3011" IS '3.機台.拉力機封口測試記錄表';
COMMENT ON COLUMN "fil3011"."guid" IS '流水編號';
COMMENT ON COLUMN "fil3011"."最後更新日" IS '最後更新日 / 最後更新時';

-- Files：3.機台.溶濟殘留異味測試記錄表
CREATE TABLE "fil3012" (
    "guid" varchar(60) DEFAULT ' ' NOT NULL,
    "日期" char(8) DEFAULT '00000000' NOT NULL,
    "檢測時間" char(6) DEFAULT '000000' NOT NULL,
    "製令單號" varchar(20) DEFAULT ' ' NOT NULL,
    "ipa" smallint DEFAULT 0 NOT NULL,
    "mek" smallint DEFAULT 0 NOT NULL,
    "eac" smallint DEFAULT 0 NOT NULL,
    "toluene" smallint DEFAULT 0 NOT NULL,
    "無溶劑貼合" smallint DEFAULT 0 NOT NULL,
    "檢測員" varchar(10) DEFAULT ' ' NOT NULL,
    "加工別" varchar(1) DEFAULT ' ' NOT NULL,
    "合格" smallint DEFAULT 0 NOT NULL,
    "備註" varchar(50) DEFAULT ' ' NOT NULL,
    "最後更新者" varchar(10) DEFAULT ' ' NOT NULL,
    "最後更新日" timestamp(0)
);
CREATE UNIQUE INDEX "fil3012_key1" ON "fil3012" ("guid");
CREATE UNIQUE INDEX "fil3012_key2" ON "fil3012" ("日期", "guid");
COMMENT ON TABLE "fil3012" IS '3.機台.溶濟殘留異味測試記錄表';
COMMENT ON COLUMN "fil3012"."guid" IS '流水編號';
COMMENT ON COLUMN "fil3012"."最後更新日" IS '最後更新日 / 最後更新時';

-- Files：3.機台.摩擦係數測定檢測記錄表
CREATE TABLE "fil3013" (
    "guid" varchar(60) DEFAULT ' ' NOT NULL,
    "日期" char(8) DEFAULT '00000000' NOT NULL,
    "廠客編號" varchar(10) DEFAULT ' ' NOT NULL,
    "製令單號" varchar(20) DEFAULT ' ' NOT NULL,
    "材料結構" varchar(400) DEFAULT ' ' NOT NULL,
    "製程別" smallint DEFAULT 1 NOT NULL,
    "裁切" smallint DEFAULT 1 NOT NULL,
    "成捲" smallint DEFAULT 0 NOT NULL,
    "加工別" varchar(1) DEFAULT 'A' NOT NULL,
    "編號" varchar(10) DEFAULT ' ' NOT NULL,
    "靜態系數" numeric(14,4) DEFAULT 0 NOT NULL,
    "動態系數" numeric(14,4) DEFAULT 0 NOT NULL,
    "摩擦系數一" varchar(16) DEFAULT ' ' NOT NULL,
    "摩擦系數二" varchar(16) DEFAULT ' ' NOT NULL,
    "摩擦系數三" varchar(16) DEFAULT ' ' NOT NULL,
    "量測一" numeric(14,4) DEFAULT 0 NOT NULL,
    "量測二" numeric(14,4) DEFAULT 0 NOT NULL,
    "量測三" numeric(14,4) DEFAULT 0 NOT NULL,
    "判定" varchar(1) DEFAULT 'A' NOT NULL,
    "檢測員" varchar(10) DEFAULT ' ' NOT NULL,
    "備註" varchar(50) DEFAULT ' ' NOT NULL,
    "最後更新者" varchar(10) DEFAULT ' ' NOT NULL,
    "最後更新日" timestamp(0)
);
CREATE UNIQUE INDEX "fil3013_key1" ON "fil3013" ("guid");
CREATE UNIQUE INDEX "fil3013_key2" ON "fil3013" ("日期", "guid");
COMMENT ON TABLE "fil3013" IS '3.機台.摩擦係數測定檢測記錄表';
COMMENT ON COLUMN "fil3013"."guid" IS '流水編號';
COMMENT ON COLUMN "fil3013"."最後更新日" IS '最後更新日 / 最後更新時';

-- Files：4.機台.原料測試記錄表
CREATE TABLE "fil3014" (
    "guid" varchar(60) DEFAULT ' ' NOT NULL,
    "日期" char(8) DEFAULT '00000000' NOT NULL,
    "進料日期" char(8) DEFAULT '00000000' NOT NULL,
    "廠商" varchar(20) DEFAULT ' ' NOT NULL,
    "原料編號" varchar(20) DEFAULT ' ' NOT NULL,
    "厚度" numeric(5,1) DEFAULT 0 NOT NULL,
    "測試厚度一" smallint DEFAULT 0 NOT NULL,
    "測試厚度二" smallint DEFAULT 0 NOT NULL,
    "測試厚度三" smallint DEFAULT 0 NOT NULL,
    "測試厚度平均" numeric(5,1) DEFAULT 0 NOT NULL,
    "喜美批號" varchar(40) DEFAULT ' ' NOT NULL,
    "批號" varchar(40) DEFAULT ' ' NOT NULL,
    "MD斷裂強度值測試1" numeric(6,2) DEFAULT 0 NOT NULL,
    "MD斷裂強度值測試2" numeric(6,2) DEFAULT 0 NOT NULL,
    "MD斷裂強度值測試3" numeric(6,2) DEFAULT 0 NOT NULL,
    "MD斷裂強度值平均一" numeric(6,2) DEFAULT 0 NOT NULL,
    "MD斷裂強度值測試4" numeric(6,2) DEFAULT 0 NOT NULL,
    "MD斷裂強度值測試5" numeric(6,2) DEFAULT 0 NOT NULL,
    "MD斷裂強度值測試6" numeric(6,2) DEFAULT 0 NOT NULL,
    "MD斷裂強度值平均二" numeric(6,2) DEFAULT 0 NOT NULL,
    "MD斷裂強度值測試7" numeric(6,2) DEFAULT 0 NOT NULL,
    "MD斷裂強度值測試8" numeric(6,2) DEFAULT 0 NOT NULL,
    "MD斷裂強度值測試9" numeric(6,2) DEFAULT 0 NOT NULL,
    "MD斷裂強度值平均三" numeric(6,2) DEFAULT 0 NOT NULL,
    "TD斷裂強度值測試1" numeric(6,2) DEFAULT 0 NOT NULL,
    "TD斷裂強度值測試2" numeric(6,2) DEFAULT 0 NOT NULL,
    "TD斷裂強度值測試3" numeric(6,2) DEFAULT 0 NOT NULL,
    "TD斷裂強度值平均一" numeric(6,2) DEFAULT 0 NOT NULL,
    "TD斷裂強度值測試4" numeric(6,2) DEFAULT 0 NOT NULL,
    "TD斷裂強度值測試5" numeric(6,2) DEFAULT 0 NOT NULL,
    "TD斷裂強度值測試6" numeric(6,2) DEFAULT 0 NOT NULL,
    "TD斷裂強度值平均二" numeric(6,2) DEFAULT 0 NOT NULL,
    "TD斷裂強度值測試7" numeric(6,2) DEFAULT 0 NOT NULL,
    "TD斷裂強度值測試8" numeric(6,2) DEFAULT 0 NOT NULL,
    "TD斷裂強度值測試9" numeric(6,2) DEFAULT 0 NOT NULL,
    "TD斷裂強度值平均三" numeric(6,2) DEFAULT 0 NOT NULL,
    "熱封溫度_假性黏著" numeric(4,0) DEFAULT 0 NOT NULL,
    "熱封溫度_確封溫度" numeric(4,0) DEFAULT 0 NOT NULL,
    "摩擦係數_動" numeric(3,2) DEFAULT 0 NOT NULL,
    "摩擦係數_靜" numeric(3,2) DEFAULT 0 NOT NULL,
    "拉力測試判定" varchar(1) DEFAULT 'A' NOT NULL,
    "熱封溫度判定" varchar(1) DEFAULT 'A' NOT NULL,
    "摩擦係數判定" varchar(1) DEFAULT 'A' NOT NULL,
    "檢測員1" varchar(10) DEFAULT ' ' NOT NULL,
    "檢測員2" varchar(10) DEFAULT ' ' NOT NULL,
    "檢測員3" varchar(10) DEFAULT ' ' NOT NULL,
    "拉力測試備註" varchar(50) DEFAULT ' ' NOT NULL,
    "熱封溫度備註" varchar(50) DEFAULT ' ' NOT NULL,
    "摩擦係數備註" varchar(50) DEFAULT ' ' NOT NULL,
    "檢測日期1" timestamp(0),
    "檢測日期2" timestamp(0),
    "檢測日期3" timestamp(0),
    "排序" smallint DEFAULT 0 NOT NULL,
    "最後更新者" varchar(10) DEFAULT ' ' NOT NULL,
    "最後更新日" timestamp(0)
);
CREATE UNIQUE INDEX "fil3014_key1" ON "fil3014" ("guid");
CREATE UNIQUE INDEX "fil3014_key2" ON "fil3014" ("日期", "guid");
CREATE UNIQUE INDEX "fil3014_key3" ON "fil3014" ("排序", "日期", "guid");
COMMENT ON TABLE "fil3014" IS '4.機台.原料測試記錄表';
COMMENT ON COLUMN "fil3014"."guid" IS '流水編號';
COMMENT ON COLUMN "fil3014"."批號" IS '廠商批號';
COMMENT ON COLUMN "fil3014"."檢測日期1" IS '檢測日期1 / 檢測時間1';
COMMENT ON COLUMN "fil3014"."檢測日期2" IS '檢測日期2 / 檢測時間2';
COMMENT ON COLUMN "fil3014"."檢測日期3" IS '檢測日期3 / 檢測時間3';
COMMENT ON COLUMN "fil3014"."最後更新日" IS '最後更新日 / 最後更新時';

-- Files：4.網站.詢價
CREATE TABLE "fil4001" (
    "流水編號" varchar(60) DEFAULT ' ' NOT NULL,
    "聯絡人" varchar(50) DEFAULT ' ' NOT NULL,
    "聯絡電話" varchar(20) DEFAULT ' ' NOT NULL,
    "電子郵件" varchar(100) DEFAULT ' ' NOT NULL,
    "成品類型" varchar(10) DEFAULT ' ' NOT NULL,
    "成捲品寬度" varchar(10) DEFAULT ' ' NOT NULL,
    "成捲品長度" varchar(10) DEFAULT ' ' NOT NULL,
    "袋型" varchar(10) DEFAULT ' ' NOT NULL,
    "袋子高度" varchar(10) DEFAULT ' ' NOT NULL,
    "袋子寬度" varchar(10) DEFAULT ' ' NOT NULL,
    "袋子長度" varchar(10) DEFAULT ' ' NOT NULL,
    "需夾鏈否" varchar(10) DEFAULT ' ' NOT NULL,
    "夾鏈類型" varchar(10) DEFAULT ' ' NOT NULL,
    "夾鏈樣式" varchar(10) DEFAULT ' ' NOT NULL,
    "第一色" varchar(20) DEFAULT ' ' NOT NULL,
    "第二色" varchar(20) DEFAULT ' ' NOT NULL,
    "第三色" varchar(20) DEFAULT ' ' NOT NULL,
    "第四色" varchar(20) DEFAULT ' ' NOT NULL,
    "第五色" varchar(20) DEFAULT ' ' NOT NULL,
    "第六色" varchar(20) DEFAULT ' ' NOT NULL,
    "第七色" varchar(20) DEFAULT ' ' NOT NULL,
    "第八色" varchar(20) DEFAULT ' ' NOT NULL,
    "第九色" varchar(20) DEFAULT ' ' NOT NULL,
    "第十色" varchar(20) DEFAULT ' ' NOT NULL,
    "共幾層" varchar(1) DEFAULT ' ' NOT NULL,
    "第一層材料" varchar(40) DEFAULT ' ' NOT NULL,
    "第一層厚度" varchar(10) DEFAULT ' ' NOT NULL,
    "第一層貼合" varchar(10) DEFAULT ' ' NOT NULL,
    "第二層材料" varchar(40) DEFAULT ' ' NOT NULL,
    "第二層厚度" varchar(10) DEFAULT ' ' NOT NULL,
    "第二層貼合" varchar(10) DEFAULT ' ' NOT NULL,
    "第三層材料" varchar(40) DEFAULT ' ' NOT NULL,
    "第三層厚度" varchar(10) DEFAULT ' ' NOT NULL,
    "第三層貼合" varchar(10) DEFAULT ' ' NOT NULL,
    "第四層材料" varchar(40) DEFAULT ' ' NOT NULL,
    "第四層厚度" varchar(10) DEFAULT ' ' NOT NULL,
    "第四層貼合" varchar(10) DEFAULT ' ' NOT NULL,
    "第五層材料" varchar(40) DEFAULT ' ' NOT NULL,
    "第五層厚度" varchar(10) DEFAULT ' ' NOT NULL,
    "第五層貼合" varchar(10) DEFAULT ' ' NOT NULL,
    "第六層材料" varchar(40) DEFAULT ' ' NOT NULL,
    "第六層厚度" varchar(10) DEFAULT ' ' NOT NULL,
    "第六層貼合" varchar(10) DEFAULT ' ' NOT NULL,
    "化學性質" varchar(256) DEFAULT ' ' NOT NULL,
    "物理性質" varchar(256) DEFAULT ' ' NOT NULL,
    "數量條件" varchar(256) DEFAULT ' ' NOT NULL,
    "商當的包裝材料" varchar(256) DEFAULT ' ' NOT NULL,
    "包裝技法" varchar(256) DEFAULT ' ' NOT NULL,
    "需要的包裝的期間" varchar(256) DEFAULT ' ' NOT NULL,
    "在此期限間的溫度及濕度" varchar(256) DEFAULT ' ' NOT NULL,
    "運輸或者貯藏單位的包裝容器" varchar(256) DEFAULT ' ' NOT NULL,
    "運輸或者貯藏中的振動衝擊" varchar(256) DEFAULT ' ' NOT NULL,
    "詢價單號" varchar(20) DEFAULT ' ' NOT NULL,
    "新增日期" char(8) DEFAULT '00000000' NOT NULL,
    "新增時間" char(6) DEFAULT '000000' NOT NULL
);
CREATE INDEX "fil4001key2" ON "fil4001" ("詢價單號");
CREATE INDEX "fil4001key3" ON "fil4001" ("新增日期", "新增時間");
CREATE UNIQUE INDEX "fil4001key1" ON "fil4001" ("流水編號", "聯絡人");
COMMENT ON TABLE "fil4001" IS '4.網站.詢價';

-- Files：4.材料.報價
CREATE TABLE "fil4002" (
    "代碼" varchar(20) DEFAULT ' ' NOT NULL,
    "生效日期" char(8) DEFAULT '00000000' NOT NULL,
    "單位報價" numeric(7,2) DEFAULT 0 NOT NULL,
    "成本單價" numeric(7,2) DEFAULT 0 NOT NULL
);
CREATE UNIQUE INDEX "fil4002key1" ON "fil4002" ("代碼", "生效日期");
CREATE UNIQUE INDEX "fil4002key2" ON "fil4002" ("生效日期", "代碼");
COMMENT ON TABLE "fil4002" IS '4.材料.報價';

-- Files：4.璿揚ARInvAdd
CREATE TABLE "fil4003" (
    "流水編號" varchar(60) DEFAULT ' ' NOT NULL,
    "connectid" varchar(30) NOT NULL,
    "結帳單別" varchar(10) NOT NULL,
    "結帳單號" varchar(20) NOT NULL,
    "結帳方式" varchar(20) NOT NULL,
    "發票日期" varchar(10) NOT NULL,
    "發票號碼起" varchar(20) NOT NULL,
    "發票號碼迄" varchar(20) NOT NULL,
    "課稅別" varchar(10) NOT NULL,
    "統一編號" varchar(10) NOT NULL,
    "客戶編號" varchar(10) NOT NULL,
    "發票聯數" varchar(10) NOT NULL,
    "營業台幣稅率" varchar(10) NOT NULL,
    "發票台幣未稅金額" varchar(20) NOT NULL,
    "發票台幣稅額" varchar(20) NOT NULL,
    "發票台幣含稅金額" varchar(20) NOT NULL,
    "原幣應收金額" varchar(20) NOT NULL,
    "原幣幣別" varchar(10) NOT NULL,
    "銷退憑單" varchar(100) NOT NULL,
    "新增日期" char(8) NOT NULL,
    "新增時間" char(6) NOT NULL
);
CREATE UNIQUE INDEX "fil4003_key1" ON "fil4003" ("流水編號");
CREATE INDEX "fil4003_key2" ON "fil4003" ("新增日期", "新增時間");
COMMENT ON TABLE "fil4003" IS '4.璿揚ARInvAdd';
COMMENT ON COLUMN "fil4003"."流水編號" IS '0.流水編號';

-- Files：5..材料月批號庫存(分倉)
CREATE TABLE "fil5001" (
    "材料編號" varchar(70) NOT NULL,
    "批號" varchar(40) DEFAULT ' ' NOT NULL,
    "倉庫代碼" varchar(40) NOT NULL,
    "月份" varchar(6) NOT NULL,
    "庫存數量" numeric(14,4) DEFAULT 0 NOT NULL,
    PRIMARY KEY ("材料編號", "批號", "倉庫代碼", "月份")
);
CREATE UNIQUE INDEX "fil5001_02" ON "fil5001" ("月份", "材料編號", "批號", "倉庫代碼");
COMMENT ON TABLE "fil5001" IS '5..材料月批號庫存(分倉)';

-- Files：5..材料月批號庫存(不分倉)
CREATE TABLE "fil5002" (
    "材料編號" varchar(20) DEFAULT ' ' NOT NULL,
    "批號" varchar(40) DEFAULT ' ' NOT NULL,
    "月份" varchar(6) NOT NULL,
    "庫存數量" numeric(14,4) DEFAULT 0 NOT NULL,
    PRIMARY KEY ("材料編號", "批號", "月份")
);
CREATE UNIQUE INDEX "fil5002_02" ON "fil5002" ("月份", "材料編號", "批號");
COMMENT ON TABLE "fil5002" IS '5..材料月批號庫存(不分倉)';

-- Files：A01單據屬性；EDB：單據屬性
CREATE TABLE "a01" (
    "serial_num" varchar(60) DEFAULT ' ' NOT NULL,
    "name" varchar(256) DEFAULT ' ' NOT NULL,
    "owner" varchar(60) DEFAULT ' ' NOT NULL,
    "version" integer DEFAULT 0 NOT NULL,
    "status" varchar(1) DEFAULT ' ' NOT NULL,
    "createdate" char(8) DEFAULT '00000000' NOT NULL,
    "createtime" char(6) DEFAULT '000000' NOT NULL,
    "companyid" varchar(60) DEFAULT ' ' NOT NULL,
    "deptid" varchar(60) DEFAULT ' ' NOT NULL,
    "applyby" varchar(60) DEFAULT ' ' NOT NULL,
    "verifiedby" varchar(60) DEFAULT ' ' NOT NULL,
    "flowstatus" varchar(1) DEFAULT ' ' NOT NULL,
    "urgency" smallint DEFAULT 0 NOT NULL,
    "special" smallint DEFAULT 0 NOT NULL,
    "duedate" char(8) DEFAULT '00000000' NOT NULL,
    "verified" smallint DEFAULT 0 NOT NULL,
    "needtransfer" smallint DEFAULT 0 NOT NULL,
    "ending" smallint DEFAULT 0 NOT NULL,
    "connectid" integer DEFAULT 0 NOT NULL,
    "accmonth" char(8) DEFAULT '00000000' NOT NULL,
    "locked" smallint DEFAULT 0 NOT NULL,
    "lockedby" varchar(60) DEFAULT ' ' NOT NULL,
    "fromid" varchar(60) DEFAULT ' ' NOT NULL,
    "projectserialno" varchar(60) DEFAULT ' ' NOT NULL,
    "morderserialno" varchar(60) DEFAULT ' ' NOT NULL,
    "processid" varchar(60) DEFAULT ' ' NOT NULL,
    "costdeptid" varchar(60) DEFAULT ' ' NOT NULL,
    "objectid" varchar(60) DEFAULT ' ' NOT NULL,
    "proucdid" varchar(60) DEFAULT ' ' NOT NULL,
    "關鍵字" varchar(256) DEFAULT ' ' NOT NULL,
    "異動日期" char(8) DEFAULT '00000000' NOT NULL,
    "異動時間" char(6) DEFAULT '000000' NOT NULL,
    PRIMARY KEY ("serial_num")
);
CREATE INDEX "a01key2" ON "a01" ("projectserialno");
CREATE INDEX "a01key3" ON "a01" ("morderserialno");
CREATE INDEX "a01key4" ON "a01" ("fromid");
CREATE INDEX "a01key5" ON "a01" ("異動日期", "異動時間");
COMMENT ON TABLE "a01" IS 'A01單據屬性';
COMMENT ON COLUMN "a01"."serial_num" IS '單據流水號';
COMMENT ON COLUMN "a01"."name" IS '單據名稱';
COMMENT ON COLUMN "a01"."owner" IS '開單人流水號';
COMMENT ON COLUMN "a01"."version" IS '版本';
COMMENT ON COLUMN "a01"."status" IS '狀態';
COMMENT ON COLUMN "a01"."createdate" IS '開單日期';
COMMENT ON COLUMN "a01"."createtime" IS '開單時間';
COMMENT ON COLUMN "a01"."companyid" IS '公司流水號';
COMMENT ON COLUMN "a01"."deptid" IS '部門流水號';
COMMENT ON COLUMN "a01"."applyby" IS '申請人流水號';
COMMENT ON COLUMN "a01"."verifiedby" IS '核銷人員';
COMMENT ON COLUMN "a01"."flowstatus" IS '簽核狀態';
COMMENT ON COLUMN "a01"."urgency" IS '緊急否';
COMMENT ON COLUMN "a01"."special" IS '特殊否';
COMMENT ON COLUMN "a01"."duedate" IS '簽核期限';
COMMENT ON COLUMN "a01"."verified" IS '已核銷';
COMMENT ON COLUMN "a01"."needtransfer" IS '需要轉單';
COMMENT ON COLUMN "a01"."ending" IS '結案';
COMMENT ON COLUMN "a01"."accmonth" IS '帳月';
COMMENT ON COLUMN "a01"."locked" IS '鎖定';
COMMENT ON COLUMN "a01"."lockedby" IS '被誰鎖定';
COMMENT ON COLUMN "a01"."fromid" IS '訂單流水號';
COMMENT ON COLUMN "a01"."projectserialno" IS '專案流水號';
COMMENT ON COLUMN "a01"."morderserialno" IS '製令流水號';
COMMENT ON COLUMN "a01"."processid" IS '作業流水號';
COMMENT ON COLUMN "a01"."costdeptid" IS '成本歸屬部門';
COMMENT ON COLUMN "a01"."objectid" IS '對象流水號';
COMMENT ON COLUMN "a01"."proucdid" IS '產品流水號';

-- Files：A30群組資料；EDB：A30群組資料
CREATE TABLE "a30" (
    "serial_num" varchar(60) DEFAULT ' ' NOT NULL,
    "groupid" varchar(10) DEFAULT ' ' NOT NULL,
    "groupname" varchar(20) DEFAULT ' ' NOT NULL,
    "engname" varchar(100) NOT NULL,
    "allowance" numeric(10,0) DEFAULT 0 NOT NULL,
    "ended" smallint DEFAULT 0 NOT NULL,
    "description" varchar(100) DEFAULT ' ' NOT NULL,
    "belongto" varchar(60) DEFAULT ' ' NOT NULL,
    "uppergroup" varchar(60) DEFAULT ' ' NOT NULL,
    "guname" varchar(100) DEFAULT ' ' NOT NULL,
    PRIMARY KEY ("serial_num")
);
CREATE UNIQUE INDEX "a30key2" ON "a30" ("groupid");
CREATE INDEX "a30key3" ON "a30" ("belongto", "groupid");
COMMENT ON TABLE "a30" IS 'A30群組資料';
COMMENT ON COLUMN "a30"."serial_num" IS '流水編號';
COMMENT ON COLUMN "a30"."groupid" IS '群組代碼';
COMMENT ON COLUMN "a30"."groupname" IS '群組名稱';
COMMENT ON COLUMN "a30"."engname" IS '英文名稱';
COMMENT ON COLUMN "a30"."allowance" IS '出勤津貼';
COMMENT ON COLUMN "a30"."ended" IS '停止使用';
COMMENT ON COLUMN "a30"."description" IS '群組說明';
COMMENT ON COLUMN "a30"."belongto" IS '所屬公司';
COMMENT ON COLUMN "a30"."uppergroup" IS '上階部門';

-- Files：A40職稱資料；EDB：A40職稱資料
CREATE TABLE "a40" (
    "serial_num" varchar(60) DEFAULT ' ' NOT NULL,
    "psoiid" varchar(5) DEFAULT ' ' NOT NULL,
    "guname" varchar(20) DEFAULT ' ' NOT NULL,
    "posiename" varchar(20) DEFAULT ' ' NOT NULL,
    "positype" varchar(1) DEFAULT ' ' NOT NULL,
    "depmanager" smallint DEFAULT 0 NOT NULL,
    PRIMARY KEY ("serial_num")
);
CREATE UNIQUE INDEX "a40key2" ON "a40" ("psoiid");
CREATE INDEX "a40key3" ON "a40" ("positype", "guname");
CREATE INDEX "a40key4" ON "a40" ("positype", "psoiid");
CREATE INDEX "a40key5" ON "a40" ("depmanager");
COMMENT ON TABLE "a40" IS 'A40職稱資料';
COMMENT ON COLUMN "a40"."serial_num" IS '流水編號';
COMMENT ON COLUMN "a40"."psoiid" IS '職稱代碼';
COMMENT ON COLUMN "a40"."guname" IS '職稱名稱';
COMMENT ON COLUMN "a40"."posiename" IS '職稱英文';
COMMENT ON COLUMN "a40"."positype" IS '職稱識別碼';
COMMENT ON COLUMN "a40"."depmanager" IS '限定部門';

-- Files：A50公司資料；EDB：A50公司資料
CREATE TABLE "a50" (
    "serial_num" varchar(60) DEFAULT ' ' NOT NULL,
    "cmpid" varchar(3) DEFAULT ' ' NOT NULL,
    "guname" varchar(50) DEFAULT ' ' NOT NULL,
    "country" varchar(20) DEFAULT ' ' NOT NULL,
    "area" varchar(10) DEFAULT ' ' NOT NULL,
    "taxrate" varchar(1) DEFAULT ' ' NOT NULL,
    "currency" varchar(4) DEFAULT ' ' NOT NULL,
    PRIMARY KEY ("serial_num")
);
CREATE UNIQUE INDEX "a50key2" ON "a50" ("cmpid");
COMMENT ON TABLE "a50" IS 'A50公司資料';
COMMENT ON COLUMN "a50"."serial_num" IS '流水編號';
COMMENT ON COLUMN "a50"."cmpid" IS '公司代碼';
COMMENT ON COLUMN "a50"."guname" IS '公司名稱';
COMMENT ON COLUMN "a50"."country" IS '國別';
COMMENT ON COLUMN "a50"."area" IS '區域';
COMMENT ON COLUMN "a50"."taxrate" IS '公司稅率';
COMMENT ON COLUMN "a50"."currency" IS '公司幣別';

-- Files：A06代理人；EDB：A60代理人
CREATE TABLE "a60_7" (
    "serial_num" varchar(60) DEFAULT ' ' NOT NULL,
    "asignee" varchar(60) DEFAULT ' ' NOT NULL,
    "datefrom" char(8) NOT NULL,
    "dateto" char(8) NOT NULL,
    "recordid" varchar(60) DEFAULT ' ' NOT NULL,
    PRIMARY KEY ("recordid")
);
CREATE INDEX "a60_7key1" ON "a60_7" ("serial_num", "asignee", "datefrom", "dateto");
COMMENT ON TABLE "a60_7" IS 'A06代理人';
COMMENT ON COLUMN "a60_7"."serial_num" IS '流水編號';
COMMENT ON COLUMN "a60_7"."asignee" IS '代理人流水號';
COMMENT ON COLUMN "a60_7"."datefrom" IS '日期起';
COMMENT ON COLUMN "a60_7"."dateto" IS '日期迄';

-- Files：A60管轄部門；EDB：A60管轄部門
CREATE TABLE "a60_8" (
    "serial_num" varchar(60) DEFAULT ' ' NOT NULL,
    "serial_num_seq" integer NOT NULL,
    "depid" varchar(60) DEFAULT ' ' NOT NULL,
    "recordid" varchar(60) DEFAULT ' ' NOT NULL
);
CREATE UNIQUE INDEX "a60_1key0" ON "a60_8" ("recordid");
CREATE UNIQUE INDEX "a60_8key1" ON "a60_8" ("serial_num", "serial_num_seq");
CREATE UNIQUE INDEX "a60_8key2" ON "a60_8" ("serial_num", "depid");
COMMENT ON TABLE "a60_8" IS 'A60管轄部門';
COMMENT ON COLUMN "a60_8"."serial_num" IS '流水編號';
COMMENT ON COLUMN "a60_8"."serial_num_seq" IS '表身序號';
COMMENT ON COLUMN "a60_8"."depid" IS '部門流水號';

-- Files：卡鐘匯入資料
CREATE TABLE "dtfil001" (
    "人員識別碼" varchar(30) NOT NULL,
    "員工代號" varchar(30) NOT NULL,
    "通行模式" varchar(30) NOT NULL,
    "認證模式" varchar(30) NOT NULL,
    "辨識模式" varchar(30) NOT NULL,
    "相似度" varchar(30) NOT NULL,
    "是否活體" varchar(30) NOT NULL,
    "活體分數" varchar(30) NOT NULL,
    "人員姓名" varchar(30) NOT NULL,
    "卡號" varchar(30) NOT NULL,
    "時間戳記" varchar(30) NOT NULL,
    "載口罩否" varchar(30) NOT NULL,
    "測瀋通過否" varchar(30) NOT NULL,
    "體溫" varchar(30) NOT NULL,
    "門禁訊息" varchar(30) NOT NULL,
    "收集日期" char(8) DEFAULT '00000000' NOT NULL,
    "收集時間" char(6) DEFAULT '000000' NOT NULL,
    "來源" varchar(20) DEFAULT ' ' NOT NULL
);
CREATE UNIQUE INDEX "dtfil001_key1" ON "dtfil001" ("員工代號", "時間戳記");
CREATE INDEX "dtfil001_key2" ON "dtfil001" ("收集日期", "收集時間");
COMMENT ON TABLE "dtfil001" IS '卡鐘匯入資料';

-- Files：卡鐘匯入資料二
CREATE TABLE "dtfil002" (
    "人員識別碼" varchar(30) NOT NULL,
    "員工代號" varchar(30) NOT NULL,
    "通行模式" varchar(30) NOT NULL,
    "認證模式" varchar(30) NOT NULL,
    "辨識模式" varchar(30) NOT NULL,
    "相似度" varchar(30) NOT NULL,
    "是否活體" varchar(30) NOT NULL,
    "活體分數" varchar(30) NOT NULL,
    "人員姓名" varchar(30) NOT NULL,
    "卡號" varchar(30) NOT NULL,
    "時間戳記" varchar(30) NOT NULL,
    "載口罩否" varchar(30) NOT NULL,
    "測瀋通過否" varchar(30) NOT NULL,
    "體溫" varchar(30) NOT NULL,
    "門禁訊息" varchar(30) NOT NULL,
    "收集日期" char(8) DEFAULT '00000000' NOT NULL,
    "收集時間" char(6) DEFAULT '000000' NOT NULL,
    "來源" varchar(20) DEFAULT ' ' NOT NULL
);
CREATE UNIQUE INDEX "dtfil002_key1" ON "dtfil002" ("員工代號", "時間戳記");
CREATE INDEX "dtfil002_key2" ON "dtfil002" ("收集日期", "收集時間");
COMMENT ON TABLE "dtfil002" IS '卡鐘匯入資料二';

-- Files：View.材料庫存數_S(不分倉)_WK
CREATE TABLE "film008s_wk" (
    "材料編號" varchar(30) DEFAULT ' ' NOT NULL,
    "庫存數" numeric(13,3) DEFAULT 0,
    "品名" varchar(100) DEFAULT ' ' NOT NULL,
    "規格" varchar(100) DEFAULT ' ' NOT NULL
);
CREATE UNIQUE INDEX "film008s_wkkey1" ON "film008s_wk" ("材料編號");
COMMENT ON TABLE "film008s_wk" IS 'View.材料庫存數_S(不分倉)_WK';

-- Files：WK.不分倉批號異動檔_H
CREATE TABLE "wkfilm018h" (
    "單別" varchar(10) DEFAULT ' ',
    "單號" varchar(20) DEFAULT ' ',
    "序號" numeric(13,3) DEFAULT 0,
    "單據日期" char(8) DEFAULT '00000000' NOT NULL,
    "批號" varchar(160) DEFAULT ' ',
    "異動類別" varchar(10) DEFAULT ' ',
    "製程代碼" varchar(10) DEFAULT ' ',
    "接頭數" numeric(13,3) DEFAULT 0,
    "最後接頭數" numeric(13,3) DEFAULT 0,
    "圓周" numeric(13,3) DEFAULT 0,
    "規格" varchar(80) DEFAULT ' ',
    "熟成條件" varchar(200) DEFAULT ' ',
    "來源" varchar(8) DEFAULT ' ',
    "異動數" numeric(13,3) DEFAULT 0,
    "最後更新日" timestamp(0)
);
CREATE UNIQUE INDEX "wkfilm018hkey1" ON "wkfilm018h" ("單別", "單號", "序號", "異動類別", "批號", "來源");
CREATE INDEX "wkfilm018hkey2" ON "wkfilm018h" ("單據日期", "最後更新日");
COMMENT ON TABLE "wkfilm018h" IS 'WK.不分倉批號異動檔_H';
COMMENT ON COLUMN "wkfilm018h"."最後更新日" IS '最後更新日 / 最後更新日_time';

-- Files：WK.材料不分倉批號庫存_S
CREATE TABLE "wkfilm017s" (
    "材料編號" varchar(30) NOT NULL,
    "物料大類" varchar(10) NOT NULL,
    "品名" varchar(100) NOT NULL,
    "規格" varchar(100) NOT NULL,
    "批號" varchar(40),
    "庫存數" numeric(14,4),
    "廠客編號" varchar(10) NOT NULL
);
CREATE UNIQUE INDEX "wkfilm017skey1" ON "wkfilm017s" ("批號", "廠客編號", "材料編號", "物料大類", "品名", "規格");
CREATE INDEX "wkfilm017skey2" ON "wkfilm017s" ("批號", "材料編號", "物料大類", "品名", "規格");
COMMENT ON TABLE "wkfilm017s" IS 'WK.材料不分倉批號庫存_S';

-- Files：WK.材料異動數
CREATE TABLE "wkfil2022" (
    "單別" varchar(10) DEFAULT ' ' NOT NULL,
    "單號" varchar(20) DEFAULT ' ' NOT NULL,
    "序號" smallint DEFAULT 0 NOT NULL,
    "異動日期" char(8) DEFAULT '00000000' NOT NULL,
    "異動數量" numeric(14,4) DEFAULT 0 NOT NULL,
    "贈品數量" numeric(14,4) DEFAULT 0 NOT NULL,
    "材料編號" varchar(20) DEFAULT ' ' NOT NULL,
    "單位代碼" varchar(10) DEFAULT ' ' NOT NULL,
    "庫存單位" varchar(10) DEFAULT ' ' NOT NULL,
    "倉庫代碼" varchar(10) DEFAULT ' ' NOT NULL,
    "庫存參數" smallint DEFAULT 0 NOT NULL,
    "換算率" numeric(16,6) DEFAULT 0 NOT NULL,
    "異動數" numeric(14,4) DEFAULT 0 NOT NULL,
    "批號" varchar(40) DEFAULT ' ' NOT NULL,
    "前置單別" varchar(10) DEFAULT ' ' NOT NULL,
    "前置單號" varchar(30) DEFAULT ' ' NOT NULL,
    "採購單別" varchar(10) DEFAULT ' ' NOT NULL,
    "採購單號" varchar(20) DEFAULT ' ' NOT NULL,
    "採購序號" smallint DEFAULT 0 NOT NULL,
    "備註說明" varchar(100) DEFAULT ' ' NOT NULL,
    "廠商批號" varchar(40) DEFAULT ' ' NOT NULL,
    PRIMARY KEY ("單別", "單號", "序號")
);
CREATE INDEX "wkfil2022key02" ON "wkfil2022" ("異動日期", "材料編號", "倉庫代碼");
CREATE INDEX "wkfil2022key03" ON "wkfil2022" ("材料編號", "倉庫代碼", "異動日期");
CREATE INDEX "wkfil2022key04" ON "wkfil2022" ("材料編號", "異動日期" DESC, "單別", "單號");
CREATE INDEX "wkfil2022key05" ON "wkfil2022" ("批號", "異動日期", "單別", "單號");
CREATE INDEX "wkfil2022key06" ON "wkfil2022" ("前置單別", "前置單號", "材料編號");
CREATE INDEX "wkfil2022key07" ON "wkfil2022" ("廠商批號", "異動日期");
COMMENT ON TABLE "wkfil2022" IS 'WK.材料異動數';
COMMENT ON COLUMN "wkfil2022"."採購單別" IS '採購單別(D11)';
COMMENT ON COLUMN "wkfil2022"."採購單號" IS '採購單號(D11)';
COMMENT ON COLUMN "wkfil2022"."採購序號" IS '採購序號(D11)';

-- Files：u.欄位異動記錄；EDB：單據異動記錄
CREATE TABLE "filu001" (
    "異動流水編號" varchar(60) DEFAULT ' ' NOT NULL,
    "單據流水編號" varchar(60) DEFAULT ' ' NOT NULL,
    "單據序號1" numeric(18,0) DEFAULT 0 NOT NULL,
    "單據序號2" numeric(18,0) DEFAULT 0 NOT NULL,
    "單據序號3" numeric(18,0) DEFAULT 0 NOT NULL,
    "欄位名稱" varchar(50) DEFAULT ' ' NOT NULL,
    "異動狀態" varchar(10) DEFAULT ' ' NOT NULL,
    "修改前" text,
    "修改後" text,
    "異動批號" varchar(60) DEFAULT ' ' NOT NULL,
    "最後更新者" varchar(10) DEFAULT ' ' NOT NULL,
    "最後更新日" timestamp(0)
);
CREATE UNIQUE INDEX "filu001_01" ON "filu001" ("異動流水編號", "欄位名稱");
CREATE INDEX "filu001_02" ON "filu001" ("單據流水編號", "單據序號1", "最後更新日");
CREATE INDEX "filu001_03" ON "filu001" ("最後更新者", "最後更新日");
CREATE INDEX "filu001_04" ON "filu001" ("異動批號", "最後更新日");
COMMENT ON TABLE "filu001" IS 'u.欄位異動記錄';
COMMENT ON COLUMN "filu001"."最後更新日" IS '最後更新日 / 最後更新時';

-- Files：薪資系統參數
CREATE TABLE "hrfil1002" (
    "syskey" varchar(3) NOT NULL,
    "item1a" numeric(7,4) NOT NULL,
    "item1b" numeric(7,4) NOT NULL,
    "item1c" numeric(7,4) NOT NULL,
    "item1t" varchar(10) NOT NULL,
    "item2l" smallint NOT NULL,
    "item2a1" numeric(7,4) NOT NULL,
    "item2b1" numeric(7,4) NOT NULL,
    "item2c1" numeric(7,4) NOT NULL,
    "item2t" varchar(10) NOT NULL,
    "item2a2" numeric(7,4) NOT NULL,
    "item2b2" numeric(7,4) NOT NULL,
    "item2c2" numeric(7,4) NOT NULL,
    "item3a" numeric(7,4) NOT NULL,
    "item3b" numeric(7,4) NOT NULL,
    "item3c" numeric(7,4) NOT NULL,
    "item3t" varchar(10) NOT NULL,
    "item4a" numeric(7,4) NOT NULL,
    "item4b" numeric(7,4) NOT NULL,
    "item5a" numeric(7,4) NOT NULL,
    "item5b" numeric(7,4) NOT NULL,
    "item6a" numeric(5,2) NOT NULL,
    "item6t" varchar(10) NOT NULL,
    "item7a" numeric(5,2) NOT NULL,
    "item7b" numeric(5,2) NOT NULL,
    "item7c" numeric(5,2) NOT NULL,
    "item7d" numeric(5,2) NOT NULL,
    "item7e" numeric(5,2) NOT NULL,
    "overtimemale" numeric(4,2) NOT NULL,
    "overtimefemale" numeric(4,2) NOT NULL
);
CREATE UNIQUE INDEX "hrfil1002key1" ON "hrfil1002" ("syskey");
COMMENT ON TABLE "hrfil1002" IS '薪資系統參數';

-- Files：薪資其它參數
CREATE TABLE "hrfil1002a" (
    "syskey" varchar(10) DEFAULT 'EMP' NOT NULL,
    "基本薪點" smallint DEFAULT 200 NOT NULL,
    "基本薪點薪資" smallint DEFAULT 75 NOT NULL,
    "超額薪點薪資" smallint DEFAULT 50 NOT NULL,
    "出勤午餐天數" smallint DEFAULT 23 NOT NULL,
    "午餐津貼日支" smallint DEFAULT 80 NOT NULL,
    "外藉基本工資" numeric(10,0) DEFAULT 26400 NOT NULL,
    "伙食津貼月支" numeric(10,0) DEFAULT 2400 NOT NULL,
    "伙食津貼天數" smallint DEFAULT 30 NOT NULL,
    "夜班津貼" smallint DEFAULT 160 NOT NULL,
    "大夜津貼" smallint DEFAULT 400 NOT NULL,
    "關帳年月" char(8) DEFAULT '00000000' NOT NULL,
    "其他說明一" varchar(10) DEFAULT '減項一' NOT NULL,
    "其他說明二" varchar(10) DEFAULT '減項二' NOT NULL,
    "其他說明三" varchar(10) DEFAULT '減項三' NOT NULL,
    "其他加項一" varchar(10) DEFAULT '加項一' NOT NULL,
    "其他加項二" varchar(10) DEFAULT '加項二' NOT NULL,
    "其他加項三" varchar(10) DEFAULT '加項三' NOT NULL
);
CREATE UNIQUE INDEX "hrfil1002akey1" ON "hrfil1002a" ("syskey");
COMMENT ON TABLE "hrfil1002a" IS '薪資其它參數';
COMMENT ON COLUMN "hrfil1002a"."出勤午餐天數" IS '出勤午餐津貼天數';
COMMENT ON COLUMN "hrfil1002a"."外藉基本工資" IS '外藉基本月支';
COMMENT ON COLUMN "hrfil1002a"."夜班津貼" IS '夜班津貼每次';
COMMENT ON COLUMN "hrfil1002a"."大夜津貼" IS '大夜津貼每次';
COMMENT ON COLUMN "hrfil1002a"."其他說明一" IS '其他減項一';
COMMENT ON COLUMN "hrfil1002a"."其他說明二" IS '其他減項二';
COMMENT ON COLUMN "hrfil1002a"."其他說明三" IS '其他減項三';

-- Files：加班設定
CREATE TABLE "hrfil1003" (
    "序號" smallint NOT NULL,
    "類別名稱" varchar(8) NOT NULL,
    "時間起" numeric(4,2) NOT NULL,
    "時間迄" numeric(4,2) NOT NULL,
    "參數一" numeric(7,4) NOT NULL,
    "參數二" numeric(7,4) NOT NULL,
    "參數三" numeric(7,4) NOT NULL,
    "項目" varchar(10) NOT NULL
);
CREATE UNIQUE INDEX "hrfil1003key1" ON "hrfil1003" ("序號");
COMMENT ON TABLE "hrfil1003" IS '加班設定';

-- Files：工作職稱
CREATE TABLE "hrfil1004" (
    "職務代碼" varchar(5) DEFAULT ' ' NOT NULL,
    "職務名稱" varchar(30) NOT NULL,
    "薪資" numeric(5,2) NOT NULL,
    "計薪單位" integer NOT NULL
);
CREATE UNIQUE INDEX "hrfil1004key1" ON "hrfil1004" ("職務代碼");
COMMENT ON TABLE "hrfil1004" IS '工作職稱';

-- Files：年假設定
CREATE TABLE "hrfil1005" (
    "年假起日" smallint NOT NULL,
    "年假迄日" smallint NOT NULL,
    "年假天數" smallint NOT NULL
);
CREATE UNIQUE INDEX "hrfil1005key1" ON "hrfil1005" ("年假起日", "年假迄日");
CREATE UNIQUE INDEX "hrfil1005key2" ON "hrfil1005" ("年假起日");
COMMENT ON TABLE "hrfil1005" IS '年假設定';

-- Files：員工每月出勤
CREATE TABLE "hrfil1006" (
    "員工編號" varchar(10) DEFAULT ' ' NOT NULL,
    "年月" varchar(6) DEFAULT ' ' NOT NULL,
    "時數1" numeric(5,2) DEFAULT 0 NOT NULL,
    "時數2" numeric(5,2) DEFAULT 0 NOT NULL,
    "時數3" numeric(5,2) DEFAULT 0 NOT NULL,
    "時數4" numeric(5,2) DEFAULT 0 NOT NULL,
    "時數5" numeric(5,2) DEFAULT 0 NOT NULL,
    "時數6" numeric(5,2) DEFAULT 0 NOT NULL,
    "時數7" numeric(5,2) DEFAULT 0 NOT NULL,
    "時數8" numeric(5,2) DEFAULT 0 NOT NULL,
    "時數9" numeric(5,2) DEFAULT 0 NOT NULL,
    "時數10" numeric(5,2) DEFAULT 0 NOT NULL,
    "時數11" numeric(5,2) DEFAULT 0 NOT NULL,
    "時數12" numeric(5,2) DEFAULT 0 NOT NULL
);
CREATE UNIQUE INDEX "hrfil1006key1" ON "hrfil1006" ("員工編號", "年月");
CREATE UNIQUE INDEX "hrfil1006key2" ON "hrfil1006" ("年月", "員工編號");
COMMENT ON TABLE "hrfil1006" IS '員工每月出勤';

-- Files：員工每日出勤
CREATE TABLE "hrfil1007" (
    "員工編號" varchar(10) DEFAULT ' ' NOT NULL,
    "出勤日期" char(8) DEFAULT '00000000' NOT NULL,
    "遲到" smallint DEFAULT 0 NOT NULL,
    "早退" smallint DEFAULT 0 NOT NULL,
    "打卡遲到" smallint DEFAULT 0 NOT NULL,
    "打卡早退" smallint DEFAULT 0 NOT NULL,
    "上班刷卡" char(6) DEFAULT '000000' NOT NULL,
    "下班刷卡" char(6) DEFAULT '000000' NOT NULL,
    "卡鐘上班刷卡" char(6) DEFAULT '000000' NOT NULL,
    "卡鐘下班刷卡" char(6) DEFAULT '000000' NOT NULL,
    "門禁上班刷卡" char(6) DEFAULT '000000' NOT NULL,
    "門禁下班刷卡" char(6) DEFAULT '000000' NOT NULL,
    "門禁中午進" char(6) DEFAULT '000000' NOT NULL,
    "門禁中午出" char(6) DEFAULT '000000' NOT NULL,
    "門禁午休時間" numeric(14,4) DEFAULT 0 NOT NULL,
    "門禁計薪上班" char(6) DEFAULT '000000' NOT NULL,
    "門禁計薪下班" char(6) DEFAULT '000000' NOT NULL,
    "門禁遲到" smallint DEFAULT 0 NOT NULL,
    "門禁早退" smallint DEFAULT 0 NOT NULL,
    "班別" varchar(10) DEFAULT ' ' NOT NULL,
    "班別時間起" char(6) DEFAULT '000000' NOT NULL,
    "班別時間迄" char(6) DEFAULT '000000' NOT NULL,
    "加班時數一" numeric(4,1) DEFAULT 0 NOT NULL,
    "加班時數二" numeric(4,1) DEFAULT 0 NOT NULL,
    "已手動修正" smallint DEFAULT 0 NOT NULL,
    "門禁手動修正" smallint DEFAULT 0 NOT NULL,
    "修正午晚進" char(6) DEFAULT '000000' NOT NULL,
    "修正午晚出" char(6) DEFAULT '000000' NOT NULL,
    "打卡日調整" numeric(4,1) DEFAULT 0 NOT NULL,
    "流水編號" varchar(60) DEFAULT ' ' NOT NULL,
    "最後更新者" varchar(10) DEFAULT ' ' NOT NULL,
    "最後更新日" timestamp(0)
);
CREATE UNIQUE INDEX "hrfil1007key1" ON "hrfil1007" ("流水編號");
CREATE UNIQUE INDEX "hrfil1007key2" ON "hrfil1007" ("員工編號", "出勤日期");
COMMENT ON TABLE "hrfil1007" IS '員工每日出勤';
COMMENT ON COLUMN "hrfil1007"."遲到" IS '計薪遲到';
COMMENT ON COLUMN "hrfil1007"."早退" IS '計薪早退';
COMMENT ON COLUMN "hrfil1007"."最後更新日" IS '最後更新日 / 最後更新時';

-- Files：員工每月職務薪資
CREATE TABLE "hrfil1008" (
    "員工流水編號" varchar(60) DEFAULT ' ' NOT NULL,
    "年月" varchar(6) DEFAULT ' ' NOT NULL,
    "日期" char(8) DEFAULT '00000000' NOT NULL,
    "職務代碼" varchar(5) DEFAULT ' ' NOT NULL,
    "單位工資" numeric(10,0) DEFAULT 0 NOT NULL,
    "計薪單位" numeric(10,0) DEFAULT 0 NOT NULL,
    "時數" numeric(6,1) NOT NULL,
    "金額" numeric(10,0) DEFAULT 0 NOT NULL
);
CREATE UNIQUE INDEX "hrfil1008key1" ON "hrfil1008" ("員工流水編號", "年月", "日期", "職務代碼");
COMMENT ON TABLE "hrfil1008" IS '員工每月職務薪資';

-- Files：離職其他清單
CREATE TABLE "hrfil1020" (
    "流水編號" varchar(60) DEFAULT ' ' NOT NULL,
    "序號" smallint NOT NULL,
    "其他說明" varchar(60) NOT NULL,
    "交接完成" smallint NOT NULL,
    "guid" varchar(60) DEFAULT ' ' NOT NULL
);
CREATE UNIQUE INDEX "hrfil1020key1" ON "hrfil1020" ("guid");
CREATE UNIQUE INDEX "hrfil1020key2" ON "hrfil1020" ("流水編號", "序號");
COMMENT ON TABLE "hrfil1020" IS '離職其他清單';

-- Files：離職檔案清單
CREATE TABLE "hrfil1021" (
    "流水編號" varchar(60) DEFAULT ' ' NOT NULL,
    "item" smallint NOT NULL,
    "檔案說明" varchar(60) NOT NULL,
    "交接完成" smallint NOT NULL,
    "guid" varchar(60) DEFAULT ' ' NOT NULL
);
CREATE UNIQUE INDEX "hrfil1021key1" ON "hrfil1021" ("guid");
CREATE UNIQUE INDEX "hrfil1021key2" ON "hrfil1021" ("流水編號", "item");
COMMENT ON TABLE "hrfil1021" IS '離職檔案清單';
COMMENT ON COLUMN "hrfil1021"."item" IS '表身序號';

-- Files：離職文件清單
CREATE TABLE "hrfil1022" (
    "流水編號" varchar(60) DEFAULT ' ' NOT NULL,
    "序號" smallint NOT NULL,
    "文件說明" varchar(60) NOT NULL,
    "交接完成" smallint NOT NULL,
    "guid" varchar(60) DEFAULT ' ' NOT NULL
);
CREATE UNIQUE INDEX "hrfil1022key1" ON "hrfil1022" ("guid");
CREATE UNIQUE INDEX "hrfil1022key2" ON "hrfil1022" ("流水編號", "序號");
COMMENT ON TABLE "hrfil1022" IS '離職文件清單';

-- Files：離職工作清單
CREATE TABLE "hrfil1023" (
    "流水編號" varchar(60) DEFAULT ' ' NOT NULL,
    "序號" smallint NOT NULL,
    "工作內容" varchar(60) NOT NULL,
    "交接完成" smallint NOT NULL,
    "guid" varchar(60) DEFAULT ' ' NOT NULL
);
CREATE UNIQUE INDEX "hrfil1023key1" ON "hrfil1023" ("guid");
CREATE UNIQUE INDEX "hrfil1023key2" ON "hrfil1023" ("流水編號", "序號");
COMMENT ON TABLE "hrfil1023" IS '離職工作清單';

-- Files：離職財產歸還
CREATE TABLE "hrfil1024" (
    "流水編號" varchar(60) DEFAULT ' ' NOT NULL,
    "序號" smallint NOT NULL,
    "財產編號" varchar(60) DEFAULT ' ' NOT NULL,
    "歸還數量" integer NOT NULL,
    "交接完成" smallint NOT NULL,
    "guid" varchar(60) DEFAULT ' ' NOT NULL
);
CREATE UNIQUE INDEX "hrfil1024key1" ON "hrfil1024" ("guid");
CREATE UNIQUE INDEX "hrfil1024key2" ON "hrfil1024" ("流水編號", "序號");
COMMENT ON TABLE "hrfil1024" IS '離職財產歸還';

-- Files：離職執行
CREATE TABLE "hrfil1025" (
    "流水編號" varchar(60) DEFAULT ' ' NOT NULL,
    "單號" varchar(15) NOT NULL,
    "填寫人" varchar(60) DEFAULT ' ' NOT NULL,
    "申請人" varchar(60) DEFAULT ' ' NOT NULL,
    "填寫日期" char(8) NOT NULL,
    "請款地點" varchar(60) DEFAULT ' ' NOT NULL,
    "源頭單號" varchar(60) DEFAULT ' ' NOT NULL,
    "交接人員" varchar(60) DEFAULT ' ' NOT NULL,
    "guid" varchar(60) DEFAULT ' ' NOT NULL
);
CREATE UNIQUE INDEX "hrfil1025key1" ON "hrfil1025" ("流水編號");
CREATE UNIQUE INDEX "hrfil1025key2" ON "hrfil1025" ("單號");
CREATE INDEX "hrfil1025key3" ON "hrfil1025" ("源頭單號");
COMMENT ON TABLE "hrfil1025" IS '離職執行';

-- Files：離職單
CREATE TABLE "hrfil1026" (
    "流水編號" varchar(60) DEFAULT ' ' NOT NULL,
    "單號" varchar(15) NOT NULL,
    "填寫人" varchar(60) DEFAULT ' ' NOT NULL,
    "申請人" varchar(60) DEFAULT ' ' NOT NULL,
    "填寫日期" char(8) DEFAULT '00000000' NOT NULL,
    "請款地點" varchar(60) DEFAULT ' ' NOT NULL,
    "源頭單號" varchar(60) DEFAULT ' ' NOT NULL,
    "離職原因" varchar(256) NOT NULL,
    "交接事項" varchar(256) NOT NULL,
    "公司個人財產項目" varchar(256) NOT NULL,
    "預計離職日" char(8) DEFAULT '00000000' NOT NULL,
    "公司核定離職日" char(8) DEFAULT '00000000' NOT NULL,
    "聯絡電話" varchar(20) NOT NULL,
    "需交接" smallint NOT NULL,
    "公司借貸款未還" smallint NOT NULL,
    "持有產品相關文件" smallint NOT NULL,
    "持有相關技術檔案程式" smallint NOT NULL,
    "持有公司門禁錀匙" smallint NOT NULL,
    "交接日期起" char(8) DEFAULT '00000000' NOT NULL,
    "交接日期迄" char(8) DEFAULT '00000000' NOT NULL,
    "guid" varchar(60) DEFAULT ' ' NOT NULL,
    "交接人員" varchar(60) DEFAULT ' ' NOT NULL,
    "執行單流水號" varchar(60) DEFAULT ' ' NOT NULL
);
CREATE UNIQUE INDEX "hrfil1026key1" ON "hrfil1026" ("流水編號");
CREATE INDEX "hrfil1026key2" ON "hrfil1026" ("填寫人", "填寫日期");
CREATE UNIQUE INDEX "hrfil1026key3" ON "hrfil1026" ("單號");
COMMENT ON TABLE "hrfil1026" IS '離職單';
COMMENT ON COLUMN "hrfil1026"."持有相關技術檔案程式" IS '持有相關技術檔案/程式';

-- Files：請假單
CREATE TABLE "hrfil1031" (
    "流水編號" varchar(60) DEFAULT ' ' NOT NULL,
    "單別" varchar(10) DEFAULT ' ' NOT NULL,
    "單號" varchar(15) DEFAULT ' ' NOT NULL,
    "填寫人" varchar(60) DEFAULT ' ' NOT NULL,
    "申請人" varchar(60) DEFAULT ' ' NOT NULL,
    "填寫日期" char(8) DEFAULT '00000000' NOT NULL,
    "請款地點" varchar(60) DEFAULT ' ' NOT NULL,
    "源頭單號" varchar(60) DEFAULT ' ' NOT NULL,
    "請假假別" varchar(4) DEFAULT ' ' NOT NULL,
    "假別" varchar(4) DEFAULT ' ' NOT NULL,
    "起始日期" char(8) DEFAULT '00000000' NOT NULL,
    "起始時間" char(6) DEFAULT '000000' NOT NULL,
    "截止日期" char(8) DEFAULT '00000000' NOT NULL,
    "截止時間" char(6) DEFAULT '0000' NOT NULL,
    "天數" numeric(2,0) DEFAULT 0 NOT NULL,
    "時數" numeric(2,1) DEFAULT 0 NOT NULL,
    "代理人" varchar(60) DEFAULT ' ' NOT NULL,
    "guid" varchar(60) DEFAULT ' ' NOT NULL,
    "請假事由" text
);
CREATE UNIQUE INDEX "hrfil1031key1" ON "hrfil1031" ("流水編號");
CREATE INDEX "hrfil1031key2" ON "hrfil1031" ("填寫人", "填寫日期");
CREATE UNIQUE INDEX "hrfil1031key3" ON "hrfil1031" ("單別", "單號");
COMMENT ON TABLE "hrfil1031" IS '請假單';

-- Files：特休排定表
CREATE TABLE "hrfil1032" (
    "流水編號" varchar(60) DEFAULT ' ' NOT NULL,
    "單號" varchar(20) DEFAULT ' ' NOT NULL,
    "填寫人" varchar(10) DEFAULT ' ' NOT NULL,
    "申請人" varchar(10) DEFAULT ' ' NOT NULL,
    "填寫日期" char(8) DEFAULT '00000000' NOT NULL,
    "年度" smallint DEFAULT 0 NOT NULL,
    "應休天數" smallint DEFAULT 0 NOT NULL,
    "生效日期" char(8) DEFAULT '00000000' NOT NULL,
    "一月" numeric(3,1) DEFAULT 0 NOT NULL,
    "二月" numeric(3,1) DEFAULT 0 NOT NULL,
    "三月" numeric(3,1) DEFAULT 0 NOT NULL,
    "四月" numeric(3,1) DEFAULT 0 NOT NULL,
    "五月" numeric(3,1) DEFAULT 0 NOT NULL,
    "六月" numeric(3,1) DEFAULT 0 NOT NULL,
    "七月" numeric(3,1) DEFAULT 0 NOT NULL,
    "八月" numeric(3,1) DEFAULT 0 NOT NULL,
    "九月" numeric(3,1) DEFAULT 0 NOT NULL,
    "十月" numeric(3,1) DEFAULT 0 NOT NULL,
    "十一月" numeric(3,1) DEFAULT 0 NOT NULL,
    "十二月" numeric(3,1) DEFAULT 0 NOT NULL,
    "事由" text,
    PRIMARY KEY ("流水編號")
);
CREATE INDEX "hrfil1032_02" ON "hrfil1032" ("單號");
CREATE INDEX "hrfil1032_03" ON "hrfil1032" ("填寫人", "填寫日期");
CREATE INDEX "hrfil1032_04" ON "hrfil1032" ("申請人", "填寫日期");
COMMENT ON TABLE "hrfil1032" IS '特休排定表';

-- Files：應特休日
CREATE TABLE "hrfil1033" (
    "員工" varchar(10) DEFAULT ' ' NOT NULL,
    "年度" smallint DEFAULT 0 NOT NULL,
    "年資_年" smallint DEFAULT 0 NOT NULL,
    "年資_月" numeric(3,1) DEFAULT 0 NOT NULL,
    "年結天數" smallint DEFAULT 0 NOT NULL,
    "月結天數" smallint DEFAULT 0 NOT NULL,
    "應特休日" smallint DEFAULT 0 NOT NULL,
    "到職基準日" char(8) DEFAULT 00000000 NOT NULL,
    "開始給假年月" char(8) DEFAULT '00000000' NOT NULL,
    "建檔人" varchar(10) DEFAULT ' ' NOT NULL,
    "建檔日" timestamp(0),
    "最後更新人" varchar(10) DEFAULT ' ' NOT NULL,
    "最後更新日" timestamp(0),
    PRIMARY KEY ("員工", "年度")
);
CREATE UNIQUE INDEX "hrfil1033_02" ON "hrfil1033" ("年度", "員工");
COMMENT ON TABLE "hrfil1033" IS '應特休日';
COMMENT ON COLUMN "hrfil1033"."年資_年" IS '年資(年)';
COMMENT ON COLUMN "hrfil1033"."年資_月" IS '年資(月)';
COMMENT ON COLUMN "hrfil1033"."建檔日" IS '建檔日 / 建檔時';
COMMENT ON COLUMN "hrfil1033"."最後更新日" IS '最後更新日 / 最後更新時';

-- Files：出勤調整單
CREATE TABLE "hrfil1034" (
    "流水編號" varchar(60) DEFAULT ' ' NOT NULL,
    "單號" varchar(15) DEFAULT ' ' NOT NULL,
    "填寫人" varchar(60) DEFAULT ' ' NOT NULL,
    "申請人" varchar(60) DEFAULT ' ' NOT NULL,
    "填寫日期" char(8) DEFAULT '00000000' NOT NULL,
    "請款地點" varchar(60) DEFAULT ' ' NOT NULL,
    "源頭單號" varchar(60) DEFAULT ' ' NOT NULL,
    "請假假別" varchar(4) DEFAULT ' ' NOT NULL,
    "假別" varchar(4) DEFAULT ' ' NOT NULL,
    "起始日期" char(8) DEFAULT '00000000' NOT NULL,
    "起始時間" char(6) DEFAULT '000000' NOT NULL,
    "截止日期" char(8) DEFAULT '00000000' NOT NULL,
    "截止時間" char(6) DEFAULT '0000' NOT NULL,
    "天數" numeric(2,0) DEFAULT 0 NOT NULL,
    "時數" numeric(2,1) DEFAULT 0 NOT NULL,
    "代理人" varchar(60) DEFAULT ' ' NOT NULL,
    "guid" varchar(60) DEFAULT ' ' NOT NULL,
    "請假事由" text
);
CREATE UNIQUE INDEX "hrfil1034key1" ON "hrfil1034" ("流水編號");
CREATE INDEX "hrfil1034key2" ON "hrfil1034" ("填寫人", "填寫日期");
CREATE UNIQUE INDEX "hrfil1034key3" ON "hrfil1034" ("單號");
COMMENT ON TABLE "hrfil1034" IS '出勤調整單';

-- Files：人事異動
CREATE TABLE "hrfil1041" (
    "流水編號" varchar(60) DEFAULT ' ' NOT NULL,
    "單號" varchar(15) NOT NULL,
    "填寫人" varchar(60) DEFAULT ' ' NOT NULL,
    "申請人" varchar(60) DEFAULT ' ' NOT NULL,
    "異動對象" varchar(60) DEFAULT ' ' NOT NULL,
    "填寫日期" char(8) DEFAULT '00000000' NOT NULL,
    "請款地點" varchar(60) DEFAULT ' ' NOT NULL,
    "源頭單號" varchar(60) DEFAULT ' ' NOT NULL,
    "生效日期" char(8) DEFAULT '00000000' NOT NULL,
    "調整項目" varchar NOT NULL,
    "隸屬公司" varchar NOT NULL,
    "隸屬部門" varchar NOT NULL,
    "職務名稱" varchar NOT NULL,
    "幣別" varchar(4) NOT NULL,
    "底薪" numeric(9,1) NOT NULL,
    "伙食津貼" numeric(9,1) NOT NULL,
    "職務津貼" numeric(9,1) NOT NULL,
    "電話津貼" numeric(9,1) NOT NULL,
    "技術津貼" numeric(9,1) NOT NULL,
    "固定加班津貼" numeric(9,1) NOT NULL,
    "全勤津貼" numeric(9,1) NOT NULL,
    "其他津貼1" numeric(9,1) NOT NULL,
    "其他津貼2" numeric(9,1) NOT NULL,
    "其他津貼3" numeric(9,1) NOT NULL,
    "總薪資" numeric(9,1) NOT NULL,
    "調整金額" numeric(9,1) NOT NULL,
    "調幅" numeric(5,2) NOT NULL,
    "有附件" smallint NOT NULL,
    "調整原因" varchar(512) NOT NULL,
    "guid" varchar(60) DEFAULT ' ' NOT NULL,
    "註解" text
);
CREATE UNIQUE INDEX "hrfil1041key1" ON "hrfil1041" ("流水編號");
CREATE INDEX "hrfil1041key2" ON "hrfil1041" ("申請人", "生效日期");
CREATE INDEX "hrfil1041key3" ON "hrfil1041" ("異動對象", "生效日期");
CREATE UNIQUE INDEX "hrfil1041key4" ON "hrfil1041" ("單號");
COMMENT ON TABLE "hrfil1041" IS '人事異動';

-- Files：人資申請
CREATE TABLE "hrfil1051" (
    "流水編號" varchar(60) DEFAULT ' ' NOT NULL,
    "單號" varchar(15) NOT NULL,
    "填寫人" varchar(60) DEFAULT ' ' NOT NULL,
    "申請人" varchar(60) DEFAULT ' ' NOT NULL,
    "填寫日期" char(8) DEFAULT '00000000' NOT NULL,
    "請款地點" varchar(60) DEFAULT ' ' NOT NULL,
    "源頭單號" varchar(60) DEFAULT ' ' NOT NULL,
    "部門流水號" varchar(60) DEFAULT ' ' NOT NULL,
    "職稱" varchar(60) DEFAULT ' ' NOT NULL,
    "身份" varchar(4) NOT NULL,
    "需求人數" smallint NOT NULL,
    "要求條件" varchar(256) NOT NULL,
    "徵人原因" varchar(256) NOT NULL,
    "工作內容" varchar(512) NOT NULL,
    "希望到職時間" char(8) DEFAULT '00000000' NOT NULL,
    "guid" varchar(60) DEFAULT ' ' NOT NULL,
    "註解" text
);
CREATE UNIQUE INDEX "hrfil1051key1" ON "hrfil1051" ("流水編號");
CREATE INDEX "hrfil1051key2" ON "hrfil1051" ("填寫人", "填寫日期");
CREATE UNIQUE INDEX "hrfil1051key3" ON "hrfil1051" ("單號");
COMMENT ON TABLE "hrfil1051" IS '人資申請';

-- Files：帳號申請
CREATE TABLE "hrfil1061" (
    "流水編號" varchar(60) DEFAULT ' ' NOT NULL,
    "單號" varchar(15) NOT NULL,
    "填寫人" varchar(60) DEFAULT ' ' NOT NULL,
    "申請人" varchar(60) DEFAULT ' ' NOT NULL,
    "填寫日期" char(8) DEFAULT '00000000' NOT NULL,
    "請款地點" varchar(60) DEFAULT ' ' NOT NULL,
    "源頭單號" varchar(60) DEFAULT ' ' NOT NULL,
    "所屬部門" varchar(60) DEFAULT ' ' NOT NULL,
    "職稱" varchar(60) DEFAULT ' ' NOT NULL,
    "姓名" varchar(16) NOT NULL,
    "登入帳號" varchar(20) NOT NULL,
    "登入密碼" varchar(20) NOT NULL,
    "自訂帳號名稱" smallint NOT NULL,
    "實際到職時間" char(8) DEFAULT '00000000' NOT NULL,
    "check1" smallint NOT NULL,
    "check2" smallint NOT NULL,
    "check3" smallint NOT NULL,
    "check4" smallint NOT NULL,
    "check5" smallint NOT NULL,
    "參考權限" varchar(60) DEFAULT ' ' NOT NULL,
    "guid" varchar(60) DEFAULT ' ' NOT NULL,
    "註解" text
);
CREATE UNIQUE INDEX "hrfil1061key1" ON "hrfil1061" ("流水編號");
CREATE INDEX "hrfil1061key2" ON "hrfil1061" ("填寫人", "填寫日期");
CREATE UNIQUE INDEX "hrfil1061key3" ON "hrfil1061" ("單號");
COMMENT ON TABLE "hrfil1061" IS '帳號申請';

-- Files：勞健保對照表
CREATE TABLE "hrfil1071" (
    "序號" smallint NOT NULL,
    "級數" smallint NOT NULL,
    "投保級距" numeric(10,0) NOT NULL,
    "勞保勞工負擔" numeric(10,0) NOT NULL,
    "勞保雇主負擔" numeric(10,0) NOT NULL,
    "工資" numeric(10,0) NOT NULL,
    "健保費勞工負擔" numeric(10,0) NOT NULL,
    "健保費顧主負擔" numeric(10,0) NOT NULL,
    "勞工退休金提繳" numeric(10,0) NOT NULL,
    "勞健保合計勞工負擔" numeric(10,0) NOT NULL,
    "勞健保合計雇主負擔" numeric(10,0) NOT NULL,
    "備註" varchar(20) NOT NULL,
    "健保本人加1眷屬" numeric(10,0) NOT NULL,
    "健保本人加2眷屬" numeric(10,0) NOT NULL,
    "健保本人加3眷屬" numeric(10,0) NOT NULL
);
CREATE UNIQUE INDEX "hrfil1071key1" ON "hrfil1071" ("序號");
COMMENT ON TABLE "hrfil1071" IS '勞健保對照表';
COMMENT ON COLUMN "hrfil1071"."工資" IS '工資墊償基金';

-- Files：薪資扣繳稅額表
CREATE TABLE "hrfil1081" (
    "nodeid" integer NOT NULL,
    "parentid" integer NOT NULL,
    "序號" smallint NOT NULL,
    "薪資所得" numeric(10,0) NOT NULL,
    "薪資起" numeric(10,0) NOT NULL,
    "薪資迄" numeric(10,0) NOT NULL,
    "撫養人數0" numeric(10,0) NOT NULL,
    "撫養人數1" numeric(10,0) NOT NULL,
    "撫養人數2" numeric(10,0) NOT NULL,
    "撫養人數3" numeric(10,0) NOT NULL,
    "撫養人數4" numeric(10,0) NOT NULL,
    "撫養人數5" numeric(10,0) NOT NULL,
    "撫養人數6" numeric(10,0) NOT NULL,
    "撫養人數7" numeric(10,0) NOT NULL,
    "撫養人數8" numeric(10,0) NOT NULL,
    "撫養人數9" numeric(10,0) NOT NULL,
    "撫養人數10" numeric(10,0) NOT NULL,
    "撫養人數11" numeric(10,0) NOT NULL
);
CREATE UNIQUE INDEX "hrfil1081key1" ON "hrfil1081" ("序號");
COMMENT ON TABLE "hrfil1081" IS '薪資扣繳稅額表';

-- Files：個人薪資主檔
CREATE TABLE "hrfil2001" (
    "年月" varchar(6) DEFAULT ' ' NOT NULL,
    "員工編號" varchar(10) DEFAULT ' ' NOT NULL,
    "所得稅率" numeric(5,2) DEFAULT 0 NOT NULL,
    "健保卡號" varchar(10) DEFAULT ' ' NOT NULL,
    "勞保費" numeric(10,0) DEFAULT 0 NOT NULL,
    "健保費" numeric(10,0) DEFAULT 0 NOT NULL,
    "自提退休金" numeric(10,0) DEFAULT 0 NOT NULL,
    "二代健保" numeric(10,0) DEFAULT 0 NOT NULL,
    "本薪" numeric(10,0) DEFAULT 0 NOT NULL,
    "職務津貼" numeric(10,0) DEFAULT 0 NOT NULL,
    "出勤日支" numeric(10,0) DEFAULT 0 NOT NULL,
    "出勤津貼" numeric(10,0) DEFAULT 0 NOT NULL,
    "交通津貼" numeric(10,0) DEFAULT 0 NOT NULL,
    "技術津貼" numeric(10,0) DEFAULT 0 NOT NULL,
    "午餐津貼" numeric(10,0) DEFAULT 0 NOT NULL,
    "伙食津貼" numeric(10,0) DEFAULT 0 NOT NULL,
    "車馬費" numeric(10,0) DEFAULT 0 NOT NULL,
    "othalw6" numeric(10,0) DEFAULT 0 NOT NULL,
    "othalw7" numeric(10,0) DEFAULT 0 NOT NULL,
    "labinsfeec" numeric(10,0) DEFAULT 0 NOT NULL,
    "hlthinsfeec" numeric(10,0) DEFAULT 0 NOT NULL,
    "pretaxfee" numeric(10,0) DEFAULT 0 NOT NULL,
    "benealw" numeric(10,0) DEFAULT 0 NOT NULL,
    "othfee1" numeric(10,0) DEFAULT 0 NOT NULL,
    "othfee2" numeric(10,0) DEFAULT 0 NOT NULL,
    "othfee3" numeric(10,0) DEFAULT 0 NOT NULL,
    "othfee4" numeric(10,0) DEFAULT 0 NOT NULL,
    "othfee5" numeric(10,0) DEFAULT 0 NOT NULL,
    "職等" smallint DEFAULT 0 NOT NULL,
    "職級" smallint DEFAULT 0 NOT NULL,
    "薪點" numeric(10,0) DEFAULT 0 NOT NULL,
    "公司代碼" varchar(1) DEFAULT ' ' NOT NULL,
    "薪資分群" varchar(2) DEFAULT ' ' NOT NULL,
    "製程代碼" varchar(10) DEFAULT ' ' NOT NULL,
    "成本類別" varchar(1) DEFAULT ' ' NOT NULL
);
CREATE UNIQUE INDEX "hrfil2001key1" ON "hrfil2001" ("員工編號", "年月");
CREATE UNIQUE INDEX "hrfil2001key2" ON "hrfil2001" ("年月", "員工編號");
COMMENT ON TABLE "hrfil2001" IS '個人薪資主檔';
COMMENT ON COLUMN "hrfil2001"."othalw6" IS '車馬費一';
COMMENT ON COLUMN "hrfil2001"."othalw7" IS '車馬費二';
COMMENT ON COLUMN "hrfil2001"."othfee1" IS '午餐日支';
COMMENT ON COLUMN "hrfil2001"."othfee2" IS '借支';
COMMENT ON COLUMN "hrfil2001"."othfee3" IS '固定所得稅';
COMMENT ON COLUMN "hrfil2001"."othfee4" IS '退休金提撥';
COMMENT ON COLUMN "hrfil2001"."othfee5" IS '固定時薪(計時)';

-- Files：所得扶養人數
CREATE TABLE "hrfil2002" (
    "員工編號" varchar(10) DEFAULT ' ' NOT NULL,
    "姓名" varchar(12) NOT NULL,
    "關係" varchar(8) NOT NULL,
    "生日" char(8) DEFAULT '00000000' NOT NULL,
    "身份證號" varchar(10) NOT NULL,
    "住址" varchar(100) NOT NULL
);
CREATE UNIQUE INDEX "hrfil2002key1" ON "hrfil2002" ("員工編號", "身份證號");
COMMENT ON TABLE "hrfil2002" IS '所得扶養人數';

-- Files：健保扶養人數
CREATE TABLE "hrfil2003" (
    "員工編號" varchar(10) DEFAULT ' ' NOT NULL,
    "姓名" varchar(12) NOT NULL,
    "關係" varchar(8) NOT NULL,
    "生日" char(8) DEFAULT '00000000' NOT NULL,
    "身份證號" varchar(10) NOT NULL,
    "住址" varchar(100) NOT NULL
);
CREATE UNIQUE INDEX "hrfil2003key1" ON "hrfil2003" ("員工編號", "身份證號");
COMMENT ON TABLE "hrfil2003" IS '健保扶養人數';

-- Files：薪資項目設定
CREATE TABLE "hrfil2004" (
    "syskey" varchar(10) NOT NULL,
    "officetimefrom" char(6) NOT NULL,
    "officetimeto" char(6) NOT NULL,
    "officetime" smallint NOT NULL,
    "arrivelateunit" varchar(1) NOT NULL,
    "leaveearlyunit" varchar(1) NOT NULL,
    "footersignby" varchar(30) NOT NULL,
    "salarysignby" varchar(30) NOT NULL,
    "bonussignby" varchar(30) NOT NULL,
    "本薪" varchar(10) DEFAULT ' ' NOT NULL,
    "職務津貼" varchar(10) DEFAULT ' ' NOT NULL,
    "出勤津貼" varchar(10) DEFAULT ' ' NOT NULL,
    "交通津貼" varchar(10) DEFAULT ' ' NOT NULL,
    "技術津貼" varchar(10) DEFAULT ' ' NOT NULL,
    "伙食津貼" varchar(10) DEFAULT ' ' NOT NULL,
    "午餐津貼" varchar(10) DEFAULT ' ' NOT NULL,
    "特休津貼" varchar(10) DEFAULT ' ' NOT NULL,
    "夜班津貼" varchar(10) DEFAULT ' ' NOT NULL,
    "大夜津貼" varchar(10) DEFAULT ' ' NOT NULL,
    "車馬費" varchar(10) DEFAULT ' ' NOT NULL,
    "fixedplusitemt" varchar(15) NOT NULL,
    "事病假薪點" varchar(10) DEFAULT ' ' NOT NULL,
    "借支" varchar(10) DEFAULT ' ' NOT NULL,
    "自提退休金" varchar(10) DEFAULT ' ' NOT NULL,
    "所得稅" varchar(10) DEFAULT ' ' NOT NULL,
    "勞保費" varchar(10) DEFAULT ' ' NOT NULL,
    "健保費" varchar(10) DEFAULT ' ' NOT NULL,
    "二代健保" varchar(10) DEFAULT ' ' NOT NULL,
    "fixedpminusitem8" varchar(10) DEFAULT ' ' NOT NULL,
    "fixedpminusitemt" varchar(10) NOT NULL,
    "加班費一" varchar(10) DEFAULT ' ' NOT NULL,
    "加班費二" varchar(10) DEFAULT ' ' NOT NULL,
    "chgplusitem3" varchar(10) DEFAULT ' ' NOT NULL,
    "chgplusitem4" varchar(10) DEFAULT ' ' NOT NULL,
    "chgplusitem5" varchar(10) DEFAULT ' ' NOT NULL,
    "chgplusitem6" varchar(10) DEFAULT ' ' NOT NULL,
    "chgplusitem7" varchar(10) DEFAULT ' ' NOT NULL,
    "chgplusitem8" varchar(10) DEFAULT ' ' NOT NULL,
    "chgplusitemt" varchar(10) NOT NULL,
    "事假扣款" varchar(10) DEFAULT ' ' NOT NULL,
    "病假扣款" varchar(10) DEFAULT ' ' NOT NULL,
    "曠假扣款" varchar(10) DEFAULT ' ' NOT NULL,
    "遲到扣款" varchar(10) DEFAULT ' ' NOT NULL,
    "早退扣款" varchar(10) DEFAULT ' ' NOT NULL,
    "缺失扣款" varchar(10) DEFAULT ' ' NOT NULL,
    "損失扣款" varchar(10) DEFAULT ' ' NOT NULL,
    "chgminusitem8" varchar(10) DEFAULT ' ' NOT NULL,
    "chgminusitemt" varchar(10) NOT NULL,
    "事假時數" varchar(10) DEFAULT ' ' NOT NULL,
    "病假時數" varchar(10) DEFAULT ' ' NOT NULL,
    "曠職天數" varchar(10) DEFAULT ' ' NOT NULL,
    "特休時數" varchar(10) DEFAULT ' ' NOT NULL,
    "婚假天數" varchar(10) DEFAULT ' ' NOT NULL,
    "產假天數" varchar(10) DEFAULT ' ' NOT NULL,
    "公傷天數" varchar(10) DEFAULT ' ' NOT NULL,
    "喪假天數" varchar(10) DEFAULT ' ' NOT NULL,
    "公假時數" varchar(10) DEFAULT ' ' NOT NULL,
    "補休天數" varchar(10) DEFAULT ' ' NOT NULL,
    "陪產天數" varchar(10) DEFAULT ' ' NOT NULL,
    "vacitem12" varchar(10) DEFAULT ' ' NOT NULL,
    "lsa1" numeric(4,4) NOT NULL,
    "lsa2" numeric(4,4) NOT NULL,
    "lsb" numeric(4,4) NOT NULL,
    "lsc" numeric(4,4) NOT NULL,
    "hsa" numeric(4,4) NOT NULL,
    "hsb" numeric(4,4) NOT NULL,
    "hsc" numeric(4,4) NOT NULL,
    "hsd" numeric(4,4) NOT NULL,
    "insovercnt" smallint NOT NULL,
    "特休計算天數" smallint DEFAULT 22 NOT NULL,
    "加班計算天數" smallint DEFAULT 23 NOT NULL,
    "日加班補貼" varchar(10) DEFAULT ' ' NOT NULL,
    "月加班補貼" varchar(10) DEFAULT ' ' NOT NULL,
    "職等" smallint DEFAULT 0 NOT NULL,
    "職級" smallint DEFAULT 0 NOT NULL,
    "薪點" numeric(10,0) DEFAULT 0 NOT NULL
);
CREATE UNIQUE INDEX "hrfil2004key1" ON "hrfil2004" ("syskey");
COMMENT ON TABLE "hrfil2004" IS '薪資項目設定';
COMMENT ON COLUMN "hrfil2004"."本薪" IS '名稱:本薪';
COMMENT ON COLUMN "hrfil2004"."職務津貼" IS '名稱:職務津貼';
COMMENT ON COLUMN "hrfil2004"."出勤津貼" IS '名稱:出勤津貼';
COMMENT ON COLUMN "hrfil2004"."交通津貼" IS '名稱:交通津貼';
COMMENT ON COLUMN "hrfil2004"."技術津貼" IS '名稱:技術津貼';
COMMENT ON COLUMN "hrfil2004"."伙食津貼" IS '名稱:伙食津貼';
COMMENT ON COLUMN "hrfil2004"."午餐津貼" IS '名稱:午餐津貼';
COMMENT ON COLUMN "hrfil2004"."特休津貼" IS '名稱:特休津貼';
COMMENT ON COLUMN "hrfil2004"."夜班津貼" IS '名稱:夜班津貼';
COMMENT ON COLUMN "hrfil2004"."大夜津貼" IS '名稱:大夜津貼';
COMMENT ON COLUMN "hrfil2004"."車馬費" IS '名稱:車馬費';
COMMENT ON COLUMN "hrfil2004"."事病假薪點" IS '名稱:事病假薪點';
COMMENT ON COLUMN "hrfil2004"."借支" IS '名稱:借支';
COMMENT ON COLUMN "hrfil2004"."自提退休金" IS '名稱:自提退休金';
COMMENT ON COLUMN "hrfil2004"."所得稅" IS '名稱:所得稅';
COMMENT ON COLUMN "hrfil2004"."勞保費" IS '名稱:勞保費';
COMMENT ON COLUMN "hrfil2004"."健保費" IS '名稱:健保費';
COMMENT ON COLUMN "hrfil2004"."二代健保" IS '名稱:二代健保';
COMMENT ON COLUMN "hrfil2004"."加班費一" IS '名稱:加班費一';
COMMENT ON COLUMN "hrfil2004"."加班費二" IS '名稱:加班費二';
COMMENT ON COLUMN "hrfil2004"."事假扣款" IS '名稱:事病假扣款';
COMMENT ON COLUMN "hrfil2004"."病假扣款" IS '名稱:遲到早退扣款';
COMMENT ON COLUMN "hrfil2004"."曠假扣款" IS '名稱:調補扣款';
COMMENT ON COLUMN "hrfil2004"."遲到扣款" IS '名稱:遲到扣款';
COMMENT ON COLUMN "hrfil2004"."早退扣款" IS '名稱:早退扣款';
COMMENT ON COLUMN "hrfil2004"."缺失扣款" IS '名稱:缺失扣款';
COMMENT ON COLUMN "hrfil2004"."損失扣款" IS '名稱:損失扣款';
COMMENT ON COLUMN "hrfil2004"."事假時數" IS '名稱:事假時數';
COMMENT ON COLUMN "hrfil2004"."病假時數" IS '名稱:病假時數';
COMMENT ON COLUMN "hrfil2004"."曠職天數" IS '名稱:曠職天數';
COMMENT ON COLUMN "hrfil2004"."特休時數" IS '名稱:特休時數';
COMMENT ON COLUMN "hrfil2004"."婚假天數" IS '名稱:婚假天數';
COMMENT ON COLUMN "hrfil2004"."產假天數" IS '名稱:產假天數';
COMMENT ON COLUMN "hrfil2004"."公傷天數" IS '名稱:公傷天數';
COMMENT ON COLUMN "hrfil2004"."喪假天數" IS '名稱:喪假天數';
COMMENT ON COLUMN "hrfil2004"."公假時數" IS '名稱:公假時數';
COMMENT ON COLUMN "hrfil2004"."補休天數" IS '名稱:補休天數';
COMMENT ON COLUMN "hrfil2004"."陪產天數" IS '名稱:陪產天數';
COMMENT ON COLUMN "hrfil2004"."特休計算天數" IS '名稱:特休計算天數';
COMMENT ON COLUMN "hrfil2004"."加班計算天數" IS '名稱:加班計算天數';
COMMENT ON COLUMN "hrfil2004"."日加班補貼" IS '名稱:日加班補貼';
COMMENT ON COLUMN "hrfil2004"."月加班補貼" IS '名稱:月加班補貼';

-- Files：每月薪資明細
CREATE TABLE "hrfil2005" (
    "年月" varchar(6) DEFAULT ' ' NOT NULL,
    "員工編號" varchar(10) DEFAULT ' ' NOT NULL,
    "計薪天數" smallint DEFAULT 30 NOT NULL,
    "特休計算天數" smallint DEFAULT 23 NOT NULL,
    "打卡天數" smallint DEFAULT 22 NOT NULL,
    "本薪" numeric(10,0) DEFAULT 0 NOT NULL,
    "職務津貼" numeric(10,0) DEFAULT 0 NOT NULL,
    "出勤日支" numeric(10,0) DEFAULT 0 NOT NULL,
    "出勤津貼" numeric(10,0) DEFAULT 0 NOT NULL,
    "交通津貼" numeric(10,0) DEFAULT 0 NOT NULL,
    "技術津貼" numeric(10,0) DEFAULT 0 NOT NULL,
    "午餐津貼" numeric(10,0) DEFAULT 0 NOT NULL,
    "加班費" numeric(10,0) DEFAULT 0 NOT NULL,
    "plusitem9" numeric(10,0) DEFAULT 0 NOT NULL,
    "plusitem10" numeric(10,0) DEFAULT 0 NOT NULL,
    "事病假薪點" numeric(10,0) DEFAULT 0 NOT NULL,
    "借支" numeric(10,0) DEFAULT 0 NOT NULL,
    "自提退休金" numeric(10,0) DEFAULT 0 NOT NULL,
    "所得稅" numeric(10,0) DEFAULT 0 NOT NULL,
    "勞保費" numeric(10,0) DEFAULT 0 NOT NULL,
    "健保費" numeric(10,0) DEFAULT 0 NOT NULL,
    "二代健保" numeric(10,0) DEFAULT 0 NOT NULL,
    "minusitem8" numeric(10,0) DEFAULT 0 NOT NULL,
    "特休津貼" numeric(10,0) DEFAULT 0 NOT NULL,
    "伙食津貼" numeric(10,0) DEFAULT 0 NOT NULL,
    "加班費二" numeric(10,0) DEFAULT 0 NOT NULL,
    "cplusitem4" numeric(10,0) DEFAULT 0 NOT NULL,
    "cplusitem5" numeric(10,0) DEFAULT 0 NOT NULL,
    "cplusitem6" numeric(10,0) DEFAULT 0 NOT NULL,
    "cplusitem7" numeric(10,0) DEFAULT 0 NOT NULL,
    "cplusitem8" numeric(10,0) DEFAULT 0 NOT NULL,
    "事假扣款" numeric(10,0) DEFAULT 0 NOT NULL,
    "病假扣款" numeric(10,0) DEFAULT 0 NOT NULL,
    "曠職扣款" numeric(10,0) DEFAULT 0 NOT NULL,
    "遲到扣款" numeric(10,0) DEFAULT 0 NOT NULL,
    "早退扣款" numeric(10,0) DEFAULT 0 NOT NULL,
    "缺失扣款" numeric(10,0) DEFAULT 0 NOT NULL,
    "損失扣款" numeric(10,0) DEFAULT 0 NOT NULL,
    "cminusitem8" numeric(10,0) DEFAULT 0 NOT NULL,
    "dailyovertime" numeric(10,0) DEFAULT 0 NOT NULL,
    "montylyovertime" numeric(10,0) DEFAULT 0 NOT NULL,
    "職等" smallint DEFAULT 0 NOT NULL,
    "職級" smallint DEFAULT 0 NOT NULL,
    "薪點" numeric(10,0) DEFAULT 0 NOT NULL
);
CREATE UNIQUE INDEX "hrfil2005key1" ON "hrfil2005" ("員工編號", "年月");
CREATE UNIQUE INDEX "hrfil2005key2" ON "hrfil2005" ("年月", "員工編號");
COMMENT ON TABLE "hrfil2005" IS '每月薪資明細';

-- Files：每月薪資彙總
CREATE TABLE "hrfil2006" (
    "年月" char(8) DEFAULT ' ' NOT NULL,
    "員工編號" varchar(10) DEFAULT ' ' NOT NULL,
    "員工姓名" varchar(50) DEFAULT ' ' NOT NULL,
    "身份證" varchar(10) DEFAULT ' ' NOT NULL,
    "工資卡號" varchar(10) DEFAULT ' ' NOT NULL,
    "部門代號" varchar(10) DEFAULT ' ' NOT NULL,
    "部門" varchar(20) DEFAULT ' ' NOT NULL,
    "職稱" varchar(50) DEFAULT ' ' NOT NULL,
    "出差" numeric(4,1) DEFAULT 0 NOT NULL,
    "遲到" numeric(4,1) DEFAULT 0 NOT NULL,
    "早退" numeric(4,1) DEFAULT 0 NOT NULL,
    "假別一" numeric(4,1) DEFAULT 0 NOT NULL,
    "假別二" numeric(4,1) DEFAULT 0 NOT NULL,
    "假別三" numeric(4,1) DEFAULT 0 NOT NULL,
    "假別四" numeric(4,1) DEFAULT 0 NOT NULL,
    "假別五" numeric(4,1) DEFAULT 0 NOT NULL,
    "假別六" numeric(4,1) DEFAULT 0 NOT NULL,
    "假別七" numeric(4,1) DEFAULT 0 NOT NULL,
    "假別八" numeric(4,1) DEFAULT 0 NOT NULL,
    "假別九" numeric(4,1) DEFAULT 0 NOT NULL,
    "假別十" numeric(4,1) DEFAULT 0 NOT NULL,
    "假別十一" numeric(4,1) DEFAULT 0 NOT NULL,
    "假別十二" numeric(4,1) DEFAULT 0 NOT NULL,
    "假別十三" numeric(4,1) DEFAULT 0 NOT NULL,
    "假別十四" numeric(4,1) DEFAULT 0 NOT NULL,
    "本薪" numeric(12,2) DEFAULT 0 NOT NULL,
    "職務津貼" numeric(12,2) DEFAULT 0 NOT NULL,
    "出勤日支" numeric(12,2) DEFAULT 0 NOT NULL,
    "出勤津貼" numeric(12,2) DEFAULT 0 NOT NULL,
    "交通津貼" numeric(12,2) DEFAULT 0 NOT NULL,
    "技術津貼" numeric(12,2) DEFAULT 0 NOT NULL,
    "午餐津貼" numeric(12,2) DEFAULT 0 NOT NULL,
    "特休津貼" numeric(12,2) DEFAULT 0 NOT NULL,
    "伙食津貼" numeric(12,2) DEFAULT 0 NOT NULL,
    "夜班津貼" numeric(12,2) DEFAULT 0 NOT NULL,
    "大夜津貼" numeric(12,2) DEFAULT 0 NOT NULL,
    "加班費" numeric(12,2) DEFAULT 0 NOT NULL,
    "車馬費一" numeric(12,2) DEFAULT 0 NOT NULL,
    "車馬費二" numeric(12,2) DEFAULT 0 NOT NULL,
    "車馬費" numeric(12,2) DEFAULT 0 NOT NULL,
    "本月應發金額" numeric(12,2) DEFAULT 0 NOT NULL,
    "事病假薪點" numeric(12,2) DEFAULT 0 NOT NULL,
    "遲到早退扣支" numeric(12,2) DEFAULT 0 NOT NULL,
    "調補扣支" numeric(12,2) DEFAULT 0 NOT NULL,
    "借支" numeric(12,2) DEFAULT 0 NOT NULL,
    "自提退休金" numeric(12,2) DEFAULT 0 NOT NULL,
    "所得稅" numeric(12,2) DEFAULT 0 NOT NULL,
    "勞保費" numeric(12,2) DEFAULT 0 NOT NULL,
    "健保費" numeric(12,2) DEFAULT 0 NOT NULL,
    "二代健保" numeric(12,2) DEFAULT 0 NOT NULL,
    "加班費一" numeric(12,2) DEFAULT 0 NOT NULL,
    "加班費二" numeric(12,2) DEFAULT 0 NOT NULL,
    "實發金額" numeric(12,2) DEFAULT 0 NOT NULL,
    "上班打卡日" numeric(4,1) DEFAULT 0 NOT NULL,
    "加班計算日薪" numeric(12,2) DEFAULT 0 NOT NULL,
    "特休計算日薪" numeric(12,2) DEFAULT 0 NOT NULL,
    "課稅所得" numeric(12,2) DEFAULT 0 NOT NULL,
    "平日前2小時" numeric(6,2) DEFAULT 0 NOT NULL,
    "平日前4小時" numeric(6,2) DEFAULT 0 NOT NULL,
    "平日大於4小時" numeric(6,2) DEFAULT 0 NOT NULL,
    "休息日前2小時" numeric(6,2) DEFAULT 0 NOT NULL,
    "休息日前8小時" numeric(6,2) DEFAULT 0 NOT NULL,
    "休息日大於8小時" numeric(6,2) DEFAULT 0 NOT NULL,
    "例假日前8小時" numeric(6,2) DEFAULT 0 NOT NULL,
    "例假日大於8小時" numeric(6,2) DEFAULT 0 NOT NULL,
    "例假日大於10小時" numeric(6,2) DEFAULT 0 NOT NULL,
    "例假日補休小時" numeric(6,2) DEFAULT 0 NOT NULL,
    "國定假日前8小時" numeric(6,2) DEFAULT 0 NOT NULL,
    "國定假日大於8小時" numeric(6,2) DEFAULT 0 NOT NULL,
    "國定假日大於10小時" numeric(6,2) DEFAULT 0 NOT NULL,
    "公司代碼" varchar(1) DEFAULT ' ' NOT NULL,
    "薪資分群" varchar(2) DEFAULT ' ' NOT NULL
);
CREATE UNIQUE INDEX "hrfil2006key1" ON "hrfil2006" ("年月", "員工編號");
COMMENT ON TABLE "hrfil2006" IS '每月薪資彙總';
COMMENT ON COLUMN "hrfil2006"."出差" IS '特休計薪天數';
COMMENT ON COLUMN "hrfil2006"."假別一" IS '01病假';
COMMENT ON COLUMN "hrfil2006"."假別二" IS '02事假';
COMMENT ON COLUMN "hrfil2006"."假別三" IS '03公傷病假';
COMMENT ON COLUMN "hrfil2006"."假別四" IS '04調補';
COMMENT ON COLUMN "hrfil2006"."假別五" IS '05公假';
COMMENT ON COLUMN "hrfil2006"."假別六" IS '06婚假';
COMMENT ON COLUMN "hrfil2006"."假別七" IS '07喪假';
COMMENT ON COLUMN "hrfil2006"."假別八" IS '08特別休假';
COMMENT ON COLUMN "hrfil2006"."假別九" IS '09產假';
COMMENT ON COLUMN "hrfil2006"."假別十" IS '10產檢假';
COMMENT ON COLUMN "hrfil2006"."假別十一" IS '11陪產假';
COMMENT ON COLUMN "hrfil2006"."假別十二" IS '12加班轉調補';
COMMENT ON COLUMN "hrfil2006"."假別十三" IS '13加班勾調補';
COMMENT ON COLUMN "hrfil2006"."假別十四" IS '14.無薪假';
COMMENT ON COLUMN "hrfil2006"."出勤日支" IS '時薪';
COMMENT ON COLUMN "hrfil2006"."事病假薪點" IS '事病假扣支';

-- Files：薪資匯入明細
CREATE TABLE "hrfil2007" (
    "年月" varchar(6) DEFAULT ' ' NOT NULL,
    "員工編號" varchar(10) DEFAULT ' ' NOT NULL,
    "員工姓名" varchar(10) NOT NULL,
    "本薪" numeric(10,0) DEFAULT 0 NOT NULL,
    "職務津貼" numeric(10,0) DEFAULT 0 NOT NULL,
    "出勤日支" numeric(10,0) DEFAULT 0 NOT NULL,
    "出勤天數" numeric(10,0) DEFAULT 0 NOT NULL,
    "出勤津貼" numeric(10,0) DEFAULT 0 NOT NULL,
    "交通津貼" numeric(10,0) DEFAULT 0 NOT NULL,
    "技術津貼" numeric(10,0) DEFAULT 0 NOT NULL,
    "午餐日支" numeric(10,0) DEFAULT 0 NOT NULL,
    "午餐津貼" numeric(10,0) DEFAULT 0 NOT NULL,
    "加班費" numeric(10,0) DEFAULT 0 NOT NULL,
    "合計" numeric(10,0) DEFAULT 0 NOT NULL,
    "事病假薪點" numeric(10,0) DEFAULT 0 NOT NULL,
    "借支" numeric(10,0) DEFAULT 0 NOT NULL,
    "自提退休金" numeric(10,0) DEFAULT 0 NOT NULL,
    "所得稅" numeric(10,0) DEFAULT 0 NOT NULL,
    "勞保費" numeric(10,0) DEFAULT 0 NOT NULL,
    "健保費" numeric(10,0) DEFAULT 0 NOT NULL,
    "二代健保" numeric(10,0) DEFAULT 0 NOT NULL,
    "特休津貼" numeric(10,0) DEFAULT 0 NOT NULL,
    "伙食津貼" numeric(10,0) DEFAULT 0 NOT NULL,
    "加班費二" numeric(10,0) DEFAULT 0 NOT NULL,
    "實付金額" numeric(10,0) DEFAULT 0 NOT NULL,
    "職等" varchar(10) DEFAULT ' ' NOT NULL,
    "薪點" numeric(10,0) DEFAULT 0 NOT NULL
);
CREATE UNIQUE INDEX "hrfil2007key1" ON "hrfil2007" ("員工編號", "年月");
CREATE UNIQUE INDEX "hrfil2007key2" ON "hrfil2007" ("年月", "員工編號");
COMMENT ON TABLE "hrfil2007" IS '薪資匯入明細';

-- Files：職位薪點表
CREATE TABLE "hrfil2008" (
    "職等" smallint DEFAULT 1 NOT NULL,
    "級差" smallint NOT NULL,
    "初級薪資" smallint NOT NULL
);
CREATE UNIQUE INDEX "hrfil2008key1" ON "hrfil2008" ("職等");
COMMENT ON TABLE "hrfil2008" IS '職位薪點表';

-- Files：員工附檔一
CREATE TABLE "hrfil0011" (
    "員工流水編號" varchar(60) DEFAULT ' ' NOT NULL,
    "介紹人" varchar(12) NOT NULL,
    "性別" smallint NOT NULL,
    "畢業學校" varchar(15) NOT NULL,
    "教育程度" varchar(10) NOT NULL,
    "主修系統" varchar(16) NOT NULL,
    "緊急連絡人一" varchar(12) NOT NULL,
    "緊急連絡電話一" varchar(20) NOT NULL,
    "緊急連絡人二" varchar(12) NOT NULL,
    "緊急連絡電話二" varchar(20) NOT NULL,
    "戶藉地址" varchar(70) NOT NULL,
    "年假" smallint NOT NULL,
    "剩餘年假" smallint NOT NULL,
    "薪資類別" varchar(1) NOT NULL,
    "銀行帳戶" varchar(20) NOT NULL,
    "專長" varchar(100) NOT NULL,
    "轉帳" smallint NOT NULL,
    "議定薪資" numeric(10,2) NOT NULL,
    PRIMARY KEY ("員工流水編號")
);
COMMENT ON TABLE "hrfil0011" IS '員工附檔一';
COMMENT ON COLUMN "hrfil0011"."主修系統" IS '主修科系';

-- Files：員工學歷
CREATE TABLE "hrfil0012" (
    "員工流水編號" varchar(60) DEFAULT ' ' NOT NULL,
    "序號" smallint NOT NULL,
    "學校" varchar(30) NOT NULL,
    "畢業否" smallint NOT NULL,
    "修業日期起" char(8) NOT NULL,
    "修業日期迄" char(8) NOT NULL,
    "流水編號" varchar(60) DEFAULT ' ' NOT NULL,
    PRIMARY KEY ("流水編號")
);
CREATE INDEX "hrfil0012key2" ON "hrfil0012" ("員工流水編號", "序號");
COMMENT ON TABLE "hrfil0012" IS '員工學歷';

-- Files：員工經歷
CREATE TABLE "hrfil0013" (
    "員工流水編號" varchar(60) DEFAULT ' ' NOT NULL,
    "序號" smallint NOT NULL,
    "公司名稱" varchar(60) NOT NULL,
    "職務" varchar(30) NOT NULL,
    "起始日期" char(8) NOT NULL,
    "結束日期" char(8) NOT NULL,
    "流水編號" varchar(60) DEFAULT ' ' NOT NULL,
    PRIMARY KEY ("流水編號")
);
CREATE INDEX "hrfil0013key2" ON "hrfil0013" ("員工流水編號", "序號");
COMMENT ON TABLE "hrfil0013" IS '員工經歷';

-- Files：員工獎懲
CREATE TABLE "hrfil0014" (
    "員工流水編號" varchar(60) DEFAULT ' ' NOT NULL,
    "序號" smallint NOT NULL,
    "獎懲類別" varchar(10) NOT NULL,
    "獎懲日期" char(8) NOT NULL,
    "金額" numeric(12,2) NOT NULL,
    "備註" varchar(30) NOT NULL,
    "流水編號" varchar(60) DEFAULT ' ' NOT NULL,
    PRIMARY KEY ("流水編號")
);
CREATE INDEX "hrfil0014key2" ON "hrfil0014" ("員工流水編號", "序號");
COMMENT ON TABLE "hrfil0014" IS '員工獎懲';

-- Files：員工職務
CREATE TABLE "hrfil0015" (
    "員工流水編號" varchar(60) DEFAULT ' ' NOT NULL,
    "序號" smallint NOT NULL,
    "部門流水編號" varchar(60) NOT NULL,
    "職務代碼" varchar(30) NOT NULL,
    "起始日期" char(8) NOT NULL,
    "結束日期" char(8) NOT NULL,
    "流水編號" varchar(60) DEFAULT ' ' NOT NULL,
    PRIMARY KEY ("流水編號")
);
CREATE INDEX "hrfil0015key2" ON "hrfil0015" ("員工流水編號", "序號");
COMMENT ON TABLE "hrfil0015" IS '員工職務';

-- Files：員工訓練
CREATE TABLE "hrfil0016" (
    "員工流水編號" varchar(60) DEFAULT ' ' NOT NULL,
    "序號" smallint NOT NULL,
    "項目" varchar(30) NOT NULL,
    "地點" varchar(30) NOT NULL,
    "期間" varchar(20) NOT NULL,
    "備註" varchar(255) NOT NULL,
    "流水編號" varchar(60) DEFAULT ' ' NOT NULL,
    PRIMARY KEY ("流水編號")
);
CREATE INDEX "hrfil0016key2" ON "hrfil0016" ("員工流水編號", "序號");
COMMENT ON TABLE "hrfil0016" IS '員工訓練';

-- Files：代理人
CREATE TABLE "hrfil0017" (
    "員工流水編號" varchar(60) DEFAULT ' ' NOT NULL,
    "代理人流水編號" varchar(60) DEFAULT ' ' NOT NULL,
    "起始日期" char(8) NOT NULL,
    "終止日期" char(8) NOT NULL,
    "流水編號" varchar(60) DEFAULT ' ' NOT NULL,
    PRIMARY KEY ("流水編號")
);
CREATE INDEX "hrfil0017key2" ON "hrfil0017" ("員工流水編號", "代理人流水編號", "起始日期", "終止日期");
COMMENT ON TABLE "hrfil0017" IS '代理人';

-- Files：最高權限
CREATE TABLE "hrfil0018" (
    "員工流水編號" varchar(60) DEFAULT ' ' NOT NULL,
    "最高權限" smallint NOT NULL
);
CREATE UNIQUE INDEX "hrfil0018key1" ON "hrfil0018" ("員工流水編號");
COMMENT ON TABLE "hrfil0018" IS '最高權限';

-- Files：請假匯入明細
CREATE TABLE "hrfil0020" (
    "員工編號" varchar(10) DEFAULT ' ' NOT NULL,
    "年月" varchar(6) DEFAULT ' ' NOT NULL,
    "已休特休" numeric(4,1) NOT NULL,
    "特休支薪" numeric(4,1) NOT NULL,
    "病假" numeric(4,1) NOT NULL,
    "喪假" numeric(4,1) NOT NULL,
    "公傷假" numeric(4,1) NOT NULL,
    "事假" numeric(5,1) NOT NULL,
    "調補班" numeric(5,1) NOT NULL,
    "行號" integer NOT NULL
);
CREATE UNIQUE INDEX "hrfil0020key1" ON "hrfil0020" ("員工編號", "年月");
COMMENT ON TABLE "hrfil0020" IS '請假匯入明細';
COMMENT ON COLUMN "hrfil0020"."已休特休" IS '已休特休(日)';
COMMENT ON COLUMN "hrfil0020"."特休支薪" IS '特休支薪(日)';
COMMENT ON COLUMN "hrfil0020"."病假" IS '病假(日)';
COMMENT ON COLUMN "hrfil0020"."喪假" IS '喪假(日)';
COMMENT ON COLUMN "hrfil0020"."公傷假" IS '公傷假(日)';
COMMENT ON COLUMN "hrfil0020"."事假" IS '事假(時)';
COMMENT ON COLUMN "hrfil0020"."調補班" IS '調補班(時)';

-- Files：員工加班一
CREATE TABLE "hrfil0021" (
    "申請人" varchar(20) DEFAULT ' ',
    "加班日期" char(8) DEFAULT '00000000' NOT NULL,
    "倍數欄位" numeric(2,0) DEFAULT 0,
    "加班小時" numeric(4,1) DEFAULT 0,
    "當日累計" numeric(4,1) DEFAULT 0 NOT NULL,
    "上班時間" char(6) DEFAULT '000000' NOT NULL,
    "下班時間" char(6) DEFAULT '000000' NOT NULL,
    "加班費" numeric(12,2) NOT NULL
);
CREATE UNIQUE INDEX "hrfil0021key1" ON "hrfil0021" ("申請人", "加班日期", "倍數欄位");
COMMENT ON TABLE "hrfil0021" IS '員工加班一';

-- Files：每月其它扣支
CREATE TABLE "hrfil0022" (
    "年月" char(8) DEFAULT '00000000' NOT NULL,
    "員工編號" varchar(10) DEFAULT ' ' NOT NULL,
    "定期存款" numeric(10,0) DEFAULT 0 NOT NULL,
    "宿舍打掃費" numeric(10,0) DEFAULT 0 NOT NULL,
    "蒸籠使用費" numeric(10,0) DEFAULT 0 NOT NULL,
    "水電費" numeric(10,0) DEFAULT 0 NOT NULL,
    "便當費" numeric(10,0) DEFAULT 0 NOT NULL,
    "其他一" numeric(10,0) DEFAULT 0 NOT NULL,
    "其他二" numeric(10,0) DEFAULT 0 NOT NULL,
    "其他三" numeric(10,0) DEFAULT 0 NOT NULL,
    "其他加項一" numeric(10,0) DEFAULT 0 NOT NULL,
    "其他加項二" numeric(10,0) DEFAULT 0 NOT NULL,
    "其他加項三" numeric(10,0) DEFAULT 0 NOT NULL,
    "備註" varchar(30) NOT NULL
);
CREATE UNIQUE INDEX "hrfil0022key1" ON "hrfil0022" ("年月", "員工編號");
CREATE UNIQUE INDEX "hrfil0022key2" ON "hrfil0022" ("員工編號", "年月");
COMMENT ON TABLE "hrfil0022" IS '每月其它扣支';
COMMENT ON COLUMN "hrfil0022"."其他一" IS '其他減項一';
COMMENT ON COLUMN "hrfil0022"."其他二" IS '其他減項二';
COMMENT ON COLUMN "hrfil0022"."其他三" IS '其他減項三';

-- Files：門禁資料
CREATE TABLE "hrfil0023" (
    "裝置名稱" varchar(30) NOT NULL,
    "門禁點" varchar(30) NOT NULL,
    "部門" varchar(20) NOT NULL,
    "姓名" varchar(20) NOT NULL,
    "工號" varchar(10) NOT NULL,
    "卡號" varchar(10) NOT NULL,
    "刷卡日期" char(8) NOT NULL,
    "刷卡時間" char(6) NOT NULL,
    "時間戳記" varchar(30) DEFAULT ' ' NOT NULL,
    "事件說明" varchar(30) NOT NULL,
    "進_出" varchar(10) NOT NULL,
    "班別" varchar(10) NOT NULL,
    "原刷卡時間" char(6) NOT NULL
);
CREATE UNIQUE INDEX "hrfil0023key1" ON "hrfil0023" ("裝置名稱", "工號", "刷卡日期", "刷卡時間");
CREATE INDEX "hrfil0023key2" ON "hrfil0023" ("工號", "時間戳記");
COMMENT ON TABLE "hrfil0023" IS '門禁資料';

-- Files：xxMobile.Server.AP log
CREATE TABLE "mobile0001" (
    "employee_id" varchar(20) DEFAULT ' ' NOT NULL,
    "id" varchar(16) DEFAULT ' ' NOT NULL,
    "ctx_id" varchar(18) DEFAULT ' ' NOT NULL,
    "program" varchar(50) DEFAULT ' ' NOT NULL,
    "client_os" varchar(50) DEFAULT ' ' NOT NULL,
    "client_ip" varchar(40) DEFAULT ' ' NOT NULL,
    "start_timestam" varchar(14) DEFAULT ' ' NOT NULL,
    PRIMARY KEY ("employee_id", "id")
);
CREATE INDEX "mobile0001_02" ON "mobile0001" ("id");
COMMENT ON TABLE "mobile0001" IS 'xxMobile.Server.AP log';
COMMENT ON COLUMN "mobile0001"."employee_id" IS 'employee id';
COMMENT ON COLUMN "mobile0001"."ctx_id" IS 'ctx id';
COMMENT ON COLUMN "mobile0001"."client_os" IS 'client os';
COMMENT ON COLUMN "mobile0001"."client_ip" IS 'client IP';
COMMENT ON COLUMN "mobile0001"."start_timestam" IS 'start timestamp';

-- Files：xxMobile.Server.DataSync
CREATE TABLE "mobile0002" (
    "master" varchar(1) DEFAULT 'M' NOT NULL,
    "lastsynctimestamp" varchar(14) DEFAULT ' ' NOT NULL,
    PRIMARY KEY ("master")
);
COMMENT ON TABLE "mobile0002" IS 'xxMobile.Server.DataSync';

-- Files：合一智感.感測器記錄
CREATE TABLE "fili0001" (
    "流水編號" varchar(60) DEFAULT ' ' NOT NULL,
    "感測器編號" varchar(20) NOT NULL,
    "感測器序號" smallint NOT NULL,
    "感測器類型代碼" varchar(20) NOT NULL,
    "啟用狀態" varchar(1) NOT NULL,
    "slaveid" varchar(20) NOT NULL,
    "感測器類型" varchar(20) NOT NULL,
    "感測器別名" varchar(20) NOT NULL,
    "讀值模式" varchar(20) NOT NULL,
    "讀值持續" integer NOT NULL,
    "讀取週期" numeric(7,2) NOT NULL,
    "讀值微調" numeric(7,2) NOT NULL,
    "上傳模式" varchar(20) NOT NULL,
    "單位" varchar(10) NOT NULL,
    "狀態代碼" varchar(2) NOT NULL,
    "錯誤處理次數" smallint NOT NULL,
    "錯誤處理動作" varchar(20) NOT NULL,
    "目標參數動作" varchar(30) NOT NULL,
    "備註" varchar(50) NOT NULL,
    "讀值" numeric(12,2) NOT NULL,
    "讀取日期" char(8) DEFAULT '00000000' NOT NULL,
    "讀取時間" char(6) DEFAULT '000000' NOT NULL,
    "讀取IP" varchar(50) NOT NULL
);
CREATE UNIQUE INDEX "fili0001key1" ON "fili0001" ("流水編號");
CREATE UNIQUE INDEX "fili0001key2" ON "fili0001" ("感測器編號", "感測器序號", "讀取日期", "讀取時間");
COMMENT ON TABLE "fili0001" IS '合一智感.感測器記錄';

-- EDB：模組參數
CREATE TABLE "app" (
    "appkey" integer DEFAULT 0 NOT NULL,
    "appname" varchar(10) NOT NULL,
    "ecf" varchar(20) NOT NULL,
    "entrance" varchar(16) DEFAULT 'Entrance' NOT NULL,
    "available" smallint NOT NULL,
    PRIMARY KEY ("appkey")
);
COMMENT ON TABLE "app" IS '模組參數';

-- EDB：單據記錄
CREATE TABLE "a01_1" (
    "serial_num" varchar(60) DEFAULT ' ' NOT NULL,
    "seqno" numeric(10,0) DEFAULT 0 NOT NULL,
    "objectdetailid" varchar(60) DEFAULT ' ' NOT NULL,
    "modifiedby" varchar(60) DEFAULT ' ' NOT NULL,
    "modifieddate" char(8) DEFAULT '00000000' NOT NULL,
    "modifiedtime" char(6) DEFAULT '000000' NOT NULL,
    "modifiedfield" varchar(50) DEFAULT ' ' NOT NULL,
    "modifiedcontent" bytea,
    PRIMARY KEY ("serial_num", "seqno")
);
CREATE INDEX "a01_1key2" ON "a01_1" ("serial_num", "objectdetailid");
COMMENT ON TABLE "a01_1" IS '單據記錄';
COMMENT ON COLUMN "a01_1"."serial_num" IS 'ID';
COMMENT ON COLUMN "a01_1"."objectdetailid" IS 'DetailID';
COMMENT ON COLUMN "a01_1"."modifieddate" IS 'Date';
COMMENT ON COLUMN "a01_1"."modifiedtime" IS 'Time';
COMMENT ON COLUMN "a01_1"."modifiedfield" IS 'Field';
COMMENT ON COLUMN "a01_1"."modifiedcontent" IS 'Content';

-- EDB：單據流程
CREATE TABLE "a01_2" (
    "serial_num" varchar(60) DEFAULT ' ' NOT NULL,
    "version" integer DEFAULT 0 NOT NULL,
    "serial_num_seq" integer DEFAULT 0 NOT NULL,
    "assignedto" varchar(60) DEFAULT ' ' NOT NULL,
    "signedby" varchar(60) DEFAULT ' ' NOT NULL,
    "signeddate" char(8) DEFAULT '00000000' NOT NULL,
    "signedtime" char(6) DEFAULT '000000' NOT NULL,
    "signedtype" varchar(1) DEFAULT '0' NOT NULL,
    "read" smallint DEFAULT 0 NOT NULL,
    "signorcc" smallint DEFAULT 0 NOT NULL,
    "free2sign" smallint DEFAULT 0 NOT NULL,
    "folder" varchar(1) DEFAULT ' ' NOT NULL,
    "actionguid" varchar(60) DEFAULT ' ' NOT NULL,
    "actioncompleted" smallint DEFAULT 0 NOT NULL,
    "actionresult" varchar(60) DEFAULT ' ' NOT NULL,
    "dataedit" varchar(30) DEFAULT ' ' NOT NULL,
    "processfor" varchar(60) DEFAULT ' ' NOT NULL,
    "addflow" smallint DEFAULT 0 NOT NULL,
    "assigncostdept" smallint DEFAULT 0 NOT NULL,
    "foroption" smallint DEFAULT 0 NOT NULL,
    "opento" smallint DEFAULT 0 NOT NULL,
    "fromid" varchar(60) DEFAULT ' ' NOT NULL,
    "會簽判定" smallint DEFAULT 0 NOT NULL,
    "會簽方式" varchar(1) DEFAULT ' ' NOT NULL,
    "signbackto" varchar(60) DEFAULT ' ' NOT NULL,
    "singature_header" varchar(100) DEFAULT ' ' NOT NULL,
    "singature_line" integer DEFAULT 0 NOT NULL,
    "singature_seq" integer DEFAULT 0 NOT NULL,
    "recordid" varchar(60) DEFAULT ' ' NOT NULL,
    "opnion" text,
    "註解" text,
    "加簽通知" smallint DEFAULT 0 NOT NULL,
    PRIMARY KEY ("serial_num", "serial_num_seq")
);
CREATE INDEX "a01_2key3" ON "a01_2" ("serial_num", "signorcc" DESC, "serial_num_seq");
CREATE INDEX "a01_2key4" ON "a01_2" ("serial_num", "signedby");
CREATE INDEX "a01_2key5" ON "a01_2" ("serial_num", "assignedto");
CREATE INDEX "objflowkey6" ON "a01_2" ("recordid");
CREATE INDEX "objflowkey7" ON "a01_2" ("actionguid");
CREATE INDEX "objflowkey8" ON "a01_2" ("serial_num", "singature_seq", "serial_num_seq");
COMMENT ON TABLE "a01_2" IS '單據流程';
COMMENT ON COLUMN "a01_2"."serial_num" IS '單據流水號';
COMMENT ON COLUMN "a01_2"."version" IS '父階序號';
COMMENT ON COLUMN "a01_2"."serial_num_seq" IS '流程序號';
COMMENT ON COLUMN "a01_2"."assignedto" IS '應簽核人員';
COMMENT ON COLUMN "a01_2"."signedby" IS '簽核人員';
COMMENT ON COLUMN "a01_2"."signeddate" IS '簽核日期';
COMMENT ON COLUMN "a01_2"."signedtime" IS '簽核時間';
COMMENT ON COLUMN "a01_2"."signedtype" IS '簽核結果';
COMMENT ON COLUMN "a01_2"."read" IS '已讀取';
COMMENT ON COLUMN "a01_2"."signorcc" IS '正副本';
COMMENT ON COLUMN "a01_2"."free2sign" IS '免簽';
COMMENT ON COLUMN "a01_2"."folder" IS '資料夾';
COMMENT ON COLUMN "a01_2"."actionguid" IS '程序GUID';
COMMENT ON COLUMN "a01_2"."actioncompleted" IS '程序完成';
COMMENT ON COLUMN "a01_2"."actionresult" IS '程序結果';
COMMENT ON COLUMN "a01_2"."dataedit" IS '內容修正';
COMMENT ON COLUMN "a01_2"."processfor" IS '執行說明';
COMMENT ON COLUMN "a01_2"."addflow" IS '加簽';
COMMENT ON COLUMN "a01_2"."assigncostdept" IS '成本歸屬';
COMMENT ON COLUMN "a01_2"."foroption" IS '意見收集';
COMMENT ON COLUMN "a01_2"."opento" IS '並簽';
COMMENT ON COLUMN "a01_2"."fromid" IS '來源或加簽人';
COMMENT ON COLUMN "a01_2"."signbackto" IS '指定退簽人';
COMMENT ON COLUMN "a01_2"."singature_header" IS '簽名抬頭';
COMMENT ON COLUMN "a01_2"."singature_line" IS '簽名行號';
COMMENT ON COLUMN "a01_2"."singature_seq" IS '簽名序號';
COMMENT ON COLUMN "a01_2"."opnion" IS '簽核意見';

-- EDB：單據活動
CREATE TABLE "a01_3" (
    "serial_num" varchar(60) DEFAULT ' ' NOT NULL,
    "version" integer DEFAULT 0 NOT NULL,
    "serial_num_seq" integer DEFAULT 0 NOT NULL,
    "activity_seqno" integer DEFAULT 0 NOT NULL,
    "activity" varchar(1) DEFAULT ' ' NOT NULL,
    "date_" char(8) DEFAULT '00000000' NOT NULL,
    "time_" char(6) DEFAULT '000000' NOT NULL,
    "employeeid" varchar(60) DEFAULT ' ' NOT NULL,
    "refdocid" varchar(60) DEFAULT ' ' NOT NULL,
    PRIMARY KEY ("serial_num", "version", "serial_num_seq", "activity_seqno")
);
CREATE INDEX "a01_3key2" ON "a01_3" ("serial_num", "version", "date_", "time_");
COMMENT ON TABLE "a01_3" IS '單據活動';
COMMENT ON COLUMN "a01_3"."serial_num" IS '流水編號';
COMMENT ON COLUMN "a01_3"."version" IS '單據階層';
COMMENT ON COLUMN "a01_3"."serial_num_seq" IS '流程序號';
COMMENT ON COLUMN "a01_3"."activity_seqno" IS '活動序號';
COMMENT ON COLUMN "a01_3"."activity" IS '活動項目';
COMMENT ON COLUMN "a01_3"."date_" IS '日期';
COMMENT ON COLUMN "a01_3"."time_" IS '時間';
COMMENT ON COLUMN "a01_3"."employeeid" IS '人員';
COMMENT ON COLUMN "a01_3"."refdocid" IS '參考單據';

-- EDB：單據授權
CREATE TABLE "a01_4" (
    "serial_num" varchar(60) DEFAULT ' ' NOT NULL,
    "toid" varchar(60) DEFAULT ' ' NOT NULL,
    "write" smallint DEFAULT 0 NOT NULL,
    "read" smallint DEFAULT 0 NOT NULL,
    "download" smallint DEFAULT 0 NOT NULL,
    "pdfcopy" smallint DEFAULT 0 NOT NULL,
    "pdfprint" smallint DEFAULT 0 NOT NULL,
    "pdfwrite" smallint DEFAULT 0 NOT NULL,
    "pdfannotation" smallint DEFAULT 0 NOT NULL,
    "duedate" char(8) DEFAULT '00000000' NOT NULL,
    PRIMARY KEY ("serial_num", "toid")
);
CREATE INDEX "a01_4key2" ON "a01_4" ("toid");
COMMENT ON TABLE "a01_4" IS '單據授權';
COMMENT ON COLUMN "a01_4"."serial_num" IS '單據流水號';
COMMENT ON COLUMN "a01_4"."toid" IS '人員流水號';

-- EDB：單據附件
CREATE TABLE "a01_5" (
    "serial_num" varchar(60) DEFAULT ' ' NOT NULL,
    "version" integer DEFAULT 0 NOT NULL,
    "detail_item_num" integer DEFAULT 0 NOT NULL,
    "attfile" varchar(50) DEFAULT ' ' NOT NULL,
    "說明" varchar(100) DEFAULT ' ' NOT NULL,
    "createby" varchar(60) DEFAULT ' ' NOT NULL,
    "recordid" varchar(60) DEFAULT ' ' NOT NULL,
    PRIMARY KEY ("recordid")
);
CREATE INDEX "a01_5key1" ON "a01_5" ("serial_num", "version", "detail_item_num");
COMMENT ON TABLE "a01_5" IS '單據附件';
COMMENT ON COLUMN "a01_5"."serial_num" IS '流水編號';
COMMENT ON COLUMN "a01_5"."version" IS '單據階層';
COMMENT ON COLUMN "a01_5"."detail_item_num" IS '表身序號';
COMMENT ON COLUMN "a01_5"."attfile" IS '附件名稱';
COMMENT ON COLUMN "a01_5"."createby" IS '建檔人';

-- EDB：單據受文者
CREATE TABLE "a01_6" (
    "serial_num" varchar(60) DEFAULT ' ' NOT NULL,
    "copytoid" varchar(512) DEFAULT ' ' NOT NULL,
    "copytoname" varchar(1024) DEFAULT ' ' NOT NULL,
    "duedate" char(8) DEFAULT '00000000' NOT NULL
);
CREATE UNIQUE INDEX "a01_6key1" ON "a01_6" ("serial_num");
COMMENT ON TABLE "a01_6" IS '單據受文者';
COMMENT ON COLUMN "a01_6"."serial_num" IS '流水編號';
COMMENT ON COLUMN "a01_6"."copytoid" IS '受文者ID';
COMMENT ON COLUMN "a01_6"."copytoname" IS '受文者Name';
COMMENT ON COLUMN "a01_6"."duedate" IS '簽核期限';

-- EDB：單據自定內容
CREATE TABLE "a01_7" (
    "serial_num" varchar(60) DEFAULT ' ' NOT NULL,
    "serial_num_seq" integer DEFAULT 0 NOT NULL,
    "defined_seq" integer DEFAULT 0 NOT NULL,
    "content" varchar(512) DEFAULT ' ' NOT NULL,
    "recordid" varchar(60) DEFAULT ' ' NOT NULL
);
CREATE UNIQUE INDEX "a01_7key0" ON "a01_7" ("recordid");
CREATE UNIQUE INDEX "a01_7key1" ON "a01_7" ("serial_num", "serial_num_seq", "defined_seq");
COMMENT ON TABLE "a01_7" IS '單據自定內容';
COMMENT ON COLUMN "a01_7"."serial_num" IS '流水編號';
COMMENT ON COLUMN "a01_7"."serial_num_seq" IS '表身序號';
COMMENT ON COLUMN "a01_7"."defined_seq" IS '自定檔序號';
COMMENT ON COLUMN "a01_7"."content" IS '內容';

-- EDB：單據自定資料
CREATE TABLE "a01_8" (
    "serial_num" varchar(60) DEFAULT ' ' NOT NULL,
    "serial_num_seq" integer DEFAULT 0 NOT NULL,
    "itemtype" varchar(4) DEFAULT ' ' NOT NULL,
    "description" varchar(100) DEFAULT ' ' NOT NULL,
    "recordid" varchar(60) DEFAULT ' ' NOT NULL
);
CREATE UNIQUE INDEX "a01_8key0" ON "a01_8" ("recordid");
CREATE UNIQUE INDEX "a01_8key1" ON "a01_8" ("serial_num", "serial_num_seq");
COMMENT ON TABLE "a01_8" IS '單據自定資料';
COMMENT ON COLUMN "a01_8"."serial_num" IS '流水編號';
COMMENT ON COLUMN "a01_8"."serial_num_seq" IS '表身序號';
COMMENT ON COLUMN "a01_8"."itemtype" IS '自定大類';
COMMENT ON COLUMN "a01_8"."description" IS '項目說明';

-- EDB：單據傳票明細
CREATE TABLE "a01_9" (
    "serial_num" varchar(60) DEFAULT ' ' NOT NULL,
    "serial_num_seq" integer DEFAULT 0 NOT NULL,
    "借貸" smallint DEFAULT 0 NOT NULL,
    "科目代號" varchar(8) DEFAULT ' ' NOT NULL,
    "amount" numeric(12,2) DEFAULT 0 NOT NULL,
    "recordid" varchar(60) DEFAULT ' ' NOT NULL
);
CREATE UNIQUE INDEX "a10_9key0" ON "a01_9" ("recordid");
CREATE UNIQUE INDEX "a10_9key1" ON "a01_9" ("serial_num", "serial_num_seq");
COMMENT ON TABLE "a01_9" IS '單據傳票明細';
COMMENT ON COLUMN "a01_9"."serial_num" IS '單據流水號';
COMMENT ON COLUMN "a01_9"."serial_num_seq" IS '表身序號';
COMMENT ON COLUMN "a01_9"."amount" IS '金額';

-- EDB：單據傳票表頭
CREATE TABLE "a01_10" (
    "serial_num" varchar(60) DEFAULT ' ' NOT NULL,
    "trandate" char(8) DEFAULT '00000000' NOT NULL,
    "dramount" numeric(12,2) DEFAULT 0 NOT NULL,
    "cramount" numeric(12,2) DEFAULT 0 NOT NULL,
    "noteid" varchar(60) DEFAULT ' ' NOT NULL
);
CREATE UNIQUE INDEX "a01_10key0" ON "a01_10" ("serial_num");
CREATE UNIQUE INDEX "a01_10key1" ON "a01_10" ("noteid");
COMMENT ON TABLE "a01_10" IS '單據傳票表頭';
COMMENT ON COLUMN "a01_10"."serial_num" IS '流水編號';
COMMENT ON COLUMN "a01_10"."trandate" IS '結轉日期';
COMMENT ON COLUMN "a01_10"."dramount" IS '借方金額';
COMMENT ON COLUMN "a01_10"."cramount" IS '貸方金額';
COMMENT ON COLUMN "a01_10"."noteid" IS '傳票識別碼';

-- EDB：單據付款記錄
CREATE TABLE "a01_11" (
    "serial_num" varchar(60) DEFAULT ' ' NOT NULL,
    "serial_num_seq" integer DEFAULT 0 NOT NULL,
    "付款類別" varchar(1) DEFAULT '1' NOT NULL,
    "付款日期" char(8) DEFAULT ' ' NOT NULL,
    "現金匯款" varchar(1) DEFAULT ' ' NOT NULL,
    "實付金額" numeric(12,2) DEFAULT 0 NOT NULL,
    "相關單號" varchar(20) DEFAULT ' ' NOT NULL,
    "幣別" varchar(4) DEFAULT ' ' NOT NULL,
    "匯率" numeric(5,2) DEFAULT 0 NOT NULL,
    "請款金額" numeric(12,2) DEFAULT 0 NOT NULL,
    "recordid" varchar(60) DEFAULT ' ' NOT NULL
);
CREATE UNIQUE INDEX "a01_11key1" ON "a01_11" ("serial_num", "serial_num_seq");
COMMENT ON TABLE "a01_11" IS '單據付款記錄';
COMMENT ON COLUMN "a01_11"."serial_num" IS '流水編號';
COMMENT ON COLUMN "a01_11"."serial_num_seq" IS '付款序號';

-- EDB：單據動作確認
CREATE TABLE "a01_12" (
    "serial_num" varchar(60) DEFAULT ' ' NOT NULL,
    "serial_num_seq" integer DEFAULT 0 NOT NULL,
    "取消執行" smallint DEFAULT 0 NOT NULL,
    "執行狀態" varchar(1) DEFAULT ' ' NOT NULL,
    "相關單號" varchar(60) DEFAULT ' ' NOT NULL,
    "相關序號" integer DEFAULT 0 NOT NULL
);
CREATE UNIQUE INDEX "a01_12key1" ON "a01_12" ("serial_num", "serial_num_seq");
CREATE INDEX "a01_12key2" ON "a01_12" ("相關單號", "相關序號");
COMMENT ON TABLE "a01_12" IS '單據動作確認';
COMMENT ON COLUMN "a01_12"."serial_num" IS '流水編號';
COMMENT ON COLUMN "a01_12"."serial_num_seq" IS '動作序號';

-- EDB：單據意見設計
CREATE TABLE "a01_13" (
    "serial_num" varchar(60) DEFAULT ' ' NOT NULL,
    "serial_num_seq" integer DEFAULT 0 NOT NULL,
    "options" varchar(20) DEFAULT ' ' NOT NULL,
    "allowdescrip" smallint DEFAULT 0 NOT NULL
);
CREATE UNIQUE INDEX "a01_13key1" ON "a01_13" ("serial_num", "serial_num_seq");
COMMENT ON TABLE "a01_13" IS '單據意見設計';
COMMENT ON COLUMN "a01_13"."serial_num" IS '流水編號';
COMMENT ON COLUMN "a01_13"."serial_num_seq" IS '表身序號';
COMMENT ON COLUMN "a01_13"."options" IS '選項說明';
COMMENT ON COLUMN "a01_13"."allowdescrip" IS '附說明';

-- EDB：單據意見回覆
CREATE TABLE "a01_14" (
    "serial_num" varchar(60) DEFAULT ' ' NOT NULL,
    "repliedby" varchar(60) DEFAULT ' ' NOT NULL,
    "optionselected" integer DEFAULT 0 NOT NULL,
    "opion" varchar(50) DEFAULT ' ' NOT NULL
);
CREATE UNIQUE INDEX "a01_14key1" ON "a01_14" ("serial_num", "repliedby");
COMMENT ON TABLE "a01_14" IS '單據意見回覆';
COMMENT ON COLUMN "a01_14"."serial_num" IS '流水編號';
COMMENT ON COLUMN "a01_14"."repliedby" IS '回覆者ID';
COMMENT ON COLUMN "a01_14"."optionselected" IS '選項';
COMMENT ON COLUMN "a01_14"."opion" IS '意見';

-- EDB：單據個人註解
CREATE TABLE "a01_15" (
    "serial_num" varchar(60) DEFAULT ' ' NOT NULL,
    "serial_num_seq" integer DEFAULT 0 NOT NULL,
    "repliedby" varchar(60) DEFAULT ' ' NOT NULL,
    "日期" char(8) DEFAULT '00000000' NOT NULL,
    "時間" char(6) DEFAULT '000000' NOT NULL,
    "remarks" text
);
CREATE UNIQUE INDEX "a01_15key1" ON "a01_15" ("serial_num", "serial_num_seq");
COMMENT ON TABLE "a01_15" IS '單據個人註解';
COMMENT ON COLUMN "a01_15"."serial_num" IS '流水編號';
COMMENT ON COLUMN "a01_15"."serial_num_seq" IS '表身序號';
COMMENT ON COLUMN "a01_15"."repliedby" IS '回覆者ID';
COMMENT ON COLUMN "a01_15"."remarks" IS '註解';

-- EDB：單據關鍵字
CREATE TABLE "a01_16" (
    "guid" varchar(60) DEFAULT ' ' NOT NULL,
    "keyword" varchar(128) DEFAULT ' ' NOT NULL
);
CREATE UNIQUE INDEX "a01_16key1" ON "a01_16" ("guid", "keyword");
CREATE UNIQUE INDEX "a01_16key2" ON "a01_16" ("keyword", "guid");
COMMENT ON TABLE "a01_16" IS '單據關鍵字';
COMMENT ON COLUMN "a01_16"."guid" IS '流水編號';

-- EDB：單據外部簽核記錄
CREATE TABLE "a01_17" (
    "guid" varchar(60) DEFAULT ' ' NOT NULL,
    "docguid" varchar(60) DEFAULT ' ' NOT NULL,
    "signflag" varchar(10) DEFAULT ' ' NOT NULL,
    "filelocatiion" varchar(256) DEFAULT ' ' NOT NULL,
    "content" text,
    "updatedate" char(8) DEFAULT '00000000' NOT NULL,
    "updatetime" char(6) DEFAULT '000000' NOT NULL
);
CREATE UNIQUE INDEX "a01_17key1" ON "a01_17" ("guid");
CREATE INDEX "a01_17key2" ON "a01_17" ("docguid", "updatedate", "updatetime");
CREATE INDEX "a01_17key3" ON "a01_17" ("updatedate", "updatetime");
COMMENT ON TABLE "a01_17" IS '單據外部簽核記錄';
COMMENT ON COLUMN "a01_17"."guid" IS '流水編號';
COMMENT ON COLUMN "a01_17"."docguid" IS '文件GUID';
COMMENT ON COLUMN "a01_17"."signflag" IS '簽核註記';
COMMENT ON COLUMN "a01_17"."filelocatiion" IS '附件位置';
COMMENT ON COLUMN "a01_17"."content" IS '簽核內容';
COMMENT ON COLUMN "a01_17"."updatedate" IS '異動日期';
COMMENT ON COLUMN "a01_17"."updatetime" IS '異動時間';

-- EDB：單據留言板
CREATE TABLE "a01_18" (
    "serial_num" varchar(60) DEFAULT ' ' NOT NULL,
    "serial_num_seq" integer DEFAULT 0 NOT NULL,
    "emp_id" varchar(60) DEFAULT ' ' NOT NULL,
    "新增日期" char(8) DEFAULT '00000000' NOT NULL,
    "新增時間" char(6) DEFAULT '000000' NOT NULL,
    "產品編號" varchar(60) DEFAULT ' ' NOT NULL,
    "客戶編號" varchar(60) DEFAULT ' ' NOT NULL,
    "廠商編號" varchar(60) DEFAULT ' ' NOT NULL,
    "留言" text,
    "手繪" bytea
);
CREATE UNIQUE INDEX "a01_18key1" ON "a01_18" ("serial_num", "serial_num_seq");
CREATE INDEX "a01_18key2" ON "a01_18" ("serial_num", "emp_id", "新增日期", "新增時間");
CREATE INDEX "a01_18key3" ON "a01_18" ("產品編號", "新增日期", "新增時間");
CREATE INDEX "a01_18key4" ON "a01_18" ("客戶編號", "新增日期", "新增時間");
CREATE INDEX "a01_18key5" ON "a01_18" ("廠商編號", "新增日期", "新增時間");
COMMENT ON TABLE "a01_18" IS '單據留言板';
COMMENT ON COLUMN "a01_18"."serial_num" IS '流水編號';
COMMENT ON COLUMN "a01_18"."serial_num_seq" IS '表身序號';
COMMENT ON COLUMN "a01_18"."emp_id" IS '留言人ID';

-- EDB：單據變更日期
CREATE TABLE "a01_19" (
    "serial_num" varchar(60) DEFAULT ' ' NOT NULL,
    "PDF新增日期" char(8) DEFAULT '00000000' NOT NULL,
    "PDF新增時間" char(6) DEFAULT '000000' NOT NULL
);
CREATE UNIQUE INDEX "a01_19key1" ON "a01_19" ("serial_num");
CREATE INDEX "a01_19key2" ON "a01_19" ("PDF新增日期", "PDF新增時間");
COMMENT ON TABLE "a01_19" IS '單據變更日期';
COMMENT ON COLUMN "a01_19"."serial_num" IS '流水編號';

-- EDB：Translation
CREATE TABLE "a02" (
    "pagecode" varchar(5) DEFAULT ' ' NOT NULL,
    "localname" varchar(100) DEFAULT ' ' NOT NULL,
    "translateto" varchar(100) DEFAULT ' ' NOT NULL,
    PRIMARY KEY ("pagecode", "localname", "translateto")
);
COMMENT ON TABLE "a02" IS 'Translation';

-- EDB：SignHistory
CREATE TABLE "a03" (
    "empserialno" varchar(60) DEFAULT ' ' NOT NULL,
    "logondate" char(8) DEFAULT '00000000' NOT NULL,
    "logontime" char(6) DEFAULT '000000' NOT NULL,
    "ipaddr" varchar(30) DEFAULT ' ' NOT NULL,
    PRIMARY KEY ("empserialno")
);
COMMENT ON TABLE "a03" IS 'SignHistory';

-- EDB：TalkingStatus
CREATE TABLE "a04" (
    "serial_num" varchar(60) DEFAULT ' ' NOT NULL,
    "talkto" varchar(60) DEFAULT ' ' NOT NULL,
    "logondate" char(8) DEFAULT '00000000' NOT NULL,
    "time_" char(6) DEFAULT '000000' NOT NULL,
    "status" varchar(1) DEFAULT ' ' NOT NULL,
    PRIMARY KEY ("serial_num", "talkto")
);
COMMENT ON TABLE "a04" IS 'TalkingStatus';
COMMENT ON COLUMN "a04"."serial_num" IS 'MyID';
COMMENT ON COLUMN "a04"."time_" IS 'LogonTime';

-- EDB：LogonSetting
CREATE TABLE "a05" (
    "loginname" varchar(16) DEFAULT ' ' NOT NULL,
    "username" varchar(30) DEFAULT ' ' NOT NULL,
    "tempdir" varchar(100) DEFAULT ' ' NOT NULL,
    PRIMARY KEY ("loginname")
);
COMMENT ON TABLE "a05" IS 'LogonSetting';
COMMENT ON COLUMN "a05"."loginname" IS 'LoginID';

-- EDB：CntList
CREATE TABLE "a06" (
    "user_" varchar(16) DEFAULT ' ' NOT NULL,
    "ip" varchar(50) DEFAULT ' ' NOT NULL,
    "date_" char(8) DEFAULT '00000000' NOT NULL,
    "starttime" char(6) DEFAULT '000000' NOT NULL,
    "endtime" char(6) DEFAULT '000000' NOT NULL,
    "jobtype" varchar(50) DEFAULT ' ' NOT NULL,
    "instseqno" varchar(20) DEFAULT ' ' NOT NULL,
    PRIMARY KEY ("user_", "ip", "date_")
);
CREATE INDEX "a06key2" ON "a06" ("user_", "date_", "endtime");
COMMENT ON TABLE "a06" IS 'CntList';
COMMENT ON COLUMN "a06"."user_" IS 'User';
COMMENT ON COLUMN "a06"."date_" IS 'Date';

-- EDB：Tree Menu
CREATE TABLE "a07" (
    "node" smallint DEFAULT 0 NOT NULL,
    "parent" smallint DEFAULT 0 NOT NULL,
    "description" varchar(50) DEFAULT ' ' NOT NULL,
    "visiable" smallint DEFAULT 1 NOT NULL,
    "enable" smallint DEFAULT 1 NOT NULL,
    "accountsonly" smallint DEFAULT 0 NOT NULL,
    "programid" varchar(3) DEFAULT ' ' NOT NULL,
    "forall" smallint DEFAULT 0 NOT NULL,
    PRIMARY KEY ("parent", "node")
);
CREATE UNIQUE INDEX "a07key2" ON "a07" ("node");
COMMENT ON TABLE "a07" IS 'Tree Menu';

-- EDB：A10系統代碼
CREATE TABLE "a10" (
    "serial_num" varchar(60) DEFAULT ' ' NOT NULL,
    "codetype" varchar(30) DEFAULT ' ' NOT NULL,
    "codeid" varchar(30) DEFAULT ' ' NOT NULL,
    "codename" varchar(60) DEFAULT ' ' NOT NULL,
    "codepara" numeric(16,6) DEFAULT 0 NOT NULL,
    "reftype" varchar(30) DEFAULT ' ' NOT NULL,
    "guname" varchar(100) DEFAULT ' ' NOT NULL,
    PRIMARY KEY ("serial_num")
);
CREATE UNIQUE INDEX "a10_key2" ON "a10" ("codetype", "codeid");
COMMENT ON TABLE "a10" IS 'A10系統代碼';
COMMENT ON COLUMN "a10"."serial_num" IS '流水編號';
COMMENT ON COLUMN "a10"."codetype" IS '代碼類別';
COMMENT ON COLUMN "a10"."codeid" IS '代碼索引';
COMMENT ON COLUMN "a10"."codename" IS '代碼內容';
COMMENT ON COLUMN "a10"."codepara" IS '代碼系數';
COMMENT ON COLUMN "a10"."reftype" IS '參考類別';

-- EDB：A20元件註冊
CREATE TABLE "a20" (
    "serial_num" varchar(60) DEFAULT ' ' NOT NULL,
    "job_type" varchar(3) DEFAULT ' ' NOT NULL,
    "job_id" varchar(50) DEFAULT ' ' NOT NULL,
    "guname" varchar(50) DEFAULT ' ' NOT NULL,
    "job_description" varchar(200) DEFAULT ' ' NOT NULL,
    "query_fieldname_c" varchar(20) DEFAULT ' ' NOT NULL,
    "query_fieldname_e" varchar(20) DEFAULT ' ' NOT NULL,
    "rights_create_object" varchar(15) DEFAULT ' ' NOT NULL,
    "rights_modify_object" varchar(15) DEFAULT ' ' NOT NULL,
    "rights_delete_object" varchar(15) DEFAULT ' ' NOT NULL,
    "表單查詢權限" varchar(15) DEFAULT ' ' NOT NULL,
    "rights_excute_object" varchar(15) DEFAULT ' ' NOT NULL,
    "rights_print_object" varchar(15) DEFAULT ' ' NOT NULL,
    "visible" smallint DEFAULT 0 NOT NULL,
    "headcontrol" varchar(50) DEFAULT ' ' NOT NULL,
    "detailcontrol" varchar(50) DEFAULT ' ' NOT NULL,
    "產品庫存參數" smallint DEFAULT 0 NOT NULL,
    "應收參數" smallint DEFAULT 0 NOT NULL,
    "應付參數" smallint DEFAULT 0 NOT NULL,
    "材料銷貨參數" smallint DEFAULT 0 NOT NULL,
    "材料實際庫存" smallint DEFAULT 0 NOT NULL,
    "編碼方式" varchar(1) DEFAULT ' ' NOT NULL,
    "序號位數" smallint DEFAULT 3 NOT NULL,
    "產品庫存主檔" smallint DEFAULT 0 NOT NULL,
    "產品來源檔名" varchar(30) DEFAULT ' ' NOT NULL,
    "產品編號欄位" varchar(20) DEFAULT ' ' NOT NULL,
    "材料庫存主檔" smallint DEFAULT 0 NOT NULL,
    "iso" varchar(20) DEFAULT ' ' NOT NULL,
    "publicname" varchar(30) DEFAULT 'Main' NOT NULL,
    "ecffile" varchar(30) DEFAULT ' ' NOT NULL,
    "產品單頭或單身" smallint DEFAULT 0 NOT NULL,
    "材料單頭或單身" smallint DEFAULT 0 NOT NULL,
    "單據前置碼" varchar(4) DEFAULT ' ' NOT NULL,
    "表單類別" varchar(1) DEFAULT '1' NOT NULL,
    "庫存類別" varchar(1) DEFAULT ' ' NOT NULL,
    "流程獨立否" smallint DEFAULT 0 NOT NULL,
    "屬性大類名稱" varchar(60) DEFAULT ' ' NOT NULL,
    "屬性中類名稱" varchar(60) DEFAULT ' ' NOT NULL,
    "個人資料總灠" varchar(30) DEFAULT ' ' NOT NULL,
    "關帳" char(8) DEFAULT '00000000' NOT NULL,
    "startstatus" varchar(1) DEFAULT ' ' NOT NULL,
    "laststatus" varchar(1) DEFAULT ' ' NOT NULL,
    "同人合併" smallint DEFAULT 1 NOT NULL,
    "singature_header" varchar(100) DEFAULT ' ' NOT NULL,
    "加簽給自己" smallint DEFAULT 0 NOT NULL,
    "允許退簽" smallint DEFAULT 1 NOT NULL,
    "icons" bytea,
    PRIMARY KEY ("serial_num")
);
CREATE UNIQUE INDEX "a20key2" ON "a20" ("job_type");
CREATE UNIQUE INDEX "a20key3" ON "a20" ("job_id");
CREATE UNIQUE INDEX "a20key4" ON "a20" ("guname");
COMMENT ON TABLE "a20" IS 'A20元件註冊';
COMMENT ON COLUMN "a20"."serial_num" IS '流水編號';
COMMENT ON COLUMN "a20"."job_type" IS '表單代碼';
COMMENT ON COLUMN "a20"."job_id" IS '表單代號';
COMMENT ON COLUMN "a20"."guname" IS '表單名稱';
COMMENT ON COLUMN "a20"."job_description" IS '表單說明';
COMMENT ON COLUMN "a20"."query_fieldname_c" IS '查詢欄位_中文';
COMMENT ON COLUMN "a20"."query_fieldname_e" IS '查詢欄位_英文';
COMMENT ON COLUMN "a20"."rights_create_object" IS '表單新增權限';
COMMENT ON COLUMN "a20"."rights_modify_object" IS '表單修改權限';
COMMENT ON COLUMN "a20"."rights_delete_object" IS '表單刪除權限';
COMMENT ON COLUMN "a20"."rights_excute_object" IS '表單流灠權限';
COMMENT ON COLUMN "a20"."rights_print_object" IS '表單列印權限';
COMMENT ON COLUMN "a20"."visible" IS '免送簽核';
COMMENT ON COLUMN "a20"."材料銷貨參數" IS '材料虛擬庫存';
COMMENT ON COLUMN "a20"."產品庫存主檔" IS '淮許代理';
COMMENT ON COLUMN "a20"."產品來源檔名" IS '流程選項程式';
COMMENT ON COLUMN "a20"."產品編號欄位" IS '部門選項程式';
COMMENT ON COLUMN "a20"."材料庫存主檔" IS '可以更改單據流程';
COMMENT ON COLUMN "a20"."產品單頭或單身" IS '限定公司';
COMMENT ON COLUMN "a20"."材料單頭或單身" IS '限定部門';
COMMENT ON COLUMN "a20"."流程獨立否" IS '申請人免簽';
COMMENT ON COLUMN "a20"."屬性大類名稱" IS '部門選項';
COMMENT ON COLUMN "a20"."屬性中類名稱" IS '簽核後程式';
COMMENT ON COLUMN "a20"."個人資料總灠" IS '主檔名稱';
COMMENT ON COLUMN "a20"."關帳" IS '關帳日期';
COMMENT ON COLUMN "a20"."startstatus" IS '開始狀態';
COMMENT ON COLUMN "a20"."laststatus" IS '最後狀態';
COMMENT ON COLUMN "a20"."singature_header" IS '簽核抬頭';

-- EDB：A20元件流程
CREATE TABLE "a20_1" (
    "serial_num" varchar(60) DEFAULT ' ' NOT NULL,
    "compid" varchar(60) DEFAULT ' ' NOT NULL,
    "level_" integer DEFAULT 0 NOT NULL,
    "serial_num_seq" integer DEFAULT 0 NOT NULL,
    "指定人員" varchar(60) DEFAULT ' ' NOT NULL,
    "posiid" varchar(60) DEFAULT ' ' NOT NULL,
    "signorcc" smallint DEFAULT 1 NOT NULL,
    "bydept" smallint DEFAULT 0 NOT NULL,
    "bycomp" smallint DEFAULT 0 NOT NULL,
    "freesign" smallint DEFAULT 0 NOT NULL,
    "cndfile" varchar(30) DEFAULT ' ' NOT NULL,
    "cndfield" varchar(30) DEFAULT ' ' NOT NULL,
    "cndexpression" varchar(2) DEFAULT ' ' NOT NULL,
    "cndcontent" varchar(30) DEFAULT ' ' NOT NULL,
    "cndattribute" varchar(1) DEFAULT ' ' NOT NULL,
    "cndexpression2" varchar(2) DEFAULT ' ' NOT NULL,
    "cndcontent2" varchar(30) DEFAULT ' ' NOT NULL,
    "dataedit" varchar(30) DEFAULT ' ' NOT NULL,
    "addflow" smallint DEFAULT 0 NOT NULL,
    "assigncostdept" smallint DEFAULT 0 NOT NULL,
    "appdept" varchar(60) DEFAULT ' ' NOT NULL,
    "flowdept" varchar(60) DEFAULT ' ' NOT NULL,
    "會簽判定" smallint DEFAULT 0 NOT NULL,
    "會簽方式" varchar(1) DEFAULT '1' NOT NULL,
    "singature_line" integer DEFAULT 0 NOT NULL,
    "singature_seq" integer DEFAULT 0 NOT NULL,
    "加簽通知" smallint DEFAULT 0 NOT NULL,
    "recordid" varchar(60) DEFAULT ' ' NOT NULL
);
CREATE INDEX "a20_1key0" ON "a20_1" ("serial_num");
CREATE UNIQUE INDEX "a20_1key1" ON "a20_1" ("serial_num", "compid", "serial_num_seq");
CREATE INDEX "a20_1key2" ON "a20_1" ("serial_num", "compid", "posiid");
CREATE INDEX "a20_1key3" ON "a20_1" ("serial_num", "compid", "signorcc" DESC, "serial_num_seq");
COMMENT ON TABLE "a20_1" IS 'A20元件流程';
COMMENT ON COLUMN "a20_1"."serial_num" IS '流水編號';
COMMENT ON COLUMN "a20_1"."compid" IS '公司流水號';
COMMENT ON COLUMN "a20_1"."level_" IS '父階序號';
COMMENT ON COLUMN "a20_1"."serial_num_seq" IS '表身序號';
COMMENT ON COLUMN "a20_1"."posiid" IS '職稱代碼';
COMMENT ON COLUMN "a20_1"."signorcc" IS '正副本';
COMMENT ON COLUMN "a20_1"."bydept" IS '限定部門';
COMMENT ON COLUMN "a20_1"."bycomp" IS '指定欄位';
COMMENT ON COLUMN "a20_1"."freesign" IS '免簽';
COMMENT ON COLUMN "a20_1"."cndfile" IS '條件檔案';
COMMENT ON COLUMN "a20_1"."cndfield" IS '條件欄位';
COMMENT ON COLUMN "a20_1"."cndexpression" IS '條件式';
COMMENT ON COLUMN "a20_1"."cndcontent" IS '條件內容';
COMMENT ON COLUMN "a20_1"."cndattribute" IS '條件屬性';
COMMENT ON COLUMN "a20_1"."cndexpression2" IS '免簽條件式';
COMMENT ON COLUMN "a20_1"."cndcontent2" IS '免簽內容';
COMMENT ON COLUMN "a20_1"."dataedit" IS '內容修正';
COMMENT ON COLUMN "a20_1"."addflow" IS '可以加簽';
COMMENT ON COLUMN "a20_1"."assigncostdept" IS '設定成本';
COMMENT ON COLUMN "a20_1"."appdept" IS '限定申請部門';
COMMENT ON COLUMN "a20_1"."flowdept" IS '簽核部門欄位';
COMMENT ON COLUMN "a20_1"."singature_line" IS '簽名列號';
COMMENT ON COLUMN "a20_1"."singature_seq" IS '簽名序號';

-- EDB：A20元件取號
CREATE TABLE "a20_3" (
    "表單代碼" varchar(3) DEFAULT ' ' NOT NULL,
    "keygroup" varchar(20) DEFAULT ' ' NOT NULL,
    "nextno" integer DEFAULT 0 NOT NULL,
    "recordid" varchar(60) DEFAULT ' ' NOT NULL,
    PRIMARY KEY ("recordid")
);
CREATE INDEX "a20_3key1" ON "a20_3" ("表單代碼", "keygroup");
COMMENT ON TABLE "a20_3" IS 'A20元件取號';

-- EDB：A20元件參考
CREATE TABLE "a20_2" (
    "doccode" varchar(3) DEFAULT ' ' NOT NULL,
    "serial_num_seq" integer DEFAULT 0 NOT NULL,
    "itemname" varchar(30) DEFAULT ' ' NOT NULL,
    "publicname" varchar(30) DEFAULT ' ' NOT NULL,
    "recordid" varchar(60) DEFAULT ' ' NOT NULL,
    PRIMARY KEY ("recordid")
);
CREATE INDEX "a20_2key1" ON "a20_2" ("doccode", "serial_num_seq");
COMMENT ON TABLE "a20_2" IS 'A20元件參考';
COMMENT ON COLUMN "a20_2"."doccode" IS '表單代碼';
COMMENT ON COLUMN "a20_2"."serial_num_seq" IS '表身序號';
COMMENT ON COLUMN "a20_2"."itemname" IS '相關查詢';

-- EDB：A20元件自定欄位
CREATE TABLE "a20_4" (
    "doccode" varchar(3) DEFAULT ' ' NOT NULL,
    "serial_num_seq" integer DEFAULT 0 NOT NULL,
    "itemtype" varchar(4) DEFAULT ' ' NOT NULL,
    "itemcode" varchar(4) DEFAULT ' ' NOT NULL,
    "itemattribute" varchar(1) DEFAULT ' ' NOT NULL,
    "itemformat" varchar(20) DEFAULT ' ' NOT NULL,
    "借貸" smallint DEFAULT 0 NOT NULL,
    "科目代號" varchar(8) DEFAULT ' ' NOT NULL,
    "recordid" varchar(60) DEFAULT ' ' NOT NULL,
    PRIMARY KEY ("recordid")
);
CREATE INDEX "a20_4key1" ON "a20_4" ("doccode", "serial_num_seq");
CREATE UNIQUE INDEX "a20_4key2" ON "a20_4" ("doccode", "itemtype", "itemcode");
COMMENT ON TABLE "a20_4" IS 'A20元件自定欄位';
COMMENT ON COLUMN "a20_4"."doccode" IS '表單代碼';
COMMENT ON COLUMN "a20_4"."serial_num_seq" IS '表身序號';
COMMENT ON COLUMN "a20_4"."itemtype" IS '自定大類';
COMMENT ON COLUMN "a20_4"."itemcode" IS '自定細目';
COMMENT ON COLUMN "a20_4"."itemattribute" IS '屬性';
COMMENT ON COLUMN "a20_4"."itemformat" IS '格式';

-- EDB：A20元件執行
CREATE TABLE "a20_6" (
    "job_type" varchar(3) DEFAULT ' ' NOT NULL,
    "compid" varchar(60) DEFAULT ' ' NOT NULL,
    "serial_num_seq" integer DEFAULT 0 NOT NULL,
    "action" varchar(3) DEFAULT ' ' NOT NULL,
    "publicname" varchar(30) DEFAULT ' ' NOT NULL,
    "excutedby" varchar(60) DEFAULT ' ' NOT NULL,
    "enable" smallint DEFAULT 0 NOT NULL,
    "deptassigned" varchar(60) DEFAULT ' ' NOT NULL,
    "條件檔案" varchar(30) DEFAULT ' ' NOT NULL,
    "條件欄位" varchar(30) DEFAULT ' ' NOT NULL,
    "條件式" varchar(2) DEFAULT ' ' NOT NULL,
    "條件內容" varchar(30) DEFAULT ' ' NOT NULL,
    "條件屬性" varchar(1) DEFAULT ' ' NOT NULL,
    "processfor" varchar(60) DEFAULT ' ' NOT NULL,
    "手動確認" smallint DEFAULT 0 NOT NULL,
    "recordid" varchar(60) DEFAULT ' ' NOT NULL
);
CREATE UNIQUE INDEX "a20_6key1" ON "a20_6" ("job_type", "compid", "serial_num_seq");
CREATE UNIQUE INDEX "a20_6key2" ON "a20_6" ("recordid");
CREATE UNIQUE INDEX "a20_6key3" ON "a20_6" ("job_type", "compid", "action");
COMMENT ON TABLE "a20_6" IS 'A20元件執行';
COMMENT ON COLUMN "a20_6"."job_type" IS '表單代碼';
COMMENT ON COLUMN "a20_6"."compid" IS '公司流水號';
COMMENT ON COLUMN "a20_6"."serial_num_seq" IS '表身序號';
COMMENT ON COLUMN "a20_6"."action" IS '程序';
COMMENT ON COLUMN "a20_6"."publicname" IS '功能';
COMMENT ON COLUMN "a20_6"."excutedby" IS '執行者';
COMMENT ON COLUMN "a20_6"."enable" IS '啟用/關閉';
COMMENT ON COLUMN "a20_6"."deptassigned" IS '限定部門';
COMMENT ON COLUMN "a20_6"."processfor" IS '執行說明';

-- EDB：A20元件科目
CREATE TABLE "a20_5" (
    "job_type" varchar(3) DEFAULT ' ' NOT NULL,
    "serial_num_seq" integer DEFAULT 0 NOT NULL,
    "借貸" smallint DEFAULT 0 NOT NULL,
    "科目代號" varchar(8) DEFAULT ' ' NOT NULL,
    "參考欄位" varchar(30) DEFAULT ' ' NOT NULL,
    "recordid" varchar(60) DEFAULT ' ' NOT NULL
);
CREATE UNIQUE INDEX "a20_5key0" ON "a20_5" ("recordid");
CREATE UNIQUE INDEX "a20_5key1" ON "a20_5" ("job_type", "serial_num_seq");
COMMENT ON TABLE "a20_5" IS 'A20元件科目';
COMMENT ON COLUMN "a20_5"."job_type" IS '表單代碼';
COMMENT ON COLUMN "a20_5"."serial_num_seq" IS '表身序號';

-- EDB：A20元件階層
CREATE TABLE "a20_7" (
    "job_type" varchar(3) DEFAULT ' ' NOT NULL,
    "level_" integer DEFAULT 0 NOT NULL,
    "method" smallint DEFAULT 0 NOT NULL,
    "決議" varchar(1) DEFAULT '1' NOT NULL,
    "recordid" varchar(60) DEFAULT ' ' NOT NULL
);
CREATE UNIQUE INDEX "a20_7key1" ON "a20_7" ("recordid");
CREATE UNIQUE INDEX "a20_7key2" ON "a20_7" ("job_type", "level_");
COMMENT ON TABLE "a20_7" IS 'A20元件階層';
COMMENT ON COLUMN "a20_7"."job_type" IS '表單代碼';
COMMENT ON COLUMN "a20_7"."level_" IS '階層';
COMMENT ON COLUMN "a20_7"."method" IS '簽法';

-- EDB：A20元件簽核類別
CREATE TABLE "a20_8" (
    "job_type" varchar(3) DEFAULT ' ' NOT NULL,
    "類別代碼" varchar(2) NOT NULL,
    "說明" varchar(50) NOT NULL,
    "recordid" varchar(60) DEFAULT ' ' NOT NULL
);
CREATE UNIQUE INDEX "a20_8key0" ON "a20_8" ("recordid");
CREATE UNIQUE INDEX "a20_8key1" ON "a20_8" ("job_type", "類別代碼");
COMMENT ON TABLE "a20_8" IS 'A20元件簽核類別';
COMMENT ON COLUMN "a20_8"."job_type" IS '表單代碼';

-- EDB：A30群組成員
CREATE TABLE "a30_1" (
    "serial_num" varchar(60) DEFAULT ' ' NOT NULL,
    "serial_num_seq" integer DEFAULT 0 NOT NULL,
    "empserialno" varchar(60) DEFAULT ' ' NOT NULL,
    "recordid" varchar(60) DEFAULT ' ' NOT NULL,
    PRIMARY KEY ("recordid")
);
CREATE INDEX "a30_1key1" ON "a30_1" ("serial_num", "serial_num_seq");
CREATE UNIQUE INDEX "a30_1key2" ON "a30_1" ("serial_num", "empserialno");
CREATE UNIQUE INDEX "a30_1key3" ON "a30_1" ("empserialno", "serial_num");
COMMENT ON TABLE "a30_1" IS 'A30群組成員';
COMMENT ON COLUMN "a30_1"."serial_num" IS '群組識別碼';
COMMENT ON COLUMN "a30_1"."serial_num_seq" IS '表身序號';
COMMENT ON COLUMN "a30_1"."empserialno" IS '員工識別碼';

-- EDB：A30群組表單
CREATE TABLE "a30_2" (
    "serial_num" varchar(60) DEFAULT ' ' NOT NULL,
    "serial_num_seq" integer DEFAULT 0 NOT NULL,
    "docserialno" varchar(60) DEFAULT ' ' NOT NULL,
    "createflag" smallint DEFAULT 0 NOT NULL,
    "queryflag" smallint DEFAULT 0 NOT NULL,
    "printflag" smallint DEFAULT 0 NOT NULL,
    "amountflag" smallint DEFAULT 0 NOT NULL,
    "querylimited" smallint DEFAULT 0 NOT NULL,
    "recordid" varchar(60) DEFAULT ' ' NOT NULL,
    PRIMARY KEY ("recordid")
);
CREATE INDEX "a30_2key1" ON "a30_2" ("serial_num", "serial_num_seq");
CREATE UNIQUE INDEX "a30_2key2" ON "a30_2" ("serial_num", "docserialno");
COMMENT ON TABLE "a30_2" IS 'A30群組表單';
COMMENT ON COLUMN "a30_2"."serial_num" IS '群組識別碼';
COMMENT ON COLUMN "a30_2"."serial_num_seq" IS '表身序號';
COMMENT ON COLUMN "a30_2"."docserialno" IS '單據識別碼';
COMMENT ON COLUMN "a30_2"."createflag" IS '增修';
COMMENT ON COLUMN "a30_2"."queryflag" IS '查詢';
COMMENT ON COLUMN "a30_2"."printflag" IS '列印';
COMMENT ON COLUMN "a30_2"."amountflag" IS '金額';
COMMENT ON COLUMN "a30_2"."querylimited" IS '限定查詢';

-- EDB：A30群組歸屬
CREATE TABLE "a30_3" (
    "上階群組" varchar(60) DEFAULT ' ' NOT NULL,
    "下階群組" varchar(60) DEFAULT ' ' NOT NULL
);
CREATE UNIQUE INDEX "a30_3key1" ON "a30_3" ("上階群組", "下階群組");
COMMENT ON TABLE "a30_3" IS 'A30群組歸屬';

-- EDB：A35單位資料
CREATE TABLE "a35" (
    "serial_num" varchar(60) DEFAULT ' ' NOT NULL,
    "subdeptid" varchar(5) DEFAULT ' ' NOT NULL,
    "subdeptname" varchar(20) DEFAULT ' ' NOT NULL,
    "description" varchar(100) DEFAULT ' ' NOT NULL,
    "engname" varchar(20) DEFAULT ' ' NOT NULL,
    "groupid" varchar(60) DEFAULT ' ' NOT NULL,
    "guname" varchar(100) DEFAULT ' ' NOT NULL,
    PRIMARY KEY ("serial_num")
);
CREATE UNIQUE INDEX "a35key2" ON "a35" ("groupid", "subdeptid");
COMMENT ON TABLE "a35" IS 'A35單位資料';
COMMENT ON COLUMN "a35"."serial_num" IS '流水編號';
COMMENT ON COLUMN "a35"."subdeptid" IS '單位代碼';
COMMENT ON COLUMN "a35"."subdeptname" IS '單位名稱';
COMMENT ON COLUMN "a35"."description" IS '單位說明';
COMMENT ON COLUMN "a35"."engname" IS '英文名稱';
COMMENT ON COLUMN "a35"."groupid" IS '所屬部門';

-- EDB：A70作業程序
CREATE TABLE "a70" (
    "serial_num" varchar(60) DEFAULT ' ' NOT NULL,
    "作業代碼" varchar(12) DEFAULT ' ' NOT NULL,
    "作業名稱" varchar(60) DEFAULT ' ' NOT NULL,
    "作業說明" varchar(256) DEFAULT ' ' NOT NULL,
    "用於表單" varchar(3) DEFAULT ' ' NOT NULL
);
CREATE UNIQUE INDEX "a70key1" ON "a70" ("serial_num");
CREATE UNIQUE INDEX "a70key2" ON "a70" ("用於表單", "作業代碼");
CREATE UNIQUE INDEX "a70key3" ON "a70" ("作業名稱");
COMMENT ON TABLE "a70" IS 'A70作業程序';
COMMENT ON COLUMN "a70"."serial_num" IS '流水編號';

-- EDB：A70作業明細
CREATE TABLE "a70_1" (
    "流水編號" varchar(60) DEFAULT ' ' NOT NULL,
    "表身序號" integer DEFAULT 0 NOT NULL,
    "表單代碼" varchar(3) DEFAULT ' ' NOT NULL,
    "recordid" varchar(60) DEFAULT ' ' NOT NULL
);
CREATE UNIQUE INDEX "a70_1key0" ON "a70_1" ("recordid");
CREATE UNIQUE INDEX "a70_1key1" ON "a70_1" ("流水編號", "表身序號");
COMMENT ON TABLE "a70_1" IS 'A70作業明細';

-- EDB：公告記錄
CREATE TABLE "a80" (
    "serial_num" varchar(60) DEFAULT ' ' NOT NULL,
    "createdby" varchar(60) DEFAULT ' ' NOT NULL,
    "applyby" varchar(60) DEFAULT ' ' NOT NULL,
    "itemno" varchar(50) DEFAULT ' ' NOT NULL,
    "guname" varchar(256) DEFAULT ' ' NOT NULL,
    "description" varchar(256) DEFAULT ' ' NOT NULL,
    "issuedate" char(8) DEFAULT '00000000' NOT NULL,
    "enddate" char(8) DEFAULT '00000000' NOT NULL,
    "issuetime" char(6) DEFAULT '000000' NOT NULL,
    "type" smallint DEFAULT 0 NOT NULL,
    PRIMARY KEY ("serial_num")
);
CREATE INDEX "a80key2" ON "a80" ("issuedate", "serial_num");
COMMENT ON TABLE "a80" IS '公告記錄';
COMMENT ON COLUMN "a80"."serial_num" IS '流水編號';
COMMENT ON COLUMN "a80"."createdby" IS '填單人';
COMMENT ON COLUMN "a80"."applyby" IS '製單人';
COMMENT ON COLUMN "a80"."itemno" IS '字號';
COMMENT ON COLUMN "a80"."guname" IS '主旨';
COMMENT ON COLUMN "a80"."description" IS '說明';
COMMENT ON COLUMN "a80"."issuedate" IS '公告日期';
COMMENT ON COLUMN "a80"."enddate" IS '公告結束日期';
COMMENT ON COLUMN "a80"."issuetime" IS '通知時間';
COMMENT ON COLUMN "a80"."type" IS '通知/公告';

-- EDB：通知對象
CREATE TABLE "a80_1" (
    "serial_num" varchar(60) DEFAULT ' ' NOT NULL,
    "messageto" varchar(60) DEFAULT ' ' NOT NULL,
    "calserialno" varchar(60) DEFAULT ' ' NOT NULL,
    "notifytype" varchar(1) DEFAULT 'Q' NOT NULL,
    "createdate" char(8) DEFAULT '00000000' NOT NULL,
    "createtime" char(6) DEFAULT '000000' NOT NULL,
    "ending" smallint DEFAULT 0 NOT NULL,
    "notified" smallint DEFAULT 0 NOT NULL,
    PRIMARY KEY ("serial_num", "messageto")
);
CREATE INDEX "a80_1key2" ON "a80_1" ("calserialno");
COMMENT ON TABLE "a80_1" IS '通知對象';
COMMENT ON COLUMN "a80_1"."serial_num" IS '流水編號';
COMMENT ON COLUMN "a80_1"."messageto" IS '收訊人';
COMMENT ON COLUMN "a80_1"."calserialno" IS '行事曆編號';
COMMENT ON COLUMN "a80_1"."notifytype" IS '類型';
COMMENT ON COLUMN "a80_1"."createdate" IS '日期';
COMMENT ON COLUMN "a80_1"."createtime" IS '時間';
COMMENT ON COLUMN "a80_1"."ending" IS '結案';
COMMENT ON COLUMN "a80_1"."notified" IS '已通知';

-- EDB：匯率資料
CREATE TABLE "a90" (
    "serial_num" varchar(60) DEFAULT ' ' NOT NULL,
    "幣別" varchar(4) DEFAULT ' ' NOT NULL,
    "更正日期" char(8) DEFAULT '00000000' NOT NULL,
    "匯率" numeric(7,4) DEFAULT 0 NOT NULL,
    "小數位" smallint DEFAULT 0 NOT NULL,
    "guname" varchar(4) DEFAULT ' ' NOT NULL
);
CREATE UNIQUE INDEX "a90key1" ON "a90" ("serial_num");
CREATE UNIQUE INDEX "a90key2" ON "a90" ("幣別", "更正日期");
COMMENT ON TABLE "a90" IS '匯率資料';
COMMENT ON COLUMN "a90"."serial_num" IS '流水編號';

-- EDB：倉庫資料
CREATE TABLE "aa0" (
    "serial_num" varchar(60) DEFAULT ' ' NOT NULL,
    "whid" varchar(5) DEFAULT ' ' NOT NULL,
    "whname" varchar(20) DEFAULT ' ' NOT NULL,
    "description" varchar(100) DEFAULT ' ' NOT NULL,
    "whename" varchar(20) DEFAULT ' ' NOT NULL,
    "companyid" varchar(60) DEFAULT ' ' NOT NULL,
    "guname" varchar(100) DEFAULT ' ' NOT NULL,
    PRIMARY KEY ("serial_num")
);
CREATE UNIQUE INDEX "aa0key2" ON "aa0" ("whid");
CREATE INDEX "aa0key3" ON "aa0" ("companyid", "whid");
COMMENT ON TABLE "aa0" IS '倉庫資料';
COMMENT ON COLUMN "aa0"."serial_num" IS '流水編號';
COMMENT ON COLUMN "aa0"."whid" IS '倉庫代碼';
COMMENT ON COLUMN "aa0"."whname" IS '倉庫名稱';
COMMENT ON COLUMN "aa0"."description" IS '倉庫說明';
COMMENT ON COLUMN "aa0"."whename" IS '英文名稱';
COMMENT ON COLUMN "aa0"."companyid" IS '所屬公司';

-- EDB：訊息記錄
CREATE TABLE "messages" (
    "serial_num" varchar(60) DEFAULT ' ' NOT NULL,
    "createby" varchar(60) DEFAULT ' ' NOT NULL,
    "messageto" varchar(60) DEFAULT ' ' NOT NULL,
    "formessage" varchar(60) DEFAULT ' ' NOT NULL,
    "refdocument" varchar(60) DEFAULT ' ' NOT NULL,
    "類型" varchar(1) DEFAULT 'Q' NOT NULL,
    "createdate" char(8) DEFAULT '00000000' NOT NULL,
    "createtime" char(6) DEFAULT '000000' NOT NULL,
    "ending" smallint DEFAULT 0 NOT NULL,
    "message" text,
    "attachedaction" varchar(1) DEFAULT ' ' NOT NULL,
    "notified" smallint DEFAULT 0 NOT NULL,
    "imflag" smallint DEFAULT 0 NOT NULL,
    "attacheddocid" varchar(60) DEFAULT ' ' NOT NULL,
    "enddate" char(8) DEFAULT '00000000' NOT NULL,
    "endtime" char(6) DEFAULT '000000' NOT NULL,
    "invaliddate" char(8) DEFAULT '00000000' NOT NULL,
    PRIMARY KEY ("serial_num")
);
CREATE INDEX "mesgkey2" ON "messages" ("createby", "imflag", "createdate", "createtime", "serial_num");
CREATE INDEX "mesgkey3" ON "messages" ("messageto", "imflag", "createdate", "createtime", "serial_num");
CREATE INDEX "mesgkey4" ON "messages" ("refdocument", "createdate", "createtime");
CREATE INDEX "mesgkey5" ON "messages" ("formessage", "createby");
CREATE INDEX "mesgkey6" ON "messages" ("ending", "createdate", "createtime");
CREATE INDEX "mesgkey7" ON "messages" ("notified", "createdate" DESC, "createtime" DESC);
COMMENT ON TABLE "messages" IS '訊息記錄';
COMMENT ON COLUMN "messages"."serial_num" IS '流水編號';
COMMENT ON COLUMN "messages"."createby" IS '發訊人';
COMMENT ON COLUMN "messages"."messageto" IS '收訊人';
COMMENT ON COLUMN "messages"."formessage" IS '來源訊息';
COMMENT ON COLUMN "messages"."refdocument" IS '相關單據';
COMMENT ON COLUMN "messages"."createdate" IS '日期';
COMMENT ON COLUMN "messages"."createtime" IS '時間';
COMMENT ON COLUMN "messages"."ending" IS '讀取否？';
COMMENT ON COLUMN "messages"."message" IS '訊息內容';
COMMENT ON COLUMN "messages"."notified" IS '已通知';
COMMENT ON COLUMN "messages"."imflag" IS '列入IM清單';
COMMENT ON COLUMN "messages"."attacheddocid" IS '附件流水編號';
COMMENT ON COLUMN "messages"."enddate" IS '讀取日期';
COMMENT ON COLUMN "messages"."endtime" IS '讀取時間';
COMMENT ON COLUMN "messages"."invaliddate" IS '截止日期';

-- EDB：IM連絡人
CREATE TABLE "imcontact" (
    "myid" varchar(60) DEFAULT ' ' NOT NULL,
    "contactid" varchar(60) DEFAULT ' ' NOT NULL,
    PRIMARY KEY ("myid", "contactid")
);
COMMENT ON TABLE "imcontact" IS 'IM連絡人';

-- EDB：CtxCheckList
CREATE TABLE "ctxchecklist" (
    "ctxid" varchar(60) DEFAULT ' ' NOT NULL,
    "lastdate" char(8) DEFAULT '00000000' NOT NULL,
    "lasttime" char(6) DEFAULT '000000' NOT NULL,
    PRIMARY KEY ("ctxid")
);
COMMENT ON TABLE "ctxchecklist" IS 'CtxCheckList';

-- EDB：User Logins
CREATE TABLE "user_logins" (
    "uniqueid_usr" varchar(60) DEFAULT ' ' NOT NULL,
    "userid_usr" varchar(20) DEFAULT ' ' NOT NULL,
    "name_usr" varchar(20) DEFAULT ' ' NOT NULL,
    "status_usr" varchar(1) DEFAULT 'A' NOT NULL,
    "password_usr" varchar(20) DEFAULT ' ' NOT NULL,
    "numgroups_usr" smallint NOT NULL,
    "numrights_usr" smallint NOT NULL,
    "defaultapp" smallint DEFAULT 1 NOT NULL,
    "otherinformation" varchar(300) DEFAULT ' ' NOT NULL,
    "desktoptype" smallint DEFAULT 0 NOT NULL,
    PRIMARY KEY ("uniqueid_usr")
);
COMMENT ON TABLE "user_logins" IS 'User Logins';
COMMENT ON COLUMN "user_logins"."otherinformation" IS 'OtherInformation_USR';

-- EDB：User Rights
CREATE TABLE "user_rights" (
    "parent_id_rght" varchar(20) DEFAULT ' ' NOT NULL,
    "unique_id_rgt" varchar(20) DEFAULT ' ' NOT NULL,
    "user_id" varchar(20) DEFAULT ' ' NOT NULL,
    "right_rgt" varchar(30) DEFAULT ' ' NOT NULL,
    PRIMARY KEY ("parent_id_rght", "unique_id_rgt")
);
CREATE INDEX "userrithskey2" ON "user_rights" ("user_id", "right_rgt");
COMMENT ON TABLE "user_rights" IS 'User Rights';
COMMENT ON COLUMN "user_rights"."parent_id_rght" IS 'Parent_ID_RGT';
COMMENT ON COLUMN "user_rights"."unique_id_rgt" IS 'Unique ID_RGT';
COMMENT ON COLUMN "user_rights"."user_id" IS 'User ID_RGT';

-- EDB：User Groups
CREATE TABLE "user_groups" (
    "parent_id_grp" varchar(20) DEFAULT ' ' NOT NULL,
    "unique_id_rgt" varchar(20) DEFAULT ' ' NOT NULL,
    "user_id" varchar(20) DEFAULT ' ' NOT NULL,
    "right_rgt" varchar(30) DEFAULT ' ' NOT NULL,
    PRIMARY KEY ("parent_id_grp", "unique_id_rgt")
);
CREATE INDEX "usergroupskey2" ON "user_groups" ("user_id", "right_rgt");
COMMENT ON TABLE "user_groups" IS 'User Groups';
COMMENT ON COLUMN "user_groups"."parent_id_grp" IS 'Parent ID_GRP';
COMMENT ON COLUMN "user_groups"."unique_id_rgt" IS 'Unique ID_GRP';
COMMENT ON COLUMN "user_groups"."user_id" IS 'User ID_GRP';
COMMENT ON COLUMN "user_groups"."right_rgt" IS 'Group_GRP';

-- EDB：User_Modules
CREATE TABLE "user_modules" (
    "uniqueid_usr" varchar(40) NOT NULL,
    "seq_no" integer NOT NULL,
    "modulename" varchar(20) NOT NULL,
    "ecf" varchar(50) NOT NULL,
    "publicname" varchar(20) NOT NULL
);
CREATE UNIQUE INDEX "user_modulekey1" ON "user_modules" ("uniqueid_usr", "seq_no");
COMMENT ON TABLE "user_modules" IS 'User_Modules';

-- EDB：Calendar
CREATE TABLE "calendar" (
    "userid" varchar(40) DEFAULT ' ' NOT NULL,
    "serialno" varchar(40) DEFAULT ' ' NOT NULL,
    "subject" varchar(128) DEFAULT ' ' NOT NULL,
    "place" varchar(128) DEFAULT ' ' NOT NULL,
    "datefrom" char(8) DEFAULT '00000000' NOT NULL,
    "dateto" char(8) DEFAULT '00000000' NOT NULL,
    "timefrom" char(6) DEFAULT '000000' NOT NULL,
    "timeto" char(6) DEFAULT '000000' NOT NULL,
    "content" varchar(256) DEFAULT ' ' NOT NULL,
    "completed" smallint DEFAULT 0 NOT NULL,
    "flag" smallint NOT NULL,
    "fromserialno" varchar(40) DEFAULT ' ' NOT NULL
);
CREATE UNIQUE INDEX "CalKey1%EntryID%" ON "calendar" ("serialno");
CREATE INDEX "CalKey2%EntryID%" ON "calendar" ("userid", "datefrom", "timefrom");
CREATE INDEX "CalKey3%EntryID%" ON "calendar" ("userid", "completed", "datefrom", "timefrom");
COMMENT ON TABLE "calendar" IS 'Calendar';
COMMENT ON COLUMN "calendar"."flag" IS 'Level';

-- EDB：CalSeqNo
CREATE TABLE "calendarsn" (
    "date_" char(8) DEFAULT '00000000' NOT NULL,
    "seqno" smallint NOT NULL
);
CREATE UNIQUE INDEX "SNOKey1%EntryID%" ON "calendarsn" ("date_");
COMMENT ON TABLE "calendarsn" IS 'CalSeqNo';
COMMENT ON COLUMN "calendarsn"."date_" IS 'CalDate';

-- EDB：CalTZData
CREATE TABLE "calendartz" (
    "userid" varchar(40) DEFAULT ' ' NOT NULL,
    "date_" char(8) DEFAULT '00000000' NOT NULL,
    "time" char(6) DEFAULT '000000' NOT NULL,
    "zdata" varchar(2048) DEFAULT ' ' NOT NULL
);
CREATE UNIQUE INDEX "CalTZKey1%EntryID%" ON "calendartz" ("userid", "date_", "time");
COMMENT ON TABLE "calendartz" IS 'CalTZData';
COMMENT ON COLUMN "calendartz"."date_" IS 'Date';

-- EDB：CalTimeLine
CREATE TABLE "caltimeline" (
    "time" char(6) DEFAULT '000000' NOT NULL,
    "endtime" char(6) DEFAULT '000000' NOT NULL
);
CREATE UNIQUE INDEX "cltlkey1" ON "caltimeline" ("time", "endtime");
COMMENT ON TABLE "caltimeline" IS 'CalTimeLine';
COMMENT ON COLUMN "caltimeline"."time" IS 'StartTime';

-- EDB：CalendarTemp
CREATE TABLE "calendartemp" (
    "userid" varchar(40) DEFAULT ' ' NOT NULL,
    "serialno" varchar(40) DEFAULT ' ' NOT NULL,
    "subject" varchar(128) DEFAULT ' ' NOT NULL,
    "place" varchar(128) DEFAULT ' ' NOT NULL,
    "datefrom" char(8) DEFAULT '00000000' NOT NULL,
    "dateto" char(8) DEFAULT '00000000' NOT NULL,
    "timefrom" char(6) DEFAULT '000000' NOT NULL,
    "timeto" char(6) DEFAULT '000000' NOT NULL,
    "content" varchar(256) DEFAULT ' ' NOT NULL,
    "completed" smallint DEFAULT 0 NOT NULL,
    "flag" smallint NOT NULL,
    "status" smallint DEFAULT 0 NOT NULL,
    "createdate" char(8) DEFAULT '00000000' NOT NULL,
    "createtime" char(6) DEFAULT '000000' NOT NULL,
    "processed" smallint DEFAULT 0 NOT NULL,
    "fromserialno" varchar(40) DEFAULT ' ' NOT NULL
);
CREATE UNIQUE INDEX "calkeymain" ON "calendartemp" ("serialno");
CREATE INDEX "calkey1temp" ON "calendartemp" ("userid", "createdate", "createtime");
CREATE INDEX "caltempkey2" ON "calendartemp" ("processed", "userid", "createdate", "createtime");
COMMENT ON TABLE "calendartemp" IS 'CalendarTemp';
COMMENT ON COLUMN "calendartemp"."flag" IS 'Level';
COMMENT ON COLUMN "calendartemp"."status" IS 'Create/Delete';

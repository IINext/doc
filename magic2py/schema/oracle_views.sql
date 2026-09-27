-- 由 magic_views.py 抽出的 Oracle View 定義（每個 View 最後修改的版本），請勿手動修改

-- Oracle user_views
CREATE VIEW "IEWFILF015" ("工站代碼", "製令單號", "填表日") AS (
SELECT 
	D.工站代碼,	
	E.廠客品號 製令單號,
	min(C.填表日) 填表日
FROM 
	FIL0041 A 
	INNER JOIN FIL0040 E ON A.單別 = E.單據類別 AND A.單號 = E.單據編號 AND A.序號 = E.單據序號
	INNER JOIN FIL0030 C ON A.單別 = C.單據類別 AND A.單號 = C.單據編號
	INNER JOIN FIL0031 D ON A.單別 = D.單別 AND A.單號 = D.單號
WHERE
	A.單別 = 'F11'
GROUP BY 
	D.工站代碼,	
	E.廠客品號);

-- Oracle user_views
CREATE VIEW "VIEWA01_19_01" ("SERIAL_NUM", "主檔異動日時", "PDF新增日時") AS (                                                                                                                                                SELECT 
	A.Serial_Num,
	trim(A.異動日期)||trim(A.異動時間) 主檔異動日時,
	nvl(trim(B.PDF新增日期),' ')||nvl(trim(B.PDF新增時間),' ') PDF新增日時
FROM 
	A01 A
	Left JOIN A01_19 B ON A.Serial_Num= B.Serial_Num);

-- Oracle user_views
CREATE VIEW "VIEWDOC_KMTREE" ("OBJID", "CATEGORY", "NODEID", "SUBJECT", "USER_", "OPEN2TRAN") AS ( 
SELECT 	
	DOC_KMTree.ObjID,  
	DOC_KMTree.Category, 
	DOC_KMTree.NodeID,
	DOC_KMTree.Subject, 
	DOC_KMCategory.User_,
	DOC_KMTree.Open2Tran
FROM  
	DOC_KMTree, 
	DOC_KMCategory 
WHERE 
	DOC_KMTree.Category = DOC_KMCategory.Category
);

-- Oracle user_views
CREATE VIEW "VIEWDOC_OBJPATH" ("CATEGORY", "NODEID", "PATH") AS ( 
SELECT 	Distinct
	M.Category,
	M.NodeID,
	(SELECT 
		SYS_CONNECT_BY_PATH(A.Subject,'．') AS Path
		FROM  (SELECT NodeID,Subject,ParentID,Category From DOC_KMTree Where Category=M.Category) A
		WHERE A.Category=M.Category AND A.NodeID=M.NodeID
		START WITH A.ParentID=' '
		CONNECT BY PRIOR A.NodeID = A.ParentID) Path
From DOC_KMTree M

);

-- Oracle user_views
CREATE VIEW "VIEWDOC_OWNERTOTALSIZE" ("USERID", "TOTALSIZE", "ALLOWSIZE", "ALLOWCATEGORY", "ALLOWNODE", "ALLOWDOC") AS ( 
SELECT 	DOC_AllowedSize.UserID, 
		Round(sum(nvl(DOC_DocByTool.BlobSize,0))/1000000,2) TotalSize,
		avg(nvl(DOC_AllowedSize.AllowedSize,0)) AllowSize,
		max(nvl(DOC_AllowedSize.AllowCategory,0)) AllowCategory,
		max(nvl(DOC_AllowedSize.AllowNode,0)) AllowNode,
		max(nvl(DOC_AllowedSize.AllowDoc,0)) AllowDoc	
FROM  	DOC_AllowedSize
LEFT JOIN DOC_DocByTool ON DOC_DocByTool.CreatedBy= DOC_AllowedSize.UserID AND DOC_DocByTool.Category<>' ' 
GROUP BY  DOC_AllowedSize.UserID
);

-- Oracle user_views
CREATE VIEW "VIEWDOC_SHAREFOLDER" ("CREATEDBY", "PARENTID", "文件夾", "USERID") AS ( 
SELECT  Distinct 
	CAST(' ' as nvarchar2(100)) CreatedBy, 
	CAST(' ' as nvarchar2(100)) ParentID, 
	CAST('分享文件' as nvarchar2(100)) 文件夾,
	A.UserID
FROM	
	ViewDoc_UserRights A
	Inner Join DOC_DocByTool B On A.ObjID=B.OBJID and B.Deleted=0
	Inner Join DOC_KMTree C On B.Category=C.Category and B.NodeID=C.NodeID
	Inner Join DOC_JobStatus D On A.ObjID=D.ObjID and D.Status='U'

UNION ALL

SELECT  Distinct 
	CAST('分享文件' as nvarchar2(100)) CreatedBy,
	CAST('分享文件' as nvarchar2(100)) ParentID, 	
	CAST(nvl(E.員工姓名,B.CreatedBy) as nvarchar2(100)) 文件夾,
	A.UserID
FROM	
	ViewDoc_UserRights A
	Inner Join DOC_DocByTool B On A.ObjID=B.OBJID and B.Deleted=0
	Inner Join DOC_KMTree C On B.Category=C.Category and B.NodeID=C.NodeID
	Inner Join DOC_JobStatus D On A.ObjID=D.ObjID and D.Status='U'
	Left Join ViewFil1010 E On B.CreatedBy=E.員工編號

UNION ALL

SELECT	Distinct  
	CAST(nvl(E.員工姓名,B.CreatedBy) as nvarchar2(100)) CreatedBy, 
	CAST(nvl(E.員工姓名,B.CreatedBy) as nvarchar2(100)) ParentID, 
	CAST(B.Category||'#'||substr(B.NodeID,1,2) as nvarchar2(100)) 文件夾,
	A.UserID
FROM 
	ViewDoc_UserRights A 
	Inner Join DOC_DocByTool B On A.ObjID=B.OBJID and B.Deleted=0
	Inner Join DOC_JobStatus D On A.ObjID=D.ObjID and D.Status='U'
	Left Join ViewFil1010 E On B.CreatedBy=E.員工編號

UNION ALL

SELECT	Distinct  
	CAST(nvl(E.員工姓名,B.CreatedBy) as nvarchar2(100)) CreatedBy,
	CAST(B.Category||'#'||substr(B.NodeID,1,2) as nvarchar2(100)) ParentID, 
	CAST(B.Category||'#'||substr(B.NodeID,1,5) as nvarchar2(100)) 文件夾,
	A.UserID
FROM 
	ViewDoc_UserRights A 
	Inner Join DOC_DocByTool B On A.ObjID=B.OBJID and B.Deleted=0
	Inner Join DOC_JobStatus D On A.ObjID=D.ObjID and D.Status='U'
	Left Join ViewFil1010 E On B.CreatedBy=E.員工編號	
WHERE
	LENGTH(trim(B.NodeID))>2
	
UNION ALL

SELECT	Distinct  
	CAST(nvl(E.員工姓名,B.CreatedBy) as nvarchar2(100)) CreatedBy,
	CAST(B.Category||'#'||substr(B.NodeID,1,5) as nvarchar2(100)) ParentID, 
	CAST(B.Category||'#'||substr(B.NodeID,1,8) as nvarchar2(100)) 文件夾,
	A.UserID
FROM 
	ViewDoc_UserRights A 
	Inner Join DOC_DocByTool B On A.ObjID=B.OBJID and B.Deleted=0
	Inner Join DOC_JobStatus D On A.ObjID=D.ObjID and D.Status='U'
	Left Join ViewFil1010 E On B.CreatedBy=E.員工編號	
WHERE
	LENGTH(trim(B.NodeID))>5
	

UNION ALL

SELECT	Distinct  
	CAST(nvl(E.員工姓名,B.CreatedBy) as nvarchar2(100)) CreatedBy,
	CAST(B.Category||'#'||substr(B.NodeID,1,8) as nvarchar2(100)) ParentID, 
	CAST(B.Category||'#'||B.NodeID as nvarchar2(100)) 文件夾,
	A.UserID
FROM 
	ViewDoc_UserRights A 
	Inner Join DOC_DocByTool B On A.ObjID=B.OBJID and B.Deleted=0
	Inner Join DOC_JobStatus D On A.ObjID=D.ObjID and D.Status='U'
	Left Join ViewFil1010 E On B.CreatedBy=E.員工編號
WHERE
	LENGTH(trim(B.NodeID))>8	
);

-- Oracle user_views
CREATE VIEW "VIEWDOC_SHAREOBJ" ("文件夾", "USERID", "OBJID", "讀取", "修改", "刪除") AS ( 


SELECT 
	CAST(B.CreatedBy||'.'||C.Subject  as varchar2(50)) 文件夾,
	A.UserID,
	A.ObjID,
	A.Read_ 讀取,
	A.Modify_ 修改,
	A.Delete_ 刪除
FROM 
	ViewDoc_UserRights A 
	Inner Join DOC_DocByTool B On A.ObjID=B.OBJID and B.Deleted=0 
	Inner Join DOC_KMTree C On B.Category=C.Category and B.NodeID=C.NodeID
	Inner Join DOC_JobStatus D On A.ObjID=D.ObjID and D.Status='U'
);

-- Oracle user_views
CREATE VIEW "VIEWDOC_USERRIGHTS" ("USERID", "OBJID", "READ_", "MODIFY_", "DELETE_") AS ( 
SELECT 	A.UserID,
	A.ObjID,
	Decode(sum(A.Read_),0,0,1) Read_, 
	Decode(sum(A.Modify_),0,0,1) Modify_, 
	Decode(sum(A.Delete_),0,0,1) Delete_
From	
	
	/*群組分享文件*/
	(
	SELECT 
		A.UserID, 
		B.ObjID, 
		Decode(sum(B.Read_),0,0,1) Read_, 
		Decode(sum(B.Modify_),0,0,1) Modify_, 
		Decode(sum(B.Delete_),0,0,1) Delete_
	FROM   
		DOC_GroupUsers A
		Inner Join DOC_GroupObj B On A.GroupID= B.GroupID
		INNER JOIN DOC_DocByTool Z ON B.ObjID=Z.ObjID
	Group by 
		A.UserID, 
		B.ObjID

	union all

	/*個人分享文件*/
	SELECT
		A.UserID,
		A.ObjID,
		A.Read_,
		A.Modify_,
		A.Delete_
	From
		DOC_UserObj A
		INNER JOIN DOC_DocByTool Z ON A.ObjID=Z.ObjID

	union all

	/*群組分享頁籤*/
	SELECT 
		A.UserID, 
		Z.ObjID, 
		Decode(sum(B.Read_),0,0,1) Read_, 
		Decode(sum(B.Modify_),0,0,1) Modify_, 
		Decode(sum(B.Delete_),0,0,1) Delete_
	FROM   
		DOC_GroupUsers A
		Inner Join DOC_GroupObj B On A.GroupID= B.GroupID 
		INNER Join DOC_KMCategory Y On B.ObjID=Y.Category
		INNER JOIN DOC_DocByTool Z ON Y.Category=Z.Category
	Group by 
		A.UserID, 
		Z.ObjID
	
	union all

	/*個人分享頁籤*/
	SELECT
		A.UserID,
		Z.ObjID,
		A.Read_,
		A.Modify_,
		A.Delete_
	From
		DOC_UserObj A
		INNER Join DOC_KMCategory Y On A.ObjID=Y.Category
		INNER JOIN DOC_DocByTool Z ON Y.Category=Z.Category

	union all

	/*群組分享資料夾*/
	SELECT 
		A.UserID, 
		Z.ObjID, 
		Decode(sum(B.Read_),0,0,1) Read_, 
		Decode(sum(B.Modify_),0,0,1) Modify_, 
		Decode(sum(B.Delete_),0,0,1) Delete_
	FROM   
		DOC_GroupUsers A
		Inner Join DOC_GroupObj B On A.GroupID= B.GroupID 
		INNER JOIN DOC_KMTree Y ON B.ObjID=Y.ObjID
		INNER JOIN DOC_DocByTool Z ON Y.Category=Z.Category AND Z.NodeID like rtrim(Y.NodeID)||'%'
	Group by 
		A.UserID, 
		Z.ObjID
	
	union all

	/*個人分享資料夾*/
	SELECT
		A.UserID,
		Z.ObjID,
		A.Read_,
		A.Modify_,
		A.Delete_
	From
		DOC_UserObj A
		INNER JOIN DOC_KMTree Y ON A.ObjID=Y.ObjID
		INNER JOIN DOC_DocByTool Z ON Y.Category=Z.Category AND Z.NodeID like rtrim(Y.NodeID)||'%'
	) A
	

GROUP BY 
	A.UserID,
	A.ObjID
);

-- Oracle user_views
CREATE VIEW "VIEWFIL0010" ("員工編號", "員工姓名", "序號", "父階", "子階", "NODE", "說明", "CABINET", "PUBLICNAME", "啟用", "隱藏", "不需授權", "權限組合", "單據類別", "流程代碼", "特殊管制", "人事管制", "權限", "最後更新者", "最後更新日", "使用者隱藏", "獨立執行", "密碼執行") AS (                                                                                                                                                              SELECT 
	A.員工編號, 
	A.員工姓名, 
	A.序號, 
	A.父階, 
	A.子階, 
	A.Node, 
	A.說明,
	A.Cabinet, 
	A.PublicName, 
	A.啟用, 
	A.隱藏, 
	A.不需授權, 
	A.權限組合,
	A.單據類別, 
	A.流程代碼,
	A.特殊管制,
	A.人事管制,
	nvl(B.權限, ' ') 權限, 
	nvl(B.最後更新者, ' ') 最後更新者, 
	B.最後更新日,
	nvl(B.隱藏, 0) 使用者隱藏,
	nvl(B.獨立執行, 0) 獨立執行,
	nvl(B.密碼執行,0) 密碼執行
FROM 
	(	SELECT
			* 
		FROM
			FIL1000 A,
			FIL0010 B
	) A
	LEFT JOIN FIL1007 B ON B.員工編號 = A.員工編號 and B.PublicName = A.PublicName);

-- Oracle user_views
CREATE VIEW "VIEWFIL0011" ("代碼", "名稱", "廠商編號", "全名", "簡稱", "最後更新者", "更新者姓名", "最後更新日") AS (                                                                                                                                                              SELECT 
	A.系統代碼 代碼, 
	A.代碼名稱 名稱, 
	A.文字參數 廠商編號,
	nvl(B.全名, ' ') 全名,
	nvl(B.簡稱, ' ') 簡稱,
	A.最後更新者, 
	nvl(Z1.員工姓名, ' ') 更新者姓名, 
	A.最後更新日 
FROM 
	FIL1014 A
	LEFT JOIN FIL0011 B ON A.文字參數 = B.編號
	LEFT JOIN FIL0010 Z1 ON A.最後更新者 = Z1.員工編號
WHERE 
	A.代碼類別 = '公司別');

-- Oracle user_views
CREATE VIEW "VIEWFIL0012" ("部門編號", "部門名稱", "英文名稱", "出勤津貼", "停止使用", "所屬公司", "所屬公司名稱", "上階部門", "製程代碼", "製程名稱", "上階部門名稱", "權責單位", "流水編號", "公司流水編號", "更新者姓名", "最後更新日") AS (                                                                                                                                                              SELECT 
	A.部門編號, 
	nvl(B.名稱,' ')||'.'||A.部門名稱 部門名稱, 
	A.英文名稱,
	A.出勤津貼,
	A.停止使用,
	A.所屬公司,
	nvl(B.名稱,' ') 所屬公司名稱,
	A.上階部門, 
	A.製程代碼,
	A.製程名稱,
	nvl(C.部門名稱,' ') 上階部門名稱,
	(case when (A.部門編號 between 'A12' and 'AZ') or (A.部門編號 between 'H12' and 'HZ') then 1 else 0 end) 權責單位,
	D.SERIAL_NUM 流水編號,
	D.BelongTo 公司流水編號,
	nvl(Z.員工姓名, ' ') 更新者姓名, 
	A.最後更新日 
FROM 
	FIL0020 A
	LEFT JOIN ViewFIL0011 B ON B.代碼=A.所屬公司
	LEFT JOIN FIL0020 C ON C.部門編號=A.上階部門
	LEFT JOIN FIL0010 Z ON A.最後更新者 = Z.員工編號
	LEFT JOIN A30 D ON D.GROUPID = A.部門編號
	);

-- Oracle user_views
CREATE VIEW "VIEWFIL0012014" ("編號", "名稱", "排序", "類別") AS (  
SELECT 
	A.部門編號 編號, 
	nvl(B.名稱,' ')||'.'||A.部門名稱 名稱, 
	to_char(nvl(B.名稱,' ')||'.'||A.部門名稱) 排序,
	'1' 類別
FROM 
	FIL0020 A
	LEFT JOIN ViewFIL0011 B ON B.代碼=A.所屬公司

union all

SELECT
	A.編號,
	A.全名 名稱,
	to_char(A.全名) 排序,
	'2' 類別
FROM
	FIL0011 A
WHERE
	A.廠客 = '1');

-- Oracle user_views
CREATE VIEW "VIEWFIL0013" ("寄件者", "收件者", "序號", "主旨", "本文", "提醒日", "寄件日", "寄件者姓名", "收件者姓名", "發送", "已讀", "隱藏", "通知", "簽核系統") AS (                                                                                                                                                SELECT
	A.寄件者,
	A.收件者,
	A.序號,
	A.主旨,
	A.本文,
	A.提醒日,
	A.寄件日,
	nvl(B.員工姓名, ' ') 寄件者姓名,
	nvl(C.員工姓名, ' ') 收件者姓名,
	A.發送,
	A.已讀,
	A.隱藏,
	A.通知,
	A.簽核系統
FROM
	FIL1017 A
	LEFT JOIN FIL0010 B ON A.寄件者 = B.員工編號
	LEFT JOIN FIL0010 C ON A.收件者 = C.員工編號);

-- Oracle user_views
CREATE VIEW "VIEWFIL0014" ("單據類別", "單據編號", "序號", "說明", "狀態", "修改人", "修改人姓名", "修改日") AS (                                                                                                                                                SELECT 
	A.單據類別,
	A.單據編號,
	A.序號,
	A.說明, 
	A.狀態,
	A.修改人, 
	nvl(B.員工姓名, ' ') 修改人姓名, 
	A.修改日
FROM 
	FIL1018 A
	LEFT JOIN FIL0010 B ON A.修改人 = B.員工編號);

-- Oracle user_views
CREATE VIEW "VIEWFIL0015" ("對應編號", "員工編號", "西元日期", "時間", "記錄內容", "裝置位址") AS (                                         
Select
	對應編號,
	員工編號,
	MAX(西元日期) 西元日期,
	MAX(時間) 時間,
	MAX(記錄內容) 記錄內容,
	MAX(裝置位址) 裝置位址
From
	FIL1006
Where
	類別 like '附件%' and 對應編號 like 'C11B%'
GROUP BY
	對應編號,
	員工編號
);

-- Oracle user_views
CREATE VIEW "VIEWFIL0020" ("單據類別", "單據名稱", "排序", "產品庫存參數", "材料庫存參數", "採購應付參數", "代工應付參數", "應收參數", "成本參數", "ISO", "單據管理員代號", "單據管理員姓名", "單據管理員代號二", "單據管理員姓名二", "單據管理員代號三", "單據管理員姓名三", "最後更新者", "更新者姓名", "最後更新日") AS (                                                                                                                                                SELECT 
	A.系統代碼 單據類別, 
	A.代碼名稱 單據名稱, 
	A.文字參數 排序,
	A.數字參數   產品庫存參數,
	A.數字參數二 材料庫存參數,
	A.數字參數三 採購應付參數,
	A.數字參數四 代工應付參數,
	A.數字參數五 應收參數,
	A.數字參數六 成本參數,
	A.英數參數 ISO,
	A.文字參數一 單據管理員代號,
	nvl(C.員工姓名,' ') 單據管理員姓名,
	A.文字參數二 單據管理員代號二,
	nvl(D.員工姓名,' ') 單據管理員姓名二,
	A.文字參數三 單據管理員代號三,
	nvl(E.員工姓名,' ') 單據管理員姓名三,
	A.最後更新者, 
	nvl(B.員工姓名, ' ') 更新者姓名, 
	A.最後更新日 
FROM 
	FIL1014 A
	LEFT JOIN FIL0010 B ON B.員工編號 = A.最後更新者
	LEFT JOIN FIL0010 C ON C.員工編號 = A.文字參數一
	LEFT JOIN FIL0010 D ON D.員工編號 = A.文字參數二
	LEFT JOIN FIL0010 E ON E.員工編號 = A.文字參數三
WHERE 
	A.代碼類別 = '單據類別');

-- Oracle user_views
CREATE VIEW "VIEWFIL0030" ("簽核編號", "簽核系統", "單號", "發函人", "發函人姓名", "發函日期", "發函時間", "簽核群組", "最後簽核流程順序", "簽核狀態", "刪除退回人", "刪除退回日", "發函代理人", "代理人姓名") AS (                                                                                                                                                                    SELECT 
	A.簽核編號, 
	A.簽核系統, 
	A.單號, 
	A.發函人,
	NVL(C.員工姓名, ' ') 發函人姓名,
	A.發函日期, 
	A.發函時間, 
	A.簽核群組, 
	A.最後簽核流程順序, 
	A.簽核狀態, 
	A.刪除退回人, 
	A.刪除退回日, 
	A.發函代理人, 
	NVL(B.員工姓名,' ') 代理人姓名 
FROM 
	FIL1009 A
	LEFT JOIN FIL0010 B ON B.員工編號 = A.發函代理人
	LEFT JOIN FIL0010 C ON C.員工編號 = A.發函人
WHERE 
	A.簽核編號 =
	(	SELECT 
			MAX(A1.簽核編號) 
		FROM 
			FIL1009 A1 
		WHERE 
			A1.簽核系統 = A.簽核系統 AND 
			A1.單號 = A.單號
	));

-- Oracle user_views
CREATE VIEW "VIEWFIL0040" ("簽核編號", "簽核系統", "單據類別", "單據名稱", "單據編號", "表單狀態", "發函人", "發函人姓名", "發函日期", "發函時間", "簽核群組", "最後簽核流程順序", "簽核狀態", "刪除退回人", "撤回人姓名", "刪除退回日", "發函代理人", "發函代理人姓名", "單據日期", "備註", "填表人", "填表人姓名") AS (                                                                                                                                                                    SELECT 
	A.簽核編號, 
	A.簽核系統, 
	B.單據類別, 
	C.單據名稱, 
	A.單號 單據編號, 
	D.簽核狀態 表單狀態, 
	A.發函人, 
	nvl(E.員工姓名, ' ') 發函人姓名,
	A.發函日期, 
	A.發函時間, 
	A.簽核群組, 
	A.最後簽核流程順序, 
	A.簽核狀態, 
	A.刪除退回人, 
	nvl(F.員工姓名, ' ') 撤回人姓名, 
	A.刪除退回日, 
	A.發函代理人,
	nvl(G.員工姓名, ' ') 發函代理人姓名,  
	B.單據日期, 
	B.備註,
	B.填表人, 
	nvl(H.員工姓名, ' ') 填表人姓名 
FROM 
	FIL1009 A
	INNER JOIN FIL0030 B ON B.單據編號 = A.單號 and (B.簽核系統 = A.簽核系統 or B.簽核系統_結案 = A.簽核系統)
	LEFT JOIN ViewFIL0020 C ON C.單據類別 = B.單據類別
	LEFT JOIN ViewFIL0030 D ON D.簽核系統 = A.簽核系統 and D.單號 = A.單號
	LEFT JOIN FIL0010 E ON E.員工編號 = A.發函人
	LEFT JOIN FIL0010 F ON F.員工編號 = A.刪除退回人
	LEFT JOIN FIL0010 G ON G.員工編號 = A.發函代理人
	LEFT JOIN FIL0010 H ON H.員工編號 = B.填表人);

-- Oracle user_views
CREATE VIEW "VIEWFIL0050" ("簽核編號", "序號", "簽核人", "簽核人姓名", "簽核流程順序", "執行碼", "執行碼說明", "執行日", "執行時", "意見", "移轉簽核人", "移轉簽核人姓名", "代簽人", "代簽人姓名", "GUID") AS (                                                                                                                                                       SELECT 
	A.簽核編號, 
	A.序號, 
	A.簽核人, 
	nvl(B.員工姓名, ' ') 簽核人姓名, 
	A.簽核流程順序, 
	A.執行碼, 
	decode(A.執行碼, 'K', '核准', 'R', '退件',
		case when E.最後簽核流程順序 = A.簽核流程順序 then '待簽'
			else ' '
			end) 執行碼說明, 
	A.執行日, 
	A.執行時, 
	A.意見,  
	A.移轉簽核人, 
	nvl(C.員工姓名, ' ') 移轉簽核人姓名, 
	A.代簽人, 
	nvl(D.員工姓名, ' ') 代簽人姓名, 
	A.GUID 
FROM
	FIL1010 A
	INNER JOIN FIL1009 E ON E.簽核編號 = A.簽核編號
	LEFT JOIN FIL0010 B ON B.員工編號 = A.簽核人
	LEFT JOIN FIL0010 C ON C.員工編號 = A.移轉簽核人
	LEFT JOIN FIL0010 D ON D.員工編號 = A.代簽人);

-- Oracle user_views
CREATE VIEW "VIEWFIL0051" ("簽核系統", "單號", "序號", "附件", "格式", "說明", "大小", "關鍵字", "客供類別", "客供名稱", "附件類別", "附件類別名稱", "最後更新者", "更新者姓名", "最後更新日", "建檔人姓名", "建檔日", "建檔時") AS (                                                                                                                                                       SELECT
	A.簽核系統,
	A.單號,
	A.序號,
	A.附件,
	upper(A.格式) 格式,
	A.說明,
	A.大小,
	A.關鍵字,
	A.客供類別,
	' ' 客供名稱,
	A.附件類別,
	' ' 附件類別名稱,
	A.更新者 最後更新者,
	nvl(B.員工姓名, ' ') 更新者姓名,
	A.更新日 最後更新日,
	nvl(C.員工姓名, ' ') 建檔人姓名,
	A.建檔日 建檔日,
	A.建檔時 建檔時
FROM
	FIL1011 A
	LEFT JOIN FIL0010 B ON A.更新者 = B.員工編號
	LEFT JOIN FIL0010 C ON A.建檔人 = C.員工編號
);

-- Oracle user_views
CREATE VIEW "VIEWFIL0052" ("簽核系統", "單據類別", "單據編號", "單據名稱", "訂單號碼", "單據日期", "廠客編號", "廠客全名", "序號", "附件", "格式", "說明", "大小", "關鍵字", "最後更新者", "更新者姓名", "最後更新日") AS (                                                                                                                                                       SELECT
	A.簽核系統,
	B.單據類別,
	A.單號 單據編號,
	D.單據名稱,
	B.訂單號碼,
	B.單據日期,
	B.廠客編號,
	nvl(E.全名, ' ') 廠客全名,
	A.序號,
	A.附件,
	upper(A.格式) 格式,
	A.說明,
	A.大小,
	A.關鍵字,
	A.更新者 最後更新者,
	nvl(C.員工姓名, ' ') 更新者姓名,
	A.更新日 最後更新日
FROM
	FIL1011 A
	INNER JOIN FIL0030 B ON A.簽核系統 = B.簽核系統 AND A.單號 = B.單據編號
	INNER JOIN ViewFIL0020 D ON B.單據類別 = D.單據類別
	LEFT JOIN FIL0010 C ON A.更新者 = C.員工編號
	LEFT JOIN FIL0011 E ON B.廠客編號 = E.編號);

-- Oracle user_views
CREATE VIEW "VIEWFIL0053" ("父階", "子階", "年度", "廠商", "單號", "附件", "說明") AS (                                                                                                                                                       SELECT
	A.父階,
	A.子階,
	A.年度,
	A.廠商,
	A.單號,
	A.附件,
	A.說明
FROM
	(	SELECT
			distinct '0000' 父階,
			substr(A.單據日期,1,4) 子階,
			1 年度,
			0 廠商,
			0 單號,
			0 附件,
			substr(A.單據日期,1,4) 說明
		FROM
			ViewFIL0052 A

		union	

		SELECT
			distinct substr(A.單據日期,1,4) 父階,
			A.廠客編號 子階,
			0 年度,
			1 廠商,
			0 單號,
			0 附件,
			to_char(A.廠客全名) 說明
		FROM
			ViewFIL0052 A
		
		union
		
		SELECT
			distinct A.廠客編號 父階,
			to_char(trim(A.訂單號碼) || '^' || '^' || trim(A.單據編號) || '^' || A.簽核系統) 子階,
			0 年度,
			0 廠商,
			1 單號,
			0 附件,
			to_char(trim(A.單據編號) || ' ' || A.單據名稱) 說明
		FROM
			ViewFIL0052 A
		
		union
		
		SELECT
			distinct to_char(trim(A.訂單號碼) || '^' || trim(A.單據編號) || '^' || A.簽核系統) 父階,
			to_char(A.序號, '999') 子階,
			0 年度,
			0 廠商,
			0 單號,
			1 附件,
			to_char('【' || trim(upper(A.格式)) || '】' || A.說明) 說明
		FROM
			ViewFIL0052 A
	) A);

-- Oracle user_views
CREATE VIEW "VIEWFIL0054" ("簽核系統", "單號", "檔案大小", "筆數") AS (
SELECT
	A.簽核系統,
	A.單號,
	sum(A.大小) 檔案大小,
	count(A.序號) 筆數
FROM
	FIL1011 A
WHERE
	A.說明<>' '
GROUP BY 
	A.簽核系統,
	A.單號
);

-- Oracle user_views
CREATE VIEW "VIEWFIL0055" ("單別", "單號", "材料序號", "屬性", "筆數") AS (
SELECT
	A.製令單別 單別,
	A.製令單號 單號,
	A.材料序號,
	A.屬性,
	count(序號) 筆數
FROM
	FIL0037 A
WHERE
	length(A.圖檔)>0 or A.備註<>' '
GROUP BY 
	A.製令單別,
	A.製令單號,
	A.材料序號,
	A.屬性
);

-- Oracle user_views
CREATE VIEW "VIEWFIL0081" ("簽核系統", "組別", "簽核順序", "員工編號", "員工姓名", "開始日期", "結束日期", "類別", "啟用", "最後更新者", "更新者姓名", "最後更新日") AS (SELECT
	A.簽核系統,
	A.組別,
	A.簽核順序,
	A.員工編號,
	nvl(B.員工姓名, ' ') 員工姓名,
	A.開始日期,
	A.結束日期,
	A.類別,
	A.啟用,
	A.最後更新者,
	nvl(C.員工姓名, ' ') 更新者姓名,
	A.最後更新日
FROM
	FIL1013 A
	LEFT JOIN FIL0010 B ON B.員工編號 = A.員工編號
	LEFT JOIN FIL0010 C ON C.員工編號 = A.最後更新者);

-- Oracle user_views
CREATE VIEW "VIEWFIL1010" ("員工編號", "員工姓名", "英文姓名", "公司代碼", "公司別", "出生日期", "就職日期", "離職日期", "聯絡電話", "EMAILADDRESS", "郵遞區號", "通訊地址", "個人密碼", "部門編號", "部門名稱", "身份證號", "停止使用", "主管編號", "主管姓名", "職稱代碼", "職位名稱", "開放時間_起", "開放時間_迄", "內定工站一", "流水編號", "FLOWPOSI", "簽核職位", "SALARYPOSI", "班別代碼", "班別", "國籍", "薪資類別", "指定程式", "生產部門禁", "最後更新者", "更新者姓名", "最後更新日", "最後更新時") AS (SELECT
	A.員工編號,
	A.員工姓名,
	A.英文姓名,
	A.公司代碼,
	nvl(F.名稱,' ') 公司別,
	A.出生日期,
	A.就職日期,
	A.離職日期,
	A.聯絡電話,
	A.eMailAddress,
	A.郵遞區號,
	A.通訊地址,
	A.個人密碼,
	A.部門編號,
	nvl(C.GUName, ' ') 部門名稱,
	A.身份證號,
	A.停止使用,
	A.主管編號,
	nvl(D.員工姓名, ' ') 主管姓名,
	A.職稱代碼,
	nvl(E.GUName, ' ') 職位名稱,
	A.開放時間_起,
	A.開放時間_迄,
	DECODE(NVL(G.內定工站一,' '),' ','NONE',NVL(G.內定工站一,' ')) 內定工站一,
	A.Serial_Num 流水編號,
	A.FLOWPOSI,
	nvl(I.GUName, ' ') 簽核職位,
	A.SALARYPOSI,
	A.Party 班別代碼,
	nvl(H.名稱,' ') 班別,
	DECODE(A.NATION,' ','本國',A.NATION) 國籍,
	A.EmpStatus 薪資類別,
	A.EntryID 指定程式,
	A.生產部門禁,
	A.最後更新者,
	nvl(B.員工姓名, ' ') 更新者姓名,
	A.最後更新日,
	A.最後更新時
FROM
	FIL0010 A
	LEFT JOIN FIL0010 B ON A.最後更新者 = B.員工編號
	LEFT JOIN A30 C ON A.部門編號 = C.GroupID
	LEFT JOIN FIL0010 D ON A.主管編號 = D.員工編號
	LEFT JOIN A40 E ON A.職稱代碼 = E.SERIAL_NUM
	LEFT JOIN ViewFIL0011 F ON A.公司代碼 = F.代碼
	LEFT JOIN FIL0024 G ON G.員工編號 = A.員工編號
	LEFT JOIN FIL0025 H ON H.代碼 = A.PARTY
	LEFT JOIN A40 I ON A.FLOWPOSI = I.SERIAL_NUM
	);

-- Oracle user_views
CREATE VIEW "VIEWFIL1010A" ("員工編號", "員工姓名", "公司別", "部門編號", "部門名稱", "流水編號", "班別", "國籍", "最後更新者", "更新者姓名", "最後更新日", "最後更新時") AS (SELECT
	A.員工編號,
	A.員工姓名,
	nvl(F.名稱,' ') 公司別,
	A.部門編號,
	nvl(C.GUName, ' ') 部門名稱,
	A.Serial_Num 流水編號,
	nvl(H.名稱,' ') 班別,
	DECODE(A.NATION,' ','本國',A.NATION) 國籍,
	A.最後更新者,
	nvl(B.員工姓名, ' ') 更新者姓名,
	A.最後更新日,
	A.最後更新時
FROM
	FIL0010 A
	LEFT JOIN FIL0010 B ON A.最後更新者 = B.員工編號
	LEFT JOIN A30 C ON A.部門編號 = C.GroupID
	LEFT JOIN ViewFIL0011 F ON A.公司代碼 = F.代碼
	LEFT JOIN FIL0025 H ON H.代碼 = A.PARTY
	);

-- Oracle user_views
CREATE VIEW "VIEWFIL1012" ("產品編號", "產品類別", "類別名稱", "物料大類", "大類名稱", "批號管理", "品名", "規格", "貨號", "版次", "單位代碼", "單位名稱", "包裝數量", "包裝單位", "代理人姓名", "新品號核准日期", "修改品名規格", "財務", "主要庫別", "庫別名稱", "採購單位", "採購單位名稱", "銷售單位", "銷售單位名稱", "稅則", "條碼編號", "庫存管理", "進價管制", "單價上限率", "售價管制", "重量", "超交管理", "超交率", "品號屬性", "品號屬性名稱", "低階碼", "備註", "標準途程品號", "次要供應商名稱", "採購人", "採購人姓名", "主供應商", "主供應商名稱", "補貨政策", "補貨政策名稱", "固定前置天數", "變動前置天數", "批量", "承認碼", "最低補量", "補貨倍量", "領用倍量", "轉撥倍量", "檢驗方式", "檢驗方式名稱", "領料代碼", "領料代碼名稱", "超收率", "標準進價", "標準售價", "零售價", "售價定價一", "營業稅率", "重量單位", "重量單位名稱", "熟成溫度1", "熟成時間1", "熟成溫度2", "熟成時間2", "英文品名", "材質結構1", "材質結構2", "材質結構3", "材質結構", "失效日期", "客戶成品尺寸", "客戶最終名稱", "安全存量", "密度", "進貨報價類別", "盤點日期", "盤存數量", "流水編號", "建立員工", "建立姓名", "建立日期", "最後更新者", "更新者姓名", "最後更新日") AS (SELECT
	A.產品編號,
	A.產品類別,
	decode(A.產品類別, 'F', '成品', 'M', '原料', 'N', '物料', 'O', '其他', '空白') 類別名稱,
	A.物料大類,
	nvl(D.名稱, ' ') 大類名稱,
	nvl(D.批號管理,0) 批號管理,
	A.品名,
	A.規格,
	A.貨號,
	A.版次,
	A.單位代碼,
	nvl(H1.名稱,  ' ') 單位名稱,
	A.包裝數量,
	A.包裝單位,
	nvl(M.員工姓名, ' ') 代理人姓名,
	A.新品號核准日期,
	A.修改品名規格,
	A.財務,
	A.主要庫別,
	nvl(I.名稱, ' ') 庫別名稱,
	A.採購單位,
	nvl(H2.名稱,  ' ') 採購單位名稱,
	A.銷售單位,
	nvl(H3.名稱,  ' ') 銷售單位名稱,
	A.稅則,
	A.條碼編號,
	A.庫存管理,
	A.進價管制,
	A.單價上限率,
	A.售價管制,
	A.單價下限率 重量,
	A.超交管理,
	A.超交率,
	A.品號屬性,
	decode(A.品號屬性, 'M', '自製件', 'P', '採購件', '空白') 品號屬性名稱,
	A.低階碼,
	A.備註,
	A.標準途程品號,
	nvl(L.全名, ' ') 次要供應商名稱,
	A.採購人,
	nvl(J.員工姓名, ' ') 採購人姓名,
	A.主供應商,
	nvl(K.全名, ' ') 主供應商名稱,
	A.補貨政策,
	decode(A.補貨政策, 'L', '依LRPM需求', 'R', '依補貨點', '空白') 補貨政策名稱,
	A.固定前置天數,
	A.變動前置天數,
	A.批量,
	A.承認碼,
	A.最低補量,
	A.補貨倍量,
	A.領用倍量,
	A.轉撥倍量,
	A.檢驗方式,
	decode(A.檢驗方式, '0', '免檢', '2', '抽檢(正常)', '4', '全檢', '空白') 檢驗方式名稱,
	A.領料代碼,
	decode(A.領料代碼, '1', '逐批領料', '空白') 領料代碼名稱,
	A.超收率,
	A.標準進價,
	A.標準售價,
	A.零售價,
	A.售價定價一,
	A.營業稅率,
	A.重量單位,
	nvl(H4.名稱, ' ') 重量單位名稱,
	A.熟成溫度1,
	A.熟成時間1,
	A.熟成溫度2,
	A.熟成時間2,
	A.英文品名,
	A.材質結構1,
	A.材質結構2,
	A.材質結構3,
	trim(nvl(E.品名, ' ')) || decode(A.材質結構2, ' ', ' ', '/' || trim(nvl(F.品名, ' '))) || decode(A.材質結構3, ' ', ' ', '/' || trim(nvl(G.品名, ' '))) 材質結構,
	A.失效日期,
	A.客戶成品尺寸,
	A.客戶最終名稱,
	A.安全存量,
	N.密度,
	N.名稱 進貨報價類別,
	A.盤點日期,
	A.盤存數量,
	A.流水編號,
	A.建立員工,
	nvl(B.員工姓名, ' ') 建立姓名,
	A.建立日期,
	A.最後更新者,
	nvl(C.員工姓名, ' ') 更新者姓名,
	A.最後更新日
FROM
	FIL0012 A
	LEFT JOIN FIL0010 B ON A.建立員工 = B.員工編號
	LEFT JOIN FIL0010 C ON A.最後更新者 = C.員工編號
	LEFT JOIN ViewFIL310B D ON A.物料大類 = D.代碼
	LEFT JOIN FIL0012 E ON A.材質結構1 = E.產品編號
	LEFT JOIN FIL0012 F ON A.材質結構2 = F.產品編號
	LEFT JOIN FIL0012 G ON A.材質結構3 = G.產品編號
	LEFT JOIN ViewFIL3103 H1 ON A.單位代碼 = H1.代碼
	LEFT JOIN ViewFIL3103 H2 ON A.採購單位 = H2.代碼
	LEFT JOIN ViewFIL3103 H3 ON A.銷售單位 = H3.代碼
	LEFT JOIN ViewFIL3103 H4 ON A.重量單位 = H4.代碼
	LEFT JOIN ViewFIL3106 I ON A.主要庫別 = I.代碼
	LEFT JOIN FIL0010 J ON A.採購人 = J.員工編號
	LEFT JOIN FIL0011 K ON A.主供應商 = K.編號
	LEFT JOIN FIL0011 L ON A.標準途程品號 = L.編號
	LEFT JOIN FIL0010 M ON A.包裝單位 = M.員工編號
	LEFT JOIN ViewFIL3117 N ON N.代碼 = A.進貨報價類別
	);

-- Oracle user_views
CREATE VIEW "VIEWFIL1013" ("廠別編號", "廠別名稱", "建立員工", "建立姓名", "建立日期", "最後更新者", "更新者姓名", "最後更新日") AS (SELECT
	A.廠別編號,
	A.廠別名稱,
	A.建立員工,
	nvl(B.員工姓名, ' ') 建立姓名,
	A.建立日期,
	A.最後更新者,
	nvl(C.員工姓名, ' ') 更新者姓名,
	A.最後更新日
FROM
	FIL0013 A
	LEFT JOIN FIL0010 B ON A.建立員工 = B.員工編號
	LEFT JOIN FIL0010 C ON A.最後更新者 = C.員工編號);

-- Oracle user_views
CREATE VIEW "VIEWFIL1014" ("編號", "全名", "簡稱", "關係人代號", "憑證列印格式", "統一編號", "核准狀況", "核准狀況名稱", "電話一", "電話二", "傳真", "EMAIL", "負責人", "聯絡人一", "聯絡人二", "聯絡人三", "採購人員", "採購人員姓名", "備註", "總公司", "總公司收款", "會計傳真", "交易項目", "區域代號", "區域名稱", "國別代號", "國別名稱", "廠商分類", "廠商分類名稱", "開業日", "資本額", "員工數", "交易幣別", "交易幣別名稱", "稅額計算方式", "稅額計算方式名稱", "單身多稅率", "採購單發送方式", "採購單發送方式名稱", "訂金比率", "允許分批交貨", "付款方式", "付款方式名稱", "付款條件", "付款條件名稱", "價格條件", "匯款總行", "匯款銀行", "銀行名稱", "匯款帳號", "交易條件", "交易條件名稱", "票據寄領", "票據寄領名稱", "稅別代碼", "稅別名稱", "發票聯數", "發票聯數名稱", "課稅別", "課稅別名稱", "應付帳款科目", "帳款科目名稱", "加工費用科目", "費用科目名稱", "應付票據科目", "票據科目名稱", "ABC等級", "交貨評等", "品質評等", "匯至EBC", "EBC申請代號", "聯絡郵區一", "聯絡地址一", "聯絡郵區二", "聯絡地址二", "帳單郵區一", "帳單地址一", "帳單郵區二", "帳單地址二", "隨貨附發票", "版次", "核准日期", "結帳日", "個月逢", "報價自動回覆", "報價聯絡人", "報價EMAIL", "驗報自動回覆", "驗報聯絡人", "驗報EMAIL", "設計圖自動回覆", "設計圖聯絡人", "設計圖EMAIL", "流水編號", "建立員工", "建立員工姓名", "建立日期", "最後更新者", "更新者姓名", "最後更新日") AS (SELECT
	A.編號,
	A.全名,
	A.簡稱,
	A.關係人代號,
	A.憑證列印格式,
	A.統一編號,
	A.核准狀況,
	decode(A.核准狀況, '1', '已核准', '其他') 核准狀況名稱,
	A.電話一,
	A.電話二,
	A.傳真,
	A.eMail,
	A.負責人,
	A.聯絡人一,
	A.聯絡人二,
	A.聯絡人三,
	A.採購人員,
	nvl(K.員工姓名, ' ') 採購人員姓名,
	A.備註,
	A.總公司,
	A.總公司收款,
	A.會計傳真,
	A.交易項目,
	A.區域代號,
	nvl(L.名稱, ' ') 區域名稱,
	A.國別代號,
	nvl(M.名稱, ' ') 國別名稱,
	A.廠商分類,
	nvl(N.名稱, ' ') 廠商分類名稱,
	A.開業日,
	A.資本額,
	A.員工數,
	A.交易幣別,
	nvl(O.名稱, ' ') 交易幣別名稱,
	A.稅額計算方式,
	decode(A.稅額計算方式, '1', '整張資料計算', '2', '單身單筆資料計算', '其他') 稅額計算方式名稱,
	A.單身多稅率,
	A.單據發送方式 採購單發送方式,
	decode(A.單據發送方式, '1', '郵寄', '2', 'FAX', '4', 'eMail', '其他') 採購單發送方式名稱,
	A.訂金比率,
	A.允許分批交貨,
	A.收付類別 付款方式,
	decode(A.收付類別, '1', '現金', '2', '電匯', '3', '支票', '4', '其他') 付款方式名稱,
	A.收付方式 付款條件,
	nvl(D.名稱, ' ') 付款條件名稱,
	A.價格條件,
	A.匯款總行,
	A.匯款銀行,
	nvl(E.機構名稱, ' ') 銀行名稱,
	A.匯款帳號,
	A.交易條件,
	decode(A.交易條件, '1', '一般', '其他') 交易條件名稱,
	A.票據寄領,
	decode(A.票據寄領, '1', '郵寄', '3', '其他') 票據寄領名稱,
	A.稅別代碼,
	nvl(F.名稱, ' ')  稅別名稱,
	A.發票類別 發票聯數,
	nvl(G.名稱, ' ') 發票聯數名稱,
	A.課稅別,
	decode(A.課稅別, '2', '應稅外加', '3', '零稅率', '4', '免稅', '9', '不計稅', '其他') 課稅別名稱,
	A.應收付款科目 應付帳款科目,
	nvl(H.科目名稱, ' ') 帳款科目名稱,
	A.加工費用科目,
	nvl(I.科目名稱, ' ') 費用科目名稱,
	A.應收付票科目 應付票據科目,
	nvl(J.科目名稱, ' ') 票據科目名稱,
	A.ABC等級,
	A.交貨評等,
	A.品質評等,
	A.匯至EBC,
	A.EBC申請代號,
	A.聯絡郵區一,
	A.聯絡地址一,
	A.聯絡郵區二,
	A.聯絡地址二,
	A.帳單郵區一,
	A.帳單地址一,
	A.帳單郵區二,
	A.帳單地址二,
	A.隨貨附發票,
	A.版次,
	A.核准日期,
	A.結帳日,
	A.個月逢,
	A.報價自動回覆,
	A.報價聯絡人,
	A.報價email,
	A.驗報自動回覆,
	A.驗報聯絡人,
	A.驗報email,
	A.設計圖自動回覆,
	A.設計圖聯絡人,
	A.設計圖email,
	A.流水編號,
	A.建立員工,
	nvl(B.員工姓名, ' ') 建立員工姓名,
	A.建立日期,
	A.最後更新者,
	nvl(C.員工姓名, ' ') 更新者姓名,
	A.最後更新日
FROM
	FIL0011 A
	LEFT JOIN FIL0010 B ON A.建立員工 = B.員工編號
	LEFT JOIN FIL0010 C ON A.最後更新者 = C.員工編號
	LEFT JOIN ViewFIL3107 D ON A.收付方式 = D.代碼
	LEFT JOIN FIL0021 E ON A.匯款總行 = E.總機構代碼 AND A.匯款銀行 = E.分支機構代碼 AND E.分支機構代碼 != ' '
	LEFT JOIN ViewFIL310E F ON A.稅別代碼 = F.代碼
	LEFT JOIN ViewFIL3104 G ON A.發票類別 = G.代碼
	LEFT JOIN FIL0018 H ON A.應收付款科目 = H.科目代碼
	LEFT JOIN FIL0018 I ON A.加工費用科目 = I.科目代碼
	LEFT JOIN FIL0018 J ON A.應收付票科目 = J.科目代碼
	LEFT JOIN FIL0010 K ON A.採購人員 = K.員工編號
	LEFT JOIN ViewFIL310F L ON A.區域代號 = L.代碼
	LEFT JOIN ViewFIL310G M ON A.國別代號 = M.代碼
	LEFT JOIN ViewFIL310H N ON A.廠商分類 = N.代碼
	LEFT JOIN ViewFIL3102 O ON A.交易幣別 = O.代碼
WHERE
	A.廠客 = '1');

-- Oracle user_views
CREATE VIEW "VIEWFIL1015" ("編號", "全名", "英文名稱", "簡稱", "關係人代號", "負責人", "聯絡人一", "聯絡人二", "電話一", "電話二", "分機一", "分機二", "傳真", "EMAIL", "統一編號", "資本額", "年營業額", "員工數", "總店號", "總公司請款", "發票號碼依總公司控管", "合約訂單是否歸屬總公司", "分店數", "交易幣別", "交易幣別名稱", "部門別", "部門名稱", "業務人員", "業務人員姓名", "收款業務", "收款業務姓名", "開業日", "歇業日", "登記郵區一", "登記地址一", "登記郵區二", "登記地址二", "發票郵區一", "發票地址一", "發票郵區二", "發票地址二", "送貨郵區一", "送貨地址一", "送貨郵區二", "送貨地址二", "帳單郵區一", "帳單收件人", "帳單地址一", "帳單郵區二", "帳單地址二", "信用額度依總公司控管", "信用額度管制", "信用額度", "可超出率", "訂單信用查核方式", "訂單信用查核方式名稱", "出貨通知信用查核方式", "出貨通知信用查核方式名稱", "銷貨信用查核方式", "銷貨信用查核方式名稱", "暫出單信用查核方式", "暫出單信用查核方式名稱", "付款條件", "付款條件名稱", "稅額計算方式", "稅額計算方式名稱", "單身多稅率", "隨貨附發票", "訂金比率", "價格條件", "稅別代碼", "稅別名稱", "發票聯數", "發票聯數名稱", "課稅別", "課稅別名稱", "通關方式", "通關方式名稱", "單據發送方式", "單據發送方式名稱", "收款方式", "收款方式名稱", "票據寄領", "票據寄領名稱", "客戶型態", "型態名稱", "區域代號", "區域名稱", "國別代號", "國別名稱", "取價順序", "折扣率", "折扣率預設", "匯至EBC", "EBC申請代號", "結帳日", "付款總行一", "付款銀行一", "銀行名稱一", "銀行帳號一", "付款總行二", "付款銀行二", "銀行名稱二", "銀行帳號二", "付款總行三", "付款銀行三", "銀行名稱三", "銀行帳號三", "帳款科目", "帳款科目名稱", "票據科目", "票據科目名稱", "備註", "運輸方式", "運輸方式名稱", "交易條件", "交易條件名稱", "文件郵區一", "文件地址一", "文件郵區二", "文件地址二", "版次", "核准日期", "報價自動回覆", "報價聯絡人", "報價EMAIL", "驗報自動回覆", "驗報聯絡人", "驗報EMAIL", "設計圖自動回覆", "設計圖聯絡人", "設計圖EMAIL", "流水編號", "建立員工", "建立員工姓名", "建立日期", "最後更新者", "更新者姓名", "最後更新日") AS (SELECT
	A.編號,
	A.全名,
	A.英文名稱,
	A.簡稱,
	A.關係人代號,
	A.負責人,
	A.聯絡人一,
	A.聯絡人二,
	A.電話一,
	A.電話二,
	A.分機一,
	A.分機二,
	A.傳真,
	A.eMail,
	A.統一編號,
	A.資本額,
	A.年營業額,
	A.員工數,
	A.總公司 總店號,
	A.總公司收款 總公司請款,
	A.發票號碼依總公司控管,
	A.合約訂單是否歸屬總公司,
	A.分店數,
	A.交易幣別,
	nvl(O.名稱, ' ') 交易幣別名稱,
	A.部門別,
	nvl(P.部門名稱, ' ') 部門名稱,
	A.採購人員 業務人員,
	nvl(K.員工姓名, ' ') 業務人員姓名,	
	A.收款業務,
	nvl(Q.員工姓名, ' ') 收款業務姓名,	
	A.開業日,
	A.歇業日,
	A.登記郵區一,
	A.登記地址一,
	A.登記郵區二,
	A.登記地址二,
	A.發票郵區一,
	A.發票地址一,
	A.發票郵區二,
	A.發票地址二,
	A.送貨郵區一,
	A.送貨地址一,
	A.送貨郵區二,
	A.送貨地址二,
	A.帳單郵區一,
	A.帳單收件人,
	A.帳單地址一,
	A.帳單郵區二,
	A.帳單地址二,
	A.信用額度依總公司控管,
	A.信用額度管制,
	A.信用額度,
	A.可超出率,
	A.訂單信用查核方式,
	decode(A.訂單信用查核方式, '1', '不檢查', '其他') 訂單信用查核方式名稱,
	A.出貨通知信用查核方式,
	decode(A.出貨通知信用查核方式, '1', '不檢查', '其他') 出貨通知信用查核方式名稱,
	A.銷貨信用查核方式,
	decode(A.銷貨信用查核方式, '1', '不檢查', '其他') 銷貨信用查核方式名稱,
	A.暫出單信用查核方式,
	decode(A.暫出單信用查核方式, '1', '不檢查', '其他') 暫出單信用查核方式名稱,
	A.收付方式 付款條件,
	nvl(D.名稱, ' ') 付款條件名稱,
	A.稅額計算方式,
	decode(A.稅額計算方式, '1', '整張資料計算', '2', '單身單筆資料計算', '其他') 稅額計算方式名稱,
	A.單身多稅率,
	A.隨貨附發票,
	A.訂金比率,
	A.價格條件,
	A.稅別代碼,
	nvl(F.名稱, ' ')  稅別名稱,	
	A.發票類別 發票聯數,
	nvl(G.名稱, ' ') 發票聯數名稱,
	A.課稅別,
	decode(A.課稅別, '2', '應稅外加', '3', '零稅率', '4', '免稅', '9', '不計稅', '其他') 課稅別名稱,
	A.通關方式,
	decode(A.通關方式, '1', '非經海關', '2', '經海關', '其他') 通關方式名稱,
	A.單據發送方式,
	decode(A.單據發送方式, '1', '郵寄', '2', 'FAX', '4', 'eMail', '其他') 單據發送方式名稱,
	A.收付類別 收款方式,
	decode(A.收付類別, '1', '現金', '2', '電匯', '3', '支票', '4', '其他') 收款方式名稱,
	A.票據寄領,
	decode(A.票據寄領, '1', '郵寄', '3', '其他') 票據寄領名稱,
	A.客戶型態,
	nvl(R.名稱, ' ') 型態名稱,
	A.區域代號,
	nvl(L.名稱, ' ') 區域名稱,
	A.國別代號,
	nvl(M.名稱, ' ') 國別名稱,
	A.取價順序,
	A.折扣率,
	A.折扣率預設,
	A.匯至EBC,
	A.EBC申請代號,
	A.結帳日,
	A.匯款總行 付款總行一,
	A.匯款銀行 付款銀行一,
	nvl(E.機構名稱, ' ') 銀行名稱一,
	A.匯款帳號 銀行帳號一,
	A.付款總行二,
	A.付款銀行二,
	nvl(S.機構名稱, ' ') 銀行名稱二,
	A.銀行帳號二,
	A.付款總行三,
	A.付款銀行三,
	nvl(T.機構名稱, ' ') 銀行名稱三,
	A.銀行帳號三,
	A.應收付款科目 帳款科目,
	nvl(H.科目名稱, ' ') 帳款科目名稱,
	A.應收付票科目 票據科目,
	nvl(J.科目名稱, ' ') 票據科目名稱,	
	A.備註,
	A.運輸方式,
	decode(A.運輸方式, '1', '空運', '2', '海運', '3', '海空聯運', '4', '郵寄', '5', '陸運', '7', '自送', '8', '快遞', '其他') 運輸方式名稱,
	A.交易條件,
	decode(A.交易條件, '1', '一般', '其他') 交易條件名稱,
	A.文件郵區一,
	A.文件地址一,
	A.文件郵區二,
	A.文件地址二,
	A.版次,
	A.核准日期,
	A.報價自動回覆,
	A.報價聯絡人,
	A.報價email,
	A.驗報自動回覆,
	A.驗報聯絡人,
	A.驗報email,
	A.設計圖自動回覆,
	A.設計圖聯絡人,
	A.設計圖email,
	A.流水編號,
	A.建立員工,
	nvl(B.員工姓名, ' ') 建立員工姓名,
	A.建立日期,
	A.最後更新者,
	nvl(C.員工姓名, ' ') 更新者姓名,
	A.最後更新日
FROM
	FIL0011 A
	LEFT JOIN FIL0010 B ON A.建立員工 = B.員工編號
	LEFT JOIN FIL0010 C ON A.最後更新者 = C.員工編號
	LEFT JOIN ViewFIL3108 D ON A.收付方式 = D.代碼
	LEFT JOIN FIL0021 E ON A.匯款總行 = E.總機構代碼 AND A.匯款銀行 = E.分支機構代碼 AND E.分支機構代碼 != ' '
	LEFT JOIN ViewFIL310E F ON A.稅別代碼 = F.代碼
	LEFT JOIN ViewFIL3104 G ON A.發票類別 = G.代碼
	LEFT JOIN FIL0018 H ON A.應收付款科目 = H.科目代碼
	LEFT JOIN FIL0018 J ON A.應收付票科目 = J.科目代碼
	LEFT JOIN FIL0010 K ON A.採購人員 = K.員工編號
	LEFT JOIN ViewFIL310F L ON A.區域代號 = L.代碼
	LEFT JOIN ViewFIL310G M ON A.國別代號 = M.代碼
	LEFT JOIN ViewFIL3102 O ON A.交易幣別 = O.代碼
	LEFT JOIN FIL0020 P ON A.部門別 = P.部門編號
	LEFT JOIN FIL0010 Q ON A.收款業務 = Q.員工編號
	LEFT JOIN ViewFIL310I R ON A.客戶型態 = R.代碼
	LEFT JOIN FIL0021 S ON A.付款總行二 = S.總機構代碼 AND  A.付款銀行二 = S.分支機構代碼 AND S.分支機構代碼 != ' '
	LEFT JOIN FIL0021 T ON A.付款總行三 = T.總機構代碼 AND  A.付款銀行三 = T.分支機構代碼 AND T.分支機構代碼 != ' '	
WHERE
	A.廠客 = '2');

-- Oracle user_views
CREATE VIEW "VIEWFIL1015A" ("編號", "序號", "聯絡人", "電話", "分機", "職務", "EMAIL", "行動電話") AS (SELECT
	A.編號,
	0 序號,
	A.聯絡人一 聯絡人,
	A.電話一 電話,
	A.分機一 分機,
	to_char(A.最常職務) 職務,
	A.eMail,
	' ' 行動電話
FROM
	FIL0011 A
WHERE
	A.聯絡人一 != ' '

UNION
	
SELECT
	A.編號,
	1 序號,
	A.聯絡人二,
	A.電話二,
	A.分機二,
	to_char('發票聯絡人'),
	A.eMail,
	' '
FROM
	FIL0011 A
WHERE
	A.聯絡人二 != ' '

UNION

SELECT
	A.廠客編號,
	A.序號,
	A.聯絡人,
	A.電話,
	A.分機,
	to_char(A.職務),
	A.email,
	to_char(A.行動電話)
FROM
	FIL0014 A);

-- Oracle user_views
CREATE VIEW "VIEWFIL1016" ("單據類別", "單據編號", "單據日期", "員工編號", "員工姓名", "請假日期_起", "請假日期_迄", "請假時間_起", "請假時間_迄", "假別代碼", "事由", "填表人", "填表人姓名", "填表日", "最後更新者", "更新者姓名", "最後更新日") AS (                                                                                                                                                SELECT
	A.單據類別,
	A.單據編號,
	A.單據日期,
	A.員工編號,
	nvl(B.員工姓名, ' ') 員工姓名,
	A.請假日期_起,
	A.請假日期_迄,
	A.請假時間_起,
	A.請假時間_迄,
	A.假別代碼,
	A.事由,
	A.填表人,
	nvl(D.員工姓名, ' ') 填表人姓名,
	A.填表日,
	A.最後更新者,
	nvl(C.員工姓名, ' ') 更新者姓名,
	A.最後更新日
FROM
	FIL0016 A
	LEFT JOIN FIL0010 B ON A.員工編號 = B.員工編號
	LEFT JOIN FIL0010 C ON A.最後更新者 = C.員工編號
	LEFT JOIN FIL0010 D ON A.填表人 = D.員工編號);

-- Oracle user_views
CREATE VIEW "VIEWFIL1017" ("從", "從名稱", "到", "到名稱", "換算率", "正反向", "最後更新者", "更新者姓名", "最後更新日") AS (                                                                                                                                                SELECT
	A.從, 
	nvl(C.名稱, ' ') 從名稱,
	A.到, 
	nvl(D.名稱, ' ') 到名稱,
	A.換算率,
	A.正反向,
	A.最後更新者, 
	nvl(B.員工姓名, ' ') 更新者姓名, 
	A.最後更新日 
FROM
	(	
		SELECT 
			A.從, 
			A.到, 
			A.換算率,
			'+' 正反向,
			A.最後更新者, 
			A.最後更新日 
		FROM 
			FIL0017 A

		union

		SELECT 
			A.到 從, 
			A.從 到, 
			round(1/A.換算率,6) 換算率,
			'-' 正反向,
			A.最後更新者, 
			A.最後更新日 
		FROM 
			FIL0017 A
		WHERE
			A.到 != A.從
	) A
	LEFT JOIN FIL0010 B ON A.最後更新者 = B.員工編號
	LEFT JOIN ViewFIL3103 C ON A.從 = C.代碼
	LEFT JOIN ViewFIL3103 D ON A.到 = D.代碼);

-- Oracle user_views
CREATE VIEW "VIEWFIL1018" ("科目代碼", "科目名稱", "建立員工", "建立姓名", "建立日期", "最後更新者", "更新者姓名", "最後更新日") AS (SELECT
	A.科目代碼,
	A.科目名稱,
	A.建立員工,
	nvl(B.員工姓名, ' ') 建立姓名,
	A.建立日期,
	A.最後更新者,
	nvl(C.員工姓名, ' ') 更新者姓名,
	A.最後更新日
FROM
	FIL0018 A
	LEFT JOIN FIL0010 B ON A.建立員工 = B.員工編號
	LEFT JOIN FIL0010 C ON A.最後更新者 = C.員工編號);

-- Oracle user_views
CREATE VIEW "VIEWFIL1019" ("物料編號", "物料品名", "廠商編號", "廠商全名", "廠商料號", "幣別代碼", "幣別名稱", "價格條件", "採購單位", "單位名稱", "單價", "最大供量", "採購人", "採購人姓名", "建立員工", "建立姓名", "建立日期", "最後更新者", "更新者姓名", "最後更新日") AS (SELECT
	A.物料編號,
	nvl(B.品名, ' ') 物料品名,
	A.廠商編號,
	nvl(C.全名, ' ') 廠商全名,
	A.廠商料號,
	A.幣別代碼,
	nvl(D.名稱, ' ') 幣別名稱,
	A.價格條件,
	A.採購單位,
	nvl(F.名稱, ' ') 單位名稱,
	A.單價,
	A.最大供量,
	B.採購人,
	nvl(E.員工姓名, ' ') 採購人姓名,
	A.建立員工,
	nvl(Z1.員工姓名, ' ') 建立姓名,
	A.建立日期,
	A.最後更新者,
	nvl(Z2.員工姓名, ' ') 更新者姓名,
	A.最後更新日
FROM
	FIL0019 A
	INNER JOIN FIL0012 B ON A.物料編號 = B.產品編號
	INNER JOIN FIL0011 C ON A.廠商編號 = C.編號
	LEFT JOIN ViewFIL3102 D ON A.幣別代碼 = D.代碼
	LEFT JOIN FIL0010 E ON B.採購人 = E.員工編號
	LEFT JOIN ViewFIL3103 F ON A.採購單位 = F.代碼
	LEFT JOIN FIL0010 Z1 ON A.建立員工 = Z1.員工編號
	LEFT JOIN FIL0010 Z2 ON A.最後更新者 = Z2.員工編號);

-- Oracle user_views
CREATE VIEW "VIEWFIL1021" ("銀行類別", "類別名稱", "總機構代碼", "總機構名稱", "分支機構代碼", "機構名稱", "地址", "電話", "負責人", "網址", "最後更新者", "更新者姓名", "最後更新日") AS (SELECT
	A.銀行類別,
	A.類別名稱,
	A.總機構代碼,
	A.總機構代碼 || ' '|| nvl(C.機構名稱, ' ') 總機構名稱,
	A.分支機構代碼,
	A.機構名稱,
	A.地址,
	A.電話,
	A.負責人,
	A.網址,
	A.最後更新者,
	nvl(B.員工姓名, ' ') 更新者姓名,
	A.最後更新日
FROM
	FIL0021 A
	LEFT JOIN FIL0010 B ON B.員工編號 = A.最後更新者
	LEFT JOIN FIL0021 C ON C.總機構代碼 = A.總機構代碼 AND C.分支機構代碼 = ' ');

-- Oracle user_views
CREATE VIEW "VIEWFIL1022" ("幣別代碼", "幣別名稱", "匯率日期", "現鈔匯率", "一般匯率", "出口匯率", "進口匯率", "啟用", "即期買入", "即期賣出", "平均匯率", "月平均匯率", "海關買進", "海關賣出", "最後更新者", "更新者姓名", "最後更新日") AS (SELECT
	A.幣別代碼,
	nvl(C.名稱, ' ') 幣別名稱,
	A.匯率日期,
	A.現鈔匯率,
	A.一般匯率,
	A.出口匯率,
	A.進口匯率,
	A.啟用,
	A.即期買入,
	A.即期賣出,
	A.平均匯率,
	A.月平均匯率,
	A.海關買進,
	A.海關賣出,
	A.最後更新者,
	nvl(B.員工姓名, ' ') 更新者姓名,
	A.最後更新日
FROM
	FIL0022 A
	LEFT JOIN FIL0010 B ON B.員工編號 = A.最後更新者
	LEFT JOIN ViewFIL3102 C ON C.代碼 = A.幣別代碼);

-- Oracle user_views
CREATE VIEW "VIEWFIL1022A" ("幣別代碼", "幣別名稱", "匯率月份", "即期買入", "即期賣出", "月平均匯率") AS (SELECT
	A.幣別代碼,
	nvl(B.名稱, ' ') 幣別名稱,
	A.匯率月份,
	round((A.即期買入 / A.筆數),4) 即期買入,
	round((A.即期賣出 / A.筆數),4) 即期賣出,
	round((A.即期買入 + A.即期賣出) / (A.筆數 * 2),4) 月平均匯率
FROM
	(	SELECT
			A.幣別代碼,
			A.匯率月份,
			count(A.匯率月份) 筆數,
			sum(A.即期買入) 即期買入,
			sum(A.即期賣出) 即期賣出
		FROM
			(	SELECT
					A.幣別代碼,
					substr(A.匯率日期, 1, 6) 匯率月份,
					A.即期買入,
					A.即期賣出
				FROM
					FIL0022 A
				WHERE
					A.啟用 = 1
			) A
		GROUP BY
			A.幣別代碼,
			A.匯率月份
	) A
	INNER JOIN ViewFIL3102 B ON A.幣別代碼 = B.代碼);

-- Oracle user_views
CREATE VIEW "VIEWFIL1023" ("費用代碼", "費用名稱", "幣別代碼", "幣別名稱", "金額", "稅額", "付款條件", "付款條件名稱", "建立員工", "建立姓名", "建立日期", "最後更新者", "更新者姓名", "最後更新日") AS (SELECT
	A.費用代碼,
	A.費用名稱,
	A.幣別代碼,
	nvl(B.名稱, ' ') 幣別名稱,
	A.金額,
	A.稅額,
	A.付款條件,
	nvl(C.名稱, ' ') 付款條件名稱,
	A.建立員工,
	nvl(Z1.員工姓名, ' ') 建立姓名,
	A.建立日期,
	A.最後更新者,
	nvl(Z2.員工姓名, ' ') 更新者姓名,
	A.最後更新日
FROM
	FIL0023 A
	LEFT JOIN ViewFIL3102 B ON A.幣別代碼 = B.代碼
	LEFT JOIN ViewFIL3107 C ON A.付款條件 = C.代碼
	LEFT JOIN FIL0010 Z1 ON A.建立員工 = Z1.員工編號
	LEFT JOIN FIL0010 Z2 ON A.最後更新者 = Z2.員工編號);

-- Oracle user_views
CREATE VIEW "VIEWFIL1024" ("條碼", "單別", "單號", "序號", "QRNO", "廠客", "全名", "日期", "料號", "品名", "規格", "幅寬", "接頭數", "數量", "單位", "公司代碼", "公司名稱", "採購單號", "進料單號", "庫別", "庫別名稱", "入料", "驗收倉", "製令單別", "製令單號", "廠商批號", "廠商規格", "庫存異動數", "類別", "製造日期", "批次匯入", "臨時編號", "總批號", "填表人", "填表人姓名", "填表日", "最後更新者", "更新者姓名", "最後更新日") AS (
SELECT 
	A.條碼,
	A.單別,
	A.單號,
	A.序號,
	A.QRNo,
	A.廠客,
	nvl(k.全名, ' ') 全名,
	A.日期,
	A.料號,
	nvl(decode(nvl(J.手動品名,' '),' ',G.品名,J.手動品名),' ') 品名,
	nvl(decode(nvl(J.手動規格,' '),' ',G.規格,J.手動規格),' ') 規格,
	A.幅寬,
	A.接頭數,
	A.數量,
	A.單位,
	A.公司代碼,
	nvl(H.全名, ' ') 公司名稱,
	trim(A.單別) || '-' || trim(A.單號) || '-' || trim(to_char(A.序號, '0000')) 採購單號,
	case when A.單別 = 'C41'
		then trim(A.單別) || '-' || trim(A.單號) || '-' || trim(to_char(A.序號, '0000'))
		else decode(nvl(B.單別, ' '),' ',' ',nvl(B.單別, ' ') || '-' || trim(nvl(B.單號, ' ')) || '-' || trim(to_char(nvl(B.序號, 0), '0000')))
	end 進料單號,
	decode(A.單別, 'C41', nvl(I.倉庫代碼, ' '), nvl(B.倉庫代碼, ' ')) 庫別,
	nvl(F.名稱, ' ') 庫別名稱,
	decode(A.單別, 'C41', 1, decode(B.單號, null, 0, 1)) 入料,
	A.驗收倉,
	'C11' 製令單別,
	SUBSTR(A.條碼,1,INSTR(A.條碼,'_')-1) 製令單號,
	A.廠商批號,
	A.廠商規格,
	A.庫存異動數,
	decode(instr(A.條碼,'_'),0,0,1) 類別,
	decode(A.製造日期,'00000000',A.日期,A.製造日期) 製造日期,
	A.批次匯入,
	A.GUID 臨時編號,
	SUBSTR(A.GUID,1,INSTR(A.GUID,'_')-1) 總批號,
	A.填表人,
	nvl(Z1.員工姓名,' ') 填表人姓名, 
	A.填表日, 
	A.最後更新者,
	nvl(Z2.員工姓名,' ') 更新者姓名, 
	A.最後更新日
FROM 
	FIL0043 A
	/*主檔*/
	INNER JOIN FIL0030 D ON decode(A.單別,'Q01',substr(A.條碼,1,3),A.單別) = D.單據類別 AND A.單號 = D.單據編號
	/*進料明細*/
	LEFT JOIN ViewFIL4A21 B ON A.條碼 = B.批號 AND B.單別 = 'D21' AND B.簽核狀態<>'A'
	/*採購明細*/
	LEFT JOIN FIL0040 I ON A.單別 = I.單據類別 AND A.單號 = I.單據編號 AND A.序號 = I.單據序號
	LEFT JOIN FIL0041 J ON A.單別 = J.單別 AND A.單號 = J.單號 AND A.序號 = J.序號
	/**/
	LEFT JOIN FIL0011 K ON A.廠客 = K.編號
	LEFT JOIN ViewFIL3106 F ON decode(A.單別, 'C41', I.倉庫代碼, B.倉庫代碼) = F.代碼
	LEFT JOIN FIL0012 G ON A.料號 = G.產品編號
	LEFT JOIN ViewFIL0011 H ON A.公司代碼 = H.代碼
	LEFT JOIN FIL0010 Z1 ON A.填表人 = Z1.員工編號
	LEFT JOIN FIL0010 Z2 ON A.最後更新者 = Z2.員工編號
	);

-- Oracle user_views
CREATE VIEW "VIEWFIL1024A" ("條碼") AS (
select distinct 
	條碼 
from 
	fil0044
where
	(條碼 like 'D11%' or 條碼 like 'E11%') and 
	來源 <> ' '
);

-- Oracle user_views
CREATE VIEW "VIEWFIL1024B" ("條碼", "異動數量", "來源", "唯一值", "單別", "單號", "序號", "最後更新日") AS (
SELECT 
	A.條碼,
	A.異動數量,
	A.來源,
	A.唯一值,
	A.單別,
	A.單號,
	A.序號,
	A.最後更新日
FROM
	(SELECT
		to_char(A.文數字4) 條碼,
		C.異動數量*-1 異動數量,
		DECODE(B.製程代碼,'C31A','印刷','C31B','淋膜','C31C','積層','C31D','裁切','C32D','上蠟','C31H','印刷檢品','C31K','裁切檢品','')||'.領用' 來源,
		A.ROWID 唯一值,
		A.單別,
		A.單號,
		A.序號,
		C.最後更新日
	FROM
		FIL0041 A
		INNER JOIN FIL0031 B ON A.單別=B.單別 AND A.單號=B.單號
		INNER JOIN FIL0040 C ON A.單別=C.單據類別 AND A.單號=C.單據編號 AND A.序號=C.單據序號
	WHERE
		A.單別 = 'C41' AND
		(B.製程代碼 BETWEEN 'C31A' AND 'C31D'  OR B.製程代碼 = 'C32D'  OR B.製程代碼 = 'C31H'   OR B.製程代碼 = 'C31K' ) AND 
		C.異動類別 = 'A' AND 
		A.文數字4 <> ' '

	UNION ALL

	SELECT
		to_char(A.文數字5) 條碼,
		C.數值1*-1 異動數量,
		'裁切.領用2' 來源,
		A.ROWID 唯一值,
		A.單別,
		A.單號,
		A.序號,
		C.最後更新日
	FROM
		FIL0041 A
		INNER JOIN FIL0031 B ON A.單別=B.單別 AND A.單號=B.單號
		INNER JOIN FIL0040 C ON A.單別=C.單據類別 AND A.單號=C.單據編號 AND A.序號=C.單據序號
	WHERE
		A.單別 = 'C41' AND
		B.製程代碼 = 'C31D' AND 
		C.異動類別 = 'A' AND 
		A.文數字4 <> ' '	
		
	UNION ALL 

	SELECT 
		TO_CHAR(A.文數字1) 條碼,
		A.贈品數量 異動數量,
		DECODE(B.製程代碼,'C31A','印刷','C31B','淋膜','C31C','積層','C31D','裁切','C32D','上蠟','C31H','印刷檢品','C31K','裁切檢品','')||'.退庫' 來源,
		A.ROWID 唯一值,
		A.單據類別 單別,
		A.單據編號 單號,
		A.單據序號 序號,
		A.最後更新日
	FROM 
		FIL0040 A
		INNER JOIN FIL0031 B ON A.單據類別=B.單別 AND A.單據編號=B.單號
	WHERE
		A.單據類別 = 'C41' AND
		(B.製程代碼 BETWEEN 'C31A' AND 'C31D'  OR B.製程代碼 = 'C32D'  OR B.製程代碼 = 'C31H'   OR B.製程代碼 = 'C31K' ) AND
		A.異動類別 = 'G' AND
		A.文數字1 <> ' '
		
	UNION ALL 

	SELECT 
		to_char(A.文數字4) 條碼,
		C.退庫數量 異動數量,
		DECODE(B.製程代碼,'C31A','印刷','C31B','淋膜','C31C','積層','C32D','上蠟','C31H','印刷檢品','C31K','裁切檢品','')||'.退庫' 來源,
		A.ROWID 唯一值,
		A.單別,
		A.單號,
		A.序號,
		C.最後更新日
	FROM
		FIL0041 A
		INNER JOIN FIL0031 B ON A.單別=B.單別 AND A.單號=B.單號
		INNER JOIN FIL0040 C ON A.單別=C.單據類別 AND A.單號=C.單據編號 AND A.序號=C.單據序號
	WHERE
		A.單別 = 'C41' AND
		(B.製程代碼 BETWEEN 'C31A' AND 'C31C'  OR B.製程代碼 = 'C32D' OR B.製程代碼 = 'C31H'   OR B.製程代碼 = 'C31K' )  AND 
		C.異動類別 = 'A' AND 
		A.文數字4 <> ' ' AND
		C.退庫數量<>0
		
	UNION ALL

	SELECT
		to_char(A.批號) 條碼,
		C.異動單價-C.夾鏈費 異動數量,
		DECODE(B.製程代碼,'C31A','印刷','C31B','淋膜','C31C','積層','C32D','上蠟','C31H','印刷檢品','C31K','裁切檢品','')||'.入庫' 來源,
		A.ROWID 唯一值,
		A.單別,
		A.單號,
		A.序號,
		C.最後更新日
	FROM
		FIL0041 A
		INNER JOIN FIL0031 B ON A.單別=B.單別 AND A.單號=B.單號
		INNER JOIN FIL0040 C ON A.單別=C.單據類別 AND A.單號=C.單據編號 AND A.序號=C.單據序號
	WHERE
		A.單別 = 'C41' AND
		(B.製程代碼 BETWEEN 'C31A' AND 'C31C'  OR B.製程代碼 = 'C32D' OR B.製程代碼 = 'C31H'   OR B.製程代碼 = 'C31K' )  AND 
		C.異動類別 = 'A' AND 
		A.批號 <> ' '	

		
	UNION ALL

	SELECT
		to_char(A.文字一) 條碼,
		A.數字一 異動數量,
		'裁切.入庫' 來源,
		A.ROWID 唯一值,
		A.單別,
		A.單號,
		A.序號,
		C.最後更新日
	FROM
		FIL00401 A
		INNER JOIN FIL0031 B ON A.單別=B.單別 AND A.單號=B.單號
		INNER JOIN FIL0040 C ON A.單別=C.單據類別 AND A.單號=C.單據編號 AND A.序號=C.單據序號
	WHERE
		A.單別 = 'C41' AND
		B.製程代碼 = 'C31D'  AND 
		C.異動類別 = 'A' AND 
		A.文字一 <> ' '
		
	UNION ALL
		
	SELECT
		to_char(A.批號) 條碼,
		C.數值4 異動數量,
		'原材料.驗收' 來源,
		A.ROWID 唯一值,
		A.單別,
		A.單號,
		A.序號,
		C.最後更新日
	FROM
		FIL0041 A
		INNER JOIN FIL0031 B ON A.單別=B.單別 AND A.單號=B.單號
		INNER JOIN FIL0040 C ON A.單別=C.單據類別 AND A.單號=C.單據編號 AND A.序號=C.單據序號
	WHERE
		A.單別 = 'D21' AND
		C.異動類別 = 'A' AND 
		A.批號 <> ' '	
		
	UNION ALL
		
	SELECT
		to_char(A.批號) 條碼,
		C.數值2 異動數量,
		'原材料.裁切材料' 來源,
		A.ROWID 唯一值,
		A.單別,
		A.單號,
		A.序號,
		C.最後更新日
	FROM
		FIL0041 A
		INNER JOIN FIL0040 C ON A.單別=C.單據類別 AND A.單號=C.單據編號 AND A.序號=C.單據序號
	WHERE
		A.單別 = 'E13' AND 
		A.批號 <> ' '	
		
	UNION ALL

	SELECT
		to_char(A.批號) 條碼,
		C.異動數量 異動數量,
		'半成品.入庫' 來源,
		A.ROWID 唯一值,
		A.單別,
		A.單號,
		A.序號,
		C.最後更新日
	FROM
		FIL0041 A
		INNER JOIN FIL0040 C ON A.單別=C.單據類別 AND A.單號=C.單據編號 AND A.序號=C.單據序號
	WHERE
		A.單別 = 'E24' AND
		C.異動類別 = 'A' AND 
		A.批號 <> ' '		
	
	UNION ALL

	SELECT
		to_char(A.批號) 條碼,
		C.數值4*-1 異動數量,
		'原材料.退料' 來源,
		A.ROWID 唯一值,
		A.單別,
		A.單號,
		A.序號,
		C.最後更新日
	FROM
		FIL0041 A
		INNER JOIN FIL0040 C ON A.單別=C.單據類別 AND A.單號=C.單據編號 AND A.序號=C.單據序號
	WHERE
		A.單別 = 'D41' AND
		A.批號 <> ' '		

	UNION ALL

	SELECT
		to_char(A.條碼) 條碼,
		A.庫存異動數 異動數量,
		'客供品.驗收' 來源,
		A.ROWID 唯一值,
		A.單別,
		A.單號,
		A.序號,
		C.最後更新日
	FROM
		FIL0043 A
		INNER JOIN FIL0040 C ON A.單別=C.單據類別 AND A.單號=C.單據編號 AND A.序號=C.單據序號
	WHERE
		A.單別 = 'D51' AND
		A.條碼 <> ' '				
		) A 
	INNER JOIN FIL0043 B ON B.條碼 = A.條碼	
);

-- Oracle user_views
CREATE VIEW "VIEWFIL1024C" ("條碼", "庫存數量") AS (
SELECT 
	A.條碼,
	SUM(A.異動數量) 庫存數量
FROM
	ViewFIL1024B A
GROUP BY
	A.條碼
);

-- Oracle user_views
CREATE VIEW "VIEWFIL1024D" ("條碼", "廠客", "廠客全名", "日期", "料號", "品名", "規格", "單位", "廠商批號", "廠商規格", "轉換後條碼", "製造日期", "驗收倉", "庫存異動數", "單別", "單號", "序號", "製令單別", "製令單號", "採購單號", "進料單號", "填表人", "填表人姓名", "填表日") AS (
SELECT 
	A.條碼,
	A.廠客,
	nvl(K.全名, ' ') 廠客全名,
	A.日期,
	A.料號,
	nvl(decode(J.手動品名,' ',G.品名,J.手動品名),' ') 品名,
	nvl(decode(J.手動規格,' ',G.規格,J.手動規格),' ') 規格,
	A.單位,
	A.廠商批號,
	A.廠商規格,
	A.料號||'^'||REGEXP_SUBSTR(A.條碼, '[^^]+', 1, 2) 轉換後條碼,
	decode(A.製造日期,'00000000',A.日期,A.製造日期) 製造日期,
	A.驗收倉,
	A.庫存異動數,
	A.單別,
	A.單號,
	A.序號,
	'C11' 製令單別,
	SUBSTR(A.條碼,1,INSTR(A.條碼,'_')-1) 製令單號,
	trim(A.單別) || '-' || trim(A.單號) || '-' || trim(to_char(A.序號, '0000')) 採購單號,
	case when A.單別 = 'C41'
		then trim(A.單別) || '-' || trim(A.單號) || '-' || trim(to_char(A.序號, '0000'))
		else decode(nvl(B.單別, ' '),' ',' ',nvl(B.單別, ' ') || '-' || trim(nvl(B.單號, ' ')) || '-' || trim(to_char(nvl(B.序號, 0), '0000')))
	end 進料單號,
	A.填表人,
	nvl(Z1.員工姓名,' ') 填表人姓名, 
	A.填表日
FROM 
	FIL0043 A
	/*進料明細*/
	LEFT JOIN ViewFIL4A21 B ON A.條碼 = B.批號 AND B.單別 = 'D21' AND B.簽核狀態<>'A'
	LEFT JOIN FIL0012 G ON A.料號 = G.產品編號
	LEFT JOIN FIL0041 J ON A.單別 = J.單別 AND A.單號 = J.單號 AND A.序號 = J.序號
	LEFT JOIN FIL0011 K ON A.廠客 = K.編號
	LEFT JOIN FIL0010 Z1 ON A.填表人 = Z1.員工編號
	);

-- Oracle user_views
CREATE VIEW "VIEWFIL1024E" ("條碼", "條碼序號", "列印日期", "列印時間", "列印人代號", "廠商規格", "廠商批號", "來源", "細分", "開立", "單別", "單號", "序號", "已收料") AS (
SELECT
	A.條碼,
	A.序號 條碼序號,
	A.列印日期,
	A.列印時間,
	A.列印人代號,
	A.廠商規格,
	A.廠商批號,
	A.來源,
	A.細分,
	A.開立,
	REGEXP_SUBSTR(A.條碼, '[^-]+', 1, 1) 單別,
	REGEXP_SUBSTR(A.條碼, '[^-]+', 1, 2) 單號,
	NVL(TO_NUMBER(REGEXP_SUBSTR(A.條碼, '[^-]+', 1, 3)),0) 序號,
	DECODE(NVL(B.條碼,' '),' ',0,1) 已收料 
FROM
	FIL0044A A
	LEFT JOIN FIL0043 B ON B.條碼 = A.條碼
  );

-- Oracle user_views
CREATE VIEW "VIEWFIL1024F" ("請領單號", "請領料號", "異動數量") AS (
SELECT 
	A.其它單號 請領單號,
	A.請領料號,
	SUM(A.異動數量) 異動數量
FROM
	FIL0044 A
WHERE
	(A.單據類別='TMP') AND 
	A.其它單號 <> ' ' 
GROUP BY
	A.其它單號,
	A.請領料號
);

-- Oracle user_views
CREATE VIEW "VIEWFIL1024G" ("請領單號", "請領料號", "異動數量") AS (
SELECT 
	A.其它單號 請領單號,
	A.請領料號,
	SUM(A.異動數量) 異動數量
FROM
	FIL0044 A
WHERE
	A.單據類別 = 'C41' AND
	A.來源 = 'I' AND 
	A.其它單號 <> ' ' AND
	A.備註 = '回庫'
GROUP BY
	A.其它單號,
	A.請領料號
);

-- Oracle user_views
CREATE VIEW "VIEWFIL1024H" ("條碼", "首筆序號") AS (
select distinct 
	條碼,
	min(序號) 首筆序號
from 
	fil0044
where
	(條碼 like 'D11%' or 條碼 like 'E11%') and 
	來源 = 'I' 	
Group by 
	條碼
);

-- Oracle user_views
CREATE VIEW "VIEWFIL1024I" ("料號", "管制日期", "刷回數量", "刷回桶數", "刷出數量", "刷出桶數", "日報使用量", "日報使用桶數") AS With 
	/*主檔*/
	Tmp0 AS
	(
	select distinct
		A.料號,
		A.管制日期
	from	
		(select  distinct
			M.料號,
			nvl(to_char(decode(A.其它日期1,'00000000',A.異動日期,A.其它日期1)),'00000000') 管制日期
		from 
			fil0044 A
			inner join FIL0043 M On M.條碼 = A.條碼
			inner join ViewFIL1024h B on B.條碼 = A.條碼 
		where
			(A.條碼 like 'D11%' or A.條碼 like 'E11%') and 
			A.來源 <> ' ' and
			A.序號 <> nvl(B.首筆序號,0) and
			substr(M.料號,1,1)='B'
		
		union all
		
		select  distinct
			M.料號,
			nvl(E.單據日期,'00000000') 管制日期
		from 
			fil0041 A
			inner join FIL0043 M On M.條碼 = A.文數字4
			inner join FIL0040 B on B.單據類別 = A.單別 AND B.單據編號 = A.單號 AND B.單據序號 = A.序號
			inner join FIL0031 D on D.單別 = A.單別 AND D.單號 = A.單號 
			inner join FIL0030 E on E.單據類別 = A.單別 AND E.單據編號 = A.單號
		where
			A.單別 = 'C41' and
			(D.製程代碼 between 'C31A' and 'C31C' or D.製程代碼 = 'C32D') and
			substr(M.料號,1,1)='B') A		
		),		
		
	/*刷回*/
	Tmp1 AS
	(select  
		M.料號,
		nvl(to_char(to_date(A.異動日期,'YYYYMMDD')+(case when A.異動時間>='000000' and A.異動時間<='070000'  then -1 else 0 end),'YYYYMMDD'),'00000000') 管制日期,
		A.來源,
		Count(A.條碼) 桶數,
		sum(M.庫存異動數) 異動數量
	from 
		fil0044 A
		inner join FIL0043 M On M.條碼 = A.條碼
		inner join ViewFIL1024h B on B.條碼 = A.條碼 
	where
		(A.條碼 like 'D11%' or A.條碼 like 'E11%') and 
		A.來源 = 'I' and
		A.序號 <> nvl(B.首筆序號,0) and
		substr(M.料號,1,1)='B' 
	Group by
		M.料號,
		nvl(to_char(to_date(A.異動日期,'YYYYMMDD')+(case when A.異動時間>='000000' and A.異動時間<='070000'  then -1 else 0 end),'YYYYMMDD'),'00000000'),
		A.來源),
		
	/*刷出*/	
	Tmp2 AS
	(select  
		M.料號,
		nvl(to_char(decode(A.其它日期1,'00000000',A.異動日期,A.其它日期1)),'00000000') 管制日期,
		A.來源,
		Count(A.條碼) 桶數,
		sum(abs(M.庫存異動數)) 異動數量
	from 
		fil0044 A
		inner join FIL0043 M On M.條碼 = A.條碼
	where
		(A.條碼 like 'D11%' or A.條碼 like 'E11%') and 
		A.來源 = 'O' and
		substr(M.料號,1,1)='B'
	Group by
		M.料號,
		nvl(to_char(decode(A.其它日期1,'00000000',A.異動日期,A.其它日期1)),'00000000'),
		A.來源),
		
	/*日報領用*/	
	Tmp3 AS
	(select  
		M.料號,
		nvl(E.單據日期,'00000000') 管制日期,
		sum(decode(B.退庫數量,0,1,0	)) 桶數,
		sum(B.異動數量-B.退庫數量-B.毛重) 異動數量
	from 
		fil0041 A
		inner join FIL0043 M On M.條碼 = A.文數字4
		inner join FIL0040 B on B.單據類別 = A.單別 AND B.單據編號 = A.單號 AND B.單據序號 = A.序號
		inner join FIL0031 D on D.單別 = A.單別 AND D.單號 = A.單號 
    	inner join FIL0030 E on E.單據類別 = A.單別 AND E.單據編號 = A.單號
	where
		A.單別 = 'C41' and
		(D.製程代碼 BETWEEN 'C31A' AND 'C31C' or D.製程代碼 = 'C32D') and
		substr(M.料號,1,1)='B' and 
		B.異動類別 = 'E'
	Group by
		M.料號,
		nvl(E.單據日期,'00000000'))		
Select distinct 
	A.料號,
	nvl(A.管制日期,'00000000') 管制日期,
	nvl(B.異動數量,0) 刷回數量,
	nvl(B.桶數,0) 刷回桶數,
	nvl(C.異動數量,0) 刷出數量,
	nvl(C.桶數,0) 刷出桶數,
	nvl(D.異動數量,0) 日報使用量,
	nvl(D.桶數,0) 日報使用桶數
From
	Tmp0 A 
	Left Join Tmp1 B on B.料號 = A.料號 and B.管制日期 = A.管制日期
	Left Join Tmp2 C on C.料號 = A.料號 and C.管制日期 = A.管制日期
	Left Join Tmp3 D on D.料號 = A.料號 and D.管制日期 = A.管制日期
Where
	Substr(A.料號,1,1) = 'B';

-- Oracle user_views
CREATE VIEW "VIEWFIL1024J" ("列印批號", "單據類別", "單據編號", "單據序號") AS With 
	/*主檔*/
	Tmp0 AS
	(select  distinct
		M.列印批號,
		M.條碼
	from 
		fil0044A M
	where
		M.列印批號 like 'QRC%'
	)	
Select distinct 
	A.列印批號,
	REGEXP_SUBSTR(A.條碼, '[^-]+',1) 單據類別,
	REGEXP_SUBSTR(A.條碼, '[^-]+',1,2) 單據編號,
	to_number(REGEXP_SUBSTR(A.條碼, '[^-]+',1,3)) 單據序號
From
	Tmp0 A;

-- Oracle user_views
CREATE VIEW "VIEWFIL1024K" ("條碼", "單別", "單號", "序號", "料號", "數量", "庫存異動數") AS (
SELECT 
	A.條碼,
	A.單別,
	A.單號,
	A.序號,
	A.料號,
	B.數量,
	B.庫存異動數
FROM 
	FIL0043 A
	/*進料明細*/
	INNER JOIN ViewFIL4A21 B ON A.條碼 = B.批號 AND B.單別 = 'D21' AND B.簽核狀態<>'A'
WHERE
  A.條碼<>' '
	);

-- Oracle user_views
CREATE VIEW "VIEWFIL1024L" ("條碼", "日期", "製令單號", "料號", "油墨配比", "色順", "製造日期", "機台號碼", "庫存數", "單別", "單號", "序號", "QRNO", "產品名稱", "加白墨", "填表人姓名", "調色日時", "狀態") AS (
SELECT 
	A.條碼,
	A.日期,	
	A.廠商料號 製令單號,
	A.料號,
	A.廠商批號 油墨配比,
	A.廠商規格 色順,
	A.製造日期 製造日期,
	A.驗收倉 機台號碼,
	DECODE(NVL(B.來源,' '),' ',1,0) 庫存數,
	A.單別,
	A.單號,
	A.序號,
	A.QRNO,
	A.GUID 產品名稱,
	A.選擇 加白墨,
	nvl(Z1.員工姓名,' ') 填表人姓名, 
	A.填表日 調色日時,
	NVL(B.來源,' ') 狀態 
FROM 
	FIL0043 A
	LEFT JOIN 
	(
	SELECT 
		A.批號,
		MAX(A.來源) 來源
	FROM
		ViewFIL404A3A A
	GROUP BY
		A.批號
	) B ON B.批號 = A.條碼
	LEFT JOIN FIL0010 Z1 ON A.填表人 = Z1.員工編號
WHERE
	A.批次匯入 = 1 AND A.條碼 LIKE 'C31A%'
	);

-- Oracle user_views
CREATE VIEW "VIEWFIL1025" ("加熱器序號", "名稱", "製程代碼", "製程名稱", "機台代碼", "機台名稱", "機台序號", "最後更新者", "更新者姓名", "最後更新日") AS (
SELECT 
	A.加熱器序號,
	A.名稱,
	A.製程代碼,
	nvl(B.名稱, ' ') 製程名稱,
	A.機台代碼,
	nvl(C.名稱, ' ') 機台名稱,
	A.機台序號,
	A.最後更新者,
	nvl(Z1.員工姓名,' ') 更新者姓名, 
	A.最後更新日
FROM 
	FIL0047 A
	LEFT JOIN ViewFIL310N B ON A.製程代碼 = B.代碼
	LEFT JOIN ViewFIL310P C ON A.機台代碼 = C.代碼
	LEFT JOIN FIL0010 Z1 ON A.最後更新者 = Z1.員工編號);

-- Oracle user_views
CREATE VIEW "VIEWFIL1026" ("版銅代碼", "入庫日期", "入庫時間", "庫別代碼", "庫別名稱", "歸屬流水編號", "送修", "回廠", "回廠日期", "最後更新者", "更新者姓名", "最後更新日") AS (
SELECT 
	A.版銅代碼,
	A.入庫日期,
	A.入庫時間,
	A.庫別代碼,
	nvl(B.名稱, ' ') 庫別名稱,
	A.歸屬流水編號,
	A.送修,
	A.回廠,
	A.回廠日期,
	A.最後更新者,
	nvl(Z1.員工姓名,' ') 更新者姓名, 
	A.最後更新日
FROM 
	FIL004D A
	LEFT JOIN ViewFIL3106 B ON A.庫別代碼 = B.代碼
	LEFT JOIN FIL0010 Z1 ON A.最後更新者 = Z1.員工編號);

-- Oracle user_views
CREATE VIEW "VIEWFIL1027" ("單據類別", "單據編號", "異動日期", "最後更新日", "版銅編號", "異動類別", "歸屬單別", "歸屬單號", "庫別代碼", "送修", "回廠", "作業人員", "作業人員姓名", "來源", "庫存相關") AS (
Select 
	A.單據類別,
	TO_CHAR(A.單據編號) 單據編號,
	A.異動日期,
	A.最後更新日,
	TO_CHAR(A.產品編號) 版銅編號,
	TO_CHAR(DECODE(A.單位代碼,'A','取版','回收')) 異動類別,
	TO_CHAR(A.前置單別) 歸屬單別,
	TO_CHAR(A.前置單號) 歸屬單號,
	decode(A.單位代碼, 'A', ' ', A.倉庫代碼) 庫別代碼,
	0 送修,
	0 回廠,
	A.最後更新者 作業人員,
	NVL(D.員工姓名,' ') 作業人員姓名,
	to_char('1') 來源,
	0 庫存相關
From	
	FIL0040 A
	INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
	INNER JOIN FIL0030 C ON A.單據類別 = C.單據類別 AND A.單據編號 = C.單據編號
	LEFT JOIN FIL0010 D ON D.員工編號 = A.最後更新者
Where
	A.單據類別 = 'C41' AND 
	B.製程代碼 = 'C32E' AND
	A.單位代碼 between 'A' AND 'B'

UNION ALL 

Select 
	A.單據類別,
	TO_CHAR(A.單據編號) 單據編號,
	C.單據日期,
	A.最後更新日,
	TO_CHAR(A.產品編號) 版銅編號,
	TO_CHAR('送修') 異動類別,
	TO_CHAR('F34') 歸屬單別,
	TO_CHAR(A.文數字1) 歸屬單號,
	' ' 庫別代碼,
	0 送修申請,
	0 回廠,
	A.最後更新者 作業人員,
	NVL(D.員工姓名,' ') 作業人員姓名,
	to_char('2') 來源,
	0 庫存相關
From	
	FIL0040 A
	INNER JOIN FIL0030 C ON A.單據類別 = C.單據類別 AND A.單據編號 = C.單據編號
	LEFT JOIN FIL0010 D ON D.員工編號 = A.最後更新者	
Where
	A.單據類別 = 'F33' 
	
UNION ALL

Select 
	' ' 單據類別,
	TO_CHAR(A.版銅代碼||':'||A.入庫日期||A.入庫時間) 單據編號,
	nvl(decode(A.送修,0,A.入庫日期,C.異動日期),' ') 異動日期,
	A.最後更新日,
	TO_CHAR(A.版銅代碼) 版銅編號,
	TO_CHAR(decode(A.送修,0,decode(instr(A.歸屬流水編號,'送修'),0,'入庫','入庫(送修)'), decode(A.回廠, 0, '出廠未回', '出廠已回'))) 異動類別,
	DECODE(NVL(C.單據編號,' '),' ',' ',TO_CHAR('F33')) 歸屬單別,
	TO_CHAR(NVL(C.單據編號,' ')) 歸屬單號,
	A.庫別代碼,
	A.送修,
	A.回廠,
	A.最後更新者 作業人員,
	NVL(D.員工姓名,' ') 作業人員姓名,
	to_char('3') 來源,
	decode(A.送修,0,1,0) 庫存相關
From	
	FIL004D A
	LEFT JOIN FIL0040 C ON C.單據類別 = 'F33' AND A.歸屬流水編號 = C.流水編號
	LEFT JOIN FIL0010 D ON D.員工編號 = A.最後更新者

UNION ALL

Select 
	' ' 單據類別,
	TO_CHAR(A.版銅代碼)||' '||to_char(A.最後更新日,'yyyymmdd')||to_char(A.序號,'0000000000') 單據編號,
	to_char(A.最後更新日,'yyyymmdd') 異動日期,
	A.最後更新日,
	TO_CHAR(A.版銅代碼) 版銅編號,
	TO_CHAR(decode(A.類別, 'A', '洗版開始', 'B', '洗版', 'C', '停用', ' ')) 異動類別,
	' ' 歸屬單別,
	A.歸屬代碼 歸屬單號,
	' ' 庫別代碼,
	0 送修,
	0 回廠,
	A.最後更新者 作業人員,
	NVL(D.員工姓名,' ') 作業人員姓名,
	to_char('4') 來源,
	0 庫存相關
From	
	FIL004E A
	LEFT JOIN FIL0010 D ON D.員工編號 = A.最後更新者
	
union all

Select 
	' ' 單據類別,
	TO_CHAR(A.歸屬代碼)||' '||to_char(A.最後更新日,'yyyymmdd')||to_char(A.序號,'0000000000') 單據編號,
	to_char(A.最後更新日,'yyyymmdd') 異動日期,
	A.最後更新日,
	TO_CHAR(A.歸屬代碼) 版銅編號,
	TO_CHAR('調入') 異動類別,
	' ' 歸屬單別,
	to_char(A.版銅代碼) 歸屬單號,
	' ' 庫別代碼,
	0 送修,
	0 回廠,
	A.最後更新者 作業人員,
	NVL(D.員工姓名,' ') 作業人員姓名,
	to_char('5') 來源,
	0 庫存相關
From	
	FIL004E A
	LEFT JOIN FIL0010 D ON D.員工編號 = A.最後更新者
WHERE
	A.歸屬代碼 != ' '

union all

Select 
	' ' 單據類別,
	TO_CHAR(A.代碼) 單據編號,
	to_char(' ') 異動日期,
	A.最後更新日,
	TO_CHAR(A.代碼) 版銅編號,
	TO_CHAR('建檔') 異動類別,
	' ' 歸屬單別,
	to_char(A.代碼) 歸屬單號,
	A.庫位代碼 庫別代碼,
	0 送修,
	0 回廠,
	A.最後更新者 作業人員,
	A.更新者姓名 作業人員姓名,
	to_char('6') 來源,
	1 庫存相關
From	
	ViewFIL3112 A
	
union all

Select 
	' ' 單據類別,
	TO_CHAR(A.單據編號)||' '||to_char(A.修改日,'yyyymmdd')||to_char(A.序號,'0000000000') 單據編號,
	to_char(A.修改日,'yyyymmdd') 異動日期,
	A.修改日 最後更新日,
	TO_CHAR(A.單據編號) 版銅編號,
	TO_CHAR('錯誤入庫') 異動類別,
	' ' 歸屬單別,
	to_char(A.單據編號) 歸屬單號,
	to_char(A.說明) 庫別代碼,
	0 送修,
	0 回廠,
	A.修改人 作業人員,
	NVL(D.員工姓名,' ') 作業人員姓名,
	to_char('7') 來源,
	0 庫存相關
From	
	FIL1018 A
	LEFT JOIN FIL0010 D ON D.員工編號 = A.修改人
Where
	A.單據類別 = 'C41.C32E'
	);

-- Oracle user_views
CREATE VIEW "VIEWFIL1027A" ("版銅編號", "最近取版日期") AS (
Select 
	A.產品編號 版銅編號,
	max(A.異動日期) 最近取版日期
From	
	FIL0040 A
	INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
Where
	A.單據類別 = 'C41' AND 
	B.製程代碼 = 'C32E' AND
	A.單位代碼 = 'A' 
Group by 
	A.產品編號
);

-- Oracle user_views
CREATE VIEW "VIEWFIL1027B" ("版銅編號", "異動日期", "異動類別", "單據編號", "來源", "庫別代碼", "最後更新日") AS (
Select 
	TO_CHAR(A.版銅代碼) 版銅編號,
	nvl(A.入庫日期,' ') 異動日期,	
	TO_CHAR(decode(instr(A.歸屬流水編號,'送修'),0,'入庫','入庫(送修)')) 異動類別,	
	TO_CHAR(A.版銅代碼||':'||A.入庫日期||A.入庫時間) 單據編號,	
	to_char('3') 來源,
	A.庫別代碼,
	A.最後更新日
From	
	FIL004D A
	LEFT JOIN FIL0040 C ON C.單據類別 = 'F33' AND A.歸屬流水編號 = C.流水編號
Where
	A.送修 = 0
	
union all

Select 
	TO_CHAR(A.代碼) 版銅編號,
	TO_CHAR(' ') 異動日期,
	TO_CHAR('建檔') 異動類別,
	TO_CHAR(A.代碼) 單據編號,
	to_char('6') 來源,
	A.庫位代碼 庫別代碼,
	A.最後更新日
From	
	ViewFIL3112 A
	);

-- Oracle user_views
CREATE VIEW "VIEWFIL1027C" ("單據編號", "異動日期", "最後更新日", "版銅編號", "異動類別", "送修", "回廠", "來源") AS (
Select 
	TO_CHAR(A.單據編號) 單據編號,
	A.異動日期,
	A.最後更新日,
	TO_CHAR(A.產品編號) 版銅編號,
	TO_CHAR(DECODE(A.單位代碼,'A','取版','回收')) 異動類別,
	0 送修,
	0 回廠,
	to_char('1') 來源
From	
	FIL0040 A
	INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
	INNER JOIN FIL0030 C ON A.單據類別 = C.單據類別 AND A.單據編號 = C.單據編號
	LEFT JOIN FIL0010 D ON D.員工編號 = C.業務員
Where
	A.單據類別 = 'C41' AND 
	B.製程代碼 = 'C32E' AND
	A.單位代碼 between 'A' AND 'B'

UNION ALL 

Select 
	TO_CHAR(A.單據編號) 單據編號,
	C.單據日期,
	A.最後更新日,
	TO_CHAR(A.產品編號) 版銅編號,
	TO_CHAR('送修') 異動類別,
	0 送修申請,
	0 回廠,
	to_char('2') 來源
From	
	FIL0040 A
	INNER JOIN FIL0030 C ON A.單據類別 = C.單據類別 AND A.單據編號 = C.單據編號
	LEFT JOIN FIL0010 D ON D.員工編號 = C.業務員	
Where
	A.單據類別 = 'F33' 
	
UNION ALL

Select 
	TO_CHAR(A.版銅代碼||':'||A.入庫日期||A.入庫時間) 單據編號,
	nvl(decode(A.送修,0,A.入庫日期,C.異動日期),' ') 異動日期,
	A.最後更新日,
	TO_CHAR(A.版銅代碼) 版銅編號,
	TO_CHAR(decode(A.送修,0,decode(instr(A.歸屬流水編號,'送修'),0,'入庫','入庫(送修)'), decode(A.回廠, 0, '出廠未回', '出廠已回'))) 異動類別,
	A.送修,
	A.回廠,
	to_char('3') 來源
From	
	FIL004D A
	LEFT JOIN FIL0040 C ON C.單據類別 = 'F33' AND A.歸屬流水編號 = C.流水編號
	LEFT JOIN FIL0010 D ON D.員工編號 = A.最後更新者

UNION ALL

Select 
	TO_CHAR(A.版銅代碼)||' '||to_char(A.最後更新日,'yyyymmdd')||to_char(A.序號,'0000000000') 單據編號,
	to_char(A.最後更新日,'yyyymmdd') 異動日期,
	A.最後更新日,
	TO_CHAR(A.版銅代碼) 版銅編號,
	TO_CHAR(decode(A.類別, 'A', '洗版開始', 'B', '洗版', 'C', '停用', ' ')) 異動類別,
	0 送修,
	0 回廠,
	to_char('4') 來源
From	
	FIL004E A
	LEFT JOIN FIL0010 D ON D.員工編號 = A.最後更新者
	
union all

Select 
	TO_CHAR(A.歸屬代碼)||' '||to_char(A.最後更新日,'yyyymmdd')||to_char(A.序號,'0000000000') 單據編號,
	to_char(A.最後更新日,'yyyymmdd') 異動日期,
	A.最後更新日,
	TO_CHAR(A.歸屬代碼) 版銅編號,
	TO_CHAR('調入') 異動類別,
	0 送修,
	0 回廠,
	to_char('5') 來源
From	
	FIL004E A
	LEFT JOIN FIL0010 D ON D.員工編號 = A.最後更新者
WHERE
	A.歸屬代碼 != ' '
	);

-- Oracle user_views
CREATE VIEW "VIEWFIL2010" ("單據類別", "單據編號", "單據日期", "訂單號碼", "採購單號", "歸屬類別", "歸屬編號", "歸屬序號", "公司代碼", "簽核系統", "簽核系統_結案", "廠客編號", "廠客簡稱", "廠客全名", "折讓", "備註", "業務員", "業務員姓名", "幣別代碼", "幣別名稱", "稅別", "稅率", "匯率", "匯率日期", "匯率類別", "廠客單號", "廠別編號", "廠別名稱", "部門編號", "部門名稱", "收付方式", "確認碼", "流水編號", "填表人", "填表人姓名", "填表日", "最後更新者", "更新者姓名", "最後更新日", "簽核狀態", "發函代理人", "代理人姓名", "簽核狀態_結案", "發函代理人_結案", "代理人姓名_結案") AS (                                                                                                                                                      SELECT 
	A.單據類別, 
	A.單據編號, 
	A.單據日期,
	A.訂單號碼,
	A.採購單號,
	A.歸屬類別,
	A.歸屬編號,
	A.歸屬序號,
	A.公司代碼,
	A.簽核系統, 
	A.簽核系統_結案, 
	A.廠客編號,
	nvl(I.簡稱, ' ') 廠客簡稱,
	nvl(I.全名, ' ') 廠客全名,
	A.折讓,
	A.備註, 
	A.業務員,
	nvl(L.員工姓名,' ') 業務員姓名, 	
	A.幣別代碼,
	nvl(M.名稱, ' ') 幣別名稱,
	A.稅別,
	A.稅率,
	A.匯率,
	A.匯率日期,
	A.匯率類別,
	A.廠客單號,
	A.廠別編號,
	nvl(M.廠別名稱, ' ') 廠別名稱,
	A.部門編號,
	nvl(N.部門名稱, ' ') 部門名稱,
	A.收付方式,
	A.確認碼,
	A.流水編號,
	A.填表人,
	nvl(F.員工姓名,' ') 填表人姓名, 
	A.填表日, 
	A.最後更新者,
	nvl(G.員工姓名,' ') 更新者姓名, 
	A.最後更新日,
	nvl(H.簽核狀態, ' ') 簽核狀態,
	nvl(D.發函代理人, ' ') 發函代理人,
	nvl(D.代理人姓名, ' ') 代理人姓名,
	nvl(E.簽核狀態, ' ') 簽核狀態_結案,
	nvl(E.發函代理人, ' ') 發函代理人_結案,
	nvl(E.代理人姓名, ' ') 代理人姓名_結案
FROM 
	FIL0030 A
	LEFT JOIN FIL0011 I ON A.廠客編號 = I.編號
	LEFT JOIN FIL0010 L ON A.業務員 = L.員工編號
	LEFT JOIN ViewFIL3102 M ON A.幣別代碼 = M.代碼
	LEFT JOIN FIL0010 F ON A.填表人 = F.員工編號
	LEFT JOIN FIL0010 G ON A.最後更新者 = G.員工編號
	LEFT JOIN ViewFIL0030 D ON A.單據編號 = D.單號 AND A.簽核系統 = D.簽核系統
	LEFT JOIN ViewFIL0030 E ON A.單據編號 = E.單號 AND A.簽核系統_結案 = E.簽核系統
	LEFT JOIN FIL0013 M ON A.廠別編號 = M.廠別編號
	LEFT JOIN FIL0020 N ON A.部門編號 = N.部門編號
	LEFT JOIN ViewOfObjProperties H ON A.流水編號 = H.單據流水號);

-- Oracle user_views
CREATE VIEW "VIEWFIL2010_A" ("單據類別", "單據編號", "填表人姓名", "更新者姓名", "簽核狀態") AS (    
SELECT 
	A.單據類別, 
	A.單據編號, 
	nvl(F.員工姓名,' ') 填表人姓名, 
	nvl(G.員工姓名,' ') 更新者姓名, 
	nvl(H.簽核狀態, ' ') 簽核狀態
FROM 
	FIL0030 A
	LEFT JOIN FIL0010 F ON A.填表人 = F.員工編號
	LEFT JOIN FIL0010 G ON A.最後更新者 = G.員工編號
	LEFT JOIN ViewOfObjProperties H ON A.流水編號 = H.單據流水號);

-- Oracle user_views
CREATE VIEW "VIEWFIL2010_B" ("單據類別", "單據編號", "單據日期", "流水編號", "歸屬編號", "製程代碼", "簽核狀態") AS (                                                                                                                                                      SELECT 
	A.單據類別, 
	A.單據編號, 
	A.單據日期,
	A.流水編號,  歸屬編號,
	NVL(B.製程代碼,' ') 製程代碼, 
	nvl(H.簽核狀態, ' ') 簽核狀態
FROM 
	FIL0030 A
	LEFT JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
	LEFT JOIN ViewOfObjProperties H ON A.流水編號 = H.單據流水號
	);

-- Oracle user_views
CREATE VIEW "VIEWFIL2011" ("單別", "單號", "最後序號") AS (                                                                                                                                                      SELECT 
	A.單據類別 單別, 
	A.單據編號 單號,
	max(A.單據序號) 最後序號
FROM 
	FIL0040 A
	INNER JOIN FIL0030 M ON A.單據類別 = M.單據類別 AND A.單據編號 = M.單據編號
GROUP BY
	A.單據類別, 
	A.單據編號);

-- Oracle user_views
CREATE VIEW "VIEWFIL2020" ("單據類別", "單據編號", "單據序號", "異動類別", "異動日期", "異動數量", "贈品數量", "異動單價", "異動金額", "備註說明", "產品編號", "產品品名", "廠客品號", "單位代碼", "單位名稱", "倉庫代碼", "倉庫名稱", "庫存參數", "折扣率", "毛重", "材積", "折讓", "預交日", "前置單別", "前置單號", "結案碼", "製版費", "燙金費", "雷射費", "流水編號", "最後更新者", "更新者姓名", "最後更新日") AS (
SELECT 
	A.單據類別, 
	A.單據編號,
	A.單據序號,
	A.異動類別,
	A.異動日期,
	A.異動數量,
	A.贈品數量,
	A.異動單價,
	A.異動金額,
	A.備註說明,
	A.產品編號,
	nvl(D.品名, ' ') 產品品名,
	A.廠客品號,
	A.單位代碼,
	nvl(E.名稱, ' ') 單位名稱,
	A.倉庫代碼,
	' ' 倉庫名稱,
	B.產品庫存參數 庫存參數,
	A.折扣率,
	A.毛重,
	A.材積,
	A.折讓,
	A.預交日,
	A.前置單別,
	A.前置單號,
	A.結案碼,
	A.製版費,
	A.燙金費,
	A.雷射費,
	A.流水編號,
	A.最後更新者,
	NVL(C.員工姓名,' ') 更新者姓名,
	A.最後更新日
FROM 
	FIL0040 A
	INNER JOIN ViewFIL0020 B ON A.單據類別 = B.單據類別
	LEFT JOIN FIL0010 C ON A.最後更新者 = C.員工編號
	LEFT JOIN FIL0012 D ON A.產品編號 = D.產品編號
	LEFT JOIN ViewFIL3103 E ON A.單位代碼 = E.代碼);

-- Oracle user_views
CREATE VIEW "VIEWFIL2021" ("單別", "單號", "序號", "異動日期", "異動數量", "贈品數量", "產品編號", "單位代碼", "庫存單位", "倉庫代碼", "庫存參數", "換算率", "異動數") AS (SELECT 
	A.單據類別 單別, 
	A.單據編號 單號,
	A.單據序號 序號,
	decode(A.異動日期, '00000000', D.單據日期, A.異動日期) 異動日期,
	A.異動數量,
	A.贈品數量,
	A.產品編號,
	A.單位代碼,
	C.單位代碼 庫存單位,
	A.倉庫代碼,
	B.產品庫存參數 庫存參數,
	nvl(E.換算率, 1) 換算率,
	(A.異動數量 + A.贈品數量) * B.產品庫存參數 * nvl(E.換算率, 1) 異動數
FROM 
	FIL0040 A
	INNER JOIN ViewFIL0020 B ON A.單據類別 = B.單據類別 AND B.產品庫存參數 != 0
	INNER JOIN FIL0012 C ON A.產品編號 = C.產品編號
	INNER JOIN FIL0030 D ON A.單據類別 = D.單據類別 AND A.單據編號 = D.單據編號
	LEFT JOIN ViewFIL1017 E ON A.單位代碼 = E.從 AND C.單位代碼 = E.到);

-- Oracle user_views
CREATE VIEW "VIEWFIL2022" ("單別", "單號", "序號", "異動日期", "異動數量", "贈品數量", "材料編號", "單位代碼", "庫存單位", "倉庫代碼", "庫存參數", "換算率", "異動數", "前置單別", "前置單號", "批號", "採購單別", "採購單號", "採購序號", "備註說明", "廠商批號") AS with temp1 as (
SELECT 
	A.單據類別 單別, 
	A.單據編號 單號,
	A.單據序號 序號,
	decode(A.異動日期, '00000000', D.單據日期, A.異動日期) 異動日期,
	decode(A.單據類別,'D21',A.數值4,A.異動數量) 異動數量,
	A.贈品數量,
	A.產品編號 材料編號,
	A.單位代碼,
	nvl(C.單位代碼, ' ') 庫存單位,
	A.倉庫代碼,
	B.材料庫存參數 庫存參數,
	1 換算率,
	decode(A.單據類別,'D21',A.數值4,(A.異動數量 + A.贈品數量) * B.材料庫存參數) 異動數,
	nvl(A.前置單別,' ') 前置單別,
	nvl(A.前置單號,' ') 前置單號,
	nvl(F.批號, ' ') 批號,
	REGEXP_SUBSTR(nvl(F.批號, ' '), '[^-]+', 1,1) 採購單別,
	REGEXP_SUBSTR(nvl(F.批號, ' '), '[^-]+', 1,2) 採購單號,
	to_number(REGEXP_SUBSTR(nvl(F.批號, ' '), '[^-]+', 1,3),'9999') 採購序號,
	to_char(A.備註說明) 備註說明,
	nvl(G.廠商批號,' ') 廠商批號
FROM 
	FIL0040 A
	/*庫存參數*/
	INNER JOIN ViewFIL0020 B ON A.單據類別 = B.單據類別 AND B.材料庫存參數 != 0
	/*主檔*/
	INNER JOIN FIL0030 D ON A.單據類別 = D.單據類別 AND A.單據編號 = D.單據編號
	/*品號檔*/
	INNER JOIN VIEWFIL1012 C ON A.產品編號 = C.產品編號 AND C.產品類別 between 'M' and 'P'
	/*單位換算
	LEFT JOIN ViewFIL1017 E ON A.單位代碼 = E.從 AND C.單位代碼 = E.到
	*/
	/*特殊欄位*/
	LEFT JOIN FIL0041 F ON A.單據類別 = F.單別 AND A.單據編號 = F.單號 AND A.單據序號 = F.序號
	/*廠商批號*/
	LEFT JOIN FIL0043 G ON nvl(F.批號, ' ')=G.條碼
	/*簽核*/
	LEFT JOIN ViewOfObjProperties H ON H.單據流水號 = D.流水編號
WHERE
	A.產品編號 != ' ' and
	(A.單據類別 = 'D21' and A.異動類別='A' or A.單據類別 <> 'D21') and
	NVL(H.簽核狀態,' ')<>'A'
	
UNION ALL

/*領料*/
SELECT 
	A.單據類別 單別, 
	A.單據編號 單號,
	A.單據序號 + 5000 序號,
	A.異動日期,
	A.異動數量,
	0 贈品數量,
	A.產品編號 材料編號,
	A.單位代碼,
	nvl(G.單位代碼, ' ') 庫存單位,
	F.庫位代碼 倉庫代碼,
	1 庫存參數,
	1 換算率,
	A.異動數量 異動數,
	nvl(E.歸屬類別,' ') 前置單別,
	nvl(E.歸屬編號,' ') 前置單號,
	nvl(C.批號,' ') 批號,
	REGEXP_SUBSTR(C.批號, '[^-]+', 1,1) 採購單別,
	REGEXP_SUBSTR(C.批號, '[^-]+', 1,2) 採購單號,
	to_number(REGEXP_SUBSTR(C.批號, '[^-]+', 1,3),'9999') 採購序號,
	to_char(A.備註說明) 備註說明,
	nvl(G.廠商批號,' ') 廠商批號
FROM 
	FIL0040 A
	INNER JOIN FIL0041 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號 AND A.單據序號 = C.序號
	INNER JOIN FIL0031 D ON A.單據類別 = D.單別 AND A.單據編號 = D.單號
	INNER JOIN FIL0030 E ON A.單據類別 = E.單據類別 AND A.單據編號 = E.單據編號
	LEFT JOIN ViewFIL310P F ON D.機台代碼 = F.代碼
	LEFT JOIN VIEWFIL1012 G ON A.產品編號 = G.產品編號
	/*單位換算
	LEFT JOIN ViewFIL1017 H ON A.單位代碼 = H.從 AND G.單位代碼 = H.到
	*/
	/*廠商批號*/
	LEFT JOIN FIL0043 G ON C.批號 = G.條碼
WHERE
	A.單據類別 = 'C4M' AND
	A.產品編號 != ' '

UNION ALL

/*材料領用,報廢,油墨領用*/
SELECT 
	A.單據類別 單別, 
	A.單據編號 單號,
	A.單據序號 序號,
	A.異動日期,
	A.異動數量,
	0 贈品數量,
	A.產品編號 材料編號,
	A.單位代碼,
	nvl(D.單位代碼, ' ') 庫存單位,
	A.倉庫代碼,
	-1 庫存參數,
	1 換算率,
	A.異動數量 * -1 異動數,
	nvl(C1.歸屬類別,' ') 前置單別,
	nvl(C1.歸屬編號,' ') 前置單號,
	nvl(B.批號,' ') 批號,
	REGEXP_SUBSTR(B.批號, '[^-]+', 1,1) 採購單別,
	REGEXP_SUBSTR(B.批號, '[^-]+', 1,2) 採購單號,
	to_number(REGEXP_SUBSTR(B.批號, '[^-]+', 1,3),'9999') 採購序號,
	to_char(decode(A.異動類別, 'C', '領用', 'D', '報廢', 'E', '油墨領用', ' ')) 備註說明,
	nvl(G.廠商批號,' ') 廠商批號
FROM 
	FIL0040 A
	INNER JOIN FIL0041 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號 AND A.單據序號 = B.序號
	INNER JOIN FIL0031 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號
	INNER JOIN FIL0030 C1 ON A.單據類別 = C1.單據類別 AND A.單據編號 = C1.單據編號
	INNER JOIN VIEWFIL1012 D ON A.產品編號 = D.產品編號
	/*單位換算
	LEFT JOIN ViewFIL1017 E ON A.單位代碼 = E.從 AND D.單位代碼 = E.到
	*/
	/*廠商批號*/
	LEFT JOIN FIL0043 G ON B.批號 = G.條碼
WHERE
	A.單據類別 = 'C41' AND
	A.異動類別 between 'C' and 'E' AND
	A.異動數量 != 0 AND
	A.產品編號 != ' '
	
UNION ALL

/*印刷日報領用*/
SELECT 
	A.單據類別 單別, 
	A.單據編號 單號,
	A.單據序號 序號,
	A.異動日期,
	A.異動數量,
	0 贈品數量,
	to_char(A.前製程編號) 材料編號,
	A.單位代碼,
	nvl(D.單位代碼, ' ') 庫存單位,
	A.倉庫代碼,
	-1 庫存參數,
	1 換算率,
	(A.異動數量-A.退庫數量) * -1 異動數,
	nvl(C1.歸屬類別,' ') 前置單別,
	nvl(C1.歸屬編號,' ') 前置單號,
	to_char(B.文數字4) 批號,
	REGEXP_SUBSTR(to_char(B.文數字4), '[^-]+', 1,1) 採購單別,
	REGEXP_SUBSTR(to_char(B.文數字4), '[^-]+', 1,2) 採購單號,
	to_number(REGEXP_SUBSTR(to_char(B.文數字4), '[^-]+', 1,3),'9999') 採購序號,
	to_char('印刷領用') 備註說明,
	nvl(G.廠商批號,' ') 廠商批號
FROM 
	FIL0040 A
	INNER JOIN FIL0041 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號 AND A.單據序號 = B.序號
	INNER JOIN FIL0031 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號
	INNER JOIN FIL0030 C1 ON A.單據類別 = C1.單據類別 AND A.單據編號 = C1.單據編號
	INNER JOIN VIEWFIL1012 D ON to_char(A.前製程編號) = D.產品編號
	/*單位換算
	LEFT JOIN ViewFIL1017 E ON A.單位代碼 = E.從 AND D.單位代碼 = E.到
	*/
	/*廠商批號*/
	LEFT JOIN FIL0043 G ON B.批號 = G.條碼
WHERE
	A.單據類別 = 'C41' AND
	A.異動數量 > 0 AND
	C.製程代碼 = 'C31A' AND 
	A.前製程編號 != ' '
	
UNION ALL

/*材料領用.氣閥.鐵條-批號1*/
SELECT 
	A.單據類別 單別, 
	A.單據編號 單號,
	A.單據序號 序號,
	A.異動日期,
	B.數值1 異動數量,
	0 贈品數量,
	D.料號 材料編號,
	A.單位代碼,
	A.單位代碼 庫存單位,
	A.倉庫代碼,
	-1 庫存參數,
	1 換算率,
	B.數值1 * -1 異動數,
	nvl(C1.歸屬類別,' ') 前置單別,
	nvl(C1.歸屬編號,' ') 前置單號,
	nvl(B.文數字1,' ') 批號,
	REGEXP_SUBSTR(B.文數字1, '[^-]+', 1,1) 採購單別,
	REGEXP_SUBSTR(B.文數字1, '[^-]+', 1,2) 採購單號,
	to_number(REGEXP_SUBSTR(B.文數字1, '[^-]+', 1,3),'9999') 採購序號,
	to_char(decode(C.製程代碼, 'C31F', '領用氣閥', 'C31G', '領用鐵條', ' ')) 備註說明,
	nvl(G.廠商批號,' ') 廠商批號
FROM 
	FIL0040 A
	INNER JOIN FIL0041 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號 AND A.單據序號 = B.序號
	INNER JOIN FIL0031 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號
	INNER JOIN FIL0030 C1 ON A.單據類別 = C1.單據類別 AND A.單據編號 = C1.單據編號
	INNER JOIN ViewFIL1024 D ON B.文數字1 = D.條碼
	INNER JOIN VIEWFIL1012 E ON D.料號 = E.產品編號
	/*廠商批號*/
	LEFT JOIN FIL0043 G ON B.文數字1=G.條碼
WHERE
	A.單據類別 = 'C41' AND
	A.異動類別 = 'A' AND
	C.製程代碼 between 'C31F' and 'C31G' AND
	B.文數字1 != ' ' AND
	D.料號 != ' '

UNION ALL
	
/*材料領用.氣閥.鐵條-批號2*/
SELECT 
	A.單據類別 單別, 
	A.單據編號 單號,
	A.單據序號+9000 序號,
	A.異動日期,
	B.數值2 異動數量,
	0 贈品數量,
	D.料號 材料編號,
	A.單位代碼,
	A.單位代碼 庫存單位,
	A.倉庫代碼,
	-1 庫存參數,
	1 換算率,
	B.數值2 * -1 異動數,
	nvl(C1.歸屬類別,' ') 前置單別,
	nvl(C1.歸屬編號,' ') 前置單號,
	nvl(B.文數字2,' ') 批號,
	REGEXP_SUBSTR(B.文數字2, '[^-]+', 1,1) 採購單別,
	REGEXP_SUBSTR(B.文數字2, '[^-]+', 1,2) 採購單號,
	to_number(REGEXP_SUBSTR(B.文數字2, '[^-]+', 1,3),'9999') 採購序號,
	to_char(decode(C.製程代碼, 'C31F', '領用氣閥', 'C31G', '領用鐵條', ' ')) 備註說明,
	nvl(G.廠商批號,' ') 廠商批號
FROM 
	FIL0040 A
	INNER JOIN FIL0041 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號 AND A.單據序號 = B.序號
	INNER JOIN FIL0031 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號
	INNER JOIN FIL0030 C1 ON A.單據類別 = C1.單據類別 AND A.單據編號 = C1.單據編號
	INNER JOIN ViewFIL1024 D ON B.文數字2 = D.條碼
	INNER JOIN VIEWFIL1012 E ON D.料號 = E.產品編號
	/*廠商批號*/
	LEFT JOIN FIL0043 G ON B.文數字2 = G.條碼 
WHERE
	A.單據類別 = 'C41' AND
	A.異動類別 = 'A' AND
	C.製程代碼 between 'C31F' and 'C31G' AND
	B.文數字2 != ' ' AND
	D.料號 != ' '
	
UNION ALL

/*發料回庫(-)
SELECT 
	A.單據類別 單別, 
	A.單據編號 單號,
	A.單據序號 + 5100 序號,
	A.異動日期,
	A.贈品數量 異動數量,
	0 贈品數量,
	A.產品編號 材料編號,
	A.單位代碼,
	nvl(C.單位代碼, ' ') 庫存單位,
	A.倉庫代碼,
	-1 庫存參數,
	1 換算率,
	A.贈品數量 * -1 異動數,
	' ' 前置單別,
	' ' 前置單號,
	nvl(B.批號,' ') 批號,
	REGEXP_SUBSTR(B.批號, '[^-]+', 1,1) 採購單別,
	REGEXP_SUBSTR(B.批號, '[^-]+', 1,2) 採購單號,
	to_number(REGEXP_SUBSTR(B.批號, '[^-]+', 1,3),'9999') 採購序號,
	to_char('餘料回庫') 備註說明,
	nvl(G.廠商批號,' ') 廠商批號
FROM 
	FIL0040 A
	INNER JOIN FIL0041 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號 AND A.單據序號 = B.序號
	LEFT JOIN VIEWFIL1012 C ON A.產品編號 = C.產品編號
	LEFT JOIN FIL0043 G ON B.批號 = G.條碼
WHERE
	A.單據類別 = 'C41' AND
	A.異動類別 = 'C' AND
	A.贈品數量 != 0 AND
	A.產品編號 != ' '

UNION ALL
*/

/*發料回庫(+)*/
SELECT 
	A.單據類別 單別, 
	A.單據編號 單號,
	A.單據序號 + 5200 序號,
	A.異動日期,
	A.贈品數量 異動數量,
	0 贈品數量,
	A.產品編號 材料編號,
	A.單位代碼,
	nvl(C.單位代碼, ' ') 庫存單位,
	A.前置單別 倉庫代碼,
	1 庫存參數,
	1 換算率,
	A.贈品數量 * 1 異動數,
	' ' 前置單別,
	' ' 前置單號,
	nvl(B.批號,' ') 批號,
	REGEXP_SUBSTR(B.批號, '[^-]+', 1,1) 採購單別,
	REGEXP_SUBSTR(B.批號, '[^-]+', 1,2) 採購單號,
	to_number(REGEXP_SUBSTR(B.批號, '[^-]+', 1,3),'9999') 採購序號,
	to_char('餘料回庫') 備註說明,
	nvl(G.廠商批號,' ') 廠商批號
FROM 
	FIL0040 A
	INNER JOIN FIL0041 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號 AND A.單據序號 = B.序號
	LEFT JOIN VIEWFIL1012 C ON A.產品編號 = C.產品編號
	/*單位換算
	LEFT JOIN ViewFIL1017 E ON A.單位代碼 = E.從 AND C.單位代碼 = E.到
	*/
	/*廠商批號*/
	LEFT JOIN FIL0043 G ON B.批號 = G.條碼
WHERE
	A.單據類別 = 'C41' AND
	A.異動類別 = 'C' AND
	A.贈品數量 != 0 AND
	A.產品編號 != ' '
	
/*廠內盤點調整*/
UNION ALL

SELECT 
	A.單據類別 單別, 
	A.單據編號 單號,
	A.單據序號 序號,
	A.異動日期,
	0 異動數量,
	A.贈品數量,
	A.產品編號 材料編號,
	nvl(E.單位代碼, ' ') 單位代碼,
	nvl(E.單位代碼, ' ') 庫存單位,
	' ' 倉庫代碼,
	1 庫存參數,
	1 換算率,
	(A.異動數量 + A.贈品數量) 異動數,
	' ' 前置單別,
	' ' 前置單號,
	nvl(C.批號,' ') 批號,
	REGEXP_SUBSTR(C.批號, '[^-]+', 1,1) 採購單別,
	REGEXP_SUBSTR(C.批號, '[^-]+', 1,2) 採購單號,
	to_number(REGEXP_SUBSTR(C.批號, '[^-]+', 1,3),'9999') 採購序號,
	to_char('盤點調整') 備註說明,
	nvl(G.廠商批號,' ') 廠商批號
FROM 
	FIL0040 A
	INNER JOIN FIL0030 B ON A.單據類別 = B.單據類別 AND A.單據編號 = B.單據編號
	/*特殊欄位*/
	INNER JOIN FIL0041 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號 AND A.單據序號 = C.序號
	LEFT JOIN VIEWFIL1012 E ON A.產品編號 = E.產品編號
	/*廠商批號*/
	LEFT JOIN FIL0043 G ON C.批號 = G.條碼
WHERE
	A.單據類別 = 'F32' AND
	A.異動類別 = '2')
select "單別","單號","序號","異動日期","異動數量","贈品數量","材料編號","單位代碼","庫存單位","倉庫代碼","庫存參數","換算率","異動數","前置單別","前置單號","批號","採購單別","採購單號","採購序號","備註說明","廠商批號" from temp1;

-- Oracle user_views
CREATE VIEW "VIEWFIL2022A" ("單別", "單號", "序號", "異動日期", "異動數量", "材料編號", "更新日時") AS (
SELECT 
	A.單據類別 單別, 
	A.單據編號 單號,
	A.單據序號 序號,
	A.異動日期,
	decode(A.單據類別,'D21',A.數值4,(A.異動數量 + A.贈品數量) * B.材料庫存參數) 異動數量,
	A.產品編號 材料編號,
	TO_CHAR(A.最後更新日,'YYYYMMDDHH24MISS') 更新日時
FROM 
	FIL0040 A
	/*庫存參數*/
	INNER JOIN ViewFIL0020 B ON A.單據類別 = B.單據類別 AND B.材料庫存參數 != 0
	/*主檔*/
	INNER JOIN FIL0030 D ON A.單據類別 = D.單據類別 AND A.單據編號 = D.單據編號
	/*品號檔*/
	INNER JOIN FIL0012 C ON A.產品編號 = C.產品編號 AND C.產品類別 between 'M' and 'P'
WHERE
	A.產品編號 != ' ' and
	(A.單據類別 = 'D21' and A.異動類別='A' or A.單據類別 <> 'D21')

UNION ALL

/*領料*/
SELECT 
	A.單據類別 單別, 
	A.單據編號 單號,
	A.單據序號 + 5000 序號,
	A.異動日期,
	A.異動數量,
	A.產品編號 材料編號,
	TO_CHAR(A.最後更新日,'YYYYMMDDHH24MISS') 更新日時
FROM 
	FIL0040 A
	INNER JOIN FIL0041 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號 AND A.單據序號 = C.序號
	INNER JOIN FIL0031 D ON A.單據類別 = D.單別 AND A.單據編號 = D.單號
	INNER JOIN FIL0030 E ON A.單據類別 = E.單據類別 AND A.單據編號 = E.單據編號
WHERE
	A.單據類別 = 'C4M' AND
	A.產品編號 != ' '

UNION ALL

/*材料領用,報廢,油墨領用*/
SELECT 
	A.單據類別 單別, 
	A.單據編號 單號,
	A.單據序號 序號,
	A.異動日期,
	A.異動數量*-1 異動數量,
	A.產品編號 材料編號,
	TO_CHAR(A.最後更新日,'YYYYMMDDHH24MISS') 更新日時
FROM 
	FIL0040 A
	INNER JOIN FIL0041 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號 AND A.單據序號 = B.序號
	INNER JOIN FIL0031 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號
	INNER JOIN FIL0030 C1 ON A.單據類別 = C1.單據類別 AND A.單據編號 = C1.單據編號
	INNER JOIN FIL0012 D ON A.產品編號 = D.產品編號
WHERE
	A.單據類別 = 'C41' AND
	A.異動類別 between 'C' and 'E' AND
	A.異動數量 != 0 AND
	A.產品編號 != ' '
	
UNION ALL

/*材料領用.氣閥.鐵條-批號1*/
SELECT 
	A.單據類別 單別, 
	A.單據編號 單號,
	A.單據序號 序號,
	A.異動日期,
	B.數值1*-1 異動數量,
	D.料號 材料編號,
	TO_CHAR(A.最後更新日,'YYYYMMDDHH24MISS') 更新日時
FROM 
	FIL0040 A
	INNER JOIN FIL0041 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號 AND A.單據序號 = B.序號
	INNER JOIN FIL0031 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號
	INNER JOIN FIL0030 C1 ON A.單據類別 = C1.單據類別 AND A.單據編號 = C1.單據編號
	INNER JOIN ViewFIL1024 D ON B.文數字1 = D.條碼
WHERE
	A.單據類別 = 'C41' AND
	A.異動類別 = 'A' AND
	C.製程代碼 between 'C31F' and 'C31G' AND
	B.文數字1 != ' ' AND
	D.料號 != ' '

UNION ALL
	
/*材料領用.氣閥.鐵條-批號2*/
SELECT 
	A.單據類別 單別, 
	A.單據編號 單號,
	A.單據序號+9000 序號,
	A.異動日期,
	B.數值2*-1 異動數量,
	D.料號 材料編號,
	TO_CHAR(A.最後更新日,'YYYYMMDDHH24MISS') 更新日時
FROM 
	FIL0040 A
	INNER JOIN FIL0041 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號 AND A.單據序號 = B.序號
	INNER JOIN FIL0031 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號
	INNER JOIN FIL0030 C1 ON A.單據類別 = C1.單據類別 AND A.單據編號 = C1.單據編號
	INNER JOIN ViewFIL1024 D ON B.文數字2 = D.條碼
WHERE
	A.單據類別 = 'C41' AND
	A.異動類別 = 'A' AND
	C.製程代碼 between 'C31F' and 'C31G' AND
	B.文數字2 != ' ' AND
	D.料號 != ' '
	
UNION ALL

/*發料回庫(-)
SELECT 
	A.單據類別 單別, 
	A.單據編號 單號,
	A.單據序號 + 5100 序號,
	A.異動日期,
	A.贈品數量*-1 異動數量,
	A.產品編號 材料編號,
	TO_CHAR(A.最後更新日,'YYYYMMDDHH24MISS') 更新日時
FROM 
	FIL0040 A
	INNER JOIN FIL0041 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號 AND A.單據序號 = B.序號
	INNER JOIN FIL0030 C1 ON A.單據類別 = C1.單據類別 AND A.單據編號 = C1.單據編號
WHERE
	A.單據類別 = 'C41' AND
	A.異動類別 = 'C' AND
	A.贈品數量 != 0 AND
	A.產品編號 != ' '

UNION ALL
*/

/*發料回庫(+)*/
SELECT 
	A.單據類別 單別, 
	A.單據編號 單號,
	A.單據序號 + 5200 序號,
	A.異動日期,
	A.贈品數量 異動數量,
	A.產品編號 材料編號,
	TO_CHAR(A.最後更新日,'YYYYMMDDHH24MISS') 更新日時
FROM 
	FIL0040 A
	INNER JOIN FIL0041 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號 AND A.單據序號 = B.序號
	INNER JOIN FIL0030 C1 ON A.單據類別 = C1.單據類別 AND A.單據編號 = C1.單據編號
WHERE
	A.單據類別 = 'C41' AND
	A.異動類別 = 'C' AND
	A.贈品數量 != 0 AND
	A.產品編號 != ' '
	
/*廠內盤點調整*/
UNION ALL

SELECT 
	A.單據類別 單別, 
	A.單據編號 單號,
	A.單據序號 序號,
	A.異動日期,
	(A.異動數量 + A.贈品數量) 異動數量,
	A.產品編號 材料編號,
	TO_CHAR(A.最後更新日,'YYYYMMDDHH24MISS') 更新日時
FROM 
	FIL0040 A
	INNER JOIN FIL0030 B ON A.單據類別 = B.單據類別 AND A.單據編號 = B.單據編號
	/*特殊欄位*/
	INNER JOIN FIL0041 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號 AND A.單據序號 = C.序號
WHERE
	A.單據類別 = 'F32' AND
	A.異動類別 = '2');

-- Oracle user_views
CREATE VIEW "VIEWFIL2022C" ("單別", "單號", "序號", "異動日期", "異動數量", "贈品數量", "材料編號", "單位代碼", "庫存單位", "倉庫代碼", "庫存參數", "換算率", "異動數", "前置單別", "前置單號", "批號", "採購單別", "採購單號", "採購序號", "備註說明", "廠商批號") AS with temp1 as (
SELECT 
	A.單據類別 單別, 
	A.單據編號 單號,
	A.單據序號 序號,
	decode(A.異動日期, '00000000', D.單據日期, A.異動日期) 異動日期,
	decode(A.單據類別,'D21',A.數值4,A.異動數量) 異動數量,
	A.贈品數量,
	A.產品編號 材料編號,
	A.單位代碼,
	nvl(C.單位代碼, ' ') 庫存單位,
	A.倉庫代碼,
	B.材料庫存參數 庫存參數,
	1 換算率,
	decode(A.單據類別,'D21',A.數值4,(A.異動數量 + A.贈品數量) * B.材料庫存參數) 異動數,
	nvl(A.前置單別,' ') 前置單別,
	nvl(A.前置單號,' ') 前置單號,
	nvl(F.批號, ' ') 批號,
	REGEXP_SUBSTR(nvl(F.批號, ' '), '[^-]+', 1,1) 採購單別,
	REGEXP_SUBSTR(nvl(F.批號, ' '), '[^-]+', 1,2) 採購單號,
	to_number(REGEXP_SUBSTR(nvl(F.批號, ' '), '[^-]+', 1,3),'9999') 採購序號,
	to_char(A.備註說明) 備註說明,
	nvl(G.廠商批號,' ') 廠商批號
FROM 
	FIL0040 A
	/*庫存參數*/
	INNER JOIN ViewFIL0020 B ON A.單據類別 = B.單據類別 AND B.材料庫存參數 != 0
	/*主檔*/
	INNER JOIN FIL0030 D ON A.單據類別 = D.單據類別 AND A.單據編號 = D.單據編號
	/*品號檔*/
	INNER JOIN VIEWFIL1012 C ON A.產品編號 = C.產品編號 AND C.物料大類 between 'B10' and 'B20'
	/*單位換算
	LEFT JOIN ViewFIL1017 E ON A.單位代碼 = E.從 AND C.單位代碼 = E.到
	*/
	/*特殊欄位*/
	LEFT JOIN FIL0041 F ON A.單據類別 = F.單別 AND A.單據編號 = F.單號 AND A.單據序號 = F.序號
	/*廠商批號*/
	LEFT JOIN FIL0043 G ON nvl(F.批號, ' ')=G.條碼
	/*簽核*/
	LEFT JOIN ViewOfObjProperties H ON H.單據流水號 = D.流水編號
WHERE
	A.產品編號 != ' ' and
	(A.單據類別 = 'D21' and A.異動類別='A' or A.單據類別 <> 'D21') and
	NVL(H.簽核狀態,' ')<>'A'
	
UNION ALL

/*領料*/
SELECT 
	A.單據類別 單別, 
	A.單據編號 單號,
	A.單據序號 + 5000 序號,
	A.異動日期,
	A.異動數量,
	0 贈品數量,
	A.產品編號 材料編號,
	A.單位代碼,
	nvl(G.單位代碼, ' ') 庫存單位,
	F.庫位代碼 倉庫代碼,
	1 庫存參數,
	1 換算率,
	A.異動數量 異動數,
	nvl(E.歸屬類別,' ') 前置單別,
	nvl(E.歸屬編號,' ') 前置單號,
	nvl(C.批號,' ') 批號,
	REGEXP_SUBSTR(C.批號, '[^-]+', 1,1) 採購單別,
	REGEXP_SUBSTR(C.批號, '[^-]+', 1,2) 採購單號,
	to_number(REGEXP_SUBSTR(C.批號, '[^-]+', 1,3),'9999') 採購序號,
	to_char(A.備註說明) 備註說明,
	nvl(G.廠商批號,' ') 廠商批號
FROM 
	FIL0040 A
	INNER JOIN FIL0041 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號 AND A.單據序號 = C.序號
	INNER JOIN FIL0031 D ON A.單據類別 = D.單別 AND A.單據編號 = D.單號
	INNER JOIN FIL0030 E ON A.單據類別 = E.單據類別 AND A.單據編號 = E.單據編號
	LEFT JOIN ViewFIL310P F ON D.機台代碼 = F.代碼
	INNER JOIN VIEWFIL1012 G ON A.產品編號 = G.產品編號 AND G.物料大類 between 'B10' and 'B20'
	/*單位換算
	LEFT JOIN ViewFIL1017 H ON A.單位代碼 = H.從 AND G.單位代碼 = H.到
	*/
	/*廠商批號*/
	LEFT JOIN FIL0043 G ON C.批號 = G.條碼
WHERE
	A.單據類別 = 'C4M' AND
	A.產品編號 != ' '

UNION ALL

/*材料領用,報廢,油墨領用*/
SELECT 
	A.單據類別 單別, 
	A.單據編號 單號,
	A.單據序號 序號,
	A.異動日期,
	A.異動數量,
	0 贈品數量,
	A.產品編號 材料編號,
	A.單位代碼,
	nvl(D.單位代碼, ' ') 庫存單位,
	A.倉庫代碼,
	-1 庫存參數,
	1 換算率,
	A.異動數量 * -1 異動數,
	nvl(C1.歸屬類別,' ') 前置單別,
	nvl(C1.歸屬編號,' ') 前置單號,
	nvl(B.批號,' ') 批號,
	REGEXP_SUBSTR(B.批號, '[^-]+', 1,1) 採購單別,
	REGEXP_SUBSTR(B.批號, '[^-]+', 1,2) 採購單號,
	to_number(REGEXP_SUBSTR(B.批號, '[^-]+', 1,3),'9999') 採購序號,
	to_char(decode(A.異動類別, 'C', '領用', 'D', '報廢', 'E', '油墨領用', ' ')) 備註說明,
	nvl(G.廠商批號,' ') 廠商批號
FROM 
	FIL0040 A
	INNER JOIN FIL0041 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號 AND A.單據序號 = B.序號
	INNER JOIN FIL0031 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號
	INNER JOIN FIL0030 C1 ON A.單據類別 = C1.單據類別 AND A.單據編號 = C1.單據編號
	INNER JOIN VIEWFIL1012 D ON A.產品編號 = D.產品編號 AND D.物料大類 between 'B10' and 'B20'
	/*單位換算
	LEFT JOIN ViewFIL1017 E ON A.單位代碼 = E.從 AND D.單位代碼 = E.到
	*/
	/*廠商批號*/
	LEFT JOIN FIL0043 G ON B.批號 = G.條碼
WHERE
	A.單據類別 = 'C41' AND
	A.異動類別 between 'C' and 'E' AND
	A.異動數量 != 0 AND
	A.產品編號 != ' '
	
UNION ALL

/*印刷日報領用*/
SELECT 
	A.單據類別 單別, 
	A.單據編號 單號,
	A.單據序號 序號,
	A.異動日期,
	A.異動數量,
	0 贈品數量,
	to_char(A.前製程編號) 材料編號,
	A.單位代碼,
	nvl(D.單位代碼, ' ') 庫存單位,
	A.倉庫代碼,
	-1 庫存參數,
	1 換算率,
	(A.異動數量-A.退庫數量) * -1 異動數,
	nvl(C1.歸屬類別,' ') 前置單別,
	nvl(C1.歸屬編號,' ') 前置單號,
	to_char(B.文數字4) 批號,
	REGEXP_SUBSTR(to_char(B.文數字4), '[^-]+', 1,1) 採購單別,
	REGEXP_SUBSTR(to_char(B.文數字4), '[^-]+', 1,2) 採購單號,
	to_number(REGEXP_SUBSTR(to_char(B.文數字4), '[^-]+', 1,3),'9999') 採購序號,
	to_char('印刷領用') 備註說明,
	nvl(G.廠商批號,' ') 廠商批號
FROM 
	FIL0040 A
	INNER JOIN FIL0041 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號 AND A.單據序號 = B.序號
	INNER JOIN FIL0031 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號
	INNER JOIN FIL0030 C1 ON A.單據類別 = C1.單據類別 AND A.單據編號 = C1.單據編號
	INNER JOIN VIEWFIL1012 D ON to_char(A.前製程編號) = D.產品編號 AND D.物料大類 between 'B10' and 'B20'
	/*單位換算
	LEFT JOIN ViewFIL1017 E ON A.單位代碼 = E.從 AND D.單位代碼 = E.到
	*/
	/*廠商批號*/
	LEFT JOIN FIL0043 G ON B.批號 = G.條碼
WHERE
	A.單據類別 = 'C41' AND
	A.異動數量 > 0 AND
	C.製程代碼 = 'C31A' AND 
	A.前製程編號 != ' '
	
UNION ALL

/*材料領用.氣閥.鐵條-批號1*/
SELECT 
	A.單據類別 單別, 
	A.單據編號 單號,
	A.單據序號 序號,
	A.異動日期,
	B.數值1 異動數量,
	0 贈品數量,
	D.料號 材料編號,
	A.單位代碼,
	A.單位代碼 庫存單位,
	A.倉庫代碼,
	-1 庫存參數,
	1 換算率,
	B.數值1 * -1 異動數,
	nvl(C1.歸屬類別,' ') 前置單別,
	nvl(C1.歸屬編號,' ') 前置單號,
	nvl(B.文數字1,' ') 批號,
	REGEXP_SUBSTR(B.文數字1, '[^-]+', 1,1) 採購單別,
	REGEXP_SUBSTR(B.文數字1, '[^-]+', 1,2) 採購單號,
	to_number(REGEXP_SUBSTR(B.文數字1, '[^-]+', 1,3),'9999') 採購序號,
	to_char(decode(C.製程代碼, 'C31F', '領用氣閥', 'C31G', '領用鐵條', ' ')) 備註說明,
	nvl(G.廠商批號,' ') 廠商批號
FROM 
	FIL0040 A
	INNER JOIN FIL0041 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號 AND A.單據序號 = B.序號
	INNER JOIN FIL0031 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號
	INNER JOIN FIL0030 C1 ON A.單據類別 = C1.單據類別 AND A.單據編號 = C1.單據編號
	INNER JOIN ViewFIL1024 D ON B.文數字1 = D.條碼
	INNER JOIN VIEWFIL1012 E ON D.料號 = E.產品編號 AND E.物料大類 between 'B10' and 'B20'
	/*廠商批號*/
	LEFT JOIN FIL0043 G ON B.文數字1=G.條碼
WHERE
	A.單據類別 = 'C41' AND
	A.異動類別 = 'A' AND
	C.製程代碼 between 'C31F' and 'C31G' AND
	B.文數字1 != ' ' AND
	D.料號 != ' '

UNION ALL
	
/*材料領用.氣閥.鐵條-批號2*/
SELECT 
	A.單據類別 單別, 
	A.單據編號 單號,
	A.單據序號+9000 序號,
	A.異動日期,
	B.數值2 異動數量,
	0 贈品數量,
	D.料號 材料編號,
	A.單位代碼,
	A.單位代碼 庫存單位,
	A.倉庫代碼,
	-1 庫存參數,
	1 換算率,
	B.數值2 * -1 異動數,
	nvl(C1.歸屬類別,' ') 前置單別,
	nvl(C1.歸屬編號,' ') 前置單號,
	nvl(B.文數字2,' ') 批號,
	REGEXP_SUBSTR(B.文數字2, '[^-]+', 1,1) 採購單別,
	REGEXP_SUBSTR(B.文數字2, '[^-]+', 1,2) 採購單號,
	to_number(REGEXP_SUBSTR(B.文數字2, '[^-]+', 1,3),'9999') 採購序號,
	to_char(decode(C.製程代碼, 'C31F', '領用氣閥', 'C31G', '領用鐵條', ' ')) 備註說明,
	nvl(G.廠商批號,' ') 廠商批號
FROM 
	FIL0040 A
	INNER JOIN FIL0041 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號 AND A.單據序號 = B.序號
	INNER JOIN FIL0031 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號
	INNER JOIN FIL0030 C1 ON A.單據類別 = C1.單據類別 AND A.單據編號 = C1.單據編號
	INNER JOIN ViewFIL1024 D ON B.文數字2 = D.條碼
	INNER JOIN VIEWFIL1012 E ON D.料號 = E.產品編號 AND E.物料大類 between 'B10' and 'B20'
	/*廠商批號*/
	LEFT JOIN FIL0043 G ON B.文數字2 = G.條碼 
WHERE
	A.單據類別 = 'C41' AND
	A.異動類別 = 'A' AND
	C.製程代碼 between 'C31F' and 'C31G' AND
	B.文數字2 != ' ' AND
	D.料號 != ' '
	
UNION ALL

/*發料回庫(-)
SELECT 
	A.單據類別 單別, 
	A.單據編號 單號,
	A.單據序號 + 5100 序號,
	A.異動日期,
	A.贈品數量 異動數量,
	0 贈品數量,
	A.產品編號 材料編號,
	A.單位代碼,
	nvl(C.單位代碼, ' ') 庫存單位,
	A.倉庫代碼,
	-1 庫存參數,
	1 換算率,
	A.贈品數量 * -1 異動數,
	' ' 前置單別,
	' ' 前置單號,
	nvl(B.批號,' ') 批號,
	REGEXP_SUBSTR(B.批號, '[^-]+', 1,1) 採購單別,
	REGEXP_SUBSTR(B.批號, '[^-]+', 1,2) 採購單號,
	to_number(REGEXP_SUBSTR(B.批號, '[^-]+', 1,3),'9999') 採購序號,
	to_char('餘料回庫') 備註說明,
	nvl(G.廠商批號,' ') 廠商批號
FROM 
	FIL0040 A
	INNER JOIN FIL0041 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號 AND A.單據序號 = B.序號
	INNER JOIN VIEWFIL1012 C ON A.產品編號 = C.產品編號 AND C.物料大類 between 'B10' and 'B20'
	LEFT JOIN FIL0043 G ON B.批號 = G.條碼
WHERE
	A.單據類別 = 'C41' AND
	A.異動類別 = 'C' AND
	A.贈品數量 != 0 AND
	A.產品編號 != ' '

UNION ALL
*/

/*發料回庫(+)*/
SELECT 
	A.單據類別 單別, 
	A.單據編號 單號,
	A.單據序號 + 5200 序號,
	A.異動日期,
	A.贈品數量 異動數量,
	0 贈品數量,
	A.產品編號 材料編號,
	A.單位代碼,
	nvl(C.單位代碼, ' ') 庫存單位,
	A.前置單別 倉庫代碼,
	1 庫存參數,
	1 換算率,
	A.贈品數量 * 1 異動數,
	' ' 前置單別,
	' ' 前置單號,
	nvl(B.批號,' ') 批號,
	REGEXP_SUBSTR(B.批號, '[^-]+', 1,1) 採購單別,
	REGEXP_SUBSTR(B.批號, '[^-]+', 1,2) 採購單號,
	to_number(REGEXP_SUBSTR(B.批號, '[^-]+', 1,3),'9999') 採購序號,
	to_char('餘料回庫') 備註說明,
	nvl(G.廠商批號,' ') 廠商批號
FROM 
	FIL0040 A
	INNER JOIN FIL0041 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號 AND A.單據序號 = B.序號
	INNER JOIN VIEWFIL1012 C ON A.產品編號 = C.產品編號 AND C.物料大類 between 'B10' and 'B20'
	/*單位換算
	LEFT JOIN ViewFIL1017 E ON A.單位代碼 = E.從 AND C.單位代碼 = E.到
	*/
	/*廠商批號*/
	LEFT JOIN FIL0043 G ON B.批號 = G.條碼
WHERE
	A.單據類別 = 'C41' AND
	A.異動類別 = 'C' AND
	A.贈品數量 != 0 AND
	A.產品編號 != ' '
	
/*廠內盤點調整*/
UNION ALL

SELECT 
	A.單據類別 單別, 
	A.單據編號 單號,
	A.單據序號 序號,
	A.異動日期,
	0 異動數量,
	A.贈品數量,
	A.產品編號 材料編號,
	nvl(E.單位代碼, ' ') 單位代碼,
	nvl(E.單位代碼, ' ') 庫存單位,
	' ' 倉庫代碼,
	1 庫存參數,
	1 換算率,
	(A.異動數量 + A.贈品數量) 異動數,
	' ' 前置單別,
	' ' 前置單號,
	nvl(C.批號,' ') 批號,
	REGEXP_SUBSTR(C.批號, '[^-]+', 1,1) 採購單別,
	REGEXP_SUBSTR(C.批號, '[^-]+', 1,2) 採購單號,
	to_number(REGEXP_SUBSTR(C.批號, '[^-]+', 1,3),'9999') 採購序號,
	to_char('盤點調整') 備註說明,
	nvl(G.廠商批號,' ') 廠商批號
FROM 
	FIL0040 A
	INNER JOIN FIL0030 B ON A.單據類別 = B.單據類別 AND A.單據編號 = B.單據編號
	/*特殊欄位*/
	INNER JOIN FIL0041 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號 AND A.單據序號 = C.序號
	INNER JOIN VIEWFIL1012 E ON A.產品編號 = E.產品編號 AND E.物料大類 between 'B10' and 'B20'
	/*廠商批號*/
	LEFT JOIN FIL0043 G ON C.批號 = G.條碼
WHERE
	A.單據類別 = 'F32' AND
	A.異動類別 = '2')
select "單別","單號","序號","異動日期","異動數量","贈品數量","材料編號","單位代碼","庫存單位","倉庫代碼","庫存參數","換算率","異動數","前置單別","前置單號","批號","採購單別","採購單號","採購序號","備註說明","廠商批號" from temp1;

-- Oracle user_views
CREATE VIEW "VIEWFIL2023" ("單別", "單號", "序號", "類別", "LOGICAL2", "DESC排序") AS (                                                                                                                                           SELECT
	A.單據類別 單別,
	A.單據編號 單號,
	A.單據序號 序號,
	A.異動類別 類別,
	A.Logical2,
	row_number() over (partition by A.單據類別, A.單據編號, A.異動類別 order by A.單據類別, A.單據編號, A.單據序號 desc) as DESC排序
FROM
	FIL0040 A);

-- Oracle user_views
CREATE VIEW "VIEWFIL2030" ("單據類別", "單據編號", "數量", "贈品量", "金額", "毛重", "材積", "製版費", "燙金費", "雷射費") AS (                                                                                                                                                      SELECT
	A.單據類別,
	A.單據編號,
	sum(A.異動數量) 數量,
	sum(A.贈品數量) 贈品量,
	sum(A.異動金額) 金額,
	sum(A.毛重) 毛重,
	sum(A.材積) 材積,
	sum(A.製版費) 製版費,
	sum(A.燙金費) 燙金費,
	sum(A.雷射費) 雷射費
FROM
	FIL0040 A
GROUP BY
	A.單據類別,
	A.單據編號);

-- Oracle user_views
CREATE VIEW "VIEWFIL2040" ("單據類別", "單據編號", "內容") AS SELECT
	A.單據類別,
	A.單據編號,
	listagg
	(	to_char
			(
			trim(to_char( A.異動數量,'999999.999')) || ' x ' ||
			trim(to_char( A.異動單價,'99999.999')) || ' ' ||
			trim(A.產品編號)
			), ',') within group (order by A.單據序號) as 內容
FROM
	FIL0040 A 
group by 
	A.單據類別, 
	A.單據編號;

-- Oracle user_views
CREATE VIEW "VIEWFIL2050" ("單據類別", "單據編號", "單據序號", "代碼", "名稱", "日期", "幣別", "金額", "稅額", "備註", "付款條件", "付款條件名稱", "流水編號", "最後更新者", "更新者姓名", "最後更新日") AS (SELECT 
	A.單據類別, 
	A.單據編號,
	A.單據序號,
	A.代碼,
	nvl(B.費用名稱, ' ') 名稱,
	A.日期,
	A.幣別,
	A.金額,
	A.稅額,
	A.備註,
	A.付款條件,
	nvl(C.名稱, ' ') 付款條件名稱,
	A.流水編號,
	A.最後更新者,
	nvl(Z1.員工姓名,' ') 更新者姓名,
	A.最後更新日
FROM 
	FIL0042 A
	LEFT JOIN FIL0023 B ON A.代碼 = B.費用代碼
	LEFT JOIN ViewFIL3107 C ON A.付款條件 = C.代碼
	LEFT JOIN FIL0010 Z1 ON A.最後更新者 = Z1.員工編號);

-- Oracle user_views
CREATE VIEW "VIEWFIL2051" ("單據類別", "單據編號", "幣別", "金額", "稅額") AS (SELECT 
	A.單據類別, 
	A.單據編號,
	A.幣別,
	sum(A.金額) 金額,
	sum(A.稅額) 稅額
FROM 
	FIL0042 A
GROUP BY
	A.單據類別, 
	A.單據編號,
	A.幣別);

-- Oracle user_views
CREATE VIEW "VIEWFIL2061" ("單別", "單號", "序號", "異動日期", "半成品編號", "入庫米數", "捲數", "有效日期", "製造日期", "作業者", "報廢米數") AS (
/*入庫*/
SELECT 
	A.單別 單別, 
	A.單號 單號,
	A.序號,
	A.日期一 異動日期,	
	A.文字一 半成品編號,
	A.數字一*decode(A.報廢,1,0,1) 入庫米數,
	case when decode(A.報廢,1,0,A.數字一) >= nvl(E.裁切規格_M,0) or nvl(E.裁切規格_M,0) = 0 
		 then 1 	
		 else trunc(decode(A.報廢,1,0,A.數字一)/decode(INSTR(P.產品編號,'R',1,1),0,E.裁切規格_M,P.訂購數量),1)
	end 捲數,
	F.有效日期 有效日期,
	decode(nvl(B.交貨日期,' '),' ',A.日期二,B.交貨日期) 製造日期,
	D.填表人 作業者,
	0 報廢米數 
FROM 
	FIL00401 A
	INNER JOIN FIL0031 B ON A.單別 = B.單別 AND A.單號 = B.單號
	/*主檔*/
	INNER JOIN FIL0030 D ON A.單別 = D.單據類別 AND A.單號 = D.單據編號
	INNER JOIN FIL0040 G ON A.單別 = G.單據類別 AND A.單號 = G.單據編號 AND A.序號 = G.單據序號
	INNER JOIN FIL0032 P ON P.製令單別 = 'C11' and P.製令單號 = REGEXP_SUBSTR(A.文字一, '[^_]+', 1, 1)
	LEFT JOIN FIL0033 E ON E.製令單別 = 'C11' and E.製令單號 = REGEXP_SUBSTR(A.文字一, '[^_]+', 1, 1) and E.加工別 = 'A'
	LEFT JOIN FIL003F1 F ON F.單據類別 = 'C11' and F.單據編號 = REGEXP_SUBSTR(A.文字一, '[^_]+', 1, 1) and F.類別 = 'G1'
WHERE
	A.單別 = 'C41' AND 
	G.異動類別 = 'A' AND
	B.製程代碼 = 'C31D' AND
	A.文字一<>' '

UNION ALL

/*調整*/
SELECT 
	A.單據類別 單別, 
	A.單據編號 單號,
	A.單據序號 單據序號, 
	D.單據日期 異動日期,	
	A.產品編號 半成品編號,
	A.異動數量*decode(A.異動類別,'C',-1,1) 入庫米數,
	case when A.異動數量 >= nvl(E.裁切規格_M,0) or nvl(E.裁切規格_M,0) = 0 
		 then 1
		 else trunc(A.異動數量*decode(A.異動類別,'C',-1,1) / decode(INSTR(P.產品編號,'R',1,1),0,E.裁切規格_M,P.訂購數量) ,1)
	end 捲數,
	'00000000' 有效日期,
	DECODE(D.匯率日期,' ','00000000',D.匯率日期) 製造日期,
	A.文數字1 作業者,
	A.數值1*decode(A.異動類別,'C',-1,1) 報廢米數
FROM 
	FIL0040 A
	/*主檔*/
	INNER JOIN FIL0030 D ON A.單據類別 = D.單據類別 AND A.單據編號 = D.單據編號
	INNER JOIN FIL0032 P ON P.製令單別 = 'C11' and P.製令單號 = REGEXP_SUBSTR(A.產品編號, '[^_]+', 1, 1)
	LEFT JOIN FIL0033 E ON E.製令單別 = 'C11' and E.製令單號 = REGEXP_SUBSTR(A.產品編號, '[^_]+', 1, 1) and E.加工別 = 'A'
WHERE
	A.單據類別 = 'E22' 

UNION ALL

/*調整*/
SELECT 
	A.單據類別 單別, 
	A.單據編號 單號,
	A.單據序號 單據序號, 
	D.單據日期 異動日期,	
	A.產品編號 半成品編號,
	A.異動數量*decode(A.異動類別,'C',-1,1) 入庫米數,
	case when A.異動數量 >= nvl(E.裁切規格_M,0) or nvl(E.裁切規格_M,0) = 0 
		 then 1
		 else trunc(A.異動數量*decode(A.異動類別,'C',-1,1) / decode(INSTR(P.產品編號,'R',1,1),0,E.裁切規格_M,P.訂購數量) ,1)
	end 捲數,
	'00000000' 有效日期,
	DECODE(D.匯率日期,' ','00000000',D.匯率日期) 製造日期,
	A.文數字1 作業者,
	0 報廢米數
FROM 
	FIL0040 A
	/*主檔*/
	INNER JOIN FIL0030 D ON A.單據類別 = D.單據類別 AND A.單據編號 = D.單據編號
	INNER JOIN FIL0032 P ON P.製令單別 = 'C11' and P.製令單號 = REGEXP_SUBSTR(A.產品編號, '[^_]+', 1, 1)
	LEFT JOIN FIL0033 E ON E.製令單別 = 'C11' and E.製令單號 = REGEXP_SUBSTR(A.產品編號, '[^_]+', 1, 1) and E.加工別 = 'A'
WHERE
	A.單據類別 = 'E23' 	
);

-- Oracle user_views
CREATE VIEW "VIEWFIL2061M" ("半成品編號", "製令單號", "序號", "序號2", "報廢", "重整") AS (
SELECT 
	A.半成品編號,
	A.製令單號,
	A.序號,
	A.序號2,
	max(A.報廢) 報廢,
	max(A.重整) 重整
From	
(/*入庫*/
SELECT DISTINCT
	A.文字一 半成品編號,
	REGEXP_SUBSTR(A.文字一, '[^_]+', 1,1) 製令單號,
	to_number(decode(REGEXP_SUBSTR(REGEXP_SUBSTR(A.文字一, '[^_]+', 1,REGEXP_COUNT(A.文字一, '_')+1),'[^-]+', 1,1),'',0,REGEXP_SUBSTR(REGEXP_SUBSTR(A.文字一, '[^_]+', 1,REGEXP_COUNT(A.文字一, '_')+1),'[^-]+', 1,1))) 序號,
	to_number(nvl(REGEXP_SUBSTR(REGEXP_SUBSTR(A.文字一, '[^_]+', 1,REGEXP_COUNT(A.文字一, '_')+1), '[^-]+', 1,REGEXP_COUNT(A.文字一, '-')+1),'0')) 序號2,
	nvl(A.報廢,0) 報廢,
	nvl(A.重整,0) 重整
FROM 
	FIL00401 A
	INNER JOIN FIL0040 M ON M.單據類別 = A.單別 and M.單據編號= A.單號 and M.單據序號 = A.序號
	INNER JOIN FIL0031 B ON A.單別 = B.單別 AND A.單號 = B.單號
	INNER JOIN FIL0041 C ON A.單別 = C.單別 AND A.單號 = C.單號 AND A.序號 = C.序號
	/*主檔*/
	INNER JOIN FIL0030 D ON A.單別 = D.單據類別 AND A.單號 = D.單據編號
WHERE
	A.單別 = 'C41' AND
	M.異動類別 = 'A' AND
	B.製程代碼 = 'C31D' AND
	A.文字一<>' '
	
UNION All

/*調整出庫*/
SELECT DISTINCT
	A.產品編號 半成品編號,
	REGEXP_SUBSTR(A.產品編號, '[^_]+', 1,1) 製令單號,
	TO_NUMBER(REGEXP_SUBSTR(REGEXP_SUBSTR(A.產品編號, '[^_]+', 1,REGEXP_COUNT(A.產品編號, '_')+1),'[^-]+', 1,1)) 序號,
	to_number(nvl(REGEXP_SUBSTR(REGEXP_SUBSTR(A.產品編號, '[^_]+', 1,REGEXP_COUNT(A.產品編號, '_')+1), '[^-]+', 1,REGEXP_COUNT(A.產品編號, '-')+1),'0')) 序號2,
	0 報廢,
	0 重整
FROM 
	FIL0040 A
	/*主檔*/
	INNER JOIN FIL0030 D ON A.單據類別 = D.單據類別 AND A.單據編號 = D.單據編號
WHERE
	A.單據類別 = 'E22' and 
	A.異動類別 = 'A' AND
	A.產品編號<>' '
	
UNION All

/*調整入庫*/
SELECT DISTINCT
	A.產品編號 半成品編號,
	REGEXP_SUBSTR(A.產品編號, '[^_]+', 1,1) 製令單號,
	TO_NUMBER(REGEXP_SUBSTR(REGEXP_SUBSTR(A.產品編號, '[^_]+', 1,REGEXP_COUNT(A.產品編號, '_')+1),'[^-]+', 1,1)) 序號,
	to_number(nvl(REGEXP_SUBSTR(REGEXP_SUBSTR(A.產品編號, '[^_]+', 1,REGEXP_COUNT(A.產品編號, '_')+1), '[^-]+', 1,REGEXP_COUNT(A.產品編號, '-')+1),'0')) 序號2,
	0 報廢,
	0 重整
FROM 
	FIL0040 A
	/*主檔*/
	INNER JOIN FIL0030 D ON A.單據類別 = D.單據類別 AND A.單據編號 = D.單據編號
WHERE
	A.單據類別 = 'E23' AND	
	A.異動類別 = 'A' 
) A
GROUP BY 
	A.半成品編號,
	A.製令單號,
	A.序號,
	A.序號2
);

-- Oracle user_views
CREATE VIEW "VIEWFIL2062" ("半成品編號", "製令單號", "有效日期", "製造日期", "庫存數", "捲數", "報廢米數") AS (
/*入庫*/
SELECT 
    A.半成品編號,
	REGEXP_SUBSTR(A.半成品編號, '[^_]+', 1, 1) 製令單號,
	max(A.有效日期) 有效日期,
	max(A.製造日期) 製造日期,
	sum(A.入庫米數) 庫存數,
	sum(A.捲數) 捲數,
	sum(A.報廢米數) 報廢米數
FROM 
	ViewFIL2061 A
GROUP BY
	A.半成品編號,
	REGEXP_SUBSTR(A.半成品編號, '[^_]+', 1, 1)
);

-- Oracle user_views
CREATE VIEW "VIEWFIL2063" ("單別", "單號", "單據序號", "異動日期", "半成品編號", "製令單號", "有效日期", "製造日期") AS (
/*入庫*/
SELECT 
	A.單據類別 單別, 
	A.單據編號 單號,
	A.單據序號,
	decode(A.異動日期, '00000000', D.單據日期, A.異動日期) 異動日期,	
	REGEXP_SUBSTR(nvl(C.文字1, ' '), '[^,]+', 1,1) 半成品編號,
	REGEXP_SUBSTR(REGEXP_SUBSTR(nvl(C.文字1, ' '), '[^,]+', 1,1), '[^-]+', 1,1) 製令單號,
	E.有效日期,
	E.製造日期
FROM 
	FIL0040 A
	INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
	INNER JOIN FIL0041 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號 AND A.單據序號 = C.序號
	/*主檔*/
	INNER JOIN FIL0030 D ON A.單據類別 = D.單據類別 AND A.單據編號 = D.單據編號
	LEFT JOIN ViewFIL2062 E ON E.半成品編號=REGEXP_SUBSTR(nvl(C.文字1, ' '), '[^,]+', 1,1)
WHERE
	A.單據類別 = 'C41' AND
	A.異動類別 = 'A' AND
	B.製程代碼 = 'C31I' AND
	REGEXP_SUBSTR(nvl(C.文字1, ' '), '[^,]+', 1,1)<>' '

UNION ALL	

SELECT 
	A.單據類別 單別, 
	A.單據編號 單號,
	A.單據序號+1000 單據序號,
	decode(A.異動日期, '00000000', D.單據日期, A.異動日期) 異動日期,	
	REGEXP_SUBSTR(nvl(C.文字1, ' '), '[^,]+', 1,2) 半成品編號,
	REGEXP_SUBSTR(REGEXP_SUBSTR(nvl(C.文字1, ' '), '[^,]+', 1,2), '[^-]+', 1,1) 製令單號,
	E.有效日期,
	E.製造日期
FROM 
	FIL0040 A
	INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
	INNER JOIN FIL0041 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號 AND A.單據序號 = C.序號
	/*主檔*/
	INNER JOIN FIL0030 D ON A.單據類別 = D.單據類別 AND A.單據編號 = D.單據編號
	LEFT JOIN ViewFIL2062 E ON E.半成品編號=REGEXP_SUBSTR(nvl(C.文字1, ' '), '[^,]+', 1,2)
WHERE
	A.單據類別 = 'C41' AND
	A.異動類別 = 'A' AND
	B.製程代碼 = 'C31I' AND
	REGEXP_SUBSTR(nvl(C.文字1, ' '), '[^,]+', 1,2)<>' '

UNION ALL

SELECT 
	A.單據類別 單別, 
	A.單據編號 單號,
	A.單據序號+2000 單據序號,
	decode(A.異動日期, '00000000', D.單據日期, A.異動日期) 異動日期,	
	REGEXP_SUBSTR(nvl(C.文字1, ' '), '[^,]+', 1,3) 半成品編號,
	REGEXP_SUBSTR(REGEXP_SUBSTR(nvl(C.文字1, ' '), '[^,]+', 1,3), '[^-]+', 1,1) 製令單號,
	E.有效日期,
	E.製造日期
FROM 
	FIL0040 A
	INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
	INNER JOIN FIL0041 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號 AND A.單據序號 = C.序號
	/*主檔*/
	INNER JOIN FIL0030 D ON A.單據類別 = D.單據類別 AND A.單據編號 = D.單據編號
	LEFT JOIN ViewFIL2062 E ON E.半成品編號=REGEXP_SUBSTR(nvl(C.文字1, ' '), '[^,]+', 1,3)
WHERE
	A.單據類別 = 'C41' AND
	A.異動類別 = 'A' AND
	B.製程代碼 = 'C31I' AND
	REGEXP_SUBSTR(nvl(C.文字1, ' '), '[^,]+', 1,3)<>' '

UNION ALL	

SELECT 
	A.單據類別 單別, 
	A.單據編號 單號,
	A.單據序號+3000 單據序號,
	decode(A.異動日期, '00000000', D.單據日期, A.異動日期) 異動日期,	
	REGEXP_SUBSTR(nvl(C.文字1, ' '), '[^,]+', 1,4) 半成品編號,
	REGEXP_SUBSTR(REGEXP_SUBSTR(nvl(C.文字1, ' '), '[^,]+', 1,4), '[^-]+', 1,1) 製令單號,
	E.有效日期,
	E.製造日期
FROM 
	FIL0040 A
	INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
	INNER JOIN FIL0041 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號 AND A.單據序號 = C.序號
	/*主檔*/
	INNER JOIN FIL0030 D ON A.單據類別 = D.單據類別 AND A.單據編號 = D.單據編號
	LEFT JOIN ViewFIL2062 E ON E.半成品編號=REGEXP_SUBSTR(nvl(C.文字1, ' '), '[^,]+', 1,4)
WHERE
	A.單據類別 = 'C41' AND
	A.異動類別 = 'A' AND
	B.製程代碼 = 'C31I' AND
	REGEXP_SUBSTR(nvl(C.文字1, ' '), '[^,]+', 1,4)<>' '

UNION ALL

SELECT 
	A.單據類別 單別, 
	A.單據編號 單號,
	A.單據序號+4000 單據序號,
	decode(A.異動日期, '00000000', D.單據日期, A.異動日期) 異動日期,	
	REGEXP_SUBSTR(nvl(C.文字1, ' '), '[^,]+', 1,5) 半成品編號,
	REGEXP_SUBSTR(REGEXP_SUBSTR(nvl(C.文字1, ' '), '[^,]+', 1,5), '[^-]+', 1,1) 製令單號,
	E.有效日期,
	E.製造日期
FROM 
	FIL0040 A
	INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
	INNER JOIN FIL0041 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號 AND A.單據序號 = C.序號
	/*主檔*/
	INNER JOIN FIL0030 D ON A.單據類別 = D.單據類別 AND A.單據編號 = D.單據編號
	LEFT JOIN ViewFIL2062 E ON E.半成品編號=REGEXP_SUBSTR(nvl(C.文字1, ' '), '[^,]+', 1,5)
WHERE
	A.單據類別 = 'C41' AND
	A.異動類別 = 'A' AND
	B.製程代碼 = 'C31I' AND
	REGEXP_SUBSTR(nvl(C.文字1, ' '), '[^,]+', 1,5)<>' '

UNION ALL	

SELECT 
	A.單據類別 單別, 
	A.單據編號 單號,
	A.單據序號+5000 單據序號,
	decode(A.異動日期, '00000000', D.單據日期, A.異動日期) 異動日期,	
	REGEXP_SUBSTR(nvl(C.文字1, ' '), '[^,]+', 1,6) 半成品編號,
	REGEXP_SUBSTR(REGEXP_SUBSTR(nvl(C.文字1, ' '), '[^,]+', 1,6), '[^-]+', 1,1) 製令單號,
	E.有效日期,
	E.製造日期
FROM 
	FIL0040 A
	INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
	INNER JOIN FIL0041 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號 AND A.單據序號 = C.序號
	/*主檔*/
	INNER JOIN FIL0030 D ON A.單據類別 = D.單據類別 AND A.單據編號 = D.單據編號
	LEFT JOIN ViewFIL2062 E ON E.半成品編號=REGEXP_SUBSTR(nvl(C.文字1, ' '), '[^,]+', 1,6)
WHERE
	A.單據類別 = 'C41' AND
	A.異動類別 = 'A' AND
	B.製程代碼 = 'C31I' AND
	REGEXP_SUBSTR(nvl(C.文字1, ' '), '[^,]+', 1,6)<>' '	

);

-- Oracle user_views
CREATE VIEW "VIEWFIL2064" ("製令單號", "捲數") AS (
/*裁切*/
SELECT 
	製令單號,
	sum(捲數) 捲數
FROM 
	ViewFIL2062 A
WHERE 
	A.庫存數>0 
GROUP BY
	製令單號
);

-- Oracle user_views
CREATE VIEW "VIEWFIL2065" ("製令單號", "捲數") AS (
/*包裝*/
SELECT 
	REGEXP_SUBSTR(A.文字一, '[^_]+', 1, 1) 製令單號,
	SUM(nvl(D.捲數,0)) 捲數
FROM 
	FIL00401 A
	INNER JOIN FIL0031 B ON A.單別 = B.單別 AND A.單號 = B.單號
	INNER JOIN FIL0040 C ON A.單別 = C.單據類別 AND A.單號 = C.單據編號 AND A.序號 = C.單據序號
	LEFT JOIN ViewFIL2062 D ON D.半成品編號 = A.文字一
WHERE
	C.單據類別 = 'C41' AND
	C.異動類別 = 'A' AND
	B.製程代碼 = 'C31I'
GROUP BY
	REGEXP_SUBSTR(A.文字一, '[^_]+', 1, 1)
);

-- Oracle user_views
CREATE VIEW "VIEWFIL2066" ("單別", "單號", "前製程米數", "PLC抓取米數", "合理剔除數", "不良剔除數", "檢品數量", "線內不良剔除數", "線外不良剔除數", "備註", "製令單號", "回庫數量") AS (
SELECT 
		A.單別, 
		A.單號,
		MAX(A.前製程米數) 前製程米數,
		MAX(A.PLC抓取米數) PLC抓取米數,
		MAX(A.合理剔除數) 合理剔除數,
		MAX(A.不良剔除數) 不良剔除數,
		MAX(A.檢品數量) 檢品數量,
		MAX(A.線內不良剔除數) 線內不良剔除數,
		MAX(A.線外不良剔除數) 線外不良剔除數,
		MAX(A.備註) 備註,
		listagg(nvl(trim(B.廠客品號),' '),',') within group (order by B.廠客品號) as 製令單號,
		max(nvl(E.回庫數量,0)) 回庫數量	
FROM		
	(SELECT 
		A.單據類別 單別, 
		A.單據編號 單號,
		SUM(A.異動數量) 前製程米數,
		SUM(A.異動單價) PLC抓取米數,
		SUM(A.燙金費) 合理剔除數,
		SUM(A.毛重) 不良剔除數,
		SUM(A.贈品數量) 檢品數量,
		SUM(A.雷射費) 線外不良剔除數,
		SUM(A.夾鏈費) 線內不良剔除數,
		listagg(nvl(trim(C.文字1),' '),' ') within group (order by A.單據序號) as 備註
	FROM 
		FIL0040 A
		INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
		LEFT JOIN FIL0041 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號 AND A.單據序號 = C.序號
	WHERE
		A.單據類別 = 'C41' AND
		A.異動類別 = 'A' AND
		B.製程代碼 = 'C31H' 
	GROUP BY
		A.單據類別, 
		A.單據編號
	) A
	LEFT JOIN
	(SELECT DISTINCT 
		A.單據類別 單別, 
		A.單據編號 單號,
		A.廠客品號
	FROM 
		FIL0040 A
		INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
	WHERE
		A.單據類別 = 'C41' AND
		A.異動類別 = 'A' AND
		B.製程代碼 = 'C31H' AND
		A.廠客品號 <>' '
	) B ON A.單別=B.單別 AND  A.單號=B.單號
	LEFT JOIN 
	(SELECT 
		A.單據類別,
		A.單據編號,
		SUM(A.贈品數量) 回庫數量
	FROM
		FIL0040 A
		INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
		INNER JOIN FIL0041 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號 AND A.單據序號 = C.序號
	WHERE
		A.單據類別 = 'C41' AND
		A.異動類別= 'G' AND
		B.製程代碼 = 'C31H'	AND
		C.標籤列印次數 > 0
	GROUP BY
		A.單據類別, 
		A.單據編號
	) E ON E.單據類別 = A.單別 AND E.單據編號 = A.單號
GROUP BY 
	A.單別,
	A.單號
);

-- Oracle user_views
CREATE VIEW "VIEWFIL2067" ("單別", "單號", "製令單別", "製令單號", "加工別", "順序", "檢品編號", "前製程米數", "PLC抓取米數", "合理剔除數", "不良剔除數", "線外不良剔除數", "線內不良剔除數", "檢品數量", "接頭數", "回庫數量", "生產條件米數", "備註", "耗時") AS (
SELECT 
	A.單據類別 單別, 
	A.單據編號 單號,
	A.前置單別 製令單別,
	A.前置單號 製令單號,
	decode(C.小單位 ,'A','A材','B','B材','C','底邊','D','A側','E','B側',' ') 加工別,
	MIN(A.單據序號) 順序,
	MAX(A.產品編號) 檢品編號,
	SUM(A.異動數量) 前製程米數,
	SUM(A.異動單價) PLC抓取米數,
	SUM(A.燙金費) 合理剔除數,
	SUM(A.毛重) 不良剔除數,
	SUM(A.雷射費) 線外不良剔除數,
	SUM(A.夾鏈費) 線內不良剔除數,
	SUM(A.贈品數量) 檢品數量,
	SUM(A.折扣率) 接頭數,
	max(nvl(E.回庫數量,0)) 回庫數量,
	max(nvl(D.印刷米數,0)*1000) 生產條件米數,
	listagg(nvl(trim(C.文字1),' '),' ') within group (order by A.單據序號) as 備註,
	SUM(A.QRNo) 耗時
FROM 
	FIL0040 A
	INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
	LEFT JOIN FIL0041 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號 AND A.單據序號 = C.序號
	LEFT JOIN
		(SELECT 
			F.製令單別, 
			F.製令單號, 
			sum(F.印刷米數) 印刷米數
		FROM 
			FIL0033 F 
		WHERE 
			F.印刷基材<>' ' 
		GROUP BY
			F.製令單別, 
			F.製令單號) D ON D.製令單別 = A.前置單別 AND D.製令單號 = A.前置單號 
	LEFT JOIN 
	(SELECT 
		A.單據類別,
		A.單據編號,
		A.前置單號 製令單號,
		A.單位代碼 加工別,
		SUM(A.贈品數量) 回庫數量
	FROM
		FIL0040 A
		INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
		INNER JOIN FIL0041 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號 AND A.單據序號 = C.序號
	WHERE
		A.單據類別 = 'C41' AND
		A.異動類別= 'G' AND
		B.製程代碼 = 'C31H'	AND
		C.標籤列印次數 > 0
	GROUP BY
		A.單據類別, 
		A.單據編號,
		A.前置單號,
		A.單位代碼
	) E ON E.單據類別 =A.單據類別 AND E.單據編號 = A.單據編號 AND A.前置單號=E.製令單號 and A.單位代碼 = E.加工別
WHERE
	A.單據類別 = 'C41' AND
	A.異動類別 = 'A' AND
	B.製程代碼 = 'C31H' 
GROUP BY
	A.單據類別, 
	A.單據編號,
	A.前置單別,
	A.前置單號,
	decode(C.小單位 ,'A','A材','B','B材','C','底邊','D','A側','E','B側',' ')
);

-- Oracle user_views
CREATE VIEW "VIEWFIL2068" ("單別", "單號", "前製程米數", "PLC抓取米數", "合理剔除數", "不良剔除數", "檢品數量", "線內不良剔除數", "線外不良剔除數", "備註", "製令單號", "回庫數量") AS (
SELECT 
		A.單別, 
		A.單號,
		MAX(A.前製程米數) 前製程米數,
		MAX(A.PLC抓取米數) PLC抓取米數,
		MAX(A.合理剔除數) 合理剔除數,
		MAX(A.不良剔除數) 不良剔除數,
		MAX(A.檢品數量) 檢品數量,
		MAX(A.線內不良剔除數) 線內不良剔除數,
		MAX(A.線外不良剔除數) 線外不良剔除數,
		MAX(A.備註) 備註,
		listagg(nvl(trim(B.廠客品號),' '),',') within group (order by B.廠客品號) as 製令單號,
		max(nvl(E.回庫數量,0)) 回庫數量	
FROM		
	(SELECT 
		A.單據類別 單別, 
		A.單據編號 單號,
		SUM(A.異動數量) 前製程米數,
		SUM(A.異動單價) PLC抓取米數,
		SUM(A.燙金費) 合理剔除數,
		SUM(A.毛重) 不良剔除數,
		SUM(A.贈品數量) 檢品數量,
		SUM(A.雷射費) 線外不良剔除數,
		SUM(A.夾鏈費) 線內不良剔除數,
		listagg(nvl(trim(C.文字1),' '),' ') within group (order by A.單據序號) as 備註
	FROM 
		FIL0040 A
		INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
		LEFT JOIN FIL0041 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號 AND A.單據序號 = C.序號
	WHERE
		A.單據類別 = 'C41' AND
		A.異動類別 = 'A' AND
		B.製程代碼 = 'C31K' 
	GROUP BY
		A.單據類別, 
		A.單據編號
	) A
	LEFT JOIN
	(SELECT DISTINCT 
		A.單據類別 單別, 
		A.單據編號 單號,
		A.廠客品號
	FROM 
		FIL0040 A
		INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
	WHERE
		A.單據類別 = 'C41' AND
		A.異動類別 = 'A' AND
		B.製程代碼 = 'C31K' AND
		A.廠客品號 <>' '
	) B ON A.單別=B.單別 AND  A.單號=B.單號
	LEFT JOIN 
	(SELECT 
		A.單據類別,
		A.單據編號,
		SUM(A.贈品數量) 回庫數量
	FROM
		FIL0040 A
		INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
		INNER JOIN FIL0041 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號 AND A.單據序號 = C.序號		
	WHERE
		A.單據類別 = 'C41' AND
		A.異動類別= 'G' AND
		B.製程代碼 = 'C31K'	AND
		C.標籤列印次數 > 0
	GROUP BY
		A.單據類別, 
		A.單據編號
	) E ON E.單據類別 = A.單別 AND E.單據編號 = A.單號
GROUP BY 
	A.單別,
	A.單號
);

-- Oracle user_views
CREATE VIEW "VIEWFIL2069" ("單別", "單號", "製令單別", "製令單號", "順序", "檢品編號", "前製程米數", "PLC抓取米數", "合理剔除數", "不良剔除數", "線外不良剔除數", "線內不良剔除數", "檢品數量", "接頭數", "回庫數量", "備註", "耗時") AS (
SELECT 
	A.單據類別 單別, 
	A.單據編號 單號,
	A.前置單別 製令單別,
	A.前置單號 製令單號,
	MIN(A.單據序號) 順序,
	MAX(A.產品編號) 檢品編號,
	SUM(A.異動數量) 前製程米數,
	SUM(A.異動單價) PLC抓取米數,
	SUM(A.燙金費) 合理剔除數,
	SUM(A.毛重) 不良剔除數,
	SUM(A.雷射費) 線外不良剔除數,
	SUM(A.夾鏈費) 線內不良剔除數,
	SUM(A.贈品數量) 檢品數量,
	SUM(A.折扣率) 接頭數,
	max(nvl(E.回庫數量,0)) 回庫數量,
	listagg(nvl(trim(C.文字1),' '),' ') within group (order by A.單據序號) as 備註,
	SUM(A.QRNo) 耗時
FROM 
	FIL0040 A
	INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
	LEFT JOIN FIL0041 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號 AND A.單據序號 = C.序號
	LEFT JOIN 
	(SELECT 
		A.單據類別,
		A.單據編號,
		A.前置單號 製令單號,
		SUM(A.贈品數量) 回庫數量
	FROM
		FIL0040 A
		INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
		INNER JOIN FIL0041 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號 AND A.單據序號 = C.序號
	WHERE
		A.單據類別 = 'C41' AND
		A.異動類別= 'G' AND
		B.製程代碼 = 'C31H' AND
		C.標籤列印次數 > 0
	GROUP BY
		A.單據類別, 
		A.單據編號,
		A.前置單號
	) E ON E.單據類別 =A.單據類別 AND E.單據編號 = A.單據編號 AND A.前置單號=E.製令單號
WHERE
	A.單據類別 = 'C41' AND
	A.異動類別 = 'A' AND
	B.製程代碼 = 'C31K' 
GROUP BY
	A.單據類別, 
	A.單據編號,
	A.前置單別,
	A.前置單號
);

-- Oracle user_views
CREATE VIEW "VIEWFIL2070" ("製令單別", "製令單號", "半成品編號", "加工別", "製程代碼", "熟成條件", "接頭數", "庫存數量") AS (
SELECT
	A.製令單別,
	A.製令單號,
	A.半成品編號,
	A.加工別,
	A.製程代碼,
	max(熟成條件) 熟成條件,
	MIN(A.接頭數) 接頭數,
	SUM(A.異動數量*庫存參數) 庫存數量
FROM	
	ViewFIL2071 A
GROUP BY
	A.製令單別,
	A.製令單號,
	A.半成品編號,
	A.加工別,
	A.製程代碼
);

-- Oracle user_views
CREATE VIEW "VIEWFIL2070A" ("製令單別", "製令單號", "半成品編號", "加工別", "製程代碼", "庫存數量") AS (
SELECT
	A.製令單別,
	A.製令單號,
	A.半成品編號,
	A.加工別,
	A.製程代碼,
	SUM(A.異動數量*庫存參數) 庫存數量
FROM	
	ViewFIL2071 A
GROUP BY
	A.製令單別,
	A.製令單號,
	A.半成品編號,
	A.加工別,
	A.製程代碼
);

-- Oracle user_views
CREATE VIEW "VIEWFIL2070B" ("製令單別", "製令單號", "加工別", "半成品編號", "庫存數量") AS (
SELECT
	A.製令單別,
	A.製令單號,
	A.加工別,
	A.半成品編號,
	SUM(A.異動數量*庫存參數) 庫存數量
FROM	
	ViewFIL2071 A
GROUP BY
	A.製令單別,
	A.製令單號,
	A.加工別,
	A.半成品編號
);

-- Oracle user_views
CREATE VIEW "VIEWFIL2071" ("庫存參數", "單別", "單號", "序號", "製令單別", "製令單號", "製程代碼", "加工次數", "本製程編號", "半成品編號", "加工別", "前製程編號", "熟成條件", "異動數量", "接頭數", "來源") AS (
/* 印刷*/
SELECT
	1 庫存參數,
	A.單據類別 單別, 
	A.單據編號 單號,
	A.單據序號 序號,
	to_char('C11') 製令單別,
	to_char(C.歸屬編號) 製令單號,
	to_char(B.製程代碼) 製程代碼,
	C.歸屬序號 加工次數,
	TO_CHAR(A.產品編號) 本製程編號,
	to_char(C.歸屬編號||'_'||B.交貨日期_次批||'_'||A.產品編號) 半成品編號,
	to_char(B.交貨日期_次批)	加工別,
	TO_CHAR(A.前製程編號) 前製程編號,
	to_char(' ') 熟成條件,
	(A.異動單價-A.夾鏈費) 異動數量,
	A.數值2 接頭數,
	'入庫印刷' 來源
FROM 
	FIL0040 A
	INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
	INNER JOIN FIL0030 C ON A.單據類別 = C.單據類別 AND A.單據編號 = C.單據編號
	INNER JOIN FIL0041 D ON A.單據類別 = D.單別 AND A.單據編號 = D.單號 AND A.單據序號 = D.序號
WHERE
	A.單據類別 = 'C41' AND
	A.異動類別 = 'A' AND
	B.製程代碼 = 'C31A' AND 
	A.產品編號 <> ' '
	
Union All
/* 淋膜/積層 */
SELECT
	1 庫存參數,
	A.單據類別 單別, 
	A.單據編號 單號,
	A.單據序號 序號,
	to_char('C11') 製令單別,
	to_char(C.歸屬編號) 製令單號,
	to_char(B.製程代碼) 製程代碼,
	C.歸屬序號 加工次數,
	TO_CHAR(A.產品編號) 本製程編號,
	to_char(C.歸屬編號||'_'||B.交貨日期_次批||'_'||A.產品編號) 半成品編號,
	to_char(B.交貨日期_次批)	加工別,
	TO_CHAR(A.前製程編號) 前製程編號,
	to_char(B.文字4) 熟成條件,
	(A.異動單價-A.夾鏈費) 異動數量,
	A.折扣率 接頭數,
	decode(B.製程代碼,'C31B','入庫淋膜','入庫積層') 來源
FROM 
	FIL0040 A
	INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
	INNER JOIN FIL0030 C ON A.單據類別 = C.單據類別 AND A.單據編號 = C.單據編號
	INNER JOIN FIL0041 D ON A.單據類別 = D.單別 AND A.單據編號 = D.單號 AND A.單據序號 = D.序號
WHERE
	A.單據類別 = 'C41' AND
	A.異動類別 = 'A' AND
	B.製程代碼 between 'C31B' and 'C31C' AND 
	A.產品編號 <> ' '
	
Union All
/*印刷檢品/裁切檢品入庫*/
SELECT
	1 庫存參數,
	A.單據類別 單別, 
	A.單據編號 單號,
	A.單據序號 序號,
	to_char('C11') 製令單別,
	to_char(A.前置單號) 製令單號,
	to_char(B.製程代碼) 製程代碼,
	C.歸屬序號 加工次數,
	TO_CHAR(A.產品編號) 本製程編號,
	to_char(A.前置單號||'_'||D.小單位||'_'||A.產品編號) 半成品編號,
	to_char(D.小單位)	加工別,
	TO_CHAR(A.前製程編號) 前製程編號,
	to_char(' ') 熟成條件,
	(A.異動單價-A.夾鏈費) 異動數量,
	A.折扣率 接頭數,
	'入庫檢品' 來源
FROM 
	FIL0040 A
	INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
	INNER JOIN FIL0030 C ON A.單據類別 = C.單據類別 AND A.單據編號 = C.單據編號
	INNER JOIN FIL0041 D ON A.單據類別 = D.單別 AND A.單據編號 = D.單號 AND A.單據序號 = D.序號
WHERE
	A.單據類別 = 'C41' AND
	A.異動類別 = 'A' AND
	(B.製程代碼 = 'C31H' OR B.製程代碼 = 'C31K') AND 
	A.產品編號 <> ' '
	

Union All
/*上臘*/
SELECT
	1 庫存參數,
	A.單據類別 單別, 
	A.單據編號 單號,
	A.單據序號 序號,
	to_char('C11') 製令單別,
	to_char(C.歸屬編號) 製令單號,
	to_char(B.製程代碼) 製程代碼,
	C.歸屬序號 加工次數,
	TO_CHAR(A.產品編號) 本製程編號,
	to_char(C.歸屬編號||'_'||B.交貨日期_次批||'_'||A.產品編號) 半成品編號,
	to_char(B.交貨日期_次批)	加工別,
	TO_CHAR(A.前製程編號) 前製程編號,
	to_char(' ') 熟成條件,
	(A.異動單價-A.夾鏈費) 異動數量,
	A.數值2 接頭數,
	'入庫上臘' 來源
FROM 
	FIL0040 A
	INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
	INNER JOIN FIL0030 C ON A.單據類別 = C.單據類別 AND A.單據編號 = C.單據編號
	INNER JOIN FIL0041 D ON A.單據類別 = D.單別 AND A.單據編號 = D.單號 AND A.單據序號 = D.序號
WHERE
	A.單據類別 = 'C41' AND
	A.異動類別 = 'A' AND
	B.製程代碼 = 'C32D' AND
	A.產品編號 <> ' '	
	
Union All
/* 前製程領料 */
SELECT
	-1 庫存參數,
	A.單據類別 單別, 
	A.單據編號 單號,
	A.單據序號 序號,
	to_char('C11') 製令單別,
	substr(to_char(regexp_substr(D.文數字4,'[^_]+',1,1)),1,20) 製令單號,
	substr(to_char(regexp_substr(D.文數字4,'[^\^]+',1,2)),1,10) 製程代碼,
	0 加工次數,
	TO_CHAR(A.前製程編號) 本製程編號,
	substr(to_char(to_char(regexp_substr(D.文數字4,'[^\^]+',1,1))),1,30) 半成品編號,
	substr(to_char(regexp_substr(D.文數字4,'[^_]+',1,2)),1,10) 加工別,
	TO_CHAR(A.前製程編號) 前製程編號,
	to_char(' ') 熟成條件,
	A.異動數量 異動數量,
	A.材積 接頭數,
	'領用' 來源
FROM 
	FIL0040 A
	INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
	INNER JOIN FIL0030 C ON A.單據類別 = C.單據類別 AND A.單據編號 = C.單據編號
	INNER JOIN FIL0041 D ON A.單據類別 = D.單別 AND A.單據編號 = D.單號 AND A.單據序號 = D.序號
WHERE
	A.單據類別 = 'C41' AND
	A.異動類別 = 'A' AND
	(B.製程代碼 = 'C32D' OR B.製程代碼 ='C31A'  OR B.製程代碼 ='C31B'  OR B.製程代碼 ='C31C'  OR B.製程代碼 ='C31H' OR B.製程代碼 ='C31K') AND 
	A.前製程編號 <> ' '	
		
Union All
/* 裁切第一欄領料 */
SELECT
	-1 庫存參數,
	A.單據類別 單別, 
	A.單據編號 單號,
	A.單據序號 序號,
	to_char('C11') 製令單別,
	to_char(A.前製程編號) 製令單號,
	to_char(A.相關代碼1) 製程代碼,
	C.歸屬序號 加工次數,
	TO_CHAR(A.廠客品號) 本製程編號,
	to_char(A.前製程編號||'_'||B.交貨日期_次批||'_'||A.廠客品號) 半成品編號,
	to_char(B.交貨日期_次批)	加工別,
	TO_CHAR(A.廠客品號) 前製程編號,
	to_char(B.文字4) 熟成條件,
	A.異動數量 異動數量,
	A.燙金費 接頭數,
	'領用裁切' 來源
FROM 
	FIL0040 A
	INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
	INNER JOIN FIL0030 C ON A.單據類別 = C.單據類別 AND A.單據編號 = C.單據編號
	INNER JOIN FIL0041 D ON A.單據類別 = D.單別 AND A.單據編號 = D.單號 AND A.單據序號 = D.序號
WHERE
	A.單據類別 = 'C41' AND
	A.異動類別 = 'A' AND
	B.製程代碼 = 'C31D' AND 
	A.廠客品號 <> ' '	
	
Union All
/* 裁切第二欄領料 */
SELECT
	-1 庫存參數,
	A.單據類別 單別, 
	A.單據編號 單號,
	A.單據序號 序號,
	to_char('C11') 製令單別,
	to_char(A.合併編號) 製令單號,
	to_char(A.相關代碼2) 製程代碼,
	C.歸屬序號 加工次數,
	TO_CHAR(A.前置單號) 本製程編號,
	to_char(A.合併編號||'_'||B.交貨日期_次批||'_'||A.前置單號) 半成品編號,
	to_char(B.交貨日期_次批)	加工別,
	TO_CHAR(A.前置單號) 前製程編號,
	to_char(B.文字4) 熟成條件,
	A.數值1 異動數量,
	A.夾鏈費 接頭數,
	'領用裁切' 來源
FROM 
	FIL0040 A
	INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
	INNER JOIN FIL0030 C ON A.單據類別 = C.單據類別 AND A.單據編號 = C.單據編號
	INNER JOIN FIL0041 D ON A.單據類別 = D.單別 AND A.單據編號 = D.單號 AND A.單據序號 = D.序號
WHERE
	A.單據類別 = 'C41' AND
	A.異動類別 = 'A' AND
	B.製程代碼 = 'C31D' AND 
	A.前置單號 <> ' '	
	
Union All
/* 退庫：類別G*/
SELECT
	1 庫存參數,
	A.單據類別 單別, 
	A.單據編號 單號,
	A.單據序號 序號,
	to_char('C11') 製令單別,
	to_char(A.前置單號) 製令單號,
	to_char(A.前置單別) 製程代碼,
	C.歸屬序號 加工次數,
	TO_CHAR(A.廠客品號) 本製程編號,
	to_char(A.前置單號||'_'||A.單位代碼||'_'||A.廠客品號) 半成品編號,
	to_char(A.單位代碼) 加工別,
	TO_CHAR(A.廠客品號) 前製程編號,
	to_char(B.文字4) 熟成條件,
	A.贈品數量 異動數量,
	A.數值2 接頭數,
	'退庫' 來源
FROM 
	FIL0040 A
	INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
	INNER JOIN FIL0030 C ON A.單據類別 = C.單據類別 AND A.單據編號 = C.單據編號
	INNER JOIN (SELECT DISTINCT A.單據類別, A.單據編號,A.單據序號 FROM FIL004A A) D ON A.單據類別 = D.單據類別 AND A.單據編號 = D.單據編號 AND A.單據序號 = D.單據序號
WHERE
	A.單據類別 = 'C41' AND
	A.異動類別 = 'G' AND
	A.廠客品號 <> ' '
);

-- Oracle user_views
CREATE VIEW "VIEWFIL2072" ("單別", "單號", "序號", "製令單別", "製令單號", "製程代碼", "本製程編號", "加工別", "加工次數", "規格", "圓周") AS (
/* 印刷*/
SELECT
	A.單據類別 單別, 
	A.單據編號 單號,
	A.單據序號 序號,
	to_char(C.歸屬類別) 製令單別,
	to_char(C.歸屬編號) 製令單號,
	to_char(B.製程代碼) 製程代碼,
	TO_CHAR(A.產品編號) 本製程編號,
	to_char(B.交貨日期_次批) 加工別,
	DECODE(C.歸屬序號,0,1,C.歸屬序號) 加工次數,
	D.專案代號 規格,
	A.折扣率 圓周
FROM 
	FIL0040 A
	INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
	INNER JOIN FIL0030 C ON A.單據類別 = C.單據類別 AND A.單據編號 = C.單據編號
	INNER JOIN FIL0041 D ON A.單據類別 = D.單別 AND A.單據編號 = D.單號 AND A.單據序號 = D.序號
WHERE
	A.單據類別 = 'C41' AND
	A.異動類別 = 'A' AND
	B.製程代碼 = 'C31A' AND 
	A.產品編號 <> ' '
	
Union All
/* 淋膜/積層 */
SELECT
	A.單據類別 單別, 
	A.單據編號 單號,
	A.單據序號 序號,
	to_char(C.歸屬類別) 製令單別,
	to_char(C.歸屬編號) 製令單號,
	to_char(B.製程代碼) 製程代碼,
	TO_CHAR(A.產品編號) 本製程編號,
	to_char(B.交貨日期_次批) 加工別,
	DECODE(C.歸屬序號,0,1,C.歸屬序號) 加工次數,
	D.專案代號 規格,
	A.氣閥費 圓周
FROM 
	FIL0040 A
	INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
	INNER JOIN FIL0030 C ON A.單據類別 = C.單據類別 AND A.單據編號 = C.單據編號
	INNER JOIN FIL0041 D ON A.單據類別 = D.單別 AND A.單據編號 = D.單號 AND A.單據序號 = D.序號
WHERE
	A.單據類別 = 'C41' AND
	A.異動類別 = 'A' AND
	B.製程代碼 between 'C31B' and 'C31C' AND 
	A.產品編號 <> ' '
	
Union All
/*印刷檢品/裁切檢品入庫*/
SELECT
	A.單據類別 單別, 
	A.單據編號 單號,
	A.單據序號 序號,
	to_char(A.前置單別) 製令單別,
	to_char(A.前置單號) 製令單號,
	to_char(B.製程代碼) 製程代碼,
	TO_CHAR(A.產品編號) 本製程編號,
	to_char(D.小單位) 加工別,
	C.歸屬序號 加工次數,
	D.專案代號 規格,
	A.氣閥費 圓周
FROM 
	FIL0040 A
	INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
	INNER JOIN FIL0030 C ON A.單據類別 = C.單據類別 AND A.單據編號 = C.單據編號
	INNER JOIN FIL0041 D ON A.單據類別 = D.單別 AND A.單據編號 = D.單號 AND A.單據序號 = D.序號
WHERE
	A.單據類別 = 'C41' AND
	A.異動類別 = 'A' AND
	(B.製程代碼 = 'C31H' OR B.製程代碼 = 'C31K') AND 
	A.產品編號 <> ' '
	

Union All
/*上臘*/
SELECT
	A.單據類別 單別, 
	A.單據編號 單號,
	A.單據序號 序號,
	to_char(C.歸屬類別) 製令單別,
	to_char(C.歸屬編號) 製令單號,
	to_char(B.製程代碼) 製程代碼,
	TO_CHAR(A.產品編號) 本製程編號,
	to_char(B.交貨日期_次批) 加工別,
	C.歸屬序號 加工次數,
	D.專案代號 規格,
	A.折扣率 圓周
FROM 
	FIL0040 A
	INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
	INNER JOIN FIL0030 C ON A.單據類別 = C.單據類別 AND A.單據編號 = C.單據編號
	INNER JOIN FIL0041 D ON A.單據類別 = D.單別 AND A.單據編號 = D.單號 AND A.單據序號 = D.序號
WHERE
	A.單據類別 = 'C41' AND
	A.異動類別 = 'A' AND
	B.製程代碼 = 'C32D' AND
	A.產品編號 <> ' '	
);

-- Oracle user_views
CREATE VIEW "VIEWFIL2073" ("條碼", "接頭數", "庫存數量") AS (
SELECT
	A.條碼,
	MIN(A.接頭數) 接頭數,
	SUM(A.異動數量*庫存參數) 庫存數量
FROM
	(SELECT
			A.庫存參數,
			A.條碼,
			A.異動數量,
			first_value(A.接頭數) over (partition by A.條碼  order by A.最後更新日 desc) 接頭數
	FROM 
		(
		SELECT
			1 庫存參數,
			to_char(C.歸屬編號||'_'||B.交貨日期_次批||'_'||A.產品編號||'^'||B.製程代碼) 條碼,
			(A.異動單價-A.夾鏈費) 異動數量,
			A.數值2 接頭數,
			A.最後更新日
		FROM 
			FIL0040 A
			INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
			INNER JOIN FIL0030 C ON A.單據類別 = C.單據類別 AND A.單據編號 = C.單據編號
		WHERE
			A.單據類別 = 'C41' AND
			A.異動類別 = 'A' AND
			B.製程代碼 = 'C31A' AND 
			A.產品編號 <> ' '
			
		Union All
		/* 淋膜/積層 */
		SELECT
			1 庫存參數,
			to_char(C.歸屬編號||'_'||B.交貨日期_次批||'_'||A.產品編號||'^'||B.製程代碼) 條碼,
			(A.異動單價-A.夾鏈費) 異動數量,
			A.折扣率 接頭數,
			A.最後更新日
		FROM 
			FIL0040 A
			INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
			INNER JOIN FIL0030 C ON A.單據類別 = C.單據類別 AND A.單據編號 = C.單據編號
		WHERE
			A.單據類別 = 'C41' AND
			A.異動類別 = 'A' AND
			B.製程代碼 between 'C31B' and 'C31C' AND 
			A.產品編號 <> ' '
			
		Union All
		/*印刷檢品/裁切檢品入庫*/
		SELECT
			1 庫存參數,
			to_char(A.前置單號||'_'||D.小單位||'_'||A.產品編號||'^'||B.製程代碼) 條碼,
			(A.異動單價-A.夾鏈費) 異動數量,
			A.折扣率 接頭數,
			A.最後更新日
		FROM 
			FIL0040 A
			INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
			INNER JOIN FIL0030 C ON A.單據類別 = C.單據類別 AND A.單據編號 = C.單據編號
			INNER JOIN FIL0041 D ON A.單據類別 = D.單別 AND A.單據編號 = D.單號 AND A.單據序號 = D.序號
		WHERE
			A.單據類別 = 'C41' AND
			A.異動類別 = 'A' AND
			(B.製程代碼 = 'C31H' OR B.製程代碼 = 'C31K') AND 
			A.產品編號 <> ' '
			

		Union All
		/*上臘*/
		SELECT
			1 庫存參數,
			to_char(C.歸屬編號||'_'||B.交貨日期_次批||'_'||A.產品編號||'^'||B.製程代碼) 條碼,
			(A.異動單價-A.夾鏈費) 異動數量,
			A.QRNo 接頭數,
			A.最後更新日
		FROM 
			FIL0040 A
			INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
			INNER JOIN FIL0030 C ON A.單據類別 = C.單據類別 AND A.單據編號 = C.單據編號
		WHERE
			A.單據類別 = 'C41' AND
			A.異動類別 = 'A' AND
			B.製程代碼 = 'C32D' AND
			A.產品編號 <> ' '	
			
		Union All
		/* 前製程領料 */
		SELECT
			-1 庫存參數,
			to_char(D.文數字4) 條碼,
			A.異動數量 異動數量,
			A.材積 接頭數,
			A.最後更新日
		FROM 
			FIL0040 A
			INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
			INNER JOIN FIL0030 C ON A.單據類別 = C.單據類別 AND A.單據編號 = C.單據編號
			INNER JOIN FIL0041 D ON A.單據類別 = D.單別 AND A.單據編號 = D.單號 AND A.單據序號 = D.序號
		WHERE
			A.單據類別 = 'C41' AND
			A.異動類別 = 'A' AND
			(B.製程代碼 = 'C32D' OR B.製程代碼 ='C31A'  OR B.製程代碼 ='C31B'  OR B.製程代碼 ='C31C'  OR B.製程代碼 ='C31H' OR B.製程代碼 ='C31K') AND 
			A.前製程編號 <> ' '	
				
		Union All
		/* 裁切第一欄領料 */
		SELECT
			-1 庫存參數,
			to_char(A.前製程編號||'_'||B.交貨日期_次批||'_'||A.廠客品號||'^'||A.相關代碼1) 條碼,
			A.異動數量 異動數量,
			A.燙金費 接頭數,
			A.最後更新日
		FROM 
			FIL0040 A
			INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
		WHERE
			A.單據類別 = 'C41' AND
			A.異動類別 = 'A' AND
			B.製程代碼 = 'C31D' AND 
			A.廠客品號 <> ' '	
			
		Union All
		/* 裁切第二欄領料 */
		SELECT
			-1 庫存參數,
			to_char(A.合併編號||'_'||B.交貨日期_次批||'_'||A.前置單號||'^'||A.相關代碼2) 條碼,
			A.數值1 異動數量,
			A.夾鏈費 接頭數,
			A.最後更新日
		FROM 
			FIL0040 A
			INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
		WHERE
			A.單據類別 = 'C41' AND
			A.異動類別 = 'A' AND
			B.製程代碼 = 'C31D' AND 
			A.前置單號 <> ' '	
			
		Union All
		/* 退庫：類別G*/
		SELECT
			1 庫存參數,
			to_char(A.前置單號||'_'||A.單位代碼||'_'||A.廠客品號||'^'||A.前置單別) 條碼,
			A.贈品數量 異動數量,
			A.數值2 接頭數,
			A.最後更新日
		FROM 
			FIL0040 A
			INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
			INNER JOIN (SELECT DISTINCT A.單據類別, A.單據編號,A.單據序號 FROM FIL004A A) C ON A.單據類別 = C.單據類別 AND A.單據編號 = C.單據編號 AND A.單據序號 = C.單據序號
		WHERE
			A.單據類別 = 'C41' AND
			A.異動類別 = 'G' AND
			A.廠客品號 <> ' '
		)A
	)A	
GROUP BY
	A.條碼
);

-- Oracle user_views
CREATE VIEW "VIEWFIL2074" ("單別", "單號", "備註") AS (
select
	A.製令單別 單別,
	A.製令單號 單號,
	utl_raw.cast_to_nvarchar2(listagg(utl_raw.cast_to_raw(A.備註||(case when A.相關單號<>' ' then '|'||A.相關單號 end))||utl_raw.cast_to_raw(nvl(B.名稱, ' ')), utl_raw.cast_to_raw(N'　')) within group (order by A.製令單別,A.製令單號,A.材料序號,A.序號)) as 備註
from 
	FIL0037 A
	INNER JOIN FIL0030 M ON M.單據類別=A.製令單別 AND M.單據編號=A.製令單號
	LEFT JOIN ViewFIL3103 B ON A.代碼 = B.代碼
WHERE 
	A.材料序號 = 0 AND  A.屬性='4'
group by 
	A.製令單別,
	A.製令單號,
	A.材料序號
);

-- Oracle user_views
CREATE VIEW "VIEWFIL3101" ("代碼", "名稱", "說明", "最後更新者", "更新者姓名", "最後更新日") AS (                                                                                                                                                SELECT 
	A.系統代碼 代碼, 
	trim(A.系統代碼) || '.' || A.代碼名稱 名稱, 
	A.文字參數 說明,
	A.最後更新者, 
	nvl(B.員工姓名, ' ') 更新者姓名, 
	A.最後更新日 
FROM 
	FIL1014 A
	LEFT JOIN FIL0010 B ON B.員工編號 = A.最後更新者
WHERE 
	A.代碼類別 = to_char('貿易條件'));

-- Oracle user_views
CREATE VIEW "VIEWFIL3102" ("代碼", "名稱", "說明", "最後更新者", "更新者姓名", "最後更新日") AS (                                                                                                                                                SELECT 
	A.系統代碼 代碼, 
	A.代碼名稱 名稱, 
	A.文字參數 說明,
	A.最後更新者, 
	nvl(B.員工姓名, ' ') 更新者姓名, 
	A.最後更新日 
FROM 
	FIL1014 A
	LEFT JOIN FIL0010 B ON B.員工編號 = A.最後更新者
WHERE 
	A.代碼類別 = to_char('幣別'));

-- Oracle user_views
CREATE VIEW "VIEWFIL3103" ("代碼", "名稱", "英文名稱", "進貨類別專用", "庫存乘數", "庫存單位", "最後更新者", "更新者姓名", "最後更新日") AS (                                                                                                                                                
SELECT 
	A.系統代碼 代碼, 
	A.代碼名稱 名稱, 
	A.文字參數 英文名稱,
	A.邏輯值 進貨類別專用,
	decode(Nvl(C.到,' '),' ',1,C.換算率) 庫存乘數,
	decode(Nvl(C.到,' '),' ',A.系統代碼,C.到) 庫存單位,
	A.最後更新者, 
	nvl(B.員工姓名, ' ') 更新者姓名, 
	A.最後更新日 
FROM 
	FIL1014 A 
	LEFT JOIN FIL0010 B ON B.員工編號 = A.最後更新者
	LEFT JOIN FIL0017 C ON C.從 = A.系統代碼
WHERE 
	A.代碼類別 = to_char('單位'));

-- Oracle user_views
CREATE VIEW "VIEWFIL3104" ("代碼", "名稱", "說明", "最後更新者", "更新者姓名", "最後更新日") AS (                                                                                                                                                SELECT 
	A.系統代碼 代碼, 
	A.代碼名稱 名稱, 
	A.文字參數 說明,
	A.最後更新者, 
	nvl(B.員工姓名, ' ') 更新者姓名, 
	A.最後更新日 
FROM 
	FIL1014 A
	LEFT JOIN FIL0010 B ON B.員工編號 = A.最後更新者
WHERE 
	A.代碼類別 = to_char('發票類別'));

-- Oracle user_views
CREATE VIEW "VIEWFIL3105" ("代碼", "名稱", "說明", "識別", "部門限定", "流水編號", "最後更新者", "更新者姓名", "最後更新日") AS (                                                                                                                                                SELECT 
	A.系統代碼 代碼, 
	A.代碼名稱 名稱, 
	A.文字參數 說明,
	A.數字參數 識別,
	A.數字參數二 部門限定,
	trim(to_char(A.英數參數)) 流水編號,
	A.最後更新者, 
	nvl(B.員工姓名, ' ') 更新者姓名, 
	A.最後更新日 
FROM 
	FIL1014 A
	LEFT JOIN FIL0010 B ON B.員工編號 = A.最後更新者
WHERE 
	A.代碼類別 = to_char('職稱代碼'));

-- Oracle user_views
CREATE VIEW "VIEWFIL3106" ("代碼", "名稱", "說明", "倉別代碼", "倉別名稱", "廠別編號", "廠別名稱", "全稱", "組別", "最後更新者", "更新者姓名", "最後更新日") AS (                                                                                                                                                SELECT 
	A.系統代碼 代碼, 
	A.代碼名稱 名稱, 
	A.文字參數 說明,
	A.文字參數一 倉別代碼,
	nvl(C.全稱,' ') 倉別名稱,
	C.廠別編號 廠別編號,
	nvl(C.廠別名稱,' ') 廠別名稱,
	nvl(C.全稱,' ')||'.'||A.代碼名稱 全稱,
	A.數字參數 組別,
	A.最後更新者, 
	nvl(B.員工姓名, ' ') 更新者姓名, 
	A.最後更新日 
FROM 
	FIL1014 A
	LEFT JOIN FIL0010 B ON B.員工編號 = A.最後更新者
	LEFT JOIN ViewFIL310R C ON A.文字參數一=C.代碼
WHERE 
	A.代碼類別 = to_char('庫別代碼'));

-- Oracle user_views
CREATE VIEW "VIEWFIL3107" ("代碼", "名稱", "說明", "最後更新者", "更新者姓名", "最後更新日") AS (                                                                                                                                                SELECT 
	A.系統代碼 代碼, 
	A.代碼名稱 名稱, 
	A.文字參數 說明,
	A.最後更新者, 
	nvl(B.員工姓名, ' ') 更新者姓名, 
	A.最後更新日 
FROM 
	FIL1014 A
	LEFT JOIN FIL0010 B ON B.員工編號 = A.最後更新者
WHERE 
	A.代碼類別 = to_char('付款條件'));

-- Oracle user_views
CREATE VIEW "VIEWFIL3108" ("代碼", "名稱", "說明", "最後更新者", "更新者姓名", "最後更新日") AS (                                                                                                                                                SELECT 
	A.系統代碼 代碼, 
	A.代碼名稱 名稱, 
	A.文字參數 說明,
	A.最後更新者, 
	nvl(B.員工姓名, ' ') 更新者姓名, 
	A.最後更新日 
FROM 
	FIL1014 A
	LEFT JOIN FIL0010 B ON B.員工編號 = A.最後更新者
WHERE 
	A.代碼類別 = to_char('收款條件'));

-- Oracle user_views
CREATE VIEW "VIEWFIL3109" ("代碼", "名稱", "說明", "最後更新者", "更新者姓名", "最後更新日") AS (                                                                                                                                                SELECT 
	A.系統代碼 代碼, 
	A.代碼名稱 名稱, 
	A.文字參數 說明,
	A.最後更新者, 
	nvl(B.員工姓名, ' ') 更新者姓名, 
	A.最後更新日 
FROM 
	FIL1014 A
	LEFT JOIN FIL0010 B ON B.員工編號 = A.最後更新者
WHERE 
	A.代碼類別 = to_char('油墨種類'));

-- Oracle user_views
CREATE VIEW "VIEWFIL310A" ("代碼", "名稱", "說明", "最後更新者", "更新者姓名", "最後更新日") AS (                                                                                                                                                SELECT 
	A.系統代碼 代碼, 
	A.代碼名稱 名稱, 
	A.文字參數 說明,
	A.最後更新者, 
	nvl(B.員工姓名, ' ') 更新者姓名, 
	A.最後更新日 
FROM 
	FIL1014 A
	LEFT JOIN FIL0010 B ON B.員工編號 = A.最後更新者
WHERE 
	A.代碼類別 = to_char('印刷色順'));

-- Oracle user_views
CREATE VIEW "VIEWFIL310B" ("代碼", "名稱", "說明", "批號管理", "最後更新者", "更新者姓名", "最後更新日") AS (                                                                                                                                                SELECT 
	A.系統代碼 代碼, 
	A.代碼名稱 名稱, 
	A.文字參數 說明,
	A.邏輯值 批號管理,
	A.最後更新者, 
	nvl(B.員工姓名, ' ') 更新者姓名, 
	A.最後更新日 
FROM 
	FIL1014 A
	LEFT JOIN FIL0010 B ON B.員工編號 = A.最後更新者
WHERE 
	A.代碼類別 = to_char('物料大類'));

-- Oracle user_views
CREATE VIEW "VIEWFIL310C" ("代碼", "名稱", "說明", "最後更新者", "更新者姓名", "最後更新日") AS (                                                                                                                                                SELECT 
	A.系統代碼 代碼, 
	A.代碼名稱 名稱, 
	A.文字參數 說明,
	A.最後更新者, 
	nvl(B.員工姓名, ' ') 更新者姓名, 
	A.最後更新日 
FROM 
	FIL1014 A
	LEFT JOIN FIL0010 B ON B.員工編號 = A.最後更新者
WHERE 
	A.代碼類別 = to_char('包裝方式'));

-- Oracle user_views
CREATE VIEW "VIEWFIL310D" ("代碼", "名稱", "說明", "大類", "最後更新者", "更新者姓名", "最後更新日") AS (                                                                                                                                                SELECT 
	A.系統代碼 代碼, 
	A.代碼名稱 名稱, 
	A.文字參數 說明,
	nvl(C.名稱, ' ') 大類,
	A.最後更新者, 
	nvl(B.員工姓名, ' ') 更新者姓名, 
	A.最後更新日 
FROM 
	FIL1014 A
	LEFT JOIN FIL0010 B ON B.員工編號 = A.最後更新者
	LEFT JOIN ViewFIL310S C ON A.英數參數 = C.代碼
WHERE 
	A.代碼類別 = to_char('製袋型態'));

-- Oracle user_views
CREATE VIEW "VIEWFIL310E" ("代碼", "名稱", "說明", "最後更新者", "更新者姓名", "最後更新日") AS (                                                                                                                                                SELECT 
	A.系統代碼 代碼, 
	A.代碼名稱 名稱, 
	A.文字參數 說明,
	A.最後更新者, 
	nvl(B.員工姓名, ' ') 更新者姓名, 
	A.最後更新日 
FROM 
	FIL1014 A
	LEFT JOIN FIL0010 B ON B.員工編號 = A.最後更新者
WHERE 
	A.代碼類別 = to_char('稅別代碼'));

-- Oracle user_views
CREATE VIEW "VIEWFIL310F" ("代碼", "名稱", "說明", "最後更新者", "更新者姓名", "最後更新日") AS (                                                                                                                                                SELECT 
	A.系統代碼 代碼, 
	A.代碼名稱 名稱, 
	A.文字參數 說明,
	A.最後更新者, 
	nvl(B.員工姓名, ' ') 更新者姓名, 
	A.最後更新日 
FROM 
	FIL1014 A
	LEFT JOIN FIL0010 B ON B.員工編號 = A.最後更新者
WHERE 
	A.代碼類別 = to_char('區域代號'));

-- Oracle user_views
CREATE VIEW "VIEWFIL310G" ("代碼", "名稱", "說明", "最後更新者", "更新者姓名", "最後更新日") AS (                                                                                                                                                SELECT 
	A.系統代碼 代碼, 
	A.代碼名稱 名稱, 
	A.文字參數 說明,
	A.最後更新者, 
	nvl(B.員工姓名, ' ') 更新者姓名, 
	A.最後更新日 
FROM 
	FIL1014 A
	LEFT JOIN FIL0010 B ON B.員工編號 = A.最後更新者
WHERE 
	A.代碼類別 = to_char('國別代號'));

-- Oracle user_views
CREATE VIEW "VIEWFIL310H" ("代碼", "名稱", "說明", "最後更新者", "更新者姓名", "最後更新日") AS (                                                                                                                                                SELECT 
	A.系統代碼 代碼, 
	A.代碼名稱 名稱, 
	A.文字參數 說明,
	A.最後更新者, 
	nvl(B.員工姓名, ' ') 更新者姓名, 
	A.最後更新日 
FROM 
	FIL1014 A
	LEFT JOIN FIL0010 B ON B.員工編號 = A.最後更新者
WHERE 
	A.代碼類別 = to_char('廠商分類'));

-- Oracle user_views
CREATE VIEW "VIEWFIL310I" ("代碼", "名稱", "說明", "最後更新者", "更新者姓名", "最後更新日") AS (                                                                                                                                                SELECT 
	A.系統代碼 代碼, 
	A.代碼名稱 名稱, 
	A.文字參數 說明,
	A.最後更新者, 
	nvl(B.員工姓名, ' ') 更新者姓名, 
	A.最後更新日 
FROM 
	FIL1014 A
	LEFT JOIN FIL0010 B ON B.員工編號 = A.最後更新者
WHERE 
	A.代碼類別 = to_char('客戶型態'));

-- Oracle user_views
CREATE VIEW "VIEWFIL310J" ("代碼", "名稱", "說明", "最後更新者", "更新者姓名", "最後更新日") AS (                                                                                                                                                SELECT 
	A.系統代碼 代碼, 
	A.代碼名稱 名稱, 
	A.文字參數 說明,
	A.最後更新者, 
	nvl(B.員工姓名, ' ') 更新者姓名, 
	A.最後更新日 
FROM 
	FIL1014 A
	LEFT JOIN FIL0010 B ON B.員工編號 = A.最後更新者
WHERE 
	A.代碼類別 = to_char('廠牌代碼'));

-- Oracle user_views
CREATE VIEW "VIEWFIL310K" ("代碼", "名稱", "說明", "淋膜冷鏈", "最後更新者", "更新者姓名", "最後更新日") AS (                                                                                                                                                SELECT 
	A.系統代碼 代碼, 
	A.代碼名稱 名稱, 
	A.文字參數 說明,
	A.邏輯值	淋膜冷鏈,
	A.最後更新者, 
	nvl(B.員工姓名, ' ') 更新者姓名, 
	A.最後更新日 
FROM 
	FIL1014 A
	LEFT JOIN FIL0010 B ON B.員工編號 = A.最後更新者
WHERE 
	A.代碼類別 = to_char('溫度區間'));

-- Oracle user_views
CREATE VIEW "VIEWFIL310L" ("代碼", "名稱", "說明", "淋膜冷鏈", "最後更新者", "更新者姓名", "最後更新日") AS (                                                                                                                                                SELECT 
	A.系統代碼 代碼, 
	A.代碼名稱 名稱, 
	A.文字參數 說明,
	A.邏輯值	淋膜冷鏈,
	A.最後更新者, 
	nvl(B.員工姓名, ' ') 更新者姓名, 
	A.最後更新日 
FROM 
	FIL1014 A
	LEFT JOIN FIL0010 B ON B.員工編號 = A.最後更新者
WHERE 
	A.代碼類別 = to_char('時間區間'));

-- Oracle user_views
CREATE VIEW "VIEWFIL310M" ("代碼", "名稱", "說明", "最後更新者", "更新者姓名", "最後更新日") AS (                                                                                                                                                SELECT 
	A.系統代碼 代碼, 
	A.代碼名稱 名稱, 
	A.文字參數 說明,
	A.最後更新者, 
	nvl(B.員工姓名, ' ') 更新者姓名, 
	A.最後更新日 
FROM 
	FIL1014 A
	LEFT JOIN FIL0010 B ON B.員工編號 = A.最後更新者
WHERE 
	A.代碼類別 = to_char('壓紋類別'));

-- Oracle user_views
CREATE VIEW "VIEWFIL310N" ("代碼類別", "代碼", "名稱", "說明", "加簽通知人", "加簽通知人代碼", "排程", "前製程開放輸入", "本製程開放輸入", "生產條件投入製程", "最後更新者", "更新者姓名", "最後更新日") AS (                                                                                                                                                
SELECT
	A.代碼類別,
	A.系統代碼 代碼, 
	A.代碼名稱 名稱, 
	A.文字參數 說明,
	A.文字參數四 加簽通知人,
	A.文字參數五 加簽通知人代碼,
	A.邏輯值 排程,
	A.邏輯值一 前製程開放輸入 ,
	A.邏輯值二	本製程開放輸入 ,
	A.邏輯值三 生產條件投入製程,
	A.最後更新者, 
	nvl(B.員工姓名, ' ') 更新者姓名, 
	A.最後更新日 
FROM 
	FIL1014 A
	LEFT JOIN FIL0010 B ON B.員工編號 = A.最後更新者
WHERE 
	A.代碼類別 = to_char('製程代碼') or A.代碼類別 = '單據類別');

-- Oracle user_views
CREATE VIEW "VIEWFIL310O" ("代碼", "名稱", "說明", "製程代碼", "製程名稱", "製程工站", "庫存起算日", "預估起算日", "最後更新者", "更新者姓名", "最後更新日") AS (                                                                                                                                                SELECT 
	A.系統代碼 代碼, 
	A.代碼名稱 名稱, 
	A.文字參數 說明,
	A.英數參數 製程代碼,
	nvl(C.名稱,' ') 製程名稱,
	nvl(C.名稱,' ') || '.' ||A.代碼名稱||'('||A.文字參數||')' 製程工站,
	A.日期 庫存起算日,
	A.日期一 預估起算日,
	A.最後更新者, 
	nvl(B.員工姓名, ' ') 更新者姓名, 
	A.最後更新日 
FROM 
	FIL1014 A
	LEFT JOIN FIL0010 B ON B.員工編號 = A.最後更新者
	LEFT JOIN ViewFIL310N C ON A.英數參數 = C.代碼
WHERE 
	A.代碼類別 = to_char('工站代碼'));

-- Oracle user_views
CREATE VIEW "VIEWFIL310P" ("代碼", "名稱", "名稱無代碼", "說明", "工站", "工站名稱", "製程代碼", "製程名稱", "委外", "部門編號", "部門名稱", "庫位代碼", "庫位名稱", "印刷上蠟版銅", "單位主管流水編號", "檢品主管流水編號", "停用", "生管排程", "排程順序", "抓取PLC資料", "不需要CCP", "最後更新者", "更新者姓名", "最後更新日") AS (
SELECT 
	A.系統代碼 代碼, 
	trim(A.代碼名稱) || '(' || trim(A.系統代碼) || ')' 名稱, 
	A.代碼名稱 名稱無代碼, 
	A.文字參數 說明,
	A.英數參數 工站,
	nvl(C.製程工站, ' ') 工站名稱,
	nvl(C.製程代碼, ' ') 製程代碼,
	nvl(C.製程名稱, ' ') 製程名稱,
	DECODE(A.數字參數,0,0,1) 委外,
	A.文字參數一 部門編號,
	nvl(DECODE(A.數字參數,0,D.名稱,E.名稱), ' ') 部門名稱,
	A.文字參數二 庫位代碼,
	nvl(F.名稱, ' ') 庫位名稱,
	A.數字參數二 印刷上蠟版銅,
	A.文字參數三 單位主管流水編號,
	A.文字參數四 檢品主管流水編號,
	case when A.數字參數三 = 0 then 0 when A.數字參數三 <= TO_NUMBER(TO_CHAR(SYSDATE,'YYYYMMDD')) then 1 else 0 end 停用,
	A.數字參數四 生管排程,
	A.數字參數五 排程順序,
	A.邏輯值 抓取PLC資料,
	A.邏輯值一 不需要CCP,
	A.最後更新者, 
	nvl(B.員工姓名, ' ') 更新者姓名, 
	A.最後更新日 
FROM 
	FIL1014 A
	LEFT JOIN FIL0010 B ON B.員工編號 = A.最後更新者
	LEFT JOIN ViewFIL310O C ON A.英數參數 = C.代碼
	LEFT JOIN ViewFIL0012014 D ON A.文字參數一 = D.編號 AND  D.類別='1'
	LEFT JOIN ViewFIL0012014 E ON A.文字參數一 = E.編號 AND  E.類別='2'
	LEFT JOIN ViewFIL3106 F ON A.文字參數二 = F.代碼
WHERE 
	A.代碼類別 = to_char('機台代碼'));

-- Oracle user_views
CREATE VIEW "VIEWFIL310Q" ("工站代碼", "工站名稱", "機台代碼", "機台名稱") AS (                                                                                                                                                SELECT
	A.工站 工站代碼,
	A.工站名稱,
	listagg( to_char( '□' || trim(A.代碼)), ' ') within group (order by A.代碼) as 機台代碼,
	listagg( to_char( '□' || trim(A.名稱)), ' ') within group (order by A.代碼) as 機台名稱
FROM
	ViewFIL310P A
GROUP BY
	A.工站,
	A.工站名稱);

-- Oracle user_views
CREATE VIEW "VIEWFIL310R" ("代碼", "名稱", "說明", "廠別編號", "廠別名稱", "全稱", "最後更新者", "更新者姓名", "最後更新日") AS (                                                                                                                                                SELECT 
	A.系統代碼 代碼, 
	A.代碼名稱 名稱, 
	A.文字參數 說明,
	C.廠別編號 廠別編號,
	nvl(C.廠別名稱,' ') 廠別名稱,
	nvl(C.廠別名稱,' ')||'.'||A.代碼名稱 全稱,
	A.最後更新者, 
	nvl(B.員工姓名, ' ') 更新者姓名, 
	A.最後更新日 
FROM 
	FIL1014 A
	LEFT JOIN FIL0010 B ON B.員工編號 = A.最後更新者
	LEFT JOIN ViewFIL1013 C ON A.文字參數一=C.廠別編號
WHERE 
	A.代碼類別 = to_char('倉別代碼'));

-- Oracle user_views
CREATE VIEW "VIEWFIL310S" ("代碼", "名稱", "說明", "最後更新者", "更新者姓名", "最後更新日") AS (                                                                                                                                                SELECT 
	A.系統代碼 代碼, 
	A.代碼名稱 名稱, 
	A.文字參數 說明,
	A.最後更新者, 
	nvl(B.員工姓名, ' ') 更新者姓名, 
	A.最後更新日 
FROM 
	FIL1014 A
	LEFT JOIN FIL0010 B ON B.員工編號 = A.最後更新者
WHERE 
	A.代碼類別 = to_char('製袋大類'));

-- Oracle user_views
CREATE VIEW "VIEWFIL310T" ("代碼", "名稱", "說明", "最後更新者", "更新者姓名", "最後更新日") AS (                                                                                                                                                SELECT 
	A.系統代碼 代碼, 
	A.代碼名稱 名稱, 
	A.文字參數 說明,
	A.最後更新者, 
	nvl(B.員工姓名, ' ') 更新者姓名, 
	A.最後更新日 
FROM 
	FIL1014 A
	LEFT JOIN FIL0010 B ON B.員工編號 = A.最後更新者
WHERE 
	A.代碼類別 = to_char('工作代碼'));

-- Oracle user_views
CREATE VIEW "VIEWFIL310U" ("代碼", "常用語句", "最後更新者", "更新者姓名", "最後更新日") AS (                                                                                                                                                SELECT 
	A.系統代碼 代碼, 
	A.文字參數 常用語句, 
	A.最後更新者, 
	nvl(B.員工姓名, ' ') 更新者姓名, 
	A.最後更新日 
FROM 
	FIL1014 A
	LEFT JOIN FIL0010 B ON B.員工編號 = A.最後更新者
WHERE 
	A.代碼類別 = to_char('常用語句'));

-- Oracle user_views
CREATE VIEW "VIEWFIL310UA" ("代碼", "常用語句", "最後更新者", "更新者姓名", "最後更新日") AS (                                                                                                                                                SELECT 
	A.系統代碼 代碼, 
	A.文字參數 常用語句, 
	A.最後更新者, 
	nvl(B.員工姓名, ' ') 更新者姓名, 
	A.最後更新日 
FROM 
	FIL1014 A
	LEFT JOIN FIL0010 B ON B.員工編號 = A.最後更新者
WHERE 
	A.代碼類別 = to_char('報價語句'));

-- Oracle user_views
CREATE VIEW "VIEWFIL310UB" ("代碼", "必選", "報價必選", "條文", "最後更新者", "更新者姓名", "最後更新日") AS (                                                                                                                                                SELECT 
	A.系統代碼 代碼,
	A.邏輯值	 必選,
	A.邏輯值一 報價必選,
	A.文字參數 條文, 
	A.最後更新者, 
	nvl(B.員工姓名, ' ') 更新者姓名, 
	A.最後更新日 
FROM 
	FIL1014 A
	LEFT JOIN FIL0010 B ON B.員工編號 = A.最後更新者
WHERE 
	A.代碼類別 = to_char('報價條文'));

-- Oracle user_views
CREATE VIEW "VIEWFIL310UC" ("代碼", "採購必選", "必選", "條文", "最後更新者", "更新者姓名", "最後更新日") AS (                                                                                                                                                SELECT 
	A.系統代碼 代碼,
	A.邏輯值	 採購必選,
	A.邏輯值一 必選,
	A.文字參數 條文, 
	A.最後更新者, 
	nvl(B.員工姓名, ' ') 更新者姓名, 
	A.最後更新日 
FROM 
	FIL1014 A
	LEFT JOIN FIL0010 B ON B.員工編號 = A.最後更新者
WHERE 
	A.代碼類別 = to_char('採購條文'));

-- Oracle user_views
CREATE VIEW "VIEWFIL310V" ("代碼", "名稱", "最後更新者", "更新者姓名", "最後更新日") AS (                                                                                                                                                SELECT 
	A.系統代碼 代碼, 
	A.代碼名稱 名稱, 
	A.最後更新者, 
	nvl(B.員工姓名, ' ') 更新者姓名, 
	A.最後更新日 
FROM 
	FIL1014 A
	LEFT JOIN FIL0010 B ON B.員工編號 = A.最後更新者
WHERE 
	A.代碼類別 = to_char('外箱標示'));

-- Oracle user_views
CREATE VIEW "VIEWFIL310W" ("代碼", "名稱", "最後更新者", "更新者姓名", "最後更新日") AS (                                                                                                                                                SELECT 
	A.系統代碼 代碼, 
	A.代碼名稱 名稱, 
	A.最後更新者, 
	nvl(B.員工姓名, ' ') 更新者姓名, 
	A.最後更新日 
FROM 
	FIL1014 A
	LEFT JOIN FIL0010 B ON B.員工編號 = A.最後更新者
WHERE 
	A.代碼類別 = to_char('不良原因'));

-- Oracle user_views
CREATE VIEW "VIEWFIL310WA" ("代碼", "名稱", "最後更新者", "更新者姓名", "最後更新日") AS (                                                                                                                                          SELECT 
	A.系統代碼 代碼, 
	A.代碼名稱 名稱, 
	A.最後更新者, 
	nvl(B.員工姓名, ' ') 更新者姓名, 
	A.最後更新日 
FROM 
	FIL1014 A
	LEFT JOIN FIL0010 B ON B.員工編號 = A.最後更新者
WHERE 
	A.代碼類別 = to_char('客戶要求'));

-- Oracle user_views
CREATE VIEW "VIEWFIL310X" ("代碼", "名稱", "說明", "最後更新者", "更新者姓名", "最後更新日") AS (                                                                                                                                                SELECT 
	A.系統代碼 代碼, 
	A.代碼名稱 名稱, 
	A.文字參數 說明,
	A.最後更新者, 
	nvl(B.員工姓名, ' ') 更新者姓名, 
	A.最後更新日 
FROM 
	FIL1014 A
	LEFT JOIN FIL0010 B ON B.員工編號 = A.最後更新者
WHERE 
	A.代碼類別 = to_char('裁切方向'));

-- Oracle user_views
CREATE VIEW "VIEWFIL310Y" ("代碼", "IP", "說明", "裁切標籤目錄", "限定製程代碼", "限定製程", "最後更新者", "更新者姓名", "最後更新日") AS (                                                                                                                                                SELECT 
	A.系統代碼 代碼, 
	A.代碼名稱 IP, 
	A.文字參數 說明,
	A.英數參數 裁切標籤目錄,
	trim(A.文字參數一||decode(nvl(A.文字參數二,' '),' ',' ',','||A.文字參數二)) 限定製程代碼,
	trim(nvl(C.名稱,' ')||decode(A.文字參數二,'E22',',裁切入庫',decode(nvl(D.名稱,' '),' ',' ',','||D.名稱))) 限定製程,
	A.最後更新者, 
	nvl(B.員工姓名, ' ') 更新者姓名, 
	A.最後更新日 
FROM 
	FIL1014 A
	LEFT JOIN FIL0010 B ON B.員工編號 = A.最後更新者
	LEFT JOIN ViewFIL310N C ON C.代碼 = A.文字參數一
	LEFT JOIN ViewFIL310N D ON D.代碼 = A.文字參數二
WHERE 
	A.代碼類別 = to_char('標籤機'));

-- Oracle user_views
CREATE VIEW "VIEWFIL310Z" ("材質", "溫度", "說明", "最後更新者", "更新者姓名", "最後更新日") AS (                                                                                                                                                SELECT 
	A.系統代碼 材質, 
	A.代碼名稱 溫度, 
	A.文字參數 說明,
	A.最後更新者, 
	nvl(B.員工姓名, ' ') 更新者姓名, 
	A.最後更新日 
FROM 
	FIL1014 A
	LEFT JOIN FIL0010 B ON B.員工編號 = A.最後更新者
WHERE 
	A.代碼類別 = to_char('材質溫度'));

-- Oracle user_views
CREATE VIEW "VIEWFIL3110" ("代碼", "名稱", "最後更新者", "更新者姓名", "最後更新日") AS ( 
SELECT 
	A.系統代碼 代碼, 
	A.代碼名稱 名稱, 
	A.最後更新者, 
	nvl(B.員工姓名, ' ') 更新者姓名, 
	A.最後更新日 
FROM 
	FIL1014 A
	LEFT JOIN FIL0010 B ON B.員工編號 = A.最後更新者
WHERE 
	A.代碼類別 = to_char('氣閥種類'));

-- Oracle user_views
CREATE VIEW "VIEWFIL3111" ("代碼", "名稱", "說明", "最後更新者", "更新者姓名", "最後更新日") AS (
SELECT 
	A.系統代碼 代碼, 
	A.代碼名稱 名稱, 
	A.文字參數 說明,
	A.最後更新者, 
	nvl(B.員工姓名, ' ') 更新者姓名, 
	A.最後更新日 
FROM 
	FIL1014 A
	LEFT JOIN FIL0010 B ON B.員工編號 = A.最後更新者
WHERE 
	A.代碼類別 = to_char('運送方式'));

-- Oracle user_views
CREATE VIEW "VIEWFIL3112" ("代碼類別", "產品編號", "品名", "規格", "加工別", "系統生成", "庫存異動日期", "加工別名稱", "色順", "代碼", "滿版", "圓周", "版長", "庫位代碼", "色順說明", "共版", "共版代碼", "製造日期", "停用日期", "說明", "停用原因", "停用", "倉管確認", "QRCODE手動確認", "最後更新者", "更新者姓名", "尾碼", "有子版", "最後更新日") AS (
SELECT 
	A.代碼類別, 
	A.代碼名稱 產品編號,
	D.品名,
	D.規格,
	A.文字參數五 加工別,
	A.邏輯值 系統生成,
	A.日期 庫存異動日期,
	case TRIM(A.文字參數五)
		when 'A' then 'A材' 
		when 'B' then 'B材' 
		when 'C' then '底邊' 
		when 'D' then 'A側' 
		when 'E' then 'B側' 
		else ' ' end 加工別名稱,
	A.文字參數一 色順,
	A.系統代碼 代碼,
	DECODE(A.數字參數五,0,0,1) 滿版,
	A.數字參數 圓周,
	A.數字參數二 版長,
	A.文字參數二 庫位代碼,
	A.文字參數三 色順說明,
	DECODE(A.數字參數四,0,0,1) 共版,
	A.文字參數四 共版代碼,
	trim(decode(A.數字參數六,0,'00000000',to_char(A.數字參數六))) 製造日期,
	trim(decode(A.數字參數三,0,'00000000',to_char(A.數字參數三))) 停用日期,
	A.文字參數 說明,
	A.英數參數 停用原因,
	decode(A.數字參數三,0,0,1) 停用,
	A.邏輯值一 倉管確認,
	A.邏輯值二 QRcode手動確認,
	A.最後更新者,
	NVL(Z1.員工姓名,' ') 更新者姓名,
	substr(REGEXP_SUBSTR(A.系統代碼,'[^_]+',1,3,'i'),3,1) 尾碼, 
	decode(nvl(C.版銅編號,' '),' ',0,1) 有子版,
	A.最後更新日
FROM 
	FIL1014 A
	/*特殊欄位*/
	LEFT JOIN FIL003C C ON C.版銅編號 = A.系統代碼
	LEFT JOIN FIL0012 D ON A.代碼名稱 = D.產品編號
	LEFT JOIN FIL0010 Z1 ON A.最後更新者 = Z1.員工編號
WHERE
	A.代碼類別 = to_char('版銅代碼')
);

-- Oracle user_views
CREATE VIEW "VIEWFIL3113" ("代碼", "IP", "類別", "說明", "最後更新者", "更新者姓名", "最後更新日") AS (                                                                                                                                                SELECT 
	A.系統代碼 代碼, 
	A.代碼名稱 IP, 
	A.文字參數一 類別,
	A.文字參數 說明,
	A.最後更新者, 
	nvl(B.員工姓名, ' ') 更新者姓名, 
	A.最後更新日 
FROM 
	FIL1014 A
	LEFT JOIN FIL0010 B ON B.員工編號 = A.最後更新者
WHERE 
	A.代碼類別 = to_char('IOT設備'));

-- Oracle user_views
CREATE VIEW "VIEWFIL3114" ("代碼", "名稱", "最後更新者", "更新者姓名", "最後更新日") AS (
SELECT 
	A.系統代碼 代碼, 
	A.代碼名稱 名稱, 
	A.最後更新者, 
	nvl(B.員工姓名, ' ') 更新者姓名, 
	A.最後更新日 
FROM 
	FIL1014 A
	LEFT JOIN FIL0010 B ON B.員工編號 = A.最後更新者
WHERE 
	A.代碼類別 = to_char('品質異常大類'));

-- Oracle user_views
CREATE VIEW "VIEWFIL3115" ("代碼", "名稱", "最後更新者", "更新者姓名", "最後更新日") AS (
SELECT 
	A.系統代碼 代碼, 
	A.代碼名稱 名稱, 
	A.最後更新者, 
	nvl(B.員工姓名, ' ') 更新者姓名, 
	A.最後更新日 
FROM 
	FIL1014 A
	LEFT JOIN FIL0010 B ON B.員工編號 = A.最後更新者
WHERE 
	A.代碼類別 = to_char('品質異常原因'));

-- Oracle user_views
CREATE VIEW "VIEWFIL3116" ("代碼", "名稱", "尺寸說明", "展開尺寸", "價格", "一般夾鏈", "口袋式夾鏈", "樣式", "魔鬼氈夾鏈", "最後更新者", "更新者姓名", "最後更新日") AS (
SELECT 
	A.系統代碼 代碼, 
	A.代碼名稱 名稱, 
	A.文字參數 尺寸說明,
	A.文字參數一 展開尺寸,
	A.數字參數 價格,
	A.邏輯值 一般夾鏈,
	A.邏輯值一 口袋式夾鏈,
	A.邏輯值二 樣式,
	A.邏輯值三 魔鬼氈夾鏈,
	A.最後更新者, 
	nvl(B.員工姓名, ' ') 更新者姓名, 
	A.最後更新日 
FROM 
	FIL1014 A
	LEFT JOIN FIL0010 B ON B.員工編號 = A.最後更新者
WHERE 
	A.代碼類別 = to_char('袋型'));

-- Oracle user_views
CREATE VIEW "VIEWFIL3117" ("代碼", "名稱", "說明", "密度", "單位", "停用", "最近成本單價", "最近單位報價", "最後更新者", "更新者姓名", "最後更新日") AS (
SELECT 
	A.系統代碼 代碼, 
	A.代碼名稱 名稱, 
	A.文字參數 說明,
	A.文字參數一 密度,
	A.文字參數二 單位,
	A.邏輯值 停用,	
	C.成本單價 最近成本單價,
	C.單位報價 最近單位報價,
	A.最後更新者, 
	nvl(B.員工姓名, ' ') 更新者姓名, 
	A.最後更新日 
FROM 
	FIL1014 A
	LEFT JOIN FIL0010 B ON B.員工編號 = A.最後更新者
	LEFT JOIN 
	(SELECT DISTINCT 代碼,FIRST_VALUE(成本單價) OVER(PARTITION BY 代碼 ORDER BY 生效日期 DESC) 成本單價,FIRST_VALUE(單位報價) OVER(PARTITION BY 代碼 ORDER BY 生效日期 DESC) 單位報價 FROM FIL4002 WHERE 生效日期<=TO_CHAR(SYSDATE,'yyyymmdd')) C ON C.代碼=A.系統代碼
WHERE 
	A.代碼類別 = to_char('材枓進貨類別'));

-- Oracle user_views
CREATE VIEW "VIEWFIL3118" ("系統代碼", "進貨價格倍率", "貼合每層價格", "貼合工資", "塑膠粒每層加價", "每色價格", "印刷工資", "氣閥工資", "鐵條工資", "滿版價格") AS (
SELECT 
	A.系統代碼 系統代碼,
	A.數字參數 進貨價格倍率,
	A.數字參數二 貼合每層價格, 
	A.數字參數三 貼合工資,
	A.數字參數四 塑膠粒每層加價,
	A.數字參數五 每色價格,
	A.數字參數六 印刷工資,
	A.數字參數七 氣閥工資,
	A.數字參數八 鐵條工資,
	A.數字參數九 滿版價格
FROM 
	FIL1014 A
WHERE 
	A.代碼類別 = 'MC' AND A.系統代碼='估價單參數');

-- Oracle user_views
CREATE VIEW "VIEWFIL3119" ("代碼", "名稱", "特殊系列", "全稱", "最後更新者", "更新者姓名", "最後更新日") AS (
SELECT 
	A.系統代碼 代碼, 
	A.代碼名稱 名稱, 
	A.邏輯值 特殊系列,
	A.系統代碼||'.'||A.代碼名稱 全稱,
	A.最後更新者, 
	nvl(B.員工姓名, ' ') 更新者姓名, 
	A.最後更新日 
FROM 
	FIL1014 A
	LEFT JOIN FIL0010 B ON B.員工編號 = A.最後更新者
WHERE 
	A.代碼類別 = to_char('燙金顏色'));

-- Oracle user_views
CREATE VIEW "VIEWFIL3120" ("代碼", "常用語句", "最後更新者", "更新者姓名", "最後更新日") AS (                                                                                                                                                SELECT 
	A.系統代碼 代碼, 
	A.文字參數 常用語句, 
	A.最後更新者, 
	nvl(B.員工姓名, ' ') 更新者姓名, 
	A.最後更新日 
FROM 
	FIL1014 A
	LEFT JOIN FIL0010 B ON B.員工編號 = A.最後更新者
WHERE 
	A.代碼類別 = to_char('排程語句'));

-- Oracle user_views
CREATE VIEW "VIEWFIL3121" ("代碼", "名稱", "說明", "顯示名稱", "最後更新者", "更新者姓名", "最後更新日") AS (                                                                                                                                                SELECT 
	A.系統代碼 代碼, 
	A.代碼名稱 名稱, 
	A.文字參數 說明,
	trim(A.系統代碼)||':'||trim(代碼名稱) 顯示名稱,
	A.最後更新者, 
	nvl(B.員工姓名, ' ') 更新者姓名, 
	A.最後更新日 
FROM 
	FIL1014 A
	LEFT JOIN FIL0010 B ON B.員工編號 = A.最後更新者
WHERE 
	A.代碼類別 = to_char('裁切標籤'));

-- Oracle user_views
CREATE VIEW "VIEWFIL3122" ("類別", "代碼", "常用語句", "最後更新者", "更新者姓名", "最後更新日") AS (                                                                                                                                                
SELECT 
	A.代碼類別 類別,
	A.系統代碼 代碼, 
	A.文字參數 常用語句, 
	A.最後更新者, 
	nvl(B.員工姓名, ' ') 更新者姓名, 
	A.最後更新日 
FROM 
	FIL1014 A
	LEFT JOIN FIL0010 B ON B.員工編號 = A.最後更新者
WHERE 
	A.代碼類別 LIKE to_char('製程_%')	
);

-- Oracle user_views
CREATE VIEW "VIEWFIL3123" ("代碼", "名稱", "說明", "最後更新者", "更新者姓名", "最後更新日") AS (                                                                                                                                                SELECT 
	A.系統代碼 代碼, 
	A.代碼名稱 名稱, 
	A.文字參數 說明,
	A.最後更新者, 
	nvl(B.員工姓名, ' ') 更新者姓名, 
	A.最後更新日 
FROM 
	FIL1014 A
	LEFT JOIN FIL0010 B ON B.員工編號 = A.最後更新者
WHERE 
	A.代碼類別 = to_char('檢驗原料'));

-- Oracle user_views
CREATE VIEW "VIEWFIL3124" ("代碼", "名稱", "說明", "最後更新者", "更新者姓名", "最後更新日") AS (                                                                                                                                                SELECT 
	A.系統代碼 代碼, 
	A.代碼名稱 名稱, 
	A.文字參數 說明,
	A.最後更新者, 
	nvl(B.員工姓名, ' ') 更新者姓名, 
	A.最後更新日 
FROM 
	FIL1014 A
	LEFT JOIN FIL0010 B ON B.員工編號 = A.最後更新者
WHERE 
	A.代碼類別 = to_char('檢驗廠商'));

-- Oracle user_views
CREATE VIEW "VIEWFIL3125" ("代碼", "名稱", "說明", "最後更新者", "更新者姓名", "最後更新日") AS (                                                                                                                                                SELECT 
	A.系統代碼 代碼, 
	A.代碼名稱 名稱, 
	A.文字參數 說明,
	A.最後更新者, 
	nvl(B.員工姓名, ' ') 更新者姓名, 
	A.最後更新日 
FROM 
	FIL1014 A
	LEFT JOIN FIL0010 B ON B.員工編號 = A.最後更新者
WHERE 
	A.代碼類別 = to_char('調整類別'));

-- Oracle user_views
CREATE VIEW "VIEWFIL3126" ("代碼", "名稱", "說明", "最後更新者", "更新者姓名", "最後更新日") AS (                                                                                                                                                SELECT 
	A.系統代碼 代碼, 
	A.代碼名稱 名稱, 
	A.文字參數 說明,
	A.最後更新者, 
	nvl(B.員工姓名, ' ') 更新者姓名, 
	A.最後更新日 
FROM 
	FIL1014 A
	LEFT JOIN FIL0010 B ON B.員工編號 = A.最後更新者
WHERE 
	A.代碼類別 = to_char('盤差原因'));

-- Oracle user_views
CREATE VIEW "VIEWFIL3127" ("代碼", "名稱", "說明", "最後更新者", "更新者姓名", "最後更新日") AS (                                                                                                                                                SELECT 
	A.系統代碼 代碼, 
	A.代碼名稱 名稱, 
	A.文字參數 說明,
	A.最後更新者, 
	nvl(B.員工姓名, ' ') 更新者姓名, 
	A.最後更新日 
FROM 
	FIL1014 A
	LEFT JOIN FIL0010 B ON B.員工編號 = A.最後更新者
WHERE 
	A.代碼類別 = to_char('材料入庫原因'));

-- Oracle user_views
CREATE VIEW "VIEWFIL3128" ("代碼", "名稱", "說明", "材料幅寬", "套筒寬度", "印刷幅寬", "最後更新者", "更新者姓名", "最後更新日") AS (                                                                                                                                                SELECT 
	A.系統代碼 代碼, 
	A.代碼名稱 名稱, 
	A.文字參數 說明,
	A.數字參數 材料幅寬,
	A.數字參數二 套筒寬度,
	A.數字參數三 印刷幅寬,
	A.最後更新者, 
	nvl(B.員工姓名, ' ') 更新者姓名, 
	A.最後更新日 
FROM 
	FIL1014 A
	LEFT JOIN FIL0010 B ON B.員工編號 = A.最後更新者
WHERE 
	A.代碼類別 = to_char('印製後裁修'));

-- Oracle user_views
CREATE VIEW "VIEWFIL3801" ("代碼", "名稱", "說明", "至少小時", "年度限請天數", "扣薪", "扣點", "性別", "天數含假日", "事由必打", "男性限定", "女性限定", "最後更新者", "更新者姓名", "最後更新日") AS (
SELECT 
	A.系統代碼 代碼, 
	A.代碼名稱 名稱, 
	A.文字參數 說明,
	A.數字參數 至少小時,
	A.數字參數二 年度限請天數,
	A.數字參數三 扣薪,
	A.數字參數四 扣點,	
	A.文字參數一 性別,
	A.邏輯值 天數含假日,
	A.邏輯值一 事由必打,
	case when A.文字參數一=' ' or A.文字參數一='男' then 1 else 0 end 男性限定,
	case when A.文字參數一=' ' or A.文字參數一='女' then 1 else 0 end 女性限定,
	A.最後更新者, 
	nvl(B.員工姓名, ' ') 更新者姓名, 
	A.最後更新日 
FROM 
	FIL1014 A
	LEFT JOIN FIL0010 B ON B.員工編號 = A.最後更新者
WHERE 
	A.代碼類別 = to_char('假別代碼'));

-- Oracle user_views
CREATE VIEW "VIEWFIL3802" ("代碼", "工作內容", "最後更新者", "更新者姓名", "最後更新日") AS (
SELECT 
	A.系統代碼 代碼, 
	A.文字參數 工作內容,
	A.最後更新者, 
	nvl(B.員工姓名, ' ') 更新者姓名, 
	A.最後更新日 
FROM 
	FIL1014 A
	LEFT JOIN FIL0010 B ON B.員工編號 = A.最後更新者
WHERE 
	A.代碼類別 = to_char('工作內容'));

-- Oracle user_views
CREATE VIEW "VIEWFIL3803" ("代碼", "名稱", "假日", "說明", "最後更新者", "放假否", "更新者姓名", "最後更新日") AS (
SELECT 
	A.系統代碼 代碼, 
	A.代碼名稱 名稱, 
	A.日期 假日,
	A.文字參數 說明,
	A.最後更新者, 
	A.邏輯值 放假否,
	nvl(B.員工姓名, ' ') 更新者姓名, 
	A.最後更新日 
FROM 
	FIL1014 A
	LEFT JOIN FIL0010 B ON B.員工編號 = A.最後更新者
WHERE 
	A.代碼類別 = to_char('假日設定'));

-- Oracle user_views
CREATE VIEW "VIEWFIL3804" ("日期", "主旨", "附檔大小") AS ( 
SELECT
	A.製令單號 日期,
	(listagg
	(trim(to_char(B.序號,'99'))||') '||B.主旨||' 時間:'||decode(B.時間,'000000','',' '||substr(B.時間,1,2)||':'||substr(B.時間,3,2))||' 地點:'||B.地點,chr(13)) within group (order by B.序號)) as 主旨,
	sum(nvl(length(A.圖檔),0)) 附檔大小
FROM
	FIL0037A B
	INNER JOIN FIL0037 A ON B.單據類別=A.製令單別 and B.單據編號=A.製令單號 and B.序號=A.序號
WHERE
	A.製令單別='CA1' AND
	A.屬性 = '4' AND
	A.材料序號 = 0
GROUP BY
	A.製令單號);

-- Oracle user_views
CREATE VIEW "VIEWFIL3805" ("日期", "陰曆", "休假", "說明", "星期") AS ( 
SELECT 
	日 日期,  
	陰曆日 陰曆,  
	休假日 休假,  
	說明日 說明,
	星期 星期
FROM	
	(SELECT   
		日,  
		陰曆日,  
		休假日,  
		說明日,
		'星期日' 星期
	FROM 
		FIL1019

	UNION ALL

	SELECT   
		一,  
		陰曆一,  
		休假一,  
		說明一,
		'星期一' 星期
	FROM 
		FIL1019

	UNION ALL

	SELECT   
		二,  
		陰曆二,  
		休假二,  
		說明二,
		'星期二' 星期
	FROM 
		FIL1019

	UNION ALL

	SELECT   
		三,  
		陰曆三,  
		休假三,  
		說明三,
		'星期三' 星期 
	FROM 
		FIL1019

	UNION ALL

	SELECT   
		四,  
		陰曆四,  
		休假四,  
		說明四,
		'星期四'  星期
	FROM 
		FIL1019

	UNION ALL

	SELECT   
		五,  
		陰曆五,  
		休假五,  
		說明五,
		'星期五'  星期
	FROM 
		FIL1019

	UNION ALL	

	SELECT   
		六,  
		陰曆六,  
		休假六,  
		說明六,
		'星期六'  星期
	FROM 
		FIL1019	
	)
WHERE
	日 > '00000000'
);

-- Oracle user_views
CREATE VIEW "VIEWFIL3806" ("流水編號", "檔案大小合計") AS (
SELECT  
	A.GroupID 流水編號,
	sum(length(A.Photo)) 檔案大小合計 
FROM 
	FIL0100 A 
GROUP BY 
	A.GroupID
	);

-- Oracle user_views
CREATE VIEW "VIEWFIL3806A" ("產品編號", "檔案大小合計") AS (
SELECT  
	B.產品編號 產品編號,
	sum(length(A.Photo)) 檔案大小合計 
FROM 
	FIL0100 A 
	INNER JOIN FIL0030 M ON A.GroupID = M.流水編號 
	INNER JOIN FIL0032 B ON M.單據類別 = B.製令單別 AND M.單據編號 = B.製令單號 
GROUP BY 
	B.產品編號
	);

-- Oracle user_views
CREATE VIEW "VIEWFIL4001" ("單別", "單號", "單據日期", "公司代碼", "公司名稱", "部門編號", "簽核系統", "簽核狀態", "簽核系統_結案", "客戶編號", "客戶簡稱", "客戶全名", "產品編號", "產品名稱", "高", "寬", "長", "備註", "業務員", "業務員姓名", "幣別代碼", "幣別名稱", "聯絡人序號", "地址", "聯絡人", "電話", "分機", "職務", "EMAIL", "行動電話", "單價", "購買數量", "製版費", "燙金費", "未稅價格", "成捲製袋", "流水編號", "填表人", "填表人姓名", "員工流水編號", "填表日", "最後更新者", "更新者姓名", "最後更新日") AS (
SELECT
	A.單據類別 單別,
	A.單據編號 單號,
	A.單據日期,
	A.公司代碼,
	nvl(K.全名, ' ') 公司名稱,
	Z1.部門編號,
	A.簽核系統, 
	nvl(Z3.簽核狀態,'0') 簽核狀態,
	A.簽核系統_結案, 
	A.廠客編號 客戶編號,
	nvl(B2.說明一, ' ') 客戶簡稱,
	nvl(B2.說明一, ' ') 客戶全名,
	A.廠客單號 產品編號,
	B1.產品名稱,
	B1.高,
	B1.寬,
	B1.長,
	A.備註, 
	A.業務員,
	nvl(F.員工姓名,' ') 業務員姓名, 	
	A.幣別代碼,
	nvl(G.名稱, ' ') 幣別名稱,
	B.聯絡人序號,
	nvl(B2.說明二, ' ') 地址,
	nvl(B2.說明三, ' ') 聯絡人,
	nvl(decode(nvl(B2.說明五,' '),' ',C.電話,B2.說明五), ' ') 電話,
	nvl(C.分機, ' ') 分機,
	nvl(C.職務, ' ') 職務,
	nvl(decode(nvl(B2.說明四,' '),' ',C.eMail,B2.說明四), ' ') eMail,
	nvl(C.行動電話, ' ') 行動電話,
	B1.單價,
	B1.購買數量,
	B1.製版費,
	B1.燙金費,
	nvl(B1.單價*B1.購買數量+B1.製版費+B1.燙金費,0) 未稅價格,
	Decode(B1.成捲製袋,'A','成捲品','製袋品') 成捲製袋,
	A.流水編號,
	A.填表人,
	nvl(Z1.員工姓名,' ') 填表人姓名,
	nvl(Z1.Serial_Num,' ') 員工流水編號,	
	A.填表日, 
	A.最後更新者,
	nvl(Z2.員工姓名,' ') 更新者姓名, 
	A.最後更新日
FROM
	FIL0030 A
	LEFT JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
	INNER JOIN FIL003I B1 ON A.單據類別 = B1.單別 AND A.單據編號 = B1.單號
	INNER JOIN FIL0038 B2 ON A.單據類別 = B2.單別 AND A.單據編號 = B2.單號
	LEFT JOIN ViewFIL1015a C ON A.廠客編號 = C.編號 AND B.聯絡人序號 = C.序號
	LEFT JOIN FIL0011 E ON A.廠客編號 = E.編號
	LEFT JOIN FIL0010 F ON A.業務員 = F.員工編號
	LEFT JOIN ViewFIL3102 G ON A.幣別代碼 = G.代碼
	LEFT JOIN ViewFIL0011 K ON A.公司代碼 = K.代碼
	LEFT JOIN FIL0010 Z1 ON A.填表人 = Z1.員工編號
	LEFT JOIN FIL0010 Z2 ON A.最後更新者 = Z2.員工編號	
	LEFT JOIN ViewOfObjProperties Z3 ON A.流水編號 = Z3.單據流水號
WHERE
	A.單據類別 = 'B01');

-- Oracle user_views
CREATE VIEW "VIEWFIL4002" ("單別", "單號", "流水編號", "價格") AS (
SELECT
	B.單別,
	B.單號,
	A.流水編號,
	A.價格
FROM
	(	SELECT
			A.流水編號,
			sum(A.價格) 價格
		FROM
			FIL003J A
		WHERE
			A.選擇 = 1
		GROUP BY
			A.流水編號
	) A
	INNER JOIN FIL003I B ON A.流水編號 = B.流水編號);

-- Oracle user_views
CREATE VIEW "VIEWFIL4003" ("流水編號", "單據序號", "購買數量", "共幾色", "版費", "材料費") AS (
select
	A.流水編號,
	A.單據序號,
	max(B.異動數量) 購買數量,
	count(A.序號) 共幾色,
	sum(A.版費) 版費,
	sum(A.材料單價*B.異動數量) 材料費
 from 
	FIL003J1 A 		
	INNER JOIN FIL0040 B ON B.流水編號=A.流水編號 AND B.單據序號=A.單據序號
Group by 	
	A.流水編號,
	A.單據序號
);

-- Oracle user_views
CREATE VIEW "VIEWFIL4004" ("單別", "單號", "序號", "類別", "價格倍率", "合計價格", "單價", "購買數量", "總價", "色數", "每色製版費", "製版費", "燙金費", "雷射開窗", "夾鏈費", "氣閥費", "鐵條費", "未稅金額", "說明", "應稅金額", "備註", "流水編號", "最後更新者", "更新者姓名", "最後更新日") AS (
SELECT 
	A.單據類別 單別, 
	A.單據編號 單號,
	A.單據序號 序號,
	A.異動類別 類別,
	A.折讓 價格倍率,
	A.贈品數量 合計價格,
	A.異動單價 單價,	
	A.異動數量 購買數量,
	A.異動金額 總價,
	A.毛重 色數,
	A.材積 每色製版費,
	A.製版費,
	A.燙金費,
	A.雷射費 雷射開窗,
	A.夾鏈費,
	A.氣閥費,
	A.鐵條費,
	A.異動金額 + A.製版費 + A.燙金費 +	A.雷射費 + A.夾鏈費 + A.氣閥費 + A.鐵條費 未稅金額,
	'倍率:'||trim(to_char(A.折讓,'990.00'))||' '||'單價:'||trim(to_char(decode(A.異動數量,0,0,(A.異動金額 + A.燙金費 +	A.雷射費 + A.夾鏈費 + A.氣閥費 + A.鐵條費)/A.異動數量),'99,990.00'))||' '||'數量:'||trim(to_char(A.異動數量,'999,999'))||' '||'未稅金額:'||trim(to_char(A.異動金額 + A.製版費 + A.燙金費 +	A.雷射費 + A.夾鏈費 + A.氣閥費 + A.鐵條費,'9,999,999')) 說明,
	A.數值1 應稅金額,
	A.備註說明 備註,
	A.流水編號,
	A.最後更新者,
	NVL(B.員工姓名,' ') 更新者姓名,
	A.最後更新日
FROM 
	FIL0040 A
	LEFT JOIN FIL0010 B ON A.最後更新者 = B.員工編號
WHERE
	A.單據類別 = 'B01');

-- Oracle user_views
CREATE VIEW "VIEWFIL4010" ("單別", "單號", "單據日期", "公司代碼", "公司名稱", "簽核系統", "簽核系統_結案", "廠客編號", "廠客簡稱", "廠客全名", "備註", "業務員", "業務員姓名", "幣別代碼", "幣別名稱", "稅別", "稅率", "類別", "交貨日期_天", "交貨日期", "交貨日期_次批", "交貨數量正負", "交貨數量差", "訂金率", "訂金", "票期", "有效期限", "聯絡人序號", "產品編號", "品名", "規格", "材質1", "材質2", "材質3", "材質4", "材質5", "材質6", "厚度1", "厚度2", "厚度3", "厚度4", "厚度5", "厚度6", "色別1", "色別2", "色別3", "色別4", "色別5", "色別6", "色別7", "色別8", "色別9", "色別10", "聯絡人", "電話", "傳真", "分機", "職務", "EMAIL", "行動電話", "送貨地址序號", "收貨人", "收貨地址", "工廠地址", "收貨電話", "客戶回簽", "客戶佐證", "流水編號", "填表人", "填表人姓名", "填表日", "最後更新者", "更新者姓名", "最後更新日", "簽核狀態", "發函代理人", "代理人姓名", "不用回簽報價單") AS (                                                                                                                                                      
SELECT
	A.單據類別 單別,
	A.單據編號 單號,
	A.單據日期,
	A.公司代碼,
	nvl(K.全名, ' ') 公司名稱,
	A.簽核系統, 
	A.簽核系統_結案, 
	A.廠客編號,
	nvl(E.簡稱, ' ') 廠客簡稱,
	nvl(E.全名,nvl(J.說明一,' ')) 廠客全名,
	A.備註, 
	decode(A.業務員,' ',A.填表人,A.業務員) 業務員,
	nvl(F.員工姓名,' ') 業務員姓名, 	
	A.幣別代碼,
	nvl(G.名稱, ' ') 幣別名稱,
	A.稅別,
	A.稅率,
	B.類別, 
	B.材積單位 交貨日期_天,
	B.交貨日期,
	B.交貨日期_次批,
	B.運輸方式 交貨數量正負,
	B.交貨日期_天 交貨數量差,
	B.數量 訂金率,
	B.訂金,
	B.票期,
	A.歸屬序號 有效期限,
	B.聯絡人序號,
	B.材料編號一 產品編號,
	B.文字1 品名,
	B.文字2 規格,
	B.文數字11 材質1,
	B.文數字12 材質2,
	B.文數字13 材質3,
	B.文數字14 材質4,
	B.文數字15 材質5,
	B.文字6 材質6,
	B.數值1 厚度1,
	B.數值2 厚度2,
	B.數值3 厚度3,
	B.數值4 厚度4,
	B.數值5 厚度5,
	B.數值6 厚度6,
	B.文數字1 色別1,
	B.文數字2 色別2,
	B.文數字3 色別3,
	B.文數字4 色別4,
	B.文數字5 色別5,
	B.文數字6 色別6,
	B.文數字7 色別7,
	B.文數字8 色別8,
	B.文數字9 色別9,
	B.文數字10 色別10,
	nvl(J.說明三,nvl(C.聯絡人,' ')) 聯絡人,
	nvl(B.材料編號二, ' ') 電話,
	nvl(B.材料編號三, ' ') 傳真,
	nvl(C.分機, ' ') 分機,
	nvl(C.職務, ' ') 職務,
	nvl(C.eMail, ' ') eMail,
	nvl(C.行動電話, ' ') 行動電話,
	B.送貨地址序號,
	nvl(J.說明三,nvl(D.收貨人,' ')) 收貨人,
	nvl(J.說明二,nvl(D.地址,' ')) 收貨地址,
	nvl(J.說明四,nvl(D.地址,' ')) 工廠地址,
	nvl(D.電話, ' ') 收貨電話,
	decode(nvl(I.回簽,0),0,0,1) 客戶回簽,
	decode(nvl(L.佐證,0),0,0,1) 客戶佐證,
	A.流水編號,
	A.填表人,
	nvl(Z1.員工姓名,' ') 填表人姓名, 
	A.填表日, 
	A.最後更新者,
	nvl(Z2.員工姓名,' ') 更新者姓名, 
	A.最後更新日,
	nvl(Z3.簽核狀態, '0') 簽核狀態,
	nvl(H.發函代理人, ' ') 發函代理人,
	nvl(H.代理人姓名, ' ') 代理人姓名,
	nvl(E.合約訂單是否歸屬總公司,0) 不用回簽報價單
FROM
	FIL0030 A
	INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
	LEFT JOIN ViewFIL1015a C ON A.廠客編號 = C.編號 AND B.聯絡人序號 = C.序號
	LEFT JOIN FIL0015 D ON A.廠客編號 = D.廠客編號 AND B.送貨地址序號 = D.序號
	LEFT JOIN FIL0011 E ON A.廠客編號 = E.編號
	LEFT JOIN FIL0010 F ON decode(A.業務員,' ',A.填表人,A.業務員) = F.員工編號
	LEFT JOIN ViewFIL3102 G ON A.幣別代碼 = G.代碼
	LEFT JOIN ViewFIL0030 H ON A.簽核系統 = H.簽核系統 AND A.單據編號 = H.單號
	LEFT JOIN 
	(SELECT
		A.簽核系統,
		A.單據編號,
		COUNT(A.單據編號) 回簽
	 FROM
		ViewFIL0052 A 
	 GROUP BY
		A.簽核系統,
		A.單據編號
	) I	ON A.簽核系統 = I.簽核系統 AND A.單據編號 = I.單據編號
	LEFT JOIN FIL0038 J ON A.流水編號 = J.流水編號 and A.流水編號<>' '
	LEFT JOIN ViewFIL0011 K ON A.公司代碼 = K.代碼
	LEFT JOIN 
	(SELECT
		A.簽核系統,
		A.單號,
		COUNT(A.單號) 佐證
	 FROM
		ViewFIL0051 A 
	 GROUP BY
		A.簽核系統,
		A.單號
	)L ON trim(A.簽核系統)||'_A' = L.簽核系統 AND A.單據編號 = L.單號
	LEFT JOIN FIL0010 Z1 ON A.填表人 = Z1.員工編號
	LEFT JOIN FIL0010 Z2 ON A.最後更新者 = Z2.員工編號	
	LEFT JOIN ViewOfObjProperties Z3 ON A.流水編號 = Z3.單據流水號
	
WHERE
	A.單據類別 = 'B11');

-- Oracle user_views
CREATE VIEW "VIEWFIL4011" ("單別", "單號", "序號", "類別", "類別名稱", "前置單別", "前置單號", "產品編號", "品名", "規格", "材質", "印刷", "數量", "單位代碼", "單位名稱", "單價", "總體單價", "總價", "製版費", "色數", "每色製版費", "燙金費", "雷射費", "未稅金額", "含稅金額", "含稅訂金", "備註", "估價單號", "估價流水編號", "估價單序號", "流水編號", "最後更新者", "更新者姓名", "最後更新日") AS (
SELECT 
	A.單據類別 單別, 
	A.單據編號 單號,
	A.單據序號 序號,
	F.類別 類別,
	decode(F.類別, 'A', '新品', 'B', '重覆訂單', 'C', '改版', '其他') 類別名稱,
	A.前置單別,
	A.前置單號,
	'倍率:'||trim(to_char(D.折讓,'990.00'))||' '||'單價:'||trim(to_char(decode(A.異動數量,0,0,A.數值1),'99,990.00'))||' '||'數量:'||trim(to_char(A.異動數量,'999,999'))||' '||'未稅金額:'||trim(to_char(A.異動金額,'9,999,999'))產品編號,
	' ' 品名,
	' ' 規格,
	' ' 材質,
	' ' 印刷,
	A.異動數量 數量,
	A.單位代碼,
	nvl(H.名稱, ' ') 單位名稱,
	A.異動單價 單價,
	A.數值1 總體單價,
	A.異動金額 總價,
	A.製版費,
	A.折扣率 色數,
	A.折讓 每色製版費,
	A.燙金費,
	A.雷射費,
	A.贈品數量 未稅金額,
	A.毛重 含稅金額,
	A.材積 含稅訂金,
	A.備註說明 備註,
	' ' 估價單號,
	C.估價流水編號,
	A.QRNo 估價單序號,
	A.流水編號,
	A.最後更新者,
	NVL(B.員工姓名,' ') 更新者姓名,
	A.最後更新日
FROM 
	FIL0040 A
	INNER JOIN FIL004G C ON C.單別=A.單據類別 AND C.單號 = A.單據編號 AND C.序號 = A.單據序號
	INNER JOIN FIL0031 F ON F.單別=A.單據類別 AND F.單號 = A.單據編號 
	LEFT JOIN FIL0040 D ON C.估價流水編號 = D.流水編號 AND A.QRNo = D.單據序號
	LEFT JOIN FIL0010 B ON A.最後更新者 = B.員工編號
	LEFT JOIN ViewFIL3103 H ON A.單位代碼 = H.代碼
WHERE
	A.單據類別 = 'B11');

-- Oracle user_views
CREATE VIEW "VIEWFIL4012" ("單別", "單號", "總體單價") AS (
SELECT 
	A.單據類別 單別, 
	A.單據編號 單號,
	avg(A.數值1) 總體單價
FROM 
	FIL0040 A
WHERE
	A.單據類別 = 'B11' and 
	A.數值1<>0
GROUP BY
	A.單據類別, 
	A.單據編號
	);

-- Oracle user_views
CREATE VIEW "VIEWFIL401A" ("單別", "單號", "數量", "總價", "製版費", "燙金費", "雷射費", "合計總價", "稅率", "訂金率", "訂金", "稅額", "含稅價") AS (SELECT
	A.單別,
	A.單號,
	A.數量,
	A.總價,
	A.製版費,
	A.燙金費,
	A.雷射費,
	A.總價 + A.製版費 + A.燙金費 + A.雷射費 合計總價,
	C.稅率,
	D.數值1 訂金率,
	D.訂金,
	round((A.總價 + A.製版費 + A.燙金費 + A.雷射費) * C.稅率 / 100) 稅額,
	round((A.總價 + A.製版費 + A.燙金費 + A.雷射費) * (1 + C.稅率 / 100)) 含稅價
FROM
	(	SELECT
			A.單據類別 單別,
			A.單據編號 單號,
			sum(A.異動數量) 數量,
			sum(A.異動金額) 總價,
			sum(A.製版費) 製版費,
			sum(A.燙金費) 燙金費,
			sum(A.雷射費) 雷射費
		FROM
			FIL0040 A
		WHERE
			A.單據類別 = 'B11'
		GROUP BY
			A.單據類別,
			A.單據編號
	)	A
	INNER JOIN FIL0030 C ON A.單別 = C.單據類別 AND A.單號 = C.單據編號
	INNER JOIN FIL0031 D ON A.單別 = D.單別 AND A.單號 = D.單號
	);

-- Oracle user_views
CREATE VIEW "VIEWFIL401B" ("單別", "單號", "序號", "類別名稱", "備註", "產品編號", "總價", "製版費", "流水編號", "單據日期", "廠客編號", "廠客全名", "品名", "簽核狀態", "客戶回簽", "客戶佐證", "稅別", "幣別代碼") AS (
SELECT 
	A.單據類別 單別, 
	A.單據編號 單號,
	A.單據序號 序號,
	decode(F.類別, 'A', '新品', 'B', '重覆訂單', 'C', '改版', '其他') 類別名稱,
	A.備註說明 備註,
	'倍率:'||trim(to_char(D.折讓,'990.00'))||' '||'單價:'||trim(to_char(decode(A.異動數量,0,0,A.數值1),'99,990.00'))||' '||'數量:'||trim(to_char(A.異動數量,'999,999'))||' '||'未稅金額:'||trim(to_char(A.異動金額,'9,999,999'))產品編號,
	A.異動金額 總價,
	A.製版費,
	M.流水編號,
	M.單據日期,
	M.廠客編號,
	nvl(E.全名,nvl(J.說明一,' ')) 廠客全名,
	F.文字1 品名,
	nvl(Z3.簽核狀態, '0') 簽核狀態,
	decode(nvl(I.回簽,0),0,0,1) 客戶回簽,
	decode(nvl(L.佐證,0),0,0,1) 客戶佐證,
	M.稅別,
	M.幣別代碼
FROM 
	FIL0040 A
	INNER JOIN FIL0030 M ON M.單據類別=A.單據類別 AND M.單據編號  = A.單據編號 
	INNER JOIN FIL004G C ON C.單別=A.單據類別 AND C.單號 = A.單據編號 AND C.序號 = A.單據序號
	INNER JOIN FIL0031 F ON F.單別=A.單據類別 AND F.單號 = A.單據編號 
	INNER JOIN ViewOfObjProperties Z3 ON M.流水編號 = Z3.單據流水號 AND Z3.簽核狀態 = 'E'
	LEFT JOIN FIL0040 D ON C.估價流水編號 = D.流水編號 AND A.QRNo = D.單據序號
	LEFT JOIN FIL0011 E ON M.廠客編號 = E.編號
	LEFT JOIN FIL0038 J ON M.流水編號 = J.流水編號 and M.流水編號<>' '
	LEFT JOIN 
	(SELECT
		A.簽核系統,
		A.單號,
		COUNT(A.單號) 回簽
	 FROM
		FIL1011 A 
	 GROUP BY
		A.簽核系統,
		A.單號
	)I ON trim(M.簽核系統) = I.簽核系統 AND A.單據編號 = I.單號
	LEFT JOIN 
	(SELECT
		A.簽核系統,
		A.單號,
		COUNT(A.單號) 佐證
	 FROM
		FIL1011 A 
	 GROUP BY
		A.簽核系統,
		A.單號
	)L ON trim(M.簽核系統)||'_A' = L.簽核系統 AND A.單據編號 = L.單號
WHERE
	A.單據類別 = 'B11' AND 
	(nvl(I.回簽,0)>0 OR nvl(L.佐證,0)>0)
	);

-- Oracle user_views
CREATE VIEW "VIEWFIL4020" ("單別", "單號", "報價單別", "報價單號", "公司代碼", "公司名稱", "訂單類別", "客戶單號", "出貨廠別", "廠別名稱", "部門編號", "部門名稱", "價格條件", "付款條件", "付款條件名稱", "材積單位", "材積單位名稱", "確認碼", "單據日期", "簽核系統", "簽核系統_結案", "廠客編號", "廠客簡稱", "廠客全名", "備註", "業務員", "業務員姓名", "幣別代碼", "幣別名稱", "匯率", "稅別", "稅別說明", "稅率", "聯絡人序號", "聯絡人", "電話", "分機", "職務", "EMAIL", "行動電話", "送貨地址序號", "收貨人", "收貨地址", "收貨電話", "未稅金額", "稅額", "應稅金額", "流水編號", "填表人", "填表人姓名", "填表日", "最後更新者", "更新者姓名", "最後更新日", "簽核狀態", "發函代理人", "代理人姓名") AS (                                                                                                                                                      SELECT
	A.單據類別 單別,
	A.單據編號 單號,
	A.歸屬類別 報價單別,
	A.歸屬編號 報價單號,
	A.公司代碼,
	nvl(M.全名, ' ') 公司名稱,
	B.類別 訂單類別,
	A.廠客單號 客戶單號,
	A.廠別編號 出貨廠別,
	nvl(L.廠別名稱, ' ') 廠別名稱,
	A.部門編號,
	nvl(I.部門名稱, ' ') 部門名稱,
	B.價格條件,
	A.收付方式 付款條件,
	nvl(J.名稱, ' ') 付款條件名稱,
	B.材積單位,
	nvl(K.名稱, ' ') 材積單位名稱,
	A.確認碼,
	A.單據日期,
	A.簽核系統, 
	A.簽核系統_結案, 
	A.廠客編號,
	nvl(E.簡稱, ' ') 廠客簡稱,
	nvl(E.全名, ' ') 廠客全名,
	A.備註, 
	A.業務員,
	nvl(F.員工姓名,' ') 業務員姓名, 	
	A.幣別代碼,
	nvl(G.名稱, ' ') 幣別名稱,
	A.匯率,
	A.稅別,
	decode(A.稅別, '1', '應稅', '2', '零稅率', '3', '免稅', '空白') 稅別說明,
	A.稅率,
	B.聯絡人序號,
	nvl(C.聯絡人, ' ') 聯絡人,
	nvl(C.電話, ' ') 電話,
	nvl(C.分機, ' ') 分機,
	nvl(C.職務, ' ') 職務,
	nvl(C.eMail, ' ') eMail,
	nvl(C.行動電話, ' ') 行動電話,
	B.送貨地址序號,
	nvl(D.收貨人, ' ') 收貨人,
	nvl(D.地址, ' ') 收貨地址,
	nvl(D.電話, ' ') 收貨電話,
	B.數值1 未稅金額,
	B.數值2 稅額,
	B.數值3 應稅金額,
	A.流水編號,
	A.填表人,
	nvl(Z1.員工姓名,' ') 填表人姓名, 
	A.填表日, 
	A.最後更新者,
	nvl(Z2.員工姓名,' ') 更新者姓名, 
	A.最後更新日,
	nvl(Z3.簽核狀態, '0') 簽核狀態,
	nvl(H.發函代理人, ' ') 發函代理人,
	nvl(H.代理人姓名, ' ') 代理人姓名	
FROM
	FIL0030 A
	INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
	LEFT JOIN ViewFIL1015a C ON A.廠客編號 = C.編號 AND B.聯絡人序號 = C.序號
	LEFT JOIN FIL0015 D ON A.廠客編號 = D.廠客編號 AND B.送貨地址序號 = D.序號
	LEFT JOIN FIL0011 E ON A.廠客編號 = E.編號
	LEFT JOIN FIL0010 F ON A.業務員 = F.員工編號
	LEFT JOIN ViewFIL3102 G ON A.幣別代碼 = G.代碼
	LEFT JOIN ViewFIL0030 H ON A.簽核系統 = H.簽核系統 AND A.單據編號 = H.單號
	LEFT JOIN FIL0020 I ON A.部門編號 = I.部門編號
	LEFT JOIN ViewFIL3107 J ON A.收付方式 = J.代碼
	LEFT JOIN ViewFIL3103 K ON B.材積單位 = K.代碼
	LEFT JOIN FIL0013 L ON A.廠別編號 = L.廠別編號
	LEFT JOIN ViewFIL0011 M ON A.公司代碼 = M.代碼
	LEFT JOIN FIL0010 Z1 ON A.填表人 = Z1.員工編號
	LEFT JOIN FIL0010 Z2 ON A.最後更新者 = Z2.員工編號
	LEFT JOIN ViewOfObjProperties Z3 ON A.流水編號 = Z3.單據流水號
WHERE
	A.單據類別 = 'B31');

-- Oracle user_views
CREATE VIEW "VIEWFIL4021" ("單別", "單號", "序號", "產品編號", "品名", "規格", "材質", "異動日期", "客戶品號", "訂單數量", "已交數量", "贈品量", "贈品已交量", "單位代碼", "單位名稱", "小單位", "小單位名稱", "折扣率", "包裝數量", "包裝單位", "包裝單位名稱", "單價", "金額", "毛重", "材積", "製版費", "預交日", "交貨庫別", "庫別名稱", "前置單別", "前置單號", "報價單別", "報價單號", "報價單序號", "專案代號", "備註", "結案碼", "參考尺寸", "米平方單價", "流水編號", "最後更新者", "更新者姓名", "最後更新日") AS (
SELECT 
	A.單據類別 單別, 
	A.單據編號 單號,
	A.單據序號 序號,
	A.產品編號,
	nvl(A1.手動品名, ' ') 品名,
	nvl(A1.手動規格, ' ') 規格,
	trim(nvl(H.品名, ' ')||nvl(H.規格,' ')) || decode(A1.客戶報價材質結構2, ' ', ' ', '/' || trim(nvl(I.品名||nvl(I.規格,' '), ' '))) || decode(A1.客戶報價材質結構3, ' ', ' ', '/' || trim(nvl(J.品名||nvl(J.規格,' '), ' '))) 材質,
	A.異動日期,
	A.廠客品號 客戶品號,
	A.異動數量 訂單數量,
	(NVL(K.交貨數量,0)-NVL(L.退貨數量,0)) 已交數量,
	A.贈品數量 贈品量,
	(NVL(K.交貨贈品數,0)-NVL(L.退貨贈品數,0)) 贈品已交量,
	A.單位代碼,
	nvl(D.名稱, ' ') 單位名稱,
	A1.小單位,
	nvl(E.名稱, ' ') 小單位名稱,
	A.折扣率,
	A1.包裝數量,
	A1.包裝單位,
	nvl(F.名稱, ' ') 包裝單位名稱,
	A.異動單價 單價,
	A.異動金額 金額,
	A.毛重,
	A.材積,
	A.製版費,
	A.預交日,
	A.倉庫代碼 交貨庫別,
	nvl(G.名稱, ' ') 庫別名稱,
	A.前置單別,
	A.前置單號,
	A1.文數字1 報價單別,
	A1.文數字2 報價單號,
	A1.數值1 報價單序號,
	A1.專案代號,
	A.備註說明 備註,
	A.結案碼,
	A.數值1 參考尺寸,
	A.數值2 米平方單價,
	A.流水編號,
	A.最後更新者,
	NVL(B.員工姓名,' ') 更新者姓名,
	A.最後更新日
FROM 
	FIL0040 A
	INNER JOIN FIL0041 A1 ON A.單據類別 = A1.單別 AND A.單據編號 = A1.單號 AND A.單據序號 = A1.序號
	LEFT JOIN FIL0010 B ON A.最後更新者 = B.員工編號
	LEFT JOIN ViewFIL1012 C ON A.產品編號 = C.產品編號
	LEFT JOIN ViewFIL3103 D ON A.單位代碼 = D.代碼
	LEFT JOIN ViewFIL3103 E ON A1.小單位 = E.代碼
	LEFT JOIN ViewFIL3103 F ON A1.包裝單位 = F.代碼
	LEFT JOIN ViewFIL3106 G ON A.倉庫代碼 = G.代碼
	LEFT JOIN FIL0012 H ON A1.客戶報價材質結構1 = H.產品編號
	LEFT JOIN FIL0012 I ON A1.客戶報價材質結構2 = I.產品編號
	LEFT JOIN FIL0012 J ON A1.客戶報價材質結構3 = J.產品編號
	LEFT JOIN 
	(
	SELECT 
		A1.文數字1 訂單單別,
		A1.文數字2 訂單單號,
		A1.數值1 訂單序號,
		sum(A.異動數量) 交貨數量,
		sum(A.贈品數量) 交貨贈品數	
	FROM 
		FIL0040 A
		INNER JOIN FIL0030 M ON M.單據類別 = A.單據類別 AND M.單據編號 = A.單據編號
		INNER JOIN FIL0041 A1 ON A.單據類別 = A1.單別 AND A.單據編號 = A1.單號 AND A.單據序號 = A1.序號
		LEFT JOIN ViewOfObjProperties Z3 ON M.流水編號 = Z3.單據流水號
	WHERE
		A.單據類別 = 'B42' and
		nvl(Z3.簽核狀態,' ') <> 'A'
	GROUP BY
		A1.文數字1,
		A1.文數字2,
		A1.數值1
	) K ON K.訂單單別 = A.單據類別 AND K.訂單單號 = A.單據編號 AND K.訂單序號 = A.單據序號
	LEFT JOIN 
	(
	SELECT 
		A1.文數字1 訂單單別,
		A1.文數字2 訂單單號,
		A1.數值1 訂單序號,
		SUM(A.異動數量*-1) 退貨數量,
		SUM(A.贈品數量*-1) 退貨贈品數	
	FROM 
		FIL0040 A
		INNER JOIN FIL0030 M ON M.單據類別 = A.單據類別 AND M.單據編號 = A.單據編號
		INNER JOIN FIL0041 A1 ON A.單據類別 = A1.單別 AND A.單據編號 = A1.單號 AND A.單據序號 = A1.序號
		LEFT JOIN ViewOfObjProperties Z3 ON M.流水編號 = Z3.單據流水號
	WHERE
		A.單據類別 = 'B51' and
		nvl(Z3.簽核狀態,' ') <> 'A'
	GROUP BY
		A1.文數字1,
		A1.文數字2,
		A1.數值1	
	) L ON L.訂單單別 = A.單據類別 AND L.訂單單號 = A.單據編號 AND L.訂單序號 = A.單據序號
WHERE
	A.單據類別 = 'B31');

-- Oracle user_views
CREATE VIEW "VIEWFIL402A" ("單別", "單號", "訂單數量", "已交數量", "贈品量", "贈品已交量", "金額", "毛重", "材積", "稅率", "稅額", "含稅金額") AS (SELECT 
	A.單別, 
	A.單號,
	A.訂單數量,
	A.已交數量,
	A.贈品量,
	A.贈品已交量,
	A.金額,
	A.毛重,
	A.材積,
	B.稅率,
	round(A.金額 * B.稅率 / 100) 稅額,
	round(A.金額 * (1 + B.稅率 / 100)) 含稅金額
FROM
	(	SELECT 
			A.單據類別 單別, 
			A.單據編號 單號,
			sum(A.異動數量) 訂單數量,
			0 已交數量,
			sum(A.贈品數量) 贈品量,
			0 贈品已交量,
			sum(A.異動金額) 金額,
			sum(A.毛重) 毛重,
			sum(A.材積) 材積
		FROM 
			FIL0040 A
		WHERE
			A.單據類別 = 'B31'
		GROUP BY
			A.單據類別,
			A.單據編號
	) A
	INNER JOIN FIL0030 B ON A.單別 = B.單據類別 AND A.單號 = B.單據編號);

-- Oracle user_views
CREATE VIEW "VIEWFIL402B" ("單別", "單號", "產品編號", "報價數量", "訂單數量", "未訂購數", "報價金額", "訂單金額") AS (SELECT
	nvl(A.單據類別, B.歸屬類別) 單別,
	nvl(A.單據編號, B.歸屬編號) 單號,
	nvl(A.產品編號, B.產品編號) 產品編號,
	nvl(A.報價數量, 0) 報價數量,
	nvl(B.訂單數量, 0) 訂單數量,
	nvl(A.報價數量, 0) - nvl(B.訂單數量, 0) 未訂購數,
	nvl(A.報價金額, 0) 報價金額,
	nvl(B.訂單金額, 0) 訂單金額
FROM
	/* 報價單 */
	(	SELECT
			A.單據類別,
			A.單據編號,
			A.產品編號,
			sum(A.異動數量) 報價數量,
			sum(A.異動金額 + A.製版費 + A.燙金費 + A.雷射費) 報價金額
		FROM
			FIL0040 A
		WHERE
			A.單據類別 = 'B11'
		GROUP BY
			A.單據類別,
			A.單據編號,
			A.產品編號
	) A
	FULL OUTER JOIN
	/* 訂單 */
	(	SELECT 
			B.歸屬類別, 
			B.歸屬編號,
			A.產品編號,
			sum(A.異動數量) 訂單數量,
			sum(A.異動金額) 訂單金額
		FROM 
			FIL0040 A
			INNER JOIN FIL0030 B ON A.單據類別 = B.單據類別 AND A.單據編號 = B.單據編號
		WHERE
			A.單據類別 = 'B31'
		GROUP BY
			B.歸屬類別,
			B.歸屬編號,
			A.產品編號
	) B ON A.單據類別 = B.歸屬類別 AND A.單據編號 = B.歸屬編號 AND A.產品編號 = B.產品編號);

-- Oracle user_views
CREATE VIEW "VIEWFIL402C" ("歸屬類別編號", "單據類別編號", "製程代碼", "加工別", "單據類別", "單據編號", "單據名稱", "製程名稱", "流水編號") AS (
Select 
	A.歸屬類別編號,
	A.單據類別編號,
	A.製程代碼,
	A.加工別,
	substr(A.單據類別編號,1,3) 單據類別,
	substr(A.單據類別編號,5,20) 單據編號,
	case when A.製程代碼='31C_A' then to_char('熟成') else to_char(C.單據名稱) end 單據名稱,
	case when A.製程代碼='31C_A' then to_char('熟成') else to_char(B.名稱) end 製程名稱,
	A.流水編號
From 	
(select distinct 
	to_char(' ') 歸屬類別編號,
	A.單據類別||'.'||A.單據編號 單據類別編號,
	to_char(' ') 製程代碼,
	to_char(' ') 加工別,
	A.流水編號
from 
	fil0030 A 
where 
	A.單據類別='C11'

union all

select distinct 
	B.單別||'.'||B.單號 歸屬類別編號,
	A.單據類別||'.'||A.單據編號 單據類別編號,
	to_char(' ') 製程代碼,
	to_char(' ') 加工別,
	A.流水編號
from 
	fil0030 A 
	inner join fil0038 B on B.說明一=A.單據編號 and B.單別='C11'
where 
	A.單據類別='B11' 

union all

select distinct 
	A.歸屬類別||'.'||A.歸屬編號 歸屬類別編號,
	A.單據類別||'.'||A.單據編號 單據類別編號,
	B.製程代碼,
	to_char(B.交貨日期_次批) 加工別,
	A.流水編號
from 
	fil0030 A 
	inner join fil0031 B on B.單別=A.單據類別 and B.單號=A.單據編號
where 
	A.單據類別='C41'and
	(B.製程代碼<>'C31K' and B.製程代碼<>'C31H')
	
union

select distinct 
	'C11'||'.'||A.前置單號 歸屬類別編號,
	A.單據類別||'.'||A.單據編號 單據類別編號,
	to_char(' ') 製程代碼,
	to_char(' ') 加工別,
	B.流水編號
from 
	fil0040 A 
	inner join fil0030 B on B.單據類別=A.單據類別 and B.單據編號=A.單據編號
where 
	A.單據類別 between 'E22' and 'E23' 
		
union

select distinct 
	'C11'||'.'||A.廠客品號 歸屬類別編號,
	A.單據類別||'.'||A.單據編號 單據類別編號,
	to_char(' ') 製程代碼,
	to_char(' ') 加工別,
	B.流水編號
from 
	fil0040 A 
	inner join fil0030 B on B.單據類別=A.單據類別 and B.單據編號=A.單據編號
where 
	A.單據類別 between 'E32' and 'E37'
	
union

select distinct 
	'C11'||'.'||D.製令單號 歸屬類別編號,
	A.單據類別||'.'||A.單據編號 單據類別編號,
	to_char(' ') 製程代碼,
	to_char(' ') 加工別,
	A.流水編號
from 
	FIL0030 A
	INNER JOIN FIL003E D ON A.流水編號 = D.主檔流水編號	
where 
	A.單據類別 between 'C44' and 'C48'
	
union all

select distinct 
	A.單據類別||'.'||A.單據編號 歸屬類別編號,
	to_char('B01.'||substr(B.說明一,1,20)) 單據類別編號,
	to_char(' ') 製程代碼,
	to_char(' ') 加工別,
	A.流水編號
from 
	fil0030 A 
	inner join fil0038 B on B.流水編號=A.流水編號 
where 
	A.單據類別='C11' and B.說明一<>' '
	
union all 

select distinct 
	A.前置單別||'.'||A.前置單號 歸屬類別編號,
	A.單據類別||'.'||A.單據編號 單據類別編號,
	to_char(' ') 製程代碼,
	to_char(' ') 加工別,
	B.流水編號
from 
	FIL0040 A
	inner join fil0030 B on B.單據類別=A.單據類別 and B.單據編號=A.單據編號
where 
	A.單據類別 between 'R01' and 'R11'

union all 

select distinct 
	'C11'||'.'||A.製令單號 歸屬類別編號,
	A.單別||'.'||A.單號 單據類別編號,
	to_char('31C_A') 製程代碼,
	to_char(' ') 加工別,
	A.單頭流水編號 流水編號
from 
	ViewFIL404C4_V1 A

union all 

select distinct 
	A.製令單別||'.'||A.製令單號 歸屬類別編號,
	A.單別||'.'||A.單號 單據類別編號,
	to_char('C31H') 製程代碼,
	to_char(A.加工別) 加工別,
	A.流水編號 流水編號
from 
	ViewFIL404H2 A


union all 

select distinct 
	A.製令單別||'.'||A.製令單號 歸屬類別編號,
	A.單別||'.'||A.單號 單據類別編號,
	to_char('C31K') 製程代碼,
	to_char(A.加工別) 加工別,
	A.流水編號 流水編號
from 
	ViewFIL404I2 A

	) A
LEFT JOIN ViewFIL310N B ON A.製程代碼=B.代碼
LEFT JOIN ViewFIL0020 C ON substr(A.單據類別編號,1,3)=C.單據類別
);

-- Oracle user_views
CREATE VIEW "VIEWFIL402D" ("單別", "報價單號", "製令單號", "建檔日時", "客戶回簽日時", "佐證上傳日時", "最早上傳日時", "報價日期", "客戶編號", "客戶簡稱", "客戶全名", "業務員", "業務員姓名", "客戶回簽", "客戶佐證", "產品編號", "品名", "規格", "不用回簽報價單") AS (
SELECT 
	M.單別,
	M.單號 報價單號,
	A.單號 製令單號,
	TO_CHAR(N.填表日,'YYYYMMDDHH24MISS') 建檔日時,
	NVL(B.客戶回簽日時,'00000000000000') 客戶回簽日時,
	NVL(C.佐證上傳日時,'00000000000000') 佐證上傳日時,
	LEAST(NVL(B.客戶回簽日時,'Z'),NVL(C.佐證上傳日時,'Z')) 最早上傳日時,
	nvl(M.單據日期,'00000000') 報價日期,
	nvl(M.廠客編號,' ') 客戶編號,
	nvl(M.廠客簡稱,' ') 客戶簡稱,
	nvl(M.廠客全名,' ') 客戶全名,
	nvl(M.業務員,' ') 業務員,
	nvl(M.業務員姓名,' ') 業務員姓名,
	nvl(M.客戶回簽,0) 客戶回簽,
	nvl(M.客戶佐證,0) 客戶佐證,
	nvl(M.產品編號,' ') 產品編號,
	nvl(M.品名,' ') 品名,
	nvl(M.規格,' ') 規格,
	M.不用回簽報價單
FROM
	ViewFIL4010 M 
	LEFT JOIN FIL0038 A ON M.單別='B11' AND M.單號=A.說明一
	LEFT JOIN FIL0030 N ON N.單據類別=A.單別 AND N.單據編號=A.單號
	LEFT JOIN
	(
	SELECT 
		A.單號,
		MIN(A.建檔日||建檔時) 客戶回簽日時
	FROM
		FIL1011 A
	WHERE 
		A.簽核系統 = 'B11.APK'
	GROUP BY
		A.單號
	) B ON B.單號 = A.說明一
	LEFT JOIN
	(
	SELECT 
		A.單號,
		MIN(A.建檔日||建檔時) 佐證上傳日時
	FROM
		FIL1011 A
	WHERE 
		A.簽核系統 = 'B11.APK_A'
	GROUP BY
		A.單號
	) C ON C.單號 = A.說明一
);

-- Oracle user_views
CREATE VIEW "VIEWFIL402DA" ("單別", "報價單號", "製令單號", "建檔日時", "客戶回簽日時", "佐證上傳日時", "最早上傳日時", "報價日期", "客戶編號", "客戶簡稱", "客戶全名", "業務員", "業務員姓名", "客戶回簽", "客戶佐證", "產品編號", "品名", "規格", "不用回簽報價單") AS (
SELECT 
	M.單別,
	M.單號 報價單號,
	SUBSTR(NVL(A.製令單號,' '),1,200) 製令單號,
	TO_CHAR(N.填表日,'YYYYMMDDHH24MISS') 建檔日時,
	NVL(B.客戶回簽日時,'00000000000000') 客戶回簽日時,
	NVL(C.佐證上傳日時,'00000000000000') 佐證上傳日時,
	LEAST(NVL(B.客戶回簽日時,'Z'),NVL(C.佐證上傳日時,'Z')) 最早上傳日時,
	nvl(M.單據日期,'00000000') 報價日期,
	nvl(M.廠客編號,' ') 客戶編號,
	nvl(M.廠客簡稱,' ') 客戶簡稱,
	nvl(M.廠客全名,' ') 客戶全名,
	nvl(M.業務員,' ') 業務員,
	nvl(M.業務員姓名,' ') 業務員姓名,
	nvl(M.客戶回簽,0) 客戶回簽,
	nvl(M.客戶佐證,0) 客戶佐證,
	nvl(M.產品編號,' ') 產品編號,
	nvl(M.品名,' ') 品名,
	nvl(M.規格,' ') 規格,
	M.不用回簽報價單
FROM
	ViewFIL4010 M 
	LEFT JOIN FIL0030 N ON N.單據類別=M.單別 AND N.單據編號=M.單號
	LEFT JOIN 
	(
	SELECT A.說明一,
		LISTAGG(A.單號, ',') WITHIN GROUP (ORDER BY A.流水編號) as 製令單號
	FROM 
		FIL0038 A
	WHERE 
		A.單別='C11' AND A.說明一<>' '
	GROUP BY 
		A.說明一
	) A ON M.單號=A.說明一
	LEFT JOIN
	(
	SELECT 
		A.單號,
		MIN(A.建檔日||建檔時) 客戶回簽日時
	FROM
		FIL1011 A
	WHERE 
		A.簽核系統 = 'B11.APK'
	GROUP BY
		A.單號
	) B ON B.單號 = A.說明一
	LEFT JOIN
	(
	SELECT 
		A.單號,
		MIN(A.建檔日||建檔時) 佐證上傳日時
	FROM
		FIL1011 A
	WHERE 
		A.簽核系統 = 'B11.APK_A'
	GROUP BY
		A.單號
	) C ON C.單號 = A.說明一
Where
	M.不用回簽報價單=0 AND
	M.簽核狀態 = 'E'
	
);

-- Oracle user_views
CREATE VIEW "VIEWFIL402E" ("單別", "單號", "序號", "備註", "產品編號", "品名", "規格", "手動品名", "手動規格", "總價", "製版費", "流水編號", "單據日期", "廠客編號", "廠客全名", "簽核狀態", "訂單數量", "已交數量", "贈品量", "贈品已交量", "待交數量") AS (
SELECT 
	A.單據類別 單別, 
	A.單據編號 單號,
	A.單據序號 序號,
	A.備註說明 備註,
	A.產品編號,
	D.品名,
	D.規格,
	C.手動品名,
	C.手動規格,
	A.異動金額 總價,
	A.製版費,
	M.流水編號,
	M.單據日期,
	M.廠客編號,
	E.全名 廠客全名,
	nvl(Z3.簽核狀態, '0') 簽核狀態,
	A.異動數量 訂單數量,
	(NVL(K.交貨數量,0)-NVL(L.退貨數量,0)) 已交數量,
	A.贈品數量 贈品量,
	(NVL(K.交貨贈品數,0)-NVL(L.退貨贈品數,0)) 贈品已交量,
	greatest((A.異動數量+A.贈品數量)-(NVL(K.交貨數量,0)-NVL(L.退貨數量,0))-(NVL(K.交貨贈品數,0)-NVL(L.退貨贈品數,0)),0) 待交數量
FROM 
	FIL0040 A
	INNER JOIN FIL0030 M ON M.單據類別=A.單據類別 AND M.單據編號  = A.單據編號 
	INNER JOIN FIL0041 C ON C.單別=A.單據類別 AND C.單號 = A.單據編號 AND C.序號 = A.單據序號
	INNER JOIN ViewOfObjProperties Z3 ON M.流水編號 = Z3.單據流水號 AND Z3.簽核狀態 = 'E'
	INNER JOIN ViewFIL1012 D ON A.產品編號 = D.產品編號 
	LEFT JOIN FIL0011 E ON M.廠客編號 = E.編號
	LEFT JOIN 
	(
	SELECT 
		A1.文數字1 訂單單別,
		A1.文數字2 訂單單號,
		A1.數值1 訂單序號,
		sum(A.異動數量) 交貨數量,
		sum(A.贈品數量) 交貨贈品數	
	FROM 
		FIL0040 A
		INNER JOIN FIL0030 M ON M.單據類別 = A.單據類別 AND M.單據編號 = A.單據編號
		INNER JOIN FIL0041 A1 ON A.單據類別 = A1.單別 AND A.單據編號 = A1.單號 AND A.單據序號 = A1.序號
		LEFT JOIN ViewOfObjProperties Z3 ON M.流水編號 = Z3.單據流水號
	WHERE
		A.單據類別 = 'B42' and
		nvl(Z3.簽核狀態,' ') <> 'A'
	GROUP BY
		A1.文數字1,
		A1.文數字2,
		A1.數值1
	) K ON K.訂單單別 = A.單據類別 AND K.訂單單號 = A.單據編號 AND K.訂單序號 = A.單據序號
	LEFT JOIN 
	(
	SELECT 
		A1.文數字1 訂單單別,
		A1.文數字2 訂單單號,
		A1.數值1 訂單序號,
		SUM(A.異動數量*-1) 退貨數量,
		SUM(A.贈品數量*-1) 退貨贈品數	
	FROM 
		FIL0040 A
		INNER JOIN FIL0030 M ON M.單據類別 = A.單據類別 AND M.單據編號 = A.單據編號
		INNER JOIN FIL0041 A1 ON A.單據類別 = A1.單別 AND A.單據編號 = A1.單號 AND A.單據序號 = A1.序號
		LEFT JOIN ViewOfObjProperties Z3 ON M.流水編號 = Z3.單據流水號
	WHERE
		A.單據類別 = 'B51' and
		nvl(Z3.簽核狀態,' ') <> 'A'
	GROUP BY
		A1.文數字1,
		A1.文數字2,
		A1.數值1	
	) L ON L.訂單單別 = A.單據類別 AND L.訂單單號 = A.單據編號 AND L.訂單序號 = A.單據序號
WHERE
	A.單據類別 = 'B31' 
	);

-- Oracle user_views
CREATE VIEW "VIEWFIL402F" ("單別", "單號", "訂單單別", "訂單單號", "公司代碼", "公司名稱", "訂單類別", "客戶單號", "出貨廠別", "廠別名稱", "部門編號", "部門名稱", "價格條件", "付款條件", "付款條件名稱", "材積單位", "材積單位名稱", "確認碼", "單據日期", "簽核系統", "簽核系統_結案", "廠客編號", "廠客簡稱", "廠客全名", "備註", "業務員", "業務員姓名", "幣別代碼", "幣別名稱", "匯率", "稅別", "稅別說明", "稅率", "聯絡人序號", "聯絡人", "電話", "分機", "職務", "EMAIL", "行動電話", "送貨地址序號", "收貨人", "收貨地址", "收貨電話", "未稅金額", "稅額", "應稅金額", "寄庫品", "流水編號", "填表人", "填表人姓名", "填表日", "最後更新者", "更新者姓名", "最後更新日", "簽核狀態", "發函代理人", "代理人姓名", "寄庫發貨允許") AS (                                                                                                                                                      SELECT
	A.單據類別 單別,
	A.單據編號 單號,
	A.歸屬類別 訂單單別,
	A.歸屬編號 訂單單號,
	A.公司代碼,
	nvl(M.全名, ' ') 公司名稱,
	B.類別 訂單類別,
	A.廠客單號 客戶單號,
	A.廠別編號 出貨廠別,
	nvl(L.廠別名稱, ' ') 廠別名稱,
	A.部門編號,
	nvl(I.部門名稱, ' ') 部門名稱,
	B.價格條件,
	A.收付方式 付款條件,
	nvl(J.名稱, ' ') 付款條件名稱,
	B.材積單位,
	nvl(K.名稱, ' ') 材積單位名稱,
	A.確認碼,
	A.單據日期,
	A.簽核系統, 
	A.簽核系統_結案, 
	A.廠客編號,
	nvl(E.簡稱, ' ') 廠客簡稱,
	nvl(E.全名, ' ') 廠客全名,
	A.備註, 
	A.業務員,
	nvl(F.員工姓名,' ') 業務員姓名, 	
	A.幣別代碼,
	nvl(G.名稱, ' ') 幣別名稱,
	A.匯率,
	A.稅別,
	decode(A.稅別, '1', '應稅', '2', '零稅率', '3', '免稅', '空白') 稅別說明,
	A.稅率,
	B.聯絡人序號,
	nvl(C.聯絡人, ' ') 聯絡人,
	nvl(C.電話, ' ') 電話,
	nvl(C.分機, ' ') 分機,
	nvl(C.職務, ' ') 職務,
	nvl(C.eMail, ' ') eMail,
	nvl(C.行動電話, ' ') 行動電話,
	B.送貨地址序號,
	nvl(D.收貨人, ' ') 收貨人,
	nvl(D.地址, ' ') 收貨地址,
	nvl(D.電話, ' ') 收貨電話,
	B.數值1 未稅金額,
	B.數值2 稅額,
	B.數值3 應稅金額,
	A.邏輯值一 寄庫品,
	A.流水編號,
	A.填表人,
	nvl(Z1.員工姓名,' ') 填表人姓名, 
	A.填表日, 
	A.最後更新者,
	nvl(Z2.員工姓名,' ') 更新者姓名, 
	A.最後更新日,
	nvl(Z3.簽核狀態, '0') 簽核狀態,
	nvl(H.發函代理人, ' ') 發函代理人,
	nvl(H.代理人姓名, ' ') 代理人姓名,
	B.Logical1 寄庫發貨允許	
FROM
	FIL0030 A
	INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
	LEFT JOIN ViewFIL1015a C ON A.廠客編號 = C.編號 AND B.聯絡人序號 = C.序號
	LEFT JOIN FIL0015 D ON A.廠客編號 = D.廠客編號 AND B.送貨地址序號 = D.序號
	LEFT JOIN FIL0011 E ON A.廠客編號 = E.編號
	LEFT JOIN FIL0010 F ON A.業務員 = F.員工編號
	LEFT JOIN ViewFIL3102 G ON A.幣別代碼 = G.代碼
	LEFT JOIN ViewFIL0030 H ON A.簽核系統 = H.簽核系統 AND A.單據編號 = H.單號
	LEFT JOIN FIL0020 I ON A.部門編號 = I.部門編號
	LEFT JOIN ViewFIL3107 J ON A.收付方式 = J.代碼
	LEFT JOIN ViewFIL3103 K ON B.材積單位 = K.代碼
	LEFT JOIN FIL0013 L ON A.廠別編號 = L.廠別編號
	LEFT JOIN ViewFIL0011 M ON A.公司代碼 = M.代碼
	LEFT JOIN FIL0010 Z1 ON A.填表人 = Z1.員工編號
	LEFT JOIN FIL0010 Z2 ON A.最後更新者 = Z2.員工編號
	LEFT JOIN ViewOfObjProperties Z3 ON A.流水編號 = Z3.單據流水號
WHERE
	A.單據類別 = 'B42');

-- Oracle user_views
CREATE VIEW "VIEWFIL402G" ("單別", "單號", "序號", "產品編號", "品名", "規格", "材質", "異動日期", "客戶品號", "訂單數量", "出庫數量", "贈品量", "寄庫數量", "寄庫出貨", "單位代碼", "單位名稱", "小單位", "小單位名稱", "折扣率", "包裝數量", "包裝單位", "包裝單位名稱", "單價", "金額", "毛重", "材積", "製版費", "預交日", "交貨庫別", "庫別名稱", "前置單別", "前置單號", "訂單單別", "訂單單號", "訂單序號", "專案代號", "備註", "結案碼", "流水編號", "最後更新者", "更新者姓名", "最後更新日") AS (
SELECT 
	A.單據類別 單別, 
	A.單據編號 單號,
	A.單據序號 序號,
	A.產品編號,
	nvl(C.品名, ' ') 品名,
	nvl(C.規格, ' ') 規格,
	trim(nvl(H.品名, ' ')||nvl(H.規格,' ')) || decode(A1.客戶報價材質結構2, ' ', ' ', '/' || trim(nvl(I.品名||nvl(I.規格,' '), ' '))) || decode(A1.客戶報價材質結構3, ' ', ' ', '/' || trim(nvl(J.品名||nvl(J.規格,' '), ' '))) 材質,
	A.異動日期,
	A.廠客品號 客戶品號,
	A.異動數量 訂單數量,
	decode(C.產品類別,'O',A.異動數量,NVL(K.出庫數量,0)) 出庫數量,
	A.贈品數量 贈品量,
	A.數值3 寄庫數量,
	greatest(decode(C.產品類別,'O',A.異動數量,NVL(K.出庫數量,0))-(A.異動數量+A.贈品數量),0) 寄庫出貨,
	A.單位代碼,
	nvl(D.名稱, ' ') 單位名稱,
	A1.小單位,
	nvl(E.名稱, ' ') 小單位名稱,
	A.折扣率,
	A1.包裝數量,
	A1.包裝單位,
	nvl(F.名稱, ' ') 包裝單位名稱,
	A.異動單價 單價,
	A.異動金額 金額,
	A.毛重,
	A.材積,
	A.製版費,
	A.預交日,
	A.倉庫代碼 交貨庫別,
	nvl(G.名稱, ' ') 庫別名稱,
	A.前置單別,
	A.前置單號,
	A1.文數字1 訂單單別,
	A1.文數字2 訂單單號,
	A1.數值1 訂單序號,
	A1.專案代號,
	A.備註說明 備註,
	A.結案碼,
	A.流水編號,
	A.最後更新者,
	NVL(B.員工姓名,' ') 更新者姓名,
	A.最後更新日
FROM 
	FIL0040 A
	INNER JOIN FIL0041 A1 ON A.單據類別 = A1.單別 AND A.單據編號 = A1.單號 AND A.單據序號 = A1.序號
	LEFT JOIN FIL0010 B ON A.最後更新者 = B.員工編號
	LEFT JOIN ViewFIL1012 C ON A.產品編號 = C.產品編號
	LEFT JOIN ViewFIL3103 D ON A.單位代碼 = D.代碼
	LEFT JOIN ViewFIL3103 E ON A1.小單位 = E.代碼
	LEFT JOIN ViewFIL3103 F ON A1.包裝單位 = F.代碼
	LEFT JOIN ViewFIL3106 G ON A.倉庫代碼 = G.代碼
	LEFT JOIN FIL0012 H ON A1.客戶報價材質結構1 = H.產品編號
	LEFT JOIN FIL0012 I ON A1.客戶報價材質結構2 = I.產品編號
	LEFT JOIN FIL0012 J ON A1.客戶報價材質結構3 = J.產品編號
	LEFT JOIN 
	(
	SELECT 
		A.單據類別,
		A.單據號碼,
		A.單據序號,
		SUM(A.異動數量)*-1 出庫數量
	FROM 
		FIL0044 A 
	WHERE A.單據類別='B42'	
	GROUP BY 
		A.單據類別,
		A.單據號碼,
		A.單據序號 
	) K ON A.單據類別 = K.單據類別 AND A.單據編號 = K.單據號碼 AND A.單據序號 = K.單據序號
WHERE
	A.單據類別 = 'B42');

-- Oracle user_views
CREATE VIEW "VIEWFIL402G1" ("單據類別", "單據號碼", "單據序號", "出庫數量") AS (
SELECT 
	A.單據類別, 
	A.單據編號 單據號碼,
	A.單據序號,
	sum(decode(C.產品類別,'O',A.異動數量,NVL(K.出庫數量,0))) 出庫數量
FROM 
	FIL0040 A
	INNER JOIN FIL0041 A1 ON A.單據類別 = A1.單別 AND A.單據編號 = A1.單號 AND A.單據序號 = A1.序號
	LEFT JOIN ViewFIL1012 C ON A.產品編號 = C.產品編號
	LEFT JOIN 
	(
	SELECT 
		A.單據類別,
		A.單據號碼,
		A.單據序號,
		SUM(A.異動數量)*-1 出庫數量
	FROM 
		FIL0044 A 
	WHERE A.單據類別='B42'	
	GROUP BY 
		A.單據類別,
		A.單據號碼,
		A.單據序號 
	) K ON A.單據類別 = K.單據類別 AND A.單據編號 = K.單據號碼 AND A.單據序號 = K.單據序號
WHERE
	A.單據類別 = 'B42'	
GROUP BY
	A.單據類別,
	A.單據編號,
	A.單據序號
	);

-- Oracle user_views
CREATE VIEW "VIEWFIL402H" ("單別", "單號", "訂單數量", "已交數量", "贈品量", "贈品已交量", "金額", "毛重", "材積", "稅率", "稅額", "含稅金額") AS (SELECT 
	A.單別, 
	A.單號,
	A.訂單數量,
	A.已交數量,
	A.贈品量,
	A.贈品已交量,
	A.金額,
	A.毛重,
	A.材積,
	B.稅率,
	A.稅額 稅額,
	A.金額+A.稅額 含稅金額
FROM
	(	SELECT 
			A.單據類別 單別, 
			A.單據編號 單號,
			sum(A.異動數量) 訂單數量,
			0 已交數量,
			sum(A.贈品數量) 贈品量,
			0 贈品已交量,
			sum(A.異動金額) 金額,
			sum(A.異動稅額) 稅額,
			sum(A.毛重) 毛重,
			sum(A.材積) 材積
		FROM 
			FIL0040 A
		WHERE
			A.單據類別 = 'B42'
		GROUP BY
			A.單據類別,
			A.單據編號
	) A
	INNER JOIN FIL0030 B ON A.單別 = B.單據類別 AND A.單號 = B.單據編號);

-- Oracle user_views
CREATE VIEW "VIEWFIL402I" ("單別", "單號", "訂單單別", "訂單單號", "公司代碼", "公司名稱", "訂單類別", "客戶單號", "出貨廠別", "廠別名稱", "部門編號", "部門名稱", "價格條件", "付款條件", "付款條件名稱", "材積單位", "材積單位名稱", "確認碼", "單據日期", "簽核系統", "簽核系統_結案", "廠客編號", "廠客簡稱", "廠客全名", "備註", "業務員", "業務員姓名", "幣別代碼", "幣別名稱", "匯率", "稅別", "稅別說明", "稅率", "聯絡人序號", "聯絡人", "電話", "分機", "職務", "EMAIL", "行動電話", "送貨地址序號", "收貨人", "收貨地址", "收貨電話", "未稅金額", "稅額", "應稅金額", "流水編號", "填表人", "填表人姓名", "填表日", "最後更新者", "更新者姓名", "最後更新日", "簽核狀態", "發函代理人", "代理人姓名") AS (                                                                                                                                                      SELECT
	A.單據類別 單別,
	A.單據編號 單號,
	A.歸屬類別 訂單單別,
	A.歸屬編號 訂單單號,
	A.公司代碼,
	nvl(M.全名, ' ') 公司名稱,
	B.類別 訂單類別,
	A.廠客單號 客戶單號,
	A.廠別編號 出貨廠別,
	nvl(L.廠別名稱, ' ') 廠別名稱,
	A.部門編號,
	nvl(I.部門名稱, ' ') 部門名稱,
	B.價格條件,
	A.收付方式 付款條件,
	nvl(J.名稱, ' ') 付款條件名稱,
	B.材積單位,
	nvl(K.名稱, ' ') 材積單位名稱,
	A.確認碼,
	A.單據日期,
	A.簽核系統, 
	A.簽核系統_結案, 
	A.廠客編號,
	nvl(E.簡稱, ' ') 廠客簡稱,
	nvl(E.全名, ' ') 廠客全名,
	A.備註, 
	A.業務員,
	nvl(F.員工姓名,' ') 業務員姓名, 	
	A.幣別代碼,
	nvl(G.名稱, ' ') 幣別名稱,
	A.匯率,
	A.稅別,
	decode(A.稅別, '1', '應稅', '2', '零稅率', '3', '免稅', '空白') 稅別說明,
	A.稅率,
	B.聯絡人序號,
	nvl(C.聯絡人, ' ') 聯絡人,
	nvl(C.電話, ' ') 電話,
	nvl(C.分機, ' ') 分機,
	nvl(C.職務, ' ') 職務,
	nvl(C.eMail, ' ') eMail,
	nvl(C.行動電話, ' ') 行動電話,
	B.送貨地址序號,
	nvl(D.收貨人, ' ') 收貨人,
	nvl(D.地址, ' ') 收貨地址,
	nvl(D.電話, ' ') 收貨電話,
	B.數值1 未稅金額,
	B.數值2 稅額,
	B.數值3 應稅金額,
	A.流水編號,
	A.填表人,
	nvl(Z1.員工姓名,' ') 填表人姓名, 
	A.填表日, 
	A.最後更新者,
	nvl(Z2.員工姓名,' ') 更新者姓名, 
	A.最後更新日,
	nvl(Z3.簽核狀態, '0') 簽核狀態,
	nvl(H.發函代理人, ' ') 發函代理人,
	nvl(H.代理人姓名, ' ') 代理人姓名	
FROM
	FIL0030 A
	INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
	LEFT JOIN ViewFIL1015a C ON A.廠客編號 = C.編號 AND B.聯絡人序號 = C.序號
	LEFT JOIN FIL0015 D ON A.廠客編號 = D.廠客編號 AND B.送貨地址序號 = D.序號
	LEFT JOIN FIL0011 E ON A.廠客編號 = E.編號
	LEFT JOIN FIL0010 F ON A.業務員 = F.員工編號
	LEFT JOIN ViewFIL3102 G ON A.幣別代碼 = G.代碼
	LEFT JOIN ViewFIL0030 H ON A.簽核系統 = H.簽核系統 AND A.單據編號 = H.單號
	LEFT JOIN FIL0020 I ON A.部門編號 = I.部門編號
	LEFT JOIN ViewFIL3107 J ON A.收付方式 = J.代碼
	LEFT JOIN ViewFIL3103 K ON B.材積單位 = K.代碼
	LEFT JOIN FIL0013 L ON A.廠別編號 = L.廠別編號
	LEFT JOIN ViewFIL0011 M ON A.公司代碼 = M.代碼
	LEFT JOIN FIL0010 Z1 ON A.填表人 = Z1.員工編號
	LEFT JOIN FIL0010 Z2 ON A.最後更新者 = Z2.員工編號
	LEFT JOIN ViewOfObjProperties Z3 ON A.流水編號 = Z3.單據流水號
WHERE
	A.單據類別 = 'B51');

-- Oracle user_views
CREATE VIEW "VIEWFIL402J" ("單別", "單號", "序號", "產品編號", "品名", "規格", "材質", "異動日期", "客戶品號", "訂單數量", "已交數量", "贈品量", "贈品已交量", "單位代碼", "單位名稱", "小單位", "小單位名稱", "折扣率", "包裝數量", "包裝單位", "包裝單位名稱", "單價", "金額", "毛重", "材積", "製版費", "預交日", "交貨庫別", "庫別名稱", "前置單別", "前置單號", "訂單單別", "訂單單號", "訂單序號", "專案代號", "備註", "結案碼", "流水編號", "最後更新者", "更新者姓名", "最後更新日") AS (SELECT 
	A.單據類別 單別, 
	A.單據編號 單號,
	A.單據序號 序號,
	A.產品編號,
	nvl(C.品名, ' ') 品名,
	nvl(C.規格, ' ') 規格,
	trim(nvl(H.品名, ' ')||nvl(H.規格,' ')) || decode(A1.客戶報價材質結構2, ' ', ' ', '/' || trim(nvl(I.品名||nvl(I.規格,' '), ' '))) || decode(A1.客戶報價材質結構3, ' ', ' ', '/' || trim(nvl(J.品名||nvl(J.規格,' '), ' '))) 材質,
	A.異動日期,
	A.廠客品號 客戶品號,
	A.異動數量 訂單數量,
	0 已交數量,
	A.贈品數量 贈品量,
	0 贈品已交量,
	A.單位代碼,
	nvl(D.名稱, ' ') 單位名稱,
	A1.小單位,
	nvl(E.名稱, ' ') 小單位名稱,
	A.折扣率,
	A1.包裝數量,
	A1.包裝單位,
	nvl(F.名稱, ' ') 包裝單位名稱,
	A.異動單價 單價,
	A.異動金額 金額,
	A.毛重,
	A.材積,
	A.製版費,
	A.預交日,
	A.倉庫代碼 交貨庫別,
	nvl(G.名稱, ' ') 庫別名稱,
	A.前置單別,
	A.前置單號,
	A1.文數字1 訂單單別,
	A1.文數字2 訂單單號,
	A1.數值1 訂單序號,
	A1.專案代號,
	A.備註說明 備註,
	A.結案碼,
	A.流水編號,
	A.最後更新者,
	NVL(B.員工姓名,' ') 更新者姓名,
	A.最後更新日
FROM 
	FIL0040 A
	INNER JOIN FIL0041 A1 ON A.單據類別 = A1.單別 AND A.單據編號 = A1.單號 AND A.單據序號 = A1.序號
	LEFT JOIN FIL0010 B ON A.最後更新者 = B.員工編號
	LEFT JOIN ViewFIL1012 C ON A.產品編號 = C.產品編號
	LEFT JOIN ViewFIL3103 D ON A.單位代碼 = D.代碼
	LEFT JOIN ViewFIL3103 E ON A1.小單位 = E.代碼
	LEFT JOIN ViewFIL3103 F ON A1.包裝單位 = F.代碼
	LEFT JOIN ViewFIL3106 G ON A.倉庫代碼 = G.代碼
	LEFT JOIN FIL0012 H ON A1.客戶報價材質結構1 = H.產品編號
	LEFT JOIN FIL0012 I ON A1.客戶報價材質結構2 = I.產品編號
	LEFT JOIN FIL0012 J ON A1.客戶報價材質結構3 = J.產品編號
WHERE
	A.單據類別 = 'B51');

-- Oracle user_views
CREATE VIEW "VIEWFIL402K" ("單別", "單號", "訂單數量", "已交數量", "贈品量", "贈品已交量", "金額", "毛重", "材積", "稅率", "稅額", "含稅金額") AS (SELECT 
	A.單別, 
	A.單號,
	A.訂單數量,
	A.已交數量,
	A.贈品量,
	A.贈品已交量,
	A.金額,
	A.毛重,
	A.材積,
	B.稅率,
	A.稅額,
	A.金額 + A.稅額 含稅金額
FROM
	(	SELECT 
			A.單據類別 單別, 
			A.單據編號 單號,
			sum(A.異動數量) 訂單數量,
			0 已交數量,
			sum(A.贈品數量) 贈品量,
			0 贈品已交量,
			sum(A.異動金額) 金額,
			sum(A.異動稅額) 稅額,
			sum(A.毛重) 毛重,
			sum(A.材積) 材積
		FROM 
			FIL0040 A
		WHERE
			A.單據類別 = 'B51'
		GROUP BY
			A.單據類別,
			A.單據編號
	) A
	INNER JOIN FIL0030 B ON A.單別 = B.單據類別 AND A.單號 = B.單據編號);

-- Oracle user_views
CREATE VIEW "VIEWFIL402L" ("單別", "單號", "訂單單別", "訂單單號", "公司代碼", "公司名稱", "訂單類別", "客戶單號", "出貨廠別", "廠別名稱", "部門編號", "部門名稱", "價格條件", "付款條件", "付款條件名稱", "材積單位", "材積單位名稱", "確認碼", "單據日期", "簽核系統", "簽核系統_結案", "廠客編號", "廠客簡稱", "廠客全名", "備註", "業務員", "業務員姓名", "幣別代碼", "幣別名稱", "匯率", "稅別", "稅別說明", "稅率", "聯絡人序號", "聯絡人", "電話", "分機", "職務", "EMAIL", "行動電話", "送貨地址序號", "收貨人", "收貨地址", "收貨電話", "未稅金額", "稅額", "應稅金額", "流水編號", "填表人", "填表人姓名", "填表日", "最後更新者", "更新者姓名", "最後更新日", "簽核狀態", "發函代理人", "代理人姓名", "寄庫發貨允許") AS (                                                                                                                                                      
SELECT
	to_char('B43') 單別,
	A.單據編號 單號,
	A.歸屬類別 訂單單別,
	A.歸屬編號 訂單單號,
	A.公司代碼,
	nvl(M.全名, ' ') 公司名稱,
	B.類別 訂單類別,
	A.廠客單號 客戶單號,
	A.廠別編號 出貨廠別,
	nvl(L.廠別名稱, ' ') 廠別名稱,
	A.部門編號,
	nvl(I.部門名稱, ' ') 部門名稱,
	B.價格條件,
	A.收付方式 付款條件,
	nvl(J.名稱, ' ') 付款條件名稱,
	B.材積單位,
	nvl(K.名稱, ' ') 材積單位名稱,
	A.確認碼,
	A.單據日期,
	A.簽核系統, 
	A.簽核系統_結案, 
	A.廠客編號,
	nvl(E.簡稱, ' ') 廠客簡稱,
	nvl(E.全名, ' ') 廠客全名,
	A.備註, 
	A.業務員,
	nvl(F.員工姓名,' ') 業務員姓名, 	
	A.幣別代碼,
	nvl(G.名稱, ' ') 幣別名稱,
	A.匯率,
	A.稅別,
	decode(A.稅別, '1', '應稅', '2', '零稅率', '3', '免稅', '空白') 稅別說明,
	A.稅率,
	B.聯絡人序號,
	nvl(C.聯絡人, ' ') 聯絡人,
	nvl(C.電話, ' ') 電話,
	nvl(C.分機, ' ') 分機,
	nvl(C.職務, ' ') 職務,
	nvl(C.eMail, ' ') eMail,
	nvl(C.行動電話, ' ') 行動電話,
	B.送貨地址序號,
	nvl(D.收貨人, ' ') 收貨人,
	nvl(D.地址, ' ') 收貨地址,
	nvl(D.電話, ' ') 收貨電話,
	B.數值1 未稅金額,
	B.數值2 稅額,
	B.數值3 應稅金額,
	A.流水編號,
	A.填表人,
	nvl(Z1.員工姓名,' ') 填表人姓名, 
	A.填表日, 
	A.最後更新者,
	nvl(Z2.員工姓名,' ') 更新者姓名, 
	A.最後更新日,
	nvl(Z3.簽核狀態, '0') 簽核狀態,
	nvl(H.發函代理人, ' ') 發函代理人,
	nvl(H.代理人姓名, ' ') 代理人姓名,
	B.Logical1 寄庫發貨允許
FROM
	FIL0030 A
	INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
	LEFT JOIN ViewFIL1015a C ON A.廠客編號 = C.編號 AND B.聯絡人序號 = C.序號
	LEFT JOIN FIL0015 D ON A.廠客編號 = D.廠客編號 AND B.送貨地址序號 = D.序號
	LEFT JOIN FIL0011 E ON A.廠客編號 = E.編號
	LEFT JOIN FIL0010 F ON A.業務員 = F.員工編號
	LEFT JOIN ViewFIL3102 G ON A.幣別代碼 = G.代碼
	LEFT JOIN ViewFIL0030 H ON A.簽核系統 = H.簽核系統 AND A.單據編號 = H.單號
	LEFT JOIN FIL0020 I ON A.部門編號 = I.部門編號
	LEFT JOIN ViewFIL3107 J ON A.收付方式 = J.代碼
	LEFT JOIN ViewFIL3103 K ON B.材積單位 = K.代碼
	LEFT JOIN FIL0013 L ON A.廠別編號 = L.廠別編號
	LEFT JOIN ViewFIL0011 M ON A.公司代碼 = M.代碼
	LEFT JOIN FIL0010 Z1 ON A.填表人 = Z1.員工編號
	LEFT JOIN FIL0010 Z2 ON A.最後更新者 = Z2.員工編號
	INNER JOIN ViewOfObjProperties Z3 ON A.流水編號 = Z3.單據流水號 and Z3.簽核狀態 = 'E'
WHERE
	A.單據類別 = 'B42' AND A.邏輯值一= 1);

-- Oracle user_views
CREATE VIEW "VIEWFIL402M" ("單別", "單號", "序號", "產品編號", "品名", "規格", "材質", "異動日期", "客戶品號", "訂單數量", "出庫數量", "贈品量", "單位代碼", "單位名稱", "小單位", "小單位名稱", "折扣率", "包裝數量", "包裝單位", "包裝單位名稱", "單價", "金額", "毛重", "材積", "製版費", "預交日", "交貨庫別", "庫別名稱", "前置單別", "前置單號", "訂單單別", "訂單單號", "訂單序號", "專案代號", "備註", "結案碼", "流水編號", "最後更新者", "更新者姓名", "最後更新日") AS (
SELECT 
	TO_CHAR('B43') 單別, 
	A.單據編號 單號,
	A.單據序號 序號,
	A.產品編號,
	nvl(C.品名, ' ') 品名,
	nvl(C.規格, ' ') 規格,
	trim(nvl(H.品名, ' ')||nvl(H.規格,' ')) || decode(A1.客戶報價材質結構2, ' ', ' ', '/' || trim(nvl(I.品名||nvl(I.規格,' '), ' '))) || decode(A1.客戶報價材質結構3, ' ', ' ', '/' || trim(nvl(J.品名||nvl(J.規格,' '), ' '))) 材質,
	A.異動日期,
	A.廠客品號 客戶品號,
	A.異動數量 訂單數量,
	decode(C.產品類別,'O',A.異動數量,NVL(K.出庫數量,0)) 出庫數量,
	A.贈品數量 贈品量,
	A.單位代碼,
	nvl(D.名稱, ' ') 單位名稱,
	A1.小單位,
	nvl(E.名稱, ' ') 小單位名稱,
	A.折扣率,
	A1.包裝數量,
	A1.包裝單位,
	nvl(F.名稱, ' ') 包裝單位名稱,
	A.異動單價 單價,
	A.異動金額 金額,
	A.毛重,
	A.材積,
	A.製版費,
	A.預交日,
	A.倉庫代碼 交貨庫別,
	nvl(G.名稱, ' ') 庫別名稱,
	A.前置單別,
	A.前置單號,
	A1.文數字1 訂單單別,
	A1.文數字2 訂單單號,
	A1.數值1 訂單序號,
	A1.專案代號,
	A.備註說明 備註,
	A.結案碼,
	A.流水編號,
	A.最後更新者,
	NVL(B.員工姓名,' ') 更新者姓名,
	A.最後更新日
FROM 
	FIL0040 A
	INNER JOIN FIL0041 A1 ON A.單據類別 = A1.單別 AND A.單據編號 = A1.單號 AND A.單據序號 = A1.序號
	INNER JOIN FIL0030 Z1 ON Z1.單據類別 = A.單據類別 AND Z1.單據編號 = A.單據編號 AND Z1.邏輯值一= 1	
	INNER JOIN ViewOfObjProperties Z3 ON Z1.流水編號 = Z3.單據流水號 and Z3.簽核狀態 = 'E'
	LEFT JOIN FIL0010 B ON A.最後更新者 = B.員工編號
	LEFT JOIN ViewFIL1012 C ON A.產品編號 = C.產品編號
	LEFT JOIN ViewFIL3103 D ON A.單位代碼 = D.代碼
	LEFT JOIN ViewFIL3103 E ON A1.小單位 = E.代碼
	LEFT JOIN ViewFIL3103 F ON A1.包裝單位 = F.代碼
	LEFT JOIN ViewFIL3106 G ON A.倉庫代碼 = G.代碼
	LEFT JOIN FIL0012 H ON A1.客戶報價材質結構1 = H.產品編號
	LEFT JOIN FIL0012 I ON A1.客戶報價材質結構2 = I.產品編號
	LEFT JOIN FIL0012 J ON A1.客戶報價材質結構3 = J.產品編號
	LEFT JOIN 
	(
	SELECT 
		A.單據類別,
		A.單據號碼,
		A.單據序號,
		SUM(A.異動數量)*-1 出庫數量
	FROM 
		FIL0044 A 
	WHERE A.單據類別='B42'	
	GROUP BY 
		A.單據類別,
		A.單據號碼,
		A.單據序號 
	) K ON A.單據類別 = K.單據類別 AND A.單據編號 = K.單據號碼 AND A.單據序號 = K.單據序號
WHERE
	A.單據類別 = 'B42');

-- Oracle user_views
CREATE VIEW "VIEWFIL4030" ("製令單別", "製令單號", "前置單別", "前置單號", "前置產品編號", "填單日期", "簽核系統", "簽核系統_結案", "產品編號", "產品名稱", "產品規格", "材質結構", "訂單單別", "訂單單號", "客戶編號", "客戶名稱", "客戶地址", "客戶電話", "業務流水編號", "公司代碼", "公司名稱", "明細序號", "訂購數量", "色數", "預交日", "印刷單位", "印刷單位名稱", "包裝方式", "包裝方式說明", "油墨種類", "油墨種類名稱", "送貨地址", "流水編號", "主旨", "員工流水編號", "類別", "填表人", "填表人姓名", "填表日", "最後更新者", "更新者姓名", "最後更新日", "簽核狀態", "改版", "改色", "結案", "產品3D網址", "包裝對應客戶標籤") AS (                                                                                                                                                  SELECT
	A.製令單別,
	A.製令單號,
	A.前置單別,
	A.前置單號,
	NVL(A1.產品編號,' ') 前置產品編號,
	B.單據日期 填單日期,
	B.簽核系統, 
	B.簽核系統_結案, 
	A.產品編號,
	A.產品名稱,
	nvl(I1.規格, nvl(I2.規格, ' ')) 產品規格,
	' ' 材質結構,
	B.歸屬類別 訂單單別,
	decode(B.歸屬編號,' ',B.訂單號碼,B.歸屬編號) 訂單單號,
	B.廠客編號 客戶編號,
	nvl(H.全名, ' ') 客戶名稱,
	nvl(H.登記地址一, ' ') 客戶地址,
	nvl(H.登記電話, ' ') 客戶電話,
	nvl(H1.Serial_Num,' ') 業務流水編號,
	nvl(F.公司代碼, B.公司代碼) 公司代碼,
	nvl(M.名稱, ' ') 公司名稱,
	nvl(G.單據序號, 0) 明細序號,
	decode(A.成袋數, 0, nvl(N1.成捲數, nvl(N2.成捲數, nvl(N3.成捲數, nvl(N4.成捲數, 0)))), A.成袋數) 訂購數量,
	(decode(N1.印刷色順一,' ',0,1)+decode(N1.印刷色順二,' ',0,1)+decode(N1.印刷色順三,' ',0,1)+decode(N1.印刷色順四,' ',0,1)+decode(N1.印刷色順五,' ',0,1)+decode(N1.印刷色順六,' ',0,1)+decode(N1.印刷色順七,' ',0,1)+decode(N1.印刷色順八,' ',0,1)+decode(N1.印刷色順九,' ',0,1)+decode(N1.印刷色順十,' ',0,1)+decode(N1.印刷色順十一,' ',0,1)+decode(N1.印刷色順十二,' ',0,1)) 色數,
	B.匯率日期 預交日,
	A.印刷單位,
	nvl(J.名稱, ' ') 印刷單位名稱,
	A.包裝方式,
	nvl(K.名稱, ' ') 包裝方式說明,
	A.油墨種類,
	nvl(L.名稱, ' ') 油墨種類名稱,
	A.送貨地址,
	B.流水編號,
	A.製令單號||'('||trim(A.製令單別)||')'||'/'||nvl(H.全名, ' ')||'/'||A.產品名稱 主旨,
	nvl(C.Serial_Num,' ') 員工流水編號,
	B.稅別 類別,
	B.填表人,
	nvl(C.員工姓名,' ') 填表人姓名, 
	B.填表日, 
	B.最後更新者,
	nvl(D.員工姓名,' ') 更新者姓名, 
	B.最後更新日,
	nvl(E.簽核狀態, '0') 簽核狀態,
	decode(B.確認碼,' ',0,1) 改版,
	B.歸屬序號 改色,
	B.邏輯值一 結案,
	A.成品尺寸 產品3D網址,
	A.包裝對應客戶標籤
FROM
	FIL0032 A
	INNER JOIN FIL0030 B ON A.製令單別 = B.單據類別 AND A.製令單號 = B.單據編號
	LEFT JOIN FIL0010 C ON B.填表人 = C.員工編號
	LEFT JOIN FIL0010 D ON B.最後更新者 = D.員工編號
	LEFT JOIN ViewOfObjProperties E ON B.流水編號 = E.單據流水號
	LEFT JOIN FIL0032 A1 ON A.前置單別 = A1.製令單別 AND A.前置單號=A1.製令單號
	/* 訂單 */
	LEFT JOIN FIL0030 F ON B.歸屬類別 = F.單據類別 AND B.歸屬編號 = F.單據編號
	LEFT JOIN FIL0040 G ON B.歸屬類別 = G.單據類別 AND B.歸屬編號 = G.單據編號 AND A.產品編號 = G.產品編號
	/* 客戶 */
	LEFT JOIN FIL0011 H ON B.廠客編號 = H.編號
	LEFT JOIN FIL0010 H1 ON H.採購人員 = H1.員工編號
	/* 規格(成品尺寸) */
	LEFT JOIN FIL0012 I1 ON A.產品編號 = I1.產品編號
	LEFT JOIN FIL0012 I2 ON trim(REGEXP_SUBSTR(A.產品編號, '([^/]+)', 1,1)) = I2.產品編號
	/* 印刷單位 */
	LEFT JOIN ViewFIL3103 J ON A.印刷單位 = J.代碼
	/* 包裝方式 */
	LEFT JOIN ViewFIL310C K ON A.包裝方式 = K.代碼
	/* 油墨種類 */
	LEFT JOIN ViewFIL3109 L ON A.油墨種類 = L.代碼
	/* 訂單公司別 */
	LEFT JOIN ViewFIL0011 M ON F.公司代碼 = M.代碼
	/* 成捲數 */
	LEFT JOIN FIL0033 N1 ON A.製令單別 = N1.製令單別 AND A.製令單號 = N1.製令單號 AND N1.加工別 = 'A'
	LEFT JOIN FIL0033 N2 ON A.製令單別 = N2.製令單別 AND A.製令單號 = N2.製令單號 AND N2.加工別 = 'B'
	LEFT JOIN FIL0033 N3 ON A.製令單別 = N3.製令單別 AND A.製令單號 = N3.製令單號 AND N3.加工別 = 'C'
	LEFT JOIN FIL0033 N4 ON A.製令單別 = N4.製令單別 AND A.製令單號 = N4.製令單號 AND N4.加工別 = 'D');

-- Oracle user_views
CREATE VIEW "VIEWFIL4030A" ("製令單別", "製令單號", "前置單別", "前置單號", "填單日期", "簽核系統", "簽核系統_結案", "產品編號", "產品名稱", "產品規格", "材質結構", "訂單單別", "訂單單號", "客戶編號", "客戶名稱", "業務流水編號", "公司代碼", "公司名稱", "明細序號", "訂購數量", "預交日", "印刷單位", "印刷單位名稱", "包裝方式", "包裝方式說明", "油墨種類", "油墨種類名稱", "送貨地址", "流水編號", "主旨", "員工流水編號", "類別", "填表人", "填表人姓名", "填表日", "最後更新者", "更新者姓名", "最後更新日", "簽核狀態", "改版") AS (                                                                                                                                                  SELECT
	A.製令單別,
	A.製令單號,
	A.前置單別,
	A.前置單號,
	B.單據日期 填單日期,
	B.簽核系統, 
	B.簽核系統_結案, 
	A.產品編號,
	A.產品名稱,
	nvl(I1.規格, nvl(I2.規格, ' ')) 產品規格,
	' ' 材質結構,
	B.歸屬類別 訂單單別,
	B.歸屬編號 訂單單號,
	B.廠客編號 客戶編號,
	nvl(H.全名, ' ') 客戶名稱,
	nvl(H1.Serial_Num,' ') 業務流水編號,
	nvl(F.公司代碼, B.公司代碼) 公司代碼,
	nvl(M.名稱, ' ') 公司名稱,
	nvl(G.單據序號, 0) 明細序號,
	decode(A.成袋數, 0, nvl(N1.成捲數, nvl(N2.成捲數, nvl(N3.成捲數, nvl(N4.成捲數, 0)))), A.成袋數) 訂購數量,
	B.匯率日期 預交日,
	A.印刷單位,
	nvl(J.名稱, ' ') 印刷單位名稱,
	A.包裝方式,
	nvl(K.名稱, ' ') 包裝方式說明,
	A.油墨種類,
	nvl(L.名稱, ' ') 油墨種類名稱,
	A.送貨地址,
	B.流水編號,
	A.製令單號||'('||trim(A.製令單別)||')'||'/'||nvl(H.全名, ' ')||'/'||A.產品名稱 主旨,
	nvl(C.Serial_Num,' ') 員工流水編號,
	B.稅別 類別,
	B.填表人,
	nvl(C.員工姓名,' ') 填表人姓名, 
	B.填表日, 
	B.最後更新者,
	nvl(D.員工姓名,' ') 更新者姓名, 
	B.最後更新日,
	nvl(E.簽核狀態, ' ') 簽核狀態,
	decode(B.確認碼,' ',0,1) 改版
FROM
	FIL0032 A
	INNER JOIN FIL0030 B ON A.製令單別 = B.單據類別 AND A.製令單號 = B.單據編號
	LEFT JOIN FIL0010 C ON B.填表人 = C.員工編號
	LEFT JOIN FIL0010 D ON B.最後更新者 = D.員工編號
	LEFT JOIN ViewOfObjProperties E ON B.流水編號 = E.單據流水號
	/* 訂單 */
	LEFT JOIN FIL0030 F ON B.歸屬類別 = F.單據類別 AND B.歸屬編號 = F.單據編號
	LEFT JOIN FIL0040 G ON B.歸屬類別 = G.單據類別 AND B.歸屬編號 = G.單據編號 AND A.產品編號 = G.產品編號
	/* 客戶 */
	LEFT JOIN FIL0011 H ON B.廠客編號 = H.編號
	LEFT JOIN FIL0010 H1 ON H.採購人員 = H1.員工編號
	/* 規格(成品尺寸) */
	LEFT JOIN FIL0012 I1 ON A.產品編號 = I1.產品編號
	LEFT JOIN FIL0012 I2 ON trim(REGEXP_SUBSTR(A.產品編號, '([^/]+)', 1,1)) = I2.產品編號
	/* 印刷單位 */
	LEFT JOIN ViewFIL3103 J ON A.印刷單位 = J.代碼
	/* 包裝方式 */
	LEFT JOIN ViewFIL310C K ON A.包裝方式 = K.代碼
	/* 油墨種類 */
	LEFT JOIN ViewFIL3109 L ON A.油墨種類 = L.代碼
	/* 訂單公司別 */
	LEFT JOIN ViewFIL0011 M ON F.公司代碼 = M.代碼
	/* 成捲數 */
	LEFT JOIN FIL0033 N1 ON A.製令單別 = N1.製令單別 AND A.製令單號 = N1.製令單號 AND N1.加工別 = 'A'
	LEFT JOIN FIL0033 N2 ON A.製令單別 = N2.製令單別 AND A.製令單號 = N2.製令單號 AND N2.加工別 = 'B'
	LEFT JOIN FIL0033 N3 ON A.製令單別 = N3.製令單別 AND A.製令單號 = N3.製令單號 AND N3.加工別 = 'C'
	LEFT JOIN FIL0033 N4 ON A.製令單別 = N4.製令單別 AND A.製令單號 = N4.製令單號 AND N4.加工別 = 'D'
WHERE
	B.稅別='A'
	);

-- Oracle user_views
CREATE VIEW "VIEWFIL4030_A" ("製令單別", "製令單號", "訂單單別", "訂單單號", "產品編號", "產品名稱", "產品規格", "客戶編號", "預交日", "客戶名稱", "公司代碼", "公司名稱", "類別", "成袋數", "成捲數", "製袋型態", "報價單號", "透氣孔", "流水編號") AS (                                                                                                                                                  
SELECT
	A.製令單別,
	A.製令單號,
	B.歸屬類別 訂單單別,
	B.歸屬編號 訂單單號,	
	A.產品編號,
	A.產品名稱,
	nvl(I1.規格, nvl(I2.規格, ' ')) 產品規格,
	B.廠客編號 客戶編號,
	B.匯率日期 預交日,
	nvl(H.全名, ' ') 客戶名稱,
	nvl(F.公司代碼, B.公司代碼) 公司代碼,
	nvl(M.名稱, ' ') 公司名稱,
	B.稅別 類別,
	A.成袋數,
	nvl(I3.成捲數,0) 成捲數,
	C.名稱 製袋型態,
	nvl(I4.說明一,' ') 報價單號,
	nvl(I4.數字一,0) 透氣孔,
	B.流水編號
FROM
	FIL0032 A
	INNER JOIN FIL0030 B ON A.製令單別 = B.單據類別 AND A.製令單號 = B.單據編號
	LEFT JOIN ViewFIL310D C ON C.代碼 = A.製袋型態
	LEFT JOIN FIL0030 F ON B.歸屬類別 = F.單據類別 AND B.歸屬編號 = F.單據編號
	LEFT JOIN FIL0011 H ON B.廠客編號 = H.編號
	LEFT JOIN FIL0012 I1 ON A.產品編號 = I1.產品編號
	LEFT JOIN FIL0012 I2 ON trim(REGEXP_SUBSTR(A.產品編號, '([^/]+)', 1,1)) = I2.產品編號
	/* 訂單公司別 */
	LEFT JOIN ViewFIL0011 M ON F.公司代碼 = M.代碼		
	LEFT JOIN FIL0033 I3 ON A.製令單別 = I3.製令單別 AND A.製令單號 = I3.製令單號 AND I3.加工別 = 'A'
	LEFT JOIN FIL0038 I4 ON A.製令單別 = I4.單別 AND A.製令單號 = I4.單號 
);

-- Oracle user_views
CREATE VIEW "VIEWFIL4030_B" ("製令單別", "製令單號", "訂單單別", "訂單單號", "產品編號", "產品名稱", "產品規格", "客戶編號", "預交日", "客戶名稱", "公司代碼", "公司名稱", "類別", "訂單成袋數", "訂單成捲數", "裁切捲數", "包裝捲數", "製袋數量", "製袋完成率", "裁切完成率", "包裝完成率", "達成率", "總入庫數", "作業日期", "流水編號") AS (                                                                                                                                                  
SELECT
	A.製令單別,
	A.製令單號,
	B.歸屬類別 訂單單別,
	B.歸屬編號 訂單單號,	
	A.產品編號,
	A.產品名稱,
	nvl(I1.規格, nvl(I2.規格, ' ')) 產品規格,
	B.廠客編號 客戶編號,
	B.匯率日期 預交日,
	nvl(H.全名, ' ') 客戶名稱,
	nvl(F.公司代碼, B.公司代碼) 公司代碼,
	nvl(M.名稱, ' ') 公司名稱,
	B.稅別 類別,
	A.成袋數 訂單成袋數,
	I3.成捲數 訂單成捲數,
	nvl(I4.捲數,0) 裁切捲數,
	nvl(I5.捲數,0) 包裝捲數,
	nvl(I6.數量,0) 製袋數量,
	case when A.成袋數=0 then 0 else nvl(I6.數量,0)/A.成袋數 end 製袋完成率,
	case when I3.成捲數=0 then 0 else nvl(I4.捲數,0)/I3.成捲數 end 裁切完成率,
	case when I3.成捲數=0 then 0 else nvl(I5.捲數,0)/I3.成捲數 end 包裝完成率,
	case when instr(A.產品編號,'R',1)>0 then 
		case when I3.成捲數=0 then 0 else nvl(I5.捲數,0)/I3.成捲數 end else
		case when A.成袋數=0 then 0 else nvl(I6.數量,0)/A.成袋數 end
		end 達成率,
	case when instr(A.產品編號,'R',1)>0 then 
		nvl(I5.捲數,0) else
		nvl(I6.數量,0) end  總入庫數,
	F.單據日期 作業日期,	
	B.流水編號
FROM
	FIL0032 A
	INNER JOIN FIL0030 B ON A.製令單別 = B.單據類別 AND A.製令單號 = B.單據編號
	LEFT JOIN FIL0030 F ON A.製令單別 = F.單據類別 AND A.製令單號 = F.單據編號
	LEFT JOIN FIL0011 H ON B.廠客編號 = H.編號
	LEFT JOIN FIL0012 I1 ON A.產品編號 = I1.產品編號
	LEFT JOIN FIL0012 I2 ON trim(REGEXP_SUBSTR(A.產品編號, '([^/]+)', 1,1)) = I2.產品編號
	/* 訂單公司別 */
	LEFT JOIN ViewFIL0011 M ON F.公司代碼 = M.代碼
	LEFT JOIN FIL0033 I3 ON A.製令單別 = I3.製令單別 AND A.製令單號 = I3.製令單號 AND I3.加工別 = 'A'
	LEFT JOIN ViewFIL2064 I4 ON A.製令單號 = I4.製令單號
	LEFT JOIN ViewFIL2065 I5 ON  A.製令單號 = I5.製令單號
	LEFT JOIN ViewFIL404E74 I6 ON A.製令單號 = I6.製令單號
);

-- Oracle user_views
CREATE VIEW "VIEWFIL4030_C" ("製令單別", "製令單號", "訂單單別", "訂單單號", "產品編號", "產品名稱", "產品規格", "客戶編號", "單據日期", "客戶名稱", "類別", "成袋數", "成捲數", "報價單號", "總體單價", "總價", "流水編號") AS (                                                                                                                                                  
SELECT
	A.製令單別,
	A.製令單號,
	B.歸屬類別 訂單單別,
	B.歸屬編號 訂單單號,	
	A.產品編號,
	A.產品名稱,
	nvl(I1.規格, nvl(I2.規格, ' ')) 產品規格,
	B.廠客編號 客戶編號,
	B.單據日期 單據日期,
	nvl(H.全名, ' ') 客戶名稱,
	B.稅別 類別,
	A.成袋數,
	I3.成捲數,
	NVL(I4.說明一,' ') 報價單號,
	NVL(I5.總體單價,0) 總體單價,
	NVL(I5.總體單價,0)* DECODE( A.成袋數,0,I3.成捲數,A.成袋數) 總價,
	B.流水編號
FROM
	FIL0032 A
	INNER JOIN FIL0030 B ON A.製令單別 = B.單據類別 AND A.製令單號 = B.單據編號
	LEFT JOIN FIL0030 F ON B.歸屬類別 = F.單據類別 AND B.歸屬編號 = F.單據編號
	LEFT JOIN FIL0011 H ON B.廠客編號 = H.編號
	LEFT JOIN FIL0012 I1 ON A.產品編號 = I1.產品編號
	LEFT JOIN FIL0012 I2 ON trim(REGEXP_SUBSTR(A.產品編號, '([^/]+)', 1,1)) = I2.產品編號
	/* 訂單公司別 */
	LEFT JOIN FIL0033 I3 ON A.製令單別 = I3.製令單別 AND A.製令單號 = I3.製令單號 AND I3.加工別 = 'A'
	INNER JOIN FIL0038 I4 ON B.流水編號 = I4.流水編號
    INNER JOIN ViewFIL4012 I5 ON I5.單號 = NVL(I4.說明一,' ')
);

-- Oracle user_views
CREATE VIEW "VIEWFIL4031" ("製令單別", "製令單號", "加工別", "序號", "色順") AS (                                                                                                                                                      
SELECT
	A.製令單別,
	A.製令單號,
	A.加工別,
	1 序號,
	A.印刷色順一	色順
FROM
	FIL0033 A
where
	A.印刷色順一 <> ' '	
	
UNION ALL

SELECT
	A.製令單別,
	A.製令單號,
	A.加工別,
	2 序號,
	A.印刷色順二	色順
FROM
	FIL0033 A	
where
	A.印刷色順二 <> ' '
	
UNION ALL

SELECT
	A.製令單別,
	A.製令單號,
	A.加工別,
	3 序號,
	A.印刷色順三	色順
FROM
	FIL0033 A		
where
	A.印刷色順三 <> ' '
	
UNION ALL

SELECT
	A.製令單別,
	A.製令單號,
	A.加工別,
	4 序號,
	A.印刷色順四	色順
FROM
	FIL0033 A		
where
	A.印刷色順四 <> ' '
	
UNION ALL

SELECT
	A.製令單別,
	A.製令單號,
	A.加工別,
	5 序號,
	A.印刷色順五	色順
FROM
	FIL0033 A		
where
	A.印刷色順五 <> ' '
	
UNION ALL

SELECT
	A.製令單別,
	A.製令單號,
	A.加工別,
	6 序號,
	A.印刷色順六	色順
FROM
	FIL0033 A
where
	A.印刷色順六 <> ' '
	
UNION ALL

SELECT
	A.製令單別,
	A.製令單號,
	A.加工別,
	7 序號,
	A.印刷色順七	色順
FROM
	FIL0033 A
where
	A.印刷色順七 <> ' '
	
UNION ALL

SELECT
	A.製令單別,
	A.製令單號,
	A.加工別,
	8 序號,
	A.印刷色順八	色順
FROM
	FIL0033 A	
		where
	A.印刷色順八 <> ' '
	
UNION ALL

SELECT
	A.製令單別,
	A.製令單號,
	A.加工別,
	9 序號,
	A.印刷色順九	色順
FROM
	FIL0033 A		
where
	A.印刷色順九 <> ' '
		
UNION ALL

SELECT
	A.製令單別,
	A.製令單號,
	A.加工別,
	10 序號,
	A.印刷色順十	色順
FROM
	FIL0033 A		
where
	A.印刷色順十 <> ' '
		
UNION ALL

SELECT
	A.製令單別,
	A.製令單號,
	A.加工別,
	11 序號,
	A.印刷色順十一	色順
FROM
	FIL0033 A		
where
	A.印刷色順十一 <> ' '	
	
UNION ALL

SELECT
	A.製令單別,
	A.製令單號,
	A.加工別,
	12 序號,
	A.印刷色順十二	色順
FROM
	FIL0033 A		
where
	A.印刷色順十二 <> ' '	
);

-- Oracle user_views
CREATE VIEW "VIEWFIL4032" ("製令單別", "製令單號", "加工別", "成捲數", "色順數") AS (
SELECT 
	F.製令單別, 
	F.製令單號, 
	F.加工別,
	F.成捲數,
	(
		decode(F.印刷色順一,' ',0,1)+
		decode(F.印刷色順二,' ',0,1)+
		decode(F.印刷色順三,' ',0,1)+
		decode(F.印刷色順四,' ',0,1)+
		decode(F.印刷色順五,' ',0,1)+
		decode(F.印刷色順六,' ',0,1)+
		decode(F.印刷色順七,' ',0,1)+
		decode(F.印刷色順八,' ',0,1)+
		decode(F.印刷色順九,' ',0,1)+
		decode(F.印刷色順十,' ',0,1)+
		decode(F.印刷色順十一,' ',0,1)+
		decode(F.印刷色順十二,' ',0,1)
	) 色順數
FROM 
	FIL0033 F 
WHERE 
	F.印刷基材<>' ' 
);

-- Oracle user_views
CREATE VIEW "VIEWFIL4033" ("製令單別", "製令單號", "材料序號", "膠水") AS (                                                                                                                                                      SELECT
	A.製令單別,
	A.製令單號,
	A.材料序號,
	listagg
	(	to_char
			(	trim(nvl(B.品名, A.代碼))
			), ',') within group (order by A.序號) as 膠水
FROM
	FIL0037 A
	LEFT JOIN FIL0012 B ON A.代碼 = B.產品編號
WHERE
	A.屬性 = '3'
GROUP BY
	A.製令單別,
	A.製令單號,
	A.材料序號);

-- Oracle user_views
CREATE VIEW "VIEWFIL4034" ("單別", "單號", "變更日期", "製令單別", "製令單號", "公司代碼", "公司名稱", "訂單單別", "訂單單號", "客戶編號", "客戶名稱", "產品編號", "產品名稱", "產品規格", "材質結構", "交貨數量", "交貨日期", "變更別_材料變更", "變更別_廠商", "變更別_廠商名稱", "變更別_規格變更", "變更別_其他變更", "變更別_製程變更", "變更別_單位_製程", "變更別_單位名稱_製程", "變更別_交期變更", "變更別_單位_交期", "變更別_單位名稱_交期", "變更事項", "變更原因", "主管意見", "主管批示", "知會單位_營業課", "知會單位_印刷課", "知會單位_加工課", "知會單位_會計課", "知會單位_總務課", "知會單位_積層課", "知會單位_製袋課", "知會單位_廠務課", "知會單位_其他單位", "知會單位_營業課_承辦人", "知會單位_印刷課_承辦人", "知會單位_加工課_承辦人", "知會單位_會計課_承辦人", "知會單位_總務課_承辦人", "知會單位_積層課_承辦人", "知會單位_製袋課_承辦人", "知會單位_廠務課_承辦人", "知會單位_其他單位_承辦人", "知會單位_營業課_承辦人姓名", "知會單位_印刷課_承辦人姓名", "知會單位_加工課_承辦人姓名", "知會單位_會計課_承辦人姓名", "知會單位_總務課_承辦人姓名", "知會單位_積層課_承辦人姓名", "知會單位_製袋課_承辦人姓名", "知會單位_廠務課_承辦人姓名", "知會單位_其他單位_承辦人姓名", "確認_營業課", "確認_印刷課", "確認_加工課", "確認_會計課", "確認_總務課", "確認_積層課", "確認_製袋課", "確認_廠務課", "確認_其他單位", "確認_營業課_承辦人", "確認_印刷課_承辦人", "確認_加工課_承辦人", "確認_會計課_承辦人", "確認_總務課_承辦人", "確認_積層課_承辦人", "確認_製袋課_承辦人", "確認_廠務課_承辦人", "確認_其他單位_承辦人", "確認_營業課_承辦人姓名", "確認_印刷課_承辦人姓名", "確認_加工課_承辦人姓名", "確認_會計課_承辦人姓名", "確認_總務課_承辦人姓名", "確認_積層課_承辦人姓名", "確認_製袋課_承辦人姓名", "確認_廠務課_承辦人姓名", "確認_其他單位_承辦人姓名", "簽核系統", "簽核系統_結案", "流水編號", "填表人", "填表人姓名", "填表日", "最後更新者", "更新者姓名", "最後更新日", "簽核狀態") AS (                                                                                                                                                      SELECT
	A.單別,
	A.單號,
	B.單據日期 變更日期,
	B.歸屬類別 製令單別,
	B.歸屬編號 製令單號,
	nvl(C.公司代碼, ' ') 公司代碼,
	nvl(C.公司名稱, ' ') 公司名稱,
	nvl(C.訂單單別, ' ') 訂單單別,
	nvl(C.訂單單號, ' ') 訂單單號,
	nvl(C.客戶編號, ' ') 客戶編號,
	nvl(C.客戶名稱, ' ') 客戶名稱,
	nvl(C.產品編號, ' ') 產品編號,
	nvl(C.產品名稱, ' ') 產品名稱,
	nvl(C.產品規格, ' ') 產品規格,
	nvl(C.材質結構, ' ') 材質結構,
	nvl(C.訂購數量, 0) 交貨數量,
	nvl(C.預交日, ' ') 交貨日期,
	A.變更別_材料變更,
	A.變更別_廠商,
	nvl(D.全名, ' ') 變更別_廠商名稱,
	A.變更別_規格變更,
	A.變更別_其他變更,
	A.變更別_製程變更,
	A.變更別_單位_製程,
	nvl(E.部門名稱, ' ') 變更別_單位名稱_製程,
	A.變更別_交期變更,
	A.變更別_單位_交期,
	nvl(F.部門名稱, ' ') 變更別_單位名稱_交期,
	A.變更事項,
	A.變更原因,
	A.主管意見,
	A.主管批示,
	A.知會單位_營業課,
	A.知會單位_印刷課,
	A.知會單位_加工課,
	A.知會單位_會計課,
	A.知會單位_總務課,
	A.知會單位_積層課,
	A.知會單位_製袋課,
	A.知會單位_廠務課,
	A.知會單位_其他單位,
	A.知會單位_營業課_承辦人,
	A.知會單位_印刷課_承辦人,
	A.知會單位_加工課_承辦人,
	A.知會單位_會計課_承辦人,
	A.知會單位_總務課_承辦人,
	A.知會單位_積層課_承辦人,
	A.知會單位_製袋課_承辦人,
	A.知會單位_廠務課_承辦人,
	A.知會單位_其他單位_承辦人,
	nvl(G.員工姓名, ' ') 知會單位_營業課_承辦人姓名,
	nvl(H.員工姓名, ' ') 知會單位_印刷課_承辦人姓名,
	nvl(I.員工姓名, ' ') 知會單位_加工課_承辦人姓名,
	nvl(J.員工姓名, ' ') 知會單位_會計課_承辦人姓名,
	nvl(K.員工姓名, ' ') 知會單位_總務課_承辦人姓名,
	nvl(L.員工姓名, ' ') 知會單位_積層課_承辦人姓名,
	nvl(M.員工姓名, ' ') 知會單位_製袋課_承辦人姓名,
	nvl(N.員工姓名, ' ') 知會單位_廠務課_承辦人姓名,
	nvl(O.員工姓名, ' ') 知會單位_其他單位_承辦人姓名,
	A.確認_營業課,
	A.確認_印刷課,
	A.確認_加工課,
	A.確認_會計課,
	A.確認_總務課,
	A.確認_積層課,
	A.確認_製袋課,
	A.確認_廠務課,
	A.確認_其他單位,
	A.確認_營業課_承辦人,
	A.確認_印刷課_承辦人,
	A.確認_加工課_承辦人,
	A.確認_會計課_承辦人,
	A.確認_總務課_承辦人,
	A.確認_積層課_承辦人,
	A.確認_製袋課_承辦人,
	A.確認_廠務課_承辦人,
	A.確認_其他單位_承辦人,
	nvl(P.員工姓名, ' ') 確認_營業課_承辦人姓名,
	nvl(Q.員工姓名, ' ') 確認_印刷課_承辦人姓名,
	nvl(R.員工姓名, ' ') 確認_加工課_承辦人姓名,
	nvl(S.員工姓名, ' ') 確認_會計課_承辦人姓名,
	nvl(T.員工姓名, ' ') 確認_總務課_承辦人姓名,
	nvl(U.員工姓名, ' ') 確認_積層課_承辦人姓名,
	nvl(V.員工姓名, ' ') 確認_製袋課_承辦人姓名,
	nvl(W.員工姓名, ' ') 確認_廠務課_承辦人姓名,
	nvl(X.員工姓名, ' ') 確認_其他單位_承辦人姓名,
	B.簽核系統, 
	B.簽核系統_結案,
	B.流水編號,
	B.填表人,
	nvl(Z1.員工姓名,' ') 填表人姓名, 
	B.填表日, 
	B.最後更新者,
	nvl(Z2.員工姓名,' ') 更新者姓名, 
	B.最後更新日,
	nvl(Z3.簽核狀態, '0') 簽核狀態
FROM
	FIL0035 A
	INNER JOIN FIL0030 B ON A.單別 = B.單據類別 AND A.單號 = B.單據編號
	/* 製令 */
	LEFT JOIN ViewFIL4030 C ON B.歸屬類別 = C.製令單別 AND B.歸屬編號 = C.製令單號
	LEFT JOIN FIL0010 Z1 ON B.填表人 = Z1.員工編號
	LEFT JOIN FIL0010 Z2 ON B.最後更新者 = Z2.員工編號
	LEFT JOIN ViewFIL0030 Z3 ON B.簽核系統 = Z3.簽核系統 AND B.單據編號 = Z3.單號
	LEFT JOIN FIL0011 D ON A.變更別_廠商 = D.編號
	LEFT JOIN FIL0020 E ON A.變更別_單位_製程 = E.部門編號
	LEFT JOIN FIL0020 F ON A.變更別_單位_交期 = F.部門編號
	LEFT JOIN FIL0010 G ON A.知會單位_營業課_承辦人 = G.員工編號
	LEFT JOIN FIL0010 H ON A.知會單位_印刷課_承辦人 = H.員工編號
	LEFT JOIN FIL0010 I ON A.知會單位_加工課_承辦人 = I.員工編號
	LEFT JOIN FIL0010 J ON A.知會單位_會計課_承辦人 = J.員工編號
	LEFT JOIN FIL0010 K ON A.知會單位_總務課_承辦人 = K.員工編號
	LEFT JOIN FIL0010 L ON A.知會單位_積層課_承辦人 = L.員工編號
	LEFT JOIN FIL0010 M ON A.知會單位_製袋課_承辦人 = M.員工編號
	LEFT JOIN FIL0010 N ON A.知會單位_廠務課_承辦人 = N.員工編號
	LEFT JOIN FIL0010 O ON A.知會單位_其他單位_承辦人 = O.員工編號
	LEFT JOIN FIL0010 P ON A.確認_營業課_承辦人 = P.員工編號
	LEFT JOIN FIL0010 Q ON A.確認_印刷課_承辦人 = Q.員工編號
	LEFT JOIN FIL0010 R ON A.確認_加工課_承辦人 = R.員工編號
	LEFT JOIN FIL0010 S ON A.確認_會計課_承辦人 = S.員工編號
	LEFT JOIN FIL0010 T ON A.確認_總務課_承辦人 = T.員工編號
	LEFT JOIN FIL0010 U ON A.確認_積層課_承辦人 = U.員工編號
	LEFT JOIN FIL0010 V ON A.確認_製袋課_承辦人 = V.員工編號
	LEFT JOIN FIL0010 W ON A.確認_廠務課_承辦人 = W.員工編號
	LEFT JOIN FIL0010 X ON A.確認_其他單位_承辦人 = X.員工編號);

-- Oracle user_views
CREATE VIEW "VIEWFIL4035" ("變更單別", "變更單號", "製令單別", "製令單號", "序號") AS (                                                                                                                                                      SELECT
	A.單據類別 變更單別,
	A.單據編號 變更單號,
	A.歸屬類別 製令單別,
	A.歸屬編號 製令單號,
	row_number() over (partition by A.歸屬編號 order by A.單據編號) 序號
FROM
	FIL0030 A
WHERE
	A.單據類別 = 'C21' AND
	A.歸屬類別 = 'C11');

-- Oracle user_views
CREATE VIEW "VIEWFIL4036" ("製令單別", "製令單號", "製造日期") AS (
SELECT
	A.歸屬類別 製令單別,
	A.歸屬編號 製令單號,
	MAX(A.單據日期) 製造日期
FROM
	FIL0030 A
	INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
WHERE
	A.單據類別 = 'C41' AND
	B.製程代碼 = 'C31E'
GROUP BY
	A.歸屬類別,
	A.歸屬編號);

-- Oracle user_views
CREATE VIEW "VIEWFIL403A" ("單別", "單號", "單據日期", "公司代碼", "公司名稱", "客戶名稱", "產品名稱", "指示單別", "接稿日期", "發版日期", "營業人員", "營業人員姓名", "設計製稿", "設計製稿姓名", "簽核系統", "流水編號", "填表人", "填表人姓名", "填表日", "最後更新者", "更新者姓名", "最後更新日", "簽核狀態") AS (                                                                                                                                                      SELECT
	A.單別,
	A.單號,
	B.單據日期,
	B.公司代碼,
	nvl(C.全名, ' ') 公司名稱,
	A.客戶說明 客戶名稱,
	A.產品說明 產品名稱,
	A.指示單別,
	A.接稿日期,
	A.發版日期,
	B.業務員 營業人員,
	nvl(D.員工姓名, ' ') 營業人員姓名,
	A.設計製稿,
	nvl(E.員工姓名, ' ') 設計製稿姓名,
	B.簽核系統, 
	B.流水編號,
	B.填表人,
	nvl(Z1.員工姓名,' ') 填表人姓名, 
	B.填表日, 
	B.最後更新者,
	nvl(Z2.員工姓名,' ') 更新者姓名, 
	B.最後更新日,
	nvl(Z3.簽核狀態, '0') 簽核狀態
FROM
	FIL0036 A
	INNER JOIN FIL0030 B ON A.單別 = B.單據類別 AND A.單號 = B.單據編號
	LEFT JOIN ViewFIL0011 C ON B.公司代碼 = C.代碼
	LEFT JOIN FIL0010 D ON B.業務員 = D.員工編號
	LEFT JOIN FIL0010 E ON A.設計製稿 = E.員工編號
	LEFT JOIN FIL0010 Z1 ON B.填表人 = Z1.員工編號
	LEFT JOIN FIL0010 Z2 ON B.最後更新者 = Z2.員工編號
	LEFT JOIN ViewFIL0030 Z3 ON B.簽核系統 = Z3.簽核系統 AND B.單據編號 = Z3.單號);

-- Oracle user_views
CREATE VIEW "VIEWFIL403A1" ("製令單別", "製令單號", "加工類別", "材料序號", "用料", "排在基材前面塑膠料", "塑料排在用料前面") AS (
select 
		A.製令單別, 
		A.製令單號, 
		A.加工類別,
		A.材料序號,
		to_nchar(decode(A.組合材質結構,1,'■',0,'/')||trim(decode(nvl(B.品名, ' '),' ',N' ',trim(nvl(B.品名, ' '))||trim(nvl(B.規格,' '))) || decode(A.材料說明,' ',N' ','(' || trim(A.材料說明) || ')')) ||
			trim(decode(A.排在基材前面,1,N' ',decode(nvl(C.品名, ' '),' ',N' ','_' || trim(decode(nvl(C.品名, ' '),' ',N' ','淋')||nvl(C.品名, ' '))||' '||trim(nvl(A.厚度,' ')||decode(nvl(A.厚度,' '),' ',N' ','μ'))) || decode(A.塑膠粒說明,' ',N' ','(' || trim(A.塑膠粒說明) || ')')))) 
			用料,
		to_nchar(trim(decode(A.排在基材前面,0,N' ',decode(nvl(C.品名, ' '),' ',N' ',trim(decode(nvl(C.品名, ' '),' ',N' ','淋')||nvl(C.品名, ' '))||' '||trim(nvl(A.厚度,' ')||decode(nvl(A.厚度,' '),' ',N' ','μ'))) || decode(A.塑膠粒說明,' ',N' ','(' || trim(A.塑膠粒說明) || ')')))
			) 排在基材前面塑膠料,
		to_nchar(trim(decode(A.排在材料前面,0,decode(A.組合材質結構,1,'■',0,'/')||trim(decode(nvl(B.品名, ' '),' ',N' ',trim(nvl(B.品名, ' '))||trim(nvl(B.規格,' '))) || decode(A.材料說明,' ',N' ','(' || trim(A.材料說明) || ')')) ||
			trim(decode(A.排在基材前面,1,N' ',decode(nvl(C.品名, ' '),' ',N' ','_' || trim(decode(nvl(C.品名, ' '),' ',N' ','淋')||nvl(C.品名, ' '))||' '||trim(nvl(A.厚度,' ')||decode(nvl(A.厚度,' '),' ',N' ','μ'))) || decode(A.塑膠粒說明,' ',N' ','(' || trim(A.塑膠粒說明) || ')'))),
			decode(A.組合材質結構,1,'■',0,'/')
			||trim(decode(nvl(C.品名, ' '),' ',' ','淋')||nvl(C.品名, ' '))
			||' '
			||trim(nvl(A.厚度,' ')||decode(nvl(A.厚度,' '),' ',N' ','μ'))
			||decode(A.塑膠粒說明,' ',N' ','(' || trim(A.塑膠粒說明) || ')')
			||trim(decode(nvl(C.品名, ' '),' ',N' ','/'))||trim(decode(nvl(B.品名, ' '),' ',N' ',trim(nvl(B.品名, ' '))||trim(nvl(B.規格,' '))) || decode(A.材料說明,' ',N' ','(' || trim(A.材料說明) || ')'))))
			) 塑料排在用料前面
from  
		FIL0034 A
		LEFT JOIN FIL0012 B ON A.材料代碼 = B.產品編號
		LEFT JOIN FIL0012 C ON A.塑膠粒材料代碼 = C.產品編號
);

-- Oracle user_views
CREATE VIEW "VIEWFIL403B" ("製令單別", "製令單號", "加工類別", "基材", "用料", "排在基材前面塑膠料", "塑料排在用料前面") AS (
select 
	A.製令單別, 
	A.製令單號, 
	A.加工別,
	trim(decode(nvl(E.品名,' '),' ',' ',trim(nvl(E.品名, ' '))||' '||trim(nvl(E.規格,' '))) || decode(A.數位印刷,0,' ','(' ||'數位水墨印製後裁修'||trim(to_char(A.印製後裁修,'999'))|| ')') || decode(A.基材投入說明,' ',' ','(' || trim(A.基材投入說明)|| ')')) 基材,
	NVL(B.用料,' ') 用料,
	NVL(B.排在基材前面塑膠料,' ') 排在基材前面塑膠料,
	NVL(B.塑料排在用料前面,' ') 塑料排在用料前面
from
	FIL0033 A
	LEFT JOIN FIL0012 E ON A.印刷基材 = E.產品編號
	LEFT JOIN
	(select 
		A.製令單別, 
		A.製令單號, 
		A.加工類別,
		listagg(
			decode(A.組合材質結構,1,'■',0,'/')||trim(decode(nvl(B.品名, ' '),' ',' ',trim(nvl(B.品名, ' '))||trim(nvl(B.規格,' '))) || decode(A.材料說明,' ',' ','(' || trim(A.材料說明) || ')')) ||
			trim(decode(A.排在基材前面,1,' ',decode(nvl(C.品名, ' '),' ',' ','_' || trim(decode(nvl(C.品名, ' '),' ',' ','淋')||nvl(C.品名, ' '))||' '||trim(nvl(A.厚度,' ')||decode(nvl(A.厚度,' '),' ',' ','μ'))) || decode(A.塑膠粒說明,' ',' ','(' || trim(A.塑膠粒說明) || ')'))) ,'')
			within GROUP (order by A.材料序號) 用料,
		listagg(
			trim(decode(A.排在基材前面,0,' ',decode(nvl(C.品名, ' '),' ',' ',trim(decode(nvl(C.品名, ' '),' ',' ','淋')||nvl(C.品名, ' '))||' '||trim(nvl(A.厚度,' ')||decode(nvl(A.厚度,' '),' ',' ','μ'))) || decode(A.塑膠粒說明,' ',' ','(' || trim(A.塑膠粒說明) || ')'))) ,'')
			within GROUP (order by A.材料序號) 排在基材前面塑膠料,
		listagg(trim(decode(A.排在材料前面,0,decode(A.組合材質結構,1,'■',0,'/')||trim(decode(nvl(B.品名, ' '),' ',' ',trim(nvl(B.品名, ' '))||trim(nvl(B.規格,' '))) || decode(A.材料說明,' ',' ','(' || trim(A.材料說明) || ')')) ||
			trim(decode(A.排在基材前面,1,' ',decode(nvl(C.品名, ' '),' ',' ','_' || trim(decode(nvl(C.品名, ' '),' ',' ','淋')||nvl(C.品名, ' '))||' '||trim(nvl(A.厚度,' ')||decode(nvl(A.厚度,' '),' ',' ','μ'))) || decode(A.塑膠粒說明,' ',' ','(' || trim(A.塑膠粒說明) || ')'))),
			decode(A.組合材質結構,1,'■',0,'/')
			||trim(decode(nvl(C.品名, ' '),' ',' ','淋')||nvl(C.品名, ' '))
			||' '
			||trim(nvl(A.厚度,' ')||decode(nvl(A.厚度,' '),' ',' ','μ'))
			||decode(A.塑膠粒說明,' ',' ','(' || trim(A.塑膠粒說明) || ')')
			||trim(decode(nvl(C.品名, ' '),' ',' ','/'))||trim(decode(nvl(B.品名, ' '),' ',' ',trim(nvl(B.品名, ' '))||trim(nvl(B.規格,' '))) || decode(A.材料說明,' ',' ','(' || trim(A.材料說明) || ')')))),' ')
			within GROUP (order by A.材料序號) 塑料排在用料前面
			from  
		FIL0034 A
		LEFT JOIN FIL0012 B ON A.材料代碼 = B.產品編號
		LEFT JOIN FIL0012 C ON A.塑膠粒材料代碼 = C.產品編號

	GROUP BY  
		A.製令單別,
		A.製令單號,
		A.加工類別
	) B ON  A.製令單別=B.製令單別 AND A.製令單號=B.製令單號 AND A.加工別=B.加工類別	
);

-- Oracle user_views
CREATE VIEW "VIEWFIL4040" ("單別", "單號", "排程日期", "註記代碼", "註記", "回收", "訂單單別", "訂單單號", "製令單別", "製令單號", "加工別", "公司代碼", "公司名稱", "簽核系統", "簽核狀態", "序號", "製程代碼", "製程名稱", "工站代碼", "工站名稱", "機台代碼", "機台名稱", "數量", "單位", "產品編號", "產品名稱", "產品規格", "客戶編號", "預計交期", "客戶名稱", "作業人員", "作業員姓名", "材料品名規格", "膠水品名規格", "塑膠粒品名規格", "校色人", "作業順序", "作業順序2", "作業順序3", "色數", "光霧面", "積層模式", "成捲製袋", "待確認人", "看色人員", "成捲數", "成捲數正負差", "成捲差異比", "裁切方向", "作業者1", "作業者2", "作業者3", "送貨地址", "電話", "前置單號", "版銅已處理", "製袋型態", "備註", "材料編號一", "材料編號二", "流水編號", "填表人", "填表人姓名", "填表日", "最後更新者", "更新者姓名", "最後更新日") AS (                                                                                                                                               SELECT
	A.單據類別 單別,
	A.單據編號 單號,
	A.單據日期 排程日期,
	A.歸屬序號 註記代碼,
	decode(A.歸屬序號,139,'插件',144,'重要',138,'暫停',' ') 註記,
	A.邏輯值一 回收,
	'B31' 訂單單別,
	A.訂單號碼 訂單單號,
	A.歸屬類別 製令單別,
	A.歸屬編號 製令單號,
	A.稅別 加工別,
	A.公司代碼,
	nvl(I.名稱, ' ') 公司名稱,
	A.簽核系統,
	nvl(Z3.簽核狀態, '0') 簽核狀態,
	B.聯絡人序號 序號,
	B.製程代碼,
	nvl(C.名稱, ' ') 製程名稱,
	B.工站代碼,
	nvl(D.名稱, ' ') 工站名稱,	
	B.機台代碼,
	nvl(E.名稱, ' ') 機台名稱,
	B.數量,
	B.材積單位 單位,
	F.產品編號,
	B.文字4 產品名稱,
	nvl(H.規格, ' ') 產品規格,
	NVL(G.廠客編號,' ') 客戶編號,
	NVL(G.匯率日期,'00000000') 預計交期,
	nvl(J.全名, ' ') 客戶名稱,
	A.業務員 作業人員,
	nvl(K.員工姓名, ' ') 作業員姓名,
	B.文字1 材料品名規格,
	B.文字2 膠水品名規格,
	B.文字3 塑膠粒品名規格,
	B.文數字4 校色人,
	B.數值1 作業順序,
	B.數值3 作業順序2,
	B.數值4 作業順序3,
	B.數值2 色數,
	B.文字5 光霧面,
	decode(B.交貨日期_次批, '1', '四合一', '2', '三合一', ' ') 積層模式,
	decode(B.付款方式, '1', '成捲品', '2', '製袋品', ' ') 成捲製袋,
	nvl(M.員工姓名, ' ') 待確認人,
	decode(nvl(M2.全名, ' '),' ',nvl(M1.員工姓名, ' '),nvl(M2.全名, ' ')) 看色人員,
	nvl(L.成捲數,0) 成捲數,
	nvl(L.成捲數正負差,0) 成捲數正負差,
	nvl(L.成捲差異比,0) 成捲差異比,
	nvl(N.名稱,' ') 裁切方向,
	nvl(O.員工姓名,' ') 作業者1, 
	nvl(P.員工姓名,' ') 作業者2, 
	nvl(Q.員工姓名,' ') 作業者3, 
	B.價格條件 送貨地址,
	B.文數字5 電話,
	F.前置單號,
	B.Logical1 版銅已處理,
	F.製袋型態,
	A.備註,
	B.材料編號一,
	B.材料編號二,
	A.流水編號,
	A.填表人,
	nvl(Z1.員工姓名,' ') 填表人姓名, 
	A.填表日, 
	A.最後更新者,
	nvl(Z2.員工姓名,' ') 更新者姓名, 
	A.最後更新日
FROM
	FIL0030 A
	INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
	LEFT JOIN ViewFIL310N C ON B.製程代碼 = C.代碼
	LEFT JOIN ViewFIL310O D ON B.工站代碼 = D.代碼
	LEFT JOIN ViewFIL310P E ON B.機台代碼 = E.代碼
	LEFT JOIN FIL0032 F ON A.歸屬類別 = F.製令單別 AND A.歸屬編號 = F.製令單號
	LEFT JOIN FIL0030 G ON A.歸屬類別 = G.單據類別 AND A.歸屬編號 = G.單據編號
	LEFT JOIN FIL0012 H ON F.產品編號 = H.產品編號
	LEFT JOIN ViewFIL0011 I ON A.公司代碼 = I.代碼
	LEFT JOIN FIL0011 J ON G.廠客編號 = J.編號
	LEFT JOIN FIL0010 K ON A.業務員 = K.員工編號
	LEFT JOIN FIL0033 L ON A.歸屬類別 = L.製令單別 AND A.歸屬編號 = L.製令單號 AND decode(A.稅別,' ','A',A.稅別) = L.加工別
	LEFT JOIN FIL0010 M ON L.鋁箔貼合面_待確認人 = M.員工編號
	LEFT JOIN FIL0010 M1 ON L.看色人員編號 = M.員工編號
	LEFT JOIN FIL0011 M2 ON L.看色人員編號 = M.員工編號
	LEFT JOIN ViewFIL310X N ON L.裁切方向 = N.代碼
	LEFT JOIN FIL0010 O ON B.文數字1 = O.員工編號
	LEFT JOIN FIL0010 P ON B.文數字2 = P.員工編號
	LEFT JOIN FIL0010 Q ON B.文數字3 = Q.員工編號
	LEFT JOIN FIL0010 Z1 ON A.填表人 = Z1.員工編號
	LEFT JOIN FIL0010 Z2 ON A.最後更新者 = Z2.員工編號
	LEFT JOIN ViewOfObjProperties Z3 ON A.流水編號 = Z3.單據流水號
WHERE
	A.單據類別= 'C31');

-- Oracle user_views
CREATE VIEW "VIEWFIL4040M" ("單別", "單號", "製程代碼", "機台代碼", "機台名稱", "排程日期", "作業順序", "序號") AS (
SELECT DISTINCT
	A.單據類別 單別,
	A.單據編號 單號,
	B.製程代碼,
	B.機台代碼,
	NVL(E.名稱,' ') 機台名稱,
	A.單據日期 排程日期,
	B.數值1 作業順序,
	B.聯絡人序號 序號
FROM 
	FIL0030 A
	INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
	LEFT JOIN ViewFIL310P E ON B.機台代碼 = E.代碼
WHERE
	A.單據類別= 'C31'	

UNION 

SELECT DISTINCT 
	A.製令單別 單別,
	A.製令單號 單號,
	B.製程代碼,
	A.製令單別 機台代碼,
	NVL(B.名稱,' ') 機台名稱,	
	A.製令單號 排程日期,
	0 作業順序,
	0 序號
FROM 
	FIL0037 A
	INNER JOIN ViewFIL310P B ON A.製令單別 = B.代碼 
);

-- Oracle user_views
CREATE VIEW "VIEWFIL4040S" ("製令單別", "製令單號", "加工別", "加工別名稱", "排程日期", "製程代碼", "機台代碼", "製程名稱", "機台名稱", "排程數量", "生產數量", "色順數") AS ( 
SELECT
	A.製令單別,
	A.製令單號,
	A.加工別,
	decode(A.加工別,'A','A材','B','B材','C','底邊','D','A側','E','B側',' ') 加工別名稱,
	A.排程日期,
	A.製程代碼,
	A.機台代碼,
	nvl(C.名稱, ' ') 製程名稱,
	nvl(E.名稱, ' ') 機台名稱,
	A.數量 排程數量,
	nvl(B.數量,0) 生產數量,
	(decode(nvl(F.印刷色順一,' '),' ',0,1)
	+decode(nvl(F.印刷色順二,' '),' ',0,1)
	+decode(nvl(F.印刷色順三,' '),' ',0,1)
	+decode(nvl(F.印刷色順四,' '),' ',0,1)
	+decode(nvl(F.印刷色順五,' '),' ',0,1)
	+decode(nvl(F.印刷色順六,' '),' ',0,1)
	+decode(nvl(F.印刷色順七,' '),' ',0,1)
	+decode(nvl(F.印刷色順八,' '),' ',0,1)
	+decode(nvl(F.印刷色順九,' '),' ',0,1)
	+decode(nvl(F.印刷色順十,' '),' ',0,1)) 色順數
FROM 
	ViewFIL4041B A
	LEFT JOIN ViewFIL404CC B ON A.製令單別 = B.製令單別 AND A.製令單號 = B.製令單號 AND A.加工別 = B.加工別 AND A.排程日期 = B.作業日期 AND A.製程代碼 = B.製程代碼 AND A.機台代碼 = B.機台代碼
	LEFT JOIN ViewFIL310N C ON A.製程代碼 = C.代碼
	LEFT JOIN ViewFIL310P E ON A.機台代碼 = E.代碼
	LEFT JOIN FIL0033 F ON A.製令單別 = F.製令單別 AND A.製令單號 = F.製令單號 AND A.加工別 = F.加工別
	);

-- Oracle user_views
CREATE VIEW "VIEWFIL4041" ("製令單別", "製令單號", "排程日期", "製程代碼", "機台代碼", "數量") AS (                                                                                                                                               SELECT
	A.歸屬類別 製令單別,
	A.歸屬編號 製令單號,
	A.單據日期 排程日期,
	B.製程代碼,
	B.機台代碼,
	sum(B.數量) 數量
FROM
	FIL0030 A
	INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
WHERE
	A.單據類別= 'C31'
GROUP BY
	A.歸屬類別,
	A.歸屬編號,
	A.單據日期,
	B.製程代碼,
	B.機台代碼);

-- Oracle user_views
CREATE VIEW "VIEWFIL4041A" ("製令單別", "製令單號", "製程代碼", "數量") AS (                                                                                                                                               SELECT
	A.歸屬類別 製令單別,
	A.歸屬編號 製令單號,
	B.製程代碼,
	sum(B.數量) 數量
FROM
	FIL0030 A
	INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
WHERE
	A.單據類別= 'C31'
GROUP BY
	A.歸屬類別,
	A.歸屬編號,
	B.製程代碼);

-- Oracle user_views
CREATE VIEW "VIEWFIL4041B" ("製令單別", "製令單號", "加工別", "排程日期", "製程代碼", "機台代碼", "數量") AS (                                                                                                                                               SELECT
	A.歸屬類別 製令單別,
	A.歸屬編號 製令單號,
	A.稅別 加工別,
	A.單據日期 排程日期,
	B.製程代碼,
	B.機台代碼,
	sum(B.數量*1000) 數量
FROM
	FIL0030 A
	INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
WHERE
	A.單據類別= 'C31'
GROUP BY
	A.歸屬類別,
	A.歸屬編號,
	A.稅別,
	A.單據日期,
	B.製程代碼,
	B.機台代碼);

-- Oracle user_views
CREATE VIEW "VIEWFIL4041C" ("製令單別", "製令單號", "加工別", "製程代碼", "數量") AS (                                                                                                                                               SELECT
	A.歸屬類別 製令單別,
	A.歸屬編號 製令單號,
	A.稅別 加工別,
	B.製程代碼,
	sum(B.數量*1000) 數量
FROM
	FIL0030 A
	INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
WHERE
	A.單據類別= 'C31'
GROUP BY
	A.歸屬類別,
	A.歸屬編號,
	A.稅別,
	B.製程代碼);

-- Oracle user_views
CREATE VIEW "VIEWFIL4042" ("製令單號", "節點", "製程代碼", "AB底側", "AB底側二", "AB底側三", "AB底側四", "使用半成品", "使用半成品二", "使用半成品三", "使用半成品四", "物料編號", "物料編號二", "物料編號三", "物料編號四", "工作代碼", "預計投產日", "實際投產日", "名稱", "父節點", "說明", "半成品名稱") AS ( 
SELECT 	M.製令單號,
	M.節點,
	M.製程代碼,
	M.AB底側,
	M.AB底側二,
	M.AB底側三,
	M.AB底側四,
	M.使用半成品,
	M.使用半成品二,
	M.使用半成品三,
	M.使用半成品四,
	M.物料編號,
	M.物料編號二,
	M.物料編號三,
	M.物料編號四,
	M.工作代碼,
	M.預計投產日,
	M.實際投產日,
	REPLACE(decode(M.製程代碼,'C32A','燙金','C32B','數位噴墨','C32C','品檢','C32D','上臘',nvl(trim(A.名稱),' '))
	||replace(trim(TRIM(M.AB底側)||TRIM(M.AB底側二)||TRIM(M.AB底側三)||TRIM(M.AB底側四)),'()','')||'半成品'||
	DECODE(NVL(B.名稱,' '),' ','','#')||nvl(trim(B.名稱),' ')
	||replace(M.預計投產日,'00000000','')
	||rtrim(' '||trim(decode(nvl(trim(C.名稱),' '),' ',' ','＠'||nvl(trim(C.名稱無代碼),' ')))),'A材B材','AB材') as 名稱,
	M.父節點,
	M.說明,
	M.半成品名稱
From 
	FIL0039 M
	LEFT JOIN ViewFil310N A ON M.製程代碼 = A.代碼
	LEFT JOIN ViewFil310T B ON M.工作代碼 = B.代碼
	LEFT JOIN ViewFil310P C ON M.機台代碼 = C.代碼);

-- Oracle user_views
CREATE VIEW "VIEWFIL4043" ("製令單別", "製令單號", "加工類別", "材料代碼") AS SELECT
	A.製令單別,
	A.製令單號,
	A.加工類別,
	LISTAGG (A.材料代碼, ',') WITHIN GROUP (ORDER BY 材料代碼) AS 材料代碼
FROM
	FIL0034 A
WHERE
	A.材料代碼 <> ' '
GROUP BY
	A.製令單別,
	A.製令單號,
	A.加工類別;

-- Oracle user_views
CREATE VIEW "VIEWFIL4044" ("製令單號", "名稱", "名稱二", "節點") AS ( 
SELECT 	M.製令單號,
	TO_NCHAR('A材') as 名稱,
	TO_NCHAR('A材') as 名稱二,
	' ' 節點
From 
	ViewFil4030 M

UNION ALL

SELECT 	M.製令單號,
	TO_NCHAR('B材') as 名稱,
	TO_NCHAR('B材') as 名稱二,
	' ' 節點
From 
	ViewFil4030 M

UNION ALL

SELECT 	M.製令單號,
	TO_NCHAR('底材') as 名稱,
	TO_NCHAR('底材') as 名稱二,
	' ' 節點
From 
	ViewFil4030 M

UNION ALL

SELECT 	M.製令單號,
	TO_NCHAR('A側') as 名稱,
	TO_NCHAR('A側') as 名稱二,
	' ' 節點
From 
	ViewFil4030 M

UNION ALL

SELECT 	M.製令單號,
	TO_NCHAR('B側') as 名稱,
	TO_NCHAR('B側') as 名稱二,
	' ' 節點
From 
	ViewFil4030 M	
);

-- Oracle user_views
CREATE VIEW "VIEWFIL4045" ("製程代碼", "預計投產日", "製令單號") AS ( 
select 
	FIL0039.製程代碼, 
	FIL0039.預計投產日,
	listagg(FIL0039.製令單號, ',') within group (order by  FIL0039.製程代碼, FIL0039.預計投產日)
from 
	FIL0039 
WHERE	FIL0039.預計投產日 > '00000000'	
group by 
	FIL0039.製程代碼, FIL0039.預計投產日
);

-- Oracle user_views
CREATE VIEW "VIEWFIL4046" ("用途", "製令單別", "製令單號", "加工類別", "材料序號", "材料代碼", "材料名稱") AS ( 
SELECT 	'印刷基材',
	A.製令單別,
	A.製令單號,
	DECODE(A.加工別,'A','A.A材','B','B.B材','C','C.底邊','D','D.A側','E','E.B側',' '),
	0,
	A.印刷基材,
	B.品名||' '||B.規格
FROM FIL0033 A,FIL0012 B 
WHERE A.印刷基材<>' ' AND A.印刷基材=B.產品編號

UNION ALL 

SELECT	'淋膜積層材料',
	A.製令單別,
	A.製令單號,
	DECODE(A.加工類別,'A','A.A材','B','B.B材','C','C.底邊','D.A側','E','E.B側',' '),
	A.材料序號,
	A.材料代碼,
	B.品名||' '||B.規格
FROM FIL0034 A,FIL0012 B 
WHERE 	A.材料代碼<>' ' AND A.材料代碼=B.產品編號

UNION ALL 

SELECT 	'淋膜積層膠水', 
	A.製令單別,
	A.製令單號,
	DECODE(A.加工類別,'A','A.A材','B','B.B材','C','C.底邊','D.A側','E','E.B側',' '),
	A.材料序號,
	A.膠水材料代碼,
	B.品名
FROM FIL0034 A,FIL0012 B 
WHERE 	A.膠水材料代碼<>' ' AND A.膠水材料代碼=B.產品編號

UNION ALL 

SELECT 	'淋膜積層塑膠粒', 
	A.製令單別,
	A.製令單號,
	DECODE(A.加工類別,'A','A.A材','B','B.B材','C','C.底邊','D.A側','E','E.B側',' '),
	A.材料序號,
	A.塑膠粒材料代碼,
	B.品名||' '||A.厚度||'μ'
FROM FIL0034 A,FIL0012 B 
WHERE 	A.塑膠粒材料代碼<>' ' AND A.塑膠粒材料代碼=B.產品編號

UNION ALL 

SELECT 	'上臘',
	A.製令單別,
	A.製令單號,
	DECODE(A.加工別,'A','A.A材','B','B.B材','C','C.底邊','D.A側','E','E.B側',' '),
	0,
	A.上臘材料編號,
	B.品名
FROM FIL0033 A,FIL0012 B 
WHERE	A.上臘材料編號<>' '

UNION ALL 

SELECT 	'紙箱',
	A.製令單別,
	A.製令單號,
	DECODE(A.加工別,'A','A.A材','B','B.B材','C','C.底邊','D.A側','E','E.B側',' '),
	0,
	A.紙箱代碼,
	B.品名||' '||B.規格
FROM FIL0033 A,FIL0012 B 
WHERE	A.紙箱代碼<>' ' AND A.紙箱代碼=B.產品編號

UNION ALL 

SELECT 	'夾鍊',
	A.製令單別,
	A.製令單號,
	'主檔',
	0,
	A.加工項目_夾鍊代碼,
	B.品名||' '||B.規格
FROM FIL0032 A,FIL0012 B 
WHERE	A.加工項目_夾鍊代碼<>' ' AND A.加工項目_夾鍊代碼=B.產品編號

UNION ALL 

SELECT 	'氣閥',
	A.製令單別,
	A.製令單號,
	'主檔',
	0,
	A.加工項目_氣閥代碼,
	B.品名||' '||B.規格
FROM FIL0032 A,FIL0012 B 
WHERE	A.加工項目_氣閥代碼<>' ' AND A.加工項目_氣閥代碼=B.產品編號

UNION ALL 

SELECT 	'鐵條',
	A.製令單別,
	A.製令單號,
	'主檔',
	0,
	A.加工項目_鐵條代碼,
	B.品名||' '||B.規格
FROM FIL0032 A,FIL0012 B 
WHERE	A.加工項目_鐵條代碼<>' ' AND A.加工項目_鐵條代碼=B.產品編號

UNION ALL 

SELECT 	'無氣閥紙箱',
	A.製令單別,
	A.製令單號,
	'主檔',
	0,
	A.紙箱代碼,
	B.品名||' '||B.規格
FROM FIL0032 A,FIL0012 B 
WHERE	A.紙箱代碼<>' ' AND A.紙箱代碼=B.產品編號

UNION ALL 

SELECT 	'氣閥紙箱',
	A.製令單別,
	A.製令單號,
	'主檔',
	0,
	A.紙箱代碼_氣閥,
	B.品名||' '||B.規格
FROM FIL0032 A,FIL0012 B 
WHERE	A.紙箱代碼_氣閥<>' ' AND A.紙箱代碼=B.產品編號
);

-- Oracle user_views
CREATE VIEW "VIEWFIL4047" ("製令單別", "製令單號", "節點", "半成品名稱", "材料") AS SELECT 
	'C11' 單據類別,
	A.製令單號 單據編號,
	A.節點,
	A.半成品名稱,
	TRIM(TRIM(REPLACE(DECODE(A.使用半成品,' ',' ',A.使用半成品)||
			     DECODE(A.使用半成品二,' ',' ','/')||DECODE(A.使用半成品二,' ',' ',A.使用半成品二)||
			     DECODE(A.使用半成品三,' ',' ','/')||DECODE(A.使用半成品三,' ',' ',A.使用半成品三)||
			     DECODE(A.使用半成品四,' ',' ','/')||DECODE(A.使用半成品四,' ',' ',A.使用半成品四),'A材B材','AB材'))
				 ||DECODE(A.使用半成品,' ',' ','/')
	||DECODE(NVL(B.材料名稱,' '),' ',' ',NVL(B.材料名稱,' '))
	||DECODE(NVL(C.材料名稱,' '),' ',' ','/')||DECODE(NVL(C.材料名稱,' '),' ',' ',NVL(C.材料名稱,' '))
	||DECODE(NVL(D.材料名稱,' '),' ',' ','/')||DECODE(NVL(D.材料名稱,' '),' ',' ',NVL(D.材料名稱,' '))
	||DECODE(NVL(E.材料名稱,' '),' ',' ','/')||DECODE(NVL(E.材料名稱,' '),' ',' ',NVL(E.材料名稱,' ')))
FROM
	FIL0039 A
	LEFT JOIN ViewFIL4046 B ON   A.物料編號=B.材料代碼 AND A.製令單號=B.製令單號
	LEFT JOIN ViewFIL4046 C ON A.物料編號二=C.材料代碼 AND A.製令單號=C.製令單號
	LEFT JOIN ViewFIL4046 D ON A.物料編號三=D.材料代碼 AND A.製令單號=D.製令單號
	LEFT JOIN ViewFIL4046 E ON A.物料編號四=E.材料代碼 AND A.製令單號=E.製令單號;

-- Oracle user_views
CREATE VIEW "VIEWFIL4048" ("製令單別", "製令單號", "加工別", "色順產品編號") AS SELECT  
	A.單據類別,
	A.單據編號,
	A.加工別,
	LISTAGG (to_char(A.色順)||'：'||to_char(A.產品編號)||decode(A.母版色順代碼,' ',' ',to_char('('||A.母版色順代碼||')')), '，') WITHIN GROUP (ORDER BY A.色順) AS 色順產品編號
FROM	FIL003C A
	INNER JOIN FIL0012 B ON A.產品編號=B.產品編號 
Where 
	A.產品編號<>' '
GROUP BY A.單據類別, A.單據編號, A.加工別
ORDER BY A.單據類別, A.單據編號, A.加工別;

-- Oracle user_views
CREATE VIEW "VIEWFIL4048A" ("單據類別", "單據編號", "類別", "序號", "類別名稱") AS Select 
	單據類別,
	單據編號,
	類別,
	單據序號 序號,
	decode(類別,'A1','A1:TRICOR BRAUN(客製品)','A2','A2:TRICOR BRAUN(公版品)','A3','A3:TRICOR BRAUN(客製品_加)','A4','A4:TRICOR BRAUN(公版品_加)','B1','B1:The Bag Broker EU','B2','B2:The Bag Broker EU 可分解','B3','B3:The Bag Broker UK','B4','B4:Bag Broker UK 可分解','C1','C1:The Packaging People','C2','C2:The Packing People 可分解','D1','D1:喜美標籤','D2','D2:盤商標籤','E1','E1：祥龍,F1：永恆包裝(TBB-其他)
','F1','F1：永恆包裝(TBB-其他)',' ') 類別名稱
from 
	FIL003F;

-- Oracle user_views
CREATE VIEW "VIEWFIL4048A1" ("製令單別", "製令單號", "序號", "類別", "類別名稱", "無氣閥無鐵條編號", "品名規格", "產品編號品名規格") AS Select 
	A.單據類別 製令單別,
	A.單據編號 製令單號,
	A.單據序號 序號,
	A.類別,
	decode(A.類別,'A1','A1:TRICOR BRAUN(客製品)','A2','A2:TRICOR BRAUN(公版品)','A3','A3:TRICOR BRAUN(客製品_加)','A4','A4:TRICOR BRAUN(公版品_加)','B1','B1:The Bag Broker EU','B2','B2:The Bag Broker EU 可分解','B3','B3:The Bag Broker UK','B4','B4:Bag Broker UK 可分解','C1','C1:The Packaging People','C2','C2:The Packing People 可分解','D1','D1:喜美標籤','D2','D2:盤商標籤','E1','E1：祥龍,F1：永恆包裝(TBB-其他)
','F1','F1：永恆包裝(TBB-其他)',' ') 類別名稱,
	A.無氣閥產品編號 無氣閥無鐵條編號,
	nvl(B.品名,'無品名')||'/'||nvl(B.規格,'') 品名規格,
	'('||A.無氣閥產品編號||')'||nvl(B.品名,'無品名')||' '||nvl(B.規格,'')||nvl(B.品名,'無品名')||' '||規格 產品編號品名規格
from 
	FIL003F A
	Left JOIN ViewFIL1012 B ON A.無氣閥產品編號=B.產品編號
WHERE
	A.無氣閥產品編號<>' ';

-- Oracle user_views
CREATE VIEW "VIEWFIL4048A2" ("製令單別", "製令單號", "產品序號", "類別", "類別名稱", "有氣閥編號", "品名規格", "產品編號品名規格") AS Select 
	A.單據類別 製令單別,
	A.單據編號 製令單號,
	to_char(A.單據序號)||to_char('-1') 產品序號,
	A.類別,
	decode(A.類別,'A1','A1:TRICOR BRAUN(客製品)','A2','A2:TRICOR BRAUN(公版品)','A3','A3:TRICOR BRAUN(客製品_加)','A4','A4:TRICOR BRAUN(公版品_加)','B1','B1:The Bag Broker EU','B2','B2:The Bag Broker EU 可分解','B3','B3:The Bag Broker UK','B4','B4:Bag Broker UK 可分解','C1','C1:The Packaging People','C2','C2:The Packing People 可分解','D1','D1:喜美標籤','D2','D2:盤商標籤','E1','E1：祥龍,F1：永恆包裝(TBB-其他)
','F1','F1：永恆包裝(TBB-其他)',' ') 類別名稱,
	to_char(A.有氣閥產品編號) 有氣閥編號,
	nvl(B.品名,'無品名')||'/'||nvl(B.規格,'') 品名規格,
	'('||A.無氣閥產品編號||')'||nvl(B.品名,'無品名')||' '||nvl(B.規格,'')||nvl(B.品名,'無品名')||' '||規格 產品編號品名規格
from 
	FIL003F A
	LEFT JOIN ViewFIL1012 B ON A.有氣閥產品編號=B.產品編號
where
	A.有氣閥產品編號<>' ';

-- Oracle user_views
CREATE VIEW "VIEWFIL4048A3" ("製令單別", "製令單號", "產品序號", "類別", "類別名稱", "有鐵條編號", "品名規格", "產品編號品名規格") AS Select 
	A.單據類別 製令單別,
	A.單據編號 製令單號,
	to_char(A.單據序號)||to_char('-1') 產品序號,
	A.類別,
	decode(A.類別,'A1','A1:TRICOR BRAUN(客製品)','A2','A2:TRICOR BRAUN(公版品)','A3','A3:TRICOR BRAUN(客製品_加)','A4','A4:TRICOR BRAUN(公版品_加)','B1','B1:The Bag Broker EU','B2','B2:The Bag Broker EU 可分解','B3','B3:The Bag Broker UK','B4','B4:Bag Broker UK 可分解','C1','C1:The Packaging People','C2','C2:The Packing People 可分解','D1','D1:喜美標籤','D2','D2:盤商標籤','E1','E1：祥龍,F1：永恆包裝(TBB-其他)
','F1','F1：永恆包裝(TBB-其他)',' ') 類別名稱,
	to_char(A.無氣閥有鐵條編號) 有鐵條編號,
	nvl(B.品名,'無品名')||'/'||nvl(B.規格,'') 品名規格,
	'('||A.無氣閥產品編號||')'||nvl(B.品名,'無品名')||' '||nvl(B.規格,'')||nvl(B.品名,'無品名')||' '||規格 產品編號品名規格
from 
	FIL003F A
	LEFT JOIN ViewFIL1012 B ON A.無氣閥有鐵條編號=B.產品編號
where 
	A.無氣閥有鐵條編號<>' '

Union all

Select 
	A.單據類別 製令單別,
	A.單據編號 製令單號,
	to_char(A.單據序號)||to_char('-2') 產品序號,
	A.類別,
	decode(A.類別,'A1','A1:TRICOR BRAUN(客製品)','A2','A2:TRICOR BRAUN(公版品)','B1','B1:The Bag Broker EU','B2','B2:The Bag Broker EU 可分解','B3','B3:The Bag Broker UK','B4','B4:Bag Broker UK 可分解','C1','C1:The Packaging People','C2','C2:The Packing People 可分解','D1','D1:喜美標籤','D2','D2:盤商標籤','E1','E1：祥龍,F1：永恆包裝(TBB-其他)
','F1','F1：永恆包裝(TBB-其他)',' ') 類別名稱,
	to_char(A.有氣閥有鐵條編號) 有條鐵編號,
	nvl(B.品名,'無品名')||'/'||nvl(B.規格,'') 品名規格,
	'('||A.無氣閥產品編號||')'||nvl(B.品名,'無品名')||' '||nvl(B.規格,'')||nvl(B.品名,'無品名')||' '||規格 產品編號品名規格
from 
	FIL003F A
	LEFT JOIN ViewFIL1012 B ON A.有氣閥有鐵條編號=B.產品編號
where
	A.有氣閥有鐵條編號<>' ';

-- Oracle user_views
CREATE VIEW "VIEWFIL4048A4" ("製令單別", "製令單號", "單據序號", "產品序號", "類別", "類別名稱", "產品編號", "品名規格", "產品編號品名規格", "PO", "產品名稱", "客戶料號", "客戶品號", "客戶名稱", "保存期限", "儲存溫度", "儲存濕度", "製造廠商", "材質") AS Select 
	A.單據類別 製令單別,
	A.單據編號 製令單號,
	A.單據序號,
	1 產品序號,
	A.類別,
	decode(A.類別,'A1','A1:TRICOR BRAUN(客製品)','A2','A2:TRICOR BRAUN(公版品)','A3','A3:TRICOR BRAUN(客製品_加)','A4','A4:TRICOR BRAUN(公版品_加)','B1','B1:The Bag Broker EU','B2','B2:The Bag Broker EU 可分解','B3','B3:The Bag Broker UK','B4','B4:Bag Broker UK 可分解','C1','C1:The Packaging People','C2','C2:The Packing People 可分解','D1','D1:喜美標籤','D2','D2:盤商標籤','E1','E1：祥龍,F1：永恆包裝(TBB-其他)
','F1','F1：永恆包裝(TBB-其他)',' ') 類別名稱,
	to_char(A.無氣閥產品編號) 產品編號,
	nvl(B.品名,'無品名')||'/'||nvl(B.規格,'') 品名規格,
	'('||A.無氣閥產品編號||')'||nvl(B.品名,'無品名')||' '||nvl(B.規格,'') 產品編號品名規格,
	A.PO,
	A.TITLE 產品名稱,
	A.CARTONLABEL 客戶料號,
	A.ITEM 客戶品號,
	A.客戶名稱,
	A.保存期限,
	A.儲存溫度,
	A.儲存濕度,
	A.製造廠商,
	A.材質
from 
	FIL003F A
	LEFT JOIN ViewFIL1012 B ON A.無氣閥產品編號=B.產品編號

Union all

Select 
	A.單據類別 製令單別,
	A.單據編號 製令單號,
	A.單據序號,
	3 產品序號,
	A.類別,
	decode(A.類別,'A1','A1:TRICOR BRAUN(客製品)','A2','A2:TRICOR BRAUN(公版品)','A3','A3:TRICOR BRAUN(客製品_加)','A4','A4:TRICOR BRAUN(公版品_加)','B1','B1:The Bag Broker EU','B2','B2:The Bag Broker EU 可分解','B3','B3:The Bag Broker UK','B4','B4:Bag Broker UK 可分解','C1','C1:The Packaging People','C2','C2:The Packing People 可分解','D1','D1:喜美標籤','D2','D2:盤商標籤','E1','E1：祥龍,F1：永恆包裝(TBB-其他)
','F1','F1：永恆包裝(TBB-其他)',' ') 類別名稱,
	to_char(A.有氣閥產品編號) 產品編號,
	nvl(B.品名,'無品名')||'/'||nvl(B.規格,'') 品名規格,
	'('||A.有氣閥產品編號||')'||nvl(B.品名,'無品名')||' '||nvl(B.規格,'') 產品編號品名規格,
	A.PO_2,
	A.TITLE_2 產品名稱,
	A.CARTONLABEL_2 客戶料號,
	A.ITEM_2 客戶品號,
	A.客戶名稱_2,
	A.保存期限_2,
	A.儲存溫度_2,
	A.儲存濕度_2,
	A.製造廠商_2,
	A.材質
from 
	FIL003F A
	LEFT JOIN ViewFIL1012 B ON A.有氣閥產品編號=B.產品編號


Union all

Select 
	A.單據類別 製令單別,
	A.單據編號 製令單號,
	A.單據序號,
	2 產品序號,
	A.類別,
	decode(A.類別,'A1','A1:TRICOR BRAUN(客製品)','A2','A2:TRICOR BRAUN(公版品)','A3','A3:TRICOR BRAUN(客製品_加)','A4','A4:TRICOR BRAUN(公版品_加)','B1','B1:The Bag Broker EU','B2','B2:The Bag Broker EU 可分解','B3','B3:The Bag Broker UK','B4','B4:Bag Broker UK 可分解','C1','C1:The Packaging People','C2','C2:The Packing People 可分解','D1','D1:喜美標籤','D2','D2:盤商標籤','E1','E1：祥龍,F1：永恆包裝(TBB-其他)
','F1','F1：永恆包裝(TBB-其他)',' ') 類別名稱,
	to_char(A.無氣閥有鐵條編號) 產品編號,
	B.品名||'/'||規格 品名規格,
	'('||A.無氣閥有鐵條編號||')'||nvl(B.品名,'無品名')||' '||nvl(B.規格,'')產品編號品名規格,
	A.PO_3,
	A.TITLE_3 產品名稱,
	A.CARTONLABEL_3 客戶料號,
	A.ITEM_3 客戶品號,
	A.客戶名稱_3,
	A.保存期限_3,
	A.儲存溫度_3,
	A.儲存濕度_3,
	A.製造廠商_3,
	A.材質
from 
	FIL003F A
	LEFT JOIN ViewFIL1012 B ON A.無氣閥有鐵條編號=B.產品編號


Union all

Select 
	A.單據類別 製令單別,
	A.單據編號 製令單號,
	A.單據序號,
	4 產品序號,
	A.類別,
	decode(A.類別,'A1','A1:TRICOR BRAUN(客製品)','A2','A2:TRICOR BRAUN(公版品)','A3','A3:TRICOR BRAUN(客製品_加)','A4','A4:TRICOR BRAUN(公版品_加)','B1','B1:The Bag Broker EU','B2','B2:The Bag Broker EU 可分解','B3','B3:The Bag Broker UK','B4','B4:Bag Broker UK 可分解','C1','C1:The Packaging People','C2','C2:The Packing People 可分解','D1','D1:喜美標籤','D2','D2:盤商標籤','E1','E1：祥龍,F1：永恆包裝(TBB-其他)
','F1','F1：永恆包裝(TBB-其他)',' ') 類別名稱,
	to_char(A.有氣閥有鐵條編號) 產品編號,
	nvl(B.品名,'無品名')||'/'||nvl(B.規格,'') 品名規格,
	'('||A.有氣閥有鐵條編號||')'||nvl(B.品名,'無品名')||' '||nvl(B.規格,'') 產品編號品名規格,
	A.PO_4,
	A.TITLE_4 產品名稱,
	A.CARTONLABEL_4 客戶料號,
	A.ITEM_4 客戶品號,
	A.客戶名稱_4,
	A.保存期限_4,
	A.儲存溫度_4,
	A.儲存濕度_4,
	A.製造廠商_4,
	A.材質
from 
	FIL003F A
	LEFT JOIN ViewFIL1012 B ON A.有氣閥有鐵條編號=B.產品編號;

-- Oracle user_views
CREATE VIEW "VIEWFIL4048A5" ("製令類別", "製令單號", "單據類別", "製程代碼", "產品編號") AS SELECT  distinct A.製令類別,A.製令單號,	A.單據類別,A.製程代碼,
		first_value(A.產品編號) over (partition by A.製令類別,A.製令單號,A.單據類別 order by A.作業日期 desc) 產品編號
FROM 
(SELECT 
	D.歸屬類別 製令類別,
	D.歸屬編號 製令單號,
	A.單據類別,
	C.製程代碼,
	D.單據日期 作業日期,
	A.產品編號
FROM 
	FIL0040 A
	INNER JOIN FIL0041 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號 AND A.單據序號 = B.序號
	INNER JOIN FIL0031 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號 
	INNER JOIN FIL0030 D ON A.單據類別 = D.單據類別 AND A.單據編號 = D.單據編號
	LEFT JOIN VIEWFIL404E7 G ON D.歸屬類別 = G.製令單別 AND D.歸屬編號 = G.製令單號 AND A.異動數量=G.箱號
WHERE
	A.異動類別 = 'A' AND (C.製程代碼 = 'C31E' OR C.製程代碼 = 'C31F' OR C.製程代碼 = 'C31G') AND A.產品編號<>' '

Union All

SELECT 
	To_Char('C11') 製令類別,
	A.廠客品號 製令單號,
	A.單據類別,
	To_Char(' ') 製程代碼,
	D.單據日期 作業日期,
	A.產品編號
FROM 
	FIL0040 A
	INNER JOIN FIL0041 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號 AND A.單據序號 = B.序號
	INNER JOIN FIL0030 D ON A.單據類別 = D.單據類別 AND A.單據編號 = D.單據編號
	LEFT JOIN VIEWFIL404E7 J ON To_Char('C11') = J.製令單別 AND A.廠客品號 = J.製令單號 AND A.異動數量=J.箱號
	
WHERE
	(A.單據類別 = 'E32' or A.單據類別 = 'E33'  or A.單據類別 = 'E35' or A.單據類別='E37') AND A.產品編號<>' '
) A;

-- Oracle user_views
CREATE VIEW "VIEWFIL4048A6" ("製令類別", "製令單號", "產品編號") AS SELECT  distinct A.製令類別,A.製令單號,
		first_value(A.產品編號) over (partition by A.製令類別,A.製令單號 order by A.作業日期 desc) 產品編號
FROM 
(SELECT 
	D.歸屬類別 製令類別,
	D.歸屬編號 製令單號,
	D.單據日期 作業日期,
	A.產品編號
FROM 
	FIL0040 A
	INNER JOIN FIL0041 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號 AND A.單據序號 = B.序號
	INNER JOIN FIL0031 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號 
	INNER JOIN FIL0030 D ON A.單據類別 = D.單據類別 AND A.單據編號 = D.單據編號
	LEFT JOIN VIEWFIL404E7 G ON D.歸屬類別 = G.製令單別 AND D.歸屬編號 = G.製令單號 AND A.異動數量=G.箱號
WHERE
	A.異動類別 = 'A' AND (C.製程代碼 = 'C31E' OR C.製程代碼 = 'C31F' OR C.製程代碼 = 'C31G') AND A.產品編號<>' '

Union All

SELECT 
	To_Char('C11') 製令類別,
	A.廠客品號 製令單號,
	D.單據日期 作業日期,
	A.產品編號
FROM 
	FIL0040 A
	INNER JOIN FIL0041 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號 AND A.單據序號 = B.序號
	INNER JOIN FIL0030 D ON A.單據類別 = D.單據類別 AND A.單據編號 = D.單據編號
	LEFT JOIN VIEWFIL404E7 J ON To_Char('C11') = J.製令單別 AND A.廠客品號 = J.製令單號 AND A.異動數量=J.箱號
	
WHERE
	(A.單據類別 = 'E32' or A.單據類別 = 'E33'  or A.單據類別 = 'E35' or A.單據類別='E37') AND A.產品編號<>' '
) A;

-- Oracle user_views
CREATE VIEW "VIEWFIL4048AA" ("製令單別", "製令單號", "料號", "需求量", "類別") AS (
	/* 夾鍊一 */
SELECT
	A.製令單別,
	A.製令單號,
	A.加工項目_夾鍊代碼 料號,
	A.成袋數*A.加工項目_夾鍊mm 需求量,
	TO_CHAR('夾鍊一') 類別
FROM
	FIL0032 A
	INNER JOIN FIL0030 B ON A.製令單別 = B.單據類別 AND A.製令單號 = B.單據編號
	INNER JOIN ViewOfObjProperties C ON B.流水編號 = C.單據流水號
WHERE
	B.邏輯值一 = 0 AND C.簽核狀態 = 'E' AND A.加工項目_夾鍊代碼 != ' '

UNION
	
	/* 夾鍊二 */
SELECT
	A.製令單別,
	A.製令單號,
	A.加工項目_夾鍊代碼二 料號,
	A.成袋數*A.加工項目_夾鍊mm二 需求量,
	TO_CHAR('夾鍊二') 類別
FROM
	FIL0032 A
	INNER JOIN FIL0030 B ON A.製令單別 = B.單據類別 AND A.製令單號 = B.單據編號
	INNER JOIN ViewOfObjProperties C ON B.流水編號 = C.單據流水號
WHERE
	B.邏輯值一 = 0 AND C.簽核狀態 = 'E' AND A.加工項目_夾鍊代碼二 != ' '	

UNION
	
	/* 氣閥 */
SELECT
	A.製令單別,
	A.製令單號,
	A.加工項目_氣閥代碼 料號,
	A.成袋數*A.加工項目_氣閥mm 需求量,
	TO_CHAR('氣閥') 類別
FROM
	FIL0032 A
	INNER JOIN FIL0030 B ON A.製令單別 = B.單據類別 AND A.製令單號 = B.單據編號
	INNER JOIN ViewOfObjProperties C ON B.流水編號 = C.單據流水號
WHERE
	B.邏輯值一 = 0 AND C.簽核狀態 = 'E' AND A.加工項目_氣閥代碼 != ' '	

UNION
	
	/* 鐵條 */
SELECT
	A.製令單別,
	A.製令單號,
	A.加工項目_鐵條代碼 料號,
	A.成袋數*A.加工項目_鐵條mm 需求量,
	TO_CHAR('鐵條') 類別
FROM
	FIL0032 A
	INNER JOIN FIL0030 B ON A.製令單別 = B.單據類別 AND A.製令單號 = B.單據編號
	INNER JOIN ViewOfObjProperties C ON B.流水編號 = C.單據流水號
WHERE
	B.邏輯值一 = 0 AND C.簽核狀態 = 'E' AND A.加工項目_鐵條代碼 != ' '	 	

UNION
	
	/* 紙箱_無氣閥 */
SELECT
	A.製令單別,
	A.製令單號,
	A.紙箱代碼 料號,
	A.成袋數 需求量,
	TO_CHAR('紙箱無氣閥') 類別
FROM
	FIL0032 A
	INNER JOIN FIL0030 B ON A.製令單別 = B.單據類別 AND A.製令單號 = B.單據編號
	INNER JOIN ViewOfObjProperties C ON B.流水編號 = C.單據流水號
WHERE
	B.邏輯值一 = 0 AND C.簽核狀態 = 'E' AND A.紙箱代碼 != ' '		

UNION
	
	/* 紙箱_氣閥 */
SELECT
	A.製令單別,
	A.製令單號,
	A.紙箱代碼_氣閥 料號,
	A.成袋數 需求量,
	TO_CHAR('紙箱有氣閥') 類別
FROM
	FIL0032 A
	INNER JOIN FIL0030 B ON A.製令單別 = B.單據類別 AND A.製令單號 = B.單據編號
	INNER JOIN ViewOfObjProperties C ON B.流水編號 = C.單據流水號
WHERE
	B.邏輯值一 = 0 AND C.簽核狀態 = 'E' AND A.紙箱代碼_氣閥 != ' '			
);

-- Oracle user_views
CREATE VIEW "VIEWFIL4048AB" ("製令單號") AS (
SELECT distinct
	A.製令單號
FROM
	FIL0033 A
WHERE
	((DECODE(INSTR(A.印刷色順一,'共'),0,0,1)+DECODE(INSTR(A.印刷色順二,'共'),0,0,1)+DECODE(INSTR(A.印刷色順三,'共'),0,0,1)+DECODE(INSTR(A.印刷色順四,'共'),0,0,1)+DECODE(INSTR(A.印刷色順五,'共'),0,0,1)+DECODE(INSTR(A.印刷色順六,'共'),0,0,1)+DECODE(INSTR(A.印刷色順七,'共'),0,0,1)+DECODE(INSTR(A.印刷色順八,'共'),0,0,1)+DECODE(INSTR(A.印刷色順九,'共'),0,0,1)+DECODE(INSTR(A.印刷色順十,'共'),0,0,1))
	-(DECODE(INSTR(A.印刷色順一,'母共'),0,0,1)+DECODE(INSTR(A.印刷色順二,'母共'),0,0,1)+DECODE(INSTR(A.印刷色順三,'母共'),0,0,1)+DECODE(INSTR(A.印刷色順四,'母共'),0,0,1)+DECODE(INSTR(A.印刷色順五,'母共'),0,0,1)+DECODE(INSTR(A.印刷色順六,'母共'),0,0,1)+DECODE(INSTR(A.印刷色順七,'母共'),0,0,1)+DECODE(INSTR(A.印刷色順八,'母共'),0,0,1)+DECODE(INSTR(A.印刷色順九,'母共'),0,0,1)+DECODE(INSTR(A.印刷色順十,'母共'),0,0,1))
	)
	> 0
GROUP BY
	A.製令單號
);

-- Oracle user_views
CREATE VIEW "VIEWFIL4048AC" ("主產品編號", "產品編號") AS (
SELECT DISTINCT
	A.主產品編號,
	A.產品編號
FROM
(	
SELECT 
	A.產品編號 主產品編號,
	A.產品編號 產品編號
FROM
	FIL0032 A 
	
UNION

SELECT 
	B.產品編號 主產品編號,
	A.無氣閥產品編號 產品編號
FROM
	FIL003F A
	INNER JOIN FIL0032 B ON A.單據類別=B.製令單別 AND A.單據編號=B.製令單號
WHERE 
	A.無氣閥產品編號<>' '

UNION

SELECT
	B.產品編號 主產品編號,
	A.無氣閥有鐵條編號 產品編號
FROM
	FIL003F A
	INNER JOIN FIL0032 B ON A.單據類別=B.製令單別 AND A.單據編號=B.製令單號
WHERE 
	A.無氣閥有鐵條編號<>' '	

UNION

SELECT
	B.產品編號 主產品編號,
	A.有氣閥產品編號 產品編號
FROM
	FIL003F A
	INNER JOIN FIL0032 B ON A.單據類別=B.製令單別 AND A.單據編號=B.製令單號
WHERE 
	A.有氣閥產品編號<>' '		

UNION

SELECT
	B.產品編號 主產品編號,
	A.有氣閥有鐵條編號 產品編號
FROM
	FIL003F A
	INNER JOIN FIL0032 B ON A.單據類別=B.製令單別 AND A.單據編號=B.製令單號
WHERE 
	A.有氣閥有鐵條編號<>' '	
) A
INNER JOIN A01_18 C ON A.產品編號 = C.產品編號 AND (LENGTH(C.留言)>0 OR LENGTH(C.手繪)>0)
);

-- Oracle user_views
CREATE VIEW "VIEWFIL4048AD" ("製令單別", "製令單號", "加工別", "用途", "印刷基材", "用量") AS (
SELECT 
	A.製令單別,
	A.製令單號,
	A.加工別,
	'印刷基材' 用途,
	A.印刷基材,
	A.印刷米數 用量
FROM
	FIL0033 A
WHERE
	A.印刷基材<>' '
	
UNION 

SELECT 
	A.製令單別,
	A.製令單號,
	A.加工別,
	'上臘材料' 用途,
	A.上臘材料編號,
	0 用量
FROM
	FIL0033 A
WHERE
	A.上臘材料編號<>' '	
	
UNION 

SELECT 
	A.製令單別,
	A.製令單號,
	A.加工別,
	'紙箱' 用途,
	A.紙箱代碼,
	DECODE(A.每箱幾捲,0,0,(A.成捲數*1+A.成捲差異比/100)/A.每箱幾捲) 用量
FROM
	FIL0033 A		
WHERE
	A.紙箱代碼<>' '	

UNION 

SELECT 
	A.製令單別,
	A.製令單號,
	A.加工類別 加工別,
	'膠水' 用途,
	A.膠水材料代碼 材料代碼,
	0 用量
FROM
	FIL0034 A			
WHERE
	A.膠水材料代碼<>' '
	
UNION 

SELECT 
	A.製令單別,
	A.製令單號,
	A.加工類別 加工別,
	'塑膠粒' 用途,
	A.塑膠粒材料代碼 材料代碼,
	0 用量
FROM
	FIL0034 A		
WHERE
	A.塑膠粒材料代碼<>' '
	
UNION 

SELECT 
	A.製令單別,
	A.製令單號,
	' ' 加工別,
	'夾鏈' 用途,
	A.加工項目_夾鍊代碼 材料代碼,
	A.成袋數*(1+成袋差異比/100) 用量
FROM
	FIL0032 A	
WHERE
	A.加工項目_夾鍊代碼<>' '	

UNION 

SELECT 
	A.製令單別,
	A.製令單號,
	' ' 加工別,
	'夾鏈二' 用途,
	A.加工項目_夾鍊代碼二 材料代碼,
	A.成袋數*(1+成袋差異比/100) 用量
FROM
	FIL0032 A		
WHERE
	A.加工項目_夾鍊代碼二<>' '	
	
UNION 

SELECT 
	A.製令單別,
	A.製令單號,
	' ' 加工別,
	'氣閥' 用途,
	A.加工項目_氣閥代碼 材料代碼,
	A.成袋數*(1+成袋差異比/100) 用量
FROM
	FIL0032 A	
WHERE
	A.加工項目_氣閥代碼<>' '		

UNION 

SELECT 
	A.製令單別,
	A.製令單號,
	' ' 加工別,
	'鐵條' 用途,
	A.加工項目_鐵條代碼 材料代碼,
	A.成袋數*(1+成袋差異比/100) 用量
FROM
	FIL0032 A		
WHERE
	A.加工項目_鐵條代碼<>' '		
);

-- Oracle user_views
CREATE VIEW "VIEWFIL4048B" ("單據類別", "單據編號", "類別", "類別名稱") AS Select 
	A.單據類別,
	A.單據編號,
	A.類別,
	B.顯示名稱 類別名稱
from 
	FIL003F1 A
	INNER JOIN ViewFIL3121 B ON A.類別 = B.代碼;

-- Oracle user_views
CREATE VIEW "VIEWFIL4048B1" ("製令單別", "製令單號", "單據序號", "產品序號", "類別", "類別名稱", "產品編號", "品名規格", "產品編號品名規格", "PO", "產品名稱", "客戶料號", "客戶品號", "客戶名稱", "保存期限", "儲存溫度", "儲存濕度", "製造廠商", "材質") AS Select 
	A.單據類別 製令單別,
	A.單據編號 製令單號,
	A.單據序號,
	1 產品序號,
	A.類別,
	decode(A.類別,'A1','A1:TRICOR BRAUN(客製品)','A2','A2:TRICOR BRAUN(公版品)','A3','A3:TRICOR BRAUN(客製品_加)','A4','A4:TRICOR BRAUN(公版品_加)','B1','B1:The Bag Broker EU','B2','B2:The Bag Broker EU 可分解','B3','B3:The Bag Broker UK','B4','B4:Bag Broker UK 可分解','C1','C1:The Packaging People','C2','C2:The Packing People 可分解','D1','D1:喜美標籤','D2','D2:盤商標籤','E1','E1：祥龍,F1：永恆包裝(TBB-其他)
','F1','F1：永恆包裝(TBB-其他)',' ') 類別名稱,
	A.產品編號,
	A.產品規格 品名規格,
	'('||A.產品編號||')'||A.產品名稱||' '||A.產品規格 產品編號品名規格,
	A.客戶訂單 PO,
	A.產品名稱,
	A.客戶料號,
	A.客戶品號,
	A.客戶名稱,
	A.保存期限,
	A.儲存溫度,
	A.儲存濕度,
	A.廠商 製造廠商,
	A.材質結構 材質
from 
	FIL003F1 A;

-- Oracle user_views
CREATE VIEW "VIEWFIL4049" ("單據類別", "單據編號", "節點", "用途", "材料代碼", "品名", "備註", "單位", "規格", "厚度", "序號") AS (SELECT 
	'C11' 單據類別,
	A.製令單號 單據編號,
	A.節點,
	'使用半成品一',
	to_char(' '),
	to_char(DECODE(A.使用半成品,' ',' ',A.使用半成品)),
	A.說明,
	to_char(' '),
	to_char(' '),
	to_char(' '),
	1
FROM
	FIL0039 A
WHERE A.使用半成品<>' '	

union all

SELECT 
	'C11' 單據類別,
	A.製令單號 單據編號,
	A.節點,
	'使用半成品二',
	to_char(' '),
	to_char(DECODE(A.使用半成品二,' ',' ',A.使用半成品)),
	A.說明,
	to_char(' '),
	to_char(' '),
	to_char(' '),
	2
FROM
	FIL0039 A
WHERE A.使用半成品二<>' '

union all

SELECT 
	'C11' 單據類別,
	A.製令單號 單據編號,
	A.節點,
	'使用半成品三',
	to_char(' '),
	to_char(DECODE(A.使用半成品三,' ',' ',A.使用半成品)),
	A.說明,
	to_char(' '),
	to_char(' '),
	to_char(' '),
	3
FROM
	FIL0039 A
WHERE A.使用半成品三<>' '

union all

SELECT 
	'C11' 單據類別,
	A.製令單號 單據編號,
	A.節點,
	'使用半成品四',
	to_char(' '),
	to_char(DECODE(A.使用半成品四,' ',' ',A.使用半成品)),
	A.說明,
	to_char(' '),
	to_char(' '),
	to_char(' '),
	4
FROM
	FIL0039 A
WHERE A.使用半成品四<>' '

union all

SELECT 
	'C11' 單據類別,
	A.製令單號 單據編號,
	A.節點,
	'使用材料一',
	to_char(NVL(A.物料編號,' ')),
	to_char(NVL(B.品名,' ')),
	A.說明,
	to_char(B.單位代碼),
	to_char(NVL(B.規格,' ')),
	to_char(NVL(C.厚度,' ')),
	5
FROM
	FIL0039 A		
	LEFT JOIN FIL0012 B ON A.物料編號=B.產品編號
	LEFT JOIN FIL0034 C ON C.塑膠粒材料代碼=A.物料編號
WHERE 	A.物料編號<>' '
	
union all

SELECT 
	'C11' 單據類別,
	A.製令單號 單據編號,
	A.節點,
	'使用材料二',
	to_char(NVL(A.物料編號二,' ')),
	to_char(NVL(B.品名,' ')),
	A.說明,
	to_char(B.單位代碼),
	to_char(NVL(B.規格,' ')),
	to_char(NVL(C.厚度,' ')),
	6
FROM
	FIL0039 A		
	LEFT JOIN FIL0012 B ON A.物料編號=B.產品編號
	LEFT JOIN FIL0034 C ON C.塑膠粒材料代碼=A.物料編號
WHERE 	A.物料編號二<>' '	
	
union all

SELECT 
	'C11' 單據類別,
	A.製令單號 單據編號,
	A.節點,
	'使用材料三',
	to_char(NVL(A.物料編號三,' ')),
	to_char(NVL(B.品名,' ')),
	A.說明,
	to_char(B.單位代碼),
	to_char(NVL(B.規格,' ')),
	to_char(NVL(C.厚度,' ')),
	7
FROM
	FIL0039 A		
	LEFT JOIN FIL0012 B ON A.物料編號=B.產品編號
	LEFT JOIN FIL0034 C ON C.塑膠粒材料代碼=A.物料編號
WHERE 	A.物料編號三<>' '	
	
union all

SELECT 
	'C11' 單據類別,
	A.製令單號 單據編號,
	A.節點,
	'使用材料四',
	to_char(NVL(A.物料編號四,' ')),
	to_char(NVL(B.品名,' ')),
	A.說明,
	to_char(B.單位代碼),
	to_char(NVL(B.規格,' ')),
	to_char(NVL(C.厚度,' ')),
	8
FROM
	FIL0039 A		
	LEFT JOIN FIL0012 B ON A.物料編號=B.產品編號
	LEFT JOIN FIL0034 C ON C.塑膠粒材料代碼=A.物料編號
WHERE 	A.物料編號四<>' '	
);

-- Oracle user_views（在 Oracle 已失效）
CREATE VIEW "VIEWFIL4049A" ("單別", "單號", "用途", "加工類別", "序號", "製程代碼", "製程名稱", "工站代碼", "工站名稱", "機台代碼", "機台名稱", "排程日期", "排程序號", "製令單別", "製令單號", "節點", "公司代碼", "公司名稱", "訂單單別", "訂單單號", "產品編號", "產品名稱", "產品規格", "材質結構", "材料代碼", "用量", "單位", "備註", "材料品名", "材料規格", "厚度") AS (SELECT
	A.單別,
	A.單號,
	to_char(B.用途) 用途,
	to_char(' ') 加工類別,
	B.序號,
	A.製程代碼,
	A.製程名稱,
	A.工站代碼,
	A.工站名稱,
	A.機台代碼,
	A.機台名稱,
	A.排程日期,
	A.序號 排程序號,
	A.製令單別,
	A.製令單號,
	A.節點,
	A.公司代碼,
	A.公司名稱,
	A.訂單單別,
	A.訂單單號,
	A.產品編號,
	A.產品名稱,
	A.產品規格,
	A.材質結構,
	B.材料代碼,
	0 用量,
	to_char(B.單位) 單位,
	B.備註,
	nvl(B.品名, ' ') 材料品名,
	to_char(nvl(B.規格, ' ')) 材料規格,
	to_char(nvl(B.厚度,' ')) 厚度
FROM
	ViewFIL4040 A
	INNER JOIN VIEWFIL4049 B ON A.製令單別 = B.單據類別 AND A.製令單號 = B.單據編號 AND A.節點 = B.節點
);

-- Oracle user_views
CREATE VIEW "VIEWFIL404A" ("單別", "單號", "訂單數量", "已交數量", "贈品量", "贈品已交量", "金額", "毛重", "材積", "稅率", "稅額", "含稅金額") AS (SELECT 
	A.單別, 
	A.單號,
	A.訂單數量,
	A.已交數量,
	A.贈品量,
	A.贈品已交量,
	A.金額,
	A.毛重,
	A.材積,
	B.稅率,
	round(A.金額 * B.稅率 / 100) 稅額,
	round(A.金額 * (1 + B.稅率 / 100)) 含稅金額
FROM
	(	SELECT 
			A.單據類別 單別, 
			A.單據編號 單號,
			sum(A.異動數量) 訂單數量,
			0 已交數量,
			sum(A.贈品數量) 贈品量,
			0 贈品已交量,
			sum(A.異動金額) 金額,
			sum(A.毛重) 毛重,
			sum(A.材積) 材積
		FROM 
			FIL0040 A
		WHERE
			A.單據類別 = 'B42'
		GROUP BY
			A.單據類別,
			A.單據編號
	) A
	INNER JOIN FIL0030 B ON A.單別 = B.單據類別 AND A.單號 = B.單據編號);

-- Oracle user_views
CREATE VIEW "VIEWFIL404A1" ("單別", "單號", "作業日期", "製令單別", "製令單號", "公司代碼", "公司名稱", "訂單單別", "訂單單號", "機台代碼", "機台名稱", "加工別", "本日件數順序", "主旨", "客戶編號", "客戶名稱", "產品編號", "產品名稱", "產品規格", "試刷料號", "試刷料名稱", "試刷料規格", "正式料號", "正式料名稱", "正式料規格", "打樣", "結束", "待補", "改件調機", "試刷料米數", "使用廢料試刷", "看色人員", "看色人員說明", "其他看色人員", "印刷色數", "頭出尾出", "頭出尾出說明", "印刷面", "印刷面說明", "開始時間", "收拾時間", "結束時間", "印刷時間", "看色耗時", "總耗時", "看色日時起", "看色日時迄", "開始日時", "結束日時", "停機日時", "印刷日時", "版銅圓周", "加工速度", "簽核系統", "備註", "作業人員", "作業人員姓名", "確認碼", "餘料回庫", "餘料回庫預設庫別", "代客戶看色", "開始看色", "結束看色", "重印刷", "看色時間起", "看色時間迄", "簽核狀態", "生產數量", "色順數", "流水編號", "填表人", "單位主管流水編號", "填表人姓名", "員工流水編號", "填表日", "CCP筆數", "生產條件捲數", "最後更新者", "更新者姓名", "最後更新日") AS (                                                                                                                                                      SELECT
	A.單據類別 單別,
	A.單據編號 單號,
	A.單據日期 作業日期,
	A.歸屬類別 製令單別,
	A.歸屬編號 製令單號,
	C.公司代碼,
	C.公司名稱,
	C.訂單單別,
	C.訂單單號,
	B.機台代碼,
	nvl(D.名稱, ' ') 機台名稱,
	decode(B.交貨日期_次批 ,'A','A材','B','B材','C','底邊','D','A側','E','B側',' ') 加工別,
	B.交貨日期_天 本日件數順序,
	A.單據編號||'('||trim(A.單據類別)||')'||'/製令:'||nvl(A.歸屬編號, ' ')||'/'||C.產品名稱 主旨,
	C.客戶編號,
	C.客戶名稱,
	C.產品編號,
	C.產品名稱,
	C.產品規格,
	B.文數字2 試刷料號,
	nvl(F.品名, ' ') 試刷料名稱,
	nvl(F.規格, ' ') 試刷料規格,
	B.文數字4 正式料號,
	nvl(G.品名, ' ') 正式料名稱,
	nvl(G.規格, ' ') 正式料規格,
	B.回簽 打樣,
	B.Logical4 結束,
	B.Logical5 待補,
	B.Logical6 改件調機,
	B.數值11 試刷料米數,
	B.Logical1 使用廢料試刷,
	B.付款方式 看色人員,
	decode(B.付款方式, '1', '客戶', '2', '副理', '3', '營業', '4', '自己', '5', '其他', ' ') 看色人員說明,
	B.文數字13 其他看色人員,
	B.票期 印刷色數,
	B.運輸方式 頭出尾出,
	decode(B.運輸方式, 'A', '頭出', 'B', '尾出', 'c', '均可', ' ') 頭出尾出說明,
	B.付款方式 印刷面,
	decode(B.付款方式, 'A', '表刷', 'B', '裡刷', 'C', '霧化', ' ') 印刷面說明,
	B.時間一 開始時間,
	B.時間六 收拾時間,
	B.時間五 結束時間,
	B.時間四 印刷時間,
	decode(B.時間三,'000000',0,(to_date(to_char(case when B.時間三>B.時間一 then to_date(A.單據日期,'yyyymmdd') else to_date(A.單據日期,'yyyymmdd')+1 end,'yyyymmdd')||B.時間三,'yyyymmddhh24miss')- 
	to_date(to_char(case when B.時間二>B.時間一 then to_date(A.單據日期,'yyyymmdd') else to_date(A.單據日期,'yyyymmdd')+1 end,'yyyymmdd')||B.時間二,'yyyymmddhh24miss'))*24) 看色耗時,
	decode(B.時間五,'000000',0,(to_date(to_char(case when B.時間五>B.時間一 then to_date(A.單據日期,'yyyymmdd') else to_date(A.單據日期,'yyyymmdd')+1 end,'yyyymmdd')||B.時間五,'yyyymmddhh24miss')- 
	to_date(trim(A.單據日期)||B.時間一,'yyyymmddhh24miss'))*24) 總耗時,
	to_date(to_char(case when B.時間二>B.時間一 then to_date(A.單據日期,'yyyymmdd') else to_date(A.單據日期,'yyyymmdd')+1 end,'yyyymmdd')||B.時間二,'yyyymmddhh24miss') 看色日時起,
	to_date(to_char(case when B.時間三>B.時間一 then to_date(A.單據日期,'yyyymmdd') else to_date(A.單據日期,'yyyymmdd')+1 end,'yyyymmdd')||B.時間三,'yyyymmddhh24miss') 看色日時迄,
	to_date(trim(A.單據日期)||B.時間一,'yyyymmddhh24miss') 開始日時,
	to_date(to_char(case when B.時間五>B.時間一 then to_date(A.單據日期,'yyyymmdd') else to_date(A.單據日期,'yyyymmdd')+1 end,'yyyymmdd')||B.時間五,'yyyymmddhh24miss') 結束日時,
	to_date(to_char(case when B.時間六>B.時間一 then to_date(A.單據日期,'yyyymmdd') else to_date(A.單據日期,'yyyymmdd')+1 end,'yyyymmdd')||B.時間六,'yyyymmddhh24miss') 停機日時,
	to_date(to_char(case when B.時間四>B.時間一 then to_date(A.單據日期,'yyyymmdd') else to_date(A.單據日期,'yyyymmdd')+1 end,'yyyymmdd')||B.時間四,'yyyymmddhh24miss') 印刷日時,
	B.數值3 版銅圓周,
	B.聯絡人序號 加工速度,
	A.簽核系統, 
	A.備註, 
	A.業務員 作業人員,
	nvl(E.員工姓名,' ') 作業人員姓名,
	A.確認碼,
	B.Logical3 餘料回庫,
	A.倉庫代碼 餘料回庫預設庫別,
	A.邏輯值一 代客戶看色,
	B.Logical9 開始看色,
	B.Logical10 結束看色,
	B.Logical13 重印刷,
	B.時間二 看色時間起,
	B.時間三 看色時間迄,
	nvl(Z3.簽核狀態, '0') 簽核狀態,
	nvl(B.數量,0) 生產數量,
	(decode(nvl(Z4.印刷色順一,' '),' ',0,1)
	+decode(nvl(Z4.印刷色順二,' '),' ',0,1)
	+decode(nvl(Z4.印刷色順三,' '),' ',0,1)
	+decode(nvl(Z4.印刷色順四,' '),' ',0,1)
	+decode(nvl(Z4.印刷色順五,' '),' ',0,1)
	+decode(nvl(Z4.印刷色順六,' '),' ',0,1)
	+decode(nvl(Z4.印刷色順七,' '),' ',0,1)
	+decode(nvl(Z4.印刷色順八,' '),' ',0,1)
	+decode(nvl(Z4.印刷色順九,' '),' ',0,1)
	+decode(nvl(Z4.印刷色順十,' '),' ',0,1)) 色順數,
	A.流水編號,
	A.填表人,
	D.單位主管流水編號,
	nvl(Z1.員工姓名,' ') 填表人姓名, 
	nvl(Z1.Serial_Num,' ') 員工流水編號,
	A.填表日, 
	NVL(J.CCP筆數,0) CCP筆數,
	NVL(Z5.印刷米數,0) 生產條件捲數,
	A.最後更新者,
	nvl(Z2.員工姓名,' ') 更新者姓名, 
	A.最後更新日
FROM
	FIL0030 A
	INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
	INNER JOIN ViewFIL4030 C ON A.歸屬類別 = C.製令單別 AND A.歸屬編號 = C.製令單號
	LEFT JOIN ViewFIL310P D ON B.機台代碼 = D.代碼
	LEFT JOIN FIL0010 E ON A.業務員 = E.員工編號
	LEFT JOIN FIL0012 F ON B.文數字2 = F.產品編號
	LEFT JOIN FIL0012 G ON B.文數字4 = G.產品編號
	LEFT JOIN FIL0010 Z1 ON A.填表人 = Z1.員工編號
	LEFT JOIN FIL0010 Z2 ON A.最後更新者 = Z2.員工編號
	LEFT JOIN ViewOfObjProperties Z3 ON A.流水編號 = Z3.單據流水號
	LEFT JOIN 
	(SELECT A.單別,A.單號,COUNT(序號) CCP筆數 FROM FIL004I A GROUP BY A.單別,A.單號) J ON J.單別=A.單據類別 AND J.單號=A.單據編號
	LEFT JOIN FIL0033 Z4 ON A.歸屬類別 = Z4.製令單別 AND A.歸屬編號 = Z4.製令單號 AND Z4.加工別=B.交貨日期_次批
	LEFT JOIN FIL0033 Z5 ON A.歸屬類別 = Z5.製令單別 AND A.歸屬編號 = Z5.製令單號 AND Z5.加工別='A'
WHERE
	A.單據類別 = 'C41' AND
	B.製程代碼 = 'C31A');

-- Oracle user_views
CREATE VIEW "VIEWFIL404A1A" ("單別", "單號", "開始看色", "結束看色", "看色時間起", "看色時間迄") AS (                                                                                                                                                      SELECT
	B.單別 單別,
	B.單號 單號,
	B.Logical9 開始看色,
	B.Logical10 結束看色,
	B.時間二 看色時間起,
	B.時間三 看色時間迄
FROM
	FIL0031 B
WHERE
	B.單別 = 'C41' AND
	B.製程代碼 = 'C31A');

-- Oracle user_views
CREATE VIEW "VIEWFIL404A1B" ("單別", "單號", "作業日期", "製令單號", "訂單單號", "產品編號", "結束", "待補", "改件調機", "加工人數", "總耗時", "簽核狀態", "製程代碼") AS (                                                                                                                                                      
SELECT
	A.單據類別 單別,
	A.單據編號 單號,
	A.單據日期 作業日期,
	A.歸屬編號 製令單號,
	C.訂單單號,
	C.產品編號,
	B.Logical4 結束,
	B.Logical5 待補,
	B.Logical6 改件調機,
	(DECODE(A.業務員,' ',0,1)+DECODE(B.文數字10,' ',0,1)+DECODE(B.文數字11,' ',0,1)+DECODE(B.文數字12,' ',0,1)) 加工人數,
	decode(B.時間五,'000000',0,(to_date(to_char(case when B.時間五>B.時間一 then to_date(A.單據日期,'yyyymmdd') else to_date(A.單據日期,'yyyymmdd')+1 end,'yyyymmdd')||B.時間五,'yyyymmddhh24miss')- 
	to_date(trim(A.單據日期)||B.時間一,'yyyymmddhh24miss'))*24) 總耗時,
	nvl(Z3.簽核狀態, '0') 簽核狀態,
	B.製程代碼
FROM
	FIL0030 A
	INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
	INNER JOIN ViewFIL4030 C ON A.歸屬類別 = C.製令單別 AND A.歸屬編號 = C.製令單號
	LEFT JOIN ViewOfObjProperties Z3 ON A.流水編號 = Z3.單據流水號
WHERE
	A.單據類別 = 'C41' AND
	(B.製程代碼 BETWEEN 'C31A' AND 'C31C' OR B.製程代碼 = 'C32D'));

-- Oracle user_views
CREATE VIEW "VIEWFIL404A1C" ("單別", "單號", "作業日期", "製令單號", "機台代碼", "機台名稱", "客戶編號", "客戶名稱") AS (                                                                                                                                                      SELECT
	A.單據類別 單別,
	A.單據編號 單號,
	A.單據日期 作業日期,
	A.歸屬編號 製令單號,
	B.機台代碼,
	nvl(D.名稱, ' ') 機台名稱,
	C.客戶編號,
	C.客戶名稱
FROM
	FIL0030 A
	INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
	INNER JOIN ViewFIL4030 C ON A.歸屬類別 = C.製令單別 AND A.歸屬編號 = C.製令單號
	LEFT JOIN ViewFIL310P D ON B.機台代碼 = D.代碼
WHERE
	A.單據類別 = 'C41' AND
	B.製程代碼 = 'C31A');

-- Oracle user_views
CREATE VIEW "VIEWFIL404A2" ("單別", "單號", "序號", "日期", "前製程編號", "領料米數", "材料編號", "印刷米數", "印刷處理面", "紙粗細面", "圓周數值", "引入張力", "版銅完整度", "不良標記數量", "半成品編號", "備註說明", "批號", "本製程編號", "品名", "規格", "前製程米數", "PLC抓取米數", "合理剔除數", "不良剔除數", "檢品數量", "線外不良剔除數", "線內不良剔除數", "試刷米數", "前製程條碼", "流水編號", "最後更新者", "更新者姓名", "最後更新日") AS (
SELECT 
	A.單據類別 單別, 
	A.單據編號 單號,
	A.單據序號 序號,
	A.異動日期 日期,
	A.前置單號 前製程編號,
	A.異動數量 領料米數,
	A.產品編號 材料編號,
	A.異動單價-夾鏈費 印刷米數,
	A.前置單別 印刷處理面,
	A.廠客品號 紙粗細面,
	A.折扣率 圓周數值,
	A.異動金額 引入張力,
	A.Logical1 版銅完整度,
	A.數值2 不良標記數量,
	A.文數字1 半成品編號,
	A.備註說明,
	C.批號,
	A.產品編號 本製程編號,
	nvl(E.品名, ' ') 品名,
	nvl(E.規格, ' ') 規格,
	A.異動數量 前製程米數,
	A.異動單價 PLC抓取米數,
	A.燙金費 合理剔除數,
	A.毛重 不良剔除數,
	A.贈品數量 檢品數量,
	A.雷射費 線外不良剔除數,
	A.夾鏈費 線內不良剔除數,
	A.氣閥費 試刷米數,
	C.文數字4 前製程條碼,
	A.流水編號,
	A.最後更新者,
	nvl(Z1.員工姓名,' ') 更新者姓名,
	A.最後更新日
FROM 
	FIL0040 A
	INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
	INNER JOIN FIL0041 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號 AND A.單據序號 = C.序號
	LEFT JOIN ViewFIL310P D ON B.機台代碼 = D.代碼
	LEFT JOIN FIL0012 E ON A.產品編號 = E.產品編號
	LEFT JOIN FIL0010 Z1 ON A.最後更新者 = Z1.員工編號
WHERE
	A.單據類別 = 'C41' AND
	A.異動類別 = 'A' AND
	B.製程代碼 = 'C31A' AND
	D.印刷上蠟版銅 = 0);

-- Oracle user_views
CREATE VIEW "VIEWFIL404A2A" ("單別", "單號", "序號", "異動類別", "本製程編號", "序號1", "前製程編號", "結餘數", "PLC抓取米數", "PLC抓取日", "最後更新日") AS (
SELECT 
	A.單據類別 單別, 
	A.單據編號 單號,
	A.單據序號 序號,
	A.異動類別,
	A.產品編號 本製程編號,
	A.鐵條費 序號1,
	A.前製程編號,
	A.數值1 結餘數,
	A.異動單價 PLC抓取米數,
	A.其它日期 PLC抓取日,
	A.最後更新日
FROM 
	FIL0040 A
	INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
	INNER JOIN FIL0041 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號 AND A.單據序號 = C.序號
	LEFT JOIN ViewFIL310P D ON B.機台代碼 = D.代碼
WHERE
	A.單據類別 = 'C41' AND
	A.異動類別 = 'A' AND
	B.製程代碼 = 'C31A' AND
	C.檢驗外觀 < 'B' AND
	D.印刷上蠟版銅 = 0);

-- Oracle user_views
CREATE VIEW "VIEWFIL404A3" ("單別", "單號", "序號", "色順", "色順名稱", "調色日期", "批號", "材料編號", "品名", "規格", "油墨配比", "製令單別", "製令單號", "客戶編號", "客戶名稱", "產品編號", "產品名稱", "產品規格", "備註說明", "流水編號", "最後更新者", "更新者姓名", "最後更新日") AS (
SELECT 
	A.單據類別 單別, 
	A.單據編號 單號,
	A.單據序號 序號,
	A.數值1 色順,
	A.廠客品號 色順名稱,
	A.預交日 調色日期,
	B.批號,
	A.產品編號 材料編號,
	nvl(C.品名, ' ') 品名,
	nvl(C.規格, ' ') 規格,
	A.文數字1 油墨配比,
	D1.歸屬類別 製令單別,
	D1.歸屬編號 製令單號,
	C1.客戶編號,
	C1.客戶名稱,
	C1.產品編號,
	C1.產品名稱,
	C1.產品規格,
	A.備註說明,
	A.流水編號,
	A.最後更新者,
	nvl(Z1.員工姓名,' ') 更新者姓名,
	A.最後更新日
FROM 
	FIL0040 A
	INNER JOIN FIL0031 D ON A.單據類別 = D.單別 AND A.單據編號 = D.單號
	INNER JOIN FIL0030 D1 ON A.單據類別 = D1.單據類別 AND A.單據編號 = D1.單據編號
	LEFT JOIN FIL0041 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號 AND A.單據序號 = B.序號
	LEFT JOIN FIL0012 C ON A.產品編號 = C.產品編號
	LEFT JOIN FIL0010 Z1 ON A.最後更新者 = Z1.員工編號
	INNER JOIN ViewFIL4030 C1 ON D1.歸屬類別 = C1.製令單別 AND D1.歸屬編號 = C1.製令單號
WHERE
	A.單據類別 = 'C41' AND
	D.製程代碼 = 'C31A' AND 
	A.異動類別 = 'B');

-- Oracle user_views
CREATE VIEW "VIEWFIL404A3A" ("單別", "單號", "序號", "批號", "來源") AS (
SELECT 
	A.單據類別 單別, 
	A.單據編號 單號,
	A.單據序號 序號,
	TO_CHAR(C.文數字4) 批號,
	'1.領用' 來源
FROM 
	FIL0040 A
	INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
	INNER JOIN FIL0041 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號 AND A.單據序號 = C.序號
	INNER JOIN FIL0043 D ON D.條碼 = C.文數字4 AND D.批次匯入 = 1
WHERE
	A.單據類別 = 'C41' AND
	A.異動類別 = 'E' AND
	B.製程代碼 = 'C31A' AND
	A.單據序號 >= 900 AND
	D.料號 LIKE 'B%'

union all
	/*報廢*/
SELECT 
	A.單據類別 單別, 
	A.單據號碼 單號,
	A.單據序號 序號,
	TO_CHAR(A.條碼) 批號,
	'2.報廢' 來源
FROM 
	FIL0044 A
WHERE
	A.條碼 like 'C31A%' AND
	A.序號 = 9999  AND
	A.庫位 = '報廢'
);

-- Oracle user_views
CREATE VIEW "VIEWFIL404A4" ("單別", "單號", "作業日期", "製令單別", "製令單號", "公司代碼", "公司名稱", "訂單單別", "訂單單號", "機台代碼", "機台名稱", "加工別", "本日件數順序", "主旨", "客戶編號", "客戶名稱", "產品編號", "產品名稱", "產品規格", "頭出尾出", "頭出尾出說明", "蠟名稱", "蠟進貨日期", "開始時間", "結束時間", "溶蠟時間", "前置耗時", "總耗時", "加工速度", "簽核系統", "備註", "作業人員", "作業人員姓名", "確認碼", "簽核狀態", "結束", "待補", "改件調機", "生產條件捲數", "流水編號", "填表人", "單位主管流水編號", "填表人姓名", "員工流水編號", "填表日", "最後更新者", "更新者姓名", "最後更新日") AS (                                                                                                                                                      SELECT
	A.單據類別 單別,
	A.單據編號 單號,
	A.單據日期 作業日期,
	A.歸屬類別 製令單別,
	A.歸屬編號 製令單號,
	C.公司代碼,
	C.公司名稱,
	C.訂單單別,
	C.訂單單號,
	B.機台代碼,
	nvl(D.名稱, ' ') 機台名稱,
	decode(B.交貨日期_次批 ,'A','A材','B','B材','C','底邊','D','A側','E','B側',' ') 加工別,
	B.交貨日期_天 本日件數順序,
	A.單據編號||'('||trim(A.單據類別)||')'||'/製令:'||nvl(A.歸屬編號, ' ')||'/'||C.產品名稱 主旨,
	C.客戶編號,
	C.客戶名稱,
	C.產品編號,
	C.產品名稱,
	C.產品規格,
	B.運輸方式 頭出尾出,
	decode(B.運輸方式, 'A', '頭出', 'B', '尾出', 'c', '均可', ' ') 頭出尾出說明,
	B.文字1 蠟名稱,
	A.匯率日期 蠟進貨日期,
	B.時間一 開始時間,
	B.時間五 結束時間,
	B.時間二 溶蠟時間,
	decode(B.時間二,'000000',0,(to_date(to_char(case when B.時間二>B.時間一 then to_date(A.單據日期,'yyyymmdd') else to_date(A.單據日期,'yyyymmdd')+1 end,'yyyymmdd')||B.時間二,'yyyymmddhh24miss')- 
	to_date(trim(A.單據日期)||B.時間一,'yyyymmddhh24miss'))*24) 前置耗時,
	decode(B.時間五,'000000',0,(to_date(to_char(case when B.時間五>B.時間一 then to_date(A.單據日期,'yyyymmdd') else to_date(A.單據日期,'yyyymmdd')+1 end,'yyyymmdd')||B.時間五,'yyyymmddhh24miss')- 
	to_date(trim(A.單據日期)||B.時間一,'yyyymmddhh24miss'))*24) 總耗時,
	B.聯絡人序號 加工速度,
	A.簽核系統, 
	A.備註, 
	A.業務員 作業人員,
	nvl(E.員工姓名,' ') 作業人員姓名, 
	A.確認碼,
	nvl(Z3.簽核狀態, '0') 簽核狀態,
	B.Logical4 結束,
	B.Logical5 待補,
	B.Logical6 改件調機,
	NVL(Z5.印刷米數,0) 生產條件捲數,	
	A.流水編號,
	A.填表人,
	D.單位主管流水編號,
	nvl(Z1.員工姓名,' ') 填表人姓名, 
	nvl(Z1.Serial_Num,' ') 員工流水編號,
	A.填表日, 
	A.最後更新者,
	nvl(Z2.員工姓名,' ') 更新者姓名, 
	A.最後更新日
FROM
	FIL0030 A
	INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
	INNER JOIN ViewFIL4030 C ON A.歸屬類別 = C.製令單別 AND A.歸屬編號 = C.製令單號
	LEFT JOIN ViewFIL310P D ON B.機台代碼 = D.代碼
	LEFT JOIN FIL0010 E ON A.業務員 = E.員工編號
	LEFT JOIN FIL0010 Z1 ON A.填表人 = Z1.員工編號
	LEFT JOIN FIL0010 Z2 ON A.最後更新者 = Z2.員工編號
	LEFT JOIN ViewOfObjProperties Z3 ON A.流水編號 = Z3.單據流水號
	LEFT JOIN FIL0033 Z5 ON A.歸屬類別 = Z5.製令單別 AND A.歸屬編號 = Z5.製令單號 AND Z5.加工別='A'
WHERE
	A.單據類別 = 'C41' AND
	B.製程代碼 = 'C32D' );

-- Oracle user_views
CREATE VIEW "VIEWFIL404A5" ("單別", "單號", "序號", "日期", "前製程編號顯示", "前製程編號", "領料米數", "本製程編號", "上蠟米數", "接頭數量", "合理剔除數", "線內不良數", "線外不良數", "不良剔除數", "本筆結餘", "上蠟前厚度", "上蠟前重量", "上蠟後厚度", "上蠟後重量", "塗佈量", "前製程接頭數", "蠟槽溫度", "前冷卻輪溫度", "後冷卻輪溫度", "壓胴壓力KG", "反頂", "反頂說明", "網點清晰度", "半成品編號", "前製程條碼", "單位代碼", "單位名稱", "庫別代碼", "庫別名稱", "備註說明", "結案碼", "流水編號", "最後更新者", "更新者姓名", "最後更新日") AS (                                                                                                                                                      SELECT 
	A.單據類別 單別, 
	A.單據編號 單號,
	A.單據序號 序號,
	A.異動日期 日期,
	A.前製程編號 前製程編號顯示,
	A.前置單號 前製程編號,
	A.異動數量 領料米數,
	A.產品編號 本製程編號,
	A.異動單價 上蠟米數,
	A.QRNo 接頭數量,
	A.燙金費 合理剔除數,
	A.雷射費 線內不良數,
	A.夾鏈費 線外不良數,
	A.毛重 不良剔除數,
	A.數值1 本筆結餘,
	A.異動金額 上蠟前厚度,
	A.數值2 上蠟前重量,
	A.數值3 上蠟後厚度,
	A.數值4  上蠟後重量,
	A.數值5 塗佈量,
	A.材積 前製程接頭數,
	A.折讓 蠟槽溫度,
	A.製版費 前冷卻輪溫度,
	A.氣閥費 後冷卻輪溫度,
	A.鐵條費 壓胴壓力kg,
	A.前置單別 反頂,
	decode(A.前置單別,'L','左','R','右','B','均有','無') 反頂說明,
	A.相關代碼1 網點清晰度,
	A.文數字1 半成品編號,
	F.文數字4 前製程條碼,
	A.單位代碼,
	nvl(D.名稱, ' ') 單位名稱,
	A.倉庫代碼 庫別代碼,
	nvl(E.名稱, ' ') 庫別名稱,
	A.備註說明,
	A.結案碼,
	A.流水編號,
	A.最後更新者,
	nvl(Z1.員工姓名,' ') 更新者姓名,
	A.最後更新日
FROM 
	FIL0040 A
	INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
	INNER JOIN FIL0041 F ON A.單據類別 = F.單別 AND A.單據編號 = F.單號 AND A.單據序號 = F.序號
	LEFT JOIN ViewFIL310P C ON B.機台代碼 = C.代碼
	LEFT JOIN ViewFIL3103 D ON A.單位代碼 = D.代碼
	LEFT JOIN ViewFIL3106 E ON A.倉庫代碼 = E.代碼
	LEFT JOIN FIL0010 Z1 ON A.最後更新者 = Z1.員工編號
WHERE
	A.單據類別 = 'C41' AND
	A.異動類別 = 'A' AND
	B.製程代碼 = 'C32D' AND
	C.印刷上蠟版銅 = 1);

-- Oracle user_views
CREATE VIEW "VIEWFIL404A5A" ("單別", "單號", "前製程米數", "PLC抓取米數", "合理剔除數", "不良剔除數", "檢品數量", "線外不良剔除數", "線內不良剔除數", "回庫數量") AS (
SELECT 
		A.單據類別 單別, 
		A.單據編號 單號,
		SUM(A.異動數量) 前製程米數,
		SUM(A.異動單價) PLC抓取米數,
		SUM(A.燙金費) 合理剔除數,
		SUM(A.毛重) 不良剔除數,
		SUM(A.贈品數量) 檢品數量,
		SUM(A.雷射費) 線外不良剔除數,
		SUM(A.夾鏈費) 線內不良剔除數,
		SUM(A.退庫數量) 回庫數量
	FROM 
		FIL0040 A
		INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
		LEFT JOIN FIL0041 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號 AND A.單據序號 = C.序號
		LEFT JOIN 
		(
			SELECT 
				A.單據類別,
				A.單據編號,
				SUM(A.贈品數量) 回庫數量
			FROM
				FIL0040 A
				INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
				INNER JOIN FIL0041 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號 AND A.單據序號 = C.序號
			WHERE
				A.單據類別 = 'C41' AND
				A.異動類別= 'G' AND
				B.製程代碼 = 'C32D' AND
				C.標籤列印次數 > 0	
			GROUP BY
				A.單據類別, 
				A.單據編號
		) E ON E.單據類別 = A.單據類別 AND E.單據編號 = A.單據編號
	WHERE
		A.單據類別 = 'C41' AND
		A.異動類別 = 'A' AND
		B.製程代碼 = 'C32D' 
	GROUP BY
		A.單據類別, 
		A.單據編號
);

-- Oracle user_views
CREATE VIEW "VIEWFIL404A6" ("單別", "單號", "作業日期", "主旨", "公司代碼", "公司名稱", "製程代碼", "機台代碼", "機台名稱", "備註", "作業人員", "作業人員姓名", "確認碼", "製令單號", "簽核系統", "簽核狀態", "流水編號", "填表人", "填表人姓名", "填表日", "最後更新者", "更新者姓名", "最後更新日") AS (                                                                                                                                                      SELECT
	A.單據類別 單別,
	A.單據編號 單號,
	A.單據日期 作業日期,
	A.單據編號||'('||trim(A.單據類別)||')' 主旨,
	A.公司代碼,
	nvl(E.名稱, ' ') 公司名稱,
	B.製程代碼,
	B.機台代碼,
	nvl(D.名稱, ' ') 機台名稱,
	A.備註, 
	A.業務員 作業人員,
	nvl(C.員工姓名,' ') 作業人員姓名,
	A.確認碼,
	NVL(F.製令單號,' ') 製令單號, 
	A.簽核系統, 
	nvl(Z3.簽核狀態, '0') 簽核狀態,
	A.流水編號,
	A.填表人,
	nvl(Z1.員工姓名,' ') 填表人姓名, 
	A.填表日, 
	A.最後更新者,
	nvl(Z2.員工姓名,' ') 更新者姓名, 
	A.最後更新日
FROM
	FIL0030 A
	/*特殊欄位*/
	INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
	/* */
	LEFT JOIN FIL0010 C ON A.業務員 = C.員工編號
	LEFT JOIN ViewFIL310P D ON B.機台代碼 = D.代碼
	LEFT JOIN ViewFIL0011 E ON A.公司代碼 = E.代碼
	LEFT JOIN FIL0010 Z1 ON A.填表人 = Z1.員工編號
	LEFT JOIN FIL0010 Z2 ON A.最後更新者 = Z2.員工編號
	LEFT JOIN ViewOfObjProperties Z3 ON A.流水編號 = Z3.單據流水號
	LEFT JOIN 
	(
	SELECT
	A.單據類別,
	A.單據編號,
	listagg
	(	to_char
			(
			trim(A.前置單號)
			), ',') within group (order by A.單據序號) as 製令單號
	FROM
		FIL0040 A 
		INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
	WHERE
		A.單據類別 = 'C41' AND
		A.異動類別 = 'A' AND
		B.製程代碼 = 'C32E'
	group by 
		A.單據類別, 
		A.單據編號
	)F ON F.單據類別=A.單據類別 AND F.單據編號=A.單據編號
WHERE
	A.單據類別 = 'C41' AND
	B.製程代碼 = 'C32E' AND
	D.印刷上蠟版銅 = 2);

-- Oracle user_views
CREATE VIEW "VIEWFIL404A7" ("單別", "單號", "序號", "日期", "製令單別", "製令單號", "對應製令單號", "共版", "版長", "圓周", "版銅代碼", "產品編號", "產品名稱", "產品規格", "說明", "取版回收", "取版或回收", "印刷色數", "內容校對", "清潔度", "不良原因", "不良版序", "處置", "處置說明", "流水編號", "最後更新者", "更新者姓名", "最後更新日") AS (                                                                                                                                                      SELECT 
	A.單據類別 單別, 
	A.單據編號 單號,
	A.單據序號 序號,
	A.異動日期 日期,
	A.前置單別 製令單別,
	A.前置單號 製令單號,
	D.前置單號 對應製令單號,
	F.共版,
	F.版長,
	F.圓周,
	A.產品編號 版銅代碼,
	nvl(D.產品編號, ' ') 產品編號,
	nvl(D.產品名稱, ' ') 產品名稱,
	nvl(F.規格, ' ') 產品規格,
	nvl(F.說明, ' ') 說明,
	A.單位代碼 取版回收,
	decode(A.單位代碼,'A','取版','B','回收',' ') 取版或回收,
	A.Logical1 印刷色數,
	A.Logical2 內容校對,
	A.Logical3 清潔度,
	A.備註說明 不良原因,
	A.異動金額 不良版序,
	A.結案碼 處置,
	decode(A.結案碼,'A','重製','B','重鍍',' ') 處置說明,
	A.流水編號,
	A.最後更新者,
	nvl(Z1.員工姓名,' ') 更新者姓名,
	A.最後更新日
FROM 
	FIL0040 A
	/*特殊欄位*/
	INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
	LEFT JOIN ViewFIL310P C ON B.機台代碼 = C.代碼
	/*製令*/
	INNER JOIN FIL0032 D ON A.前置單別 = D.製令單別 AND A.前置單號 = D.製令單號
	/*版銅*/
	LEFT JOIN ViewFIL3112 F ON A.產品編號 = F.代碼
	LEFT JOIN FIL0010 Z1 ON A.最後更新者 = Z1.員工編號
WHERE
	A.單據類別 = 'C41' AND
	A.異動類別 = 'A' AND
	B.製程代碼 = 'C32E' AND
	C.印刷上蠟版銅 = 2);

-- Oracle user_views
CREATE VIEW "VIEWFIL404A8" ("單別", "單號", "序號", "作業日期", "機台代碼", "機台名稱", "製令單別", "製令單號", "對應製令單號") AS (                                                                                                                                                      SELECT
	A.單據類別 單別,
	A.單據編號 單號,
	D.單據序號 序號,
	A.單據日期 作業日期,
	B.機台代碼,
	nvl(C.名稱, ' ') 機台名稱,
	D.前置單別 製令單別,
	D.前置單號 製令單號,
	D.產品編號 對應製令單號
FROM
	FIL0030 A
	/*特殊欄位*/
	INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
	/* */
	LEFT JOIN ViewFIL310P C ON B.機台代碼 = C.代碼
	/*檢品明細*/
	INNER JOIN FIL0040 D ON A.單據類別 = D.單據類別 AND A.單據編號 = D.單據編號 AND D.異動類別 = 'A'
WHERE
	A.單據類別 = 'C41' AND
	B.製程代碼 = 'C32E' AND
	C.印刷上蠟版銅 = 2);

-- Oracle user_views
CREATE VIEW "VIEWFIL404A9" ("單別", "單號", "製令", "簽收", "簽收人", "簽收人姓名") AS (                                                                                                                                               SELECT 
	A.單別, 
	A.單號,
	A.製令,
	decode(nvl(dbms_lob.getlength(B.圖檔),0),0,0,1) 簽收,
	B.代碼 簽收人,
	nvl(C.員工姓名, ' ') 簽收人姓名
FROM
	(
		SELECT 
			distinct
			A.單據類別 單別, 
			A.單據編號 單號,
			A.前置單號 製令
		FROM 
			FIL0040 A
			/*特殊欄位*/
			INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
			LEFT JOIN ViewFIL310P C ON B.機台代碼 = C.代碼
		WHERE
			A.單據類別 = 'C41' AND
			A.異動類別 = 'A' AND
			A.單位代碼 = 'A' AND 	/*取版*/
			B.製程代碼 = 'C32E' AND
			C.印刷上蠟版銅 = 2
	) A
	LEFT JOIN FIL0037 B ON A.單別 = B.製令單別 AND A.單號 = B.製令單號 AND B.材料序號=0 AND A.製令 = B.屬性
	LEFT JOIN FIL0010 C ON B.代碼 = C.員工編號);

-- Oracle user_views
CREATE VIEW "VIEWFIL404AA" ("單別", "單號", "前製程米數", "PLC抓取米數", "合理剔除數", "不良剔除數", "檢品數量", "線外不良剔除數", "線內不良剔除數", "試刷米數", "回庫數量") AS (
SELECT 
		A.單據類別 單別, 
		A.單據編號 單號,
		SUM(A.異動數量) 前製程米數,
		SUM(decode(C.檢驗外觀,' ',A.異動單價,'A',A.異動單價,0)) PLC抓取米數,
		SUM(A.燙金費) 合理剔除數,
		SUM(A.毛重) 不良剔除數,
		SUM(A.贈品數量) 檢品數量,
		SUM(A.雷射費) 線外不良剔除數,
		SUM(decode(C.檢驗外觀,' ',A.夾鏈費,'A',A.夾鏈費,0)) 線內不良剔除數,
		SUM(A.氣閥費) 試刷米數,
		SUM(A.退庫數量) 回庫數量
	FROM 
		FIL0040 A
		INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
		INNER JOIN FIL0041 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號 AND A.單據序號 = C.序號
		/* 
		LEFT JOIN 
		(
			SELECT 
				A.單據類別,
				A.單據編號,
				SUM(A.贈品數量) 回庫數量
			FROM
				FIL0040 A
				INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
				INNER JOIN FIL0041 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號 AND A.單據序號 = C.序號
			WHERE
				A.單據類別 = 'C41' AND
				A.異動類別= 'G' AND
				B.製程代碼 = 'C31A'	AND
				C.標籤列印次數 > 0
			GROUP BY
				A.單據類別, 
				A.單據編號
		) E ON E.單據類別 = A.單據類別 AND E.單據編號 = A.單據編號
		*/
	WHERE
		A.單據類別 = 'C41' AND
		A.異動類別 = 'A' AND
		B.製程代碼 = 'C31A'
	GROUP BY
		A.單據類別, 
		A.單據編號
);

-- Oracle user_views
CREATE VIEW "VIEWFIL404AB" ("單別", "單號", "主檔序號", "筆數") AS (
SELECT 
	A.單據類別 單別, 
	A.單據編號 單號,
	A.QRNo 主檔序號,
	count(A.單據序號) 筆數
FROM 
	FIL0040 A
	INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
WHERE
	A.單據類別 = 'C41' AND
	A.異動類別 = 'C' AND
	B.製程代碼 = 'C31A'
GROUP BY 
	A.單據類別, 
	A.單據編號,
	A.QRNo
	);

-- Oracle user_views
CREATE VIEW "VIEWFIL404AC" ("單別", "單號", "群組序號", "前一筆結餘", "前製程米數", "PLC抓取米數", "合理剔除數", "不良剔除數", "檢品數量") AS (
SELECT 
		A.單據類別 單別, 
		A.單據編號 單號,
		A.鐵條費 群組序號, 
		SUM(A.數值1) 前一筆結餘,
		SUM(A.異動數量) 前製程米數,
		SUM(A.異動單價) PLC抓取米數,
		SUM(A.燙金費) 合理剔除數,
		SUM(A.毛重) 不良剔除數,
		SUM(A.贈品數量) 檢品數量
	FROM 
		FIL0040 A
		INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
		LEFT JOIN FIL0041 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號 AND A.單據序號 = C.序號
	WHERE
		A.單據類別 = 'C41' AND
		A.異動類別 = 'A' AND
		B.製程代碼 = 'C31A' 
	GROUP BY
		A.單據類別, 
		A.單據編號,
		A.鐵條費
);

-- Oracle user_views
CREATE VIEW "VIEWFIL404AD" ("製令單別", "製令單號", "前製程米數", "PLC抓取米數", "合理剔除數", "不良剔除數", "檢品數量", "線外不良剔除數", "線內不良剔除數", "試刷米數", "回庫數量", "生產條件米數") AS (
SELECT 
		A1.歸屬類別 製令單別, 
		A1.歸屬編號 製令單號,
		SUM(A.異動數量) 前製程米數,
		SUM(A.異動單價) PLC抓取米數,
		SUM(A.燙金費) 合理剔除數,
		SUM(A.毛重) 不良剔除數,
		SUM(A.贈品數量) 檢品數量,
		SUM(A.雷射費) 線外不良剔除數,
		SUM(A.夾鏈費) 線內不良剔除數,
		SUM(A.氣閥費) 試刷米數,
		max(nvl(E.回庫數量,0)) 回庫數量,
		max(nvl(D.印刷米數,0)*1000) 生產條件米數
	FROM 
		FIL0040 A
		INNER JOIN FIL0030 A1 ON A.單據類別 = A1.單據類別 AND A.單據編號 = A1.單據編號
		INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
		LEFT JOIN FIL0041 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號 AND A.單據序號 = C.序號
		LEFT JOIN
		(SELECT 
			F.製令單別, 
			F.製令單號, 
			sum(F.印刷米數) 印刷米數
		FROM 
			FIL0033 F 
		WHERE 
			F.印刷基材<>' ' 
		GROUP BY
			F.製令單別, 
			F.製令單號) D ON D.製令單別 = A1.歸屬類別 AND D.製令單號 = A1.歸屬編號 
		LEFT JOIN 
		(
			SELECT 
				A.單據類別,
				A.單據編號,
				SUM(A.贈品數量) 回庫數量
			FROM
				FIL0040 A
				INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
				INNER JOIN FIL0041 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號 AND A.單據序號 = C.序號
			WHERE
				A.單據類別 = 'C41' AND
				A.異動類別= 'G' AND
				B.製程代碼 = 'C31A'	AND
				C.標籤列印次數 > 0
			GROUP BY
				A.單據類別, 
				A.單據編號
		) E ON E.單據類別 = A.單據類別 AND E.單據編號 = A.單據編號
	WHERE
		A.單據類別 = 'C41' AND
		A.異動類別 = 'A' AND
		B.製程代碼 = 'C31A' 
	GROUP BY
		A1.歸屬類別, 
		A1.歸屬編號
);

-- Oracle user_views
CREATE VIEW "VIEWFIL404AD1" ("單據類別", "單據編號", "改件調機", "製令單別", "製令單號", "前製程米數", "PLC抓取米數", "合理剔除數", "不良剔除數", "檢品數量", "線外不良剔除數", "線內不良剔除數", "試刷米數", "回庫數量", "生產條件米數") AS (
SELECT 
		A.單據類別, 
		A.單據編號,
		B.Logical6 改件調機,
		max(A1.歸屬類別) 製令單別, 
		max(A1.歸屬編號) 製令單號,
		SUM(A.異動數量) 前製程米數,
		SUM(A.異動單價) PLC抓取米數,
		SUM(A.燙金費) 合理剔除數,
		SUM(A.毛重) 不良剔除數,
		SUM(A.贈品數量) 檢品數量,
		SUM(A.雷射費) 線外不良剔除數,
		SUM(A.夾鏈費) 線內不良剔除數,
		SUM(A.氣閥費) 試刷米數,
		max(nvl(E.回庫數量,0)) 回庫數量,
		max(nvl(D.印刷米數,0)*1000) 生產條件米數
	FROM 
		FIL0040 A
		INNER JOIN FIL0030 A1 ON A.單據類別 = A1.單據類別 AND A.單據編號 = A1.單據編號 and A1.歸屬編號<>' '
		INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
		LEFT JOIN FIL0041 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號 AND A.單據序號 = C.序號
		LEFT JOIN
		(SELECT 
			F.製令單別, 
			F.製令單號, 
			sum(F.印刷米數) 印刷米數
		FROM 
			FIL0033 F 
		WHERE 
			F.印刷基材<>' ' 
		GROUP BY
			F.製令單別, 
			F.製令單號
		) D ON D.製令單別 = A1.歸屬類別 AND D.製令單號 = A1.歸屬編號 
		LEFT JOIN 
		(
			SELECT 
				A.單據類別,
				A.單據編號,
				SUM(A.贈品數量) 回庫數量
			FROM
				FIL0040 A
				INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
				INNER JOIN FIL0041 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號 AND A.單據序號 = C.序號
			WHERE
				A.單據類別 = 'C41' AND
				A.異動類別= 'G' AND
				B.製程代碼 = 'C31A'	AND
				C.標籤列印次數 > 0
			GROUP BY
				A.單據類別, 
				A.單據編號
		) E ON E.單據類別 = A.單據類別 AND E.單據編號 = A.單據編號
	WHERE
		A.單據類別 = 'C41' AND
		A.異動類別 = 'A' AND
		B.製程代碼 = 'C31A' 
	GROUP BY
		A.單據類別, 
		A.單據編號,
		B.Logical6
);

-- Oracle user_views
CREATE VIEW "VIEWFIL404AD2" ("單別", "單號", "改件調機", "製令單別", "製令單號", "前製程米數", "PLC抓取米數", "合理剔除數", "不良剔除數", "檢品數量", "線外不良剔除數", "線內不良剔除數", "試刷米數", "回庫數量", "生產條件米數") AS (                                                                                                                                                      SELECT
	A.單據類別 單別,
	A.單據編號 單號,
	B.Logical6 改件調機,
	A.歸屬類別 製令單別, 
	A.歸屬編號 製令單號,
	nvl(Y.前製程米數,0)前製程米數,
	nvl(Y.PLC抓取米數,0)PLC抓取米數,
	nvl(Y.合理剔除數,0)合理剔除數,
	nvl(Y.不良剔除數,0)不良剔除數,
	nvl(Y.檢品數量,0)檢品數量,
	nvl(Y.線外不良剔除數,0)線外不良剔除數,
	nvl(Y.線內不良剔除數,0)線內不良剔除數,
	nvl(Y.試刷米數,0)試刷米數,
	nvl(Y.回庫數量,0)回庫數量,
	nvl(Y.生產條件米數,0)生產條件米數
FROM
	FIL0030 A
	INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
	INNER JOIN ViewFIL404AD1 Y ON A.單據類別 = Y.單據類別 AND A.單據編號 = Y.單據編號
WHERE
	A.單據類別 = 'C41' AND
	B.製程代碼 = 'C31A' AND
	(nvl(Y.前製程米數,0)<>0 OR nvl(Y.PLC抓取米數,0)<>0) );

-- Oracle user_views
CREATE VIEW "VIEWFIL404AE" ("製令單別", "製令單號", "前製程米數", "PLC抓取米數", "合理剔除數", "不良剔除數", "檢品數量", "線外不良剔除數", "線內不良剔除數", "試刷米數", "回庫數量", "生產條件米數") AS (
SELECT 
		A1.歸屬類別 製令單別, 
		A1.歸屬編號 製令單號,
		SUM(A.異動數量) 前製程米數,
		SUM(A.異動單價) PLC抓取米數,
		SUM(A.燙金費) 合理剔除數,
		SUM(A.毛重) 不良剔除數,
		SUM(A.贈品數量) 檢品數量,
		SUM(A.雷射費) 線外不良剔除數,
		SUM(A.夾鏈費) 線內不良剔除數,
		SUM(A.氣閥費) 試刷米數,
		max(nvl(E.回庫數量,0)) 回庫數量,
		max(nvl(D.印刷米數,0)*1000) 生產條件米數
	FROM 
		FIL0040 A
		INNER JOIN FIL0030 A1 ON A.單據類別 = A1.單據類別 AND A.單據編號 = A1.單據編號
		INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
		LEFT JOIN FIL0041 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號 AND A.單據序號 = C.序號
		LEFT JOIN
		(SELECT 
			F.製令單別, 
			F.製令單號, 
			sum(F.印刷米數) 印刷米數
		FROM 
			FIL0033 F 
		WHERE 
			F.印刷基材<>' ' 
		GROUP BY
			F.製令單別, 
			F.製令單號) D ON D.製令單別 = A1.歸屬類別 AND D.製令單號 = A1.歸屬編號 
		LEFT JOIN 
		(
			SELECT 
				A.單據類別,
				A.單據編號,
				SUM(A.贈品數量) 回庫數量
			FROM
				FIL0040 A
				INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
				INNER JOIN FIL0041 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號 AND A.單據序號 = C.序號
			WHERE
				A.單據類別 = 'C41' AND
				A.異動類別= 'G' AND
				B.製程代碼 = 'C32D'	AND
				C.標籤列印次數 > 0
			GROUP BY
				A.單據類別, 
				A.單據編號
		) E ON E.單據類別 = A.單據類別 AND E.單據編號 = A.單據編號
	WHERE
		A.單據類別 = 'C41' AND
		A.異動類別 = 'A' AND
		B.製程代碼 = 'C32D' 
	GROUP BY
		A1.歸屬類別, 
		A1.歸屬編號
);

-- Oracle user_views
CREATE VIEW "VIEWFIL404B1" ("單別", "單號", "作業日期", "製令單別", "製令單號", "加工別", "主旨", "公司代碼", "公司名稱", "訂單單別", "訂單單號", "機台代碼", "機台名稱", "本日件數順序", "客戶編號", "客戶名稱", "產品編號", "產品名稱", "產品規格", "待補", "結束", "改件調機", "側", "基材", "打樣", "生產條件捲數", "基材名稱", "基材規格", "中間材", "中間材名稱", "中間材規格", "副材", "副材名稱", "副材規格", "貼合日期", "開始時間", "接班時間", "損耗時間", "貼合時間", "結束時間", "收拾時間", "前置耗時", "總耗時", "損耗人員", "貼合人員", "結束人員", "收拾人員", "貼合速度", "冷卻輪溫度", "版目前", "版目後", "配比1", "配比2", "配比3", "配比4", "配比5", "配比6", "前槽接著劑", "前槽硬化劑", "前槽溶劑", "後槽接著劑", "後槽硬化劑", "後槽溶劑", "簽核系統", "備註", "作業人員", "作業人員姓名", "確認碼", "簽核狀態", "流水編號", "填表人", "單位主管流水編號", "員工流水編號", "填表人姓名", "填表日", "CCP筆數", "最後更新者", "更新者姓名", "最後更新日", "沿用單號") AS (                                                                                                                                                      SELECT
	A.單據類別 單別,
	A.單據編號 單號,
	A.單據日期 作業日期,
	A.歸屬類別 製令單別,
	A.歸屬編號 製令單號,
	decode(B.交貨日期_次批 ,'A','A材','B','B材','C','底邊','D','A側','E','B側',' ') 加工別,
	A.單據編號||'('||trim(A.單據類別)||')'||'/製令:'||nvl(A.歸屬編號, ' ')||'/'||C.產品名稱 主旨,
	C.公司代碼,
	C.公司名稱,
	C.訂單單別,
	C.訂單單號,
	B.機台代碼,
	nvl(D.名稱, ' ') 機台名稱,
	B.交貨日期_天 本日件數順序,
	C.客戶編號,
	C.客戶名稱,
	C.產品編號,
	C.產品名稱,
	C.產品規格,
	B.Logical4 待補,
	B.Logical5 結束,
	B.Logical6 改件調機,
	B.回簽 側,
	B.材料編號一 基材,
	0 打樣,
	NVL(Z5.印刷米數,0) 生產條件捲數,
	nvl(F.品名, ' ') 基材名稱,
	nvl(F.規格, ' ') 基材規格,
	B.材料編號二 中間材,
	nvl(G.品名, ' ') 中間材名稱,
	nvl(G.規格, ' ') 中間材規格,
	B.材料編號三 副材,
	nvl(H.品名, ' ') 副材名稱,
	nvl(H.規格, ' ') 副材規格,
	to_char(case when B.時間四>B.時間一 then to_date(A.單據日期,'yyyymmdd') else to_date(A.單據日期,'yyyymmdd')+1 end,'yyyymmdd') 貼合日期,
	B.時間一 開始時間,
	B.時間二 接班時間,
	B.時間三 損耗時間,
	B.時間四 貼合時間,
	B.時間五 結束時間,
	B.時間六 收拾時間,
	decode(B.時間四,'000000',0,(to_date(to_char(case when B.時間四>B.時間一 then to_date(A.單據日期,'yyyymmdd') else to_date(A.單據日期,'yyyymmdd')+1 end,'yyyymmdd')||B.時間四,'yyyymmddhh24miss')- 
	to_date(trim(A.單據日期)||B.時間一,'yyyymmddhh24miss'))*24) 前置耗時,
	decode(B.時間五,'000000',0,(to_date(to_char(case when B.時間五>B.時間一 then to_date(A.單據日期,'yyyymmdd') else to_date(A.單據日期,'yyyymmdd')+1 end,'yyyymmdd')||B.時間五,'yyyymmddhh24miss')- 
	to_date(trim(A.單據日期)||B.時間一,'yyyymmddhh24miss'))*24) 總耗時,
	B.訂金 損耗人員,
	B.票期 貼合人員,
	B.送貨地址序號 結束人員,
	B.聯絡人序號 收拾人員,
	B.數量 貼合速度,
	B.數值1 冷卻輪溫度,
	B.數值2 版目前,
	B.數值3 版目後,
	B.數值4 配比1,
	B.數值5 配比2,
	B.數值6 配比3,
	B.數值7 配比4,
	B.數值8 配比5,
	B.數值9 配比6,
	B.文字1 前槽接著劑,
	B.文字2 前槽硬化劑,
	B.文字3 前槽溶劑,
	B.文字4 後槽接著劑,
	B.文字5 後槽硬化劑,
	B.文字6 後槽溶劑,
	A.簽核系統, 
	A.備註, 
	A.業務員 作業人員,
	nvl(E.員工姓名,' ') 作業人員姓名,
	A.確認碼,
	nvl(Z3.簽核狀態, '0') 簽核狀態,
	A.流水編號,
	A.填表人,
	D.單位主管流水編號,
	nvl(Z1.Serial_Num,' ') 員工流水編號,
	nvl(Z1.員工姓名,' ') 填表人姓名, 
	A.填表日, 
	NVL(J.CCP筆數,0) CCP筆數,
	A.最後更新者,
	nvl(Z2.員工姓名,' ') 更新者姓名, 
	A.最後更新日,
	A.採購單號 沿用單號
FROM
	FIL0030 A
	INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
	/*製令*/
	INNER JOIN ViewFIL4030 C ON A.歸屬類別 = C.製令單別 AND A.歸屬編號 = C.製令單號
	LEFT JOIN ViewFIL310P D ON B.機台代碼 = D.代碼
	LEFT JOIN FIL0010 E ON A.業務員 = E.員工編號
	LEFT JOIN FIL0012 F ON B.材料編號一 = F.產品編號
	LEFT JOIN FIL0012 G ON B.材料編號二 = G.產品編號
	LEFT JOIN FIL0012 H ON B.材料編號三 = H.產品編號
	LEFT JOIN FIL0010 Z1 ON A.填表人 = Z1.員工編號
	LEFT JOIN FIL0010 Z2 ON A.最後更新者 = Z2.員工編號
	LEFT JOIN ViewOfObjProperties Z3 ON A.流水編號 = Z3.單據流水號
	LEFT JOIN FIL0033 Z5 ON A.歸屬類別 = Z5.製令單別 AND A.歸屬編號 = Z5.製令單號 AND Z5.加工別='A'
	LEFT JOIN 
	(SELECT A.單別,A.單號,COUNT(序號) CCP筆數 FROM FIL004I A GROUP BY A.單別,A.單號) J ON J.單別=A.單據類別 AND J.單號=A.單據編號
WHERE
	A.單據類別 = 'C41' AND
	B.製程代碼 = 'C31B');

-- Oracle user_views
CREATE VIEW "VIEWFIL404B1A" ("單別", "單號", "序號", "作業日期", "沿用編號", "已被沿用") AS (
/*沿用打勾的日報領料*/
SELECT
	A.單據類別 單別,
	A.單據編號 單號,
	A.單據序號 序號,
	C.單據日期 作業日期,
	NVL(M.沿用編號,0) 沿用編號,
	DECODE(NVL(M.沿用編號,0),0,0,1) 已被沿用
FROM
	FIL0040 A
	INNER JOIN FIL0030 C ON A.單據類別 = C.單據類別 AND A.單據編號 = C.單據編號
	INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
	LEFT JOIN 
	(
	/*單頭沿用日報*/
	SELECT 
		M.採購單號,
		MAX(M.單據編號) 沿用編號
	FROM
		FIL0030 M
		INNER JOIN FIL0031 B ON M.單據類別 = B.單別 AND M.單據編號 = B.單號
	WHERE
		M.單據類別='C41' AND 
		B.製程代碼 = 'C31B'
	GROUP BY
		M.採購單號
		) M ON	M.採購單號=A.單據編號
WHERE
	A.單據類別 = 'C41' AND
	B.製程代碼 = 'C31B' AND
	A.異動類別 = 'C' AND 
	A.Logical1 = 1
	);

-- Oracle user_views
CREATE VIEW "VIEWFIL404B2" ("單別", "單號", "序號", "日期", "前製程編號顯示", "前製程編號", "群組序號", "前製程接頭數", "前製程米數", "前一筆結餘數", "本製程編號顯示", "PLC抓取米數", "合理剔除數", "線外剔除數", "線內剔除數", "加工前測量", "檢品米數", "製品厚度", "接頭數量", "加工後測量", "不良剔除米數", "PLC抓取日期", "PLC抓取時間", "合併編號", "檢品編號", "印刷色數", "不良原因", "編號項目", "字圖清晰度", "是否符合", "清除", "材料分派數", "貼合面", "CCP", "AL", "VM", "紙", "單位代碼", "單位名稱", "庫別代碼", "庫別名稱", "結案碼", "熟成條件", "前製程條碼", "流水編號", "最後更新者", "更新者姓名", "最後更新日") AS (  
SELECT 
	A.單據類別 單別, 
	A.單據編號 單號,
	A.單據序號 序號,
	A.異動日期 日期,
	A.前製程編號 前製程編號顯示,
	A.前置單號 前製程編號,
	A.鐵條費 群組序號,
	A.材積 前製程接頭數,
	A.異動數量 前製程米數,
	A.數值1 前一筆結餘數,	
	A.產品編號 本製程編號顯示,
	A.異動單價 PLC抓取米數,	
	A.燙金費 合理剔除數,
	A.雷射費 線外剔除數,
	A.夾鏈費 線內剔除數,
	A.數值2 加工前測量,
	A.贈品數量 檢品米數,
	A.數值3 製品厚度,
	A.折扣率 接頭數量,
	A.氣閥費 加工後測量,
	A.毛重 不良剔除米數,
	A.其它日期 PLC抓取日期,
	A.TIME1 PLC抓取時間,
	A.合併編號 合併編號,
	A.文數字1 檢品編號,
	A.異動金額 印刷色數,
	A.備註說明 不良原因,
	A.Logical2 編號項目,
	A.結案碼 字圖清晰度,
	A.Logical1 是否符合,
	A.Logical3 清除,
	NVL(F.材料分派數,0) 材料分派數,
	C.檢驗外觀 貼合面,
	C.檢驗清潔度 CCP,
	C.檢驗顏色 AL,
	C.檢驗尺寸 VM,
	C.檢驗厚度 紙,
	A.單位代碼,
	nvl(D.名稱, ' ') 單位名稱,
	A.倉庫代碼 庫別代碼,
	nvl(E.名稱, ' ') 庫別名稱,
	A.結案碼,
	B.文字4 熟成條件,
	C.文數字4 前製程條碼,
	A.流水編號,
	A.最後更新者,
	nvl(Z1.員工姓名,' ') 更新者姓名,
	A.最後更新日
FROM 
	FIL0040 A
	INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
	INNER JOIN FIL0041 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號 AND A.單據序號 = C.序號
	LEFT JOIN ViewFIL3103 D ON A.單位代碼 = D.代碼
	LEFT JOIN ViewFIL3106 E ON A.倉庫代碼 = E.代碼
	LEFT JOIN FIL0010 Z1 ON A.最後更新者 = Z1.員工編號
	LEFT JOIN 
    (
	SELECT 
		A.單別,
		A.單號,
		A.數字一,
		SUM(NVL(A.數字二,0)) 材料分派數
	FROM 
		FIL00401 A
		INNER JOIN FIL0040 B ON B.單據類別 = A.單別 AND B.單據編號 = A.單號 AND B.單據序號 = A.序號
		INNER JOIN FIL0031 C ON C.單別 = A.單別 AND C.單號 = A.單號
	WHERE
		A.單別 = 'C41' AND
		B.異動類別 = 'C' AND
		C.製程代碼 = 'C31C'
	GROUP BY
		A.單別,
		A.單號,
		A.數字一
	)F ON F.單別=A.單據類別 AND F.單號=A.單據編號 AND F.數字一=A.單據序號
WHERE
	A.單據類別 = 'C41' AND
	A.異動類別 = 'A' AND
	B.製程代碼 = 'C31B');

-- Oracle user_views
CREATE VIEW "VIEWFIL404B3" ("單別", "單號", "主檔序號", "筆數") AS (
SELECT 
	A.單據類別 單別, 
	A.單據編號 單號,
	A.QRNo 主檔序號,
	count(A.單據序號) 筆數
FROM 
	FIL0040 A
	INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
WHERE
	A.單據類別 = 'C41' AND
	A.異動類別 = 'C' AND
	B.製程代碼 = 'C31B'
GROUP BY 
	A.單據類別, 
	A.單據編號,
	A.QRNo
	);

-- Oracle user_views
CREATE VIEW "VIEWFIL404BA" ("單別", "單號", "前製程米數", "PLC抓取米數", "合理剔除數", "不良剔除數", "檢品數量", "線外不良剔除數", "線內不良剔除數", "試刷米數", "回庫數量") AS (
SELECT 
		A.單據類別 單別, 
		A.單據編號 單號,
		SUM(A.異動數量) 前製程米數,
		SUM(A.異動單價) PLC抓取米數,
		SUM(A.燙金費) 合理剔除數,
		SUM(A.毛重) 不良剔除數,
		SUM(A.贈品數量) 檢品數量,
		SUM(A.雷射費) 線外不良剔除數,
		SUM(A.夾鏈費) 線內不良剔除數,
		SUM(A.氣閥費) 試刷米數,
		max(nvl(E.回庫數量,0))+SUM(A.退庫數量) 回庫數量
	FROM 
		FIL0040 A
		INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
		LEFT JOIN FIL0041 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號 AND A.單據序號 = C.序號
		LEFT JOIN 
		(
			SELECT 
				A.單據類別,
				A.單據編號,
				SUM(A.贈品數量) 回庫數量
			FROM
				FIL0040 A
				INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
				INNER JOIN FIL0041 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號 AND A.單據序號 = C.序號
			WHERE
				A.單據類別 = 'C41' AND
				A.異動類別= 'G' AND
				B.製程代碼 = 'C31B'	AND
				C.標籤列印次數 > 0
			GROUP BY
				A.單據類別, 
				A.單據編號
		) E ON E.單據類別 = A.單據類別 AND E.單據編號 = A.單據編號
	WHERE
		A.單據類別 = 'C41' AND
		A.異動類別 = 'A' AND
		B.製程代碼 = 'C31B' 
	GROUP BY
		A.單據類別, 
		A.單據編號
);

-- Oracle user_views
CREATE VIEW "VIEWFIL404BB" ("單別", "單號", "群組序號", "前一筆結餘", "前製程米數", "PLC抓取米數", "合理剔除數", "不良剔除數", "檢品數量") AS (
SELECT 
		A.單據類別 單別, 
		A.單據編號 單號,
		A.鐵條費 群組序號, 
		SUM(A.數值1) 前一筆結餘,
		SUM(A.異動數量) 前製程米數,
		SUM(A.異動單價) PLC抓取米數,
		SUM(A.燙金費) 合理剔除數,
		SUM(A.毛重) 不良剔除數,
		SUM(A.贈品數量) 檢品數量
	FROM 
		FIL0040 A
		INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
		LEFT JOIN FIL0041 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號 AND A.單據序號 = C.序號
	WHERE
		A.單據類別 = 'C41' AND
		A.異動類別 = 'A' AND
		B.製程代碼 = 'C31B' 
	GROUP BY
		A.單據類別, 
		A.單據編號,
		A.鐵條費
);

-- Oracle user_views
CREATE VIEW "VIEWFIL404BD" ("製令單別", "製令單號", "前製程米數", "PLC抓取米數", "合理剔除數", "不良剔除數", "檢品數量", "線外不良剔除數", "線內不良剔除數", "試刷米數", "回庫數量", "生產條件米數") AS (
SELECT 
		A1.歸屬類別 製令單別, 
		A1.歸屬編號 製令單號,
		SUM(A.異動數量) 前製程米數,
		SUM(A.異動單價) PLC抓取米數,
		SUM(A.燙金費) 合理剔除數,
		SUM(A.毛重) 不良剔除數,
		SUM(A.贈品數量) 檢品數量,
		SUM(A.雷射費) 線外不良剔除數,
		SUM(A.夾鏈費) 線內不良剔除數,
		SUM(A.氣閥費) 試刷米數,
		max(nvl(E.回庫數量,0)) 回庫數量,
		max(nvl(D.印刷米數,0)*1000) 生產條件米數
	FROM 
		FIL0040 A
		INNER JOIN FIL0030 A1 ON A.單據類別 = A1.單據類別 AND A.單據編號 = A1.單據編號
		INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
		LEFT JOIN FIL0041 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號 AND A.單據序號 = C.序號
		LEFT JOIN
		(SELECT 
			F.製令單別, 
			F.製令單號, 
			sum(F.印刷米數) 印刷米數
		FROM 
			FIL0033 F 
		WHERE 
			F.印刷基材<>' ' 
		GROUP BY
			F.製令單別, 
			F.製令單號) D ON D.製令單別 = A1.歸屬類別 AND D.製令單號 = A1.歸屬編號 
		LEFT JOIN 
		(
			SELECT 
				A.單據類別,
				A.單據編號,
				SUM(A.贈品數量) 回庫數量
			FROM
				FIL0040 A
				INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
				INNER JOIN FIL0041 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號 AND A.單據序號 = C.序號
			WHERE
				A.單據類別 = 'C41' AND
				A.異動類別= 'G' AND
				B.製程代碼 = 'C31B'	AND
				C.標籤列印次數 > 0
			GROUP BY
				A.單據類別, 
				A.單據編號
		) E ON E.單據類別 = A.單據類別 AND E.單據編號 = A.單據編號
	WHERE
		A.單據類別 = 'C41' AND
		A.異動類別 = 'A' AND
		B.製程代碼 = 'C31B' 
	GROUP BY
		A1.歸屬類別, 
		A1.歸屬編號
);

-- Oracle user_views
CREATE VIEW "VIEWFIL404BD1" ("單據類別", "單據編號", "改件調機", "製令單別", "製令單號", "前製程米數", "PLC抓取米數", "合理剔除數", "不良剔除數", "檢品數量", "線外不良剔除數", "線內不良剔除數", "試刷米數", "回庫數量", "生產條件米數") AS (
SELECT 
		A.單據類別, 
		A.單據編號,
		B.Logical6 改件調機,
		max(A1.歸屬類別) 製令單別, 
		max(A1.歸屬編號) 製令單號,
		SUM(A.異動數量) 前製程米數,
		SUM(A.異動單價) PLC抓取米數,
		SUM(A.燙金費) 合理剔除數,
		SUM(A.毛重) 不良剔除數,
		SUM(A.贈品數量) 檢品數量,
		SUM(A.雷射費) 線外不良剔除數,
		SUM(A.夾鏈費) 線內不良剔除數,
		SUM(A.氣閥費) 試刷米數,
		max(nvl(E.回庫數量,0)) 回庫數量,
		max(nvl(D.印刷米數,0)*1000) 生產條件米數
	FROM 
		FIL0040 A
		INNER JOIN FIL0030 A1 ON A.單據類別 = A1.單據類別 AND A.單據編號 = A1.單據編號 and A1.歸屬編號<>' '
		INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
		LEFT JOIN FIL0041 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號 AND A.單據序號 = C.序號
		LEFT JOIN
		(SELECT 
			F.製令單別, 
			F.製令單號, 
			sum(F.印刷米數) 印刷米數
		FROM 
			FIL0033 F 
		WHERE 
			F.印刷基材<>' ' 
		GROUP BY
			F.製令單別, 
			F.製令單號
		) D ON D.製令單別 = A1.歸屬類別 AND D.製令單號 = A1.歸屬編號 
		LEFT JOIN 
		(
			SELECT 
				A.單據類別,
				A.單據編號,
				SUM(A.贈品數量) 回庫數量
			FROM
				FIL0040 A
				INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
				INNER JOIN FIL0041 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號 AND A.單據序號 = C.序號
			WHERE
				A.單據類別 = 'C41' AND
				A.異動類別= 'G' AND
				B.製程代碼 = 'C31B'	AND
				C.標籤列印次數 > 0
			GROUP BY
				A.單據類別, 
				A.單據編號
		) E ON E.單據類別 = A.單據類別 AND E.單據編號 = A.單據編號
	WHERE
		A.單據類別 = 'C41' AND
		A.異動類別 = 'A' AND
		B.製程代碼 = 'C31B' 
	GROUP BY
		A.單據類別, 
		A.單據編號,
		B.Logical6
);

-- Oracle user_views
CREATE VIEW "VIEWFIL404C1" ("單別", "單號", "作業日期", "製令單別", "製令單號", "加工別", "主旨", "公司代碼", "公司名稱", "訂單單別", "訂單單號", "機台代碼", "機台名稱", "本日件數順序", "客戶編號", "客戶名稱", "產品編號", "產品名稱", "產品規格", "待補", "結束", "改件調機", "側", "基材", "基材名稱", "基材規格", "中間材", "中間材名稱", "中間材規格", "副材", "副材名稱", "副材規格", "打樣", "生產條件捲數", "貼合日期", "開始時間", "接班時間", "損耗時間", "貼合時間", "結束時間", "收拾時間", "前置耗時", "總耗時", "損耗人員", "貼合人員", "結束人員", "收拾人員", "貼合速度", "冷卻輪溫度", "版目前", "版目後", "配比1", "配比2", "配比3", "配比4", "配比5", "配比6", "前槽接著劑", "前槽硬化劑", "前槽溶劑", "後槽接著劑", "後槽硬化劑", "後槽溶劑", "電暈", "簽核系統", "備註", "作業人員", "作業人員姓名", "確認碼", "簽核狀態", "流水編號", "填表人", "單位主管流水編號", "員工流水編號", "填表人姓名", "填表日", "CCP筆數", "最後更新者", "更新者姓名", "最後更新日", "沿用單號") AS (                                                                                                                                                      SELECT
	A.單據類別 單別,
	A.單據編號 單號,
	A.單據日期 作業日期,
	A.歸屬類別 製令單別,
	A.歸屬編號 製令單號,
	decode(B.交貨日期_次批 ,'A','A材','B','B材','C','底邊','D','A側','E','B側',' ') 加工別,
	A.單據編號||'('||trim(A.單據類別)||')'||'/製令:'||nvl(A.歸屬編號, ' ')||'/'||C.產品名稱 主旨,
	C.公司代碼,
	C.公司名稱,
	C.訂單單別,
	C.訂單單號,
	B.機台代碼,
	nvl(D.名稱, ' ') 機台名稱,
	B.交貨日期_天 本日件數順序,
	C.客戶編號,
	C.客戶名稱,
	C.產品編號,
	C.產品名稱,
	C.產品規格,
	B.Logical4 待補,
	B.Logical5 結束,
	B.Logical6 改件調機,
	B.回簽 側,
	B.材料編號一 基材,
	nvl(F.品名, ' ') 基材名稱,
	nvl(F.規格, ' ') 基材規格,
	B.材料編號二 中間材,
	nvl(G.品名, ' ') 中間材名稱,
	nvl(G.規格, ' ') 中間材規格,
	B.材料編號三 副材,
	nvl(H.品名, ' ') 副材名稱,
	nvl(H.規格, ' ') 副材規格,
	0 打樣,
	NVL(Z5.印刷米數,0) 生產條件捲數,
	to_char(case when B.時間四>B.時間一 then to_date(A.單據日期,'yyyymmdd') else to_date(A.單據日期,'yyyymmdd')+1 end,'yyyymmdd') 貼合日期,
	B.時間一 開始時間,
	B.時間二 接班時間,
	B.時間三 損耗時間,
	B.時間四 貼合時間,
	B.時間五 結束時間,
	B.時間六 收拾時間,
	decode(B.時間四,'000000',0,(to_date(to_char(case when B.時間四>B.時間一 then to_date(A.單據日期,'yyyymmdd') else to_date(A.單據日期,'yyyymmdd')+1 end,'yyyymmdd')||B.時間四,'yyyymmddhh24miss')- 
	to_date(trim(A.單據日期)||B.時間一,'yyyymmddhh24miss'))*24) 前置耗時,
	decode(B.時間五,'000000',0,(to_date(to_char(case when B.時間五>B.時間一 then to_date(A.單據日期,'yyyymmdd') else to_date(A.單據日期,'yyyymmdd')+1 end,'yyyymmdd')||B.時間五,'yyyymmddhh24miss')- 
	to_date(trim(A.單據日期)||B.時間一,'yyyymmddhh24miss'))*24) 總耗時,
	B.訂金 損耗人員,
	B.票期 貼合人員,
	B.送貨地址序號 結束人員,
	B.聯絡人序號 收拾人員,
	B.數量 貼合速度,
	B.數值1 冷卻輪溫度,
	B.數值2 版目前,
	B.數值3 版目後,
	B.數值4 配比1,
	B.數值5 配比2,
	B.數值6 配比3,
	B.數值7 配比4,
	B.數值8 配比5,
	B.數值9 配比6,
	B.文字1 前槽接著劑,
	B.文字2 前槽硬化劑,
	B.文字3 前槽溶劑,
	B.文字4 後槽接著劑,
	B.文字5 後槽硬化劑,
	B.文字6 後槽溶劑,
	B.Logical7 電暈,
	A.簽核系統, 
	A.備註, 
	A.業務員 作業人員,
	nvl(E.員工姓名,' ') 作業人員姓名,
	A.確認碼,
	nvl(Z3.簽核狀態, '0') 簽核狀態,
	A.流水編號,
	A.填表人,
	D.單位主管流水編號,
	nvl(Z1.Serial_Num,' ') 員工流水編號,
	nvl(Z1.員工姓名,' ') 填表人姓名, 
	A.填表日, 
	NVL(J.CCP筆數,0) CCP筆數,
	A.最後更新者,
	nvl(Z2.員工姓名,' ') 更新者姓名, 
	A.最後更新日,
	A.採購單號 沿用單號
FROM
	FIL0030 A
	INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
	/*製令*/
	INNER JOIN ViewFIL4030 C ON A.歸屬類別 = C.製令單別 AND A.歸屬編號 = C.製令單號
	LEFT JOIN ViewFIL310P D ON B.機台代碼 = D.代碼
	LEFT JOIN FIL0010 E ON A.業務員 = E.員工編號
	LEFT JOIN FIL0012 F ON B.材料編號一 = F.產品編號
	LEFT JOIN FIL0012 G ON B.材料編號二 = G.產品編號
	LEFT JOIN FIL0012 H ON B.材料編號三 = H.產品編號
	LEFT JOIN FIL0010 Z1 ON A.填表人 = Z1.員工編號
	LEFT JOIN FIL0010 Z2 ON A.最後更新者 = Z2.員工編號
	LEFT JOIN ViewOfObjProperties Z3 ON A.流水編號 = Z3.單據流水號
	LEFT JOIN FIL0033 Z5 ON A.歸屬類別 = Z5.製令單別 AND A.歸屬編號 = Z5.製令單號 AND Z5.加工別='A'
	LEFT JOIN 
	(SELECT A.單別,A.單號,COUNT(序號) CCP筆數 FROM FIL004I A GROUP BY A.單別,A.單號) J ON J.單別=A.單據類別 AND J.單號=A.單據編號
WHERE
	A.單據類別 = 'C41' AND
	B.製程代碼 = 'C31C');

-- Oracle user_views
CREATE VIEW "VIEWFIL404C1A" ("單別", "單號", "序號", "作業日期", "沿用編號", "已被沿用") AS (
/*沿用打勾的日報領料*/
SELECT
	A.單據類別 單別,
	A.單據編號 單號,
	A.單據序號 序號,
	C.單據日期 作業日期,
	NVL(M.沿用編號,0) 沿用編號,
	DECODE(NVL(M.沿用編號,0),0,0,1) 已被沿用
FROM
	FIL0040 A
	INNER JOIN FIL0030 C ON A.單據類別 = C.單據類別 AND A.單據編號 = C.單據編號
	INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
	LEFT JOIN 
	(
	/*單頭沿用日報*/
	SELECT 
		M.採購單號,
		MAX(M.單據編號) 沿用編號
	FROM
		FIL0030 M
		INNER JOIN FIL0031 B ON M.單據類別 = B.單別 AND M.單據編號 = B.單號
	WHERE
		M.單據類別='C41' AND 
		B.製程代碼 = 'C31C'
	GROUP BY
		M.採購單號
		) M ON	M.採購單號=A.單據編號
WHERE
	A.單據類別 = 'C41' AND
	B.製程代碼 = 'C31C' AND
	A.異動類別 = 'C' AND 
	A.Logical1 = 1
	);

-- Oracle user_views
CREATE VIEW "VIEWFIL404C2" ("單別", "單號", "序號", "日期", "前製程編號顯示", "前製程編號", "群組序號", "前製程接頭數", "前製程米數", "前一筆結餘數", "本製程編號顯示", "PLC抓取米數", "合理剔除數", "線外剔除數", "線內剔除數", "加工前測量", "檢品米數", "製品厚度", "接頭數量", "加工後測量", "不良剔除米數", "PLC抓取日期", "PLC抓取時間", "合併編號", "檢品編號", "印刷色數", "不良原因", "編號項目", "字圖清晰度", "是否符合", "清除", "材料分派數", "貼合面", "CCP", "AL", "VM", "紙", "單位代碼", "單位名稱", "庫別代碼", "庫別名稱", "結案碼", "熟成條件", "前製程條碼", "流水編號", "最後更新者", "更新者姓名", "最後更新日") AS (  
SELECT 
	A.單據類別 單別, 
	A.單據編號 單號,
	A.單據序號 序號,
	A.異動日期 日期,
	A.前製程編號 前製程編號顯示,
	A.前置單號 前製程編號,
	A.鐵條費 群組序號,
	A.材積 前製程接頭數,
	A.異動數量 前製程米數,
	A.數值1 前一筆結餘數,	
	A.產品編號 本製程編號顯示,
	A.異動單價 PLC抓取米數,	
	A.燙金費 合理剔除數,
	A.雷射費 線外剔除數,
	A.夾鏈費 線內剔除數,
	A.數值2 加工前測量,
	A.贈品數量 檢品米數,
	A.數值3 製品厚度,
	A.折扣率 接頭數量,
	A.氣閥費 加工後測量,
	A.毛重 不良剔除米數,
	A.其它日期 PLC抓取日期,
	A.TIME1 PLC抓取時間,
	A.合併編號 合併編號,
	A.文數字1 檢品編號,
	A.異動金額 印刷色數,
	A.備註說明 不良原因,
	A.Logical2 編號項目,
	A.結案碼 字圖清晰度,
	A.Logical1 是否符合,
	A.Logical3 清除,
	NVL(F.材料分派數,0) 材料分派數,
	C.檢驗外觀 貼合面,
	C.檢驗清潔度 CCP,
	C.檢驗顏色 AL,
	C.檢驗尺寸 VM,
	C.檢驗厚度 紙,
	A.單位代碼,
	nvl(D.名稱, ' ') 單位名稱,
	A.倉庫代碼 庫別代碼,
	nvl(E.名稱, ' ') 庫別名稱,
	A.結案碼,
	B.文字4 熟成條件,
	C.文數字4 前製程條碼,
	A.流水編號,
	A.最後更新者,
	nvl(Z1.員工姓名,' ') 更新者姓名,
	A.最後更新日
FROM 
	FIL0040 A
	INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
	INNER JOIN FIL0041 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號 AND A.單據序號 = C.序號
	LEFT JOIN ViewFIL3103 D ON A.單位代碼 = D.代碼
	LEFT JOIN ViewFIL3106 E ON A.倉庫代碼 = E.代碼
	LEFT JOIN FIL0010 Z1 ON A.最後更新者 = Z1.員工編號
	LEFT JOIN 
    (
	SELECT 
		A.單別,
		A.單號,
		A.數字一,
		SUM(NVL(A.數字二,0)) 材料分派數
	FROM 
		FIL00401 A
		INNER JOIN FIL0040 B ON B.單據類別 = A.單別 AND B.單據編號 = A.單號 AND B.單據序號 = A.序號
		INNER JOIN FIL0031 C ON C.單別 = A.單別 AND C.單號 = A.單號
	WHERE
		A.單別 = 'C41' AND
		B.異動類別 = 'C' AND
		C.製程代碼 = 'C31C'
	GROUP BY
		A.單別,
		A.單號,
		A.數字一
	)F ON F.單別=A.單據類別 AND F.單號=A.單據編號 AND F.數字一=A.單據序號
WHERE
	A.單據類別 = 'C41' AND
	A.異動類別 = 'A' AND
	B.製程代碼 = 'C31C');

-- Oracle user_views
CREATE VIEW "VIEWFIL404C3" ("單別", "單號", "主檔序號", "筆數") AS (
SELECT 
	A.單據類別 單別, 
	A.單據編號 單號,
	A.QRNo 主檔序號,
	count(A.單據序號) 筆數
FROM 
	FIL0040 A
	INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
WHERE
	A.單據類別 = 'C41' AND
	A.異動類別 = 'C' AND
	B.製程代碼 = 'C31C'
GROUP BY 
	A.單據類別, 
	A.單據編號,
	A.QRNo
	);

-- Oracle user_views
CREATE VIEW "VIEWFIL404C4" ("單別", "單號", "序號", "製令類別", "製令單號", "產品編號", "產品名稱", "熟成入庫日期", "熟成入庫時間", "熟成出庫日期", "熟成出庫時間", "不限出庫時間", "熟成狀態", "入庫狀態", "出庫狀態", "應出庫日時起", "應出庫日時迄", "應入庫日時", "本製程編號", "PLC抓取米數", "庫存數", "製品厚度", "熟成條件", "可提早出庫", "入庫人員姓名", "出庫人員姓名", "放行人員姓名", "不限出庫設定姓名", "製程", "IP位址", "熟成室位置", "加工別", "超時未入庫", "異常", "重覆入庫", "單頭流水編號", "來源") AS (  
SELECT 
	A.單據類別 單別, 
	A.單據編號 單號,
	A.單據序號 序號,
	C.歸屬類別 製令類別,
	C.歸屬編號 製令單號,
	D.產品編號 產品編號,
	D.產品名稱 產品名稱,
	A.異動日期 熟成入庫日期,
	B.Time3 熟成入庫時間,
	A.預交日 熟成出庫日期,
	B.Time4 熟成出庫時間,
	DECODE(E.Logical2 + B.Logical2,0,0,1) 不限出庫時間,
	nvl(case
		 when A.Logical5 = 1 and A.預交日 > '00000000' then '4' 
		 when A.Logical5 = 1 and A.異動日期 > '00000000' and A.預交日 <= '00000000' then '2' 
		 when A.異動日期 <= '00000000' and sysdate > to_date(trim(B.標籤列印日期一)||trim(B.標籤列印時間一), 'YYYYMMDDHH24:MI:SS') + 1/24 then '1' 
	     when A.異動日期 > '00000000' and A.預交日 <= '00000000' then '2'
		 when A.預交日 > '00000000' and to_date(trim(A.預交日)||trim(B.Time4), 'YYYYMMDDHH24:MI:SS') < to_date(trim(A.異動日期)||trim(B.Time3), 'YYYYMMDDHH24:MI:SS') + E.數值10 / 24 then '3' 		 
		 when A.預交日 > '00000000' and to_date(trim(A.預交日)||trim(B.Time4), 'YYYYMMDDHH24:MI:SS') between to_date(trim(A.異動日期)||trim(B.Time3), 'YYYYMMDDHH24:MI:SS') + E.數值10 / 24 and to_date(trim(A.異動日期)||trim(B.Time3), 'YYYYMMDDHH24:MI:SS') + E.數值11 / 24 then '4' 		 
		 when A.預交日 > '00000000' and to_date(trim(A.預交日)||trim(B.Time4), 'YYYYMMDDHH24:MI:SS') > to_date(trim(A.異動日期)||trim(B.Time3), 'YYYYMMDDHH24:MI:SS') + E.數值11 / 24 then '5' 
		 else ' ' 
	end,' ') 熟成狀態,
	nvl(case 
		 when A.Logical5 = 1 and A.異動日期 > '00000000' then '2'
		 when A.Logical5 = 1 and A.異動日期 <= '00000000' then ' '
		 when A.異動日期 <= '00000000' and  sysdate > (to_date(trim(B.標籤列印日期一)||trim(B.標籤列印時間一), 'YYYYMMDDHH24:MI:SS')  + interval '30' minute) then '1' 
		 when A.異動日期 > '00000000' and to_date(trim(A.異動日期)||trim(B.Time3), 'YYYYMMDDHH24:MI:SS') <= to_date(trim(B.標籤列印日期一)||trim(B.標籤列印時間一), 'YYYYMMDDHH24:MI:SS')  + interval '30' minute then '2'
		 when A.異動日期 > '00000000' and to_date(trim(A.異動日期)||trim(B.Time3), 'YYYYMMDDHH24:MI:SS') > to_date(trim(B.標籤列印日期一)||trim(B.標籤列印時間一), 'YYYYMMDDHH24:MI:SS')  + interval '30' minute  then '3'
		else ' '
		end,' ') 入庫狀態,
	nvl(case 
		 when A.Logical5 = 1 and A.預交日 > '00000000' then '3'
		 when A.Logical5 = 1 and A.預交日 <= '00000000' then '1'
		 when (A.預交日 <= '00000000' and (E.Logical2 + B.Logical2) = 0) then '1' 
		 when (A.預交日 > '00000000' and to_date(trim(A.預交日)||trim(B.Time4), 'YYYYMMDDHH24:MI:SS') < to_date(trim(A.異動日期)||trim(B.Time3), 'YYYYMMDDHH24:MI:SS') + E.數值10 / 24  and (E.Logical2 + B.Logical2) = 0) then '2' 
		 when (A.預交日 > '00000000' and ((E.Logical2 + B.Logical2) > 0 or (to_date(trim(A.預交日)||trim(B.Time4), 'YYYYMMDDHH24:MI:SS') between to_date(trim(A.異動日期)||trim(B.Time3), 'YYYYMMDDHH24:MI:SS') + E.數值10 / 24 and to_date(trim(A.異動日期)||trim(B.Time3), 'YYYYMMDDHH24:MI:SS') + E.數值11 / 24))) then '3' 		 		 
		 when (A.預交日 > '00000000' and to_date(trim(A.預交日)||trim(B.Time4), 'YYYYMMDDHH24:MI:SS') > to_date(trim(A.異動日期)||trim(B.Time3), 'YYYYMMDDHH24:MI:SS') + E.數值11 / 24  and (E.Logical2 + B.Logical2) = 0) then '4' 
		else ' ' 
		end,' ') 出庫狀態,		
	case when A.異動日期 > '00000000' then to_date(trim(A.異動日期)||trim(B.Time3), 'YYYYMMDDHH24:MI:SS') + E.數值10 / 24 else add_months(sysdate,12) end 應出庫日時起,
	case when A.異動日期 > '00000000' then to_date(trim(A.異動日期)||trim(B.Time3), 'YYYYMMDDHH24:MI:SS') + E.數值11 / 24 else add_months(sysdate,12) end 應出庫日時迄,
	to_date(trim(B.標籤列印日期一)||trim(B.標籤列印時間一), 'YYYYMMDDHH24:MI:SS') 應入庫日時,
	A.產品編號 本製程編號,
	A.異動單價 PLC抓取米數,
	A.異動單價-A.夾鏈費 庫存數,
	A.數值3 製品厚度,
	decode(A.Logical5,1,to_char('無限制'),to_char(E.文字4)) 熟成條件,
	A.Logical4 可提早出庫,
	NVL(G.員工姓名,' ') 入庫人員姓名,
	NVL(H.員工姓名,' ') 出庫人員姓名,
	NVL(I.員工姓名,' ') 放行人員姓名,
	NVL(K.員工姓名,' ') 不限出庫設定姓名,
	J.名稱 製程,
	B.文數字4 IP位址,
	NVL(L.部門名稱,B.文數字4) 熟成室位置,
	E.交貨日期_次批 加工別,
	case when A.Logical5 = 1 then 0
		 when 
			nvl(case when A.異動日期 <= '00000000' and  sysdate > (to_date(trim(B.標籤列印日期一)||trim(B.標籤列印時間一), 'YYYYMMDDHH24:MI:SS')  + interval '30' minute) then '1' 
				 when A.異動日期 > '00000000' and to_date(trim(A.異動日期)||trim(B.Time3), 'YYYYMMDDHH24:MI:SS') <= to_date(trim(B.標籤列印日期一)||trim(B.標籤列印時間一), 'YYYYMMDDHH24:MI:SS')  + interval '30' minute then '2'
				 when A.異動日期 > '00000000' and to_date(trim(A.異動日期)||trim(B.Time3), 'YYYYMMDDHH24:MI:SS') > to_date(trim(B.標籤列印日期一)||trim(B.標籤列印時間一), 'YYYYMMDDHH24:MI:SS')  + interval '30' minute  then '3'
			else ' '
			end,' ') = '1' 
		 then 1
		 else 0
	end 超時未入庫,
	case when A.Logical5 = 1 then 0 
		 when
			sysdate > (case when A.異動日期 > '00000000' then to_date(trim(A.異動日期)||trim(B.Time3), 'YYYYMMDDHH24:MI:SS') + E.數值10 / 24 else add_months(sysdate,12) end) and 
			nvl(case when A.異動日期 <= '00000000' and sysdate > to_date(trim(B.標籤列印日期一)||trim(B.標籤列印時間一), 'YYYYMMDDHH24:MI:SS') + 1/24 then '1' 
			 when A.異動日期 > '00000000' and A.預交日 <= '00000000' then '2'
			 when A.預交日 > '00000000' and to_date(trim(A.預交日)||trim(B.Time4), 'YYYYMMDDHH24:MI:SS') < to_date(trim(A.異動日期)||trim(B.Time3), 'YYYYMMDDHH24:MI:SS') + E.數值10 / 24 then '3' 		 
			 when A.預交日 > '00000000' and to_date(trim(A.預交日)||trim(B.Time4), 'YYYYMMDDHH24:MI:SS') between to_date(trim(A.異動日期)||trim(B.Time3), 'YYYYMMDDHH24:MI:SS') + E.數值10 / 24 and to_date(trim(A.異動日期)||trim(B.Time3), 'YYYYMMDDHH24:MI:SS') + E.數值10 / 24 then '4' 		 
			 when A.預交日 > '00000000' and to_date(trim(A.預交日)||trim(B.Time4), 'YYYYMMDDHH24:MI:SS') > to_date(trim(A.異動日期)||trim(B.Time3), 'YYYYMMDDHH24:MI:SS') + E.數值11 / 24 then '5' 
			 else ' ' 
			end,' ') ='2'
		 then 1
		 else 0
	end 異常,
	A.Logical5 重覆入庫,
	C.流水編號 單頭流水編號,
	0 來源
FROM 
	FIL0040 A
	INNER JOIN FIL0041 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號 AND A.單據序號 = B.序號
	INNER JOIN FIL0030 C ON A.單據類別 = C.單據類別 AND A.單據編號 = C.單據編號
	INNER JOIN FIL0032 D ON C.歸屬類別 = D.製令單別 AND C.歸屬編號 = D.製令單號
	INNER JOIN FIL0031 E ON A.單據類別 = E.單別 AND A.單據編號 = E.單號
	LEFT JOIN FIL0010 G ON A.相關代碼1 = G.員工編號
	LEFT JOIN FIL0010 H ON A.相關代碼2 = H.員工編號
	LEFT JOIN FIL0010 I ON A.相關代碼3 = I.員工編號
	LEFT JOIN ViewFil310N J ON J.代碼 = E.製程代碼
	LEFT JOIN FIL0010 K ON decode(E.Logical2,1,E.文數字13,B.文數字5) = K.員工編號
	LEFT JOIN ViewFIL0012 L ON B.文數字4 = L.部門編號
WHERE
	A.單據類別 = 'C41' AND
	A.異動類別 = 'A' AND
	(E.製程代碼 = 'C31B' or E.製程代碼 = 'C31C') AND
	E.文字4<>'不用熟成' AND
	A.產品編號<>' '  AND
	B.標籤列印日期一>'20240101'
	
UNION ALL 

SELECT 
	A.單別, 
	A.單號,
	A.序號,
	A.製令類別,
	A.製令單號,
	D.產品編號 產品編號,
	D.產品名稱 產品名稱,
	A.熟成入庫日期,
	A.熟成入庫時間,
	A.熟成出庫日期,
	A.熟成出庫時間,
	0 不限出庫時間,
	A.熟成狀態,
	A.入庫狀態,
	A.出庫狀態,		
	A.應出庫日時起,
	A.應出庫日時迄,
	A.應入庫日時,
	A.本製程編號,
	A.PLC抓取米數,
	A.庫存數,
	A.製品厚度,
	to_char(A.熟成條件) 熟成條件,
	A.可提早出庫,
	NVL(G.員工姓名,' ') 入庫人員姓名,
	NVL(H.員工姓名,' ') 出庫人員姓名,
	NVL(I.員工姓名,' ') 放行人員姓名,
	NVL(K.員工姓名,' ') 不限出庫設定姓名,
	J.名稱 製程,
	A.IP位址,
	NVL(L.部門名稱,' ') 熟成室位置,
	A.加工別,
	0 超時未入庫,
	0 異常,
	1 重覆入庫,
	C.流水編號 單頭流水編號,
	1 來源
FROM 
	FIL004K A
	INNER JOIN FIL0030 C ON A.單別 = C.單據類別 AND A.單號 = C.單據編號
	INNER JOIN FIL0032 D ON D.製令單別 = A.製令類別 AND D.製令單號 = A.製令單號
	LEFT JOIN FIL0010 G ON A.入庫人員 = G.員工編號
	LEFT JOIN FIL0010 H ON A.出庫人員 = H.員工編號
	LEFT JOIN FIL0010 I ON A.放行人員 = I.員工編號
	LEFT JOIN ViewFil310N J ON J.代碼 = A.製程代碼
	LEFT JOIN FIL0010 K ON A.不限出庫設定人員 = K.員工編號
	LEFT JOIN ViewFIL0012 L ON A.IP位址 = L.部門編號
	
	);

-- Oracle user_views
CREATE VIEW "VIEWFIL404C4AA" ("單別", "單號", "序號", "已熟成") AS (  
SELECT 
	A.單別 單別, 
	A.單號 單號,
	A.序號 序號,
	case when (nvl(case
		 when A.重覆入庫 = 1 and A.出庫日期 > '00000000' then '4' 
		 when A.重覆入庫 = 1 and A.入庫日期 > '00000000' and A.出庫日期 <= '00000000' then '2' 
		 when A.入庫日期 <= '00000000' and sysdate > to_date(trim(B.標籤列印日期一)||trim(B.標籤列印時間一), 'YYYYMMDDHH24:MI:SS') + 1/24 then '1' 
	     when A.入庫日期 > '00000000' and A.出庫日期 <= '00000000' then '2'
		 when A.出庫日期 > '00000000' and to_date(trim(A.出庫日期)||trim(A.出庫時間), 'YYYYMMDDHH24:MI:SS') < to_date(trim(A.入庫日期)||trim(A.入庫時間), 'YYYYMMDDHH24:MI:SS') + E.數值10 / 24 then '3' 		 
		 when A.出庫日期 > '00000000' and to_date(trim(A.出庫日期)||trim(A.出庫時間), 'YYYYMMDDHH24:MI:SS') between to_date(trim(A.入庫日期)||trim(A.入庫時間), 'YYYYMMDDHH24:MI:SS') + E.數值10 / 24 and to_date(trim(A.入庫日期)||trim(A.入庫時間), 'YYYYMMDDHH24:MI:SS') + E.數值11 / 24 then '4' 		 
		 when A.出庫日期 > '00000000' and to_date(trim(A.出庫日期)||trim(A.出庫時間), 'YYYYMMDDHH24:MI:SS') > to_date(trim(A.入庫日期)||trim(A.入庫時間), 'YYYYMMDDHH24:MI:SS') + E.數值11 / 24 then '5' 
		 else ' ' 
	end,' ')) > '2' then 1 else 0 end 已熟成
FROM 
	FIL0041_B A
	INNER JOIN FIL0040 M ON A.單別 = M.單據類別 AND A.單號 = M.單據編號 AND A.序號 = M.單據序號
	INNER JOIN FIL0041 B ON A.單別 = B.單別 AND A.單號 = B.單號 AND A.序號 = B.序號
	INNER JOIN FIL0031 E ON A.單別 = E.單別 AND A.單號 = E.單號
WHERE
	A.單別 = 'C41' AND
	M.異動類別 = 'A' AND
	(E.製程代碼 = 'C31B' or E.製程代碼 = 'C31C') AND
	E.文字4<>'不用熟成' AND
	M.產品編號<>' '  AND
	B.標籤列印日期一>'20240101'
	
UNION ALL 

SELECT 
	A.單別, 
	A.單號,
	A.序號,
	case when (A.熟成狀態 > '2') then 1 else 0 end 已熟成
FROM 
	FIL004K A	
	);

-- Oracle user_views
CREATE VIEW "VIEWFIL404C4AB" ("單別", "單號", "序號", "已冷鏈") AS (  
SELECT 
	A.單別 單別, 
	A.單號 單號,
	A.序號 序號,
	case when (nvl(case
		 when A.重覆入庫 = 1 and A.出庫日期 > '00000000' then '4' 
		 when A.重覆入庫 = 1 and A.入庫日期 > '00000000' and A.出庫日期 <= '00000000' then '2' 
		 when A.入庫日期 <= '00000000' and sysdate > to_date(trim(B.標籤列印日期一)||trim(B.標籤列印時間一), 'YYYYMMDDHH24:MI:SS') + 1/24 then '1' 
	     when A.入庫日期 > '00000000' and A.出庫日期 <= '00000000' then '2'
		 when A.出庫日期 > '00000000' and to_date(trim(A.出庫日期)||trim(A.出庫時間), 'YYYYMMDDHH24:MI:SS') < to_date(trim(A.入庫日期)||trim(A.入庫時間), 'YYYYMMDDHH24:MI:SS') + E.數值10 / 24 then '3' 		 
		 when A.出庫日期 > '00000000' and to_date(trim(A.出庫日期)||trim(A.出庫時間), 'YYYYMMDDHH24:MI:SS') between to_date(trim(A.入庫日期)||trim(A.入庫時間), 'YYYYMMDDHH24:MI:SS') + E.數值10 / 24 and to_date(trim(A.入庫日期)||trim(A.入庫時間), 'YYYYMMDDHH24:MI:SS') + E.數值11 / 24 then '4' 		 
		 when A.出庫日期 > '00000000' and to_date(trim(A.出庫日期)||trim(A.出庫時間), 'YYYYMMDDHH24:MI:SS') > to_date(trim(A.入庫日期)||trim(A.入庫時間), 'YYYYMMDDHH24:MI:SS') + E.數值11 / 24 then '5' 
		 else ' ' 
	end,' ')) > '2' then 1 else 0 end 已冷鏈
FROM 
	FIL0041_BA A
	INNER JOIN FIL0040 M ON A.單別 = M.單據類別 AND A.單號 = M.單據編號 AND A.序號 = M.單據序號
	INNER JOIN FIL0041 B ON A.單別 = B.單別 AND A.單號 = B.單號 AND A.序號 = B.序號
	INNER JOIN FIL0031 E ON A.單別 = E.單別 AND A.單號 = E.單號
WHERE
	A.單別 = 'C41' AND
	M.異動類別 = 'A' AND
	(E.製程代碼 = 'C31B' or E.製程代碼 = 'C31C') AND
	E.文字5<>'不用冷鏈' AND
	M.產品編號<>' '  AND
	B.標籤列印日期一>'20240101'
	
UNION ALL 

SELECT 
	A.單別, 
	A.單號,
	A.序號,
	case when A.冷鏈狀態 > '2' then 1 else 0 end 已冷鏈
FROM 
	FIL004KA A	
	);

-- Oracle user_views
CREATE VIEW "VIEWFIL404C4A_V1" ("單別", "單號", "序號", "製令類別", "製令單號", "產品編號", "產品名稱", "冷鏈入庫日期", "冷鏈入庫時間", "冷鏈出庫日期", "冷鏈出庫時間", "不限出庫時間", "冷鏈狀態", "入庫狀態", "出庫狀態", "應出庫日時起", "應出庫日時迄", "應入庫日時", "本製程編號", "PLC抓取米數", "庫存數", "製品厚度", "冷鏈條件", "可提早出庫", "入庫人員", "入庫人員姓名", "出庫人員姓名", "放行人員姓名", "不限出庫設定姓名", "製程", "IP位址", "IP位址2", "冷鏈室位置", "加工別", "超時未入庫", "異常", "重覆入庫", "最後入出日時", "單頭流水編號", "來源", "優先冷鏈") AS (  
SELECT 
	A.單別 單別, 
	A.單號 單號,
	A.序號 序號,
	C.歸屬類別 製令類別,
	C.歸屬編號 製令單號,
	D.產品編號 產品編號,
	D.產品名稱 產品名稱,
	A.入庫日期 冷鏈入庫日期,
	A.入庫時間 冷鏈入庫時間,
	A.出庫日期 冷鏈出庫日期,
	A.出庫時間 冷鏈出庫時間,
	DECODE(E.Logical2 + A.不限出庫,0,0,1) 不限出庫時間,
	nvl(case
		 when A.重覆入庫 = 1 and A.出庫日期 > '00000000' then '4' 
		 when A.重覆入庫 = 1 and A.入庫日期 > '00000000' and A.出庫日期 <= '00000000' then '2' 
		 when A.入庫日期 <= '00000000' and sysdate > to_date(trim(B.標籤列印日期一)||trim(B.標籤列印時間一), 'YYYYMMDDHH24:MI:SS') + 1/24 then '1' 
	     when A.入庫日期 > '00000000' and A.出庫日期 <= '00000000' then '2'
		 when A.出庫日期 > '00000000' and to_date(trim(A.出庫日期)||trim(A.出庫時間), 'YYYYMMDDHH24:MI:SS') < to_date(trim(A.入庫日期)||trim(A.入庫時間), 'YYYYMMDDHH24:MI:SS') + E.數值10 / 24 then '3' 		 
		 when A.出庫日期 > '00000000' and to_date(trim(A.出庫日期)||trim(A.出庫時間), 'YYYYMMDDHH24:MI:SS') between to_date(trim(A.入庫日期)||trim(A.入庫時間), 'YYYYMMDDHH24:MI:SS') + E.數值10 / 24 and to_date(trim(A.入庫日期)||trim(A.入庫時間), 'YYYYMMDDHH24:MI:SS') + E.數值11 / 24 then '4' 		 
		 when A.出庫日期 > '00000000' and to_date(trim(A.出庫日期)||trim(A.出庫時間), 'YYYYMMDDHH24:MI:SS') > to_date(trim(A.入庫日期)||trim(A.入庫時間), 'YYYYMMDDHH24:MI:SS') + E.數值11 / 24 then '5' 
		 else ' ' 
	end,' ') 冷鏈狀態,
	nvl(case 
		 when A.重覆入庫 = 1 and A.入庫日期 > '00000000' then '2'
		 when A.重覆入庫 = 1 and A.入庫日期 <= '00000000' then ' '
		 when A.入庫日期 <= '00000000' and  sysdate > (to_date(trim(B.標籤列印日期一)||trim(B.標籤列印時間一), 'YYYYMMDDHH24:MI:SS')  + interval '30' minute) then '1' 
		 when A.入庫日期 > '00000000' and to_date(trim(A.入庫日期)||trim(A.入庫時間), 'YYYYMMDDHH24:MI:SS') <= to_date(trim(B.標籤列印日期一)||trim(B.標籤列印時間一), 'YYYYMMDDHH24:MI:SS')  + interval '30' minute then '2'
		 when A.入庫日期 > '00000000' and to_date(trim(A.入庫日期)||trim(A.入庫時間), 'YYYYMMDDHH24:MI:SS') > to_date(trim(B.標籤列印日期一)||trim(B.標籤列印時間一), 'YYYYMMDDHH24:MI:SS')  + interval '30' minute  then '3'
		else ' '
		end,' ') 入庫狀態,
	nvl(case 
		 when A.重覆入庫 = 1 and A.出庫日期 > '00000000' then '3'
		 when A.重覆入庫 = 1 and A.出庫日期 <= '00000000' then '1'
		 when (A.出庫日期 <= '00000000' and (E.Logical2 + A.不限出庫) = 0) then '1' 
		 when (A.出庫日期 > '00000000' and to_date(trim(A.出庫日期)||trim(A.出庫時間), 'YYYYMMDDHH24:MI:SS') < to_date(trim(A.入庫日期)||trim(A.入庫時間), 'YYYYMMDDHH24:MI:SS') + E.數值10 / 24  and (E.Logical2 + A.不限出庫) = 0) then '2' 
		 when (A.出庫日期 > '00000000' and ((E.Logical2 + A.不限出庫) > 0 or (to_date(trim(A.出庫日期)||trim(A.出庫時間), 'YYYYMMDDHH24:MI:SS') between to_date(trim(A.入庫日期)||trim(A.入庫時間), 'YYYYMMDDHH24:MI:SS') + E.數值10 / 24 and to_date(trim(A.入庫日期)||trim(A.入庫時間), 'YYYYMMDDHH24:MI:SS') + E.數值11 / 24))) then '3' 		 		 
		 when (A.出庫日期 > '00000000' and to_date(trim(A.出庫日期)||trim(A.出庫時間), 'YYYYMMDDHH24:MI:SS') > to_date(trim(A.入庫日期)||trim(A.入庫時間), 'YYYYMMDDHH24:MI:SS') + E.數值11 / 24  and (E.Logical2 + A.不限出庫) = 0) then '4' 
		else ' ' 
		end,' ') 出庫狀態,		
	case when A.入庫日期 > '00000000' then to_date(trim(A.入庫日期)||trim(A.入庫時間), 'YYYYMMDDHH24:MI:SS') + E.數值10 / 24 else add_months(sysdate,12) end 應出庫日時起,
	case when A.入庫日期 > '00000000' then to_date(trim(A.入庫日期)||trim(A.入庫時間), 'YYYYMMDDHH24:MI:SS') + E.數值11 / 24 else add_months(sysdate,12) end 應出庫日時迄,
	to_date(trim(B.標籤列印日期一)||trim(B.標籤列印時間一), 'YYYYMMDDHH24:MI:SS') 應入庫日時,
	M.產品編號 本製程編號,
	M.異動單價 PLC抓取米數,
	M.異動單價-M.夾鏈費 庫存數,
	M.數值3 製品厚度,
	decode(A.重覆入庫,1,to_char('無限制'),to_char(E.文字5)) 冷鏈條件,
	A.可提早出庫,
	A.入庫人員,
	NVL(G.員工姓名,' ') 入庫人員姓名,
	NVL(H.員工姓名,' ') 出庫人員姓名,
	NVL(I.員工姓名,' ') 放行人員姓名,
	NVL(K.員工姓名,' ') 不限出庫設定姓名,
	J.名稱 製程,
	A.冷鏈室位置 IP位址,
	A.IP位址2,
	NVL(L.部門名稱,A.冷鏈室位置) 冷鏈室位置,
	E.交貨日期_次批 加工別,
	case when A.重覆入庫 = 1 then 0
		 when 
			nvl(case when A.入庫日期 <= '00000000' and  sysdate > (to_date(trim(B.標籤列印日期一)||trim(B.標籤列印時間一), 'YYYYMMDDHH24:MI:SS')  + interval '15' minute) then '1' 
				 when A.入庫日期 > '00000000' and to_date(trim(A.入庫日期)||trim(A.入庫時間), 'YYYYMMDDHH24:MI:SS') <= to_date(trim(B.標籤列印日期一)||trim(B.標籤列印時間一), 'YYYYMMDDHH24:MI:SS')  + interval '15' minute then '2'
				 when A.入庫日期 > '00000000' and to_date(trim(A.入庫日期)||trim(A.入庫時間), 'YYYYMMDDHH24:MI:SS') > to_date(trim(B.標籤列印日期一)||trim(B.標籤列印時間一), 'YYYYMMDDHH24:MI:SS')  + interval '15' minute  then '3'
			else ' '
			end,' ') = '1' 
		 then 1
		 else 0
	end 超時未入庫,
	case when A.重覆入庫 = 1 then 0 
		 when
			sysdate > (case when A.入庫日期 > '00000000' then to_date(trim(A.入庫日期)||trim(A.入庫時間), 'YYYYMMDDHH24:MI:SS') + E.數值10 / 24 else add_months(sysdate,12) end) and 
			nvl(case when A.入庫日期 <= '00000000' and sysdate > to_date(trim(B.標籤列印日期一)||trim(B.標籤列印時間一), 'YYYYMMDDHH24:MI:SS') + 1/24 then '1' 
			 when A.入庫日期 > '00000000' and A.出庫日期 <= '00000000' then '2'
			 when A.出庫日期 > '00000000' and to_date(trim(A.出庫日期)||trim(A.出庫時間), 'YYYYMMDDHH24:MI:SS') < to_date(trim(A.入庫日期)||trim(A.入庫時間), 'YYYYMMDDHH24:MI:SS') + E.數值10 / 24 then '3' 		 
			 when A.出庫日期 > '00000000' and to_date(trim(A.出庫日期)||trim(A.出庫時間), 'YYYYMMDDHH24:MI:SS') between to_date(trim(A.入庫日期)||trim(A.入庫時間), 'YYYYMMDDHH24:MI:SS') + E.數值10 / 24 and to_date(trim(A.入庫日期)||trim(A.入庫時間), 'YYYYMMDDHH24:MI:SS') + E.數值10 / 24 then '4' 		 
			 when A.出庫日期 > '00000000' and to_date(trim(A.出庫日期)||trim(A.出庫時間), 'YYYYMMDDHH24:MI:SS') > to_date(trim(A.入庫日期)||trim(A.入庫時間), 'YYYYMMDDHH24:MI:SS') + E.數值11 / 24 then '5' 
			 else ' ' 
			end,' ') ='2'
		 then 1
		 else 0
	end 異常,
	A.重覆入庫 重覆入庫,
	case when trim(A.入庫日期)||A.入庫時間 > trim(A.出庫日期)||A.出庫時間 then trim(A.入庫日期)||A.入庫時間 else trim(A.出庫日期)||A.出庫時間 end 最後入出日時,
	C.流水編號 單頭流水編號,
	0 來源,
	C.邏輯值一 優先冷鏈
FROM 
	FIL0041_BA A
	INNER JOIN FIL0040 M ON A.單別 = M.單據類別 AND A.單號 = M.單據編號 AND A.序號 = M.單據序號
	INNER JOIN FIL0041 B ON A.單別 = B.單別 AND A.單號 = B.單號 AND A.序號 = B.序號
	INNER JOIN FIL0030 C ON A.單別 = C.單據類別 AND A.單號 = C.單據編號
	INNER JOIN FIL0032 D ON C.歸屬類別 = D.製令單別 AND C.歸屬編號 = D.製令單號
	INNER JOIN FIL0031 E ON A.單別 = E.單別 AND A.單號 = E.單號
	LEFT JOIN FIL0010 G ON A.入庫人員 = G.員工編號
	LEFT JOIN FIL0010 H ON A.出庫人員 = H.員工編號
	LEFT JOIN FIL0010 I ON A.放行人員 = I.員工編號
	LEFT JOIN ViewFil310N J ON J.代碼 = E.製程代碼
	LEFT JOIN FIL0010 K ON decode(E.Logical2,1,E.文數字13,A.不限出庫人員) = K.員工編號
	LEFT JOIN ViewFIL0012 L ON A.冷鏈室位置 = L.部門編號
WHERE
	A.單別 = 'C41' AND
	M.異動類別 = 'A' AND
	(E.製程代碼 = 'C31B' or E.製程代碼 = 'C31C') AND
	E.文字5<>'不用冷鏈' AND
	M.產品編號<>' '  AND
	B.標籤列印日期一>'20240101'
	
UNION ALL 

SELECT 
	A.單別, 
	A.單號,
	A.序號,
	A.製令類別,
	A.製令單號,
	D.產品編號 產品編號,
	D.產品名稱 產品名稱,
	A.冷鏈入庫日期,
	A.冷鏈入庫時間,
	A.冷鏈出庫日期,
	A.冷鏈出庫時間,
	0 不限出庫時間,
	A.冷鏈狀態,
	A.入庫狀態,
	A.出庫狀態,		
	A.應出庫日時起,
	A.應出庫日時迄,
	A.應入庫日時,
	A.本製程編號,
	A.PLC抓取米數,
	A.庫存數,
	A.製品厚度,
	to_char(A.冷鏈條件) 冷鏈條件,
	A.可提早出庫,
	A.入庫人員,
	NVL(G.員工姓名,' ') 入庫人員姓名,
	NVL(H.員工姓名,' ') 出庫人員姓名,
	NVL(I.員工姓名,' ') 放行人員姓名,
	NVL(K.員工姓名,' ') 不限出庫設定姓名,
	J.名稱 製程,
	A.IP位址,
	A.IP位址2,
	NVL(L.部門名稱,' ') 冷鏈室位置,
	A.加工別,
	0 超時未入庫,
	0 異常,
	1 重覆入庫,
	case when trim(A.冷鏈入庫日期)||A.冷鏈入庫時間 > trim(A.冷鏈出庫日期)||A.冷鏈出庫時間 then trim(A.冷鏈入庫日期)||A.冷鏈入庫時間 else trim(A.冷鏈出庫日期)||A.冷鏈出庫時間 end 最後入出日時,
	C.流水編號 單頭流水編號,
	1 來源,
	C.邏輯值一 優先冷鏈
FROM 
	FIL004KA A
	INNER JOIN FIL0030 C ON A.單別 = C.單據類別 AND A.單號 = C.單據編號
	INNER JOIN FIL0032 D ON D.製令單別 = A.製令類別 AND D.製令單號 = A.製令單號
	LEFT JOIN FIL0010 G ON A.入庫人員 = G.員工編號
	LEFT JOIN FIL0010 H ON A.出庫人員 = H.員工編號
	LEFT JOIN FIL0010 I ON A.放行人員 = I.員工編號
	LEFT JOIN ViewFil310N J ON J.代碼 = A.製程代碼
	LEFT JOIN FIL0010 K ON A.不限出庫設定人員 = K.員工編號
	LEFT JOIN ViewFIL0012 L ON A.IP位址 = L.部門編號
	
	);

-- Oracle user_views
CREATE VIEW "VIEWFIL404C4A_V2" ("單別", "單號", "序號", "製令類別", "製令單號", "產品編號", "產品名稱", "冷鏈入庫日期", "冷鏈入庫時間", "冷鏈出庫日期", "冷鏈出庫時間", "不限出庫時間", "冷鏈狀態", "入庫狀態", "出庫狀態", "本製程編號", "PLC抓取米數", "庫存數", "製品厚度", "冷鏈條件", "可提早出庫", "入庫人員姓名", "出庫人員姓名", "放行人員姓名", "不限出庫設定姓名", "製程", "IP位址", "冷鏈室位置", "加工別", "超時未入庫", "異常", "重覆入庫", "單頭流水編號", "來源") AS (  
SELECT 
	A.單別 單別, 
	A.單號 單號,
	A.序號 序號,
	C.歸屬類別 製令類別,
	C.歸屬編號 製令單號,
	D.產品編號 產品編號,
	D.產品名稱 產品名稱,
	A.入庫日期 冷鏈入庫日期,
	A.入庫時間 冷鏈入庫時間,
	A.出庫日期 冷鏈出庫日期,
	A.出庫時間 冷鏈出庫時間,
	DECODE(E.Logical2 + A.不限出庫,0,0,1) 不限出庫時間,
	nvl(case
		 when A.重覆入庫 = 1 and A.出庫日期 > '00000000' then '4' 
		 when A.重覆入庫 = 1 and A.入庫日期 > '00000000' and A.出庫日期 <= '00000000' then '2' 
		 when A.入庫日期 <= '00000000' and sysdate > to_date(trim(B.標籤列印日期一)||trim(B.標籤列印時間一), 'YYYYMMDDHH24:MI:SS') + 1/24 then '1' 
	     when A.入庫日期 > '00000000' and A.出庫日期 <= '00000000' then '2'
		 when A.出庫日期 > '00000000' and to_date(trim(A.出庫日期)||trim(A.出庫時間), 'YYYYMMDDHH24:MI:SS') < to_date(trim(A.入庫日期)||trim(A.入庫時間), 'YYYYMMDDHH24:MI:SS') + E.數值10 / 24 then '3' 		 
		 when A.出庫日期 > '00000000' and to_date(trim(A.出庫日期)||trim(A.出庫時間), 'YYYYMMDDHH24:MI:SS') between to_date(trim(A.入庫日期)||trim(A.入庫時間), 'YYYYMMDDHH24:MI:SS') + E.數值10 / 24 and to_date(trim(A.入庫日期)||trim(A.入庫時間), 'YYYYMMDDHH24:MI:SS') + E.數值11 / 24 then '4' 		 
		 when A.出庫日期 > '00000000' and to_date(trim(A.出庫日期)||trim(A.出庫時間), 'YYYYMMDDHH24:MI:SS') > to_date(trim(A.入庫日期)||trim(A.入庫時間), 'YYYYMMDDHH24:MI:SS') + E.數值11 / 24 then '5' 
		 else ' ' 
	end,' ') 冷鏈狀態,
	nvl(case 
		 when A.重覆入庫 = 1 and A.入庫日期 > '00000000' then '2'
		 when A.重覆入庫 = 1 and A.入庫日期 <= '00000000' then ' '
		 when A.入庫日期 <= '00000000' and  sysdate > (to_date(trim(B.標籤列印日期一)||trim(B.標籤列印時間一), 'YYYYMMDDHH24:MI:SS')  + interval '30' minute) then '1' 
		 when A.入庫日期 > '00000000' and to_date(trim(A.入庫日期)||trim(A.入庫時間), 'YYYYMMDDHH24:MI:SS') <= to_date(trim(B.標籤列印日期一)||trim(B.標籤列印時間一), 'YYYYMMDDHH24:MI:SS')  + interval '30' minute then '2'
		 when A.入庫日期 > '00000000' and to_date(trim(A.入庫日期)||trim(A.入庫時間), 'YYYYMMDDHH24:MI:SS') > to_date(trim(B.標籤列印日期一)||trim(B.標籤列印時間一), 'YYYYMMDDHH24:MI:SS')  + interval '30' minute  then '3'
		else ' '
		end,' ') 入庫狀態,
	nvl(case 
		 when A.重覆入庫 = 1 and A.出庫日期 > '00000000' then '3'
		 when A.重覆入庫 = 1 and A.出庫日期 <= '00000000' then '1'
		 when (A.出庫日期 <= '00000000' and (E.Logical2 + A.不限出庫) = 0) then '1' 
		 when (A.出庫日期 > '00000000' and to_date(trim(A.出庫日期)||trim(A.出庫時間), 'YYYYMMDDHH24:MI:SS') < to_date(trim(A.入庫日期)||trim(A.入庫時間), 'YYYYMMDDHH24:MI:SS') + E.數值10 / 24  and (E.Logical2 + A.不限出庫) = 0) then '2' 
		 when (A.出庫日期 > '00000000' and ((E.Logical2 + A.不限出庫) > 0 or (to_date(trim(A.出庫日期)||trim(A.出庫時間), 'YYYYMMDDHH24:MI:SS') between to_date(trim(A.入庫日期)||trim(A.入庫時間), 'YYYYMMDDHH24:MI:SS') + E.數值10 / 24 and to_date(trim(A.入庫日期)||trim(A.入庫時間), 'YYYYMMDDHH24:MI:SS') + E.數值11 / 24))) then '3' 		 		 
		 when (A.出庫日期 > '00000000' and to_date(trim(A.出庫日期)||trim(A.出庫時間), 'YYYYMMDDHH24:MI:SS') > to_date(trim(A.入庫日期)||trim(A.入庫時間), 'YYYYMMDDHH24:MI:SS') + E.數值11 / 24  and (E.Logical2 + A.不限出庫) = 0) then '4' 
		else ' ' 
		end,' ') 出庫狀態,		
	M.產品編號 本製程編號,
	M.異動單價 PLC抓取米數,
	M.異動單價-M.夾鏈費 庫存數,
	M.數值3 製品厚度,
	decode(A.重覆入庫,1,to_char('無限制'),to_char(E.文字5)) 冷鏈條件,
	A.可提早出庫,
	NVL(G.員工姓名,' ') 入庫人員姓名,
	NVL(H.員工姓名,' ') 出庫人員姓名,
	NVL(I.員工姓名,' ') 放行人員姓名,
	NVL(K.員工姓名,' ') 不限出庫設定姓名,
	J.名稱 製程,
	A.冷鏈室位置 IP位址,
	NVL(L.部門名稱,A.冷鏈室位置) 冷鏈室位置,
	E.交貨日期_次批 加工別,
	case when A.重覆入庫 = 1 then 0
		 when 
			nvl(case when A.入庫日期 <= '00000000' and  sysdate > (to_date(trim(B.標籤列印日期一)||trim(B.標籤列印時間一), 'YYYYMMDDHH24:MI:SS')  + interval '30' minute) then '1' 
				 when A.入庫日期 > '00000000' and to_date(trim(A.入庫日期)||trim(A.入庫時間), 'YYYYMMDDHH24:MI:SS') <= to_date(trim(B.標籤列印日期一)||trim(B.標籤列印時間一), 'YYYYMMDDHH24:MI:SS')  + interval '30' minute then '2'
				 when A.入庫日期 > '00000000' and to_date(trim(A.入庫日期)||trim(A.入庫時間), 'YYYYMMDDHH24:MI:SS') > to_date(trim(B.標籤列印日期一)||trim(B.標籤列印時間一), 'YYYYMMDDHH24:MI:SS')  + interval '30' minute  then '3'
			else ' '
			end,' ') = '1' 
		 then 1
		 else 0
	end 超時未入庫,
	case when A.重覆入庫 = 1 then 0 
		 when
			sysdate > (case when A.入庫日期 > '00000000' then to_date(trim(A.入庫日期)||trim(A.入庫時間), 'YYYYMMDDHH24:MI:SS') + E.數值10 / 24 else add_months(sysdate,12) end) and 
			nvl(case when A.入庫日期 <= '00000000' and sysdate > to_date(trim(B.標籤列印日期一)||trim(B.標籤列印時間一), 'YYYYMMDDHH24:MI:SS') + 1/24 then '1' 
			 when A.入庫日期 > '00000000' and A.出庫日期 <= '00000000' then '2'
			 when A.出庫日期 > '00000000' and to_date(trim(A.出庫日期)||trim(A.出庫時間), 'YYYYMMDDHH24:MI:SS') < to_date(trim(A.入庫日期)||trim(A.入庫時間), 'YYYYMMDDHH24:MI:SS') + E.數值10 / 24 then '3' 		 
			 when A.出庫日期 > '00000000' and to_date(trim(A.出庫日期)||trim(A.出庫時間), 'YYYYMMDDHH24:MI:SS') between to_date(trim(A.入庫日期)||trim(A.入庫時間), 'YYYYMMDDHH24:MI:SS') + E.數值10 / 24 and to_date(trim(A.入庫日期)||trim(A.入庫時間), 'YYYYMMDDHH24:MI:SS') + E.數值10 / 24 then '4' 		 
			 when A.出庫日期 > '00000000' and to_date(trim(A.出庫日期)||trim(A.出庫時間), 'YYYYMMDDHH24:MI:SS') > to_date(trim(A.入庫日期)||trim(A.入庫時間), 'YYYYMMDDHH24:MI:SS') + E.數值11 / 24 then '5' 
			 else ' ' 
			end,' ') ='2'
		 then 1
		 else 0
	end 異常,
	A.重覆入庫 重覆入庫,
	C.流水編號 單頭流水編號,
	0 來源
FROM 
	FIL0041_BA A
	INNER JOIN FIL0040 M ON A.單別 = M.單據類別 AND A.單號 = M.單據編號 AND A.序號 = M.單據序號
	INNER JOIN FIL0041 B ON A.單別 = B.單別 AND A.單號 = B.單號 AND A.序號 = B.序號
	INNER JOIN FIL0030 C ON A.單別 = C.單據類別 AND A.單號 = C.單據編號
	INNER JOIN FIL0032 D ON C.歸屬類別 = D.製令單別 AND C.歸屬編號 = D.製令單號
	INNER JOIN FIL0031 E ON A.單別 = E.單別 AND A.單號 = E.單號
	LEFT JOIN FIL0010 G ON A.入庫人員 = G.員工編號
	LEFT JOIN FIL0010 H ON A.出庫人員 = H.員工編號
	LEFT JOIN FIL0010 I ON A.放行人員 = I.員工編號
	LEFT JOIN ViewFil310N J ON J.代碼 = E.製程代碼
	LEFT JOIN FIL0010 K ON decode(E.Logical2,1,E.文數字13,A.不限出庫人員) = K.員工編號
	LEFT JOIN ViewFIL0012 L ON A.冷鏈室位置 = L.部門編號
WHERE
	A.單別 = 'C41' AND
	M.異動類別 = 'A' AND
	(E.製程代碼 = 'C31B' or E.製程代碼 = 'C31C') AND
	E.文字5<>'不用冷鏈' AND
	M.產品編號<>' '  AND
	B.標籤列印日期一>'20240101'
	
UNION ALL 

SELECT 
	A.單別, 
	A.單號,
	A.序號,
	A.製令類別,
	A.製令單號,
	D.產品編號 產品編號,
	D.產品名稱 產品名稱,
	A.冷鏈入庫日期,
	A.冷鏈入庫時間,
	A.冷鏈出庫日期,
	A.冷鏈出庫時間,
	0 不限出庫時間,
	A.冷鏈狀態,
	A.入庫狀態,
	A.出庫狀態,		
	A.本製程編號,
	A.PLC抓取米數,
	A.庫存數,
	A.製品厚度,
	to_char(A.冷鏈條件) 冷鏈條件,
	A.可提早出庫,
	NVL(G.員工姓名,' ') 入庫人員姓名,
	NVL(H.員工姓名,' ') 出庫人員姓名,
	NVL(I.員工姓名,' ') 放行人員姓名,
	NVL(K.員工姓名,' ') 不限出庫設定姓名,
	J.名稱 製程,
	A.IP位址,
	NVL(L.部門名稱,' ') 冷鏈室位置,
	A.加工別,
	0 超時未入庫,
	0 異常,
	1 重覆入庫,
	C.流水編號 單頭流水編號,
	1 來源
FROM 
	FIL004KA A
	INNER JOIN FIL0030 C ON A.單別 = C.單據類別 AND A.單號 = C.單據編號
	INNER JOIN FIL0032 D ON D.製令單別 = A.製令類別 AND D.製令單號 = A.製令單號
	LEFT JOIN FIL0010 G ON A.入庫人員 = G.員工編號
	LEFT JOIN FIL0010 H ON A.出庫人員 = H.員工編號
	LEFT JOIN FIL0010 I ON A.放行人員 = I.員工編號
	LEFT JOIN ViewFil310N J ON J.代碼 = A.製程代碼
	LEFT JOIN FIL0010 K ON A.不限出庫設定人員 = K.員工編號
	LEFT JOIN ViewFIL0012 L ON A.IP位址 = L.部門編號
	
	);

-- Oracle user_views
CREATE VIEW "VIEWFIL404C4_V1" ("單別", "單號", "序號", "製令類別", "製令單號", "產品編號", "產品名稱", "熟成入庫日期", "熟成入庫時間", "熟成出庫日期", "熟成出庫時間", "不限出庫時間", "熟成狀態", "入庫狀態", "出庫狀態", "應出庫日時起", "應出庫日時迄", "應入庫日時", "本製程編號", "PLC抓取米數", "庫存數", "製品厚度", "熟成條件", "可提早出庫", "入庫人員", "入庫人員姓名", "出庫人員姓名", "放行人員姓名", "不限出庫設定姓名", "製程", "IP位址", "IP位址2", "熟成室位置", "加工別", "超時未入庫", "異常", "重覆入庫", "最後入出日時", "單頭流水編號", "來源", "優先冷鏈") AS (  
SELECT 
	A.單別 單別, 
	A.單號 單號,
	A.序號 序號,
	C.歸屬類別 製令類別,
	C.歸屬編號 製令單號,
	D.產品編號 產品編號,
	D.產品名稱 產品名稱,
	A.入庫日期 熟成入庫日期,
	A.入庫時間 熟成入庫時間,
	A.出庫日期 熟成出庫日期,
	A.出庫時間 熟成出庫時間,
	DECODE(E.Logical2 + A.不限出庫,0,0,1) 不限出庫時間,
	nvl(case
		 when A.重覆入庫 = 1 and A.出庫日期 > '00000000' then '4' 
		 when A.重覆入庫 = 1 and A.入庫日期 > '00000000' and A.出庫日期 <= '00000000' then '2' 
		 when A.入庫日期 <= '00000000' and sysdate > to_date(trim(B.標籤列印日期一)||trim(B.標籤列印時間一), 'YYYYMMDDHH24:MI:SS') + 1/24 then '1' 
	     when A.入庫日期 > '00000000' and A.出庫日期 <= '00000000' then '2'
		 when A.出庫日期 > '00000000' and to_date(trim(A.出庫日期)||trim(A.出庫時間), 'YYYYMMDDHH24:MI:SS') < to_date(trim(A.入庫日期)||trim(A.入庫時間), 'YYYYMMDDHH24:MI:SS') + E.數值10 / 24 then '3' 		 
		 when A.出庫日期 > '00000000' and to_date(trim(A.出庫日期)||trim(A.出庫時間), 'YYYYMMDDHH24:MI:SS') between to_date(trim(A.入庫日期)||trim(A.入庫時間), 'YYYYMMDDHH24:MI:SS') + E.數值10 / 24 and to_date(trim(A.入庫日期)||trim(A.入庫時間), 'YYYYMMDDHH24:MI:SS') + E.數值11 / 24 then '4' 		 
		 when A.出庫日期 > '00000000' and to_date(trim(A.出庫日期)||trim(A.出庫時間), 'YYYYMMDDHH24:MI:SS') > to_date(trim(A.入庫日期)||trim(A.入庫時間), 'YYYYMMDDHH24:MI:SS') + E.數值11 / 24 then '5' 
		 else ' ' 
	end,' ') 熟成狀態,
	nvl(case 
		 when A.重覆入庫 = 1 and A.入庫日期 > '00000000' then '2'
		 when A.重覆入庫 = 1 and A.入庫日期 <= '00000000' then ' '
		 when A.入庫日期 <= '00000000' and  sysdate > (to_date(trim(B.標籤列印日期一)||trim(B.標籤列印時間一), 'YYYYMMDDHH24:MI:SS')  + interval '30' minute) then '1' 
		 when A.入庫日期 > '00000000' and to_date(trim(A.入庫日期)||trim(A.入庫時間), 'YYYYMMDDHH24:MI:SS') <= to_date(trim(B.標籤列印日期一)||trim(B.標籤列印時間一), 'YYYYMMDDHH24:MI:SS')  + interval '30' minute then '2'
		 when A.入庫日期 > '00000000' and to_date(trim(A.入庫日期)||trim(A.入庫時間), 'YYYYMMDDHH24:MI:SS') > to_date(trim(B.標籤列印日期一)||trim(B.標籤列印時間一), 'YYYYMMDDHH24:MI:SS')  + interval '30' minute  then '3'
		else ' '
		end,' ') 入庫狀態,
	nvl(case 
		 when A.重覆入庫 = 1 and A.出庫日期 > '00000000' then '3'
		 when A.重覆入庫 = 1 and A.出庫日期 <= '00000000' then '1'
		 when (A.出庫日期 <= '00000000' and (E.Logical2 + A.不限出庫) = 0) then '1' 
		 when (A.出庫日期 > '00000000' and to_date(trim(A.出庫日期)||trim(A.出庫時間), 'YYYYMMDDHH24:MI:SS') < to_date(trim(A.入庫日期)||trim(A.入庫時間), 'YYYYMMDDHH24:MI:SS') + E.數值10 / 24  and (E.Logical2 + A.不限出庫) = 0) then '2' 
		 when (A.出庫日期 > '00000000' and ((E.Logical2 + A.不限出庫) > 0 or (to_date(trim(A.出庫日期)||trim(A.出庫時間), 'YYYYMMDDHH24:MI:SS') between to_date(trim(A.入庫日期)||trim(A.入庫時間), 'YYYYMMDDHH24:MI:SS') + E.數值10 / 24 and to_date(trim(A.入庫日期)||trim(A.入庫時間), 'YYYYMMDDHH24:MI:SS') + E.數值11 / 24))) then '3' 		 		 
		 when (A.出庫日期 > '00000000' and to_date(trim(A.出庫日期)||trim(A.出庫時間), 'YYYYMMDDHH24:MI:SS') > to_date(trim(A.入庫日期)||trim(A.入庫時間), 'YYYYMMDDHH24:MI:SS') + E.數值11 / 24  and (E.Logical2 + A.不限出庫) = 0) then '4' 
		else ' ' 
		end,' ') 出庫狀態,		
	case when A.入庫日期 > '00000000' then to_date(trim(A.入庫日期)||trim(A.入庫時間), 'YYYYMMDDHH24:MI:SS') + E.數值10 / 24 else add_months(sysdate,12) end 應出庫日時起,
	case when A.入庫日期 > '00000000' then to_date(trim(A.入庫日期)||trim(A.入庫時間), 'YYYYMMDDHH24:MI:SS') + E.數值11 / 24 else add_months(sysdate,12) end 應出庫日時迄,
	to_date(trim(B.標籤列印日期一)||trim(B.標籤列印時間一), 'YYYYMMDDHH24:MI:SS') 應入庫日時,
	M.產品編號 本製程編號,
	M.異動單價 PLC抓取米數,
	M.異動單價-M.夾鏈費 庫存數,
	M.數值3 製品厚度,
	decode(A.重覆入庫,1,to_char('無限制'),to_char(E.文字4)) 熟成條件,
	A.可提早出庫,
	A.入庫人員,
	NVL(G.員工姓名,' ') 入庫人員姓名,
	NVL(H.員工姓名,' ') 出庫人員姓名,
	NVL(I.員工姓名,' ') 放行人員姓名,
	NVL(K.員工姓名,' ') 不限出庫設定姓名,
	J.名稱 製程,
	A.熟成室位置 IP位址,
	A.IP位址2,
	NVL(L.部門名稱,A.熟成室位置) 熟成室位置,
	E.交貨日期_次批 加工別,
	case when A.重覆入庫 = 1 then 0
		 when 
			nvl(case when A.入庫日期 <= '00000000' and  sysdate > (to_date(trim(B.標籤列印日期一)||trim(B.標籤列印時間一), 'YYYYMMDDHH24:MI:SS')  + interval '15' minute) then '1' 
				 when A.入庫日期 > '00000000' and to_date(trim(A.入庫日期)||trim(A.入庫時間), 'YYYYMMDDHH24:MI:SS') <= to_date(trim(B.標籤列印日期一)||trim(B.標籤列印時間一), 'YYYYMMDDHH24:MI:SS')  + interval '15' minute then '2'
				 when A.入庫日期 > '00000000' and to_date(trim(A.入庫日期)||trim(A.入庫時間), 'YYYYMMDDHH24:MI:SS') > to_date(trim(B.標籤列印日期一)||trim(B.標籤列印時間一), 'YYYYMMDDHH24:MI:SS')  + interval '15' minute  then '3'
			else ' '
			end,' ') = '1' 
		 then 1
		 else 0
	end 超時未入庫,
	case when A.重覆入庫 = 1 then 0 
		 when
			sysdate > (case when A.入庫日期 > '00000000' then to_date(trim(A.入庫日期)||trim(A.入庫時間), 'YYYYMMDDHH24:MI:SS') + E.數值10 / 24 else add_months(sysdate,12) end) and 
			nvl(case when A.入庫日期 <= '00000000' and sysdate > to_date(trim(B.標籤列印日期一)||trim(B.標籤列印時間一), 'YYYYMMDDHH24:MI:SS') + 1/24 then '1' 
			 when A.入庫日期 > '00000000' and A.出庫日期 <= '00000000' then '2'
			 when A.出庫日期 > '00000000' and to_date(trim(A.出庫日期)||trim(A.出庫時間), 'YYYYMMDDHH24:MI:SS') < to_date(trim(A.入庫日期)||trim(A.入庫時間), 'YYYYMMDDHH24:MI:SS') + E.數值10 / 24 then '3' 		 
			 when A.出庫日期 > '00000000' and to_date(trim(A.出庫日期)||trim(A.出庫時間), 'YYYYMMDDHH24:MI:SS') between to_date(trim(A.入庫日期)||trim(A.入庫時間), 'YYYYMMDDHH24:MI:SS') + E.數值10 / 24 and to_date(trim(A.入庫日期)||trim(A.入庫時間), 'YYYYMMDDHH24:MI:SS') + E.數值10 / 24 then '4' 		 
			 when A.出庫日期 > '00000000' and to_date(trim(A.出庫日期)||trim(A.出庫時間), 'YYYYMMDDHH24:MI:SS') > to_date(trim(A.入庫日期)||trim(A.入庫時間), 'YYYYMMDDHH24:MI:SS') + E.數值11 / 24 then '5' 
			 else ' ' 
			end,' ') ='2'
		 then 1
		 else 0
	end 異常,
	A.重覆入庫 重覆入庫,
	case when trim(A.入庫日期)||A.入庫時間 > trim(A.出庫日期)||A.出庫時間 then trim(A.入庫日期)||A.入庫時間 else trim(A.出庫日期)||A.出庫時間 end 最後入出日時,
	C.流水編號 單頭流水編號,
	0 來源,
	C.邏輯值一 優先冷鏈
FROM 
	FIL0041_B A
	INNER JOIN FIL0040 M ON A.單別 = M.單據類別 AND A.單號 = M.單據編號 AND A.序號 = M.單據序號
	INNER JOIN FIL0041 B ON A.單別 = B.單別 AND A.單號 = B.單號 AND A.序號 = B.序號
	INNER JOIN FIL0030 C ON A.單別 = C.單據類別 AND A.單號 = C.單據編號
	INNER JOIN FIL0032 D ON C.歸屬類別 = D.製令單別 AND C.歸屬編號 = D.製令單號
	INNER JOIN FIL0031 E ON A.單別 = E.單別 AND A.單號 = E.單號
	LEFT JOIN FIL0010 G ON A.入庫人員 = G.員工編號
	LEFT JOIN FIL0010 H ON A.出庫人員 = H.員工編號
	LEFT JOIN FIL0010 I ON A.放行人員 = I.員工編號
	LEFT JOIN ViewFil310N J ON J.代碼 = E.製程代碼
	LEFT JOIN FIL0010 K ON decode(E.Logical2,1,E.文數字13,A.不限出庫人員) = K.員工編號
	LEFT JOIN ViewFIL0012 L ON A.熟成室位置 = L.部門編號
WHERE
	A.單別 = 'C41' AND
	M.異動類別 = 'A' AND
	(E.製程代碼 = 'C31B' or E.製程代碼 = 'C31C') AND
	E.文字4<>'不用熟成' AND
	M.產品編號<>' '  AND
	B.標籤列印日期一>'20240101'
	
UNION ALL 

SELECT 
	A.單別, 
	A.單號,
	A.序號,
	A.製令類別,
	A.製令單號,
	D.產品編號 產品編號,
	D.產品名稱 產品名稱,
	A.熟成入庫日期,
	A.熟成入庫時間,
	A.熟成出庫日期,
	A.熟成出庫時間,
	0 不限出庫時間,
	A.熟成狀態,
	A.入庫狀態,
	A.出庫狀態,		
	A.應出庫日時起,
	A.應出庫日時迄,
	A.應入庫日時,
	A.本製程編號,
	A.PLC抓取米數,
	A.庫存數,
	A.製品厚度,
	to_char(A.熟成條件) 熟成條件,
	A.可提早出庫,
	A.入庫人員,
	NVL(G.員工姓名,' ') 入庫人員姓名,
	NVL(H.員工姓名,' ') 出庫人員姓名,
	NVL(I.員工姓名,' ') 放行人員姓名,
	NVL(K.員工姓名,' ') 不限出庫設定姓名,
	J.名稱 製程,
	A.IP位址,
	A.IP位址2,
	NVL(L.部門名稱,' ') 熟成室位置,
	A.加工別,
	0 超時未入庫,
	0 異常,
	1 重覆入庫,
	case when trim(A.熟成入庫日期)||A.熟成入庫時間 > trim(A.熟成出庫日期)||A.熟成出庫時間 then trim(A.熟成入庫日期)||A.熟成入庫時間 else trim(A.熟成出庫日期)||A.熟成出庫時間 end 最後入出日時,
	C.流水編號 單頭流水編號,
	1 來源,
	C.邏輯值一 優先冷鏈
FROM 
	FIL004K A
	INNER JOIN FIL0030 C ON A.單別 = C.單據類別 AND A.單號 = C.單據編號
	INNER JOIN FIL0032 D ON D.製令單別 = A.製令類別 AND D.製令單號 = A.製令單號
	LEFT JOIN FIL0010 G ON A.入庫人員 = G.員工編號
	LEFT JOIN FIL0010 H ON A.出庫人員 = H.員工編號
	LEFT JOIN FIL0010 I ON A.放行人員 = I.員工編號
	LEFT JOIN ViewFil310N J ON J.代碼 = A.製程代碼
	LEFT JOIN FIL0010 K ON A.不限出庫設定人員 = K.員工編號
	LEFT JOIN ViewFIL0012 L ON A.IP位址 = L.部門編號
	
	);

-- Oracle user_views
CREATE VIEW "VIEWFIL404C4_V2" ("單別", "單號", "序號", "製令類別", "製令單號", "產品編號", "產品名稱", "熟成入庫日期", "熟成入庫時間", "熟成出庫日期", "熟成出庫時間", "不限出庫時間", "熟成狀態", "入庫狀態", "出庫狀態", "本製程編號", "PLC抓取米數", "庫存數", "製品厚度", "熟成條件", "可提早出庫", "入庫人員姓名", "出庫人員姓名", "放行人員姓名", "不限出庫設定姓名", "製程", "IP位址", "熟成室位置", "加工別", "超時未入庫", "異常", "重覆入庫", "單頭流水編號", "來源") AS (  
SELECT 
	A.單別 單別, 
	A.單號 單號,
	A.序號 序號,
	C.歸屬類別 製令類別,
	C.歸屬編號 製令單號,
	D.產品編號 產品編號,
	D.產品名稱 產品名稱,
	A.入庫日期 熟成入庫日期,
	A.入庫時間 熟成入庫時間,
	A.出庫日期 熟成出庫日期,
	A.出庫時間 熟成出庫時間,
	DECODE(E.Logical2 + A.不限出庫,0,0,1) 不限出庫時間,
	nvl(case
		 when A.重覆入庫 = 1 and A.出庫日期 > '00000000' then '4' 
		 when A.重覆入庫 = 1 and A.入庫日期 > '00000000' and A.出庫日期 <= '00000000' then '2' 
		 when A.入庫日期 <= '00000000' and sysdate > to_date(trim(B.標籤列印日期一)||trim(B.標籤列印時間一), 'YYYYMMDDHH24:MI:SS') + 1/24 then '1' 
	     when A.入庫日期 > '00000000' and A.出庫日期 <= '00000000' then '2'
		 when A.出庫日期 > '00000000' and to_date(trim(A.出庫日期)||trim(A.出庫時間), 'YYYYMMDDHH24:MI:SS') < to_date(trim(A.入庫日期)||trim(A.入庫時間), 'YYYYMMDDHH24:MI:SS') + E.數值10 / 24 then '3' 		 
		 when A.出庫日期 > '00000000' and to_date(trim(A.出庫日期)||trim(A.出庫時間), 'YYYYMMDDHH24:MI:SS') between to_date(trim(A.入庫日期)||trim(A.入庫時間), 'YYYYMMDDHH24:MI:SS') + E.數值10 / 24 and to_date(trim(A.入庫日期)||trim(A.入庫時間), 'YYYYMMDDHH24:MI:SS') + E.數值11 / 24 then '4' 		 
		 when A.出庫日期 > '00000000' and to_date(trim(A.出庫日期)||trim(A.出庫時間), 'YYYYMMDDHH24:MI:SS') > to_date(trim(A.入庫日期)||trim(A.入庫時間), 'YYYYMMDDHH24:MI:SS') + E.數值11 / 24 then '5' 
		 else ' ' 
	end,' ') 熟成狀態,
	nvl(case 
		 when A.重覆入庫 = 1 and A.入庫日期 > '00000000' then '2'
		 when A.重覆入庫 = 1 and A.入庫日期 <= '00000000' then ' '
		 when A.入庫日期 <= '00000000' and  sysdate > (to_date(trim(B.標籤列印日期一)||trim(B.標籤列印時間一), 'YYYYMMDDHH24:MI:SS')  + interval '30' minute) then '1' 
		 when A.入庫日期 > '00000000' and to_date(trim(A.入庫日期)||trim(A.入庫時間), 'YYYYMMDDHH24:MI:SS') <= to_date(trim(B.標籤列印日期一)||trim(B.標籤列印時間一), 'YYYYMMDDHH24:MI:SS')  + interval '30' minute then '2'
		 when A.入庫日期 > '00000000' and to_date(trim(A.入庫日期)||trim(A.入庫時間), 'YYYYMMDDHH24:MI:SS') > to_date(trim(B.標籤列印日期一)||trim(B.標籤列印時間一), 'YYYYMMDDHH24:MI:SS')  + interval '30' minute  then '3'
		else ' '
		end,' ') 入庫狀態,
	nvl(case 
		 when A.重覆入庫 = 1 and A.出庫日期 > '00000000' then '3'
		 when A.重覆入庫 = 1 and A.出庫日期 <= '00000000' then '1'
		 when (A.出庫日期 <= '00000000' and (E.Logical2 + A.不限出庫) = 0) then '1' 
		 when (A.出庫日期 > '00000000' and to_date(trim(A.出庫日期)||trim(A.出庫時間), 'YYYYMMDDHH24:MI:SS') < to_date(trim(A.入庫日期)||trim(A.入庫時間), 'YYYYMMDDHH24:MI:SS') + E.數值10 / 24  and (E.Logical2 + A.不限出庫) = 0) then '2' 
		 when (A.出庫日期 > '00000000' and ((E.Logical2 + A.不限出庫) > 0 or (to_date(trim(A.出庫日期)||trim(A.出庫時間), 'YYYYMMDDHH24:MI:SS') between to_date(trim(A.入庫日期)||trim(A.入庫時間), 'YYYYMMDDHH24:MI:SS') + E.數值10 / 24 and to_date(trim(A.入庫日期)||trim(A.入庫時間), 'YYYYMMDDHH24:MI:SS') + E.數值11 / 24))) then '3' 		 		 
		 when (A.出庫日期 > '00000000' and to_date(trim(A.出庫日期)||trim(A.出庫時間), 'YYYYMMDDHH24:MI:SS') > to_date(trim(A.入庫日期)||trim(A.入庫時間), 'YYYYMMDDHH24:MI:SS') + E.數值11 / 24  and (E.Logical2 + A.不限出庫) = 0) then '4' 
		else ' ' 
		end,' ') 出庫狀態,		
	M.產品編號 本製程編號,
	M.異動單價 PLC抓取米數,
	M.異動單價-M.夾鏈費 庫存數,
	M.數值3 製品厚度,
	decode(A.重覆入庫,1,to_char('無限制'),to_char(E.文字4)) 熟成條件,
	A.可提早出庫,
	NVL(G.員工姓名,' ') 入庫人員姓名,
	NVL(H.員工姓名,' ') 出庫人員姓名,
	NVL(I.員工姓名,' ') 放行人員姓名,
	NVL(K.員工姓名,' ') 不限出庫設定姓名,
	J.名稱 製程,
	A.熟成室位置 IP位址,
	NVL(L.部門名稱,A.熟成室位置) 熟成室位置,
	E.交貨日期_次批 加工別,
	case when A.重覆入庫 = 1 then 0
		 when 
			nvl(case when A.入庫日期 <= '00000000' and  sysdate > (to_date(trim(B.標籤列印日期一)||trim(B.標籤列印時間一), 'YYYYMMDDHH24:MI:SS')  + interval '30' minute) then '1' 
				 when A.入庫日期 > '00000000' and to_date(trim(A.入庫日期)||trim(A.入庫時間), 'YYYYMMDDHH24:MI:SS') <= to_date(trim(B.標籤列印日期一)||trim(B.標籤列印時間一), 'YYYYMMDDHH24:MI:SS')  + interval '30' minute then '2'
				 when A.入庫日期 > '00000000' and to_date(trim(A.入庫日期)||trim(A.入庫時間), 'YYYYMMDDHH24:MI:SS') > to_date(trim(B.標籤列印日期一)||trim(B.標籤列印時間一), 'YYYYMMDDHH24:MI:SS')  + interval '30' minute  then '3'
			else ' '
			end,' ') = '1' 
		 then 1
		 else 0
	end 超時未入庫,
	case when A.重覆入庫 = 1 then 0 
		 when
			sysdate > (case when A.入庫日期 > '00000000' then to_date(trim(A.入庫日期)||trim(A.入庫時間), 'YYYYMMDDHH24:MI:SS') + E.數值10 / 24 else add_months(sysdate,12) end) and 
			nvl(case when A.入庫日期 <= '00000000' and sysdate > to_date(trim(B.標籤列印日期一)||trim(B.標籤列印時間一), 'YYYYMMDDHH24:MI:SS') + 1/24 then '1' 
			 when A.入庫日期 > '00000000' and A.出庫日期 <= '00000000' then '2'
			 when A.出庫日期 > '00000000' and to_date(trim(A.出庫日期)||trim(A.出庫時間), 'YYYYMMDDHH24:MI:SS') < to_date(trim(A.入庫日期)||trim(A.入庫時間), 'YYYYMMDDHH24:MI:SS') + E.數值10 / 24 then '3' 		 
			 when A.出庫日期 > '00000000' and to_date(trim(A.出庫日期)||trim(A.出庫時間), 'YYYYMMDDHH24:MI:SS') between to_date(trim(A.入庫日期)||trim(A.入庫時間), 'YYYYMMDDHH24:MI:SS') + E.數值10 / 24 and to_date(trim(A.入庫日期)||trim(A.入庫時間), 'YYYYMMDDHH24:MI:SS') + E.數值10 / 24 then '4' 		 
			 when A.出庫日期 > '00000000' and to_date(trim(A.出庫日期)||trim(A.出庫時間), 'YYYYMMDDHH24:MI:SS') > to_date(trim(A.入庫日期)||trim(A.入庫時間), 'YYYYMMDDHH24:MI:SS') + E.數值11 / 24 then '5' 
			 else ' ' 
			end,' ') ='2'
		 then 1
		 else 0
	end 異常,
	A.重覆入庫 重覆入庫,
	C.流水編號 單頭流水編號,
	0 來源
FROM 
	FIL0041_B A
	INNER JOIN FIL0040 M ON A.單別 = M.單據類別 AND A.單號 = M.單據編號 AND A.序號 = M.單據序號
	INNER JOIN FIL0041 B ON A.單別 = B.單別 AND A.單號 = B.單號 AND A.序號 = B.序號
	INNER JOIN FIL0030 C ON A.單別 = C.單據類別 AND A.單號 = C.單據編號
	INNER JOIN FIL0032 D ON C.歸屬類別 = D.製令單別 AND C.歸屬編號 = D.製令單號
	INNER JOIN FIL0031 E ON A.單別 = E.單別 AND A.單號 = E.單號
	LEFT JOIN FIL0010 G ON A.入庫人員 = G.員工編號
	LEFT JOIN FIL0010 H ON A.出庫人員 = H.員工編號
	LEFT JOIN FIL0010 I ON A.放行人員 = I.員工編號
	LEFT JOIN ViewFil310N J ON J.代碼 = E.製程代碼
	LEFT JOIN FIL0010 K ON decode(E.Logical2,1,E.文數字13,A.不限出庫人員) = K.員工編號
	LEFT JOIN ViewFIL0012 L ON A.熟成室位置 = L.部門編號
WHERE
	A.單別 = 'C41' AND
	M.異動類別 = 'A' AND
	(E.製程代碼 = 'C31B' or E.製程代碼 = 'C31C') AND
	E.文字4<>'不用熟成' AND
	M.產品編號<>' '  AND
	B.標籤列印日期一>'20240101'
	
UNION ALL 

SELECT 
	A.單別, 
	A.單號,
	A.序號,
	A.製令類別,
	A.製令單號,
	D.產品編號 產品編號,
	D.產品名稱 產品名稱,
	A.熟成入庫日期,
	A.熟成入庫時間,
	A.熟成出庫日期,
	A.熟成出庫時間,
	0 不限出庫時間,
	A.熟成狀態,
	A.入庫狀態,
	A.出庫狀態,		
	A.本製程編號,
	A.PLC抓取米數,
	A.庫存數,
	A.製品厚度,
	to_char(A.熟成條件) 熟成條件,
	A.可提早出庫,
	NVL(G.員工姓名,' ') 入庫人員姓名,
	NVL(H.員工姓名,' ') 出庫人員姓名,
	NVL(I.員工姓名,' ') 放行人員姓名,
	NVL(K.員工姓名,' ') 不限出庫設定姓名,
	J.名稱 製程,
	A.IP位址,
	NVL(L.部門名稱,' ') 熟成室位置,
	A.加工別,
	0 超時未入庫,
	0 異常,
	1 重覆入庫,
	C.流水編號 單頭流水編號,
	1 來源
FROM 
	FIL004K A
	INNER JOIN FIL0030 C ON A.單別 = C.單據類別 AND A.單號 = C.單據編號
	INNER JOIN FIL0032 D ON D.製令單別 = A.製令類別 AND D.製令單號 = A.製令單號
	LEFT JOIN FIL0010 G ON A.入庫人員 = G.員工編號
	LEFT JOIN FIL0010 H ON A.出庫人員 = H.員工編號
	LEFT JOIN FIL0010 I ON A.放行人員 = I.員工編號
	LEFT JOIN ViewFil310N J ON J.代碼 = A.製程代碼
	LEFT JOIN FIL0010 K ON A.不限出庫設定人員 = K.員工編號
	LEFT JOIN ViewFIL0012 L ON A.IP位址 = L.部門編號
	
	);

-- Oracle user_views
CREATE VIEW "VIEWFIL404C5" ("單別", "單號", "序號", "製令單號", "本製程編號", "加工別", "可提早出庫", "重覆入庫", "熟成狀態", "應出庫日時起", "應出庫日時迄", "熟成入庫日期", "熟成入庫時間", "熟成出庫日期", "熟成出庫時間", "製程代碼") AS (  
SELECT 
	A.單據類別 單別, 
	A.單據編號 單號,
	A.單據序號 序號,
	C.歸屬編號 製令單號,
	A.產品編號 本製程編號,
	E.交貨日期_次批 加工別,	
	A.Logical4 可提早出庫,
	A.Logical5 重覆入庫,
	nvl(case 
		 when A.Logical5 = 1 and A.預交日 > '00000000' then '4' 
		 when A.Logical5 = 1 and A.異動日期 > '00000000' and A.預交日 <= '00000000' then '2' 
		 when A.異動日期 <= '00000000' and sysdate > to_date(trim(B.標籤列印日期一)||trim(B.標籤列印時間一), 'YYYYMMDDHH24:MI:SS') + 1/24 then '1' 
	     when A.異動日期 > '00000000' and A.預交日 <= '00000000' then '2'
		 when A.預交日 > '00000000' and to_date(trim(A.預交日)||trim(B.Time4), 'YYYYMMDDHH24:MI:SS') < to_date(trim(A.異動日期)||trim(B.Time3), 'YYYYMMDDHH24:MI:SS') + E.數值10 / 24 then '3' 		 
		 when A.預交日 > '00000000' and to_date(trim(A.預交日)||trim(B.Time4), 'YYYYMMDDHH24:MI:SS') between to_date(trim(A.異動日期)||trim(B.Time3), 'YYYYMMDDHH24:MI:SS') + E.數值10 / 24 and to_date(trim(A.異動日期)||trim(B.Time3), 'YYYYMMDDHH24:MI:SS') + E.數值11 / 24 then '4' 		 
		 when A.預交日 > '00000000' and to_date(trim(A.預交日)||trim(B.Time4), 'YYYYMMDDHH24:MI:SS') > to_date(trim(A.異動日期)||trim(B.Time3), 'YYYYMMDDHH24:MI:SS') + E.數值11 / 24 then '5' 
		 else ' ' 
	end,' ') 熟成狀態,	
	case when A.異動日期 > '00000000' then to_date(trim(A.異動日期)||trim(B.Time3), 'YYYYMMDDHH24:MI:SS') + E.數值10 / 24 else add_months(sysdate,12) end 應出庫日時起,
	case when A.異動日期 > '00000000' then to_date(trim(A.異動日期)||trim(B.Time3), 'YYYYMMDDHH24:MI:SS') + E.數值11 / 24 else add_months(sysdate,12) end 應出庫日時迄	,
	A.異動日期 熟成入庫日期,
	B.Time3 熟成入庫時間,
	A.預交日 熟成出庫日期,
	B.Time4 熟成出庫時間,
	E.製程代碼
FROM 
	FIL0040 A
	INNER JOIN FIL0041 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號 AND A.單據序號 = B.序號	
	INNER JOIN FIL0030 C ON A.單據類別 = C.單據類別 AND A.單據編號 = C.單據編號
	INNER JOIN FIL0031 E ON A.單據類別 = E.單別 AND A.單據編號 = E.單號
WHERE
	A.單據類別 = 'C41' AND
	A.異動類別 = 'A' AND
	(E.製程代碼 = 'C31B' or E.製程代碼 = 'C31C') AND
	E.文字4<>'不用熟成' AND
	A.產品編號<>' ' AND
	B.標籤列印日期一>'20240101'
	
UNION ALL 

SELECT 
	A.單別, 
	A.單號,
	A.序號,
	A.製令單號,
	A.本製程編號,
	A.加工別,	
	A.可提早出庫,
	A.重覆入庫,	
	A.熟成狀態,
	A.應出庫日時起,
	A.應出庫日時迄,
	A.熟成入庫日期,
	A.熟成入庫時間,
	A.熟成出庫日期,
	A.熟成出庫時間,
	E.製程代碼
FROM	
	FIL004K A	
	INNER JOIN FIL0031 E ON A.單別 = E.單別 AND A.單號 = E.單號
	);

-- Oracle user_views
CREATE VIEW "VIEWFIL404C5A_V1" ("單別", "單號", "序號", "製令單號", "本製程編號", "加工別", "可提早出庫", "重覆入庫", "冷鏈狀態", "應出庫日時起", "應出庫日時迄", "冷鏈入庫日期", "冷鏈入庫時間", "冷鏈出庫日期", "冷鏈出庫時間", "製程代碼", "最後入出日時") AS (  
SELECT 
	A.單別 單別, 
	A.單號 單號,
	A.序號 序號,
	C.歸屬編號 製令單號,
	M.產品編號 本製程編號,
	E.交貨日期_次批 加工別,	
	A.可提早出庫,
	A.重覆入庫 重覆入庫,
	nvl(case
		 when A.重覆入庫 = 1 and A.出庫日期 > '00000000' then '4' 
		 when A.重覆入庫 = 1 and A.入庫日期 > '00000000' and A.出庫日期 <= '00000000' then '2' 
		 when A.入庫日期 <= '00000000' and sysdate > to_date(trim(B.標籤列印日期一)||trim(B.標籤列印時間一), 'YYYYMMDDHH24:MI:SS') + 1/24 then '1' 
	     when A.入庫日期 > '00000000' and A.出庫日期 <= '00000000' then '2'
		 when A.出庫日期 > '00000000' and to_date(trim(A.出庫日期)||trim(A.出庫時間), 'YYYYMMDDHH24:MI:SS') < to_date(trim(A.入庫日期)||trim(A.入庫時間), 'YYYYMMDDHH24:MI:SS') + E.數值10 / 24 then '3' 		 
		 when A.出庫日期 > '00000000' and to_date(trim(A.出庫日期)||trim(A.出庫時間), 'YYYYMMDDHH24:MI:SS') between to_date(trim(A.入庫日期)||trim(A.入庫時間), 'YYYYMMDDHH24:MI:SS') + E.數值10 / 24 and to_date(trim(A.入庫日期)||trim(A.入庫時間), 'YYYYMMDDHH24:MI:SS') + E.數值11 / 24 then '4' 		 
		 when A.出庫日期 > '00000000' and to_date(trim(A.出庫日期)||trim(A.出庫時間), 'YYYYMMDDHH24:MI:SS') > to_date(trim(A.入庫日期)||trim(A.入庫時間), 'YYYYMMDDHH24:MI:SS') + E.數值11 / 24 then '5' 
		 else ' ' 
	end,' ') 冷鏈狀態,
	case when A.入庫日期 > '00000000' then to_date(trim(A.入庫日期)||trim(A.入庫時間), 'YYYYMMDDHH24:MI:SS') + E.數值10 / 24 else add_months(sysdate,12) end 應出庫日時起,
	case when A.入庫日期 > '00000000' then to_date(trim(A.入庫日期)||trim(A.入庫時間), 'YYYYMMDDHH24:MI:SS') + E.數值11 / 24 else add_months(sysdate,12) end 應出庫日時迄,
	A.入庫日期 冷鏈入庫日期,
	A.入庫時間 冷鏈入庫時間,
	A.出庫日期 冷鏈出庫日期,
	A.出庫時間 冷鏈出庫時間,
	E.製程代碼,
	case when trim(A.入庫日期)||A.入庫時間 > trim(A.出庫日期)||A.出庫時間 then trim(A.入庫日期)||A.入庫時間 else trim(A.出庫日期)||A.出庫時間 end 最後入出日時
FROM 
	FIL0041_BA A
	INNER JOIN FIL0040 M ON A.單別 = M.單據類別 AND A.單號 = M.單據編號 AND A.序號 = M.單據序號
	INNER JOIN FIL0041 B ON A.單別 = B.單別 AND A.單號 = B.單號 AND A.序號 = B.序號
	INNER JOIN FIL0030 C ON A.單別 = C.單據類別 AND A.單號 = C.單據編號
	INNER JOIN FIL0031 E ON A.單別 = E.單別 AND A.單號 = E.單號
WHERE
	A.單別 = 'C41' AND
	M.異動類別 = 'A' AND
	(E.製程代碼 = 'C31B' or E.製程代碼 = 'C31C') AND
	E.文字5<>'不用冷鏈' AND
	M.產品編號<>' '  AND
	B.標籤列印日期一>'20240101'
	
UNION ALL 

SELECT 
	A.單別, 
	A.單號,
	A.序號,
	A.製令單號,
	A.本製程編號,
	A.加工別,	
	A.可提早出庫,
	A.重覆入庫,	
	A.冷鏈狀態,
	A.應出庫日時起,
	A.應出庫日時迄,
	A.冷鏈入庫日期,
	A.冷鏈入庫時間,
	A.冷鏈出庫日期,
	A.冷鏈出庫時間,
	E.製程代碼,
	case when trim(A.冷鏈入庫日期)||A.冷鏈入庫時間 > trim(A.冷鏈出庫日期)||A.冷鏈出庫時間 then trim(A.冷鏈入庫日期)||A.冷鏈入庫時間 else trim(A.冷鏈出庫日期)||A.冷鏈出庫時間 end 最後入出日時
FROM	
	FIL004KA A	
	INNER JOIN FIL0031 E ON A.單別 = E.單別 AND A.單號 = E.單號
	);

-- Oracle user_views
CREATE VIEW "VIEWFIL404C5_V1" ("單別", "單號", "序號", "製令單號", "本製程編號", "加工別", "可提早出庫", "重覆入庫", "熟成狀態", "應出庫日時起", "應出庫日時迄", "熟成入庫日期", "熟成入庫時間", "熟成出庫日期", "熟成出庫時間", "製程代碼", "最後入出日時") AS (  
SELECT 
	A.單別 單別, 
	A.單號 單號,
	A.序號 序號,
	C.歸屬編號 製令單號,
	M.產品編號 本製程編號,
	E.交貨日期_次批 加工別,	
	A.可提早出庫,
	A.重覆入庫 重覆入庫,
	nvl(case
		 when A.重覆入庫 = 1 and A.出庫日期 > '00000000' then '4' 
		 when A.重覆入庫 = 1 and A.入庫日期 > '00000000' and A.出庫日期 <= '00000000' then '2' 
		 when A.入庫日期 <= '00000000' and sysdate > to_date(trim(B.標籤列印日期一)||trim(B.標籤列印時間一), 'YYYYMMDDHH24:MI:SS') + 1/24 then '1' 
	     when A.入庫日期 > '00000000' and A.出庫日期 <= '00000000' then '2'
		 when A.出庫日期 > '00000000' and to_date(trim(A.出庫日期)||trim(A.出庫時間), 'YYYYMMDDHH24:MI:SS') < to_date(trim(A.入庫日期)||trim(A.入庫時間), 'YYYYMMDDHH24:MI:SS') + E.數值10 / 24 then '3' 		 
		 when A.出庫日期 > '00000000' and to_date(trim(A.出庫日期)||trim(A.出庫時間), 'YYYYMMDDHH24:MI:SS') between to_date(trim(A.入庫日期)||trim(A.入庫時間), 'YYYYMMDDHH24:MI:SS') + E.數值10 / 24 and to_date(trim(A.入庫日期)||trim(A.入庫時間), 'YYYYMMDDHH24:MI:SS') + E.數值11 / 24 then '4' 		 
		 when A.出庫日期 > '00000000' and to_date(trim(A.出庫日期)||trim(A.出庫時間), 'YYYYMMDDHH24:MI:SS') > to_date(trim(A.入庫日期)||trim(A.入庫時間), 'YYYYMMDDHH24:MI:SS') + E.數值11 / 24 then '5' 
		 else ' ' 
	end,' ') 熟成狀態,
	case when A.入庫日期 > '00000000' then to_date(trim(A.入庫日期)||trim(A.入庫時間), 'YYYYMMDDHH24:MI:SS') + E.數值10 / 24 else add_months(sysdate,12) end 應出庫日時起,
	case when A.入庫日期 > '00000000' then to_date(trim(A.入庫日期)||trim(A.入庫時間), 'YYYYMMDDHH24:MI:SS') + E.數值11 / 24 else add_months(sysdate,12) end 應出庫日時迄,
	A.入庫日期 熟成入庫日期,
	A.入庫時間 熟成入庫時間,
	A.出庫日期 熟成出庫日期,
	A.出庫時間 熟成出庫時間,
	E.製程代碼,
	case when trim(A.入庫日期)||A.入庫時間 > trim(A.出庫日期)||A.出庫時間 then trim(A.入庫日期)||A.入庫時間 else trim(A.出庫日期)||A.出庫時間 end 最後入出日時
FROM 
	FIL0041_B A
	INNER JOIN FIL0040 M ON A.單別 = M.單據類別 AND A.單號 = M.單據編號 AND A.序號 = M.單據序號
	INNER JOIN FIL0041 B ON A.單別 = B.單別 AND A.單號 = B.單號 AND A.序號 = B.序號
	INNER JOIN FIL0030 C ON A.單別 = C.單據類別 AND A.單號 = C.單據編號
	INNER JOIN FIL0031 E ON A.單別 = E.單別 AND A.單號 = E.單號
WHERE
	A.單別 = 'C41' AND
	M.異動類別 = 'A' AND
	(E.製程代碼 = 'C31B' or E.製程代碼 = 'C31C') AND
	E.文字4<>'不用熟成' AND
	M.產品編號<>' '  AND
	B.標籤列印日期一>'20240101'
	
UNION ALL 

SELECT 
	A.單別, 
	A.單號,
	A.序號,
	A.製令單號,
	A.本製程編號,
	A.加工別,	
	A.可提早出庫,
	A.重覆入庫,	
	A.熟成狀態,
	A.應出庫日時起,
	A.應出庫日時迄,
	A.熟成入庫日期,
	A.熟成入庫時間,
	A.熟成出庫日期,
	A.熟成出庫時間,
	E.製程代碼,
	case when trim(A.熟成入庫日期)||A.熟成入庫時間 > trim(A.熟成出庫日期)||A.熟成出庫時間 then trim(A.熟成入庫日期)||A.熟成入庫時間 else trim(A.熟成出庫日期)||A.熟成出庫時間 end 最後入出日時
FROM	
	FIL004K A	
	INNER JOIN FIL0031 E ON A.單別 = E.單別 AND A.單號 = E.單號
	);

-- Oracle user_views
CREATE VIEW "VIEWFIL404CA" ("單別", "單號", "前製程米數", "PLC抓取米數", "合理剔除數", "不良剔除數", "檢品數量", "線外不良剔除數", "線內不良剔除數", "試刷米數", "回庫數量") AS (
SELECT 
		A.單據類別 單別, 
		A.單據編號 單號,
		SUM(A.異動數量) 前製程米數,
		SUM(A.異動單價) PLC抓取米數,
		SUM(A.燙金費) 合理剔除數,
		SUM(A.毛重) 不良剔除數,
		SUM(A.贈品數量) 檢品數量,
		SUM(A.雷射費) 線外不良剔除數,
		SUM(A.夾鏈費) 線內不良剔除數,
		SUM(A.氣閥費) 試刷米數,
		max(nvl(E.回庫數量,0))+SUM(A.退庫數量) 回庫數量
	FROM 
		FIL0040 A
		INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
		LEFT JOIN FIL0041 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號 AND A.單據序號 = C.序號
		LEFT JOIN 
		(
			SELECT 
				A.單據類別,
				A.單據編號,
				SUM(A.贈品數量) 回庫數量
			FROM
				FIL0040 A
				INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
				INNER JOIN FIL0041 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號 AND A.單據序號 = C.序號
			WHERE
				A.單據類別 = 'C41' AND
				A.異動類別= 'G' AND
				B.製程代碼 = 'C31C'	AND
				C.標籤列印次數 > 0
			GROUP BY
				A.單據類別, 
				A.單據編號
		) E ON E.單據類別 = A.單據類別 AND E.單據編號 = A.單據編號
	WHERE
		A.單據類別 = 'C41' AND
		A.異動類別 = 'A' AND
		B.製程代碼 = 'C31C' 
	GROUP BY
		A.單據類別, 
		A.單據編號
);

-- Oracle user_views
CREATE VIEW "VIEWFIL404CB" ("單別", "單號", "群組序號", "前一筆結餘", "前製程米數", "PLC抓取米數", "合理剔除數", "不良剔除數", "檢品數量") AS (
SELECT 
		A.單據類別 單別, 
		A.單據編號 單號,
		A.鐵條費 群組序號, 
		SUM(A.數值1) 前一筆結餘,
		SUM(A.異動數量) 前製程米數,
		SUM(A.異動單價) PLC抓取米數,
		SUM(A.燙金費) 合理剔除數,
		SUM(A.毛重) 不良剔除數,
		SUM(A.贈品數量) 檢品數量
	FROM 
		FIL0040 A
		INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
		LEFT JOIN FIL0041 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號 AND A.單據序號 = C.序號
	WHERE
		A.單據類別 = 'C41' AND
		A.異動類別 = 'A' AND
		B.製程代碼 = 'C31C' 
	GROUP BY
		A.單據類別, 
		A.單據編號,
		A.鐵條費
);

-- Oracle user_views
CREATE VIEW "VIEWFIL404CC" ("製令單別", "製令單號", "加工別", "製程代碼", "作業日期", "機台代碼", "數量") AS (  
SELECT 
	C.歸屬類別 製令單別,
	C.歸屬編號 製令單號,
	decode(B.製程代碼,'C31E',' ',B.交貨日期_次批) 加工別,
	B.製程代碼,
	C.單據日期 作業日期,
	B.機台代碼,
	sum(decode(B.製程代碼,'C31D',(case when A.材積+nvl(D.包裝數量,0)<A.異動單價-A.QRNO then 0 else A.材積+nvl(D.包裝數量,0)-A.異動單價-A.QRNO end)/1000,'C31E',decode(D.數值14, 0, A.贈品數量,D.數值14),A.異動單價 - A.夾鏈費)) 數量
FROM 
	FIL0040 A
	INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
	INNER JOIN FIL0030 C ON A.單據類別 = C.單據類別 AND A.單據編號 = C.單據編號	
	LEFT JOIN FIL0041 D ON A.單據類別 = D.單別 AND A.單據編號 = D.單號 AND A.單據序號 = D.序號
WHERE
	A.單據類別 = 'C41' AND
	A.異動類別 = 'A' AND
	(B.製程代碼 between 'C31A' and 'C31E' or B.製程代碼='C32D')
GROUP BY
	C.歸屬類別,
	C.歸屬編號,
	B.交貨日期_次批,
	C.單據日期,
	B.製程代碼,
	B.機台代碼);

-- Oracle user_views
CREATE VIEW "VIEWFIL404CD" ("製令單別", "製令單號", "加工別", "製程代碼", "數量") AS (  
SELECT 
	C.歸屬類別 製令單別,
	C.歸屬編號 製令單號,
	B.交貨日期_次批 加工別,
	B.製程代碼,
	sum(A.異動單價 - A.夾鏈費) 數量
FROM 
	FIL0040 A
	INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
	INNER JOIN FIL0030 C ON A.單據類別 = C.單據類別 AND A.單據編號 = C.單據編號	
WHERE
	A.單據類別 = 'C41' AND
	A.異動類別 = 'A' AND
	(B.製程代碼 between 'C31A' AND 'C31C' or B.製程代碼 = 'C32D')
GROUP BY
	C.歸屬類別,
	C.歸屬編號,
	B.交貨日期_次批,
	B.製程代碼);

-- Oracle user_views
CREATE VIEW "VIEWFIL404CD0" ("製令單別", "製令單號", "前製程米數", "PLC抓取米數", "合理剔除數", "不良剔除數", "檢品數量", "線外不良剔除數", "線內不良剔除數", "試刷米數", "回庫數量", "生產條件米數") AS (
SELECT 
		A1.歸屬類別 製令單別, 
		A1.歸屬編號 製令單號,
		SUM(A.異動數量) 前製程米數,
		SUM(A.異動單價) PLC抓取米數,
		SUM(A.燙金費) 合理剔除數,
		SUM(A.毛重) 不良剔除數,
		SUM(A.贈品數量) 檢品數量,
		SUM(A.雷射費) 線外不良剔除數,
		SUM(A.夾鏈費) 線內不良剔除數,
		SUM(A.氣閥費) 試刷米數,
		max(nvl(E.回庫數量,0)) 回庫數量,
		max(nvl(D.印刷米數,0)*1000) 生產條件米數
	FROM 
		FIL0040 A
		INNER JOIN FIL0030 A1 ON A.單據類別 = A1.單據類別 AND A.單據編號 = A1.單據編號
		INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
		LEFT JOIN FIL0041 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號 AND A.單據序號 = C.序號
		LEFT JOIN
		(SELECT 
			F.製令單別, 
			F.製令單號, 
			sum(F.印刷米數) 印刷米數
		FROM 
			FIL0033 F 
		WHERE 
			F.印刷基材<>' ' 
		GROUP BY
			F.製令單別, 
			F.製令單號) D ON D.製令單別 = A1.歸屬類別 AND D.製令單號 = A1.歸屬編號 
		LEFT JOIN 
		(
			SELECT 
				A.單據類別,
				A.單據編號,
				SUM(A.贈品數量) 回庫數量
			FROM
				FIL0040 A
				INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
				INNER JOIN FIL0041 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號 AND A.單據序號 = C.序號
			WHERE
				A.單據類別 = 'C41' AND
				A.異動類別= 'G' AND
				B.製程代碼 = 'C31C'	AND
				C.標籤列印次數 > 0
			GROUP BY
				A.單據類別, 
				A.單據編號
		) E ON E.單據類別 = A.單據類別 AND E.單據編號 = A.單據編號
	WHERE
		A.單據類別 = 'C41' AND
		A.異動類別 = 'A' AND
		B.製程代碼 = 'C31C' 
	GROUP BY
		A1.歸屬類別, 
		A1.歸屬編號
);

-- Oracle user_views
CREATE VIEW "VIEWFIL404CD1" ("單據類別", "單據編號", "改件調機", "製令單別", "製令單號", "前製程米數", "PLC抓取米數", "合理剔除數", "不良剔除數", "檢品數量", "線外不良剔除數", "線內不良剔除數", "試刷米數", "回庫數量", "生產條件米數") AS (
SELECT 
		A.單據類別, 
		A.單據編號,
		B.Logical6 改件調機,
		max(A1.歸屬類別) 製令單別, 
		max(A1.歸屬編號) 製令單號,
		SUM(A.異動數量) 前製程米數,
		SUM(A.異動單價) PLC抓取米數,
		SUM(A.燙金費) 合理剔除數,
		SUM(A.毛重) 不良剔除數,
		SUM(A.贈品數量) 檢品數量,
		SUM(A.雷射費) 線外不良剔除數,
		SUM(A.夾鏈費) 線內不良剔除數,
		SUM(A.氣閥費) 試刷米數,
		max(nvl(E.回庫數量,0)) 回庫數量,
		max(nvl(D.印刷米數,0)*1000) 生產條件米數
	FROM 
		FIL0040 A
		INNER JOIN FIL0030 A1 ON A.單據類別 = A1.單據類別 AND A.單據編號 = A1.單據編號 and A1.歸屬編號<>' '
		INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
		LEFT JOIN FIL0041 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號 AND A.單據序號 = C.序號
		LEFT JOIN
		(SELECT 
			F.製令單別, 
			F.製令單號, 
			sum(F.印刷米數) 印刷米數
		FROM 
			FIL0033 F 
		WHERE 
			F.印刷基材<>' ' 
		GROUP BY
			F.製令單別, 
			F.製令單號
		) D ON D.製令單別 = A1.歸屬類別 AND D.製令單號 = A1.歸屬編號 
		LEFT JOIN 
		(
			SELECT 
				A.單據類別,
				A.單據編號,
				SUM(A.贈品數量) 回庫數量
			FROM
				FIL0040 A
				INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
				INNER JOIN FIL0041 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號 AND A.單據序號 = C.序號
			WHERE
				A.單據類別 = 'C41' AND
				A.異動類別= 'G' AND
				B.製程代碼 = 'C31C'	AND
				C.標籤列印次數 > 0
			GROUP BY
				A.單據類別, 
				A.單據編號
		) E ON E.單據類別 = A.單據類別 AND E.單據編號 = A.單據編號
	WHERE
		A.單據類別 = 'C41' AND
		A.異動類別 = 'A' AND
		B.製程代碼 = 'C31C' 
	GROUP BY
		A.單據類別, 
		A.單據編號,
		B.Logical6
);

-- Oracle user_views
CREATE VIEW "VIEWFIL404CD2" ("製令單別", "製令單號", "前製程米數", "PLC抓取米數", "合理剔除數", "不良剔除數", "檢品數量", "線外不良剔除數", "線內不良剔除數", "試刷米數", "回庫數量", "生產條件米數") AS (
SELECT 
		A.歸屬類別 製令單別, 
		A.歸屬編號 製令單號,
		SUM(M.異動數量) 前製程米數,
		SUM(M.異動單價) PLC抓取米數,
		SUM(M.燙金費) 合理剔除數,
		SUM(M.毛重) 不良剔除數,
		SUM(M.贈品數量) 檢品數量,
		SUM(M.雷射費) 線外不良剔除數,
		SUM(M.夾鏈費) 線內不良剔除數,
		SUM(M.氣閥費) 試刷米數,
		max(nvl(ME.回庫數量,0)) 回庫數量,
		max(nvl(MD.印刷米數,0)*1000) 生產條件米數
	FROM 
		FIL0040 M
		INNER JOIN FIL0030 A ON M.單據類別 = A.單據類別 AND M.單據編號 = A.單據編號
		INNER JOIN FIL0031 B ON M.單據類別 = B.單別 AND M.單據編號 = B.單號
		INNER JOIN ViewFIL4030 C ON A.歸屬類別 = C.製令單別 AND A.歸屬編號 = C.製令單號
		LEFT JOIN ViewFIL310P D ON B.機台代碼 = D.代碼
		LEFT JOIN FIL0010 E ON A.業務員 = E.員工編號
		LEFT JOIN FIL0012 F ON B.材料編號一 = F.產品編號
		LEFT JOIN FIL0012 G ON B.材料編號二 = G.產品編號
		LEFT JOIN FIL0012 H ON B.材料編號三 = H.產品編號
		LEFT JOIN FIL0010 Z1 ON A.填表人 = Z1.員工編號
		LEFT JOIN FIL0010 Z2 ON A.最後更新者 = Z2.員工編號
		LEFT JOIN ViewOfObjProperties Z3 ON A.流水編號 = Z3.單據流水號
		LEFT JOIN FIL0033 Z5 ON A.歸屬類別 = Z5.製令單別 AND A.歸屬編號 = Z5.製令單號 AND Z5.加工別='A'
		LEFT JOIN 
		(SELECT A.單別,A.單號,COUNT(序號) CCP筆數 FROM FIL004I A GROUP BY A.單別,A.單號) J ON J.單別=A.單據類別 AND J.單號=A.單據編號
		LEFT JOIN FIL0041 MC ON M.單據類別 = MC.單別 AND M.單據編號 = MC.單號 AND M.單據序號 = MC.序號
		LEFT JOIN
		(SELECT 
			F.製令單別, 
			F.製令單號, 
			sum(F.印刷米數) 印刷米數
		FROM 
			FIL0033 F 
		WHERE 
			F.印刷基材<>' ' 
		GROUP BY
			F.製令單別, 
			F.製令單號) MD ON MD.製令單別 = A.歸屬類別 AND MD.製令單號 = A.歸屬編號 
		LEFT JOIN 
		(
			SELECT 
				M.單據類別,
				M.單據編號,
				SUM(M.贈品數量) 回庫數量
			FROM
				FIL0040 M
				INNER JOIN FIL0031 B ON M.單據類別 = B.單別 AND M.單據編號 = B.單號
				INNER JOIN FIL0041 MC ON M.單據類別 = MC.單別 AND M.單據編號 = MC.單號 AND M.單據序號 = MC.序號
			WHERE
				M.單據類別 = 'C41' AND
				M.異動類別= 'G' AND
				B.製程代碼 = 'C31C'	AND
				MC.標籤列印次數 > 0
			GROUP BY
				M.單據類別, 
				M.單據編號
		) ME ON ME.單據類別 = M.單據類別 AND ME.單據編號 = M.單據編號
	WHERE
		M.單據類別 = 'C41' AND
		M.異動類別 = 'A' AND
		B.製程代碼 = 'C31C' 
	GROUP BY
		A.歸屬類別, 
		A.歸屬編號
);

-- Oracle user_views
CREATE VIEW "VIEWFIL404D1" ("單別", "單號", "作業日期", "製令單別", "製令單號", "公司代碼", "公司名稱", "訂單單別", "訂單單號", "主旨", "機台代碼", "機台名稱", "加工別", "本日件數順序", "客戶編號", "客戶名稱", "產品編號", "產品名稱", "產品規格", "側邊料", "共版", "尾數需待重整", "待補", "結束", "改件調機", "頭出尾出", "頭出尾出說明", "開始時間", "結束時間", "條數", "撒粉量", "前置耗時", "總耗時", "成捲寬度", "成捲長度", "加工速度RPM", "加工速度M", "報廢數", "重整數", "每箱捲數", "待補日報", "簽核系統", "備註", "流水編號", "作業人員", "作業人員姓名", "確認碼", "簽核狀態", "填表人", "單位主管流水編號", "員工流水編號", "填表人姓名", "填表日", "OPRP次數", "最後更新者", "更新者姓名", "最後更新日") AS (                                                                                                                                                      SELECT
	A.單據類別 單別,
	A.單據編號 單號,
	A.單據日期 作業日期,
	A.歸屬類別 製令單別,
	A.歸屬編號 製令單號,
	C.公司代碼,
	C.公司名稱,
	C.訂單單別,
	C.訂單單號,
	A.單據編號||'('||trim(A.單據類別)||')'||'/製令:'||nvl(A.歸屬編號, ' ')||'/'||C.產品名稱 主旨,
	B.機台代碼,
	nvl(D.名稱, ' ') 機台名稱,
	decode(B.交貨日期_次批 ,'A','A材','B','B材','C','底邊','D','A側','E','B側',' ') 加工別,
	B.交貨日期_天 本日件數順序,
	C.客戶編號,
	C.客戶名稱,
	C.產品編號,
	C.產品名稱,
	C.產品規格,
	B.Logical1 側邊料,
	B.Logical2 共版,
	B.Logical3 尾數需待重整,
	B.Logical4 待補,
	B.Logical5 結束,
	B.Logical6 改件調機,
	B.運輸方式 頭出尾出,
	decode(B.運輸方式, 'A', '頭出', 'B', '尾出', 'C', '均可', ' ') 頭出尾出說明,
	B.時間一 開始時間,
	B.時間五 結束時間,
	B.數值1 條數,
	B.數值2 撒粉量,
	B.數值3 前置耗時,
	decode(B.時間五,'000000',0,(to_date(to_char(case when B.時間五>B.時間一 then to_date(A.單據日期,'yyyymmdd') else to_date(A.單據日期,'yyyymmdd')+1 end,'yyyymmdd')||B.時間五,'yyyymmddhh24miss')- 
	to_date(trim(A.單據日期)||B.時間一,'yyyymmddhh24miss'))*24) 總耗時,
	B.數值4 成捲寬度,
	B.數值5 成捲長度,
	B.數值6 加工速度rpm,
	B.數值7 加工速度M,
	B.數值8 報廢數,
	B.數值9 重整數,	
	B.數值10 每箱捲數,
	B.文數字9 待補日報,
	A.簽核系統, 
	A.備註, 
	A.流水編號,
	A.業務員 作業人員,
	nvl(E.員工姓名,' ') 作業人員姓名, 
	A.確認碼,
	nvl(Z3.簽核狀態, '0') 簽核狀態,
	A.填表人,
	D.單位主管流水編號,
	nvl(Z1.Serial_Num,' ') 員工流水編號,
	nvl(Z1.員工姓名,' ') 填表人姓名, 
	A.填表日, 
	nvl(F.OPRP次數,0) OPRP次數,
	A.最後更新者,
	nvl(Z2.員工姓名,' ') 更新者姓名, 
	A.最後更新日
FROM
	FIL0030 A
	INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
	INNER JOIN ViewFIL4030_A C ON A.歸屬類別 = C.製令單別 AND A.歸屬編號 = C.製令單號
	LEFT JOIN ViewFIL310P D ON B.機台代碼 = D.代碼
	LEFT JOIN FIL0010 E ON A.業務員 = E.員工編號
	LEFT JOIN FIL0010 Z1 ON A.填表人 = Z1.員工編號
	LEFT JOIN FIL0010 Z2 ON A.最後更新者 = Z2.員工編號
	LEFT JOIN ViewOfObjProperties Z3 ON A.流水編號 = Z3.單據流水號
	LEFT JOIN 
	(SELECT 
		A.單別,
		A.單號,
		COUNT(A.序號) OPRP次數
	 FROM 
		FIL004F A
	 GROUP BY 
		A.單別,
		A.單號
	)F ON F.單別=A.單據類別 AND F.單號=A.單據編號
WHERE
	A.單據類別 = 'C41' AND
	B.製程代碼 = 'C31D');

-- Oracle user_views
CREATE VIEW "VIEWFIL404D2" ("單別", "單號", "序號", "日期", "前製程米數", "裁切米數", "入庫數量", "合併編號", "分條號", "故障及尾數", "待補", "印刷", "淋膜", "積層", "裁切尺寸", "製品厚度", "接頭數量", "平整度", "半成品編號", "單位代碼", "單位名稱", "庫別代碼", "庫別名稱", "備註說明", "結案碼", "標籤列印次數", "標籤類別", "首次列印日期", "前製程條碼1", "前製程條碼2", "流水編號", "最後更新者", "更新者姓名", "最後更新日") AS (
SELECT 
	A.單據類別 單別, 
	A.單據編號 單號,
	A.單據序號 序號,
	A.異動日期 日期,
	A.異動數量 前製程米數,
	A.材積 裁切米數,
	A.贈品數量 入庫數量,
	A.廠客品號||DECODE(A.前置單號,' ','',','||A.前置單號) 合併編號,
	A.產品編號 分條號,
	A.異動單價 故障及尾數,
	A.Logical1 待補,
	A.Logical2 印刷,
	A.Logical3 淋膜,
	A.Logical4 積層,
	decode(A.折扣率,1,1,0) 裁切尺寸,
	A.異動金額 製品厚度,
	A.毛重 接頭數量,
	A.前置單別 平整度,
	A.文數字1 半成品編號,
	A.單位代碼,
	nvl(D.名稱, ' ') 單位名稱,
	A.倉庫代碼 庫別代碼,
	nvl(E.名稱, ' ') 庫別名稱,
	A.備註說明,
	A.結案碼,
	NVL(C.標籤列印次數,0) 標籤列印次數,
	NVL(C.標籤類別,' ') 標籤類別,
	NVL(C.批號,' ') 首次列印日期,
	C.文數字4 前製程條碼1,
	C.文數字5 前製程條碼2,
	A.流水編號,
	A.最後更新者,
	nvl(Z1.員工姓名,' ') 更新者姓名,
	A.最後更新日
FROM 
	FIL0040 A
	INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
	LEFT JOIN FIL0041 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號 AND A.單據序號=C.序號
	LEFT JOIN ViewFIL3103 D ON A.單位代碼 = D.代碼
	LEFT JOIN ViewFIL3106 E ON A.倉庫代碼 = E.代碼
	LEFT JOIN FIL0010 Z1 ON A.最後更新者 = Z1.員工編號
WHERE
	A.單據類別 = 'C41' AND
	A.異動類別 = 'A' AND
	B.製程代碼 = 'C31D');

-- Oracle user_views
CREATE VIEW "VIEWFIL404D3" ("單據類別", "單據編號", "單據序號", "前製程條碼", "結餘米數") AS (
SELECT 
	A.單據類別,
	A.單據編號,
	A.單據序號,
	nvl(C.文數字4||TRIM(DECODE(C.文數字5,' ',' ',','||C.文數字5)),' ') 前製程條碼,
	sum(decode(A.異動類別,'A',A.異動數量+A.數值1,0)
		+decode(A.異動類別,'A',A.數值1,0)
		-(decode(A.異動類別,'A',A.材積,0)+decode(A.異動類別,'A',nvl(C.包裝數量,0),0)+decode(A.異動類別,'A',A.數值2,0)+decode(A.異動類別,'A',A.數值3,0))-
		decode(A.異動類別,'A',0,A.贈品數量)
		)
	over ( PARTITION BY A.單據編號 ORDER BY A.單據序號
		) 結餘米數
FROM 
	FIL0040 A
	INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
	Left JOIN FIL0041 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號 AND A.單據序號 = C.序號
	/*製令副檔取條數*/
	INNER JOIN FIL0030 M ON A.單據類別 = M.單據類別 AND A.單據編號 = M.單據編號
WHERE
	A.單據類別 = 'C41' AND
	A.異動類別 = 'A' AND
	B.製程代碼 = 'C31D'
);

-- Oracle user_views
CREATE VIEW "VIEWFIL404DA" ("單別", "單號", "最後更新日時", "入庫捲數", "前製程米數", "裁切米數", "故障米數", "客戶要求數", "線外剔除數", "合理剔除數", "使用米數", "結餘米數", "PLC抓取米數", "上次尾數", "回庫數量", "資料筆數") AS (                                                                                                                                                      
SELECT 
	A.單據類別 單別, 
	A.單據編號 單號,
	max(TO_CHAR(A.最後更新日,'YYYYMMDDHH24MISS')) 最後更新日時,	
	sum(A.材積*D.條數) 入庫捲數,
	sum(A.異動數量+A.數值1) 前製程米數,
	sum(A.雷射費+A.氣閥費) 裁切米數,
	sum(A.異動單價) 故障米數,
	sum(A.QRNO) 客戶要求數,
	sum(A.數值2) 線外剔除數,
	sum(A.數值3) 合理剔除數,
	sum(A.贈品數量+A.異動單價) 使用米數,
	sum(A.異動數量+A.數值1 -(A.材積+nvl(C.包裝數量,0)+A.數值2+A.數值3))-max(nvl(E.回庫數量,0)) 結餘米數,
	sum(A.材積) PLC抓取米數,
	sum(nvl(C.包裝數量,0)) 上次尾數,
	max(nvl(E.回庫數量,0)) 回庫數量,
	count(A.單據序號) 資料筆數
FROM 
	FIL0040 A
	INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
	Left JOIN FIL0041 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號 AND A.單據序號 = C.序號
	/*製令副檔取條數*/
	INNER JOIN FIL0030 M ON A.單據類別 = M.單據類別 AND A.單據編號 = M.單據編號
	INNER JOIN FIL0033 D ON M.歸屬類別 = D.製令單別 AND M.歸屬編號 = D.製令單號 AND D.加工別='A'
	LEFT JOIN 
	(
	SELECT 
		A.單據類別,
		A.單據編號,
		SUM(A.贈品數量) 回庫數量
	FROM
		FIL0040 A
		INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
		INNER JOIN FIL0041 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號 AND A.單據序號 = C.序號
	WHERE
		A.單據類別 = 'C41' AND
		A.異動類別= 'G' AND
		B.製程代碼 = 'C31D'	AND
		C.標籤列印次數 > 0
	GROUP BY
		A.單據類別, 
		A.單據編號
	) E ON E.單據類別 = A.單據類別 AND E.單據編號 = A.單據編號
WHERE
	A.單據類別 = 'C41' AND
	A.異動類別 = 'A' AND
	B.製程代碼 = 'C31D'
GROUP BY
	A.單據類別, 
	A.單據編號);

-- Oracle user_views
CREATE VIEW "VIEWFIL404DA1" ("單別", "單號", "改件調機", "製令單別", "製令單號", "入庫捲數", "前製程米數", "裁切米數", "不良剔除數", "客戶要求數", "線外不良剔除數", "合理不良剔除數", "使用米數", "結餘米數", "PLC抓取米數", "上次尾數", "回庫數量", "資料筆數") AS (                                                                                                                                                      
SELECT 
	A.單據類別 單別, 
	A.單據編號 單號,
	B.Logical6 改件調機,
	max(M.歸屬類別) 製令單別, 
	max(M.歸屬編號) 製令單號,
	sum(A.材積*D.條數) 入庫捲數,
	sum(A.異動數量+A.數值1) 前製程米數,
	sum(A.雷射費+A.氣閥費) 裁切米數,
	sum(A.異動單價) 不良剔除數,
	sum(A.QRNO) 客戶要求數,
	sum(A.數值2) 線外不良剔除數,
	sum(A.數值3) 合理不良剔除數,
	sum(A.贈品數量+A.異動單價) 使用米數,
	sum(A.異動數量+A.數值1 -(A.材積+nvl(C.包裝數量,0)+A.數值2+A.數值3))-max(nvl(E.回庫數量,0)) 結餘米數,
	sum(A.材積) PLC抓取米數,
	sum(nvl(C.包裝數量,0)) 上次尾數,
	max(nvl(E.回庫數量,0)) 回庫數量,
	count(A.單據序號) 資料筆數
FROM 
	FIL0040 A
	INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
	Left JOIN FIL0041 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號 AND A.單據序號 = C.序號
	/*製令副檔取條數*/
	INNER JOIN FIL0030 M ON A.單據類別 = M.單據類別 AND A.單據編號 = M.單據編號
	INNER JOIN FIL0033 D ON M.歸屬類別 = D.製令單別 AND M.歸屬編號 = D.製令單號 AND D.加工別='A'
	LEFT JOIN 
	(
	SELECT 
		A.單據類別,
		A.單據編號,
		SUM(A.贈品數量) 回庫數量
	FROM
		FIL0040 A
		INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
		INNER JOIN FIL0041 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號 AND A.單據序號 = C.序號
	WHERE
		A.單據類別 = 'C41' AND
		A.異動類別= 'G' AND
		B.製程代碼 = 'C31D'	AND
		C.標籤列印次數 > 0
	GROUP BY
		A.單據類別, 
		A.單據編號
	) E ON E.單據類別 = A.單據類別 AND E.單據編號 = A.單據編號
WHERE
	A.單據類別 = 'C41' AND
	A.異動類別 = 'A' AND
	B.製程代碼 = 'C31D'
GROUP BY
	A.單據類別, 
	A.單據編號,
	B.Logical6);

-- Oracle user_views
CREATE VIEW "VIEWFIL404DB" ("單別", "單號", "每捲數量", "幾捲") AS (                                                                                                                                                      SELECT 
	A.單據類別 單別, 
	A.單據編號 單號,
	(A.贈品數量+nvl(C.包裝數量,0)) 每捲數量, 
	sum(REGEXP_COUNT (A.產品編號, ',')+1) 幾捲
FROM 
	FIL0040 A
	INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
	INNER JOIN FIL0041 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號 AND A.單據序號 = C.序號
	/*製令副檔取條數*/
	INNER JOIN FIL0030 M ON A.單據類別 = M.單據類別 AND A.單據編號 = M.單據編號
	INNER JOIN FIL0033 D ON M.歸屬類別 = D.製令單別 AND M.歸屬編號 = D.製令單號 AND D.加工別='A'
WHERE
	A.單據類別 = 'C41' AND
	A.異動類別 = 'A' AND
	B.製程代碼 = 'C31D' AND
	A.Logical1 = 0
GROUP BY
	A.單據類別, 
	A.單據編號,
	(A.贈品數量+nvl(C.包裝數量,0))
	);

-- Oracle user_views
CREATE VIEW "VIEWFIL404DC" ("單別", "單號", "彙總") AS (
SELECT 
	A.單別, 
	A.單號,
	listagg(trim(to_char(A.幾捲,'999'))||'R X '||trim(to_char(A.每捲數量,'99999')),',') within group (order by A.序號) as 彙總
FROM 
	(
	SELECT 
		A.單據類別 單別, 
		A.單據編號 單號,
		(A.贈品數量) 每捲數量, 
		MIN(A.單據序號) 序號,
		COUNT(M.細分) 幾捲
	FROM 
		FIL00401 M
		INNER JOIN FIL0040 A ON A.單據類別 = M.單別 AND A.單據編號 = M.單號 AND A.單據序號 = M.序號
		INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
		INNER JOIN FIL0041 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號 AND A.單據序號 = C.序號
		/*製令副檔取條數*/
		INNER JOIN FIL0030 M ON A.單據類別 = M.單據類別 AND A.單據編號 = M.單據編號
		INNER JOIN FIL0033 D ON M.歸屬類別 = D.製令單別 AND M.歸屬編號 = D.製令單號 AND D.加工別='A'
	WHERE
		A.單據類別 = 'C41' AND
		A.異動類別 = 'A' AND
		B.製程代碼 = 'C31D' AND
		M.報廢 = 0
	GROUP BY
		A.單據類別, 
		A.單據編號,
		(A.贈品數量)
	) A
GROUP BY 
	A.單別, 
	A.單號
);

-- Oracle user_views
CREATE VIEW "VIEWFIL404DD" ("單別", "單號", "報廢筆數", "重整筆數") AS (
SELECT 
	A.單別, 
	A.單號,
	sum(A.報廢) 報廢筆數,
	sum(A.重整) 重整筆數
FROM 
	FIL00401 A
GROUP BY 
	A.單別, 
	A.單號
);

-- Oracle user_views
CREATE VIEW "VIEWFIL404DE" ("製令單號", "捲數") AS (
SELECT 
	A.製令單號,
	sum(A.幾捲) 捲數
FROM 
	(
	SELECT 
		E.歸屬編號 製令單號,
		COUNT(M.細分) 幾捲
	FROM 
		FIL00401 M
		INNER JOIN FIL0040 A ON A.單據類別 = M.單別 AND A.單據編號 = M.單號 AND A.單據序號 = M.序號
		INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
		/*製令副檔取條數*/
		INNER JOIN FIL0030 E ON M.單別 = E.單據類別 AND M.單號 = E.單據編號
	WHERE
		M.單別 = 'C41' AND
		A.異動類別 = 'A' AND
		B.製程代碼 = 'C31D' AND
		M.報廢 = 0
	GROUP BY
		E.歸屬編號
	) A
GROUP BY 
	A.製令單號
);

-- Oracle user_views
CREATE VIEW "VIEWFIL404E1" ("單別", "單號", "作業日期", "製令單別", "製令單號", "公司代碼", "公司名稱", "訂單單別", "訂單單號", "機台代碼", "機台名稱", "單位主管流水編號", "本日件數順序", "製造日期", "主旨", "客戶編號", "客戶名稱", "產品編號", "產品名稱", "產品規格", "共版", "改件調機", "結束", "待補", "產品條件確認", "溫度條牛設定確認", "壓力條件設定確認", "電眼設定確認", "銅條與規板規格確認", "開始時間", "結束時間", "製袋速度", "成品尺寸", "成品尺寸_高", "成品尺寸_底", "成品尺寸_寬", "展開尺寸_高", "展開尺寸_寬", "報廢數", "重整數", "簽核系統", "備註", "作業人員", "作業人員姓名", "作業員二", "作業員二姓名", "作業員三", "作業員三姓名", "紙箱_無氣閥_每束幾袋", "紙箱_無氣閥_每箱幾袋", "紙箱代碼1", "紙箱品名_無氣閥", "紙箱_氣閥_每束幾袋", "紙箱_氣閥_每箱幾袋", "紙箱代碼2", "紙箱品名_氣閥", "抬頭1", "抬頭2", "抬頭3", "確認碼", "自主檢查_封邊上下", "自主檢查_封邊背側邊", "自主檢查_圓孔", "自主檢查_封邊上下MM", "自主檢查_封邊上下MM2", "自主檢查_封邊背邊側MM", "自主檢查_封邊背邊側MM2", "自主檢查_打角MM", "自主檢查_夾鏈MM", "待補日報號碼", "簽核狀態", "CCP提醒HR", "自主檢查提醒HR", "氣閥代碼", "鐵條代碼", "尾數紙箱", "雙膜", "流水編號", "填表人", "填表人姓名", "員工流水編號", "填表日", "最後更新者", "更新者姓名", "最後更新日") AS (                                                                                                                                                      SELECT
	A.單據類別 單別,
	A.單據編號 單號,
	A.單據日期 作業日期,
	A.歸屬類別 製令單別,
	A.歸屬編號 製令單號,
	C.公司代碼,
	C.公司名稱,
	C.訂單單別,
	C.訂單單號,
	B.機台代碼,
	nvl(D.名稱, ' ') 機台名稱,
	D.單位主管流水編號,
	B.交貨日期_天 本日件數順序,
	B.交貨日期 製造日期,
	A.單據編號||'('||trim(A.單據類別)||')'||'/製令:'||nvl(A.歸屬編號, ' ')||'/'||C.產品名稱 主旨,
	C.客戶編號,
	C.客戶名稱,
	C.產品編號,
	C.產品名稱,
	C.產品規格,
	B.Logical1 共版,
	B.Logical3 改件調機,
	B.Logical4 結束,
	B.Logical5 待補,
	B.Logical6 產品條件確認,
	B.Logical7 溫度條牛設定確認,
	B.Logical8 壓力條件設定確認,
	B.Logical9 電眼設定確認,
	B.Logical10 銅條與規板規格確認,
	B.時間一 開始時間,
	B.時間五 結束時間,
	B.數值1 製袋速度,
	C1.成品尺寸,
	B.數值2 成品尺寸_高,
	B.數值3 成品尺寸_底,
	B.數值4 成品尺寸_寬,
	B.數值5 展開尺寸_高,
	B.數值6 展開尺寸_寬,
	B.送貨地址序號 報廢數,
	B.聯絡人序號 重整數,
	A.簽核系統, 
	A.備註, 
	A.業務員 作業人員,
	nvl(E.員工姓名,' ') 作業人員姓名, 
	B.文數字10 作業員二,
	nvl(G.員工姓名,' ') 作業員二姓名, 
	B.文數字11 作業員三,
	nvl(H.員工姓名,' ') 作業員三姓名,
	B.數值16 紙箱_無氣閥_每束幾袋,
	B.數值17 紙箱_無氣閥_每箱幾袋,
	B.文數字7 紙箱代碼1,
	nvl(I.品名, ' ') 紙箱品名_無氣閥,
	B.數值18 紙箱_氣閥_每束幾袋,
	B.數值19 紙箱_氣閥_每箱幾袋,
	B.文數字8 紙箱代碼2,
	nvl(J.品名, ' ') 紙箱品名_氣閥,
	B.文數字4 抬頭1,
	B.文數字5 抬頭2,
	B.文數字6 抬頭3,
	A.確認碼,
	B.文數字1 自主檢查_封邊上下,
	B.文數字2 自主檢查_封邊背側邊,
	B.文數字3 自主檢查_圓孔,
	B.數值8  自主檢查_封邊上下mm,
	B.數值12 自主檢查_封邊上下mm2,
	B.數值9  自主檢查_封邊背邊側mm,
	B.數值13 自主檢查_封邊背邊側mm2,
	B.數值10 自主檢查_打角mm,
	B.數值11 自主檢查_夾鏈mm,
	B.文數字9 待補日報號碼,
	nvl(Z3.簽核狀態, '0') 簽核狀態,
	B.數值14 CCP提醒HR,
	B.數值15 自主檢查提醒HR,
	C1.加工項目_氣閥代碼 氣閥代碼,
	C1.加工項目_鐵條代碼 鐵條代碼,
	B.文數字12 尾數紙箱,
	A.邏輯值一 雙膜,
	A.流水編號,
	A.填表人,
	nvl(Z1.員工姓名,' ') 填表人姓名, 
	nvl(Z1.Serial_Num,' ') 員工流水編號, 
	A.填表日, 
	A.最後更新者,
	nvl(Z2.員工姓名,' ') 更新者姓名, 
	A.最後更新日
FROM
	FIL0030 A
	INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
	INNER JOIN ViewFIL4030 C ON A.歸屬類別 = C.製令單別 AND A.歸屬編號 = C.製令單號
	INNER JOIN FIL0032 C1 ON A.歸屬類別 = C1.製令單別 AND A.歸屬編號 = C1.製令單號
	LEFT JOIN ViewFIL310P D ON B.機台代碼 = D.代碼
	LEFT JOIN FIL0010 E ON A.業務員 = E.員工編號
	LEFT JOIN FIL0010 F ON A.收付方式 = F.員工編號
	LEFT JOIN FIL0010 G ON B.文數字10 = G.員工編號
	LEFT JOIN FIL0010 H ON B.文數字11 = H.員工編號
	LEFT JOIN FIL0012 I ON B.文數字7 = I.產品編號
	LEFT JOIN FIL0012 J ON B.文數字8 = J.產品編號
	LEFT JOIN FIL0010 Z1 ON A.填表人 = Z1.員工編號
	LEFT JOIN FIL0010 Z2 ON A.最後更新者 = Z2.員工編號
	LEFT JOIN ViewOfObjProperties Z3 ON A.流水編號 = Z3.單據流水號
WHERE
	A.單據類別 = 'C41' AND
	B.製程代碼 = 'C31E');

-- Oracle user_views
CREATE VIEW "VIEWFIL404E1A" ("機台代碼", "製令單號") AS (
select distinct B.機台代碼,
        first_value(A.歸屬編號) over (partition by B.機台代碼 order by A.最後更新日 desc RANGE BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) 製令單號
FROM
	FIL0030 A
	INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
WHERE
	A.單據類別 = 'C41' AND
	B.製程代碼 = 'C31E' AND 
	B.時間二 = '000000'
);

-- Oracle user_views
CREATE VIEW "VIEWFIL404E1_B" ("單別", "單號", "作業日期", "製造日期", "製令單別", "製令單號", "機台代碼", "結束", "待補", "紙箱_無氣閥_每束幾袋", "紙箱_無氣閥_每箱幾袋", "紙箱代碼1", "紙箱_氣閥_每束幾袋", "紙箱_氣閥_每箱幾袋", "紙箱代碼2", "尾數紙箱", "抬頭1", "抬頭2", "抬頭3", "待補日報號碼", "氣閥代碼", "鐵條代碼", "作業人員", "作業員二", "作業員三") AS ( 
SELECT
	A.單據類別 單別,
	A.單據編號 單號,
	A.單據日期 作業日期,
	B.交貨日期 製造日期,
	A.歸屬類別 製令單別,
	A.歸屬編號 製令單號,
	B.機台代碼,
	B.Logical4 結束,
	B.Logical5 待補,
	B.數值16 紙箱_無氣閥_每束幾袋,
	B.數值17 紙箱_無氣閥_每箱幾袋,
	B.文數字7 紙箱代碼1,
	B.數值18 紙箱_氣閥_每束幾袋,
	B.數值19 紙箱_氣閥_每箱幾袋,
	B.文數字8 紙箱代碼2,
	B.文數字12 尾數紙箱,
	B.文數字4 抬頭1,
	B.文數字5 抬頭2,
	B.文數字6 抬頭3,
	B.文數字9 待補日報號碼,
	C1.加工項目_氣閥代碼 氣閥代碼,
	C1.加工項目_鐵條代碼 鐵條代碼,
	A.業務員 作業人員,
	B.文數字10 作業員二,
	B.文數字11 作業員三
FROM
	FIL0030 A
	INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
	INNER JOIN ViewFIL4030 C ON A.歸屬類別 = C.製令單別 AND A.歸屬編號 = C.製令單號
	INNER JOIN FIL0032 C1 ON A.歸屬類別 = C1.製令單別 AND A.歸屬編號 = C1.製令單號
WHERE
	A.單據類別 = 'C41' AND
	B.製程代碼 = 'C31E');

-- Oracle user_views
CREATE VIEW "VIEWFIL404E1_C" ("單據類別", "單據編號", "箱號", "幾箱") AS ( 
SELECT
	A.單據類別,
	A.單據編號,
	A.異動數量 箱號,
	COUNT(A.單據序號) 幾箱
FROM 
	FIL0040 A
	INNER JOIN FIL0031 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號 
WHERE
	A.單據類別 = 'C41' AND 
	A.異動類別 = 'A' AND 
	C.製程代碼 = 'C31E' 		
GROUP BY 
	A.單據類別,
	A.單據編號,
	A.異動數量);

-- Oracle user_views
CREATE VIEW "VIEWFIL404E1_D" ("單別", "單號", "作業日期", "製令單別", "製令單號", "公司代碼", "公司名稱", "訂單單別", "訂單單號", "機台代碼", "機台名稱", "本日件數順序", "主旨", "客戶編號", "客戶名稱", "產品編號", "產品名稱", "產品規格", "改件調機", "結束", "待補", "開始時間", "結束時間", "簽核系統", "備註", "作業人員", "作業人員姓名", "作業員二", "作業員二姓名", "作業員三", "作業員三姓名", "確認碼", "簽核狀態", "雙膜", "流水編號", "填表人", "填表人姓名", "單位主管流水編號", "員工流水編號", "填表日") AS (                                                                                                                                                      
SELECT
	A.單據類別 單別,
	A.單據編號 單號,
	A.單據日期 作業日期,
	A.歸屬類別 製令單別,
	A.歸屬編號 製令單號,
	C.公司代碼,
	C.公司名稱,
	C.訂單單別,
	C.訂單單號,
	B.機台代碼,
	nvl(D.名稱, ' ') 機台名稱,
	B.交貨日期_天 本日件數順序,
	A.單據編號||'('||trim(A.單據類別)||')'||'/製令:'||nvl(A.歸屬編號, ' ')||'/'||C.產品名稱 主旨,
	C.客戶編號,
	C.客戶名稱,
	C.產品編號,
	C.產品名稱,
	C.產品規格,
	B.Logical3 改件調機,
	B.Logical4 結束,
	B.Logical5 待補,
	B.時間一 開始時間,
	B.時間五 結束時間,
	A.簽核系統, 
	A.備註, 
	A.業務員 作業人員,
	nvl(E.員工姓名,' ') 作業人員姓名, 
	B.文數字10 作業員二,
	nvl(G.員工姓名,' ') 作業員二姓名, 
	B.文數字11 作業員三,
	nvl(H.員工姓名,' ') 作業員三姓名,
	A.確認碼,
	nvl(Z3.簽核狀態, '0') 簽核狀態,
	A.邏輯值一 雙膜,
	A.流水編號,
	A.填表人,
	nvl(Z1.員工姓名,' ') 填表人姓名, 
	D.單位主管流水編號,
	nvl(Z1.Serial_Num,' ') 員工流水編號, 
	A.填表日
FROM
	FIL0030 A
	INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
	INNER JOIN ViewFIL4030 C ON A.歸屬類別 = C.製令單別 AND A.歸屬編號 = C.製令單號
	LEFT JOIN ViewFIL310P D ON B.機台代碼 = D.代碼
	LEFT JOIN FIL0010 E ON A.業務員 = E.員工編號
	LEFT JOIN FIL0010 G ON B.文數字10 = G.員工編號
	LEFT JOIN FIL0010 H ON B.文數字11 = H.員工編號
	LEFT JOIN FIL0010 Z1 ON A.填表人 = Z1.員工編號
	LEFT JOIN FIL0010 Z2 ON A.最後更新者 = Z2.員工編號
	LEFT JOIN ViewOfObjProperties Z3 ON A.流水編號 = Z3.單據流水號
WHERE
	A.單據類別 = 'C41' AND
	B.製程代碼 = 'C31E');

-- Oracle user_views
CREATE VIEW "VIEWFIL404E2" ("單別", "單號", "序號", "日期", "夾鏈批號", "夾鏈料號", "夾鏈品名", "夾鏈規格", "夾鏈米數", "Ａ材編號", "Ａ材領料米數", "Ａ接頭數", "Ａ切刀次數", "Ａ結案", "Ｂ材編號", "Ｂ材領料米數", "Ｂ接頭數", "Ｂ切刀次數", "Ｂ結案", "側邊編號", "側邊領料米數", "側接頭數", "側切刀次數", "側結案", "底邊編號", "底邊領料米數", "底接頭數", "底切刀次數", "底結案", "箱號", "氣閥", "數量", "補尾數", "重量", "不良原因", "外箱標示", "不良原因說明", "外箱標示說明", "單位代碼", "單位名稱", "庫別代碼", "庫別名稱", "半成品編號", "結案碼", "備註說明", "製令單別", "製令單號", "氣閥代碼", "鐵條代碼", "氣閥重量", "鐵條重量", "總重量", "待補", "雙膜", "待重工", "結束時間", "流水編號", "最後更新者", "更新者姓名", "最後更新日") AS (                                                                                                                                                      SELECT 
	A.單據類別 單別, 
	A.單據編號 單號,
	A.單據序號 序號,
	A.異動日期 日期,
	B.批號 夾鏈批號,
	nvl(F.料號, ' ') 夾鏈料號,
	nvl(G.品名, ' ') 夾鏈品名,
	nvl(G.規格, ' ') 夾鏈規格,
	B.數值9 夾鏈米數,
	B.文數字1 Ａ材編號,
	B.數值1 Ａ材領料米數,
	B.數值5 Ａ接頭數,
	B.數值10 Ａ切刀次數,
	B.Logical1 Ａ結案,
	B.文數字2 Ｂ材編號,
	B.數值2 Ｂ材領料米數,
	B.數值6 Ｂ接頭數,
	B.數值11 Ｂ切刀次數,
	B.Logical2 Ｂ結案,
	B.文數字3 側邊編號,
	B.數值3 側邊領料米數,
	B.數值7 側接頭數,
	B.數值12 側切刀次數,
	B.Logical3 側結案,
	B.文數字4 底邊編號,
	B.數值4 底邊領料米數,
	B.數值8 底接頭數,
	B.數值13 底切刀次數,
	B.Logical4 底結案,
	A.異動數量 箱號,
	B.Logical5 氣閥,
	A.贈品數量 數量,
	B.數值14 補尾數,
	A.毛重 重量,
	A.前置單別 不良原因,
	A.前置單號 外箱標示,
	B.手動品名 不良原因說明,
	B.手動規格 外箱標示說明,
	A.單位代碼,
	nvl(D.名稱, ' ') 單位名稱,
	A.倉庫代碼 庫別代碼,
	nvl(E.名稱, ' ') 庫別名稱,
	A.文數字1 半成品編號,
	A.結案碼,
	A.備註說明,
	C1.歸屬類別 製令單別,
	C1.歸屬編號 製令單號,
	C2.加工項目_氣閥代碼 氣閥代碼,
	C2.加工項目_鐵條代碼 鐵條代碼,
	nvl(G1.單價下限率, 0) 氣閥重量,
	nvl(G2.單價下限率, 0) 鐵條重量,
	round(A.毛重 + (nvl(G2.單價下限率, 0)/1000)*A.贈品數量 + (decode(B.Logical5, 0, 0, nvl(G1.單價下限率, 0))/1000)*A.贈品數量,2) 總重量,
	A.Logical1 待補,
	A.Logical2 雙膜,
	A.Logical3 待重工,
	A.TIME1 結束時間,
	A.流水編號,
	A.最後更新者,
	nvl(Z1.員工姓名,' ') 更新者姓名,
	A.最後更新日
FROM 
	FIL0040 A
	INNER JOIN FIL0041 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號 AND A.單據序號 = B.序號
	INNER JOIN FIL0031 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號
	INNER JOIN FIL0030 C1 ON A.單據類別 = C1.單據類別 AND A.單據編號 = C1.單據編號
	LEFT JOIN FIL0032 C2 ON C1.歸屬類別 = C2.製令單別 AND C1.歸屬編號 = C2.製令單號
	LEFT JOIN ViewFIL3103 D ON A.單位代碼 = D.代碼
	LEFT JOIN ViewFIL3106 E ON A.倉庫代碼 = E.代碼
	LEFT JOIN ViewFIL1024 F ON B.批號 = F.條碼
	LEFT JOIN FIL0012 G ON F.料號 = G.產品編號
	LEFT JOIN FIL0012 G1 ON C2.加工項目_氣閥代碼 = G1.產品編號
	LEFT JOIN FIL0012 G2 ON C2.加工項目_鐵條代碼 = G2.產品編號
	LEFT JOIN FIL0010 Z1 ON A.最後更新者 = Z1.員工編號
WHERE
	A.單據類別 = 'C41' AND
	A.異動類別 = 'A' AND
	C.製程代碼 = 'C31E');

-- Oracle user_views
CREATE VIEW "VIEWFIL404E2_A" ("單別", "單號", "序號", "Ａ材編號", "Ａ材領料米數", "Ａ接頭數", "Ａ切刀次數", "Ａ結案", "Ｂ材編號", "Ｂ材領料米數", "Ｂ接頭數", "Ｂ切刀次數", "Ｂ結案", "側邊編號", "側邊領料米數", "側接頭數", "側切刀次數", "側結案", "底邊編號", "底邊領料米數", "底接頭數", "底切刀次數", "底結案", "箱號", "氣閥", "數量", "補尾數", "重量", "不良原因", "外箱標示", "不良原因說明", "外箱標示說明", "單位代碼", "庫別代碼", "成品檢驗單號", "製令單別", "製令單號", "作業日期", "製造日期", "待重工") AS (  
SELECT 
	A.單據類別 單別, 
	A.單據編號 單號,
	A.單據序號 序號,
	B.文數字1 Ａ材編號,
	B.數值1 Ａ材領料米數,
	B.數值5 Ａ接頭數,
	B.數值10 Ａ切刀次數,
	B.Logical1 Ａ結案,
	B.文數字2 Ｂ材編號,
	B.數值2 Ｂ材領料米數,
	B.數值6 Ｂ接頭數,
	B.數值11 Ｂ切刀次數,
	B.Logical2 Ｂ結案,
	B.文數字3 側邊編號,
	B.數值3 側邊領料米數,
	B.數值7 側接頭數,
	B.數值12 側切刀次數,
	B.Logical3 側結案,
	B.文數字4 底邊編號,
	B.數值4 底邊領料米數,
	B.數值8 底接頭數,
	B.數值13 底切刀次數,
	B.Logical4 底結案,
	A.異動數量 箱號,
	B.Logical5 氣閥,
	A.贈品數量 數量,
	B.數值14 補尾數,
	A.毛重 重量,
	A.前置單別 不良原因,
	A.前置單號 外箱標示,
	B.手動品名 不良原因說明,
	B.手動規格 外箱標示說明,
	A.單位代碼,
	A.倉庫代碼 庫別代碼,
	B.專案代號 成品檢驗單號,
	D.歸屬類別 製令單別,
	D.歸屬編號 製令單號,
	D.單據日期 作業日期,
	C.交貨日期 製造日期,
	A.Logical3 待重工
FROM 
	FIL0040 A
	INNER JOIN FIL0041 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號 AND A.單據序號 = B.序號
	INNER JOIN FIL0031 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號	
	INNER JOIN FIL0030 D ON D.單據類別 = A.單據類別 AND D.單據編號 = A.單據編號
WHERE
	A.單據類別 = 'C41' AND
	A.異動類別 = 'A' AND
	C.製程代碼 = 'C31E' );

-- Oracle user_views
CREATE VIEW "VIEWFIL404E2_B" ("單別", "單號", "箱號") AS (  
SELECT 
	A.單據類別 單別, 
	A.單據編號 單號,
	listagg(A.異動數量, ' ') within group (order by A.單據編號) as 箱號
FROM 
	FIL0040 A
	INNER JOIN FIL0031 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號	
WHERE
	A.單據類別 = 'C41' AND
	A.異動類別 = 'A' AND
	C.製程代碼 = 'C31E' 
GROUP BY 
	A.單據類別, 
	A.單據編號
	);

-- Oracle user_views
CREATE VIEW "VIEWFIL404E3" ("單別", "單號", "序號", "箱號", "數量", "報廢數量", "重量", "批號", "製令類別", "製令單號", "作業日期", "作業員一", "作業員二", "作業員三", "作業員一姓名", "作業員二姓名", "作業員三姓名", "單據數量", "單據重量", "來源", "標籤類別", "製袋", "氣閥", "鐵條", "異動", "重工", "品檢", "流水編號", "最後更新日時") AS (
SELECT 
	A.單據類別 單別, 
	A.單據編號 單號,
	A.單據序號 序號,
	A.異動數量 箱號,
	NVL(decode(C.製程代碼,'C31E',decode(B.數值14,0,A.贈品數量,B.數值14),B.數值5*-1),0) 數量,
	0 報廢數量,
	NVL(decode(C.製程代碼,'C31E',decode(B.數值14,0,A.毛重,A.毛重*(B.數值14/A.贈品數量)),B.數值5*-1*G.平均袋重),0) 重量,
	D.歸屬編號 ||'-'||trim(to_char(A.異動數量, '0000')) 批號,		
	D.歸屬類別 製令類別,
	D.歸屬編號 製令單號,
	D.單據日期 作業日期,
	G.作業人員 作業員一,
	G.作業員二 作業員二,
	G.作業員三 作業員三,
	G.作業人員姓名 作業員一姓名,
	G.作業員二姓名 作業員二姓名,
	G.作業員三姓名 作業員三姓名,
	A.贈品數量 單據數量,
	A.毛重 單據重量,
	decode(C.製程代碼,'C31E',TO_CHAR('製袋'),'C31G',TO_CHAR('鐵條'),TO_CHAR('氣閥')) 來源,
	B.標籤類別,
	1 製袋,
	decode(C.製程代碼,'C31F',1,0) 氣閥,
	decode(C.製程代碼,'C31G',1,0) 鐵條,
	0 異動,
	0 重工,
	0 品檢,
	A.流水編號,
	to_char(A.最後更新日,'YYYYMMDDHH24MISS') 最後更新日時
FROM 
	FIL0040 A
	INNER JOIN FIL0041 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號 AND A.單據序號 = B.序號
	LEFT JOIN FIL0031 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號 
	INNER JOIN FIL0030 D ON A.單據類別 = D.單據類別 AND A.單據編號 = D.單據編號
	LEFT JOIN VIEWFIL404E7 G ON D.歸屬類別 = G.製令單別 AND D.歸屬編號 = G.製令單號 AND A.異動數量=G.箱號
WHERE
	A.異動類別 = 'A' AND (C.製程代碼 = 'C31E' OR C.製程代碼 = 'C31F' OR C.製程代碼 = 'C31G')

Union All

SELECT 
	A.單據類別 單別, 
	A.單據編號 單號,
	A.單據序號 序號,
	A.異動數量 箱號,
	NVL(decode(A.單據類別,'E35',A.贈品數量*-1,'E37',B.數值5*-1,A.贈品數量),0) 數量,
	NVL(decode(A.單據類別,'E33',B.數值5,0),0) 報廢數量,
	NVL(decode(A.單據類別,'E35',(A.贈品數量*-1*J.平均袋重),'E37',(B.數值5*-1*(J.平均袋重+NVL(K.每袋重量,0)+NVL(L.每袋重量,0))),A.毛重),0) 重量,
	B.批號 批號,
	To_Char('C11') 製令類別,
	A.廠客品號 製令單號,
	D.單據日期 作業日期,
	J.作業人員 作業員一,
	J.作業員二 作業員二,
	J.作業員三 作業員三,
	J.作業人員姓名 作業員一姓名,
	J.作業員二姓名 作業員二姓名,
	J.作業員三姓名 作業員三姓名,
	A.贈品數量 單據數量,
	A.毛重 單據重量,
	decode(A.單據類別,'E32',TO_CHAR('異動'),'E33',TO_CHAR('重工'),'E35',TO_CHAR('出貨'),TO_CHAR('品檢')) 來源,
	B.標籤類別,
	1 製袋,
	B.logical2 氣閥,
	B.logical3 鐵條,
	decode(A.單據類別,'E32',1,0) 異動,
	decode(A.單據類別,'E33',1,0) 重工,
	decode(A.單據類別,'E37',1,0) 品檢,
	A.流水編號,
	to_char(A.最後更新日,'YYYYMMDDHH24MISS') 最後更新日時
FROM 
	FIL0040 A
	INNER JOIN FIL0041 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號 AND A.單據序號 = B.序號
	INNER JOIN FIL0030 D ON A.單據類別 = D.單據類別 AND A.單據編號 = D.單據編號
	LEFT JOIN VIEWFIL404E7 J ON To_Char('C11') = J.製令單別 AND A.廠客品號 = J.製令單號 AND A.異動數量=J.箱號
	LEFT JOIN VIEWFIL404F3 K ON To_Char('C11') = K.製令單別 AND A.廠客品號 = K.製令單號 AND A.異動數量=K.箱號
	LEFT JOIN VIEWFIL404G3 L ON To_Char('C11') = L.製令單別 AND A.廠客品號 = L.製令單號 AND A.異動數量=L.箱號
	
WHERE
	A.單據類別 = 'E32' or A.單據類別 = 'E33'  or A.單據類別 = 'E35' or A.單據類別='E37'
);

-- Oracle user_views
CREATE VIEW "VIEWFIL404E3_S" ("製令單號", "箱號", "數量", "報廢數量", "重量", "批號", "製袋", "氣閥", "鐵條", "異動", "重工", "出貨", "品檢", "來源", "單別", "單號", "序號") AS (
SELECT
 	D.歸屬編號 製令單號,
	A.異動數量 箱號,
	NVL(decode(C.製程代碼,'C31E',decode(B.數值14,0,A.贈品數量,B.數值14),B.數值5*-1),0) 數量,
	0 報廢數量,
	NVL(decode(C.製程代碼,'C31E',decode(B.數值14,0,A.毛重,A.毛重*(B.數值14/A.贈品數量)),B.數值5*-1*G.平均袋重),0) 重量,
	D.歸屬編號 ||'-'||trim(to_char(A.異動數量, '0000')) 批號,		
	1 製袋,
	decode(C.製程代碼,'C31F',1,0) 氣閥,
	decode(C.製程代碼,'C31G',1,0) 鐵條,
	0 異動,
	0 重工,
	0 出貨,
	0 品檢,
	decode(C.製程代碼,'C31E',TO_NCHAR('製袋'),'C31G',TO_NCHAR('鐵條'),TO_NCHAR('氣閥')) 來源,
	A.單據類別 單別,
	A.單據編號 單號,
	A.單據序號 序號
FROM 
	FIL0040 A
	INNER JOIN FIL0041 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號 AND A.單據序號 = B.序號
	LEFT JOIN FIL0031 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號 
	INNER JOIN FIL0030 D ON A.單據類別 = D.單據類別 AND A.單據編號 = D.單據編號
	LEFT JOIN VIEWFIL404E7 G ON D.歸屬類別 = G.製令單別 AND D.歸屬編號 = G.製令單號 AND A.異動數量=G.箱號
WHERE
	A.異動類別 = 'A' AND
	C.製程代碼 between 'C31E' and 'C31G'

Union All

SELECT
 	A.廠客品號 製令單號,
	A.異動數量 箱號,
	NVL(decode(A.單據類別,'E35',A.贈品數量*-1,'E37',B.數值5*-1,A.贈品數量),0) 數量,
	NVL(decode(A.單據類別,'E33',B.數值5,0),0) 報廢數量,	
	NVL(decode(A.單據類別,'E35',(A.贈品數量*-1*J.平均袋重),'E37',(B.數值5*-1*(J.平均袋重+NVL(K.每袋重量,0)+NVL(L.每袋重量,0))),A.毛重),0) 重量,
	B.批號 批號,
	1 製袋,
	B.logical2 氣閥,
	B.logical3 鐵條,
	decode(A.單據類別,'E32',1,0) 異動,
	decode(A.單據類別,'E33',1,0) 重工,
	decode(A.單據類別,'E35',1,0) 重工,
	decode(A.單據類別,'E37',1,0) 品檢,
	decode(A.單據類別,'E32',TO_NCHAR('異動'),'E33',TO_NCHAR('重工'),'E35',TO_NCHAR('出貨'),TO_NCHAR('品檢')) 來源,
	A.單據類別 單別,
	A.單據編號 單號,
	A.單據序號 序號
FROM 
	FIL0040 A
	INNER JOIN FIL0041 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號 AND A.單據序號 = B.序號
	LEFT JOIN VIEWFIL404E7 J ON To_Char('C11') = J.製令單別 AND A.廠客品號 = J.製令單號 AND A.異動數量=J.箱號
	LEFT JOIN VIEWFIL404F3 K ON To_Char('C11') = K.製令單別 AND A.廠客品號 = K.製令單號 AND A.異動數量=K.箱號
	LEFT JOIN VIEWFIL404G3 L ON To_Char('C11') = L.製令單別 AND A.廠客品號 = L.製令單號 AND A.異動數量=L.箱號
	
WHERE
	A.單據類別 between 'E32' and 'E37'
);

-- Oracle user_views
CREATE VIEW "VIEWFIL404E3_S1" ("製令單號", "箱號", "數量", "報廢數量", "重量", "批號", "製袋", "氣閥", "鐵條", "異動", "重工", "出貨", "品檢", "來源", "單別", "單號", "序號") AS (
SELECT 	D.歸屬編號 製令單號,
	A.異動數量 箱號,
	NVL(decode(C.製程代碼,'C31E',decode(B.數值14,0,A.贈品數量,B.數值14),B.數值5*-1),0) 數量,
	0 報廢數量,
	NVL(decode(C.製程代碼,'C31E',decode(B.數值14,0,A.毛重,A.毛重*(B.數值14/A.贈品數量)),B.數值5*-1*G.平均袋重),0) 重量,
	D.歸屬編號 ||'-'||trim(to_char(A.異動數量, '0000')) 批號,		
	1 製袋,
	decode(C.製程代碼,'C31F',1,0) 氣閥,
	decode(C.製程代碼,'C31G',1,0) 鐵條,
	0 異動,
	0 重工,
	0 出貨,
	0 品檢,
	decode(C.製程代碼,'C31E',TO_NCHAR('製袋'),'C31G',TO_NCHAR('鐵條'),TO_NCHAR('氣閥')) 來源,
	A.單據類別 單別,
	A.單據編號 單號,
	A.單據序號 序號
FROM 
	FIL0040 A
	INNER JOIN FIL0041 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號 AND A.單據序號 = B.序號
	LEFT JOIN FIL0031 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號 
	INNER JOIN FIL0030 D ON A.單據類別 = D.單據類別 AND A.單據編號 = D.單據編號
	LEFT JOIN VIEWFIL404E7 G ON D.歸屬類別 = G.製令單別 AND D.歸屬編號 = G.製令單號 AND A.異動數量=G.箱號
WHERE
	A.異動類別 = 'A' AND (C.製程代碼 = 'C31E' OR C.製程代碼 = 'C31F' OR C.製程代碼 = 'C31G')



Union All

SELECT 	A.廠客品號 製令單號,
	A.異動數量 箱號,
	NVL(decode(A.單據類別,'E35',A.贈品數量*-1,'E37',B.數值5*-1,A.贈品數量),0) 數量,
	NVL(decode(A.單據類別,'E33',B.數值5,0),0),
	NVL(decode(A.單據類別,'E35',(A.贈品數量*-1*J.平均袋重),'E37',(B.數值5*-1*J.平均袋重),A.毛重),0) 重量,
	B.批號 批號,
	1 製袋,
	B.logical2 氣閥,
	B.logical3 鐵條,
	decode(A.單據類別,'E32',1,0) 異動,
	decode(A.單據類別,'E33',1,0) 重工,
	decode(A.單據類別,'E35',1,0) 重工,
	decode(A.單據類別,'E37',1,0) 品檢,
	decode(A.單據類別,'E32',TO_NCHAR('異動'),'E33',TO_NCHAR('重工'),'E35',TO_NCHAR('出貨'),TO_NCHAR('品檢')) 來源,
	A.單據類別 單別,
	A.單據編號 單號,
	A.單據序號 序號
FROM 
	FIL0040 A
	INNER JOIN FIL0041 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號 AND A.單據序號 = B.序號
	LEFT JOIN VIEWFIL404E7 J ON To_Char('C11') = J.製令單別 AND A.廠客品號 = J.製令單號 AND A.異動數量=J.箱號
	
WHERE
	A.單據類別 = 'E32' or A.單據類別 = 'E33'  or A.單據類別 = 'E35'
);

-- Oracle user_views
CREATE VIEW "VIEWFIL404E3_S2" ("批號", "製袋", "氣閥", "鐵條", "異動", "重工", "出貨", "品檢", "來源") AS (
SELECT 	
	D.歸屬編號 ||'-'||trim(to_char(A.異動數量, '0000')) 批號,		
	1 製袋,
	decode(C.製程代碼,'C31F',1,0) 氣閥,
	decode(C.製程代碼,'C31G',1,0) 鐵條,
	0 異動,
	0 重工,
	0 出貨,
	0 品檢,
	decode(C.製程代碼,'C31E',TO_NCHAR('製袋'),'C31G',TO_NCHAR('鐵條'),TO_NCHAR('氣閥')) 來源
FROM 
	FIL0040 A
	INNER JOIN FIL0041 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號 AND A.單據序號 = B.序號
	LEFT JOIN FIL0031 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號 
	INNER JOIN FIL0030 D ON A.單據類別 = D.單據類別 AND A.單據編號 = D.單據編號
WHERE
	A.異動類別 = 'A' AND (C.製程代碼 = 'C31E' OR C.製程代碼 = 'C31F' OR C.製程代碼 = 'C31G')



Union All

SELECT 	
	B.批號 批號,
	1 製袋,
	B.logical2 氣閥,
	B.logical3 鐵條,
	decode(A.單據類別,'E32',1,0) 異動,
	decode(A.單據類別,'E33',1,0) 重工,
	decode(A.單據類別,'E35',1,0) 重工,
	decode(A.單據類別,'E37',1,0) 品檢,
	decode(A.單據類別,'E32',TO_NCHAR('異動'),'E33',TO_NCHAR('重工'),'E35',TO_NCHAR('出貨'),TO_NCHAR('品檢')) 來源
FROM 
	FIL0040 A
	INNER JOIN FIL0041 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號 AND A.單據序號 = B.序號
WHERE
	A.單據類別 = 'E32' or A.單據類別 = 'E33'  or A.單據類別 = 'E35' or A.單據類別='E37'
);

-- Oracle user_views
CREATE VIEW "VIEWFIL404E3_S3" ("單別", "單號", "序號", "箱號", "作業日期", "批號", "製令類別", "製令單號", "流水編號") AS (
SELECT 
	A.單據類別 單別, 
	A.單據編號 單號,
	A.單據序號 序號,
	A.異動數量 箱號,
	D.單據日期 作業日期,
	D.歸屬編號 ||'-'||trim(to_char(A.異動數量, '0000')) 批號,		
	D.歸屬類別 製令類別,
	D.歸屬編號 製令單號,
	A.流水編號
FROM 
	FIL0040 A
	INNER JOIN FIL0030 D ON A.單據類別 = D.單據類別 AND A.單據編號 = D.單據編號
	INNER JOIN FIL0031 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號
WHERE
	A.異動類別 = 'A' AND C.製程代碼 = 'C31E'

Union 

SELECT 
	A.單據類別 單別, 
	A.單據編號 單號,
	A.單據序號 序號,
	A.異動數量 箱號,
	D.單據日期 作業日期,
	B.批號 批號,
	To_Char('C11') 製令類別,
	A.廠客品號 製令單號,
	A.流水編號
FROM 
	FIL0040 A
	INNER JOIN FIL0041 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號 AND A.單據序號 = B.序號
	INNER JOIN FIL0030 D ON A.單據類別 = D.單據類別 AND A.單據編號 = D.單據編號

WHERE
	A.單據類別 = 'E32' or A.單據類別 = 'E37' 
);

-- Oracle user_views
CREATE VIEW "VIEWFIL404E3_S4" ("單別", "單號", "序號", "異動日期", "製令單號", "箱號", "數量", "報廢數量", "批號", "製袋", "氣閥", "鐵條", "異動", "重工", "出貨", "品檢", "來源") AS (
SELECT
	A.單據類別 單別,
	A.單據編號 單號,
	A.單據序號 序號,
	A.異動日期,
 	D.歸屬編號 製令單號,
	A.異動數量 箱號,
	decode(C.製程代碼, 'C31E', decode(B.數值14, 0, A.贈品數量, B.數值14), B.數值5*-1) 數量,
	0 報廢數量,
	D.歸屬編號 || '-' || trim(to_char(A.異動數量, '0000')) 批號,		
	1 製袋,
	decode(C.製程代碼,'C31F',1,0) 氣閥,
	decode(C.製程代碼,'C31G',1,0) 鐵條,
	0 異動,
	0 重工,
	0 出貨,
	0 品檢,
	decode(C.製程代碼, 'C31E', TO_NCHAR('製袋'), 'C31G', TO_NCHAR('鐵條'), TO_NCHAR('氣閥')) 來源
FROM 
	FIL0040 A
	INNER JOIN FIL0041 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號 AND A.單據序號 = B.序號
	INNER JOIN FIL0031 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號 
	INNER JOIN FIL0030 D ON A.單據類別 = D.單據類別 AND A.單據編號 = D.單據編號
WHERE
	A.異動類別 = 'A' AND
	C.製程代碼 between 'C31E' and 'C31G'

Union All

SELECT
	A.單據類別 單別,
	A.單據編號 單號,
	A.單據序號 序號,
	A.異動日期,
 	A.廠客品號 製令單號,
	A.異動數量 箱號,
	nvl(decode(A.單據類別, 'E35', A.贈品數量*-1, 'E37', B.數值5*-1, 'E34', 0, A.贈品數量), 0) 數量,
	nvl(decode(A.單據類別, 'E33', B.數值5,0), 0) 報廢數量,	
	B.批號 批號,
	1 製袋,
	B.logical2 氣閥,
	B.logical3 鐵條,
	decode(A.單據類別,'E32',1,0) 異動,
	decode(A.單據類別,'E33',1,0) 重工,
	decode(A.單據類別,'E35',1,0) 重工,
	decode(A.單據類別,'E37',1,0) 品檢,
	decode(A.單據類別,'E32', TO_NCHAR('異動'), 'E33', TO_NCHAR('重工'), 'E35', TO_NCHAR('出貨'), 'E37', TO_NCHAR('品檢'), ' ') 來源
FROM 
	FIL0040 A
	INNER JOIN FIL0041 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號 AND A.單據序號 = B.序號
WHERE
	A.單據類別 between 'E32' and 'E37'
	
union all

SELECT 
	A.單據類別 單別, 
	A.單據編號 單號,
	A.單據序號 序號,
	A.異動日期,
	A.廠客品號 製令單號,
	A.異動數量 箱號,
	A.贈品數量 數量,
	0 報廢數量,
	C.批號,
	0 製袋,
	0 氣閥,
	0 鐵條,
	1 異動,
	0 重工,
	0 出貨,
	0 品檢,
	TO_NCHAR('盤點')
FROM 
	FIL0040 A
	INNER JOIN FIL0030 B ON A.單據類別 = B.單據類別 AND A.單據編號 = B.單據編號
	/*特殊欄位*/
	INNER JOIN FIL0041 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號 AND A.單據序號 = C.序號
WHERE
	A.單據類別 = 'F32' AND
	A.異動類別 = '1' AND /*半成品*/
	B.稅別 = 'B' /*廠內*/);

-- Oracle user_views
CREATE VIEW "VIEWFIL404E3_S5" ("批號", "來源", "單別", "單號", "序號", "單據日期") AS (
SELECT 	
	D.歸屬編號 ||'-'||trim(to_char(A.異動數量, '0000')) 批號,		
	TO_NCHAR('製袋') 來源,
	A.單據類別 單別,
	A.單據編號 單號,
	A.單據序號 序號,
	D.單據日期
FROM 
	FIL0040 A
	LEFT JOIN FIL0031 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號 
	INNER JOIN FIL0030 D ON A.單據類別 = D.單據類別 AND A.單據編號 = D.單據編號
WHERE
	A.異動類別 = 'A' AND C.製程代碼 = 'C31E' 

Union All

SELECT
	B.批號 批號,
	decode(A.單據類別,'E32',TO_NCHAR('異動'),TO_NCHAR('重工')) 來源,
	A.單據類別 單別,
	A.單據編號 單號,
	A.單據序號 序號,
	D.單據日期
FROM 
	FIL0040 A
	INNER JOIN FIL0041 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號 AND A.單據序號 = B.序號
	INNER JOIN FIL0030 D ON A.單據類別 = D.單據類別 AND A.單據編號 = D.單據編號	
WHERE
	A.單據類別 between 'E32' AND 'E33' 
);

-- Oracle user_views
CREATE VIEW "VIEWFIL404E3_S6" ("製令單號", "箱號") AS (
SELECT DISTINCT
	A.製令單號,
	MAX(A.箱號) 箱號
FROM	
	(SELECT DISTINCT		
		D.歸屬編號 製令單號,
		A.異動數量 箱號
	FROM 
		FIL0040 A
		INNER JOIN FIL0031 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號 
		INNER JOIN FIL0030 D ON A.單據類別 = D.單據類別 AND A.單據編號 = D.單據編號
	WHERE
		A.異動類別 = 'A' AND (C.製程代碼 = 'C31E' OR C.製程代碼 = 'C31F' OR C.製程代碼 = 'C31G')

	Union All

	SELECT DISTINCT
		A.廠客品號 製令單號,
		A.異動數量 箱號
	FROM 
		FIL0040 A	
		INNER JOIN FIL0030 D ON A.單據類別 = D.單據類別 AND A.單據編號 = D.單據編號
	WHERE
		(A.單據類別 = 'E32' or A.單據類別 = 'E33'  or A.單據類別 = 'E35' or A.單據類別='E37') 	
	) A	
GROUP BY 
A.製令單號
);

-- Oracle user_views
CREATE VIEW "VIEWFIL404E4" ("批號", "製袋", "氣閥", "鐵條", "異動", "重工", "出貨", "品檢", "箱號", "數量", "報廢數量", "重量", "平均重量") AS (
SELECT 
	A.批號 批號,
	decode(SUM(製袋),0,0,1) 製袋,
	decode(SUM(氣閥),0,0,1) 氣閥,
	decode(SUM(鐵條),0,0,1) 鐵條,
	decode(SUM(異動),0,0,1) 異動,
	decode(SUM(重工),0,0,1) 重工,
	decode(SUM(出貨),0,0,1) 出貨,
	decode(SUM(品檢),0,0,1) 品檢,
	Max(A.箱號) 箱號,
	SUM(A.數量) 數量,
	SUM(A.報廢數量) 報廢數量,
	SUM(A.數量*DECODE(NVL(C.平均袋重,0),0,NVL(B.平均袋重,0),NVL(C.平均袋重,0))) 重量,
	DECODE(SUM(A.數量),0,0,SUM(A.數量*DECODE(NVL(C.平均袋重,0),0,NVL(B.平均袋重,0),NVL(C.平均袋重,0)))/SUM(A.數量)) 平均重量
FROM 
	ViewFIL404E3_S A
	LEFT JOIN ViewFIL404E7 B ON A.製令單號=B.製令單號 AND A.箱號=B.箱號
	LEFT JOIN ViewFIL404E8 C ON A.製令單號=C.製令單號 AND A.箱號=C.箱號

GROUP BY 
	A.批號
);

-- Oracle user_views
CREATE VIEW "VIEWFIL404E4_S" ("批號", "製袋", "氣閥", "鐵條", "異動", "重工", "出貨", "品檢") AS (
SELECT 
	A.批號 批號,
	decode(SUM(製袋),0,0,1) 製袋,
	decode(SUM(氣閥),0,0,1) 氣閥,
	decode(SUM(鐵條),0,0,1) 鐵條,
	decode(SUM(異動),0,0,1) 異動,
	decode(SUM(重工),0,0,1) 重工,
	decode(SUM(出貨),0,0,1) 出貨,
	decode(SUM(品檢),0,0,1) 品檢
FROM 
	ViewFIL404E3_S2 A
GROUP BY 
	A.批號
);

-- Oracle user_views
CREATE VIEW "VIEWFIL404E4_S1" ("批號", "製袋", "氣閥", "鐵條", "異動", "重工", "出貨", "品檢", "箱號", "數量", "報廢數量", "重量", "平均重量") AS (
SELECT 
	A.批號 批號,
	decode(SUM(製袋),0,0,1) 製袋,
	decode(SUM(氣閥),0,0,1) 氣閥,
	decode(SUM(鐵條),0,0,1) 鐵條,
	decode(SUM(異動),0,0,1) 異動,
	decode(SUM(重工),0,0,1) 重工,
	decode(SUM(出貨),0,0,1) 出貨,
	decode(SUM(品檢),0,0,1) 品檢,
	Max(A.箱號) 箱號,
	SUM(A.數量) 數量,
	SUM(A.報廢數量) 報廢數量,
	SUM(A.數量*DECODE(NVL(C.平均袋重,0),0,NVL(B.平均袋重,0),NVL(C.平均袋重,0))) 重量,
	DECODE(SUM(A.數量),0,0,SUM(A.數量*DECODE(NVL(C.平均袋重,0),0,NVL(B.平均袋重,0),NVL(C.平均袋重,0)))/SUM(A.數量)) 平均重量
FROM 
	ViewFIL404E3_S1 A
	LEFT JOIN ViewFIL404E7 B ON A.製令單號=B.製令單號 AND A.箱號=B.箱號
	LEFT JOIN ViewFIL404E8 C ON A.製令單號=C.製令單號 AND A.箱號=C.箱號

GROUP BY 
	A.批號
);

-- Oracle user_views
CREATE VIEW "VIEWFIL404E4_T" ("批號", "數量", "製袋重量", "平均袋重") AS (  
SELECT 
	A.批號,
	sum(A.數量)	數量,
	sum(A.數量*DECODE(nvl(B.平均袋重,0),0,C.平均袋重,B.平均袋重)) 製袋重量,
	AVG(DECODE(nvl(B.平均袋重,0),0,C.平均袋重,B.平均袋重)) 平均袋重
FROM	
(
SELECT 	D.歸屬編號||'-'||trim(to_char(A.異動數量,'0009')) 批號,
		sum(NVL(decode(B.數值14,0,A.贈品數量,B.數值14),0)) 數量,
		sum(NVL(decode(B.數值14,0,A.毛重,A.毛重*DECODE(A.贈品數量,0,0,(B.數值14/A.贈品數量))),0)) 重量
FROM 
	FIL0040 A,FIL0041 B,FIL0031 C ,FIL0030 D 
WHERE
	A.單據類別 = 'C41' AND A.異動類別 = 'A' AND C.製程代碼 = 'C31E' 
	AND A.單據類別 = B.單別 AND A.單據編號 = B.單號 AND A.單據序號 = B.序號
	AND A.單據類別 = C.單別 AND A.單據編號 = C.單號
	AND A.單據類別 = D.單據類別 AND A.單據編號 = D.單據編號
GROUP BY 
	D.歸屬編號||'-'||trim(to_char(A.異動數量,'0009'))

Union All

SELECT 	D.歸屬編號||'-'||trim(to_char(A.異動數量,'0009')) 批號,
		sum(NVL((B.數值5+A.燙金費)*-1,0)) 數量,
		0 重量
FROM 
	FIL0040 A,FIL0041 B,FIL0031 C ,FIL0030 D 
WHERE
	A.單據類別 = 'C41' AND A.異動類別 = 'A' AND C.製程代碼 = 'C31F'
	AND A.單據類別 = B.單別 AND A.單據編號 = B.單號 AND A.單據序號 = B.序號
	AND A.單據類別 = C.單別 AND A.單據編號 = C.單號
	AND A.單據類別 = D.單據類別 AND A.單據編號 = D.單據編號
GROUP BY 
	D.歸屬編號||'-'||trim(to_char(A.異動數量,'0009'))
	
Union All

SELECT 	D.歸屬編號||'-'||trim(to_char(A.異動數量,'0009')) 批號,
		sum(NVL((B.數值5+A.燙金費)*-1,0)) 數量,
		0 重量
FROM 
	FIL0040 A,FIL0041 B,FIL0031 C ,FIL0030 D 
WHERE
	A.單據類別 = 'C41' AND A.異動類別 = 'A' AND C.製程代碼 = 'C31G'
	AND A.單據類別 = B.單別 AND A.單據編號 = B.單號 AND A.單據序號 = B.序號
	AND A.單據類別 = C.單別 AND A.單據編號 = C.單號
	AND A.單據類別 = D.單據類別 AND A.單據編號 = D.單據編號
GROUP BY 
	D.歸屬編號||'-'||trim(to_char(A.異動數量,'0009'))
	
Union All

SELECT 	A.廠客品號||'-'||trim(to_char(A.異動數量,'0009')) 批號,
	sum(NVL(A.贈品數量,0)) 數量,
	sum(NVL(A.毛重,0)) 重量
FROM 
	FIL0040 A
	INNER JOIN FIL0041 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號 AND A.單據序號 = B.序號
	
WHERE
	A.單據類別 = 'E32' 
GROUP BY
	A.廠客品號||'-'||trim(to_char(A.異動數量,'0009'))

Union All

SELECT 	A.廠客品號||'-'||trim(to_char(A.異動數量,'0009')) 批號,
	sum(NVL(A.贈品數量,0)) 數量,
	sum(NVL(A.毛重,0)) 重量
FROM 
	FIL0040 A
	INNER JOIN FIL0041 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號 AND A.單據序號 = B.序號
	
WHERE
	A.單據類別 = 'E33' 
GROUP BY
	A.廠客品號||'-'||trim(to_char(A.異動數量,'0009'))
	
Union All

SELECT 	A.廠客品號||'-'||trim(to_char(A.異動數量,'0009')) 批號,
	sum(NVL(B.數值5,0)) 數量,
	sum(NVL(decode(B.數值5,0,0,B.數值5*(decode(A.贈品數量,0,0,A.毛重/A.贈品數量))),0)) 重量
FROM 
	FIL0040 A
	INNER JOIN FIL0041 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號 AND A.單據序號 = B.序號
	
WHERE
	A.單據類別 = 'E33' 
GROUP BY
	A.廠客品號||'-'||trim(to_char(A.異動數量,'0009'))	
		
Union All

SELECT 	A.廠客品號||'-'||trim(to_char(A.異動數量,'0009')) 批號,
	sum((A.贈品數量-NVL(B.數值1,0))+NVL(B.數值5*-1,0)) 數量,
		0 重量
FROM 
	FIL0040 A
	INNER JOIN FIL0041 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號 AND A.單據序號 = B.序號
	
WHERE
	A.單據類別 = 'E37' 
GROUP BY
	A.廠客品號||'-'||trim(to_char(A.異動數量,'0009'))
) A	
LEFT JOIN ViewFIL404E71 B ON A.批號=B.批號			
LEFT JOIN ViewFIL404E81 C ON A.批號=C.批號
Group by 
	A.批號

);

-- Oracle user_views
CREATE VIEW "VIEWFIL404E4_T1" ("批號", "數量") AS (  
SELECT 
	A.批號,
	sum(A.數量)	數量
FROM	
(
SELECT 	D.歸屬編號||'-'||trim(to_char(A.異動數量,'0009')) 批號,
		sum(
			decode(C.製程代碼,'C31E',NVL(decode(B.數值14,0,A.贈品數量,B.數值14),0),'C31F',NVL((B.數值5+A.燙金費)*-1,0),'C31G',NVL((B.數值5+A.燙金費)*-1,0),0)
			) 數量
FROM 
	FIL0040 A,FIL0041 B,FIL0031 C ,FIL0030 D 
WHERE
	A.單據類別 = 'C41' AND A.異動類別 = 'A' 
	AND A.單據類別 = B.單別 AND A.單據編號 = B.單號 AND A.單據序號 = B.序號
	AND A.單據類別 = C.單別 AND A.單據編號 = C.單號
	AND A.單據類別 = D.單據類別 AND A.單據編號 = D.單據編號
	AND C.製程代碼 BETWEEN 'C31E' AND 'C31G'
GROUP BY 
	D.歸屬編號||'-'||trim(to_char(A.異動數量,'0009'))
	
Union All

SELECT 	A.廠客品號||'-'||trim(to_char(A.異動數量,'0009')) 批號,
	sum(
		decode(A.單據類別,'E32',NVL(A.贈品數量,0),'E33',NVL(A.贈品數量,0)+NVL(B.數值5,0),'E37' ,NVL(B.數值5*-1,0),0)
	) 數量
FROM 
	FIL0040 A,FIL0041 B
WHERE
	(A.單據類別 = 'E32' or A.單據類別 = 'E33' or A.單據類別 = 'E37' )
	AND A.單據類別 = B.單別 AND A.單據編號 = B.單號 AND A.單據序號 = B.序號
GROUP BY
	A.廠客品號||'-'||trim(to_char(A.異動數量,'0009'))

) A	
Group by 
	A.批號

);

-- Oracle user_views
CREATE VIEW "VIEWFIL404E4_T2" ("批號", "數量") AS (
SELECT 	D.歸屬編號||'-'||trim(to_char(A.異動數量,'0009')) 批號,
		sum(NVL(B.數值5*-1,0)) 數量
FROM 
	FIL0040 A,FIL0041 B,FIL0031 C ,FIL0030 D 
WHERE
	A.單據類別 = 'C41' AND A.異動類別 = 'A' AND C.製程代碼 = 'C31F'
	AND A.單據類別 = B.單別 AND A.單據編號 = B.單號 AND A.單據序號 = B.序號
	AND A.單據類別 = C.單別 AND A.單據編號 = C.單號
	AND A.單據類別 = D.單據類別 AND A.單據編號 = D.單據編號
GROUP BY 
	D.歸屬編號||'-'||trim(to_char(A.異動數量,'0009'))
);

-- Oracle user_views
CREATE VIEW "VIEWFIL404E4_T3" ("批號", "數量") AS (
SELECT 	D.歸屬編號||'-'||trim(to_char(A.異動數量,'0009')) 批號,
		sum(NVL(B.數值5*-1,0)) 數量
FROM 
	FIL0040 A,FIL0041 B,FIL0031 C ,FIL0030 D 
WHERE
	A.單據類別 = 'C41' AND A.異動類別 = 'A' AND C.製程代碼 = 'C31G'
	AND A.單據類別 = B.單別 AND A.單據編號 = B.單號 AND A.單據序號 = B.序號
	AND A.單據類別 = C.單別 AND A.單據編號 = C.單號
	AND A.單據類別 = D.單據類別 AND A.單據編號 = D.單據編號
GROUP BY 
	D.歸屬編號||'-'||trim(to_char(A.異動數量,'0009'))
);

-- Oracle user_views
CREATE VIEW "VIEWFIL404E4_T4" ("批號", "數量", "重量") AS (
SELECT 	A.廠客品號||'-'||trim(to_char(A.異動數量,'0009')) 批號,
	sum(NVL(A.贈品數量,0)) 數量,
	sum(NVL(A.毛重,0)) 重量
FROM 
	FIL0040 A
	INNER JOIN FIL0041 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號 AND A.單據序號 = B.序號
	
WHERE
	A.單據類別 = 'E32' 
GROUP BY
	A.廠客品號||'-'||trim(to_char(A.異動數量,'0009'))
);

-- Oracle user_views
CREATE VIEW "VIEWFIL404E4_T5" ("批號", "數量", "重量", "報廢數量") AS (
SELECT 	A.廠客品號||'-'||trim(to_char(A.異動數量,'0009')) 批號,
	sum(NVL(A.贈品數量,0)) 數量,
	sum(NVL(A.毛重,0)) 重量,
	sum(NVL(B.數值5,0)) 報廢數量
FROM 
	FIL0040 A
	INNER JOIN FIL0041 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號 AND A.單據序號 = B.序號
	
WHERE
	A.單據類別 = 'E33' 
GROUP BY
	A.廠客品號||'-'||trim(to_char(A.異動數量,'0009'))
);

-- Oracle user_views
CREATE VIEW "VIEWFIL404E4_T6" ("批號", "數量") AS (
SELECT 	A.廠客品號||'-'||trim(to_char(A.異動數量,'0009')) 批號,
	sum(NVL(B.數值5*-1,0)) 數量
FROM 
	FIL0040 A
	INNER JOIN FIL0041 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號 AND A.單據序號 = B.序號
	
WHERE
	A.單據類別 = 'E37' 
GROUP BY
	A.廠客品號||'-'||trim(to_char(A.異動數量,'0009'))
);

-- Oracle user_views
CREATE VIEW "VIEWFIL404E4_T7" ("製令號碼", "結存數量", "結存重量") AS (  
SELECT 
	regexp_substr(A.批號,'[^-]+', 1, 1) 製令號碼,
	sum(A.結存數量) 結存數量,
	sum(A.結存重量) 結存重量
FROM	
	FIL004H A
GROUP BY
	regexp_substr(A.批號,'[^-]+', 1, 1)
);

-- Oracle user_views
CREATE VIEW "VIEWFIL404E4_T8" ("批號") AS (  
SELECT 
	DISTINCT A.批號
FROM	
	FIL004L A
);

-- Oracle user_views
CREATE VIEW "VIEWFIL404E5" ("製令類別", "製令單號", "箱號", "數量", "報廢數量", "重量", "平均重量") AS (
SELECT 
	TO_CHAR('C11') 製令類別,
	A.製令單號,
	Max(A.箱號) 箱號,
	SUM(A.數量) 數量,
	SUM(A.報廢數量) 報廢數量,
	SUM(A.數量*DECODE(NVL(C.平均袋重,0),0,NVL(B.平均袋重,0),NVL(C.平均袋重,0))) 重量,
	DECODE(SUM(A.數量),0,0,SUM(A.數量*DECODE(NVL(C.平均袋重,0),0,NVL(B.平均袋重,0),NVL(C.平均袋重,0)))/SUM(A.數量)) 平均重量
FROM 
	ViewFIL404E3_S A
	LEFT JOIN ViewFIL404E71 B ON B.批號 = A.製令單號||'-'||trim(to_char(A.箱號,'0009'))
	LEFT JOIN ViewFIL404E81 C ON C.批號 = A.製令單號||'-'||trim(to_char(A.箱號,'0009'))
GROUP BY 
	TO_CHAR('C11'),
	A.製令單號
);

-- Oracle user_views
CREATE VIEW "VIEWFIL404E6" ("製令類別", "製令單號", "製袋", "氣閥", "鐵條", "異動", "重工", "出貨", "品檢", "箱號", "數量", "報廢數量", "重量", "平均重量") AS (
SELECT 
	TO_CHAR('C11') 製令類別,
	A.製令單號,
	decode(SUM(製袋),0,0,1) 製袋,
	decode(SUM(氣閥),0,0,1) 氣閥,
	decode(SUM(鐵條),0,0,1) 鐵條,
	decode(SUM(異動),0,0,1) 異動,
	decode(SUM(重工),0,0,1) 重工,
	decode(SUM(出貨),0,0,1) 出貨,
	decode(SUM(品檢),0,0,1) 品檢,
	Max(A.箱號) 箱號,
	SUM(A.數量) 數量,
	SUM(A.報廢數量) 報廢數量,
	SUM(A.數量*DECODE(NVL(C.平均袋重,0),0,NVL(B.平均袋重,0),NVL(C.平均袋重,0))) 重量,
	DECODE(SUM(A.數量),0,0,SUM(A.數量*DECODE(NVL(C.平均袋重,0),0,NVL(B.平均袋重,0),NVL(C.平均袋重,0)))/SUM(A.數量)) 平均重量
FROM 
	ViewFIL404E3_S A
	LEFT JOIN ViewFIL404E7 B ON A.製令單號=B.製令單號 AND A.箱號=B.箱號
	LEFT JOIN ViewFIL404E8 C ON A.製令單號=C.製令單號 AND A.箱號=C.箱號
GROUP BY 
	TO_CHAR('C11'),
	A.製令單號
);

-- Oracle user_views
CREATE VIEW "VIEWFIL404E7" ("製令單別", "製令單號", "箱號", "平均袋重", "紙箱重量", "作業人員", "作業員二", "作業員三", "作業人員姓名", "作業員二姓名", "作業員三姓名") AS (
SELECT 	DISTINCT A.製令單別,A.製令單號,A.箱號,
	first_value(A.平均袋重) over (partition by 製令單別,製令單號,箱號  order by 單號 asc) 平均袋重,
	first_value(A.紙箱重量) over (partition by 製令單別,製令單號,箱號  order by 單號 asc) 紙箱重量,
	first_value(A.作業人員) over (partition by 製令單別,製令單號,箱號  order by 單號 asc) 作業人員,
	first_value(A.作業員二) over (partition by 製令單別,製令單號,箱號  order by 單號 asc) 作業員二,
	first_value(A.作業員三) over (partition by 製令單別,製令單號,箱號  order by 單號 asc) 作業員三,
	first_value(A.作業人員姓名) over (partition by 製令單別,製令單號,箱號  order by 單號 asc) 作業人員姓名,
	first_value(A.作業員二姓名) over (partition by 製令單別,製令單號,箱號  order by 單號 asc) 作業員二姓名,
	first_value(A.作業員三姓名) over (partition by 製令單別,製令單號,箱號  order by 單號 asc) 作業員三姓名	
FROM

	(SELECT
		C1.歸屬類別 製令單別,
		C1.歸屬編號 製令單號,
		A.異動數量 箱號,
		DECODE(A.贈品數量,0,0,(A.毛重-nvl(D.單價下限率,0))/A.贈品數量) 平均袋重,
		nvl(D.單價下限率,0) 紙箱重量,
		A.單據編號||'-'||TO_CHAR(A.單據序號,'0000') 單號,
		C1.業務員 作業人員,
		nvl(E.員工姓名,' ') 作業人員姓名, 
		C.文數字10 作業員二,
		nvl(G.員工姓名,' ') 作業員二姓名, 
		C.文數字11 作業員三,
		nvl(H.員工姓名,' ') 作業員三姓名
	FROM 
		FIL0040 A
		INNER JOIN FIL0031 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號
		INNER JOIN FIL0030 C1 ON A.單據類別 = C1.單據類別 AND A.單據編號 = C1.單據編號
		INNER JOIN FIL0041 B ON B.單別=A.單據類別 AND B.單號=A.單據編號 AND B.序號=A.單據序號
		LEFT JOIN FIL0010 E ON C1.業務員 = E.員工編號
		LEFT JOIN FIL0010 G ON C.文數字10 = G.員工編號
		LEFT JOIN FIL0010 H ON C.文數字11 = H.員工編號
		LEFT JOIN FIL0012 D ON D.產品編號=
			 CASE WHEN B.Logical5=0 THEN
				CASE WHEN C.數值17<>A.贈品數量 THEN DECODE(C.文數字12,' ',C.文數字7,C.文數字12) ELSE C.文數字7 END 
			 ELSE
				CASE WHEN C.數值19<>A.贈品數量 THEN DECODE(C.文數字12,' ',C.文數字8,C.文數字12) ELSE C.文數字8 END 
			 END 	
	WHERE
		A.單據類別 = 'C41' AND
		A.異動類別 = 'A' AND
		C.製程代碼 = 'C31E'
	) A
);

-- Oracle user_views
CREATE VIEW "VIEWFIL404E71" ("批號", "平均袋重") AS (
SELECT 	DISTINCT A.批號,
	nvl(first_value(A.平均袋重) over (partition by A.批號  order by 單號 asc),0) 平均袋重
		
FROM
	(SELECT
		C1.歸屬編號||'-'||trim(to_char(A.異動數量,'0009')) 批號,
		A.單據編號||'-'||TO_CHAR(A.單據序號,'0000') 單號,
		DECODE(A.贈品數量,0,0,A.毛重/A.贈品數量) 平均袋重
	FROM 
		FIL0040 A
		INNER JOIN FIL0031 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號
		INNER JOIN FIL0030 C1 ON A.單據類別 = C1.單據類別 AND A.單據編號 = C1.單據編號
	WHERE
		A.單據類別 = 'C41' AND
		A.異動類別 = 'A' AND
		C.製程代碼 = 'C31E' AND A.贈品數量<>0
	) A
);

-- Oracle user_views
CREATE VIEW "VIEWFIL404E72" ("製令單別", "製令單號", "作業日期", "每日產量") AS (
SELECT
		C1.歸屬類別 製令單別,
		C1.歸屬編號 製令單號,
		C1.單據日期 作業日期,
		sum(decode(B.數值14,0,A.贈品數量,B.數值14)) 每日產量
	FROM 
		FIL0040 A
		INNER JOIN FIL0041 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號 AND A.單據序號 = B.序號
		INNER JOIN FIL0031 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號
		INNER JOIN FIL0030 C1 ON A.單據類別 = C1.單據類別 AND A.單據編號 = C1.單據編號
	WHERE
		A.單據類別 = 'C41' AND
		A.異動類別 = 'A' AND
		C.製程代碼 = 'C31E'
	Group by	
		C1.歸屬類別,
		C1.歸屬編號,
		C1.單據日期
);

-- Oracle user_views
CREATE VIEW "VIEWFIL404E72A" ("成品檢驗單號", "每日產量") AS (
SELECT
		B.專案代號 成品檢驗單號,
		sum(decode(B.數值14,0,A.贈品數量,B.數值14)) 每日產量
	FROM 
		FIL0040 A
		INNER JOIN FIL0041 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號 AND A.單據序號 = B.序號
		INNER JOIN FIL0031 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號
	WHERE
		A.單據類別 = 'C41' AND
		A.異動類別 = 'A' AND
		C.製程代碼 = 'C31E' AND
		B.專案代號<>' '
	Group by	
		B.專案代號
);

-- Oracle user_views
CREATE VIEW "VIEWFIL404E73" ("製令單別", "製令單號", "箱號", "平均袋重") AS (
SELECT 	DISTINCT 
		A.製令單別,
		A.製令單號,
		nvl(first_value(A.箱號) over (partition by A.製令單別,A.製令單號  order by A.製令單別,A.製令單號,A.箱號 asc),0) 箱號,
		nvl(first_value(A.平均袋重) over (partition by A.製令單別,A.製令單號  order by A.製令單別,A.製令單號,A.箱號 asc),0) 平均袋重		
FROM
	(SELECT
		C1.歸屬類別 製令單別,
		C1.歸屬編號 製令單號,
		A.異動數量 箱號,
		DECODE(A.贈品數量,0,0,(A.毛重-nvl(D.單價下限率,0))/A.贈品數量) 平均袋重
	FROM 
		FIL0040 A
		INNER JOIN FIL0031 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號
		INNER JOIN FIL0030 C1 ON A.單據類別 = C1.單據類別 AND A.單據編號 = C1.單據編號
		INNER JOIN FIL0041 B ON B.單別=A.單據類別 AND B.單號=A.單據編號 AND B.序號=A.單據序號
		LEFT JOIN FIL0012 D ON D.產品編號=
			 CASE WHEN B.Logical5=0 THEN
				CASE WHEN C.數值17<>A.贈品數量 THEN DECODE(C.文數字12,' ',C.文數字7,C.文數字12) ELSE C.文數字7 END 
			 ELSE
				CASE WHEN C.數值19<>A.贈品數量 THEN DECODE(C.文數字12,' ',C.文數字8,C.文數字12) ELSE C.文數字8 END 
			 END 	
	WHERE
		A.單據類別 = 'C41' AND
		A.異動類別 = 'A' AND
		C.製程代碼 = 'C31E' AND
		A.毛重-nvl(D.單價下限率,0)>0		
	) A 
);

-- Oracle user_views
CREATE VIEW "VIEWFIL404E74" ("製令單號", "最後箱號", "數量", "重量") AS (
SELECT
 	D.歸屬編號 製令單號,
	max(A.異動數量) 最後箱號,
	sum(decode(B.數值14,0,A.贈品數量,B.數值14)) 數量,
	sum(decode(B.數值14,0,A.毛重,A.毛重*decode(A.贈品數量,0,0,(B.數值14/A.贈品數量)))) 重量	
FROM 
	FIL0040 A
	INNER JOIN FIL0041 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號 AND A.單據序號 = B.序號 
	INNER JOIN FIL0030 D ON A.單據類別 = D.單據類別 AND A.單據編號 = D.單據編號
	LEFT JOIN FIL0031 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號
WHERE
	A.異動類別 = 'A' AND
	C.製程代碼 = 'C31E'
GROUP BY
	D.歸屬編號
);

-- Oracle user_views
CREATE VIEW "VIEWFIL404E75" ("批號", "平均製袋重量", "平均氣閥重量", "平均鐵條重量", "紙箱重量") AS (
select distinct A.批號,
	(select b.製袋重量/b.數量
	from fil004l B  
	where B.批號=A.批號 and B.製袋重量 > 0
	order by 異動日期
	fetch first 1 rows only) as 平均製袋重量,
	(select b.氣閥重量/b.數量
	from fil004l B  
	where B.批號=A.批號 and B.氣閥重量 > 0
	order by 異動日期
	fetch first 1 rows only) as 平均氣閥重量,
	(select b.鐵條重量/b.數量
	from fil004l B  
	where B.批號=A.批號 and B.鐵條重量 > 0
	order by 異動日期
	fetch first 1 rows only) as 平均鐵條重量,
	(select b.紙箱重量
	from fil004l B  
	where B.批號=A.批號 and B.紙箱重量 > 0
	order by 異動日期
	fetch first 1 rows only) as 紙箱重量
from fil004l A
);

-- Oracle user_views
CREATE VIEW "VIEWFIL404E8" ("製令單別", "製令單號", "箱號", "平均袋重") AS (
SELECT	
	TO_CHAR('C11') 製令單別,
	A.廠客品號 製令單號,
	A.異動數量 箱號,
	DECODE(sum(A.贈品數量),0,0,sum(A.毛重)/sum(A.贈品數量)) 平均袋重
FROM 
	FIL0040 A
WHERE
	A.單據類別 = 'E37'
Group by 
	TO_CHAR('C11'),
	A.廠客品號,
	A.異動數量
);

-- Oracle user_views
CREATE VIEW "VIEWFIL404E81" ("批號", "平均袋重") AS (
SELECT 	DISTINCT A.批號,
	nvl(first_value(A.平均袋重) over (partition by A.批號  order by A.單號 asc),0) 平均袋重
		
FROM
(SELECT	
	A.廠客品號||'-'||trim(to_char(A.異動數量,'0009')) 批號,
	A.單據編號||'-'||TO_CHAR(A.單據序號,'0000') 單號,
	DECODE(A.贈品數量,0,0,A.毛重/A.贈品數量) 平均袋重
FROM 
	FIL0040 A
WHERE
	A.單據類別 = 'E32'	 AND A.贈品數量<>0
) A
);

-- Oracle user_views
CREATE VIEW "VIEWFIL404EA" ("單別", "單號", "Ａ材領料米數", "Ｂ材領料米數", "側邊領料米數", "底邊領料米數", "Ａ切刀次數", "Ｂ切刀次數", "側切刀次數", "底切刀次數", "總切刀次數", "補足上次尾數", "補足上次尾數_箱數", "繳庫袋數", "繳庫袋數_箱數", "尾數成品", "尾數成品_箱數", "繳庫總袋數", "繳庫總袋數_箱數", "尾數成品二", "尾數成品二_箱數", "待重工總袋數", "待重工總箱數", "報廢數", "重整數", "結束", "待補", "不良剔除後成品率", "展開尺寸_寬", "生產條件成袋數", "A材退庫", "B材退庫", "側邊退庫", "底邊退庫") AS (                                                                                                                                                      SELECT 
	A.單別, 
	A.單號,
	A.Ａ材領料米數,
	A.Ｂ材領料米數,
	A.側邊領料米數,
	A.底邊領料米數,
	A.Ａ切刀次數,
	A.Ｂ切刀次數,
	A.側切刀次數,
	A.底切刀次數,
	A.繳庫總袋數 + 	C.送貨地址序號 + decode(C.Logical11,0,C.聯絡人序號,0) 總切刀次數,
	A.補足上次尾數,
	A.補足上次尾數_箱數,
	A.繳庫袋數,
	A.繳庫袋數_箱數,
	A.尾數成品,
	A.尾數成品_箱數,
	A.繳庫總袋數,
	A.繳庫袋數_箱數 + A.補足上次尾數_箱數 + A.尾數成品_箱數 繳庫總袋數_箱數,
	A.尾數成品二,
	A.尾數成品二_箱數,
	A.待重工總袋數,
	A.待重工總箱數,
	C.送貨地址序號 報廢數,
	C.聯絡人序號 重整數,
	C.Logical4 結束,
	C.Logical5 待補,
	case
		when C.數值6 = 0 or A.Ａ材領料米數 = 0 then 0
		else round(A.繳庫總袋數 / (1000 / C.數值6 * A.Ａ材領料米數) * 100, 0)
	end 不良剔除後成品率,
	C.數值6 展開尺寸_寬,
	E.成袋數 生產條件成袋數,
	A.A材退庫,
	A.B材退庫,
	A.側邊退庫,
	A.底邊退庫
FROM
	(	SELECT 
			A.單據類別 單別, 
			A.單據編號 單號,
			sum((C.數值1-C.數值15-C.數值19)*decode(M.邏輯值一,1,2,1)) Ａ材領料米數,
			sum(C.數值2-C.數值16-C.數值20) Ｂ材領料米數,
			sum(C.數值3-C.數值18-C.數值22) 側邊領料米數,
			sum(C.數值4-C.數值17-C.數值21) 底邊領料米數,
			sum(C.數值10) Ａ切刀次數,
			sum(C.數值11) Ｂ切刀次數,
			sum(C.數值12) 側切刀次數,
			sum(C.數值13) 底切刀次數,
			sum(C.數值14) 補足上次尾數,
			sum(decode(C.數值14, 0, 0, 1)) 補足上次尾數_箱數,
			sum(decode(A.贈品數量, decode(A.單據序號, D.序號/*末一筆*/, decode(C.Logical5, 0, B.數值17, B.數值19), E.序號/*末二筆*/, decode(D.Logical2/*雙膜*/, 0, A.贈品數量/*非雙膜數量全計*/, decode(C.Logical5, 0, B.數值17, B.數值19)), A.贈品數量/*非末一二筆數量全計*/), decode(C.數值14/*補尾數*/, 0, A.贈品數量, 0), 0)) 繳庫袋數,
			sum(decode(A.贈品數量, decode(A.單據序號, D.序號/*末一筆*/, decode(C.Logical5, 0, B.數值17, B.數值19), E.序號/*末二筆*/, decode(D.Logical2/*雙膜*/, 0, A.贈品數量/*非雙膜數量全計*/, decode(C.Logical5, 0, B.數值17, B.數值19)), A.贈品數量/*非末一二筆數量全計*/), decode(C.數值14/*補尾數*/, 0, 1, 0), 0)) 繳庫袋數_箱數,
			sum(decode(A.單據序號, D.序號/*末一筆*/, decode(A.贈品數量, decode(C.Logical5, 0, B.數值17, B.數值19), 0, A.贈品數量), E.序號/*末二筆*/, decode(D.Logical2/*雙膜*/, 0, 0, decode(A.贈品數量, decode(C.Logical5, 0, B.數值17, B.數值19), 0, A.贈品數量)), 0)) 尾數成品,  
			sum(decode(A.單據序號, D.序號/*末一筆*/, decode(A.贈品數量, decode(C.Logical5, 0, B.數值17, B.數值19), 0, B.Logical4), E.序號/*末二筆*/, decode(D.Logical2/*雙膜*/, 0, 0, decode(A.贈品數量, decode(C.Logical5, 0, B.數值17, B.數值19), 0, B.Logical4)), 0)) 尾數成品_箱數,  /*有尾數成品且結束則1箱*/
			sum(decode(A.單據序號, E.序號/*末二筆*/, decode(D.Logical2/*雙膜*/, 0, 0, decode(A.贈品數量, decode(C.Logical5, 0, B.數值17, B.數值19), 0, A.贈品數量)), 0)) 尾數成品二,  
			sum(decode(A.單據序號, E.序號/*末二筆*/, decode(D.Logical2/*雙膜*/, 0, 0, decode(A.贈品數量, decode(C.Logical5, 0, B.數值17, B.數值19), 0, B.Logical4)), 0)) 尾數成品二_箱數,
			sum(decode(C.數值14, 0, A.贈品數量, C.數值14)) 繳庫總袋數,
			sum(decode(A.Logical3,1,decode(C.數值14, 0, A.贈品數量, C.數值14),0)) 待重工總袋數,
			(sum(decode(A.Logical3,1,decode(A.贈品數量, decode(A.單據序號, D.序號/*末一筆*/, decode(C.Logical5, 0, B.數值17, B.數值19), E.序號/*末二筆*/, decode(D.Logical2/*雙膜*/, 0, A.贈品數量/*非雙膜數量全計*/, decode(C.Logical5, 0, B.數值17, B.數值19)), A.贈品數量/*非末一二筆數量全計*/), decode(C.數值14/*補尾數*/, 0, 1, 0), 0),0))+
			 sum(decode(A.Logical3,1,decode(C.數值14, 0, 0, 1),0)) +
			 sum(decode(A.Logical3,1,decode(A.單據序號, D.序號/*末一筆*/, decode(A.贈品數量, decode(C.Logical5, 0, B.數值17, B.數值19), 0, B.Logical4), E.序號/*末二筆*/, decode(D.Logical2/*雙膜*/, 0, 0, decode(A.贈品數量, decode(C.Logical5, 0, B.數值17, B.數值19), 0, B.Logical4)), 0),0))
			) 待重工總箱數,
			sum(C.數值19) A材退庫,
			sum(C.數值20) B材退庫,
			sum(C.數值21) 側邊退庫,
			sum(C.數值22) 底邊退庫
			/*
			B.數值17 紙箱_無氣閥_每箱幾袋
			B.數值19 紙箱_氣閥_每箱幾袋
			B.Logical4 結束
			B.Logical5 待補
			C.Logical5 氣閥
			C.數值14 補尾數
			D.Logical2 雙膜
			*/
		FROM 
			FIL0040 A
			INNER JOIN FIL0030 M ON A.單據類別 = M.單據類別 AND A.單據編號 = M.單據編號
			INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
			INNER JOIN FIL0041 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號 AND A.單據序號 = C.序號
			INNER JOIN ViewFIL2023 D ON A.單據類別 = D.單別 AND A.單據編號 = D.單號 AND D.類別 = 'A' AND D.DESC排序 = 1
			LEFT JOIN ViewFIL2023 E ON A.單據類別 = E.單別 AND A.單據編號 = E.單號 AND E.類別 = 'A' AND E.DESC排序 = 2
		WHERE
			A.單據類別 = 'C41' AND
			A.異動類別 = 'A' AND
			B.製程代碼 = 'C31E'
		GROUP BY
			A.單據類別, 
			A.單據編號
	) A
	INNER JOIN FIL0030 B ON B.單據類別 = A.單別 AND A.單號 = B.單據編號
	INNER JOIN FIL0031 C ON A.單別 = C.單別 AND A.單號 = C.單號
	INNER JOIN FIL0032 E ON E.製令單別 = B.歸屬類別 AND E.製令單號 = B.歸屬編號
	);

-- Oracle user_views
CREATE VIEW "VIEWFIL404EB" ("單別", "單號", "單據日期", "機台代碼", "機台名稱", "製令單別", "製令單號", "作業人員", "作業人員姓名", "作業人數", "繳庫總袋數", "繳庫總箱數", "報廢數", "不良剔除後成品率", "製袋速度", "產品編號", "產品名稱", "產品規格") AS (Select 
	A.單別,
	A.單號,
	C.單據日期,
	B.機台代碼,
	nvl(F.名稱, ' ') 機台名稱,
	C.歸屬類別 製令單別,
	C.歸屬編號 製令單號,	
	A.作業人員,
	A.作業人員姓名,
	A.作業人數,
	D.繳庫總袋數/A.作業人數 繳庫總袋數,
	D.繳庫總袋數_箱數/A.作業人數 繳庫總箱數,
	D.報廢數/A.作業人數 報廢數,
	D.不良剔除後成品率,
	B.數值1 製袋速度,
	E.產品編號,
	E.產品名稱,
	E.產品規格
FROM 	
(                                                                                                                                                      
SELECT
	A.單據類別 單別,
	A.單據編號 單號,
	to_char(nvl(A.業務員,' ')) 作業人員,
	to_char(nvl(E.員工姓名,' ')) 作業人員姓名, 
	decode(A.業務員,' ',0,1)+decode(B.文數字10,' ',0,1)+decode(B.文數字11,' ',0,1) 作業人數
FROM
	FIL0030 A
	INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
	LEFT JOIN FIL0010 E ON A.業務員 = E.員工編號
WHERE
	A.單據類別 = 'C41' AND
	B.製程代碼 = 'C31E' AND
	A.業務員 <> ' '
	
Union

SELECT
	A.單據類別 單別,
	A.單據編號 單號,
	to_char(nvl(B.文數字10,' ')) 作業人員,
	to_char(nvl(E.員工姓名,' ')) 作業人員姓名, 
	decode(A.業務員,' ',0,1)+decode(B.文數字10,' ',0,1)+decode(B.文數字11,' ',0,1) 作業人數
FROM
	FIL0030 A
	INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
	LEFT JOIN FIL0010 E ON B.文數字10 = E.員工編號
WHERE
	A.單據類別 = 'C41' AND
	B.製程代碼 = 'C31E' AND
	B.文數字10 <> ' '
	
Union
	
SELECT
	A.單據類別 單別,
	A.單據編號 單號,
	to_char(nvl(B.文數字11,' ')) 作業人員,
	to_char(nvl(E.員工姓名,' ')) 作業人員姓名, 
	decode(A.業務員,' ',0,1)+decode(B.文數字10,' ',0,1)+decode(B.文數字11,' ',0,1) 作業人數
FROM
	FIL0030 A
	INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
	LEFT JOIN FIL0010 E ON B.文數字11 = E.員工編號
WHERE
	A.單據類別 = 'C41' AND
	B.製程代碼 = 'C31E'	AND
	B.文數字11 <> ' '
	) A
INNER JOIN FIL0031 B ON A.單別 = B.單別 AND A.單號 = B.單號
INNER JOIN FIL0030 C ON A.單別=C.單據類別 AND A.單號=C.單據編號
INNER JOIN ViewFIL404EA D ON A.單別=D.單別 AND A.單號=D.單號
INNER JOIN ViewFIL4030 E ON C.歸屬類別 = E.製令單別 AND C.歸屬編號 = E.製令單號
LEFT JOIN ViewFIL310P F ON B.機台代碼 = F.代碼
);

-- Oracle user_views
CREATE VIEW "VIEWFIL404EC" ("單別", "單號", "作業日期", "製令單別", "製令單號", "機台代碼", "機台名稱", "客戶編號", "客戶名稱", "產品編號", "產品名稱", "產品規格", "開始時間", "結束時間", "委外", "作業人員", "作業人員姓名", "繳庫總袋數", "繳庫總袋數_箱數", "報廢數", "重整數", "報廢率", "不良剔除後成品率", "生產或調機") AS (
SELECT
	A.單據類別 單別,
	A.單據編號 單號,
	A.單據日期 作業日期,
	A.歸屬類別 製令單別,
	A.歸屬編號 製令單號,
	B.機台代碼,
	nvl(D.名稱, ' ') 機台名稱,
	F.客戶編號,
	F.客戶名稱,
	F.產品編號,
	F.產品名稱,
	F.產品規格,
	to_timestamp(A.單據日期||' '||case when B.時間一<'000000' or B.時間一>'235959' then '000000' else B.時間一 end, 'syyyymmdd hh24:mi:ss') 開始時間,
	to_timestamp(case when B.時間一>B.時間二 then to_char(to_date(A.單據日期,'yyyymmdd')+1,'yyyymmdd') else A.單據日期 end||' '||case when B.時間二<'000000' or B.時間二>'235959' then '000000' else B.時間二 end , 'syyyymmdd hh24:mi:ss') 結束時間,
	DECODE(nvl(D.委外, 0),0,'廠內','委外') 委外,
	A.業務員 作業人員,
	nvl(E.員工姓名,' ') 作業人員姓名,
	nvl(C.繳庫總袋數,0) 繳庫總袋數,
	nvl(C.繳庫總袋數_箱數,0) 繳庫總袋數_箱數,
	nvl(C.報廢數,0) 報廢數,
	nvl(C.重整數,0) 重整數,
	decode(nvl(C.繳庫總袋數,0)+nvl(C.報廢數,0),0,0,nvl(C.報廢數,0)/(nvl(C.繳庫總袋數,0)+nvl(C.報廢數,0))) 報廢率,
	nvl(C.不良剔除後成品率,0)/100 不良剔除後成品率,
	decode(B.Logical3,0,'生產','調機') 生產或調機
FROM
	FIL0030 A
	INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
	LEFT JOIN ViewFIL404EA C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號
	LEFT JOIN ViewFIL310P D ON B.機台代碼 = D.代碼
	LEFT JOIN FIL0010 E ON A.業務員 = E.員工編號
	INNER JOIN ViewFIL4030 F ON A.歸屬類別 = F.製令單別 AND A.歸屬編號 = F.製令單號
WHERE
	A.單據類別 = 'C41' AND
	B.製程代碼 = 'C31E');

-- Oracle user_views
CREATE VIEW "VIEWFIL404ED" ("單別", "單號", "序號", "數量", "開始時間", "結束時間", "開始秒數", "結束秒數", "上一筆秒數", "差異秒數") AS (
SELECT 
	A.單別,
	A.單號,
	A.序號,
	A.數量,
	B.開始時間,
	A.結束時間,
	to_number(substr(B.開始時間,1,2)*60*60)+to_number(substr(B.開始時間,3,2)*60)+to_number(substr(B.開始時間,5,2)) 開始秒數,
	to_number(substr(A.結束時間,1,2)*60*60)+to_number(substr(A.結束時間,3,2)*60)+to_number(substr(A.結束時間,5,2)) 結束秒數,
	DECODE(NVL(lag(to_number(substr(A.結束時間,1,2)*60*60)+to_number(substr(A.結束時間,3,2)*60)+to_number(substr(A.結束時間,5,2))) over (PARTITION BY A.單別,A.單號 order by A.單別,A.單號,A.序號),0)
	,0,to_number(substr(B.開始時間,1,2)*60*60)+to_number(substr(B.開始時間,3,2)*60)+to_number(substr(B.開始時間,5,2))
	,NVL(lag(to_number(substr(A.結束時間,1,2)*60*60)+to_number(substr(A.結束時間,3,2)*60)+to_number(substr(A.結束時間,5,2))) over (PARTITION BY A.單別,A.單號 order by A.單別,A.單號,A.序號),0))上一筆秒數,
	(to_number(substr(A.結束時間,1,2)*60*60)+to_number(substr(A.結束時間,3,2)*60)+to_number(substr(A.結束時間,5,2)))-(DECODE(NVL(lag(to_number(substr(A.結束時間,1,2)*60*60)+to_number(substr(A.結束時間,3,2)*60)+to_number(substr(A.結束時間,5,2))) over (PARTITION BY A.單別,A.單號 order by A.單別,A.單號,A.序號),0)
	,0,to_number(substr(B.開始時間,1,2)*60*60)+to_number(substr(B.開始時間,3,2)*60)+to_number(substr(B.開始時間,5,2))
	,NVL(lag(to_number(substr(A.結束時間,1,2)*60*60)+to_number(substr(A.結束時間,3,2)*60)+to_number(substr(A.結束時間,5,2))) over (PARTITION BY A.單別,A.單號 order by A.單別,A.單號,A.序號),0))) 差異秒數
FROM 
	ViewFIL404E2 A
	INNER JOIN ViewFIL404E1 B ON A.單別=B.單別 AND A.單號=B.單號
);

-- Oracle user_views
CREATE VIEW "VIEWFIL404EE" ("單號", "作業日期", "工作時數", "類別") AS (
SELECT
	A.單據編號 單號,
	A.單據日期 作業日期,
    (86400-(to_number(substr(B.時間一,1,2))*60*60+to_number(substr(B.時間一,3,2))*60+to_number(substr(B.時間一,5,6))))/3600 工作時數,
	'1' 類別
FROM
	FIL0030 A
	INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
WHERE
	A.單據類別 = 'C41' AND
	B.製程代碼 = 'C31E' AND
	B.時間一 > B.時間二

union

SELECT
	A.單據編號 單號,
	to_char(to_date(A.單據日期,'yyyymmdd')+1,'yyyymmdd') 作業日期,
    (to_number(substr(B.時間二,1,2))*60*60+to_number(substr(B.時間二,3,2))*60+to_number(substr(B.時間二,5,6)))/3600 工作時數,
	'2' 類別
FROM
	FIL0030 A
	INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
WHERE
	A.單據類別 = 'C41' AND
	B.製程代碼 = 'C31E' AND
	B.時間一 > B.時間二	

union

SELECT
	A.單據編號 單號,
	A.單據日期 作業日期,
    ((to_number(substr(B.時間二,1,2))*60*60+to_number(substr(B.時間二,3,2))*60+to_number(substr(B.時間二,5,6)))-(to_number(substr(B.時間一,1,2))*60*60+to_number(substr(B.時間一,3,2))*60+to_number(substr(B.時間一,5,6))))/3600 工作時數,
	'3' 類別
FROM
	FIL0030 A
	INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
WHERE
	A.單據類別 = 'C41' AND
	B.製程代碼 = 'C31E' AND
	B.時間一 < B.時間二		
);

-- Oracle user_views
CREATE VIEW "VIEWFIL404EF" ("單別", "單號", "作業人員", "作業人員姓名", "作業人數") AS (Select 
	A.單別,
	A.單號,
	A.作業人員,
	A.作業人員姓名,
	A.作業人數
FROM 	
(                                                                                                                                                      
SELECT
	A.單據類別 單別,
	A.單據編號 單號,
	to_char(nvl(A.業務員,' ')) 作業人員,
	to_char(nvl(E.員工姓名,' ')) 作業人員姓名, 
	decode(A.業務員,' ',0,1)+decode(B.文數字10,' ',0,1)+decode(B.文數字11,' ',0,1) 作業人數
FROM
	FIL0030 A
	INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
	LEFT JOIN FIL0010 E ON A.業務員 = E.員工編號
WHERE
	A.單據類別 = 'C41' AND
	B.製程代碼 = 'C31E' AND
	A.業務員 <> ' '
	
Union

SELECT
	A.單據類別 單別,
	A.單據編號 單號,
	to_char(nvl(B.文數字10,' ')) 作業人員,
	to_char(nvl(E.員工姓名,' ')) 作業人員姓名, 
	decode(A.業務員,' ',0,1)+decode(B.文數字10,' ',0,1)+decode(B.文數字11,' ',0,1) 作業人數
FROM
	FIL0030 A
	INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
	LEFT JOIN FIL0010 E ON B.文數字10 = E.員工編號
WHERE
	A.單據類別 = 'C41' AND
	B.製程代碼 = 'C31E' AND
	B.文數字10 <> ' '
	
Union
	
SELECT
	A.單據類別 單別,
	A.單據編號 單號,
	to_char(nvl(B.文數字11,' ')) 作業人員,
	to_char(nvl(E.員工姓名,' ')) 作業人員姓名, 
	decode(A.業務員,' ',0,1)+decode(B.文數字10,' ',0,1)+decode(B.文數字11,' ',0,1) 作業人數
FROM
	FIL0030 A
	INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
	LEFT JOIN FIL0010 E ON B.文數字11 = E.員工編號
WHERE
	A.單據類別 = 'C41' AND
	B.製程代碼 = 'C31E'	AND
	B.文數字11 <> ' '
	) A
);

-- Oracle user_views
CREATE VIEW "VIEWFIL404EG" ("單別", "單號", "筆數") AS (                                                                                                                                                   
SELECT
	A.單別 單別,
	A.單號 單號,
	count(A.序號) 筆數
FROM
	FIL0049 A
WHERE
	A.單別 = 'C41'
GROUP BY 
	A.單別,
	A.單號
);

-- Oracle user_views
CREATE VIEW "VIEWFIL404EH" ("作業日期", "實際工作時數", "作業人數") AS (                                                                                                                                                   
SELECT 
	A.作業日期,
	sum(B.差異秒數/3600) 實際工作時數,
	count(distinct A.作業人員) 作業人數
FROM
	ViewFIL404EC A
	inner join ViewFIL404ED B on B.單別=A.單別 and B.單號=A.單號 AND B.結束秒數>B.開始秒數
Group by 
	A.作業日期
);

-- Oracle user_views
CREATE VIEW "VIEWFIL404F1" ("單別", "單號", "作業日期", "製令單別", "製令單號", "公司代碼", "公司名稱", "訂單單別", "訂單單號", "機台代碼", "機台名稱", "委外", "單位主管流水編號", "本日件數順序", "主旨", "客戶編號", "客戶名稱", "產品編號", "產品名稱", "產品規格", "作業面", "開始時間", "生產時間", "吃飯時間", "支援時間", "結束時間", "收拾時間", "每束幾袋", "每箱幾袋", "下壓秒數", "左距邊", "右距邊", "簽核系統", "備註", "作業人員", "作業人員姓名", "確認碼", "簽核狀態", "流水編號", "填表人", "填表人姓名", "員工流水編號", "填表日", "最後更新者", "更新者姓名", "最後更新日") AS (                                                                                                                                                      SELECT
	A.單據類別 單別,
	A.單據編號 單號,
	A.單據日期 作業日期,
	A.歸屬類別 製令單別,
	A.歸屬編號 製令單號,
	C.公司代碼,
	C.公司名稱,
	C.訂單單別,
	C.訂單單號,
	B.機台代碼,
	nvl(D.名稱, ' ') 機台名稱,
	nvl(D.委外, 0) 委外,
	D.單位主管流水編號,
	B.交貨日期_天 本日件數順序,
	A.單據編號||'('||trim(A.單據類別)||')'||'/製令:'||nvl(A.歸屬編號, ' ')||'/'||C.產品名稱 主旨,
	C.客戶編號,
	C.客戶名稱,
	C.產品編號,
	C.產品名稱,
	C.產品規格,
	A.匯率類別 作業面,
	B.時間一 開始時間,
	B.時間二 生產時間,
	B.時間三 吃飯時間,
	B.時間四 支援時間,
	B.時間五 結束時間,
	B.時間六 收拾時間,
	B.數值1 每束幾袋,
	B.數值2 每箱幾袋,
	B.數值5 下壓秒數,
	A.稅率 左距邊,
	B.訂金 右距邊,
	A.簽核系統, 
	A.備註, 
	A.業務員 作業人員,
	nvl(E.員工姓名,' ') 作業人員姓名, 
	A.確認碼,
	nvl(Z3.簽核狀態, '0') 簽核狀態,
	A.流水編號,
	A.填表人,
	nvl(Z1.員工姓名,' ') 填表人姓名, 
	nvl(Z1.Serial_Num,' ') 員工流水編號, 
	A.填表日, 
	A.最後更新者,
	nvl(Z2.員工姓名,' ') 更新者姓名, 
	A.最後更新日
FROM
	FIL0030 A
	INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
	INNER JOIN ViewFIL4030 C ON A.歸屬類別 = C.製令單別 AND A.歸屬編號 = C.製令單號
	LEFT JOIN ViewFIL310P D ON B.機台代碼 = D.代碼
	LEFT JOIN FIL0010 E ON A.業務員 = E.員工編號
	LEFT JOIN FIL0010 Z1 ON A.填表人 = Z1.員工編號
	LEFT JOIN FIL0010 Z2 ON A.最後更新者 = Z2.員工編號
	LEFT JOIN ViewOfObjProperties Z3 ON A.流水編號 = Z3.單據流水號
WHERE
	A.單據類別 = 'C41' AND
	B.製程代碼 = 'C31F');

-- Oracle user_views
CREATE VIEW "VIEWFIL404F2" ("單別", "單號", "序號", "批號1", "批號2", "數量1", "數量2", "日期", "箱號", "繳庫袋數", "位置是否正確", "下壓間隙", "溫度", "壓力", "牢固完整度", "單位代碼", "單位名稱", "庫別代碼", "庫別名稱", "半成品編號", "每箱結束時間", "紙袋報廢數", "成品庫存數", "庫存數1", "庫存數2", "建檔時的庫存1", "建檔時的庫存2", "備註說明", "結案碼", "流水編號", "最後更新者", "更新者姓名", "最後更新日") AS (                                                                                                                                                      SELECT 
	A.單據類別 單別, 
	A.單據編號 單號,
	A.單據序號 序號,
	B.文數字1 批號1,
	B.文數字2 批號2,
	B.數值1 數量1,
	B.數值2 數量2,
	A.異動日期 日期,
	A.異動數量 箱號,
	A.贈品數量 繳庫袋數,
	B.Logical1 位置是否正確,
	B.Logical2 下壓間隙,
	B.數值3 溫度,
	B.數值4 壓力,
	B.Logical3 牢固完整度,
	A.單位代碼,
	nvl(D.名稱, ' ') 單位名稱,
	A.倉庫代碼 庫別代碼,
	nvl(E.名稱, ' ') 庫別名稱,
	A.文數字1 半成品編號,
	A.TIME1 每箱結束時間,
	B.數值5 紙袋報廢數,
	B.數值6 成品庫存數,
	B.數值7 庫存數1,
	B.數值8 庫存數2,
	B.數值9 建檔時的庫存1,
	B.數值10 建檔時的庫存2,
	A.備註說明,
	A.結案碼,
	A.流水編號,
	A.最後更新者,
	nvl(Z1.員工姓名,' ') 更新者姓名,
	A.最後更新日
FROM 
	FIL0040 A
	INNER JOIN FIL0041 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號 AND A.單據序號 = B.序號
	INNER JOIN FIL0031 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號
	LEFT JOIN ViewFIL3103 D ON A.單位代碼 = D.代碼
	LEFT JOIN ViewFIL3106 E ON A.倉庫代碼 = E.代碼
	LEFT JOIN FIL0010 Z1 ON A.最後更新者 = Z1.員工編號
WHERE
	A.單據類別 = 'C41' AND
	A.異動類別 = 'A' AND
	C.製程代碼 = 'C31F');

-- Oracle user_views
CREATE VIEW "VIEWFIL404F3" ("製令單別", "製令單號", "箱號", "繳庫袋數", "重量", "每袋重量") AS (                                                                                                                                                      
SELECT 
	C.歸屬類別 製令單別,
	C.歸屬編號 製令單號,
	A.異動數量 箱號,
	A.贈品數量 繳庫袋數,	
	B.數值1*NVL(E.單價下限率/1000,0)+B.數值2*NVL(G.單價下限率/1000,0) 重量,
	decode(A.贈品數量,0,0,(B.數值1*NVL(E.單價下限率/1000,0)+B.數值2*NVL(G.單價下限率/1000,0))/A.贈品數量) 每袋重量
FROM 
	FIL0040 A
	INNER JOIN FIL0041 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號 AND A.單據序號 = B.序號
	INNER JOIN FIL0030 C ON A.單據類別 = C.單據類別 AND A.單據編號 = C.單據編號
	INNER JOIN FIL0031 C1 ON A.單據類別 = C1.單別 AND A.單據編號 = C1.單號
	LEFT JOIN ViewFIL1024 D ON B.文數字1 = D.條碼
	LEFT JOIN FIL0012 E ON D.料號 = E.產品編號
	LEFT JOIN ViewFIL1024 F ON B.文數字2 = F.條碼
	LEFT JOIN FIL0012 G ON F.料號 = G.產品編號
WHERE
	A.單據類別 = 'C41' AND
	A.異動類別 = 'A' AND
	C1.製程代碼 = 'C31F');

-- Oracle user_views
CREATE VIEW "VIEWFIL404F4" ("單別", "單號", "報廢數量") AS (                                                                                                                                                      SELECT 
	A.單據類別 單別, 
	A.單據編號 單號,
	sum(A.異動數量) 報廢數量
FROM 
	FIL0040 A
	INNER JOIN FIL0031 C1 ON A.單據類別 = C1.單別 AND A.單據編號 = C1.單號
WHERE
	A.單據類別 = 'C41' AND
	A.異動類別 = 'A' AND
	C1.製程代碼 = 'C31F'
GROUP BY
	A.單據類別, 
	A.單據編號);

-- Oracle user_views
CREATE VIEW "VIEWFIL404FA" ("單別", "單號", "繳庫袋數", "繳庫袋數_箱數", "繳庫總袋數", "繳庫總袋數_箱數", "尾數成品", "尾數成品_箱數", "每箱幾袋", "序號") AS (                                                                                                                                                      SELECT 
	A.單據類別 單別, 
	A.單據編號 單號,
	sum(A.贈品數量 - decode(A.贈品數量, B.數值2, 0, A.贈品數量)) 繳庫袋數,
	count(A.單據序號) - sum(decode(A.贈品數量, B.數值2, 0, 1)) 繳庫袋數_箱數,
	sum(A.贈品數量) 繳庫總袋數,
	count(A.單據序號) 繳庫總袋數_箱數,
	sum(decode(A.贈品數量, B.數值2, 0, A.贈品數量)) 尾數成品,
	sum(decode(A.贈品數量, B.數值2, 0, 1)) 尾數成品_箱數,
	max(B.數值2) 每箱幾袋,
	max(A.單據序號) 序號
FROM 
	FIL0040 A
	INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
WHERE
	A.單據類別 = 'C41' AND
	A.異動類別 = 'A' AND
	B.製程代碼 = 'C31F'
GROUP BY
	A.單據類別, 
	A.單據編號
);

-- Oracle user_views
CREATE VIEW "VIEWFIL404FB" ("單別", "單號", "作業日期", "製令單別", "製令單號", "機台代碼", "機台名稱", "客戶編號", "客戶名稱", "產品編號", "產品名稱", "產品規格", "開始時間", "結束時間", "委外", "作業人員", "作業人員姓名", "繳庫總袋數", "繳庫總袋數_箱數") AS (                                                                                                                                                      SELECT
	A.單據類別 單別,
	A.單據編號 單號,
	A.單據日期 作業日期,
	A.歸屬類別 製令單別,
	A.歸屬編號 製令單號,
	B.機台代碼,
	nvl(D.名稱, ' ') 機台名稱,
	F.客戶編號,
	F.客戶名稱,
	F.產品編號,
	F.產品名稱,
	F.產品規格,
	to_timestamp(A.單據日期||' '||case when B.時間一<'000000' or B.時間一>'235959' then '000000' else B.時間一 end, 'syyyymmdd hh24:mi:ss') 開始時間,
	to_timestamp(case when B.時間一>B.時間二 then to_char(to_date(A.單據日期,'yyyymmdd')+1,'yyyymmdd') else A.單據日期 end||' '||case when B.時間二<'000000' or B.時間二>'235959' then '000000' else B.時間二 end , 'syyyymmdd hh24:mi:ss') 結束時間,
	DECODE(nvl(D.委外, 0),0,'廠內','委外') 委外,
	A.業務員 作業人員,
	nvl(E.員工姓名,' ') 作業人員姓名,
	C.繳庫總袋數,
	C.繳庫總袋數_箱數
FROM
	FIL0030 A
	INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
	INNER JOIN ViewFIL404FA C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號
	LEFT JOIN ViewFIL310P D ON B.機台代碼 = D.代碼
	LEFT JOIN FIL0010 E ON A.業務員 = E.員工編號
	INNER JOIN ViewFIL4030 F ON A.歸屬類別 = F.製令單別 AND A.歸屬編號 = F.製令單號
WHERE
	A.單據類別 = 'C41' AND
	B.製程代碼 = 'C31F');

-- Oracle user_views
CREATE VIEW "VIEWFIL404FC" ("單別", "單號", "序號", "繳庫袋數", "開始時間", "每箱結束時間", "開始秒數", "結束秒數", "上一筆秒數", "差異秒數") AS (
SELECT 
	A.單別,
	A.單號,
	A.序號,
	A.繳庫袋數,
	B.開始時間,
	A.每箱結束時間,
	to_number(substr(B.開始時間,1,2)*60*60)+to_number(substr(B.開始時間,3,2)*60)+to_number(substr(B.開始時間,5,2)) 開始秒數,
	to_number(substr(A.每箱結束時間,1,2)*60*60)+to_number(substr(A.每箱結束時間,3,2)*60)+to_number(substr(A.每箱結束時間,5,2)) 結束秒數,
	DECODE(NVL(lag(to_number(substr(A.每箱結束時間,1,2)*60*60)+to_number(substr(A.每箱結束時間,3,2)*60)+to_number(substr(A.每箱結束時間,5,2))) over (PARTITION BY A.單別,A.單號 order by A.單別,A.單號,A.序號),0)
	,0,to_number(substr(B.開始時間,1,2)*60*60)+to_number(substr(B.開始時間,3,2)*60)+to_number(substr(B.開始時間,5,2))
	,NVL(lag(to_number(substr(A.每箱結束時間,1,2)*60*60)+to_number(substr(A.每箱結束時間,3,2)*60)+to_number(substr(A.每箱結束時間,5,2))) over (PARTITION BY A.單別,A.單號 order by A.單別,A.單號,A.序號),0))上一筆秒數,
	(to_number(substr(A.每箱結束時間,1,2)*60*60)+to_number(substr(A.每箱結束時間,3,2)*60)+to_number(substr(A.每箱結束時間,5,2)))-(DECODE(NVL(lag(to_number(substr(A.每箱結束時間,1,2)*60*60)+to_number(substr(A.每箱結束時間,3,2)*60)+to_number(substr(A.每箱結束時間,5,2))) over (PARTITION BY A.單別,A.單號 order by A.單別,A.單號,A.序號),0)
	,0,to_number(substr(B.開始時間,1,2)*60*60)+to_number(substr(B.開始時間,3,2)*60)+to_number(substr(B.開始時間,5,2))
	,NVL(lag(to_number(substr(A.每箱結束時間,1,2)*60*60)+to_number(substr(A.每箱結束時間,3,2)*60)+to_number(substr(A.每箱結束時間,5,2))) over (PARTITION BY A.單別,A.單號 order by A.單別,A.單號,A.序號),0))) 差異秒數
FROM 
	ViewFIL404F2 A
	INNER JOIN ViewFIL404F1 B ON A.單別=B.單別 AND A.單號=B.單號
);

-- Oracle user_views
CREATE VIEW "VIEWFIL404FD" ("單別", "單號", "作業日期", "製令單別", "製令單號", "機台代碼", "機台名稱", "委外", "客戶編號", "客戶名稱", "產品編號", "產品名稱", "產品規格", "作業人員", "作業人員姓名", "報廢數量", "繳庫總袋數", "報廢率") AS (                                                                                                                                                      SELECT
	A.單據類別 單別,
	A.單據編號 單號,
	A.單據日期 作業日期,
	A.歸屬類別 製令單別,
	A.歸屬編號 製令單號,
	B.機台代碼,
	nvl(D.名稱, ' ') 機台名稱,
	nvl(D.委外, 0) 委外,
	C.客戶編號,
	C.客戶名稱,
	C.產品編號,
	C.產品名稱,
	C.產品規格,
	A.業務員 作業人員,
	nvl(E.員工姓名,' ') 作業人員姓名, 
	nvl(G.報廢數量,0) 報廢數量,
	nvl(F.繳庫總袋數,0) 繳庫總袋數,
	decode(nvl(F.繳庫總袋數,0),0,0,nvl(G.報廢數量,0)/nvl(F.繳庫總袋數,0))*100 報廢率
FROM
	FIL0030 A
	INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
	INNER JOIN ViewFIL4030 C ON A.歸屬類別 = C.製令單別 AND A.歸屬編號 = C.製令單號
	LEFT JOIN ViewFIL310P D ON B.機台代碼 = D.代碼
	LEFT JOIN FIL0010 E ON A.業務員 = E.員工編號
	LEFT JOIN 
	(SELECT 
		A.單據類別 單別, 
		A.單據編號 單號,
		sum(A.贈品數量) 繳庫總袋數
	FROM 
		FIL0040 A
		INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
	WHERE
		A.單據類別 = 'C41' AND
		A.異動類別 = 'A' AND
		B.製程代碼 = 'C31F'
	GROUP BY
		A.單據類別, 
		A.單據編號
	) F ON F.單別=A.單據類別 AND F.單號=A.單據編號
	LEFT JOIN 
	(SELECT 
		A.單據類別, 
		A.單據編號,
		sum(A.異動數量) 報廢數量
	 FROM 
		FIL0040 A
		INNER JOIN FIL0031 C1 ON A.單據類別 = C1.單別 AND A.單據編號 = C1.單號
	WHERE
		A.單據類別 = 'C41' AND
		A.異動類別 = 'D' AND
		C1.製程代碼 = 'C31F'
	GROUP BY
		A.單據類別, 
		A.單據編號) G ON G.單據類別=A.單據類別 AND G.單據編號=A.單據編號
WHERE
	A.單據類別 = 'C41' AND
	B.製程代碼 = 'C31F');

-- Oracle user_views
CREATE VIEW "VIEWFIL404FE" ("單別", "單號", "彙總") AS (
SELECT 
	A.單別, 
	A.單號,
	listagg(trim(to_char(A.繳庫箱數,'999'))||'箱 X '||trim(to_char(A.繳庫袋數,'99999'))||'袋',',') within group (order by A.序號 DESC) as 彙總
FROM 
	(SELECT 
		A.單據類別 單別, 
		A.單據編號 單號,
		A.贈品數量 繳庫袋數,
		MIN(A.單據序號) 序號,
		count(A.單據序號) 繳庫箱數
	FROM 
		FIL0040 A
		INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
	WHERE
		A.單據類別 = 'C41' AND
		A.異動類別 = 'A' AND
		B.製程代碼 = 'C31F'
	GROUP BY
		A.單據類別, 
		A.單據編號,
		A.贈品數量)A
GROUP BY 
	A.單別, 
	A.單號);

-- Oracle user_views
CREATE VIEW "VIEWFIL404F_G" ("單別", "單號", "序號", "作業日期", "製令單別", "製令單號", "作業人員", "每箱結束時間", "計件日時", "製程代碼", "繳庫袋數") AS (                                                                                                                                                      SELECT 
	A.單據類別 單別, 
	A.單據編號 單號,
	A.單據序號 序號,
	C.單據日期 作業日期,
	C.歸屬類別 製令單別,
	C.歸屬編號 製令單號,	
	C.業務員 作業人員,	
	A.TIME1 每箱結束時間,
	case when A.TIME1 >= B.時間一 then C.單據日期 else to_char(to_date(C.單據日期,'yyyymmdd')+1,'yyyymmdd') end ||A.TIME1 計件日時,
	B.製程代碼,
	A.贈品數量 繳庫袋數
FROM 
	FIL0040 A
	INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
	INNER JOIN FIL0030 C ON A.單據類別 = C.單據類別 AND A.單據編號 = C.單據編號
WHERE
	A.單據類別 = 'C41' AND
	A.異動類別 = 'A' AND
	(B.製程代碼 = 'C31F' OR B.製程代碼 = 'C31G')
	);

-- Oracle user_views
CREATE VIEW "VIEWFIL404G1" ("單別", "單號", "作業日期", "製令單別", "製令單號", "公司代碼", "公司名稱", "訂單單別", "訂單單號", "機台代碼", "機台名稱", "委外", "單位主管流水編號", "本日件數順序", "主旨", "客戶編號", "客戶名稱", "產品編號", "產品名稱", "產品規格", "作業面", "開始時間", "結束時間", "每束幾袋", "每箱幾袋", "下壓秒數", "出袋距離_左", "出袋距離_右", "簽核系統", "備註", "作業人員", "作業人員姓名", "確認碼", "簽核狀態", "流水編號", "填表人", "填表人姓名", "員工流水編號", "填表日", "最後更新者", "更新者姓名", "最後更新日") AS (                                                                                                                                                      SELECT
	A.單據類別 單別,
	A.單據編號 單號,
	A.單據日期 作業日期,
	A.歸屬類別 製令單別,
	A.歸屬編號 製令單號,
	C.公司代碼,
	C.公司名稱,
	C.訂單單別,
	C.訂單單號,
	B.機台代碼,
	nvl(D.名稱, ' ') 機台名稱,
	nvl(D.委外, 0) 委外,
	D.單位主管流水編號,
	B.交貨日期_天 本日件數順序,
	A.單據編號||'('||trim(A.單據類別)||')'||'/製令:'||nvl(A.歸屬編號, ' ')||'/'||C.產品名稱 主旨,
	C.客戶編號,
	C.客戶名稱,
	C.產品編號,
	C.產品名稱,
	C.產品規格,
	A.匯率類別 作業面,
	B.時間一 開始時間,
	B.時間五 結束時間,
	B.數值1 每束幾袋,
	B.數值2 每箱幾袋,
	B.數值5 下壓秒數,
	A.稅率 出袋距離_左,
	B.訂金 出袋距離_右,
	A.簽核系統, 
	A.備註, 
	A.業務員 作業人員,
	nvl(E.員工姓名,' ') 作業人員姓名, 
	A.確認碼,
	nvl(Z3.簽核狀態, '0') 簽核狀態,
	A.流水編號,
	A.填表人,
	nvl(Z1.員工姓名,' ') 填表人姓名, 
	nvl(Z1.Serial_Num,' ') 員工流水編號, 
	A.填表日, 
	A.最後更新者,
	nvl(Z2.員工姓名,' ') 更新者姓名, 
	A.最後更新日
FROM
	FIL0030 A
	INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
	INNER JOIN ViewFIL4030 C ON A.歸屬類別 = C.製令單別 AND A.歸屬編號 = C.製令單號
	LEFT JOIN ViewFIL310P D ON B.機台代碼 = D.代碼
	LEFT JOIN FIL0010 E ON A.業務員 = E.員工編號
	LEFT JOIN FIL0010 Z1 ON A.填表人 = Z1.員工編號
	LEFT JOIN FIL0010 Z2 ON A.最後更新者 = Z2.員工編號
	LEFT JOIN ViewOfObjProperties Z3 ON A.流水編號 = Z3.單據流水號
WHERE
	A.單據類別 = 'C41' AND
	B.製程代碼 = 'C31G');

-- Oracle user_views
CREATE VIEW "VIEWFIL404G2" ("單別", "單號", "序號", "批號1", "批號2", "數量1", "數量2", "日期", "箱號", "繳庫袋數", "位置是否正確", "溫度", "壓力", "牢固完整度", "單位代碼", "單位名稱", "庫別代碼", "庫別名稱", "半成品編號", "每箱結束時間", "紙袋報廢數", "成品庫存數", "庫存數1", "庫存數2", "建檔時的庫存1", "建檔時的庫存2", "備註說明", "結案碼", "流水編號", "最後更新者", "更新者姓名", "最後更新日") AS (                                                                                                                                                      SELECT 
	A.單據類別 單別, 
	A.單據編號 單號,
	A.單據序號 序號,
	B.文數字1 批號1,
	B.文數字2 批號2,
	B.數值1 數量1,
	B.數值2 數量2,
	A.異動日期 日期,
	A.異動數量 箱號,
	A.贈品數量 繳庫袋數,
	B.Logical1 位置是否正確,
	B.數值3 溫度,
	B.數值4 壓力,
	B.Logical3 牢固完整度,
	A.單位代碼,
	nvl(D.名稱, ' ') 單位名稱,
	A.倉庫代碼 庫別代碼,
	nvl(E.名稱, ' ') 庫別名稱,
	A.文數字1 半成品編號,
	A.TIME1 每箱結束時間,
	B.數值5 紙袋報廢數,
	B.數值6 成品庫存數,
	B.數值7 庫存數1,
	B.數值8 庫存數2,
	B.數值9 建檔時的庫存1,
	B.數值10 建檔時的庫存2,
	A.備註說明,
	A.結案碼,
	A.流水編號,
	A.最後更新者,
	nvl(Z1.員工姓名,' ') 更新者姓名,
	A.最後更新日
FROM 
	FIL0040 A
	INNER JOIN FIL0041 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號 AND A.單據序號 = B.序號
	INNER JOIN FIL0031 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號
	LEFT JOIN ViewFIL3103 D ON A.單位代碼 = D.代碼
	LEFT JOIN ViewFIL3106 E ON A.倉庫代碼 = E.代碼
	LEFT JOIN FIL0010 Z1 ON A.最後更新者 = Z1.員工編號
WHERE
	A.單據類別 = 'C41' AND
	A.異動類別 = 'A' AND
	C.製程代碼 = 'C31G');

-- Oracle user_views
CREATE VIEW "VIEWFIL404G3" ("製令單別", "製令單號", "箱號", "繳庫袋數", "重量", "每袋重量") AS (                                                                                                                                                      
SELECT 
	C.歸屬類別 製令單別,
	C.歸屬編號 製令單號,
	A.異動數量 箱號,
	SUM(A.贈品數量) 繳庫袋數,	
	SUM(B.數值1*NVL(E.單價下限率/1000,0)+B.數值2*NVL(G.單價下限率/1000,0)) 重量,
	DECODE(SUM(A.贈品數量),0,0,SUM(B.數值1*NVL(E.單價下限率/1000,0)+B.數值2*NVL(G.單價下限率/1000,0))/SUM(A.贈品數量)) 每袋重量
FROM 
	FIL0040 A
	INNER JOIN FIL0041 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號 AND A.單據序號 = B.序號
	INNER JOIN FIL0030 C ON A.單據類別 = C.單據類別 AND A.單據編號 = C.單據編號
	INNER JOIN FIL0031 C1 ON A.單據類別 = C1.單別 AND A.單據編號 = C1.單號
	LEFT JOIN ViewFIL1024 D ON B.文數字1 = D.條碼
	LEFT JOIN FIL0012 E ON D.料號 = E.產品編號
	LEFT JOIN ViewFIL1024 F ON B.文數字2 = F.條碼
	LEFT JOIN FIL0012 G ON F.料號 = G.產品編號
WHERE
	A.單據類別 = 'C41' AND
	A.異動類別 = 'A' AND
	C1.製程代碼 = 'C31G'
GROUP BY 
	C.歸屬類別,
	C.歸屬編號,
	A.異動數量);

-- Oracle user_views
CREATE VIEW "VIEWFIL404GA" ("單別", "單號", "繳庫袋數", "繳庫袋數_箱數", "繳庫總袋數", "繳庫總袋數_箱數", "尾數成品", "尾數成品_箱數", "每箱幾袋", "序號") AS (
SELECT 
	A.單據類別 單別, 
	A.單據編號 單號,
	sum(A.贈品數量 - decode(A.贈品數量, B.數值2, 0, A.贈品數量)) 繳庫袋數,
	count(A.單據序號) - sum(decode(A.贈品數量, B.數值2, 0, 1)) 繳庫袋數_箱數,
	sum(A.贈品數量) 繳庫總袋數,
	count(A.單據序號) 繳庫總袋數_箱數,
	sum(decode(A.贈品數量, B.數值2, 0, A.贈品數量)) 尾數成品,
	sum(decode(A.贈品數量, B.數值2, 0, 1)) 尾數成品_箱數,
	max(B.數值2) 每箱幾袋,
	max(A.單據序號) 序號
FROM 
	FIL0040 A
	INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
WHERE
	A.單據類別 = 'C41' AND
	A.異動類別 = 'A' AND
	B.製程代碼 = 'C31G'
GROUP BY
	A.單據類別, 
	A.單據編號
	);

-- Oracle user_views
CREATE VIEW "VIEWFIL404GB" ("單別", "單號", "作業日期", "製令單別", "製令單號", "機台代碼", "機台名稱", "客戶編號", "客戶名稱", "產品編號", "產品名稱", "產品規格", "開始時間", "結束時間", "委外", "作業人員", "作業人員姓名", "繳庫總袋數", "繳庫總袋數_箱數") AS (                                                                                                                                                      SELECT
	A.單據類別 單別,
	A.單據編號 單號,
	A.單據日期 作業日期,
	A.歸屬類別 製令單別,
	A.歸屬編號 製令單號,
	B.機台代碼,
	nvl(D.名稱, ' ') 機台名稱,
	F.客戶編號,
	F.客戶名稱,
	F.產品編號,
	F.產品名稱,
	F.產品規格,
	to_timestamp(A.單據日期||' '||case when B.時間一<'000000' or B.時間一>'235959' then '000000' else B.時間一 end, 'syyyymmdd hh24:mi:ss') 開始時間,
	to_timestamp(case when B.時間一>B.時間二 then to_char(to_date(A.單據日期,'yyyymmdd')+1,'yyyymmdd') else A.單據日期 end||' '||case when B.時間二<'000000' or B.時間二>'235959' then '000000' else B.時間二 end , 'syyyymmdd hh24:mi:ss') 結束時間,
	DECODE(nvl(D.委外, 0),0,'廠內','委外') 委外,
	A.業務員 作業人員,
	nvl(E.員工姓名,' ') 作業人員姓名,
	C.繳庫總袋數,
	C.繳庫總袋數_箱數
FROM
	FIL0030 A
	INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
	INNER JOIN ViewFIL404GA C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號
	LEFT JOIN ViewFIL310P D ON B.機台代碼 = D.代碼
	LEFT JOIN FIL0010 E ON A.業務員 = E.員工編號
	INNER JOIN ViewFIL4030 F ON A.歸屬類別 = F.製令單別 AND A.歸屬編號 = F.製令單號
WHERE
	A.單據類別 = 'C41' AND
	B.製程代碼 = 'C31G');

-- Oracle user_views
CREATE VIEW "VIEWFIL404GC" ("單別", "單號", "序號", "繳庫袋數", "開始時間", "每箱結束時間", "開始秒數", "結束秒數", "上一筆秒數", "差異秒數") AS (
SELECT 
	A.單別,
	A.單號,
	A.序號,A.繳庫袋數,
	B.開始時間,
	A.每箱結束時間,
	to_number(substr(B.開始時間,1,2)*60*60)+to_number(substr(B.開始時間,3,2)*60)+to_number(substr(B.開始時間,5,2)) 開始秒數,
	to_number(substr(A.每箱結束時間,1,2)*60*60)+to_number(substr(A.每箱結束時間,3,2)*60)+to_number(substr(A.每箱結束時間,5,2)) 結束秒數,
	DECODE(NVL(lag(to_number(substr(A.每箱結束時間,1,2)*60*60)+to_number(substr(A.每箱結束時間,3,2)*60)+to_number(substr(A.每箱結束時間,5,2))) over (PARTITION BY A.單別,A.單號 order by A.單別,A.單號,A.序號),0)
	,0,to_number(substr(B.開始時間,1,2)*60*60)+to_number(substr(B.開始時間,3,2)*60)+to_number(substr(B.開始時間,5,2))
	,NVL(lag(to_number(substr(A.每箱結束時間,1,2)*60*60)+to_number(substr(A.每箱結束時間,3,2)*60)+to_number(substr(A.每箱結束時間,5,2))) over (PARTITION BY A.單別,A.單號 order by A.單別,A.單號,A.序號),0))上一筆秒數,
	(to_number(substr(A.每箱結束時間,1,2)*60*60)+to_number(substr(A.每箱結束時間,3,2)*60)+to_number(substr(A.每箱結束時間,5,2)))-(DECODE(NVL(lag(to_number(substr(A.每箱結束時間,1,2)*60*60)+to_number(substr(A.每箱結束時間,3,2)*60)+to_number(substr(A.每箱結束時間,5,2))) over (PARTITION BY A.單別,A.單號 order by A.單別,A.單號,A.序號),0)
	,0,to_number(substr(B.開始時間,1,2)*60*60)+to_number(substr(B.開始時間,3,2)*60)+to_number(substr(B.開始時間,5,2))
	,NVL(lag(to_number(substr(A.每箱結束時間,1,2)*60*60)+to_number(substr(A.每箱結束時間,3,2)*60)+to_number(substr(A.每箱結束時間,5,2))) over (PARTITION BY A.單別,A.單號 order by A.單別,A.單號,A.序號),0))) 差異秒數
FROM 
	ViewFIL404G2 A
	INNER JOIN ViewFIL404G1 B ON A.單別=B.單別 AND A.單號=B.單號
);

-- Oracle user_views
CREATE VIEW "VIEWFIL404GE" ("單別", "單號", "彙總") AS (
SELECT 
	A.單別, 
	A.單號,
	listagg(trim(to_char(A.繳庫箱數,'999'))||'箱 X '||trim(to_char(A.繳庫袋數,'99999'))||'袋',',') within group (order by A.序號 DESC) as 彙總
FROM 
	(SELECT 
		A.單據類別 單別, 
		A.單據編號 單號,
		A.贈品數量 繳庫袋數,
		MIN(A.單據序號) 序號,
		count(A.單據序號) 繳庫箱數
	FROM 
		FIL0040 A
		INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
	WHERE
		A.單據類別 = 'C41' AND
		A.異動類別 = 'A' AND
		B.製程代碼 = 'C31G'
	GROUP BY
		A.單據類別, 
		A.單據編號,
		A.贈品數量)A
GROUP BY 
	A.單別, 
	A.單號);

-- Oracle user_views
CREATE VIEW "VIEWFIL404H1" ("單別", "單號", "作業日期", "公司代碼", "公司名稱", "機台代碼", "機台名稱", "備註", "作業人員", "作業人員姓名", "確認碼", "標籤機代碼", "簽核系統", "簽核狀態", "主旨", "單位主管流水編號", "員工流水編號", "流水編號", "填表人", "填表人姓名", "填表日", "最後更新者", "更新者姓名", "最後更新日", "起始時間", "結束時間", "總耗時", "改件調整") AS (                                                                                                                                                      SELECT
	A.單據類別 單別,
	A.單據編號 單號,
	A.單據日期 作業日期,
	A.公司代碼,
	nvl(E.名稱, ' ') 公司名稱,
	B.機台代碼,
	nvl(D.名稱, ' ') 機台名稱,
	A.備註, 
	A.業務員 作業人員,
	nvl(C.員工姓名,' ') 作業人員姓名, 	
	A.確認碼,
	B.貿易條件 標籤機代碼,
	A.簽核系統, 
	nvl(Z3.簽核狀態, '0') 簽核狀態,
	A.單據編號||'('||trim(A.單據類別)||')' 主旨,
	D.單位主管流水編號,
	nvl(Z1.Serial_Num,' ') 員工流水編號, 
	A.流水編號,
	A.填表人,
	nvl(Z1.員工姓名,' ') 填表人姓名, 
	A.填表日, 
	A.最後更新者,
	nvl(Z2.員工姓名,' ') 更新者姓名, 
	A.最後更新日,
	B.時間一 起始時間,
	B.時間五 結束時間,
	decode(B.時間五,'000000',0,(to_date(to_char(case when B.時間五>B.時間一 then to_date(A.單據日期,'yyyymmdd') else to_date(A.單據日期,'yyyymmdd')+1 end,'yyyymmdd')||B.時間五,'yyyymmddhh24miss')- 
	to_date(trim(A.單據日期)||B.時間一,'yyyymmddhh24miss'))*24) 總耗時,
	B.LOGICAL6 改件調整
FROM
	FIL0030 A
	/*特殊欄位*/
	INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
	/* */
	LEFT JOIN FIL0010 C ON A.業務員 = C.員工編號
	LEFT JOIN ViewFIL310P D ON B.機台代碼 = D.代碼
	LEFT JOIN ViewFIL0011 E ON A.公司代碼 = E.代碼
	LEFT JOIN FIL0010 Z1 ON A.填表人 = Z1.員工編號
	LEFT JOIN FIL0010 Z2 ON A.最後更新者 = Z2.員工編號
	LEFT JOIN ViewOfObjProperties Z3 ON A.流水編號 = Z3.單據流水號
WHERE
	A.單據類別 = 'C41' AND
	B.製程代碼 = 'C31H');

-- Oracle user_views
CREATE VIEW "VIEWFIL404H2" ("單別", "單號", "序號", "日期", "開始時間", "結束時間", "製令單別", "製令單號", "加工別", "公司代碼", "公司名稱", "訂單單別", "訂單單號", "客戶編號", "客戶名稱", "產品編號", "產品名稱", "產品規格", "前製程編號", "前製程米數", "檢品編號", "檢品米數", "庫存米數", "合併編號", "合併米數", "印刷色數", "機台選擇", "機台名稱", "機台名稱串", "是否符合", "字圖清晰度", "接頭數量", "線外不良剔除", "線內不良剔除", "不良剔除米數", "合理剔除數", "標籤列印次數二", "前製程條碼", "備註說明", "流水編號", "最後更新者", "更新者姓名", "最後更新日", "PLC抓取日期", "PLC抓取時間") AS (                                                                                                                                                      SELECT 
	A.單據類別 單別, 
	A.單據編號 單號,
	A.單據序號 序號,
	M.單據日期 日期,
	C.TIME1 開始時間,
	C.TIME2 結束時間,
	A.前置單別 製令單別,
	A.前置單號 製令單號,
	C.小單位 加工別,
	D.公司代碼,
	D.公司名稱,
	D.訂單單別,
	D.訂單單號,
	D.客戶編號,
	D.客戶名稱,
	D.產品編號,
	D.產品名稱,
	D.產品規格,
	A.前製程編號,
	A.異動數量 前製程米數,
	A.產品編號 檢品編號,
	A.贈品數量 檢品米數,
	(A.異動單價 - 夾鏈費) 庫存米數,
	A.合併編號,
	A.異動單價 合併米數,
	A.異動金額 印刷色數,
	C.包裝單位 機台選擇,
	decode(C.包裝單位,'A','十色','B','七色','C','六色','D','積層','E','淋膜','選擇') 機台名稱,
	replace('□十色 □七色 □六色 □積層 □淋膜', trim('□' || decode(C.包裝單位,'A','十色','B','七色','C','六色','D','積層','E','淋膜','選擇')), trim('■' || decode(C.包裝單位,'A','十色','B','七色','C','六色','D','積層','E','淋膜','選擇')))  機台名稱串,
	A.Logical1 是否符合,
	A.結案碼 字圖清晰度,
	A.折扣率 接頭數量,
	A.雷射費 線外不良剔除,
	A.夾鏈費 線內不良剔除,
	A.毛重 不良剔除米數,
	A.燙金費 合理剔除數,
	C.標籤列印次數二,
	C.文數字4 前製程條碼,
	A.備註說明,
	A.流水編號,
	A.最後更新者,
	nvl(Z1.員工姓名,' ') 更新者姓名,
	A.最後更新日,
	A.其它日期 PLC抓取日期,
	A.Time1 PLC抓取時間
FROM 
	FIL0040 A
	/*特殊欄位*/
	INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
	INNER JOIN FIL0041 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號 AND A.單據序號 = C.序號
	INNER JOIN FIL0030 M ON A.單據類別 = M.單據類別 AND A.單據編號 = M.單據編號 
	/*製令*/
	INNER JOIN ViewFIL4030 D ON A.前置單別 = D.製令單別 AND A.前置單號 = D.製令單號
	LEFT JOIN FIL0010 Z1 ON A.最後更新者 = Z1.員工編號
WHERE
	A.單據類別 = 'C41' AND
	A.異動類別 = 'A' AND
	B.製程代碼 = 'C31H');

-- Oracle user_views
CREATE VIEW "VIEWFIL404H3" ("單別", "單號", "序號", "作業日期", "機台代碼", "機台名稱", "開始時間", "結束時間", "製令單別", "製令單號", "機台選擇", "選擇名稱", "機台名稱串") AS (                                                                                                                                                      SELECT
	A.單據類別 單別,
	A.單據編號 單號,
	D.單據序號 序號,
	A.單據日期 作業日期,
	B.機台代碼,
	nvl(C.名稱, ' ') 機台名稱,
	E.TIME1 開始時間,
	E.TIME2 結束時間,
	D.前置單別 製令單別,
	D.前置單號 製令單號,
	E.包裝單位 機台選擇,
	decode(E.包裝單位,'A','十色','B','七色','C','六色','D','積層','E','淋膜','選擇') 選擇名稱,
	replace('□十色 □七色 □六色 □積層 □淋膜', trim('□' || decode(E.包裝單位,'A','十色','B','七色','C','六色','D','積層','E','淋膜','選擇')), trim('■' || decode(E.包裝單位,'A','十色','B','七色','C','六色','D','積層','E','淋膜','選擇')))  機台名稱串
FROM
	FIL0030 A
	/*特殊欄位*/
	INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
	/* */
	LEFT JOIN ViewFIL310P C ON B.機台代碼 = C.代碼
	/*檢品明細*/
	LEFT JOIN FIL0040 D ON A.單據類別 = D.單據類別 AND A.單據編號 = D.單據編號 AND D.異動類別 = 'A'
	LEFT JOIN FIL0041 E ON A.單據類別 = E.單別 AND A.單據編號 = E.單號 AND D.單據序號 = E.序號
WHERE
	A.單據類別 = 'C41' AND
	B.製程代碼 = 'C31H');

-- Oracle user_views
CREATE VIEW "VIEWFIL404I1" ("單別", "單號", "作業日期", "公司代碼", "公司名稱", "機台代碼", "機台名稱", "備註", "作業人員", "作業人員姓名", "確認碼", "標籤機代碼", "簽核系統", "簽核狀態", "主旨", "單位主管流水編號", "員工流水編號", "流水編號", "填表人", "填表人姓名", "填表日", "最後更新者", "更新者姓名", "最後更新日", "起始時間", "結束時間", "總耗時", "改件調整") AS (                                                                                                                                                      SELECT
	A.單據類別 單別,
	A.單據編號 單號,
	A.單據日期 作業日期,
	A.公司代碼,
	nvl(E.名稱, ' ') 公司名稱,
	B.機台代碼,
	nvl(D.名稱, ' ') 機台名稱,
	A.備註, 
	A.業務員 作業人員,
	nvl(C.員工姓名,' ') 作業人員姓名, 	
	A.確認碼,
	B.貿易條件 標籤機代碼,
	A.簽核系統, 
	nvl(Z3.簽核狀態, '0') 簽核狀態,
	A.單據編號||'('||trim(A.單據類別)||')' 主旨,
	D.單位主管流水編號,
	nvl(Z1.Serial_Num,' ') 員工流水編號, 
	A.流水編號,
	A.填表人,
	nvl(Z1.員工姓名,' ') 填表人姓名, 
	A.填表日, 
	A.最後更新者,
	nvl(Z2.員工姓名,' ') 更新者姓名, 
	A.最後更新日,
	B.時間一 起始時間,
	B.時間五 結束時間	,
	decode(B.時間五,'000000',0,(to_date(to_char(case when B.時間五>B.時間一 then to_date(A.單據日期,'yyyymmdd') else to_date(A.單據日期,'yyyymmdd')+1 end,'yyyymmdd')||B.時間五,'yyyymmddhh24miss')- 
	to_date(trim(A.單據日期)||B.時間一,'yyyymmddhh24miss'))*24) 總耗時,
	B.LOGICAL6 改件調整
FROM
	FIL0030 A
	/*特殊欄位*/
	INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
	/* */
	LEFT JOIN FIL0010 C ON A.業務員 = C.員工編號
	LEFT JOIN ViewFIL310P D ON B.機台代碼 = D.代碼
	LEFT JOIN ViewFIL0011 E ON A.公司代碼 = E.代碼
	LEFT JOIN FIL0010 Z1 ON A.填表人 = Z1.員工編號
	LEFT JOIN FIL0010 Z2 ON A.最後更新者 = Z2.員工編號
	LEFT JOIN ViewOfObjProperties Z3 ON A.流水編號 = Z3.單據流水號
WHERE
	A.單據類別 = 'C41' AND
	B.製程代碼 = 'C31K');

-- Oracle user_views
CREATE VIEW "VIEWFIL404I2" ("單別", "單號", "序號", "日期", "開始時間", "結束時間", "製令單別", "製令單號", "加工別", "公司代碼", "公司名稱", "訂單單別", "訂單單號", "客戶編號", "客戶名稱", "產品編號", "產品名稱", "產品規格", "前製程編號", "前製程米數", "檢品編號", "檢品米數", "庫存米數", "合併編號", "合併米數", "印刷色數", "機台選擇", "機台名稱", "機台名稱串", "是否符合", "字圖清晰度", "接頭數量", "線外不良剔除", "線內不良剔除", "不良剔除米數", "合理剔除數", "標籤列印次數二", "前製程條碼", "備註說明", "流水編號", "最後更新者", "更新者姓名", "最後更新日", "PLC抓取日期", "PLC抓取時間") AS (                                                                                                                                                      SELECT 
	A.單據類別 單別, 
	A.單據編號 單號,
	A.單據序號 序號,
	M.單據日期 日期,
	C.TIME1 開始時間,
	C.TIME2 結束時間,
	A.前置單別 製令單別,
	A.前置單號 製令單號,
	C.小單位 加工別,
	D.公司代碼,
	D.公司名稱,
	D.訂單單別,
	D.訂單單號,
	D.客戶編號,
	D.客戶名稱,
	D.產品編號,
	D.產品名稱,
	D.產品規格,
	A.前製程編號,
	A.異動數量 前製程米數,
	A.產品編號 檢品編號,
	A.贈品數量 檢品米數,
	(A.異動單價 - 夾鏈費) 庫存米數,
	A.合併編號,
	A.異動單價 合併米數,
	A.異動金額 印刷色數,
	C.包裝單位 機台選擇,
	decode(C.包裝單位,'A','十色','B','七色','C','六色','D','積層','E','淋膜','選擇') 機台名稱,
	replace('□十色 □七色 □六色 □積層 □淋膜', trim('□' || decode(C.包裝單位,'A','十色','B','七色','C','六色','D','積層','E','淋膜','選擇')), trim('■' || decode(C.包裝單位,'A','十色','B','七色','C','六色','D','積層','E','淋膜','選擇')))  機台名稱串,
	A.Logical1 是否符合,
	A.結案碼 字圖清晰度,
	A.折扣率 接頭數量,
	A.雷射費 線外不良剔除,
	A.夾鏈費 線內不良剔除,
	A.毛重 不良剔除米數,
	A.燙金費 合理剔除數,
	C.標籤列印次數二,
	C.文數字4 前製程條碼,
	A.備註說明,
	A.流水編號,
	A.最後更新者,
	nvl(Z1.員工姓名,' ') 更新者姓名,
	A.最後更新日,
	A.其它日期 PLC抓取日期,
	A.Time1 PLC抓取時間
FROM 
	FIL0040 A
	/*特殊欄位*/
	INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
	INNER JOIN FIL0041 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號 AND A.單據序號 = C.序號
	INNER JOIN FIL0030 M ON A.單據類別 = M.單據類別 AND A.單據編號 = M.單據編號 
	/*製令*/
	INNER JOIN ViewFIL4030 D ON A.前置單別 = D.製令單別 AND A.前置單號 = D.製令單號
	LEFT JOIN FIL0010 Z1 ON A.最後更新者 = Z1.員工編號
WHERE
	A.單據類別 = 'C41' AND
	A.異動類別 = 'A' AND
	B.製程代碼 = 'C31K');

-- Oracle user_views
CREATE VIEW "VIEWFIL404I3" ("單別", "單號", "序號", "作業日期", "機台代碼", "機台名稱", "開始時間", "結束時間", "製令單別", "製令單號", "機台選擇", "選擇名稱", "機台名稱串") AS (                                                                                                                                                      SELECT
	A.單據類別 單別,
	A.單據編號 單號,
	D.單據序號 序號,
	A.單據日期 作業日期,
	B.機台代碼,
	nvl(C.名稱, ' ') 機台名稱,
	E.TIME1 開始時間,
	E.TIME2 結束時間,
	D.前置單別 製令單別,
	D.前置單號 製令單號,
	E.包裝單位 機台選擇,
	decode(E.包裝單位,'A','十色','B','七色','C','六色','D','積層','E','淋膜','選擇') 選擇名稱,
	replace('□十色 □七色 □六色 □積層 □淋膜', trim('□' || decode(E.包裝單位,'A','十色','B','七色','C','六色','D','積層','E','淋膜','選擇')), trim('■' || decode(E.包裝單位,'A','十色','B','七色','C','六色','D','積層','E','淋膜','選擇')))  機台名稱串
FROM
	FIL0030 A
	/*特殊欄位*/
	INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
	/* */
	LEFT JOIN ViewFIL310P C ON B.機台代碼 = C.代碼
	/*檢品明細*/
	LEFT JOIN FIL0040 D ON A.單據類別 = D.單據類別 AND A.單據編號 = D.單據編號 AND D.異動類別 = 'A'
	LEFT JOIN FIL0041 E ON A.單據類別 = E.單別 AND A.單據編號 = E.單號 AND D.單據序號 = E.序號
WHERE
	A.單據類別 = 'C41' AND
	B.製程代碼 = 'C31K');

-- Oracle user_views
CREATE VIEW "VIEWFIL404J1" ("單別", "單號", "作業日期", "製令單別", "製令單號", "製程代碼", "單位主管流水編號", "主旨", "客戶名稱", "產品名稱", "產品規格", "時間一", "時間二", "委外", "流水編號", "填表人", "員工流水編號") AS (                                                                                                                                                      SELECT
	A.單據類別 單別,
	A.單據編號 單號,
	A.單據日期 作業日期,
	A.歸屬類別 製令單別,
	A.歸屬編號 製令單號,
	B.製程代碼,
	D.單位主管流水編號,
	A.單據編號||'('||trim(A.單據類別)||')'||'/製令:'||nvl(A.歸屬編號, ' ')||'/'||C.客戶名稱||'/'||C.產品名稱 主旨,
	C.客戶名稱,
	C.產品名稱,
	C.產品規格,
	B.時間一,
	B.時間二,
	nvl(D.委外, 0) 委外,
	A.流水編號,
	A.填表人,
	nvl(Z1.Serial_Num,' ') 員工流水編號
FROM
	FIL0030 A
	LEFT JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
	LEFT JOIN ViewFIL4030 C ON A.歸屬類別 = C.製令單別 AND A.歸屬編號 = C.製令單號
	LEFT JOIN ViewFIL310P D ON B.機台代碼 = D.代碼
	LEFT JOIN FIL0010 Z1 ON A.填表人 = Z1.員工編號
WHERE
	A.單據類別 = 'C41');

-- Oracle user_views
CREATE VIEW "VIEWFIL404K1" ("單別", "單號", "作業日期", "製令單別", "製令單號", "簽核系統", "備註", "作業人員", "確認碼", "主旨", "流水編號", "填表人", "填表日", "最後更新者", "最後更新日", "待補", "結束", "開始時間", "結束時間", "總耗時", "包裝方式", "每箱捲數", "紙箱編號", "待補日報", "尾數紙箱編號", "機台代碼", "公司代碼", "公司名稱", "訂單單別", "訂單單號", "客戶編號", "客戶名稱", "產品編號", "產品名稱", "產品規格", "機台名稱", "紙箱品名", "尾數紙箱品名", "作業人員姓名", "員工流水編號", "填表人姓名", "更新者姓名", "簽核狀態", "單位主管流水編號") AS WITH TMP1 AS
(SELECT
	A.單據類別 單別,
	A.單據編號 單號,
	A.單據日期 作業日期,
	A.歸屬類別 製令單別,
	A.歸屬編號 製令單號,
	A.簽核系統, 
	A.備註, 
	A.業務員 作業人員,
	A.確認碼,
	A.單據編號||'('||trim(A.單據類別)||')'||'/製令:'||nvl(A.歸屬編號, ' ')||'/'||C.產品名稱 主旨,
	A.流水編號,
	A.填表人,
	A.填表日, 
	A.最後更新者,
	A.最後更新日,
	B.Logical4 待補,
	B.Logical5 結束,
	B.時間一 開始時間,
	B.時間五 結束時間,
	decode(B.時間五,'000000',0,(to_date(to_char(case when B.時間五>B.時間一 then to_date(A.單據日期,'yyyymmdd') else to_date(A.單據日期,'yyyymmdd')+1 end,'yyyymmdd')||B.時間五,'yyyymmddhh24miss')- 
	to_date(trim(A.單據日期)||B.時間一,'yyyymmddhh24miss'))*24) 總耗時,
	B.文數字1 包裝方式,
	B.數值1 每箱捲數,
	B.材料編號一 紙箱編號,
	B.文數字9 待補日報,
	B.文數字12 尾數紙箱編號,
	B.機台代碼,
	C.公司代碼,
	C.公司名稱,
	C.訂單單別,
	C.訂單單號,
	C.客戶編號,
	C.客戶名稱,
	C.產品編號,
	C.產品名稱,
	C.產品規格
FROM
	FIL0030 A
	INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
	INNER JOIN ViewFIL4030_A C ON A.歸屬類別 = C.製令單別 AND A.歸屬編號 = C.製令單號
WHERE
	A.單據類別 = 'C41' AND
	B.製程代碼 = 'C31I')	
SELECT 
	A.單別,
	A.單號,
	A.作業日期,
	A.製令單別,
	A.製令單號,
	A.簽核系統, 
	A.備註, 
	A.作業人員,
	A.確認碼,
	A.主旨,
	A.流水編號,
	A.填表人,
	A.填表日, 
	A.最後更新者,
	A.最後更新日,
	A.待補,
	A.結束,
	A.開始時間,
	A.結束時間,
	A.總耗時,
	A.包裝方式,
	A.每箱捲數,
	A.紙箱編號,
	A.待補日報,
	A.尾數紙箱編號,
	A.機台代碼,
	A.公司代碼,
	A.公司名稱,
	A.訂單單別,
	A.訂單單號,
	A.客戶編號,
	A.客戶名稱,
	A.產品編號,
	A.產品名稱,
	A.產品規格,
	nvl(D.名稱, ' ') 機台名稱,
	Z4.品名||Z4.規格 紙箱品名,
	nvl(Z5.品名,' ')||nvl(Z5.規格,' ') 尾數紙箱品名,
	nvl(E.員工姓名,' ') 作業人員姓名, 
	nvl(Z1.Serial_Num,' ') 員工流水編號, 
	nvl(Z1.員工姓名,' ') 填表人姓名, 
	nvl(Z2.員工姓名,' ') 更新者姓名, 
	nvl(Z3.簽核狀態, '0') 簽核狀態,
	D.單位主管流水編號
FROM 
	TMP1 A
	LEFT JOIN ViewFIL310P D ON A.機台代碼 = D.代碼
	LEFT JOIN FIL0010 E ON A.作業人員 = E.員工編號
	LEFT JOIN FIL0010 Z1 ON A.填表人 = Z1.員工編號
	LEFT JOIN FIL0010 Z2 ON A.最後更新者 = Z2.員工編號
	LEFT JOIN ViewOfObjProperties Z3 ON A.流水編號 = Z3.單據流水號
	LEFT JOIN ViewFIL1012 Z4 ON Z4.產品編號 = A.紙箱編號
	LEFT JOIN ViewFIL1012 Z5 ON Z5.產品編號 = A.尾數紙箱編號;

-- Oracle user_views
CREATE VIEW "VIEWFIL404K2" ("單別", "單號", "全部箱數", "尾數箱", "全部捲數", "尾數捲數") AS (                                                                                                                                                      SELECT 
	A.單據類別 單別, 
	A.單據編號 單號,
	count(A.單據序號) 全部箱數,
	SUM(decode(B.數值1,C.包裝數量,0,1)) 尾數箱,
	SUM(nvl(C.包裝數量,0)) 全部捲數,
	SUM(decode(B.數值1,nvl(C.包裝數量,0),0,nvl(C.包裝數量,0))) 尾數捲數
FROM 
	FIL0040 A
	INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
	LEFT JOIN FIL0041 C ON C.單別 = A.單據類別 AND C.單號 = A.單據編號 AND C.序號 = A.單據序號
WHERE
	A.單據類別 = 'C41' AND
	A.異動類別 = 'A' AND
	B.製程代碼 = 'C31I' AND
	nvl(C.包裝數量,0) > 0
GROUP BY
	A.單據類別, 
	A.單據編號);

-- Oracle user_views
CREATE VIEW "VIEWFIL404K3" ("單別", "單號", "序號", "細分", "箱號", "半成品編號", "數量", "重量", "入庫日期", "製造日期", "單號序號") AS (                                                                                                                                                      SELECT 
	A.單別, 
	A.單號,
	A.序號,
	A.細分,
	C.異動數量 箱號,
	A.文字一 半成品編號,
	A.數字一 數量,
	C.毛重 重量,
	A.日期一 入庫日期,
	A.日期二 製造日期,
	rtrim(A.單號)||trim(to_char(A.序號,'0000')) 單號序號
FROM 
	FIL00401 A
	INNER JOIN FIL0031 B ON A.單別 = B.單別 AND A.單號 = B.單號
	INNER JOIN FIL0040 C ON A.單別 = c.單據類別 AND A.單號 = C.單據編號 AND A.序號=C.單據序號
WHERE
	A.單別 = 'C41' AND
	B.製程代碼 = 'C31I'
);

-- Oracle user_views
CREATE VIEW "VIEWFIL404K4" ("製令單別", "製令單號", "箱號") AS (                                                                                                                                                      SELECT 
	D.歸屬類別 製令單別, 
	D.歸屬編號 製令單號,
	max(C.異動數量) 箱號
FROM 
	FIL00401 A
	INNER JOIN FIL0031 B ON A.單別 = B.單別 AND A.單號 = B.單號
	INNER JOIN FIL0040 C ON A.單別 = c.單據類別 AND A.單號 = C.單據編號 AND A.序號=C.單據序號
	INNER JOIN FIL0030 D ON A.單別 = D.單據類別 AND A.單號 = D.單據編號 
WHERE
	A.單別 = 'C41' AND
	B.製程代碼 = 'C31I'
GROUP BY 
	D.歸屬類別, 
	D.歸屬編號
);

-- Oracle user_views
CREATE VIEW "VIEWFIL404K5" ("製令單別", "製令單號", "捲數") AS (                                                                                                                                                      SELECT 
	D.歸屬類別 製令單別, 
	D.歸屬編號 製令單號,
	SUM(nvl(C.包裝數量,0)) 捲數
FROM 
	FIL0040 A
	INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
	LEFT JOIN FIL0041 C ON C.單別 = A.單據類別 AND C.單號 = A.單據編號 AND C.序號 = A.單據序號
	INNER JOIN FIL0030 D ON A.單據類別 = D.單據類別 AND A.單據編號 = D.單據編號
WHERE
	A.單據類別 = 'C41' AND
	A.異動類別 = 'A' AND
	B.製程代碼 = 'C31I' AND
	nvl(C.包裝數量,0) > 0
GROUP BY
	D.歸屬類別, 
	D.歸屬編號);

-- Oracle user_views
CREATE VIEW "VIEWFIL404K6" ("製令單別", "製令單號", "箱號") AS (        
SELECT Distinct
	D.歸屬類別 製令單別, 
	D.歸屬編號 製令單號,
	A.異動數量 箱號
FROM 
	FIL0040 A
	INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
	LEFT JOIN FIL0041 C ON C.單別 = A.單據類別 AND C.單號 = A.單據編號 AND C.序號 = A.單據序號
	INNER JOIN FIL0030 D ON A.單據類別 = D.單據類別 AND A.單據編號 = D.單據編號
WHERE
	A.單據類別 = 'C41' AND
	A.異動類別 = 'A' AND
	B.製程代碼 = 'C31I' 
);

-- Oracle user_views
CREATE VIEW "VIEWFIL404K7" ("製令單號", "條碼", "庫存數") AS with tmp1 AS
(SELECT 
	REGEXP_SUBSTR(REGEXP_SUBSTR(A.文字一, '[^_]+', 1,1),'[^-]+', 1,1) 製令單號,
	A.文字一 條碼,
	1 數量
FROM 
	FIL00401 A
	INNER JOIN FIL0031 B ON A.單別 = B.單別 AND A.單號 = B.單號
	INNER JOIN FIL0040 C ON A.單別 = c.單據類別 AND A.單號 = C.單據編號 AND A.序號=C.單據序號
WHERE
	A.單別 = 'C41' AND
	B.製程代碼 = 'C31I'
	
union all	

SELECT 
		REGEXP_SUBSTR(REGEXP_SUBSTR(A.條碼, '[^_]+', 1,1),'[^-]+', 1,1) 製令單號,
		A.條碼,
		-1 數量
	FROM 
		FIL0044 A 
	WHERE 
		A.單據類別='B42' and 
		A.來源 ='O'	 
	GROUP BY
		REGEXP_SUBSTR(REGEXP_SUBSTR(A.條碼, '[^_]+', 1,1),'[^-]+', 1,1),
		A.條碼
 )   
SELECT
	A.製令單號,
	A.條碼,
	sum(A.數量) 庫存數
FROM
	tmp1 A
GROUP BY
	A.製令單號,
	A.條碼;

-- Oracle user_views
CREATE VIEW "VIEWFIL404K8" ("製令單號", "庫存數") AS with tmp1 AS
(SELECT 
	REGEXP_SUBSTR(REGEXP_SUBSTR(A.文字一, '[^_]+', 1, 1), '[^-]+', 1, 1) 製令單號,
	A.文字一 條碼,
	1 數量
FROM 
	FIL00401 A
	INNER JOIN FIL0031 B ON A.單別 = B.單別 AND A.單號 = B.單號
	INNER JOIN FIL0040 C ON A.單別 = c.單據類別 AND A.單號 = C.單據編號 AND A.序號=C.單據序號
WHERE
	A.單別 = 'C41' AND
	B.製程代碼 = 'C31I'
	
union all	

SELECT 
		REGEXP_SUBSTR(REGEXP_SUBSTR(A.條碼, '[^_]+', 1, 1), '[^-]+', 1, 1) 製令單號,
		A.條碼,
		-1 數量
	FROM 
		FIL0044 A 
	WHERE 
		A.單據類別='B42' and 
		A.來源 ='O'	 
	GROUP BY
		REGEXP_SUBSTR(REGEXP_SUBSTR(A.條碼, '[^_]+', 1, 1), '[^-]+', 1, 1),
		A.條碼
 )   
SELECT
	A.製令單號,
	sum(A.數量) 庫存數
FROM
	tmp1 A
GROUP BY
	A.製令單號;

-- Oracle user_views
CREATE VIEW "VIEWFIL404Z1" ("製程代碼", "機台代碼", "作業日期", "製令單別", "製令單號", "筆數") AS (                                                                                                                                                      SELECT
	A.製程代碼,
	A.機台代碼,
	B.單據日期 作業日期,
	B.歸屬類別 製令單別,
	B.歸屬編號 製令單號,
	count(*) 筆數
FROM
	FIL0031 A
	INNER JOIN FIL0030 B ON A.單別 = B.單據類別 AND A.單號 = B.單據編號
WHERE
	A.單別 = 'C41' AND
	B.歸屬編號 != ' '
GROUP BY
	A.製程代碼,
	A.機台代碼,
	B.單據日期,
	B.歸屬類別,
	B.歸屬編號);

-- Oracle user_views
CREATE VIEW "VIEWFIL404Z2" ("單別", "單號", "作業日期", "公司代碼", "公司名稱", "製程代碼", "製程名稱", "機台代碼", "機台名稱", "備註", "作業人員", "作業人員姓名", "簽核系統", "簽核狀態", "流水編號", "填表人", "填表人姓名", "填表日", "最後更新者", "更新者姓名", "最後更新日") AS (                                                                                                                                                      SELECT
	A.單據類別 單別,
	A.單據編號 單號,
	A.單據日期 作業日期,
	A.公司代碼,
	nvl(E.名稱, ' ') 公司名稱,
	B.製程代碼,
	nvl(F.名稱, ' ') 製程名稱,
	B.機台代碼,
	nvl(D.名稱, ' ') 機台名稱,
	A.備註, 
	A.業務員 作業人員,
	nvl(C.員工姓名,' ') 作業人員姓名, 	
	A.簽核系統, 
	nvl(Z3.簽核狀態, ' ') 簽核狀態,
	A.流水編號,
	A.填表人,
	nvl(Z1.員工姓名,' ') 填表人姓名, 
	A.填表日, 
	A.最後更新者,
	nvl(Z2.員工姓名,' ') 更新者姓名, 
	A.最後更新日
FROM
	FIL0030 A
	/*特殊欄位*/
	INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
	/* */
	LEFT JOIN FIL0010 C ON A.業務員 = C.員工編號
	LEFT JOIN ViewFIL310P D ON B.機台代碼 = D.代碼
	LEFT JOIN ViewFIL0011 E ON A.公司代碼 = E.代碼
	LEFT JOIN ViewFIL310N F ON B.製程代碼 = F.代碼
	LEFT JOIN FIL0010 Z1 ON A.填表人 = Z1.員工編號
	LEFT JOIN FIL0010 Z2 ON A.最後更新者 = Z2.員工編號
	LEFT JOIN ViewFIL0030 Z3 ON A.簽核系統 = Z3.簽核系統 AND A.單據編號 = Z3.單號
WHERE
	A.單據類別 = 'C41');

-- Oracle user_views
CREATE VIEW "VIEWFIL404Z3" ("單別", "單號", "序號", "料號", "品名", "規格", "批號", "領用日期", "領用數量", "庫存數", "單位代碼", "庫別代碼", "庫別名稱", "回庫日期", "回庫數量", "回庫庫別", "報廢數量", "回庫名稱", "主檔序號", "備註說明", "沿用", "使用廢料", "接頭數", "標籤列印次數", "標籤列印日期一", "標籤列印時間一", "狀態", "流水編號", "最後更新者", "更新者姓名", "最後更新日") AS (                                                                                                                                                      SELECT 
	A.單據類別 單別, 
	A.單據編號 單號,
	A.單據序號 序號,
	A.產品編號 料號,
	nvl(C.品名, ' ') 品名,
	nvl(C.規格, ' ') 規格,
	nvl(B.批號,' ') 批號,
	A.異動日期 領用日期,
	A.異動數量 領用數量,
	A.數值1 庫存數,
	A.單位代碼,
	A.倉庫代碼 庫別代碼,
	nvl(D.名稱, ' ') 庫別名稱,
	A.預交日 回庫日期,
	A.贈品數量 回庫數量,
	A.前置單別 回庫庫別,
	A.毛重 報廢數量,
	nvl(E.名稱, ' ') 回庫名稱,
	A.QRNo 主檔序號,
	A.備註說明,
	A.Logical1 沿用,
	A.Logical1 使用廢料,
	A.數值2 接頭數, 
	B.標籤列印次數,
	B.標籤列印日期一,
	B.標籤列印時間一,
	decode(B.檢驗外觀,'A','正式料','B','試刷料','C','廢料',' ') 狀態,
	A.流水編號,
	A.最後更新者,
	nvl(Z1.員工姓名,' ') 更新者姓名,
	A.最後更新日
FROM 
	FIL0040 A
	LEFT JOIN FIL0041 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號 AND A.單據序號 = B.序號
	LEFT JOIN FIL0012 C ON A.產品編號 = C.產品編號
	LEFT JOIN ViewFIL3106 D ON A.倉庫代碼 = D.代碼
	LEFT JOIN ViewFIL310N E ON A.前置單別 = E.代碼
	LEFT JOIN FIL0010 Z1 ON A.最後更新者 = Z1.員工編號
WHERE
	A.單據類別 = 'C41' AND
	A.異動類別 = 'C');

-- Oracle user_views
CREATE VIEW "VIEWFIL404Z4" ("單別", "單號", "領用數量", "回庫數量", "報廢數量") AS (                                                                                                                                                      SELECT 
	A.單據類別 單別, 
	A.單據編號 單號,
	sum(A.異動數量) 領用數量,
	sum(A.贈品數量) 回庫數量,
	sum(A.毛重) 報廢數量
FROM 
	FIL0040 A
WHERE
	A.單據類別 = 'C41' AND
	A.異動類別 = 'C'
GROUP BY
	A.單據類別, 
	A.單據編號);

-- Oracle user_views
CREATE VIEW "VIEWFIL404Z5" ("批號", "領用數量") AS (                                                                                                                                                      SELECT 
	B.批號,
	sum(A.異動數量 * nvl(E.換算率, 1)) 領用數量
FROM 
	FIL0040 A
	INNER JOIN FIL0041 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號 AND A.單據序號 = B.序號
	LEFT JOIN FIL0012 C ON A.產品編號 = C.產品編號
	/*單位換算*/
	LEFT JOIN ViewFIL1017 E ON A.單位代碼 = E.從 AND C.單位代碼 = E.到
WHERE
	A.單據類別 = 'C41' AND
	A.異動類別 = 'C' AND
	A.異動數量 != 0
GROUP BY
	B.批號);

-- Oracle user_views
CREATE VIEW "VIEWFIL404Z6" ("流水編號", "前製程編號") AS (                                                                                                                                                      SELECT
	A.流水編號,
	listagg
	(trim(B.文數字1) , ',') within group (order by B.文數字1) as 前製程編號
FROM
	FIL0045 A 
	INNER JOIN FIL0040 B ON A.領用編號 = B.流水編號 AND B.單據類別 = 'C41'
group by 
	A.流水編號);

-- Oracle user_views
CREATE VIEW "VIEWFIL404Z7" ("單別", "單號", "序號", "料號", "品名", "規格", "批號", "報廢日期", "報廢數量", "單位代碼", "庫別代碼", "庫別名稱", "備註說明", "流水編號", "最後更新者", "更新者姓名", "最後更新日") AS (                                                                                                                                                      SELECT 
	A.單據類別 單別, 
	A.單據編號 單號,
	A.單據序號 序號,
	A.產品編號 料號,
	nvl(C.品名, ' ') 品名,
	nvl(C.規格, ' ') 規格,
	B.批號,
	A.異動日期 報廢日期,
	A.異動數量 報廢數量,
	A.單位代碼,
	A.倉庫代碼 庫別代碼,
	nvl(D.名稱, ' ') 庫別名稱,
	A.備註說明,
	A.流水編號,
	A.最後更新者,
	nvl(Z1.員工姓名,' ') 更新者姓名,
	A.最後更新日
FROM 
	FIL0040 A
	INNER JOIN FIL0041 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號 AND A.單據序號 = B.序號
	LEFT JOIN FIL0012 C ON A.產品編號 = C.產品編號
	LEFT JOIN ViewFIL3106 D ON A.倉庫代碼 = D.代碼
	LEFT JOIN FIL0010 Z1 ON A.最後更新者 = Z1.員工編號
WHERE
	A.單據類別 = 'C41' AND
	A.異動類別 = 'D');

-- Oracle user_views
CREATE VIEW "VIEWFIL404Z8" ("單別", "單號", "報廢數量") AS (                                                                                                                                                      SELECT 
	A.單據類別 單別, 
	A.單據編號 單號,
	sum(A.異動數量) 報廢數量
FROM 
	FIL0040 A
WHERE
	A.單據類別 = 'C41' AND
	A.異動類別 = 'D'
GROUP BY
	A.單據類別, 
	A.單據編號);

-- Oracle user_views
CREATE VIEW "VIEWFIL404Z9" ("單別", "單號", "序號", "料號", "品名", "規格", "批號", "領用日期", "領用數量", "單位代碼", "庫別代碼", "庫別名稱", "回庫日期", "回庫數量", "回庫庫別", "回庫名稱", "品名規格", "備註說明", "流水編號", "最後更新者", "更新者姓名", "最後更新日") AS (
SELECT 
	A.單據類別 單別, 
	A.單據編號 單號,
	A.單據序號 序號,
	A.產品編號 料號,
	nvl(C.品名, ' ') 品名,
	nvl(C.規格, ' ') 規格,
	B.批號,
	A.異動日期 領用日期,
	A.異動數量 領用數量,
	A.單位代碼,
	A.倉庫代碼 庫別代碼,
	nvl(D.名稱, ' ') 庫別名稱,
	A.預交日 回庫日期,
	A.贈品數量 回庫數量,
	A.前置單別 回庫庫別,
	nvl(E.名稱, ' ') 回庫名稱,
	trim(B.批號) || ' ' || trim(nvl(C.品名, ' ')) || '/' || nvl(C.規格, ' ') 品名規格,
	A.備註說明,
	A.流水編號,
	A.最後更新者,
	nvl(Z1.員工姓名,' ') 更新者姓名,
	A.最後更新日
FROM 
	FIL0040 A
	INNER JOIN FIL0041 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號 AND A.單據序號 = B.序號
	LEFT JOIN FIL0012 C ON A.產品編號 = C.產品編號
	LEFT JOIN ViewFIL3106 D ON A.倉庫代碼 = D.代碼
	LEFT JOIN ViewFIL3106 E ON A.前置單別 = E.代碼
	LEFT JOIN FIL0010 Z1 ON A.最後更新者 = Z1.員工編號
WHERE
	A.單據類別 = 'C41' AND
	A.異動類別 = 'E');

-- Oracle user_views
CREATE VIEW "VIEWFIL404ZA" ("單別", "單號", "領用數量", "回庫數量") AS (
SELECT 
	A.單據類別 單別, 
	A.單據編號 單號,
	sum(A.異動數量) 領用數量,
	sum(A.贈品數量) 回庫數量
FROM 
	FIL0040 A
WHERE
	A.單據類別 = 'C41' AND
	A.異動類別 = 'E'
GROUP BY
	A.單據類別, 
	A.單據編號);

-- Oracle user_views
CREATE VIEW "VIEWFIL404ZB" ("單別", "單號", "批號", "領用數量", "耗用數量") AS (
SELECT 
	A.單據類別 單別, 
	A.單據編號 單號,
	B.批號,
	sum(decode(A.異動類別, 'C', A.異動數量, 0)) 領用數量,
	sum(decode(A.異動類別, 'A', A.異動數量, 0)) 耗用數量 /*印刷米數*/
FROM 
	FIL0040 A
	INNER JOIN FIL0041 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號 AND A.單據序號 = B.序號
WHERE
	A.單據類別 = 'C41' AND
	A.異動類別 between 'A' and 'C' AND
	A.異動類別 != 'B'
GROUP BY
	A.單據類別, 
	A.單據編號,
	B.批號);

-- Oracle user_views
CREATE VIEW "VIEWFIL404ZC" ("單別", "歸屬類別", "歸屬編號", "生產日期") AS (
SELECT 
	A.單據類別 單別, 
	A.歸屬類別,
	A.歸屬編號,
	max(B.交貨日期) 生產日期
FROM 
	FIL0030 A
	INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號 
WHERE
	A.單據類別 = 'C41' AND
	B.製程代碼 = 'C31D'
GROUP BY
	A.單據類別, 
	A.歸屬類別,
	A.歸屬編號);

-- Oracle user_views
CREATE VIEW "VIEWFIL404ZD" ("製令單別", "製令單號", "製造日期") AS (
SELECT
	A.歸屬類別 製令單別,
	A.歸屬編號 製令單號,
	max(A.製造日期) 製造日期
FROM	
	(SELECT 
		A.歸屬類別,
		A.歸屬編號,
		max(B.交貨日期) 製造日期
	FROM 
		FIL0030 A
		INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號 
	WHERE
		A.單據類別 = 'C41' AND
		B.製程代碼 = 'C31D' AND
		B.交貨日期<>' '
	GROUP BY
		A.歸屬類別,
		A.歸屬編號
		
	union all

	SELECT 
		A.歸屬類別,
		A.歸屬編號,
		max(A.匯率日期) 製造日期 
	FROM 
		FIL0030 A
	WHERE
		A.單據類別 = 'E22' AND
		A.匯率日期<>' '
	GROUP BY
		A.歸屬類別,
		A.歸屬編號	
	)A	
GROUP BY
		A.歸屬類別,
		A.歸屬編號		
);

-- Oracle user_views
CREATE VIEW "VIEWFIL404ZE" ("製令單別", "製令單號", "製造日期") AS (
SELECT
	A.歸屬類別 製令單別,
	A.歸屬編號 製令單號,
	max(A.製造日期) 製造日期
FROM	
	(SELECT 
		A.歸屬類別,
		A.歸屬編號,
		B.交貨日期 製造日期
	FROM 
		FIL0030 A
		INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號 
	WHERE
		A.單據類別 = 'C41' AND
		B.製程代碼 = 'C31E' AND
		B.交貨日期<>' '
		
	union all

	SELECT 
		'C11' 歸屬類別,
		A.廠客品號 歸屬編號,
		A.預交日 製造日期 
	FROM 
		FIL0040 A
	WHERE
		A.單據類別 = 'E32' AND
		A.預交日<>' '	
		
	union all

	SELECT 
		'C11' 歸屬類別,
		A.廠客品號 歸屬編號,
		A.預交日 製造日期 
	FROM 
		FIL0040 A
	WHERE
		A.單據類別 = 'E37' AND
		A.預交日<>' '
	
	)A	
GROUP BY
		A.歸屬類別,
		A.歸屬編號		
);

-- Oracle user_views
CREATE VIEW "VIEWFIL404ZE_A" ("製令單別", "製令單號", "箱號", "製造日期") AS (
SELECT
	A.歸屬類別 製令單別,
	A.歸屬編號 製令單號,
	A.箱號,
	max(A.製造日期) 製造日期
FROM	
	(SELECT 
		A.歸屬類別,
		A.歸屬編號,
		M.異動數量 箱號,
		B.交貨日期 製造日期
	FROM 
		FIL0040 M
		INNER JOIN FIL0030 A ON A.單據類別 = M.單據類別 AND A.單據編號 = M.單據編號
		INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號 
	WHERE
		A.單據類別 = 'C41' AND
		B.製程代碼 = 'C31E' AND
		B.交貨日期<>' '
		
	union all

	SELECT 
		'C11' 歸屬類別,
		A.廠客品號 歸屬編號,
		A.異動數量 箱號,
		A.預交日 製造日期 
	FROM 
		FIL0040 A
	WHERE
		A.單據類別 = 'E32' AND
		A.預交日<>' '
		
	union all

	SELECT 
		'C11' 歸屬類別,
		A.廠客品號 歸屬編號,
		A.異動數量 箱號,
		A.預交日 製造日期 
	FROM 
		FIL0040 A
	WHERE
		A.單據類別 = 'E37' AND
		A.預交日<>' '	
	)A	
GROUP BY
		A.歸屬類別,
		A.歸屬編號,
		A.箱號
);

-- Oracle user_views
CREATE VIEW "VIEWFIL404ZF" ("單別", "單號", "材料編號", "領用數量", "回庫數量", "報廢數量") AS (                                                                                                                                                      SELECT 
	A.單據類別 單別, 
	A.單據編號 單號,
	A.產品編號 材料編號,
	sum(A.異動數量) 領用數量,
	sum(A.贈品數量) 回庫數量,
	sum(A.毛重) 報廢數量
FROM 
	FIL0040 A
WHERE
	A.單據類別 = 'C41' AND
	A.異動類別 = 'C'
GROUP BY
	A.單據類別, 
	A.單據編號,
	A.產品編號);

-- Oracle user_views
CREATE VIEW "VIEWFIL404ZF_A" ("單別", "單號", "主檔別", "領用數量", "回庫數量", "報廢數量", "合理剔除數") AS (                                                                                                                                                      SELECT 
	A.單據類別 單別, 
	A.單據編號 單號,
	A.QRNO 主檔別,
	sum(A.異動數量) 領用數量,
	sum(A.退庫數量) 回庫數量,
	sum(A.毛重) 報廢數量,
	sum(A.燙金費) 合理剔除數
FROM 
	FIL0040 A
WHERE
	A.單據類別 = 'C41' AND
	A.異動類別 = 'C' AND
	A.QRNO > 0
GROUP BY
	A.單據類別, 
	A.單據編號,
	A.QRNO);

-- Oracle user_views
CREATE VIEW "VIEWFIL404ZG" ("單別", "單號", "序號", "半成品編號", "製程編號", "製令單號", "加工別", "製程代碼", "製程名稱", "回庫日期", "回庫數量", "接頭數", "備註說明", "標籤列印次數", "標籤列印日期一", "標籤列印時間一", "退庫條碼", "流水編號", "最後更新者", "更新者姓名", "最後更新日") AS (                                                                                                                                                      SELECT 
	A.單據類別 單別, 
	A.單據編號 單號,
	A.單據序號 序號,
	A.文數字1 半成品編號,
	A.廠客品號 製程編號,
	A.前置單號 製令單號,
	A.單位代碼 加工別,
	A.前置單別 製程代碼,
	Z2.名稱 製程名稱,
	A.預交日 回庫日期,
	A.贈品數量 回庫數量,
	A.數值2 接頭數,
	A.備註說明,
	B.標籤列印次數,
	B.標籤列印日期一,
	B.標籤列印時間一,
	A.合併編號 退庫條碼,
	A.流水編號,
	A.最後更新者,
	nvl(Z1.員工姓名,' ') 更新者姓名,
	A.最後更新日
FROM 
	FIL0040 A
	LEFT JOIN FIL0041 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號 AND A.單據序號 = B.序號
	LEFT JOIN FIL0010 Z1 ON A.最後更新者 = Z1.員工編號
	LEFT JOIN ViewFil310N Z2 ON A.前置單別 = Z2.代碼
WHERE
	A.單據類別 = 'C41' AND
	A.異動類別 = 'G');

-- Oracle user_views
CREATE VIEW "VIEWFIL404ZH" ("單別", "單號", "回庫數量") AS (                                                                                                                                                      SELECT 
	A.單據類別 單別, 
	A.單據編號 單號,
	sum(A.贈品數量) 回庫數量
FROM 
	FIL0040 A
WHERE
	A.單據類別 = 'C41' AND
	A.異動類別 = 'G'
GROUP BY
	A.單據類別, 
	A.單據編號);

-- Oracle user_views
CREATE VIEW "VIEWFIL404ZI" ("製程", "單別", "單號", "製令單別", "製令單號", "加工別", "開始時間", "結束時間", "總耗時") AS (                                                                                                                                                      
/* 印刷~積層*/
SELECT
	to_char(decode(B.製程代碼,'C31A','印刷','C32D','上臘','C31B','淋膜','積層')) 製程,
	A.單據類別 單別, 
	A.單據編號 單號,
	A.歸屬類別 製令單別,
	A.歸屬編號 製令單號,
	decode(B.交貨日期_次批,'A','A材','B','B材','C','底邊','D','A側','E','B側',' ') 加工別,
	to_date(trim(A.單據日期)||B.時間一,'yyyymmddhh24miss') 開始時間,
	to_date(to_char(case when B.時間五>B.時間一 then to_date(A.單據日期,'yyyymmdd') else to_date(A.單據日期,'yyyymmdd')+1 end,'yyyymmdd')||B.時間五,'yyyymmddhh24miss') 結束時間,
	decode(B.時間五,'000000',0,(to_date(to_char(case when B.時間五>B.時間一 then to_date(A.單據日期,'yyyymmdd') else to_date(A.單據日期,'yyyymmdd')+1 end,'yyyymmdd')||B.時間五,'yyyymmddhh24miss')- to_date(trim(A.單據日期)||B.時間一,'yyyymmddhh24miss'))*24) 總耗時
FROM
	FIL0030 A
	INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
	INNER JOIN ViewFIL4030 C ON A.歸屬類別 = C.製令單別 AND A.歸屬編號 = C.製令單號
WHERE
	A.單據類別 = 'C41' AND
	(B.製程代碼 between 'C31A' and 'C31D' or B.製程代碼 = 'C32D')and 
	（B.時間一 between '000000' and '235959') and 
	（B.時間五 between '000000' and '235959')
	
UNION ALL

/* 裁切~成捲*/	
SELECT
	to_char(decode(B.製程代碼,'C31D','裁切','C31E','製袋','C31F','氣閥','C31G','鐵條','成捲')) 製程,
	A.單據類別 單別,
	A.單據編號 單號,
	A.歸屬類別 製令單別,
	A.歸屬編號 製令單號,
	decode(B.交貨日期_次批,'A','A材','B','B材','C','底邊','D','A側','E','B側',' ') 加工別,
	to_date(trim(A.單據日期)||B.時間一,'yyyymmddhh24miss') 起始時間,
	to_date(to_char(case when B.時間二>B.時間一 then to_date(A.單據日期,'yyyymmdd') else to_date(A.單據日期,'yyyymmdd')+1 end,'yyyymmdd')||B.時間二,'yyyymmddhh24miss') 結束時間,
	decode(B.時間二,'000000',0,(to_date(to_char(case when B.時間二>B.時間一 then to_date(A.單據日期,'yyyymmdd') else to_date(A.單據日期,'yyyymmdd')+1 end,'yyyymmdd')||B.時間二,'yyyymmddhh24miss')- 
	to_date(trim(A.單據日期)||B.時間一,'yyyymmddhh24miss'))*24) 總耗時
FROM
	FIL0030 A
	INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
	INNER JOIN ViewFIL4030_A C ON A.歸屬類別 = C.製令單別 AND A.歸屬編號 = C.製令單號
WHERE
	A.單據類別 = 'C41' AND
	(B.製程代碼 between 'C31D' and 'C31G' or B.製程代碼 = 'C31I') and 
	（B.時間一 between '000000' and '235959') and 
	（B.時間二 between '000000' and '235959')
）;

-- Oracle user_views
CREATE VIEW "VIEWFIL404ZJ" ("製令單別", "製令單號", "開始時間", "結束時間") AS (          
SELECT 
	A.製令單別,
	A.製令單號,
	MIN(A.開始時間) 開始時間,
	MAX(A.結束時間) 結束時間
FROM																																			
	( /* 印刷~積層*/
	SELECT
		A.歸屬類別 製令單別,
		A.歸屬編號 製令單號,
		min(to_date(trim(A.單據日期)||B.時間一,'yyyymmddhh24miss')) 開始時間,
		max(to_date(to_char(case when B.時間五>B.時間一 then to_date(A.單據日期,'yyyymmdd') else to_date(A.單據日期,'yyyymmdd')+1 end,'yyyymmdd')||B.時間五,'yyyymmddhh24miss')) 結束時間
	FROM
		FIL0030 A
		INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
		INNER JOIN ViewFIL4030 C ON A.歸屬類別 = C.製令單別 AND A.歸屬編號 = C.製令單號
	WHERE
		A.單據類別 = 'C41' AND
		(B.製程代碼 between 'C31A' and 'C31D' or B.製程代碼 = 'C32D')and 
		（B.時間一 between '000000' and '235959') and 
		（B.時間五 between '000000' and '235959')
	GROUP BY 
		to_char(decode(B.製程代碼,'C31A','1.印刷','C32D','2.上臘','C31B','3.淋膜','4.積層')),
		A.歸屬類別,
		A.歸屬編號
		
	UNION ALL

	/* 裁切~成捲*/	
	SELECT
		A.歸屬類別 製令單別,
		A.歸屬編號 製令單號,
		min(to_date(trim(A.單據日期)||B.時間一,'yyyymmddhh24miss')) 起始時間,
		max(to_date(to_char(case when B.時間二>B.時間一 then to_date(A.單據日期,'yyyymmdd') else to_date(A.單據日期,'yyyymmdd')+1 end,'yyyymmdd')||B.時間二,'yyyymmddhh24miss')) 結束時間
	FROM
		FIL0030 A
		INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
		INNER JOIN ViewFIL4030_A C ON A.歸屬類別 = C.製令單別 AND A.歸屬編號 = C.製令單號
	WHERE
		A.單據類別 = 'C41' AND
		(B.製程代碼 between 'C31D' and 'C31G' or B.製程代碼 = 'C31I') and 
		（B.時間一 between '000000' and '235959') and 
		（B.時間二 between '000000' and '235959')
	GROUP BY 
		to_char(decode(B.製程代碼,'C31D','5.裁切','C31E','6.製袋','C31F','7.氣閥','C31G','8.鐵條','9.成捲')),
		A.歸屬類別,
		A.歸屬編號
	) A
GROUP BY
	A.製令單別,
	A.製令單號
);

-- Oracle user_views
CREATE VIEW "VIEWFIL404ZK" ("製程", "單別", "單號", "製令單別", "製令單號", "入庫米數") AS (
SELECT 
	to_char(decode(B.製程代碼,'C31A','印刷','C32D','上臘','C31B','淋膜','積層')) 製程,	
	A.單據類別 單別, 
	A.單據編號 單號,
	C.歸屬類別 製令單別,
	C.歸屬編號 製令單號,
	SUM(A.異動單價-A.夾鏈費)入庫米數 
FROM 
	FIL0040 A
	INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
	INNER JOIN FIL0030 C ON A.單據類別 = C.單據類別 AND A.單據編號 = C.單據編號
WHERE
	A.單據類別 = 'C41' AND
	A.異動類別 = 'A' AND
	(B.製程代碼 between 'C31A' and 'C31D' or B.製程代碼 = 'C32D')
GROUP BY
	to_char(decode(B.製程代碼,'C31A','印刷','C32D','上臘','C31B','淋膜','積層')),
	A.單據類別, 
	A.單據編號,
	C.歸屬類別,
	C.歸屬編號

UNION ALL

SELECT 
	to_char('裁切') 製程,	
	A.單據類別 單別, 
	A.單據編號 單號,
	C.歸屬類別 製令單別,
	C.歸屬編號 製令單號,
	sum(case when A.材積+nvl(D.包裝數量,0)<A.異動單價-A.QRNO then 0 else A.材積+nvl(D.包裝數量,0)-A.異動單價-A.QRNO end) 入庫米數
FROM 
	FIL0040 A
	INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
	INNER JOIN FIL0030 C ON A.單據類別 = C.單據類別 AND A.單據編號 = C.單據編號
	Left JOIN FIL0041 D ON A.單據類別 = D.單別 AND A.單據編號 = D.單號 AND A.單據序號 = D.序號
WHERE
	A.單據類別 = 'C41' AND
	A.異動類別 = 'A' AND
	B.製程代碼 = 'C31D'
GROUP BY
	to_char('裁切'),
	A.單據類別, 
	A.單據編號,
	C.歸屬類別,
	C.歸屬編號
	
UNION ALL

/* 製袋/氣閥/鐵條/成捲 */
SELECT 
	to_char(decode(B.製程代碼,'C31E','製袋','C31F','氣閥','C31G','鐵條','成捲')) 製程,
	A.單據類別 單別, 
	A.單據編號 單號,
	D.歸屬類別 製令單別,
	D.歸屬編號 製令單號,
	sum(
		case when B.製程代碼 = 'C31E' then decode(C.數值14, 0, A.贈品數量, C.數值14)
			when B.製程代碼 = 'C31F' then A.贈品數量
			when B.製程代碼 = 'C31G' then A.贈品數量
			when B.製程代碼 = 'C31I' then nvl(C.包裝數量,0) end
	) 繳庫總袋數
FROM 
	FIL0040 A
	INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
	INNER JOIN FIL0041 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號 AND A.單據序號 = C.序號
	INNER JOIN FIL0030 D ON A.單據類別 = D.單據類別 AND A.單據編號 = D.單據編號
WHERE
	A.單據類別 = 'C41' AND
	A.異動類別 = 'A' AND
	（B.製程代碼 between 'C31E' AND 'C31G' or B.製程代碼 = 'C31I'）
GROUP BY
	to_char(decode(B.製程代碼,'C31E','製袋','C31F','氣閥','C31G','鐵條','成捲')),
	A.單據類別, 
	A.單據編號,
	D.歸屬類別,
	D.歸屬編號		
);

-- Oracle user_views
CREATE VIEW "VIEWFIL404ZL" ("製程", "製令單別", "製令單號", "入庫米數") AS (
SELECT 
	to_char(decode(B.製程代碼,'C31A','1.印刷','C32D','2.上臘','C31B','3.淋膜','4.積層')) 製程,	
	C.歸屬類別 製令單別,
	C.歸屬編號 製令單號,
	SUM(A.異動單價-A.夾鏈費)入庫米數 
FROM 
	FIL0040 A
	INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
	INNER JOIN FIL0030 C ON A.單據類別 = C.單據類別 AND A.單據編號 = C.單據編號
WHERE
	A.單據類別 = 'C41' AND
	A.異動類別 = 'A' AND
	(B.製程代碼 between 'C31A' and 'C31D' or B.製程代碼 = 'C32D')
GROUP BY
	to_char(decode(B.製程代碼,'C31A','1.印刷','C32D','2.上臘','C31B','3.淋膜','4.積層')),
	C.歸屬類別,
	C.歸屬編號

UNION ALL

SELECT 
	to_char('5.裁切') 製程,	
	C.歸屬類別 製令單別,
	C.歸屬編號 製令單號,
	sum(case when A.材積+nvl(D.包裝數量,0)<A.異動單價-A.QRNO then 0 else A.材積+nvl(D.包裝數量,0)-A.異動單價-A.QRNO end) 入庫米數
FROM 
	FIL0040 A
	INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
	INNER JOIN FIL0030 C ON A.單據類別 = C.單據類別 AND A.單據編號 = C.單據編號
	Left JOIN FIL0041 D ON A.單據類別 = D.單別 AND A.單據編號 = D.單號 AND A.單據序號 = D.序號
WHERE
	A.單據類別 = 'C41' AND
	A.異動類別 = 'A' AND
	B.製程代碼 = 'C31D'
GROUP BY
	to_char('裁切'),
	C.歸屬類別,
	C.歸屬編號
	
UNION ALL

/* 製袋/氣閥/鐵條/成捲 */
SELECT 
	to_char(decode(B.製程代碼,'C31E','6.製袋','C31F','7.氣閥','C31G','8.鐵條','9.成捲')) 製程,
	D.歸屬類別 製令單別,
	D.歸屬編號 製令單號,
	sum(
		case when B.製程代碼 = 'C31E' then decode(C.數值14, 0, A.贈品數量, C.數值14)
			when B.製程代碼 = 'C31F' then A.贈品數量
			when B.製程代碼 = 'C31G' then A.贈品數量
			when B.製程代碼 = 'C31I' then nvl(C.包裝數量,0) end
	) 繳庫總袋數
FROM 
	FIL0040 A
	INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
	INNER JOIN FIL0041 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號 AND A.單據序號 = C.序號
	INNER JOIN FIL0030 D ON A.單據類別 = D.單據類別 AND A.單據編號 = D.單據編號
WHERE
	A.單據類別 = 'C41' AND
	A.異動類別 = 'A' AND
	（B.製程代碼 between 'C31E' AND 'C31G' or B.製程代碼 = 'C31I'）
GROUP BY
	to_char(decode(B.製程代碼,'C31E','6.製袋','C31F','7.氣閥','C31G','8.鐵條','9.成捲')),
	D.歸屬類別,
	D.歸屬編號		
);

-- Oracle user_views
CREATE VIEW "VIEWFIL404ZM" ("製令單別", "製令單號", "起始時間", "結束時間") AS (          
SELECT
	A.歸屬類別 製令單別,
	A.歸屬編號 製令單號,
	min(to_date(trim(A.單據日期)||B.時間一,'yyyymmddhh24miss')) 起始時間,
	max(to_date(to_char(case when B.時間二>B.時間一 then to_date(A.單據日期,'yyyymmdd') else to_date(A.單據日期,'yyyymmdd')+1 end,'yyyymmdd')||B.時間二,'yyyymmddhh24miss')) 結束時間
FROM
	FIL0030 A
	INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
	INNER JOIN ViewFIL4030_A C ON A.歸屬類別 = C.製令單別 AND A.歸屬編號 = C.製令單號
WHERE
	A.單據類別 = 'C41' AND
	(B.製程代碼 between 'C31E' and 'C31G' or B.製程代碼 = 'C31I') and 
	(B.時間一 between '000000' and '235959') and 
	(B.時間二 between '000000' and '235959')
GROUP BY 
	A.歸屬類別,
	A.歸屬編號
);

-- Oracle user_views
CREATE VIEW "VIEWFIL404ZN" ("單別", "單號", "序號", "製令單別", "製令單號", "產品編號", "製程", "製程編號", "加工別", "箱號", "備註說明") AS (
SELECT 
	A.單據類別 單別, 
	A.單據編號 單號,
	A.單據序號 序號,
	'C11' 製令單別,
	decode(B.製程代碼,'C31H',A.前置單號,'C31K',A.前置單號,D.歸屬編號) 製令單號,
	E.產品編號 產品編號,
	Decode(B.製程代碼,'C31A','印刷','C31B','淋膜','C31C','積層','C31D','裁切','C31E','製袋','C31F','氣閥','C31G','鐵條','C31H','印刷檢品','C31I','成捲','C31K','裁切檢品','C32D','上蠟',' ') 製程,
	A.產品編號 製程編號,
	case when (B.製程代碼 between 'C31A' and 'C31D') or B.製程代碼 = 'C32D' then 
		decode(B.交貨日期_次批 ,'A','A材','B','B材','C','底邊','D','A側','E','B側',' ')
		 else ' '
	end 加工別,	 
	case when (B.製程代碼 between 'C31E' and 'C32I') THEN A.異動數量
	     else 0
	end	箱號,	
	decode(B.製程代碼,'C31H',C.文字1,'C31K',C.文字1,A.備註說明) 備註說明
FROM 
	FIL0040 A
	INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
	INNER JOIN FIL0041 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號 AND A.單據序號 = C.序號
	INNER JOIN FIL0030 D ON A.單據類別 = D.單據類別 AND A.單據編號 = D.單據編號 
	INNER JOIN FIL0032 E ON E.製令單別 = 'C11' AND decode(B.製程代碼,'C31H',A.前置單號,'C31K',A.前置單號,D.歸屬編號) = E.製令單號 
WHERE
	A.單據類別 = 'C41' AND
	A.異動類別 = 'A' AND
	decode(B.製程代碼,'C31H',C.文字1,'C31K',C.文字1,A.備註說明) <> ' ' AND
	(B.製程代碼 between 'C31A' and 'C31I') or B.製程代碼 = 'C32D'
	);

-- Oracle user_views
CREATE VIEW "VIEWFIL404ZO" ("單別", "單號", "單據日期", "製程", "作業人員", "作業人員姓名", "總耗時", "直接人工") AS (Select 
	A.單別,
	A.單號,
	A.單據日期,
	E.名稱 製程,
	A.作業人員,
	D.員工姓名 作業人員姓名,
	nvl(A.總耗時,0) 總耗時,
	nvl(A.時薪*A.總耗時,0) 直接人工
FROM 	
(                                                                                                                                                      
SELECT
	A.單據類別 單別,
	A.單據編號 單號,
	A.單據日期,
	B.製程代碼,
	TO_CHAR(SUBSTR(A.業務員,1,10)) 作業人員,
	decode(B.時間五,'000000',0,(to_date(to_char(case when B.時間五>B.時間一 then to_date(A.單據日期,'yyyymmdd') else to_date(A.單據日期,'yyyymmdd')+1 end,'yyyymmdd')||B.時間五,'yyyymmddhh24miss')- 
	to_date(trim(A.單據日期)||B.時間一,'yyyymmddhh24miss'))*24) 總耗時,
	((F.本月應發金額-F.遲到早退扣支-F.調補扣支)/(30*8)) 時薪
FROM
	FIL0030 A
	INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
	INNER JOIN FIL0010 E ON A.業務員 = E.員工編號
	LEFT JOIN ViewFILHS02 F ON substr(F.年月,1,6)=SUBSTR(A.單據日期,1,6) AND F.員工編號=TO_CHAR(SUBSTR(A.業務員,1,10))
WHERE
	A.單據類別 = 'C41' AND
	B.製程代碼 in('C31A','C31E','C31B','C31C','C31F','C31G','C31I','C32D') AND
	A.業務員 <> ' ' AND
	A.單據日期>'2025'
	
Union

SELECT
	A.單據類別 單別,
	A.單據編號 單號,
	A.單據日期,
	B.製程代碼,
	TO_CHAR(SUBSTR(B.文數字10,1,10)) 作業人員,
	decode(B.時間五,'000000',0,(to_date(to_char(case when B.時間五>B.時間一 then to_date(A.單據日期,'yyyymmdd') else to_date(A.單據日期,'yyyymmdd')+1 end,'yyyymmdd')||B.時間五,'yyyymmddhh24miss')- 
	to_date(trim(A.單據日期)||B.時間一,'yyyymmddhh24miss'))*24) 總耗時,
	((F.本月應發金額-F.遲到早退扣支-F.調補扣支)/(30*8)) 時薪
FROM
	FIL0030 A
	INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
	INNER JOIN FIL0010 E ON B.文數字10 = E.員工編號
	LEFT JOIN ViewFILHS02 F ON substr(F.年月,1,6)=SUBSTR(A.單據日期,1,6) AND F.員工編號=TO_CHAR(SUBSTR(B.文數字10,1,10))
WHERE
	A.單據類別 = 'C41' AND
	(B.製程代碼 = 'C31A' OR B.製程代碼 = 'C31B' OR B.製程代碼 = 'C31C' OR B.製程代碼 = 'C31E' ) AND
	B.文數字10 <> ' ' AND
	A.單據日期>'2025'
	
Union
	
SELECT
	A.單據類別 單別,
	A.單據編號 單號,
	A.單據日期,
	B.製程代碼,
	TO_CHAR(SUBSTR(B.文數字11,1,10)) 作業人員,
	decode(B.時間五,'000000',0,(to_date(to_char(case when B.時間五>B.時間一 then to_date(A.單據日期,'yyyymmdd') else to_date(A.單據日期,'yyyymmdd')+1 end,'yyyymmdd')||B.時間五,'yyyymmddhh24miss')- 
	to_date(trim(A.單據日期)||B.時間一,'yyyymmddhh24miss'))*24) 總耗時,
	((F.本月應發金額-F.遲到早退扣支-F.調補扣支)/(30*8)) 時薪
FROM
	FIL0030 A
	INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
	INNER JOIN FIL0010 E ON B.文數字11 = E.員工編號
	LEFT JOIN ViewFILHS02 F ON substr(F.年月,1,6)=SUBSTR(A.單據日期,1,6) AND F.員工編號=TO_CHAR(SUBSTR(B.文數字11,1,10))
WHERE
	A.單據類別 = 'C41' AND
	(B.製程代碼 = 'C31A' OR B.製程代碼 = 'C31B' OR B.製程代碼 = 'C31C' OR B.製程代碼 = 'C31E' )	AND
	B.文數字11 <> ' ' AND
	A.單據日期>'2025'
	
Union
	
SELECT
	A.單據類別 單別,
	A.單據編號 單號,
	A.單據日期,
	B.製程代碼,
	TO_CHAR(SUBSTR(B.文數字12,1,10)) 作業人員,
	decode(B.時間五,'000000',0,(to_date(to_char(case when B.時間五>B.時間一 then to_date(A.單據日期,'yyyymmdd') else to_date(A.單據日期,'yyyymmdd')+1 end,'yyyymmdd')||B.時間五,'yyyymmddhh24miss')- 
	to_date(trim(A.單據日期)||B.時間一,'yyyymmddhh24miss'))*24) 總耗時,
	((F.本月應發金額-F.遲到早退扣支-F.調補扣支)/(30*8)) 時薪
FROM
	FIL0030 A
	INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
	INNER JOIN FIL0010 E ON B.文數字11 = E.員工編號
	LEFT JOIN ViewFILHS02 F ON substr(F.年月,1,6)=SUBSTR(A.單據日期,1,6) AND F.員工編號=TO_CHAR(SUBSTR(B.文數字12,1,10))
WHERE
	A.單據類別 = 'C41' AND
	(B.製程代碼 = 'C31B' OR B.製程代碼 = 'C31C')	AND
	B.文數字12 <> ' ' AND
	A.單據日期>'2025'
	
Union
	
SELECT
	A.單據類別 單別,
	A.單據編號 單號,
	A.單據日期,
	B.製程代碼,
	TO_CHAR(SUBSTR(A.填表人,1,10)) 作業人員,
	decode(B.時間五,'000000',0,(to_date(to_char(case when B.時間五>B.時間一 then to_date(A.單據日期,'yyyymmdd') else to_date(A.單據日期,'yyyymmdd')+1 end,'yyyymmdd')||B.時間五,'yyyymmddhh24miss')- 
	to_date(trim(A.單據日期)||B.時間一,'yyyymmddhh24miss'))*24) 總耗時,
	((F.本月應發金額-F.遲到早退扣支-F.調補扣支)/(30*8)) 時薪
FROM
	FIL0030 A
	INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
	INNER JOIN FIL0010 E ON A.填表人 = E.員工編號
	LEFT JOIN ViewFILHS02 F ON substr(F.年月,1,6)=SUBSTR(A.單據日期,1,6) AND F.員工編號=TO_CHAR(SUBSTR(A.填表人,1,10))
WHERE
	A.單據類別 = 'C41' AND
	(B.製程代碼 = 'C31H' OR B.製程代碼 = 'C31K' )	AND
	A.填表人 <> ' '	 AND
	A.單據日期>'2025'
	) A
INNER JOIN FIL0010 D ON A.作業人員 = D.員工編號
INNER JOIN ViewFIL310N E ON E.代碼 = A.製程代碼
);

-- Oracle user_views
CREATE VIEW "VIEWFIL404ZP" ("單別", "單號", "單據日期", "製程", "總耗時", "直接人工") AS (Select 
	A.單別,
	A.單號,
	A.單據日期,
	A.製程,
	SUM(A.總耗時) 總耗時,
	SUM(A.直接人工) 直接人工
FROM 	
	ViewFIL404ZO A
GROUP BY	
	A.單別,
	A.單號,
	A.單據日期,
	A.製程
);

-- Oracle user_views
CREATE VIEW "VIEWFIL404ZQ" ("單別", "單號", "入庫數") AS (
Select 
	A.單別,
	A.單號,
	A.入庫數
FROM	
（	SELECT
		/*印刷(C31A)*/
		A.單別,
		A.單號,
		A.PLC抓取米數-A.線內不良剔除數 入庫數
	FROM
		VIEWFIL404AA A

	UNION

	SELECT
		/*上臘(C32D)*/
		A.單別,
		A.單號,
		A.PLC抓取米數-A.線內不良剔除數 入庫數
	FROM
		VIEWFIL404A5A A	

	UNION

	SELECT
		/*淋膜(C31B)*/
		A.單別,
		A.單號,
		A.PLC抓取米數-A.線內不良剔除數 入庫數
	FROM
		VIEWFIL404BA A		

	UNION

	SELECT
		/*積層(C31C)*/
		A.單別,
		A.單號,
		A.PLC抓取米數-A.線內不良剔除數 入庫數
	FROM
		VIEWFIL404CA A			

	UNION

	SELECT
		/*裁切(C31D)*/
		A.單別,
		A.單號,
		A.PLC抓取米數+上次尾數-A.故障米數-A.客戶要求數 入庫數
	FROM
		VIEWFIL404DA A	

	UNION

	SELECT
		/*印刷檢品(C31H)*/
		A.單別,
		A.單號,
		A.PLC抓取米數-A.線內不良剔除數 入庫數
	FROM
		VIEWFIL2066 A	

	UNION

	SELECT
		/*裁切檢品(C31K)*/
		A.單別,
		A.單號,
		A.PLC抓取米數-A.線內不良剔除數 入庫數
	FROM
		VIEWFIL2068 A		

	UNION

	SELECT
		/*製袋(C31E)*/
		A.單別,
		A.單號,
		A.繳庫總袋數 入庫數
	FROM
		ViewFIL404EA A			
		
	UNION

	SELECT
		/*氣閥(C31F)*/
		A.單別,
		A.單號,
		A.繳庫總袋數 入庫數
	FROM
		ViewFIL404FA A				
		
	UNION

	SELECT
		/*鐵條(C31G)*/
		A.單別,
		A.單號,
		A.繳庫總袋數 入庫數
	FROM
		ViewFIL404GA A
		
	UNION

	SELECT
		/*成捲(C31I)*/
		A.單別,
		A.單號,
		A.全部捲數 入庫數
	FROM
		ViewFIL404K2 A		
) A
INNER JOIN FIL0030 B ON B.單據類別=A.單別 AND B.單據編號=A.單號
WHERE
	B.單據日期 > '2025'
);

-- Oracle user_views
CREATE VIEW "VIEWFIL404ZR" ("總標籤", "箱號", "產品標籤", "製令單號", "數量", "單別", "單號", "製程代碼", "名稱") AS With tmp as (
SELECT 
	A.單別||'_'||A.單號 總標籤,
	C.異動數量 箱號,
	A.文字一 產品標籤,
	D.歸屬編號 製令單號,
	A.數字一 數量,
	A.單別,
	A.單號,
	B.製程代碼,
	E.名稱
FROM 
	FIL00401 A
	INNER JOIN FIL0031 B ON A.單別 = B.單別 AND A.單號 = B.單號
	INNER JOIN FIL0040 C ON A.單別 = c.單據類別 AND A.單號 = C.單據編號 AND A.序號=C.單據序號
	INNER JOIN FIL0030 D ON D.單據類別 = A.單別 AND D.單據編號 = A.單號
	INNER JOIN ViewFIL310N E ON E.代碼類別 = '製程代碼' AND E.代碼 = B.製程代碼
WHERE
	A.單別 = 'C41' AND
	B.製程代碼 = 'C31I'
	
UNION ALL

SELECT 
	A.單據類別||'_'||A.單據編號 總標籤,
	A.異動數量 箱號,
	A.廠客品號||'-'||trim(TO_CHAR(A.異動數量,'0009')) 產品標籤,
	A.廠客品號 製令單號,
	A.贈品數量 數量,
	A.單據類別,
	A.單據編號,
	A.單據類別,
	E.名稱
FROM 
	FIL0040 A
	INNER JOIN ViewFIL310N E ON E.代碼類別 = '單據類別' AND E.代碼 = A.單據類別
WHERE
	A.單據類別 = 'E37'	
	
UNION ALL

SELECT 
	A.單據類別||'_'||A.單據編號||'-'||TRIM(TO_CHAR(QRNO,'009')) 總標籤,
	A.異動數量 箱號,
	D.歸屬編號||'-'||trim(TO_CHAR(A.異動數量,'0009')) 產品標籤,
	D.歸屬編號 製令單號,
	A.贈品數量 數量,
	A.單據類別,
	A.單據編號,
	C.製程代碼,
	E.名稱
FROM 
	FIL0040 A
	INNER JOIN FIL0041 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號 AND A.單據序號 = B.序號
	INNER JOIN FIL0031 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號	
	INNER JOIN FIL0030 D ON D.單據類別 = A.單據類別 AND D.單據編號 = A.單據編號
	INNER JOIN ViewFIL310N E ON E.代碼類別 = '製程代碼' AND E.代碼 = C.製程代碼
WHERE
	A.單據類別 = 'C41' AND
	A.異動類別 = 'A' AND
	C.製程代碼 = 'C31E' AND
	QRNO > 0
)	
Select
	DECODE (NVL(B.最後總標籤,' '),' ',A.總標籤,B.最後總標籤) 總標籤,
	A.箱號,
	A.產品標籤,
	A.製令單號,
	A.數量,
	A.單別,
	A.單號,
	A.製程代碼,
	A.名稱
from 
	tmp A
	left join fil0044b B on B.產品標籤 = A.產品標籤;

-- Oracle user_views
CREATE VIEW "VIEWFIL404ZS" ("總標籤", "製令單號", "製程名稱") AS ( 
SELECT DISTINCT
	A.總標籤,
	A.製令單號,
	A.名稱 製程名稱
FROM 
	ViewFIL404ZR A
);

-- Oracle user_views
CREATE VIEW "VIEWFIL4050" ("單別", "單號", "排程日期", "公司代碼", "公司名稱", "製程代碼", "製程名稱", "工站代碼", "工站名稱", "機台代碼", "機台名稱", "部門編號", "部門名稱", "確認碼", "開放領料", "備註", "簽核系統", "簽核狀態", "流水編號", "填表人", "填表人姓名", "填表日", "最後更新者", "更新者姓名", "最後更新日", "員工流水編號", "主旨", "結案") AS (                                                                                                                                                      SELECT
	A.單據類別 單別,
	A.單據編號 單號,
	A.單據日期 排程日期,
	A.公司代碼,
	nvl(F.名稱, ' ') 公司名稱,
	B.製程代碼,
	nvl(D.名稱, ' ') 製程名稱,
	B.工站代碼,
	nvl(G.名稱, ' ') 工站名稱,
	B.機台代碼,
	nvl(C.名稱, ' ') 機台名稱,
	A.部門編號,
	nvl(E.部門名稱, ' ') 部門名稱,
	A.確認碼,
	A.邏輯值一 開放領料,
	A.備註, 
	A.簽核系統, 
	nvl(Z3.簽核狀態, '0') 簽核狀態,
	A.流水編號,
	A.填表人,
	nvl(Z1.員工姓名,' ') 填表人姓名, 
	A.填表日, 
	A.最後更新者,
	nvl(Z2.員工姓名,' ') 更新者姓名, 
	A.最後更新日,
	Z1.Serial_Num 員工流水編號,
	A.單據編號  主旨,
	decode(A.確認碼,'Y',1,0) 結案
FROM
	FIL0030 A
	INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
	LEFT JOIN ViewFIL310P C ON B.機台代碼 = C.代碼
	LEFT JOIN ViewFIL310N D ON B.製程代碼 = D.代碼
	LEFT JOIN ViewFIL0012 E ON A.部門編號 = E.部門編號
	LEFT JOIN ViewFIL0011 F ON A.公司代碼 = F.代碼
	LEFT JOIN ViewFIL310O G ON B.工站代碼 = G.代碼
	LEFT JOIN FIL0010 Z1 ON A.填表人 = Z1.員工編號
	LEFT JOIN FIL0010 Z2 ON A.最後更新者 = Z2.員工編號
	LEFT JOIN ViewOfObjProperties Z3 ON A.流水編號 = Z3.單據流水號
WHERE
	A.單據類別 = 'C4L');

-- Oracle user_views
CREATE VIEW "VIEWFIL4051" ("單別", "單號", "序號", "料號", "品名", "規格", "請領數量", "庫存異動數", "單位代碼", "單位名稱", "備註說明", "流水編號", "最後更新者", "更新者姓名", "最後更新日") AS (
SELECT 
	A.單據類別 單別, 
	A.單據編號 單號,
	A.單據序號 序號,
	A.產品編號 料號,
	nvl(C.品名, ' ') 品名,
	nvl(C.規格, ' ') 規格,
	A.異動數量 請領數量,
	A.數值4 庫存異動數,
	A.單位代碼,
	nvl(D.名稱, ' ') 單位名稱,
	A.備註說明,
	A.流水編號,
	A.最後更新者,
	nvl(Z1.員工姓名,' ') 更新者姓名,
	A.最後更新日
FROM 
	FIL0040 A
	LEFT JOIN FIL0012 C ON A.產品編號 = C.產品編號
	LEFT JOIN ViewFIL3103 D ON A.單位代碼 = D.代碼
	LEFT JOIN FIL0010 Z1 ON A.最後更新者 = Z1.員工編號
WHERE
	A.單據類別 = 'C4L');

-- Oracle user_views
CREATE VIEW "VIEWFIL405A" ("單別", "單號", "請領數量") AS (                                                                                                                                                      SELECT 
	A.單據類別 單別, 
	A.單據編號 單號,
	sum(A.異動數量) 請領數量
FROM 
	FIL0040 A
WHERE
	A.單據類別 = 'C4L'
GROUP BY
	A.單據類別, 
	A.單據編號);

-- Oracle user_views
CREATE VIEW "VIEWFIL405B" ("單別", "單號", "製令單別", "製令單號", "加工別", "色順數", "料號", "請領數量") AS (                                                                                                                                                      
SELECT 
	A.單別 單別, 
	A.單號 單號,
	A.文字一 製令單別,
	A.文字二 製令單號,
	A.文字三 加工別,
	A.數字一 色順數, 
	B.產品編號 料號,	
	sum(A.數字四) 請領數量
FROM 
	FIL00401 A
	INNER JOIN FIL0040 B ON B.單據類別 = A.單別 AND B.單據編號 = A.單號 AND B.單據序號 = A.序號
WHERE
	A.單別 = 'C4L'
GROUP BY
	A.單別, 
	A.單號,
	A.文字一,
	A.文字二,
	A.文字三,
	A.數字一, 
	B.產品編號
	);

-- Oracle user_views
CREATE VIEW "VIEWFIL4060" ("單別", "單號", "發料日期", "請領單別", "請領單號", "排程日期", "公司代碼", "公司名稱", "製程代碼", "製程名稱", "工站代碼", "工站名稱", "機台代碼", "機台名稱", "部門編號", "部門名稱", "備註", "已簽收", "簽核系統", "簽核狀態", "流水編號", "填表人", "填表人姓名", "填表日", "最後更新者", "更新者姓名", "最後更新日") AS (                                                                                                                                                      SELECT
	A.單據類別 單別,
	A.單據編號 單號,
	A.單據日期 發料日期,
	A.歸屬類別 請領單別,
	A.歸屬編號 請領單號,
	H.單據日期 排程日期,
	A.公司代碼,
	nvl(F.名稱, ' ') 公司名稱,
	B.製程代碼,
	nvl(D.名稱, ' ') 製程名稱,
	B.工站代碼,
	nvl(G.名稱, ' ') 工站名稱,
	B.機台代碼,
	nvl(C.名稱, ' ') 機台名稱,
	A.部門編號,
	nvl(E.部門名稱, ' ') 部門名稱,
	A.備註, 
	DECODE(nvl(dbms_lob.getlength(I.圖檔),0),0,0,1) 已簽收,
	A.簽核系統, 
	nvl(Z3.簽核狀態, ' ') 簽核狀態,
	A.流水編號,
	A.填表人,
	nvl(Z1.員工姓名,' ') 填表人姓名, 
	A.填表日, 
	A.最後更新者,
	nvl(Z2.員工姓名,' ') 更新者姓名, 
	A.最後更新日
FROM
	FIL0030 A
	INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
	INNER JOIN FIL0030 H ON A.歸屬類別 = H.單據類別 AND A.歸屬編號 = H.單據編號
	LEFT JOIN ViewFIL310P C ON B.機台代碼 = C.代碼
	LEFT JOIN ViewFIL310N D ON B.製程代碼 = D.代碼
	LEFT JOIN ViewFIL0012 E ON A.部門編號 = E.部門編號
	LEFT JOIN ViewFIL0011 F ON A.公司代碼 = F.代碼
	LEFT JOIN ViewFIL310O G ON B.工站代碼 = G.代碼
	LEFT JOIN FIL0037 I ON A.單據類別 = I.製令單別 AND A.單據編號 = I.製令單號 AND I.材料序號 = 0
	LEFT JOIN FIL0010 Z1 ON A.填表人 = Z1.員工編號
	LEFT JOIN FIL0010 Z2 ON A.最後更新者 = Z2.員工編號
	LEFT JOIN ViewFIL0030 Z3 ON A.簽核系統 = Z3.簽核系統 AND A.單據編號 = Z3.單號
WHERE
	A.單據類別 = 'C4M');

-- Oracle user_views
CREATE VIEW "VIEWFIL4061" ("單別", "單號", "序號", "料號", "請領單別", "請領單號", "請領料號", "批號", "品名", "規格", "發料日期", "發料數量", "單位代碼", "單位名稱", "倉庫代碼", "倉庫名稱", "製程代碼", "備註說明", "流水編號", "最後更新者", "更新者姓名", "最後更新日") AS (
SELECT 
	A.單據類別 單別, 
	A.單據編號 單號,
	A.單據序號 序號,
	A.產品編號 料號,
	B.歸屬類別 請領單別,
	B.歸屬編號 請領單號,
	A.文數字1 請領料號,
	C.批號,
	nvl(D.品名, ' ') 品名,
	nvl(D.規格, ' ') 規格,
	A.異動日期 發料日期,
	A.異動數量 發料數量,
	A.單位代碼,
	nvl(F.名稱, ' ') 單位名稱,
	A.倉庫代碼,
	nvl(E.名稱, ' ') 倉庫名稱,
	nvl(G.製程代碼,' ') 製程代碼,
	A.備註說明,
	A.流水編號,
	A.最後更新者,
	nvl(Z1.員工姓名,' ') 更新者姓名,
	A.最後更新日
FROM 
	FIL0040 A
	INNER JOIN FIL0030 B ON A.單據類別 = B.單據類別 AND A.單據編號 = B.單據編號
	INNER JOIN FIL0031 G ON A.單據類別 = G.單別 AND A.單據編號 = G.單號
	INNER JOIN FIL0041 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號 AND A.單據序號 = C.序號
	LEFT JOIN FIL0012 D ON A.產品編號 = D.產品編號
	LEFT JOIN ViewFIL3106 E ON A.倉庫代碼 = E.代碼
	LEFT JOIN ViewFIL3103 F ON A.單位代碼 = F.代碼
	LEFT JOIN FIL0010 Z1 ON A.最後更新者 = Z1.員工編號
WHERE
	A.單據類別 = 'C4M');

-- Oracle user_views
CREATE VIEW "VIEWFIL406A" ("單別", "單號", "發料數量") AS (                                                                                                                                                      SELECT 
	A.單據類別 單別, 
	A.單據編號 單號,
	sum(A.異動數量) 發料數量
FROM 
	FIL0040 A
WHERE
	A.單據類別 = 'C4M'
GROUP BY
	A.單據類別, 
	A.單據編號);

-- Oracle user_views
CREATE VIEW "VIEWFIL4070" ("單別", "單號", "退料日期", "公司代碼", "公司名稱", "製程代碼", "製程名稱", "機台代碼", "機台名稱", "部門編號", "部門名稱", "備註", "簽核系統", "簽核狀態", "流水編號", "填表人", "填表人姓名", "填表日", "最後更新者", "更新者姓名", "最後更新日") AS (                                                                                                                                                      SELECT
	A.單據類別 單別,
	A.單據編號 單號,
	A.單據日期 退料日期,
	A.公司代碼,
	nvl(F.名稱, ' ') 公司名稱,
	B.製程代碼,
	nvl(D.名稱, ' ') 製程名稱,
	B.機台代碼,
	nvl(C.名稱, ' ') 機台名稱,
	A.部門編號,
	nvl(E.部門名稱, ' ') 部門名稱,
	A.備註, 
	A.簽核系統, 
	nvl(Z3.簽核狀態, ' ') 簽核狀態,
	A.流水編號,
	A.填表人,
	nvl(Z1.員工姓名,' ') 填表人姓名, 
	A.填表日, 
	A.最後更新者,
	nvl(Z2.員工姓名,' ') 更新者姓名, 
	A.最後更新日
FROM
	FIL0030 A
	INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
	LEFT JOIN ViewFIL310P C ON B.機台代碼 = C.代碼
	LEFT JOIN ViewFIL310N D ON B.製程代碼 = D.代碼
	LEFT JOIN ViewFIL0012 E ON A.部門編號 = E.部門編號
	LEFT JOIN ViewFIL0011 F ON A.公司代碼 = F.代碼
	LEFT JOIN FIL0010 Z1 ON A.填表人 = Z1.員工編號
	LEFT JOIN FIL0010 Z2 ON A.最後更新者 = Z2.員工編號
	LEFT JOIN ViewFIL0030 Z3 ON A.簽核系統 = Z3.簽核系統 AND A.單據編號 = Z3.單號
WHERE
	A.單據類別 = 'C4N');

-- Oracle user_views
CREATE VIEW "VIEWFIL4071" ("單別", "單號", "序號", "料號", "批號", "品名", "規格", "退料數量", "不良數量", "單位代碼", "單位名稱", "製令單別", "製令單號", "公司代碼", "公司名稱", "訂單單別", "訂單單號", "客戶編號", "客戶名稱", "產品編號", "產品名稱", "產品規格", "備註說明", "流水編號", "最後更新者", "更新者姓名", "最後更新日") AS (                                                                                                                                                      SELECT 
	A.單據類別 單別, 
	A.單據編號 單號,
	A.單據序號 序號,
	A.產品編號 料號,
	C.批號,
	nvl(D.品名, ' ') 品名,
	nvl(D.規格, ' ') 規格,
	A.異動數量 退料數量,
	A.贈品數量 不良數量,
	A.單位代碼,
	nvl(E.名稱, ' ') 單位名稱,
	A.前置單別 製令單別,
	A.前置單號 製令單號,
	B.公司代碼,
	B.公司名稱,
	B.訂單單別,
	B.訂單單號,
	B.客戶編號,
	B.客戶名稱,
	B.產品編號,
	B.產品名稱,
	B.產品規格,
	A.備註說明,
	A.流水編號,
	A.最後更新者,
	nvl(Z1.員工姓名,' ') 更新者姓名,
	A.最後更新日
FROM 
	FIL0040 A
	INNER JOIN ViewFIL4030 B ON A.前置單別 = B.製令單別 AND A.前置單號 = B.製令單號
	INNER JOIN FIL0041 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號 AND A.單據序號 = C.序號
	LEFT JOIN FIL0012 D ON A.產品編號 = D.產品編號
	LEFT JOIN ViewFIL3103 E ON A.單位代碼 = E.代碼
	LEFT JOIN FIL0010 Z1 ON A.最後更新者 = Z1.員工編號
WHERE
	A.單據類別 = 'C4N');

-- Oracle user_views
CREATE VIEW "VIEWFIL407A" ("單別", "單號", "退料數量", "不良數量") AS (                                                                                                                                                      SELECT 
	A.單據類別 單別, 
	A.單據編號 單號,
	sum(A.異動數量) 退料數量,
	sum(A.贈品數量) 不良數量
FROM 
	FIL0040 A
WHERE
	A.單據類別 = 'C4N'
GROUP BY
	A.單據類別, 
	A.單據編號);

-- Oracle user_views
CREATE VIEW "VIEWFIL4080" ("單別", "單號", "退料日期", "公司代碼", "公司名稱", "製程代碼", "製程名稱", "機台代碼", "機台名稱", "部門編號", "部門名稱", "備註", "簽核系統", "簽核狀態", "流水編號", "填表人", "填表人姓名", "填表日", "最後更新者", "更新者姓名", "最後更新日") AS (                                                                                                                                                      SELECT
	A.單據類別 單別,
	A.單據編號 單號,
	A.單據日期 退料日期,
	A.公司代碼,
	nvl(F.名稱, ' ') 公司名稱,
	B.製程代碼,
	nvl(D.名稱, ' ') 製程名稱,
	B.機台代碼,
	nvl(C.名稱, ' ') 機台名稱,
	A.部門編號,
	nvl(E.部門名稱, ' ') 部門名稱,
	A.備註, 
	A.簽核系統, 
	nvl(Z3.簽核狀態, ' ') 簽核狀態,
	A.流水編號,
	A.填表人,
	nvl(Z1.員工姓名,' ') 填表人姓名, 
	A.填表日, 
	A.最後更新者,
	nvl(Z2.員工姓名,' ') 更新者姓名, 
	A.最後更新日
FROM
	FIL0030 A
	INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
	LEFT JOIN ViewFIL310P C ON B.機台代碼 = C.代碼
	LEFT JOIN ViewFIL310N D ON B.製程代碼 = D.代碼
	LEFT JOIN ViewFIL0012 E ON A.部門編號 = E.部門編號
	LEFT JOIN ViewFIL0011 F ON A.公司代碼 = F.代碼
	LEFT JOIN FIL0010 Z1 ON A.填表人 = Z1.員工編號
	LEFT JOIN FIL0010 Z2 ON A.最後更新者 = Z2.員工編號
	LEFT JOIN ViewFIL0030 Z3 ON A.簽核系統 = Z3.簽核系統 AND A.單據編號 = Z3.單號
WHERE
	A.單據類別 = 'C4O');

-- Oracle user_views
CREATE VIEW "VIEWFIL4081" ("單別", "單號", "序號", "料號", "批號", "品名", "規格", "退料日期", "實收數量", "單位代碼", "單位名稱", "倉庫代碼", "倉庫名稱", "製令單別", "製令單號", "公司代碼", "公司名稱", "訂單單別", "訂單單號", "客戶編號", "客戶名稱", "產品編號", "產品名稱", "產品規格", "備註說明", "流水編號", "最後更新者", "更新者姓名", "最後更新日") AS (                                                                                                                                                      SELECT 
	A.單據類別 單別, 
	A.單據編號 單號,
	A.單據序號 序號,
	A.產品編號 料號,
	C.批號,
	nvl(D.品名, ' ') 品名,
	nvl(D.規格, ' ') 規格,
	A.異動日期 退料日期,
	A.異動數量 實收數量,
	A.單位代碼,
	nvl(F.名稱, ' ') 單位名稱,
	A.倉庫代碼,
	nvl(E.名稱, ' ') 倉庫名稱,
	A.前置單別 製令單別,
	A.前置單號 製令單號,
	B.公司代碼,
	B.公司名稱,
	B.訂單單別,
	B.訂單單號,
	B.客戶編號,
	B.客戶名稱,
	B.產品編號,
	B.產品名稱,
	B.產品規格,
	A.備註說明,
	A.流水編號,
	A.最後更新者,
	nvl(Z1.員工姓名,' ') 更新者姓名,
	A.最後更新日
FROM 
	FIL0040 A
	INNER JOIN ViewFIL4030 B ON A.前置單別 = B.製令單別 AND A.前置單號 = B.製令單號
	INNER JOIN FIL0041 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號 AND A.單據序號 = C.序號
	LEFT JOIN FIL0012 D ON A.產品編號 = D.產品編號
	LEFT JOIN ViewFIL3106 E ON A.倉庫代碼 = E.代碼
	LEFT JOIN ViewFIL3103 F ON A.單位代碼 = F.代碼
	LEFT JOIN FIL0010 Z1 ON A.最後更新者 = Z1.員工編號
WHERE
	A.單據類別 = 'C4O');

-- Oracle user_views
CREATE VIEW "VIEWFIL408A" ("單別", "單號", "實收數量") AS (                                                                                                                                                      SELECT 
	A.單據類別 單別, 
	A.單據編號 單號,
	sum(A.異動數量) 實收數量
FROM 
	FIL0040 A
WHERE
	A.單據類別 = 'C4O'
GROUP BY
	A.單據類別, 
	A.單據編號);

-- Oracle user_views
CREATE VIEW "VIEWFIL408B" ("請領單別", "請領單號", "排程日期", "製程代碼", "製程名稱", "工站代碼", "工站名稱", "機台代碼", "機台名稱", "料號", "品名", "規格", "公司代碼", "公司名稱", "請領數量", "核准數量", "發料數量", "未發料數") AS (
SELECT 
	A.請領單別,
	A.請領單號,
	B.單據日期 排程日期,
	C.製程代碼,
	nvl(D.名稱, ' ') 製程名稱,
	C.工站代碼,
	nvl(E.名稱, ' ') 工站名稱,
	A.機台代碼,
	nvl(F.名稱, ' ') 機台名稱,
	A.料號,
	nvl(G.品名, ' ') 品名,
	nvl(G.規格, ' ') 規格,
	B.公司代碼,
	nvl(H.名稱, ' ') 公司名稱,
	A.請領數量,
	A.核准數量,
	A.發料數量,
	greatest(0, A.核准數量 - A.發料數量) 未發料數
FROM 
	(	SELECT
			A.請領單別,
			A.請領單號,
			A.機台代碼,
			A.料號,
			sum(A.請領數量) 請領數量,
			sum(A.核准數量) 核准數量,
			sum(A.發料數量) 發料數量
		FROM
			(	SELECT
					decode(A.單據類別, 'C4L', A.單據類別, B.歸屬類別) 請領單別,
					decode(A.單據類別, 'C4L', A.單據編號, B.歸屬編號) 請領單號,
					C.機台代碼,
					decode(A.單據類別, 'C4L',A.產品編號,A.文數字1) 料號,
					decode(A.單據類別, 'C4L', A.異動數量, 0) 請領數量,
					decode(A.單據類別, 'C4L', A.異動數量, 0)*B.邏輯值一 核准數量,
					decode(A.單據類別, 'C4M', A.異動數量, 0) 發料數量
				FROM 
					FIL0040 A
					INNER JOIN FIL0030 B ON A.單據類別 = B.單據類別 AND A.單據編號 = B.單據編號 
					/*特殊欄位*/
					INNER JOIN FIL0031 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號
				WHERE
					A.單據類別 between 'C4L' and 'C4M'
			) A
		GROUP BY
			A.請領單別,
			A.請領單號,
			A.機台代碼,
			A.料號
	) A
	INNER JOIN FIL0030 B ON A.請領單別 = B.單據類別 AND A.請領單號 = B.單據編號
	/*特殊欄位*/
	INNER JOIN FIL0031 C ON A.請領單別 = C.單別 AND A.請領單號 = C.單號
	/*製程*/
	LEFT JOIN ViewFIL310N D ON C.製程代碼 = D.代碼
	/*工站*/
	LEFT JOIN ViewFIL310O E ON C.工站代碼 = E.代碼
	/*機台*/
	LEFT JOIN ViewFIL310P F ON A.機台代碼 = F.代碼
	/*料號*/
	LEFT JOIN FIL0012 G ON A.料號 = G.產品編號
	/*公司別*/
	LEFT JOIN ViewFIL0011 H ON B.公司代碼 = H.代碼
WHERE
	A.請領數量 > 0);

-- Oracle user_views
CREATE VIEW "VIEWFIL408C" ("請領單別", "請領單號", "請領數量", "發料數量") AS (                                                                                                                                                      SELECT
	A.請領單別,
	A.請領單號,
	sum(A.請領數量) 請領數量,
	sum(A.發料數量) 發料數量
FROM
	(	SELECT
			decode(A.單據類別, 'C4L', A.單據類別, B.歸屬類別) 請領單別,
			decode(A.單據類別, 'C4L', A.單據編號, B.歸屬編號) 請領單號,
			decode(A.單據類別, 'C4L', A.異動數量, 0) 請領數量,
			decode(A.單據類別, 'C4M', A.異動數量, 0) 發料數量
		FROM 
			FIL0040 A
			INNER JOIN FIL0030 B ON A.單據類別 = B.單據類別 AND A.單據編號 = B.單據編號
		WHERE
			A.單據類別 between 'C4L' and 'C4M'
	) A
GROUP BY
	A.請領單別,
	A.請領單號);

-- Oracle user_views
CREATE VIEW "VIEWFIL4090" ("單位年月", "生產製令筆數") AS (
SELECT 
	A.單位年月,
	COUNT(A.製令單號) 生產製令筆數
FROM
	(
	SELECT DISTINCT
		NVL(C.部門編號,'H13000')||SUBSTR(A.單據日期,1,6) 單位年月,
		(A.歸屬編號) 製令單號
	FROM
		FIL0030 A
		INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
		LEFT JOIN FIL0020 C ON C.製程代碼 = B.製程代碼
	WHERE
		A.單據類別 = 'C41' 
	) A
GROUP BY
	A.單位年月
);

-- Oracle user_views
CREATE VIEW "VIEWFIL4101" ("單別", "單號", "作業區域", "機台名稱", "巡檢日期", "製令單別", "製令單號", "簽核系統", "簽核狀態", "公司代碼", "公司名稱", "訂單單別", "訂單單號", "客戶編號", "客戶名稱", "產品編號", "產品名稱", "成品尺寸", "訂單數量", "作業速率", "檢驗時間", "箱號", "缺失說明", "備註", "流水編號", "填表人", "填表人姓名", "填表日", "最後更新者", "更新者姓名", "最後更新日", "機台狀態") AS (                                                                                                                                            SELECT
	A.單據類別 單別,
	A.單據編號 單號,
	C.機台代碼 作業區域,
	D.名稱 機台名稱,
	A.單據日期 巡檢日期,
	A.歸屬類別 製令單別,
	A.歸屬編號 製令單號,
	A.簽核系統,
	nvl(Z3.簽核狀態, '0') 簽核狀態,
	B.公司代碼,
	B.公司名稱,
	B.訂單單別,
	B.訂單單號,
	B.客戶編號,
	B.客戶名稱,
	B.產品編號,
	B.產品名稱,
	B.產品規格 成品尺寸,
	B.訂購數量 訂單數量,
	C.作業速率,
	C.檢驗時間,
	C.箱號,
	A.備註 缺失說明, 
	C.備註,
	A.流水編號,
	A.填表人,
	nvl(Z1.員工姓名,' ') 填表人姓名, 
	A.填表日, 
	A.最後更新者,
	nvl(Z2.員工姓名,' ') 更新者姓名, 
	A.最後更新日,
	C.機台狀態
FROM
	FIL0030 A
	INNER JOIN FIL003G C ON A.流水編號 = C.主檔流水編號
	INNER JOIN ViewFIL310P D ON C.機台代碼 = D.代碼
	LEFT JOIN ViewFIL4030 B ON A.歸屬類別 = B.製令單別 AND A.歸屬編號 = B.製令單號	
	LEFT JOIN FIL0010 Z1 ON A.填表人 = Z1.員工編號
	LEFT JOIN FIL0010 Z2 ON A.最後更新者 = Z2.員工編號
	LEFT JOIN ViewFIL0030 Z3 ON A.簽核系統 = Z3.簽核系統 AND A.單據編號 = Z3.單號	
WHERE
	A.單據類別 = 'C47');

-- Oracle user_views（在 Oracle 已失效）
CREATE VIEW "VIEWFIL41012" ("單別", "單號", "序號", "子序", "半成品編號", "作業日期", "機台代碼", "機台名稱", "庫別代碼", "庫別名稱", "異動日期", "異動數量", "製令單號") AS (                                                                                                                                                      SELECT 
	A.單別,
	A.單號,
	A.序號,
	A.子序,
	A.半成品編號,
	A.作業日期,
	A.機台代碼,
	nvl(B.名稱, ' ') 機台名稱,
	A.庫別代碼,
	nvl(C.名稱, ' ') 庫別名稱,
	A.異動日期,
	A.異動數量,
	regexp_substr(A.半成品編號, '[^-]+', 1, 1) 製令單號
FROM 
	(	SELECT 
			A.單據類別 單別,
			A.單據編號 單號,
			A.單據序號 序號,
			0 子序,
			A.文數字1 半成品編號,
			B.單據日期 作業日期,
			C.機台代碼,
			A.異動日期,
			A.倉庫代碼 庫別代碼,
			A.贈品數量 異動數量
		FROM 
			FIL0040 A
			INNER JOIN FIL0030 B ON A.單據類別 = B.單據類別 AND A.單據編號 = B.單據編號
			INNER JOIN FIL0031 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號
		WHERE
			A.單據類別 = 'C41' AND
			A.異動類別 = 'A' AND
			A.文數字1 != ' ' AND
			A.結案碼 = 'Y'
			
		union
		
		SELECT 
			B.單據類別 單別,
			B.單據編號 單號,
			B.單據序號 序號,
			A.序號 子序,
			A.半成品編號,
			A.生產日期 作業日期,
			A.生產機台 機台代碼,
			A.領用日期 異動日期,
			A.庫別代碼,
			A.領用數量 * -1 異動數量
		FROM 
			FIL0045 A
			/*異動明細*/
			INNER JOIN FIL0040 B ON A.流水編號 = B.流水編號
	) A
	LEFT JOIN ViewFIL310P B ON A.機台代碼 = B.代碼
	LEFT JOIN ViewFIL3106 C ON A.庫別代碼 = C.代碼);

-- Oracle user_views（在 Oracle 已失效）
CREATE VIEW "VIEWFIL41013" ("半成品編號", "作業日期", "機台代碼", "庫別代碼", "入庫數量", "領用數量", "庫存數量") AS (                                                                                                                                                      SELECT 
	A.半成品編號,
	A.作業日期,
	A.機台代碼,
	A.庫別代碼,
	sum(A.入庫數量) 入庫數量,
	sum(A.領用數量) 領用數量,
	sum(A.入庫數量 - A.領用數量) 庫存數量
FROM
	(	SELECT 
			A.文數字1 半成品編號,
			B.單據日期 作業日期,
			C.機台代碼,
			A.倉庫代碼 庫別代碼,
			A.贈品數量 入庫數量,
			0 領用數量
		FROM 
			FIL0040 A
			INNER JOIN FIL0030 B ON A.單據類別 = B.單據類別 AND A.單據編號 = B.單據編號
			INNER JOIN FIL0031 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號
		WHERE
			A.單據類別 = 'C41' AND
			A.異動類別 = 'A' AND
			A.文數字1 != ' ' AND
			A.結案碼 = 'Y'
			
		union
		
		SELECT 
			A.半成品編號,
			A.生產日期 作業日期,
			A.生產機台 機台代碼,
			A.庫別代碼,
			0 入庫數量,
			A.領用數量
		FROM 
			FIL0045 A
	) A
GROUP BY
	A.半成品編號,
	A.作業日期,
	A.機台代碼,
	A.庫別代碼);

-- Oracle user_views
CREATE VIEW "VIEWFIL4102" ("單別", "單號", "作業區域", "巡檢日期", "製令單號", "箱號", "檢驗時間", "次數") AS (                                                                                                                                            SELECT
	A.單據類別 單別,
	A.單據編號 單號,
	C.機台代碼 作業區域,
	A.單據日期 巡檢日期,
	A.歸屬編號 製令單號,
	C.箱號,
	C.檢驗時間,
	row_number() over (partition by C.機台代碼, A.歸屬編號, A.單據日期 order by C.檢驗時間 asc) as 次數
FROM
	FIL0030 A
	INNER JOIN FIL003G C ON A.流水編號 = C.主檔流水編號
WHERE
	A.單據類別 = 'C47');

-- Oracle user_views
CREATE VIEW "VIEWFIL4103" ("條碼", "單別", "單號", "序號", "半成品編號", "作業日期", "製令單別", "製令單號", "公司代碼", "公司名稱", "產品名稱", "產品規格", "作業人員", "作業員姓名", "製程代碼", "製程名稱", "機台代碼", "機台名稱", "異動日期", "庫別代碼", "庫別名稱", "異動數量", "備註說明") AS (                                                                                                                                                      SELECT 
	A.條碼,
	A.單別,
	A.單號,
	A.序號,
	A.半成品編號,
	A.作業日期,
	A.製令單別,
	A.製令單號,
	D.公司代碼,
	D.公司名稱,
	D.產品名稱,
	D.產品規格,
	A.作業人員,
	nvl(E.員工姓名, ' ') 作業員姓名,
	A.製程代碼,
	nvl(F.名稱, ' ') 製程名稱,
	A.機台代碼,
	nvl(B.名稱, ' ') 機台名稱,
	A.異動日期,
	A.庫別代碼,
	nvl(C.名稱, ' ') 庫別名稱,
	A.異動數量,
	A.備註說明
FROM 
	(	SELECT 
			A.流水編號 條碼,
			A.單據類別 單別,
			A.單據編號 單號,
			A.單據序號 序號,
			A.文數字1 半成品編號,
			B.單據日期 作業日期,
			B.歸屬類別 製令單別,
			B.歸屬編號 製令單號,
			B.業務員 作業人員,
			C.製程代碼,
			C.機台代碼,
			A.異動日期,
			A.倉庫代碼 庫別代碼,
			A.贈品數量 異動數量,
			A.備註說明
		FROM 
			FIL0040 A
			INNER JOIN FIL0030 B ON A.單據類別 = B.單據類別 AND A.單據編號 = B.單據編號
			INNER JOIN FIL0031 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號
		WHERE
			A.單據類別 = 'C41' AND
			A.異動類別 = 'A' AND
			A.文數字1 != ' ' AND
			A.結案碼 = 'Y'
			
		union
		
		SELECT 
			A.領用編號 條碼,
			B.單據類別 單別,
			B.單據編號 單號,
			B.單據序號 序號,
			B.文數字1 半成品編號,
			C.單據日期 作業日期,
			C.歸屬類別 製令單別,
			C.歸屬編號 製令單號,
			C.業務員 作業人員,
			D.製程代碼,
			D.機台代碼,
			A.領用日期 異動日期,
			A.庫別代碼,
			A.領用數量 * -1 異動數量,
			B.備註說明
		FROM 
			FIL0045 A
			/*流水編號*/
			INNER JOIN FIL0040 B ON A.流水編號 = B.流水編號 AND B.單據類別 = 'C41'
			INNER JOIN FIL0030 C ON B.單據類別 = C.單據類別 AND B.單據編號 = C.單據編號
			INNER JOIN FIL0031 D ON B.單據類別 = D.單別 AND B.單據編號 = D.單號
			/*領用編號
			INNER JOIN FIL0040 B1 ON A.領用編號 = B1.流水編號 AND B1.單據類別 = 'C41'
			INNER JOIN FIL0030 C1 ON B1.單據類別 = C1.單據類別 AND B1.單據編號 = C1.單據編號
			INNER JOIN FIL0031 D1 ON B1.單據類別 = D1.單別 AND B1.單據編號 = D1.單號
			*/
	) A
	LEFT JOIN ViewFIL310P B ON A.機台代碼 = B.代碼
	LEFT JOIN ViewFIL3106 C ON A.庫別代碼 = C.代碼
	LEFT JOIN ViewFIL4030 D ON A.製令單別 = D.製令單別 AND A.製令單號 = D.製令單號
	LEFT JOIN FIL0010 E ON A.作業人員 = E.員工編號
	LEFT JOIN ViewFIL310N F ON A.製程代碼 = F.代碼);

-- Oracle user_views
CREATE VIEW "VIEWFIL4104" ("條碼", "單別", "單號", "序號", "半成品編號", "作業日期", "製令單別", "製令單號", "製程代碼", "製程名稱", "機台代碼", "機台名稱", "庫別代碼", "庫別名稱", "入庫數量", "領用數量", "庫存數量", "產品名稱", "產品規格", "公司代碼", "公司名稱") AS (                                                                                                                                                      SELECT
	A.條碼,
	B.單據類別 單別,
	B.單據編號 單號,
	B.單據序號 序號,
	B.文數字1 半成品編號,
	C.單據日期 作業日期,
	C.歸屬類別 製令單別,
	C.歸屬編號 製令單號,
	D.製程代碼,
	nvl(E.名稱, ' ') 製程名稱,
	D.機台代碼,
	nvl(F.名稱, ' ') 機台名稱,
	A.庫別代碼,
	nvl(G.名稱, ' ') 庫別名稱,
	A.入庫數量,
	A.領用數量,
	A.庫存數量,
	nvl(H.產品名稱, ' ') 產品名稱,
	nvl(H.產品規格, ' ') 產品規格,
	nvl(H.公司代碼, ' ') 公司代碼,
	nvl(H.公司名稱, ' ') 公司名稱
FROM
	(	SELECT
			A.條碼,
			A.庫別代碼,
			sum(A.入庫數量) 入庫數量,
			sum(A.領用數量) 領用數量,
			sum(A.入庫數量 - A.領用數量) 庫存數量
		FROM
			(	SELECT 
					A.流水編號 條碼,
					A.倉庫代碼 庫別代碼,
					A.贈品數量 入庫數量,
					0 領用數量
				FROM 
					FIL0040 A
				WHERE
					A.單據類別 = 'C41' AND
					A.異動類別 = 'A' AND
					A.文數字1 != ' ' AND
					A.結案碼 = 'Y'
					
				union
				
				SELECT 
					A.領用編號 條碼,
					A.庫別代碼,
					0 入庫數量,
					A.領用數量
				FROM 
					FIL0045 A
			) A
		GROUP BY
			A.條碼,
			A.庫別代碼
	) A
	INNER JOIN FIL0040 B ON A.條碼 = B.流水編號 AND B.單據類別 = 'C41'
	INNER JOIN FIL0030 C ON B.單據類別 = C.單據類別 AND B.單據編號 = C.單據編號
	INNER JOIN FIL0031 D ON B.單據類別 = D.單別 AND B.單據編號 = D.單號
	LEFT JOIN ViewFIL310N E ON D.製程代碼 = E.代碼
	LEFT JOIN ViewFIL310P F ON D.機台代碼 = F.代碼
	LEFT JOIN ViewFIL3106 G ON A.庫別代碼 = G.代碼
	LEFT JOIN ViewFIL4030 H ON C.歸屬類別 = H.製令單別 AND C.歸屬編號 = H.製令單號);

-- Oracle user_views（在 Oracle 已失效）
CREATE VIEW "VIEWFIL4105" ("製令單別", "製令單號", "製程代碼", "製程名稱", "入庫數量", "出庫數量", "結存數量") AS (SELECT 
	A.製令單別,
	A.製令單號,
	A.製程代碼,
	A.製程名稱,
	sum(A.入庫數量) 入庫數量,
	sum(A.出庫數量) 出庫數量,
	sum(A.入庫數量) - sum(A.出庫數量) 結存數量
FROM
	(	SELECT 
			A.製令單別,
			A.製令單號,
			A.製程代碼,
			A.製程名稱,
			A.入庫數量,
			0 出庫數量
		FROM 
			ViewFIL4101 A
	) A
GROUP BY
	A.製令單別,
	A.製令單號,
	A.製程代碼,
	A.製程名稱);

-- Oracle user_views
CREATE VIEW "VIEWFIL4111" ("單別", "單號", "機台代碼", "機台名稱", "作業位置", "出袋距離_左", "出袋距離_右", "巡檢日期", "製令單別", "製令單號", "簽核系統", "簽核狀態", "公司代碼", "公司名稱", "訂單單別", "訂單單號", "客戶編號", "客戶名稱", "產品編號", "產品名稱", "成品尺寸", "訂單數量", "檢驗時間", "箱號", "Y牢固完整度", "N牢固完整度", "作業員", "作業員姓名", "備註", "流水編號", "填表人", "填表人姓名", "填表日", "最後更新者", "更新者姓名", "最後更新日", "機台狀態") AS (                                                                                                                                            SELECT
	B.單據類別 單別,
	B.單據編號 單號,
	A.機台代碼,
	C.名稱 機台名稱,
	A.作業位置,
	A.出袋距離_左,
	A.出袋距離_右,
	B.單據日期 巡檢日期,
	B.歸屬類別 製令單別,
	B.歸屬編號 製令單號,
	B.簽核系統,
	nvl(Z3.簽核狀態, '0') 簽核狀態,
	D.公司代碼,
	D.公司名稱,
	D.訂單單別,
	D.訂單單號,
	D.客戶編號,
	D.客戶名稱,
	D.產品編號,
	D.產品名稱,
	D.產品規格 成品尺寸,
	D.訂購數量 訂單數量,
	A.檢驗時間,
	A.箱號,
	A.Y牢固完整度,
	A.N牢固完整度,
	A.作業員,
	nvl(E.員工姓名,' ') 作業員姓名, 
	A.備註,
	A.主檔流水編號 流水編號,
	B.填表人,
	nvl(Z1.員工姓名,' ') 填表人姓名, 
	B.填表日, 
	B.最後更新者,
	nvl(Z2.員工姓名,' ') 更新者姓名, 
	B.最後更新日,
	A.機台狀態
FROM
	FIL003H A
	INNER JOIN FIL0030 B ON A.主檔流水編號 = B.流水編號
	INNER JOIN ViewFIL310P C ON A.機台代碼 = C.代碼
	LEFT JOIN ViewFIL4030 D ON B.歸屬類別 = D.製令單別 AND B.歸屬編號 = D.製令單號
	LEFT JOIN FIL0010 E ON A.作業員 = E.員工編號
	LEFT JOIN FIL0010 Z1 ON B.填表人 = Z1.員工編號
	LEFT JOIN FIL0010 Z2 ON B.最後更新者 = Z2.員工編號
	LEFT JOIN ViewFIL0030 Z3 ON B.簽核系統 = Z3.簽核系統 AND B.單據編號 = Z3.單號	
WHERE
	A.巡檢項目 = 'C31F');

-- Oracle user_views
CREATE VIEW "VIEWFIL4112" ("單別", "單號", "作業區域", "巡檢日期", "製令單號", "箱號", "檢驗時間", "次數") AS (                                                                                                                                            SELECT
	A.單據類別 單別,
	A.單據編號 單號,
	C.機台代碼 作業區域,
	A.單據日期 巡檢日期,
	A.歸屬編號 製令單號,
	C.箱號,
	C.檢驗時間,
	row_number() over (partition by C.機台代碼, A.歸屬編號, A.單據日期 order by C.檢驗時間 asc) as 次數
FROM
	FIL0030 A
	INNER JOIN FIL003H C ON A.流水編號 = C.主檔流水編號
WHERE
	A.單據類別 = 'C45');

-- Oracle user_views
CREATE VIEW "VIEWFIL4121" ("單別", "單號", "機台代碼", "機台名稱", "作業位置", "出袋距離_左", "出袋距離_右", "巡檢日期", "製令單別", "製令單號", "簽核系統", "簽核狀態", "公司代碼", "公司名稱", "訂單單別", "訂單單號", "客戶編號", "客戶名稱", "產品編號", "產品名稱", "成品尺寸", "訂單數量", "檢驗時間", "箱號", "Y牢固完整度", "N牢固完整度", "作業員", "作業員姓名", "備註", "流水編號", "填表人", "填表人姓名", "填表日", "最後更新者", "更新者姓名", "最後更新日", "機台狀態") AS (                                                                                                                                            SELECT
	B.單據類別 單別,
	B.單據編號 單號,
	A.機台代碼,
	C.名稱 機台名稱,
	A.作業位置,
	A.出袋距離_左,
	A.出袋距離_右,
	B.單據日期 巡檢日期,
	B.歸屬類別 製令單別,
	B.歸屬編號 製令單號,
	B.簽核系統,
	nvl(Z3.簽核狀態, '0') 簽核狀態,
	D.公司代碼,
	D.公司名稱,
	D.訂單單別,
	D.訂單單號,
	D.客戶編號,
	D.客戶名稱,
	D.產品編號,
	D.產品名稱,
	D.產品規格 成品尺寸,
	D.訂購數量 訂單數量,
	A.檢驗時間,
	A.箱號,
	A.Y牢固完整度,
	A.N牢固完整度,
	A.作業員,
	nvl(E.員工姓名,' ') 作業員姓名, 
	A.備註,
	A.主檔流水編號 流水編號,
	B.填表人,
	nvl(Z1.員工姓名,' ') 填表人姓名, 
	B.填表日, 
	B.最後更新者,
	nvl(Z2.員工姓名,' ') 更新者姓名, 
	B.最後更新日,
	A.機台狀態
FROM
	FIL003H A
	INNER JOIN FIL0030 B ON A.主檔流水編號 = B.流水編號
	INNER JOIN ViewFIL310P C ON A.機台代碼 = C.代碼
	LEFT JOIN ViewFIL4030 D ON B.歸屬類別 = D.製令單別 AND B.歸屬編號 = D.製令單號
	LEFT JOIN FIL0010 E ON A.作業員 = E.員工編號
	LEFT JOIN FIL0010 Z1 ON B.填表人 = Z1.員工編號
	LEFT JOIN FIL0010 Z2 ON B.最後更新者 = Z2.員工編號
	LEFT JOIN ViewFIL0030 Z3 ON B.簽核系統 = Z3.簽核系統 AND B.單據編號 = Z3.單號	
WHERE
	A.巡檢項目 = 'C31G');

-- Oracle user_views
CREATE VIEW "VIEWFIL4122" ("單別", "單號", "作業區域", "巡檢日期", "製令單號", "箱號", "檢驗時間", "次數") AS (                                                                                                                                            SELECT
	A.單據類別 單別,
	A.單據編號 單號,
	C.機台代碼 作業區域,
	A.單據日期 巡檢日期,
	A.歸屬編號 製令單號,
	C.箱號,
	C.檢驗時間,
	row_number() over (partition by C.機台代碼, A.歸屬編號, A.單據日期 order by C.檢驗時間 asc) as 次數
FROM
	FIL0030 A
	INNER JOIN FIL003H C ON A.流水編號 = C.主檔流水編號
WHERE
	A.單據類別 = 'C46');

-- Oracle user_views
CREATE VIEW "VIEWFIL4201" ("單別", "單號", "檢驗日期", "巡檢單別", "巡檢單號", "製令單別", "製令單號", "箱號", "簽核系統", "簽核狀態", "公司代碼", "公司名稱", "訂單單別", "訂單單號", "客戶編號", "客戶名稱", "產品編號", "產品名稱", "產品規格", "預計交期", "生產數量", "製造日期", "檢驗數量", "不良數量", "交貨日期", "交貨數量", "判定", "判定其他說明", "作業人員1", "作業員1姓名", "作業人員2", "作業員2姓名", "作業人員3", "作業員3姓名", "標籤類別", "備註", "流水編號", "填表人", "填表人姓名", "填表日", "最後更新者", "更新者姓名", "最後更新日") AS (
SELECT
	A.單據類別 單別,
	A.單據編號 單號,
	A.單據日期 檢驗日期,
	A.歸屬類別 巡檢單別,
	A.歸屬編號 巡檢單號,
	D.製令單別 製令單別,
	D.製令單號,
	nvl(D1.箱號,0) 箱號,
	A.簽核系統,
	nvl(Z3.簽核狀態, '0') 簽核狀態,
	B.公司代碼,
	B.公司名稱,
	B.訂單單別,
	B.訂單單號,
	B.客戶編號,
	B.客戶名稱,
	DECODE(A.廠客單號,' ',E.成品編號,A.廠客單號) 產品編號,
	F.品名 產品名稱,
	F.規格 產品規格,
	B.預交日 預計交期,
	D.生產數量 生產數量,
	D.製造日期,
	nvl(D.檢驗數量, 0) 檢驗數量,
	nvl(D.不良數量, 0) 不良數量,
	nvl(D.交貨日期, '00000000') 交貨日期,
	nvl(D.交貨數量, 0) 交貨數量,
	nvl(D.判定, ' ') 判定,
	nvl(D.判定其他說明, ' ') 判定其他說明,
	nvl(D.作業人員1, ' ') 作業人員1,
	nvl(Y1.員工姓名,' ') 作業員1姓名, 
	nvl(D.作業人員2, ' ') 作業人員2,
	nvl(Y2.員工姓名,' ') 作業員2姓名, 
	nvl(D.作業人員3, ' ') 作業人員3,
	nvl(Y3.員工姓名,' ') 作業員3姓名, 
	D.標籤類別,
	A.備註, 
	A.流水編號,
	A.填表人,
	nvl(Z1.員工姓名,' ') 填表人姓名, 
	A.填表日, 
	A.最後更新者,
	nvl(Z2.員工姓名,' ') 更新者姓名, 
	A.最後更新日
FROM
	FIL0030 A
	INNER JOIN FIL003E D ON A.流水編號 = D.主檔流水編號	
	/*檢驗記錄表*/
	LEFT JOIN ViewFIL4030_A B ON D.製令單別 = B.製令單別 AND D.製令單號 = B.製令單號
	/*製令主檔*/
	LEFT JOIN FIL0032 C ON D.製令單別 = C.製令單別 AND D.製令單號 = C.製令單號
	/*產品條件主檔*/
	LEFT JOIN ViewFil4101 D1 ON A.歸屬類別 = D1.單別 AND A.歸屬編號=D1.單號
	/*製袋巡檢記錄表*/
	LEFT JOIN FIL004B E ON E.製令單號 = D.製令單號 AND E.箱號 = NVL(D1.箱號,0)
	/*製成品屬性*/
	LEFT JOIN FIL0012 F ON F.產品編號 = DECODE(A.廠客單號,' ',E.成品編號,A.廠客單號)
	LEFT JOIN FIL0010 Y1 ON D.作業人員1 = Y1.員工編號
	LEFT JOIN FIL0010 Y2 ON D.作業人員2 = Y2.員工編號
	LEFT JOIN FIL0010 Y3 ON D.作業人員3 = Y3.員工編號
	LEFT JOIN FIL0010 Z1 ON A.填表人 = Z1.員工編號
	LEFT JOIN FIL0010 Z2 ON A.最後更新者 = Z2.員工編號
	LEFT JOIN ViewFIL0030 Z3 ON A.簽核系統 = Z3.簽核系統 AND A.單據編號 = Z3.單號
WHERE
	A.單據類別 = 'C48');

-- Oracle user_views
CREATE VIEW "VIEWFIL4202" ("單別", "單號", "檢驗日期", "檢驗單別", "檢驗單號", "製令單別", "製令單號", "箱號", "簽核系統", "簽核狀態", "公司代碼", "公司名稱", "訂單單別", "訂單單號", "客戶編號", "客戶名稱", "產品編號", "產品名稱", "產品規格", "預計交期", "生產數量", "製造日期", "檢驗數量", "不良數量", "交貨日期", "交貨數量", "判定", "判定其他說明", "作業人員1", "作業員1姓名", "作業人員2", "作業員2姓名", "作業人員3", "作業員3姓名", "標籤類別", "備註", "流水編號", "填表人", "填表人姓名", "填表日", "最後更新者", "更新者姓名", "最後更新日") AS (                                                                                                                                            SELECT
	A.單據類別 單別,
	A.單據編號 單號,
	A.單據日期 檢驗日期,
	A.歸屬類別 檢驗單別,
	A.歸屬編號 檢驗單號,
	D.製令單別,
	D.製令單號,
	D1.箱號,
	A.簽核系統,
	nvl(Z3.簽核狀態, '0') 簽核狀態,
	B.公司代碼,
	B.公司名稱,
	B.訂單單別,
	B.訂單單號,
	B.客戶編號,
	B.客戶名稱,
	B.產品編號,
	B.產品名稱,
	B.產品規格,
	B.預交日 預計交期,
	C.成袋數 生產數量,
	D.製造日期,
	nvl(D.檢驗數量, 0) 檢驗數量,
	nvl(D.不良數量, 0) 不良數量,
	nvl(D.交貨日期, '00000000') 交貨日期,
	nvl(D.交貨數量, 0) 交貨數量,
	nvl(D.判定, ' ') 判定,
	nvl(D.判定其他說明, ' ') 判定其他說明,
	nvl(D.作業人員1, ' ') 作業人員1,
	nvl(Y1.員工姓名,' ') 作業員1姓名, 
	nvl(D.作業人員2, ' ') 作業人員2,
	nvl(Y2.員工姓名,' ') 作業員2姓名, 
	nvl(D.作業人員3, ' ') 作業人員3,
	nvl(Y3.員工姓名,' ') 作業員3姓名, 
	D.標籤類別,
	A.備註, 
	A.流水編號,
	A.填表人,
	nvl(Z1.員工姓名,' ') 填表人姓名, 
	A.填表日, 
	A.最後更新者,
	nvl(Z2.員工姓名,' ') 更新者姓名, 
	A.最後更新日
FROM
	FIL0030 A
	/*出廠檢驗報告*/
	INNER JOIN FIL003E D ON A.流水編號 = D.主檔流水編號
	/*成品檢驗記錄表:A0*/
	INNER JOIN FIL0030 A0 ON A.歸屬類別 = A0.單據類別 AND A.歸屬編號 = A0.單據編號
	/*製袋巡檢記錄表*/
	LEFT JOIN FIL0030 A1 ON A0.歸屬類別 = A1.單據類別 AND A0.歸屬編號 = A1.單據編號
	/*生產條件*/
	INNER JOIN ViewFIL4030_A B ON D.製令單別 = B.製令單別 AND D.製令單號 = B.製令單號
	INNER JOIN FIL0032 C ON D.製令單別 = C.製令單別 AND D.製令單號 = C.製令單號
	/*製袋巡檢記錄表*/
	LEFT JOIN FIL003G D1 ON A1.流水編號 = D1.主檔流水編號
	LEFT JOIN FIL0010 Y1 ON D.作業人員1 = Y1.員工編號
	LEFT JOIN FIL0010 Y2 ON D.作業人員2 = Y2.員工編號
	LEFT JOIN FIL0010 Y3 ON D.作業人員3 = Y3.員工編號
	LEFT JOIN FIL0010 Z1 ON A.填表人 = Z1.員工編號
	LEFT JOIN FIL0010 Z2 ON A.最後更新者 = Z2.員工編號
	LEFT JOIN ViewOfObjProperties Z3 ON A.流水編號 = Z3.單據流水號
WHERE
	A.單據類別 = 'C44');

-- Oracle user_views
CREATE VIEW "VIEWFIL4301" ("單別", "單號", "檢驗日期", "巡檢單別", "巡檢單號", "製令單別", "製令單號", "箱號", "簽核系統", "簽核狀態", "公司代碼", "公司名稱", "訂單單別", "訂單單號", "客戶編號", "客戶名稱", "產品編號", "產品名稱", "產品規格", "預計交期", "生產數量", "製造日期", "檢驗數量", "不良數量", "交貨日期", "交貨數量", "判定", "判定其他說明", "作業人員1", "作業員1姓名", "作業人員2", "作業員2姓名", "作業人員3", "作業員3姓名", "標籤類別", "備註", "依檢驗結果", "流水編號", "填表人", "填表人姓名", "填表日", "最後更新者", "更新者姓名", "最後更新日") AS (
SELECT
	A.單據類別 單別,
	A.單據編號 單號,
	A.單據日期 檢驗日期,
	A.歸屬類別 巡檢單別,
	A.歸屬編號 巡檢單號,
	D.製令單別 製令單別,
	D.製令單號,
	nvl(D1.箱號,0) 箱號,
	A.簽核系統,
	nvl(Z3.簽核狀態, '0') 簽核狀態,
	B.公司代碼,
	B.公司名稱,
	B.訂單單別,
	B.訂單單號,
	B.客戶編號,
	B.客戶名稱,
	DECODE(A.廠客單號,' ',E.成品編號,A.廠客單號) 產品編號,
	F.品名 產品名稱,
	F.規格 產品規格,
	B.預交日 預計交期,
	D.生產數量 生產數量,
	D.製造日期,
	nvl(D.檢驗數量, 0) 檢驗數量,
	nvl(D.不良數量, 0) 不良數量,
	nvl(D.交貨日期, '00000000') 交貨日期,
	nvl(D.交貨數量, 0) 交貨數量,
	nvl(D.判定, ' ') 判定,
	nvl(D.判定其他說明, ' ') 判定其他說明,
	nvl(D.作業人員1, ' ') 作業人員1,
	nvl(Y1.員工姓名,' ') 作業員1姓名, 
	nvl(D.作業人員2, ' ') 作業人員2,
	nvl(Y2.員工姓名,' ') 作業員2姓名, 
	nvl(D.作業人員3, ' ') 作業人員3,
	nvl(Y3.員工姓名,' ') 作業員3姓名, 
	D.標籤類別,
	A.備註, 
	A.邏輯值一 依檢驗結果,
	A.流水編號,
	A.填表人,
	nvl(Z1.員工姓名,' ') 填表人姓名, 
	A.填表日, 
	A.最後更新者,
	nvl(Z2.員工姓名,' ') 更新者姓名, 
	A.最後更新日
FROM
	FIL0030 A
	INNER JOIN FIL003E D ON A.流水編號 = D.主檔流水編號	
	/*檢驗記錄表*/
	LEFT JOIN ViewFIL4030_A B ON D.製令單別 = B.製令單別 AND D.製令單號 = B.製令單號
	/*製令主檔*/
	LEFT JOIN FIL0032 C ON D.製令單別 = C.製令單別 AND D.製令單號 = C.製令單號
	/*產品條件主檔*/
	LEFT JOIN ViewFil4101 D1 ON A.歸屬類別 = D1.單別 AND A.歸屬編號=D1.單號
	/*製袋巡檢記錄表*/
	LEFT JOIN FIL004B E ON E.製令單號 = D.製令單號 AND E.箱號 = NVL(D1.箱號,0)
	/*製成品屬性*/
	LEFT JOIN FIL0012 F ON F.產品編號 = DECODE(A.廠客單號,' ',E.成品編號,A.廠客單號)
	LEFT JOIN FIL0010 Y1 ON D.作業人員1 = Y1.員工編號
	LEFT JOIN FIL0010 Y2 ON D.作業人員2 = Y2.員工編號
	LEFT JOIN FIL0010 Y3 ON D.作業人員3 = Y3.員工編號
	LEFT JOIN FIL0010 Z1 ON A.填表人 = Z1.員工編號
	LEFT JOIN FIL0010 Z2 ON A.最後更新者 = Z2.員工編號
	LEFT JOIN ViewFIL0030 Z3 ON A.簽核系統 = Z3.簽核系統 AND A.單據編號 = Z3.單號
WHERE
	A.單據類別 = 'C49');

-- Oracle user_views
CREATE VIEW "VIEWFIL4302" ("單別", "單號", "檢驗日期", "檢驗單別", "檢驗單號", "製令單別", "製令單號", "箱號", "簽核系統", "簽核狀態", "公司代碼", "公司名稱", "訂單單別", "訂單單號", "客戶編號", "客戶名稱", "產品編號", "產品名稱", "產品規格", "預計交期", "生產數量", "製造日期", "檢驗數量", "不良數量", "交貨日期", "交貨數量", "判定", "判定其他說明", "作業人員1", "作業員1姓名", "作業人員2", "作業員2姓名", "作業人員3", "作業員3姓名", "標籤類別", "備註", "依檢驗結果", "流水編號", "填表人", "填表人姓名", "填表日", "最後更新者", "更新者姓名", "最後更新日") AS (                                                                                                                                            SELECT
	A.單據類別 單別,
	A.單據編號 單號,
	A.單據日期 檢驗日期,
	A.歸屬類別 檢驗單別,
	A.歸屬編號 檢驗單號,
	D.製令單別,
	D.製令單號,
	D1.箱號,
	A.簽核系統,
	nvl(Z3.簽核狀態, '0') 簽核狀態,
	B.公司代碼,
	B.公司名稱,
	B.訂單單別,
	B.訂單單號,
	B.客戶編號,
	B.客戶名稱,
	B.產品編號,
	B.產品名稱,
	B.產品規格,
	B.預交日 預計交期,
	C.成袋數 生產數量,
	D.製造日期,
	nvl(D.檢驗數量, 0) 檢驗數量,
	nvl(D.不良數量, 0) 不良數量,
	nvl(D.交貨日期, '00000000') 交貨日期,
	nvl(D.交貨數量, 0) 交貨數量,
	nvl(D.判定, ' ') 判定,
	nvl(D.判定其他說明, ' ') 判定其他說明,
	nvl(D.作業人員1, ' ') 作業人員1,
	nvl(Y1.員工姓名,' ') 作業員1姓名, 
	nvl(D.作業人員2, ' ') 作業人員2,
	nvl(Y2.員工姓名,' ') 作業員2姓名, 
	nvl(D.作業人員3, ' ') 作業人員3,
	nvl(Y3.員工姓名,' ') 作業員3姓名, 
	D.標籤類別,
	A.備註, 
	A.邏輯值一 依檢驗結果,
	A.流水編號,
	A.填表人,
	nvl(Z1.員工姓名,' ') 填表人姓名, 
	A.填表日, 
	A.最後更新者,
	nvl(Z2.員工姓名,' ') 更新者姓名, 
	A.最後更新日
FROM
	FIL0030 A
	/*出廠檢驗報告*/
	INNER JOIN FIL003E D ON A.流水編號 = D.主檔流水編號
	/*成品檢驗記錄表:A0*/
	INNER JOIN FIL0030 A0 ON A.歸屬類別 = A0.單據類別 AND A.歸屬編號 = A0.單據編號
	/*製袋巡檢記錄表*/
	LEFT JOIN FIL0030 A1 ON A0.歸屬類別 = A1.單據類別 AND A0.歸屬編號 = A1.單據編號
	/*生產條件*/
	INNER JOIN ViewFIL4030_A B ON D.製令單別 = B.製令單別 AND D.製令單號 = B.製令單號
	INNER JOIN FIL0032 C ON D.製令單別 = C.製令單別 AND D.製令單號 = C.製令單號
	/*製袋巡檢記錄表*/
	LEFT JOIN FIL003G D1 ON A1.流水編號 = D1.主檔流水編號
	LEFT JOIN FIL0010 Y1 ON D.作業人員1 = Y1.員工編號
	LEFT JOIN FIL0010 Y2 ON D.作業人員2 = Y2.員工編號
	LEFT JOIN FIL0010 Y3 ON D.作業人員3 = Y3.員工編號
	LEFT JOIN FIL0010 Z1 ON A.填表人 = Z1.員工編號
	LEFT JOIN FIL0010 Z2 ON A.最後更新者 = Z2.員工編號
	LEFT JOIN ViewOfObjProperties Z3 ON A.流水編號 = Z3.單據流水號
WHERE
	A.單據類別 = 'C43');

-- Oracle user_views
CREATE VIEW "VIEWFIL4A00" ("單別", "單號", "單據日期", "公司代碼", "公司名稱", "簽核系統", "備註", "請購人", "請購人姓名", "幣別代碼", "幣別名稱", "匯率", "稅率", "國內外", "國內外名稱", "貿易條件", "貿易條件名稱", "運輸方式", "運輸方式名稱", "付款方式", "付款方式名稱", "付款條件", "付款條件名稱", "流水編號", "填表人", "填表人姓名", "填表日", "最後更新者", "更新者姓名", "最後更新日", "簽核狀態", "發函代理人", "代理人姓名", "主旨", "員工流水編號") AS (                                                                                                                                                      SELECT
	A.單據類別 單別,
	A.單據編號 單號,
	A.單據日期,
	A.公司代碼,
	nvl(I.全名, ' ') 公司名稱,
	A.簽核系統, 
	A.備註, 
	A.業務員 請購人,
	nvl(D.員工姓名,' ') 請購人姓名, 	
	A.幣別代碼,
	nvl(E.名稱, ' ') 幣別名稱,
	A.匯率,
	A.稅率,
	B.類別 國內外,
	decode(B.類別, 'A', '國內', 'B', '國外', '空白') 國內外名稱,
	B.貿易條件,
	nvl(H.名稱, ' ') 貿易條件名稱,
	B.運輸方式,
	decode(B.運輸方式, '1', '空運', '2', '海運', '3', '海空聯運', '4', '郵寄', '5', '陸運', '7', '自送', '8', '快遞', '其他') 運輸方式名稱,
	B.付款方式,
	decode(B.付款方式, '1', '現金', '2', '電匯', '3', '支票', '4', '其他', '空白') 付款方式名稱,
	A.收付方式 付款條件,
	nvl(G.名稱, ' ') 付款條件名稱,
	A.流水編號,
	A.填表人,
	nvl(Z1.員工姓名,' ') 填表人姓名, 
	A.填表日, 
	A.最後更新者,
	nvl(Z2.員工姓名,' ') 更新者姓名, 
	A.最後更新日,
	nvl(Z3.簽核狀態, '0') 簽核狀態,
	nvl(F.發函代理人, ' ') 發函代理人,
	nvl(F.代理人姓名, ' ') 代理人姓名,
	A.單據編號||'('||trim(A.單據類別)||')' 主旨,
	nvl(Z1.Serial_Num,' ') 員工流水編號
FROM
	FIL0030 A
	LEFT JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
	LEFT JOIN FIL0010 D ON A.業務員 = D.員工編號
	LEFT JOIN ViewFIL3102 E ON A.幣別代碼 = E.代碼
	LEFT JOIN ViewFIL0030 F ON A.簽核系統 = F.簽核系統 AND A.單據編號 = F.單號
	LEFT JOIN ViewFIL3107 G ON A.收付方式 = G.代碼
	LEFT JOIN ViewFIL3101 H ON B.貿易條件 = H.代碼
	LEFT JOIN ViewFIL0011 I ON A.公司代碼 = I.代碼
	LEFT JOIN FIL0010 Z1 ON A.填表人 = Z1.員工編號
	LEFT JOIN FIL0010 Z2 ON A.最後更新者 = Z2.員工編號
	LEFT JOIN ViewOfObjProperties Z3 ON A.流水編號 = Z3.單據流水號
WHERE
	A.單據類別 = 'D01');

-- Oracle user_views
CREATE VIEW "VIEWFIL4A01" ("單別", "單號", "序號", "廠商編號", "廠商簡稱", "廠商全名", "料號", "品名", "規格", "廠商料號", "數量", "送貨規格", "送貨單位", "送貨數量", "庫存異動數", "庫存單位", "單位代碼", "單位名稱", "單價", "總價", "預交日", "備註", "結案", "流水編號", "最後更新者", "更新者姓名", "最後更新日") AS (                                                                                                                                                      SELECT 
	A.單據類別 單別, 
	A.單據編號 單號,
	A.單據序號 序號,
	A.相關代碼1 廠商編號,
	nvl(Z2.簡稱, ' ') 廠商簡稱,
	nvl(Z2.全名, ' ') 廠商全名,
	A.產品編號 料號,
	decode(nvl(B.手動品名,' '),' ',nvl(C.品名, ' '),nvl(B.手動品名,' ')) 品名,
	decode(nvl(B.手動規格,' '),' ',nvl(C.規格, ' '),nvl(B.手動規格,' ')) 規格,
	A.廠客品號 廠商料號,
	A.異動數量 數量,
	A.數值3 送貨規格,
	A.相關代碼2 送貨單位,
	A.數值2 送貨數量,
	A.數值4 庫存異動數,
	D.庫存單位,
	A.單位代碼,
	nvl(D.名稱, ' ') 單位名稱,
	A.異動單價 單價,
	A.異動金額 總價,
	A.預交日,
	A.備註說明 備註,
	A.Logical1 結案,
	A.流水編號,
	A.最後更新者,
	NVL(Z1.員工姓名,' ') 更新者姓名,
	A.最後更新日
FROM 
	FIL0040 A
	LEFT JOIN FIL0041 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號 AND A.單據序號 = B.序號
	LEFT JOIN ViewFIL1012 C ON A.產品編號 = C.產品編號
	LEFT JOIN ViewFIL3103 D ON A.單位代碼 = D.代碼
	LEFT JOIN FIL0010 Z1 ON A.最後更新者 = Z1.員工編號
	LEFT JOIN FIL0011 Z2 ON A.相關代碼1 = Z2.編號
WHERE
	A.單據類別 = 'D01');

-- Oracle user_views
CREATE VIEW "VIEWFIL4A0A" ("單別", "單號", "數量", "總價", "稅率", "稅額", "含稅價") AS (SELECT
	A.單別,
	A.單號,
	A.數量,
	A.總價,
	B.稅率,
	round(A.總價 * B.稅率 / 100) 稅額,
	round(A.總價 * (1 + B.稅率 / 100)) 含稅價
FROM
	(	SELECT
			A.單據類別 單別,
			A.單據編號 單號,
			sum(A.異動數量) 數量,
			sum(A.異動金額) 總價
		FROM
			FIL0040 A
		WHERE
			A.單據類別 = 'D01'
		GROUP BY
			A.單據類別,
			A.單據編號
	) A
	INNER JOIN FIL0030 B ON A.單別 = B.單據類別 AND A.單號 = B.單據編號);

-- Oracle user_views
CREATE VIEW "VIEWFIL4A10" ("單別", "單號", "請購單別", "請購單號", "公司代碼", "公司名稱", "單據日期", "簽核系統", "廠商編號", "廠商簡稱", "廠商全名", "備註", "採購人", "採購人姓名", "幣別代碼", "幣別名稱", "匯率", "稅別", "稅率", "未稅金額", "稅額", "應稅金額", "預付原幣", "預付台幣", "國內外", "國內外名稱", "貿易條件", "貿易條件名稱", "運輸方式", "運輸方式名稱", "付款方式", "付款方式名稱", "廠商已讀", "付款條件", "送貨地址", "付款條件名稱", "流水編號", "填表人", "填表人姓名", "填表日", "最後更新者", "更新者姓名", "最後更新日", "簽核狀態", "發函代理人", "代理人姓名", "主旨", "員工流水編號", "需要總經理簽", "印採購總標") AS (                                                                                                                                                      SELECT
	A.單據類別 單別,
	A.單據編號 單號,
	A.歸屬類別 請購單別,
	A.歸屬編號 請購單號,
	A.公司代碼,
	nvl(I.全名, ' ') 公司名稱,
	A.單據日期,
	A.簽核系統, 
	A.廠客編號 廠商編號,
	nvl(C.簡稱, ' ') 廠商簡稱,
	nvl(C.全名, ' ') 廠商全名,
	A.備註, 
	A.業務員 採購人,
	nvl(D.員工姓名,' ') 採購人姓名, 	
	A.幣別代碼,
	nvl(E.名稱, ' ') 幣別名稱,
	A.匯率,
	A.稅別,
	A.稅率,
	B.數值1 未稅金額,
	B.數值2 稅額,
	B.數值3 應稅金額,
	B.數值5 預付原幣,
	B.數值6 預付台幣,
	B.類別 國內外,
	decode(B.類別, 'A', '國內', 'B', '國外', '空白') 國內外名稱,
	B.貿易條件,
	nvl(H.名稱, ' ') 貿易條件名稱,
	B.運輸方式,
	decode(B.運輸方式, '1', '空運', '2', '海運', '3', '海空聯運', '4', '郵寄', '5', '陸運', '7', '自送', '8', '快遞', '其他') 運輸方式名稱,
	B.付款方式,
	decode(B.付款方式, '1', '現金', '2', '電匯', '3', '支票', '4', '其他', '空白') 付款方式名稱,
	B.Logical1 廠商已讀,
	A.收付方式 付款條件,
	B.價格條件 送貨地址,
	nvl(G.名稱, ' ') 付款條件名稱,
	A.流水編號,
	A.填表人,
	nvl(Z1.員工姓名,' ') 填表人姓名, 
	A.填表日, 
	A.最後更新者,
	nvl(Z2.員工姓名,' ') 更新者姓名, 
	A.最後更新日,
	nvl(Z3.簽核狀態, '0') 簽核狀態,
	nvl(F.發函代理人, ' ') 發函代理人,
	nvl(F.代理人姓名, ' ') 代理人姓名,
	A.單據編號||'('||trim(A.單據類別)||')' 主旨,
	nvl(Z1.Serial_Num,' ') 員工流水編號,
	A.邏輯值一 需要總經理簽,
	B.Logical2 印採購總標
FROM
	FIL0030 A
	INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
	LEFT JOIN FIL0011 C ON A.廠客編號 = C.編號
	LEFT JOIN FIL0010 D ON A.業務員 = D.員工編號
	LEFT JOIN ViewFIL3102 E ON A.幣別代碼 = E.代碼
	LEFT JOIN ViewFIL0030 F ON A.簽核系統 = F.簽核系統 AND A.單據編號 = F.單號
	LEFT JOIN ViewFIL3107 G ON A.收付方式 = G.代碼
	LEFT JOIN ViewFIL3101 H ON B.貿易條件 = H.代碼
	LEFT JOIN ViewFIL0011 I ON A.公司代碼 = I.代碼
	LEFT JOIN FIL0010 Z1 ON A.填表人 = Z1.員工編號
	LEFT JOIN FIL0010 Z2 ON A.最後更新者 = Z2.員工編號
	LEFT JOIN ViewOfObjProperties Z3 ON A.流水編號 = Z3.單據流水號
WHERE
	A.單據類別 = 'D11');

-- Oracle user_views
CREATE VIEW "VIEWFIL4A11" ("單別", "單號", "序號", "料號", "品名", "規格", "廠商料號", "廠商批號", "數量", "單位代碼", "單位名稱", "單價", "總價", "收貨量", "收貨單位", "收貨規格", "預交日", "備註", "製令單別", "製令單號", "批號", "批號規格", "QRNO", "庶物用品", "紙管箱", "急用", "流水編號", "最後更新者", "更新者姓名", "最後更新日") AS (
SELECT 
	A.單據類別 單別, 
	A.單據編號 單號,
	A.單據序號 序號,
	A.產品編號 料號,
	decode(nvl(B.手動品名,' '),' ',nvl(C.品名, ' '),nvl(B.手動品名,' ')) 品名,
	decode(nvl(B.手動規格,' '),' ',nvl(C.規格, ' '),nvl(B.手動規格,' ')) 規格,
	A.廠客品號 廠商料號,
	A.文數字1 廠商批號,
	A.異動數量 數量,
	A.單位代碼,
	nvl(D.名稱, ' ') 單位名稱,
	A.異動單價 單價,
	A.異動金額 總價,
	A.數值2 收貨量,
	A.相關代碼1 收貨單位,
	A.數值3 收貨規格,
	A.預交日,
	A.備註說明 備註,
	A.前置單別 製令單別,
	A.前置單號 製令單號,
	trim(A.單據類別) || '-' || trim(A.單據編號) || '-' || trim(to_char(A.單據序號, '0000')) 批號,
	trim(A.單據類別) || '-' || trim(A.單據編號) || '-' || trim(to_char(A.單據序號, '0000')) || ' (' || A.產品編號 || ') ' || nvl(C.規格, ' ') 批號規格,
	A.QRNo,
	Decode(nvl(C.採購單位,' '),' ',1,0) 庶物用品,
	Decode(Substr(A.產品編號,1,1),'C',1,0) 紙管箱,
	B.Logical1 急用,
	A.流水編號,
	A.最後更新者,
	NVL(Z1.員工姓名,' ') 更新者姓名,
	A.最後更新日
FROM 
	FIL0040 A
	LEFT JOIN FIL0041 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號 AND A.單據序號 = B.序號
	LEFT JOIN ViewFIL1012 C ON A.產品編號 = C.產品編號
	LEFT JOIN ViewFIL3103 D ON A.單位代碼 = D.代碼
	LEFT JOIN FIL0010 Z1 ON A.最後更新者 = Z1.員工編號
WHERE
	A.單據類別 = 'D11');

-- Oracle user_views
CREATE VIEW "VIEWFIL4A1A" ("單別", "單號", "數量", "總價", "稅率", "稅額", "含稅價", "原幣總價", "原物料編號", "原物料名稱") AS (SELECT
	A.單別,
	A.單號,
	A.數量,
	A.總價,
	B.稅率,
	round(A.總價 * B.稅率 / 100) 稅額,
	round(A.總價 * (1 + B.稅率 / 100)) 含稅價,
	A.原幣總價,
	原物料編號,
	原物料名稱
FROM
	(	SELECT
			A.單據類別 單別,
			A.單據編號 單號,
			sum(A.異動數量) 數量,
			sum(A.異動金額) 總價,
			sum(nvl(b.數值2,0)) 原幣總價,
			listagg( trim(A.產品編號), ' ') within group (order by A.產品編號) as 原物料編號,
			listagg( trim(C.品名), ' ') within group (order by C.品名) as 原物料名稱
		FROM
			FIL0040 A
			LEFT JOIN FIL0041 B ON B.單別=A.單據類別 AND B.單號=A.單據編號 AND B.序號=A.單據序號
			LEFT JOIN ViewFIL1012 C ON A.產品編號 = C.產品編號
		WHERE
			A.單據類別 = 'D11'
		GROUP BY
			A.單據類別,
			A.單據編號
	) A
	INNER JOIN FIL0030 B ON A.單別 = B.單據類別 AND A.單號 = B.單據編號);

-- Oracle user_views
CREATE VIEW "VIEWFIL4A1B" ("單別", "單號", "序號", "廠客編號", "料號", "請購數量", "採購數量", "未採購數", "請購金額", "採購金額", "結案") AS (
SELECT
	A.單別,
	A.單號,
	A.序號,
	A.廠客編號,
	A.料號,
	A.請購數量,
	nvl(B.採購數量, 0) 採購數量,
	case when nvl(B.採購數量, 0)> nvl(A.請購數量, 0) then 0 else nvl(A.請購數量, 0) - nvl(B.採購數量, 0) end 未採購數,
	A.請購金額,
	nvl(B.採購金額, 0) 採購金額,
	case when (case when nvl(B.採購數量, 0)> nvl(A.請購數量, 0) then 0 else nvl(A.請購數量, 0) - nvl(B.採購數量, 0) end) = 0 or A.結案 = 1 then 1 else 0 end  結案
FROM
	/* 請購單 */
	(	SELECT
			A.單據類別 單別,
			A.單據編號 單號,
			A.單據序號 序號,
			A.相關代碼1 廠客編號,
			A.產品編號 料號,
			sum(A.異動數量) 請購數量,
			sum(A.異動金額) 請購金額,
			max(A.Logical1) 結案
		FROM
			FIL0040 A
		WHERE
			A.單據類別 = 'D01' 
		GROUP BY
			A.單據類別,
			A.單據編號,
			A.單據序號,
			A.相關代碼1,
			A.產品編號
	) A
	LEFT JOIN
	/* 採購 */
	(	SELECT 
			B.歸屬類別 單別, 
			B.歸屬編號 單號,
			A.數值1 序號,
			sum(A.異動數量) 採購數量,
			sum(A.異動金額) 採購金額
		FROM 
			FIL0040 A
			INNER JOIN FIL0030 B ON A.單據類別 = B.單據類別 AND A.單據編號 = B.單據編號
		WHERE
			A.單據類別 = 'D11' AND
			B.歸屬編號 != ' '
		GROUP BY
			B.歸屬類別,
			B.歸屬編號,
			A.數值1
	) B ON A.單別 = B.單別 AND A.單號 = B.單號 AND A.序號 = B.序號);

-- Oracle user_views
CREATE VIEW "VIEWFIL4A1C" ("單別", "單號", "請購數量", "採購數量", "未採購數", "請購金額", "採購金額") AS (SELECT
	nvl(A.單別, B.單別) 單別,
	nvl(A.單號, B.單號) 單號,
	nvl(A.請購數量, 0) 請購數量,
	nvl(B.採購數量, 0) 採購數量,
	nvl(A.請購數量, 0) - nvl(B.採購數量, 0) 未採購數,
	nvl(A.請購金額, 0) 請購金額,
	nvl(B.採購金額, 0) 採購金額
FROM
	/* 請購 */
	(	SELECT
			A.單據類別 單別,
			A.單據編號 單號,
			sum(A.異動數量) 請購數量,
			sum(A.異動金額) 請購金額
		FROM
			FIL0040 A
		WHERE
			A.單據類別 = 'D01'
		GROUP BY
			A.單據類別,
			A.單據編號
	) A
	FULL OUTER JOIN
	/* 採購 */
	(	SELECT 
			B.歸屬類別 單別, 
			B.歸屬編號 單號,
			sum(A.異動數量) 採購數量,
			sum(A.異動金額) 採購金額
		FROM 
			FIL0040 A
			INNER JOIN FIL0030 B ON A.單據類別 = B.單據類別 AND A.單據編號 = B.單據編號
		WHERE
			A.單據類別 = 'D11' AND
			B.歸屬編號 != ' '
		GROUP BY
			B.歸屬類別,
			B.歸屬編號
	) B ON A.單別 = B.單別 AND A.單號 = B.單號);

-- Oracle user_views
CREATE VIEW "VIEWFIL4A1D" ("單別", "單號", "序號", "細分", "出貨支數", "庫存異動數", "單價", "採購數量", "廠商規格", "製作日期", "截止日期", "廠商預交日期", "製造批號", "廠商料號", "廠商發票", "喜美批號", "平台上傳", "備註", "已開發票", "喜美收貨", "建檔人員", "出貨支數單位", "運送方式代碼", "運送方式") AS (
SELECT 
	A.單別, 
	A.單號,
	A.序號,
	A.細分,
	A.數字一 出貨支數,
	A.數字二 庫存異動數,
	A.數字三 單價,
	A.數字四 採購數量,
	to_char(A.數字五,'99999.9')||decode(A.文字四,' ',B.相關代碼1,A.文字四) 廠商規格,	
	A.日期一 製作日期,
	A.日期二 截止日期,
	A.日期三 廠商預交日期,
	A.文字一 製造批號,
	A.文字二 廠商料號,
	A.文字三 廠商發票,
	A.文字五 喜美批號,
	A.邏輯一 平台上傳,
	A.備註,
	DECODE(A.文字三,' ',0,1) 已開發票,
	DECODE(NVL(C.條碼,' '),' ',0,1) 喜美收貨,
	A.文字六 建檔人員,
	decode(A.文字七,' ',decode(A.文字四,'M','支','MB','米/箱','桶'),A.文字七) 出貨支數單位,
	A.運送方式 運送方式代碼,
	D.名稱 運送方式
FROM 
	FIL00401 A
	INNER JOIN FIL0040 B ON A.單別 = B.單據類別 AND A.單號 = B.單據編號 AND A.序號=B.單據序號
	LEFT JOIN ViewFIL1024 C ON A.文字五 = C.條碼
	LEFT JOIN ViewFIL3111 D ON D.代碼 = A.運送方式
	LEFT JOIN ViewOfObjProperties Z3 ON B.流水編號 = Z3.單據流水號
WHERE
	A.單別 = 'D11' AND 
	nvl(Z3.簽核狀態, '0') <>'A');

-- Oracle user_views
CREATE VIEW "VIEWFIL4A1E" ("單別", "單號", "序號", "採購單數量", "採購單庫存異動數", "廠商出貨採購數", "廠商出貨庫存異動數", "廠商出貨支數", "喜美收料庫存異動數", "廠商條碼筆數", "喜美收料採購數", "未交貨採購數", "廠商未交貨庫存異動數") AS WITH 
/*採購單明細*/
TMP1 AS 
(
SELECT 
	A.單據類別 單別, 
	A.單據編號 單號,
	A.單據序號 序號,
	A.單位代碼,
	A.異動數量 採購單數量,
	A.數值4 採購單庫存異動數	
FROM 
	FIL0040 A
	LEFT JOIN ViewOfObjProperties Z3 ON A.流水編號 = Z3.單據流水號
WHERE
	A.單據類別 = 'D11' AND 
	nvl(Z3.簽核狀態, '0') <>'A'
),
/*廠商出貨明細*/
TMP2 AS
(
SELECT 
		A.單別, 
		A.單號,
		A.序號,
		SUM(A.數字四) 廠商出貨採購數,
		SUM(A.數字二) 廠商出貨庫存異動數,
		SUM(A.數字一) 廠商出貨支數,
		count(A.細分) 廠商條碼筆數
	FROM 
		FIL00401 A
	WHERE
		A.單別 = 'D11' and A.邏輯一=1
	GROUP BY
		A.單別, 
		A.單號,
		A.序號
),
/*喜美收料*/
TMP3 AS
(SELECT
		A.單別,
		A.單號,
		A.序號,
		SUM(A.庫存異動數) 喜美收料庫存異動數
	FROM
		FIL0043 A
	WHERE
		A.單別 = 'D11'
	GROUP BY
		A.單別,
		A.單號,
		A.序號
)
SELECT
	A.單別, 
	A.單號,
	A.序號,
	A.採購單數量,
	A.採購單庫存異動數,	
	NVL(N.廠商出貨採購數,0) 廠商出貨採購數,
	NVL(N.廠商出貨庫存異動數,0) 廠商出貨庫存異動數,
	NVL(N.廠商出貨支數,0) 廠商出貨支數,
	nvl(P.喜美收料庫存異動數,0) 喜美收料庫存異動數,
	NVL(N.廠商條碼筆數,0) 廠商條碼筆數,
	nvl(P.喜美收料庫存異動數,0)/DECODE(D.庫存乘數,0,1,D.庫存乘數) 喜美收料採購數,	
	case when A.採購單數量>=NVL(N.廠商出貨採購數,0) then A.採購單數量-NVL(N.廠商出貨採購數,0) else 0 end 未交貨採購數,
	case when A.採購單庫存異動數>=NVL(N.廠商出貨庫存異動數,0) then A.採購單庫存異動數-NVL(N.廠商出貨庫存異動數,0) else 0 end 廠商未交貨庫存異動數
FROM
	TMP1 A
	LEFT JOIN TMP2 N ON N.單別 = A.單別 AND N.單號 = A.單號 AND N.序號 = A.序號
	LEFT JOIN TMP3 P ON P.單別 = A.單別 AND P.單號 = A.單號 AND P.序號 = A.序號
	LEFT JOIN ViewFIL3103 D ON A.單位代碼 = D.代碼;

-- Oracle user_views
CREATE VIEW "VIEWFIL4A1EA" ("單別", "單號", "序號", "料號", "品名", "規格", "單價", "預交日", "備註", "批號", "收貨量", "收貨單位", "收貨規格", "庶物用品", "急用", "流水編號", "採購單數量", "採購單庫存異動數", "廠商出貨採購數", "廠商出貨庫存異動數", "廠商出貨支數", "廠商條碼筆數", "喜美收料採購數", "喜美收料庫存異動數", "未交貨採購數", "廠商未交貨庫存異動數", "單據日期", "廠商編號", "廠商簡稱", "簽核系統", "簽核狀態", "送貨地址", "廠商已讀") AS WITH 
/*採購單明細*/
TMP1 AS 
(
SELECT 
	A.單據類別 單別, 
	A.單據編號 單號,
	A.單據序號 序號,
	A.產品編號 料號,
	decode(nvl(B.手動品名,' '),' ',nvl(C.品名, ' '),nvl(B.手動品名,' ')) 品名,
	decode(nvl(B.手動規格,' '),' ',nvl(C.規格, ' '),nvl(B.手動規格,' ')) 規格,
	A.異動單價 單價,
	A.預交日,	
	A.備註說明 備註,	
	trim(A.單據類別) || '-' || trim(A.單據編號) || '-' || trim(to_char(A.單據序號, '0000')) 批號,	
	A.數值2 收貨量,
	A.相關代碼1 收貨單位,
	A.數值3 收貨規格,	
	Decode(nvl(C.採購單位,' '),' ',1,0) 庶物用品,	
	B.Logical1 急用,
	M.流水編號,		
	M.單據日期,
	M.廠客編號 廠商編號,
	nvl(Z2.簡稱, ' ') 廠商簡稱,
	M.簽核系統,
	nvl(Z3.簽核狀態, '0') 簽核狀態,
	Q.價格條件 送貨地址,
	Q.Logical1 廠商已讀,
	D.庫存乘數
FROM 
	FIL0040 A
	INNER JOIN FIL0030 M ON A.單據類別 = M.單據類別 AND A.單據編號 = M.單據編號	
	INNER JOIN FIL0031 Q ON A.單據類別 = Q.單別 AND A.單據編號 = Q.單號
	LEFT JOIN FIL0041 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號 AND A.單據序號 = B.序號
	LEFT JOIN FIL0012 C ON A.產品編號 = C.產品編號
	LEFT JOIN ViewFIL3103 D ON A.單位代碼 = D.代碼
	LEFT JOIN FIL0010 Z1 ON A.最後更新者 = Z1.員工編號	
	LEFT JOIN FIL0011 Z2 ON M.廠客編號 = Z2.編號
	LEFT JOIN ViewOfObjProperties Z3 ON M.流水編號 = Z3.單據流水號
WHERE
	A.單據類別 = 'D11' AND 
	nvl(Z3.簽核狀態, '0') <>'A'
)
SELECT
	A.單別, 
	A.單號,
	A.序號,
	A.料號,
	A.品名,
	A.規格,
	A.單價,
	A.預交日,	
	A.備註,	
	A.批號,	
	A.收貨量,
	A.收貨單位,
	A.收貨規格,	
	A.庶物用品,	
	A.急用,
	A.流水編號,		
	N.採購單數量,
	N.採購單庫存異動數,	
	N.廠商出貨採購數,
	N.廠商出貨庫存異動數,
	N.廠商出貨支數,
	N.廠商條碼筆數,
	N.喜美收料採購數,
	N.喜美收料庫存異動數,
	N.未交貨採購數,
	N.廠商未交貨庫存異動數,
	A.單據日期,
	A.廠商編號,
	A.廠商簡稱,
	A.簽核系統,
	A.簽核狀態,
	A.送貨地址,
	A.廠商已讀
FROM
	TMP1 A
	INNER JOIN ViewFIL4A1E N ON N.單別 = A.單別 AND N.單號 = A.單號 AND N.序號 = A.序號;

-- Oracle user_views
CREATE VIEW "VIEWFIL4A1EB" ("單別", "單號", "序號", "採購單庫存異動數", "喜美收料庫存異動數") AS WITH 
/*採購單明細*/
TMP1 AS 
(
SELECT 
	A.單據類別 單別, 
	A.單據編號 單號,
	A.單據序號 序號,
	A.數值4 採購單庫存異動數	
FROM 
	FIL0040 A
	LEFT JOIN ViewOfObjProperties Z3 ON A.流水編號 = Z3.單據流水號
WHERE
	A.單據類別 = 'D11' AND 
	nvl(Z3.簽核狀態, '0') <>'A' AND
	A.結案碼 = ' '
),
/*喜美收料*/
TMP3 AS
(SELECT
		A.單別,
		A.單號,
		A.序號,
		SUM(A.庫存異動數) 喜美收料庫存異動數
	FROM
		FIL0043 A
	WHERE
		A.單別 = 'D11'
	GROUP BY
		A.單別,
		A.單號,
		A.序號
)
SELECT
	A.單別, 
	A.單號,
	A.序號,
	A.採購單庫存異動數,	
	nvl(P.喜美收料庫存異動數,0) 喜美收料庫存異動數
FROM
	TMP1 A
	LEFT JOIN TMP3 P ON P.單別 = A.單別 AND P.單號 = A.單號 AND P.序號 = A.序號;

-- Oracle user_views
CREATE VIEW "VIEWFIL4A1F" ("廠客編號", "預交日", "狀態", "補件說明", "採購單號") AS (
SELECT
  A.廠客編號,
  A.預交日,
  CASE WHEN C.筆數>0 AND nvl(B.確認碼,' ') = ' ' THEN 'A' ELSE nvl(B.確認碼,' ') END  狀態,
  nvl(B.簽核系統_結案,' ') 補件說明,
  listagg(nvl(trim(A.單據編號),' '),',') within group (order by A.廠客編號) as 採購單號
FROM
(
	SELECT 
	  A.廠客編號,
	  A.單據編號,
	  listagg(nvl(to_char(to_date(A.預交日,'yyyy/mm/dd'),'yyyy/mm/dd'),' '),',') within group (order by A.廠客編號) as 預交日
	FROM  
	  （SELECT DISTINCT 
		  B.廠客編號, 
		  A.單據編號,
		  A.預交日
	  FROM 
		  FIL0040 A
		  INNER JOIN FIL0030 B ON A.單據類別 = B.單據類別 AND A.單據編號 = B.單據編號 
		  LEFT JOIN ViewOfObjProperties Z3 ON B.流水編號 = Z3.單據流水號
	  WHERE
		  A.單據類別 = 'D11' AND Z3.簽核狀態 = 'E'
	  GROUP BY 
		  B.廠客編號, 
		  A.單據編號,
		  A.預交日）A
	GROUP BY 
		  A.廠客編號, 
		  A.單據編號    
) A
LEFT JOIN FIL0030 B ON B.單據類別='COA' and B.單據編號=trim(A.廠客編號)||'-'||replace(regexp_substr(A.預交日, '[^,]+'),'/','')
LEFT JOIN ViewFIL0054 C ON C.簽核系統 = 'COA' AND C.單號=trim(A.廠客編號)||'-'||replace(regexp_substr(A.預交日, '[^,]+'),'/','')
GROUP BY
	A.廠客編號, 
  A.預交日,
	CASE WHEN C.筆數>0 AND nvl(B.確認碼,' ') = ' ' THEN 'A' ELSE nvl(B.確認碼,' ') END,
	nvl(B.簽核系統_結案,' ')
);

-- Oracle user_views
CREATE VIEW "VIEWFIL4A20" ("單別", "單號", "採購單別", "採購單號", "公司代碼", "公司名稱", "單據日期", "簽核系統", "廠商編號", "廠商簡稱", "廠商全名", "廠商送貨單", "備註", "收貨人", "收貨人姓名", "幣別代碼", "幣別名稱", "匯率", "稅率", "未稅金額", "稅額", "應稅金額", "總重量", "原幣金額", "統一編號", "發票號碼", "發票聯式", "運送方式", "發票日期", "流水編號", "填表人", "填表人姓名", "填表日", "最後更新者", "更新者姓名", "最後更新日", "簽核狀態", "發函代理人", "代理人姓名", "主旨", "員工流水編號") AS (                                                                                                                                                      SELECT
	A.單據類別 單別,
	A.單據編號 單號,
	A.歸屬類別 採購單別,
	A.歸屬編號 採購單號,
	A.公司代碼,
	nvl(G.全名, ' ') 公司名稱,
	A.單據日期,
	A.簽核系統, 
	A.廠客編號 廠商編號,
	nvl(C.簡稱, ' ') 廠商簡稱,
	nvl(C.全名, ' ') 廠商全名,
	A.廠客單號 廠商送貨單,
	A.備註, 
	A.業務員 收貨人,
	nvl(D.員工姓名,' ') 收貨人姓名, 	
	A.幣別代碼,
	nvl(E.名稱, ' ') 幣別名稱,
	A.匯率,
	A.稅率,
	B.數值1 未稅金額,
	B.數值2 稅額,
	B.數值3 應稅金額,
	B.數值4 總重量,
	B.數值5 原幣金額,
	B.文數字1 統一編號,
	B.文數字2 發票號碼,
	B.文數字3 發票聯式,
	B.文字6 運送方式,
	B.交貨日期 發票日期,
	A.流水編號,
	A.填表人,
	nvl(Z1.員工姓名,' ') 填表人姓名, 
	A.填表日, 
	A.最後更新者,
	nvl(Z2.員工姓名,' ') 更新者姓名, 
	A.最後更新日,
	nvl(Z3.簽核狀態, '0') 簽核狀態,
	nvl(F.發函代理人, ' ') 發函代理人,
	nvl(F.代理人姓名, ' ') 代理人姓名,
	A.單據編號||'('||trim(A.單據類別)||')' 主旨,
	nvl(Z1.Serial_Num,' ') 員工流水編號
FROM
	FIL0030 A
	INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
	LEFT JOIN FIL0011 C ON A.廠客編號 = C.編號
	LEFT JOIN FIL0010 D ON A.業務員 = D.員工編號
	LEFT JOIN ViewFIL3102 E ON A.幣別代碼 = E.代碼
	LEFT JOIN ViewFIL0030 F ON A.簽核系統 = F.簽核系統 AND A.單據編號 = F.單號
	LEFT JOIN ViewFIL0011 G ON A.公司代碼 = G.代碼
	LEFT JOIN FIL0010 Z1 ON A.填表人 = Z1.員工編號
	LEFT JOIN FIL0010 Z2 ON A.最後更新者 = Z2.員工編號
	LEFT JOIN ViewOfObjProperties Z3 ON A.流水編號 = Z3.單據流水號
WHERE
	A.單據類別 = 'D21');

-- Oracle user_views
CREATE VIEW "VIEWFIL4A21" ("單別", "單號", "序號", "採購單別", "採購單號", "採購序號", "料號", "品名", "規格", "入庫日期", "倉庫代碼", "倉庫名稱", "數量", "贈品數量", "單位代碼", "單位名稱", "單價", "總價", "庫存異動數", "批號", "批號規格", "廠商批號", "備註", "簽核狀態", "流水編號", "最後更新者", "更新者姓名", "最後更新日") AS (                                                                                                                                                      
SELECT 
	A.單據類別 單別, 
	A.單據編號 單號,
	A.單據序號 序號,
	A.前置單別 採購單別, 
	A.前置單號 採購單號,
	A.QRNO 採購序號,
	A.產品編號 料號,
	decode(nvl(C.手動品名,' '),' ',nvl(E.品名, ' '),nvl(C.手動品名,' ')) 品名,
	decode(nvl(C.手動規格,' '),' ',nvl(E.規格, ' '),nvl(C.手動規格,' ')) 規格,
	A.異動日期 入庫日期,
	A.倉庫代碼,
	nvl(G.名稱, ' ') 倉庫名稱,
	A.異動數量 數量,
	A.贈品數量,
	A.單位代碼,
	nvl(F.名稱, ' ') 單位名稱,
	A.異動單價 單價,
	A.異動金額 總價,
	A.數值4 庫存異動數,
	nvl(C.批號, ' ') 批號,
	nvl(C.批號, ' ') || ' (' || A.產品編號 || ') ' || trim(nvl(E.品名, ' ')) || '/' || nvl(E.規格, ' ') 批號規格,
	A.文數字1 廠商批號,
	A.備註說明 備註,
	nvl(Z3.簽核狀態, '0') 簽核狀態,
	A.流水編號,
	A.最後更新者,
	NVL(Z1.員工姓名,' ') 更新者姓名,
	A.最後更新日
FROM 
	FIL0040 A
	/*主檔*/
	INNER JOIN FIL0030 B ON A.單據類別 = B.單據類別 AND A.單據編號 = B.單據編號
	/*特殊欄位*/
	LEFT JOIN FIL0041 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號 AND A.單據序號 = C.序號
	LEFT JOIN ViewFIL1012 E ON A.產品編號 = E.產品編號
	LEFT JOIN ViewFIL3103 F ON A.單位代碼 = F.代碼
	LEFT JOIN ViewFIL3106 G ON A.倉庫代碼 = G.代碼
	LEFT JOIN FIL0010 Z1 ON A.最後更新者 = Z1.員工編號
	LEFT JOIN ViewOfObjProperties Z3 ON B.流水編號 = Z3.單據流水號
WHERE
	A.單據類別 = 'D21' and A.異動類別 = 'A');

-- Oracle user_views
CREATE VIEW "VIEWFIL4A2A" ("單別", "單號", "數量", "贈品", "總價", "重量", "稅率", "稅額", "含稅價", "原幣總價") AS (SELECT
	A.單別,
	A.單號,
	A.數量,
	A.贈品,
	A.總價,
	A.重量,
	B.稅率,
	A.稅額 稅額,
	A.總價 + A.稅額 含稅價,
	A.原幣總價
FROM
	(	SELECT
			A.單據類別 單別,
			A.單據編號 單號,
			sum(A.異動數量) 數量,
			sum(A.贈品數量) 贈品,
			sum(A.異動金額) 總價,
			sum(A.異動稅額) 稅額,
			sum(A.毛重) 重量,
			sum(nvl(b.數值2,0)) 原幣總價
		FROM
			FIL0040 A
			LEFT JOIN FIL0041 B ON B.單別=A.單據類別 AND B.單號=A.單據編號 AND B.序號=A.單據序號
		WHERE
			A.單據類別 = 'D21' AND
			A.異動類別 = ' '
		GROUP BY
			A.單據類別,
			A.單據編號
	) A
	INNER JOIN FIL0030 B ON A.單別 = B.單據類別 AND A.單號 = B.單據編號);

-- Oracle user_views
CREATE VIEW "VIEWFIL4A2B" ("單別", "單號", "序號", "料號", "採購數量", "採購數量_庫存單位", "進料數量", "進料數量_庫存單位", "收料數量", "收料數量_庫存單位", "未進料數", "未進料數_庫存單位", "收料未入庫數_庫存單位", "採購金額", "進料金額", "結案否") AS (
SELECT
	nvl(A.單別, B.單別) 單別,
	nvl(A.單號, B.單號) 單號,
	NVL(A.序號, B.序號) 序號,
	nvl(A.料號, B.料號) 料號,
	nvl(A.採購數量, 0) 採購數量,
	nvl(A.庫存異動數, 0) 採購數量_庫存單位,
	nvl(greatest(nvl(C.收料數量, 0),nvl(B.進料數量, 0)), 0) 進料數量,
	nvl(greatest(nvl(C.庫存異動數, 0),nvl(B.庫存異動數, 0)), 0) 進料數量_庫存單位,
	nvl(C.收料數量, 0) 收料數量,
	nvl(C.庫存異動數, 0) 收料數量_庫存單位,
	nvl(A.採購數量, 0) - greatest(nvl(C.收料數量, 0),nvl(B.進料數量, 0)) 未進料數,
	nvl(A.庫存異動數, 0) - greatest(nvl(C.庫存異動數, 0),nvl(B.庫存異動數, 0)) 未進料數_庫存單位,
	greatest(nvl(C.庫存異動數, 0)- nvl(B.庫存異動數, 0),0) 收料未入庫數_庫存單位,
	nvl(A.採購金額, 0) 採購金額,
	nvl(B.進料金額, 0) 進料金額,
	case when nvl(A.採購數量, 0) - greatest(nvl(C.收料數量, 0),nvl(B.進料數量, 0))>0 then 0 else 1 end 結案否
FROM
	/* 採購單 */
	(	SELECT
			A.單據類別 單別,
			A.單據編號 單號,
			A.單據序號 序號,
			A.產品編號 料號,
			sum(A.異動數量) 採購數量,
			sum(A.異動金額) 採購金額,
			sum(A.數值4) 庫存異動數
		FROM
			FIL0040 A
		WHERE
			A.單據類別 = 'D11' or A.單據類別 = 'D51'
		GROUP BY
			A.單據類別,
			A.單據編號,
			A.產品編號,
			A.單據序號
	) A
	FULL OUTER JOIN
	/* 進料 */
	(	SELECT 
			A.採購單別 單別, 
			A.採購單號 單號,
			A.採購序號 序號,
			A.料號,
			sum(A.數量) 進料數量,
			sum(A.總價) 進料金額,
			sum(A.庫存異動數) 庫存異動數
		FROM 
			ViewFIL4A21 A
		WHERE
			A.簽核狀態 <>'A'
		GROUP BY
			A.採購單別,
			A.採購單號,
			A.採購序號,
			A.料號
	) B ON A.單別 = B.單別 AND A.單號 = B.單號 AND A.序號 = B.序號
	FULL OUTER JOIN
	/* 收料 */
	(	SELECT 
			A.單別, 
			A.單號,
			A.序號,
			A.料號,
			sum(A.數量) 收料數量,
			sum(A.庫存異動數) 庫存異動數
		FROM 
			ViewFil1024K A
		WHERE
			A.單別 = 'D11' or A.單別 = 'D51'
		GROUP BY
			A.單別, 
			A.單號,
			A.序號,
			A.料號
	) C ON A.單別 = C.單別 AND A.單號 = C.單號 AND A.序號 = C.序號);

-- Oracle user_views
CREATE VIEW "VIEWFIL4A2C" ("採購單別", "採購單號", "進料原幣總價", "進料台幣總價") AS (                                                                                                                                                 
SELECT 
	A.前置單別 採購單別, 
	A.前置單號 採購單號,
	SUM(C.數值2) 進料原幣總價,
	SUM(A.異動金額) 進料台幣總價
FROM 
	FIL0040 A
	/*主檔*/
	INNER JOIN FIL0030 B ON A.單據類別 = B.單據類別 AND A.單據編號 = B.單據編號
	/*特殊欄位*/
	LEFT JOIN FIL0041 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號 AND A.單據序號 = C.序號
WHERE
	A.單據類別 = 'D21' and A.異動類別 = ' '
GROUP BY
	A.前置單別, 
	A.前置單號
	);

-- Oracle user_views
CREATE VIEW "VIEWFIL4A30" ("單別", "單號", "進料單別", "進料單號", "公司代碼", "公司名稱", "單據日期", "簽核系統", "廠商編號", "廠商簡稱", "廠商全名", "備註", "檢驗員", "檢驗員姓名", "流水編號", "填表人", "填表人姓名", "填表日", "最後更新者", "更新者姓名", "最後更新日", "簽核狀態", "發函代理人", "代理人姓名", "主旨", "運送方式", "員工流水編號") AS (                                                                                                                                                      SELECT
	A.單據類別 單別,
	A.單據編號 單號,
	A.歸屬類別 進料單別,
	A.歸屬編號 進料單號,
	A.公司代碼,
	nvl(E.全名, ' ') 公司名稱,
	A.單據日期,
	A.簽核系統, 
	A.廠客編號 廠商編號,
	nvl(C.簡稱, ' ') 廠商簡稱,
	nvl(C.全名, ' ') 廠商全名,
	A.備註, 
	A.業務員 檢驗員,
	nvl(D.員工姓名,' ') 檢驗員姓名, 	
	A.流水編號,
	A.填表人,
	nvl(Z1.員工姓名,' ') 填表人姓名, 
	A.填表日, 
	A.最後更新者,
	nvl(Z2.員工姓名,' ') 更新者姓名, 
	A.最後更新日,
	nvl(Z3.簽核狀態, '0') 簽核狀態,
	nvl(F.發函代理人, ' ') 發函代理人,
	nvl(F.代理人姓名, ' ') 代理人姓名,
	A.單據編號||'('||trim(A.單據類別)||')' 主旨,
	B.文字6 運送方式,
	nvl(Z1.Serial_Num,' ') 員工流水編號
FROM
	FIL0030 A
	INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
	LEFT JOIN FIL0011 C ON A.廠客編號 = C.編號
	LEFT JOIN FIL0010 D ON A.業務員 = D.員工編號
	LEFT JOIN ViewFIL0011 E ON A.公司代碼 = E.代碼
	LEFT JOIN ViewFIL0030 F ON A.簽核系統 = F.簽核系統 AND A.單據編號 = F.單號
	LEFT JOIN FIL0010 Z1 ON A.填表人 = Z1.員工編號
	LEFT JOIN FIL0010 Z2 ON A.最後更新者 = Z2.員工編號
	LEFT JOIN ViewOfObjProperties Z3 ON A.流水編號 = Z3.單據流水號
WHERE
	A.單據類別 = 'D31');

-- Oracle user_views
CREATE VIEW "VIEWFIL4A31" ("單別", "單號", "序號", "料號", "品名", "規格", "進料日期", "檢驗日期", "倉庫代碼", "倉庫名稱", "數量", "單位代碼", "單位名稱", "進料序號", "批號", "檢附COA", "檢驗外觀", "檢驗清潔度", "檢驗顏色", "檢驗尺寸", "檢驗厚度", "檢驗滑度", "檢驗人員", "檢驗姓名", "判定", "特採", "不合格原因", "流水編號", "最後更新者", "更新者姓名", "最後更新日") AS (
SELECT 
	A.單據類別 單別, 
	A.單據編號 單號,
	A.單據序號 序號,
	A.產品編號 料號,
	nvl(E.品名, ' ') 品名,
	nvl(E.規格, ' ') 規格,
	nvl(D.入庫日期, ' ') 進料日期,
	A.異動日期 檢驗日期,
	A.倉庫代碼,
	nvl(G.名稱, ' ') 倉庫名稱,
	A.異動數量 數量,
	A.單位代碼,
	nvl(F.名稱, ' ') 單位名稱,
	D.序號 進料序號,
	C.批號,
	C.檢附COA,
	C.檢驗外觀,
	C.檢驗清潔度,
	C.檢驗顏色,
	C.檢驗尺寸,
	C.檢驗厚度,
	C.檢驗滑度,
	C.檢驗人員,
	nvl(H.員工姓名,' ') 檢驗姓名,
	C.檢驗判定 判定,
	C.檢驗特採 特採,
	A.備註說明 不合格原因,
	A.流水編號,
	A.最後更新者,
	NVL(Z1.員工姓名,' ') 更新者姓名,
	A.最後更新日
FROM 
	FIL0040 A
	INNER JOIN FIL0030 B ON A.單據類別 = B.單據類別 AND A.單據編號 = B.單據編號
	INNER JOIN FIL0041 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號 AND A.單據序號 = C.序號
	/*進料*/
	LEFT JOIN ViewFIL4A21 D ON C.批號 = D.批號
	LEFT JOIN ViewFIL1012 E ON A.產品編號 = E.產品編號
	LEFT JOIN ViewFIL3103 F ON A.單位代碼 = F.代碼
	LEFT JOIN ViewFIL3106 G ON A.倉庫代碼 = G.代碼
	LEFT JOIN FIL0010 H ON C.檢驗人員 = H.員工編號
	LEFT JOIN FIL0010 Z1 ON A.最後更新者 = Z1.員工編號
WHERE
	A.單據類別 = 'D31');

-- Oracle user_views
CREATE VIEW "VIEWFIL4A3A" ("單別", "單號", "數量") AS (SELECT
	A.單據類別 單別,
	A.單據編號 單號,
	sum(A.異動數量) 數量
FROM
	FIL0040 A
WHERE
	A.單據類別 = 'D31'
GROUP BY
	A.單據類別,
	A.單據編號);

-- Oracle user_views
CREATE VIEW "VIEWFIL4A40" ("單別", "單號", "進料單別", "進料單號", "公司代碼", "公司名稱", "單據日期", "簽核系統", "廠商編號", "廠商簡稱", "廠商全名", "備註", "倉管員", "倉管員姓名", "幣別代碼", "幣別名稱", "收付方式", "統一編號", "發票號碼", "發票聯數", "發票日期", "稅別", "稅率", "匯率", "未稅金額", "稅額", "應稅金額", "流水編號", "填表人", "填表人姓名", "填表日", "最後更新者", "更新者姓名", "最後更新日", "簽核狀態", "發函代理人", "代理人姓名", "主旨", "員工流水編號") AS (                                                                                                                                                      SELECT
	A.單據類別 單別,
	A.單據編號 單號,
	A.歸屬類別 進料單別,
	A.歸屬編號 進料單號,
	A.公司代碼,
	nvl(E.全名, ' ') 公司名稱,
	A.單據日期,
	A.簽核系統, 
	A.廠客編號 廠商編號,
	nvl(C.簡稱, ' ') 廠商簡稱,
	nvl(C.全名, ' ') 廠商全名,
	A.備註, 
	A.業務員 倉管員,
	nvl(D.員工姓名,' ') 倉管員姓名, 	
	A.幣別代碼,
	nvl(G.名稱, ' ') 幣別名稱,
	NVL(H.名稱,' ') 收付方式,
	B.文數字1 統一編號,
	B.文數字2 發票號碼,
	B.文數字3 發票聯數,
	B.交貨日期 發票日期,
	DECODE(A.稅別,'2','應稅外加','4','免稅','9','不計稅',' ') 稅別,
	A.稅率,
	A.匯率,
	B.數值1 未稅金額,
	B.數值2 稅額,
	B.數值3 應稅金額,
	A.流水編號,
	A.填表人,
	nvl(Z1.員工姓名,' ') 填表人姓名, 
	A.填表日, 
	A.最後更新者,
	nvl(Z2.員工姓名,' ') 更新者姓名, 
	A.最後更新日,
	nvl(Z3.簽核狀態, '0') 簽核狀態,
	nvl(F.發函代理人, ' ') 發函代理人,
	nvl(F.代理人姓名, ' ') 代理人姓名,
	A.單據編號||'('||trim(A.單據類別)||')' 主旨,
	nvl(Z1.Serial_Num,' ') 員工流水編號
FROM
	FIL0030 A
	INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
	LEFT JOIN FIL0011 C ON A.廠客編號 = C.編號
	LEFT JOIN FIL0010 D ON A.業務員 = D.員工編號
	LEFT JOIN ViewFIL0011 E ON A.公司代碼 = E.代碼
	LEFT JOIN ViewFIL0030 F ON A.簽核系統 = F.簽核系統 AND A.單據編號 = F.單號
	LEFT JOIN ViewFIL3102 G ON A.幣別代碼 = G.代碼
	LEFT JOIN ViewFIL3107 H ON A.收付方式 = H.代碼
	LEFT JOIN FIL0010 Z1 ON A.填表人 = Z1.員工編號
	LEFT JOIN FIL0010 Z2 ON A.最後更新者 = Z2.員工編號
	LEFT JOIN ViewOfObjProperties Z3 ON A.流水編號 = Z3.單據流水號
WHERE
	A.單據類別 = 'D41');

-- Oracle user_views
CREATE VIEW "VIEWFIL4A41" ("單別", "單號", "序號", "料號", "品名", "規格", "退料日期", "倉庫代碼", "倉庫名稱", "數量", "金額", "單價", "庫存異動數", "單位代碼", "單位名稱", "進料序號", "批號", "備註", "流水編號", "最後更新者", "更新者姓名", "最後更新日") AS (
SELECT 
	A.單據類別 單別, 
	A.單據編號 單號,
	A.單據序號 序號,
	A.產品編號 料號,
	nvl(E.品名, ' ') 品名,
	nvl(E.規格, ' ') 規格,
	A.異動日期 退料日期,
	A.倉庫代碼,
	nvl(G.名稱, ' ') 倉庫名稱,
	A.異動數量 數量,
	A.異動金額 金額,
	A.異動單價 單價,
	A.數值4 庫存異動數,
	A.單位代碼,
	nvl(F.名稱, ' ') 單位名稱,
	D.序號 進料序號,
	C.批號,
	A.備註說明 備註,
	A.流水編號,
	A.最後更新者,
	NVL(Z1.員工姓名,' ') 更新者姓名,
	A.最後更新日
FROM 
	FIL0040 A
	/*特殊欄位*/
	INNER JOIN FIL0041 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號 AND A.單據序號 = C.序號
	/*進料*/
	LEFT JOIN ViewFIL4A21 D ON C.批號 = D.批號
	LEFT JOIN ViewFIL1012 E ON A.產品編號 = E.產品編號
	LEFT JOIN ViewFIL3103 F ON A.單位代碼 = F.代碼
	LEFT JOIN ViewFIL3106 G ON A.倉庫代碼 = G.代碼
	LEFT JOIN FIL0010 Z1 ON A.最後更新者 = Z1.員工編號
WHERE
	A.單據類別 = 'D41' and A.異動類別='S');

-- Oracle user_views
CREATE VIEW "VIEWFIL4A4A" ("單別", "單號", "數量", "贈品", "總價", "稅率", "稅額", "含稅價") AS (
SELECT
	A.單別,
	A.單號,
	A.數量,
	A.贈品,
	A.總價,
	B.稅率,
	A.稅額,
	A.總價+A.稅額 含稅價
FROM
	(	SELECT
			A.單據類別 單別,
			A.單據編號 單號,
			sum(A.異動數量) 數量,
			sum(A.贈品數量) 贈品,
			sum(A.異動金額) 總價,
			sum(A.異動稅額) 稅額
		FROM
			FIL0040 A
		WHERE
			A.單據類別 = 'D41' AND
			A.異動類別 = 'A'
		GROUP BY
			A.單據類別,
			A.單據編號
	) A
	INNER JOIN FIL0030 B ON A.單別 = B.單據類別 AND A.單號 = B.單據編號);

-- Oracle user_views
CREATE VIEW "VIEWFIL4A4B" ("單別", "單號", "料號", "採購數量", "進料數量", "未進料數", "採購數量_庫存單位", "進料數量_庫存單位", "未進料數_庫存單位", "採購金額", "進料金額", "退料數量", "檢驗數量") AS WITH 
TMP1 AS 
(
SELECT
	A.單別,
	A.單號,
	A.料號,
	A.採購數量,
	A.進料數量,
	A.未進料數,
	A.採購數量_庫存單位,
	A.進料數量_庫存單位,
	A.未進料數_庫存單位,
	A.採購金額,
	A.進料金額
FROM
	ViewFIL4A2B A
),
TMP2 AS
(
SELECT 
	C.歸屬類別 單別, 
	C.歸屬編號 單號,
	A.產品編號 料號,
	sum(A.異動數量) 退料數量
FROM 
	FIL0040 A
	INNER JOIN FIL0030 B ON A.單據類別 = B.單據類別 AND A.單據編號 = B.單據編號
	INNER JOIN FIL0030 C ON B.歸屬類別 = C.單據類別 AND B.歸屬編號 = C.單據編號
WHERE
	A.單據類別 = 'D41' or A.單據類別 = 'D52'
GROUP BY
	C.歸屬類別,
	C.歸屬編號,
	A.產品編號
),
TMP3 AS
(
SELECT 
	C.歸屬類別 單別, 
	C.歸屬編號 單號,
	A.產品編號 料號,
	sum(A.異動數量) 檢驗數量
FROM 
	FIL0040 A
	INNER JOIN FIL0030 B ON A.單據類別 = B.單據類別 AND A.單據編號 = B.單據編號
	INNER JOIN FIL0030 C ON B.歸屬類別 = C.單據類別 AND B.歸屬編號 = C.單據編號
WHERE
	A.單據類別 = 'D31'
GROUP BY
	C.歸屬類別,
	C.歸屬編號,
	A.產品編號
)
SELECT
	A.單別,
	A.單號,
	A.料號,
	nvl(A.採購數量, 0) 採購數量,
	nvl(A.進料數量, 0) 進料數量,
	nvl(A.未進料數, 0) 未進料數,
	nvl(A.採購數量_庫存單位, 0) 採購數量_庫存單位,
	nvl(A.進料數量_庫存單位, 0) 進料數量_庫存單位,
	nvl(A.未進料數_庫存單位, 0) 未進料數_庫存單位,
	nvl(A.採購金額, 0) 採購金額,
	nvl(A.進料金額, 0) 進料金額,
	nvl(B.退料數量, 0) 退料數量,
	nvl(C.檢驗數量, 0) 檢驗數量
FROM	
	TMP1 A
	LEFT JOIN TMP2 B ON A.單別 = B.單別 AND A.單號 = B.單號 AND A.料號 = B.料號
	LEFT JOIN TMP3 C ON A.單別 = C.單別 AND A.單號 = C.單號 AND A.料號 = C.料號;

-- Oracle user_views
CREATE VIEW "VIEWFIL4A4C" ("批號", "進料數量", "退料數量", "未退料數", "檢驗數量", "未檢驗數") AS (SELECT
	nvl(A.批號, B.批號) 批號,
	nvl(A.進料數量, 0) 進料數量,
	nvl(A.退料數量, 0) 退料數量,
	nvl(A.未退料數, 0) 未退料數,
	nvl(B.檢驗數量, 0) 檢驗數量,
	nvl(A.進料數量, 0) - nvl(B.檢驗數量, 0) 未檢驗數
FROM
	(	SELECT
			nvl(A.批號, B.批號) 批號,
			nvl(A.數量, 0) 進料數量,
			nvl(B.退料數, 0) 退料數量,
			nvl(A.數量, 0) - nvl(B.退料數, 0) 未退料數
		FROM
			/* 進料 */
			(	SELECT
					A.批號,
					A.數量
				FROM
					ViewFIL4A21 A
			) A
			FULL OUTER JOIN
			/* 退料 */
			(	SELECT
					A.批號,
					sum(A.數量) 退料數
				FROM
					ViewFIL4A41 A
				GROUP BY
					A.批號	
			) B ON A.批號 = B.批號
	) A
	FULL OUTER JOIN
	/* 檢驗 */
	(	SELECT
			A.批號,
			sum(A.數量) 檢驗數量
		FROM
			ViewFIL4A31 A
		GROUP BY
			A.批號	
	) B ON A.批號 = B.批號);

-- Oracle user_views
CREATE VIEW "VIEWFIL4A4D" ("料號", "批號", "委外數量") AS (
SELECT
			A.料號,
			A.批號,	
			SUM(A.數量*A.庫存參數) 委外數量
		FROM
			ViewFILF0W3 A
		GROUP BY 
			A.料號,
			A.批號
);

-- Oracle user_views
CREATE VIEW "VIEWFIL4A4E" ("料號", "批號", "數量") AS (
SELECT
	材料編號 料號,
	批號,
	SUM(異動數) 數量
FROM
	ViewFIL2022 
GROUP BY 
	材料編號,
	批號
);

-- Oracle user_views
CREATE VIEW "VIEWFIL4A4F" ("單別", "單號", "進料單別", "進料單號", "公司代碼", "公司名稱", "單據日期", "簽核系統", "客戶編號", "客戶簡稱", "客戶全名", "備註", "倉管員", "倉管員姓名", "流水編號", "填表人", "填表人姓名", "填表日", "最後更新者", "更新者姓名", "最後更新日", "簽核狀態", "發函代理人", "代理人姓名", "需品檢", "主旨", "員工流水編號", "指定簽核人員") AS (                                                                                                                                                      SELECT
	A.單據類別 單別,
	A.單據編號 單號,
	A.歸屬類別 進料單別,
	A.歸屬編號 進料單號,
	A.公司代碼,
	nvl(E.全名, ' ') 公司名稱,
	A.單據日期,
	A.簽核系統, 
	A.廠客編號 客戶編號,
	nvl(C.簡稱, ' ') 客戶簡稱,
	nvl(C.全名, ' ') 客戶全名,
	A.備註, 
	A.業務員 倉管員,
	nvl(D.員工姓名,' ') 倉管員姓名, 	
	A.流水編號,
	A.填表人,
	nvl(Z1.員工姓名,' ') 填表人姓名, 
	A.填表日, 
	A.最後更新者,
	nvl(Z2.員工姓名,' ') 更新者姓名, 
	A.最後更新日,
	nvl(Z3.簽核狀態, '0') 簽核狀態,
	nvl(F.發函代理人, ' ') 發函代理人,
	nvl(F.代理人姓名, ' ') 代理人姓名,
	A.邏輯值一 需品檢,
	A.單據編號||'('||trim(A.單據類別)||')' 主旨,
	nvl(Z1.Serial_Num,' ') 員工流水編號,
	nvl(z4.Serial_Num,' ') 指定簽核人員
FROM
	FIL0030 A
	/*
	INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
	*/
	LEFT JOIN FIL0011 C ON A.廠客編號 = C.編號
	LEFT JOIN FIL0010 D ON A.業務員 = D.員工編號
	LEFT JOIN ViewFIL0011 E ON A.公司代碼 = E.代碼
	LEFT JOIN ViewFIL0030 F ON A.簽核系統 = F.簽核系統 AND A.單據編號 = F.單號
	LEFT JOIN FIL0010 Z1 ON A.填表人 = Z1.員工編號
	LEFT JOIN FIL0010 Z2 ON A.最後更新者 = Z2.員工編號
	LEFT JOIN ViewOfObjProperties Z3 ON A.流水編號 = Z3.單據流水號
	LEFT JOIN FIL0010 Z4 ON A.收付方式 = Z4.員工編號
WHERE
	A.單據類別 = 'D51');

-- Oracle user_views
CREATE VIEW "VIEWFIL4A4G" ("單別", "單號", "序號", "單據日期", "客戶編號", "客戶簡稱", "料號", "品名", "規格", "來料日期", "倉庫代碼", "批號", "倉庫名稱", "數量", "庫存異動數", "單位代碼", "庫存單位", "單位名稱", "廠商批號", "備註", "流水編號", "最後更新者", "更新者姓名", "最後更新日") AS (
SELECT 
	A.單據類別 單別, 
	A.單據編號 單號,
	A.單據序號 序號,
	B.單據日期,
	B.廠客編號 客戶編號,
	nvl(Z2.簡稱, ' ') 客戶簡稱,
	A.產品編號 料號,
	nvl(E.品名, ' ') 品名,
	nvl(E.規格, ' ') 規格,
	A.異動日期 來料日期,
	A.倉庫代碼,
	A.單據類別||'-'||A.單據編號||'-'||to_char(A.單據序號,'0009') 批號,
	nvl(G.名稱, ' ') 倉庫名稱,
	A.異動數量 數量,
	A.數值4 庫存異動數,
	A.單位代碼,
	A.相關代碼1 庫存單位,
	nvl(F.名稱, ' ') 單位名稱,
	A.文數字1 廠商批號,
	A.備註說明 備註,
	A.流水編號,
	A.最後更新者,
	NVL(Z1.員工姓名,' ') 更新者姓名,
	A.最後更新日
FROM 
	FIL0040 A
	INNER JOIN FIL0030 B ON A.單據類別 = B.單據類別 AND A.單據編號 = A.單據編號
	LEFT JOIN ViewFIL1012 E ON A.產品編號 = E.產品編號
	LEFT JOIN ViewFIL3103 F ON A.單位代碼 = F.代碼
	LEFT JOIN ViewFIL3106 G ON A.倉庫代碼 = G.代碼
	LEFT JOIN FIL0010 Z1 ON A.最後更新者 = Z1.員工編號
	LEFT JOIN FIL0011 Z2 ON B.廠客編號 = Z2.編號
WHERE
	A.單據類別 = 'D51' and A.異動類別 = ' ');

-- Oracle user_views
CREATE VIEW "VIEWFIL4A4H" ("單別", "單號", "數量", "庫存異動數") AS (SELECT
	A.單據類別 單別,
	A.單據編號 單號,
	sum(A.異動數量) 數量,
	sum(A.數值4) 庫存異動數
FROM
	FIL0040 A
WHERE
	A.單據類別 = 'D51' and A.異動類別 = ' '
GROUP BY
	A.單據類別,
	A.單據編號);

-- Oracle user_views
CREATE VIEW "VIEWFIL4A4I" ("單別", "單號", "客供單別", "客供單號", "公司代碼", "公司名稱", "單據日期", "簽核系統", "客戶編號", "客戶簡稱", "客戶全名", "備註", "倉管員", "倉管員姓名", "寄回或喜美處理", "收件人", "收件人電話", "收件人地址", "流水編號", "填表人", "填表人姓名", "填表日", "最後更新者", "更新者姓名", "最後更新日", "簽核狀態", "發函代理人", "代理人姓名", "需品檢", "主旨", "員工流水編號") AS (                                                                                                                                                      SELECT
	A.單據類別 單別,
	A.單據編號 單號,
	A.歸屬類別 客供單別,
	A.歸屬編號 客供單號,
	A.公司代碼,
	nvl(E.全名, ' ') 公司名稱,
	A.單據日期,
	A.簽核系統, 
	A.廠客編號 客戶編號,
	nvl(C.簡稱, ' ') 客戶簡稱,
	nvl(C.全名, ' ') 客戶全名,
	A.備註, 
	A.業務員 倉管員,
	nvl(D.員工姓名,' ') 倉管員姓名, 	
	B.回簽 寄回或喜美處理,
	B.文字5 收件人,
	B.材料編號一 收件人電話,
	B.價格條件 收件人地址,
	A.流水編號,
	A.填表人,
	nvl(Z1.員工姓名,' ') 填表人姓名, 
	A.填表日, 
	A.最後更新者,
	nvl(Z2.員工姓名,' ') 更新者姓名, 
	A.最後更新日,
	nvl(Z3.簽核狀態, '0') 簽核狀態,
	nvl(F.發函代理人, ' ') 發函代理人,
	nvl(F.代理人姓名, ' ') 代理人姓名,
	A.邏輯值一 需品檢,
	A.單據編號||'('||trim(A.單據類別)||')' 主旨,
	nvl(Z1.Serial_Num,' ') 員工流水編號
FROM
	FIL0030 A
	INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
	LEFT JOIN FIL0011 C ON A.廠客編號 = C.編號
	LEFT JOIN FIL0010 D ON A.業務員 = D.員工編號
	LEFT JOIN ViewFIL0011 E ON A.公司代碼 = E.代碼
	LEFT JOIN ViewFIL0030 F ON A.簽核系統 = F.簽核系統 AND A.單據編號 = F.單號
	LEFT JOIN FIL0010 Z1 ON A.填表人 = Z1.員工編號
	LEFT JOIN FIL0010 Z2 ON A.最後更新者 = Z2.員工編號
	LEFT JOIN ViewOfObjProperties Z3 ON A.流水編號 = Z3.單據流水號
WHERE
	A.單據類別 = 'D52');

-- Oracle user_views
CREATE VIEW "VIEWFIL4A4J" ("單別", "單號", "序號", "料號", "品名", "規格", "來料日期", "倉庫代碼", "倉庫名稱", "數量", "單位代碼", "單位名稱", "進料序號", "批號", "廠商批號", "庫存異動數", "庫存單位", "備註", "流水編號", "最後更新者", "更新者姓名", "最後更新日") AS (
SELECT 
	A.單據類別 單別, 
	A.單據編號 單號,
	A.單據序號 序號,
	A.產品編號 料號,
	nvl(E.品名, ' ') 品名,
	nvl(E.規格, ' ') 規格,
	A.異動日期 來料日期,
	A.倉庫代碼,
	nvl(G.名稱, ' ') 倉庫名稱,
	A.異動數量 數量,
	A.單位代碼,
	nvl(F.名稱, ' ') 單位名稱,
	D.序號 進料序號,
	C.批號,
	A.文數字1 廠商批號,
	A.數值4 庫存異動數,
	A.相關代碼1 庫存單位,
	A.備註說明 備註,
	A.流水編號,
	A.最後更新者,
	NVL(Z1.員工姓名,' ') 更新者姓名,
	A.最後更新日
FROM 
	FIL0040 A
	/*特殊欄位*/
	LEFT JOIN FIL0041 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號 AND A.單據序號 = C.序號
	/*進料*/
	LEFT JOIN ViewFIL4A21 D ON C.批號 = D.批號
	LEFT JOIN ViewFIL1012 E ON A.產品編號 = E.產品編號
	LEFT JOIN ViewFIL3103 F ON A.單位代碼 = F.代碼
	LEFT JOIN ViewFIL3106 G ON A.倉庫代碼 = G.代碼
	LEFT JOIN FIL0010 Z1 ON A.最後更新者 = Z1.員工編號
WHERE
	A.單據類別 = 'D52' and A.異動類別 = 'S');

-- Oracle user_views
CREATE VIEW "VIEWFIL4A4K" ("單別", "單號", "庫存異動數", "數量") AS (SELECT
	A.單據類別 單別,
	A.單據編號 單號,
	sum(A.數值4) 庫存異動數,
	sum(A.異動數量) 數量
FROM
	FIL0040 A
WHERE
	A.單據類別 = 'D52'  and A.異動類別 = 'S'
GROUP BY
	A.單據類別,
	A.單據編號);

-- Oracle user_views
CREATE VIEW "VIEWFIL4A4L" ("產品編號") AS (SELECT 
	DISTINCT A.產品編號 產品編號
FROM 
	FIL0043 M
	INNER JOIN FIL0040 A ON A.單據類別 = M.單別 AND A.單據編號 = M.單號 AND A.單據序號 = 序號
WHERE
	M.單別 = 'D51' AND 
	A.產品編號 != ' ' );

-- Oracle user_views
CREATE VIEW "VIEWFIL5001" ("機台代碼", "位置") AS (
SELECT
	distinct
	A.機台代碼,
	A.位置
FROM
	FIL300B A);

-- Oracle user_views
CREATE VIEW "VIEWFIL5002" ("製令單號", "產品編號", "產品名稱", "產品規格", "讀取日時") AS (
SELECT	Distinct
	A.製令單號,
	B.產品編號,
	B.產品名稱,
	B.產品規格,
	TO_CHAR(A.變更日期,'yyyy/mm/dd hh24:mi:ss') 讀取日時
FROM
	FIL300B A
	INNER JOIN ViewFIL4030_A B ON B.製令單別='C11' AND B.製令單號=A.製令單號 
WHERE
	A.PLC數值<>0
	);

-- Oracle user_views
CREATE VIEW "VIEWFILA001" ("訂單號碼", "產品編號", "單據日期", "父階", "父階單別", "父階單號", "子階", "子階單別", "子階單號", "排序") AS (
SELECT
	B.訂單號碼,
	A.產品編號,
	B.單據日期,
	' ' 父階,
	' ' 父階單別,
	' ' 父階單號,
	trim(A.單據類別) || '.' || A.單據編號 子階,
	A.單據類別 子階單別,
	A.單據編號 子階單號,
	trim(A.單據類別) || '.' || A.單據編號 排序
FROM
	FIL0040 A
	INNER JOIN FIL0030 B ON A.單據類別 = B.單據類別 AND A.單據編號 = B.單據編號
WHERE
	A.單據類別 = 'B31'
/* 客戶訂單 */

UNION

SELECT
	B.訂單號碼,
	A.產品編號,
	B.單據日期,
	trim(B.歸屬類別) || '.' || B.歸屬編號 父階,
	B.歸屬類別 父階單別,
	B.歸屬編號 父階單號,
	trim(A.製令單別) || '.' || A.製令單號 子階,
	A.製令單別 子階單別,
	A.製令單號 子階單號,
	trim(A.製令單別) || '.' || A.製令單號 排序
FROM
	FIL0032 A
	INNER JOIN FIL0030 B ON A.製令單別 = B.單據類別 AND A.製令單號 = B.單據編號
/* 生產條件單 */

UNION

SELECT
	B.訂單號碼,
	nvl(C.產品編號, ' ') 產品編號,
	B.單據日期,
	trim(B.歸屬類別) || '.' || B.歸屬編號 父階,
	B.歸屬類別 父階單別,
	B.歸屬編號 父階單號,
	trim(A.單別) || '.' || A.單號 子階,
	A.單別 子階單別,
	A.單號 子階單號,
	trim(A.單別) || '.' || A.單號 排序
FROM
	FIL0035 A
	INNER JOIN FIL0030 B ON A.單別 = B.單據類別 AND A.單號 = B.單據編號
	LEFT JOIN FIL0032 C ON B.歸屬類別 = C.製令單別 AND B.歸屬編號 = C.製令單號
/* 條件變更單 */

/*
UNION

SELECT
	B.訂單號碼,
	nvl(C.產品編號, ' ') 產品編號,
	B.單據日期,
	trim(B.歸屬類別) || '.' || B.歸屬編號 父階,
	B.歸屬類別 父階單別,
	B.歸屬編號 父階單號,
	trim(A.單別) || '.' || A.單號 子階,
	A.單別 子階單別,
	A.單號 子階單號,
	trim(A.單別) || '.' || A.單號 排序
FROM
	FIL0036 A
	INNER JOIN FIL0030 B ON A.單別 = B.單據類別 AND A.單號 = B.單據編號
	LEFT JOIN FIL0032 C ON B.歸屬類別 = C.製令單別 AND B.歸屬編號 = C.製令單號
製稿工作指示單 */

UNION

SELECT
	C.訂單單號 訂單號碼,
	C.產品編號,
	B.單據日期,
	trim(A.前置單別) || '.' || A.前置單號 父階,
	A.前置單別 父階單別,
	A.前置單號 父階單號,
	trim(A.單據類別) || '.' || A.單據編號 子階,
	A.單據類別 子階單別,
	A.單據編號 子階單號,
	trim(A.單據類別) || '.' || A.單據編號 排序
FROM
	FIL0040 A
	INNER JOIN FIL0030 B ON A.單據類別 = B.單據類別 AND A.單據編號 = B.單據編號
	INNER JOIN ViewFIL4030 C ON A.前置單別 = C.製令單別 AND A.前置單號 = C.製令單號
WHERE
	A.單據類別 = 'D11' AND
	A.前置單號 != ' '
/* 採購單 */

UNION

SELECT
	B.訂單號碼,
	C.產品編號,
	B.單據日期,
	trim(B.歸屬類別) || '.' || B.歸屬編號 父階,
	B.歸屬類別 父階單別,
	B.歸屬編號 父階單號,
	trim(A.單別) || '.' || A.單號 子階,
	A.單別 子階單別,
	A.單號 子階單號,
	trim(A.製程代碼) || ' ' || trim(A.機台代碼) || ' ' || to_char(A.聯絡人序號, '0000') 排序
FROM
	FIL0031 A
	INNER JOIN FIL0030 B ON A.單別 = B.單據類別 AND A.單號 = B.單據編號
	INNER JOIN FIL0032 C ON B.歸屬類別 = C.製令單別 AND B.歸屬編號 = C.製令單號
WHERE
	A.單別 = 'C31'
/* 生產排程 */

UNION

SELECT
	B.訂單號碼,
	C.產品編號,
	B.單據日期,
	trim(B.歸屬類別) || '.' || B.歸屬編號 父階,
	B.歸屬類別 父階單別,
	B.歸屬編號 父階單號,
	trim(A.單別) || '.' || A.單號 子階,
	A.單別 子階單別,
	A.單號 子階單號,
	trim(A.製程代碼) || ' ' || trim(A.機台代碼) || ' ' || to_char(A.交貨日期_天, '0000') 排序
FROM
	FIL0031 A
	INNER JOIN FIL0030 B ON A.單別 = B.單據類別 AND A.單號 = B.單據編號
	INNER JOIN FIL0032 C ON B.歸屬類別 = C.製令單別 AND B.歸屬編號 = C.製令單號
WHERE
	A.單別 = 'C41'
/* 日報表 */);

-- Oracle user_views
CREATE VIEW "VIEWFILA010" ("採購單號", "單據日期", "父階", "父階單別", "父階單號", "子階", "子階單別", "子階單號") AS (
SELECT
	A.採購單號,
	A.單據日期,
	' ' 父階,
	' ' 父階單別,
	' ' 父階單號,
	trim(A.單據類別) || '.' || A.單據編號 子階,
	A.單據類別 子階單別,
	A.單據編號 子階單號
FROM
	FIL0030 A
WHERE
	A.單據類別 = 'D11'
/* 採購單 */

UNION

SELECT
	A.採購單號,
	A.單據日期,
	trim(A.歸屬類別) || '.' || A.歸屬編號 父階,
	A.歸屬類別 父階單別,
	A.歸屬編號 父階單號,
	trim(A.單據類別) || '.' || A.單據編號 子階,
	A.單據類別 子階單別,
	A.單據編號 子階單號
FROM
	FIL0030 A
WHERE
	A.單據類別 = 'D21'
/* 進料單 */

UNION

SELECT
	A.採購單號,
	A.單據日期,
	trim(A.歸屬類別) || '.' || A.歸屬編號 父階,
	A.歸屬類別 父階單別,
	A.歸屬編號 父階單號,
	trim(A.單據類別) || '.' || A.單據編號 子階,
	A.單據類別 子階單別,
	A.單據編號 子階單號
FROM
	FIL0030 A
WHERE
	A.單據類別 = 'D41'
/* 退料單 */

UNION

SELECT
	A.採購單號,
	A.單據日期,
	trim(A.歸屬類別) || '.' || A.歸屬編號 父階,
	A.歸屬類別 父階單別,
	A.歸屬編號 父階單號,
	trim(A.單據類別) || '.' || A.單據編號 子階,
	A.單據類別 子階單別,
	A.單據編號 子階單號
FROM
	FIL0030 A
WHERE
	A.單據類別 = 'D31'
/* 檢驗單 */);

-- Oracle user_views
CREATE VIEW "VIEWFILE010" ("單別", "單號", "公司代碼", "公司名稱", "單據日期", "簽核系統", "備註", "倉管員", "倉管員姓名", "流水編號", "填表人", "填表人姓名", "填表日", "最後更新者", "更新者姓名", "最後更新日", "簽核狀態") AS (
SELECT
	A.單據類別 單別,
	A.單據編號 單號,
	A.公司代碼,
	nvl(E.全名, ' ') 公司名稱,
	A.單據日期,
	A.簽核系統, 
	A.備註, 
	A.業務員 倉管員,
	nvl(D.員工姓名,' ') 倉管員姓名, 	
	A.流水編號,
	A.填表人,
	nvl(Z1.員工姓名,' ') 填表人姓名, 
	A.填表日, 
	A.最後更新者,
	nvl(Z2.員工姓名,' ') 更新者姓名, 
	A.最後更新日,
	nvl(F.簽核狀態, '0') 簽核狀態
FROM
	FIL0030 A
	/*
	INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
	*/
	LEFT JOIN FIL0010 D ON A.業務員 = D.員工編號
	LEFT JOIN ViewFIL0011 E ON A.公司代碼 = E.代碼
	LEFT JOIN ViewOfObjProperties F ON A.流水編號 = F.單據流水號
	LEFT JOIN FIL0010 Z1 ON A.填表人 = Z1.員工編號
	LEFT JOIN FIL0010 Z2 ON A.最後更新者 = Z2.員工編號
WHERE
	A.單據類別 = 'E11');

-- Oracle user_views
CREATE VIEW "VIEWFILE011" ("單別", "單號", "序號", "料號", "品名", "規格", "盤點日期", "進貨日期", "有效日期", "廠別代碼", "倉別代碼", "庫別代碼", "庫別名稱", "庫存數量", "包裝數量", "庫存單位代碼", "庫存單位名稱", "包裝單位代碼", "包裝單位名稱", "批號", "廠商批號", "QRNO", "備註", "流水編號", "最後更新者", "更新者姓名", "最後更新日") AS (
SELECT 
	A.單據類別 單別, 
	A.單據編號 單號,
	A.單據序號 序號,
	A.產品編號 料號,
	nvl(E.品名, ' ') 品名,
	nvl(E.規格, ' ') 規格,
	A.異動日期 盤點日期,
	A.預交日 進貨日期,
	A.其它日期 有效日期,
	C.文數字4 廠別代碼,
	C.文數字5 倉別代碼,
	A.倉庫代碼 庫別代碼,
	nvl(G.名稱, ' ') 庫別名稱,
	A.異動數量 庫存數量,
	A.異動單價 包裝數量,
	A.單位代碼 庫存單位代碼,
	nvl(F1.名稱, ' ') 庫存單位名稱,
	A.文數字1 包裝單位代碼,
	nvl(F2.名稱, ' ') 包裝單位名稱,
	C.批號,
	A.廠客品號 廠商批號,
	A.QRNo,
	A.備註說明 備註,
	A.流水編號,
	A.最後更新者,
	NVL(Z1.員工姓名,' ') 更新者姓名,
	A.最後更新日
FROM 
	FIL0040 A
	/*特殊欄位*/
	INNER JOIN FIL0041 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號 AND A.單據序號 = C.序號
	LEFT JOIN ViewFIL1012 E ON A.產品編號 = E.產品編號
	LEFT JOIN ViewFIL3103 F1 ON A.單位代碼 = F1.代碼
	LEFT JOIN ViewFIL3103 F2 ON A.文數字1 = F2.代碼
	LEFT JOIN ViewFIL3106 G ON A.倉庫代碼 = G.代碼
	LEFT JOIN FIL0010 Z1 ON A.最後更新者 = Z1.員工編號
WHERE
	A.單據類別 = 'E11');

-- Oracle user_views
CREATE VIEW "VIEWFILE01A" ("單別", "單號", "庫存數量", "包裝數量") AS (
SELECT 
	A.單據類別 單別, 
	A.單據編號 單號,
	sum(A.異動數量) 庫存數量,
	sum(A.異動單價) 包裝數量
FROM 
	FIL0040 A
WHERE
	A.單據類別 = 'E11'
GROUP BY
	A.單據類別, 
	A.單據編號);

-- Oracle user_views
CREATE VIEW "VIEWFILE01B" ("批號", "廠商批號") AS (
SELECT DISTINCT
	C.批號,
	A.廠客品號 廠商批號
FROM 
	FIL0040 A
	/*特殊欄位*/
	INNER JOIN FIL0041 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號 AND A.單據序號 = C.序號
WHERE
	A.單據類別 = 'E11');

-- Oracle user_views
CREATE VIEW "VIEWFILE01C" ("單別", "單號", "序號", "料號", "品名", "規格", "單據日期", "入庫原因", "廠商名稱", "庫存異動數", "沖銷異動數", "待沖銷數") AS (
SELECT 
	A.單據類別 單別, 
	A.單據編號 單號,
	A.單據序號 序號,
	A.產品編號 料號,
	nvl(E.品名, ' ') 品名,
	nvl(E.規格, ' ') 規格,
	B.單據日期,
	D.名稱 入庫原因,
	F.全名 廠商名稱,
	abs(A.異動數量) 庫存異動數,
	NVL(abs(C.沖銷異動數),0) 沖銷異動數,
	GREATEST(abs(A.異動數量)-NVL(abs(C.沖銷異動數),0),0) 待沖銷數
FROM 
	FIL0040 A
	INNER JOIN FIL0030 B ON A.單據類別 = B.單據類別 AND A.單據編號 = B.單據編號
	INNER JOIN ViewFIL3127 D ON D.代碼 = B.收付方式
	INNER JOIN FIL0011 F ON F.編號 = B.廠客編號
	LEFT JOIN ViewFIL1012 E ON A.產品編號 = E.產品編號
	LEFT JOIN 
	(
	SELECT 
		前置單別,
		前置單號,
		圓周 前置序號,
		SUM(異動數量) 沖銷異動數
	FROM
		FIL0040
	WHERE
		單據類別 = 'E12'
	GROUP BY
		前置單別,
		前置單號,
		圓周
	) C ON C.前置單別 = A.單據類別 AND C.前置單號 = A.單據編號 AND C.前置序號 = A.單據序號
WHERE
	A.單據類別 = 'E11' AND B.收付方式 <> ' '
);

-- Oracle user_views
CREATE VIEW "VIEWFILE020" ("單別", "單號", "公司代碼", "公司名稱", "單據日期", "簽核系統", "備註", "倉管員", "倉管員姓名", "流水編號", "填表人", "填表人姓名", "填表日", "最後更新者", "更新者姓名", "最後更新日", "簽核狀態") AS (
SELECT
	A.單據類別 單別,
	A.單據編號 單號,
	A.公司代碼,
	nvl(E.全名, ' ') 公司名稱,
	A.單據日期,
	A.簽核系統, 
	A.備註, 
	A.業務員 倉管員,
	nvl(D.員工姓名,' ') 倉管員姓名, 	
	A.流水編號,
	A.填表人,
	nvl(Z1.員工姓名,' ') 填表人姓名, 
	A.填表日, 
	A.最後更新者,
	nvl(Z2.員工姓名,' ') 更新者姓名, 
	A.最後更新日,
	nvl(F.簽核狀態, '0') 簽核狀態
FROM
	FIL0030 A
	/*
	INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
	*/
	LEFT JOIN FIL0010 D ON A.業務員 = D.員工編號
	LEFT JOIN ViewFIL0011 E ON A.公司代碼 = E.代碼
	LEFT JOIN ViewOfObjProperties F ON A.流水編號 = F.單據流水號
	LEFT JOIN FIL0010 Z1 ON A.填表人 = Z1.員工編號
	LEFT JOIN FIL0010 Z2 ON A.最後更新者 = Z2.員工編號
WHERE
	A.單據類別 = 'E12');

-- Oracle user_views
CREATE VIEW "VIEWFILE021" ("單別", "單號", "序號", "料號", "品名", "規格", "調整日期", "廠別代碼", "倉別代碼", "庫別代碼", "庫別名稱", "入或領", "調整數量", "庫存單位代碼", "庫存單位名稱", "批號", "QRNO", "廠商批號", "有效日期", "製造日期", "備註", "流水編號", "最後更新者", "更新者姓名", "最後更新日") AS (
SELECT 
	A.單據類別 單別, 
	A.單據編號 單號,
	A.單據序號 序號,
	A.產品編號 料號,
	nvl(E.品名, ' ') 品名,
	nvl(E.規格, ' ') 規格,
	A.異動日期 調整日期,
	C.文數字4 廠別代碼,
	C.文數字5 倉別代碼,
	A.倉庫代碼 庫別代碼,
	nvl(G.名稱, ' ') 庫別名稱,
	A.Logical3 入或領,
	A.異動數量 調整數量,
	A.單位代碼 庫存單位代碼,
	nvl(F1.名稱, ' ') 庫存單位名稱,
	C.批號,
	A.QRNo,
	A.文數字1 廠商批號,
	A.預交日 有效日期,
	A.其它日期 製造日期,
	A.備註說明 備註,
	A.流水編號,
	A.最後更新者,
	NVL(Z1.員工姓名,' ') 更新者姓名,
	A.最後更新日
FROM 
	FIL0040 A
	/*特殊欄位*/
	INNER JOIN FIL0041 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號 AND A.單據序號 = C.序號
	LEFT JOIN ViewFIL1012 E ON A.產品編號 = E.產品編號
	LEFT JOIN ViewFIL3103 F1 ON A.單位代碼 = F1.代碼
	LEFT JOIN ViewFIL3106 G ON A.倉庫代碼 = G.代碼
	LEFT JOIN FIL0010 Z1 ON A.最後更新者 = Z1.員工編號
WHERE
	A.單據類別 = 'E12');

-- Oracle user_views
CREATE VIEW "VIEWFILE025" ("單別", "單號", "公司代碼", "公司名稱", "廠客編號", "單據日期", "簽核系統", "備註", "倉管員", "倉管員姓名", "機台代碼", "機台名稱", "流水編號", "填表人", "填表人姓名", "填表日", "最後更新者", "更新者姓名", "最後更新日", "簽核狀態") AS (
SELECT
	A.單據類別 單別,
	A.單據編號 單號,
	A.公司代碼,
	nvl(E.全名, ' ') 公司名稱,
	A.廠客編號,
	A.單據日期,
	A.簽核系統, 
	A.備註, 
	A.業務員 倉管員,
	nvl(D.員工姓名,' ') 倉管員姓名, 	
	B.機台代碼,
	Z3.名稱 機台名稱,
	A.流水編號,
	A.填表人,
	nvl(Z1.員工姓名,' ') 填表人姓名, 
	A.填表日, 
	A.最後更新者,
	nvl(Z2.員工姓名,' ') 更新者姓名, 
	A.最後更新日,
	nvl(F.簽核狀態, '0') 簽核狀態
FROM
	FIL0030 A
	INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
	LEFT JOIN FIL0010 D ON A.業務員 = D.員工編號
	LEFT JOIN ViewFIL0011 E ON A.公司代碼 = E.代碼
	LEFT JOIN ViewOfObjProperties F ON A.流水編號 = F.單據流水號
	LEFT JOIN FIL0010 Z1 ON A.填表人 = Z1.員工編號
	LEFT JOIN FIL0010 Z2 ON A.最後更新者 = Z2.員工編號
	LEFT JOIN ViewFIL310P Z3 ON Z3.代碼 = B.機台代碼 
WHERE
	A.單據類別 = 'E13');

-- Oracle user_views
CREATE VIEW "VIEWFILE026" ("單別", "單號", "序號", "料號", "品名", "規格", "調整日期", "廠別代碼", "倉別代碼", "庫別代碼", "庫別名稱", "調整數量", "庫存異動數", "庫存單位代碼", "庫存單位名稱", "批號", "QRNO", "廠商批號", "廠商規格", "有效日期", "製造日期", "備註", "標籤列印次數", "標籤列印日期", "流水編號", "最後更新者", "更新者姓名", "最後更新日") AS (
SELECT 
	A.單據類別 單別, 
	A.單據編號 單號,
	A.單據序號 序號,
	A.產品編號 料號,
	nvl(E.品名, ' ') 品名,
	nvl(E.規格, ' ') 規格,
	A.異動日期 調整日期,
	C.文數字4 廠別代碼,
	C.文數字5 倉別代碼,
	A.倉庫代碼 庫別代碼,
	nvl(G.名稱, ' ') 庫別名稱,
	A.異動數量 調整數量,
	A.數值2 庫存異動數,
	A.相關代碼2 庫存單位代碼,
	nvl(F1.名稱, ' ') 庫存單位名稱,
	C.批號,
	A.QRNo,
	A.文數字1 廠商批號,
	A.合併編號 廠商規格,
	A.預交日 有效日期,
	A.其它日期 製造日期,
	A.備註說明 備註,
	C.標籤列印次數,
	C.標籤列印日期,
	A.流水編號,
	A.最後更新者,
	NVL(Z1.員工姓名,' ') 更新者姓名,
	A.最後更新日
FROM 
	FIL0040 A
	/*特殊欄位*/
	INNER JOIN FIL0041 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號 AND A.單據序號 = C.序號
	LEFT JOIN ViewFIL1012 E ON A.產品編號 = E.產品編號
	LEFT JOIN ViewFIL3103 F1 ON A.單位代碼 = F1.代碼
	LEFT JOIN ViewFIL3106 G ON A.倉庫代碼 = G.代碼
	LEFT JOIN FIL0010 Z1 ON A.最後更新者 = Z1.員工編號
WHERE
	A.單據類別 = 'E13');

-- Oracle user_views
CREATE VIEW "VIEWFILE027" ("單別", "單號", "調整數量") AS (
SELECT 
	A.單據類別 單別, 
	A.單據編號 單號,
	sum(A.異動數量) 調整數量
FROM 
	FIL0040 A
WHERE
	A.單據類別 = 'E13'
GROUP BY
	A.單據類別, 
	A.單據編號);

-- Oracle user_views
CREATE VIEW "VIEWFILE02A" ("單別", "單號", "調整數量") AS (
SELECT 
	A.單據類別 單別, 
	A.單據編號 單號,
	sum(A.異動數量) 調整數量
FROM 
	FIL0040 A
WHERE
	A.單據類別 = 'E12'
GROUP BY
	A.單據類別, 
	A.單據編號);

-- Oracle user_views
CREATE VIEW "VIEWFILE02B" ("單別", "單號", "公司代碼", "公司名稱", "單據日期", "簽核系統", "備註", "倉管員", "倉管員姓名", "製令類別", "製令單號", "裁切單號", "分條號", "主旨", "員工流水編號", "流水編號", "填表人", "填表人姓名", "填表日", "最後更新者", "更新者姓名", "最後更新日", "簽核狀態") AS (
SELECT
	A.單據類別 單別,
	A.單據編號 單號,
	A.公司代碼,
	nvl(E.全名, ' ') 公司名稱,
	A.單據日期,
	A.簽核系統, 
	A.備註, 
	A.業務員 倉管員,
	nvl(D.員工姓名,' ') 倉管員姓名, 	
	A.歸屬類別 製令類別,
	A.歸屬編號 製令單號,
	A.廠客單號 裁切單號,
	M.分條號,
	A.單據編號||'('||trim(A.單據類別)||')'||'/製令:'||nvl(A.歸屬編號, ' ') 主旨,
	nvl(Z1.Serial_Num,' ') 員工流水編號,
	A.流水編號,
	A.填表人,
	nvl(Z1.員工姓名,' ') 填表人姓名, 
	A.填表日, 
	A.最後更新者,
	nvl(Z2.員工姓名,' ') 更新者姓名, 
	A.最後更新日,
	nvl(F.簽核狀態, '0') 簽核狀態
FROM
	FIL0030 A
	/*
	INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
	*/
	LEFT JOIN FIL0010 D ON A.業務員 = D.員工編號
	LEFT JOIN ViewFIL0011 E ON A.公司代碼 = E.代碼
	LEFT JOIN ViewOfObjProperties F ON A.流水編號 = F.單據流水號
	LEFT JOIN FIL0010 Z1 ON A.填表人 = Z1.員工編號
	LEFT JOIN FIL0010 Z2 ON A.最後更新者 = Z2.員工編號
	LEFT JOIN 
	(SELECT 
		A.單據類別 單別, 
		A.單據編號 單號,
		listagg(REGEXP_SUBSTR(A.產品編號, '[^_]+', 1, 2),',') within group (order by A.單據類別,A.單據編號) 分條號
	FROM 
		FIL0040 A
	WHERE
		A.單據類別 = 'E22' AND A.異動類別 = 'A'
	GROUP BY
		A.單據類別,
		A.單據編號) M 
	ON M.單別=A.單據類別 and M.單號=A.單據編號	
WHERE
	A.單據類別 = 'E22');

-- Oracle user_views
CREATE VIEW "VIEWFILE02C" ("單別", "單號", "序號", "異動類別", "半成品編號", "品名", "規格", "調整日期", "廠別代碼", "倉別代碼", "庫別代碼", "庫別名稱", "調整數量", "報廢數量", "庫存單位代碼", "庫存單位名稱", "製令單號", "QRCODE", "製成品編號", "接頭數", "備註", "作業者", "作業者姓名", "流水編號", "最後更新者", "更新者姓名", "最後更新日") AS (
SELECT 
	A.單據類別 單別, 
	A.單據編號 單號,
	A.單據序號 序號,
	A.異動類別,
	A.產品編號 半成品編號,
	nvl(E.品名, ' ') 品名,
	nvl(E.規格, ' ') 規格,
	A.異動日期 調整日期,
	C.文數字4 廠別代碼,
	C.文數字5 倉別代碼,
	A.倉庫代碼 庫別代碼,
	nvl(G.名稱, ' ') 庫別名稱,
	A.異動數量 調整數量,
	A.數值1	報廢數量,
	A.單位代碼 庫存單位代碼,
	nvl(F1.名稱, ' ') 庫存單位名稱,
	A.前置單號 製令單號,
	A.產品編號 QRCode,
	A.廠客品號 製成品編號,
	A.毛重 接頭數,
	A.備註說明 備註,
	A.文數字1 作業者,
	NVL(Z2.員工姓名,' ') 作業者姓名,
	A.流水編號,
	A.最後更新者,
	NVL(Z1.員工姓名,' ') 更新者姓名,
	A.最後更新日
FROM 
	FIL0040 A
	/*特殊欄位*/
	INNER JOIN FIL0041 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號 AND A.單據序號 = C.序號
	LEFT JOIN FIL0032 B ON REGEXP_SUBSTR(A.產品編號, '[^_]+', 1,1)=B.製令單號 
	LEFT JOIN ViewFIL1012 E ON B.產品編號 = E.產品編號
	LEFT JOIN ViewFIL3103 F1 ON A.單位代碼 = F1.代碼
	LEFT JOIN ViewFIL3106 G ON A.倉庫代碼 = G.代碼
	LEFT JOIN FIL0010 Z1 ON A.最後更新者 = Z1.員工編號
	LEFT JOIN FIL0010 Z2 ON A.文數字1 = Z2.員工編號
WHERE
	A.單據類別 = 'E22');

-- Oracle user_views
CREATE VIEW "VIEWFILE02D" ("單別", "單號", "異動類別", "調整數量", "報廢數量") AS (
SELECT 
	A.單據類別 單別, 
	A.單據編號 單號,
	A.異動類別,
	sum(A.異動數量) 調整數量,
	sum(A.數值1) 報廢數量
FROM 
	FIL0040 A
WHERE
	A.單據類別 = 'E22'
GROUP BY
	A.單據類別, 
	A.單據編號,
	A.異動類別
);

-- Oracle user_views
CREATE VIEW "VIEWFILE02H" ("單別", "單號", "公司代碼", "公司名稱", "製令類別", "製令單號", "單據日期", "簽核系統", "備註", "倉管員", "倉管員姓名", "分條號", "流水編號", "填表人", "填表人姓名", "填表日", "最後更新者", "更新者姓名", "最後更新日", "簽核狀態") AS (
SELECT
	A.單據類別 單別,
	A.單據編號 單號,
	A.公司代碼,
	nvl(E.全名, ' ') 公司名稱,
	A.歸屬類別 製令類別,
	A.歸屬編號 製令單號,
	A.單據日期,
	A.簽核系統, 
	A.備註, 
	A.業務員 倉管員,
	nvl(D.員工姓名,' ') 倉管員姓名,
	M.分條號,
	A.流水編號,
	A.填表人,
	nvl(Z1.員工姓名,' ') 填表人姓名, 
	A.填表日, 
	A.最後更新者,
	nvl(Z2.員工姓名,' ') 更新者姓名, 
	A.最後更新日,
	nvl(F.簽核狀態, '0') 簽核狀態
FROM
	FIL0030 A
	/*
	INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
	*/
	LEFT JOIN FIL0010 D ON A.業務員 = D.員工編號
	LEFT JOIN ViewFIL0011 E ON A.公司代碼 = E.代碼
	LEFT JOIN ViewOfObjProperties F ON A.流水編號 = F.單據流水號
	LEFT JOIN FIL0010 Z1 ON A.填表人 = Z1.員工編號
	LEFT JOIN FIL0010 Z2 ON A.最後更新者 = Z2.員工編號
	LEFT JOIN
	(SELECT 
		A.單據類別 單別, 
		A.單據編號 單號,
		listagg(REGEXP_SUBSTR(A.產品編號, '[^_]+', 1, 2),',') within group (order by A.單據類別,A.單據編號) 分條號
	FROM 
		FIL0040 A
	WHERE
		A.單據類別 = 'E23' AND A.異動類別 = 'A'
	GROUP BY
		A.單據類別,
		A.單據編號) M 
	ON M.單別=A.單據類別 and M.單號=A.單據編號	
WHERE
	A.單據類別 = 'E23');

-- Oracle user_views
CREATE VIEW "VIEWFILE02I" ("單別", "單號", "序號", "異動類別", "半成品編號", "品名", "規格", "調整日期", "廠別代碼", "倉別代碼", "庫別代碼", "庫別名稱", "調整數量", "庫存單位代碼", "庫存單位名稱", "製令單號", "QRCODE", "製成品編號", "接頭數", "備註", "作業者", "作業者姓名", "流水編號", "最後更新者", "更新者姓名", "最後更新日") AS (
SELECT 
	A.單據類別 單別, 
	A.單據編號 單號,
	A.單據序號 序號,
	A.異動類別,
	A.產品編號 半成品編號,
	nvl(E.品名, ' ') 品名,
	nvl(E.規格, ' ') 規格,
	A.異動日期 調整日期,
	C.文數字4 廠別代碼,
	C.文數字5 倉別代碼,
	A.倉庫代碼 庫別代碼,
	nvl(G.名稱, ' ') 庫別名稱,
	A.異動數量 調整數量,
	A.單位代碼 庫存單位代碼,
	nvl(F1.名稱, ' ') 庫存單位名稱,
	C.批號 製令單號,
	A.產品編號 QRCode,
	A.廠客品號 製成品編號,
	A.毛重 接頭數,
	A.備註說明 備註,
	A.文數字1 作業者,
	NVL(Z2.員工姓名,' ') 作業者姓名,
	A.流水編號,
	A.最後更新者,
	NVL(Z1.員工姓名,' ') 更新者姓名,
	A.最後更新日
FROM 
	FIL0040 A
	/*特殊欄位*/
	INNER JOIN FIL0041 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號 AND A.單據序號 = C.序號
	LEFT JOIN FIL0032 B ON REGEXP_SUBSTR(A.產品編號, '[^_]+', 1,1)=B.製令單號 
	LEFT JOIN ViewFIL1012 E ON B.產品編號 = E.產品編號
	LEFT JOIN ViewFIL3103 F1 ON A.單位代碼 = F1.代碼
	LEFT JOIN ViewFIL3106 G ON A.倉庫代碼 = G.代碼
	LEFT JOIN FIL0010 Z1 ON A.最後更新者 = Z1.員工編號
	LEFT JOIN FIL0010 Z2 ON A.文數字1 = Z2.員工編號
WHERE
	A.單據類別 = 'E23');

-- Oracle user_views
CREATE VIEW "VIEWFILE02J" ("單別", "單號", "異動類別", "調整數量") AS (
SELECT 
	A.單據類別 單別, 
	A.單據編號 單號,
	A.異動類別,
	sum(A.異動數量) 調整數量
FROM 
	FIL0040 A
WHERE
	A.單據類別 = 'E23'
GROUP BY
	A.單據類別, 
	A.單據編號,
	A.異動類別
);

-- Oracle user_views
CREATE VIEW "VIEWFILE02K" ("單別", "單號", "公司代碼", "公司名稱", "單據日期", "簽核系統", "備註", "倉管員", "倉管員姓名", "流水編號", "填表人", "填表人姓名", "填表日", "最後更新者", "更新者姓名", "最後更新日", "簽核狀態") AS (
SELECT
	A.單據類別 單別,
	A.單據編號 單號,
	A.公司代碼,
	nvl(E.全名, ' ') 公司名稱,
	A.單據日期,
	A.簽核系統, 
	A.備註, 
	A.業務員 倉管員,
	nvl(D.員工姓名,' ') 倉管員姓名, 	
	A.流水編號,
	A.填表人,
	nvl(Z1.員工姓名,' ') 填表人姓名, 
	A.填表日, 
	A.最後更新者,
	nvl(Z2.員工姓名,' ') 更新者姓名, 
	A.最後更新日,
	nvl(F.簽核狀態, '0') 簽核狀態
FROM
	FIL0030 A
	/*
	INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
	*/
	LEFT JOIN FIL0010 D ON A.業務員 = D.員工編號
	LEFT JOIN ViewFIL0011 E ON A.公司代碼 = E.代碼
	LEFT JOIN ViewOfObjProperties F ON A.流水編號 = F.單據流水號
	LEFT JOIN FIL0010 Z1 ON A.填表人 = Z1.員工編號
	LEFT JOIN FIL0010 Z2 ON A.最後更新者 = Z2.員工編號
WHERE
	A.單據類別 = 'E24');

-- Oracle user_views
CREATE VIEW "VIEWFILE02L" ("單別", "單號", "序號", "製令單別", "製令單號", "本製程編號", "製程編號", "加工別", "批號", "盤點日期", "製造日期", "有效日期", "庫存數量", "接頭數", "規格", "廠商批號", "廠商規格", "備註說明", "標籤列印次數", "流水編號", "最後更新者", "更新者姓名", "最後更新日") AS (
SELECT 
	A.單據類別 單別, 
	A.單據編號 單號,
	A.單據序號 序號,
	A.前置單別 製令單別,
	A.前置單號 製令單號,
	A.產品編號 本製程編號,
	A.廠客品號 製程編號,
	C.小單位 加工別,
	C.批號 批號,
	A.異動日期 盤點日期,
	A.預交日 製造日期,
	A.其它日期 有效日期,
	A.異動單價 庫存數量,
	A.接頭數,
	A.相關代碼1 規格,
	A.相關代碼2 廠商批號,
	A.相關代碼3 廠商規格,
	A.備註說明,
	C.標籤列印次數,
	A.流水編號,
	A.最後更新者,
	NVL(Z1.員工姓名,' ') 更新者姓名,
	A.最後更新日
FROM 
	FIL0040 A
	/*特殊欄位*/
	INNER JOIN FIL0041 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號 AND A.單據序號 = C.序號
	LEFT JOIN FIL0010 Z1 ON A.最後更新者 = Z1.員工編號
WHERE
	A.單據類別 = 'E24' and A.異動類別='A');

-- Oracle user_views
CREATE VIEW "VIEWFILE02M" ("單別", "單號", "庫存數量", "包裝數量") AS (
SELECT 
	A.單據類別 單別, 
	A.單據編號 單號,
	sum(A.異動數量) 庫存數量,
	sum(A.異動單價) 包裝數量
FROM 
	FIL0040 A
WHERE
	A.單據類別 = 'E24'
GROUP BY
	A.單據類別, 
	A.單據編號);

-- Oracle user_views
CREATE VIEW "VIEWFILE030" ("單別", "單號", "公司代碼", "公司名稱", "單據日期", "簽核系統", "備註", "倉管員", "倉管員姓名", "流水編號", "填表人", "填表人姓名", "填表日", "最後更新者", "更新者姓名", "最後更新日", "簽核狀態") AS (
SELECT
	A.單據類別 單別,
	A.單據編號 單號,
	A.公司代碼,
	nvl(E.全名, ' ') 公司名稱,
	A.單據日期,
	A.簽核系統, 
	A.備註, 
	A.業務員 倉管員,
	nvl(D.員工姓名,' ') 倉管員姓名, 	
	A.流水編號,
	A.填表人,
	nvl(Z1.員工姓名,' ') 填表人姓名, 
	A.填表日, 
	A.最後更新者,
	nvl(Z2.員工姓名,' ') 更新者姓名, 
	A.最後更新日,
	nvl(F.簽核狀態, '0') 簽核狀態
FROM
	FIL0030 A
	/*
	INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
	*/
	LEFT JOIN FIL0010 D ON A.業務員 = D.員工編號
	LEFT JOIN ViewFIL0011 E ON A.公司代碼 = E.代碼
	LEFT JOIN ViewFIL0030 F ON A.簽核系統 = F.簽核系統 AND A.單據編號 = F.單號
	LEFT JOIN FIL0010 Z1 ON A.填表人 = Z1.員工編號
	LEFT JOIN FIL0010 Z2 ON A.最後更新者 = Z2.員工編號
WHERE
	A.單據類別 = 'E32');

-- Oracle user_views
CREATE VIEW "VIEWFILE031" ("單別", "單號", "序號", "料號", "品名", "規格", "盤點日期", "進貨日期", "庫別代碼", "庫別名稱", "箱號", "包裝數量", "重量", "紙箱料號", "紙箱重量", "庫存單位代碼", "庫存單位名稱", "包裝單位代碼", "包裝單位名稱", "批號", "幾束一袋", "氣閥重量", "鐵條重量", "調整前製袋重量", "調整前氣閥重量", "調整前鐵條重量", "製令單號", "QRNO", "備註", "業務員", "業務員二", "業務員三", "業務員姓名", "業務員姓名二", "業務員姓名三", "領用或入庫", "流水編號", "最後更新者", "更新者姓名", "最後更新日") AS (
SELECT 
	A.單據類別 單別, 
	A.單據編號 單號,
	A.單據序號 序號,
	A.產品編號 料號,
	nvl(E.品名, ' ') 品名,
	nvl(E.規格, ' ') 規格,
	A.異動日期 盤點日期,
	A.預交日 進貨日期,
	A.倉庫代碼 庫別代碼,
	nvl(G.名稱, ' ') 庫別名稱,
	A.異動數量 箱號,
	A.贈品數量 包裝數量,
	A.毛重 重量,
	A.前置單號 紙箱料號,
	nvl(C.數值11,0) 紙箱重量,
	A.單位代碼 庫存單位代碼,
	nvl(F1.名稱, ' ') 庫存單位名稱,
	A.文數字1 包裝單位代碼,
	nvl(F2.名稱, ' ') 包裝單位名稱,
	C.批號,
	C.數值1 幾束一袋,
	C.數值2 氣閥重量,
	C.數值3 鐵條重量,
	C.數值8	調整前製袋重量,
	C.數值9 調整前氣閥重量,
	C.數值10 調整前鐵條重量,
	A.廠客品號 製令單號,
	A.QRNo,
	A.備註說明 備註,
	C.文數字1 業務員,
	C.文數字2 業務員二,
	C.文數字3 業務員三,
	NVL(Z2.員工姓名,' ') 業務員姓名,
	NVL(Z3.員工姓名,' ') 業務員姓名二,
	NVL(Z4.員工姓名,' ') 業務員姓名三,
	A.Logical3 領用或入庫,
	A.流水編號,
	A.最後更新者,
	NVL(Z1.員工姓名,' ') 更新者姓名,
	A.最後更新日
FROM 
	FIL0040 A
	/*特殊欄位*/
	INNER JOIN FIL0041 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號 AND A.單據序號 = C.序號
	LEFT JOIN FIL0012 B ON A.前置單號 = B.產品編號
	LEFT JOIN ViewFIL1012 E ON A.產品編號 = E.產品編號
	LEFT JOIN ViewFIL3103 F1 ON A.單位代碼 = F1.代碼
	LEFT JOIN ViewFIL3103 F2 ON A.文數字1 = F2.代碼
	LEFT JOIN ViewFIL3106 G ON A.倉庫代碼 = G.代碼
	LEFT JOIN FIL0010 Z1 ON A.最後更新者 = Z1.員工編號
	LEFT JOIN FIL0010 Z2 ON C.文數字1 = Z2.員工編號
	LEFT JOIN FIL0010 Z3 ON C.文數字2 = Z3.員工編號
	LEFT JOIN FIL0010 Z4 ON C.文數字3 = Z4.員工編號
WHERE
	A.單據類別 = 'E32');

-- Oracle user_views
CREATE VIEW "VIEWFILE032" ("單別", "單號", "庫存數量", "包裝數量") AS (
SELECT 
	A.單據類別 單別, 
	A.單據編號 單號,
	count(A.異動數量) 庫存數量,
	sum(A.贈品數量) 包裝數量
FROM 
	FIL0040 A
WHERE
	A.單據類別 = 'E32'
GROUP BY
	A.單據類別, 
	A.單據編號);

-- Oracle user_views
CREATE VIEW "VIEWFILE032A" ("製令單別", "製令單號", "箱號", "平均袋重", "紙箱重量", "氣閥重量", "鐵條重量", "每袋幾束") AS (
SELECT	
	TO_CHAR('C11') 製令單別,
	A.廠客品號 製令單號,
	A.異動數量 箱號,
	DECODE(sum(A.贈品數量),0,0,sum(A.毛重)/sum(A.贈品數量)) 平均袋重,
	max(nvl(B.單價下限率,0)) 紙箱重量,
	max(DECODE(A.贈品數量,0,0,nvl(C.數值2,0)/A.贈品數量)) 氣閥重量,
	max(DECODE(A.贈品數量,0,0,nvl(C.數值3,0)/A.贈品數量)) 鐵條重量,
	max(nvl(C.數值1,0)) 每袋幾束
FROM 
	FIL0040 A
	INNER JOIN FIL0041 C ON A.單據類別=C.單別 AND A.單據編號=C.單號 AND A.單據序號=C.序號
	LEFT JOIN FIL0012 B ON A.前置單號 = B.產品編號
WHERE
	A.單據類別 = 'E32'
Group by 
	TO_CHAR('C11'),
	A.廠客品號,
	A.異動數量
);

-- Oracle user_views
CREATE VIEW "VIEWFILE033" ("單別", "單號", "製令單別", "製令單號", "公司代碼", "公司名稱", "單據日期", "簽核系統", "備註", "倉管員", "倉管員姓名", "報廢數量", "重工人員1", "重工人員2", "重工人員3", "重工人員4", "品檢人員", "重工人員名稱1", "重工人員名稱2", "重工人員名稱3", "重工人員名稱4", "品檢人員名稱", "判定", "流水編號", "填表人", "填表人姓名", "填表日", "最後更新者", "更新者姓名", "最後更新日", "簽核狀態", "主旨", "員工流水編號", "指定簽核人員") AS (
SELECT
	A.單據類別 單別,
	A.單據編號 單號,
	A.歸屬類別 製令單別,
	A.歸屬編號 製令單號,
	A.公司代碼,
	nvl(E.全名, ' ') 公司名稱,
	A.單據日期,
	A.簽核系統, 
	A.備註, 
	A.業務員 倉管員,
	nvl(D.員工姓名,' ') 倉管員姓名, 	
	A.折讓 報廢數量,
	H.文數字1 重工人員1,
	H.文數字2 重工人員2,
	H.文數字3 重工人員3,
	H.文數字4 重工人員4,
	H.文數字5 品檢人員,
	NVL(Z2.員工姓名,' ') 重工人員名稱1,
	NVL(Z3.員工姓名,' ') 重工人員名稱2,
	NVL(Z4.員工姓名,' ') 重工人員名稱3,
	NVL(Z5.員工姓名,' ') 重工人員名稱4,
	NVL(Z6.員工姓名,' ') 品檢人員名稱,
	A.匯率類別 判定,
	A.流水編號,
	A.填表人,
	nvl(Z1.員工姓名,' ') 填表人姓名, 
	A.填表日, 
	A.最後更新者,
	nvl(Z2.員工姓名,' ') 更新者姓名, 
	A.最後更新日,
	nvl(Z8.簽核狀態, '0') 簽核狀態,
	A.單據編號||'('||trim(A.單據類別)||')' 主旨,
	nvl(Z1.Serial_Num,' ') 員工流水編號,
	nvl(Z6.Serial_Num,' ') 指定簽核人員
FROM
	FIL0030 A
	LEFT JOIN FIL0031 H ON A.單據類別 = H.單別 AND A.單據編號 = H.單號
	LEFT JOIN FIL0010 D ON A.業務員 = D.員工編號
	LEFT JOIN ViewFIL0011 E ON A.公司代碼 = E.代碼
	LEFT JOIN FIL0010 Z1 ON A.填表人 = Z1.員工編號
	LEFT JOIN FIL0010 Z2 ON A.最後更新者 = Z2.員工編號
	LEFT JOIN FIL0010 Z1 ON A.最後更新者 = Z1.員工編號
	LEFT JOIN FIL0010 Z2 ON H.文數字1 = Z2.員工編號
	LEFT JOIN FIL0010 Z3 ON H.文數字2 = Z3.員工編號
	LEFT JOIN FIL0010 Z4 ON H.文數字3 = Z4.員工編號
	LEFT JOIN FIL0010 Z5 ON H.文數字4 = Z5.員工編號
	LEFT JOIN FIL0010 Z6 ON H.文數字5 = Z6.員工編號
	LEFT JOIN FIL0010 Z7 ON A.業務員 = Z7.員工編號
	LEFT JOIN ViewOfObjProperties Z8 ON A.流水編號 = Z8.單據流水號
WHERE
	A.單據類別 = 'E33');

-- Oracle user_views
CREATE VIEW "VIEWFILE034" ("單別", "單號", "序號", "單據日期", "異動類別", "父項序號", "料號", "品名", "規格", "盤點日期", "進貨日期", "庫別代碼", "庫別名稱", "箱號", "包裝數量", "報廢數量", "重量", "庫存單位代碼", "庫存單位名稱", "包裝單位代碼", "包裝單位名稱", "批號", "幾束一袋", "氣閥重量", "鐵條重量", "製袋重量", "製令單別", "製令單號", "QRNO", "紙箱代碼", "備註", "流水編號", "最後更新者", "更新者姓名", "最後更新日", "倉管人員", "重工人員1", "重工人員2", "重工人員3", "重工人員4", "品檢人員", "重工人員名稱1", "重工人員名稱2", "重工人員名稱3", "重工人員名稱4", "品檢人員名稱", "倉管人員名稱") AS (
SELECT 
	A.單據類別 單別, 
	A.單據編號 單號,
	A.單據序號 序號,
	B.單據日期,
	A.異動類別,
	A.數值1 父項序號,
	D.產品編號 料號,
	nvl(E.品名, ' ') 品名,
	nvl(E.規格, ' ') 規格,
	A.異動日期 盤點日期,
	A.預交日 進貨日期,
	A.倉庫代碼 庫別代碼,
	nvl(G.名稱, ' ') 庫別名稱,
	A.異動數量 箱號,
	A.贈品數量 包裝數量,
	decode(A.異動類別,'A',0,0) 報廢數量,
	A.毛重 重量,
	A.單位代碼 庫存單位代碼,
	nvl(F1.名稱, ' ') 庫存單位名稱,
	A.文數字1 包裝單位代碼,
	nvl(F2.名稱, ' ') 包裝單位名稱,
	C.批號,
	C.數值1 幾束一袋,
	C.數值2 氣閥重量,
	C.數值3 鐵條重量,
	A.毛重 製袋重量,
	B.歸屬類別 製令單別,
	B.歸屬編號 製令單號,
	A.QRNo,
	A.前置單號 紙箱代碼,
	A.備註說明 備註,
	A.流水編號,
	A.最後更新者,
	NVL(Z1.員工姓名,' ') 更新者姓名,
	A.最後更新日,	
	B.業務員 倉管人員,
	H.文數字1 重工人員1,
	H.文數字2 重工人員2,
	H.文數字3 重工人員3,
	H.文數字4 重工人員4,
	H.文數字5 品檢人員,
	NVL(Z2.員工姓名,' ') 重工人員名稱1,
	NVL(Z3.員工姓名,' ') 重工人員名稱2,
	NVL(Z4.員工姓名,' ') 重工人員名稱3,
	NVL(Z5.員工姓名,' ') 重工人員名稱4,
	NVL(Z6.員工姓名,' ') 品檢人員名稱,
	NVL(Z7.員工姓名,' ') 倉管人員名稱
FROM 
	FIL0040 A
	INNER JOIN FIL0030 B ON A.單據類別 = B.單據類別 AND A.單據編號 = B.單據編號 
	LEFT JOIN FIL0031 H ON A.單據類別 = H.單別 AND A.單據編號 = H.單號 
	/*特殊欄位*/
	LEFT JOIN FIL0041 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號 AND A.單據序號 = C.序號
	LEFT JOIN FIL0032 D ON D.製令單別 = B.歸屬類別 AND D.製令單號 = B.歸屬編號  
	LEFT JOIN ViewFIL1012 E ON D.產品編號 = E.產品編號
	LEFT JOIN ViewFIL3103 F1 ON A.單位代碼 = F1.代碼
	LEFT JOIN ViewFIL3103 F2 ON A.文數字1 = F2.代碼
	LEFT JOIN ViewFIL3106 G ON A.倉庫代碼 = G.代碼
	LEFT JOIN FIL0010 Z1 ON A.最後更新者 = Z1.員工編號
	LEFT JOIN FIL0010 Z2 ON H.文數字1 = Z2.員工編號
	LEFT JOIN FIL0010 Z3 ON H.文數字2 = Z3.員工編號
	LEFT JOIN FIL0010 Z4 ON H.文數字3 = Z4.員工編號
	LEFT JOIN FIL0010 Z5 ON H.文數字4 = Z5.員工編號
	LEFT JOIN FIL0010 Z6 ON H.文數字5 = Z6.員工編號
	LEFT JOIN FIL0010 Z7 ON B.業務員 = Z7.員工編號
WHERE
	A.單據類別 = 'E33');

-- Oracle user_views
CREATE VIEW "VIEWFILE035" ("單別", "單號", "異動類別", "包裝數量", "重量", "箱數", "氣閥重量", "鐵條重量", "製袋重量", "紙箱重量") AS (
SELECT 
	A.單據類別 單別, 
	A.單據編號 單號,
	A.異動類別,
	SUM(A.贈品數量) 包裝數量,
	Sum(A.毛重+C.數值2+C.數值3+C.數值8) 重量,
	count(單據序號) 箱數,
	sum(C.數值2) 氣閥重量,
	sum(C.數值3) 鐵條重量,
	sum(A.毛重) 製袋重量,
	sum(C.數值8) 紙箱重量
FROM 
	FIL0040 A
	/*特殊欄位*/
	INNER JOIN FIL0041 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號 AND A.單據序號 = C.序號
WHERE
	A.單據類別 = 'E33'
GROUP BY
	A.單據類別, 
	A.單據編號,
	A.異動類別
);

-- Oracle user_views
CREATE VIEW "VIEWFILE035A" ("製令類別", "製令單號", "箱號", "平均袋重", "數量", "製袋重量", "氣閥重量", "鐵條重量", "紙箱重量") AS (
SELECT 
	To_Char('C11') 製令類別,
	A.廠客品號 製令單號,
	A.異動數量 箱號,
	SUM(A.毛重)/SUM(A.贈品數量*decode(A.異動類別,'A',-1,1)) 平均袋重,
	SUM(A.贈品數量*decode(A.異動類別,'A',-1,1)) 數量,
	SUM(A.毛重*decode(A.異動類別,'A',-1,1)) 製袋重量,
	SUM(B.數值2*decode(A.異動類別,'A',-1,1)) 氣閥重量,
	SUM(B.數值3*decode(A.異動類別,'A',-1,1)) 鐵條重量,
	SUM(B.數值8*decode(A.異動類別,'A',-1,1)) 紙箱重量
FROM 
	FIL0040 A
	INNER JOIN FIL0041 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號 AND A.單據序號 = B.序號
	INNER JOIN FIL0030 D ON A.單據類別 = D.單據類別 AND A.單據編號 = D.單據編號
WHERE
	A.單據類別 = 'E33' AND A.贈品數量<>0
GROUP BY
	To_Char('C11'),
	A.廠客品號,
	A.異動數量	
);

-- Oracle user_views
CREATE VIEW "VIEWFILE036" ("單別", "單號", "公司代碼", "公司名稱", "單據日期", "簽核系統", "備註", "倉管員", "倉管員姓名", "流水編號", "填表人", "填表人姓名", "填表日", "最後更新者", "更新者姓名", "車號", "最後更新日", "簽核狀態", "廠商簽收") AS (
SELECT
	A.單據類別 單別,
	A.單據編號 單號,
	A.公司代碼,
	nvl(E.全名, ' ') 公司名稱,
	A.單據日期,
	A.簽核系統, 
	A.備註, 
	A.業務員 倉管員,
	nvl(D.員工姓名,' ') 倉管員姓名, 	
	A.流水編號,
	A.填表人,
	nvl(Z1.員工姓名,' ') 填表人姓名, 
	A.填表日, 
	A.最後更新者,
	nvl(Z2.員工姓名,' ') 更新者姓名, 
	B.製程代碼 車號,
	A.最後更新日,
	nvl(F.簽核狀態, '0') 簽核狀態,
	DECODE(nvl(dbms_lob.getlength(G.圖檔),0),0,0,1) 廠商簽收
FROM
	FIL0030 A
	LEFT JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
	LEFT JOIN FIL0010 D ON A.業務員 = D.員工編號
	LEFT JOIN ViewFIL0011 E ON A.公司代碼 = E.代碼
	LEFT JOIN ViewFIL0030 F ON A.簽核系統 = F.簽核系統 AND A.單據編號 = F.單號
	LEFT JOIN FIL0010 Z1 ON A.填表人 = Z1.員工編號
	LEFT JOIN FIL0010 Z2 ON A.最後更新者 = Z2.員工編號
	LEFT JOIN FIL0037 G ON A.單據類別 = G.製令單別 AND A.單據編號 = G.製令單號 AND G.材料序號=0
WHERE
	A.單據類別 = 'E35');

-- Oracle user_views
CREATE VIEW "VIEWFILE037" ("單別", "單號", "序號", "料號", "品名", "規格", "異動日期", "預交日", "庫別代碼", "庫別名稱", "箱號", "包裝數量", "重量", "庫存單位代碼", "庫存單位名稱", "包裝單位代碼", "包裝單位名稱", "箱數", "批號", "製令單號", "QRNO", "備註", "流水編號", "最後更新者", "更新者姓名", "最後更新日") AS (
SELECT 
	A.單據類別 單別, 
	A.單據編號 單號,
	A.單據序號 序號,
	A.產品編號 料號,
	nvl(E.品名, ' ') 品名,
	nvl(E.規格, ' ') 規格,
	A.異動日期,
	A.預交日,
	A.倉庫代碼 庫別代碼,
	nvl(G.名稱, ' ') 庫別名稱,
	A.異動數量 箱號,
	A.贈品數量 包裝數量,
	A.毛重 重量,
	A.單位代碼 庫存單位代碼,
	nvl(F1.名稱, ' ') 庫存單位名稱,
	A.文數字1 包裝單位代碼,
	nvl(F2.名稱, ' ') 包裝單位名稱,
	A.數值1 箱數,
	C.批號,
	A.廠客品號 製令單號,
	A.QRNo,
	A.備註說明 備註,
	A.流水編號,
	A.最後更新者,
	NVL(Z1.員工姓名,' ') 更新者姓名,
	A.最後更新日
FROM 
	FIL0040 A
	/*特殊欄位*/
	LEFT JOIN FIL0041 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號 AND A.單據序號 = C.序號
	LEFT JOIN ViewFIL1012 E ON A.產品編號 = E.產品編號
	LEFT JOIN ViewFIL3103 F1 ON A.單位代碼 = F1.代碼
	LEFT JOIN ViewFIL3103 F2 ON A.文數字1 = F2.代碼
	LEFT JOIN ViewFIL3106 G ON A.倉庫代碼 = G.代碼
	LEFT JOIN FIL0010 Z1 ON A.最後更新者 = Z1.員工編號
WHERE
	A.單據類別 = 'E35');

-- Oracle user_views
CREATE VIEW "VIEWFILE038" ("單別", "單號", "箱數", "包裝數量") AS (
SELECT 
	A.單據類別 單別, 
	A.單據編號 單號,
	sum(A.數值1) 箱數,
	sum(A.贈品數量) 包裝數量
FROM 
	FIL0040 A
WHERE
	A.單據類別 = 'E35'
GROUP BY
	A.單據類別, 
	A.單據編號);

-- Oracle user_views
CREATE VIEW "VIEWFILE039" ("單別", "單號", "裝櫃單別", "貨櫃號碼", "嘜頭序號", "公司代碼", "公司名稱", "單據日期", "簽核系統", "備註", "品檢員", "品檢員姓名", "流水編號", "填表人", "填表人姓名", "填表日", "最後更新者", "更新者姓名", "製程代碼", "工站代碼", "機台代碼", "機台名稱", "工站名稱", "製程名稱", "最後更新日", "簽核狀態", "品檢簽收") AS (
SELECT
	A.單據類別 單別,
	A.單據編號 單號,
	A.歸屬類別 裝櫃單別,
	A.歸屬編號 貨櫃號碼,
	A.歸屬序號 嘜頭序號, /*棧板單號與嘜頭序號一對一*/
	A.公司代碼,
	nvl(E.全名, ' ') 公司名稱,
	A.單據日期,
	A.簽核系統, 
	A.備註, 
	A.業務員 品檢員,
	nvl(D.員工姓名,' ') 品檢員姓名, 	
	A.流水編號,
	A.填表人,
	nvl(Z1.員工姓名,' ') 填表人姓名, 
	A.填表日, 
	A.最後更新者,
	nvl(Z2.員工姓名,' ') 更新者姓名, 
	B.製程代碼,
	B.工站代碼,
	B.機台代碼,
	nvl(H.名稱, ' ') 機台名稱,
	nvl(I.名稱, ' ') 工站名稱,
	nvl(I.製程名稱, ' ') 製程名稱,
	A.最後更新日,
	nvl(Z3.簽核狀態, '0') 簽核狀態,
	DECODE(nvl(dbms_lob.getlength(G.圖檔),0),0,0,1) 品檢簽收
FROM
	FIL0030 A
	INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
	LEFT JOIN FIL0010 D ON A.業務員 = D.員工編號
	LEFT JOIN ViewFIL0011 E ON A.公司代碼 = E.代碼
	LEFT JOIN FIL0010 Z1 ON A.填表人 = Z1.員工編號
	LEFT JOIN FIL0010 Z2 ON A.最後更新者 = Z2.員工編號
	LEFT JOIN FIL0037 G ON A.單據類別 = G.製令單別 AND A.單據編號 = G.製令單號 AND G.材料序號=0
	LEFT JOIN ViewFIL310P H ON B.機台代碼=H.代碼
	LEFT JOIN ViewFIL310O I ON B.工站代碼=I.代碼
	LEFT JOIN ViewOfObjProperties Z3 ON A.流水編號 = Z3.單據流水號
WHERE
	A.單據類別 = 'E37');

-- Oracle user_views
CREATE VIEW "VIEWFILE039A" ("單別", "單號", "客戶編號") AS (
SELECT 
	A.單據類別 單別, 
	A.單據編號 單號,
	LISTAGG(A.廠客編號,',') WITHIN GROUP(ORDER BY A.廠客編號) AS 客戶編號
FROM
 (
	SELECT DISTINCT 
		A.單據類別, 
		A.單據編號,
		B.廠客編號
	FROM 
		FIL0040 A
		LEFT JOIN FIL0030 B ON B.單據類別='C11' AND A.廠客品號 = B.單據編號
	WHERE
		A.單據類別 = 'E37'
) A
GROUP BY
	A.單據類別, 
	A.單據編號	
);

-- Oracle user_views
CREATE VIEW "VIEWFILE03A" ("單別", "單號", "序號", "料號", "品名", "規格", "英文品名", "異動日期", "預交日", "庫別代碼", "庫別名稱", "原庫存數", "箱號", "包裝數量", "差異數量", "重量", "庫存單位代碼", "庫存單位名稱", "包裝單位代碼", "包裝單位名稱", "箱數", "批號", "製令單號", "客戶編號", "QRNO", "標籤類別", "備註", "流水編號", "最後更新者", "更新者姓名", "最後更新日") AS (
SELECT 
	A.單據類別 單別, 
	A.單據編號 單號,
	A.單據序號 序號,
	A.產品編號 料號,
	nvl(E.英文品名, ' ') 品名,
	nvl(E.規格, ' ') 規格,
	nvl(E.英文品名, ' ') 英文品名,
	B.單據日期 異動日期,
	A.預交日,
	A.倉庫代碼 庫別代碼,
	nvl(G.名稱, ' ') 庫別名稱,
	nvl(C.數值1,0) 原庫存數,
	A.異動數量 箱號,
	A.贈品數量 包裝數量,
	C.數值5*-1 差異數量,
	A.毛重 重量,
	nvl(E.單位代碼, ' ') 庫存單位代碼,
	nvl(F1.名稱, ' ') 庫存單位名稱,
	nvl(E.銷售單位, ' ') 包裝單位代碼,
	nvl(F2.名稱, ' ') 包裝單位名稱,
	A.數值1 箱數,
	C.批號,
	A.廠客品號 製令單號,
	Z2.廠客編號 客戶編號,
	/* C.數值1 棧板序號, 依櫃號+製令編製*/
	A.QRNo,
	C.標籤類別,
	A.備註說明 備註,
	A.流水編號,
	A.最後更新者,
	NVL(Z1.員工姓名,' ') 更新者姓名,
	A.最後更新日
FROM 
	FIL0040 A
	/*特殊欄位*/
	INNER JOIN FIL0041 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號 AND A.單據序號 = C.序號
	INNER JOIN FIL0030 B ON A.單據類別 = B.單據類別 AND A.單據編號 = B.單據編號
	LEFT JOIN FIL0012 E ON A.產品編號 = E.產品編號
	LEFT JOIN ViewFIL3103 F1 ON E.單位代碼 = F1.代碼
	LEFT JOIN ViewFIL3103 F2 ON E.銷售單位 = F2.代碼
	LEFT JOIN ViewFIL3106 G ON A.倉庫代碼 = G.代碼
	LEFT JOIN FIL0010 Z1 ON A.最後更新者 = Z1.員工編號
	LEFT JOIN FIL0030 Z2 ON Z2.單據類別='C11' AND A.廠客品號 = Z2.單據編號
WHERE
	A.單據類別 = 'E37');

-- Oracle user_views
CREATE VIEW "VIEWFILE03B" ("單別", "單號", "箱數", "包裝數量", "淨重", "毛重") AS (
SELECT 
	A.單據類別 單別, 
	A.單據編號 單號,
	count(A.異動數量) 箱數,
	sum(A.贈品數量) 包裝數量,
	sum(A.毛重) 淨重,
	sum(A.毛重)+15 毛重
FROM 
	FIL0040 A
WHERE
	A.單據類別 = 'E37'
GROUP BY
	A.單據類別, 
	A.單據編號);

-- Oracle user_views
CREATE VIEW "VIEWFILE03C" ("製令單號", "箱號", "來源單別", "平均袋重") AS (
SELECT	
	A.廠客品號 製令單號,
	A.異動數量 箱號,
	A.單據類別 來源單別,
	DECODE(sum(A.贈品數量),0,0,sum(A.毛重)/sum(A.贈品數量)) 平均袋重
FROM 
	FIL0040 A
WHERE
	A.單據類別 between  'E32' AND 'E33'
Group by 
	A.廠客品號,
	A.異動數量,
	A.單據類別
);

-- Oracle user_views
CREATE VIEW "VIEWFILE03D" ("製令單別", "製令單號", "箱號", "每袋重量") AS (
SELECT	
	Decode(nvl(A.平均袋重,0),0,to_char('C11'),A.製令單別) 製令單別,
	Decode(nvl(A.平均袋重,0),0,D.製令單號,A.製令單號) 製令單號,
	Decode(nvl(A.平均袋重,0),0,D.箱號,A.箱號) 箱號,
	Decode(nvl(A.平均袋重,0),0,nvl(D.平均袋重,0),A.平均袋重+nvl(B.每袋重量,0)+nvl(C.每袋重量,0)) 每袋重量
FROM 
	ViewFIL404E7 A
	Left Join ViewFIL404F3 B ON A.製令單別=B.製令單別 AND A.製令單號=B.製令單號 AND A.箱號=B.箱號
	Left Join ViewFIL404G3 C ON A.製令單別=C.製令單別 AND A.製令單號=C.製令單號 AND A.箱號=C.箱號
	Full Outer Join ViewFILE03C D ON A.製令單號=D.製令單號 AND A.箱號=D.箱號 AND nvl(D.平均袋重,0)<>0
);

-- Oracle user_views
CREATE VIEW "VIEWFILE03E" ("批號", "結存數量", "製袋重量", "生產日期", "氣閥重量", "鐵條重量", "紙箱重量", "箱號異動", "重工", "品檢", "製袋平均重量", "氣閥平均重量", "鐵條平均重量") AS (
SELECT  
	A.批號,
	ROUND(NVL(case when B.結存數量<0 then 0 else B.結存數量 end,0)) 結存數量,
	ROUND(NVL(C.製袋平均重量*NVL(case when B.結存數量<0 then 0 else B.結存數量 end,0),0),2) 製袋重量,
	NVL(C.生產日期,' ') 生產日期,
	ROUND(NVL(D.氣閥平均重量*NVL(case when B.結存數量<0 then 0 else B.結存數量 end,0),0),2) 氣閥重量,
	ROUND(NVL(E.鐵條平均重量*NVL(case when B.結存數量<0 then 0 else B.結存數量 end,0),0),2) 鐵條重量,
	ROUND(NVL(F.紙箱重量,0),2) 紙箱重量,
	DECODE(NVL(G.筆數,0),0,0,1) 箱號異動,
	DECODE(NVL(H.筆數,0),0,0,1) 重工,
	DECODE(NVL(I.筆數,0),0,0,1) 品檢,
	nvl(C.製袋平均重量,0) 製袋平均重量,
	nvl(D.氣閥平均重量,0) 氣閥平均重量,
	nvl(E.鐵條平均重量,0) 鐵條平均重量
FROM 
	ViewFIL404E4_T8 A
	LEFT JOIN
	(
	SELECT DISTINCT 
		A.批號,
		FIRST_VALUE(A.數量) OVER (PARTITION BY A.批號 ORDER BY A.最後更新日時 DESC) AS 結存數量
	FROM 
		FIL004L A
	) B ON B.批號=A.批號
	LEFT JOIN 
	(
	SELECT DISTINCT 
		A.批號,
		FIRST_VALUE(A.異動日期) OVER (PARTITION BY A.批號 ORDER BY A.最後更新日時 ASC) 生產日期,
		FIRST_VALUE(A.製袋重量/A.數量) OVER (PARTITION BY A.批號 ORDER BY A.最後更新日時 DESC) AS 製袋平均重量
	FROM 
		FIL004L A
	WHERE
		A.製袋重量>0 AND A.數量>0
	) C ON C.批號=A.批號
	LEFT JOIN 
	(
	SELECT DISTINCT 
		A.批號,
		FIRST_VALUE(A.氣閥重量/A.數量) OVER (PARTITION BY A.批號 ORDER BY A.最後更新日時 DESC) AS 氣閥平均重量
	FROM 
		FIL004L A
	WHERE
		A.氣閥重量>0 AND A.數量>0
	) D ON D.批號=A.批號
	LEFT JOIN 
	(
	SELECT DISTINCT 
		A.批號,
		FIRST_VALUE(A.鐵條重量/A.數量) OVER (PARTITION BY A.批號 ORDER BY A.最後更新日時 DESC) AS 鐵條平均重量
	FROM 
		FIL004L A
	WHERE
		A.鐵條重量>0 AND A.數量>0
	) E ON E.批號=A.批號
	LEFT JOIN 
	(
	SELECT DISTINCT 
		A.批號,
		FIRST_VALUE(A.紙箱重量) OVER (PARTITION BY A.批號 ORDER BY A.最後更新日時 DESC) AS 紙箱重量
	FROM 
		FIL004L A
	WHERE
		A.紙箱重量>0 AND A.數量>0
	) F ON F.批號=A.批號
	LEFT JOIN 
	(
	SELECT DISTINCT 
		A.批號,
		COUNT(A.批號) 筆數
	FROM 
		FIL004L A
	WHERE
		A.來源='異動'
	GROUP BY 
		A.批號
	) G ON G.批號=A.批號
	LEFT JOIN 
	(
	SELECT DISTINCT 
		A.批號,
		COUNT(A.批號) 筆數
	FROM 
		FIL004L A
	WHERE
		A.來源='重工'
	GROUP BY 
		A.批號
	) H ON H.批號=A.批號
	LEFT JOIN 
	(
	SELECT DISTINCT 
		A.批號,
		COUNT(A.批號) 筆數
	FROM 
		FIL004L A
	WHERE
		A.來源='品檢'
	GROUP BY 
		A.批號
	) I ON I.批號=A.批號
);

-- Oracle user_views
CREATE VIEW "VIEWFILE03F" ("製令單號", "結存數量", "結存重量", "平均製袋重量", "平均氣閥重量", "平均鐵條重量") AS (
SELECT  REGEXP_SUBSTR(A.批號, '[^-]+', 1, 1) 製令單號,
	SUM(A.結存數量) 結存數量,
	SUM(DECODE(A.結存數量,0,0,A.製袋重量+A.氣閥重量+A.鐵條重量+紙箱重量)) 結存重量,
	DECODE(SUM(A.結存數量),0,0,SUM(A.製袋重量)/SUM(A.結存數量)) 平均製袋重量,
	DECODE(SUM(A.結存數量),0,0,SUM(A.氣閥重量)/SUM(A.結存數量)) 平均氣閥重量,
	DECODE(SUM(A.結存數量),0,0,SUM(A.鐵條重量)/SUM(A.結存數量)) 平均鐵條重量
FROM
	ViewFILE03E A
GROUP BY 
	REGEXP_SUBSTR(A.批號, '[^-]+', 1, 1)
);

-- Oracle user_views
CREATE VIEW "VIEWFILE040" ("單別", "單號", "公司代碼", "公司名稱", "單據日期", "簽核系統", "客戶編號", "貨櫃號碼", "客戶名稱", "ATTN", "TEL", "FAX", "ADDRESS", "價格條件", "目的地", "封條號碼", "車架號碼", "SO", "貨櫃尺寸", "運送方式", "VESSELNO", "ONBOARDDATE", "ETA", "運送方式名稱", "幣別代碼", "備註", "作業員", "作業員姓名", "流水編號", "填表人", "填表人姓名", "填表日", "最後更新者", "更新者姓名", "最後更新日", "簽核狀態", "裝櫃簽收") AS (
SELECT
	A.單據類別 單別,
	A.單據編號 單號,
	A.公司代碼,
	nvl(D.全名, ' ') 公司名稱,
	A.單據日期,
	A.簽核系統, 
	A.廠客編號 客戶編號,
	A.廠客單號 貨櫃號碼,
	nvl(C.全名, ' ')  客戶名稱,
	B.文數字7 Attn,
	B.文數字8 Tel,
	B.文數字9 Fax,
	B.文字1 Address,
	B.文字2 價格條件,
	B.文字3 目的地,
	B.文數字1 封條號碼,
	B.文數字2 車架號碼,
	B.文數字3 SO,
	B.文數字4 貨櫃尺寸,
	B.文數字5 運送方式,
	B.文數字6 VESSELNO,
	B.交貨日期 ONBOARDDATE,
	A.匯率日期 ETA,
	nvl(E.名稱, ' ') 運送方式名稱,
	A.幣別代碼,
	A.備註, 
	A.業務員 作業員,
	nvl(Z3.員工姓名,' ') 作業員姓名, 	
	A.流水編號,
	A.填表人,
	nvl(Z1.員工姓名,' ') 填表人姓名, 
	A.填表日, 
	A.最後更新者,
	nvl(Z2.員工姓名,' ') 更新者姓名, 
	A.最後更新日,
	nvl(Z4.簽核狀態, '0') 簽核狀態,
	DECODE(nvl(dbms_lob.getlength(Z5.圖檔),0),0,0,1) 裝櫃簽收
FROM
	FIL0030 A
	INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
	LEFT JOIN FIL0011 C ON A.廠客編號 = C.編號
	LEFT JOIN ViewFIL0011 D ON A.公司代碼 = D.代碼
	LEFT JOIN ViewFIL3111 E ON B.文數字5 = E.代碼
	LEFT JOIN FIL0010 Z1 ON A.填表人 = Z1.員工編號
	LEFT JOIN FIL0010 Z2 ON A.最後更新者 = Z2.員工編號
	LEFT JOIN FIL0010 Z3 ON A.業務員 = Z3.員工編號
	LEFT JOIN ViewOfObjProperties Z4 ON A.流水編號 = Z4.單據流水號
	LEFT JOIN FIL0037 Z5 ON A.單據類別 = Z5.製令單別 AND A.單據編號 = Z5.製令單號 AND Z5.材料序號=0
WHERE
	A.單據類別 = 'E38');

-- Oracle user_views
CREATE VIEW "VIEWFILE041" ("裝櫃單別", "貨櫃號碼", "嘜頭序號", "品檢單別", "品檢單號", "品檢序號", "料號", "品名", "規格", "異動日期", "庫別代碼", "庫別名稱", "箱號", "包裝數量", "重量", "庫存單位代碼", "庫存單位名稱", "包裝單位代碼", "包裝單位名稱", "箱數", "批號", "製令單號", "備註", "流水編號", "最後更新者", "更新者姓名", "最後更新日") AS (
SELECT 
	B.歸屬類別 裝櫃單別,
	B.歸屬編號 貨櫃號碼,
	B.歸屬序號 嘜頭序號,
	A.單據類別 品檢單別, 
	A.單據編號 品檢單號,
	A.單據序號 品檢序號,
	A.產品編號 料號,
	nvl(E.英文品名, ' ') 品名,
	nvl(E.規格, ' ') 規格,
	A.異動日期,
	A.倉庫代碼 庫別代碼,
	nvl(G.名稱, ' ') 庫別名稱,
	A.異動數量 箱號,
	A.贈品數量 包裝數量,
	A.毛重 重量,
	nvl(E.單位代碼, ' ') 庫存單位代碼,
	nvl(F1.名稱, ' ') 庫存單位名稱,
	nvl(E.銷售單位, ' ') 包裝單位代碼,
	nvl(F2.名稱, ' ') 包裝單位名稱,
	A.數值1 箱數,
	C.批號,
	A.廠客品號 製令單號,
	/* C.數值1 棧板序號, 依櫃號+製令編製*/
	A.備註說明 備註,
	A.流水編號,
	A.最後更新者,
	NVL(Z1.員工姓名,' ') 更新者姓名,
	A.最後更新日
FROM 
	FIL0040 A
	/*貨櫃號碼*/
	INNER JOIN FIL0030 B ON A.單據類別 = B.單據類別 AND A.單據編號 = B.單據編號 AND B.歸屬類別 = 'E38'
	/*特殊欄位*/
	INNER JOIN FIL0041 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號 AND A.單據序號 = C.序號
	LEFT JOIN FIL0012 E ON A.產品編號 = E.產品編號
	LEFT JOIN ViewFIL3103 F1 ON E.單位代碼 = F1.代碼
	LEFT JOIN ViewFIL3103 F2 ON E.銷售單位 = F2.代碼
	LEFT JOIN ViewFIL3106 G ON A.倉庫代碼 = G.代碼
	LEFT JOIN FIL0010 Z1 ON A.最後更新者 = Z1.員工編號
WHERE
	A.單據類別 = 'E37');

-- Oracle user_views
CREATE VIEW "VIEWFILE042" ("單別", "單號", "製令單號", "產品編號", "箱數", "數量", "製令序號") AS (
SELECT 
	A.單別, 
	A.單號,
	A.製令單號,
	A.產品編號,
	A.箱數,
	A.數量,
	row_number() over (partition by A.單別, A.單號 order by A.製令單號) 製令序號
FROM
	(	SELECT 
			B.歸屬類別 單別, 
			B.歸屬編號 單號,
			A.廠客品號 製令單號,
			A.產品編號,
			count(A.異動數量) 箱數,
			sum(A.贈品數量) 數量
		FROM 
			FIL0040 A
			/*貨櫃號碼*/
			INNER JOIN FIL0030 B ON A.單據類別 = B.單據類別 AND A.單據編號 = B.單據編號 AND B.歸屬類別 = 'E38'
		WHERE
			A.單據類別 = 'E37'
		GROUP BY
			B.歸屬類別, 
			B.歸屬編號,
			A.廠客品號,
			A.產品編號
	) A);

-- Oracle user_views
CREATE VIEW "VIEWFILE043" ("單別", "單號", "箱數", "數量", "淨重", "毛重") AS (
SELECT 
	B.歸屬類別 單別, 
	B.歸屬編號 單號,
	count(A.異動數量) 箱數,
	sum(A.贈品數量) 數量,
	sum(A.毛重) 淨重,
	sum(A.毛重 + 15) 毛重
FROM 
	FIL0040 A
	/*貨櫃號碼*/
	INNER JOIN FIL0030 B ON A.單據類別 = B.單據類別 AND A.單據編號 = B.單據編號 AND B.歸屬類別 = 'E38'
WHERE
	A.單據類別 = 'E37'
GROUP BY
	B.歸屬類別, 
	B.歸屬編號);

-- Oracle user_views
CREATE VIEW "VIEWFILE044" ("單別", "單號", "嘜頭序號", "製令單號", "產品編號", "箱數", "數量", "品名", "客戶成品尺寸", "客戶最終名稱") AS (
SELECT 
	A.單別, 
	A.單號,
	A.嘜頭序號,
	A.製令單號,
	A.產品編號,
	A.箱數,
	A.數量,
	nvl(B.英文品名, ' ') 品名,
	nvl(B.客戶成品尺寸, ' ') 客戶成品尺寸,
	nvl(B.客戶最終名稱, ' ') 客戶最終名稱
FROM
	(	SELECT 
			B.歸屬類別 單別, 
			B.歸屬編號 單號,
			B.歸屬序號 嘜頭序號,
			A.廠客品號 製令單號,
			A.產品編號,
			count(A.異動數量) 箱數,
			sum(A.贈品數量) 數量
		FROM 
			FIL0040 A
			/*貨櫃號碼*/
			INNER JOIN FIL0030 B ON A.單據類別 = B.單據類別 AND A.單據編號 = B.單據編號 AND B.歸屬類別 = 'E38'
		WHERE
			A.單據類別 = 'E37'
		GROUP BY
			B.歸屬類別, 
			B.歸屬編號,
			B.歸屬序號,
			A.廠客品號,
			A.產品編號
	) A
	LEFT JOIN FIL0012 B ON A.產品編號 = B.產品編號);

-- Oracle user_views
CREATE VIEW "VIEWFILE045" ("單別", "單號", "序號", "製令序號", "DESCRIPTION", "製令單號", "數量", "單位", "單價", "金額", "客戶最終名稱", "備註", "板費", "流水編號", "最後更新者", "更新者姓名", "最後更新日") AS (
SELECT 
	A.單據類別 單別, 
	A.單據編號 單號,
	A.單據序號 序號,
	nvl(C.製令序號, 0) 製令序號,
	B.文字1 DESCRIPTION,
	A.產品編號 製令單號,
	A.異動數量 數量,
	A.單位代碼 單位,
	A.異動單價 單價,
	A.異動金額 金額,
	nvl(B.文字2, ' ') 客戶最終名稱,
	A.備註說明 備註,
	B.Logical1 板費,
	A.流水編號,
	A.最後更新者,
	NVL(Z1.員工姓名,' ') 更新者姓名,
	A.最後更新日
FROM 
	FIL0040 A
	/*特殊欄位*/
	INNER JOIN FIL0041 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號 AND A.單據序號 = B.序號
	LEFT JOIN ViewFILE042 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號 AND A.產品編號 = C.製令單號
	LEFT JOIN FIL0012 D ON A.產品編號 = D.產品編號
	LEFT JOIN FIL0010 Z1 ON A.最後更新者 = Z1.員工編號
WHERE
	A.單據類別 = 'E38' AND
	A.異動類別 = 'B');

-- Oracle user_views
CREATE VIEW "VIEWFILE046" ("單別", "單號", "數量", "金額") AS (
SELECT 
	A.單據類別 單別, 
	A.單據編號 單號,
	sum(A.異動數量) 數量,
	sum(A.異動金額) 金額
FROM 
	FIL0040 A
WHERE
	A.單據類別 = 'E38' AND
	A.異動類別 = 'B'
GROUP BY
	A.單據類別, 
	A.單據編號);

-- Oracle user_views
CREATE VIEW "VIEWFILF010" ("單別", "單號", "公司代碼", "公司名稱", "單據日期", "簽核系統", "備註", "倉管員", "倉管員姓名", "流水編號", "填表人", "填表人姓名", "填表日", "最後更新者", "更新者姓名", "製程代碼", "工站代碼", "機台代碼", "機台名稱", "工站名稱", "製程名稱", "最後更新日", "簽核狀態", "廠商簽收") AS (
SELECT
	A.單據類別 單別,
	A.單據編號 單號,
	A.公司代碼,
	nvl(E.全名, ' ') 公司名稱,
	A.單據日期,
	A.簽核系統, 
	A.備註, 
	A.業務員 倉管員,
	nvl(D.員工姓名,' ') 倉管員姓名, 	
	A.流水編號,
	A.填表人,
	nvl(Z1.員工姓名,' ') 填表人姓名, 
	A.填表日, 
	A.最後更新者,
	nvl(Z2.員工姓名,' ') 更新者姓名, 
	B.製程代碼,
	B.工站代碼,
	B.機台代碼,
	nvl(H.名稱, ' ') 機台名稱,
	nvl(I.名稱, ' ') 工站名稱,
	nvl(I.製程名稱, ' ') 製程名稱,
	A.最後更新日,
	nvl(Z3.簽核狀態, '0') 簽核狀態,
	DECODE(nvl(dbms_lob.getlength(G.圖檔),0),0,0,1) 廠商簽收
FROM
	FIL0030 A
	INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
	LEFT JOIN FIL0010 D ON A.業務員 = D.員工編號
	LEFT JOIN ViewFIL0011 E ON A.公司代碼 = E.代碼
	LEFT JOIN FIL0037 G ON A.單據類別 = G.製令單別 AND A.單據編號 = G.製令單號 AND G.材料序號=0
	LEFT JOIN ViewFIL310P H ON B.機台代碼=H.代碼
	LEFT JOIN ViewFIL310O I ON B.工站代碼=I.代碼
	LEFT JOIN FIL0010 Z1 ON A.填表人 = Z1.員工編號
	LEFT JOIN FIL0010 Z2 ON A.最後更新者 = Z2.員工編號
	LEFT JOIN ViewOfObjProperties Z3 ON A.流水編號 = Z3.單據流水號
WHERE
	A.單據類別 = 'F11');

-- Oracle user_views
CREATE VIEW "VIEWFILF011" ("單別", "單號", "序號", "料號", "品名", "規格", "異動日期", "製造日期", "箱號", "包裝數量", "重量", "箱數", "批號", "製令單號", "備註說明", "流水編號", "最後更新者", "更新者姓名", "最後更新日") AS (
SELECT 
	A.單據類別 單別, 
	A.單據編號 單號,
	A.單據序號 序號,
	NVL(H.產品編號,A.產品編號) 料號,
	nvl(H.產品名稱, nvl(E.品名,' ')) 品名,
	nvl(E.規格, ' ') 規格,
	A.異動日期,
	nvl(F.製造日期, ' ') 製造日期,
	A.異動數量 箱號,
	A.贈品數量 包裝數量,
	A.毛重 重量,
	A.數值1 箱數,
	C.批號,
	A.廠客品號 製令單號,
	A.備註說明,
	A.流水編號,
	A.最後更新者,
	NVL(Z1.員工姓名,' ') 更新者姓名,
	A.最後更新日
FROM 
	FIL0040 A
	/*特殊欄位*/
	INNER JOIN FIL0041 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號 AND A.單據序號 = C.序號
	LEFT JOIN FIL0032 H ON H.製令單別 = 'C11' AND H.製令單號 = A.廠客品號
	/*製造日期*/
	LEFT JOIN ViewFIL4036 F ON A.廠客品號 = F.製令單號
	LEFT JOIN FIL0012 E ON A.產品編號 = E.產品編號
	LEFT JOIN FIL0010 Z1 ON A.最後更新者 = Z1.員工編號
WHERE
	A.單據類別 = 'F11');

-- Oracle user_views
CREATE VIEW "VIEWFILF012" ("單別", "單號", "箱數", "包裝數量") AS (
SELECT 
	A.單據類別 單別, 
	A.單據編號 單號,
	sum(A.數值1) 箱數,
	sum(A.贈品數量) 包裝數量
FROM 
	FIL0040 A
WHERE
	A.單據類別 = 'F11'
GROUP BY
	A.單據類別, 
	A.單據編號);

-- Oracle user_views
CREATE VIEW "VIEWFILF013" ("工站代碼", "批號", "填表日") AS (
SELECT 
	D.工站代碼,	
	A.批號,
	min(C.填表日) 填表日
FROM 
	FIL0041 A
	INNER JOIN FIL0030 C ON A.單別 = C.單據類別 AND A.單號 = C.單據編號
	INNER JOIN FIL0031 D ON A.單別 = D.單別 AND A.單號 = D.單號
WHERE
	A.單別 = 'F11'
GROUP BY 
	D.工站代碼,	
	A.批號);

-- Oracle user_views
CREATE VIEW "VIEWFILF014" ("製程代碼", "工站代碼", "製令單號", "生產數量", "合理剔除數", "報廢數量") AS (
SELECT 
	B.製程代碼,
	B.工站代碼,
	C.歸屬編號 製令單號,
	SUM(A.贈品數量) 生產數量,
	SUM(A.燙金費) 合理剔除數,
	SUM(D.數值5) 報廢數量
FROM 
	FIL0040 A
	INNER JOIN FIL0041 D ON D.單別 = A.單據類別 AND D.單號 = A.單據編號 AND D.序號 = A.單據序號
	INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
	INNER JOIN FIL0030 C ON A.單據類別 = C.單據類別 AND A.單據編號 = C.單據編號
	INNER JOIN ViewFILF015 E ON  B.工站代碼 = E.工站代碼 AND C.歸屬編號 = E.製令單號 AND C.填表日 >= E.填表日
WHERE
	A.單據類別 = 'C41' AND
	A.異動類別 = 'A' AND
	B.製程代碼 BETWEEN 'C31F' AND 'C31G'
GROUP BY
	B.製程代碼,
	B.工站代碼,
	C.歸屬編號
);

-- Oracle user_views
CREATE VIEW "VIEWFILF015" ("工站代碼", "製令單號", "填表日") AS (
SELECT 
	D.工站代碼,	
	E.廠客品號 製令單號,
	min(C.填表日) 填表日
FROM 
	FIL0040 E 
	INNER JOIN FIL0030 C ON E.單據類別 = C.單據類別 AND E.單據編號 = C.單據編號
	INNER JOIN FIL0031 D ON E.單據類別 = D.單別 AND E.單據編號 = D.單號
WHERE
	E.單據類別 = 'F11'
GROUP BY 
	D.工站代碼,	
	E.廠客品號);

-- Oracle user_views
CREATE VIEW "VIEWFILF016" ("單據類別", "單據編號", "單據序號", "製程代碼", "工站代碼", "製令單號", "生產數量", "報廢數量") AS (
SELECT 
	A.單據類別,
	A.單據編號,
	A.單據序號,
	B.製程代碼,
	B.工站代碼,
	C.歸屬編號 製令單號,
	A.贈品數量 生產數量,
	D.數值5 報廢數量
FROM 
	FIL0040 A
	INNER JOIN FIL0041 D ON D.單別 = A.單據類別 AND D.單號 = A.單據編號 AND D.序號 = A.單據序號
	INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
	INNER JOIN FIL0030 C ON A.單據類別 = C.單據類別 AND A.單據編號 = C.單據編號
	INNER JOIN ViewFILF015 E ON  B.工站代碼 = E.工站代碼 AND C.歸屬編號 = E.製令單號 AND C.填表日 >= E.填表日
WHERE
	A.單據類別 = 'C41' AND
	A.異動類別 = 'A' AND
	B.製程代碼 BETWEEN 'C31F' AND 'C31G'
);

-- Oracle user_views
CREATE VIEW "VIEWFILF020" ("單別", "單號", "公司代碼", "公司名稱", "單據日期", "簽核系統", "備註", "倉管員", "倉管員姓名", "流水編號", "填表人", "填表人姓名", "填表日", "最後更新者", "更新者姓名", "製程代碼", "工站代碼", "機台代碼", "機台名稱", "工站名稱", "製程名稱", "最後更新日", "簽核狀態", "廠商簽收") AS (
SELECT
	A.單據類別 單別,
	A.單據編號 單號,
	A.公司代碼,
	nvl(E.全名, ' ') 公司名稱,
	A.單據日期,
	A.簽核系統, 
	A.備註, 
	A.業務員 倉管員,
	nvl(D.員工姓名,' ') 倉管員姓名, 	
	A.流水編號,
	A.填表人,
	nvl(Z1.員工姓名,' ') 填表人姓名, 
	A.填表日, 
	A.最後更新者,
	nvl(Z2.員工姓名,' ') 更新者姓名, 
	B.製程代碼,
	B.工站代碼,
	B.機台代碼,
	nvl(H.名稱, ' ') 機台名稱,
	nvl(I.名稱, ' ') 工站名稱,
	nvl(I.製程名稱, ' ') 製程名稱,
	A.最後更新日,
	nvl(Z3.簽核狀態, '0') 簽核狀態,
	DECODE(nvl(dbms_lob.getlength(G.圖檔),0),0,0,1) 廠商簽收
FROM
	FIL0030 A
	INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
	LEFT JOIN FIL0010 D ON A.業務員 = D.員工編號
	LEFT JOIN ViewFIL0011 E ON A.公司代碼 = E.代碼	
	LEFT JOIN FIL0037 G ON A.單據類別 = G.製令單別 AND A.單據編號 = G.製令單號 AND G.材料序號=0
	LEFT JOIN ViewFIL310P H ON B.機台代碼=H.代碼
	LEFT JOIN ViewFIL310O I ON B.工站代碼=I.代碼
	LEFT JOIN FIL0010 Z1 ON A.填表人 = Z1.員工編號
	LEFT JOIN FIL0010 Z2 ON A.最後更新者 = Z2.員工編號
	LEFT JOIN ViewOfObjProperties Z3 ON A.流水編號 = Z3.單據流水號
WHERE
	A.單據類別 = 'F21');

-- Oracle user_views
CREATE VIEW "VIEWFILF021" ("單別", "單號", "序號", "料號", "品名", "規格", "異動日期", "製造日期", "箱號", "包裝數量", "重量", "箱數", "退回", "批號", "製令單號", "備註說明", "流水編號", "最後更新者", "更新者姓名", "最後更新日") AS (
SELECT 
	A.單據類別 單別, 
	A.單據編號 單號,
	A.單據序號 序號,
	NVL(H.產品編號,A.產品編號) 料號,
	nvl(H.產品名稱, nvl(E.品名,' ')) 品名,
	nvl(E.規格, ' ') 規格,
	A.異動日期,
	nvl(F.製造日期, ' ') 製造日期,
	A.異動數量 箱號,
	A.贈品數量 包裝數量,
	A.毛重 重量,
	A.數值1 箱數,
	A.Logical1 退回,
	C.批號,
	A.廠客品號 製令單號,
	A.備註說明,
	A.流水編號,
	A.最後更新者,
	NVL(Z1.員工姓名,' ') 更新者姓名,
	A.最後更新日
FROM 
	FIL0040 A
	/*特殊欄位*/
	INNER JOIN FIL0041 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號 AND A.單據序號 = C.序號
	LEFT JOIN FIL0032 H ON H.製令單別 = 'C11' AND H.製令單號 = A.廠客品號
	/*製造日期*/
	LEFT JOIN ViewFIL4036 F ON A.廠客品號 = F.製令單號
	LEFT JOIN FIL0012 E ON A.產品編號 = E.產品編號
	LEFT JOIN FIL0010 Z1 ON A.最後更新者 = Z1.員工編號
WHERE
	A.單據類別 = 'F21');

-- Oracle user_views
CREATE VIEW "VIEWFILF022" ("單別", "單號", "箱數", "包裝數量") AS (
SELECT 
	A.單據類別 單別, 
	A.單據編號 單號,
	sum(A.數值1) 箱數,
	sum(A.贈品數量) 包裝數量
FROM 
	FIL0040 A
WHERE
	A.單據類別 = 'F21'
GROUP BY
	A.單據類別, 
	A.單據編號);

-- Oracle user_views
CREATE VIEW "VIEWFILF030" ("單別", "單號", "類別代碼", "類別說明", "公司代碼", "公司名稱", "單據日期", "簽核系統", "備註", "倉管員", "倉管員姓名", "流水編號", "填表人", "填表人姓名", "填表日", "最後更新者", "更新者姓名", "製程代碼", "製程名稱", "工站代碼", "工站名稱", "製程工站", "機台代碼", "機台名稱", "已轉調整", "最後更新日", "簽核狀態", "廠商簽收") AS (
SELECT
	A.單據類別 單別,
	A.單據編號 單號,
	A.稅別 類別代碼,
	decode(A.稅別, 'A', '委外', '廠內') 類別說明,
	A.公司代碼,
	nvl(E.全名, ' ') 公司名稱,
	A.單據日期,
	A.簽核系統, 
	A.備註, 
	A.業務員 倉管員,
	nvl(D.員工姓名,' ') 倉管員姓名, 	
	A.流水編號,
	A.填表人,
	nvl(Z1.員工姓名,' ') 填表人姓名, 
	A.填表日, 
	A.最後更新者,
	nvl(Z2.員工姓名,' ') 更新者姓名, 
	B.製程代碼,
	decode(A.稅別, 'A', nvl(I.製程名稱, ' '), decode(B.製程代碼, 'M', '原料', 'N', '物料', 'O', '其他', 'S', '半成品', 'P', '版銅', '錯誤')) 製程名稱,
	B.工站代碼,
	decode(A.稅別, 'A', nvl(I.名稱, ' '), nvl(J.名稱, ' ')) 工站名稱,
	decode(A.稅別, 'A', nvl(I.製程工站, ' '),  nvl(J.名稱, ' ') || '(' || decode(B.製程代碼, 'M', '原料', 'N', '物料', 'O', '其他', 'S', '半成品', 'P', '版銅', '錯誤') || ')') 製程工站,
	B.機台代碼,
	nvl(H.名稱, ' ') 機台名稱,
	B.Logical1 已轉調整,
	A.最後更新日,
	nvl(Z3.簽核狀態, '0') 簽核狀態,
	DECODE(nvl(dbms_lob.getlength(G.圖檔),0),0,0,1) 廠商簽收
FROM
	FIL0030 A
	INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
	LEFT JOIN FIL0010 D ON A.業務員 = D.員工編號
	LEFT JOIN ViewFIL0011 E ON A.公司代碼 = E.代碼
	LEFT JOIN FIL0037 G ON A.單據類別 = G.製令單別 AND A.單據編號 = G.製令單號 AND G.材料序號=0
	/*委外盤點.工站*/
	LEFT JOIN ViewFIL310P H ON B.機台代碼=H.代碼
	LEFT JOIN ViewFIL310O I ON B.工站代碼=I.代碼
	/*廠內盤點.物料大類*/
	LEFT JOIN ViewFIL310B J ON B.工站代碼 = J.代碼
	LEFT JOIN FIL0010 Z1 ON A.填表人 = Z1.員工編號
	LEFT JOIN FIL0010 Z2 ON A.最後更新者 = Z2.員工編號
	LEFT JOIN ViewOfObjProperties Z3 ON A.流水編號 = Z3.單據流水號
WHERE
	A.單據類別 = 'F31');

-- Oracle user_views
CREATE VIEW "VIEWFILF031" ("單別", "單號", "序號", "料號", "品名", "規格", "異動類別", "異動說明", "異動日期", "製造日期", "箱號", "數量", "重量", "箱數", "批號", "製令單號", "庫存數", "差異數", "委外庫存數", "已盤", "備註說明", "流水編號", "最後更新者", "更新者姓名", "廠商批號", "最後更新日") AS (
SELECT 
	A.單據類別 單別, 
	A.單據編號 單號,
	A.單據序號 序號,
	A.產品編號 料號,
	nvl(E.品名, ' ') 品名,
	nvl(E.規格, ' ') 規格,
	A.異動類別,
	decode(A.異動類別, '1', '半成品', '材料') 異動說明,
	A.異動日期,
	nvl(F.製造日期, ' ') 製造日期,
	A.異動數量 箱號,
	nvl(A.贈品數量,0) 數量,
	A.毛重 重量,
	A.數值1 箱數,
	C.批號,
	A.廠客品號 製令單號,
	nvl(A.異動單價,0) 庫存數,
	nvl(A.贈品數量,0) - nvl(A.異動單價,0) 差異數,
	nvl(A.異動金額,0) 委外庫存數,
	A.Logical1 已盤,
	A.備註說明,
	A.流水編號,
	A.最後更新者,
	NVL(Z1.員工姓名,' ') 更新者姓名,
	NVL(Z2.廠商批號,' ') 廠商批號,
	A.最後更新日
FROM 
	FIL0040 A
	/*特殊欄位*/
	INNER JOIN FIL0041 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號 AND A.單據序號 = C.序號
	/*製造日期*/
	LEFT JOIN ViewFIL4036 F ON A.廠客品號 = F.製令單號
	LEFT JOIN FIL0012 E ON A.產品編號 = E.產品編號
	LEFT JOIN FIL0010 Z1 ON A.最後更新者 = Z1.員工編號
	LEFT JOIN ViewFIL1024 Z2 ON Z2.單別 = 'E11' AND C.批號 = Z2.條碼
WHERE
	A.單據類別 = 'F31');

-- Oracle user_views
CREATE VIEW "VIEWFILF031A" ("單別", "單號", "序號", "料號", "批號", "異動日期", "盤點數") AS (
SELECT 
	A.單據類別 單別, 
	A.單據編號 單號,
	A.單據序號 序號,
	A.產品編號 料號,
	C.批號,
	A.異動日期,
	nvl(A.贈品數量,0) 盤點數
FROM 
	FIL0040 A
	INNER JOIN FIL0041 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號 AND A.單據序號 = C.序號
WHERE
	A.單據類別 = 'F31');

-- Oracle user_views
CREATE VIEW "VIEWFILF032" ("單別", "單號", "箱數", "數量", "庫存數", "差異數", "委外數") AS (
SELECT 
	A.單據類別 單別, 
	A.單據編號 單號,
	sum(A.數值1) 箱數,
	sum(A.贈品數量) 數量,
	sum(A.異動單價) 庫存數,
	sum(A.贈品數量 - A.異動單價) 差異數,
	sum(A.異動金額) 委外數
FROM 
	FIL0040 A
WHERE
	A.單據類別 = 'F31'
GROUP BY
	A.單據類別, 
	A.單據編號);

-- Oracle user_views
CREATE VIEW "VIEWFILF040" ("單別", "單號", "類別代碼", "類別說明", "公司代碼", "公司名稱", "單據日期", "簽核系統", "備註", "倉管員", "倉管員姓名", "流水編號", "填表人", "填表人姓名", "填表日", "最後更新者", "更新者姓名", "製程代碼", "製程名稱", "工站代碼", "工站名稱", "製程工站", "機台代碼", "機台名稱", "最後更新日", "簽核狀態") AS (
SELECT
	A.單據類別 單別,
	A.單據編號 單號,
	A.稅別 類別代碼,
	decode(A.稅別, 'A', '委外', '廠內') 類別說明,
	A.公司代碼,
	nvl(E.全名, ' ') 公司名稱,
	A.單據日期,
	A.簽核系統, 
	A.備註, 
	A.業務員 倉管員,
	nvl(D.員工姓名,' ') 倉管員姓名, 	
	A.流水編號,
	A.填表人,
	nvl(Z1.員工姓名,' ') 填表人姓名, 
	A.填表日, 
	A.最後更新者,
	nvl(Z2.員工姓名,' ') 更新者姓名, 
	B.製程代碼,
		decode(A.稅別, 'A', nvl(I.製程名稱, ' '), decode(B.製程代碼, 'M', '原料', 'N', '物料', 'O', '其他', 'S', '半成品', 'P', '版銅', '錯誤')) 製程名稱,
	B.工站代碼,
	decode(A.稅別, 'A', nvl(I.名稱, ' '), nvl(J.名稱, ' ')) 工站名稱,
	decode(A.稅別, 'A', nvl(I.製程工站, ' '),  nvl(J.名稱, ' ') || '(' || decode(B.製程代碼, 'M', '原料', 'N', '物料', 'O', '其他', 'S', '半成品', 'P', '版銅', '錯誤') || ')') 製程工站,
	B.機台代碼,
	nvl(H.名稱, ' ') 機台名稱,
	A.最後更新日,
	nvl(Z3.簽核狀態, '0') 簽核狀態
FROM
	FIL0030 A
	INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
	LEFT JOIN FIL0010 D ON A.業務員 = D.員工編號
	LEFT JOIN ViewFIL0011 E ON A.公司代碼 = E.代碼
	LEFT JOIN FIL0037 G ON A.單據類別 = G.製令單別 AND A.單據編號 = G.製令單號 AND G.材料序號=0
	/*委外盤點.工站*/
	LEFT JOIN ViewFIL310P H ON B.機台代碼=H.代碼
	LEFT JOIN ViewFIL310O I ON B.工站代碼=I.代碼
/*廠內盤點.物料大類*/
	LEFT JOIN ViewFIL310B J ON B.工站代碼 = J.代碼
	LEFT JOIN FIL0010 Z1 ON A.填表人 = Z1.員工編號
	LEFT JOIN FIL0010 Z2 ON A.最後更新者 = Z2.員工編號
	LEFT JOIN ViewOfObjProperties Z3 ON A.流水編號 = Z3.單據流水號
WHERE
	A.單據類別 = 'F32');

-- Oracle user_views
CREATE VIEW "VIEWFILF041" ("單別", "單號", "序號", "料號", "品名", "規格", "異動類別", "異動說明", "異動日期", "製造日期", "箱號", "調整數量", "重量", "箱數", "批號", "廠商批號", "製令單號", "庫存數", "差異數", "已盤", "備註說明", "流水編號", "最後更新者", "更新者姓名", "最後更新日") AS (
SELECT 
	A.單據類別 單別, 
	A.單據編號 單號,
	A.單據序號 序號,
	A.產品編號 料號,
	nvl(E.品名, ' ') 品名,
	nvl(E.規格, ' ') 規格,
	A.異動類別,
	decode(A.異動類別, '1', '半成品', '材料') 異動說明,
	A.異動日期,
	nvl(F.製造日期, ' ') 製造日期,
	A.異動數量 箱號,
	A.贈品數量 調整數量,
	A.毛重 重量,
	A.數值1 箱數,
	C.批號,
	NVL(Z2.廠商批號,' ') 廠商批號,
	A.廠客品號 製令單號,
	A.異動單價 庫存數,
	A.贈品數量 - A.異動單價 差異數,
	A.Logical1 已盤,
	A.備註說明,
	A.流水編號,
	A.最後更新者,
	NVL(Z1.員工姓名,' ') 更新者姓名,
	A.最後更新日
FROM 
	FIL0040 A
	/*特殊欄位*/
	INNER JOIN FIL0041 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號 AND A.單據序號 = C.序號
	/*製造日期*/
	LEFT JOIN ViewFIL4036 F ON A.廠客品號 = F.製令單號
	LEFT JOIN FIL0012 E ON A.產品編號 = E.產品編號
	LEFT JOIN FIL0010 Z1 ON A.最後更新者 = Z1.員工編號
	LEFT JOIN ViewFIL1024 Z2 ON Z2.單別 = 'E11' AND C.批號 = Z2.條碼
WHERE
	A.單據類別 = 'F32');

-- Oracle user_views
CREATE VIEW "VIEWFILF042" ("單別", "單號", "數量") AS (
SELECT 
	A.單據類別 單別, 
	A.單據編號 單號,
	sum(A.贈品數量) 數量
FROM 
	FIL0040 A
WHERE
	A.單據類別 = 'F32'
GROUP BY
	A.單據類別, 
	A.單據編號);

-- Oracle user_views
CREATE VIEW "VIEWFILF050" ("單別", "單號", "廠商編號", "廠商名稱", "公司代碼", "公司名稱", "單據日期", "簽核系統", "交貨地點", "交貨方式", "出廠原因", "作業員", "作業員姓名", "流水編號", "填表人", "填表人姓名", "填表日", "最後更新者", "更新者姓名", "最後更新日", "簽核狀態") AS (
SELECT
	A.單據類別 單別,
	A.單據編號 單號,
	A.廠客編號 廠商編號,
	C.全名 廠商名稱,
	A.公司代碼,
	nvl(E.全名, ' ') 公司名稱,
	A.單據日期,
	A.簽核系統, 
	B.價格條件 交貨地點,
	A.稅別 交貨方式,
	A.備註 出廠原因, 
	A.業務員 作業員,
	nvl(D.員工姓名,' ') 作業員姓名, 	
	A.流水編號,
	A.填表人,
	nvl(Z1.員工姓名,' ') 填表人姓名, 
	A.填表日, 
	A.最後更新者,
	nvl(Z2.員工姓名,' ') 更新者姓名, 
	A.最後更新日,
	nvl(Z3.簽核狀態, '0') 簽核狀態
FROM
	FIL0030 A
	INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
	INNER JOIN FIL0011 C ON A.廠客編號 = C.編號
	LEFT JOIN FIL0010 D ON A.業務員 = D.員工編號
	LEFT JOIN ViewFIL0011 E ON A.公司代碼 = E.代碼
	LEFT JOIN FIL0010 Z1 ON A.填表人 = Z1.員工編號
	LEFT JOIN FIL0010 Z2 ON A.最後更新者 = Z2.員工編號
	LEFT JOIN ViewOfObjProperties Z3 ON A.流水編號 = Z3.單據流水號
WHERE
	A.單據類別 = 'F33');

-- Oracle user_views
CREATE VIEW "VIEWFILF051" ("單別", "單號", "序號", "版銅編號", "品名", "規格", "圓周", "版長", "說明", "數量", "交期", "出庫單號", "備註說明", "出廠原因", "回廠", "回廠日期", "流水編號", "最後更新者", "更新者姓名", "最後更新日") AS (
SELECT 
	A.單據類別 單別, 
	A.單據編號 單號,
	A.單據序號 序號,
	A.產品編號 版銅編號,
	B.品名,
	B.規格,
	B.圓周,
	B.版長,
	B.說明,
	A.異動數量 數量,
	A.異動日期 交期,
	A.文數字1 出庫單號,
	A.備註說明,
	NVL(D.文字1,' ') 出廠原因,
	NVL(E.回廠,0) 回廠,
	NVL(TO_CHAR(E.回廠日期,'YYYYMMDD HH24:MI:SS'),' ') 回廠日期,
	A.流水編號,
	A.最後更新者,
	NVL(Z1.員工姓名,' ') 更新者姓名,
	A.最後更新日
FROM 
	FIL0040 A
	INNER JOIN ViewFIL3112 B ON A.產品編號 = B.代碼
	LEFT JOIN FIL0041 D ON D.單別 = A.單據類別 AND D.單號 = A.單據編號 AND D.序號 = A.單據序號
	LEFT JOIN FIL0010 Z1 ON A.最後更新者 = Z1.員工編號
	LEFT JOIN FIL004D E ON E.歸屬流水編號 = A.流水編號
WHERE
	A.單據類別 = 'F33');

-- Oracle user_views
CREATE VIEW "VIEWFILF052" ("單別", "單號", "出廠數", "出庫數", "回廠數", "已出庫", "已結案") AS (
SELECT 
	A.單據類別 單別, 
	A.單據編號 單號,
	sum(A.異動數量) 出廠數,
	sum(decode(A.文數字1, ' ', 0, A.異動數量)) 出庫數,
	sum(NVL(B.回廠,0)) 回廠數,
	case when sum(A.異動數量)= sum(decode(A.文數字1, ' ', 0, A.異動數量)) then 1 else 0 end 已出庫,
	case when sum(A.異動數量)= sum(NVL(B.回廠,0)) then 1 else 0 end 已結案
FROM 
	FIL0040 A
	LEFT JOIN 
	(SELECT
		A.歸屬流水編號,
		MAX(A.回廠) 回廠
	 FROM
		FIL004D A
	 WHERE
		A.歸屬流水編號 <> ' '
	 GROUP BY
		A.歸屬流水編號	
	) B ON A.流水編號 = B.歸屬流水編號
WHERE
	A.單據類別 = 'F33'
GROUP BY
	A.單據類別, 
	A.單據編號);

-- Oracle user_views
CREATE VIEW "VIEWFILF053" ("單別", "單號", "公司代碼", "公司名稱", "單據日期", "簽核系統", "備註", "作業員", "作業員姓名", "流水編號", "填表人", "填表人姓名", "填表日", "最後更新者", "更新者姓名", "最後更新日", "簽核狀態", "簽收") AS (
SELECT
	A.單據類別 單別,
	A.單據編號 單號,
	A.公司代碼,
	nvl(E.全名, ' ') 公司名稱,
	A.單據日期,
	A.簽核系統, 
	A.備註, 
	A.業務員 作業員,
	nvl(D.員工姓名,' ') 作業員姓名, 	
	A.流水編號,
	A.填表人,
	nvl(Z1.員工姓名,' ') 填表人姓名, 
	A.填表日, 
	A.最後更新者,
	nvl(Z2.員工姓名,' ') 更新者姓名, 
	A.最後更新日,
	nvl(Z3.簽核狀態, '0') 簽核狀態,
	DECODE(nvl(dbms_lob.getlength(G.圖檔),0),0,0,1) 簽收
FROM
	FIL0030 A
	LEFT JOIN FIL0010 D ON A.業務員 = D.員工編號
	LEFT JOIN ViewFIL0011 E ON A.公司代碼 = E.代碼
	LEFT JOIN FIL0037 G ON A.單據類別 = G.製令單別 AND A.單據編號 = G.製令單號 AND G.材料序號=0
	LEFT JOIN FIL0010 Z1 ON A.填表人 = Z1.員工編號
	LEFT JOIN FIL0010 Z2 ON A.最後更新者 = Z2.員工編號
	LEFT JOIN ViewOfObjProperties Z3 ON A.流水編號 = Z3.單據流水號
WHERE
	A.單據類別 = 'F34');

-- Oracle user_views
CREATE VIEW "VIEWFILF054" ("單別", "單號", "序號", "出廠單號", "日期", "數量", "版銅編號", "品名", "規格", "說明", "圓周", "版長", "備註說明", "回廠", "回廠日期", "流水編號", "最後更新者", "更新者姓名", "最後更新日") AS (
SELECT 
	'F34' 單別, 
	A.文數字1 單號, 
	A.單據序號 序號,
	A.單據編號 出廠單號,
	B.單據日期 日期,
	A.異動數量 數量,
	A.產品編號 版銅編號,
	C.品名,
	C.規格,
	C.說明,
	C.圓周,
	C.版長,
	A.備註說明,
	D.回廠,
	D.回廠日期,
	A.流水編號,
	A.最後更新者,
	NVL(Z1.員工姓名,' ') 更新者姓名,
	A.最後更新日
FROM 
	FIL0040 A
	INNER JOIN FIL0030 B ON B.單據類別 = 'F34' AND B.單據編號 = A.文數字1
	/*版銅代碼*/
	INNER JOIN ViewFIL3112 C ON A.產品編號 = C.代碼
	/*回廠*/
	LEFT JOIN FIL004D D ON A.流水編號 = D.歸屬流水編號
	LEFT JOIN FIL0010 Z1 ON A.最後更新者 = Z1.員工編號
WHERE
	/*出庫F34與出廠F33同一筆記錄，出庫單號記錄於文數字1*/
	A.單據類別 = 'F33' AND
	A.文數字1 != ' ');

-- Oracle user_views
CREATE VIEW "VIEWFILF055" ("單別", "單號", "筆數", "數量") AS (
SELECT 
	'F34' 單別, 
	A.文數字1 單號,
	count(*) 筆數,
	sum(A.異動數量) 數量
FROM 
	FIL0040 A
WHERE
	/*出庫F34與出廠F33同一筆記錄，出庫單號記錄於文數字1*/
	A.單據類別 = 'F33' AND
	A.文數字1 != ' '
GROUP BY
	A.文數字1);

-- Oracle user_views
CREATE VIEW "VIEWFILF061" ("單別", "單號", "類別代碼", "類別說明", "公司代碼", "公司名稱", "單據日期", "簽核系統", "備註", "倉管員", "倉管員姓名", "流水編號", "填表人", "填表人姓名", "填表日", "最後更新者", "更新者姓名", "製程代碼", "製程名稱", "工站代碼", "工站名稱", "製程工站", "機台代碼", "機台名稱", "最後更新日", "簽核狀態") AS (
SELECT
	A.單據類別 單別,
	A.單據編號 單號,
	A.稅別 類別代碼,
	decode(A.稅別, 'A', '委外', '廠內') 類別說明,
	A.公司代碼,
	nvl(E.全名, ' ') 公司名稱,
	A.單據日期,
	A.簽核系統, 
	A.備註, 
	A.業務員 倉管員,
	nvl(D.員工姓名,' ') 倉管員姓名, 	
	A.流水編號,
	A.填表人,
	nvl(Z1.員工姓名,' ') 填表人姓名, 
	A.填表日, 
	A.最後更新者,
	nvl(Z2.員工姓名,' ') 更新者姓名, 
	B.製程代碼,
		decode(A.稅別, 'A', nvl(I.製程名稱, ' '), decode(B.製程代碼, 'M', '原料', 'N', '物料', 'O', '其他', 'S', '半成品', 'P', '版銅', '錯誤')) 製程名稱,
	B.工站代碼,
	decode(A.稅別, 'A', nvl(I.名稱, ' '), nvl(J.名稱, ' ')) 工站名稱,
	decode(A.稅別, 'A', nvl(I.製程工站, ' '),  nvl(J.名稱, ' ') || '(' || decode(B.製程代碼, 'M', '原料', 'N', '物料', 'O', '其他', 'S', '半成品', 'P', '版銅', '錯誤') || ')') 製程工站,
	B.機台代碼,
	nvl(H.名稱, ' ') 機台名稱,
	A.最後更新日,
	nvl(Z3.簽核狀態, '0') 簽核狀態
FROM
	FIL0030 A
	INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
	LEFT JOIN FIL0010 D ON A.業務員 = D.員工編號
	LEFT JOIN ViewFIL0011 E ON A.公司代碼 = E.代碼
	LEFT JOIN FIL0037 G ON A.單據類別 = G.製令單別 AND A.單據編號 = G.製令單號 AND G.材料序號=0
	/*委外盤點.工站*/
	LEFT JOIN ViewFIL310P H ON B.機台代碼=H.代碼
	LEFT JOIN ViewFIL310O I ON B.工站代碼=I.代碼
/*廠內盤點.物料大類*/
	LEFT JOIN ViewFIL310B J ON B.工站代碼 = J.代碼
	LEFT JOIN FIL0010 Z1 ON A.填表人 = Z1.員工編號
	LEFT JOIN FIL0010 Z2 ON A.最後更新者 = Z2.員工編號
	LEFT JOIN ViewOfObjProperties Z3 ON A.流水編號 = Z3.單據流水號
WHERE
	A.單據類別 = 'F35');

-- Oracle user_views
CREATE VIEW "VIEWFILF062" ("單別", "單號", "序號", "料號", "品名", "規格", "異動類別", "異動說明", "異動日期", "製造日期", "箱號", "調整數量", "金額", "重量", "箱數", "批號", "廠商批號", "製令單號", "單價", "差異數", "已盤", "備註說明", "流水編號", "最後更新者", "更新者姓名", "最後更新日") AS (
SELECT 
	A.單據類別 單別, 
	A.單據編號 單號,
	A.單據序號 序號,
	A.產品編號 料號,
	nvl(E.品名, ' ') 品名,
	nvl(E.規格, ' ') 規格,
	A.異動類別,
	decode(A.異動類別, '1', '半成品', '材料') 異動說明,
	A.異動日期,
	nvl(F.製造日期, ' ') 製造日期,
	A.異動數量 箱號,
	A.贈品數量 調整數量,
	A.異動金額 金額,
	A.毛重 重量,
	A.數值1 箱數,
	C.批號,
	NVL(Z2.廠商批號,' ') 廠商批號,
	A.廠客品號 製令單號,
	A.異動單價 單價,
	0 差異數,
	A.Logical1 已盤,
	A.備註說明,
	A.流水編號,
	A.最後更新者,
	NVL(Z1.員工姓名,' ') 更新者姓名,
	A.最後更新日
FROM 
	FIL0040 A
	/*特殊欄位*/
	INNER JOIN FIL0041 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號 AND A.單據序號 = C.序號
	/*製造日期*/
	LEFT JOIN ViewFIL4036 F ON A.廠客品號 = F.製令單號
	LEFT JOIN FIL0012 E ON A.產品編號 = E.產品編號
	LEFT JOIN FIL0010 Z1 ON A.最後更新者 = Z1.員工編號
	LEFT JOIN ViewFIL1024 Z2 ON Z2.單別 = 'E11' AND C.批號 = Z2.條碼
WHERE
	A.單據類別 = 'F35');

-- Oracle user_views
CREATE VIEW "VIEWFILF063" ("單別", "單號", "數量", "金額") AS (
SELECT 
	A.單據類別 單別, 
	A.單據編號 單號,
	sum(A.贈品數量) 數量,
	sum(A.異動金額) 金額
FROM 
	FIL0040 A
WHERE
	A.單據類別 = 'F35'
GROUP BY
	A.單據類別, 
	A.單據編號);

-- Oracle user_views
CREATE VIEW "VIEWFILF0W0" ("製程代碼", "製程名稱", "工站代碼", "工站名稱", "製程工站", "產品編號", "品名", "規格", "氣閥代碼", "製令單號", "製造日期", "加工數量", "回廠數量", "退回數量", "調整數量", "生產數量", "報廢數量", "合理剔除數", "結存數量", "待生產數量", "待回廠數量", "結案") AS (
SELECT 
	A.製程代碼,
	D.製程名稱,
	A.工站代碼,
	D.名稱 工站名稱,
	D.製程工站,
	C.產品編號,
	C.產品名稱 品名,
	C.展開尺寸 規格,
	C.加工項目_氣閥代碼 氣閥代碼,
	A.製令單號,
	A.填表日 製造日期,
	A.加工數量,
	A.回廠數量,
	A.退回數量,
	A.調整數量,
	nvl(B.生產數量,0) 生產數量,
	nvl(B.報廢數量,0) 報廢數量,
	nvl(B.合理剔除數,0) 合理剔除數,
	A.加工數量 - A.回廠數量 - A.退回數量 + A.調整數量 - nvl(B.報廢數量,0)-nvl(B.合理剔除數,0) 結存數量,
	DECODE(A.加工數量 - A.回廠數量 - A.退回數量 + A.調整數量 - nvl(B.報廢數量,0)-nvl(B.合理剔除數,0),0,0,A.加工數量 - A.退回數量 - nvl(B.生產數量,0) - nvl(B.報廢數量,0)-nvl(B.合理剔除數,0)) 待生產數量,
	DECODE(A.加工數量 - A.回廠數量 - A.退回數量 + A.調整數量 - nvl(B.報廢數量,0)-nvl(B.合理剔除數,0),0,0,nvl(B.生產數量,0) - A.回廠數量) 待回廠數量,
	DECODE(A.加工數量 - A.退回數量,nvl(B.報廢數量,0)+nvl(B.生產數量,0)+nvl(B.合理剔除數,0),1,0) 結案
FROM
	(SELECT 
			B.製程代碼,
			B.工站代碼,
			A.廠客品號 製令單號,
			min(nvl(D.填表日,E.填表日)) 填表日,
			sum(decode(A.單據類別, 'F11', A.贈品數量, 0)) 加工數量,
			sum(decode(A.單據類別, 'F21', A.贈品數量*decode(A.Logical1,0,1,0), 0)) 回廠數量,
			sum(decode(A.單據類別, 'F21', A.贈品數量*decode(A.Logical1,0,0,1), 0)) 退回數量,
			sum(decode(A.單據類別, 'F32', A.贈品數量, 0)) 調整數量
		FROM 
			FIL0040 A
			INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
			INNER JOIN FIL0037 C ON A.單據類別 = C.製令單別 AND A.單據編號 = C.製令單號 AND C.材料序號=0 AND ((nvl(dbms_lob.getlength(C.圖檔),0) > 0) OR A.單據類別 = 'F32')
			LEFT JOIN FIL0030 D ON A.單據類別 = D.單據類別 AND A.單據編號 = D.單據編號 AND D.單據類別='F11'
			LEFT JOIN FIL0030 E ON A.單據類別 = E.單據類別 AND A.單據編號 = E.單據編號
		WHERE
			A.單據類別 between 'F11' and 'F32' AND
			A.單據類別 != 'F31' 
		GROUP BY
			B.製程代碼,
			B.工站代碼,
			A.廠客品號
	)A
INNER JOIN ViewFIL310O D ON A.工站代碼 = D.代碼
INNER JOIN FIL0032 C ON C.製令單別 = 'C11' AND C.製令單號 = A.製令單號 
LEFT JOIN ViewFILF014 B ON A.工站代碼 = B.工站代碼 AND A.製令單號 = B.製令單號
);

-- Oracle user_views
CREATE VIEW "VIEWFILF0W1" ("單別", "單號", "序號", "產品編號", "品名", "規格", "異動日期", "箱號", "數量", "重量", "箱數", "批號", "庫存參數", "製令單號", "製造日期", "製程代碼", "製程名稱", "工站代碼", "工站名稱", "製程工站", "類別", "備註說明", "流水編號", "最後更新者", "更新者姓名", "最後更新日") AS (
SELECT 
	A.單據類別 單別, 
	A.單據編號 單號,
	A.單據序號 序號,
	H.產品編號,
	H.產品名稱 品名,
	E.規格,
	A.異動日期,
	A.異動數量 箱號,
	A.贈品數量 數量,
	A.毛重 重量,
	A.數值1 箱數,
	B.批號,
	decode(A.單據類別, 'F11', 1, 'F21', -1, 1) 庫存參數,
	A.廠客品號 製令單號,
	A.異動日期 製造日期,
	C.製程代碼,
	G.製程名稱,
	C.工站代碼,
	G.名稱 工站名稱,
	G.製程工站,
	decode(A.單據類別, 'F11', '加工' , 'F21', '回廠', '調整') 類別,
	A.備註說明,
	A.流水編號,
	A.最後更新者,
	nvl(Z1.員工姓名, ' ') 更新者姓名,
	A.最後更新日
FROM 
	FIL0040 A
	/*特殊欄位*/
	INNER JOIN FIL0041 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號 AND A.單據序號 = B.序號
	/*表頭特殊欄位*/
	INNER JOIN FIL0031 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號
	/*簽收*/
	INNER JOIN FIL0037 D ON A.單據類別 = D.製令單別 AND A.單據編號 = D.製令單號 AND D.材料序號=0 AND ((nvl(dbms_lob.getlength(D.圖檔),0) > 0) OR A.單據類別 = 'F32')
	/*產品編號*/
	INNER JOIN FIL0032 H ON H.製令單別 = 'C11' AND H.製令單號 = A.廠客品號
	/*成品*/
	INNER JOIN FIL0012 E ON H.產品編號 = E.產品編號 AND E.產品類別 = 'F'
	/*委外工站*/
	INNER JOIN ViewFIL310O G ON C.工站代碼 = G.代碼
	LEFT JOIN FIL0010 Z1 ON A.最後更新者 = Z1.員工編號
WHERE
	A.單據類別 between 'F11' and 'F32' AND
	A.單據類別 != 'F31');

-- Oracle user_views
CREATE VIEW "VIEWFILF0W3" ("單別", "單號", "序號", "異動日期", "料號", "品名", "規格", "箱數", "數量", "批號", "類別", "庫存參數", "製程代碼", "工站代碼", "製程名稱", "工站名稱", "製程工站", "備註說明", "填表日") AS (
Select
	A.單別, 
	A.單號,
	A.序號,
	A.異動日期,
	A.料號,
	E.品名,
	E.規格,
	A.箱數,
	nvl(A.數量,0) 數量,
	A.批號,
	decode(A.單別, 'F11', '加工', 'F21', '回廠', 'F32', '調整', '耗用') 類別,
	decode(A.單別, 'F11', 1, 'F21', -1, 'F32', 1, -1) 庫存參數,
	A.製程代碼,
	A.工站代碼,
	G.製程名稱,
	G.名稱 工站名稱,
	G.製程工站,
	A.備註說明,
	DECODE(D1.送簽日時,NULL,B.填表日,D1.送簽日時) 填表日
FROM	
(
/*材料耗用.氣閥.鐵條*/
/*批號1*/
SELECT 
	A.單據類別 單別, 
	A.單據編號 單號,
	A.單據序號 序號,
	A.異動日期,
	D.料號,
	B.數值1 數量,
	C.製程代碼,
	C.工站代碼,
	B.文數字1 批號,
	A.備註說明,
	0 箱數
FROM 
	FIL0040 A
	INNER JOIN FIL0041 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號 AND A.單據序號 = B.序號
	INNER JOIN FIL0031 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號
	INNER JOIN ViewFIL1024 D ON B.文數字1 = D.條碼
	INNER JOIN ViewFIL310P E ON C.機台代碼 = E.代碼 AND E.委外 = 1
	INNER JOIN FIL1014 F ON F.代碼類別 = '工站代碼' AND C.工站代碼 = F.系統代碼
WHERE
	A.單據類別 = 'C41' AND
	A.異動類別 = 'A' AND
	C.製程代碼 between 'C31F' and 'C31G' AND
	D.料號 != ' ' AND 
	A.異動日期 >= F.日期

UNION ALL

/*批號2*/	
SELECT 
	A.單據類別 單別, 
	A.單據編號 單號,
	A.單據序號+9000 序號,
	A.異動日期,
	D.料號,
	B.數值2 數量,
	C.製程代碼,
	C.工站代碼,
	B.文數字2 批號,
	A.備註說明,
	0 箱數
FROM 
	FIL0040 A
	INNER JOIN FIL0041 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號 AND A.單據序號 = B.序號
	INNER JOIN FIL0031 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號
	INNER JOIN ViewFIL1024 D ON B.文數字2 = D.條碼
	INNER JOIN ViewFIL310P E ON C.機台代碼 = E.代碼 AND E.委外 = 1
	INNER JOIN FIL1014 F ON F.代碼類別 = '工站代碼' AND C.工站代碼 = F.系統代碼
WHERE
	A.單據類別 = 'C41' AND
	A.異動類別 = 'A' AND
	C.製程代碼 between 'C31F' and 'C31G' AND
	D.料號 != ' ' AND
	A.異動日期 >= F.日期

UNION ALL

/*材料耗用.氣閥.鐵條*/
/*報廢*/	
SELECT 
	A.單據類別 單別, 
	A.單據編號 單號,
	A.單據序號+9500 序號,
	A.異動日期,
	A.產品編號 料號,
	A.異動數量 數量,
	C.製程代碼,
	C.工站代碼,
	B.批號,
	A.備註說明,
	0 箱數
FROM 
	FIL0040 A
	INNER JOIN FIL0041 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號 AND A.單據序號 = B.序號
	INNER JOIN FIL0031 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號
	INNER JOIN FIL0030 G ON A.單據類別 = G.單據類別 AND A.單據編號 = G.單據編號
	INNER JOIN FIL1014 F ON F.代碼類別 = '工站代碼' AND C.工站代碼 = F.系統代碼
WHERE
	A.單據類別 = 'C41' AND
	A.異動類別 = 'D' AND
	C.製程代碼 between 'C31F' and 'C31G' AND
	A.產品編號 != ' '	 AND
	A.異動日期 >= F.日期
	
UNION ALL

SELECT 
	A.單據類別 單別, 
	A.單據編號 單號,
	A.單據序號 序號,
	A.異動日期,
	A.產品編號 料號,
	A.贈品數量 數量,
	B.製程代碼,
	B.工站代碼,
	C.批號,
	A.備註說明,
	A.數值1 箱數
FROM 
	FIL0040 A
	/*特殊欄位*/
	INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
	/*料號*/
	INNER JOIN FIL0012 E ON A.產品編號 = E.產品編號 AND E.產品類別 between 'M' and 'P'
	/*簽收*/
	INNER JOIN FIL0041 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號 AND A.單據序號 = C.序號
	INNER JOIN FIL0037 D ON A.單據類別 = D.製令單別 AND A.單據編號 = D.製令單號 AND D.材料序號=0 AND ((nvl(dbms_lob.getlength(D.圖檔),0) > 0) OR A.單據類別 = 'F32')
	INNER JOIN FIL1014 F ON F.代碼類別 = '工站代碼' AND B.工站代碼 = F.系統代碼
WHERE
	A.單據類別 between 'F11' and 'F32' AND
	A.單據類別 != 'F31' AND
	A.異動日期 >= F.日期
	) A	
INNER JOIN FIL0030 B ON A.單別 = B.單據類別 AND A.單號 = B.單據編號
LEFT JOIN ViewOfObjProperties D1 on B.流水編號 = D1.單據流水號
/*料號*/
INNER JOIN FIL0012 E ON A.料號 = E.產品編號
/*工站*/
INNER JOIN ViewFIL310O G ON A.工站代碼 = G.代碼	
);

-- Oracle user_views
CREATE VIEW "VIEWFILF0W3A" ("單別", "單號", "序號", "料號", "數量", "製程代碼", "工站代碼", "批號", "填表日") AS (
SELECT 
	A.單別, 
	A.單號,
	A.序號,
	A.料號,
	A.數量,
	A.製程代碼,
	A.工站代碼,
	A.批號,
	A.填表日
FROM 
(SELECT 
	A.單據類別 單別, 
	A.單據編號 單號,
	A.單據序號 序號,
	A.產品編號 料號,
	A.贈品數量 數量,
	B.製程代碼,
	B.工站代碼,
	C.批號,
	DECODE(D1.送簽日時,NULL,D.填表日,D1.送簽日時) 填表日
FROM 
	FIL0040 A
	/*特殊欄位*/
	INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
	INNER JOIN FIL0030 D ON A.單據類別 = D.單據類別 AND A.單據編號 = D.單據編號
	LEFT JOIN ViewOfObjProperties D1 on D.流水編號 = D1.單據流水號
	/*料號*/
	INNER JOIN FIL0012 E ON A.產品編號 = E.產品編號 AND E.產品類別 between 'M' and 'P'
	INNER JOIN FIL0041 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號 AND A.單據序號 = C.序號
	/*簽收*/
	INNER JOIN FIL0037 F ON A.單據類別 = F.製令單別 AND A.單據編號 = F.製令單號 AND F.材料序號=0 AND ((nvl(dbms_lob.getlength(F.圖檔),0) > 0) OR A.單據類別 = 'F32')
	INNER JOIN FIL1014 H ON H.代碼類別 = '工站代碼' AND B.工站代碼 = H.系統代碼
WHERE
	A.單據類別 between 'F11' and 'F32' AND
	A.單據類別 != 'F31' AND 
	A.異動日期 >= H.日期

UNION ALL
	
/*材料耗用.氣閥.鐵條*/
/*批號1*/
SELECT 
	A.單據類別 單別, 
	A.單據編號 單號,
	A.單據序號 序號,
	D.料號,
	B.數值1 數量,
	C.製程代碼,
	C.工站代碼,
	B.文數字1 批號,
	DECODE(D1.送簽日時,NULL,G.填表日,D1.送簽日時) 填表日
FROM 
	FIL0040 A
	INNER JOIN FIL0041 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號 AND A.單據序號 = B.序號
	INNER JOIN FIL0031 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號
	INNER JOIN FIL0030 G ON A.單據類別 = G.單據類別 AND A.單據編號 = G.單據編號
	LEFT JOIN ViewOfObjProperties D1 on G.流水編號 = D1.單據流水號
	INNER JOIN ViewFIL1024 D ON B.文數字1 = D.條碼
	INNER JOIN ViewFIL310P E ON C.機台代碼 = E.代碼 AND E.委外 = 1
	INNER JOIN FIL1014 H ON H.代碼類別 = '工站代碼' AND C.工站代碼 = H.系統代碼
WHERE
	A.單據類別 = 'C41' AND
	A.異動類別 = 'A' AND
	C.製程代碼 between 'C31F' and 'C31G' AND
	D.料號 != ' ' AND 
	A.異動日期 >= H.日期

UNION ALL

/*材料耗用.氣閥.鐵條*/
/*批號2*/	
SELECT 
	A.單據類別 單別, 
	A.單據編號 單號,
	A.單據序號+9000 序號,
	D.料號,
	B.數值2 數量,
	C.製程代碼,
	C.工站代碼,
	B.文數字2 批號,
	DECODE(D1.送簽日時,NULL,G.填表日,D1.送簽日時) 填表日
FROM 
	FIL0040 A
	INNER JOIN FIL0041 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號 AND A.單據序號 = B.序號
	INNER JOIN FIL0031 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號
	INNER JOIN FIL0030 G ON A.單據類別 = G.單據類別 AND A.單據編號 = G.單據編號
	LEFT JOIN ViewOfObjProperties D1 on G.流水編號 = D1.單據流水號
	INNER JOIN ViewFIL1024 D ON B.文數字2 = D.條碼
	INNER JOIN ViewFIL310P E ON C.機台代碼 = E.代碼 AND E.委外 = 1
	INNER JOIN FIL1014 H ON H.代碼類別 = '工站代碼' AND C.工站代碼 = H.系統代碼
WHERE
	A.單據類別 = 'C41' AND
	A.異動類別 = 'A' AND
	C.製程代碼 between 'C31F' and 'C31G' AND
	D.料號 != ' ' AND 
	A.異動日期 >= H.日期

UNION ALL

/*材料耗用.氣閥.鐵條*/
/*報廢*/	
SELECT 
	A.單據類別 單別, 
	A.單據編號 單號,
	A.單據序號+9500 序號,
	A.產品編號 料號,
	A.異動數量 數量,
	C.製程代碼,
	C.工站代碼,
	B.批號,
	DECODE(D1.送簽日時,NULL,G.填表日,D1.送簽日時) 填表日
FROM 
	FIL0040 A
	INNER JOIN FIL0041 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號 AND A.單據序號 = B.序號
	INNER JOIN FIL0031 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號
	INNER JOIN FIL0030 G ON A.單據類別 = G.單據類別 AND A.單據編號 = G.單據編號
	LEFT JOIN ViewOfObjProperties D1 on G.流水編號 = D1.單據流水號
	INNER JOIN FIL1014 H ON H.代碼類別 = '工站代碼' AND C.工站代碼 = H.系統代碼
WHERE
	A.單據類別 = 'C41' AND
	A.異動類別 = 'D' AND
	C.製程代碼 between 'C31F' and 'C31G' AND
	A.產品編號 != ' '	 AND 
	A.異動日期 >= H.日期
) A
	INNER JOIN ViewFILF013 F ON F.工站代碼=A.工站代碼 AND F.批號 = A.批號 AND A.填表日 >= F.填表日
);

-- Oracle user_views
CREATE VIEW "VIEWFILF0W3B" ("單別", "單號", "序號", "料號", "批號", "數量", "製程代碼", "工站代碼") AS (
SELECT 
	A.單別, 
	A.單號,
	A.序號,
	A.料號,
	A.批號,
	A.數量,
	A.製程代碼,
	A.工站代碼
FROM	
(SELECT 
	A.單據類別 單別, 
	A.單據編號 單號,
	A.單據序號 序號,
	A.產品編號 料號,
	C.批號,
	A.贈品數量 數量,
	B.製程代碼,
	B.工站代碼
FROM 
	FIL0040 A
	INNER JOIN FIL0041 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號 AND A.單據序號 = C.序號
	/*特殊欄位*/
	INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
	/*料號*/
	INNER JOIN FIL0012 E ON A.產品編號 = E.產品編號 AND E.產品類別 between 'M' and 'P'
	/*簽收*/
	INNER JOIN FIL0037 F ON A.單據類別 = F.製令單別 AND A.單據編號 = F.製令單號 AND F.材料序號=0 AND ((nvl(dbms_lob.getlength(F.圖檔),0) > 0) OR A.單據類別 = 'F32')
	INNER JOIN FIL1014 H ON H.代碼類別 = '工站代碼' AND B.工站代碼 = H.系統代碼
WHERE
	A.單據類別 between 'F11' and 'F32' AND
	A.單據類別 != 'F31'AND 
	A.異動日期 >= H.日期

UNION ALL
	
/*材料耗用.氣閥.鐵條*/
/*批號1*/
SELECT 
	A.單據類別 單別, 
	A.單據編號 單號,
	A.單據序號 序號,
	D.料號,
	B.文數字1 批號,
	B.數值1 數量,
	C.製程代碼,
	C.工站代碼
FROM 
	FIL0040 A
	INNER JOIN FIL0041 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號 AND A.單據序號 = B.序號
	INNER JOIN FIL0031 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號
	INNER JOIN ViewFIL1024 D ON B.文數字1 = D.條碼
	INNER JOIN ViewFIL310P E ON C.機台代碼 = E.代碼 AND E.委外 = 1
	INNER JOIN FIL1014 H ON H.代碼類別 = '工站代碼' AND C.工站代碼 = H.系統代碼
WHERE
	A.單據類別 = 'C41' AND
	A.異動類別 = 'A' AND
	C.製程代碼 between 'C31F' and 'C31G' AND
	D.料號 != ' 'AND 
	A.異動日期 >= H.日期

UNION ALL

/*材料耗用.氣閥.鐵條*/
/*批號2*/	
SELECT 
	A.單據類別 單別, 
	A.單據編號 單號,
	A.單據序號+9000 序號,
	D.料號,
	B.文數字2 批號,
	B.數值2 數量,
	C.製程代碼,
	C.工站代碼
FROM 
	FIL0040 A
	INNER JOIN FIL0041 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號 AND A.單據序號 = B.序號
	INNER JOIN FIL0031 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號
	INNER JOIN ViewFIL1024 D ON B.文數字2 = D.條碼
	INNER JOIN ViewFIL310P E ON C.機台代碼 = E.代碼 AND E.委外 = 1
	INNER JOIN FIL1014 H ON H.代碼類別 = '工站代碼' AND C.工站代碼 = H.系統代碼
WHERE
	A.單據類別 = 'C41' AND
	A.異動類別 = 'A' AND
	C.製程代碼 between 'C31F' and 'C31G' AND
	D.料號 != ' 'AND 
	A.異動日期 >= H.日期


UNION ALL

/*材料耗用.氣閥.鐵條*/
/*報廢*/	
SELECT 
	A.單據類別 單別, 
	A.單據編號 單號,
	A.單據序號+9500 序號,
	A.產品編號 料號,
	B.批號,
	A.異動數量 數量,
	C.製程代碼,
	C.工站代碼
FROM 
	FIL0040 A
	INNER JOIN FIL0041 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號 AND A.單據序號 = B.序號
	INNER JOIN FIL0031 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號
	INNER JOIN FIL1014 H ON H.代碼類別 = '工站代碼' AND C.工站代碼 = H.系統代碼
WHERE
	A.單據類別 = 'C41' AND
	A.異動類別 = 'D' AND
	C.製程代碼 between 'C31F' and 'C31G' AND
	A.產品編號 != ' '	AND 
	A.異動日期 >= H.日期	
) A
INNER JOIN FIL0030 B ON A.單別 = B.單據類別 AND A.單號 = B.單據編號
LEFT JOIN ViewOfObjProperties D1 on B.流水編號 = D1.單據流水號
INNER JOIN ViewFILF013 F ON F.批號 = A.批號 AND DECODE(D1.送簽日時,NULL,B.填表日,D1.送簽日時) >= F.填表日	
);

-- Oracle user_views
CREATE VIEW "VIEWFILF0W3C" ("批號", "料號", "製程代碼", "工站代碼") AS (
SELECT DISTINCT
	C.批號,
	A.產品編號 料號,
	B.製程代碼,
	B.工站代碼
FROM 
	FIL0040 A
	/*特殊欄位*/
	INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
	/*料號*/
	INNER JOIN FIL0012 E ON A.產品編號 = E.產品編號 AND E.產品類別 between 'M' and 'P'
	INNER JOIN FIL0041 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號 AND A.單據序號 = C.序號
	/*簽收*/
	INNER JOIN FIL0037 F ON A.單據類別 = F.製令單別 AND A.單據編號 = F.製令單號 AND F.材料序號=0 AND ((nvl(dbms_lob.getlength(F.圖檔),0) > 0) OR A.單據類別 = 'F32')
WHERE
	A.單據類別 between 'F11' and 'F32' AND
	A.單據類別 != 'F31'		
	
UNION ALL
	
SELECT DISTINCT
	B.文數字1 批號,
	D.料號,
	C.製程代碼,
	C.工站代碼
FROM 
	FIL0040 A
	INNER JOIN FIL0041 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號 AND A.單據序號 = B.序號
	INNER JOIN FIL0031 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號
	INNER JOIN ViewFIL1024 D ON B.文數字1 = D.條碼
	INNER JOIN ViewFIL310P E ON C.機台代碼 = E.代碼 AND E.委外 = 1
WHERE
	A.單據類別 = 'C41' AND
	A.異動類別 = 'A' AND
	C.製程代碼 between 'C31F' and 'C31G' AND
	D.料號 != ' '

UNION ALL

/*材料耗用.氣閥.鐵條*/
/*批號2*/	
SELECT DISTINCT
	B.文數字2 批號,
	D.料號,
	C.製程代碼,
	C.工站代碼
FROM 
	FIL0040 A
	INNER JOIN FIL0041 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號 AND A.單據序號 = B.序號
	INNER JOIN FIL0031 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號
	INNER JOIN ViewFIL1024 D ON B.文數字2 = D.條碼
	INNER JOIN ViewFIL310P E ON C.機台代碼 = E.代碼 AND E.委外 = 1
WHERE
	A.單據類別 = 'C41' AND
	A.異動類別 = 'A' AND
	C.製程代碼 between 'C31F' and 'C31G' AND
	D.料號 != ' '
);

-- Oracle user_views
CREATE VIEW "VIEWFILF0W3D" ("料號", "工站代碼", "預估用量") AS (
SELECT 
		A.氣閥代碼 料號,
		A.工站代碼,
		SUM(A.待生產數量) 預估用量
FROM
	(
	SELECT 
		A.工站代碼,
		C.加工項目_氣閥代碼 氣閥代碼,
		DECODE(A.加工數量 - A.回廠數量 - A.退回數量 + A.調整數量 - nvl(B.報廢數量,0),0,0,A.加工數量 - A.退回數量 - nvl(B.生產數量,0) - nvl(B.報廢數量,0)) 待生產數量
	FROM
		(SELECT 
				B.製程代碼,
				B.工站代碼,
				A.廠客品號 製令單號,
				sum(decode(A.單據類別, 'F11', A.贈品數量, 0)) 加工數量,
				sum(decode(A.單據類別, 'F21', A.贈品數量*decode(A.Logical1,0,1,0), 0)) 回廠數量,
				sum(decode(A.單據類別, 'F21', A.贈品數量*decode(A.Logical1,0,0,1), 0)) 退回數量,
				sum(decode(A.單據類別, 'F32', A.贈品數量, 0)) 調整數量
			FROM 
				FIL0040 A
				INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
				INNER JOIN FIL0037 C ON A.單據類別 = C.製令單別 AND A.單據編號 = C.製令單號 AND C.材料序號=0 AND ((nvl(dbms_lob.getlength(C.圖檔),0) > 0) OR A.單據類別 = 'F32')
				INNER JOIN FIL1014 I ON I.代碼類別 = '工站代碼' AND B.工站代碼 = I.系統代碼	
			WHERE
				A.單據類別 between 'F11' and 'F32' AND
				A.單據類別 != 'F31' AND
				A.異動日期 >= I.日期一
			GROUP BY
				B.製程代碼,
				B.工站代碼,
				A.廠客品號
		) A
	INNER JOIN FIL0032 C ON C.製令單別 = 'C11' AND C.製令單號 = A.製令單號 
	LEFT JOIN ViewFILF014 B ON A.工站代碼 = B.工站代碼 AND A.製令單號 = B.製令單號 
	) A
GROUP BY 	
	A.氣閥代碼,
	A.工站代碼);

-- Oracle user_views
CREATE VIEW "VIEWFILF0W4" ("料號", "品名", "規格", "製程代碼", "製程名稱", "工站代碼", "工站名稱", "製程工站", "加工數量", "回廠數量", "耗用數量", "調整數量", "結存數量") AS (
SELECT 
	A.料號,
	A.品名,
	A.規格,
	A.製程代碼,
	A.製程名稱,
	A.工站代碼,
	A.工站名稱,
	A.製程工站,
	sum(decode(A.單別, 'F11', A.數量, 0)) 加工數量,
	sum(decode(A.單別, 'F21', A.數量, 0)) 回廠數量,
	sum(decode(A.單別, 'C41', A.數量, 0)) 耗用數量,
	sum(decode(A.單別, 'F32', A.數量, 0)) 調整數量,	
	sum(A.數量 * A.庫存參數) 結存數量
FROM 
	ViewFILF0W3 A
GROUP BY
	A.料號,
	A.品名,
	A.規格,
	A.製程代碼,
	A.製程名稱,
	A.工站代碼,
	A.工站名稱,
	A.製程工站);

-- Oracle user_views
CREATE VIEW "VIEWFILF0W4A" ("料號", "品名", "規格", "製程代碼", "製程名稱", "工站代碼", "工站名稱", "製程工站", "加工數量", "回廠數量", "耗用數量", "報廢數量", "調整數量", "結存數量") AS (
SELECT 
	A.料號,
	E.品名,
	E.規格,
	A.製程代碼,
	G.製程名稱,
	A.工站代碼,
	G.名稱 工站名稱,
	G.製程工站,
	sum(decode(A.單別, 'F11', A.數量, 0)) 加工數量,
	sum(decode(A.單別, 'F21', A.數量, 0)) 回廠數量,
	sum(decode(A.單別, 'C41', (case when A.序號 <= 9500 then A.數量 else 0 end), 0)) 耗用數量,
	sum(decode(A.單別, 'C41', (case when A.序號 > 9500 then A.數量 else 0 end), 0)) 報廢數量,
	sum(decode(A.單別, 'F32', A.數量, 0)) 調整數量,	
	sum(A.數量 * decode(A.單別, 'F11', 1, 'F21', -1, 'F32', 1, -1)) 結存數量
FROM 
	ViewFILF0W3A A
	/*料號*/
	INNER JOIN FIL0012 E ON A.料號 = E.產品編號
	/*工站*/
	INNER JOIN ViewFIL310O G ON A.工站代碼 = G.代碼
	
GROUP BY
	A.料號,
	E.品名,
	E.規格,
	A.製程代碼,
	G.製程名稱,
	A.工站代碼,
	G.名稱,
	G.製程工站);

-- Oracle user_views
CREATE VIEW "VIEWFILF0W4B" ("料號", "製程代碼", "工站代碼", "加工數量", "回廠數量", "耗用數量", "報廢數量", "調整數量", "結存數量") AS (
SELECT 
	A.料號,
	A.製程代碼,
	A.工站代碼,
	sum(A.加工數量) 加工數量,
	sum(A.回廠數量) 回廠數量,
	sum(A.耗用數量) 耗用數量,
	sum(A.報廢數量) 報廢數量,
	sum(A.調整數量) 調整數量,	
	sum(A.結存數量) 結存數量
FROM 		
(
	SELECT 
		A.產品編號 料號,
		B.製程代碼,
		B.工站代碼,
		sum(decode(A.單據類別, 'F11', A.贈品數量, 0)) 加工數量,
		sum(decode(A.單據類別, 'F21', A.贈品數量, 0)) 回廠數量,
		0 耗用數量,
		0 報廢數量,
		sum(decode(A.單據類別, 'F32', A.贈品數量, 0)) 調整數量,	
		sum(A.贈品數量 * decode(A.單據類別, 'F11', 1, 'F21', -1, 'F32', 1, -1)) 結存數量
	FROM 
		FIL0040 A
		/*特殊欄位*/
		INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
		INNER JOIN FIL0030 D ON A.單據類別 = D.單據類別 AND A.單據編號 = D.單據編號
		LEFT JOIN ViewOfObjProperties D1 on D.流水編號 = D1.單據流水號
		/*料號*/
		INNER JOIN FIL0012 E ON A.產品編號 = E.產品編號 AND E.產品類別 between 'M' and 'P'
		INNER JOIN FIL0041 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號 AND A.單據序號 = C.序號
		/*簽收*/
		INNER JOIN FIL0037 F ON A.單據類別 = F.製令單別 AND A.單據編號 = F.製令單號 AND F.材料序號=0 AND ((nvl(dbms_lob.getlength(F.圖檔),0) > 0) OR A.單據類別 = 'F32')
		/*填單日*/
		INNER JOIN ViewFILF013 H ON H.工站代碼=B.工站代碼 AND H.批號 = C.批號 AND DECODE(D1.送簽日時,NULL,D.填表日,D1.送簽日時) >= H.填表日
		INNER JOIN FIL1014 I ON I.代碼類別 = '工站代碼' AND B.工站代碼 = I.系統代碼
	WHERE
		A.單據類別 between 'F11' and 'F32' AND
		A.單據類別 != 'F31' AND 
		A.異動日期 >= I.日期	
	GROUP BY
		A.產品編號,
		B.製程代碼,
		B.工站代碼

	UNION ALL

	/*材料耗用.氣閥.鐵條*/
	/*批號1*/
	SELECT 
		D.料號,
		C.製程代碼,
		C.工站代碼,
		0 加工數量,
		0 回廠數量,
		sum(B.數值1) 耗用數量,
		0 報廢數量,
		0 調整數量,	
		sum(B.數值1* decode(A.單據類別, 'F11', 1, 'F21', -1, 'F32', 1, -1)) 結存數量
	FROM 
		FIL0040 A
		INNER JOIN FIL0041 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號 AND A.單據序號 = B.序號
		INNER JOIN FIL0031 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號
		INNER JOIN FIL0030 G ON A.單據類別 = G.單據類別 AND A.單據編號 = G.單據編號
		INNER JOIN ViewFIL1024 D ON B.文數字1 = D.條碼
		/*填單日*/
		INNER JOIN ViewFILF013 H ON H.工站代碼=C.工站代碼 AND H.批號=B.文數字1 AND G.填表日>= H.填表日	
		INNER JOIN FIL1014 I ON I.代碼類別 = '工站代碼' AND C.工站代碼 = I.系統代碼
	WHERE
		A.單據類別 = 'C41' AND
		A.異動類別 = 'A' AND
		C.製程代碼 between 'C31F' and 'C31G' AND
		D.料號 != ' ' AND 
		A.異動日期 >= I.日期
	GROUP BY
		D.料號,
		C.製程代碼,
		C.工站代碼

	UNION ALL

	/*材料耗用.氣閥.鐵條*/
	/*批號2*/
	SELECT 
		D.料號,
		C.製程代碼,
		C.工站代碼,
		0 加工數量,
		0 回廠數量,
		sum(B.數值2) 耗用數量,
		0 報廢數量,
		0 調整數量,	
		sum(B.數值2* decode(A.單據類別, 'F11', 1, 'F21', -1, 'F32', 1, -1)) 結存數量
	FROM 
		FIL0040 A
		INNER JOIN FIL0041 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號 AND A.單據序號 = B.序號
		INNER JOIN FIL0031 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號
		INNER JOIN FIL0030 G ON A.單據類別 = G.單據類別 AND A.單據編號 = G.單據編號
		INNER JOIN ViewFIL1024 D ON B.文數字2 = D.條碼
		/*填單日*/
		INNER JOIN ViewFILF013 H ON H.工站代碼=C.工站代碼 AND H.批號=B.文數字2 AND G.填表日 >= H.填表日	
		INNER JOIN FIL1014 I ON I.代碼類別 = '工站代碼' AND C.工站代碼 = I.系統代碼
	WHERE
		A.單據類別 = 'C41' AND
		A.異動類別 = 'A' AND
		C.製程代碼 between 'C31F' and 'C31G' AND
		D.料號 != ' ' AND 
		A.異動日期 >= I.日期	
	GROUP BY
		D.料號,
		C.製程代碼,
		C.工站代碼

	UNION ALL

	/*材料耗用.氣閥.鐵條*/
	/*報廢*/	
	SELECT 
		A.產品編號 料號,
		C.製程代碼,
		C.工站代碼,
		0 加工數量,
		0 回廠數量,
		0 耗用數量,
		sum(A.異動數量) 報廢數量,
		0 調整數量,	
		sum(A.異動數量 * decode(A.單據類別, 'F11', 1, 'F21', -1, 'F32', 1, -1)) 結存數量
	FROM 
		FIL0040 A
		INNER JOIN FIL0041 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號 AND A.單據序號 = B.序號
		INNER JOIN FIL0031 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號
		INNER JOIN FIL0030 G ON A.單據類別 = G.單據類別 AND A.單據編號 = G.單據編號
		LEFT JOIN ViewOfObjProperties D1 on G.流水編號 = D1.單據流水號
		/*填單日*/
		INNER JOIN ViewFILF013 H ON H.工站代碼=C.工站代碼 AND H.批號=B.批號 AND DECODE(D1.送簽日時,NULL,G.填表日,D1.送簽日時) >= H.填表日	
		INNER JOIN FIL1014 I ON I.代碼類別 = '工站代碼' AND C.工站代碼 = I.系統代碼
	WHERE
		A.單據類別 = 'C41' AND
		A.異動類別 = 'D' AND
		C.製程代碼 between 'C31F' and 'C31G' AND
		A.產品編號 != ' '	 AND 
		A.異動日期 >= I.日期
	GROUP BY 
		A.產品編號,
		C.製程代碼,
		C.工站代碼		
) A
GROUP BY
	A.料號,
	A.製程代碼,
	A.工站代碼
);

-- Oracle user_views
CREATE VIEW "VIEWFILF0W4B_1" ("料號", "製程代碼", "工站代碼", "加工數量", "回廠數量", "耗用數量", "報廢數量", "調整數量", "結存數量") AS (
SELECT 
	A.產品編號 料號,
	B.製程代碼,
	B.工站代碼,
	sum(decode(A.單據類別, 'F11', A.贈品數量, 0)) 加工數量,
	sum(decode(A.單據類別, 'F21', A.贈品數量, 0)) 回廠數量,
	0 耗用數量,
	0 報廢數量,
	sum(decode(A.單據類別, 'F32', A.贈品數量, 0)) 調整數量,	
	sum(A.贈品數量 * decode(A.單據類別, 'F11', 1, 'F21', -1, 'F32', 1, -1)) 結存數量
FROM 
	FIL0040 A
	/*特殊欄位*/
	INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
	INNER JOIN FIL0030 D ON A.單據類別 = D.單據類別 AND A.單據編號 = D.單據編號
	LEFT JOIN ViewOfObjProperties D1 on D.流水編號 = D1.單據流水號
	/*料號*/
	INNER JOIN FIL0012 E ON A.產品編號 = E.產品編號 AND E.產品類別 between 'M' and 'P'
	INNER JOIN FIL0041 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號 AND A.單據序號 = C.序號
	/*簽收*/
	INNER JOIN FIL0037 F ON A.單據類別 = F.製令單別 AND A.單據編號 = F.製令單號 AND F.材料序號=0 AND ((nvl(dbms_lob.getlength(F.圖檔),0) > 0) OR A.單據類別 = 'F32')
	/*填單日*/
	INNER JOIN ViewFILF013 H ON H.工站代碼=B.工站代碼 AND H.批號 = C.批號 AND DECODE(D1.送簽日時,NULL,D.填表日,D1.送簽日時) >= H.填表日
	INNER JOIN FIL1014 I ON I.代碼類別 = '工站代碼' AND B.工站代碼 = I.系統代碼
WHERE
	A.單據類別 between 'F11' and 'F32' AND
	A.單據類別 != 'F31' AND 
	A.異動日期 >= I.日期	
GROUP BY
	A.產品編號,
	B.製程代碼,
	B.工站代碼
);

-- Oracle user_views
CREATE VIEW "VIEWFILF0W4B_2" ("料號", "製程代碼", "工站代碼", "加工數量", "回廠數量", "耗用數量", "報廢數量", "調整數量", "結存數量") AS (
/*材料耗用.氣閥.鐵條*/
	/*批號1*/
SELECT 
	D.料號,
	C.製程代碼,
	C.工站代碼,
	0 加工數量,
	0 回廠數量,
	sum(B.數值1) 耗用數量,
	0 報廢數量,
	0 調整數量,	
	sum(B.數值1*-1) 結存數量
FROM 
	FIL0040 A
	INNER JOIN FIL0041 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號 AND A.單據序號 = B.序號
	INNER JOIN FIL0031 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號
	INNER JOIN FIL0030 G ON A.單據類別 = G.單據類別 AND A.單據編號 = G.單據編號	
	INNER JOIN ViewFIL1024 D ON B.文數字1 = D.條碼
	/*填單日*/
	INNER JOIN ViewFILF013 H ON H.工站代碼=C.工站代碼 AND H.批號=B.文數字1 AND G.填表日 >= H.填表日	
	INNER JOIN FIL1014 I ON I.代碼類別 = '工站代碼' AND C.工站代碼 = I.系統代碼
WHERE
	A.單據類別 = 'C41' AND
	A.異動類別 = 'A' AND
	C.製程代碼 between 'C31F' and 'C31G' AND
	B.文數字1 != ' ' AND 
	A.異動日期 >= I.日期	
GROUP BY
	D.料號,
	C.製程代碼,
	C.工站代碼
);

-- Oracle user_views
CREATE VIEW "VIEWFILF0W4B_3" ("料號", "製程代碼", "工站代碼", "加工數量", "回廠數量", "耗用數量", "報廢數量", "調整數量", "結存數量") AS (
/*材料耗用.氣閥.鐵條*/
	/*批號2*/
SELECT 
	D.料號,
	C.製程代碼,
	C.工站代碼,
	0 加工數量,
	0 回廠數量,
	sum(B.數值2) 耗用數量,
	0 報廢數量,
	0 調整數量,	
	sum(B.數值2*-1) 結存數量
FROM 
	FIL0040 A
	INNER JOIN FIL0041 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號 AND A.單據序號 = B.序號
	INNER JOIN FIL0031 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號
	INNER JOIN FIL0030 G ON A.單據類別 = G.單據類別 AND A.單據編號 = G.單據編號
	INNER JOIN ViewFIL1024 D ON B.文數字2 = D.條碼
	/*填單日*/
	INNER JOIN ViewFILF013 H ON H.工站代碼=C.工站代碼 AND H.批號=B.文數字2 AND G.填表日 >= H.填表日	
	INNER JOIN FIL1014 I ON I.代碼類別 = '工站代碼' AND C.工站代碼 = I.系統代碼
WHERE
	A.單據類別 = 'C41' AND
	A.異動類別 = 'A' AND
	C.製程代碼 between 'C31F' and 'C31G' AND
	B.文數字2 != ' '	 AND 
	A.異動日期 >= I.日期
GROUP BY
	D.料號,
	C.製程代碼,
	C.工站代碼
);

-- Oracle user_views
CREATE VIEW "VIEWFILF0W4B_4" ("料號", "製程代碼", "工站代碼", "加工數量", "回廠數量", "耗用數量", "報廢數量", "調整數量", "結存數量") AS (
/*材料耗用.氣閥.鐵條*/
/*報廢*/	
SELECT 
	A.產品編號 料號,
	C.製程代碼,
	C.工站代碼,
	0 加工數量,
	0 回廠數量,
	0 耗用數量,
	sum(A.異動數量) 報廢數量,
	0 調整數量,	
	sum(A.異動數量 * decode(A.單據類別, 'F11', 1, 'F21', -1, 'F32', 1, -1)) 結存數量
FROM 
	FIL0040 A
	INNER JOIN FIL0041 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號 AND A.單據序號 = B.序號
	INNER JOIN FIL0031 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號
	INNER JOIN FIL0030 G ON A.單據類別 = G.單據類別 AND A.單據編號 = G.單據編號
	LEFT JOIN ViewOfObjProperties D1 on G.流水編號 = D1.單據流水號
	/*填單日*/
	INNER JOIN ViewFILF013 H ON H.工站代碼=C.工站代碼 AND H.批號=B.批號 AND DECODE(D1.送簽日時,NULL,G.填表日,D1.送簽日時) >= H.填表日
	INNER JOIN FIL1014 I ON I.代碼類別 = '工站代碼' AND C.工站代碼 = I.系統代碼	
WHERE
	A.單據類別 = 'C41' AND
	A.異動類別 = 'D' AND
	C.製程代碼 between 'C31F' and 'C31G' AND
	A.產品編號 != ' '	 AND 
	A.異動日期 >= I.日期
GROUP BY 
	A.產品編號,
	C.製程代碼,
	C.工站代碼		
);

-- Oracle user_views
CREATE VIEW "VIEWFILF0W5" ("料號", "批號", "品名", "規格", "製程代碼", "製程名稱", "工站代碼", "工站名稱", "製程工站", "加工數量", "回廠數量", "耗用數量", "報廢數量", "調整數量", "結存數量") AS (
SELECT 
	nvl(A.料號,' ') 料號,
	nvl(A.批號,' ') 批號,
	E.品名,
	E.規格,
	nvl(A.製程代碼,' ') 製程代碼,
	G.製程名稱,
	nvl(A.工站代碼,' ') 工站代碼,
	G.名稱 工站名稱,
	G.製程工站,
	sum(decode(A.單別, 'F11', nvl(A.數量,0), 0)) 加工數量,
	sum(decode(A.單別, 'F21', nvl(A.數量,0), 0)) 回廠數量,
	sum(decode(A.單別, 'C41', (case when A.序號 <= 9500 then A.數量 else 0 end), 0)) 耗用數量,
	sum(decode(A.單別, 'C41', (case when A.序號 > 9500 then A.數量 else 0 end), 0)) 報廢數量,
	sum(decode(A.單別, 'F32', nvl(A.數量,0), 0)) 調整數量,	
	sum(A.數量 * decode(A.單別, 'F11', 1, 'F21', -1, 'F32', 1, -1)) 結存數量
FROM 
	ViewFILF0W3A A
		/*料號*/
	INNER JOIN FIL0012 E ON A.料號 = E.產品編號
	/*工站*/
	INNER JOIN ViewFIL310O G ON A.工站代碼 = G.代碼
GROUP BY
	A.料號,
	A.批號,
	E.品名,
	E.規格,
	A.製程代碼,
	G.製程名稱,
	A.工站代碼,
	G.名稱,
	G.製程工站);

-- Oracle user_views
CREATE VIEW "VIEWFILF0W5A" ("料號", "批號", "品名", "規格", "製程代碼", "製程名稱", "工站代碼", "工站名稱", "製程工站", "加工數量", "回廠數量", "耗用數量", "報廢數量", "調整數量", "結存數量") AS (
SELECT 
	A.料號,
	A.批號,
	E.品名,
	E.規格,
	A.製程代碼,
	G.製程名稱,
	A.工站代碼,
	G.名稱 工站名稱,
	G.製程工站,
	sum(decode(A.單別, 'F11', nvl(A.數量,0), 0)) 加工數量,
	sum(decode(A.單別, 'F21', nvl(A.數量,0), 0)) 回廠數量,
	sum(decode(A.單別, 'C41', (case when A.序號 <= 9500 then A.數量 else 0 end), 0)) 耗用數量,
	sum(decode(A.單別, 'C41', (case when A.序號 > 9500 then A.數量 else 0 end), 0)) 報廢數量,
	sum(decode(A.單別, 'F32', nvl(A.數量,0), 0)) 調整數量,	
	sum(A.數量 * decode(A.單別, 'F11', 1, 'F21', -1, 'F32', 1, -1)) 結存數量
FROM 
	ViewFILF0W3B A
	/*料號*/
	INNER JOIN FIL0012 E ON A.料號 = E.產品編號
	/*工站*/
	INNER JOIN ViewFIL310O G ON A.工站代碼 = G.代碼
	
GROUP BY
	A.料號,
	A.批號,
	E.品名,
	E.規格,
	A.製程代碼,
	G.製程名稱,
	A.工站代碼,
	G.名稱,
	G.製程工站
	);

-- Oracle user_views
CREATE VIEW "VIEWFILF0W6" ("料號", "批號", "品名", "規格", "加工數量", "回廠數量", "耗用數量", "調整數量", "結存數量") AS (
SELECT 
	A.料號,
	A.批號,
	A.品名,
	A.規格,
	sum(decode(A.單別, 'F11', A.數量, 0)) 加工數量,
	sum(decode(A.單別, 'F21', A.數量, 0)) 回廠數量,
	sum(decode(A.單別, 'C41', A.數量, 0)) 耗用數量,
	sum(decode(A.單別, 'F32', A.數量, 0)) 調整數量,	
	sum(A.數量 * A.庫存參數) 結存數量
FROM 
	ViewFILF0W3 A
GROUP BY
	A.料號,
	A.批號,
	A.品名,
	A.規格);

-- Oracle user_views
CREATE VIEW "VIEWFILH001" ("單別", "單號", "單據日期", "主旨", "填寫人", "填寫人姓名", "申請人", "申請人姓名", "填寫日期", "假別", "假別名稱", "請假假別", "請假假別名稱", "起始日期", "起始時間", "截止日期", "截止時間", "天數", "時數", "請假時數", "代理人", "代理人姓名", "部門編號", "部門名稱", "簽核狀態", "簽核排序", "簽核系統", "每日時數合計", "流水編號", "請假事由", "最後更新者", "更新者姓名", "員工流水編號", "最後更新日") AS (
SELECT
	'H01' 單別,
	A.單號,
	B.單據日期,
	A.單號||'('||'H01'||')' 主旨,
	A.填寫人,
	nvl(C.員工姓名, ' ') 填寫人姓名,
	A.申請人,
	nvl(F.員工姓名, ' ') 申請人姓名,
	A.填寫日期,
	A.假別,
	nvl(D.名稱, ' ') 假別名稱,
	decode(A.請假假別,' ',A.假別,A.請假假別) 請假假別,
	nvl(decode(A.請假假別,' ',D.名稱,D1.名稱), ' ') 請假假別名稱,
	A.起始日期,
	A.起始時間,
	A.截止日期,
	A.截止時間,
	A.天數,
	A.時數,
	(A.天數*8+A.時數) 請假時數,
	A.代理人,
	nvl(E.員工姓名, ' ') 代理人姓名,
	B.部門編號,
	nvl(Z3.GUName, ' ') 部門名稱,
	nvl(Z2.簽核狀態, '0') 簽核狀態,
	decode(nvl(Z2.簽核狀態, ' '),' ',' ','0',' ','I','1','D','2','E','3','A','Z',' ') 簽核排序,
	B.簽核系統,
	nvl(G.每日時數合計,0) 每日時數合計,
	A.流水編號,
	A.請假事由,
	B.最後更新者,
	nvl(Z1.員工姓名, ' ') 更新者姓名,
	nvl(C.Serial_Num,' ') 員工流水編號, 
	B.最後更新日
FROM
	HRFIL1031 A
	INNER JOIN FIL0030 B ON A.流水編號 = B.流水編號
	LEFT JOIN FIL0010 C ON A.填寫人 = C.員工編號
	LEFT JOIN ViewFIL3801 D ON A.假別 = D.代碼
	LEFT JOIN ViewFIL3801 D1 ON A.請假假別 = D1.代碼
	LEFT JOIN FIL0010 E ON A.代理人 = E.員工編號
	LEFT JOIN FIL0010 F ON A.申請人 = F.員工編號
	LEFT JOIN FIL0010 Z1 ON B.最後更新者 = Z1.員工編號
	LEFT JOIN ViewOfObjProperties Z2 ON A.流水編號 = Z2.單據流水號
	LEFT JOIN A30 Z3 ON B.部門編號 = Z3.GroupID
	LEFT JOIN 
	(SELECT 
		A.單據類別,
		A.單據編號,
		SUM(A.異動數量) 每日時數合計
	 FROM
		FIL0040 A
	 WHERE 
		A.單據類別 = 'H01'
	 GROUP BY 
		A.單據類別,
		A.單據編號
	) G ON G.單據類別 = A.單別 AND G.單據編號 = A.單號	
WHERE
	B.單據類別 = 'H01'
	);

-- Oracle user_views
CREATE VIEW "VIEWFILH002" ("單別", "單號", "單據日期", "主旨", "類別", "填寫人", "填寫人姓名", "申請人", "申請人姓名", "填寫日期", "年度", "應休天數", "生效日期", "一月", "二月", "三月", "四月", "五月", "六月", "七月", "八月", "九月", "十月", "十一月", "十二月", "合計", "部門編號", "部門名稱", "簽核狀態", "簽核系統", "流水編號", "事由", "最後更新者", "更新者姓名", "員工流水編號", "最後更新日") AS (
SELECT
	'H02' 單別,
	A.單號,
	B.單據日期,
	A.單號||'('||'H02'||')' 主旨,
	DECODE(B.稅別,'T',1,0) 類別,
	A.填寫人,
	nvl(C.員工姓名, ' ') 填寫人姓名,
	A.申請人,
	nvl(D.員工姓名, ' ') 申請人姓名,
	A.填寫日期,
	A.年度,
	A.應休天數,
	A.生效日期,
	A.一月,
	A.二月,
	A.三月,
	A.四月,
	A.五月,
	A.六月,
	A.七月,
	A.八月,
	A.九月,
	A.十月,
	A.十一月,
	A.十二月,
	A.一月+	A.二月+	A.三月+	A.四月+ A.五月+	A.六月+	A.七月+	A.八月+	A.九月+	A.十月+	A.十一月+ A.十二月 合計,
	B.部門編號,
	nvl(Z3.GUName, ' ') 部門名稱,
	nvl(Z2.簽核狀態, '0') 簽核狀態,
	B.簽核系統,
	A.流水編號,
	A.事由,
	B.最後更新者,
	nvl(Z1.員工姓名, ' ') 更新者姓名,
	nvl(C.Serial_Num,' ') 員工流水編號, 
	B.最後更新日
FROM
	HRFIL1032 A
	INNER JOIN FIL0030 B ON A.流水編號 = B.流水編號
	LEFT JOIN FIL0010 C ON A.填寫人 = C.員工編號
	LEFT JOIN FIL0010 D ON A.申請人 = D.員工編號
	LEFT JOIN FIL0010 Z1 ON B.最後更新者 = Z1.員工編號
	LEFT JOIN ViewOfObjProperties Z2 ON A.流水編號 = Z2.單據流水號
	LEFT JOIN A30 Z3 ON B.部門編號 = Z3.GroupID
	);

-- Oracle user_views
CREATE VIEW "VIEWFILH003" ("申請人", "年度", "單號", "一月", "二月", "三月", "四月", "五月", "六月", "七月", "八月", "九月", "十月", "十一月", "十二月", "合計") AS (
SELECT
	A.申請人,
	A.年度,
	A.單號,
	B.一月,
	B.二月,
	B.三月,
	B.四月,
	B.五月,
	B.六月,
	B.七月,
	B.八月,
	B.九月,
	B.十月,
	B.十一月,
	B.十二月,
	B.一月+	B.二月+	B.三月+	B.四月+ B.五月+	B.六月+	B.七月+	B.八月+	B.九月+	B.十月+	B.十一月+ B.十二月 合計
FROM
	(
		SELECT A.申請人,A.年度,A.單號
		FROM (
			SELECT A.*,
				   ROW_NUMBER() OVER (PARTITION BY A.申請人,A.年度 ORDER BY A.生效日期 DESC) AS rn
			FROM HRFIL1032 A
			WHERE A.單號 <> ' '
		) A
		WHERE rn = 1
	) A
	INNER JOIN HRFIL1032 B ON A.單號 = B.單號);

-- Oracle user_views
CREATE VIEW "VIEWFILH004" ("單別", "單號", "主旨", "公司代碼", "公司名稱", "加班日期", "計薪日期", "部門編號", "部門名稱", "簽核系統", "簽核狀態", "簽核排序", "備註", "流水編號", "填表人", "填表人姓名", "填表人職稱", "填表日", "最後更新者", "更新者姓名", "員工流水編號", "最後更新日") AS (
SELECT
	A.單據類別 單別,
	A.單據編號 單號,
	A.單據編號||'('||A.單據類別||')' 主旨,
	A.公司代碼,
	nvl(E.全名, ' ') 公司名稱,
	A.單據日期 加班日期,
	'000000' 計薪日期,
	A.部門編號,
	nvl(B.GUName, ' ') 部門名稱,
	A.簽核系統, 
	nvl(Z3.簽核狀態, '0') 簽核狀態,
	decode(nvl(Z3.簽核狀態, ' '),' ',' .未送簽','I','1.簽核中','D','2.退回','A','3.作廢','E','9.已簽',' .草稿') 簽核排序,
	A.備註, 
	A.流水編號,
	A.填表人,
	nvl(Z1.員工姓名,' ') 填表人姓名, 
	NVL(Z4.GUNAME,' ') 填表人職稱,
	A.填表日, 
	A.最後更新者,
	nvl(Z2.員工姓名,' ') 更新者姓名,
	nvl(Z1.Serial_Num,' ') 員工流水編號, 	
	A.最後更新日
FROM
	FIL0030 A
	LEFT JOIN A30 B ON A.部門編號 = B.GroupID
	LEFT JOIN ViewFIL0011 E ON A.公司代碼 = E.代碼
	LEFT JOIN ViewFIL0030 F ON A.簽核系統 = F.簽核系統 AND A.單據編號 = F.單號
	LEFT JOIN FIL0010 Z1 ON A.填表人 = Z1.員工編號
	LEFT JOIN FIL0010 Z2 ON A.最後更新者 = Z2.員工編號
	LEFT JOIN ViewOfObjProperties Z3 ON A.流水編號 = Z3.單據流水號
	LEFT JOIN A40 Z4 ON Z1.FLOWPOSI = Z4.Serial_Num
WHERE
	A.單據類別 = 'H03');

-- Oracle user_views
CREATE VIEW "VIEWFILH005" ("單別", "單號", "序號", "申請人", "加班日期", "申請人姓名", "部門編號", "部門名稱", "工作內容", "數量", "單位代碼", "單位名稱", "時間起", "時間訖", "休息起1", "休息迄1", "休息起2", "休息迄2", "時數", "休息1", "休息2", "小計", "計件", "調補", "教育", "計時", "備註", "流水編號", "最後更新者", "更新者姓名", "最後更新日", "簽核狀態") AS (
SELECT 
	A.單據類別 單別, 
	A.單據編號 單號,
	A.單據序號 序號,
	A.產品編號 申請人,
	decode(A.異動日期,'00000000',B.單據日期,A.異動日期) 加班日期,
	nvl(E.員工姓名, ' ') 申請人姓名,
	nvl(E.部門編號, ' ') 部門編號,
	nvl(F.GUName, ' ') 部門名稱,
	NVL(G.工作內容,' ') 工作內容,
	A.異動數量 數量,
	A.單位代碼,
	nvl(D.名稱, ' ') 單位名稱,
	C.TIME1 時間起,
	C.TIME2 時間訖,
	C.TIME3 休息起1,
	C.TIME4 休息迄1,
	C.TIME5 休息起2,
	C.TIME6 休息迄2,
	A.贈品數量 時數,
	A.異動單價 休息1,
	A.異動金額 休息2,
	A.贈品數量-A.異動單價 -A.異動金額 小計,
	A.Logical1 計件, 
	A.Logical2 調補,
	A.Logical3 教育,
	A.Logical4 計時,
	A.備註說明 備註,
	A.流水編號,
	A.最後更新者,
	NVL(Z1.員工姓名,' ') 更新者姓名,
	A.最後更新日,
	nvl(Z3.簽核狀態,' ') 簽核狀態
FROM 
	FIL0040 A
	/*特殊欄位*/
	INNER JOIN FIL0030 B ON A.單據類別 = B.單據類別 AND A.單據編號 = B.單據編號
	INNER JOIN FIL0041 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號 AND A.單據序號 = C.序號
	LEFT JOIN ViewFIL3103 D ON A.單位代碼 = D.代碼
	LEFT JOIN FIL0010 E ON A.產品編號 = E.員工編號
	LEFT JOIN A30 F ON E.部門編號 = F.GroupID
	LEFT JOIN FIL0010 Z1 ON A.最後更新者 = Z1.員工編號
	LEFT JOIN ViewOfObjProperties Z3 ON B.流水編號 = Z3.單據流水號
	LEFT JOIN 
	(
		select
			A.製令單別,
			A.製令單號,
			A.材料序號 序號,
			utl_raw.cast_to_nvarchar2(listagg(utl_raw.cast_to_raw(A.備註||(case when A.相關單號<>' ' then '|'||A.相關單號 end)||'/')||utl_raw.cast_to_raw(TO_NCHAR(ROUND(A.數字一)))||utl_raw.cast_to_raw(nvl(B.名稱, ' ')), utl_raw.cast_to_raw(N'　')) within group (order by A.製令單別,A.製令單號,A.材料序號,A.序號)) as 工作內容
		from 
			FIL0037 A
			LEFT JOIN ViewFIL3103 B ON A.代碼 = B.代碼
		WHERE 
			A.製令單別 = 'H03'	
		group by 
			A.製令單別,
			A.製令單號,
			A.材料序號
	) G ON A.單據類別 = G.製令單別 AND 	A.單據編號 = G.製令單號 AND A.單據序號 = G.序號
WHERE
	A.單據類別 = 'H03');

-- Oracle user_views
CREATE VIEW "VIEWFILH005A" ("申請人", "加班日期", "調補", "小計") AS (
SELECT 
	A.產品編號 申請人,
	decode(A.異動日期,'00000000',B.單據日期,A.異動日期) 加班日期,
	A.Logical2 調補,
	SUM(A.贈品數量-A.異動單價 -A.異動金額) 小計
FROM 
	FIL0040 A
	/*特殊欄位*/
	INNER JOIN FIL0030 B ON A.單據類別 = B.單據類別 AND A.單據編號 = B.單據編號
	LEFT JOIN ViewOfObjProperties Z3 ON B.流水編號 = Z3.單據流水號
WHERE
	A.單據類別 = 'H03' AND Z3.簽核狀態='E' AND A.Logical1=0
GROUP BY 
	A.產品編號,
	decode(A.異動日期,'00000000',B.單據日期,A.異動日期),
	A.Logical2
	);

-- Oracle user_views
CREATE VIEW "VIEWFILH005B" ("申請人", "加班日期", "調補", "教育", "小計") AS (
SELECT 
	A.產品編號 申請人,
	decode(A.異動日期,'00000000',B.單據日期,A.異動日期) 加班日期,
	A.Logical2 調補,
	A.Logical3 教育,
	SUM(A.贈品數量-A.異動單價 -A.異動金額) 小計
FROM 
	FIL0040 A
	/*特殊欄位*/
	INNER JOIN FIL0030 B ON A.單據類別 = B.單據類別 AND A.單據編號 = B.單據編號
	LEFT JOIN ViewOfObjProperties Z3 ON B.流水編號 = Z3.單據流水號
WHERE
	A.單據類別 = 'H03' AND Z3.簽核狀態='E' AND A.Logical1=0
GROUP BY 
	A.產品編號,
	decode(A.異動日期,'00000000',B.單據日期,A.異動日期),
	A.Logical2,
	A.Logical3
	);

-- Oracle user_views
CREATE VIEW "VIEWFILH005C" ("單別", "單號", "序號", "氣閥日報", "氣閥產量", "申請人代號", "申請人姓名", "加班日期", "單據加班時數", "製令單號") AS WITH Tmp1 AS (
select
	A.製令單別 單別,
	A.製令單號 單號,
	A.材料序號 序號,
	A.相關單號 氣閥日報,
	SUM(A.數字一) 氣閥產量
from 
	FIL0037 A
	inner join FIL0031 B ON B.單別 = A.相關單別 AND B.單號 = A.相關單號
WHERE 
	A.製令單別 = 'H03' and
	A.屬性 = '4'	and
	A.相關單別 = 'C41' and
	B.製程代碼 = 'C31F'
group by 
	A.製令單別,
	A.製令單號,
	A.材料序號,
	A.相關單號
),
Tmp2 AS (
SELECT 
	A1.單據類別 單別, 
	A1.單據編號 單號,
	A1.單據序號 序號,
	A1.產品編號 申請人代號,
	decode(A1.異動日期,'00000000',B1.單據日期,A1.異動日期) 加班日期,
	nvl(E1.員工姓名, ' ') 申請人姓名,
	A1.贈品數量-A1.異動單價 -A1.異動金額 單據加班時數
FROM 
	FIL0040 A1
	/*特殊欄位*/
	INNER JOIN FIL0030 B1 ON A1.單據類別 = B1.單據類別 AND A1.單據編號 = B1.單據編號
	LEFT JOIN FIL0010 E1 ON A1.產品編號 = E1.員工編號
WHERE
	A1.單據類別 = 'H03'
)
SELECT 
	A.單別,
	A.單號,
	A.序號,
	A.氣閥日報,
	A.氣閥產量,
	B.申請人代號,
	B.申請人姓名,
	B.加班日期,
	B.單據加班時數,
	C.歸屬編號 製令單號
FROM
	Tmp1 A
	INNER JOIN Tmp2 B on A.單別=B.單別 AND A.單號=B.單號 AND A.序號=B.序號
	INNER JOIN FIL0030 C ON C.單據類別='C41' AND C.單據編號 = A.氣閥日報;

-- Oracle user_views
CREATE VIEW "VIEWFILH006" ("單別", "單號", "數量", "時數", "申請人") AS (
SELECT
	A.單據類別 單別,
	A.單據編號 單號,
	NVL(M.數量,0) 數量,
	nvl(M.時數,0) 時數,
	nvl(M.申請人,' ') 申請人
FROM
	FIL0030 A	
	LEFT JOIN 
	(SELECT 
		A.單據類別 單別, 
		A.單據編號 單號,
		sum(A.異動數量) 數量,
		sum(A.贈品數量) 時數,
		utl_raw.cast_to_nvarchar2(listagg(utl_raw.cast_to_raw(B.員工姓名||'[')||utl_raw.cast_to_raw(trim(TO_NCHAR(ROUND(A.贈品數量-A.異動單價 -A.異動金額,1),'90D9')))||utl_raw.cast_to_raw(N'小時]'),utl_raw.cast_to_raw(N',')) within group (order by A.單據類別,A.單據編號)) 申請人
	FROM 
		FIL0040 A
		Left Join FIL0010 B on A.產品編號 = B.員工編號
	WHERE
		A.單據類別 = 'H03'
	GROUP BY
		A.單據類別,
		A.單據編號) M 
	ON M.單別=A.單據類別 and M.單號=A.單據編號
WHERE
		A.單據類別 = 'H03'	
	);

-- Oracle user_views
CREATE VIEW "VIEWFILH006A" ("申請人", "加班日期", "筆數") AS (
SELECT 
	A.產品編號 申請人,
	decode(A.異動日期,'00000000',B.單據日期,A.異動日期) 加班日期,
	count(A.單據序號) 筆數
FROM 
	FIL0040 A
	/*特殊欄位*/
	INNER JOIN FIL0030 B ON A.單據類別 = B.單據類別 AND A.單據編號 = B.單據編號
	INNER JOIN FIL0041 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號 AND A.單據序號 = C.序號
WHERE
	A.單據類別 = 'H03' AND 
	A.產品編號 <> ' '
GROUP BY 
	A.產品編號,
	decode(A.異動日期,'00000000',B.單據日期,A.異動日期)
	);

-- Oracle user_views
CREATE VIEW "VIEWFILH007" ("員工編號", "員工姓名", "公司別", "部門名稱", "職位名稱", "生產部門禁", "出勤日期", "遲到", "早退", "假別", "上班刷卡", "下班刷卡", "夜班", "大夜", "平日打卡日", "假日打卡日", "打卡日調整", "門禁上班刷卡", "門禁下班刷卡", "門禁中午進", "門禁中午出", "門禁午休時間", "班別", "班別時間起", "班別時間迄", "平日前2小時", "平日前4小時", "平日大於4小時", "休息日前2小時", "休息日前8小時", "休息日大於8小時", "例假日前8小時", "例假日大於8小時", "例假日大於10小時", "例假日補休小時", "國定假日前8小時", "國定假日大於8小時", "國定假日大於10小時", "調補時數", "已手動修正", "星期代碼", "星期說明", "星期幾", "流水編號", "最後更新者", "最後更新日") AS (
SELECT 
	A.員工編號,
	B.員工姓名,
	B.公司別,
	B.部門名稱,
	B.職位名稱,
	B.生產部門禁,
	A.出勤日期,
	(CASE WHEN NVL(F.休假,0) <=1 AND NVL(E.請假時數,0)=0 then A.遲到 else 0 end) 遲到,
	(CASE WHEN NVL(F.休假,0) <=1 AND NVL(E.請假時數,0)=0 then A.早退 else 0 end) 早退,
	C.假別,
	A.上班刷卡,
	A.下班刷卡,
	(case when (A.班別 ='4' or A.班別= '5'  or A.班別= '7') AND A.上班刷卡<>'000000' AND A.下班刷卡 between '013000' and '032959' then 1 
		  else 0 
	end) 夜班,
	(case when (A.班別 ='4' or A.班別= '5'  or A.班別= '7') AND A.上班刷卡<>'000000' AND A.下班刷卡 between '033000' and A.班別時間起 then 1 
		  else 0 
	end) 大夜,	
	(CASE WHEN NVL(F.休假,0) <=1 AND NVL(E.請假時數,0) <= 2 THEN decode(to_number(A.上班刷卡,'999999')+to_number(A.下班刷卡,'999999'),0,0,1)
			  WHEN NVL(F.休假,0) <=1 AND NVL(E.請假時數,0) BETWEEN 2.01 AND 4 THEN decode(to_number(A.上班刷卡,'999999')+to_number(A.下班刷卡,'999999'),0,0,0.5)
			  ELSE 0 END) 平日打卡日,
	(CASE WHEN NVL(F.休假,0) > 1 AND D.加班時數 >= 6  THEN decode(to_number(A.上班刷卡,'999999')+to_number(A.下班刷卡,'999999'),0,0,1)
			  WHEN NVL(F.休假,0) > 1 AND D.加班時數 BETWEEN 4 AND 5.99 THEN decode(to_number(A.上班刷卡,'999999')+to_number(A.下班刷卡,'999999'),0,0,0.5)
			  ELSE 0 END) 假日打卡日,
	A.打卡日調整,		
	decode(A.門禁計薪上班,'000000',A.門禁上班刷卡,A.門禁計薪上班) 門禁上班刷卡,
	decode(A.門禁計薪下班,'000000',A.門禁下班刷卡,A.門禁計薪下班) 門禁下班刷卡,
	A.修正午晚進 門禁中午進,
	A.修正午晚出 門禁中午出,
	A.門禁午休時間,
	A.班別,
	A.班別時間起,
	A.班別時間迄,
	NVL(D.平日前2小時,0) 平日前2小時,
	NVL(D.平日前4小時,0) 平日前4小時,
	NVL(D.平日大於4小時,0) 平日大於4小時,
	NVL(D.休息日前2小時,0) 休息日前2小時,
	NVL(D.休息日前8小時,0) 休息日前8小時,
	NVL(D.休息日大於8小時,0) 休息日大於8小時,
	NVL(D.例假日前8小時,0) 例假日前8小時,
	NVL(D.例假日大於8小時,0) 例假日大於8小時,
	NVL(D.例假日大於10小時,0) 例假日大於10小時,
	NVL(D.例假日補休小時,0) 例假日補休小時,
	NVL(D.國定假日前8小時,0) 國定假日前8小時,
	NVL(D.國定假日大於8小時,0) 國定假日大於8小時,
	NVL(D.國定假日大於10小時,0) 國定假日大於10小時,
	NVL(D.調補時數,0) 調補時數,
	A.已手動修正,
	F.休假 星期代碼,
	F.說明 星期說明,
	F.星期 星期幾,
	A.流水編號,
	A.最後更新者,
	A.最後更新日
FROM
	HRFIL1007 A
	INNER JOIN VIEWFIL1010 B ON B.員工編號 = A.員工編號 AND B.國籍<>'委外'
	LEFT JOIN 
	(SELECT
		A.申請人,
		M.異動日期 起始日期,
		utl_raw.cast_to_nvarchar2(listagg(utl_raw.cast_to_raw(A.假別名稱||substr(M.Time1,1,2)||':'||substr(M.Time1,3,2)||'[')||utl_raw.cast_to_raw(TO_NCHAR(ROUND(M.異動數量,1),'90D9'))||utl_raw.cast_to_raw(N'小時]'), utl_raw.cast_to_raw(N' ')) within group (order by A.申請人)) as 假別
	 FROM
		FIL0040 M
		INNER JOIN ViewFilH001 A ON A.單別 = M.單據類別 AND A.單號 = M.單據編號
	 WHERE 
		M.單據類別 = 'H01' AND
		A.簽核狀態 = 'E' 
	 GROUP BY 
		A.申請人,
		M.異動日期
	) C ON C.申請人 = A.員工編號 AND A.出勤日期 = C.起始日期 
	LEFT JOIN 
	(
	 SELECT 
		A.申請人,
		A.加班日期 加班日期,
		/*平日、補班*/
		SUM(NVL(CASE WHEN NVL(C.休假,0)<=1 AND A.調補=0 THEN (CASE WHEN A.小計>=2 THEN 2 ELSE A.小計 END) ELSE 0 END ,0)) 平日前2小時,
		SUM(NVL(CASE WHEN NVL(C.休假,0)<=1 AND A.調補=0 THEN (CASE WHEN A.小計>2 AND A.小計<4 THEN A.小計-2 WHEN A.小計>=4 THEN 2 ELSE 0 END) ELSE 0 END ,0)) 平日前4小時,
		SUM(NVL(CASE WHEN NVL(C.休假,0)<=1 AND A.調補=0 THEN (CASE WHEN A.小計>4 THEN A.小計-4 ELSE 0 END) ELSE 0 END,0)) 平日大於4小時,
		/*休息日*/
		SUM(NVL(CASE WHEN NVL(C.休假,0)=2 AND A.調補=0 THEN (CASE WHEN A.小計>=2 THEN 2 ELSE A.小計 END) ELSE 0 END ,0)) 休息日前2小時,
		SUM(NVL(CASE WHEN NVL(C.休假,0)=2 AND A.調補=0 THEN (CASE WHEN A.小計>2 AND A.小計<8 THEN A.小計-2 WHEN A.小計>=8 THEN 6 ELSE 0 END) ELSE 0 END ,0)) 休息日前8小時,
		SUM(NVL(CASE WHEN NVL(C.休假,0)=2 AND A.調補=0 THEN (CASE WHEN A.小計>8 THEN A.小計-8 ELSE 0 END) ELSE 0 END ,0)) 休息日大於8小時,
		/*例假日*/
		SUM(NVL(CASE WHEN NVL(C.休假,0)=3 AND A.調補=0 THEN (CASE WHEN A.小計>0 THEN (case when A.小計>8 then 8 else A.小計 end) ELSE 0 END) ELSE 0 END ,0)) 例假日前8小時,
		SUM(NVL(CASE WHEN NVL(C.休假,0)=3 AND A.調補=0 THEN (CASE WHEN A.小計>8 AND A.小計<10 THEN A.小計-8 WHEN A.小計>=10 THEN 2 ELSE 0 END) ELSE 0 END ,0)) 例假日大於8小時,
		SUM(NVL(CASE WHEN NVL(C.休假,0)=3 AND A.調補=0 THEN (CASE WHEN A.小計>10 THEN A.小計-10 ELSE 0 END) ELSE 0 END ,0)) 例假日大於10小時,
		SUM(NVL(CASE WHEN NVL(C.休假,0)=3 AND A.調補=0 THEN (CASE WHEN A.小計>8 THEN 8 ELSE A.小計 END) ELSE 0 END ,0)) 例假日補休小時,
		/*國定假日*/
		SUM(NVL(CASE WHEN NVL(C.休假,0)=4 AND A.調補=0 THEN (CASE WHEN A.小計>0 THEN (case when A.小計>8 then 8 else A.小計 end) ELSE 0 END) ELSE 0 END ,0)) 國定假日前8小時,
		SUM(NVL(CASE WHEN NVL(C.休假,0)=4 AND A.調補=0 THEN (CASE WHEN A.小計>8 AND A.小計<10 THEN A.小計-8 WHEN A.小計>=10 THEN 2 ELSE 0 END) ELSE 0 END ,0)) 國定假日大於8小時,
		SUM(NVL(CASE WHEN NVL(C.休假,0)=4 AND A.調補=0 THEN (CASE WHEN A.小計>10 THEN A.小計-10 ELSE 0 END) ELSE 0 END ,0)) 國定假日大於10小時,
		/*調補*/
		SUM(NVL(CASE WHEN A.調補=1 THEN A.小計 ELSE 0 END,0)) 調補時數,
		SUM(NVL(A.小計,0)) 加班時數
	 FROM
		VIEWFILH005A A
		LEFT JOIN ViewFIL3805 C ON A.加班日期 = C.日期
	 GROUP BY 
		A.申請人,
		A.加班日期
	) D ON A.員工編號 = D.申請人 AND D.加班日期 = A.出勤日期
	LEFT JOIN ViewFILH012 E ON E.申請人 = A.員工編號 AND E.異動日期 = A.出勤日期
	LEFT JOIN ViewFIL3805 F ON A.出勤日期 = F.日期
);

-- Oracle user_views
CREATE VIEW "VIEWFILH008" ("員工編號", "出勤年月", "遲到", "早退", "夜班", "大夜", "平日前2小時", "平日前4小時", "平日大於4小時", "休息日前2小時", "休息日前8小時", "休息日大於8小時", "例假日前8小時", "例假日大於8小時", "例假日大於10小時", "例假日補休小時", "國定假日前8小時", "國定假日大於8小時", "國定假日大於10小時", "平日打卡日", "假日打卡日", "調補時數", "打卡日調整") AS (
SELECT 
	A.員工編號,
	substr(A.出勤日期,1,6) 出勤年月,
	sum(case when NVL(F.休假,0) <=1 and NVL(E.請假時數,0)=0 and A.遲到-5 > 0 then 1 else 0 end) 遲到,
	sum(case when NVL(F.休假,0) <=1 and NVL(E.請假時數,0)=0 and A.早退 > 0 then 1 else 0 end ) 早退,
	sum((case when (A.班別 ='4' or A.班別= '5'  or A.班別= '7') AND A.上班刷卡<>'000000' AND A.下班刷卡 between '013000' and '032959' then 1 
		  else 0 
	end)) 夜班,
	sum((case when (A.班別 ='4' or A.班別= '5'  or A.班別= '7') AND A.上班刷卡<>'000000' AND A.下班刷卡 between '033000' and A.班別時間起 then 1 
		  else 0 
	end)) 大夜,	
	sum(NVL(D.平日前2小時,0)) 平日前2小時,
	sum(NVL(D.平日前4小時,0)) 平日前4小時,
	sum(NVL(D.平日大於4小時,0)) 平日大於4小時,
	sum(NVL(D.休息日前2小時,0)) 休息日前2小時,
	sum(NVL(D.休息日前8小時,0)) 休息日前8小時,
	sum(NVL(D.休息日大於8小時,0)) 休息日大於8小時,
	sum(NVL(D.例假日前8小時,0)) 例假日前8小時,
	sum(NVL(D.例假日大於8小時,0)) 例假日大於8小時,
	sum(NVL(D.例假日大於10小時,0)) 例假日大於10小時,
	sum(NVL(D.例假日補休小時,0)) 例假日補休小時,
	sum(NVL(D.國定假日前8小時,0)) 國定假日前8小時,
	sum(NVL(D.國定假日大於8小時,0)) 國定假日大於8小時,
	sum(NVL(D.國定假日大於10小時,0)) 國定假日大於10小時,
	sum((CASE WHEN NVL(F.休假,0) <=1 AND NVL(E.請假時數,0) <= 2 THEN decode(to_number(A.上班刷卡,'999999')+to_number(A.下班刷卡,'999999'),0,0,1)
			  WHEN NVL(F.休假,0) <=1 AND NVL(E.請假時數,0) BETWEEN 2.01 AND 4 THEN decode(to_number(A.上班刷卡,'999999')+to_number(A.下班刷卡,'999999'),0,0,0.5)
			  ELSE 0 END)
		) 平日打卡日,
	sum((CASE WHEN NVL(F.休假,0) > 1 AND D.加班時數 >= 6  THEN decode(to_number(A.上班刷卡,'999999')+to_number(A.下班刷卡,'999999'),0,0,1)
			  WHEN NVL(F.休假,0) > 1 AND D.加班時數 BETWEEN 4 AND 5.99 THEN decode(to_number(A.上班刷卡,'999999')+to_number(A.下班刷卡,'999999'),0,0,0.5)
			  ELSE 0 END)
		) 假日打卡日,	
	sum(nvl(D.調補時數,0)) 調補時數,
	sum(A.打卡日調整)	打卡日調整
FROM
	HRFIL1007 A
	INNER JOIN VIEWFIL1010 B ON B.員工編號 = A.員工編號 AND B.國籍<>'委外'
	LEFT JOIN 
	(SELECT
		A.申請人,
		A.起始日期,
		A.截止日期,
		utl_raw.cast_to_nvarchar2(listagg(utl_raw.cast_to_raw(A.假別名稱||'[')||utl_raw.cast_to_raw(TO_NCHAR(ROUND(A.天數)))||utl_raw.cast_to_raw(N'天')||utl_raw.cast_to_raw(TO_NCHAR(ROUND(A.時數)))||utl_raw.cast_to_raw(N'小時]'), utl_raw.cast_to_raw(N' ')) within group (order by A.申請人)) as 假別
	 FROM
		VIEWFILH001 A
	 WHERE A.簽核狀態 = 'E'	
	 GROUP BY 
		A.申請人,
		A.起始日期,
		A.截止日期
	) C ON C.申請人 = A.員工編號 AND A.出勤日期 BETWEEN C.起始日期 AND C.截止日期
	LEFT JOIN 
	(
	 SELECT 
		A.申請人,
		A.加班日期 加班日期,
		MAX(C.休假) 休假,
		/*平日、補班*/
		SUM(NVL(CASE WHEN NVL(C.休假,0)<=1 AND A.調補=0  THEN (CASE WHEN A.小計>=2 THEN 2 ELSE A.小計 END) ELSE 0 END ,0)) 平日前2小時,
		SUM(NVL(CASE WHEN NVL(C.休假,0)<=1 AND A.調補=0  THEN (CASE WHEN A.小計>2 AND A.小計<4 THEN A.小計-2 WHEN A.小計>=4 THEN 2 ELSE 0 END) ELSE 0 END ,0)) 平日前4小時,
		SUM(NVL(CASE WHEN NVL(C.休假,0)<=1 AND A.調補=0  THEN (CASE WHEN A.小計>4 THEN A.小計-4 ELSE 0 END) ELSE 0 END,0)) 平日大於4小時,
		/*休息日*/
		SUM(NVL(CASE WHEN NVL(C.休假,0)=2 AND A.調補=0  THEN (CASE WHEN A.小計>=2 THEN 2 ELSE A.小計 END) ELSE 0 END ,0)) 休息日前2小時,
		SUM(NVL(CASE WHEN NVL(C.休假,0)=2 AND A.調補=0  THEN (CASE WHEN A.小計>2 AND A.小計<8 THEN A.小計-2 WHEN A.小計>=8 THEN 6 ELSE 0 END) ELSE 0 END ,0)) 休息日前8小時,
		SUM(NVL(CASE WHEN NVL(C.休假,0)=2 AND A.調補=0  THEN (CASE WHEN A.小計>8 THEN A.小計-8 ELSE 0 END) ELSE 0 END ,0)) 休息日大於8小時,
		/*例假日*/
		SUM(NVL(CASE WHEN NVL(C.休假,0)=3 AND A.調補=0  THEN (CASE WHEN A.小計>0 THEN (case when A.小計>8 then 8 else A.小計 end) ELSE 0 END) ELSE 0 END ,0)) 例假日前8小時,
		SUM(NVL(CASE WHEN NVL(C.休假,0)=3 AND A.調補=0  THEN (CASE WHEN A.小計>8 AND A.小計<10 THEN A.小計-8 WHEN A.小計>=10 THEN 2 ELSE 0 END) ELSE 0 END ,0)) 例假日大於8小時,
		SUM(NVL(CASE WHEN NVL(C.休假,0)=3 AND A.調補=0  THEN (CASE WHEN A.小計>10 THEN A.小計-10 ELSE 0 END) ELSE 0 END ,0)) 例假日大於10小時,
		SUM(NVL(CASE WHEN NVL(C.休假,0)=3 AND A.調補=0  THEN (CASE WHEN A.小計>8 THEN 8 ELSE A.小計 END) ELSE 0 END ,0)) 例假日補休小時,
		/*國定假日*/
		SUM(NVL(CASE WHEN NVL(C.休假,0)=4 AND A.調補=0  THEN (CASE WHEN A.小計>0 THEN (case when A.小計>8 then 8 else A.小計 end) ELSE 0 END) ELSE 0 END ,0)) 國定假日前8小時,
		SUM(NVL(CASE WHEN NVL(C.休假,0)=4 AND A.調補=0  THEN (CASE WHEN A.小計>8 AND A.小計<10 THEN A.小計-8 WHEN A.小計>=10 THEN 2 ELSE 0 END) ELSE 0 END ,0)) 國定假日大於8小時,
		SUM(NVL(CASE WHEN NVL(C.休假,0)=4 AND A.調補=0  THEN (CASE WHEN A.小計>10 THEN A.小計-10 ELSE 0 END) ELSE 0 END ,0)) 國定假日大於10小時,
		/*加班總時數*/
		SUM(NVL(A.小計,0)) 加班時數,
		/*調補*/
		SUM(NVL(CASE WHEN A.調補=1 THEN A.小計 ELSE 0 END,0)) 調補時數
	 FROM
		VIEWFILH005A A
		LEFT JOIN ViewFIL3805 C ON A.加班日期 = C.日期
	 GROUP BY 
		A.申請人,
		A.加班日期
	) D ON A.員工編號 = D.申請人 AND D.加班日期 = A.出勤日期
	LEFT JOIN ViewFILH012 E ON E.申請人 = A.員工編號 AND E.異動日期 = A.出勤日期
	LEFT JOIN ViewFIL3805 F ON A.出勤日期 = F.日期
GROUP BY 
	A.員工編號,
	substr(A.出勤日期,1,6)
);

-- Oracle user_views
CREATE VIEW "VIEWFILH009" ("單別", "單號", "單據序號", "序號", "申請人", "加班日期", "申請人姓名", "部門編號", "部門名稱", "工作內容", "數量", "單位代碼", "單位名稱", "計件", "相關單號", "簽核狀態") AS (
SELECT 
	M.製令單別 單別, 
	M.製令單號 單號,
	M.材料序號 單據序號,
	M.序號 序號,
	A.產品編號 申請人,
	B.單據日期 加班日期,
	nvl(E.員工姓名, ' ') 申請人姓名,
	nvl(E.部門編號, ' ') 部門編號,
	nvl(F.GUName, ' ') 部門名稱,
	NVL(M.備註,' ') 工作內容,
	M.數字一 數量,
	M.代碼 單位代碼,
	nvl(D.名稱, ' ') 單位名稱,
	A.Logical1 計件, 
	M.相關單號,
	nvl(Z3.簽核狀態,' ') 簽核狀態
FROM 
	FIL0037 M
	INNER JOIN FIL0040 A ON A.單據類別 = M.製令單別 AND A.單據編號 = M.製令單號  AND A.單據序號 = M.材料序號
	INNER JOIN FIL0030 B ON M.製令單別 = B.單據類別 AND M.製令單號 = B.單據編號
	INNER JOIN FIL0041 C ON M.製令單別 = C.單別 AND M.製令單號 = C.單號 AND M.材料序號 = C.序號
	LEFT JOIN ViewFIL3103 D ON M.代碼 = D.代碼
	LEFT JOIN FIL0010 E ON A.產品編號 = E.員工編號
	LEFT JOIN A30 F ON E.部門編號 = F.GroupID
	LEFT JOIN FIL0010 Z1 ON A.最後更新者 = Z1.員工編號
	LEFT JOIN ViewOfObjProperties Z3 ON B.流水編號 = Z3.單據流水號
WHERE
	M.製令單別 = 'H03'  AND	
	M.屬性 = '4');

-- Oracle user_views
CREATE VIEW "VIEWFILH010" ("年月", "申請人", "假別", "請假時數", "請假扣薪", "假別轉換") AS (
SELECT  
	substr(A.異動日期,1,6) 年月,
	B.申請人, 
	B.假別,
	sum(A.異動數量) 請假時數,
	sum(decode(D.扣點,0,A.異動數量*(E.本薪/(30*8)*D.扣薪),A.異動數量*(E.本薪/(30*8*2))*D.扣點+(A.異動數量/8*(E.出勤日支*D.扣點)))) 請假扣薪,
	sum(case when B.假別<>B.請假假別 then A.異動數量 else 0 end) 假別轉換
FROM 
	FIL0040 A
	INNER JOIN HRFIl1031 B ON B.單號 = A.單據編號 AND B.單別 = A.單據類別
	LEFT JOIN HRFil2006 C ON B.申請人 = C.員工編號 AND substr(A.異動日期,1,6) = substr(C.年月,1,6)
	LEFT JOIN ViewFIL3801 D ON D.代碼=B.假別
	LEFT JOIN HRFil2001 E ON E.員工編號 = B.申請人 AND substr(A.異動日期,1,6) = E.年月
	LEFT JOIN ViewFilH001 Z ON Z.單別 = A.單據類別 AND Z.單號 = A.單據編號
	LEFT JOIN ViewFilH018 Z1 ON Z1.單別 = A.單據類別 AND Z1.單號 = A.單據編號 
WHERE 
	A.單據類別='H01' AND Z.簽核狀態 = 'E' or 
	A.單據類別='H05' AND Z1.簽核狀態 = 'E' 
GROUP BY  
	substr(A.異動日期,1,6),
	B.申請人, 
	B.假別
);

-- Oracle user_views
CREATE VIEW "VIEWFILH011" ("年度", "申請人", "假別", "請假時數") AS (
SELECT  
	substr(A.異動日期,1,4) 年度,
	B.申請人, 
	B.假別,
	sum(A.異動數量) 請假時數
FROM 
	FIL0040 A
	INNER JOIN HRFil1031 B ON B.單號 = A.單據編號 AND B.單別 = A.單據類別
	LEFT JOIN ViewFilH001 Z ON Z.單別 = A.單據類別 AND Z.單號 = A.單據編號
	LEFT JOIN ViewFilH018 Z1 ON Z1.單別 = A.單據類別 AND Z1.單號 = A.單據編號 	
WHERE 
	A.單據類別='H01' AND Z.簽核狀態 = 'E' or 
	A.單據類別='H05' AND Z1.簽核狀態 = 'E'
GROUP BY  
	substr(A.異動日期,1,4),
	B.申請人, 
	B.假別
);

-- Oracle user_views
CREATE VIEW "VIEWFILH012" ("異動日期", "申請人", "請假時數", "出勤扣點", "出勤扣支", "午餐扣支", "伙食扣支") AS (
SELECT  
	A.異動日期,
	DECODE(A.單據類別,'H01',B.申請人,B1.申請人) 申請人, 
	sum(A.異動數量) 請假時數,
	sum(nvl(case when A.異動數量 between 2 and 4 then decode(DECODE(A.單據類別,'H01',B.假別名稱,B1.假別名稱),'事假',2,1)*0.5 
			 when A.異動數量 > 4 then decode(DECODE(A.單據類別,'H01',B.假別名稱,B1.假別名稱),'事假',2,1)
			 else 0
			end,0)) 出勤扣點,
	sum(nvl(case when A.異動數量 between 2 and 4 then decode(DECODE(A.單據類別,'H01',B.假別名稱,B1.假別名稱),'事假',C.出勤日支,C.出勤日支/2)*0.5 
		 when A.異動數量 > 4 then decode(DECODE(A.單據類別,'H01',B.假別名稱,B1.假別名稱),'事假',C.出勤日支,C.出勤日支/2)
		 else 0
			end,0)) 出勤扣支,
	sum(nvl(case when A.異動數量 between 2 and 4 then C.OthFee1 * 0.5 
		 when A.異動數量 > 4 then C.OthFee1
		 else 0
			end,0)) 午餐扣支,
	sum(nvl(case when A.異動數量 between 2 and 4 then C.伙食津貼/30 * 0.5 
		 when A.異動數量 > 4 then C.伙食津貼/30
		 else 0
			end,0)) 伙食扣支	
FROM 
	FIL0040 A
	LEFT JOIN ViewFilH001 B ON B.單別 = A.單據類別 AND B.單號 = A.單據編號
	LEFT JOIN ViewFilH018 B1 ON B1.單別 = A.單據類別 AND B1.單號 = A.單據編號 	
	LEFT JOIN HRFIL2001 C ON C.員工編號 = DECODE(A.單據類別,'H01',B.申請人,B1.申請人) AND substr(A.異動日期,1,6) = C.年月

WHERE 
	A.單據類別='H01' AND B.簽核狀態 = 'E'	OR 
	A.單據類別='H05' AND B1.簽核狀態 = 'E'
	
GROUP BY  
	A.異動日期,
	DECODE(A.單據類別,'H01',B.申請人,B1.申請人)
);

-- Oracle user_views
CREATE VIEW "VIEWFILH012A" ("異動日期", "申請人", "請假時數") AS (
SELECT  
	A.異動日期,
	DECODE(A.單據類別,'H01',B.申請人,B1.申請人) 申請人, 
	sum(A.異動數量) 請假時數
FROM 
	FIL0040 A
	LEFT JOIN ViewFilH001 B ON B.單別 = A.單據類別 AND B.單號 = A.單據編號
	LEFT JOIN ViewFilH018 B1 ON B1.單別 = A.單據類別 AND B1.單號 = A.單據編號 	

WHERE 
	A.單據類別='H01' OR A.單據類別='H05' 
	
GROUP BY  
	A.異動日期,
	DECODE(A.單據類別,'H01',B.申請人,B1.申請人)
);

-- Oracle user_views
CREATE VIEW "VIEWFILH013" ("單據編號", "請假時數") AS (
SELECT  
	A.單據編號,
	sum(A.異動數量) 請假時數
FROM 
	FIL0040 A
WHERE 
	A.單據類別='H01' 
GROUP BY  
	A.單據編號
);

-- Oracle user_views
CREATE VIEW "VIEWFILH014" ("年月", "申請人", "請假時數合計", "伙食扣假") AS (
SELECT  
	substr(A.異動日期,1,6) 年月,
	DECODE(A.單據類別,'H01',B.申請人,B1.申請人) 申請人, 
	sum(A.異動數量) 請假時數合計,
	sum(case when A.異動數量 > 4 then 1 else 0.5 end) 伙食扣假
FROM 
	FIL0040 A
	LEFT JOIN ViewFilH001 B ON B.單別 = A.單據類別 AND B.單號 = A.單據編號 
	LEFT JOIN ViewFilH018 B1 ON B1.單別 = A.單據類別 AND B1.單號 = A.單據編號 
WHERE 
	A.單據類別='H01' AND B.簽核狀態 = 'E' OR 
	A.單據類別='H05' AND B1.簽核狀態 = 'E'
GROUP BY  
	substr(A.異動日期,1,6) ,
	DECODE(A.單據類別,'H01',B.申請人,B1.申請人)
);

-- Oracle user_views
CREATE VIEW "VIEWFILH015" ("年月", "申請人", "請假扣支", "請假時數", "出勤扣點", "伙食扣支") AS (
SELECT  
	substr(A.異動日期,1,6) 年月,
	A.申請人, 
	F.請假扣支 請假扣支,
	sum(A.請假時數) 請假時數,
	sum(A.出勤扣點) 出勤扣點,
	sum(A.伙食扣支時數 * C.伙食津貼/30) 伙食扣支	
FROM 
	(
	SELECT  
	A.異動日期,
	DECODE(A.單據類別,'H01',B.申請人,B1.申請人) 申請人, 
	sum(A.異動數量) 請假時數,
	sum(nvl(case when A.異動數量 between 2.01 and 4 then decode(DECODE(A.單據類別,'H01',B.假別名稱,B1.假別名稱),'事假',2,1)*0.5 
			 when A.異動數量 > 4 then decode(DECODE(A.單據類別,'H01',B.假別名稱,B1.假別名稱),'事假',2,1)
			 else 0
			end,0)) 出勤扣點,
	sum(nvl(case when A.異動數量 between 2.01 and 4 then  0.5 
		 when A.異動數量 > 4 then 1
		 else 0
			end,0)) 伙食扣支時數	
	FROM 
		FIL0040 A
		LEFT JOIN ViewFilH001 B ON B.單別 = A.單據類別 AND B.單號 = A.單據編號 
		LEFT JOIN ViewFilH018 B1 ON B1.單別 = A.單據類別 AND B1.單號 = A.單據編號 
	WHERE 
		(A.單據類別='H01' AND B.簽核狀態 = 'E' OR A.單據類別='H05' AND B1.簽核狀態 = 'E')
	GROUP BY 
		A.異動日期,
		DECODE(A.單據類別,'H01',B.申請人,B1.申請人) 
	) A
	LEFT JOIN HRFIL2001 C ON C.員工編號 = A.申請人 AND substr(A.異動日期,1,6) = C.年月
	LEFT JOIN HRFil2006 E ON A.申請人 = E.員工編號 AND substr(A.異動日期,1,6) = substr(E.年月,1,6)
	LEFT JOIN 
		(SELECT 
			A.年月,
			A.申請人,
			SUM(A.請假扣薪) 請假扣支 
		FROM ViewFILH010 A 
		GROUP BY 
			A.年月,
			A.申請人
		) F ON F.年月 = substr(A.異動日期,1,6) AND F.申請人 = A.申請人
GROUP BY  
	substr(A.異動日期,1,6),
	A.申請人,
	F.請假扣支
);

-- Oracle user_views
CREATE VIEW "VIEWFILH016" ("年月", "假日天數") AS (
Select
 to_char(年月) 年月,
 sum(decode(休假日,0,0,1,0,1)+decode(休假一,0,0,1,0,1)+decode(休假二,0,0,1,0,1)+decode(休假三,0,0,1,0,1)+decode(休假四,0,0,1,0,1)+decode(休假五,0,0,1,0,1)+decode(休假六,0,0,1,0,1)) 假日天數
From
 Fil1019
Group by to_char(年月) 
);

-- Oracle user_views
CREATE VIEW "VIEWFILH017" ("申請人", "加班年月", "平日前2小時", "平日前4小時", "平日大於4小時", "休息日前2小時", "休息日前8小時", "休息日大於8小時", "例假日前8小時", "例假日大於8小時", "例假日大於10小時", "例假日補休小時", "國定假日前8小時", "國定假日大於8小時", "國定假日大於10小時", "調補時數") AS (
SELECT 
		A.申請人,
		substr(A.加班日期,1,6) 加班年月,
		/*平日、補班*/
		SUM(NVL(CASE WHEN NVL(C.休假,0)<=1 AND A.調補=0 THEN (CASE WHEN A.小計>=2 THEN 2 ELSE A.小計 END) ELSE 0 END ,0)) 平日前2小時,
		SUM(NVL(CASE WHEN NVL(C.休假,0)<=1 AND A.調補=0 THEN (CASE WHEN A.小計>2 AND A.小計<4 THEN A.小計-2 WHEN A.小計>=4 THEN 2 ELSE 0 END) ELSE 0 END ,0)) 平日前4小時,
		SUM(NVL(CASE WHEN NVL(C.休假,0)<=1 AND A.調補=0 THEN (CASE WHEN A.小計>4 THEN A.小計-4 ELSE 0 END) ELSE 0 END,0)) 平日大於4小時,
		/*休息日*/
		SUM(NVL(CASE WHEN NVL(C.休假,0)=2 AND A.調補=0 THEN (CASE WHEN A.小計>=2 THEN 2 ELSE A.小計 END) ELSE 0 END ,0)) 休息日前2小時,
		SUM(NVL(CASE WHEN NVL(C.休假,0)=2 AND A.調補=0 THEN (CASE WHEN A.小計>2 AND A.小計<8 THEN A.小計-2 WHEN A.小計>=8 THEN 6 ELSE 0 END) ELSE 0 END ,0)) 休息日前8小時,
		SUM(NVL(CASE WHEN NVL(C.休假,0)=2 AND A.調補=0 THEN (CASE WHEN A.小計>8 THEN A.小計-8 ELSE 0 END) ELSE 0 END ,0)) 休息日大於8小時,
		/*例假日*/
		SUM(NVL(CASE WHEN NVL(C.休假,0)=3 AND A.調補=0 THEN (CASE WHEN A.小計>0 THEN (case when A.小計>8 then 8 else A.小計 end) ELSE 0 END) ELSE 0 END ,0)) 例假日前8小時,
		SUM(NVL(CASE WHEN NVL(C.休假,0)=3 AND A.調補=0 THEN (CASE WHEN A.小計>8 AND A.小計<10 THEN A.小計-8 WHEN A.小計>=10 THEN 2 ELSE 0 END) ELSE 0 END ,0)) 例假日大於8小時,
		SUM(NVL(CASE WHEN NVL(C.休假,0)=3 AND A.調補=0 THEN (CASE WHEN A.小計>10 THEN A.小計-10 ELSE 0 END) ELSE 0 END ,0)) 例假日大於10小時,
		SUM(NVL(CASE WHEN NVL(C.休假,0)=3 AND A.調補=0 THEN (CASE WHEN A.小計>8 THEN 8 ELSE A.小計 END) ELSE 0 END ,0)) 例假日補休小時,
		/*國定假日*/
		SUM(NVL(CASE WHEN NVL(C.休假,0)=4 AND A.調補=0 THEN (CASE WHEN A.小計>0 THEN (case when A.小計>8 then 8 else A.小計 end) ELSE 0 END) ELSE 0 END ,0)) 國定假日前8小時,
		SUM(NVL(CASE WHEN NVL(C.休假,0)=4 AND A.調補=0 THEN (CASE WHEN A.小計>8 AND A.小計<10 THEN A.小計-8 WHEN A.小計>=10 THEN 2 ELSE 0 END) ELSE 0 END ,0)) 國定假日大於8小時,
		SUM(NVL(CASE WHEN NVL(C.休假,0)=4 AND A.調補=0 THEN (CASE WHEN A.小計>10 THEN A.小計-10 ELSE 0 END) ELSE 0 END ,0)) 國定假日大於10小時,
		/*調補*/
		SUM(NVL(CASE WHEN A.調補=1 THEN A.小計 ELSE 0 END,0)) 調補時數
	 FROM
		VIEWFILH005A A
		LEFT JOIN ViewFIL3805 C ON A.加班日期 = C.日期
	 GROUP BY 
		A.申請人,
		substr(A.加班日期,1,6)	 
);

-- Oracle user_views
CREATE VIEW "VIEWFILH018" ("單別", "單號", "單據日期", "主旨", "填寫人", "填寫人姓名", "申請人", "申請人姓名", "填寫日期", "假別", "假別名稱", "請假假別", "請假假別名稱", "起始日期", "起始時間", "截止日期", "截止時間", "天數", "時數", "代理人", "代理人姓名", "部門編號", "部門名稱", "簽核狀態", "簽核系統", "流水編號", "請假事由", "最後更新者", "更新者姓名", "員工流水編號", "最後更新日") AS (
SELECT
	'H05' 單別,
	A.單號,
	B.單據日期,
	A.單號||'('||'H01'||')' 主旨,
	A.填寫人,
	nvl(C.員工姓名, ' ') 填寫人姓名,
	A.申請人,
	nvl(F.員工姓名, ' ') 申請人姓名,
	A.填寫日期,
	A.假別,
	nvl(D.名稱, ' ') 假別名稱,
	decode(A.請假假別,' ',A.假別,A.請假假別) 請假假別,
	nvl(decode(A.請假假別,' ',D.名稱,D1.名稱), ' ') 請假假別名稱,
	A.起始日期,
	A.起始時間,
	A.截止日期,
	A.截止時間,
	A.天數,
	A.時數,
	A.代理人,
	nvl(E.員工姓名, ' ') 代理人姓名,
	B.部門編號,
	nvl(Z3.GUName, ' ') 部門名稱,
	nvl(Z2.簽核狀態, ' ') 簽核狀態,
	B.簽核系統,
	A.流水編號,
	A.請假事由,
	B.最後更新者,
	nvl(Z1.員工姓名, ' ') 更新者姓名,
	nvl(C.Serial_Num,' ') 員工流水編號, 
	B.最後更新日
FROM
	HRFIL1031 A
	INNER JOIN FIL0030 B ON A.流水編號 = B.流水編號
	LEFT JOIN FIL0010 C ON A.填寫人 = C.員工編號
	LEFT JOIN ViewFIL3801 D ON A.假別 = D.代碼
	LEFT JOIN ViewFIL3801 D1 ON A.請假假別 = D1.代碼
	LEFT JOIN FIL0010 E ON A.代理人 = E.員工編號
	LEFT JOIN FIL0010 F ON A.申請人 = F.員工編號
	LEFT JOIN FIL0010 Z1 ON B.最後更新者 = Z1.員工編號
	LEFT JOIN ViewOfObjProperties Z2 ON A.流水編號 = Z2.單據流水號
	LEFT JOIN A30 Z3 ON B.部門編號 = Z3.GroupID
WHERE
	B.單據類別 = 'H05'	
	);

-- Oracle user_views
CREATE VIEW "VIEWFILH019" ("申請人", "起始日期", "假別") AS (
SELECT
	A.申請人,
	M.異動日期 起始日期,
	utl_raw.cast_to_nvarchar2(listagg(utl_raw.cast_to_raw(A.假別名稱||substr(M.Time1,1,2)||':'||substr(M.Time1,3,2)||'[')||utl_raw.cast_to_raw(trim(TO_NCHAR(ROUND(M.異動數量,1),'90D9')))||utl_raw.cast_to_raw(N'小時]'||trim(decode(A.簽核狀態,'E',' ','(未)'))), utl_raw.cast_to_raw(N' ')) within group (order by A.申請人)) as 假別
FROM
	FIL0040 M
	INNER JOIN ViewFilH001 A ON A.單別 = M.單據類別 AND A.單號 = M.單據編號
WHERE 
	M.單據類別 = 'H01' 
GROUP BY 
	A.申請人,
	M.異動日期	
);

-- Oracle user_views
CREATE VIEW "VIEWFILH020" ("申請人", "加班日期", "倍數欄位", "小時") AS (
SELECT 
	A.申請人,
	A.加班日期 加班日期,
	1 倍數欄位,
	SUM(NVL(CASE WHEN NVL(C.休假,0)<=1  THEN (CASE WHEN A.小計>=2 THEN 2 ELSE A.小計 END) ELSE 0 END ,0)) 小時
 FROM
	VIEWFILH005 A
	INNER JOIN VIEWFILH004 B ON B.單別 =  A.單別 AND B.單號 = A.單號
	LEFT JOIN ViewFIL3805 C ON A.加班日期 = C.日期
 WHERE 
	B.簽核狀態 = 'E' AND A.計件=0 AND A.調補=0	
 GROUP BY 
	A.申請人,
	A.加班日期,
	1

Union All

SELECT 
	A.申請人,
	A.加班日期 加班日期,
	2 倍數欄位,
	SUM(NVL(CASE WHEN NVL(C.休假,0)<=1  THEN (CASE WHEN A.小計>2 AND A.小計<4 THEN A.小計-2 WHEN A.小計>=4 THEN 2 ELSE 0 END) ELSE 0 END ,0)) 小時
 FROM
	VIEWFILH005 A
	INNER JOIN VIEWFILH004 B ON B.單別 =  A.單別 AND B.單號 = A.單號
	LEFT JOIN ViewFIL3805 C ON A.加班日期 = C.日期
 WHERE 
	B.簽核狀態 = 'E' AND A.計件=0 AND A.調補=0	
 GROUP BY 
	A.申請人,
	A.加班日期,
	2

Union All

SELECT 
	A.申請人,
	A.加班日期 加班日期,
	4 倍數欄位,
	SUM(NVL(CASE WHEN NVL(C.休假,0)=2  THEN (CASE WHEN A.小計>=2 THEN 2 ELSE A.小計 END) ELSE 0 END ,0)) 小時
 FROM
	VIEWFILH005 A
	INNER JOIN VIEWFILH004 B ON B.單別 =  A.單別 AND B.單號 = A.單號
	LEFT JOIN ViewFIL3805 C ON A.加班日期 = C.日期
 WHERE 
	B.簽核狀態 = 'E' AND A.計件=0 AND A.調補=0	
 GROUP BY 
	A.申請人,
	A.加班日期,
	4

Union All

SELECT 
	A.申請人,
	A.加班日期 加班日期,
	5 倍數欄位,
	SUM(NVL(CASE WHEN NVL(C.休假,0)=2  THEN (CASE WHEN A.小計>2 AND A.小計<8 THEN A.小計-2 WHEN A.小計>=8 THEN 6 ELSE 0 END) ELSE 0 END ,0)) 小時
 FROM
	VIEWFILH005 A
	INNER JOIN VIEWFILH004 B ON B.單別 =  A.單別 AND B.單號 = A.單號
	LEFT JOIN ViewFIL3805 C ON A.加班日期 = C.日期
 WHERE 
	B.簽核狀態 = 'E' AND A.計件=0 AND A.調補=0	
 GROUP BY 
	A.申請人,
	A.加班日期,
	5
	
Union All

SELECT 
	A.申請人,
	A.加班日期 加班日期,
	6 倍數欄位,
	SUM(NVL(CASE WHEN NVL(C.休假,0)=2  THEN (CASE WHEN A.小計>8 AND A.小計<12 THEN A.小計-8 WHEN A.小計>=12 THEN 4 ELSE 0 END) ELSE 0 END ,0)) 小時
 FROM
	VIEWFILH005 A
	INNER JOIN VIEWFILH004 B ON B.單別 =  A.單別 AND B.單號 = A.單號
	LEFT JOIN ViewFIL3805 C ON A.加班日期 = C.日期
 WHERE 
	B.簽核狀態 = 'E' AND A.計件=0 AND A.調補=0	
 GROUP BY 
	A.申請人,
	A.加班日期,
	6		
Union All

SELECT 
	A.申請人,
	A.加班日期 加班日期,
	7 倍數欄位,
	SUM(NVL(CASE WHEN NVL(C.休假,0)=3  THEN (CASE WHEN A.小計>0 THEN (case when A.小計>8 then 8 else A.小計 end) ELSE 0 END) ELSE 0 END ,0)) 小時
 FROM
	VIEWFILH005 A
	INNER JOIN VIEWFILH004 B ON B.單別 =  A.單別 AND B.單號 = A.單號
	LEFT JOIN ViewFIL3805 C ON A.加班日期 = C.日期
 WHERE 
	B.簽核狀態 = 'E' AND A.計件=0 AND A.調補=0	
 GROUP BY 
	A.申請人,
	A.加班日期,
	7

Union All

SELECT 
	A.申請人,
	A.加班日期 加班日期,
	8 倍數欄位,
	SUM(NVL(CASE WHEN NVL(C.休假,0)=3  THEN (CASE WHEN A.小計>8 AND A.小計<10 THEN A.小計-8 WHEN A.小計>=10 THEN 2 ELSE 0 END) ELSE 0 END ,0)) 小時
 FROM
	VIEWFILH005 A
	INNER JOIN VIEWFILH004 B ON B.單別 =  A.單別 AND B.單號 = A.單號
	LEFT JOIN ViewFIL3805 C ON A.加班日期 = C.日期
 WHERE 
	B.簽核狀態 = 'E' AND A.計件=0  AND A.教育=0 AND A.調補=0	
 GROUP BY 
	A.申請人,
	A.加班日期,
	8

Union All

SELECT 
	A.申請人,
	A.加班日期 加班日期,
	9 倍數欄位,
	SUM(NVL(CASE WHEN NVL(C.休假,0)=3  THEN (CASE WHEN A.小計>10 AND A.小計<12 THEN A.小計-10 WHEN A.小計>=12 THEN 2 ELSE 0 END) ELSE 0 END ,0)) 小時
 FROM
	VIEWFILH005 A
	INNER JOIN VIEWFILH004 B ON B.單別 =  A.單別 AND B.單號 = A.單號
	LEFT JOIN ViewFIL3805 C ON A.加班日期 = C.日期
 WHERE 
	B.簽核狀態 = 'E' AND A.計件=0 AND A.教育=0 AND A.調補=0	
 GROUP BY 
	A.申請人,
	A.加班日期,
	9		

Union All

SELECT 
	A.申請人,
	A.加班日期 加班日期,
	10 倍數欄位,
	SUM(NVL(CASE WHEN NVL(C.休假,0)=4  THEN (CASE WHEN A.小計>0 THEN (case when A.小計>8 then 8 else A.小計 end) ELSE 0 END) ELSE 0 END ,0)) 小時
 FROM
	VIEWFILH005 A
	INNER JOIN VIEWFILH004 B ON B.單別 =  A.單別 AND B.單號 = A.單號
	LEFT JOIN ViewFIL3805 C ON A.加班日期 = C.日期
 WHERE 
	B.簽核狀態 = 'E' AND A.計件=0 AND A.教育=0 AND A.調補=0	
 GROUP BY 
	A.申請人,
	A.加班日期,
	10

Union All

SELECT 
	A.申請人,
	A.加班日期 加班日期,
	11 倍數欄位,
	SUM(NVL(CASE WHEN NVL(C.休假,0)=4  THEN (CASE WHEN A.小計>8 AND A.小計<10 THEN A.小計-8 WHEN A.小計>=10 THEN 2 ELSE 0 END) ELSE 0 END ,0)) 小時
 FROM
	VIEWFILH005 A
	INNER JOIN VIEWFILH004 B ON B.單別 =  A.單別 AND B.單號 = A.單號
	LEFT JOIN ViewFIL3805 C ON A.加班日期 = C.日期
 WHERE 
	B.簽核狀態 = 'E' AND A.計件=0 AND A.教育=0 AND A.調補=0	
 GROUP BY 
	A.申請人,
	A.加班日期,
	11			

Union All

SELECT 
	A.申請人,
	A.加班日期 加班日期,
	12 倍數欄位,
	SUM(NVL(CASE WHEN NVL(C.休假,0)=4  THEN (CASE WHEN A.小計>10 AND A.小計<12 THEN A.小計-10 WHEN A.小計>=12 THEN 2 ELSE 0 END) ELSE 0 END ,0)) 小時
 FROM
	VIEWFILH005 A
	INNER JOIN VIEWFILH004 B ON B.單別 =  A.單別 AND B.單號 = A.單號
	LEFT JOIN ViewFIL3805 C ON A.加班日期 = C.日期
 WHERE 
	B.簽核狀態 = 'E' AND A.計件=0 AND A.教育=0 AND A.調補=0	
 GROUP BY 
	A.申請人,
	A.加班日期,
	12				
);

-- Oracle user_views
CREATE VIEW "VIEWFILH021" ("申請人", "加班日期", "加班小時", "上班時間", "下班時間", "加班費") AS (
SELECT 
	A.申請人,
	A.加班日期,
	sum(A.加班小時) 加班小時,
	min(A.上班時間) 上班時間,
	max(A.下班時間) 下班時間,
	sum(round(A.加班費,1)) 加班費
FROM
	HRFIL0021 A
WHERE
	A.上班時間 > '000000'
GROUP BY 
	A.申請人,
	A.加班日期		
);

-- Oracle user_views
CREATE VIEW "VIEWFILH022" ("申請人", "加班年月", "加班小時", "加班費") AS (
SELECT 
	A.申請人,
	substr(A.加班日期,1,6) 加班年月,
	sum(A.加班小時) 加班小時,
	sum(round(A.加班費,1)) 加班費
FROM
	HRFIL0021 A
GROUP BY 
	A.申請人,
	substr(A.加班日期,1,6)		
);

-- Oracle user_views
CREATE VIEW "VIEWFILH023" ("單別", "單號", "主旨", "公司代碼", "公司名稱", "申請日期", "帳款年月", "部門編號", "部門名稱", "簽核系統", "費用類別", "簽核狀態", "簽核排序", "備註", "流水編號", "填表人", "填表人姓名", "填表人職稱", "填表日", "最後更新者", "更新者姓名", "員工流水編號", "最後更新日") AS (
SELECT
	A.單據類別 單別,
	A.單據編號 單號,
	A.單據編號||'('||A.單據類別||')' 主旨,
	A.公司代碼,
	nvl(E.全名, ' ') 公司名稱,
	A.單據日期 申請日期,
	A.匯率日期 帳款年月,
	A.部門編號,
	nvl(B.GUName, ' ') 部門名稱,
	A.簽核系統, 
	A.稅別 費用類別,
	nvl(Z3.簽核狀態, '0') 簽核狀態,
	decode(nvl(Z3.簽核狀態, ' '),' ',' .未送簽','I','1.簽核中','D','2.退回','A','3.作廢','E','9.已簽',' .草稿') 簽核排序,
	A.備註, 
	A.流水編號,
	A.填表人,
	nvl(Z1.員工姓名,' ') 填表人姓名, 
	NVL(Z4.GUNAME,' ') 填表人職稱,
	A.填表日, 
	A.最後更新者,
	nvl(Z2.員工姓名,' ') 更新者姓名,
	nvl(Z1.Serial_Num,' ') 員工流水編號, 	
	A.最後更新日
FROM
	FIL0030 A
	LEFT JOIN A30 B ON A.部門編號 = B.GroupID
	LEFT JOIN ViewFIL0011 E ON A.公司代碼 = E.代碼
	LEFT JOIN ViewFIL0030 F ON A.簽核系統 = F.簽核系統 AND A.單據編號 = F.單號
	LEFT JOIN FIL0010 Z1 ON A.填表人 = Z1.員工編號
	LEFT JOIN FIL0010 Z2 ON A.最後更新者 = Z2.員工編號
	LEFT JOIN ViewOfObjProperties Z3 ON A.流水編號 = Z3.單據流水號
	LEFT JOIN A40 Z4 ON Z1.FLOWPOSI = Z4.Serial_Num
WHERE
	A.單據類別 = 'H11');

-- Oracle user_views
CREATE VIEW "VIEWFILH024" ("單別", "單號", "序號", "申請人", "申請人姓名", "部門編號", "部門名稱", "金額", "備註", "流水編號", "最後更新者", "更新者姓名", "最後更新日", "簽核狀態") AS (
SELECT 
	A.單據類別 單別, 
	A.單據編號 單號,
	A.單據序號 序號,
	A.產品編號 申請人,
	nvl(E.員工姓名, ' ') 申請人姓名,
	nvl(E.部門編號, ' ') 部門編號,
	nvl(F.GUName, ' ') 部門名稱,
	A.異動數量 金額,
	A.備註說明 備註,
	A.流水編號,
	A.最後更新者,
	NVL(Z1.員工姓名,' ') 更新者姓名,
	A.最後更新日,
	nvl(Z3.簽核狀態,' ') 簽核狀態
FROM 
	FIL0040 A
	INNER JOIN FIL0030 B ON A.單據類別 = B.單據類別 AND A.單據編號 = B.單據編號
	LEFT JOIN ViewFIL3103 D ON A.單位代碼 = D.代碼
	LEFT JOIN FIL0010 E ON A.產品編號 = E.員工編號
	LEFT JOIN A30 F ON E.部門編號 = F.GroupID
	LEFT JOIN FIL0010 Z1 ON A.最後更新者 = Z1.員工編號
	LEFT JOIN ViewOfObjProperties Z3 ON B.流水編號 = Z3.單據流水號
WHERE
	A.單據類別 = 'H11');

-- Oracle user_views
CREATE VIEW "VIEWFILH025" ("單別", "單號", "金額") AS (
SELECT 
	A.單據類別 單別, 
	A.單據編號 單號,
	sum(A.異動數量) 金額
FROM 
	FIL0040 A
WHERE
	A.單據類別 = 'H11'
GROUP BY
	A.單據類別,
	A.單據編號);

-- Oracle user_views
CREATE VIEW "VIEWFILH026" ("作業人員", "年月", "件數", "加工費") AS (
select 
	D.產品編號 作業人員,
	substr(C.匯率日期,1,6) 年月,
	max(A.數字一) 件數,
	sum(round(A.數字一*nvl(decode(E.製程代碼,'C31G',B.鐵條加工單價,B.氣閥加工單價),0),0)) 加工費
from
	fil0037 A
	inner join fil0031 E ON E.單別 = A.相關單別 AND E.單號 = A.相關單號
	inner join fil0030 G ON G.單據類別 = E.單別 AND G.單據編號 = E.單號
	inner join fil0032 B on B.製令單別=G.歸屬類別 and B.製令單號=G.歸屬編號
	inner join fil0030 C on A.製令單別=C.單據類別 and A.製令單號=C.單據編號
	inner join fil0040 D on A.製令單別=D.單據類別 and A.製令單號=D.單據編號 and A.材料序號=D.單據序號
	inner join ViewOfObjProperties G on C.流水編號 = G.單據流水號
Where
	A.製令單別='H03' AND
	A.屬性='4' AND 
	G.簽核狀態='E' AND 
	D.Logical1=1
Group by
	D.產品編號,
	substr(C.匯率日期,1,6)
);

-- Oracle user_views
CREATE VIEW "VIEWFILH027" ("作業人員", "年度", "件數", "加工費") AS (
select 
	D.產品編號 作業人員,
	substr(C.匯率日期,1,4) 年度,
	max(A.數字一) 件數,
	sum(round(A.數字一*nvl(decode(E.製程代碼,'C31G',B.鐵條加工單價,B.氣閥加工單價),0),0)) 加工費
from
	fil0037 A
	inner join fil0031 E ON E.單別 = A.相關單別 AND E.單號 = A.相關單號
	inner join fil0030 G ON G.單據類別 = E.單別 AND G.單據編號 = E.單號
	inner join fil0032 B on B.製令單別=G.歸屬類別 and B.製令單號=G.歸屬編號
	inner join fil0030 C on A.製令單別=C.單據類別 and A.製令單號=C.單據編號
	inner join fil0040 D on A.製令單別=D.單據類別 and A.製令單號=D.單據編號 and A.材料序號=D.單據序號
	inner join ViewOfObjProperties G on C.流水編號 = G.單據流水號
Where
	A.製令單別='H03' AND
	A.屬性='4' AND 
	G.簽核狀態='E' AND 
	D.Logical1=1
Group by
	D.產品編號,
	substr(C.匯率日期,1,4)
);

-- Oracle user_views
CREATE VIEW "VIEWFILH030" ("單別", "單號", "主旨", "公司代碼", "公司名稱", "申請日期", "帳款年月", "簽核系統", "簽核狀態", "簽核排序", "費用類別", "備註", "流水編號", "填表人", "填表人姓名", "填表日", "最後更新者", "更新者姓名", "員工流水編號", "最後更新日") AS (
SELECT
	A.單據類別 單別,
	A.單據編號 單號,
	A.單據編號||'('||A.單據類別||'):'||SUBSTR(A.匯率日期,6) 主旨,
	A.公司代碼,
	nvl(E.全名, ' ') 公司名稱,
	A.單據日期 申請日期,
	A.匯率日期 帳款年月,
	A.簽核系統, 
	nvl(Z3.簽核狀態, '0') 簽核狀態,
	decode(nvl(Z3.簽核狀態, ' '),' ',' .未送簽','I','1.簽核中','D','2.退回','A','3.作廢','E','9.已簽',' .草稿') 簽核排序,
	A.稅別 費用類別,
	A.備註, 
	A.流水編號,
	A.填表人,
	nvl(Z1.員工姓名,' ') 填表人姓名, 
	A.填表日, 
	A.最後更新者,
	nvl(Z2.員工姓名,' ') 更新者姓名,
	nvl(Z1.Serial_Num,' ') 員工流水編號, 	
	A.最後更新日
FROM
	FIL0030 A
	LEFT JOIN ViewFIL0011 E ON A.公司代碼 = E.代碼
	LEFT JOIN ViewFIL0030 F ON A.簽核系統 = F.簽核系統 AND A.單據編號 = F.單號
	LEFT JOIN FIL0010 Z1 ON A.填表人 = Z1.員工編號
	LEFT JOIN FIL0010 Z2 ON A.最後更新者 = Z2.員工編號
	LEFT JOIN ViewOfObjProperties Z3 ON A.流水編號 = Z3.單據流水號
	LEFT JOIN A40 Z4 ON Z1.FLOWPOSI = Z4.Serial_Num
WHERE
	A.單據類別 = 'H21');

-- Oracle user_views
CREATE VIEW "VIEWFILH031" ("單別", "單號", "主旨", "公司代碼", "公司名稱", "申請日期", "帳款年月", "簽核系統", "簽核狀態", "簽核排序", "費用類別", "備註", "流水編號", "填表人", "填表人姓名", "填表日", "最後更新者", "更新者姓名", "員工流水編號", "最後更新日") AS (
SELECT
	A.單據類別 單別,
	A.單據編號 單號,
	A.單據編號||'('||A.單據類別||'):'||SUBSTR(A.匯率日期,6) 主旨,
	A.公司代碼,
	nvl(E.全名, ' ') 公司名稱,
	A.單據日期 申請日期,
	A.匯率日期 帳款年月,
	A.簽核系統, 
	nvl(Z3.簽核狀態, '0') 簽核狀態,
	decode(nvl(Z3.簽核狀態, ' '),' ',' .未送簽','I','1.簽核中','D','2.退回','A','3.作廢','E','9.已簽',' .草稿') 簽核排序,
	A.稅別 費用類別,
	A.備註, 
	A.流水編號,
	A.填表人,
	nvl(Z1.員工姓名,' ') 填表人姓名, 
	A.填表日, 
	A.最後更新者,
	nvl(Z2.員工姓名,' ') 更新者姓名,
	nvl(Z1.Serial_Num,' ') 員工流水編號, 	
	A.最後更新日
FROM
	FIL0030 A
	LEFT JOIN ViewFIL0011 E ON A.公司代碼 = E.代碼
	LEFT JOIN ViewFIL0030 F ON A.簽核系統 = F.簽核系統 AND A.單據編號 = F.單號
	LEFT JOIN FIL0010 Z1 ON A.填表人 = Z1.員工編號
	LEFT JOIN FIL0010 Z2 ON A.最後更新者 = Z2.員工編號
	LEFT JOIN ViewOfObjProperties Z3 ON A.流水編號 = Z3.單據流水號
	LEFT JOIN A40 Z4 ON Z1.FLOWPOSI = Z4.Serial_Num
WHERE
	A.單據類別 = 'H22');

-- Oracle user_views
CREATE VIEW "VIEWFILH032" ("單別", "單號", "主旨", "公司代碼", "公司名稱", "申請日期", "帳款年月", "簽核系統", "簽核狀態", "簽核排序", "費用類別", "備註", "流水編號", "填表人", "填表人姓名", "填表日", "最後更新者", "更新者姓名", "員工流水編號", "最後更新日") AS (
SELECT
	A.單據類別 單別,
	A.單據編號 單號,
	A.單據編號||'('||A.單據類別||'):'||SUBSTR(A.匯率日期,6) 主旨,
	A.公司代碼,
	nvl(E.全名, ' ') 公司名稱,
	A.單據日期 申請日期,
	A.匯率日期 帳款年月,
	A.簽核系統, 
	nvl(Z3.簽核狀態, '0') 簽核狀態,
	decode(nvl(Z3.簽核狀態, ' '),' ',' .未送簽','I','1.簽核中','D','2.退回','A','3.作廢','E','9.已簽',' .草稿') 簽核排序,
	A.稅別 費用類別,
	A.備註, 
	A.流水編號,
	A.填表人,
	nvl(Z1.員工姓名,' ') 填表人姓名, 
	A.填表日, 
	A.最後更新者,
	nvl(Z2.員工姓名,' ') 更新者姓名,
	nvl(Z1.Serial_Num,' ') 員工流水編號, 	
	A.最後更新日
FROM
	FIL0030 A
	LEFT JOIN ViewFIL0011 E ON A.公司代碼 = E.代碼
	LEFT JOIN ViewFIL0030 F ON A.簽核系統 = F.簽核系統 AND A.單據編號 = F.單號
	LEFT JOIN FIL0010 Z1 ON A.填表人 = Z1.員工編號
	LEFT JOIN FIL0010 Z2 ON A.最後更新者 = Z2.員工編號
	LEFT JOIN ViewOfObjProperties Z3 ON A.流水編號 = Z3.單據流水號
	LEFT JOIN A40 Z4 ON Z1.FLOWPOSI = Z4.Serial_Num
WHERE
	A.單據類別 = 'H23');

-- Oracle user_views
CREATE VIEW "VIEWFILH033" ("員工編號", "年月", "計件工資") AS (
select 
		D.產品編號 員工編號,
		substr(C.匯率日期,1,6) 年月,
		sum(round(A.數字一*nvl(decode(E.製程代碼,'C31G',B.鐵條加工單價,B.氣閥加工單價),0),0)) 計件工資
from
	fil0037 A
	inner join fil0031 E ON E.單別 = A.相關單別 AND E.單號 = A.相關單號
	inner join fil0030 G ON G.單據類別 = E.單別 AND G.單據編號 = E.單號
	inner join fil0032 B on B.製令單別=G.歸屬類別 and B.製令單號=G.歸屬編號
	inner join fil0030 C on A.製令單別=C.單據類別 and A.製令單號=C.單據編號
	inner join fil0040 D on A.製令單別=D.單據類別 and A.製令單號=D.單據編號 and A.材料序號=D.單據序號
	inner join ViewOfObjProperties G on C.流水編號 = G.單據流水號
Where
	A.製令單別='H03' AND
	G.簽核狀態='E' AND
	A.屬性='4' AND
	D.Logical1=1
Group by
	D.產品編號,
	substr(C.匯率日期,1,6)			
);

-- Oracle user_views
CREATE VIEW "VIEWFILHS01" ("年月", "員工編號", "員工姓名", "公司代碼", "公司別", "部門編號", "部門名稱", "職位名稱", "國籍", "薪資分群", "所得稅率", "健保卡號", "勞保費", "健保費", "自提退休金", "二代健保", "本薪", "職務津貼", "出勤日支", "出勤津貼", "交通津貼", "技術津貼", "午餐津貼", "伙食津貼", "午餐日支", "借支", "固定所得稅", "退休金提撥", "特休日支", "職等", "職級", "薪點") AS (
SELECT
	substr(B.年月,1,6) 年月,
	A.員工編號,
	A.員工姓名,
	B.公司代碼,
	C.GUName 公司別,
	A.部門編號,
	A.部門名稱,
	A.職位名稱,
	A.國籍,
	B.薪資分群,
	NVL(B.所得稅率,0) 所得稅率,
	NVL(B.健保卡號,' ') 健保卡號,
	NVL(B.勞保費,0) 勞保費,
	NVL(B.健保費,0) 健保費,
	NVL(B.自提退休金,0) 自提退休金,
	NVL(B.二代健保,0) 二代健保,
	NVL(B.本薪,0) 本薪,
	NVL(B.職務津貼,0) 職務津貼,
	NVL(B.出勤日支,0) 出勤日支,
	NVL(B.出勤津貼,0) 出勤津貼,
	NVL(B.交通津貼,0) 交通津貼,
	NVL(B.技術津貼,0) 技術津貼,
	NVL(B.午餐津貼,0) 午餐津貼,
	NVL(B.伙食津貼,0) 伙食津貼,
	NVL(B.OTHFEE1,0) 午餐日支,
	NVL(B.OTHFEE2,0) 借支,
	NVL(B.OTHFEE3,0) 固定所得稅,
	NVL(B.OTHFEE4,0) 退休金提撥,
	NVL((B.本薪+B.職務津貼+B.出勤津貼+B.交通津貼+B.技術津貼+B.午餐津貼+B.伙食津貼)/30,0) 特休日支,
	NVL(B.職等,0) 職等,
	NVL(B.職級,0) 職級,
	NVL(B.薪點,0) 薪點
FROM
	HRFIL2001 B 
	INNER JOIN ViewFil1010 A ON B.員工編號= A.員工編號
	LEFT JOIN A50 C ON C.CMPID = B.公司代碼
WHERE
	A.停止使用=0
	);

-- Oracle user_views
CREATE VIEW "VIEWFILHS02" ("年月", "員工編號", "員工姓名", "身份證", "工資卡號", "公司代碼", "薪資分群", "部門代號", "部門", "職稱", "出差", "遲到", "早退", "假別一", "假別二", "假別三", "假別四", "假別五", "假別六", "假別七", "假別八", "假別九", "假別十", "假別十一", "假別十二", "假別十三", "本薪", "職務津貼", "出勤日支", "出勤津貼", "交通津貼", "技術津貼", "午餐津貼", "特休津貼", "伙食津貼", "夜班津貼", "大夜津貼", "車馬費", "加班費", "本月應發金額", "事病假薪點", "遲到早退扣支", "調補扣支", "借支", "自提退休金", "所得稅", "勞保費", "健保費", "二代健保", "加班費一", "加班費二", "實發金額", "上班打卡日", "加班計算日薪", "特休計算日薪", "平日前2小時", "平日前4小時", "平日大於4小時", "休息日前2小時", "休息日前8小時", "休息日大於8小時", "例假日前8小時", "例假日大於8小時", "例假日大於10小時", "例假日補休小時", "國定假日前8小時", "國定假日大於8小時", "國定假日大於10小時", "製程代碼", "成本類別", "實際直接人工時薪", "直接人工時薪") AS (
select
	A.年月,
	A.員工編號,
	A.員工姓名,
	A.身份證,
	A.工資卡號,
	A.公司代碼,
	A.薪資分群,
	A.部門代號,
	A.部門,
	A.職稱,
	A.出差,
	A.遲到,
	A.早退,
	A.假別一,
	A.假別二,
	A.假別三,
	A.假別四,
	A.假別五,
	A.假別六,
	A.假別七,
	A.假別八,
	A.假別九,
	A.假別十,
	A.假別十一,
	A.假別十二,
	A.假別十三,
	A.本薪,
	A.職務津貼,
	A.出勤日支,
	A.出勤津貼,
	A.交通津貼,
	A.技術津貼,
	A.午餐津貼,
	A.特休津貼,
	A.伙食津貼,
	A.夜班津貼,
	A.大夜津貼,
	A.車馬費,
	A.加班費,
	A.本月應發金額,
	A.事病假薪點,
	A.遲到早退扣支,
	A.調補扣支,
	A.借支,
	A.自提退休金,
	A.所得稅,
	A.勞保費,
	A.健保費,
	A.二代健保,
	A.加班費一,
	A.加班費二,
	A.實發金額,
	A.上班打卡日,
	A.加班計算日薪,
	A.特休計算日薪,
	A.平日前2小時,
	A.平日前4小時,
	A.平日大於4小時,
	A.休息日前2小時,
	A.休息日前8小時,
	A.休息日大於8小時,
	A.例假日前8小時,
	A.例假日大於8小時,
	A.例假日大於10小時,
	A.例假日補休小時,
	A.國定假日前8小時,
	A.國定假日大於8小時,
	A.國定假日大於10小時,
	NVL(B.製程代碼,' ') 製程代碼,
	NVL(B.成本類別,' ') 成本類別,
	decode(A.上班打卡日,0,0,(A.本月應發金額-A.事病假薪點-A.遲到早退扣支-A.調補扣支)/(A.上班打卡日*8+(A.平日前2小時+A.平日前4小時+A.平日大於4小時+A.休息日大於8小時+A.例假日大於8小時+A.例假日大於10小時+A.國定假日大於8小時+A.國定假日大於10小時-A.休息日前2小時-A.休息日前8小時-A.例假日前8小時-A.國定假日前8小時))) 實際直接人工時薪,
	decode(A.上班打卡日,0,0,(A.本薪+A.職務津貼+A.出勤津貼+A.交通津貼+A.技術津貼+A.特休津貼+A.加班費-A.借支-A.事病假薪點)/(A.上班打卡日*8+(A.平日前2小時+A.平日前4小時+A.平日大於4小時+A.休息日大於8小時+A.例假日大於8小時+A.例假日大於10小時+A.國定假日大於8小時+A.國定假日大於10小時-A.休息日前2小時-A.休息日前8小時-A.例假日前8小時-A.國定假日前8小時))) 直接人工時薪
From
	HRFIL2006 A
	LEFT JOIN HRFIL2001 B ON SUBSTR(B.年月,1,6)=SUBSTR(A.年月,1,6) AND B.員工編號=A.員工編號
	);

-- Oracle user_views
CREATE VIEW "VIEWFILHS03" ("年度", "員工編號", "特休支薪天數", "遲到", "早退", "病假", "事假", "公傷病假", "調補", "公假", "婚假", "喪假", "特別休假", "產假", "產檢假", "陪產假", "調補剩餘", "調補減少", "本薪", "職務津貼", "出勤日支", "出勤津貼", "交通津貼", "技術津貼", "午餐津貼", "特休津貼", "伙食津貼", "夜班津貼", "大夜津貼", "加班費", "車馬費", "本月應發金額", "病假薪點", "遲到早退扣支", "調補扣支", "借支", "自提退休金", "所得稅", "勞保費", "健保費", "二代健保", "加班費一", "加班費二", "實發金額", "上班打卡日", "加班計算日薪", "特休計算日薪", "日前2小時", "平日前4小時", "日大於4小時", "休息日前2小時", "休息日前8小時", "休息日大於8小時", "假日前8小時", "例假日大於8小時", "例假日大於10小時", "例假日補休小時", "國定假日前8小時", "國定假日大於8小時", "國定假日大於10小時") AS (
select
	substr(A.年月,1,4) 年度,
	A.員工編號,
	sum(A.出差) 特休支薪天數,
	sum(A.遲到) 遲到,
	sum(A.早退) 早退,
	sum(A.假別一) 病假,
	sum(A.假別二) 事假,
	sum(A.假別三) 公傷病假,
	sum(A.假別四) 調補,
	sum(A.假別五) 公假,
	sum(A.假別六) 婚假,
	sum(A.假別七) 喪假,
	sum(A.假別八) 特別休假,
	sum(A.假別九) 產假,
	sum(A.假別十) 產檢假,
	sum(A.假別十一) 陪產假,
	sum(A.假別十二) 調補剩餘,
	sum(A.假別十三) 調補減少,
	sum(A.本薪) 本薪,
	sum(A.職務津貼) 職務津貼,
	sum(A.出勤日支) 出勤日支,
	sum(A.出勤津貼) 出勤津貼,
	sum(A.交通津貼) 交通津貼,
	sum(A.技術津貼) 技術津貼,
	sum(A.午餐津貼) 午餐津貼,
	sum(A.特休津貼) 特休津貼,
	sum(A.伙食津貼) 伙食津貼,
	sum(A.夜班津貼) 夜班津貼,
	sum(A.大夜津貼) 大夜津貼,
	sum(A.加班費) 加班費,
	sum(A.車馬費) 車馬費,
	sum(A.本月應發金額) 本月應發金額,
	sum(A.事病假薪點) 病假薪點,
	sum(A.遲到早退扣支) 遲到早退扣支,
	sum(A.調補扣支) 調補扣支,
	sum(A.借支) 借支,
	sum(A.自提退休金) 自提退休金,
	sum(A.所得稅) 所得稅,
	sum(A.勞保費) 勞保費,
	sum(A.健保費) 健保費,
	sum(A.二代健保) 二代健保,
	sum(A.加班費一) 加班費一,
	sum(A.加班費二) 加班費二,
	sum(A.實發金額) 實發金額,
	sum(A.上班打卡日) 上班打卡日,
	sum(A.加班計算日薪) 加班計算日薪,
	sum(A.特休計算日薪) 特休計算日薪,
	sum(A.平日前2小時) 日前2小時,
	sum(A.平日前4小時) 平日前4小時,
	sum(A.平日大於4小時) 日大於4小時,
	sum(A.休息日前2小時) 休息日前2小時,
	sum(A.休息日前8小時) 休息日前8小時,
	sum(A.休息日大於8小時) 休息日大於8小時,
	sum(A.例假日前8小時) 假日前8小時,
	sum(A.例假日大於8小時) 例假日大於8小時,
	sum(A.例假日大於10小時) 例假日大於10小時,
	sum(A.例假日補休小時) 例假日補休小時,
	sum(A.國定假日前8小時) 國定假日前8小時,
	sum(A.國定假日大於8小時) 國定假日大於8小時,
	sum(A.國定假日大於10小時) 國定假日大於10小時
From
	HRFIL2006 A
	LEFT Join HRFIL1002A B on B.SYSKEY='EMP'
Where
	substr(A.年月,1,6) <= substr(B.關帳年月,1,6)
Group By
	substr(A.年月,1,4),
	A.員工編號
	);

-- Oracle user_views
CREATE VIEW "VIEWFILM000S" ("條碼", "目前庫位") AS (
SELECT  DISTINCT
	條碼, 
	LAST_VALUE (庫位) OVER (PARTITION BY 條碼 ORDER BY 序號 RANGE BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) as 目前庫位
FROM
	FIL0044
WHERE
  條碼<>' ' AND 庫位<>' '	
);

-- Oracle user_views
CREATE VIEW "VIEWFILM001" ("月份", "倉庫代碼", "材料編號", "異動數量") AS (
SELECT
	substr(A.異動日期,1,6) 月份,
	A.倉庫代碼,
	A.材料編號,
	sum(A.異動數) 異動數量
FROM
	ViewFIL2022 A
GROUP BY
	substr(A.異動日期,1,6),
	A.倉庫代碼,
	A.材料編號);

-- Oracle user_views
CREATE VIEW "VIEWFILM005" ("月份", "庫別代碼", "庫別名稱", "倉別代碼", "倉別名稱", "材料編號", "前期庫存", "本期異動", "期末庫存", "年月序") AS (
SELECT
	A.月份,
	A.倉庫代碼 庫別代碼,
	nvl(B.名稱, ' ') 庫別名稱,
	nvl(B.倉別代碼, ' ') 倉別代碼,
	nvl(C.名稱, ' ') 倉別名稱,
	A.材料編號,
	nvl(A.前期庫存, 0) 前期庫存,
	A.本期異動,
	nvl(A.前期庫存, 0) + A.本期異動 期末庫存,
	row_number() over (partition by A.材料編號, A.倉庫代碼 order by A.月份 desc) as 年月序
FROM
	(	SELECT
			A.月份,
			A.倉庫代碼,
			A.材料編號,
			(	SELECT
					sum(B.異動數量)
				FROM
					ViewFILM001 B
				WHERE
					B.材料編號 = A.材料編號 AND
					B.倉庫代碼 = A.倉庫代碼 AND
					B.月份 < A.月份
			)	前期庫存,
			A.異動數量 本期異動
		FROM
			ViewFILM001 A
	) A
	LEFT JOIN ViewFIL3106 B ON A.倉庫代碼 = B.代碼
	LEFT JOIN ViewFIL310R C ON B.倉別代碼 = C.代碼);

-- Oracle user_views
CREATE VIEW "VIEWFILM006" ("材料編號", "庫存數") AS (
SELECT
	A.材料編號,
	sum(A.異動數) 庫存數
FROM
	ViewFIL2022 A
GROUP BY
	A.材料編號);

-- Oracle user_views
CREATE VIEW "VIEWFILM006A" ("材料編號", "庫存數") AS (
SELECT
	A.材料編號,
	sum(A.庫存數) 庫存數
FROM
	ViewFILM017A A
GROUP BY
	A.材料編號);

-- Oracle user_views
CREATE VIEW "VIEWFILM007" ("材料編號", "庫別代碼", "庫別名稱", "倉別代碼", "倉別名稱", "庫存數") AS (
SELECT
	A.材料編號,
	A.庫別代碼,
	nvl(B.名稱, ' ') 庫別名稱,
	nvl(B.倉別代碼, ' ') 倉別代碼,
	nvl(C.名稱, ' ') 倉別名稱,
	A.庫存數
FROM
	(	SELECT
			A.材料編號,
			A.倉庫代碼 庫別代碼,
			sum(A.異動數) 庫存數
		FROM
			ViewFIL2022 A
		GROUP BY
			A.材料編號,
			A.倉庫代碼
	) A
	LEFT JOIN ViewFIL3106 B ON A.庫別代碼 = B.代碼
	LEFT JOIN ViewFIL310R C ON B.倉別代碼 = C.代碼);

-- Oracle user_views
CREATE VIEW "VIEWFILM007A" ("材料編號", "庫別代碼", "庫別名稱", "倉別代碼", "倉別名稱", "庫存數") AS (
SELECT 
	A.材料編號,
	A.倉庫代碼 庫別代碼,
	nvl(B.名稱, ' ') 庫別名稱,
	nvl(B.倉別代碼, ' ') 倉別代碼,
	nvl(C.名稱, ' ') 倉別名稱,
	SUM(A.庫存數量) 庫存數
FROM
	(SELECT
		A.倉庫代碼,
		A.材料編號,
		sum(A.異動數量) 庫存數量
	FROM
		ViewFILM011 A
	WHERE
		A.月份 = TO_CHAR(SYSDATE,'yyyymm')
	GROUP BY 
		A.倉庫代碼,
		A.材料編號
		
	union all

	SELECT
		A.倉庫代碼,
		A.材料編號,
		sum(A.庫存數量) 庫存數量
	FROM
		fil5001 A
	WHERE
		A.月份 = TO_CHAR(SYSDATE - interval '1' month,'yyyymm')	
	GROUP BY 
		A.倉庫代碼,
		A.材料編號	
	) A 
	LEFT JOIN ViewFIL3106 B ON A.倉庫代碼 = B.代碼
	LEFT JOIN ViewFIL310R C ON B.倉別代碼 = C.代碼
GROUP BY 
	A.材料編號,
	A.倉庫代碼,
	nvl(B.名稱, ' '),
	nvl(B.倉別代碼, ' '),
	nvl(C.名稱, ' ')
);

-- Oracle user_views
CREATE VIEW "VIEWFILM007_WK" ("材料編號", "庫別代碼", "庫別名稱", "倉別代碼", "倉別名稱", "庫存數") AS (
SELECT
	A.材料編號,
	A.庫別代碼,
	nvl(B.名稱, ' ') 庫別名稱,
	nvl(B.倉別代碼, ' ') 倉別代碼,
	nvl(C.名稱, ' ') 倉別名稱,
	A.庫存數
FROM
	(	SELECT
			A.材料編號,
			A.倉庫代碼 庫別代碼,
			sum(A.異動數) 庫存數
		FROM
			WKFIL2022 A
		GROUP BY
			A.材料編號,
			A.倉庫代碼
	) A
	LEFT JOIN ViewFIL3106 B ON A.庫別代碼 = B.代碼
	LEFT JOIN ViewFIL310R C ON B.倉別代碼 = C.代碼);

-- Oracle user_views
CREATE VIEW "VIEWFILM008" ("材料編號", "庫存數") AS (
SELECT
	A.材料編號,
	sum(CASE WHEN B.批號管理=0 THEN 
			A.庫存數 
		ELSE 	
			(CASE WHEN A.庫存數 <=0 THEN 0 ELSE A.庫存數 END)
		END) 庫存數
FROM
	ViewFILM017 A
	INNER JOIN VIEWFIL1012 B ON A.材料編號 = B.產品編號
GROUP BY
	A.材料編號);

-- Oracle user_views
CREATE VIEW "VIEWFILM008A" ("材料編號", "庫存數") AS (
SELECT
	A.材料編號,
	sum(CASE WHEN B.批號管理=0 THEN 
			A.庫存數 
		ELSE 	
			(CASE WHEN A.庫存數 <=0 THEN 0 ELSE A.庫存數 END)
		END) 庫存數
FROM
	ViewFILM017A A
	INNER JOIN VIEWFIL1012 B ON A.材料編號 = B.產品編號
GROUP BY
	A.材料編號);

-- Oracle user_views
CREATE VIEW "VIEWFILM008H" ("製令單別", "製令單號", "加工別", "製程代碼", "半成品編號", "庫存數") AS (
SELECT
	to_char('C11')製令單別,
	regexp_substr (A.批號, '[^_]+', 1) 製令單號,
	regexp_substr (A.批號, '[A-Z]+',1) 加工別,
	regexp_substr(A.批號, '[A-Z][0-9][0-9][A-Z]') 製程代碼,
	A.批號 半成品編號,
	sum(nvl(A.異動數,0)) 庫存數
FROM
	(	SELECT 
			A.批號,
			A.異動數
		FROM 
			ViewFILM018H A
	) A	
GROUP BY
	to_char('C11'),
	regexp_substr (A.批號, '[^_]+', 1),
	regexp_substr (A.批號, '[A-Z]+',1),
	regexp_substr(A.批號, '[A-Z][0-9][0-9][A-Z]'),
	A.批號
	);

-- Oracle user_views
CREATE VIEW "VIEWFILM008H_WK" ("製令單別", "製令單號", "加工別", "製程代碼", "半成品編號", "庫存數") AS (
SELECT
	to_char('C11')製令單別,
	regexp_substr (A.批號, '[^_]+', 1) 製令單號,
	regexp_substr (A.批號, '[A-Z]+',1) 加工別,
	regexp_substr(A.批號, '[A-Z][0-9][0-9][A-Z]') 製程代碼,
	A.批號 半成品編號,
	sum(nvl(A.異動數,0)) 庫存數
FROM
	(	SELECT 
			A.批號,
			A.異動數
		FROM 
			WKFILM018H A
	) A	
GROUP BY
	to_char('C11'),
	regexp_substr (A.批號, '[^_]+', 1),
	regexp_substr (A.批號, '[A-Z]+',1),
	regexp_substr(A.批號, '[A-Z][0-9][0-9][A-Z]'),
	A.批號
	);

-- Oracle user_views
CREATE VIEW "VIEWFILM008S" ("材料編號", "品名", "規格", "庫存數") AS (
SELECT
	A.料號 材料編號,
	E.品名,
	E.規格,
	A.庫存數
FROM
	(
	SELECT 
	  F.料號,
	  SUM(greatest(NVL(A.庫存數,0),0)) 庫存數
	FROM 
	  ViewFILM017SA A	
	  INNER JOIN FIL0043 F ON F.條碼 = A.批號
	GROUP BY
	  F.料號
	) A	
	INNER JOIN FIL0012 E ON E.產品編號 = A.料號
	);

-- Oracle user_views
CREATE VIEW "VIEWFILM008SA" ("材料編號", "品名", "規格", "庫位", "庫存數") AS (
SELECT
	A.料號 材料編號,
	E.品名,
	E.規格,
	A.庫位,
	sum(nvl(A.異動數,0)) 庫存數
FROM
	(	SELECT 
			A.批號,
			A.料號,
			NVL(G.目前庫位,' ') 庫位,
			A.異動數
		FROM 
			ViewFILM018S A
			INNER JOIN VIEWFILM000S G ON G.條碼 = A.批號
	) A	
	INNER JOIN ViewFIL1012 E ON A.料號 = E.產品編號
GROUP BY
	A.料號,
	E.品名,
	E.規格,
	A.庫位
	);

-- Oracle user_views
CREATE VIEW "VIEWFILM008SC" ("材料編號", "品名", "規格", "庫存數") AS with temp1 as (
SELECT 
	A.產品編號 材料編號,
	SUM(decode(A.單據類別,'D21',A.數值4,(A.異動數量 + A.贈品數量) * B.材料庫存參數)) 異動數
FROM 
	FIL0040 A
	/*庫存參數*/
	INNER JOIN ViewFIL0020 B ON A.單據類別 = B.單據類別 AND B.材料庫存參數 != 0
	/*主檔*/
	INNER JOIN FIL0030 D ON A.單據類別 = D.單據類別 AND A.單據編號 = D.單據編號
	/*品號檔*/
	INNER JOIN FIL0012 C ON A.產品編號 = C.產品編號 AND C.物料大類 between 'B10' and 'B20' AND decode(A.異動日期, '00000000', D.單據日期, A.異動日期) >= C.盤點日期
	/*簽核*/
	LEFT JOIN ViewOfObjProperties H ON H.單據流水號 = D.流水編號
WHERE
	A.產品編號 != ' ' and
	(A.單據類別 = 'D21' and A.異動類別='A' or A.單據類別 <> 'D21') and
	NVL(H.簽核狀態,' ')<>'A'
GROUP BY
	A.產品編號
	
UNION ALL

/*領料*/
SELECT 
	A.產品編號 材料編號,
	SUM(A.異動數量) 異動數
FROM 
	FIL0040 A
	INNER JOIN FIL0041 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號 AND A.單據序號 = C.序號
	INNER JOIN FIL0031 D ON A.單據類別 = D.單別 AND A.單據編號 = D.單號
	INNER JOIN FIL0030 E ON A.單據類別 = E.單據類別 AND A.單據編號 = E.單據編號
	LEFT JOIN ViewFIL310P F ON D.機台代碼 = F.代碼
	INNER JOIN FIL0012 G ON A.產品編號 = G.產品編號 AND G.物料大類 between 'B10' and 'B20' AND  A.異動日期 >= G.盤點日期
WHERE
	A.單據類別 = 'C4M' AND
	A.產品編號 != ' '
GROUP BY
	A.產品編號

UNION ALL

/*材料領用,報廢,油墨領用*/
SELECT 
	A.產品編號 材料編號,
	SUM(A.異動數量 * -1) 異動數
FROM 
	FIL0040 A
	INNER JOIN FIL0041 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號 AND A.單據序號 = B.序號
	INNER JOIN FIL0031 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號
	INNER JOIN FIL0030 C1 ON A.單據類別 = C1.單據類別 AND A.單據編號 = C1.單據編號
	INNER JOIN FIL0012 D ON A.產品編號 = D.產品編號 AND D.物料大類 between 'B10' and 'B20' AND  A.異動日期 >= D.盤點日期
WHERE
	A.單據類別 = 'C41' AND
	A.異動類別 between 'C' and 'E' AND
	A.異動數量 != 0 AND
	A.產品編號 != ' '
GROUP BY
	A.產品編號
	
UNION ALL

/*印刷日報領用*/
SELECT 
	to_char(A.前製程編號) 材料編號,
	SUM((A.異動數量-A.退庫數量) * -1) 異動數
FROM 
	FIL0040 A
	INNER JOIN FIL0041 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號 AND A.單據序號 = B.序號
	INNER JOIN FIL0031 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號
	INNER JOIN FIL0030 C1 ON A.單據類別 = C1.單據類別 AND A.單據編號 = C1.單據編號
	INNER JOIN FIL0012 D ON to_char(A.前製程編號) = D.產品編號 AND D.物料大類 between 'B10' and 'B20'  AND  A.異動日期 >= D.盤點日期
WHERE
	A.單據類別 = 'C41' AND
	A.異動數量 > 0 AND
	C.製程代碼 = 'C31A' AND 
	A.前製程編號 != ' '
GROUP BY
	to_char(A.前製程編號)
	
UNION ALL

/*材料領用.氣閥.鐵條-批號1*/
SELECT 
	D.料號 材料編號,
	SUM(B.數值1 * -1) 異動數
FROM 
	FIL0040 A
	INNER JOIN FIL0041 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號 AND A.單據序號 = B.序號
	INNER JOIN FIL0031 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號
	INNER JOIN FIL0030 C1 ON A.單據類別 = C1.單據類別 AND A.單據編號 = C1.單據編號
	INNER JOIN ViewFIL1024 D ON B.文數字1 = D.條碼
	INNER JOIN FIL0012 E ON D.料號 = E.產品編號 AND E.物料大類 between 'B10' and 'B20' AND  A.異動日期 >= E.盤點日期
WHERE
	A.單據類別 = 'C41' AND
	A.異動類別 = 'A' AND
	C.製程代碼 between 'C31F' and 'C31G' AND
	B.文數字1 != ' ' AND
	D.料號 != ' '
GROUP BY
	D.料號

UNION ALL
	
/*材料領用.氣閥.鐵條-批號2*/
SELECT 
	D.料號 材料編號,
	SUM(B.數值2 * -1) 異動數
FROM 
	FIL0040 A
	INNER JOIN FIL0041 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號 AND A.單據序號 = B.序號
	INNER JOIN FIL0031 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號
	INNER JOIN FIL0030 C1 ON A.單據類別 = C1.單據類別 AND A.單據編號 = C1.單據編號
	INNER JOIN ViewFIL1024 D ON B.文數字2 = D.條碼
	INNER JOIN FIL0012 E ON D.料號 = E.產品編號 AND E.物料大類 between 'B10' and 'B20' AND  A.異動日期 >= E.盤點日期
WHERE
	A.單據類別 = 'C41' AND
	A.異動類別 = 'A' AND
	C.製程代碼 between 'C31F' and 'C31G' AND
	B.文數字2 != ' ' AND
	D.料號 != ' '
GROUP BY
	D.料號
	
UNION ALL

/*發料回庫(-)
SELECT 
	A.產品編號 材料編號,
	SUM(A.贈品數量 * -1) 異動數
FROM 
	FIL0040 A
	INNER JOIN FIL0041 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號 AND A.單據序號 = B.序號
	INNER JOIN FIL0012 C ON A.產品編號 = C.產品編號 AND C.物料大類 between 'B10' and 'B20' AND  A.異動日期 >= C.盤點日期
	LEFT JOIN FIL0043 G ON B.批號 = G.條碼
WHERE
	A.單據類別 = 'C41' AND
	A.異動類別 = 'C' AND
	A.贈品數量 != 0 AND
	A.產品編號 != ' '
GROUP BY
	A.產品編號

UNION ALL
*/

/*發料回庫(+)*/
SELECT 
	A.產品編號 材料編號,
	SUM(A.贈品數量 * 1) 異動數
FROM 
	FIL0040 A
	INNER JOIN FIL0041 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號 AND A.單據序號 = B.序號
	INNER JOIN FIL0012 C ON A.產品編號 = C.產品編號 AND C.物料大類 between 'B10' and 'B20' AND  A.異動日期 >= C.盤點日期
WHERE
	A.單據類別 = 'C41' AND
	A.異動類別 = 'C' AND
	A.贈品數量 != 0 AND
	A.產品編號 != ' '
GROUP BY
	A.產品編號
	
/*廠內盤點調整*/
UNION ALL

SELECT 
	A.產品編號 材料編號,
	SUM((A.異動數量 + A.贈品數量)) 異動數
FROM 
	FIL0040 A
	INNER JOIN FIL0030 B ON A.單據類別 = B.單據類別 AND A.單據編號 = B.單據編號
	/*特殊欄位*/
	INNER JOIN FIL0041 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號 AND A.單據序號 = C.序號
	INNER JOIN FIL0012 E ON A.產品編號 = E.產品編號 AND E.物料大類 between 'B10' and 'B20' AND  A.異動日期 >= E.盤點日期
WHERE
	A.單據類別 = 'F32' AND
	A.異動類別 = '2'
GROUP BY
	A.產品編號
	)
select 
	E.產品編號 材料編號,
	E.品名,
	E.規格,
	SUM(nvl(A.異動數,0))+MAX(nvl(E.盤存數量,0)) 庫存數
from 
	FIL0012 E
	left join temp1 A ON A.材料編號 = E.產品編號
where
  E.物料大類 between 'B10' and 'B20'
GROUP BY
	E.產品編號,
	E.品名,
	E.規格;

-- Oracle user_views
CREATE VIEW "VIEWFILM008S_WK" ("材料編號", "品名", "規格", "庫存數") AS (
SELECT
	A.料號 材料編號,
	E.品名,
	E.規格,
	A.庫存數
FROM
	(
	SELECT 
	  F.料號,
	  SUM(NVL(A.庫存數,0)) 庫存數
	FROM 
	  WKFILM017S A	
	  INNER JOIN FIL0043 F ON F.條碼 = A.批號
	GROUP BY
	  F.料號
	) A	
	INNER JOIN FIL0012 E ON E.產品編號 = A.料號
	);

-- Oracle user_views
CREATE VIEW "VIEWFILM011" ("月份", "倉庫代碼", "材料編號", "批號", "異動數量") AS (
SELECT
	substr(A.異動日期,1,6) 月份,
	A.倉庫代碼,
	A.材料編號,
	A.批號,
	sum(A.異動數) 異動數量
FROM
	ViewFIL2022 A
WHERE
	A.批號 != ' '
GROUP BY
	substr(A.異動日期,1,6),
	A.倉庫代碼,
	A.材料編號,
	A.批號);

-- Oracle user_views
CREATE VIEW "VIEWFILM015" ("月份", "倉庫代碼", "倉庫名稱", "倉別代碼", "倉別名稱", "材料編號", "批號", "前期庫存", "本期異動", "期末庫存", "年月序") AS (
SELECT
	A.月份,
	A.倉庫代碼,
	nvl(B.名稱, ' ') 倉庫名稱,
	nvl(B.倉別代碼, ' ') 倉別代碼,
	nvl(B.倉別名稱, ' ') 倉別名稱,
	A.材料編號,
	A.批號,
	nvl(A.前期庫存, 0) 前期庫存,
	A.本期異動,
	nvl(A.前期庫存, 0) + A.本期異動 期末庫存,
	row_number() over (partition by A.材料編號, A.批號, A.倉庫代碼 order by A.月份 desc) as 年月序
FROM
	(	SELECT
			A.月份,
			A.倉庫代碼,
			A.材料編號,
			A.批號,
			(	SELECT
					sum(B.異動數量)
				FROM
					ViewFILM011 B
				WHERE
					B.材料編號 = A.材料編號 AND
					B.批號 = A.批號 AND
					B.倉庫代碼 = A.倉庫代碼 AND
					B.月份 < A.月份
			)	前期庫存,
			A.異動數量 本期異動
		FROM
			ViewFILM011 A
	) A
	LEFT JOIN ViewFIL3106 B ON A.倉庫代碼 = B.代碼);

-- Oracle user_views
CREATE VIEW "VIEWFILM016" ("批號", "庫存數") AS (
SELECT
	A.批號,
	sum(A.異動數) 庫存數
FROM
	(	SELECT 
			C.批號,
			decode(A.單據類別,'D21',A.數值4,(A.異動數量 + A.贈品數量)) * B.材料庫存參數 異動數
		FROM 
			FIL0040 A
			/*庫存參數*/
			INNER JOIN ViewFIL0020 B ON A.單據類別 = B.單據類別 AND B.材料庫存參數 != 0
			/*特殊欄位*/
			INNER JOIN FIL0041 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號 AND A.單據序號 = C.序號
			/*單位換算
			LEFT JOIN FIL0012 E ON A.產品編號 = E.產品編號
			LEFT JOIN ViewFIL1017 F ON A.單位代碼 = F.從 AND E.單位代碼 = F.到
			*/
		WHERE
			C.批號 != ' '
			
		union all

		/*發料*/
		SELECT 
			C.批號,
			A.異動數量 異動數
		FROM 
			FIL0040 A
			INNER JOIN FIL0041 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號 AND A.單據序號 = C.序號
			/*單位換算
			LEFT JOIN FIL0012 G ON A.產品編號 = G.產品編號
			LEFT JOIN ViewFIL1017 H ON A.單位代碼 = H.從 AND G.單位代碼 = H.到
			*/
		WHERE
			A.單據類別 = 'C4M' AND
			C.批號 != ' '
			
		union all
		
		/*材料領用,報廢,油墨領用*/
		SELECT 
			B.批號,
			A.異動數量 * -1 異動數
		FROM 
			FIL0040 A
			INNER JOIN FIL0041 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號 AND A.單據序號 = B.序號
			/*單位換算
			LEFT JOIN FIL0012 C ON A.產品編號 = C.產品編號
			LEFT JOIN ViewFIL1017 E ON A.單位代碼 = E.從 AND C.單位代碼 = E.到
			*/
		WHERE
			A.單據類別 = 'C41' AND
			A.異動類別 between 'C' and 'E' AND
			A.異動數量 != 0 AND
			B.批號 != ' '
		
		union all
		
		/*材料領用.氣閥.鐵條-批號1*/
		SELECT 
			B.文數字1 批號,
			B.數值1 * -1 異動數
		FROM 
			FIL0040 A
			INNER JOIN FIL0041 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號 AND A.單據序號 = B.序號
			INNER JOIN FIL0031 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號
		WHERE
			A.單據類別 = 'C41' AND
			A.異動類別 = 'A' AND
			C.製程代碼 between 'C31F' and 'C31G' AND
			B.文數字1 != ' '

		UNION ALL
		
		/*材料領用.氣閥.鐵條-批號2*/
		SELECT 
			B.文數字2 批號,
			B.數值2 * -1 異動數
		FROM 
			FIL0040 A
			INNER JOIN FIL0041 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號 AND A.單據序號 = B.序號
			INNER JOIN FIL0031 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號
		WHERE
			A.單據類別 = 'C41' AND
			A.異動類別 = 'A' AND
			C.製程代碼 between 'C31F' and 'C31G' AND
			B.文數字2 != ' '	
		
		union all
		
		/*發料回庫(+)*/
		SELECT 
			B.批號,
			A.贈品數量 * 1 異動數
		FROM 
			FIL0040 A
			INNER JOIN FIL0041 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號 AND A.單據序號 = B.序號
			/*單位換算
			LEFT JOIN FIL0012 C ON A.產品編號 = C.產品編號
			LEFT JOIN ViewFIL1017 E ON A.單位代碼 = E.從 AND C.單位代碼 = E.到
			*/
		WHERE
			A.單據類別 = 'C41' AND
			A.異動類別 = 'C' AND
			A.贈品數量 != 0
		
		/*廠內盤點調整*/
		union all
		
		SELECT 
			C.批號,
			(A.異動數量 + A.贈品數量) 異動數
		FROM 
			FIL0040 A
			INNER JOIN FIL0030 B ON A.單據類別 = B.單據類別 AND A.單據編號 = B.單據編號
			/*特殊欄位*/
			INNER JOIN FIL0041 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號 AND A.單據序號 = C.序號
		WHERE
			A.單據類別 = 'F32' AND
			A.異動類別 = '2'
	) A
GROUP BY
	A.批號);

-- Oracle user_views
CREATE VIEW "VIEWFILM016A" ("批號", "庫存數") AS (
SELECT 
	A.批號,
	SUM(A.庫存數量) 庫存數
FROM
	(SELECT
		A.批號,
		sum(A.異動數量) 庫存數量
	FROM
		ViewFILM011 A
	WHERE
		A.月份 = TO_CHAR(SYSDATE,'yyyymm')
	GROUP BY 
		A.批號
		
	union all

	SELECT
		A.批號,
		SUM(A.庫存數量)
	FROM
		fil5002 A
	WHERE
		A.月份 = TO_CHAR(SYSDATE - interval '1' month,'yyyymm')
	GROUP BY 
		A.批號
	) A 
GROUP BY 
	A.批號
);

-- Oracle user_views
CREATE VIEW "VIEWFILM017" ("材料編號", "物料大類", "品名", "規格", "批號", "庫存數") AS (
SELECT
	A.產品編號 材料編號,
	E.物料大類,
	E.品名,
	E.規格,
	DECODE(E.批號管理,0,'',A.批號) 批號,
	sum(nvl(A.異動數,0)) 庫存數
FROM
	(	SELECT 
			A.產品編號,
			C.批號,
			decode(A.單據類別,'D21',A.數值4,(A.異動數量 + A.贈品數量)) * B.材料庫存參數 異動數
		FROM 
			FIL0040 A
			/*庫存參數*/
			INNER JOIN ViewFIL0020 B ON A.單據類別 = B.單據類別 AND B.材料庫存參數 != 0
			/*特殊欄位*/
			LEFT JOIN FIL0041 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號 AND A.單據序號 = C.序號
			INNER JOIN FIL0030 D ON A.單據類別 = D.單據類別 AND A.單據編號 = D.單據編號
			LEFT JOIN FIL0012 E ON A.產品編號 = E.產品編號
			/*單位換算
			LEFT JOIN ViewFIL1017 F ON A.單位代碼 = F.從 AND E.單位代碼 = F.到
			*/
			/*簽核*/
			LEFT JOIN ViewOfObjProperties H ON H.單據流水號 = D.流水編號
		WHERE
			A.產品編號 != ' ' AND
			DECODE(E.批號管理,0,'不分批號',C.批號) != ' ' and 
			NVL(H.簽核狀態,' ')<>'A' and 
			Decode(A.單據類別,'D21',decode(A.異動類別,'A',0,1),0)=0
			
		union all

		/*發料*/
		SELECT 
			A.產品編號,
			C.批號,
			A.異動數量 異動數
		FROM 
			FIL0040 A
			INNER JOIN FIL0041 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號 AND A.單據序號 = C.序號
			LEFT JOIN FIL0012 G ON A.產品編號 = G.產品編號
			/*單位換算
			LEFT JOIN ViewFIL1017 H ON A.單位代碼 = H.從 AND G.單位代碼 = H.到
			*/
		WHERE
			A.單據類別 = 'C4M' AND
			A.產品編號 != ' ' AND
			DECODE(G.批號管理,0,'不分批號',C.批號) != ' '
			
		union all
		
		/*材料領用,報廢,油墨領用*/
		SELECT 
			A.產品編號,
			B.批號,
			A.異動數量 * -1 異動數
		FROM 
			FIL0040 A
			INNER JOIN FIL0041 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號 AND A.單據序號 = B.序號
			LEFT JOIN FIL0012 C ON A.產品編號 = C.產品編號
			/*單位換算
			LEFT JOIN ViewFIL1017 E ON A.單位代碼 = E.從 AND C.單位代碼 = E.到
			*/
		WHERE
			A.單據類別 = 'C41' AND
			A.異動類別 between 'C' and 'E' AND
			A.異動數量 != 0 AND
			A.產品編號 != ' ' AND
			DECODE(C.批號管理,0,'不分批號',B.批號) != ' '
		
		union all
		
		/*材料領用.氣閥.鐵條-批號1*/
		SELECT 
			E.料號,
			B.文數字1 批號,
			B.數值1 * -1 異動數
		FROM 
			FIL0040 A
			INNER JOIN FIL0041 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號 AND A.單據序號 = B.序號
			INNER JOIN FIL0031 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號
			INNER JOIN ViewFIL1024 E ON B.文數字1 = E.條碼
		WHERE
			A.單據類別 = 'C41' AND
			A.異動類別 = 'A' AND
			C.製程代碼 between 'C31F' and 'C31G' AND
			B.文數字1 != ' '

		UNION all
		
		/*材料領用.氣閥.鐵條-批號2*/
		SELECT 
			E.料號,
			B.文數字2 批號,
			B.數值2 * -1 異動數
		FROM 
			FIL0040 A
			INNER JOIN FIL0041 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號 AND A.單據序號 = B.序號
			INNER JOIN FIL0031 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號
			INNER JOIN ViewFIL1024 E ON B.文數字2 = E.條碼
		WHERE
			A.單據類別 = 'C41' AND
			A.異動類別 = 'A' AND
			C.製程代碼 between 'C31F' and 'C31G' AND
			B.文數字2 != ' '	
		
		union all

		/*發料回庫(+)*/
		SELECT 
			A.產品編號,
			B.批號,
			A.贈品數量 異動數
		FROM 
			FIL0040 A
			INNER JOIN FIL0041 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號 AND A.單據序號 = B.序號
			/*單位換算
			LEFT JOIN FIL0012 C ON A.產品編號 = C.產品編號
			LEFT JOIN ViewFIL1017 E ON A.單位代碼 = E.從 AND C.單位代碼 = E.到
			*/
		WHERE
			A.單據類別 = 'C41' AND
			A.異動類別 = 'C' AND
			A.贈品數量 != 0
			
		/*廠內盤點調整*/
		union all
		
		SELECT
			A.產品編號,
			C.批號,
			(A.異動數量 + A.贈品數量) 異動數
		FROM 
			FIL0040 A
			INNER JOIN FIL0030 B ON A.單據類別 = B.單據類別 AND A.單據編號 = B.單據編號
			/*特殊欄位*/
			INNER JOIN FIL0041 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號 AND A.單據序號 = C.序號
		WHERE
			A.單據類別 = 'F32' AND
			A.異動類別 = '2'
	) A
	INNER JOIN FIL0012 E ON A.產品編號 = E.產品編號	
GROUP BY
	A.產品編號,
	E.物料大類,
	E.品名,
	E.規格,
	DECODE(E.批號管理,0,'',A.批號));

-- Oracle user_views
CREATE VIEW "VIEWFILM017A" ("材料編號", "物料大類", "品名", "規格", "批號", "庫存數") AS (
SELECT 
	A.材料編號,
	E.物料大類,
	E.品名,
	E.規格,
	DECODE(E.批號管理,0,'',A.批號) 批號,
	SUM(A.庫存數量) 庫存數
FROM
	(SELECT
		A.材料編號,
		A.批號,
		sum(A.異動數量) 庫存數量
	FROM
		ViewFILM011 A
	WHERE
		A.月份 = TO_CHAR(SYSDATE,'yyyymm')
	GROUP BY 
		A.材料編號,
		A.批號
		
	union all

	SELECT
		A.材料編號,
		A.批號,
		sum(A.庫存數量)
	FROM
		fil5002 A
	WHERE
		A.月份 = TO_CHAR(SYSDATE - interval '1' month,'yyyymm')	
	GROUP BY 
		A.材料編號,
		A.批號
	) A 
	INNER JOIN ViewFIL1012 E ON A.材料編號 = E.產品編號	
GROUP BY 
	A.材料編號,
	E.物料大類,
	E.品名,
	E.規格,
	DECODE(E.批號管理,0,'',A.批號)
);

-- Oracle user_views
CREATE VIEW "VIEWFILM017H" ("製令單號", "產品編號", "產品名稱", "批號", "廠客編號", "接頭數", "圓周", "規格", "熟成條件", "庫存數") AS (
SELECT
	F.製令單號,
	E.產品編號,
	E.產品名稱,
	A.批號,
	F.廠客 廠客編號,
	max(A.接頭數) 接頭數,
	max(A.圓周) 圓周,
	max(A.規格) 規格,
	MAX(A.熟成條件) 熟成條件,
	sum(nvl(A.異動數,0)) 庫存數
FROM
	(	
		SELECT 
			A.批號,
			A.最後接頭數 接頭數,
			A.圓周,
			A.規格,
			A.熟成條件,
			A.異動數
		FROM 
			ViewFILM018H A			
		
	) A	
	INNER JOIN ViewFIL1024 F ON F.條碼 = A.批號 AND INSTR(F.條碼,'^')>0 
	INNER JOIN FIL0032 E ON E.製令單號 = F.製令單號
GROUP BY
	F.製令單號,
	E.產品編號,
	E.產品名稱,
	A.批號,
	F.廠客
	);

-- Oracle user_views
CREATE VIEW "VIEWFILM017S" ("材料編號", "物料大類", "品名", "規格", "批號", "廠客編號", "庫存數") AS (
SELECT
	F.料號 材料編號,
	E.物料大類,
	E.品名,
	E.規格,
	A.批號,
	F.廠客 廠客編號,
	greatest(sum(nvl(A.異動數,0)),0) 庫存數
FROM
	(	/*期初庫存*/
		SELECT
			A.條碼 批號,
			A.庫存結算數 異動數
		FROM
			FIL0043 A
		
		UNION ALL
		/*盤點調整*/
		SELECT 
			C.批號,
			(A.異動數量 + A.贈品數量) 異動數
		FROM 
			FIL0040 A
			/*特殊欄位*/
			INNER JOIN FIL0041 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號 AND A.單據序號 = C.序號
			INNER JOIN FIL0043 F ON F.條碼 = C.批號
		WHERE
			A.單據類別 = 'F32' AND 
			C.批號 != ' '  and 
			A.異動日期 >= F.結算日期
		
		UNION ALL
		
		/*驗收/入庫/調整/退出*/
		SELECT 
			C.批號,
			decode(A.單據類別,'D21',A.數值4,'E12',A.數值2,'E13',A.數值2,(A.異動數量 + A.贈品數量)) 異動數
		FROM 
			FIL0040 A
			/*特殊欄位*/
			INNER JOIN FIL0041 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號 AND A.單據序號 = C.序號
			INNER JOIN FIL0030 B ON A.單據類別 = B.單據類別 AND A.單據編號 = B.單據編號
			INNER JOIN FIL0043 F ON F.條碼 = C.批號
			LEFT JOIN ViewOfObjProperties D ON D.單據流水號 = B.流水編號
		WHERE
			A.入料註記 = 1 AND
			A.產品編號 != ' ' AND
			C.批號 != ' ' and
			NVL(D.簽核狀態,' ')<>'A' and 
			A.異動日期 >= F.結算日期
			
		UNION ALL
		/*前製程日報領料*/
		SELECT 
			to_char(C.文數字4) 批號,
			(A.異動數量)*-1 異動數	
		FROM 
			FIL0040 A
			INNER JOIN FIL0030 B ON A.單據類別 = B.單據類別 AND A.單據編號 = B.單據編號
			/*特殊欄位*/
			INNER JOIN FIL0041 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號 AND A.單據序號 = C.序號
			INNER JOIN FIL0031 D ON A.單據類別 = D.單別 AND A.單據編號 = D.單號
			INNER JOIN FIL0043 F ON F.條碼 = to_char(C.文數字4)
		WHERE
			A.單據類別 = 'C41' AND
			((D.製程代碼 BETWEEN 'C31A' AND 'C31C') OR D.製程代碼 = 'C32D' OR D.製程代碼 = 'C31H' OR D.製程代碼 = 'C31K') AND
			C.文數字4 != ' '	 and 
			A.異動數量 > 0 and
			B.單據日期 >= F.結算日期				
	
		UNION ALL
		/*前製程日報退庫*/
		SELECT 
			to_char(C.文數字4) 批號,
			A.退庫數量 異動數	
		FROM 
			FIL0040 A
			INNER JOIN FIL0030 B ON A.單據類別 = B.單據類別 AND A.單據編號 = B.單據編號
			/*特殊欄位*/
			INNER JOIN FIL0041 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號 AND A.單據序號 = C.序號
			INNER JOIN FIL0031 D ON A.單據類別 = D.單別 AND A.單據編號 = D.單號
			INNER JOIN FIL0043 F ON F.條碼 = to_char(C.文數字4)
		WHERE
			A.單據類別 = 'C41' AND A.單據序號 < 500 AND
			(D.製程代碼 = 'C31B' or  D.製程代碼 = 'C31C' OR D.製程代碼 = 'C32D' OR D.製程代碼 = 'C31H' OR D.製程代碼 = 'C31K') AND
			C.文數字4 != ' '	 AND
			A.退庫數量 > 0 AND
			B.單據日期 >= F.結算日期	
	
		UNION ALL
		/*前製程日報領用退庫*/
		SELECT 
			to_char(C.文數字4) 批號,
			A.退庫數量 異動數	
		FROM 
			FIL0040 A
			INNER JOIN FIL0030 B ON A.單據類別 = B.單據類別 AND A.單據編號 = B.單據編號
			/*特殊欄位*/
			INNER JOIN FIL0041 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號 AND A.單據序號 = C.序號
			INNER JOIN FIL0031 D ON A.單據類別 = D.單別 AND A.單據編號 = D.單號
			INNER JOIN FIL0043 F ON F.條碼 = to_char(C.文數字4)
		WHERE
			A.單據類別 = 'C41' AND A.單據序號 >=500 AND
			(D.製程代碼 = 'C31B' or  D.製程代碼 = 'C31C' OR D.製程代碼 = 'C32D' OR D.製程代碼 = 'C31H' OR D.製程代碼 = 'C31K') AND
			C.文數字4 != ' '	 and 
			A.Logical1 = 0 AND
			A.退庫數量 > 0 AND
			B.單據日期 >= F.結算日期			
			
		UNION ALL
		/*印刷日報退庫*/
		SELECT 
			to_char(C.文數字4) 批號,
			A.退庫數量 異動數	
		FROM 
			FIL0040 A
			INNER JOIN FIL0030 B ON A.單據類別 = B.單據類別 AND A.單據編號 = B.單據編號
			/*特殊欄位*/
			INNER JOIN FIL0041 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號 AND A.單據序號 = C.序號
			INNER JOIN FIL0031 D ON A.單據類別 = D.單別 AND A.單據編號 = D.單號
			INNER JOIN FIL0043 F ON F.條碼 = to_char(C.文數字4)
		WHERE
			A.單據類別 = 'C41' AND
			D.製程代碼 = 'C31A' AND 
			to_char(C.文數字4) != ' ' and 
			A.退庫數量 > 0 AND
			B.單據日期 >= F.結算日期												
			
		UNION ALL 
		/*製袋主頁領料*/
		SELECT 
			A.批號,
			A.異動數*-1 異動數
		FROM 
			ViewFILM018A A	
			INNER JOIN FIL0043 F ON F.條碼 = A.批號
		WHERE 
			A.單據日期 >= F.結算日期		
			
		UNION ALL
		/*退庫*/
		SELECT 
			C.批號,
			decode(A.單據類別,'D52',A.數值4,(A.異動數量 + A.贈品數量))*-1 異動數
		FROM 
			FIL0040 A
			/*特殊欄位*/
			INNER JOIN FIL0041 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號 AND A.單據序號 = C.序號
			INNER JOIN FIL0043 F ON F.條碼 = C.批號
		WHERE
			A.退料註記 = 1 AND
			A.產品編號 != ' ' AND
			C.批號 != ' ' and 
			A.異動日期 >= F.結算日期
				
		UNION ALL 
			/*裁切材料領用*/
		SELECT 
			A.廠客單號 批號,
			A.折讓*-1 異動數 
		FROM 
			FIL0030 A
			/*特殊欄位*/
			INNER JOIN FIL0031 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號 
			LEFT JOIN ViewOfObjProperties D ON D.單據流水號 = A.流水編號
		WHERE
			A.單據類別 ='E13' and
			A.廠客單號 != ' ' and
			A.折讓 > 0 and
			NVL(D.簽核狀態,' ')<>'A'
						
		UNION ALL 
			/*裁切材料退庫*/
		SELECT 
			A.廠客單號 批號,
			C.數值1 異動數
		FROM 
			FIL0030 A
			/*特殊欄位*/
			INNER JOIN FIL0031 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號 
			LEFT JOIN ViewOfObjProperties D ON D.單據流水號 = A.流水編號
		WHERE
			A.單據類別 ='E13' and
			A.廠客單號 != ' ' and
			C.數值1 > 0 and
			NVL(D.簽核狀態,' ')<>'A'
							
		UNION ALL 
			/*氣閥鐵條領用1*/
		SELECT 
			C.文數字1  批號,
			(C.數值1)*-1 異動數
		FROM 
			FIL0040 A
			/*特殊欄位*/
			INNER JOIN FIL0041 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號 AND A.單據序號 = C.序號
			INNER JOIN FIL0031 D ON A.單據類別 = D.單別 AND A.單據編號 = D.單號
			INNER JOIN FIL0043 F ON F.條碼 = C.文數字1
		WHERE
			A.單據類別 = 'C41' AND
			C.數值1 > 0 AND
			D.製程代碼 BETWEEN 'C31F' AND 'C31G' AND 
			A.異動類別 = 'A' AND
			C.文數字1 != ' '	AND
			A.異動日期 >= F.結算日期
				
		UNION ALL 
			/*氣閥鐵條領用2*/
		SELECT 
			C.文數字2  批號,
			(C.數值2)*-1 異動數
		FROM 
			FIL0040 A
			/*特殊欄位*/
			INNER JOIN FIL0041 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號 AND A.單據序號 = C.序號
			INNER JOIN FIL0031 D ON A.單據類別 = D.單別 AND A.單據編號 = D.單號
			INNER JOIN FIL0043 F ON F.條碼 = C.文數字2
		WHERE
			A.單據類別 = 'C41' AND
			C.數值2 > 0 AND
			D.製程代碼 BETWEEN 'C31F' AND 'C31G' AND 
			A.異動類別 = 'A'  AND
			C.文數字2 != ' '	 AND
			A.異動日期 >= F.結算日期
		
		UNION ALL 
			/*材料領用,報廢,油墨領用*/
		SELECT 
			B.批號,
			(A.異動數量-A.退庫數量)*-1
		FROM 
			FIL0040 A
			INNER JOIN FIL0041 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號 AND A.單據序號 = B.序號
			INNER JOIN FIL0031 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號
			INNER JOIN FIL0030 C1 ON A.單據類別 = C1.單據類別 AND A.單據編號 = C1.單據編號
			INNER JOIN FIL0043 F ON F.條碼 = B.批號
		WHERE
			A.單據類別 = 'C41' AND
			A.異動類別 between 'C' and 'E' AND
			A.異動數量 != 0 AND
			B.批號 != ' ' AND
			C1.單據日期 >= F.結算日期	
			
		/*UNION ALL 
		客供品條碼入庫
		SELECT 
			M.條碼,
			M.庫存異動數 異動數
		FROM 
			FIL0043 M
			INNER JOIN FIL0040 A ON A.單據類別 = M.單別 AND A.單據編號 = M.單號 AND A.單據序號 = 序號
			INNER JOIN FIL0030 B ON A.單據類別 = B.單據類別 AND A.單據編號 = B.單據編號
			INNER JOIN FIL0043 F ON F.條碼 = M.條碼
			LEFT JOIN ViewOfObjProperties D ON D.單據流水號 = B.流水編號
		WHERE
			M.單別 = 'D51' and
			NVL(D.簽核狀態,' ')<>'A' and 
			A.異動日期 >= F.結算日期
		*/	
		/*UNION ALL 
			客供品退料
		SELECT 
			C.批號,
			decode(A.單據類別,'D52',A.數值4,(A.異動數量 + A.贈品數量))*-1 異動數
		FROM 
			FIL0040 A
			INNER JOIN FIL0041 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號 AND A.單據序號 = C.序號
			INNER JOIN FIL0030 B ON A.單據類別 = B.單據類別 AND A.單據編號 = B.單據編號
			INNER JOIN FIL0043 F ON F.條碼 = C.批號
			LEFT JOIN ViewOfObjProperties D ON D.單據流水號 = B.流水編號
		WHERE
			A.退料註記 = 1 AND
			A.產品編號 != ' ' and
			NVL(D.簽核狀態,' ')<>'A' and 
			A.異動日期 >= F.結算日期
		*/
	) A	
	INNER JOIN FIL0043 F ON F.條碼 = A.批號
	INNER JOIN ViewFIL1012 E ON F.料號 = E.產品編號
GROUP BY
	F.料號,
	E.物料大類,
	E.品名,
	E.規格,
	A.批號,
	F.廠客
	);

-- Oracle user_views
CREATE VIEW "VIEWFILM017SA" ("批號", "庫存數") AS (
SELECT
	A.批號,
	sum(nvl(A.異動數,0)) 庫存數
FROM
	(	/*期初庫存*/
		SELECT
			A.條碼 批號,
			A.庫存結算數 異動數
		FROM
			FIL0043 A
		
		UNION ALL
		/*盤點調整*/
		SELECT 
			C.批號,
			(A.異動數量 + A.贈品數量) 異動數
		FROM 
			FIL0040 A
			/*特殊欄位*/
			INNER JOIN FIL0041 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號 AND A.單據序號 = C.序號
			INNER JOIN FIL0043 F ON F.條碼 = C.批號
		WHERE
			A.單據類別 = 'F32' AND 
			C.批號 != ' '  and 
			A.異動日期 >= F.結算日期
		
		UNION ALL
		
		/*驗收/入庫/調整/退出*/
		SELECT 
			C.批號,
			decode(A.單據類別,'D21',A.數值4,'E12',A.數值2,'E13',A.數值2,(A.異動數量 + A.贈品數量)) 異動數
		FROM 
			FIL0040 A
			/*特殊欄位*/
			INNER JOIN FIL0041 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號 AND A.單據序號 = C.序號
			INNER JOIN FIL0030 B ON A.單據類別 = B.單據類別 AND A.單據編號 = B.單據編號
			INNER JOIN FIL0043 F ON F.條碼 = C.批號
			LEFT JOIN ViewOfObjProperties D ON D.單據流水號 = B.流水編號
		WHERE
			A.入料註記 = 1 AND
			A.產品編號 != ' ' AND
			C.批號 != ' ' and
			NVL(D.簽核狀態,' ')<>'A' and 
			A.異動日期 >= F.結算日期
			
		UNION ALL
		/*前製程日報領料*/
		SELECT 
			to_char(C.文數字4) 批號,
			(A.異動數量)*-1 異動數	
		FROM 
			FIL0040 A
			INNER JOIN FIL0030 B ON A.單據類別 = B.單據類別 AND A.單據編號 = B.單據編號
			/*特殊欄位*/
			INNER JOIN FIL0041 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號 AND A.單據序號 = C.序號
			INNER JOIN FIL0031 D ON A.單據類別 = D.單別 AND A.單據編號 = D.單號
			INNER JOIN FIL0043 F ON F.條碼 = to_char(C.文數字4)
		WHERE
			A.單據類別 = 'C41' AND
			((D.製程代碼 BETWEEN 'C31A' AND 'C31C') OR D.製程代碼 = 'C32D' OR D.製程代碼 = 'C31H' OR D.製程代碼 = 'C31K') AND
			C.文數字4 != ' '	 and 
			A.異動數量 > 0 and
			B.單據日期 >= F.結算日期				
	
		UNION ALL
		/*前製程日報退庫*/
		SELECT 
			to_char(C.文數字4) 批號,
			A.退庫數量 異動數	
		FROM 
			FIL0040 A
			INNER JOIN FIL0030 B ON A.單據類別 = B.單據類別 AND A.單據編號 = B.單據編號
			/*特殊欄位*/
			INNER JOIN FIL0041 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號 AND A.單據序號 = C.序號
			INNER JOIN FIL0031 D ON A.單據類別 = D.單別 AND A.單據編號 = D.單號
			INNER JOIN FIL0043 F ON F.條碼 = to_char(C.文數字4)
		WHERE
			A.單據類別 = 'C41' AND A.單據序號 < 500 AND
			(D.製程代碼 = 'C31B' or  D.製程代碼 = 'C31C' OR D.製程代碼 = 'C32D' OR D.製程代碼 = 'C31H' OR D.製程代碼 = 'C31K') AND
			C.文數字4 != ' '	 AND
			A.退庫數量 > 0 AND
			B.單據日期 >= F.結算日期	
		
		UNION ALL
		/*前製程日報領用退庫*/
		SELECT 
			to_char(C.文數字4) 批號,
			A.退庫數量 異動數	
		FROM 
			FIL0040 A
			INNER JOIN FIL0030 B ON A.單據類別 = B.單據類別 AND A.單據編號 = B.單據編號
			/*特殊欄位*/
			INNER JOIN FIL0041 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號 AND A.單據序號 = C.序號
			INNER JOIN FIL0031 D ON A.單據類別 = D.單別 AND A.單據編號 = D.單號
			INNER JOIN FIL0043 F ON F.條碼 = to_char(C.文數字4)
		WHERE
			A.單據類別 = 'C41' AND A.單據序號 >=500 AND
			(D.製程代碼 = 'C31B' or  D.製程代碼 = 'C31C' OR D.製程代碼 = 'C32D' OR D.製程代碼 = 'C31H' OR D.製程代碼 = 'C31K') AND
			C.文數字4 != ' '	 and 
			A.Logical1 = 0 AND
			A.退庫數量 > 0 AND
			B.單據日期 >= F.結算日期			

		UNION ALL 
			/*前製程日報沿用*/
		SELECT 
			to_char(C.文數字4) 批號,
			A.退庫數量 異動數
		FROM 
			FIL0040 A
			INNER JOIN FIL0030 B ON A.單據類別 = B.單據類別 AND A.單據編號 = B.單據編號 
			/*特殊欄位*/
			INNER JOIN FIL0041 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號 AND A.單據序號 = C.序號
			INNER JOIN FIL0031 D ON A.單據類別 = D.單別 AND A.單據編號 = D.單號
			INNER JOIN FIL0043 F ON F.條碼 = to_char(C.文數字4)
		WHERE
			A.單據類別 = 'C41' AND
			A.異動類別 = 'C' AND
			A.退庫數量 > 0  AND
			(D.製程代碼 BETWEEN 'C31B' AND 'C31C') AND 
			C.文數字4 != ' '	and
			A.Logical1 = 1 AND
			B.單據日期 >= F.結算日期
				
		UNION ALL
		/*印刷日報退庫*/
		SELECT 
			to_char(C.文數字4) 批號,
			A.退庫數量 異動數	
		FROM 
			FIL0040 A
			INNER JOIN FIL0030 B ON A.單據類別 = B.單據類別 AND A.單據編號 = B.單據編號
			/*特殊欄位*/
			INNER JOIN FIL0041 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號 AND A.單據序號 = C.序號
			INNER JOIN FIL0031 D ON A.單據類別 = D.單別 AND A.單據編號 = D.單號
			INNER JOIN FIL0043 F ON F.條碼 = to_char(C.文數字4)
		WHERE
			A.單據類別 = 'C41' AND
			D.製程代碼 = 'C31A' AND 
			to_char(C.文數字4) != ' ' and 
			A.退庫數量 > 0 AND
			B.單據日期 >= F.結算日期												
			
		UNION ALL 
		/*製袋主頁領料*/
		SELECT 
			A.批號,
			A.異動數*-1 異動數
		FROM 
			ViewFILM018A A	
			INNER JOIN FIL0043 F ON F.條碼 = A.批號
		WHERE 
			A.批號 != ' ' and
			A.單據日期 >= F.結算日期		
			
		UNION ALL
		/*退庫*/
		SELECT 
			C.批號,
			decode(A.單據類別,'D52',A.數值4,(A.異動數量 + A.贈品數量))*-1 異動數
		FROM 
			FIL0040 A
			/*特殊欄位*/
			INNER JOIN FIL0041 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號 AND A.單據序號 = C.序號
			INNER JOIN FIL0043 F ON F.條碼 = C.批號
		WHERE
			A.退料註記 = 1 AND
			A.產品編號 != ' ' AND
			C.批號 != ' ' and 
			A.異動日期 >= F.結算日期
				
		UNION ALL 
			/*氣閥鐵條領用1*/
		SELECT 
			C.文數字1  批號,
			(C.數值1)*-1 異動數
		FROM 
			FIL0040 A
			/*特殊欄位*/
			INNER JOIN FIL0041 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號 AND A.單據序號 = C.序號
			INNER JOIN FIL0031 D ON A.單據類別 = D.單別 AND A.單據編號 = D.單號
			INNER JOIN FIL0043 F ON F.條碼 = C.文數字1
		WHERE
			A.單據類別 = 'C41' AND
			C.數值1 > 0 AND
			D.製程代碼 BETWEEN 'C31F' AND 'C31G' AND 
			A.異動類別 = 'A' AND
			C.文數字1 != ' '	AND
			A.異動日期 >= F.結算日期
						
		UNION ALL 
			/*裁切材料領用*/
		SELECT 
			A.廠客單號 批號,
			A.折讓*-1 異動數 
		FROM 
			FIL0030 A
			/*特殊欄位*/
			INNER JOIN FIL0031 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號 
			LEFT JOIN ViewOfObjProperties D ON D.單據流水號 = A.流水編號
			INNER JOIN FIL0043 F ON F.條碼 = A.廠客單號
		WHERE
			A.單據類別 ='E13' and
			A.廠客單號 != ' ' and
			A.折讓 > 0 and
			NVL(D.簽核狀態,' ')<>'A' and
			A.單據日期 >= F.結算日期
						
		UNION ALL 
			/*裁切材料退庫*/
		SELECT 
			A.廠客單號 批號,
			C.數值1 異動數
		FROM 
			FIL0030 A
			/*特殊欄位*/
			INNER JOIN FIL0031 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號 
			LEFT JOIN ViewOfObjProperties D ON D.單據流水號 = A.流水編號
			INNER JOIN FIL0043 F ON F.條碼 = A.廠客單號
		WHERE
			A.單據類別 ='E13' and
			A.廠客單號 != ' ' and
			C.數值1 > 0 and
			NVL(D.簽核狀態,' ')<>'A'	and
			A.單據日期 >= F.結算日期	
			
		UNION ALL 
			/*氣閥鐵條領用2*/
		SELECT 
			C.文數字2  批號,
			(C.數值2)*-1 異動數
		FROM 
			FIL0040 A
			/*特殊欄位*/
			INNER JOIN FIL0041 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號 AND A.單據序號 = C.序號
			INNER JOIN FIL0031 D ON A.單據類別 = D.單別 AND A.單據編號 = D.單號
			INNER JOIN FIL0043 F ON F.條碼 = C.文數字2
		WHERE
			A.單據類別 = 'C41' AND
			C.數值2 > 0 AND
			D.製程代碼 BETWEEN 'C31F' AND 'C31G' AND 
			A.異動類別 = 'A'  AND
			C.文數字2 != ' '	 AND
			A.異動日期 >= F.結算日期
		
		UNION ALL 
			/*材料領用,報廢,油墨領用*/
		SELECT 
			B.批號,
			(A.異動數量-A.退庫數量)*-1
		FROM 
			FIL0040 A
			INNER JOIN FIL0041 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號 AND A.單據序號 = B.序號
			INNER JOIN FIL0031 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號
			INNER JOIN FIL0030 C1 ON A.單據類別 = C1.單據類別 AND A.單據編號 = C1.單據編號
			INNER JOIN FIL0043 F ON F.條碼 = B.批號
		WHERE
			A.單據類別 = 'C41' AND
			A.異動類別 between 'C' and 'E' AND
			A.異動數量 != 0 AND
			B.批號 != ' ' AND
			C1.單據日期 >= F.結算日期	
			
		/*UNION ALL 
		客供品條碼入庫
		SELECT 
			M.條碼,
			M.庫存異動數 異動數
		FROM 
			FIL0043 M
			INNER JOIN FIL0040 A ON A.單據類別 = M.單別 AND A.單據編號 = M.單號 AND A.單據序號 = 序號
			INNER JOIN FIL0030 B ON A.單據類別 = B.單據類別 AND A.單據編號 = B.單據編號
			INNER JOIN FIL0043 F ON F.條碼 = M.條碼
			LEFT JOIN ViewOfObjProperties D ON D.單據流水號 = B.流水編號
		WHERE
			M.單別 = 'D51' and
			NVL(D.簽核狀態,' ')<>'A' and 
			A.異動日期 >= F.結算日期
		*/	
		/*UNION ALL 
			客供品退料
		SELECT 
			C.批號,
			decode(A.單據類別,'D52',A.數值4,(A.異動數量 + A.贈品數量))*-1 異動數
		FROM 
			FIL0040 A
			INNER JOIN FIL0041 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號 AND A.單據序號 = C.序號
			INNER JOIN FIL0030 B ON A.單據類別 = B.單據類別 AND A.單據編號 = B.單據編號
			INNER JOIN FIL0043 F ON F.條碼 = C.批號
			LEFT JOIN ViewOfObjProperties D ON D.單據流水號 = B.流水編號
		WHERE
			A.退料註記 = 1 AND
			A.產品編號 != ' ' and
			NVL(D.簽核狀態,' ')<>'A' and 
			A.異動日期 >= F.結算日期
		*/
	) A	
	INNER JOIN FIL0043 F ON F.條碼 = A.批號
	INNER JOIN ViewFIL1012 E ON F.料號 = E.產品編號
GROUP BY
	A.批號
	);

-- Oracle user_views
CREATE VIEW "VIEWFILM018" ("單別", "單號", "序號", "異動日期", "料號", "批號", "異動數") AS (
SELECT 
	A.單據類別 單別,
	A.單據編號 單號,
	A.單據序號 序號,
	A.異動日期,
	A.產品編號 料號,
	nvl(decode(E.批號管理,0,' ',C.批號),' ') 批號,
	nvl(decode(A.單據類別,'D21',A.數值4,(A.異動數量 + A.贈品數量)) * B.材料庫存參數,0) 異動數
FROM 
	FIL0040 A
	/*庫存參數*/
	INNER JOIN ViewFIL0020 B ON A.單據類別 = B.單據類別 AND B.材料庫存參數 != 0
	/*特殊欄位*/
	INNER JOIN FIL0041 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號 AND A.單據序號 = C.序號
	LEFT JOIN VIEWFIL1012 E ON A.產品編號 = E.產品編號
	/*單位換算
	LEFT JOIN ViewFIL1017 F ON A.單位代碼 = F.從 AND E.單位代碼 = F.到
	*/
WHERE
	A.產品編號 != ' ' AND
	C.批號 != ' '
	
union all

/*發料*/
SELECT 
	A.單據類別 單別,
	A.單據編號 單號,
	A.單據序號 序號,
	A.異動日期,
	A.產品編號,
	decode(G.批號管理,0,' ',C.批號) 批號,
	A.異動數量 異動數
FROM 
	FIL0040 A
	INNER JOIN FIL0041 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號 AND A.單據序號 = C.序號
	LEFT JOIN VIEWFIL1012 G ON A.產品編號 = G.產品編號
	/*單位換算
	LEFT JOIN ViewFIL1017 H ON A.單位代碼 = H.從 AND G.單位代碼 = H.到
	*/
WHERE
	A.單據類別 = 'C4M' AND
	A.產品編號 != ' ' AND
	C.批號 != ' '
	
union all

/*材料領用,報廢,油墨領用*/
SELECT 
	A.單據類別 單別,
	A.單據編號 單號,
	A.單據序號 序號,
	A.產品編號,
	A.異動日期,
	decode(C.批號管理,0,' ',B.批號) 批號,
	A.異動數量 * -1 異動數
FROM 
	FIL0040 A
	INNER JOIN FIL0041 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號 AND A.單據序號 = B.序號
	LEFT JOIN VIEWFIL1012 C ON A.產品編號 = C.產品編號
	/*單位換算
	LEFT JOIN ViewFIL1017 E ON A.單位代碼 = E.從 AND C.單位代碼 = E.到
	*/
WHERE
	A.單據類別 = 'C41' AND
	A.異動類別 between 'C' and 'E' AND
	A.異動數量 != 0 AND
	B.批號 != ' '

union all

/*材料領用.氣閥.鐵條-批號1*/
SELECT 
	A.單據類別 單別,
	A.單據編號 單號,
	A.單據序號 序號,
	A.異動日期,
	E.料號,
	decode(F.批號管理,0,' ',B.文數字1) 批號,
	B.數值1 * -1 異動數
FROM 
	FIL0040 A
	INNER JOIN FIL0041 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號 AND A.單據序號 = B.序號
	INNER JOIN FIL0031 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號
	INNER JOIN ViewFIL1024 E ON B.文數字1 = E.條碼
	INNER JOIN VIEWFIL1012 F ON E.料號 = F.產品編號
WHERE
	A.單據類別 = 'C41' AND
	A.異動類別 = 'A' AND
	C.製程代碼 between 'C31F' and 'C31G' AND
	B.文數字1 != ' '

UNION all

/*材料領用.氣閥.鐵條-批號2*/
SELECT
	A.單據類別 單別,
	A.單據編號 單號,
	A.單據序號 序號,
	A.異動日期,
	E.料號,
	decode(F.批號管理,0,' ',B.文數字2) 批號,
	B.數值2 * -1 異動數
FROM 
	FIL0040 A
	INNER JOIN FIL0041 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號 AND A.單據序號 = B.序號
	INNER JOIN FIL0031 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號
	INNER JOIN ViewFIL1024 E ON B.文數字2 = E.條碼
	INNER JOIN VIEWFIL1012 F ON E.料號 = F.產品編號
WHERE
	A.單據類別 = 'C41' AND
	A.異動類別 = 'A' AND
	C.製程代碼 between 'C31F' and 'C31G' AND
	B.文數字2 != ' '	

union all

/*發料回庫(+)*/
SELECT 
	A.單據類別 單別,
	A.單據編號 單號,
	A.單據序號 + 5200 序號,
	A.異動日期,
	A.產品編號,
	decode(C.批號管理,0,' ',B.批號) 批號,
	A.贈品數量 異動數
FROM 
	FIL0040 A
	INNER JOIN FIL0041 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號 AND A.單據序號 = B.序號
	LEFT JOIN VIEWFIL1012 C ON A.產品編號 = C.產品編號
	/*單位換算
	LEFT JOIN ViewFIL1017 E ON A.單位代碼 = E.從 AND C.單位代碼 = E.到
	*/
WHERE
	A.單據類別 = 'C41' AND
	A.異動類別 = 'C' AND
	A.贈品數量 != 0
	
/*廠內盤點調整*/
union all

SELECT
	A.單據類別 單別,
	A.單據編號 單號,
	A.單據序號 序號,
	A.異動日期,
	A.產品編號,
	decode(D.批號管理,0,' ',C.批號) 批號,
	(A.異動數量 + A.贈品數量) 異動數
FROM 
	FIL0040 A
	INNER JOIN FIL0030 B ON A.單據類別 = B.單據類別 AND A.單據編號 = B.單據編號
	/*特殊欄位*/
	INNER JOIN FIL0041 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號 AND A.單據序號 = C.序號
	LEFT JOIN VIEWFIL1012 D ON A.產品編號 = D.產品編號
WHERE
	A.單據類別 = 'F32' AND
	A.異動類別 = '2');

-- Oracle user_views
CREATE VIEW "VIEWFILM018A" ("單據類別", "單據編號", "單據序號", "製程代碼", "異動類別", "單據日期", "批號", "最後更新日", "異動數") AS (
/*A材*/
SELECT 
	A.單據類別,
	A.單據編號,
	A.單據序號,
	B.製程代碼,
	A.異動類別,
	A.異動日期 單據日期,
	C.文數字1 批號,
	A.最後更新日,
	(C.數值1 - C.數值19) 異動數
FROM 
	FIL0040 A
	INNER JOIN FIL0041 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號 AND A.單據序號 = C.序號
	INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 =B.單號 
	INNER JOIN FIL0043 F ON F.條碼 = C.文數字1
WHERE
	A.單據類別 = 'C41' AND
	B.製程代碼 = 'C31E' AND
	C.文數字1 <> ' ' 

Union All
/*B材*/
SELECT 
	A.單據類別,
	A.單據編號,
	A.單據序號,
	B.製程代碼,
	A.異動類別,
	A.異動日期 單據日期,
	C.文數字2 批號,
	A.最後更新日,
	(C.數值2 - C.數值20) 異動數
FROM 
	FIL0040 A
	INNER JOIN FIL0041 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號 AND A.單據序號 = C.序號
	INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 =B.單號 
	INNER JOIN FIL0043 F ON F.條碼 = C.文數字2 
WHERE
	A.單據類別 = 'C41' AND
	B.製程代碼 = 'C31E' AND
	C.文數字2 <> ' '
	
Union All
/*側邊*/
SELECT 
	A.單據類別,
	A.單據編號,
	A.單據序號,
	B.製程代碼,
	A.異動類別,
	A.異動日期 單據日期,
	C.文數字3 批號,
	A.最後更新日,
	(C.數值3 - C.數值21) 異動數
FROM 
	FIL0040 A
	INNER JOIN FIL0041 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號 AND A.單據序號 = C.序號
	INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 =B.單號 
	INNER JOIN FIL0043 F ON F.條碼 = C.文數字3
WHERE
	A.單據類別 = 'C41' AND
	B.製程代碼 = 'C31E' AND
	C.文數字3 <> ' ' 			

Union All
/*底邊*/
SELECT 
	A.單據類別,
	A.單據編號,
	A.單據序號,
	A.異動類別,
	B.製程代碼,
	A.異動日期 單據日期,
	TO_CHAR(C.文數字4) 批號,
	A.最後更新日,
	(C.數值4 - C.數值22) 異動數
FROM 
	FIL0040 A
	INNER JOIN FIL0041 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號 AND A.單據序號 = C.序號
	INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 =B.單號 
	INNER JOIN FIL0043 F ON F.條碼 = C.文數字4
WHERE
	A.單據類別 = 'C41' AND
	B.製程代碼 = 'C31E' AND
	C.文數字4 <> ' '

Union All
/*裁切一*/
SELECT 
	A.單據類別,
	A.單據編號,
	A.單據序號,
	B.製程代碼,
	A.異動類別,
	A.異動日期 單據日期,
	TO_CHAR(C.文數字4) 批號,
	A.最後更新日,
	(A.異動數量) 異動數
FROM 
	FIL0040 A
	INNER JOIN FIL0041 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號 AND A.單據序號 = C.序號
	INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 =B.單號 
	INNER JOIN FIL0043 F ON F.條碼 = C.文數字4
WHERE
	A.單據類別 = 'C41' AND
	B.製程代碼 = 'C31D' AND
	C.文數字4 <> ' '	

Union All
/*裁切二*/
SELECT 
	A.單據類別,
	A.單據編號,
	A.單據序號,
	B.製程代碼,
	A.異動類別,
	A.異動日期 單據日期,
	TO_CHAR(C.文數字5) 批號,
	A.最後更新日,
	(A.數值1) 異動數
FROM 
	FIL0040 A
	INNER JOIN FIL0041 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號 AND A.單據序號 = C.序號
	INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 =B.單號 
	INNER JOIN FIL0043 F ON F.條碼 = C.文數字4
WHERE
	A.單據類別 = 'C41' AND
	B.製程代碼 = 'C31D' AND
	C.文數字5 <> ' '		
);

-- Oracle user_views
CREATE VIEW "VIEWFILM018A0" ("單據類別", "單據編號", "單據序號", "製程代碼", "異動類別", "單據日期", "批號", "最後更新日", "異動數") AS (
/*A材*/
SELECT 
	A.單據類別,
	A.單據編號,
	A.單據序號,
	B.製程代碼,
	A.異動類別,
	A.異動日期 單據日期,
	C.文數字1 批號,
	A.最後更新日,
	C.數值1 異動數
FROM 
	FIL0040 A
	INNER JOIN FIL0041 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號 AND A.單據序號 = C.序號
	INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 =B.單號 
	INNER JOIN FIL0043 F ON F.條碼 = C.文數字1
WHERE
	A.單據類別 = 'C41' AND
	B.製程代碼 = 'C31E' AND
	INSTR(C.文數字1,'^')>0 

Union All
/*B材*/
SELECT 
	A.單據類別,
	A.單據編號,
	A.單據序號,
	B.製程代碼,
	A.異動類別,
	A.異動日期 單據日期,
	C.文數字2 批號,
	A.最後更新日,
	C.數值2 異動數
FROM 
	FIL0040 A
	INNER JOIN FIL0041 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號 AND A.單據序號 = C.序號
	INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 =B.單號 
	INNER JOIN FIL0043 F ON F.條碼 = C.文數字2 
WHERE
	A.單據類別 = 'C41' AND
	B.製程代碼 = 'C31E' AND
	INSTR(C.文數字2,'^')>0
	
Union All
/*側邊*/
SELECT 
	A.單據類別,
	A.單據編號,
	A.單據序號,
	B.製程代碼,
	A.異動類別,
	A.異動日期 單據日期,
	C.文數字3 批號,
	A.最後更新日,
	C.數值3 異動數
FROM 
	FIL0040 A
	INNER JOIN FIL0041 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號 AND A.單據序號 = C.序號
	INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 =B.單號 
	INNER JOIN FIL0043 F ON F.條碼 = C.文數字3
WHERE
	A.單據類別 = 'C41' AND
	B.製程代碼 = 'C31E' AND
	INSTR(C.文數字3,'^')>0			

Union All
/*底邊*/
SELECT 
	A.單據類別,
	A.單據編號,
	A.單據序號,
	A.異動類別,
	B.製程代碼,
	A.異動日期 單據日期,
	TO_CHAR(C.文數字4) 批號,
	A.最後更新日,
	C.數值4 異動數
FROM 
	FIL0040 A
	INNER JOIN FIL0041 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號 AND A.單據序號 = C.序號
	INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 =B.單號 
	INNER JOIN FIL0043 F ON F.條碼 = C.文數字4
WHERE
	A.單據類別 = 'C41' AND
	B.製程代碼 = 'C31E' AND
	INSTR(C.文數字4,'^')>0

Union All
/*裁切一*/
SELECT 
	A.單據類別,
	A.單據編號,
	A.單據序號,
	B.製程代碼,
	A.異動類別,
	A.異動日期 單據日期,
	TO_CHAR(C.文數字4) 批號,
	A.最後更新日,
	(A.異動數量) 異動數
FROM 
	FIL0040 A
	INNER JOIN FIL0041 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號 AND A.單據序號 = C.序號
	INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 =B.單號 
	INNER JOIN FIL0043 F ON F.條碼 = C.文數字4
WHERE
	A.單據類別 = 'C41' AND
	B.製程代碼 = 'C31D' AND
	INSTR(C.文數字4,'^')>0

Union All
/*裁切二*/
SELECT 
	A.單據類別,
	A.單據編號,
	A.單據序號,
	B.製程代碼,
	A.異動類別,
	A.異動日期 單據日期,
	TO_CHAR(C.文數字5) 批號,
	A.最後更新日,
	(A.數值1) 異動數
FROM 
	FIL0040 A
	INNER JOIN FIL0041 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號 AND A.單據序號 = C.序號
	INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 =B.單號 
	INNER JOIN FIL0043 F ON F.條碼 = C.文數字4
WHERE
	A.單據類別 = 'C41' AND
	B.製程代碼 = 'C31D' AND
	INSTR(C.文數字5,'^')>0	
);

-- Oracle user_views
CREATE VIEW "VIEWFILM018A1" ("單據類別", "單據編號", "單據序號", "製程代碼", "異動類別", "單據日期", "批號", "最後更新日", "異動數") AS (
/*A材退庫*/
SELECT 
	A.單據類別,
	A.單據編號,
	A.單據序號,
	B.製程代碼,
	A.異動類別,
	A.異動日期 單據日期,
	C.文數字1 批號,
	A.最後更新日,
	C.數值19 異動數
FROM 
	FIL0040 A
	INNER JOIN FIL0041 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號 AND A.單據序號 = C.序號
	INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 =B.單號 
	INNER JOIN FIL0043 F ON F.條碼 = C.文數字1
WHERE
	A.單據類別 = 'C41' AND
	B.製程代碼 = 'C31E' AND
	INSTR(C.文數字1,'^')>0 AND
	C.數值19 <> 0

Union All
/*B材退庫*/
SELECT 
	A.單據類別,
	A.單據編號,
	A.單據序號,
	B.製程代碼,
	A.異動類別,
	A.異動日期 單據日期,
	C.文數字2 批號,
	A.最後更新日,
	C.數值20 異動數
FROM 
	FIL0040 A
	INNER JOIN FIL0041 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號 AND A.單據序號 = C.序號
	INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 =B.單號 
	INNER JOIN FIL0043 F ON F.條碼 = C.文數字2 
WHERE
	A.單據類別 = 'C41' AND
	B.製程代碼 = 'C31E' AND
	INSTR(C.文數字2,'^')>0 AND
	C.數值20 <> 0
	
Union All
/*側邊退庫*/
SELECT 
	A.單據類別,
	A.單據編號,
	A.單據序號,
	B.製程代碼,
	A.異動類別,
	A.異動日期 單據日期,
	C.文數字3 批號,
	A.最後更新日,
	C.數值21 異動數
FROM 
	FIL0040 A
	INNER JOIN FIL0041 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號 AND A.單據序號 = C.序號
	INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 =B.單號 
	INNER JOIN FIL0043 F ON F.條碼 = C.文數字3
WHERE
	A.單據類別 = 'C41' AND
	B.製程代碼 = 'C31E' AND
	INSTR(C.文數字3,'^')>0 AND
	C.數值21 <> 0			

Union All
/*底邊退庫*/
SELECT 
	A.單據類別,
	A.單據編號,
	A.單據序號,
	A.異動類別,
	B.製程代碼,
	A.異動日期 單據日期,
	TO_CHAR(C.文數字4) 批號,
	A.最後更新日,
	C.數值22 異動數
FROM 
	FIL0040 A
	INNER JOIN FIL0041 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號 AND A.單據序號 = C.序號
	INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 =B.單號 
	INNER JOIN FIL0043 F ON F.條碼 = C.文數字4
WHERE
	A.單據類別 = 'C41' AND
	B.製程代碼 = 'C31E' AND
	INSTR(C.文數字4,'^')>0 AND
	C.數值22 <> 0
);

-- Oracle user_views
CREATE VIEW "VIEWFILM018H" ("單別", "單號", "序號", "異動類別", "單據日期", "批號", "製程代碼", "接頭數", "最後接頭數", "圓周", "規格", "熟成條件", "來源", "最後更新日", "異動數") AS (
	SELECT
		A.單據類別 單別,
		A.單據編號 單號,
		A.單據序號 序號,
		A.異動類別,
		A.單據日期,
		A.批號,
		A.製程代碼,
		A.接頭數,
		first_value(A.接頭數 ignore nulls) over (partition by A.批號  order by A.最後更新日 desc) 最後接頭數,
		A.圓周,
		A.規格,
		A.熟成條件,
		A.來源,
		A.最後更新日,
		A.異動數
	FROM
		(	
		/*日報入庫*/
		SELECT 
			'日報入庫' 來源,
			A.單據類別,
			A.單據編號,
			A.單據序號,
			A.異動類別,
			D.單據日期,
			C.批號,
			B.製程代碼,
			A.接頭數,
			A.最後更新日,
			A.圓周,
			to_char(C.專案代號) 規格,
			decode(B.製程代碼,'C31B',to_char(B.文字4),'C31C',to_char(B.文字4),'C31D',to_char(B.文字4),' ') 熟成條件,
			(異動單價-夾鏈費) 異動數
		FROM 
			FIL0040 A
			INNER JOIN FIL0030 D ON A.單據類別 = D.單據類別 AND A.單據編號 = D.單據編號 
			/*特殊欄位*/
			INNER JOIN FIL0041 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號 AND A.單據序號 = C.序號
			INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
		WHERE
			A.單據類別 = 'C41' AND 
			((B.製程代碼 BETWEEN 'C31A' AND 'C31C') OR B.製程代碼 = 'C32D' OR B.製程代碼 = 'C31H' OR B.製程代碼 = 'C31K') AND  
			INSTR(C.批號,'^')>0
			
		UNION ALL
		/*裁切入庫*/
		SELECT 
			'日報入庫' 來源,
			A.單別, 
			A.單號,
			A.序號,
			G.異動類別,
			D.單據日期,	
			trim(A.文字一)||'^C31D',
			'C31D',
			0,
			D.最後更新日,
			0,
			' ',
			' ',
			A.數字一*decode(A.報廢,1,0,1) 入庫米數			
		FROM 
			FIL00401 A
			INNER JOIN FIL0031 B ON A.單別 = B.單別 AND A.單號 = B.單號
			/*主檔*/
			INNER JOIN FIL0030 D ON A.單別 = D.單據類別 AND A.單號 = D.單據編號
			INNER JOIN FIL0040 G ON A.單別 = G.單據類別 AND A.單號 = G.單據編號 AND A.序號 = G.單據序號
			INNER JOIN FIL0032 P ON P.製令單別 = 'C11' and P.製令單號 = REGEXP_SUBSTR(A.文字一, '[^_]+', 1, 1)
			LEFT JOIN FIL0033 E ON E.製令單別 = 'C11' and E.製令單號 = REGEXP_SUBSTR(A.文字一, '[^_]+', 1, 1) and E.加工別 = 'A'
			LEFT JOIN FIL003F1 F ON F.單據類別 = 'C11' and F.單據編號 = REGEXP_SUBSTR(A.文字一, '[^_]+', 1, 1) and F.類別 = 'G1'
		WHERE
			A.單別 = 'C41' AND 
			G.異動類別 = 'A' AND
			B.製程代碼 = 'C31D' AND
			A.文字一<>' '
	
		UNION ALL	
		/*前製程調整入庫*/
		SELECT 
			'調整入庫' 來源,
			A.單據類別,
			A.單據編號,
			A.單據序號,
			A.異動類別,
			D.單據日期,
			C.批號,
			A.單據類別 製程代碼,
			A.接頭數,
			A.最後更新日,
			0 圓周,
			to_char(C.專案代號) 規格,
			' ' 熟成條件 ,
			(異動單價-夾鏈費) 異動數
		FROM 
			FIL0040 A
			INNER JOIN FIL0030 D ON A.單據類別 = D.單據類別 AND A.單據編號 = D.單據編號 
			/*特殊欄位*/
			INNER JOIN FIL0041 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號 AND A.單據序號 = C.序號
		WHERE
			A.單據類別 = 'E24' AND 
			INSTR(C.批號,'^')>0

		UNION ALL	
		/*裁切調整單*/
		SELECT 
			'裁切調整' 來源,
			A.單據類別,
			A.單據編號,
			A.單據序號,
			A.異動類別,
			D.單據日期,
			A.產品編號||'^C31D' 批號,
			A.單據類別 製程代碼,
			A.接頭數,
			A.最後更新日,
			0 圓周,
			to_char(C.專案代號) 規格,
			' ' 熟成條件 ,
			A.異動數量*decode(A.異動類別,'C',-1,1) 異動數
		FROM 
			FIL0040 A
			INNER JOIN FIL0030 D ON A.單據類別 = D.單據類別 AND A.單據編號 = D.單據編號 
			/*特殊欄位*/
			INNER JOIN FIL0041 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號 AND A.單據序號 = C.序號
		WHERE
			A.單據類別 = 'E22' 
			
		UNION ALL
		/*日報領料*/
		SELECT 
			'日報領用' 來源,
			A.單據類別,
			A.單據編號,
			A.單據序號,
			A.異動類別,
			B.單據日期,
			to_char(C.文數字4) 批號,
			D.製程代碼,
			case when A.退庫數量=0 then null else A.接頭數 end 接頭數,
			A.最後更新日,
			0 圓周,
			to_char(' ') 規格,
			' ' 熟成條件 ,
			A.異動數量*-1 異動數
		FROM 
			FIL0040 A
			INNER JOIN FIL0030 B ON A.單據類別 = B.單據類別 AND A.單據編號 = B.單據編號 
			/*特殊欄位*/
			INNER JOIN FIL0041 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號 AND A.單據序號 = C.序號
			INNER JOIN FIL0031 D ON A.單據類別 = D.單別 AND A.單據編號 = D.單號
		WHERE
			A.單據類別 = 'C41' AND
			A.異動數量 > 0 AND 
			((D.製程代碼 BETWEEN 'C31A' AND 'C31C') OR D.製程代碼 = 'C32D' OR D.製程代碼 = 'C31H' OR D.製程代碼 = 'C31K')	AND
			INSTR(C.文數字4,'^')>0 
			
		UNION ALL
		/*日報領退*/
		SELECT 
			'日報領退' 來源,
			A.單據類別,
			A.單據編號,
			A.單據序號+9000 單據序號,
			A.異動類別,
			B.單據日期,
			to_char(C.文數字4) 批號,
			D.製程代碼,
			case when A.退庫數量=0 then null else A.接頭數 end 接頭數,
			A.最後更新日,
			0 圓周,
			to_char(' ') 規格,
			' ' 熟成條件 ,
			A.退庫數量 異動數
		FROM 
			FIL0040 A
			INNER JOIN FIL0030 B ON A.單據類別 = B.單據類別 AND A.單據編號 = B.單據編號 
			/*特殊欄位*/
			INNER JOIN FIL0041 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號 AND A.單據序號 = C.序號
			INNER JOIN FIL0031 D ON A.單據類別 = D.單別 AND A.單據編號 = D.單號
		WHERE
			A.單據類別 = 'C41' AND
			A.退庫數量 > 0 AND 
			((D.製程代碼 BETWEEN 'C31A' AND 'C31C') OR D.製程代碼 = 'C32D' OR D.製程代碼 = 'C31H' OR D.製程代碼 = 'C31K')	AND
			INSTR(C.文數字4,'^')>0 			
			
		UNION ALL
		/*日報半成品退料*/
		SELECT 
			'日報退庫' 來源,
			A.單據類別,
			A.單據編號,
			A.單據序號,
			A.異動類別,
			B.單據日期,
			to_char(A.合併編號) 批號,
			D.製程代碼,
			A.接頭數,
			A.最後更新日,
			0 圓周,
			to_char(' ') 規格,
			' ' 熟成條件 ,
			ABS(A.贈品數量) 異動數
		FROM 
			FIL0040 A
			INNER JOIN FIL0041 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號 AND A.單據序號 = C.序號
			INNER JOIN FIL0030 B ON A.單據類別 = B.單據類別 AND A.單據編號 = B.單據編號 
			INNER JOIN FIL0031 D ON A.單據類別 = D.單別 AND A.單據編號 = D.單號
		WHERE
			A.退料註記 = 1 AND
			C.標籤列印次數 > 0 AND
			INSTR(A.文數字1,'^')>0 			
					
		UNION ALL 
		/*製袋裁切領料*/
		SELECT 
			'日報領用' 來源,
			A.單據類別,
			A.單據編號,
			A.單據序號,
			A.異動類別,
			A.單據日期,
			A.批號,
			A.製程代碼,
			null 接頭數,
			A.最後更新日,
			0 圓周,
			to_char(' ') 規格,
			' ' 熟成條件 ,
			A.異動數*-1 異動數
		FROM 
			ViewFILM018A0 A	
			
		UNION ALL 
		/*製袋裁切領退料*/
		SELECT 
			'日報領退' 來源,
			A.單據類別,
			A.單據編號,
			A.單據序號+9000 單據序號,
			A.異動類別,
			A.單據日期,
			A.批號,
			A.製程代碼,
			null 接頭數,
			A.最後更新日,
			0 圓周,
			to_char(' ') 規格,
			' ' 熟成條件 ,
			A.異動數 異動數
		FROM 
			ViewFILM018A1 A			
			
		/*成捲領用條碼*/	
		UNION ALL	
		SELECT 
			'成捲領用' 來源,
			A.單別 單據類別, 
			A.單號 單據編號,
			A.序號*100+A.細分 單據序號,
			C.異動類別,			
			D.單據日期,
			RTRIM(A.文字一)||'^C31D' 批號,			
			B.製程代碼,
			null 接頭數,
			C.最後更新日,
			0 圓周,
			to_char(' ') 規格,
			' ' 熟成條件,
			E.庫存異動數*-1 異動數
		FROM 
			FIL00401 A
			INNER JOIN FIL0031 B ON A.單別 = B.單別 AND A.單號 = B.單號
			INNER JOIN FIL0040 C ON A.單別 = c.單據類別 AND A.單號 = C.單據編號 AND A.序號=C.單據序號
			INNER JOIN FIL0030 D ON A.單別 = D.單據類別 AND A.單號 = D.單據編號 
			INNER JOIN FIL0043 E ON E.條碼 = RTRIM(A.文字一)||'^C31D'
		WHERE
			A.單別 = 'C41' AND
			B.製程代碼 = 'C31I' AND
			A.文字一 <> ' '
		
		UNION ALL 
		/*銷貨單條碼*/
		SELECT 
			'出貨' 來源,
			A.單據類別,
			A.單據號碼,
			A.單據序號,
			to_char('A') 異動類別,
			A.異動日期 單據日期,
			A.條碼 批號,
			to_char(' ') 製程代碼,
			null 接頭數,
			to_date(A.異動日期||A.異動時間,'yyyymmddHH24miss'),
			0 圓周,
			to_char(' ') 規格,
			' ' 熟成條件 ,
			B.庫存異動數*-1 異動數
		FROM 
			Fil0044 A
			INNER JOIN FIL0043 B ON B.條碼 = A.條碼
		WHERE	
			A.單據類別 = 'B42'
	) A	
);

-- Oracle user_views
CREATE VIEW "VIEWFILM018S" ("單別", "單號", "序號", "異動類別", "異動日期", "料號", "批號", "最後更新日", "異動數", "來源") AS (
SELECT
	A.單據類別 單別,
	A.單據編號 單號,
	A.單據序號 序號,
	A.異動類別,
	A.異動日期,
	F.料號 料號,
	A.批號,
	A.最後更新日,
	nvl(A.異動數,0) 異動數,
	A.來源
FROM
	(	/*盤點調整*/
		SELECT 
			A.單據類別,
			A.單據編號,
			A.單據序號,
			A.異動類別,
			A.異動日期,
			C.批號,
			A.最後更新日,
			(A.異動數量 + A.贈品數量) 異動數,
			'盤點調整' 來源
		FROM 
			FIL0040 A
			/*特殊欄位*/
			INNER JOIN FIL0041 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號 AND A.單據序號 = C.序號
			INNER JOIN FIL0043 F ON F.條碼 = C.批號
		WHERE
			A.單據類別 = 'F32' AND 
			C.批號 != ' ' 
		
		UNION ALL 
		/*驗收,進料退出,材料入庫,調整,裁切材料入庫*/
		SELECT 
			A.單據類別,
			A.單據編號,
			A.單據序號,
			A.異動類別,
			A.異動日期,
			C.批號,
			A.最後更新日,
			decode(A.單據類別,'D21',A.數值4,'E12',A.數值2,'E13',A.數值2,(A.異動數量 + A.贈品數量)) 異動數,
			decode(A.單據類別,'D41','原材料.退料','E12','材料調整','E13','裁切.材料','原材料.驗收') 來源
		FROM 
			FIL0040 A
			/*特殊欄位*/
			INNER JOIN FIL0041 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號 AND A.單據序號 = C.序號
			INNER JOIN FIL0030 B ON A.單據類別 = B.單據類別 AND A.單據編號 = B.單據編號
			LEFT JOIN ViewOfObjProperties D ON D.單據流水號 = B.流水編號
		WHERE
			A.入料註記 = 1 AND
			A.產品編號 != ' ' AND
			C.批號 != ' ' and
			NVL(D.簽核狀態,' ')<>'A'
		
		UNION ALL 
			/*前製程日報領料*/
		SELECT 
			A.單據類別,
			A.單據編號,
			A.單據序號,
			A.異動類別,
			B.單據日期,
			to_char(C.文數字4) 批號,
			A.最後更新日,
			(A.異動數量)*-1 異動數,
			decode(D.製程代碼,'C31B',case when A.異動類別 = 'C' and C.專案代號<>' ' then '沿用轉入' else '領用' end,'C31C',case when A.異動類別 = 'C' and C.專案代號<>' ' then '沿用轉入' else '領用' end,'領用') 來源
		FROM 
			FIL0040 A
			INNER JOIN FIL0030 B ON A.單據類別 = B.單據類別 AND A.單據編號 = B.單據編號 
			/*特殊欄位*/
			INNER JOIN FIL0041 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號 AND A.單據序號 = C.序號
			INNER JOIN FIL0031 D ON A.單據類別 = D.單別 AND A.單據編號 = D.單號
		WHERE
			A.單據類別 = 'C41' AND
			A.異動數量 > 0 AND
			((D.製程代碼 BETWEEN 'C31A' AND 'C31C') OR D.製程代碼 = 'C32D' OR D.製程代碼 = 'C31H' OR D.製程代碼 = 'C31K') AND 
			C.文數字4 != ' '	

		UNION ALL 
			/*印刷日報退回*/
		SELECT 
			A.單據類別,
			A.單據編號,
			A.單據序號,
			A.異動類別,
			B.單據日期,
			to_char(C.文數字4) 批號,
			A.最後更新日,
			A.退庫數量 異動數,
			'退庫' 來源
		FROM 
			FIL0040 A
			INNER JOIN FIL0030 B ON A.單據類別 = B.單據類別 AND A.單據編號 = B.單據編號 
			/*特殊欄位*/
			INNER JOIN FIL0041 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號 AND A.單據序號 = C.序號
			INNER JOIN FIL0031 D ON A.單據類別 = D.單別 AND A.單據編號 = D.單號
		WHERE
			A.單據類別 = 'C41' AND
			A.退庫數量 > 0 AND
			D.製程代碼 = 'C31A' AND 
			to_char(C.文數字4) != ' '			

		UNION ALL 
			/*前製程日報退回*/
		SELECT 
			A.單據類別,
			A.單據編號,
			A.單據序號,
			A.異動類別,
			B.單據日期,
			to_char(C.文數字4) 批號,
			A.最後更新日,
			A.退庫數量 異動數,
			'退庫' 來源
		FROM 
			FIL0040 A
			INNER JOIN FIL0030 B ON A.單據類別 = B.單據類別 AND A.單據編號 = B.單據編號 
			/*特殊欄位*/
			INNER JOIN FIL0041 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號 AND A.單據序號 = C.序號
			INNER JOIN FIL0031 D ON A.單據類別 = D.單別 AND A.單據編號 = D.單號
		WHERE
			A.單據類別 = 'C41' AND
			A.異動類別 = 'A' AND
			A.退庫數量 > 0 AND
			(D.製程代碼 = 'C31B' OR D.製程代碼 = 'C31C'  OR D.製程代碼 = 'C32D' OR D.製程代碼 = 'C31H' OR D.製程代碼 = 'C31K') AND 
			C.文數字4 != ' '			

		UNION ALL 
			/*前製程日報沿用*/
		SELECT 
			A.單據類別,
			A.單據編號,
			A.單據序號,
			A.異動類別,
			B.單據日期,
			to_char(C.文數字4) 批號,
			A.最後更新日,
			A.退庫數量 異動數,
			decode(A.Logical1,1,'退庫沿用','退庫') 來源
		FROM 
			FIL0040 A
			INNER JOIN FIL0030 B ON A.單據類別 = B.單據類別 AND A.單據編號 = B.單據編號 
			/*特殊欄位*/
			INNER JOIN FIL0041 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號 AND A.單據序號 = C.序號
			INNER JOIN FIL0031 D ON A.單據類別 = D.單別 AND A.單據編號 = D.單號
		WHERE
			A.單據類別 = 'C41' AND
			A.異動類別 = 'C' AND
			A.退庫數量 > 0  AND
			(D.製程代碼 BETWEEN 'C31B' AND 'C31C') AND 
			C.文數字4 != ' '			
		
		UNION ALL 
			/*材料領用,報廢,油墨領用*/
		SELECT 
			A.單據類別,
			A.單據編號,
			A.單據序號,
			A.異動類別,
			B.單據日期,
			C.批號  批號,
			A.最後更新日,
			(A.異動數量-A.退庫數量)*-1 異動數,
			'領用' 來源
		FROM 
			FIL0040 A
			INNER JOIN FIL0030 B ON A.單據類別 = B.單據類別 AND A.單據編號 = B.單據編號 
			/*特殊欄位*/
			INNER JOIN FIL0041 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號 AND A.單據序號 = C.序號
			INNER JOIN FIL0031 D ON A.單據類別 = D.單別 AND A.單據編號 = D.單號
		WHERE
			A.單據類別 = 'C41' AND
			A.異動數量 > 0  AND 
			A.異動類別 BETWEEN 'C' AND 'E' AND
			C.批號 != ' '					
		
		UNION ALL 
			/*製袋日報退庫_沿用*/
		SELECT 
			A.單據類別,
			A.單據編號,
			A.單據序號,
			A.異動類別,
			B.單據日期,
			C.批號  批號,
			A.最後更新日,
			A.贈品數量 異動數,
			decode(A.Logical1,1,'退庫沿用','退庫') 來源
		FROM 
			FIL0040 A
			INNER JOIN FIL0030 B ON A.單據類別 = B.單據類別 AND A.單據編號 = B.單據編號 
			/*特殊欄位*/
			INNER JOIN FIL0041 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號 AND A.單據序號 = C.序號
			INNER JOIN FIL0031 D ON A.單據類別 = D.單別 AND A.單據編號 = D.單號
		WHERE
			A.單據類別 = 'C41' AND
			A.贈品數量 > 0 AND
			D.製程代碼 ='C31E' AND 
			A.異動類別 = 'C' AND
			C.批號 != ' '					
			
		UNION ALL 
			/*製袋裁切領料*/
		SELECT 
			A.單據類別,
			A.單據編號,
			A.單據序號,
			A.異動類別,
			A.單據日期,
			A.批號,
			A.最後更新日,
			A.異動數*-1 異動數,
			'領用' 來源
		FROM 
			ViewFILM018A A			
						
		UNION ALL 
			/*裁切材料領用*/
		SELECT 
			A.單據類別,
			A.單據編號,
			0,
			' ',
			A.單據日期,
			A.廠客單號 批號,
			A.最後更新日,
			A.折讓*-1 異動數,
			'領用' 來源
		FROM 
			FIL0030 A
			/*特殊欄位*/
			INNER JOIN FIL0031 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號 
			LEFT JOIN ViewOfObjProperties D ON D.單據流水號 = A.流水編號
		WHERE
			A.單據類別 ='E13' and
			A.廠客單號 != ' ' and
			A.折讓 > 0 and
			NVL(D.簽核狀態,' ')<>'A'
						
		UNION ALL 
			/*裁切材料退庫*/
		SELECT 
			A.單據類別,
			A.單據編號,
			0,
			' ',
			A.單據日期,
			A.廠客單號 批號,
			A.最後更新日,
			C.數值1 異動數,
			'退回' 來源
		FROM 
			FIL0030 A
			/*特殊欄位*/
			INNER JOIN FIL0031 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號 
			LEFT JOIN ViewOfObjProperties D ON D.單據流水號 = A.流水編號
		WHERE
			A.單據類別 ='E13' and
			A.廠客單號 != ' ' and
			C.數值1 > 0 and
			NVL(D.簽核狀態,' ')<>'A'
						
		UNION ALL 
			/*氣閥鐵條領用1*/
		SELECT 
			A.單據類別,
			A.單據編號,
			A.單據序號,
			A.異動類別,
			B.單據日期,
			C.文數字1  批號,
			A.最後更新日,
			(C.數值1)*-1 異動數,
			'領用' 來源
		FROM 
			FIL0040 A
			INNER JOIN FIL0030 B ON A.單據類別 = B.單據類別 AND A.單據編號 = B.單據編號 
			/*特殊欄位*/
			INNER JOIN FIL0041 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號 AND A.單據序號 = C.序號
			INNER JOIN FIL0031 D ON A.單據類別 = D.單別 AND A.單據編號 = D.單號
		WHERE
			A.單據類別 = 'C41' AND
			C.數值1 > 0 AND
			D.製程代碼 BETWEEN 'C31F' AND 'C31G' AND 
			A.異動類別 = 'A' AND
			C.文數字1 != ' '				
				
		UNION ALL 
			/*氣閥鐵條領用2*/
		SELECT 
			A.單據類別,
			A.單據編號,
			A.單據序號,
			A.異動類別,
			B.單據日期,
			C.文數字2  批號,
			A.最後更新日,
			(C.數值2)*-1 異動數,
			'領用' 來源
		FROM 
			FIL0040 A
			INNER JOIN FIL0030 B ON A.單據類別 = B.單據類別 AND A.單據編號 = B.單據編號 
			/*特殊欄位*/
			INNER JOIN FIL0041 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號 AND A.單據序號 = C.序號
			INNER JOIN FIL0031 D ON A.單據類別 = D.單別 AND A.單據編號 = D.單號
		WHERE
			A.單據類別 = 'C41' AND
			C.數值2 > 0 AND
			D.製程代碼 BETWEEN 'C31F' AND 'C31G' AND 
			A.異動類別 = 'A' AND
			C.文數字2 != ' '				
			
		/*客供品暫不使用 	
			UNION ALL */
				/*客供品退料
			SELECT 
				A.單據類別,
				A.單據編號,
				A.單據序號,
				A.異動類別,
				A.異動日期,
				C.批號,
				A.最後更新日,
				decode(A.單據類別,'D52',A.數值4,(A.異動數量 + A.贈品數量))*-1 異動數,
				'客供品退料' 來源
			FROM 
				FIL0040 A
				INNER JOIN FIL0041 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號 AND A.單據序號 = C.序號
				INNER JOIN FIL0030 B ON A.單據類別 = B.單據類別 AND A.單據編號 = B.單據編號
				LEFT JOIN ViewOfObjProperties D ON D.單據流水號 = B.流水編號
			WHERE
				A.退料註記 = 1 AND
				A.產品編號 != ' ' AND
				C.批號 != ' ' and
				NVL(D.簽核狀態,' ')<>'A'
				*/	
		/*客供品暫不使用		
			UNION ALL */
				/*客供品條碼入庫
			SELECT 
				A.單據類別,
				A.單據編號,
				A.單據序號,
				'S',
				A.異動日期,
				M.條碼,
				A.最後更新日,
				M.庫存異動數 異動數,
				'客供品入庫' 來源
			FROM 
				FIL0043 M
				INNER JOIN FIL0040 A ON A.單據類別 = M.單別 AND A.單據編號 = M.單號 AND A.單據序號 = 序號
				INNER JOIN FIL0030 B ON A.單據類別 = B.單據類別 AND A.單據編號 = B.單據編號
				LEFT JOIN ViewOfObjProperties D ON D.單據流水號 = B.流水編號
			WHERE
				M.單別 = 'D51' AND 
				A.產品編號 != ' '  and
				NVL(D.簽核狀態,' ')<>'A'	
			*/	
	) A	
	INNER JOIN FIL0043 F ON F.條碼 = A.批號
	INNER JOIN ViewFIL1012 E ON F.料號 = E.產品編號
	);

-- Oracle user_views
CREATE VIEW "VIEWFILM018SA" ("請領單別", "請領單號", "料號", "請領數量", "發料數量", "日報領用數量", "日報退庫數量", "日報沿用數量") AS WITH 
TMP1 AS
	(
/*請領發料*/	
	SELECT
		A.請領單別,
		A.請領單號,
		A.料號,
		sum(A.核准數量) 核准數量,
		sum(A.發料數量) 發料數量
	FROM
		(	SELECT
				decode(A.單據類別, 'C4L', A.單據類別, B.歸屬類別) 請領單別,
				decode(A.單據類別, 'C4L', A.單據編號, B.歸屬編號) 請領單號,
				decode(A.單據類別, 'C4L', A.產品編號, A.文數字1) 料號,
				decode(A.單據類別, 'C4L', A.異動數量, 0)*B.邏輯值一 核准數量,
				decode(A.單據類別, 'C4M', A.異動數量, 0) 發料數量
			FROM 
				FIL0040 A
				INNER JOIN FIL0030 B ON A.單據類別 = B.單據類別 AND A.單據編號 = B.單據編號 
				/*特殊欄位*/
				INNER JOIN FIL0031 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號
				LEFT JOIN FIL0041 D ON A.單據類別 = D.單別 AND A.單據編號 = D.單號 AND A.單據序號 = D.序號
			WHERE
				A.單據類別 between 'C4L' and 'C4M'
		) A
	GROUP BY
		A.請領單別,
		A.請領單號,
		A.料號
	),
/*日報領用*/
TMP2 AS
	(SELECT 
		'C4L' 請領單別,
		E.其它單號 請領單號,
		E.請領料號 料號,
		sum(A.異動數量) 領用數量
	FROM 
		FIL0040 A
		INNER JOIN FIL0030 B ON A.單據類別 = B.單據類別 AND A.單據編號 = B.單據編號 
		/*特殊欄位*/
		INNER JOIN FIL0041 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號 AND A.單據序號 = C.序號
		INNER JOIN FIL0031 D ON A.單據類別 = D.單別 AND A.單據編號 = D.單號
		INNER JOIN FIL0044 E ON E.條碼 = to_char(C.文數字4) AND E.單據類別 = 'C4M' AND E.來源 = 'O' 
	WHERE
		A.單據類別 = 'C41' AND
		A.異動數量 > 0 AND
		((D.製程代碼 BETWEEN 'C31A' AND 'C31C') OR D.製程代碼 = 'C32D' OR D.製程代碼 = 'C31H' OR D.製程代碼 = 'C31K') AND 
		C.文數字4 != ' '	
	GROUP BY
		'C4L',
		E.其它單號,
		E.請領料號	
	),
/*裁切領用*/	
TMP2A AS
	(	
	SELECT 
		'C4L' 請領單別,
		E.其它單號 請領單號,
		E.請領料號 料號,
		sum(A.折讓) 領用數量
	FROM 
		FIL0030 A
		/*特殊欄位*/
		INNER JOIN FIL0044 E ON E.條碼 = A.廠客單號 AND E.單據類別 = 'C4M' AND E.來源 = 'O' 
	WHERE
		A.單據類別 = 'E13' AND
		A.折讓 > 0 AND
		A.廠客單號 != ' '	
	GROUP BY
		'C4L',
		E.其它單號,
		E.請領料號
	),
/*日報退回*/
TMP3 AS
	(SELECT 
		'C4L' 請領單別,
		E.其它單號 請領單號,
		E.請領料號 料號,
		sum(A.退庫數量*decode(A.Logical1,1,0,1)) 退庫數量,
		sum(A.退庫數量*A.Logical1) 沿用數量
	FROM 
		FIL0040 A
		INNER JOIN FIL0030 B ON A.單據類別 = B.單據類別 AND A.單據編號 = B.單據編號 
		/*特殊欄位*/
		INNER JOIN FIL0041 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號 AND A.單據序號 = C.序號
		INNER JOIN FIL0031 D ON A.單據類別 = D.單別 AND A.單據編號 = D.單號
		INNER JOIN FIL0044 E ON E.條碼 = to_char(C.文數字4) AND E.單據類別 = 'C4M' AND E.來源 = 'O' 
	WHERE
		A.單據類別 = 'C41' AND
		A.退庫數量 > 0 AND
		((D.製程代碼 BETWEEN 'C31A' AND 'C31C') OR D.製程代碼 = 'C32D' OR D.製程代碼 = 'C31H' OR D.製程代碼 = 'C31K') AND 
		C.文數字4 != ' '	
	GROUP BY
		'C4L',
		E.其它單號,
		E.請領料號	
	),
/*裁切退回*/	
TMP3A AS
	(
	SELECT 
		'C4L' 請領單別,
		E.其它單號 請領單號,
		E.請領料號 料號,
		sum(D.數值1) 退庫數量
	FROM 
		FIL0030 A
		/*特殊欄位*/
		INNER JOIN FIL0044 E ON E.條碼 = A.廠客單號 AND E.單據類別 = 'C4M' AND E.來源 = 'O'
		INNER JOIN FIL0031 D ON A.單據類別 = D.單別 AND A.單據編號 = D.單號	
	WHERE
		A.單據類別 = 'E13' AND
		D.數值1 > 0 AND
		A.廠客單號 != ' '	
	GROUP BY
		'C4L',
		E.其它單號,
		E.請領料號	
	)	
SELECT 
	A.請領單別,
	A.請領單號,
	A.料號,
	sum(A.核准數量) 請領數量,
	sum(A.發料數量) 發料數量,
	sum((NVL(B.領用數量,0)+NVL(D.領用數量,0))/1000) 日報領用數量,
	sum((NVL(C.退庫數量,0)+NVL(E.退庫數量,0))/1000) 日報退庫數量,
	sum(NVL(C.沿用數量,0)/1000) 日報沿用數量
FROM 
	TMP1 A
	LEFT JOIN TMP2 B ON B.請領單別 = A.請領單別 AND B.請領單號=A.請領單號 AND B.料號 = A.料號
	LEFT JOIN TMP3 C ON C.請領單別 = A.請領單別 AND C.請領單號=A.請領單號 AND C.料號 = A.料號
	LEFT JOIN TMP2A D ON D.請領單別 = A.請領單別 AND D.請領單號=A.請領單號 AND D.料號 = A.料號
	LEFT JOIN TMP3A E ON E.請領單別 = A.請領單別 AND E.請領單號=A.請領單號 AND E.料號 = A.料號	
GROUP BY
	A.請領單別,
	A.請領單號,
	A.料號;

-- Oracle user_views
CREATE VIEW "VIEWFILM018SB" ("請領單別", "請領單號", "料號", "異動數量", "來源單別", "來源單號", "來源序號", "批號", "製令單別", "製令單號", "來源") AS WITH 
TMP0 AS
	(
	SELECT
		A.單據類別 請領單別,
		A.單據編號 請領單號,
		A.產品編號 料號,
		A.異動數量*B.邏輯值一 異動數量,
		A.單據類別 來源單別,
		A.單據編號 來源單號,
		A.單據序號 來源序號,
		' ' 批號,
		' ' 製令單別,
		' ' 製令單號,
		'1.請領' 來源
	FROM 
		FIL0040 A
		INNER JOIN FIL0030 B ON A.單據類別 = B.單據類別 AND A.單據編號 = B.單據編號 
		/*特殊欄位*/
		INNER JOIN FIL0031 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號
		LEFT JOIN FIL0041 D ON A.單據類別 = D.單別 AND A.單據編號 = D.單號 AND A.單據序號 = D.序號
	WHERE
		A.單據類別 = 'C4L'
	),
TMP1 AS
	(
	SELECT
		B.歸屬類別 請領單別,
		B.歸屬編號 請領單號,
		A.文數字1 料號,
		A.異動數量 異動數量,
		A.單據類別 來源單別,
		A.單據編號 來源單號,
		A.單據序號 來源序號,
		D.批號,
		' ' 製令單別,
		' ' 製令單號,
		'2.發料' 來源
	FROM 
		FIL0040 A
		INNER JOIN FIL0030 B ON A.單據類別 = B.單據類別 AND A.單據編號 = B.單據編號 
		/*特殊欄位*/
		INNER JOIN FIL0031 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號
		LEFT JOIN FIL0041 D ON A.單據類別 = D.單別 AND A.單據編號 = D.單號 AND A.單據序號 = D.序號
	WHERE
		A.單據類別 = 'C4M'
	),
/*日報領用*/
TMP2 AS
	(SELECT 
		'C4L' 請領單別,
		E.其它單號 請領單號,
		E.請領料號 料號,
		A.異動數量 異動數量,
		A.單據類別 來源單別,
		A.單據編號 來源單號,
		A.單據序號 來源序號,
		to_char(C.文數字4) 批號,
		decode(D.製程代碼,'C31H',A.前置單別,'C31K',A.前置單別,B.歸屬類別) 製令單別,
		decode(D.製程代碼,'C31H',A.前置單號,'C31K',A.前置單號,B.歸屬編號) 製令單號,
		'3.領用' 來源
	FROM 
		FIL0040 A
		INNER JOIN FIL0030 B ON A.單據類別 = B.單據類別 AND A.單據編號 = B.單據編號 
		/*特殊欄位*/
		INNER JOIN FIL0041 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號 AND A.單據序號 = C.序號
		INNER JOIN FIL0031 D ON A.單據類別 = D.單別 AND A.單據編號 = D.單號
		INNER JOIN FIL0044 E ON E.條碼 = to_char(C.文數字4) AND E.單據類別 = 'C4M' AND E.來源 = 'O' 
	WHERE
		A.單據類別 = 'C41' AND
		A.異動數量 > 0 AND
		((D.製程代碼 BETWEEN 'C31A' AND 'C31C') OR D.製程代碼 = 'C32D' OR D.製程代碼 = 'C31H' OR D.製程代碼 = 'C31K') AND 
		C.文數字4 != ' '	
	),
/*日報退回*/
TMP3 AS
	(SELECT 
		'C4L' 請領單別,
		E.其它單號 請領單號,
		E.請領料號 料號,
		A.退庫數量 異動數量,
		A.單據類別 來源單別,
		A.單據編號 來源單號,
		A.單據序號 來源序號,
		to_char(C.文數字4) 批號,
		decode(D.製程代碼,'C31H',A.前置單別,'C31K',A.前置單別,B.歸屬類別) 製令單別,
		decode(D.製程代碼,'C31H',A.前置單號,'C31K',A.前置單號,B.歸屬編號) 製令單號,
		'4.退回' 來源
	FROM 
		FIL0040 A
		INNER JOIN FIL0030 B ON A.單據類別 = B.單據類別 AND A.單據編號 = B.單據編號 
		/*特殊欄位*/
		INNER JOIN FIL0041 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號 AND A.單據序號 = C.序號
		INNER JOIN FIL0031 D ON A.單據類別 = D.單別 AND A.單據編號 = D.單號
		INNER JOIN FIL0044 E ON E.條碼 = to_char(C.文數字4) AND E.單據類別 = 'C4M' AND E.來源 = 'O' 
	WHERE
		A.單據類別 = 'C41' AND
		A.退庫數量 > 0 AND
		((D.製程代碼 BETWEEN 'C31A' AND 'C31C') OR D.製程代碼 = 'C32D' OR D.製程代碼 = 'C31H' OR D.製程代碼 = 'C31K') AND 
		C.文數字4 != ' '	
	)	
SELECT "請領單別","請領單號","料號","異動數量","來源單別","來源單號","來源序號","批號","製令單別","製令單號","來源" FROM TMP0
UNION ALL 
SELECT "請領單別","請領單號","料號","異動數量","來源單別","來源單號","來源序號","批號","製令單別","製令單號","來源" FROM TMP1
UNION ALL 
SELECT "請領單別","請領單號","料號","異動數量","來源單別","來源單號","來源序號","批號","製令單別","製令單號","來源" FROM TMP2
UNION ALL 
SELECT "請領單別","請領單號","料號","異動數量","來源單別","來源單號","來源序號","批號","製令單別","製令單號","來源" FROM TMP3;

-- Oracle user_views
CREATE VIEW "VIEWFILM018SC" ("請領單別", "請領單號", "日報單號", "料號", "製令單別", "製令單號", "批號", "領用數量", "退庫數量", "沿用數量", "異動日時", "沿用", "製程代碼") AS SELECT 
	'C4L' 請領單別,
	E.其它單號 請領單號,
	A.單據編號 日報單號,
	E.請領料號 料號,
	decode(D.製程代碼,'C31H',A.前置單別,'C31K',A.前置單別,B.歸屬類別) 製令單別,
	decode(D.製程代碼,'C31H',A.前置單號,'C31K',A.前置單號,B.歸屬編號) 製令單號,
	to_char(C.文數字4) 批號,
	A.異動數量 領用數量,
	A.退庫數量*decode(A.Logical1,1,0,1) 退庫數量,
	A.退庫數量*A.Logical1 沿用數量,
	E.異動日期||E.異動時間 異動日時,
	A.Logical1 沿用,
	D.製程代碼
FROM 
	FIL0040 A
	INNER JOIN FIL0030 B ON A.單據類別 = B.單據類別 AND A.單據編號 = B.單據編號 
	/*特殊欄位*/
	INNER JOIN FIL0041 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號 AND A.單據序號 = C.序號
	INNER JOIN FIL0031 D ON A.單據類別 = D.單別 AND A.單據編號 = D.單號
	INNER JOIN FIL0044 E ON E.條碼 = to_char(C.文數字4) AND E.單據類別 = 'C4M' AND E.來源 = 'O' 
WHERE
	A.單據類別 = 'C41' AND
	(A.異動數量 > 0 OR A.退庫數量 > 0) AND
	((D.製程代碼 BETWEEN 'C31A' AND 'C31C') OR D.製程代碼 = 'C32D' OR D.製程代碼 = 'C31H' OR D.製程代碼 = 'C31K') AND 
	C.文數字4 != ' '			

Union ALL
/*裁切領用*/	
SELECT 
	'C4L' 請領單別,
	E.其它單號 請領單號,
	A.單據編號 日報單號,
	E.請領料號 料號,
	'C11' 製令單別,
	'Z' 製令單號,
	TO_CHAR(A.廠客單號) 批號,
	A.折讓 領用數量,
	D.數值1 退庫數量,
	0 沿用數量,
	E.異動日期||E.異動時間 異動日時,
	0 沿用,
	' '
FROM 
	FIL0030 A
	/*特殊欄位*/
	INNER JOIN FIL0044 E ON E.條碼 = A.廠客單號 AND E.單據類別 = 'C4M' AND E.來源 = 'O'
	INNER JOIN FIL0031 D ON A.單據類別 = D.單別 AND A.單據編號 = D.單號	
WHERE
	A.單據類別 = 'E13' AND
	(A.折讓>0 OR D.數值1 > 0) AND
	A.廠客單號 != ' ';

-- Oracle user_views
CREATE VIEW "VIEWFILM019" ("倉庫代碼", "倉庫名稱", "材料編號", "批號", "庫存數") AS (
SELECT
	A.倉庫代碼,
	nvl(B.名稱, ' ') 倉庫名稱,
	A.材料編號,
	A.批號,
	sum(A.異動數量) 庫存數
FROM
	ViewFILM011 A
	LEFT JOIN ViewFIL3106 B ON A.倉庫代碼 = B.代碼
GROUP BY
	A.倉庫代碼,
	nvl(B.名稱, ' '),
	A.材料編號,
	A.批號
);

-- Oracle user_views
CREATE VIEW "VIEWFILM019A" ("倉庫代碼", "倉庫名稱", "材料編號", "批號", "庫存數") AS (
SELECT 
	A.倉庫代碼,
	nvl(B.名稱, ' ') 倉庫名稱,
	A.材料編號,
	A.批號,
	SUM(A.庫存數量) 庫存數
FROM
	(SELECT
		A.倉庫代碼,
		A.材料編號,
		A.批號,
		sum(A.異動數量) 庫存數量
	FROM
		ViewFILM011 A
	WHERE
		A.月份 = TO_CHAR(SYSDATE,'yyyymm')
	GROUP BY 
		A.倉庫代碼,
		A.材料編號,
		A.批號
		
	union all

	SELECT
		A.倉庫代碼,
		A.材料編號,
		A.批號,
		A.庫存數量
	FROM
		fil5001 A
	WHERE
		A.月份 = TO_CHAR(SYSDATE - interval '1' month,'yyyymm')	
	) A 
	LEFT JOIN ViewFIL3106 B ON A.倉庫代碼 = B.代碼
GROUP BY 
	A.倉庫代碼,
	nvl(B.名稱, ' '),
	A.材料編號,
	A.批號
);

-- Oracle user_views
CREATE VIEW "VIEWFILM020A" ("材料編號", "倉庫代碼", "批號", "庫存數") AS (
SELECT 
	A.產品編號 材料編號,
	A.倉庫代碼,	
	nvl(decode(C.批號管理,0,' ',F.批號), ' ') 批號,
	SUM((A.異動數量 + A.贈品數量) * B.材料庫存參數) 庫存數
FROM 
	FIL0040 A
	/*庫存參數*/
	INNER JOIN ViewFIL0020 B ON A.單據類別 = B.單據類別 AND B.材料庫存參數 != 0
	/*主檔*/
	INNER JOIN FIL0030 D ON A.單據類別 = D.單據類別 AND A.單據編號 = D.單據編號
	/*品號檔*/
	INNER JOIN VIEWFIL1012 C ON A.產品編號 = C.產品編號 AND C.產品類別 between 'M' and 'P'
	/*特殊欄位*/
	LEFT JOIN FIL0041 F ON A.單據類別 = F.單別 AND A.單據編號 = F.單號 AND A.單據序號 = F.序號
WHERE
	A.產品編號 != ' ' AND 
	decode(A.異動日期, '00000000', D.單據日期, A.異動日期) <= TO_CHAR(SYSDATE - interval '1' month,'yyyymm')||'99'
GROUP BY
	A.產品編號,
	A.倉庫代碼,	
	nvl(decode(C.批號管理,0,' ',F.批號), ' ')

UNION ALL

/*領料*/
SELECT 
	A.產品編號 材料編號,
	F.庫位代碼 倉庫代碼,	
	decode(G.批號管理,0,' ',C.批號),
	SUM(A.異動數量) 庫存數
FROM 
	FIL0040 A
	INNER JOIN FIL0030 B ON A.單據類別 = B.單據類別 AND A.單據編號 = B.單據編號
	INNER JOIN FIL0041 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號 AND A.單據序號 = C.序號
	INNER JOIN FIL0031 D ON A.單據類別 = D.單別 AND A.單據編號 = D.單號
	LEFT JOIN ViewFIL310P F ON D.機台代碼 = F.代碼
	LEFT JOIN VIEWFIL1012 G ON A.產品編號 = G.產品編號
WHERE
	A.單據類別 = 'C4M' AND
	A.產品編號 != ' ' AND 
	A.異動日期 <= TO_CHAR(SYSDATE - interval '1' month,'yyyymm')||'99'
GROUP BY
	A.產品編號,
	F.庫位代碼,
	decode(G.批號管理,0,' ',C.批號)

UNION ALL

/*材料領用,報廢,油墨領用*/
SELECT 
	A.產品編號 材料編號,
	A.倉庫代碼,
	decode(D.批號管理,0,' ',B.批號) 批號,
	SUM(A.異動數量 * -1) 庫存數
FROM 
	FIL0040 A
	INNER JOIN FIL0041 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號 AND A.單據序號 = B.序號
	INNER JOIN FIL0030 C ON A.單據類別 = C.單據類別 AND A.單據編號 = C.單據編號	
	INNER JOIN VIEWFIL1012 D ON A.產品編號 = D.產品編號
WHERE
	A.單據類別 = 'C41' AND
	A.異動類別 between 'C' and 'E' AND
	A.異動數量 != 0 AND
	A.產品編號 != ' ' AND 
	A.異動日期 <= TO_CHAR(SYSDATE - interval '1' month,'yyyymm')||'99'
GROUP BY
	A.產品編號,
	A.倉庫代碼,
	decode(D.批號管理,0,' ',B.批號)
	
UNION ALL

/*材料領用.氣閥.鐵條-批號1*/
SELECT 
	D.料號 材料編號,
	A.倉庫代碼,
	decode(E.批號管理,0,' ',B.文數字1) 批號,
	SUM(B.數值1 * -1) 庫存數
FROM 
	FIL0040 A
	INNER JOIN FIL0041 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號 AND A.單據序號 = B.序號
	INNER JOIN FIL0031 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號
	INNER JOIN ViewFIL1024 D ON B.文數字1 = D.條碼
	INNER JOIN VIEWFIL1012 E ON D.料號 = E.產品編號
WHERE
	A.單據類別 = 'C41' AND
	A.異動類別 = 'A' AND
	C.製程代碼 between 'C31F' and 'C31G' AND
	B.文數字1 != ' ' AND
	D.料號 != ' ' AND
	A.異動日期 <= TO_CHAR(SYSDATE - interval '1' month,'yyyymm')||'99'
GROUP BY 
	D.料號,
	A.倉庫代碼,
	decode(E.批號管理,0,' ',B.文數字1)


UNION ALL
	
/*材料領用.氣閥.鐵條-批號2*/
SELECT 
	D.料號 材料編號,
	A.倉庫代碼,
	decode(E.批號管理,0,' ',B.文數字2) 批號,
	SUM(B.數值2 * -1) 庫存數
FROM 
	FIL0040 A
	INNER JOIN FIL0041 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號 AND A.單據序號 = B.序號
	INNER JOIN FIL0031 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號
	INNER JOIN ViewFIL1024 D ON B.文數字2 = D.條碼
	INNER JOIN VIEWFIL1012 E ON D.料號 = E.產品編號
WHERE
	A.單據類別 = 'C41' AND
	A.異動類別 = 'A' AND
	C.製程代碼 between 'C31F' and 'C31G' AND
	B.文數字2 != ' ' AND
	D.料號 != ' ' AND
	A.異動日期 <= TO_CHAR(SYSDATE - interval '1' month,'yyyymm')||'99'
GROUP BY
	D.料號,
	A.倉庫代碼,
	decode(E.批號管理,0,' ',B.文數字2)

	
UNION ALL

/*發料回庫(-)
SELECT 
	A.產品編號 材料編號,
	A.倉庫代碼,
	decode(C.批號管理,0,' ',B.批號) 批號,
	SUM(A.贈品數量 * -1) 庫存數
FROM 
	FIL0040 A
	INNER JOIN FIL0041 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號 AND A.單據序號 = B.序號
	INNER JOIN FIL0030 D ON A.單據類別 = D.單據類別 AND A.單據編號 = D.單據編號	
	LEFT JOIN VIEWFIL1012 C ON A.產品編號 = C.產品編號
WHERE
	A.單據類別 = 'C41' AND
	A.異動類別 = 'C' AND
	A.贈品數量 != 0 AND
	A.產品編號 != ' ' AND
	A.異動日期 <= TO_CHAR(SYSDATE - interval '1' month,'yyyymm')||'99'
GROUP BY 
	A.產品編號,
	A.倉庫代碼,
	decode(C.批號管理,0,' ',B.批號)

UNION ALL
*/

/*發料回庫(+)*/
SELECT 
	A.產品編號,
	A.前置單別 倉庫代碼,
	decode(C.批號管理,0,' ',B.批號) 批號,
	SUM(A.贈品數量 * 1) 庫存數
FROM 
	FIL0040 A
	INNER JOIN FIL0041 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號 AND A.單據序號 = B.序號
	LEFT JOIN VIEWFIL1012 C ON A.產品編號 = C.產品編號
	INNER JOIN FIL0030 D ON A.單據類別 = D.單據類別 AND A.單據編號 = D.單據編號		
WHERE
	A.單據類別 = 'C41' AND
	A.異動類別 = 'C' AND
	A.贈品數量 != 0 AND
	A.產品編號 != ' ' AND 
	A.異動日期 <= TO_CHAR(SYSDATE - interval '1' month,'yyyymm')||'99'
GROUP BY
	A.產品編號,
	A.前置單別,
	decode(C.批號管理,0,' ',B.批號)
	
/*廠內盤點調整*/
UNION ALL

SELECT 
	A.產品編號,
	' ' 倉庫代碼,
	decode(E.批號管理,0,' ',C.批號) 批號,
	SUM(A.異動數量 + A.贈品數量) 庫存數
FROM 
	FIL0040 A
	INNER JOIN FIL0030 B ON A.單據類別 = B.單據類別 AND A.單據編號 = B.單據編號
	INNER JOIN FIL0041 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號 AND A.單據序號 = C.序號
	LEFT JOIN VIEWFIL1012 E ON A.產品編號 = E.產品編號
WHERE
	A.單據類別 = 'F32' AND
	A.異動類別 = '2'	AND 
	A.異動日期 <= TO_CHAR(SYSDATE - interval '1' month,'yyyymm')||'99'
GROUP BY
	A.產品編號,
	' ',
	decode(E.批號管理,0,' ',C.批號)
);

-- Oracle user_views
CREATE VIEW "VIEWFILM021A" ("製程代碼", "年月", "製程日報人工時") AS (
SELECT
	A.製程代碼,
	SUBSTR(A.作業日期,1,6) 年月,
	SUM(A.總耗時*A.加工人數) 製程日報人工時
FROM
	ViewFILM201 A
GROUP BY
	A.製程代碼,
	SUBSTR(A.作業日期,1,6)
);

-- Oracle user_views
CREATE VIEW "VIEWFILM022A" ("年月", "日報總人工時", "分攤間接人工", "分攤直接人工") AS (
SELECT
	SUBSTR(A.作業日期,1,6) 年月,
	SUM(A.總耗時*A.加工人數) 日報總人工時,
	MAX(NVL(B.分攤間接人工,0)) 分攤間接人工,
	MAX(NVL(B.分攤直接人工,0)) 分攤直接人工
FROM
	ViewFILM201 A
	LEFT JOIN
	(SELECT 
    SUBSTR(A.年月,1,6) 年月,
		SUM(DECODE(A.成本類別,'B',(A.本月應發金額-A.事病假薪點-A.遲到早退扣支-A.調補扣支),0)) 分攤間接人工,
		SUM(DECODE(A.成本類別,'A',(A.本月應發金額-A.事病假薪點-A.遲到早退扣支-A.調補扣支),0)) 分攤直接人工
	FROM	
		ViewFILHS02 A
	WHERE A.製程代碼 = ' '  AND SUBSTR(A.年月,1,6) > '2025'
	GROUP BY 
		SUBSTR(A.年月,1,6)
	) B ON B.年月 = SUBSTR(A.作業日期,1,6)
WHERE	
	SUBSTR(A.作業日期,1,6)>'2025'	
GROUP BY
	SUBSTR(A.作業日期,1,6)
);

-- Oracle user_views
CREATE VIEW "VIEWFILM101" ("單別", "單號", "序號", "異動日期", "年月", "料號", "最後更新日", "異動數", "異動單價", "異動金額", "來源", "製程代碼") AS (
SELECT
	A.單據類別 單別,
	A.單據編號 單號,
	A.單據序號 序號,
	A.異動日期,
	A.年月,
	A.料號,
	A.最後更新日,
	nvl(A.異動數,0) 異動數,
	nvl(A.異動單價,0) 異動單價,
	nvl(A.異動金額,0) 異動金額,
	A.來源,
	A.製程代碼
FROM
	(	/*期初庫存*/
		SELECT 
			A.單據類別,
			A.單據編號,
			A.單據序號,
			A.異動日期,
			SUBSTR(A.異動日期,1,6) 年月,
			A.產品編號 料號,
			A.最後更新日,
			A.贈品數量 異動數,
			A.異動單價 異動單價,
			A.異動金額 異動金額,
			'1.期初庫存' 來源,
			A.單據類別 製程代碼
		FROM 
			FIL0040 A
		WHERE
			A.單據類別='F35' AND 
			A.異動日期>'2025'
			
		UNION ALL	
		/*進貨發票*/
		SELECT 
			A.單據類別,
			A.單據編號,
			A.單據序號,
			B.單據日期,
			SUBSTR(B.單據日期,1,6) 年月,
			A.產品編號 料號,
			A.最後更新日,
			A.數值4 異動數,
			A.異動單價 異動單價,
			A.異動金額 異動金額,
			'2.本期進貨' 來源,
			A.單據類別 製程代碼
		FROM 
			FIL0040 A
			INNER JOIN FIL0030 B ON A.單據類別 = B.單據類別 AND A.單據編號 = B.單據編號
			LEFT JOIN ViewOfObjProperties C ON C.單據流水號 = B.流水編號
		WHERE
			A.單據類別='D21' and
			B.單據日期>'2025' AND
			A.異動類別=' ' and
			NVL(C.簽核狀態,' ')<>'A'
			
		UNION ALL	
		/*退貨*/
		SELECT 
			A.單據類別,
			A.單據編號,
			A.單據序號,
			B.單據日期,
			SUBSTR(B.單據日期,1,6) 年月,
			A.產品編號 料號,
			A.最後更新日,
			(A.數值4)*-1 異動數,
			(A.異動單價)*-1 異動單價,
			(A.異動金額)*-1 異動金額,
			'2.本期進貨' 來源,
			A.單據類別 製程代碼
		FROM 
			FIL0040 A
			INNER JOIN FIL0030 B ON A.單據類別 = B.單據類別 AND A.單據編號 = B.單據編號
			LEFT JOIN ViewOfObjProperties C ON C.單據流水號 = B.流水編號
		WHERE
			A.單據類別='D41' and
			B.單據日期>'2025' AND
			A.異動類別='S' and
			NVL(C.簽核狀態,' ')<>'A'		
			
		UNION ALL 
			/*日報領料*/
		SELECT 
			A.單據類別,
			A.單據編號,
			A.單據序號,
			B.單據日期,
			SUBSTR(B.單據日期,1,6) 年月,
			TO_CHAR(A.前製程編號) 料號,
			A.最後更新日,
			(A.異動數量 - A.退庫數量)*-1 異動數,
			NVL(E.平均單價,0) 異動單價,
			((A.異動數量 - A.退庫數量)*-1)*NVL(E.平均單價,0) 異動金額,
			'4.領料' 來源,
			D.製程代碼 
		FROM 
			FIL0040 A
			INNER JOIN FIL0030 B ON A.單據類別 = B.單據類別 AND A.單據編號 = B.單據編號 
			INNER JOIN FIL0031 D ON A.單據類別 = D.單別 AND A.單據編號 = D.單號 
			/*特殊欄位*/
			INNER JOIN FIL0041 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號 AND A.單據序號 = C.序號
			LEFT JOIN ViewFILM104 E ON E.年月=SUBSTR(B.單據日期,1,6) AND E.料號=A.前製程編號
		WHERE
			A.單據類別 = 'C41' AND
			A.異動數量 > 0 AND
			((D.製程代碼 BETWEEN 'C31A' AND 'C31C') OR D.製程代碼 = 'C32D' OR D.製程代碼 = 'C31H' OR D.製程代碼 = 'C31K') AND 
			B.單據日期>'2025' AND
			C.文數字4 != ' '				
			
		UNION ALL 
			/*製袋裁切領料*/
		SELECT 
			A.單據類別,
			A.單據編號,
			A.單據序號,
			A.單據日期,
			SUBSTR(A.單據日期,1,6) 年月,
			F.料號,
			A.最後更新日,
			A.異動數*-1 異動數,
			NVL(E.平均單價,0) 異動單價,
			(A.異動數*-1*NVL(E.平均單價,0)) 異動金額,
			'4.領料' 來源,
			D.製程代碼 
		FROM 
			ViewFILM018A A	
			INNER JOIN FIL0043 F ON F.條碼 = A.批號
			INNER JOIN FIL0031 D ON A.單據類別 = D.單別 AND A.單據編號 = D.單號 
			LEFT JOIN ViewFILM104 E ON E.年月=SUBSTR(A.單據日期,1,6) AND E.料號=F.料號
		WHERE
			A.單據日期>'2025'
	) A	
	INNER JOIN ViewFIL1012 E ON A.料號 = E.產品編號
	);

-- Oracle user_views
CREATE VIEW "VIEWFILM102" ("年月", "料號", "來源", "數量", "金額") AS (
SELECT
	A.年月,
	A.料號,
	A.來源,
	SUM(A.異動數) 數量,
	SUM(A.異動金額) 金額
FROM
	FIL004N A
GROUP BY
	A.年月,
	A.料號,
	A.來源
	);

-- Oracle user_views
CREATE VIEW "VIEWFILM103" ("年月", "料號") AS (
SELECT 
	A.年月,
	A.料號
FROM 
	FIL004N A
	);

-- Oracle user_views
CREATE VIEW "VIEWFILM104" ("年月", "料號", "期初數量", "期初金額", "進貨數量", "進貨金額", "平均單價", "耗用數量", "耗用金額", "期末數量", "期末金額") AS (
SELECT DISTINCT 
  A.年月,
  A.料號,
  NVL(B.數量,0) 期初數量,
  NVL(B.金額,0) 期初金額,
  NVL(C.數量,0) 進貨數量,
  NVL(C.金額,0) 進貨金額,
  DECODE(NVL(B.數量,0)+NVL(C.數量,0),0,0,( NVL(B.金額,0)+ NVL(C.金額,0))/(NVL(B.數量,0)+NVL(C.數量,0))) 平均單價,
  NVL(D.數量,0) 耗用數量,
  NVL(D.數量,0)*DECODE(NVL(B.數量,0)+NVL(C.數量,0),0,0,( NVL(B.金額,0)+ NVL(C.金額,0))/(NVL(B.數量,0)+NVL(C.數量,0))) 耗用金額,
  NVL(B.數量,0)+NVL(C.數量,0)+NVL(C.數量,0) 期末數量,
  (NVL(B.數量,0)+NVL(C.數量,0)+NVL(C.數量,0))*DECODE(NVL(B.數量,0)+NVL(C.數量,0),0,0,( NVL(B.金額,0)+ NVL(C.金額,0))/(NVL(B.數量,0)+NVL(C.數量,0))) 期末金額
FROM 
  VIEWFILM102 A
  LEFT JOIN VIEWFILM102 B ON A.年月 = B.年月 AND A.料號 = B.料號 AND B.來源 = '1.期初庫存'
  LEFT JOIN VIEWFILM102 C ON A.年月 = C.年月 AND A.料號 = C.料號 AND C.來源 = '2.本期進貨'
  LEFT JOIN VIEWFILM102 D ON A.年月 = D.年月 AND A.料號 = D.料號 AND D.來源 = '4.領料'
	);

-- Oracle user_views
CREATE VIEW "VIEWFILM105" ("年月", "製程代碼", "直接材料") AS (
SELECT 
  A.年月,
  A.製程代碼,
  SUM(A.異動金額) 直接材料
FROM
  ViewFILM101 A
WHERE
  A.來源 = '4.領料'
GROUP BY 
  A.年月,
  A.製程代碼
	);

-- Oracle user_views
CREATE VIEW "VIEWFILM106" ("單別", "單號", "直接材料") AS (
SELECT 
  A.單別 單別,
  A.單號 單號,
  SUM(A.異動金額) 直接材料
FROM
  ViewFILM101 A
WHERE
  A.來源 = '4.領料'
GROUP BY 
  A.單別,
  A.單號
	);

-- Oracle user_views
CREATE VIEW "VIEWFILM111" ("單別", "單號", "序號", "異動日期", "年月", "料號", "最後更新日", "異動數", "異動單價", "異動金額", "來源") AS (
SELECT
	A.單據類別 單別,
	A.單據編號 單號,
	A.單據序號 序號,
	A.異動日期,
	A.年月,
	A.料號,
	A.最後更新日,
	nvl(A.異動數,0) 異動數,
	nvl(A.異動單價,0) 異動單價,
	nvl(A.異動金額,0) 異動金額,
	A.來源
FROM
	(	/*期初庫存*/
		SELECT 
			A.單據類別,
			A.單據編號,
			A.單據序號,
			A.異動日期,
			SUBSTR(A.異動日期,1,6) 年月,
			A.產品編號 料號,
			A.最後更新日,
			A.贈品數量 異動數,
			A.異動單價 異動單價,
			A.異動金額 異動金額,
			'1.期初庫存' 來源
		FROM 
			FIL0040 A
			INNER JOIN ViewFIL1012 E ON A.產品編號 = E.產品編號
		WHERE
			A.單據類別='F35' AND 
			E.物料大類='C10'
		
		UNION ALL 
		/*客供品條碼入庫*/
		SELECT 
			A.單據類別,
			A.單據編號,
			A.單據序號,
			B.單據日期,
			SUBSTR(B.單據日期,1,6) 年月,
			A.產品編號 料號,
			A.最後更新日,
			(A.數值4) 異動數,
			(A.異動單價) 異動單價,
			(A.異動金額) 異動金額,
			'2.本期進貨' 來源
		FROM 
			FIL0040 A
			INNER JOIN FIL0030 B ON A.單據類別 = B.單據類別 AND A.單據編號 = B.單據編號
			INNER JOIN ViewFIL1012 E ON A.產品編號 = E.產品編號
		WHERE
			A.單據類別='D51' and
			A.異動類別=' ' AND 
			E.物料大類='C10'	
			
		UNION ALL	
		/*退貨*/
		SELECT 
			A.單據類別,
			A.單據編號,
			A.單據序號,
			B.單據日期,
			SUBSTR(B.單據日期,1,6) 年月,
			A.產品編號 料號,
			A.最後更新日,
			(A.數值4)*-1 異動數,
			(A.異動單價)*-1 異動單價,
			(A.異動金額)*-1 異動金額,
			'2.本期進貨' 來源
		FROM 
			FIL0040 A
			INNER JOIN FIL0030 B ON A.單據類別 = B.單據類別 AND A.單據編號 = B.單據編號 
			INNER JOIN ViewFIL1012 E ON A.產品編號 = E.產品編號
		WHERE
			A.單據類別='D52' and
			A.異動類別='S' AND 
			E.物料大類='C10'		
			
		UNION ALL 
			/*領料*/
		SELECT 
			A.單據類別,
			A.單據編號,
			A.單據序號,
			B.單據日期,
			SUBSTR(B.單據日期,1,6) 年月,
			A.產品編號 料號,
			A.最後更新日,
			(A.異動數量 - A.退庫數量)*-1 異動數,
			0 異動單價,
			0 異動金額,
			'4.領料'
		FROM 
			FIL0040 A
			INNER JOIN FIL0030 B ON A.單據類別 = B.單據類別 AND A.單據編號 = B.單據編號 
			/*特殊欄位*/
			INNER JOIN FIL0041 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號 AND A.單據序號 = C.序號
			INNER JOIN ViewFIL1012 E ON A.產品編號 = E.產品編號
		WHERE
			A.領料註記 = 1 AND
			C.文數字4 != ' ' AND 
			E.物料大類='C10'				
			
		UNION ALL 
			/*製袋裁切領料*/
		SELECT 
			A.單據類別,
			A.單據編號,
			A.單據序號,
			A.單據日期,
			SUBSTR(A.單據日期,1,6) 年月,
			F.料號,
			A.最後更新日,
			A.異動數*-1 異動數,
			0 異動單價,
			0 異動金額,
			'4.領料'
		FROM 
			ViewFILM018A A	
			INNER JOIN FIL0043 F ON F.條碼 = A.批號
			INNER JOIN ViewFIL1012 E ON F.料號 = E.產品編號
		WHERE	
			E.物料大類='C10'
	) A	
	INNER JOIN ViewFIL4A4L B ON B.產品編號 = A.料號
	INNER JOIN ViewFIL1012 E ON A.料號 = E.產品編號
	);

-- Oracle user_views
CREATE VIEW "VIEWFILM112" ("年月", "料號", "來源", "數量", "金額") AS (
SELECT
	A.年月,
	A.料號,
	A.來源,
	SUM(A.異動數) 數量,
	SUM(A.異動金額) 金額
FROM
	FIL004O A
GROUP BY
	A.年月,
	A.料號,
	A.來源
	);

-- Oracle user_views
CREATE VIEW "VIEWFILM113" ("年月", "料號") AS (
SELECT 
	A.年月,
	A.料號
FROM 
	FIL004O A
	);

-- Oracle user_views
CREATE VIEW "VIEWFILM201" ("單別", "單號", "作業日期", "結束", "待補", "改件調機", "員工實際時薪", "加工人數", "總耗時", "簽核狀態", "製程代碼", "年月") AS with temp1 as (
	/*前製程*/
SELECT
	A.單據類別 單別,
	A.單據編號 單號,
	A.單據日期 作業日期,
	B.Logical4 結束,
	B.Logical5 待補,
	B.Logical6 改件調機,
	(NVL(W.實際直接人工時薪,0)+NVL(X.實際直接人工時薪,0)+NVL(Y.實際直接人工時薪,0)+NVL(Z.實際直接人工時薪,0)) 員工實際時薪,
	(DECODE(A.業務員,' ',0,1)+DECODE(B.文數字10,' ',0,1)+DECODE(B.文數字11,' ',0,1)+DECODE(B.製程代碼,'C31E',0,DECODE(B.文數字12,' ',0,1))) 加工人數,
	decode(B.時間五,'000000',0,(to_date(to_char(case when B.時間五>B.時間一 then to_date(A.單據日期,'yyyymmdd') else to_date(A.單據日期,'yyyymmdd')+1 end,'yyyymmdd')||B.時間五,'yyyymmddhh24miss')- 
	to_date(trim(A.單據日期)||B.時間一,'yyyymmddhh24miss'))*24) 總耗時,
	nvl(Z3.簽核狀態, '0') 簽核狀態,
	B.製程代碼,
	SUBSTR(A.單據日期,1,6) 年月
FROM
	FIL0030 A
	INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
	LEFT JOIN ViewOfObjProperties Z3 ON A.流水編號 = Z3.單據流水號
	LEFT JOIN ViewFILHS02 W ON SUBSTR(W.年月,1,6) = SUBSTR(A.單據日期,1,6) AND W.員工編號 = A.業務員
	LEFT JOIN ViewFILHS02 X ON SUBSTR(X.年月,1,6) = SUBSTR(A.單據日期,1,6) AND X.員工編號 = B.文數字10
	LEFT JOIN ViewFILHS02 Y ON SUBSTR(Y.年月,1,6) = SUBSTR(A.單據日期,1,6) AND Y.員工編號 = B.文數字11
	LEFT JOIN ViewFILHS02 Z ON SUBSTR(Z.年月,1,6) = SUBSTR(A.單據日期,1,6) AND Z.員工編號 = DECODE(B.製程代碼,'C31E',' ',B.文數字12)
WHERE
	A.單據類別 = 'C41' AND A.單據日期>'2025' AND 
	(B.製程代碼 between 'C31A' and 'C31G' or B.製程代碼 = 'C32D' or B.製程代碼 = 'C31I')
	
UNION ALL
	
	/*檢品*/	
SELECT
	A.單據類別 單別,
	A.單據編號 單號,
	A.單據日期 作業日期,
	B.Logical4 結束,
	B.Logical5 待補,
	B.Logical6 改件調機,
	(NVL(W.實際直接人工時薪,0)+NVL(X.實際直接人工時薪,0)+NVL(Y.實際直接人工時薪,0)+NVL(Z.實際直接人工時薪,0)) 員工實際時薪,
	(DECODE(A.業務員,' ',0,1)+DECODE(B.文數字10,' ',0,1)+DECODE(B.文數字11,' ',0,1)+DECODE(B.文數字12,' ',0,1)) 加工人數,
	decode(B.時間五,'000000',0,(to_date(to_char(case when B.時間五>B.時間一 then to_date(A.單據日期,'yyyymmdd') else to_date(A.單據日期,'yyyymmdd')+1 end,'yyyymmdd')||B.時間五,'yyyymmddhh24miss')- 
	to_date(trim(A.單據日期)||B.時間一,'yyyymmddhh24miss'))*24) 總耗時,
	nvl(Z3.簽核狀態, '0') 簽核狀態,
	B.製程代碼,
	SUBSTR(A.單據日期,1,6) 年月
FROM
	FIL0030 A 
	INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
	LEFT JOIN ViewOfObjProperties Z3 ON A.流水編號 = Z3.單據流水號
	LEFT JOIN ViewFILHS02 W ON SUBSTR(W.年月,1,6) = SUBSTR(A.單據日期,1,6) AND W.員工編號 = A.業務員
	LEFT JOIN ViewFILHS02 X ON SUBSTR(X.年月,1,6) = SUBSTR(A.單據日期,1,6) AND X.員工編號 = B.文數字10
	LEFT JOIN ViewFILHS02 Y ON SUBSTR(Y.年月,1,6) = SUBSTR(A.單據日期,1,6) AND Y.員工編號 = B.文數字11
	LEFT JOIN ViewFILHS02 Z ON SUBSTR(Z.年月,1,6) = SUBSTR(A.單據日期,1,6) AND Z.員工編號 = B.文數字12
WHERE
	A.單據類別 = 'C41' AND A.單據日期>'2025' AND
	(B.製程代碼 = 'C31H' or B.製程代碼 = 'C31K')	
	)
select "單別","單號","作業日期","結束","待補","改件調機","員工實際時薪","加工人數","總耗時","簽核狀態","製程代碼","年月" from temp1;

-- Oracle user_views
CREATE VIEW "VIEWFILM202" ("年月", "製程代碼", "實際直接人工", "分攤直接人工") AS with temp1 as(	
SELECT
	SUBSTR(A.單據日期,1,6) 年月,
	B.製程代碼,
	sum((NVL(W.實際直接人工時薪,0)+NVL(X.實際直接人工時薪,0)+NVL(Y.實際直接人工時薪,0)+NVL(Z.實際直接人工時薪,0))*decode(B.時間五,'000000',0,(to_date(to_char(case when B.時間五>B.時間一 then to_date(A.單據日期,'yyyymmdd') else to_date(A.單據日期,'yyyymmdd')+1 end,'yyyymmdd')||B.時間五,'yyyymmddhh24miss')- 
	to_date(trim(A.單據日期)||B.時間一,'yyyymmddhh24miss'))*24)) 實際直接人工
FROM
	FIL0030 A
	INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
	LEFT JOIN ViewFILHS02 W ON SUBSTR(W.年月,1,6) = SUBSTR(A.單據日期,1,6) AND W.員工編號 = A.業務員
	LEFT JOIN ViewFILHS02 X ON SUBSTR(X.年月,1,6) = SUBSTR(A.單據日期,1,6) AND X.員工編號 = B.文數字10
	LEFT JOIN ViewFILHS02 Y ON SUBSTR(Y.年月,1,6) = SUBSTR(A.單據日期,1,6) AND Y.員工編號 = B.文數字11
	LEFT JOIN ViewFILHS02 Z ON SUBSTR(Z.年月,1,6) = SUBSTR(A.單據日期,1,6) AND Z.員工編號 = DECODE(B.製程代碼,'C31E',' ',B.文數字12)
WHERE
	A.單據類別 = 'C41' AND A.單據日期>'2025' AND 
	(B.製程代碼 between 'C31A' and 'C31G' or B.製程代碼 = 'C32D' or B.製程代碼 = 'C32I')
GROUP BY
	SUBSTR(A.單據日期,1,6),
	B.製程代碼

union all 

SELECT
	SUBSTR(A.單據日期,1,6) 年月,
	B.製程代碼,
	sum((NVL(W.實際直接人工時薪,0)+NVL(X.實際直接人工時薪,0)+NVL(Y.實際直接人工時薪,0)+NVL(Z.實際直接人工時薪,0))*decode(B.時間五,'000000',0,(to_date(to_char(case when B.時間五>B.時間一 then to_date(A.單據日期,'yyyymmdd') else to_date(A.單據日期,'yyyymmdd')+1 end,'yyyymmdd')||B.時間五,'yyyymmddhh24miss')- 
	to_date(trim(A.單據日期)||B.時間一,'yyyymmddhh24miss'))*24)) 實際直接人工
FROM
	FIL0030 A
	INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
	LEFT JOIN ViewFILHS02 W ON SUBSTR(W.年月,1,6) = SUBSTR(A.單據日期,1,6) AND W.員工編號 = A.業務員
	LEFT JOIN ViewFILHS02 X ON SUBSTR(X.年月,1,6) = SUBSTR(A.單據日期,1,6) AND X.員工編號 = B.文數字10
	LEFT JOIN ViewFILHS02 Y ON SUBSTR(Y.年月,1,6) = SUBSTR(A.單據日期,1,6) AND Y.員工編號 = B.文數字11
	LEFT JOIN ViewFILHS02 Z ON SUBSTR(Z.年月,1,6) = SUBSTR(A.單據日期,1,6) AND Z.員工編號 = B.文數字12
WHERE
	A.單據類別 = 'C41' AND A.單據日期>'2025' AND
	(B.製程代碼 = 'C31H' or B.製程代碼 = 'C31K')	
GROUP BY
	SUBSTR(A.單據日期,1,6),
	B.製程代碼
)
select 
	A.年月,
	A.製程代碼,
	A.實際直接人工,
	NVL(B.分攤直接人工,0) 分攤直接人工
from 
	temp1 A
	LEFT JOIN 
	(
	SELECT 
		A.年月,
		A.製程代碼,
		SUM(DECODE(A.成本類別,'A',(A.本月應發金額-A.事病假薪點-A.遲到早退扣支-A.調補扣支),0)) 分攤直接人工
	FROM	
		ViewFILHS02 A
	GROUP BY 
		A.年月,
		A.製程代碼
	) B ON SUBSTR(A.年月,1,6)=SUBSTR(B.年月,1,6) AND A.製程代碼=B.製程代碼;

-- Oracle user_views
CREATE VIEW "VIEWFILM203" ("單別", "單號", "作業日期", "製令單號", "訂單單號", "產品編號", "簽核狀態", "製程代碼", "年月") AS with temp1 as (
	/*前製程*/
SELECT
	A.單據類別 單別,
	A.單據編號 單號,
	A.單據日期 作業日期,
	A.歸屬編號 製令單號,
	C.訂單單號,
	C.產品編號,
	nvl(Z3.簽核狀態, '0') 簽核狀態,
	B.製程代碼,
	SUBSTR(A.單據日期,1,6) 年月
FROM
	FIL0030 A
	INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
	INNER JOIN ViewFIL4030 C ON A.歸屬類別 = C.製令單別 AND A.歸屬編號 = C.製令單號
	LEFT JOIN ViewOfObjProperties Z3 ON A.流水編號 = Z3.單據流水號
	LEFT JOIN ViewFILHS02 W ON SUBSTR(W.年月,1,6) = SUBSTR(A.單據日期,1,6) AND W.員工編號 = A.業務員
	LEFT JOIN ViewFILHS02 X ON SUBSTR(X.年月,1,6) = SUBSTR(A.單據日期,1,6) AND X.員工編號 = B.文數字10
	LEFT JOIN ViewFILHS02 Y ON SUBSTR(Y.年月,1,6) = SUBSTR(A.單據日期,1,6) AND Y.員工編號 = B.文數字11
	LEFT JOIN ViewFILHS02 Z ON SUBSTR(Z.年月,1,6) = SUBSTR(A.單據日期,1,6) AND Z.員工編號 = DECODE(B.製程代碼,'C31E',' ',B.文數字12)
WHERE
	A.單據類別 = 'C41' AND A.單據日期>'2025' AND 
	(B.製程代碼 between 'C31A' and 'C31G' or B.製程代碼 = 'C32D' or B.製程代碼 = 'C31I')
	
UNION ALL
	
	/*檢品*/	
SELECT
	A.單據類別 單別,
	A.單據編號 單號,
	A.單據日期 作業日期,
	to_char(M.前置單號) 製令單號,
	C.訂單單號,
	C.產品編號,
	nvl(Z3.簽核狀態, '0') 簽核狀態,
	B.製程代碼,
	SUBSTR(A.單據日期,1,6) 年月
FROM
	FIL0040 M
	INNER JOIN FIL0030 A ON A.單據類別 = M.單據類別 AND A.單據編號 = M.單據編號
	INNER JOIN FIL0031 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
	INNER JOIN ViewFIL4030 C ON M.前置單別 = C.製令單別 AND M.前置單號 = C.製令單號
	LEFT JOIN ViewOfObjProperties Z3 ON A.流水編號 = Z3.單據流水號
	LEFT JOIN ViewFILHS02 W ON SUBSTR(W.年月,1,6) = SUBSTR(A.單據日期,1,6) AND W.員工編號 = A.業務員
	LEFT JOIN ViewFILHS02 X ON SUBSTR(X.年月,1,6) = SUBSTR(A.單據日期,1,6) AND X.員工編號 = B.文數字10
	LEFT JOIN ViewFILHS02 Y ON SUBSTR(Y.年月,1,6) = SUBSTR(A.單據日期,1,6) AND Y.員工編號 = B.文數字11
	LEFT JOIN ViewFILHS02 Z ON SUBSTR(Z.年月,1,6) = SUBSTR(A.單據日期,1,6) AND Z.員工編號 = B.文數字12
WHERE
	A.單據類別 = 'C41' AND A.單據日期>'2025' AND
	(B.製程代碼 = 'C31H' or B.製程代碼 = 'C31K')	
	)
select "單別","單號","作業日期","製令單號","訂單單號","產品編號","簽核狀態","製程代碼","年月" from temp1;

-- Oracle user_views
CREATE VIEW "VIEWFILM204" ("製程代碼", "年月", "製程直接人工每人工時", "製程製造費用每人工時") AS with temp1 as ( 
SELECT
	M.製程代碼,
	M.年月,
	case when nvl(A.製程日報人工時,0)=0 then 0 else nvl(C.分攤直接人工,0)/nvl(A.製程日報人工時,0) end 製程直接人工每人工時,
	case when nvl(A.製程日報人工時,0)=0 then 0 else (case when nvl(B.日報總人工時,0)=0 then 0 else nvl(B.分攤間接人工,0)*nvl(A.製程日報人工時,0)/nvl(B.日報總人工時,0) end)/nvl(A.製程日報人工時,0) end 製程製造費用每人工時
FROM
	FIL1051 M
	/*製程人工時月彙總*/
	LEFT JOIN ViewFILM021A A ON M.年月 = A.年月 AND M.製程代碼 = A.製程代碼
	/*人工時月彙總*/
	LEFT JOIN ViewFILM022A B ON B.年月=M.年月
	/*製程實際直接人工*/
	LEFT JOIN ViewFILM202 C ON C.年月=M.年月 AND C.製程代碼=M.製程代碼
)
select "製程代碼","年月","製程直接人工每人工時","製程製造費用每人工時" from temp1;

-- Oracle user_views
CREATE VIEW "VIEWFILR001" ("單別", "單號", "單據日期", "品質異常單別", "品質異常單號", "品管課填表人", "品管課填表人姓名", "公司代碼", "公司名稱", "簽核系統", "簽核狀態", "簽核系統_結案", "客戶編號", "客戶簡稱", "客戶名稱", "摘要", "異常別權責單位", "流水編號", "員工流水編號", "填表人部門編號", "填表人", "填表人姓名", "填表日", "標籤數", "最後更新者", "更新者姓名", "最後更新日") AS (
SELECT
	A.單據類別 單別,
	A.單據編號 單號,
	A.單據日期,
	A.歸屬類別 品質異常單別,
	A.歸屬編號 品質異常單號,
	A.業務員 品管課填表人,
	nvl(C.員工姓名,' ') 品管課填表人姓名, 
	A.公司代碼,
	nvl(K.全名, ' ') 公司名稱,
	A.簽核系統, 
	NVL(Z3.簽核狀態,'0') 簽核狀態,
	A.簽核系統_結案, 
	A.廠客編號 客戶編號,
	nvl(E.簡稱, ' ') 客戶簡稱,
	nvl(E.全名, ' ') 客戶名稱,
	B.摘要,
	B.異常別權責單位,
	A.流水編號,
	nvl(Z1.Serial_Num,' ') 員工流水編號,
	nvl(Z1.部門編號,' ') 填表人部門編號,
	A.填表人,
	nvl(Z1.員工姓名,' ') 填表人姓名, 
	A.填表日, 
	NVL(Z4.標籤數,0) 標籤數,
	A.最後更新者,
	nvl(Z2.員工姓名,' ') 更新者姓名, 
	A.最後更新日
FROM
	FIL0030 A
	INNER JOIN FIL003K1 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
	LEFT JOIN FIL0010 C ON A.業務員 = C.員工編號
	LEFT JOIN FIL0011 E ON A.廠客編號 = E.編號
	LEFT JOIN ViewFIL0011 K ON A.公司代碼 = K.代碼
	LEFT JOIN FIL0010 Z1 ON A.填表人 = Z1.員工編號
	LEFT JOIN FIL0010 Z2 ON A.最後更新者 = Z2.員工編號	
	LEFT JOIN ViewOfObjProperties Z3 ON A.流水編號 = Z3.單據流水號
	LEFT JOIN 
	(SELECT 單別,單號,COUNT(序號) 標籤數 FROM FIL0041 WHERE 單別='R01' AND 標籤列印次數>0 GROUP BY 單別,單號) Z4 ON Z4.單別=A.單據類別 AND Z4.單號=A.單據編號
WHERE
	A.單據類別 = 'R01');

-- Oracle user_views
CREATE VIEW "VIEWFILR002" ("單別", "單號", "序號", "製令單別", "製令單號", "產品編號", "產品名稱", "產品規格", "材質結構", "交貨備註", "異常備註", "成品規格", "交貨日期", "交貨數量", "異常數量", "單位代碼", "單位名稱", "異常單位代碼", "異常單位名稱", "客戶編號", "流水編號", "最後更新者", "更新者姓名", "最後更新日") AS (SELECT 
	A.單據類別 單別, 
	A.單據編號 單號,
	A.單據序號 序號,
	A.前置單別 製令單別,
	A.前置單號 製令單號,
	A.產品編號,
	nvl(E.客戶報價品名,' ') 產品名稱,
	nvl(E.客戶報價規格,' ') 產品規格,
	nvl(E.文數字4,' ') 材質結構,
	nvl(E.文字1,' ') 交貨備註,
	nvl(E.文字2,' ') 異常備註,
	nvl(D.規格, ' ') 成品規格,
	A.異動日期 交貨日期,
	A.異動數量 交貨數量,
	A.贈品數量 異常數量,
	A.單位代碼 單位代碼,
	nvl(F1.名稱, ' ') 單位名稱,
	A.倉庫代碼 異常單位代碼,
	nvl(F1.名稱, ' ') 異常單位名稱,
	C.廠客編號 客戶編號,
	A.流水編號,
	A.最後更新者,
	NVL(Z1.員工姓名,' ') 更新者姓名,
	A.最後更新日
FROM 
	FIL0040 A
	INNER JOIN FIL0032 B ON A.前置單別 = B.製令單別 AND A.前置單號 = B.製令單號
	INNER JOIN FIL0030 C ON A.前置單別 = C.單據類別 AND A.前置單號 = C.單據編號
	LEFT JOIN FIL0012 D ON B.產品編號 = D.產品編號
	LEFT JOIN FIL0041 E ON A.單據類別 = E.單別 AND A.單據編號 = E.單號 AND A.單據序號 = E.序號
	LEFT JOIN ViewFIL3103 F1 ON A.單位代碼 = F1.代碼
	LEFT JOIN ViewFIL3103 F2 ON A.倉庫代碼 = F2.代碼
	LEFT JOIN FIL0010 Z1 ON A.最後更新者 = Z1.員工編號
WHERE
	A.單據類別 = 'R01' AND
	A.單據編號 <>' ');

-- Oracle user_views
CREATE VIEW "VIEWFILR010" ("單別", "單號", "單據日期", "客戶編號", "客戶名稱", "客訴單別", "客訴單號", "公司代碼", "公司名稱", "簽核系統", "簽核狀態", "簽核系統_結案", "異常大類", "異常大類名稱", "異常原因分類", "異常原因分類名稱", "異常單位", "異常單位名稱", "異常現象_作業者", "異常現象_作業者姓名", "異常現象_摘要", "異常現象_詳述", "異常原因分析", "矯正措施_摘要1", "矯正措施_摘要2", "再發防止措施", "追蹤確認", "異常現象_填表人", "異常現象_填表人姓名", "業務擔當", "業務擔當姓名", "流水編號", "員工流水編號", "矯正人流水編號", "矯正人姓名", "填表人", "填表人部門編號", "填表人姓名", "單位年月", "填表日", "最後更新者", "更新者姓名", "最後更新日") AS (
SELECT
	A.單據類別 單別,
	A.單據編號 單號,
	A.單據日期,
	A.廠客編號 客戶編號,
	nvl(G.全名, ' ') 客戶名稱,
	A.歸屬類別 客訴單別,
	A.歸屬編號 客訴單號,
	A.公司代碼,
	nvl(Z3.全名, ' ') 公司名稱,
	A.簽核系統, 
	nvl(Z4.簽核狀態,'0') 簽核狀態,
	A.簽核系統_結案, 
	B.異常大類,
	nvl(C.名稱, ' ') 異常大類名稱,
	B.異常原因分類,
	nvl(D.名稱, ' ') 異常原因分類名稱,
	B.異常單位,
	nvl(E.部門名稱, ' ') 異常單位名稱,
	B.異常現象_作業者,
	B.異常現象_作業者姓名,
	B.異常現象_摘要,
	B.異常現象_詳述,
	B.異常原因分析,
	B.矯正措施_摘要1,
	B.矯正措施_摘要2,
	B.再發防止措施,
	B.追蹤確認,
	B.異常現象_填表人,
	nvl(F.員工姓名, ' ') 異常現象_填表人姓名,
	A.業務員 業務擔當,
	nvl(Z6.員工姓名,' ') 業務擔當姓名,
	A.流水編號,
	nvl(Z1.Serial_Num,' ') 員工流水編號,
	nvl(Z5.Serial_Num,' ') 矯正人流水編號,
	nvl(Z5.員工姓名,' ') 矯正人姓名,
	A.填表人,
	nvl(Z1.部門編號,' ') 填表人部門編號,
	nvl(Z1.員工姓名,' ') 填表人姓名, 
	B.異常單位||substr(A.單據日期,1,6) 單位年月,
	A.填表日, 
	A.最後更新者,
	nvl(Z2.員工姓名,' ') 更新者姓名, 
	A.最後更新日
FROM
	FIL0030 A
	INNER JOIN FIL003L1 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
	LEFT JOIN ViewFIL3114 C ON B.異常大類 = C.代碼
	LEFT JOIN ViewFIL3115 D ON B.異常原因分類 = D.代碼
	LEFT JOIN FIL0020 E ON B.異常單位 = E.部門編號
	LEFT JOIN FIL0010 F ON B.異常現象_填表人 = F.員工編號
	LEFT JOIN FIL0011 G ON A.廠客編號 = G.編號
	LEFT JOIN FIL0010 Z1 ON A.填表人 = Z1.員工編號
	LEFT JOIN FIL0010 Z2 ON A.最後更新者 = Z2.員工編號	
	LEFT JOIN ViewFIL0011 Z3 ON A.公司代碼 = Z3.代碼
	LEFT JOIN ViewOfObjProperties Z4 ON A.流水編號 = Z4.單據流水號
	LEFT JOIN FIL0010 Z5 ON B.矯正措施_填表人 = Z5.員工編號
	LEFT JOIN FIL0010 Z6 ON A.業務員 = Z6.員工編號
WHERE
	A.單據類別 = 'R02');

-- Oracle user_views
CREATE VIEW "VIEWFILR010D" ("單別", "單號", "序號", "加工別", "製令單別", "製令單號", "產品編號", "產品名稱", "材質結構", "成品規格", "生產總量", "異常數量", "單位代碼", "單位名稱", "異常單位代碼", "異常單位名稱", "交貨日期", "客戶編號", "特採數量", "報廢數量", "全批", "生產中", "異常數量待確認", "特採數量待確認", "報廢數量待確認", "尚未生產", "建檔日期", "建檔時間", "流水編號", "主檔流水編號", "最後更新者", "更新者姓名", "最後更新日") AS (
SELECT 
	A.單據類別 單別, 
	A.單據編號 單號,
	A.單據序號 序號,
	A.異動類別 加工別,
	A.前置單別 製令單別,
	A.前置單號 製令單號,
	B.產品編號,
	B.產品名稱,
	A.備註說明 材質結構,
	nvl(D.規格, ' ') 成品規格,
	A.異動數量 生產總量,
	A.贈品數量 異常數量,
	A.單位代碼,
	nvl(F1.名稱, ' ') 單位名稱,
	A.相關代碼1 異常單位代碼,
	nvl(F2.名稱, ' ') 異常單位名稱,
	A.異動日期 交貨日期,
	C.廠客編號 客戶編號,
	A.數值1 特採數量,
	A.數值2 報廢數量,
	A.Logical1 全批,
	A.Logical2 生產中,
	A.Logical3 異常數量待確認,
	A.Logical4 特採數量待確認,
	A.Logical5 報廢數量待確認,
	A.領料註記 尚未生產,
	A.預交日 建檔日期,
	A.Time1 建檔時間,
	A.流水編號,
	M.流水編號 主檔流水編號,
	A.最後更新者,
	NVL(Z1.員工姓名,' ') 更新者姓名,
	A.最後更新日
FROM 
	FIL0040 A
	INNER JOIN FIL0030 M ON M.單據類別 = A.單據類別 AND M.單據編號 = A.單據編號
	INNER JOIN FIL0032 B ON A.前置單別 = B.製令單別 AND A.前置單號 = B.製令單號
	INNER JOIN FIL0030 C ON A.前置單別 = C.單據類別 AND A.前置單號 = C.單據編號
	LEFT JOIN ViewFIL1012 D ON REGEXP_SUBSTR(B.產品編號, '[^/]+', 1,1) = D.產品編號
	LEFT JOIN ViewFIL3103 F1 ON A.單位代碼 = F1.代碼
	LEFT JOIN ViewFIL3103 F2 ON A.相關代碼1 = F2.代碼
	LEFT JOIN FIL0010 Z1 ON A.最後更新者 = Z1.員工編號
WHERE
	A.單據類別 = 'R02');

-- Oracle user_views
CREATE VIEW "VIEWFILR011" ("單別", "單號", "單據日期", "品質異常單別", "品質異常單號", "品管課填表人", "品管課填表人姓名", "公司代碼", "公司名稱", "簽核系統", "簽核狀態", "簽核系統_結案", "客戶編號", "客戶簡稱", "客戶名稱", "摘要", "異常別權責單位", "流水編號", "員工流水編號", "填表人部門編號", "填表人", "填表人姓名", "填表日", "最後更新者", "更新者姓名", "最後更新日") AS (
SELECT
	M.單據類別 單別,
	M.單據編號 單號,
	A.單據日期,
	A.歸屬類別 品質異常單別,
	A.歸屬編號 品質異常單號,
	A.業務員 品管課填表人,
	nvl(C.員工姓名,' ') 品管課填表人姓名, 
	A.公司代碼,
	nvl(K.全名, ' ') 公司名稱,
	A.簽核系統, 
	nvl(Z3.簽核狀態,'0') 簽核狀態,
	A.簽核系統_結案, 
	A.廠客編號 客戶編號,
	nvl(E.簡稱, ' ') 客戶簡稱,
	nvl(E.全名, ' ') 客戶名稱,
	B.摘要,
	B.異常別權責單位,
	M.流水編號,
	nvl(Z1.Serial_Num,' ') 員工流水編號,
	nvl(Z1.部門編號,' ') 填表人部門編號,
	M.填表人,
	nvl(Z1.員工姓名,' ') 填表人姓名, 
	M.填表日, 
	M.最後更新者,
	nvl(Z2.員工姓名,' ') 更新者姓名, 
	M.最後更新日
FROM
	FIL0030 M
	INNER JOIN FIL0030 A ON A.流水編號 = 'R01'||SUBSTR(M.流水編號,4,60)
	INNER JOIN FIL003K1 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
	INNER JOIN ViewOfObjProperties Z5 ON Z5.單據流水號 = 'R01'||SUBSTR(M.流水編號,4,60) AND Z5.簽核狀態 ='E'
	LEFT JOIN FIL0010 C ON A.業務員 = C.員工編號
	LEFT JOIN FIL0011 E ON A.廠客編號 = E.編號
	LEFT JOIN ViewFIL0011 K ON A.公司代碼 = K.代碼
	LEFT JOIN FIL0010 Z1 ON M.填表人 = Z1.員工編號
	LEFT JOIN FIL0010 Z2 ON M.最後更新者 = Z2.員工編號	
	LEFT JOIN ViewOfObjProperties Z3 ON M.流水編號 = Z3.單據流水號
WHERE
	M.單據類別 = 'R11');

-- Oracle user_views
CREATE VIEW "VIEWFILR012" ("單別", "單號", "生產總量", "異常數量", "不良率", "待確認筆數", "單位不同", "總產量單位") AS (
SELECT 
	A.單據類別 單別, 
	A.單據編號 單號,
	sum(A.異動數量) 生產總量,
	sum(decode(A.Logical3,0,A.贈品數量)) 異常數量,
	decode(sum(A.異動數量),0,0,round(sum(decode(A.Logical3,0,A.贈品數量)) / sum(A.異動數量) * 100,3)) 不良率,
	sum(decode(A.Logical3,1,1,0)) 待確認筆數,
	sum(case when A.單位代碼=to_char(A.相關代碼1) or A.相關代碼1=' ' then 0 else 1 end) 單位不同,
	' ' 總產量單位
FROM 
	FIL0040 A
WHERE
	A.單據類別 = 'R02'
GROUP BY
	A.單據類別,
	A.單據編號);

-- Oracle user_views
CREATE VIEW "VIEWFILR013" ("異常單位", "異常年月", "異常單位名稱", "異常次數", "單位年月") AS (
SELECT
	A.異常單位,
	substr(B.單據日期, 1, 6) 異常年月,
	nvl(E.部門名稱, ' ') 異常單位名稱,
	count(*) 異常次數,
	A.異常單位||substr(B.單據日期,1,6) 單位年月
FROM
	FIL003L1 A
	INNER JOIN FIL0030 B ON A.單別 = B.單據類別 AND A.單號 = B.單據編號
	LEFT JOIN FIL0020 E ON A.異常單位 = E.部門編號
GROUP BY
	A.異常單位,
	substr(B.單據日期, 1, 6),
	nvl(E.部門名稱, ' ')
);

-- Oracle user_views
CREATE VIEW "VIEWFILR014" ("異常單位", "作業人員", "異常年月", "異常次數") AS (
SELECT
	A.異常單位,
	A.作業人員,
	A.異常年月,
	count(*) 異常次數
FROM
	(SELECT distinct
		A.異常單位,A.單別,A.單號,
		REGEXP_SUBSTR(A.異常現象_作業者, '[^,]+', 1, level) AS 作業人員,
		substr(B.單據日期, 1, 6) 異常年月
	FROM 
		fil003L1 A
		INNER JOIN FIL0030 B ON A.單別 = B.單據類別 AND A.單號 = B.單據編號
	CONNECT BY 
		REGEXP_SUBSTR(A.異常現象_作業者, '[^,]+', 1, level) IS NOT NULL
	) A
WHERE
	A.作業人員<>' '	
GROUP BY
	A.異常單位,
	A.作業人員,
	A.異常年月
);

-- Oracle user_views
CREATE VIEW "VIEWFILR020" ("單別", "單號", "單據日期", "客戶編號", "客戶名稱", "公司代碼", "公司名稱", "簽核系統", "簽核狀態", "簽核系統_結案", "退貨日期", "退貨方式", "退貨方式名稱", "退貨件數", "退貨方式說明", "退貨原因", "處理數量_入庫", "處理數量_銷毀", "處理數量_其他", "後續處理", "品管課負責人姓名", "流水編號", "員工流水編號", "填表人部門編號", "填表人", "填表人姓名", "填表日", "最後更新者", "更新者姓名", "最後更新日") AS (
SELECT
	A.單據類別 單別,
	A.單據編號 單號,
	A.單據日期,
	A.廠客編號 客戶編號,
	nvl(G.全名, ' ') 客戶名稱,
	A.公司代碼,
	nvl(Z3.全名, ' ') 公司名稱,
	A.簽核系統, 
	nvl(Z3.簽核狀態,'0') 簽核狀態,
	A.簽核系統_結案,
	B.退貨日期,
	B.退貨方式,
	decode(B.退貨方式,'A','新竹貨運','B','大榮貨運','C','宅配公司','D','司機','E','業務','其它') 退貨方式名稱,
	B.退貨件數,
	B.退貨方式說明,
	B.退貨原因,
	B.處理數量_入庫,
	B.處理數量_銷毀,
	B.處理數量_其他,
	B.後續處理,
	nvl(Z4.員工姓名,' ') 品管課負責人姓名,
	A.流水編號,
	nvl(Z1.Serial_Num,' ') 員工流水編號,
	nvl(Z1.部門編號,' ') 填表人部門編號,
	A.填表人,
	nvl(Z1.員工姓名,' ') 填表人姓名, 
	A.填表日, 
	A.最後更新者,
	nvl(Z2.員工姓名,' ') 更新者姓名, 
	A.最後更新日
FROM
	FIL0030 A
	INNER JOIN FIL003M1 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
	LEFT JOIN FIL0011 G ON A.廠客編號 = G.編號
	LEFT JOIN FIL0010 Z1 ON A.填表人 = Z1.員工編號
	LEFT JOIN FIL0010 Z2 ON A.最後更新者 = Z2.員工編號	
	LEFT JOIN ViewFIL0011 Z3 ON A.公司代碼 = Z3.代碼
	LEFT JOIN FIL0010 Z4 ON B.品管課負責人 = Z4.員工編號	
	LEFT JOIN ViewOfObjProperties Z3 ON A.流水編號 = Z3.單據流水號
WHERE
	A.單據類別 = 'R03');

-- Oracle user_views
CREATE VIEW "VIEWFILR021" ("單別", "單號", "序號", "製令單別", "製令單號", "產品編號", "產品名稱", "備註說明", "數量", "客戶編號", "單位代碼", "單位名稱", "流水編號", "最後更新者", "更新者姓名", "最後更新日") AS (
SELECT 
	A.單據類別 單別, 
	A.單據編號 單號,
	A.單據序號 序號,
	A.前置單別 製令單別,
	A.前置單號 製令單號,
	A.產品編號,
	A.文數字1 產品名稱,
	A.備註說明,
	A.異動數量 數量,
	C.廠客編號 客戶編號,
	A.單位代碼,
	nvl(F1.名稱, ' ') 單位名稱,
	A.流水編號,
	A.最後更新者,
	NVL(Z1.員工姓名,' ') 更新者姓名,
	A.最後更新日
FROM 
	FIL0040 A
	INNER JOIN FIL0032 B ON A.前置單別 = B.製令單別 AND A.前置單號 = B.製令單號
	INNER JOIN FIL0030 C ON A.前置單別 = C.單據類別 AND A.前置單號 = C.單據編號
	LEFT JOIN ViewFIL3103 F1 ON A.單位代碼 = F1.代碼
	LEFT JOIN FIL0010 Z1 ON A.最後更新者 = Z1.員工編號
WHERE
	A.單據類別 = 'R03');

-- Oracle user_views
CREATE VIEW "VIEWFILR030" ("單別", "單號", "單據日期", "異常單別", "異常單號", "異常明細序號", "廠商編號", "廠商名稱", "公司代碼", "公司名稱", "簽核系統", "簽核狀態", "簽核系統_結案", "特採類別", "進料批號", "進料數量", "進料單位", "進料單位名稱", "進料日期", "原物料名稱", "製令單別", "製令單號", "客戶編號", "客戶名稱", "生產數量", "製造日期", "責任單位", "責任單位名稱", "作業人員", "作業人員姓名", "特採日期", "特採數量", "特採單位", "特採單位名稱", "不良原因", "流水編號", "員工流水編號", "填表人部門編號", "填表人", "填表人姓名", "填表日", "最後更新者", "更新者姓名", "最後更新日") AS (
SELECT
	A.單據類別 單別,
	A.單據編號 單號,
	A.單據日期,
	A.歸屬類別 異常單別,
	A.歸屬編號 異常單號,
	A.歸屬序號 異常明細序號,
	A.廠客編號 廠商編號,
	nvl(G.全名, ' ') 廠商名稱,
	A.公司代碼,
	nvl(Z3.全名, ' ') 公司名稱,
	A.簽核系統, 
	nvl(Z3.簽核狀態,'0') 簽核狀態,
	A.簽核系統_結案,
	B.特採類別,
	B.進料批號,
	B.進料數量,
	B.進料單位,
	nvl(C.名稱, ' ') 進料單位名稱,
	B.進料日期,
	B.原物料名稱,
	D.前置單別 製令單別,
	D.前置單號 製令單號,
	E.廠客編號 客戶編號,
	nvl(F.全名, ' ') 客戶名稱,
	D.異動數量 生產數量,
	B.製造日期,
	H.異常單位 責任單位,
	nvl(I.部門名稱, ' ') 責任單位名稱,
	B.作業人員,
	B.作業人員姓名,
	B.特採日期,
	B.特採數量,
	B.特採單位,
	nvl(C1.名稱, ' ') 特採單位名稱,
	H.異常現象_詳述 不良原因,
	A.流水編號,
	nvl(Z1.Serial_Num,' ') 員工流水編號,
	nvl(Z1.部門編號,' ') 填表人部門編號,
	A.填表人,
	nvl(Z1.員工姓名,' ') 填表人姓名, 
	A.填表日, 
	A.最後更新者,
	nvl(Z2.員工姓名,' ') 更新者姓名, 
	A.最後更新日
FROM
	FIL0030 A
	INNER JOIN FIL003N1 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
	LEFT JOIN ViewFIL3103 C ON B.進料單位 = C.代碼
	LEFT JOIN ViewFIL3103 C1 ON B.特採單位 = C1.代碼
	/*異常明細*/
	LEFT JOIN FIL0040 D ON A.歸屬類別 = D.單據類別 AND A.歸屬編號 = D.單據編號 AND A.歸屬序號 = D.單據序號
	/*異常表頭*/
	LEFT JOIN FIL0030 E ON A.歸屬類別 = E.單據類別 AND A.歸屬編號 = E.單據編號
	/*異常單客戶*/
	LEFT JOIN FIL0011 F ON E.廠客編號 = F.編號
	/*特採單廠商*/
	LEFT JOIN FIL0011 G ON A.廠客編號 = G.編號
	/*異常單*/
	LEFT JOIN FIL003L1 H ON A.歸屬類別 = H.單別 AND A.歸屬編號 = H.單號
	/*異常單位*/
	LEFT JOIN FIL0020 I ON H.異常單位 = I.部門編號
	LEFT JOIN FIL0010 Z1 ON A.填表人 = Z1.員工編號
	LEFT JOIN FIL0010 Z2 ON A.最後更新者 = Z2.員工編號	
	LEFT JOIN ViewFIL0011 Z3 ON A.公司代碼 = Z3.代碼
	LEFT JOIN ViewOfObjProperties Z3 ON A.流水編號 = Z3.單據流水號
WHERE
	A.單據類別 = 'R04');

-- Oracle user_views
CREATE VIEW "VIEWFILR031" ("單別", "單號", "單據日期", "客戶編號", "客戶名稱", "公司代碼", "公司名稱", "簽核系統", "簽核狀態", "簽核系統_結案", "退貨日期", "退貨方式", "退貨件數", "退貨方式說明", "退貨原因", "處理數量_入庫", "處理數量_銷毀", "處理數量_其他", "後續處理", "品管課負責人姓名", "流水編號", "員工流水編號", "填表人部門編號", "填表人", "填表人姓名", "擔當業務", "擔當業務流水編號", "擔當業務姓名", "填表日", "最後更新者", "更新者姓名", "最後更新日") AS (
SELECT
	M.單據類別 單別,
	M.單據編號 單號,
	A.單據日期,
	A.廠客編號 客戶編號,
	nvl(G.全名, ' ') 客戶名稱,
	A.公司代碼,
	nvl(Z3.全名, ' ') 公司名稱,
	A.簽核系統, 
	nvl(Z6.簽核狀態,'0') 簽核狀態,
	A.簽核系統_結案,
	B.退貨日期,
	B.退貨方式,
	B.退貨件數,
	B.退貨方式說明,
	B.退貨原因,
	B.處理數量_入庫,
	B.處理數量_銷毀,
	B.處理數量_其他,
	B.後續處理,
	nvl(Z4.員工姓名,' ') 品管課負責人姓名,
	M.流水編號,
	nvl(Z1.Serial_Num,' ') 員工流水編號,
	nvl(Z1.部門編號,' ') 填表人部門編號,
	M.填表人,
	nvl(Z1.員工姓名,' ') 填表人姓名, 
	M.收付方式 擔當業務,
	nvl(Z7.Serial_Num,' ') 擔當業務流水編號,
	nvl(Z7.員工姓名,' ') 擔當業務姓名,
	M.填表日, 
	M.最後更新者,
	nvl(Z2.員工姓名,' ') 更新者姓名, 
	M.最後更新日
FROM
	FIL0030 M
	INNER JOIN FIL0030 A ON A.流水編號 = 'R03'||SUBSTR(M.流水編號,4,60)
	INNER JOIN FIL003M1 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
	INNER JOIN ViewOfObjProperties Z5 ON Z5.單據流水號 = 'R03'||SUBSTR(M.流水編號,4,60) AND Z5.簽核狀態 ='E'
	LEFT JOIN FIL0011 G ON A.廠客編號 = G.編號
	LEFT JOIN FIL0010 Z1 ON M.填表人 = Z1.員工編號
	LEFT JOIN FIL0010 Z2 ON M.最後更新者 = Z2.員工編號	
	LEFT JOIN ViewFIL0011 Z3 ON A.公司代碼 = Z3.代碼
	LEFT JOIN FIL0010 Z4 ON B.品管課負責人 = Z4.員工編號	
	LEFT JOIN ViewOfObjProperties Z6 ON M.流水編號 = Z6.單據流水號
	LEFT JOIN FIL0010 Z7 ON A.收付方式 = Z7.員工編號
WHERE
	M.單據類別 = 'R31');

-- Oracle user_views
CREATE VIEW "VIEWFILR210" ("單別", "單號", "單據日期", "客戶編號", "客戶名稱", "客訴單別", "客訴單號", "公司代碼", "公司名稱", "簽核系統", "簽核狀態", "簽核系統_結案", "異常大類", "異常大類名稱", "異常原因分類", "異常原因分類名稱", "異常單位", "異常單位名稱", "異常現象_作業者", "異常現象_作業者姓名", "異常現象_摘要", "異常現象_詳述", "異常現象_填表人", "異常原因_摘要", "異常原因分析", "再發防止措施_摘要", "再發防止措施", "矯正措施_填表人", "異常現象_填表人姓名", "流水編號", "填表人", "員工流水編號", "填表人部門編號", "填表人姓名", "填表日", "最後更新者", "更新者姓名", "最後更新日") AS (
SELECT
	M.單據類別 單別,
	M.單據編號 單號,
	A.單據日期,
	A.廠客編號 客戶編號,
	nvl(G.全名, ' ') 客戶名稱,
	A.歸屬類別 客訴單別,
	A.歸屬編號 客訴單號,
	A.公司代碼,
	nvl(Z3.全名, ' ') 公司名稱,
	A.簽核系統, 
	nvl(Z4.簽核狀態,'0') 簽核狀態,
	A.簽核系統_結案, 
	B.異常大類,
	nvl(C.名稱, ' ') 異常大類名稱,
	B.異常原因分類,
	nvl(D.名稱, ' ') 異常原因分類名稱,
	B.異常單位,
	nvl(E.部門名稱, ' ') 異常單位名稱,
	B.異常現象_作業者,
	B.異常現象_作業者姓名,
	B.異常現象_摘要,
	B.異常現象_詳述,
	B.異常現象_填表人,
	B.異常原因_摘要,
	B.異常原因分析,
	B.再發防止措施_摘要,
	B.再發防止措施,
	B.矯正措施_填表人,
	nvl(F.員工姓名, ' ') 異常現象_填表人姓名,
	M.流水編號,
	M.填表人,
	nvl(Z1.Serial_Num,' ') 員工流水編號,
	nvl(Z1.部門編號,' ') 填表人部門編號,
	nvl(Z1.員工姓名,' ') 填表人姓名, 
	M.填表日, 
	M.最後更新者,
	nvl(Z2.員工姓名,' ') 更新者姓名, 
	M.最後更新日
FROM
	FIL0030 M
	INNER JOIN FIL0030 A ON A.流水編號 = 'R02'||SUBSTR(M.流水編號,4,60)
	INNER JOIN FIL003L1 B ON B.單別 = 'R02' AND A.單據編號 = B.單號
	INNER JOIN ViewOfObjProperties Z5 ON A.流水編號 = Z5.單據流水號 AND Z5.簽核狀態 ='E'
	LEFT JOIN ViewFIL3114 C ON B.異常大類 = C.代碼
	LEFT JOIN ViewFIL3115 D ON B.異常原因分類 = D.代碼
	LEFT JOIN FIL0020 E ON B.異常單位 = E.部門編號
	LEFT JOIN FIL0010 F ON B.異常現象_填表人 = F.員工編號
	LEFT JOIN FIL0011 G ON A.廠客編號 = G.編號
	LEFT JOIN FIL0010 Z1 ON M.填表人 = Z1.員工編號
	LEFT JOIN FIL0010 Z2 ON M.最後更新者 = Z2.員工編號	
	LEFT JOIN ViewFIL0011 Z3 ON A.公司代碼 = Z3.代碼
	LEFT JOIN ViewOfObjProperties Z4 ON M.流水編號 = Z4.單據流水號
WHERE
	M.單據類別 = 'R21');

-- Oracle user_views
CREATE VIEW "VIEWFILR220" ("單別", "單號", "單據日期", "客戶編號", "客戶名稱", "客訴單別", "客訴單號", "公司代碼", "公司名稱", "簽核系統", "簽核狀態", "簽核系統_結案", "異常大類", "異常大類名稱", "異常原因分類", "異常原因分類名稱", "異常單位", "異常單位名稱", "異常現象_作業者", "異常現象_作業者姓名", "異常現象_摘要", "異常現象_詳述", "異常現象_填表人", "矯正措施_填表人", "指定簽核人員", "異常現象_填表人姓名", "流水編號", "填表人", "員工流水編號", "填表人部門編號", "填表人姓名", "填表日", "最後更新者", "更新者姓名", "最後更新日") AS (
SELECT
	M.單據類別 單別,
	M.單據編號 單號,
	A.單據日期,
	A.廠客編號 客戶編號,
	nvl(G.全名, ' ') 客戶名稱,
	A.歸屬類別 客訴單別,
	A.歸屬編號 客訴單號,
	A.公司代碼,
	nvl(Z3.全名, ' ') 公司名稱,
	A.簽核系統, 
	nvl(Z4.簽核狀態,'0') 簽核狀態,
	A.簽核系統_結案, 
	B.異常大類,
	nvl(C.名稱, ' ') 異常大類名稱,
	B.異常原因分類,
	nvl(D.名稱, ' ') 異常原因分類名稱,
	B.異常單位,
	nvl(E.部門名稱, ' ') 異常單位名稱,
	B.異常現象_作業者,
	B.異常現象_作業者姓名,
	B.異常現象_摘要,
	B.異常現象_詳述,
	B.異常現象_填表人,
	B.矯正措施_填表人,
	nvl(Z5.Serial_Num,' ') 指定簽核人員,
	nvl(F.員工姓名, ' ') 異常現象_填表人姓名,
	M.流水編號,
	M.填表人,
	nvl(Z1.Serial_Num,' ') 員工流水編號,
	nvl(Z1.部門編號,' ') 填表人部門編號,
	nvl(Z1.員工姓名,' ') 填表人姓名, 
	M.填表日, 
	M.最後更新者,
	nvl(Z2.員工姓名,' ') 更新者姓名, 
	M.最後更新日
FROM
	FIL0030 M
	INNER JOIN FIL0030 A ON A.流水編號 = 'R02'||SUBSTR(M.流水編號,4,60)
	INNER JOIN FIL003L1 B ON B.單別 = 'R02' AND A.單據編號 = B.單號
	INNER JOIN ViewOfObjProperties Z5 ON Z5.單據流水號 = 'R21'||SUBSTR(M.流水編號,4,60) AND Z5.簽核狀態 ='E'
	LEFT JOIN ViewFIL3114 C ON B.異常大類 = C.代碼
	LEFT JOIN ViewFIL3115 D ON B.異常原因分類 = D.代碼
	LEFT JOIN FIL0020 E ON B.異常單位 = E.部門編號
	LEFT JOIN FIL0010 F ON B.異常現象_填表人 = F.員工編號
	LEFT JOIN FIL0011 G ON A.廠客編號 = G.編號
	LEFT JOIN FIL0010 Z1 ON M.填表人 = Z1.員工編號
	LEFT JOIN FIL0010 Z2 ON M.最後更新者 = Z2.員工編號	
	LEFT JOIN ViewFIL0011 Z3 ON A.公司代碼 = Z3.代碼
	LEFT JOIN ViewOfObjProperties Z4 ON M.流水編號 = Z4.單據流水號
	LEFT JOIN FIL0010 Z5 ON B.矯正措施_填表人 = Z5.員工編號	
WHERE
	M.單據類別 = 'R22');

-- Oracle user_views
CREATE VIEW "VIEWFILR230" ("單別", "單號", "單據日期", "客戶編號", "客戶名稱", "客訴單別", "客訴單號", "公司代碼", "公司名稱", "簽核系統", "簽核狀態", "簽核系統_結案", "異常大類", "異常大類名稱", "異常原因分類", "異常原因分類名稱", "異常單位", "異常單位名稱", "異常現象_作業者", "異常現象_作業者姓名", "異常現象_摘要", "異常現象_詳述", "異常現象_填表人", "追蹤確認", "異常現象_填表人姓名", "流水編號", "填表人", "員工流水編號", "填表人部門編號", "填表人姓名", "填表日", "最後更新者", "更新者姓名", "最後更新日") AS (
SELECT
	M.單據類別 單別,
	M.單據編號 單號,
	A.單據日期,
	A.廠客編號 客戶編號,
	nvl(G.全名, ' ') 客戶名稱,
	A.歸屬類別 客訴單別,
	A.歸屬編號 客訴單號,
	A.公司代碼,
	nvl(Z3.全名, ' ') 公司名稱,
	A.簽核系統, 
	nvl(Z4.簽核狀態,'0') 簽核狀態,
	A.簽核系統_結案, 
	B.異常大類,
	nvl(C.名稱, ' ') 異常大類名稱,
	B.異常原因分類,
	nvl(D.名稱, ' ') 異常原因分類名稱,
	B.異常單位,
	nvl(E.部門名稱, ' ') 異常單位名稱,
	B.異常現象_作業者,
	B.異常現象_作業者姓名,
	B.異常現象_摘要,
	B.異常現象_詳述,
	B.異常現象_填表人,
	B.追蹤確認,
	nvl(F.員工姓名, ' ') 異常現象_填表人姓名,
	M.流水編號,
	M.填表人,
	nvl(Z1.Serial_Num,' ') 員工流水編號,
	nvl(Z1.部門編號,' ') 填表人部門編號,
	nvl(Z1.員工姓名,' ') 填表人姓名, 
	M.填表日, 
	M.最後更新者,
	nvl(Z2.員工姓名,' ') 更新者姓名, 
	M.最後更新日
FROM
	FIL0030 M
	INNER JOIN FIL0030 A ON A.流水編號 = 'R02'||SUBSTR(M.流水編號,4,60)
	INNER JOIN FIL003L1 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號
	INNER JOIN ViewOfObjProperties Z5 ON Z5.單據流水號 = 'R22'||SUBSTR(M.流水編號,4,60) AND Z5.簽核狀態 ='E'
	LEFT JOIN ViewFIL3114 C ON B.異常大類 = C.代碼
	LEFT JOIN ViewFIL3115 D ON B.異常原因分類 = D.代碼
	LEFT JOIN FIL0020 E ON B.異常單位 = E.部門編號
	LEFT JOIN FIL0010 F ON B.異常現象_填表人 = F.員工編號
	LEFT JOIN FIL0011 G ON A.廠客編號 = G.編號
	LEFT JOIN FIL0010 Z1 ON M.填表人 = Z1.員工編號
	LEFT JOIN FIL0010 Z2 ON M.最後更新者 = Z2.員工編號	
	LEFT JOIN ViewFIL0011 Z3 ON A.公司代碼 = Z3.代碼
	LEFT JOIN ViewOfObjProperties Z4 ON M.流水編號 = Z4.單據流水號
WHERE
	M.單據類別 = 'R23');

-- Oracle user_views
CREATE VIEW "VIEWHRFIL1007" ("員工編號", "員工姓名", "公司別", "部門名稱", "職位名稱", "出勤日期", "遲到", "早退", "假別", "上班刷卡", "下班刷卡", "班別", "班別時間起", "班別時間迄", "加班時數一", "加班時數二", "流水編號", "最後更新者", "最後更新日") AS (
SELECT 
	A.員工編號,
	B.員工姓名,
	B.公司別,
	B.部門名稱,
	B.職位名稱,
	A.出勤日期,
	A.遲到,
	A.早退,
	C.假別,
	A.上班刷卡,
	A.下班刷卡,
	A.班別,
	A.班別時間起,
	A.班別時間迄,
	A.加班時數一,
	A.加班時數二,
	A.流水編號,
	A.最後更新者,
	A.最後更新日
FROM
	HRFIL1007 A
	INNER JOIN VIEWFIL1010 B ON B.員工編號 = A.員工編號
	LEFT JOIN 
	(SELECT
		A.申請人,
		A.起始日期,
		A.截止日期,
		utl_raw.cast_to_nvarchar2(listagg(utl_raw.cast_to_raw(A.假別名稱||'[')||utl_raw.cast_to_raw(TO_NCHAR(ROUND(A.天數)))||utl_raw.cast_to_raw(N'天')||utl_raw.cast_to_raw(TO_NCHAR(ROUND(A.時數)))||utl_raw.cast_to_raw(N'小時]'), utl_raw.cast_to_raw(N' ')) within group (order by A.申請人)) as 假別
	 FROM
		VIEWFILH001 A
	 WHERE A.簽核狀態 = 'E'	
	 GROUP BY 
		A.申請人,
		A.起始日期,
		A.截止日期
	) C ON C.申請人 = A.員工編號 AND A.出勤日期 BETWEEN C.起始日期 AND C.截止日期 
);

-- Oracle user_views
CREATE VIEW "VIEWOFA01" ("流水編號", "開單人流水號", "申請人流水號", "開單日期", "簽核期限", "表單代碼") AS Select 
		A.Serial_Num 流水編號,  
		A.Owner 開單人流水號,
		A.ApplyBy 申請人流水號,
		to_date(A.CreateDate,'yyyymmdd') 開單日期,
		A.DueDate 簽核期限,
		Substr(A.Serial_Num,1,3) 表單代碼
	FROM 
		A01 A
  WHERE
    A.CreateDate BETWEEN TO_CHAR(SYSDATE-100) AND TO_CHAR(SYSDATE);

-- Oracle user_views
CREATE VIEW "VIEWOFDEPTTREE" ("PARENTID", "NODEID") AS Select 'All',' ' From dual union SELECT  ' ', A30.Serial_Num FROM A30;

-- Oracle user_views
CREATE VIEW "VIEWOFEMP" ("SERIALNO", "EMPID", "EMPNAME", "POSITION", "SALARYPOSI", "FLOWPOSI", "ENTRYID", "ENTRYPSW", "NICKNAME", "LANGUAGE", "EMPEMAIL", "COMPSERIAL", "DEPSERIAL", "ASSIGNEE", "REPLACEBY", "IMHEADER", "IMSTATUS", "HIREDATE", "TERMDATE", "CLOSED", "SALARYTYPE", "SALARY", "DISPLAYNAME", "SUPERVISOR") AS Select 
	A.Serial_Num, 
	A.員工編號, 
	A.員工姓名, 
	A.職稱代碼,
	A.SalaryPosi, 
	A.FlowPosi, 
	A.EntryID, 
	A.個人密碼, 
	A.英文姓名, 
	A.Language,
	A.eMailAddress, 
	A.CompSerial, 
	A.DepSerial,  
	nvl(ViewOfValidAssignee.ASIGNEE,' '), 
	A.ReplaceBy, 
	A.IMHeader, 
	A.IMStatus, 
	A.就職日期, 
	A.離職日期, 
	A.停止使用,
	' ', 
	0,
	rtrim( A50.GUName)||'.'||rtrim( A30.GroupName)||'.'||rtrim( A40.GUName)||'.'||rtrim(A.員工姓名), 
	0
FROM 
	FIL0010 A
	left join ViewOfValidAssignee on A.Serial_Num= ViewOfValidAssignee.SERIAL_NUM 
	left join A50 on A.CompSerial= A50.Serial_Num 
	left join A30 on A.DepSerial= A30.Serial_Num 
	left join A40 on A.SalaryPosi= A40.Serial_Num
	left join A01 on A.Serial_Num= A01.Serial_Num;

-- Oracle user_views
CREATE VIEW "VIEWOFEMPMA" ("EMPID", "DEP_ID", "EMP_NAM", "EMP_ADDR", "EMP_TEL", "EMP_MOB", "VOICE") AS SELECT  A.員工編號,  A30.GroupID, A.員工姓名, A.通訊地址, A.OffPhone, A.聯絡電話, ' ' FROM FIL0010 A   left outer join A30 on A.DepSerial= A30.Serial_Num;

-- Oracle user_views
CREATE VIEW "VIEWOFFLOW" ("流水編號", "公司流水號", "父階序號", "表身序號", "指定人員流水號", "職稱流水號", "正副本", "簽核部門流水號", "會簽判定", "會簽方式", "職稱", "指定人員", "條件欄位", "條件式", "條件內容") AS SELECT 	distinct A.Serial_Num 流水編號,
		A.CompID 公司流水號,
		A.Level_ 父階序號, 
		A.Serial_Num_Seq 表身序號, 
		A.指定人員 指定人員流水號, 
		A.PosiID 職稱流水號, 
		A.SignOrCC 正副本,
		A.FlowDept 簽核部門流水號,
		A.會簽判定,
		A.會簽方式,
		NVL(B.GUNAME,' ') 職稱,
		NVL(C.EMPNAME,' ') 指定人員,
		A.CndField 條件欄位,
		A.CndExpression 條件式,
		A.CndContent 條件內容
FROM A20_1 A
LEFT JOIN A40 B ON A.Serial_Num = B.Serial_Num AND B.POSITYPE='2'
LEFT JOIN ViewOfEMP C ON A.指定人員 = C.SerialNo;

-- Oracle user_views
CREATE VIEW "VIEWOFFLOWDETAIL" ("TYPE", "SERIALNO", "EMPSERIALNO", "FOLDERSTATUS", "FLOWSTATUS", "SIGNORCC", "ITEMNO") AS SELECT 'A', A01.Serial_Num,A01.ApplyBy, A01.FlowStatus ,'A',1,0 FROM A01 

Union  

/*單據屬性:開單人 */
SELECT 'B', A01.Serial_Num, A01.Owner, A01.FlowStatus ,'A',1,0 FROM A01 

Union  

/*單據流程:應簽 */
SELECT 'C',
	A.Serial_Num, 
	A.AssignedTo, 
	B.FlowStatus ,
	(case when  A.SignedType = '2'  then 'R' when A.SignedType ='1' then 'A' else 'I' end), 
	A.SignOrCC, 
	A.Serial_Num_Seq 
FROM A01_2 A
INNER JOIN A01 B ON A.Serial_Num=B.Serial_Num 
LEFT JOIN A01_2 C ON A.Serial_Num=C.Serial_Num AND A.Version=C.Serial_Num_Seq

Union  


/*單據流程:簽核 */
SELECT 'D',
	A01_2.Serial_Num, 
	A01_2.SignedBy,  
	A01.FlowStatus , 
	(case when A01_2.SignedType = '2' then 'R' when A01_2.SignedType='1' then 'A' else 'I' end) , 
	A01_2.SignOrCC, 
	A01_2.Serial_Num_Seq 

FROM A01_2, A01 

Where A01_2.Serial_Num=A01.Serial_Num and A01_2.SignedBy<>' ' and  A01_2.AssignedTo <>  A01_2.SignedBy

Union  

/*單據流程:退簽 */
SELECT 'E',
	A.Serial_Num, 
	A.SignBackTo, 
	B.FlowStatus ,
	(case when  A.SignedType = '2'  then 'R' when A.SignedType ='1' then 'A' else 'I' end), 
	A.SignOrCC, 
	A.Serial_Num_Seq 
FROM A01_2 A
INNER JOIN A01 B ON A.Serial_Num=B.Serial_Num 
LEFT JOIN A01_2 C ON A.Serial_Num=C.Serial_Num AND A.Version=C.Serial_Num_Seq;

-- Oracle user_views
CREATE VIEW "VIEWOFFLOWTYPE" ("表單代碼", "類別代碼", "說明", "代碼說明") AS SELECT
	Job_Type 表單代碼,
	類別代碼,
	說明,
	類別代碼||'.'||說明 代碼說明
FROM
	A20_8;

-- Oracle user_views
CREATE VIEW "VIEWOFGROUPDOC" ("GROUPSERIALNO", "DOCSERIALNO", "JOB_TYPE", "DOCNAME") AS SELECT A30_2.Serial_Num, A30_2.DocSerialNo, A20.Job_Type, A20.GUName FROM A30_2, A20 WHERE A30_2.DocSerialNo = A20.Serial_Num and  A20.表單類別 between '1' and '2' Union  SELECT 'SUPERVISOR', A20.Serial_Num, A20.Job_Type,  A20.GUName FROM A20 where A20.表單類別 between '1' and '2' Union  SELECT A30.Serial_Num,  A20.Serial_Num, A20.Job_Type, A20.GUName FROM  A30, A07, A20 WHERE A07.ProgramID= A20.Job_Type and  A07.ForAll=1 and A20.表單類別 between '1' and '2';

-- Oracle user_views
CREATE VIEW "VIEWOFGROUPDOCID" ("GROUPSERIALNO", "PROGRAMID", "PROGRAMNAME") AS SELECT    ViewOfGroupDoc.GROUPSERIALNO, A07.ProgramID,A07.ProgramID||' '||A20.GUName FROM  ViewOfGroupDoc,A07,A20 WHERE  ViewOfGroupDoc.Job_Type= ViewOfGroupDoc.Job_Type and  A07.ProgramID= A20.Job_Type and A07.ForAll='1' union  SELECT A30_2.Serial_Num,A20.Job_Type,A20.Job_Type||' '||A20.GUName FROM A30_2, A20 WHERE A30_2.DocSerialNo= A20.Serial_Num;

-- Oracle user_views
CREATE VIEW "VIEWOFIMALIVE" ("來源訊息", "筆數") AS (
SELECT 
	ForMessage 來源訊息,
	count( Serial_Num) 筆數 
FROM Messages 
WHERE 
	Ending=0 and  
	Messages.ForMessage<>' ' and
	類型='R'
GROUP BY 
	ForMessage
);

-- Oracle user_views
CREATE VIEW "VIEWOFIMNOTEND" ("收訊人", "員工編號", "未結案筆數") AS SELECT 
	M.MessageTo 收訊人,
	A.員工編號,
	COUNT(M.Serial_Num) 未結案筆數
FROM   
	Messages M 
	INNER JOIN FIL0010 A ON A.Serial_Num = M.MessageTo
	INNER JOIN FIL0010 C ON C.Serial_Num = M.CreateBy
	LEFT JOIN ViewOfIMAlive B on M.Serial_Num = B.來源訊息
WHERE   
	M.IMFlag = 1 and 
	/*含未回覆
	(M.Ending = 0 or nvl(筆數,0) > 0)  and
	*/
	M.Ending = 0 and
	M.類型<>'R' and 
	M.InValidDate > to_char(sysdate,'yyyymmdd') 
GROUP BY
	M.MessageTo,
	A.員工編號;

-- Oracle user_views
CREATE VIEW "VIEWOFMSGNOTREP" ("相關單據", "流水編號", "發訊人", "收訊人") AS SELECT M.RefDocument,M.Serial_Num, M.CreateBy, M.MessageTo FROM   Messages M WHERE   M.Ending=0 and  M.類型='Q'  and M.Serial_Num not In ( SELECT   D.ForMessage  FROM Messages D Where D.CreateBy= M.MessageTo and D.RefDocument=M.RefDocument and  D.ForMessage= M.Serial_Num );

-- Oracle user_views
CREATE VIEW "VIEWOFMSGREPLIST" ("來源訊息", "收訊人", "回覆內容") AS SELECT
	 Messages.ForMessage 來源訊息,
	 Messages.MessageTo 收訊人,
	 listagg(trim(Messages.Message), ',') within group( Order By Messages.ForMessage, Messages.MessageTo) as 回覆內容
	
FROM 
	 Messages
where 	 
	Messages.類型='R' and  Messages.ForMessage<>' '
Group by  
	Messages.ForMessage, Messages.MessageTo;

-- Oracle user_views
CREATE VIEW "VIEWOFOBJ" ("SERIALNO", "OBJID", "OBJNAME") AS Select A20.Serial_Num,  A20.Job_Type,  A20.GUName FROM A20, A01 WHERE A20.Serial_Num= A01.Serial_Num and   A01.FlowStatus='E';

-- Oracle user_views
CREATE VIEW "VIEWOFOBJFLOW" ("單據流水號", "父階序號", "流程序號", "排序", "應簽核人員", "簽核人員流水號", "員工編號", "員工姓名", "簽核日期", "簽核時間", "簽核結果", "資料夾", "簽核意見", "加簽", "執行說明", "免簽", "簽核列印列號", "簽核列印序號") AS SELECT Serial_Num 單據流水號,
	Version 父階序號,
	Serial_Num_Seq 流程序號,
	decode(Version,0,Serial_Num_Seq,Version+Serial_Num_Seq/100) 排序,
	AssignedTo 應簽核人員,
	nvl(SignedBy,' ') 簽核人員流水號,
	nvl(EmpID,' ') 員工編號,
	nvl(EmpName,' ') 員工姓名,
	SignedDate 簽核日期,
	SignedTime 簽核時間,
	SignedType 簽核結果,
	Folder 資料夾,
	Opnion 簽核意見,
	addflow 加簽,
	nvl(ProcessFor,' ') 執行說明,
	Free2Sign 免簽,
	Singature_Line 簽核列印列號,
	Singature_Seq 簽核列印序號
FROM A01_2,ViewOfEmp 
Where AssignedTo<>' ' and A01_2.SignedBy=ViewOfEmp.SerialNo(+);

-- Oracle user_views
CREATE VIEW "VIEWOFOBJFLOWSIGNED" ("單據流水號", "排序", "簽核人員流水號", "員工編號", "員工姓名") AS SELECT Serial_Num 單據流水號,
	0 排序,
	ApplyBy 簽核人員流水號,
	nvl(EmpID,' ') 員工編號,
	nvl(EmpName,' ') 員工姓名
FROM A01,ViewOfEmp 
Where FlowStatus > '0' and ApplyBy<>' 'and A01.ApplyBy=ViewOfEmp.SerialNo(+)

Union

SELECT Serial_Num 單據流水號,
	decode(Version,0,Serial_Num_Seq*100,Version*100+Serial_Num_Seq) 排序,
	nvl(SignedBy,' ') 簽核人員流水號,
	nvl(EmpID,' ') 員工編號,
	nvl(EmpName,' ') 員工姓名 
FROM A01_2,ViewOfEmp 
Where SignedBy<>' ' and nvl(SignedBy,' ')<>' ' and  A01_2.SignedBy=ViewOfEmp.SerialNo(+);

-- Oracle user_views
CREATE VIEW "VIEWOFOBJPROPERTIES" ("單據流水號", "單據名稱", "簽核狀態", "送簽日時") AS SELECT Serial_Num 單據流水號,Name 單據名稱,FlowStatus 簽核狀態,TO_TIMESTAMP(CreateDate||CreateTime,'YYYYMMDDHH24MISS') 送簽日時 FROM A01;

-- Oracle user_views
CREATE VIEW "VIEWOFOBJQUERYID" ("SERIALNO", "EMP_SERINALNO", "VERSION") AS SELECT DISTINCT A01.Serial_Num, A01.Owner, A01.Version FROM A01 Union  SELECT DISTINCT A01.Serial_Num, A01.ApplyBy, A01.Version FROM A01 Union  SELECT DISTINCT A01_2.Serial_Num, A01_2.AssignedTo, A01_2.Version FROM A01_2 Union  SELECT DISTINCT A01_2.Serial_Num, A01_2.SignedBy, A01_2.Version FROM A01_2;

-- Oracle user_views
CREATE VIEW "VIEWOFSUBDEPT" ("PARENTID", "NODEID") AS Select 'All',' ' From dual union SELECT  ' ', A30.Serial_Num FROM A30 Union  SELECT A35.GroupID, A35.Serial_Num FROM A35;

-- Oracle user_views
CREATE VIEW "VIEWOFSYSCODE" ("SERIALNO", "CODETYPE", "CODEID", "CODENAME") AS Select  A10.Serial_Num,   A10.CodeType,   A10.CodeID,  A10.GUName FROM  A10, A01 WHERE  A10.Serial_Num= A01.Serial_Num and   A01.FlowStatus='E';

-- Oracle user_views
CREATE VIEW "VIEWOFSYSCODE1" ("PARENTID", "NODEID") AS Select 'All',' ' From dual union SELECT  ' ', To_char(A10.CodeID,'yyyymmdd') FROM   A10  WHERE CodeType='文件類別';

-- Oracle user_views
CREATE VIEW "VIEWOFVALIDASSIGNEE" ("SERIAL_NUM", "ASIGNEE", "DATEFROM", "DATETO") AS SELECT  
	Serial_Num, 
	Asignee, 
	DateFrom, 
	DateTo 
FROM 
	A60_7 
WHERE 
	to_char(sysdate,'YYYYMMDD') between A60_7.DateFrom and A60_7.DateTo;

-- Oracle user_views
CREATE VIEW "VIEWTEMP01" ("材料編號", "庫存數") AS (
SELECT
	A.產品編號 材料編號,
	sum(nvl(A.異動數,0)) 庫存數
FROM
	(	SELECT 
			A.產品編號,
			SUM((A.異動數量 + A.贈品數量) * B.材料庫存參數) 異動數
		FROM 
			FIL0040 A
			/*庫存參數*/
			INNER JOIN ViewFIL0020 B ON A.單據類別 = B.單據類別 AND B.材料庫存參數 != 0
			INNER JOIN FIL0030 C1 ON A.單據類別 = C1.單據類別 AND A.單據編號 = C1.單據編號
			/*特殊欄位*/
			INNER JOIN FIL0041 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號 AND A.單據序號 = C.序號
			LEFT JOIN VIEWFIL1012 E ON A.產品編號 = E.產品編號
			/*單位換算
			LEFT JOIN ViewFIL1017 F ON A.單位代碼 = F.從 AND E.單位代碼 = F.到
			*/
		WHERE
			A.產品編號 != ' ' AND
			DECODE(E.批號管理,0,'不分批號',C.批號) != ' ' AND
			TO_CHAR(C1.填表日,'YYYYMMDDHH24MISS')<='20220628070000'
		GROUP BY
			A.產品編號		
			
		union all

		/*發料*/
		SELECT 
			A.產品編號,
			SUM(A.異動數量) 異動數
		FROM 
			FIL0040 A
			INNER JOIN FIL0041 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號 AND A.單據序號 = C.序號
			INNER JOIN FIL0030 C1 ON A.單據類別 = C1.單據類別 AND A.單據編號 = C1.單據編號
			LEFT JOIN VIEWFIL1012 G ON A.產品編號 = G.產品編號
			/*單位換算
			LEFT JOIN ViewFIL1017 H ON A.單位代碼 = H.從 AND G.單位代碼 = H.到
			*/
		WHERE
			A.單據類別 = 'C4M' AND
			A.產品編號 != ' ' AND
			DECODE(G.批號管理,0,'不分批號',C.批號) != ' ' AND
			TO_CHAR(C1.填表日,'YYYYMMDDHH24MISS')<='20220628070000'
		GROUP BY
			A.產品編號		
			
		union all
		
		/*材料領用,報廢,油墨領用*/
		SELECT 
			A.產品編號,
			SUM(A.異動數量 * -1) 異動數
		FROM 
			FIL0040 A
			INNER JOIN FIL0041 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號 AND A.單據序號 = B.序號
			LEFT JOIN VIEWFIL1012 C ON A.產品編號 = C.產品編號
			/*單位換算
			LEFT JOIN ViewFIL1017 E ON A.單位代碼 = E.從 AND C.單位代碼 = E.到
			*/
		WHERE
			A.單據類別 = 'C41' AND
			A.異動類別 between 'C' and 'E' AND
			A.異動數量 != 0 AND
			A.產品編號 != ' ' AND
			DECODE(C.批號管理,0,'不分批號',B.批號) != ' ' AND
			TO_CHAR(A.最後更新日,'YYYYMMDDHH24MISS')<='20220628070000'
		GROUP BY
			A.產品編號		
		
		union all
		
		/*材料領用.氣閥.鐵條-批號1*/
		SELECT 
			E.料號 產品編號,
			SUM(B.數值1 * -1) 異動數
		FROM 
			FIL0040 A
			INNER JOIN FIL0041 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號 AND A.單據序號 = B.序號
			INNER JOIN FIL0031 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號
			INNER JOIN ViewFIL1024 E ON B.文數字1 = E.條碼
		WHERE
			A.單據類別 = 'C41' AND
			A.異動類別 = 'A' AND
			C.製程代碼 between 'C31F' and 'C31G' AND
			B.文數字1 != ' ' AND
			TO_CHAR(A.最後更新日,'YYYYMMDDHH24MISS')<='20220628070000'
		GROUP BY
			E.料號		

		UNION all
		
		/*材料領用.氣閥.鐵條-批號2*/
		SELECT 
			E.料號 產品編號,
			SUM(B.數值2 * -1) 異動數
		FROM 
			FIL0040 A
			INNER JOIN FIL0041 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號 AND A.單據序號 = B.序號
			INNER JOIN FIL0031 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號
			INNER JOIN ViewFIL1024 E ON B.文數字2 = E.條碼
		WHERE
			A.單據類別 = 'C41' AND
			A.異動類別 = 'A' AND
			C.製程代碼 between 'C31F' and 'C31G' AND
			B.文數字2 != ' ' AND
			TO_CHAR(A.最後更新日,'YYYYMMDDHH24MISS')<='20220628070000'
		GROUP BY
			E.料號		
		
		union all

		/*發料回庫(+)*/
		SELECT 
			A.產品編號,
			SUM(A.贈品數量) 異動數
		FROM 
			FIL0040 A
			INNER JOIN FIL0041 B ON A.單據類別 = B.單別 AND A.單據編號 = B.單號 AND A.單據序號 = B.序號
			INNER JOIN FIL0030 C1 ON A.單據類別 = C1.單據類別 AND A.單據編號 = C1.單據編號
			/*單位換算
			LEFT JOIN VIEWFIL1012 C ON A.產品編號 = C.產品編號
			LEFT JOIN ViewFIL1017 E ON A.單位代碼 = E.從 AND C.單位代碼 = E.到
			*/
		WHERE
			A.單據類別 = 'C41' AND
			A.異動類別 = 'C' AND
			A.贈品數量 != 0 AND
			TO_CHAR(c1.填表日,'YYYYMMDDHH24MISS')<='20220628070000'
		GROUP BY
			A.產品編號		
			
		/*廠內盤點調整*/
		union all
		
		SELECT
			A.產品編號,
			SUM(A.異動數量 + A.贈品數量) 異動數
		FROM 
			FIL0040 A
			INNER JOIN FIL0030 B ON A.單據類別 = B.單據類別 AND A.單據編號 = B.單據編號
			/*特殊欄位*/
			INNER JOIN FIL0041 C ON A.單據類別 = C.單別 AND A.單據編號 = C.單號 AND A.單據序號 = C.序號
		WHERE
			A.單據類別 = 'F32' AND
			A.異動類別 = '2' AND
			TO_CHAR(B.填表日,'YYYYMMDDHH24MISS')<='20220628070000'
		GROUP BY
			A.產品編號	
	) A
GROUP BY
	A.產品編號);


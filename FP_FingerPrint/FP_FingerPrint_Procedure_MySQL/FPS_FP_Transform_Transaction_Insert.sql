/*<info serverAlias="FPSDC-FPS_FingerPrint" databaseType="2" executers="fpsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `FPS_FP_Transform_Transaction_Insert`;
DELIMITER $$

CREATE DEFINER=`fpsOwner`@`%` PROCEDURE `FPS_FP_Transform_Transaction_Insert`(
		ip_Transaction LONGTEXT
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20221114@Jonathan.Doan
		Task :		
		DB:			FPS_FingerPrint
		Original:

		Revisions: 
			- 20221114@Jonathan.Doan: Created [Redmine ID: #180406]
            
		Param's Explanation (filtered by):	

		Example:
			- CALL FPS_FP_Transform_Transaction_Insert('');
			
	*/
    DECLARE lv_CurrentDate DATETIME DEFAULT NOW();
    
    /*******LOG TEST********************/
    IF (SELECT ofs.OffsetValue FROM FPS_FingerPrint.Offset AS ofs WHERE Id = 7) = 1 THEN		
		INSERT INTO CTS_Log.FPSLog(SpName, JsonString, OtherText, InsertTime)
		SELECT 'FPS_FP_Transform_Transaction_Insert', ip_Transaction, NULL, CURRENT_TIMESTAMP();
	END IF;
    /*******LOG TEST********************/
    
	DROP TEMPORARY TABLE IF EXISTS Temp_Transaction;
    DROP TEMPORARY TABLE IF EXISTS Temp_Cookie;
    DROP TEMPORARY TABLE IF EXISTS Temp_RawUserAgent;
    DROP TEMPORARY TABLE IF EXISTS Temp_FingerPrintAttributes;
    DROP TEMPORARY TABLE IF EXISTS Temp_RawFingerPrint;
	DROP TEMPORARY TABLE IF EXISTS Temp_RawUserAgent;
	DROP TEMPORARY TABLE IF EXISTS Temp_MapIdRawUserAgent;
	DROP TEMPORARY TABLE IF EXISTS Temp_BrowserInfo;
	DROP TEMPORARY TABLE IF EXISTS Temp_Evolution;
    
    
	CREATE TEMPORARY TABLE Temp_Transaction(
			Id 						INT AUTO_INCREMENT	NOT NULL 
		,	CookieId 				BIGINT UNSIGNED 	DEFAULT NULL
		,	CookieCode 				VARCHAR(200)		DEFAULT NULL
		,	CustId 					BIGINT 				DEFAULT NULL
		,	SubAccId 				BIGINT 				DEFAULT NULL
		,	AccountId 				BIGINT UNSIGNED 	DEFAULT NULL
		,	LoginName 				VARCHAR(100) 		DEFAULT NULL
		,	SubscriberId 			INT 				DEFAULT NULL
		,	TransTime 				DATETIME(4) 		DEFAULT NULL
		,	ClientIp 				VARCHAR(45) 		DEFAULT NULL
		,	UserAgentId 			BIGINT UNSIGNED 	DEFAULT NULL
		,	UserAgent				LONGTEXT			DEFAULT NULL
		,	UserAgentCode			VARCHAR(100)		DEFAULT NULL
		,	Url 					VARCHAR(100) 		DEFAULT NULL
		,	Action 					VARCHAR(100) 		DEFAULT NULL
		,	TransKey 				VARCHAR(200) 		DEFAULT NULL
		,	RawFingerPrintId 		BIGINT UNSIGNED 	DEFAULT NULL
		,	BrowserInfoId 			BIGINT UNSIGNED 	DEFAULT NULL
		,	FingerprintAttribute 	JSON 				DEFAULT NULL
		,	UserAgentInfo		 	JSON 				DEFAULT NULL
		,	BrowserInfo			 	JSON 				DEFAULT NULL
		,	BrowserInfoAttribute 	JSON 				DEFAULT NULL
        
        ,	PRIMARY KEY (Id)
        , 	INDEX IX_Temp_Transaction_CookieCode(CookieCode)
        , 	INDEX IX_Temp_Transaction_UserAgentCode(UserAgentCode)
    );
    
    CREATE TEMPORARY TABLE Temp_Evolution(
			Id 						INT AUTO_INCREMENT	NOT NULL 
		,	CookieId 				BIGINT UNSIGNED 	DEFAULT NULL
		,	CookieCode 				VARCHAR(200)		DEFAULT NULL
		,	CustId 					BIGINT 				DEFAULT NULL
		,	SubAccId 				BIGINT 				DEFAULT NULL
		,	AccountId 				BIGINT UNSIGNED 	DEFAULT NULL
		,	LoginName 				VARCHAR(100) 		DEFAULT NULL
		,	SubscriberId 			INT 				DEFAULT NULL
		,	TransTime 				DATETIME(4) 		DEFAULT NULL
		,	ClientIp 				VARCHAR(45) 		DEFAULT NULL
		,	UserAgentId 			BIGINT UNSIGNED 	DEFAULT NULL
		,	UserAgent				LONGTEXT			DEFAULT NULL
		,	UserAgentCode			VARCHAR(100)		DEFAULT NULL
		,	Url 					VARCHAR(100) 		DEFAULT NULL
		,	Action 					VARCHAR(100) 		DEFAULT NULL
		,	TransKey 				VARCHAR(200) 		DEFAULT NULL
		,	RawFingerPrintId 		BIGINT UNSIGNED 	DEFAULT NULL
		,	BrowserInfoId 			BIGINT UNSIGNED 	DEFAULT NULL
		,	FingerprintAttribute 	JSON 				DEFAULT NULL
		,	UserAgentInfo		 	JSON 				DEFAULT NULL
		,	BrowserInfo			 	JSON 				DEFAULT NULL
		,	BrowserInfoAttribute 	JSON 				DEFAULT NULL
        
        ,	PRIMARY KEY (Id)
    );
    
	CREATE TEMPORARY TABLE Temp_Cookie(
			TmpTransactionsId 			BIGINT UNSIGNED		NOT NULL 
		,	CookieId					BIGINT UNSIGNED 	NOT NULL
        
        ,	PRIMARY KEY (TmpTransactionsId)
    );
    
	CREATE TEMPORARY TABLE Temp_RawUserAgent(
			TmpTransactionsId 	BIGINT UNSIGNED		NOT NULL  
		,	UserAgent	 		LONGTEXT	    	NULL    
		,	UserAgentCode 		VARCHAR(100)    	NULL    
		,	ClientType 			VARCHAR(15) 		NULL
		,	ClientName 			VARCHAR(100) 		NULL
		,	ClientVersion 		VARCHAR(50) 		NULL
		,	OSName 				VARCHAR(100) 		NULL
		,	OSShortName 		VARCHAR(50) 		NULL
		,	OSVersion 			VARCHAR(50) 		NULL
		,	OSPlatform 			VARCHAR(15) 		NULL
		,	Device 				VARCHAR(50) 		NULL
		,	Brand 				VARCHAR(50) 		NULL
		,	Model 				VARCHAR(15) 		NULL
        
        ,	PRIMARY KEY (TmpTransactionsId)
    );
    
	CREATE TEMPORARY TABLE Temp_MapIdRawUserAgent(
			TmpTransactionsId 	BIGINT UNSIGNED		NOT NULL 
		,	UserAgentId			BIGINT UNSIGNED		NOT NULL
        
        ,	PRIMARY KEY (TmpTransactionsId)
    );
    
	CREATE TEMPORARY TABLE Temp_FingerPrintAttributes(
			TmpTransactionsId 			INT 				NOT NULL 
		,	Attribute					LONGTEXT	 		NULL
		,	FingerPrintCode				VARCHAR(64) 		NULL
		,	BrowserInstanceCode			VARCHAR(64) 		NULL
		,	Accept						VARCHAR(100)	 	NULL
		,	Encoding					VARCHAR(200)	 	NULL
		,	Headers						VARCHAR(500)	 	NULL
		,	OSName						VARCHAR(100)	 	NULL
		,	BrowserName					VARCHAR(100)	 	NULL
		,	BrowserVersion				VARCHAR(50)	 		NULL
		,	Platform					VARCHAR(45)	 		NULL
		,	UserAgent					LONGTEXT	 		NULL
        
        ,	PRIMARY KEY (TmpTransactionsId)
        , 	INDEX IX_Temp_FingerPrintAttributes_FingerPrintCode(FingerPrintCode)
    );
    
	CREATE TEMPORARY TABLE Temp_RawFingerPrint(
			TmpTransactionsId 			INT 				NOT NULL 
		,	RawFingerPrintId			BIGINT UNSIGNED 	NULL	
		,	FingerPrintCode				VARCHAR(64) 		NULL
        
        ,	PRIMARY KEY (TmpTransactionsId)	
        , 	INDEX IX_Temp_RawFingerPrint_FingerPrintCode(FingerPrintCode)
    );
    
	CREATE TEMPORARY TABLE Temp_BrowserInfo(	
			TmpTransactionsId 			INT 				NOT NULL 
		,	BrowserInfoId				BIGINT UNSIGNED 	NULL
		,	BrowserInfoAttributeCode	VARCHAR(64) 		NOT NULL
		,	BrowserInfoAttributeId		BIGINT UNSIGNED 	NULL
		,	UserAgentId 				BIGINT UNSIGNED 	NULL
		,	OSName						VARCHAR(50)	 		NULL
		,	BrowserName					VARCHAR(100)		NULL
		,	HeadlessScore				DECIMAL(1)			NULL
		,	HeadlessDetail				LONGTEXT			NULL
		,	BrowserInfoCode				VARCHAR(64)			NULL
		,	SecChUa						VARCHAR(100)	 	NULL
		,	SecChUaPlatform				VARCHAR(100)		NULL
		,	SecChUaMobile				VARCHAR(50) 		NULL
		,	JsBrowserName				VARCHAR(100)		NULL
		,	JsOSName					VARCHAR(50)			NULL
        
        ,	PRIMARY KEY (TmpTransactionsId)
        , 	INDEX IX_Temp_BrowserInfo_BrowserInfoId(BrowserInfoId)
        , 	INDEX IX_Temp_BrowserInfo_BrowserInfoCodee(BrowserInfoCode)
        , 	INDEX IX_Temp_BrowserInfo_BrowserInfoAttributeCode(BrowserInfoAttributeCode)
    );
    
	INSERT INTO Temp_Transaction(CookieCode, CustId, SubAccId, AccountId, LoginName, SubscriberId, TransTime, ClientIp, UserAgent, UserAgentCode, Url, Action, TransKey, FingerprintAttribute, UserAgentInfo, BrowserInfo, BrowserInfoAttribute)
	SELECT	rt.CookieCode
		,	rt.CustId
		,	rt.SubAccId
		,	rt.AccountId
		,	rt.LoginName
		,	rt.SubscriberId
		,	rt.TransTime
		,	rt.ClientIp
		,	rt.UserAgent
		,	rt.UserAgentCode
		,	rt.Url
		,	rt.Action
		,	rt.TransKey
		,	rt.FingerprintAttribute
		,	rt.UserAgentInfo
		,	rt.BrowserInfo
		,	rt.BrowserInfoAttribute
	FROM	JSON_TABLE(
			ip_Transaction,
			 "$[*]" COLUMNS(
						CookieCode				VARCHAR(200) 	PATH "$.CookieCode"
					,	CustId 					BIGINT		 	PATH "$.CustId"
					,	SubAccId 				BIGINT		 	PATH "$.SubAccId"
					,	AccountId 				BIGINT UNSIGNED	PATH "$.AccountId"
					,	LoginName 				VARCHAR(100) 	PATH "$.LoginName"
					,	SubscriberId 			INT			 	PATH "$.SubscriberId"
					,	TransTime 				DATETIME(4)	 	PATH "$.TransTime"
					,	ClientIp 				VARCHAR(45)	 	PATH "$.ClientIp"
					,	UserAgent 				LONGTEXT	 	PATH "$.UserAgent"
					,	UserAgentCode 			VARCHAR(100) 	PATH "$.UserAgentCode"
					,	Url 					VARCHAR(100)	PATH "$.Url"
					,	Action 					VARCHAR(100)	PATH "$.Action"
					,	TransKey 				VARCHAR(200) 	PATH "$.TransKey"
					,	FingerprintAttribute	JSON			PATH "$.FingerprintAttribute"
					,	UserAgentInfo			JSON			PATH "$.UserAgentInfo"
					,	BrowserInfo				JSON			PATH "$.BrowserInfo"
					,	BrowserInfoAttribute	JSON			PATH "$.BrowserInfoAttribute"
				)
		   ) AS  rt;
           
    /*******Account********************/
    INSERT INTO FPS_FingerPrint.Account(SubscriberId, LoginName, CreatedDate)
    SELECT 	tmp.SubscriberId
		,	tmp.LoginName
		,	lv_CurrentDate AS CreatedDate
    FROM Temp_Transaction AS tmp
    ON DUPLICATE KEY UPDATE ModifiedDate = lv_CurrentDate;
    
    UPDATE Temp_Transaction AS tmp
		INNER JOIN FPS_FingerPrint.Account AS acc ON acc.SubscriberId = tmp.SubscriberId AND acc.LoginName = tmp.LoginName
	SET tmp.AccountId = acc.Id;
    
    /*******Cookie********************/
    INSERT IGNORE INTO FPS_FingerPrint.Cookie(CookieCode, CreatedDate, ModifiedDate)
	SELECT	DISTINCT
			tmp.CookieCode		
        ,	lv_CurrentDate AS CreatedDate
        ,	lv_CurrentDate AS ModifiedDate
	FROM Temp_Transaction AS tmp
    WHERE NOT EXISTS (SELECT 1 FROM FPS_FingerPrint.Cookie c WHERE c.CookieCode = tmp.CookieCode);
    
    INSERT INTO Temp_Cookie(TmpTransactionsId, CookieId)
    SELECT 	tmp.Id AS TmpTransactionsId
		,	c.Id AS CookieId
    FROM Temp_Transaction AS tmp
		INNER JOIN FPS_FingerPrint.Cookie AS c ON c.CookieCode = tmp.CookieCode;
        
    UPDATE Temp_Transaction AS tmp
		INNER JOIN Temp_Cookie AS c ON c.TmpTransactionsId = tmp.Id
    SET tmp.CookieId = c.CookieId;
        
    /*******RawUserAgent********************/
    INSERT IGNORE INTO Temp_RawUserAgent(TmpTransactionsId, UserAgentCode, UserAgent, ClientType, ClientName, ClientVersion, OSName, OSShortName, OSVersion, OSPlatform, Device, Brand, Model)
    SELECT 	tmp.Id AS TmpTransactionsId
		,	tmp.UserAgentCode
		,	tmp.UserAgent
		,	tmp.UserAgentInfo->>'$.ClientType'
		,	tmp.UserAgentInfo->>'$.ClientName'
		,	tmp.UserAgentInfo->>'$.ClientVersion'
		,	tmp.UserAgentInfo->>'$.OSName'
		,	tmp.UserAgentInfo->>'$.OSShortName'
		,	tmp.UserAgentInfo->>'$.OSVersion'
		,	tmp.UserAgentInfo->>'$.OSPlatform'
		,	tmp.UserAgentInfo->>'$.Device'
		,	tmp.UserAgentInfo->>'$.Brand'
		,	tmp.UserAgentInfo->>'$.Model'
    FROM Temp_Transaction AS tmp;
    
	/*******RawUserAgent********************/
    INSERT IGNORE INTO FPS_FingerPrint.RawUserAgent (UserAgentCode, UserAgent, ClientType, ClientName, ClientVersion, OSName, OSShortName, OSVersion, OSPlatform, Device, Brand, Model, CreatedDate, ModifiedDate)
	SELECT	DISTINCT
			tmp.UserAgentCode
		,	tmp.UserAgent
		,	tmp.ClientType
		,	tmp.ClientName
		,	tmp.ClientVersion
		,	tmp.OSName
		,	tmp.OSShortName
		,	tmp.OSVersion
		,	tmp.OSPlatform
		,	tmp.Device
		,	tmp.Brand
		,	tmp.Model
        ,	lv_CurrentDate AS CreatedDate
        ,	lv_CurrentDate AS ModifiedDate
	FROM Temp_RawUserAgent AS tmp
    WHERE NOT EXISTS (SELECT 1 FROM FPS_FingerPrint.RawUserAgent ua WHERE ua.UserAgentCode = tmp.UserAgentCode);
        
    INSERT INTO Temp_MapIdRawUserAgent(TmpTransactionsId, UserAgentId)
    SELECT 	tmp.TmpTransactionsId
		, 	ua.Id AS UserAgentId
    FROM Temp_RawUserAgent AS tmp
		INNER JOIN FPS_FingerPrint.RawUserAgent AS ua ON tmp.UserAgentCode = ua.UserAgentCode;

    UPDATE Temp_Transaction AS tmp
		INNER JOIN Temp_MapIdRawUserAgent AS ua ON ua.TmpTransactionsId = tmp.Id
	SET tmp.UserAgentId = ua.UserAgentId;
    
    
    /*******FingerPrintAttributes********************/
    INSERT INTO Temp_FingerPrintAttributes(TmpTransactionsId, Attribute, FingerPrintCode, BrowserInstanceCode, Accept, Encoding, Headers, OSName, BrowserName, BrowserVersion, Platform, UserAgent)
    SELECT 	Id AS TmpTransactionsId
		,	FingerprintAttribute->>'$.Attribute'
		,	FingerprintAttribute->>'$.FingerPrintCode'
		,	FingerprintAttribute->>'$.BrowserInstanceCode'
		,	FingerprintAttribute->>'$.Accept'
		,	FingerprintAttribute->>'$.Encoding'
		,	FingerprintAttribute->>'$.Headers'
		,	FingerprintAttribute->>'$.OSName'
		,	FingerprintAttribute->>'$.BrowserName'
		,	FingerprintAttribute->>'$.BrowserVersion'
		,	FingerprintAttribute->>'$.Platform'
		,	FingerprintAttribute->>'$.UserAgent'
    FROM Temp_Transaction;
    
    /*******RawFingerPrint********************/
    INSERT IGNORE INTO FPS_FingerPrint.RawFingerPrint(FingerPrintCode, CreatedDate, ModifiedDate)
	SELECT	tmp.FingerPrintCode		
        ,	lv_CurrentDate AS CreatedDate
        ,	lv_CurrentDate AS ModifiedDate
	FROM Temp_FingerPrintAttributes AS tmp;
    
    INSERT INTO Temp_RawFingerPrint(TmpTransactionsId, RawFingerPrintId)
    SELECT DISTINCT 
			tmp.TmpTransactionsId
		,	rfp.Id AS RawFingerPrintId
    FROM Temp_FingerPrintAttributes AS tmp
		INNER JOIN FPS_FingerPrint.RawFingerPrint AS rfp ON rfp.FingerPrintCode = tmp.FingerPrintCode;
    
    UPDATE Temp_Transaction AS tmp
		INNER JOIN Temp_RawFingerPrint AS rfp ON rfp.TmpTransactionsId = tmp.Id
    SET tmp.RawFingerPrintId = rfp.RawFingerPrintId;
    
    INSERT IGNORE INTO FPS_FingerPrint.FingerPrintAttribute(FingerPrintCode, DoNotTrack, GLRenderer, Audio, Canvas, ColorDepth, ColorGamut, Contrast, Cookies, CpuClass, DeviceMemory, DomBlockers, FontPreferencePrint, Fonts, ForcedColors, HardwareConcurrency, HDR, IndexedDB, InvertedColors, Languages, LocalStorage, Math, Monochrome, OpenDatabase, OsCpu, Platform, Plugins, ReducedMotion, Resolution, SessionStorage, Timezone, TouchSupport, Vendor, VendorFlavors, WebglPrint)
    SELECT	tmp.FingerPrintCode
		,	tmp.Attribute->>'$.doNotTrack' AS DoNotTrack
		,	tmp.Attribute->>'$.webglRenderer' AS GLRenderer
		,	tmp.Attribute->>'$.audio'
		,	tmp.Attribute->>'$.canvasPrint' AS Canvas
		,	tmp.Attribute->>'$.colorDepth'
		,	tmp.Attribute->>'$.colorGamut'
		,	tmp.Attribute->>'$.contrast'
		,	CASE 	tmp.Attribute->>'$.cookiesEnabled'
					WHEN 'true' THEN 1
                    WHEN 'false' THEN 0
                    ELSE NULL END AS Cookies
		,	tmp.Attribute->>'$.cpuClass'
		,	CASE 	tmp.Attribute->>'$.deviceMemory'
					WHEN 'undefined' THEN NULL
                    ELSE tmp.Attribute->>'$.deviceMemory' END AS deviceMemory
		,	tmp.Attribute->>'$.domBlockers'
		,	tmp.Attribute->>'$.fontPreferencePrint'
		,	tmp.Attribute->>'$.fonts'
		,	CASE 	tmp.Attribute->>'$.forcedColors'
					WHEN 'true' THEN 1
                    WHEN 'false' THEN 0
                    ELSE NULL END AS forcedColors
		,	CASE 	tmp.Attribute->>'$.hardwareConcurrency'
					WHEN 'undefined' THEN NULL
                    ELSE tmp.Attribute->>'$.hardwareConcurrency' END AS hardwareConcurrency
		,	CASE 	tmp.Attribute->>'$.hdr'
					WHEN 'true' THEN 1
                    WHEN 'false' THEN 0
                    ELSE NULL END AS hdr
		,	CASE 	tmp.Attribute->>'$.indexedDB'
					WHEN 'true' THEN 1
                    WHEN 'false' THEN 0
                    ELSE NULL END AS indexedDB
		,	CASE 	tmp.Attribute->>'$.invertedColors'
					WHEN 'true' THEN 1
                    WHEN 'false' THEN 0
                    ELSE NULL END AS invertedColors
		,	tmp.Attribute->>'$.languagesPrint' AS Languages
		,	CASE 	tmp.Attribute->>'$.localStorage'
					WHEN 'true' THEN 1
                    WHEN 'false' THEN 0
                    ELSE NULL END AS localStorage
		,	tmp.Attribute->>'$.math'
		,	CASE 	tmp.Attribute->>'$.monochrome'
					WHEN 'undefined' THEN NULL
                    ELSE tmp.Attribute->>'$.monochrome' END AS monochrome
		,	CASE 	tmp.Attribute->>'$.openDatabase'
					WHEN 'true' THEN 1
                    WHEN 'false' THEN 0
                    ELSE -1 END AS openDatabase
		,	tmp.Attribute->>'$.osCpu'
		,	tmp.Attribute->>'$.platform'
		,	tmp.Attribute->>'$.plugins'
		,	CASE 	tmp.Attribute->>'$.reducedMotion'
					WHEN 'true' THEN 1
                    WHEN 'false' THEN 0
                    ELSE -1 END AS reducedMotion
		,	tmp.Attribute->>'$.screenPrint' AS Resolution
		,	CASE 	tmp.Attribute->>'$.sessionStorage'
					WHEN 'true' THEN 1
                    WHEN 'false' THEN 0
                    ELSE -1 END AS sessionStorage
		,	tmp.Attribute->>'$.timezone'
		,	tmp.Attribute->>'$.touchSupport'
		,	tmp.Attribute->>'$.vendor'
		,	tmp.Attribute->>'$.vendorFlavors'
		,	tmp.Attribute->>'$.webglPrint'
	FROM Temp_FingerPrintAttributes AS tmp
    WHERE NOT EXISTS (SELECT 1 FROM FPS_FingerPrint.FingerPrintAttribute fpa WHERE fpa.FingerPrintCode = tmp.FingerPrintCode);
    
    /*******BrowserInstance********************/
	INSERT IGNORE INTO FPS_FingerPrint.BrowserInstance(BrowserInstanceCode, BrowserFamilyCode, UserAgent, OSName, BrowserName, BrowserVersion, Platform, Accept, Encoding, Headers)
    SELECT	tmp.BrowserInstanceCode
		,	MD5(CONCAT(tmp.OSName, tmp.BrowserName, tmp.Platform)) AS BrowserFamilyCode
		,	tmp.UserAgent
		,	tmp.OSName
		,	tmp.BrowserName
		,	tmp.BrowserVersion
		,	tmp.Platform
		,	tmp.Accept
		,	tmp.Encoding
		,	tmp.Headers
	FROM Temp_FingerPrintAttributes AS tmp;
    
    INSERT IGNORE INTO FPS_FingerPrint.BrowserInstanceAttribute(FingerPrintAttributeId, BrowserInstanceId)
    SELECT 	fpa.Id AS FingerPrintAttributeId
		,	bi.Id AS BrowserInstanceId
    FROM Temp_FingerPrintAttributes AS tmp
		INNER JOIN FPS_FingerPrint.FingerPrintAttribute AS fpa ON fpa.FingerPrintCode = tmp.FingerPrintCode
		INNER JOIN FPS_FingerPrint.BrowserInstance AS bi ON bi.BrowserInstanceCode = tmp.BrowserInstanceCode;
    
    /*******BrowserInfo********************/
    INSERT IGNORE INTO Temp_BrowserInfo(TmpTransactionsId, BrowserInfoAttributeCode, OSName, BrowserName, HeadlessScore, HeadlessDetail, SecChUa, SecChUaPlatform, SecChUaMobile, JsBrowserName, JsOSName)
    SELECT 	tmp.Id AS TmpTransactionsId
		,	MD5(tmp.BrowserInfoAttribute) AS BrowserInfoAttributeCode
		,	tmp.BrowserInfo->>'$.OSName'
		,	tmp.BrowserInfo->>'$.BrowserName'
		,	tmp.BrowserInfo->>'$.HeadlessScore'
		,	tmp.BrowserInfo->>'$.HeadlessDetail'
		,	tmp.BrowserInfoAttribute->>'$.SecChUa'
		,	tmp.BrowserInfoAttribute->>'$.SecChUaPlatform'
		,	tmp.BrowserInfoAttribute->>'$.SecChUaMobile'
		,	tmp.BrowserInfoAttribute->>'$.JsBrowserName'
		,	tmp.BrowserInfoAttribute->>'$.JsOSName'
    FROM Temp_Transaction AS tmp;
    
    INSERT IGNORE INTO FPS_FingerPrint.BrowserInfoAttribute(BrowserInfoAttributeCode, SecChUa, SecChUaPlatform, SecChUaMobile, JsBrowserName, JsOSName)
    SELECT 	tmp.BrowserInfoAttributeCode
		,	tmp.SecChUa
		,	tmp.SecChUaPlatform
		,	tmp.SecChUaMobile
		,	tmp.JsBrowserName
		,	tmp.JsOSName
    FROM Temp_BrowserInfo tmp
    WHERE NOT EXISTS (SELECT 1 FROM FPS_FingerPrint.BrowserInfoAttribute bia WHERE bia.BrowserInfoAttributeCode = tmp.BrowserInfoAttributeCode);
    
    UPDATE Temp_BrowserInfo tmp
		LEFT JOIN FPS_FingerPrint.BrowserInfoAttribute bia ON bia.BrowserInfoAttributeCode = tmp.BrowserInfoAttributeCode
		INNER JOIN Temp_Transaction AS tmpT ON tmpT.Id = tmp.TmpTransactionsId
    SET tmp.BrowserInfoAttributeId = bia.Id
	,	tmp.UserAgentId = tmpT.UserAgentId
    ,	tmp.BrowserInfoCode = MD5(CONCAT(COALESCE(tmpT.UserAgentId, '#'), COALESCE(tmp.BrowserInfoAttributeId, '#'), COALESCE(tmp.HeadlessDetail, '#'), COALESCE(tmp.BrowserName, '#'), COALESCE(tmp.OSName, '#'), COALESCE(tmp.HeadlessScore, 0)));
    
    INSERT IGNORE INTO FPS_FingerPrint.BrowserInfo(BrowserInfoAttributeId, BrowserName, OSName, HeadlessScore, HeadlessDetail, UserAgentId, CreatedDate, ModifiedDate, BrowserInfoCode)
    SELECT 	tmp.BrowserInfoAttributeId
		, 	tmp.BrowserName
        , 	tmp.OSName
        , 	tmp.HeadlessScore
        , 	tmp.HeadlessDetail
        , 	tmp.UserAgentId
        ,	lv_CurrentDate AS CreatedDate
        ,	lv_CurrentDate AS ModifiedDate
        ,	tmp.BrowserInfoCode
    FROM Temp_BrowserInfo AS tmp
    WHERE NOT EXISTS (SELECT 1 FROM FPS_FingerPrint.BrowserInfo bi WHERE bi.BrowserInfoCode = tmp.BrowserInfoCode);
    
    UPDATE Temp_BrowserInfo AS tmp
		INNER JOIN FPS_FingerPrint.BrowserInfo AS bi ON bi.BrowserInfoCode = tmp.BrowserInfoCode
	SET tmp.BrowserInfoId = bi.Id;
    
    UPDATE Temp_Transaction AS tmp
		INNER JOIN Temp_BrowserInfo AS bi ON bi.TmpTransactionsId = tmp.Id
	SET tmp.BrowserInfoId = bi.BrowserInfoId;
    
    /*******Evolution********************/
    INSERT INTO Temp_Evolution(Id, CustId, SubAccId, AccountId, LoginName, SubscriberId, RawFingerPrintId, CookieId, TransTime, ClientIP, UserAgentId, Url, Action, TransKey, BrowserInfoId)
	SELECT 	tmp.Id
		,	tmp.CustId
		,	tmp.SubAccId
		,	tmp.AccountId
		,	tmp.LoginName
		,	tmp.SubscriberId
		,	tmp.RawFingerPrintId
		,	tmp.CookieId
		,	tmp.TransTime
		,	tmp.ClientIP
		,	tmp.UserAgentId
		,	tmp.Url
		,	tmp.Action
		,	tmp.TransKey
		,	tmp.BrowserInfoId
	FROM Temp_Transaction AS tmp 
	WHERE NOT EXISTS (SELECT 1 FROM FPS_FingerPrint.DeviceFingerPrint df WHERE df.RawFingerPrintId = tmp.RawFingerPrintId)
		AND NOT EXISTS (SELECT 1 FROM FPS_FingerPrint.DeviceCookie dc WHERE dc.CookieId = tmp.CookieId)
		AND EXISTS (SELECT 1 FROM FPS_FingerPrint.AccountFingerprint af WHERE af.AccountId = tmp.AccountId AND af.IsEvolution IS NULL);
    
    /*******INSERT INTO TransactionEvolution********************/
    IF EXISTS (
		SELECT 1
		FROM Temp_Evolution
    ) THEN
		INSERT INTO FPS_FingerPrint.TransactionEvolution(CustId, SubAccId, AccountId, LoginName, SubscriberId, RawFingerPrintId, CookieId, TransTime, ClientIP, UserAgentId, Url, Action, CreatedDate, TransKey, BrowserInfoId)
        SELECT 	tmp.CustId
			,	tmp.SubAccId
			,	tmp.AccountId
			,	tmp.LoginName
			,	tmp.SubscriberId
			,	tmp.RawFingerPrintId
			,	tmp.CookieId
			,	tmp.TransTime
			,	tmp.ClientIP
			,	tmp.UserAgentId
			,	tmp.Url
			,	tmp.Action
			,	lv_CurrentDate AS CreatedDate
			,	tmp.TransKey
			,	tmp.BrowserInfoId
        FROM Temp_Evolution AS tmp;
        
		DELETE tmp
		FROM Temp_Transaction AS tmp
        INNER JOIN Temp_Evolution AS tmpE ON tmpE.Id = tmp.Id;
    END IF;
    
    /*******Transaction********************/
    INSERT INTO FPS_FingerPrint.Transaction(CustId, SubAccId, AccountId, LoginName, SubscriberId, RawFingerPrintId, CookieId, TransTime, ClientIP, UserAgentId, Url, Action, CreatedDate, TransKey, BrowserInfoId)
	SELECT	tmp.CustId
		,	tmp.SubAccId
		,	tmp.AccountId
		,	tmp.LoginName
		,	tmp.SubscriberId
		,	tmp.RawFingerPrintId
		,	tmp.CookieId
		,	tmp.TransTime
		,	tmp.ClientIP
		,	tmp.UserAgentId
		,	tmp.Url
		,	tmp.Action
		,	lv_CurrentDate AS CreatedDate
		,	tmp.TransKey
		,	tmp.BrowserInfoId
	FROM Temp_Transaction AS tmp;
    
END$$
DELIMITER ;
/*<info serverAlias="FPSDC-FPS_FingerPrint" databaseType="2" executers="fpsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `FPS_FP_Recover_TransactionEvolution_RecoverDevice`;
DELIMITER $$

CREATE DEFINER=`fpsOwner`@`%` PROCEDURE `FPS_FP_Recover_TransactionEvolution_RecoverDevice`(
		ip_TransJson LONGTEXT
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20220913@Jonathan.Doan
		Task :		
		DB:			FPS_FingerPrint
		Original:

		Revisions:
			- 20220913@Jonathan.Doan: Created [Redmine ID: #176820]
			- 20221123@Jonathan.Doan: Remove field SeverTransId, ClientTransId, AddonId [Redmine ID: #180406]
			- 20231017@Teddy.Le: Detect real ip and fake ip via x-real-ip [Redmine ID: #195602]
		Param's Explanation (filtered by):	

		Example:
			- CALL FPS_FP_Recover_TransactionEvolution_RecoverDevice('[{"Id": 1}]');
			
	*/
    
    DECLARE lv_CurrentDate DATETIME DEFAULT NOW();
    
    /*******LOG TEST********************/
    IF (SELECT ofs.OffsetValue FROM FPS_FingerPrint.Offset AS ofs WHERE Id = 7) = 1 THEN		
		INSERT INTO CTS_Log.FPSLog(SpName, JsonString, OtherText, InsertTime)
		SELECT 'FPS_FP_Recover_TransactionEvolution_RecoverDevice', ip_TransJson, NULL, CURRENT_TIMESTAMP();
	END IF;
    /*******LOG TEST********************/
    DROP TEMPORARY TABLE IF EXISTS Temp_Recover;
    DROP TEMPORARY TABLE IF EXISTS Temp_TransactionDevice;
    
    CREATE TEMPORARY TABLE Temp_Recover(
				Id 						BIGINT UNSIGNED NOT NULL PRIMARY KEY
			, 	RecoverFingerPrintId	BIGINT UNSIGNED
			, 	DeviceId				BIGINT UNSIGNED
    );
    
    CREATE TEMPORARY TABLE Temp_TransactionDevice(
			 	Id 						BIGINT UNSIGNED NOT NULL PRIMARY KEY
			, 	CustId					BIGINT UNSIGNED
			, 	SubAccId				BIGINT UNSIGNED
			, 	AccountId				BIGINT UNSIGNED
			, 	LoginName				VARCHAR(100)
			, 	SubscriberId			INT
			, 	RawFingerPrintId		BIGINT UNSIGNED
			, 	BrowserInstanceId		BIGINT UNSIGNED
			, 	CookieId				BIGINT UNSIGNED
			, 	DeviceId				BIGINT UNSIGNED
			, 	RecoverFingerPrintId	BIGINT UNSIGNED
			, 	TransTime				DATETIME(4)
			, 	ClientIP				VARCHAR(45)
            , 	FakeIP					VARCHAR(50)
			, 	BrowserInfoId			BIGINT UNSIGNED
			, 	UserAgentId				BIGINT UNSIGNED
			, 	Url						VARCHAR(100)
			, 	Action					VARCHAR(100)
			, 	CreatedDate				DATETIME
			, 	TransKey				VARCHAR(200)
			, 	RecoverType				TINYINT DEFAULT 0
    );
    
	INSERT IGNORE INTO Temp_Recover(Id, RecoverFingerPrintId)
	SELECT	tmp.Id
		,	tmp.RecoverFingerPrintId
	FROM	JSON_TABLE(
			ip_TransJson,
			 "$[*]" COLUMNS(
						Id						BIGINT UNSIGNED			PATH "$.Id",
						RecoverFingerPrintId	BIGINT UNSIGNED			PATH "$.RecoverFingerPrintId"
				)
		   ) AS tmp;
		   
	UPDATE Temp_Recover AS tmp
		INNER JOIN FPS_FingerPrint.DeviceFingerPrint AS df ON tmp.RecoverFingerPrintId = df.RawFingerPrintId
	SET tmp.DeviceId = df.DeviceId;
		   
	INSERT IGNORE INTO Temp_TransactionDevice(Id, TransTime, CustId, SubAccId, AccountId, LoginName, SubscriberId, RawFingerPrintId, BrowserInstanceId, CookieId, DeviceId, ClientIP, FakeIP, BrowserInfoId, UserAgentId, Url, Action, CreatedDate, TransKey, RecoverType, RecoverFingerPrintId)
	SELECT  te.Id
		,	te.TransTime
		, 	te.CustId
		, 	te.SubAccId
		, 	te.AccountId
		, 	te.LoginName
		, 	te.SubscriberId
		, 	te.RawFingerPrintId
		, 	te.BrowserInstanceId
		, 	te.CookieId
		, 	tmp.DeviceId
		, 	te.ClientIP
        ,	te.FakeIP
		, 	te.BrowserInfoId
		, 	te.UserAgentId
		, 	te.Url
		, 	te.Action
		, 	lv_CurrentDate
		, 	te.TransKey
		, 	4 AS RecoverType
		, 	tmp.RecoverFingerPrintId
	FROM Temp_Recover AS tmp
		INNER JOIN FPS_FingerPrint.TransactionEvolution AS te ON tmp.Id = te.Id;
		   
	INSERT INTO FPS_FingerPrint.TransactionDevice(TransTime, CustId, SubAccId, AccountId, LoginName, SubscriberId, RawFingerPrintId, BrowserInstanceId, CookieId, DeviceId, ClientIP, FakeIP, BrowserInfoId, UserAgentId, Url, Action, CreatedDate, TransKey, RecoverType)
	SELECT  tmp.TransTime
		, 	tmp.CustId
		, 	tmp.SubAccId
		, 	tmp.AccountId
		, 	tmp.LoginName
		, 	tmp.SubscriberId
		, 	tmp.RawFingerPrintId
		, 	tmp.BrowserInstanceId
		, 	tmp.CookieId
		, 	tmp.DeviceId
		, 	tmp.ClientIP
        ,	tmp.FakeIP
		, 	tmp.BrowserInfoId
		, 	tmp.UserAgentId
		, 	tmp.Url
		, 	tmp.Action
		, 	lv_CurrentDate
		, 	tmp.TransKey
		, 	tmp.RecoverType
	FROM Temp_TransactionDevice AS tmp;

	INSERT IGNORE INTO FPS_FingerPrint.DeviceFingerPrint(RawFingerPrintId, DeviceId, CreatedDate)
	WITH cte (RawFingerPrintId, DeviceId) AS
	(
		SELECT 	DISTINCT
				tmp.RawFingerPrintId
			,	tmp.DeviceId
		FROM Temp_TransactionDevice AS tmp
	)
	SELECT 	cte.RawFingerPrintId
		,	cte.DeviceId
		,	lv_CurrentDate
	FROM cte
	WHERE NOT EXISTS (SELECT 1 FROM FPS_FingerPrint.DeviceFingerPrint df WHERE df.RawFingerPrintId = cte.RawFingerPrintId);
	
	INSERT IGNORE INTO FPS_FingerPrint.DeviceCookie(CookieId, DeviceId, CreatedDate)
	WITH cte (CookieId, DeviceId) AS
	(
		SELECT 	DISTINCT
				tmp.CookieId
			,	tmp.DeviceId
		FROM Temp_TransactionDevice AS tmp
		GROUP BY tmp.CookieId, tmp.DeviceId
	)
	SELECT 	cte.CookieId
		,	cte.DeviceId
		,	lv_CurrentDate
	FROM cte
	WHERE NOT EXISTS (SELECT 1 FROM FPS_FingerPrint.DeviceCookie dc WHERE dc.CookieId = cte.CookieId);
	
	/*****AccountFingerprint******************/
	INSERT IGNORE INTO FPS_FingerPrint.AccountFingerprint(AccountId, RawFingerPrintId, CreatedDate)
	SELECT	AccountId
		,	RawFingerPrintId
		,	lv_CurrentDate
	FROM Temp_TransactionDevice;
    
	UPDATE Temp_TransactionDevice AS tmp
		INNER JOIN FPS_FingerPrint.AccountFingerprint AS af ON tmp.AccountId = af.AccountId AND tmp.RecoverFingerPrintId = af.RawFingerPrintId 
	SET af.IsEvolution = 1,
		af.ModifiedDate = lv_CurrentDate;
    
    INSERT IGNORE INTO FPS_FingerPrint.TransactionEvolutionCompleted(Id, RawFingerPrintId, RecoverFingerPrintId, DeviceId, CreatedDate)
    SELECT	Id
		,	RawFingerPrintId
		,	RecoverFingerPrintId
		,	DeviceId
		,	lv_CurrentDate AS CreatedDate
    FROM Temp_TransactionDevice;

	DELETE te
	FROM Temp_Recover AS tmp
		INNER JOIN FPS_FingerPrint.TransactionEvolution AS te ON tmp.Id = te.Id;

END$$
DELIMITER ;

/*<info serverAlias="FPSDC-FPS_FingerPrint" databaseType="2" executers="fpsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `FPS_FP_Transform_ServerTransaction_Update`;
DELIMITER $$

CREATE DEFINER=`fpsOwner`@`%` PROCEDURE `FPS_FP_Transform_ServerTransaction_Update`(
		ip_RawTransJson	LONGTEXT
    ,	ip_Retry		INT
    ,   ip_OffsetId		INT
	,	ip_OffsetValue	BIGINT
)
    SQL SECURITY INVOKER
BEGIN  
	/* 
		Created:	20220221@Terry.Nguyen
		Task :		
		DB:			FPS_FingerPrint
		Original:

		Revisions:
			- 20220307@Terry.Nguyen: Created [Redmine ID: #162668]
			- 20220318@Jonathan.Doan: Update TotalValidTrans in table TransactionDailySum [Redmine ID: #162668]
            - 20220601@Jonathan.Doan: Update BrowserInfo [Redmine ID: #172167]
            - 20220729@Terry.Nguyen: Ignore and check exist in table ServerTransactionCompleted and ClientTransactionCompleted [Redmine ID: #175065]
            - 20220808@Jonathan.Doan: Add AddonId [Redmine ID: #175155]
            - 20220811@Jonathan.Doan: Update UserAgentId into BrowserInfo [Redmine ID: #176448]
            - 20220912@Jonathan.Doan: FPS Evolution [Redmine ID: #176820]
            
		Param's Explanation (filtered by):	

		Example:
			- CALL FPS_FP_Transform_ServerTransaction_Update({});
			
	*/
   
    DECLARE lv_currentDate DATETIME DEFAULT NOW();
    DECLARE lv_countTrans INT DEFAULT 0;
    
    /*******LOG TEST********************/
    IF (SELECT ofs.OffsetValue FROM FPS_FingerPrint.Offset AS ofs WHERE Id = 7) = 1 THEN		
		INSERT INTO CTS_Log.FPSLog(SpName, JsonString, OtherText, InsertTime)
		SELECT 'FPS_FP_Transform_ServerTransaction_Update', ip_RawTransJson, CONCAT('ip_Retry:',ip_Retry,'; ip_OffsetId:',ip_OffsetId,'; ip_OffsetValue:',ip_OffsetValue), CURRENT_TIMESTAMP();
	END IF;
    /*******LOG TEST********************/
    
	DROP TEMPORARY TABLE IF EXISTS Temp_RawTransaction;  
    DROP TEMPORARY TABLE IF EXISTS Temp_RawTransaction2;
    DROP TEMPORARY TABLE IF EXISTS Temp_BrowserInfo;
    DROP TEMPORARY TABLE IF EXISTS Temp_Recover;
    
    /*******Create Temporary table********************/
	CREATE TEMPORARY TABLE Temp_RawTransaction(
			Id 					BIGINT UNSIGNED PRIMARY KEY
		,	SessionKey 			VARCHAR(200) NULL
		,	CustId 				BIGINT DEFAULT NULL
		,	SubAccId 			BIGINT DEFAULT NULL
		,	AccountId 			BIGINT UNSIGNED DEFAULT NULL
		,	LoginName 			VARCHAR(100) DEFAULT NULL
		,	SubscriberId 		INT DEFAULT NULL
		,	TransTime 			DATETIME(4) DEFAULT NULL
		,	ClientIP 			VARCHAR(45) DEFAULT NULL
		,	UserAgentId 		BIGINT UNSIGNED DEFAULT NULL
		,	Url 				VARCHAR(100) DEFAULT NULL
		,	Action 				VARCHAR(100) DEFAULT NULL
		,	CreatedDate 		DATETIME DEFAULT NULL
		,	TransKey 			VARCHAR(200) DEFAULT NULL
		,	Retry 				TINYINT DEFAULT 0
		,	RawFingerPrintId 	BIGINT UNSIGNED DEFAULT NULL
		,	CookieId 			BIGINT UNSIGNED DEFAULT NULL
        
        ,	INDEX IX_Temp_RawTransaction_SessionKey(SessionKey)
    );   
    
	CREATE TEMPORARY TABLE Temp_RawTransaction2(
			Id 					BIGINT UNSIGNED PRIMARY KEY
		,	SessionKey 			VARCHAR(200) NOT NULL
		,	CustId 				BIGINT DEFAULT NULL
		,	SubAccId 			BIGINT DEFAULT NULL
		,	AccountId 			BIGINT UNSIGNED DEFAULT NULL
		,	LoginName 			VARCHAR(100) DEFAULT NULL
		,	SubscriberId 		INT DEFAULT NULL
		,	TransTime 			DATETIME(4) DEFAULT NULL
		,	ClientIP 			VARCHAR(45) DEFAULT NULL
		,	UserAgentId 		BIGINT UNSIGNED DEFAULT NULL
		,	Url 				VARCHAR(100) DEFAULT NULL
		,	Action 				VARCHAR(100) DEFAULT NULL
		,	CreatedDate 		DATETIME DEFAULT NULL
		,	TransKey 			VARCHAR(200) DEFAULT NULL
		,	Retry 				TINYINT DEFAULT '0'
		,	ClientTransId		BIGINT UNSIGNED DEFAULT NULL
		,	RawFingerPrintId 	BIGINT UNSIGNED DEFAULT NULL
		,	CookieId 			BIGINT UNSIGNED DEFAULT NULL
		,	BrowserInfoId 		BIGINT UNSIGNED DEFAULT NULL
		,	AddonId		 		BIGINT UNSIGNED DEFAULT NULL
        
        ,	INDEX IX_Temp_RawTransaction2_ClientTransId (ClientTransId)
    );
   
    CREATE TEMPORARY TABLE Temp_BrowserInfo(
			Id 				BIGINT UNSIGNED NOT NULL PRIMARY KEY
		, 	SessionKey 		VARCHAR(200)
		, 	UserAgentId 	BIGINT UNSIGNED DEFAULT NULL
		, 	UNIQUE INDEX UX_Temp_BrowserInfo_SessionKey(SessionKey)
    );
   
    CREATE TEMPORARY TABLE Temp_Recover(
			Id 					BIGINT UNSIGNED PRIMARY KEY
		,	SessionKey 			VARCHAR(200) NOT NULL
		,	CustId 				BIGINT DEFAULT NULL
		,	SubAccId 			BIGINT DEFAULT NULL
		,	AccountId 			BIGINT UNSIGNED DEFAULT NULL
		,	LoginName 			VARCHAR(100) DEFAULT NULL
		,	SubscriberId 		INT DEFAULT NULL
		,	TransTime 			DATETIME(4) DEFAULT NULL
		,	ClientIP 			VARCHAR(45) DEFAULT NULL
		,	UserAgentId 		BIGINT UNSIGNED DEFAULT NULL
		,	Url 				VARCHAR(100) DEFAULT NULL
		,	Action 				VARCHAR(100) DEFAULT NULL
		,	CreatedDate 		DATETIME DEFAULT NULL
		,	TransKey 			VARCHAR(200) DEFAULT NULL
		,	Retry 				TINYINT DEFAULT '0'
		,	ClientTransId		BIGINT UNSIGNED
		,	RawFingerPrintId 	BIGINT UNSIGNED DEFAULT NULL
		,	CookieId 			BIGINT UNSIGNED DEFAULT NULL
		,	BrowserInfoId 		BIGINT UNSIGNED DEFAULT NULL
		,	AddonId		 		BIGINT UNSIGNED DEFAULT NULL
        
        ,	INDEX IX_Temp_Recover_RawFingerPrintId (RawFingerPrintId)
    );
    
   INSERT INTO Temp_RawTransaction(Id, SessionKey, CustId, SubAccId, AccountId, LoginName, SubscriberId, TransTime, ClientIP, UserAgentId, Url, TransKey, Retry, Action, CreatedDate)
	SELECT	rt.Id
		,	rt.SessionKey
		,	rt.CustId
		,	rt.SubAccId
		,	rt.AccountId
		,	rt.LoginName
		,	rt.SubscriberId
		,	rt.TransTime
		,	rt.ClientIP
		,	rt.UserAgentId
		,	rt.Url
        ,	rt.TransKey
        ,	rt.Retry
        ,	rt.Action
        ,	lv_currentDate
	FROM	JSON_TABLE(
			ip_RawTransJson,
			 "$[*]" COLUMNS(
								Id						BIGINT			PATH "$.Id"
							,	SessionKey				VARCHAR(200) 	PATH "$.SessionKey"
							,	CustId					BIGINT 			PATH "$.CustId"
							,	SubAccId				BIGINT			PATH "$.SubAccId"
							,	AccountId				BIGINT UNSIGNED	PATH "$.AccountId"
							,	LoginName				VARCHAR(100)	PATH "$.LoginName"
							,	SubscriberId			INT 			PATH "$.SubscriberId"
							,	TransTime				DATETIME(4)	 	PATH "$.TransTime"
                            ,	ClientIP				VARCHAR(45)		PATH "$.ClientIP"
                            ,	UserAgentId				BIGINT UNSIGNED	PATH "$.UserAgentId"
							,	Url						VARCHAR(100) 	PATH "$.Url"
							,	TransKey				VARCHAR(200) 	PATH "$.TransKey"
                            ,	Retry					TINYINT			PATH "$.Retry"
							,	Action					VARCHAR(100) 	PATH "$.Action"
				)
		   ) AS  rt;    
    
   INSERT INTO Temp_RawTransaction2(Id, SessionKey, CustId, SubAccId, LoginName, SubscriberId, TransTime, ClientIP, UserAgentId, Url, TransKey, Retry, Action, ClientTransId, RawFingerPrintId, CookieId, AddonId, CreatedDate)
   SELECT 	tmpTs.Id
	   , 	tmpTs.SessionKey
	   , 	tmpTs.CustId
	   , 	tmpTs.SubAccId
	   , 	tmpTs.AccountId
	   , 	tmpTs.LoginName
	   , 	tmpTs.SubscriberId
	   , 	tmpTs.TransTime
	   , 	tmpTs.ClientIP
	   , 	tmpTs.UserAgentId
	   , 	IFNULL(tmpTs.Url, fp.Url)
	   , 	tmpTs.TransKey
	   ,	tmpTs.retry + 1
	   ,	tmpTs.Action
	   ,	fp.Id AS ClientTransId
	   ,	fp.RawFingerPrintId
	   ,	fp.CookieId
	   ,	fp.AddonId
	   ,	lv_currentDate
   FROM Temp_RawTransaction AS tmpTs 
		LEFT JOIN FPS_FingerPrint.ClientTransaction AS fp ON fp.SessionKey = tmpTs.SessionKey;
      
	INSERT IGNORE INTO Temp_BrowserInfo(Id, SessionKey, UserAgentId)
    SELECT 	bi.Id
		,	bi.SessionKey
		,	tmp.UserAgentId
    FROM Temp_RawTransaction tmp
		INNER JOIN FPS_FingerPrint.BrowserInfo AS bi ON bi.SessionKey = tmp.SessionKey;    
    
    /*******Update BrowserInfo UserAgentId********************/
    UPDATE FPS_FingerPrint.BrowserInfo bi
		INNER JOIN Temp_BrowserInfo tmp ON tmp.Id = bi.Id
    SET bi.UserAgentId = tmp.UserAgentId
    WHERE bi.UserAgentId IS NULL;
	
    /*******Update BrowserInfoId********************/
	UPDATE Temp_RawTransaction2 tmp
		INNER JOIN Temp_BrowserInfo AS bi ON bi.SessionKey = tmp.SessionKey
    SET tmp.BrowserInfoId = bi.Id; 
    
    /*******CHECK RECOVER********************/        
	INSERT INTO Temp_Recover(Id, SessionKey, CustId, SubAccId, AccountId, LoginName, SubscriberId, TransTime, ClientIP, UserAgentId, Url, TransKey, Retry, Action, ClientTransId, RawFingerPrintId, CookieId, BrowserInfoId, AddonId, CreatedDate)
	SELECT 	tmpTs.Id
	   , 	tmpTs.SessionKey
	   , 	tmpTs.CustId
	   , 	tmpTs.SubAccId
	   , 	tmpTs.AccountId
	   , 	tmpTs.LoginName
	   , 	tmpTs.SubscriberId
	   , 	tmpTs.TransTime
	   , 	tmpTs.ClientIP
	   , 	tmpTs.UserAgentId
	   , 	tmpTs.Url
	   , 	tmpTs.TransKey
	   ,	tmpTs.Retry
	   ,	tmpTs.Action
	   ,	tmpTs.ClientTransId
	   ,	tmpTs.RawFingerPrintId
	   ,	tmpTs.CookieId
	   ,	tmpTs.BrowserInfoId
	   ,	tmpTs.AddonId
	   ,	tmpTs.CreatedDate
	FROM Temp_RawTransaction2 AS tmpTs 
	WHERE NOT EXISTS (SELECT 1 FROM FPS_FingerPrint.DeviceFingerPrint df WHERE df.RawFingerPrintId = tmpTs.RawFingerPrintId)
		AND NOT EXISTS (SELECT 1 FROM FPS_FingerPrint.DeviceCookie dc WHERE dc.CookieId = tmpTs.CookieId)
		AND EXISTS (SELECT 1 FROM FPS_FingerPrint.AccountFingerprint af WHERE af.AccountId = tmpTs.AccountId AND af.IsEvolution IS NULL)
		AND tmpTs.RawFingerPrintId IS NOT NULL;
    
    /*******INSERT INTO TransactionEvolution********************/
    IF EXISTS (
		SELECT 1
		FROM Temp_Recover
    ) THEN
		INSERT INTO FPS_FingerPrint.TransactionEvolution(ServerTransId, ClientTransId, CustId, SubAccId, AccountId, LoginName, SubscriberId, RawFingerPrintId, CookieId, TransTime, ClientIP, UserAgentId, Url, Action, CreatedDate, TransKey, BrowserInfoId, AddonId)
        SELECT 	tmp.Id
			,	tmp.ClientTransId
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
			,	tmp.CreatedDate
			,	tmp.TransKey
			,	tmp.BrowserInfoId
			,	tmp.AddonId
        FROM Temp_Recover AS tmp;
        
        SELECT COUNT(1)
        INTO lv_countTrans
        FROM Temp_Recover;
        
        INSERT INTO FPS_FingerPrint.RecoverDailySum(TransDate, SubscriberId, TotalRecoverTrans, TotalEvolutionTrans, CreatedDate)
        SELECT 	DATE_FORMAT(tmp.TransTime,'%Y-%m-%d') AS TransDate
			,	tmp.SubscriberId
			,	0 AS TotalRecoverTrans
			,	lv_countTrans AS TotalEvolutionTrans
			,	lv_currentDate AS CreatedDate
        FROM Temp_Recover AS tmp
		ON DUPLICATE KEY UPDATE TotalEvolutionTrans = TotalEvolutionTrans + lv_countTrans,
								ModifiedDate = lv_CurrentDate;

		DELETE tmp
		FROM Temp_RawTransaction2 AS tmp
        INNER JOIN Temp_Recover AS tmpR ON tmpR.Id = tmp.Id;
        
		INSERT IGNORE INTO FPS_FingerPrint.ServerTransactionCompleted(Id, SessionKey, CustId, SubAccId, AccountId, LoginName, SubscriberId, TransTime, ClientIP, UserAgentId, Url, ModifiedDate, CreatedDate, TransKey, Retry, Action)
		SELECT	rt.Id
			,	rt.SessionKey
			,	rt.CustId
			,	rt.SubAccId
			,	rt.AccountId
			,	rt.LoginName
			,	rt.SubscriberId
			,	rt.TransTime
			,	rt.ClientIP
			,	rt.UserAgentId
			,	rt.Url
			,	rt.ModifiedDate
			,	rt.CreatedDate
			,	rt.TransKey
			,	rt.Retry
			,	rt.Action
		FROM Temp_Recover AS tmp 
			INNER JOIN FPS_FingerPrint.ServerTransaction AS rt ON rt.Id = tmp.Id
		WHERE tmp.RawFingerPrintId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM FPS_FingerPrint.ServerTransactionCompleted sc WHERE sc.Id = tmp.Id);
        
		INSERT IGNORE INTO FPS_FingerPrint.ClientTransactionCompleted(Id, RawFingerPrintId, CookieId, SubscriberId, SessionKey, Url, TransTime, AddonId, CreatedDate)
		SELECT	fp.Id
			,	fp.RawFingerPrintId
			,	fp.CookieId
			,	fp.SubscriberId
			,	fp.SessionKey
			,	fp.Url
			,	fp.TransTime
			,	fp.AddonId
			,	fp.CreatedDate
		FROM Temp_Recover AS tmp
			INNER JOIN FPS_FingerPrint.ClientTransaction AS fp ON tmp.SessionKey = fp.SessionKey
		WHERE NOT EXISTS (SELECT 1 FROM FPS_FingerPrint.ClientTransactionCompleted cc WHERE cc.Id = tmp.Id);
			
		DELETE fp FROM FPS_FingerPrint.ClientTransaction AS fp
			INNER JOIN Temp_Recover AS tmp ON tmp.SessionKey = fp.SessionKey;
		
		DELETE rt FROM FPS_FingerPrint.ServerTransaction AS rt 
			INNER JOIN Temp_Recover AS tmp ON rt.Id = tmp.Id
		WHERE tmp.RawFingerPrintId IS NOT NULL;
		
    END IF;
    
	/*******Insert data completed********************/
	INSERT INTO FPS_FingerPrint.Transaction(ServerTransId, ClientTransId, CustId, SubAccId, AccountId, LoginName, SubscriberId, RawFingerPrintId, CookieId, TransTime, ClientIP, UserAgentId, Url, Action, CreatedDate, TransKey, BrowserInfoId, AddonId)
	SELECT	tmpTs2.Id
		,	tmpTs2.ClientTransId
		,	tmpTs2.CustId
		,	tmpTs2.SubAccId
		,	tmpTs2.AccountId
		,	tmpTs2.LoginName
		,	tmpTs2.SubscriberId
		,	tmpTs2.RawFingerPrintId
		,	tmpTs2.CookieId
		,	tmpTs2.TransTime
		,	tmpTs2.ClientIP
		,	tmpTs2.UserAgentId
		,	tmpTs2.Url
		,	tmpTs2.Action
		,	tmpTs2.CreatedDate
		,	tmpTs2.TransKey
		,	tmpTs2.BrowserInfoId
		,	tmpTs2.AddonId
	FROM Temp_RawTransaction2 AS tmpTs2
    WHERE tmpTs2.ClientTransId IS NOT NULL;
    
	SELECT COUNT(1)
	INTO lv_countTrans
	FROM Temp_RawTransaction2;

	INSERT INTO FPS_FingerPrint.RecoverDailySum(TransDate, SubscriberId, TotalRecoverTrans, TotalEvolutionTrans, CreatedDate)
	SELECT 	DATE_FORMAT(tmp.TransTime,'%Y-%m-%d') AS TransDate
		,	tmp.SubscriberId
		,	lv_countTrans AS TotalRecoverTrans
		,	0 AS TotalEvolutionTrans
		,	lv_currentDate AS CreatedDate
	FROM Temp_RawTransaction2 AS tmp
	ON DUPLICATE KEY UPDATE TotalRecoverTrans = TotalRecoverTrans + lv_countTrans,
							ModifiedDate = lv_CurrentDate;

	INSERT IGNORE INTO FPS_FingerPrint.ServerTransactionCompleted(Id, SessionKey, CustId, SubAccId, AccountId, LoginName, SubscriberId, TransTime, ClientIP, UserAgentId, Url, ModifiedDate, CreatedDate, TransKey, Retry, Action)
	SELECT	rt.Id
		,	rt.SessionKey
		,	rt.CustId
		,	rt.SubAccId
		,	rt.AccountId
		,	rt.LoginName
		,	rt.SubscriberId
		,	rt.TransTime
		,	rt.ClientIP
		,	rt.UserAgentId
		,	rt.Url
		,	rt.ModifiedDate
		,	rt.CreatedDate
		,	rt.TransKey
		,	rt.Retry
		,	rt.Action
	FROM Temp_RawTransaction2 AS tmpT2 
		INNER JOIN FPS_FingerPrint.ServerTransaction AS rt ON rt.Id = tmpT2.Id
    WHERE tmpT2.ClientTransId IS NOT NULL AND NOT EXISTS(SELECT 1 FROM FPS_FingerPrint.ServerTransactionCompleted sc WHERE sc.Id = tmpT2.Id);
	
	INSERT IGNORE INTO FPS_FingerPrint.ClientTransactionCompleted(Id, RawFingerPrintId, CookieId, SubscriberId, SessionKey, Url, TransTime, AddonId, CreatedDate)
	SELECT	fp.Id
		,	fp.RawFingerPrintId
		,	fp.CookieId
		,	fp.SubscriberId
		,	fp.SessionKey
		,	fp.Url
		,	fp.TransTime
		,	fp.AddonId
		,	fp.CreatedDate
	FROM Temp_RawTransaction2 AS tmpT2
		INNER JOIN FPS_FingerPrint.ClientTransaction AS fp ON tmpT2.ClientTransId = fp.Id
	WHERE NOT EXISTS(SELECT 1 FROM FPS_FingerPrint.ClientTransactionCompleted cc WHERE cc.Id = tmpT2.ClientTransId);
		
    DELETE fp FROM Temp_RawTransaction2 AS tmpT2
		INNER JOIN FPS_FingerPrint.ClientTransaction AS fp ON tmpT2.ClientTransId = fp.Id;
	
    DELETE rt FROM Temp_RawTransaction2 AS tmpT2 
		INNER JOIN FPS_FingerPrint.ServerTransaction AS rt ON rt.Id = tmpT2.Id
    WHERE tmpT2.ClientTransId IS NOT NULL;
	
	DELETE tmpT2 FROM Temp_RawTransaction2 AS tmpT2
    WHERE tmpT2.ClientTransId IS NOT NULL;
		   
	INSERT INTO FPS_FingerPrint.ServerTransactionN(SessionKey, ServerTransId, CreatedDate, Retry)
	SELECT 	tmpT2.SessionKey
		,	tmpT2.Id
		,	tmpT2.CreatedDate
		,	tmpT2.Retry
	FROM Temp_RawTransaction2 AS tmpT2
    WHERE tmpT2.ClientTransId IS NULL AND tmpT2.Retry >= ip_Retry
    ON DUPLICATE KEY UPDATE Retry = tmpT2.Retry;
    
    UPDATE Temp_RawTransaction2 AS tmp
		INNER JOIN FPS_FingerPrint.ServerTransaction AS rawTrans ON tmp.Id = rawTrans.Id
		SET rawTrans.Retry = tmp.Retry
	WHERE tmp.ClientTransId IS NULL;
    
    DELETE tmpT2 FROM Temp_RawTransaction2 AS tmpT2
    WHERE tmpT2.ClientTransId IS NULL AND Retry >= ip_Retry;
    
    UPDATE FPS_FingerPrint.Offset AS off
		SET off.OffsetValue = ip_OffsetValue
    WHERE off.Id = ip_OffsetId;
END$$
DELIMITER ;
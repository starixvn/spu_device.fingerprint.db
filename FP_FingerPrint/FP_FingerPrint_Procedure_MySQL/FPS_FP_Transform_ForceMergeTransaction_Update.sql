/*<info serverAlias="FPSDC-FPS_FingerPrint" databaseType="2" executers="fpsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `FPS_FP_Transform_ForceMergeTransaction_Update`;
DELIMITER $$

CREATE DEFINER=`fpsOwner`@`%` PROCEDURE `FPS_FP_Transform_ForceMergeTransaction_Update`(
		ip_TransJson LONGTEXT
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20220224@Terry.Nguyen
		Task :		
		DB:			FPS_FingerPrint
		Original:

		Revisions:
			- 20220307@Terry.Nguyen: Created [Redmine ID: #162668]
            - 20220808@Jonathan.Doan: Add AddonId [Redmine ID: #175155]
			- 20221123@Jonathan.Doan: Remove field SeverTransId, ClientTransId, AddonId [Redmine ID: #180406]
            
		Param's Explanation (filtered by):	

		Example:
			- CALL FPS_FP_Transform_ForceMergeTransaction_Update('[{"Id":1,"TransKey":"ABC"},{"Id":2,"TransKey":"abv"}]');
			
	*/        
    
    /*******LOG TEST********************/
    IF (SELECT ofs.OffsetValue FROM FPS_FingerPrint.Offset AS ofs WHERE Id = 7) = 1 THEN		
		INSERT INTO CTS_Log.FPSLog(SpName, JsonString, OtherText, InsertTime)
		SELECT 'FPS_FP_Transform_ForceMergeTransaction_Update', ip_TransJson , NULL, CURRENT_TIMESTAMP();
	END IF;
    /*******LOG TEST********************/
    
    DROP TEMPORARY TABLE IF EXISTS Temp_Transactions; 
    DROP TEMPORARY TABLE IF EXISTS Temp_Transactions2; 
    DROP TEMPORARY TABLE IF EXISTS Temp_TransactionsDevice;
    DROP TEMPORARY TABLE IF EXISTS Temp_TransactionsFlagged;
    
    CREATE TEMPORARY TABLE Temp_Transactions(
			Id 				BIGINT	NOT NULL PRIMARY KEY	
		, 	TransKey 		VARCHAR(200)          
    );
    
    INSERT INTO Temp_Transactions(Id, TransKey)
	SELECT	rt.Id		
        ,	rt.TransKey 
	FROM	JSON_TABLE(
			ip_TransJson,
			 "$[*]" COLUMNS(
							Id						BIGINT			PATH "$.Id"       
						,	TransKey				VARCHAR(200) 	PATH "$.TransKey"                                                 
				)
		   ) AS rt; 
        
    CREATE TEMPORARY TABLE Temp_TransactionsDevice(
			Id 					BIGINT UNSIGNED	NOT NULL PRIMARY KEY
		,	CustId 				BIGINT UNSIGNED
		,	SubAccId 			BIGINT UNSIGNED
		,	AccountId 			BIGINT UNSIGNED
		,	LoginName 			VARCHAR(100) 
		,	SubscriberId 		INT 
		,	RawFingerPrintId 	BIGINT UNSIGNED
		,	BrowserInstanceId 	BIGINT UNSIGNED
		,	CookieId 			BIGINT UNSIGNED
		,	DeviceId 			BIGINT UNSIGNED
		,	TransTime 			DATETIME(4) 
		,	ClientIP 			VARCHAR(45) 
		,	BrowserInfoId		BIGINT UNSIGNED
		,	UserAgentId			BIGINT UNSIGNED
		,	UserAgent 			VARCHAR(500) 
		,	Url 				VARCHAR(100) 
		,	Action 				VARCHAR(100) 
		,	CreatedDate 		DATETIME 
		,	TransKey 			VARCHAR(200) 
		,	Retry 				TINYINT
		,	RecoverType 		TINYINT
        
        , 	INDEX IX_Temp_TransactionsDevice_TransKey(TransKey)
    );
    
    INSERT IGNORE INTO Temp_TransactionsDevice(Id, CustId, SubAccId, AccountId, LoginName, SubscriberId, RawFingerPrintId, BrowserInstanceId, CookieId, DeviceId, TransTime, ClientIP, BrowserInfoId, UserAgentId, UserAgent, Url, Action, CreatedDate, TransKey, Retry, RecoverType)
		SELECT  td.Id
			, 	td.CustId
			, 	td.SubAccId
			, 	td.AccountId
			, 	td.LoginName
			, 	td.SubscriberId
			, 	td.RawFingerPrintId
			, 	td.BrowserInstanceId
			, 	td.CookieId
			, 	td.DeviceId
			, 	td.TransTime
			, 	td.ClientIP
			, 	td.BrowserInfoId
			, 	td.UserAgentId
			, 	ua.UserAgent
			, 	td.Url
			, 	td.Action
			, 	td.CreatedDate
			, 	td.TransKey
			, 	td.Retry
			, 	td.RecoverType
    FROM Temp_Transactions AS tmp
		INNER JOIN FPS_FingerPrint.TransactionDevice AS td ON td.Id = tmp.Id
        LEFT JOIN FPS_FingerPrint.RawUserAgent AS ua ON ua.Id = td.UserAgentId;
    
    CREATE TEMPORARY TABLE Temp_TransactionsFlagged(
			Id 					BIGINT UNSIGNED	NOT NULL PRIMARY KEY
		,	CustId 				BIGINT UNSIGNED
		,	SubAccId 			BIGINT UNSIGNED
		,	AccountId 			BIGINT UNSIGNED
		,	LoginName 			VARCHAR(100)
		,	SubscriberId 		INT UNSIGNED
		,	RawFingerPrintId 	BIGINT UNSIGNED
		,	BrowserInstanceId 	BIGINT UNSIGNED
		,	CookieId 			BIGINT UNSIGNED
		,	DeviceId 			BIGINT UNSIGNED
		,	TransTime 			DATETIME(4)
		,	ClientIP 			VARCHAR(45)
		,	Flagged				TINYINT
		,	BrowserInfoId		BIGINT UNSIGNED
		,	UserAgentId			BIGINT UNSIGNED
		,	UserAgent 			VARCHAR(500)
		,	Url 				VARCHAR(100)
		,	Action 				VARCHAR(100)
		,	CreatedDate 		DATETIME
		,	TransKey 			VARCHAR(200)
		,	Retry 				TINYINT
		,	RecoverType 		TINYINT
        
        , 	INDEX IX_Temp_Transactions_TransKey(TransKey)
    );
    
    /*******UPDATE FLAGGED********************/
    INSERT IGNORE INTO Temp_TransactionsFlagged(Id, CustId, SubAccId, AccountId, LoginName, SubscriberId, RawFingerPrintId, BrowserInstanceId, CookieId, DeviceId, TransTime, ClientIP, Flagged, BrowserInfoId, UserAgentId, UserAgent, Url, Action, CreatedDate, TransKey, Retry, RecoverType)
    SELECT  tmp.Id
		, 	tmp.CustId
		, 	tmp.SubAccId
		, 	tmp.AccountId
		, 	tmp.LoginName
		, 	tmp.SubscriberId
		, 	tmp.RawFingerPrintId
		, 	tmp.BrowserInstanceId
		, 	tmp.CookieId
		, 	tmp.DeviceId
		, 	tmp.TransTime
		, 	tmp.ClientIP
		, 	CASE WHEN bi.Flagged IS NULL THEN 6 ELSE bi.Flagged END AS Flagged
		, 	tmp.BrowserInfoId
		, 	tmp.UserAgentId
		, 	tmp.UserAgent
		, 	tmp.Url
		, 	tmp.Action
		, 	tmp.CreatedDate
		, 	tmp.TransKey
		, 	tmp.Retry
		, 	tmp.RecoverType
    FROM Temp_TransactionsDevice AS tmp
		LEFT JOIN FPS_FingerPrint.BrowserInfo AS bi ON bi.Id = tmp.BrowserInfoId;
        
	INSERT IGNORE INTO FPSTesting.FP_RawTransaction(LoginName, SubscriberName, TransTime, CreatedDate, DeviceCode, FingerprintCode, FingerprintMoreInfo, UserAgent, IP, IPID, PluginID, URL, Action, ActionResult, InvalidDevice, TransStatus,	FPSTransID,	Flagged, FPDeviceID, SubscriberID, CustID, CustSubID, LoginName_Old, TransTime_Old, IP_Old, UserAgent_Old, URL_Old, Flagged_Old, TransKey)
	SELECT	transF.LoginName	
		, 	sub.Name
		, 	transF.TransTime
		,	DATE(transF.TransTime) AS CreatedDate	
		, 	NULL AS DeviceCode
		, 	NULL AS FingerprintCode
		, 	NULL AS FingerprintMoreInfo
		,	transF.UserAgent
		, 	transF.ClientIP
		, 	NULL AS IPID
		, 	NULL AS PluginID
		, 	transF.URL
		, 	transF.Action
		, 	NULL AS ActionResult
		, 	NULL AS InvalidDevice
		, 	0 AS TransStatus
		, 	NULL AS FPSTransID
		, 	transF.Flagged
		, 	transF.DeviceId
		, 	sub.Id
		, 	transF.CustId
		, 	transF.SubAccId
		, 	NULL AS LoginName_Old
		, 	NULL AS TransTime_Old
		, 	NULL AS IP_Old
		, 	NULL AS UserAgent_Old
		, 	NULL AS URL_Old
		, 	NULL AS Flagged_Old
		,	transF.TransKey 
	FROM Temp_TransactionsFlagged AS transF   
		INNER JOIN FPS_FingerPrint.Subscribers AS sub ON sub.Id = transF.SubscriberId;
    
	INSERT IGNORE INTO FPS_FingerPrint.TransactionCompleted(Id, CustId, SubAccId, AccountId, LoginName, SubscriberId, RawFingerPrintId, BrowserInstanceId, CookieId, DeviceId, TransTime, ClientIP, BrowserInfoId, UserAgentId, Url, Action, CreatedDate, TransKey, Retry, RecoverType)
	SELECT	transF.Id
		,	transF.CustId
		,	transF.SubAccId
		,	transF.AccountId
		,	transF.LoginName
		,	transF.SubscriberId
		,	transF.RawFingerPrintId
		,	transF.BrowserInstanceId
		,	transF.CookieId
		,	transF.DeviceId
		,	transF.TransTime
		,	transF.ClientIP
		,	transF.BrowserInfoId
		,	transF.UserAgentId
		,	transF.Url
		,	transF.Action
		,	transF.CreatedDate
		,	transF.TransKey   
		,	transF.Retry
		,	transF.RecoverType
	FROM  Temp_TransactionsFlagged AS transF
    WHERE NOT EXISTS (SELECT 1 FROM FPS_FingerPrint.TransactionCompleted transC WHERE transC.Id = transF.Id AND transC.CreatedDate = transF.CreatedDate);
    
	DELETE transD 
    FROM FPS_FingerPrint.TransactionDevice AS transD
		INNER JOIN Temp_TransactionsFlagged AS transF ON transD.Id = transF.Id; 
    
END$$
DELIMITER ;

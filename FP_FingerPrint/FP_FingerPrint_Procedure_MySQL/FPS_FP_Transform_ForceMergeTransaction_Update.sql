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
			- 20231023@Jonathan.Doan: Apply BotD [Redmine ID: #195880]
            
		Param's Explanation (filtered by):	

		Example:
			- CALL FPS_FP_Transform_ForceMergeTransaction_Update('[{"Id":664,"TransKey":"fe59f38b-3127-4d76-ac9a-8e0806d07460"}]');
			
	*/        
    
    /*******LOG TEST********************/
    IF (SELECT ofs.OffsetValue FROM FPS_FingerPrint.Offset AS ofs WHERE Id = 7) = 1 THEN		
		INSERT INTO CTS_Log.FPSLog(SpName, JsonString, OtherText, InsertTime)
		SELECT 'FPS_FP_Transform_ForceMergeTransaction_Update', ip_TransJson , NULL, CURRENT_TIMESTAMP();
	END IF;
    /*******LOG TEST********************/
    
    DROP TEMPORARY TABLE IF EXISTS Temp_TransInput; 
    DROP TEMPORARY TABLE IF EXISTS Temp_Transactions2; 
    DROP TEMPORARY TABLE IF EXISTS Temp_TransactionsDevice;
    
    CREATE TEMPORARY TABLE Temp_TransInput(
			Id 				BIGINT	NOT NULL PRIMARY KEY	
		, 	TransKey 		VARCHAR(200)          
    );
        
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
		,	UserAgentId			BIGINT UNSIGNED
		,	UserAgent 			VARCHAR(500) 
		,	Url 				VARCHAR(100) 
		,	Action 				VARCHAR(100) 
		,	CreatedDate 		DATETIME 
		,	TransKey 			VARCHAR(200) 
		,	Retry 				TINYINT
		,	RecoverType 		TINYINT
		,	Flagged		 		SMALLINT
		,	BotDetectionValue	BIT(32)
		,	BotComponentID		BIGINT UNSIGNED
        
        , 	INDEX IX_Temp_TransactionsDevice_TransKey(TransKey)
    );
    
    INSERT INTO Temp_TransInput(Id, TransKey)
	SELECT	rt.Id		
        ,	rt.TransKey 
	FROM	JSON_TABLE(
			ip_TransJson,
			 "$[*]" COLUMNS(
							Id						BIGINT			PATH "$.Id"       
						,	TransKey				VARCHAR(200) 	PATH "$.TransKey"                                                 
				)
		   ) AS rt;
    
    INSERT IGNORE INTO Temp_TransactionsDevice(Id, CustId, SubAccId, AccountId, LoginName, SubscriberId, RawFingerPrintId, BrowserInstanceId, CookieId, DeviceId, TransTime, ClientIP, UserAgentId, UserAgent, Url, Action, CreatedDate, TransKey, Retry, RecoverType, Flagged, BotDetectionValue, BotComponentID)
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
			, 	td.UserAgentId
			, 	ua.UserAgent
			, 	td.Url
			, 	td.Action
			, 	td.CreatedDate
			, 	td.TransKey
			, 	td.Retry
			, 	td.RecoverType
			, 	td.Flagged
			, 	td.BotDetectionValue
			, 	td.BotComponentID
    FROM Temp_TransInput AS tmpInput
		INNER JOIN FPS_FingerPrint.TransactionDevice AS td ON td.Id = tmpInput.Id
        LEFT JOIN FPS_FingerPrint.RawUserAgent AS ua ON ua.Id = td.UserAgentId;
        
	INSERT IGNORE INTO FPSTesting.FP_RawTransaction(LoginName, SubscriberName, TransTime, CreatedDate, DeviceCode, FingerprintCode, FingerprintMoreInfo, UserAgent, IP, IPID, PluginID, URL, Action, ActionResult, InvalidDevice, TransStatus,	FPSTransID,	Flagged, FPDeviceID, SubscriberID, CustID, CustSubID, LoginName_Old, TransTime_Old, IP_Old, UserAgent_Old, URL_Old, Flagged_Old, TransKey)
	SELECT	tmpTD.LoginName	
		, 	sub.Name
		, 	tmpTD.TransTime
		,	DATE(tmpTD.TransTime) AS CreatedDate	
		, 	NULL AS DeviceCode
		, 	NULL AS FingerprintCode
		, 	NULL AS FingerprintMoreInfo
		,	tmpTD.UserAgent
		, 	tmpTD.ClientIP
		, 	NULL AS IPID
		, 	NULL AS PluginID
		, 	tmpTD.URL
		, 	tmpTD.Action
		, 	NULL AS ActionResult
		, 	NULL AS InvalidDevice
		, 	0 AS TransStatus
		, 	NULL AS FPSTransID
		, 	tmpTD.Flagged
		, 	tmpTD.DeviceId
		, 	sub.Id
		, 	tmpTD.CustId
		, 	tmpTD.SubAccId
		, 	NULL AS LoginName_Old
		, 	NULL AS TransTime_Old
		, 	NULL AS IP_Old
		, 	NULL AS UserAgent_Old
		, 	NULL AS URL_Old
		, 	NULL AS Flagged_Old
		,	tmpTD.TransKey 
	FROM Temp_TransactionsDevice AS tmpTD   
		INNER JOIN FPS_FingerPrint.Subscribers AS sub ON sub.Id = tmpTD.SubscriberId;
    
	INSERT IGNORE INTO FPS_FingerPrint.TransactionCompleted(Id, CustId, SubAccId, AccountId, LoginName, SubscriberId, RawFingerPrintId, BrowserInstanceId, CookieId, DeviceId, TransTime, ClientIP, UserAgentId, Url, Action, CreatedDate, TransKey, Retry, RecoverType, Flagged, BotDetectionValue, BotComponentID)
	SELECT	tmpTD.Id
		,	tmpTD.CustId
		,	tmpTD.SubAccId
		,	tmpTD.AccountId
		,	tmpTD.LoginName
		,	tmpTD.SubscriberId
		,	tmpTD.RawFingerPrintId
		,	tmpTD.BrowserInstanceId
		,	tmpTD.CookieId
		,	tmpTD.DeviceId
		,	tmpTD.TransTime
		,	tmpTD.ClientIP
		,	tmpTD.UserAgentId
		,	tmpTD.Url
		,	tmpTD.Action
		,	tmpTD.CreatedDate
		,	tmpTD.TransKey   
		,	tmpTD.Retry
		,	tmpTD.RecoverType
		, 	tmpTD.Flagged
		, 	tmpTD.BotDetectionValue
		, 	tmpTD.BotComponentID
	FROM  Temp_TransactionsDevice AS tmpTD
    WHERE NOT EXISTS (SELECT 1 FROM FPS_FingerPrint.TransactionCompleted transC WHERE transC.Id = tmpTD.Id AND transC.CreatedDate = tmpTD.CreatedDate);
    
    DELETE td 
    FROM FPS_FingerPrint.TransactionDevice AS td
		INNER JOIN Temp_TransactionsDevice AS tmpTD ON td.Id = tmpTD.Id;
END$$
DELIMITER ;
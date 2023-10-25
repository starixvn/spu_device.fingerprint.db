/*<info serverAlias="FPSDC-FPS_FingerPrint" databaseType="2" executers="fpsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `FPS_FP_Transform_MergeTransaction_Update`;
DELIMITER $$

CREATE DEFINER=`fpsOwner`@`%` PROCEDURE `FPS_FP_Transform_MergeTransaction_Update`(
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
            - 20231017@Teddy.Le: Detect real ip and fake ip via x-real-ip [Redmine ID: #195602]
			- 20231023@Jonathan.Doan: Apply BotD [Redmine ID: #195880]
            
		Param's Explanation (filtered by):	

		Example:
			CALL FPS_FP_Transform_MergeTransaction_Update('[{"Id":663,"TransKey":"test#638336755868139990"}]');
			
	*/
    /*******LOG TEST********************/
    IF (SELECT ofs.OffsetValue FROM FPS_FingerPrint.Offset AS ofs WHERE Id = 7) = 1 THEN		
		INSERT INTO CTS_Log.FPSLog(SpName, JsonString, OtherText, InsertTime)
		SELECT 'FPS_FP_Transform_MergeTransaction_Update', ip_TransJson,NULL, CURRENT_TIMESTAMP();
	END IF;
    /*******LOG TEST********************/
    
    DROP TEMPORARY TABLE IF EXISTS Temp_TransInput;
    DROP TEMPORARY TABLE IF EXISTS Temp_Transactions;
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
		,	SubscriberId 		INT UNSIGNED
		,	RawFingerPrintId 	BIGINT UNSIGNED
		,	BrowserInstanceId 	BIGINT UNSIGNED
		,	CookieId 			BIGINT UNSIGNED
		,	DeviceId 			BIGINT UNSIGNED
		,	TransTime 			DATETIME(4)
		,	ClientIP 			VARCHAR(45)
        ,	FakeIP 				VARCHAR(50)
		,	BrowserInfoId		BIGINT UNSIGNED
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
        
        ,	INDEX IX_Temp_TransactionsDevice_TransKey(TransKey)
    );
    
    CREATE TEMPORARY TABLE Temp_Transactions(
			Id					BIGINT UNSIGNED	NOT NULL PRIMARY KEY
		,	Id_Old				BIGINT UNSIGNED
		,	AccountId			BIGINT UNSIGNED
		,	LoginName 			VARCHAR(100) 
		,	SubscriberName 		VARCHAR(50) 
		,	TransTime 			TIMESTAMP(4) 
		,	CreatedDate 		DATETIME 
		,	DeviceCode 			VARCHAR(32) 
		,	FingerprintCode 	VARCHAR(620) 
		,	FingerprintMoreInfo VARCHAR(250) 
		,	UserAgentId			BIGINT UNSIGNED
		,	UserAgent 			VARCHAR(500) 
		,	IP 					VARCHAR(50) 
		,	FakeIP				VARCHAR(50) 
		,	IPID 				DECIMAL(50,0) 
		,	PluginID 			BIGINT UNSIGNED
		,	URL 				VARCHAR(500) 
		,	Action 				VARCHAR(100) 
		,	ActionResult 		VARCHAR(100) 
		,	InvalidDevice 		VARCHAR(1000) 
		,	TransStatus 		BIT(16) 
		,	FPSTransID 			BIGINT UNSIGNED
		,	Flagged				SMALLINT
		,	IsProcessed 		TINYINT 
		,	TransID 			BIGINT UNSIGNED
		,	FPDeviceID 			BIGINT UNSIGNED
		,	SubscriberID 		INT 
		,	CustID 				INT 
		,	CustSubID 			INT 
		,	LoginName_Old 		VARCHAR(100) 
		,	TransTime_Old 		TIMESTAMP(4) 
		,	IP_Old 				VARCHAR(50) 
		,	UserAgent_Old 		VARCHAR(1000) 
		,	URL_Old 			VARCHAR(500) 
		,	Flagged_Old 		SMALLINT 
        ,	TransKey			VARCHAR(200)
        
        , 	INDEX IX_Temp_Transactions_Id_Old(Id_Old)
    );
    
    INSERT IGNORE INTO Temp_TransInput(Id, TransKey)
	SELECT	rt.Id
        ,	rt.TransKey
	FROM	JSON_TABLE(
			ip_TransJson,
			 "$[*]" COLUMNS(
								Id						BIGINT			PATH "$.Id"
							,	TransKey				VARCHAR(200) 	PATH "$.TransKey"
				)
		   ) AS  rt; 
    
    INSERT IGNORE INTO Temp_TransactionsDevice(Id, CustId, SubAccId, AccountId, LoginName, SubscriberId, RawFingerPrintId, BrowserInstanceId, CookieId, DeviceId, TransTime, ClientIP, FakeIP, UserAgentId, UserAgent, Url, Action, CreatedDate, TransKey, Retry, RecoverType, Flagged, BotDetectionValue, BotComponentID)
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
		, 	td.FakeIP
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
    FROM Temp_TransInput AS tmp
		INNER JOIN FPS_FingerPrint.TransactionDevice AS td ON td.Id = tmp.Id
		LEFT JOIN FPS_FingerPrint.RawUserAgent AS ua ON ua.Id = td.UserAgentId;
    
    
    INSERT IGNORE INTO Temp_Transactions(Id, Id_Old, AccountId, LoginName, SubscriberName, TransTime, CreatedDate, DeviceCode, FingerprintCode, FingerprintMoreInfo, UserAgentId, UserAgent, IP, FakeIP, Flagged, IPID, PluginID, URL, Action, ActionResult, InvalidDevice, TransStatus, FPSTransID, IsProcessed, TransID, FPDeviceID, SubscriberID, CustID, CustSubID, LoginName_Old, TransTime_Old, IP_Old, UserAgent_Old, URL_Old, Flagged_Old,TransKey)
	SELECT	tmpTD.Id
		,	rtOld.TransID
		,	tmpTD.AccountId
		,	tmpTD.LoginName
		,	rtOld.SubscriberName
		,	tmpTD.TransTime
		,	rtOld.CreatedDate
		,	rtOld.DeviceCode
		,	rtOld.FingerprintCode
		,	rtOld.FingerprintMoreInfo
		,	tmpTD.UserAgentId
		,	tmpTD.UserAgent
		,	tmpTD.ClientIP AS IP
		,	tmpTD.FakeIP
		, 	tmpTD.Flagged
		,	rtOld.IPID
		,	rtOld.PluginID
		,	tmpTD.URL
		,	tmpTD.Action
		,	rtOld.ActionResult
		,	rtOld.InvalidDevice
		,	rtOld.TransStatus
		,	rtOld.FPSTransID
		,	rtOld.IsProcessed
		,	rtOld.TransID
		,	tmpTD.DeviceId
		,	tmpTD.SubscriberId
		,	tmpTD.CustId
		,	tmpTD.SubAccId
		,	rtOld.LoginName
		,	rtOld.TransTime
		,	rtOld.IP
		,	rtOld.UserAgent
		,	rtOld.URL
		,	rtOld.Flagged
        ,	tmpTD.TransKey
	FROM Temp_TransactionsDevice AS tmpTD
		INNER JOIN FPSTesting.FP_RawTransaction_Old AS rtOld ON tmpTD.TransKey = rtOld.TransKey;
    
	INSERT IGNORE INTO FPSTesting.FP_RawTransaction(LoginName,	SubscriberName,	TransTime, CreatedDate,	DeviceCode,	FingerprintCode, FingerprintMoreInfo, UserAgent, IP, FakeIP, IPID, PluginID, URL, Action, ActionResult, InvalidDevice, TransStatus,	FPSTransID,	Flagged, FPDeviceID, SubscriberID, CustID,	CustSubID, LoginName_Old, TransTime_Old, IP_Old, UserAgent_Old, URL_Old, Flagged_Old, TransKey)
	SELECT	tmpTrans.LoginName	
	   , 	tmpTrans.SubscriberName
	   , 	tmpTrans.TransTime
	   ,	DATE(tmpTrans.TransTime)	
	   , 	tmpTrans.DeviceCode
	   , 	tmpTrans.FingerprintCode
	   , 	tmpTrans.FingerprintMoreInfo
	   ,	tmpTrans.UserAgent
	   , 	tmpTrans.IP
	   , 	tmpTrans.FakeIP
	   , 	tmpTrans.IPID
	   , 	tmpTrans.PluginID
	   , 	tmpTrans.URL
	   , 	tmpTrans.Action
	   , 	tmpTrans.ActionResult
	   , 	tmpTrans.InvalidDevice
	   , 	tmpTrans.TransStatus
	   , 	tmpTrans.FPSTransID
	   , 	tmpTrans.Flagged
	   , 	tmpTrans.FPDeviceID
	   , 	tmpTrans.SubscriberId
	   , 	tmpTrans.CustId
	   , 	tmpTrans.CustSubID
	   , 	tmpTrans.LoginName_Old
	   , 	tmpTrans.TransTime_Old
	   , 	tmpTrans.IP_Old
	   , 	tmpTrans.UserAgent_Old
	   , 	tmpTrans.URL_Old
	   , 	tmpTrans.Flagged_Old
	   ,	tmpTrans.TransKey
	FROM Temp_Transactions AS tmpTrans;
      
   INSERT IGNORE INTO FPS_FingerPrint.TransactionCompleted(Id, CustId, SubAccId, AccountId, LoginName, SubscriberId, RawFingerPrintId, BrowserInstanceId, CookieId, DeviceId, TransTime, ClientIP, FakeIP, UserAgentId, Url, Action, CreatedDate, TransKey, Retry, RecoverType, Flagged, BotDetectionValue, BotComponentID)
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
		,	tmpTD.FakeIP
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
		INNER JOIN Temp_Transactions AS tmpTrans ON tmpTD.Id = tmpTrans.Id
    WHERE NOT EXISTS (SELECT 1 FROM FPS_FingerPrint.TransactionCompleted transC WHERE transC.Id = tmpTD.Id AND transC.CreatedDate = tmpTD.CreatedDate);
    
	DELETE td FROM FPS_FingerPrint.TransactionDevice AS td
		INNER JOIN Temp_Transactions AS tmpTrans ON td.Id = tmpTrans.Id;
   
	DELETE tmpTD FROM Temp_TransactionsDevice AS tmpTD
		INNER JOIN Temp_Transactions AS tmpTrans ON tmpTD.Id = tmpTrans.Id;
   
	UPDATE FPS_FingerPrint.TransactionDevice AS td
		INNER JOIN Temp_TransactionsDevice AS tmpTD ON td.Id = tmpTD.Id
	SET td.Retry = tmpTD.Retry + 1;

	INSERT IGNORE INTO FPSTesting.FP_RawTransaction_Old_Completed(LoginName, SubscriberName, TransTime, CreatedDate, DeviceCode, FingerprintCode, FingerprintMoreInfo, UserAgent, IP, FakeIP, IPID, PluginID, URL, Action, ActionResult, InvalidDevice, TransStatus, FPSTransID, Flagged, IsProcessed, TransID, TransKey)
	SELECT 	rtOld.LoginName
		, 	rtOld.SubscriberName
		, 	rtOld.TransTime
		, 	rtOld.CreatedDate
		, 	rtOld.DeviceCode
		, 	rtOld.FingerprintCode
		, 	rtOld.FingerprintMoreInfo
		, 	rtOld.UserAgent
		, 	rtOld.IP
		, 	rtOld.FakeIP
		, 	rtOld.IPID
		, 	rtOld.PluginID
		, 	rtOld.URL
		, 	rtOld.Action
		, 	rtOld.ActionResult
		, 	rtOld.InvalidDevice
		, 	rtOld.TransStatus
		, 	rtOld.FPSTransID
		, 	rtOld.Flagged
		, 	rtOld.IsProcessed
		, 	rtOld.TransID
		, 	rtOld.TransKey 
	FROM FPSTesting.FP_RawTransaction_Old AS rtOld 
		INNER JOIN Temp_Transactions AS tmpTrans ON rtOld.TransID = tmpTrans.Id_Old;
    
	DELETE rtOld 
    FROM FPSTesting.FP_RawTransaction_Old AS rtOld
		INNER JOIN Temp_Transactions AS tmpTrans ON rtOld.TransID = tmpTrans.Id_Old;       
    
    DROP TEMPORARY TABLE IF EXISTS Temp_TransInput; 
    DROP TEMPORARY TABLE IF EXISTS Temp_Transactions; 
    DROP TEMPORARY TABLE IF EXISTS Temp_TransactionsDevice;
        
END$$
DELIMITER ;
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
            
		Param's Explanation (filtered by):	

		Example:
			- CALL FPS_FP_Transform_MergeTransaction_Update('[{"Id":1,"TransKey":"ABC"},{"Id":2,"TransKey":"abv"}]');
			
	*/
    /*******LOG TEST********************/
    IF (SELECT ofs.OffsetValue FROM FPS_FingerPrint.Offset AS ofs WHERE Id = 7) = 1 THEN		
		INSERT INTO CTS_Log.FPSLog(SpName, JsonString, OtherText, InsertTime)
		SELECT 'FPS_FP_Transform_MergeTransaction_Update', ip_TransJson,NULL, CURRENT_TIMESTAMP();
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
    
    INSERT IGNORE INTO Temp_Transactions(Id, TransKey)
	SELECT	rt.Id
        ,	rt.TransKey
	FROM	JSON_TABLE(
			ip_TransJson,
			 "$[*]" COLUMNS(
								Id						BIGINT			PATH "$.Id"
							,	TransKey				VARCHAR(200) 	PATH "$.TransKey"
				)
		   ) AS  rt; 
    
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
        ,	FakeIP 				VARCHAR(45)
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
    );
    
    INSERT IGNORE INTO Temp_TransactionsDevice(Id, CustId, SubAccId, AccountId, LoginName, SubscriberId, RawFingerPrintId, BrowserInstanceId, CookieId, DeviceId, TransTime, ClientIP, FakeIP, BrowserInfoId, UserAgentId, UserAgent, Url, Action, CreatedDate, TransKey, Retry, RecoverType)
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
        ,	td.FakeIP
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
        ,	FakeIP 				VARCHAR(45)
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
    INSERT IGNORE INTO Temp_TransactionsFlagged(Id, CustId, SubAccId, AccountId, LoginName, SubscriberId, RawFingerPrintId, BrowserInstanceId, CookieId, DeviceId, TransTime, ClientIP, FakeIP, Flagged, BrowserInfoId, UserAgentId, UserAgent, Url, Action, CreatedDate, TransKey, Retry, RecoverType)
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
        ,	tmp.FakeIP
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
		LEFT JOIN FPS_FingerPrint.BrowserInfo AS bi ON bi.Id = tmp.BrowserInfoId
	WHERE tmp.DeviceId IS NULL
		OR (tmp.DeviceId IS NOT NULL AND bi.Id IS NOT NULL);
    
    CREATE TEMPORARY TABLE Temp_Transactions2(
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
		,	IPID 				DECIMAL(50,0) 
		,	PluginID 			BIGINT UNSIGNED
		,	URL 				VARCHAR(500) 
		,	Action 				VARCHAR(100) 
		,	ActionResult 		VARCHAR(100) 
		,	InvalidDevice 		VARCHAR(1000) 
		,	TransStatus 		BIT(16) 
		,	FPSTransID 			BIGINT UNSIGNED
		,	Flagged				SMALLINT
		,	BrowserInfoId		BIGINT UNSIGNED
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
        
        , 	INDEX IX_Temp_Transactions2_Id_Old(Id_Old)
    );
    
    INSERT IGNORE INTO Temp_Transactions2(Id, Id_Old, AccountId, LoginName, SubscriberName, TransTime, CreatedDate, DeviceCode, FingerprintCode, FingerprintMoreInfo, UserAgentId, UserAgent, IP, FakeIP, Flagged, BrowserInfoId, IPID, PluginID, URL, Action, ActionResult, InvalidDevice, TransStatus, FPSTransID, IsProcessed, TransID, FPDeviceID, SubscriberID, CustID, CustSubID, LoginName_Old, TransTime_Old, IP_Old, UserAgent_Old, URL_Old, Flagged_Old,TransKey)
	SELECT	transF.Id
		,	transO.TransID
		,	transF.AccountId
		,	transF.LoginName
		,	transO.SubscriberName
		,	transF.TransTime
		,	transO.CreatedDate
		,	transO.DeviceCode
		,	transO.FingerprintCode
		,	transO.FingerprintMoreInfo
		,	transF.UserAgentId
		,	transF.UserAgent
		,	transF.ClientIP AS IP
        ,	transF.FakeIP
		, 	transF.Flagged
		, 	transF.BrowserInfoId
		,	transO.IPID
		,	transO.PluginID
		,	transF.URL
		,	transF.Action
		,	transO.ActionResult
		,	transO.InvalidDevice
		,	transO.TransStatus
		,	transO.FPSTransID
		,	transO.IsProcessed
		,	transO.TransID
		,	transF.DeviceId
		,	transF.SubscriberId
		,	transF.CustId
		,	transF.SubAccId
		,	transO.LoginName
		,	transO.TransTime
		,	transO.IP
		,	transO.UserAgent
		,	transO.URL
		,	transO.Flagged
        ,	transF.TransKey
	FROM Temp_TransactionsFlagged AS transF
		INNER JOIN FPSTesting.FP_RawTransaction_Old AS transO ON transF.TransKey = transO.TransKey;
    
	INSERT IGNORE INTO FPSTesting.FP_RawTransaction(LoginName,	SubscriberName,	TransTime, CreatedDate,	DeviceCode,	FingerprintCode, FingerprintMoreInfo, UserAgent, IP, IPID, PluginID, URL, Action, ActionResult, InvalidDevice, TransStatus,	FPSTransID,	Flagged, FPDeviceID, SubscriberID, CustID,	CustSubID, LoginName_Old, TransTime_Old, IP_Old, UserAgent_Old, URL_Old, Flagged_Old, TransKey)
	SELECT	tmp.LoginName	
	   , 	tmp.SubscriberName
	   , 	tmp.TransTime
	   ,	DATE(tmp.TransTime)	
	   , 	tmp.DeviceCode
	   , 	tmp.FingerprintCode
	   , 	tmp.FingerprintMoreInfo
	   ,	tmp.UserAgent
	   , 	tmp.IP
	   , 	tmp.IPID
	   , 	tmp.PluginID
	   , 	tmp.URL
	   , 	tmp.Action
	   , 	tmp.ActionResult
	   , 	tmp.InvalidDevice
	   , 	tmp.TransStatus
	   , 	tmp.FPSTransID
	   , 	tmp.Flagged
	   , 	tmp.FPDeviceID
	   , 	tmp.SubscriberId
	   , 	tmp.CustId
	   , 	tmp.CustSubID
	   , 	tmp.LoginName_Old
	   , 	tmp.TransTime_Old
	   , 	tmp.IP_Old
	   , 	tmp.UserAgent_Old
	   , 	tmp.URL_Old
	   , 	tmp.Flagged_Old
	   ,	tmp.TransKey
	FROM Temp_Transactions2 AS tmp;
      
   INSERT IGNORE INTO FPS_FingerPrint.TransactionCompleted(Id, CustId, SubAccId, AccountId, LoginName, SubscriberId, RawFingerPrintId, BrowserInstanceId, CookieId, DeviceId, TransTime, ClientIP, FakeIP, BrowserInfoId, UserAgentId, Url, Action, CreatedDate, TransKey, Retry, RecoverType)
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
        ,	transF.FakeIP
		,	transF.BrowserInfoId
		,	transF.UserAgentId
		,	transF.Url
		,	transF.Action
		,	transF.CreatedDate
		,	transF.TransKey
        ,	transF.Retry
        ,	transF.RecoverType
	FROM  Temp_TransactionsFlagged AS transF 
		INNER JOIN Temp_Transactions2 AS tmp ON transF.Id = tmp.Id
    WHERE NOT EXISTS (SELECT 1 FROM FPS_FingerPrint.TransactionCompleted transC WHERE transC.Id = transF.Id AND transC.CreatedDate = transF.CreatedDate);
    
	DELETE transD FROM FPS_FingerPrint.TransactionDevice AS transD
		INNER JOIN Temp_Transactions2 AS tmp ON transD.Id = tmp.Id;
   
	DELETE tmp FROM Temp_TransactionsDevice AS tmp
		INNER JOIN Temp_Transactions2 AS tmp2 ON tmp.Id = tmp2.Id;
   
	UPDATE FPS_FingerPrint.TransactionDevice AS transD
		INNER JOIN Temp_TransactionsDevice AS transF ON transD.Id = transF.Id
	SET transD.Retry = transD.Retry + 1;

	INSERT IGNORE INTO FPSTesting.FP_RawTransaction_Old_Completed(LoginName, SubscriberName, TransTime, CreatedDate, DeviceCode, FingerprintCode, FingerprintMoreInfo, UserAgent, IP, FakeIP, IPID, PluginID, URL, Action, ActionResult, InvalidDevice, TransStatus, FPSTransID, Flagged, IsProcessed, TransID, TransKey)
	SELECT 	trans.LoginName
		, 	trans.SubscriberName
		, 	trans.TransTime
		, 	trans.CreatedDate
		, 	trans.DeviceCode
		, 	trans.FingerprintCode
		, 	trans.FingerprintMoreInfo
		, 	trans.UserAgent
		, 	trans.IP
        ,	trans.FakeIP
		, 	trans.IPID
		, 	trans.PluginID
		, 	trans.URL
		, 	trans.Action
		, 	trans.ActionResult
		, 	trans.InvalidDevice
		, 	trans.TransStatus
		, 	trans.FPSTransID
		, 	trans.Flagged
		, 	trans.IsProcessed
		, 	trans.TransID
		, 	trans.TransKey 
	FROM FPSTesting.FP_RawTransaction_Old AS trans 
		INNER JOIN Temp_Transactions2 AS tmp ON trans.TransID = tmp.Id_Old;
    
	DELETE trans 
    FROM FPSTesting.FP_RawTransaction_Old AS trans
		INNER JOIN Temp_Transactions2 AS tmp ON trans.TransID = tmp.Id_Old;       
    
    DROP TEMPORARY TABLE IF EXISTS Temp_Transactions; 
    DROP TEMPORARY TABLE IF EXISTS Temp_Transactions2; 
    DROP TEMPORARY TABLE IF EXISTS Temp_TransactionsDevice; 
    DROP TEMPORARY TABLE IF EXISTS Temp_TransactionsFlagged; 
        
END$$
DELIMITER ;

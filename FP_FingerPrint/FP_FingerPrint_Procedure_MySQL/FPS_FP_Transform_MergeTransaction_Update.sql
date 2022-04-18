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
    
    CREATE TEMPORARY TABLE Temp_Transactions(
				Id 				BIGINT	NOT NULL PRIMARY KEY	
			, 	TransKey 		VARCHAR(200)
            , 	INDEX IX_Temp_Transactions_TransKey(TransKey)            
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
		   ) AS  rt; 
    
    CREATE TEMPORARY TABLE Temp_TransactionsDevice(
			Id 				BIGINT 
		,	ServerTransId 	BIGINT
		,	CustId 			BIGINT 
		,	SubAccId 		BIGINT
		,	LoginName 		VARCHAR(100) 
		,	SubscriberId 	INT 
		,	FingerPrintCode VARCHAR(64) 
		,	CookieCode 		VARCHAR(64) 
		,	DeviceId 		BIGINT
		,	TransTime 		DATETIME(4) 
		,	ClientIP 		VARCHAR(45) 
		,	UserAgentId		BIGINT
		,	UserAgent 		VARCHAR(500) 
		,	Url 			VARCHAR(100) 
		,	Action 			VARCHAR(100) 
		,	CreatedDate 	DATETIME 
		,	TransKey 		VARCHAR(200) 
		,	Retry 			TINYINT 
		,	Flagged 		VARCHAR(50)
        , 	INDEX IX_Temp_Transactions_TransKey(TransKey)
    );
    
    INSERT INTO Temp_TransactionsDevice(Id, ServerTransId, CustId, SubAccId, LoginName, SubscriberId, FingerPrintCode, CookieCode, DeviceId, TransTime, ClientIP, UserAgentId, UserAgent, Url, Action, CreatedDate, TransKey, Retry, Flagged)
    SELECT  td.Id
    , td.ServerTransId
    , td.CustId
    , td.SubAccId
    , td.LoginName
    , td.SubscriberId
    , td.FingerPrintCode
    , td.CookieCode
    , td.DeviceId
    , td.TransTime
    , td.ClientIP
    , td.UserAgentId
    , td.UserAgent
    , td.Url
    , td.Action
    , td.CreatedDate
    , td.TransKey
    , td.Retry
    , td.Flagged
    FROM FPS_FingerPrint.TransactionDevice td
    INNER JOIN Temp_Transactions tmp ON td.Id = tmp.Id;
    
    CREATE TEMPORARY TABLE Temp_Transactions2(
			Id					BIGINT UNSIGNED
		,	Id_Old				BIGINT UNSIGNED
		,	LoginName 			VARCHAR(100) 
		,	SubscriberName 		VARCHAR(50) 
		,	TransTime 			TIMESTAMP(4) 
		,	CreatedDate 		DATETIME 
		,	DeviceCode 			VARCHAR(32) 
		,	FingerprintCode 	VARCHAR(620) 
		,	FingerprintMoreInfo VARCHAR(250) 
		,	UserAgentId			BIGINT 
		,	UserAgent 			VARCHAR(500) 
		,	IP 					VARCHAR(50) 
		,	IPID 				DECIMAL(50,0) 
		,	PluginID 			BIGINT 
		,	URL 				VARCHAR(500) 
		,	Action 				VARCHAR(100) 
		,	ActionResult 		VARCHAR(100) 
		,	InvalidDevice 		VARCHAR(1000) 
		,	TransStatus 		BIT(16) 
		,	FPSTransID 			BIGINT 
		,	Flagged 			SMALLINT 
		,	IsProcessed 		TINYINT 
		,	TransID 			BIGINT
		,	FPDeviceID 			BIGINT 
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
    );
    
    INSERT INTO Temp_Transactions2(Id, Id_Old, LoginName, SubscriberName, TransTime, CreatedDate, DeviceCode, FingerprintCode, FingerprintMoreInfo, UserAgentId, UserAgent, IP, IPID, PluginID, URL, Action, ActionResult, InvalidDevice, TransStatus, FPSTransID, Flagged, IsProcessed, TransID, FPDeviceID, SubscriberID, CustID, CustSubID, LoginName_Old, TransTime_Old, IP_Old, UserAgent_Old, URL_Old, Flagged_Old,TransKey)
	SELECT	transD.Id
		,	transO.TransID
		,	transD.LoginName 			
		,	transO.SubscriberName 		
		,	transD.TransTime 			
		,	transO.CreatedDate 		
		,	transO.DeviceCode 			
		,	transO.FingerprintCode 	
		,	transO.FingerprintMoreInfo 
		,	transD.UserAgentId 			
		,	transD.UserAgent 			
		,	transD.ClientIP 					
		,	transO.IPID 				
		,	transO.PluginID 			
		,	transD.URL 				
		,	transD.Action 				
		,	transO.ActionResult 		
		,	transO.InvalidDevice 		
		,	transO.TransStatus 		
		,	transO.FPSTransID 			
		, 	(CASE WHEN transD.Flagged = 'human' THEN 1
			WHEN transD.Flagged = 'bot' THEN 9 
            ELSE 6 END) AS Flagged			
		,	transO.IsProcessed 		
		,	transO.TransID 			
		,	transD.DeviceId 			
		,	transD.SubscriberId 		
		,	transD.CustId 				
		,	transD.SubAccId 			
		,	transO.LoginName 		
		,	transO.TransTime		
		,	transO.IP			
		,	transO.UserAgent		
		,	transO.URL		
		,	transO.Flagged
        ,	transD.TransKey
	FROM Temp_TransactionsDevice AS transD
	INNER JOIN FPSTesting.FP_RawTransaction_Old AS transO ON transD.TransKey = transO.TransKey;
    
    INSERT INTO FPSTesting.FP_RawTransaction(LoginName,	SubscriberName,	TransTime, CreatedDate,	DeviceCode,	FingerprintCode, FingerprintMoreInfo, UserAgent, IP, IPID, PluginID, URL, Action, ActionResult, InvalidDevice, TransStatus,	FPSTransID,	Flagged, FPDeviceID, SubscriberID, CustID,	CustSubID, LoginName_Old, TransTime_Old, IP_Old, UserAgent_Old, URL_Old, Flagged_Old, TransKey)
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
      
   INSERT INTO FPS_FingerPrint.TransactionCompleted(Id, ServerTransId, CustId, SubAccId, LoginName, SubscriberId, FingerPrintCode, CookieCode, DeviceId, TransTime, ClientIP, UserAgentId, UserAgent, Url, Action, CreatedDate, TransKey, Flagged, Retry)
   SELECT	transD.Id
		,	transD.ServerTransId
		,	transD.CustId
		,	transD.SubAccId
		,	transD.LoginName
		,	transD.SubscriberId
		,	transD.FingerPrintCode
		,	transD.CookieCode
		,	transD.DeviceId
		,	transD.TransTime
		,	transD.ClientIP
		,	transD.UserAgentId
		,	transD.UserAgent
		,	transD.Url
		,	transD.Action
		,	transD.CreatedDate
		,	transD.TransKey
		,	transD.Flagged
        ,	transD.Retry
	FROM  Temp_TransactionsDevice AS transD 
		INNER JOIN Temp_Transactions2 AS tmp ON transD.Id = tmp.Id;
   
	DELETE transD FROM FPS_FingerPrint.TransactionDevice AS transD
		INNER JOIN Temp_Transactions2 AS tmp ON transD.Id = tmp.Id;
   
	DELETE tmp FROM Temp_TransactionsDevice AS tmp
		INNER JOIN Temp_Transactions2 AS tmp2 ON tmp.Id = tmp2.Id;
   
	UPDATE FPS_FingerPrint.TransactionDevice AS transD
		INNER JOIN Temp_TransactionsDevice AS tmp ON transD.Id = tmp.Id
	SET transD.Retry = transD.Retry + 1;
      
	INSERT INTO FPSTesting.FP_RawTransaction_Old_Completed(LoginName, SubscriberName, TransTime, CreatedDate, DeviceCode, FingerprintCode, FingerprintMoreInfo, UserAgent, IP, IPID, PluginID, URL, Action, ActionResult, InvalidDevice, TransStatus, FPSTransID, Flagged, IsProcessed, TransID, TransKey)
	SELECT trans.LoginName
    , 	trans.SubscriberName
    , 	trans.TransTime
    , 	trans.CreatedDate
    , 	trans.DeviceCode
    , 	trans.FingerprintCode
    , 	trans.FingerprintMoreInfo
    , 	trans.UserAgent
    , 	trans.IP
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
   
	DELETE trans FROM FPSTesting.FP_RawTransaction_Old AS trans
	INNER JOIN Temp_Transactions2 AS tmp ON trans.TransID = tmp.Id_Old;       
    
    DROP TEMPORARY TABLE IF EXISTS Temp_Transactions; 
    DROP TEMPORARY TABLE IF EXISTS Temp_Transactions2; 
    DROP TEMPORARY TABLE IF EXISTS Temp_TransactionsDevice; 
        
END$$
DELIMITER ;

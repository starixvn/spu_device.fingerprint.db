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
		   ) AS rt; 
        
    CREATE TEMPORARY TABLE Temp_TransactionsDevice(
			Id 					BIGINT UNSIGNED
		,	ServerTransId 		BIGINT UNSIGNED
		,	CustId 				BIGINT UNSIGNED
		,	SubAccId 			BIGINT UNSIGNED
		,	LoginName 			VARCHAR(100) 
		,	SubscriberId 		INT 
		,	RawFingerPrintId 	BIGINT UNSIGNED
		,	CookieCode 			VARCHAR(64) 
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
		,	Flagged 			VARCHAR(50)
        , 	INDEX IX_Temp_TransactionsDevice_TransKey(TransKey)
    );
    
    INSERT INTO Temp_TransactionsDevice(Id, ServerTransId, CustId, SubAccId, LoginName, SubscriberId, RawFingerPrintId, CookieCode, DeviceId, TransTime, ClientIP, UserAgentId, UserAgent, Url, Action, CreatedDate, TransKey, Retry, Flagged)
		SELECT  td.Id
			, 	td.ServerTransId
			, 	td.CustId
			, 	td.SubAccId
			, 	td.LoginName
			, 	td.SubscriberId
			, 	td.RawFingerPrintId
			, 	td.CookieCode
			, 	td.DeviceId
			, 	td.TransTime
			, 	td.ClientIP
			, 	td.UserAgentId
			, 	td.UserAgent
			, 	td.Url
			, 	td.Action
			, 	td.CreatedDate
			, 	td.TransKey
			, 	td.Retry
			, 	td.Flagged
    FROM FPS_FingerPrint.TransactionDevice AS td
		INNER JOIN Temp_Transactions tmp ON td.Id = tmp.Id;
    
	INSERT INTO FPSTesting.FP_RawTransaction(LoginName,	SubscriberName,	TransTime, CreatedDate,	DeviceCode,	FingerprintCode, FingerprintMoreInfo, UserAgent, IP, IPID, PluginID, URL
		, Action, ActionResult, InvalidDevice, TransStatus,	FPSTransID,	Flagged, FPDeviceID, SubscriberID, CustID, CustSubID, LoginName_Old, TransTime_Old,	IP_Old,	UserAgent_Old, URL_Old,	Flagged_Old, TransKey)
	SELECT	transD.LoginName	
		, 	sub.Name
		, 	transD.TransTime
		,	DATE(transD.TransTime) AS CreatedDate	
		, 	NULL AS DeviceCode
		, 	NULL AS FingerprintCode
		, 	NULL AS FingerprintMoreInfo
		,	transD.UserAgent
		, 	transD.ClientIP
		, 	NULL AS IPID
		, 	NULL AS PluginID
		, 	transD.URL
		, 	transD.Action
		, 	NULL AS ActionResult
		, 	NULL AS InvalidDevice
		, 	0 AS TransStatus
		, 	NULL AS FPSTransID
		, 		(CASE WHEN transD.Flagged = 'human' THEN 1
					WHEN transD.Flagged = 'bot' THEN 9 
					ELSE 6 END) AS Flagged   
		, 	transD.DeviceId
		, 	sub.Id
		, 	transD.CustId
		, 	transD.SubAccId
		, 	NULL AS LoginName_Old
		, 	NULL AS TransTime_Old
		, 	NULL AS IP_Old
		, 	NULL AS UserAgent_Old
		, 	NULL AS URL_Old
		, 	NULL AS Flagged_Old
		,	transD.TransKey 
	FROM Temp_TransactionsDevice AS transD   
		INNER JOIN FPS_FingerPrint.Subscribers AS sub ON sub.Id = transD.SubscriberId;
    
	INSERT INTO FPS_FingerPrint.TransactionCompleted(Id, ServerTransId,	CustId,	SubAccId, LoginName, SubscriberId, RawFingerPrintId, CookieCode, DeviceId, TransTime, ClientIP, UserAgentId, UserAgent, Url, Action, CreatedDate,	TransKey, Flagged, Retry)
	SELECT	transD.Id	
		,	transD.ServerTransId
		,	transD.CustId
		,	transD.SubAccId
		,	transD.LoginName
		,	transD.SubscriberId
		,	transD.RawFingerPrintId
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
	FROM  Temp_TransactionsDevice AS transD;
    
	DELETE transD 
    FROM FPS_FingerPrint.TransactionDevice AS transD
		INNER JOIN Temp_TransactionsDevice AS tmp ON transD.Id = tmp.Id; 
    
END$$
DELIMITER ;

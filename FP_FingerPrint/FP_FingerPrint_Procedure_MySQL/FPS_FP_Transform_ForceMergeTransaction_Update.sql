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
    INSERT INTO FPS_FingerPrint.Test_LOG(SpName, JsonString, OtherText, InsertTime)
    SELECT 'FPS_FP_Transform_ForceMergeTransaction_Update', ip_TransJson , NULL, CURRENT_TIMESTAMP();
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
		,	UserAgent 		VARCHAR(500) 
		,	Url 			VARCHAR(100) 
		,	Action 			VARCHAR(100) 
		,	CreatedDate 	DATETIME 
		,	TransKey 		VARCHAR(200) 
		,	Retry 			TINYINT 
		,	Flagged 		VARCHAR(50)
        , 	INDEX IX_Temp_Transactions_TransKey(TransKey)
    );
    
    INSERT INTO Temp_TransactionsDevice(Id, ServerTransId, CustId, SubAccId, LoginName, SubscriberId, FingerPrintCode, CookieCode, DeviceId, TransTime, ClientIP, UserAgent, Url, Action, CreatedDate, TransKey, Retry, Flagged)
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
    , td.UserAgent
    , td.Url
    , td.Action
    , td.CreatedDate
    , td.TransKey
    , td.Retry
    , td.Flagged
    FROM FPS_FingerPrint.TransactionDevice td
    INNER JOIN Temp_Transactions tmp ON td.Id = tmp.Id;
    
   INSERT INTO FPSTesting.FP_RawTransaction(LoginName,	SubscriberName,	TransTime, CreatedDate,	DeviceCode,	FingerprintCode, FingerprintMoreInfo, UserAgent, IP, IPID, PluginID, URL, Action, ActionResult,	InvalidDevice, TransStatus,	FPSTransID,	Flagged, FPDeviceID, SubscriberID, CustID, CustSubID, LoginName_Old, TransTime_Old,	IP_Old,	UserAgent_Old, URL_Old,	Flagged_Old)
   SELECT transD.LoginName	
   , 	sub.Name
   , 	transD.TransTime
   ,	DATE(transD.TransTime)	
   , 	NULL
   , 	NULL
   , 	NULL
   ,	transD.UserAgent
   , 	transD.ClientIP
   , 	NULL
   , 	NULL
   , 	transD.URL
   , 	transD.Action
   , 	NULL
   , 	NULL
   , 	0
   , 	NULL
   , 		(CASE WHEN transD.Flagged = 'human' THEN 1
				WHEN transD.Flagged = 'bot' THEN 9 
                ELSE 6 END) AS Flagged   
   , 	transD.DeviceId
   , 	sub.Id
   , 	transD.CustId
   , 	transD.SubAccId
   , 	NULL
   , 	NULL
   , 	NULL
   , 	NULL
   , 	NULL
   , 	NULL
   FROM Temp_TransactionsDevice transD   
   INNER JOIN FPS_FingerPrint.Subscribers sub ON sub.Id = transD.SubscriberId;
    
   INSERT INTO FPS_FingerPrint.TransactionCompleted(Id, ServerTransId,	CustId,	SubAccId, LoginName, SubscriberId, FingerPrintCode,	CookieCode,	DeviceId, TransTime, ClientIP, UserAgent, Url, Action, CreatedDate,	TransKey, Flagged)
   SELECT transD.Id	
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
	,	transD.UserAgent
	,	transD.Url
	,	transD.Action
	,	transD.CreatedDate
	,	transD.TransKey
	,	transD.Flagged    
	FROM  Temp_TransactionsDevice transD;
    
	DELETE transD FROM FPS_FingerPrint.TransactionDevice transD
	INNER JOIN Temp_TransactionsDevice tmp ON transD.Id = tmp.Id; 
 
    DROP TEMPORARY TABLE IF EXISTS Temp_Transactions; 
    DROP TEMPORARY TABLE IF EXISTS Temp_TransactionsDevice; 
    
END$$
DELIMITER ;

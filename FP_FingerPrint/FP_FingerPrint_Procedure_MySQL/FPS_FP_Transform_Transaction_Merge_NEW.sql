/*<info serverAlias="xxxx" databaseType="2" executers="fpsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `FPS_FP_Transform_Transaction_Merge_NEW`;
DELIMITER $$

CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `FPS_FP_Transform_Transaction_Merge_NEW`(
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
            
		Param's Explanation (filtered by):	

		Example:
			- CALL FPS_FP_Transform_Transaction_Merge_NEW('[{}]');
			
	*/
    DROP TEMPORARY TABLE IF EXISTS Temp_Transactions;    
    CREATE TEMPORARY TABLE Temp_Transactions(
				Id 				BIGINT	NOT NULL PRIMARY KEY		
			, 	RawTransId 		BIGINT
			, 	CustId 			BIGINT 
            ,	SubAccId		BIGINT
			, 	LoginName 		VARCHAR(100) 
			, 	SubscriberId 	INT 
			, 	DeviceId 		BIGINT 
			, 	Transtime 		DATETIME 
			, 	ClientIP 		VARCHAR(45) 
			, 	UserAgent 		VARCHAR(500) 
			, 	Url 			VARCHAR(100)
			, 	Flagged			SMALLINT
			, 	TransKey 		VARCHAR(200) 
			, 	CanMerged 		TINYINT DEFAULT 0  
            , INDEX IX_Temp_Transactions_TransKey(TransKey, CanMerged)
            , INDEX IX_Temp_Transactions_CanMerged(CanMerged)
    );
    
    INSERT INTO Temp_Transactions(
		Id
        , RawTransId
        , CustId
        , SubAccId
        , LoginName
        , SubscriberId       
        , Transtime
        , ClientIP
        , UserAgent
        , Url
        , Flagged
        , TransKey)
	SELECT	tmp.Id
		,	tmp.RawTransId
		,	tmp.CustId
		,	tmp.SubAccId
        ,	tmp.LoginName
        ,	tmp.SubscriberId
        ,	tmp.Transtime
        ,	tmp.ClientIP
        ,	tmp.UserAgent
        ,	tmp.Url
        ,	tmp.Flagged
        ,	tmp.TransKey
	FROM	JSON_TABLE(
			ip_Transaction,
			 "$[*]" COLUMNS(
					Id					BIGINT			PATH "$.Id"       
				,	RawTransId			BIGINT 			PATH "$.RawTransId"   
				,	CustId				BIGINT 			PATH "$.CustId"
				,	SubAccId			BIGINT			PATH "$.SubAccId"
				,	LoginName			VARCHAR(100)	PATH "$.LoginName"
				,	SubscriberId		INT				PATH "$.SubscriberId"
				,	Transtime			DATETIME 		PATH "$.Transtime"
				,	ClientIP			VARCHAR(45) 	PATH "$.ClientIP"
				,	UserAgent			VARCHAR(500) 	PATH "$.UserAgent"
				,	Url					VARCHAR(100)	PATH "$.Url"
				,	Flagged				VARCHAR(50)		PATH "$.Flagged"
                ,	TransKey			VARCHAR(200)	PATH "$.TransKey"
				)
		   ) AS  tmp; 
    
    UPDATE Temp_Transactions tmp 
		INNER JOIN FPS_FingerPrint.TransactionCompleted trans ON tmp.Id = trans.Id
        INNER JOIN FPTesting.FP_RawTransaction_Old transOld ON tmp.TransKey = transOld.TransKey
    SET tmp.DeviceId = trans.DeviceId,
		tmp.CanMerged = 1;
     
    INSERT INTO FPTesting.FP_RawTransaction(
		LoginName
    , 	SubscriberName
    , 	TransTime
    , 	CreatedDate
    , 	DeviceCode
    , 	FingerprintCode
    , 	FingerprintMoreInfo
    , 	UserAgent
    , 	IP
    , 	IPID
    , 	PluginID
    , 	URL
    , 	Action
    , 	ActionResult
    , 	InvalidDevice
    , 	TransStatus
    , 	FPSTransID
    , 	Flagged    
    , 	FPDeviceID
    , 	SubscriberID
    , 	CustID
    ,	CustSubID
    , 	LoginName_Old
    , 	TransTime_Old
    , 	IP_Old
    , 	UserAgent_Old
    , 	URL_Old
    , 	Flagged_Old)
   SELECT 
    (CASE WHEN transNew.LoginName is null THEN transOld.LoginName			
			ELSE transNew.LoginName END)	
   , transOld.SubscriberName
   , (CASE WHEN transNew.TransTime is null THEN transOld.TransTime			
			ELSE transNew.TransTime END)
   , (CASE WHEN transNew.TransTime is null THEN DATE(transOld.TransTime)		
			ELSE DATE(transNew.TransTime) END)
   , transOld.DeviceCode
   , transOld.FingerprintCode
   , transOld.FingerprintMoreInfo
   ,(CASE WHEN transNew.UserAgent is null THEN transOld.UserAgent		
			ELSE transNew.UserAgent END)
   , transNew.ClientIP
   , transOld.IPID
   , transOld.PluginID
   , (CASE WHEN transNew.URL is null THEN transOld.URL		
			ELSE transNew.URL END)
   , transOld.Action
   , transOld.ActionResult
   , transOld.InvalidDevice
   , transOld.TransStatus
   , transOld.FPSTransID   
   , (CASE WHEN transNew.Flagged = 'human' THEN 1
			WHEN transNew.Flagged = 'bot' THEN 2
			ELSE 0 END)   
   , transNew.DeviceId
   , transNew.SubscriberId
   , transNew.CustId
   , transNew.SubAccId
   , transOld.LoginName
   , transOld.TransTime
   , transOld.IP
   , transOld.UserAgent
   , transOld.URL
   , transOld.Flagged
   FROM Temp_Transactions transNew
   INNER JOIN FPTesting.FP_RawTransaction_Old transOld ON transNew.TransKey = transOld.TransKey
   WHERE transNew.CanMerged = 1;
   
   UPDATE FPS_FingerPrint.TransactionCompleted trans 
		INNER JOIN Temp_Transactions tmp ON trans.Id = tmp.Id
   SET trans.IsMerged = 1
   WHERE tmp.CanMerged = 1;
   
   INSERT INTO FPTesting.FP_RawTransaction_Old_Completed(LoginName, SubscriberName, TransTime, CreatedDate, DeviceCode, FingerprintCode, FingerprintMoreInfo, UserAgent, IP, IPID, PluginID, URL, Action, ActionResult, InvalidDevice, TransStatus, FPSTransID, Flagged, IsProcessed, TransID, TransKey)
   SELECT trans.LoginName, trans.SubscriberName, trans.TransTime, trans.CreatedDate, trans.DeviceCode, trans.FingerprintCode, trans.FingerprintMoreInfo, trans.UserAgent, trans.IP, trans.IPID, trans.PluginID, trans.URL, trans.Action, trans.ActionResult, trans.InvalidDevice, trans.TransStatus, trans.FPSTransID, trans.Flagged, trans.IsProcessed, trans.TransID, trans.TransKey 
		FROM FPTesting.FP_RawTransaction_Old trans 
		INNER JOIN Temp_Transactions tmp ON trans.TransKey = tmp.TransKey
	WHERE tmp.CanMerged = 1;
   
   DELETE trans FROM FPTesting.FP_RawTransaction_Old trans
		INNER JOIN Temp_Transactions tmp ON trans.TransKey = tmp.TransKey
	WHERE tmp.CanMerged = 1;       
    
END$$
DELIMITER ;

GRANT EXECUTE ON PROCEDURE FPS_FingerPrint.FPS_FP_Transform_Transaction_Merge_NEW TO 'fpsServiceAdmin'@'%';
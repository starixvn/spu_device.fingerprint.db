/*<info serverAlias="xxxx" databaseType="2" executers="fpsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `FPS_FP_Transform_Transaction_ForceMerge`;
DELIMITER $$

CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `FPS_FP_Transform_Transaction_ForceMerge`(
		ip_TransTime 	DateTime,
        ip_Interval		INT,
        ip_OffsetName	VARCHAR(100)
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
			- CALL FPS_FP_Transform_Transaction_ForceMerge();
			
	*/        
    
    DROP TEMPORARY TABLE IF EXISTS Temp_RawTransactions;   
    DROP TEMPORARY TABLE IF EXISTS Temp_Transactions_Old;   
    
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
            , INDEX IX_Temp_Transactions_TransTime(TransTime)
    );
    
    CREATE TEMPORARY TABLE Temp_RawTransactions_Old(				
				LoginName			VARCHAR(100)
            ,	SubscriberName		VARCHAR(50)
            ,	TransTime			TIMESTAMP(4)
			,	CreatedDate			DATETIME
            ,	DeviceCode			VARCHAR(32)
            ,	FingerprintCode		VARCHAR(620)
            ,	FingerprintMoreInfo	VARCHAR(250)
            ,	UserAgent			VARCHAR(1000)
            ,	IP					VARCHAR(50)
            ,	IPID				DECIMAL(50,0)
            ,	PluginID			BIGINT
            ,	URL					VARCHAR(500)
            ,	Action				VARCHAR(100)
            ,	ActionResult		VARCHAR(100)
            ,	InvalidDevice		VARCHAR(1000)
            ,	TransStatus			BIT(16)
            ,	FPSTransID			BIGINT
            ,	Flagged				SMALLINT
            ,	IsProcessed			TINYINT
            ,	TransID				BIGINT NOT NULL PRIMARY KEY
            ,	TransKey			VARCHAR(32)   
			, INDEX IX_Temp_RawTransactions_Old_TransKey(TransKey)
            , INDEX IX_Temp_RawTransactions_Old_TransTime(TransTime)
    );
    
    SET @lv_TransTime = DATE_ADD(ip_TransTime, INTERVAL ip_Interval MINUTE);
    
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
	SELECT trans.Id, trans.RawTransId, trans.CustId, trans.SubAccId, trans.LoginName, trans.SubscriberId, trans.Transtime, trans.ClientIP, trans.UserAgent, trans.Url, trans.Flagged, trans.TransKey
    FROM FPS_FingerPrint.TransactionCompleted trans 
    WHERE trans.Transtime BETWEEN ip_TransTime AND @lv_TransTime;
    
    INSERT INTO Temp_RawTransactions_Old(
    LoginName
    , SubscriberName
    , TransTime
    , CreatedDate
    , DeviceCode
    , FingerprintCode
    , FingerprintMoreInfo
    , UserAgent
    , IP
    , IPID
    , PluginID
    , URL
    , Action
    , ActionResult
    , InvalidDevice
    , TransStatus
    , FPSTransID
    , Flagged
    , IsProcessed
    , TransID
    , TransKey)
    SELECT trans.LoginName, trans.SubscriberName, trans.TransTime, trans.CreatedDate, trans.DeviceCode, trans.FingerprintCode, trans.FingerprintMoreInfo, trans.UserAgent, trans.IP, trans.IPID, trans.PluginID, trans.URL, trans.Action, trans.ActionResult, trans.InvalidDevice, trans.TransStatus, trans.FPSTransID, trans.Flagged, trans.IsProcessed, trans.TransID, trans.TransKey
    FROM FPTesting.FP_RawTransaction_Old trans 
	WHERE trans.Transtime BETWEEN ip_TransTime AND @lv_TransTime;
    
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
   (SELECT 
    (CASE WHEN transNew.LoginName is null THEN rawOld.LoginName			
			ELSE transNew.LoginName END)	
   , rawOld.SubscriberName
   , (CASE WHEN transNew.TransTime is null THEN rawOld.TransTime			
			ELSE transNew.TransTime END)
   , (CASE WHEN transNew.TransTime is null THEN DATE(rawOld.TransTime)		
			ELSE DATE(transNew.TransTime) END)
   , rawOld.DeviceCode
   , rawOld.FingerprintCode
   , rawOld.FingerprintMoreInfo
   ,(CASE WHEN transNew.UserAgent is null THEN rawOld.UserAgent		
			ELSE transNew.UserAgent END)
   , transNew.ClientIP
   , rawOld.IPID
   , rawOld.PluginID
   , (CASE WHEN transNew.URL is null THEN rawOld.URL		
			ELSE transNew.URL END)
   , rawOld.Action
   , rawOld.ActionResult
   , rawOld.InvalidDevice
   , rawOld.TransStatus
   , rawOld.FPSTransID   
   , (CASE WHEN transNew.Flagged = 'human' THEN 1
			WHEN transNew.Flagged = 'bot' THEN 2
			ELSE 0 END)   
   , transNew.DeviceId
   , transNew.SubscriberId
   , transNew.CustId
   , transNew.SubAccId
   , rawOld.LoginName
   , rawOld.TransTime
   , rawOld.IP
   , rawOld.UserAgent
   , rawOld.URL
   , rawOld.Flagged
   FROM Temp_Transactions transNew
   LEFT OUTER JOIN Temp_RawTransactions_Old transOld ON transNew.TransKey = transOld.TransKey
   UNION
   SELECT 
    rawOld.LoginName
   , rawOld.SubscriberName
   , rawOld.TransTime
   , DATE(rawOld.TransTime)
   , rawOld.DeviceCode
   , rawOld.FingerprintCode
   , rawOld.FingerprintMoreInfo
   , rawOld.UserAgent
   , rawOld.IP
   , rawOld.IPID
   , rawOld.PluginID
   , rawOld.URL
   , rawOld.Action
   , rawOld.ActionResult
   , rawOld.InvalidDevice
   , rawOld.TransStatus
   , rawOld.FPSTransID   
   , rawOld.Flagged   
   , NULL
   , NULL
   , NULL
   , NULL
   , rawOld.LoginName
   , rawOld.TransTime
   , rawOld.IP
   , rawOld.UserAgent
   , rawOld.URL
   , rawOld.Flagged
   FROM Temp_Transactions transNew
   RIGHT OUTER JOIN Temp_RawTransactions_Old transOld ON transNew.TransKey = transOld.TransKey
   WHERE transNew.TransKey IS NULL);
   
   UPDATE FPS_FingerPrint.TransactionCompleted trans 
		INNER JOIN Temp_Transactions tmp ON trans.Id = tmp.Id
   SET trans.IsMerged = 1;
   
   INSERT INTO FP_RawTransaction_Old_Completed(LoginName, SubscriberName, TransTime, CreatedDate, DeviceCode, FingerprintCode, FingerprintMoreInfo, UserAgent, IP, IPID, PluginID, URL, Action, ActionResult, InvalidDevice, TransStatus, FPSTransID, Flagged, IsProcessed, TransID, TransKey)
   SELECT trans.LoginName, trans.SubscriberName, trans.TransTime, trans.CreatedDate, trans.DeviceCode, trans.FingerprintCode, trans.FingerprintMoreInfo, trans.UserAgent, trans.IP, trans.IPID, trans.PluginID, trans.URL, trans.Action, trans.ActionResult, trans.InvalidDevice, trans.TransStatus, trans.FPSTransID, trans.Flagged, trans.IsProcessed, trans.TransID, trans.TransKey 
		FROM Temp_Transactions_Old trans;
   
   DELETE trans FROM FPTesting.FP_RawTransaction_Old trans
		INNER JOIN Temp_Transactions_Old tmp ON trans.TransID = tmp.TransID;       
    
   UPDATE  FPS_FingerPrint.Offset 
   SET OffsetValue = @lv_TransTime 
   WHERE OffsetName = ip_OffsetName;
END$$
DELIMITER ;

GRANT EXECUTE ON PROCEDURE FPS_FingerPrint.FPS_FP_Transform_Transaction_ForceMerge TO 'fpsServiceAdmin'@'%';
/*<info serverAlias="xxxx" databaseType="2" executers="fpsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `FPS_FP_Transform_Transaction_Merge`;
DELIMITER $$

CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `FPS_FP_Transform_Transaction_Merge`(
		ip_Size INT
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
			- CALL FPS_FP_Transform_Transaction_Merge_New(100);
			
	*/
    DROP TEMPORARY TABLE IF EXISTS Temp_RawTransactions;
    DROP TEMPORARY TABLE IF EXISTS Temp_RawTransactions_Old;
    
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
            ,	TransID				BIGINT
            ,	TransKey			VARCHAR(32)            
    );
    
    INSERT INTO Temp_RawTransactions_Old(LoginName, SubscriberName, TransTime, CreatedDate, DeviceCode, FingerprintCode, FingerprintMoreInfo, UserAgent, IP, IPID, PluginID, URL, Action, ActionResult, InvalidDevice, TransStatus, FPSTransID, Flagged, IsProcessed, TransID, TransKey)
    SELECT rawOld.LoginName, rawOld.SubscriberName, rawOld.TransTime, rawOld.CreatedDate, rawOld.DeviceCode, rawOld.FingerprintCode, rawOld.FingerprintMoreInfo, rawOld.UserAgent, rawOld.IP, rawOld.IPID, rawOld.PluginID, rawOld.URL, rawOld.Action, rawOld.ActionResult, rawOld.InvalidDevice, rawOld.TransStatus, rawOld.FPSTransID, rawOld.Flagged, rawOld.IsProcessed, rawOld.TransID, rawOld.TransKey
    FROM FPTesting.FP_RawTransaction_Old rawOld 
    WHERE rawOld.IsProcessed = 0 
    LIMIT ip_Size;
    
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
    , 	LoginName_Old
    , 	TransTime_Old
    , 	IP_Old
    , 	UserAgent_Old
    , 	URL_Old
    , 	Flagged_Old)
   SELECT 
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
   , rawOld.LoginName
   , rawOld.TransTime
   , rawOld.IP
   , rawOld.UserAgent
   , rawOld.URL
   , rawOld.Flagged
   FROM Temp_RawTransactions_Old rawOld 
   LEFT JOIN FPS_FingerPrint.TransactionCompleted transNew ON rawOld.TransKey = transNew.TransKey;
   
   UPDATE  FPS_FingerPrint.TransactionCompleted transNew INNER JOIN Temp_RawTransactions_Old rawOld ON rawOld.TransKey = transNew.TransKey
   SET transNew.IsMerged = 1;
   
   UPDATE FPTesting.FP_RawTransaction_Old rawOld INNER JOIN Temp_RawTransactions_Old tmp ON rawOld.TransID = tmp.TransID
   SET rawOld.IsProcessed = 1;    
   
END$$
DELIMITER ;

GRANT EXECUTE ON PROCEDURE FPS_FingerPrint.FPS_FP_Transform_Transaction_Merge TO 'fpsServiceAdmin'@'%';
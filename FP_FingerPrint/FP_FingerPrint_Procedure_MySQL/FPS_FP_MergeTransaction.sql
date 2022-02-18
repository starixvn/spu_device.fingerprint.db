/*<info serverAlias="xxxx" databaseType="2" executers="fpsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `FPS_FP_MergeTransaction`;
DELIMITER $$

CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `FPS_FP_MergeTransaction`(
		ip_Size INT
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20220218@Terry.Nguyen
		Task :		
		DB:			FPS_FingerPrint
		Original:

		Revisions:
            
		Param's Explanation (filtered by):	

		Example:
			- CALL FPS_FP_MergeTransaction(100);
			
	*/
    DROP TEMPORARY TABLE IF EXISTS Temp_Transactions;
    DROP TEMPORARY TABLE IF EXISTS Temp_Transactions_Old;
    
	CREATE TEMPORARY TABLE Temp_Transactions(
				Id 				BIGINT			
			, 	CustId 			BIGINT 
            ,	SubAccId		BIGINT
			, 	LoginName 		VARCHAR(100) 
			, 	SubscriberId 	INT 
			, 	FingerPrintCode VARCHAR(200) 			
			, 	DeviceId 		BIGINT 
			, 	Transtime 		DATETIME 
			, 	ClientIP 		VARCHAR(45) 
			, 	UserAgent 		VARCHAR(500) 
			, 	Url 			VARCHAR(100)
			, 	Flagged			SMALLINT
			, 	TransKey 		VARCHAR(200) 
			, 	IsMerged 		TINYINT
    );
    
    CREATE TEMPORARY TABLE Temp_Transactions_Old(
				LoginName varchar(100) 
				, SubscriberName varchar(50) 
				, TransTime timestamp(4) 
				, CreatedDate datetime 
				, DeviceCode varchar(32) 
				, FingerprintCode varchar(620) 
				, FingerprintMoreInfo varchar(250) 
				, UserAgent varchar(1000) 
				, IP varchar(50) 
				, IPID decimal(50,0) 
				, PluginID bigint 
				, URL varchar(500) 
				, Action varchar(100) 
				, ActionResult varchar(100) 
				, InvalidDevice varchar(1000) 
				, TransStatus bit(16) 
				, FPSTransID bigint 
				, Flagged smallint 
				, IsProcessed tinyint 
				, TransID bigint 
				, FPDeviceID bigint 
				, SubscriberID int 
				, CustID int
                , CustSubID int
				, LoginName_Old varchar(100) 
				, TransTime_Old timestamp(4) 
				, IP_Old varchar(50) 
				, UserAgent_Old varchar(1000) 
				, URL_Old varchar(500) 
				, Flagged_Old smallint
    );
        
    
   INSERT INTO  Temp_Transactions
   SELECT trans.Id
   , trans.CustId
   , trans.SubAccId
   , trans.LoginName
   , trans.SubscriberId
   , trans.FingerPrintCode
   , trans.DeviceId
   , trans.Transtime
   , trans.ClientIP
   , trans.UserAgent
   , trans.Url
   , (CASE WHEN trans.Flagged = 'human' THEN 1
			WHEN trans.Flagged = 'bot' THEN 2
			ELSE 0 END)			
   , trans.TransKey
   , trans.IsMerged
   FROM FPS_FingerPrint.Transaction trans WHERE trans.DeviceId Is Not NULL AND trans.IsMerged = 0 AND trans.TransKey Is not Null
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
	transNew.LoginName
   , transOld.SubscriberName
   , transNew.TransTime
   , DATE(transNew.TransTime)
   , transOld.DeviceCode
   , transOld.FingerprintCode
   , transOld.FingerprintMoreInfo
   , transNew.UserAgent
   , transNew.ClientIP
   , transOld.IPID
   , transOld.PluginID
   , transNew.URL
   , transOld.Action
   , transOld.ActionResult
   , transOld.InvalidDevice
   , transOld.TransStatus
   , transOld.FPSTransID
   , transNew.Flagged
   , transNew.DeviceID
   , transNew.SubscriberId
   , transNew.CustId
   , transOld.LoginName
   , transOld.TransTime
   , transOld.IP
   , transOld.UserAgent
   , transOld.URL
   , transOld.Flagged
   FROM FPTesting.FP_RawTransaction_Old transOld 
   INNER JOIN Temp_Transactions transNew ON transOld.TransKey = transNew.TransKey
   WHERE transOld.IsProcessed != 1;  
   
   UPDATE FPTesting.FP_RawTransaction_Old transOld
   INNER JOIN Temp_Transactions tmp ON transOld.TransKey = tmp.TransKey
   SET transOld.IsProcessed = 1;   	
   
   #========================================
    INSERT INTO Temp_Transactions_Old(
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
    ,	TransID 
    ,	FPDeviceID
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
	transOld.LoginName
   , transOld.SubscriberName
   , transOld.TransTime
   , DATE(transOld.TransTime)
   , transOld.DeviceCode
   , transOld.FingerprintCode
   , transOld.FingerprintMoreInfo
   , transOld.UserAgent
   , transOld.IP
   , transOld.IPID
   , transOld.PluginID
   , transOld.URL
   , transOld.Action
   , transOld.ActionResult
   , transOld.InvalidDevice
   , transOld.TransStatus
   , transOld.FPSTransID
   , transOld.Flagged
   , transOld.TransID   
   , 0 # fpdeviceId  
   , 0 # subcriberId
   , 0 # custId
   , 0 # custSubId
   , transOld.LoginName
   , transOld.TransTime
   , transOld.IP
   , transOld.UserAgent
   , transOld.URL
   , transOld.Flagged
   FROM FPTesting.FP_RawTransaction_Old transOld 
   LEFT JOIN Temp_Transactions transNew ON transOld.TransKey = transNew.TransKey
   WHERE transOld.IsProcessed != 1
   LIMIT ip_Size;  
   
   select * from Temp_Transactions_Old;
   
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
	,	FPDeviceID	
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
	transOld.LoginName
   , transOld.SubscriberName
   , transOld.TransTime
   , DATE(transOld.TransTime)
   , transOld.DeviceCode
   , transOld.FingerprintCode
   , transOld.FingerprintMoreInfo
   , transOld.UserAgent
   , transOld.IP
   , transOld.IPID
   , transOld.PluginID
   , transOld.URL
   , transOld.Action
   , transOld.ActionResult
   , transOld.InvalidDevice
   , transOld.TransStatus
   , transOld.FPSTransID  
   , transOld.Flagged  
   , transOld.FPDeviceID
   , transOld.SubscriberID
   , transOld.CustID
   , transOld.CustSubID
   , transOld.LoginName_Old
   , transOld.TransTime
   , transOld.IP
   , transOld.UserAgent
   , transOld.URL
   , transOld.Flagged_Old
   FROM Temp_Transactions_Old transOld;
   
   UPDATE FPTesting.FP_RawTransaction_Old transOld
   INNER JOIN Temp_Transactions_Old tmp ON transOld.TransID = tmp.TransID
   SET transOld.IsProcessed = 1;   
      
   UPDATE FPS_FingerPrint.Transaction trans 
   INNER JOIN Temp_Transactions tmp ON trans.Id = tmp.Id
   SET trans.IsMerged = 1;
END$$
DELIMITER ;

GRANT EXECUTE ON PROCEDURE FPS_FingerPrint.FPS_FP_MergeTransaction TO 'fpsServiceAdmin'@'%';
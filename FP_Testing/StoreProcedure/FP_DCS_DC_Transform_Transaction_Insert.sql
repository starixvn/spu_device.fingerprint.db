/*<info serverAlias="FPSDC-FPSTesting" databaseType="2" executers="fpsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `FP_DCS_DC_Transform_Transaction_Insert`;

DELIMITER $$
CREATE DEFINER=`fpsOwner`@`%` PROCEDURE `FP_DCS_DC_Transform_Transaction_Insert`(
        IN ip_FromTransID   BIGINT UNSIGNED
    ,   IN ip_ToTransID     BIGINT UNSIGNED
)
    SQL SECURITY INVOKER
BEGIN
    /*
	    Created: 20190730@Casey.Huynh
	    Task : Insert Transaction
	    DB: FPSTesting
	    Original:

	    Revisions:
		    - 20220106@CaseyHuynh: Created [RedmineID: #166727]
            
	    Param's Explanation (filtered by):
		
        Example:
			CALL FP_DCS_DC_Transform_Transaction_Insert(1,200);
            SELECT * FROM FP_Account;
            SELECT * FROM FP_Transaction;
    */
	DECLARE		lv_SysMinCreatedDate	DATETIME;
    
	/*******LOG TEST********************/
    INSERT INTO FPS_FingerPrint.Test_LOG(SpName, JsonString, OtherText, InsertTime)
    SELECT 'FP_DCS_DC_Transform_Transaction_Insert', NULL,CONCAT('ip_FromTransID:',ip_FromTransID,'; ip_ToTransID:',ip_ToTransID), CURRENT_TIMESTAMP();
    /*******LOG TEST********************/

    DROP TEMPORARY TABLE IF EXISTS Temp_RawTransaction;
	CREATE TEMPORARY TABLE IF NOT EXISTS Temp_RawTransaction (
		    TransID					BIGINT UNSIGNED NOT NULL
		,   LoginName				VARCHAR(100)  CHARACTER SET 'UTF8MB4' COLLATE 'UTF8MB4_UNICODE_CI' NOT NULL
		,   TransTime				TIMESTAMP(4) NOT NULL
        ,   AccountID				BIGINT	UNSIGNED 	
        ,   SubscriberType		    TINYINT	UNSIGNED	
        ,   URLDetails			    VARCHAR(250)		
		,   URLID					INT					
		,   DeviceCode			    VARCHAR(32) COMMENT 'Trans Device Code'
        ,   UserAgentKey			VARCHAR(32)			
		,   IP					    VARCHAR(50) 		
        ,   IPID					DECIMAL(50,0)			
		,   ActionResultID		    INT					
		,   Flagged				    SMALLINT COMMENT 'captcha & browserless'
		,   PluginID				BIGINT 				
		,   TransStatus			    BIT(16) 			
		,   CreatedDate			    DATETIME COMMENT 'Date Only' 
		,   InsertTime			    TIMESTAMP(4) 		
        ,   FingerprintCode		    VARCHAR(620)
        ,	FPDeviceID				BIGINT UNSIGNED
        ,   SubscriberID			INT
        ,	CustID					INT
        ,	CustSubID				INT
        ,	LoginName_Old			VARCHAR(100)  CHARACTER SET 'UTF8MB4' COLLATE 'UTF8MB4_UNICODE_CI' 
        ,	TransTime_Old			DATETIME(3)
        ,	IP_Old					VARCHAR(50)
        ,	UserAgent_Old			VARCHAR(1000)
        ,	URL_Old					VARCHAR(500)
        ,	Flagged_Old				SMALLINT
	);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_RawTransactionInfo;
	CREATE TEMPORARY TABLE  Temp_RawTransactionInfo(
		    TransID		    BIGINT UNSIGNED NOT NULL
		,   URLID			INT 
        ,   AccountID		BIGINT	UNSIGNED
        ,   INDEX           IX_Temp_RawTransactionInfo_TransID(TransID)
    );

    DROP TEMPORARY TABLE IF EXISTS Temp_Account;
	CREATE TEMPORARY TABLE  Temp_Account(
		    LoginName				VARCHAR(100) CHARACTER SET 'UTF8MB4' COLLATE 'UTF8MB4_UNICODE_CI' NOT NULL
		,   SubscriberID			INT 
        ,   SubscriberType		    TINYINT	UNSIGNED	
    );
    /*
	DROP TEMPORARY TABLE IF EXISTS Temp_LastLoginTime;
    CREATE TEMPORARY TABLE Temp_LastLoginTime(
		    SubscriberID	INT
        ,   AccountID		BIGINT UNSIGNED
        ,   LastLoginTime	TIMESTAMP(4)
    );
    
   
    DROP TEMPORARY TABLE IF EXISTS Temp_LastLoginTimeCTSCust;
    CREATE TEMPORARY TABLE Temp_LastLoginTimeCTSCust(
		    CTSCustID		BIGINT UNSIGNED
        ,   LastLoginTime	TIMESTAMP(4)
    );
    */
   
    SELECT DATE(VValue)
    INTO lv_SysMinCreatedDate
    FROM FPSTesting.FP_SystemSetting 
   # WHERE VGroup = "DCS_Device_Transform" AND VName = "MinCreatedDate";
	WHERE Id = 2;
    
	INSERT INTO Temp_RawTransaction(TransID, LoginName, TransTime, SubscriberType, DeviceCode , URLDetails, UserAgentKey, IP, IPID, ActionResultID, Flagged, PluginID, TransStatus, CreatedDate, FingerprintCode, FPDeviceID, SubscriberID,CustID, CustSubID, LoginName_Old, TransTime_Old, IP_Old,UserAgent_Old, URL_Old,Flagged_Old)
	SELECT  rt.TransID
	    ,   rt.LoginName
        ,   rt.TransTime
        ,   su.SubscriberType        
        ,   rt.DeviceCode
        ,   rt.URL
        ,   MD5(LOWER(rt.UserAgent))
        ,   rt.IP
        ,   rt.IPID
        ,   ar.ActionResultID
        ,   rt.Flagged
        ,   rt.PluginID
        ,   rt.TransStatus
        ,   rt.CreatedDate
        ,   rt.FingerprintCode
        ,	rt.FPDeviceID
        , 	rt.SubscriberID
        ,	rt.CustID
        , 	rt.CustSubID
        , 	rt.LoginName_Old
        , 	rt.TransTime_Old
        , 	rt.IP_Old
        ,	rt.UserAgent_Old
        , 	rt.URL_Old
        ,	rt.Flagged_Old
	FROM		FPSTesting.FP_RawTransaction AS rt
        INNER JOIN	CTS_Admin.Subscriber AS su ON	rt.SubscriberName = su.SubscriberName
	    LEFT JOIN	FPSTesting.FP_ActionResult AS ar ON	rt.Action = ar.Action AND IFNULL(rt.ActionResult,'') = ar.ActionResult
	WHERE   rt.IsProcessed = 0
	    AND rt.TransID BETWEEN ip_FromTransID AND ip_ToTransID
        AND rt.CreatedDate 	>=	lv_SysMinCreatedDate;

    #===INSERT SUBCRIBERURL    
    INSERT IGNORE INTO FPSTesting.FP_URL(URLDetails, SubscriberID, CreatedDate)
	SELECT	trt.URLDetails
        ,   trt.SubscriberID
        ,   MIN(trt.CreatedDate)
	FROM Temp_RawTransaction AS trt
	GROUP BY trt.SubscriberID
        ,    trt.URLDetails;    
    
	# Insert New Account
    INSERT IGNORE INTO FPSTesting.FP_Account(LoginName, SubscriberID, SubscriberType, CreatedDate, InsertTime, CreatedTime, LastLoginTime)
    SELECT  trt.LoginName
	    ,   trt.SubscriberID
	    ,   trt.SubscriberType
	    ,   MIN(trt.CreatedDate)
	    ,   CURRENT_TIMESTAMP(4) AS InsertTime
        ,   MIN(trt.TransTime) AS CreatedTime
        ,   MAX(trt.TransTime) AS LastLoginTime
    FROM Temp_RawTransaction AS trt
    WHERE NOT EXISTS (SELECT 1 FROM FPSTesting.FP_Account AS acc  where trt.LoginName = acc.LoginName and trt.SubscriberID = acc.SubscriberID)
    GROUP BY trt.SubscriberID
        ,    trt.LoginName
        ,    trt.SubscriberType;
    
    # Update AccountID to Temp_Transaction
    INSERT INTO Temp_RawTransactionInfo(TransID, AccountID, URLID)
    SELECT  trt.TransID
        ,   ac.AccountID
        ,   ur.URLID
    FROM Temp_RawTransaction AS trt
        INNER JOIN	FPSTesting.FP_Account AS ac ON trt.SubscriberID = ac.SubscriberID  AND trt.LoginName = ac.LoginName
	    LEFT JOIN	FPSTesting.FP_URL	AS ur ON trt.URLDetails = ur.URLDetails;
	SELECT 1;
    UPDATE Temp_RawTransaction AS trt
        INNER JOIN	Temp_RawTransactionInfo AS info ON trt.TransID = info.TransID  
    SET     trt.AccountID = info.AccountID
	    ,   trt.URLID = info.URLID;   
    
    #Remove Temp Trans If AccountID Is NULL
    DELETE 	trt
    FROM	Temp_RawTransaction AS trt
    WHERE 	trt.AccountID IS NULL;       
	/*
    INSERT INTO Temp_LastLoginTime(SubscriberID, AccountID, LastLoginTime)   
    SELECT  acc.SubscriberID
        ,   acc.AccountID
        ,   tac.LastLoginTime
    FROM FPSTesting.FP_Account 	AS acc
        INNER JOIN (SELECT trt.AccountID, MAX(trt.TransTime) AS LastLoginTime FROM Temp_RawTransaction AS trt GROUP BY trt.AccountID) AS tac ON	acc.AccountID = tac.AccountID
    WHERE tac.LastLoginTime > acc.LastLoginTime;    

    INSERT INTO FPSTesting.FP_AccountLastLoginTimeProcess(AccountID, LastLoginTime)
    SELECT  tll.AccountID
        ,   tll.LastLoginTime
    FROM Temp_LastLoginTime AS tll;
	*/
    INSERT IGNORE INTO  FPSTesting.FP_Transaction(RawTransID, LoginName, TransTime,  AccountID, URLID, UserAgentKey , IP, IPID, ActionResultID, Flagged, PluginID, TransStatus, CreatedDate, InsertTime, DeviceCode, FingerprintCode
    , FPDeviceID, SubscriberID)
   	SELECT  trt.TransID
	    ,   trt.LoginName
        ,   trt.TransTime      
        ,   trt.AccountID
	    ,   trt.URLID
        ,   trt.UserAgentKey
        ,   trt.IP
        ,   trt.IPID
        ,   trt.ActionResultID
	    ,   trt.Flagged
        ,   trt.PluginID
        ,   trt.TransStatus				
	    ,   trt.CreatedDate                
        ,   CURRENT_TIMESTAMP(4) AS InsertTime
        ,   trt.DeviceCode
        ,   trt.FingerprintCode
        ,	trt.FPDeviceID
        , 	trt.SubscriberID
	FROM Temp_RawTransaction AS trt;
    
    #================================================================
    
	INSERT IGNORE INTO FPSTesting.FP_ProcessedTransaction(LoginName, SubscriberName, TransTime, CreatedDate, DeviceCode, FingerprintCode, UserAgent , IP, IPID, Flagged, PluginID, URL, Action, ActionResult, InvalidDevice, TransStatus, IsProcessed, TransID
    , FPDeviceID, SubscriberID,CustID, CustSubID, LoginName_Old, TransTime_Old, IP_Old,UserAgent_Old, URL_Old,Flagged_Old)
	SELECT  rt.LoginName
        ,   rt.SubscriberName
        ,   rt.TransTime
        ,   rt.CreatedDate
        ,   rt.DeviceCode
        ,   rt.FingerprintCode
        ,   rt.UserAgent
	    ,   rt.IP
        ,   rt.IPID
        ,   rt.Flagged
        ,   rt.PluginID
        ,   rt.URL
        ,   rt.Action
        ,   rt.ActionResult
        ,   rt.InvalidDevice
        ,   rt.TransStatus
        ,   rt.IsProcessed
        ,   rt.TransID
        ,	rt.FPDeviceID
		, 	rt.SubscriberID
        ,	rt.CustID
        , 	rt.CustSubID
        , 	rt.LoginName_Old
        , 	rt.TransTime_Old
        , 	rt.IP_Old
        ,	rt.UserAgent_Old
        , 	rt.URL_Old
        ,	rt.Flagged_Old
	FROM FPSTesting.FP_RawTransaction AS rt
	    INNER JOIN	Temp_RawTransaction	AS tmp_rm ON	rt.TransID = tmp_rm.TransID AND rt.CreatedDate = tmp_rm.CreatedDate;
        
	DELETE rt
	FROM FPSTesting.FP_RawTransaction AS rt
	    INNER JOIN	Temp_RawTransaction	AS tmp_rm ON rt.TransID = tmp_rm.TransID AND rt.CreatedDate = tmp_rm.CreatedDate;   

END$$
DELIMITER ;

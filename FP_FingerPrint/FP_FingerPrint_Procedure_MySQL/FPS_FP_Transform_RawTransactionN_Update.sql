/*<info serverAlias="FPSDC-FPS_FingerPrint" databaseType="2" executers="fpsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `FPS_FP_Transform_RawTransactionN_Update`;
DELIMITER $$

CREATE DEFINER=`fpsOwner`@`%` PROCEDURE `FPS_FP_Transform_RawTransactionN_Update`(
			ip_RawTransJson	LONGTEXT
	,       ip_OffsetId		INT
	,       ip_OffsetValue	BIGINT
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20220221@Terry.Nguyen
		Task :		
		DB:			FPS_FingerPrint
		Original:

		Revisions:
			- 20220307@Terry.Nguyen: Created [Redmine ID: #162668]
            
		Param's Explanation (filtered by):	

		Example:
			- CALL FPS_FP_Transform_TransactionN_Update({});
			
	*/
   
    DECLARE lv_currentDate DATETIME DEFAULT NOW();   
    
	-- Create Temporary table
    DROP TEMPORARY TABLE IF EXISTS Temp_RawTransaction; 
	CREATE TEMPORARY TABLE Temp_RawTransaction(
			Id 				BIGINT UNSIGNED PRIMARY KEY    
		,	SessionKey 		VARCHAR(200) NOT NULL
		,	CustId 			BIGINT DEFAULT NULL
		,	SubAccId 		BIGINT DEFAULT NULL
		,	LoginName 		VARCHAR(100) DEFAULT NULL
		,	SubscriberId 	INT DEFAULT NULL
		,	Transtime 		DATETIME(4) DEFAULT NULL
		,	ClientIP 		VARCHAR(45) DEFAULT NULL
		,	UserAgent 		VARCHAR(500) DEFAULT NULL
		,	Url 			VARCHAR(100) DEFAULT NULL
		,	Action 			VARCHAR(100) DEFAULT NULL
		,	ModifiedDate 	DATETIME DEFAULT NULL
		,	CreatedDate 	DATETIME DEFAULT NULL
		,	TransKey 		VARCHAR(200) DEFAULT NULL
		,	Flagged 		VARCHAR(50) DEFAULT NULL		
		,	Retry 			TINYINT DEFAULT '0'
		,	FingerPrintCode VARCHAR(200) DEFAULT NULL
		,	CookieCode 		VARCHAR(64) DEFAULT NULL
        
        ,	INDEX IX_Temp_RawTransaction_FingerPrintCode(FingerPrintCode)
    );  
    
    DROP TEMPORARY TABLE IF EXISTS Temp_RawTransaction2;
    CREATE TEMPORARY TABLE Temp_RawTransaction2(
			Id 					BIGINT UNSIGNED PRIMARY KEY        
		,	SessionKey 			VARCHAR(200) NOT NULL
		,	CustId 				BIGINT DEFAULT NULL
		,	SubAccId 			BIGINT DEFAULT NULL
		,	LoginName 			VARCHAR(100) DEFAULT NULL
		,	SubscriberId 		INT DEFAULT NULL
		,	Transtime 			DATETIME(4) DEFAULT NULL
		,	ClientIP 			VARCHAR(45) DEFAULT NULL
		,	UserAgent 			VARCHAR(500) DEFAULT NULL
		,	Url 				VARCHAR(100) DEFAULT NULL
		,	Action 				VARCHAR(100) DEFAULT NULL
		,	ModifiedDate 		DATETIME DEFAULT NULL
		,	CreatedDate 		DATETIME DEFAULT NULL
		,	TransKey 			VARCHAR(200) DEFAULT NULL
		,	Flagged 			VARCHAR(50) DEFAULT NULL		
		,	Retry 				TINYINT DEFAULT 0
		,	FingerPrintCode 	VARCHAR(200) DEFAULT NULL
		,	CookieCode 			VARCHAR(64) DEFAULT NULL
        
        ,	INDEX IX_Temp_RawTransaction2_FingerPrintCode(FingerPrintCode)
        ,	INDEX IX_Temp_RawTransaction2_SessionKey(SessionKey)
    );  
    
   INSERT INTO Temp_RawTransaction(Id, SessionKey, CustId, SubAccId, LoginName, SubscriberId, Transtime, ClientIP, UserAgent, Url, TransKey, Retry, Action)
	SELECT	rt.Id
		,	rt.SessionKey
		,	rt.CustId
		,	rt.SubAccId
		,	rt.LoginName
		,	rt.SubscriberId
		,	rt.Transtime
		,	rt.ClientIP
		,	rt.UserAgent
		,	rt.Url	
        ,	rt.TransKey	
        ,	rt.Retry	
        ,	rt.Action
	FROM	JSON_TABLE(
			ip_RawTransJson,
			 "$[*]" COLUMNS(
								Id						BIGINT			PATH "$.Id"       
							,	SessionKey				VARCHAR(200) 	PATH "$.SessionKey"   
							,	CustId					BIGINT 			PATH "$.CustId"
							,	SubAccId				BIGINT			PATH "$.SubAccId"
							,	LoginName				VARCHAR(100)	PATH "$.LoginName"
							,	SubscriberId			INT 			PATH "$.SubscriberId"
							,	Transtime				DATETIME(4)	 	PATH "$.Transtime"
                            ,	ClientIP				VARCHAR(45)		PATH "$.ClientIP"
                            ,	UserAgent				VARCHAR(500)	PATH "$.UserAgent"
							,	Url						VARCHAR(100) 	PATH "$.Url"
							,	TransKey				VARCHAR(200) 	PATH "$.TransKey"
                            ,	Retry					TINYINT			PATH "$.Retry"
							,	Action					VARCHAR(100) 	PATH "$.Action"                           
				)
		   ) AS  rt; 
           
    INSERT INTO Temp_RawTransaction2(Id, SessionKey, CustId, SubAccId, LoginName, SubscriberId, Transtime, ClientIP, UserAgent, Url, TransKey, Retry, Action, FingerPrintCode, CookieCode, Flagged)
	SELECT	tmpRt.Id
		,	tmpRt.SessionKey
		,	tmpRt.CustId
		,	tmpRt.SubAccId
		,	tmpRt.LoginName
		,	tmpRt.SubscriberId
		,	tmpRt.Transtime
		,	tmpRt.ClientIP
		,	tmpRt.UserAgent
		,	IFNULL(tmpRt.Url, fp.Url)
		,	tmpRt.TransKey
		,	tmpRt.Retry
		,	tmpRt.Action
		,	fp.FingerPrintCode
		,	fp.CookieCode
		,	fp.Flagged
    FROM Temp_RawTransaction AS tmpRt
		LEFT JOIN FPS_FingerPrint.FingerPrint fp ON fp.SessionKey = tmpRt.SessionKey;
      
	-- Insert data completed
    INSERT INTO FPS_FingerPrint.Transaction(RawTransId, CustId, SubAccId, LoginName, SubscriberId, FingerPrintCode, CookieCode, Transtime, ClientIP, UserAgent, Url, Action, CreatedDate, TransKey, Flagged)
    SELECT Id
		,	tmpRt2.CustId
        ,	tmpRt2.SubAccId
        ,	tmpRt2.LoginName
        ,	tmpRt2.SubscriberId
        ,	tmpRt2.FingerPrintCode
		,	tmpRt2.CookieCode
        ,	tmpRt2.Transtime
        ,	tmpRt2.ClientIP
        ,	tmpRt2.UserAgent
        ,	tmpRt2.Url
        ,	tmpRt2.Action
        ,	tmpRt2.CreatedDate
        ,	tmpRt2.TransKey
        ,	tmpRt2.Flagged
    FROM Temp_RawTransaction2 AS tmpRt2;

	INSERT INTO FPS_FingerPrint.RawTransactionCompleted(Id, SessionKey, CustId, SubAccId, LoginName, SubscriberId, Transtime, ClientIP, UserAgent, Url, ModifiedDate, CreatedDate, TransKey, Retry, Action)
    SELECT ts.Id
    , 	ts.SessionKey
    , 	ts.CustId
    , 	ts.SubAccId
    , 	ts.LoginName
    , 	ts.SubscriberId
    , 	ts.Transtime
    , 	ts.ClientIP
    , 	ts.UserAgent
    , 	ts.Url
    , 	ts.ModifiedDate
    , 	ts.CreatedDate
    , 	ts.TransKey
    , 	ts.Retry
    , 	ts.Action
    FROM FPS_FingerPrint.RawTransaction AS ts 
		INNER JOIN Temp_RawTransaction2 AS tmpRt2 ON ts.Id = tmpRt2.Id;
    
    INSERT INTO FPS_FingerPrint.FingerPrintCompleted(Id, FingerPrintCode, UserAgentCode, CookieCode, SubscriberId, SessionKey, Flagged, Url, CreatedDate)
    SELECT 	fp.Id
		,	fp.FingerPrintCode
		,	fp.UserAgentCode
		,	fp.CookieCode
		,	fp.SubscriberId
		,	fp.SessionKey
		,	fp.Flagged
		,	fp.Url
		,	fp.CreatedDate
    FROM FPS_FingerPrint.FingerPrint AS fp
		INNER JOIN Temp_RawTransaction2 AS tmpRt2 ON tmpRt2.SessionKey = fp.SessionKey;
    
    DELETE fp FROM FPS_FingerPrint.FingerPrint AS fp
		INNER JOIN Temp_RawTransaction2 AS tmpRt2 ON tmpRt2.SessionKey = fp.SessionKey;   
    
    DELETE rt 
    FROM FPS_FingerPrint.RawTransaction AS rt 
		INNER JOIN Temp_RawTransaction2 AS tmpRt2 ON rt.Id = tmpRt2.Id;
    
    DELETE rtn 
    FROM FPS_FingerPrint.RawTransactionN AS rtn
		INNER JOIN Temp_RawTransaction2 AS tmpRt2 ON rtn.RawTransId = tmpRt2.Id;
    
    UPDATE FPS_FingerPrint.Offset AS fs
	SET fs.OffsetValue = ip_OffsetValue
    WHERE fs.Id = ip_OffsetId;

END$$
DELIMITER ;
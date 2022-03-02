/*<info serverAlias="xxxx" databaseType="2" executers="fpsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `FPS_FP_Transform_RawTransactionN_Update`;
DELIMITER $$

CREATE DEFINER=`FPSOwner`@`%` PROCEDURE `FPS_FP_Transform_RawTransactionN_Update`(
		ip_RawTransJson	LONGTEXT,
        ip_OffsetId		INT,
        ip_OffsetValue	BIGINT
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20220221@Terry.Nguyen
		Task :		
		DB:			FPS_FingerPrint
		Original:

		Revisions:
            
		Param's Explanation (filtered by):	

		Example:
			- CALL FPS_FP_Transform_TransactionN_Update({});
			
	*/
   
    DECLARE lv_currentDate DATETIME DEFAULT NOW();   
    
	DROP TEMPORARY TABLE IF EXISTS Temp_RawTransaction;  
    DROP TEMPORARY TABLE IF EXISTS Temp_RawTransaction2;
    
	-- Create Temporary table
	CREATE TEMPORARY TABLE Temp_RawTransaction(
		`Id` 				BIGINT SIGNED PRIMARY KEY,        
		`SessionKey` 		VARCHAR(200) NOT NULL,
		`CustId` 			BIGINT DEFAULT NULL,
		`SubAccId` 			BIGINT DEFAULT NULL,
		`LoginName` 		VARCHAR(100) DEFAULT NULL,
		`SubscriberId` 		INT DEFAULT NULL,
		`Transtime` 		DATETIME DEFAULT NULL,
		`ClientIP` 			VARCHAR(45) DEFAULT NULL,
		`UserAgent` 		VARCHAR(500) DEFAULT NULL,
		`Url` 				VARCHAR(100) DEFAULT NULL,
		`Action` 			VARCHAR(100) DEFAULT NULL,
		`ModifiedDate` 		DATETIME DEFAULT NULL,
		`CreatedDate` 		DATETIME DEFAULT NULL,
		`TransKey` 			VARCHAR(200) DEFAULT NULL,
		`Flagged` 			VARCHAR(50) DEFAULT NULL,		
		`Retry` 			TINYINT DEFAULT '0',
		`FingerPrintCode` 	VARCHAR(200) DEFAULT NULL,
		`CookieId` 			BIGINT DEFAULT NULL,
        INDEX Temp_RawTransaction_FingerPrintCode_Index (FingerPrintCode)
    );  
    
    CREATE TEMPORARY TABLE Temp_RawTransaction2(
		`Id` 				BIGINT SIGNED PRIMARY KEY,        
		`SessionKey` 		VARCHAR(200) NOT NULL,
		`CustId` 			BIGINT DEFAULT NULL,
		`SubAccId` 			BIGINT DEFAULT NULL,
		`LoginName` 		VARCHAR(100) DEFAULT NULL,
		`SubscriberId` 		INT DEFAULT NULL,
		`Transtime` 		DATETIME DEFAULT NULL,
		`ClientIP` 			VARCHAR(45) DEFAULT NULL,
		`UserAgent` 		VARCHAR(500) DEFAULT NULL,
		`Url` 				VARCHAR(100) DEFAULT NULL,
		`Action` 			VARCHAR(100) DEFAULT NULL,
		`ModifiedDate` 		DATETIME DEFAULT NULL,
		`CreatedDate` 		DATETIME DEFAULT NULL,
		`TransKey` 			VARCHAR(200) DEFAULT NULL,
		`Flagged` 			VARCHAR(50) DEFAULT NULL,		
		`Retry` 			TINYINT DEFAULT '0',
		`FingerPrintCode` 	VARCHAR(200) DEFAULT NULL,
		`CookieId` 			BIGINT DEFAULT NULL,
        INDEX Temp_RawTransaction_FingerPrintCode_Index (FingerPrintCode)
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
							,	Transtime				DATETIME	 	PATH "$.Transtime"
                            ,	ClientIP				VARCHAR(45)		PATH "$.ClientIP"
                            ,	UserAgent				VARCHAR(500)	PATH "$.UserAgent"
							,	Url						VARCHAR(100) 	PATH "$.Url"
							,	TransKey				VARCHAR(200) 	PATH "$.TransKey"
                            ,	Retry					TINYINT			PATH "$.Retry"
							,	Action					VARCHAR(100) 	PATH "$.Action"                           
				)
		   ) AS  rt; 
           
    INSERT INTO Temp_RawTransaction2(Id, SessionKey, CustId, SubAccId, LoginName, SubscriberId, Transtime, ClientIP, UserAgent, Url, TransKey, Retry, Action, FingerPrintCode, CookieId, Flagged)
    SELECT trans.Id
    ,	trans.SessionKey
    ,	trans.CustId
    ,	trans.SubAccId
    ,	trans.LoginName
    ,	trans.SubscriberId
    ,	trans.Transtime
    ,	trans.ClientIP
    ,	IFNULL(trans.Url, fp.Url)
    ,	trans.TransKey
    ,	trans.Retry
    ,	trans.Action
    ,	fp.FingerPrintCode
    ,	fp.CookieId
    ,	fp.Flagged
    FROM Temp_RawTransaction trans
		INNER JOIN FPS_FingerPrint.FingerPrint fp ON fp.SessionKey = trans.SessionKey;
      
	-- Insert data completed
    INSERT INTO FPS_FingerPrint.Transaction(
		RawTransId
		, CustId
		, SubAccId
		, LoginName
		, SubscriberId
		, FingerPrintCode
		, CookieId
		, Transtime
		, ClientIP
		, UserAgent
		, Url
		, Action
		, ModifiedDate
		, CreatedDate
		, TransKey
		, Flagged
	)
    SELECT Id
		, CustId
        , SubAccId
        , LoginName
        , SubscriberId
        , FingerPrintCode
		, CookieId
        , Transtime
        , ClientIP
        , UserAgent
        , Url
        , Action
        , lv_currentDate as ModifiedDate
        , CreatedDate
        , TransKey
        , Flagged
    FROM Temp_RawTransaction2;

	INSERT INTO FPS_FingerPrint.RawTransactionCompleted(Id, SessionKey, CustId, SubAccId, LoginName, SubscriberId, Transtime, ClientIP, UserAgent, Url, ModifiedDate, CreatedDate, TransKey, Retry, Action)
    SELECT trans.Id
    , 	trans.SessionKey
    , 	trans.CustId
    , 	trans.SubAccId
    , 	trans.LoginName
    , 	trans.SubscriberId
    , 	trans.Transtime
    , 	trans.ClientIP
    , 	trans.UserAgent
    , 	trans.Url
    , 	trans.ModifiedDate
    , 	trans.CreatedDate
    , 	trans.TransKey
    , 	trans.Retry
    , 	trans.Action
    FROM FPS_FingerPrint.RawTransaction trans 
    INNER JOIN Temp_RawTransaction2 tmp ON trans.Id = tmp.Id;
    
    INSERT INTO FPS_FingerPrint.FingerPrintCompleted(Id, FingerPrintCode, UserAgentCode, CookieId, SubscriberId, SessionKey, Flagged, Url, CreatedDate)
    SELECT fp.Id
    ,	fp.FingerPrintCode
    ,	fp.UserAgentCode
    ,	fp.CookieId
    ,	fp.SubscriberId
    ,	fp.SessionKey
    ,	fp.Flagged
    ,	fp.Url
    ,	fp.CreatedDate
    FROM FPS_FingerPrint.FingerPrint fp
		INNER JOIN Temp_RawTransaction2 tmp ON tmp.SessionKey = fp.SessionKey;
    
    DELETE fp FROM FPS_FingerPrint.FingerPrint fp
			INNER JOIN Temp_RawTransaction2 tmp ON tmp.SessionKey = fp.SessionKey;   
    
    DELETE trans FROM FPS_FingerPrint.RawTransaction trans 
    INNER JOIN Temp_RawTransaction2 tmp ON trans.Id = tmp.Id;
    
    DELETE trans FROM FPS_FingerPrint.RawTransactionN trans
    INNER JOIN Temp_RawTransaction2 tmp ON trans.RawTransId = tmp.Id;
    
    UPDATE FPS_FingerPrint.Offset off
		SET off.OffsetValue = ip_OffsetValue
    WHERE off.Id = ip_OffsetId;
    
	DROP TEMPORARY TABLE IF EXISTS Temp_RawTransaction;
    DROP TEMPORARY TABLE IF EXISTS Temp_RawTransaction2;
END$$
DELIMITER ;

GRANT EXECUTE ON PROCEDURE FPS_FingerPrint.FPS_FP_Transform_RawTransactionN_Update TO 'fpsServiceAdmin'@'%';
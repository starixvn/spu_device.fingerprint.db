/*<info serverAlias="FPSDC-FPS_FingerPrint" databaseType="2" executers="fpsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `FPS_FP_Transform_RawTransaction_Update`;
DELIMITER $$

CREATE DEFINER=`FPSOwner`@`%` PROCEDURE `FPS_FP_Transform_RawTransaction_Update`(
		ip_RawTransJson	LONGTEXT
    ,	ip_Retry		INT
    ,   ip_OffsetId		INT
	,	ip_OffsetValue	BIGINT
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
			- CALL FPS_FP_UpdateTransaction({});
			
	*/
   
    DECLARE lv_currentDate DATETIME DEFAULT NOW();
    
	DROP TEMPORARY TABLE IF EXISTS Temp_RawTransaction;  
    DROP TEMPORARY TABLE IF EXISTS Temp_RawTransaction2;
    
	-- Create Temporary table

	CREATE TEMPORARY TABLE Temp_RawTransaction(
			Id 					BIGINT UNSIGNED PRIMARY KEY        
		,	SessionKey 			VARCHAR(200) NULL
		,	CustId 				BIGINT DEFAULT NULL
		,	SubAccId 			BIGINT DEFAULT NULL
		,	LoginName 			VARCHAR(100) DEFAULT NULL
		,	SubscriberId 		INT DEFAULT NULL
		,	Transtime 			DATETIME(4) DEFAULT NULL
		,	ClientIP 			VARCHAR(45) DEFAULT NULL
		,	UserAgent 			VARCHAR(500) DEFAULT NULL
		,	Url 				VARCHAR(100) DEFAULT NULL
		,	Action 				VARCHAR(100) DEFAULT NULL		
		,	CreatedDate 		DATETIME DEFAULT NULL
		,	TransKey 			VARCHAR(200) DEFAULT NULL
		,	Flagged 			VARCHAR(50) DEFAULT NULL		
		,	Retry 				TINYINT DEFAULT 0
		,	FingerPrintCode 	VARCHAR(200) DEFAULT NULL
		,	CookieCode 			VARCHAR(64) DEFAULT NULL
        
		,	INDEX IX_Temp_RawTransaction_FingerPrintCode(FingerPrintCode)
        ,	INDEX IX_Temp_RawTransaction_SessionKey(SessionKey)
    );   
    
	CREATE TEMPORARY TABLE Temp_RawTransaction2(
			Id 					BIGINT SIGNED PRIMARY KEY        
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
		,	CreatedDate 		DATETIME DEFAULT NULL
		,	TransKey 			VARCHAR(200) DEFAULT NULL
		,	Flagged 			VARCHAR(50) DEFAULT NULL		
		,	Retry 				TINYINT DEFAULT '0'
		,	FingerPrintCode 	VARCHAR(200) DEFAULT NULL
		,	CookieCode 			VARCHAR(64) DEFAULT NULL
        
        ,	INDEX Temp_RawTransaction_FingerPrintCode_Index (FingerPrintCode)
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
   SELECT tmpTs.Id
   , 	tmpTs.SessionKey
   , 	tmpTs.CustId
   , 	tmpTs.SubAccId
   , 	tmpTs.LoginName
   , 	tmpTs.SubscriberId
   , 	tmpTs.Transtime
   , 	tmpTs.ClientIP
   , 	tmpTs.UserAgent
   , 	IFNULL(tmpTs.Url, fp.Url)
   , 	tmpTs.TransKey
   ,	tmpTs.retry + 1
   ,	tmpTs.Action
   ,	fp.FingerPrintCode
   ,	fp.CookieCode
   ,	fp.Flagged
   FROM Temp_RawTransaction AS tmpTs 
		LEFT JOIN FPS_FingerPrint.FingerPrint AS fp ON fp.SessionKey = tmpTs.SessionKey;
  
	-- Insert data completed
    INSERT INTO FPS_FingerPrint.Transaction(
			RawTransId
		,	CustId
		,	SubAccId
		,	LoginName
		,	SubscriberId
		,	FingerPrintCode
		,	CookieCode
		,	Transtime
		,	ClientIP
		,	UserAgent
		,	Url
		,	Action		
		,	CreatedDate
		,	TransKey
		,	Flagged
	)
    SELECT	tmpTs2.Id
		,	tmpTs2.CustId
        ,	tmpTs2.SubAccId
        ,	tmpTs2.LoginName
        ,	tmpTs2.SubscriberId
        ,	tmpTs2.FingerPrintCode
		,	tmpTs2.CookieCode
        ,	tmpTs2.Transtime
        ,	tmpTs2.ClientIP
        ,	tmpTs2.UserAgent
        ,	tmpTs2.Url
        ,	tmpTs2.Action        
        ,	tmpTs2.CreatedDate
        ,	tmpTs2.TransKey
        ,	tmpTs2.Flagged
    FROM Temp_RawTransaction2 AS tmpTs2
    WHERE tmpTs2.FingerPrintCode IS NOT NULL;

	INSERT INTO FPS_FingerPrint.RawTransactionCompleted(Id, SessionKey, CustId, SubAccId, LoginName, SubscriberId, Transtime, ClientIP, UserAgent, Url, ModifiedDate, CreatedDate, TransKey, Retry, Action)
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
        ,	rt.ModifiedDate
        ,	rt.CreatedDate
        ,	rt.TransKey
        ,	rt.Retry
        ,	rt.Action
    FROM FPS_FingerPrint.RawTransaction AS rt 
		INNER JOIN Temp_RawTransaction2 AS tmpT2 ON rt.Id = tmpT2.Id 
    WHERE tmpT2.FingerPrintCode IS NOT NULL;
    
    INSERT INTO FPS_FingerPrint.FingerPrintCompleted(Id, FingerPrintCode, UserAgentCode, CookieCode, SubscriberId, SessionKey, Flagged, Url, CreatedDate)
    SELECT	fp.Id
		,	fp.FingerPrintCode
		,	fp.UserAgentCode
		,	fp.CookieCode
		,	fp.SubscriberId
		,	fp.SessionKey
		,	fp.Flagged
		,	fp.Url
		,	fp.CreatedDate
    FROM FPS_FingerPrint.FingerPrint AS fp
		INNER JOIN Temp_RawTransaction2 AS tmpT2 ON tmpT2.SessionKey = fp.SessionKey;
    
    DELETE fp FROM FPS_FingerPrint.FingerPrint AS fp
		INNER JOIN Temp_RawTransaction2 AS tmpT2 ON tmpT2.SessionKey = fp.SessionKey;   
    
    DELETE rt FROM FPS_FingerPrint.RawTransaction rt 
		INNER JOIN Temp_RawTransaction2 AS tmpT2 ON rt.Id = tmpT2.Id 
    WHERE tmpT2.FingerPrintCode IS NOT NULL;
    
    DELETE tmpT2
    FROM Temp_RawTransaction2 AS tmpT2
    WHERE tmpT2.FingerPrintCode IS NOT NULL;
    	   
    INSERT INTO FPS_FingerPrint.RawTransactionN(SessionKey, RawTransId, CreatedDate)
    SELECT tmpT2.SessionKey
		,	tmpT2.Id
        ,	tmpT2.CreatedDate 
    FROM Temp_RawTransaction2 AS tmpT2 
    WHERE tmpT2.FingerPrintCode IS NULL AND tmpT2.Retry >= ip_Retry;
    
    UPDATE FPS_FingerPrint.RawTransaction rawTrans
		INNER JOIN Temp_RawTransaction2 tmp ON tmp.Id = rawTrans.Id
		SET rawTrans.Retry = tmp.Retry     
	WHERE tmp.FingerPrintCode IS NULL;
    
    DELETE tmpT2
    FROM Temp_RawTransaction2 AS tmpT2
    WHERE tmpT2.FingerPrintCode IS NULL AND Retry >= ip_Retry;
    
    UPDATE FPS_FingerPrint.Offset off
		SET off.OffsetValue = ip_OffsetValue
    WHERE off.Id = ip_OffsetId;

END$$
DELIMITER ;

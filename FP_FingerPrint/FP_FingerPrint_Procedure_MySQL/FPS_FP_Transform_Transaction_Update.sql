/*<info serverAlias="xxxx" databaseType="2" executers="fpsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `FPS_FP_Transform_Transaction_Update`;
DELIMITER $$

CREATE DEFINER=`FPSOwner`@`%` PROCEDURE `FPS_FP_Transform_Transaction_Update`(
		ip_RawTransJson	LONGTEXT,
        ip_Retry		INT,
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
			- CALL FPS_FP_UpdateTransaction({});
			
	*/
   
    DECLARE lv_currentDate DATETIME DEFAULT NOW();
    
	DROP TEMPORARY TABLE IF EXISTS Temp_RawTransaction;  
    
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
		`CreatedDate` 		DATETIME DEFAULT NULL,
		`TransKey` 			VARCHAR(200) DEFAULT NULL,
		`Flagged` 			VARCHAR(50) DEFAULT NULL,		
		`Retry` 			TINYINT DEFAULT '0',
		`FingerPrintCode` 	VARCHAR(200) DEFAULT NULL,
		`CookieId` 			BIGINT DEFAULT NULL,
        INDEX Temp_RawTransaction_FingerPrintCode_Index (FingerPrintCode)
    ) ENGINE = MEMORY;  
    
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
    
    UPDATE Temp_RawTransaction trans
		LEFT JOIN FPS_FingerPrint.FingerPrint fp ON fp.SessionKey = trans.SessionKey
    SET trans.FingerPrintCode = fp.FingerPrintCode
		, trans.CookieId = fp.CookieId
		, trans.Flagged = fp.Flagged
        , trans.retry = trans.retry + 1
        , trans.Url = IFNULL(trans.Url, fp.Url);
    
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
        , CreatedDate
        , TransKey
        , Flagged
    FROM Temp_RawTransaction
    WHERE FingerPrintCode IS NOT NULL;

	INSERT INTO FPS_FingerPrint.RawTransactionCompleted(Id, SessionKey, CustId, SubAccId, LoginName, SubscriberId, Transtime, ClientIP, UserAgent, Url, ModifiedDate, CreatedDate, TransKey, Retry, Action)
    SELECT trans.Id, trans.SessionKey, trans.CustId, trans.SubAccId, trans.LoginName, trans.SubscriberId, trans.Transtime, trans.ClientIP, trans.UserAgent, trans.Url, trans.ModifiedDate, trans.CreatedDate, trans.TransKey, trans.Retry, trans.Action
    FROM FPS_FingerPrint.RawTransaction trans 
		INNER JOIN Temp_RawTransaction tmp ON trans.Id = tmp.Id 
    WHERE tmp.FingerPrintCode IS NOT NULL;
    
    UPDATE FPS_FingerPrint.FingerPrint fp
		INNER JOIN Temp_RawTransaction tmp ON tmp.SessionKey = fp.SessionKey
    SET fp.MergedStatus = 1;
    
    DELETE trans FROM FPS_FingerPrint.RawTransaction trans 
		INNER JOIN Temp_RawTransaction tmp ON trans.Id = tmp.Id 
    WHERE tmp.FingerPrintCode IS NOT NULL;
    
    DELETE FROM Temp_RawTransaction WHERE FingerPrintCode IS NOT NULL;
    	   
    INSERT INTO FPS_FingerPrint.RawTransactionN(SessionKey, RawTransId, CreatedDate)
    SELECT tmp.SessionKey, tmp.Id, tmp.CreatedDate 
    FROM Temp_RawTransaction tmp 
    WHERE tmp.FingerPrintCode IS NULL AND tmp.Retry >= ip_Retry;
    
    DELETE FROM Temp_RawTransaction WHERE FingerPrintCode IS NOT NULL AND Retry >= ip_Retry;
    
    UPDATE FPS_FingerPrint.RawTransaction rawTrans
		INNER JOIN Temp_RawTransaction tmp ON tmp.Id = rawTrans.Id
		SET rawTrans.Retry = tmp.Retry     
	WHERE tmp.FingerPrintCode IS NULL;
    
    UPDATE FPS_FingerPrint.Offset off
		SET off.OffsetValue = ip_OffsetValue
    WHERE off.Id = ip_OffsetId;
    
	DROP TEMPORARY TABLE IF EXISTS Temp_RawTransaction;
END$$
DELIMITER ;

GRANT EXECUTE ON PROCEDURE FPS_FingerPrint.FPS_FP_Transform_Transaction_Update TO 'fpsServiceAdmin'@'%';
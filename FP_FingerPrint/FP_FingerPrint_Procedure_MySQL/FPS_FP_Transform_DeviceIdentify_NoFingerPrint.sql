/*<info serverAlias="xxxx" databaseType="2" executers="fpsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `FPS_FP_Transform_DeviceIdentify_NoFingerPrint`;
DELIMITER $$

CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `FPS_FP_Transform_DeviceIdentify_NoFingerPrint`(		
        ip_TransJson	LONGTEXT
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
			- CALL FPS_FP_Transform_DeviceIdentify_NoFingerPrint('[{"Id":2,"FingerPrintCode":"4c87b1360e6a1c77741180339a50355f","CookieId":68}]', 'DeviceIndetify');
			
	*/
   
    DECLARE lv_currentDate DATETIME DEFAULT NOW();   
        	
    DROP TEMPORARY TABLE IF EXISTS Temp_Transaction;    
    
	CREATE TEMPORARY TABLE Temp_Transaction(
		Id 					BIGINT SIGNED PRIMARY KEY,  
        RawTransId			BIGINT,
        CustId				BIGINT,
        SubAccId			BIGINT,
        LoginName			VARCHAR(100),
        SubscriberId		INT,      
        Transtime			DateTime,
        ClientIP			VARCHAR(45),
        UserAgent			VARCHAR(500),
        Url					VARCHAR(100),
        Action				VARCHAR(100),                
		ModifiedDate		DATETIME,
        CreatedDate			DATETIME,
        TransKey			VARCHAR(200),
        Flagged				VARCHAR(50)
    ) ENGINE = MEMORY;
    
    INSERT INTO Temp_Transaction(Id, RawTransId, CustId, SubAccId, LoginName, SubscriberId, Transtime, ClientIP, UserAgent, Url, Action, ModifiedDate, CreatedDate, TransKey, Flagged)
	SELECT	rt.Id
		,	rt.RawTransId
        ,	rt.CustId
        ,	rt.SubAccId
        ,	rt.LoginName
        ,	rt.SubscriberId     
        ,	rt.Transtime
        ,	rt.ClientIP
        ,	rt.UserAgent
        ,	rt.Url
        ,	rt.Action
        ,	rt.ModifiedDate
        ,	rt.CreatedDate
        ,	rt.TransKey
        ,	rt.Flagged       
	FROM	JSON_TABLE(
			ip_TransJson,
			 "$[*]" COLUMNS(
								Id						BIGINT			PATH "$.Id"       
							,	RawTransId				BIGINT			PATH "$.RawTransId"
                            ,	CustId					BIGINT			PATH "$.CustId"
                            ,	SubAccId				BIGINT			PATH "$.SubAccId"
                            ,	LoginName				VARCHAR(100)	PATH "$.LoginName"
                            ,	SubscriberId			INT				PATH "$.SubscriberId"
                            ,	Transtime				DATETIME		PATH "$.Transtime"
                            ,	ClientIP				VARCHAR(45)		PATH "$.ClientIP"
                            ,	UserAgent				VARCHAR(500)	PATH "$.UserAgent"
                            ,	Url						VARCHAR(100)	PATH "$.Url"
                            ,	Action					VARCHAR(100)	PATH "$.Action"
                            ,	ModifiedDate			DATETIME		PATH "$.ModifiedDate"
                            ,	CreatedDate				DATETIME		PATH "$.CreatedDate"
                            ,	TransKey				VARCHAR(200)	PATH "$.TransKey"
                            ,	Flagged					VARCHAR(50)		PATH "$.Flagged"
                                                   
				)
		   ) AS  rt;  
          
    INSERT INTO FPS_FingerPrint.TransactionCompleted(Id, RawTransId, CustId , SubAccId, LoginName, SubscriberId, Transtime,  ClientIP, UserAgent, Url, Action, ModifiedDate, CreatedDate, TransKey, Flagged)
    SELECT  	tmp.Id
			, 	tmp.RawTransId
			, 	tmp.CustId
			, 	tmp.SubAccId
			, 	tmp.LoginName
			, 	tmp.SubscriberId			
			, 	tmp.Transtime
			, 	tmp.ClientIP
			, 	tmp.UserAgent
			, 	tmp.Url
			, 	tmp.Action
			, 	tmp.ModifiedDate
			, 	lv_currentDate
			, 	tmp.TransKey
			, 	tmp.Flagged    
		FROM Temp_Transaction tmp;
    
    DELETE trans FROM FPS_FingerPrint.Transaction trans
		INNER JOIN Temp_Transaction tmp ON trans.Id = tmp.Id;    
    
END$$
DELIMITER ;

GRANT EXECUTE ON PROCEDURE FPS_FingerPrint.FPS_FP_Transform_DeviceIdentify_NoFingerPrint TO 'fpsServiceAdmin'@'%';
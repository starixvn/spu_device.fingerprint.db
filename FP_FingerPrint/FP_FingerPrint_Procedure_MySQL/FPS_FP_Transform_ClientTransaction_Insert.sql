/*<info serverAlias="FPSDC-FPS_FingerPrint" databaseType="2" executers="fpsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `FPS_FP_Transform_ClientTransaction_Insert`;
DELIMITER $$

CREATE DEFINER=`fpsOwner`@`%` PROCEDURE `FPS_FP_Transform_ClientTransaction_Insert`(
		ip_FingerPrint LONGTEXT
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20220218@Terry.Nguyen
		Task :		
		DB:			FPS_FingerPrint
		Original:

		Revisions:
			- 20220307@Terry.Nguyen: Created [Redmine ID: #162668]
			- 20220318@Jonathan.Doan: Add TransTime for ClientTransaction and Insert ClientTransactionDailySum [Redmine ID: #162668]
            
		Param's Explanation (filtered by):	

		Example:
			- CALL FPS_FP_Transform_ClientTransaction_Insert('[{"FingerPrintCode":"53b9f5d0e59645d09cfb56690a7b0916","SessionKey":"ddddd","SubscriberId":2,"Attribute":"dfsfsafsaf","UserAgentCode":"fdsafasfasf","UserAgentAttribute":"dddddd","CookieCode":"cookief5d0e59645d09cfb56690a7b0916","Flagged":"Human","Url":"fdsafdsaf"}]');
			
	*/
    
    /*******LOG TEST********************/
    INSERT INTO FPS_FingerPrint.Test_LOG(SpName, JsonString, OtherText, InsertTime)
    SELECT 'FPS_FP_Transform_ClientTransaction_Insert', ip_FingerPrint , NULL, CURRENT_TIMESTAMP();
    /*******LOG TEST********************/
    
    DROP TEMPORARY TABLE IF EXISTS Temp_FingerPrint;    
	CREATE TEMPORARY TABLE Temp_FingerPrint(
			FingerPrintCode				VARCHAR(200) 	NULL	
		,	SessionKey					VARCHAR(100) 	NULL
		,	SubscriberId				INT	 			NULL
		,	Attribute					LONGTEXT	 	NULL		
		,	UserAgentCode				VARCHAR(100)	NULL		
		,	UserAgentAttribute			LONGTEXT		NULL
		,	CookieCode 					VARCHAR(64)		NULL		
        ,	Flagged						VARCHAR(50)		NULL		
        ,	Url							VARCHAR(100)	NULL
		,	TransTime					DATETIME(4)	 	NULL	
		
		,	INDEX	IX_Temp_FingerPrint_UserAgentCode(UserAgentCode)
    );     
    
    INSERT INTO Temp_FingerPrint(FingerPrintCode, SessionKey, SubscriberId, Attribute, UserAgentCode, UserAgentAttribute, CookieCode, Flagged, Url, TransTime)
	SELECT	tmp.FingerPrintCode
		,	tmp.SessionKey
		,	tmp.SubscriberId
		,	tmp.Attribute
        ,	tmp.UserAgentCode
        ,	tmp.UserAgentAttribute
        ,	tmp.CookieCode
        ,	tmp.Flagged
        ,	tmp.Url
        ,	tmp.TransTime
	FROM	JSON_TABLE(
			ip_FingerPrint,
			 "$[*]" COLUMNS(
								FingerPrintCode			VARCHAR(200)	PATH "$.FingerPrintCode"       
							,	SessionKey				VARCHAR(100) 	PATH "$.SessionKey"   
							,	SubscriberId			INT 			PATH "$.SubscriberId"
							,	Attribute				LONGTEXT		PATH "$.Attribute"
							,	UserAgentCode			VARCHAR(100)	PATH "$.UserAgentCode"
							,	UserAgentAttribute		LONGTEXT		PATH "$.UserAgentAttribute"
							,	CookieCode				VARCHAR(64) 	PATH "$.CookieCode"							
                            ,	Flagged					VARCHAR(50) 	PATH "$.Flagged"
                            ,	Url						VARCHAR(100) 	PATH "$.Url"
                            ,	TransTime				DATETIME(4)		PATH "$.TransTime"
				)
		   ) AS  tmp; 
 
    INSERT INTO FPS_FingerPrint.RawUserAgent (UserAgentCode, Attribute, CreatedDate, ModifiedDate)	
	SELECT	tmp.UserAgentCode
		,	tmp.UserAgentAttribute
        ,	NOW() AS CreatedDate
        ,	NOW() AS ModifiedDate
	FROM FPS_FingerPrint.RawUserAgent ua 
		RIGHT JOIN Temp_FingerPrint tmp ON ua.UserAgentCode = tmp.UserAgentCode
	ON DUPLICATE KEY UPDATE ModifiedDate = NOW();
    
    
    INSERT INTO FPS_FingerPrint.RawFingerPrint(FingerPrintCode, Attribute, CreatedDate, ModifiedDate)
	SELECT	tmp.FingerPrintCode
		,	tmp.Attribute
        ,	NOW() AS CreatedDate
        ,	NOW() AS ModifiedDate
	FROM Temp_FingerPrint tmp
	ON DUPLICATE KEY UPDATE ModifiedDate = NOW();
    
    INSERT INTO FPS_FingerPrint.ClientTransaction(FingerPrintCode, SubscriberId, UserAgentCode, CookieCode, SessionKey, Flagged, Url, TransTime, CreatedDate, ModifiedDate)
	SELECT	tmp.FingerPrintCode
		,	tmp.SubscriberId
		,	tmp.UserAgentCode
		,	tmp.CookieCode
		,	tmp.SessionKey
		,	tmp.Flagged
		,	tmp.Url
		,	tmp.TransTime
		,	NOW() AS CreatedDate
		,	NOW() AS CreatedDate
	FROM Temp_FingerPrint tmp;


    SELECT CAST(tmp.TransTime as DATE) as TransDate
			,	tmp.SubscriberId
			,	COUNT(tmp.SubscriberId) as TotalTrans
			,	0 as TotalValidTrans
			,	NOW() AS CreatedDate
    FROM Temp_FingerPrint tmp
    GROUP BY TransDate, tmp.SubscriberId;
    
	INSERT INTO FPS_FingerPrint.ClientTransactionDailySum(
			TransDate
            ,	SubscriberId
            ,	TotalTrans
            ,	TotalValidTrans
            ,	CreateDate
    )
    SELECT CAST(tmp.TransTime as DATE) as TransDate
			,	tmp.SubscriberId
			,	COUNT(tmp.SubscriberId) as TotalTrans
			,	0 as TotalValidTrans
			,	NOW() AS CreatedDate
    FROM Temp_FingerPrint tmp
    GROUP BY TransDate, tmp.SubscriberId
    ON DUPLICATE KEY UPDATE TotalTrans = TotalTrans + COUNT(tmp.SubscriberId);
END$$
DELIMITER ;
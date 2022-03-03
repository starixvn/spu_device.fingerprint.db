/*<info serverAlias="xxxx" databaseType="2" executers="fpsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `FPS_FP_Transform_FingerPrint_Insert`;
DELIMITER $$

CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `FPS_FP_Transform_FingerPrint_Insert`(
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
            
		Param's Explanation (filtered by):	

		Example:
			- CALL FPS_FP_Transform_FingerPrint_Insert('[{"FingerPrintCode":"dddddd","SessionKey":"ddddd","SubscriberId":2,"Attribute":"dfsfsafsaf","UserAgentCode":"fdsafasfasf","UserAgentAttribute":"dddddd","CookieCode":"1","Flagged":"Human","Url":"fdsafdsaf"}]');
			
	*/
    DROP TEMPORARY TABLE IF EXISTS Temp_FingerPrint;    
	CREATE TEMPORARY TABLE Temp_FingerPrint(
			FingerPrintCode				VARCHAR(200) 	NULL	
		,	SessionKey					VARCHAR(100) 	NULL
		,	SubscriberId				INT	 			NULL
		,	Attribute					LONGTEXT	 	NULL		
		,	UserAgentCode				VARCHAR(100)	NULL		
		,	UserAgentAttribute			LONGTEXT		NULL
		,	CookieCode 					BINARY(16)		NULL		
        ,	Flagged						VARCHAR(50)		NULL		
        ,	Url							VARCHAR(100)	NULL
		
		,	INDEX	IX_Temp_FingerPrint_UserAgentCode(UserAgentCode)
    );     
    
    INSERT INTO Temp_FingerPrint(FingerPrintCode, SessionKey, SubscriberId, Attribute, UserAgentCode, UserAgentAttribute, CookieCode, Flagged, Url)
	SELECT	tmp.FingerPrintCode
		,	tmp.SessionKey
		,	tmp.SubscriberId
		,	tmp.Attribute
        ,	tmp.UserAgentCode
        ,	tmp.UserAgentAttribute
        ,	tmp.CookieCode
        ,	tmp.Flagged
        ,	tmp.Url
	FROM	JSON_TABLE(
			ip_FingerPrint,
			 "$[*]" COLUMNS(
								FingerPrintCode			VARCHAR(200)	PATH "$.FingerPrintCode"       
							,	SessionKey				VARCHAR(100) 	PATH "$.SessionKey"   
							,	SubscriberId			INT 			PATH "$.SubscriberId"
							,	Attribute				LONGTEXT		PATH "$.Attribute"
							,	UserAgentCode			VARCHAR(100)	PATH "$.UserAgentCode"
							,	UserAgentAttribute		LONGTEXT		PATH "$.UserAgentAttribute"
							,	CookieCode				BINARY(16) 		PATH "$.CookieCode"							
                            ,	Flagged					VARCHAR(50) 	PATH "$.Flagged"
                            ,	Url						VARCHAR(100) 	PATH "$.Url"
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
    
    INSERT INTO FPS_FingerPrint.FingerPrint(FingerPrintCode, SubscriberId, UserAgentCode, CookieCode, SessionKey, Flagged, Url, CreatedDate, ModifiedDate)
	SELECT	tmp.FingerPrintCode
		,	tmp.SubscriberId
		,	tmp.UserAgentCode
		,	tmp.CookieCode
		,	tmp.SessionKey
		,	tmp.Flagged
		,	tmp.Url
		,	NOW() AS CreatedDate
		,	NOW() AS CreatedDate
	FROM Temp_FingerPrint tmp;

END$$
DELIMITER ;
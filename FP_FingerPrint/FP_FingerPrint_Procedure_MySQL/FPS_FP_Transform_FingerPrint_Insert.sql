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
			- CALL FPS_FP_InsertFingerPrint(100);
			
	*/
    DROP TEMPORARY TABLE IF EXISTS Temp_FingerPrint;
    
	CREATE TEMPORARY TABLE Temp_FingerPrint(
			FingerPrint					VARCHAR(200) 	NOT NULL	
		,	SessionKey					VARCHAR(100) 	NOT NULL
		,	SubscriberId				INT	 			NOT NULL
		,	Attributes					LONGTEXT	 	NOT NULL		
		,	DeviceCode					VARCHAR(100)	NOT NULL		
		,	DeviceInfo					LONGTEXT		NOT NULL
		,	CookieId					BIGINT			NOT NULL		
        ,	Flagged						VARCHAR(50)		NOT NULL		
        ,	Url							VARCHAR(100)	NOT NULL
    );     
    
    INSERT INTO Temp_FingerPrint(FingerPrint, SessionKey, SubscriberId, Attributes, DeviceCode, DeviceInfo, CookieId, Flagged, Url)
	SELECT	tmp.FingerPrint
		,	tmp.SessionKey
		,	tmp.SubscriberId
		,	tmp.Attributes
        ,	tmp.DeviceCode
        ,	tmp.DeviceInfo
        ,	tmp.CookieId
        ,	tmp.Flagged
        ,	tmp.Url
	FROM	JSON_TABLE(
			ip_FingerPrint,
			 "$[*]" COLUMNS(
								FingerPrint				VARCHAR(200)	PATH "$.FingerPrint"       
							,	SessionKey				VARCHAR(100) 	PATH "$.SessionKey"   
							,	SubscriberId			INT 			PATH "$.SubscriberId"
							,	Attributes				LONGTEXT		PATH "$.Attributes"
							,	DeviceCode				VARCHAR(100)	PATH "$.DeviceCode"
							,	DeviceInfo				LONGTEXT		PATH "$.DeviceInfo"
							,	CookieId				BIGINT 			PATH "$.CookieId"							
                            ,	Flagged					VARCHAR(50) 	PATH "$.Flagged"
                            ,	Url						VARCHAR(100) 	PATH "$.Url"
				)
		   ) AS  tmp; 
      
    INSERT INTO FPS_FingerPrint.RawUserAgent (
				Code
				, Attributes
				, CreatedDate
				, ModifiedDate)	
	(SELECT tmp.DeviceCode, tmp.DeviceInfo, NOW(), NOW() 
		FROM FPS_FingerPrint.RawUserAgent ua 
        RIGHT JOIN Temp_FingerPrint tmp ON ua.Code = tmp.DeviceCode)
	ON DUPLICATE KEY UPDATE ModifiedDate = NOW();
    
    INSERT INTO FPS_FingerPrint.RawFingerPrint(
						FingerPrintCode
					, 	Attributes
					, 	CreatedDate
					, 	ModifiedDate)
	SELECT tmp.FingerPrint, tmp.Attributes, NOW(), NOW() FROM Temp_FingerPrint tmp
	ON DUPLICATE KEY UPDATE ModifiedDate = NOW();
    
    INSERT INTO FPS_FingerPrint.FingerPrint(
								FingerPrintCode
							, 	SubscriberId                        							
                            ,	UserAgentCode
                            ,	CookieId
							, 	SessionKey
							, 	Flagged
							, 	Url
							, 	CreatedDate
							, 	ModifiedDate)
	SELECT tmp.FingerPrint, tmp.SubscriberId, tmp.DeviceCode, tmp.CookieId, tmp.SessionKey, tmp.Flagged, tmp.Url, NOW(), NOW() FROM Temp_FingerPrint tmp;
     
	DROP TEMPORARY TABLE IF EXISTS Temp_FingerPrint;
END$$
DELIMITER ;

GRANT EXECUTE ON PROCEDURE FPS_FingerPrint.FPS_FP_Transform_FingerPrint_Insert TO 'fpsServiceAdmin'@'%';
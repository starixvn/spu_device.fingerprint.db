/*<info serverAlias="xxxx" databaseType="2" executers="fpsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `FPS_FP_Transform_FingerPrintCookie_Update`;
DELIMITER $$

CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `FPS_FP_Transform_FingerPrintCookie_Update`(
		IN ip_CookieId		BIGINT        
    ,	IN ip_FingerPrint	VARCHAR(100)
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
			- CALL FPS_FP_Transform_FingerPrintCookie_Update(ip_CookieId,ip_FingerPrint);
			
	*/
    DECLARE rawFingerPrintId BIGINT DEFAULT 0;
    DECLARE cookie VARCHAR(100);
        
	SELECT rfp.Id INTO rawFingerPrintId 
    FROM FPS_FingerPrint.RawFingerPrint rfp 
    WHERE rfp.FingerPrint = ip_FingerPrint;
    
    IF rawFingerPrintId != 0 THEN
    BEGIN
			IF EXISTS(SELECT 1 FROM FPS_FingerPrint.FingerPrintCookie fpc WHERE fpc.RawFingerPrintId = rawFingerPrintId AND fpc.CookieId = ip_CookieId) THEN
            BEGIN
				UPDATE FPS_FingerPrint.FingerPrintCookie
                SET ModifiedDate = NOW()
                WHERE FingerPrintId = rawFingerPrintId AND CookieId = ip_CookieId;
            END;
            ELSE
            BEGIN
				SELECT BIN_TO_UUID(Code) INTO cookie FROM FPS_FingerPrint.Cookie WHERE Id = ip_CookieId;
                
				INSERT INTO FPS_FingerPrint.FingerPrintCookie(RawFingerPrintId, FingerPrintCode, CookieId, Cookie, CreatedDate, ModifiedDate)
                VALUE(rawFingerPrintId, ip_FingerPrint, ip_CookieId, cookie, NOW(), NOW());
            END;
            END IF;
    END;    
    END IF;
END$$
DELIMITER ;

GRANT EXECUTE ON PROCEDURE FPS_FingerPrint.FPS_FP_Transform_FingerPrintCookie_Update TO 'fpsServiceAdmin'@'%';
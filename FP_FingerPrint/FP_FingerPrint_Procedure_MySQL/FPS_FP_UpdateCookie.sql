/*<info serverAlias="xxxx" databaseType="2" executers="fpsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `FPS_FP_UpdateCookie`;
DELIMITER $$

CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `FPS_FP_UpdateCookie`(
		IN ip_Cookie VARCHAR(100)
    ,	OUT op_Id BIGINT
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
			- CALL FPS_FP_UpdateCookie(100);
			
	*/
    DECLARE cookieId INT DEFAULT 0;	

	SELECT Id into cookieId
	FROM Cookie
	WHERE code = UUID_TO_BIN(ip_Cookie);
        
    IF cookieId <= 0 THEN
		BEGIN
			INSERT INTO FPS_FingerPrint.Cookie(code, createdDate, modifiedDate)
            VALUE(UUID_TO_BIN(ip_Cookie), NOW(), NOW());
                                    
            SELECT Id INTO op_Id 
            FROM  FPS_FingerPrint.Cookie 
            WHERE code = UUID_TO_BIN(ip_Cookie);
		END;
    ELSE
		BEGIN
			UPDATE FPS_FingerPrint.Cookie
            SET ModifiedDate = NOW()
            WHERE Id = cookieId;                        
            
            SET op_Id = cookieId;
		END;
    END IF;
END$$
DELIMITER ;

GRANT EXECUTE ON PROCEDURE FPS_FingerPrint.FPS_FP_UpdateCookie TO 'fpsServiceAdmin'@'%';
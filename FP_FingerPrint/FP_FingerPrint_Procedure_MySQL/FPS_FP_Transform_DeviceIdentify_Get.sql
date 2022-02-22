/*<info serverAlias="xxxx" databaseType="2" executers="fpsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `FPS_FP_Transform_DeviceIdentify_Get`;
DELIMITER $$

CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `FPS_FP_Transform_DeviceIdentify_Get`(
		ip_BatchSize 	INT,
        ip_Offset		BIGINT
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20220222@Terry.Nguyen
		Task :		
		DB:			FPS_FingerPrint
		Original:

		Revisions:
            
		Param's Explanation (filtered by):	

		Example:
			- CALL FPS_FP_Transform_DeviceIdentify_Get(100);
			
	*/
    
    DECLARE lv_currentDate DATETIME DEFAULT NOW();
    
	SELECT trans.Id
		, trans.FingerPrintCode
        , trans.CookieId
        , lv_currentDate
        , lv_currentDate
    FROM FPS_FingerPrint.Transaction trans
    WHERE trans.Id > ip_Offset AND trans.DeviceId IS NULL    
    LIMIT ip_BatchSize;  
END$$
DELIMITER ;

GRANT EXECUTE ON PROCEDURE FPS_FingerPrint.FPS_FP_Transform_DeviceIdentify_Get TO 'fpsServiceAdmin'@'%';
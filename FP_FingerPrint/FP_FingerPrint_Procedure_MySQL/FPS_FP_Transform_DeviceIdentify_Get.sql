/*<info serverAlias="xxxx" databaseType="2" executers="fpsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `FPS_FP_Transform_DeviceIdentify_Get`;
DELIMITER $$

CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `FPS_FP_Transform_DeviceIdentify_Get`(
		ip_BatchSize 	INT,
        ip_OffsetName	VARCHAR(100)
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
			- CALL FPS_FP_Transform_DeviceIdentify_Get(100, 'ABC');
			
	*/
    
    DECLARE lv_currentDate DATETIME DEFAULT NOW();
    DECLARE lv_offsetValue BIGINT;
    
    SELECT OffsetValue 
    INTO lv_offsetValue
    FROM FPS_FingerPrint.Offset o
    WHERE OffsetName = ip_OffsetName
    LIMIT 1;
    
	SELECT trans.Id
		, trans.FingerPrintCode
        , trans.CookieId
        , lv_currentDate
        , lv_currentDate
    FROM FPS_FingerPrint.Transaction trans
    WHERE trans.Id > lv_offsetValue 
		AND trans.DeviceId IS NULL    
	ORDER BY trans.Id
    LIMIT ip_BatchSize;  
END$$
DELIMITER ;

GRANT EXECUTE ON PROCEDURE FPS_FingerPrint.FPS_FP_Transform_DeviceIdentify_Get TO 'fpsServiceAdmin'@'%';
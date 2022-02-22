/*<info serverAlias="xxxx" databaseType="2" executers="fpsService" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `FPS_FP_Core_Offset_UpdateOffsetValue`;
DELIMITER $$

CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `FPS_FP_Core_Offset_UpdateOffsetValue`(
		ip_OffsetName 	VARCHAR(100),
        ip_OffsetValue	BIGINT
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20220222@Jonathan.Doan
		Task :		
		DB:			FPS_FP_Core_Offset_UpdateOffsetValue
		Original:

		Revisions:
            
		Param's Explanation (filtered by):	

		Example:
			- CALL FPS_FP_Core_Offset_UpdateOffsetValue('RawTransaction123', 1234);
			
	*/
   
    UPDATE FPS_FingerPrint.Offset
    SET OffsetValue = ip_OffsetValue
    WHERE OffsetName = ip_OffsetName;
    
END$$
DELIMITER ;

GRANT EXECUTE ON PROCEDURE FPS_FingerPrint.FPS_FP_Core_Offset_UpdateOffsetValue TO 'fpsService'@'%';
/*<info serverAlias="FPSDC-FPS_FingerPrint" databaseType="2" executers="fpsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `FPS_FP_Core_Offset_UpdateOffsetValue`;
DELIMITER $$

CREATE DEFINER=`fpsOwner`@`%` PROCEDURE `FPS_FP_Core_Offset_UpdateOffsetValue`(
		ip_Id 			BIGINT UNSIGNED
	,	ip_OffsetValue	BIGINT UNSIGNED
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20220222@Jonathan.Doan
		Task :		
		DB:			FPS_FP_Core_Offset_UpdateOffsetValue
		Original:

		Revisions:
            - 20220307@Terry.Nguyen: Created [Redmine ID: #162668]
            
		Param's Explanation (filtered by):	

		Example:
			- CALL FPS_FP_Core_Offset_UpdateOffsetValue('RawTransaction123', 1234);
			
	*/
	/*******LOG TEST********************/
    IF (SELECT ofs.OffsetValue FROM FPS_FingerPrint.Offset AS ofs WHERE Id = 7) = 1 THEN		
		INSERT INTO CTS_Log.FPSLog(SpName, JsonString, OtherText, InsertTime)
		SELECT 'FPS_FP_Core_Offset_UpdateOffsetValue', NULL,CONCAT('ip_Id:',ip_Id,', ip_OffsetValue:',ip_OffsetValue), CURRENT_TIMESTAMP();
	END IF;
    /*******LOG TEST********************/
   
    UPDATE FPS_FingerPrint.Offset
    SET OffsetValue = ip_OffsetValue
    WHERE Id = ip_Id;
    
END$$
DELIMITER ;
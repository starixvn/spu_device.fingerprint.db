/*<info serverAlias="xxxx" databaseType="2" executers="fpsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `FPS_FP_Transform_RawTrans_Completed`;
DELIMITER $$

CREATE DEFINER=`FPSOwner`@`%` PROCEDURE `FPS_FP_Transform_RawTrans_Completed`(		
		ip_OffsetId		INT,
        ip_Offset		BIGINT
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20220221@Terry.Nguyen
		Task :		
		DB:			FPS_FP_GetRawTrans
		Original:

		Revisions:
            
		Param's Explanation (filtered by):	

		Example:
			- CALL FPS_FP_Transform_RawTrans_Completed(1234);
			
	*/
   
   UPDATE FPS_FingerPrint.Offset SET OffsetValue = ip_Offset WHERE Id = ip_OffsetId;
    
END$$
DELIMITER ;

GRANT EXECUTE ON PROCEDURE FPS_FingerPrint.FPS_FP_Transform_RawTrans_Completed TO 'fpsServiceAdmin'@'%';
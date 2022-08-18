/*<info serverAlias="FPSDC-FPS_FingerPrint" databaseType="2" executers="fpsService" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `FPS_FP_Transform_ForceMergeTransaction_Get`;
DELIMITER $$

CREATE DEFINER=`fpsOwner`@`%` PROCEDURE `FPS_FP_Transform_ForceMergeTransaction_Get`(
		ip_Size		INT
	,   ip_Retry	INT
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20220325@Terry.Nguyen
		Task :		
		DB:			FPS_FingerPrint
		Original:

		Revisions:
			- 20220307@Terry.Nguyen: Created [Redmine ID: #162668]
            
		Param's Explanation (filtered by):	

		Example:
			- CALL FPS_FP_Transform_ForceMergeTransaction_Get(100,1);
			
	*/
    
    /*******LOG TEST********************/
    IF (SELECT ofs.OffsetValue FROM FPS_FingerPrint.Offset AS ofs WHERE Id = 7) = 1 THEN		
		INSERT INTO CTS_Log.FPSLog(SpName, JsonString, OtherText, InsertTime)
		SELECT 'FPS_FP_Transform_ForceMergeTransaction_Get', NULL,CONCAT('ip_Size:',ip_Size,'; ip_Retry:',ip_Retry), CURRENT_TIMESTAMP();
	END IF;
    /*******LOG TEST********************/
    
    SELECT	trans.Id
		,	trans.TransKey 
    FROM FPS_FingerPrint.TransactionDevice AS trans 
	WHERE trans.Retry > ip_Retry
    ORDER BY trans.Id
    LIMIT ip_Size;
   
END$$
DELIMITER ;
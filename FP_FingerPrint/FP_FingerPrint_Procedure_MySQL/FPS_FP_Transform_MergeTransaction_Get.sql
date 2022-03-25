/*<info serverAlias="FPSDC-FPS_FingerPrint" databaseType="2" executers="fpsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `FPS_FP_Transform_MergeTransaction_Get`;
DELIMITER $$

CREATE DEFINER=`fpsOwner`@`%` PROCEDURE `FPS_FP_Transform_MergeTransaction_Get`(
		ip_Size		INT
	,   ip_Retry	INT
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20220224@Terry.Nguyen
		Task :		
		DB:			FPS_FingerPrint
		Original:

		Revisions:
			- 20220307@Terry.Nguyen: Created [Redmine ID: #162668]
            
		Param's Explanation (filtered by):	

		Example:
			- CALL FPS_FP_Transform_MergeTransaction_Get(100,1);
			
	*/
    
    /*******LOG TEST********************/
    INSERT INTO FPS_FingerPrint.Test_LOG(SpName, JsonString, OtherText, InsertTime)
    SELECT 'FPS_FP_Transform_MergeTransaction_Get', NULL,CONCAT('ip_Size:',ip_Size,'; ip_Retry:',ip_Retry), CURRENT_TIMESTAMP();
    /*******LOG TEST********************/
    
    SELECT	trans.Id
		,	trans.TransKey 
    FROM FPS_FingerPrint.TransactionDevice AS trans 
	WHERE trans.Retry <= ip_Retry
    LIMIT ip_Size;
   
END$$
DELIMITER ;
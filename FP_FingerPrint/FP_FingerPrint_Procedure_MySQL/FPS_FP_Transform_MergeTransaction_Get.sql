/*<info serverAlias="FPSDC-FPS_FingerPrint" databaseType="2" executers="fpsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `FPS_FP_Transform_MergeTransaction_Get`;
DELIMITER $$

CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `FPS_FP_Transform_MergeTransaction_Get`(
		ip_Size INT,
        ip_Retry INT
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20220224@Terry.Nguyen
		Task :		
		DB:			FPS_FingerPrint
		Original:

		Revisions:
            
		Param's Explanation (filtered by):	

		Example:
			- CALL FPS_FP_Transform_MergeTransaction_Get(100);
			
	*/
    
    SELECT trans.Id, trans.TransKey 
    FROM FPS_FingerPrint.TransactionDevice trans 
	WHERE trans.Retry = ip_Retry
    LIMIT ip_Size;
   
END$$
DELIMITER ;

GRANT EXECUTE ON PROCEDURE FPS_FingerPrint.FPS_FP_Transform_MergeTransaction_Get TO 'fpsServiceAdmin'@'%';
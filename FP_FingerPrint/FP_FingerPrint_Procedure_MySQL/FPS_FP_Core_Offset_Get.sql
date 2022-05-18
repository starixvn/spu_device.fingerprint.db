/*<info serverAlias="FPSDC-FPS_FingerPrint" databaseType="2" executers="fpsService" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `FPS_FP_Core_Offset_Get`;
DELIMITER $$

CREATE DEFINER=`fpsOwner`@`%` PROCEDURE `FPS_FP_Core_Offset_Get`(
		ip_OffsetName VARCHAR(100)
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20220218@Terry.Nguyen
		Task :		
		DB:			FPS_FP_GetOffset
		Original:

		Revisions: 
			- 20220307@Terry.Nguyen: Created [Redmine ID: #162668]
            
		Param's Explanation (filtered by):	

		Example:
			- CALL FPS_FP_GetOffset('RawTransaction');
			
	*/
   
    SELECT	off.Id
		,	off.OffsetName
		,	off.OffsetValue 
    FROM FPS_FingerPrint.Offset AS off 
    WHERE off.OffsetName = ip_OffsetName;
    
END$$
DELIMITER ;

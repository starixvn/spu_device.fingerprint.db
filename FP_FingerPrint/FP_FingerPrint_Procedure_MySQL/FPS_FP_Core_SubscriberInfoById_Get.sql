/*<info serverAlias="FPSDC-FPS_FingerPrint" databaseType="2" executers="fpsService" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `FPS_FP_Core_SubscriberInfoById_Get`;
DELIMITER $$

CREATE DEFINER=`fpsOwner`@`%` PROCEDURE `FPS_FP_Core_SubscriberInfoById_Get`(
		ip_SubscriberId INT
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20220218@Terry.Nguyen
		Task :		
		DB:			FPS_FingerPrint
		Original:

		Revisions:
			- 20220307@Terry.Nguyen: Created [Redmine ID: #162668]
            
		Param's Explanation (filtered by):	

		Example:
			- CALL FPS_FP_GetSubscriberInfoById(2);
			
	*/
     SELECT	sub.Id AS SubscriberId
		,	sub.Name AS SubscriberName 
    FROM   FPS_FingerPrint.Subscribers AS sub           
    WHERE sub.Id = ip_SubscriberId 
		AND sub.IsActive = 1;
END$$
DELIMITER ;

GRANT EXECUTE ON PROCEDURE FPS_FingerPrint.FPS_FP_Core_SubscriberInfoById_Get TO 'fpsService'@'%';
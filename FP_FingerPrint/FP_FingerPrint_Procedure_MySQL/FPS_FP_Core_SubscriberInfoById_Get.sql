/*<info serverAlias="xxxx" databaseType="2" executers="fpsService" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `FPS_FP_Core_SubscriberInfoById_Get`;
DELIMITER $$

CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `FPS_FP_Core_SubscriberInfoById_Get`(
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
            
		Param's Explanation (filtered by):	

		Example:
			- CALL FPS_FP_GetSubscriberInfoById(2);
			
	*/
     SELECT	sub.Id as SubscriberId
		,	sub.Name as SubscriberName 
    FROM   FPS_FingerPrint.Subscribers sub           
    WHERE sub.Id = ip_SubscriberId and sub.Active = 1;
END$$
DELIMITER ;

GRANT EXECUTE ON PROCEDURE FPS_FingerPrint.FPS_FP_Core_SubscriberInfoById_Get TO 'fpsService'@'%';
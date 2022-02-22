/*<info serverAlias="xxxx" databaseType="2" executers="fpsService" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `FPS_FP_GetSubscriberInfoById`;
DELIMITER $$

CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `FPS_FP_GetSubscriberInfoById`(
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
    SELECT	ss.SubscriberId
		,	sub.Name as SubscriberName
        , 	sv.Id as DomainId
        ,	sv.Domain as DomainName
        , 	ss.IsActived
        ,	ss.IsMain        
    FROM   FPS_FingerPrint.SubscriberServer ss        
    INNER JOIN FPS_FingerPrint.Subscribers sub ON sub.Id = ss.SubscriberId
    INNER JOIN FPS_FingerPrint.HttpServers sv ON sv.Id = ss.HttpServerId
    WHERE sub.Id = ip_SubscriberId; 
END$$
DELIMITER ;

GRANT EXECUTE ON PROCEDURE FPS_FingerPrint.FPS_FP_GetSubscriberInfoById TO 'fpsService'@'%';
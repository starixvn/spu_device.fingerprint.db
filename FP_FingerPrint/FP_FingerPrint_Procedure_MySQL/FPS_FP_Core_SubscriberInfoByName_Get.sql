/*<info serverAlias="FPSDC-FPS_FingerPrint" databaseType="2" executers="fpsService" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `FPS_FP_Core_SubscriberInfoByName_Get`;
DELIMITER $$

CREATE DEFINER=`fpsOwner`@`%` PROCEDURE `FPS_FP_Core_SubscriberInfoByName_Get`(
		ip_SubscriberName VARCHAR(45)
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20220314@Jonathan.Doan
		Task :		
		DB:			FPS_FingerPrint
		Original:

		Revisions:
			- 20220314@Jonathan.Doan: Created [Redmine ID: #162668]
            
		Param's Explanation (filtered by):	

		Example:
			- CALL FPS_FP_Core_SubscriberInfoByName_Get('Alpha');
			
	*/
     SELECT	sub.Id AS SubscriberId
		,	sub.Name AS SubscriberName 
    FROM   FPS_FingerPrint.Subscribers AS sub           
    WHERE sub.Name = ip_SubscriberName 
		AND sub.IsActive = 1;
END$$
DELIMITER ;
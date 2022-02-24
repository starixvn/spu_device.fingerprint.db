/*<info serverAlias="xxxx" databaseType="2" executers="fpsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `FPS_FP_Transform_RawTrans_Get`;
DELIMITER $$

CREATE DEFINER=`FPSOwner`@`%` PROCEDURE `FPS_FP_Transform_RawTrans_Get`(
		ip_BatchSize 	INT,
        ip_OffsetName	VARCHAR(100),
        ip_Retry		INT
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
			- CALL FPS_FP_GetRawTrans(100, 1234);
			
	*/
    DECLARE lv_offsetValue BIGINT;
    
    SELECT off.OffsetValue INTO lv_offsetValue
    FROM FPS_FingerPrint.Offset off
    WHERE off.OffsetName = ip_OffsetName;	
	   
    SELECT 
		trans.Id
    , 	trans.SessionKey
    , 	trans.CustId
    , 	trans.SubAccId
    , 	trans.LoginName
    , 	trans.SubscriberId
    , 	trans.Transtime
    , 	trans.ClientIP
    , 	trans.UserAgent
    , 	trans.Url
    , 	trans.TransKey
    , 	trans.Action
    ,	trans.Retry
    FROM FPS_FingerPrint.RawTransaction trans 
    WHERE trans.Id >= lv_offsetValue AND trans.Retry < ip_Retry LIMIT ip_BatchSize;
    
END$$
DELIMITER ;

GRANT EXECUTE ON PROCEDURE FPS_FingerPrint.FPS_FP_Transform_RawTrans_Get TO 'fpsServiceAdmin'@'%';
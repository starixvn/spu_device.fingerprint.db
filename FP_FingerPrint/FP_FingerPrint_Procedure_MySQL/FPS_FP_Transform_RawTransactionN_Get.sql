/*<info serverAlias="FPSDC-FPS_FingerPrint" databaseType="2" executers="fpsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `FPS_FP_Transform_RawTransactionN_Get`;
DELIMITER $$
CREATE DEFINER=`FPSOwner`@`%` PROCEDURE `FPS_FP_Transform_RawTransactionN_Get`(
		ip_BatchSize 	INT,
        ip_OffsetId		INT
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20220221@Terry.Nguyen
		Task :		
		DB:			RawTransactionN
		Original:

		Revisions:
            
		Param's Explanation (filtered by):	

		Example:
			- CALL FPS_FP_Transform_RawTransactionN_Get(100, 1234);			
	*/
    DECLARE lv_offsetValue BIGINT;
    
    SELECT off.OffsetValue INTO lv_offsetValue
    FROM FPS_FingerPrint.Offset off
    WHERE off.Id = ip_OffsetId;	
   
    SELECT 
		trans.Id
    , 	trans.SessionKey
    , 	trans.CustId
    , 	trans.SubAccId
    , 	trans.LoginName
    , 	trans.SubAccId
    , 	trans.Transtime
    , 	trans.ClientIP
    , 	trans.UserAgent
    , 	trans.Url
    , 	trans.TransKey
    , 	trans.Action
    ,	trans.Retry
    FROM FPS_FingerPrint.RawTransaction trans 
		INNER JOIN FPS_FingerPrint.RawTransactionN transN ON trans.Id = transN.RawTransId
    WHERE trans.Id >= lv_offsetValue LIMIT ip_BatchSize;
    
END$$
DELIMITER ;

GRANT EXECUTE ON PROCEDURE FPS_FingerPrint.FPS_FP_Transform_RawTransactionN_Get TO 'fpsServiceAdmin'@'%';
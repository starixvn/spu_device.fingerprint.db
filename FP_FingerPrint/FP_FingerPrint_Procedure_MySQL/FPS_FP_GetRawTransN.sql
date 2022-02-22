/*<info serverAlias="xxxx" databaseType="2" executers="fpsService" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `FPS_FP_GetRawTransN`;
DELIMITER $$

CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `FPS_FP_GetRawTransN`(
		ip_BatchSize 	INT,
        ip_Offset		BIGINT
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
			- CALL FPS_FP_GetRawTransN(100, 1234);			
	*/
   
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
    WHERE transN.RawTransId >= ip_Offset LIMIT ip_BatchSize;
    
END$$
DELIMITER ;

GRANT EXECUTE ON PROCEDURE FPS_FingerPrint.FPS_FP_GetRawTransN TO 'fpsService'@'%';
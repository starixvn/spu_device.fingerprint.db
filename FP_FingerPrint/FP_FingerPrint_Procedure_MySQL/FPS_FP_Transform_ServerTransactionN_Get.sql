/*<info serverAlias="FPSDC-FPS_FingerPrint" databaseType="2" executers="fpsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `FPS_FP_Transform_ServerTransactionN_Get`;

DELIMITER $$
CREATE DEFINER=`fpsOwner`@`%` PROCEDURE `FPS_FP_Transform_ServerTransactionN_Get`(
		    ip_BatchSize 	INT
    ,       ip_OffsetId		INT
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20220221@Terry.Nguyen
		Task :		
		DB:			RawTransactionN
		Original:

		Revisions:
			- 20220307@Terry.Nguyen: Created [Redmine ID: #162668]
            
		Param's Explanation (filtered by):	

		Example:
			- CALL FPS_FP_Transform_RawTransactionN_Get(100, 1234);			
	*/
    DECLARE lv_offsetValue BIGINT;
    
    /*******LOG TEST********************/
    INSERT INTO FPS_FingerPrint.Test_LOG(SpName, JsonString, OtherText, InsertTime)
    SELECT 'FPS_FP_Transform_ServerTransactionN_Get', NULL,CONCAT('ip_BatchSize:',ip_BatchSize,'; ip_OffsetId:',ip_OffsetId), CURRENT_TIMESTAMP();
    /*******LOG TEST********************/
    
    SELECT off.OffsetValue 
    INTO lv_offsetValue
    FROM FPS_FingerPrint.Offset AS off
    WHERE off.Id = ip_OffsetId;	
   
    SELECT  trans.Id
        , 	trans.SessionKey
        , 	trans.CustId
        , 	trans.SubAccId
        , 	trans.LoginName
        , 	trans.SubAccId
        , 	trans.TransTime
        , 	trans.ClientIP
        , 	trans.UserAgent
        , 	trans.Url
        , 	trans.TransKey
        , 	trans.Action
        ,	trans.Retry
    FROM FPS_FingerPrint.ServerTransaction AS trans 
		INNER JOIN FPS_FingerPrint.ServerTransactionN transN ON trans.Id = transN.ServerTransId
    WHERE trans.Id >= lv_offsetValue 
    LIMIT ip_BatchSize;
    
END$$
DELIMITER ;
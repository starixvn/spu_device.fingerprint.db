/*<info serverAlias="FPSDC-FPS_FingerPrint" databaseType="2" executers="fpsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `FPS_FP_Transform_ServerTransaction_Get`;
DELIMITER $$

CREATE DEFINER=`fpsOwner`@`%` PROCEDURE `FPS_FP_Transform_ServerTransaction_Get`(
		ip_BatchSize 	INT
    ,   ip_OffsetId		INT
    ,   ip_Retry		INT
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20220221@Terry.Nguyen
		Task :		
		DB:			FPS_FP_GetRawTrans
		Original:

		Revisions:
			- 20220307@Terry.Nguyen: Created [Redmine ID: #162668]
            
		Param's Explanation (filtered by):	

		Example:
			- CALL FPS_FP_Transform_ServerTransaction_Get(100, 1234,1);
			
	*/
    DECLARE lv_offsetValue BIGINT;
    
    /*******LOG TEST********************/
    IF (SELECT ofs.OffsetValue FROM FPS_FingerPrint.Offset AS ofs WHERE Id = 7) = 1 THEN		
		INSERT INTO CTS_Log.FPSLog(SpName, JsonString, OtherText, InsertTime)
		SELECT 'FPS_FP_Transform_ServerTransaction_Get', NULL,CONCAT('ip_BatchSize:',ip_BatchSize,'; ip_OffsetId:',ip_OffsetId,'; ip_Retry:',ip_Retry), CURRENT_TIMESTAMP();
	END IF;
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
        , 	trans.SubscriberId
        , 	trans.Transtime
        , 	trans.ClientIP
        , 	trans.UserAgentId
        , 	trans.UserAgent
        , 	trans.Url
        , 	trans.TransKey
        , 	trans.Action
        ,	trans.Retry
    FROM FPS_FingerPrint.ServerTransaction AS trans 
    WHERE trans.Id >= lv_offsetValue 
        AND trans.Retry < ip_Retry 
    LIMIT ip_BatchSize;
    
END$$
DELIMITER ;

/*<info serverAlias="FPSDC-FPS_FingerPrint" databaseType="2" executers="fpsService" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `FPS_FP_Transform_BrowserInfoFlaggedDCS_Get`;
DELIMITER $$

CREATE DEFINER=`fpsOwner`@`%` PROCEDURE `FPS_FP_Transform_BrowserInfoFlaggedDCS_Get`(
		ip_BatchSize 	INT
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	202200811@Jonathan.Doan
		Task :		
		DB:			FPS_FingerPrint
		Original:

		Revisions:
            - 20220811@Jonathan.Doan: Created [Redmine ID: #176547]
            
		Param's Explanation (filtered by):	

		Example:
			- CALL FPS_FP_Transform_BrowserInfoFlaggedDCS_Get(100);
			
	*/
    DECLARE lv_offsetValue BIGINT;
    
    /*******LOG TEST********************/
    IF (SELECT ofs.OffsetValue FROM FPS_FingerPrint.Offset AS ofs WHERE Id = 7) = 1 THEN		
		INSERT INTO CTS_Log.FPSLog(SpName, JsonString, OtherText, InsertTime)
		SELECT 'FPS_FP_Transform_BrowserInfoFlaggedDCS_Get', NULL,CONCAT('ip_BatchSize:',ip_BatchSize), CURRENT_TIMESTAMP();
	END IF;
    /*******LOG TEST********************/
	   
    SELECT trans.BrowserInfoId AS Id
	FROM FPSTesting.FP_RawTransaction AS trans
	WHERE trans.BrowserInfoId IS NOT NULL 
		AND trans.Flagged IS NULL
	ORDER BY trans.CreatedDate
    LIMIT ip_BatchSize;
    
END$$
DELIMITER ;

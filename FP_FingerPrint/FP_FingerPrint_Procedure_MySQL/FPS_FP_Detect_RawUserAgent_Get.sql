/*<info serverAlias="FPSDC-FPS_FingerPrint" databaseType="2" executers="fpsService" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `FPS_FP_Detect_RawUserAgent_Get`;
DELIMITER $$

CREATE DEFINER=`fpsOwner`@`%` PROCEDURE `FPS_FP_Detect_RawUserAgent_Get`(
		ip_BatchSize 	INT
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20220406@Jonathan.Doan
		Task :		
		DB:			FPS_FingerPrint
		Original:

		Revisions:
			- 20220406@Jonathan.Doan: Created [Redmine ID: #162668]
			- 20220809@Jonathan.Doan: HF - Add service parse UA [Redmine ID: #176448]
            
		Param's Explanation (filtered by):	

		Example:
			- CALL FPS_FP_Detect_RawUserAgent_Get(100,3);
			
	*/
    
    /*******LOG TEST********************/
    IF (SELECT ofs.OffsetValue FROM FPS_FingerPrint.Offset AS ofs WHERE ofs.Id = 7) = 1 THEN		
		INSERT INTO CTS_Log.FPSLog(SpName, JsonString, OtherText, InsertTime)
		SELECT 'FPS_FP_Detect_RawUserAgent_Get', NULL, CONCAT('ip_BatchSize:',ip_BatchSize), CURRENT_TIMESTAMP();
	END IF;
    /*******LOG TEST********************/
    
    SELECT  ua.Id,
			ua.UserAgentCode,
			ua.UserAgent
    FROM FPS_FingerPrint.RawUserAgent AS ua 
    WHERE ua.Brand IS NULL
    LIMIT ip_BatchSize;
          
END$$
DELIMITER ;

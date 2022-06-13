/*<info serverAlias="FPSDC-FPS_FingerPrint" databaseType="2" executers="fpsService" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `FPS_FP_Transform_BrowserInfo_Get`;
DELIMITER $$

CREATE DEFINER=`fpsOwner`@`%` PROCEDURE `FPS_FP_Transform_BrowserInfo_Get`(
		ip_BatchSize 	INT
    ,   ip_OffsetId		INT
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20220601@Jonathan.Doan
		Task :		
		DB:			FPS_FingerPrint
		Original:

		Revisions:
			- 20220601@Jonathan.Doan: Created [Redmine ID: #172167]
            
		Param's Explanation (filtered by):	

		Example:
			- CALL FPS_FP_Transform_BrowserInfo_Get(1, 9);
			
	*/
    DECLARE lv_offsetValue BIGINT;
    
    /*******LOG TEST********************/
    IF (SELECT ofs.OffsetValue FROM FPS_FingerPrint.Offset AS ofs WHERE Id = 7) = 1 THEN		
		INSERT INTO CTS_Log.FPSLog(SpName, JsonString, OtherText, InsertTime)
		SELECT 'FPS_FP_Transform_BrowserInfo_Get', NULL,CONCAT('ip_BatchSize:',ip_BatchSize,'; ip_OffsetId:',ip_OffsetId), CURRENT_TIMESTAMP();
	END IF;
    /*******LOG TEST********************/
    
    SELECT off.OffsetValue 
    INTO lv_offsetValue
    FROM FPS_FingerPrint.Offset AS off
    WHERE off.Id = ip_OffsetId;	
	   
    SELECT 	bi.Id
		,	bi.HeadlessScore
		,	bi.BrowserName
		,	bi.OSName
		,	bi.UserAgentId
		,	ua.UserAgent
		,	ua.ClientName AS UABrowserName
		,	ua.OSName AS UAOSName
		,	CASE WHEN ua.Brand IS NOT NULL THEN 1
				ELSE 0
			END AS IsParsed
    FROM FPS_FingerPrint.BrowserInfo AS bi
		INNER JOIN FPS_FingerPrint.RawUserAgent AS ua ON ua.Id = bi.RawUserAgentId
    WHERE bi.Id >= lv_offsetValue
    LIMIT ip_BatchSize;
    
END$$
DELIMITER ;

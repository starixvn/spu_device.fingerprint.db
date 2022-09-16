/*<info serverAlias="FPSDC-FPS_FingerPrint" databaseType="2" executers="fpsService" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `FPS_FP_Recover_FingerPrintAttributesEvolution_Get`;
DELIMITER $$

CREATE DEFINER=`fpsOwner`@`%` PROCEDURE `FPS_FP_Recover_FingerPrintAttributesEvolution_Get`(
		ip_FingerPrintIds 	LONGTEXT
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20220913@Jonathan.Doan
		Task :		
		DB:			FPS_FingerPrint
		Original:

		Revisions:
			- 20220913@Jonathan.Doan: Created [Redmine ID: #176820]
            
		Param's Explanation (filtered by):	

		Example:
			- CALL FPS_FP_Recover_FingerPrintAttributesEvolution_Get('1,2');
			
	*/
    
    
    DROP TEMPORARY TABLE IF EXISTS Temp_InputTrans;
    
    CREATE TEMPORARY TABLE Temp_InputTrans(
				Id 			BIGINT	NOT NULL PRIMARY KEY
    );
    
	SET @sql = CONCAT("INSERT INTO Temp_InputTrans (Id) VALUES ('", REPLACE(ip_FingerPrintIds, ",", "'),('"),"');");
	PREPARE stmt1 FROM @sql;
	EXECUTE stmt1;
    
    SELECT 	tmp.Id
		-- ,	ua.UserAgent
		,	fpa.OSName
		,	fpa.BrowserName
		,	fpa.BrowserVersion
		,	fpa.Platform
		,	fpa.LocalStorage
		,	fpa.DoNotTrack
		,	fpa.Cookies
		,	fpa.Canvas
		,	fpa.Fonts
		,	fpa.Vendor
		,	fpa.GLRenderer
		,	fpa.Plugins
		,	fpa.Languages
		,	fpa.Accept
		,	fpa.Encoding
		,	fpa.Headers
		,	fpa.Resolution
		,	fpa.Timezone
	FROM Temp_InputTrans AS tmp
		INNER JOIN FPS_FingerPrint.RawFingerPrint AS fp ON fp.Id = tmp.Id
		-- INNER JOIN FPS_FingerPrint.RawUserAgent AS ua ON ua.Id = fp.UserAgentId
		INNER JOIN FPS_FingerPrint.FingerPrintAttribute AS fpa ON fpa.FingerPrintCode = fp.FingerPrintCode
	ORDER BY tmp.Id;

END$$
DELIMITER ;

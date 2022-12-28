/*<info serverAlias="FPSDC-FPS_FingerPrint" databaseType="2" executers="fpsService" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `FPS_FP_Recover_TransactionEvolutionAttributes_Get`;
DELIMITER $$

CREATE DEFINER=`fpsOwner`@`%` PROCEDURE `FPS_FP_Recover_TransactionEvolutionAttributes_Get`(
		ip_FingerPrintIds 		LONGTEXT
	,	ip_BrowserFamilyCode	VARCHAR(64)
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
			- CALL FPS_FP_Recover_TransactionEvolutionAttributes_Get('2,3', '0728347210233b933365877664283ce5');
			
	*/
    
    
    DROP TEMPORARY TABLE IF EXISTS Temp_InputTrans;
    
    CREATE TEMPORARY TABLE Temp_InputTrans(
				Id 			BIGINT	NOT NULL PRIMARY KEY
    );
    
	SET @sql = CONCAT("INSERT INTO Temp_InputTrans (Id) VALUES ('", REPLACE(ip_FingerPrintIds, ",", "'),('"),"');");
	PREPARE stmt1 FROM @sql;
	EXECUTE stmt1;
    
    SELECT 	tmp.Id
		,	COALESCE(bis.UserAgent, '') AS UserAgent
		,	COALESCE(bis.BrowserFamilyCode, '') AS BrowserFamilyCode
		,	COALESCE(bis.OSName, '') AS OSName
		,	COALESCE(bis.BrowserName, '') AS BrowserName
		,	COALESCE(bis.BrowserVersion, '') AS BrowserVersion
		,	COALESCE(bis.Platform, '') AS Platform
		,	COALESCE(bis.Accept, '') AS Accept
		,	COALESCE(bis.Encoding, '') AS Encoding
		,	COALESCE(bis.Headers, '') AS Headers
		,	COALESCE(fpa.LocalStorage, -1) AS LocalStorage
		,	COALESCE(fpa.DoNotTrack, '') AS DoNotTrack
		,	COALESCE(fpa.Cookies, -1) AS Cookies
		,	COALESCE(fpa.Canvas, '') AS Canvas
		,	COALESCE(fpa.Fonts, '') AS Fonts
		,	COALESCE(fpa.Vendor, '') AS Vendor
		,	COALESCE(fpa.GLRenderer, '') AS GLRenderer
		,	COALESCE(fpa.Plugins, '') AS Plugins
		,	COALESCE(fpa.Languages, '') AS Languages
		,	COALESCE(fpa.Resolution, '') AS Resolution
		,	COALESCE(fpa.Timezone, '') AS Timezone
	FROM Temp_InputTrans AS tmp
		INNER JOIN FPS_FingerPrint.RawFingerPrint AS fp ON fp.Id = tmp.Id
		INNER JOIN FPS_FingerPrint.FingerPrintAttribute AS fpa ON fpa.RawFingerPrintId = fp.Id
		INNER JOIN FPS_FingerPrint.BrowserInstanceRawFingerPrint AS bisa ON bisa.RawFingerPrintId = fp.Id
		INNER JOIN FPS_FingerPrint.BrowserInstance AS bis ON bis.Id = bisa.BrowserInstanceId
	WHERE bis.BrowserFamilyCode = ip_BrowserFamilyCode
	ORDER BY tmp.Id DESC;

END$$
DELIMITER ;

/*<info serverAlias="FPSDC-FPS_FingerPrint" databaseType="2" executers="fpsService" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `FPS_FP_Recover_TransactionEvolution_Get`;
DELIMITER $$

CREATE DEFINER=`fpsOwner`@`%` PROCEDURE `FPS_FP_Recover_TransactionEvolution_Get`(
		ip_BatchSize 	INT
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
			- CALL FPS_FP_Recover_TransactionEvolution_Get(100);
			
	*/
    
    DROP TEMPORARY TABLE IF EXISTS Temp_TransactionEvolution;
    DROP TEMPORARY TABLE IF EXISTS Temp_GroupFP;
    DROP TEMPORARY TABLE IF EXISTS Temp_FingerPrintAttribute;
    
    CREATE TEMPORARY TABLE Temp_TransactionEvolution(
				Id 						BIGINT UNSIGNED NOT NULL PRIMARY KEY
			, 	RawFingerPrintId		BIGINT UNSIGNED
			, 	BrowserInstanceId		BIGINT UNSIGNED
			, 	CookieId				BIGINT UNSIGNED
			, 	TransTime				DATETIME(4)
			, 	AccountId				BIGINT UNSIGNED
    );
    
    CREATE TEMPORARY TABLE Temp_GroupFP(
				Id 						BIGINT UNSIGNED NOT NULL PRIMARY KEY
			, 	FPIds					LONGTEXT
    );
    
    INSERT IGNORE INTO Temp_TransactionEvolution(Id, RawFingerPrintId, BrowserInstanceId, CookieId, TransTime, AccountId)
    SELECT 	Id
		,	RawFingerPrintId
		,	BrowserInstanceId
		,	CookieId
		,	TransTime
		,	AccountId
	FROM FPS_FingerPrint.TransactionEvolution
	LIMIT ip_BatchSize;
    
    INSERT INTO Temp_GroupFP(Id, FPIds)
	SELECT 	tmp.Id
		,	GROUP_CONCAT(af.RawFingerPrintId) AS FPIds
	FROM Temp_TransactionEvolution AS tmp
		INNER JOIN FPS_FingerPrint.AccountFingerprint AS af ON af.AccountId = tmp.AccountId
	WHERE af.IsEvolution IS NULL
    GROUP BY tmp.Id;
    
    SELECT 	tmp.Id
		,	tmp.RawFingerPrintId
		,	tmp.CookieId
		,	tmp.TransTime
		,	tmpG.FPIds
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
	FROM Temp_TransactionEvolution AS tmp
		INNER JOIN Temp_GroupFP AS tmpG ON tmpG.Id = tmp.Id
		LEFT JOIN FPS_FingerPrint.RawFingerPrint AS fp ON fp.Id = tmp.RawFingerPrintId
		LEFT JOIN FPS_FingerPrint.FingerPrintAttribute AS fpa ON fpa.RawFingerPrintId = fp.Id
		LEFT JOIN FPS_FingerPrint.BrowserInstanceRawFingerPrint AS bisa ON bisa.RawFingerPrintId = fp.Id AND bisa.BrowserInstanceId = tmp.BrowserInstanceId
		LEFT JOIN FPS_FingerPrint.BrowserInstance AS bis ON bis.Id = bisa.BrowserInstanceId;

END$$
DELIMITER ;

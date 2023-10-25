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
	WHERE af.IsEvolution = 0
    GROUP BY tmp.Id;
    
    SELECT 	tmp.Id
		,	tmp.RawFingerPrintId
		,	tmp.CookieId
		,	tmp.TransTime
		,	tmpG.FPIds
		,	IFNULL(bis.UserAgent, '') AS UserAgent
		,	IFNULL(bis.BrowserFamilyCode, '') AS BrowserFamilyCode
		,	IFNULL(bis.OSName, '') AS OSName
		,	IFNULL(bis.BrowserName, '') AS BrowserName
		,	IFNULL(bis.BrowserVersion, '') AS BrowserVersion
		,	IFNULL(bis.Platform, '') AS Platform
		,	IFNULL(bis.Accept, '') AS Accept
		,	IFNULL(bis.Encoding, '') AS Encoding
		,	IFNULL(bis.Headers, '') AS Headers
		,	IFNULL(fpa.LocalStorage, -1) AS LocalStorage
		,	IFNULL(fpa.DoNotTrack, '') AS DoNotTrack
		,	IFNULL(fpa.Cookies, -1) AS Cookies
		,	IFNULL(fpa.Canvas, '') AS Canvas
		,	IFNULL(fpa.Fonts, '') AS Fonts
		,	IFNULL(fpa.Vendor, '') AS Vendor
		,	IFNULL(fpa.GLRenderer, '') AS GLRenderer
		,	IFNULL(fpa.Plugins, '') AS Plugins
		,	IFNULL(fpa.Languages, '') AS Languages
		,	IFNULL(fpa.Resolution, '') AS Resolution
		,	IFNULL(fpa.Timezone, '') AS Timezone
	FROM Temp_TransactionEvolution AS tmp
		INNER JOIN Temp_GroupFP AS tmpG ON tmpG.Id = tmp.Id
		LEFT JOIN FPS_FingerPrint.RawFingerPrint AS fp ON fp.Id = tmp.RawFingerPrintId
		LEFT JOIN FPS_FingerPrint.FingerPrintAttribute AS fpa ON fpa.RawFingerPrintId = fp.Id
		LEFT JOIN FPS_FingerPrint.BrowserInstanceRawFingerPrint AS bisa ON bisa.RawFingerPrintId = fp.Id AND bisa.BrowserInstanceId = tmp.BrowserInstanceId
		LEFT JOIN FPS_FingerPrint.BrowserInstance AS bis ON bis.Id = bisa.BrowserInstanceId;

END$$
DELIMITER ;

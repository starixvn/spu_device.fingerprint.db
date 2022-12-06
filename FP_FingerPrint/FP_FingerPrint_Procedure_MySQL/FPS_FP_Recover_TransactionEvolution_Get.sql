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
			, 	CookieId				BIGINT UNSIGNED
			, 	TransTime				DATETIME(4)
			, 	AccountId				BIGINT UNSIGNED
    );
    
    CREATE TEMPORARY TABLE Temp_GroupFP(
				Id 						BIGINT UNSIGNED NOT NULL PRIMARY KEY
			, 	FPIds					LONGTEXT
    );
    
    INSERT IGNORE INTO Temp_TransactionEvolution(Id, RawFingerPrintId, CookieId, TransTime, AccountId)
    SELECT 	Id
		,	RawFingerPrintId
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
		,	bis.UserAgent
		,	bis.BrowserFamilyCode
		,	bis.OSName
		,	bis.BrowserName
		,	bis.BrowserVersion
		,	bis.Platform
		,	bis.Accept
		,	bis.Encoding
		,	bis.Headers
		,	fpa.LocalStorage
		,	fpa.DoNotTrack
		,	fpa.Cookies
		,	fpa.Canvas
		,	fpa.Fonts
		,	fpa.Vendor
		,	fpa.GLRenderer
		,	fpa.Plugins
		,	fpa.Languages
		,	fpa.Resolution
		,	fpa.Timezone
	FROM Temp_TransactionEvolution AS tmp
		INNER JOIN Temp_GroupFP AS tmpG ON tmpG.Id = tmp.Id
		LEFT JOIN FPS_FingerPrint.RawFingerPrint AS fp ON fp.Id = tmp.RawFingerPrintId
		LEFT JOIN FPS_FingerPrint.FingerPrintAttribute AS fpa ON fpa.RawFingerPrintId = fp.Id
		LEFT JOIN FPS_FingerPrint.BrowserInstanceRawFingerPrint AS bisa ON bisa.RawFingerPrintId = fp.Id
		LEFT JOIN FPS_FingerPrint.BrowserInstance AS bis ON bis.Id = bisa.BrowserInstanceId;

END$$
DELIMITER ;

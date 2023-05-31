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
    DROP TEMPORARY TABLE IF EXISTS Temp_FPAttribute;
    DROP TEMPORARY TABLE IF EXISTS Temp_Result;
    
    CREATE TEMPORARY TABLE Temp_TransactionEvolution(
				Id 						BIGINT UNSIGNED NOT NULL PRIMARY KEY
			, 	RawFingerPrintId		BIGINT UNSIGNED
			, 	BrowserInstanceId		BIGINT UNSIGNED
			, 	CookieId				BIGINT UNSIGNED
			, 	TransTime				DATETIME(4)
			, 	AccountId				BIGINT UNSIGNED
    );
    
    CREATE TEMPORARY TABLE Temp_GroupFP(
				Id 						BIGINT UNSIGNED NOT NULL AUTO_INCREMENT
			, 	TransactionEvolutionId	BIGINT UNSIGNED
			, 	RawFingerPrintId		BIGINT UNSIGNED
			, 	BrowserFamilyCode		VARCHAR(64)
            
			,	PRIMARY KEY (`Id`)
    );
    
    CREATE TEMPORARY TABLE Temp_FPAttribute(
				Id 						BIGINT UNSIGNED NOT NULL
			, 	UserAgent				LONGTEXT
			, 	BrowserFamilyCode		VARCHAR(64)
			, 	OSName					VARCHAR(100)
			, 	BrowserName				VARCHAR(100)
			, 	BrowserVersion			VARCHAR(50)
			, 	Platform				VARCHAR(45)
			, 	Accept					VARCHAR(200)
			, 	Encoding				VARCHAR(200)
			, 	Headers					LONGTEXT
			, 	LocalStorage			TINYINT(1)
			, 	DoNotTrack				VARCHAR(15)
			, 	Cookies					TINYINT(1)
			, 	Canvas					LONGTEXT
			, 	Fonts					LONGTEXT
			, 	Vendor					VARCHAR(45)
			, 	GLRenderer				VARCHAR(200)
			, 	Plugins					LONGTEXT
			, 	Languages				LONGTEXT
			, 	Resolution				VARCHAR(200)
			, 	Timezone				VARCHAR(45)
            
			,	PRIMARY KEY (`Id`)
    );
    
    CREATE TEMPORARY TABLE Temp_Result(
				Id 						BIGINT UNSIGNED NOT NULL AUTO_INCREMENT
			, 	TransactionEvolutionId	BIGINT UNSIGNED
			, 	ParentId				BIGINT UNSIGNED
			, 	RawFingerPrintId		BIGINT UNSIGNED
			, 	CookieId				BIGINT UNSIGNED
			, 	TransTime				DATETIME(4)
			, 	AccountId				BIGINT UNSIGNED
			, 	UserAgent				LONGTEXT
			, 	BrowserFamilyCode		VARCHAR(64)
			, 	OSName					VARCHAR(100)
			, 	BrowserName				VARCHAR(100)
			, 	BrowserVersion			VARCHAR(50)
			, 	Platform				VARCHAR(45)
			, 	Accept					VARCHAR(200)
			, 	Encoding				VARCHAR(200)
			, 	Headers					LONGTEXT
			, 	LocalStorage			TINYINT(1)
			, 	DoNotTrack				VARCHAR(15)
			, 	Cookies					TINYINT(1)
			, 	Canvas					LONGTEXT
			, 	Fonts					LONGTEXT
			, 	Vendor					VARCHAR(45)
			, 	GLRenderer				VARCHAR(200)
			, 	Plugins					LONGTEXT
			, 	Languages				LONGTEXT
			, 	Resolution				VARCHAR(200)
			, 	Timezone				VARCHAR(45)
            
			,	PRIMARY KEY (`Id`)
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
    
    INSERT INTO Temp_Result(TransactionEvolutionId, RawFingerPrintId, CookieId, TransTime, AccountId, UserAgent, BrowserFamilyCode, OSName, BrowserName, BrowserVersion, Platform, Accept, Encoding, Headers, LocalStorage, DoNotTrack, Cookies, Canvas, Fonts, Vendor, GLRenderer, Plugins, Languages, Resolution, Timezone)
    SELECT 	tmp.Id AS TransactionEvolutionId
		,	tmp.RawFingerPrintId
		,	tmp.CookieId
		,	tmp.TransTime
		,	tmp.AccountId
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
		LEFT JOIN FPS_FingerPrint.RawFingerPrint AS fp ON fp.Id = tmp.RawFingerPrintId
		LEFT JOIN FPS_FingerPrint.FingerPrintAttribute AS fpa ON fpa.RawFingerPrintId = fp.Id
		LEFT JOIN FPS_FingerPrint.BrowserInstance AS bis ON bis.Id = tmp.BrowserInstanceId;
	
	INSERT INTO Temp_GroupFP(TransactionEvolutionId, RawFingerPrintId, BrowserFamilyCode)
	SELECT 	tmp.TransactionEvolutionId
		,	af.RawFingerPrintId
		,	tmp.BrowserFamilyCode
	FROM Temp_Result AS tmp
		INNER JOIN FPS_FingerPrint.AccountFingerprint AS af ON af.AccountId = tmp.AccountId
	WHERE af.IsEvolution = 0;
        	
            
    INSERT IGNORE INTO Temp_FPAttribute(Id, UserAgent, BrowserFamilyCode, OSName, BrowserName, BrowserVersion, Platform, Accept, Encoding, Headers, LocalStorage, DoNotTrack, Cookies, Canvas, Fonts, Vendor, GLRenderer, Plugins, Languages, Resolution, Timezone)
    WITH cte_FingerprintAtt AS (		
		SELECT 	DISTINCT 
				RawFingerPrintId
			,	BrowserFamilyCode
		FROM Temp_GroupFP
    )
    SELECT 	fp.Id
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
    FROM cte_FingerprintAtt AS cte
		INNER JOIN FPS_FingerPrint.RawFingerPrint AS fp ON fp.Id = cte.RawFingerPrintId
		INNER JOIN FPS_FingerPrint.FingerPrintAttribute AS fpa ON fpa.RawFingerPrintId = fp.Id
		INNER JOIN FPS_FingerPrint.BrowserInstanceRawFingerPrint AS bisa ON bisa.RawFingerPrintId = fp.Id
		INNER JOIN FPS_FingerPrint.BrowserInstance AS bis ON bis.Id = bisa.BrowserInstanceId
	WHERE bis.BrowserFamilyCode = cte.BrowserFamilyCode;
    
    INSERT INTO Temp_Result(TransactionEvolutionId, ParentId, RawFingerPrintId, CookieId, TransTime, AccountId, UserAgent, BrowserFamilyCode, OSName, BrowserName, BrowserVersion, Platform, Accept, Encoding, Headers, LocalStorage, DoNotTrack, Cookies, Canvas, Fonts, Vendor, GLRenderer, Plugins, Languages, Resolution, Timezone)
	SELECT 	tmpGr.TransactionEvolutionId
		,	tmpGr.TransactionEvolutionId AS ParentId
		,	tmpGr.RawFingerPrintId
		,	tmp.CookieId
		,	tmp.TransTime
		,	tmp.AccountId
		,	tmpFP.UserAgent
		,	tmpFP.BrowserFamilyCode
		,	tmpFP.OSName
		,	tmpFP.BrowserName
		,	tmpFP.BrowserVersion
		,	tmpFP.Platform
		,	tmpFP.Accept
		,	tmpFP.Encoding
		,	tmpFP.Headers
		,	tmpFP.LocalStorage
		,	tmpFP.DoNotTrack
		,	tmpFP.Cookies
		,	tmpFP.Canvas
		,	tmpFP.Fonts
		,	tmpFP.Vendor
		,	tmpFP.GLRenderer
		,	tmpFP.Plugins
		,	tmpFP.Languages
		,	tmpFP.Resolution
		,	tmpFP.Timezone
	FROM Temp_GroupFP as tmpGr
		INNER JOIN Temp_TransactionEvolution AS tmp ON tmp.Id = tmpGr.TransactionEvolutionId
		INNER JOIN Temp_FPAttribute AS tmpFP ON tmpFP.Id = tmpGr.RawFingerPrintId;
    
	/* Return result */
	SELECT 	TransactionEvolutionId AS Id
		,	ParentId
		,	RawFingerPrintId
		,	CookieId
		,	TransTime
		,	AccountId
		,	UserAgent
		,	BrowserFamilyCode
		,	OSName
		,	BrowserName
		,	BrowserVersion
		,	Platform
		,	Accept
		,	Encoding
		,	Headers
		,	LocalStorage
		,	DoNotTrack
		,	Cookies
		,	Canvas
		,	Fonts
		,	Vendor
		,	GLRenderer
		,	Plugins
		,	Languages
		,	Resolution
		,	Timezone
    FROM Temp_Result;
END$$
DELIMITER ;

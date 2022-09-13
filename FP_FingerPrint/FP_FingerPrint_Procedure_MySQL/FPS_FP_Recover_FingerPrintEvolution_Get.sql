/*<info serverAlias="FPSDC-FPS_FingerPrint" databaseType="2" executers="fpsService" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `FPS_FP_Recover_FingerPrintEvolution_Get`;
DELIMITER $$

CREATE DEFINER=`fpsOwner`@`%` PROCEDURE `FPS_FP_Recover_FingerPrintEvolution_Get`(
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
			- CALL FPS_FP_Recover_FingerPrintEvolution_Get(100);
			
	*/
    
    SELECT 	fe.Id
		,	fe.RawFingerPrintId
		,	fe.CookieId
		,	fe.TransTime
		,	ua.UserAgent
		,	fpa.OSName
		,	fpa.BrowserName
		,	fpa.BrowserVersion
		,	fpa.Platform
		,	fpa.LocalStorage
		,	fpa.DoNotTrack
		,	fpa.CookiesEnabled
		,	fpa.CanvasPrint
		,	fpa.Fonts
		,	fpa.Vendor
		,	fpa.GLRenderer
		,	fpa.Plugins
		,	fpa.LanguagesPrint
		,	fpa.HeaderAccept
		,	fpa.HeaderAcceptEncoding
		,	fpa.Headers
	FROM FPS_FingerPrint.FingerPrintEvolution AS fe
		LEFT JOIN FPS_FingerPrint.RawUserAgent AS ua ON ua.Id = fe.UserAgentId
		LEFT JOIN FPS_FingerPrint.RawFingerPrint AS fp ON fp.Id = fe.RawFingerPrintId
		LEFT JOIN FPS_FingerPrint.FingerPrintAttribute AS fpa ON fpa.FingerPrintCode = fp.FingerPrintCode
	ORDER BY fpa.Id
	LIMIT ip_BatchSize;

END$$
DELIMITER ;

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
		,	GROUP_CONCAT(af.FingerPrintId) AS FPIds
	FROM FPS_FingerPrint.FingerPrintEvolution AS fe
		INNER JOIN FPS_FingerPrint.RawUserAgent AS ua ON ua.Id = fe.UserAgentId
		INNER JOIN FPS_FingerPrint.RawFingerPrint AS fp ON fp.Id = fe.RawFingerPrintId
		INNER JOIN FPS_FingerPrint.FingerPrintAttribute AS fpa ON fpa.FingerPrintCode = fp.FingerPrintCode
		LEFT JOIN FPS_FingerPrint.Account AS acc ON acc.SubscriberId = fe.SubscriberId AND acc.LoginName = fe.LoginName
		LEFT JOIN FPS_FingerPrint.BrowserInstance AS bi ON bi.OSName = ua.OSName AND bi.Platform = fpa.Platform AND bi.BrowserName = ua.ClientName
		LEFT JOIN FPS_FingerPrint.AccountFingerprint AS af ON af.AccountId = acc.Id AND af.BrowserInstanceId = bi.Id
	GROUP BY fe.Id, fe.RawFingerPrintId, fe.CookieId, fe.TransTime, ua.UserAgent, fpa.OSName, fpa.BrowserName, fpa.BrowserVersion, fpa.Platform, fpa.LocalStorage, fpa.DoNotTrack, fpa.Cookies, fpa.Canvas, fpa.Fonts, fpa.Vendor, fpa.GLRenderer, fpa.Plugins, fpa.Languages, fpa.Accept, fpa.Encoding, fpa.Headers, fpa.Resolution, fpa.Timezone
	ORDER BY fe.Id
	LIMIT ip_BatchSize;

END$$
DELIMITER ;

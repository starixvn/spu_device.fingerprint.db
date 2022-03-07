/*<info serverAlias="FPSDC-FPTesting" databaseType="2" executers="fpsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `FP_DCS_DC_Transform_RawTrans_Insert`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `FP_DCS_DC_Transform_RawTrans_Insert`(
		IN ip_RawTransJson LONGTEXT
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created: 20190610@Casey.Huynh
		Task : Insert to Raw Table
		DB: FPS_RawTrans
		Original:

		Revisions:
			- 20220106@CaseyHuynh: Created [RedmineID: #166727]

		Param's Explanation (filtered by):
			
		Example:
             CALL FP_DCS_DC_Transform_RawTrans_Insert ('[
					{"LoginName":"User01","SubscriberName":"Alpha","TransTime":"2021-11-21 00:00:01.0000","FPDeviceID":1,"DeviceCode":"dc001a6ce7074622bc18a921f8be1e60","FingerprintCode":"df001939c13195aaae06466b6757754413fcdc2a;0423c13edf617398aed953a6fd4e7d24","SubscriberID":2,"CustID":1,"CustSubID":0,"UserAgent":"Mozilla/5.0 (iPhone; CPU iPhone OS 15_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.1 Mobile/15E148 Safari/604.1","IP":"14.167.17.120","URL":"http://m122.viva88.net:806/FpsHandler","Action":"login","Flagged":2,"FPSTransID":null,"IPID":null,"PluginID":null,"InvalidDevice":null,"TransStatus":"0","FingerprintMoreInfo":null,"ActionResult":"Success","LoginName_Old":"User01","TransTime_Old":"2021-11-21 00:00:00.2418","IP_Old":"14.167.17.120","UserAgent_Old":"Mozilla/5.0 (iPhone; CPU iPhone OS 15_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.1 Mobile/15E148 Safari/604.1","URL_Old":"http://m122.viva88.net:806/FpsHandler","Flagged_Old":2},
					{"LoginName":"User02","SubscriberName":"Alpha","TransTime":"2021-11-21 00:00:01.0001","FPDeviceID":2,"DeviceCode":"dc0026620cce48a4ada3cd3887e5d77f","FingerprintCode":"df002f4634bfd83191d70c4f1913cc79878cce5f;4c7acb513373c49e797f2f35c6e1f99d","SubscriberID":2,"CustID":2,"CustSubID":0,"UserAgent":"Mozilla/5.0 (Linux; Android 11; CPH2113) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/96.0.4664.45 Mobile Safari/537.36","IP":"103.199.41.17","URL":"http://l9j7ma.cx5888.com/FpsHandler","Action":"login","Flagged":2,"FPSTransID":null,"IPID":null,"PluginID":null,"InvalidDevice":null,"TransStatus":"0","FingerprintMoreInfo":null,"ActionResult":"Success","LoginName_Old":"User01","TransTime_Old":"2021-11-21 00:00:00.2418","IP_Old":"103.199.41.17","UserAgent_Old":"Mozilla/5.0 (Linux; Android 11; CPH2113) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/96.0.4664.45 Mobile Safari/537.36","URL_Old":"http://l9j7ma.cx5888.com/FpsHandler","Flagged_Old":2}
				]');

	*/
	DROP TEMPORARY TABLE IF EXISTS Temp_Transactions;
	CREATE TEMPORARY TABLE Temp_Transactions(
			LoginName					VARCHAR(100) CHARACTER SET 'UTF8MB4' COLLATE 'UTF8MB4_UNICODE_CI' NOT NULL	
		,	CustID						INT									NULL
        ,	CustSubID						INT									NULL
		,	SubscriberName				VARCHAR(50) 						NOT NULL
        ,	SubscriberID				INT
		,	TransTime					TIMESTAMP(4)	 					NOT NULL
		,	DeviceCode					VARCHAR(32) 						NULL		COMMENT 'Device Inject Code: 32 characters is auto generated'
		,	FingerprintCode				VARCHAR(620)						NULL		COMMENT 'Device Fingerprint Codes, the hashcode bases on the set attributes'    
		,	UserAgent					VARCHAR(1000)						NULL
		,	IP							VARCHAR(50) 						NULL
        ,	IPID						DECIMAL(50,0)						NULL
        ,	Flagged						SMALLINT							NULL
		,	PluginID					BIGINT 								NULL	
		,	URL							VARCHAR(500) 						NULL
        ,	Action						VARCHAR(100) 						NULL
		,	ActionResult				VARCHAR(100) 						NULL
		,	InvalidDevice				VARCHAR(1000)						CHARACTER SET 'UTF8MB4' COLLATE 'UTF8MB4_UNICODE_CI' NULL
		,	TransStatus					BIT(16)								NULL
        ,	FPDeviceID					BIGINT UNSIGNED						NULL        
        ,	LoginName_Old				VARCHAR(100) CHARACTER SET 'UTF8MB4' COLLATE 'UTF8MB4_UNICODE_CI' NULL	
        ,	TransTime_Old				TIMESTAMP(4)	 					NULL
        ,	UserAgent_Old				VARCHAR(1000)						NULL
        ,	IP_Old						VARCHAR(50) 						NULL
        ,	URL_Old						VARCHAR(500) 						NULL
        ,	Flagged_Old					SMALLINT							NULL
    );     
		
	INSERT INTO Temp_Transactions(LoginName, CustID, CustSubID, SubscriberName, TransTime, DeviceCode, FingerprintCode, UserAgent, IP, IPID, Flagged, PluginID, URL, Action, ActionResult, InvalidDevice, TransStatus, FPDeviceID, SubscriberID, LoginName_Old,TransTime_Old, UserAgent_Old, IP_Old, URL_Old, Flagged_Old)
	SELECT	rt.LoginName
		,	rt.CustID
        ,	rt.CustSubID
		,	rt.SubscriberName
		,	rt.TransTime
		,	(CASE WHEN rt.DeviceCode IS NULL THEN NULL ELSE rt.DeviceCode END) AS DeviceCode
		,	(CASE WHEN rt.FingerprintCode IS NULL OR rt.DeviceCode IS NULL	THEN NULL ELSE rt.FingerprintCode END) AS FingerprintCode
		,	LEFT((CASE WHEN rt.UserAgent IS NULL THEN NULL ELSE rt.UserAgent END),1000) AS UserAgent
		,	rt.IP
		,	(CASE WHEN rt.IPID = 0 THEN NULL ELSE rt.IPID END) AS IPID
		,	(CASE WHEN rt.Flagged = -1 THEN NULL ELSE rt.Flagged END) AS Flagged
		,	rt.PluginID          
		,	rt.URL
		,	rt.Action
		,	rt.ActionResult
		,	LEFT((CASE WHEN rt.InvalidDevice IS NULL THEN NULL ELSE rt.InvalidDevice END),1000) AS InvalidDevice
		,	rt.TransStatus
        ,	rt.FPDeviceID
        ,	rt.SubscriberID
        ,	rt.LoginName_Old
        ,	rt.TransTime_Old
        ,	LEFT((CASE WHEN rt.UserAgent_Old IS NULL THEN NULL ELSE rt.UserAgent_Old END),1000) AS UserAgent_Old
        , 	rt.IP_Old
        , 	rt.URL_Old
        , 	(CASE WHEN rt.Flagged_Old = -1 THEN NULL ELSE rt.Flagged_Old END) AS Flagged_Old
	FROM	JSON_TABLE(
			ip_RawTransJson,
			 "$[*]" COLUMNS(
								LoginName				VARCHAR(100)	CHARACTER SET 'UTF8MB4' COLLATE 'UTF8MB4_UNICODE_CI' PATH "$.LoginName"  
							,	CustID					INT				PATH "$.CustID"
                            ,	CustSubID				INT				PATH "$.CustSubID"
							,	SubscriberName			VARCHAR(50) 	PATH "$.SubscriberName"   
							,	TransTime				TIMESTAMP(4) 	PATH "$.TransTime"
							,	DeviceCode				VARCHAR(32)		PATH "$.DeviceCode"
							,	FingerprintCode			VARCHAR(620)	PATH "$.FingerprintCode"
							,	UserAgent				TEXT 			PATH "$.UserAgent"
							,	IP						VARCHAR(50) 	PATH "$.IP"
                            ,	IPID					DECIMAL(50,0)	PATH "$.IPId"
                            ,	Flagged					SMALLINT		PATH "$.Flagged"
							,	PluginID				BIGINT 			PATH "$.PluginID"
							,	URL						VARCHAR(500) 	PATH "$.URL"
                            ,	Action					VARCHAR(100)	PATH "$.Action"
							,	ActionResult			VARCHAR(100) 	PATH "$.ActionResult"
                            ,	InvalidDevice			TEXT			CHARACTER SET 'UTF8MB4' COLLATE 'UTF8MB4_UNICODE_CI' PATH "$.InvalidDevice"
                            ,	TransStatus				BIT(16)			PATH "$.TransStatus"
                            ,	FPDeviceID				BIGINT UNSIGNED	PATH "$.FPDeviceID"
                            ,	SubscriberID			INT				PATH "$.SubscriberID"
                            ,	LoginName_Old			VARCHAR(100)	CHARACTER SET 'UTF8MB4' COLLATE 'UTF8MB4_UNICODE_CI' PATH "$.LoginName_Old" 
                            ,	TransTime_Old			TIMESTAMP(4) 	PATH "$.TransTime_Old"
                            ,	UserAgent_Old			TEXT 			PATH "$.UserAgent_Old"
                            ,	IP_Old					VARCHAR(50)		PATH "$.IP_Old"
                            ,	URL_Old					VARCHAR(500) 	PATH "$.URL_Old"
                            ,	Flagged_Old				SMALLINT		PATH "$.Flagged_Old"
				)
		   ) AS  rt; 
   
	INSERT INTO FPTesting.FP_RawTransaction(LoginName, CustID, CustSubID, SubscriberName, TransTime, CreatedDate, DeviceCode, FingerprintCode, UserAgent, IP, IPID, Flagged, PluginID, URL, Action, ActionResult, InvalidDevice, TransStatus, FPDeviceID, SubscriberID, LoginName_Old, TransTime_Old, UserAgent_Old, IP_Old, URL_Old, Flagged_Old)
	SELECT	rt.LoginName
		,	rt.CustID
        ,	rt.CustSubID
		,	rt.SubscriberName
		,	rt.TransTime
		,	DATE(rt.TransTime) AS CreatedDate
		,	rt.DeviceCode
		,	rt.FingerprintCode
		,	rt.UserAgent
		,	rt.IP
        ,	rt.IPID
        ,	rt.Flagged
		,	rt.PluginID
		,	rt.URL
        ,	rt.Action
		,	rt.ActionResult
        ,	rt.InvalidDevice
        ,	rt.TransStatus
        ,	rt.FPDeviceID
        ,	rt.SubscriberID
        ,	LoginName_Old
		,	TransTime_Old
		,	UserAgent_Old
		,	IP_Old
		,	URL_Old
		,	Flagged_Old
	FROM Temp_Transactions AS rt;
	
    DROP TEMPORARY TABLE IF EXISTS Temp_Transactions;
END$$

DELIMITER ;

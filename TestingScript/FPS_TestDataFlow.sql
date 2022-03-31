USE FPS_FingerPrint;
/* TRUNCATE and RESET FPS

TRUNCATE TABLE FPS_FingerPrint.Device;
TRUNCATE TABLE FPS_FingerPrint.DeviceCookie;
TRUNCATE TABLE FPS_FingerPrint.DeviceFingerPrint;
TRUNCATE TABLE FPS_FingerPrint.FingerPrint;
TRUNCATE TABLE FPS_FingerPrint.FingerPrintCompleted;

TRUNCATE TABLE FPS_FingerPrint.RawTransaction;
TRUNCATE TABLE FPS_FingerPrint.RawTransactionCompleted;
TRUNCATE TABLE FPS_FingerPrint.RawTransactionN;
TRUNCATE TABLE FPS_FingerPrint.RawUserAgent;
TRUNCATE TABLE FPS_FingerPrint.Transaction;
TRUNCATE TABLE FPS_FingerPrint.TransactionDevice;
TRUNCATE TABLE FPS_FingerPrint.TransactionCompleted;


TRUNCATE TABLE FPTesting.FP_RawTransaction_Old;
TRUNCATE TABLE FPTesting.FP_RawTransaction_Old_Completed;
TRUNCATE TABLE FPTesting.FP_RawTransaction;

TRUNCATE TABLE FPS_FingerPrint.Test_LOG;

UPDATE Offset
SET OffsetValue = 0
WHERE Id IN (1,2) ;

*/

/* TRUNCATE and RESET FPSTesting

TRUNCATE TABLE FPSTesting.FP_Account;

TRUNCATE TABLE FPSTesting.FP_ActionResult;
TRUNCATE TABLE FPSTesting.FP_AssociationNew;
TRUNCATE TABLE FPSTesting.FP_dba_SP_PerformanceStats;
TRUNCATE TABLE FPSTesting.FP_Device;
TRUNCATE TABLE FPSTesting.FP_DeviceCode;
TRUNCATE TABLE FPSTesting.FP_DeviceFingerprint;
TRUNCATE TABLE FPSTesting.FP_DeviceType;
TRUNCATE TABLE FPSTesting.FP_MappingDevice;
TRUNCATE TABLE FPSTesting.FP_ProcessedTransaction;
TRUNCATE TABLE FPSTesting.FP_RawTransaction;
TRUNCATE TABLE FPSTesting.FP_Transaction;
TRUNCATE TABLE FPSTesting.FP_Transaction07;
TRUNCATE TABLE FPSTesting.FP_URL;
TRUNCATE TABLE FPSTesting.FP_UserAgent;
TRUNCATE FPS_FingerPrint.Test_LOG;

UPDATE FPSTesting.FP_SystemSetting
SET VValue = 0
WHERE Id IN (94423,1) ;

UPDATE FPSTesting.FP_SystemSetting
SET VValue = '2020-01-01'
WHERE Id IN (2) ;

SELECT * FROM FP_Transaction07;
SELECT * FROM FP_Transaction;
SELECT TransId, t.* FROM FP_RawTransaction t;
SELECT * FROM FP_SystemSetting;
SELECT * FROM FPS_FingerPrint.Test_LOG ORDER BY ID DESC;
SELECT * FROM FPS_FingerPrint.Test_LOG WHERE SPName LIKE '%FP_DCS_DC_Transform_Device%'

CALL FPS_FingerPrint.Test_LOG
*/
CALL FP_DCS_DC_Transform_RawTrans_GetPackage(0,10,5); --> n goi

Get ---
	(7	20) --unsub, userAgent, TransactionInsert 
	(21	29) --unsub, userAgent, TransactionInsert
Get ---

INSERT INTO FP_RawTransaction SELECT * FROM zzzTestData_FP_RawTransaction;

INSERT INTO `FPSTesting`.`FP_RawTransaction`
(`LoginName`,
`SubscriberName`,
`TransTime`,
`CreatedDate`,
`DeviceCode`,
`FingerprintCode`,
`FingerprintMoreInfo`,
`UserAgent`,
`IP`,
`IPID`,
`PluginID`,
`URL`,
`Action`,
`ActionResult`,
`InvalidDevice`,
`TransStatus`,
`FPSTransID`,
`Flagged`,
`IsProcessed`,
`FPDeviceID`,
`SubscriberID`,
`CustID`,
`CustSubID`,
`LoginName_Old`,
`TransTime_Old`,
`IP_Old`,
`UserAgent_Old`,
`URL_Old`,
`Flagged_Old`,
`TransKey`)
SELECT `LoginName`,
`SubscriberName`,
`TransTime`,
`CreatedDate`,
`DeviceCode`,
`FingerprintCode`,
`FingerprintMoreInfo`,
`UserAgent`,
`IP`,
`IPID`,
`PluginID`,
`URL`,
`Action`,
`ActionResult`,
`InvalidDevice`,
`TransStatus`,
`FPSTransID`,
`Flagged`,
`IsProcessed`,
`FPDeviceID`,
`SubscriberID`,
`CustID`,
`CustSubID`,
`LoginName_Old`,
`TransTime_Old`,
`IP_Old`,
`UserAgent_Old`,
`URL_Old`,
`Flagged_Old`,
`TransKey`
FROM FPSTesting.zzzTestData_FP_RawTransaction;


CREATE TABLE zzzTestData_FP_RawTransaction SELECT * FROM FP_RawTransaction;
TRUNCATE TABLE FP_ProcessedTransaction;
CALL FPSTesting.FP_DCS_DC_Transform_Transaction_Insert(7,29); '209', 'FP_DCS_DC_Transform_Transaction_Insert', NULL, 'ip_FromTransID:7; ip_ToTransID:32', '2022-03-31 02:40:47'

SELECT * FROM FPS_FingerPrint.Offset;
SELECT * FROM FPS_FingerPrint.RawUserAgent;
SELECT * FROM FPS_FingerPrint.TransactionDevice;
SELECT * FROM FPS_FingerPrint.FingerPrintCompleted;

SELECT * FROM FPTesting.FP_RawTransaction_Old_Completed  WHERE  TransKey = 'caseyTest#637819649820000000';
SELECT * FROM FPS_FingerPrint.TransactionCompleted ORDER BY Id DESC;
SELECT TransId,rt.* FROM FPTesting.FP_RawTransaction AS rt ORDER BY TransId DESC;
SELECT * FROM FPTesting.FP_RawTransaction_Old WHERE  TransKey = 'caseyTest#637819662070000000';
SELECT TransKey, r.* FROM FPS_FingerPrint.TransactionDevice AS r WHERE TransKey =  'caseyTest#637819662070000000'; 

#TURN OFF ALL SERVICES: http://spu-fps-job-management.nexdev.net/jobs/Triggers
#**************************************************************************************
# Step 01: Login http://ha.nexdev.net:7409/site-main/
#SP: 	FPS_FingerPrint.FPS_FP_Transform_RawTransaction_Insert
#		FPS_FP_Transform_FingerPrint_Insert
#		FPTesting.FP_DCS_DC_Transform_RawTransOld_Insert			
#**************************************************************************************
#	FPS_FingerPrint.FPS_FP_Transform_RawTransaction_Insert
SELECT rt.SessionKey, rt.TransKey, rt.TransTime, rt.*  FROM FPS_FingerPrint.RawTransaction AS rt ORDER BY Id DESC;
#		FPS_FP_Transform_FingerPrint_Insert
SELECT * FROM FPS_FingerPrint.RawUserAgent ORDER BY ModifiedDate DESC;	
SELECT * FROM FPS_FingerPrint.RawFingerPrint ORDER BY ModifiedDate DESC;	
SELECT * FROM FPS_FingerPrint.FingerPrint;
#		FPTesting.FP_DCS_DC_Transform_RawTransOld_Insert	
SELECT rto.TransKey,rto.* FROM FPTesting.FP_RawTransaction_Old AS rto ORDER BY TransId DESC; 	#sutest01#637819493230000000
SELECT rt.TransKey,rto.TransKey,rt.TransTime, rto.TransTime, rt.* 
FROM FPS_FingerPrint.RawTransaction AS rt
	LEFT JOIN  FPTesting.FP_RawTransaction_Old AS rto ON rt.TransKey = rto.TransKey;
#****************************************************************************************************************
# Step 02: TURN ON SERVICE FP_UpdateTransaction_Job
# SP:	FPS_FingerPrint.FPS_FP_Transform_RawTransaction_Get(10,1,1)
#    	FPS_FP_Transform_RawTransaction_Update
CALL FPS_FingerPrint.FPS_FP_Transform_RawTransaction_Update('[
	{
		"Id" : 1,
		"SessionKey" : "306881fc20764532bd62be1eec5f44df",
		"CustId" : 14542629,
		"SubAccId" : 0,
		"LoginName" : "sutest01",
		"SubscriberId" : 1,
		"Transtime" : "2022-03-03 09:29:42.8731",
		"ClientIP" : "10.23.10.23",
		"UserAgent" : "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/98.0.4758.102 Safari/537.36 Edg/98.0.1108.62",
		"Url" : null,
		"TransKey" : "sutest01#637818821820000000",
		"Action" : "Login",
		"Retry" : 0
	},
	{
		"Id" : 2,
		"SessionKey" : "5e87e5d2ca304665855adec87ede7cdd",
		"CustId" : 1176070,
		"SubAccId" : 0,
		"LoginName" : "alele1",
		"SubscriberId" : 1,
		"Transtime" : "2022-03-03 09:30:21.8388",
		"ClientIP" : "10.23.10.11",
		"UserAgent" : "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/98.0.4758.102 Safari/537.36",
		"Url" : null,
		"TransKey" : "alele1#637818822210000000",
		"Action" : "Login",
		"Retry" : 0
	}
]', 1, 1, 1);	
#****************************************************************************************************************  
SELECT * FROM FPS_FingerPrint.RawTransactionN;
SELECT * FROM FPS_FingerPrint.Transaction;

#**************************************************************************************
# Step 03: TURN ON SERVICE FP_UpdateTransactionN_Job
# SP: 	FPS_FingerPrint.FPS_FP_Transform_RawTransactionN_Get
#     	FPS_FingerPrint.FPS_FP_Transform_RawTransactionN_Update
#**************************************************************************************  
SELECT * FROM FPS_FingerPrint.RawTransactionN;
SELECT * FROM FPS_FingerPrint.Transaction;

#**************************************************************************************
# Step 03: TURN ON SERVICE FP_DeviceIdentify_Job
# SP: 	FPS_FingerPrint.FPS_FP_Transform_DeviceIdentify_Get
#     	FPS_FingerPrint.FPS_FP_Transform_DeviceIdentify
#		FPS_FingerPrint.FPS_FP_Transform_DeviceIdentify_NoFingerPrint
#**************************************************************************************  
SELECT * FROM FPS_FingerPrint.Device;
SELECT * FROM FPS_FingerPrint.DeviceCookie;
SELECT * FROM FPS_FingerPrint.DeviceFingerPrint;
SELECT * FROM FPS_FingerPrint.TransactionDevice;

#**************************************************************************************
# Step 04: TURN ON SERVICE FP_DeviceIdentify_Job
# SP: 	FPS_FingerPrint.FPS_FP_Transform_DeviceIdentify_Get
#     	FPS_FingerPrint.FPS_FP_Transform_DeviceIdentify
#		FPS_FingerPrint.FPS_FP_Transform_DeviceIdentify_NoFingerPrint
#**************************************************************************************  
SELECT * FROM FPS_FingerPrint.Device;
SELECT * FROM FPS_FingerPrint.DeviceCookie;
SELECT * FROM FPS_FingerPrint.DeviceFingerPrint;
SELECT * FROM FPS_FingerPrint.TransactionDevice;

/*
TRUNCATE TABLE FPS_FingerPrint.Device;
TRUNCATE TABLE FPS_FingerPrint.DeviceCookie;
TRUNCATE TABLE FPS_FingerPrint.DeviceFingerPrint;
TRUNCATE TABLE FPS_FingerPrint.TransactionDevice;
*/
SELECT * FROM  FPS_FingerPrint.Transaction ORDER BY Id ASC;
CALL FPS_FP_Transform_DeviceIdentify_Get(3,2); --> 1000; #ip_BatchSize,ip_NoOfBatch
SELECT * FROM FPS_FingerPrint.Transaction WHERE CookieId IS NULL and FingerPrintCode IS NOT NULL;
SELECT * FROM FPS_FingerPrint.Device;
SELECT * FROM FPS_FingerPrint.DeviceCookie;
SELECT * FROM FPS_FingerPrint.DeviceFingerPrint;
SELECT * FROM FPS_FingerPrint.TransactionDevice;

CALL FPS_FP_Transform_DeviceIdentify(0,'[
	{"Id":3356314495,"Transtime":"2022-02-20 00:00:05.2640","FingerPrintCode":"53b9f5d0e59645d09cfb56690a7b0916","CookieId":244603010,"GroupId":0},
	{"Id":3356314496,"Transtime":"2022-02-20 00:00:05.2757","FingerPrintCode":"e61bec118a0a44869ea57aec2b57d5a6","CookieId":323500147,"GroupId":0},
	{"Id":3356314498,"Transtime":"2022-02-20 00:00:05.4575","FingerPrintCode":"1245f5a2122b4f74b9e09c416497f6e6","CookieId":335528936,"GroupId":0}
]');

SELET
CALL FPS_FP_Transform_DeviceIdentify(1,'[
	{"Id":3356314503,"Transtime":"2022-02-20 00:00:05","FingerPrintCode":"ac918eadfdc1499cb1aade3183f6363f","CookieId":335525301,"GroupId":3356314503},
	{"Id":3356314519,"Transtime":"2022-02-20 00:00:06.2956","FingerPrintCode":"ac918eadfdc1499cb1aade3183f6363f","CookieId":336065236,"GroupId":3356314503},
	{"Id":3356314505,"Transtime":"2022-02-20 00:00:05.7028","FingerPrintCode":"66e37de75aad4166ae4dc7270dcd995a","CookieId":335947204,"GroupId":3356314505},
	{"Id":3356314721,"Transtime":"2022-02-20 00:00:02.8868","FingerPrintCode":"66e37de75aad4166ae4dc7270dcd995a","CookieId":335212300,"GroupId":3356314505}
]');



{"Id":3356314495,"Transtime":"2022-02-20 00:00:05.2640","FingerPrintCode":"53b9f5d0e59645d09cfb56690a7b0916","CookieId":244603009,"GroupId":0},
	{"Id":3356314496,"Transtime":"2022-02-20 00:00:05.2757","FingerPrintCode":"e61bec118a0a44869ea57aec2b57d5a6","CookieId":323500147,"GroupId":0},
	{"Id":3356314498,"Transtime":"2022-02-20 00:00:05.4575","FingerPrintCode":"1245f5a2122b4f74b9e09c416497f6e6","CookieId":335528936,"GroupId":0},

SELECT 'DEBUG_3b', t.* FROM Temp_GroupDevice AS t;  
SELECT * FROM Temp_InputTrans AS tmpIt
			INNER JOIN Temp_GroupDevice AS tmpGd ON tmpGd.GroupId = tmpIt.GroupId
		SET	tmpIt.DeviceId = tmpGd.DeviceId; 

CALL FPS_FP_Transform_DeviceIdentify(1,'[
	{"Id":3356314533,"Transtime":"2022-02-20 00:00:06.8377","FingerPrintCode":"89570f7049ce4e9e99ebb4fc86d787bf","CookieId":143368885,"GroupId":3356314533},
	{"Id":3356314535,"Transtime":"2022-02-20 00:00:07.0883","FingerPrintCode":"89570f7049ce4e9e99ebb4fc86d787bf","CookieId":143368885,"GroupId":3356314533}
]');



CALL FPS_FP_Transform_DeviceIdentify_Get_test(100,10);
CALL FPS_FP_Transform_DeviceIdentify_Get(1000);

CREATE TABLE Transaction_BK SELECT * FROM Transaction;

SELECT * FROM INFORMATION_SCHEMA.Tables WHERE TABLE_SCHEMA = 'FPS_FingerPrint';
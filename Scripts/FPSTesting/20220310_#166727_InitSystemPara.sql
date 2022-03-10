/*<info serverAlias="FPSDC-FPSTesting" databaseType="2"></info>*/
/*
	Created: 20220310@Aries.Nguyen [Redmine ID: #166727]
	Task: Init Schema
	DB: FPSTesting
*/
USE FPSTesting;
INSERT INTO `FP_SystemSetting` 
VALUES (1,'DCS_Device_Transform','MinTransId','0','2022-03-09 01:09:09'),
(2,'DCS_Device_Transform','MinCreatedDate','2020-01-01','2022-03-09 01:09:09'),
(94423,'DCS_RawTrans_Transform','MinRawTransId','0','2022-03-09 01:09:09');



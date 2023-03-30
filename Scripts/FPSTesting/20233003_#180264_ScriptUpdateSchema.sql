/*<info serverAlias="FPSDC-FPSTesting" databaseType="2"></info>*/
/*
	Created: 20233003@Jonathan.Doan [Redmine ID: #180264]
	Task: Update Schema
	DB: FPSTesting
*/

USE FPSTesting;

RENAME TABLE FPSTesting.FP_Association TO FPSTesting.FP_Association_Old;
RENAME TABLE FPSTesting.FP_AssociationNew TO FPSTesting.FP_Association;

ALTER TABLE `FPSTesting`.`FP_Association` RENAME INDEX `UX_FP_AssociationNew_AccountIDFPDeviceID` TO `UX_FP_Association_AccountIDFPDeviceID`;
ALTER TABLE `FPSTesting`.`FP_Association` RENAME INDEX `IX_FP_AssociationNew_IsCTSTransformed` TO `IX_FP_Association_IsCTSTransformed`;
ALTER TABLE `FPSTesting`.`FP_Association` RENAME INDEX `IX_FP_AssociationNew_FPDeviceIDAccountID` TO `IX_FP_Association_FPDeviceIDAccountID`;

ALTER TABLE `FPSTesting`.`FP_Association_Old` RENAME INDEX `IX_Association_SubscriberID_AccountID_DeviceID` TO `IX_FP_Association_Old_SubscriberID_AccountID_DeviceID`;
ALTER TABLE `FPSTesting`.`FP_Association_Old` RENAME INDEX `IX_Association_IsCTSTransformed` TO `IX_FP_Association_Old_IsCTSTransformed`;
ALTER TABLE `FPSTesting`.`FP_Association_Old` RENAME INDEX `IX_Association_CTSCustID_DeviceID_AccountID` TO `IX_FP_Association_Old_CTSCustID_DeviceID_AccountID`;

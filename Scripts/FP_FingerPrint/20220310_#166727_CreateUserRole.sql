/*<info serverAlias="FPSDC-FPS_FingerPrint" databaseType="2"></info>*/
/*
	Created: 20220310@Aries.Nguyen [Redmine ID: #166727]
	Task: Init Schema
	DB: FPS_FingerPrint
*/


/*Create Role*/
CREATE ROLE IF NOT EXISTS `RoleFPSOwner`;
GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, ALTER, CREATE TEMPORARY TABLES, LOCK TABLES, EXECUTE, CREATE VIEW, SHOW VIEW, CREATE ROUTINE, ALTER ROUTINE ON `FPS_FingerPrint`.* TO `RoleFPSOwner`@`%`;
GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, ALTER, CREATE TEMPORARY TABLES, LOCK TABLES, EXECUTE, CREATE VIEW, SHOW VIEW, CREATE ROUTINE, ALTER ROUTINE ON `FPSTesting`.* TO `RoleFPSOwner`@`%`;

CREATE ROLE IF NOT EXISTS `RoleFPSReader`;
GRANT SELECT, CREATE TEMPORARY TABLES, EXECUTE ON `FPS_FingerPrint`.* TO `RoleFPSReader`@`%`;
GRANT SELECT, CREATE TEMPORARY TABLES, EXECUTE ON `FPSTesting`.* TO `RoleFPSReader`@`%`;

CREATE ROLE IF NOT EXISTS `RoleFPSWriter`;
GRANT SELECT, INSERT, UPDATE, DELETE, CREATE TEMPORARY TABLES, EXECUTE ON `FPS_FingerPrint`.* TO `RoleFPSWriter`@`%`;
GRANT SELECT, INSERT, UPDATE, DELETE, CREATE TEMPORARY TABLES, EXECUTE ON `FPSTesting`.* TO `RoleFPSWriter`@`%`;


/*Create User Role*/
CREATE USER 'fpsOwner'@'%' IDENTIFIED WITH mysql_native_password BY 'xxxxx';
GRANT `RoleFPSOwner`@`%`,`CTSLogWriter`@`%`  TO `fpsOwner`@`%`;

CREATE USER 'fpsWeb'@'%' IDENTIFIED WITH mysql_native_password BY 'xxxxx';
GRANT `RoleFPSReader`@`%`,`CTSLogWriter`@`%`  TO `fpsWeb`@`%`;
CREATE USER 'fpsWebAdmin'@'%' IDENTIFIED WITH mysql_native_password BY 'xxxxx';
GRANT `RoleFPSWriter`@`%`,`CTSLogWriter`@`%` TO `fpsWebAdmin`@`%`;

CREATE USER 'fpsService'@'%' IDENTIFIED WITH mysql_native_password BY 'xxxxx';
GRANT `RoleFPSReader`@`%`,`CTSLogWriter`@`%` TO `fpsService`@`%`;
CREATE USER 'fpsServiceAdmin'@'%' IDENTIFIED WITH mysql_native_password BY 'xxxxx';
GRANT `RoleFPSWriter`@`%`,`CTSLogWriter`@`%`,`CTSAdminWriter`@`%` TO `fpsServiceAdmin`@`%`;

CREATE USER 'fpsAPI'@'%' IDENTIFIED WITH mysql_native_password BY 'xxxxx';
GRANT `RoleFPSReader`@`%`,`CTSLogWriter`@`%` TO `fpsAPI`@`%`;
CREATE USER 'fpsAPIAdmin'@'%' IDENTIFIED WITH mysql_native_password BY 'xxxxx';
GRANT `RoleFPSWriter`@`%`,`CTSLogWriter`@`%` TO `fpsAPIAdmin`@`%`;

FLUSH PRIVILEGES;
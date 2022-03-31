/*<info serverAlias="FPSDC-FPS_FingerPrint" databaseType="2"></info>*/
/*
	Created: 20220310@Aries.Nguyen [Redmine ID: #166727]
	Task: Init Schema
	DB: FPS_FingerPrint
*/


/*Create Role*/
CREATE ROLE IF NOT EXISTS `FPSOwner`;
GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, ALTER, CREATE TEMPORARY TABLES, LOCK TABLES, EXECUTE, CREATE VIEW, SHOW VIEW, CREATE ROUTINE, ALTER ROUTINE ON `FPS_FingerPrint`.* TO `FPSOwner`@`%`;
GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, ALTER, CREATE TEMPORARY TABLES, LOCK TABLES, EXECUTE, CREATE VIEW, SHOW VIEW, CREATE ROUTINE, ALTER ROUTINE ON `FPSTesting`.* TO `FPSOwner`@`%`;

CREATE ROLE IF NOT EXISTS `FPSReader`;
GRANT SELECT, CREATE TEMPORARY TABLES, EXECUTE ON `FPS_FingerPrint`.* TO `FPSReader`@`%`;
GRANT SELECT, CREATE TEMPORARY TABLES, EXECUTE ON `FPSTesting`.* TO `FPSReader`@`%`;

CREATE ROLE IF NOT EXISTS `FPSWriter`;
GRANT SELECT, INSERT, UPDATE, DELETE, CREATE TEMPORARY TABLES, EXECUTE ON `FPS_FingerPrint`.* TO `FPSWriter`@`%`;
GRANT SELECT, INSERT, UPDATE, DELETE, CREATE TEMPORARY TABLES, EXECUTE ON `FPSTesting`.* TO `FPSWriter`@`%`;


/*Create User Role*/
CREATE USER 'fpsWeb'@'%' IDENTIFIED WITH mysql_native_password BY 'xxxxx';
GRANT `FPSReader`@`%`  TO `fpsWeb`@`%`;
CREATE USER 'fpsWebAdmin'@'%' IDENTIFIED WITH mysql_native_password BY 'xxxxx';
GRANT `FPSWriter`@`%` TO `fpsWebAdmin`@`%`;

CREATE USER 'fpsService'@'%' IDENTIFIED WITH mysql_native_password BY 'xxxxx';
GRANT `FPSReader`@`%`  TO `fpsService`@`%`;
CREATE USER 'fpsServiceAdmin'@'%' IDENTIFIED WITH mysql_native_password BY 'xxxxx';
GRANT `FPSWriter`@`%`,`CTSAdminWriter`@`%` TO `fpsServiceAdmin`@`%`;

CREATE USER 'fpsAPI'@'%' IDENTIFIED WITH mysql_native_password BY 'xxxxx';
GRANT `FPSReader`@`%`  TO `fpsAPI`@`%`;
CREATE USER 'fpsAPIAdmin'@'%' IDENTIFIED WITH mysql_native_password BY 'xxxxx';
GRANT `FPSWriter`@`%` TO `fpsAPIAdmin`@`%`;

FLUSH PRIVILEGES;
/*<info serverAlias="FPSDC-FPSTesting" databaseType="2" executers="fpsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `FP_DCS_DC_Transform_Account_UpdateLastLoginTime`;

DELIMITER $$
CREATE DEFINER=`fpsOwner`@`%` PROCEDURE `FP_DCS_DC_Transform_Account_UpdateLastLoginTime`(
		IN BatchSize 	INT
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20210705@Aries.Nguyen
		Task:		Fix deadlock issue [Redmine ID: #157203]
		DB:			DCS_DataCenter
		Original:

		Revisions:
			- 20210705@Aries.Nguyen: Created
			
		Param's Explanation (filtered by):
		
        Examples: 
			CALL FP_DCS_DC_Transform_Account_UpdateLastLoginTime(1);
	*/ 
	/*******LOG TEST********************/
    IF (SELECT ofs.OffsetValue FROM FPS_FingerPrint.Offset AS ofs) = 1 THEN		
		INSERT INTO CTS_Log.FPSLog(SpName, JsonString, OtherText, InsertTime)
		SELECT 'FP_DCS_DC_Transform_Account_UpdateLastLoginTime', NULL,CONCAT('BatchSize:',BatchSize), CURRENT_TIMESTAMP();
	END IF;
    /*******LOG TEST********************/
    
    DROP TEMPORARY TABLE IF EXISTS Temp_AccountLastLoginTimeProcess;  
	CREATE TEMPORARY TABLE Temp_AccountLastLoginTimeProcess(
			ID 				BIGINT UNSIGNED
		,	AccountID 		BIGINT UNSIGNED
		,	LastLoginTime 	TIMESTAMP(4) NOT NULL
		,	PRIMARY KEY (ID)     
        ,	INDEX 			IX_Temp_AccountLastLoginTimeProcess_AccountID(AccountID)
    );
    
    INSERT INTO Temp_AccountLastLoginTimeProcess(ID, AccountID, LastLoginTime)
    SELECT 	acc.ID
		,	acc.AccountID
        ,	acc.LastLoginTime
    FROM FPSTesting.FP_AccountLastLoginTimeProcess AS acc
    ORDER BY acc.ID ASC
    LIMIT BatchSize;
    
    UPDATE FPSTesting.FP_Account 	AS acc
        INNER JOIN	Temp_AccountLastLoginTimeProcess AS tll ON acc.AccountID = tll.AccountID
	SET	 acc.LastLoginTime = tll.LastLoginTime; 
    
    DELETE FROM FPSTesting.FP_AccountLastLoginTimeProcess AS acc
    WHERE acc.ID IN (SELECT ID FROM Temp_AccountLastLoginTimeProcess);    

END$$
DELIMITER ;

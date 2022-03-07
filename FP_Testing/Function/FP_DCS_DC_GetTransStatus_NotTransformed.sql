/*<info serverAlias="FPSDC-FPTesting" databaseType="2" executers="fpsServiceAdmin" isFunction="1" isNested="1"></info>*/
DROP FUNCTION IF EXISTS FP_DCS_DC_GetTransStatus_NotTransformed;

DELIMITER $$

CREATE DEFINER=`FPSOwner`@`%` FUNCTION FP_DCS_DC_GetTransStatus_NotTransformed()

RETURNS TINYINT

DETERMINISTIC
SQL SECURITY INVOKER
BEGIN
/*
	Created: 20190610@Casey.Huynh
	Task : Return the value of all TransStatus that Not Transform
	DB: DCS_DataCenter
	Original:

	Revisions:
		- 20220106@CaseyHuynh: Created [RedmineID: #166727]
        
	Param's Explanation (filtered by):
	
    Example:
	SELECT FP_DCS_DC_GetTransStatus_NotTransformed();	
    
*/

	DECLARE vrTransStatus BIT(16) DEFAULT 0;
	DECLARE vrTransStatus_i BIT(16) DEFAULT 0;
	
	DROP TEMPORARY TABLE IF EXISTS Temp_NotTransformedStatus;
	CREATE TEMPORARY TABLE Temp_NotTransformedStatus(
		TransStatus BIT(16)
	);
	
	INSERT INTO Temp_NotTransformedStatus(TransStatus)
	SELECT  StatusValue
	FROM 	FPTesting.FP_TransStatus
	WHERE	IsTransformed = 0;

	WHILE EXISTS (SELECT 1 FROM Temp_NotTransformedStatus LIMIT 1)
	DO
		SET vrTransStatus_i = (SELECT TransStatus FROM Temp_NotTransformedStatus LIMIT 1);        
		SET vrTransStatus = vrTransStatus | vrTransStatus_i;
		
		DELETE	ts
		FROM	Temp_NotTransformedStatus ts
		WHERE 	ts.TransStatus = vrTransStatus_i;        
	END WHILE;
	RETURN vrTransStatus;
END$$

DELIMITER ;


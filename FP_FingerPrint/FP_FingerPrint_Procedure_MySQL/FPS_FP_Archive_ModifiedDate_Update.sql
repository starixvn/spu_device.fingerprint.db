/*<info serverAlias="FPSDC-FPS_FingerPrint" databaseType="2" executers="fpsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `FPS_FP_Archive_ModifiedDate_Update`;
DELIMITER $$

CREATE DEFINER=`fpsOwner`@`%` PROCEDURE `FPS_FP_Archive_ModifiedDate_Update`(
	ip_BatchSize INT
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20220628@Jonathan.Doan
		Task :		
		DB:			FPS_FingerPrint
		Original:

		Revisions:
			- 20220628@Jonathan.Doan: Created [Redmine ID: #174020]
            
		Param's Explanation (filtered by):

		Example:
			CALL FPS_FP_Archive_ModifiedDate_Update(100);
	*/
    DECLARE lv_offsetId INT DEFAULT 11;
    DECLARE lv_offsetValue BIGINT;
    DECLARE lv_maxOffsetValue BIGINT;

    /*******LOG TEST********************/
    IF (SELECT ofs.OffsetValue FROM FPS_FingerPrint.Offset AS ofs WHERE Id = 7) = 1 THEN
		INSERT INTO CTS_Log.FPSLog(SpName, JsonString, OtherText, InsertTime)
		SELECT 'FPS_FP_Archive_ModifiedDate_Update', NULL,CONCAT('ip_BatchSize:',ip_BatchSize), CURRENT_TIMESTAMP();
    END IF;
    /*******LOG TEST********************/

    /*******INIT TEMPORARY TABLE********************/
    DROP TEMPORARY TABLE IF EXISTS Temp_Transaction;
	CREATE TEMPORARY TABLE Temp_Transaction(
        	Id					BIGINT UNSIGNED PRIMARY KEY
        ,	RawFingerPrintId	BIGINT UNSIGNED
        ,	CookieId			BIGINT UNSIGNED
        ,	DeviceId			BIGINT UNSIGNED
        ,	TransTime			DATETIME(4)
        , 	INDEX IX_Temp_Transaction_TransTime(TransTime)
    );

    DROP TEMPORARY TABLE IF EXISTS Temp_Device;
	CREATE TEMPORARY TABLE Temp_Device(
        	DeviceId			BIGINT UNSIGNED PRIMARY KEY
        ,	TransTime			DATETIME(4)
        , 	INDEX IX_Temp_Device_TransTime(TransTime)
    );

    DROP TEMPORARY TABLE IF EXISTS Temp_DeviceFingerPrint;
	CREATE TEMPORARY TABLE Temp_DeviceFingerPrint(
			RawFingerPrintId	BIGINT UNSIGNED PRIMARY KEY
        ,	TransTime			DATETIME(4)
        , 	INDEX IX_Temp_DeviceFingerPrint_TransTime(TransTime)
    );

    DROP TEMPORARY TABLE IF EXISTS Temp_DeviceCookie;
	CREATE TEMPORARY TABLE Temp_DeviceCookie(
			CookieId			BIGINT UNSIGNED PRIMARY KEY
        ,	TransTime			DATETIME(4)
        , 	INDEX IX_Temp_DeviceCookie_TransTime(TransTime)
    );

    /*******INIT DATA********************/
    SELECT off.OffsetValue
    INTO lv_offsetValue
    FROM FPS_FingerPrint.Offset AS off
    WHERE off.Id = lv_offsetId;

    INSERT INTO Temp_Transaction(Id, RawFingerPrintId, CookieId, DeviceId, TransTime)
    SELECT 	Id
        ,	RawFingerPrintId
        ,	CookieId
        ,	DeviceId
        ,	TransTime
	FROM FPS_FingerPrint.TransactionCompleted
	WHERE Id > lv_offsetValue
		AND DeviceId IS NOT NULL
		AND CookieId IS NOT NULL
	LIMIT ip_BatchSize;

    INSERT INTO Temp_Device(DeviceId, TransTime)
    SELECT 	DeviceId
		,	MAX(TransTime)
    FROM Temp_Transaction
    GROUP BY DeviceId;

    INSERT INTO Temp_DeviceFingerPrint(RawFingerPrintId, TransTime)
    SELECT 	RawFingerPrintId
		,	MAX(TransTime)
    FROM Temp_Transaction
    GROUP BY RawFingerPrintId;

    INSERT INTO Temp_DeviceCookie(CookieId, TransTime)
    SELECT 	CookieId
		,	MAX(TransTime)
    FROM Temp_Transaction
    GROUP BY CookieId;
    
    SELECT MAX(Id)
    INTO lv_maxOffsetValue
    FROM Temp_Transaction;

    /*******UPDATE DATA********************/
	UPDATE FPS_FingerPrint.Device AS dv
		INNER JOIN Temp_Device AS tmp ON dv.Id = tmp.DeviceId
	SET dv.ModifiedDate = tmp.TransTime;

	UPDATE FPS_FingerPrint.DeviceFingerPrint AS df
		INNER JOIN Temp_DeviceFingerPrint AS tmp ON df.RawFingerPrintId = tmp.RawFingerPrintId
	SET df.ModifiedDate = tmp.TransTime;

	UPDATE FPS_FingerPrint.DeviceCookie AS dc
		INNER JOIN Temp_DeviceCookie AS tmp ON dc.CookieId = tmp.CookieId
	SET dc.ModifiedDate = tmp.TransTime;
    
    IF lv_maxOffsetValue IS NOT NULL
    THEN
		UPDATE FPS_FingerPrint.Offset
		SET OffsetValue = lv_maxOffsetValue
		WHERE Id = lv_offsetId;
    END IF;

END$$
DELIMITER ;

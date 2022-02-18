/*<info serverAlias="xxxx" databaseType="2" executers="fpsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `FPS_FP_DeviceIdentify`;
DELIMITER $$

CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `FPS_FP_DeviceIdentify`(
		ip_BatchSize INT
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20220218@Terry.Nguyen
		Task :		
		DB:			FPS_FingerPrint
		Original:

		Revisions:
            
		Param's Explanation (filtered by):	

		Example:
			- CALL FPS_FP_DeviceIdentify(100);
			
	*/
    DECLARE lv_transId BIGINT DEFAULT 0;	
    DECLARE lv_deviceId BIGINT;
    DECLARE lv_currentDate DATETIME DEFAULT NOW();
    
    DECLARE lv_flag BOOLEAN DEFAULT TRUE;
    
	DROP TEMPORARY TABLE IF EXISTS Temp_Transaction;    
    
	CREATE TEMPORARY TABLE Temp_Transaction(
		Id 					BIGINT SIGNED PRIMARY KEY,              
        FingerPrintCode 	VARCHAR(200),
        CookieId			BIGINT,
        DeviceId			BIGINT,  
        IsRecovered			BOOLEAN DEFAULT FALSE,
		CreatedDate			DATETIME,
        ModifiedDate		DATETIME,
        INDEX isRecoverd_Index (IsRecovered),
        INDEX FingerPrintCode_Index (FingerPrintCode)
    ) ENGINE = MEMORY;
    
    INSERT INTO Temp_Transaction(Id, FingerPrintCode, CookieId, CreatedDate, ModifiedDate)
    SELECT trans.Id, trans.FingerPrintCode, trans.CookieId, lv_currentDate, lv_currentDate
    FROM FPS_FingerPrint.Transaction trans
    WHERE trans.DeviceId Is NULL
    ORDER BY Id ASC
    LIMIT ip_BatchSize;  
    
    WHILE(lv_flag) DO
		BEGIN		
			
            # Recover By FingerPrint =========================
			UPDATE 	Temp_Transaction tmp 
				INNER JOIN FPS_FingerPrint.DeviceFingerPrint df ON tmp.FingerPrintCode = df.FingerPrintCode                
			SET 
				tmp.DeviceId = df.DeviceId,
                tmp.IsRecovered = 1            
            WHERE tmp.IsRecovered = 0;
            
            INSERT INTO FPS_FingerPrint.DeviceFingerPrint(DeviceId, FingerPrintCode, CreatedDate, ModifiedDate)
            SELECT DISTINCT tmp.DeviceId, tmp.FingerPrintCode, tmp.CreatedDate, tmp.ModifiedDate 
				FROM Temp_Transaction tmp 
                WHERE tmp.IsRecovered = 1
                GROUP BY tmp.DeviceId, tmp.FingerPrintCode, tmp.CreatedDate, tmp.ModifiedDate
            ON DUPLICATE KEY UPDATE ModifiedDate = lv_currentDate;
            
            INSERT INTO FPS_FingerPrint.DeviceCookie(DeviceId, CookieId, CreatedDate, ModifiedDate)
			SELECT DISTINCT tmp.DeviceId, tmp.CookieId, tmp.CreatedDate, tmp.ModifiedDate 
				FROM Temp_Transaction tmp                
                WHERE tmp.IsRecovered = 1
                GROUP BY tmp.DeviceId, tmp.CookieId, tmp.CreatedDate, tmp.ModifiedDate 
            ON DUPLICATE KEY UPDATE ModifiedDate = lv_currentDate; 
            #============================================
            
            # Recover By Cookie =========================
            UPDATE 	Temp_Transaction tmp 				
                INNER JOIN FPS_FingerPrint.DeviceCookie dc ON tmp.CookieId = dc.CookieId
			SET 
				tmp.DeviceId =  dc.DeviceId,
                tmp.IsRecovered = 1            
            WHERE tmp.IsRecovered = 0;           
            
            INSERT INTO FPS_FingerPrint.DeviceFingerPrint(DeviceId, FingerPrintCode, CreatedDate, ModifiedDate)
            SELECT DISTINCT tmp.DeviceId, tmp.FingerPrintCode, tmp.CreatedDate, tmp.ModifiedDate 
				FROM Temp_Transaction tmp 
                WHERE tmp.IsRecovered = 1
                GROUP BY tmp.DeviceId, tmp.FingerPrintCode, tmp.CreatedDate, tmp.ModifiedDate
            ON DUPLICATE KEY UPDATE ModifiedDate = lv_currentDate;
            
            INSERT INTO FPS_FingerPrint.DeviceCookie(DeviceId, CookieId, CreatedDate, ModifiedDate)
			SELECT DISTINCT tmp.DeviceId, tmp.CookieId, tmp.CreatedDate, tmp.ModifiedDate 
				FROM Temp_Transaction tmp                
                WHERE tmp.IsRecovered = 1
                GROUP BY tmp.DeviceId, tmp.CookieId, tmp.CreatedDate, tmp.ModifiedDate 
            ON DUPLICATE KEY UPDATE ModifiedDate = lv_currentDate; 
            #============================================
            
            IF NOT EXISTS(SELECT 1 FROM Temp_Transaction tmp 
								INNER JOIN FPS_FingerPrint.DeviceFingerPrint df ON tmp.FingerPrintCode = df.FingerPrintCode
                                INNER JOIN FPS_FingerPrint.DeviceCookie dc ON tmp.CookieId = dc.CookieId
						  WHERE tmp.IsRecovered = 0) THEN
				BEGIN
					SELECT Min(Id) INTO lv_transId FROM Temp_Transaction tmp WHERE tmp.IsRecovered = 0; 
                    
					INSERT INTO FPS_FingerPrint.Devices(CreatedDate, ModifiedDate) VALUE(lv_currentDate, lv_currentDate);
                    
					SELECT MAX(Id) INTO lv_DeviceId FROM FPS_FingerPrint.Devices;
                    
					UPDATE Temp_Transaction tmp 
					SET 
						tmp.DeviceId = lv_DeviceId,
						tmp.IsRecovered = 1 
					WHERE tmp.Id = lv_transId;
                    
                    INSERT INTO FPS_FingerPrint.DeviceFingerPrint(DeviceId, FingerPrintCode, CreatedDate, ModifiedDate)
                    SELECT tmp.DeviceId, tmp.FingerPrintCode, tmp.CreatedDate, tmp.ModifiedDate  
						FROM Temp_Transaction tmp 
                        WHERE tmp.Id = lv_transId AND tmp.IsRecovered = 1 ;
                    
                    INSERT INTO FPS_FingerPrint.DeviceCookie(DeviceId, CookieId, CreatedDate, ModifiedDate)
                    SELECT tmp.DeviceId, tmp.CookieId, tmp.CreatedDate, tmp.ModifiedDate 
						FROM Temp_Transaction tmp 
                        WHERE tmp.Id = lv_transId AND tmp.IsRecovered = 1 ;
				END;
            END IF;
            
            SELECT IF(COUNT(1) > 0, TRUE, FALSE) INTO lv_flag 
				FROM Temp_Transaction temp 
                WHERE temp.IsRecovered = 0 LIMIT 1;
		END;
        
    END WHILE;   
    
    UPDATE FPS_FingerPrint.Transaction trans INNER JOIN Temp_Transaction tmp ON trans.Id = tmp.Id
    SET 
		trans.DeviceId = tmp.DeviceId
    WHERE tmp.IsRecovered = 1;
END$$
DELIMITER ;

GRANT EXECUTE ON PROCEDURE FPS_FingerPrint.FPS_FP_DeviceIdentify TO 'fpsServiceAdmin'@'%';
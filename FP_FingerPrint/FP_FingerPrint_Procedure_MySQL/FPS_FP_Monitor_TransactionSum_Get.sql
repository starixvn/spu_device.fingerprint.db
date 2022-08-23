/*<info serverAlias="FPSDC-FPS_FingerPrint" databaseType="2" executers="fpsService" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `FPS_FP_Monitor_TransactionSum_Get`;
DELIMITER $$

CREATE DEFINER=`fpsOwner`@`%` PROCEDURE `FPS_FP_Monitor_TransactionSum_Get`(
		ip_FromDate	DATE,
		ip_ToDate 	DATE
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20220324@Jonathan.Doan
		Task :		
		DB:			FPS_FingerPrint
		Original:

		Revisions: 
			- 20220819@Jonathan.Doan: Created [Redmine ID: #176851]
            
		Param's Explanation (filtered by):	

		Example:
			- CALL FPS_FP_Monitor_TransactionSum_Get('03/2022');
			
	*/
   
    /*******LOG TEST********************/
    IF (SELECT ofs.OffsetValue FROM FPS_FingerPrint.Offset AS ofs WHERE ofs.Id = 7) = 1 THEN		
		INSERT INTO CTS_Log.FPSLog(SpName, JsonString, OtherText, InsertTime)
		SELECT 'FPS_FP_Monitor_TransactionSum_Get', NULL, CONCAT('ip_FromDate:',DATE_FORMAT(ip_FromDate, '%Y-%m-%d %T'),', ip_ToDate:',DATE_FORMAT(ip_ToDate, '%Y-%m-%d %T')), CURRENT_TIMESTAMP();
	END IF;
    /*******LOG TEST********************/
    
    -- Server monthly sum
    WITH tmp_SumDaily AS
    (
		SELECT 	st.SubscriberId
			, 	SUM(st.TotalTrans) AS TotalTrans
			, 	SUM(st.TotalValidTrans) AS TotalValidTrans
		FROM FPS_FingerPrint.ServerTransactionDailySum AS st 
		WHERE st.TransDate BETWEEN ip_FromDate AND DATE_ADD(ip_ToDate, INTERVAL 1 DAY)
		GROUP BY st.SubscriberId
	)
    SELECT 	sub.Name AS SubscriberName	
		,	tmp.TotalTrans	
		,	tmp.TotalValidTrans	
    FROM tmp_SumDaily AS tmp
		INNER JOIN FPS_FingerPrint.Subscribers AS sub ON sub.Id = tmp.SubscriberId;

   -- Client monthly sum
    WITH tmp_SumDaily AS
    (
		SELECT 	ct.SubscriberId
			, 	SUM(ct.TotalTrans) AS TotalTrans
			, 	SUM(ct.TotalValidTrans) AS TotalValidTrans
		FROM FPS_FingerPrint.ClientTransactionDailySum AS ct 
		WHERE ct.TransDate BETWEEN ip_FromDate AND DATE_ADD(ip_ToDate, INTERVAL 1 DAY)
		GROUP BY ct.SubscriberId
	)
    SELECT 	sub.Name AS SubscriberName
		,	tmp.TotalTrans
		,	tmp.TotalValidTrans
    FROM tmp_SumDaily AS tmp
		INNER JOIN FPS_FingerPrint.Subscribers AS sub ON sub.Id = tmp.SubscriberId;

   -- Transaction sum
    WITH tmp_TransactionSum AS
    (
		SELECT 	st.SubscriberId
			, 	SUM(st.TotalTrans) AS TotalTrans
		FROM FPS_FingerPrint.TransactionDailySum AS st
		WHERE st.TransDate BETWEEN ip_FromDate AND DATE_ADD(ip_ToDate, INTERVAL 1 DAY)
		GROUP BY st.SubscriberId
	)
    SELECT 	sub.Name AS SubscriberName
		,	tmp.TotalTrans
		,	NULL AS TotalValidTrans
    FROM tmp_TransactionSum AS tmp
		INNER JOIN FPS_FingerPrint.Subscribers AS sub ON sub.Id = tmp.SubscriberId;
    
END$$
DELIMITER ;

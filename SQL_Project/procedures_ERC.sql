USE erc;
-- ********************************************************************************************************************************************************************
-- функция контроля правильности выбора норматива потребления э/э в соответсвии с количеством комнат и числом жильцов
DROP FUNCTION IF EXISTS tariff_control;
 
DELIMITER //
 
CREATE FUNCTION tariff_control(a int,b int) RETURNS int
       DETERMINISTIC
       
 BEGIN
       DECLARE result INT;
	IF a> 4 THEN SET a=4;
       END IF;
	IF b> 5 THEN  SET b=5;
       END IF;

SELECT id INTO result
  FROM standards_consumption  
 WHERE number_of_rooms = a AND inhabitants_number = b;
RETURN (result); 
END//
 
DELIMITER ;
-- ********************************************************************************************************************************************************************
-- Предополагается, что процедуры запускаются ежемесячно и производят только текущие расчеты (запуск в ноябре будет производить расчеты за октябрь).
-- делать перерасчет предыдущих периодов не предполагается
-- ********************************************************************************************************************************************************************
-- процедура выполняется перед расчетами, проверят подошел ли срок поверки прибора учета согласно его типу на текущую дату.
-- Если подошел, то меняет его статут на "Необходима поверка", далее триггер исключит эти приборы учета из расчетов за э/э
DROP PROCEDURE IF EXISTS checkout_devices
DELIMITER //
CREATE PROCEDURE checkout_devices()
BEGIN
	UPDATE metering_devices SET equipment_status_id = 
		  (SELECT id 
	 	   FROM equipment_statuses 
	       WHERE name ='Необходима поверка')
    WHERE DATE(NOW()) > DATE_ADD(calibration_date, INTERVAL
          (SELECT calibration_interval 
           FROM device_types 
           WHERE device_types.id = metering_devices.device_type_id) YEAR);
END //
DELIMITER ;
-- ********************************************************************************************************************************************************************
-- процедура выполняет расчет платы за э/э за текущий период.

DROP PROCEDURE IF EXISTS energy_accounting;
DELIMITER //
CREATE PROCEDURE energy_accounting()
 BEGIN 
	   DECLARE out_of_limit DECIMAL;
	   DECLARE period1, period2 DATE;
-- 	   DECLARE comm_use DECIMAL;
	  

 START TRANSACTION;

DROP TABLE IF EXISTS temp1; -- таблица промежуточных расчетов
CREATE TEMPORARY TABLE temp1
(
personal_account_id BIGINT,
accounting_type_id BIGINT,
accounting_period DATE,
individual_energy_demand DECIMAL,
individual_use_charge DECIMAL,
flat_space DECIMAL,
tariff_rate DECIMAL,
house_id BIGINT
);

DROP TABLE IF EXISTS temp_ind_total; -- таблица расчетов индивидуального потребления
CREATE TEMPORARY TABLE temp_ind_total
(
personal_account_id BIGINT,
accounting_type_id BIGINT,
accounting_period DATE,
individual_energy_demand DECIMAL,
individual_use_charge DECIMAL,
flat_space DECIMAL,
tariff_rate DECIMAL,
house_id BIGINT
);

DROP TABLE IF EXISTS temp_acc_odn; -- таблица расчетов ОДН по домам
CREATE TEMPORARY TABLE temp_acc_odn
(
house_id BIGINT,
commual_energy_demand DECIMAL,
res_space DECIMAL
);


--    SET period1 = DATE_SUB(DATE_SUB(CURDATE(), INTERVAL (DAY(CURDATE()-1)) DAY), INTERVAL 1 MONTH); -- начало расчетного периода -- так должно быть по умолчанию
--    SET period2 = DATE_SUB(DATE_SUB(CURDATE(), INTERVAL (DAY(CURDATE()-1)) DAY), INTERVAL 2 MONTH); -- начало предыдущего месяца
     
     SET period1 = '2020-10-01'; -- установлено для проверочных целей
     SET period2 = '2020-09-01';
     SET out_of_limit = 2000;
    
    IF EXISTS(SELECT * FROM energy_accounting WHERE accounting_period = period1) -- прервать процедуру если месяц уже расчитан
  THEN
  	   SIGNAL SQLSTATE '45005' SET MESSAGE_TEXT = 'Период уже рассчитан';
   END IF;
  
-- расчеты для потребителей, передавших показания (с учетом контроля исправности ПУ и проверки превышения лимита расхода электричества)
 INSERT INTO temp1 (personal_account_id, accounting_type_id, accounting_period, individual_energy_demand, individual_use_charge, flat_space, tariff_rate, house_id) 
 
 SELECT DISTINCT(pa.id),
        (SELECT id FROM accounting_types at2 WHERE name = 'По показаниям ПУ'), 
        period1,
        (mr2.meters_reading - mr.meters_reading),
        t2.tariff_rate * (mr2.meters_reading - mr.meters_reading),
        pa.flat_space,
        t2.tariff_rate,
        pa.house_id

  FROM personal_accounts pa
  LEFT JOIN metering_devices md 
       ON pa.metering_device_id = md.id 
  LEFT JOIN meters_reading mr
       ON pa.metering_device_id = mr.metering_device_id 
  LEFT JOIN meters_reading mr2 
       ON pa.metering_device_id = mr2.metering_device_id
  LEFT JOIN tariffs t2
       ON pa.tariff_id = t2.id 
 WHERE (mr2.accounting_period = period1) AND (mr.accounting_period = period2) AND (ABS(mr2.meters_reading - mr.meters_reading) < out_of_limit) AND (pa.status = 'открыт');

INSERT INTO temp_ind_total -- добавление данных в итоговую временную таблицу
SELECT * FROM temp1;
TRUNCATE TABLE temp1;

-- расчеты по нормативу для потребителей у которых не установлен/ неисправен ПУ или расход превышеает допустимый для расчетов лимит (некорретные показания ПУ)

INSERT INTO temp1  
SELECT DISTINCT(pa.id),
       IF ((SELECT COUNT(*) FROM meters_reading WHERE (metering_device_id = pa.metering_device_id) AND (accounting_period = period1)) > 0,
       (SELECT id FROM accounting_types WHERE name = 'Превышение лимита/норматив'),
       (SELECT id FROM accounting_types WHERE name = 'По нормативу')),
       period1,
       pa.inhabitants_number * sc.normative_rate,
       pa.inhabitants_number * sc.normative_rate * t2.tariff_rate,
       pa.flat_space,
       t2.tariff_rate,
       pa.house_id 
       
 FROM personal_accounts pa
 LEFT JOIN standards_consumption sc
      ON pa.standard_consumption_id = sc.id
 LEFT JOIN tariffs t2
      ON pa.tariff_id = t2.id 
WHERE pa.id NOT IN (SELECT personal_account_id FROM temp_ind_total) AND pa.status = 'открыт';

INSERT INTO temp_ind_total -- добавление данных в итоговую временную таблицу
SELECT * FROM temp1;

-- расчет расхода электроэнергии на общедомовые нужды, с расбивкой по домам
INSERT INTO temp_acc_odn 
SELECT h.id, ((mr2.meters_reading - mr.meters_reading) * md.СT_ratio - SUM(tit.individual_energy_demand)), h.residential_space 
  FROM personal_accounts pa
   LEFT JOIN houses h 
        ON pa.house_id = h.id
   LEFT JOIN metering_devices md 
        ON h.metering_device_id = md.id
   LEFT JOIN meters_reading mr2 
        ON h.metering_device_id = mr2.metering_device_id
   LEFT JOIN meters_reading mr 
        ON h.metering_device_id = mr.metering_device_id
   LEFT JOIN temp_ind_total tit
        ON tit.personal_account_id =pa.id
  WHERE mr2.accounting_period = period1 AND mr.accounting_period = period2
  GROUP BY h.id;


INSERT INTO energy_accounting (personal_account_id,
                               accounting_type_id,
                               accounting_period,
                               individual_energy_demand,
                               communal_energy_demand,
                               individual_use_charge,
                               communal_use_charge)
                               
SELECT DISTINCT(personal_account_id), tit.accounting_type_id, tit.accounting_period, tit.individual_energy_demand,
       (tit.flat_space / tao.res_space * tao.commual_energy_demand), -- объем ОДН на человека
       tit.individual_use_charge,
       (tit.flat_space / tao.res_space * tao.commual_energy_demand * tit.tariff_rate) -- плата ОДН на человека
  FROM temp_ind_total tit
  LEFT JOIN temp_acc_odn tao
       ON tao.house_id = tit.house_id;
   
--   DROP TABLE temp1;
--   DROP TABLE temp_ind_total;
--   DROP TABLE temp_acc_odn;
  
 COMMIT;
END //

DELIMITER ;
-- установка текущих показаний для потребителей, не предавших показнания и исправление показаний не принятых к расчету 
-- (текущие показания приравниваются к предыдущим + насчитанный норматив), 
-- эти показания будут использоваться в следующем мясяце
-- ********************************************************************************************************************************************************************
DROP PROCEDURE IF EXISTS metered_values_control;
DELIMITER //

CREATE PROCEDURE metered_values_control()
BEGIN
	DECLARE period1, period2 DATE;
  -- SET period1 = DATE_SUB(DATE_SUB(CURDATE(), INTERVAL (DAY(CURDATE()-1)) DAY), INTERVAL 1 MONTH); -- начало расчетного периода -- так должно быть по умолчанию
  -- SET period2 = DATE_SUB(DATE_SUB(CURDATE(), INTERVAL (DAY(CURDATE()-1)) DAY), INTERVAL 2 MONTH); -- начало расчетного периода -- так должно быть по умолчанию
     SET period1 = '2020-10-01'; -- установлено для проверочных целей
     SET period2 = '2020-09-01'; -- установлено для проверочных целей
     
UPDATE meters_reading mr 
  JOIN meters_reading mr2
	   ON mr.metering_device_id = mr2.metering_device_id
  JOIN personal_accounts pa
	   ON mr.metering_device_id = pa.metering_device_id
  JOIN energy_accounting ea
	   ON pa.id = ea.personal_account_id
   SET mr.meters_reading = mr2.meters_reading + ea.individual_energy_demand
 WHERE (ea.accounting_type_id != 1) AND (ea.accounting_period = period1) AND (mr2.accounting_period = period2) AND (mr.accounting_period = period1);

INSERT INTO meters_reading(metering_device_id, meters_reading, accounting_period)
SELECT mr.metering_device_id, meters_reading + ea.individual_energy_demand,  period1
  FROM personal_accounts pa
  JOIN meters_reading mr 
       ON pa.metering_device_id = mr.metering_device_id
  JOIN energy_accounting ea 
       ON pa.id = ea.personal_account_id
 WHERE mr.metering_device_id NOT IN (SELECT DISTINCT(metering_device_id) FROM meters_reading WHERE accounting_period = period1);

END //
DELIMITER ;

CALL checkout_devices() ;  -- проверяет не подошел ли срок поверки на текущую дату и ставит соствествующий статус в табице

CALL energy_accounting();  -- осуществляет расчеты за э/э в соответсвии со всеми условиями и ограничениями и заполняет таблицу energy_accounting

-- ******************************************************************************************************************************************************
-- Данные потребителей, показания которых не были приняты к расчетам, т.к. привышают лимит 2000кВч. Они рассчитывались по нормативу (для направления к ним контролеров)

SELECT 
       c.surname AS 'Фамилия',
       c.name AS 'Имя',
       c.patronymic AS 'Отчество',
       s2.name  AS 'Улица',
       h.house_number  AS 'Дом',
       pa.flat_number  AS 'Квартира',
       mr2.meters_reading  AS 'Конечные показания',
       mr.meters_reading  AS 'Начальные показания',
       (mr2.meters_reading - mr.meters_reading)  AS 'Расход электричества'
  FROM personal_accounts pa 
  JOIN consumers c 
       ON pa.consumer_id = c.id
  JOIN energy_accounting ea  
       ON ea.personal_account_id = pa.id
  JOIN houses h
       ON pa.house_id = h.id
  JOIN streets s2 
       ON h.street_id = s2.id 
  JOIN meters_reading mr
       ON pa.metering_device_id = mr.metering_device_id 
  JOIN meters_reading mr2 
       ON pa.metering_device_id = mr2.metering_device_id
 WHERE (mr2.accounting_period = '2020-10-01') AND (mr.accounting_period = '2020-09-01') AND ea.accounting_type_id = 3;

-- ****************************************************************************************************************************************************** 
-- установка текущих показаний для потребителей, не предавших показнания и исправление показаний не принятых к расчету 
-- (текущие показания приравниваются к предыдущим + насчитанный норматив), 
-- эти показания будут использоваться в следующем мясяце
  CALL metered_values_control();  
  
 -- ****************************************************************************************************************************************************
 -- Данные пользователей с максимальным индивидуальным потреблением э/э  ПРЕДСТАВЛЕНИЕ
CREATE OR REPLACE VIEW max_energy_consamption AS
SELECT c.surname AS 'Фамилия',
       c.name AS 'Имя',
       c.patronymic AS 'Отчество',
       s2.name  AS 'Улица',
       h.house_number  AS 'Дом',
       pa.flat_number  AS 'Квартира',
       ea.individual_energy_demand AS 'потребление кВтч',
       md.factory_number  AS 'Номер счетчика'
  FROM personal_accounts pa 
  LEFT JOIN consumers c 
       ON pa.consumer_id = c.id
  LEFT JOIN energy_accounting ea  
       ON ea.personal_account_id = pa.id
  LEFT JOIN houses h
       ON h.id = pa.house_id 
  LEFT JOIN streets s2 
       ON h.street_id = s2.id
  LEFT JOIN metering_devices md
       ON pa.metering_device_id = md.id
 ORDER BY ea.individual_energy_demand DESC;

SELECT * FROM max_energy_consamption LIMIT 10;

-- *****************************************************************************************************************************************************
-- Приборы учета и их тип, у которых в ближайшие 3 месяца наступит очердной срок поверки. (Куда направить электриков.)   ПРЕДСТАВЛЕНИЕ
CREATE OR REPLACE VIEW metering_devices_calibration AS
SELECT c.surname AS 'Фамилия',
       c.name AS 'Имя',
       c.patronymic AS 'Отчество',
       s2.name  AS 'Улица',
       h.house_number  AS 'Дом',
       pa.flat_number  AS 'Квартира',
       md.factory_number  AS 'Номер счетчика',
       dt.name AS 'Тип ПУ',
       md.calibration_date  AS 'дата предыдущей поверки',
       DATE_ADD(md.calibration_date, INTERVAL dt.calibration_interval YEAR)  AS 'дата следующей поверки'
  FROM personal_accounts pa 
  JOIN consumers c 
       ON pa.consumer_id = c.id
  JOIN houses h
       ON h.id = pa.house_id 
  JOIN streets s2 
       ON h.street_id = s2.id
  JOIN metering_devices md
       ON pa.metering_device_id = md.id
  JOIN device_types dt 
       ON md.device_type_id = dt.id
 WHERE  DATE_ADD(md.calibration_date, INTERVAL dt.calibration_interval YEAR) <
        DATE_ADD(CURDATE(), INTERVAL 3 MONTH);
       
SELECT * FROM metering_devices_calibration;

-- *****************************************************************************************************************************************************
-- Анализ начислений платы за э/э в разрезе домов
SELECT DISTINCT(h.id),
       s2.name AS 'улица',
       h.house_number AS 'Номер дома',
       MAX(ea.total_charge) OVER w AS 'максимальное начисление',
       AVG(ea.total_charge) OVER w AS 'среднее начисление',
       SUM(ea.total_charge) OVER w AS 'сумма всех начислений',
       SUM(ea.total_charge) OVER w * 100 /
       SUM(ea.total_charge) OVER() AS '%%'
  FROM energy_accounting ea 
  LEFT JOIN personal_accounts pa
       ON ea.personal_account_id = pa.id
  LEFT JOIN houses h
       ON h.id = pa.house_id 
  LEFT JOIN streets s2 
       ON h.street_id = s2.id
WINDOW w AS (PARTITION BY h.id);

-- *****************************************************************************************************************************************************
-- Самые распространненые типы приборов учета из действующих (привязанных к ЛС) и его параметры
SELECT COUNT(dt.id) AS num,
	   dt.name AS 'ТИП ПУ',
       dt.calibration_interval AS 'межповерочный интервал, лет',
       dt.digit AS 'разрядность' 
  FROM personal_accounts pa 
  JOIN metering_devices md 
    ON pa.metering_device_id = md.id
  JOIN device_types dt 
    ON md.device_type_id = dt.id
 GROUP BY dt.id
 ORDER BY num DESC
 LIMIT 5;
 
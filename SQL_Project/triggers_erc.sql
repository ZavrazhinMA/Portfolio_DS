USE erc;
-- *********************************************************************************************************************************
-- Блокировка выбора некорректного тарифа и норматива потребления в ЛС в зависимости от параметров (тип дома и квартиры потребителя)
DROP TRIGGER IF EXISTS normative_tariff_control_update;
DELIMITER //

CREATE TRIGGER normative_tariff_control_update BEFORE UPDATE ON personal_accounts
   FOR EACH ROW
 BEGIN
    IF tariff_control(NEW.number_of_rooms, NEW.inhabitants_number) != NEW.standard_consumption_id
  THEN
SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = 'Некорректно выбран норматив';
   END IF;
END//

DELIMITER ;

DROP TRIGGER IF EXISTS normative_tariff_control_insert;
DELIMITER //

CREATE TRIGGER normative_tariff_control_insert BEFORE INSERT ON personal_accounts
   FOR EACH ROW
 BEGIN
	IF  tariff_control(NEW.number_of_rooms, NEW.inhabitants_number) != NEW.standard_consumption_id
  THEN
SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = 'Некорректно выбран норматив';
   END IF;
END//

DELIMITER ;

-- **********************************************************************************************************************************
-- триггеры контроля коэффициента трансформации ТТ при формировании системы учета (должны быть одинаковые коэффициенты трансформации)

DROP TRIGGER IF EXISTS measurement_systems_control_insert;
DELIMITER //
CREATE TRIGGER measurement_systems_control_insert BEFORE INSERT ON measurement_systems
   FOR EACH ROW
 BEGIN
SELECT ct1.primary_current INTO @a
  FROM current_transformers ct2 
  JOIN ct_types ct1
    ON ct2.ct_type_id = ct1.id
 WHERE ct2.id = NEW.a_current_transformer_id;

SELECT ct1.primary_current INTO @b
  FROM current_transformers ct2 
  JOIN ct_types ct1
    ON ct2.ct_type_id = ct1.id
 WHERE ct2.id = NEW.b_current_transformer_id;
 
SELECT ct1.primary_current INTO @c
  FROM current_transformers ct2 
  JOIN ct_types ct1
    ON ct2.ct_type_id = ct1.id
 WHERE ct2.id = NEW.c_current_transformer_id;
    
    IF NOT ((@a = @b) AND (@b = @c)) 
  THEN
SIGNAL SQLSTATE '45003' SET MESSAGE_TEXT = 'ТТ должны иметь одинаковый коэффициент трансформации';
   END IF;
  
END//
DELIMITER ;

DROP TRIGGER IF EXISTS measurement_systems_control_update;
DELIMITER //
CREATE TRIGGER measurement_systems_control_update BEFORE UPDATE ON measurement_systems
   FOR EACH ROW
 BEGIN
SELECT ct1.primary_current INTO @a
  FROM current_transformers ct2 
  JOIN ct_types ct1
    ON ct2.ct_type_id = ct1.id
 WHERE ct2.id = NEW.a_current_transformer_id;

SELECT ct1.primary_current INTO @b
  FROM current_transformers ct2 
  JOIN ct_types ct1
    ON ct2.ct_type_id = ct1.id
 WHERE ct2.id = NEW.b_current_transformer_id;
 
SELECT ct1.primary_current INTO @c
  FROM current_transformers ct2 
  JOIN ct_types ct1
    ON ct2.ct_type_id = ct1.id
 WHERE ct2.id = NEW.c_current_transformer_id;
    
    IF NOT ((@a = @b) AND (@b = @c)) 
  THEN
SIGNAL SQLSTATE '45003' SET MESSAGE_TEXT = 'ТТ должны иметь одинаковый коэффициент трансформации';
   END IF;
END//
DELIMITER ;

-- **********************************************************************************************************************************
-- триггеры изменения расчетного коэффициента в таблице metering_devices при добавлении/измении/удалении строки таблице measurement_systems

DROP TRIGGER IF EXISTS CT_ratio_control_insert;
DELIMITER //
CREATE TRIGGER CT_ratio_control_insert AFTER INSERT ON measurement_systems
   FOR EACH ROW
 BEGIN
	 
SELECT ct1.primary_current INTO @pc
  FROM current_transformers ct2 
  JOIN ct_types ct1
    ON ct2.ct_type_id = ct1.id
 WHERE ct2.id = NEW.c_current_transformer_id;

SELECT ct1.secondary_current INTO @sc
  FROM current_transformers ct2 
  JOIN ct_types ct1
    ON ct2.ct_type_id = ct1.id
 WHERE ct2.id = NEW.c_current_transformer_id;

UPDATE metering_devices 
	   SET СT_ratio = (@pc / @sc) 
	   WHERE metering_devices.id = NEW.metering_device_id; 
 END //
DELIMITER ;

DROP TRIGGER IF EXISTS CT_ratio_control_update;
DELIMITER //
CREATE TRIGGER CT_ratio_control_update AFTER UPDATE ON measurement_systems
   FOR EACH ROW
 BEGIN
	 
SELECT ct1.primary_current INTO @pc
  FROM current_transformers ct2 
  JOIN ct_types ct1
    ON ct2.ct_type_id = ct1.id
 WHERE ct2.id = NEW.c_current_transformer_id;

SELECT ct1.secondary_current INTO @sc
  FROM current_transformers ct2 
  JOIN ct_types ct1
    ON ct2.ct_type_id = ct1.id
 WHERE ct2.id = NEW.c_current_transformer_id;

UPDATE metering_devices 
	   SET СT_ratio = (@pc / @sc) 
	   WHERE metering_devices.id = NEW.metering_device_id; 
   END //
DELIMITER ;

DROP TRIGGER IF EXISTS CT_ratio_control_delete;
DELIMITER //
CREATE TRIGGER CT_ratio_control_delete AFTER DELETE ON measurement_systems
   FOR EACH ROW
 BEGIN
	 
UPDATE metering_devices 
	   SET СT_ratio = DEFAULT
	   WHERE metering_devices.id = OLD.metering_device_id; 
   END //
DELIMITER ;

-- **********************************************************************************************************************************
-- триггер контроля уникальности занчений (дом + № кв) и уникальности номера прибора учета в лицевых счетах

DROP TRIGGER IF EXISTS personal_accounts_control_insert;
DELIMITER //
CREATE TRIGGER personal_accounts_control_insert BEFORE INSERT ON personal_accounts
   FOR EACH ROW
 BEGIN
	   IF EXISTS(SELECT * FROM personal_accounts WHERE house_id = NEW.house_id AND flat_number = NEW.flat_number)
	      THEN
          SIGNAL SQLSTATE '45004' SET MESSAGE_TEXT = 'Лицевой счет на объект по указанному адресу уже открыт';
       END IF;
     
       IF EXISTS(SELECT * FROM personal_accounts WHERE metering_device_id = NEW.metering_device_id)
	      THEN
          SIGNAL SQLSTATE '45005' SET MESSAGE_TEXT = 'Лицевой счет с данным номером прибора учета уже существует';
      END IF;
 END //
DELIMITER ;

-- **********************************************************************************************************************************
-- триггер отвязки ПУ со статусом "снят" и "необходима поверка" от лицевого счета, чтобы ПУ не участвовал в расчетах

DROP TRIGGER IF EXISTS equipment_status_control_update;
DELIMITER //
CREATE TRIGGER equipment_status_control_update AFTER UPDATE ON metering_devices
   FOR EACH ROW
 BEGIN
	   IF (SELECT name FROM equipment_statuses WHERE id = NEW.equipment_status_id) != 'В работе'
	   THEN
	   UPDATE personal_accounts SET metering_device_id = NULL WHERE metering_device_id = NEW.id;
       END IF;
 END //
DELIMITER ;

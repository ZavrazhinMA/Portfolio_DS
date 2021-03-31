DROP DATABASE IF EXISTS ERC;
CREATE DATABASE ERC;
USE ERC;

DROP TABLE IF EXISTS consumers;
CREATE TABLE consumers
(
id SERIAL PRIMARY KEY COMMENT 'Идентификатор потребителя',
surname VARCHAR(50) NOT NULL COMMENT 'Имя потребителя',
name VARCHAR(50) NOT NULL COMMENT 'Имя потребителя',
patronymic VARCHAR(50) COMMENT 'Отчество потребителя',
sex ENUM('м','ж') COMMENT 'пол потребителя',
birthday_at DATE NOT NULL COMMENT 'Дата рождения потребитея',
pasport VARCHAR(10) NOT NULL UNIQUE COMMENT 'паспортные данные потребителя',
phone_number VARCHAR(20)  NOT NULL UNIQUE COMMENT 'телефонный номер потребителя',
email VARCHAR(30) COMMENT 'электронный адрес потребитея',
created_at DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT 'Дата создания',
updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Дата внесения изменений',
KEY consumers_surname_name_idx (surname, name)
) COMMENT 'Таблица потребителей';

DROP TABLE IF EXISTS metering_devices;
CREATE TABLE metering_devices
(
id SERIAL PRIMARY KEY COMMENT 'Идентификатор ПУ',
factory_number VARCHAR(20) UNIQUE NOT NULL COMMENT 'Заводской номер ПУ',  -- может содержать символы
device_type_id BIGINT UNSIGNED NOT NULL COMMENT 'Ссылка на тип ПУ',
equipment_status_id BIGINT UNSIGNED NOT NULL DEFAULT '1' COMMENT 'Статус оборудования',
calibration_date DATE NOT NULL COMMENT 'Дата последней поверки ПУ',
СT_ratio INT UNSIGNED NOT NULL DEFAULT '1' COMMENT 'Расчетный коэффициент / коэффициент трансформации',
created_at DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT 'Дата создания',
updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Дата внесения изменений'
) COMMENT 'Таблица приборов учета';

DROP TABLE IF EXISTS device_types;
CREATE TABLE device_types
(
id SERIAL PRIMARY KEY COMMENT 'Идентификатор типа ПУ',
name VARCHAR(100) UNIQUE NOT NULL COMMENT 'Тип ПУ',
phases_namber INT(1) UNSIGNED NOT NULL COMMENT 'Количество фаз ПУ',
accuracy_class VARCHAR(5) NOT NULL COMMENT 'Класс точности ПУ',
calibration_interval INT(2) UNSIGNED NOT NULL COMMENT 'Межповерочный интревал ПУ, лет',
digit INT(1) UNSIGNED NOT NULL COMMENT 'Разрядность измерений',
created_at DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT 'Дата создания',
updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Дата внесения изменений'
) COMMENT 'Таблица типов приборов учета';

DROP TABLE IF EXISTS current_transformers;
CREATE TABLE current_transformers
(
id SERIAL PRIMARY KEY COMMENT 'Идентификатор трансформатора тока',
factory_number VARCHAR(20) UNIQUE NOT NULL COMMENT 'Заводской номер ТТ',  -- может содержать символы
ct_type_id BIGINT UNSIGNED NOT NULL COMMENT 'Ссылка на тип ТТ',
calibration_date DATE NOT NULL COMMENT 'Дата последней поверки ТТ',
equipment_status_id BIGINT UNSIGNED NOT NULL DEFAULT '1' COMMENT 'Статус оборудования',
created_at DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT 'Дата создания',
updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Дата внесения изменений'
) COMMENT 'Таблица трансформаторов тока';

DROP TABLE IF EXISTS ct_types;
CREATE TABLE ct_types
(
id SERIAL PRIMARY KEY COMMENT 'Идентификатор типа ТТ',
name VARCHAR(100) UNIQUE NOT NULL COMMENT 'Тип ТТ',
accuracy_class VARCHAR(5) NOT NULL COMMENT 'Класс точности ТТ',
calibration_interval INT(2) UNSIGNED NOT NULL COMMENT 'Межповерочный интревал ТТ, лет',
primary_current INT(5) UNSIGNED NOT NULL COMMENT 'Номинальный ток первичной обмотки',
secondary_current INT(1) UNSIGNED NOT NULL COMMENT 'Номинальный ток вторичной обмотки обмотки',
created_at DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT 'Дата создания',
updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Дата внесения изменений'
) COMMENT 'Таблица типов трансформаторов тока';

DROP TABLE IF EXISTS measurement_systems;
CREATE TABLE measurement_systems
(
id SERIAL PRIMARY KEY COMMENT 'Идентификатор системы учета',
metering_device_id BIGINT UNSIGNED NOT NULL COMMENT 'Ссылка на ПУ',
a_current_transformer_id BIGINT UNSIGNED NOT NULL COMMENT 'Ссылка на трансформатор тока фазы A',
b_current_transformer_id BIGINT UNSIGNED NOT NULL COMMENT 'Ссылка на трансформатор тока фазы B',
c_current_transformer_id BIGINT UNSIGNED NOT NULL COMMENT 'Ссылка на трансформатор тока фазы C',
created_at DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT 'Дата создания',
updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Дата внесения изменений'
) COMMENT 'Таблица измерительных комплексов';

DROP TABLE IF EXISTS equipment_statuses;  -- тариф зависит от типа плит
CREATE TABLE equipment_statuses
(
id SERIAL PRIMARY KEY COMMENT 'Идентификатор статуса оборудования',
name VARCHAR(20) UNIQUE NOT NULL COMMENT 'Статус измерительного оборудования',
created_at DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT 'Дата создания',
updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Дата внесения изменений'
) COMMENT 'Таблица статусов оборудования';

DROP TABLE IF EXISTS houses;
CREATE TABLE houses
(
id SERIAL PRIMARY KEY COMMENT 'Идентификатор дома',
house_number INT  COMMENT 'Номер дома',
street_id BIGINT UNSIGNED NOT NULL COMMENT 'Ссылка на улицу',
building_date YEAR NOT NULL COMMENT 'Дата постройки дома',
metering_device_id BIGINT UNSIGNED COMMENT 'Ссылка на общедомовой прибор учета',
residential_space DECIMAL(7,2) UNSIGNED NOT NULL COMMENT 'Общая площадь жилых помещений', -- участвует в расчете платы за ОДН
plates_type_id BIGINT UNSIGNED NOT NULL COMMENT 'Ссылка на тип плит, которыми оборудован дом',
created_at DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT 'Дата создания',
updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Дата внесения изменений'
) COMMENT 'Таблица паспотрных данных МКД';

DROP TABLE IF EXISTS plate_types;  -- тариф зависит от типа плит
CREATE TABLE plate_types
(
id SERIAL PRIMARY KEY COMMENT 'Идентификатор типа становленых плит в доме',
name VARCHAR(50) UNIQUE NOT NULL COMMENT 'Типы становленых плит в доме',
created_at DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT 'Дата создания',
updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Дата внесения изменений'
) COMMENT 'Таблица типов плит, установленных в доме';

DROP TABLE IF EXISTS streets;  
CREATE TABLE streets
(
id SERIAL PRIMARY KEY COMMENT 'Идентификатор улицы',
name VARCHAR(100) UNIQUE NOT NULL COMMENT 'Название улицы',
created_at DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT 'Дата создания',
updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Дата внесения изменений'
) COMMENT 'Справочник улиц';

DROP TABLE IF EXISTS personal_accounts;
CREATE TABLE personal_accounts
(
id SERIAL COMMENT 'Идентификатор ЛС',
personal_number VARCHAR(10) UNIQUE COMMENT 'Номер лицевого счета потребителя',  -- может содержать символы
consumer_id BIGINT UNSIGNED NOT NULL COMMENT 'Ссылка потребителя',
metering_device_id BIGINT UNSIGNED COMMENT 'Ссылка на прибор учета',
house_id BIGINT UNSIGNED NOT NULL COMMENT 'Ссылка дом проживания потребителя',
standard_consumption_id BIGINT UNSIGNED NOT NULL COMMENT 'Ссылка на норматив потребления',
tariff_id BIGINT UNSIGNED NOT NULL COMMENT 'Ссылка на тариф',
flat_number INT UNSIGNED NOT NULL COMMENT 'Номер квартиры потребителя',
flat_space DECIMAL(6,2) UNSIGNED NOT NULL COMMENT 'Площадь квартиры потребителя',  -- участвует в расчете платы за ОДН 
number_of_rooms INT UNSIGNED NOT NULL COMMENT 'Количество комнат в квартире потребителя',
inhabitants_number INT UNSIGNED NOT NULL COMMENT 'Количество жильцов в квартире',
status ENUM('открыт', 'закрыт') NOT NULL DEFAULT 'открыт' COMMENT 'Статус ЛС',
created_at DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT 'Дата создания',
updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Дата внесения изменений',
PRIMARY KEY(id)
) COMMENT 'Таблица лицевых счетов';

DROP TABLE IF EXISTS tariffs; 
CREATE TABLE tariffs
(
id SERIAL PRIMARY KEY COMMENT 'Идентификатор тарифа',
description VARCHAR(100) NOT NULL COMMENT 'Описание тарифа',
tariff_rate DECIMAL(4,2) UNSIGNED NOT NULL COMMENT 'Тариф на электроэнергию, р/кВтч',
created_at DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT 'Дата создания',
updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Дата внесения изменений'
) COMMENT 'Таблица тарифов за электроэнергию';

DROP TABLE IF EXISTS standards_consumption; 
CREATE TABLE standards_consumption
(
id SERIAL PRIMARY KEY COMMENT 'Идентификатор норматива',
number_of_rooms INT UNSIGNED NOT NULL COMMENT 'Количество комнат-для пределения норматива',
inhabitants_number INT UNSIGNED NOT NULL COMMENT 'Количество жильцов -для пределения норматива',
description VARCHAR(100) COMMENT 'Описание норматива',
normative_rate DECIMAL(5,2) UNSIGNED NOT NULL COMMENT 'Норматив потребления электроэнергии, кВтч/чел',
created_at DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT 'Дата создания',
updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Дата внесения изменений'
) COMMENT 'Таблица нормативов потребления электроэнергии';

DROP TABLE IF EXISTS meters_reading;
CREATE TABLE meters_reading
(
id SERIAL COMMENT 'Идентификатор показаний',
metering_device_id BIGINT UNSIGNED COMMENT 'Ссылка на прибор учета',
meters_reading DECIMAL(9,2) NOT NULL COMMENT 'Показания прибора учета', -- могут быть отрицательными для перерасчетов
accounting_period DATE NOT NULL COMMENT 'Расчетный период',
created_at DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT 'Дата создания',
updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Дата внесения изменений',
PRIMARY KEY(id)
) COMMENT 'Таблица снятия показаний';

DROP TABLE IF EXISTS energy_accounting;
CREATE TABLE energy_accounting
(
id SERIAL PRIMARY KEY COMMENT 'Идентификатор расчета за электроэнергию по личевому счету',
personal_account_id BIGINT UNSIGNED NOT NULL COMMENT 'Ссылка на лицевой счет',
accounting_type_id BIGINT UNSIGNED NOT NULL COMMENT 'Ссылка на тип расчетов за э/э',
accounting_period DATE NOT NULL COMMENT 'Расчетный период',
individual_energy_demand DECIMAL(8,2) NOT NULL COMMENT 'Объем потребления по показаниям ПУ', -- может быть отрицательным для перерасчетов
communal_energy_demand DECIMAL(8,2) NOT NULL DEFAULT 0 COMMENT 'Объем потребления э/э на общедомовые нужды', -- может быть отрицательным для перерасчетов
individual_use_charge DECIMAL(8,2) NOT NULL COMMENT 'Начисления плтаты за э/э по покозаниемя ИПУ или по нормативу',  -- может быть отрицательным для перерасчетов
communal_use_charge DECIMAL(8,2) NOT NULL DEFAULT 0 COMMENT 'Начисления плтаты за э/э на общедомовые нужды',  -- может быть отрицательным для перерасчетов
total_charge DECIMAL(9,2)  AS (individual_use_charge + communal_use_charge) COMMENT 'Начисления плтаты за э/э итоговое',
created_at DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT 'Дата создания',
updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Дата внесения изменений',
KEY energy_accounting_energy_demand_idx (individual_energy_demand),
KEY energy_accounting_total_charge_idx (total_charge)
) COMMENT 'Таблица расчетов платы за э/э ';

DROP TABLE IF EXISTS accounting_types; 
CREATE TABLE accounting_types
(
id SERIAL PRIMARY KEY COMMENT 'Идентификатор типа расчетов за э/э',
name VARCHAR(100) COMMENT 'Тип расчетов за э/э',
created_at DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT 'Дата создания',
updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Дата внесения изменений'
) COMMENT 'Таблица типов расчета за э/э';

-- *****************************************************************************************************************************
-- Добавление внешних связей

ALTER TABLE metering_devices 
  ADD CONSTRAINT metering_devices_device_type_id_fk 
      FOREIGN KEY (device_type_id) REFERENCES device_types(id),
  ADD CONSTRAINT metering_devices_equipment_status_id_fk 
      FOREIGN KEY (equipment_status_id) REFERENCES equipment_statuses(id);

ALTER TABLE current_transformers 
  ADD CONSTRAINT current_transformers_ct_type_id_fk 
      FOREIGN KEY (ct_type_id) REFERENCES ct_types(id),
  ADD CONSTRAINT current_transformers_equipment_status_id_fk 
      FOREIGN KEY (equipment_status_id) REFERENCES equipment_statuses(id);
  
ALTER TABLE measurement_systems
  ADD CONSTRAINT measurement_systems_metering_device_id_fk 
      FOREIGN KEY (metering_device_id) REFERENCES metering_devices(id)
   ON DELETE CASCADE,
  ADD CONSTRAINT measurement_systems_a_current_transformer_id_fk 
      FOREIGN KEY (a_current_transformer_id) REFERENCES current_transformers(id)
   ON DELETE CASCADE,
  ADD CONSTRAINT measurement_systems_b_current_transformer_id_fk 
      FOREIGN KEY (b_current_transformer_id) REFERENCES current_transformers(id)
   ON DELETE CASCADE,
  ADD CONSTRAINT measurement_systems_c_current_transformer_id_fk 
      FOREIGN KEY (c_current_transformer_id) REFERENCES current_transformers(id)
   ON DELETE CASCADE;
  
ALTER TABLE houses 
  ADD CONSTRAINT houses_metering_device_id_fk 
      FOREIGN KEY (metering_device_id) REFERENCES metering_devices(id)
   ON DELETE SET NULL,  
  ADD CONSTRAINT houses_street_id_fk 
      FOREIGN KEY (street_id) REFERENCES streets(id),   
  ADD CONSTRAINT houses_plates_type_id_fk 
      FOREIGN KEY (plates_type_id) REFERENCES plate_types(id);
 
ALTER TABLE personal_accounts
  ADD CONSTRAINT personal_accounts_device_id_fk 
      FOREIGN KEY (metering_device_id) REFERENCES metering_devices(id)
   ON DELETE SET NULL,
  ADD CONSTRAINT personal_accounts_consumer_id_fk 
      FOREIGN KEY (consumer_id) REFERENCES consumers(id),
  ADD CONSTRAINT personal_accounts_tariff_id_fk 
      FOREIGN KEY (tariff_id) REFERENCES tariffs(id),
  ADD CONSTRAINT personal_accounts_standard_consumption_id_fk 
      FOREIGN KEY (standard_consumption_id) REFERENCES standards_consumption(id),
  ADD CONSTRAINT personal_accounts_house_id_fk 
      FOREIGN KEY (house_id) REFERENCES houses(id);

ALTER TABLE meters_reading
  ADD CONSTRAINT meters_reading_device_id_fk 
      FOREIGN KEY (metering_device_id) REFERENCES metering_devices(id);

ALTER TABLE energy_accounting
  ADD CONSTRAINT energy_accounting_personal_account_id_fk 
      FOREIGN KEY (personal_account_id) REFERENCES personal_accounts(id),
  ADD CONSTRAINT energy_accounting_accounting_type_id_fk 
      FOREIGN KEY (accounting_type_id) REFERENCES accounting_types(id);





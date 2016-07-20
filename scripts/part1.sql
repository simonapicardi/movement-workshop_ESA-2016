--- LESSON 2
--- TOPIC 2.1

CREATE DATABASE gps_tracking_db_esa
ENCODING = 'UTF8'
TEMPLATE = template0
LC_COLLATE = 'C'
LC_CTYPE = 'C';

COMMENT ON DATABASE gps_tracking_db   
IS 'Next Generation Data Management in Movement Ecology Summer school: my database.'; 

CREATE SCHEMA main;
COMMENT ON SCHEMA main IS 'Schema that stores all the GPS tracking core data.'; 

CREATE TABLE main.gps_data 
( 
gps_data_id serial NOT NULL, 
gps_sensors_code character varying, 
line_no integer, 
utc_date date, 
utc_time time without time zone, 
lmt_date date, 
lmt_time time without time zone, 
ecef_x integer, 
ecef_y integer, 
ecef_z integer, 
latitude double precision, 
longitude double precision, 
height double precision, 
dop double precision, 
nav character varying(2), 
validated character varying(3), 
sats_used integer, 
ch01_sat_id integer, 
ch01_sat_cnr integer, 
ch02_sat_id integer, 
ch02_sat_cnr integer, 
ch03_sat_id integer, 
ch03_sat_cnr integer, 
ch04_sat_id integer, 
ch04_sat_cnr integer, 
ch05_sat_id integer, 
ch05_sat_cnr integer, 
ch06_sat_id integer, 
ch06_sat_cnr integer, 
ch07_sat_id integer, 
ch07_sat_cnr integer, 
ch08_sat_id integer, 
ch08_sat_cnr integer, 
ch09_sat_id integer, 
ch09_sat_cnr integer, 
ch10_sat_id integer, 
ch10_sat_cnr integer, 
ch11_sat_id integer, 
ch11_sat_cnr integer, 
ch12_sat_id integer, 
ch12_sat_cnr integer, 
main_vol double precision, 
bu_vol double precision, 
temp double precision, 
easting integer, 
northing integer, 
remarks character varying 
); 

COMMENT ON TABLE main.gps_data 
IS 'Table that stores raw data as they come from the sensors (plus the ID of the sensor).'; 


ALTER TABLE main.gps_data 
ADD CONSTRAINT gps_data_pkey PRIMARY KEY(gps_data_id); 

ALTER TABLE main.gps_data ADD COLUMN insert_timestamp timestamp with time zone; 
ALTER TABLE main.gps_data ALTER COLUMN insert_timestamp SET DEFAULT now(); 

COPY main.gps_data( 
gps_sensors_code, line_no, utc_date, utc_time, lmt_date, lmt_time, ecef_x, ecef_y, ecef_z, latitude, longitude, height, dop, nav, validated, sats_used, ch01_sat_id, ch01_sat_cnr, ch02_sat_id, ch02_sat_cnr, ch03_sat_id, ch03_sat_cnr, ch04_sat_id, ch04_sat_cnr, ch05_sat_id, ch05_sat_cnr, ch06_sat_id, ch06_sat_cnr, ch07_sat_id, ch07_sat_cnr, ch08_sat_id, ch08_sat_cnr, ch09_sat_id, ch09_sat_cnr, ch10_sat_id, ch10_sat_cnr, ch11_sat_id, ch11_sat_cnr, ch12_sat_id, ch12_sat_cnr, main_vol, bu_vol, temp, easting, northing, remarks) 
FROM 
'C:\tracking_db\data\sensors_data\GSM01438.csv' WITH CSV HEADER DELIMITER ';'; 

SHOW datestyle; 

SET SESSION datestyle = "ISO, DMY"; 

COPY main.gps_data( 
gps_sensors_code, line_no, utc_date, utc_time, lmt_date, lmt_time, ecef_x, ecef_y, ecef_z, latitude, longitude, height, dop, nav, validated, sats_used, ch01_sat_id, ch01_sat_cnr, ch02_sat_id, ch02_sat_cnr, ch03_sat_id, ch03_sat_cnr, ch04_sat_id, ch04_sat_cnr, ch05_sat_id, ch05_sat_cnr, ch06_sat_id, ch06_sat_cnr, ch07_sat_id, ch07_sat_cnr, ch08_sat_id, ch08_sat_cnr, ch09_sat_id, ch09_sat_cnr, ch10_sat_id, ch10_sat_cnr, ch11_sat_id, ch11_sat_cnr, ch12_sat_id, ch12_sat_cnr, main_vol, bu_vol, temp, easting, northing, remarks) 
FROM 
'C:\tracking_db\data\sensors_data\GSM01438.csv' WITH CSV HEADER DELIMITER ';'; 

COPY main.gps_data( 
gps_sensors_code, line_no, utc_date, utc_time, lmt_date, lmt_time, ecef_x, ecef_y, ecef_z, latitude, longitude, height, dop, nav, validated, sats_used, ch01_sat_id, ch01_sat_cnr, ch02_sat_id, ch02_sat_cnr, ch03_sat_id, ch03_sat_cnr, ch04_sat_id, ch04_sat_cnr, ch05_sat_id, ch05_sat_cnr, ch06_sat_id, ch06_sat_cnr, ch07_sat_id, ch07_sat_cnr, ch08_sat_id, ch08_sat_cnr, ch09_sat_id, ch09_sat_cnr, ch10_sat_id, ch10_sat_cnr, ch11_sat_id, ch11_sat_cnr, ch12_sat_id, ch12_sat_cnr, main_vol, bu_vol, temp, easting, northing, remarks) 
FROM 
'C:\tracking_db\data\sensors_data\GSM01508.csv' WITH CSV HEADER DELIMITER ';'; 

COPY main.gps_data( 
gps_sensors_code, line_no, utc_date, utc_time, lmt_date, lmt_time, ecef_x, ecef_y, ecef_z, latitude, longitude, height, dop, nav, validated, sats_used, ch01_sat_id, ch01_sat_cnr, ch02_sat_id, ch02_sat_cnr, ch03_sat_id, ch03_sat_cnr, ch04_sat_id, ch04_sat_cnr, ch05_sat_id, ch05_sat_cnr, ch06_sat_id, ch06_sat_cnr, ch07_sat_id, ch07_sat_cnr, ch08_sat_id, ch08_sat_cnr, ch09_sat_id, ch09_sat_cnr, ch10_sat_id, ch10_sat_cnr, ch11_sat_id, ch11_sat_cnr, ch12_sat_id, ch12_sat_cnr, main_vol, bu_vol, temp, easting, northing, remarks) 
FROM 
'C:\tracking_db\data\sensors_data\GSM01511.csv' WITH CSV HEADER DELIMITER ';'; 

COPY main.gps_data( 
gps_sensors_code, line_no, utc_date, utc_time, lmt_date, lmt_time, ecef_x, ecef_y, ecef_z, latitude, longitude, height, dop, nav, validated, sats_used, ch01_sat_id, ch01_sat_cnr, ch02_sat_id, ch02_sat_cnr, ch03_sat_id, ch03_sat_cnr, ch04_sat_id, ch04_sat_cnr, ch05_sat_id, ch05_sat_cnr, ch06_sat_id, ch06_sat_cnr, ch07_sat_id, ch07_sat_cnr, ch08_sat_id, ch08_sat_cnr, ch09_sat_id, ch09_sat_cnr, ch10_sat_id, ch10_sat_cnr, ch11_sat_id, ch11_sat_cnr, ch12_sat_id, ch12_sat_cnr, main_vol, bu_vol, temp, easting, northing, remarks) 
FROM 
'C:\tracking_db\data\sensors_data\GSM01512.csv' WITH CSV HEADER DELIMITER ';'; 


--- TOPIC 1.2

ALTER TABLE main.gps_data 
  ADD COLUMN acquisition_time timestamp with time zone;
UPDATE main.gps_data 
  SET acquisition_time = (utc_date + utc_time) AT TIME ZONE 'UTC';

CREATE INDEX acquisition_time_index
  ON main.gps_data
  USING btree (acquisition_time );
CREATE INDEX gps_sensors_code_index
  ON main.gps_data
  USING btree (gps_sensors_code);

SELECT 
  gps_data_id AS id, gps_sensors_code AS sensor_id, 
  latitude, longitude, acquisition_time
FROM 
  main.gps_data
WHERE 
  gps_sensors_code = 'GSM01512' and EXTRACT(MONTH FROM acquisition_time) = 5
ORDER BY 
  acquisition_time
LIMIT 5;

-- drop rest of 1.2
-- drop 1.3

--LESSON 3

-- TOPIC 3.2

CREATE TABLE main.gps_sensors(
gps_sensors_id integer,
gps_sensors_code character varying NOT NULL,
purchase_date date,
frequency double precision,
vendor character varying,
model character varying,
sim character varying,
CONSTRAINT gps_sensors_pkey
PRIMARY KEY (gps_sensors_id),
CONSTRAINT gps_sensor_code_unique
UNIQUE (gps_sensors_code)
);
COMMENT ON TABLE main.gps_sensors
IS 'GPS sensors catalog.';

ALTER TABLE main.gps_sensors 
  ADD COLUMN insert_timestamp timestamp with time zone DEFAULT now();

COPY main.gps_sensors(
  gps_sensors_id, gps_sensors_code, purchase_date, frequency, vendor, model, sim)
FROM 
  'C:\tracking_db\data\sensors\gps_sensors.csv' 
  WITH (FORMAT csv, DELIMITER ';');

ALTER TABLE main.gps_data
  ADD CONSTRAINT gps_data_gps_sensors_fkey 
  FOREIGN KEY (gps_sensors_code)
  REFERENCES main.gps_sensors (gps_sensors_code) 
  MATCH SIMPLE ON UPDATE NO ACTION ON DELETE NO ACTION;

ALTER TABLE main.gps_sensors
  ADD CONSTRAINT purchase_date_check 
  CHECK (purchase_date > '2000-01-01'::date);

-- TOPIC 3.3

CREATE TABLE main.animals(
  animals_id integer,
  animals_code character varying(20) NOT NULL,
  name character varying(40),
  sex character(1),
  age_class_code integer,
  species_code integer,
  note character varying,
  CONSTRAINT animals_pkey PRIMARY KEY (animals_id)
);
COMMENT ON TABLE main.animals
IS 'Animals catalog with the main information on individuals.';

CREATE SCHEMA lu_tables;

--GRANT USAGE ON SCHEMA lu_tables TO basic_user;

COMMENT ON SCHEMA lu_tables
IS 'Schema that stores look up tables.';

--ALTER DEFAULT PRIVILEGES 
--  IN SCHEMA lu_tables 
--  GRANT SELECT ON TABLES 
--  TO basic_user;

CREATE TABLE lu_tables.lu_species(
  species_code integer,
  species_description character varying,
  CONSTRAINT lu_species_pkey 
  PRIMARY KEY (species_code)
);
COMMENT ON TABLE lu_tables.lu_species
IS 'Look up table for species.';


INSERT INTO lu_tables.lu_species 
  VALUES (1, 'roe deer');

INSERT INTO lu_tables.lu_species 
  VALUES (2, 'rein deer');

INSERT INTO lu_tables.lu_species 
  VALUES (3, 'moose');

CREATE TABLE lu_tables.lu_age_class(
  age_class_code integer, 
  age_class_description character varying,
  CONSTRAINT lage_class_pkey 
  PRIMARY KEY (age_class_code)
);
COMMENT ON TABLE lu_tables.lu_age_class
IS 'Look up table for age classes.';

INSERT INTO lu_tables.lu_age_class 
  VALUES (1, 'fawn');

INSERT INTO lu_tables.lu_age_class 
  VALUES (2, 'yearling');

INSERT INTO lu_tables.lu_age_class 
  VALUES (3, 'adult');

ALTER TABLE main.animals
  ADD CONSTRAINT animals_lu_species 
  FOREIGN KEY (species_code)
  REFERENCES lu_tables.lu_species (species_code) 
  MATCH SIMPLE ON UPDATE NO ACTION ON DELETE NO ACTION;
ALTER TABLE main.animals
  ADD CONSTRAINT animals_lu_age_class 
  FOREIGN KEY (age_class_code)
  REFERENCES lu_tables.lu_age_class (age_class_code) 
  MATCH SIMPLE ON UPDATE NO ACTION ON DELETE NO ACTION;

ALTER TABLE main.animals
  ADD CONSTRAINT sex_check 
  CHECK (sex = 'm' OR sex = 'f');

ALTER TABLE main.animals 
  ADD COLUMN insert_timestamp timestamp with time zone DEFAULT now();

COPY main.animals(
  animals_id,animals_code, name, sex, age_class_code, species_code)
FROM 
  'C:\tracking_db\data\animals\animals.csv' 
  WITH (FORMAT csv, DELIMITER ';');

SELECT
  animals.animals_id AS id, 
  animals.animals_code AS code, 
  animals.name, 
  lu_age_class.age_class_description AS age_class
FROM 
  lu_tables.lu_age_class, 
  main.animals
WHERE 
  lu_age_class.age_class_code = animals.age_class_code


-- LESSON 4

-- TOPIC 4.1

CREATE TABLE main.gps_sensors_animals(
  gps_sensors_animals_id serial NOT NULL, 
  animals_id integer NOT NULL, 
  gps_sensors_id integer NOT NULL,
  start_time timestamp with time zone NOT NULL, 
  end_time timestamp with time zone,
  notes character varying, 
  insert_timestamp timestamp with time zone DEFAULT now(),
  CONSTRAINT gps_sensors_animals_pkey 
    PRIMARY KEY (gps_sensors_animals_id ),
  CONSTRAINT gps_sensors_animals_animals_id_fkey 
    FOREIGN KEY (animals_id)
    REFERENCES main.animals (animals_id) 
    MATCH SIMPLE ON UPDATE NO ACTION ON DELETE CASCADE,
  CONSTRAINT gps_sensors_animals_gps_sensors_id_fkey 
    FOREIGN KEY (gps_sensors_id)
    REFERENCES main.gps_sensors (gps_sensors_id) 
    MATCH SIMPLE ON UPDATE NO ACTION ON DELETE CASCADE
);

COMMENT ON TABLE main.gps_sensors_animals
IS 'Table that stores information of deployments of sensors on animals.';


COPY main.gps_sensors_animals(
  animals_id, gps_sensors_id, start_time, end_time, notes)
FROM 
  'C:\tracking_db\data\sensors_animals\gps_sensors_animals.csv' 
  WITH (FORMAT csv, DELIMITER ';');


SELECT 
  deployment.gps_sensors_id AS sensor, 
  deployment.animals_id AS animal,
  data.acquisition_time, 
  data.longitude::numeric(7,5) AS long, 
  data.latitude::numeric(7,5) AS lat
FROM 
  main.gps_sensors_animals AS deployment,
  main.gps_data AS data,
  main.gps_sensors AS gps
WHERE 
  data.gps_sensors_code = gps.gps_sensors_code AND
  gps.gps_sensors_id = deployment.gps_sensors_id AND
  (
    (data.acquisition_time >= deployment.start_time AND 
     data.acquisition_time <= deployment.end_time)
    OR 
    (data.acquisition_time >= deployment.start_time AND 
     deployment.end_time IS NULL)
  )
ORDER BY 
  animals_id, acquisition_time
LIMIT 5;

-- TOPIC 4.2

CREATE TABLE main.gps_data_animals(
  gps_data_animals_id serial NOT NULL, 
  gps_sensors_id integer, 
  animals_id integer,
  acquisition_time timestamp with time zone, 
  longitude double precision,
  latitude double precision,
  insert_timestamp timestamp with time zone DEFAULT now(), 
  CONSTRAINT gps_data_animals_pkey 
    PRIMARY KEY (gps_data_animals_id),
  CONSTRAINT gps_data_animals_animals_fkey 
    FOREIGN KEY (animals_id)
    REFERENCES main.animals (animals_id) 
    MATCH SIMPLE ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT gps_data_animals_gps_sensors 
    FOREIGN KEY (gps_sensors_id)
    REFERENCES main.gps_sensors (gps_sensors_id) 
    MATCH SIMPLE ON UPDATE NO ACTION ON DELETE NO ACTION
);
COMMENT ON TABLE main.gps_data_animals 
IS 'GPS sensors data associated to animals wearing the sensor.';
CREATE INDEX gps_data_animals_acquisition_time_index
  ON main.gps_data_animals
  USING BTREE (acquisition_time);
CREATE INDEX gps_data_animals_animals_id_index
  ON main.gps_data_animals
  USING BTREE (animals_id);

INSERT INTO main.gps_data_animals (
  animals_id, gps_sensors_id, acquisition_time, longitude, latitude) 
SELECT 
  gps_sensors_animals.animals_id,
  gps_sensors_animals.gps_sensors_id,
  gps_data.acquisition_time, gps_data.longitude,
  gps_data.latitude
FROM 
  main.gps_sensors_animals, main.gps_data, main.gps_sensors
WHERE 
  gps_data.gps_sensors_code = gps_sensors.gps_sensors_code AND
  gps_sensors.gps_sensors_id = gps_sensors_animals.gps_sensors_id AND
  (
    (gps_data.acquisition_time>=gps_sensors_animals.start_time AND 
     gps_data.acquisition_time<=gps_sensors_animals.end_time)
    OR 
    (gps_data.acquisition_time>=gps_sensors_animals.start_time AND 
     gps_sensors_animals.end_time IS NULL)
  );

-- TOPIC 4.3

CREATE SCHEMA tools
  AUTHORIZATION postgres;
 
--GRANT USAGE ON SCHEMA tools TO basic_user;

COMMENT ON SCHEMA tools 
IS 'Schema that hosts all the functions and ancillary tools used for the database.';

--ALTER DEFAULT PRIVILEGES 
--  IN SCHEMA tools 
--  GRANT SELECT ON TABLES 
-- TO basic_user;

CREATE FUNCTION tools.test_add(integer, integer) 
  RETURNS integer AS 
'SELECT $1 + $2;'
LANGUAGE SQL
IMMUTABLE
RETURNS NULL ON NULL INPUT;

SELECT tools.test_add(2,7);

CREATE OR REPLACE FUNCTION tools.acquisition_time_update()
RETURNS trigger AS
$BODY$BEGIN
  NEW.acquisition_time = ((NEW.utc_date + NEW.utc_time) at time zone 'UTC');
  RETURN NEW;
END;$BODY$
LANGUAGE plpgsql VOLATILE
COST 100;
COMMENT ON FUNCTION tools.acquisition_time_update() 
IS 'When a record is inserted, the acquisition_time is composed from utc_date and utc_time.';

CREATE TRIGGER update_acquisition_time
  BEFORE INSERT
  ON main.gps_data
  FOR EACH ROW
  EXECUTE PROCEDURE tools.acquisition_time_update();

-- Supplementary code: Automation of the GPS data association with animals

CREATE OR REPLACE FUNCTION tools.gps_data2gps_data_animals()
RETURNS trigger AS
$BODY$ begin
INSERT INTO main.gps_data_animals (
  animals_id, gps_sensors_id, acquisition_time, longitude, latitude)
SELECT 
  gps_sensors_animals.animals_id, gps_sensors_animals.gps_sensors_id, NEW.acquisition_time, NEW.longitude, NEW.latitude
FROM 
  main.gps_sensors_animals, main.gps_sensors
WHERE 
  NEW.gps_sensors_code = gps_sensors.gps_sensors_code AND 
  gps_sensors.gps_sensors_id = gps_sensors_animals.gps_sensors_id AND
  (
    (NEW.acquisition_time >= gps_sensors_animals.start_time AND 
     NEW.acquisition_time <= gps_sensors_animals.end_time)
    OR 
    (NEW.acquisition_time >= gps_sensors_animals.start_time AND 
     gps_sensors_animals.end_time IS NULL)
  );
RETURN NULL;
END
$BODY$
LANGUAGE plpgsql VOLATILE
COST 100;

COMMENT ON FUNCTION tools.gps_data2gps_data_animals() 
IS 'Automatic upload data from gps_data to gps_data_animals.';

CREATE TRIGGER trigger_gps_data_upload
  AFTER INSERT
  ON main.gps_data
  FOR EACH ROW
  EXECUTE PROCEDURE tools.gps_data2gps_data_animals();

COMMENT ON TRIGGER trigger_gps_data_upload ON main.gps_data
IS 'Upload data from gps_data to gps_data_animals whenever a new record is inserted.';


COPY main.gps_data(
  gps_sensors_code, line_no, utc_date, utc_time, lmt_date, lmt_time, ecef_x, ecef_y, ecef_z, latitude, longitude, height, dop, nav, validated, sats_used, ch01_sat_id, ch01_sat_cnr, ch02_sat_id, ch02_sat_cnr, ch03_sat_id, ch03_sat_cnr, ch04_sat_id, ch04_sat_cnr, ch05_sat_id, ch05_sat_cnr, ch06_sat_id, ch06_sat_cnr, ch07_sat_id, ch07_sat_cnr, ch08_sat_id, ch08_sat_cnr, ch09_sat_id, ch09_sat_cnr, ch10_sat_id, ch10_sat_cnr, ch11_sat_id, ch11_sat_cnr, ch12_sat_id, ch12_sat_cnr, main_vol, bu_vol, temp, easting, northing, remarks)
FROM 
  'C:\tracking_db\data\sensors_data\GSM02927.csv' 
  WITH (FORMAT csv, HEADER, DELIMITER ';');

-- VALIDATE gps_data_animals table (check that it matches)
SELECT animals_id, count(animals_id), min(acquisition_time), max(acquisition_time) 
FROM main.gps_data_animals
GROUP BY animals_id
ORDER BY animals_id;

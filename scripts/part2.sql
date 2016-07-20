-- Lesson 6
-- TOPIC 6.1

CREATE EXTENSION postgis;

ALTER TABLE main.gps_data_animals 
  ADD COLUMN geom geometry(Point,4326);

CREATE INDEX gps_data_animals_geom_gist
  ON main.gps_data_animals
  USING gist (geom);

UPDATE 
  main.gps_data_animals
SET 
  geom = ST_SetSRID(ST_MakePoint(longitude, latitude),4326)
WHERE 
  latitude IS NOT NULL AND longitude IS NOT NULL;

--TOPIC 6.2

CREATE OR REPLACE FUNCTION tools.new_gps_data_animals()
RETURNS trigger AS
$BODY$
DECLARE 
thegeom geometry;
BEGIN

IF NEW.longitude IS NOT NULL AND NEW.latitude IS NOT NULL THEN
  thegeom = ST_SetSRID(ST_MakePoint(NEW.longitude, NEW.latitude),4326);
  NEW.geom = thegeom;
END IF;

RETURN NEW;
END;$BODY$
LANGUAGE plpgsql VOLATILE
COST 100;
COMMENT ON FUNCTION tools.new_gps_data_animals() 
IS 'When called by a trigger (insert_gps_locations) this function populates the field geom using the values from longitude and latitude fields.';

CREATE TRIGGER insert_gps_location
  BEFORE INSERT
  ON main.gps_data_animals
  FOR EACH ROW
  EXECUTE PROCEDURE tools.new_gps_data_animals();


SELECT 
  animals_id, 
  ST_AsEWKT(
    ST_Centroid(
     ST_Collect(geom))) AS centroid 
FROM 
  main.gps_data_animals 
WHERE 
  geom IS NOT NULL 
GROUP BY 
  animals_id 
ORDER BY 
  animals_id;

-- TOPIC 6.3

CREATE SCHEMA analysis
  AUTHORIZATION postgres;

COMMENT ON SCHEMA analysis 
IS 'Schema that stores key layers for analysis.';

CREATE VIEW analysis.view_gps_locations AS 
  SELECT 
    gps_data_animals.gps_data_animals_id, 
    gps_data_animals.animals_id,
    animals.name,
    gps_data_animals.acquisition_time at time zone 'UTC' AS time_utc, 
    animals.sex, 
    lu_age_class.age_class_description, 
    lu_species.species_description,
    gps_data_animals.geom
  FROM 
    main.gps_data_animals, 
    main.animals, 
    lu_tables.lu_age_class, 
    lu_tables.lu_species
  WHERE 
    gps_data_animals.animals_id = animals.animals_id AND
    animals.age_class_code = lu_age_class.age_class_code AND
    animals.species_code = lu_species.species_code AND 
    geom IS NOT NULL;
COMMENT ON VIEW analysis.view_gps_locations
IS 'GPS locations.';

SELECT 
  gps_data_animals_id AS id, 
  name AS animal,
  time_utc, 
  sex, 
  age_class_description AS age, 
  species_description AS species
FROM 
  analysis.view_gps_locations
LIMIT 5;

CREATE VIEW analysis.view_trajectories AS 
  SELECT 
    animals_id, 
    ST_MakeLine(geom)::geometry(LineString,4326) AS geom 
  FROM 
    (SELECT animals_id, geom, acquisition_time 
    FROM main.gps_data_animals 
    WHERE geom IS NOT NULL 
    ORDER BY 
    animals_id, acquisition_time) AS sel_subquery 
  GROUP BY 
    animals_id;
COMMENT ON VIEW analysis.view_trajectories
IS 'GPS locations – Trajectories.';

CREATE VIEW analysis.view_convex_hulls AS
  SELECT 
    animals_id,
    (ST_ConvexHull(ST_Collect(geom)))::geometry(Polygon,4326) AS geom
  FROM 
    main.gps_data_animals 
  WHERE 
    geom IS NOT NULL 
  GROUP BY 
    animals_id 
  ORDER BY 
    animals_id;
COMMENT ON VIEW analysis.view_convex_hulls
IS 'GPS locations - Minimum convex polygons.';

-- LESSON 7

-- TOPIC 7.1

-- command line or QGIS?
-- raster needs to be command line

CREATE SCHEMA env_data
  AUTHORIZATION postgres;
COMMENT ON SCHEMA env_data 
IS 'Schema that stores environmental ancillary information.';

--COMMAND LINE - SHAPEFILES
"C:\Program Files\PostgreSQL\9.5\bin\shp2pgsql.exe" -s 4326 -I C:\tracking_db\data\env_data\vector\meteo_stations.shp env_data.meteo_stations | "C:\Program Files\PostgreSQL\9.5\bin\psql.exe" -p 5432 -d gps_tracking_db -U postgres -h localhost

"C:\Program Files\PostgreSQL\9.5\bin\shp2pgsql.exe" -s 4326 -I C:\tracking_db\data\env_data\vector\study_area.shp env_data.study_area | "C:\Program Files\PostgreSQL\9.5\bin\psql.exe" -p 5432 -d gps_tracking_db -U postgres -h localhost

"C:\Program Files\PostgreSQL\9.5\bin\shp2pgsql.exe" -s 4326 -I C:\tracking_db\data\env_data\vector\roads.shp env_data.roads | "C:\Program Files\PostgreSQL\9.5\bin\psql.exe" -p 5432 -d gps_tracking_db -U postgres -h localhost

"C:\Program Files\PostgreSQL\9.5\\bin\shp2pgsql.exe" -s 4326 -I C:\tracking_db\data\env_data\vector\adm_boundaries.shp env_data.adm_boundaries | "C:\Program Files\PostgreSQL\9.5\bin\psql.exe" -p 5432 -d gps_tracking_db -U postgres -h localhost

SELECT * FROM geometry_columns;

-- RASTERS
"C:\Program Files\PostgreSQL\9.5\bin\raster2pgsql.exe" -I -M -C -s 4326 -t 20x20 C:\tracking_db\data\env_data\raster\srtm_dem.tif env_data.srtm_dem | "C:\Program Files\PostgreSQL\9.5\bin\psql.exe" -p 5432 -d gps_tracking_db -U postgres -h localhost

"C:\Program Files\PostgreSQL\9.5\bin\raster2pgsql.exe" -I -M -C -s 3035 C:\tracking_db\data\env_data\raster\corine06.tif -t 20x20 env_data.corine_land_cover | "C:\Program Files\PostgreSQL\9.5\bin\psql.exe" -p 5432 -d gps_tracking_db -U postgres -h localhost

CREATE TABLE env_data.corine_land_cover_legend(
  grid_code integer NOT NULL,
  clc_l3_code character(3),
  label1 character varying,
  label2 character varying,
  label3 character varying,
  CONSTRAINT corine_land_cover_legend_pkey 
    PRIMARY KEY (grid_code ));
COMMENT ON TABLE env_data.corine_land_cover_legend
IS 'Legend of Corine land cover, associating the numeric code to the three nested levels.';

COPY env_data.corine_land_cover_legend 
FROM 
  'C:\tracking_db\data\env_data\raster\corine_legend.csv' 
  WITH (FORMAT csv, HEADER, DELIMITER ';');


SELECT * FROM raster_columns;

COMMENT ON TABLE env_data.adm_boundaries 
IS 'Layer (polygons) of administrative boundaries (comuni).';
COMMENT ON TABLE env_data.corine_land_cover 
IS 'Layer (raster) of land cover (from Corine project).';
COMMENT ON TABLE env_data.meteo_stations 
IS 'Layer (points) of meteo stations.';
COMMENT ON TABLE env_data.roads 
IS 'Layer (lines) of roads network.';
COMMENT ON TABLE env_data.srtm_dem 
IS 'Layer (raster) of digital elevation model (from SRTM project).';
COMMENT ON TABLE env_data.study_area 
IS 'Layer (polygons) of the boundaries of the study area.';

--TOPIC 7.2 (only SELECT queries-dropped)

-- LESSON 8

--TOPIC 8.1

ALTER TABLE main.gps_data_animals 
  ADD COLUMN pro_com integer;
  
ALTER TABLE main.gps_data_animals 
  ADD COLUMN corine_land_cover_code integer;
  
ALTER TABLE main.gps_data_animals 
  ADD COLUMN altitude_srtm integer;
  
ALTER TABLE main.gps_data_animals 
  ADD COLUMN station_id integer;
  
ALTER TABLE main.gps_data_animals 
  ADD COLUMN roads_dist integer;

UPDATE
 main.gps_data_animals
SET
 pro_com = adm_boundaries.pro_com
FROM 
 env_data.adm_boundaries 
WHERE 
 ST_Intersects(gps_data_animals.geom,adm_boundaries.geom);

UPDATE 
 main.gps_data_animals
SET
 corine_land_cover_code = ST_Value(rast,ST_Transform(geom,3035)) 
FROM 
 env_data.corine_land_cover 
WHERE 
 ST_Intersects(ST_Transform(geom,3035), rast);

UPDATE 
 main.gps_data_animals
SET
 altitude_srtm = ST_Value(rast,geom) 
FROM 
 env_data.srtm_dem 
WHERE 
 ST_Intersects(geom, rast);

-- closest station's ID
UPDATE 
 main.gps_data_animals
SET
 station_id = 
 (SELECT 
 meteo_stations.station_id::integer 
 FROM 
 env_data.meteo_stations
 ORDER BY 
 ST_Distance_Spheroid(meteo_stations.geom, gps_data_animals.geom, 'SPHEROID["WGS 84",6378137,298.257223563]') 
 LIMIT 1)
WHERE
 gps_data_animals.geom IS NOT NULL;

--roads (takes 1-2 min)
UPDATE 
 main.gps_data_animals
SET
 roads_dist =
 (SELECT 
 ST_Distance(gps_data_animals.geom::geography, roads.geom::geography)::integer 
 FROM 
 env_data.roads 
 ORDER BY 
 ST_distance(gps_data_animals.geom::geography, roads.geom::geography) 
 LIMIT 1)
WHERE
 gps_data_animals.geom IS NOT NULL;


CREATE OR REPLACE FUNCTION tools.new_gps_data_animals()
RETURNS trigger AS
$BODY$
DECLARE 
  thegeom geometry;
BEGIN

IF NEW.longitude IS NOT NULL AND NEW.latitude IS NOT NULL THEN
  thegeom = ST_SetSRID(ST_MakePoint(NEW.longitude, NEW.latitude), 4326);
  NEW.geom =thegeom;
  NEW.pro_com = 
    (SELECT pro_com::integer 
    FROM env_data.adm_boundaries 
    WHERE ST_Intersects(geom,thegeom)); 
  NEW.corine_land_cover_code = 
    (SELECT ST_Value(rast,ST_Transform(thegeom,3035)) 
    FROM env_data.corine_land_cover 
    WHERE ST_Intersects(ST_Transform(thegeom,3035), rast));
  NEW.altitude_srtm = 
    (SELECT ST_Value(rast,thegeom) 
    FROM env_data.srtm_dem 
    WHERE ST_Intersects(thegeom, rast));
  NEW.station_id = 
    (SELECT station_id::integer 
    FROM env_data.meteo_stations 
    ORDER BY ST_Distance_Spheroid(thegeom, geom, 'SPHEROID["WGS 84",6378137,298.257223563]') 
    LIMIT 1);
  NEW.roads_dist = 
    (SELECT ST_Distance(thegeom::geography, geom::geography)::integer 
    FROM env_data.roads 
    ORDER BY ST_distance(thegeom::geography, geom::geography) 
    LIMIT 1);
END IF;

RETURN NEW;
END;$BODY$
LANGUAGE plpgsql VOLATILE
COST 100;
ALTER FUNCTION tools.new_gps_data_animals()
OWNER TO postgres;
COMMENT ON FUNCTION tools.new_gps_data_animals() 
IS 'When called by the trigger insert_gps_positions 
(raised whenever a new position is uploaded into gps_data_animals) this function gets the longitude and latitude values and sets the geometry field accordingly,
computing a set of derived environmental information calculated intersecting or relating the position with the environmental ancillary layers.';


-- LESSON 9

-- TOPIC 9.1

ALTER TABLE main.gps_data_animals 
  ADD COLUMN gps_validity_code integer;

CREATE TABLE lu_tables.lu_gps_validity(
  gps_validity_code integer,
  gps_validity_description character varying,
  CONSTRAINT lu_gps_validity_pkey 
    PRIMARY KEY (gps_validity_code));
COMMENT ON TABLE lu_tables.lu_gps_validity
IS 'Look up table for GPS positions validity codes.';

ALTER TABLE main.gps_data_animals
  ADD CONSTRAINT animals_lu_gps_validity 
  FOREIGN KEY (gps_validity_code)
  REFERENCES lu_tables.lu_gps_validity (gps_validity_code)
  MATCH SIMPLE ON UPDATE NO ACTION ON DELETE NO ACTION;
  
INSERT INTO lu_tables.lu_gps_validity 
  VALUES (0, 'Position with no coordinate');
INSERT INTO lu_tables.lu_gps_validity 
  VALUES (1, 'Valid Position');
INSERT INTO lu_tables.lu_gps_validity 
  VALUES (2, 'Position with a low degree of reliability');
INSERT INTO lu_tables.lu_gps_validity 
  VALUES (11, 'Position wrong: out of the study area');
INSERT INTO lu_tables.lu_gps_validity 
  VALUES (12, 'Position wrong: impossible spike');
INSERT INTO lu_tables.lu_gps_validity 
  VALUES (13, 'Position wrong: impossible place (e.g. lake or sea)');
INSERT INTO lu_tables.lu_gps_validity 
  VALUES (21, 'Position wrong: duplicated timestamp');

UPDATE main.gps_data_animals 
  SET gps_validity_code = 1;

-- TOPIC 9.2

-- missing coordinates (0)
UPDATE main.gps_data_animals 
  SET gps_validity_code = 0 
  WHERE geom IS NULL;

-- duplicated timestamp (21)
UPDATE main.gps_data_animals 
  SET gps_validity_code = 21 
  WHERE 
    gps_data_animals_id in 
      (SELECT x.gps_data_animals_id 
      FROM 
        main.gps_data_animals x, 
        (SELECT animals_id, acquisition_time 
        FROM main.gps_data_animals 
        WHERE gps_validity_code = 1 
        GROUP BY animals_id, acquisition_time 
        HAVING count(animals_id) > 1) a 
      WHERE 
        a.animals_id = x.animals_id AND 
        a.acquisition_time = x.acquisition_time);

-- outside study area example
SELECT 
  gps_data_animals_id 
FROM 
  main.gps_data_animals 
LEFT JOIN 
  env_data.study_area 
ON 
  ST_Intersects(gps_data_animals.geom, study_area.geom) 
WHERE 
  study_area IS NULL AND 
  gps_data_animals.geom IS NOT NULL;

-- outside study area (11)
UPDATE main.gps_data_animals 
  SET gps_validity_code = 11 
  WHERE 
    gps_data_animals_id in 
    (SELECT gps_data_animals_id 
    FROM main.gps_data_animals, env_data.study_area 
    WHERE ST_Disjoint(
      gps_data_animals.geom,
      ST_Simplify(ST_Buffer(study_area.geom, 0.1), 0.1)));

-- falling in water (13)
UPDATE main.gps_data_animals 
  SET gps_validity_code = 13 
  FROM 
    env_data.corine_land_cover 
  WHERE
    ST_Intersects(
      corine_land_cover.rast,
      ST_Transform(gps_data_animals.geom, 3035)) AND
    ST_Value(
      corine_land_cover.rast, 
      ST_Transform(gps_data_animals.geom, 3035)) 
      in (40,41,42,43,44) AND 
    gps_validity_code = 1 AND 
    ST_Value(
      corine_land_cover.rast, 
      ST_Transform(gps_data_animals.geom, 3035)) != 'NaN';

-- TOPIC 9.3

CREATE OR REPLACE VIEW analysis.view_convex_hulls AS 
SELECT 
  gps_data_animals.animals_id,
  ST_ConvexHull(ST_Collect(gps_data_animals.geom))::geometry(Polygon,4326) AS geom
FROM 
  main.gps_data_animals
WHERE 
  gps_data_animals.gps_validity_code = 1
GROUP BY 
  gps_data_animals.animals_id
ORDER BY 
  gps_data_animals.animals_id;


CREATE OR REPLACE VIEW analysis.view_gps_locations AS 
SELECT 
  gps_data_animals.gps_data_animals_id,
  gps_data_animals.animals_id, 
  animals.name, 
  timezone('UTC'::text, gps_data_animals.acquisition_time) AS time_utc, 
  animals.sex, 
  lu_age_class.age_class_description, 
  lu_species.species_description, 
  gps_data_animals.geom
FROM 
  main.gps_data_animals, 
  main.animals, 
  lu_tables.lu_age_class, 
  lu_tables.lu_species
WHERE 
  gps_data_animals.animals_id = animals.animals_id AND
  animals.age_class_code = lu_age_class.age_class_code AND 
  animals.species_code = lu_species.species_code AND 
  gps_data_animals.gps_validity_code = 1;


CREATE OR REPLACE VIEW analysis.view_trajectories AS 
SELECT 
  sel_subquery.animals_id,
  st_MakeLine(sel_subquery.geom)::geometry(LineString,4326) AS geom
FROM 
  (SELECT 
    gps_data_animals.animals_id, 
    gps_data_animals.geom, 
    gps_data_animals.acquisition_time
  FROM main.gps_data_animals
  WHERE gps_data_animals.gps_validity_code = 1
  ORDER BY gps_data_animals.animals_id, gps_data_animals.acquisition_time) sel_subquery
GROUP BY sel_subquery.animals_id;

-- Topic 9.Supplementary code: Update import procedure with detection of erroneous positions

CREATE OR REPLACE FUNCTION tools.new_gps_data_animals()
RETURNS trigger AS
$BODY$
DECLARE 
thegeom geometry;
BEGIN
IF NEW.longitude IS NOT NULL AND NEW.latitude IS NOT NULL THEN
  thegeom = ST_setsrid(ST_MakePoint(NEW.longitude, NEW.latitude), 4326);
  NEW.geom =thegeom;
  NEW.gps_validity_code = 1;
    IF NOT EXISTS (SELECT study_area FROM env_data.study_area WHERE ST_intersects(ST_Buffer(thegeom,0.1), study_area.geom)) THEN
      NEW.gps_validity_code = 11;
    END IF;
  NEW.pro_com = (SELECT pro_com::integer FROM env_data.adm_boundaries WHERE ST_intersects(geom,thegeom)); 
  NEW.corine_land_cover_code = (SELECT ST_Value(rast, ST_Transform(thegeom, 3035)) FROM env_data.corine_land_cover WHERE ST_Intersects(ST_Transform(thegeom,3035), rast));
  NEW.altitude_srtm = (SELECT ST_Value(rast,thegeom) FROM env_data.srtm_dem WHERE ST_intersects(thegeom, rast));
  NEW.station_id = (SELECT station_id::integer FROM env_data.meteo_stations ORDER BY ST_Distance_Spheroid(thegeom, geom, 'SPHEROID["WGS 84",6378137,298.257223563]') LIMIT 1);
  NEW.roads_dist = (SELECT ST_Distance(thegeom::geography, geom::geography)::integer FROM env_data.roads ORDER BY ST_Distance(thegeom::geography, geom::geography) LIMIT 1);
ELSE 
NEW.gps_validity_code = 0;
END IF;
RETURN NEW;
END;$BODY$
LANGUAGE plpgsql VOLATILE
COST 100;
ALTER FUNCTION tools.new_gps_data_animals()
OWNER TO postgres;
COMMENT ON FUNCTION tools.new_gps_data_animals() 
IS 'When called by the trigger insert_gps_locations (raised whenever a new GPS position is uploaded into gps_data_animals) this function gets the new longitude and latitude values and sets the field geom accordingly, computing a set of derived environmental information calculated intersection the GPS position with the environmental ancillary layers. GPS positions outside the study area are tagged as outliers.';


-- test animal? to show all the processes working.
INSERT INTO main.animals 
  (animals_id, animals_code, name, sex, age_class_code, species_code, note) 
  VALUES (6, 'test', 'test-ina', 'm', 3, 1, 'This is a fake animal, used to test outliers detection processes.');

INSERT INTO main.gps_sensors 
  (gps_sensors_id, gps_sensors_code, purchase_date, frequency, vendor, model, sim) 
  VALUES (6, 'GSM_test', '2005-01-01', 1000, 'Lotek', 'top', '+391441414');

INSERT INTO main.gps_sensors_animals 
  (animals_id, gps_sensors_id, start_time, end_time, notes)
  VALUES (6, 6, '2005-04-04 08:00:00+02', '2005-05-06 02:00:00+02', 'test deployment');

COPY main.gps_data(
  gps_sensors_code, line_no, utc_date, utc_time, lmt_date, lmt_time, ecef_x, ecef_y, ecef_z, latitude, longitude, height, dop, nav, validated, sats_used, ch01_sat_id, ch01_sat_cnr, ch02_sat_id, ch02_sat_cnr, ch03_sat_id, ch03_sat_cnr, ch04_sat_id, ch04_sat_cnr, ch05_sat_id, ch05_sat_cnr, ch06_sat_id, ch06_sat_cnr, ch07_sat_id, ch07_sat_cnr, ch08_sat_id, ch08_sat_cnr, ch09_sat_id, ch09_sat_cnr, ch10_sat_id, ch10_sat_cnr, ch11_sat_id, ch11_sat_cnr, ch12_sat_id, ch12_sat_cnr, main_vol, bu_vol, temp, easting, northing, remarks)
FROM
  'C:\tracking_db\data\sensors_data\GSM_test.csv' 
    WITH (FORMAT csv, HEADER, DELIMITER ';');

-- View updated data
SELECT * FROM main.gps_data_animals WHERE animals_id = 6;

-- Delete all data related to animal 6
DELETE FROM main.gps_data_animals WHERE animals_id = 6;
DELETE FROM main.gps_sensors_animals WHERE animals_id = 6;
DELETE FROM main.animals WHERE animals_id = 6;
DELETE FROM main.gps_data WHERE gps_sensors_code = 'GSM_test';
DELETE FROM main.gps_sensors WHERE gps_sensors_code = 'GSM_test';
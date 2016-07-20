# Integration of spatial data and exercises

% Lesson 5. Spatial data types in PostgreSQL/PostGIS
% 7 June 2016


This lesson will focus on introducing spatial data types, which will
enable you to accomplish richer analysis of wildlife tracking data. By
the end of the lesson you will become familiar with geometry columns,
and make the database compute answers to spatial questions. We will
make use of the `demo` database on the host `basille-flrec.ad.ufl.edu`
for this lesson.


## Spatial data


### Introduction 

An ordinary database has strings, numbers, and dates. A spatial
database adds additional (spatial) types for representing geographic
features.  These spatial data types abstract and encapsulate spatial
structures such as boundary and dimension. In many respects, spatial
data types can be understood simply as shapes: typically points,
curves, surfaces and collections of them.

![hierarchy](images/l5/hierarchy.png)

Such data were traditionally manipulated outside of databases using
specialized tools (GIS software) until very recently. In the last 15
years or so, spurred by the wide usage of GPS systems, a few
implementations of GIS tools for RBMS have emerged. There has also
been an effort to [standardize](http://www.opengeospatial.org/) many
aspects of spatial systems, which made data exchange between different
platforms somewhat more comfortable.

For manipulating data during a query, an ordinary database provides
functions such as concatenating strings, performing hash operations on
strings, doing mathematics on numbers, and extracting information from
dates. A spatial database provides a complete set of functions for
analyzing geometric components, determining spatial relationships, and
manipulating geometries. These spatial functions serve as the building
block for any spatial project.

The majority of all spatial functions can be grouped into one of the
following five categories:

-   Conversion: Functions that convert between geometries and external
    data formats.
-   Management: Functions that manage information about spatial tables
    and PostGIS administration.
-   Retrieval: Functions that retrieve properties and measurements of
    a Geometry.
-   Comparison: Functions that compare two geometries with respect to
    their spatial relation.
-   Generation: Functions that generate new geometries from others.

The list of possible functions is very large, but a common set of
functions is defined by the
[OGC SFSQL](http://workshops.boundlessgeo.com/postgis-intro/glossary.html#term-sfsql).

In the Open Source world, one of the richest implementations of the
spatial SQL standards is provided by the
[PostGIS](http://postgis.net/) extension for PostgreSQL - and that was
one strong motivation for choosing this particular RDBMS for analyzing
tracking data.

As we have seen before, RDBMS allow for storing and searching large
amounts of data: to optimize access times, they make use of indexes
which are often in the form of
[B-trees](http://en.wikipedia.org/wiki/B-tree). Spatial data require a
different kind of indexes for efficient searching: spatial indexes are
generally computed around the concept of *bounding box*: A bounding
box is the smallest rectangle - parallel to the coordinate axes -
capable of containing a given feature.

Bounding boxes are used because answering the question “is A inside
B?”  is very computationally intensive for polygons but very fast in
the case of rectangles. Even the most complex polygons and linestrings
can be represented by a simple bounding box.

Indexes have to perform quickly in order to be useful. So instead of
providing exact results, as B-trees do, spatial indexes provide
approximate results. The question “what lines are inside this
polygon?”  will be instead interpreted by a spatial index as “what
lines have bounding boxes that are contained inside this polygon’s
bounding box?”

PostGIS extension supports
[R-tree spatial indexes](http://en.wikipedia.org/wiki/R-tree),
allowing for fast answers to many geometrical questions.


### Example 

We have already enabled the spatial extensions for `demo`. The command
to install PostGIS inside a database is:

```sql
CREATE EXTENSION postgis;
```

To check that everything is in order, we can call our first PostGIS
function, `postgis_full_version`. On the server, we obtain the
following answer:

``` sql
SELECT postgis_full_version();
```

```postgis_full_version                                                                              
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
POSTGIS="2.2.2 r14797" GEOS="3.4.2-CAPI-1.8.2 r3921" PROJ="Rel. 4.8.0, 6 March 2012" GDAL="GDAL 1.10.1, released 2013/08/26" LIBXML="2.9.1" LIBJSON="0.11.99" RASTER
(1 row)
```

So far, so good. Now, we build a new `geometries` table with a column
of type (surprise, surprise!) `geometry`, and then put some data in
it:

```sql 
--don't run
CREATE TABLE geometries (name varchar, geom geometry);
INSERT INTO geometries VALUES
  ('Point', 'POINT(0 0)'),
  ('Linestring', 'LINESTRING(0 0, 1 1, 2 1, 2 2)'),
  ('Polygon', 'POLYGON((0 0, 1 0, 1 1, 0 1, 0 0))'),
  ('PolygonWithHole', 'POLYGON((0 0, 10 0, 10 10, 0 10, 0 0),(1 1, 1 2, 2 2, 2 1, 1 1))'),
  ('Collection', 'GEOMETRYCOLLECTION(POINT(2 0),POLYGON((0 0, 1 0, 1 1, 0 1, 0 0)))');
```

Note that we are inserting a string value into column `geom`: the
format is called
[Well-known text](https://en.wikipedia.org/wiki/Well-known_text), WKT
for short, and is also standardized.

The internal database representation is not meant for being readable:

``` sql
SELECT geom FROM geometries WHERE name = 'Point';
```

```
                    geom                    
--------------------------------------------
 010100000000000000000000000000000000000000
(1 row)
```

Among the many functions provided by PostGIS, you find one for
converting from the internal representation back to WKT:

```sql
SELECT name, ST_AsText(geom) FROM geometries;
```

```
      name       |                           st_astext                           
-----------------+---------------------------------------------------------------
 Point           | POINT(0 0)
 Linestring      | LINESTRING(0 0,1 1,2 1,2 2)
 Polygon         | POLYGON((0 0,1 0,1 1,0 1,0 0))
 PolygonWithHole | POLYGON((0 0,10 0,10 10,0 10,0 0),(1 1,1 2,2 2,2 1,1 1))
 Collection      | GEOMETRYCOLLECTION(POINT(2 0),POLYGON((0 0,1 0,1 1,0 1,0 0)))
(5 rows)
```

Geometric data can also be computed directly from coordinates, as in:

```sql
SELECT ST_MakePoint(11.001,46.001) AS point;
```

```
                   point                    
--------------------------------------------
 01010000008D976E1283002640E3A59BC420004740
(1 row)
```

The textual representation is easier to recognize, of course:

```sql
SELECT ST_AsText(ST_MakePoint(11.001,46.001)) AS point;
```

```
        point         
----------------------
 POINT(11.001 46.001)
(1 row)
```

In conformance with the standard, PostGIS offers a way to track and
report on the geometry types available in a given database:

```sql
SELECT * FROM geometry_columns;
```

```
 f_table_catalog | f_table_schema |        f_table_name        | f_geometry_column | coord_dimension | srid |      type       
-----------------+----------------+----------------------------+-------------------+-----------------+------+-----------------
 demo | analysis       | home_ranges_mcp            | geom              |               2 | 4326 | MULTIPOLYGON
 demo | analysis       | test_randompoints          | geom              |               2 | 4326 | POINT
 demo | analysis       | trajectories               | geom              |               2 | 4326 | LINESTRING
 demo | main           | gps_data_animals           | geom              |               2 | 4326 | POINT
 demo | analysis       | view_convex_hulls          | geom              |               2 | 4326 | POLYGON
 demo | analysis       | view_gps_locations         | geom              |               2 | 4326 | POINT
 demo | analysis       | view_locations_buffer      | geom              |               2 | 4326 | MULTIPOLYGON
 demo | analysis       | view_probability_grid_traj | geom              |               2 | 4326 | POLYGON
 demo | env_data       | study_area                 | geom              |               2 | 4326 | MULTIPOLYGON
 demo | analysis       | view_test_randompoints     | geom              |               2 | 4326 | POINT
 demo | analysis       | view_trajectories          | geom              |               2 | 4326 | LINESTRING
 demo | env_data       | adm_boundaries             | geom              |               2 | 4326 | MULTIPOLYGON
 demo | env_data       | meteo_stations             | geom              |               2 | 4326 | POINT
 demo | env_data       | roads                      | geom              |               2 | 4326 | MULTILINESTRING
 demo | main           | view_locations_set         | geom              |               2 |    0 | GEOMETRY
 demo | public         | geometries                 | geom              |               2 |    0 | GEOMETRY
(16 rows)
```

The previous query informs us that inside our `demo` there are 16
tables with a geometry column, and that each of these columns is named
`geom` and contains 2-dimensional data. Most of them, unlike the one
we have just created, only accept a specific data type. Furthermore,
they also carry information about the reference coordinate system in
use, via the [SRID](https://en.wikipedia.org/wiki/SRID) parameter.

The number `4326` refers to
[EPSG:4326](http://spatialreference.org/ref/epsg/4326/), which is
European Petroleum Survey Group identifier for WGS84:

```sql
GEOGCS["WGS 84",
    DATUM["WGS_1984",
        SPHEROID["WGS 84",6378137,298.257223563,
            AUTHORITY["EPSG","7030"]],
        AUTHORITY["EPSG","6326"]],
    PRIMEM["Greenwich",0,
        AUTHORITY["EPSG","8901"]],
    UNIT["degree",0.01745329251994328,
        AUTHORITY["EPSG","9122"]],
    AUTHORITY["EPSG","4326"]]
```

In the case of `demo` data, we are not storing planar Euclidean
coordinates, but use latitude and longitude to identify a point on the
ellipsoid expressed by the geodetic datum WGS\_1984 - the one used
globally by GPS systems.

Our test table `geometries` actually does not specify an SRID, but we
can easily fix that:

```sql
SELECT UpdateGeometrySRID('geometries','geom',4326);
```

```
             updategeometrysrid              
---------------------------------------------
 public.geometries.geom SRID changed to 4326
(1 row)
```

Let's query the contents of our `geometries` table using PostGIS some
functions intended for metadata retrieval:

```sql
SELECT name, ST_GeometryType(geom), ST_NDims(geom), ST_SRID(geom)
FROM geometries;
```

```
      name       |    st_geometrytype    | st_ndims | st_srid 
-----------------+-----------------------+----------+---------
 Point           | ST_Point              |        2 |    4326
 Linestring      | ST_LineString         |        2 |    4326
 Polygon         | ST_Polygon            |        2 |    4326
 PolygonWithHole | ST_Polygon            |        2 |    4326
 Collection      | ST_GeometryCollection |        2 |    4326
(5 rows)
```

When using real world spatial data obtained from various sources, you
will likely encounter different coordinate systems. One of the tasks
that you will need to accomplish will be to re-project the data into a
common SRID, in order to be able to do any useful work.

Taken together, a coordinate and an SRID define a location on the
globe.  Without an SRID, a coordinate is just an abstract notion. A
“Cartesian” coordinate plane is defined as a “flat” coordinate system
placed on the surface of Earth. Because PostGIS functions work on such
a plane, comparison operations require that both geometries be
represented in the same SRID.

If you feed in geometries with differing SRIDs you will just get an
error:

```sql
SELECT ST_Equals(
        ST_GeomFromText('POINT(0 0)', 4326),
        ST_GeomFromText('POINT(0 0)', 26918)
);
```

```
ERROR:  Operation on mixed SRID geometries
CONTEXT:  SQL function "st_equals" statement 1
```

PostGIS has a table enumerating all the projections it knows about,
that you can use to lookup the correct number:

```sql
SELECT * FROM spatial_ref_sys;
```

Using the correct SRID, you can then reproject data with
`ST_Transform(geometry, srid)`. Let's transform one of our geometries
to UTM32 WGS84 (SRID 32632):

```sql
SELECT
    name,
    ST_AsText(geom) AS wgs84,
    ST_AsText(ST_Transform(geom,32632)) AS utm32
FROM
    geometries
WHERE
    name = 'Point';
```

```
 name  |   wgs84    |           utm32            
-------+------------+----------------------------
 Point | POINT(0 0) | POINT(-505646.888236832 0)
(1 row)
```

The above example is a bit contrived, but you get the point.

Our spatial extension is intended for data analysis, thus it also
sports many function for computing things out of a geometry:

``` sql
SELECT name, ST_AsText(geom), ST_NPoints(geom), ST_Length(geom), ST_Perimeter(geom), ST_Area(geom)
FROM geometries;
```

```
      name       |                           st_astext                           | st_npoints |    st_length     | st_perimeter | st_area 
-----------------+---------------------------------------------------------------+------------+------------------+--------------+---------
 Point           | POINT(0 0)                                                    |          1 |                0 |            0 |       0
 Linestring      | LINESTRING(0 0,1 1,2 1,2 2)                                   |          4 | 3.41421356237309 |            0 |       0
 Polygon         | POLYGON((0 0,1 0,1 1,0 1,0 0))                                |          5 |                0 |            4 |       1
 PolygonWithHole | POLYGON((0 0,10 0,10 10,0 10,0 0),(1 1,1 2,2 2,2 1,1 1))      |         10 |                0 |           44 |      99
 Collection      | GEOMETRYCOLLECTION(POINT(2 0),POLYGON((0 0,1 0,1 1,0 1,0 0))) |          6 |                0 |            4 |       1
(5 rows)
```

Other functions can be used to test of compute relations between
geometries, like `ST_Equals` we have seen before. Probably the most
used one will be `ST_Distance`:

```sql
 SELECT 
  ST_Distance(
     ST_SetSRID(ST_MakePoint(-80.238,26.084), 4326),
     ST_SetSRID(ST_MakePoint(-82.355,29.644), 4326)
  ) AS distance;
```

```
      distance      
--------------------
 4.1418943733514
(1 row)
```

As you can see, the result is given in the original unit, decimal
degrees. If you want to compute the distance in kilometers, you could
do it in Euclidean space, by projecting both point to the correct
coordinate system:

```sql
--Transform from WGS 1984 to UTM Zone 17N (NAD 83)
SELECT
 ST_Distance(
   ST_Transform(ST_SetSRID(ST_MakePoint(-80.238,26.084), 4326),26917),
   ST_Transform(ST_SetSRID(ST_MakePoint(-82.355,29.644), 4326),26917)
)/1000 AS distance;
```

```
     distance     
------------------
 446.030122288446
(1 row)
```

PostGIS can be more accurate than that, though: at the cost of some
more complex calculations, you can ask it to compute the actual
distance on the WGS84 spheroid surface:

```sql
--No transformation, calculated distance on the WGS 1984 spheroid
SELECT
 ST_Distance(
   ST_SetSRID(ST_MakePoint(-80.238,26.084), 4326),
   ST_SetSRID(ST_MakePoint(-82.355,29.644), 4326),
   true
)/1000 AS distance;
```

```
    distance    
----------------
 446.18470782638
(1 row)
```

The available functions are many, many more: look them up in the
[reference](http://postgis.net/docs/manual-2.0/reference.html) to get
a grasp of what kind of tools PostGIS will offer you.



% Lesson 6. Spatial is not special: how to manage the locations data in a spatial database: PostGIS
% 7 June 2016


A wildlife tracking data management system must include the capability
to explicitly deal with the spatial component of movement data. GPS
tracking data are sets of spatio-temporal objects (locations) and the
spatial component must be properly handled. You will now extend the
database adding spatial functionalities through the PostgreSQL spatial
extension called [PostGIS](http://postgis.refractions.net/). PostGIS
introduces the spatial data types (both vector and raster) and a large
set of SQL spatial functions and tools, including spatial
indexes. This possibility essentially allows you to build a GIS using
the existing capabilities of relational databases. In this lesson, you
will implement a system that automatically transforms the GPS
coordinates generated by GPS sensors from a pair of numbers into
spatial objects.


## Topic 1. Transforming GPS Coordinates into a Spatial Object


### Introduction

At the moment, your data are stored in the database and the GPS
positions are linked to individuals. While time is properly managed,
coordinates are still just two decimal numbers (longitude and
latitude) and not spatial objects. It is therefore not possible to
find the distance between two points, or the length of a trajectory,
or the speed and angle of the step between two locations. In this
chapter, you will learn how to add a spatial extension to your
database and transform the coordinates into a spatial element (i.e. a
point). Until few years ago, the spatial information produced by GPS
sensors was managed and analyzed using dedicated software (GIS) in
file-based data formats (e.g. shapefile). Nowadays, the most advanced
approaches in data management consider the spatial component of
objects (e.g. a moving animal) as one of its many attributes: thus,
while understanding the spatial nature of your data is essential to
proper analysis, from a software perspective spatial is (less and
less) not special. Spatial databases are the technical tool needed to
implement this perspective. They integrate spatial data types (vector
and raster) together with standard data types that store the objects'
other (non-spatial) associated attributes. Spatial data types can be
manipulated by SQL through additional commands and functions for the
spatial domain. This possibility essentially allows you to build a GIS
using the existing capabilities of relational databases. Moreover,
while dedicated GIS software is usually focused on analyses and data
visualization, providing a rich set of spatial operations, few are
optimized for managing large spatial data sets (in particular, vector
data) and complex data structures. Spatial databases, in turn, allow
both advanced management and spatial operations that can be
efficiently undertaken on a large set of elements. This combination of
features is becoming essential, as with animal movement data sets the
challenge is now on the extraction of synthetic information from very
large data sets rather than on the extrapolation of new information
(e.g. kernel home ranges from VHF data) from limited data sets with
complex algorithms.


### Example

The first step to do in order to spatially enable your database is to
load the PostGIS extension, which can easily done with the following
SQL command (many other extensions exist for PostgreSQL):

```sql
CREATE EXTENSION postgis;
```

Now you can use and exploit all the features offered by PostGIS in
your database. The vector objects (points, lines, and polygons) are
stored in a specific field of your tables as spatial data types. This
field contains the structured list of vertexes, i.e. coordinates of
the spatial object, and also includes its reference system. The
PostGIS spatial (vectors) data types are not topological, although, if
needed, PostGIS has a dedicated
[topological extension](http://postgis.refractions.net/docs/Topology.html).

With PostGIS activated, you can create a field with geometry data type
in your table (2D point feature with longitude/latitude WGS84 as
reference system):

```sql
ALTER TABLE main.gps_data_animals 
  ADD COLUMN geom geometry(Point,4326);
```

You can create a spatial index:

```sql
CREATE INDEX gps_data_animals_geom_gist
  ON main.gps_data_animals
  USING gist (geom);
```

You can now populate it (excluding points that have no
latitude/longitude):

```sql
UPDATE 
  main.gps_data_animals
SET 
  geom = ST_SetSRID(ST_MakePoint(longitude, latitude),4326)
WHERE 
  latitude IS NOT NULL AND longitude IS NOT NULL;
```

At this point, it is important to visualize the spatial content of
your tables. PostgreSQL/PostGIS offers no tool for spatial data
visualization, but this can be done by a number of client
applications, in particular GIS desktop software like
[ESRI ArcGIS 10.x](http://www.esri.com/software/arcgis) or
[QGIS](http://www.qgis.org/). QGIS is a powerful and complete open
source software. It offers all the functions needed to deal with
spatial data. QGIS is the suggested GIS interface because it has many
tools specifically for managing and visualizing PostGIS
data. Especially remarkable is the tool *DB Manager*. Now you can
explore the GPS positions data set in QGIS (see figure below). The
example is a view zoomed in on the study area rather than all points,
because some outliers are located very far from Monte Bondone,
affecting the default visualization. In the background you have the
Google satellite layer loaded using the *OpenLayer Plugin*.

![gps-qgis](images/l6/gps-qgis.png)

You can also use ArcGIS ESRI 10.x to visualize (but not natively edit,
at least at the time of writing this text) your spatial data. Data can
be accessed using “Query layers”. A query layer is a layer or
stand-alone table that is defined by a SQL query. Query layers allow
both spatial and non-spatial information stored in a (spatial) DBMS to
be integrated into GIS projects within ArcMap. When working in ArcMap,
you create query layers by defining a SQL query. The query is then run
against the tables and views in a database, and the result set is
added to ArcMap. Query layers behave like any other feature layer or
stand-alone table, so they can be used to display data, used as input
into a geoprocessing tool, or accessed using developer APIs. The query
is executed every time the layer is displayed or used in ArcMap. This
allows the latest information to be visible without making a copy or
snapshot of the data and is especially useful when working with
dynamic information that is frequently changing.


### Exercise

1.  Find the distance of all locations of animal 2 to the point
    (11.0620855, 45.9878812).


## Topic 2. Automating the Creation of Points from GPS Coordinates


### Introduction

Working with massive data sets (i.e. many sensors at the same time) in
near real time requires that routinely operations are done
automatically to save time and to avoid errors of manual
processing. Here you create a new function to update the geometry
field as soon as a new record is uploaded.


### Example

You can automate the population of the geometry column so that
whenever a new GPS position is updated in the
table*main.gps\_data\_animals*, the spatial geometry is also
created. To do so, you need a trigger and its related function. Here
is the SQL code to generate the function:

```sql
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
```

```sql
COMMENT ON FUNCTION tools.new_gps_data_animals() 
IS 'When called by a trigger (insert_gps_locations) this function populates the field geom using the values from longitude and latitude fields.';
```

And here is the SQL code to generate the trigger:

```sql
CREATE TRIGGER insert_gps_location
  BEFORE INSERT
  ON main.gps_data_animals
  FOR EACH ROW
  EXECUTE PROCEDURE tools.new_gps_data_animals();
```

You can see the result by deleting all the records from the
*main.gps\_data\_animals* table, e.g. for animal 2, and reloading
them. As you have set an automatic procedure to synchronize
*main.gps\_data\_animals* table with the information contained in the
table *main.gps\_sensors\_animals* (supplementary code in Lesson 4),
you can drop the animal 2 record from *main.gps\_sensors\_animals* and
this will affect *main.gps\_data\_animals* in a cascade effect (note
that it will not affect the original data in *main.gps\_data*):

```sql
DELETE FROM 
  main.gps_sensors_animals 
WHERE 
  animals_id = 2;
```

There are now no rows for animal 2 in the table
*main.gps\_data\_animals*. You can verify this by retrieving the
number of locations per animal:

```sql
SELECT 
  animals_id, count(animals_id) 
FROM 
  main.gps_data_animals
GROUP BY 
  animals_id
ORDER BY 
  animals_id;
```

The result should be:

| animals\_id | count |
|-------------|-------|
| 1           | 2114  |
| 3           | 2106  |
| 4           | 2869  |
| 5           | 2924  |

Note that animal 2 is not in the list. Now you reload the record in
the *main.gps\_sensors\_animals*:

```sql
INSERT INTO main.gps_sensors_animals 
  (animals_id, gps_sensors_id, start_time, end_time, notes) 
VALUES 
  (2,1,'2005-03-20 16:03:14 +0','2006-05-27 17:00:00 +0','End of battery life. Sensor not recovered.');
```

You can see that records have been re-added to
*main.gps\_data\_animals* by reloading the original data stored
in*main.gps\_data*, with the geometry field correctly and
automatically populated (when longitude and latitude are not null):

```sql
SELECT 
  animals_id, count(animals_id) AS num_records, count(geom) AS num_records_valid 
FROM 
  main.gps_data_animals
GROUP BY 
  animals_id
ORDER BY 
  animals_id;
```

The result is:

| animals\_id | num\_records | num\_records\_valid |
|-------------|--------------|---------------------|
| 1           | 2114         | 1650                |
| 2           | 2624         | 2196                |
| 3           | 2106         | 1828                |
| 4           | 2869         | 2642                |
| 5           | 2924         | 2696                |

You can now play around with your spatial data set. For example, when
you have a number of locations per animal, you can find the centroid
of the area covered by the locations:

```sql
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
```

The result is:

| animals\_id | centroid                                           |
|-------------|----------------------------------------------------|
| 1           | SRID=4326;POINT(11.056405072 46.0065913348485)     |
| 2           | SRID=4326;POINT(11.0388902698087 46.0118316898451) |
| 3           | SRID=4326;POINT(11.062054399453 46.0229784057986)  |
| 4           | SRID=4326;POINT(11.0215063307722 46.0046905791446) |
| 5           | SRID=4326;POINT(11.0287071960312 46.0085975505935) |

In this case you used the SQL command
[ST\_Collect](http://postgis.refractions.net/docs/ST_Collect.html). This
function returns a GEOMETRYCOLLECTION or a MULTI object from a set of
geometries. The collect function is an 'aggregate' function in the
terminology of PostgreSQL. That means that it operates on rows of
data, in the same way the sum() and mean() functions do. *ST\_Collect*
and [ST\_Union](http://postgis.refractions.net/docs/ST_Union.html) are
often interchangeable. *ST\_Collect* is in general orders of magnitude
faster than *ST\_Union* because it does not try to dissolve
boundaries. It merely rolls up single geometries into MULTI and MULTI
or mixed geometry types into Geometry Collections. The contrary of
*ST\_Collect* is
[ST\_Dump](http://postgis.refractions.net/docs/ST_Dump.html), which is
a set-returning function.


### Exercise

1.  Find the centroids of all the points for each month for animal 2,
    and load them in QGIS as a layer.


## Topic 3. Creating Spatial Database Views

[Views](http://www.postgresql.org/docs/devel/static/sql-createview.html)
are queries permanently stored in the database. For users (and client
applications), they work like normal tables, but their data are
calculated at query time and not physically stored. Changing the data
in a table alters the data shown in subsequent invocations of related
views. Views are useful because they can represent a subset of the
data contained in a table; can join and simplify multiple tables into
a single virtual table; take very little space to store, as the
database contains only the definition of a view (i.e. the SQL query),
not a copy of all the data it presents; and provide extra security,
limiting the degree of exposure of tables to the outer world. On the
other hand, a view might take some time to return its data
content. For complex computations that are often used, it is more
convenient to store the information in a permanent table.


### Example

You can create views where derived information is (virtually)
stored. First, create a new schema where all the analysis can be
accommodated and kept separated from the basic data:

```sql
CREATE SCHEMA analysis
  AUTHORIZATION postgres;
  GRANT USAGE ON SCHEMA analysis TO basic_user;
```

```sql
COMMENT ON SCHEMA analysis 
IS 'Schema that stores key layers for analysis.';
```

```sql
ALTER DEFAULT PRIVILEGES 
  IN SCHEMA analysis 
  GRANT SELECT ON TABLES 
  TO basic_user;
```

You can see below an example of a view in which just (spatially valid)
positions of a single animal are included, created by joining the
information with the animal and look-up tables.

```sql
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
```

```sql
COMMENT ON VIEW analysis.view_gps_locations
IS 'GPS locations.';
```

Although the best way to visualize this view is in a GIS environment
(in QGIS you might need to explicitly define the unique identifier of
the view, i.e. *gps\_data\_animals\_id*), you can query its
non-spatial content with

```sql
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
```

The result is something similar to:

| id  | animal   | time\_utc           | sex | age   | species  |
|-----|----------|---------------------|-----|-------|----------|
| 62  | Agostino | 2005-03-20 16:03:14 | m   | adult | roe deer |
| 64  | Agostino | 2005-03-21 00:03:06 | m   | adult | roe deer |
| 65  | Agostino | 2005-03-21 04:01:45 | m   | adult | roe deer |
| 67  | Agostino | 2005-03-21 12:02:19 | m   | adult | roe deer |
| 68  | Agostino | 2005-03-21 16:01:12 | m   | adult | roe deer |

Now you create view with a different representation of your data
sets. In this case you derive a trajectory from GPS points. You have
to order locations per animal and per acquisition time; then you can
group them (animal by animal) in a trajectory (stored as a view):

```sql
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
```

```sql
COMMENT ON VIEW analysis.view_trajectories
IS 'GPS locations – Trajectories.';
```

In the figure below you can see *analysis.view\_trajectories*
visualized in QGIS.

![traj_view](images/l6/traj-view.png)

Lastly, create one more view to spatially summarize the GPS data set
using convex hull polygons (or minimum convex polygons):

```sql
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
    animals_id 
```

```sql
COMMENT ON VIEW analysis.view_convex_hulls
IS 'GPS locations - Minimum convex polygons.';
```

The result is represented in the figure below, where you can clearly
see the effect of the outliers located far from the study area.

![ch-view](images/l6/ch-view.png)

This last view is correct only if the GPS positions are located in a
relatively small area (e.g. less than 50 kilometers) because the
minimum convex polygon of points in geographic coordinates cannot be
calculated assuming that coordinates are related to Euclidean
space. At the moment the function *ST\_ConvexHull* does not support
the GEOGRAPHY data type, so the correct way to proceed would be to
project the GPS locations in a proper reference system, calculate the
minimum convex polygon and then convert the result back to geographic
coordinates. In the example, the error is negligible.


### Exercise

1.  Create a view of all the points of female animals, visualize it in
    QGIS and export as shapefile.


## Supplementary code: UTM zone of a given point in geographic coordinates

Here you create a simple function to automatically find the UTM zone
at defined coordinates:

```sql
CREATE OR REPLACE FUNCTION tools.srid_utm(longitude double precision, latitude double precision)
RETURNS integer AS
$BODY$
DECLARE
  srid integer;
  lon float;
  lat float;
BEGIN
  lat := latitude;
  lon := longitude;

IF ((lon > 360 or lon < -360) or (lat > 90 or lat < -90)) THEN 
  RAISE EXCEPTION 'Longitude and latitude is not in a valid format (-360 to 360; -90 to 90)';
ELSEIF (longitude < -180)THEN 
  lon := 360 + lon;
ELSEIF (longitude > 180)THEN 
  lon := 180 - lon;
END IF;

IF latitude >= 0 THEN 
  srid := 32600 + floor((lon+186)/6); 
ELSE
  srid := 32700 + floor((lon+186)/6); 
END IF;

RETURN srid;
END;
$BODY$
LANGUAGE plpgsql VOLATILE STRICT
COST 100;
```

```sql
COMMENT ON FUNCTION tools.srid_utm(double precision, double precision) 
IS 'Function that returns the SRID code of the UTM zone where a point (in geographic coordinates) is located. For polygons or line, it can be used giving ST_x(ST_Centroid(the_geom)) and ST_y(ST_Centroid(the_geom)) as parameters. This function is typically used be used with ST_Transform to project elements with no prior knowledge of their position.';
```

Here an example to see the SRID of the UTM zone of the point at
coordinates (11.001,46.001):

```sql
SELECT TOOLS.SRID_UTM(11.001,46.001) AS UTM_zone;
```

The result is 32632 that corresponds to UTM 32 N WGS84.

You can use this function to project points when you do not know the
UTM zone. You can test this functionality with the following code:

```sql
SELECT
  ST_AsEWKT(
    ST_Transform(
      ST_SetSRID(ST_MakePoint(31.001,16.001), 4326),
      TOOLS.SRID_UTM(31.001,16.001))
  ) AS projected_point;
```

If you want to allow the user `basic_user` to project spatial data,
you have to grant permission on the table `spatial_ref_sys`:

```sql
GRANT SELECT ON TABLE spatial_ref_sys TO basic_user;
```


## Summary exercise of Lesson 6

1.  Create a view with a convex hull for all the points of every month
    for animal 2 and visualize in QGIS to check if there is any
    spatial pattern;
2.  Calculate the area of the monthly convex hulls of animal 2 and
    verify if there is any temporal pattern;
3.  Repeat the above exercises for all the animals.



% Lesson 7. Environmental layers: integration and management of spatial ancillary information
% 8 June 2016


Animals move in and interact with complex environments that can be
characterized by a set of spatial layers containing environmental
data. Spatial databases can manage these different data sets in a
unified framework, defining spatial and non-spatial relationships that
simplify the analysis of the interaction between animals and their
habitat. This simplifies a large set of analyses that can be performed
directly in the database with no need for dedicated GIS or statistical
software. Such an approach moves the information content managed in
the database from a *geographical space* to an *animal's ecological
space*. This more comprehensive database model of the animals'
movement ecology reduces the distance between physical reality and the
way data are structured in the database, filling the semantic gap
between the scientist's view of biological systems and its
implementation in the information system. This lesson shows how vector
and raster layers can be included in the database and how you can
handle them using (spatial) SQL. The database built so far is extended
with environmental ancillary data sets.


## Topic 1. Adding ancillary environmental layers


### Introduction

In traditional information systems for wildlife tracking data
management, position data are stored in some file-based spatial format
(e.g. shapefile). With a multi-steps process in a GIS environment,
position data are associated with a set of environmental attributes
through an analytical stage (e.g. intersection of GPS positions with
vector and raster environmental layers). This process is usually
time-consuming and prone to error, implies data replication, and often
has to be repeated for any new analysis. It also generally involves
different tools for vector and raster maps. An advanced data
management system should achieve the same result with an efficient
(and, if needed, automated) procedure, possibly performed as a
real-time routine management task. To do so, the first step is to
integrate both position data and spatial ancillary information on the
environment in a unique framework. This is essential to exploring the
animals' behavior and understanding the ecological relationships that
can be revealed by tracking data. Spatial databases can manage these
different data sets in a unified framework. This also affects
performance, as databases are optimized to run simple processes on
large data sets like the ones generated by GPS sensors. In this
exercise, you will see how to integrate a number of spatial features
(see figure below).

![layers](images/l7/layers.png)

-   Points: meteorological stations (derived from
    [MeteoTrentino](http://www.meteotrentino.it/))
-   Linestrings: roads network (derived from
    [OpenStreetMap](http://www.openstreetmap.org/))
-   Polygons: administrative units (derived from
    [ISTAT](http://www.istat.it/it/strumenti/cartografia)) and the
    study area.
-   Rasters: land cover (source:
    [Corine](http://www.eea.europa.eu/data-and-maps/data/corine-land-cover-2006-clc2006-100-m-version-12-2009))
    and digital elevation models (source:
    [SRTM](http://srtm.csi.cgiar.org/), see also *Jarvis A, Reuter HI,
    Nelson A, Guevara E (2008) Hole-filled seamless SRTM data
    V4. International Centre for Tropical Agriculture (CIAT)*).


### Example

Each species and study have specific data sets required and available,
so the goal of this example is to show a complete set of procedures
that can be replicated and customized on different data sets. Once
layers are integrated into the database, you are encouraged to
visualize and explore them in a GIS environment (e.g. QGIS). Once data
are loaded into the database, you will extend the *gps\_data\_animals*
table with the environmental attributes derived from the ancillary
layers provided in the test data set. You will also modify the
function *tools.new\_gps\_data\_animals* to compute these values
automatically. In addition, you are encouraged to develop your own
(spatial) queries (e.g. detect how many times each animal crosses a
road, calculate how many times two animals are in the same place at
the same time). It is a good practice to store your environmental
layers in a dedicated schema in order to keep a clear database
structure. Let's create the schema *env\_data*:

```sql
CREATE SCHEMA env_data
  AUTHORIZATION postgres;
GRANT USAGE ON SCHEMA env_data TO basic_user;
```

```sql
COMMENT ON SCHEMA env_data 
IS 'Schema that stores environmental ancillary information.';
```

```sql
ALTER DEFAULT PRIVILEGES IN SCHEMA env_data 
  GRANT SELECT ON TABLES TO basic_user;
```

Now you can start importing the shapefiles of the (vector)
environmental layers included in the test data set. An option is to
use the drag and drop function of *DB Manager* (from QGIS Browser)
plugin in QGIS (from the *QGIS Data Browser*), or the DB manager tool
*Update/import layer* in QGIS desktop.

Alternatively, a standard solution to import shapefiles (vector data)
is the
[shp2pgsql](http://suite.opengeo.org/4.1/dataadmin/pgGettingStarted/shp2pgsql.html)
tool. *sph2pgsql* is an external command-line tool, which can not be
run in a SQL interface as it can for a regular SQL command. The code
below has to be run in a command-line interpreter (if you are using
Windows as operating system, it is also called Command Prompt or
MS-DOS shell). You will see other examples of external tools that are
run in the same way, and it is very important to understand the
difference between these and SQL commands. In these exercises, this
difference is represented with a different graphic layout. Start with
the meteorological stations:

```
> "C:\\Program Files\\PostgreSQL\\9.5\\bin\\shp2pgsql.exe" -s 4326 -I C:\\tracking\_db\\data\\env\_data\\vector\\meteo\_stations.shp env\_data.meteo\_stations | "C:\\Program Files\\PostgreSQL\\9.5\\bin\\psql.exe" -p 5432 -d gps\_tracking\_db -U postgres -h localhost
```

Note that the path to *shp2pgsql.exe* and *psql.exe* (in this case
*C:\\Program Files\\PostgreSQL\\9.5\\bin)* can be different according
to the folder where you installed your version of PostgreSQL. If you
connect to the database remotely, you also have to change the address
of the server (*-h* option). In the parameters, set the reference
system (option -s) and create a spatial index for the new table
(option *-I*). The result of *shp2pgsql* is a text file with the SQL
that generates and populates the table
*env\_data.meteo\_stations*. With the symbol '|' you 'pipe' (send
directly) the SQL to the database (through the PostgreSQL interactive
terminal
[psql](http://www.postgresql.org/docs/devel/static/app-psql.html))
where it is automatically executed. You have to set the the port
(*-p*), the name of the database (*-d*), the user (*-U*) and the
password, if requested. In this way, you complete the whole process
with a single command. You can refer to *shp2pgsql* documentation for
more details. You might have to add the whole path to *psql* and
*shp2pgsql*. This depends on the folder where you installed
PostgreSQL. You can easily verify the path searching for these two
files. You also have to check that the path of your shapefile
(*meteo\_stations.shp*) is properly defined. You can repeat the same
operation for the study area layer:

```
> "C:\\Program Files\\PostgreSQL\\9.5\\bin\\shp2pgsql.exe" -s 4326 -I C:\\tracking\_db\\data\\env\_data\\vector\\study\_area.shp env\_data.study\_area | "C:\\Program Files\\PostgreSQL\\9.5\\bin\\psql.exe" -p 5432 -d gps\_tracking\_db -U postgres -h localhost
```

Next for the roads layer:

```
> "C:\\Program Files\\PostgreSQL\\9.5\\bin\\shp2pgsql.exe" -s 4326 -I C:\\tracking\_db\\data\\env\_data\\vector\\roads.shp env\_data.roads | "C:\\Program Files\\PostgreSQL\\9.5\\bin\\psql.exe" -p 5432 -d gps\_tracking\_db -U postgres -h localhost
```

And for the administrative boundaries:

```
> "C:\\Program Files\\PostgreSQL\\9.5\\bin\\shp2pgsql.exe" -s 4326 -I C:\\tracking\_db\\data\\env\_data\\vector\\adm\_boundaries.shp env\_data.adm\_boundaries | "C:\\Program Files\\PostgreSQL\\9.5\\bin\\psql.exe" -p 5432 -d gps\_tracking\_db -U postgres -h localhost
```

Now the shapefiles are in the database as new tables (one table for
each shapefile). You can visualize them through a GIS interface
(e.g. QGIS). You can also retrieve a summary of the information from
all vector layers available in the database with the following
command:

```sql
SELECT * FROM geometry_columns;
```

The primary method to import a raster layer is the command-line tool
[raster2pgsql](http://postgis.net/docs/using_raster_dataman.html), the
equivalent of shp2pgsql but for raster files, that converts
GDAL-supported rasters into SQL suitable for loading into PostGIS. It
is also capable of loading folders of raster
files. [GDAL](http://www.gdal.org/) (Geospatial Data Abstraction
Library) is a (free) library for reading, writing and processing
raster geospatial data formats. It has a lot of simple but very
powerful and fast command-line tools for raster data translation and
processing. The related OGR library provides a similar capability for
simple vector data features. GDAL is used by most of the spatial
open-source tools and by a large number of commercial software
programs as well. You will probably benefit in particular from the
tools *gdalinfo* (get a layer's basic metadata), *gdal\_translate*
(change data format, change data type, cut), gdalwarp1 (mosaicing,
reprojection and warping utility).

An interesting feature of *raster2pgsql* is its capability to store
the rasters inside the database (in-db) or keep them as (out-db) files
in the file system (with the raster2pgsql -R option). In the last
case, only raster metadata are stored in the database, not pixel
values themselves. Loading out-db rasters metadata is much faster than
loading them completely in the database. Most operations at the pixel
values level (e.g. \*ST\_SummaryStats\*) will have equivalent
performance with out- and in-db rasters. Other functions, like
*ST\_Tile*, involving only the metadata, will be faster with out-db
rasters. Another advantage of out-db rasters is that they stay
accessible for external applications unable to query databases (with
SQL). However, the administrator must make sure that the link between
what is in the db (the path to the raster file in the file system) is
not broken (e.g. by moving or renaming the files). On the other hand,
only in-db rasters can be generated with CREATE TABLE and modified
with UPDATE statements. Which is the best choice depends on the size
of the data set and on considerations about performance and database
management. A good practice is generally to load very large raster
data sets as out-db and to load smaller ones as in-db to save time on
loading and to avoid repeatedly backing up huge, static rasters.

The QGIS plugin *Load Raster to PostGIS* can also be used to import
raster data with a graphical interface. An important parameter to set
when importing raster layers is the number of tiles (*-t*
option). Tiles are small subsets of the image and correspond to a
physical record in the table. This approach dramatically decreases the
time required to retrieve information. The recommended values for the
tile option range from 20x20 to 100x100. Here is the code (to be run
in the Command Prompt) to transform a raster (the digital elevation
model derived from SRTM) into the SQL code that is then used to
physically load the raster into the database (as you did with
*shp2pgsql* for vectors):

```
> "C:\\Program Files\\PostgreSQL\\9.5\\bin\\raster2pgsql.exe" -I -M -C -s 4326 -t 20x20 C:\\tracking\_db\\data\\env\_data\\raster\\srtm\_dem.tif env\_data.srtm\_dem | "C:\\Program Files\\PostgreSQL\\9.5\\bin\\psql.exe" -p 5432 -d gps\_tracking\_db -U postgres -h localhost
```

If you copy-paste the copy from an Internet browser, some character
(e.g. double quotes and 'x') might be transformed into different
character and you might have to manually fix this problem). You can
repeat the same process on the land cover layer:

```
> "C:\\Program Files\\PostgreSQL\\9.5\\bin\\raster2pgsql.exe" -I -M -C -s 3035 C:\\tracking\_db\\data\\env\_data\\raster\\corine06.tif -t 20x20 env\_data.corine\_land\_cover | "C:\\Program Files\\PostgreSQL\\9.5\\bin\\psql.exe" -p 5432 -d gps\_tracking\_db -U postgres -h localhost
```

The reference system of the Corine Land Cover data set is not
geographic coordinates (SRID 4326), but ETRS89/ETRS-LAEA (SRID 3035),
an equal-area projection over Europe. This must be specified with the
-s option and kept in mind when this layer will be connected to other
spatial layers stored in a different reference system. As with
shp2pgsql.exe, the -I option will create a spatial index on the loaded
tiles, speeding up many spatial operations, and the*-C* option will
generate a set of constraints on the table, allowing it to be
correctly listed in the *raster\_columns* metadata table. The land
cover raster identifies classes that are labeled by a code (an
integer). To specify the meaning of the codes, you can add a table
where they are described. In this example, the land cover layer is
taken from the Corine project. Classes are described by a hierarchical
legend over three nested levels. The legend is provided in the test
data set in the file *corine\_legend.csv*. You import the table of the
legend (first creating an empty table, and then loading the data):

```sql
CREATE TABLE env_data.corine_land_cover_legend(
  grid_code integer NOT NULL,
  clc_l3_code character(3),
  label1 character varying,
  label2 character varying,
  label3 character varying,
  CONSTRAINT corine_land_cover_legend_pkey 
    PRIMARY KEY (grid_code ));
```

```sql
COMMENT ON TABLE env_data.corine_land_cover_legend
IS 'Legend of Corine land cover, associating the numeric code to the three nested levels.';
```

Then you load the data:

```sql
COPY env_data.corine_land_cover_legend 
FROM 
  'C:\tracking_db\data\env_data\raster\corine_legend.csv' 
  WITH (FORMAT csv, HEADER, DELIMITER ';');
```

You can retrieve a summary of the information from all raster layers
available in the database with the following command:

```sql
SELECT * FROM raster_columns;
```

To keep a well-documented database, add comments to describe all the
spatial layers that you have added:

```sql
COMMENT ON TABLE env_data.adm_boundaries 
IS 'Layer (polygons) of administrative boundaries (comuni).';
```

```sql
COMMENT ON TABLE env_data.corine_land_cover 
IS 'Layer (raster) of land cover (from Corine project).';
```

```sql
COMMENT ON TABLE env_data.meteo_stations 
IS 'Layer (points) of meteo stations.';
```

```sql
COMMENT ON TABLE env_data.roads 
IS 'Layer (lines) of roads network.';
```

```sql
COMMENT ON TABLE env_data.srtm_dem 
IS 'Layer (raster) of digital elevation model (from SRTM project).';
```

```sql
COMMENT ON TABLE env_data.study_area 
IS 'Layer (polygons) of the boundaries of the study area.';
```

### Exercise

1.  Load the roads network layer in QGIS, edit it adding some
    additional roads (using OpenStreetMap or GoogleEarth as reference,
    save edits and export as a shapefile.


## Topic 2. Querying spatial environmental data


### Introduction

As the set of ancillary (spatial) information is now loaded into the
database, you can start playing with this information using spatial
SQL queries. In fact, it is possible with spatial SQL to run queries
that explicitly handle the spatial relationships among the different
spatial tables that you have stored in the database. In the following
examples, SQL statements will show you how to take advantage of
PostGIS features to manage, explore and analyze spatial objects, with
optimized performances and no need for specific GIS interfaces.


### Example

You start playing with your spatial data by asking for the name of the
administrative unit (*comune*, Italian commune) in which the point at
coordinates (11, 46) (longitude, latitude) is located. There are two
commands that are used when it comes to intersection of spatial
elements: *ST\_Intersects* and *ST\_Intersection*. The former returns
true if two features intersect, while the latter returns the geometry
produced by the intersection of the objects. In this case,
*ST\_Intersects* is used to select the right comune:

```sql
SELECT 
  nome_com
FROM 
  env_data.adm_boundaries 
WHERE 
  ST_Intersects((ST_SetSRID(ST_MakePoint(11,46), 4326)), geom);
```

The result is *Cavedine*.

In the second example, you compute the distance (rounded to the meter)
from the point at coordinates (11, 46) to all the meteorological
stations (ordered by distance) in the table
*env\_data.meteo\_stations*. This information could be used, for
example, to derive the precipitation and temperature for a GPS
position at the given acquisition time, weighting the measurement from
each station according to the distance to the point. In this case,
*ST\_Distance\_Spheroid* is used. Alternatively, you could use
*ST\_Distance* and cast your geometries as *geography* data types.

```sql
SELECT 
  station_id, ST_Distance_Spheroid((ST_SetSRID(ST_MakePoint(11,46), 4326)), geom, 'SPHEROID["WGS 84",6378137,298.257223563]')::integer AS distance
FROM 
  env_data.meteo_stations
ORDER BY 
  distance;
```

The result is:

| station\_id | distance |
|-------------|----------|
| 1           | 2224     |
| 2           | 4080     |
| 5           | 4569     |
| 4           | 10085    |
| 3           | 10374    |
| 6           | 18755    |

In the third example, you compute the distance to the closest road:

```sql
SELECT 
  ST_Distance((ST_SetSRID(ST_MakePoint(11,46), 4326))::geography, geom::geography)::integer AS distance
FROM 
  env_data.roads
ORDER BY 
  distance 
LIMIT 1;
```

The result is *1560*.

For users, the data type (vector, raster) used to store spatial
information is not so relevant when they query their data: queries
should transparently use any kind of spatial data as input. Users can
then focus on the environmental model instead of worrying about the
data model. In the next example, you intersect a point with two raster
layers (altitude and land cover) in the same way you do for vector
layers. In the case of land cover, the point must first be projected
into the Corine reference system (SRID 3035). In the raster layer,
just the Corine code class (integer) is stored while the legend is
stored in the table *env\_data.corine\_land\_cover\_legend*. In the
query, the code class is joined to the legend table and the code
description is returned. This is an example of integration of both
spatial and non-spatial elements in the same query.

```sql
SELECT 
  ST_Value(srtm_dem.rast,
  (ST_SetSRID(ST_MakePoint(11,46), 4326))) AS altitude,
  ST_value(corine_land_cover.rast,
  ST_transform((ST_SetSRID(ST_MakePoint(11,46), 4326)), 3035)) AS land_cover, 
  label2, 
  label3
FROM 
  env_data.corine_land_cover, 
  env_data.srtm_dem, 
  env_data.corine_land_cover_legend
WHERE 
  ST_Intersects(
    corine_land_cover.rast,
    ST_Transform((ST_SetSRID(ST_MakePoint(11,46), 4326)), 3035)) AND
  ST_Intersects(srtm_dem.rast,(ST_SetSRID(ST_MakePoint(11,46), 4326))) AND
  grid_code = ST_Value(
    corine_land_cover.rast,
    ST_Transform((ST_SetSRID(ST_MakePoint(11,46), 4326)), 3035));
```

The result is:

| altitude | land\_cover | label2  | label3            |
|----------|-------------|---------|-------------------|
| 956      | 24          | Forests | Coniferous forest |

Now combine roads and administrative boundaries to compute how many
meters of roads there are in each administrative unit. You first have
to intersect the two layers (*ST\_Intersection*), then compute the
length (*ST\_Length*) and summarize per administrative unit (sum()
associated with GROUP BY clause).

```sql
SELECT 
  nome_com, 
  sum(ST_Length(
    (ST_Intersection(roads.geom, adm_boundaries.geom))::geography))::integer AS total_length
FROM 
  env_data.roads, 
  env_data.adm_boundaries 
WHERE 
  ST_Intersects(roads.geom, adm_boundaries.geom)
GROUP BY 
  nome_com 
ORDER BY 
  total_length desc;
```

The result of the query is:

| nome\_com     | total\_length |
|---------------|---------------|
| Trento        | 24552         |
| Lasino        | 15298         |
| Garniga Terme | 12653         |
| Calavino      | 6185          |
| Cavedine      | 5802          |
| Cimone        | 5142          |
| Padergnone    | 4510          |
| Vezzano       | 1618          |
| Aldeno        | 1367          |

The last examples are about the interaction between rasters and
polygons. In this case, we compute some statistics (minimum, maximum,
mean, and standard deviation) for the altitude within the study area:

```sql
SELECT 
  (sum(ST_Area(((gv).geom)::geography)))/1000000 area,
  min((gv).val) alt_min, 
  max((gv).val) alt_max,
  avg((gv).val) alt_avg,
  stddev((gv).val) alt_stddev
FROM
  (SELECT 
    ST_intersection(rast, geom) AS gv
  FROM 
    env_data.srtm_dem,
    env_data.study_area 
  WHERE 
    ST_intersects(rast, geom)
) foo;
```

The result, from which it is possible to appreciate the large
variability of altitude across the study area, is:

| area             | alt\_min | alt\_max | alt\_avg         | alt\_stddev     |
|------------------|----------|----------|------------------|-----------------|
| 199.018552456188 | 180      | 2133     | 879.286157704969 | 422.56622698974 |

You might also be interested in the number of pixels of each land
cover type within the study area. As with the previous example, we
first intersect the study area with the raster of interest, but in
this case we need to reproject the study area polygon into the
coordinate system of the Corine land cover raster (SRID: 3035). With
the following query, you can see the dominance of mixed forests in the
study area:

```sql
SELECT (pvc).value, SUM((pvc).count) AS total, label3
FROM 
  (SELECT ST_ValueCount(rast) AS pvc
  FROM env_data.corine_land_cover, env_data.study_area
  WHERE ST_Intersects(rast, ST_Transform(geom, 3035))) AS cnts, 
  env_data.corine_land_cover_legend
WHERE grid_code = (pvc).value
GROUP BY (pvc).value, label3
ORDER BY (pvc).value;
```

The result is:

| lc\_class | total | label3                                       |
|-----------|-------|----------------------------------------------|
| 1         | 114   | Continuous urban fabric                      |
| 2         | 817   | Discontinuous urban fabric                   |
| 3         | 324   | Industrial or commercial units               |
| 7         | 125   | Mineral extraction sites                     |
| 16        | 324   | Fruit trees and berry plantations            |
| 18        | 760   | Pastures                                     |
| 19        | 237   | Annual crops associated with permanent crops |
| 20        | 1967  | Complex cultivation patterns                 |
| 21        | 2700  | Land principally occupied by agriculture     |
| 23        | 4473  | Broad-leaved forest                          |
| 24        | 2867  | Coniferous forest                            |
| 25        | 8762  | Mixed forest                                 |
| 26        | 600   | Natural grasslands                           |
| 27        | 586   | Moors and heathland                          |
| 29        | 1524  | Transitional woodland-shrub                  |
| 31        | 188   | Bare rocks                                   |
| 32        | 611   | Sparsely vegetated areas                     |
| 41        | 221   | Water bodies                                 |

The previous query can be modified to return the percentage of each
class over the total number of pixels. This can be achieved using
[window functions](http://www.postgresql.org/docs/devel/static/tutorial-window.html)
(which are a valuable tool in many applications and worth to be
learnt):

```sql
SELECT 
  (pvc).value, 
  (SUM((pvc).count)*100/
    SUM(SUM((pvc).count)) over ()
  )::numeric(4,2) AS total_perc, label3
FROM 
  (SELECT ST_ValueCount(rast) AS pvc
  FROM env_data.corine_land_cover, env_data.study_area
  WHERE ST_Intersects(rast, ST_Transform(geom, 3035))) AS cnts, 
  env_data.corine_land_cover_legend
WHERE grid_code = (pvc).value
GROUP BY (pvc).value, label3
ORDER BY (pvc).value;
```

The result is:

| value | total\_perc | label3                                       |
|-------|-------------|----------------------------------------------|
| 1     | 0.42        | Continuous urban fabric                      |
| 2     | 3.00        | Discontinuous urban fabric                   |
| 3     | 1.19        | Industrial or commercial units               |
| 7     | 0.46        | Mineral extraction sites                     |
| 16    | 1.19        | Fruit trees and berry plantations            |
| 18    | 2.79        | Pastures                                     |
| 19    | 0.87        | Annual crops associated with permanent crops |
| 20    | 7.23        | Complex cultivation patterns                 |
| 21    | 9.93        | Land principally occupied by agriculture     |
| 23    | 16.44       | Broad-leaved forest                          |
| 24    | 10.54       | Coniferous forest                            |
| 25    | 32.21       | Mixed forest                                 |
| 26    | 2.21        | Natural grasslands                           |
| 27    | 2.15        | Moors and heathland                          |
| 29    | 5.60        | Transitional woodland-shrub                  |
| 31    | 0.69        | Bare rocks                                   |
| 32    | 2.25        | Sparsely vegetated areas                     |
| 41    | 0.81        | Water bodies                                 |


### Exercise

1.  What is the administrative unit where each meteo station is
    located?
2.  What is the land cover class where each meteo station is located?


## Summary exercise of Lesson 7

1.  What is the distance of each GPS position to the closest road?
2.  What is the proportion of GPS locations in each land cover class
    used by all animals?



% Lesson 8. How to extract environmental information related to location data
% 8 June 2016


The association of GPS position with environmental attributes can be
part of the preliminary processing before data analysis where a set of
procedures is created to intersect ancillary layers with GPS
positions. Database tools like triggers and functions can be used for
this scope. The result is that positions are transformed from a simple
pair of numbers (coordinates) to complex multi-dimensional (spatial)
objects that define the individual and its habitat in time and space,
including their interactions and dependencies. In an additional step,
position data can also be joined to activity data to define an even
more complete picture of the animal's behavior. Once this is
implemented in the database framework, scientists and wildlife
managers can deal with data in the same way they model the object of
their study as they can start their analyses from objects that
represent the animals in their habitat (which previously was the
result of a long and complex process). Moreover, users can directly
query these objects using a simple and powerful language (SQL) that is
close to their natural language. All these elements strengthen the
opportunity provided by GPS data to move from mainly testing
statistical hypotheses to focusing on biological
hypotheses. Scientists can store, access, and manipulate their data in
a simple and quick way, which allows them to formulate biological
questions that previously were almost impossible to answer for
technical reasons. In this lesson, GPS data and ancillary information
are connected with automated procedures. In an extra section, an
example is illustrated to manage time series of environmental layers
that can introduce temporal variability in habitat conditions.


## Topic 1. Associate environmental characteristics with GPS locations


### Introduction

The goal of this exercise is to automatically transform position data
from simple points to objects holding information about the habitat
and conditions where the animals were located at a certain moment in
time. We will use the points to automatically extract, by the mean of
a SQL trigger, this information from other ecological layers.


### Exercise

The first step is to add the new fields of information into
the *main.gps\_data\_animals* table. We will add columns for the name
of the administrative unit to which the GPS position belongs, the code
for the land cover it is located in, the altitude from the digital
elevation model (which can then be used as the third dimension of the
point), the id of the closest meteorological station, and the distance
to the closest road:

```sql
ALTER TABLE main.gps_data_animals 
  ADD COLUMN pro_com integer;
```

```sql
ALTER TABLE main.gps_data_animals 
  ADD COLUMN corine_land_cover_code integer;
```

```sql
ALTER TABLE main.gps_data_animals 
  ADD COLUMN altitude_srtm integer;
```

```sql
ALTER TABLE main.gps_data_animals 
  ADD COLUMN station_id integer;
```

```sql
ALTER TABLE main.gps_data_animals 
  ADD COLUMN roads_dist integer;
```

These are several common examples of environmental information that
can be associated with GPS positions, and others can be implemented
according to specific needs. It is important to keep in mind that
these spatial relationships are implicitly determined by the
coordinates of the elements involved; you do not necessarily have to
store these values in a table as you can compute them on the fly
whenever you need. Moreover, you might need different information
according to the specific study (e.g. the land cover composition in an
area of one kilometre around each GPS position instead of the value of
the pixel where the point is located). Computing these spatial
relationships on the fly can require significant time, so in some
cases it is preferable to run the query just once and permanently
store the most relevant parameters for your specific study (think
about what you will most likely use often). Another advantage of
making the relations explicit within tables is that you can then
create indexes on columns of these tables. This is not possible with
on-the-fly sub-queries. Making many small queries and hence creating
many tables and indexing them along the way is generally more
efficient in terms of processing time then trying to do everything in
a long and complex query. This is not necessarily true when the data
set is small enough, as indexes are mostly efficient on large
tables. Sometimes, the time necessary to write many SQL statements and
the associated indexes exceed the time necessary to execute them. In
that case, it might be more efficient to write a single, long, and
complex statement and forget about the indexes. This does not apply to
the following trigger function, as all the ecological layers were well
indexed at load time and it does not rely on intermediate sub-queries
of those layers. Now you use spatial SQL to populate the new columns
in the main *gps\_data\_animals* table. You start uploading the code
of the *comune* (table *env\_data.adm\_boundaries*) where each GPS
position is located (simple intersection point-polygon):

```sql
UPDATE
 main.gps_data_animals
SET
 pro_com = adm_boundaries.pro_com
FROM 
 env_data.adm_boundaries 
WHERE 
 ST_Intersects(gps_data_animals.geom,adm_boundaries.geom);
```

Now you calculate and update the land cover class for each GPS
position from the Corine Land Cover layer (which is stored in the
*3035* spatial reference system, therefore a reprojection with
*ST\_Transform* is required in order to have both layers in the same
referenec system):

```sql
UPDATE 
 main.gps_data_animals
SET
 corine_land_cover_code = ST_Value(rast,ST_Transform(geom,3035)) 
FROM 
 env_data.corine_land_cover 
WHERE 
 ST_Intersects(ST_Transform(geom,3035), rast);
```

You intersect GPS locations with the digital elevation model (raster)
to obtain the altitude of each point:

```sql
UPDATE 
 main.gps_data_animals
SET
 altitude_srtm = ST_Value(rast,geom) 
FROM 
 env_data.srtm_dem 
WHERE 
 ST_Intersects(geom, rast);
```

To identify the closest meteorological stations to each GPS locations,
you have to calculate the distance from locations to all the stations,
order by the distance and then limit the result to the first record:

```sql
UPDATE 
 main.gps_data_animals
SET
 station_id = 
 (SELECT 
 meteo_stations.station_id::integer 
 FROM 
 env_data.meteo_stations
 ORDER BY 
 ST_Distance_Spheroid(meteo_stations.geom, geom, 'SPHEROID["WGS 84",6378137,298.257223563]') 
 LIMIT 1)
WHERE
 gps_data_animals.geom IS NOT NULL;
```

The final column that you have to update is the distance to the
closest road:

```sql
UPDATE 
 main.gps_data_animals
SET
 roads_dist =
 (SELECT 
 ST_Distance(geom::geography, roads.geom::geography)::integer 
 FROM 
 env_data.roads 
 ORDER BY 
 ST_distance(geom::geography, roads.geom::geography) 
 LIMIT 1)
WHERE
 gps_data_animals.geom IS NOT NULL;
```

The next step is to implement the computation of these parameters
inside the automated process of associating GPS positions with animals
(from *gps\_data* to*gps\_data\_animals*). To achieve this goal, you
have to modify the trigger function
*tools.new\_gps\_data\_animals*. In fact, the function
*tools.new\_gps\_data\_animals* is activated whenever a new location
is inserted into *gps\_data\_animals* (from*gps\_data*). It adds new
information (i.e. fills additional fields) to the incoming record
(e.g. creates the geometry object from latitude and longitude values)
before it is uploaded into the *gps\_data\_animals* table (in the
code, NEW. Is used to reference the new record not yet inserted). The
SQL code that does this is below. The drawback of this function is
that it will slow down the import of a large set of positions at once
(e.g. millions or more), but it has no practical impact when you
manage a continuous data flow from sensors, even for a large number of
sensors deployed at the same time.

```sql
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
```

```sql
COMMENT ON FUNCTION tools.new_gps_data_animals() 
IS 'When called by the trigger insert_gps_positions (raised whenever a new position is uploaded into gps_data_animals) this function gets the longitude and latitude values and sets the geometry field accordingly, computing a set of derived environmental information calculated intersecting or relating the position with the environmental ancillary layers.';
```

As the trigger function is run during location import, the function
only works on the locations that are imported after it was created,
and not on previously imported locations. To see the effects, you have
to add new positions or delete and reload the GPS position stored in
*gps\_data\_animals*. You can do this by saving the records in
*gps\_sensors\_animals* in an external .csv file, and then deleting
the records from the table (which also deletes the records in
*gps\_data\_animals* in a cascading effect). When you reload them, the
new function will be activated by the trigger that was just defined,
and the new attributes will be calculated. You can perform these steps
with the following commands. First, check how many records you have
per animal:

```sql
SELECT animals_id, count(animals_id) 
FROM main.gps_data_animals 
GROUP BY animals_id;
```

The result is:

| animals\_id | count |
|-------------|-------|
| 4           | 2869  |
| 5           | 2924  |
| 2           | 2624  |
| 1           | 2114  |
| 3           | 2106  |

Then, copy of the table *main.gps\_sensors\_animals* into an external
file.

```sql
COPY 
  (SELECT animals_id, gps_sensors_id, start_time, end_time, notes 
FROM main.gps_sensors_animals)
TO 
  'c:/tracking_db/test/gps_sensors_animals.csv' 
  WITH (FORMAT csv, DELIMITER ';');
```

You then delete all the records in *main.gps\_sensors\_animals*, which
will delete (in a cascade) all the records
in*main.gps\_data\_animals*.

```sql
DELETE FROM main.gps_sensors_animals;
```

You can verify that there are now no records are in
*main.gps\_data\_animals* (the query should return 0 rows).

```sql
SELECT * FROM main.gps_data_animals;
```

The final step is to reload the .csv file into
*main.gps\_sensors\_animals*. This will launch the trigger functions
that recreate all the records in *main.gps\_data\_animals*, in which
the fields related to environmental attributes are also automatically
updated. Note that, due to the different triggers which imply massive
computations, the query can take several minutes to execute (you can
skip this step and speed up the process by simply calculating the
environmental attributes with an update query).

```sql
COPY main.gps_sensors_animals 
  (animals_id, gps_sensors_id, start_time, end_time, notes) 
FROM 
  'c:/tracking_db/test/gps_sensors_animals.csv' 
  WITH (FORMAT csv, DELIMITER ';');
```

You can verify that all the fields were updated:

```sql
SELECT 
  gps_data_animals_id AS id, acquisition_time, pro_com, corine_land_cover_code AS lc_code, altitude_srtm AS alt, station_id AS meteo, roads_dist AS dist
FROM 
  main.gps_data_animals 
WHERE 
  geom IS NOT NULL
LIMIT 5;
```

The result is:

| id    | acquisition\_time      | pro\_com | lc\_code | alt  | meteo | dist |
|-------|------------------------|----------|----------|------|-------|------|
| 15275 | 2005-10-23 22:00:53+02 | 22091    | 18       | 1536 | 5     | 812  |
| 15276 | 2005-10-24 02:00:55+02 | 22091    | 18       | 1519 | 5     | 740  |
| 15277 | 2005-10-24 06:00:55+02 | 22091    | 18       | 1531 | 5     | 598  |
| 15280 | 2005-10-24 18:02:57+02 | 22091    | 23       | 1198 | 5     | 586  |
| 15281 | 2005-10-24 22:01:49+02 | 22091    | 25       | 1480 | 5     | 319  |

You can also check that all the records of every animal are in
*main.gps\_data\_animals*:

```sql
SELECT animals_id, count(*) FROM main.gps_data_animals GROUP BY animals_id;
```

The result is:

| animals\_id | count |
|-------------|-------|
| 4           | 2869  |
| 5           | 2924  |
| 2           | 2624  |
| 1           | 2114  |
| 3           | 2106  |

As you can see, the whole process can take a few minutes, as you are
calculating the environmental attributes for the whole data set at
once. As discussed in the previous chapters, the use of triggers and
indexes to automatize data flow and speed up analyses might imply
processing times that are not sustainable when large data sets are
imported at once. In this case, it might be preferable to update
environmental attributes and calculate indexes in a later stage to
speed up the import process. In this book, we assume that in the
operational environment where the database is developed, the data flow
is continuous, with large but still limited data sets imported at
intervals. You can compare this processing time with what is generally
required to achieve the same result in a classic GIS environment based
on flat files (e.g. shapefiles, .tif). Do not forget to consider that
you can use these minutes for a coffee break while the database does
the job for you, instead of clicking here and there in your favorite
GIS application!


### Exercise

1.  Retrieve the average altitude per month/year of all animals,
    ordered per animal, year and month and verify if there is any
    temporal pattern


## Supplementary code: Tracking animals in a dynamic environment with remote sensing image time series

The advancement in movement ecology from a data perspective can reach
its full potential only by combining the technology of animal tracking
with the technology of other environmental sensing programmes. Ecology
is fundamentally spatial, and animal ecology is obviously no
exception. Any scientific question in animal ecology cannot overlook
its spatial dimension, and in particular the dynamic interaction
between individual animals or populations, and the environment in
which the ecological processes occur. Movement provides the
mechanistic link to explain this complex ecosystem interaction, as the
movement path is dynamically determined by external factors, through
their effect on the individual's state and the life-history
characteristics of an animal. Therefore, most modelling approaches for
animal movement include environmental factors as explanatory
variables. This technically implies the intersection of animal
locations with environmental layers, in order to extract the
information about the environment that is embedded in spatial
coordinates. It appears very clear at this stage, though, that animal
locations are not only spatial, but are fully defined by spatial and
temporal coordinates (as given by the acquisition time). Logically,
the same temporal definition also applies to environmental
layers. Some characteristics of the landscape, such as land cover or
road networks, can be considered static over a large period of time
(on the order of several years), and these static environmental layers
are commonly intersected with animal locations to infer habitat use
and selection by animals. However, many characteristics actually
relevant to wildlife, such as vegetation biomass or road traffic, are
indeed subject to temporal variability (on the order of hours to
weeks) in the landscape, and would be better represented by dynamic
layers that correspond closely to the conditions actually encountered
by an animal moving across the landscape. In this case, using static
environmental layers directly limits the potential of
wildlife-tracking data, reduces the power of inference of statistical
models, and sometimes even introduces sources of bias. Nowadays,
satellite-based remote sensing can provide dynamic global coverage of
medium-resolution images that can be used to compute a large number of
environmental parameters very useful to wildlife studies. Through
remote sensing, it is possible to acquire spatial time series which
can then be linked to animal locations, fully exploiting the
spatio-temporal nature of wildlife tracking data. Numerous satellite
and other sensor networks can now provide information on resources on
a monthly, weekly or even daily basis, which can be used as
explanatory variables in statistical models or to parametrize bayesian
inferences or mechanistic models. The first set of environmental data
which was made available as a time series was the Normalized
Difference Vegetation Index (NDVI), but other examples include data
sets on snow, ocean primary productivity, surface temperature, or
salinity. Snow cover, NDVI, and sea surface temperature are some
examples of indexes that can be used as explanatory variables in
statistical models or to parametrize bayesian inferences or
mechanistic models. The main shortcoming of such remote-sensing layers
is the relatively low spatial resolution, which does not fit the
current average bias of wildlife-tracking GPS locations (less than 20
m), thus potentially leading to a spatial mismatch between the
animal-based information and the environmental layers (note that the
resolution can still be perfectly fine, depending on the overall
spatial variability and the species and biological process under
study). Yet, this is much more desirable than using static layers when
the temporal variability is an essential component of the ecological
inference. Higher-resolution images and new types of information
(e.g. forest structure) are presently provided by new types of
sensors, such as those from lidar, radar, or hyper-spectral
remote-sensing technology and the new Sentinel 2 (optical data). The
new generation of satellites will probably require dedicated storage
and analysis tools (e.g. Goggle Earth Engine) that can be related to
the Big Data framework. Here, we discuss the integration in the
spatial database of one of the most used indexes for ecological
productivity and phenology, i.e. NDVI, derived from MODIS images. The
intersection of NDVI images with GPS locations requires a system that
is able to handle large amounts of data and explicitly manage both
spatial and temporal dimensions, which makes PostGIS an ideal
candidate for the task.

The MODIS (Moderate Resolution Imaging Spectroradiometer) instrument
operates on the NASA's Terra and Aqua spacecraft. The instrument views
the entire earth surface every 1 to 2 days, captures data in 36
spectral bands ranging in wavelength from 0.4 μm to 14.4 μm and at
varying spatial resolutions (250 m, 500 m and 1 km). The Global MODIS
vegetation indices (code MOD13Q1) are designed to provide consistent
spatial and temporal comparisons of vegetation conditions. Red and
near-infrared reflectances, centred at 645 nm and 858 nm,
respectively, are used to determine the daily vegetation indices,
including the well known NDVI. This index is calculated by contrasting
intense chlorophyll pigment absorption in the red against the high
reflectance of leaf mesophyll in the near infrared. It is a proxy of
plant photosynthetic activity and has been found to be highly related
to green leaf area index (LAI) and to the fraction of
photosynthetically active radiation absorbed by vegetation
(FAPAR). Past studies have demonstrated the potential of using NDVI
data to study vegetation dynamics. More recently, several applications
have been developed using MODIS NDVI data such as land-cover change
detection, monitoring forest phenophases, modelling wheat yield, and
other applications in forest and agricultural sciences. However, the
utility of the MODIS NDVI data products is limited by the availability
of high-quality data (e.g. cloud-free), and several processing steps
are required before using the data: acquisition via web facilities,
re-projection from the native sinusoidal projection to a standard
latitude-longitude format, eventually the mosaicking of two or more
tiles into a single tile. A number of processing techniques to
'smooth' the data and obtain a cleaned (no clouds) time series of NDVI
imagery have also been implemented. These kind of processes are
usually based on a set of ancillary information on the data quality of
each pixel that are provided together with MODIS NDVI. In the
framework of the present project, NDVI data over the study area have
been acquired from
[Boku University Portal](http://ivfl-info.boku.ac.at/index.php/eo-data-processing)
as weekly smoothed data. In the next figure you can see an example of
non smoothed and smoothed temporal profile.

[![ndvi-profile](images/l8/ndvi-profile-800.png)](images/l8/ndvi-profile.png)

Raster time series are quite common from medium- and low-resolution
data sets generated by satellites that record information at the same
location on Earth at regular time intervals. In this case, each pixel
has both a spatial and a temporal reference. In this exercise you
integrate an NDVI data set of MODIS images covering the period
2005-2008 (spatial resolution of 1 km and temporal resolution of 7
days divided in 4 tiles). In this example, you will use the*env\_data*
schema to store raster time series, in order to keep it transparent to
the user: all environmental data (static or dynamic) is in this
schema. However, over larger amounts of data, it might be useful to
store raster time series in a different schema (e.g. *env\_data\_ts*,
where *ts* stands for time series) to support an easier and more
efficient back-up procedure. When you import a raster image using
*raster2pgsql*, a new record is added in the target table for each
raster, including one for each tile if the raster was tiled. At this
point, each record does not consider time yet, and is thus simply a
spatial object. To transform each record into a spatio-temporal
object, you must add a field with the timestamp of the data
acquisition, or, better, the time range covered by the data if it is
related to a period. The time associated with each raster (and each
tile) can usually be derived from the name of the file, where this
information is typically embedded. In the case of MODIS composite over
16 days, this is the first day of the 7-day period associated with the
image in the form
*MCD13Q1.**AyyyyDDD**.005.250m\_7\_days\_NDVI.REFMIDw.tif* (where
*yyyy* is the year and *DDD* the day of the year (from 1 to 365). This
image is the result of a clip on a mosaic of 4 images derived from the
Boku's grid tiles. Note also that values are scale, i.e. converted to
1 byte (in a scale 0-250) using the formula:

```
> NDVI Value = 0.0048 \* Digital value – 0.2
```

Values between 25 and 255 are used to identify not valid data.

With this data type, you can now associate each image or tile with the
correct time reference, that is, the 7-day period associated with each
raster. This will make the spatio-temporal intersection with GPS
positions possible by allowing direct comparisons with GPS
timestamps. To start, create an empty table to store the NDVI images,
including a field for the temporal reference (of type *date*), and its
index:

```sql
CREATE TABLE env_data.ndvi_modis(
  rid serial NOT NULL, 
  rast raster, 
  filename text,
  acquisition_date date,
  CONSTRAINT ndvi_modis_pkey
    PRIMARY KEY (rid));
```

```sql
CREATE INDEX ndvi_modis_wkb_rast_idx 
  ON env_data.ndvi_modis 
  USING GIST (ST_ConvexHull(rast));
```

```sql
COMMENT ON TABLE env_data.ndvi_modis
IS 'Table that stores values of smoothed MODIS NDVI (7-day periods).';
```

Now the trick is to use two arguments of the *raster2pgsql* command
*-F* to include the raster file name as a column of the table (which
will then be used by the trigger function), and *-a* to append the
data to an existing table, instead of creating a new one. You can
import all of them in a single operation using the wildcard character
'\*' in the input filename. You can thus run the following command in
the Command Prompt (warning: you might need to adjust the rasters'
path according to your own setup):

```
> C:\Program Files\PostgreSQL\9.5\bin\raster2pgsql.exe -a -C -F -M -s 4326 -t 40x40 C:\David\postgis_workshop_2016\files\tracking_db\data\env_data\raster\raster_ts\*.tif env_data.ndvi_modis | C:\Program Files\PostgreSQL\9.5\bin\psql.exe -p 5432 -d gps_tracking_db -U postgres
```

Each raster file embeds the acquisition period in its filename. For
instance, `MCD13Q1.A2005003.005.250m_7_days_NDVI.REFMIDw.tif` is
associated with the 3rd day of 2005 (3rd January). As you can see, the
period is encoded on 10 characters following the common prefix
`MCD13Q1.A`. This allows you to use the
[to\_date](http://www.postgresql.org/docs/devel/static/functions-formatting.html)
function to extract the date from the filename (which was
automatically stored in the *filename* field during the import). For
instance, you can extract the starting date from the first raster
imported:

```sql
SELECT 
    filename, 
    to_date(substring(filename FROM 10 FOR 7) , 'YYYYDDD') AS date
FROM env_data.ndvi_modis
LIMIT 1;
```

| filename                                             | date       |
|------------------------------------------------------|------------|
| MCD13Q1.A2005003.005.250m\_7\_days\_NDVI.REFMIDw.tif | 2005-01-03 |

In the case of more complex filenames with a variable number of
characters, you could retrieve the encoded date using the *substring*
function, by extracting the relevant characters relative to some other
characters found first using the *position* function. Let's now update
the table by converting the filenames into the date ranges according
to the convention used in file naming:

```sql
UPDATE env_data.ndvi_modis
SET acquisition_date = to_date(substring(filename FROM 10 FOR 7) , 'YYYYDDD');
```

As for any type of column, if the table contains a large number of
rows (e.g. &gt; 10,000), querying based on the *acquisition\_date* will
be faster if you first index it (you can do it even if the table is
not that big, as the PostgreSQL planer will determine whether the
query will be faster by using the index or not):

```sql
CREATE INDEX ndvi_modis_acquisition_date_idx 
ON env_data.ndvi_modis (acquisition_date);
```

Now each tile (and therefore each pixel) has a spatial and a temporal
component and thus can be queried according to both criteria. Based on
this, you can now create a trigger and its associated function to
automatically create the appropriate date during the NDVI data import
(for future NDVI images). Note that the
*ndvi\_acquisition\_date\_update* function will be activated before a
NDVI tile is loaded, so that the transaction is aborted if, for any
reason, the *acquisition\_date* can not be computed, and only valid
rows are inserted into the *ndvi\_modis* table:

```sql
CREATE OR REPLACE FUNCTION tools.ndvi_acquisition_date_update()
RETURNS trigger AS
$BODY$
BEGIN
  NEW.acquisition_date = to_date(substring(new.filename FROM 10 FOR 7) , 'YYYYDDD');
RETURN NEW;
END;
$BODY$
LANGUAGE plpgsql VOLATILE
COST 100;
```

```sql
COMMENT ON FUNCTION tools.ndvi_acquisition_date_update() 
IS 'This function is raised whenever a new record is inserted into the MODIS NDVI time series table in order to define the date range. The acquisition_range value is derived from the original filename.';
```

```sql
CREATE TRIGGER update_ndvi_acquisition_range
BEFORE INSERT ON env_data.ndvi_modis
  FOR EACH ROW EXECUTE PROCEDURE tools.ndvi_acquisition_date_update();
```

Every time you add new NDVI rasters, the *acquisition\_date* will then
be updated appropriately.

To intersect a GPS position with this kind of data set, both temporal
and spatial criteria must be defined. In the next example, you
retrieve the MODIS NDVI value at point (11, 46) using the *ST\_Value*
PostGIS SQL function, and for the whole year 2005:

```sql
SELECT 
  rid,
  acquisition_date,
  ST_Value(rast, ST_SetSRID(ST_MakePoint(11.1, 46.1), 4326)) * 0.0048 -0.2
    AS ndvi
FROM env_data.ndvi_modis
WHERE ST_Intersects(ST_SetSRID(ST_MakePoint(11.1, 46.1), 4326), rast) AND
  EXTRACT(year FROM acquisition_date) = 2005
ORDER BY acquisition_date;
```

The result gives you the complete NDVI profile at this location for
the year 2005. You can now retrieve NDVI values at coordinates from
real animals. Data at a given day can be derived interpolating the
previous and next NDVI images (the time series is smoothed, and also
given the low temporal variability of NDVI, you can assume that in a
week the value change linearly).

```sql
SELECT 
  gps_data_animals_id, 
  (trunc((st_value(pre.rast, geom) * (date_trunc('week', acquisition_time::date + 7)::date -acquisition_time::date)::integer +
st_value(post.rast, geom) * (acquisition_time::date - date_trunc('week', acquisition_time::date)::date))::integer/7)) * 0.0048 -0.2
FROM  
  main.gps_data_animals, 
  env_data.ndvi_modis pre,
  env_data.ndvi_modis post
WHERE
  st_intersects(geom, pre.rast) AND 
  st_intersects(geom, post.rast) AND 
  date_trunc('week', acquisition_time::date)::date = pre.acquisition_date and 
  date_trunc('week', acquisition_time::date + 7)::date = post.acquisition_date
LIMIT 10;
```

You can now create a new field to permanently store the NDVI value in
the *gps\_data\_animals* table:

```sql
ALTER TABLE main.gps_data_animals 
ADD COLUMN ndvi_modis double precision;
```

Now, let's update the value of this column:

```sql
UPDATE 
    main.gps_data_animals
SET 
    ndvi_modis = (trunc((st_value(pre.rast, geom) * (date_trunc('week', acquisition_time::date + 7)::date -acquisition_time::date)::integer +
st_value(post.rast, geom) * (acquisition_time::date - date_trunc('week', acquisition_time::date)::date))::integer/7)) * 0.0048 - 0.2
FROM  
    env_data.ndvi_modis pre,
    env_data.ndvi_modis post 
WHERE
    geom IS NOT NULL AND
    st_intersects(geom, pre.rast) AND 
    st_intersects(geom, post.rast) AND 
    date_trunc('week', acquisition_time::date)::date = pre.acquisition_date AND 
    date_trunc('week', acquisition_time::date + 7)::date = post.acquisition_date;
```

If you want, now you can try to use triggers to automate the process
as you did with other environmental variables, extending the trigger
function *new\_gps\_data\_animals*.


## Summary exercise of Lesson 8

1.  Is the average altitude higher for males or females?
2.  What is the average monthly NDVI for each animal?



% Lesson 9. Data quality: how to detect and manage outliers
% 8 June 2016


Tracking data can potentially be affected by a large set of errors in
different steps of data acquisition and processing, involving
malfunctioning or dis-performance of the sensor device that may affect
measurement, acquisition and recording; dis-performance of
transmission hardware or lack of transmission network or physical
conditions; errors in data handling and processing. Erroneous location
data can substantially affect analysis related to ecological or
conservation questions, thus leading to biased inference and
misleading wildlife management/conservation indications. Nature of
localization error is variable, but whatever the source and type of
errors, they have to be taken into account. Indeed, data quality
assessment is a key step in data management. In this lesson we
especially deal with biased locations, or wrong locations.

While in some cases incorrect data are evident, in many situations it
is not possible to clearly identify locations as outliers because
although they are suspicious (e.g. long distances covered by animals
in a short time or repeated extreme values), they might still be
correct, leaving a margin of uncertainty. For example, it is evident
from the figure below that there are at least three points (red dots)
of the GPS data set with clearly incorrect coordinates.

![outliers](images/l9/outliers.png)

On the other side, the definition of outliers depends on how you
define 'outlier' which can depend on the specific analysis. Here you
will focus on impossible locations that are clearly caused by
errors. In the exercise presented in this chapter, different potential
errors are identified. A general approach to managing outliers is
proposed that tag records rather than deleting them. According to this
approach, practical methods to find and mark errors are
illustrated. The following are some of the main errors that can
potentially affect data acquired from GPS sensors:

1.  Missing records. This means that no information (not even the
    acquisition time) has been received from the sensor, although it
    was planned by the acquisition schedule.
2.  Records with missing coordinates. In this case, there is a GPS
    failure probably due to bad GPS coverage or canopy closure. In
    this case the information on acquisition time is still valid, even
    if no coordinates are provided. This correspond to 'fix rate'
    error (see special topic).
3.  Multiple records with the same acquisition time. This has no
    physical meaning and is a clear error. The main problem here is to
    decide which record (if any) is correct.
4.  Records that contain different values when acquired using
    different data transfer procedures (e.g. direct download from the
    sensor through a cable vs. data transmission through the GSM
    network).
5.  Records erroneously attributed to an animal because of inexact
    deployment information. This case is frequent and is usually due
    to an imprecise definition of the deployment time range of the
    sensor on the animal. A typical result are locations in the
    scientist's office first followed by a trajectory along the road
    to the point of capture.

Below, the type of errors that can be classified as GPS location bias,
i.e. due to a malfunctioning of the GPS sensor that leads to locations
with low accuracy:

1.  Records located outside the study area. In this case coordinates
    are incorrect (probably due to malfunctioning of the GPS sensor)
    and outliers appear very far from the other (valid)
    locations. This is a special case of impossible movements where
    the erroneous location is detected even with a simple visual
    exploration. This can be considered an 'extreme case' of location
    bias, in terms of accuracy (see special topic).
2.  Records located in impossible places. This might include
    (depending on species) sea, lakes, or otherwise inaccessible
    places. Again, the error can be attributed to GPS sensor bias.
3.  Records that imply impossible movements (e.g. very long
    displacements, requiring movement at a speed impossible for the
    species). In this case some assumptions on the movement model must
    be done (e.g. maximum speed).
4.  Records that imply improbable movements. In this case, although
    the movement is physically possible according to the threshold
    defined, the likelihood of the movement is so low that it raises
    serious doubt about its reliability. Once the location is tagged
    as suspicious, analysts can decide whether should be considered in
    specific analyses.

GPS sensors usually record other ancillary information that can vary
according to vendors and models. Detection of errors in the
acquisition of this attributes is not treated here. Examples are the
number of satellites used to estimate the position, the dilution of
precision (DOP), the temperatures as measured by the sensor associated
with the GPS, and the altitude estimated by the GPS. Temperature is
measured close to the body of the animal, while altitude is not
measured on the geoid but as the distance from the center of the
Earth, thus in both cases the measure is affected by large errors.

A source of uncertainty associated with GPS data is the positioning
error of the sensor. GPS error can be classified as bias (i.e. average
distance between the 'true location' and the estimated location, where
the average value represents the accuracy while the measure of
dispersion of repeated measures represents the precision) and fix
rate, or the proportion of expected fixes (i.e. those expected
according to the schedule of positioning that is programmed on the GPS
unit) compared to the number of fixes actually obtained. Both these
types of errors are related to several factors, including collar
brand, orientation, fix interval (e.g. cold/warm or hot start), and
topography and canopy closure. Unfortunately, the relationship between
animals and the latter two factors is the subject of a fundamental
branch of spatial ecology habitat selection studies. In extreme
synthesis, habitat selection models establish a relationship between
the habitat used by animals(estimated by acquired locations)
vs. available proportion of habitat (e.g., random locations throughout
study area or home range). Therefore, a habitat-biased proportion of
fixes due to instrumental error may hamper the inferential powers of
habitat selection models. A series of solutions have been
proposed. Among others, a robust methodology is the use of spatial
predictive models for the probability of GPS acquisition, usually
based on dedicated local tests, the so called Pfix. Data can then be
weighted by the inverse of Pfix, so that positions taken in
difficult-to-estimate locations are weighted more. In general, it is
extremely important to account for GPS bias, especially in resource
selection models.


## Topic 1. A general approach to the management of erroneous locations


### Introduction

Once erroneous records are detected, the suggested approach is to keep
a copy of all the information as it comes from the sensors
(in *gps\_data* table), and then mark records affected by each of the
possible errors using different tags in the table where locations are
associated with animals (*gps\_data\_animals*). Records should never
be deleted from the data set even when they are completely wrong, for
the following reasons:

- If you detect errors with automatic procedures, it is always a good
  idea to be able to manually check the results to be sure that the
  method performed as expected, which is not possible if you delete
  the records. For example, records with missing coordinates are
  important to determine the fix rate error and therefore models to
  account for this errors.
- If you delete a record, whenever you have to re-synchronize your
  data set with the original source, you will reintroduce the outlier,
  particularly for erroneous locations that cannot be automatically
  detected.
- A record can have some values that are wrong (e.g. coordinates), but
  others that are valid and useful (e.g. timestamp).
- The fact that the record is an outlier is valuable information that
  you do not want to lose (e.g. you might want to know the success
  rate of the sensor according to the different types of errors).
- It is important to differentiate missing locations (no data from
  sensor) from data that were received but erroneous for another
  reason (incorrect coordinates). The difference between these two
  types of error is substantial.
- It is often difficult to determine unequivocally that a record is
  wrong, because this decision is related to assumptions about the
  species' biology. If all original data are kept, criteria to
  identify outliers can be changed at any time.
- What looks useless in most cases (e.g. records without coordinates)
  might be very useful in other studies that were not planned when
  data were acquired and screened.
- Repeated erroneous data is a fairly reliable clue that a sensor is
  not working properly, and you might use this information to decide
  whether and when to replace it.


### Example

In the following examples, you will explore the location data set
hunting for possible errors. First, you will create a field in the GPS
data table where you can store a tag associated with each erroneous or
suspicious record. Then you will define a list of codes, one for each
possible type of error. In general, a preliminary visual exploration
of the spatial distribution of the entire set of locations can be
useful for detecting the general spatial patterns of the animals'
movements and evident outlier locations. To tag locations as errors or
unreliable data, you first create a new field
(*sensor\_validity\_code*) in the *gps\_data\_animals* table. At the
same time, a list of codes corresponding to all possible errors must
be created using a look-up table *gps\_validity*, linked to the
*sensor\_validity\_code* field with a foreign key. When an outlier
detection process identifies an error, the record is marked with the
corresponding tag code. In the analytical stage, users can decide to
exclude all or part of the records tagged as erroneous. The evident
errors (e.g. points outside the study area) can be automatically
marked in the import procedure, while some other detection algorithms
are better run by users when required because they imply a long
processing time or might need a fine tuning of the parameters. First,
add the new field to the table:

```sql
ALTER TABLE main.gps_data_animals 
  ADD COLUMN gps_validity_code integer;
```

Now create a table to store the validity codes, create the external
key, and insert the admitted values:

```sql
CREATE TABLE lu_tables.lu_gps_validity(
  gps_validity_code integer,
  gps_validity_description character varying,
  CONSTRAINT lu_gps_validity_pkey 
    PRIMARY KEY (gps_validity_code));
COMMENT ON TABLE lu_tables.lu_gps_validity
IS 'Look up table for GPS positions validity codes.';
```

```sql
ALTER TABLE main.gps_data_animals
  ADD CONSTRAINT animals_lu_gps_validity 
  FOREIGN KEY (gps_validity_code)
  REFERENCES lu_tables.lu_gps_validity (gps_validity_code)
  MATCH SIMPLE ON UPDATE NO ACTION ON DELETE NO ACTION;
```

```sql
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
```

For the example, let's insert a new animal (with outliers), called 'test':

```sql
INSERT INTO main.animals 
  (animals_id, animals_code, name, sex, age_class_code, species_code, note) 
  VALUES (6, 'test', 'test-ina', 'm', 3, 1, 'This is a fake animal, used to test outliers detection processes.');
```

Its sensor is called 'GSM\_test':

```sql
INSERT INTO main.gps_sensors 
  (gps_sensors_id, gps_sensors_code, purchase_date, frequency, vendor, model, sim) 
  VALUES (6, 'GSM_test', '2005-01-01', 1000, 'Lotek', 'top', '+391441414');
```

Wa also insert the time interval of the deployment of the test sensor
on the test animal:

```sql
INSERT INTO main.gps_sensors_animals 
  (animals_id, gps_sensors_id, start_time, end_time, notes)
  VALUES (6, 6, '2005-04-04 08:00:00+02', '2005-05-06 02:00:00+02', 'test deployment');
```

And finally  import the data set from the `.csv` file:

```sql
COPY main.gps_data(
  gps_sensors_code, line_no, utc_date, utc_time, lmt_date, lmt_time, ecef_x, ecef_y, ecef_z, latitude, longitude, height, dop, nav, validated, sats_used, ch01_sat_id, ch01_sat_cnr, ch02_sat_id, ch02_sat_cnr, ch03_sat_id, ch03_sat_cnr, ch04_sat_id, ch04_sat_cnr, ch05_sat_id, ch05_sat_cnr, ch06_sat_id, ch06_sat_cnr, ch07_sat_id, ch07_sat_cnr, ch08_sat_id, ch08_sat_cnr, ch09_sat_id, ch09_sat_cnr, ch10_sat_id, ch10_sat_cnr, ch11_sat_id, ch11_sat_cnr, ch12_sat_id, ch12_sat_cnr, main_vol, bu_vol, temp, easting, northing, remarks)
FROM
  'C:\tracking_db\data\sensors_data\GSM_test.csv' 
    WITH (FORMAT csv, HEADER, DELIMITER ';');
```

Now you can proceed with outlier detection. You can start by assuming
that all the GPS positions are correct:

```sql
UPDATE main.gps_data_animals 
  SET gps_validity_code = 1;
```


## Topic 2. Detect and mark erroneous data


### Introduction

In this topic, you can see an example of how each kind of error can be
detected with SQL and marked in the *gps\_data\_animals* table.


### Example

You might have a missing record when the device was programmed to
acquire the position but no information (not even the acquisition
time) is recorded. In this case, you can use specific functions to
create 'virtual' records and, if needed, compute and interpolate
values for the coordinates. The 'virtual' records should be created
just in the analytical stage and not stored in the reference data set
(table *gps\_data\_animals*).

When the GPS is unable to receive sufficient satellite signal, the
record has no coordinates associated. The rate of GPS failure can vary
substantially, mainly according to sensor quality, terrain morphology,
and vegetation cover. Missing coordinates cannot be managed as
location bias, but have to be properly treated in the analytical stage
depending on the specific objective, since they result in erroneous
'fix rate'. Technically, they can be excluded from the data set, or an
estimated value can be calculated by interpolating the previous and
next GPS positions. This is a very important issue, since several
analytical methods require regular time intervals. Note that with no
longitude/latitude, the spatial attribute (i.e. the *geom* field)
cannot be created, which makes it easy to identify this type of
error. You can mark all the GPS positions with no coordinates with the
code 0:

```sql
UPDATE main.gps_data_animals 
  SET gps_validity_code = 0 
  WHERE geom IS NULL;
```

In some (rare) cases, you might have a repeated acquisition time (from
the same acquisition source). You can detect these errors by grouping
your data set by animal and acquisition time and asking for multiple
occurrences. Here is an example of an SQL query to get this result:

```sql
SELECT 
  x.gps_data_animals_id, x.animals_id, x.acquisition_time 
FROM 
  main.gps_data_animals x, 
  (SELECT animals_id, acquisition_time 
  FROM main.gps_data_animals
  WHERE gps_validity_code = 1
  GROUP BY animals_id, acquisition_time
  HAVING count(animals_id) > 1) a 
WHERE 
  a.animals_id = x.animals_id AND 
  a.acquisition_time = x.acquisition_time 
ORDER BY 
  x.animals_id, x.acquisition_time;
```

This query returns the id of the records with duplicated timestamps
(*HAVING count(animals\_id) &gt; 1*). In this case, you have no data
affected by this error. In case there are records with this problem,
the data manager has to decide what to do. You can keep one of the two
(or more) GPS positions with repeated acquisition time, or tag both
(all) as unreliable. The first possibility would imply a detailed
inspection of the locations at fault, in order to possibly identify
(with no guarantee of success) which one is correct. On the other
hand, the second case is more conservative and can be automated as the
user does not have to take any decision that could lead to erroneous
conclusions. Removing data (or tagging them as erroneous) is often not
so much a problem with GPS data sets, since you probably have
thousands of locations anyway. On the other hand, keeping incorrect
data could be much more of a problem and bias further
analyses. However, suspicious locations, if correct, might be exactly
the information needed for a specific analysis (e.g. rutting
excursions). As for the other type of errors, a specific
*gps\_validity\_code* is suggested. Here is an example (that will not
affect your database as no timestamp is duplicated):

```sql
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
```

It may happen that data are obtained from sensors through different
data transfer processes. A typical example is data received in near
real time through a GSM network and later downloaded directly via
cable from the sensor when it is physically removed from the
animal. If the information is different, it probably means that an
error occurred during data transmission. In this case, it is necessary
to define a hierarchy of reliability for the different sources
(e.g. data obtained via cable download are better than those obtained
via the GSM network). This information should be stored when data are
imported into the database into *gps\_data* table. Then, when valid
data are to be identified, the 'best' code should be selected, paying
attention to properly synchronize *gps\_data* and
*gps\_data\_animals*. Which specific tools will be used to manage
different acquisition sources largely depends on the number of
sensors, frequency of updates, and desired level of automation of the
process. No specific examples are provided here.

Records erroneously attributed to animals usually occurs for the first
and/or last GPS positions because the start and end date and time of
the sensor deployment is not correct. The consequence is that the
movements of the sensor before and after the deployment are attributed
to the animal. It may be difficult to trap this error with automatic
methods because incorrect records can be organized in spatial clusters
with a (theoretically) meaningful pattern (the set of erroneous GPS
positions has a high degree of spatial autocorrelation as it contains
'real' GPS positions of 'real' movements, although they are not
animal's movements). It is important to stress that this kind of
pattern, e.g. GPS positions repeated in a small area where the sensor
is stored before the deployment (researcher's office) and then a long
movement to where the sensor is deployed on the animal, can closely
resemble the sequence of GPS positions for animals just released in a
new area. To identify this type of error, the suggested approach is to
visually explore the data set in a GIS desktop interface. Once you
detect this situation, you should check the source of information on
the date of capture and sensor deployment and, if needed, correct the
information in the table *gps\_sensors\_animals* (this will
automatically update the table *gps\_data\_animals*). In general, a
visual exploration of your GPS data sets, using as representation both
points and trajectories, is always useful to help identify unusual
spatial patterns. For this kind of error no *gps\_validity\_code* are
used because, once detected, they are automatically excluded from the
table *gps\_data\_animals*. The best method to avoid this type of
error is to get accurate and complete information about the deployment
of the sensors on the animals, for example verifying not just the
starting and ending date, but also the time of the day and time
zone. Special attention must be paid to the end of the deployment. For
active deployments, no end is defined. In this case, the procedure can
make use of the function now() to define a dynamic upper limit when
checking the timestamp of recorded locations (i.e. the record is not
valid if *acquisition\_time &gt; now()*).

The next types of error can all be connected to GPS sensor
malfunctioning or dis-performance, leading to biased locations with
low accuracy, or a true wrong location, i.e. coordinates which are
distant or very distant from the 'true location'.

When the error of coordinates is due to reasons not related to general
GPS accuracy (which will almost always be within a few dozen meters),
the incorrect positions are often quite evident as they are usually
very far from the others (a typical example is the inversion of
longitude and latitude). At the same time, this error is random, so
erroneous GPS positions are hardly grouped in spatial clusters. When a
study area has defined limits (e.g. fencing or natural boundaries),
the simplest way to identify incorrect GPS positions is to run a query
that looks for those that are located outside these boundaries
(optionally, with an extra buffer area). If animals have no
constraints to their movements, but they are still limited to a
specific area (e.g. an island), you can delineate a very large
boundary so that at least GPS positions very far outside this area are
captured. In this case it is better to be conservative and enlarge the
study area as much as possible to exclude all the valid GPS
positions. Other, more fine-tuned methods can be used at a later stage
to detect the remaining erroneous GPS positions. This approach has the
risk of tagging correct locations if the boundaries are not properly
set, as the criteria are very subjective. It is important to note that
erroneous locations will be removed in any case as impossible
movements (see next sections). This step can be useful in cases where
you don't have access to movement properties (e.g. VHF data with only
one location a week). Another element to keep in mind, especially in
the case of automatic procedures to be run in real time on the data
flow, is that very complex geometries (e.g. a coastline drawn at high
spatial resolution) can slow down the intersection queries. In this
case, you can exploit the power of spatial indexes and/or simplify
your geometry, which can be done using the PostGIS commands
[ST\_Simplify](http://www.postgis.org/docs/ST_Simplify.html) and
[ST\_SimplifyPreserveTopology](http://www.postgis.org/docs/ST_SimplifyPreserveTopology.html)). Here
is an example of an SQL query that detects outliers outside the
boundaries of the *study\_area* layer, returning the IDs of outlying
records:

```sql
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
```

The result is the list of the three GPS positions that fall outside
the study area.

The same query could be made using *ST\_Disjoint*, i.e. the opposite
of *ST\_Intersects* (note, however, that the former does not work on
multiple polygons). Here is an example where a small buffer
(*ST\_Buffer*) is added (using
[Common Table Expressions](http://www.postgresql.org/docs/9.2/static/queries-with.html)):

```sql
WITH area_buffer_simplified AS 
  (SELECT 
    ST_Simplify(
      ST_Buffer(study_area.geom, 0.1), 0.1) AS geom 
  FROM 
    env_data.study_area)
SELECT 
  animals_id, gps_data_animals_id 
FROM 
  main.gps_data_animals 
WHERE 
  ST_Disjoint(
    gps_data_animals.geom, 
    (SELECT geom FROM area_buffer_simplified));
```

The use of the syntax with *WITH* is optional, but in some cases can
be a useful way to simplify your queries, and it might be interesting
for you to know how it works.

This GPS position deserves a more accurate analysis to determine
whether it is really an outlier. Now tag the other five GPS positions
as erroneous (validity code 11, i.e. *Position wrong: out of the study
area*):

```sql
UPDATE main.gps_data_animals 
  SET gps_validity_code = 11 
  WHERE 
    gps_data_animals_id in 
    (SELECT gps_data_animals_id 
    FROM main.gps_data_animals, env_data.study_area 
    WHERE ST_Disjoint(
      gps_data_animals.geom,
      ST_Simplify(ST_Buffer(study_area.geom, 0.1), 0.1)));
```

Using a simpler approach, another quick way to detect these errors is
to order GPS positions according to their longitude and latitude
coordinates. The outliers are immediately visible as their values are
completely different from the others and they pop up at the beginning
of the list. An example of this kind of query is:

```sql
SELECT 
  gps_data_animals_id, ST_X(geom) 
FROM 
  main.gps_data_animals 
WHERE 
  geom IS NOT NULL 
ORDER BY 
  ST_X(geom) 
LIMIT 10;
```

The resulting data set is limited to 10 records, as just a few GPS
positions are expected to be affected by this type of error. The same
query can then be repeated in reverse order, and then doing the same
for latitude:

```sql
SELECT gps_data_animals_id, ST_X(geom) 
FROM main.gps_data_animals 
WHERE geom IS NOT NULL 
ORDER BY ST_X(geom) DESC 
LIMIT 10;
```

```sql
SELECT gps_data_animals_id, ST_Y(geom) 
FROM main.gps_data_animals 
WHERE geom IS NOT NULL 
ORDER BY ST_Y(geom) 
LIMIT 10;
```

```sql
SELECT gps_data_animals_id, ST_Y(geom) 
FROM main.gps_data_animals 
WHERE geom IS NOT NULL 
ORDER BY ST_Y(geom) DESC 
LIMIT 10;
```

When there are areas not accessible to animals because of physical
constraints (e.g. fencing, natural barriers) or environments not
compatible with the studied species (lakes and sea, or land, according
to the species), you can detect GPS positions that are located in
those areas where it is impossible for the animal to be. Therefore,
the decision whether to mark or not the locations as incorrect is
based on ecological assumptions (i.e., non-habitat). In this example,
you mark, using validity code '13', all the GPS positions that fall
inside a water body according to Corine land cover layer (Corine codes
'40', '41', '42', '43', '44'):

```sql
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
```

For this kind of control, you must also consider also that the result
depends on the accuracy of the land cover layer and of the GPS
positions. Thus, at a minimum, a further visual check in a GIS
environment is recommended.


## Topic 3. Update of spatial views to exclude erroneous locations


### Introduction

As a consequence of the outlier tagging approach illustrated in these
pages, views based on the GPS positions data set should exclude the
incorrect points, adding a *gps\_validity\_code = 1* criteria
(corresponding to GPS positions with no errors and valid geometry) in
their WHERE conditions.


### Exercise

First, you update the view *analysis.view\_convex\_hulls*:

```sql
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
```

You do the same for *analysis.view\_gps\_locations*:

```sql
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
```

Now repeat the same operation for *analysis.view\_trajectories*:

```sql
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
```

If you visualize these layers in a GIS desktop, you can verify that
outliers are now excluded. An example for the MCP is illustrated in
the figure below.

![ch-correct](http://www.irsae.no/wp-content/uploads/2015/07/ch_correct.png)


## Supplementary code: Records that would imply impossible or improbable movements

To detect records with incorrect coordinates that cannot be identified
using clear boundaries, such as the study area or land cover type, a
more sophisticated outlier filtering procedure must be applied. To do
so, some kind of assumption about the animals' movement model has to
be made, for example a speed limit. It is important to remember that
animal movements can be modelled in different ways at different
temporal scales: an average speed that is impossible over a period of
four hours could be perfectly feasible for movements in a shorter time
(e.g. five minutes). Which algorithm to apply depends largely on the
species and the environment in which the animal is moving and the duty
cycle of the tag. In general, PostgreSQL window functions can help. A
[window function](http://www.postgresql.org/docs/devel/static/tutorial-window.html)
performs a calculation across a set of rows that are somehow related
to the current row. This is similar to an aggregate function, but
unlike regular aggregate functions, window functions do not group rows
into a single output row, hence they are still able to access more
than just the current row of the query result. In particular, it
enables you to access previous and next rows (according to a
user-defined ordering criteria) while calculating values for the
current row. This is very useful, as a tracking data set has a
predetermined temporal order, where many properties (e.g. geometric
parameters of the trajectory, such as turning angle and speed) involve
a sequence of GPS positions. It is important to remember that the
order of records in a database is irrelevant. The ordering criteria
must be set in the query that retrieves data.

In the next example, you will make use of window functions to convert
the series of locations into steps (i.e. the straight-line segment
connecting two successive locations), and compute geometric
characteristics of each step: the step length, the time interval, and
the speed as the ratio of the previous two. It is important to note
that while a step is the movement between two points, in many cases
its attributes are associated with the starting or the ending
point. In this book we use the ending point as reference. In some
software, particularly the
[adehabitat](http://cran.r-project.org/web/packages/adehabitat/index.html)
package for R, the step is associated with the starting point. If
needed, the queries and functions presented in this book can be
modified to follow this convention.

```sql
SELECT 
  animals_id AS id, 
  acquisition_time, 
  LEAD(acquisition_time,-1) 
    OVER (
      PARTITION BY animals_id 
      ORDER BY acquisition_time) AS acquisition_time_1,
  (EXTRACT(epoch FROM acquisition_time) - 
  LEAD(EXTRACT(epoch FROM acquisition_time), -1) 
    OVER (
      PARTITION BY animals_id 
      ORDER BY acquisition_time))::integer AS deltat,
  (ST_Distance_Spheroid(
    geom, 
    LEAD(geom, -1) 
      OVER (
        PARTITION BY animals_id 
        ORDER BY acquisition_time), 
    'SPHEROID["WGS 84",6378137,298.257223563]'))::integer AS dist,
  (ST_Distance_Spheroid(
    geom, 
    LEAD(geom, -1) 
      OVER (
        PARTITION BY animals_id 
        ORDER BY acquisition_time), 
    'SPHEROID["WGS 84",6378137,298.257223563]')/
  ((EXTRACT(epoch FROM acquisition_time) - 
  LEAD(
    EXTRACT(epoch FROM acquisition_time), -1) 
    OVER (
      PARTITION BY animals_id 
      ORDER BY acquisition_time))+1)*60*60)::numeric(8,2) AS speed
FROM main.gps_data_animals 
WHERE gps_validity_code = 1
LIMIT 5;
```

The result of this query is:

| id  | acquisition\_time      | acquisition\_time\_1   | deltat | dist | speed  |
|-----|------------------------|------------------------|--------|------|--------|
| 1   | 2005-10-18 22:00:54+02 |                        |        |      |        |
| 1   | 2005-10-19 02:01:23+02 | 2005-10-18 22:00:54+02 | 14429  | 97   | 24.15  |
| 1   | 2005-10-19 06:02:22+02 | 2005-10-19 02:01:23+02 | 14459  | 430  | 107.08 |
| 1   | 2005-10-19 10:03:08+02 | 2005-10-19 06:02:22+02 | 14446  | 218  | 54.40  |
| 1   | 2005-10-20 22:00:53+02 | 2005-10-19 10:03:08+02 | 129465 | 510  | 14.17  |

As a demonstration of a possible approach to detecting 'impossible
movements', here is an adapted function that implements the algorithm
presented in Bjorneraas et al. (2010). In the first step, you compute
the distance from each GPS position to the centroid of the previous
and next 10 GPS positions, and extract records that have values bigger
then a defined threshold (in this case, arbitrarily set to 10,000
meters):

```sql
SELECT gps_data_animals_id 
FROM 
  (SELECT 
    gps_data_animals_id, 
    ST_Distance_Spheroid(geom, 
      ST_setsrid(ST_makepoint(
        avg(ST_X(geom)) 
          OVER (
            PARTITION BY animals_id 
            ORDER BY acquisition_time rows 
              BETWEEN 10 PRECEDING and 10 FOLLOWING), 
        avg(ST_Y(geom)) 
          OVER (
            PARTITION BY animals_id 
            ORDER BY acquisition_time rows 
          BETWEEN 10 PRECEDING and 10 FOLLOWING)),
     4326),'SPHEROID["WGS 84",6378137,298.257223563]') AS dist_to_avg 
  FROM 
    main.gps_data_animals 
  WHERE 
    gps_validity_code = 1) a 
WHERE 
  dist_to_avg > 10000;
```

The result is the list of Ids, if any, of all the GPS positions that
match the defined conditions (and thus can be considered outliers).

This code can be improved in many ways. For example, it is possible to
consider the median instead of the average. It is also possible to
take into consideration that the first and last 10 GPS positions have
incomplete windows of 10+10 GPS positions. Moreover, this method works
fine for GPS positions at regular time intervals, but in the case of a
change in acquisition schedule might lead to unexpected results. In
these cases, you should create a query with a temporal window instead
of a fixed number of GPS positions. In the second step, the angle and
speed based on the previous and next GPS position is calculated (both
the previous and next location are used to determine whether the
location under consideration shows a spike in speed or turning angle),
and then GPS positions below the defined thresholds (in this case,
arbitrarily set as cosine of the relative angle &lt; -0.99 and speed
&gt; 2500 meters per hour) are extracted:

```sql
SELECT 
  gps_data_animals_id 
FROM 
  (SELECT gps_data_animals_id, 
  ST_Distance_Spheroid(
    geom, 
    LAG(geom, 1) OVER (PARTITION BY animals_id ORDER BY acquisition_time), 'SPHEROID["WGS 84",6378137,298.257223563]') /
    (EXTRACT(epoch FROM acquisition_time) - EXTRACT (epoch FROM (lag(acquisition_time, 1) OVER (PARTITION BY animals_id ORDER BY acquisition_time))))*3600 AS speed_FROM,
  ST_Distance_Spheroid(
    geom, 
    LEAD(geom, 1) OVER (PARTITION BY animals_id ORDER BY acquisition_time), 'SPHEROID["WGS 84",6378137,298.257223563]') /
    ( - EXTRACT(epoch FROM acquisition_time) + EXTRACT (epoch FROM (lead(acquisition_time, 1) OVER (PARTITION BY animals_id ORDER BY acquisition_time))))*3600 AS speed_to,
  cos(ST_Azimuth((
    LAG(geom, 1) OVER (PARTITION BY animals_id ORDER BY acquisition_time))::geography, 
    geom::geography) - 
  ST_Azimuth(
    geom::geography, 
    (LEAD(geom, 1) OVER (PARTITION BY animals_id ORDER BY acquisition_time))::geography)) AS rel_angle
  FROM main.gps_data_animals 
  WHERE gps_validity_code = 1) a 
WHERE 
  rel_angle < -0.99 AND 
  speed_from > 2500 AND 
  speed_to > 2500;
```

The result returns the list of IDs of all the GPS positions that match
the defined conditions. The same record detected in the previous query
is returned. These examples can be used as templates to create other
filtering procedures based on the temporal sequence of GPS positions
and the users' defined movement constraints. It is important to
remember that this kind of method is based on the analysis of the
sequence of GPS positions, and therefore results might change when new
GPS positions are uploaded. Moreover, it is not possible to run them
in real-time because the calculation requires a subsequent GPS
position. The result is that they have to be run in a specific
procedure unlinked with the (near) real-time import procedure. Now you
run this process on your data sets to mark the detected outliers
(validity code '12'):

```sql
UPDATE 
  main.gps_data_animals 
SET 
  gps_validity_code = 12 
WHERE 
  gps_data_animals_id in
    (SELECT gps_data_animals_id 
    FROM 
      (SELECT 
        gps_data_animals_id, 
        ST_Distance_Spheroid(geom, lag(geom, 1) OVER (PARTITION BY animals_id ORDER BY acquisition_time), 'SPHEROID["WGS 84",6378137,298.257223563]') /
        (EXTRACT(epoch FROM acquisition_time) - EXTRACT (epoch FROM (lag(acquisition_time, 1) OVER (PARTITION BY animals_id ORDER BY acquisition_time))))*3600 AS speed_from,
        ST_Distance_Spheroid(geom, lead(geom, 1) OVER (PARTITION BY animals_id order by acquisition_time), 'SPHEROID["WGS 84",6378137,298.257223563]') /
        ( - EXTRACT(epoch FROM acquisition_time) + EXTRACT (epoch FROM (lead(acquisition_time, 1) OVER (PARTITION BY animals_id ORDER BY acquisition_time))))*3600 AS speed_to,
        cos(ST_Azimuth((lag(geom, 1) OVER (PARTITION BY animals_id ORDER BY acquisition_time))::geography, geom::geography) - ST_Azimuth(geom::geography, (lead(geom, 1) OVER (PARTITION BY animals_id ORDER BY acquisition_time))::geography)) AS rel_angle
      FROM main.gps_data_animals 
      WHERE gps_validity_code = 1) a 
    WHERE 
      rel_angle < -0.99 AND 
      speed_from > 2500 AND 
      speed_to > 2500);
```

The case of records that would imply improbable movements is similar
to the previous type of error, but in this case the assumption made in
the animals' movement model cannot completely exclude that the GPS
position is correct (e.g. same methods as before, but with reduced
thresholds: cosine of the relative angle &lt; -0.98 and speed &gt; 300
meters per hour). These records should be kept as valid but marked
with a specific validity code that can permit users to exclude them
for analysis as appropriate.

```sql
UPDATE 
  main.gps_data_animals 
SET 
  gps_validity_code = 2 
WHERE 
  gps_data_animals_id IN 
    (SELECT gps_data_animals_id 
    FROM 
      (SELECT 
        gps_data_animals_id, 
        ST_Distance_Spheroid(geom, lag(geom, 1) OVER (PARTITION BY animals_id ORDER BY acquisition_time), 'SPHEROID["WGS 84",6378137,298.257223563]') /
        (EXTRACT(epoch FROM acquisition_time) - EXTRACT (epoch FROM (lag(acquisition_time, 1) OVER (PARTITION BY animals_id ORDER BY acquisition_time))))*3600 AS speed_FROM,
        ST_Distance_Spheroid(geom, lead(geom, 1) OVER (PARTITION BY animals_id order by acquisition_time), 'SPHEROID["WGS 84",6378137,298.257223563]') /
        ( - EXTRACT(epoch FROM acquisition_time) + EXTRACT (epoch FROM (lead(acquisition_time, 1) OVER (PARTITION BY animals_id ORDER BY acquisition_time))))*3600 AS speed_to,
        cos(ST_Azimuth((lag(geom, 1) OVER (PARTITION BY animals_id ORDER BY acquisition_time))::geography, geom::geography) - ST_Azimuth(geom::geography, (lead(geom, 1) OVER (PARTITION BY animals_id ORDER BY acquisition_time))::geography)) AS rel_angle
      FROM main.gps_data_animals 
      WHERE gps_validity_code = 1) a 
    WHERE 
      rel_angle < -0.98 AND 
      speed_from > 300 AND 
      speed_to > 300);
```

The marked GPS positions should then be inspected visually to decide
if they are valid with a direct expert evaluation.


## Supplementary code: Update import procedure with detection of erroneous positions

Some of the operations to filter outliers can be integrated into the
procedure that automatically uploads GPS positions into the table
*gps\_data\_animals*. In this example, you redefine the
*tools.new\_gps\_data\_animals()* function to tag GPS positions with
no coordinates (*gps\_validity\_code = 0*) and GPS positions outside
of the study area (*gps\_validity\_code = 11*) as soon as they are
imported into the database. All the others are set as valid
(*gps\_validity\_code = 1*).

```sql
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
  NEW.ndvi_modis = (SELECT ST_Value(rast, thegeom)FROM env_data_ts.ndvi_modis WHERE ST_Intersects(thegeom, rast) 
AND EXTRACT(year FROM acquisition_date) = EXTRACT(year FROM NEW.acquisition_time)
AND EXTRACT(month FROM acquisition_date) = EXTRACT(month FROM NEW.acquisition_time)
and EXTRACT(day FROM acquisition_date) = CASE
WHEN EXTRACT(day FROM NEW.acquisition_time) < 11 THEN 1
WHEN EXTRACT(day FROM NEW.acquisition_time) < 21 THEN 11
ELSE 21
END);
ELSE 
NEW.gps_validity_code = 0;
END IF;
RETURN NEW;
END;$BODY$
LANGUAGE plpgsql VOLATILE
COST 100;
ALTER FUNCTION tools.new_gps_data_animals()
OWNER TO postgres;
```

```sql
COMMENT ON FUNCTION tools.new_gps_data_animals() 
IS 'When called by the trigger insert_gps_locations (raised whenever a new GPS position is uploaded into gps_data_animals) this function gets the new longitude and latitude values and sets the field geom accordingly, computing a set of derived environmental information calculated intersection the GPS position with the environmental ancillary layers. GPS positions outside the study area are tagged as outliers.';
```

You can test the results by reloading the GPS positions into
*gps\_data\_animals* (for example modifying the*gps\_sensors\_animals*
table). If you do so, do not forget to re-run the GPS positions in
water detection, impossible spike detection, and duplicated
acquisition time detection, as they are not integrated in the
automated upload procedure.

Finally, delete the test animals records from *gps\_data\_animals* by
removing it's record from *gps\_sensors\_animals* (remember you
created a trigger and function to synchronize the two tables).

```sql
DELETE FROM main.gps_sensors_animals WHERE animals_id = 6;
```

Then you can also delete the animal and it's locations from *animals*
and *gps\_data*:

```sql
DELETE FROM main.animals WHERE animals_id = 6;
DELETE FROM main.gps_data WHERE gps_sensors_code = 'GSM_test';
```


% Lesson 10. From Movements to Steps: the movement model implementation
% 8 June 2016


Up to this point, we have worked with GPS locations from animal
tracking as points. In reality, the animal's movement can be more
accurately described as a trajectory (simply, the curve described by
the animal when it moves). Trajectories are made of a set of steps
(the link between successive points) which can be described by a
specific set of parameters (angles, distances, and times). The
relationships between these parameters, and the environment the animal
is moving through, can help us understand more about the animal's
movement. In this exercise, we will introduce the trajectory into the
database, calculate a base set of parameters for the steps, and
investigate how steps can be used with PostGIS functionality in the
database, by looking at their relationships with environmental data.


## Topic 1. Create a new trajectories table and populate it


### Introduction

In this section, we will set up a table to hold points that make up a
specific, defined trajectory, and the another table to store these
trajectories as steps (lines). We will go over a set of parameters
generally used to describe trajectory steps, and calculate these with
PostGIS functions in our new table.


### Example

The first step is to create a new table, which will hold a specific
set of points which we will process into a trajectory. We'll put it in
the 'analysis' schema, and call it *animal\_traj\_points*. A new
serial ID will hold a unique ID number for each point.
    
```sql
CREATE TABLE analysis.animal_traj_points(
	animal_traj_id serial,
	animals_id integer,
	burst integer,
	acquisition_time timestamp with time zone,
	geom geometry(POINT,4326));
COMMENT ON TABLE analysis.animal_traj_points IS 'Table that holds final set of points to be processed into trajectories.';

ALTER TABLE analysis.animal_traj_points ADD PRIMARY KEY (animal_traj_id);
```

This table will act as a storage for points that are processed in
specific ways (e.g., for a specific project). Steps generally used to
process point data include identifying 'incorrect' points, marking
'bursts' of data (a set of points gathered at the same acquisition
schedule, or a logically-defined set of points that will be processed
into one trajectory), regularizing the data acquisition schedule,
interpolating new points in 'time gaps' to fit this schedule. We will
cover these processes later in the week, but notice that we include a
'burst' column for identifying unique bursts. The next step is to
populate the table with data - We will work with a pre-defined set of
data here from animal \#4 and \#5. Note that this data is generally on
a 4-hour schedule, but it has not been processed, as we are taking
records (after 2006-02-19) directly from
*main.gps\_data\_animals*. These are thus irregular trajectories
(i.e., there are variable times lag between relocations).
    
```sql
INSERT INTO analysis.animal_traj_points(animals_id,acquisition_time,geom) 
    SELECT animals_id, acquisition_time, geom
    FROM main.gps_data_animals
    WHERE (animals_id = 4 AND acquisition_time > '2006-02-19')
    OR animals_id = 5
    AND gps_validity_code = 1
    ORDER BY animals_id,acquisition_time;
```

For this exercise, we will assume that each animal has one burst of
data, and set the burst column = 1. Bursts are subsets of the animal
trajectory that follow a pre-defined acquisition schedule, but they
also provide us the technical ability to logically group a set of
locations by 'stationary' animal movement modes (e.g. foraging,
migration, etc.).

```sql
UPDATE analysis.animal_traj_points SET
	burst = 1;
```

Lets load the dataset in QGIS using the *DB manager* tool. Instead of
loading the table directly, let's use the SQL Window to load the data
with a query. This will allow us to add a column 'time\_string' which
converts the timestamp field to a field that is readable with an
animation tool ("Time Manager").

```sql
SELECT animal_traj_id, animals_id, to_char(acquisition_time,'yyyy-mm-dd hh:mm:ss') AS time_string,geom
	FROM analysis.animal_traj_points
ORDER BY animals_id, animal_traj_id;
```

Now load the data set into the layers, with the 'roads' vector and
'srtm\_dem' raster as well. We'll install the plugin "Time Manager" in
QGIS and demonstrate how to animate the animal movement in the GIS.

Now that we have the points selected which we would like to process
into trajectories, we'll create a new table to hold our trajectory
steps. This table will take *animal\_traj\_id*, *animals\_id*, and
*burst* from the *animal\_traj\_points* table (so that the associated
point for the *animal\_traj\_id* is the *beginning* of the step). It
will also hold a set of descriptive parameters that have been
identified by Calenge et al. (2009) to characterize trajectory
steps. Finally, it will hold a LineString geometry (the steps).

```sql
CREATE TABLE analysis.animal_traj_steps(
	animal_traj_id integer,
	animals_id integer,
	burst integer,
	acquisition_time timestamp with time zone,
	d_x double precision,
	d_y double precision,
	dt_s integer,
	dist_m double precision,
	speed_m_ph double precision,
	r2n integer,
	absolute_angle double precision,
	relative_angle double precision,
	geom geometry(LINESTRING,4326));
COMMENT ON TABLE analysis.animal_traj_steps IS 'Table that stores animal trajectories as lines (steps).';
```

Let's populate some of the columns of the new table with data from the
*animal\_traj\_points* table. Note that we need to use PostgreSQL
*Window* functions (LEAD(), OVER() in combination with PARTITION BY
and ORDER BY to subset and arrange multiple rows from our source
table. This allows us to calculate the difference in time from one row
to the next, as well as access the start and end points for each of
the trajectory steps. In addition, we can use the first\_value()
window function to help calculate R2n, a parameter that needs to
access the first point of each burst for each animal.

```sql
INSERT INTO analysis.animal_traj_steps(animal_traj_id,animals_id,burst,acquisition_time,dt_s,r2n,geom)
	SELECT animal_traj_id,
	animals_id,
	burst,
	acquisition_time,
	(LEAD(EXTRACT(epoch FROM acquisition_time), 1) 
	OVER (PARTITION BY animals_id,burst ORDER BY acquisition_time)
	- (EXTRACT(epoch FROM acquisition_time)))::integer,
	((ST_Distance_Spheroid(geom,first_value(geom) OVER (PARTITION BY animals_id,burst ORDER BY acquisition_time),
	'SPHEROID["WGS 84",6378137,298.257223563]'))^2)::integer,
	ST_SetSRID(ST_MakeLine(geom,LEAD(geom, 1) 
	OVER (PARTITION BY animals_id,burst ORDER BY acquisition_time)),4326)
	FROM analysis.animal_traj_points
	WHERE burst IS NOT NULL and geom IS NOT NULL
	ORDER BY animals_id,animal_traj_id asc;
```

Now that we have created the geometries for *animal\_traj\_steps*,
let's load the layer into QGIS, and look more closely at just the
first 7 steps. Load the *animal\_traj\_steps* layer in QGIS from DB
Manager, and use the Feature Subset to only display steps 1-7
(*animal\_traj\_id* &lt;=7). The following figure displays the
parameters we would like to calculate - here we are focused on step
\#3.

![geom-param2](images/l10/geom-param2.png)

These parameters are often used in animal movement analysis, to help
fit movement models, to inform step-selection functions, and for
testing hypotheses about the animal's movement (e.g., is the animal's
movement more constrained than a correlated random walk?).


### Exercise

We have already populated the *dt\_s* and *geom* columns. For this
exercise, calculate the remaining rows (*d\_x*, *d\_y*, *dist\_m*,
*speed\_m\_ph*, *absolute\_angle*, *relative\_angle*) using UPDATE
statements. Hint \#1: You can use the PostGIS function
*ST\_StartPoint()* and *ST\_EndPoint()* to access the start and
endpoint of lines, respectively. Hint \#2:
ST\_Azimuth(startpoint,endpoint) calculates the north-based clockwise
angle (in radians) from startpoint to endpoint. The PostgreSQL
function degrees() can convert the radians to degrees, if desired. (We
leave the result in radians in this exercise).


### Exercise

After you table is fully populated, create a query to summarize animal
\#4's average speed by month. (Remember that the trajectory is not
regularized, so simply summarizing the *speed\_m\_ph* column will be
inaccurate - steps have different *d\_t* values.)


## Topic 2. Analyzing trajectory steps and environmental data relationships


### Introduction

One of the benefits of storing animal movement trajectories as a set
of linestrings in PostGIS is the ability to analyze a complete
trajectory of movement with environmental data sets. Lets begin be
analyzing trajectory steps with the roads layer in the database
(*env\_data.roads*). Load this dataset into QGIS, so we can visualize
some queries and results.


### Example (Roads)

Let's begin with a easy query - which steps intersect with roads? The
following query will select this steps using the *ST\_Intersects*
function. Note the use of SELECT DISTINCT ON (*animal\_traj\_id*),
which is useful in nearest-neighbor queries. For example, in this
query we only want to know if each step intersects with any road
(we're not concerned about multiple interesctions between a step and
road segments). Without the DISTINCT ON clause, the query would return
one line for every intersection between a step and any road segment.
    
```sql
SELECT DISTINCT ON (animal_traj_id) animal_traj_id as id,
	animals_id as ani,
	acquisition_time as acq_time,
	animal_traj_steps.geom as geom1
	FROM analysis.animal_traj_steps,env_data.roads
	WHERE ST_Intersects(animal_traj_steps.geom,roads.geom)
	ORDER BY id;
```

We can also use *ST\_DWithin()* to display trajectories that pass
within a certain distance of a road. For example, this query
summarizes the number of steps within 500m of any road at their
closest point, and averages the distance for those steps.

```sql
SELECT animal, count(id), avg(dist_to_road)::numeric(8,2) AS mean_distance_from_road FROM
	(SELECT DISTINCT ON (animal_traj_id) animal_traj_id as id,
		animals_id as animal,
		acquisition_time as acq_time,
		animal_traj_steps.geom as geom1,
	ST_Distance(animal_traj_steps.geom::geography,roads.geom::geography)::numeric as dist_to_road
		FROM analysis.animal_traj_steps,env_data.roads
		WHERE ST_DWithin(animal_traj_steps.geom::geography,roads.geom::geography,500)
		ORDER BY id, dist_to_road ASC) t
	GROUP BY animal
	ORDER BY animal;
```

| animal | count | mean\_distance\_to\_road |
|--------|-------|--------------------------|
| 4      | 780   | 166.05                   |
| 5      | 652   | 407.45                   |

As we can see, animal 4 has more steps closer to the roads, and those
steps are much closer to the roads than animal 5 in general.


### Exercise

Create a query to summarize each animal's average speed (all steps)
vs. their speed when they are closer to roads (500 meters).


### Example - trajectory and elevation relationship

We can also intersect the trajectory steps with raster data, such as a
Digital Elevation Model (DEM). In the following query, we summarize
the mean, max, min, and range of elevation for each step from the
*srtm\_dem* raster. The query utilizes *ST\_Intersect* (to select
rasters that intersect with each line), and *ST\_Clip()* (to extract
the pixels that intersect with each line). The *ST\_Summary\_Stats*
function is used to extract statistics from each clipped raster, which
are then summarized by each step's ID. When clipping a raster with a
line, one line is returned in the query result for each raster tile
intersected, so additional aggregation functions are needed to
summarize each *animal\_traj\_id*. Note that this query will take
several seconds to run.
    
```sql
SELECT
stats.id,
(sum(stats.sum)/sum(stats.pixels))::numeric(8,2) as mean_elevation,
max(stats.max) as max_elevation,
min(stats.min) as min_elevation,
(max(stats.max) - min(stats.min)) as range_elevation
	FROM (SELECT
	foo.id,
	foo.rid,
	(ST_SummaryStats(foo.trajr)).count as pixels,
	(ST_SummaryStats(foo.trajr)).sum as sum,
	(ST_SummaryStats(foo.trajr)).max as max,
	(ST_SummaryStats(foo.trajr)).min as min
		FROM
		(SELECT
		animal_traj_steps.animal_traj_id as id,
		srtm_dem.rid as rid,
		ST_Clip(rast, geom) as trajr --returns a set of raster objects (pixels intersected by line)
		FROM
		env_data.srtm_dem,
		analysis.animal_traj_steps
		WHERE
		animal_traj_steps.geom IS NOT NULL AND
		ST_intersects(rast, geom) -- determine which rasters intersect line
		) AS foo
	order by foo.id) as stats
GROUP BY stats.id
ORDER BY id;
```

The first 5 results should be:

| id  | mean\_elevation | max\_elevation | min\_elevation | range\_elevation |
|-----|-----------------|----------------|----------------|------------------|
| 1   | 849.25          | 853            | 847            | 6                |
| 2   | 862.50          | 875            | 850            | 25               |
| 3   | 919.00          | 931            | 907            | 24               |
| 4   | 924.67          | 944            | 910            | 34               |
| 3   | 909.33          | 920            | 898            | 22               |


### Example - trajectory and land cover relationship

We can also summarize the land cover (from
*env\_data.corine\_land\_cover*) near the trajectories using
PostGIS. For example, we may want to know what proportion of each land
cover type is within 50 meters of each step. There are two ways to
approach this in PostGIS. We can think of the 50 meters around each
step as a polygon (created using *ST\_Buffer*). In the query below, we
use the PostGIS function *ST\_Intersection* to return the overlap
between our land cover raster and the buffered step - the output is
therefore also a polygon. The function automatically "vectorizes" the
raster, and the result is buffered step polygons split by land cover
types. Run this query in QGIS DB Manager Query tool to visualize the
resulting query layer:
    
```sql
SELECT
row_number() OVER (ORDER BY id) AS gid,
id,
val,
(sum(area)*100/SUM(SUM(area)) over (PARTITION BY id))::numeric(8,2) as step_lc_perc,
ST_Union(geom) as geom FROM
	(SELECT
	id,
	(gv).val,
	ST_Area(ST_Union((gv).geom))::numeric(10,2) as area,
	ST_Union((gv).geom) as geom
	 --calculate area for each land cover by step
	FROM
		(SELECT
		animal_traj_steps.animal_traj_id as id,
		ST_Intersection(rast, ST_Buffer(ST_Transform(geom,3035),50,'endcap=round')) AS gv
		FROM
		env_data.corine_land_cover,
		analysis.animal_traj_steps
		WHERE
		animal_traj_steps.geom IS NOT NULL AND
		ST_intersects(rast, ST_Buffer(ST_Transform(geom,3035),50,'endcap=round')) -- determine which rasters intersect buffered line
		AND animal_traj_steps.animal_traj_id <= 7 --only run for first 7 steps
		) AS foo
	GROUP BY id,val
	ORDER BY id) as stats
GROUP BY id,val;
```

We can see that this result would give us the most "precise"
estimation of land cover within the buffer, but it comes at the cost
of performance; running this query for the entire
*analysis.animal\_traj\_steps* table can take a minute or more. The
other option for this summary is to use the *ST\_Clip()* function. As
you may recall from the elevation summary, this function returns a
raster (in the case of a line, just the pixels intersecting the
line). When a polygon is used to clip a raster, all pixels
centerpoints falling within the polygon are retained.  Depending on
the pixel size of your raster in relation to the polygon (buffer)
size, this may be a better option than ST\_Intersection, as it
processes much more quickly (rasters do not have to be
vectorized). For example, the query below is over 10 times faster than
the previous one (when run for the full dataset).

```sql
SELECT
id,
lc_val,
(sum(num_pixels)*100/SUM(SUM(num_pixels)) over (PARTITION BY id))::numeric(8,2) as step_lc_perc FROM
	(SELECT
	id,
	lc_val,
	sum(lc_ct) as num_pixels
	FROM
		(SELECT
		animal_traj_steps.animal_traj_id as id,
		corine_land_cover.rid as rid,
		(ST_ValueCount(ST_Clip(rast, ST_Buffer(ST_Transform(geom,3035),50)))).value AS lc_val,
		(ST_ValueCount(ST_Clip(rast, ST_Buffer(ST_Transform(geom,3035),50)))).count AS lc_ct
		FROM
		env_data.corine_land_cover,
		analysis.animal_traj_steps
		WHERE
		animal_traj_steps.geom IS NOT NULL AND
		ST_intersects(rast, ST_Transform(geom,3035)) -- determine which rasters intersect line
		ORDER BY id
		) AS foo
	GROUP BY foo.id,lc_val
	ORDER BY foo.id,lc_val) as stats
GROUP BY id, lc_val
ORDER BY id;
```


### Exercise

Calculate the % of each animal's trajectory in forest (land cover \#'s
23, 24, 25) for each month of the year (use ST\_Clip with just the
line, no buffer).


## Summary exercise of Lesson 10

1.  Create a query to summary animal 4's average speed and R2n by
    month.
2.  The *animal\_traj\_steps* is currently a table in the analysis
    schema, but in order to keep it current with the points in
    *animal\_traj\_points*, we can make it into a view that is
    populated whenever it is accessed. Remake the
    *animal\_traj\_steps* table into a view, making sure to DROP TABLE
    *analysis.animal\_traj\_steps* first.
3.  Run a query in QGIS that selects the 10 trajectory steps with the
    greatest range in elevation, and add the query result to your view
    (don't forget to query the geometry)!




# Part 1. Setting up a wildlife tracking database using PostgreSQL


% Lesson 2. Storing tracking data in an advanced database platform: PostgreSQL
% 6 June 2016

The state-of-the-art technical tool for effectively and efficiently
managing tracking data is the spatial relational database. Using
databases to manage tracking data implies a considerable effort for
those who are not already familiar with these tools, but this is
necessary to be able to deal with the data coming from the new
sensors. Moreover, the time spent to learn databases will be largely
paid back with the time saved for the management and processing of the
data. In this lesson, you are guided through how to set up a new
database in which you will create a table to accommodate the test GPS
data sets. You create a new table in a dedicated schema. This lesson
describes how to upload the raw GPS data coming from five sensors
deployed on roe deer in the Italian Alps into the database and how to
create additional database users. The reference software platform used
is the open source PostgreSQL with its spatial extension PostGIS. The
reference (graphical) interface used to deal with the database
is [pgAdmin](http://www.pgadmin.org/). All the examples provided (SQL
code) and technical solutions proposed are tuned on this software,
although most of the code can be easily adapted for other platforms.

The datasets you will need for the following lessons can be downloaded
[here](http://basille-flrec.ad.ufl.edu:4554/dbucklin/postgis_workshop_2016/tree/master/lesson_files/p2/tracking_db_datasets.zip). Download
and unzip the contents to your computer. If using Windows, unzip them
to a location the `postgres` database user can access (e.g., a new
folder under `C:/postgis_workshop/`).


## Topic 1. Create a database and import your data in a table


### Introduction

Once a tracking project starts and sensors are deployed on animals,
data begin to arrive (usually in the form of text files containing the
raw information recorded by sensors). At this point, data must be
handled by researchers. In this and the following exercises, you will
create a fully operational relational database for GPS tracking
data. The first steps to carry out are the creation of a new database,
of a new schema and a table to accommodate data coming from the (GPS)
sensor that can then be imported. All the basic knowledge needed for
these tasks were introduced in the Part 1 of this tutorial.


### Example

Assuming that you have PostgreSQL installed and running on your
computer (or server), the first thing that you have to do to import
your raw sensors data into the database is to connect to the database
server and create a new database with the
command [CREATE DATABASE](http://www.postgresql.org/docs/devel/static/sql-createdatabase.html):

```sql
CREATE DATABASE gps_tracking_db
ENCODING = 'UTF8'
TEMPLATE = template0
LC_COLLATE = 'C'
LC_CTYPE = 'C';
```

You could create the database using just the first line of the
code. The other lines are added just to be sure that the database will
use UTF8 as encoding system and will not be based on any
local-specific setting regarding, e.g. alphabets, sorting, or number
formatting. This is very important when you work in an international
environment where different languages (and therefore characters) can
potentially be used. When you import textual data with different
encoding, you have to specify the original encoding otherwise special
character might be misinterpreted. Different encodings are a typical
source of error when data are moved from a system to another.

Although not compulsory, it is very important to document the objects
that you create in your database to enable other users (and probably
yourself later on) to understand its structure and content, pretty
much the same way you use to do with metadata of your
data. [COMMENT](http://www.postgresql.org/docs/devel/static/sql-comment.html)
command gives you this possibility. Comments are stored into the
database. In this case:

```sql
COMMENT ON DATABASE gps_tracking_db   
IS 'Next Generation Data Management in Movement Ecology Summer school: my database.'; 
```

By default, a database comes with the *public* schema; it is good
practice, however, to use different schemas to store user data. For
this reason you create a new
[SCHEMA](http://www.postgresql.org/docs/devel/static/sql-createschema.html)
called *main*:

```sql
CREATE SCHEMA main;
```

```sql
COMMENT ON SCHEMA main IS 'Schema that stores all the GPS tracking core data.'; 
```

Before importing the GPS data sets into the database, it is
recommended that you examine the source data (usually .dbf, .csv, or
.txt files) with a spreadsheet or a text editor to see what
information is contained. Every GPS brand/model can produce different
information, or at least organise this information in a different way,
as unfortunately no consolidated standards exist yet. The idea is to
import raw data (as they are when received from the sensors) into the
database and then process them to transform data into
information. Once you identify which attributes are stored in the
original files (for example, *GSM01438.csv*), you can create the
structure of a table with the same columns, with the correct database
[DATA TYPES](http://www.postgresql.org/docs/devel/static/datatype.html). You
can find the GPS data sets in .csv files included in the
*trackingDB\_datasets.zip* file with test data in the sub-folder
*/tracking\_db/data/sensors\_data*. The SQL code that generates the
same table structure of the source files (Vectronic GPS collars)
within the database, which is called here *main.gps\_data* (*main* is
the name of the schema where the table will be created, while
*gps\_data* is the name of the table) is

```sql
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
```

```sql
COMMENT ON TABLE main.gps_data 
IS 'Table that stores raw data as they come from the sensors (plus the ID of the sensor).'; 
```

In a relational database, each table must have a primary key, that is
a field (or combination of fields) that uniquely identify each
record. In this case, we added a
[SERIAL](http://www.postgresql.org/docs/devel/static/sql-createsequence.html)
id field managed by the database (as a sequence of integers
automatically generated) to be sure that it is unique. We set this
field as the primary key of the table:

```sql
ALTER TABLE main.gps_data 
ADD CONSTRAINT gps_data_pkey PRIMARY KEY(gps_data_id); 
```

To keep track of database changes, it is useful to add another field
where the timestamp of the insert of each record is automatically
recorded (assigning a dynamic default value):

```sql
ALTER TABLE main.gps_data ADD COLUMN insert_timestamp timestamp with time zone; 
```

```sql
ALTER TABLE main.gps_data ALTER COLUMN insert_timestamp SET DEFAULT now(); 
```

Now we are ready to import our data sets. There are many ways to do
so. The main one is to use the
[COPY](http://www.postgresql.org/docs/devel/static/sql-copy.html)
command setting the appropriate parameters:

```sql
COPY main.gps_data( 
gps_sensors_code, line_no, utc_date, utc_time, lmt_date, lmt_time, ecef_x, ecef_y, ecef_z, latitude, longitude, height, dop, nav, validated, sats_used, ch01_sat_id, ch01_sat_cnr, ch02_sat_id, ch02_sat_cnr, ch03_sat_id, ch03_sat_cnr, ch04_sat_id, ch04_sat_cnr, ch05_sat_id, ch05_sat_cnr, ch06_sat_id, ch06_sat_cnr, ch07_sat_id, ch07_sat_cnr, ch08_sat_id, ch08_sat_cnr, ch09_sat_id, ch09_sat_cnr, ch10_sat_id, ch10_sat_cnr, ch11_sat_id, ch11_sat_cnr, ch12_sat_id, ch12_sat_cnr, main_vol, bu_vol, temp, easting, northing, remarks) 
FROM 
'C:\tracking_db\data\sensors_data\GSM01438.csv' WITH CSV HEADER DELIMITER ';'; 
```

You might have to adapt the path to the file. If you get an error
about permissions (you cannot open the source file) it means that the
file is stored in a folder where it is not accessible by the
database. In this case, move it to a folder that is accessible to all
users of your computer.

If PostgreSQL complain that date is out of range, check the standard
date format used by PostgreSQL
([datestyle](http://www.postgresql.org/docs/devel/static/runtime-config-client.html#GUC-DATESTYLE)):

```sql
SHOW datestyle; 
```

if it is not *ISO, DMY*, then you have to set the date format (for the
current session) as:

```sql
SET SESSION datestyle = "ISO, DMY"; 
```

This will change the *datastyle* for the current session only. If you
want to change this setting permanently, you have to modify the
*datestyle* option in the
[postgresql.conf](http://www.postgresql.org/docs/devel/static/config-setting.html#CONFIG-SETTING-CONFIGURATION-FILE)
file.

In the case of .dbf files, you can use a tool that comes with PgAdmin
(*Shapefile and .dbf importer*). In this case, you do not have to
create the structure of the table before importing, but you lose
control over the definition of data type (e.g. time will probably be
stored as a text value). You can also use MS Access and link both
source and destination table and run an upload query.


### Exercise

Import into the database the raw GPS data from the test sensors:

-   GSM01508
-   GSM01511
-   GSM01512


## Topic 2. Finalise the table of raw data: acquisition timestamps, indexes and permissions


### Introduction

PostgreSQL (and most of the database systems) can deal with a large
set of specific type of data with dedicated database data types and
related functionalities in addition to string and numbers. In the next
exercise, a new field is introduced to represent a
[timestamp with time zone](http://www.postgresql.org/docs/9.1/static/datatype-datetime.html),
i.e. date + time + time zone together (later on in this tutorial,
another specific data type will be introduced to manage spatial data).

Moreover, a database offers many functionalities to improve
performances. One of these are
[indexes](http://www.postgresql.org/docs/devel/static/indexes.html)
that are data structures that improve the speed of data retrieval
operations on a database table at the cost of slower writes and the
use of more storage space. Database indexes work in a similar way to a
book's table of contents: you have to add an extra page and update it
whenever new content is added, but then searching for specific
sections will be much faster. In the exercise, an index will be added
to the location table and an example of its effectiveness will be
shown.

One of the main advantages of an advanced database management system
like PostgreSQL is that the database can be accessed by a number of
different users at the same time, keeping the data always in a single
version with a proper management of concurrency. This ensures that the
database maintains the ACID (atomicity, consistency, isolation,
durability) principles in an efficient manner and that different
permission levels can be set for each user. For example, you can have
a single administrator that can change the database, a set of advanced
users that can edit the content of the core tables and create their
own object (e.g. tables, functions) without changing the main database
structure, and a set of users that can just read the data. In the
exercise, a new group of database users and related
permissions([roles and privileges](http://www.postgresql.org/docs/9.0/static/user-manag.html))
on the raw locations table will be added to illustrate some of the
options to manage different class of users.


### Example

In the original GPS data file, no timestamp field is present. Although
the table main.gps\_data is designed to store data as they come from
the sensors, it is convenient to have an additional field where date
and time are combined and where the correct time zone is set (in this
case UTC). To do so, you first add a field with data type *timestamp
with time zone* type. Then you fill it (with an UPDATE statement) from
the time and date fields. In a later exercise, you will see how to
automatize this step using triggers.

```sql
ALTER TABLE main.gps_data 
  ADD COLUMN acquisition_time timestamp with time zone;
```

```sql
UPDATE main.gps_data 
  SET acquisition_time = (utc_date + utc_time) AT TIME ZONE 'UTC';
```

Now the table is ready. Next you can add some indexes. You have to
decide on which fields you create indexes for by considering what kind
of query will be performed most often in the database. Here you add
indexes on the *acquisition\_time* and the *gps\_sensors\_code*
fields, which are probably two key attributes in the retrieval of data
from this table:

```sql
CREATE INDEX acquisition_time_index
  ON main.gps_data
  USING btree (acquisition_time );
```

```sql
CREATE INDEX gps_sensors_code_index
  ON main.gps_data
  USING btree (gps_sensors_code);
```

As a simple example, you can now retrieve data using specific
selection criteria. Let's retrieve data from the collar **GSM01512**
during the month of May (whatever the year), and order them by their
acquisition time:

```sql
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
```

The first records (LIMIT 5 returns just the first 5 records) of the
result of this query are:

| id    | sensor\_id | latitude | longitude | acquisition\_time      |
|-------|------------|----------|-----------|------------------------|
| 11906 | GSM01512   | 46.00563 | 11.05291  | 2006-05-01 00:01:01+00 |
| 11907 | GSM01512   | 46.00630 | 11.05352  | 2006-05-01 04:02:54+00 |
| 11908 | GSM01512   | 46.00652 | 11.05326  | 2006-05-01 08:01:03+00 |
| 11909 | GSM01512   | 46.00437 | 11.05536  | 2006-05-01 12:02:40+00 |
| 11910 | GSM01512   | 46.00720 | 11.05297  | 2006-05-01 16:01:23+00 |

In most of the cases, your database will have multiple users. As an
example, you create here a group of users, called *basic\_users*.

```sql
CREATE ROLE basic_user LOGIN
NOSUPERUSER INHERIT NOCREATEDB NOCREATEROLE NOREPLICATION;
```

You can then associate a permission to SELECT data from the raw
locations data. First, you have to give USAGE permission on the SCHEMA
where the *main.gps\_data* table is stored (with SET USAGE ON THE
SCHEMA), then you grant READ permission on the table.

```sql
GRANT USAGE ON SCHEMA main TO basic_user;
```

```sql
GRANT SELECT ON main.gps_data TO basic_user;
```

Groups are very useful because you can associate multiple users to the
same group and they will automatically inherit all the permissions of
the group so you do not have to assign permissions to each one
individually. Permissions can be given to a whole group or to specific
users.

You create a user that is part of the *basic\_users* group (login
*ciccio\_pasticcio*, password *pasticcio\_ciccio*).

```sql
CREATE ROLE ciccio_pasticcio LOGIN IN ROLE basic_user
  PASSWORD 'pasticcio_ciccio'
  NOSUPERUSER INHERIT NOCREATEDB NOCREATEROLE NOREPLICATION;
```

In general, every time you create a new database object, you have to
set the privileges (for tables: `ALL`, `INSERT`, `SELECT`, `DELETE`,
`UPDATE`) to groups/users. If you want to set the same privileges to a
group/user for all the tables in a specific schema you can use GRANT
SELECT ON ALL TABLES:

```sql
GRANT SELECT ON ALL TABLES 
  IN SCHEMA main 
  TO basic_user;
```

You can now reconnect to the database as *ciccio\_pasticcio* user and
try first to visualize data and then change the values of a
record. This latter operation will be forbidden because the user do
not have this kind of privilege. In this way, the database integrity
will be safeguarded from inexperienced user that might remove all the
data running the wrong command.

If you want to automatically grant permissions to specific
groups/users to all new (i.e. that will be created in the future)
objects in a schema, you can use ALTER DEFAULT PRIVILEGES:

```sql
ALTER DEFAULT PRIVILEGES 
  IN SCHEMA main 
  GRANT SELECT ON TABLES 
  TO basic_user;
```

From now on, users belonging to *basic\_user's* group with have
reading access to all the tables that will be created in the *main*
schema. By default, all objects created in the schema *public* are
fully accessible to all users.

Setting a permission policy in a complex multi-user environment
requires an appropriate definition of data access at different levels.


### Exercise

Write SQL queries to determine answers to the following:

1.  How many locations are acquired in summer?
2.  What are the extreme coordinates (minimum and maximum longitude
    and latitude) for each sensor?


## Topic 3. Export your data and backup the database


### Introduction

There are different ways to export a table or the results of a query
to an external file. One is to use the command
[COPY (TO)](http://www.postgresql.org/docs/devel/static/sql-copy.html). COPY
TO (similarly to what happens with the command COPY FROM used to
import data) with a file name directly write the content of a table or
the result of a query to a file. The file must be accessible by the
PostgreSQL user (i.e. you have to check the permission on target
folder by the user ID the PostgreSQL server runs as) and the name
(path) must be specified from the viewpoint of the server. This means
that files can be read or write only in folders 'visible' to the
database servers. If you want to remotely connect to the database and
save data into your local machine, you can use the command
[\\COPY](http://www.postgresql.org/docs/devel/static/app-psql.html#APP-PSQL-META-COMMANDS-COPY)
that performs a frontend (client) copy. \\COPY is not an SQL command
and must be run from a PostgreSQL interactive terminal
([PSQL](http://www.postgresql.org/docs/devel/static/app-psql.html)). This
is an operation that runs an SQL COPY command, but instead of the
server reading or writing the specified file, PSQL reads or writes the
file and routes the data between the server and the local file
system. This means that file accessibility and privileges are those of
the local user, not the server, and no SQL superuser privileges are
required. Another possibility to export data is to use the pgAdmin
interface: in the SQL console select *Query/Execute to file* and the
results will be saved to a local file instead of being
visualized. Other database interfaces have similar tools.

A proper backup policy for a database is important to securing all
your valuable data and the information that you have derived through
data processing. In general it is recommended to have frequent
(scheduled) backups (e.g. once a day) for schemas that change often
and less frequent backups (e.g. once a week) for schemas (if any) that
occupy a larger disk size and do not change often (e.g. ancillary
environmental layers). PostgreSQL offers very good tools for database
[backup and recovery](http://www.postgresql.org/docs/devel/static/backup.html). The
two main tools to back up are:

- [pg\_dump.exe](http://www.postgresql.org/docs/devel/static/app-pgdump.html):
  extracts a PostgreSQL database or part of the database into a script
  file or other archive file
  ([pg\_restore.exe](http://www.postgresql.org/docs/devel/static/app-pgrestore.html)
  is then used to restore the database);
- [pg\_dumpall.exe](http://www.postgresql.org/docs/devel/static/app-pg-dumpall.html):
  extracts a PostgreSQL database cluster (i.e. all the databases
  created inside the same installation of PostgreSQL) into a script
  file (e.g. including database setting, roles).

These are not SQL commands but executable commands that must run from
a command-line interpreter (with Windows, the default command-line
interpreter is the program *cmd.exe*, also called *Command
Prompt*). pgAdmin also offers a graphic interface for backing up and
restoring the database. Moreover, it also important to keep a
file-based copy of the original raw data files, particularly those
generated by sensors.


### Example

An example of data export for the whole *main.gps\_data* table is

```sql
COPY (
  SELECT gps_data_id, gps_sensors_code, latitude, longitude, acquisition_time, insert_timestamp 
  FROM main.gps_data) 
TO 
  'C:\tracking_db\test\export_test1.csv' 
  WITH (FORMAT csv, HEADER, DELIMITER ';');
```

An example of a back up (if you want to reuse this layout, you must
properly set the path to your *pg\_dump* command) of the full database
is:

```
> cd C:\Program Files\PostgreSQL\9.5\bin\
>
> pg\_dump.exe -h localhost -p 5432 -U postgres -F p -E UTF8 -f C:\postgis\_workshop\tracking\_db\test\backup\_db.sql -d gps\_tracking\_db
```

To restore the SQL file to a new database, first create the database
(e.g., `gps2`), then run in command line:

```
> cd C:\Program Files\PostgreSQL\9.5\bin\
>
> psql.exe gps2 < C:\postgis_workshop\tracking\_db\test\backup\_db.sql postgres
```


### Exercise

1.  Find and export to a .csv file the first and last acquisition
    times for each sensor;
2.  Make a complete backup of the database built so far and restore it
    in a new database on your computer.


## Summary exercise of Lesson 2

1.  Find the number of days monitored by each GPS sensor.



% Lesson 3. Managing and modelling information on animals and sensors
% 7 June 2016


GPS positions are used to describe animal movements and to derive a
large set of information, for example about animals' behavior, social
interactions, and environmental preferences. GPS data are related to
(and must be integrated with) many other sources of information that
together can be used to describe the complexity of movement
ecology. In a database framework, this can only be achieved through
proper database data modelling, which depends on a clear definition of
the biological context of a study. Particularly, data modelling
becomes a key step when database systems manage a large set of
connected data sets that grow in size and complexity: it permits easy
updates and modification and adaptation of the database structure to
accommodate the changing goals, constraints, and spatial scales of
studies. In this lesson, you will extend your database with two new
tables to integrate ancillary information useful to interpreting GPS
data: one for GPS sensors, and one for animals. Additionally, you will
add "lookup tables" which translate certain codes into descriptions,
and enforce which codes can be used for species and age classes in the
database.


## Topic 1. The world in a database: database data models

A data model describes what types of data are stored and how they are
organized. It can be seen as the conceptual representation of the real
world in the database structures that include data objects
(i.e. tables) and their mutual relationships. In particular, data
modelling becomes a key step when database systems grow in size and
complexity, and user requirements become more sophisticated: it
permits easy updates and modification and adaptation of the database
structure to accommodate the changing goals, constraints, and spatial
scales of studies and the evolution of wildlife tracking
systems. Without a rigorous data modelling approach, an information
system might lose the flexibility to manage data efficiently in the
long term, reducing its utility to a simple storage device for raw
data, and thus failing to address many of the necessary requirements.

To model data properly, you have to clearly state the biological
context of your study. A logical way to proceed is to define (**a**)
very basic questions on the sample unit, i.e. individual animals and
(**b**) basic questions about data collection. **a**) Typically,
individuals are the sampling units of an ecological study based on
wildlife tracking. Therefore, the first question to be asked while
modelling the data is: *What basic biological information is needed to
characterise individuals as part of a sample?* Species, sex and age
(or age class) at capture are the main factors which are relevant in
all studies. Age classes typically depend on the species. Moreover,
age class is not constant for all the GPS positions. The correct age
class at any given moment can be derived from the age class at capture
and then defining rules that specify when the individual change from a
class to another (for roe deer, you might assume that at 1st April of
every year each individual that was a fawn becomes a yearling, and
each yearling becomes an adult). Other information used to
characterise individuals could be specific to a study, for example in
a study on spatial behaviour of translocated animals, 'resident' or
'translocated' is an essential piece of information linked to
individual animals. All these elements should be described in specific
tables. **b**) A single individual becomes a 'studied unit' when it is
fitted with a sensor, in this case to collect position
information. First of all, GPS sensors should be described by a
dedicated table containing the technical characteristics of each
device (e.g. vendor, model). Capture time, or 'device-fitting' time,
together with the time and a description of the end of the deployment
(e.g. drop-off of the tag, death of the animal), are also essential to
the model. The link between the sensors and the animals should be
described in a table that states unequivocally when the data collected
from a sensor 'become' (and cease to be) bio-logged data, i.e. the
period during which they refer to an individual's behaviour. The start
of the deployment usually coincides with the moment of capture, but it
is not the same thing. Indeed, moment of capture can be the 'end' of
one relationship between a sensor and an animal (i.e. when a device is
taken off an animal) and at the same time the 'beginning' of another
(i.e. another device is fitted instead).

Thanks to the tables 'animals', 'sensors' and 'sensors to animals',
and the relationships built among them, GPS data can be linked
unequivocally to individuals, i.e. the sampling units (see Lesson 4).

Some information related to animals can change over time. Therefore,
they must be marked with the reference time that they refer
to. Examples of typical parameters assessed at capture are age and
positivity of association to a disease. Translocation may also
coincide with the capture/release time. If this information changes
over time according to well-defined rules (e.g. transition from age
classes), their value can be dynamically calculated in the database at
different moments in time (e.g. using database functions). In one of
the next lessons, you will see an example of a function to calculate
age class from the information on the age class at capture and the
acquisition time of GPS positions for roe deer. The basic structure
based on the elements *animals*, *sensors*, *sensors to animals*, and,
of course, *position data*, can be extended to take into account the
specific goals of each project, the complexity of the real-world
problems faced, the technical environment, and the available
data. Examples of data that can be integrated are capture methodology,
handling procedure, use of tranquilizers and so forth, that should be
described in a 'captures' table linked to the specific individual (in
the table 'animals'). Finally, data referring to individuals may come
from several sources, e.g. several sensors or visual observations. In
all these cases, the link between data and sample units (individuals)
should also be clearly stated by appropriate relationships. In complex
projects, especially those involving field data collection in parallel
with remote tracking, and involve multiple species/sensor types,
databases can quickly get complex and grow up to hundreds of tables.

The design of the database data model is an exercise that must be
performed at the very initial stage of the creation of a
database. Once the objects (and objectives) of a study are identified
and described (see above), some tools exist to graphically translates
the conceptual model into connected tables, each of them representing
a specific entity of the world. This process is not trivial and force
biologists to "formalize" their goals, data and scientific approach
(which also helps to organize the whole data collection in a
systematic and consistent way). For example, at the beginning of a
tracking study, it is easy to assume that a tag (i.e. a collar) can be
identified with the animal where it is deployed, creating a single
table. Later on, it happens very often that the same collar is reused
on other animals, thus making a data model based on a single
animal-collar table unsuitable. Changing a database on and advanced
stage of development is very complicate and requires by far more times
than a carefully planned phase of data modelling at the start of the
project.

A very popular graphical tool to represent a data model is the
[Entity-Relationship Diagram (ERD)](https://en.wikipedia.org/wiki/Entity%E2%80%93relationship_model)
that helps to show the relationship between elements, concepts or
events of a system and that can be used as the foundation for a
relational database.

In the figure below, it is illustrated the schema of the database
structure created at the end of this and the next lessons.

![schema-db](images/l3/schema-db.png)


## Topic 2. Extend the database: data on sensors and animals


### Introduction

At the moment, there is a single table in the your test database and
it represents raw data from GPS sensors. This data alone gives very
little information on what it represents. To take full advantage of
these positional data sets, you have to join locations with other kind
of information that help to transform the raw number into the
description of real-life objects (in this case, moving animals). When
this contextual information is very limited, you can simply add some
metadata, but in case it is more structured and complex, you have to
properly integrate it into the database as tables. Now you can start
to extend the database with new tables to represent sensors and
animals. This process will continue throughout all the following
lessons in order to include a wide range of information that are
relevant for wildlife tracking.


### Example

In the sub-folder */tracking\_db/data/animals* and
*/tracking\_db/data/sensors* of the test data set you will find two
files:*animals.csv* and *gps\_sensors.csv*. Let's start with data on
GPS sensors. Once you have explored its content, first you have to
create a table in the database with the same attributes as the .csv
file, and then import the data into it. Here is the code of the table
structure:

```sql
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
```

```sql
COMMENT ON TABLE main.gps_sensors
IS 'GPS sensors catalog.';
```

The field *gps\_sensors\_id* is an integer and is used as the primary
key. You could also use *gps\_sensors\_code* as primary key, but in
many practical situations it is handy to use an integer field. In some
cases, a good recommendation is to use a *serial number* as primary
key to let the database generate a unique code (integer) every time
that a new record is inserted. In this exercise, we use an integer
data type because the values of the *gps\_sensors\_id* field are
pre-defined in order to be correctly referenced in the exercises of
the next lessons. A
[UNIQUE](http://www.postgresql.org/docs/9.3/static/ddl-constraints.html)
constraint is created on the field *gps\_sensors\_code* to be sure
that the same sensor is not imported more than once. You add a field
to keep track of the timestamp of record insertion, which can be very
useful to monitor database activities:

```sql
ALTER TABLE main.gps_sensors 
  ADD COLUMN insert_timestamp timestamp with time zone DEFAULT now();
```

Now you can import data using the COPY command:

```sql
COPY main.gps_sensors(
  gps_sensors_id, gps_sensors_code, purchase_date, frequency, vendor, model, sim)
FROM 
  'C:\tracking_db\data\sensors\gps_sensors.csv' 
  WITH (FORMAT csv, DELIMITER ';');
```

At this stage, you have defined the list of GPS sensors that exist in
your database. To be sure that you will never have GPS data that come
from a GPS sensor that does not exist in the database, you apply a
[foreign key](http://www.postgresql.org/docs/9.3/static/ddl-constraints.html)
between *main.gps\_data* and *main.gps\_sensors*. Foreign keys
physically translate the concept of relations among tables.

```sql
ALTER TABLE main.gps_data
  ADD CONSTRAINT gps_data_gps_sensors_fkey 
  FOREIGN KEY (gps_sensors_code)
  REFERENCES main.gps_sensors (gps_sensors_code) 
  MATCH SIMPLE ON UPDATE NO ACTION ON DELETE NO ACTION;
```

This setting says that in order to delete a record in
main.gps\_sensors, you first have to delete all the associated records
in *main.gps\_data*. From now on, before importing GPS data from a
sensor, you have first to create the sensor's record in the
*main.gps\_sensors table*. You can add other kinds of constraints to
control the consistency of your database. As an example, here you
check that the date of purchase is after *2000-01-01*. If this
condition is not met, the database will refuse to insert (or modify)
the record and will return an error message.

```sql
ALTER TABLE main.gps_sensors
  ADD CONSTRAINT purchase_date_check 
  CHECK (purchase_date > '2000-01-01'::date);
```


### Exercise

1.  Write a query to view all the data stored in *main.gps\_data*,
    along with the date when the sensor was purchased and the vendor
    name.


## Topic 3. Extend the database: data on animals


### Introduction

The coordinates provided by GPS sensors describe in detail the spatial
patterns of animal movements, which provide valuable information to
biologists and wildlife managers. On the other hand, coordinates
alone, with no information of what they represent i.e. (the object
that is moving and its characteristics), can just partially address
the main ecological questions that they can potential answer. In this
and in the next lessons, we will try to build up a (database)
framework to move from coordinates to more complex object: individual
animals, with their characteristics and interactions, moving in their
environment. The first step is to describe the individuals that are
monitored. In this exercise we create a table to store basic
information such as age, sex, species, and the name that researchers
use to identify that individual (if any).


### Example

Now you repeat the same process for data on animals. Analyzing the
animals' source file (*animals.csv*), you can derive the fields of the
new main.animals table:

```sql
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
```

```sql
COMMENT ON TABLE main.animals
IS 'Animals catalog with the main information on individuals.';
```

As for *main.gps\_sensors*, in your operational database you could
have used the serial data type for the *animals\_id* field. Age class
(at capture) and species are attributes that can only have defined
values. To enforce consistency in the database, in these cases you can
use look up tables. Look up tables are tables that store the list and
the description of all possible values referenced by specific fields
in different tables and constitute the definition of the valid
domain. They are very common because they can help to simplify a
database structure and add flexibility as compared to *constraints*
defined on specific fields. It is recommended to keep look up tables
in a separated schema to give the database a more readable and clear
data structure. Therefore, you create a *lu\_tables* schema:

```sql
CREATE SCHEMA lu_tables;
  GRANT USAGE ON SCHEMA lu_tables TO basic_user;
```

```sql
COMMENT ON SCHEMA lu_tables
IS 'Schema that stores look up tables.';
```

You set as default that the user *basic\_user* will be able to run
SELECT queries on all the tables that will be created into this
schema:

```sql
ALTER DEFAULT PRIVILEGES 
  IN SCHEMA lu_tables 
  GRANT SELECT ON TABLES 
  TO basic_user;
```

Now you create a look up table for species:

```sql
CREATE TABLE lu_tables.lu_species(
  species_code integer,
  species_description character varying,
  CONSTRAINT lu_species_pkey 
  PRIMARY KEY (species_code)
);
```

```sql
COMMENT ON TABLE lu_tables.lu_species
IS 'Look up table for species.';
```

You populate it with some values (just roe deer code will be used in
our test data set):

```sql
INSERT INTO lu_tables.lu_species 
  VALUES (1, 'roe deer');

INSERT INTO lu_tables.lu_species 
  VALUES (2, 'rein deer');

INSERT INTO lu_tables.lu_species 
  VALUES (3, 'moose');
```

You can do the same for age classes:

```sql
CREATE TABLE lu_tables.lu_age_class(
  age_class_code integer, 
  age_class_description character varying,
  CONSTRAINT lage_class_pkey 
  PRIMARY KEY (age_class_code)
);
```

```sql
COMMENT ON TABLE lu_tables.lu_age_class
IS 'Look up table for age classes.';
```

You populate it with some values (these categories are based on roe
deer, other species might need a different approach):

```sql
INSERT INTO lu_tables.lu_age_class 
  VALUES (1, 'fawn');

INSERT INTO lu_tables.lu_age_class 
  VALUES (2, 'yearling');

INSERT INTO lu_tables.lu_age_class 
  VALUES (3, 'adult');
```

At this stage you can create the foreign keys between the
*main.animals* table and the two look up tables. This will prevent to
have animals with species and age classes that are not listed in the
look up tables. This is an important tool to ensure data integrity.

```sql
ALTER TABLE main.animals
  ADD CONSTRAINT animals_lu_species 
  FOREIGN KEY (species_code)
  REFERENCES lu_tables.lu_species (species_code) 
  MATCH SIMPLE ON UPDATE NO ACTION ON DELETE NO ACTION;
```

```sql
ALTER TABLE main.animals
  ADD CONSTRAINT animals_lu_age_class 
  FOREIGN KEY (age_class_code)
  REFERENCES lu_tables.lu_age_class (age_class_code) 
  MATCH SIMPLE ON UPDATE NO ACTION ON DELETE NO ACTION;
```

For sex class of deer, you do not expect to have more than the two
possible values: female and male (stored in the database as 'f' and
'm' to simplify data input). In this case, instead of a look up table
you can set a check on the field:

```sql
ALTER TABLE main.animals
  ADD CONSTRAINT sex_check 
  CHECK (sex = 'm' OR sex = 'f');
```

Whether it is better to use a look up table or a check must be
evaluated case by case, mainly according to the number of admitted
values and the possibility that you will want to add new values in the
future. You should also add a field to keep track of the timestamp of
record insertion in order to be able to keep track of what happened in
the database. More complex approach are possible to monitor the
database activity, from the creation of a log file that store all the
operations performed to proper versioned database, each of them with
pro and cons.

```sql
ALTER TABLE main.animals 
  ADD COLUMN insert_timestamp timestamp with time zone DEFAULT now();
```

As a last step, you import the values from the file:

```sql
COPY main.animals(
  animals_id,animals_code, name, sex, age_class_code, species_code)
FROM 
  'C:\tracking_db\data\animals\animals.csv' 
  WITH (FORMAT csv, DELIMITER ';');
```

To test the result, you can retrieve the animals' data with the
extended age class description:

```sql
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
```

The result of the query is:

| id  | code | name       | age\_class |
|-----|------|------------|------------|
| 1   | F09  | Daniela    | adult      |
| 2   | M03  | Agostino   | adult      |
| 3   | M06  | Sandro     | adult      |
| 4   | F10  | Alessandra | adult      |
| 5   | M10  | Decimo     | adult      |


### Exercise

1.  Query the table *main.animals* including the information on the
    sex and the species (with the name of the species stored in the
    look up table)
2.  Modify the field *vendor* in the table *main.gps\_sensors* to
    limit the possible values to: 'Vectronic Aerospace GmbH',
    'Sirtrack' and 'Lotek', then try to insert a vendor not in the
    list.


## Summary exercise of Lesson 3

1.  Design a general schema of a possible database extension
    (i.e. table(s) and their links) to include information on capture
    and particularly on:
    -   date and time of the capture (note that the same animal can be
        captured more than once)
    -   location of capture
    -   capture method
    -   person who captured the animal
    -   if the animal was collared, in this case include the code of
        the collar
    -   the name/id of the animal
    -   body temperature (note that temperature can be measured more
        than once at the different stages of the capture).



% Lesson 4. From data to information: associating locations to animals
% 7 June 2016


When position data are received from GPS sensors, they are not
explicitly associated with any animal. Linking GPS data to animals is
a key step in the data management process. This can be achieved using
the information on the deployments of GPS sensors on animals (when
sensors started and ceased to be deployed on the animals). In the case
of a continuous data flow, the transformation of GPS positions into
animal locations must be automated in order to have GPS data imported
and processed in real-time. In this lesson, you extend the database
with two new tables, *gps\_sensors\_animals* and
*gps\_data\_animals*. As additional material, a set of dedicated
database triggers and functions is presented that add tools to
automatically manage the association of GPS positions with animals.


## Topic 1. Storing information on GPS sensor deployments on animals


### Introduction

To associate a positions to animals, you need the information on
deployments, i.e. the time interval when a defined animal is wearing a
specific tag. This information is also needed to exclude the positions
recorded when a sensor was not deployed on any animal. The key point
is to integrate into the database the information on the deployment of
sensors on animals in a dedicated table. The design of the table
structure must take into consideration that each animal can be
monitored with multiple sensors (most likely at different times) and
each sensor can be reused on multiple animals (no more than one at a
time). This corresponds to a many-to-many relationship between animals
and GPS sensors, where the main attribute is the time range: start and
end of deployment (when the sensor is still deployed on the animal,
the end of deployment can be set to null). Making reference to the
case of GPS (but with a general validity), this information can be
stored in a *gps\_sensors\_animals* table where the ID of the sensor,
the ID of the animal, and the start and end timestamps of deployment
are included. A possible solution to store the records that are
associated with animals is to create a new table, which could be
called *gps\_data\_animals*, where a list of derived fields can be
eventually added to the basic animals ID, GPS sensors ID, acquisition
time, and coordinates. This new table duplicates part of the
information stored in the original *gps\_data table*, and the two
tables must be kept synchronized. On the other hand, there are
advantages of this database structure over alternative approaches with
a single table (*gps\_data*) where all the original data from GPS
sensors (including GPS positions not associated to animals) are also
related to other information (e.g. the animal ID, environmental
attributes, movement parameters):

-   *gps\_data* cannot be easily synchronized with the data source if
    too many additional fields (i.e. calculated after data are
    imported into the database) are present in the table;
-   if sensors from different vendors or different models of the same
    vendor are used, you might have file formats with a different set
    of fields: in this case it is complicated to merge all the
    information from each source in a single *gps\_data*table;
-   in a table containing just those GPS positions associated with
    animals, performance improves because of the reduced number of
    records and fields (the fields not relevant for analysis, e.g. the
    list of satellites, can be kept only in the *gps\_data* table);
-   with the additional *gps\_data\_animals* table, it is easier and
    more efficient to manage a system of tags to mark potential wrong
    locations and to share and disseminate the relevant information
    (you would lose the information on outliers if *gps\_data* is
    synchronized with the original data set, i.e. the text file from
    the sensors). In this course, we use the table *gps\_data* as an
    exact copy of raw data as they come from GPS sensors, while
    *gps\_data\_animals* is used to store and process the information
    that is used to monitor and study animals' movements. In a
    way,*gps\_data* is a 'system' table used as an intermediate step
    for the data import process. This approach is an example of
    possible database structure, but there is no best solution that
    fits all cases and a database for wildlife tracking data must be
    designed according to the specific data and requirements of each
    project.


### Example

The first step to associating GPS positions with animals is to create
a table to accommodate information on the deployment of GPS sensors on
animals:

```sql
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
```

```sql
COMMENT ON TABLE main.gps_sensors_animals
IS 'Table that stores information of deployments of sensors on animals.';
```

Now your table is ready to be populated. The general way of populating
this kind of table is the manual entry of the information. In our
case, you can use the test data set stored in the .csv file included
in the test data set
*\\tracking\_db\\data\\sensors\_animals\\gps\_sensors\_animals.csv*:

```sql
COPY main.gps_sensors_animals(
  animals_id, gps_sensors_id, start_time, end_time, notes)
FROM 
  'C:\tracking_db\data\sensors_animals\gps_sensors_animals.csv' 
  WITH (FORMAT csv, DELIMITER ';');
```

Once the values in this table are updated, you can use an SQL
statement to obtain the id of the animal related to each GPS
position. Here an example of a query to retrieve the codes of the
animal and GPS sensor, the acquisition time and the coordinates (to
make the query easier to read, aliases are used for the name of the
tables):

```sql
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
```

In the query, three tables are involved: *main.gps\_sensors\_animals*,
*main.gps\_data*, and *main.gps\_sensors*. This is because in the
*main.gps\_data*, where raw data from the sensors are stored, the
*gps\_sensors\_id* is not present, thus the table *main.gps\_sensors*
is necessary to convert the *gps\_sensors\_code* into the
corresponding *gps\_sensors\_id*. You can see that in the WHERE part
of the statement two cases are considered: when the acquisition time
is after the start and before the end of the deployment, and when the
acquisition time is after the start of the deployment and the end is
NULL (which means that the sensor is still deployed on the
animal). The first 5 records returned by this SELECT statement are:

| sensor | animal | acquisition\_time      | long     | lat      |
|--------|--------|------------------------|----------|----------|
| 4      | 1      | 2005-10-18 20:00:54+00 | 11.04413 | 46.01096 |
| 4      | 1      | 2005-10-19 00:01:23+00 | 11.04454 | 46.01178 |
| 4      | 1      | 2005-10-19 04:02:22+00 | 11.04515 | 46.00793 |
| 4      | 1      | 2005-10-19 08:03:08+00 | 11.04567 | 46.00600 |
| 4      | 1      | 2005-10-20 20:00:53+00 | 11.04286 | 46.01015 |


### Exercise

1.  Calculate how many locations for each sensor are not related to
    any animal (i.e. are not inside any deployment period).
2.  Create a constraint on *main.gps\_sensors\_animals* to avoid the
    case where *start\_time* &gt; *end\_time*.


## Topic 2. From GPS position to animal locations


### Introduction

Once the information on GPS sensors deployment is included into the
database, it is possible to associate locations to animals. It is
convenient to store this information in a permanent table.


### Example

A new table (*main.gps\_data\_animals*) can be used to store GPS data
with the code of the animal were the related sensor is deployed. This
table will be the main reference for data analysis, visualization, and
dissemination. In the figure below it is illustrated the structure of
data flow that populates the *gps\_data\_animals* table.

![deployment_schema](images/l4/deployment-schema.png)

Here is the SQL code that generates the *main.gps\_data\_animals*
table:

```sql
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
```

```sql
COMMENT ON TABLE main.gps_data_animals 
IS 'GPS sensors data associated to animals wearing the sensor.';
```

```sql
CREATE INDEX gps_data_animals_acquisition_time_index
  ON main.gps_data_animals
  USING BTREE (acquisition_time);
```

```sql
CREATE INDEX gps_data_animals_animals_id_index
  ON main.gps_data_animals
  USING BTREE (animals_id);
```

The foreign keys (on *animals\_id* and *sensor\_id*) are created as
well as indexes on the fields *animals\_id* and*acquisition\_time*
(that are those most probably involved in queries on this table).

At this point, you can feed the table with the data stored in the
table *gps\_data* and use *gps\_sensors\_animals* to derive the id of
the animals (checking if the timestamp of the location falls inside
the deployment interval of the sensor on an animal):

```sql
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
```

Another possibility is to simultaneously create and populate the table
*main.gps\_data\_animals* by using '*CREATE TABLE
main.gps\_data\_animals AS*' instead of '*INSERT INTO
main.gps\_data\_animals*' in the previous query and then adding the
primary and foreign keys and indexes to the table.


### Exercise

1.  What is the proportion of records with non-null coordinates for
    each animal?


## Topic 3. Timestamping changes in the database using triggers


### Introduction

It can often be useful to know not only when a record is created (see
Lesson 3) but also the last time that a record has been modified and
who modified it. This is important to keep track of what happens in
the database. This can be achieved using two powerful tools: functions
and triggers.

A
[function](http://www.postgresql.org/docs/devel/static/xfunc-sql.html)
is a program code that is implemented inside the database using SQL or
a set of other languages (e.g. SQL, PSQL, Python, C). Functions allow
you to create complex processes and algorithms when SQL queries alone
cannot do the job. Once created, a function becomes part of the
database library and can be called inside SQL queries. In the
framework of these lessons, you do not need to create your own
functions, but you must be aware of the possibility offered by these
tools and be able to understand and use existing functions that
advanced users can adapt according to their specific needs.

A [trigger](http://www.postgresql.org/docs/devel/static/triggers.html)
is a specification that the database should automatically execute a
particular function whenever a certain type of operation is performed
on a particular table in the database. The trigger fires a specific
function to perform some actions BEFORE or AFTER records are DELETED,
UPDATED, or INSERTED in a table. The trigger function must be defined
before the trigger itself can be created. The trigger function must be
declared as a function taking no arguments and returning type
trigger. For example, when you insert a new record in a table, you can
modify the values of the attributes before they are uploaded or you
can update another table that should be affected by this new
upload. It is important to stress that triggers are very powerful
tools for automating the data flow. The drawback is that they will
slow down the data import process. This note is also valid for
indexes, which speed up queries but imply some additional computation
during the import stage. In the case of frequent uploads (or
modification) of very large data sets at once, the use of the proposed
triggers could significantly decrease performance. In these cases, you
can more quickly process the data in a later stage after they are
imported into the database and therefore available to users. The best
approach must be identified according to the specific goals,
constraints, and characteristics of your application. In this guide,
we use as reference the management of data coming from a set of
sensors deployed on animals, transmitting data in near real time,
where the import step will include just few thousand locations at a
time.


### Example

It might be convenient to store all functions and ancillary tools in a
defined schema:

```sql
CREATE SCHEMA tools
  AUTHORIZATION postgres;
  GRANT USAGE ON SCHEMA tools TO basic_user;
```

```sql
COMMENT ON SCHEMA tools 
IS 'Schema that hosts all the functions and ancillary tools used for the database.';
```

```sql
ALTER DEFAULT PRIVILEGES 
  IN SCHEMA tools 
  GRANT SELECT ON TABLES 
  TO basic_user;
```

Here a simple example of an SQL function that makes the sum of two
input integers:

```sql
CREATE FUNCTION tools.test_add(integer, integer) 
  RETURNS integer AS 
'SELECT $1 + $2;'
LANGUAGE SQL
IMMUTABLE
RETURNS NULL ON NULL INPUT;
```

The variables *$1* and *$2* are the first and second input
parameters. You can test it with

```sql
SELECT tools.test_add(2,7);
```

The result is '9'.

As a first simple example of a trigger, you add a field to the table
*gps\_data\_animals* where you register the timestamp of the last
modification (update) of each record in order to keep track of the
changes in the table. This field can have *now()*as default when data
is inserted the first time:

```sql
ALTER TABLE main.gps_data_animals 
  ADD COLUMN update_timestamp timestamp with time zone DEFAULT now();
```

Once you have created the field, you need a function called by a
trigger to set this field to the timestamp of the change time whenever
a record is updated. The SQL to generate the function is:

```sql
CREATE OR REPLACE FUNCTION tools.timestamp_last_update()
RETURNS trigger AS
$BODY$BEGIN
IF NEW IS DISTINCT FROM OLD THEN
  NEW.update_timestamp = now();
END IF;
RETURN NEW;
END;$BODY$
LANGUAGE plpgsql VOLATILE
COST 100;
```

```sql
COMMENT ON FUNCTION tools.timestamp_last_update() 
IS 'When a record is updated, the update_timestamp is set to the current time.';
```

Here is the code for the trigger that calls the function:

```sql
CREATE TRIGGER update_timestamp
  BEFORE UPDATE
  ON main.gps_data_animals
  FOR EACH ROW
  EXECUTE PROCEDURE tools.timestamp_last_update();
```

You have to initialize the existing records in the table, as the
trigger/function was not yet created when data were uploaded:

```sql
UPDATE main.gps_data_animals 
  SET update_timestamp = now();
```

Another interesting application of triggers is the automation of the
*acquisition\_time* computation when a new record is inserted into the
*gps\_data* table:

```sql
CREATE OR REPLACE FUNCTION tools.acquisition_time_update()
RETURNS trigger AS
$BODY$BEGIN
  NEW.acquisition_time = ((NEW.utc_date + NEW.utc_time) at time zone 'UTC');
  RETURN NEW;
END;$BODY$
LANGUAGE plpgsql VOLATILE
COST 100;
```

```sql
COMMENT ON FUNCTION tools.acquisition_time_update() 
IS 'When a record is inserted, the acquisition_time is composed from utc_date and utc_time.';
```

```sql
CREATE TRIGGER update_acquisition_time
  BEFORE INSERT
  ON main.gps_data
  FOR EACH ROW
  EXECUTE PROCEDURE tools.acquisition_time_update();
```


### Exercise

1.  Create an *update\_timestamp* field on
    *main.gps\_sensors\_animals*;
2.  Create and populate a new field *update\_user* on
    *main.gps\_data\_animals* to identify the last
    [user](http://www.postgresql.org/docs/devel/static/functions-info.html)
    who modified the record.


## Supplementary code: Automation of the GPS data association with animals

**NOTE:** *This section (supplementary code) is meant to provide
advanced examples of how database tools can be used to improve the
management of tracking data. The code itself is introduced to
illustrate the goals and functionalities but the technical details are
not explained because they require an advanced knowledge of database
programming. The idea is that this supplementary code can be used as
it is or as a study example for they who want to explore and learn
advances features offered by spatial database.*

In the case of a large number of sensors and animals, the association
of locations to animals is hard to manage manually, and usually
requires some dedicated, and possibly automated, tools. Moreover, the
process of associating GPS positions and animals must be able to
manage dynamic changes in the information about sensor deployment. For
example, hours or even days can pass before the death of an animal
tagged with a GPS sensor is discovered. In the while, the GPS
positions acquired in near real time are associated with the
animal. This is an error, as the positions recorded between the death
and its detection by researchers are not valid and must be
'disassociated' from the animal. A tool to automatically and
dynamically update the association between animals and GPS location
based on the information stored in the table on sensors deployment
would also efficiently manages the re-deployment of a GPS sensor
recovered from an animal (because of e.g. end of battery or death of
the animal) to another animal, and the deployment of a new GPS sensor
on an animal previously monitored with another GPS sensor.

With triggers and functions, you can automatize the upload from
*gps\_data* to *gps\_data\_animals* of records that are associated
with animals (a sensor deployed on an animal). First, you have to
create the function that will be called by the trigger:

```sql
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
```

```sql
COMMENT ON FUNCTION tools.gps_data2gps_data_animals() 
IS 'Automatic upload data from gps_data to gps_data_animals.';
```

Then, you create a trigger that calls the function whenever a new
record is uploaded into \*gps\_data\*:

```sql
CREATE TRIGGER trigger_gps_data_upload
  AFTER INSERT
  ON main.gps_data
  FOR EACH ROW
  EXECUTE PROCEDURE tools.gps_data2gps_data_animals();
```

```sql
COMMENT ON TRIGGER trigger_gps_data_upload ON main.gps_data
IS 'Upload data from gps_data to gps_data_animals whenever a new record is inserted.';
```

You can test this function by adding the last GPS sensor not yet
imported:

```sql
COPY main.gps_data(
  gps_sensors_code, line_no, utc_date, utc_time, lmt_date, lmt_time, ecef_x, ecef_y, ecef_z, latitude, longitude, height, dop, nav, validated, sats_used, ch01_sat_id, ch01_sat_cnr, ch02_sat_id, ch02_sat_cnr, ch03_sat_id, ch03_sat_cnr, ch04_sat_id, ch04_sat_cnr, ch05_sat_id, ch05_sat_cnr, ch06_sat_id, ch06_sat_cnr, ch07_sat_id, ch07_sat_cnr, ch08_sat_id, ch08_sat_cnr, ch09_sat_id, ch09_sat_cnr, ch10_sat_id, ch10_sat_cnr, ch11_sat_id, ch11_sat_cnr, ch12_sat_id, ch12_sat_cnr, main_vol, bu_vol, temp, easting, northing, remarks)
FROM 
  'C:\tracking_db\data\sensors_data\GSM02927.csv' 
  WITH (FORMAT csv, HEADER, DELIMITER ';');
```

Data are automatically processed and imported into the table
*gps\_data\_animals* including the correct association with the animal
wearing the sensor.


## Supplementary code: Consistency checks on the deployments information

The management of the association between animals and GPS sensors can
be further improved using additional, more sophisticated tools. A
first example is the implementation of consistency checks on the
*gps\_sensors\_animals* table. You already created a check to ensure
that the *start\_date* &lt; *end\_date*, but this is not enough to
prevent illogical associations between animals and sensors. The two
most evident constraints are that the same sensor cannot be worn by
two animals at the same time, and that no more than one GPS sensor can
be deployed on the same animal at the same time (this assumption can
be questionable in case of other sensors, but in general can be
considered valid for GPS). To avoid any impossible overlaps in
animal/sensor deployments, you have to create a trigger on both
insertion and updates of records in *gps\_animals\_sensors* that
verifies the correctness of the new values (i.e. the new deployment
interval is not in conflict with other existing
deployments). [NEW](http://www.postgresql.org/docs/devel/static/plpgsql-trigger.html)
in a BEFORE INSERT/UPDATE trigger refers to the values that are going
to be inserted. In an UPDATE/DELETE trigger,
[OLD](http://www.postgresql.org/docs/devel/static/plpgsql-trigger.html)
refers to the value that is going to be modified. In case of invalid
values, the insert/modify statement is aborted and an error message is
raised by the database. Here is an example of code for this function:

```sql
CREATE OR REPLACE FUNCTION tools.gps_sensors_animals_consistency_check()
RETURNS trigger AS
$BODY$
DECLARE
  deletex integer;
BEGIN

SELECT 
  gps_sensors_animals_id 
INTO 
  deletex 
FROM 
  main.gps_sensors_animals b
WHERE
  (NEW.animals_id = b.animals_id OR NEW.gps_sensors_id = b.gps_sensors_id)
  AND
  (
  (NEW.start_time > b.start_time AND NEW.start_time < b.end_time)
  OR
  (NEW.start_time > b.start_time AND b.end_time IS NULL)
  OR
  (NEW.end_time > b.start_time AND NEW.end_time < b.end_time)
  OR
  (NEW.start_time < b.start_time AND NEW.end_time > b.end_time)
  OR
  (NEW.start_time < b.start_time AND NEW.end_time IS NULL )
  OR
  (NEW.end_time > b.start_time AND b.end_time IS NULL)
);

IF deletex IS not NULL THEN
  IF TG_OP = 'INSERT' THEN
    RAISE EXCEPTION 'This row is not inserted: Animal-sensor association not valid: (the same animal would wear two different GPS sensors at the same time or the same GPS sensor would be deployed on two animals at the same time).';
    RETURN NULL;
  END IF;
  IF TG_OP = 'UPDATE' THEN
    IF deletex != OLD.gps_sensors_animals_id THEN
      RAISE EXCEPTION 'This row is not updated: Animal-sensor association not valid (the same animal would wear two different GPS sensors at the same time or the same GPS sensor would be deployed on two animals at the same time).';
      RETURN NULL;
    END IF;
  END IF;
END IF;

RETURN NEW;
END;
$BODY$
LANGUAGE plpgsql VOLATILE
COST 100;
```

```sql
COMMENT ON FUNCTION tools.gps_sensors_animals_consistency_check() 
IS 'Check if a modified or insert row in gps_sensors_animals is valid (no impossible time range overlaps of deployments).';
```

Here is an example of the trigger to call the function:

```sql
CREATE TRIGGER gps_sensors_animals_changes_consistency
  BEFORE INSERT OR UPDATE
  ON main. gps_sensors_animals
  FOR EACH ROW
  EXECUTE PROCEDURE tools.gps_sensors_animals_consistency_check();
```

You can test this process by trying to insert a deployment of a GPS
sensor in the `gps_sensors_animals` table in a time interval that
overlaps the association of the same sensor on another animal:

```sql
INSERT INTO main.gps_sensors_animals
  (animals_id, gps_sensors_id, start_time, end_time, notes)
VALUES
  (2,2,'2004-10-23 20:00:53 +0','2005-11-28 13:00:00 +0','Ovelapping sensor');
```

You should receive an error message like:

```
> **\*\*\**** Error ***\*\**\**** ERROR: This row is not inserted:
Animal-sensor association not valid: (the same animal would wear two
different GPS sensors at the same time or the same GPS sensor would be
deployed on two animals at the same time). SQL state: P0001
```


## Supplementary code: Synchronization of *gps\_sensors\_animals* and *gps\_data\_animals*

In an operational environment where data are managed in (near) real
time, it happens that the information about the association between
animals and sensors changes over time. A typical example is the death
of an animal: this event is usually discovered with a delay of some
days. In the meantime, GPS positions are received and associated with
the animals in the *gps\_data\_animals* table. When the new
information on the deployment time range is registered
in*gps\_sensors\_animals*, the table *gps\_data\_animals* must be
changed accordingly. It is highly desirable that any change in the
table *gps\_sensors\_animals* is automatically reflected in
*gps\_data\_animals*. It is possible to use triggers to keep the two
tables automatically synchronized in real time. Here below you have an
example of a trigger function to implement this procedure. The code is
fairly complex because it manages the three possible operations:
delete, insert, and modification of the *gps\_sensors\_animals*
table. For each case, it checks whether GPS positions previously
associated with an animal are no longer valid (and if so, deletes them
from the table *gps\_data\_animals*) and whether GPS positions
previously not associated with the animal should now be linked (and if
so, adds them to the table*gps\_data\_animals*).

```sql
CREATE OR REPLACE FUNCTION tools.gps_sensors_animals2gps_data_animals()
RETURNS trigger AS
$BODY$ begin

IF TG_OP = 'DELETE' THEN

  DELETE FROM 
    main.gps_data_animals 
  WHERE 
    animals_id = OLD.animals_id AND
    gps_sensors_id = OLD.gps_sensors_id AND
    acquisition_time >= OLD.start_time AND
    (acquisition_time <= OLD.end_time OR OLD.end_time IS NULL);
  RETURN NULL;

END IF;

IF TG_OP = 'INSERT' THEN

  INSERT INTO 
    main.gps_data_animals (gps_sensors_id, animals_id, acquisition_time, longitude, latitude)
  SELECT 
    NEW.gps_sensors_id, NEW.animals_id, gps_data.acquisition_time, gps_data.longitude, gps_data.latitude
  FROM 
    main.gps_data, main.gps_sensors
  WHERE 
    NEW.gps_sensors_id = gps_sensors.gps_sensors_id AND
    gps_data.gps_sensors_code = gps_sensors.gps_sensors_code AND
    gps_data.acquisition_time >= NEW.start_time AND
    (gps_data.acquisition_time <= NEW.end_time OR NEW.end_time IS NULL);
  RETURN NULL;

END IF;

IF TG_OP = 'UPDATE' THEN

  DELETE FROM 
    main.gps_data_animals 
  WHERE
    gps_data_animals_id IN (
      SELECT 
        d.gps_data_animals_id 
      FROM
        (SELECT 
          gps_data_animals_id, gps_sensors_id, animals_id, acquisition_time 
        FROM 
          main.gps_data_animals
        WHERE 
          gps_sensors_id = OLD.gps_sensors_id AND
          animals_id = OLD.animals_id AND
          acquisition_time >= OLD.start_time AND
          (acquisition_time <= OLD.end_time OR OLD.end_time IS NULL)
        ) d
      LEFT OUTER JOIN
        (SELECT 
          gps_data_animals_id, gps_sensors_id, animals_id, acquisition_time 
        FROM 
          main.gps_data_animals
        WHERE 
          gps_sensors_id = NEW.gps_sensors_id AND
          animals_id = NEW.animals_id AND
          acquisition_time >= NEW.start_time AND
          (acquisition_time <= NEW.end_time OR NEW.end_time IS NULL) 
        ) e
      ON 
        (d.gps_data_animals_id = e.gps_data_animals_id)
      WHERE e.gps_data_animals_id IS NULL);

  INSERT INTO 
    main.gps_data_animals (gps_sensors_id, animals_id, acquisition_time, longitude, latitude) 
  SELECT 
    u.gps_sensors_id, u.animals_id, u.acquisition_time, u.longitude, u.latitude 
  FROM
    (SELECT 
      NEW.gps_sensors_id AS gps_sensors_id, NEW.animals_id AS animals_id, gps_data.acquisition_time AS acquisition_time, gps_data.longitude AS longitude, gps_data.latitude AS latitude
    FROM 
      main.gps_data, main.gps_sensors
    WHERE 
      NEW.gps_sensors_id = gps_sensors.gps_sensors_id AND 
      gps_data.gps_sensors_code = gps_sensors.gps_sensors_code AND
      gps_data.acquisition_time >= NEW.start_time AND
      (acquisition_time <= NEW.end_time OR NEW.end_time IS NULL)
    ) u
  LEFT OUTER JOIN
    (SELECT 
      gps_data_animals_id, gps_sensors_id, animals_id, acquisition_time 
    FROM 
      main.gps_data_animals
    WHERE 
      gps_sensors_id = OLD.gps_sensors_id AND
      animals_id = OLD.animals_id AND
      acquisition_time >= OLD.start_time AND
      (acquisition_time <= OLD.end_time OR OLD.end_time IS NULL)
    ) w
  ON 
    (u.gps_sensors_id = w.gps_sensors_id AND 
    u.animals_id = w.animals_id AND 
    u.acquisition_time = w.acquisition_time )
  WHERE 
    w.gps_data_animals_id IS NULL;
  RETURN NULL;

END IF;

END;$BODY$
LANGUAGE plpgsql VOLATILE
COST 100;
```

```sql
COMMENT ON FUNCTION tools.gps_sensors_animals2gps_data_animals() 
IS 'When a record in gps_sensors_animals is deleted OR updated OR inserted, this function synchronizes this information with gps_data_animals.';
```

Here is the code of the trigger to call the function:

```sql
CREATE TRIGGER synchronize_gps_data_animals
  AFTER INSERT OR UPDATE OR DELETE
  ON main.gps_sensors_animals
  FOR EACH ROW
  EXECUTE PROCEDURE tools.gps_sensors_animals2gps_data_animals();
```


## Summary exercise of Lesson 4

1.  Calculate the average longitude and latitude of all females.
2.  Calculate the dates and location (latitude and longitude) of the
    first and last collected location per animal.
3.  Create a view that returns, for each animal, the number of non
    null locations, the number of null locations, and the start and
    end date of the deployment.
4.  Create a function that returns the number of minutes to the next
    coffee break.





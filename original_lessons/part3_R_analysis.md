# Part 3. Analyzing data in the R environment

% Lesson 13. There and back again – part I: Analyzing movement data in the R statistical environment
% 9 June 2016


## Introduction

Until now, we explored the wide set of tools that PostgreSQL and
PostGIS offer to process and analyse tracking data. Nevertheless, a
database is not specifically designed to perform advanced statistical
analysis or to implement complex analytical algorithms, which are key
elements to extract scientific knowledge from the data for both
fundamental and applied research. In fact, these functionalities must
be part of an information system that aims at a proper handling of
wildlife tracking data. The possibility of a tighter integration of
analytical functions with the database is particularly interesting
because the availability of large amounts of information from the new
generation sensors blurs the boundary between data analysis and data
management. Tasks like outlier filtering, real-time detection of
specific events (e.g. virtual fencing), or meta-analysis (analysis of
results of a first analytical step, e.g. variation in home range size
in the different months of a year) are clearly in the overlapping area
between data analysis and management.

To analyse data, and movement data in particular, R is probably the
best solution. R is an open source programming language and
environment for statistical computing and graphics
(http://www.r-project.org/). It is a popular choice for data analysis
in academics, with its popularity for ecological research increasing
rapidly.  One of the main strengths of R is the availability of a
large range of packages or libraries for specific applications, which
cover virtually every field of research. For the analysis of animal
tracking data, we often use functions from the adehabitat family which
consists of four packages:
* `adehabitatMA`: management of raster maps;
* `adehabitatLT`: analysis of trajectories;
* `adehabitatHR`: home range estimation;
* `adehabitatHS`: habitat-selection analysis.

Other packages will be useful for this lesson:
* `sp`: spatial data in R;
* `raster`: special package for raster data;
* `lubridate`: management of dates/timestamps in R;
* `RPostgreSQL`: connection to PostgreSQL.

We will also need the package `devtools` to access packages hosted on GitHub.

Let's install all necessary packages right now:

```r
install.packages(c("adehabitatHS", "raster", "lubridate", "RPostgreSQL", "devtools"))
```

Finally, we install the packages `basr` and `hab` directly from
GitHub, with the help of `devtools`:

```r
library("devtools")
install_github("basille/basr")
install_github("basille/hab")
```


## Topic 1: Trajectories in R

For the analysis of movement data, we will mostly rely on the class
`ltraj` from the `adehabitatLT` package. This class is intended to
store trajectories of animals. Trajectories of type I correspond to
trajectories for which the time has not been recorded (e.g.  sampling
of tracks in the snow). Trajectories of type II correspond to
trajectories for which the time is available for each relocation
(mainly GPS and radio-tracking), that is the focus of this week.

Let's build step by step a `ltraj` object using an example data set
provided in the package (wild boar tracking data in southern
France). We first load the package and the data:

```r
library("hab")
data(puechabonsp)
```

Then check what we have in this dataset:

```r
names(puechabonsp)
```

We first extract the maps themselves, and plot them:

```r
(map <- puechabonsp$map)
mimage(puechabonsp$map)
```

We now extract the location dataset, and explore it a bit:

```r
locs <- puechabonsp$relocs
summary(locs)
head(locs)
image(puechabonsp$map)
points(locs, pch = 20, col = locs$Name)
```

The column for dates is not stored in a class that is recognized as
such in R. We need to do it now, using the package `lubridate`:


```r
class(locs$Date)
library("lubridate")
locs$Date <- ymd(paste0("19", locs$Date), tz = "UTC")
head(locs$Date)
class(locs$Date)
```

We can now store the data into a `ltraj` object, using the `as.ltraj`
function, and explore the structure of this object:

```r
(tr1 <- as.ltraj(coordinates(locs), date = locs$Date, id = locs$Name))
class(tr1)
tr1[[1]]
str(tr1[[1]])
```

This allows us to display each individual trajectory:

```r
plot(tr1, spixdf = map)
plot(tr1, by = "none", spixdf = map, ppar = list(col = c(Brock = "blue", Calou = "orange", Chou = "green", Jean = "red"), pch = 20), lpar = list(col = c(Brock = "blue", Calou = "orange", Chou = "green", Jean = "red")))
```

We can quickly look at the distribution of step lengths:

```r
dtr1 <- ld(tr1)
head(dtr1)
hist(dtr1$dist, breaks = 20, freq = FALSE, xlab = "Step length", main = "Histogram of wild boar step lengths")
lines(density(dtr1$dist, na.rm = TRUE), lwd = 3)
```

... and turning angles (using a circular histogram):

```r
rose.diag(na.omit(dtr1$rel.angle), bins = 18, prop = 1.5)
```


### Exercise

You will now import in R all location data from the database, and
build them into a `ltraj` object. Import and export will be the
subject of another lesson, let's just do it now once and for all
without more explanations:

```r
library("RPostgreSQL")
drv <- dbDriver("PostgreSQL")
con <- dbConnect(drv, dbname = "gps_tracking_db", host = "localhost", user = "<user>", password = "<password>")
query <- "SELECT animals_id, acquisition_time, longitude, latitude, ST_X(ST_Transform(geom, 32632)) as x, ST_Y(ST_Transform(geom, 32632)) as y, roads_dist, corine_land_cover_code, altitude_srtm FROM main.gps_data_animals;"
locs2 <- dbGetQuery(con, query)
head(locs2)
```

You will now build the `ltraj`, with the name `tr2`, and only keep
individual #5. If you manage to do it properly, try to explore
dynamically the trajectory with the function `trajdyn`, and play with
the different parameters:

```r
trajdyn(tr2)
```


## Topic 2: Cleaning trajectories

Assuming that there are only valid points in the trajectory, there is
generally two things that need to be addressed: missing values and
exact timestamps. Both are related to the temporal aspect of
movement. Let's thus look at the temporal interval between every
location, in days:

```r
plotltr(tr1, "dt/3600/24")
```

For Chou, there is a huge gap in the middle, because the individual
was monitored two successive summers. We thus create two bursts for
this individual, one per summer:

```r
tr1 <- cutltraj(tr1, "dt > 100*3600*24", nextr = TRUE)
plotltr(tr1, "dt/3600/24")
```

As we can see, although there is supposed to be one day in between
successive locations, there can be up to 8 days in between. To
'regularize' the trajectory, we thus need to add missing values (NAs)
in the trajectory for those days where there is no data. For this, we
need to use the function `setNA` with a reference date (which will be
the oldest date of the dataset):

```r
min(locs$Date)
(ref <- dmy("29071992", tz = "UTC"))
(tr1 <- setNA(tr1, ref, 1, units = "day"))
plotltr(tr1, "dt/3600/24")
head(tr1[[1]])
```

The intervals are now perfectly regular, with one day in between
successive relocations. We can also see where NAs have been placed
(this could be the subject of a separate analysis!):

```r
plotNAltraj(tr1, addlines = FALSE, ppar = list(pch = 15))
```

### Exercise

You will first start by checking and adding missing data in the roe
deer dataset (`tr2`). Are the missing data randomly distributed in the
trajectory? (look up the function `runsNAltraj`)

Now, the wild boar dataset does not include the time of the day: the
temporal precision is the day. In the case of more precise times, like
for the roe deer case, the recorded time will generally not be the
exact scheduled time: the GPS needs some time to find a location. For
instance, if the GPS is programmed to take one relocation precisely at
2:00, it will probably do it a few minutes later, maybe at 2:03:24. To
have a perfectly regular trajectory, we thus need to round the
recorded times to the expected times. You will do it on the roe deer
dataset (`tr2`), using the `sett0` function.


## Topic 3: Interpolation in time and space 

In this section, we are going to interpolate in time and in
space. Let's start by interpolation in time, i.e. linear
interpoloation of missing locations:

```r
(tr1t <- redisltraj(na.omit(tr1), 3600*24, type = "time"))
col <- ifelse(is.na(tr1[[2]]$x), "white", "black")
plot(tr1t[2], ppar = list(pch = 21, col = "black", bg = list(Calou.1 = col[-length(col)])))
```

In a second step, we interpolate in space, that is we rediscretize the
trajectory with constant step length of 100 m:

```r
summary(dtr1$dist)
(tr1s <- redisltraj(tr1, 100, nnew = 10))
plot(tr1s[2])
```


### Exercise

You will now rediscretize roe deer trajectories with constant step
length approximately equal to the median step length. Does the result
make sense?


## Topic 4: Home ranges

We will now look at home ranges. We will first start with classical
home ranges methods that do not take movement into account, before
incorporating movement information along steps. Let us start with
Minimum Convex Polygons:

```r
tr1sp <- ltraj2spdf(tr1)
summary(tr1sp)
mcp1 <- mcp(tr1sp["id"])
plot(mcp1)
plot(tr1sp, col = as.data.frame(tr1sp)[, "id"], add = TRUE)
```

A second classical approach is kernel home ranges, which estimates a
utilization distribution:

```r
kud1 <- kernelUD(tr1sp["id"], grid = 100, same4all = TRUE)
image(kud1)
image(kud1[[2]])
plot(mcp1[2, ], add = TRUE)
```

Finally, we can estimate home ranges using the Brownian bridge kernel
approach, which incorporates information along movement steps:

```r
liker(tr1, sig2 = 50, rangesig1 = c(1, 10))
kbb1 <- kernelbb(tr1, sig1 = 2, sig2 = 50, grid = 100, same4all = TRUE)
image(kbb1)
image(kbb1[[2]])
plot(mcp1[2, ], add = TRUE)
```

### Exercise

Simply estimate Brownian bridge kernels on the roe deer data set, and
compare it to MCP!



## Topic 5: Random walks

On Wednesday morning, we learned the importance of random walk theory
in movement ecology. Now is the time to put it in practice! We will
start by simulating a simple random walk for 1000 steps

```r
rw1 <- simm.crw(1:1000, r = 0, burst = "RW r = 0")
plot(rw1, addpoints = FALSE)
```

Let's have a look at step length and turning angle distributions:

```r
drw1 <- ld(rw1)
hist(drw1$dist, breaks = 20, freq = FALSE, xlab = "Step length", main = "Histogram of RW step lengths")
lines(density(drw1$dist, na.rm = TRUE), lwd = 3)
rose.diag(na.omit(drw1$rel.angle), bins = 18, prop = 3)
```

We can see the diffusive property of the random walk by increasing the
number of steps to 100000:

```r
rw2 <- simm.crw(1:100000, r = 0, burst = "RW 100000 steps")
plot(rw2, addpoints = FALSE)
```

The next step is to simulate correlated random walks by increasing the
concentration parameter of turning angles (`r`). Remember that the
simple RW is a specific case of CRW:

```r
crw0 <- simm.crw(1:1000, r = 0, id = "CRW0 r = 0 (RW)", h = 8)
crw1 <- simm.crw(1:1000, r = 0.6, id = "CRW1 r = 0.6", h = 5)
crw2 <- simm.crw(1:1000, r = 0.9, id = "CRW2 r = 0.9", h = 2)
crw3 <- simm.crw(1:1000, r = 0.99, id = "CRW3 r = 0.99")
mov <- c(crw0, crw1, crw2, crw3)
plot(mov, addpoints = FALSE)
```

We can also check step length and turning angle distributions:

```r
dcrw2 <- ld(crw2)
hist(dcrw2$dist, breaks = 20, freq = FALSE, xlab = "Step length", main = "Histogram of CRW step lengths")
lines(density(dcrw2$dist, na.rm = TRUE), lwd = 3)
rose.diag(na.omit(dcrw2$rel.angle), bins = 18, prop = 1.5)
```

### Exercise

Now you will generate a Brownian bridge from the point (0,0) to the
point (100,100) using the function `simm.bb`. Try to vary the number
of steps, as well as the end point.

In a second step, simulate several Levy walks using the `simm.levy`
and vary the different parameters to understand their effect.



## Topic 6: Habitat selection

In this section, we will see how to perform a simple approach of Step
Selection Functions. The first step is to create random steps, by
drawing random step lengths and random turning angles within the set
of observed steps:

```r
rdtr2 <- rdSteps(tr2, reproducible = TRUE)
head(rdtr2)
```

The result is a data frame, that we convert to a
SpatialPointsDataFrame using the coordinates at the end of the step:

```r
coordinates(rdtr2) <- data.frame(x = rdtr2$x + rdtr2$dx, y = rdtr2$y + rdtr2$dy)
proj4string(rdtr2) <- "+init=epsg:32632"
plot(rdtr2, pch = 20, cex = 0.2)
segments(x0 = rdtr2@data$x, y0 = rdtr2@data$y, x1 = rdtr2@data$x + rdtr2$dx, y = rdtr2@data$y + rdtr2$dy)
rd1tr2 <- subset(rdtr2, case == 1)
segments(x0 = rd1tr2@data$x, y0 = rd1tr2@data$y, x1 = rd1tr2@data$x + rd1tr2$dx, y = rd1tr2@data$y + rd1tr2$dy, col = "red")
```

The next step is to intersect all steps (observed and random) to the
environmental variables of choice. Here we work with the land cover
(Corine Land Cover) and the elevation (Digital Elevation Model):

```r
library("raster")
corine <- raster("<...>\tracking_db\data\env_data\raster\corine06.tif")
plot(corine)

dem <- raster("<...>\tracking_db\data\env_data\raster\srtm_dem.tif")
plot(dem)
```

We now extract the environmental variables at the end of the step; we
also reclassify the land cover type into a limited number of
categories:

```r
rdtr2@data <- data.frame(rdtr2@data, dem = extract(dem, rdtr2), corine = extract(corine, rdtr2))
table(rdtr2$corine)

library("basr")
(matsimp <- matrix(c(2, 18, 20, 21, 23, 24, 25, 26, 27, 29, 31, 32, "open", "agri", "agri", "agri", "forest", "forest", "forest", "open", "open", "open", "open", "open"), ncol = 2))
rdtr2$corine <- reclass(rdtr2$corine, matsimp, factor = TRUE)
table(rdtr2$corine)
```

Finally, given that the land cover type is a factor (i.e. qualitative
variable), we need to convert it to a set of dummy variables, one of
which will be dropped and used as a reference later:

```r
library("ade4")
rdtr2@data <- data.frame(rdtr2@data, acm.disjonctif(rdtr2@data[, "corine", drop = FALSE]))
head(rdtr2)
```

We can now run the conditional logistic regression on each strata (one
observed step + 10 associated random steps) to check the selection on
these two variables:

```r
library("survival")
ssf1 <- clogit(case ~ dem + corine.forest + corine.open + strata(strata), data = rdtr2, method = "breslow")
summary(ssf1)
```




% Lesson 14. There and back again — part II: Connecting PostGIS and R statistical environment
% 9 June 2016


## Introduction

In the previous lesson, we directly imported data from the PostGIS
database, without paying real attention to the commands. Now in this
lesson, we are going to investigate the benefits and drawbacks of the
various possibilities to import and export data from PostGIS to R and
back.

For this lesson, we are going to use four packages:

* `RPostgreSQL`: provides a standard connection from R to PostgreSQL;
* `rgdal`: access to the GDAL library from R;
* `rgeos`: access to the GEOS library from R;
* `rpostgis`: various functions to interact between R and PostGIS.

Let us install them right away:

```r
install.packages(c("RPostgreSQL", "rgdal", "rgeos"))
library("devtools")
install_github("mablab/rpostgis")
```


## Using `RPostgreSQL`

The most direct approach is to use `RPostgreSQL` to connect to the
database for the whole session, evaluate SQL queries, and import and
export data frames.  The first step involves opening the connection,
and may require username (`user`) and password (`password`) as
additional parameters:

```r
library(RPostgreSQL)
drv <- dbDriver("PostgreSQL")
con <- dbConnect(drv, dbname = "gps_tracking_db", host = "localhost", user = "<user>", password = "<password>")
dbListTables(con)
```


### Import data from PostGIS

The package provide a generic function to import a given table into a
`data.frame`:

```r
(tab <- dbReadTable(con, c("main", "animals")))
class(tab)
str(tab)
```

However, this function is not able to handle geometry columns
properly:

```r
tab <- dbReadTable(con, c("main", "gps_data_animals"))
head(tab)
str(tab)
```

In this case, we need to write a specific query to get only the fields
we want, and in the format we want:

```r
query <- "SELECT * FROM main.animals;"
class(query)
query
(tab <- dbGetQuery(con, query))
class(tab)
str(tab)
```

Let's do it now on the GPS data, and extract the projected coordinates
(UTM):

```r
dbListFields(con, c("main", "gps_data_animals"))
query <- "SELECT animals_id, acquisition_time, longitude, latitude, ST_X(ST_Transform(geom, 32632)) as x, ST_Y(ST_Transform(geom, 32632)) as y, roads_dist, corine_land_cover_code, altitude_srtm
FROM main.gps_data_animals where gps_validity_code = 1;"
locs <- dbGetQuery(con, query)
head(locs)
class(locs)
dim(locs)
```

We can now convert this data frame into a proper spatial object in R:

```r
library(sp)
coordinates(locs) <- c("x", "y")
class(locs)
summary(locs)
```

We could also extract the SRID directly from PostGIS to declare it in
our spatial object, but in this case, we projected the data on the fly
to the UTM coordinates:

```r
query <- "SELECT DISTINCT(ST_SRID(geom)) FROM main.gps_data_animals WHERE geom IS NOT NULL;"
dbGetQuery(con, query)
proj4string(locs) <- CRS("+init=epsg:32632")
summary(locs)
plot(locs, xlim = c(653000, 663000), ylim = c(5093000, 5103000))
```


### Exercise 1: Import steps as ltraj

You should now be able to import locations from the database, and
convert them to a proper `ltraj` object.


### Export data to PostGIS

`RPostgreSQL` also provides functions to export data back to PostGIS.
Let's first load the `puechcirc` dataset as an example:

```r
library(adehabitatHS)
data(puechcirc)
puechcirc
dfpu <- ld(puechcirc)
head(dfpu)
dl(dfpu)
```

We first create a test schema in the database, using the function
`dbSendQuery`.  We can then use it to send the points back to the
database, using the function `dbWriteTable`:

```r
query <- "CREATE SCHEMA test;"
dbSendQuery(con, query)
query <- "COMMENT ON SCHEMA test IS 'Schema for test purpose.';"
dbSendQuery(con, query)
dbWriteTable(con, c("test", "puechcirc"), dfpu)
```

We can now convert the coordinates into a proper geometry in PostGIS,
without forgetting to create a spatial index:

```r
query <- "ALTER TABLE test.puechcirc ADD COLUMN pts_geom geometry(POINT, 32632);"
dbSendQuery(con, query)
query <- "CREATE INDEX puechcirc_pts_geom_idx ON test.puechcirc USING GIST (pts_geom);"
dbSendQuery(con, query)
query <- "UPDATE test.puechcirc SET pts_geom=ST_SetSRID(ST_MakePoint(x, y), 32632)
WHERE x IS NOT NULL AND y IS NOT NULL;"
dbSendQuery(con, query)
query <- "COMMENT ON TABLE test.puechcirc IS 'Telemetry data (as points) from 2 wild boars at Puechabon (from RPostgreSQL).';"
dbSendQuery(con, query)
```


### Exercise 2: Export ltraj to the data base as steps

In this exercise, you will write the queries to send the ltraj back to
the database as steps (i.e. segments of line).


### Exercise 3: Import roads

But there's more than simple tables or points/steps in the
database. You will now try to import the roads (multilines) into R.


## Using `rgdal`

GDAL (Geospatial Data Abstraction Library) is a translator library for
raster and vector geospatial data formats.  It can handle pretty much
every format, grab it from a given source or format and convert it to
another format. The package `rgdal` for R provides bindings for GDAL
in R. We check that PostgreSQL is in the list of supported
formats: 

```r
library(rgdal)
ogrDrivers()
conGDAL <- "PG:dbname=gps_tracking_db host=localhost user=<user> password=<password>"
ogrListLayers(conGDAL)
```

> Unfortunately, there seems to be persistent issues with the use of
> `rgdal` under Windows: in all likelihood, the driver `PostgreSQL`
> will not supported, as the `rgdal` binary provided for Windows only
> contains a limited set of drivers. The only solution seems to build
> `rgdal` from source, which is awfully painful on Windows.


### Import data from PostGIS

We start by reading in location data from the `gps_data_animals`
table:

```r
locs2 <- readOGR(conGDAL, layer = "main.gps_data_animals")
class(locs2)
summary(locs2)
head(locs2)
```

We do some cleaning and only keep relocations with a validity code of
1:

```r
table(locs2$gps_validity_code)
locs2 <- subset(locs2, gps_validity_code == 1)
row.names(locs2) <- 1:nrow(locs2)
dim(locs2)
head(locs2)
```

We can now compare it with the spatial locations imported before with
`RPostgreSQL`:

```r
names(locs)
names(locs2)
names(locs) %in% names(locs2)
locs2 <- subset(locs2, select = names(locs))

proj4string(locs)
proj4string(locs2)
locs2 <- spTransform(locs2, CRS("+init=epsg:32632"))

all.equal(locs, locs2)

locs@bbox
locs2@bbox

head(locs@coords)
head(locs2@coords)

locs@coords.nrs
locs2@coords.nrs
```


### Exercise 4: Import GIS layers

Using `readOGR`, import the road shapefile, and plot it with the
locations on top.  Try to do the same for a raster layer, using
`readGDAL`.


### Export data to PostGIS

Since GDAL works in both directions, we can use it to send spatial
objects from R to the database. As an example, we export the points
from the `puechcirc` trajectory into PostGIS. We first prepare it as a
`SpatialPointsDataFrame`, with the correct projection:

```r
pusp <- ltraj2spdf(puechcirc)
class(pusp)
summary(pusp)
proj4string(pusp) <- CRS("+init=epsg:32632")
summary(pusp)
```

And then use `writeOGR` to export it to PostGIS, into
`test.puechcircsp`:

```r
writeOGR(pusp, conGDAL, driver = "PostgreSQL", layer = "test.puechcircsp2")
query <- "COMMENT ON TABLE test.puechcircsp IS 'Telemetry data (as points) from 2 wild boars at Puechabon (from rgdal).';"
dbSendQuery(con, query)
```


### Exercise 5: Send back a trajectory to the data base

In this exercise, you will export the `puechcirc` trajectory (a
`ltraj`) to the database as lines. Using `ltraj2sldf` from the package
`hab`, you will do it in two versions:

* One line per animal;
* One line per step.


## Using `rgeos`

GEOS (Geometry Engine - Open Source) is a library that provide a
complete set of spatial features on geometries, such as spatial
predicate functions and spatial operators. It complements GDAL by
providing many additional tools. The package `rgeos` provides bindings
for GEOS in R.

One key feature of GEOS is that it is able to handle well-known text
(WKT) representations. We can thus use it to import/export complex
geometries that can not be handled manually. We start by importing a
simple point, which defines the city of Terlago in Northern Italy:

```r
library(rgeos)
(terlago <- readWKT("POINT(11.001 46.001)"))
(terlago <- readWKT("POINT(11.001 46.001)", p4s = CRS("+init=epsg:4326")))
(terlago <- spTransform(terlago, CRS("+init=epsg:32632")))

plot(locs, xlim = c(653000, 663000), ylim = c(5093000, 5103000))
plot(terlago, add = TRUE, col = "red", pch = 20, cex = 2)
```

Of course, PostGIS also provides functions to convert any geometry to
its WKT representation. We can thus use it before importing the data
(note that we could also query the SRID from PostGIS!):

```r
query <- "SELECT ST_AsText(ST_MakePoint(11.001,46.001)) AS terlago;"
(terlago <- dbGetQuery(con, query))
(terlago <- readWKT(dbGetQuery(con, query), p4s = CRS("+init=epsg:4326")))
```

PostGIS also provides a function `AsEWKT`, which returns the WKT
representation of the geometry with SRID meta data. That could be very
useful, but as we will see, this is not a standard yet, and `readWKT`
is unable to process it:

```r
query <- "SELECT ST_AsText(ST_Transform(ST_SetSRID(ST_MakePoint(11.001,46.001), 4326), 32632)) AS terlago;"
(terlago <- dbGetQuery(con, query))
readWKT(terlago)
readWKT(terlago, p4s = CRS(paste0("+init=epsg:32632")))

query <- "SELECT ST_AsEWKT(ST_Transform(ST_SetSRID(ST_MakePoint(11.001,46.001), 4326), 32632)) AS terlago;"
(terlago <- dbGetQuery(con, query))
readWKT(terlago)
```


### Exercise 6: Import roads as WKT

You will now import the roads again, this time using the WKT representation.


### Export data to PostGIS

`rgeos` also provides the corresponding function to convert a geometry
to its WKT representation: `writeWKT`. We can thus use it to export
any spatial object from R to PostGIS. We try to do it on the road
network. Since everything is a table in PostgreSQL, we need to put
it in a dataframe first: 

```r
roadsdf <- data.frame(roads = writeWKT(roads, byid = TRUE))
dim(roadsdf)
```

We can then export it and create a new table `test.roads` using
`dbWriteTable` (from `RPostgreSQL`). We need to declare a new column
`lin_geom` before updating it with the WKT representations:

```r
dbWriteTable(con, c("test", "roads"), roadsdf)

query <- "ALTER TABLE test.roads ADD COLUMN lin_geom geometry(LINESTRING, 32632);"
dbSendQuery(con, query)

query <- "UPDATE test.roads SET lin_geom=ST_GeomFromText(roads, 32632);"
dbSendQuery(con, query)

query <- "COMMENT ON TABLE test.roads IS 'Roads (as lines) in the study area (from rgeos).';"
dbSendQuery(con, query)
```


### Exercise 7: Send back a trajectory to the data base

As in exercise 5, you will export the `puechcirc` trajectory to the
databases, one line per animal and one line per step, using functions
from `rgeos` this time, instead of `rgdal`.


## Using `rpostgis`

The package `rpostgis` is an attempt at facilitating the connection
bewteen R and PostGIS. To this aim, it introduces wrappers to common
database procedures (e.g. `pgAddKey`, `pgSchema`, `pgComment`, etc.),
as well as functions dedicated to handling spatial features. The one
demonstrated here is `pgGetPts`, to import a POINTS geometry into a
SpatialPointsDataFrame. The function allows to select a number of
columns, which are passed into the SPDF's data. We use it to import
roe deer GPS data into `locs3`:

```r
library(rpostgis)

locs3 <- pgGetPts(con, c("main", "gps_data_animals"), pts = "geom", colname = c("animals_id", "acquisition_time", "longitude", "latitude", "roads_dist", "corine_land_cover_code", "altitude_srtm", "gps_validity_code"))
summary(locs3)
```

We then subset the valid points and reproject them to UTM 32, in order
to compare them to the locations imported at the very beginning of
this lesson (in `locs`):

```r
locs3 <- subset(locs3, gps_validity_code == 1, select = -gps_validity_code)
row.names(locs3) <- 1:nrow(locs3)
dim(locs3)

proj4string(locs3)
locs3 <- spTransform(locs3, CRS("+init=epsg:32632"))

all.equal(locs, locs3)
```

This package, in active development, will notably include functions to
export points into the database, as well as a companion package to
import/export trajectories as `ltraj` in R. Stay tuned!


## Closure…

Finally, we don't forget to close the connection to the database, as
opened by RPostgreSQL at the beginning of this exercise:

```r
dbDisconnect(con)
```


% Lesson 15. There and back again – part III: Extending PostGIS with Pl/R
% 10 June 2016


## Introduction

Until now, we saw what PostGIS had to offer to process and manage
tracking data, and how R could be used to analyse movement data. We
also explored different ways to transfer data from PostGIS to R and
vice versa, which highlighted the many hurdles and difficulties in
streamlining the workflow. Pl/R is one possible answer to this
problem.

Pl/R is a loadable procedural language that allows the use of the R
engine and libraries directly inside the database, thus embedding R
scripts into SQL statements and database functions and triggers.

This lesson is a simplified version of Chapter 11 ("A Step Further in
the Integration of Data Management and Analysis: Pl/R") from the book
Spatial Database for GPS Wildlife Tracking Data (Urbano & Cagnacci,
2014).


## Getting Started with Pl/R

From now on, we assume that Pl/R is properly installed on your system
(which may be a tricky process). We can then enable Pl/R in the
database, and check the outcome like this:

```sql
CREATE EXTENSION plr;
SELECT * FROM plr_version();
```

Now you can create functions in Pl/R procedural language pretty much
the same way you write functions in R. Indeed, the body of a Pl/R
function uses the R syntax, because it is actually pure R code! A
generic R code snippet such as:

```r
> x <- 10
> 4/3*pi*x^3
```

can be directly embedded into a Pl/R function in PostgreSQL using a
generic function skeleton with the Pl/R language:

```sql
CREATE OR REPLACE FUNCTION tools.plr_fn ()
RETURNS float8 AS
$BODY$
  x <- 10
  4/3*pi*x^3
$BODY$
LANGUAGE 'plr';
```

The function can then be used in an SQL statement:

```sql
SELECT tools.plr_fn ();
```

Fortunately, we can also have more useful pieces of code in Pl/R. In
this workflow, however, we still need to communicate data from the
database to and from R. Pl/R can natively handle several types,
including booleans (converted to `logical` in R), all forms of integer
(converted to `integer`) or numeric (converted to `numeric`) and all
forms of text (converted to `character`).

In a simple example, let's try to compute logarithms. We write a Pl/R
function `r_log` to calculate the logarithm of a sample of numbers
using R:

```sql
CREATE OR REPLACE FUNCTION tools.r_log(float8, float8)
RETURNS float AS
$BODY$
  log(arg1, arg2)
$BODY$
LANGUAGE 'plr';
```

Note that with a Pl/R function, the R engine does the computation, and
PostgreSQL only handles the input and output, so that we can compare
the outputs to the same logarithms computed by PostgreSQL:

```sql
SELECT
  ST_Area(geom) AS area,
  log(ST_Area(geom)) AS pg_log,
  tools.r_log(ST_Area(geom), 10) AS r_log,
  ln(ST_Area(geom)) AS pg_ln,
  tools.r_log(ST_Area(geom), exp(1)) AS r_ln
FROM analysis.view_convex_hulls;      
```

Fortunately, the results seem consistent…



## In the Middle of the Night

One of the most powerful assets of R is its broad and ever-growing
package ecosystem. In this example, you are going to implement a
useful feature concealed in the `maptools` package, which provides a
set of functions able to deal with the position of the sun and compute
crepuscule, sunrise and sunset times for a given location at a given
date. We thus need to install in R the `maptools` package, together
with `rgeos` and `rgdal` packages (which should already be there after
the previous lesson):

```r
install.packages(c("rgeos", "rgdal", "maptools"))
```

Pl/R can communicate basic data types from PostgreSQL and R, but
cannot handle spatial objects. To circumvent this problem, we will use
well-known text (WKT) representations, which are simply passed as text
strings. Here is the daylight function, which returns the sunrise and
sunset times (as a text array) for a spatial point expressed as a WKT,
with its associated SRID, a timestamp to give the date and a time
zone:

```sql
CREATE OR REPLACE FUNCTION tools.daylight(
  wkt text,
  srid integer,
  datetime timestamptz,
  timezone text)
RETURNS text[] AS
$BODY$
  require(rgeos)
  require(maptools)
  require(rgdal)
  pt <- readWKT(wkt, p4s = CRS(paste0("+init=epsg:", srid)))
  dt <- as.POSIXct(substring(datetime, 1, 19), tz = timezone)
  sr <- sunriset(pt, dateTime = dt, direction = "sunrise",
      POSIXct.out = TRUE)$time
  ss <- sunriset(pt, dateTime = dt, direction = "sunset",
      POSIXct.out = TRUE)$time
  return(c(as.character(sr), as.character(ss)))
$BODY$
LANGUAGE 'plr';
```

Let's get the sunrise and sunset times for today, near the
municipality of Terlago, northern Italy. Because R and PostgreSQL use
different time zone formats, you need to pass the time zone to R
literally as `Europe/Rome`:

```sql
SELECT tools.daylight('POINT(11.001 46.001)', 4326, now(), 'Europe/Rome');
```

Let's now modify this function to return a boolean value (`TRUE` or
`FALSE`) indicating whether a given time of the day at a given
location corresponds to daylight or not. This is the purpose of the
`is_daylight` function, which will prove useful to test the daylight
for animal locations:

```sql
CREATE OR REPLACE FUNCTION tools.is_daylight(
  wkt text,
  srid integer,
  datetime timestamptz,
  timezone text)
RETURNS boolean AS
$BODY$
  require(rgeos)
  require(maptools)
  require(rgdal)
  pt <- readWKT(wkt, p4s = CRS(paste0("+init=epsg:", srid)))
  dt <- as.POSIXct(substring(datetime, 1, 19), tz = timezone)
  sr <- sunriset(pt, dateTime = dt, direction = "sunrise",
      POSIXct.out = TRUE)$time
  ss <- sunriset(pt, dateTime = dt, direction = "sunset",
      POSIXct.out = TRUE)$time
  return(ifelse(dt >= sr & dt < ss, TRUE, FALSE))
$BODY$
LANGUAGE 'plr';
```

This function can be used on a single point, e.g. with the same
coordinates as above:

```sql
SELECT tools.is_daylight('POINT(11.001 46.001)', 4326, current_date, 'Europe/Rome');
```

Or it can be used to a series of points, such as the first 10 valid
locations:

```sql
WITH tmp AS (SELECT ('Europe/Rome')::text AS tz)
SELECT
  ST_AsText(geom) AS location,
  acquisition_time AT TIME ZONE tz AS acquisition_time,
  tools.is_daylight(ST_AsText(geom), ST_SRID(geom), acquisition_time AT TIME ZONE tz, tz)
FROM main.gps_data_animals, tmp
WHERE gps_validity_code = 1
LIMIT 10;
```


## Extending the Home Range Concept

In this section, we will embed the function `kernelUD` (from
`adehabitatHR`) to compute kernel home ranges directly from
PostGIS. We start by installing the package in R if necessary:

```r
install.packages("adehabitatHR")
```

We want to be able to produce the home range contours as produced by
the kernel utilization distribution (see the help page for the
function `kernelUD` in R). To do this, we first need to create a new
type `hr` that stores a polygon as a WKT, together with its associated
percentage (e.g. 90% corresponds to the area with a 90% probability of
finding the animal of interest):

```sql
CREATE TYPE tools.hr AS (percent int, wkt text);
```

We thus create the function `tools.kernelud` to compute kernel home
ranges using R:

```sql
CREATE OR REPLACE FUNCTION tools.kernelud (wkt text, percent integer)
RETURNS SETOF tools.hr AS
$BODY$
  require(rgeos)
  require(adehabitatHR)
  geom <- readWKT(wkt)
  kud <- kernelUD(geom)
  return(data.frame(percent = percent, wkt = sapply(percent, function(x)
      writeWKT(getverticeshr(kud, x)))))
$BODY$
LANGUAGE plr;
```

We can now query the table with all animal locations to compute the
kernel home range, for instance for animal 1 at 50, 90, and 95% (note
that we subset only locations with a Y-coordinate greater than
5,000,000):

```sql
WITH tmp AS (SELECT unnest(ARRAY[50,90,95]) AS pc)
SELECT (tools.kernelud(ST_AsText(ST_Collect(ST_Transform(geom, 32632))), pc)).*
FROM main.gps_data_animals, tmp
WHERE animals_id = 1 AND ST_Y(ST_Transform(geom, 32632)) > 5000000
GROUP BY pc
ORDER BY pc;
```

Finally, we can now create a table `analysis.home_ranges_kernelud` to
store the different kernel home ranges and various parameters of
interest:

```sql
CREATE TABLE analysis.home_ranges_kernelud(
  home_ranges_kernelud_id serial NOT NULL,
  animals_id integer NOT NULL,
  start_time timestamp with time zone NOT NULL,
  end_time timestamp with time zone NOT NULL,
  num_locations integer,
  area numeric(13,5),
  geom geometry (multipolygon, 32632),
  percentage double precision,
  insert_timestamp timestamp with time zone DEFAULT now(),
  CONSTRAINT home_ranges_kernelud_pk
    PRIMARY KEY (home_ranges_kernelud_id),
  CONSTRAINT home_ranges_kernelud_animals_fk
    FOREIGN KEY (animals_id)
    REFERENCES main.animals (animals_id) MATCH SIMPLE
    ON UPDATE NO ACTION ON DELETE NO ACTION);
COMMENT ON TABLE analysis.home_ranges_kernelud
IS 'Table that stores the home range polygons derived from kernelUD. The area is computed in squared km.';
CREATE INDEX fki_home_ranges_kernelud_animals_fk
  ON analysis.home_ranges_kernelud
  USING btree (animals_id);
CREATE INDEX gist_home_ranges_kernelud_index
  ON analysis.home_ranges_kernelud
  USING gist (geom);
```

Let us now populate this table using 50 and 90% kernels for all
animals:

```sql
WITH
  tmp AS (SELECT unnest(ARRAY[50,90,95]) AS pc),
  kud AS (
    SELECT
      animals_id,
      min(acquisition_time) AS start_time,
      max(acquisition_time) AS end_time,
      count(animals_id) AS num_locations,
      (tools.kernelud(ST_AsText(ST_Collect(ST_Transform(geom, 32632))), pc)).*
    FROM main.gps_data_animals, tmp
    WHERE ST_X(ST_Transform(geom, 32632)) > 650000
      AND ST_Y(ST_Transform(geom, 32632)) > 5000000
    GROUP BY animals_id,pc
    ORDER BY animals_id,pc)
INSERT INTO analysis.home_ranges_kernelud (animals_id, start_time, end_time,
  num_locations, area, geom, percentage)
SELECT
  animals_id,
  start_time,
  end_time,
  num_locations,
  ST_Area(wkt) / 1000000,
  ST_GeomFromText(wkt, 32632),
  percent / 100.0
FROM kud
ORDER BY animals_id, percent;
```

We can display part of the outcome in this table, for instance to
check that the area is increasing with higher percentage:

```sql
SELECT animals_id, percentage, num_locations, area
FROM analysis.home_ranges_kernelud
ORDER BY animals_id, percentage;
```

… and explore in QGIS the different polygons associated to different
percentages for each animal, with the GPS locations overlaid.


## Concluding remarks

The benefits of Pl/R are obvious: it allows to embed R (and its myriad
of packages) into the database, thus enhancing the database itself
with R superpowers! One of the biggest advantage of this approach is
to streamline procedures that would involve going back and forth from
PostGIS to R: imagine for instance a scenario where you would prepare
a trajectory in PostGIS, import it in R to compute Brownian bridge
kernels, which you would export back to PostGIS to intersect them with
environmental GIS layers (e.g. Corine Land Cover), before sending the
results of the intersection to R again for further analysis… Using
Pl/R, you could easily embed the R functions required to compute
Brownian bridge kernels, and thus having a completely smooth workflow.

The limits of the approach are, unfortunately, exactly the same as for
connecting R to PostGIS: communicating complex spatial objects can be
a real issue (e.g. using `rgdal` or manipulating rasters in
general). However, we can only expect progress in this area.








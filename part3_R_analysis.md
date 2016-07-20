# load data from PostGIS

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
con <- dbConnect(drv, dbname = "gps_tracking_db", host = "localhost", user = "postgres", password = "pgis")
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

Let's do it now on the GPS data, and extract the projected coordinates in an Albers equal area projection for Europe (SRID = 3035).
We'll also extract the acquisiton time at the proper time

```r
dbListFields(con, c("main", "gps_data_animals"))
query <- "SELECT animals_id, acquisition_time, longitude, latitude, ST_X(ST_Transform(geom, 3035)) as x, ST_Y(ST_Transform(geom, 3035)) as y, roads_dist, corine_land_cover_code, altitude_srtm
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
to the Albers coordinates:

```r

##FIX projection or drop this
query <- "SELECT DISTINCT(ST_SRID(geom)) FROM main.gps_data_animals WHERE geom IS NOT NULL;"
dbGetQuery(con, query)
proj4string(locs) <- CRS("+init=epsg:32632")
summary(locs)
plot(locs, xlim = c(653000, 663000), ylim = c(5093000, 5103000))
```


### Exercise 1: Build ltraj from locations in database

The acquistion_time column in the database by default will display
times in your local time zone. Since our dataset is from Italy, we can
change the time zone attribute of the acquisition_time column to the
local time zone in the study area (using the name "Europe/Rome"). This will
ensure that any daylight savings time changes will be incorporated as well:

```r
head(locs$acquisition_time)
attr(locs$acquisition_time,"tzone") <- "Europe/Rome"
locs$acquistion_time<-as.POSIXct(locs$acquisition_time)
head(locs$acquisition_time)
```

We can now store the data into a `ltraj` object, using the `as.ltraj`
function, and explore the structure of this object:

```r
library("adehabitatLT")
(tr1 <- as.ltraj(coordinates(locs), date = locs$acquistion_time, id = locs$animals_id))
class(tr1)
head(tr1[[1]])
str(tr1[[1]])
```

This allows us to display each individual trajectory:

```r
plot(tr1)
```

We can quickly look at the distribution of step lengths:

```r
dtr1 <- ld(tr1)
head(dtr1)
hist(dtr1$dist, breaks = 40, freq = FALSE, xlab = "Step length", main = "Histogram of roe deer step lengths")
lines(density(dtr1$dist, na.rm = TRUE), lwd = 3)
```

... and turning angles (using a circular histogram):

```r
rose.diag(na.omit(dtr1$rel.angle), bins = 18, prop = 1.5)
```

---

# load some other spatial data from database

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

The package `rpostgis` combines the ability to send queries from R (in `RPostgreSQL`)
with the ability to read WKT geometry representations (in `rgeos`) with functions that
can directly load tables in a PostGIS database and convert the to `sp`-package
spatial objects. There are currently functions for loading points (`pgGetPts`),
lines (`pgGetLines`), and polygons (`pgGetPolys`). We can use these functions
to directly load the spatial data into R which we uploaded in the previous lesson.

We'll also use the `sp` function `spTransform` to convert the projections
of each layer to match the Albers projection of the roe deer locations.


### Import spatial data using `rpostgis`

First lets import the `roads` table:

```r
library("rpostgis")
roads<-pgGetLines(con,c("env_data","roads"))
roads<-spTransform(roads, CRS("+init=epsg:3035"))
```

By default the `pgGet*` functions return the full table, resulting in a 
`SpatialLinesDataFrame`, in this case.

Now the administrative boundaries:

```
admin<-pgGetPolys(con,c("env_data","adm_boundaries"))
admin<-spTransform(admin,CRS("+init=epsg:3035"))
```

And finally the weather stations:

```
meteo<-pgGetPts(con,c("env_data","meteo_stations"))
meteo<-spTransform(meteo,CRS("+init=epsg:3035"))
```

We can visually inspect the datasets by overlaying them
and make sure all are projected correctly:
```
plot(admin)
plot(locs,pch=20,cex=1,add=T)
plot(roads,col='red',add=T)
plot(meteo,pch='M',add=T)
```

Note that `sp` objects cannot contain NULL geometries, so if there were
rows missing a geometry in the database (e.g., a relocation where GPS failed
to record a location), those rows would not be included in the imported dataset. If you
needed this data as well (e.g., for trajectory building and analysis), it would be best
to write your our SQL query and use RPostgreSQL to fetch the data, as we 
did earlier in this lesson to build the ltraj `tr1`.

#### Import raster maps

Directly loading raster maps in R from PostGIS is not as
well supported by current R packages. GDAL (Geospatial Data Abstraction Library)
is a translator library for raster and vector geospatial data formats which can handle
pretty much every format, grab it from a given 
source or format and convert it to another format. The package
rgdal for R provides bindings for GDAL in R.

Unfortunately, there seems to be persistent issues with 
the use of rgdal under Windows: in all likelihood,
the driver PostgreSQL will not supported, as the rgdal binary 
provided for Windows only contains a limited set of drivers. 
The only solution seems to build rgdal from source, 
which is awfully painful on Windows.

In place of `rgdal`, the package `rpostgis` does allow 
for importing of raster from PostGIS using `pgGetRast`, though the
process isn't the most efficient; it essentially extracts the 
midpoints and value of each raster cell and rebuilds the raster 
from this information in R. For the smaller
rasters used in this database, though, import is rather quick. Here
we load the land cover and DEM layers, and project the 
DEM to match the projection of the roe deer locations:

```r
library("raster")
corine<-pgGetRast(con,c("env_data","corine_land_cover"))

dem<-pgGetRast(con,c("env_data","srtm_dem"))
dem<-projectRaster(dem,lc,method='bilinear')
```

We can now overlay the points on the rasters:

```r
plot(elev,xlim=as.vector(locs@bbox[1,]),ylim=as.vector(locs@bbox[2,]))
plot(locs,col=locs$animals_id,add=T)

plot(lc,xlim=as.vector(locs@bbox[1,]),ylim=as.vector(locs@bbox[2,]))
plot(locs,col=locs$animals_id,add=T)
```


---

# play around with trajectories

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


You will now build the `ltraj`, with the name `tr2`, and only keep
individual #5. Try to explore dynamically the trajectory with the 
function `trajdyn`, and play with the different parameters:

```r
tr2<-tr1[5]
trajdyn(tr2)
```

# BEGIN section that needs to be modified to use "tr1" ltraj (full roe deer dataset) or "tr2" ltraj (just animal #5)


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


# END Section that needs to be re-worked for a different ltraj 

## Topic 5: Random walks

On Wednesday morning, we learned the importance of random walk theory
in movement ecology. Now is the time to put it in practice! We will
start by simulating a simple random walk for 1000 steps:

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
library("hab")
rdtr2 <- rdSteps(tr2, reproducible = TRUE)
head(rdtr2)
```

The result is a data frame, that we convert to a
SpatialPointsDataFrame using the coordinates at the end of the step:

```r
coordinates(rdtr2) <- data.frame(x = rdtr2$x + rdtr2$dx, y = rdtr2$y + rdtr2$dy)
proj4string(rdtr2) <- "+init=epsg:3035"
plot(rdtr2, pch = 20, cex = 0.2)
segments(x0 = rdtr2@data$x, y0 = rdtr2@data$y, x1 = rdtr2@data$x + rdtr2$dx, y = rdtr2@data$y + rdtr2$dy)
rd1tr2 <- subset(rdtr2, case == 1)
segments(x0 = rd1tr2@data$x, y0 = rd1tr2@data$y, x1 = rd1tr2@data$x + rd1tr2$dx, y = rd1tr2@data$y + rd1tr2$dy, col = "red")
```

The next step is to intersect all steps (observed and random) to the
environmental variables of choice. We now extract the environmental 
variables at the end of the step; we also reclassify the land cover 
type into a limited number of categories:

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


---

# export data back to database

# This section could be modified to send a roe-deer trajectory that was modified above to the database

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
query <- "ALTER TABLE test.puechcirc ADD COLUMN pts_geom geometry(POINT, 3035);"
dbSendQuery(con, query)
query <- "CREATE INDEX puechcirc_pts_geom_idx ON test.puechcirc USING GIST (pts_geom);"
dbSendQuery(con, query)
query <- "UPDATE test.puechcirc SET pts_geom=ST_SetSRID(ST_MakePoint(x, y), 3035)
WHERE x IS NOT NULL AND y IS NOT NULL;"
dbSendQuery(con, query)
query <- "COMMENT ON TABLE test.puechcirc IS 'Telemetry data (as points) from 2 wild boars at Puechabon (from RPostgreSQL).';"
dbSendQuery(con, query)
```

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

query <- "ALTER TABLE test.roads ADD COLUMN lin_geom geometry(LINESTRING, 3035);"
dbSendQuery(con, query)

query <- "UPDATE test.roads SET lin_geom=ST_GeomFromText(roads, 3035);"
dbSendQuery(con, query)

query <- "COMMENT ON TABLE test.roads IS 'Roads (as lines) in the study area (from rgeos).';"
dbSendQuery(con, query)
```


### Exercise 7: Send back a trajectory to the data base

As in exercise 5, you will export the `puechcirc` trajectory to the
databases, one line per animal and one line per step, using functions
from `rgeos` this time, instead of `rgdal`.


## Closure…

Finally, we don't forget to close the connection to the database, as
opened by RPostgreSQL at the beginning of this exercise:

```r
dbDisconnect(con)
```

# Pl/R(?)
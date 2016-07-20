% Installing Pl/R on Windows


## Getting Pl/R

First, download the correct files for your version of PostgreSQL and R
from [here](http://www.joeconway.com/plr/). If you updated prior to
the workshop, this is PostgreSQL 9.5 and R 3.3. Also make sure to
download the the correct bit-level files (32 or 64 bit).

Inside the zip file are a set of files that need to be moved to
certain locations in your system's PostgreSQL folder. The file names
and the places to put, using an example system PostgreSQL folder of
`C:\Program Files\PostgreSQL\9.5`, are:

| file  | place in...  |
|-------------------------------|------------------------------------------------------|
| README.plr  | C:\Program Files\PostgreSQL\9.5\doc\extension\ |
|  plr.dll | C:\Program Files\PostgreSQL\9.5\lib\ |
| plr.sql  | C:\Program Files\PostgreSQL\9.5\share\extension\ |
| plr.control	|	C:\Program Files\PostgreSQL\9.5\share\extension\ |
| plr--8.3.0.14.sql	|	C:\Program Files\PostgreSQL\9.5\share\extension\ |
| plr--unpackaged--8.3.0.16.sql | C:\Program Files\PostgreSQL\9.5\share\extension\ |


## Set the following environment variables

Open control panel and navigate to System -> Advanced System
Settings. In the dialog, click the "Environmental Variables" button on
the bottom.

Append to end of your current `PATH` variable (adjust the paths to
PostgreSQL and R if necessary):

```
C:\Program Files\PostgreSQL\9.5\bin;C:\Program Files\PostgreSQL\9.5\lib;C:\Program Files\R\R-3.3.0\bin\x64;$PATH
```

Create a new variable called `R_HOME` and add the value of your
current R folder:

```
C:\Program Files\R\R-3.3.0\
```


## Restart PostgreSQL

Close all open PostgreSQL connections (pgAdmin, R, anything that is
connected to the server).

Finally, go to your Windows services dialog. You can find this in the
Task Manager, Services Tab. Then Click the "Services" button on the
bottom.

Once inside the services, locate the `postgresql-x64-9.5 - PostgreSQL
Server 9.5` service, and Restart it.


## Enable plr

Once PostgreSQL is restarted, you can go to pgAdmin and connect to a
database. Then execute the command:

```
CREATE EXTENSION plr;
```

This will enable `plr` on that database; if it completes the command,
then everything is likely OK on the PostgreSQL end. To test whether
you can connect to R, use the following commands:

```
SELECT * FROM plr_environ();
SELECT load_r_typenames();
```

If the commands run successfully, you have successfully set up plr; if
they hang (run for a long time but don't finish), you likely have some
environmental variables incorrectly set (go back and check that all
the path names you set in the environmental variables section above
are valid). For more troubleshooting, visit the guide
[here](http://www.bostongis.com/PrinterFriendly.aspx?content_name=postgresql_plr_tut01).

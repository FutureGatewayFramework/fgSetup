# fgapiserver
Docker build scripts for FutureGateway component 'fgapiserver'

## Configuration
The **fgapiserver** component requires the following variables to properly generate its Docker image:

### FutureGateway user
* `FG_USER` Unix username that will manage FutureGateway' components
* `FG_DIR` FutureGateway unix user home directory
### FurtureGateway DB settings
* `MYSQL_ROOT_PASSWORD` root password for FG database
* `FGDB_HOST` FG database host name
* `FGDB_PORT` FG database port number
* `FGDB_USER` FG database user
* `FGDB_PASSWD` FG database user' password
* `FGDB_NAME` Name for FG database
### Environment for scripts
In this section it is possible to point the source code extraction to a particular repository and branch.
* `FGAPISERVER_GIT` Git repository address for fgapiserver
* `FGAPISERVER_BRANCH` Git repository branch for fgapiserver
* `FGSETUP_GIT` Git repository address for FG setup files
* `FGSETUP_BRANCH` Git repository branch for FG setup files
### Environment for **fgapiserver.conf**
* `FGAPIVER` Version of implemented APIs (see [specs](http://docs.fgapis.apiary.io))
* `FGAPISERVER_NAME`  Name of the Flask app
* `FGAPISRV_HOST` Flask app host value (default 0.0.0.0, accepts all hosts) 
* `FGAPISRV_PORT` Flask app listening port number
* `FGAPISRV_DEBUG` Debug operation mode True/False
* `FGAPISRV_IOSANDBOX` Directory used to store task information and files
* `FGAPISRV_GEAPPID` Grid and Cloud engine Application Id
* `FGJSON_INDENT` Indentation level for all readable JSON outputs  
* `FGAPISRV_KEY` Certificate key file path for  Flask operating in https
* `FGAPISRV_CRT` Certificate public key path for Flask operating in https
* `FGAPISRV_LOGCFG` Log file configuration
* `FGAPISRV_DBVER` Needed database schema version
* `FGAPISRV_SECRET` Any secret key used to encrypy/decrypt user Tokens
* `FGAPISRV_NOTOKEN` Flag that switches off Token management (True to disable)
* `FGAPISRV_NOTOKENUSR`  Name of the user adopted when the Token is disabled 
* `FGAPISRV_LNKPTVFLAG` Set this flat to True to enable PTV service
* `FGAPISRV_PTVENDPOINT` Complete endpoint to reach the PTV check token service 
* `FGAPISRV_PTVUSER` PTV basic authentication username
* `FGAPISRV_PTVPASS` PTV basic authentication password 
* `FGAPISRV_PTVDEFUSR` PTV user mapping default username
* `FGAPISRV_PTVDEFGRP` PTV user mapping default group name
* `FGAPISRV_PTVMAPFILE`  PTV user map file
### Environment for **fgapiserver**
FGAPISRV_APPSDIR Directory hosting applications
#### Environment for GridAndCloudEngine
* `UTDB_HOST` GridAnClouddEngine host name
* `UTDB_PORT` GridAnClouddEngine port number
* `UTDB_USER` GridAnClouddEngine database user
* `UTDB_PASSWORD` GridAnClouddEngine database password
* `UTDB_DATABASE` GridAnClouddEngine database name

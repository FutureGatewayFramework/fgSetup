# apiserverdaemon 
Docker build scripts for FutureGateway component 'apiserverdaemon'

## Configuration
The **apiserverdaemon** component requires the following variables to properly generate its Docker image:

### FutureGateway user
* `FG_USER` Unix username that will manage FutureGateway' components
* `FG_DIR` FutureGateway unix user home directory
### FurtureGateway DB settings
* `FGDB_HOST` FG database host name
* `FGDB_PORT` FG database port number
* `FGDB_USER` FG database user
* `FGDB_PASSWD` FG database user' password
* `FGDB_NAME` Name for FG database
### Environment for scripts
In this section it is possible to point the source code extraction to a particular repository and branch.
* `FGDB_GIT` Git repository address containing database files (fgAPIServer)
* `FGDB_BRANCH` Git repository branch for FG database
### Environment for Tomcat
* `TOMCAT_USER` Username for Tomcat management
* `TOMCAT_PASSWORD` Password for Tomcat management
### Environment for **apiserverdaemon**
* `FGAPISRV_IOSANDBOX` I/O sandbox the FG shared directory (see FG docker Volume setting)
### Environment for ExecutorInterfaces
#### Environment for GridEngine EI
* `UTDB_HOST` GridAnClouddEngine host name
* `UTDB_PORT` GridAnClouddEngine port number
* `UTDB_USER` GridAnClouddEngine database user
* `UTDB_PASSWORD` GridAnClouddEngine database password
* `UTDB_DATABASE` GridAnClouddEngine database name
* `GNCENG_ADP_ROCCI` Repoisitory address for JSAGA rOCCI adaptor
* `GNCENG_ADP_ROCCI_BRANCH` Branch for the JSAGA rOCCI adaptor code
* `GNCENG` Git repository address
* `GNCENG_BRANCH` GridAnClouddEngine Git repository branch name
* `PTV_HSTPRT` fgAPIServer PTV service endpoint


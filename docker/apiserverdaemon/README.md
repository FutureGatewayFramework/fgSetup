# apiserverdaemon 
Docker build scripts for FutureGateway component 'apiserverdaemon'

## Usage
Use one of the following make recipes:
* `make image` Build the Docker image file
* `make run` Executes the docker container
* `make publish` Publishes the image in the Docker-hub

Before to execute the Makefile, please have a look in the Makefile variables, in particular:
* `DOCKER_REPO` Used for publishing in the hub
* `IMAGE_NAME` The name of the image file
* `IMAGE_TAG` Tag to assign to the image
* `FG_NETWORK` Name of the Docker network dedicated to the FG components
* `FG_IOSNDBXVOLNAME` Volume name to store FutureGateway IO Sandbox 
* `FGAPISRV_IOSANDBOX` Container path to the IO Sandbox dir
* `FG_APISRVVOLNAME` Volume name for APIServer
* `FG_APPSDIRVOLNAME` Apps directory volume name
* `FG_IOSNDBXVOLNAME` Volume storing IO Sandbox
* `FG_APISERVERGIT` Git repository address for fgAPIServer 
* `FG_APISERVERGITBRANCH` Git repository branch for fgAPIServer

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

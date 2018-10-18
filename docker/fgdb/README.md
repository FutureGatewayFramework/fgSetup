# fgdb
Docker build scripts for FutureGateway component 'fgdb'

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
* `FG_MYSQLDIRVOLNAME` Name of the Docker volume dedicated to the FG components

## Configuration
The **fgdb** component requires the following variables to properly generate its Docker image:

### FutureGateway user
* `FG_USER` Unix username that will manage FutureGateway' components
* `FG_DIR` FutureGateway unix user home directory
### FGDB main settings
* `MYSQL_ROOT_PASSWORD` MySQL database root directory
* `FGDB_HOST` FG database host name
* `FGDB_PORT` FG database port number 
* `FGDB_USER` FG database user
* `FGDB_PASSWD` FG database user' password
* `FGDB_NAME` Name for FG database
### Environment for scripts
In this section it is possible to point the source code extraction to a particular repository and branch.
* `FGDB_GIT` Git repository address containing database files (fgAPIServer)
* `FGDB_BRANCH` Git repository branch for FG database
* `FGSETUP_GIT` Git repository address for FG setup files
* `FGSETUP_BRANCH` Git repository branch for FG setup files
### Environment for GridEngine EI
Executor interfaces such as the GridAndCloudEngine, may require a dedicated DB 
* `UTDB_HOST` GridAnClouddEngine host name
* `UTDB_PORT` GridAnClouddEngine port number
* `UTDB_USER` GridAnClouddEngine database user
* `UTDB_PASSWORD` GridAnClouddEngine database password
* `UTDB_DATABASE` GridAnClouddEngine database name
* `GNCENG` Git repository address
* `GNCENG_BRANCH` GridAnClouddEngine Git repository branch name

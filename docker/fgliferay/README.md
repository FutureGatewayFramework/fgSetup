# fgliferay
Docker build scripts to create a Liferay based portal integrable with FG.

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
* `FG_LIFERAYVOLNAME` Volume name for the Liferay content
* `MYSQL_ROOT_PASSWORD` Name of the Docker volume dedicated to the FG components

* `LFRY_DBNAME` Liferay database name
* `LFRY_DBUSER` Liferay database username
* `LFRY_DBPASS` Liferay database password
* `LPORTAL_SQL` sql filename that builds Liferay database
* `LIFERAY_PLUGINS_REL` = https://github.com/indigo-dc/LiferayPlugIns/releases/download/2.2.1/LiferayPlugins-binary-2.2.1.tgz
* `FG_DIR` FutureGateway user directory 

## Configuration
The **fgliferay** component requires the following variables to properly generate its Docker image:

### Liferay database seettings
* `MYSQL_ROOT_PASSWORD` Liferay database root password
* `DB_HOST` Liferay database host
* `DB_PORT` Liferay database port
* `DB_SCHEMA` Liferay database schema
* `DB_USER` Liferay database user
* `DB_PASSWORD` Liferay database password

### FutureGateway user and tester user
* `FG_USER` Unix username that will manage FutureGateway' components
* `FG_USERPWD` Unix password for FutureGayeay user
* `FG_DIR` FutureGateway unix user home directory
*  `FG_TEST` Tester user username
*  `FG_TESTPWD`  Tester user password
*  `FG_TESTDIR` Tester user home directory
*  
### FurtureGateway DB settings
* `FGDB_HOST` FG database host name
* `FGDB_PORT` FG database port number
* `FGDB_USER` FG database user
* `FGDB_PASSWD` FG database user' password
* `FGDB_NAME` Name for FG database
### Environment for scripts
In this section it is possible to point the source code extraction to a particular repository and branch.
* `FGSETUP_GIT` Git repository address for FG setup files
* `FGSETUP_BRANCH` Git repository branch for FG setup files
### Environment for GridAndCloudEngine
* `UTDB_HOST` GridAnClouddEngine host name
* `UTDB_PORT` GridAnClouddEngine port number
* `UTDB_USER` GridAnClouddEngine database user
* `UTDB_PASSWORD` GridAnClouddEngine database password
* `UTDB_DATABASE` GridAnClouddEngine database name
### Environment for Liferay portal
* `FG_LIFERAY_PROXYPATH` published endpoint for liferay portal
* `FG_LIFERAY_PROXY` ajp address for liferay portal
### Environment for JAVA settings
* `JAVA_OPTS` Java settings used to assign resources to Liferay
### Liferay settings
* `FG_LIFERAY_PROXYPATH` Liferay Proxy path


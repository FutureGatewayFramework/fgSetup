# fghttpd
Docker build scripts to create an apache based http proxy that manages the whole FutureGateway based ScienceGateway web site.

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
* `FGAPISRV_IOSANDBOX` IO Sandbox volume name
* `FG_APISERVERGIT` Git repository address for APIServerDaemon
* `FG_APISERVERGITBRANCH` Git repository branch for APIServerDaeon

## Configuration
The **fghttpd** component requires the following variables to properly generate its Docker image:

### FutureGateway user and tester user
* `FG_USER` Unix username that will manage FutureGateway' components
* `FG_USERPWD` Unix password for FutureGayeay user
* `FG_DIR` FutureGateway unix user home directory
*  `FG_TEST` Tester user username
*  `FG_TESTPWD`  Tester user password
*  `FG_TESTDIR` Tester user home directory
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

## SSL Certificates
To build self signed certificates, it is possible to generate them accordingly to these [instructions][AKADIA].


[AKADIA]: <https://www.akadia.com/services/ssh_test_certificate.html>

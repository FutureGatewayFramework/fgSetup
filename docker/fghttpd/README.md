# fghttpd
Docker build scripts to create an apache based http proxy that manages the whole FutureGateway based ScienceGateway web site.

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



# Docker Installation

This repository contains necessary files to instantiate FutureGateway components using Docker containers.
There are two different kind of possible installations, the first uses a manual approach to configure and build each FutureGateway component, the second, called automated installation, uses altready built docker images offering a faster approach to the installation process.

## Automated installation
The automated installation requires to almost no apply any change to the existing files. This installation gives also the possibility to test the installed components.

### Installation procedure
If your conteiner server does not host yet any FutureGateway instance, the automated installation is accomplished simply executing the following commands:

```bash
$ ./setup_futuregateway.sh
docker-compose up -d
```

In case more than one FutureGateway instance is present, it is necessary to open the `stup_futuregateway.sh` file first, and change the environment variables related to the **instance settings** ensuring to generate unique names.
It is possible that FG database component is not yet ready when other FG components are starting. For this reason ensure the fgapiserver and apiserverdaemon components connected to the DB correctly. To fix the FG components, it is enough to restart the relative components with `docker stop <container_id>`, and then `docker start <container_id>`. This is the way the test script described in the next chapter, uses to align FG running components. It is higly suggested to execute this script after the installation.

### Testing the instance
To test the generated instance, the following commands have to be executed:

```bash
$ ./exec_futuregateway_test.sh
```

### Persistency and networking
 The automated installation foresees the creation of the following volumes:

 * `<docker>_fgvolume_<instance_name>_apiserver` - FutureGateway applications directory
 * `<docker>_fgvolume_<instance_name>_iosandbox` - FutureGateway I/O Sandboxing directory
 * `<docker>_fgvolume_<instance_name>_mysqldb` - Storing FutureGateay database tables

Where the `<instance_name>` refers to the configuration variable `FGINSTANCE_NAME` in the setup file `setup_futuregateway.sh`.

## Manual installation
In this kind of installation, each FutureGateway component has its own directory and each directory shares the same structure and installation procedure.
Essentially each directory contains:

 * A README file explaining the component
 * A Makefile that can be used to build the container image and run its instance. The Makefile contains several variables to configure properly and in accordance with settings configured inside each Dockerfile.
 * The Dockerfile containing internally several environment variables needed to configure the component. Several variables are shared among different Dockerfiles and Makefile across the different component directories, for this reason it is important that their values will be the same on each Dockerfile/Makefile.

### Persistency and networking
The manual installation foresees the creation of the following volumes:

 * `fg_apiserver` - FutureGateway applications directory
 * `fg_iosandbox` - FutureGateway I/O Sandboxing directory
 * `fg_liferay` - Liferary database and site configurations
 * `fg_mysql` - Storing FutureGateay database tables

The manual installation also foresees the creation of the following network:

 * `fg_network` - Used across any FutureGateway component and used to refer each node using their component names: fgdb, fgapiserver, fgapiserverdaemin, sshnode, fgliferay, ...
The name of the volumes and directories may be changed modifying the Makefiles accordingly.

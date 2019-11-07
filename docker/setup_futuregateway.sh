#!/bin/bash
#
# setup docker compose environment and yml file
#
# Author: Riccardo Bruno INFN <riccardo.bruno@ct.infn.it>
#
FGDB_RPWD=rpass
FGDB_HOST=fgdb
FGDB_NAME=fgapiserver
FGDB_PASSWD=fgapiserver_password
FGDB_PORT=3306
FGDB_USER=fgapiserver
PTV_PORT=8889
ASD_TOMCAT_PASSWORD=tomcat__pass
ASD_TOMCAT_USER=tomcat
TEST_USER=test
TEST_PASS=test_pass

#
# FutureGateway docker images
#
FGDB_IMG=futuregateway/fgdb:0.3
FGAPISERVER_IMG=futuregateway/fgapiserver:0.3
FGAPISERVERDAEMON_IMG=futuregateway/apiserverdaemon:0.3
SSHNODE_IMG=futuregateway/sshnode:0.2

#
# FutureGateway instance settings
#
FGINSTANCE_NAME="test"
FGINSTANCE_ENVF=".env"
FGINSTANCE_CMPF="docker-compose.yml"

cat >$FGINSTANCE_ENVF <<EOF
#
# Common/Misc. settings
#
FG_USER=futuregateway
FG_DIR=/home/futuregateway
# FutureGateway Setup
FGSETUP_BRANCH=py2py3
FGSETUP_GIT=https://github.com/FutureGatewayFramework/fgSetup.git
FGDB_IMG=$FGDB_IMG
FGAPISERVER_IMG=$FGAPISERVER_IMG
FGAPISERVERDAEMON_IMG=$FGAPISERVERDAEMON_IMG
SSHNODE_IMG=$SSHNODE_IMG

#
# FutureGateway DB
#
FGDB_HOST=$FGDB_HOST
FGDB_NAME=$FGDB_NAME
FGDB_PASSWD=$FGDB_PASSWD
FGDB_PORT=$FGDB_PORT
FGDB_USER=$FGDB_USER
# Used by MySQL container
MYSQL_DATABASE=$FGDB_NAME
MYSQL_HOST=$FGDB_HOST
MYSQL_PASSWORD=$FGDB_PASSWD
MYSQL_PORT=$FGDB_PORT
MYSQL_ROOT_PASSWORD=$FGDB_RPWD
MYSQL_USER=$FGDB_USER

#
# fgAPIServer
#
FGAPISERVER_BRANCH=py2py3
FGAPISERVER_GIT=https://github.com/FutureGatewayFramework/fgAPIServer.git
# fgAPIServer configuration settings
FGAPIVER=v1.0
FGJSON_INDENT=4
FGAPISERVER_NAME='API Server'
FGAPISRV_APPSDIR=/app/apps
FGAPISRV_CRT=''
FGAPISRV_DB_HOST=$FGDB_HOST
FGAPISRV_DB_NAME=$FGDB_NAME
FGAPISRV_DB_PASS=$FGDB_PASSWD
FGAPISRV_DB_PORT=$FGDB_PORT
FGAPISRV_DB_USER=$FGDB_USER
FGAPISRV_DBVER=0.0.13
FGAPISRV_DEBUG=True
FGAPISRV_GEAPPID=10000
FGAPISRV_HOST=0.0.0.0
FGAPISRV_IOSANDBOX=/app/fgiosandbox
FGAPISRV_KEY=''
FGAPISRV_LNKPTVFLAG=True
FGAPISRV_LOGCFG=fgapiserver_log.conf
FGAPISRV_NOTOKEN=False
FGAPISRV_NOTOKENUSR=test
FGAPISRV_PORT=8888
FGAPISRV_PTVDEFGRP=administrator
FGAPISRV_PTVDEFUSR=futuregateway
FGAPISRV_PTVENDPOINT=http://localhost:$PTV_PORT/checktoken
FGAPISRV_PTVMAPFILE=fgapiserver_ptvmap.json
FGAPISRV_PTVPASS=tokenver_pass
FGAPISRV_PTVUSER=tokenver_user
FGAPISRV_SECRET=0123456789ABCDEF
# PTV
PTV_HSTPRT=fgapiserver:$PTV_PORT

#
# APIServerDaemon
#
FGASD_BRANCH=user_data
FGASD_GIT=https://github.com/FutureGatewayFramework/APIServerDaemon.git
TOMCAT_PASSWORD=$ASD_TOMCAT_PASSWORD
TOMCAT_USER=$ASD_TOMCAT_USER

# GnCEngine UTDB
UTDB_DATABASE=userstracking
UTDB_HOST=fgdb
UTDB_HOST=$FGDB_HOST
UTDB_PASSWORD=usertracking
UTDB_PORT=3306
UTDB_USER=tracking_user

# GnCEngine Repository
GNCENG_ADP_ROCCI_BRANCH=master
GNCENG_ADP_ROCCI=https://github.com/csgf/jsaga-adaptor-rocci.git
GNCENG_BRANCH=FutureGateway
GNCENG_BRANCH=master
GNCENG=https://github.com/csgf/grid-and-cloud-engine.git

#
# SSH Node (test)
#
TEST_USER=$TEST_USER
TEST_PASS=$TEST_PASS
EOF
echo "Common FutureGateway environment file: '$FGINSTANCE_ENVF' created"

# Source configuration in order to setup properly yml file
. $FGINSTANCE_ENVF

cat >$FGINSTANCE_CMPF <<EOF
version: '3'

services:

  fgdb:
    ports:
     - "23306:3306"
    image: "$FGDB_IMG"
    volumes:
     - fgvolume_${FGINSTANCE_NAME}_mysqldb:/var/lib/mysql
    networks:
     - fg_${FGINSTANCE_NAME}_network
    env_file:
     - ${FGINSTANCE_ENVF}

  fgapiserver:
    depends_on:
     - fgdb
    ports:
     - "2880:80"
     - "2888:\${FGAPISRV_PORT}"
     - "2889:8889"
    image: "$FGAPISERVER_IMG"
    volumes:
     - fgvolume_${FGINSTANCE_NAME}_iosandbox:${FGAPISRV_IOSANDBOX}
     - fgvolume_${FGINSTANCE_NAME}_appsdir:${FGAPISRV_APPSDIR}
    networks:
     - fg_${FGINSTANCE_NAME}_network
    env_file:
     - ${FGINSTANCE_ENVF}

  fgapiserverdaemon:
    depends_on:
     - fgdb
    ports:
     - "38080:8080"
    image: "$FGAPISERVERDAEMON_IMG"
    networks:
     - fg_${FGINSTANCE_NAME}_network
    volumes:
      - fgvolume_${FGINSTANCE_NAME}_iosandbox:${FGAPISRV_IOSANDBOX}
    env_file:
      - ${FGINSTANCE_ENVF}

  sshnode:
    image: "$SSHNODE_IMG"
    networks:
     - fg_${FGINSTANCE_NAME}_network
    env_file:
      - ${FGINSTANCE_ENVF}

volumes:
 fgvolume_${FGINSTANCE_NAME}_mysqldb:
 fgvolume_${FGINSTANCE_NAME}_iosandbox:
 fgvolume_${FGINSTANCE_NAME}_appsdir:
networks:
 fg_${FGINSTANCE_NAME}_network:
EOF
echo "FutureGateway docker compose file: '$FGINSTANCE_CMPF' created"
echo "To instantiate the FutureGateway execute: 'docker-compose up -d'"

# OS
FROM tiangolo/uwsgi-nginx-flask:python2.7

# Maintainer
MAINTAINER Riccardo Bruno <riccardo.bruno@ct.infn.it>

# Environment for fgAPIServer
ENV FG_USER=futuregateway\
 FG_DIR=/home/futuregateway\
 FGAPISRV_APPSDIR=/app/apps\
 FGAPISERVER_GIT=https://github.com/FutureGatewayFramework/fgAPIServer.git\
 FGAPISERVER_BRANCH=py2py3\
# Environment for fgdb
 MYSQL_ROOT_PASSWORD=rpass\
 FGDB_HOST=fgdb\
 FGDB_PORT=3306\
 FGDB_USER=fgapiserver\
 FGDB_PASSWD=fgapiserver_password\
 FGDB_NAME=fgapiserver\
# Environment for ei_gridengine EI
 UTDB_HOST=fgdb\
 UTDB_PORT=3306\
 UTDB_USER=tracking_user\
 UTDB_PASSWORD=usertracking\
 UTDB_DATABASE=userstracking\
# Environment for scripts
 FGSETUP_GIT=https://github.com/FutureGatewayFramework/fgSetup.git\
 FGSETUP_BRANCH=py2py3\
# Environment for fgAPIServer configuration
 FGAPIVER=v1.0\
 FGAPISERVER_NAME='API Server'\
 FGAPISRV_HOST=0.0.0.0\
 FGAPISRV_PORT=8888\
 FGAPISRV_DEBUG=True\
 FGAPISRV_IOSANDBOX=/app/fgiosandbox\
 FGAPISRV_IOSANDBOX_ESC=\\/app\\/fgiosandbox\
 FGAPISRV_GEAPPID=10000\
 FGJSON_INDENT=4\
 FGAPISRV_KEY=''\
 FGAPISRV_CRT=''\
 FGAPISRV_LOGCFG=fgapiserver_log.conf\
 FGAPISRV_DBVER=0.0.13\
 FGAPISRV_SECRET=0123456789ABCDEF\
 FGAPISRV_NOTOKEN=False\
 FGAPISRV_NOTOKENUSR=test\
 FGAPISRV_LNKPTVFLAG=True\
 FGAPISRV_PTVENDPOINT=http:\\/\\/localhost:8889\\/checktoken\
 FGAPISRV_PTVUSER=tokenver_user\
 FGAPISRV_PTVPASS=tokenver_pass\
 FGAPISRV_PTVDEFUSR=futuregateway\
 FGAPISRV_PTVDEFGRP=administrator\
 FGAPISRV_PTVMAPFILE=fgapiserver_ptvmap.json\
 FGAPISRV_DB_HOST=fgdb\
 FGAPISRV_DB_PORT=3306\
 FGAPISRV_DB_USER=fgapiserver\
 FGAPISRV_DB_PASS=fgapiserver_password\ 
 FGAPISRV_DB_NAME=fgapiserver

# User and working directory
WORKDIR $FG_DIR

# Package Installation and TeSS cloning
RUN adduser --disabled-password --gecos "" $FG_USER &&\
    chown -R $FG_USER:$FG_USERS $FG_DIR &&\
    apt-get update &&\
    apt-get install -y --no-install-recommends\
    ca-certificates\
    mysql-client\
    sudo\
    git\
    mlocate\
    vim\
    jq &&\
    sudo echo "$FG_USER ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers &&\
    apt-get clean &&\
    rm -rf /var/lib/apt/lists/*

# User and working directory
USER $FG_USER
WORKDIR $FG_DIR

# Getting FG repo
RUN git clone $FGAPISERVER_GIT -b $FGAPISERVER_BRANCH

# FutureGateway scripts
RUN git clone $FGSETUP_GIT -b $FGSETUP_BRANCH &&\
    mkdir -p .fgprofile &&\
    cp fgSetup/scripts/commons .fgprofile/commons &&\
    cp fgSetup/scripts/fgdb .fgprofile/fgdb &&\
    cp fgSetup/scripts/fgapiserver .fgprofile/fgapiserver &&\
    cp fgSetup/scripts/ei_gridengine .fgprofile/ei_gridengine &&\
# Configure scripts
    ESC_FG_DIR=$(echo $FG_DIR | sed 's/\//\\\//g') &&\
    sed -i "s/^export FGLOCATION.*/export FGLOCATION=$ESC_FG_DIR/" .fgprofile/fgdb &&\
    sed -i "s/^export FGDB_HOST.*/export FGDB_HOST=$FGDB_HOST/" .fgprofile/fgdb &&\
    sed -i "s/^export FGDB_PORT.*/export FGDB_PORT=$FGDB_PORT/" .fgprofile/fgdb &&\
    sed -i "s/^export FGDB_USER.*/export FGDB_USER=$FGDB_USER/" .fgprofile/fgdb &&\
    sed -i "s/^export FGDB_PASSWD.*/export FGDB_PASSWD=$FGDB_PASSWD/" .fgprofile/fgdb &&\
    sed -i "s/^export FGDB_NAME.*/export FGDB_NAME=$FGDB_NAME/" .fgprofile/fgdb &&\
    sed -i "s/^export ASDB_OPTS.*/export ASDB_OPTS=''/" .fgprofile/fgdb &&\
    sed -i "s/^export FGDB_ROOTPWD.*/export FGDB_ROOTPWD=$MYSQL_ROOT_PASSWORD/" .fgprofile/fgdb &&\
# Configuring scripts ei_gridengine
    sed -i "s/^export UTDB_HOST.*/export UTDB_HOST=$UTDB_HOST/" .fgprofile/ei_gridengine &&\
    sed -i "s/^export UTDB_PORT.*/export UTDB_PORT=$UTDB_PORT/" .fgprofile/ei_gridengine &&\
#    sed -i "s/^export UTDB_USER.*/export UTDB_USER=$UTDB_USER/" .fgprofile/ei_gridengine &&\
#    sed -i "s/^export UTDB_PASSWD.*/export UTDB_PASSWD=$UTDB_PASSWD/" .fgprofile/ei_gridengine &&\
#    sed -i "s/^export UTDB_NAME.*/export UTDB_NAME=$UTDB_NAME/" .fgprofile/ei_gridengine &&\
    sed -i "s/^export UTDB_OPTS.*/export UTDB_OPTS=''/" .fgprofile/ei_gridengine &&\
    cat .fgprofile/fgdb &&\
    cat .fgprofile/ei_gridengine


# nginx port 80 available to the world outside this container
EXPOSE 8888
EXPOSE 8889 

# Back to the root user
USER root

# Configure the webapp
RUN mv /app /app_orig &&\
    mv fgAPIServer /app &&\
    mkdir -p $FGAPISRV_IOSANDBOX

WORKDIR /app

RUN ln -s fgapiserver.py main.py &&\
    sed -i'' "s/  fgapiver.*/  fgapiver: $FGAPIVER/" fgapiserver.yaml &&\
    sed -i'' "s/  fgapiserver_name.*/  fgapiserver_name: $FGAPISERVER_NAME/" fgapiserver.yaml &&\
    sed -i'' "s/  fgapisrv_host.*/  fgapisrv_host: $FGAPISRV_HOST/" fgapiserver.yaml &&\
    sed -i'' "s/  fgapisrv_port.*/  fgapisrv_port: $FGAPISRV_PORT/" fgapiserver.yaml &&\
    sed -i'' "s/  fgapisrv_debug.*/  fgapisrv_debug: $FGAPISRV_DEBUG/" fgapiserver.yaml &&\
    sed -i'' "s/  fgapisrv_iosandbox.*/  fgapisrv_iosandbox: $FGAPISRV_IOSANDBOX_ESC/" fgapiserver.yaml &&\
    sed -i'' "s/  fgapisrv_geappid.*/  fgapisrv_geappid: $FGAPISRV_GEAPPID/" fgapiserver.yaml &&\
    sed -i'' "s/  fgjson_indent.*/  fgjson_indent: $FGJSON_INDENT/" fgapiserver.yaml &&\
    sed -i'' "s/  fgapisrv_key.*/  fgapisrv_key: $FGAPISRV_KEY/" fgapiserver.yaml &&\
    sed -i'' "s/  fgapisrv_crt.*/  fgapisrv_crt: $FGAPISRV_CRT/" fgapiserver.yaml &&\
    sed -i'' "s/  fgapisrv_logcfg.*/  fgapisrv_logcfg: $FGAPISRV_LOGCFG/" fgapiserver.yaml &&\
    sed -i'' "s/  fgapisrv_dbver.*/  fgapisrv_dbver: $FGAPISRV_DBVER/" fgapiserver.yaml &&\
    sed -i'' "s/  fgapisrv_secret.*/  fgapisrv_secret: $FGAPISRV_SECRET/" fgapiserver.yaml &&\
    sed -i'' "s/  fgapisrv_notoken\ .*/  fgapisrv_notoken: $FGAPISRV_NOTOKEN/" fgapiserver.yaml &&\
    sed -i'' "s/  fgapisrv_notokenusr.*/  fgapisrv_notokenusr: $FGAPISRV_NOTOKENUSR/" fgapiserver.yaml &&\
    sed -i'' "s/  fgapisrv_lnkptvflag.*/  fgapisrv_lnkptvflag: $FGAPISRV_LNKPTVFLAG/" fgapiserver.yaml &&\
    sed -i'' "s/  fgapisrv_ptvendpoint.*/  fgapisrv_ptvendpoint: $FGAPISRV_PTVENDPOINT/" fgapiserver.yaml &&\
    sed -i'' "s/  fgapisrv_ptvuser.*/  fgapisrv_ptvuser: $FGAPISRV_PTVUSER/" fgapiserver.yaml &&\
    sed -i'' "s/  fgapisrv_ptvpass.*/  fgapisrv_ptvpass: $FGAPISRV_PTVPASS/" fgapiserver.yaml &&\
    sed -i'' "s/  fgapisrv_ptvdefusr.*/  fgapisrv_ptvdefusr: $FGAPISRV_PTVDEFUSR/" fgapiserver.yaml &&\
    sed -i'' "s/  fgapisrv_ptvdefgrp.*/  fgapisrv_ptvdefgrp: $FGAPISRV_PTVDEFGRP/" fgapiserver.yaml &&\
    sed -i'' "s/  fgapisrv_ptvmapfile.*/  fgapisrv_ptvmapfile: $FGAPISRV_PTVMAPFILE/" fgapiserver.yaml &&\
    sed -i'' "s/  fgapisrv_db_host.*/  fgapisrv_db_host: $FGAPISRV_DB_HOST/" fgapiserver.yaml &&\
    sed -i'' "s/  fgapisrv_db_port.*/  fgapisrv_db_port: $FGAPISRV_DB_PORT/" fgapiserver.yaml &&\
    sed -i'' "s/  fgapisrv_db_user.*/  fgapisrv_db_user: $FGAPISRV_DB_USER/" fgapiserver.yaml &&\
    sed -i'' "s/  fgapisrv_db_pass.*/  fgapisrv_db_pass: $FGAPISRV_DB_PASS/" fgapiserver.yaml &&\
    sed -i'' "s/  fgapisrv_db_name.*/  fgapisrv_db_name: $FGAPISRV_DB_NAME/" fgapiserver.yaml &&\
    cat fgapiserver.yaml &&\
    cp /app_orig/uwsgi.ini uwsgi.ini &&\
    pip install -r requirements.txt

# Test purposes, execute PTV and TOSCA simulator
RUN echo "./fgapiserver_ptv.py 2>fgapiserver.log >fgapiserver.log &" > prestart.sh


# Setup FGDB profile (all users)
RUN echo "for f in \$(find $FG_DIR/.fgprofile -type f); do source \$f; done # FGLOADENV" >> /etc/profile.d/fg_profile.sh 

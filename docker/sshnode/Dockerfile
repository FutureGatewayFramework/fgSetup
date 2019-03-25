# OS
FROM ubuntu 

# Maintainer
MAINTAINER Riccardo Bruno <riccardo.bruno@ct.infn.it>

# Environment for FGDB
ENV FG_USER=futuregateway\
    FG_USERPWD=futuregateway\
    FG_DIR=/home/futuregateway\
    FG_TEST=fgtest\
    FG_TESTPWD=fgtest\
    FG_TESTDIR=/home/fgtest\
    FGDB_HOST=fgdb\
    FGDB_PORT=3306\
    FGDB_USER=fgapiserver\
    FGDB_PASSWD=fgapiserver_password\
    FGDB_NAME=fgapiserver\
# Environment for scripts
    FGSETUP_GIT=https://github.com/FutureGatewayFramework/fgSetup.git\
    FGSETUP_BRANCH=v0.0.10\
# Environment for GridEngine EI
    UTDB_HOST=$FGDB_HOST\ 
    UTDB_PORT=3306\
    UTDB_USER=tracking_user\
    UTDB_PASSWORD=usertracking\
    UTDB_DATABASE=userstracking

# Package Installation and TeSS cloning
RUN adduser --disabled-password --gecos "" $FG_USER &&\
    chown -R $FG_USER:$FG_USERS $FG_DIR &&\
    echo "$FG_USER:$FG_USERPWD" | /usr/sbin/chpasswd &&\
    adduser --disabled-password --gecos "" $FG_TEST &&\
    chown -R $FG_TEST:$FG_TEST $FG_TESTDIR &&\
    echo "$FG_TEST:$FG_TESTPWD" | /usr/sbin/chpasswd &&\
    apt-get update &&\
    apt-get install\
            -y\
            --no-install-recommends\
            ca-certificates\
            sudo\
            git\
            mysql-client\
            mlocate\
            vim\
            openssh-server\
            locales &&\
   #sudo echo "$FG_USER ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers &&\
    apt-get clean &&\
    rm -rf /var/lib/apt/lists/* &&\
    locale-gen en_US.UTF-8 &&\
    sed -i "s/.*PasswordAuthentication.*/PasswordAuthentication yes/g" /etc/ssh/sshd_config &&\
    echo "for f in \$(find $FG_DIR/.fgprofile -type f); do source \$f; done # FGLOADENV" >> /etc/profile.d/fg_profile.sh

# User and working directory
USER $FG_USER
WORKDIR $FG_DIR

# FutureGateway scripts
RUN git clone $FGSETUP_GIT -b $FGSETUP_BRANCH &&\
    mkdir -p .fgprofile &&\
    cp fgSetup/scripts/commons .fgprofile/commons &&\
    cp fgSetup/scripts/fgdb .fgprofile/fgdb &&\
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
    sed -i "s/^export FGDB_ROOTPWD.*/export FGDB_ROOTPWD=$MYSQL_ROOT_PASSWORD/" .fgprofile/fgdb 

#
# Additional setup for Executor Interfaces
#

# Grid and Cloud Engine UsersTracking database
RUN sed -i "s/^export UTDB_HOST.*/export UTDB_HOST=$UTDB_HOST/" .fgprofile/ei_gridengine &&\
    sed -i "s/^export UTDB_PORT.*/export UTDB_PORT=$UTDB_PORT/" .fgprofile/ei_gridengine &&\
#    sed -i "s/^export UTDB_USER.*/export UTDB_USER=$UTDB_USER/" .fgprofile/ei_gridengine &&\
#    sed -i "s/^export UTDB_PASSWD.*/export UTDB_PASSWD=$UTDB_PASSWD/" .fgprofile/ei_gridengine &&\
#    sed -i "s/^export UTDB_NAME.*/export UTDB_NAME=$UTDB_NAME/" .fgprofile/ei_gridengine &&\
    sed -i "s/^export UTDB_OPTS.*/export UTDB_OPTS=''/" .fgprofile/ei_gridengine

# Prepare and execute sshd
USER root
WORKDIR /root
RUN  mkdir -p /var/run/sshd
ENTRYPOINT [ "/usr/sbin/sshd", "-D" ]  


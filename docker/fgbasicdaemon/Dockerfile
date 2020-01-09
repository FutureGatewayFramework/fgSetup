# OS
FROM ubuntu:18.04

# Maintainer
MAINTAINER Riccardo Bruno <riccardo.bruno@ct.infn.it>

# Environment for FGDB
ENV FG_USER=futuregateway\
    FG_DIR=/home/futuregateway\
    FGSETUP_GIT=https://github.com/FutureGatewayFramework/fgSetup\
    FGSETUP_BRANCH=basicdaemon\
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
    UTDB_DATABASE=userstracking

# Package Installation and TeSS cloning
RUN adduser --disabled-password --gecos "" $FG_USER &&\
    chown -R $FG_USER:$FG_USER $FG_DIR &&\
    apt-get update &&\
    apt-get install -y --no-install-recommends\
             ca-certificates\
             sudo\
             git\
             software-properties-common\
             mlocate\
             vim\
             git\
             openssh-server\
             wget\
             build-essential\
             libssl-dev\
             python-dev\
             python-pip\
             mariadb-client\
             jq &&\
    sudo echo "$FG_USER ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers &&\
    apt-get clean &&\
    rm -rf /var/lib/apt/lists/*

# User and working directory
USER $FG_USER
WORKDIR $FG_DIR

# Getting FG repo
RUN git clone $FGSETUP_GIT -b $FGSETUP_BRANCH &&\
    echo "StrictHostKeyChecking no\nUserKnownHostsFile=/dev/null\n" > ssh_opt &&\
    sudo su - -c "cat $FG_DIR/ssh_opt >> /etc/ssh/ssh_config" &&\
    rm -f ssh_opt &&\
# SSH keygen
    ssh-keygen -t rsa -N '' -f $FG_DIR/.ssh/id_rsa &&\

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
    cat .fgprofile/ei_gridengine &&\
    echo "Done"


RUN echo "\
sudo /etc/init.d/ssh start\n\
mkdir $FG_DIR/.ssh\n\
ssh-keygen -t rsa -N '' -f $TEST_DIR/.ssh/id_rsa\n\
sudo su - -c \"ssh-keygen -t rsa -N '' -f /root/.ssh/id_rsa\"\n\
sudo su - -c \"cat $FG_DIR_DIR/.ssh/id_rsa.pub >> /root/.ssh/authorized_keys\"\n\
sudo su - -c \"cat $FG_DIR_DIR/.ssh/id_rsa.pub >> $FG_DIR/.ssh/authorized_keys\"\n\
sudo su - -c \"cat /root/.ssh/id_rsa.pub >> $FG_DIR_DIR/.ssh/authorized_keys\"\n\
sudo su - -c \"cat /root/.ssh/id_rsa.pub >> /root/.ssh/authorized_keys\"\n\
while [ 1 ]; do sleep 3600; done" > loop.sh &&\
    chmod +x loop.sh

# Setup FGDB profile (all users)
RUN echo "for f in \$(find $FG_DIR/.fgprofile -type f); do source \$f; done # FGLOADENV" >> /etc/profile.d/fg_profile.sh

# Lasts forever
ENTRYPOINT ["/bin/bash"]
CMD ["loop.sh"]

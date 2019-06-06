# OS
#FROM ubuntu:14.04
#FROM ubuntu:16.04
FROM ubuntu:18.04

# Maintainer
MAINTAINER Riccardo Bruno <riccardo.bruno@ct.infn.it>

# Environment for FGDB
ENV TEST_USER=fgtest\
    TEST_DIR=/home/fgtest\
    FG_USER=futuregateway\
    FG_DIR=/home/futuregateway\
    FGSETUP_GIT=https://github.com/FutureGatewayFramework/fgSetup\
    FGSETUP_BRANCH=py2py3

# Package Installation and TeSS cloning
RUN  adduser --home $TEST_DIR --disabled-password --gecos "" $TEST_USER &&\
     adduser --home $FG_DIR --disabled-password --gecos "" $FG_USER &&\
     export DEBIAN_FRONTEND=noninteractive &&\
     apt-get update &&\
     apt-get install -y --no-install-recommends\
             sudo\
             screen\
             git\
             ca-certificates\
             software-properties-common\
             mlocate\
             vim\
             openssh-client\
             openssh-server\
             mysql-client\
             wget\
             build-essential &&\
    echo "$TEST_USER ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers &&\
    echo "$FG_USER ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers &&\
    apt-get clean &&\
    rm -rf /var/lib/apt/lists/*

# FGUser
USER $FG_USER
WORKDIR $FG_DIR
RUN ssh-keygen -t rsa -N '' -f $FG_DIR/.ssh/id_rsa &&\
    echo "Done"

# User and working directory
USER $TEST_USER
WORKDIR $TEST_DIR

# Add do_tests.sh script
ADD do_tests.sh do_tests.sh

# Getting FG repo
RUN sudo chown $TEST_USER:$TEST_USER do_tests.sh &&\
    echo "StrictHostKeyChecking no\nUserKnownHostsFile=/dev/null\n" > ssh_opt &&\
    sudo su - -c "cat $TEST_DIR/ssh_opt >> /etc/ssh/ssh_config" &&\
    rm -f ssh_opt &&\
# SSH keygen
    ssh-keygen -t rsa -N '' -f $TEST_DIR/.ssh/id_rsa &&\
# Building FG with ansible here
    echo "Done"


RUN echo "\
git clone $FGSETUP_GIT -b $FGSETUP_BRANCH\n\
sudo /etc/init.d/ssh start\n\
sudo su - -c \"ssh-keygen -t rsa -N '' -f /root/.ssh/id_rsa\"\n\
sudo su - -c \"cat $TEST_DIR/.ssh/id_rsa.pub >> /root/.ssh/authorized_keys\"\n\
sudo su - -c \"cat $TEST_DIR/.ssh/id_rsa.pub >> $TEST_DIR/.ssh/authorized_keys\"\n\
sudo su - -c \"cat $TEST_DIR/.ssh/id_rsa.pub >> $FG_DIR/.ssh/authorized_keys\"\n\
sudo su - -c \"cat $FG_DIR/.ssh/id_rsa.pub >> /root/.ssh/authorized_keys\"\n\
sudo su - -c \"cat $FG_DIR/.ssh/id_rsa.pub >> $TEST_DIR/.ssh/authorized_keys\"\n\
sudo su - -c \"cat $FG_DIR/.ssh/id_rsa.pub >> $FG_DIR/.ssh/authorized_keys\"\n\
sudo su - -c \"cat /root/.ssh/id_rsa.pub >> $TEST_DIR/.ssh/authorized_keys\"\n\
sudo su - -c \"cat /root/.ssh/id_rsa.pub >> $FG_DIR/.ssh/authorized_keys\"\n\
sudo su - -c \"cat /root/.ssh/id_rsa.pub >> /root/.ssh/authorized_keys\"\n\
while [ 1 ]; do sleep 3600; done" > loop.sh &&\
    chmod +x loop.sh

# Lasts forever
ENTRYPOINT ["/bin/bash"]
CMD ["loop.sh"]

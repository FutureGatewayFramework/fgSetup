# OS
FROM ubuntu:14.04

# Maintainer
MAINTAINER Riccardo Bruno <riccardo.bruno@ct.infn.it>

# Environment for FGDB
ENV TEST_USER=fgtest\
    TEST_DIR=/home/fgtest\
    FGSETUP_GIT=https://github.com/FutureGatewayFramework/fgSetup\
    FGSETUP_BRANCH=v0.0.9

# User and working directory
WORKDIR $TEST_DIR

# Package Installation and TeSS cloning
RUN adduser --disabled-password --gecos "" $TEST_USER &&\
    chown -R $TEST_USER:$TEST_USER $TEST_DIR &&\
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
             pdftk\
             xvfb\
             wkhtmltopdf\
             wget\
             sshpass\
             build-essential\
             libssl-dev\
             libffi-dev\
             python-dev\
             python-pip &&\
    sudo echo "$TEST_USER ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers &&\
    sudo add-apt-repository -y ppa:fkrull/deadsnakes-python2.7 &&\
    sudo apt-add-repository -y ppa:ansible/ansible &&\
    sudo apt-get update -y &&\
    sudo apt-get upgrade -y --force-yes &&\
    sudo apt-get install -y ansible &&\
    apt-get clean &&\
    rm -rf /var/lib/apt/lists/*

# User and working directory
USER $TEST_USER
WORKDIR $TEST_DIR

# Getting FG repo
RUN git clone $FGSETUP_GIT -b $FGSETUP_BRANCH &&\
    ansible-galaxy install geerlingguy.git &&\
    ansible-galaxy install geerlingguy.mysql &&\
    ansible-galaxy install geerlingguy.apache &&\
    ansible-galaxy install bobbyrenwick.pip &&\
    echo "StrictHostKeyChecking no\nUserKnownHostsFile=/dev/null\n" > ssh_opt &&\
    sudo su - -c "cat $TEST_DIR/ssh_opt >> /etc/ssh/ssh_config" &&\
    rm -f ssh_opt &&\
    #cd fgSetup/ansible &&\
    #cd - &&\
# SSH keygen
    ssh-keygen -t rsa -N '' -f $TEST_DIR/.ssh/id_rsa &&\
# Building FG with ansible here
    echo "Done"


RUN echo "\
sudo /etc/init.d/ssh start\n\
mkdir $TEST_DIR/.ssh\n\
ssh-keygen -t rsa -N '' -f $TEST_DIR/.ssh/id_rsa\n\
sudo su - -c \"ssh-keygen -t rsa -N '' -f /root/.ssh/id_rsa\"\n\
sudo su - -c \"cat $TEST_DIR/.ssh/id_rsa.pub >> /root/.ssh/authorized_keys\"\n\
sudo su - -c \"cat $TEST_DIR/.ssh/id_rsa.pub >> $TEST_DIR/.ssh/authorized_keys\"\n\
sudo su - -c \"cat /root/.ssh/id_rsa.pub >> $TEST_DIR/.ssh/authorized_keys\"\n\
sudo su - -c \"cat /root/.ssh/id_rsa.pub >> /root/.ssh/authorized_keys\"\n\
while [ 1 ]; do sleep 3600; done" > loop.sh &&\
    chmod +x loop.sh

# Lasts forever
ENTRYPOINT ["/bin/bash"]
CMD ["loop.sh"]

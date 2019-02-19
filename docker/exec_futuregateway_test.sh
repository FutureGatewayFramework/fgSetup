#!/bin/bash
#
# setup_futuregateway - configure the FutureGateway to execute tests
#
# Author: Riccardo Bruno INFN <riccardo.bruno@ct.infn.it>
#
TEST_SCRIPT='test_futuregateway.sh'

# Load FutureGateway configuration
ENV_FILE=.env
[ ! -f $ENV_FILE ] &&\
    echo "Unable to load FutureGateway environment file: '$ENV_FILE'" &&\
    exit 1
. $ENV_FILE

# Verify test script
[ ! -f $TEST_SCRIPT ] &&\
    echo "Test script '$TEST_SCRIPT' not found" &&\
    exit 1

#
# Functions
#

# View FutureGateway docker container Ids
view_fg_nodes() {
	echo "FutureGateway nodes"
	echo "-------------------"
	echo "    FGDB             : '$FGDB_CID'" &&\
	echo "    FGAPISERVER      : '$FGAPISERVER_CID'" &&\
	echo "    FGAPISERVERDAEMON: '$FGAPISERVERDAEMON_CID'" &&\
	echo "    SSHNODE          : '$SSHNODE_CID'"
	echo ""
}

# Check FutureGateway nodes determine the container id of each FG node.
get_fg_nodes() {
	FGDB_CID=$(docker ps -a | grep $FGDB_IMG | awk '{ print $1 }')
	FGAPISERVER_CID=$(docker ps -a |\
	                  grep $FGAPISERVER_IMG |\
	                  awk '{ print $1 }')
	FGAPISERVERDAEMON_CID=$(docker ps -a |\
	                        grep $FGAPISERVERDAEMON_IMG |\
	                        awk '{ print $1 }')
	SSHNODE_CID=$(docker ps -a | grep $SSHNODE_IMG | awk '{ print $1 }')

	view_fg_nodes
	[ "$FGDB_CID" = "" -o\
	  "$FGAPISERVER_CID" = "" -o\
	  "$FGAPISERVERDAEMON_CID" = "" -o\
	  "$SSHNODE_CID" = "" ] &&\
	  echo "Unable to determine one or more FutureGateway container Ids:" &&\
	  exit 1 ||\
	  echo "All FutureGateway nodes successfully retrieved"
}

# FGDB requires a while in order to start. FG components depending on it may
# fall into an inconsistent state and they require to be restarted
align_installation() {
  # Wait for FGDB service first
  printf "Waiting for FG database availability ... "
  MYSQL_RUNNING=0
  while [ $MYSQL_RUNNING -eq 0 ]; do
	  MYSQL_RUNNING=$(docker logs $FGDB_CID 2>&1 |\
                          grep ^Version |\
		          tail -n 1 |\
			  grep /var/run/mysqld/mysqld.sock |\
			  wc -l)
  done
  sleep 60
  echo "done"
  RESTART_SERVICES=(
    $FGAPISERVER_CID
    $FGAPISERVERDAEMON_CID
  )
  for service in ${RESTART_SERVICES[@]}; do
    printf "Restarting container: $service ... " &&\
    docker container restart $service 2>&1 >/dev/null &&\
    echo "ok" ||\
    FAILED="failed"
    [ "$FAILED" != "" ] &&\
      echo $FAILED &&\
      return 1
  done
  return 0
}

# Execute a given script into a Docker containerId
#   $1 ContainerId
#   $2 File containing the script to execute
#   $3 User owning file
#   $4 Script file name at destination
exec_script() {
	CID=$1
	SFL=$2
	SUS=$3
	SFN=$4
  docker cp $SFL $CID:/tmp/$SFN
  CMD_FILE=$(mktemp)
  cat >$CMD_FILE <<EOF
chmod +x /tmp/$SFN
chown $SUS /tmp/$SFN
/bin/bash /tmp/$SFN
rm -f /tmp/$SFN
EOF
    while read command; do
      printf "Executing on $CID: '$command' ... "
      docker exec -t $CID $command &&\
      cmd_state="ok" ||\
      cmd_state="fail"
      echo "$cmd_state"
      [ "$cmd_state" = "fail" ] &&\
         break
    done < $CMD_FILE
    rm -f $CMD_FILE
    [ "$cmd_state" != "ok" ] &&\
      return 1
    return 0
}


# Setup the APIServerDaemon component
setup_apiserverdaemon() {	
    CFG_SCRIPT=$(mktemp)
    cat >$CFG_SCRIPT <<EOF
echo "Host sshnode" >> /etc/ssh/ssh_config
echo "    StrictHostKeyChecking no" >> /etc/ssh/ssh_config
echo "    UserKnownHostsFile=/dev/null" >> /etc/ssh/ssh_config
EOF
	CFG_DONE=$(docker exec $FGAPISERVERDAEMON_CID cat /etc/ssh/ssh_config |\
	          grep sshnode |\
	          wc -l)
    [ $CFG_DONE -ne 0 ] &&\
      echo "APIServerDaemon altready configured" &&\
      return 0

    exec_script $FGAPISERVERDAEMON_CID\
                $CFG_SCRIPT\
                'root'\
                'cfg_sshnode.sh' &&\
    RES=0 ||\
    RES=1

    [ $RES -eq 0 ] &&\
      echo "APIServerDaemon successfully configured" ||\
      echo "ERROR: Failed to configure APIServerDaemon"

    rm -f $CFG_SCRIPT
    return $RES
}

# Setup the SSHNode component
setup_sshnode() {
    CFG_SCRIPT=$(mktemp)
    cat >$CFG_SCRIPT <<EOF
adduser --disabled-password --gecos "" $TEST_USER
echo -e "$TEST_PASS\n$TEST_PASS" | passwd $TEST_USER
EOF
    CFG_DONE=$(docker exec $SSHNODE_CID ls -ld /home/test 2>/dev/null | wc -l)
    [ $CFG_DONE -eq 0 ] &&\
        exec_script $SSHNODE_CID\
                    $CFG_SCRIPT\
                    'futuregateway'\
                    'cfg_sshnode_user.sh' &&\
        printf "sshnode successfully configured "||\
        printf "sshnode altready configured "
        echo "to connect with user: '$TEST_USER' using password: '$TEST_PASS'"
    rm -f $CFG_SCRIPT
}

# Setup fgAPIServer node
setup_fgapiserver() {
	CFG_SCRIPT=$(mktemp)
	cat >$CFG_SCRIPT <<EOF
# By default LKNPTVFLAG is enabled, it is necessart to switch it off
# Load FutureGateway environment
  cd /home/futuregateway &&\
  . .fgprofile/commons &&\
  . .fgprofile/fgdb &&\
  asdb "update srv_config set value=FALSE where name='fgapisrv_lnkptvflag';"
EOF
    exec_script $FGAPISERVER_CID\
                $CFG_SCRIPT\
                'futuregateway'\
                'cfg_lnk_ptv_flag.sh' &&\
    echo "Successfully disabled LNKPTVFLAG for fgAPIServer"
    rm -f $CFG_SCRIPT
}

# Run test script on fgapiserver node
run_tests() {
  [ -f $TEST_SCRIPT ] &&\
    exec_script $FGAPISERVER_CID\
                $TEST_SCRIPT\
                'futuregateway'\
                $TEST_SCRIPT
}

#
# Test steps
#
get_fg_nodes &&\
align_installation &&\
setup_apiserverdaemon &&\
setup_sshnode &&\
setup_fgapiserver &&\
run_tests &&\
echo "Done"

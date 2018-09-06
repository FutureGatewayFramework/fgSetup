#
# Test script for FutureGateway
#
# Author: Riccardo Bruno <riccardo.bruno@ct.infn.it>
#

# Load setup environment variables
source fgSetup/setup_config.sh

# Load setup common functions
source fgSetup/setup_commons.sh

# Used token during tests using PTV
TKN="________TEST_TKN________"

# Setup FutureGateway
[ ! -f .fgsetup ] &&\
  cd fgSetup &&\
  ./setup_futuregateway.sh &&\
  cd - >/dev/null 2>/dev/null &&
  touch .fgsetup ||\
  out "Setup already executed"

# Setup PTV simulator for test running
PTV=$(sudo su - futuregateway -c "screen -ls | grep ptv")
[ "$PTV" == "" ] &&\
  sudo su - futuregateway\
     -c "screen -S ptv\
         -dm /bin/bash\
         -c \"cd fgAPIServer &&\
              pwd &&\
              source ./.venv/bin/activate &&\
              ./fgapiserver_ptv.py &&\
              sleep 60 || sleep 60\"" &&\
  out "Waiting a minute to ensure PTV is properly running ... " 1 &&\
  sleep 60 &&\
  out "done" 0 1 ||\
  out "PTV already running"

# Test functions and variables

# The array above contains any global scope temporaty file
TEMP_FILES=()

# Create temporary files
cleanup_tempFiles() {
  out "Cleaning temporary files:"
  for tempfile in ${TEMP_FILES[@]}
  do
    out "Cleaning up '"$tempfile"' ... " 1
    rm -rf $tempfile
    out "done" 0 1
  done
}

# Cleanup global scope temporary files upon exit
trap cleanup_tempFiles EXIT

TEST_CMD=$(mktemp)
chmod +x $TEST_CMD
TEMP_FILES+=( TEST_CMD )
TEST_OUT=$(mktemp)
TEMP_FILES+=( TEST_OUT )
TEST_ERR=$(mktemp)
TEMP_FILES+=( TEST_ERR )

# Perform test
do_test() {
  [ ! -d ".tests" ] && mkdir .tests
  [ "$TEST_CNT" == "" ] && TEST_CNT=1 || TEST_CNT=$((TEST_CNT+1))
  TEST_NAME=$1
  TEST_CASE=$2
  TEST_FILE=$(printf "%04d_%s" $TEST_CNT "$2")

  TEST_MSG=$(printf "Test (%04d) - '$1' ... " $TEST_CNT)
  out "$TEST_MSG" 1
  if [ ! -f $TEST_FILE ]; then
    $TEST_CMD >$TEST_OUT 2>$TEST_ERR
    RES=$?
    if [ $RES -eq 0 ]; then
      # Produce json file for test execution
      echo "$TEST_NAME" > .tests/$TEST_FILE.name
      cat $TEST_CMD > .tests/$TEST_FILE.cmd
      cat $TEST_OUT > .tests/$TEST_FILE.out
      cat $TEST_ERR > .tests/$TEST_FILE.err
      out "passed" 0 1
    else
      out "failed" 0 1
      out "Test command:"
      cat $TEST_CMD
      out "Test output:"
      cat $TEST_OUT
      out "Test error:"
      cat $TEST_ERR
    fi
  else
    out "passed" 0 1
  fi
}

#
# Test cases, below:
#
out "Starting testing"


#
# PTV
#

cat >$TEST_CMD <<EOF
curl -f -d token="________TEST_TKN________" -u "$FGAPISERVER_PTVUSER:$FGAPISERVER_PTVPASS" $FGAPISERVER_PTVENDPOINT 
EOF
do_test "PTV checktoken" "ptv_checktoken"

#
# APIServer
#

cat >$TEST_CMD <<EOF
curl -f -H "Authorization: Bearer $TKN" http://$FGAPISERVER_HOST/fgapiserver/$FGAPISERVER_APIVER/tasks
EOF
do_test "API: /tasks" "api_tasks"

#
# APIServerDaemon
#


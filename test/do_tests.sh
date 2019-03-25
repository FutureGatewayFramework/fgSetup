#!/bin/bash
#
# Test script for FutureGateway
#
# Author: Riccardo Bruno <riccardo.bruno@ct.infn.it>
#

# Load setup environment variables
source fgSetup/setup_config.sh

# Load setup common functions
source fgSetup/setup_commons.sh

# Test environment file
TEST_ENV='tests/test_env'

# Used token during tests using PTV
TKN="________TEST_TKN________"

# Setup FutureGateway
[ ! -f .fgsetup ] &&\
  cd fgSetup &&\
  ./setup_futuregateway.sh &&\
  cd - >/dev/null 2>/dev/null &&
  touch .fgsetup ||\
  out "Setup already executed"
[ ! -f .fgsetup ] &&\
  echo  "FutureGateway installation unsuccessful" &&\
  exit 1

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
  TEST_CMD=$1
  [ ! -d ".tests" ] && mkdir .tests
  [ "$TEST_CNT" == "" ] && TEST_CNT=1 || TEST_CNT=$((TEST_CNT+1))
  [ ! -f tests/$TEST_CMD ] &&\
    echo "Unable to find test file: '$TEST_CMD'" &&\
    return 1
  TEST_NAME=$(cat tests/$TEST_CMD | grep TEST_NAME | awk -F'=' '{ print $2}' | xargs echo)
  TEST_CASE=$(cat tests/$TEST_CMD | grep TEST_CASE | awk -F'=' '{ print $2}' | xargs echo)
  TEST_FILE=$(printf "%04d_%s" $TEST_CNT "$TEST_CASE")
  TEST_DESC=$(cat tests/$TEST_CMD | grep TEST_DESC | awk -F'=' '{ print $2}' | xargs echo)
  TEST_MSG=$(printf "Test (%04d) - '$TEST_NAME' ... " $TEST_CNT)
  out "$TEST_MSG" 1
  if [ ! -f ".tests/$TEST_FILE.name" ]; then
    tests/$TEST_CMD >$TEST_OUT 2>$TEST_ERR
    RES=$?
    if [ $RES -eq 0 ]; then
      # Produce json file for test execution
      echo "$TEST_NAME" > .tests/$TEST_FILE.name
      echo "$TEST_DESC" > .tests/$TEST_FILE.desc
      cat tests/$TEST_CMD > .tests/$TEST_FILE.cmd
      cat $TEST_OUT > .tests/$TEST_FILE.out
      cat $TEST_ERR > .tests/$TEST_FILE.err
      out "passed" 0 1
    else
      out "failed" 0 1
      out "Test command:"
      cat tests/$TEST_CMD
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
cd $HOME/fgSetup/test
out "Starting testing"
out "Common environment file: '$TEST_ENV'"
cat >$TEST_ENV <<EOF
#
# Test environment file, automatically generated by do_tests.sh script
#
TKN=${TKN}
FGAPISERVER_PTVUSER=${FGAPISERVER_PTVUSER}
FGAPISERVER_PTVPASS=${FGAPISERVER_PTVPASS}
FGAPISERVER_PTVENDPOINT=${FGAPISERVER_PTVENDPOINT}
FGAPISERVER_HOST=${FGAPISERVER_HOST}
FGAPISERVER_APIVER=${FGAPISERVER_APIVER}
EOF

TESTS=(\
  #
  # PTV
  #
  check_token

  #
  # APIServer
  #
  get_tasks

  #
  # User Data
  #
  post_user_data
  get_user_data
  patch_user_data
  delete_user_data
  post_user_data_name
  get_user_data_name
  patch_user_data_name
  delete_user_data_name

  #
  # APIServerDaemon
  #
)
for t in ${TESTS[@]}; do
  do_test $t
  RES=$?
  [ $RES -ne 0 ] &&\
    echo "Error on test: '$t'" &&\
    break
done
out "Tests completed successfully,  details aviable at: fgSetup/test/.tests"

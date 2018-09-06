#
# Test script for FutureGateway
#
# Author: Riccardo Bruno <riccardo.bruno@ct.infn.it>
#

TKN="________TEST_TKN________"

[ ! -f .fgsetup ] &&\
  cd fgSetup &&\
  ./setup_futuregateway.sh &&\
  cd - &&
  touch .fgsetup ||\
  echo "Setup already executed"

PTV=$(sudo su - futuregateway -c "screen -ls | grep ptv")
[ "$PTV" == "" ] &&\
  sudo su - futuregateway\
     -c "screen -S ptv\
         -dm /bin/bash\
         -c \"cd fgAPIServer &&\
              pwd &&\
              source ./.venv/bin/activate &&\
              ./fgapiserver_ptv.py &&\
              sleep 60 || sleep 60\"" ||\
  echo "PTV already running"

# The array above contains any global scope temporaty file
TEMP_FILES=()

# Create temporary files
cleanup_tempFiles() {
  echo "Cleaning temporary files:"
  for tempfile in ${TEMP_FILES[@]}
  do
    printf "Cleaning up '"$tempfile"' ... "
    rm -rf $tempfile
    echo "done"
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

  printf "Test (%04d) - '$1' ... " $TEST_CNT
  if [ ! -f $TEST_FILE ]; then
    $TEST_CMD >$TEST_OUT 2>$TEST_ERR
    RES=$?
    if [ $RES -eq 0 ]; then
      # Produce json file for test execution
      echo "$TEST_NAME" > .tests/$TEST_FILE.name
      cat $TEST_CMD > .tests/$TEST_FILE.cmd
      cat $TEST_OUT > .tests/$TEST_FILE.out
      cat $TEST_ERR > .tests/$TEST_FILE.err
      echo "passed"
    else
      echo "failed"
      echo "Test command:"
      cat $TEST_CMD
      echo "Test output:"
      cat $TEST_OUT
      echo "Test error:"
      cat $TEST_ERR
    fi
  else
    echo "passed"
  fi
}

#
# Test counter
#
TEST_CNT=0

#
# PTV
#

cat >$TEST_CMD <<EOF
curl -f -d token="________TEST_TKN________" -u "tokenver_user:tokenver_pass" http://localhost:8889/checktoken
EOF
do_test "PTV checktoken" "ptv_checktoken"

#
# APIServer
#

cat >$TEST_CMD <<EOF
curl -f -H "Authorization: Bearer $TKN" http://localhost/fgapiserver/1.0/tasks
EOF
do_test "API: /tasks" "api_tasks"

#
# APIServerDaemon
#


#
# Test script for FutureGateway
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
  TEST_NAME=$1
  TEST_CASE=$2

  printf "Test - '$1' ... "
  if [ ! -f $TEST_CASE ]; then
    $TEST_CMD >$TEST_OUT 2>$TEST_ERR
    RES=$?
    if [ $RES -eq 0 ]; then
      echo "Test name: $TEST_NAME" > $TEST_CASE
      echo "Test command:"  >> $TEST_CASE
      cat $TEST_CMD >> $TEST_CASE
      echo "Test output:" >> $TEST_CASE
      cat $TEST_OUT >> $TEST_CASE
      echo "Test error:" >> $TEST_CASE
      cat $TEST_ERR >> $TEST_CASE
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
# PTV
#

cat >$TEST_CMD <<EOF
curl -f -d token="________TEST_TKN________" -u "tokenver_user:tokenver_pass" http://localhost:8889/checktoken
EOF
do_test "PTV checktoken" ".ptv_checktoken"

#
# APISrv
#
cat >$TEST_CMD <<EOF
curl -f -H "Authorization: Bearer $TKN" http://localhost/fgapiserver/1.0/tasks
EOF
do_test "API: /tasks" ".api_tasks"



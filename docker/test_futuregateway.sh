#!/bin/bash
#
# test_futuregateway - Perform core tests on FutureGateway APIs
#
# Author: Riccardo Bruno INFN <riccardo.bruno@ct.infn.it>
#

# Tests are done submitting SayHello application, this needs to 
# This needs to change the setup_app file
for f in $(find $HOME/.fgprofile -type f); do source $f; done # FGLOADENV

FGHOST=localhost/$FGAPISERVER_APIVER
[ "$TEST_USER" = "" ] && TEST_USER="test"
[ "$TEST_PASSWORD" = "" ] && TEST_PASSWORD="test"

echo ""
echo "------------------------------------------"
echo "Testing FutureGateway core functionalities"
echo "------------------------------------------"
echo ""
cd apps/sayhello


# Retrieve access token (using futuregateway/futuregateway)
TKN=$(curl -s\
           -H "Content-type: application/json"\
           -H "Authorization: futuregateway:ZnV0dXJlZ2F0ZXdheQ=="\
           -X POST\
          $FGHOST/auth |\
      jq '.token' |\
      xargs echo) &&\
echo "Session token from credentials: futuregateway/futuregateway: '$TKN'"

# Checkpoint on Token
[ "$TKN" = "" ] &&\
  echo "ERROR: Unable to retrieve session token" &&\
  exit 1

# Configure TKN in seutp file
API_URL=$(echo $FGHOST | sed s/\\//\\\\\\//g)
sed -i "s/<place token here>/$TKN/" setup_app.sh
sed -i "s/API_URL=.*/API_URL=$API_URL/" setup_app.sh

# The setup script needs to setup the infrastrucure and retrieve its numeric
# identifier (INFRA_ID)
INFRA_ID=$(curl -s\
                -H "Authorization: $TKN"\
                -H "Content-Type: application/json"\
                -X POST\
                -d "{ \"name\": \"Test infrastructure\",
                      \"parameters\": [
                        { \"name\": \"jobservice\",
                          \"value\": \"ssh://sshnode\" },
                        { \"name\": \"username\",
                          \"value\": \"$TEST_USER\" },
                        { \"name\": \"password\",
                          \"value\": \"$TEST_PASS\" }],
                      \"description\": \"sshnode test infrastructure\",
                      \"enabled\": true,
                      \"virtual\": false }"\
                $FGHOST/infrastructures|\
            jq '.id' |\
            xargs echo) &&\
echo "Installed test infrastructure having id: '$INFRA_ID'"

# Checkpoint on Infrastructure
[ "$INFRA_ID" = "" ] &&\
  echo "ERROR: Unable to create infrastructure" &&\
  exit 1

# Configure infrastructure in setup file
sed -i "s/infrastructures\":\ \[1\]/infrastructures\":\ \[$INFRA_ID\]/" setup_app.sh
sed -i "s/Authorization:\ Bearer/Authorization:\ /" setup_app.sh

# Call setup script to install SayHello application
./setup_app.sh

# Retrieve the application numeric identifier (APP_ID) as last inserted application
APP_ID=$(curl -H "Authorization: $TKN" $FGHOST/applications |\
         jq '.applications[].id' |\
         tail -n 1 |\
         xargs echo) &&\
echo "SayHello application successfully installed having id: '$APP_ID'"

# Checkpoint on Applicaiton
[ "$APP_ID" = "" ] &&\
  echo "ERROR: Unable to create application" &&\
  exit 1

# Execute app
POST_DATA=$(mktemp)
cat >$POST_DATA <<EOF
{"application":"$APP_ID",
 "description":"sayhello by app_id: $APP_ID test run",
  "arguments": ["This is the argument"],
  "output_files": [{"name": "sayhello.data"}]}
EOF
curl -H "Content-Type: application/json"\
     -H "Authorization: $TKN"\
     -X POST\
     -d @$POST_DATA $FGHOST/tasks

# Get last task_id
TASK_ID=$(curl -H "Authorization: $TKN" $FGHOST/tasks |\
          jq '.tasks[].id' |\
          xargs -I{} echo "{}" |\
          sort |\
          tail -n 1) &&\
echo "Task successfully submitted with task identifier: '$TASK_ID'"

# Checkpoint on Task
[ "$TASK_ID" = "" ] &&\
  echo "ERROR: Unable to create task from application having id: '$APP_ID'" &&\
  exit 1

# Loop on task status, until DONE or reaching a timeout (LOOP_DELAY*MAXCOUNT)
# seconds
CNT=0
MAXCNT=180
LOOP_DELAY=60
TASK_STATUS=""
while [ $CNT -lt $MAXCNT ]; do
    TASK_STATUS=$(curl -s\
                       -H "Authorization: $TKN"\
                       $FGHOST/tasks/$TASK_ID |\
                       jq '.status' |\
                       xargs echo) &&\
    echo "Task having id: '$TASK_ID' has status: '$TASK_STATUS'"
    [ "$TASK_STATUS" = 'DONE' ] &&\
      break ||\
      sleep $LOOP_DELAY
    CNT=$((CNT+1))
done

# Checkpoint on task status, when DONE, retrieve SayHello output
if [ "$TASK_STATUS" = "DONE" ]; then
  OUTPUT_FILES=$(curl -s\
                 -H "Authorization: $TKN"\
                 $FGHOST/tasks/$TASK_ID |\
                 jq '.output_files[]' |\
                 jq '.url+"|"+.name' |\
                 xargs echo) &&\
  for of in $OUTPUT_FILES; do\
    URL=$(echo $of | awk -F"|" '{ print $1 }');\
    FNM=$(echo $of | awk -F"|" '{ print $2 }');\
    curl  -s -H "Authorization: $TKN" "$FGHOST/$URL" > $FNM;\
    MSG="# File: '$FNM' #";\
    MSGLN=$(echo $MSG | tr '[:print:]' '#');\
    echo $MSGLN;\
    echo $MSG;\
    echo $MSGLN;\
    cat $FNM;
  done
else
  echo "ERROR: Task with identifier '$TASK_ID' did not finished in DONE status"
  exit 1
fi

# Notify successful execution
echo
echo "-----------------------------------------"
echo "Submission test successfully accomplished"
echo "-----------------------------------------"


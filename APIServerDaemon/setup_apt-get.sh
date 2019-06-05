#!/bin/bash
#
# FutureGateway APIServerDaemon apt-get version setup script
#
# Author: Riccardo Bruno <riccardo.bruno@ct.infn.it>
#

source .fgprofile/commons
source .fgprofile/apt_commons
source .fgprofile/config

FGLOG=$HOME/APIServerDaemon.log
ASDB_OPTS="-sN"

# The array above contains any global scope temporaty file
TEMP_FILES=() 

# Create temporary files
cleanup_tempFiles() {
  echo "Cleaning temporary files:"
  for tempfile in ${TEMP_FILES[@]}
  do
    #echo "Viewing '"$tempfile"':"
    #cat $tempfile
    printf "Cleaning up '"$tempfile"' ... "
    rm -rf $tempfile
    echo "done"
  done
}

#
# Script body
#

# Cleanup global scope temporary files upon exit
trap cleanup_tempFiles EXIT

# Local temporary files for SSH output and error files
STD_OUT=$(mktemp -t stdout.XXXXXX)
STD_ERR=$(mktemp -t stderr.XXXXXX)
TEMP_FILES+=( $STD_OUT )
TEMP_FILES+=( $STD_ERR )
CMD_FILE=$(mktemp -t command.XXXXXX)
CMD_OUT=$(mktemp -t stdout.XXXXXX)
CMD_ERR=$(mktemp -t stderr.XXXXXX)
TEMP_FILES+=( $CMD_FILE )
TEMP_FILES+=( $CMD_OUT )
TEMP_FILES+=( $CMD_ERR )

out "Starting FutureGateway APIServerDaemon apt-get versioned setup script"

# Check for FutureGateway fgAPIServer unix user
check_and_create_user $FGAPISERVER_APPHOSTUNAME

# Determine Tomcat version
TOMCATV=$(apt-cache search tomcat |\
          awk -F"-" '{ print $1 }' |\
          grep tomcat |\
          grep -v lib |\
          sort -u |\
          tail -n 1|\
          xargs echo)

# Mandatory packages installation
out "Installing packages ..." 1
# Mandatory packages installation
APTPACKAGES=(
  curl
  git
  wget
  coreutils
  jq
  mysql-client
  libmysql-java
  ant
  maven
  default-jdk
  $TOMCATV
)
CMD="install_apt ${APTPACKAGES[@]}"
exec_cmd "Error installing required packages"

#
# Checking packages consistency
#

# Check mandatory command line commands
out "Verifying mandatory commands ... " 1
CMD="MISSING_PKGS=\"\"; \
     GIT=\$(which git || \$MISSING_PKGS=\$MISSING_PKGS\"git \"); \
     ANT=\$(which ant || \$MISSING_PKGS=\$MISSING_PKGS\"ant \"); \
     MVN=\$(which mvn || \$MISSING_PKGS=\$MISSING_PKGS\"mvn \"); \
     CATALINA=\$(ls -1 /etc/init.d | grep tomcat); \
     CATALINASYSD=\$(find /etc/systemd/ | grep tomcat); \
     [ \"\$CATALINA \$CATALINASYSD\" = \"\" ] && \$MISSING_PKGS=\$MISSING_PKGS\"tomcat \"; \
     JAVA=\$(which java || \$MISSING_PKGS=$MISSING_PKGS\"java \"); \
     [ \"\$MISSING_PKGS\" == \"\" ] || echo  \"Missing packages identified: \$MISSING_PKGS\""
exec_cmd "Following mandatory commands are not present: \"$MISSING_PKGS\"" "(git: \$GIT, ant: \$ANT, mvn: \$MVN, tomcat: \$CATALINA, java: \$JAVA)"

# Check Java v >= 1.6.0
CMD="JAVA_VER=\$(java -version 2>&1|\
                 grep version |\
                 awk '{ print \$3 }' |\
                 xargs echo |\
                 awk -F\"_\" '{ print \$1 }' |\
                 tr -d '.'); [ \"\$JAVA_VER\" -gt 160 ]"
exec_cmd "Unsupported java version; (>= 1.6.0)" "(java version: \$JAVA_VER)" "(java version: \$JAVA_VER)" 

# Check and configure catalina (Tomcat)
if [ "$CATALINA" != "" ]; then
  export CATALINA_HOME=$(cat /etc/init.d/$CATALINA |\
                         grep ^CATALINA_HOME |\
                         awk -F'=' '{ print $2}' |\
                         sed s/\$NAME/$CATALINA/ |\
                         xargs echo)
  export CATALINA_BASE=$(cat /etc/init.d/$CATALINA |\
                         grep ^CATALINA_BASE |\
                         awk -F'=' '{ print $2}' |\
                         sed s/\$NAME/$CATALINA/ |\
                         xargs echo)
elif [ "$CATALINASYSD" != "" ]; then
  export CATALINA_HOME=$(cat $CATALINASYSD |\
                   grep ^Environment |\
       awk -F'="' '{ print substr($2, 1, length($2)-1); }' |\
       grep ^CATALINA_HOME |\
       awk -F '=' '{ print $2 }' |\
       xargs echo)
  export CATALINA_BASE=$(cat $CATALINASYSD |\
                         grep ^Environment |\
                         awk -F'="' '{ print substr($2, 1, length($2)-1); }' |\
                         grep ^CATALINA_BASE |\
                         awk -F '=' '{ print $2 }' |\
                         xargs echo)
else
  err "WARNING: No tomcat in /etc/init.d nor in /etc/systemd" 
fi  

out "CATALINA_HOME=$CATALINA_HOME"
out "CATALINA_BASE=$CATALINA_BASE"

CMD="[ \"\$CATALINA_HOME\" != \"\" -a \"\$CATALINA_BASE\" != \"\" ]"
exec_cmd "Did not find Tomcat environment variables CATALINA_HOME or CATALINA_BASE"

TOMCAT_SYSUSR=$(cat /etc/passwd | grep tomcat | awk -F':' '{ print $1 }')

cat >$CMD_FILE <<EOF
TOMCAT_CONFDIR=/etc/$TOMCATV &&\
TOMCAT_USRFILE=\$TOMCAT_CONFDIR/tomcat-users.xml &&\
sudo chmod -R 644 \$TOMCAT_CONFDIR &&\
sudo chmod g+x,o+x,o+w \$TOMCAT_CONFDIR &&\
sudo chmod g+x,g+w,o+w \$TOMCAT_USRFILE;\
if [ ! -f \${TOMCAT_USRFILE}_fgsetup ]; then
  sudo cp -n \$TOMCAT_USRFILE \${TOMCAT_USRFILE}_fgsetup &&\
  LN=\$(sudo cat \${TOMCAT_USRFILE}_fgsetup | grep -n "</tomcat-users>" | awk -F":" '{ print \$1 }') &&\
  ALN=\$(sudo cat \${TOMCAT_USRFILE}_fgsetup | wc -l) &&\
  sudo cat \${TOMCAT_USRFILE}_fgsetup | head -n \$((LN-1)) > \$TOMCAT_USRFILE &&\
  sudo echo "                 <role rolename=\\"manager-gui\\"/>" >> \$TOMCAT_USRFILE &&\
  sudo echo "                 <role rolename=\\"manager-script\\"/>" >> \$TOMCAT_USRFILE &&\
  sudo echo "                 <role rolename=\\"tomcat\\"/>" >> \$TOMCAT_USRFILE &&\
  sudo echo "                 <role rolename=\\"liferay\\"/>" >> \$TOMCAT_USRFILE &&\
  sudo echo "                 <user username=\\"$TOMCAT_USER\\" password=\\"$TOMCAT_PASSWORD\\" roles=\\"tomcat,liferay,manager-gui,manager-script\\"/>" >> \$TOMCAT_USRFILE &&\
  sudo cat \${TOMCAT_USRFILE}_fgsetup | tail -n \$((ALN-LN+1)) >> \$TOMCAT_USRFILE &&\
  sudo chmod o-w \$TOMCAT_CONFDIR &&\
  sudo chmod o-w \$TOMCAT_USRFILE;\
else\
  err "Warning file: '\${TOMCAT_USRFILE}' already processed";\
fi
EOF
CMD=$(cat $CMD_FILE)
exec_cmd "Unable to configure tomcat user roles"

out "Setup mysql-connector" 1
CMD="sudo updatedb &&\
     MYSQL_CONNECTOR=\$(locate mysql-connector-java | grep jar | head -n 1) &&\
     cd \$CATALINA_HOME/lib &&\
     sudo rm -f mysql-connector-java.jar &&\
     sudo ln -s \$MYSQL_CONNECTOR mysql-connector-java.jar &&\
     [ -L mysql-connector-java.jar ] &&\
     cd -"
exec_cmd "Unable to setup mysql-connector" "(\$MYSQL_CONNECTOR)"

out " Configuring GridEngine connection pools" 1
cat >$CMD_FILE <<EOF
TOMCAT_CONFDIR=/etc/$TOMCATV &&\
SERVER_XML=\$TOMCAT_CONFDIR/server.xml &&\
sudo chmod g+x,g+w,o+x,o+w \$TOMCAT_CONFDIR &&
sudo chmod g+r,g+w,o+r,o+w \$SERVER_XML;\
if [ ! -f \${SERVER_XML}_fgsetup ]; then
  sudo cp -n \$SERVER_XML \${SERVER_XML}_fgsetup &&\
  LN=\$(cat \${SERVER_XML}_fgsetup | grep -n "</GlobalNamingResources>" | awk -F":" '{ print \$1 }') &&\
  ALN=\$(cat \${SERVER_XML}_fgsetup | wc -l) &&\
  sudo cat \${SERVER_XML}_fgsetup | head -n \$((LN-1)) > \$SERVER_XML &&\
  sudo echo "               <Resource name=\\"jdbc/UserTrackingPool\\"" >> \$SERVER_XML &&\
  sudo echo "                           auth=\\"Container\\"" >> \$SERVER_XML &&\
  sudo echo "                           type=\\"javax.sql.DataSource\\"" >> \$SERVER_XML &&\
  sudo echo "                           username=\\"$UTDB_USER\\"" >> \$SERVER_XML &&\
  sudo echo "                           password=\\"$UTDB_PASSWD\\"" >> \$SERVER_XML &&\
  sudo echo "                           driverClassName=\\"com.mysql.jdbc.Driver\\"" >> \$SERVER_XML &&\
  sudo echo "                           url=\\"jdbc:mysql://$UTDB_HOST:$UTDB_PORT/$UTDB_NAME\\"" >> \$SERVER_XML &&\
  sudo echo "                           testOnBorrow=\\"true\\"" >> \$SERVER_XML &&\
  sudo echo "                           testWhileIdle=\\"true\\"" >> \$SERVER_XML &&\
  sudo echo "                           validationInterval=\\"0\\"" >> \$SERVER_XML &&\
  sudo echo "                           initialSize=\\"3\\"" >> \$SERVER_XML &&\
  sudo echo "                           maxTotal=\\"100\\"" >> \$SERVER_XML &&\
  sudo echo "                           maxIdle=\\"30\\"" >> \$SERVER_XML &&\
  sudo echo "                           maxWaitMillis=\\"10000\\"" >> \$SERVER_XML &&\
  sudo echo "                           validationQuery=\\"select 1 as connection_test\\"/>" >> \$SERVER_XML &&\
  sudo echo "                 <Resource name=\\"jdbc/gehibernatepool\\"" >> \$SERVER_XML &&\
  sudo echo "                           auth=\\"Container\\"" >> \$SERVER_XML &&\
  sudo echo "                           type=\\"javax.sql.DataSource\\"" >> \$SERVER_XML &&\
  sudo echo "                           username=\\"$UTDB_USER\\"" >> \$SERVER_XML &&\
  sudo echo "                           password=\\"$UTDB_PASSWD\\"" >> \$SERVER_XML &&\
  sudo echo "                           driverClassName=\\"com.mysql.jdbc.Driver\\"" >> \$SERVER_XML &&\
  sudo echo "                           url=\\"jdbc:mysql://$UTDB_HOST:$UTDB_PORT/$UTDB_NAME\\"" >> \$SERVER_XML &&\
  sudo echo "                           testOnBorrow=\\"true\\"" >> \$SERVER_XML &&\
  sudo echo "                           testWhileIdle=\\"true\\"" >> \$SERVER_XML &&\
  sudo echo "                           validationInterval=\\"0\\"" >> \$SERVER_XML &&\
  sudo echo "                           initialSize=\\"3\\"" >> \$SERVER_XML &&\
  sudo echo "                           maxTotal=\\"100\\"" >> \$SERVER_XML &&\
  sudo echo "                           maxIdle=\\"30\\"" >> \$SERVER_XML &&\
  sudo echo "                           maxWaitMillis=\\"10000\\"" >> \$SERVER_XML &&\
  sudo echo "                           validationQuery=\\"select 1 as connection_test\\"/>" >> \$SERVER_XML &&\
  sudo cat \${SERVER_XML}_fgsetup | tail -n \$((ALN-LN+1)) >> \$SERVER_XML &&\
  sudo chmod g+x,g-w,o+x,o-w \$TOMCAT_CONFDIR &&\
  sudo chmod g+r,g-w,o+r,o-w \$SERVER_XML;\
else\
  err "Warning file: '\${SERVER_XML}' already processed";\
fi
EOF
CMD=$(cat $CMD_FILE)
exec_cmd "Unable to setup UserTracking connection pools"

# It seems a missing directory exists
out "Setting up Tomcat directories ... " 1
CMD="sudo mkdir -p \$CATALINA_HOME/temp &&\
     sudo mkdir -p \$CATALINA_HOME/logs &&\
     sudo mkdir -p \$CATALINA_HOME/conf &&\
     sudo mkdir -p \$CATALINA_HOME/common/classes &&\
     sudo mkdir -p \$CATALINA_HOME/server/classes &&\
     sudo mkdir -p \$CATALINA_HOME/shared/classes &&\
     sudo mkdir -p \$CATALINA_BASE/webapps/ROOT &&\
     sudo chown -R $TOMCAT_SYSUSR:\$USER \$CATALINA_HOME &&\
     sudo chown -R $TOMCAT_SYSUSR:\$USER \$CATALINA_BASE &&\
     sudo mv -n $CATALINA_BASE/webapps/ROOT $CATALINA_HOME/webapps/ &&\
     cd \$CATALINA_HOME/conf &&\
     sudo rm -f tomcat-users.xml &&\
     sudo ln -s \$TOMCAT_USRFILE tomcat-users.xml &&\
     sudo rm -f server.xml &&\
     sudo ln -s \$SERVER_XML server.xml &&\
     cd -"
exec_cmd "Unable to setup $TOMCATV directories"

# Set shutdown port
replace_line $TOMCAT_CONFDIR/server.xml "<Server port=\"-1\"" "<Server port=\"8005\" shutdown=\"SHUTDOWN\">"

# Setup groups
#  futuregateway in tomcat group
#  tomcat in futuregatway group
#  tomcat in www-data (needed for FGAPISERVER_IOPATH)
sudo usermod -a -G $TOMCAT_SYSUSR $FG_USER
sudo usermod -a -G $FG_USER $TOMCAT_SYSUSR
sudo usermod -a -G www-data $TOMCAT_SYSUSR
sudo usermod -a -G $TOMCAT_SYSUSR www-data 

# Check mysql client
out "Looking up mysql client ... " 1
CMD="MYSQL=\$(which mysql)"
exec_cmd "Did not find mysql command" "(\$MYSQL)"

# Check mysql version
out "Looking up mysql version ... " 1
CMD="MYSQLVER=\$(\$MYSQL -V | awk '{ print \$5 }' | awk -F \".\" '{ v=\$1*10+\$2; printf (\"%s\",v) }')"
exec_cmd "Did not retrieve mysql version" "(\$MYSQLVER)"

#Check connectivity
out "Checking mysql connectivity ... " 1
CMD="$MYSQL -h $UTDB_HOST -P $UTDB_PORT -u root -p$UTDB_ROOTPWD -e \"select version()\" >$CMD_OUT 2>$CMD_ERR"
exec_cmd "Missing mysql connectivity"

#
# Software packages setup
#

out "Extracting/installing software ..."

# JSAGA
# PortalSetup used to install jsaga and its libraries accordingly to the instructions
# reported on its download page: http://software.in2p3.fr/jsaga/latest-release/download.html
# Actually the new recommended way to install it is via maven configuring the java project.
# This installation will perform the new suggested way as reported at:
# https://indigo-dc.gitbooks.io/jsaga-resource-management/content/deployment.html
sudo mkdir -p $CATALINA_BASE/bin
sudo cat > $CATALINA_BASE/bin/setenv.sh <<EOF
export JSAGA_HOME=${HOME}
EOF
sudo chmod +x $CATALINA_BASE/bin/setenv.sh
sudo chown -R $TOMCAT_SYSUSR:$FG_USER $CATALINA_BASE

# Above setenv.sh seems to be ignored, the following allows the execution
sudo mkdir /.jsaga
sudo chown $TOMCAT_SYSUSR:$FG_USER /.jsaga
sudo chmod g+r,g+w,g+x /.jsaga 


# OCCI+(GSI)
OCCI=$(which occi)
if [ "$OCCI" != "" -a -d /etc/grid-security/vomsdir -a -d /etc/vomses/ ]; then
    out "WARNING: Most probably OCCI client and GSI are already installed; skipping their installation"
else
    curl -s -L http://go.egi.eu/fedcloud.ui | sudo /bin/bash -
    # Fix apt list files, otherwise apt will not work anymore
    sudo rm -f /etc/apt/sources.list.d/UMD-3-base.list\
               /etc/apt/sources.list.d/UMD-3-updates.list\
               /etc/apt/sources.list.d/rocci.list 

    # Now configure VO fedcloud.egi.eu
    sudo mkdir -p /etc/grid-security/vomsdir/fedcloud.egi.eu

    sudo chmod o+w /etc/grid-security/vomsdir/fedcloud.egi.eu
    sudo cat > /etc/grid-security/vomsdir/fedcloud.egi.eu/voms1.egee.cesnet.cz.lsc << EOF 
/DC=org/DC=terena/DC=tcs/OU=Domain Control Validated/CN=voms1.egee.cesnet.cz
/C=NL/O=TERENA/CN=TERENA eScience SSL CA
EOF
    sudo cat > /etc/grid-security/vomsdir/fedcloud.egi.eu/voms2.grid.cesnet.cz << EOF 
/DC=org/DC=terena/DC=tcs/C=CZ/ST=Hlavni mesto Praha/L=Praha 6/O=CESNET/CN=voms2.grid.cesnet.cz
/C=NL/ST=Noord-Holland/L=Amsterdam/O=TERENA/CN=TERENA eScience SSL CA 3
EOF
    sudo chmod o-w /etc/grid-security/vomsdir/fedcloud.egi.eu
    sudo mkdir -p /etc/vomses
    sudo chmod o+w /etc/vomses
    sudo cat >> /etc/vomses/fedcloud.egi.eu << EOF 
"fedcloud.egi.eu" "voms1.egee.cesnet.cz" "15002" "/DC=org/DC=terena/DC=tcs/OU=Domain Control Validated/CN=voms1.egee.cesnet.cz" "fedcloud.egi.eu" "24"
"fedcloud.egi.eu" "voms2.grid.cesnet.cz" "15002" "/DC=org/DC=terena/DC=tcs/C=CZ/ST=Hlavni mesto Praha/L=Praha 6/O=CESNET/CN=voms2.grid.cesnet.cz" "fedcloud.egi.eu" "24"
EOF
    sudo chmod o-w /etc/vomses
fi

# Getting or updading software from Git
out "Getting APIServerDaemon source components ... " 1
MISSING_GITREPO="";
git_clone_or_update "$GNCENG_GIT_BASE" "$GNCENG_GITREPO" "$GNCENG_GITTAG" ||\
    MISSING_GITREPO=$MISSING_GITREPO"$GNCENG_GITREPO "
git_clone_or_update "$ROCCI_GIT_BASE" "$ROCCI_GITREPO" "$ROCCI_GITTAG" ||\
    MISSING_GITREPO=$MISSING_GITREPO"$ROCCI_GITREPO "
git_clone_or_update "$GIT_BASE" "$APISERVERDAEMON_GITREPO" "$APISERVERDAEMON_GITTAG" ||\
    MISSING_GITREPO=$MISSING_GITREPO"$APISERVERDAEMON_GITREPO "
CMD="[ \"$MISSING_GITREPO\" == \"\" ]"
exec_cmd "Following Git repositories failed to clone/update: \"$MISSING_GITREPO\"" "" "missing repositories: \"$MISSING_GITREPO\""

# Create Grid and Cloud engine UsersTrackingDB
out "Installing Grid and Cloud Engine UsersTrackingDB ... "
INSTALL_UTDB=0
$MYSQL -h $UTDB_HOST -P $UTDB_PORT -u root -p$UTDB_ROOTPWD $UTDB_NAME -e "" 1>/dev/null 2>/dev/null &&\
  out "UsersTrackingDB already present" ||\
  INSTALL_UTDB=1
[ $INSTALL_UTDB -ne 0 ] &&\
  CMD="$MYSQL -h $UTDB_HOST -P $UTDB_PORT -u root -p$UTDB_ROOTPWD < grid-and-cloud-engine/UsersTrackingDB/UsersTrackingDB.sql" &&\
  exec_cmd "Unable to setup Grid and Cloud Engine UsersTrackingDB" ||\
  out "Grid and Cloud Engine UsersTrackingDB already present"

#
# Now it is possible to start Tomcat service
#
# Do not use service since containers may not accept this way
# Starting Tomcat using startup script
out "Checking for $TOMCATV service ... " 1
CMD="CATALINAP=$(ps -ef | grep \$TOMCATV | grep -v grep | grep java | awk '{ print \$2 }' | xargs echo)"
exec_cmd "Unable to verify catalina process" "(PID: \$CATALINAP)"

if [ "$CATALINAP" = "" ]; then
  out "Starting $TOMCATV ..." 1
  CMD="export UMASK="0022" &&\
       sudo -u $TOMCAT_SYSUSR $CATALINA_HOME/bin/catalina.sh start &&\
       CATALINAP=\$(ps -ef | grep $TOMCAT_SYSUSR | grep -v grep | grep java | awk '{ print \$2 }' | xargs echo) &&\
  [ \"\$CATALINAP\" != \"\" ]"
  exec_cmd "Unable to start service $TOMCATV" "($TOMCATV: \$CATALINAP)"
else
  out "Service $TOMCATV is already running with pid: $CATALINAP"
fi

#
# Compiling APIServerDaemon components and executor interfaces
#
out "Starting APIServerDaemon components compilation ... "

# Creting lib/ directory under APIServerDaemon dir
mkdir -p $APISERVERDAEMON_GITREPO/web/WEB-INF/lib

# Compile EI components and APIServerDaemon
MISSING_COMPILATION=""

# rOCCI jsaga adaptor for Grid and Cloud Engine
cd $ROCCI_GITREPO
ant all || MISSING_COMPILATION=$MISSING_COMPILATION"$ROCCI_GITREPO "
[ -f dist/$ROCCI_GITREPO.jar ] && cp dist/$ROCCI_GITREPO.jar ../$APISERVERDAEMON_GITREPO/lib/
cd - 2>&1 >/dev/null

# Grid and Cloud Engine
cd $GNCENG_GITREPO/grid-and-cloud-engine-threadpool
mvn install || MISSING_COMPILATION=$MISSING_COMPILATION"$GNCENG_GITREPO "
GNCENG_THREADPOOL_LIB=$(find . -name '*.jar' | grep grid-and-cloud-engine-threadpool)
[ -f $GNCENG_THREADPOOL_LIB ] && cp $GNCENG_THREADPOOL_LIB ../../$APISERVERDAEMON_GITREPO/lib/
cd - 2>&1 >/dev/null
cd $GNCENG_GITREPO/grid-and-cloud-engine_M
mvn install || MISSING_COMPILATION=$MISSING_COMPILATION"$GNCENG_GITREPO "
GNCENG_GNCENG_LIB=$(find . -name '*.jar' | grep grid-and-cloud-engine_M)
[ -f $GNCENG_GNCENG_LIB ] && cp $GNCENG_GNCENG_LIB ../../$APISERVERDAEMON_GITREPO/lib/
cd - 2>&1 >/dev/null

cd $APISERVERDAEMON_GITREPO
# APIServerDaemon.properties
PROPF=./web/WEB-INF/classes/it/infn/ct/APIServerDaemon.properties
replace_line $PROPF "apisrv_dbhost" "apisrv_dbhost = $FGDB_HOST"
replace_line $PROPF "apisrv_dbport" "apisrv_dbport = $FGDB_PORT"
replace_line $PROPF "apisrv_dbuser" "apisrv_dbuser = $FGDB_USER"
replace_line $PROPF "apisrv_dbuser" "apisrv_dbuser = $FGDB_USER"
replace_line $PROPF "apisrv_dbpass" "apisrv_dbpass = $FGDB_PASSWD"
replace_line $PROPF "apisrv_dbname" "apisrv_dbname = $FGDB_NAME"
replace_line $PROPF "apisrv_dbver" "apisrv_dbver = $FGDB_VER"
replace_line $PROPF "asdMaxThreads" "asdMaxThreads = $APISERVERDAEMON_MAXTHREADS"
replace_line $PROPF "asdCloseTimeout" "asdCloseTimeout = $APISERVERDAEMON_ASDCLOSETIMEOUT"
replace_line $PROPF "gePollingDelay" "gePollingDelay = $APISERVERDAEMON_GEPOLLINGDELAY"
replace_line $PROPF "gePollingMaxCommands" "gePollingMaxCommands = $APISERVERDAEMON_GEPOLLINGMAXCOMMANDS"
replace_line $PROPF "asControllerDelay" "asControllerDelay = $APISERVERDAEMON_ASCONTROLLERDELAY"
replace_line $PROPF "asControllerMaxCommands" "asControllerMaxCommands = $APISERVERDAEMON_ASCONTROLLERMAXCOMMANDS"
replace_line $PROPF "asTaskMaxRetries" "asTaskMaxRetries = $APISERVERDAEMON_ASTASKMAXRETRIES"
replace_line $PROPF "asTaskMaxWait" "asTaskMaxWait = $APISERVERDAEMON_ASTASKMAXWAIT"
replace_line $PROPF "utdb_jndi" "utdb_jndi = $APISERVERDAEMON_UTDB_JNDI"
replace_line $PROPF "utdb_host" "utdb_host = $APISERVERDAEMON_UTDB_HOST"
replace_line $PROPF "utdb_port" "utdb_port = $APISERVERDAEMON_UTDB_PORT"
replace_line $PROPF "utdb_user" "utdb_user = $APISERVERDAEMON_UTDB_USER"
replace_line $PROPF "utdb_pass" "utdb_pass = $APISERVERDAEMON_UTDB_PASS"
replace_line $PROPF "utdb_name" "utdb_name = $APISERVERDAEMON_UTDB_NAME"
# ToscaIDC.properties
PROPF=./web/WEB-INF/classes/it/infn/ct/ToscaIDC.properties
replace_line $PROPF "fgapisrv_ptvtokensrv" "fgapisrv_ptvendpoint = $TOSCAIDC_FGAPISRV_PTVENDPOINT/get-token/"
replace_line $PROPF "fgapisrv_ptvuser" "fgapisrv_ptvuser = $TOSCAIDC_FGAPISRV_PTVUSER"
replace_line $PROPF "fgapisrv_ptvpass" "fgapisrv_ptvpass = $TOSCAIDC_FGAPISRV_PTVPASS"
cd - 2>/dev/null >/dev/null
out "done" 0 1

# APIServerDaemon
cd $APISERVERDAEMON_GITREPO
mkdir -p src/main/webapp/WEB-INF/lib/
cp ../$ROCCI_GITREPO/dist/jsaga-adaptor-rocci.jar src/main/webapp/WEB-INF/lib/
cp ../$GNCENG_GITREPO/grid-and-cloud-engine_M/target/lib/*.jar src/main/webapp/WEB-INF/lib/
cp ../$GNCENG_GITREPO/grid-and-cloud-engine-threadpool/target/lib/*.jar src/main/webapp/WEB-INF/lib/
mvn install || MISSING_COMPILATION=$MISSING_COMPILATION"$APISERVERDAEMON_GITREPO "

# Verify compilation
out "Verify APIServerDaemon components compilation ... " 1
CMD="[ \"\$MISSING_COMPILATION\" = \"\" ]"
exec_cmd "Following APIServerDaemon components failed to compile: \"$MISSING_COMPILATION\"" "" "missing component: \"$MISSING_COMPILATION\""
out "Installing APIServerDaemon.war" 1
CMD="[ -f target/${APISERVERDAEMON_GITREPO}.war ] &&\
     sudo cp target/${APISERVERDAEMON_GITREPO}.war $CATALINA_HOME/webapps/"
exec_cmd "Unable to install APIServerDaemon.war file" 
cd - 2>&1 >/dev/null

out "Successfully compiled and installed APIServerDaemon components"

# APIServerDaemon accessrights and ownership, the loop waits until the webapp dir is available
MAX_LOOPS=6
for i in $(seq 1 $MAX_LOOPS); do
  [ -d $CATALINA_HOME/webapps/APIServerDaemon ] &&\
    out "APIServerDaemon directory: '"$CATALINA_HOME/webapps/APIServerDaemon"' exists" &&\
    break ||\
    out "APIServerDaemon directory: '"$CATALINA_HOME/webapps/APIServerDaemon"' not existing yet (${i}/${MAX_LOOPS})"
  sleep 10
done
if [ $i -gt $MAX_LOOPS ]; then
  out "WARNING: Reached timeout while looking for tomcat' APIServerDaemon folder"
else
  sudo chmod -R g+x,g+r,g+w,o+x,o+r $CATALINA_HOME/webapps/APIServerDaemon &&\
  sudo chown -R $TOMCAT_SYSUSR:$FG_USER $CATALINA_HOME/webapps/APIServerDaemon
fi

# Setup access rights to $FGAPISERVER_IOPATH
sudo chown -R futuregateway:tomcat $FGAPISERVER_IOPATH
sudo chmod -R u+r,u+w,u+x,g+r,g+w,g+x,o+r $FGAPISERVER_IOPATH

# Environment setup
out "Preparing the environment ..."
   
# Now take care of environment settings
out "Setting up \"$APISERVERDAEMON_HOSTUNAME\" user profile ..."
   
# Preparing user environment in .fgprofile/APIServerDaemon file
#   BGDB variables
#   DB macro functions
FGAPISERVERENVFILEPATH=.fgprofile/APIServerDaemon
cat >$FGAPISERVERENVFILEPATH <<EOF
#!/bin/bash
#
# APIServerDaemon Environment setting configuration file
#
# Very specific APIServerDaemon service components environment must be set here
#
# Author: Riccardo Bruno <riccardo.bruno@ct.infn.it>
export CATALINA_HOME=${CATALINA_HOME}
export CATALINA_BASE=${CATALINA_BASE}
EOF
#for vgdbvar in ${FGAPISERVER_VARS[@]}; do
#    echo "$vgdbvar=${!vgdbvar}" >> $FGAPISERVERENVFILEPATH
#done
## Now place functions from setup_commons.sh
#declare -f asdb  >> $FGAPISERVERENVFILEPATH
#declare -f asdbr >> $FGAPISERVERENVFILEPATH
#declare -f dbcn  >> $FGAPISERVERENVFILEPATH
#out "done" 0 1
out "User profile successfully created"

out "Successfully finished FutureGateway APIServerDaemon apt-get versioned setup script"
exit $RES

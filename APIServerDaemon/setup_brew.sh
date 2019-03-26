#!/bin/bash
#
# FutureGateway APIServerDaemon brew version setup script
#
# Author: Riccardo Bruno <riccardo.bruno@ct.infn.it>
#

source .fgprofile/commons
source .fgprofile/brew_commons
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

out "Starting FutureGateway APIServerDaemon brew versioned setup script"

out "Verifying package manager and APIServerDaemon user ..."

# Check for brew and install it eventually
check_and_setup_brew

# Check for FutureGateway fgAPIServer unix user
check_and_create_user $FGAPISERVER_APPHOSTUNAME

# Mandatory packages installation
if [ "$BREW" = "" ]; then
  out "Did not find brew package manager"
  exit 1
fi
out "Brew is on: \"$BREW\""

out "Installing packages ..."

# Mandatory packages installation
BREWPACKAGES=(
  git
  wget
  coreutils
  jq
  mysql
  ant
  maven
  tomcat
)
for pkg in ${BREWPACKAGES[@]}; do    
    install_brew "$pkg"     
done

# APIServerDaemon requires JAVA, but no installation procedure is actually included
# so that JDK us considered a necessary condition to run this script
# Java can be installed with:
#     brew cask install java
# The command above requires the user password
# Java may also installed via standard Oracle procedures

#
# Checking packages consistency
#

# Check mandatory command line commands
MISSING_PKGS=""
GIT=$(which git || $MISSING_PKGS=$MISSING_PKGS"git ")
ANT=$(which ant || $MISSING_PKGS=$MISSING_PKGS"ant ")
MVN=$(which mvn || $MISSING_PKGS=$MISSING_PKGS"mvn ")
CATALINA=$(which catalina || $MISSING_PKGS=$MISSING_PKGS"catalina ")
JAVA=$(which java || $MISSING_PKGS=$MISSING_PKGS"java ")
if [ "$MISSING_PKGS" != "" ]; then
  out "ERROR: Following mandatory commands are not present: \"$MISSING_PKGS\""
  exit 1
fi

# Check Java v >= 1.6.0
JAVA_VER=$(java -version 2>&1| grep version | awk '{ print $3 }' | xargs echo | awk -F"_" '{ print $1 }' | tr -d '.')
if [ "$JAVA_VER" -lt 160 ]; then
  out "ERROR: Unsupported java version; $JAVA_VER (>= 1.6.0)"
  exit 1
fi

# Check catalina (Tomcat)
# Catalina contains a check on tty avoiding output when this command returns 1 (not a tty)
# The following call cheats the tty command
ORIG_PATH=$PATH
echo "exit 0">tty; chmod +x tty; export PATH=.:$PATH\"
export CATALINA_HOME=$($CATALINA version | grep CATALINA_HOME| awk -F":" '{ print $2 }' | xargs echo )
export CATALINA_BASE=$($CATALINA version | grep CATALINA_BASE | awk -F":" '{ print $2 }' | xargs echo )
out "CATALINA_HOME=$CATALINA_HOME"
out "CATALINA_BASE=$CATALINA_BASE"
if [ "$CATALINA_HOME" = "" -o "$CATALINA_BASE" = "" ]; then
  out "ERROR: Did not find Tomcat environment variables CATALINA_HOME or CATALINA_BASE"
  exit 1
fi
# Reset the tty command to the original behavior
rm -f ./tty
export PATH=$ORIG_PATH
    
# Check mysql client
out "Looking up mysql client ... " 1
MYSQL=$(which mysql)
if [ "$MYSQL" = "" ]; then
    out "failed" 0 1
    out "Did not find mysql command"
    exit 1
fi
out "done ($MYSQL)" 0 1
        
#Check connectivity with fgdb
out "Checking mysql connectivity with FutureGateway DB ... " 1
ASDBVER=$(asdb "select version from db_patches order by 1 desc limit 1;")
RES=$?
if [ $RES -ne 0 ]; then
    out "failed" 0 1
    out "Missing mysql connectivity"
    exit 1
fi
out "done ($ASDBVER)" 0 1    

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

# OCCI+(GSI)
OCCI=$(which occi)
if [ "$OCCI" != "" -a -d /etc/grid-security/vomsdir -a -d /etc/vomses/ ]; then
  out "WARNING: Most probably OCCI client and GSI are already installed; skipping their installation"
else
    curl -L http://go.egi.eu/fedcloud.ui | sudo /bin/bash -

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
MISSING_GITREPO=""
git_clone_or_update "$GNCENG_GIT_BASE" "$GNCENG_GITREPO" "$GNCENG_GITTAG" || MISSING_GITREPO=$MISSING_GITREPO"$GNCENG_GITREPO "
git_clone_or_update "$ROCCI_GIT_BASE" "$ROCCI_GITREPO" "$ROCCI_GITTAG" || MISSING_GITREPO=$MISSING_GITREPO"$ROCCI_GITREPO "
git_clone_or_update "$GIT_BASE" "$APISERVERDAEMON_GITREPO" "$APISERVERDAEMON_GITTAG" || MISSING_GITREPO=$MISSING_GITREPO"$APISERVERDAEMON_GITREPO "
if [ "$MISSING_GITREPO" != "" ]; then
  out "ERROR: Following Git repositories failed to clone/update: \"$MISSING_GITREPO\""
  exit 1
fi

#
# Compiling APIServerDaemon components and executor interfaces
#
out "Starting APIServerDaemon components compilation ... "

# Creting lib/ directory under APIServerDaemon dir
mkdir -p $APISERVERDAEMON_GITREPO/lib

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

# APIServerDaemon configuration
# Now configure APIServerDaemon accordingly to configuration settings
out "Configuring APIServerDaemon ... " 1
cd $APISERVERDAEMON_GITREPO
# APIServerDaemon.properties
replace_line ./web/WEB-INF/classes/it/infn/ct/APIServerDaemon.properties "apisrv_dbhost" "apisrv_dbhost = $FGDB_HOST"
replace_line ./web/WEB-INF/classes/it/infn/ct/APIServerDaemon.properties "apisrv_dbport" "apisrv_dbport = $FGDB_PORT"
replace_line ./web/WEB-INF/classes/it/infn/ct/APIServerDaemon.properties "apisrv_dbuser" "apisrv_dbuser = $FGDB_USER"
replace_line ./web/WEB-INF/classes/it/infn/ct/APIServerDaemon.properties "apisrv_dbuser" "apisrv_dbuser = $FGDB_USER"
replace_line ./web/WEB-INF/classes/it/infn/ct/APIServerDaemon.properties "apisrv_dbpass" "apisrv_dbpass = $FGDB_PASS"
replace_line ./web/WEB-INF/classes/it/infn/ct/APIServerDaemon.properties "apisrv_dbname" "apisrv_dbname = $FGDB_NAME"
replace_line ./web/WEB-INF/classes/it/infn/ct/APIServerDaemon.properties "apisrv_dbver" "apisrv_dbver = $ASDBVER"
replace_line ./web/WEB-INF/classes/it/infn/ct/APIServerDaemon.properties "asdMaxThreads" "asdMaxThreads = $APISERVERDAEMON_MAXTHREADS"
replace_line ./web/WEB-INF/classes/it/infn/ct/APIServerDaemon.properties "asdCloseTimeout" "asdCloseTimeout = $APISERVERDAEMON_ASDCLOSETIMEOUT"
replace_line ./web/WEB-INF/classes/it/infn/ct/APIServerDaemon.properties "gePollingDelay" "gePollingDelay = $APISERVERDAEMON_GEPOLLINGDELAY"
replace_line ./web/WEB-INF/classes/it/infn/ct/APIServerDaemon.properties "gePollingMaxCommands" "gePollingMaxCommands = $APISERVERDAEMON_GEPOLLINGMAXCOMMANDS"
replace_line ./web/WEB-INF/classes/it/infn/ct/APIServerDaemon.properties "asControllerDelay" "asControllerDelay = $APISERVERDAEMON_ASCONTROLLERDELAY"
replace_line ./web/WEB-INF/classes/it/infn/ct/APIServerDaemon.properties "asControllerMaxCommands" "asControllerMaxCommands = $APISERVERDAEMON_ASCONTROLLERMAXCOMMANDS"
replace_line ./web/WEB-INF/classes/it/infn/ct/APIServerDaemon.properties "asTaskMaxRetries" "asTaskMaxRetries = $APISERVERDAEMON_ASTASKMAXRETRIES"
replace_line ./web/WEB-INF/classes/it/infn/ct/APIServerDaemon.properties "asTaskMaxWait" "asTaskMaxWait = $APISERVERDAEMON_ASTASKMAXWAIT"
replace_line ./web/WEB-INF/classes/it/infn/ct/APIServerDaemon.properties "utdb_jndi" "utdb_jndi = $APISERVERDAEMON_UTDB_JNDI"
replace_line ./web/WEB-INF/classes/it/infn/ct/APIServerDaemon.properties "utdb_host" "utdb_host = $APISERVERDAEMON_UTDB_HOST"
replace_line ./web/WEB-INF/classes/it/infn/ct/APIServerDaemon.properties "utdb_port" "utdb_port = $APISERVERDAEMON_UTDB_PORT"
replace_line ./web/WEB-INF/classes/it/infn/ct/APIServerDaemon.properties "utdb_user" "utdb_user = $APISERVERDAEMON_UTDB_USER"
replace_line ./web/WEB-INF/classes/it/infn/ct/APIServerDaemon.properties "utdb_pass" "utdb_pass = $APISERVERDAEMON_UTDB_PASS"
replace_line ./web/WEB-INF/classes/it/infn/ct/APIServerDaemon.properties "utdb_name" "utdb_name = $APISERVERDAEMON_UTDB_NAME"
# ToscaIDC.properties
replace_line ./web/WEB-INF/classes/it/infn/ct/ToscaIDC.properties "fgapisrv_ptvendpoint" "fgapisrv_ptvendpoint = $TOSCAIDC_FGAPISRV_PTVENDPOINT"
replace_line ./web/WEB-INF/classes/it/infn/ct/ToscaIDC.properties "fgapisrv_ptvuser" "fgapisrv_ptvuser = $TOSCAIDC_FGAPISRV_PTVUSER"
replace_line ./web/WEB-INF/classes/it/infn/ct/ToscaIDC.properties "fgapisrv_ptvpass" "fgapisrv_ptvpass = $TOSCAIDC_FGAPISRV_PTVPASS"
cd - 2>/dev/null >/dev/null
out "done" 0 1

# APIServerDaemon
cd $APISERVERDAEMON_GITREPO
ant all || MISSING_COMPILATION=$MISSING_COMPILATION"$APISERVERDAEMON_GITREPO "
[ -f dist/APIServerDaemon.war/$APISERVERDAEMON_GITREPO.war ] &&\
  cp dist/APIServerDaemon.war/$APISERVERDAEMON_GITREPO.war $CATALINA_HOME/webapps
cd - 2>&1 >/dev/null
if [ "$MISSING_COMPILATION" != "" ]; then
  out "ERROR: Following components did not compile successfully: \"$MISSING_COMPILATION\""
  exit 1
fi

out "Successfully compiled all APIServerDaemon components"


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
   


out "Successfully finished FutureGateway APIServerDaemon brew versioned setup script"
exit $RES

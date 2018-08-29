#!/bin/bash
#
# FutureGateway fgAPIServer brew version setup script
#
# Author: Riccardo Bruno <riccardo.bruno@ct.infn.it>
#

source .fgprofile/commons
source .fgprofile/apt_commons
source .fgprofile/config

FGLOG=$HOME/fgAPIServer.log
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

out "Starting FutureGateway fgAPIServer apt-get versioned setup script"

out "Verifying package manager and fgAPIServer user ..."

# Check for brew and install it eventually
check_and_setup_brew

# Check for FutureGateway fgAPIServer unix user
check_and_create_user $FGAPISERVER_APPHOSTUNAME

# Mandatory packages installation
out "Installing packages ..."

# Mandatory packages installation
APTPACKAGES=(
  git
  wget
  coreutils
  jq
  mysql-client
  python
  python-pip
  apache2
  apache2-utils
  libexpat1
  ssl-cert
  libapache2-mod-wsgi
  virtualenv
)
install_apt ${APTPACKAGES[@]}

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

#Check apache2
out "Checkgin apache2 ... " 1
sudo service apache2 start
RES=$?
if [ $RES -ne 0 ]; then
    out "failed" 0 1
    out "Service apache2 wont start"
    exit 1
fi
our "done" 0 1

# Getting or updading software from Git
git_clone_or_update "$GIT_BASE" "$FGAPISERVER_GITREPO" "$FGAPISERVER_GITTAG"
RES=$?
if [ $RES -ne 0 ]; then
   out "ERROR: Unable to clone or update repository: \"$FGAPISERVER_GITREPO\""
   exit 1
fi 

# Environment setup
if [ $RES -eq 0 ]; then

   out "Preparing the environment ..."

   # Python virtualenv and dependencies
   cd fgAPIServer
   out "Installing python virtualenv and dependencies ..." 1
   RES=1
   sudo pip install --upgrade pip virtualenv && RES=0
   if [ $RES -ne 0 ]; then
      out "failed" 0 1
      out "Unable to install python virtualenv"
   fi
   if [ $RES -eq 0 ]; then
      RES=1 &&
      virtualenv .venv &&
      source ./.venv/bin/activate &&    
      pip install -r requirements.txt &&
      RES=0
      if  [ $RES -ne 0 ]; then
        out "failed" 0 1
        out "Unable to install python requirements"
      fi
   fi
   cd - 2>/dev/null >/dev/null
   [ $RES -eq 0 ] && out "done" 0 1 || exit 1
   out "Python virtualenv and dependencies successfully installed"
 
   # Take care of config values to setup fgapiserver.conf properly
   
   # WSGI or screen configuration
   if [ $FGAPISERVER_WSGI -ne 0 ]; then
       out "Configuring fgAPIServer for wsgi ..."
       
       # Configureing WSGI with apache
       if [ ! -d /etc/apache2 ]; then
           out "ERROR: Apache2 seems not installed in your system, impossible to configure wsgi"
           exit 1
       fi
       sudo su - -c "chmod o+w /etc/apache2/other"
       sudo cat >/etc/apache2/other/fgapiserver.conf <<EOF
LoadModule wsgi_module $MOD_WSGI
<IfModule wsgi_module>
    <VirtualHost *:80>
        ServerName fgapiserver
        WSGIDaemonProcess fgapiserver user=$FGAPISERVER_APPHOSTUNAME group=Admin processes=2 threads=5 home=$HOME/$FGAPISERVER_GITREPO python-path=$MYSQLPYPATH
        WSGIProcessGroup fgapiserver
        WSGIScriptAlias /fgapiserver $HOME/$FGAPISERVER_GITREPO/fgapiserver.wsgi
        <Directory $HOME/$FGAPISERVER_GITREPO>
                WSGIProcessGroup fgapiserver
                WSGIApplicationGroup %{GLOBAL}
                Order deny,allow
                Allow from all
                Options All
                AllowOverride All
                Require all granted
        </Directory>
    </VirtualHost>
</IfModule>
EOF
        sudo su - -c "chmod o-w /etc/apache2/other"
        sudo service apache2 restart
   else
       out "Configuring fgAPIServer for stand-alone execution ..."
       cat >/etc/init.d/fgapiserver << EOF
#! /bin/sh

### BEGIN INIT INFO
# Provides:		fgapiserver
# Required-Start:	$remote_fs $syslog
# Required-Stop:	$remote_fs $syslog
# Default-Start:	2 3 4 5
# Default-Stop:		
# Short-Description:	FutureGateway API server
### END INIT INFO

set -e

# /etc/init.d/fgapiserver: start and stop the FutureGateway API Server" daemon

umask 022

. /lib/lsb/init-functions

startfg() {
  cd $HOME 
  . ./venv/bin/activate
  python fgapiserver.py
  cd -
}

stopfg() {
  FGPROC=$(ps -ef | grep python | grep fgapiserver.py | grep -v grep | | awk '{ print $2 }')
  kill $FGPROC
}

export PATH="${PATH:+$PATH:}/usr/sbin:/sbin"

case "$1" in
  start)
	startfg
	;;
  stop)
	stopfg
	;;

  restart)
	startfg
	stopfg
	;;

  *)
	log_action_msg "Usage: /etc/init.d/fgapiserver {start|stop|reload|force-reload|restart|try-restart|status}" || true
	exit 1
esac

exit 0
EOF
       # Executing fgAPIServer service
       sudo service fgapiserver start
       # In case switching from wsgi to stand-alone
       [ -f /etc/apache2/other/fgapiserver.conf ] && sudo service apache2 restart
   fi
   # Now take care of environment settings
   out "Setting up '"$FGAPISERVER_APPHOSTUNAME"' user profile ..."
   
   # Preparing user environment in .fgprofile/APIServerDaemon file
   #   BGDB variables
   #   DB macro functions
   FGAPISERVERENVFILEPATH=.fgprofile/APIServerDaemon
   cat >$FGAPISERVERENVFILEPATH <<EOF
#!/bin/bash
#
# fgAPIServer Environment setting configuration file
#
# Very specific fgAPIServer service components environment must be set here
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
   
   # Now configure fgAPIServer accordingly to configuration settings
   out "Configuring fgAPIServer ... " 1
   cd $HOME/$FGAPISERVER_GITREPO
   replace_line fgapiserver.conf "fgapisrv_host" "fgapisrv_host = \"$FGAPISERVER_APPHOST\""
   replace_line fgapiserver.conf "fgapisrv_debug" "fgapisrv_debug = \"$FGAPISERVER_DEBUG\""
   replace_line fgapiserver.conf "fgapisrv_port" "fgapisrv_port = \"$FGAPISERVER_PORT\""
   replace_line fgapiserver.conf "fgapisrv_iosandbox" "fgapisrv_iosandbox = \"$FGAPISERVER_IOPATH\""
   replace_line fgapiserver.conf "fgapisrv_db_port" "fgapisrv_db_port = \"$FGDB_PORT\""
   replace_line fgapiserver.conf "fgapisrv_db_pass" "fgapisrv_db_pass = \"$FGDB_PASSWD\""
   replace_line fgapiserver.conf "fgapisrv_db_host" "fgapisrv_db_host = \"$FGDB_HOST\""
   replace_line fgapiserver.conf "fgapisrv_db_name" "fgapisrv_db_name = \"$FGDB_HOST\""
   replace_line fgapiserver.conf "fgapisrv_dbver" "fgapisrv_dbver = \"$ASDBVER\""
   replace_line fgapiserver.conf "fgapisrv_geappid" "fgapisrv_geappid = \"$UTDB_FGAPPID\""
   replace_line fgapiserver.conf "fgapiver" "fgapiver = \"$FGAPISERVER_APIVER\""
   replace_line fgapiserver.conf "fgapisrv_notoken" "fgapisrv_notoken = \"$FGAPISERVER_NOTOKEN\""
   replace_line fgapiserver.conf "fgapisrv_lnkptvflag" "fgapisrv_lnkptvflag = \"$FGAPISERVER_PTVFLAG\""
   replace_line fgapiserver.conf "fgapisrv_ptvendpoint" "fgapisrv_ptvendpoint = \"$FGAPISERVER_PTVENDPOINT\""
   replace_line fgapiserver.conf "fgapisrv_ptvmapfile" "fgapisrv_ptvmapfile = \"$FGAPISERVER_PTVMAPFILE\""
   replace_line fgapiserver.conf "fgapisrv_ptvuser" "fgapisrv_ptvuser = \"$FGAPISERVER_PTVUSER\""
   replace_line fgapiserver.conf "fgapisrv_ptvpass" "fgapisrv_ptvpass = \"$FGAPISERVER_PTVPASS\""
   cd - 2>/dev/null >/dev/null
   out "done" 0 1
fi

# Report installation termination
if [ $RES -ne 0 ]; then
  OUTMODE="Unsuccesfully"
else
  OUTMODE="Successfully"
fi
out "$OUTMODE finished FutureGateway fgAPIServer apt-get versioned setup script"
exit $RES

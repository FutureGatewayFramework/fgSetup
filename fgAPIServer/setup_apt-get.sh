#!/bin/bash
#
# FutureGateway fgAPIServer brew version setup script
#
# Author: Riccardo Bruno <riccardo.bruno@ct.infn.it>
#

source .fgprofile/commons
source .fgprofile/apt_commons
source .fgprofile/config

APACHE_CONFDIR_AVAILABLE=/etc/apache2/conf-available
APACHE_CONFDIR_ENABLED=/etc/apache2/conf-enabled
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
CMD_OUT=$(mktemp -t stdout.XXXXXX)
CMD_ERR=$(mktemp -t stderr.XXXXXX)
TEMP_FILES+=( $CMD_OUT )
TEMP_FILES+=( $CMD_ERR )

out "Starting FutureGateway fgAPIServer apt-get versioned setup script"

out "Verifying package manager and fgAPIServer user ..."

# Check for brew and install it eventually
#@check_and_setup_brew

# Check for FutureGateway fgAPIServer unix user
check_and_create_user $FGAPISERVER_APPHOSTUNAME

# Mandatory packages installation
out "Installing packages ..."

# Mandatory packages installation
APTPACKAGES=(
  curl
  git
  wget
  coreutils
  jq
  mysql-client
  python
  python-pip
  python-dev
  libmysqlclient-dev
  apache2
  apache2-utils
  libexpat1
  ssl-cert
  libapache2-mod-wsgi
)
install_apt ${APTPACKAGES[@]} >$CMD_OUT 2>$CMD_ERR
RES=$?
if [ $RES -ne 0 ]; then
  out "failed" 0 1
  out "Could not install required packages"
  out "Command: install_apt ${APTPACKAGES[@]} >$CMD_OUT 2>$CMD_ERR"
  out "Command output:"
  cat $CMD_OUT
  out "Command error:"
  cat $CMD_ERR
  exit 1
fi
out "done" 0 1

# Check mysql client version
out "Looking up mysql client ... " 1
MYSQLVER=$(mysql -V | awk '{ print $5 }' | awk -F "." '{ printf ("%s.%s",$1,$2) }')
if [ "$MYSQLVER" = "" ]; then
    out "failed" 0 1
    out "Did not find mysql client"
    exit 1
fi
out "done ($MYSQLVER)" 0 1
        
#Check connectivity with fgdb retrieving FGDB version
out "Checking mysql connectivity with FutureGateway DB ... " 1
ASDBVER=$(asdb "select version from db_patches order by id desc limit 1;")
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
out "done" 0 1

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
      rm -rf .venv &&
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
       sudo su - -c "chmod o+w $APACHE_CONFDIR_AVAILABLE && chmod o+w $APACHE_CONFDIR_ENABLED"
       sudo cat >$APACHE_CONFDIR_AVAILABLE/fgapiserver.conf <<EOF
<IfModule wsgi_module>
    <VirtualHost *:80>
        ServerName fgapiserver
        WSGIPassAuthorization On
        WSGIDaemonProcess fgapiserver user=$FGAPISERVER_APPHOSTUNAME processes=2 threads=5 home=$HOME/$FGAPISERVER_GITREPO python-path=$HOME/fgAPIServer python-home=$HOME/fgAPIServer/.venv
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
        [ ! -l $APACHE_CONFDIR_ENABLED/fgapiserver.conf ] &&\
          sudo ln -s $APACHE_CONFDIR_AVAILABLE/fgapiserver.conf $APACHE_CONFDIR_ENABLED/fgapiserver.conf
        sudo su - -c "chmod o-w $APACHE_CONFDIR_AVAILABLE && chmod o-w $APACHE_CONFDIR_ENABLED"
        sudo service apache2 restart >/dev/null 2>/dev/null
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
       [ -l $APACHE_CONFDIR_ENABLED/fgapiserver.conf ] && sudo service apache2 restart
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
   get_ts
   cp fgapiserver.conf fgapiserver.conf_$TS
   sed -i "s/^fgapiver.*/fgapiver = $FGAPISERVER_APIVER/" fgapiserver.conf &&\
   sed -i "s/^fgapiserver_name.*/fgapiserver_name = $FGAPISERVER_NAME/" fgapiserver.conf &&\
   sed -i "s/^fgapisrv_host.*/fgapisrv_host = $FGAPISERVER_APPHOST/" fgapiserver.conf &&\
   sed -i "s/^fgapisrv_port.*/fgapisrv_port = $FGAPISERVER_PORT/" fgapiserver.conf &&\
   sed -i "s/^fgapisrv_debug.*/fgapisrv_debug = $FGAPISERVER_DEBUG/" fgapiserver.conf &&\
   sed -i "s/^fgapisrv_iosandbox.*/fgapisrv_iosandbox = $FGAPISERVER_IOPATH/" fgapiserver.conf &&\
   sed -i "s/^fgapisrv_geappid.*/fgapisrv_geappid = $UTDB_FGAPPID/" fgapiserver.conf &&\
   sed -i "s/^fgjson_indent.*/fgjson_indent = $FGAPISERVER_JSONINDENT/" fgapiserver.conf &&\
   sed -i "s/^fgapisrv_key.*/fgapisrv_key = $FGAPISERVER_KEY/" fgapiserver.conf &&\
   sed -i "s/^fgapisrv_crt.*/fgapisrv_crt = $FGAPISERVER_CRT/" fgapiserver.conf &&\
   sed -i "s/^fgapisrv_logcfg.*/fgapisrv_logcfg = $FGAPISERVER_LOGCFG/" fgapiserver.conf &&\
   sed -i "s/^fgapisrv_dbver.*/fgapisrv_dbver = $ASDBVER/" fgapiserver.conf &&\
   sed -i "s/^fgapisrv_secret.*/fgapisrv_secret = $FGAPISRV_SECRET/" fgapiserver.conf &&\
   sed -i "s/^fgapisrv_notoken\ .*/fgapisrv_notoken = $FGAPISRV_NOTOKEN/" fgapiserver.conf &&\
   sed -i "s/^fgapisrv_notokenusr.*/fgapisrv_notokenusr = $FGAPISERVER_NOTOKEN/" fgapiserver.conf &&\
   sed -i "s/^fgapisrv_lnkptvflag.*/fgapisrv_lnkptvflag = $FGAPISERVER_PTVFLAG/" fgapiserver.conf &&\
   sed -i "s/^fgapisrv_ptvendpoint.*/fgapisrv_ptvendpoint = $FGAPISERVER_PTVENDPOINT/" fgapiserver.conf &&\
   sed -i "s/^fgapisrv_ptvuser.*/fgapisrv_ptvuser = $FGAPISERVER_PTVUSER/" fgapiserver.conf &&\
   sed -i "s/^fgapisrv_ptvpass.*/fgapisrv_ptvpass = $FGAPISERVER_PTVPASS/" fgapiserver.conf &&\
   sed -i "s/^fgapisrv_ptvdefusr.*/fgapisrv_ptvdefusr = $FGAPISERVER_PTVUSER/" fgapiserver.conf &&\
   sed -i "s/^fgapisrv_ptvdefgrp.*/fgapisrv_ptvdefgrp = $FGAPISRV_PTVDEFGRP/" fgapiserver.conf &&\
   sed -i "s/^fgapisrv_ptvmapfile.*/fgapisrv_ptvmapfile = $FGAPISERVER_PTVMAPFILE/" fgapiserver.conf &&\
   sed -i "s/^fgapisrv_db_host.*/fgapisrv_db_host = $FGDB_HOST/" fgapiserver.conf &&\
   sed -i "s/^fgapisrv_db_port.*/fgapisrv_db_port = $FGDB_PORT/" fgapiserver.conf &&\
   sed -i "s/^fgapisrv_db_user.*/fgapisrv_db_user = $FGDB_USER/" fgapiserver.conf &&\
   sed -i "s/^fgapisrv_db_pass.*/fgapisrv_db_pass = $FGDB_PASSWD/" fgapiserver.conf &&\
   sed -i "s/^fgapisrv_db_name.*/fgapisrv_db_name = $FGDB_NAME/" fgapiserver.conf &&\
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


#!/bin/bash
#
# FutureGateway fgAPIServer brew version setup script
#
# Author: Riccardo Bruno <riccardo.bruno@ct.infn.it>
#

source .fgprofile/commons
source .fgprofile/brew_commons
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

out "Starting FutureGateway fgAPIServer brew versioned setup script"

out "Verifying package manager and fgAPIServer user ..."

# Check for brew and install it eventually
check_and_setup_brew

# Check for FutureGateway fgAPIServer unix user
check_and_create_user $FGAPISERVER_APPHOSTUNAME

# Mandatory packages installation
if [ "$BREW" = "" ]; then
  out "Did not find brew package manager"
  exit 1
fi
out "Brew is on: '"$BREW"'"

out "Installing packages ..."

# Mandatory packages installation
BREWPACKAGES=(
  git
  wget
  coreutils
  jq
  mysql
  python
)
# WSGI requires particular setup
if [ $FGAPISERVER_WSGI -ne 0 ]; then
    out "Installing WSGI pre-requisites"
    # XCode Tools are necessary
    out "XCode command line tools ... "
     touch /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress;
     PROD=$(softwareupdate -l |
          grep "\*.*Command Line" |
          head -n 1 | awk -F"*" '{print $2}' |
          sed -e 's/^ *//' |
          tr -d '\n')
    softwareupdate -i "$PROD" -v;
    out "XCode command line tools installed"
    # brew tap apache
    brew tap homebrew/apache
    # Add mod_wsgi on  brew package list
    BREWPACKAGES+=( "mod_wsgi" )
fi
for pkg in ${BREWPACKAGES[@]}; do    
    install_brew $pkg     
done

# Python dependencies
out "Installing python dependencies ..." 1
RES=0
sudo easy_install pip &&
sudo pip install --upgrade pip &&
sudo pip install flask &&
sudo pip install flask-login &&
sudo pip install mysql-python &&
sudo pip install crypto &&
sudo pip install pyopenssl &&
RES=0
if [ $RES -ne 0 ]; then
    out "failed" 0 1
    out "Unable to install python depenencies"
fi
out "done" 0 1
out "Python dependencies successfully installed"

    
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
   
   # Take care of config values to setup fgapiserver.conf properly
   
   # WSGI or screen configuration
   if [ $FGAPISERVER_WSGI -ne 0 ]; then
       out "Configuring fgAPIServer for wsgi ..."
       
       # Stop and remove stand-alone agent if it exists
       if [ -f /Library/LaunchDaemons/it.infn.ct.fgAPIServer.plist ]; then
           sudo launchctl stop it.infn.ct.fgAPIServer
           sudo launchctl remove it.infn.ct.fgAPIServer
       fi
       # Configureing WSGI with apache
       if [ ! -d /etc/apache2 ]; then
           out "ERROR: Apache2 seems not installed in your system, impossible to configure wsgi"
           exit 1
       fi
       MYSQLPYPATH=$(pip show $(pip list --format=columns | grep MySQL-python | awk '{ print $1 }') | grep Location | awk '{ print $2 }')
       MOD_WSGI=$($BREW ls mod_wsgi | grep "mod_wsgi.so")
       sudo chmod o+w /etc/apache2/other
       sudo cat >/etc/apache2/other/fgapiserver.conf <<EOF
LoadModule wsgi_module $MOD_WSGI
<IfModule wsgi_module>
    <VirtualHost *:80>
        ServerName fgapiserver
        WSGIPassAuthorization On
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
        sudo chmod o-w /etc/apache2/other
        sudo /usr/sbin/apachectl restart
   else
       out "Configuring fgAPIServer for stand-alone execution ..."
       CURRDIR=$(pwd)
       APISERVERDAEMON_LAUNCHDFILE=$(mktemp launchd.XXXXXX)
       TEMP_FILES+=( $APISERVERDAEMON_LAUNCHDFILE )
       sudo chown root:Admin /Library/LaunchDaemons
       sudo chmod g+w /Library/LaunchDaemons
       sudo cat >/Library/LaunchDaemons/it.infn.ct.fgAPIServer.plist <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
	<dict>
		<key>Label</key>
		<string>it.infn.ct.fgAPIServer</string>
		<key>ProgramArguments</key>
		<array>
			<string>$CURRDIR/$FGAPISERVER_GITREPO/fgapiserver.py</string>
		</array>
		<key>Program</key>
		<key>KeepAlive</key>
		<true/>
		<key>UserName</key>
		<string>$FGAPISERVER_APPHOSTUNAME</string>
		<key>WorkingDirectory</key>
		<string>$CURRDIR/$FGAPISERVER_GITREPO</string>
	</dict>
</plist>
EOF
       # Executing fgAPIServer service
       # In case switching from wsgi to stand-alone
       [ -f /etc/apache2/other/fgapiserver.conf ] && sudo /usr/sbin/apachectl restart
       # Setup stand-alone mode
       sudo chown root:wheel /Library/LaunchDaemons
       sudo chmod g-w /Library/LaunchDaemons
       sudo chown root /Library/LaunchDaemons/it.infn.ct.fgAPIServer.plist
       sudo chgrp wheel /Library/LaunchDaemons/it.infn.ct.fgAPIServer.plist
       sudo chmod o-w /Library/LaunchDaemons/it.infn.ct.fgAPIServer.plist
       sudo launchctl load -w /Library/LaunchDaemons/it.infn.ct.fgAPIServer.plist
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
out "$OUTMODE finished FutureGateway fgAPIServer brew versioned setup script"
exit $RES

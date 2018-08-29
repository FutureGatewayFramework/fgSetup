#!/bin/bash
#
# FutureGateway database apt-get version setup script
#
# Author: Riccardo Bruno <riccardo.bruno@ct.infn.it>
#

source .fgprofile/commons
source .fgprofile/config
source .fgprofile/apt_commons

FGLOG=$HOME/fgdb.log

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

out "Starting FutureGateway database apt-get versioned setup script"

out "Verifying package manager and fgdb user ..."

# Check for FutureGateway fgdb unix user
if [ ! -d /home/$FGDB_HOSTUNAME ]; then
  sudo adduser --disabled-password --gecos "" $FGDB_HOSTUNAME
  RES=$?
  if [ $RES -eq 0 ]; then
    out "User $FGDB_HOSTUNAME added successfully"
  else
    out "Unable to add user: $FGDB_HOSTUNAME"
    exit 1
  fi
fi

# Mandatory packages installation
APTPACKAGES=(
  git
  wget
  coreutils
  jq
  mysql-server
)
install_apt ${APTPACKAGES[@]} 
RES=$?

# Continue only if packages have been installed correctly
if [ $RES -eq 0 ]; then
    out "Starting mysql service ... " 1
    # Using restart since mysql could be already running
    sudo service mysql start 2>$STD_ERR >$STD_OUT
    RES=$?
    if [ $RES -ne 0 ]; then
        out "failed" 0 1
        out "Output:"
        out "$(cat $STD_ERR)"
        out "Error:"
        out "$(cat $STD_ERR)"
    else
        out "done" 0 1    
    fi
    
    # Check mysql client
    out "Looking up mysql client ... " 1
    MYSQL=$(which mysql)
    if [ "$MYSQL" = "" ]; then
      out "failed" 0 1
      out "Did not find mysql command"
      exit 1
    fi
    out "done ($MYSQL)" 0 1
        
    #Check connectivity
    out "Checking mysql connectivity ... " 1
    $MYSQL -h $FGDB_HOST -P $FGDB_PORT -u root $([ "$FGDB_ROOTPWD" != "" ] && echo "-p$FGDB_ROOTPWD") -e "select version()" >/dev/null 2>/dev/null
    RES=$?
    if [ $RES -ne 0 ]; then
        out "failed" 0 1
        out "Missing mysql connectivity"
        exit 1
    fi
    out "done" 0 1    
fi

# Getting or updading software from Git (database in fgAPIServer repo)
git_clone_or_update "$GIT_BASE" "$FGAPISERVER_GITREPO" "$FGAPISERVER_GITTAG"
RES=$?
if [ $RES -ne 0 ]; then
   out "ERROR: Unable to clone or update repository: \"$FGAPISERVER_GITREPO\""
   exit 1
fi 

# Environment setup
if [ $RES -eq 0 ]; then

   out "Preparing the environment ..."
   
   # Check for db mandatory functions
   out "Checking for mysql macro functions ... "
   out "  asdbr ... " 1   
   declare -F asdbr &>/dev/null && out "found" 0 1 || (echo "not found" 0 1; RES=1)
   out "  asdb ... " 1
   declare -F asdb &>/dev/null && out "found" 0 1 || (echo "not found" 0 1; RES=1)
   out "  dbcn ... " 1
   declare -F dbcn &>/dev/null && out "found" 0 1 || (echo "not found" 0 1; RES=1)
   if [ $RES -ne 0 ]; then
       out "Macro function test check failed!"
       out "At lease one of the mandatory functions is missing"
       exit 1
   fi
   ASDB_OPTS="-sN"

   out "Checkig APIServer database exists ... " 1
   ASDB_OPTS="-sN"
   ASDBCOUNT=$(asdbr "select count(*) from information_schema.schemata where schema_name = 'fgapiserver';")
   RES=$?
   if [ $RES -ne 0 ]; then
       out "failed" 0 1
       out "Did not check if APIServer database exists"
       exit 1
   else
       out "done" 0 1
       if [ $ASDBCOUNT -ne 0 ]; then
           # Database exists; determine version and patch
           out "APIServerDatabase exists; deterimne its version ... " 1
           ASDBVER=$(asdb "select version from db_patches order by 1 desc limit 1;")
           RES=$?
           if [ $RES -ne 0 ]; then
               out "failed" 0 1
               out "Did not check if APIServerDatabase exists"
               exit 1
           fi
           # Database exists; it's time to update it
           out "done ($ASDBVER)" 0 1
           out "Attempting to patch APIServer database ... " 
           cd $FGDB_GITREPO/db_patches
           # Following replace_line statement are required because db_patching 
           # uses fixed and default values
           replace_line patch_functions.sh "mysql -h localhost -P 3306 -u fgapiserver -pfgapiserver_password fgapiserver < \$SQLFILE" "    mysql -h $FGDB_HOST -P $FGDB_PORT -u $FGDB_USER -p$FGDB_PASSWD $FGDB_NAME < \$SQLFILE"
           replace_line patch_functions.sh "mysql -h localhost -P 3306 -u fgapiserver -pfgapiserver_password fgapiserver -s -N -e \"\$SQLCMD\"" "mysql -h localhost -P 3306 -u fgapiserver -pfgapiserver_password fgapiserver -s -N -e \"\$SQLCMD\""
           chmod +x patch_apply.sh
           ./patch_apply.sh
           RES=$?
           if [ $RES -ne 0 ]; then
               out "failed" 0 1
               out "Error applying database patch"
               exit 1
           fi
           out "Patch successfully applied"
           cd - 2>/dev/null >/dev/null 
       else
           # Database does not exist; create it
           out "APIServer database does not exists; creating  it... " 1
           cd $FGDB_GITREPO
           ASDB_OPTS="< fgapiserver_db.sql"
           asdbr           
           RES=$?
           ASDB_OPTS="-sN"
           if [ $RES -ne 0 ]; then
               out "failed" 0 1
               out "Error creating database"
               exit 1
           fi
           out "done" 0 1
           out "APIServer database successfully created"
           cd - 2>/dev/null >/dev/null           
       fi
   fi
   
   # Now take care of environment settings
   out "Setting up '"$FGDB_HOSTUNAME"' user profile ..."
   
   # Preparing user environment in .fgprofile/fgdb file
   #   BGDB variables
   #   DB macro functions
   FGDBENVFILEPATH=.fgprofile/fgdb
   cat >$FGDBENVFILEPATH <<EOF
#!/bin/bash
#
# fgdb Environment setting configuration file
#
# Very specific FGDB service components environment must be set here
#
# Author: Riccardo Bruno <riccardo.bruno@ct.infn.it>
EOF
   for vgdbvar in ${FGDB_VARS[@]}; do
       echo "$vgdbvar=${!vgdbvar}" >> $FGDBENVFILEPATH
   done
   out "User profile successfully created"
fi

#
# Global FG  profile
# 
out "Installing global FG profile"
FGPROFILE=$(mktemp -t stderr.XXXXXX)
TEMP_FILES+=( $FGPROFILE )
cat >$FGPROFILE <<EOF
  echo "for f in \\\$(find $HOME/.fgprofile -type f); do source \\\$f; done # FGLOADENV" > /etc/profile.d/fg_profile.sh
EOF
chmod +x $FGPROFILE
sudo su - -c "$FGPROFILE"

# Report installation termination
if [ $RES -ne 0 ]; then
  OUTMODE="Unsuccesfully"
else
  OUTMODE="Successfully"
fi
out "$OUTMODE finished FutureGateway database apt-get versioned setup script"
exit $RES


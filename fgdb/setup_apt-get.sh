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

# Report CMD failure
done_or_report_fail() {
  if [ $RES -ne 0 ]; then
    out "failed" 0 1
    out "ERROR: \"$1\"" 
    out "Command: \"$CMD\""
    out "Output:"
    out "$(cat $CMD_OUT)"
    out "Error:"
    out "$(cat $CMD_ERR)"
    exit 1
 else
    out "done$2" 0 1  
 fi
}

# DB settings configuration
configure_db_settings() {
    RES=1

    get_ts
    cp fgapiserver_db.sql fgapiserver_db.sql_$TS

    sed -i "s/drop\ database\ if\ exists\ fgapiserver;/drop\ database\ if\ exists\ $FGDB_NAME;/"  fgapiserver_db.sql &&\
    sed -i "s/create\ database\ fgapiserver;/create\ database\ $FGDB_NAME;/" fgapiserver_db.sql &&\
# FG user@%
    sed -i "s/create\ user\ 'fgapiserver'\@'%'/create\ user\ '$FGDB_USER'\@'%'/" fgapiserver_db.sql &&\
    sed -i "s/alter\ user\ 'fgapiserver'\@'%'\ identified\ by\ \"fgapiserver_password\";/alter\ user\ 'fgapiserver'\@'%'\ identified\ by\ \"$FGDB_PASSWD\";/" fgapiserver_db.sql &&\
    sed -i "s/on\ fgapiserver.\*/on\ $FGDB_NAME.\*/" fgapiserver_db.sql &&\
    sed -i "s/to\ 'fgapiserver'\@'%'/to\ '$FGDB_USER'\@'%'/" fgapiserver_db.sql &&\
# FG user@localhost
    sed -i "s/create\ user\ 'fgapiserver'\@'localhost'/create\ user\ '$FGDB_USER'\@'localhost'/" fgapiserver_db.sql &&\
    sed -i "s/alter\ user\ 'fgapiserver'\@'localhost'\ identified\ by\ \"fgapiserver_password\";/alter\ user\ 'fgapiserver'\@'localhost'\ identified\ by\ \"$FGDB_PASSWD\";/" fgapiserver_db.sql &&\
    sed -i "s/on\ fgapiserver.\*/on\ $FGDB_NAME.\*/" fgapiserver_db.sql &&\
    sed -i "s/to\ 'fgapiserver'\@'localhost'/to\ '$FGDB_USER'\@'localhost'/" fgapiserver_db.sql &&\
    RES=0

    return $RES
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

out "Starting FutureGateway database apt-get versioned setup script"

out "Verifying package manager and fgdb user ..."

# Check for FutureGateway fgdb unix user
check_and_create_user $FGDB_HOSTUNAME

# Mandatory packages installation
APTPACKAGES=(
  curl
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
    CMD="sudo service mysql start 2>$CMD_ERR >$CMD_OUT"
    eval $CMD >$CMD_OUT 2>$CMD_ERR
    RES=$?
    done_or_report_fail "Unable to start mysql service"
    
    # Check mysql client
    out "Looking up mysql client ... " 1
    CMD="MYSQL=\$(which mysql)"
    eval $CMD >$CMD_OUT 2>$CMD_ERR 
    done_or_report_fail "Did not find mysql command"
    out "done ($MYSQL)" 0 1
        
    #Check connectivity
    out "Checking mysql connectivity ... " 1
    CMD="$MYSQL -h $FGDB_HOST -P $FGDB_PORT -u root $([ \"$FGDB_ROOTPWD\" != \"\" ] && echo \"-p$FGDB_ROOTPWD\") -e \"select version()\" >$CMD_OUT 2>$CMD_ERR"
    eval $CMD >$CMD_OUT 2>$CMD_ERR 
    done_or_report_fail "Missing mysql connectivity"
    out "done" 0 1    
fi

# Getting or updading software from Git (database in fgAPIServer repo)
CMD="git_clone_or_update \"$GIT_BASE\" \"$FGAPISERVER_GITREPO\" \"$FGAPISERVER_GITTAG\""
eval $CMD >$CMD_OUT 2>$CMD_ERR
RES=$?
done_or_report_fail "Unable to clone or update repository: \"$FGAPISERVER_GITREPO\""

# Environment setup

out "Preparing the environment ..."
   
# Check for db mandatory functions
out "Checking for mysql macro functions ... "
out "  asdbr ... " 1   
declare -F asdbr &>/dev/null && out "found" 0 1 || (echo "asdbr not found" 0 1; RES=1)
out "  asdb ... " 1
declare -F asdb &>/dev/null && out "found" 0 1 || (echo "asdb not found" 0 1; RES=1)
out "  dbcn ... " 1
declare -F dbcn &>/dev/null && out "found" 0 1 || (echo "dbcn not found" 0 1; RES=1)
done_or_report_fail "Macro function test check failed; at lease one of the mandatory functions is missing"

out "Checkig APIServer database exists ... " 1
ASDB_OPTS="-sN"
CMD="ASDBCOUNT=\$(asdbr \"select count(*) from information_schema.schemata where schema_name = 'fgapiserver';\")"
eval $CMD >$CMD_OUT 2>$CMD_ERR
RES=$?
done_or_report_fail "Did not check if APIServer database exists"
    
out "done" 0 1
if [ $ASDBCOUNT -ne 0 ]; then
  # Database exists; determine version and patch
  out "APIServerDatabase exists; deterimne its version ... " 1
  CMD="ASDBVER=\$(asdb \"select version from db_patches order by 1 desc limit 1;\")"
  eval $CMD >$CMD_OUT 2>$CMD_ERR 
  RES=$?
  done_or_report_fail "Unable to determine FG database version" " ($ASDBVER)"
  
  # Database exists; it's time to update it
  out "Attempting to patch APIServer database ... " 
  cd $FGDB_GITREPO/db_patches
  # Following are required because db_patching 
  # uses fixed and default values in patch_functions.sh
  sed -i "s/export ASDB_USER=fgapiserver/export ASDB_USER=$FGDB_USER/" patch_functions.sh 
  sed -i "s/export ASDB_PASS=fgapiserver_password/export ASDB_PASS=$FGDB_PASSWD/" patch_functions.sh
  sed -i "s/export ASDB_HOST=localhost/export ASDB_HOST=$FGDB_HOST/" patch_functions.sh
  sed -i "s/export ASDB_PORT=3306/export ASDB_PORT=$FGDB_PORT/" patch_functions.sh
  sed -i "s/export ASDB_NAME=fgapiserver/export ASDB_NAME=$FGDB_NAME/" patch_functions.sh
  chmod +x patch_apply.sh
  CMD="./patch_apply.sh"
  eval $CMD >$CMD_OUT 2>$CMD_ERR 
  RES=$?
  done_or_report_fail "Error applying database patches"
  out "Patch successfully applied"
  cd - 2>/dev/null >/dev/null 
else
  # Database does not exist; create it
  out "APIServer database does not exists; creating  it... " 1
  cd $FGDB_GITREPO
  configure_db_settings
  ASDB_OPTS="< fgapiserver_db.sql"
  CMD="asdbr > $CMD_OUT 2>$CMD_ERR"
  eval $CMD >$CMD_OUT 2>$CMD_ERR          
  RES=$?
  done_or_report_fail "Error creating FG database"  
  ASDB_OPTS="-sN"
  out "done" 0 1
  out "APIServer database successfully created"
  cd - 2>/dev/null >/dev/null           
fi

# Exit upon failure
[ $RES -ne 0 ] && exit 1   

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


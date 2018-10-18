#!/bin/bash
#
# FutureGateway database brew version setup script
#
# Author: Riccardo Bruno <riccardo.bruno@ct.infn.it>
#

source .fgprofile/commons
source .fgprofile/brew_commons
source .fgprofile/config

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
CMD_OUT=$(mktemp -t stdout.XXXXXX)
CMD_ERR=$(mktemp -t stderr.XXXXXX)
TEMP_FILES+=( $CMD_OUT )
TEMP_FILES+=( $CMD_ERR )

out "Starting FutureGateway database brew versioned setup script"

out "Verifying package manager and fgAPIServer user ..."

# Check for brew and install it eventually
check_and_setup_brew  

# Check for FutureGateway fgAPIServer unix user
check_and_create_user $FGDB_HOSTUNAME

# Mandatory packages installation
BREW=$(which brew)
if [ "$BREW" = "" ]; then
  out "Did not find brew package manager"
  exit 1
fi
out "Brew is on: '"$BREW"'"
out "Installing packages ..."

BREWPACKAGES=(
  git
  wget
  coreutils
  jq
  mysql
)
for pkg in ${BREWPACKAGES[@]}; do    
    install_brew $pkg     
done

# Continue only if packages have been installed correctly
if [ $RES -eq 0 ]; then
    out "Starting mysql service ... " 1
    # Using restart since mysql could be already running
    CMD="sudo \$BREW services restart mysql" 
    exec_cmd "Unable to start mysql service"

    # Check mysql client
    out "Looking up mysql client ... " 1
    CMD="MYSQL=\$(which mysql)"
    exec_cmd "Did not find mysql command" "(\$MYSQL)"

    # Check mysql client
    out "Looking up mysql version ... " 1
    CMD="MYSQLVER=\$(\$MYSQL -V | awk '{ print \$5 }' | awk -F \".\" '{ v=\$1*10+\$2; printf (\"%s\",v) }')"
    exec_cmd "Did not retrieve mysql version" "(\$MYSQLVER)"

    #Check connectivity
    out "Checking mysql connectivity ... " 1
    CMD="$MYSQL -h $FGDB_HOST -P $FGDB_PORT -u root $([ \"$FGDB_ROOTPWD\" != \"\" ] && echo \"-p$FGDB_ROOTPWD\") -e \"select version()\" >$CMD_OUT 2>$CMD_ERR"
    exec_cmd "Missing mysql connectivity"
fi

# Getting or updading software from Git (database in fgAPIServer repo)
CMD="git_clone_or_update \"\$GIT_BASE\" \"\$FGAPISERVER_GITREPO\" \"\$FGAPISERVER_GITTAG\""
exec_cmd "Unable to clone or update repository: \"$FGAPISERVER_GITREPO\""

out "Preparing the environment ..."

# Check for db mandatory functions
out "Checking for mysql macro functions ... "
out "  asdbr ... " 1
declare -F asdbr &>/dev/null && out "found" 0 1 || (echo "asdbr not found" 0 1; RES=1)
out "  asdb ... " 1
declare -F asdb &>/dev/null && out "found" 0 1 || (echo "asdb not found" 0 1; RES=1)
out "  dbcn ... " 1
declare -F dbcn &>/dev/null && out "found" 0 1 || (echo "dbcn not found" 0 1; RES=1)
CMD="[ $RES -eq 0 ]"
exec_cmd "Macro function test check failed; at lease one of the mandatory functions is missing"

out "Checkig APIServer database exists ... " 1
ASDB_OPTS="-sN"
CMD="ASDBCOUNT=\$(asdbr \"select count(*) from information_schema.schemata where schema_name = 'fgapiserver';\")"
exec_cmd "Did not check if APIServer database exists"

cd $FGDB_GITREPO
out "Configure DB settings ... " 1
CMD="configure_db_settings"
exec_cmd "Unable to confiugre database settings"
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
  CMD="chmod +x patch_apply.sh && ./patch_apply.sh"
  exec_cmd "Error applying database patch"
  out "Patch(es) successfully applied"
else
  # Database does not exist; create it
  out "APIServer database does not exists; creating  it ... " 1
  ASDB_OPTS="< fgapiserver_db.sql"
  CMD="asdbr"
  cmd_exec "Error creating FG database"
  out "Creating APIServer database user ... " 1
  if [ $MYSQLVER -lt 80 ]; then
    out "(dbusr5)" 1 1
    ASDB_OPTS="< fgapiserver_dbusr5.sql"
  else
    out "(dbusr8)" 1 1
    ASDB_OPTS="< fgapiserver_dbusr8.sql"
  fi
  CMD="asdbr"          
  cmd_exec "Error creating database"
  out "done" 0 1
  out "APIServer database successfully created"
fi
cd - 2>/dev/null >/dev/null 
 
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
#for vgdbvar in ${FGDB_VARS[@]}; do
#    echo "$vgdbvar=${!vgdbvar}" >> $FGDBENVFILEPATH
#done
## Now place functions from setup_commons.sh
#declare -f asdb  >> $FGDBENVFILEPATH
#declare -f asdbr >> $FGDBENVFILEPATH
#declare -f dbcn  >> $FGDBENVFILEPATH
#out "done" 0 1
out "User profile successfully created"

# Report installation termination
if [ $RES -ne 0 ]; then
  OUTMODE="Unsuccesfully"
else
  OUTMODE="Successfully"
fi
out "$OUTMODE finished FutureGateway database brew versioned setup script"
exit $RES

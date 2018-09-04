#!/bin/bash
#
# FutureGateway common functions
#
# Author: Riccardo Bruno <riccardo.bruno@ct.infn.it>
#

# Timestamp
get_ts() {
  TS=$(date +%y%m%d%H%M%S)
}

# Output function notify messages
# Arguments: $1 - Message to print
#            $2 - No new line if not zero
#            $3 - No timestamp if not zero
out() {
  # Get timestamp in TS variable  
  get_ts

  # Prepare output flags
  OUTCMD=echo
  MESSAGE="$1"
  NONEWLINE="$2"
  NOTIMESTAMP="$3" 
  if [ "$NONEWLINE" != "" -a $((1*NONEWLINE)) -ne 0 ]; then
    OUTCMD=printf
  fi
  if [ "$3" != "" -a $((1*NOTIMESTAMP)) -ne 0 ]; then
    TS=""
  fi
  OUTMSG=$(echo $TS" "$MESSAGE)
  $OUTCMD "$OUTMSG" >&1
  if [ "$FGLOG" != "" ]; then
    $OUTCMD "$OUTMSG" >> $FGLOG
  fi  
}

# Error function notify about errors
err() {
  get_ts
  echo $TS" "$1 >&2 
  if [ "$FGLOG" != "" ]; then
    echo $TS" "$1 >> $FGLOG
  fi
}

# Show output and error files
outf() {
  OUTF=$1
  ERRF=$2
  if [ "$OUTF" != "" -a -f "$OUTF" ]; then
    while read out_line; do
      out "$out_line"
    done < $OUTF
  fi
  if [ "$ERRF" != "" -a -f "$ERRF" ]; then
    while read err_line; do
      err "$err_line"
    done < $ERRF
  fi
}

# Execute the given command
# $1 Command to execute
# $2 If not null does not print the command (optional)
fg_exec() {
  TMPOUT=$(mktemp /tmp/fg_out_XXXXXXXX)
  TMPERR=$(mktemp /tmp/fg_err_XXXXXXXX)
  if [ "$2" = "" ]; then
    out "Executing: '""$1""'"
  fi  
  eval "$1" >$TMPOUT 2>$TMPERR
  RES=$?
  outf $TMPOUT $TMPERR
  rm -f $TMPOUT
  rm -f $TMPERR
  return $RES
}

# Function that replace the 1st matching occurrence of
# a pattern with a given line into the specified filename
#  $1 # File to change
#  $2 # Matching pattern that identifies the line
#  $3 # New line content
#  $4 # Optionally specify a suffix to keep a safe copy
replace_line() {
  file_name="$1"   # File to change
  pattern="$2"     # Matching pattern that identifies the line
  new_line="$3"    # New line content
  keep_suffix="$4" # Optionally specify a suffix to keep a safe copy
  
  if [ "$file_name" != "" -a -f $file_name -a "$pattern" != "" ]; then
    TMP=$(mktemp /tmp/fg_replace_XXXXXXXX)
    cp $file_name $TMP
    if [ "$keep_suffix" != "" ]; then # keep a copy of replaced file
      cp $file_name $file_name"_"$keep_suffix
    fi
    MATCHING_LINE=$(cat $TMP | grep -n "$pattern" | head -n 1 | awk -F':' '{ print $1 }' | xargs echo)
    if [ "$MATCHING_LINE" != "" ]; then
      cat $TMP | head -n $((MATCHING_LINE-1)) > $file_name
      printf "$new_line\n" >> $file_name
      cat $TMP | tail -n +$((MATCHING_LINE+1)) >> $file_name
    else
      echo "WARNING: Did not find '"$pattern"' in file: '"$file_name"'"
    fi
    rm -f $TMP
  else
    echo "You must provide an existing filename and a valid pattern"
    return 1
  fi
}

#
# Function that checks/reports environment variables
#
check_envs() {
  RES=0
  ENV_VARS="$1"
  SKIP_VARS="$2"
  if [ "$ENV_VARS" = "" ]; then
    err "Sorry no variables found to check"
    RES=1
  fi
  for ENV_VAR in $ENV_VARS; do
    VARTOSKIP=0
    for SKIP_VAR in $SKIP_VARS; do
        if [ "$SKIP_VAR" = "$ENV_VAR" ]; then
            VARTOSKIP=1
        fi
    done
    eval ENV_VAL=\$$ENV_VAR
    out "$ENV_VAR='"$ENV_VAL"'"
    if [ "$ENV_VAL" = "" -a $VARTOSKIP -eq 0 ]; then
        err "Found required variable $ENV_VAR empty!"
        RES=1
    fi
  done
  return $RES
}

#
# Customize a given set of variables in setup_config.sh file
#
setup_config_vars() {
  ENV_VARS=$*
  if [ "$ENV_VARS" = "" ]; then
    err "Sorry no variables found to replace"
  fi
  for ENV_VAR in $ENV_VARS; do
    replace_line setup_config.sh "$ENV_VAR=" "  $ENV_VAR=\$$ENV_VAR"
  done
}

#
# Customize existing setup_config.sh accordingly
#
customize_common() {
  FGCOMMON_ENV="FGHOME\
               FGLOCATION"
  setup_config_vars $FGCOMMON_ENV
}

customize_fgportal() {
  FGPORTAL_ENV="TOMCATUSR\
                TOMCATPAS\
                SKIP_LIFERAY\
                LIFERAY_VER\
                LIFERAY_SDK_ON\
                LIFERAY_SDK_LOCATION\
                MAVEN_ON\
                STARTUP_SYSTEM\
                TIMEZONE\
                SETUPDB\
                MYSQL_HOST\
                MYSQL_PORT\
                MYSQL_USER\
                MYSQL_PASS\
                MYSQL_DBNM\
                MYSQL_ROOT\
                MYSQL_RPAS"
  setup_config_vars $FGPORTAL_ENV
}

#
# Show environment variables
#
# $1 - Variable set name
# $2 - Variable set
# $3 - Non zero or empty to indent values (optional)
# $4 - Specify indentation char (optional)
#
show_vars() {
  if [ "$1" = "" -o "$2" = "" ]; then
    echo "No variables available to be shown"
    return 1
  fi
  echo "-----------------------------------------"
  echo " $1 values"
  echo "-----------------------------------------"
  SV_INDENT=""$3 
  if [ "$SV_INDENT" != "" -a $((1*SV_INDENT)) -gt 0 ]; then 
    MAXLEN=$(for var in $ENV_VARS; do
               echo $var | wc -c
             done | awk 'BEGIN{MAX=0} { if($1>MAX) MAX=$1 } END{ print MAX}')
    SV_INDENT=$((MAXLEN+1))
  fi 
  SV_INDCHR=""$4
  if [ "$SV_INDCHR" = "" ]; then
    SV_INDCHR=" "
  fi
  for var in $2; do
    if [ "$SV_INDENT" != "" ]; then
    VARLEN=$(echo $var | wc -c | xargs echo)
    SPCS=$((SV_INDENT-VARLEN-1))
    else
      SPCS=""
    fi
    SV_INDENTSPCS=""
    if [ $SPCS -gt 0 ]; then
      for i in $(seq 1 $SPCS); do
        SV_INDENTSPCS=$SV_INDENTSPCS$SV_INDCHR
      done 
    fi
    printf "$var$SV_INDENTSPCS: '"
    EVNVALUE=$(eval printf \$$var 2>/dev/null)
    if [ "$EVNVALUE" != "" ]; then
      printf $EVNVALUE
    fi  
    echo "'"
  done
}

#
# Find the supported OSes package manager
#
load_package_manager() {
    BREW=$(which brew 2>/dev/null)
    APTGET=$(which apt-get 2>/dev/null)
    YUM=$(which yum 2>/dev/null)
}

# Determine SSH connection settings related to the given service name
# $1 - The FutureGateway component name
# Returns: Setup the following variables:
#          SSH_HOST - Service host name
#          SSH_USER - Service user name
#          SSH_PORT - Service port number
setsrvsshvars() {
    FGCOMPONENT=$1
    
    case $FGCOMPONENT in
        'fgdb')
            SSH_HOST=$FGDB_HOST       
            SSH_USER=$FGDB_HOSTUNAME
            SSH_PORT=$FGDB_SSHPORT
        ;;
        'fgAPIServer')
            SSH_HOST=$FGAPISERVER_HOST       
            SSH_USER=$FGAPISERVER_APPHOSTUNAME
            SSH_PORT=$FGAPISERVER_SSHPORT
        ;;
        'APIServerDaemon')
            SSH_HOST=$APISERVERDAEMON_HOST       
            SSH_USER=$APISERVERDAEMON_HOSTUNAME
            SSH_PORT=$APISERVERDAEMON_SSHPORT
        ;;
        'Liferay62')
            SSH_HOST=$FGPORTAL_LIFERAY62_HOST       
            SSH_USER=$FGPORTAL_LIFERAY62_HOSTUNAME
            SSH_PORT=$FGPORTAL_LIFERAY62_SSHPORT
        ;;
       'Liferay7')
            SSH_HOST=$FGPORTAL_LIFERAY7_HOST       
            SSH_USER=$FGPORTAL_LIFERAY7_HOSTUNAME
            SSH_PORT=$FGPORTAL_LIFERAY7_SSHPORT
        ;;
        *)
            SSH_HOST=
            SSH_USER=
            SSH_PORT=
            echo "Unknown FutureGateway component '"$FGCOMPONENT"'"
            return 1
    esac
    return 0
}

#
# Function that execute a command on a FutureGateway node via SSH
#
# $1 - FutureGateway component name; possible values are:
#      fgdb, 
#      fgAPIServer, 
#      APIServerDaemon, 
#      Liferay64, 
#      Liferay7
# $2 - The command to execute
# $3 - The SSH std-out (/dev/null default)
# $4 - The SSH std-err (/dev/null default)
# $5 - SSH opts
ssh_command() {
    RES=0
    FGCOMPONENT="$1"
    SSHCOMMAND="$2"
    SSHOUT=/dev/null
    SSHERR=/dev/null
    [ "$3" != "" ] && SSHOUT="$3"
    [ "$4" != "" ] && SSHERR="$4"
    [ "$5" != "" ] && SSHOPTS="$5" ||\
                      SSHOPTS="-n -o \"StrictHostKeyChecking no\" -o \"BatchMode=yes\""    
    if [ "$SSH" = "" ]; then
      SSH=$(which ssh)
      if [ "$SSH" = "" ]; then
        echo "SSH variable not set; unable to execute any ssh command"
        return 1
      fi
    fi
    
    # Get SSH values related to the given service
    setsrvsshvars "$FGCOMPONENT"
    RES=$?
    [ $RES -eq 0 ] || exit 1
    
    # Execute SSH command
    CMD="$SSH ""$SSHOPTS"" -l $SSH_USER $SSH_HOST -p $SSH_PORT \"$SSHCOMMAND\""
    #out "$CMD" 1 1
    eval $CMD 2>$SSHERR >$SSHOUT
    RES=$?
    return $RES
}

# Copy a file with scp on the right node from service name
# $1 - FutureGateway component name; possible values are:
#      fgdb, 
#      fgAPIServer, 
#      APIServerDaemon, 
#      Liferay64, 
#      Liferay7
# $2 - The file to copy
# $3 - If not empty keeps the destination filename
# $4 - The SSH std-out (/dev/null default)
# $5 - The SSH std-err (/dev/null default)
ssh_sendfile() {
    RES=0
    FGCOMPONENT=$1
    SSHFILE=$2
    SSHOUT=/dev/null
    SSHERR=/dev/null
    SSHDSTFILE=""
    [ "$3" != "" ] && SSHDSTFILE=$3
    [ "$4" != "" ] && SSHOUT=$4
    [ "$5" != "" ] && SSHERR=$5
    if [ "$SCP" = "" ]; then
      SCP=$(which scp)
      if [ "$SCP" = "" ]; then
        echo "SCP variable not set; unable to copy any file"
        return 1
      fi
    fi
    
    # Get SSH values related to the given service
    setsrvsshvars "$FGCOMPONENT"
    RES=$?
    [ $RES -eq 0 ] || exit 1
    
    # Execute SCP command
    #echo "$SCP -P $SSH_PORT $SSHFILE $SSH_USER@$SSH_HOST:$SSHDSTFILE 2>$SSHERR >$SSHOUT"
    CMD="$SCP -P $SSH_PORT $SSHFILE $SSH_USER@$SSH_HOST:$SSHDSTFILE 2>$SSHERR >$SSHOUT"
    $SCP -P $SSH_PORT $SSHFILE $SSH_USER@$SSH_HOST:$SSHDSTFILE 2>$SSHERR >$SSHOUT 
    RES=$?

    return $RES
}

# Get a file with scp from the right service using service name
# $1 - FutureGateway component name; possible values are:
#      fgdb, 
#      fgAPIServer, 
#      APIServerDaemon, 
#      Liferay64, 
#      Liferay7
# $2 - The file to get
# $3 - If not empty keeps the destination filename
# $4 - The SSH std-out (/dev/null default)
# $5 - The SSH std-err (/dev/null default)
ssh_getfile() {
    RES=0
    FGCOMPONENT=$1
    SSHFILE=$2
    SSHOUT=/dev/null
    SSHERR=/dev/null
    SSHDSTFILE=""
    [ "$3" != "" ] && SSHDSTFILE=$3
    [ "$4" != "" ] && SSHOUT=$4
    [ "$5" != "" ] && SSHERR=$5
    if [ "$SCP" = "" ]; then
      SCP=$(which scp)
      if [ "$SCP" = "" ]; then
        echo "SCP variable not set; unable to copy any file"
        return 1
      fi
    fi
    
    # Get SSH values related to the given service
    setsrvsshvars "$FGCOMPONENT"
    RES=$?
    [ $RES -eq 0 ] || exit 1
    
    # Execute SCP command
    $SCP -P $SSH_PORT $SSH_USER@$SSH_HOST:$SSHDSTFILE $SSHFILE  2>$SSHERR >$SSHOUT 
	RES=$?

    return $RES
}


# asdb - Tool to manage FutureGateway database
asdb() {
  cmd=$@
  if [ "$cmd" != "" ]; then
    cmd="-e \"""$cmd""\""
  fi
  dbcn "$FGDB_HOST" "$FGDB_PORT" "$FGDB_USER" "$FGDB_PASSWD" "$ASDB_OPTS" "$FGDB_NAME" "$cmd"
  RES=$?
  return $RES
}

# asdbr - DB root verson of asdb
asdbr() {
  cmd=$@
  if [ "$cmd" != "" ]; then
    cmd="-e \"""$cmd""\""
  fi
  dbcn "$FGDB_HOST" "$FGDB_PORT" root "$FGDB_ROOTPWD" "$ASDB_OPTS" "" "$cmd"
  RES=$?
  return $RES
}

# utdb - Tool to manage Grid and Cloud Engine DB: UsersTrackingDatabase
utdb() {
  cmd=$@
  if [ "$cmd" != "" ]; then
    cmd="-e \"""$cmd""\""
  fi
  dbcn "$UTDB_HOST" "$UTDB_PORT" "$UTDB_USER" "$UTDB_PASSWD" "$UTDB_OPTS" "$UTDB_NAME" "$cmd"
  RES=$?
  return $RES
}

# utdbr - DB root verson of utdb
utdbr() {
  cmd=$@
  if [ "$cmd" != "" ]; then
    cmd="-e \"""$cmd""\""
  fi
  dbcn "$FGDB_HOST" "$FGDB_PORT" root "$UTDB_ROOTPWD" "$UTDB_OPTS" "" "$cmd"
  RES=$?
  return $RES
}

# dbcn - Tool to connect a given database
# $1 - DB host
# $2 - DB port
# $3 - DB user
# $4 - DB password
# $5 - mysql command line options
# $6 - DB name
# $7 - DB command to execute
# $8 - Output (default stdout)
# $9 - Error (default stderr)
dbcn() {
    DB_HOST=$1 
    DB_PORT=$2
    DB_USER=$3
    DB_PASSWD=$([ "$4" != "" ] && echo -p$4)
    DB_OPTS=$5
    DB_NAME=$6
    DB_CMD=$7
    DB_OUT=$8
    DB_ERR=$9
    if [ "$MYSQL" = "" ]; then
       MYSQL=$(which mysql)
       if [ "$MYSQL" = "" ]; then
           echo "MYSQL variable not set; unable to execute any mysql command"
           return 1
       fi
    fi
    DB_OUT_OPT=""
    if [ "$DB_OUT" != "" ]; then
      DB_OUT_OPT="> $DB_OUT"
    fi
    DB_ERR_OPT=""
    if [ "$DB_ERR" != "" ]; then
      DB_ERR_OPT="2> $DB_ERR"
    fi
    eval $MYSQL -h $DB_HOST -P $DB_PORT -u $DB_USER $DB_PASSWD $DB_OPTS $DB_NAME "$DB_CMD" $DB_OUT_OPT $DB_ERR_OPT 
    RES=$?
    return $RES
}

# Clone or update a given Git repository; call from the directory that contains the repo
# dir in case of update
# $1 Git repository base 'http://github.com/<repobase_name>'
# $2 Repository name
# $3 Repository tag/version
git_clone_or_update() {

    GCO_GITBASE="$1"
    GCO_GITREPO="$2"
    GCO_GITTAG="$3"
     
    MISSING_PARAMS=""
    [ "$GCO_GITBASE" = "" ] && MISSING_PARAMS=$MISSING_PARAMS"Git-base "
    [ "$GCO_GITREPO" = "" ] && MISSING_PARAMS=$MISSING_PARAMS"Git-repository "
    [ "$GCO_GITTAG" = "" ] && MISSING_PARAMS=$MISSING_PARAMS"Git-tag "
    if [ "$MISSING_PARAMS" != "" ]; then
        out "ERROR: Following mandatory parameters are not present: \"$MISSING_PARAMS\""
        return 1
    fi
    
    GIT=$(which git)
    if [ "$GIT" = "" ]; then
        out "ERROR: Mandatory git command line is not present"
        return 1
    fi
    
    if [ -d $GCO_GITREPO ]; then
        out "Repository exists!"
        cd $GCO_GITREPO
        git pull origin $GCO_GITTAG
        RES=$?
        if [ $RES -ne 0 ]; then
            out "Unable to pull $GCO_GITREPO sources"
            return 1
        else
            out "Reposiroty successfully pulled"
        fi
        cd - 2>/dev/null >/dev/null
    else
        out "Cloning from: $GCO_GITBASE/$GCO_GITREPO tag/branch: $GCO_GITTAG"
        $GIT clone -b $GCO_GITTAG $GCO_GITBASE/$GCO_GITREPO.git
        RES=$?
        if [ $RES -ne 0 ]; then
            out "Unable to clone '"$GCO_GITREPO"'"
            return 1
        fi
        #cd $(pwd)/$GCO_GITREPO
        #cd - 2>/dev/null >/dev/null
    fi
    
    return 0
}


# Execute the command specified in $CMD variable and report execution status
# In case of error, output and error streams are reported together with a given
# error message
#
# Used values as input/output:
#   $CMD - The command to execute
#   $RES - Return code of the executed command 
#   $1   - Error message to report in case of failure
#   $CMD_OUT, $CMD_ER created during installation startup, they must exist
exec_cmd() {
  eval $CMD >$CMD_OUT 2>$CMD_ERR
  RES=$?
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

# Configure database settings in fgAPIServer directory
# The operation involves files:
#    fgapiserver_dbusr5.sql
#    fgapiserver_dbusr8.sql
#    db_patches/patch_functions.sh
configure_db_settings() {
    RES=1

    get_ts &&\
    cp fgapiserver_db.sql fgapiserver_db.sql_$TS &&\

    # Change db settings for both mysql5, mysql8

    # mysql5
    sed -i "s/fgapiserver.*/$FGDB_NAME/g" fgapiserver_dbusr5.sql &&\
    sed -i "s/fgapiserver\'@/$FGDB_USER\'@/g" fgapiserver_dbusr5.sql &&\
    sed -i "s/identified\ by\ \"fgapiserver_password\"/identified\ by\ \"$FGDB_PASSWD\"/g" fgapiserver_dbusr5.sql &&\

    # mysql8
    sed -i "s/fgapiserver.*/$FGDB_NAME/g" fgapiserver_dbusr5.sql &&\
    sed -i "s/fgapiserver\'@/$FGDB_USER\'@/g" fgapiserver_dbusr5.sql &&\
    sed -i "s/identified\ by\ \"fgapiserver_password\"/identified\ by\ \"$FGDB_PASSWD\"/g" fgapiserver_dbusr5.sql &&\

    # db_patches/patch_functions.sh
    sed -i "s/export ASDB_USER=fgapiserver/export ASDB_USER=$FGDB_USER/" db_patches/patch_functions.sh &&\
    sed -i "s/export ASDB_PASS=fgapiserver_password/export ASDB_PASS=$FGDB_PASSWD/" db_patches/patch_functions.sh &&\
    sed -i "s/export ASDB_HOST=localhost/export ASDB_HOST=$FGDB_HOST/" db_patches/patch_functions.sh &&\
    sed -i "s/export ASDB_PORT=3306/export ASDB_PORT=$FGDB_PORT/" db_patches/patch_functions.sh &&\
    sed -i "s/export ASDB_NAME=fgapiserver/export ASDB_NAME=$FGDB_NAME/" db_patches/patch_functions.sh &&\

    return $RES
}


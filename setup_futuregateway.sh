#!/bin/bash
#
# FutureGateway setup script
#
# This setup script manages the whole FutureGateway installation accordingly to
# the configuration settings placed in file 'setup_config.sh'
# The installatio procedure foresees that any FutureGateway component may run
# on a separate machine/container. Before to start its execution please check
# the following mandatory requisites:
#
# All service nodes have a unix user allowed to execute passwordless sudo commands
# All service nodes can be reachable via SSH from the host executing the setup with
# key exchange without prompting passwords
# All service nodes must open SSH port for incoming connections; different nodes may
# have different SSH ports
# The database node must open the MYSQL port number for incoming connections; the port
# number can be different from default value as well as MYSQL root password
#
# During the installation several of the conditions above will be checked
#
# Author: Riccardo Bruno <riccardo.bruno@ct.infn.it>
#

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

# Pre-installation
setup_PreRequisites() {

    # Check for ssh client
    SSH=$(which ssh)
    if [ "$SSH" = "" ]; then
      echo "This installation script requires SSH client to run"
      echo "Please contact your system administrator to install it"
      return 1
    fi
    
    # Check for scp ssh copy client
    SCP=$(which scp)
    if [ "$SCP" = "" ]; then
      echo "This installation script requires scp SSH file copy tool to run"
      echo "Please contact your system administrator to install it"
      return 1
    fi
    
    # Check for mysql client
    MYSQL=$(which mysql)
    if [ "$MYSQL" = "" ]; then
      echo "This installation script requires mysql client to run"
      echo "Please contact your system administrator to install it"
      return 1
    fi
    
    # Check if setup_commons.sh file exists
    if [ ! -f setup_commons.sh ]; then
	    echo "Unable to run setup script without file 'setup_commons.sh'"
	    echo "This file contains common functions used by the installation scripts"
	    RES=1
    fi
    # Check if setup_config.sh file exists
    if [ ! -f setup_config.sh ]; then
	    echo "Unable to run setup script without file 'setup_config.sh'"
	    echo "This file contains all FutureGateway configuration settings"
	    RES=1
    fi
    
    # Source commons and configuration files
    source setup_commons.sh
    source setup_config.sh
    
    out "--------------------------"
    out "FutureGateway setup script"
    out "--------------------------"
    out ""
    
  	# Local temporary files for SSH output and error files
	SSH_OUT=$(mktemp -t ssh_command.XXXXXX)
	SSH_ERR=$(mktemp -t ssh_command.XXXXXX)
	TEMP_FILES+=( $SSH_OUT )
	TEMP_FILES+=( $SSH_ERR )
    
    return $RES
}

# Check configuration variables
setup_CheckVariables() {
    RES=0
    
    out "Checking variables for components to install ..."
    
    # Check configuration variables accordingly to the enabled components
    # The following check verifies only that variables are not empty
    # Database component is not optional
    check_envs "$FGDB_VARS" "FGDB_ROOTPWD" &&
    [ $FGAPISERVER_SETUP -ne 0 ]        &&\
        out "Checking fgAPIServer"      && check_envs "$FGAPISERVER_VARS"        && \
    [ $APISERVERDAEMON_SETUP -ne 0 ]    &&\
        out "Checking APIServerDaemon"  && check_envs "$APISERVERDAEMON_ENVS"    && \
    [ $FGPORTAL_LIFERAY62_SETUP -ne 0 ] &&\
        out "Checking Liferay62"        && check_envs "$FGPORTAL_LIFERAY62_ENVS" && \
    [ $FGPORTAL_LIFERAY7_SETUP -ne 0 ]  &&\
        out "Checking Liferay7"         && check_envs "$FGPORTAL_LIFERAY7_ENVS"
    RES=$?
}

# Check a single host
setup_CheckHost() {
    # Check fgAPIServer if its setup is enabled
	RES=0
	SETUP_FLAG=$1
	SETUP_SERVICE=$2
		
	# Entering check only if the component is requested		
	MKPROFILESCRIPT=$(mktemp service_profile.XXXXXX)
	TEMP_FILES+=( $MKPROFILESCRIPT )
    cat >$MKPROFILESCRIPT <<'EOF'
#!/bin/bash
# FutureGateway making profile script
# Author: Riccardo Bruno <riccardo.bruno@ct.infn.it>
if [ ! -d .fgprofile ]; then
    mkdir -p .fgprofile
fi
LOADENV=$(echo "for f in $(find $HOME/.fgprofile -type f); do source $f; done # FGLOADENV")
if [ ! -f $HOME/.bash_profile -o $(cat $HOME/.bash_profile | grep FGLOADENV | wc -l) -eq 0 ]; then
    echo $LOADENV >> .bash_profile
fi
EOF
	if [ "$SETUP_FLAG" -ne 0 ]; then
             RES=0

             [ $RES -eq 0 ] &&
	     out "Checking '"$SETUP_SERVICE"' host connection ... " 1 &&
	     ssh_command $SETUP_SERVICE "whoami" $SSH_OUT $SSH_ERR && 
	     out "passed" 0 1 && RES=0 || RES=1

             [ $RES -eq 0 ] &&
	     out "Checking '"$SETUP_SERVICE"' passwordless sudo ... " 1 &&   
	     ssh_command $SETUP_SERVICE "sudo -n true" $SSH_OUT $SSH_ERR && 
	     out "passed" 0 1 && RES=0 || RES=1
	     
             [ $RES -eq 0 ] &&
             out "Determining '"$SETUP_SERVICE"' package manager ... " 1 &&	         
	     ssh_command $SETUP_SERVICE "which apt-get || which yum || ([ \"\$(uname -s)\" = \"Darwin\" ] && echo \"brew\") || echo \"unsupported\"" $SSH_OUT $SSH_ERR "-n -o \"StrictHostKeyChecking no\" -o \"BatchMode=yes\"" &&
	     PKGMGR=$(cat $SSH_OUT | xargs basename) &&
	     out "passed ("$PKGMGR")" 0 1 && RES=0 || RES=1

             [ $RES -eq 0 ] &&
             echo $SETUP_SERVICE" "$(cat $SSH_OUT) >> $SERVICE_PKGMGR &&
             out "Setting up FutureGateway environment settings for service '"$SETUP_SERVICE"' ..." 1 &&
             ssh_sendfile $SETUP_SERVICE "$MKPROFILESCRIPT" "$MKPROFILESCRIPT" $SSH_OUT $SSH_ERR &&
             ssh_command $SETUP_SERVICE "chmod +x $MKPROFILESCRIPT" $SSH_OUT $SSH_ERR &&
             ssh_command $SETUP_SERVICE "./$MKPROFILESCRIPT" $SSH_OUT $SSH_ERR &&
             ssh_command $SETUP_SERVICE "rm -f $MKPROFILESCRIPT" $SSH_OUT $SSH_ERR &&
             out "done" 0 1 && RES=0 || RES=1

             [ $RES -eq 0 ] &&
             out "Sending setup_commons files to the host ... " 1 &&
             ssh_sendfile $SETUP_SERVICE "setup_commons.sh" ".fgprofile/commons" $SSH_OUT $SSH_ERR &&
             out "done" 0 1 &&  RES=0 || RES=1
             
             if [ $RES -eq 0 ]; then 
               out "Sending package manager specific files to the host ... " 1 
               
               [ "$PKGMGR" = "brew" ] &&  out "(brew) " 1 1 &&
               ssh_sendfile $SETUP_SERVICE "setup_brew_commons.sh" ".fgprofile/brew_commons" $SSH_OUT $SSH_ERR &&
               RES_BREW=0 || RES_BREW=1
               
               [ "$PKGMGR" = "apt-get" ] && out "(apt-get) " 1 1 &&
               ssh_sendfile $SETUP_SERVICE "setup_apt_commons.sh" ".fgprofile/apt_commons" $SSH_OUT $SSH_ERR &&
               RES_APTGET=0 || RES_APTGET=1

               [ "$PKGMGR" = "yum" ] && out "(yum) " 1 1 &&
               ssh_sendfile $SETUP_SERVICE "setup_yum_commons.sh" ".fgprofile/yum_commons" $SSH_OUT $SSH_ERR &&
               RES_YUM=0 || RES_YUM=1

               [ $RES_BREW -eq 0 -o $RES_APTGET -eq 0 -o $RES_YUM -eq 0 ] && RES=0 || RES=1
             fi
             [ $RES -eq 0 ] && out "passed" 0 1 

             [ $RES -eq 0 ] &&
             out "Sending setup_config.sh file to the host ... " 1 &&    
             ssh_sendfile $SETUP_SERVICE "setup_config.sh" ".fgprofile/config" $SSH_OUT $SSH_ERR &&
             RES=0 || RES=1 
             [ $RES -eq 0 ] && out "done" 0 1
        fi

	if [ $RES -ne 0 ]; then
	    out "failed" 0 1 
	    err "Failing $SETUP_SERVICE host checking; command, ssh output and error files below"
            err "CMD: "
            err "$CMD"
	    err "SSH Output:"
	    err "$(cat $SSH_OUT)"
	    err "SSH Error:"
	    err "$(cat $SSH_ERR)"
	fi
	
	return $RES
}

# Check setup involved hosts and DB connections
setup_CheckHosts() {
    RES=1
    
    out "Checking nodes connectivity and privileges:"    
	
    #Global scope temporary file keeping service package manager information
	SERVICE_PKGMGR=$(mktemp service_pkgmgr.XXXXXX)
    TEMP_FILES+=( $SERVICE_PKGMGR )
	
	setup_CheckHost 1 fgdb &&
	setup_CheckHost $FGAPISERVER_SETUP fgAPIServer &&
	setup_CheckHost $APISERVERDAEMON_SETUP APIServerDaemon && 
	setup_CheckHost $FGPORTAL_LIFERAY62_SETUP Liferay62 && 
	setup_CheckHost $FGPORTAL_LIFERAY7_SETUP Liferay7 &&
	RES=0 
	
	return $RES
}

# Check setup files of the given component and package manager
# This function also copies checked setup file into destination location
# $1 - Component setup flag
# $2 - Component name
# $3 - A file containing selected setup scritps
setup_CheckScript() {
    RES=0
	SETUP_FLAG=$1
	SETUP_SERVICE=$2
	SETUP_SCRIPTS=$3
	
	# Entering setup only if the component is requested		
	if [ "$SETUP_FLAG" -ne 0 ]; then
	    PKGMGRPATH=$(cat $SERVICE_PKGMGR | grep $SETUP_SERVICE | awk '{ print $2 }' | xargs echo)
        PKGMGRNAME=$(basename $PKGMGRPATH)
        out "Checking setup script for service: '"$SETUP_SERVICE"' with package manager: '"$PKGMGRNAME"'"
        SRCSCRIPTPATHNAME=$SETUP_SERVICE"/setup_"$PKGMGRNAME.sh
        DSTSCRIPTPATHNAME=$SETUP_SERVICE"_setup_"$PKGMGRNAME.sh
        if [ ! -f "$SRCSCRIPTPATHNAME" ]; then
            err "Did not found setup script: '"$SRCSCRIPTPATHNAME"'"
            RES=1
        else
            ssh_sendfile $SETUP_SERVICE $SRCSCRIPTPATHNAME $DSTSCRIPTPATHNAME
            RES=$?
            if [ $RES -ne 0 ]; then
                err "Cannot copy setup file for component '"$SETUP_SERVICE"' and package manager: '"$PKGMGRNAME"'"
            else
                echo "$SETUP_SERVICE $DSTSCRIPTPATHNAME" >> $SETUP_SCRIPTS
            fi
        fi
    fi
    
    return $RES
}

# Check scripts accordingly to components to installa and destination package manager
setup_CheckScripts() {
    RES=1
    
    out "Checking installation scripts in accordance with destination package manager:"    
	
    #Global scope temporary file keeping service package manager information
	SETUP_SCRIPTS=$(mktemp setup_scripts.XXXXXX)
    TEMP_FILES+=( $SETUP_SCRIPTS )
	
	setup_CheckScript 1 fgdb $SETUP_SCRIPTS &&
	setup_CheckScript $FGAPISERVER_SETUP fgAPIServer $SETUP_SCRIPTS &&
	setup_CheckScript $APISERVERDAEMON_SETUP APIServerDaemon $SETUP_SCRIPTS && 
	setup_CheckScript $FGPORTAL_LIFERAY62_SETUP Liferay62 $SETUP_SCRIPTS && 
	setup_CheckScript $FGPORTAL_LIFERAY7_SETUP Liferay7 $SETUP_SCRIPTS &&
	RES=0 
	
	return $RES
}


# Setup a single component executing remotely the given script name
# This function does not need to check installation flags since requested scripts
# have been already processed during the CheckScript phase
# $1 - FutureGateway component name; possible values are:
#      fgdb, 
#      fgAPIServer, 
#      APIServerDaemon, 
#      Liferay64, 
#      Liferay7
# $2 - The setup script name as already uploaded on target node
setup_component() {
    RES=0
  	SETUP_SERVICE=$1
	SETUP_SCRIPT=$2

	out "Installing service: $SETUP_SERVICE ... " 1
	ssh_command $SETUP_SERVICE "rm -f .fgout" $SSH_OUT $SSH_ERR
	ssh_command $SETUP_SERVICE "rm -f .fgerr" $SSH_OUT $SSH_ERR
	ssh_command $SETUP_SERVICE "/bin/bash -l ./$SETUP_SCRIPT 2>.fgerr >.fgout" $SSH_OUT $SSH_ERR
    COMPONENT_RES=$?
    if [ $RES -ne 0 ]; then
	    out "failed" 0 1 
	    err "Failing $SETUP_SERVICE setup; ssh output and error files below"
	    err "$SETUP_SERVICE SSH Output:"
	    err "$(cat $SSH_OUT)"
	    err "$SETUP_SERVICE SSH Error:"
	    err "$(cat $SSH_ERR)"
	else
	   out "done" 0 1
	   out "Service $SETUP_SERVICE successfully installed"
	fi
    ssh_command $SETUP_SERVICE "[ -f .fgout ] && cat .fgout" $SSH_OUT /dev/null
	ssh_command $SETUP_SERVICE "[ -f .fgerr ] && cat .fgerr" $SSH_ERR /dev/null
	out "Service execution log ..."
    out "$SETUP_SERVICE (begin)"
    out "$SETUP_SERVICE Output:"
    outf $SSH_OUT
    out "$SETUP_SERVICE Error:"
    outf $SSH_ERR
    out "$SETUP_SERVICE (end)"       

    return $COMPONENT_RES
}


# At this stage target nodes already have the necessary files to setup each selected
# FutureGateway components such as: setup_config.sh and setup_commons.sh files
# The component related scripts for the right package manager
# The list of components and related scripts is stored in the file pointed by the 
# SETUP_SCRIPTS environment variable
setup() {
	RES=1
    
    out "Starting setup of components"
    
    while read service_and_script; do
        SERVICE=$(echo "$service_and_script" | awk '{ print $1 }' | xargs echo)
        SCRIPT=$(echo "$service_and_script" | awk '{ print $2 }' | xargs echo)
        setup_component "$SERVICE" "$SCRIPT"
        RES=$?
        if [ $RES -ne 0 ]; then
            err "Error while executing script $SCRIPT for component $SERVICE"
            break
        fi
    done <  "$SETUP_SCRIPTS"
    return $RES
}


#
# FutureGateway setup
#

# Cleanup global scope temporary files upon exit
trap cleanup_tempFiles EXIT

# Executing setup
setup_PreRequisites && \
setup_CheckHosts && \
setup_CheckScripts && \
setup && \
out "FutureGateway installation terminated"


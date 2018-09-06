#!/bin/bash
#
# FutureGateway common functions for brew package manager
#
# Author: Riccardo Bruno <riccardo.bruno@ct.infn.it>
#

# Add an OSX user
# $1 - User name
# $2 - User long name (User name if empty)
# $3 - User password (User name if empty)
add_osx_user() {
    UserName=$1
    [ "$2" != "" ] && UserLongName=$2 || UserLongName=$UserName
    [ "$3" != "" ] && UserPassWD=$3 || UserPassWD=$UserName
    RES=1 &&
    [ "$UserName" != "" ] &&
    LastID=$(dscl . -list /Users UniqueID | awk '{print $2}' | sort -n | tail -1) &&
    NextID=$((LastID + 1)) &&
    sudo dscl . -create /Users/$UserName &&
    sudo dscl . create /Users/administrator picture "futuregateway.png" &&
    sudo dscl . -create /Users/$UserName UserShell /bin/bash &&
    sudo dscl . -create /Users/$UserName RealName "$UserLongName" &&
    sudo dscl . -create /Users/$UserName UniqueID $NextID &&
    sudo dscl . -create /Users/$UserName PrimaryGroupID $NextID &&
    sudo dscl . -passwd /Users/$UserName "$UserPassWD" &&
    sudo dscl . -append /Groups/admin GroupMembership $UserName &&
    sudo dscl . -create /Users/$UserName NFSHomeDirectory /Users/$UserName &&
    sudo cp -R /System/Library/User\ Template/English.lproj /Users/$UserName &&
    sudo chown -R $UserName:staff /Users/$UserName &&
    #sudo chmod u+w /etc/sudoers &&
    # It is better to enable Admins with NOPASSWD
    #sudo echo "$UserName ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers &&
    #sudo chmod u-w /etc/sudoers &&
    RES=0
    return $RES
}

# Check if a given OSX user exists or not
# $1 - User name
exists_osx_user() {
  id "$1" >/dev/null 2>&1;
  RES=$?
  return $RES
}


# Check if a given user exists and create it if not existing
# A random password will be created and not visible; use passwd later to change it
# $1 - User name
# $2 - User long name
# $3 - User password
check_and_create_user() {
    RES=1
    UNAME=$1
    ULNAME=$([ "$2" = "" ] && echo $1 || echo "$2")
    UPASSWD=$([ "$3" = "" ] && openssl rand -hex 4 || echo "$3")
    if [ "$UNAME" != "" ]; then 
        [ $(exists_osx_user "$UNAME" && RES=$?) ] || add_osx_user $UNAME $ULNAME $UPASSWD
    fi
    return $RES
}

# Install a given brew package
# $1 package name
install_brew() {
    PKGNAME=$1
    out "Installing package: '"$PKGNAME"' ... " 1
    $BREW ls $PKGNAME >/dev/null 2>/dev/null
    RES=$?
    if [ $RES -ne 0 ]; then
        out "(installing) " 0 1
        # Package is not installed; try toinstall it
        $BREW install $PKGNAME
        RES=$?        
        out "$PKGNAME installation done"
        return $RES
    else
        out "(existing) " 1 1
    fi
    if [ $RES -ne 0 ]; then
        out "failed" 0 1
        break
    else
        out "done" 0 1
    fi
    return $RES
}

# Setup brew (call must be done by an Admin user)
check_and_setup_brew() {
    BREW=$(which brew)
    [ "$BREW" = "" ] && /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
    RES=$?
    # In case brew already exists; following commands allow Admin group members to use it
    sudo chmod -R g+w /usr/local
    [ -d /Library/Caches/Homebrew ] && sudo chmod -R g+w /Library/Caches/Homebrew
    return $RES
}

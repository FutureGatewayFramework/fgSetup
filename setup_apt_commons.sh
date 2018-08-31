#!/bin/bash
#
# FutureGateway common functions for apt-get package manager
#
# Author: Riccardo Bruno <riccardo.bruno@ct.infn.it>
#

# Install package list using apt-get
install_apt() {
  APTPACKAGES=$@

  APT_GET=$(which apt-get)
  if [ "$APT_GET" = "" ]; then
    out "Did not find apt-get package manager"
    exit 1
  fi
  out "APT is on: '"$APT_GET"'"
  out "Installing packages:"
  for pkg in $APTPACKAGES; do
    out "    $pkg"
  done

  sudo $APT_GET update &&\
  sudo $APT_GET install -y $APTPACKAGES
  RES=$?

  return $RES
}

# Check for FutureGateway fgdb unix user
check_and_create_user() {
  HOSTUNAME=$1

  if [ ! -d /home/$HOSTUNAME ]; then
    sudo adduser --disabled-password --gecos "" $HOSTUNAME
    RES=$?
    if [ $RES -eq 0 ]; then
      out "User $HOSTUNAME added successfully"
    else
      out "Unable to add user: $FGDB_HOSTUNAME"
      exit 1
    fi
  fi
  
  return $RES
}

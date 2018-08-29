#!/bin/bash
#
# FutureGateway common functions for apt-get package manager
#
# Author: Riccardo Bruno <riccardo.bruno@ct.infn.it>
#


install_apt() {
  APTPACKAGES=$@

  APT_GET=$(which apt-get)
  if [ "$APT_GET" = "" ]; then
    out "Did not find apt-get package manager"
    exit 1
  fi
  out "APT is on: '"$APT_GET"'"
  out "Installing packages ..."

  sudo $APT_GET update &&\
  sudo $APT_GET install -y $APTPACKAGES
  RES=$?

  return $RES
}

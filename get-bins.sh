#!/bin/bash
####################################################################
# Support binary downloader
# - Code by Jioh L. Jung
####################################################################
#- Move Script directory as base
BASE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd "${BASE_DIR}"

#- Imports configure & functions
if [ -f "config" ]; then
  chmod +x config
  . ./config
fi
. ./default
. libs/functions


curl -L -o ./bins/socat "https://github.com/andrew-d/static-binaries/blob/master/binaries/linux/x86_64/socat?raw=true"
chmod +x ./bins/socat


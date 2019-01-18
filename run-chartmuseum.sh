#!/bin/bash -x
####################################################################
# Helm local repository starter
# - Code by Jioh L. Jung
####################################################################

####################################################################
# Setup values

#- Root Check
if (( EUID != 0 )); then
    echo "You must be root to do this." 1>&2
    exit 1
fi

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

#- Imports configure & functions
if [ -f "config" ]; then
  chmod +x config
  . ./config
fi
. ./default
. libs/functions


docker rm -f chartmuseum || true
if [ "${FLAG_OFFLINE_INSTALL}" == "no" ]; then
  docker pull chartmuseum/chartmuseum:latest
fi

docker run \
  -d --restart=always --name=chartmuseum \
  --net=host \
  -e DEBUG=1 \
  -e STORAGE=local \
  -e STORAGE_LOCAL_ROOTDIR=/charts \
  -v $(pwd)/helm/mirror:/charts \
  chartmuseum/chartmuseum:latest --port=8888
#-p 8080:8080 \

sleep 5
helm repo remove stable
helm repo add stable http://${EXT_IP}:8888
helm repo update
exit 0
#./helm/chartmuseum --debug --port=8080 \
#  --storage="local" \
#  --storage-local-rootdir="./helm/mirror"



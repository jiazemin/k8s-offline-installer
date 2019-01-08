#!/bin/bash -x
####################################################################
# Kubernetes Docker Image downloader
# - Code by Jioh L. Jung
####################################################################

####################################################################
# Setup values
#- Log files
TMP_LOG_FILE=$(mktemp /tmp/output.XXXXXXXXXX)

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

####################################################################
docker images | awk '{print $3}' | xargs docker rmi -f {}
kubeadm config images pull --kubernetes-version v${K8S_VERSION_TMP}
. ./dump-images.sh ./images/${K8S_VERSION_TMP}


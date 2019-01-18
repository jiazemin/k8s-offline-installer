#!/bin/bash
####################################################################
# Kubernetes base installer for common
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
. ./install-common.sh

if [ -f "${HOME}/.kube/config" ]; then
  kubeadm upgrade plan
  kubeadm upgrade apply -f -y v${K8S_VERSION_TMP}
fi

sleep 3
systemctl restart kubelet

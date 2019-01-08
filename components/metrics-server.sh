#!/bin/bash
####################################################################
# Metric Servers Installer for Master
# - Code by Jioh L. Jung
####################################################################

#- Move Script directory as base
BASE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd "${BASE_DIR}"

#- Imports configure & functions
if [ -f "../config" ]; then
  chmod +x ../config
  . ../config
fi
. ../default
. ../libs/functions

kubectl create -f metrics-server.yaml

wait_pod_up "metrics-server" "kube-system" 1

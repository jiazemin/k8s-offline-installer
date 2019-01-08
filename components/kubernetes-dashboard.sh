#!/bin/bash
####################################################################
# Dashboards Installer for Master
# - Code by Jioh L. Jung
####################################################################

#- Move Script directory as base
BASE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd "${BASE_DIR}"

kubectl create -f kubernetes-dashboard.yaml

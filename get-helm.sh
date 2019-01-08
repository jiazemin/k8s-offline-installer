#!/bin/bash
####################################################################
# Helm binary downloader
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

# Install Helm
if [ "${HELM_VER}" == "latest" ]; then
  HELM_VER_TMP=$(get_latest_release 'helm/helm' | tr -dc '\.0-9')
else
  HELM_VER_TMP=$(echo "${HELM_VER}" | tr -dc '\.0-9')
fi

cd /tmp/
curl https://storage.googleapis.com/kubernetes-helm/helm-v${HELM_VER_TMP}-${HELM_ARCH}.tar.gz | tar xvzf -

mkdir -p ${BASE_DIR}/helm/${HELM_VER_TMP}
cp -f /tmp/${HELM_ARCH}/helm ${BASE_DIR}/helm/${HELM_VER_TMP}/
cp -f /tmp/${HELM_ARCH}/tiller ${BASE_DIR}/helm/${HELM_VER_TMP}/
rm -rf /tmp/${HELM_ARCH}

cd ${BASE_DIR}/helm
rm -f latest
ln -s ${HELM_VER_TMP} latest

cd "${BASE_DIR}"

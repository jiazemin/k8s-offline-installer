#!/bin/bash
####################################################################
# HAProxy Installer for Master
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

# Functions
#- Wait until Pods up
wait_pod_up () {
  POD_NAME=${1:-"none"}
  NS=${2:-"default"}
  POD_COUNT=${3:-1}
  while true; do
    RES=`kubectl get pod -o wide -n ${NS} | grep ${POD_NAME} | grep -i running | wc -l`
    echo "> Running Pod Detected (${POD_NAME}/${NS}): ${RES}/${POD_COUNT}"
    if [ "${RES}" -eq "${POD_COUNT}" ] || [ "${RES}" -gt "${POD_COUNT}" ]; then
      return 0
    else
      kubectl get pod -o wide -n ${NS} | grep ${POD_NAME} || true
    fi
    sleep 3
  done
}

# Set HAProxy
rm -rf ${HAPROXY_CONFIG_PATH} || true
mkdir -p ${HAPROXY_CONFIG_PATH} || true

# Get Cert
if [ -f "config/${CERT_DOMAINS}.pem" ]; then
  echo ">> Cert Found"
else
  echo ">> Cert Generating"
  ./generate-keys.sh
fi
cp -f config/${CERT_DOMAINS}.pem ${HAPROXY_CONFIG_PATH}/${CERT_DOMAINS}.pem

# generate haproxy configuration
. ../libs/parse.sh < ./haproxy/haproxy.cfg.template > ${HAPROXY_CONFIG_PATH}/haproxy.cfg

# yml file processing
. ../libs/parse.sh < ./haproxy/haproxy.yml.template | kubectl create -f -
. ../libs/parse.sh < ./haproxy/haproxy.yml.template > debug.yml

wait_pod_up "haproxy-lb-" "ingress" 2

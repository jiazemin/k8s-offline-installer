#!/bin/bash
####################################################################
# ES-Single Node Installer (Test Purpose)
# - Code by Jioh L. Jung
####################################################################

#- Move Script directory as base
BASE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd "${BASE_DIR}"

ELASTIC_HOST_NODE_NAME="host-10-1-2-69"

ELASTIC_VERSION=${ELASTIC_VERSION:-"6.5.2"}
# WARNING: ELASTIC_HOST_PATH must be created and setted owner directory to docker or set mode 777
ELASTIC_HOST_PATH=${ELASTIC_HOST_PATH:-"/opt/elastic/"}
ELASTIC_HOST_NODE_NAME=${ELASTIC_HOST_NODE_NAME:-""}
#ELASTIC_SEARCH_SVC=${ELASTIC_SEARCH_SVC:-"elasticsearch-client"}
ELASTIC_SEARCH_DOMAIN=${ELASTIC_SEARCH_DOMAIN:-"elasticsearch-client.kube-elk.svc.cluster.local"}
#ELASTIC_KIBANA_PATH=${ELASTIC_KIBANA_PATH:-"/NAS/k8s-data/kibana/config"}

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

kubectl create -f es-namespace.yml

. ../../libs/parse.sh < es-single.yml.template | kubectl create -f -

wait_pod_up "elasticsearch-client" "kube-elk" 1

. ../../libs/parse.sh < kibana.yml.template  | kubectl create -f -

wait_pod_up "elk-kibana" "kube-elk" 1

#kubectl run elasticsearch --image=docker.elastic.co/elasticsearch/elasticsearch:latest --env="discovery.type=single-node" --port=9200



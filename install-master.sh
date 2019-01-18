#!/bin/bash -x
####################################################################
# Kubernetes Installer for Master
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


if [ ! -x "$(command -v docker)" ]; then echo ">> need docker install <<" ; exit 1; fi
if [ ! -x "$(command -v kubeadm)" ]; then echo ">> need kubeadm install <<" ; exit 1 ; fi
if [ ! -x "$(command -v kubectl)" ]; then echo ">> need kubectl install <<" ; exit 1; fi

#- Print Env. Params for debugging
echo ">>ENV>>================================================================"
env
echo "<<ENV<<================================================================"

if [ "${FLAG_IGNORE_DOCKER_VERSION}" == "yes" ]; then
  KUBEADM_OPTIONS="${KUBEADM_OPTIONS} --ignore-preflight-errors=SystemVerification"
fi

KUBEADM_OPTIONS="${KUBEADM_OPTIONS} --kubernetes-version=v${K8S_VERSION_TMP}"
KUBEADM_OPTIONS="${KUBEADM_OPTIONS} --pod-network-cidr=${K8S_POD_CIDR}"
KUBEADM_OPTIONS="${KUBEADM_OPTIONS} --apiserver-advertise-address=${KUBEADM_ADVERTISE_IP}"

echo "K8S Version: '${K8S_VERSION}'"
if ! [ "${K8S_VERSION}" == "latest" ]; then
  ${BASE_DIR}/load-images.sh ./images/"${K8S_VERSION_TMP}"
fi
${BASE_DIR}/load-images.sh ./images/shared/


systemctl restart docker
sleep 3

kubeadm init \
  ${KUBEADM_OPTIONS}


#-  Setup kubecfg's configurations
${BASE_DIR}/set-permission.sh

#- Copy Required files
if [ "${CNI_PLUGIN_TYPE}" == "weave" ]; then
  if command_exists weave; then
    echo ">> weave found..."
  else
    cp -f ./bins/weave /usr/bin/weave
    chmod +x /usr/bin/weave
  fi
fi

#- Set CNI Plugins
./load-images.sh ./cni/${CNI_PLUGIN_TYPE}
kubectl create -f ./cni/${CNI_PLUGIN_TYPE}.yaml

#- Wait for CNI loading
if [ "${CNI_PLUGIN_TYPE}" == "calico" ]; then
  #- Calico
  wait_pod_up "calico-node-" "kube-system" 1
fi

if [ "${CNI_PLUGIN_TYPE}" == "flannel" ]; then
  #- Flannel
  wait_pod_up "kube-flannel-" "kube-system" 1
fi

if [ "${CNI_PLUGIN_TYPE}" == "weave" ]; then
  #- Weave
  wait_pod_up weave-net "kube-system" 1
fi

if [ "${CNI_PLUGIN_TYPE}" == "romania" ]; then
  #- Romania
  wait_pod_up "romana-agent" "kube-system" 1
  wait_pod_up "romana-daemon" "kube-system" 1
fi

#- CoreDNS configure
#  Kubectl coredns config (bug fix for 1.12.x issues)
kubectl -n kube-system get deployment coredns -o yaml | \
  sed 's/allowPrivilegeEscalation: false/allowPrivilegeEscalation: true/g' | \
  kubectl apply -f -

kubectl get cm coredns -n kube-system -o yaml | \
  sed 's/loop/#loop/g' | \
  kubectl apply -f -

wait_pod_up "coredns-" "kube-system" 2

#- PV storage setup
. ./storage/${PV_STORAGE_TYPE}.sh

#- Single Mode Setup
if [ "${FLAG_SET_SINGLE_NODE}" == "yes" ]; then
  # Set Single Node Taints
  kubectl taint nodes --all node-role.kubernetes.io/master-
else
  #- Generate Join Command
  ./get-slave-join.sh
fi

wait_pod_up kube-apiserver kube-system 1
wait_pod_up kube-scheduler kube-system 1


#!/bin/bash -x
####################################################################
# Kubeapps Installer for Master
# - Code by Jioh L. Jung
####################################################################

#- Move Script directory as base
BASE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd "${BASE_DIR}"

# Add Kubeapps
mkdir -p ${HOME}/.token/ || true

if [ `helm repo list | grep bitnami | wc -l` -eq "0" ]; then
  echo "> no helm repo. add bitnami"
  helm repo add bitnami https://charts.bitnami.com/bitnami || true
  helm update
fi

#helm delete --purge kubeapps
helm install --name kubeapps --namespace kubeapps bitnami/kubeapps
kubectl create serviceaccount kubeapps-operator
kubectl create clusterrolebinding kubeapps-operator --clusterrole=cluster-admin --serviceaccount=default:kubeapps-operator
TOKEN=`kubectl get secret \
  $(kubectl get serviceaccount kubeapps-operator -o jsonpath='{.secrets[].name}') \
  -o jsonpath='{.data.token}' | base64 --decode`
echo "${TOKEN}" > ${HOME}/.token/kubeapps

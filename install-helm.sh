#!/bin/bash
####################################################################
# Helm Package Installer for Master
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
# Latest
case "$lsb_dist" in
  ubuntu|debian)
    echo ">> Ubuntu/Debian..."
    echo ">> Latest Version"
    HELM_PACKAGES=`find helm/deb-packages/helm-* | sort | tail -n 1`
    echo ">> Package: ${HELM_PACKAGES}"
    if [ `apt list --installed 2> /dev/null | grep helm | wc -l` -eq "0" ]; then
      echo ">> Clean Install"
      dpkg_install ${HELM_PACKAGES}
    else
      echo ">> Update Install"
      dpkg_install ${HELM_PACKAGES}
    fi
    ;;
  centos|rhel|ol|sles)
    echo ">> Centos/RHEL/OL/SLES...."
    echo ">> Latest Version"
    HELM_PACKAGES=`find helm/rpm-packages/helm-* | sort | tail -n 1`
    echo ">> Package: ${HELM_PACKAGES}"
    if [ `rpm -qa | grep helm | wc -l` -eq "0" ]; then
      echo ">> Clean Install"
      rpm -ivh ${HELM_PACKAGES}
    else
      echo ">> Update Install"
      rpm -Uvh ${HELM_PACKAGES}
    fi
    ;;
    *)
      echo "> Not Supported OS/Dist."
      exit 1
    ;;
esac


kubectl -n kube-system create serviceaccount tiller
kubectl create clusterrolebinding tiller --clusterrole cluster-admin --serviceaccount=kube-system:tiller
helm init --service-account=tiller
helm repo update

wait_pod_up "tiller-deploy-" "kube-system" 1

# Add Repos - to Tiller
if [ "${FLAG_ADD_HELM_REPO}" == "yes" ]; then
  helm repo add bitnami https://charts.bitnami.com/bitnami
  helm repo add fabric8 https://fabric8.io/helm
  helm repo add gitlab https://charts.gitlab.io
  helm repo add svc-cat https://svc-catalog-charts.storage.googleapis.com
  helm repo update
fi

while [ `helm version | grep Server | wc -l` -eq "0" ]; do
  echo "> Wait until Helm-Tiller Server UP"
  sleep 3
done

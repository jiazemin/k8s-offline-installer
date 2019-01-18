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
#
if ! [ -x "$(command -v socat)" ]; then
  cp -f ./bins/socat /usr/bin/
fi

# Latest
case "$lsb_dist" in
  ubuntu|debian)
    echo ">> Ubuntu/Debian..."
    if [ "${K8S_VERSION}" == "latest" ] || [ "${K8S_VERSION}" == "default" ]; then
      K8S_PACKAGES=`find bases/deb-packages/kubehosts-* | sort | tail -n 1`
    else
      echo ">> Specific Version: ${K8S_VERSION}"
      K8S_PACKAGES=`find bases/deb-packages/kubehosts-* | sort | grep ${K8S_VERSION}`
    fi

    echo ">> Package: ${K8S_PACKAGES}"
    if [ `apt list --installed 2> /dev/null | grep kubehosts | wc -l` -eq "0" ]; then
      echo ">> Clean Install"
    else
      echo ">> Update Install"
    fi

    dpkg_install ${K8S_PACKAGES}
    ;;
  centos|rhel|ol|sles)
    echo ">> Centos/RHEL/OL/SLES...."
    if [ "${K8S_VERSION}" == "latest" ] || [ "${K8S_VERSION}" == "default" ]; then
      K8S_PACKAGES=`find bases/rpm-packages/kubehosts-* | sort | tail -n 1`
    else
      echo ">> Specific Version: ${K8S_VERSION}"
      K8S_PACKAGES=`find bases/rpm-packages/kubehosts-* | sort | grep ${K8S_VERSION}`
    fi

    echo ">> Package: ${K8S_PACKAGES}"
    if [ `rpm -qa | grep kubehosts | wc -l` -eq "0" ]; then
      echo ">> Clean Install"
      rpm -ivh ${K8S_PACKAGES}
    else
      echo ">> Update Install"
      rpm -Uvh ${K8S_PACKAGES}
    fi
    ;;
  *)
    echo "> Not Supported OS/Dist."
    exit 1
    ;;
esac

${BASE_DIR}/load-images.sh ./images/${K8S_VERSION_TMP}
systemctl restart docker

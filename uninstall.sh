#!/bin/bash
####################################################################
# Kubernetes Uninstaller for Master
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
# CleanUp Old configuration
#- Reset K8S using kubeadm
if command_exists kubeadm; then
  kubeadm reset -f || true
fi

#- Remove network configuration
if command_exists weave; then
  weave reset --force || true
  rm -rf /usr/bin/weave
fi

#- Stop Service
systemctl stop kubelet || true
systemctl stop docker || true

#- Remove kubernetes base packages
if command_exists apt; then
  apt remove -y kubehosts || true
fi
if command_exists yum; then
  yum remove -y kubehosts || true
fi

#- Remove directories
rm -rf ${HOME}/.kube
rm -rf ${HOME}/.helm
rm -rf ${HOME}/.token

rm -rf /etc/kubernetes/
rm -rf /etc/cni/
rm -rf /var/lib/cni/
rm -rf /var/lib/kubelet/*
rm -rf /var/lib/romana/

#- Reset Network Interfaces
purge_iface docker0
purge_iface cni0
purge_iface flannel.1
purge_iface weave
purge_iface romana-lo
ip -all netnsip netns delete || true

iptables -F && iptables -t nat -F && iptables -t mangle -F && iptables -X || true
if command_exists ipvsadm; then
  ipvsadm --clear || true
fi
#- Remove kernel modules for Kubernetes
modprobe -r ipip || true
modprobe -r libceph || true
modprobe -r rbd || true
modprobe -r vport_vxlan || true
modprobe -r openvswitch || true
modprobe -r vxlan || true

#
# Restart Base
sleep 3
mkdir -p /etc/cni/net.d
systemctl start docker

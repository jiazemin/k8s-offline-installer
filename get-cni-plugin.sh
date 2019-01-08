#!/bin/bash
####################################################################
# Kubernetes Installer for Master
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
  chmod +x ./config
  . ./config
fi
. ./default
. ./libs/functions


#command_exists docker || { echo ">> need docker install <<"; exit 1}

####################################################################
TIMESTAMPS="$(LC_ALL=c date)"

#- Functions
function get_docker_images() {
  #> Fetch Images
  CNI_PLUGINS="$1"
  mkdir -p cni/${CNI_PLUGINS}
  for j in $(cat cni/${CNI_PLUGINS}.yaml | grep "image:" | tr "'" ' ' | tr '"' ' ' | awk '{print $NF}')
  do
    case "$j" in
      *:*)
        # Do stuff
        echo ">> Tag Existed"
        ;;
      *)
        # None
        echo ">> No Tags"
        j="$j:latest"
        ;;
    esac
    FN="cni/${CNI_PLUGINS}/$(echo "$j" | tr '[/]' '_' | tr '[:]' '+').tgz"
    if [ -f "${FN}" ]; then
      echo "> already exist. skipping..: $j"
      continue
    fi

    echo "> trying pull image: $j"
    docker pull "$j"

    if [ -f "${FN}" ]; then
      echo ">> File Existed: ${FN}"
      if [ "${FN: -10}" == "latest.tgz" ]; then
        echo ">> Overwrite (latest tag)"
        echo "> ${j} Saving -> ${FN}.."
        docker save ${j} | gzip -c > ${FN}
        echo "> ${j} Done.."
      fi
    else
      echo "> ${j} Saving -> ${FN}.."
      docker save ${j} | gzip -c > ${FN}
      echo "> ${j} Done.."
    fi
    docker rmi -f "$j"
  done
}

#- Calico
#> Need URL Update from: https://kubernetes.io/docs/setup/independent/create-cluster-kubeadm/
#> For Calico to work correctly, you need to pass --pod-network-cidr=192.168.0.0/16 to kubeadm init or update the calico.yml file to match your Pod network. Note that Calico works on amd64 only.
echo "# Created: ${TIMESTAMPS}" > cni/calico.yaml
echo "#>> RBAC <<" >> cni/calico.yaml
curl -L https://docs.projectcalico.org/v3.3/getting-started/kubernetes/installation/hosted/rbac-kdd.yaml | \
  sed "s,192.168.0.0/16,${K8S_POD_CIDR},g" | \
  cat >> cni/calico.yaml
echo "---" >> cni/calico.yaml 
echo "#>> Calico <<" >> cni/calico.yaml
curl -L https://docs.projectcalico.org/v3.3/getting-started/kubernetes/installation/hosted/kubernetes-datastore/calico-networking/1.7/calico.yaml | \
  sed "s,192.168.0.0/16,${K8S_POD_CIDR},g" | \
  cat >> cni/calico.yaml

get_docker_images "calico"

#- Canal
#> Need URL Update from: https://kubernetes.io/docs/setup/independent/create-cluster-kubeadm/
#> For Canal to work correctly, --pod-network-cidr=10.244.0.0/16 has to be passed to kubeadm init. Note that Canal works on amd64 only.
echo "# Created: ${TIMESTAMPS}" > cni/canal.yaml
echo "#>> RBAC <<" >> cni/canal.yaml
curl -L https://docs.projectcalico.org/v3.3/getting-started/kubernetes/installation/hosted/canal/rbac.yaml | \
  sed "s,10.244.0.0/16,${K8S_POD_CIDR},g" | \
  cat >> cni/canal.yaml
echo "---" >> cni/canal.yaml
curl -L https://docs.projectcalico.org/v3.3/getting-started/kubernetes/installation/hosted/canal/canal.yaml | \
  sed "s,10.244.0.0/16,${K8S_POD_CIDR},g" | \
  cat >> cni/canal.yaml
get_docker_images "canal"

#- Flannel
#> Need URL Update from: https://kubernetes.io/docs/setup/independent/create-cluster-kubeadm/
#> For flannel to work correctly, you must pass --pod-network-cidr=10.244.0.0/16 to kubeadm init.
#> Set /proc/sys/net/bridge/bridge-nf-call-iptables to 1 by running sysctl net.bridge.bridge-nf-call-iptables=1 to pass bridged IPv4 traffic to iptables’ chains. This is a requirement for some CNI plugins to work, for more information please see here.
echo "# Created: ${TIMESTAMPS}" > cni/flannel.yaml
echo "#>> Flannel <<" >> cni/flannel.yaml
curl -L https://raw.githubusercontent.com/coreos/flannel/bc79dd1505b0c8681ece4de4c0d86c5cd2643275/Documentation/kube-flannel.yml | \
  sed "s,10.244.0.0/16,${K8S_POD_CIDR},g" | \
  cat >> cni/flannel.yaml
get_docker_images "flannel"

#- Romana
#> Set /proc/sys/net/bridge/bridge-nf-call-iptables to 1 by running sysctl net.bridge.bridge-nf-call-iptables=1 to pass bridged IPv4 traffic to iptables’ chains. This is a requirement for some CNI plugins to work, for more information please see here.
echo "# Created: ${TIMESTAMPS}" > cni/romana.yaml
echo "#>> Romana <<" >> cni/romana.yaml
curl -L https://raw.githubusercontent.com/romana/romana/master/containerize/specs/romana-kubeadm.yml | \
  cat >> cni/romana.yaml
get_docker_images "romana"

#- Weave
#> Set /proc/sys/net/bridge/bridge-nf-call-iptables to 1 by running sysctl net.bridge.bridge-nf-call-iptables=1 to pass bridged IPv4 traffic to iptables’ chains. This is a requirement for some CNI plugins to work, for more information please see here.
echo "# Created: ${TIMESTAMPS}" > cni/weave.yaml

#>> fetch latest kubectl
curl -L --remote-name-all https://storage.googleapis.com/kubernetes-release/release/v${K8S_VERSION_TMP}/bin/linux/amd64/kubectl
chmod +x kubectl
mv -f kubectl /tmp/

echo "#>> Weave Net <<" >> cni/weave.yaml
curl -L "https://cloud.weave.works/k8s/net?k8s-version=$(/tmp/kubectl version | base64 | tr -d '\n')" | \
  cat >> cni/weave.yaml

get_docker_images "weave"

curl -L git.io/weave -o cni/weave/weave
chmod a+x cni/weave/weave

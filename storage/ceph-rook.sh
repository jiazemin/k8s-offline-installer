CEPH_LIB_PATH=${CEPH_LIB_PATH:-"/mnt/disk1"}


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

# Rook-Based-Ceph: Known Issue (After Remove, CPU Hogging issue)
#- Single Node Test

#- Purge All Data
mkdir -p ${CEPH_LIB_PATH}
rm -rf ${CEPH_LIB_PATH}/*

#- Install Ceph (For Dynamic Storage)
#kubectl delete -f https://raw.githubusercontent.com/rook/rook/master/cluster/examples/kubernetes/ceph/cluster.yaml
#kubectl delete -f https://raw.githubusercontent.com/rook/rook/master/cluster/examples/kubernetes/ceph/operator.yaml
#kubectl delete -f https://raw.githubusercontent.com/rook/rook/master/cluster/examples/kubernetes/ceph/storageclass.yaml
#kubectl delete -f https://raw.githubusercontent.com/rook/rook/master/cluster/examples/kubernetes/ceph/dashboard-external-https.yaml
#kubectl delete -f https://raw.githubusercontent.com/rook/rook/master/cluster/examples/kubernetes/ceph/toolbox.yaml

curl -L https://raw.githubusercontent.com/rook/rook/master/cluster/examples/kubernetes/ceph/operator.yaml | \
  sed "s,/var/lib/rook,${CEPH_LIB_PATH},g" | \
  kubectl create -f -

curl -L https://raw.githubusercontent.com/rook/rook/master/cluster/examples/kubernetes/ceph/cluster.yaml | \
  sed "s,/var/lib/rook,${CEPH_LIB_PATH},g" | \
  kubectl create -f -  

curl -L https://raw.githubusercontent.com/rook/rook/master/cluster/examples/kubernetes/ceph/storageclass.yaml | \
  kubectl create -f -

curl -L https://raw.githubusercontent.com/rook/rook/master/cluster/examples/kubernetes/ceph/dashboard-external-https.yaml | \
  kubectl create -f -

curl -L https://raw.githubusercontent.com/rook/rook/master/cluster/examples/kubernetes/ceph/toolbox.yaml | \
  kubectl create -f -

wait_pod_up rook-ceph-agent rook-ceph-system 1
wait_pod_up rook-ceph-operator rook-ceph-system 1
wait_pod_up rook-discover rook-ceph-system 1
wait_pod_up rook-ceph-mon-a rook-ceph 1
wait_pod_up rook-ceph-mon-b rook-ceph 1
wait_pod_up rook-ceph-mon-c rook-ceph 1

kubectl patch storageclass rook-ceph-block \
  -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'


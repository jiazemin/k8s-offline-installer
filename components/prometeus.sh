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

mkdir -p ${HOME}/.token/ || true

#- Prometheus
helm install stable/prometheus --name prometheus --namespace kube-monitor
helm install stable/prometheus-operator --name prometheus-operator --namespace kube-monitor

wait_pod_up prometheus-server kube-monitor 1

#- Grafana
helm install stable/grafana --name grafana --namespace kube-monitor
TOKEN=`kubectl get secret --namespace kube-monitor grafana -o jsonpath="{.data.admin-password}" | base64 --decode ; echo`
echo "${TOKEN}" > ${HOME}/.token/grafana

wait_pod_up grafana kube-monitor 1

# Install Kubernetes & Generate Dashboard Token
kubectl apply -f ./kubernetes-dashboard.yaml
kubectl create serviceaccount cluster-admin-dashboard-sa
kubectl create clusterrolebinding cluster-admin-dashboard-sa \
  --clusterrole=cluster-admin \
  --serviceaccount=default:cluster-admin-dashboard-sa
TOKEN=`kubectl describe secret \
   $(kubectl get secret | grep cluster-admin-dashboard-sa | awk '{print $1}') | \
   grep "^token" | awk '{print $2}'`
echo "${TOKEN}" > ${HOME}/.token/kube-dashboard

wait_pod_up "kubernetes-dashboard-" "kube-system" 1

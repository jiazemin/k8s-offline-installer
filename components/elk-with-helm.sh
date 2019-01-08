helm install stable/elastic-stack --name elk --namespace kube-elk -f elk.yml

helm install stable/elasticsearch-exporter --name es-exporter --namespace kube-elk \
--set es.uri=es-elasticsearch-client.kube-elk.svc.cluster.local:9200

#helm install stable/metricbeat --name metricbeat --namespace kube-el
kubectl create -f ./beats/

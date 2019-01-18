#!/bin/bash
. default

docker rm -f rancher || true
docker pull   rancher/rancher:latest

HostIP="${EXT_IP}"
docker run -d \
 -v /host/rancher/ca-certificates/:/etc/ssl/certs \
 -p 4001:4001 -p 2380:2380 -p 2379:2379 \
 --name etcd quay.io/coreos/etcd:v2.3.8 \
 -name etcd0 \
 -advertise-client-urls http://${HostIP}:2379,http://${HostIP}:4001 \
 -listen-client-urls http://0.0.0.0:2379,http://0.0.0.0:4001 \
 -initial-advertise-peer-urls http://${HostIP}:2380 \
 -listen-peer-urls http://0.0.0.0:2380 \
 -initial-cluster-token etcd-cluster-1 \
 -initial-cluster etcd0=http://${HostIP}:2380 \
 -initial-cluster-state new

docker run -d --restart=unless-stopped \
  --name=rancher \
  -p 10080:80 -p 10443:443 \
  -v /host/rancher:/var/lib/rancher \
  rancher/rancher:latest


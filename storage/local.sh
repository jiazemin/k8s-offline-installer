#!/bin/bash -x
####################################################################
# Kubernetes PV storage configuration (example: NFS)
# - Code by Jioh L. Jung
####################################################################
# Code is for Use local storage as K8S storage
# mabe just fit for 'NFS mounted storage'

#- Generate Local Storage
rm -rf ${PV_STORAGE_LOCAL_PATH}
mkdir -p ${PV_STORAGE_LOCAL_PATH}
cat << EFF | kubectl create -f -
kind: StorageClass
apiVersion: storage.k8s.io/v1
metadata:
  namespace: default
  name: ${PV_STORAGE_NAME}
  annotations:
    storageclass.kubernetes.io/is-default-class: "true"
provisioner: kubernetes.io/no-provisioner
volumeBindingMode: WaitForFirstConsumer
EFF

# Create Basic Storage Directories
#- 020 means total count of storage
for i in {001..040}; do
mkdir -p "${PV_STORAGE_LOCAL_PATH}/${i}"
chmod 777 "${PV_STORAGE_LOCAL_PATH}/${i}"
cat << EFF | kubectl create -f -
apiVersion: v1
kind: PersistentVolume
metadata:
  name: ${PV_STORAGE_NAME}-${i}
  labels:
    types: hdd
spec:
  storageClassName: ${PV_STORAGE_NAME}
  capacity:
    storage: ${PV_STORAGE_MAX_SIZE}
  volumeMode: Filesystem
  accessModes:
  - ReadWriteOnce
  - ReadOnlyMany
  - ReadWriteMany
  persistentVolumeReclaimPolicy: Recycle
  hostPath:
    path: "${PV_STORAGE_LOCAL_PATH}/${i}"
EFF
done

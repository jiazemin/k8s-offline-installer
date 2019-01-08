
STORAGE_K8S_ACCOUNT=${STORAGE_K8S_ACCOUNT:-"kube"}
STORAGE_NAME=${STORAGE_NAME:-"ceph"}

CEPH_PG_NUM=${CEPH_PG_NUM:-"10"}
CEPH_PGP_NUM=${CEPH_PGP_NUM:-"10"}

EXT_IP=${EXT_IP:-"$(ip route get 8.8.8.8 | awk '/8.8.8.8/ {print $7}')"}

# Single Node Ceph Configure
#- ADMIN SECRET CREATION
ADMIN_SECRET="$(ceph auth get-key client.admin | base64)"
#echo "${ADMIN_SECRET}" > /tmp/secret
#kubectl create secret generic ceph-admin-secret --from-file=/tmp/secret --namespace=kube-system

#- USER SECRET CREATION
#- http://docs.ceph.com/docs/jewel/rados/operations/pools/
ceph osd pool create ${STORAGE_K8S_ACCOUNT} ${CEPH_PG_NUM} ${CEPH_PGP_NUM}
ceph auth add client.${STORAGE_K8S_ACCOUNT} mon "allow r" osd "allow rwx pool=${STORAGE_K8S_ACCOUNT}"
KUBE_SECRET="$(ceph auth get-key client.${STORAGE_K8S_ACCOUNT} | base64)"
#echo "${KUBE_SECRET}" > /tmp/secret
#kubectl create secret generic ceph-secret --from-file=/tmp/secret --namespace=kube-system

echo "ADMIN: '${ADMIN_SECRET}'"
echo "KUBE: '${KUBE_SECRET}'"

# Start RDB Provisioner
cat << EOF | kubectl create -f -
apiVersion: v1
kind: Secret
metadata:
  name: rbd-secret-admin
  namespace: kube-system
data:
  key: ${ADMIN_SECRET}
type:
  kubernetes.io/rbd
---
apiVersion: v1
kind: Secret
metadata:
  name: rbd-secret-${STORAGE_K8S_ACCOUNT}
  namespace:
data:
  key: ${KUBE_SECRET}
type:
  kubernetes.io/rbd
---

apiVersion: v1
kind: ServiceAccount
metadata:
  namespace: kube-system
  name: rbd-provisioner

---
kind: ClusterRole
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: rbd-provisioner
rules:
  - apiGroups: [""]
    resources: ["persistentvolumes"]
    verbs: ["get", "list", "watch", "create", "delete"]
  - apiGroups: [""]
    resources: ["persistentvolumeclaims"]
    verbs: ["get", "list", "watch", "update"]
  - apiGroups: ["storage.k8s.io"]
    resources: ["storageclasses"]
    verbs: ["get", "list", "watch"]
  - apiGroups: [""]
    resources: ["events"]
    verbs: ["create", "update", "patch"]
  - apiGroups: [""]
    resources: ["services"]
    resourceNames: ["kube-dns","coredns"]
    verbs: ["list", "get"]
  - apiGroups: [""]
    resources: ["endpoints"]
    verbs: ["get", "list", "watch", "create", "update", "patch"]
  - apiGroups: [""]
    resources: ["secrets"]
    verbs: ["get", "create", "delete"]

---
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: rbd-provisioner
subjects:
  - kind: ServiceAccount
    name: rbd-provisioner
    namespace: kube-system
roleRef:
  kind: ClusterRole
  name: rbd-provisioner
  apiGroup: rbac.authorization.k8s.io
---


apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: rbd-provisioner
rules:
- apiGroups: [""]
  resources: ["secrets"]
  verbs: ["get"]
- apiGroups: [""]
  resources: ["endpoints"]
  verbs: ["get", "list", "watch", "create", "update", "patch"]
---

apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: rbd-provisioner
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: rbd-provisioner
subjects:
- kind: ServiceAccount
  name: rbd-provisioner
  namespace: default

---

apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: rbd-provisioner
  namespace: kube-system
spec:
  replicas: 1
  strategy:
    type: Recreate
  template:
    metadata:
      labels:
        app: rbd-provisioner
    spec:
      containers:
      - name: rbd-provisioner
        image: "quay.io/external_storage/rbd-provisioner:latest"
        env:
        - name: PROVISIONER_NAME
          value: ceph.com/rbd
      serviceAccount: rbd-provisioner
---

apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: rbd
  annotations:
    storageclass.kubernetes.io/is-default-class: "true"
provisioner: ceph.com/rbd
reclaimPolicy: Delete
parameters:
  monitors: ${EXT_IP}:6789
  adminId: admin
  adminSecretName: rbd-secret-admin
  adminSecretNamespace: kube-system
  pool: ${STORAGE_K8S_ACCOUNT}
  userId: ${STORAGE_K8S_ACCOUNT}
  userSecretName: rbd-secret-${STORAGE_K8S_ACCOUNT}
  imageFormat: "2"
  imageFeatures: layering
EOF


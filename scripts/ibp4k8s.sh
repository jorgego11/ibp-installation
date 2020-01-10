#!/bin/bash

##
# Copyright IBM Corporation 2020
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
##

### Delete resources from previous installation if they exist
### As reference, see https://kubernetes.io/docs/tasks/administer-cluster/namespaces/#deleting-a-namespace
log "Deleting existing resources from previous runs..."
executeCommand "kubectl delete namespaces $NAMESPACE" true
executeCommand "kubectl delete clusterrolebinding $NAMESPACE" true

### Create k8s namespace for deployment
executeCommand "kubectl create namespace $NAMESPACE"

### Define pod security policy (psp)
(
cat <<EOF
apiVersion: policy/v1beta1
kind: PodSecurityPolicy
metadata:
  name: ibm-blockchain-platform-psp
spec:
  hostIPC: false
  hostNetwork: false
  hostPID: false
  privileged: true
  allowPrivilegeEscalation: true
  readOnlyRootFilesystem: false
  seLinux:
    rule: RunAsAny
  supplementalGroups:
    rule: RunAsAny
  runAsUser:
    rule: RunAsAny
  fsGroup:
    rule: RunAsAny
  requiredDropCapabilities:
  - ALL
  allowedCapabilities:
  - NET_BIND_SERVICE
  - CHOWN
  - DAC_OVERRIDE
  - SETGID
  - SETUID
  - FOWNER
  volumes:
  - '*'
EOF
)> ibp-psp.yaml

executeCommand "kubectl apply -f ibp-psp.yaml -n $NAMESPACE"

### Define cluster role
(
cat<<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  creationTimestamp: null
  name: $NAMESPACE
rules:
- apiGroups:
  - extensions
  resourceNames:
  - ibm-blockchain-platform-psp
  resources:
  - podsecuritypolicies
  verbs:
  - use
- apiGroups:
  - "*"
  resources:
  - pods
  - services
  - endpoints
  - persistentvolumeclaims
  - persistentvolumes
  - events
  - configmaps
  - secrets
  - ingresses
  - roles
  - rolebindings
  - serviceaccounts
  - nodes
  verbs:
  - '*'
- apiGroups:
  - apiextensions.k8s.io
  resources:
  - persistentvolumeclaims
  - persistentvolumes
  - customresourcedefinitions
  verbs:
  - '*'
- apiGroups:
  - ibp.com
  resources:
  - '*'
  - ibpservices
  - ibpcas
  - ibppeers
  - ibpfabproxies
  - ibporderers
  verbs:
  - '*'
- apiGroups:
  - ibp.com
  resources:
  - '*'
  verbs:
  - '*'
- apiGroups:
  - apps
  resources:
  - deployments
  - daemonsets
  - replicasets
  - statefulsets
  verbs:
  - '*'
EOF
)> ibp-clusterrole.yaml

executeCommand "kubectl apply -f ibp-clusterrole.yaml -n $NAMESPACE"

### Define cluster role binding
(
cat<<EOF
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: $NAMESPACE
subjects:
- kind: ServiceAccount
  name: default
  namespace: $NAMESPACE
roleRef:
  kind: ClusterRole
  name: $NAMESPACE
  apiGroup: rbac.authorization.k8s.io
EOF
)> ibp-clusterrolebinding.yaml

executeCommand "kubectl apply -f ibp-clusterrolebinding.yaml -n $NAMESPACE"
### If the ClusterRoleBinding is not created, the following error will occur when installing the IBP Console:
### error: unable to recognize "ibp-console.yaml": no matches for kind "IBPConsole" in version "ibp.com/v1alpha1"

### Create the role binding
executeCommand "kubectl -n $NAMESPACE create rolebinding ibp-operator-rolebinding --clusterrole=$NAMESPACE --group=system:serviceaccounts:$NAMESPACE"

### Create k8s secret for downloading IBP images
executeCommand "kubectl create secret docker-registry docker-key-secret --docker-server=$IMAGE_REGISTRY --docker-username=$IMAGE_REGISTRY_USER --docker-password=$IMAGE_REGISTRY_PASSWORD --docker-email=$EMAIL -n $NAMESPACE"

### Define deployment for IBP operator component
(
cat <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ibp-operator
  labels:
    release: "operator"
    helm.sh/chart: "ibm-ibp"
    app.kubernetes.io/name: "ibp"
    app.kubernetes.io/instance: "ibpoperator"
    app.kubernetes.io/managed-by: "ibp-operator"
spec:
  replicas: 1
  strategy:
    type: "Recreate"
  selector:
    matchLabels:
      name: ibp-operator
  template:
    metadata:
      labels:
        name: ibp-operator
        release: "operator"
        helm.sh/chart: "ibm-ibp"
        app.kubernetes.io/name: "ibp"
        app.kubernetes.io/instance: "ibpoperator"
        app.kubernetes.io/managed-by: "ibp-operator"
      annotations:
        productName: "IBM Blockchain Platform"
        productID: "54283fa24f1a4e8589964e6e92626ec4"
        productVersion: "2.1.2"
    spec:
      hostIPC: false
      hostNetwork: false
      hostPID: false
      serviceAccountName: default
      affinity:
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
            - matchExpressions:
              - key: beta.kubernetes.io/arch
                operator: In
                values:
                - amd64
      imagePullSecrets:
        - name: docker-key-secret
      containers:
        - name: ibp-operator
          image: $IMAGE_REGISTRY/$IMAGE_PREFIX/ibp-operator:2.1.2-20191217-amd64
          command:
          - ibp-operator
          imagePullPolicy: Always
          securityContext:
            privileged: false
            allowPrivilegeEscalation: false
            readOnlyRootFilesystem: false
            runAsNonRoot: false
            runAsUser: 1001
            capabilities:
              drop:
              - ALL
              add:
              - CHOWN
              - FOWNER
          livenessProbe:
            tcpSocket:
              port: 8383
            initialDelaySeconds: 10
            timeoutSeconds: 5
            failureThreshold: 5
          readinessProbe:
            tcpSocket:
              port: 8383
            initialDelaySeconds: 10
            timeoutSeconds: 5
            periodSeconds: 5
          env:
            - name: WATCH_NAMESPACE
              valueFrom:
                fieldRef:
                  fieldPath: metadata.namespace
            - name: POD_NAME
              valueFrom:
                fieldRef:
                  fieldPath: metadata.name
            - name: OPERATOR_NAME
              value: "ibp-operator"
            - name: CLUSTERTYPE
              value: "IKS"
          resources:
            requests:
              cpu: 100m
              memory: 200Mi
            limits:
              cpu: 100m
              memory: 200Mi
EOF
)> ibp-operator.yaml

executeCommand "kubectl apply -f ibp-operator.yaml -n $NAMESPACE"

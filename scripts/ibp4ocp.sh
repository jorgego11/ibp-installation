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

# For more info, see: https://cloud.ibm.com/docs/services/blockchain-rhos?topic=blockchain-rhos-deploy-ocp

# Log in to OpenShift cluster
executeCommand "$OC_LOGIN"

# Delete any resources from previous executions
log "Deleting existing resources from previous runs..."
executeCommand "oc delete project $OC_PROJECT_NAME" true
executeCommand "oc delete clusterrolebinding $OC_PROJECT_NAME" true

# Create new project
executeCommand "oc new-project $OC_PROJECT_NAME"
#executeCommand "oc get namespaces"
#executeCommand "oc get storageclasses"

# Define Security Context Constraint
(
cat <<EOF
allowHostDirVolumePlugin: true
allowHostIPC: true
allowHostNetwork: true
allowHostPID: true
allowHostPorts: true
allowPrivilegeEscalation: true
allowPrivilegedContainer: true
allowedCapabilities:
- NET_BIND_SERVICE
- CHOWN
- DAC_OVERRIDE
- SETGID
- SETUID
- FOWNER
apiVersion: security.openshift.io/v1
defaultAddCapabilities: null
fsGroup:
  type: RunAsAny
groups:
- system:cluster-admins
- system:authenticated
kind: SecurityContextConstraints
metadata:
  name: $OC_PROJECT_NAME
readOnlyRootFilesystem: false
requiredDropCapabilities: null
runAsUser:
  type: RunAsAny
seLinuxContext:
  type: RunAsAny
supplementalGroups:
  type: RunAsAny
volumes:
- "*"

EOF
)> ibp-scc.yaml

executeCommand "oc apply -f ibp-scc.yaml -n $OC_PROJECT_NAME"
executeCommand "oc adm policy add-scc-to-user $OC_PROJECT_NAME system:serviceaccounts:$OC_PROJECT_NAME"

# Define Cluster Role
(
cat<<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  creationTimestamp: null
  name: $OC_PROJECT_NAME
rules:
- apiGroups:
  - apiextensions.k8s.io
  resources:
  - persistentvolumeclaims
  - persistentvolumes
  - customresourcedefinitions
  verbs:
  - '*'
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
  - routes
  - routes/custom-host
  verbs:
  - '*'
- apiGroups:
  - ""
  resources:
  - namespaces
  - nodes
  verbs:
  - get
- apiGroups:
  - apps
  resources:
  - deployments
  - daemonsets
  - replicasets
  - statefulsets
  verbs:
  - '*'
- apiGroups:
  - monitoring.coreos.com
  resources:
  - servicemonitors
  verbs:
  - get
  - create
- apiGroups:
  - apps
  resourceNames:
  - ibp-operator
  resources:
  - deployments/finalizers
  verbs:
  - update
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
  - config.openshift.io
  resources:
  - '*'
  verbs:
  - '*'

EOF
)> ibp-clusterrole.yaml

executeCommand "oc apply -f ibp-clusterrole.yaml -n $OC_PROJECT_NAME"
executeCommand "oc adm policy add-scc-to-group $OC_PROJECT_NAME system:serviceaccounts:$OC_PROJECT_NAME"

# Define Cluster Role Binding
(
cat <<EOF
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: $OC_PROJECT_NAME
subjects:
- kind: ServiceAccount
  name: default
  namespace: $OC_PROJECT_NAME
roleRef:
  kind: ClusterRole
  name: $OC_PROJECT_NAME
  apiGroup: rbac.authorization.k8s.io

EOF
)> ibp-clusterrolebinding.yaml

executeCommand "oc apply -f ibp-clusterrolebinding.yaml -n $OC_PROJECT_NAME"
executeCommand "oc adm policy add-cluster-role-to-user $OC_PROJECT_NAME system:serviceaccounts:$OC_PROJECT_NAME"

### Create k8s secret for downloading IBP images
executeCommand "kubectl create secret docker-registry docker-key-secret --docker-server=$IMAGE_REGISTRY --docker-username=$IMAGE_REGISTRY_USER --docker-password=$IMAGE_REGISTRY_PASSWORD --docker-email=$EMAIL -n $OC_PROJECT_NAME"

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
              value: OPENSHIFT
          resources:
            requests:
              cpu: 100m
              memory: 200Mi
            limits:
              cpu: 100m
              memory: 200Mi

EOF
)> ibp-operator.yaml

executeCommand "kubectl apply -f ibp-operator.yaml -n $OC_PROJECT_NAME"

### Wait 35 seconds before continuing... the operator should be running on your namespace
### before you can apply the IBM Blockchain Platform console object.
log "Sleeping for 35 seconds... waiting for operator to settle."
sleep 35

### Define deployment for IBP console
(
cat<<EOF  
apiVersion: ibp.com/v1alpha1
kind: IBPConsole
metadata:
  name: ibpconsole
spec:
  license: accept
  serviceAccountName: default
  email: "$EMAIL"
  password: "$PASSWORD"
  registryURL: $IMAGE_REGISTRY/$IMAGE_PREFIX
  imagePullSecret: "docker-key-secret"
  networkinfo:
    domain: $DOMAIN
  storage:
    console:
      class: $STORAGE_CLASS
      size: 10Gi

EOF
)> ibp-console.yaml

executeCommand "kubectl apply -f ibp-console.yaml -n $OC_PROJECT_NAME"

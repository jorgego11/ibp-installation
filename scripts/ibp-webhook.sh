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

log "Deleting existing IBP webhook resources from previous runs..."
if [ "$PLATFORM" = "oc" ]
then
    executeCommand "oc delete crd ibpcas.ibp.com ibppeers.ibp.com ibporderers.ibp.com ibpconsoles.ibp.com" true
    executeCommand "oc delete project ibpinfra" true
else
    executeCommand "kubectl delete crd ibpcas.ibp.com ibppeers.ibp.com ibporderers.ibp.com ibpconsoles.ibp.com" true
    executeCommand "kubectl delete namespaces ibpinfra" true
fi

log "Sleeping for 60 seconds... waiting for old resources to be deleted."
sleep 60

if [ "$PLATFORM" = "oc" ]
then
    executeCommand "oc new-project ibpinfra"    
else
    executeCommand "kubectl create namespace ibpinfra"    
fi

executeCommand "kubectl create secret docker-registry docker-key-secret --docker-server=$IMAGE_REGISTRY --docker-username=$IMAGE_REGISTRY_USER --docker-password=$IMAGE_REGISTRY_PASSWORD --docker-email=$EMAIL -n ibpinfra"

### Configure role-based access control (RBAC) for the webhook
(
cat<<EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  name: webhook
  namespace: ibpinfra
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: webhook
rules:
- apiGroups:
  - "*"
  resources:
  - secrets
  verbs:
  - "*"
---
kind: RoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: ibpinfra
subjects:
- kind: ServiceAccount
  name: webhook
  namespace: ibpinfra
roleRef:
  kind: Role
  name: webhook
  apiGroup: rbac.authorization.k8s.io
EOF
)> ibp-webhook-rbac.yaml

executeCommand "kubectl apply -f ibp-webhook-rbac.yaml -n ibpinfra"

### (OpenShift cluster only) Apply the security context constraint (webhook)
if [ "$PLATFORM" = "oc" ]
then
(
cat<<EOF
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
  name: ibpinfra
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
)> ibp-webhook-scc.yaml

    executeCommand "oc apply -f ibp-webhook-scc.yaml -n ibpinfra"
    executeCommand "oc adm policy add-scc-to-user ibpinfra system:serviceaccounts:ibpinfra"
fi

### Deploy the webhook
(
cat<<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: "ibp-webhook"
  labels:
    helm.sh/chart: "ibm-ibp"
    app.kubernetes.io/name: "ibp"
    app.kubernetes.io/instance: "ibp-webhook"
spec:
  replicas: 1
  selector:
    matchLabels:
      app.kubernetes.io/instance: "ibp-webhook"
  strategy:
    rollingUpdate:
      maxSurge: 25%
      maxUnavailable: 25%
    type: RollingUpdate
  template:
    metadata:
      labels:
        helm.sh/chart: "ibm-ibp"
        app.kubernetes.io/name: "ibp"
        app.kubernetes.io/instance: "ibp-webhook"
      annotations:
        productName: "IBM Blockchain Platform"
        productID: "54283fa24f1a4e8589964e6e92626ec4"
        productVersion: "2.5.0"
    spec:
      serviceAccountName: webhook
      imagePullSecrets:
        - name: docker-key-secret
      hostIPC: false
      hostNetwork: false
      hostPID: false
      securityContext:
        runAsNonRoot: true
        runAsUser: 1000
        fsGroup: 2000
      containers:
        - name: "ibp-webhook"
          image: "$IMAGE_REGISTRY/$IMAGE_PREFIX/ibp-crdwebhook:2.5.0-20200714-$ARCHITECTURE"
          imagePullPolicy: Always
          securityContext:
            privileged: false
            allowPrivilegeEscalation: false
            readOnlyRootFilesystem: true
            runAsNonRoot: true
            runAsUser: 1000
            capabilities:
              drop:
              - ALL
              add:
              - NET_BIND_SERVICE
          env:
            - name: "LICENSE"
              value: "accept"
            - name: NAMESPACE
              valueFrom:
                fieldRef:
                  fieldPath: metadata.namespace
          ports:
            - name: server
              containerPort: 3000
          livenessProbe:
            httpGet:
              path: /healthz
              port: server
              scheme: HTTPS
            initialDelaySeconds: 30
            timeoutSeconds: 5
            failureThreshold: 6
          readinessProbe:
            httpGet:
              path: /healthz
              port: server
              scheme: HTTPS
            initialDelaySeconds: 26
            timeoutSeconds: 5
            periodSeconds: 5
          resources:
            requests:
              cpu: 0.1
              memory: "100Mi"
EOF
)> ibp-webhook-deployment.yaml

executeCommand "kubectl apply -f ibp-webhook-deployment.yaml -n ibpinfra"

### Deploy the service (webhook)
(
cat<<EOF
apiVersion: v1
kind: Service
metadata:
  name: "ibp-webhook"
  labels:
    type: "webhook"
    app.kubernetes.io/name: "ibp"
    app.kubernetes.io/instance: "ibp-webhook"
    helm.sh/chart: "ibm-ibp"
spec:
  type: ClusterIP
  ports:
    - name: server
      port: 443
      targetPort: server
      protocol: TCP
  selector:
    app.kubernetes.io/instance: "ibp-webhook"
EOF
)> ibp-webhook-service.yaml

executeCommand "kubectl apply -f ibp-webhook-service.yaml -n ibpinfra"

### Extract the certificate (webhook)

### Wait 35 seconds before continuing... otherwise, you may not find the secret
log "Sleeping for 35 seconds... waiting for webkook to settle."
sleep 35

WEBHOOK_CERT=`kubectl get secret webhook-tls-cert -n ibpinfra -o json | jq -r .data.\"cert.pem\"`
log "WEBHOOK_CERT is: $WEBHOOK_CERT"

### Create the CA custom resource definition (webhook)
(
cat<<EOF
apiVersion: apiextensions.k8s.io/v1beta1
kind: CustomResourceDefinition
metadata:
  labels:
    app.kubernetes.io/instance: ibpca
    app.kubernetes.io/managed-by: ibp-operator
    app.kubernetes.io/name: ibp
    helm.sh/chart: ibm-ibp
    release: operator
  name: ibpcas.ibp.com
spec:
  preserveUnknownFields: false
  conversion:
    strategy: Webhook
    webhookClientConfig:
      service:
        namespace: ibpinfra
        name: ibp-webhook
        path: /crdconvert
      caBundle: "$WEBHOOK_CERT"
  validation:
    openAPIV3Schema:
      x-kubernetes-preserve-unknown-fields: true    
  group: ibp.com
  names:
    kind: IBPCA
    listKind: IBPCAList
    plural: ibpcas
    singular: ibpca
  scope: Namespaced
  subresources:
    status: {}
  version: v1alpha2
  versions:
  - name: v1alpha2
    served: true
    storage: true
  - name: v210
    served: false
    storage: false
  - name: v212
    served: false
    storage: false
  - name: v1alpha1
    served: true
    storage: false
EOF
)> ibp-webhook-ibpca-crd.yaml

executeCommand "kubectl apply -f ibp-webhook-ibpca-crd.yaml"

### Create the peer custom resource definition (webhook)
(
cat<<EOF
apiVersion: apiextensions.k8s.io/v1beta1
kind: CustomResourceDefinition
metadata:
  name: ibppeers.ibp.com
  labels:
    release: "operator"
    helm.sh/chart: "ibm-ibp"
    app.kubernetes.io/name: "ibp"
    app.kubernetes.io/instance: "ibppeer"
    app.kubernetes.io/managed-by: "ibp-operator"
spec:
  preserveUnknownFields: false
  conversion:
    strategy: Webhook
    webhookClientConfig:
      service:
        namespace: ibpinfra
        name: ibp-webhook
        path: /crdconvert
      caBundle: "$WEBHOOK_CERT"
  validation:
    openAPIV3Schema:
      x-kubernetes-preserve-unknown-fields: true    
  group: ibp.com
  names:
    kind: IBPPeer
    listKind: IBPPeerList
    plural: ibppeers
    singular: ibppeer
  scope: Namespaced
  subresources:
    status: {}
  version: v1alpha2
  versions:
  - name: v1alpha2
    served: true
    storage: true
  - name: v1alpha1
    served: true
    storage: false
EOF
)> ibp-webhook-ibppeer-crd.yaml

executeCommand "kubectl apply -f ibp-webhook-ibppeer-crd.yaml"

### Create the orderer custom resource definition (webhook)

(
cat<<EOF
apiVersion: apiextensions.k8s.io/v1beta1
kind: CustomResourceDefinition
metadata:
  name: ibporderers.ibp.com
  labels:
    release: "operator"
    helm.sh/chart: "ibm-ibp"
    app.kubernetes.io/name: "ibp"
    app.kubernetes.io/instance: "ibporderer"
    app.kubernetes.io/managed-by: "ibp-operator"
spec:
  preserveUnknownFields: false
  conversion:
    strategy: Webhook
    webhookClientConfig:
      service:
        namespace: ibpinfra
        name: ibp-webhook
        path: /crdconvert
      caBundle: "$WEBHOOK_CERT"
  validation:
    openAPIV3Schema:
      x-kubernetes-preserve-unknown-fields: true    
  group: ibp.com
  names:
    kind: IBPOrderer
    listKind: IBPOrdererList
    plural: ibporderers
    singular: ibporderer
  scope: Namespaced
  subresources:
    status: {}
  version: v1alpha2
  versions:
  - name: v1alpha2
    served: true
    storage: true
  - name: v1alpha1
    served: true
    storage: false
EOF
)> ibp-webhook-ibporderer-crd.yaml

executeCommand "kubectl apply -f ibp-webhook-ibporderer-crd.yaml"

### Create the console custom resource definition (webhook)
(
cat<<EOF
apiVersion: apiextensions.k8s.io/v1beta1
kind: CustomResourceDefinition
metadata:
  name: ibpconsoles.ibp.com
  labels:
    release: "operator"
    helm.sh/chart: "ibm-ibp"
    app.kubernetes.io/name: "ibp"
    app.kubernetes.io/instance: "ibpconsole"
    app.kubernetes.io/managed-by: "ibp-operator"
spec:
  preserveUnknownFields: false
  conversion:
    strategy: Webhook
    webhookClientConfig:
      service:
        namespace: ibpinfra
        name: ibp-webhook
        path: /crdconvert
      caBundle: "$WEBHOOK_CERT"
  validation:
    openAPIV3Schema:
      x-kubernetes-preserve-unknown-fields: true
  group: ibp.com
  names:
    kind: IBPConsole
    listKind: IBPConsoleList
    plural: ibpconsoles
    singular: ibpconsole
  scope: Namespaced
  subresources:
    status: {}
  version: v1alpha2
  versions:
  - name: v1alpha2
    served: true
    storage: true
  - name: v1alpha1
    served: true
    storage: false
EOF
)> ibp-webhook-ibpconsole-crd.yaml

executeCommand "kubectl apply -f ibp-webhook-ibpconsole-crd.yaml"
#!/bin/bash

#
#  To run the script you need to create a configuration file and provide its path as an input parameter to this script.
#
#  See below for a description of rht configuration fields.
#     
#  IMAGE_REGISTRY_USER:
#    The user for the image registry.
#
#  IMAGE_REGISTRY
#    The server name for the image regisrtry.
#
#  IMAGE_REGISTRY_PASSWORD:
#    The password to the image registry.  
#    This is obtained by making a request in https://github.ibm.com/IBM-Blockchain/ibp-requests/blob/master/ibp-on-openshift/README.md. 
#
#  EMAIL:
#    The login email for the IBP Console.
#
#  NAMESPACE:
#    The name of your Kubernetes namespace.
#
#  PASSWORD:
#    The password you will use to login to your IBP Console.  You will have to immediately change this
#    upon your first login. 
#
#  DOMAIN:
#    The domain value for your cluster domain, which should resolve to the IP address that is the entry point to the cluster.
#
#  STORAGE_CLASS:
#    The name of the storage class that IBP should use.
#

function log {
    echo "[$(date +"%m-%d-%Y %r")]: $*"
}

function executeCommand {
  local command=$1
  local continueOnError=$2
  log "Executing: $command"
  output=$(bash -c '('"$command"'); exit $?' 2>&1)
  local retCode=$?
  log $output

  if (([ ! -z "$continueOnError" ] && [ "$continueOnError" = false ]) || [ -z "$continueOnError" ]) && [ $retCode -ne 0 ]
  then
    log "Exiting script due to fatal error (see above)."
    exit $retCode
  fi
}

CONFIG_FILE=$1

### Checks
if [ -z "$KUBECONFIG" ]
then
      log "KUBECONFIG is not set. Exiting script!"
      exit 1
else
      log "KUBECONFIG is set to: $KUBECONFIG"
fi

if [ -z "$CONFIG_FILE" ]
then
      log "CONFIG_FILE is not set. Exiting script!"
      exit 1
fi

log "Starting IBP installation process..."

log "CONFIG_FILE is: $CONFIG_FILE"

IMAGE_REGISTRY=`jq -r .IMAGE_REGISTRY "$CONFIG_FILE"`
log "IMAGE_REGISTRY is: $IMAGE_REGISTRY"

IMAGE_REGISTRY_USER=`jq -r .IMAGE_REGISTRY_USER "$CONFIG_FILE"`
log "IMAGE_REGISTRY_USER is: $IMAGE_REGISTRY_USER"

EMAIL=`jq -r .EMAIL "$CONFIG_FILE"`
log "EMAIL to use for the IBP console is: $EMAIL"

IMAGE_REGISTRY_PASSWORD=`jq -r .IMAGE_REGISTRY_PASSWORD "$CONFIG_FILE"`
#log "IMAGE_REGISTRY_PASSWORD entitlement key is: $IMAGE_REGISTRY_PASSWORD"

NAMESPACE=`jq -r .NAMESPACE "$CONFIG_FILE"`
log "NAMESPACE is: $NAMESPACE"

PASSWORD=`jq -r .PASSWORD "$CONFIG_FILE"`
log "IBP Console Password is: $PASSWORD"

DOMAIN=`jq -r .DOMAIN "$CONFIG_FILE"`
log "Domain is: $DOMAIN"

STORAGE_CLASS=`jq -r .STORAGE_CLASS "$CONFIG_FILE"`
log "Storage class is: $STORAGE_CLASS"

### Delete resources from previous installation if they exist
### As reference, see https://kubernetes.io/docs/tasks/administer-cluster/namespaces/#deleting-a-namespace
log "Deleting existing resources from previous runs..."
executeCommand "kubectl delete namespaces $NAMESPACE" true
executeCommand "kubectl delete clusterrolebinding $NAMESPACE" true

#### Start deployment
log "Starting IBP deployment...."

### Get pods and storageclasses
#kubectl get pods
#kubectl get storageclasses

### Create k8s namespace for deployment
executeCommand "kubectl create namespace $NAMESPACE"

### Define pod security policy (psp)
(
cat <<EOF
apiVersion: extensions/v1beta1
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
  name: ibp-operator
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
  name: ibp-operator
  apiGroup: rbac.authorization.k8s.io

EOF
)> ibp-clusterrolebinding.yaml

executeCommand "kubectl apply -f ibp-clusterrolebinding.yaml -n $NAMESPACE"
### If the ClusterRoleBinding is not created, the following error will occur when installing the IBP Console:
### error: unable to recognize "ibp-console.yaml": no matches for kind "IBPConsole" in version "ibp.com/v1alpha1"

### Create k8s secret for downloading IBP images
executeCommand "kubectl create secret docker-registry docker-key-secret --docker-server=$IMAGE_REGISTRY --docker-username=$IMAGE_REGISTRY_USER --docker-password=$IMAGE_REGISTRY_PASSWORD --docker-email=$EMAIL -n $NAMESPACE"
executeCommand "kubectl create secret docker-registry icr-secret --docker-server=us.icr.io --docker-username=iamapikey --docker-password=YPI_DL_6S1Pder6IsJCOLGD_16EFkJL3C0QIxRN8nEfx --docker-email=$EMAIL -n $NAMESPACE"

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
        productVersion: "2.1.0"
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
        - name: icr-secret
      containers:
        - name: ibp-operator
          image: us.icr.io/ibp-temp/ibp-operator:be2148e3-amd64
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
            - name: INGRESS_NEEDED
              value: "true"
          resources:
            requests:
              cpu: 100m
              memory: 200Mi
            limits:
              cpu: 100m
              memory: 200Mi

EOF
) > ibp-operator.yaml

executeCommand "kubectl apply -f ibp-operator.yaml -n $NAMESPACE"

### Wait 35 seconds before continuing... the operator should be running on your namespace
### before you can apply the IBM Blockchain Platform console object.
log "Sleeping for 35 seconds... waiting for operator to settle."
sleep 35

executeCommand "kubectl get deployment -n $NAMESPACE"

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
  image:
      imagePullSecret: docker-key-secret
      consoleInitImage: $IMAGE_REGISTRY/cp/ibp-init
      consoleInitTag: 2.1.0-20190924-amd64
      consoleImage: $IMAGE_REGISTRY/cp/ibp-console
      consoleTag: 2.1.0-20190924-amd64
      configtxlatorImage: $IMAGE_REGISTRY/cp/ibp-utilities
      configtxlatorTag: 1.4.3-20190924-amd64
      couchdbImage: $IMAGE_REGISTRY/cp/ibp-couchdb
      couchdbTag: 2.3.1-20190924-amd64
      deployerImage: $IMAGE_REGISTRY/cp/ibp-deployer
      deployerTag: 2.1.0-20190924-amd64
  versions:
      ca:
        1.4.3-0:
          default: true
          version: 1.4.3-0
          image:
            caInitImage: $IMAGE_REGISTRY/cp/ibp-ca-init
            caInitTag: 2.1.0-20190924-amd64
            caImage: $IMAGE_REGISTRY/cp/ibp-ca
            caTag: 1.4.3-20190924-amd64
      peer:
        1.4.3-0:
          default: true
          version: 1.4.3-0
          image:
            peerInitImage: $IMAGE_REGISTRY/cp/ibp-init
            peerInitTag: 2.1.0-20190924-amd64
            peerImage: $IMAGE_REGISTRY/cp/ibp-peer
            peerTag: 1.4.3-20190924-amd64
            dindImage: $IMAGE_REGISTRY/cp/ibp-dind
            dindTag: 1.4.3-20190924-amd64
            fluentdImage: $IMAGE_REGISTRY/cp/ibp-fluentd
            fluentdTag: 2.1.0-20190924-amd64
            grpcwebImage: $IMAGE_REGISTRY/cp/ibp-grpcweb
            grpcwebTag: 2.1.0-20190924-amd64
            couchdbImage: $IMAGE_REGISTRY/cp/ibp-couchdb
            couchdbTag: 2.3.1-20190924-amd64
      orderer:
        1.4.3-0:
          default: true
          version: 1.4.3-0
          image:
            ordererInitImage: $IMAGE_REGISTRY/cp/ibp-init
            ordererInitTag: 2.1.0-20190924-amd64
            ordererImage: $IMAGE_REGISTRY/cp/ibp-orderer
            ordererTag: 1.4.3-20190924-amd64
            grpcwebImage: $IMAGE_REGISTRY/cp/ibp-grpcweb
            grpcwebTag: 2.1.0-20190924-amd64
  networkinfo:
    domain: $DOMAIN
  storage:
    console:
      class: $STORAGE_CLASS
      size: 10Gi

EOF
) > ibp-console.yaml

executeCommand "kubectl apply -f ibp-console.yaml -n $NAMESPACE"

####
#### Ok...deployment is complete. Verifying the installation.
log "The installation is now complete!"
log "Note: It will take approximately 10 minutes for the IBP console to be available."
log "You can issue: kubectl get deployments -n $NAMESPACE"
log "When both the ibp-operator and ibpconsole are in the 'Available' state, you are ready to roll!"
log "To launch the IBP Console go to:"
log "https://$NAMESPACE-ibpconsole-console.$DOMAIN"

#kubectl get deployments -n $NAMESPACE
#kubectl get pods -n $NAMESPACE
#kubectl describe ibpconsole -n $NAMESPACE

exit 0

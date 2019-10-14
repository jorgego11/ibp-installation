#!/bin/bash

#
# To run the script you need to modify the: ibp4k8s.json 
# file located in this same directory.
#
#  A sample is shown below.  Some of the json data is filled in and some you must obtain.
#   
#  For the fields you need to obtain the value, here is where you get the information.
#     
#  USER:
#    THE user is the user name associated with your docker username.
#
#  EMAIL:
#    The email is used for two purposes.
#    The email that is used for the IBP Console login and used to obtain your local registry password. 
#
#  LOCAL_REGISTRY_PASSWORD:
#    The password to your local registry.  
#    This is obtained by making a request in https://github.ibm.com/IBM-Blockchain/ibp-requests/blob/master/ibp-on-openshift/README.md. 
#
#  NAMESPACE:
#    The name of your kubernetes namespace.
#
#  PASSWORD:
#    The password you will use to login to your IBP Console.  You will have to immediately change this
#    upon your first login. 
#
#  DOMAIN:
#    The name of your cluster domain.
#
#
# Sample ibp4k8s.json
# {
#"LOCAL_REGISTRY" : "ip-ibp-images-team-docker-remote.artifactory.swg-devops.com/cp",
#"USER" : "<USER>",
#"EMAIL" : "<EMAIL>",
#"LOCAL_REGISTRY_PASSWORD": "<LOCAL_REGISTRY_PASSWORD>",
#"NAMESPACE": "<NAMESPACE>",
#"PASSWORD": "<PASSWORD>",
#"DOMAIN": "<DOMAIN>"
# }

#### SET PARMS

# Exit if any command fails
set -e

function log {
    echo "[$(date -u)]: $*"
}

LOCAL_REGISTRY=`jq -r .LOCAL_REGISTRY ibp4k8s.json`
log "LOCAL_REGISTRY to be used is: $LOCAL_REGISTRY"

USER=`jq -r .USER ibp4k8s.json`
log "USER to run under is: $USER"

EMAIL=`jq -r .EMAIL ibp4k8s.json`
log "EMAIL to use for the IBP console is: $EMAIL"

LOCAL_REGISTRY_PASSWORD=`jq -r .LOCAL_REGISTRY_PASSWORD ibp4k8s.json`
#log "LOCAL_REGISTRY_PASSWORD entitlement key is: $LOCAL_REGISTRY_PASSWORD"

NAMESPACE=`jq -r .NAMESPACE ibp4k8s.json`
log "NAMESPACE is: $NAMESPACE"

PASSWORD=`jq -r .PASSWORD ibp4k8s.json`
log "IBP Console Password is: $PASSWORD"

DOMAIN=`jq -r .DOMAIN ibp4k8s.json`
log "Domain being used: $DOMAIN"

### Checks
if [ -z "$KUBECONFIG" ]
then
      log "KUBECONFIG is empty. Exiting script!"
      exit 1
else
      log "KUBECONFIG is set to: $KUBECONFIG"
fi

#https://kubernetes.io/docs/tasks/administer-cluster/namespaces/#deleting-a-namespace
kubectl delete namespaces $NAMESPACE
kubectl delete clusterrolebinding $NAMESPACE

#### Start deployment
log "Starting IBP deployment....\n"

### Get pods and storageclasses
### IKS free does not have any storageclasses by default?
kubectl get pods
kubectl get storageclasses
#output=$((kubectl get pods) 2>&1)
#log $output

### Create k8s namespace for deployment
kubectl create namespace $NAMESPACE

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

#kubectl apply -f ibp-psp.yaml -n $NAMESPACE | grep "created"
kubectl apply -f ibp-psp.yaml -n $NAMESPACE

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

kubectl apply -f ibp-clusterrole.yaml -n $NAMESPACE #| grep "created"

# Define service account
(
cat<<EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  name: default
EOF

)> ibp-serviceaccount.yaml

kubectl apply -f ibp-serviceaccount.yaml -n $NAMESPACE 

### Define role binding
kubectl -n $NAMESPACE create rolebinding ibp-operator-rolebinding --clusterrole=ibp-operator --group=system:serviceaccounts:$NAMESPACE

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

kubectl apply -f ibp-clusterrolebinding.yaml -n $NAMESPACE

### Create k8s secret for downloading IBP images
kubectl create secret docker-registry docker-key-secret --docker-server=$LOCAL_REGISTRY --docker-username=$USER --docker-password=$LOCAL_REGISTRY_PASSWORD --docker-email=$EMAIL -n $NAMESPACE

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
        - name: docker-key-secret
      containers:
        - name: ibp-operator
          image: $LOCAL_REGISTRY/cp/ibp-operator:2.1.0-20190924-amd64
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
            - name: ISOPENSHIFT
              value: "false"
          resources:
            requests:
              cpu: 100m
              memory: 200Mi
            limits:
              cpu: 100m
              memory: 200Mi

EOF
) > ibp-operator.yaml

kubectl apply -f ibp-operator.yaml -n $NAMESPACE

#kubectl describe pod -n $NAMESPACE

### Wait 15 seconds before continuing... the operator should be running on your namespace
### before you can apply the IBM Blockchain Platform console object.
log "Sleeping for 15 seconds..."
sleep 15

kubectl get deployment -n $NAMESPACE

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
      consoleInitImage: $LOCAL_REGISTRY/cp/ibp-init
      consoleInitTag: 2.1.0-20190924-amd64
      consoleImage: $LOCAL_REGISTRY/cp/ibp-console
      consoleTag: 2.1.0-20190924-amd64
      configtxlatorImage: $LOCAL_REGISTRY/cp/ibp-utilities
      configtxlatorTag: 1.4.3-20190924-amd64
      couchdbImage: $LOCAL_REGISTRY/cp/ibp-couchdb
      couchdbTag: 2.3.1-20190924-amd64
      deployerImage: $LOCAL_REGISTRY/cp/ibp-deployer
      deployerTag: 2.1.0-20190924-amd64
  versions:
      ca:
        1.4.3-0:
          default: true
          version: 1.4.3-0
          image:
            caInitImage: $LOCAL_REGISTRY/cp/ibp-ca-init
            caInitTag: 2.1.0-20190924-amd64
            caImage: $LOCAL_REGISTRY/cp/ibp-ca
            caTag: 1.4.3-20190924-amd64
      peer:
        1.4.3-0:
          default: true
          version: 1.4.3-0
          image:
            peerInitImage: $LOCAL_REGISTRY/cp/ibp-init
            peerInitTag: 2.1.0-20190924-amd64
            peerImage: $LOCAL_REGISTRY/cp/ibp-peer
            peerTag: 1.4.3-20190924-amd64
            dindImage: $LOCAL_REGISTRY/cp/ibp-dind
            dindTag: 1.4.3-20190924-amd64
            fluentdImage: $LOCAL_REGISTRY/cp/ibp-fluentd
            fluentdTag: 2.1.0-20190924-amd64
            grpcwebImage: $LOCAL_REGISTRY/cp/ibp-grpcweb
            grpcwebTag: 2.1.0-20190924-amd64
            couchdbImage: $LOCAL_REGISTRY/cp/ibp-couchdb
            couchdbTag: 2.3.1-20190924-amd64
      orderer:
        1.4.3-0:
          default: true
          version: 1.4.3-0
          image:
            ordererInitImage: $LOCAL_REGISTRY/cp/ibp-init
            ordererInitTag: 2.1.0-20190924-amd64
            ordererImage: $LOCAL_REGISTRY/cp/ibp-orderer
            ordererTag: 1.4.3-20190924-amd64
            grpcwebImage: $LOCAL_REGISTRY/cp/ibp-grpcweb
            grpcwebTag: 2.1.0-20190924-amd64
  networkinfo:
    consolePort: 30000
    proxyPort: 30001
    domain: 10.76.68.169
  storage:
    console:
      class: default
      size: 10Gi

EOF
) > ibp-console.yaml

kubectl apply -f ibp-console.yaml -n $NAMESPACE

####
#### Ok...deployment is complete.  Verifying the installation.
####

kubectl get deployments -n $NAMESPACE
#kubectl get deployment -n $NAMESPACE | grep "operator"
#kubectl get deployment -n $NAMESPACE | grep "console"
kubectl describe ibpconsole -n $NAMESPACE 

echo -e "\nThe installation is now complete!\n"
echo -e "Note: It will take approximately 10 minutes for the console to be available."
echo -e "      You can issue:"
echo -e "      kubectl get deployment -n $NAMESPACE"
echo -e "      and when both the ibp-operator and ibpconsole are in the 'Available' state, you are ready to roll!"
echo -e ""
echo  "To launch the IBP Console go to:"
echo -e "https://$NAMESPACE-ibpconsole-console.$DOMAIN:443"
echo -e ""

exit


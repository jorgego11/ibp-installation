#!/bin/bash
#
#
# To run the script you need to modify the: ibp4ocp.json 
# file located in this same directory.
#
#  A sample is shown below.  Some of the json data is filled in and some you must obtain.
#   
#  For the fields you need to obtain the value, here is where you get the information. 
#  LOGIN: 
#    Open the OpenShift web console. In the upper right corner of the cluster overview page, click OpenShift web console.
#    From the web console, click the dropdown menu in the upper right corner and then click Copy Login Command. Paste the copied command in your terminal window.
#    The command looks similar to the following example:
#    oc login cxxx-e.us-south.containers.cloud.ibm.com:31974 --token=xxxxxxx
#    ibp4ocp.json requires this the LOGIN key have a value of xxx-e.us-south.containers.cloud.ibm.com:31974 --token=xxxxxxx
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
#  PROJECT_NAME:
#    The name of your kubernetes project/namespace.
#
#  PASSWORD:
#    The password you will use to login to your IBP Console.  You will have to immediately change this
#    upon your first login. 
#
#  DOMAIN:
#    the name of your cluster domain. You can find this value by using the OpenShift web console. 
#    Use the dropdown menu next to OpenShift Container Platform at the top of the page to switch from 
#    Service Catalog to Cluster Console. Examine the url for that page. It will be similar to 
#    console.xyz.abc.com/k8s/cluster/projects. The value of the domain then would be xyz.abc.com, after 
#    removing console and /k8s/cluster/projects.
#
#
# Sample ibp4ocp.json
# {
#"LOGIN" : "<LOGIN>",
#"LOCAL_REGISTRY" : "ip-ibp-images-team-docker-remote.artifactory.swg-devops.com/cp",
#"USER" : "<USER>",
#"EMAIL" : "<EMAIL>",
#"LOCAL_REGISTRY_PASSWORD": "<LOCAL_REGISTRY_PASSWORD>",
#"PROJECT_NAME": "<PROJECT_NAME>",
#"PASSWORD": "<PASSWORD>",
#"DOMAIN": "<DOMAIN>"
# }

#### SET PARMS

# Exit when any command fails
#set -e

echo -e ""

LOGIN=`jq -r .LOGIN ibp4ocp.json`
echo -e "LOGIN environment: $LOGIN"

LOCAL_REGISTRY=`jq -r .LOCAL_REGISTRY ibp4ocp.json`
echo -e "LOCAL_REGISTRY to be used is: $LOCAL_REGISTRY"

USER=`jq -r .USER ibp4ocp.json`
echo -e "USER to run under is: $USER"

EMAIL=`jq -r .EMAIL ibp4ocp.json`
echo -e "EMAIL to use for the IBP console is: $EMAIL"

LOCAL_REGISTRY_PASSWORD=`jq -r .LOCAL_REGISTRY_PASSWORD ibp4ocp.json`
echo -e "LOCAL_REGISTRY_PASSWORD entitlement key is: $LOCAL_REGISTRY_PASSWORD"

PROJECT_NAME=`jq -r .PROJECT_NAME ibp4ocp.json`
echo -e "PROJECT_NAME is: $PROJECT_NAME"

PASSWORD=`jq -r .PASSWORD ibp4ocp.json`
echo -e "IBP Console Password is: $PASSWORD"

DOMAIN=`jq -r .DOMAIN ibp4ocp.json`
echo -e "OpenShift Domain being used: $DOMAIN"

#### START DEPLOYMENT

function checkrc {
  if [[ $? -ne 0 ]]; then
    echo "last call failed"
    exit 1
  fi
}


#

echo -e "Starting IBP Deployment....\n"
oc login https://$LOGIN | grep "Logged"
checkrc
#
oc get pods | grep "Running"
checkrc

kubectl get pods | grep "Running"
checkrc

oc new-project $PROJECT_NAME | grep "$PROJECT_NAME"
checkrc

oc get namespace | grep "$PROJECT_NAME"
checkrc

oc get storageclasses | grep "ibm"
checkrc

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
  name: $PROJECT_NAME
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

oc apply -f ibp-scc.yaml -n $PROJECT_NAME | grep "created"
checkrc

oc adm policy add-scc-to-user $PROJECT_NAME system:serviceaccounts:$PROJECT_NAME | grep "added"
checkrc

(
cat<<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  creationTimestamp: null
  name: $PROJECT_NAME
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

EOF
)> ibp-clusterrole.yaml

oc apply -f ibp-clusterrole.yaml -n $PROJECT_NAME | grep "created"
checkrc

oc adm policy add-scc-to-group $PROJECT_NAME system:serviceaccounts:$PROJECT_NAME | grep "added"
checkrc

(
cat <<EOF
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: $PROJECT_NAME
subjects:
- kind: ServiceAccount
  name: default
  namespace: $PROJECT_NAME
roleRef:
  kind: ClusterRole
  name: $PROJECT_NAME
  apiGroup: rbac.authorization.k8s.io

EOF
) > ibp-clusterrolebinding.yaml


oc apply -f ibp-clusterrolebinding.yaml -n $PROJECT_NAME | grep "created"
checkrc

oc adm policy add-cluster-role-to-user $PROJECT_NAME system:serviceaccounts:$PROJECT_NAME | grep "added"
checkrc

kubectl create secret docker-registry docker-key-secret --docker-server=$LOCAL_REGISTRY --docker-username=$USER --docker-password=$LOCAL_REGISTRY_PASSWORD --docker-email=$EMAIL -n $PROJECT_NAME | grep "created"
checkrc

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
          image: $LOCAL_REGISTRY/ibp-operator:2.1.0-20190924-amd64
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

kubectl apply -f ibp-operator.yaml -n $PROJECT_NAME | grep "created"
checkrc

kubectl get deployment -n $PROJECT_NAME | grep "ibp-operator"
checkrc

# wait 15 seconds before continuing... 
# the operator should be running on your namespace before you can apply a custom resource to start the IBM Blockchain Platform console on your cluster.
sleep 15

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
      consoleInitImage: $LOCAL_REGISTRY/ibp-init
      consoleInitTag: 2.1.0-20190924-amd64
      consoleImage: $LOCAL_REGISTRY/ibp-console
      consoleTag: 2.1.0-20190924-amd64
      configtxlatorImage: $LOCAL_REGISTRY/ibp-utilities
      configtxlatorTag: 1.4.3-20190924-amd64
      couchdbImage: $LOCAL_REGISTRY/ibp-couchdb
      couchdbTag: 2.3.1-20190924-amd64
      deployerImage: $LOCAL_REGISTRY/ibp-deployer
      deployerTag: 2.1.0-20190924-amd64
  versions:
      ca:
        1.4.3-0:
          default: true
          version: 1.4.3-0
          image:
            caInitImage: $LOCAL_REGISTRY/ibp-ca-init
            caInitTag: 2.1.0-20190924-amd64
            caImage: $LOCAL_REGISTRY/ibp-ca
            caTag: 1.4.3-20190924-amd64
      peer:
        1.4.3-0:
          default: true
          version: 1.4.3-0
          image:
            peerInitImage: $LOCAL_REGISTRY/ibp-init
            peerInitTag: 2.1.0-20190924-amd64
            peerImage: $LOCAL_REGISTRY/ibp-peer
            peerTag: 1.4.3-20190924-amd64
            dindImage: $LOCAL_REGISTRY/ibp-dind
            dindTag: 1.4.3-20190924-amd64
            fluentdImage: $LOCAL_REGISTRY/ibp-fluentd
            fluentdTag: 2.1.0-20190924-amd64
            grpcwebImage: $LOCAL_REGISTRY/ibp-grpcweb
            grpcwebTag: 2.1.0-20190924-amd64
            couchdbImage: $LOCAL_REGISTRY/ibp-couchdb
            couchdbTag: 2.3.1-20190924-amd64
      orderer:
        1.4.3-0:
          default: true
          version: 1.4.3-0
          image:
            ordererInitImage: $LOCAL_REGISTRY/ibp-init
            ordererInitTag: 2.1.0-20190924-amd64
            ordererImage: $LOCAL_REGISTRY/ibp-orderer
            ordererTag: 1.4.3-20190924-amd64
            grpcwebImage: $LOCAL_REGISTRY/ibp-grpcweb
            grpcwebTag: 2.1.0-20190924-amd64
  networkinfo:
    domain: $DOMAIN
  storage:
    console:
      class: default
      size: 10Gi

EOF
) > ibp-console.yaml

kubectl apply -f ibp-console.yaml -n $PROJECT_NAME | grep "created"
checkrc

####
#### Ok...deployment is complete.  Verifying the installation.
####

kubectl get deployment -n $PROJECT_NAME | grep "operator"
checkrc

kubectl get deployment -n $PROJECT_NAME | grep "console"
checkrc

echo -e "\nThe installation is now complete!\n"
echo -e "Note: It will take approximately 10 minutes for the console to be available."
echo -e "      You can issue:"
echo -e "      kubectl get deployment -n $PROJECT_NAME"
echo -e "      and when both the ibp-operator and ibpconsole are in the 'Available' state, you are ready to roll!"
echo -e ""
echo  "To launch the IBP Console go to:"
echo -e "https://$PROJECT_NAME-ibpconsole-console.$DOMAIN:443"
echo -e ""

exit

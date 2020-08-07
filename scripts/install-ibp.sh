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
#  IMAGE_PREFIX:
#    This is the prefix string that is part of the image name (e.g. cp).
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
#    If installing on OpenShift, see here for instructions on how to obtain this value:
#    https://cloud.ibm.com/docs/services/blockchain-rhos?topic=blockchain-rhos-deploy-ocp#deploy-ocp-console
#
#  STORAGE_CLASS:
#    The name of the storage class that IBP should use.
#
#  OC_LOGIN:
#    Only needed if deploying to an OpenShift environment.
#    The full command for logging usint the OpenShift command line. You can obtain this command by going to your OpenShift web console. 
#    In the upper right corner of the cluster overview page, click OpenShift web console.
#    From the web console, click the dropdown menu in the upper right corner and then click Copy Login Command. 
#    The command looks similar to the following example:
#    oc login https://cxxx-e.us-south.containers.cloud.ibm.com:31974 --token=xxxxxxx
#
#  OC_PROJECT_NAME:
#    Only needed if deploying to an OpenShift environment.
#    The name of the OpenShift project where IBP will be installed.
#
#  TLS_CERT:
#     Optional value. The absolute path to the TLS public certificate file.
#
#  TLS_KEY: 
#     Optional value. The absolute path to the TLS private key file.
#
#  ARCHITECTURE: 
#     Optional value. The default value is 'amd64'. Valid values are 'amd64' or 's390x'.
#

### Functions
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

function verifyRequisites {
    if [ -z "$PLATFORM" ]
    then
        log "PLATFORM is not set. Exiting script!"
        exit 1
    fi

    if [ -z "$CONFIG_FILE" ]
    then
        log "CONFIG_FILE is not set. Exiting script!"
        exit 1
    fi

    if [ "$PLATFORM" = "k8s" ] && ( [ -z "$KUBECONFIG" ] && [ ! -f "$KUBE_CONFIG_FILE" ] )
    then
        log "KUBECONFIG is not set and Kube config file does not exist. Exiting script!"
        exit 1
    elif [ "$PLATFORM" = "k8s" ]
    then
        log "KUBECONFIG is set to: $KUBECONFIG"
    fi
}

### Begin script execution
PLATFORM=$1
CONFIG_FILE=$2
KUBE_CONFIG_FILE=~/.kube/config

# Validate PLATFORM
if [ "$PLATFORM" = "k8s" ]
then
    PLATFORM_INSTALL_SCRIPT="ibp4k8s.sh"
elif [ "$PLATFORM" = "oc" ]
then
    PLATFORM_INSTALL_SCRIPT="ibp4ocp.sh"
else 
    log "PLATFORM is not valid: $PLATFORM. Exiting script!"
    exit 1
fi

# Verify expected conditions are met
verifyRequisites

# Configuration properties
log "CONFIG_FILE is: $CONFIG_FILE"

log "PLATFORM is: $PLATFORM"

log "PLATFORM_INSTALL_SCRIPT is: $PLATFORM_INSTALL_SCRIPT"

IMAGE_REGISTRY=`jq -r .IMAGE_REGISTRY "$CONFIG_FILE"`
log "IMAGE_REGISTRY is: $IMAGE_REGISTRY"

IMAGE_REGISTRY_USER=`jq -r .IMAGE_REGISTRY_USER "$CONFIG_FILE"`
log "IMAGE_REGISTRY_USER is: $IMAGE_REGISTRY_USER"

IMAGE_PREFIX=`jq -r .IMAGE_PREFIX "$CONFIG_FILE"`
log "IMAGE_PREFIX is: $IMAGE_PREFIX"

EMAIL=`jq -r .EMAIL "$CONFIG_FILE"`
log "EMAIL to use for the IBP console is: $EMAIL"

IMAGE_REGISTRY_PASSWORD=`jq -r .IMAGE_REGISTRY_PASSWORD "$CONFIG_FILE"`
#log "IMAGE_REGISTRY_PASSWORD entitlement key is: $IMAGE_REGISTRY_PASSWORD"

PASSWORD=`jq -r .PASSWORD "$CONFIG_FILE"`
log "IBP Console Password is: $PASSWORD"

DOMAIN=`jq -r .DOMAIN "$CONFIG_FILE"`
log "Domain is: $DOMAIN"

TLS_CERT=`jq -r .TLS_CERT "$CONFIG_FILE"`
if [ "$TLS_CERT" = "null" ]
then
  unset TLS_CERT
else 
  log "TLS certificate file is: $TLS_CERT"
fi

TLS_KEY=`jq -r .TLS_KEY "$CONFIG_FILE"`
if [ "$TLS_KEY" = "null" ]
then
  unset TLS_KEY
else
  log "TLS private key file is: $TLS_KEY"
fi

STORAGE_CLASS=`jq -r .STORAGE_CLASS "$CONFIG_FILE"`
log "Storage class is: $STORAGE_CLASS"

ARCHITECTURE=`jq -r .ARCHITECTURE "$CONFIG_FILE"`
if [ "$ARCHITECTURE" = "null" ]
then
  ARCHITECTURE='amd64'
fi
log "ARCHITECTURE is: $ARCHITECTURE"

if [ "$PLATFORM" = "oc" ]
then
    OC_LOGIN=`jq -r .OC_LOGIN "$CONFIG_FILE"`
    log "OC_LOGIN is: $OC_LOGIN"

    OC_PROJECT_NAME=`jq -r .OC_PROJECT_NAME "$CONFIG_FILE"`
    log "OC_PROJECT_NAME is: $OC_PROJECT_NAME"
    NAMESPACE=$OC_PROJECT_NAME
else
    NAMESPACE=`jq -r .NAMESPACE "$CONFIG_FILE"`
    log "NAMESPACE is: $NAMESPACE"
fi

# Being installation process
log "Starting IBP deployment..."

# Source webhook installation script
log "Installing IBP webhook..."
source "${BASH_SOURCE%/*}/ibp-webhook.sh"
log "Completed installation of IBP webhook."

# Source corresponding installation script based on PLATFORM
source "${BASH_SOURCE%/*}/$PLATFORM_INSTALL_SCRIPT"

### Wait 35 seconds before continuing... the operator should be running on your namespace
### before you can apply the IBM Blockchain Platform console object.
log "Sleeping for 35 seconds... waiting for operator to settle."
sleep 35

executeCommand "kubectl get deployment -n $NAMESPACE"

if [ ! -z "$TLS_CERT" ] && [ ! -z "$TLS_KEY" ]
then
    executeCommand "kubectl create secret generic console-tls-secret --from-file=tls.crt=$TLS_CERT --from-file=tls.key=$TLS_KEY -n $NAMESPACE"
fi

### Define deployment for IBP console
(
cat<<EOF
apiVersion: ibp.com/v1alpha2
kind: IBPConsole
metadata:
  name: ibpconsole
spec:
  arch:
  - $ARCHITECTURE
  license: accept
  serviceAccountName: default
  email: "$EMAIL"
  password: "$PASSWORD"
  registryURL: $IMAGE_REGISTRY/$IMAGE_PREFIX
  imagePullSecrets:
    - docker-key-secret
  networkinfo:
    domain: $DOMAIN
  storage:
    console:
      class: $STORAGE_CLASS
      size: 10Gi
EOF
)> ibp-console.yaml

if [ ! -z "$TLS_CERT" ] && [ ! -z "$TLS_KEY" ]
then
    (
cat<<EOF
  tlsSecretName: console-tls-secret
EOF
)>> ibp-console.yaml
fi

executeCommand "kubectl apply -f ibp-console.yaml -n $NAMESPACE"

### Deployment is now complete
log "IBP installation is now complete!"
log "Note: It may take approximately 10 minutes for the IBP console to be available."
log "You can issue: kubectl get deployments -n $NAMESPACE"
log "When both the ibp-operator and ibpconsole are in the 'Available' state, you are ready to roll!"
log "To launch the IBP Console go to:"
log "https://$NAMESPACE-ibpconsole-console.$DOMAIN"

#kubectl get deployments -n $NAMESPACE
#kubectl get pods -n $NAMESPACE
#kubectl describe ibpconsole -n $NAMESPACE

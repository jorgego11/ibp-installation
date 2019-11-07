#!/bin/bash

# Dowloands and tars up IBP images to your local file system

set -e

# Your credentials
IMAGE_REGISTRY_USER=ricardo.olivieri@us.ibm.com
IMAGE_REGISTRY_PASSWORD=<password>

# Images and tags
IBP_IMAGES1=(ibp-operator ibp-ca-init ibp-init ibp-console ibp-grpcweb ibp-fluentd ibp-deployer)
IBP_IMAGES_TAG1=2.1.0-20190924-amd64
IBP_IMAGES2=(ibp-couchdb)
IBP_IMAGES_TAG2=2.3.1-20190924-amd64
FABRIC_IMAGES=(ibp-peer ibp-ca ibp-orderer ibp-dind ibp-utilities ibp-ccenv ibp-nodeenv ibp-goenv)
FABRIC_IMAGES_TAG=1.4.3-20190924-amd64

# Registry
REGISTRY=ip-ibp-images-team-docker-remote.artifactory.swg-devops.com
REGISTRY_PATH=cp

echo ">> Logging to Docker image registry: $REGISTRY"
docker login ip-ibp-images-team-docker-remote.artifactory.swg-devops.com --username $IMAGE_REGISTRY_USER --password $IMAGE_REGISTRY_PASSWORD

function tarImage {
    local IMAGE=$1
    local TAG=$2
    echo ">> Pulling image: $IMAGE:$TAG"
    docker pull $REGISTRY/$REGISTRY_PATH/$IMAGE:$TAG
    docker save $REGISTRY/$REGISTRY_PATH/$IMAGE:$TAG > $IMAGE-$TAG.tar
    echo ">> Saved image to tar file: $IMAGE-$TAG.tar"
}

echo ">> About to download and tar main IBP images"
for IMAGE in "${IBP_IMAGES1[@]}"
do
	tarImage $IMAGE $IBP_IMAGES_TAG1
done

for IMAGE in "${IBP_IMAGES2[@]}"
do
	tarImage $IMAGE $IBP_IMAGES_TAG2
done
echo ">> Done downloading and tarring main IBP images"

echo ">> About to download and tar Fabric images"
for IMAGE in "${FABRIC_IMAGES[@]}"
do
	tarImage $IMAGE $FABRIC_IMAGES_TAG
done
echo ">> Done downloading and tarring Fabric images"

echo ">> Finished downloading and tarring IBP and Fabric images."

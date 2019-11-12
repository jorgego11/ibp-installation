#!/bin/bash

set -e

export API_KEY="<password>"

FILES="ibp-operator.tar.gz ibp-utilities.tar.gz ibp-ca-init.tar.gz ibp-ca.tar.gz ibp-console.tar.gz ibp-couchdb.tar.gz ibp-deployer.tar.gz ibp-fluentd.tar.gz ibp-grpcweb.tar.gz ibp-init.tar.gz ibp-orderer.tar.gz  ibp-peer.tar.gz ibp-dind.tar.gz"

for FILE in ${FILES}; do
    echo ">> Downloading: $FILE"
	curl -H X-JFrog-Art-Api:${API_KEY} -O "https://na.artifactory.swg-devops.com/artifactory/ccs-ibp-images-tar-team-generic-local/2.1.1-20191109/${FILE}"
done

# Load the images to ensure the tar balls are good
for FILE in ${FILES}; do
    echo ">> Loading image: $FILE"
	docker load -i ${FILE}
done

echo ">> Done!"

# In addition to the above images, there is one image (ibp-dind) that downloads three additional images (this of docker in docker)
# To test this, you can execute the following commands (this should execute the container which will then download the images inside the container):
#   docker run -ti -e LICENSE=accept --privileged cp.icr.io/cp/ibp-dind:1.4.3-20191108-amd64
# You should see output similar to this:
#   Loaded image: builder:latest
#   Loaded image: golangruntime:latest
#   ...
#   Loaded image: noderuntime:latest
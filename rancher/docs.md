
Using bare-metal system with Ubunutu 
On this system, we have docker
Then processed to install Rancher using the manual install option https://rancher.com/docs/rancher/v2.x/en/quick-start-guide/deployment/quickstart-manual-setup/

used the stable images instead of latest to avoid iusses:

$ sudo docker run -d --restart=unless-stopped -p 80:80 -p 443:443 rancher/rancher:stable

https://github.com/rancher/k3d/issues/67
https://github.com/rancher/local-path-provisioner
https://raw.githubusercontent.com/rancher/local-path-provisioner/master/deploy/local-path-storage.yaml
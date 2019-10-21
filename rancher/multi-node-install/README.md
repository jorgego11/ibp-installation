# Installing IBP on Rancher (multi node install)

The overall instructions for a Rancher multi node installation are found [here](https://rancher.com/docs/rancher/v2.x/en/installation/ha/).

The following are the steps I took for getting familiar with Rancher and installing IBP on it:

1) Provisioned three VMs running Ubuntu 18.04.3 (each VM should meet the software and hardware [requirements](https://rancher.com/docs/rancher/v2.x/en/installation/requirements/) for Rancher):

    ```
   ibmadmin@rancher-node2:~$ hostnamectl
        Static hostname: rancher-node2
              Icon name: computer-vm
                Chassis: vm
             Machine ID: 678bfd874cf449c3adaf84ef4df1280f
                Boot ID: 86058ea559894716ab796f15013ce6a0
         Virtualization: vmware
       Operating System: Ubuntu 18.04.3 LTS
                 Kernel: Linux 4.15.0-65-generic
           Architecture: x86-64
    ```

    Two of the VMs are used as nodes in the Kubernetes cluster and one is used as a load balancer that resides outside the Kubernetes cluster.

2) Once all VMs are provisioned, I set up my working station (e.g. macOS laptop) for quick SSH access to each one of the VMs. For details on how to do this, see [SSH-COPY-ID](https://www.ssh.com/ssh/copy-id). For those who may be new to using SSH, see [Connect to Linux from Mac OS X by using Terminal](https://support.rackspace.com/how-to/connecting-to-linux-from-mac-os-x-by-using-terminal/).

3) Installed Docker from Ubuntu repository on each one of the VMs that will function as nodes in the Kubernetes cluster (no need to install Docker on the load balancer machine). See [here](https://linuxconfig.org/how-to-install-docker-on-ubuntu-18-04-bionic-beaver) for instructions.

4) Granted access to user for running Docker commands (see [here](https://techoverflow.net/2017/03/01/solving-docker-permission-denied-while-trying-to-connect-to-the-docker-daemon-socket/) for instructions):

    ```
    $ sudo usermod -a -G docker $USER
    ```
5) Configured load balancer VM by installing nginx and configuring the firewall. For the firewall configuration, make sure you allow HTTP, HTTPS, and OpenSSH connections. For instructions, please see [here](https://www.digitalocean.com/community/tutorials/how-to-install-nginx-on-ubuntu-18-04). Also, as reference, see [How to setup the Nginx web server on Ubuntu 18.04 Bionic Beaver Linux](https://linuxconfig.org/how-to-setup-the-nginx-web-server-on-ubuntu-18-04-bionic-beaver-linux).

6) Created `nginx.conf` configuration file on load balancer VM. See Rancher [documentation](https://rancher.com/docs/rancher/v2.x/en/installation/ha/create-nodes-lb/nginx/) for details. Also as reference, see:
    * [nginx.conf](nginx/nginx.conf)
    * [unknown-directive-stream](https://serverfault.com/questions/858067/unknown-directive-stream-in-etc-nginx-nginx-conf86)
    * [How to reload and restart Nginx](https://help.dreamhost.com/hc/en-us/articles/216454967-How-to-reload-and-restart-Nginx-Dedicated-servers-only-)

7) Before proceeding with next steps, I ensured my SSH key had been added to the ssh-agent. See [here](https://help.github.com/en/github/authenticating-to-github/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent) for instructions.

8) Installed RKE on my workstation (e.g. macOS laptop). See [Download the RKE binary](https://rancher.com/docs/rke/latest/en/installation/#download-the-rke-binary) for instructions.

9) Created `rancher-cluster.yml` file and installed Kubernetes with RKE. See [here](https://rancher.com/docs/rancher/v2.x/en/installation/ha/kubernetes-rke/) for details. As reference, see [rancher-cluster.yml](rke-artifacts/rancher-cluster.yml).

    ```
    $ rke up --config ./rancher-cluster.yml --ssh-agent-auth
    ```

10) Followed instructions for [initializing Helm](https://rancher.com/docs/rancher/v2.x/en/installation/ha/helm-init/) and [installing Rancher](https://rancher.com/docs/rancher/v2.x/en/installation/ha/helm-rancher/) on the Kubernetes cluster. As part of the Rancher installation, for the SSL configuration, I used the `Rancher Generated Certificates` option (`ingress.tls.source=rancher`). See [here](https://rancher.com/docs/rancher/v2.x/en/installation/ha/helm-rancher/#choose-your-ssl-configuration) for further details.

11) Once Rancher was up and running (by now, you should have the `KUBECONFIG` environment variable set on your workstation), I added the [Local Path Provisioner](https://github.com/rancher/local-path-provisioner) as a storage class to the K8s cluster:

    ```
    $ kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/master/deploy/local-path-storage.yaml
    ```

8) Verified that the new storage class was available to the cluster:

    ```
    $ kubectl get storageclasses
    kubectl get storageclasses
    NAME         PROVISIONER             AGE
    local-path   rancher.io/local-path   4s
    ```

9) Finally, proceeded to install IBP on the cluster using the installation [script](../ibp4k8s.sh):
    * Updated storage class to `local-path` (instead of `default`).
    * Used the IP address/hostname assigned to the load balancer VM as the domain (proxy IP) value.

    ```
    $ kubectl get deployments -n ibp-installation-tst
    NAME           READY   UP-TO-DATE   AVAILABLE   AGE
    ibp-operator   1/1     1            1           56m
    ibpconsole     1/1     1            1           56m
    ```

10) Updated the firewall configuration on the load balancer VM to allow access to ports `30000` and `30001`:

    ```
    $ sudo ufw allow 30000
    $ sudo ufw allow 30001
    ```
    
    Also, updated the `nginx` [configuration](nginx/nginx.conf) so it can forward requests to ports `30000` and `30001` on each one of the worker nodes.

11) After updating the load balancer and verifying that both IBP deployments (i.e. `ibp-operator` and `ibpconsole`) were up and running on the cluster, I was able to access the IBP Console (`https://<load balancer IP>:30000`)... now, having issues with creating blockchain artifacts (e.g. peers, MSPs, CAs, etc.). Looking into this!

## Troubleshooting & tips
* [waiting for server-url issue](https://github.com/rancher/rancher/issues/16213)
* [NET::ERR_CERT_INVALID in Chrome](https://support.google.com/chrome/thread/9253301?hl=en)
* Ideally, the Kubernetes cluster where the Rancher application resides should only host Rancher application. This means that IBP, in theory, should not be installed on the same cluster where Rancher is running. A separate cluster should be created for IBP and any other applications. See following links for further details: 
    * https://rancher.com/docs/rancher/v2.x/en/installation/ha
    * https://rancher.com/docs/rancher/v2.x/en/installation/ha/create-nodes-lb/
* If your workstation is running the latest macOS version (i.e. Catalina), chances are you won't be able to access the IBP console running on the cluster because of certificates issue. This is a known problem and an [issue](https://github.ibm.com/IBM-Blockchain/blockchain-deployer/issues/2375) against IBP has been opened. As a workaround, you should access the IBP console from a different system (e.g. such as a VM running on your macOS).

## References
* [Ingress on Rancher](https://rancher.com/docs/rancher/v2.x/en/k8s-in-rancher/load-balancers-and-ingress/ingress/)
* [Ingress Controllers on Rancher](https://rancher.com/docs/rke/latest/en/config-options/add-ons/ingress-controllers/)
* [Removing Rancher](https://rancher.com/docs/rancher/v2.x/en/cluster-admin/cleaning-cluster-nodes/)
* [Why Rancher?](https://medium.com/faun/rancher-one-place-for-all-kubernetes-clusters-51586d72858a)
* [Kubernetes: One Cluster or Many?](https://content.pivotal.io/blog/kubernetes-one-cluster-or-many)
* [Sharing Host VPN with VirtualBox guest](https://gist.github.com/patrickdappollonio/a82632298ca1e4536a2da488d0542f08)
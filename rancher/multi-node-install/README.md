# Installing IBP on Rancher (multi node install)

The overall instructions for a Rancher multi node installation are found [here](https://rancher.com/docs/rancher/v2.x/en/installation/ha/).

The following are the steps I took for getting familiar with Rancher and installing IBP on it:

1) Provisioned four VMs running Ubuntu 18.04.3. Each VM that will function as a working node in the Kubernetes cluster should meet the software and hardware [requirements](https://rancher.com/docs/rancher/v2.x/en/installation/requirements/) for Rancher and IBP. Therefore, I provisioned VMs with 4 CPUs and 8 GB RAM.

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

    Three of the four VMs are used as nodes in the Kubernetes cluster, while the fourth VM is used as a load balancer (i.e. the entry point into the cluster). Please note that the load balancer resides outside the Kubernetes cluster.

2) Once all VMs are provisioned, I set up my working station (e.g. macOS laptop) for quick SSH access to each one of the VMs. For details on how to do this, see [SSH-COPY-ID](https://www.ssh.com/ssh/copy-id). For those who may be new to using SSH, see [Connect to Linux from Mac OS X by using Terminal](https://support.rackspace.com/how-to/connecting-to-linux-from-mac-os-x-by-using-terminal/).

3) Installed Docker from the Ubuntu repository on each one of the VMs that will function as **nodes** in the Kubernetes cluster (no need to install Docker on the load balancer machine). See [here](https://linuxconfig.org/how-to-install-docker-on-ubuntu-18-04-bionic-beaver) for instructions.

4) On each VM that will function as a node in the cluster, I granted access to non-root user for running Docker commands (see [here](https://techoverflow.net/2017/03/01/solving-docker-permission-denied-while-trying-to-connect-to-the-docker-daemon-socket/) for instructions):

    ```
    $ sudo usermod -a -G docker $USER
    ```

5) Configured the load balancer VM by installing `nginx` and configuring the firewall (`ufw`). For the firewall configuration, make sure you allow HTTP, HTTPS, and OpenSSH connections. For instructions, please see [here](https://www.digitalocean.com/community/tutorials/how-to-install-nginx-on-ubuntu-18-04). Also, as reference, see [How to setup the Nginx web server on Ubuntu 18.04 Bionic Beaver Linux](https://linuxconfig.org/how-to-setup-the-nginx-web-server-on-ubuntu-18-04-bionic-beaver-linux).

6) Created `nginx.conf` configuration file on the load balancer VM. See Rancher [documentation](https://rancher.com/docs/rancher/v2.x/en/installation/ha/create-nodes-lb/nginx/) for details. Also as reference, see:
    * [nginx.conf](nginx/nginx.conf)
    * [unknown-directive-stream](https://serverfault.com/questions/858067/unknown-directive-stream-in-etc-nginx-nginx-conf86)
    * [How to reload and restart Nginx](https://help.dreamhost.com/hc/en-us/articles/216454967-How-to-reload-and-restart-Nginx-Dedicated-servers-only-)

7) Before proceeding with next steps, I ensured my SSH key had been added to the ssh-agent; see [here](https://help.github.com/en/github/authenticating-to-github/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent) for instructions. Specifically, I made sure that my `~/.ssh/config` was updated accordingly.

8) Installed RKE on my workstation (macOS) using homebrew. See [Alternative RKE MacOS X Install - Homebrew](https://rancher.com/docs/rke/latest/en/installation/#alternative-rke-macos-x-install-homebrew) for instructions.

9) Created `rancher-cluster.yml` file and installed Kubernetes with RKE. See [here](https://rancher.com/docs/rancher/v2.x/en/installation/ha/kubernetes-rke/) for details. As reference, see [rancher-cluster.yml](rke-artifacts/rancher-cluster.yml).

    ```
    $ rke up --config ./rancher-cluster.yml --ssh-agent-auth
    ```

10) Set the `KUBECONFIG` environment variable set on my workstation to reference the newly created [kube_config_rancher-cluster.yml](rke-artifacts/kube_config_rancher-cluster.yml) file.

    ```
    export KUBECONFIG=$PWD/kube_config_rancher-cluster.yml
    ```

11) Followed instructions for [installing Rancher using Helm](https://rancher.com/docs/rancher/v2.x/en/installation/ha/helm-rancher/) on the Kubernetes cluster. Make sure you select the **stable** Helm chart repository. Also, as part of the Rancher installation, for the SSL configuration, I used the `Rancher Generated Certificates` option (`ingress.tls.source=rancher`). See [here](https://rancher.com/docs/rancher/v2.x/en/installation/ha/helm-rancher/#choose-your-ssl-configuration) for further details. Please note that you will need to install `cert-manager`. Finally, regarding the `hostname` argument for the Rancher installation, I used the hostname of the load balancer:

    ```
    helm install rancher rancher-stable/rancher \
        --namespace cattle-system \
        --set hostname=<load balancer hostname>
    ```

12) Before proceeding any further, verified that the state of created cluster was `Active` (the name Rancher assigns to this cluster is `local`). This may take up to 10 minutes. You can check the state of the cluster by visiting the Rancher web console, which should be found at `https://<load balancer hostname>`. If after waiting over 10 minutes the cluster is not active yet, then this workaround should do the trick: https://github.com/rancher/rancher/issues/16213#issuecomment-561851122

13) Once Rancher was up and running and the cluster was `Active`, I added the [Local Path Provisioner](https://github.com/rancher/local-path-provisioner) as a storage class to the K8s cluster:

    ```
    $ kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/master/deploy/local-path-storage.yaml
    ```

14) Verified that the new storage class was available to the Kubernetes cluster:

    ```
    $ kubectl get storageclasses
    kubectl get storageclasses
    NAME         PROVISIONER             AGE
    local-path   rancher.io/local-path   4s
    ```

15) Updated the `nginx` ingress controller to allow sending TLS connections directly to the backend instead of performing SSL termination itself. As reference, see [SSL Passthrough](https://kubernetes.github.io/ingress-nginx/user-guide/nginx-configuration/annotations/#ssl-passthrough). This update involves editing the nginx ingress controller by adding the `--enable-ssl-passthrough` argument to the `args` array.

    ```
    kubectl edit daemonset -n ingress-nginx nginx-ingress-controller
    ```

    Executing the above command, will launch your default editor so you can make the required change:

    ```
    ...

    - args:
        - /nginx-ingress-controller
        - --default-backend-service=$(POD_NAMESPACE)/default-http-backend
        - --configmap=$(POD_NAMESPACE)/nginx-configuration
        - --tcp-services-configmap=$(POD_NAMESPACE)/tcp-services
        - --udp-services-configmap=$(POD_NAMESPACE)/udp-services
        - --annotations-prefix=nginx.ingress.kubernetes.io
        - --enable-ssl-passthrough

    ...
    ```

16) Proceeded to install IBP on the cluster using the installation [script](../../k8s/ibp4k8s.sh) and a configuration file similar to this [one](../../k8sibp4k8s-2.json). Please note that the configuration file uses (among other configuration properties):

    * A storage class named `local-path`
    * A Kubernetes namespace value of `ibp` (you can use the namespace of your liking)
    * A domain value of `myibp.us`

    Please note that the domain value needs to resolve to the IP address of the load balancer VM. One way to do this is to register a domain entry in a public DNS server of your liking and mapping it to the IP address of the load balancer VM.

    To verify the status of the `ibp-operator` and `ibpconsole` components, you can issue the following command:

    ```
    $ kubectl get deployments -n ibp
    NAME           READY   UP-TO-DATE   AVAILABLE   AGE
    ibp-operator   1/1     1            1           56m
    ibpconsole     1/1     1            1           56m
    ```

17) After verifying that both IBP deployments, `ibp-operator` and `ibpconsole`, were up and running on the cluster, you should accept the self-signed certificates for these components using your browser. For example:

    * https://ibp-ibpconsole-console.myibp.us
    * https://ibp-ibpconsole-proxy.myibp.us

18) Once you have accepted the self-signed certificates, you should be able to access the IBP Console (e.g. `https://ibp-ibpconsole-console.myibp.us`) and start creating Fabric nodes and assets.

## Troubleshooting & tips
* [waiting for server-url issue](https://github.com/rancher/rancher/issues/16213)
* [NET::ERR_CERT_INVALID in Chrome](https://support.google.com/chrome/thread/9253301?hl=en)
* Ideally, the Kubernetes cluster where the Rancher application resides should only host Rancher application. This means that IBP, in theory, should not be installed on the same cluster where Rancher is running. A separate cluster should be created for IBP and any other applications. See following links for further details: 
    * https://rancher.com/docs/rancher/v2.x/en/installation/ha
    * https://rancher.com/docs/rancher/v2.x/en/installation/ha/create-nodes-lb/
* If your workstation is running the latest macOS version (i.e. Catalina), chances are you won't be able to access the IBP console running on the cluster if using IBP's self-signed certificates. This is a known problem and an [issue](https://github.ibm.com/IBM-Blockchain/blockchain-deployer/issues/2375) against IBP has been opened. As a workaround, you should access the IBP console from a different system (e.g. such as a VM running on your macOS).

## References
* [Ingress on Rancher](https://rancher.com/docs/rancher/v2.x/en/k8s-in-rancher/load-balancers-and-ingress/ingress/)
* [Ingress Controllers on Rancher](https://rancher.com/docs/rke/latest/en/config-options/add-ons/ingress-controllers/)
* [Removing Rancher](https://rancher.com/docs/rancher/v2.x/en/cluster-admin/cleaning-cluster-nodes/) - The main takeaways from the procedure for uninstalling Rancher is that you need to perform the following steps on each one of the worker nodes in the K8s cluster: 
    1. [Remove docker containers, images, and volumes](https://rancher.com/docs/rancher/v2.x/en/cluster-admin/cleaning-cluster-nodes/#docker-containers-images-and-volumes)
    1. [Remove mounts from the system](https://rancher.com/docs/rancher/v2.x/en/cluster-admin/cleaning-cluster-nodes/#mounts)
    1. Reboot the worker node
    1. [Remove folders and files](https://rancher.com/docs/rancher/v2.x/en/cluster-admin/cleaning-cluster-nodes/#directories-and-files)

* [Why Rancher?](https://medium.com/faun/rancher-one-place-for-all-kubernetes-clusters-51586d72858a)
* [Kubernetes: One Cluster or Many?](https://content.pivotal.io/blog/kubernetes-one-cluster-or-many)
* [Sharing Host VPN with VirtualBox guest](https://gist.github.com/patrickdappollonio/a82632298ca1e4536a2da488d0542f08)
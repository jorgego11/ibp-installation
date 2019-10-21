# Installing IBP on Rancher (single node install)
The following are the steps I took for getting familiar with Rancher and installing IBP on it:

1) A bare-metal system running Ubuntu 18.04.3: 

    ```
    $ hostnamectl
    Static hostname: kubeslave
            Icon name: computer-laptop
            Chassis: laptop
            Machine ID: f6f0c98e338647d1aae1c5bc83570ddf
            Boot ID: 38754b3e2c794486b7441bc3227c4ec6
    Operating System: Ubuntu 18.04.3 LTS
                Kernel: Linux 4.15.0-65-generic
        Architecture: x86-64

    ```

Please note that instead of using a bare-metal machine, you can provision a VM on the IBM Cloud that meets the software and hardware [requirements](https://rancher.com/docs/rancher/v2.x/en/installation/requirements/) for Rancher (to save our organization a few bucks, I used a spare Linux laptop for the installation instead of provisioning a VM on the cloud).

2) Installed Docker on the Ubuntu system:

    ```
    $ docker version
    Client:
    Version:           18.09.7
    API version:       1.39
    Go version:        go1.10.1
    Git commit:        2d0083d
    Built:             Fri Aug 16 14:20:06 2019
    OS/Arch:           linux/amd64
    Experimental:      false

    Server:
    Engine:
    Version:          18.09.7
    API version:      1.39 (minimum version 1.12)
    Go version:       go1.10.1
    Git commit:       2d0083d
    Built:            Wed Aug 14 19:41:23 2019
    OS/Arch:          linux/amd64
    Experimental:     false
    ```

3) Updated networking settings. Specifically, I had to define a DHCP reservation policy to ensure the same IP address is assigned by my home router to the single worker/master node (not doing this caused problems the first time I tried to install Rancher). For further details, see:

    * [Node requirements](https://rancher.com/docs/rancher/v2.x/en/installation/requirements/)
    * [How do I reserve an IP address on my NETGEAR router?](https://kb.netgear.com/25722/How-do-I-reserve-an-IP-address-on-my-NETGEAR-router)

4) Installed Rancher using the manual install option (see [Manual Quick Start](https://rancher.com/docs/rancher/v2.x/en/quick-start-guide/deployment/quickstart-manual-setup/)). I used the stable image instead of latest to avoid any surprises:

    ```
    $ sudo docker run -d --restart=unless-stopped -p 8080:80 -p 8443:443 rancher/rancher:stable
    ```

5) Once rancher was installed, I created a **custom** Kubernetes cluster using Rancher's UI (see [here](https://rancher.com/docs/rancher/v2.x/en/quick-start-guide/deployment/quickstart-manual-setup/#3-log-in) for instructions).

6) Downloaded from the Rancher UI the Kubernetes config file and [for the cluster], saved it (`~/.kube/config`), and set the `KUBECONFIG` environment variable to point to this file.

7) Once Kubernetes cluster was up and running, you can check that by default there are not any storage classes available:

    ```
    $ kubectl get storageclasses
    No resources found in default namespace.
    ```

    Therefore, I added the [Local Path Provisioner](https://github.com/rancher/local-path-provisioner) as a storage class to the K8s cluster:

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

9) Finally, proceeded to install IBP using the installation [script](ibp4k8s.sh) in this folder:
    * Updated storage class to `local-path` (instead of `default`).
    * Used the IP address assigned to the worker node as the domain (proxy IP) value (in theory, we would instead use a proxy IP address/domain).

    ```
    $ kubectl get deployments -n ibp-installation-tst
    NAME           READY   UP-TO-DATE   AVAILABLE   AGE
    ibp-operator   1/1     1            1           56m
    ibpconsole     1/1     1            1           56m
    ```

10) After both deployments (i.e. ibp-operator and ibpconsole) were up and running on the cluster, I was able to access the IBP Console and successfully created several blockchain artifacts (e.g. peers, MSPs, CAs, etc.).

## Tips
* If you run into an error similar to "`[etcd] Failed to bring up Etcd Plane: [etcd] Etcd Cluster is not healthy`" while re-creating a cluster on Rancher, follow the steps outlined [here](https://github.com/rancher/rancher/issues/19882#issuecomment-501056386) to clean up your environment.

## Observations
* If nothing changes, I can make a few minor enhancements to the installation script so we can use the same script for installing IBP on IKS and also on a Rancher environment.
* Following the Ingress example instructions did not quite work for their hello-world example: https://rancher.com/docs/rancher/v2.x/en/quick-start-guide/workload/. Issues related to this problem:
    * https://github.com/rancher/rancher/issues/13351 
    * https://github.com/rancher/rancher/issues/14960
* Ingress and Rancher - According to the Rancher docs, a Rancher cluster should have an nginx ingress controller by default; see following links for more details:
    * https://rancher.com/docs/rancher/v2.x/en/k8s-in-rancher/load-balancers-and-ingress/
    * https://rancher.com/docs/rancher/v2.x/en/k8s-in-rancher/load-balancers-and-ingress/ingress/
# Installing IBP on Rancher
The following are the steps I took for getting familiar with Rancher and installing IBP on Kubernetes cluster that was provisioned using Rancher:

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

3) Updated Ubuntu system to ensure it meets networking requirements. Specifically, had to define DHCP reservation policy to ensure the same IP address is assigned by my router to the single worker/master node (not doing this caused problems the first time I tried to install Rancher). For further details, see:

    * [Node requirements](https://rancher.com/docs/rancher/v2.x/en/installation/requirements/)
    * [How do I reserve an IP address on my NETGEAR router?](https://kb.netgear.com/25722/How-do-I-reserve-an-IP-address-on-my-NETGEAR-router)

4) Installed Rancher using the manual install option; see [Manual Quick Start](https://rancher.com/docs/rancher/v2.x/en/quick-start-guide/deployment/quickstart-manual-setup/). I used the stable image instead of latest to avoid any surprises:

```
$ sudo docker run -d --restart=unless-stopped -p 80:80 -p 443:443 rancher/rancher:stable
```

5) Once rancher was installed, created Kubernetes cluster using Rancher's UI. See [here](https://rancher.com/docs/rancher/v2.x/en/quick-start-guide/deployment/quickstart-manual-setup/#3-log-in) for instructions.

6) Once Kubernetes cluster was up and running, you can check that by default there are not any storage classes available:

```
$ kubectl get storageclasses
```

Therefore, added the [Local Path Provisioner](https://github.com/rancher/local-path-provisioner) as a storage class to the cluster:

```
kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/master/deploy/local-path-storage.yaml
```

7) Verified that the new storage class was available to the cluster

```
$ kubectl get storageclasses
kubectl get storageclasses
NAME         PROVISIONER             AGE
local-path   rancher.io/local-path   52m
```

8) Finally, proceeded to install IBP using the script:
    * Updated storage class to `local-path` (instead of `default`).
    * Used the IP address assigned to the worker node as the domain (proxy IP) value. - THIS IS NOT THE RIGHT WAY THOUGH!
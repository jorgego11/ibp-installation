
Using bare-metal system with Ubunutu 


```
ibm@kubeslave:~/workspace/ibp/ibp-installation/rancher$ hostnamectl
   Static hostname: kubeslave
         Icon name: computer-laptop
           Chassis: laptop
        Machine ID: f6f0c98e338647d1aae1c5bc83570ddf
           Boot ID: 38754b3e2c794486b7441bc3227c4ec6
  Operating System: Ubuntu 18.04.3 LTS
            Kernel: Linux 4.15.0-65-generic
      Architecture: x86-64
ibm@kubeslave:~/workspace/ibp/ibp-installation/ranche
```



On this system, we have docker


```
 sudo docker version
[sudo] password for ibm: 
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
ibm@kubeslave:~/workspace/ibp/ibp-installation/rancher$ 
```

Before installing rancher, ensured my ubntu server met etworking requirments. especifically, had to define DHCP retention plociy to ensure the same IP is assigned by my router (not doing this caused problems the first time). See:


rancher.com/docs/rancher/v2.x/en/installation/requirements/
https://kb.netgear.com/25722/How-do-I-reserve-an-IP-address-on-my-NETGEAR-router

Then processed to install Rancher using the manual install option https://rancher.com/docs/rancher/v2.x/en/quick-start-guide/deployment/quickstart-manual-setup/

used the stable images instead of latest to avoid iusses:

$ sudo docker run -d --restart=unless-stopped -p 80:80 -p 443:443 rancher/rancher:stable

Once rancher was installed, created cluster using Ranchers UI.
Once cluster was up and running.... added sotage class optoin

https://github.com/rancher/k3d/issues/67
https://github.com/rancher/local-path-provisioner
https://raw.githubusercontent.com/rancher/local-path-provisioner/master/deploy/local-path-storage.yaml
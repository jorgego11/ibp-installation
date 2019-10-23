# IKS

Of course, if you intend to use IBP on the IBM Cloud for a client engagement, you should simply leverage IBP SaaS on the IBM Cloud. The instructions here are just for educational purposes: IBP installation on a Kubernetes environment provided by a cloud provider (e.g. IBM Cloud).

To install IBP on IKS (paid cluster), you should first determine the Ingress subdomain value that is assigned to your cluster. This value is your IP proxy value for the IBP Console installation. Please note that after provisioning your IKS cluster, it may take a few minutes to get an Ingress sub-domain assigned:

```
$ ibmcloud ks cluster get --cluster mycluster-ibp | grep Ingress
Ingress Subdomain:              -   
Ingress Secret:                 -   
```

After a few minutes (or sooner), the ingress domain should show up:

```
$ ibmcloud ks cluster get --cluster mycluster-ibp | grep Ingress
Ingress Subdomain:              mycluster-ibp.us-south.containers.appdomain.cloud   
Ingress Secret:                 mycluster-ibp   
```

```
$ ibmcloud ks cluster ls
OK
Name            ID                     State    Created          Workers   Location   Version       Resource Group Name    Provider   
mycluster       bmgfkped0vi1a9dqv8pg   normal   2 days ago       1         Dallas     1.14.7_1534   default-resource-grp   classic   
mycluster-ibp   bmiblrdd020jcujp0e80   normal   42 minutes ago   3         Dallas     1.14.7_1534   default-resource-grp   classic   

$ ibmcloud ks cluster get --cluster mycluster-ibp
Retrieving cluster mycluster-ibp...
OK
                                   
Name:                           mycluster-ibp   
ID:                             bmiblrdd020jcujp0e80   
State:                          normal   
Created:                        2019-10-14T18:15:11+0000   
Location:                       dal10   
Master URL:                     https://c7.us-south.containers.cloud.ibm.com:25190   
Public Service Endpoint URL:    https://c7.us-south.containers.cloud.ibm.com:25190   
Private Service Endpoint URL:   -   
Master Location:                Dallas   
Master Status:                  Ready (22 minutes ago)   
Master State:                   deployed   
Master Health:                  normal   
Ingress Subdomain:              mycluster-ibp.us-south.containers.appdomain.cloud   
Ingress Secret:                 mycluster-ibp   
Workers:                        3   
Worker Zones:                   dal10   
Version:                        1.14.7_1534   
Creator:                        roliv@us.ibm.com   
Monitoring Dashboard:           -   
Resource Group ID:              78344685da6948d98b9289c738f13886   
Resource Group Name:            default-resource-grp   
```
## References

* https://cloud.ibm.com/docs/containers?topic=containers-ingress#public_inside_2
* https://cloud.ibm.com/docs/containers?topic=containers-cs_troubleshoot_network
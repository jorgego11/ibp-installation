See: https://cloud.ibm.com/docs/containers?topic=containers-ingress#public_inside_2

```
Ricardos-MacBook-Pro-9:ibp-installation olivieri$ ibmcloud ks cluster ls
OK
Name            ID                     State    Created          Workers   Location   Version       Resource Group Name    Provider   
mycluster       bmgfkped0vi1a9dqv8pg   normal   2 days ago       1         Dallas     1.14.7_1534   default-resource-grp   classic   
mycluster-ibp   bmiblrdd020jcujp0e80   normal   42 minutes ago   3         Dallas     1.14.7_1534   default-resource-grp   classic   
Ricardos-MacBook-Pro-9:ibp-installation olivieri$ ibmcloud ks cluster get --cluster mycluster-ibp
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
Ricardos-MacBook-Pro-9:ibp-installation olivieri$ 
```
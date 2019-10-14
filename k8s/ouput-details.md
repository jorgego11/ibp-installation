
```
$ kubectl get deployments -n $NAMESPACE
NAME           READY   UP-TO-DATE   AVAILABLE   AGE
ibp-operator   1/1     1            1           15m
ibpconsole     0/1     1            0           15m
$ kubectl get pods -n $NAMESPACE
NAME                           READY   STATUS    RESTARTS   AGE
ibp-operator-899c5f7b9-687c9   1/1     Running   0          14m
ibpconsole-54d8647f99-5f87k    0/4     Pending   0          14m

```

```
$ kubectl describe deployment ibpconsole -n $NAMESPACE
Name:               ibpconsole
Namespace:          ibp-installation-test
CreationTimestamp:  Mon, 14 Oct 2019 11:24:14 -0400
Labels:             app=ibpconsole
                    app.kubernetes.io/instance=ibpconsole
                    app.kubernetes.io/managed-by=ibp-operator
                    app.kubernetes.io/name=ibp
                    creator=ibp
                    helm.sh/chart=ibm-ibp
                    release=operator
Annotations:        deployment.kubernetes.io/revision: 1
Selector:           app=ibpconsole
Replicas:           1 desired | 1 updated | 1 total | 0 available | 1 unavailable
StrategyType:       Recreate
MinReadySeconds:    0
Pod Template:
  Labels:           app=ibpconsole
                    app.kubernetes.io/instance=ibpconsole
                    app.kubernetes.io/managed-by=ibp-operator
                    app.kubernetes.io/name=ibp
                    creator=ibp
                    helm.sh/chart=ibm-ibp
                    release=operator
  Annotations:      productID: 54283fa24f1a4e8589964e6e92626ec4
                    productName: IBM Blockchain Platform
                    productVersion: 2.1.0
  Service Account:  default
  Init Containers:
   init:
    Image:      ip-ibp-images-team-docker-remote.artifactory.swg-devops.com/cp/ibp-init:2.1.0-20190924-amd64
    Port:       <none>
    Host Port:  <none>
    Environment:
      LICENSE:              accept
      TYPE:                 console
      PERMISSIONS_UID:      5984
      PERMISSIONS_GID:      0
      PERMISSIONS_FOLDERS:  /opt/couchdb/data/
    Mounts:
      /opt/couchdb/data from couchdb (rw,path="data")
   initcerts:
    Image:      ip-ibp-images-team-docker-remote.artifactory.swg-devops.com/cp/ibp-init:2.1.0-20190924-amd64
    Port:       <none>
    Host Port:  <none>
    Environment:
      LICENSE:              accept
      TYPE:                 console
      PERMISSIONS_UID:      1000
      PERMISSIONS_GID:      0
      PERMISSIONS_FOLDERS:  /certs/
    Mounts:
      /certs from couchdb (rw,path="tls")
  Containers:
   optools:
    Image:       ip-ibp-images-team-docker-remote.artifactory.swg-devops.com/cp/ibp-console:2.1.0-20190924-amd64
    Ports:       3000/TCP, 3001/TCP
    Host Ports:  0/TCP, 0/TCP
    Limits:
      cpu:     500m
      memory:  1000Mi
    Requests:
      cpu:      500m
      memory:   1000Mi
    Liveness:   tcp-socket :3000 delay=60s timeout=5s period=10s #success=1 #failure=5
    Readiness:  tcp-socket :3000 delay=55s timeout=5s period=5s #success=1 #failure=3
    Environment Variables from:
      ibpconsole-configmap  ConfigMap  Optional: false
    Environment:
      LICENSE:                        accept
      DEFAULT_USER_PASSWORD_INITIAL:  <set to the key 'password' in secret 'ibpconsole-console-pw'>  Optional: false
    Mounts:
      /certs/ from couchdb (rw,path="tls")
      /template/ from template (rw)
   deployer:
    Image:      ip-ibp-images-team-docker-remote.artifactory.swg-devops.com/cp/ibp-deployer:2.1.0-20190924-amd64
    Port:       8080/TCP
    Host Port:  0/TCP
    Limits:
      cpu:     100m
      memory:  200Mi
    Requests:
      cpu:      100m
      memory:   200Mi
    Liveness:   tcp-socket :8080 delay=16s timeout=5s period=10s #success=1 #failure=5
    Readiness:  tcp-socket :8080 delay=10s timeout=5s period=5s #success=1 #failure=3
    Environment:
      LICENSE:           accept
      CONFIGPATH:        /deployer/settings.yaml
      DEPLOY_NAMESPACE:   (v1:metadata.namespace)
    Mounts:
      /deployer/ from deployer-template (rw)
   configtxlator:
    Image:      ip-ibp-images-team-docker-remote.artifactory.swg-devops.com/cp/ibp-utilities:1.4.3-20190924-amd64
    Port:       8083/TCP
    Host Port:  0/TCP
    Command:
      sh
      -c
      configtxlator start --port=8083 --CORS=*
    Limits:
      cpu:     25m
      memory:  50Mi
    Requests:
      cpu:      25m
      memory:   50Mi
    Liveness:   tcp-socket :8083 delay=16s timeout=5s period=10s #success=1 #failure=5
    Readiness:  tcp-socket :8083 delay=10s timeout=5s period=5s #success=1 #failure=3
    Environment:
      LICENSE:  accept
    Mounts:     <none>
   couchdb:
    Image:      ip-ibp-images-team-docker-remote.artifactory.swg-devops.com/cp/ibp-couchdb:2.3.1-20190924-amd64
    Port:       5984/TCP
    Host Port:  0/TCP
    Command:
      sh
      -c
      /opt/couchdb/bin/couchdb
    Limits:
      cpu:     500m
      memory:  1000Mi
    Requests:
      cpu:      500m
      memory:   1000Mi
    Liveness:   tcp-socket :5984 delay=16s timeout=5s period=10s #success=1 #failure=5
    Readiness:  tcp-socket :5984 delay=10s timeout=5s period=5s #success=1 #failure=3
    Environment:
      LICENSE:  accept
    Mounts:
      /opt/couchdb/data from couchdb (rw,path="data")
  Volumes:
   couchdb:
    Type:       PersistentVolumeClaim (a reference to a PersistentVolumeClaim in the same namespace)
    ClaimName:  ibpconsole-pvc
    ReadOnly:   false
   deployer-template:
    Type:      ConfigMap (a volume populated by a ConfigMap)
    Name:      ibpconsole-deployer-template
    Optional:  false
   template:
    Type:      ConfigMap (a volume populated by a ConfigMap)
    Name:      ibpconsole-template-configmap
    Optional:  false
Conditions:
  Type           Status  Reason
  ----           ------  ------
  Available      False   MinimumReplicasUnavailable
  Progressing    False   ProgressDeadlineExceeded
OldReplicaSets:  ibpconsole-54d8647f99 (1/1 replicas created)
NewReplicaSet:   <none>
Events:
  Type    Reason             Age   From                   Message
  ----    ------             ----  ----                   -------
  Normal  ScalingReplicaSet  16m   deployment-controller  Scaled up replica set ibpconsole-54d8647f99 to 1
```


```
$ kubectl describe pod ibpconsole-54d8647f99-5f87k -n $NAMESPACE
Name:           ibpconsole-54d8647f99-5f87k
Namespace:      ibp-installation-test
Priority:       0
Node:           <none>
Labels:         app=ibpconsole
                app.kubernetes.io/instance=ibpconsole
                app.kubernetes.io/managed-by=ibp-operator
                app.kubernetes.io/name=ibp
                creator=ibp
                helm.sh/chart=ibm-ibp
                pod-template-hash=54d8647f99
                release=operator
Annotations:    kubernetes.io/psp: ibm-blockchain-platform-psp
                productID: 54283fa24f1a4e8589964e6e92626ec4
                productName: IBM Blockchain Platform
                productVersion: 2.1.0
Status:         Pending
IP:             
Controlled By:  ReplicaSet/ibpconsole-54d8647f99
Init Containers:
  init:
    Image:      ip-ibp-images-team-docker-remote.artifactory.swg-devops.com/cp/ibp-init:2.1.0-20190924-amd64
    Port:       <none>
    Host Port:  <none>
    Environment:
      LICENSE:              accept
      TYPE:                 console
      PERMISSIONS_UID:      5984
      PERMISSIONS_GID:      0
      PERMISSIONS_FOLDERS:  /opt/couchdb/data/
    Mounts:
      /opt/couchdb/data from couchdb (rw,path="data")
      /var/run/secrets/kubernetes.io/serviceaccount from default-token-tf4xc (ro)
  initcerts:
    Image:      ip-ibp-images-team-docker-remote.artifactory.swg-devops.com/cp/ibp-init:2.1.0-20190924-amd64
    Port:       <none>
    Host Port:  <none>
    Environment:
      LICENSE:              accept
      TYPE:                 console
      PERMISSIONS_UID:      1000
      PERMISSIONS_GID:      0
      PERMISSIONS_FOLDERS:  /certs/
    Mounts:
      /certs from couchdb (rw,path="tls")
      /var/run/secrets/kubernetes.io/serviceaccount from default-token-tf4xc (ro)
Containers:
  optools:
    Image:       ip-ibp-images-team-docker-remote.artifactory.swg-devops.com/cp/ibp-console:2.1.0-20190924-amd64
    Ports:       3000/TCP, 3001/TCP
    Host Ports:  0/TCP, 0/TCP
    Limits:
      cpu:     500m
      memory:  1000Mi
    Requests:
      cpu:      500m
      memory:   1000Mi
    Liveness:   tcp-socket :3000 delay=60s timeout=5s period=10s #success=1 #failure=5
    Readiness:  tcp-socket :3000 delay=55s timeout=5s period=5s #success=1 #failure=3
    Environment Variables from:
      ibpconsole-configmap  ConfigMap  Optional: false
    Environment:
      LICENSE:                        accept
      DEFAULT_USER_PASSWORD_INITIAL:  <set to the key 'password' in secret 'ibpconsole-console-pw'>  Optional: false
    Mounts:
      /certs/ from couchdb (rw,path="tls")
      /template/ from template (rw)
      /var/run/secrets/kubernetes.io/serviceaccount from default-token-tf4xc (ro)
  deployer:
    Image:      ip-ibp-images-team-docker-remote.artifactory.swg-devops.com/cp/ibp-deployer:2.1.0-20190924-amd64
    Port:       8080/TCP
    Host Port:  0/TCP
    Limits:
      cpu:     100m
      memory:  200Mi
    Requests:
      cpu:      100m
      memory:   200Mi
    Liveness:   tcp-socket :8080 delay=16s timeout=5s period=10s #success=1 #failure=5
    Readiness:  tcp-socket :8080 delay=10s timeout=5s period=5s #success=1 #failure=3
    Environment:
      LICENSE:           accept
      CONFIGPATH:        /deployer/settings.yaml
      DEPLOY_NAMESPACE:  ibp-installation-test (v1:metadata.namespace)
    Mounts:
      /deployer/ from deployer-template (rw)
      /var/run/secrets/kubernetes.io/serviceaccount from default-token-tf4xc (ro)
  configtxlator:
    Image:      ip-ibp-images-team-docker-remote.artifactory.swg-devops.com/cp/ibp-utilities:1.4.3-20190924-amd64
    Port:       8083/TCP
    Host Port:  0/TCP
    Command:
      sh
      -c
      configtxlator start --port=8083 --CORS=*
    Limits:
      cpu:     25m
      memory:  50Mi
    Requests:
      cpu:      25m
      memory:   50Mi
    Liveness:   tcp-socket :8083 delay=16s timeout=5s period=10s #success=1 #failure=5
    Readiness:  tcp-socket :8083 delay=10s timeout=5s period=5s #success=1 #failure=3
    Environment:
      LICENSE:  accept
    Mounts:
      /var/run/secrets/kubernetes.io/serviceaccount from default-token-tf4xc (ro)
  couchdb:
    Image:      ip-ibp-images-team-docker-remote.artifactory.swg-devops.com/cp/ibp-couchdb:2.3.1-20190924-amd64
    Port:       5984/TCP
    Host Port:  0/TCP
    Command:
      sh
      -c
      /opt/couchdb/bin/couchdb
    Limits:
      cpu:     500m
      memory:  1000Mi
    Requests:
      cpu:      500m
      memory:   1000Mi
    Liveness:   tcp-socket :5984 delay=16s timeout=5s period=10s #success=1 #failure=5
    Readiness:  tcp-socket :5984 delay=10s timeout=5s period=5s #success=1 #failure=3
    Environment:
      LICENSE:  accept
    Mounts:
      /opt/couchdb/data from couchdb (rw,path="data")
      /var/run/secrets/kubernetes.io/serviceaccount from default-token-tf4xc (ro)
Conditions:
  Type           Status
  PodScheduled   False 
Volumes:
  couchdb:
    Type:       PersistentVolumeClaim (a reference to a PersistentVolumeClaim in the same namespace)
    ClaimName:  ibpconsole-pvc
    ReadOnly:   false
  deployer-template:
    Type:      ConfigMap (a volume populated by a ConfigMap)
    Name:      ibpconsole-deployer-template
    Optional:  false
  template:
    Type:      ConfigMap (a volume populated by a ConfigMap)
    Name:      ibpconsole-template-configmap
    Optional:  false
  default-token-tf4xc:
    Type:        Secret (a volume populated by a Secret)
    SecretName:  default-token-tf4xc
    Optional:    false
QoS Class:       Guaranteed
Node-Selectors:  <none>
Tolerations:     node.kubernetes.io/not-ready:NoExecute for 600s
                 node.kubernetes.io/unreachable:NoExecute for 600s
Events:
  Type     Reason            Age                 From               Message
  ----     ------            ----                ----               -------
  Warning  FailedScheduling  20s (x13 over 17m)  default-scheduler  0/1 nodes are available: 1 Insufficient memory.
Ricardos-MacBook-Pro-9:k8s olivieri$ 
````

```
Ricardos-MacBook-Pro-9:k8s olivieri$ kubectl logs ibpconsole-54d8647f99-5f87k -c deployer -n $NAMESPACE
Ricardos-MacBook-Pro-9:k8s olivieri$ kubectl logs ibpconsole-54d8647f99-5f87k -c optools -n $NAMESPACE
Ricardos-MacBook-Pro-9:k8s olivieri$ kubectl logs ibpconsole-54d8647f99-5f87k -c configtxlator -n $NAMESPACE
Ricardos-MacBook-Pro-9:k8s olivieri$ kubectl logs ibpconsole-54d8647f99-5f87k -c couchdb -n $NAMESPACE
```

```
$ kubectl get deployments -n $NAMESPACE
NAME           READY   UP-TO-DATE   AVAILABLE   AGE
ibp-operator   1/1     1            1           10m
ibpconsole     1/1     1            1           10m

$ kubectl get pods -n $NAMESPACE
NAME                           READY   STATUS    RESTARTS   AGE
ibp-operator-899c5f7b9-wbprn   1/1     Running   1          11m
ibpconsole-54d8647f99-g2g95    4/4     Running   0          10m

```

```
$ $ kubectl describe deployment ibpconsole -n $NAMESPACE
Name:               ibpconsole
Namespace:          ibp-installation-test
CreationTimestamp:  Mon, 14 Oct 2019 15:03:26 -0400
Labels:             app=ibpconsole
                    app.kubernetes.io/instance=ibpconsole
                    app.kubernetes.io/managed-by=ibp-operator
                    app.kubernetes.io/name=ibp
                    creator=ibp
                    helm.sh/chart=ibm-ibp
                    release=operator
Annotations:        deployment.kubernetes.io/revision: 1
Selector:           app=ibpconsole
Replicas:           1 desired | 1 updated | 1 total | 1 available | 0 unavailable
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
  Available      True    MinimumReplicasAvailable
  Progressing    True    NewReplicaSetAvailable
OldReplicaSets:  ibpconsole-54d8647f99 (1/1 replicas created)
NewReplicaSet:   <none>
Events:
  Type    Reason             Age   From                   Message
  ----    ------             ----  ----                   -------
  Normal  ScalingReplicaSet  11m   deployment-controller  Scaled up replica set ibpconsole-54d8647f99 to 1
```

```
$ kubectl describe pod ibpconsole-54d8647f99-g2g95 -n $NAMESPACE
Name:           ibpconsole-54d8647f99-g2g95
Namespace:      ibp-installation-test
Priority:       0
Node:           10.95.244.59/10.95.244.59
Start Time:     Mon, 14 Oct 2019 15:06:11 -0400
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
Status:         Running
IP:             172.30.150.66
Controlled By:  ReplicaSet/ibpconsole-54d8647f99
Init Containers:
  init:
    Container ID:   containerd://669bece6e454c378c46242f031231b9b0bdb38b91c639572560907c21aa3f033
    Image:          ip-ibp-images-team-docker-remote.artifactory.swg-devops.com/cp/ibp-init:2.1.0-20190924-amd64
    Image ID:       ip-ibp-images-team-docker-remote.artifactory.swg-devops.com/cp/ibp-init@sha256:0358b200d8a81dd66d048d8b7376ddbe2bf8d87b623f887246aa9e5bcc20c02d
    Port:           <none>
    Host Port:      <none>
    State:          Terminated
      Reason:       Completed
      Exit Code:    0
      Started:      Mon, 14 Oct 2019 15:06:35 -0400
      Finished:     Mon, 14 Oct 2019 15:06:35 -0400
    Ready:          True
    Restart Count:  0
    Environment:
      LICENSE:              accept
      TYPE:                 console
      PERMISSIONS_UID:      5984
      PERMISSIONS_GID:      0
      PERMISSIONS_FOLDERS:  /opt/couchdb/data/
    Mounts:
      /opt/couchdb/data from couchdb (rw,path="data")
      /var/run/secrets/kubernetes.io/serviceaccount from default-token-l8g9h (ro)
  initcerts:
    Container ID:   containerd://0eec24b4fa6be1f68a063cfb826b95995e88fb52149e3d6f64dc06b900d1abc4
    Image:          ip-ibp-images-team-docker-remote.artifactory.swg-devops.com/cp/ibp-init:2.1.0-20190924-amd64
    Image ID:       ip-ibp-images-team-docker-remote.artifactory.swg-devops.com/cp/ibp-init@sha256:0358b200d8a81dd66d048d8b7376ddbe2bf8d87b623f887246aa9e5bcc20c02d
    Port:           <none>
    Host Port:      <none>
    State:          Terminated
      Reason:       Completed
      Exit Code:    0
      Started:      Mon, 14 Oct 2019 15:06:37 -0400
      Finished:     Mon, 14 Oct 2019 15:06:37 -0400
    Ready:          True
    Restart Count:  0
    Environment:
      LICENSE:              accept
      TYPE:                 console
      PERMISSIONS_UID:      1000
      PERMISSIONS_GID:      0
      PERMISSIONS_FOLDERS:  /certs/
    Mounts:
      /certs from couchdb (rw,path="tls")
      /var/run/secrets/kubernetes.io/serviceaccount from default-token-l8g9h (ro)
Containers:
  optools:
    Container ID:   containerd://2707f37714e4629cb16da8676279b0cae552b209eb921c7bfc106189ea628383
    Image:          ip-ibp-images-team-docker-remote.artifactory.swg-devops.com/cp/ibp-console:2.1.0-20190924-amd64
    Image ID:       ip-ibp-images-team-docker-remote.artifactory.swg-devops.com/cp/ibp-console@sha256:b0d3d71121abcf83a56626284780df4accc20f26b1c1d05c1e0146d599b04c91
    Ports:          3000/TCP, 3001/TCP
    Host Ports:     0/TCP, 0/TCP
    State:          Running
      Started:      Mon, 14 Oct 2019 15:07:05 -0400
    Ready:          True
    Restart Count:  0
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
      /var/run/secrets/kubernetes.io/serviceaccount from default-token-l8g9h (ro)
  deployer:
    Container ID:   containerd://93b4654e8569ac1deb5742c61dff4d180ca78d5a19f69d15cb628740e257b838
    Image:          ip-ibp-images-team-docker-remote.artifactory.swg-devops.com/cp/ibp-deployer:2.1.0-20190924-amd64
    Image ID:       ip-ibp-images-team-docker-remote.artifactory.swg-devops.com/cp/ibp-deployer@sha256:8af4abb2f2ee026395924c2ba198b4299a8813923cd8c56c30b3d912b85da490
    Port:           8080/TCP
    Host Port:      0/TCP
    State:          Running
      Started:      Mon, 14 Oct 2019 15:07:14 -0400
    Ready:          True
    Restart Count:  0
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
      /var/run/secrets/kubernetes.io/serviceaccount from default-token-l8g9h (ro)
  configtxlator:
    Container ID:  containerd://f22161d125aa051a643460e03cfebc99921f39f556a0c018ffb9c2dc689ebe0d
    Image:         ip-ibp-images-team-docker-remote.artifactory.swg-devops.com/cp/ibp-utilities:1.4.3-20190924-amd64
    Image ID:      ip-ibp-images-team-docker-remote.artifactory.swg-devops.com/cp/ibp-utilities@sha256:23744adb2f64a2c65ad1065b7784b19d02d2c0f5415726211f4f8f01809106aa
    Port:          8083/TCP
    Host Port:     0/TCP
    Command:
      sh
      -c
      configtxlator start --port=8083 --CORS=*
    State:          Running
      Started:      Mon, 14 Oct 2019 15:07:34 -0400
    Ready:          True
    Restart Count:  0
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
      /var/run/secrets/kubernetes.io/serviceaccount from default-token-l8g9h (ro)
  couchdb:
    Container ID:  containerd://be57be49a44348286954b289f18a95b881fa74be008567793419d32e81f97547
    Image:         ip-ibp-images-team-docker-remote.artifactory.swg-devops.com/cp/ibp-couchdb:2.3.1-20190924-amd64
    Image ID:      ip-ibp-images-team-docker-remote.artifactory.swg-devops.com/cp/ibp-couchdb@sha256:7f597924f26929bd737ec2710b6502e02b60b806e96258a587a5e7d20a49bf1b
    Port:          5984/TCP
    Host Port:     0/TCP
    Command:
      sh
      -c
      /opt/couchdb/bin/couchdb
    State:          Running
      Started:      Mon, 14 Oct 2019 15:07:45 -0400
    Ready:          True
    Restart Count:  0
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
      /var/run/secrets/kubernetes.io/serviceaccount from default-token-l8g9h (ro)
Conditions:
  Type              Status
  Initialized       True 
  Ready             True 
  ContainersReady   True 
  PodScheduled      True 
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
  default-token-l8g9h:
    Type:        Secret (a volume populated by a Secret)
    SecretName:  default-token-l8g9h
    Optional:    false
QoS Class:       Guaranteed
Node-Selectors:  <none>
Tolerations:     node.kubernetes.io/not-ready:NoExecute for 600s
                 node.kubernetes.io/unreachable:NoExecute for 600s
Events:
  Type     Reason            Age                From                   Message
  ----     ------            ----               ----                   -------
  Warning  FailedScheduling  11m (x3 over 14m)  default-scheduler      pod has unbound immediate PersistentVolumeClaims (repeated 3 times)
  Normal   Scheduled         11m                default-scheduler      Successfully assigned ibp-installation-test/ibpconsole-54d8647f99-g2g95 to 10.95.244.59
  Normal   Pulling           11m                kubelet, 10.95.244.59  Pulling image "ip-ibp-images-team-docker-remote.artifactory.swg-devops.com/cp/ibp-init:2.1.0-20190924-amd64"
  Normal   Pulled            11m                kubelet, 10.95.244.59  Successfully pulled image "ip-ibp-images-team-docker-remote.artifactory.swg-devops.com/cp/ibp-init:2.1.0-20190924-amd64"
  Normal   Created           11m                kubelet, 10.95.244.59  Created container init
  Normal   Started           11m                kubelet, 10.95.244.59  Started container init
  Normal   Pulling           11m                kubelet, 10.95.244.59  Pulling image "ip-ibp-images-team-docker-remote.artifactory.swg-devops.com/cp/ibp-init:2.1.0-20190924-amd64"
  Normal   Pulled            11m                kubelet, 10.95.244.59  Successfully pulled image "ip-ibp-images-team-docker-remote.artifactory.swg-devops.com/cp/ibp-init:2.1.0-20190924-amd64"
  Normal   Created           11m                kubelet, 10.95.244.59  Created container initcerts
  Normal   Started           11m                kubelet, 10.95.244.59  Started container initcerts
  Normal   Pulling           11m                kubelet, 10.95.244.59  Pulling image "ip-ibp-images-team-docker-remote.artifactory.swg-devops.com/cp/ibp-console:2.1.0-20190924-amd64"
  Normal   Pulled            11m                kubelet, 10.95.244.59  Successfully pulled image "ip-ibp-images-team-docker-remote.artifactory.swg-devops.com/cp/ibp-console:2.1.0-20190924-amd64"
  Normal   Created           11m                kubelet, 10.95.244.59  Created container optools
  Normal   Pulling           10m                kubelet, 10.95.244.59  Pulling image "ip-ibp-images-team-docker-remote.artifactory.swg-devops.com/cp/ibp-deployer:2.1.0-20190924-amd64"
  Normal   Started           10m                kubelet, 10.95.244.59  Started container optools
  Normal   Pulled            10m                kubelet, 10.95.244.59  Successfully pulled image "ip-ibp-images-team-docker-remote.artifactory.swg-devops.com/cp/ibp-deployer:2.1.0-20190924-amd64"
  Normal   Created           10m                kubelet, 10.95.244.59  Created container deployer
  Normal   Started           10m                kubelet, 10.95.244.59  Started container deployer
  Normal   Pulling           10m                kubelet, 10.95.244.59  Pulling image "ip-ibp-images-team-docker-remote.artifactory.swg-devops.com/cp/ibp-utilities:1.4.3-20190924-amd64"
  Normal   Pulled            10m                kubelet, 10.95.244.59  Successfully pulled image "ip-ibp-images-team-docker-remote.artifactory.swg-devops.com/cp/ibp-utilities:1.4.3-20190924-amd64"
  Normal   Created           10m                kubelet, 10.95.244.59  Created container configtxlator
  Normal   Started           10m                kubelet, 10.95.244.59  Started container configtxlator
  Normal   Pulling           10m                kubelet, 10.95.244.59  Pulling image "ip-ibp-images-team-docker-remote.artifactory.swg-devops.com/cp/ibp-couchdb:2.3.1-20190924-amd64"
  Normal   Pulled            10m                kubelet, 10.95.244.59  Successfully pulled image "ip-ibp-images-team-docker-remote.artifactory.swg-devops.com/cp/ibp-couchdb:2.3.1-20190924-amd64"
  Normal   Created           10m                kubelet, 10.95.244.59  Created container couchdb
  Normal   Started           10m                kubelet, 10.95.244.59  Started container couchdb
  Warning  Unhealthy         10m                kubelet, 10.95.244.59  Readiness probe failed: dial tcp 172.30.150.66:3000: connect: connection refused
````

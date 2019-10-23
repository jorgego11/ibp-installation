# IBP installation on K8s

Once you have an operational Kubernetes cluster up and running, you should be able to leverage the IBP installation script [ibp4k8s.sh](ibp4k8s.sh) in this folder. Before executing this script, make sure you have:

1. Properly set the `KUBECONFIG` environment variable so it points to the target Kubernetes cluster.
1. Created a configuration file for the installation. As reference, see [ibp4k8s.json.samp](ibp4k8s.json.samp). For details on the values that should be assigned to the elements in the configuration file, see the documentation inside the installation [script](ibp4k8s.sh).
1. Execute installation script:

    ```
    ./ibp4k8s.sh <config file>
    ```

## Resources
* [IKS and Proxy IP (ingress sub-domain)](iks.md)
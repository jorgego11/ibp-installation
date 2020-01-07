# IBP (v2.1.1) installation on IKS

Once you have an operational IKS cluster up and running, you should be able to leverage the IBP installation script [ibp4iks.sh](ibp4iks.sh) in this folder. Before executing this script, make sure you have:

1. Properly set the `KUBECONFIG` environment variable so it points to the target Kubernetes cluster.
1. Created a configuration file for the installation. As reference, see [ibp4iks.json.samp](ibp4iks.json.samp). For details on the values that should be assigned to the elements in the configuration file, see the documentation inside the installation [script](ibp4iks.sh).
1. Execute installation script:

    ```
    ./ibp4iks.sh <config file>
    ```

1. As the script runs, pay attention to the output/logs. Watch out for errors; if a fatal error occurs, the script will stop its execution.

## Resources
* [IKS and Proxy IP (ingress sub-domain)](iks-ingress.md)
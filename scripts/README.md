## IBP installation on K8s

Once you have an operational open source Kubernetes cluster up and running, you can leverage the IBP installation script [install-ibp.sh](install-ibp.sh) in this folder. Before executing this script, make sure you have:

1. Properly set the `KUBECONFIG` environment variable so it points to the target Kubernetes cluster.
1. Created a configuration file for the installation. As reference, see [ibp4k8s.json.samp](ibp4k8s.json.samp). For details on the values that should be assigned to the elements in the configuration file, see the documentation inside the installation [script](install-ibp.sh).

Once above requirements are met, you are ready to execute installation script:

    ./install-ibp.sh k8s <config file>    

As the script runs, please pay attention to the output/logs. Watch out for errors; if a fatal error occurs, the script will stop its execution.

## IBP installation on Red Hat OpenShift

Once you have an operational Red Hat OpenShift environment up and running, you can leverage the IBP installation script [install-ibp.sh](install-ibp.sh) in this folder. Before executing this script, make sure you have:

1. Created a configuration file for the installation. As reference, see [ibp4ocp.json.samp](ibp4ocp.json.samp). For details on the values that should be assigned to the elements in the configuration file, see the documentation inside the installation [script](install-ibp.sh).

Once above requirements are met, you are ready to execute installation script:
    
    ./install-ibp.sh oc <config file>

As the script runs, please pay attention to the output/logs. Watch out for errors; if a fatal error occurs, the script will stop its execution.
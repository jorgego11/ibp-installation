# IBP installation on Azure

## IBP installation on Azure Kubernetes Service (AKS)

Prerequisites:
* Have an account with Azure
* Install Azure CLI
* Create an AKS cluster (using a 4x16 node such as Standard_B4ms seems to be big enough for testing)
* Provision a public custom DNS domain

Install IBP
   * The commands below login into Azure, get connected to the cluster, verify connection and install:

    //remove previous session just in case
    az logout
    // login to Azure
    az login
    // login to your cluster
    az aks get-credentials --resource-group <ResourceGroup> --name <AKSClusterName>
    // verify you are connected to the right cluster
    kubectl get nodes
    // Create a "configuration file" for the installation. Update the "DOMAIN" information based on your Azure networking configuration below.
    // run the install as described under the scripts folder
    ./install-ibp.sh AKS <config file>  

Azure networking configuration:

* The networking configuration requires a public custom DNS domain which will be used by the install script "configuration file".

* We will create an ingress controller using the link below as guidance:

  https://github.com/kubernetes/ingress-nginx/blob/nginx-0.30.0/docs/deploy/index.md#prerequisite-generic-deployment-command
    
* Get a local copy and update *mandatory.yaml* by adding the --enable-ssl-passthrough flag in the line below

  https://github.com/kubernetes/ingress-nginx/blob/nginx-0.30.0/deploy/static/mandatory.yaml#L227

* This enables the SSL Passthrough feature, which is disabled by default. This is required to enable passthrough backends in Ingress objects. Now, lets apply the yaml file,  run:

      kubectl apply -f mandatory.yaml

* After mandatory.yaml run the "Provider Specific Steps" for Azure as explained in the same page. 

* Make the public custom DNS domain point to the external IP defined by ingress-nginx LoadBalancer resource. To find the external IP look for ingress-nginx LoadBalancer from the command output below.

      kubectl get services --all-namespaces

## Azure OpenShift licencing (from Matthew Golby-Kirk/UK/IBM)

1. "Managed OpenShift on Azure".
This is expensive as it is fully managed, like IBP v1 Enterprise - includes staff costs and the OpenShift licence etc. This is the simplest for a client to get going with as it includes the OpenShift Licence part and the Azure part is pay-per-use. It starts at around ~£3000 UKP per month and has a one year tie in, but discounts a 3 year purchase by ~60%. This is too expensive for internal use!

1. "Azure Red Hat OpenShift". 
A template set up that requires an up-front payment for the OpenShift licence. Not really looked to deep into this one as we don't need this type of licence as we can get OpenShift licences direct from RedHat. Again 1 year tie in with discounts for multi-year buy.

1. "Red Hat OpenShift Container Platform Self-Managed". 
This is a template based deployment that allows you to "bring your own OpenShift licence" so you only pay for the Azure components you use. The only downside is that by default it creates a more "prod" style of deployment with 3 Master nodes, 3 Infra nodes and a variable number of worker nodes, but I'm working on customising this for future deployments to bring the cost down. A rough estimate for this option is ~£900 UKP / Month. This is the version I have deployed and once you know what to put into it the template seems fairly good - takes about 1-2 hours to deploy the OpenShift parts and all the VMs, Bastion host, load balancers, IP address etc etc roughly 50 components! Then you have an OpenShift console and can easily deploy IBP in a couple of hours - it uses dynamic disk provisioning which makes deploying IBP components easy.

1. "DIY". 
There are templates on GitHub to configure everything yourself, but these look horribly complicated and I decided that option 3 would be best for me given the time I had.


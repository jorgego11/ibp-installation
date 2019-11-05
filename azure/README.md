# IBP installation on Azure

Thanks to Matthew Golby-Kirk/UK/IBM for the details below.

For Azure OpenShift licencing, there are 4 main options.

1. "Managed OpenShift on Azure".
This is expensive as it is fully managed, like IBP v1 Enterprise - includes staff costs and the OpenShift licence etc. This is the simplest for a client to get going with as it includes the OpenShift Licence part and the Azure part is pay-per-use. It starts at around ~£3000 UKP per month and has a one year tie in, but discounts a 3 year purchase by ~60%. This is too expensive for internal use!

1. "Azure Red Hat OpenShift". 
A template set up that requires an up-front payment for the OpenShift licence. Not really looked to deep into this one as we don't need this type of licence as we can get OpenShift licences direct from RedHat. Again 1 year tie in with discounts for multi-year buy.

1. "Red Hat OpenShift Container Platform Self-Managed". 
This is a template based deployment that allows you to "bring your own OpenShift licence" so you only pay for the Azure components you use. The only downside is that by default it creates a more "prod" style of deployment with 3 Master nodes, 3 Infra nodes and a variable number of worker nodes, but I'm working on customising this for future deployments to bring the cost down. A rough estimate for this option is ~£900 UKP / Month. This is the version I have deployed and once you know what to put into it the template seems fairly good - takes about 1-2 hours to deploy the OpenShift parts and all the VMs, Bastion host, load balancers, IP address etc etc roughly 50 components! Then you have an OpenShift console and can easily deploy IBP in a couple of hours - it uses dynamic disk provisioning which makes deploying IBP components easy.

1. "DIY". 
There are templates on GitHub to configure everything yourself, but these look horribly complicated and I decided that option 3 would be best for me given the time I had.


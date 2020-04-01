# IBP installation (v2.1.3)

Please note that assets in this repository are meant to be used by the **Blockchain Labs** and **Tech Sales** teams (i.e. they are not meant to be given to a customer for free).

This repository contains scripts for installing IBP v2 (software version) on:

* An OpenShift cluster
* A Kubernetes cluster such as Rancher and AKS

In addition to installation scripts, this repository contains notes and observations while exploring Kubernetes environments such as Rancher. This is a live repository where documents and code are updated on a regular basis.

Also, at the time of writing, if you intend to use IBP on the IBM Cloud for a client engagement, you should simply leverage IBP SaaS on the IBM Cloud.

## Table of contents

1. [IBP on K8s and OpenShift](scripts/README.md)
1. [Rancher (single node install)](rancher/single-node-install/README.md)
1. [Rancher (multi node install)](rancher/multi-node-install/README.md)
1. [IBP on Azure](azure/README.md)

## Additional resources

1. [ansible-role-blockchain-platform-manager](https://github.com/IBM-Blockchain/ansible-role-blockchain-platform-manager) - Ansible scripts for defining your Fabric blockchain network once IBP is up and running.

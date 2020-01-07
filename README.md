# IBP installation

This repository contains scripts for installing IBP v2 (software version) on:

* An OpenShift cluster
* A Kubernetes cluster such as Rancher

In addition to installation scripts, this repository contains notes and observations while exploring Kubernetes environments such as Rancher. This is a live repository where documents and code are updated on a regular basis.

Also, please note that manual installation of IBP v2 on IKS is **not** supported. Though doing so was possible on prior versions of IBP (e.g. 2.1.1), this no longer works with IBP 2.1.2. If you intend to use IBP on the IBM Cloud for a client engagement, you should simply leverage IBP SaaS on the IBM Cloud.

## Table of contents

1. [OpenShift](openshift/README.md)
1. [Rancher (single node install)](rancher/single-node-install/README.md)
1. [Rancher (multi node install)](rancher/multi-node-install/README.md)

## Additional resources

1. [ansible-role-blockchain-platform-manager](https://github.com/IBM-Blockchain/ansible-role-blockchain-platform-manager) - Ansible scripts for defining your Fabric blockchain network once IBP is up and running.
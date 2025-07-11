## **Table of Contents**

- [Usage](#usage)
- [Overview](#overview)
- [Vagrantfile explanation](#vagranfile)
- [Ingress](#ingress)
- [Resources](#resources)

## Usage

## Overview

The second part of the project requires us to deploy **3 web applications of our choice** on our **K3s instance**.

Here, the K3s setup runs in **single-node cluster mode. T**here is **no K3s agent node,** just **a single K3s server** acting as both the control plane and the agent.

To enable connectivity for our apps, we need:

- **An ingress controller:** K3s includes a built-in ingress controller (usually Traefik) that is installed automatically when you set up K3s using [https://get.k3s.io](https://get.k3s.io/).
- **Ingress rules configuration:** We create ingress resource definitions to route traffic.
- For each app, provide:
    - A `deployment.yaml` ****to define the pods.
    - A `service.yaml` ****to expose the pods within the cluster, allowing the ingress controller to route traffic to them.

For the deployment, we use the latest version of the container image created by Paul Bouwer called hello-kubernetes. This image prints a simple "Hello World". We modify it to instead display “Hello from app X”. For more details, see the original image on Docker Hub: https://hub.docker.com/r/paulbouwer/hello-kubernetes

## Vagrantfile

## Ingress

## Resources

- **Kubernetes - Cluster networking :** https://kubernetes.io/docs/concepts/cluster-administration/networking/
- **Kubernetes - Ingress documentation :** https://kubernetes.io/docs/concepts/services-networking/ingress/
- **Kubernetes - Services, load balancing and networking :** https://kubernetes.io/docs/concepts/services-networking/
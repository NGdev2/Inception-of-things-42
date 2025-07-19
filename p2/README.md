# Overview

The second part of the project requires us to deploy **3 web applications of our choice** on our **K3s instance**. The second app must have 3 replicas. Here, the K3s setup runs in **single-node cluster mode.** There is **no K3s agent node,** just **a single K3s server** acting as both the control plane and the agent.

![p2_diagram.png](../image_readme/p2_diagram.png)

To enable connectivity for our apps, we need:

- **An ingress controller:** K3s includes a built-in ingress controller (usually Traefik) that is installed automatically when you set up K3s using [https://get.k3s.io](https://get.k3s.io/).
- **Ingress rules configuration:** We create ingress resource definitions to route traffic.
- For each app, provide:
    - A `deployment.yaml` to define the pods.
    - A `service.yaml` to expose the pods within the cluster, allowing the ingress controller to route traffic to them.

For the deployment, we use the latest version of the container image created by Paul Bouwer called hello-kubernetes. This image prints a simple "Hello World". We modify it to instead display “Hello from app X”. For more details, see the original image on Docker Hub: https://hub.docker.com/r/paulbouwer/hello-kubernetes

## **Table of Contents**
- [Overview](#overview)
- [Usage](#usage)
- [Vagrantfile](#vagrantfile)
- [Ingress](#ingress)
- [Resources](#resources)

# Usage

To **launch the virtual machine** using **Vagrant**, run : 

```bash
cd p2

# Start the Vagrant environment
vagrant up
```

**You can then SSH into the VM :** 

```bash
# Access the Kubernetes server VM
vagrant ssh lduheronS
```

## Vagrantfile

This Vagrantfile declares a **single-node K3s cluster**. It uses the same setup options as the `p1/Vagrantfile`, described in `p1/README.md`.

## Ingress

An Ingress is a Kubernetes resource that defines rules for accessing services within the cluster from the outside over HTTP or HTTPS. It acts as an entry point and manages external access to the applications running inside the Kubernetes cluster.

## server.sh

The [`server.sh`](http://server.sh) script sets up a **single-node K3s cluster**, meaning there is only a **K3s agent** and no **K3s agent node**. This setup is done the same way as the server in part 1.

Once the cluster is created, the script **applies the Kubernetes manifests** for each application. 

Applying these manifests means that Kubernetes creates the necessary resources (like pods, deployments and services) to run the apps inside the cluster.

Applying the ingress configuration sets up routing rules so external requests to certain domain names are directed to the correct applications inside the cluster.

```bash
# apply deployment and services of each app
kubectl apply -f /vagrant/configs/app1
kubectl apply -f /vagrant/configs/app2
kubectl apply -f /vagrant/configs/app3

# apply ingress
kubectl apply -f /vagrant/configs/ingress/ingress.yaml
```

Finally, the script adds entries to the `/etc/hosts` file on the host machine. This **associates the IP address** of the K3s server node with the **domain names** of the applications. 

```bash
echo "192.168.56.110 app1.com" | sudo tee -a /etc/hosts
echo "192.168.56.110 app2.com" | sudo tee -a /etc/hosts
echo "192.168.56.110 app3.com" | sudo tee -a /etc/hosts
```

# Resources

- **Kubernetes - Cluster networking :** https://kubernetes.io/docs/concepts/cluster-administration/networking/
- **Kubernetes - Ingress documentation :** https://kubernetes.io/docs/concepts/services-networking/ingress/
- **Kubernetes - Services, load balancing and networking :** https://kubernetes.io/docs/concepts/services-networking/
- **K3s cluster using vagrant :** https://medium.com/@dharsannanantharaman/create-a-high-availabilty-lightweight-kubernetes-k3s-cluster-using-vagrant-822a1e025855
- **Maitriser les ingress Kubernetes - Stephane Robert :** https://blog.stephane-robert.info/docs/conteneurs/orchestrateurs/kubernetes/ingress/ 
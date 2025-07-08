## About the project

**Inception of Things** is a **42Network** project introduces basic system administration using **Vagrant** for **VM automation** and **Kubernetes** for managing containers.

## Getting started

Clone the repository using: 

```bash
git clone git@github.com:NGdev2/Inception-of-things-42.git
```

This project is divided into three independent parts.

Each part includes:

- its own `Vagrantfile` to set up a dedicated virtual machine
- a specific `README.md` explaining how to use the corresponding module

Once you've followed the setup instructions for a given part, you can use `kubectl` commands to interact with the pods, as detailed in the documentation.

## About Kubernetes

**Kubernetes (K8s)** is an open-source tool developed by Google that automates the deployment, scaling, and management of containerized applications. It handles updates, monitors application health, and restarts them if they fail. Kubernetes provides a robust framework for **running distributed systems reliably and efficiently.**

## I. K3s and Vagrant

The first part of this project requires to set-up two machines writing a **Vagrantfile.**

### About Vagrant

**Vagrant** is a tool that simplifies the **creation** and **management of virtual machines.**

Configuration is done through a **Vagrantfile** : it is a **configuration file** that defines the machine's operating system, installed software, network configuration, and more.

### About K3s

K3s is a lightweight, certified Kubernetes distribution developed by Rancher. It's optimized for resource-constrained environments, making it ideal for development and testing.

There are two types of nodes in K3s:

- **Server** (acts as both control plane and worker)
- **Agent** (also called **ServerWorker** in this project, acts as a worker node only)

Unlike the standard Kubernetes control plane, a K3s Server node can run standalone (monopod mode). The Server includes both the control plane components and a **kubelet** to handle workloads. If needed, the worker functionality of the Server can be disabled.

**Here is the content of a Server:**

| **kube-apiserver** | Handles API requests. |
| --- | --- |
| **kube-scheduler** | Control plane component that watches for newly created pods with no assigned node and selects a node for them to run on. |
| **kube-controller-manager** | Manages controllers |
| **SQLite / MySQL / etcd** | Backend database for storing cluster state |
| **kubelet** | Runs on every node to manage pods |
| **kube-apiserver** | Maintains network rules |
| **containerd** | Container runtime |

**Here is the content of a ServerWorker:**

| **kubelet** | Runs on every node to manage pods |
| --- | --- |
| **kube-proxy** | Maintains network rules |
| **containerd** | Container runtime |
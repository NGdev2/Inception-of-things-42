# Overview

The final mandatory part of the project focuses on deploying an application based on `wil42/playground` using **Docker with K3d, Argo CD, continuous integration and GitOps.** Unlike the previous parts, this one does not rely on Vagrant.

![p3_diagram.png](../image_readme/p3_diagram.png)

## Table of Contents

- [Overview](#overview)
- [Usage](#usage)
- [About K3d](#about-k3d)
- [About Argo CD](#about-argo-cd)
- [About continuous integration](#about-continuous-integration)
- [Scripts](#scripts)
  - [argocd_init.sh](#argocd_init.sh)
  - [setup_k3d_cluster.sh](#setup_k3d_cluster.sh)
  - [reset_k3d_env.sh](#reset_k3d_env.sh)
  - [argocd-app.yaml](#argocd-app.yaml)
- [Resources](#resources)

# Usage

First, the project requires a few **prerequisites** to be installed on the host machine : Docker, K3d, Kubernetes and Argo CD. This dependencies can be set up by running `set_upk3d_cluster.sh` script : 

```bash
# Set up the environment
bash setup_k3d_cluster.sh
```

Then, run the Argo CD initialization script : 

```bash
bash argocd_init.sh
```

Once Argo CD is running, access the web interface and generate a password :

- open :  [https://localhost:8082](https://localhost:8082/)
- **Username** : `admin`
- **Password** : *retrieve it with :*

```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

To access the deployed application, forward the service port:

```bash
kubectl port-forward svc/ftegan-app -n dev 8088:80
```

Finally, open [http://localhost:8088](http://localhost:8088/) or :

```bash
curl http://localhost:8088/
```

### Testing continuous integration

In order to **test continuous integration**, push a new version (v2) on GitHub repository :
https://github.com/NGdev2/ftegan

Update the image from `wil42/playground:v1` to `wil42/playground:v2`

Then monitor the Kubernetes resources as Argo CD automatically redeploys the application :

```bash
# Run this with short delays (1–3 seconds) to observe changes
kubectl get all -n dev
```

Watch for updated replicas, deployments, and pods.

### Clean

To **clean** everything up and **reset the environment :**

```bash
./cleanup.sh
```

This will:
- Stop port-forwards
- Delete the K3d cluster
- Remove dangling containers

---

## 📦 Components & Ports

| Component       | Namespace | Service Name     | Local Port | Cluster Port | Target (Pod) Port | Description                          |
|----------------|-----------|------------------|------------|---------------|-------------------|--------------------------------------|
| Argo CD        | argocd    | argocd-server     | `8082`     | `443`         | N/A               | Web UI via HTTPS                     |
| ftegan-app     | dev       | ftegan-app        | `8088`     | `80`          | `8888`            | Playground app inside container      |

---

## 🔁 Port Flow Explanation

### Diagram for `ftegan-app`:

```
Your PC
 └─> localhost:8088
       └─> port-forward
             └─> K8s Service ftegan-app:80
                   └─> Pod:8888 (container app port)
```

---

## 🔧 Port Roles Explained

| Term              | Example     | Role / Explanation                                                                 |
|-------------------|-------------|-------------------------------------------------------------------------------------|
| `containerPort`   | `8888`      | Internal port of the container (defined in the Docker image or app code).          |
| `targetPort`      | `8888`      | Port that **K8s Service** forwards to inside the pod. Usually same as containerPort. |
| `port` (Service)  | `80`        | Port **within the cluster** that the service exposes. Can be anything.             |
| `nodePort`        | `30000+`    | (Optional) Port to expose service **outside cluster** without port-forwarding.     |
| `kubectl port-forward` | `8088:80` | Maps a **local port** (8088) to a **cluster service port** (80).               |

---
Explanation
---
bash ./setup_k3d_cluster.sh
bash ./argocd_init.sh
---

if (problem=ports, kubeconfig or version of packages) -> bash ./cleanup.sh -> reinitialize
it launchs app by given in repository url of argocd-app.yaml. for accessing from Host PC, we need to launch portforwarding
to understand which port we need to ping we can use that command
kubectl describe svc ftegan-app -n dev
we will see "port" 80. it means that our ftegan-app expose that port for communicate with it

command for port forwarding
---
kubectl port-forward svc/ftegan-app -n dev 8088:80
---
now we can see our app by url 127.0.0.1:8088


host machine expose port 8088 -> service of deployment app expose port 80 -> deployment ftegan-app expose port 8888


Service determine who can connect to deployment by 2 criteries: port (80) and selector that should match to pod label:
selector:
  app: ftegan-app (file service.yaml)

Selector create filter for access permission

deployment determine labels that pods and containers will inherit
spec:
  template:
    metadata:
      labels:
        app: ftegan-app 
(deployment.yaml)

pods created by deployment will have app=ftegan-app
example:
kubectl get pods -n dev --show-labels
NAME                          READY   STATUS    RESTARTS      AGE    LABELS
ftegan-app-7b6d6fd56f-btwrl   1/1     Running   7 (68m ago)   4d4h   app=ftegan-app,pod-template-hash=7b6d6fd56f

so services are created to expose ports and provide stable access to pods
deployments is an object that creates and manages pods, maintain desired number of replicas, verify their status, restarts them if needs, updates pods (and delete outdated) or rolled out



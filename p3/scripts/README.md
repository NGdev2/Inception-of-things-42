
# 🧠 ftegan-app Kubernetes Playground

This project sets up a **K3d/K3s Kubernetes cluster**, deploys **Argo CD**, and manages a sample app based on `wil42/playground` using **GitOps**.

---

## 🚀 Quick Start

### 1. Setup Cluster & Install Argo CD
```bash
./setup_k3d_cluster.sh
```

### 2. Initialize Argo CD and deploy app
```bash
./argocd_init.sh
```

### 3. Open Argocd. generate password for it

Then open: https://localhost:8082  
Default user: `admin`  
Get password:
```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

### 4. Port Forward App
```bash
kubectl port-forward svc/ftegan-app -n dev 8088:80
```
Then open: http://localhost:8088  
Or:
```bash
curl http://localhost:8088/
```

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

## 🧼 Clean Up

To tear down and reset the environment:
```bash
./cleanup.sh
```

This will:
- Stop port-forwards
- Delete the K3d cluster
- Remove dangling containers

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

- - receive password of argocd
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
---

---
enter to argocd https://localhost:8082/ 
with login: admin and password from previous command
---

---
enter to app to http://localhost:8088/ or use curl curl http://localhost:8088/

for testing continuous integration, push v2 to github
https://github.com/NGdev2/ftegan

(change wil42/playground:v1 to wil42/playground:v2)

check what happens with object of our kubernetes (launch command with shor delay - 1-3 seconds. look for replicas, deployments and pods)
kubectl get all -n dev



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

### 3. Port Forward Argo CD Web UI
```bash
kubectl port-forward svc/argocd-server -n argocd 8082:443
```
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

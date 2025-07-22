
# Bonus Task: GitLab Integration with K3d and ArgoCD

This bonus task extends Part 3 by integrating a local GitLab instance with the existing K3d cluster and ArgoCD setup, creating a complete GitOps workflow.

## 🎯 Project Overview

**Architecture:**
```
GitLab (localhost:8880) → ArgoCD → K3d Cluster → Application (localhost:8888)
```

**What this demonstrates:**
- Local GitLab instance integrated with Kubernetes cluster
- GitOps workflow: changes in GitLab automatically deploy to cluster
- ArgoCD monitoring GitLab repository for configuration changes
- Complete CI/CD pipeline infrastructure

## 📋 Prerequisites

- Completed Part 3 successfully (K3d + ArgoCD working)
- Docker installed and running
- Sufficient system resources (GitLab is resource-intensive)
- DockerHub account (optional, for custom images)

## 🚀 Quick Start

### 1. Complete Environment Setup
```bash
# Clean any previous installations
./clean_all.sh

# Setup K3d cluster with ArgoCD
./setup_k3d_cluster.sh

# Wait for ArgoCD to be ready (2-5 minutes)
kubectl get pods -n argocd -w
# Wait until argocd-server pods show "Running"

# Initialize ArgoCD properly
./argocd_init.sh
```

### 2. Setup GitLab
```bash
# Start GitLab using Docker (simpler and more reliable)
./start_gitlab_ce_docker.sh

# Wait 2-3 minutes for GitLab to initialize
# Check status: docker inspect --format='{{.State.Health.Status}}' gitlab-ce
```

### 3. Setup Port Forwarding and Access
```bash
# Setup all port forwarding
./restart_port_forwarding.sh

# Get all access credentials and status
./show_access_info.sh
```

## 📖 Step-by-Step Setup Guide

### Step 1: Environment Preparation

```bash
# 1. Ensure Docker is running
sudo systemctl start docker
sudo systemctl status docker

# 2. Clean previous installations
./clean_all.sh

# 3. Verify cleanup
docker ps -a
k3d cluster list
```

### Step 2: K3d Cluster Setup

```bash
# 1. Create K3d cluster with namespaces
./setup_k3d_cluster.sh

# 2. Verify cluster is ready
kubectl get nodes
kubectl get namespaces

# Expected output:
# - Namespaces: argocd, dev, default, etc.
# - Node status: Ready
```

### Step 3: ArgoCD Initialization

```bash
# 1. Wait for ArgoCD pods to start
kubectl get pods -n argocd

# 2. Initialize ArgoCD when pods are Running
./argocd_init.sh

# # Apply ArgoCD app when all services are running
kubectl apply -f argocd-gitlab-app.yaml

# 3. Verify ArgoCD access
# URL: https://localhost:8082
# Username: admin
# Password: (check argocd-password.txt)
```

### Step 4: GitLab Setup

```bash
# 1. Start GitLab container
./start_gitlab_ce_docker.sh

# 2. Wait for GitLab to initialize (2-3 minutes)
curl http://localhost:8880

# 2.5 save gitlab password 
kubectl get secret gitlab-gitlab-initial-root-password -n gitlab -ojsonpath='{.data.password}' | base64 --decode > gitlab-root-password.txt


# 3. Access GitLab
# URL: http://localhost:8880
# Username: root
# Password: (auto-generated, check container logs)
```

### Step 5: GitLab Project Configuration

#### 5.1 Create GitLab Project
1. Go to: http://localhost:8880
2. Login as root with password from `gitlab-root-password.txt`
3. Create new project: "ftegan"
4. Make it public
5. Initialize with README

#### 5.2 Setup GitLab CI/CD Variables (Optional for CI/CD pipeline)
1. Go to your project → Settings → CI/CD
2. Expand "Variables" section  
3. Add these variables:
   - **DOCKER_USERNAME**: Your DockerHub username
   - **DOCKER_PASSWORD**: Your DockerHub password
   - **KUBECONFIG_CONTENT**: Run `k3d kubeconfig get fteganS | base64 -w 0` and paste output

#### 5.3 Create Personal Access Token (For Git Operations)
1. Click your avatar (top right) → Edit Profile
2. Go to Access Tokens (left sidebar)
3. Create token with:
   - **Name**: `git-access`
   - **Scopes**: ✅ api, ✅ read_repository, ✅ write_repository
4. **Copy the token** (you'll only see it once!)

#### 5.4 Upload Configuration Files

**Method A: Web Interface (Easier)**
1. In your GitLab project, click "+" → "New directory"
2. Create directory: `configs`
3. Upload files to configs/:
   - `deployment.yaml`
   - `service.yaml`

**Method B: Git Clone and Push (Recommended)**
```bash
# 1. Clone your GitLab repository
git clone http://localhost:8880/root/ftegan.git
cd ftegan

# 2. Create configs directory and add files
mkdir -p configs

# 3. Create deployment.yaml
cat > configs/deployment.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ftegan-app
  namespace: dev
  labels:
    app: ftegan-app
spec:
  replicas: 1
  selector:
    matchLabels:
      app: ftegan-app
  template:
    metadata:
      labels:
        app: ftegan-app
    spec:
      containers:
      - name: ftegan-app
        image: aidarngdev/ftegan:v2
        ports:
        - containerPort: 8888
EOF

# 4. Create service.yaml
cat > configs/service.yaml << 'EOF'
apiVersion: v1
kind: Service
metadata:
  name: ftegan-app
  namespace: dev
spec:
  selector:
    app: ftegan-app
  ports:
  - protocol: TCP
    port: 80
    targetPort: 8888
  type: NodePort
EOF

# 5. Commit and push changes
git add .
git commit -m "Add Kubernetes configuration files"
git push origin main
# When prompted:
# Username: root
# Password: [paste your personal access token]
```

### Step 6: ArgoCD Integration

```bash
# 1. Get GitLab container IP
docker inspect gitlab-ce | grep IPAddress

GITLAB_IP=$(docker inspect gitlab-ce | grep '"IPAddress"' | head -1 | cut -d'"' -f4)
echo "GitLab IP: $GITLAB_IP"

# 2. Create ArgoCD application
cat > argocd-gitlab-app.yaml << 'EOF'
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: ftegan-app-gitlab
  namespace: argocd
spec:
  project: default
  source:
    repoURL: 'http://$GITLAB_IP/root/ftegan.git  # Use GitLab container IP
    path: configs
    targetRevision: main
  destination:
    server: 'https://kubernetes.default.svc'
    namespace: dev
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
EOF

# 3. Apply ArgoCD application
kubectl apply -f argocd-gitlab-app.yaml
```

### Step 7: Setup Port Forwarding

```bash
# Setup all required port forwards
./restart_port_forwarding.sh

# Or manually:
kubectl port-forward svc/argocd-server -n argocd 8082:443 &
kubectl port-forward -n dev svc/ftegan-app 8888:80 &

# Verify port forwards
lsof -i :8082,8880,8888
```

## 🧪 Testing the Complete Pipeline

### Test 1: Verify Initial Deployment

```bash
# 1. Check ArgoCD application status
argocd app get ftegan-app-gitlab

# 2. Verify pods are running
kubectl get pods -n dev

# 3. Test application response
curl http://localhost:8888
# Expected: {"status": "ok", "message": "My ✨Flamboyant✨ app v2🥈"}
```

### Test 2: GitOps Workflow

```bash
# 1. Edit deployment.yaml in GitLab
# Change: image: aidarngdev/ftegan:v2
# To: image: aidarngdev/ftegan:v1

# 2. Watch ArgoCD detect and sync changes
argocd app get ftegan-app-gitlab
kubectl get pods -n dev -w

# 3. Verify version change
curl http://localhost:8888
# Expected: Different message for v1
```

### Test 3: Complete Git Workflow with Version Changes

```bash
# 1. Clone repository (if not already done)
git clone http://localhost:8880/root/ftegan.git
cd ftegan

# 2. Make changes to trigger GitOps workflow
# Edit configs/deployment.yaml - change image tag
sed -i 's/aidarngdev\/ftegan:v2/aidarngdev\/ftegan:v1/' configs/deployment.yaml

# 3. Commit and push changes
git add configs/deployment.yaml
git commit -m "Update application to version v1"
git push origin main
# Username: root
# Password: [your personal access token]

# 4. Watch ArgoCD detect and sync changes automatically
argocd app get ftegan-app-gitlab
kubectl get pods -n dev -w

# 5. Verify the version change
curl http://localhost:8888
# Expected: Different response showing v1 message

# 6. Change back to v2 to test again
sed -i 's/aidarngdev\/ftegan:v1/aidarngdev\/ftegan:v2/' configs/deployment.yaml
git add configs/deployment.yaml
git commit -m "Update application to version v2"
git push origin main

# 7. Watch the deployment update again
kubectl get pods -n dev -w
curl http://localhost:8888
```

### Git Authentication Troubleshooting

If you get authentication errors:

```bash
# Make sure you're using the personal access token as password
# NOT the GitLab root password

# If you forgot your token, create a new one:
# GitLab → Profile → Access Tokens → Create new token

# Alternative: Save credentials to avoid repeated prompts
git config credential.helper store
# Next git push will save credentials for future use
```

## 🔍 Monitoring and Troubleshooting

### Check System Status

```bash
# ArgoCD status
kubectl get pods -n argocd
argocd app list

# GitLab status
docker ps | grep gitlab-ce
curl http://localhost:8880

# Application status
kubectl get all -n dev
curl http://localhost:8888

# Port forwarding status
lsof -i :8082,8880,8888
```

### Common Issues and Solutions

#### ArgoCD Connection Issues
```bash
# Restart ArgoCD port forwarding
pkill -f "port-forward.*argocd"
kubectl port-forward svc/argocd-server -n argocd 8082:443 &

# Check ArgoCD password
cat argocd-password.txt
```

#### GitLab Access Issues
```bash
# Check GitLab container
docker logs gitlab-ce

# Get GitLab root password
docker exec -it gitlab-ce grep 'Password:' /etc/gitlab/initial_root_password
```

#### ArgoCD Sync Issues
```bash
# Check ArgoCD application status
argocd app get ftegan-app-gitlab

# Manual sync
argocd app sync ftegan-app-gitlab

# Check GitLab repository URL
kubectl get application ftegan-app-gitlab -n argocd -o yaml
```

#### Application Not Accessible
```bash
# Check service and pods
kubectl get svc,pods -n dev

# Restart application port forwarding
pkill -f "port-forward.*ftegan"
kubectl port-forward -n dev svc/ftegan-app 8888:80 &
```

## 📊 Verification Commands

### Complete System Check
```bash
echo "=== BONUS TASK VERIFICATION ==="

echo "1. K3d Cluster:"
kubectl get nodes

echo "2. ArgoCD:"
kubectl get pods -n argocd
echo "ArgoCD UI: https://localhost:8082"

echo "3. GitLab:"
docker ps | grep gitlab-ce
echo "GitLab UI: http://localhost:8880"

echo "4. Application:"
kubectl get pods -n dev
echo "App URL: http://localhost:8888"
curl http://localhost:8888

echo "5. ArgoCD Application:"
argocd app get ftegan-app-gitlab

echo "6. Port Forwards:"
lsof -i :8082,8880,8888
```

## 🎯 Success Criteria

✅ **GitLab running locally**: http://localhost:8880 accessible  
✅ **GitLab integrated with cluster**: ArgoCD watching GitLab repository  
✅ **Dedicated namespace**: All components in correct namespaces  
✅ **Part 3 functionality**: ArgoCD and application working  
✅ **GitOps workflow**: Changes in GitLab auto-deploy to cluster  

## 🔧 Utility Scripts

### Restart All Port Forwarding
```bash
#!/bin/bash
pkill -f "port-forward" 2>/dev/null || true
sleep 2
kubectl port-forward -n argocd svc/argocd-server 8082:443 &
kubectl port-forward -n dev svc/ftegan-app 8888:80 &
echo "Port forwarding restarted"
```

### Show Access Information
```bash
#!/bin/bash
echo "🎯 BONUS TASK ACCESS INFORMATION"
echo "ArgoCD: https://localhost:8082 (admin / $(cat argocd-password.txt))"
echo "GitLab: http://localhost:8880 (root / check container logs)"
echo "App: http://localhost:8888"
```

### Complete Cleanup
```bash
#!/bin/bash
# Stop all port forwards
pkill -f "port-forward"

# Remove GitLab container
docker stop gitlab-ce
docker rm gitlab-ce

# Clean K3d cluster
k3d cluster delete fteganS

# Clean Docker
docker system prune -f
```

## 📁 File Structure

```
bonus/
├── setup_k3d_cluster.sh          # K3d cluster setup
├── improved_argocd_init.sh        # ArgoCD initialization
├── start_gitlab_ce_docker.sh      # GitLab Docker setup
├── clean_all.sh                   # Complete cleanup
├── restart_port_forwarding.sh     # Restart port forwards
├── show_access_info.sh            # Show access credentials
├── argocd-gitlab-app.yaml         # ArgoCD application config
└── README.md                      # This guide
```

## 🏆 Evaluation Demonstration

During evaluation, demonstrate:

1. **Environment Running**: All services accessible via browsers
2. **GitOps Workflow**: Edit file in GitLab → automatic deployment
3. **Version Management**: Change image tags and see updates
4. **Monitoring**: Show ArgoCD sync status and application health
5. **Integration**: Explain how GitLab connects to K8s via ArgoCD

**Time Estimate**: 
- Setup: 15-20 minutes
- Demonstration: 5-10 minutes
- Total: ~30 minutes

---

**Note**: This bonus task successfully integrates GitLab with the Part 3 environment, creating a complete GitOps workflow suitable for modern DevOps practices.
=======
## Overview

The bonus section focuses on deploying the third part of the project via **GitLab** pipelines.

## Table of Contents

- [Overview](#overview)
- [Usage](#usage)
- [About Gitlab](#about-gitlab)
- [Resources](#resources)

## Usage

## About Gitlab

**GitLab** is a web-based DevOps platform built around Git. The platform helps automate tasks and manage software projects in one place. 

It includes built-in tools for issue tracking, continuous integration (CI) and continuous deployment (CD). It is available in both open-source and commercial editions. The platform is used to automate workflows and manage software projects in one place.

GitLab uses a file named `.gitlab-ci.yml` at the root of the repository to define a set of automated tasks called **pipelines**. These pipelines are triggered every time code is pushed to the repository. The file contains **jobs**, which are individual tasks such as building the project, running tests or deploying it. Jobs are organized into stages, which represent logical steps in the workflow. For example, a pipeline might include a build stage, followed by a test stage and finally a deploy stage. All jobs in a stage are run in parallel and the next stage only starts if all jobs in the current stage succeed. This allows for clear and structured automation of the project’s lifecycle.

## Resources

# **Overview**

The bonus part of the project extends **Part 3** by integrating a **local GitLab instance** with the existing **K3d cluster** and **ArgoCD setup**, creating a complete **GitOps workflow**. This implementation demonstrates modern DevOps practices where **GitLab serves as the source of truth** for both application code and deployment configurations.


The architecture flow: **GitLab (localhost:8880) → ArgoCD → K3d Cluster → Application (localhost:8888)**

Unlike the previous parts, this bonus task **runs GitLab locally using Docker** and creates a **dedicated GitLab namespace** for proper resource isolation. The setup maintains all functionality from Part 3 while adding GitLab integration for a production-ready CI/CD pipeline.

## Table of Contents
- [Overview](#overview)
- [Usage](#usage)
- [GitLab Integration](#gitlab-integration)
- [GitOps Workflow](#gitops-workflow)
- [Scripts Explanation](#scripts-explanation)
  - [setup_k3d_cluster.sh](#setup_k3d_clustersh)
  - [argocd_init.sh](#argocd_initsh)
  - [start_gitlab_ce_docker.sh](#start_gitlab_ce_dockersh)
  - [argocd-gitlab-app.yaml](#argocd-gitlab-appyaml)
  - [Utility Scripts](#utility-scripts)
- [Testing and Verification](#testing-and-verification)
- [Resources](#resources)

# Usage

**Prerequisites:** Docker installed and running, sufficient system resources (GitLab is resource-intensive).

To set up the complete **GitOps environment**, run:

```bash
cd bonus/scripts

# 1. Clean any previous installations (optional but recommended)
./clean_all.sh

# 2. Setup K3d cluster with ArgoCD
./setup_k3d_cluster.sh

# 3. Wait for ArgoCD to be ready (2-5 minutes)
kubectl get pods -n argocd -w
# Wait until all argocd-server pods show "Running"

# 4. Initialize ArgoCD properly
./argocd_init.sh

# 5. Start GitLab using Docker
./start_gitlab_ce_docker.sh

# 6. Setup port forwarding for all services
./restart_port_forwarding.sh

# 7. Get access credentials and status
./show_access_info.sh
```

**Access the services:**

- **ArgoCD UI:** https://localhost:8082 (admin / check argocd-password.txt)
- **GitLab UI:** http://localhost:8880 (root / check gitlab-root-password.txt)
- **Application:** http://localhost:8888

**Configure GitLab repository:**

```bash
# 1. Access GitLab at http://localhost:8880
# 2. Login as root with password from gitlab-root-password.txt
# 3. Create new project named "ftegan"
# 4. Clone repository and add configuration files

git clone http://localhost:8880/root/ftegan.git
cd ftegan
mkdir -p configs

# Create Kubernetes deployment configuration
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

# Create Kubernetes service configuration
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

# Commit and push changes
git add .
git commit -m "Add Kubernetes configuration files"
git push origin main
```

**Apply ArgoCD application to monitor GitLab repository:**

```bash
kubectl apply -f argocd-gitlab-app.yaml
```

**Test the GitOps workflow:**

```bash
# Edit deployment.yaml in GitLab to change image version
# ArgoCD will automatically detect and deploy changes
curl http://localhost:8888
```

## GitLab Integration

**GitLab** is a comprehensive DevOps platform that provides Git repository management, continuous integration, and continuous deployment capabilities. In this bonus implementation, GitLab serves as the **central source of truth** for application configuration and triggers automated deployments.

The integration works through several key components:

**GitLab CE Docker Container:** A local GitLab Community Edition instance running on port 8880, providing a full-featured Git repository with web interface, user management, and project organization.

**Repository Structure:** The GitLab repository contains Kubernetes manifests in a `configs/` directory, including deployment and service configurations that define how the application should run in the cluster.

**ArgoCD Application:** A specialized ArgoCD application resource that monitors the GitLab repository for changes and automatically syncs the cluster state to match the repository contents.

**Docker Integration:** GitLab runs as a Docker container with persistent data volumes, ensuring that repository data and configurations survive container restarts while maintaining proper isolation from the host system.

## GitOps Workflow

**GitOps** is a modern deployment methodology where **Git repositories serve as the single source of truth** for declarative infrastructure and application configuration. In this implementation, the GitOps workflow operates as follows:

**Developer makes changes:** Modifications to application configuration are made by editing YAML files in the GitLab repository through either the web interface or by cloning, editing, and pushing changes via Git commands.

**GitLab stores the desired state:** The repository maintains the authoritative version of how the application should be deployed, including container images, resource allocations, and service configurations.

**ArgoCD monitors for changes:** The ArgoCD application continuously polls the GitLab repository (using the container's internal IP address) to detect any modifications to the configuration files.

**Automatic synchronization:** When changes are detected, ArgoCD automatically applies the new configuration to the Kubernetes cluster, ensuring that the running application matches the desired state defined in Git.

**Self-healing capabilities:** If manual changes are made directly to the cluster that deviate from the Git repository, ArgoCD can automatically revert these changes to maintain consistency with the source of truth.

This workflow eliminates the need for manual deployments and provides a complete audit trail of all changes through Git history.

## Scripts Explanation

### setup_k3d_cluster.sh

This script establishes the foundation for the entire GitOps environment by installing dependencies and creating the Kubernetes cluster. The script begins by updating the system package list and installing curl, which is required for downloading other components.

The script checks for Docker installation and installs it using the official Docker installation script if not present. It adds the current user to the docker group to enable non-root access to Docker commands.

K3d installation follows using the official installation script from the K3d repository. K3d is chosen because it creates lightweight Kubernetes clusters using K3s inside Docker containers, making it ideal for local development and testing.

The script installs kubectl using the official Kubernetes release, ensuring compatibility with the cluster version. It downloads the latest stable release and installs it in `/usr/local/bin/`.

A K3d cluster named `fteganS` is created, following the naming convention established in previous parts. The script exports the KUBECONFIG environment variable to enable kubectl access to the cluster.

Finally, it creates the necessary namespaces: `argocd` for ArgoCD components and `dev` for application deployment. ArgoCD is installed using the official manifest from the ArgoCD repository.

### argocd_init.sh

This comprehensive script handles ArgoCD initialization with robust error handling and retry logic. The script includes several helper functions to ensure reliable setup.

The `wait_for_pods_ready` function monitors pod status with configurable timeout and check intervals. It waits for pods to reach "Running" status and then verifies they are ready to accept traffic.

The `wait_for_argocd_server` function specifically monitors the ArgoCD server pod, which is critical for the web interface and API access.

The `wait_for_argocd_secret` function waits for the initial admin secret to be created by ArgoCD, which contains the auto-generated password for the admin user.

The script checks if ArgoCD is already installed to avoid duplicate installations. It installs the ArgoCD CLI tool if not present, downloading the latest version from the official GitHub releases.

The admin password is extracted from the Kubernetes secret and saved to `argocd-password.txt` for easy access. Port forwarding is established to make ArgoCD accessible on localhost:8082.

The script includes retry logic for CLI login, as the ArgoCD server may take time to become fully operational even after the pods are running.

### start_gitlab_ce_docker.sh

This script manages GitLab Community Edition deployment using Docker containers. It first checks for existing GitLab containers and removes them to ensure a clean installation.

The script creates persistent data directories for GitLab configuration, logs, and data. Proper ownership is set using the GitLab user ID (998) to ensure the container can access the mounted volumes.

GitLab is deployed using the official `gitlab/gitlab-ce:17.11.6-ce.0` image with specific configuration:
- **Hostname:** Set to `gitlab.local` for internal resolution
- **Port mapping:** Container port 80 mapped to host port 8880
- **Restart policy:** `unless-stopped` ensures automatic restart
- **Shared memory:** 256MB allocated for GitLab operations
- **External URL:** Configured to match the local access URL

The container includes volume mounts for persistent data storage, ensuring that GitLab data survives container restarts and updates.

### argocd-gitlab-app.yaml

This ArgoCD Application resource defines how ArgoCD should monitor and sync the GitLab repository. The application specifies the GitLab repository URL using the Docker container's internal IP address (`172.17.0.1:8880`), which allows ArgoCD running inside the Kubernetes cluster to access GitLab running in Docker.

The `path: configs` specification tells ArgoCD to monitor only the configs directory within the repository, where Kubernetes manifests are stored. The `targetRevision: main` ensures ArgoCD tracks the main branch.

The destination configuration points to the local Kubernetes cluster and specifies the `dev` namespace for application deployment.

Automated sync policies are enabled with `prune: true` to remove resources that are no longer defined in Git, and `selfHeal: true` to automatically correct manual changes that deviate from the Git state.

### Utility Scripts

**restart_port_forwarding.sh:** This script manages port forwarding for all services. It kills existing port forwards and establishes new ones for ArgoCD (8082), GitLab (8880), and the application (8888). The script includes checks to ensure services exist before attempting to forward ports.

**show_access_info.sh:** A comprehensive status script that displays access URLs, credentials, and system status. It retrieves passwords from saved files or Docker containers and performs connectivity checks to verify service accessibility.

**clean_all.sh:** A complete cleanup script that removes all components including Docker containers, K3d clusters, kubectl configurations, and generated files. This script ensures a clean environment for fresh installations.

**reset_k3d_env.sh:** A focused cleanup script that removes only K3d and Kubernetes components while preserving Docker installations. Useful for resetting the cluster without affecting the underlying Docker environment.

## Testing and Verification

**Initial Deployment Verification:**

```bash
# Check ArgoCD application status
argocd app get ftegan-app-gitlab

# Verify pods are running in dev namespace
kubectl get pods -n dev

# Test application response
curl http://localhost:8888
# Expected: {"status": "ok", "message": "My ✨Flamboyant✨ app v2🥈"}
```

**GitOps Workflow Testing:**

```bash
# 1. Clone the GitLab repository
git clone http://localhost:8880/root/ftegan.git
cd ftegan

# 2. Change application version in deployment.yaml
sed -i 's/aidarngdev\/ftegan:v2/aidarngdev\/ftegan:v1/' configs/deployment.yaml

# 3. Commit and push changes
git add configs/deployment.yaml
git commit -m "Update application to version v1"
git push origin main

# 4. Watch ArgoCD detect and sync changes
argocd app get ftegan-app-gitlab
kubectl get pods -n dev -w

# 5. Verify version change
curl http://localhost:8888
# Expected: Different response showing v1 message
```

**Complete System Verification:**

```bash
# Check all components
echo "=== BONUS TASK VERIFICATION ==="

echo "1. K3d Cluster:"
kubectl get nodes

echo "2. ArgoCD:"
kubectl get pods -n argocd

echo "3. GitLab:"
docker ps | grep gitlab-ce

echo "4. Application:"
kubectl get pods -n dev
curl http://localhost:8888

echo "5. ArgoCD Application:"
argocd app get ftegan-app-gitlab
```

The verification demonstrates that changes made in GitLab are automatically detected by ArgoCD and deployed to the Kubernetes cluster, completing the GitOps workflow. The system provides a production-ready CI/CD pipeline suitable for modern DevOps practices.

# Resources

- **GitLab Documentation:** https://docs.gitlab.com/
- **GitLab Docker Images:** https://hub.docker.com/r/gitlab/gitlab-ce
- **ArgoCD GitOps Guide:** https://argo-cd.readthedocs.io/en/stable/user-guide/application/
- **K3d Local Development:** https://k3d.io/v5.4.6/
- **GitOps Principles:** https://www.gitops.tech/
- **Kubernetes GitOps Workflow:** https://kubernetes.io/docs/concepts/configuration/organize-cluster-access-kubeconfig/
- **Docker Container Management:** https://docs.docker.com/engine/reference/run/
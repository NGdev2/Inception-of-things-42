#!/bin/bash
set -e

GREEN="\033[32m"
YELLOW="\033[33m"
RED="\033[31m"
BLUE="\033[34m"
RESET="\033[0m"

echo -e "${GREEN}🚀 Setting up GitLab with K3d cluster integration...${RESET}"

# Step 1: Ensure K3d cluster is running
CLUSTER_NAME=fteganS
if ! k3d cluster list | grep -q "$CLUSTER_NAME"; then
  echo -e "${RED}❌ K3d cluster '$CLUSTER_NAME' not found. Please run setup_k3d_cluster.sh first.${RESET}"
  exit 1
fi

# Step 2: Install Helm if missing
if ! command -v helm &> /dev/null; then
  echo -e "${GREEN}📦 Installing Helm...${RESET}"
  curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash
else
  echo -e "${YELLOW}✔️ Helm already installed${RESET}"
fi

# Step 3: Create GitLab namespace
echo -e "${GREEN}📁 Creating namespace 'gitlab'...${RESET}"
kubectl create namespace gitlab --dry-run=client -o yaml | kubectl apply -f -

# Step 4: Add GitLab Helm repo
echo -e "${GREEN}➕ Adding GitLab Helm repo...${RESET}"
helm repo add gitlab https://charts.gitlab.io/
helm repo update

# Step 5: Create improved GitLab values file
echo -e "${GREEN}📝 Creating GitLab configuration...${RESET}"
cat > gitlab-values-k3d.yaml << 'EOF'
global:
  hosts:
    domain: gitlab.local
    externalIP: 127.0.0.1
  
  ingress:
    configureCertmanager: false
    tls:
      enabled: false
    class: traefik

  # Reduce resource requirements for local development
  nodeSelector: {}

# Disable components not needed for local dev
certmanager:
  install: false

nginx-ingress:
  enabled: false

# GitLab Runner configuration for K3d
gitlab-runner:
  runners:
    config: |
      [[runners]]
        [runners.kubernetes]
          namespace = "gitlab"
          image = "ubuntu:20.04"
          [[runners.kubernetes.volumes.empty_dir]]
            name = "docker-certs"
            mount_path = "/certs/client"
            medium = "Memory"

# Reduce replica counts for local development
gitlab:
  webservice:
    replicaCount: 1
    service:
      type: NodePort
      nodePort: 30080
  
  sidekiq:
    replicaCount: 1

# PostgreSQL configuration
postgresql:
  primary:
    persistence:
      size: 2Gi

# Redis configuration  
redis:
  master:
    persistence:
      size: 1Gi

# Disable Prometheus for resource savings
prometheus:
  install: false

# Minio configuration
minio:
  persistence:
    size: 2Gi
EOF

# Step 6: Install GitLab with Helm
echo -e "${GREEN}🚀 Installing GitLab via Helm (this may take 10-15 minutes)...${RESET}"
helm upgrade --install gitlab gitlab/gitlab \
  -f gitlab-values-k3d.yaml \
  --namespace gitlab \
  --timeout 1200s \
  --set global.edition=ce

# Step 7: Wait for GitLab to be ready
echo -e "${YELLOW}⏳ Waiting for GitLab pods to be ready...${RESET}"
kubectl wait --for=condition=ready pod -l app=webservice -n gitlab --timeout=600s

# Step 8: Setup port forwarding
echo -e "${GREEN}🌐 Setting up port forwarding...${RESET}"
kubectl port-forward -n gitlab svc/gitlab-webservice-default 8880:8181 > /dev/null 2>&1 &
echo -e "${YELLOW}💡 GitLab will be accessible at: http://localhost:8880${RESET}"

# Step 9: Get initial root password
echo -e "${GREEN}🔑 Retrieving initial GitLab root password...${RESET}"
kubectl get secret gitlab-gitlab-initial-root-password -n gitlab -ojsonpath='{.data.password}' | base64 --decode > gitlab-root-password.txt
echo -e "${YELLOW}📄 Root password saved to: gitlab-root-password.txt${RESET}"

# Step 10: Create ArgoCD integration
echo -e "${GREEN}🔗 Creating ArgoCD integration...${RESET}"
cat > argocd-gitlab-app.yaml << 'EOF'
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: ftegan-app-gitlab
  namespace: argocd
spec:
  project: default
  source:
    repoURL: 'http://gitlab.local/root/ftegan-k8s-config.git'  # Update this to your GitLab repo
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

echo -e "${GREEN}✅ GitLab setup complete!${RESET}"
echo ""
echo -e "${BLUE}📋 Next Steps:${RESET}"
echo -e "${YELLOW}1. Access GitLab at: http://localhost:8880${RESET}"
echo -e "${YELLOW}2. Login with username: root${RESET}"
echo -e "${YELLOW}3. Password: $(cat gitlab-root-password.txt)${RESET}"
echo -e "${YELLOW}4. Create a new project: ftegan-k8s-config${RESET}"
echo -e "${YELLOW}5. Push your deployment configs to the new repo${RESET}"
echo -e "${YELLOW}6. Update argocd-gitlab-app.yaml with your repo URL${RESET}"
echo -e "${YELLOW}7. Apply: kubectl apply -f argocd-gitlab-app.yaml${RESET}"
echo ""
echo -e "${GREEN}🔧 Useful commands:${RESET}"
echo -e "Monitor GitLab pods: ${YELLOW}kubectl get pods -n gitlab -w${RESET}"
echo -e "Stop port-forward: ${YELLOW}kill \$(lsof -ti:8880)${RESET}"
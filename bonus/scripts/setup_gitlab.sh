#!/bin/bash
set -e

GREEN="\033[32m"
YELLOW="\033[33m"
RED="\033[31m"
RESET="\033[0m"

echo -e "${GREEN}Starting GitLab setup on K3d cluster...${RESET}"

# Step 1: Install Helm if missing
if ! command -v helm &> /dev/null; then
  echo -e "${GREEN}📦 Installing Helm...${RESET}"
  curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash
else
  echo -e "${YELLOW}✔️ Helm already installed${RESET}"
fi

# Step 2: Create 'gitlab' namespace
echo -e "${GREEN}📁 Creating namespace 'gitlab'...${RESET}"
kubectl create namespace gitlab --dry-run=client -o yaml | kubectl apply -f -

# Step 3: Add GitLab Helm repo
echo -e "${GREEN}➕ Adding GitLab Helm repo...${RESET}"
if ! helm repo list | grep -q "gitlab"; then
  echo -e "${YELLOW}Adding GitLab Helm repository...${RESET}"
  helm repo add gitlab https://charts.gitlab.io/
else
  echo -e "${YELLOW}GitLab Helm repository already exists — skipping.${RESET}"
fi
helm repo update

# Step 4: Check for values file
if [[ ! -f gitlab-values.yaml ]]; then
  echo -e "${RED}❌ Missing gitlab-values.yaml config file. Please create it before running this script.${RESET}"
  exit 1
fi

# Step 5: Install GitLab with Helm
echo -e "${GREEN}🚀 Installing GitLab via Helm...${RESET}"
helm upgrade --install gitlab gitlab/gitlab \
  -f gitlab-values.yaml \
  --namespace gitlab \
  --timeout 600s

echo -e "${GREEN}✅ GitLab install initiated. It may take 5–10 minutes. Monitor with:${RESET}"
echo -e "${YELLOW}kubectl get pods -n gitlab -w${RESET}"

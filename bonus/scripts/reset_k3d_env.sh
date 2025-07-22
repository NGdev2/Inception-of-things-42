#!/bin/bash
set -e

# Define colors
GREEN="\033[32m"
RED="\033[31m"
YELLOW="\033[33m"
RESET="\033[0m"

echo -e "${GREEN}🧹 Resetting K3d environment...${RESET}"

# Stop port-forwarding on 8082 and 8088 if running
echo -e "${YELLOW}🔌 Stopping port-forwards on 8082 and 8088...${RESET}"
kill $(lsof -ti:8082) 2>/dev/null || true
kill $(lsof -ti:8880) 2>/dev/null || true

# Optional: Unset KUBECONFIG
echo -e "${YELLOW}🧹 Unsetting KUBECONFIG (if set)...${RESET}"
unset KUBECONFIG

# Delete the K3d cluster if it exists
CLUSTER_NAME=fteganS
if k3d cluster list | grep -q "$CLUSTER_NAME"; then
  echo -e "${YELLOW}🗑️ Deleting K3d cluster '$CLUSTER_NAME'...${RESET}"
  k3d cluster delete "$CLUSTER_NAME"
else
  echo -e "${YELLOW}⚠️ K3d cluster '$CLUSTER_NAME' not found — skipping delete.${RESET}"
fi

# Optional: Remove Argo CD CLI
echo -e "${YELLOW}❌ Removing Argo CD CLI (if installed)...${RESET}"
sudo rm -f /usr/local/bin/argocd

# Remove Argo CD and dev namespaces
echo -e "${YELLOW}🚮 Deleting namespaces 'argocd' and 'dev'...${RESET}"
kubectl delete namespace argocd --ignore-not-found
kubectl delete namespace dev --ignore-not-found

# 🧹 GitLab Cleanup
echo -e "${YELLOW}🧹 Uninstalling GitLab Helm release (if exists)...${RESET}"
helm uninstall gitlab -n gitlab 2>/dev/null || true

echo -e "${YELLOW}🚮 Deleting namespace 'gitlab'...${RESET}"
kubectl delete namespace gitlab --ignore-not-found --wait=true

echo -e "${YELLOW}🧼 Checking and deleting leftover GitLab PVs...${RESET}"
kubectl get pv | grep gitlab | awk '{print $1}' | xargs -r kubectl delete pv

# Remove any leftover Docker containers with k3d in name
K3D_CONTAINERS=$(docker ps -aq --filter "name=k3d")
if [ -n "$K3D_CONTAINERS" ]; then
  echo -e "${YELLOW}🧼 Removing leftover Docker containers...${RESET}"
  docker rm -f $K3D_CONTAINERS
else
  echo -e "${YELLOW}✅ No leftover Docker containers to remove.${RESET}"
fi

rm -f argocd-password.txt 2>/dev/null || true

echo -e "${GREEN}✅ Full K3d and GitLab environment reset complete.${RESET}"

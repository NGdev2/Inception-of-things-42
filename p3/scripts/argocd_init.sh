#!/bin/bash
set -e

# Define colors
GREEN="\033[32m"
RED="\033[31m"
YELLOW="\033[33m"
RESET="\033[0m"

echo -e "${GREEN}Installing Argo CD CLI...${RESET}"
curl -sSL -o argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
chmod +x argocd
sudo mv argocd /usr/local/bin/

echo -e "${GREEN}Starting port-forwarding for Argo CD server (localhost:8082)...${RESET}"
kubectl port-forward svc/argocd-server -n argocd 8082:443 > /dev/null 2>&1 &
echo -e "${YELLOW}💡 Port-forwarding is running in the background. Use 'kill \$(lsof -ti:8082)' to stop it later.${RESET}"

echo -e "${GREEN}Applying Argo CD Application manifest...${RESET}"
kubectl apply -f argocd-app.yaml

echo -e "${GREEN}Logging into Argo CD CLI...${RESET}"
argocd login localhost:8082 \
  --username admin \
  --password $(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)

echo -e "${GREEN}Argo CD setup complete! You can now run 'argocd app list' to view your applications.${RESET}"

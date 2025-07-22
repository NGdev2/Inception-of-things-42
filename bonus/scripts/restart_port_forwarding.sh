#!/bin/bash
set -e

# Colors
GREEN="\033[32m"
YELLOW="\033[33m"
BLUE="\033[34m"
RESET="\033[0m"

echo -e "${YELLOW}🔌 Restarting all port forwarding...${RESET}"

# Stop existing port forwards
pkill -f "port-forward" 2>/dev/null || true
sleep 2

# Start ArgoCD port forward
echo -e "${BLUE}Starting ArgoCD port forward (8082)...${RESET}"
kubectl port-forward -n argocd svc/argocd-server 8082:443 > /dev/null 2>&1 &

# Start GitLab port forward (only if GitLab container is running)
if docker ps | grep -q gitlab-ce; then
    echo -e "${BLUE}Starting GitLab port forward (8880)...${RESET}"
    # GitLab is running in Docker, no port forward needed - it's already on 8880
    echo -e "${GREEN}✅ GitLab accessible at: http://localhost:8880${RESET}"
else
    echo -e "${YELLOW}⚠️ GitLab container not running${RESET}"
fi

# Start App port forward (only if app service exists)
if kubectl get svc ftegan-app -n dev 2>/dev/null; then
    echo -e "${BLUE}Starting App port forward (8888)...${RESET}"
    kubectl port-forward -n dev svc/ftegan-app 8888:80 > /dev/null 2>&1 &
else
    echo -e "${YELLOW}⚠️ App service not found in dev namespace${RESET}"
fi

sleep 2
echo -e "${GREEN}✅ Port forwarding restarted${RESET}"
echo ""
echo -e "${BLUE}📋 Access URLs:${RESET}"
echo -e "  • ArgoCD: https://localhost:8082"
echo -e "  • GitLab: http://localhost:8880"  
echo -e "  • App: http://localhost:8888"
echo ""
echo -e "${YELLOW}🔍 Verify with: lsof -i :8082,8880,8888${RESET}"
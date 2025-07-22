#!/bin/bash

# Colors
GREEN="\033[32m"
BLUE="\033[34m"
YELLOW="\033[33m"
RED="\033[31m"
PURPLE="\033[35m"
RESET="\033[0m"

echo -e "${PURPLE}🎯 BONUS TASK ACCESS INFORMATION${RESET}"
echo -e "${BLUE}================================${RESET}"
echo ""

# ArgoCD Information
echo -e "${GREEN}🔧 ArgoCD:${RESET}"
if [ -f "argocd-password.txt" ]; then
    ARGOCD_PASSWORD=$(cat argocd-password.txt)
    echo -e "  URL: https://localhost:8082"
    echo -e "  Username: admin"
    echo -e "  Password: $ARGOCD_PASSWORD"
    
    # Check if ArgoCD is accessible
    if curl -k -s https://localhost:8082/healthz >/dev/null 2>&1; then
        echo -e "  Status: ${GREEN}✅ Accessible${RESET}"
    else
        echo -e "  Status: ${RED}❌ Not accessible (check port forwarding)${RESET}"
    fi
else
    echo -e "  ${YELLOW}⚠️ Password file not found${RESET}"
fi

echo ""

# GitLab Information
echo -e "${GREEN}🦊 GitLab:${RESET}"
if [ -f "gitlab-root-password.txt" ]; then
    GITLAB_PASSWORD=$(cat gitlab-root-password.txt)
    echo -e "  URL: http://localhost:8880"
    echo -e "  Username: root"
    echo -e "  Password: $GITLAB_PASSWORD"
    
    # Check if GitLab is accessible
    if curl -s http://localhost:8880 >/dev/null 2>&1; then
        echo -e "  Status: ${GREEN}✅ Accessible${RESET}"
    else
        echo -e "  Status: ${RED}❌ Not accessible (check if container is running)${RESET}"
    fi
elif docker ps | grep -q gitlab-ce; then
    echo -e "  URL: http://localhost:8880"
    echo -e "  Username: root"
    echo -e "  Password: ${YELLOW}Getting password...${RESET}"
    
    # Try to get password from container
    if docker exec gitlab-ce test -f /etc/gitlab/initial_root_password 2>/dev/null; then
        GITLAB_PASSWORD=$(docker exec gitlab-ce cat /etc/gitlab/initial_root_password | grep 'Password:' | awk '{print $2}' 2>/dev/null || echo "")
        if [ -n "$GITLAB_PASSWORD" ]; then
            echo "$GITLAB_PASSWORD" > gitlab-root-password.txt
            echo -e "  Password: $GITLAB_PASSWORD"
            echo -e "  Status: ${GREEN}✅ Accessible${RESET}"
        else
            echo -e "  Password: ${YELLOW}Use: docker exec -it gitlab-ce cat /etc/gitlab/initial_root_password${RESET}"
        fi
    else
        echo -e "  Password: ${YELLOW}Still initializing...${RESET}"
    fi
else
    echo -e "  ${RED}❌ GitLab container not running${RESET}"
    echo -e "  ${YELLOW}💡 Start with: ./start_gitlab_ce_docker.sh${RESET}"
fi

echo ""

# Application Information
echo -e "${GREEN}🐍 Application:${RESET}"
echo -e "  URL: http://localhost:8888"

# Check if app is accessible
if curl -s http://localhost:8888 >/dev/null 2>&1; then
    APP_RESPONSE=$(curl -s http://localhost:8888)
    echo -e "  Status: ${GREEN}✅ Accessible${RESET}"
    echo -e "  Response: $APP_RESPONSE"
else
    echo -e "  Status: ${RED}❌ Not accessible (check if deployed and port forwarding)${RESET}"
fi

echo ""

# System Status
echo -e "${GREEN}🔍 System Status:${RESET}"

# K3d cluster
if k3d cluster list | grep -q "fteganS"; then
    echo -e "  K3d Cluster: ${GREEN}✅ Running${RESET}"
else
    echo -e "  K3d Cluster: ${RED}❌ Not running${RESET}"
fi

# GitLab container
if docker ps | grep -q gitlab-ce; then
    echo -e "  GitLab Container: ${GREEN}✅ Running${RESET}"
else
    echo -e "  GitLab Container: ${RED}❌ Not running${RESET}"
fi

# ArgoCD pods
if kubectl get pods -n argocd 2>/dev/null | grep -q "Running"; then
    echo -e "  ArgoCD Pods: ${GREEN}✅ Running${RESET}"
else
    echo -e "  ArgoCD Pods: ${RED}❌ Not running${RESET}"
fi

# Application pods
if kubectl get pods -n dev 2>/dev/null | grep -q "Running"; then
    echo -e "  App Pods: ${GREEN}✅ Running${RESET}"
else
    echo -e "  App Pods: ${RED}❌ Not running${RESET}"
fi

echo ""

# Useful Commands
echo -e "${GREEN}🔧 Useful Commands:${RESET}"
echo -e "  Monitor ArgoCD: ${YELLOW}kubectl get pods -n argocd${RESET}"
echo -e "  Monitor App: ${YELLOW}kubectl get pods -n dev${RESET}"
echo -e "  ArgoCD Apps: ${YELLOW}argocd app list${RESET}"
echo -e "  Restart ports: ${YELLOW}./restart_port_forwarding.sh${RESET}"
echo -e "  Check GitLab: ${YELLOW}docker logs gitlab-ce${RESET}"

echo ""

# Port Forwarding Status
echo -e "${GREEN}🔌 Port Forwarding Status:${RESET}"
PORT_STATUS=$(lsof -i :8082,8880,8888 2>/dev/null || echo "No port forwards active")
if [ "$PORT_STATUS" != "No port forwards active" ]; then
    echo -e "  ${GREEN}Active port forwards detected${RESET}"
else
    echo -e "  ${YELLOW}No port forwards active - run ./restart_port_forwarding.sh${RESET}"
fi
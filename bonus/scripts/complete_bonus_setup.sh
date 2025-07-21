#!/bin/bash
set -e

# Colors
GREEN="\033[32m"
YELLOW="\033[33m"
RED="\033[31m"
BLUE="\033[34m"
PURPLE="\033[35m"
RESET="\033[0m"

echo -e "${PURPLE}🎯 BONUS TASK: Complete GitLab + K3d + ArgoCD Setup${RESET}"
echo -e "${BLUE}This script will set up the complete environment for the bonus task${RESET}"
echo ""

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to wait for pods to be ready
wait_for_pods() {
    local namespace=$1
    local app_label=$2
    local timeout=${3:-300}
    
    echo -e "${YELLOW}⏳ Waiting for pods with label app=$app_label in namespace $namespace...${RESET}"
    kubectl wait --for=condition=ready pod -l app=$app_label -n $namespace --timeout=${timeout}s || {
        echo -e "${RED}❌ Timeout waiting for pods to be ready${RESET}"
        kubectl get pods -n $namespace
        return 1
    }
}

# Step 1: Setup base environment
echo -e "${GREEN}📦 Step 1: Setting up base K3d environment...${RESET}"
if [ ! -f "./setup_k3d_cluster.sh" ]; then
    echo -e "${RED}❌ setup_k3d_cluster.sh not found. Please ensure you're in the correct directory.${RESET}"
    exit 1
fi

chmod +x ./setup_k3d_cluster.sh
./setup_k3d_cluster.sh

# Wait for ArgoCD to be ready
echo -e "${YELLOW}⏳ Waiting for ArgoCD to be ready...${RESET}"
wait_for_pods "argocd" "argocd-server" 600

# Step 2: Setup GitLab
echo -e "${GREEN}🦊 Step 2: Setting up GitLab...${RESET}"
chmod +x ./setup_gitlab.sh
./setup_gitlab.sh

# Wait for GitLab to be ready
echo -e "${YELLOW}⏳ Waiting for GitLab to be ready (this can take 10-15 minutes)...${RESET}"
sleep 60  # Give GitLab some time to start initializing
wait_for_pods "gitlab" "webservice" 900

# Step 3: Setup ArgoCD integration
echo -e "${GREEN}🔗 Step 3: Setting up ArgoCD CLI and integration...${RESET}"
chmod +x ./argocd_init.sh
./argocd_init.sh

# Step 4: Create GitLab project configuration
echo -e "${GREEN}📋 Step 4: Creating GitLab CI/CD configuration...${RESET}"

# Create configs directory if it doesn't exist
mkdir -p configs

# Copy Kubernetes manifests to configs directory
cp deployment.yaml configs/ 2>/dev/null || echo -e "${YELLOW}⚠️  deployment.yaml not found in root, please ensure it's in configs/${RESET}"
cp service.yaml configs/ 2>/dev/null || echo -e "${YELLOW}⚠️  service.yaml not found in root, please ensure it's in configs/${RESET}"

# Create GitLab Runner configuration for K3d
cat > gitlab-runner-values.yaml << 'EOF'
gitlabUrl: http://gitlab-webservice-default.gitlab.svc.cluster.local:8181
runnerToken: ""  # This will need to be set manually
runners:
  config: |
    [[runners]]
      name = "k3d-runner"
      url = "http://gitlab-webservice-default.gitlab.svc.cluster.local:8181"
      token = "__RUNNER_TOKEN__"
      executor = "kubernetes"
      [runners.kubernetes]
        namespace = "gitlab"
        image = "ubuntu:20.04"
        pull_policy = "if-not-present"
      [[runners.kubernetes.volumes.empty_dir]]
        name = "docker-certs"
        mount_path = "/certs/client"
        medium = "Memory"
EOF

# Step 5: Get connection information
echo -e "${GREEN}🔑 Step 5: Retrieving access information...${RESET}"

# Get ArgoCD password
ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)

# Get GitLab password (if available)
GITLAB_PASSWORD=""
if kubectl get secret gitlab-gitlab-initial-root-password -n gitlab &>/dev/null; then
    GITLAB_PASSWORD=$(kubectl get secret gitlab-gitlab-initial-root-password -n gitlab -ojsonpath='{.data.password}' | base64 --decode)
fi

# Step 6: Setup port forwarding
echo -e "${GREEN}🌐 Step 6: Setting up port forwarding...${RESET}"

# Kill existing port forwards
pkill -f "port-forward" 2>/dev/null || true
sleep 2

# Start port forwards
kubectl port-forward -n argocd svc/argocd-server 8082:443 > /dev/null 2>&1 &
kubectl port-forward -n gitlab svc/gitlab-webservice-default 8880:8181 > /dev/null 2>&1 &
kubectl port-forward -n dev svc/ftegan-app 8888:80 > /dev/null 2>&1 &

echo -e "${YELLOW}💤 Waiting for port forwards to be established...${RESET}"
sleep 5

# Step 7: Create helper scripts
echo -e "${GREEN}📝 Step 7: Creating helper scripts...${RESET}"

# Create a script to show all access information
cat > show_access_info.sh << EOF
#!/bin/bash
echo -e "\033[32m🎯 BONUS TASK ACCESS INFORMATION\033[0m"
echo -e "\033[34m================================\033[0m"
echo ""
echo -e "\033[33m🔧 ArgoCD:\033[0m"
echo -e "  URL: https://localhost:8082"
echo -e "  Username: admin"
echo -e "  Password: $ARGOCD_PASSWORD"
echo ""
echo -e "\033[33m🦊 GitLab:\033[0m"
echo -e "  URL: http://localhost:8880"
echo -e "  Username: root"
echo -e "  Password: $GITLAB_PASSWORD"
echo ""
echo -e "\033[33m🐍 Your App:\033[0m"
echo -e "  URL: http://localhost:8888"
echo ""
echo -e "\033[33m🔍 Useful Commands:\033[0m"
echo -e "  Monitor GitLab: kubectl get pods -n gitlab"
echo -e "  Monitor ArgoCD: kubectl get pods -n argocd"
echo -e "  Monitor App: kubectl get pods -n dev"
echo -e "  Stop port-forwards: pkill -f port-forward"
echo ""
echo -e "\033[33m📋 Next Steps:\033[0m"
echo -e "  1. Access GitLab and create a new project"
echo -e "  2. Push your Kubernetes configs to the GitLab repository"
echo -e "  3. Configure GitLab CI/CD with Docker credentials"
echo -e "  4. Set up ArgoCD to sync with your GitLab repository"
EOF

chmod +x show_access_info.sh

# Create a script to restart port forwarding
cat > restart_port_forwarding.sh << 'EOF'
#!/bin/bash
echo "🔌 Restarting port forwarding..."
pkill -f "port-forward" 2>/dev/null || true
sleep 2
kubectl port-forward -n argocd svc/argocd-server 8082:443 > /dev/null 2>&1 &
kubectl port-forward -n gitlab svc/gitlab-webservice-default 8880:8181 > /dev/null 2>&1 &
kubectl port-forward -n dev svc/ftegan-app 8888:80 > /dev/null 2>&1 &
echo "✅ Port forwarding restarted"
EOF

chmod +x restart_port_forwarding.sh

# Final summary
echo ""
echo -e "${PURPLE}🎉 BONUS TASK SETUP COMPLETE! 🎉${RESET}"
echo -e "${BLUE}================================${RESET}"
echo ""
echo -e "${GREEN}✅ Environment Status:${RESET}"
echo -e "  • K3d cluster: Running"
echo -e "  • ArgoCD: Ready"
echo -e "  • GitLab: Ready"
echo -e "  • Namespaces: argocd, gitlab, dev"
echo ""
echo -e "${YELLOW}📋 Access Information:${RESET}"
echo -e "  • ArgoCD: https://localhost:8082 (admin / $ARGOCD_PASSWORD)"
if [ -n "$GITLAB_PASSWORD" ]; then
    echo -e "  • GitLab: http://localhost:8880 (root / $GITLAB_PASSWORD)"
else
    echo -e "  • GitLab: http://localhost:8880 (root / retrieving...)"
fi
echo -e "  • Your App: http://localhost:8888"
echo ""
echo -e "${BLUE}📁 Files Created:${RESET}"
echo -e "  • gitlab-values-k3d.yaml - GitLab Helm configuration"
echo -e "  • gitlab-runner-values.yaml - GitLab Runner configuration"
echo -e "  • show_access_info.sh - Display all access information"
echo -e "  • restart_port_forwarding.sh - Restart port forwarding"
echo ""
echo -e "${YELLOW}🔄 Next Steps:${RESET}"
echo -e "  1. Run: ./show_access_info.sh"
echo -e "  2. Access GitLab and create your project"
echo -e "  3. Configure GitLab CI/CD variables (DOCKER_USERNAME, DOCKER_PASSWORD)"
echo -e "  4. Push your code and watch the magic happen! ✨"
echo ""
echo -e "${GREEN}🔧 Troubleshooting:${RESET}"
echo -e "  • If services are unreachable: ./restart_port_forwarding.sh"
echo -e "  • To restart everything: ./reset_k3d_env.sh && ./complete_bonus_setup.sh"
echo -e "  • To clean everything: ./clean_all.sh"
#!/bin/bash
set -e

# Define colors
GREEN="\033[32m"
RED="\033[31m"
YELLOW="\033[33m"
BLUE="\033[34m"
RESET="\033[0m"

echo -e "${GREEN}🚀 Starting ArgoCD initialization...${RESET}"

# Function to wait for pods to be ready
wait_for_pods_ready() {
    local namespace=$1
    local label_selector=$2
    local timeout=${3:-600}
    local check_interval=10
    local elapsed=0

    echo -e "${YELLOW}⏳ Waiting for pods with selector '$label_selector' in namespace '$namespace'...${RESET}"
    
    while [ $elapsed -lt $timeout ]; do
        if kubectl get pods -n "$namespace" -l "$label_selector" --no-headers 2>/dev/null | grep -q "Running"; then
            echo -e "${GREEN}✅ Pods are running, checking readiness...${RESET}"
            if kubectl wait --for=condition=ready pod -l "$label_selector" -n "$namespace" --timeout=60s 2>/dev/null; then
                echo -e "${GREEN}✅ Pods are ready!${RESET}"
                return 0
            fi
        fi
        
        echo -e "${YELLOW}⏳ Still waiting... ($elapsed/$timeout seconds)${RESET}"
        sleep $check_interval
        elapsed=$((elapsed + check_interval))
    done
    
    echo -e "${RED}❌ Timeout waiting for pods to be ready${RESET}"
    kubectl get pods -n "$namespace" -l "$label_selector" 2>/dev/null || true
    return 1
}

# Function to wait for ArgoCD server to be accessible
wait_for_argocd_server() {
    local timeout=300
    local check_interval=10
    local elapsed=0

    echo -e "${YELLOW}⏳ Waiting for ArgoCD server to be accessible...${RESET}"
    
    while [ $elapsed -lt $timeout ]; do
        if kubectl get pods -n argocd -l app.kubernetes.io/name=argocd-server --no-headers 2>/dev/null | grep -q "Running"; then
            echo -e "${GREEN}✅ ArgoCD server pod is running${RESET}"
            return 0
        fi
        
        echo -e "${YELLOW}⏳ ArgoCD server not ready yet... ($elapsed/$timeout seconds)${RESET}"
        sleep $check_interval
        elapsed=$((elapsed + check_interval))
    done
    
    echo -e "${RED}❌ Timeout waiting for ArgoCD server${RESET}"
    return 1
}

# Function to wait for ArgoCD secret
wait_for_argocd_secret() {
    local timeout=180
    local check_interval=5
    local elapsed=0

    echo -e "${YELLOW}⏳ Waiting for ArgoCD initial admin secret...${RESET}"
    
    while [ $elapsed -lt $timeout ]; do
        if kubectl get secret argocd-initial-admin-secret -n argocd 2>/dev/null >/dev/null; then
            echo -e "${GREEN}✅ ArgoCD secret is available${RESET}"
            return 0
        fi
        
        echo -e "${YELLOW}⏳ Secret not ready yet... ($elapsed/$timeout seconds)${RESET}"
        sleep $check_interval
        elapsed=$((elapsed + check_interval))
    done
    
    echo -e "${RED}❌ Timeout waiting for ArgoCD secret${RESET}"
    return 1
}

# Check if ArgoCD namespace exists
if ! kubectl get namespace argocd >/dev/null 2>&1; then
    echo -e "${YELLOW}📁 Creating ArgoCD namespace...${RESET}"
    kubectl create namespace argocd
fi

# Check if ArgoCD is already installed
if kubectl get deployment argocd-server -n argocd >/dev/null 2>&1; then
    echo -e "${YELLOW}✅ ArgoCD is already installed${RESET}"
else
    echo -e "${GREEN}📦 Installing ArgoCD...${RESET}"
    kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
fi

# Wait for ArgoCD server to be ready
echo -e "${GREEN}⏳ Waiting for ArgoCD components to be ready...${RESET}"

# Wait for server pod first
if ! wait_for_argocd_server; then
    echo -e "${RED}❌ ArgoCD server failed to start${RESET}"
    kubectl get pods -n argocd
    exit 1
fi

# Wait for the secret to be created
if ! wait_for_argocd_secret; then
    echo -e "${RED}❌ ArgoCD secret was not created${RESET}"
    echo -e "${YELLOW}📋 Checking ArgoCD server logs:${RESET}"
    kubectl logs -n argocd -l app.kubernetes.io/name=argocd-server --tail=20
    exit 1
fi

# Install ArgoCD CLI if not present
if ! command -v argocd &> /dev/null; then
    echo -e "${GREEN}📥 Installing Argo CD CLI...${RESET}"
    curl -sSL -o argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
    chmod +x argocd
    sudo mv argocd /usr/local/bin/
else
    echo -e "${YELLOW}✅ ArgoCD CLI already installed${RESET}"
fi

# Get and save the initial admin password
echo -e "${GREEN}🔑 Retrieving ArgoCD initial admin password...${RESET}"
ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
echo "$ARGOCD_PASSWORD" > argocd-password.txt
echo -e "${GREEN}✅ Password saved to argocd-password.txt${RESET}"

# Setup port forwarding for ArgoCD
echo -e "${GREEN}🌐 Setting up ArgoCD port forwarding (localhost:8082)...${RESET}"
# Kill existing port forward if any
pkill -f "port-forward.*argocd-server" 2>/dev/null || true
sleep 2

# Start new port forward
kubectl port-forward svc/argocd-server -n argocd 8082:443 > /dev/null 2>&1 &
echo -e "${YELLOW}💡 Port-forwarding is running in the background. Use 'pkill -f port-forward' to stop it later.${RESET}"

# Wait a bit for port forward to establish
sleep 5

# Test ArgoCD server accessibility
echo -e "${GREEN}🔍 Testing ArgoCD server accessibility...${RESET}"
if curl -k -s https://localhost:8082/healthz >/dev/null 2>&1; then
    echo -e "${GREEN}✅ ArgoCD server is accessible${RESET}"
else
    echo -e "${YELLOW}⚠️  ArgoCD server not immediately accessible (this is normal, it may take a moment)${RESET}"
fi

# Login to ArgoCD CLI (with retry logic)
echo -e "${GREEN}🔐 Logging into Argo CD CLI...${RESET}"
login_attempts=0
max_login_attempts=5

while [ $login_attempts -lt $max_login_attempts ]; do
    if argocd login localhost:8082 \
        --username admin \
        --password "$ARGOCD_PASSWORD" \
        --insecure 2>/dev/null; then
        echo -e "${GREEN}✅ Successfully logged into ArgoCD CLI${RESET}"
        break
    else
        login_attempts=$((login_attempts + 1))
        echo -e "${YELLOW}⏳ Login attempt $login_attempts/$max_login_attempts failed, retrying in 10 seconds...${RESET}"
        sleep 10
    fi
done

if [ $login_attempts -eq $max_login_attempts ]; then
    echo -e "${YELLOW}⚠️  Could not login to ArgoCD CLI automatically, but you can login manually later${RESET}"
fi

echo -e "${GREEN}✅ ArgoCD initialization complete!${RESET}"
echo ""
echo -e "${BLUE}📋 ArgoCD Access Information:${RESET}"
echo -e "  • URL: https://localhost:8082"
echo -e "  • Username: admin"
echo -e "  • Password: $ARGOCD_PASSWORD"
echo ""
echo -e "${YELLOW}📝 Next Steps:${RESET}"
echo -e "  1. Start GitLab: ./start_gitlab_ce_docker.sh"
echo -e "  2. Create GitLab project and upload configs"
echo -e "  3. Apply ArgoCD app: kubectl apply -f argocd-gitlab-app.yaml"
echo -e "  4. Access ArgoCD at https://localhost:8082"
echo ""
echo -e "${GREEN}🔧 Useful Commands:${RESET}"
echo -e "  • List apps: argocd app list"
echo -e "  • Check status: kubectl get pods -n argocd"
echo -e "  • Restart port-forward: pkill -f port-forward && kubectl port-forward svc/argocd-server -n argocd 8082:443 &"
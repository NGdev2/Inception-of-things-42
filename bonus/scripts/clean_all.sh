#!/bin/bash

# Define colors
GREEN="\033[32m"
RED="\033[31m"
YELLOW="\033[33m"
BLUE="\033[34m"
PURPLE="\033[35m"
RESET="\033[0m"

echo -e "${RED}💥 NUCLEAR CLEANUP - This will remove EVERYTHING Docker/k3d/k3s related!${RESET}"
echo -e "${YELLOW}⚠️  This will delete:${RESET}"
echo -e "  • All Docker containers (running and stopped)"
echo -e "  • All Docker images"
echo -e "  • All Docker volumes"
echo -e "  • All Docker networks"
echo -e "  • All k3d clusters and resources"
echo -e "  • All k3s installations"
echo -e "  • kubectl configuration"
echo -e "  • ArgoCD CLI"
echo -e "  • GitLab data and configurations"
echo -e "  • All generated files and passwords"
echo ""
read -p "Are you sure you want to continue? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Cleanup cancelled.${RESET}"
    exit 1
fi

echo -e "${GREEN}🚀 Starting nuclear cleanup...${RESET}"

# Stop all running processes
echo -e "${YELLOW}⏹️  Stopping all related processes...${RESET}"
sudo pkill -f kubectl 2>/dev/null || true
sudo pkill -f k3d 2>/dev/null || true
sudo pkill -f k3s 2>/dev/null || true
sudo pkill -f docker 2>/dev/null || true
sudo pkill -f helm 2>/dev/null || true

# Kill all port forwards
echo -e "${YELLOW}🔌 Killing all port forwards...${RESET}"
sudo pkill -f "port-forward" 2>/dev/null || true
sudo lsof -ti:8080,8082,8088,8880,8888,6443 | xargs -r kill -9 2>/dev/null || true

# Stop Docker service
echo -e "${YELLOW}🐳 Stopping Docker service...${RESET}"
sudo systemctl stop docker 2>/dev/null || true
sudo systemctl stop docker.socket 2>/dev/null || true

# Remove all k3d clusters
echo -e "${YELLOW}🗑️  Removing all k3d clusters...${RESET}"
k3d cluster list --no-headers 2>/dev/null | awk '{print $1}' | xargs -I {} k3d cluster delete {} 2>/dev/null || true

# Start Docker service for cleanup
echo -e "${YELLOW}🔄 Starting Docker for cleanup...${RESET}"
sudo systemctl start docker 2>/dev/null || true
sleep 3

# Stop and remove ALL Docker containers
echo -e "${YELLOW}🛑 Stopping and removing ALL Docker containers...${RESET}"
docker stop $(docker ps -aq) 2>/dev/null || true
docker rm -f $(docker ps -aq) 2>/dev/null || true

# Remove ALL Docker images
echo -e "${YELLOW}🖼️  Removing ALL Docker images...${RESET}"
docker rmi -f $(docker images -aq) 2>/dev/null || true

# Remove ALL Docker volumes
echo -e "${YELLOW}💾 Removing ALL Docker volumes...${RESET}"
docker volume rm $(docker volume ls -q) 2>/dev/null || true

# Remove ALL Docker networks (except default ones)
echo -e "${YELLOW}🌐 Removing ALL custom Docker networks...${RESET}"
docker network ls --format "{{.ID}} {{.Name}}" | grep -v -E "(bridge|host|none)" | awk '{print $1}' | xargs -r docker network rm 2>/dev/null || true

# Docker system prune everything
echo -e "${YELLOW}🧹 Docker system prune (everything)...${RESET}"
docker system prune -a -f --volumes 2>/dev/null || true

# Remove Docker build cache
echo -e "${YELLOW}🗂️  Removing Docker build cache...${RESET}"
docker builder prune -a -f 2>/dev/null || true

# Stop Docker service again
echo -e "${YELLOW}⏹️  Stopping Docker service...${RESET}"
sudo systemctl stop docker 2>/dev/null || true
sudo systemctl stop docker.socket 2>/dev/null || true

# Remove k3s completely
echo -e "${YELLOW}🗑️  Removing k3s installation...${RESET}"
if [ -f /usr/local/bin/k3s-uninstall.sh ]; then
    sudo /usr/local/bin/k3s-uninstall.sh 2>/dev/null || true
fi
if [ -f /usr/local/bin/k3s-agent-uninstall.sh ]; then
    sudo /usr/local/bin/k3s-agent-uninstall.sh 2>/dev/null || true
fi

# Remove k3s directories and files
echo -e "${YELLOW}📂 Removing k3s directories...${RESET}"
sudo rm -rf /var/lib/rancher/k3s 2>/dev/null || true
sudo rm -rf /etc/rancher/k3s 2>/dev/null || true
sudo rm -rf /var/lib/kubelet 2>/dev/null || true
sudo rm -rf /var/lib/cni 2>/dev/null || true
sudo rm -rf /opt/cni 2>/dev/null || true
sudo rm -rf /run/k3s 2>/dev/null || true
sudo rm -f /usr/local/bin/k3s 2>/dev/null || true

# Remove k3d binary
echo -e "${YELLOW}❌ Removing k3d binary...${RESET}"
sudo rm -f /usr/local/bin/k3d 2>/dev/null || true

# Remove ArgoCD CLI
echo -e "${YELLOW}❌ Removing ArgoCD CLI...${RESET}"
sudo rm -f /usr/local/bin/argocd 2>/dev/null || true
sudo rm -f /usr/local/bin/argocd-* 2>/dev/null || true

# Remove Helm
echo -e "${YELLOW}❌ Removing Helm...${RESET}"
sudo rm -f /usr/local/bin/helm 2>/dev/null || true

# Clean up kubectl configuration completely
echo -e "${YELLOW}📋 Cleaning kubectl configuration...${RESET}"
unset KUBECONFIG 2>/dev/null || true
export KUBECONFIG=""

# Backup and reset kubectl config
if [ -f ~/.kube/config ]; then
    echo -e "${BLUE}💾 Backing up kubectl config...${RESET}"
    cp ~/.kube/config ~/.kube/config.backup.$(date +%Y%m%d_%H%M%S) 2>/dev/null || true
fi

# Remove entire .kube directory and recreate
echo -e "${YELLOW}🗑️  Removing .kube directory...${RESET}"
rm -rf ~/.kube 2>/dev/null || true
mkdir -p ~/.kube 2>/dev/null || true

# Remove any kubectl contexts from shell environment
echo -e "${YELLOW}🧹 Cleaning shell environment...${RESET}"
unset KUBECONFIG
unset KUBECTL_CONTEXT

# Clean up /tmp for any k3d/k3s related files
echo -e "${YELLOW}🗑️  Cleaning temporary files...${RESET}"
sudo rm -rf /tmp/k3d-* 2>/dev/null || true
sudo rm -rf /tmp/k3s-* 2>/dev/null || true

# Clean up GitLab data directories
echo -e "${YELLOW}🦊 Cleaning GitLab data...${RESET}"
rm -rf ~/gitlab-data 2>/dev/null || true
rm -rf ~/gitlab-runner 2>/dev/null || true

# Remove generated files
echo -e "${YELLOW}🗑️  Removing generated files...${RESET}"
rm -f argocd-password.txt 2>/dev/null || true
rm -f gitlab-root-password.txt 2>/dev/null || true
rm -f gitlab-values-k3d.yaml 2>/dev/null || true
rm -f gitlab-runner-values.yaml 2>/dev/null || true
# rm -f argocd-gitlab-app.yaml 2>/dev/null || true
rm -f kubeconfig.yaml 2>/dev/null || true
# rm -f show_access_info.sh 2>/dev/null || true
# rm -f restart_port_forwarding.sh 2>/dev/null || true

# Remove any leftover mount points
echo -e "${YELLOW}🔧 Cleaning up mount points...${RESET}"
sudo umount /var/lib/rancher/k3s/agent/containerd/io.containerd.runtime.v2.task/k8s.io/*/rootfs 2>/dev/null || true
sudo umount /run/k3s/containerd/io.containerd.runtime.v2.task/k8s.io/*/rootfs 2>/dev/null || true

# Remove systemd services
echo -e "${YELLOW}🔧 Removing systemd services...${RESET}"
sudo systemctl disable k3s 2>/dev/null || true
sudo systemctl disable k3s-agent 2>/dev/null || true
sudo rm -f /etc/systemd/system/k3s*.service 2>/dev/null || true
sudo systemctl daemon-reload 2>/dev/null || true

# Start Docker service back up
echo -e "${YELLOW}🔄 Starting Docker service...${RESET}"
sudo systemctl start docker 2>/dev/null || true
sudo systemctl enable docker 2>/dev/null || true

# Verify cleanup
echo -e "${GREEN}✅ NUCLEAR CLEANUP COMPLETED!${RESET}"
echo ""
echo -e "${BLUE}📊 Verification:${RESET}"

echo -e "${PURPLE}Docker containers:${RESET}"
docker ps -a 2>/dev/null || echo "Docker not running or no containers"

echo -e "${PURPLE}Docker images:${RESET}"
docker images 2>/dev/null || echo "Docker not running or no images"

echo -e "${PURPLE}Docker volumes:${RESET}"
docker volume ls 2>/dev/null || echo "Docker not running or no volumes"

echo -e "${PURPLE}k3d clusters:${RESET}"
k3d cluster list 2>/dev/null || echo "k3d not installed or no clusters"

echo -e "${PURPLE}kubectl context:${RESET}"
kubectl config current-context 2>/dev/null || echo "No kubectl context set (this is expected)"

echo ""
echo -e "${GREEN}🎉 Everything has been cleaned up!${RESET}"
echo -e "${YELLOW}💡 You can now:${RESET}"
echo -e "  • Reinstall k3d: curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash"
echo -e "  • Create new clusters from scratch"
echo -e "  • kubectl should no longer show connection errors"
echo -e "  • Run step-by-step setup scripts"
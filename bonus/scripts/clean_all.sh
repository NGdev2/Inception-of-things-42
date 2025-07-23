#!/bin/bash

# Define colors
GREEN="\033[32m"
RED="\033[31m"
YELLOW="\033[33m"
BLUE="\033[34m"
PURPLE="\033[35m"
RESET="\033[0m"

echo -e "${RED}🧹 BONUS TASK CLEANUP - Removing only bonus-related resources${RESET}"
echo -e "${YELLOW}⚠️  This will delete:${RESET}"
echo -e "  • K3d clusters (fteganS)"
echo -e "  • GitLab Docker container and data"
echo -e "  • ArgoCD and related Kubernetes resources"
echo -e "  • Generated configuration files"
echo -e "  • Port forwards for bonus services"
echo ""
echo -e "${GREEN}✅ This will NOT delete:${RESET}"
echo -e "  • Other Docker containers/images from Parts 1-2"
echo -e "  • Vagrant VMs or boxes"
echo -e "  • System Docker installation"
echo -e "  • Other k3d clusters not related to bonus"
echo ""
read -p "Are you sure you want to continue? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Cleanup cancelled.${RESET}"
    exit 1
fi

echo -e "${GREEN}🚀 Starting bonus task cleanup...${RESET}"

# Stop bonus-related processes only
echo -e "${YELLOW}⏹️  Stopping bonus-related processes...${RESET}"
sudo pkill -f "port-forward.*argocd-server" 2>/dev/null || true
sudo pkill -f "port-forward.*ftegan-app" 2>/dev/null || true

# Kill port forwards for bonus services only
echo -e "${YELLOW}🔌 Killing bonus service port forwards...${RESET}"
sudo lsof -ti:8080,8082,8088,8880,8888 | xargs -r kill -9 2>/dev/null || true

# Remove only the fteganS k3d cluster (bonus-specific)
echo -e "${YELLOW}🗑️  Removing k3d cluster 'fteganS'...${RESET}"
k3d cluster delete fteganS 2>/dev/null || true

# Stop and remove only GitLab container (bonus-specific)
echo -e "${YELLOW}🦊 Stopping and removing GitLab container...${RESET}"
docker stop gitlab-ce 2>/dev/null || true
docker rm -f gitlab-ce 2>/dev/null || true

# Remove only GitLab-related Docker images (not all images)
echo -e "${YELLOW}🖼️  Removing GitLab Docker images...${RESET}"
docker images | grep gitlab | awk '{print $3}' | xargs -r docker rmi -f 2>/dev/null || true

# Remove only GitLab data directories
echo -e "${YELLOW}📂 Removing GitLab data directories...${RESET}"
rm -rf ~/gitlab-data 2>/dev/null || true
rm -rf ~/gitlab-runner 2>/dev/null || true

# Remove only unused volumes (not all volumes)
echo -e "${YELLOW}💾 Removing unused Docker volumes...${RESET}"
docker volume prune -f 2>/dev/null || true

# Clean only the kubectl config context for fteganS
echo -e "${YELLOW}📋 Cleaning kubectl context for fteganS...${RESET}"
kubectl config delete-context k3d-fteganS 2>/dev/null || true
kubectl config delete-cluster k3d-fteganS 2>/dev/null || true
kubectl config unset users.admin@k3d-fteganS 2>/dev/null || true

# Remove generated files (bonus-specific)
echo -e "${YELLOW}🗑️  Removing generated files...${RESET}"
rm -f argocd-password.txt 2>/dev/null || true
rm -f gitlab-root-password.txt 2>/dev/null || true
rm -f kubeconfig.yaml 2>/dev/null || true

# Remove any k3d containers with fteganS in name only
echo -e "${YELLOW}🧼 Removing k3d containers for fteganS cluster...${RESET}"
K3D_CONTAINERS=$(docker ps -aq --filter "name=k3d-fteganS")
if [ -n "$K3D_CONTAINERS" ]; then
  docker rm -f $K3D_CONTAINERS 2>/dev/null || true
else
  echo -e "${YELLOW}✅ No k3d fteganS containers to remove.${RESET}"
fi

# Clean up bonus-related mount points only
echo -e "${YELLOW}🔧 Cleaning up bonus-related mount points...${RESET}"
sudo umount /run/k3s/containerd/io.containerd.runtime.v2.task/k8s.io/*/rootfs 2>/dev/null || true

echo -e "${GREEN}✅ BONUS TASK CLEANUP COMPLETED!${RESET}"
echo ""
echo -e "${BLUE}📊 Verification:${RESET}"

echo -e "${PURPLE}GitLab containers:${RESET}"
docker ps -a | grep gitlab || echo "No GitLab containers found (good!)"

echo -e "${PURPLE}k3d clusters:${RESET}"
k3d cluster list 2>/dev/null || echo "k3d not installed or no clusters"

echo -e "${PURPLE}Bonus-related Docker containers:${RESET}"
docker ps -a | grep -E "(gitlab|k3d-fteganS)" || echo "No bonus containers found (good!)"

echo ""
echo -e "${GREEN}🎉 Bonus task cleanup complete!${RESET}"
echo -e "${YELLOW}💡 Other Docker containers and images from Parts 1-2 are preserved${RESET}"
echo -e "${YELLOW}💡 You can now run the bonus setup scripts again from scratch${RESET}"
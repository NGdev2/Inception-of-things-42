#!/bin/bash
set -e

GREEN="\033[32m"
RED="\033[31m"
YELLOW="\033[33m"
RESET="\033[0m"

echo -e "${GREEN}Starting environment setup...${RESET}"

echo -e "${GREEN}Updating system and installing curl...${RESET}"
sudo apt-get update -y
sudo apt install -y curl

if ! command -v docker &> /dev/null; then
  echo -e "${GREEN}Installing Docker🐳...${RESET}"
  curl -fsSL https://get.docker.com | sudo sh
  sudo usermod -aG docker $USER
else
  echo -e "${YELLOW}Docker is already installed — skipping.${RESET}"
fi


if ! command -v k3d &> /dev/null; then
  echo -e "${GREEN}Installing K3d...${RESET}"
  curl -fsSL https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
else
  echo -e "${YELLOW}K3d is already installed — skipping.${RESET}"
fi


if ! command -v kubectl &> /dev/null; then
  echo -e "${GREEN}Installing kubectl...${RESET}"
  curl -LO "https://dl.k8s.io/release/$(curl -sL https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
  chmod +x kubectl
  sudo mv kubectl /usr/local/bin/
else
  echo -e "${YELLOW}kubectl is already installed — skipping.${RESET}"
fi


CLUSTER_NAME=fteganS

if k3d cluster list | grep -q "$CLUSTER_NAME"; then
  echo -e "${YELLOW}Cluster '$CLUSTER_NAME' already exists — skipping creation.${RESET}"
else
  echo -e "${GREEN}Creating K3d cluster named '$CLUSTER_NAME'...${RESET}"
  k3d cluster create $CLUSTER_NAME
fi


echo -e "${GREEN}Creating namespaces...${RESET}"
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace dev --dry-run=client -o yaml | kubectl apply -f -


echo -e "${GREEN}Installing Argo CD into the 'argocd' namespace...${RESET}"
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml


echo -e "${GREEN}Exporting KUBECONFIG for current session...${RESET}"
export KUBECONFIG=$(k3d kubeconfig write $CLUSTER_NAME)
echo -e "${YELLOW}KUBECONFIG is set for this session.${RESET}"
echo -e "${YELLOW}To make it permanent, add the following to your ~/.bashrc or ~/.zshrc:${RESET}"
echo -e "${YELLOW}export KUBECONFIG=\$(k3d kubeconfig write $CLUSTER_NAME)${RESET}"

echo -e "${GREEN}✅ Environment setup complete!${RESET}"

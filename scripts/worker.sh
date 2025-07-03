#!/bin/bash
# This script is used to install a worker node in a K3s cluster.

GREEN="\033[32m"
RED="\033[31m"
RESET="\033[0m"

sudo apt-get update -y && sudo apt-get install -y curl
echo -e "${GREEN}APT UPDATE AND INSTALLATION OF CURL SUCCEEDED${RESET}"


if [ ! -f /vagrant/token.env ]; then
    echo -e "${RED}Token file not found.${RESET}"
    exit 1
fi


if curl -sfL https://get.k3s.io | \
  K3S_URL="https://192.168.56.110:6443" \
  K3S_TOKEN="$(cat /vagrant/token.env)" \
  INSTALL_K3S_EXEC="agent --node-ip=192.168.56.111" \
  K3S_KUBECONFIG_MODE="644" \
  sh -; then
  echo -e "${GREEN}K3s WORKER installation SUCCEEDED${RESET}"
else
    echo -e "${RED}K3s WORKER installation FAILED${RESET}"
    exit 1
fi


sudo rm /vagrant/token.env
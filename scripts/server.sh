#!/bin/bash
# This script is used to install a master node in a K3s cluster.

GREEN="\033[32m"
RED="\033[31m"
RESET="\033[0m"


sudo apt-get update -y && sudo apt-get install -y curl
echo -e "${GREEN}APT UPDATE AND INSTALLATION OF CURL SUCCEEDED${RESET}"


# Install K3s
# Setting environment variables for K3s installation
# https://docs.k3s.io/installation/configuration/#configuration-file
if curl -sfL https://get.k3s.io | \
  INSTALL_K3S_EXEC="--node-ip 192.168.56.110 --bind-address=192.168.56.110 --advertise-address=192.168.56.110 --tls-san serverS" \
  K3S_KUBECONFIG_MODE="644" \
  sh -; then
    echo -e "${GREEN}K3s MASTER installation SUCCEEDED${RESET}"
else
    echo -e "${RED}K3s MASTER installation FAILED${RESET}"
fi

# Copying the Vagrant token to the mounted folder, which will be necessary to install the worker
# https://docs.k3s.io/quick-start

if sudo cat /var/lib/rancher/k3s/server/token >> /vagrant/token.env; then
    echo -e "${GREEN}TOKEN SUCCESSFULLY SAVED${RESET}"
else
    echo -e "${RED}TOKEN SAVING FAILED${RESET}"
fi

# for test purposes, we copy the kubeconfig file to the mounted folder
sudo chown vagrant:vagrant /etc/rancher/k3s/k3s.yaml



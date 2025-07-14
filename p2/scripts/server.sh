#!/bin/bash
# This script is used to install a master node in a K3s cluster.

GREEN="\033[32m"
RED="\033[31m"
RESET="\033[0m"


sudo apt-get update -y && sudo apt-get install -y curl
echo -e "${GREEN}APT UPDATE AND INSTALLATION OF CURL SUCCEEDED${RESET}"

# Install K3s
# Setting environment variables for K3s installation, giving the node an IP address and a TLS SAN.
# giving the kubeconfig (/etc/rancher/k3s/k3s.yaml) file permissions to 644.
# https://docs.k3s.io/installation/configuration/#configuration-file
if curl -sfL https://get.k3s.io | \
  INSTALL_K3S_EXEC="--node-ip 192.168.56.110 --tls-san serverS" \
  K3S_KUBECONFIG_MODE="644" \
  sh -; then
    echo -e "${GREEN}K3s MASTER installation SUCCEEDED${RESET}"
else
    echo -e "${RED}K3s MASTER installation FAILED${RESET}"
fi

# Copying the Vagrant token to the mounted folder, which will be necessary to install the worker
# https://docs.k3s.io/quick-start

# Wait until /vagrant is properly mounted
while [ ! -d /vagrant ]; do
  echo "Waiting for /vagrant to be mounted..."
  sleep 1
done

# for test purposes, we copy the kubeconfig file to the mounted folder
sudo chown vagrant:vagrant /etc/rancher/k3s/k3s.yaml

# apply deployment and services of each app
kubectl apply -f /vagrant/configs/app1
kubectl apply -f /vagrant/configs/app2
kubectl apply -f /vagrant/configs/app3

# apply ingress
kubectl apply -f /vagrant/configs/ingress/ingress.yaml

echo -e "${GREEN}All apps and ingress deployment SUCCEEDED${RESET}"

echo "192.168.56.110 app1.com" | sudo tee -a /etc/hosts
echo "192.168.56.110 app2.com" | sudo tee -a /etc/hosts
echo "192.168.56.110 app3.com" | sudo tee -a /etc/hosts

echo -e "${GREEN}Add apps to /etc/hosts${RESET}"

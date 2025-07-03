#!/bin/bash

sudo apt-get update -y
sudo apt install curl -y

curl -fsSL https://get.docker.com | sudo sh
sudo usermod -aG docker $USER

curl -fsSL https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash

curl -LO "https://dl.k8s.io/release/$(curl -sL https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/

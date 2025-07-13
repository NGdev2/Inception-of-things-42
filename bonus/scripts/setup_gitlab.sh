#!/bin/bash
set -e

GREEN="\033[32m"
YELLOW="\033[33m"
RESET="\033[0m"

if ! command -v helm &> /dev/null; then
  echo -e "${GREEN}Installing Helm...${RESET}"
  curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
else
  echo -e "${YELLOW}Helm is already installed — skipping.${RESET}"
fi

echo -e "${GREEN}Adding GitLab Helm repo...${RESET}"
helm repo add gitlab https://charts.gitlab.io/
helm repo update

echo -e "${GREEN}Computing host IP for Docker bridge...${RESET}"
HOST_IP=$(ip -4 addr show docker0 | grep -Po 'inet \K[\d.]+' || echo "172.17.0.1")  # Fallback to common default if detection fails

echo -e "${YELLOW}Using HOST_IP: $HOST_IP${RESET}"

kubectl create ns gitlab --dry-run=client -o yaml | kubectl apply -f -

echo -e "${GREEN}Creating GitLab root password secret...${RESET}"
PASSWORD="admin12345"
kubectl -n gitlab delete secret gitlab-root-password --ignore-not-found
echo -n $PASSWORD | base64 | kubectl -n gitlab create secret generic gitlab-root-password --from-file=password=/dev/stdin

echo -e "${GREEN}Generating GitLab values.yaml...${RESET}"
cat <<EOF > gitlab-values.yaml
global:
  edition: ce
  hosts:
    domain: ${HOST_IP}.nip.io
    gitlab:
      name: gitlab.${HOST_IP}.nip.io
    https: false
    externalHttpPort: 8080
  ingress:
    class: traefik
    enabled: true
    configureCertmanager: false
    tls:
      enabled: false
  initialRootPassword:
    secret: gitlab-root-password
    key: password

minio:
  replicas: 1
postgresql:
  install: true
redis:
  replicas: 1
gitlab:
  webservice:
    replicas: 1
  sidekiq:
    replicas: 1
  gitaly:
    replicas: 1
registry:
  replicas: 1
EOF

echo -e "${GREEN}Removing existing Traefik IngressClass to allow GitLab to manage it...${RESET}"
kubectl delete ingressclass traefik --ignore-not-found

echo -e "${GREEN}Installing GitLab via Helm...${RESET}"
helm upgrade --install gitlab gitlab/gitlab \
  -n gitlab \
  -f gitlab-values.yaml \
  --timeout 600s \
  --wait

echo -e "${GREEN}✅ GitLab installed!${RESET}"
echo -e "${YELLOW}GitLab URL: http://gitlab.${HOST_IP}.nip.io:8080${RESET}"
echo -e "${YELLOW}Login: root / admin12345${RESET}"
echo -e "${YELLOW}Wait for pods to be ready (kubectl get pods -n gitlab), then follow steps to create repo.${RESET}"
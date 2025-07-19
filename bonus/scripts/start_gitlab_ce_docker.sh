#!/bin/bash
set -e

GREEN="\033[32m"
YELLOW="\033[33m"
RESET="\033[0m"

echo -e "${GREEN}🐳 Starting GitLab CE Docker container on localhost:8880...${RESET}"

# Create persistent data directory
mkdir -p ~/gitlab-data/config ~/gitlab-data/logs ~/gitlab-data/data

# Run GitLab CE
docker run --detach \
  --hostname localhost \
  --publish 8880:80 \
  --name gitlab-ce \
  --restart always \
  --volume ~/gitlab-data/config:/etc/gitlab \
  --volume ~/gitlab-data/logs:/var/log/gitlab \
  --volume ~/gitlab-data/data:/var/opt/gitlab \
  gitlab/gitlab-ce:latest

echo -e "${YELLOW}⏳ Waiting 2-3 minutes for GitLab to initialize...${RESET}"
echo -e "${YELLOW}You can inspect with: docker inspect --format='{{.State.Health.Status}}' gitlab-ce${RESET}"
echo -e "${GREEN}🌐 Access GitLab at: http://localhost:8880${RESET}"

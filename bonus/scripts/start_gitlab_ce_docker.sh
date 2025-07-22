#!/bin/bash
set -e

GREEN="\033[32m"
YELLOW="\033[33m"
RESET="\033[0m"

echo -e "${GREEN}🐳 Starting GitLab CE Docker container on localhost:8880...${RESET}"

# Check if container already exists
if docker ps -a | grep -q gitlab-ce; then
    echo -e "${YELLOW}⚠️  Container 'gitlab-ce' already exists. Removing it...${RESET}"
    docker stop gitlab-ce 2>/dev/null || true
    docker rm gitlab-ce 2>/dev/null || true
fi

# REMOVE corrupted data (if you don't need to preserve anything)
sudo rm -rf ~/gitlab-data
# Create persistent data directory
mkdir -p ~/gitlab-data/config ~/gitlab-data/logs ~/gitlab-data/data

sudo chown -R 998:998 ~/gitlab-data

# Run GitLab CE
docker run --detach \
  --hostname gitlab.local \
  --publish 8880:80 \
  --name gitlab-ce \
  --restart unless-stopped \
  --shm-size 256m \
  --env GITLAB_OMNIBUS_CONFIG="external_url 'http://gitlab.local'" \
  --volume ~/gitlab-data/config:/etc/gitlab \
  --volume ~/gitlab-data/logs:/var/log/gitlab \
  --volume ~/gitlab-data/data:/var/opt/gitlab \
  gitlab/gitlab-ce:17.11.6-ce.0

echo -e "${YELLOW}⏳ Waiting 2-3 minutes for GitLab to initialize...${RESET}"
echo -e "${YELLOW}You can inspect with: docker inspect --format='{{.State.Health.Status}}' gitlab-ce${RESET}"
echo -e "${GREEN}🌐 Access GitLab at: http://localhost:8880${RESET}"
echo -e "${YELLOW}🔑 Get initial root password with: docker exec -it gitlab-ce grep 'Password:' /etc/gitlab/initial_root_password${RESET}"

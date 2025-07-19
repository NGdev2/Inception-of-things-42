#!/bin/bash
set -e

# Colors
GREEN="\033[32m"
YELLOW="\033[33m"
RESET="\033[0m"

echo -e "${GREEN}🐳 Starting GitLab Runner container...${RESET}"

# Create config volume
mkdir -p ~/gitlab-runner/config

# Start the GitLab Runner container
docker run -d --name gitlab-runner --restart always \
  --add-host=host.docker.internal:host-gateway \
  -v /srv/gitlab-runner/config:/etc/gitlab-runner \
  -v /var/run/docker.sock:/var/run/docker.sock \
  gitlab/gitlab-runner:latest


# Ask for GitLab URL and token
echo -e "${YELLOW}🌐 Enter your GitLab instance URL (e.g. http://localhost:8880):${RESET}"
read -r GITLAB_URL

echo -e "${YELLOW}🔑 Enter the GitLab registration token (from Admin > Runners):${RESET}"
read -r REG_TOKEN

# Register the runner
docker exec -it gitlab-runner gitlab-runner register \
  --non-interactive \
  --url "$GITLAB_URL" \
  --registration-token "$REG_TOKEN" \
  --executor docker \
  --docker-image docker:latest \
  --description "local-runner" \
  --tag-list "docker" \
  --run-untagged="true" \
  --locked="false"

echo -e "${GREEN}✅ GitLab Runner registered successfully!${RESET}"

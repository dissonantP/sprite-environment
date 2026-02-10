if sprite exec -s $SPRITE_NAME bash -c 'command -v docker' > /dev/null 2>&1; then
  echo "  Docker already installed, skipping"
  exit 0
fi

sprite exec -s $SPRITE_NAME bash <<'EOF'
sudo apt-get update
sudo apt-get install -y docker.io

# Configure overlay2 storage driver
sudo mkdir -p /etc/docker
sudo tee /etc/docker/daemon.json > /dev/null <<DAEMON
{
  "storage-driver": "overlay2"
}
DAEMON

# Install docker compose v2 plugin
COMPOSE_VERSION=$(curl -sL https://api.github.com/repos/docker/compose/releases/latest | grep tag_name | cut -d'"' -f4)
sudo mkdir -p /usr/local/lib/docker/cli-plugins
sudo curl -sL "https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-linux-x86_64" -o /usr/local/lib/docker/cli-plugins/docker-compose
sudo chmod +x /usr/local/lib/docker/cli-plugins/docker-compose

# Start Docker as a sprite service
sprite-env services create docker --cmd /usr/bin/sudo --args /usr/bin/dockerd
sleep 2
EOF

# Login to ghcr.io (uses local gh token)
GHCR_LOGIN="${DOCKER_GHCR_LOGIN:-true}"
GHCR_USER="${DOCKER_GHCR_USER:-dissonantP}"
if [ "$GHCR_LOGIN" = "true" ]; then
  GH_TOKEN=$(gh auth token 2>/dev/null || true)
  if [ -n "$GH_TOKEN" ]; then
    sprite exec -s $SPRITE_NAME bash -c "echo '$GH_TOKEN' | sudo docker login ghcr.io -u $GHCR_USER --password-stdin"
  fi
fi

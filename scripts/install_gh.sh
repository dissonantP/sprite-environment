if sprite_exec bash -c 'gh auth status' > /dev/null 2>&1; then
  echo "  gh CLI already authenticated, skipping"
  exit 0
fi

GH_TOKEN=$(gh auth token)
sprite_exec bash -c "echo \"$GH_TOKEN\" | gh auth login --with-token"
sprite_exec bash -c 'gh config set git_protocol ssh --host github.com'

# Upload SSH keys for git operations
SSH_KEY="${GH_SSH_KEY:-$HOME/.ssh/id_ed25519_dissonantP}"
if [ -f "$SSH_KEY" ]; then
  sprite_exec bash -c 'mkdir -p /home/sprite/.ssh && ssh-keyscan github.com >> /home/sprite/.ssh/known_hosts 2>/dev/null'
  sprite_copy "$SSH_KEY:/home/sprite/.ssh/id_ed25519"
  sprite_copy "${SSH_KEY}.pub:/home/sprite/.ssh/id_ed25519.pub"
  sprite_exec bash -c 'chmod 600 ~/.ssh/id_ed25519 && chmod 644 ~/.ssh/id_ed25519.pub'
fi

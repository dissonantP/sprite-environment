if sprite exec -s $SPRITE_NAME bash -c 'gh auth status' > /dev/null 2>&1; then
  echo "  gh CLI already authenticated, skipping"
  exit 0
fi

GH_TOKEN=$(gh auth token)
sprite exec -s $SPRITE_NAME bash -c "echo \"$GH_TOKEN\" | gh auth login --with-token"
sprite exec -s $SPRITE_NAME bash -c 'gh config set git_protocol ssh --host github.com'

# Upload SSH keys for git operations
SSH_KEY="${GH_SSH_KEY:-$HOME/.ssh/id_ed25519_dissonantP}"
if [ -f "$SSH_KEY" ]; then
  sprite exec -s $SPRITE_NAME bash -c 'mkdir -p /home/sprite/.ssh && ssh-keyscan github.com >> /home/sprite/.ssh/known_hosts 2>/dev/null'
  sprite exec -s $SPRITE_NAME -file "$SSH_KEY:/home/sprite/.ssh/id_ed25519" true
  sprite exec -s $SPRITE_NAME -file "${SSH_KEY}.pub:/home/sprite/.ssh/id_ed25519.pub" true
  sprite exec -s $SPRITE_NAME bash -c 'chmod 600 ~/.ssh/id_ed25519 && chmod 644 ~/.ssh/id_ed25519.pub'
fi

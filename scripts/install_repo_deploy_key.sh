#!/bin/bash
set -e

if [ -z "${REPO:-}" ]; then
  echo "  Repository deploy-key setup requires --repo owner/repo"
  exit 1
fi

if [[ ! "$REPO" =~ ^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$ ]]; then
  echo "  Invalid GitHub repository: $REPO"
  exit 1
fi

DEPLOY_KEY_PATH="${REPO_DEPLOY_KEY_PATH:-/home/sprite/.ssh/id_ed25519_repo}"
DEPLOY_KEY_TITLE="${REPO_DEPLOY_KEY_TITLE:-sprite:$SPRITE_NAME}"

sprite exec -s "$SPRITE_NAME" -- env \
  DEPLOY_KEY_PATH="$DEPLOY_KEY_PATH" \
  DEPLOY_KEY_COMMENT="sprite:$SPRITE_NAME:$REPO" \
  bash <<'EOF'
set -e
mkdir -p ~/.ssh
chmod 700 ~/.ssh
if [ ! -f "$DEPLOY_KEY_PATH" ]; then
  ssh-keygen -q -t ed25519 -N "" -C "$DEPLOY_KEY_COMMENT" -f "$DEPLOY_KEY_PATH"
fi
chmod 600 "$DEPLOY_KEY_PATH"
chmod 644 "${DEPLOY_KEY_PATH}.pub"
touch ~/.ssh/known_hosts
if ! ssh-keygen -F github.com -f ~/.ssh/known_hosts > /dev/null; then
  ssh-keyscan github.com >> ~/.ssh/known_hosts 2>/dev/null
fi
chmod 644 ~/.ssh/known_hosts
EOF

PUBLIC_KEY=$(sprite exec -s "$SPRITE_NAME" -- bash -c "cat '${DEPLOY_KEY_PATH}.pub'")
KEY_MATERIAL=$(printf '%s\n' "$PUBLIC_KEY" | awk '{print $1 " " $2}')

EXISTING_KEY_ID=$(gh api "/repos/$REPO/keys" --paginate \
  --jq ".[] | select(.key == \"$KEY_MATERIAL\") | .id" | head -1)

if [ -z "$EXISTING_KEY_ID" ]; then
  STALE_KEY_IDS=$(gh api "/repos/$REPO/keys" --paginate \
    --jq ".[] | select(.title == \"$DEPLOY_KEY_TITLE\") | .id")
  while IFS= read -r key_id; do
    if [ -n "$key_id" ]; then
      gh api --method DELETE "/repos/$REPO/keys/$key_id"
    fi
  done <<< "$STALE_KEY_IDS"

  gh api --method POST "/repos/$REPO/keys" \
    -f title="$DEPLOY_KEY_TITLE" \
    -f key="$PUBLIC_KEY" \
    -F read_only=false > /dev/null
  echo "  Registered write-enabled deploy key: $DEPLOY_KEY_TITLE"
else
  echo "  Repository deploy key already registered"
fi

REPO_DIR="${REPO##*/}"
REPO_DIR="${REPO_DIR%.git}"
SSH_COMMAND="ssh -i $DEPLOY_KEY_PATH -o IdentitiesOnly=yes"

sprite exec -s "$SPRITE_NAME" -- env \
  REPO="$REPO" \
  REPO_DIR="$REPO_DIR" \
  SSH_COMMAND="$SSH_COMMAND" \
  bash <<'EOF'
set -e
if [ -d "$HOME/$REPO_DIR/.git" ]; then
  cd "$HOME/$REPO_DIR"
  git remote set-url origin "git@github.com:${REPO%.git}.git"
else
  git -c core.sshCommand="$SSH_COMMAND" clone "git@github.com:${REPO%.git}.git" "$HOME/$REPO_DIR"
  cd "$HOME/$REPO_DIR"
fi
git config core.sshCommand "$SSH_COMMAND"
git ls-remote origin > /dev/null
git push --dry-run origin HEAD > /dev/null
EOF

echo "  Repository cloned and push access verified"

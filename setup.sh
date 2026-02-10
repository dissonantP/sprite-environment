#!/bin/bash
set -e

################################################################
# Command line args
################################################################

while [[ $# -gt 0 ]]; do
  case $1 in
    --name) export SPRITE_NAME="$2"; shift 2 ;;
    --skip-docker) SKIP_DOCKER=1; shift ;;
    --repo) REPO="$2"; shift 2 ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

################################################################
# Validate that sprite name was provided
################################################################

if [ -z "$SPRITE_NAME" ]; then
  echo "Usage: setup.sh --name <sprite-name>"
  exit 1
fi

################################################################
# Validate sprite naming (lowercase)
################################################################

if [[ ! "$SPRITE_NAME" =~ ^[a-z0-9]([a-z0-9-]*[a-z0-9])?$ ]]; then
  echo "Error: sprite name must be lowercase alphanumeric with hyphens (e.g. my-sprite)"
  exit 1
fi

################################################################
# Create Sprite (skip if already exists)
################################################################

if sprite exec -s $SPRITE_NAME true > /dev/null 2>&1; then
  echo "==> Sprite '$SPRITE_NAME' already exists, updating"
else
  echo "==> Creating sprite: $SPRITE_NAME"
  sprite create -skip-console $SPRITE_NAME
fi

################################################################
# Script runner (local or remote)
################################################################

DIR="$(cd "$(dirname "$0")" 2>/dev/null && pwd)"
BASE_URL="https://dissonantp.github.io/sprite-environment"

if [ -f "$DIR/scripts/install_docker.sh" ]; then
  run_script() { SPRITE_NAME=$SPRITE_NAME bash "$DIR/$1"; }
else
  run_script() {
    local tmp=$(mktemp)
    curl -sL "$BASE_URL/$1" -o "$tmp"
    SPRITE_NAME=$SPRITE_NAME bash "$tmp"
    rm -f "$tmp"
  }
fi

################################################################
# Run scripts
################################################################

# INSTALL DOCKER
if [ -z "$SKIP_DOCKER" ]; then
  echo "==> Installing Docker"
  run_script "scripts/install_docker.sh"
else
  echo "==> Skipping Docker (--skip-docker)"
fi

# INSTALL CODEX
echo "==> Installing Codex"
run_script "scripts/install_codex.sh"

# INSTALL MCPS
echo "==> Installing Playwright MCP"
run_script "scripts/install_playwright_mcp.sh"

# INSTALL GH CLI
echo "==> Installing GitHub CLI"
run_script "scripts/install_gh.sh"

# CLONE REPO
if [ -n "$REPO" ]; then
  echo "==> Cloning repo: $REPO"
  sprite exec -s $SPRITE_NAME gh repo clone "$REPO"
fi

# VALIDATE
echo "==> Validating"
run_script "scripts/validate.sh"

# ALL DONE!
echo "==> Done"

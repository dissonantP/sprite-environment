#!/bin/bash
set -e

while [[ $# -gt 0 ]]; do
  case $1 in
    --name) export SPRITE_NAME="$2"; shift 2 ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

if [ -z "$SPRITE_NAME" ]; then
  echo "Usage: setup.sh --name <sprite-name>"
  exit 1
fi

if [[ ! "$SPRITE_NAME" =~ ^[a-z0-9]([a-z0-9-]*[a-z0-9])?$ ]]; then
  echo "Error: sprite name must be lowercase alphanumeric with hyphens (e.g. my-sprite)"
  exit 1
fi

DIR="$(cd "$(dirname "$0")" && pwd)"

echo "==> Creating sprite: $SPRITE_NAME"
sprite create -skip-console $SPRITE_NAME 2>/dev/null || true

echo "==> Installing Docker"
bash "$DIR/scripts/install_docker.sh"

echo "==> Installing Codex"
bash "$DIR/scripts/install_codex.sh"

echo "==> Validating"
bash "$DIR/scripts/validate.sh"

echo "==> Done"

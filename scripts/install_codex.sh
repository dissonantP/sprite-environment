if [ -z "${CODEX_MODEL:-}" ] && [ -f "$HOME/.codex/config.toml" ]; then
  CODEX_MODEL=$(sed -n 's/^model = "\([^"]*\)".*/\1/p' "$HOME/.codex/config.toml" | head -1)
fi

if [ -z "${CODEX_VERSION:-}" ]; then
  CODEX_VERSION=$(codex --version 2>/dev/null | sed -n 's/^codex-cli //p' | head -1)
fi

if [ -z "${CODEX_REASONING_EFFORT:-}" ] && [ -f "$HOME/.codex/config.toml" ]; then
  CODEX_REASONING_EFFORT=$(sed -n 's/^model_reasoning_effort = "\([^"]*\)".*/\1/p' "$HOME/.codex/config.toml" | head -1)
fi

CODEX_SANDBOX_MODE=${CODEX_SANDBOX_MODE:-danger-full-access}

if [[ ! "${CODEX_MODEL:-}" =~ ^[A-Za-z0-9._-]+$ ]]; then
  echo "  Codex model is not configured"
  exit 1
fi

if [[ ! "${CODEX_VERSION:-}" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "  Codex version is not configured"
  exit 1
fi

if [[ ! "${CODEX_REASONING_EFFORT:-}" =~ ^[A-Za-z0-9._-]+$ ]]; then
  echo "  Codex reasoning effort is not configured"
  exit 1
fi

if [[ ! "$CODEX_SANDBOX_MODE" =~ ^[A-Za-z0-9._-]+$ ]]; then
  echo "  Codex sandbox mode is not configured"
  exit 1
fi

if sprite exec -s "$SPRITE_NAME" -- bash -lc "test \"\$(codex --version 2>/dev/null)\" = \"codex-cli $CODEX_VERSION\""; then
  echo "  Codex already installed"
else
sprite exec -s "$SPRITE_NAME" -- env CODEX_VERSION="$CODEX_VERSION" bash <<'EOF'
mkdir -p ~/.codex
npm i -g "@openai/codex@$CODEX_VERSION"
EOF
fi

# Some older Sprites retain ~/.local/bin/codex ahead of the active Node global
# bin directory. Refresh that launcher so `codex` resolves to the version just
# installed, regardless of the base-image Node version.
sprite exec -s "$SPRITE_NAME" -- bash <<'EOF'
set -e
npm_prefix=$(npm prefix -g)
test -x "$npm_prefix/bin/codex"
mkdir -p ~/.local/bin
ln -sfn "$npm_prefix/bin/codex" ~/.local/bin/codex
EOF

sprite exec -s "$SPRITE_NAME" -- env \
  CODEX_MODEL="$CODEX_MODEL" \
  CODEX_REASONING_EFFORT="$CODEX_REASONING_EFFORT" \
  CODEX_SANDBOX_MODE="$CODEX_SANDBOX_MODE" \
  bash <<'EOF'
mkdir -p ~/.codex
touch ~/.codex/config.toml
set_config() {
  local key="$1" value="$2"
  if grep -q "^$key = " ~/.codex/config.toml; then
    sed -i "s|^$key = .*|$key = \"$value\"|" ~/.codex/config.toml
  else
    sed -i "1i$key = \"$value\"" ~/.codex/config.toml
  fi
}
set_config model "$CODEX_MODEL"
set_config model_reasoning_effort "$CODEX_REASONING_EFFORT"
set_config sandbox_mode "$CODEX_SANDBOX_MODE"
EOF

CODEX_AUTH="${CODEX_AUTH_FILE:-$HOME/.codex/auth.json}"
sprite exec -s "$SPRITE_NAME" --file "$CODEX_AUTH:/home/sprite/.codex/auth.json" -- true

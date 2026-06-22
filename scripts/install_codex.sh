if [ -z "${CODEX_MODEL:-}" ] && [ -f "$HOME/.codex/config.toml" ]; then
  CODEX_MODEL=$(sed -n 's/^model = "\([^"]*\)".*/\1/p' "$HOME/.codex/config.toml" | head -1)
fi

if [[ ! "${CODEX_MODEL:-}" =~ ^[A-Za-z0-9._-]+$ ]]; then
  echo "  Codex model is not configured"
  exit 1
fi

if sprite exec -s "$SPRITE_NAME" -- npm list -g @openai/codex > /dev/null 2>&1; then
  echo "  Codex already installed"
else
  sprite exec -s "$SPRITE_NAME" -- bash <<'EOF'
mkdir -p ~/.codex
npm i -g @openai/codex
EOF
fi

sprite exec -s "$SPRITE_NAME" -- env CODEX_MODEL="$CODEX_MODEL" bash <<'EOF'
mkdir -p ~/.codex
touch ~/.codex/config.toml
if grep -q '^model = ' ~/.codex/config.toml; then
  sed -i "s/^model = .*/model = \"$CODEX_MODEL\"/" ~/.codex/config.toml
else
  sed -i "1imodel = \"$CODEX_MODEL\"" ~/.codex/config.toml
fi
EOF

CODEX_AUTH="${CODEX_AUTH_FILE:-$HOME/.codex/auth.json}"
sprite exec -s "$SPRITE_NAME" --file "$CODEX_AUTH:/home/sprite/.codex/auth.json" -- true

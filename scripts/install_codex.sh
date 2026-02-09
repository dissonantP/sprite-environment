if sprite exec -s $SPRITE_NAME npm list -g @openai/codex > /dev/null 2>&1; then
  echo "  Codex already installed, skipping"
  exit 0
fi

sprite exec -s $SPRITE_NAME bash <<'EOF'
mkdir -p ~/.codex
npm i -g @openai/codex
EOF

# Copy auth.json into the sprite via base64 pipe
base64 < ~/.codex/auth.json | sprite exec -s $SPRITE_NAME bash -c 'base64 -d > ~/.codex/auth.json'

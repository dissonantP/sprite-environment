if sprite exec -s $SPRITE_NAME npm list -g @openai/codex > /dev/null 2>&1; then
  echo "  Codex already installed, skipping"
  exit 0
fi

sprite exec -s $SPRITE_NAME bash <<'EOF'
mkdir -p ~/.codex
npm i -g @openai/codex
EOF

sprite exec -s $SPRITE_NAME -file "$HOME/.codex/auth.json:/home/sprite/.codex/auth.json" true

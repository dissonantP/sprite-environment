if sprite exec -s $SPRITE_NAME npm list -g @openai/codex > /dev/null 2>&1; then
  echo "  Codex already installed, skipping"
  exit 0
fi

sprite exec -s $SPRITE_NAME bash <<'EOF'
mkdir -p ~/.codex
npm i -g @openai/codex
EOF

CODEX_AUTH="${CODEX_AUTH_FILE:-$HOME/.codex/auth.json}"
sprite exec -s $SPRITE_NAME -file "$CODEX_AUTH:/home/sprite/.codex/auth.json" true

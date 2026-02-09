sprite exec -s $SPRITE_NAME bash <<'EOF'
mkdir -p ~/.codex
npm i -g @openai/codex
EOF

sprite cp -s $SPRITE_NAME ~/.codex/auth.json remote_path/file.txt

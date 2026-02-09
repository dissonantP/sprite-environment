if sprite exec -s $SPRITE_NAME bash -c 'npm list -g @playwright/mcp' > /dev/null 2>&1; then
  echo "  Playwright MCP already installed, skipping"
  exit 0
fi

sprite exec -s $SPRITE_NAME bash <<'EOF'
npm i -g @playwright/mcp
npx playwright install chrome
codex mcp add playwright -- npx @playwright/mcp --headless
EOF

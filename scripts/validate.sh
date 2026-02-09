sprite exec -s $SPRITE_NAME bash <<'EOF'
check() {
  if eval "$2" > /dev/null 2>&1; then
    echo "  ✓ $1"
  else
    echo "  ✗ $1"
  fi
}

check "Docker installed" "command -v docker"
check "Docker running" "docker info"
check "Codex installed" "command -v codex"
check "Codex auth configured" "test -f ~/.codex/auth.json"
check "Playwright MCP installed" "npx @playwright/mcp --help"
check "gh CLI authenticated" "gh auth status"
EOF

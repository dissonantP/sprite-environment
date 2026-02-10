sprite exec -s $SPRITE_NAME bash <<'EOF'
PASS=0
FAIL=0

check() {
  if eval "$2" > /dev/null 2>&1; then
    echo "  ✓ $1"
    PASS=$((PASS + 1))
  else
    echo "  ✗ $1"
    FAIL=$((FAIL + 1))
  fi
}

check "Docker installed" "command -v docker"
check "Docker running" "sudo docker info"
check "Docker ghcr.io auth" "grep -q ghcr.io ~/.docker/config.json"
check "Docker Compose installed" "sudo docker compose version"
check "Codex installed" "command -v codex"
check "Codex auth configured" "test -f ~/.codex/auth.json"
check "Codex functional" 'codex --yolo exec "This is a test. Just output SUCCESS with no other output." 2>&1 | grep -q SUCCESS'
check "Codex MCP includes Playwright" "codex mcp list 2>&1 | grep -qi playwright"
check "Playwright MCP installed" "npm list -g @playwright/mcp"
check "gh CLI authenticated" "gh auth status"
check "SSH key present" "test -f ~/.ssh/id_ed25519"

echo ""
echo "  $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
EOF

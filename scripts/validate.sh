sprite exec -s "$SPRITE_NAME" -- env \
  INSTALL_GH="${INSTALL_GH:-true}" \
  INSTALL_OPENSSH="${INSTALL_OPENSSH:-false}" \
  INSTALL_DOCKER="${INSTALL_DOCKER:-false}" \
  INSTALL_YARN="${INSTALL_YARN:-true}" \
  INSTALL_CODEX="${INSTALL_CODEX:-true}" \
  INSTALL_PLAYWRIGHT_MCP="${INSTALL_PLAYWRIGHT_MCP:-true}" \
  INSTALL_CHEATSHEET="${INSTALL_CHEATSHEET:-false}" \
  DOCKER_GHCR_LOGIN="${DOCKER_GHCR_LOGIN:-true}" \
  bash <<'EOF'
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

if [ "$INSTALL_DOCKER" = "true" ]; then
  check "Docker installed" "command -v docker"
  check "Docker running" "sudo docker info"
  check "Docker Compose installed" "sudo docker compose version"
  if [ "$DOCKER_GHCR_LOGIN" = "true" ]; then
    check "Docker ghcr.io auth" "sudo grep -q ghcr.io /root/.docker/config.json"
  fi
fi

if [ "$INSTALL_CODEX" = "true" ]; then
  check "Codex installed" "command -v codex"
  check "Codex auth configured" "test -f ~/.codex/auth.json"
  check "Codex functional" 'codex --yolo exec "This is a test. Just output SUCCESS with no other output." </dev/null 2>&1 | grep -q SUCCESS'
fi

if [ "$INSTALL_PLAYWRIGHT_MCP" = "true" ]; then
  check "Codex MCP includes Playwright" "codex mcp list 2>&1 | grep -qi playwright"
  check "Playwright MCP installed" "npm list -g @playwright/mcp"
fi

if [ "$INSTALL_YARN" = "true" ]; then
  check "Yarn installed" "command -v yarn"
fi

if [ "$INSTALL_GH" = "true" ]; then
  check "gh CLI authenticated" "gh auth status"
  check "SSH key present" "test -f ~/.ssh/id_ed25519"
fi

if [ "$INSTALL_OPENSSH" = "true" ]; then
  check "OpenSSH installed" "command -v sshd"
  check "sshd service configured" "sprite-env services list 2>/dev/null | grep -q sshd"
fi

if [ "$INSTALL_CHEATSHEET" = "true" ]; then
  check "Cheatsheet installed" "test -f ~/CHEATSHEET.md"
fi

echo ""
echo "  $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
EOF

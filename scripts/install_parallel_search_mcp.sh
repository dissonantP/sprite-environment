#!/usr/bin/env bash
set -euo pipefail

: "${SPRITE_NAME:?SPRITE_NAME is required}"

sprite exec -s "$SPRITE_NAME" -- bash <<'EOF'
set -euo pipefail
if ! opencode mcp list 2>&1 | grep -q '^parallel-search'; then
  opencode mcp add parallel-search --url https://search.parallel.ai/mcp
fi
opencode mcp list
EOF

#!/usr/bin/env bash
set -euo pipefail

: "${SPRITE_NAME:?SPRITE_NAME is required}"

# The user keeps this credential in fish. Do not use env dumps or print it.
MINIMAX_KEY=$(fish -lc 'string collect --no-trim-newlines -- "$MINIMAX_API_KEY"')
if [ -z "$MINIMAX_KEY" ]; then
  echo "Error: MINIMAX_API_KEY is not set in the local fish environment" >&2
  exit 1
fi

sprite exec -s "$SPRITE_NAME" -- env MINIMAX_API_KEY="$MINIMAX_KEY" bash <<'EOF'
set -euo pipefail
mkdir -p "$HOME/.config/opencode"
umask 077
printf 'MINIMAX_API_KEY=%q\n' "$MINIMAX_API_KEY" > "$HOME/.config/opencode/.env"
chmod 600 "$HOME/.config/opencode/.env"
EOF

unset MINIMAX_KEY

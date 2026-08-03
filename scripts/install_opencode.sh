#!/usr/bin/env bash
set -euo pipefail

: "${SPRITE_NAME:?SPRITE_NAME is required}"

sprite exec -s "$SPRITE_NAME" -- bash <<'EOF'
set -euo pipefail

if ! command -v opencode > /dev/null 2>&1; then
  npm install -g --allow-scripts=opencode-ai opencode-ai
fi

mkdir -p "$HOME/.local/bin"
npm_global_bin="$(npm prefix -g)/bin"
wrapper_tmp=$(mktemp "$HOME/.local/bin/.opencode.XXXXXX")
cat > "$wrapper_tmp" <<EOF_WRAPPER
#!/usr/bin/env bash
set -euo pipefail
set -a
[ -f "\$HOME/.config/opencode/.env" ] && . "\$HOME/.config/opencode/.env"
set +a
exec "$npm_global_bin/opencode" "\$@"
EOF_WRAPPER
chmod 755 "$wrapper_tmp"
mv -f "$wrapper_tmp" "$HOME/.local/bin/opencode"
"$HOME/.local/bin/opencode" --version
EOF

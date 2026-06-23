#!/bin/bash
set -e

VERCEL_MCP_URL="${VERCEL_MCP_URL:-https://mcp.vercel.com}"
CODEX_MCP_CREDENTIALS="${CODEX_MCP_CREDENTIALS_FILE:-$HOME/.codex/.credentials.json}"

if [ ! -f "$CODEX_MCP_CREDENTIALS" ]; then
  echo "  Codex MCP credential store not found: $CODEX_MCP_CREDENTIALS"
  echo "  Run 'codex mcp login vercel' locally first"
  exit 1
fi

VERCEL_CREDENTIALS=$(mktemp)
cleanup() {
  rm -f "$VERCEL_CREDENTIALS"
}
trap cleanup EXIT

python3 - "$CODEX_MCP_CREDENTIALS" "$VERCEL_CREDENTIALS" <<'PY'
import json
import sys

source_path, output_path = sys.argv[1:3]
with open(source_path, encoding="utf-8") as source:
    credentials = json.load(source)

vercel = {
    key: value
    for key, value in credentials.items()
    if isinstance(value, dict)
    and (value.get("server_name") == "vercel" or key.startswith("vercel|"))
}

if not vercel:
    raise SystemExit(
        "No Vercel OAuth credentials found; run 'codex mcp login vercel' locally first"
    )

with open(output_path, "w", encoding="utf-8") as output:
    json.dump(vercel, output)
PY
chmod 600 "$VERCEL_CREDENTIALS"

sprite exec -s "$SPRITE_NAME" -- env VERCEL_MCP_URL="$VERCEL_MCP_URL" bash <<'EOF'
set -e
mkdir -p ~/.codex
touch ~/.codex/config.toml

if grep -q '^mcp_oauth_credentials_store = ' ~/.codex/config.toml; then
  sed -i 's/^mcp_oauth_credentials_store = .*/mcp_oauth_credentials_store = "file"/' ~/.codex/config.toml
else
  sed -i '1imcp_oauth_credentials_store = "file"' ~/.codex/config.toml
fi

if codex mcp get vercel > /dev/null 2>&1; then
  current_url=$(codex mcp get vercel 2>/dev/null | sed -n 's/^  url: //p')
  if [ "$current_url" != "$VERCEL_MCP_URL" ]; then
    codex mcp remove vercel
    codex mcp add vercel --url "$VERCEL_MCP_URL"
  fi
else
  codex mcp add vercel --url "$VERCEL_MCP_URL"
fi
EOF

sprite exec -s "$SPRITE_NAME" \
  --file "$VERCEL_CREDENTIALS:/tmp/vercel-mcp-credentials.json" -- \
  python3 - <<'PY'
import json
import os

home = os.path.expanduser("~")
destination = os.path.join(home, ".codex", ".credentials.json")
source = "/tmp/vercel-mcp-credentials.json"

os.makedirs(os.path.dirname(destination), exist_ok=True)
try:
    with open(destination, encoding="utf-8") as existing_file:
        existing = json.load(existing_file)
except FileNotFoundError:
    existing = {}

with open(source, encoding="utf-8") as source_file:
    vercel = json.load(source_file)

existing.update(vercel)
temporary = destination + ".tmp"
with open(temporary, "w", encoding="utf-8") as output:
    json.dump(existing, output)
os.chmod(temporary, 0o600)
os.replace(temporary, destination)
os.remove(source)
PY

echo "  Vercel MCP registered and OAuth credentials copied"

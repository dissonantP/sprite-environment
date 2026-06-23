#!/bin/bash
set -e

print_help() {
  cat <<'EOF'
Sprite environment bootstrap

Creates a new Sprite, or reapplies the configured bootstrap to an existing
Sprite. Defaults come from config.yaml next to this script. When config.yaml is
not available locally, the published default config is downloaded from:

  https://dissonantp.github.io/sprite-environment/config.yaml

Usage:
  ./setup.sh --name SPRITE_NAME [options]
  ./setup.sh --help

Examples:
  ./setup.sh --name my-sprite
  ./setup.sh --name form-forge --repo dissonantP/form-forge
  ./setup.sh --name test-sprite --install_docker true
  ./setup.sh --name test-sprite --dry-run

Current default profile:
  Enabled:  Codex, Yarn, Playwright MCP
  With --repo: a repository-scoped write deploy key generated on the Sprite
  Disabled: broad GitHub authentication, Vercel MCP, Docker, OpenSSH/sshd,
            cheatsheet
  Model:    inherited from the top-level model in ~/.codex/config.toml
  Repo:     none unless --repo is supplied

Primary options:
  --name NAME
      Sprite name. Required, lowercase alphanumeric with optional hyphens.
      --sprite_name NAME is also accepted as the underlying config-key form.

  --repo OWNER/REPO
      GitHub repository to clone into /home/sprite after provisioning.

  --config PATH
      Use a specific flat YAML configuration file instead of config.yaml.

  --dry-run
      Print the resolved provisioning plan without changing a Sprite.

  -h, --help
      Print this help and exit.

Component options:
  --install_gh BOOL
      Copy broad GitHub CLI authentication and the configured personal SSH key.
      This is not needed when repository deploy-key setup is enabled.
      Default: false.

  --configure_repo_deploy_key BOOL
      With --repo, generate a key inside the Sprite and register its public key
      as a write-enabled deploy key for only that repository. The local gh CLI
      performs registration; its token is not copied. Default: true.

  --install_codex BOOL
      Install Codex and copy local Codex authentication. Default: true.

  --install_yarn BOOL
      Install Yarn globally. Default: true.

  --install_playwright_mcp BOOL
      Install and register Playwright MCP. Requires Codex. Default: true.

  --install_vercel_mcp BOOL
      Register Vercel MCP and copy its scoped OAuth record. Requires Codex.
      Default: false.

  --install_docker BOOL
      Install Sprite-compatible Docker Engine and Compose. Default: false.

  --install_openssh BOOL
      Install OpenSSH and register an sshd Sprite service. Default: false.

  --install_cheatsheet BOOL
      Install ~/CHEATSHEET.md on the Sprite. Default: false.

Credential and component settings:
  --gh_ssh_key PATH
      Local SSH private key copied to the Sprite.
      Default: $HOME/.ssh/id_ed25519

  --codex_auth_file PATH
      Local Codex authentication file copied to the Sprite.
      Default: $HOME/.codex/auth.json

  --codex_model MODEL
      Codex model configured on the Sprite. By default, inherited locally.

  --codex_mcp_credentials_file PATH
      Local file-backed MCP OAuth store. Only Vercel records are copied.
      Default: $HOME/.codex/.credentials.json

  --vercel_mcp_url URL
      Vercel MCP endpoint. Default: https://mcp.vercel.com

Docker registry settings:
  --docker_ghcr_login BOOL
      Authenticate Docker with ghcr.io using the local gh token.
      Requires GitHub setup. Default: true.

  --docker_ghcr_user USER
      GitHub Container Registry username. Default: dissonantP.

Configuration:
  Permanent defaults live in config.yaml. Command-line values override that
  file for one run. Boolean values are written as true or false.

  Resolution order:
    1. Command-line options
    2. The file supplied with --config
    3. Local config.yaml
    4. Published config.yaml
EOF
}

if [[ $# -eq 0 ]]; then
  print_help
  exit 0
fi

################################################################
# Command line args (any --key value sets a config override)
################################################################

_CLI_OVERRIDES=$(mktemp)

cleanup() {
  rm -f "$_CLI_OVERRIDES"
  if [ -n "${_REMOTE_CONFIG:-}" ]; then
    rm -f "$_REMOTE_CONFIG"
  fi
}
trap cleanup EXIT

while [[ $# -gt 0 ]]; do
  case $1 in
    -h|--help) print_help; exit 0 ;;
    --config) CONFIG_FILE="$2"; shift 2 ;;
    --name) echo "sprite_name: $2" >> "$_CLI_OVERRIDES"; shift 2 ;;
    --repo) echo "repo: $2" >> "$_CLI_OVERRIDES"; shift 2 ;;
    --dry-run) echo "dry_run: true" >> "$_CLI_OVERRIDES"; shift ;;
    --*) echo "${1#--}: $2" >> "$_CLI_OVERRIDES"; shift 2 ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

################################################################
# Load config
################################################################

DIR="$(cd "$(dirname "$0")" 2>/dev/null && pwd)"
BASE_URL="https://dissonantp.github.io/sprite-environment"

# Parse a value from config YAML (flat key: value only)
# Resolution: CLI overrides > --config file > local config.yaml > remote config.yaml
cfg() {
  local key="$1" default="$2" val=""
  # Check CLI overrides first
  val=$(grep "^${key}:" "$_CLI_OVERRIDES" 2>/dev/null | tail -1 | sed 's/^[^:]*: *//' | sed 's/ *$//')
  # Then config file
  if [ -z "$val" ]; then
    local file="${CONFIG_FILE:-}"
    if [ -z "$file" ] && [ -f "$DIR/config.yaml" ]; then
      file="$DIR/config.yaml"
    fi
    if [ -z "$file" ]; then
      if [ -z "$_REMOTE_CONFIG" ]; then
        _REMOTE_CONFIG=$(mktemp)
        curl -sL "$BASE_URL/config.yaml" -o "$_REMOTE_CONFIG"
      fi
      file="$_REMOTE_CONFIG"
    fi
    val=$(grep "^${key}:" "$file" 2>/dev/null | head -1 | sed 's/^[^:]*: *//' | sed 's/ *$//')
  fi
  # Expand $HOME in values
  val=$(eval echo "$val")
  if [ -z "$val" ]; then echo "$default"; else echo "$val"; fi
}

################################################################
# Resolve sprite name
################################################################

export SPRITE_NAME=$(cfg sprite_name "")

if [ -z "$SPRITE_NAME" ]; then
  echo "Usage: setup.sh --name <sprite-name> [--config path] [--key value ...]"
  exit 1
fi

if [[ ! "$SPRITE_NAME" =~ ^[a-z0-9]([a-z0-9-]*[a-z0-9])?$ ]]; then
  echo "Error: sprite name must be lowercase alphanumeric with hyphens (e.g. my-sprite)"
  exit 1
fi

################################################################
# Resolve component plan
################################################################

export INSTALL_GH=$(cfg install_gh false)
export INSTALL_OPENSSH=$(cfg install_openssh false)
export INSTALL_DOCKER=$(cfg install_docker false)
export INSTALL_YARN=$(cfg install_yarn true)
export INSTALL_CODEX=$(cfg install_codex true)
export INSTALL_PLAYWRIGHT_MCP=$(cfg install_playwright_mcp true)
export INSTALL_VERCEL_MCP=$(cfg install_vercel_mcp false)
export CONFIGURE_REPO_DEPLOY_KEY=$(cfg configure_repo_deploy_key true)
export INSTALL_CHEATSHEET=$(cfg install_cheatsheet false)
export DOCKER_GHCR_LOGIN=$(cfg docker_ghcr_login true)
export DOCKER_GHCR_USER=$(cfg docker_ghcr_user dissonantP)
export GH_SSH_KEY=$(cfg gh_ssh_key "$HOME/.ssh/id_ed25519")
export CODEX_AUTH_FILE=$(cfg codex_auth_file "$HOME/.codex/auth.json")
export CODEX_MODEL=$(cfg codex_model "")
export CODEX_MCP_CREDENTIALS_FILE=$(cfg codex_mcp_credentials_file "$HOME/.codex/.credentials.json")
export VERCEL_MCP_URL=$(cfg vercel_mcp_url "https://mcp.vercel.com")
REPO=$(cfg repo "")
DRY_RUN=$(cfg dry_run false)
export REPO

if [ "$INSTALL_PLAYWRIGHT_MCP" = "true" ] && [ "$INSTALL_CODEX" != "true" ]; then
  echo "Error: install_playwright_mcp requires install_codex"
  exit 1
fi

if [ "$INSTALL_VERCEL_MCP" = "true" ] && [ "$INSTALL_CODEX" != "true" ]; then
  echo "Error: install_vercel_mcp requires install_codex"
  exit 1
fi

if [ -n "$REPO" ] && [ "$CONFIGURE_REPO_DEPLOY_KEY" != "true" ] && [ "$INSTALL_GH" != "true" ]; then
  echo "Error: --repo requires configure_repo_deploy_key: true or install_gh: true"
  exit 1
fi

if [ "$INSTALL_CODEX" = "true" ] && [ -z "$CODEX_MODEL" ] && [ -f "$HOME/.codex/config.toml" ]; then
  CODEX_MODEL=$(sed -n 's/^model = "\([^"]*\)".*/\1/p' "$HOME/.codex/config.toml" | head -1)
  export CODEX_MODEL
fi

if [ "$INSTALL_CODEX" = "true" ] && [[ ! "$CODEX_MODEL" =~ ^[A-Za-z0-9._-]+$ ]]; then
  echo "Error: codex_model must be configured or available in ~/.codex/config.toml"
  exit 1
fi

print_plan() {
  echo "==> Sprite provisioning plan"
  echo "  Name: $SPRITE_NAME"
  echo "  Repository: ${REPO:-none}"
  echo "  Broad GitHub CLI auth: $INSTALL_GH"
  if [ -n "$REPO" ]; then
    echo "  Repository deploy key: $CONFIGURE_REPO_DEPLOY_KEY"
  else
    echo "  Repository deploy key: not applicable (no repository)"
  fi
  echo "  Codex: $INSTALL_CODEX"
  if [ "$INSTALL_CODEX" = "true" ]; then
    echo "  Codex model: $CODEX_MODEL"
  fi
  echo "  Yarn: $INSTALL_YARN"
  echo "  Playwright MCP: $INSTALL_PLAYWRIGHT_MCP"
  echo "  Vercel MCP: $INSTALL_VERCEL_MCP"
  echo "  Docker: $INSTALL_DOCKER"
  echo "  OpenSSH/sshd: $INSTALL_OPENSSH"
  echo "  Cheatsheet: $INSTALL_CHEATSHEET"
}

if [ "$DRY_RUN" = "true" ]; then
  print_plan
  echo "==> Dry run complete; no Sprite changes made"
  exit 0
fi

if [ -n "$REPO" ] && [ "$CONFIGURE_REPO_DEPLOY_KEY" = "true" ]; then
  if ! command -v gh > /dev/null 2>&1 || ! gh auth status > /dev/null 2>&1; then
    echo "Error: repository deploy-key setup requires an authenticated local gh CLI"
    exit 1
  fi
fi

################################################################
# Create Sprite (skip if already exists)
################################################################

if sprite exec -s "$SPRITE_NAME" -- true > /dev/null 2>&1; then
  echo "==> Sprite '$SPRITE_NAME' already exists, updating"
else
  echo "==> Creating sprite: $SPRITE_NAME"
  sprite create --skip-console "$SPRITE_NAME"
fi

################################################################
# Script runner (local or remote)
################################################################

if [ -f "$DIR/scripts/install_docker.sh" ]; then
  run_script() { SPRITE_NAME="$SPRITE_NAME" bash "$DIR/$1"; }
else
  run_script() {
    local tmp=$(mktemp)
    curl -sL "$BASE_URL/$1" -o "$tmp"
    SPRITE_NAME="$SPRITE_NAME" bash "$tmp"
    rm -f "$tmp"
  }
fi

################################################################
# Run scripts
################################################################

# INSTALL BROAD GH AUTH (opt-in; first so docker can use gh token for ghcr.io)
if [ "$INSTALL_GH" = "true" ]; then
  echo "==> Installing GitHub CLI"
  run_script "scripts/install_gh.sh"
else
  echo "==> Skipping GitHub CLI"
fi

# CONFIGURE REPOSITORY DEPLOY KEY AND CLONE
if [ -n "$REPO" ] && [ "$CONFIGURE_REPO_DEPLOY_KEY" = "true" ]; then
  echo "==> Configuring repository deploy key"
  run_script "scripts/install_repo_deploy_key.sh"
fi

# INSTALL OPENSSH
if [ "$INSTALL_OPENSSH" = "true" ]; then
  echo "==> Installing OpenSSH"
  run_script "scripts/install_openssh.sh"
else
  echo "==> Skipping OpenSSH"
fi

# INSTALL DOCKER
if [ "$INSTALL_DOCKER" = "true" ]; then
  echo "==> Installing Docker"
  run_script "scripts/install_docker.sh"
else
  echo "==> Skipping Docker"
fi

# INSTALL YARN
if [ "$INSTALL_YARN" = "true" ]; then
  echo "==> Installing Yarn"
  run_script "scripts/install_yarn.sh"
else
  echo "==> Skipping Yarn"
fi

# INSTALL CODEX
if [ "$INSTALL_CODEX" = "true" ]; then
  echo "==> Installing Codex"
  run_script "scripts/install_codex.sh"
else
  echo "==> Skipping Codex"
fi

# INSTALL PLAYWRIGHT MCP
if [ "$INSTALL_PLAYWRIGHT_MCP" = "true" ]; then
  echo "==> Installing Playwright MCP"
  run_script "scripts/install_playwright_mcp.sh"
else
  echo "==> Skipping Playwright MCP"
fi

# INSTALL VERCEL MCP
if [ "$INSTALL_VERCEL_MCP" = "true" ]; then
  echo "==> Installing Vercel MCP"
  run_script "scripts/install_vercel_mcp.sh"
else
  echo "==> Skipping Vercel MCP"
fi

# CLONE REPO USING BROAD GH AUTH
if [ -n "$REPO" ] && [ "$CONFIGURE_REPO_DEPLOY_KEY" != "true" ]; then
  echo "==> Cloning repo: $REPO"
  REPO_DIR="${REPO##*/}"
  REPO_DIR="${REPO_DIR%.git}"
  sprite exec -s "$SPRITE_NAME" -- env REPO="$REPO" REPO_DIR="$REPO_DIR" bash <<'EOF'
if [ -d "$HOME/$REPO_DIR/.git" ]; then
  echo "  Repository already cloned"
else
  gh repo clone "$REPO" "$HOME/$REPO_DIR"
fi
EOF
fi

# CHEATSHEET
if [ "$INSTALL_CHEATSHEET" = "true" ]; then
  echo "==> Installing cheatsheet"
  run_script "scripts/install_cheatsheet.sh"
else
  echo "==> Skipping cheatsheet"
fi

# VALIDATE
echo "==> Validating"
run_script "scripts/validate.sh"

# ALL DONE!
echo "==> Done"

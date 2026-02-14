# AGENTS.md — LLM Developer Guide

Keep this file and `README.md` up to date when making changes. This file is for LLM agents working on the codebase. README.md is the human-facing summary.

## Overview

This repo provisions [Sprites](https://sprites.dev) dev environments. It runs locally on the user's machine and uses `sprite exec` to run commands on the remote sprite. Scripts are served via GitHub Pages at `https://dissonantp.github.io/sprite-environment/` so project repos can call setup without cloning this repo.

## Execution model

`setup.sh` is the entry point. It can run locally (`bash setup.sh`) or be fetched remotely (`curl | bash`). It detects which mode it's in by checking if `scripts/install_docker.sh` exists next to itself. In remote mode, each sub-script is downloaded to a temp file before execution.

**Critical: never pipe sub-scripts directly from curl to bash.** `sprite exec` consumes stdin, which breaks piped execution. Always download to a temp file first. See `run_script()` in setup.sh.

## Config system

`config.yaml` is flat key-value YAML parsed by the `cfg()` function in setup.sh using grep/sed (no external YAML parser needed). Values can contain `$HOME` which gets expanded via `eval echo`.

Config resolution order:
1. `--config` CLI arg (explicit path)
2. `config.yaml` next to setup.sh (local runs)
3. Remote `config.yaml` from GitHub Pages (remote runs)

Config values are exported as env vars to sub-scripts: `CODEX_AUTH_FILE`, `GH_SSH_KEY`, `DOCKER_GHCR_LOGIN`, `DOCKER_GHCR_USER`, `INSTALL_OPENSSH`. Sub-scripts use these with fallback defaults so they work standalone too.

Every config key can be overridden via CLI: `--key value`. `--name` is an alias for `--sprite_name`, `--repo` is an alias for `--repo`. All other keys use their exact name (e.g. `--install_docker false`). CLI args are written to a temp overrides file and checked first by `cfg()`.

Config keys:

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `sprite_name` | string | (required) | Name of the sprite. Set via `--name` or config. |
| `install_gh` | bool | `true` | Authenticate gh CLI and upload SSH keys. Requires local `gh auth login` first. |
| `gh_ssh_key` | path | `$HOME/.ssh/id_ed25519_dissonantP` | Private key to upload (`.pub` appended for public). Uploaded as `id_ed25519` on sprite. |
| `install_docker` | bool | `true` | Install Docker Engine, Compose plugin, overlay2 storage. |
| `install_openssh` | bool | `false` | Install OpenSSH server and register `sshd` as a sprite service. |
| `docker_ghcr_login` | bool | `true` | Login to ghcr.io using gh token. Requires `install_gh: true`. |
| `docker_ghcr_user` | string | `dissonantP` | GitHub username for ghcr.io auth. |
| `install_yarn` | bool | `true` | Install Yarn globally via npm. |
| `install_codex` | bool | `true` | Install Codex CLI globally via npm. |
| `codex_auth_file` | path | `$HOME/.codex/auth.json` | Local auth file to copy into sprite. |
| `repo` | string | (empty) | GitHub repo to clone (e.g. `owner/repo`). |
| `install_playwright_mcp` | bool | `true` | Install Playwright MCP and register with Codex. |

## Script execution order

1. **install_gh.sh** — Runs first because Docker needs the gh token for ghcr.io login.
2. **install_openssh.sh** — Installs `openssh-server` and creates `sshd` service via `sprite-env services create`.
3. **install_docker.sh** — Must use `docker.io` from apt (not `docker-ce`). Uses overlay2 storage driver. Daemon started via `sprite-env services create` (not systemd/nohup). All docker commands require `sudo`.
4. **install_yarn.sh** — Installs Yarn globally via npm.
5. **install_codex.sh** — Installs via npm, copies auth file using `sprite exec -file`.
6. **install_playwright_mcp.sh** — Installs via npm, installs Chrome, registers with `codex mcp add`.
7. **install_cheatsheet.sh** — Writes ~/CHEATSHEET.md on the sprite.
8. **validate.sh** — Checks all components are working.

Each script is idempotent with a guard clause at the top (checks if already installed, exits 0 if so).

## Sprite environment constraints

- **No systemd.** Start daemons via `sprite-env services create`.
- **Cgroups v2 restricted.** Only `cpuset cpu pids` controllers available. Memory and IO controllers are not available. Docker containers cannot have resource limits.
- **`sprite exec` flag parsing.** Commands with flags (like `mkdir -p`) get their flags parsed as sprite exec flags. Always wrap in `bash -c '...'`.
- **`sprite exec -file`** uploads local files: `sprite exec -s NAME -file "local:remote" true`. The `true` at the end is a required command arg.
- **`sudo` required for docker.** All docker/docker compose commands need `sudo` on sprites.
- **gh is pre-installed** on sprites. No apt install needed, just token injection.

## Scripting patterns and gotchas

These are hard-won lessons from building these scripts. Read before writing new ones.

### sprite exec eats stdin

`sprite exec` reads from stdin. If a script is piped via `curl | bash`, the first `sprite exec` call consumes the rest of the pipe and the script stops executing silently. **Always download to a temp file first**, then run with `bash "$tmp"`. This applies to both setup.sh calling sub-scripts and project scripts calling setup.sh.

### sprite exec parses flags aggressively

Any flag-like argument (e.g. `-p` in `mkdir -p`) gets parsed as a `sprite exec` flag, not passed to the command. Wrap commands in `bash -c '...'`:
- Wrong: `sprite exec -s NAME mkdir -p /foo`
- Right: `sprite exec -s NAME bash -c 'mkdir -p /foo'`

### sprite exec -file requires a command

`sprite exec -file "local:remote"` alone fails. You must provide a command to run, even if it's just `true`:
- `sprite exec -s NAME -file "local:remote" true`

### There is no sprite cp

File transfer uses `sprite exec -file`, not a dedicated copy command. `sprite cp` does not exist.

### Heredocs on the sprite

Use `<<'EOF'` (quoted) to prevent local variable expansion. Use unquoted `<<EOF` only when you intentionally want local expansion. Be careful with nested heredocs (e.g. the Docker daemon.json inside the install heredoc) — use different delimiters.

### gh auth tokens live in macOS keychain

On macOS, `~/.config/gh/hosts.yml` does not contain the token — it's stored in the system keychain. Use `gh auth token` to extract it. This is why we pipe `gh auth token | gh auth login --with-token` rather than copying a config file.

### gh token needs read:packages for ghcr.io

The default gh token scopes don't include `read:packages`. Users must run `gh auth refresh -s read:packages` locally before the Docker ghcr.io login will work. If pulls return 403, this is likely the cause.

### Docker on sprites requires specific setup

Docker must be installed as `docker.io` from apt, not `docker-ce` from Docker's official repo. The `docker-ce` package tries to use cgroup features that aren't available. See `/.sprite/docs/docker.md` on any sprite for the official guide.

The Docker Compose plugin is not included with `docker.io`. It's installed separately by downloading the binary from GitHub releases into `/usr/local/lib/docker/cli-plugins/`.

### Docker containers cannot have resource limits

Sprites only expose `cpuset cpu pids` cgroup controllers. Memory and IO controllers are unavailable and cannot be enabled. Any `deploy.resources` section in docker-compose.yml with memory/cpu limits will cause container creation to fail with cgroup errors. Remove these limits for sprite compatibility.

### nohup inside heredocs still hangs

Running `nohup sudo dockerd &` inside a `sprite exec bash <<'EOF'` heredoc keeps the session open because output streams are still attached. Use `sprite-env services create` instead of nohup for daemons.

### SSH keys should use the default name

Upload keys as `~/.ssh/id_ed25519` on the sprite (not the original filename) so SSH uses them automatically without needing a config entry.

### Idempotency pattern

Every install script should start with a guard that checks if the software is already present and exits 0 if so. Use specific checks:
- `command -v <binary>` for CLI tools
- `npm list -g <package>` for npm global packages
- `gh auth status` for gh authentication
- `test -f <path>` for config files

## File structure

```
setup.sh                      # Entry point, arg parsing, config loading, orchestration
config.yaml                   # Default config values (flat YAML with comments)
README.md                     # Human-facing docs
AGENTS.md                     # This file (LLM developer docs)
scripts/
  install_gh.sh               # gh auth + SSH key upload
  install_openssh.sh          # openssh-server install + sshd sprite service
  install_docker.sh           # docker.io + compose plugin + overlay2 + sprite service + ghcr.io login
  install_yarn.sh             # yarn package manager via npm
  install_codex.sh            # codex CLI + auth file copy
  install_playwright_mcp.sh   # playwright MCP + chrome + codex registration
  install_cheatsheet.sh       # ~/CHEATSHEET.md on sprite
  validate.sh                 # health checks for all components
```

## Adding a new install script

1. Create `scripts/install_foo.sh` with an idempotency guard at the top.
2. Add a config key `install_foo: true` to `config.yaml`.
3. Add the `cfg` check and `run_script` call to `setup.sh`.
4. Add a corresponding check to `scripts/validate.sh`.
5. Update this file and `README.md`.

## GitHub Pages

The repo is public. Pages serves from the `master` branch root. Deploys take ~30-60 seconds after push. All files in the repo are accessible at `https://dissonantp.github.io/sprite-environment/<path>`.

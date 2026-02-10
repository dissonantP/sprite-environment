# Sprite Setup System

Automated provisioning for [Sprites](https://sprites.dev) dev environments.

## What gets installed

- **Docker** — Docker Engine (docker.io), Compose plugin, overlay2 storage. Daemon started via sprite service. All commands require `sudo`.
- **Codex** — OpenAI Codex CLI (`@openai/codex`), with auth config copied from local machine.
- **Playwright MCP** — Playwright MCP server (`@playwright/mcp`) with Chrome browser, registered with Codex.
- **GitHub CLI** — `gh` CLI (pre-installed on sprites), authenticated via token from local keychain. SSH keys uploaded.

## Usage

Create and provision a new sprite:

```bash
bash setup.sh --name my-sprite
```

Options:

- `--config path/to/config.yaml` — Use a custom config file (defaults to `config.yaml` in repo root).
- `--repo owner/repo` — Clone a GitHub repo after setup.

```bash
bash setup.sh --name my-sprite --config my-config.yaml --repo myorg/myrepo
```

Sprite names must be lowercase alphanumeric with hyphens.

Scripts are idempotent — running against an existing sprite skips already-installed components.

## Configuration

Edit `config.yaml` to control what gets installed and with what settings. All values have sensible defaults. See comments in the file for details.

Project repos can provide their own `config.yaml` via `--config`:

```bash
bash setup.sh --name my-sprite --config /path/to/project/config.yaml
```

## Structure

- `setup.sh` — Entry point. Reads config, creates the sprite, runs install scripts.
- `config.yaml` — Default configuration values with comments.
- `scripts/install_docker.sh` — Installs Docker and starts the daemon.
- `scripts/install_codex.sh` — Installs Codex and copies auth config.
- `scripts/install_playwright_mcp.sh` — Installs Playwright MCP server and Chrome.
- `scripts/install_gh.sh` — Authenticates gh CLI via token injection and uploads SSH keys.
- `scripts/install_cheatsheet.sh` — Installs a command cheatsheet at ~/CHEATSHEET.md.
- `scripts/validate.sh` — Checks that all expected tools are installed and running.

## Remote usage

The repo is public and served via GitHub Pages. Project repos can call setup remotely:

```bash
curl -sL https://dissonantp.github.io/sprite-environment/setup.sh -o /tmp/setup.sh
bash /tmp/setup.sh --name my-sprite
```

When run this way, sub-scripts and config are fetched from GitHub Pages automatically. You can still override config with a local file:

```bash
bash /tmp/setup.sh --name my-sprite --config ./config.yaml
```

## Maintenance

When adding new install scripts, add corresponding checks to `scripts/validate.sh` to keep validation up to date.

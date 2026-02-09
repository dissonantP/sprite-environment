# Sprite Setup System

Automated provisioning for [Sprites](https://sprites.dev) dev environments.

## What gets installed

- **Docker** — Docker Engine, CLI, containerd, buildx, and compose plugin. Daemon is started after install.
- **Codex** — OpenAI Codex CLI (`@openai/codex`), with auth config copied from local `~/.codex/auth.json`.

## Usage

Create and provision a new sprite:

```bash
bash setup.sh --name my-sprite
```

Sprite names must be lowercase alphanumeric with hyphens.

Run validation on an existing sprite:

```bash
SPRITE_NAME=my-sprite bash scripts/validate.sh
```

Individual install scripts can be run standalone:

```bash
SPRITE_NAME=my-sprite bash scripts/install_docker.sh
SPRITE_NAME=my-sprite bash scripts/install_codex.sh
```

## Structure

- `setup.sh` — Entry point. Creates the sprite and runs all install scripts.
- `scripts/install_docker.sh` — Installs Docker and starts the daemon.
- `scripts/install_codex.sh` — Installs Codex and copies auth config.
- `scripts/validate.sh` — Checks that all expected tools are installed and running.

## Maintenance

When adding new install scripts, add corresponding checks to `scripts/validate.sh` to keep validation up to date.

Changes are committed and pushed to the private `sprite-environment` GitHub repo.

# sprite-environment

Automated provisioning for [Sprites](https://sprites.dev) dev environments. Installs Docker, Codex, Playwright MCP, and GitHub CLI.

## Quick start

```bash
bash setup.sh --name my-sprite
```

## Remote usage

```bash
curl -sL https://dissonantp.github.io/sprite-environment/setup.sh -o /tmp/setup.sh
bash /tmp/setup.sh --name my-sprite --repo owner/repo
```

## Options

| Flag | Description |
|------|-------------|
| `--name` | Sprite name (required, lowercase alphanumeric with hyphens) |
| `--repo owner/repo` | Clone a GitHub repo after setup |
| `--config path` | Custom config file (defaults to `config.yaml`) |

## Configuration

Edit `config.yaml` to toggle components and set paths. See comments in the file.

## Prerequisites

- [Sprite CLI](https://sprites.dev) installed
- `gh auth login` completed locally (for gh/SSH/Docker registry auth)

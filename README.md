# sprite-environment

Automated provisioning for [Sprites](https://sprites.dev) development environments. The default profile installs Codex, Playwright MCP, Yarn, and authenticated GitHub CLI access.

## What it does

- Installs Codex and copies `$HOME/.codex/auth.json`
- Copies over `gh` login and local SSH key
- Installs Yarn globally via npm
- Installs Playwright MCP to Codex
- Optionally installs Docker and Docker Compose with the Sprite-compatible setup
- Optionally installs OpenSSH server and registers `sshd` with Sprite services
- Optionally adds `~/CHEATSHEET.md`

Docker, OpenSSH/sshd, and the cheatsheet are disabled by default.

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
| `--dry-run` | Print the resolved provisioning plan without changing a Sprite |
| `--<key> <value>` | Override any config key (e.g. `--install_docker false`) |

## Configuration

Edit `config.yaml` to toggle components and set paths. All keys can also be set via CLI arguments. Opt into optional components with `--install_docker true`, `--install_openssh true`, or `--install_cheatsheet true`.

## Assumptions

- [Sprite CLI](https://sprites.dev) installed
- `gh auth login` completed locally, with `read:packages` scope (`gh auth refresh -s read:packages`)
- `~/.codex/auth.json` exists (Codex auth config)
- An SSH keypair in `~/.ssh/` for GitHub (set the key name in `config.yaml` via `gh_ssh_key`)

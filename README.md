# sprite-environment

Automated provisioning for [Sprites](https://sprites.dev) dev environments. Installs and pre-authenticates Docker, Docker Compose, Codex, Playwright MCP, and GitHub CLI.

## What it does

- Installs Codex and copies `$HOME/.codex/auth.json`
- Copies over `gh` login and local SSH key
- Installs Docker with the Sprite-compatible setup (see `/.sprite/docs/docker.md` on the Sprite)
- Installs Docker Compose
- Logs into Docker using `gh` credentials
- Installs Playwright MCP to Codex
- Add a ~/CHEATSHEET.md with a couple useful commands

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
| `--<key> <value>` | Override any config key (e.g. `--install_docker false`) |

## Configuration

Edit `config.yaml` to toggle components and set paths. See comments in the file. All keys can also be set via CLI args.

## Assumptions

- [Sprite CLI](https://sprites.dev) installed
- `gh auth login` completed locally, with `read:packages` scope (`gh auth refresh -s read:packages`)
- `~/.codex/auth.json` exists (Codex auth config)
- `~/.ssh/id_ed25519_dissonantP` and `.pub` exist (SSH keypair for GitHub)

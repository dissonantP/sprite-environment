# sprite-environment

Automated provisioning for [Sprites](https://sprites.dev) development environments. The default profile installs Codex, Playwright MCP, and Yarn. When a repository is supplied, it configures a repository-scoped write deploy key by default.

## What it does

- Installs Codex and copies `$HOME/.codex/auth.json`
- Generates repository deploy keys inside Sprites and registers only their public keys through the local `gh` CLI
- Installs Yarn globally via npm
- Installs Playwright MCP to Codex
- Optionally copies broad GitHub authentication or Vercel MCP credentials when explicitly enabled
- Optionally installs Docker and Docker Compose with the Sprite-compatible setup
- Optionally installs OpenSSH server and registers `sshd` with Sprite services
- Optionally adds `~/CHEATSHEET.md`

Broad GitHub authentication, Vercel MCP, Docker, OpenSSH/sshd, and the cheatsheet are disabled by default. Repository deploy keys are write-enabled but limited to the selected repository.

## Quick start

```bash
bash setup.sh --name my-sprite
```

Run `bash setup.sh --help`, or invoke it without arguments, to see the current
default profile, examples, configuration resolution, and the full option list.

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
- `gh auth login` completed locally so setup can register repository deploy keys
- `~/.codex/auth.json` exists (Codex auth config)
- Vercel OAuth credentials and a personal GitHub SSH key are needed only when their opt-in features are enabled

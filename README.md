# sprite-environment

Automated provisioning for [Sprites](https://sprites.dev) development
environments. The bootstrap creates or updates a Sprite, installs the selected
development tools, configures authentication, optionally clones a GitHub
repository, and validates the completed environment.

## Quick start

Create a Sprite with the default tools:

```bash
./setup.sh --name my-sprite
```

Create a Sprite and clone a repository with repository-scoped push access:

```bash
./setup.sh --name form-forge --repo proteanP/form-forge
```

Preview the resolved plan without changing anything:

```bash
./setup.sh --name form-forge --repo proteanP/form-forge --dry-run
```

Run `./setup.sh`, `./setup.sh --help`, or `./setup.sh -h` to print command
help.

## Default profile

The standard profile enables:

- Codex CLI installation and local Codex authentication transfer
- Yarn
- Playwright MCP
- A write-enabled GitHub deploy key when `--repo` is supplied
- Full post-installation validation

The standard profile disables:

- Broad GitHub CLI authentication and personal SSH-key transfer
- Vercel MCP and Vercel OAuth credential transfer
- Docker and Docker Compose
- OpenSSH server and `sshd`
- `~/CHEATSHEET.md`

The Codex model is inherited from the top-level `model` setting in the local
`~/.codex/config.toml`, unless `codex_model` is configured explicitly.
After MCP registration, setup reapplies the selected model and authentication
because Codex MCP commands may rewrite `config.toml`.

## Repository access and security

When `--repo owner/repo` is supplied, `configure_repo_deploy_key` defaults to
`true`. The bootstrap:

1. Generates a unique SSH key inside the Sprite.
2. Reads only its public key back to the host.
3. Uses the host's authenticated `gh` CLI to register that key as a
   write-enabled deploy key on the selected repository.
4. Clones the repository over SSH.
5. Configures that checkout to use the deploy key.
6. Verifies fetch and dry-run push access.

The host GitHub token and personal SSH private key are not copied to the Sprite
in this mode. The private deploy key remains readable by processes running as
the Sprite user, but its GitHub authority is limited to one repository.

Broad GitHub authentication remains available through `install_gh: true`.
That option copies the host's GitHub authentication and configured personal SSH
key into the Sprite. It should be used only when repository-scoped deploy-key
access is insufficient.

Codex authentication is copied from the configured `codex_auth_file`. A Codex
process with unrestricted filesystem access can read that credential file.
Use credentials with an acceptable account and spending scope.

Vercel MCP is opt-in because enabling it transfers Vercel OAuth credentials to
the Sprite. Keep Vercel project setup and administration local unless the
Sprite specifically requires that capability. The current installer can invoke
an interactive OAuth flow while registering the MCP; on a headless Sprite, its
loopback callback is not reachable from your browser without forwarding. Do not
enable this option for unattended provisioning.

## Usage

```text
./setup.sh --name SPRITE_NAME [options]
```

Options accept either form:

```bash
./setup.sh --name test --install_docker true
./setup.sh --name=test --install_docker=true
```

Missing values and unknown positional arguments produce an explicit error and
exit with status `2`.

### Primary options

| Option | Default | Description |
|---|---:|---|
| `--name NAME` | required | Sprite to create or update. Must be lowercase alphanumeric with optional internal hyphens. `--sprite_name` is the underlying config-key form. |
| `--repo OWNER/REPO` | none | GitHub repository to clone under `/home/sprite`. Enables repository deploy-key setup by default. |
| `--config PATH` | automatic | Read permanent defaults from a specific flat YAML file. |
| `--dry-run` | `false` | Print the resolved plan without creating or changing a Sprite. |
| `-h`, `--help` | — | Print help and exit successfully. |

### Component options

| Option | Default | Description |
|---|---:|---|
| `--install_codex BOOL` | `true` | Install Codex CLI, configure its model, and copy local Codex authentication. |
| `--install_yarn BOOL` | `true` | Install Yarn globally through npm. |
| `--install_playwright_mcp BOOL` | `true` | Install Playwright MCP, install Chrome, and register the MCP with Codex. Requires Codex. |
| `--configure_repo_deploy_key BOOL` | `true` | With `repo` set, generate and register a repository-scoped write deploy key, clone the repository, and verify push access. |
| `--install_gh BOOL` | `false` | Copy broad GitHub CLI authentication and the configured personal SSH key. |
| `--install_vercel_mcp BOOL` | `false` | Register Vercel MCP and transfer its OAuth credential record. Requires Codex. |
| `--install_docker BOOL` | `false` | Install Sprite-compatible Docker Engine and Docker Compose. |
| `--install_openssh BOOL` | `false` | Install OpenSSH server and register `sshd` as a Sprite service. |
| `--install_cheatsheet BOOL` | `false` | Install `~/CHEATSHEET.md` with notes for enabled components. |

### Credential and service settings

| Option | Default | Description |
|---|---|---|
| `--codex_auth_file PATH` | `$HOME/.codex/auth.json` | Local Codex authentication file copied to the Sprite. |
| `--codex_model MODEL` | inherited | Codex model written to the Sprite's `~/.codex/config.toml`. |
| `--codex_mcp_credentials_file PATH` | `$HOME/.codex/.credentials.json` | Local file-backed MCP OAuth store used by the optional Vercel installer. Only Vercel records are selected. |
| `--gh_ssh_key PATH` | `$HOME/.ssh/id_ed25519` | Personal SSH private key copied only when broad GitHub authentication is enabled. The matching `.pub` file must exist. |
| `--vercel_mcp_url URL` | `https://mcp.vercel.com` | Remote Vercel MCP endpoint. |
| `--docker_ghcr_login BOOL` | `true` | Log Docker into `ghcr.io` using the GitHub token. Relevant only when Docker and broad GitHub authentication are enabled. |
| `--docker_ghcr_user USER` | `proteanP` | Username supplied for `ghcr.io` authentication. |

## Configuration

Permanent defaults live in [`config.yaml`](config.yaml). It is intentionally a
flat `key: value` file so the shell bootstrap can parse it without a YAML
dependency.

Configuration resolution order:

1. Command-line options
2. The file supplied with `--config`
3. `config.yaml` next to `setup.sh`
4. The published `config.yaml` from GitHub Pages

Every configuration key can be overridden for one run:

```bash
./setup.sh \
  --name app-dev \
  --repo owner/app \
  --install_docker true \
  --install_playwright_mcp false
```

A custom configuration file can define reusable profile defaults:

```yaml
install_codex: true
install_yarn: true
install_playwright_mcp: false
install_docker: true
install_vercel_mcp: false
configure_repo_deploy_key: true
```

Then apply it with:

```bash
./setup.sh --name app-dev --repo owner/app --config ./docker-profile.yaml
```

### Complete configuration reference

| Key | Default | Purpose |
|---|---|---|
| `sprite_name` | empty | Sprite name; normally supplied through `--name`. |
| `repo` | empty | Optional GitHub repository in `owner/repo` form. |
| `configure_repo_deploy_key` | `true` | Configure repository-scoped write access when `repo` is set. |
| `install_gh` | `false` | Transfer broad GitHub authentication and a personal SSH key. |
| `gh_ssh_key` | `$HOME/.ssh/id_ed25519` | Personal SSH private key used by broad GitHub authentication. |
| `install_codex` | `true` | Install and authenticate Codex. |
| `codex_auth_file` | `$HOME/.codex/auth.json` | Source Codex authentication file. |
| `codex_model` | local top-level model | Model configured on the Sprite. |
| `install_yarn` | `true` | Install Yarn. |
| `install_playwright_mcp` | `true` | Install and register Playwright MCP. |
| `install_vercel_mcp` | `false` | Register and authenticate Vercel MCP. |
| `codex_mcp_credentials_file` | `$HOME/.codex/.credentials.json` | Source file-backed MCP OAuth credential store. |
| `vercel_mcp_url` | `https://mcp.vercel.com` | Vercel MCP URL. |
| `install_docker` | `false` | Install Docker Engine and Compose. |
| `docker_ghcr_login` | `true` | Authenticate Docker with GitHub Container Registry. |
| `docker_ghcr_user` | `proteanP` | GitHub Container Registry username. |
| `install_openssh` | `false` | Install OpenSSH server and configure `sshd`. |
| `install_cheatsheet` | `false` | Install the Sprite cheatsheet. |

## Common examples

Default development Sprite without a repository:

```bash
./setup.sh --name sandbox
```

Repository development Sprite with scoped push access:

```bash
./setup.sh --name app-dev --repo owner/app
```

Enable Docker:

```bash
./setup.sh --name app-dev --repo owner/app --install_docker true
```

Disable Playwright MCP:

```bash
./setup.sh --name app-dev --repo owner/app \
  --install_playwright_mcp false
```

Use broad GitHub authentication instead of a deploy key:

```bash
./setup.sh --name multi-repo \
  --repo owner/app \
  --configure_repo_deploy_key false \
  --install_gh true
```

Explicitly enable Vercel MCP:

```bash
./setup.sh --name vercel-test --install_vercel_mcp true
```

## Remote usage

The repository is published through GitHub Pages:

```bash
curl -fsSL https://proteanp.github.io/sprite-environment/setup.sh \
  -o /tmp/setup.sh
bash /tmp/setup.sh --name app-dev --repo owner/app
```

Download the script before running it. Do not pipe it directly into Bash:
`sprite exec` consumes standard input, which can truncate a piped bootstrap.
The component installers avoid stdin where possible, but downloaded execution
is still the supported remote pattern.

In remote mode, `setup.sh` downloads the published `config.yaml` and each
required component script from GitHub Pages.

## Prerequisites

Base requirements:

- The Sprite CLI is installed and authenticated.
- Node.js and npm are available in the Sprite base environment.
- `~/.codex/auth.json` exists locally when Codex installation is enabled.
- The local top-level Codex model is configured, or `codex_model` is provided.

For repository deploy keys:

- The local `gh` CLI is installed and authenticated.
- The authenticated GitHub account can administer deploy keys on the selected
  repository.

For broad GitHub authentication:

- `gh auth login` is complete locally.
- The configured personal SSH key and its `.pub` file exist.

For Docker registry authentication:

- Broad GitHub authentication is enabled.
- The local GitHub token has package-read permission when private GHCR images
  are required.

For Vercel MCP:

- Vercel is registered locally as `https://mcp.vercel.com`.
- `mcp_oauth_credentials_store = "file"` is configured in the local
  `~/.codex/config.toml`.
- The configured MCP credential store contains an authorized Vercel record.
- Be prepared for an interactive OAuth prompt and callback forwarding. Vercel
  MCP is not part of the unattended default profile.

## Updating an existing Sprite

Running the bootstrap again with the same name updates the existing Sprite
instead of recreating it:

```bash
./setup.sh --name app-dev --repo owner/app
```

Install scripts are designed to be idempotent. Repository setup reuses the
existing Sprite-local deploy key when it is already registered and updates the
checkout's SSH configuration.

## Validation

The final validation stage checks only enabled components. Depending on the
resolved plan, checks include:

- Codex installation, authentication, configured model, and a functional
  non-interactive Codex request
- Playwright MCP installation and registration
- Vercel MCP registration and OAuth credential presence
- Yarn installation
- Broad GitHub authentication and SSH-key presence
- Repository deploy-key presence, cloned checkout, fetch access, and dry-run
  push access
- Docker, Compose, daemon health, and optional GHCR authentication
- OpenSSH and the `sshd` Sprite service
- Cheatsheet presence

Provisioning succeeds only when the validation summary reports zero failures.

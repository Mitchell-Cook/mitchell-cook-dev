# mitchell-cook-dev

The single source of truth for **[mitchellcook.dev](https://mitchellcook.dev)** — the
website *and* the server it runs on. Edit here, `git push`, and it goes live.

The site is currently plain HTML/CSS. It'll grow (and may pick up frameworks) over
time; the deploy pipeline doesn't care what the site is built with, only what lands
in `site/`.

## Layout

```
site/                        the website (static HTML/CSS for now)
infra/                       server config, codified from the setup guide
  nginx/mitchellcook.dev.conf
  ssh/99-hardening.conf
  fail2ban/jail.local
  sysctl/99-swappiness.conf
  apt/                       unattended-upgrades config
  mise/config.toml           runtime versions
  shell/.zshrc
scripts/
  apply.sh                   SAFE deploy: site + nginx, validate, reload (runs on every push)
  provision.sh               FULL server setup, idempotent (run by hand — sensitive)
  deploy.sh                  deploy from your Mac (what CI does, manually)
.github/workflows/deploy.yml push to main -> apply.sh on the droplet
```

## How deploys work

Two clearly separated paths, split for safety:

| | Runs when | Touches | Risk |
|---|---|---|---|
| **`apply.sh`** | every push to `main` (via CI) | `site/` + nginx config, then `nginx -t` && reload | Low, reversible |
| **`provision.sh`** | only when you run it by hand | sshd, ufw, fail2ban, users, swap, packages, mise, TLS | Sensitive — could lock you out |

The push-to-deploy loop only ever runs the safe `apply.sh`. Server-level changes are
deliberate, never automatic.

### Deploy from your Mac

```bash
cp .deploy.env.example .deploy.env   # fill in once (gitignored)
./scripts/deploy.sh
```

### Deploy via GitHub Actions

Push to `main` (or run the workflow manually). Requires these repo **secrets**
(Settings → Secrets and variables → Actions):

| Secret | What |
|---|---|
| `DEPLOY_HOST` | droplet IP (or hostname) |
| `DEPLOY_USER` | the non-root login user |
| `DEPLOY_SSH_KEY` | private half of a **dedicated CI deploy key** (not your personal key) |
| `DEPLOY_KNOWN_HOSTS` | output of `ssh-keyscan <droplet-ip>` (pins the host key) |

## Provisioning a box from scratch

On a fresh Ubuntu 24.04 droplet, once the repo is synced there:

```bash
sudo PRIMARY_USER=<user> ADMIN_EMAIL=<email> bash ~/mitchell-cook-dev/scripts/provision.sh
```

Keep the DigitalOcean web console open the first time — the SSH/ufw steps can lock
you out if something's wrong, and the console bypasses SSH.

## Why no secrets live here

The repo is public-safe by design. Host IP, SSH username, and email are **never**
committed — they come from GitHub Secrets (CI) or an untracked `.deploy.env` (local).
No private keys or TLS material are ever pulled into the repo. The config files
describe a hardened posture, which is fine to share; a sound config doesn't rely on
being secret.

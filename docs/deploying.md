# Deploying

Two clearly separated deploy paths, split for safety:

| | Runs when | Touches | Risk |
|---|---|---|---|
| **`apply.sh`** | every push to `main` (via CI) | `site/` + nginx config, then `nginx -t` && reload | Low, reversible |
| **`provision.sh`** | only when you run it by hand | sshd, ufw, fail2ban, users, swap, packages, mise, TLS | Sensitive — could lock you out |

The push-to-deploy loop only ever runs the safe `apply.sh`. Server-level changes are
deliberate, never automatic. For `provision.sh`, see [provisioning.md](provisioning.md).

## Deploy from your Mac

```bash
cp .deploy.env.example .deploy.env   # fill in once (gitignored)
./scripts/deploy.sh
```

## Deploy via GitHub Actions

Push to `main` (or run the workflow manually). Requires these repo **secrets**
(Settings → Secrets and variables → Actions):

| Secret | What |
|---|---|
| `DEPLOY_HOST` | droplet IP (or hostname) |
| `DEPLOY_USER` | the non-root login user |
| `DEPLOY_SSH_KEY` | private half of a **dedicated CI deploy key** (not your personal key) |
| `DEPLOY_KNOWN_HOSTS` | output of `ssh-keyscan <droplet-ip>` (pins the host key) |

## Why no secrets live in the repo

The repo is public-safe by design. Host IP, SSH username, and email are **never**
committed — they come from GitHub Secrets (CI) or an untracked `.deploy.env` (local).
No private keys or TLS material are ever pulled into the repo. The config files describe
a hardened posture, which is fine to share; a sound config doesn't rely on being secret.

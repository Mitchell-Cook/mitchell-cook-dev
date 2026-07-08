# mitchell-cook-dev

Monorepo and single source of truth for **[mitchellcook.dev](https://mitchellcook.dev)** —
Mitchell Cook's personal dev site *and* the server it runs on. (This repo is Mitchell's;
"the user" is Mitchell.)

## What this is / why it exists

A personal playground: publish blog posts and random thoughts, and host prototypes or
demos for whatever ideas Mitchell wants to experiment with. Low-stakes and meant to
evolve freely. The site is plain HTML/CSS today and may pick up frameworks later — the
deploy pipeline doesn't care what it's built with, only what lands in `site/`.

## How it runs

Public GitHub repo → push to `main` → GitHub Actions runs `apply.sh` on a single
DigitalOcean droplet. `mitchellcook.dev` DNS points at that droplet's IP. One box, one
domain, edit-here-and-it-goes-live.

## Repo map

- `site/` — the website (static HTML/CSS for now); the only thing auto-deploy publishes
- `infra/` — server config codified as files: nginx, sshd hardening, fail2ban, sysctl,
  apt/unattended-upgrades, mise runtimes, shell
- `scripts/` — `apply.sh` (safe auto-deploy), `provision.sh` (full server setup, manual),
  `deploy.sh` (deploy from Mac)
- `.github/workflows/deploy.yml` — push-to-`main` → `apply.sh` on the droplet

## Guardrails

- **Public repo — no secrets, ever.** Host IP, SSH user, email, keys, and TLS material
  are never committed; they come from GitHub Secrets (CI) or an untracked `.deploy.env`
  (local). Keep config files generic and parameterized.
- **Two deploy paths, split for safety.** `apply.sh` is safe and runs on every push
  (site + nginx, validated, reload). `provision.sh` is sensitive (sshd, ufw, fail2ban,
  users, TLS) and is **only ever run by hand** — never wire it into automation or run it
  unprompted.

## Reference docs (read when relevant)

- `docs/deploying.md` — push-to-deploy, deploy from Mac, CI secrets, why no secrets live here
- `docs/provisioning.md` — standing up a fresh droplet with `provision.sh` (rare, sensitive)

Read these when doing deploy/infra work rather than duplicating them here.

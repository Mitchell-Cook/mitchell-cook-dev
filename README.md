# mitchell-cook-dev

The single source of truth for **[mitchellcook.dev](https://mitchellcook.dev)** — the
website *and* the server it runs on. Edit here, `git push`, and it goes live.

The site is currently plain HTML/CSS. It'll grow (and may pick up frameworks) over time;
the deploy pipeline doesn't care what the site is built with, only what lands in `site/`.

## Layout

```
site/     the website (static HTML/CSS for now)
infra/    server config, codified (nginx, ssh, fail2ban, sysctl, apt, mise, shell)
scripts/  apply.sh (safe auto-deploy) · provision.sh (manual setup) · deploy.sh (from Mac)
```

Push to `main` runs the safe `apply.sh` on the droplet via GitHub Actions. Nothing
secret lives in this repo — host, user, email, and keys come from GitHub Secrets or an
untracked `.deploy.env`.

## Docs

- [Deploying](docs/deploying.md) — push-to-deploy, deploy from your Mac, CI secrets
- [Provisioning](docs/provisioning.md) — standing up a fresh droplet from scratch

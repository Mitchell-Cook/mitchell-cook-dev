# Provisioning a box from scratch

`provision.sh` does the full, sensitive server setup — sshd, ufw, fail2ban, users, swap,
packages, mise, TLS. It's idempotent, but it's the one script that can lock you out, so
it's **only ever run by hand**, never by CI.

On a fresh Ubuntu 24.04 droplet, once the repo is synced there:

```bash
sudo PRIMARY_USER=<user> ADMIN_EMAIL=<email> bash ~/mitchell-cook-dev/scripts/provision.sh
```

Keep the DigitalOcean web console open the first time — the SSH/ufw steps can lock you
out if something's wrong, and the console bypasses SSH.

For the routine, safe deploy path (`apply.sh`), see [deploying.md](deploying.md).

#!/usr/bin/env bash
#
# provision.sh — reproduce the whole droplet from source. Runs ON the droplet.
#
# This is the codified version of droplet-setup-guide.md. It is idempotent:
# re-running it is safe. Unlike apply.sh, it touches SENSITIVE things (sshd, ufw,
# fail2ban, users), so it is NOT run on every push — you run it deliberately.
#
#   ⚠️  Keep the DigitalOcean web console open as a lockout safety net the first
#       time you run the SSH-hardening / ufw steps.
#
# Usage (on a fresh or existing Ubuntu 24.04 droplet, from the synced repo):
#   sudo PRIMARY_USER=<user> ADMIN_EMAIL=<email> bash ~/mitchell-cook-dev/scripts/provision.sh
#
# Required env:
#   PRIMARY_USER   the non-root login user (created if missing, passwordless sudo)
#   ADMIN_EMAIL    email for Let's Encrypt registration
# Optional env:
#   DOMAIN         defaults to mitchellcook.dev
set -euo pipefail

: "${PRIMARY_USER:?set PRIMARY_USER (the non-root login user)}"
: "${ADMIN_EMAIL:?set ADMIN_EMAIL (for the TLS certificate)}"
DOMAIN="${DOMAIN:-mitchellcook.dev}"
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
USER_HOME="/home/${PRIMARY_USER}"

if [[ $EUID -ne 0 ]]; then
  echo "!! Run with sudo/root." >&2
  exit 1
fi

echo "############################################################"
echo "# Provisioning ${DOMAIN} for user '${PRIMARY_USER}'"
echo "############################################################"

# ── Packages ───────────────────────────────────────────────────────────────
echo "==> [1/11] apt packages"
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y \
  zsh ufw fail2ban unattended-upgrades nginx certbot python3-certbot-nginx \
  curl rsync git ca-certificates \
  autoconf patch build-essential rustc libssl-dev libyaml-dev libreadline-dev \
  zlib1g-dev libgmp-dev libncurses-dev libffi-dev libgdbm-dev libdb-dev uuid-dev

# ── Primary user + passwordless sudo ─────────────────────────────────────────
echo "==> [2/11] user '${PRIMARY_USER}'"
if ! id -u "${PRIMARY_USER}" >/dev/null 2>&1; then
  adduser --disabled-password --gecos "" "${PRIMARY_USER}"
fi
echo "${PRIMARY_USER} ALL=(ALL) NOPASSWD:ALL" > "/etc/sudoers.d/90-${PRIMARY_USER}"
chmod 440 "/etc/sudoers.d/90-${PRIMARY_USER}"
# Seed the user's SSH key from root's authorized_keys (first run on a fresh box).
if [[ -f /root/.ssh/authorized_keys && ! -f "${USER_HOME}/.ssh/authorized_keys" ]]; then
  install -d -m 700 -o "${PRIMARY_USER}" -g "${PRIMARY_USER}" "${USER_HOME}/.ssh"
  install -m 600 -o "${PRIMARY_USER}" -g "${PRIMARY_USER}" \
    /root/.ssh/authorized_keys "${USER_HOME}/.ssh/authorized_keys"
fi

# ── SSH hardening ────────────────────────────────────────────────────────────
echo "==> [3/11] sshd hardening"
install -m 0644 "${REPO_DIR}/infra/ssh/99-hardening.conf" \
  /etc/ssh/sshd_config.d/99-hardening.conf
sshd -t
systemctl restart ssh

# ── Firewall ─────────────────────────────────────────────────────────────────
echo "==> [4/11] ufw"
ufw --force default deny incoming
ufw --force default allow outgoing
ufw allow 22/tcp
ufw allow 80/tcp    # required for Let's Encrypt http-01 renewals
ufw allow 443/tcp
ufw --force enable

# ── fail2ban ─────────────────────────────────────────────────────────────────
echo "==> [5/11] fail2ban"
install -m 0644 "${REPO_DIR}/infra/fail2ban/jail.local" /etc/fail2ban/jail.local
systemctl enable --now fail2ban
systemctl restart fail2ban

# ── Swap (2G) ────────────────────────────────────────────────────────────────
echo "==> [6/11] swap"
if [[ ! -f /swapfile ]]; then
  fallocate -l 2G /swapfile
  chmod 600 /swapfile
  mkswap /swapfile
  swapon /swapfile
  grep -q '^/swapfile ' /etc/fstab || echo '/swapfile none swap sw 0 0' >> /etc/fstab
fi
install -m 0644 "${REPO_DIR}/infra/sysctl/99-swappiness.conf" \
  /etc/sysctl.d/99-swappiness.conf
sysctl --system >/dev/null

# ── Automatic security updates ───────────────────────────────────────────────
echo "==> [7/11] unattended-upgrades"
install -m 0644 "${REPO_DIR}/infra/apt/20auto-upgrades" \
  /etc/apt/apt.conf.d/20auto-upgrades
install -m 0644 "${REPO_DIR}/infra/apt/52unattended-upgrades-reboot" \
  /etc/apt/apt.conf.d/52unattended-upgrades-reboot

# ── zsh + .zshrc ─────────────────────────────────────────────────────────────
echo "==> [8/11] zsh"
chsh -s "$(command -v zsh)" "${PRIMARY_USER}"
install -m 0644 -o "${PRIMARY_USER}" -g "${PRIMARY_USER}" \
  "${REPO_DIR}/infra/shell/.zshrc" "${USER_HOME}/.zshrc"

# ── mise + runtimes (as the primary user) ────────────────────────────────────
echo "==> [9/11] mise + runtimes"
if [[ ! -x "${USER_HOME}/.local/bin/mise" ]]; then
  sudo -u "${PRIMARY_USER}" bash -c 'curl -fsSL https://mise.run | sh'
fi
install -d -m 755 -o "${PRIMARY_USER}" -g "${PRIMARY_USER}" "${USER_HOME}/.config/mise"
install -m 0644 -o "${PRIMARY_USER}" -g "${PRIMARY_USER}" \
  "${REPO_DIR}/infra/mise/config.toml" "${USER_HOME}/.config/mise/config.toml"
sudo -u "${PRIMARY_USER}" "${USER_HOME}/.local/bin/mise" install || \
  echo "!! mise install had errors (runtimes can be retried later with 'mise install')"

# ── nginx + TLS cert ─────────────────────────────────────────────────────────
echo "==> [10/11] nginx + Let's Encrypt"
install -d -o www-data -g www-data "/var/www/${DOMAIN}"

if [[ ! -d "/etc/letsencrypt/live/${DOMAIN}" ]]; then
  # Bootstrap: a temporary HTTP-only server so the ACME http-01 challenge can be
  # answered from the webroot, then obtain the cert WITHOUT letting certbot edit
  # our nginx config (certonly). After this the real config (which references the
  # cert) validates cleanly.
  echo "    no cert yet — bootstrapping HTTP-only vhost for ACME challenge"
  cat > /etc/nginx/sites-available/"${DOMAIN}" <<EOF
server {
    listen 80;
    listen [::]:80;
    server_name ${DOMAIN} www.${DOMAIN};
    root /var/www/${DOMAIN};
    location / { try_files \$uri \$uri/ =404; }
}
EOF
  ln -sf "/etc/nginx/sites-available/${DOMAIN}" "/etc/nginx/sites-enabled/${DOMAIN}"
  rm -f /etc/nginx/sites-enabled/default
  nginx -t && systemctl reload nginx
  certbot certonly --webroot -w "/var/www/${DOMAIN}" \
    -d "${DOMAIN}" -d "www.${DOMAIN}" \
    --agree-tos -m "${ADMIN_EMAIL}" --no-eff-email --non-interactive \
    --deploy-hook "systemctl reload nginx"
fi

# ── Site content + final (HTTPS) nginx config ────────────────────────────────
echo "==> [11/11] deploy site + final nginx config"
DOMAIN="${DOMAIN}" bash "${REPO_DIR}/scripts/apply.sh"

echo
echo "############################################################"
echo "# Done. https://${DOMAIN} should be live."
echo "# Verify: curl -sI https://${DOMAIN}"
echo "############################################################"

#!/usr/bin/env bash
#
# apply.sh — the SAFE, on-every-push deploy step. Runs ON the droplet with sudo.
#
# It only touches reversible, low-risk things:
#   1. syncs the site content into the web root
#   2. installs the version-controlled nginx site config
#   3. validates nginx, and only reloads if the config is good
#
# It does NOT touch sshd, ufw, fail2ban, users, or packages — that's provision.sh.
#
# Usage (from CI or scripts/deploy.sh, after the repo is synced to the droplet):
#   sudo bash ~/mitchell-cook-dev/scripts/apply.sh
set -euo pipefail

DOMAIN="${DOMAIN:-mitchellcook.dev}"
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WEBROOT="/var/www/${DOMAIN}"

echo "==> Deploying ${DOMAIN} from ${REPO_DIR}"

# 1. Site content -----------------------------------------------------------
install -d -o www-data -g www-data "${WEBROOT}"
rsync -a --delete "${REPO_DIR}/site/" "${WEBROOT}/"
chown -R www-data:www-data "${WEBROOT}"
echo "    site synced -> ${WEBROOT}"

# 2. nginx site config ------------------------------------------------------
install -m 0644 "${REPO_DIR}/infra/nginx/${DOMAIN}.conf" \
  "/etc/nginx/sites-available/${DOMAIN}"
ln -sf "/etc/nginx/sites-available/${DOMAIN}" \
  "/etc/nginx/sites-enabled/${DOMAIN}"
rm -f /etc/nginx/sites-enabled/default
echo "    nginx site config installed"

# 3. Validate, then reload (never reload a broken config) -------------------
if nginx -t; then
  systemctl reload nginx
  echo "==> nginx reloaded. Done."
else
  echo "!! nginx config test FAILED — leaving the running config untouched." >&2
  exit 1
fi

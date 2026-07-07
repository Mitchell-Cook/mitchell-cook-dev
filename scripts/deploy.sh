#!/usr/bin/env bash
#
# deploy.sh — deploy from your Mac by hand (the same thing CI does on push).
#
# Reads connection details from an untracked .deploy.env (see .deploy.env.example),
# so no host/user/IP is ever committed. Syncs the repo to the droplet and runs the
# safe apply.sh there.
#
# Usage:
#   cp .deploy.env.example .deploy.env   # fill in once
#   ./scripts/deploy.sh
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Load DEPLOY_HOST / DEPLOY_USER (and friends) from the untracked env file.
if [[ -f "${REPO_DIR}/.deploy.env" ]]; then
  # shellcheck disable=SC1091
  source "${REPO_DIR}/.deploy.env"
else
  echo "!! ${REPO_DIR}/.deploy.env not found. Copy .deploy.env.example and fill it in." >&2
  exit 1
fi

: "${DEPLOY_HOST:?set DEPLOY_HOST in .deploy.env}"
: "${DEPLOY_USER:?set DEPLOY_USER in .deploy.env}"
REMOTE_DIR="${REMOTE_DIR:-mitchell-cook-dev}"

echo "==> Syncing repo to ${DEPLOY_USER}@${DEPLOY_HOST}:~/${REMOTE_DIR}"
rsync -az --delete \
  --exclude '.git' \
  --exclude '.deploy.env' \
  "${REPO_DIR}/" "${DEPLOY_USER}@${DEPLOY_HOST}:${REMOTE_DIR}/"

echo "==> Applying on the droplet"
ssh "${DEPLOY_USER}@${DEPLOY_HOST}" "sudo bash ~/${REMOTE_DIR}/scripts/apply.sh"

echo "==> Deployed. https://${DOMAIN:-mitchellcook.dev}"

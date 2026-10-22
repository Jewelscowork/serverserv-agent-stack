#!/usr/bin/env bash
# Install self-hosted n8n (Community Edition) with automatic HTTPS on a fresh Ubuntu VPS.
#
# Usage (as root):
#   DOMAIN_NAME=example.com SUBDOMAIN=n8n SSL_EMAIL=you@example.com bash install.sh
# Optional: GENERIC_TIMEZONE=America/Toronto  INSTALL_DIR=/opt/n8n
# Point an A record for SUBDOMAIN.DOMAIN_NAME at this server BEFORE running.
set -euo pipefail

[[ $EUID -eq 0 ]] || { echo "Run as root (sudo -i)."; exit 1; }
: "${DOMAIN_NAME:?set DOMAIN_NAME, e.g. example.com}"
: "${SUBDOMAIN:?set SUBDOMAIN, e.g. n8n}"
: "${SSL_EMAIL:?set SSL_EMAIL for the Lets Encrypt certificate}"
GENERIC_TIMEZONE="${GENERIC_TIMEZONE:-UTC}"
INSTALL_DIR="${INSTALL_DIR:-/opt/n8n}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

EXTRA_PORTS="80 443" bash "$HERE/../common/harden.sh"

# Docker Engine + Compose plugin (official convenience script)
if ! command -v docker >/dev/null; then
  curl -fsSL https://get.docker.com | sh
fi
systemctl enable --now docker

mkdir -p "$INSTALL_DIR/local-files"
cp "$HERE/docker-compose.yml" "$INSTALL_DIR/docker-compose.yml"
umask 077
cat > "$INSTALL_DIR/.env" <<ENV
DOMAIN_NAME=$DOMAIN_NAME
SUBDOMAIN=$SUBDOMAIN
GENERIC_TIMEZONE=$GENERIC_TIMEZONE
SSL_EMAIL=$SSL_EMAIL
ENV

cd "$INSTALL_DIR"
docker compose pull
docker compose up -d

echo
echo "n8n is starting at https://$SUBDOMAIN.$DOMAIN_NAME"
echo "Open it and create the owner account straight away."
echo "Update later with:  cd $INSTALL_DIR && docker compose pull && docker compose up -d"

#!/usr/bin/env bash
# Install OpenClaw on a fresh Ubuntu VPS, following docs.openclaw.ai (Linux platform guide).
# The gateway stays on loopback (127.0.0.1:18789). Reach the dashboard with an SSH tunnel.
#
# Usage (as root):  bash install.sh
# Options:          OC_USER=openclaw  (Linux user that runs the agent)
set -euo pipefail

[[ $EUID -eq 0 ]] || { echo "Run as root (sudo -i)."; exit 1; }
OC_USER="${OC_USER:-openclaw}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

bash "$HERE/../common/harden.sh"

# Node.js 24 LTS (OpenClaw needs Node 24.16+ or 26.1+)
if ! command -v node >/dev/null || [[ $(node -p 'process.versions.node.split(".")[0]') -lt 24 ]]; then
  curl -fsSL https://deb.nodesource.com/setup_24.x | bash -
  apt-get install -y nodejs
fi

# Dedicated non-root user
id "$OC_USER" >/dev/null 2>&1 || useradd -m -s /bin/bash "$OC_USER"
# Keep the user's systemd services running after logout (the gateway is a user service)
loginctl enable-linger "$OC_USER"

# Install OpenClaw for that user (user-level npm prefix, no sudo needed later)
sudo -iu "$OC_USER" bash <<'USR'
set -euo pipefail
mkdir -p "$HOME/.npm-global"
npm config set prefix "$HOME/.npm-global"
grep -q npm-global "$HOME/.bashrc" || echo 'export PATH="$HOME/.npm-global/bin:$PATH"' >> "$HOME/.bashrc"
export PATH="$HOME/.npm-global/bin:$PATH"
if npm i -g openclaw@latest --allow-scripts=openclaw 2>/dev/null; then :; else npm i -g openclaw@latest; fi
openclaw --version
USR

cat <<MSG

OpenClaw is installed for user '$OC_USER'.

Finish setup (needs the customer's model API key and chat channels):
  sudo -iu $OC_USER
  openclaw onboard --install-daemon
  openclaw gateway status --deep

Open the dashboard from your own computer:
  ssh -N -L 18789:127.0.0.1:18789 root@<server-ip>
  then visit http://127.0.0.1:18789/ and sign in with the gateway token.

Keep the gateway on loopback. If you ever bind it to LAN or a tailnet,
set gateway.auth.token or gateway.auth.password first.
MSG

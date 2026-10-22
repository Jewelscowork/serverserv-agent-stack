#!/usr/bin/env bash
# Baseline hardening for a fresh Ubuntu 22.04/24.04 VPS.
# Safe by default: SSH password login is only disabled if an SSH key is already installed.
set -euo pipefail

[[ $EUID -eq 0 ]] || { echo "Run as root (sudo -i)."; exit 1; }
EXTRA_PORTS="${EXTRA_PORTS:-}"   # e.g. "80 443" for web apps

export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get upgrade -y
apt-get install -y curl ca-certificates gnupg ufw fail2ban unattended-upgrades

# Automatic security updates
dpkg-reconfigure -f noninteractive unattended-upgrades

# Firewall: SSH plus any extra ports
ufw default deny incoming
ufw default allow outgoing
ufw allow OpenSSH
for p in $EXTRA_PORTS; do ufw allow "$p/tcp"; done
ufw --force enable

# Brute-force protection for SSH
systemctl enable --now fail2ban

# Key-only SSH, but never lock the owner out
has_key=0
for f in /root/.ssh/authorized_keys /home/*/.ssh/authorized_keys; do
  [[ -s "$f" ]] && has_key=1
done
if [[ $has_key -eq 1 ]]; then
  mkdir -p /etc/ssh/sshd_config.d
  cat > /etc/ssh/sshd_config.d/10-serverserv.conf <<'CONF'
PasswordAuthentication no
KbdInteractiveAuthentication no
PermitRootLogin prohibit-password
CONF
  systemctl reload ssh 2>/dev/null || systemctl reload sshd
  echo "SSH: password login disabled (key found)."
else
  echo "SSH: no key found, password login left ON. Add a key, then re-run this script."
fi

# 2 GB swap on small servers
if ! swapon --show | grep -q . && [[ $(free -m | awk '/Mem:/{print $2}') -lt 8000 ]]; then
  fallocate -l 2G /swapfile && chmod 600 /swapfile && mkswap /swapfile && swapon /swapfile
  grep -q '^/swapfile' /etc/fstab || echo '/swapfile none swap sw 0 0' >> /etc/fstab
fi

echo "Hardening done."

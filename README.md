# serverserv agent stack

Open-source scripts to run **OpenClaw** (AI agent) and **n8n** (workflow automation) on your own Linux VPS, set up securely.

These are the same scripts we use at [serverserv](https://serverserv.com) to prepare customer servers. They work on any Ubuntu 22.04 or 24.04 VPS from any provider.

## What you get

| Script | What it does |
|---|---|
| `common/harden.sh` | Updates, automatic security patches, firewall (UFW), fail2ban, key-only SSH (only if a key is already installed, so you can't lock yourself out), swap on small servers |
| `openclaw/install.sh` | Hardening + Node.js 24 + OpenClaw for a dedicated non-root user. The gateway stays on `127.0.0.1:18789`; you reach the dashboard through an SSH tunnel |
| `n8n/install.sh` | Hardening + Docker + n8n Community Edition behind Traefik with automatic Let's Encrypt HTTPS (based on the official n8n Compose guide) |

## Requirements

- A fresh Ubuntu 22.04 / 24.04 server with root access
- OpenClaw: 2 vCPU and 4 GB RAM is a comfortable start
- n8n: a domain or subdomain pointed at the server (A record)

## Quick start

```bash
git clone https://github.com/Jewelscowork/serverserv-agent-stack.git
cd serverserv-agent-stack
```

**OpenClaw**
```bash
sudo bash openclaw/install.sh
sudo -iu openclaw
openclaw onboard --install-daemon
```
Then, from your own computer:
```bash
ssh -N -L 18789:127.0.0.1:18789 root@YOUR_SERVER_IP
# open http://127.0.0.1:18789/
```

**n8n**
```bash
sudo DOMAIN_NAME=example.com SUBDOMAIN=n8n SSL_EMAIL=you@example.com \
     GENERIC_TIMEZONE=America/Toronto bash n8n/install.sh
```
Open `https://n8n.example.com` and create the owner account right away.

## Security notes

- Add your SSH key **before** running the scripts so password login can be switched off.
- Keep the OpenClaw gateway on loopback. If you bind it to a LAN or tailnet, set `gateway.auth.token` or `gateway.auth.password` first.
- Back up `~/.openclaw` (OpenClaw) and the `n8n_data` Docker volume (n8n) regularly.

## Don't want to run it yourself?

[serverserv](https://serverserv.com) sells KVM servers with [OpenClaw](https://serverserv.com/openclaw-hosting.html) or [n8n](https://serverserv.com/n8n-hosting.html) installed and set up for you.

## License

MIT

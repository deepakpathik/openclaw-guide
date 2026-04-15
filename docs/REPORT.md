# OpenClaw: Easy Setup & Free Hosting on Oracle Cloud

> **Prepared by:** Deepak Pathik
> **Date:** 15 April 2026 | **Version:** 1.0.0 | **Status:** Completed ✅

---

## 1. The Big Picture

This project provides a **one-click** deployment system for getting an OpenClaw AI agent running on Oracle Cloud's Always Free ARM instances. With a single `curl` command, the installer handles all the technical heavy lifting — installing software, setting up a secure VPN, and configuring a firewall — so you can have an AI assistant working 24/7 without paying for servers.

## 2. What We're Building

### 2.1 About OpenClaw

OpenClaw is an open-source AI agent that can browse the web and perform tasks on your behalf. It supports multiple AI backends:

- **Claude** (Anthropic) — Paid API
- **OpenAI** (GPT) — Paid API
- **Ollama** — Free, runs locally on the same VM

### 2.2 Project Goals

- Create a script that deploys everything with one command
- Host it on Oracle's free-tier cloud servers
- Secure the setup with a private VPN and hardened firewall
- Ensure the service auto-restarts on reboot
- Provide clear documentation so anyone can replicate it

## 3. The Free Hardware

### 3.1 What You Get for Free

| Resource | Specification | Cost |
|---|---|---|
| Compute Shape | VM.Standard.A1.Flex (ARM Ampere) | **FREE** |
| OCPUs | 4 vCPUs | **FREE** |
| RAM | 24 GB | **FREE** |
| Storage | 200 GB Block Volume | **FREE** |
| OS | Ubuntu 22.04 LTS (ARM64) | **FREE** |
| Networking | 10 TB/month outbound | **FREE** |
| Tailscale VPN | Up to 3 users / 100 devices | **FREE** |

### 3.2 Quick Tips for Setup

- A credit card is required for identity verification, but you won't be charged
- Upgrading to Pay-As-You-Go unlocks ARM capacity (still free within limits)
- Pick a region close to you that isn't too busy
- If your region is out of capacity, retry later or try another region

## 4. How the System Works

The system is built with **defense in depth** — three layers of security:

| Layer | What It Does | Tool |
|---|---|---|
| **Layer 1** | Oracle's network security list blocks almost all inbound traffic | OCI Security List |
| **Layer 2** | Server-level firewall only allows traffic from the VPN interface | UFW |
| **Layer 3** | Encrypted WireGuard tunnel ensures only authorized devices can connect | Tailscale |

The software runs as a **systemd service** that starts automatically on boot. Sensitive API keys are stored in a permissions-locked `.env` file (`chmod 600`).

## 5. The Quick Installer

### 5.1 What the Script Does

| Step | Action | Tool / Technology |
|---|---|---|
| 1 | System update & prerequisites | `apt-get` |
| 2 | Node.js 20 LTS installation | NodeSource repo |
| 3 | Tailscale VPN installation & auth | Tailscale official installer |
| 4 | UFW firewall hardening | `ufw` (allow only `tailscale0`) |
| 5 | OpenClaw clone & `npm install` | `git` + `npm` |
| 6 | `.env` config file generation | bash heredoc |
| 7 | systemd service registration | `systemctl enable` + `start` |

### 5.2 How to Use It

**Standard install:**
```bash
curl -fsSL https://raw.githubusercontent.com/deepakpathik/openclaw-guide/main/install.sh | sudo bash
```

**Fully unattended:**
```bash
export TAILSCALE_AUTHKEY="tskey-auth-xxxxx"
curl -fsSL https://raw.githubusercontent.com/deepakpathik/openclaw-guide/main/install.sh | sudo bash
```

## 6. Keeping Things Secure

| Security Layer | Implementation | Protects Against |
|---|---|---|
| OCI Security List | Block all ingress; allow only SSH for initial setup | Internet port scans |
| UFW Firewall | Default deny; allow `tailscale0` interface only | Direct VM IP attacks |
| Tailscale VPN | WireGuard-based encrypted tunnel; MFA supported | Unauthorized access |
| `.env` Permissions | `chmod 600` applied to `.env` file | File-level API key exposure |
| systemd Hardening | Runs as non-root `ubuntu` user | Privilege escalation |

## 7. Making It Run Smoothly

### 7.1 Recommended Configuration

- **Cloud AI (Claude / OpenAI):** Best performance — offloads heavy computation to external APIs, keeping the server responsive
- **Local AI (Ollama):** Fully private but slower — runs the LLM on the same VM
- Monitor response times if running everything on a single machine

### 7.2 Useful Commands

```bash
sudo journalctl -u openclaw -f          # Live logs
sudo systemctl status openclaw           # Service health
free -h                                  # RAM usage
tailscale status                         # VPN peers
```

## 8. What Does It Cost?

| Component | Monthly Cost (INR) | Notes |
|---|---|---|
| Oracle Cloud ARM VM | ₹0 | Always Free — 4 OCPU / 24GB |
| Tailscale VPN | ₹0 | Free for personal use |
| OpenClaw Software | ₹0 | Open source |
| Anthropic Claude API | Variable | ~₹0.80 per 1K input tokens |
| Ollama (local LLMs) | ₹0 | Runs free on same VM |
| **TOTAL (no API usage)** | **₹0 / month** | **Fully free stack possible** |

## 9. Project Files

```
openclaw-guide/
├── install.sh          ← One-click installer (main entry)
├── README.md           ← Setup guide
├── scripts/
│   ├── update.sh       ← Pull latest + restart
│   └── uninstall.sh    ← Full removal
├── config/
│   └── .env.example    ← Environment template
└── docs/
    └── REPORT.md       ← This report
```

## 10. Final Thoughts

The installer works as planned. You can now get a secure AI agent up and running on free cloud hardware in under 5 minutes with a single command.

### Ideas for the Future

- Add a web dashboard to manage settings
- Auto-rotate API keys for improved security
- Simplify local AI (Ollama) setup
- Automated testing for installer compatibility across OS versions
- Discord / Slack alerting for service health

---

*— Deepak Pathik*
*Report generated: 15 April 2026*

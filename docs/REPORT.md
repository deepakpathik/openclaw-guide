# OpenClaw: One-Command Setup on Free Cloud Hardware

> **Author:** Deepak Pathik
> **Date:** 15 April 2026 | **Version:** 1.0.0 | **Status:** Completed ✅

---

## 1. What This Project Does

I built a single bash script that sets up an OpenClaw AI agent on Oracle Cloud's Always Free ARM servers. You run one `curl` command. The script installs Node.js, configures a VPN, hardens the firewall, deploys OpenClaw, and registers it as a system service. Five minutes later you have an AI assistant running 24/7 on hardware that costs nothing.

## 2. What OpenClaw Is

OpenClaw is an open-source AI agent — it browses the web, writes code, and runs tasks autonomously. It talks to whichever AI backend you choose:

- **Claude** (Anthropic) — paid API, best quality
- **OpenAI** (GPT) — paid API, strong alternative
- **Ollama** — free, runs the model directly on the same VM

### What I Set Out to Do

- Write a script that deploys the entire stack with one command
- Run it on Oracle Cloud's free-tier ARM servers
- Lock it down with a private VPN and hardened firewall
- Make the service survive reboots automatically
- Document everything clearly enough that someone else can reproduce it

## 3. The Free Hardware

### What Oracle Gives You at No Cost

| Resource | Specification | Cost |
|---|---|---|
| Compute Shape | VM.Standard.A1.Flex (ARM Ampere) | **FREE** |
| OCPUs | 4 vCPUs | **FREE** |
| RAM | 24 GB | **FREE** |
| Storage | 200 GB Block Volume | **FREE** |
| OS | Ubuntu 22.04 LTS (ARM64) | **FREE** |
| Networking | 10 TB/month outbound | **FREE** |
| Tailscale VPN | Up to 3 users / 100 devices | **FREE** |

### Things to Know Before You Start

- Oracle requires a credit card for identity verification — they won't charge it
- Upgrading to Pay-As-You-Go unlocks ARM capacity (still free within the limits)
- Pick a region close to you that isn't overloaded
- If your region shows "out of capacity," try again later or switch regions

## 4. How the Security Works

Three layers protect the system — if one fails, the others still hold:

| Layer | What It Does | Tool |
|---|---|---|
| **Layer 1** | Oracle's network security list blocks nearly all inbound traffic | OCI Security List |
| **Layer 2** | The server's firewall only accepts traffic from the VPN interface | UFW |
| **Layer 3** | An encrypted WireGuard tunnel restricts access to authorized devices only | Tailscale |

OpenClaw runs as a **systemd service** — it starts on boot without anyone logging in. API keys sit in a `.env` file locked to `chmod 600` (only the owner can read it).

## 5. What the Installer Script Does

### Step by Step

| Step | Action | Tool / Technology |
|---|---|---|
| 1 | Updates the system and installs prerequisites | `apt-get` |
| 2 | Installs Node.js 20 LTS | NodeSource repo |
| 3 | Installs Tailscale VPN and authenticates | Tailscale official installer |
| 4 | Hardens the firewall — blocks everything except VPN traffic | `ufw` (allow only `tailscale0`) |
| 5 | Clones OpenClaw and installs dependencies | `git` + `npm` |
| 6 | Generates the `.env` config file | bash heredoc |
| 7 | Registers and starts the systemd service | `systemctl enable` + `start` |

### How to Run It

**Standard install:**
```bash
curl -fsSL https://raw.githubusercontent.com/deepakpathik/openclaw-guide/main/install.sh | sudo bash
```

**Fully unattended (no prompts):**
```bash
export TAILSCALE_AUTHKEY="tskey-auth-xxxxx"
curl -fsSL https://raw.githubusercontent.com/deepakpathik/openclaw-guide/main/install.sh | sudo bash
```

## 6. Security Breakdown

| Security Layer | Implementation | Protects Against |
|---|---|---|
| OCI Security List | Blocks all ingress; allows only SSH for initial setup | Internet port scans |
| UFW Firewall | Default deny; allows only the `tailscale0` interface | Direct attacks on the VM's public IP |
| Tailscale VPN | WireGuard-encrypted tunnel; supports MFA | Unauthorized access |
| `.env` Permissions | `chmod 600` — only the file owner can read it | API key exposure |
| systemd Hardening | Runs as the non-root `ubuntu` user | Privilege escalation |

## 7. Performance

### Choosing the Right AI Backend

- **Cloud AI (Claude / OpenAI):** Fastest — the VM just relays requests to external APIs, so it stays responsive
- **Local AI (Ollama):** Fully private, but slower — the VM runs the model itself alongside OpenClaw
- If you run both OpenClaw and Ollama on one machine, keep an eye on response times

### Useful Commands

```bash
sudo journalctl -u openclaw -f          # Live logs
sudo systemctl status openclaw           # Service health
free -h                                  # RAM usage
tailscale status                         # VPN peers
```

## 8. Cost

| Component | Monthly Cost (INR) | Notes |
|---|---|---|
| Oracle Cloud ARM VM | ₹0 | Always Free — 4 OCPU / 24GB |
| Tailscale VPN | ₹0 | Free for personal use |
| OpenClaw Software | ₹0 | Open source |
| Anthropic Claude API | Variable | ~₹0.80 per 1K input tokens |
| Ollama (local LLMs) | ₹0 | Runs free on same VM |
| **TOTAL (no API usage)** | **₹0 / month** | **Fully free stack** |

## 9. Project Files

```
openclaw-guide/
├── install.sh          ← One-click installer (start here)
├── README.md           ← Setup guide
├── scripts/
│   ├── update.sh       ← Pull latest + restart
│   └── uninstall.sh    ← Full removal
├── config/
│   └── .env.example    ← Environment template
└── docs/
    └── REPORT.md       ← This report
```

## 10. What's Next

The installer works. One command gives you a secure AI agent on free cloud hardware in under 5 minutes.

### Future Improvements

- Build a web dashboard for managing settings without SSH
- Auto-rotate API keys on a schedule
- Streamline local Ollama setup (currently manual)
- Add automated tests across Ubuntu versions
- Set up Discord / Slack alerts for service health

---

*— Deepak Pathik*
*15 April 2026*

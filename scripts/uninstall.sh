#!/bin/bash
# ============================================================
#  OpenClaw Uninstaller — Full removal from Oracle Cloud VM
#  Author  : Deepak
#  Usage   : sudo bash uninstall.sh
# ============================================================

set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'

log()   { echo -e "${GREEN}[✓]${NC} $*"; }
warn()  { echo -e "${YELLOW}[!]${NC} $*"; }
error() { echo -e "${RED}[✗]${NC} $*"; exit 1; }

OPENCLAW_DIR="${OPENCLAW_DIR:-/opt/openclaw}"

echo -e "${RED}${BOLD}"
echo "╔══════════════════════════════════════════╗"
echo "║    OpenClaw Uninstaller                  ║"
echo "║    This will REMOVE OpenClaw completely  ║"
echo "╚══════════════════════════════════════════╝"
echo -e "${NC}"

read -rp "Are you sure you want to remove OpenClaw? [y/N] " confirm
[[ "$confirm" != [yY] ]] && { echo "Aborted."; exit 0; }

# ─── Stop and disable service ──────────────────────────────
echo ""
if systemctl is-active --quiet openclaw 2>/dev/null; then
  systemctl stop openclaw
  log "OpenClaw service stopped"
else
  warn "OpenClaw service was not running"
fi

if systemctl is-enabled --quiet openclaw 2>/dev/null; then
  systemctl disable openclaw >/dev/null 2>&1
  log "OpenClaw service disabled"
fi

# ─── Remove systemd unit file ─────────────────────────────
if [[ -f /etc/systemd/system/openclaw.service ]]; then
  rm -f /etc/systemd/system/openclaw.service
  systemctl daemon-reload
  log "systemd service file removed"
fi

# ─── Remove OpenClaw directory ─────────────────────────────
if [[ -d "$OPENCLAW_DIR" ]]; then
  rm -rf "$OPENCLAW_DIR"
  log "Removed $OPENCLAW_DIR"
else
  warn "$OPENCLAW_DIR not found, skipping"
fi

# ─── Optional: Remove Tailscale ────────────────────────────
echo ""
read -rp "Also remove Tailscale VPN? [y/N] " remove_ts
if [[ "$remove_ts" == [yY] ]]; then
  tailscale down 2>/dev/null || true
  apt-get remove -y tailscale >/dev/null 2>&1 || true
  log "Tailscale removed"
else
  warn "Tailscale kept — you can remove it later with: sudo apt remove tailscale"
fi

# ─── Optional: Reset UFW ──────────────────────────────────
echo ""
read -rp "Reset UFW firewall to defaults? [y/N] " reset_ufw
if [[ "$reset_ufw" == [yY] ]]; then
  ufw --force reset >/dev/null 2>&1
  log "UFW reset to defaults"
else
  warn "UFW rules kept"
fi

# ─── Done ──────────────────────────────────────────────────
echo ""
echo -e "${GREEN}${BOLD}╔══════════════════════════════════════════╗"
echo -e "║    OpenClaw Removed Successfully ✅     ║"
echo -e "╚══════════════════════════════════════════╝${NC}"
echo ""
echo -e "  ${YELLOW}Note:${NC} Node.js was NOT removed (other apps may need it)."
echo -e "  To remove it manually: ${BOLD}sudo apt remove nodejs${NC}"
echo ""

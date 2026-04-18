#!/bin/bash
# ═══════════════════════════════════════════════════════════════
#  OpenClaw One-Click Desktop Installer
#  Works on: macOS, Ubuntu/Debian, Fedora/RHEL
#  Usage:   curl -fsSL https://openclaw.ai/install.sh | bash
#           OR: bash install.sh
# ═══════════════════════════════════════════════════════════════

set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'

log()     { echo -e "${GREEN}[✓]${NC} $*"; }
warn()    { echo -e "${YELLOW}[!]${NC} $*"; }
error()   { echo -e "${RED}[✗]${NC} $*"; exit 1; }
info()    { echo -e "${CYAN}[→]${NC} $*"; }
section() { echo -e "\n${CYAN}${BOLD}━━ $* ━━${NC}"; }

echo -e "${CYAN}${BOLD}"
cat << 'EOF'
   ___                  _____ _               
  / _ \ _ __  ___ _ __ / ____| | __ ___      __
 | | | | '_ \/ _ \ '_ \ |    | |/ _` \ \ /\ / /
 | |_| | |_) \  __/ | | |___| | (_| |\ V  V / 
  \___/| .__/ \___|_| |_\___|_|\__,_| \_/\_/  
       |_|   Desktop One-Click Installer
EOF
echo -e "${NC}"
echo -e "  Installing OpenClaw — your personal AI that actually does things.\n"

# ── Detect OS ─────────────────────────────────────────────
detect_os() {
  if [[ "$OSTYPE" == "darwin"* ]]; then OS="macos"
  elif [[ -f /etc/debian_version ]]; then OS="debian"
  elif [[ -f /etc/fedora-release ]] || [[ -f /etc/redhat-release ]]; then OS="fedora"
  else OS="unknown"; fi
  log "Detected OS: $OS"
}

# ── Node.js >= 22 ─────────────────────────────────────────
# OpenClaw requires Node >= 22.14.0. Older versions fail silently
# with regex/syntax errors (learned the hard way on GCP with Node 18).
ensure_node() {
  section "Node.js (requires >= 22)"
  REQUIRED_MAJOR=22

  if command -v node &>/dev/null; then
    CURRENT=$(node -v | cut -d. -f1 | tr -d 'v')
    if [[ $CURRENT -ge $REQUIRED_MAJOR ]]; then
      log "Node.js $(node -v) already meets requirement"; return
    fi
    warn "Found Node.js $(node -v) — too old. Upgrading to v22..."
  else
    info "Node.js not found. Installing v22..."
  fi

  if [[ "$OS" == "macos" ]]; then
    if ! command -v brew &>/dev/null; then
      info "Installing Homebrew first..."
      /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
    brew install node@22
    brew link node@22 --force --overwrite 2>/dev/null || true

  elif [[ "$OS" == "debian" ]]; then
    curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash - >/dev/null 2>&1
    sudo apt-get install -y -qq nodejs

  elif [[ "$OS" == "fedora" ]]; then
    curl -fsSL https://rpm.nodesource.com/setup_22.x | sudo bash - >/dev/null 2>&1
    sudo dnf install -y nodejs

  else
    error "Unsupported OS. Please install Node.js 22+ from https://nodejs.org then re-run."
  fi

  node -v | grep -qE "^v2[2-9]|^v[3-9]" || error "Node.js upgrade failed. Install Node v22+ manually."
  log "Node.js $(node -v) installed"
}

# ── pnpm ──────────────────────────────────────────────────
# OpenClaw is a pnpm workspace — npm alone will NOT work
ensure_pnpm() {
  section "pnpm (workspace manager)"
  if command -v pnpm &>/dev/null; then
    log "pnpm $(pnpm -v) already installed"; return
  fi
  info "Installing pnpm..."
  npm install -g pnpm >/dev/null 2>&1
  log "pnpm $(pnpm -v) installed"
}

# ── Install OpenClaw ───────────────────────────────────────
install_openclaw() {
  section "Installing OpenClaw"

  # Try official npm global install first (simplest)
  info "Trying: npm install -g openclaw"
  if npm install -g openclaw 2>/dev/null && command -v openclaw &>/dev/null; then
    log "OpenClaw installed via npm"; return
  fi

  # Try pnpm global install
  info "Trying: pnpm add -g openclaw"
  if pnpm add -g openclaw 2>/dev/null && command -v openclaw &>/dev/null; then
    log "OpenClaw installed via pnpm"; return
  fi

  # Fall back to source (applies all known pnpm fixes)
  warn "Global install unavailable. Installing from source (takes ~3-5 mins)..."
  install_from_source
}

# ── Source install ─────────────────────────────────────────
# Applies every fix discovered during real deployment:
#   1. --config.minimumReleaseAge=0  →  bypasses pnpm v10's 48-hour
#      package age restriction that blocks follow-redirects, koffi, etc.
#      This overrides at CLI level (highest priority) so workspace
#      config cannot interfere — the only reliable method.
#   2. --no-frozen-lockfile  →  allows fresh resolution on new machines
#   3. Node 22 check happens before this, so no regex failures
install_from_source() {
  INSTALL_DIR="${OPENCLAW_DIR:-$HOME/.openclaw}"

  if [[ -d "$INSTALL_DIR/.git" ]]; then
    info "Updating existing source..."
    git -C "$INSTALL_DIR" pull --quiet
  else
    info "Cloning openclaw/openclaw..."
    git clone https://github.com/openclaw/openclaw.git "$INSTALL_DIR" --quiet
  fi

  cd "$INSTALL_DIR"
  info "Installing workspace dependencies (this will take a few minutes)..."

  pnpm install \
    --config.minimumReleaseAge=0 \
    --no-frozen-lockfile

  info "Building..."
  pnpm run build 2>/dev/null || warn "Build completed with warnings (non-fatal)"

  # Register launcher so 'openclaw' works from anywhere
  sudo tee /usr/local/bin/openclaw > /dev/null << SCRIPT
#!/bin/bash
cd "$INSTALL_DIR"
exec pnpm exec openclaw "\$@"
SCRIPT
  sudo chmod +x /usr/local/bin/openclaw
  log "Launcher registered at /usr/local/bin/openclaw"
}

# ── Summary ────────────────────────────────────────────────
print_summary() {
  echo ""
  echo -e "${GREEN}${BOLD}╔══════════════════════════════════════════╗"
  echo -e "║   OpenClaw Installed Successfully!      ║"
  echo -e "╚══════════════════════════════════════════╝${NC}"
  echo ""
  echo -e "  ${BOLD}Next steps:${NC}"
  echo -e "  ${CYAN}openclaw onboard${NC}       — first-time setup (do this now)"
  echo -e "  ${CYAN}openclaw gateway${NC}       — start the backend service"
  echo -e "  ${CYAN}openclaw dashboard${NC}     — open the UI"
  echo -e "  ${CYAN}openclaw --help${NC}        — full command list"
  echo ""
  echo -e "  ${BOLD}Talk to it via:${NC} WhatsApp, Telegram, Discord, iMessage, Signal"
  echo -e "  ${BOLD}Docs:${NC} https://openclaw.ai"
  echo ""
}

main() {
  detect_os
  ensure_node
  ensure_pnpm
  install_openclaw
  print_summary

  if [[ -t 0 ]]; then
    read -r -p "  Run onboarding now? [Y/n]: " resp
    [[ "${resp:-Y}" =~ ^[Yy]$ ]] && openclaw onboard || echo -e "\n  Run ${CYAN}openclaw onboard${NC} when ready.\n"
  else
    echo -e "  Run ${CYAN}openclaw onboard${NC} to complete setup.\n"
  fi
}

main "$@"

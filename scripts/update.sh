#!/bin/bash
# update.sh — Pull latest OpenClaw and restart
set -euo pipefail
echo "[*] Pulling latest OpenClaw..."
git -C /opt/openclaw pull --quiet
cd /opt/openclaw && npm install --silent
sudo systemctl restart openclaw
echo "[✓] OpenClaw updated and restarted"
echo "    Status: $(systemctl is-active openclaw)"

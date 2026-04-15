#!/bin/bash
# ─────────────────────────────────────────────────────────────────
# install_splunk_server.sh
# Installs Splunk Enterprise on Ubuntu / Debian (central server)
# Usage: sudo bash install_splunk_server.sh
# ─────────────────────────────────────────────────────────────────

set -e

SPLUNK_VERSION="9.2.1"
SPLUNK_BUILD="78803f08aabb"
SPLUNK_DEB="splunk-${SPLUNK_VERSION}-${SPLUNK_BUILD}-linux-amd64.deb"
SPLUNK_URL="https://download.splunk.com/products/splunk/releases/${SPLUNK_VERSION}/linux/${SPLUNK_DEB}"
SPLUNK_HOME="/opt/splunk"
SPLUNK_ADMIN_PASS="SplunkAdmin123!"   # Change before running!
RECEIVE_PORT=9997

echo "=============================================="
echo " Splunk Enterprise — Server Install Script"
echo "=============================================="

# ── 1. Update system ─────────────────────────────────────────
echo "[1/7] Updating system packages..."
sudo apt-get update -qq

# ── 2. Download Splunk ───────────────────────────────────────
echo "[2/7] Downloading Splunk Enterprise v${SPLUNK_VERSION}..."
wget -q --show-progress -O "/tmp/${SPLUNK_DEB}" "${SPLUNK_URL}"

# ── 3. Install ───────────────────────────────────────────────
echo "[3/7] Installing Splunk..."
sudo dpkg -i "/tmp/${SPLUNK_DEB}"

# ── 4. Start & accept license ────────────────────────────────
echo "[4/7] Starting Splunk and accepting license..."
sudo ${SPLUNK_HOME}/bin/splunk start \
  --accept-license --answer-yes --no-prompt \
  --seed-passwd "${SPLUNK_ADMIN_PASS}"

# ── 5. Enable boot start ─────────────────────────────────────
echo "[5/7] Enabling Splunk at boot..."
sudo ${SPLUNK_HOME}/bin/splunk enable boot-start
sudo systemctl enable Splunkd 2>/dev/null || true

# ── 6. Enable receiving port 9997 ────────────────────────────
echo "[6/7] Enabling forwarder receiving on port ${RECEIVE_PORT}..."
sudo ${SPLUNK_HOME}/bin/splunk enable listen ${RECEIVE_PORT} \
  -auth admin:${SPLUNK_ADMIN_PASS}

# ── 7. Open firewall ports ───────────────────────────────────
echo "[7/7] Configuring UFW firewall..."
if command -v ufw &>/dev/null; then
  sudo ufw allow 9997/tcp comment "Splunk Forwarder Receiver"
  sudo ufw allow 8000/tcp comment "Splunk Web UI"
  sudo ufw allow 8089/tcp comment "Splunk Management"
  sudo ufw --force enable
  echo "UFW rules applied."
else
  echo "UFW not found — skip firewall config. Apply manually."
fi

# ── Done ─────────────────────────────────────────────────────
echo ""
echo "=============================================="
echo " Splunk Server Installation Complete!"
echo "=============================================="
echo " Web UI : http://$(hostname -I | awk '{print $1}'):8000"
echo " User   : admin"
echo " Pass   : ${SPLUNK_ADMIN_PASS}"
echo " Recv   : port ${RECEIVE_PORT} (forwarders)"
echo "=============================================="

# Cleanup
rm -f "/tmp/${SPLUNK_DEB}"

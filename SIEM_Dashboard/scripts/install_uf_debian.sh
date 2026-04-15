#!/bin/bash
# ─────────────────────────────────────────────────────────────────
# install_uf_debian.sh
# Installs Splunk Universal Forwarder on Debian / Ubuntu
# Usage: sudo bash install_uf_debian.sh
# ─────────────────────────────────────────────────────────────────

set -e

SPLUNK_VERSION="9.2.1"
SPLUNK_BUILD="78803f08aabb"
UF_DEB="splunkforwarder-${SPLUNK_VERSION}-${SPLUNK_BUILD}-linux-amd64.deb"
UF_URL="https://download.splunk.com/products/universalforwarder/releases/${SPLUNK_VERSION}/linux/${UF_DEB}"
UF_HOME="/opt/splunkforwarder"
UF_ADMIN_PASS="ForwarderPass123!"   # Change before running!

# ── EDIT THESE ───────────────────────────────────────────────
INDEXER_IP="192.168.1.100"          # Your central Splunk server IP
INDEXER_PORT="9997"
THIS_HOST="$(hostname)"             # Auto-detects hostname
LOG_USER="user"                     # User that owns ssh_autologin.log
# ─────────────────────────────────────────────────────────────

echo "=============================================="
echo " Splunk Universal Forwarder — Debian/Ubuntu"
echo "=============================================="

# ── 1. Update ────────────────────────────────────────────────
echo "[1/6] Updating packages..."
sudo apt-get update -qq

# ── 2. Download UF ───────────────────────────────────────────
echo "[2/6] Downloading Universal Forwarder v${SPLUNK_VERSION}..."
wget -q --show-progress -O "/tmp/${UF_DEB}" "${UF_URL}"

# ── 3. Install ───────────────────────────────────────────────
echo "[3/6] Installing Universal Forwarder..."
sudo dpkg -i "/tmp/${UF_DEB}"

# ── 4. Start & accept license ────────────────────────────────
echo "[4/6] Starting forwarder..."
sudo ${UF_HOME}/bin/splunk start \
  --accept-license --answer-yes --no-prompt

# Set admin password
sudo ${UF_HOME}/bin/splunk edit user admin \
  -password "${UF_ADMIN_PASS}" -auth admin:changeme 2>/dev/null || true

# ── 5. Point to central indexer ──────────────────────────────
echo "[5/6] Connecting to indexer at ${INDEXER_IP}:${INDEXER_PORT}..."
sudo ${UF_HOME}/bin/splunk add forward-server \
  "${INDEXER_IP}:${INDEXER_PORT}" \
  -auth admin:${UF_ADMIN_PASS}

# ── 6. Write inputs.conf ─────────────────────────────────────
echo "[6/6] Writing inputs.conf..."
sudo tee ${UF_HOME}/etc/system/local/inputs.conf > /dev/null <<EOF
# Auth / SSH logs
[monitor:///var/log/auth.log]
disabled = false
index = auth_logs
sourcetype = linux_secure
host = ${THIS_HOST}
crcSalt = <SOURCE>

# Syslog
[monitor:///var/log/syslog]
disabled = false
index = os_logs
sourcetype = syslog
host = ${THIS_HOST}

# Apache HTTP access
[monitor:///var/log/apache2/access.log]
disabled = false
index = web_logs
sourcetype = access_combined
host = ${THIS_HOST}

# Apache HTTP error
[monitor:///var/log/apache2/error.log]
disabled = false
index = web_logs
sourcetype = apache_error
host = ${THIS_HOST}

# Nginx
[monitor:///var/log/nginx/access.log]
disabled = false
index = web_logs
sourcetype = nginx_access
host = ${THIS_HOST}

# Custom SSH autologin JSON
[monitor:///home/${LOG_USER}/ssh_autologin.log]
disabled = false
index = ssh_logs
sourcetype = _json
host = ${THIS_HOST}
EOF

# Write outputs.conf
sudo tee ${UF_HOME}/etc/system/local/outputs.conf > /dev/null <<EOF
[tcpout]
defaultGroup = central-indexer
sendCookedData = true

[tcpout:central-indexer]
server = ${INDEXER_IP}:${INDEXER_PORT}
compressed = true
EOF

# Enable boot start & restart
sudo ${UF_HOME}/bin/splunk enable boot-start
sudo ${UF_HOME}/bin/splunk restart

# ── Done ─────────────────────────────────────────────────────
echo ""
echo "=============================================="
echo " Universal Forwarder Setup Complete!"
echo "=============================================="
echo " Host     : ${THIS_HOST}"
echo " Indexer  : ${INDEXER_IP}:${INDEXER_PORT}"
echo " UF Admin : admin / ${UF_ADMIN_PASS}"
echo "=============================================="
echo " Verify on Splunk server:"
echo "   index=main | stats count by host"
echo "=============================================="

rm -f "/tmp/${UF_DEB}"

#!/bin/bash
# ─────────────────────────────────────────────────────────────────
# install_uf_rocky.sh
# Installs Splunk Universal Forwarder on Rocky Linux / RHEL
# Usage: sudo bash install_uf_rocky.sh
# ─────────────────────────────────────────────────────────────────

set -e

SPLUNK_VERSION="9.2.1"
SPLUNK_BUILD="78803f08aabb"
UF_RPM="splunkforwarder-${SPLUNK_VERSION}-${SPLUNK_BUILD}-linux-x86_64.rpm"
UF_URL="https://download.splunk.com/products/universalforwarder/releases/${SPLUNK_VERSION}/linux/${UF_RPM}"
UF_HOME="/opt/splunkforwarder"
UF_ADMIN_PASS="ForwarderPass123!"   # Change before running!

# ── EDIT THESE ───────────────────────────────────────────────
INDEXER_IP="192.168.1.100"          # Your central Splunk server IP
INDEXER_PORT="9997"
THIS_HOST="$(hostname)"
LOG_USER="user"
# ─────────────────────────────────────────────────────────────

echo "=============================================="
echo " Splunk Universal Forwarder — Rocky Linux"
echo "=============================================="

# ── 1. Download UF ───────────────────────────────────────────
echo "[1/7] Downloading Universal Forwarder v${SPLUNK_VERSION}..."
wget -q --show-progress -O "/tmp/${UF_RPM}" "${UF_URL}"

# ── 2. Install ───────────────────────────────────────────────
echo "[2/7] Installing Universal Forwarder (RPM)..."
sudo rpm -i "/tmp/${UF_RPM}"

# ── 3. Start & accept license ────────────────────────────────
echo "[3/7] Starting forwarder..."
sudo ${UF_HOME}/bin/splunk start \
  --accept-license --answer-yes --no-prompt

sudo ${UF_HOME}/bin/splunk edit user admin \
  -password "${UF_ADMIN_PASS}" -auth admin:changeme 2>/dev/null || true

# ── 4. Point to central indexer ──────────────────────────────
echo "[4/7] Connecting to indexer at ${INDEXER_IP}:${INDEXER_PORT}..."
sudo ${UF_HOME}/bin/splunk add forward-server \
  "${INDEXER_IP}:${INDEXER_PORT}" \
  -auth admin:${UF_ADMIN_PASS}

# ── 5. Write inputs.conf ─────────────────────────────────────
echo "[5/7] Writing inputs.conf (Rocky Linux paths)..."
sudo tee ${UF_HOME}/etc/system/local/inputs.conf > /dev/null <<EOF
# Auth / SSH logs — Rocky Linux uses /var/log/secure
[monitor:///var/log/secure]
disabled = false
index = auth_logs
sourcetype = linux_secure
host = ${THIS_HOST}
crcSalt = <SOURCE>

# System logs — Rocky uses /var/log/messages
[monitor:///var/log/messages]
disabled = false
index = os_logs
sourcetype = syslog
host = ${THIS_HOST}

# Apache HTTP logs — Rocky uses /var/log/httpd/
[monitor:///var/log/httpd/access_log]
disabled = false
index = web_logs
sourcetype = access_combined
host = ${THIS_HOST}

[monitor:///var/log/httpd/error_log]
disabled = false
index = web_logs
sourcetype = apache_error
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

# ── 6. Configure firewalld ───────────────────────────────────
echo "[6/7] Configuring firewalld for outbound port 9997..."
if command -v firewall-cmd &>/dev/null; then
  sudo firewall-cmd --permanent --add-rich-rule="
    rule family='ipv4'
    destination address='${INDEXER_IP}/32'
    port protocol='tcp' port='${INDEXER_PORT}'
    accept"
  sudo firewall-cmd --reload
  echo "firewalld rule added for ${INDEXER_IP}:${INDEXER_PORT}"
else
  echo "firewalld not found — skipping firewall config."
fi

# ── 7. Handle SELinux ────────────────────────────────────────
echo "[7/7] Checking SELinux..."
if command -v sestatus &>/dev/null && sestatus | grep -q "enforcing"; then
  echo "SELinux is enforcing — adding port context for 9997..."
  sudo semanage port -a -t syslogd_port_t -p tcp 9997 2>/dev/null || \
  sudo semanage port -m -t syslogd_port_t -p tcp 9997
fi

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
echo "=============================================="
echo " Test connectivity:"
echo "   nc -zv ${INDEXER_IP} ${INDEXER_PORT}"
echo " Verify on Splunk server:"
echo "   index=main | stats count by host"
echo "=============================================="

rm -f "/tmp/${UF_RPM}"

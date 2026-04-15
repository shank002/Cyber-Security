# Quick Setup — End-to-End Guide

Get from zero to a live honeypot feeding Splunk in under 30 minutes.

---

## Prerequisites Checklist

- [ ] Ubuntu 22.04 VM with a public IP (isolated VLAN / no prod traffic)
- [ ] Ports 22 and 23 forwarded to the VM from your router/firewall
- [ ] Splunk Enterprise running and accessible
- [ ] Your Splunk server IP noted: `SPLUNK_IP = ___________`

---

## Phase 1 — Cowrie (on the honeypot VM)

```bash
# 1. Dependencies
sudo apt update && sudo apt install -y git python3-venv libssl-dev libffi-dev iptables-persistent

# 2. Create non-root user
sudo adduser --disabled-password --gecos "" cowrie

# 3. Install Cowrie
sudo su - cowrie
git clone https://github.com/cowrie/cowrie && cd cowrie
python3 -m venv cowrie-env && source cowrie-env/bin/activate
pip install -r requirements.txt

# 4. Configure
cp etc/cowrie.cfg.dist etc/cowrie.cfg
# Edit etc/cowrie.cfg:
#   hostname = prod-webserver-01
#   listen_endpoints = tcp:2222:interface=0.0.0.0
#   telnet_enabled = true
#   [output_jsonlog] enabled = true

# 5. Start
bin/cowrie start && bin/cowrie status
exit  # back to root/sudo user

# 6. Port redirect (run as root)
sudo iptables -t nat -A PREROUTING -p tcp --dport 22 -j REDIRECT --to-port 2222
sudo iptables -t nat -A PREROUTING -p tcp --dport 23 -j REDIRECT --to-port 2223
sudo netfilter-persistent save

# 7. Firewall (replace SPLUNK_IP)
sudo ufw default deny incoming
sudo ufw default deny outgoing
sudo ufw allow in 2244/tcp        # your real SSH management port
sudo ufw allow in 2222/tcp        # Cowrie SSH
sudo ufw allow in 2223/tcp        # Cowrie Telnet
sudo ufw allow out to SPLUNK_IP port 9997
sudo ufw enable
```

**Verify:** `tail -f /home/cowrie/cowrie/var/log/cowrie/cowrie.json` — JSON events should appear when you SSH to the honeypot IP.

---

## Phase 2 — Splunk Receiving (on Splunk server)

1. **Create index:** Settings → Indexes → New Index → Name: `cowrie` → Save
2. **Enable receiving:** Settings → Forwarding and receiving → Configure receiving → New → Port `9997` → Save
3. **Open firewall on Splunk server:**
   ```bash
   sudo ufw allow from HONEYPOT_IP to any port 9997
   ```

---

## Phase 3 — Universal Forwarder (on honeypot VM)

```bash
# Download (check splunk.com for latest version)
wget -O splunkforwarder.deb "https://download.splunk.com/products/universalforwarder/releases/9.2.0/linux/splunkforwarder-9.2.0-linux-amd64.deb"
sudo dpkg -i splunkforwarder.deb
sudo /opt/splunkforwarder/bin/splunk start --accept-license --answer-yes --no-prompt --seed-passwd AdminPass123
sudo /opt/splunkforwarder/bin/splunk enable boot-start -systemd-managed 1

# Point to Splunk (replace SPLUNK_IP)
sudo tee /opt/splunkforwarder/etc/system/local/outputs.conf << 'EOF'
[tcpout]
defaultGroup = splunk_indexer
[tcpout:splunk_indexer]
server = SPLUNK_IP:9997
EOF

# Tell UF what to monitor
sudo tee /opt/splunkforwarder/etc/system/local/inputs.conf << 'EOF'
[monitor:///home/cowrie/cowrie/var/log/cowrie/cowrie.json]
index = cowrie
sourcetype = cowrie_json
disabled = false
EOF

sudo /opt/splunkforwarder/bin/splunk restart
```

---

## Phase 4 — Splunk Parsing (on Splunk server)

```bash
# On Splunk server
sudo tee -a $SPLUNK_HOME/etc/system/local/props.conf << 'EOF'
[cowrie_json]
KV_MODE = json
SHOULD_LINEMERGE = false
TIME_PREFIX = "timestamp":"
TIME_FORMAT = %Y-%m-%dT%H:%M:%S.%f
MAX_TIMESTAMP_LOOKAHEAD = 32
EOF

sudo $SPLUNK_HOME/bin/splunk restart
```

**Verify:** In Splunk Search: `index=cowrie | head 5` — you should see events with individual parsed fields.

---

## Phase 5 — Dashboard

1. Splunk Web → Search & Reporting → Dashboards → Create New Dashboard
2. Name: `Honeypot Attack Monitor` → Classic Dashboard → Create
3. Edit → Source → paste the XML from [splunk/02-dashboard.md](splunk/02-dashboard.md)
4. Save → Done

---

## Phase 6 — Alerts

Create these 4 alerts via Search & Reporting → Save As → Alert:

| Alert name | SPL query | Schedule | Trigger |
|---|---|---|---|
| Honeypot - Brute Force Spike | See [splunk/03-alerts.md](splunk/03-alerts.md) | Every 5 min | Results > 0 |
| Honeypot - Successful Login | See [splunk/03-alerts.md](splunk/03-alerts.md) | Every 1 min | Results > 0 |
| Honeypot - New Country Source | See [splunk/03-alerts.md](splunk/03-alerts.md) | Every 6 hours | Results > 0 |
| Honeypot - Command Burst | See [splunk/03-alerts.md](splunk/03-alerts.md) | Every 5 min | Results > 0 |

---

## Verification Checklist

- [ ] `tail -f /home/cowrie/cowrie/var/log/cowrie/cowrie.json` shows events
- [ ] `index=cowrie | head 5` in Splunk returns events with parsed fields
- [ ] Dashboard loads with data in all 6 panels
- [ ] All 4 alerts created and showing in Settings → Searches, Reports, and Alerts
- [ ] Test alert: run 60 SSH attempts from another machine → Brute Force Spike alert fires

---

## Full Documentation Index

| Topic | File |
|---|---|
| Project overview | [docs/01-overview.md](docs/01-overview.md) |
| Architecture | [docs/02-architecture.md](docs/02-architecture.md) |
| Tech stack | [docs/03-tech-stack.md](docs/03-tech-stack.md) |
| Key features | [docs/04-key-features.md](docs/04-key-features.md) |
| Results | [docs/05-results.md](docs/05-results.md) |
| Key learnings | [docs/06-key-learnings.md](docs/06-key-learnings.md) |
| Cowrie install | [cowrie/01-install.md](cowrie/01-install.md) |
| Cowrie config | [cowrie/02-config.md](cowrie/02-config.md) |
| UF setup | [pipeline/01-splunk-uf-setup.md](pipeline/01-splunk-uf-setup.md) |
| Index & sourcetype | [splunk/01-index-sourcetype.md](splunk/01-index-sourcetype.md) |
| Dashboard | [splunk/02-dashboard.md](splunk/02-dashboard.md) |
| Alerts | [splunk/03-alerts.md](splunk/03-alerts.md) |
| SPL reference | [splunk/04-spl-reference.md](splunk/04-spl-reference.md) |

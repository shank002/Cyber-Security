# Pipeline · Splunk Universal Forwarder Setup

## Overview

The Splunk Universal Forwarder (UF) runs on the honeypot VM alongside Cowrie. It tails the `cowrie.json` log file and ships each new line to the Splunk indexer over TCP port 9997.

```
cowrie.json  →  [Splunk UF]  →  TCP/9997  →  [Splunk Indexer]  →  index=cowrie
```

---

## Step 1 — Prepare Splunk to Receive Data

Do this on your **Splunk server** before installing the UF.

### 1a — Create the `cowrie` Index

In Splunk Web:

1. Go to **Settings → Indexes**
2. Click **New Index**
3. Set:
   - Index Name: `cowrie`
   - Max Size: `5 GB` (adjust to taste)
   - Retention: `90 days`
4. Click **Save**

> ⚠️ If the index doesn't exist when the UF first connects, events will be dropped or sent to the default index.

### 1b — Enable the Receiving Port

In Splunk Web:
1. Go to **Settings → Forwarding and receiving**
2. Click **Configure receiving**
3. Click **New Receiving Port**
4. Enter port `9997`
5. Click **Save**

Or via CLI on the Splunk server:

```bash
$SPLUNK_HOME/bin/splunk enable listen 9997 -auth admin:YOUR_PASSWORD
$SPLUNK_HOME/bin/splunk restart
```

### 1c — Open Port 9997 on Splunk Server Firewall

```bash
# On the Splunk server
sudo ufw allow from HONEYPOT_IP to any port 9997
```

---

## Step 2 — Install the Universal Forwarder on the Honeypot VM

Run these commands on the **honeypot VM** as root.

### 2a — Download

```bash
wget -O splunkforwarder.deb \
  "https://download.splunk.com/products/universalforwarder/releases/9.2.0/linux/splunkforwarder-9.2.0-linux-amd64.deb"
```

> Check https://www.splunk.com/en_us/download/universal-forwarder.html for the latest version.

### 2b — Install

```bash
sudo dpkg -i splunkforwarder.deb
```

### 2c — First Start and Accept License

```bash
sudo /opt/splunkforwarder/bin/splunk start --accept-license --answer-yes --no-prompt \
  --seed-passwd YourAdminPassword123
```

### 2d — Enable Auto-start on Boot

```bash
sudo /opt/splunkforwarder/bin/splunk enable boot-start -systemd-managed 1
```

---

## Step 3 — Configure the Forwarder

### 3a — Point to Splunk Indexer

Create or edit `/opt/splunkforwarder/etc/system/local/outputs.conf`:

```ini
[tcpout]
defaultGroup = splunk_indexer

[tcpout:splunk_indexer]
server = SPLUNK_IP:9997

# Optional: compress data in transit
compressed = true
```

Replace `SPLUNK_IP` with your Splunk server's IP address.

---

### 3b — Configure What to Monitor

Create `/opt/splunkforwarder/etc/system/local/inputs.conf`:

```ini
[monitor:///home/cowrie/cowrie/var/log/cowrie/cowrie.json]
index = cowrie
sourcetype = cowrie_json
disabled = false

# Read from the beginning of the file on first run
# (set to false after initial ingestion to avoid re-sending)
# crcSalt = <SOURCE>
```

> The path must exactly match where Cowrie writes its JSON log.

---

### 3c — Restart the Forwarder

```bash
sudo /opt/splunkforwarder/bin/splunk restart
```

---

## Step 4 — Verify Data is Flowing

### On the honeypot VM — check UF logs

```bash
sudo tail -f /opt/splunkforwarder/var/log/splunk/splunkd.log | grep -i "cowrie\|error\|connect"
```

Look for:
```
Connected to idx=SPLUNK_IP:9997
```

### Trigger a test event

From another machine, SSH into the honeypot:

```bash
ssh root@HONEYPOT_IP
```

### On Splunk — verify events arrived

In Splunk Web → Search & Reporting:

```
index=cowrie | head 5
```

You should see events with parsed fields: `src_ip`, `username`, `password`, `eventid`, `timestamp`.

If no events appear within 30 seconds, see troubleshooting below.

---

## Step 5 — Allow UF Through the Honeypot Firewall

The honeypot firewall blocks all outbound by default. Add an exception for the Splunk connection:

```bash
sudo ufw allow out to SPLUNK_IP port 9997
```

Verify the rule:

```bash
sudo ufw status verbose
```

---

## Troubleshooting

| Symptom | Check |
|---|---|
| No events in Splunk | `index=cowrie` returns nothing — confirm UF is running: `sudo systemctl status SplunkForwarder` |
| UF can't connect | Check UFW outbound rule; check Splunk receiving port is enabled |
| Events in wrong index | Confirm `index = cowrie` in inputs.conf; confirm cowrie index exists in Splunk |
| Wrong sourcetype | Check `sourcetype = cowrie_json` in inputs.conf matches props.conf stanza |
| Duplicate events | UF resumed from wrong offset — check `fishbucket`: `/opt/splunkforwarder/bin/splunk cmd btprobe -d var/lib/splunk/fishbucket/splunk_private_db --file /home/cowrie/cowrie/var/log/cowrie/cowrie.json` |

---

## UF Management Commands

```bash
# Start
sudo /opt/splunkforwarder/bin/splunk start

# Stop
sudo /opt/splunkforwarder/bin/splunk stop

# Restart
sudo /opt/splunkforwarder/bin/splunk restart

# Status
sudo /opt/splunkforwarder/bin/splunk status

# List monitored files
sudo /opt/splunkforwarder/bin/splunk list monitor
```

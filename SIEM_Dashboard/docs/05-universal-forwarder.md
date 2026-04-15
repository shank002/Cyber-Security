# 05 — Splunk Universal Forwarder Setup

The Universal Forwarder (UF) is a lightweight agent installed on each client machine. It monitors log files and ships them to the central Splunk indexer over TCP port 9997.

> ⚠️ **The UF must be installed on EVERY client machine** (Ubuntu, Debian, Rocky Linux).

---

## Download the Universal Forwarder

Download from: [https://www.splunk.com/en_us/download/universal-forwarder.html](https://www.splunk.com/en_us/download/universal-forwarder.html)

---

## Installation — Ubuntu / Debian

```bash
# 1. Download the .deb package
wget -O splunkforwarder-9.x.x-linux-amd64.deb \
  'https://download.splunk.com/products/universalforwarder/releases/9.x.x/linux/splunkforwarder-9.x.x-linux-amd64.deb'

# 2. Install
sudo dpkg -i splunkforwarder-9.x.x-linux-amd64.deb

# 3. Start and accept license
sudo /opt/splunkforwarder/bin/splunk start \
  --accept-license --answer-yes --no-prompt

# 4. Enable boot-start
sudo /opt/splunkforwarder/bin/splunk enable boot-start

# 5. Set admin credentials (first time only)
sudo /opt/splunkforwarder/bin/splunk edit user admin \
  -password YourPassword -auth admin:changeme
```

---

## Installation — Rocky Linux (RHEL-based)

```bash
# 1. Download the .rpm package
wget -O splunkforwarder-9.x.x-linux-x86_64.rpm \
  'https://download.splunk.com/products/universalforwarder/releases/9.x.x/linux/splunkforwarder-9.x.x-linux-x86_64.rpm'

# 2. Install
sudo rpm -i splunkforwarder-9.x.x-linux-x86_64.rpm

# 3. Start and accept license
sudo /opt/splunkforwarder/bin/splunk start \
  --accept-license --answer-yes --no-prompt

# 4. Enable boot-start
sudo /opt/splunkforwarder/bin/splunk enable boot-start

# 5. Set admin credentials
sudo /opt/splunkforwarder/bin/splunk edit user admin \
  -password YourPassword -auth admin:changeme
```

---

## Step 1 — Point Forwarder to the Central Indexer

Run this on **each client machine** after installation:

```bash
# Replace CENTRAL_SERVER_IP with your Splunk server's IP
sudo /opt/splunkforwarder/bin/splunk add forward-server \
  CENTRAL_SERVER_IP:9997 -auth admin:YourPassword

# Verify the connection
sudo /opt/splunkforwarder/bin/splunk list forward-server \
  -auth admin:YourPassword
```

---

## Step 2 — Configure inputs.conf

This tells the forwarder which log files to monitor.

Create/edit: `/opt/splunkforwarder/etc/system/local/inputs.conf`

### Ubuntu / Debian — inputs.conf

```ini
[monitor:///var/log/auth.log]
disabled = false
index = main
sourcetype = linux_secure
host = ubuntu-client-01

[monitor:///var/log/syslog]
disabled = false
index = main
sourcetype = syslog
host = ubuntu-client-01

[monitor:///var/log/apache2/access.log]
disabled = false
index = main
sourcetype = access_combined
host = ubuntu-client-01

[monitor:///var/log/apache2/error.log]
disabled = false
index = main
sourcetype = apache_error
host = ubuntu-client-01

[monitor:///home/user/ssh_autologin.log]
disabled = false
index = main
sourcetype = _json
host = ubuntu-client-01
```

### Rocky Linux — inputs.conf

```ini
[monitor:///var/log/secure]
disabled = false
index = main
sourcetype = linux_secure
host = rocky-client-01

[monitor:///var/log/messages]
disabled = false
index = main
sourcetype = syslog
host = rocky-client-01

[monitor:///var/log/httpd/access_log]
disabled = false
index = main
sourcetype = access_combined
host = rocky-client-01

[monitor:///var/log/httpd/error_log]
disabled = false
index = main
sourcetype = apache_error
host = rocky-client-01
```

---

## Step 3 — Configure outputs.conf

Create/edit: `/opt/splunkforwarder/etc/system/local/outputs.conf`

```ini
[tcpout]
defaultGroup = splunk-indexer

[tcpout:splunk-indexer]
server = CENTRAL_SERVER_IP:9997
compressed = true
```

---

## Step 4 — Restart the Forwarder

```bash
sudo /opt/splunkforwarder/bin/splunk restart
```

---

## Step 5 — Verify Logs Are Flowing

On the **central Splunk server**, run this search in the Web UI:

```spl
index=main | stats count by host
```

You should see your client hostnames with increasing event counts.

---

## Universal Forwarder — Quick Command Reference

```bash
# Start / Stop / Restart
sudo /opt/splunkforwarder/bin/splunk start
sudo /opt/splunkforwarder/bin/splunk stop
sudo /opt/splunkforwarder/bin/splunk restart

# Check status
sudo /opt/splunkforwarder/bin/splunk status

# Add a new file to monitor
sudo /opt/splunkforwarder/bin/splunk add monitor /path/to/logfile \
  -sourcetype my_sourcetype -auth admin:password

# List monitored inputs
sudo /opt/splunkforwarder/bin/splunk list monitor -auth admin:password

# Remove a monitored file
sudo /opt/splunkforwarder/bin/splunk remove monitor /path/to/logfile \
  -auth admin:password

# Check forwarder version
sudo /opt/splunkforwarder/bin/splunk version
```

---

## Forwarder Directory Reference

| Path | Purpose |
|---|---|
| `/opt/splunkforwarder/bin/` | UF executables |
| `/opt/splunkforwarder/etc/system/local/` | Local config files |
| `/opt/splunkforwarder/var/log/splunk/` | UF internal logs |

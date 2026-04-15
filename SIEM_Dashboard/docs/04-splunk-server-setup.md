# 04 — Splunk Server Installation (Central Server)

## Prerequisites

- Ubuntu 22.04 LTS or Debian 12 (recommended for central server)
- Minimum 4GB RAM, 2 CPUs, 20GB disk
- Root or sudo access
- Open ports: `8000` (Web UI), `9997` (Forwarder receiver), `8089` (Management)

---

## Step 1 — Download Splunk Enterprise

Go to [https://www.splunk.com/en_us/download/splunk-enterprise.html](https://www.splunk.com/en_us/download/splunk-enterprise.html) and download the `.deb` or `.tgz` package.

```bash
# Download Splunk (replace URL with latest version from Splunk website)
wget -O splunk-9.x.x-linux-amd64.deb \
  'https://download.splunk.com/products/splunk/releases/9.x.x/linux/splunk-9.x.x-linux-amd64.deb'
```

---

## Step 2 — Install Splunk

### On Ubuntu / Debian

```bash
# Install the .deb package
sudo dpkg -i splunk-9.x.x-linux-amd64.deb

# Splunk installs to /opt/splunk by default
ls /opt/splunk/
```

### On Rocky Linux (RPM)

```bash
# Download the .rpm package instead
wget -O splunk-9.x.x-linux-x86_64.rpm \
  'https://download.splunk.com/products/splunk/releases/9.x.x/linux/splunk-9.x.x-linux-x86_64.rpm'

sudo rpm -i splunk-9.x.x-linux-x86_64.rpm
```

---

## Step 3 — Start Splunk & Accept License

```bash
# Start Splunk for the first time
sudo /opt/splunk/bin/splunk start --accept-license --answer-yes --no-prompt

# Set admin username and password when prompted
# Or pass them directly:
sudo /opt/splunk/bin/splunk start --accept-license \
  --answer-yes --no-prompt \
  --seed-passwd YourSecurePassword123!
```

---

## Step 4 — Enable Splunk at Boot

```bash
# Enable Splunk to start on system boot
sudo /opt/splunk/bin/splunk enable boot-start -user splunk

# If using systemd (preferred):
sudo systemctl enable Splunkd
sudo systemctl start Splunkd
sudo systemctl status Splunkd
```

---

## Step 5 — Configure the Receiving Port (9997)

This tells Splunk to listen for incoming data from Universal Forwarders.

```bash
# Enable receiving on port 9997
sudo /opt/splunk/bin/splunk enable listen 9997 -auth admin:YourPassword

# Verify it's enabled
sudo /opt/splunk/bin/splunk list forward-server -auth admin:YourPassword
```

Alternatively, via the Web UI:
1. Go to `http://<server-ip>:8000`
2. Navigate to **Settings → Forwarding and Receiving → Configure Receiving**
3. Click **New Receiving Port** → Enter `9997` → Save

---

## Step 6 — Verify Installation

```bash
# Check Splunk status
sudo /opt/splunk/bin/splunk status

# Check Splunk version
sudo /opt/splunk/bin/splunk version

# Check listening ports
sudo ss -tlnp | grep splunk
# Should show: 8000, 8089, 9997
```

Access the Web UI at: **http://\<your-server-ip\>:8000**

---

## Step 7 — Add PATH Shortcut (Optional)

```bash
# Add Splunk to your PATH for convenience
echo 'export PATH=$PATH:/opt/splunk/bin' >> ~/.bashrc
source ~/.bashrc

# Now you can run:
splunk status
splunk restart
```

---

## Useful Splunk Server Commands

```bash
# Start / Stop / Restart
sudo /opt/splunk/bin/splunk start
sudo /opt/splunk/bin/splunk stop
sudo /opt/splunk/bin/splunk restart

# Check logs
tail -f /opt/splunk/var/log/splunk/splunkd.log

# Check indexes
sudo /opt/splunk/bin/splunk list index -auth admin:password

# Search from CLI
sudo /opt/splunk/bin/splunk search 'index=main sourcetype=syslog' \
  -auth admin:password -maxout 10
```

---

## Directory Reference

| Path | Purpose |
|---|---|
| `/opt/splunk/bin/` | Splunk executables |
| `/opt/splunk/etc/system/local/` | Local configuration files |
| `/opt/splunk/var/log/splunk/` | Splunk internal logs |
| `/opt/splunk/var/lib/splunk/` | Indexed data storage |

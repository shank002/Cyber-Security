# Cowrie · Installation Guide

## Prerequisites

- Ubuntu 22.04 LTS VM (isolated network, public IP)
- Root or sudo access for initial setup
- Ports 22 and 23 forwarded to this VM from your router/firewall

---

## Step 1 — System Dependencies

```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y git python3-venv python3-dev libssl-dev \
  libffi-dev build-essential authbind
```

---

## Step 2 — Create Dedicated User

Cowrie must never run as root.

```bash
sudo adduser --disabled-password --gecos "" cowrie
```

---

## Step 3 — Clone and Install Cowrie

```bash
sudo su - cowrie

git clone https://github.com/cowrie/cowrie
cd cowrie

python3 -m venv cowrie-env
source cowrie-env/bin/activate

pip install --upgrade pip
pip install -r requirements.txt
```

---

## Step 4 — Port Redirection (iptables)

Run these as root (not as the cowrie user). This redirects the standard ports to Cowrie's high ports so it can run without root privileges.

```bash
# SSH: 22 → 2222
sudo iptables -t nat -A PREROUTING -p tcp --dport 22 -j REDIRECT --to-port 2222

# Telnet: 23 → 2223
sudo iptables -t nat -A PREROUTING -p tcp --dport 23 -j REDIRECT --to-port 2223
```

**Make rules persistent across reboots:**

```bash
sudo apt install -y iptables-persistent
sudo netfilter-persistent save
```

---

## Step 5 — Verify Installation

```bash
# As the cowrie user
cd ~/cowrie
source cowrie-env/bin/activate
bin/cowrie start
bin/cowrie status
```

Expected output:
```
Cowrie is running (PID: XXXXX).
```

Tail logs to confirm startup:

```bash
tail -f var/log/cowrie/cowrie.log
```

---

## Step 6 — systemd Service (Auto-restart on Boot)

Create the service file as root:

```bash
sudo nano /etc/systemd/system/cowrie.service
```

Paste:

```ini
[Unit]
Description=Cowrie SSH Honeypot
After=network.target

[Service]
Type=forking
User=cowrie
Group=cowrie
WorkingDirectory=/home/cowrie/cowrie
PIDFile=/home/cowrie/cowrie/var/run/cowrie.pid
ExecStart=/home/cowrie/cowrie/bin/cowrie start
ExecStop=/home/cowrie/cowrie/bin/cowrie stop
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
```

Enable and start:

```bash
sudo systemctl daemon-reload
sudo systemctl enable cowrie
sudo systemctl start cowrie
sudo systemctl status cowrie
```

---

## Step 7 — Verify JSON Log Output

Trigger a test connection from another machine:

```bash
# From another machine
ssh root@YOUR_HONEYPOT_IP
```

Then on the honeypot VM:

```bash
tail -f /home/cowrie/cowrie/var/log/cowrie/cowrie.json
```

You should see JSON events like:

```json
{"eventid": "cowrie.session.connect", "src_ip": "X.X.X.X", ...}
{"eventid": "cowrie.login.failed", "username": "root", "password": "123456", ...}
```

---

## Step 8 — Log Rotation

Prevent the JSON log from consuming all disk space:

```bash
sudo nano /etc/logrotate.d/cowrie
```

```
/home/cowrie/cowrie/var/log/cowrie/cowrie.json {
    daily
    rotate 30
    compress
    delaycompress
    missingok
    notifempty
    copytruncate
}
```

---

## Troubleshooting

| Problem | Check |
|---|---|
| Cowrie won't start | `bin/cowrie start` and read `var/log/cowrie/cowrie.log` |
| No events in log | Confirm iptables rules: `sudo iptables -t nat -L -n` |
| Port 22 still goes to real SSH | Check your real SSH is on port 2244, not 22 |
| Permission denied errors | Confirm you're running as the `cowrie` user |

# 🛡️ 04 — Defensive Setup (IDS Configuration)

## Overview

The defensive side of the lab runs on an **Ubuntu Server 22.04 VM**. Both Suricata and Snort were configured as network-based IDS engines, each capable of inspecting traffic and generating alerts based on custom detection rules.

---

## Part A — Suricata Setup

### 1. Installation

```bash
sudo apt update && sudo apt install suricata -y
```

Verify installation:
```bash
suricata --version
```

### 2. Identify Network Interface

```bash
ip a
```

Note the interface name — typically `eth0`, `enp0s3`, or `ens33` in VirtualBox.

### 3. Configure suricata.yaml

```bash
sudo nano /etc/suricata/suricata.yaml
```

Key changes made:

```yaml
# Set your defended network
vars:
  address-groups:
    HOME_NET: "[192.168.56.0/24]"

# Set your network interface
af-packet:
  - interface: enp0s3       # Replace with your actual interface

# Enable fast.log output
outputs:
  - fast:
      enabled: yes
      filename: fast.log
      append: yes

  - eve-log:
      enabled: yes
      filename: eve.json
```

### 4. Update Community Rules

```bash
sudo suricata-update
```

### 5. Add Custom Rules File

```bash
sudo nano /etc/suricata/rules/custom.rules
```

Add the following to `suricata.yaml` under `rule-files`:

```yaml
rule-files:
  - suricata.rules
  - custom.rules            # Add this line
```

### 6. Validate Configuration

```bash
sudo suricata -T -c /etc/suricata/suricata.yaml
```

Expected output:
```
Configuration provided was successfully loaded.
```

### 7. Start Suricata

```bash
sudo systemctl enable suricata
sudo systemctl start suricata
sudo systemctl status suricata
```

### 8. Monitor Alerts in Real Time

```bash
# Simple one-line alert view
sudo tail -f /var/log/suricata/fast.log

# Detailed JSON view
sudo tail -f /var/log/suricata/eve.json | python3 -m json.tool
```

---

## Part B — Snort Setup

### 1. Installation

```bash
sudo apt update && sudo apt install snort -y
```

During installation, enter your network interface when prompted.

### 2. Configure snort.conf

```bash
sudo nano /etc/snort/snort.conf
```

Key changes made:

```bash
# Set HOME_NET
ipvar HOME_NET 192.168.56.0/24

# Set RULE_PATH
var RULE_PATH /etc/snort/rules

# Add custom rules file at the bottom of the rule-files section
include $RULE_PATH/custom.rules
```

### 3. Add Custom Rules

```bash
sudo nano /etc/snort/rules/custom.rules
```

See [custom-snort.rules](../rules/custom-snort.rules) for the full ruleset used.

### 4. Validate Configuration

```bash
sudo snort -T -c /etc/snort/snort.conf
```

### 5. Run Snort

```bash
# Run with console alert output (good for testing)
sudo snort -A console -c /etc/snort/snort.conf -i enp0s3

# Run as daemon (background service)
sudo snort -D -c /etc/snort/snort.conf -i enp0s3
```

### 6. Monitor Alerts

```bash
sudo tail -f /var/log/snort/alert
```

---

## Part C — Wireshark Setup

### Installation

```bash
sudo apt install wireshark -y
```

When prompted, allow non-root users to capture packets — select **Yes**.

Add your user to the wireshark group:
```bash
sudo usermod -aG wireshark $USER
newgrp wireshark
```

### Usage

Launch Wireshark:
```bash
wireshark &
```

Key filters used during this project:

```
# Filter ICMP traffic only
icmp

# Filter TCP SYN packets (port scan signature)
tcp.flags.syn == 1 && tcp.flags.ack == 0

# Filter SSH traffic
tcp.port == 22

# Filter by attacker IP
ip.src == 192.168.56.20
```

---

## Custom IDS Rules

All custom rules are stored in the `rules/` directory:

- [custom-suricata.rules](../rules/custom-suricata.rules)
- [custom-snort.rules](../rules/custom-snort.rules)

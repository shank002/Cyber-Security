# 03 · Tech Stack

## Core Components

| Component | Tool | Version | Role |
|---|---|---|---|
| Honeypot | Cowrie | 2.5.x | SSH/Telnet emulation & session recording |
| OS | Ubuntu Server | 22.04 LTS | Honeypot VM operating system |
| Log forwarder | Splunk Universal Forwarder | 9.2.x | Tails JSON logs, ships to Splunk |
| SIEM | Splunk Enterprise | 9.x | Indexing, dashboards, alerting |
| Firewall | UFW + iptables | Built-in | Network isolation & port redirect |
| Python | Python 3.10+ | 3.10 | Cowrie runtime |
| Runtime | Python virtualenv | Built-in | Cowrie process isolation |

---

## Cowrie

**What it is:** A medium-interaction SSH and Telnet honeypot written in Python. It emulates a Debian/Ubuntu shell environment convincingly enough to keep attackers engaged while logging everything they do.

**Key capabilities:**
- Emulates OpenSSH server (presents real-looking banners)
- Fake filesystem with common Linux tools (`ls`, `cat`, `wget`, `curl`, etc.)
- Session recording — full TTY replay possible
- Accepts all credentials after a configurable number of failed attempts
- Outputs structured JSON logs (one event object per line)
- Supports Telnet in addition to SSH

**Why Cowrie over alternatives:**
- Actively maintained (GitHub: cowrie/cowrie)
- JSON log output — native Splunk compatibility
- Large community, well-documented event schema
- Configurable fake environment (hostname, users, filesystem)

---

## Splunk Universal Forwarder

**What it is:** A lightweight Splunk agent that runs on the honeypot VM and ships log data to the Splunk indexer. Uses ~50MB RAM, minimal CPU.

**How it's used here:**
- Monitors `/home/cowrie/cowrie/var/log/cowrie/cowrie.json` with inotify
- Tags events with `index=cowrie` and `sourcetype=cowrie_json`
- Connects outbound to Splunk on TCP/9997
- Auto-restarts on boot via systemd

**Why UF over Filebeat:**
- Native Splunk integration — no intermediate translation layer
- Reliable delivery with acknowledgement
- Simpler configuration for Splunk-first pipelines

---

## Splunk Enterprise

**What it is:** The SIEM backend that indexes, searches, visualises, and alerts on all honeypot data.

**How it's used here:**

| Feature | Usage |
|---|---|
| Index `cowrie` | Dedicated index for all honeypot events |
| `props.conf` | Parses JSON fields and timestamps from Cowrie logs |
| Search & Reporting | SPL queries for dashboard panels |
| Dashboard | 6-panel live attack monitoring dashboard |
| Saved Searches | Reusable queries powering dashboard panels |
| Alerts | 4 scheduled alert rules with email/webhook triggers |
| `iplocation` command | Built-in GeoIP resolution on `src_ip` field |
| Cluster Map | Geographic visualisation of attacker origins |

---

## Infrastructure

### Honeypot VM Specs (Minimum)

| Resource | Minimum | Recommended |
|---|---|---|
| CPU | 1 vCPU | 2 vCPU |
| RAM | 1 GB | 2 GB |
| Disk | 20 GB | 40 GB |
| Network | 1 public IP | 1 public IP |
| OS | Ubuntu 22.04 LTS | Ubuntu 22.04 LTS |

### Network Requirements

| Port | Direction | Purpose |
|---|---|---|
| 22 (→ 2222) | Inbound | SSH honeypot |
| 23 (→ 2223) | Inbound | Telnet honeypot |
| 2244 | Inbound | Real SSH management |
| 9997 | Outbound | Splunk UF → Splunk indexer |

# 02 · Architecture

## System Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        INTERNET                                  │
│   SSH scanners · Botnets · Script kiddies · Targeted attackers  │
└───────────────────────────┬─────────────────────────────────────┘
                            │  TCP :22 / :23 (port-forwarded)
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│              HONEYPOT VM  (Isolated VLAN / Public IP)            │
│                                                                  │
│   ┌──────────────────────────────────────────────┐              │
│   │              COWRIE  (user: cowrie)           │              │
│   │  • Listens :2222 (SSH)  · :2223 (Telnet)     │              │
│   │  • Emulates Ubuntu shell (fake filesystem)   │              │
│   │  • Accepts all credentials after N attempts  │              │
│   │  • Records: logins, commands, file xfers     │              │
│   │  • Output: /var/log/cowrie/cowrie.json        │              │
│   └────────────────────┬─────────────────────────┘              │
│                        │  JSON (one event per line)              │
│   ┌────────────────────▼─────────────────────────┐              │
│   │       SPLUNK UNIVERSAL FORWARDER              │              │
│   │  • Monitors cowrie.json (tail)                │              │
│   │  • Index: cowrie                             │              │
│   │  • Sourcetype: cowrie_json                   │              │
│   │  • Ships to Splunk :9997 (TCP)               │              │
│   └────────────────────┬─────────────────────────┘              │
│                        │  Outbound: SPLUNK_IP:9997 ONLY         │
│   UFW: deny all other outbound traffic                           │
└───────────────────────-┼────────────────────────────────────────┘
                         │  TCP :9997
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│                   SPLUNK ENTERPRISE                              │
│                                                                  │
│   ┌─────────────┐   ┌──────────────┐   ┌──────────────────┐    │
│   │  Index      │   │  Parsing     │   │  Dashboard       │    │
│   │  cowrie     │──▶│  props.conf  │──▶│  6 panels        │    │
│   │  (JSON)     │   │  KV_MODE=json│   │  GeoIP map       │    │
│   └─────────────┘   └──────────────┘   │  Timechart       │    │
│                                        │  Top IPs/Creds   │    │
│   ┌─────────────────────────────┐      └──────────────────┘    │
│   │  Alerts (4 rules)           │                               │
│   │  • Brute-force spike        │                               │
│   │  • Successful login         │                               │
│   │  • New country source       │                               │
│   │  • Command execution burst  │                               │
│   └─────────────────────────────┘                               │
└─────────────────────────────────────────────────────────────────┘
```

---

## Network Design

### Honeypot VM

| Interface | Purpose |
|---|---|
| eth0 (public) | Receives attacker connections on port 22 and 23 |
| Firewall inbound | Allow :22, :23, :2244 (real SSH management) |
| Firewall outbound | Allow only SPLUNK_IP:9997 — deny everything else |

### Port Mapping

| Public Port | Redirects To | Service |
|---|---|---|
| 22 | 2222 | Cowrie SSH honeypot |
| 23 | 2223 | Cowrie Telnet honeypot |
| 2244 | 2244 | Real SSH management access |

Port redirection is handled by iptables NAT rules so Cowrie runs as a non-root user.

---

## Data Flow

### Event Lifecycle

```
1. Attacker connects to :22
2. iptables NAT redirects → :2222 (Cowrie)
3. Cowrie presents fake SSH banner
4. Login attempt logged as cowrie.login.failed or cowrie.login.success
5. If "logged in" → fake shell presented
6. Commands typed → cowrie.command.input events
7. All events written as JSON to cowrie.json (one JSON object per line)
8. Splunk UF detects new lines (inotify)
9. UF ships event to Splunk indexer over TCP/9997
10. Splunk parses JSON fields (KV_MODE=json)
11. Event available in Search within ~5 seconds
12. Dashboard panels auto-refresh every 60s
13. Alert scheduler checks every 5 minutes
```

### Key Cowrie Event Types

| Event ID | Description |
|---|---|
| `cowrie.session.connect` | New TCP connection established |
| `cowrie.login.failed` | Login attempt with wrong credentials |
| `cowrie.login.success` | Login accepted (Cowrie allows after N attempts) |
| `cowrie.command.input` | Attacker typed a command |
| `cowrie.session.file_download` | Attacker downloaded a file (wget/curl) |
| `cowrie.session.file_upload` | Attacker uploaded a file (SCP/SFTP) |
| `cowrie.session.closed` | Connection terminated |

---

## Isolation Architecture

The honeypot is intentionally exposed but **contained**:

```
VM Network Policy
├── Inbound ALLOW  → :22, :23 (honeypot), :2244 (mgmt)
├── Outbound ALLOW → SPLUNK_IP:9997 only
└── Outbound DENY  → everything else

Cowrie Process Isolation
├── Runs as unprivileged user 'cowrie'
├── Python virtualenv (no system Python access)
├── Fake filesystem (attackers never touch real OS)
└── No real shell exposed to attackers
```

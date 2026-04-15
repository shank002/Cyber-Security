# 02 — Architecture & Workflow

## High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     NETWORK / LAN                           │
│                                                             │
│  ┌──────────────┐   ┌──────────────┐   ┌──────────────┐   │
│  │  Client 1    │   │  Client 2    │   │  Client 3    │   │
│  │  Ubuntu      │   │  Debian      │   │  Rocky Linux │   │
│  │              │   │              │   │              │   │
│  │  [UF Agent]  │   │  [UF Agent]  │   │  [UF Agent]  │   │
│  └──────┬───────┘   └──────┬───────┘   └──────┬───────┘   │
│         │                  │                  │            │
│         └──────────────────┼──────────────────┘            │
│                            │  TCP Port 9997                 │
│                            ▼                               │
│              ┌─────────────────────────┐                   │
│              │    CENTRAL SERVER       │                   │
│              │    (Ubuntu/Debian)      │                   │
│              │                         │                   │
│              │  ┌───────────────────┐  │                   │
│              │  │  Splunk Indexer   │  │                   │
│              │  │  Port: 9997       │  │                   │
│              │  │  (receives logs)  │  │                   │
│              │  └────────┬──────────┘  │                   │
│              │           │             │                   │
│              │  ┌────────▼──────────┐  │                   │
│              │  │  Splunk Web UI    │  │                   │
│              │  │  Port: 8000       │  │                   │
│              │  │  Dashboards       │  │                   │
│              │  │  Alerts           │  │                   │
│              │  └───────────────────┘  │                   │
│              └─────────────────────────┘                   │
└─────────────────────────────────────────────────────────────┘
```

---

## Data Flow

```
Linux Client (Log Source)
        │
        │  /var/log/auth.log
        │  /var/log/syslog
        │  /var/log/apache2/access.log
        │  /var/log/secure (Rocky)
        │
        ▼
Splunk Universal Forwarder
  - Monitors configured log paths
  - Tails log files in real time
  - Buffers & compresses data
  - Sends over TCP 9997 (TLS optional)
        │
        │  TCP Port 9997
        ▼
Splunk Indexer (Central Server)
  - Receives data from all forwarders
  - Parses & indexes events
  - Stores in Splunk indexes
        │
        ▼
Splunk Search Head
  - SPL queries run against indexes
  - Dashboards visualize results
  - Alerts fire on threshold conditions
        │
        ▼
Security Analyst / Dashboard Viewer
```

---

## Component Breakdown

### Central Server (Splunk Enterprise / Free)

| Component | Role |
|---|---|
| **Splunk Indexer** | Receives, parses, and stores logs from forwarders |
| **Splunk Search Head** | Runs SPL queries; hosts dashboards and alerts |
| **Splunk Web** | Browser-based UI at `http://<server-ip>:8000` |
| **Listening Port 9997** | Accepts incoming data from Universal Forwarders |

### Client Machines (Splunk Universal Forwarder)

| Component | Role |
|---|---|
| **Universal Forwarder** | Lightweight agent that ships logs to the indexer |
| **inputs.conf** | Defines which log files to monitor |
| **outputs.conf** | Points forwarder to the central indexer IP:9997 |

### Log Sources Monitored

| Log File | OS | Content |
|---|---|---|
| `/var/log/auth.log` | Ubuntu / Debian | SSH, sudo, PAM events |
| `/var/log/secure` | Rocky Linux | SSH, sudo, PAM events |
| `/var/log/syslog` | Ubuntu / Debian | General system events |
| `/var/log/messages` | Rocky Linux | General system events |
| `/var/log/apache2/access.log` | All | HTTP access logs |
| `/var/log/apache2/error.log` | All | HTTP error logs |
| `/var/log/nginx/access.log` | All | Nginx HTTP access logs |
| `ssh_autologin.log` | All | Custom SSH auto-login JSON logs |

---

## Port Reference

| Port | Protocol | Purpose |
|---|---|---|
| `9997` | TCP | Splunk Forwarder → Indexer (log data) |
| `8000` | TCP | Splunk Web UI (browser access) |
| `8089` | TCP | Splunk Management / REST API |
| `9887` | TCP | Splunk Cluster replication (if clustered) |

---

## Workflow Summary

1. Each Linux client runs a **Splunk Universal Forwarder** that tails configured log files.
2. The forwarder ships log events over **TCP port 9997** to the central Splunk server.
3. The central server **indexes** the incoming data and makes it searchable.
4. **Dashboards** query the index using SPL to visualize SSH, auth, and HTTP activity.
5. **Alerts** continuously evaluate SPL queries and notify when thresholds are breached (e.g., >10 failed SSH logins in 5 minutes).

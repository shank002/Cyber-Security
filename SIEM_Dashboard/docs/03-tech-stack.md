# 03 — Tech Stack

## Platform & Software

| Technology | Version | Role |
|---|---|---|
| **Splunk Enterprise / Free** | 9.x | SIEM platform — indexing, search, dashboards, alerts |
| **Splunk Universal Forwarder** | 9.x | Lightweight log shipping agent on each client |
| **Python 3** | 3.10+ | Custom SSH auto-login script with JSON logging |
| **Paramiko** | 3.x | Python SSH library used in autologin script |
| **Apache / Nginx** | Latest | Web servers generating HTTP access/error logs |
| **OpenSSH** | System default | SSH server generating auth/login logs |

---

## Operating Systems

| OS | Distro Family | Role in Project |
|---|---|---|
| **Ubuntu 22.04 LTS** | Debian-based | Central Splunk server + client node |
| **Debian 12 (Bookworm)** | Debian-based | Client log source node |
| **Rocky Linux 9** | RHEL-based | Client log source node |

---

## Key Configuration Files

| File | Location | Purpose |
|---|---|---|
| `inputs.conf` | `$SPLUNK_HOME/etc/system/local/` | Defines monitored log paths and sourcetypes |
| `outputs.conf` | `$SPLUNK_HOME/etc/system/local/` | Configures where to send logs (indexer IP:port) |
| `server.conf` | `$SPLUNK_HOME/etc/system/local/` | Performance and connection tuning |
| `deploymentclient.conf` | `$SPLUNK_HOME/etc/system/local/` | Connects UF to Deployment Server |
| `savedsearches.conf` | `$SPLUNK_HOME/etc/apps/<app>/local/` | Stores saved alerts and scheduled searches |

---

## SPL (Search Processing Language)

Splunk's query language used to search, filter, and visualize indexed log data. Key commands used in this project:

| SPL Command | Purpose |
|---|---|
| `search` | Filter events by keyword or field |
| `stats count by` | Aggregate counts grouped by a field |
| `timechart` | Plot event counts over time |
| `eval` | Create computed fields |
| `where` | Filter results by condition |
| `rex` | Extract fields using regex |
| `table` | Format output as a table |
| `sort` | Order results |
| `dedup` | Remove duplicate events |
| `alert` | Trigger alerts based on search results |

---

## Firewall Tools

| OS | Tool | Purpose |
|---|---|---|
| Ubuntu / Debian | `ufw` | Allow port 9997 inbound on Splunk server |
| Rocky Linux | `firewalld` | Allow port 9997 on RHEL-based clients/server |

---

## Network

| Component | Detail |
|---|---|
| Topology | Local Area Network (LAN) / VMs on same subnet |
| Forwarder → Indexer Port | TCP 9997 |
| Splunk Web Port | TCP 8000 |
| Protocol | TCP (optionally TLS-encrypted) |

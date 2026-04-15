# Honeypot SIEM Project

> SSH Honeypot with Cowrie · Splunk Universal Forwarder · Splunk SIEM Dashboard

---

## Folder Structure

```
honeypot-docs/
├── README.md                        ← You are here (project index)
├── docs/
│   ├── 01-overview.md               ← Project overview & objectives
│   ├── 02-architecture.md           ← System architecture & data flow
│   ├── 03-tech-stack.md             ← All tools and versions
│   ├── 04-key-features.md           ← Feature breakdown
│   ├── 05-results.md                ← Findings, metrics, outcomes
│   └── 06-key-learnings.md          ← Lessons learned
├── cowrie/
│   ├── 01-install.md                ← Cowrie installation guide
│   └── 02-config.md                 ← Cowrie configuration reference
├── pipeline/
│   └── 01-splunk-uf-setup.md        ← Universal Forwarder setup & inputs
├── splunk/
│   ├── 01-index-sourcetype.md       ← Index + sourcetype configuration
│   ├── 02-dashboard.md              ← Dashboard panels & SPL queries
│   ├── 03-alerts.md                 ← Alert rules & thresholds
│   └── 04-spl-reference.md          ← Full SPL query reference
└── quick-setup.md                   ← End-to-end quick setup (TL;DR)
```

---

## Quick Navigation

| What you want | Where to go |
|---|---|
| Understand the project | [docs/01-overview.md](docs/01-overview.md) |
| See the architecture | [docs/02-architecture.md](docs/02-architecture.md) |
| Install Cowrie | [cowrie/01-install.md](cowrie/01-install.md) |
| Configure Cowrie | [cowrie/02-config.md](cowrie/02-config.md) |
| Set up the log pipeline | [pipeline/01-splunk-uf-setup.md](pipeline/01-splunk-uf-setup.md) |
| Configure Splunk index | [splunk/01-index-sourcetype.md](splunk/01-index-sourcetype.md) |
| Build dashboards | [splunk/02-dashboard.md](splunk/02-dashboard.md) |
| Set up alerts | [splunk/03-alerts.md](splunk/03-alerts.md) |
| Just get it running fast | [quick-setup.md](quick-setup.md) |

---

## Project Summary

This project deploys an SSH honeypot using **Cowrie** on an isolated VM, ships all generated logs to a **Splunk** instance via the **Splunk Universal Forwarder**, and surfaces attacker behaviour through a purpose-built SIEM dashboard with automated alerts.

**What it captures:**
- SSH and Telnet brute-force attempts
- Attacker credentials (username/password combos)
- Shell commands run inside the fake environment
- File download/upload attempts
- Session durations and attacker fingerprints

**Stack:** Cowrie · Splunk Universal Forwarder · Splunk Enterprise · Ubuntu 22.04

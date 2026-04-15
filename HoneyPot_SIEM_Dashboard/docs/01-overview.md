# 01 · Project Overview & Objectives

## Overview

This project builds a production-style **SSH honeypot** that lures internet attackers into a fake Linux environment, records everything they do, and pipelines all that data into a **Splunk SIEM dashboard** for real-time analysis and alerting.

The core idea is deception: the honeypot presents itself as a legitimate SSH server. Attackers connect, attempt logins, run commands, and try to download tools — completely unaware that every action is logged in structured JSON and shipped to Splunk for analysis.

This project covers the full threat-intelligence pipeline:

```
Internet Attacker → Cowrie (SSH Trap) → JSON Logs → Splunk UF → Splunk SIEM → Alerts & Dashboard
```

---

## Motivation

Internet-facing SSH servers are attacked within minutes of being exposed. This project turns that hostile reality into a research asset — capturing real attacker behaviour, credential lists, and attack patterns from live internet traffic.

Use cases:
- **Security research** — understand real-world attack techniques and toolkits
- **Threat intelligence** — build and validate indicators of compromise (IOCs)
- **SIEM practice** — hands-on Splunk dashboard and alerting experience with real data
- **Academic/portfolio** — a complete end-to-end cybersecurity project

---

## Objectives

### Primary Objectives

| # | Objective | Status |
|---|-----------|--------|
| 1 | Deploy a convincing SSH/Telnet honeypot using Cowrie | ✅ |
| 2 | Capture attacker credentials, commands, and sessions | ✅ |
| 3 | Ship structured logs to Splunk via Universal Forwarder | ✅ |
| 4 | Build a live SIEM dashboard showing attack patterns | ✅ |
| 5 | Implement automated alerts for critical events | ✅ |

### Secondary Objectives

- Enrich attacker IPs with GeoIP data (country, city, ASN)
- Correlate attack volume over time to identify scanning campaigns
- Identify credential stuffing patterns from top username/password pairs
- Maintain complete network isolation to prevent the honeypot from being weaponised

---

## Scope

**In scope:**
- SSH (port 22 → 2222) and Telnet (port 23 → 2223) trapping
- Full session recording (commands, keystrokes, file transfers)
- Log forwarding via Splunk Universal Forwarder over TCP/9997
- Splunk dashboard with 6 core panels
- 4 automated Splunk alert rules

**Out of scope:**
- HTTP/SMB/FTP honeypot services (Dionaea, OpenCanary — recommended additions)
- Active threat response or IP blocking
- Malware sandbox analysis of captured files

---

## Threat Model

The honeypot is designed to be attacked. The threat model inverts the usual defensive posture:

| Concern | Mitigation |
|---|---|
| Honeypot used as pivot for attacks | Outbound traffic blocked at firewall (UFW deny outgoing) |
| Attacker escapes Cowrie to real shell | Cowrie runs as unprivileged user in virtualenv; no real shell exposed |
| Log tampering | Logs forwarded in near-real-time to remote Splunk; local logs are secondary |
| Resource exhaustion | VM isolated; Splunk index size capped |

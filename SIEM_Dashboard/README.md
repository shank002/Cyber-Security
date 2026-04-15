# 🛡️ SIEM Dashboard with Splunk — Cybersecurity Project

> Centralized log collection, monitoring, and alerting using Splunk on Linux infrastructure.

---

## 📁 Project Structure

```
siem-splunk-project/
│
├── README.md                          ← You are here
│
├── docs/
│   ├── 01-project-overview.md         ← Project overview & objectives
│   ├── 02-architecture.md             ← Architecture & workflow
│   ├── 03-tech-stack.md               ← Technologies used
│   ├── 04-splunk-server-setup.md      ← Splunk server installation
│   ├── 05-universal-forwarder.md      ← UF setup per distro
│   ├── 06-firewall-config.md          ← Firewall rules (RHEL/Debian/Ubuntu)
│   ├── 07-log-collection.md           ← Inputs.conf & log sources
│   ├── 08-splunk-searches.md          ← SPL queries for anomaly detection
│   ├── 09-dashboards.md               ← Dashboard setup guide
│   ├── 10-alerts.md                   ← SSH brute-force & DDoS alerts
│   ├── 11-use-cases.md                ← Real-world use cases
│   └── 12-results-and-learnings.md    ← Results, outputs & key learnings
│
├── configs/
│   ├── splunk-server/
│   │   ├── inputs.conf                ← Server-side inputs
│   │   └── outputs.conf               ← Forwarding config
│   ├── universal-forwarder/
│   │   ├── inputs.conf                ← UF log sources
│   │   ├── outputs.conf               ← Points UF → indexer
│   │   └── deploymentclient.conf      ← Deployment server config
│   └── alerts/
│       ├── ssh_bruteforce_alert.conf  ← SSH brute-force alert config
│       └── ddos_alert.conf            ← DDoS alert config
│
├── scripts/
│   ├── install_splunk_server.sh       ← Splunk server install script
│   ├── install_uf_debian.sh           ← UF install for Debian/Ubuntu
│   ├── install_uf_rocky.sh            ← UF install for Rocky Linux
│   └── ssh_autologin.py               ← SSH auto-login log generator
│
└── dashboards/
    ├── ssh_dashboard.xml              ← SSH monitoring dashboard
    └── auth_dashboard.xml             ← Auth logs dashboard
```

---

## 🚀 Quick Start

1. Set up the **central Splunk server** → see `docs/04-splunk-server-setup.md`
2. Install **Universal Forwarder** on each Linux client → see `docs/05-universal-forwarder.md`
3. Configure **firewall rules** → see `docs/06-firewall-config.md`
4. Set up **log inputs** → see `docs/07-log-collection.md`
5. Build **dashboards & alerts** → see `docs/09-dashboards.md` and `docs/10-alerts.md`

---

## 🧰 Tech Stack

| Component | Technology |
|---|---|
| SIEM Platform | Splunk Enterprise / Free |
| Log Forwarder | Splunk Universal Forwarder |
| Central Server OS | Ubuntu / Debian |
| Client OS(s) | Debian, Ubuntu, Rocky Linux |
| Log Sources | SSH, Auth, HTTP (Apache/Nginx) |
| Alerting | Splunk Alerts (Email / Webhook) |

---

## 👤 Author

Built as part of a Cybersecurity Portfolio — demonstrating real-world SIEM implementation skills.

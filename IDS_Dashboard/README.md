# 🛡️ Network Monitoring + IDS Setup — Blue Team Project

> A hands-on cybersecurity home lab simulating real-world SOC operations using Snort, Suricata, Wireshark, and Splunk for intrusion detection, traffic analysis, and security monitoring.

---

## 📁 Documentation Structure

```
network-ids-project/
│
├── README.md                        ← You are here (Project Overview)
│
├── docs/
│   ├── 01-objective.md              ← Goals and learning outcomes
│   ├── 02-architecture.md           ← Lab architecture and workflow
│   ├── 03-tech-stack.md             ← Tools and technologies used
│   ├── 04-defensive-setup.md        ← IDS setup (Suricata + Snort)
│   ├── 05-attacking-setup.md        ← Attack simulation (Kali Linux)
│   ├── 06-splunk-integration.md     ← Splunk Universal Forwarder + Dashboard
│   ├── 07-use-cases.md              ← Detection scenarios and use cases
│   ├── 08-results-outputs.md        ← Alerts, logs, and findings
│   └── 09-key-learnings.md          ← Key takeaways and skills gained
│
├── configs/
│   ├── suricata.yaml                ← Suricata config reference
│   ├── snort.conf                   ← Snort config reference
│   └── inputs.conf                  ← Splunk Universal Forwarder config
│
├── rules/
│   ├── custom-suricata.rules        ← Custom Suricata detection rules
│   └── custom-snort.rules           ← Custom Snort detection rules
│
└── queries/
    ├── splunk-searches.md           ← SPL search queries for alert analysis
    └── splunk-dashboards.md         ← SPL queries used in dashboard panels
```

---

## 🔍 Project Summary

| Field | Details |
|---|---|
| **Project Type** | Blue Team / Defensive Security |
| **Environment** | Virtualized Home Lab (VirtualBox/VMware) |
| **IDS Tools** | Suricata, Snort |
| **Packet Analysis** | Wireshark |
| **Attack Simulation** | Kali Linux |
| **SIEM** | Splunk (via Universal Forwarder) |
| **Attacks Simulated** | Port Scan, ICMP Flood, SSH Brute Force |
| **Skills Demonstrated** | IDS Configuration, Custom Rule Writing, Log Analysis, SIEM Integration, Threat Detection |

---

## 🚀 Quick Navigation

- [Objective](docs/01-objective.md)
- [Architecture & Workflow](docs/02-architecture.md)
- [Tech Stack](docs/03-tech-stack.md)
- [Defensive Setup (IDS)](docs/04-defensive-setup.md)
- [Attacking Setup (Kali)](docs/05-attacking-setup.md)
- [Splunk Integration](docs/06-splunk-integration.md)
- [Use Cases](docs/07-use-cases.md)
- [Results & Outputs](docs/08-results-outputs.md)
- [Key Learnings](docs/09-key-learnings.md)

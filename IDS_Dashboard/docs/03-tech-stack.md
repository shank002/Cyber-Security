# 🛠️ 03 — Tech Stack

## Virtualization

| Tool | Version | Purpose |
|---|---|---|
| **VirtualBox** | 7.x | Hosts all VMs in the lab environment |

---

## Defensive Tools (Ubuntu Server VM)

| Tool | Version | Purpose |
|---|---|---|
| **Suricata** | 7.x | Primary IDS — real-time network traffic inspection and alerting |
| **Snort** | 3.x | Secondary IDS — signature-based intrusion detection |
| **Wireshark** | 4.x | Packet capture and deep traffic inspection |
| **Splunk Universal Forwarder** | 9.x | Ships IDS logs to remote Splunk server |

---

## SIEM (Remote Server)

| Tool | Version | Purpose |
|---|---|---|
| **Splunk Enterprise** | 9.x | Log aggregation, indexing, SPL search, and dashboard visualization |

---

## Offensive Tools (Kali Linux VM)

| Tool | Pre-installed | Purpose |
|---|---|---|
| **Nmap** | Yes | Port scanning — SYN scan, aggressive scan |
| **Hydra** | Yes | SSH brute force credential attack |
| **ping** | Yes | ICMP flood with `-f` flag |
| **hping3** | Yes | Advanced packet crafting for custom flood attacks |

---

## Operating Systems

| OS | Role |
|---|---|
| **Ubuntu Server 22.04 LTS** | Defender machine — IDS, Wireshark, Splunk UF |
| **Kali Linux 2024.x** | Attacker machine — all offensive tooling |

---

## Protocols Involved

| Protocol | Usage in Project |
|---|---|
| **ICMP** | Ping flood simulation and detection |
| **TCP** | Port scan detection (SYN packets), SSH brute force |
| **UDP** | General traffic monitoring |
| **JSON** | eve.json log format consumed by Splunk |
| **Syslog / TCP 9997** | Log transport from Universal Forwarder to Splunk |

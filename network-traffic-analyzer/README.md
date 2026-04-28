# 🔬 PCAP Analyzer — Rocky Linux Edition

> A terminal-based network traffic analysis tool that reads `.pcap` / `.pcapng` files and renders a rich, color-coded dashboard directly in your terminal. No GUI. No browser. Just your shell.

![Python](https://img.shields.io/badge/Python-3.10%2B-blue?logo=python)
![Platform](https://img.shields.io/badge/Platform-Rocky%20Linux%20%7C%20RHEL%20%7C%20CentOS-green?logo=redhat)
![License](https://img.shields.io/badge/License-MIT-yellow)
![Dependencies](https://img.shields.io/badge/Dependencies-dpkt%20%7C%20rich-orange)

---

## 📋 Table of Contents

- [What This Project Solves](#-what-this-project-solves)
- [Features](#-features)
- [Dashboard Sections Explained](#-dashboard-sections-explained)
- [Project Architecture](#-project-architecture)
- [Folder Structure](#-folder-structure)
- [Installation](#-installation)
- [Usage](#-usage)
- [Capture + Analyze Workflow](#-capture--analyze-workflow)
- [Real-Life Use Cases](#-real-life-use-cases)
- [Performance](#-performance)
- [Contributing](#-contributing)
- [License](#-license)

---

## 🚀 What This Project Solves

Network administrators and security engineers often need to quickly answer questions like:

- *"Which IP is flooding our server?"*
- *"Is there a port scan happening on our network?"*
- *"What domains is this machine talking to?"*
- *"Why is our bandwidth spiking?"*

Traditional tools like Wireshark require a GUI and are heavy. `tcpdump` raw output requires manual `grep`/`awk` parsing. This tool bridges the gap — you capture traffic with `tcpdump`, hand the `.pcap` file to this analyzer, and get an instant, readable dashboard in under a second.

---

## ✨ Features

| Feature | Description |
|---|---|
| Protocol Breakdown | TCP, UDP, ICMP, ARP with % and bar charts |
| Top Source / Destination IPs | Ranked with OK / ELEVATED / ⚠ SUSPICIOUS labels |
| TCP Flag Analysis | Detects SYN scans, RST floods, abnormal flag combos |
| Top Destination Ports | Color-coded, service-named, risky port flagging |
| Top Talker Pairs | Most active `src → dst` conversations |
| DNS Query Extraction | Domains looked up during the capture |
| HTTP Host Extraction | Websites contacted over plain HTTP |
| ARP Sweep Detection | Flags ARP scans across subnets |
| Alert Engine | Automatic detection of 5 threat categories |
| Plain-text Report | Exportable with `-o report.txt` |
| pcap + pcapng support | Auto-detects file format from magic bytes |
| Configurable threshold | Tune sensitivity with `-t N` |
| No-color mode | `--no-color` for logging pipelines |

---

## 📊 Dashboard Sections Explained

See [docs/dashboard.md](docs/dashboard.md) for a full breakdown of every section.

| Section | What It Shows |
|---|---|
| **Capture Summary** | Total packets, bytes, duration, pps, unique IPs |
| **Alerts** | Auto-detected threats and anomalies |
| **Protocols** | Traffic mix with visual bars |
| **TCP Flags** | Flag combinations and scan indicators |
| **Top Source IPs** | Busiest senders with severity labels |
| **Top Dest IPs** | Most targeted receivers |
| **Top Dest Ports** | Services contacted, risky port flags |
| **Talker Pairs** | Dominant src→dst flows |
| **DNS Queries** | Domain names resolved |
| **HTTP Hosts** | Unencrypted web traffic |
| **ARP Targets** | ARP WHO-HAS sweep detection |

---

## 🏗 Project Architecture

See [docs/architecture.md](docs/architecture.md) for the full deep-dive.

```
┌─────────────────────────────────────────────────────┐
│                    CLI Layer                        │
│         argparse  ·  argument validation            │
└────────────────────────┬────────────────────────────┘
                         │
┌────────────────────────▼────────────────────────────┐
│                  PcapAnalysis                       │
│   load() → _parse_packet() → per-layer handlers    │
│                                                     │
│   dpkt.pcap.Reader  /  dpkt.pcapng.Reader           │
│   ├── Ethernet → ARP  → arp_targets Counter         │
│   ├── Ethernet → IP   → TCP  → flags, ports         │
│   │                          → HTTP host header     │
│   │                   → UDP  → DNS query extract    │
│   │                   → ICMP → proto counter        │
│   └── Ethernet → IPv6 → ipv6_src / ipv6_dst         │
└────────────────────────┬────────────────────────────┘
                         │
┌────────────────────────▼────────────────────────────┐
│                  Alert Engine                       │
│   generate_alerts() — 5 detection rules             │
└────────────────────────┬────────────────────────────┘
                         │
┌────────────────────────▼────────────────────────────┐
│                  Render Layer                       │
│   rich Panels, Tables, Columns, bars                │
│   Optional: _save_report() → plain .txt             │
└─────────────────────────────────────────────────────┘
```

**Data flow summary:**

1. CLI parses arguments and validates the file path
2. `PcapAnalysis.load()` opens the pcap and detects format from magic bytes
3. Each packet is decoded layer by layer using `dpkt`
4. Counters (`collections.Counter`) accumulate all metrics in a single pass
5. `generate_alerts()` runs 5 detection rules over the counters
6. `render()` builds all Rich tables and prints them to the terminal
7. Optionally, `_save_report()` writes a grep-friendly plain-text file

---

## 📁 Folder Structure

```
pcap-analyzer/
│
├── pcap_analyzer.py          # Main script — run this
│
├── docs/
│   ├── dashboard.md          # Full explanation of every dashboard section
│   ├── architecture.md       # Deep-dive into code architecture & design decisions
│   ├── alerts.md             # How the alert engine works
│   └── usage-examples.md     # Real-world usage scenarios with commands
│
├── requirements.txt          # Python dependencies
├── README.md                 # This file
└── LICENSE                   # MIT License
```

---

## ⚙ Installation

### Prerequisites

- Python 3.10 or higher
- `pip`
- Rocky Linux 8/9, RHEL 8/9, CentOS Stream, or any Linux distro

### Step 1 — Install Python & pip (if needed)

```bash
sudo dnf install python3 python3-pip -y
```

### Step 2 — Clone the repository

```bash
git clone https://github.com/yourusername/pcap-analyzer.git
cd pcap-analyzer
```

### Step 3 — Install dependencies

```bash
pip3 install -r requirements.txt --break-system-packages
```

Or manually:

```bash
pip3 install dpkt rich --break-system-packages
```

### Verify installation

```bash
python3 pcap_analyzer.py --help
```

---

## 🖥 Usage

```
python3 pcap_analyzer.py <file.pcap> [OPTIONS]

Arguments:
  file.pcap             Path to a .pcap or .pcapng capture file

Options:
  -t, --threshold N     Flag IPs sending ≥ N packets as suspicious  (default: 50)
  -o, --output FILE     Save a plain-text report to FILE
  -T, --top N           Show top N rows in each table               (default: 10)
  --no-color            Disable all color output (for logging/pipes)
  -h, --help            Show help message
```

### Basic examples

```bash
# Analyze a capture file with defaults
python3 pcap_analyzer.py capture.pcap

# Lower the suspicious threshold to catch lighter scanners
python3 pcap_analyzer.py capture.pcap -t 20

# Show top 20 IPs/ports instead of 10
python3 pcap_analyzer.py capture.pcap -T 20

# Save a report alongside the dashboard
python3 pcap_analyzer.py capture.pcap -o /var/log/nta/report.txt

# Combine options
python3 pcap_analyzer.py capture.pcap -t 15 -T 20 -o report.txt

# Pipe output to a log file (strip colors)
python3 pcap_analyzer.py capture.pcap --no-color > analysis.log
```

---

## 🔄 Capture + Analyze Workflow

This tool is designed to work alongside `tcpdump`. The recommended workflow is:

### Step 1 — Capture traffic with tcpdump

```bash
# Capture 5000 packets on eth0
sudo tcpdump -i eth0 -c 5000 -w capture.pcap

# Capture for 60 seconds
sudo tcpdump -i eth0 -G 60 -W 1 -w capture.pcap

# Capture only HTTP and HTTPS traffic
sudo tcpdump -i eth0 'tcp port 80 or tcp port 443' -w web_traffic.pcap

# Capture traffic from a specific IP
sudo tcpdump -i eth0 host 192.168.1.100 -w suspect.pcap

# Capture to a rolling 100MB file
sudo tcpdump -i eth0 -C 100 -w rolling.pcap
```

### Step 2 — Analyze with this tool

```bash
python3 pcap_analyzer.py capture.pcap
```

> **Why separate capture and analysis?**
> Running `tcpdump` and analysis in the same process adds overhead during capture and can drop packets on busy interfaces. Separating them also means you can analyze the same pcap multiple times with different thresholds without re-capturing.

---

## 🌍 Real-Life Use Cases

| Scenario | How This Tool Helps |
|---|---|
| **Incident Response** | Drop a pcap from a suspicious host into the tool and get a prioritized alert list in seconds |
| **Port Scan Detection** | SYN-only flag analysis instantly reveals nmap-style scans |
| **Bandwidth Investigation** | Top talker pairs and bytes-per-source show exactly who is consuming bandwidth |
| **Malware C2 Detection** | DNS query table reveals beaconing to unusual domains |
| **Linux Admin Interviews** | Demonstrates practical knowledge of networking, protocols, and security tooling |
| **Firewall Rule Auditing** | Top destination ports show what services are actually being reached |
| **Network Baselining** | Run weekly captures and compare protocol distributions over time |
| **Training & Education** | Human-readable output makes it ideal for teaching packet analysis |

---

## ⚡ Performance

| Metric | Value |
|---|---|
| Parse speed | ~10,000 – 50,000 packets/sec (hardware dependent) |
| Memory usage | O(n unique IPs + ports) — not O(n packets) |
| Time complexity | O(n) — single pass over all packets |
| Startup time | < 1 second |
| Max tested pcap size | 500 MB+ |
| Protocols detected | TCP, UDP, ICMP, ARP, DNS, IPv6, HTTP |
| Alert rules | 5 built-in |
| Risky ports tracked | 12 |

---

## 🤝 Contributing

Contributions are welcome! Here are good areas to extend the tool:

- Add IPv6 full analysis (currently only counted, not deeply analyzed)
- Add TLS SNI extraction from HTTPS traffic
- Add GeoIP lookup for external IPs
- Add JSON output format alongside the text report
- Add a `--watch` mode that re-analyzes a growing pcap every N seconds
- Add more alert rules (e.g., DNS tunneling detection, beaconing frequency)

Please open an issue before submitting a large PR so we can discuss the approach.

---

## 📄 License

MIT License — see [LICENSE](LICENSE) for details.

---

## 👤 Author

Built as part of a Linux Administration & Network Security portfolio project.

> *"Most candidates don't have this."*

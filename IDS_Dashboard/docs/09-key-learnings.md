# 🧠 09 — Key Learnings

## Technical Skills Gained

### Intrusion Detection Systems
- Understood the difference between **signature-based** detection (matching known patterns) and **threshold-based** detection (counting events over time)
- Learned how to configure both **Suricata** and **Snort** from scratch — including interface binding, HOME_NET definition, rule file management, and log output formats
- Understood why Suricata's `eve.json` is superior to `fast.log` for SIEM integration — it contains full packet metadata in structured JSON rather than one-line summaries
- Discovered that the **network interface misconfiguration** is the single most common reason IDS tools fail silently — always verify with `ip a` before configuring

### Custom Rule Writing
- Learned the structure of IDS rules: `action protocol src_ip src_port -> dst_ip dst_port (options)`
- Understood the purpose of each rule option: `msg`, `flags`, `threshold`, `track`, `count`, `seconds`, `sid`, `rev`
- Learned why **threshold tuning** matters — rules that are too sensitive generate alert fatigue, rules that are too strict miss real attacks
- Understood that both Suricata and Snort share nearly identical rule syntax — skills transfer between tools

### Network Traffic Analysis
- Gained hands-on experience reading raw packets in **Wireshark** — identifying TCP handshakes, SYN floods, ICMP sequences, and SSH connection patterns
- Understood how a **port scan looks at the packet level** — a rapid sweep of SYN packets with no corresponding ACK responses
- Understood how **ping -f differs from normal ping** — the inter-packet gap drops from 1 second to near-zero

### SIEM and Log Management
- Configured the **Splunk Universal Forwarder** to monitor log files and forward them over TCP to a remote Splunk indexer
- Understood the role of `inputs.conf` (what to monitor) and `outputs.conf` (where to send it)
- Learned how to write **SPL (Search Processing Language)** queries to filter, aggregate, and visualize security events
- Built a multi-panel **Splunk dashboard** that gives an at-a-glance view of the security posture of the lab

### Attacker Perspective
- Understood how **Nmap SYN scans** work and why they are considered "stealthy" compared to full TCP connect scans
- Understood how **Hydra** orchestrates credential brute force and why rate-limiting is an effective defense
- Gained appreciation for the **attacker-defender mindset gap** — attackers need to succeed once, defenders need to detect every time

---

## Conceptual Lessons

- **Defense in depth matters** — running both an IDS and a SIEM means alerts are captured even if one component has issues
- **Alert tuning is an ongoing process** — initial rules either miss attacks or generate too many false positives; tuning is a continuous SOC responsibility
- **Log forwarding latency is real** — there is always a short delay between an event happening and appearing in Splunk; in real SOC work, this needs to be minimized
- **MITRE ATT&CK provides a shared language** — mapping each attack to a technique makes communication between analysts, threat intel teams, and management much clearer

---

## What I Would Do Differently / Next Steps

- Implement **fail2ban** on the Ubuntu VM to automatically block brute force source IPs at the OS level
- Add **Zeek (formerly Bro)** alongside Suricata for richer network metadata in logs
- Write a **Splunk correlation search** that automatically creates a notable event when the same IP triggers three different alert types within 10 minutes
- Set up **Splunk alerting** via email or Slack to simulate a real SOC alert notification workflow
- Expand the ruleset to cover **DNS tunneling** and **HTTP-based C2 traffic** patterns

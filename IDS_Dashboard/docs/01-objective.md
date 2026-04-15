# 📌 01 — Objective

## Primary Goal

Build a functional network intrusion detection lab that detects malicious network activity in real-time, simulates common attacker techniques, and forwards security alerts to a centralized Splunk SIEM dashboard for analysis — mirroring the workflow of a real-world SOC environment.

---

## Specific Objectives

### Defensive Side
- Deploy and configure **Suricata** and **Snort** as network-based IDS engines on a monitored Ubuntu server
- Write custom detection rules for known attack patterns (port scans, ICMP floods, SSH brute force)
- Capture and inspect network traffic using **Wireshark** to understand packet-level behavior
- Forward generated alert logs to a **Splunk** instance via the **Splunk Universal Forwarder**
- Build a **Splunk dashboard** to visualize and monitor alerts in real time

### Offensive Side
- Use **Kali Linux** to simulate realistic attack scenarios against the defender machine
- Execute **Nmap port scans**, **ICMP ping floods**, and **SSH brute force** attempts
- Validate that each simulated attack is correctly detected and alerted by the IDS

---

## Learning Outcomes

By completing this project, the following skills are demonstrated:

| Skill Area | What Was Practiced |
|---|---|
| **IDS Configuration** | Installing, configuring, and tuning Suricata and Snort |
| **Custom Rule Writing** | Authoring detection rules in both Suricata and Snort syntax |
| **Packet Analysis** | Reading and interpreting raw network traffic in Wireshark |
| **Attack Simulation** | Executing port scans, ICMP floods, and brute force attacks |
| **Log Forwarding** | Configuring Splunk Universal Forwarder to ship logs remotely |
| **SIEM Operations** | Writing SPL queries and building alert dashboards in Splunk |
| **SOC Workflow** | Experiencing the full detect → alert → analyze → respond cycle |

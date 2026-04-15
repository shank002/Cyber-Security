# 🎯 07 — Use Cases

## Use Case 1 — Detecting External Reconnaissance (Port Scanning)

### Scenario
An external attacker (Kali VM) performs a stealthy SYN scan against the defender machine to enumerate open ports before launching a targeted attack.

### Detection Method
Suricata/Snort monitors for a high volume of TCP SYN packets from a single source IP across multiple destination ports within a short time window.

### Rule Triggered
```
alert tcp any any -> $HOME_NET any (msg:"Nmap Port Scan Detected"; flags:S;
threshold:type threshold, track by_src, count 20, seconds 3; sid:1000003; rev:1;)
```

### SOC Response Action
- Identify source IP from alert
- Check if IP is known/trusted in network inventory
- Block IP at firewall level if unauthorized
- Check what ports were scanned to assess attacker's target interest

---

## Use Case 2 — Detecting Denial of Service (ICMP Flood)

### Scenario
An attacker floods the target machine with ICMP echo requests to degrade network performance or as a distraction while another attack is carried out.

### Detection Method
IDS counts ICMP packets per source IP. When the count exceeds 10 packets within 2 seconds, an alert fires.

### Rule Triggered
```
alert icmp any any -> $HOME_NET any (msg:"ICMP Ping Flood Detected";
threshold:type threshold, track by_src, count 10, seconds 2; sid:1000004; rev:1;)
```

### SOC Response Action
- Confirm flood is ongoing using Wireshark
- Rate-limit ICMP traffic at the network perimeter
- Check for simultaneous attacks that may be using the flood as cover

---

## Use Case 3 — Detecting Credential Brute Force (SSH)

### Scenario
An attacker uses Hydra to systematically try thousands of username/password combinations against the SSH service to gain unauthorized remote access.

### Detection Method
IDS monitors TCP connections to port 22. When more than 5 connection attempts from the same source occur within 10 seconds, an alert is generated.

### Rule Triggered
```
alert tcp any any -> $HOME_NET 22 (msg:"SSH Brute Force Attempt";
threshold:type threshold, track by_src, count 5, seconds 10; sid:1000002; rev:1;)
```

### SOC Response Action
- Confirm attack in Splunk dashboard — check frequency and source IP
- Temporarily block source IP at firewall
- Check SSH auth logs for any successful logins: `sudo cat /var/log/auth.log | grep "Accepted"`
- Consider implementing fail2ban for automated SSH blocking
- Enforce SSH key-based authentication to eliminate password attacks

---

## Use Case 4 — Multi-Attack Correlation in Splunk

### Scenario
An attacker performs a port scan, followed by an ICMP flood, followed by an SSH brute force — a classic kill chain progression.

### Detection Method
Splunk correlates alerts across all three rule categories from the same source IP, identifying the full attack pattern rather than individual isolated events.

### SPL Query for Correlation
```spl
index=ids_alerts sourcetype=suricata event_type=alert
| stats count by src_ip, alert.signature
| where count > 1
| sort -count
```

### SOC Response Action
- Treat as a coordinated attack — escalate priority
- Preserve all logs for forensic timeline reconstruction
- Block source IP across all services, not just SSH
- Review whether any stage of the attack succeeded

---

## Use Case Summary

| Use Case | Attack Type | MITRE Technique | IDS Rule SID | Splunk Panel |
|---|---|---|---|---|
| Port Scan Detection | Reconnaissance | T1046 | 1000003 | Alerts by Signature |
| ICMP Flood Detection | DoS | T1498 | 1000004 | Alerts by Protocol |
| SSH Brute Force | Credential Access | T1110.001 | 1000002 | SSH Brute Force Events |
| Kill Chain Correlation | Multi-stage Attack | Multiple | Multiple | Top Source IPs |

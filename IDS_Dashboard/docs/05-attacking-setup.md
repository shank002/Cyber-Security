# ⚔️ 05 — Attacking Setup (Kali Linux — Attack Simulation)

## Overview

The attacking side of the lab runs on a **Kali Linux VM**. All attacks were executed against the Ubuntu Defender VM (192.168.56.10) to trigger IDS rules and validate the detection pipeline.

> ⚠️ **Important:** All attacks were conducted exclusively within an isolated VirtualBox internal/host-only network. No attacks were performed on real networks or external systems.

---

## Pre-Attack Checklist

Before launching any attack, confirm the following on the **Ubuntu (Defender) VM**:

```bash
# 1. Confirm Suricata is running
sudo systemctl status suricata

# 2. Start watching alerts in real time
sudo tail -f /var/log/suricata/fast.log

# 3. Confirm attacker VM can reach defender VM
ping 192.168.56.10
```

---

## Attack 1 — Nmap SYN Port Scan

### What it does
Sends TCP SYN packets across hundreds of ports rapidly to discover open services. This is typically the first step in a real-world reconnaissance phase.

### MITRE ATT&CK Mapping
`TA0043 — Reconnaissance` → `T1046 — Network Service Discovery`

### Command

```bash
# Basic SYN scan (stealth scan)
nmap -sS 192.168.56.10

# Aggressive scan — OS detection, version detection, traceroute
nmap -A -T4 192.168.56.10

# Full port scan across all 65535 ports
nmap -sS -p- 192.168.56.10
```

### What the IDS sees
A burst of TCP SYN packets from a single source IP across many destination ports within a very short time window — triggers the port scan detection rule.

### Expected Alert in fast.log
```
[**] [1:1000003:1] Nmap Port Scan Detected [**]
[Priority: 2] {TCP} 192.168.56.20:XXXXX -> 192.168.56.10:80
```

---

## Attack 2 — ICMP Ping Flood

### What it does
Sends ICMP echo requests as fast as possible, overwhelming the target with ping packets. In a real attack this can degrade availability and is a classic DoS technique.

### MITRE ATT&CK Mapping
`TA0040 — Impact` → `T1498 — Network Denial of Service`

### Command

```bash
# Basic ping flood (-f = flood mode)
sudo ping -f 192.168.56.10

# Run for a fixed duration (10 seconds)
sudo ping -f -w 10 192.168.56.10

# Using hping3 for more control
sudo hping3 --icmp --flood 192.168.56.10
```

### What the IDS sees
A single source IP sending 100+ ICMP packets within 1-2 seconds — far exceeding normal ping rates.

### Expected Alert in fast.log
```
[**] [1:1000004:1] ICMP Ping Flood Detected [**]
[Priority: 2] {ICMP} 192.168.56.20 -> 192.168.56.10
```

---

## Attack 3 — SSH Brute Force

### What it does
Repeatedly attempts to authenticate to an SSH service using different username and password combinations. A common credential-based attack targeting remote access services.

### MITRE ATT&CK Mapping
`TA0006 — Credential Access` → `T1110.001 — Brute Force: Password Guessing`

### Command

```bash
# Using Hydra with rockyou wordlist
hydra -l root -P /usr/share/wordlists/rockyou.txt ssh://192.168.56.10

# Faster — limit to 4 threads
hydra -l root -P /usr/share/wordlists/rockyou.txt -t 4 ssh://192.168.56.10

# Quick manual simulation using a loop
for i in {1..10}; do ssh root@192.168.56.10 2>/dev/null; done
```

> Note: If rockyou.txt is compressed, extract first:
> ```bash
> gunzip /usr/share/wordlists/rockyou.txt.gz
> ```

### What the IDS sees
Multiple TCP connections to port 22 from a single source within a short time window — triggers the SSH brute force threshold rule.

### Expected Alert in fast.log
```
[**] [1:1000002:1] SSH Brute Force Attempt [**]
[Priority: 1] {TCP} 192.168.56.20:XXXXX -> 192.168.56.10:22
```

---

## Attack Verification Flow

After each attack, verify detection on the **Ubuntu VM**:

```bash
# Check fast.log for new alerts
sudo tail -20 /var/log/suricata/fast.log

# Filter eve.json for specific attack types
sudo cat /var/log/suricata/eve.json | grep '"event_type":"alert"' | python3 -m json.tool

# Check if Suricata saw the traffic at all (even if no alert fired)
sudo cat /var/log/suricata/eve.json | grep '"dest_port":22'
sudo cat /var/log/suricata/eve.json | grep '"proto":"ICMP"'
```

---

## Attack Summary Table

| Attack | Tool Used | Target Port/Protocol | IDS Rule SID | MITRE Technique |
|---|---|---|---|---|
| Port Scan | Nmap | TCP / All ports | 1000003 | T1046 |
| ICMP Flood | ping -f / hping3 | ICMP | 1000004 | T1498 |
| SSH Brute Force | Hydra | TCP / Port 22 | 1000002 | T1110.001 |

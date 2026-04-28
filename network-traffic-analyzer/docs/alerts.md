# 🚨 Alert Engine — How It Works

The alert engine is the security core of the analyzer. After all packets have been parsed into counters, `generate_alerts()` evaluates 5 detection rules and builds a list of human-readable alert strings.

---

## Alert Rules

### Rule 1 — High-Volume Source IP

**Trigger:** Any source IP sends ≥ `threshold` packets (default: 50)

**What it catches:**
- Port scanners making many connection attempts
- Hosts sending repeated requests (brute-force, fuzzing)
- Misconfigured software in a retry loop
- DDoS participant machines

**How to tune:**
- On a busy production server, raise the threshold (`-t 500` or higher)
- For a quiet internal network, lower it (`-t 10`) to catch light scanners

```bash
# Catch anything sending more than 10 packets
python3 pcap_analyzer.py capture.pcap -t 10

# Only flag extreme cases (busy server)
python3 pcap_analyzer.py capture.pcap -t 500
```

---

### Rule 2 — SYN Scan Detection

**Trigger:** More than 20 TCP packets with the SYN flag set and no ACK flag

**What it catches:**
- `nmap -sS` (TCP SYN scan — the most common nmap mode)
- Any tool doing half-open connection scanning
- Automated vulnerability scanners

**Why SYN-only means scan:**

In normal TCP, a connection goes: `SYN → SYN-ACK → ACK` (the three-way handshake). A legitimate client that opens a connection always follows the SYN with an ACK. A scanner sends only SYN packets to check if ports are open (the target responds with SYN-ACK if open, RST if closed) and never completes the handshake. A high count of `S` (SYN-only) flags with no corresponding `SA` (SYN-ACK from the sender) is the signature.

**Threshold:** 20 SYN-only packets. This avoids false positives from legitimate connection setup bursts while catching any real scan (which typically involves hundreds or thousands of SYN packets).

---

### Rule 3 — Risky Port Traffic

**Trigger:** Any packets detected going to the following ports:

| Port | Service | Why It's Risky |
|---|---|---|
| 21 | FTP | Cleartext credentials, unencrypted transfers |
| 22 | SSH | Brute-force target, lateral movement |
| 23 | Telnet | Completely unencrypted — should never be used |
| 3389 | RDP | Most exploited Windows remote access port |
| 4444 | Metasploit default | Default Meterpreter reverse shell port |
| 5900 | VNC | Remote desktop, often unencrypted |
| 6666 | IRC / backdoor | Malware C2 channel |
| 6667 | IRC | Historical C2 for botnets |
| 1337 | Hacker slang port | Common backdoor/RAT port |
| 31337 | "Elite" port | Classic backdoor port |
| 12345 | NetBus | Old RAT (Remote Access Trojan) |
| 9001 | Tor / custom | Tor relay port, also used by malware |

**Note:** Port 22 (SSH) is flagged because it appears in captures where unexpected machines are attempting SSH — not because SSH itself is malicious. Use your judgment and the source IP context when evaluating this alert.

---

### Rule 4 — ICMP Flood

**Trigger:** Total ICMP packet count ≥ `threshold`

**What it catches:**
- Ping flood (`ping -f target`)
- ICMP-based DoS attacks
- Network mapping tools using ICMP echo

**What it does NOT catch:**
- Normal ping (2–3 ICMP packets) — well below any reasonable threshold
- ICMP-based traceroute — generates some ICMP but not typically above threshold

---

### Rule 5 — ARP Sweep

**Trigger:** More than 20 unique ARP WHO-HAS target IP addresses

**What it catches:**
- `arp-scan -l` or similar subnet discovery tools
- nmap host discovery phase (`nmap -sn 192.168.1.0/24`)
- Attackers mapping a local network before targeting specific hosts

**Why the threshold is 20:**
A normal host ARPs for its gateway, DNS server, and a handful of other machines it communicates with. Even a busy workstation rarely ARPs for more than 10–15 unique IPs in a short capture window. 20+ unique ARP targets in one capture almost always indicates intentional scanning.

---

## Alert Output Format

Each alert is rendered in the terminal with a red `⚠` symbol:

```
┏━━━━━━━━━━━━━━━━━━━━ 🚨  ALERTS  (3 found) ━━━━━━━━━━━━━━━━━━━━┓
┃  ⚠  High-volume source 10.0.0.99 — 70 packets                 ┃
┃  ⚠  Possible SYN scan: 170 SYN-only packets detected          ┃
┃  ⚠  Traffic to risky port 4444 (4444) — 20 packets            ┃
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
```

In the plain-text report (`-o report.txt`), alerts appear as:

```
--- ALERTS ---
  [ALERT] High-volume source 10.0.0.99 — 70 packets
  [ALERT] Possible SYN scan: 170 SYN-only packets detected
  [ALERT] Traffic to risky port 4444 (4444) — 20 packets
```

---

## Customizing the Alert Engine

The alert rules and port list are defined as constants at the top of `pcap_analyzer.py`. You can modify them for your environment:

```python
# Add or remove ports from the risky list
SUSPICIOUS_PORTS = {21, 22, 23, 3389, 4444, 5900, 6666, 6667, 1337, 31337, 12345, 9001}

# Example: add database ports to the watchlist
SUSPICIOUS_PORTS = {21, 22, 23, 3389, 4444, 5900, 3306, 5432, 27017}
```

To change the SYN scan detection threshold (currently 20 SYN-only packets), modify this line in `generate_alerts()`:

```python
if syn_only > 20:    # Change 20 to your preferred sensitivity
```

To change the ARP scan detection threshold (currently 20 unique targets):

```python
if len(self.arp_targets) > 20:    # Change 20 to your preference
```

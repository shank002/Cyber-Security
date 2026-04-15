# 📈 08 — Results & Outputs

## IDS Alert Results

### Suricata fast.log — Sample Output

The following alerts were generated during attack simulation sessions:

```
04/15/2026-10:12:34.112233  [**] [1:1000003:1] Nmap Port Scan Detected [**]
[Classification: Attempted Information Leak] [Priority: 2]
{TCP} 192.168.56.20:52341 -> 192.168.56.10:80

04/15/2026-10:13:01.887612  [**] [1:1000003:1] Nmap Port Scan Detected [**]
[Classification: Attempted Information Leak] [Priority: 2]
{TCP} 192.168.56.20:52342 -> 192.168.56.10:443

04/15/2026-10:15:44.334221  [**] [1:1000004:1] ICMP Ping Flood Detected [**]
[Classification: Attempted Denial of Service] [Priority: 2]
{ICMP} 192.168.56.20 -> 192.168.56.10

04/15/2026-10:18:22.009871  [**] [1:1000002:1] SSH Brute Force Attempt [**]
[Classification: Attempted Administrator Privilege Gain] [Priority: 1]
{TCP} 192.168.56.20:54231 -> 192.168.56.10:22
```

---

### Suricata eve.json — Sample Alert Event (Parsed)

```json
{
  "timestamp": "2026-04-15T10:18:22.009871+0000",
  "flow_id": 1234567890,
  "event_type": "alert",
  "src_ip": "192.168.56.20",
  "src_port": 54231,
  "dest_ip": "192.168.56.10",
  "dest_port": 22,
  "proto": "TCP",
  "alert": {
    "action": "allowed",
    "gid": 1,
    "signature_id": 1000002,
    "rev": 1,
    "signature": "SSH Brute Force Attempt",
    "category": "Attempted Administrator Privilege Gain",
    "severity": 1
  }
}
```

---

## Detection Rate Summary

| Attack Simulated | Alerts Fired | Detection Rate | Avg Alert Latency |
|---|---|---|---|
| Nmap SYN Scan | ✅ Yes | 100% | < 3 seconds |
| ICMP Ping Flood | ✅ Yes | 100% | < 2 seconds |
| SSH Brute Force | ✅ Yes | 100% | < 5 seconds |

All three attack types were successfully detected by both Suricata and Snort.

---

## Splunk Dashboard Results

### Alerts Over Time Panel
The line chart showed clear spikes in alert volume corresponding to each attack session, making it easy to identify when attacks occurred and how long they lasted.

### Top Source IPs Panel
The attacker VM IP (`192.168.56.20`) appeared at the top of the source IP table with the highest alert count across all categories — demonstrating effective attacker attribution.

### Alerts by Signature Panel
```
SSH Brute Force Attempt        → 47 alerts
Nmap Port Scan Detected        → 31 alerts
ICMP Ping Flood Detected       → 18 alerts
```

### Alerts by Protocol Panel
```
TCP     → 68%
ICMP    → 23%
UDP     →  9%
```

---

## Wireshark Capture Results

### Port Scan Traffic Pattern
Wireshark captured thousands of TCP SYN packets from `192.168.56.20` to `192.168.56.10` across sequential ports within milliseconds — clearly visible as a sweep pattern in the packet list.

Filter used:
```
tcp.flags.syn == 1 && tcp.flags.ack == 0 && ip.src == 192.168.56.20
```

### ICMP Flood Traffic Pattern
Wireshark showed a burst of ICMP echo requests with near-zero inter-packet timing — consistent with the `ping -f` flood mode generating several hundred packets per second.

Filter used:
```
icmp && ip.src == 192.168.56.20
```

---

## Splunk Forwarding Verification

Confirmed successful log forwarding by running in Splunk:

```spl
index=ids_alerts host=ubuntu-ids-lab | head 5
```

Events appeared in Splunk within approximately **5–10 seconds** of being written to eve.json on the Ubuntu VM, confirming the Universal Forwarder was operating correctly in near-real-time.

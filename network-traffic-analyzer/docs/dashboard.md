# 📊 Dashboard Sections — Full Reference

This document explains every section of the terminal dashboard produced by `pcap_analyzer.py`.

---

## 1. Capture Summary

```
╭──────────────────────── CAPTURE SUMMARY ─────────────────────────╮
│ Total Packets    206          Total Bytes     11,420  (11.1 KB)  │
│ Packets / sec    2.8          Duration        74.50s             │
│ First Packet     2026-03-22 23:08:40 UTC                         │
│ Last Packet      2026-03-22 23:09:55 UTC                         │
│ Unique Src IPs   6            Unique Dst IPs  2                  │
│ Alert Threshold  ≥ 30 pkts/IP IPv6 Src / Dst  0 / 0             │
╰──────────────────────────────────────────────────────────────────╯
```

**What it tells you:**

| Field | Meaning |
|---|---|
| Total Packets | How many packets were in the pcap file |
| Total Bytes | Combined size of all packet payloads |
| Packets / sec | Average traffic rate across the capture window |
| Duration | Time between first and last packet timestamp |
| First / Last Packet | Exact UTC timestamps from pcap headers |
| Unique Src/Dst IPs | How many distinct machines were communicating |
| Alert Threshold | The `-t` value in use — IPs above this are flagged |
| IPv6 Src / Dst | Count of IPv6 addresses seen (full analysis is IPv4 only) |

**What to look for:**
- A very high `pps` (packets/sec) on a short capture = potential flood or scan
- A low `Unique Src IPs` with high `Total Packets` = a small number of hosts generating all the traffic

---

## 2. 🚨 Alerts

```
┏━━━━━━━━━━━━━━━━━━━━━━━━ 🚨 ALERTS  (6 found) ━━━━━━━━━━━━━━━━━━━━━━━━┓
┃  ⚠  High-volume source 10.0.0.99 — 70 packets                        ┃
┃  ⚠  Possible SYN scan: 170 SYN-only packets detected                 ┃
┃  ⚠  Traffic to risky port 4444 (4444) — 20 packets                  ┃
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
```

This is the most important section. The alert engine checks 5 rules automatically:

| Alert Type | Trigger | What it means |
|---|---|---|
| High-volume source | Any src IP sends ≥ threshold packets | Could be a scanner, flooder, or misconfigured host |
| SYN scan | > 20 SYN-only (no ACK) packets | Classic nmap / port scanner behavior |
| Risky port traffic | Any packets to ports: 21, 22, 23, 3389, 4444, 5900, 6666, 6667, 1337, 31337, 12345, 9001 | Attacker tools, backdoors, legacy insecure services |
| ICMP flood | ICMP count ≥ threshold | Ping flood / DoS attempt |
| ARP scan | > 20 unique ARP WHO-HAS targets | Someone mapping your local subnet |

If no alerts fire, the section shows a green **✔ No suspicious activity detected.**

---

## 3. Protocol Breakdown

```
  Protocol    Packets      %    Bar
  ─────────────────────────────────────────
  TCP             190    92.2%  ████████████████████
  UDP              16     7.8%  █░░░░░░░░░░░░░░░░░░░
```

Shows the traffic composition of the capture. The bar chart gives an instant visual sense of the protocol mix.

**What to look for:**
- Unusually high `ICMP` → ping sweep or DoS
- Unusually high `ARP` → network scan or misconfigured device
- Very high `OTHER` → non-standard or malformed packets

---

## 4. TCP Flag Analysis

```
  Flags     Count   Note
  ──────────────────────────────────
  S           170   SYN only — scan?
  FA           20   FIN-ACK — graceful close
  PA            8   PSH-ACK — payload
```

TCP uses flags to manage connection state. This table shows which flag combinations appeared and how often.

| Flag combo | Meaning | Security significance |
|---|---|---|
| `S` | SYN only | **High count = port scanner** (nmap default) |
| `SA` | SYN-ACK | Responses to SYN — shows open ports |
| `A` | ACK | Normal established connection data flow |
| `PA` | PSH-ACK | Data being sent in an established connection |
| `FA` | FIN-ACK | Clean connection close |
| `R` / `RA` | RST / RST-ACK | Abrupt connection close — closed port or firewall reject |

---

## 5. Top Source IPs

```
  #   IP             Packets    Bytes     Status           Bar
  ──────────────────────────────────────────────────────────────
  1   10.0.0.99          70     3,780   ⚠ SUSPICIOUS     ████████████████
  2   10.0.0.1           56     3,316   ⚠ SUSPICIOUS     █████████████
  3   10.0.0.2           20     1,080   △ ELEVATED        ████
```

**Status labels:**

| Label | Condition |
|---|---|
| ✔ OK | Packet count below half the threshold |
| △ ELEVATED | Packet count between half and full threshold |
| ⚠ SUSPICIOUS | Packet count at or above the threshold |

The `Bytes` column helps distinguish aggressive small-packet flooding from large legitimate transfers.

---

## 6. Top Destination IPs

Same layout as Source IPs but for receiving machines. Useful for spotting:
- An internal server being targeted heavily
- All traffic flowing to a single external IP (beaconing / C2)
- A broadcast/multicast address receiving unexpected traffic

---

## 7. Top Destination Ports

```
  #    Port   Service     Packets   Risk       Bar
  ────────────────────────────────────────────────────
  1      80   HTTP             90              ████████████████
  4      22   SSH              20   ⚠ RISKY    ████
  6    4444   —                20   ⚠ RISKY    ████
```

Port colors:

| Color | Ports |
|---|---|
| 🟢 Green | HTTP (80, 8080) |
| 🟡 Yellow | HTTPS (443, 8443) |
| 🟣 Magenta | SSH (22) |
| 🔵 Cyan | DNS (53) |
| 🔴 Red | Suspicious ports (4444, 3389, Telnet, etc.) |

The `Service` column maps port numbers to well-known service names for quick reading.

---

## 8. Top Talker Pairs

```
  #   Source          →    Dest              Packets
  ─────────────────────────────────────────────────────
  1   10.0.0.99       →    10.0.0.1              70
  2   10.0.0.1        →    8.8.8.8               56
```

Shows the most active `src → dst` conversation pairs. This is often more actionable than looking at individual IPs — a single IP might talk to many destinations, but the talker pairs table surfaces the *dominant flows*.

---

## 9. Top DNS Queries

```
  #   Domain                    Count
  ─────────────────────────────────────────
  1   google.com                    4
  2   api.example.com               4
  3   rockylinux.org                4
```

Extracted from UDP port 53 traffic. Every domain name that was looked up during the capture appears here.

**What to look for:**
- Random-looking domains (e.g., `a3f9b2.xyz`) → possible DGA (Domain Generation Algorithm) malware
- Unusually frequent queries to a single domain → DNS beaconing
- Internal hostnames being queried → maps your internal naming scheme

---

## 10. HTTP Hosts

```
  #   Host                    Requests
  ─────────────────────────────────────────
  1   api.example.com              12
  2   update.company.internal       3
```

Extracted from the `Host:` HTTP header in unencrypted HTTP traffic (port 80, 8080). Shows exactly which web servers were contacted.

> Note: HTTPS traffic (port 443) is encrypted, so this section only shows plain HTTP. For HTTPS host extraction, TLS SNI parsing would be needed.

---

## 11. ARP WHO-HAS Targets

```
  Target IP        Requests   Note
  ───────────────────────────────────────
  192.168.1.1           3
  192.168.1.100        45     ⚠ SCAN?
  192.168.1.101        44     ⚠ SCAN?
```

ARP is how machines on a local network ask "who has this IP?" before sending traffic. A normal host sends a handful of ARP requests. A scanner rapidly ARP-probes every IP in a subnet. The `⚠ SCAN?` flag appears on any target that received more than 10 ARP requests.

---

## 12. Footer

```
  206 packets  •  74.50s  •  2.8 pkt/s  •  11.1 KB  •  6 src IPs  •  2 dst IPs
```

A quick summary line at the bottom — useful at a glance when scrolling back through terminal history.

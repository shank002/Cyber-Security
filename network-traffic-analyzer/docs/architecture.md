# 🏗 Architecture & Design Decisions

This document explains how `pcap_analyzer.py` is structured internally and why certain design decisions were made.

---

## High-Level Architecture

The tool is organized into four logical layers:

```
┌──────────────────────────────────────────────────────────┐
│                        CLI Layer                         │
│   argparse · argument validation · file existence check  │
└────────────────────────────┬─────────────────────────────┘
                             │  path, threshold, top_n
┌────────────────────────────▼─────────────────────────────┐
│                     PcapAnalysis                         │
│                                                          │
│  load()                                                  │
│  ├── detect format (magic bytes)                         │
│  ├── dpkt.pcap.Reader  OR  dpkt.pcapng.Reader            │
│  └── _parse_packet(ts, raw) × N packets                 │
│       ├── dpkt.ethernet.Ethernet(raw)                    │
│       ├── ARP  → arp_targets Counter                     │
│       ├── IP   → src_ip, dst_ip, ip_pairs Counters       │
│       │   ├── TCP  → dst_port, tcp_flags Counters        │
│       │   │         HTTP Host extraction (regex)         │
│       │   ├── UDP  → dst_port Counter                    │
│       │   │         DNS query extraction (dpkt.dns)      │
│       │   └── ICMP → proto Counter                       │
│       └── IPv6 → ipv6_src, ipv6_dst Counters             │
│                                                          │
│  generate_alerts() — 5 detection rules                   │
└────────────────────────────┬─────────────────────────────┘
                             │  PcapAnalysis object
┌────────────────────────────▼─────────────────────────────┐
│                      Render Layer                        │
│   render(analysis) — builds all Rich tables              │
│   ├── Panel: Capture Summary                             │
│   ├── Panel: Alerts                                      │
│   ├── Columns: Protocol table + TCP Flags table          │
│   ├── Columns: Source IPs table + Dest IPs table         │
│   ├── Columns: Dest Ports table + Talker Pairs table     │
│   ├── Columns: DNS table + HTTP Hosts table              │
│   └── Table: ARP targets                                 │
└────────────────────────────┬─────────────────────────────┘
                             │  (optional)
┌────────────────────────────▼─────────────────────────────┐
│                     Report Layer                         │
│   _save_report(analysis, path)                           │
│   Plain-text, grep-friendly, no ANSI codes               │
└──────────────────────────────────────────────────────────┘
```

---

## Core Data Structures

All analysis state lives in a single `PcapAnalysis` class. Every counter is a `collections.Counter` — a dictionary subclass that handles missing keys automatically and provides `.most_common(N)` for ranked output.

```python
class PcapAnalysis:
    src_ip         = Counter()   # { "10.0.0.1": 56, ... }
    dst_ip         = Counter()   # { "8.8.8.8": 76, ... }
    proto          = Counter()   # { "TCP": 190, "UDP": 16, ... }
    dst_port       = Counter()   # { 80: 90, 443: 20, ... }
    src_port       = Counter()   # { 54321: 1, ... }
    ip_pairs       = Counter()   # { ("10.0.0.1", "8.8.8.8"): 56, ... }
    tcp_flags      = Counter()   # { "S": 170, "FA": 20, ... }
    dns_queries    = Counter()   # { "google.com": 4, ... }
    http_hosts     = Counter()   # { "api.example.com": 12, ... }
    bytes_per_src  = Counter()   # { "10.0.0.1": 3316, ... }
    arp_targets    = Counter()   # { "192.168.1.1": 3, ... }
    ipv6_src       = Counter()   # { "fe80::1": 2, ... }
    ipv6_dst       = Counter()   # { "2001:db8::1": 1, ... }
```

**Why Counter?**

- Zero-boilerplate: `counter[key] += 1` works even if `key` was never seen before
- Built-in `.most_common(N)` returns the top-N items sorted by value — exactly what the render layer needs
- Memory efficient: only stores keys that were actually seen

---

## Packet Parsing Pipeline

Every packet goes through the same pipeline regardless of type:

```
raw bytes (from pcap)
       │
       ▼
dpkt.ethernet.Ethernet(raw)
       │
       ├─── eth.data is ARP?  → update arp_targets
       │
       ├─── eth.data is IP?
       │         │
       │         ├── src/dst → update src_ip, dst_ip, ip_pairs, bytes_per_src
       │         │
       │         ├── ip.data is TCP?
       │         │       ├── update dst_port, src_port
       │         │       ├── update tcp_flags  (_flag_str converts int → "SA" etc.)
       │         │       └── if dport 80/8080: _extract_http_host()
       │         │
       │         ├── ip.data is UDP?
       │         │       ├── update dst_port, src_port
       │         │       └── if dport 53: _extract_dns()
       │         │
       │         └── ip.data is ICMP? → update proto["ICMP"]
       │
       ├─── eth.data is IPv6? → update ipv6_src, ipv6_dst
       │
       └─── anything else → proto["OTHER"]
```

Every branch is wrapped in `try/except` — a malformed packet in any layer silently increments `proto["OTHER"]` rather than crashing the entire run.

---

## Format Detection

pcap and pcapng files have different binary structures and require different readers:

```python
magic = fh.read(4)
fh.seek(0)

if magic in (b"\xd4\xc3\xb2\xa1", b"\xa1\xb2\xc3\xd4"):
    reader = dpkt.pcap.Reader(fh)      # classic pcap (little or big endian)
else:
    reader = dpkt.pcapng.Reader(fh)    # pcapng (Wireshark default)
```

The two magic bytes cover both little-endian and big-endian classic pcap files. Anything else is assumed to be pcapng — which covers modern Wireshark captures and `tcpdump -Z pcapng` output.

---

## TCP Flag Decoding

TCP flags are stored as a bitmask integer in the packet. The tool converts this to a human-readable string:

```python
TCP_FLAG_BITS = {0x01:"F", 0x02:"S", 0x04:"R", 0x08:"P", 0x10:"A", 0x20:"U"}

def _flag_str(flags: int) -> str:
    return "".join(s for bit, s in sorted(TCP_FLAG_BITS.items()) if flags & bit)
    # Example: 0x12 (SYN + ACK) → "SA"
    # Example: 0x02 (SYN only) → "S"
```

This allows the alert engine to detect `"S"` (SYN-only) with a simple counter lookup rather than bitwise arithmetic.

---

## Alert Engine

The alert engine runs after all packets are parsed. It evaluates 5 rules:

```python
def generate_alerts(self):

    # Rule 1: High-volume source IP
    for ip, count in self.src_ip.items():
        if count >= self.threshold:
            self.alerts.append(f"High-volume source {ip} — {count} packets")

    # Rule 2: SYN scan (SYN-only flag combinations)
    if self.tcp_flags.get("S", 0) > 20:
        self.alerts.append(f"Possible SYN scan: {syn} SYN-only packets")

    # Rule 3: Traffic to known risky ports
    for port in SUSPICIOUS_PORTS:     # {21, 22, 23, 3389, 4444, 5900, ...}
        if self.dst_port.get(port, 0) > 0:
            self.alerts.append(f"Traffic to risky port {port}")

    # Rule 4: ICMP flood
    if self.proto.get("ICMP", 0) >= self.threshold:
        self.alerts.append(f"ICMP flood suspected")

    # Rule 5: ARP sweep
    if len(self.arp_targets) > 20:
        self.alerts.append(f"ARP scan suspected: {len(self.arp_targets)} targets")
```

Rules are intentionally simple and explicit — no ML, no scoring, no tuning required beyond `-t`.

---

## Render Layer

The render layer uses the `rich` library exclusively. Key design decisions:

**Tables over raw print statements** — `rich.Table` handles column alignment, wrapping, and color automatically. It adapts to terminal width without manual calculation.

**Columns layout** — `rich.Columns([table_a, table_b])` places two tables side by side when there is room and stacks them vertically on narrow terminals. This happens automatically.

**Text objects for per-cell color** — Instead of wrapping entire rows in color tags, each cell uses a `rich.Text` object so individual fields can have independent styles (e.g., the IP is cyan but the status label is red).

**make_bar() helper** — A local function that builds a `rich.Text` bar from `█` and `░` characters, proportional to value/max_value. Keeps all bar rendering logic in one place.

---

## Why dpkt Instead of Scapy?

Scapy is the most popular Python packet library, but it has a hard dependency on the OS routing table for IPv6 (`scapy.route6`). On minimal Rocky Linux installs, containers, or any system where IPv6 routing is not fully configured, Scapy raises:

```
KeyError: 'scope'
  File ".../scapy/arch/linux/rtnetlink.py", line 971
```

This crash happens at import time — before any pcap file is even opened. Since the tool needs to run reliably on minimal server installs (which is the primary Rocky Linux use case), `dpkt` was chosen instead.

`dpkt` is a pure packet parsing library. It reads bytes and returns structured objects. It has no OS dependencies, no routing table lookups, and no network interface access. For a pcap analyzer that never needs to send packets, `dpkt` is strictly better.

| Criteria | scapy | dpkt |
|---|---|---|
| Parse pcap files | ✅ | ✅ |
| Works on minimal Linux | ❌ (IPv6 crash) | ✅ |
| Import time | ~3–5 seconds | < 0.1 seconds |
| Dependencies | Many | None (stdlib only) |
| Send/craft packets | ✅ | ❌ (not needed here) |

---

## Single-Pass Design

The entire analysis runs in one pass over the packet list. There is no second loop, no re-reading the file, and no deferred computation. This means:

- Time complexity: **O(n)** where n = number of packets
- Memory for counters: **O(u)** where u = unique IPs/ports/domains (much smaller than n)
- The file is read once and then closed

For a 100,000-packet capture, the single-pass design typically completes in under 2 seconds on a standard server.

# 🖥 Usage Examples

Real-world scenarios and the exact commands to use for each.

---

## Scenario 1 — Investigating a Suspicious Host

You've noticed unusual outbound traffic from `192.168.1.55`. Capture its traffic and analyze it.

```bash
# Capture only traffic from/to the suspect host (60 seconds)
sudo tcpdump -i eth0 host 192.168.1.55 -G 60 -W 1 -w suspect.pcap

# Analyze with a low threshold to catch even light activity
python3 pcap_analyzer.py suspect.pcap -t 10 -o suspect_report.txt
```

**What to look for in the output:**
- DNS Queries table — is it contacting unusual domains?
- Talker Pairs — is it sending data to an unexpected external IP?
- TCP Flags — high `S` count means it might be scanning other hosts

---

## Scenario 2 — Port Scan Detection

Someone may be scanning your network. Capture all traffic on your main interface.

```bash
# Capture 10,000 packets
sudo tcpdump -i eth0 -c 10000 -w scan_check.pcap

# Analyze — look for SYN scan alert
python3 pcap_analyzer.py scan_check.pcap
```

**Key indicators in the output:**
- `🚨 ALERTS` section will show "Possible SYN scan" if > 20 SYN-only packets are present
- `TCP FLAGS` table will show a high `S` count
- `Top Source IPs` will show the scanner's IP with ⚠ SUSPICIOUS label

---

## Scenario 3 — Bandwidth Investigation

Your internet connection is saturated and you don't know why.

```bash
# Capture 5 minutes of traffic
sudo tcpdump -i eth0 -G 300 -W 1 -w bandwidth.pcap

# Analyze — show top 20 source IPs and pairs
python3 pcap_analyzer.py bandwidth.pcap -T 20
```

**Key indicators in the output:**
- `Top Source IPs` — `Bytes` column shows who is sending the most data
- `Top Talker Pairs` — shows the dominant flows consuming bandwidth
- `Top Destination Ports` — is most traffic going to port 443 (backups/uploads) or something else?

---

## Scenario 4 — Web Traffic Audit

You want to know what websites machines on your network are visiting over plain HTTP.

```bash
# Capture only HTTP traffic
sudo tcpdump -i eth0 'tcp port 80' -c 5000 -w http_traffic.pcap

# Analyze
python3 pcap_analyzer.py http_traffic.pcap
```

**Key indicators in the output:**
- `HTTP HOSTS` table lists every `Host:` header seen — these are the websites being accessed
- `Top Destination IPs` shows the servers' IP addresses
- `DNS QUERIES` shows domain lookups that preceded the HTTP connections

---

## Scenario 5 — Incident Response (Quick Triage)

You have a pcap from an incident and need a fast summary before deep analysis.

```bash
# Quick triage — save report for documentation
python3 pcap_analyzer.py incident.pcap -o /var/log/ir/$(date +%Y%m%d)_triage.txt

# Then review alerts, top IPs, and DNS queries
```

The plain-text report is grep-friendly:

```bash
# Find all alerts in the report
grep "\[ALERT\]" /var/log/ir/20260322_triage.txt

# Find all suspicious IPs
grep "SUSPICIOUS" /var/log/ir/20260322_triage.txt
```

---

## Scenario 6 — Scheduled Nightly Capture + Analysis

Set up a cron job to capture and analyze traffic automatically every night.

```bash
# Create the script
cat > /usr/local/bin/nightly_capture.sh << 'EOF'
#!/bin/bash
DATE=$(date +%Y%m%d)
OUTDIR="/var/log/nta"
mkdir -p "$OUTDIR"

# Capture 5 minutes of traffic
tcpdump -i eth0 -G 300 -W 1 -w "$OUTDIR/capture_${DATE}.pcap" 2>/dev/null

# Analyze and save report
python3 /opt/pcap-analyzer/pcap_analyzer.py \
  "$OUTDIR/capture_${DATE}.pcap" \
  --no-color \
  -t 100 \
  -o "$OUTDIR/report_${DATE}.txt"

# Alert if suspicious activity found
if grep -q "\[ALERT\]" "$OUTDIR/report_${DATE}.txt"; then
  echo "Suspicious activity detected — see $OUTDIR/report_${DATE}.txt" \
    | mail -s "NTA Alert $(date)" admin@company.com
fi
EOF

chmod +x /usr/local/bin/nightly_capture.sh

# Add to crontab (runs at 2:00 AM every day)
echo "0 2 * * * root /usr/local/bin/nightly_capture.sh" >> /etc/cron.d/nta
```

---

## Scenario 7 — Analyzing a Wireshark Export

Wireshark saves files in `.pcapng` format by default. The tool handles this automatically.

```bash
# Wireshark export (File → Export → pcapng)
python3 pcap_analyzer.py wireshark_export.pcapng
```

No flags needed — the tool detects the format from the file's magic bytes.

---

## Scenario 8 — Comparing Threshold Sensitivity

Run the same pcap with different thresholds to understand your traffic baseline.

```bash
# Default threshold
python3 pcap_analyzer.py capture.pcap -t 50

# Strict — catch everything
python3 pcap_analyzer.py capture.pcap -t 5

# Loose — only flag extreme cases
python3 pcap_analyzer.py capture.pcap -t 200
```

Use the strict run to understand normal traffic volumes. Once you know your typical max packets-per-IP, set the threshold just above that for production monitoring.

---

## Common tcpdump Capture Filters

Use these with `tcpdump -i <interface> '<filter>' -w output.pcap` to focus captures:

| Goal | Filter |
|---|---|
| All traffic | *(no filter)* |
| Specific host | `host 192.168.1.100` |
| Specific network | `net 192.168.1.0/24` |
| HTTP only | `tcp port 80` |
| DNS only | `udp port 53` |
| Exclude SSH | `not port 22` |
| TCP SYN packets only | `tcp[tcpflags] & tcp-syn != 0` |
| ICMP only | `icmp` |
| Traffic between two hosts | `host 10.0.0.1 and host 10.0.0.2` |
| High ports only | `portrange 1024-65535` |

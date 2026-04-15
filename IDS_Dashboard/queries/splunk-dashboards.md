# 📊 Splunk Dashboard Panel Queries

All panels are part of the **"IDS Security Monitoring"** dashboard in Splunk.
Each query below corresponds to one panel in the dashboard.

---

## Panel 1 — Total Alerts (Last 24 Hours)
**Type:** Single Value

```spl
index=ids_alerts sourcetype=suricata event_type=alert earliest=-24h
| stats count as "Total Alerts"
```

**Display settings:**
- Visualization: Single Value
- Unit: Alerts
- Color: Green → Yellow → Red based on thresholds (e.g., 0–10 green, 11–50 yellow, 51+ red)

---

## Panel 2 — Alerts Over Time
**Type:** Line Chart

```spl
index=ids_alerts sourcetype=suricata event_type=alert earliest=-24h
| timechart span=5m count by alert.signature
```

**Display settings:**
- X Axis: Time
- Y Axis: Alert Count
- Each line: One rule/signature
- Span: 5 minutes (adjust to `1m` for live monitoring or `1h` for daily review)

---

## Panel 3 — Top Alert Signatures (Bar Chart)
**Type:** Bar Chart

```spl
index=ids_alerts sourcetype=suricata event_type=alert
| stats count by alert.signature
| sort -count
| head 10
| rename alert.signature as "Alert Type", count as "Count"
```

**Display settings:**
- X Axis: Alert Type
- Y Axis: Count
- Color: Single color ramp

---

## Panel 4 — Top Source IPs (Attacker IPs)
**Type:** Table

```spl
index=ids_alerts sourcetype=suricata event_type=alert
| stats count as Alerts, dc(alert.signature) as "Unique Attack Types", 
  values(alert.signature) as "Attack Types" by src_ip
| sort -Alerts
| head 10
| rename src_ip as "Source IP"
```

**Display settings:**
- Columns: Source IP, Alerts, Unique Attack Types, Attack Types
- Highlight rows where Alerts > 50

---

## Panel 5 — Alerts by Protocol (Pie Chart)
**Type:** Pie Chart

```spl
index=ids_alerts sourcetype=suricata event_type=alert
| stats count by proto
| rename proto as "Protocol", count as "Count"
```

**Display settings:**
- Slices: One per protocol (TCP, ICMP, UDP)
- Labels: Protocol name + percentage

---

## Panel 6 — Recent Alerts Feed (Live Table)
**Type:** Table

```spl
index=ids_alerts sourcetype=suricata event_type=alert
| table _time, src_ip, dest_ip, dest_port, proto, alert.signature, alert.severity
| sort -_time
| head 20
| rename _time as "Time", src_ip as "Source IP", dest_ip as "Destination IP",
  dest_port as "Dest Port", proto as "Protocol",
  alert.signature as "Alert", alert.severity as "Severity"
```

**Display settings:**
- Auto-refresh: Every 30 seconds
- Severity column: Conditional formatting (1=Red, 2=Orange, 3=Yellow)

---

## Panel 7 — SSH Brute Force Events
**Type:** Table

```spl
index=ids_alerts sourcetype=suricata event_type=alert alert.signature="SSH Brute Force Attempt"
| stats count as Attempts, earliest(_time) as First_Seen, latest(_time) as Last_Seen by src_ip
| eval First_Seen=strftime(First_Seen, "%Y-%m-%d %H:%M:%S")
| eval Last_Seen=strftime(Last_Seen, "%Y-%m-%d %H:%M:%S")
| sort -Attempts
| rename src_ip as "Attacker IP"
```

**Display settings:**
- Columns: Attacker IP, Attempts, First Seen, Last Seen
- Sort: Descending by Attempts

---

## Panel 8 — Severity Breakdown
**Type:** Single Value Row (3 values side by side)

```spl
index=ids_alerts sourcetype=suricata event_type=alert
| eval severity_label=case(alert.severity=1, "High", alert.severity=2, "Medium", alert.severity=3, "Low")
| stats count by severity_label
```

**Display settings:**
- Three single value tiles: High (red), Medium (orange), Low (yellow)

---

## Dashboard Auto-Refresh Setting

Set the dashboard to auto-refresh every **60 seconds** to simulate a live SOC monitoring view.

In Dashboard Editor → Edit → Set time range to `Last 24 hours` and enable auto-refresh at `60s`.

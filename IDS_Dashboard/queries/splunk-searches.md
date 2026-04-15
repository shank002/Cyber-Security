# 🔍 Splunk SPL Search Queries — Alert Investigation

All queries target `index=ids_alerts` with `sourcetype=suricata` (eve.json).

---

## General Alert Queries

### View all IDS alerts in the last 24 hours
```spl
index=ids_alerts sourcetype=suricata event_type=alert
| table _time, src_ip, dest_ip, dest_port, proto, alert.signature, alert.severity
| sort -_time
```

### Count total alerts by rule signature
```spl
index=ids_alerts sourcetype=suricata event_type=alert
| stats count by alert.signature
| sort -count
```

### Alert volume over time (5-minute buckets)
```spl
index=ids_alerts sourcetype=suricata event_type=alert
| timechart span=5m count by alert.signature
```

### Alerts in the last 1 hour only
```spl
index=ids_alerts sourcetype=suricata event_type=alert earliest=-1h
| table _time, src_ip, dest_ip, alert.signature
| sort -_time
```

---

## Source IP Analysis

### Top attacking source IPs by alert count
```spl
index=ids_alerts sourcetype=suricata event_type=alert
| stats count by src_ip
| sort -count
| head 10
```

### All alerts from a specific attacker IP
```spl
index=ids_alerts sourcetype=suricata event_type=alert src_ip="192.168.56.20"
| table _time, src_ip, dest_ip, dest_port, proto, alert.signature
| sort -_time
```

### Source IPs triggering multiple different alert types (potential kill chain)
```spl
index=ids_alerts sourcetype=suricata event_type=alert
| stats dc(alert.signature) as unique_alerts, count by src_ip
| where unique_alerts > 1
| sort -unique_alerts
```

---

## Port Scan Detection Queries

### All port scan alerts
```spl
index=ids_alerts sourcetype=suricata event_type=alert alert.signature="Nmap Port Scan Detected"
| table _time, src_ip, dest_ip, dest_port
| sort -_time
```

### Count of unique destination ports scanned per source IP
```spl
index=ids_alerts sourcetype=suricata event_type=alert alert.signature="Nmap Port Scan Detected"
| stats dc(dest_port) as ports_scanned, count as scan_packets by src_ip
| sort -ports_scanned
```

---

## ICMP Flood Detection Queries

### All ICMP flood alerts
```spl
index=ids_alerts sourcetype=suricata event_type=alert alert.signature="ICMP Ping Flood Detected"
| table _time, src_ip, dest_ip, proto
| sort -_time
```

### ICMP flood alert frequency by source
```spl
index=ids_alerts sourcetype=suricata event_type=alert alert.signature="ICMP Ping Flood Detected"
| stats count by src_ip
| sort -count
```

---

## SSH Brute Force Detection Queries

### All SSH brute force alerts
```spl
index=ids_alerts sourcetype=suricata event_type=alert alert.signature="SSH Brute Force Attempt"
| table _time, src_ip, dest_ip, dest_port
| sort -_time
```

### SSH brute force attempt frequency per source IP
```spl
index=ids_alerts sourcetype=suricata event_type=alert alert.signature="SSH Brute Force Attempt"
| stats count as attempts, earliest(_time) as first_seen, latest(_time) as last_seen by src_ip
| eval first_seen=strftime(first_seen, "%Y-%m-%d %H:%M:%S")
| eval last_seen=strftime(last_seen, "%Y-%m-%d %H:%M:%S")
| sort -attempts
```

---

## Protocol and Severity Analysis

### Alerts broken down by protocol
```spl
index=ids_alerts sourcetype=suricata event_type=alert
| stats count by proto
| sort -count
```

### Alerts by severity level (1=High, 2=Medium, 3=Low)
```spl
index=ids_alerts sourcetype=suricata event_type=alert
| stats count by alert.severity
| eval severity_label=case(alert.severity=1, "High", alert.severity=2, "Medium", alert.severity=3, "Low")
| table severity_label, count
| sort alert.severity
```

---

## Correlation Queries

### Full attack timeline for a specific source IP
```spl
index=ids_alerts sourcetype=suricata event_type=alert src_ip="192.168.56.20"
| table _time, alert.signature, dest_ip, dest_port, proto
| sort _time
```

### Detect potential kill chain — IP that performed scan AND brute force
```spl
index=ids_alerts sourcetype=suricata event_type=alert
  (alert.signature="Nmap Port Scan Detected" OR alert.signature="SSH Brute Force Attempt")
| stats dc(alert.signature) as stage_count, values(alert.signature) as stages by src_ip
| where stage_count >= 2
```

### Forwarder health check — confirm logs are arriving from Ubuntu VM
```spl
index=ids_alerts host=ubuntu-ids-lab
| timechart span=1m count
```

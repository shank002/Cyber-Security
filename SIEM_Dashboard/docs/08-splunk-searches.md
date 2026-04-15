# 08 — Splunk SPL Searches for Anomaly Detection

All searches below can be run in the **Splunk Web UI Search bar** at `http://<server-ip>:8000`.

---

## SSH Log Searches

### 1. All SSH Login Attempts (Last 24 Hours)

```spl
index=auth_logs sourcetype=linux_secure "sshd"
| rex field=_raw "(?P<action>Failed|Accepted) (?P<method>\w+) for (?P<user>\S+) from (?P<src_ip>\S+)"
| table _time, host, action, method, user, src_ip
| sort -_time
```

---

### 2. Failed SSH Login Attempts (Brute-Force Detection)

```spl
index=auth_logs sourcetype=linux_secure "Failed password"
| rex field=_raw "Failed password for (?P<user>\S+) from (?P<src_ip>\S+)"
| stats count as failed_attempts by src_ip, user, host
| where failed_attempts > 5
| sort -failed_attempts
```

---

### 3. Top IPs with Most Failed SSH Logins

```spl
index=auth_logs sourcetype=linux_secure "Failed password"
| rex field=_raw "from (?P<src_ip>\d+\.\d+\.\d+\.\d+)"
| stats count as attempts by src_ip
| sort -attempts
| head 20
```

---

### 4. Successful SSH Logins

```spl
index=auth_logs sourcetype=linux_secure "Accepted password" OR "Accepted publickey"
| rex field=_raw "Accepted (?P<method>\S+) for (?P<user>\S+) from (?P<src_ip>\S+)"
| table _time, host, user, src_ip, method
| sort -_time
```

---

### 5. SSH Login Timeline (Chart Over Time)

```spl
index=auth_logs sourcetype=linux_secure ("Failed password" OR "Accepted password")
| rex field=_raw "(?P<action>Failed|Accepted) password"
| timechart span=5m count by action
```

---

### 6. SSH Brute-Force Burst Detection (>10 Failures in 1 Minute)

```spl
index=auth_logs sourcetype=linux_secure "Failed password"
| rex field=_raw "from (?P<src_ip>\d+\.\d+\.\d+\.\d+)"
| bucket _time span=1m
| stats count as attempts by _time, src_ip
| where attempts > 10
| sort -attempts
```

---

### 7. Custom SSH Autologin JSON Logs

```spl
index=ssh_logs sourcetype=_json
| spath output=status path=status
| spath output=target_host path=target_host
| spath output=username path=username
| spath output=src_host path=source_host
| table _time, src_host, target_host, username, status
| sort -_time
```

---

### 8. SSH Login Failures from Custom JSON Logs

```spl
index=ssh_logs sourcetype=_json status="failure"
| spath output=reason path=reason
| spath output=target_host path=target_host
| stats count by target_host, reason
| sort -count
```

---

## Auth Log Searches

### 9. Sudo Command Usage

```spl
index=auth_logs sourcetype=linux_secure "sudo"
| rex field=_raw "sudo: +(?P<user>\S+) : .+ COMMAND=(?P<command>.+)"
| table _time, host, user, command
| sort -_time
```

---

### 10. Account Lockouts

```spl
index=auth_logs sourcetype=linux_secure "account locked" OR "authentication failure" OR "pam_tally"
| table _time, host, _raw
| sort -_time
```

---

### 11. New User Logins (First Time)

```spl
index=auth_logs sourcetype=linux_secure "session opened"
| rex field=_raw "session opened for user (?P<user>\S+)"
| stats earliest(_time) as first_login by user, host
| eval first_login=strftime(first_login, "%Y-%m-%d %H:%M:%S")
| sort first_login
```

---

### 12. Invalid / Non-Existent User Login Attempts

```spl
index=auth_logs sourcetype=linux_secure "Invalid user"
| rex field=_raw "Invalid user (?P<user>\S+) from (?P<src_ip>\S+)"
| stats count by user, src_ip
| sort -count
```

---

## HTTP / Web Server Log Searches

### 13. Top 20 Source IPs Hitting the Web Server

```spl
index=web_logs sourcetype=access_combined
| stats count as requests by clientip
| sort -requests
| head 20
```

---

### 14. HTTP 4xx and 5xx Error Rate

```spl
index=web_logs sourcetype=access_combined
| eval error_class=if(status>=500, "5xx Server Error",
    if(status>=400, "4xx Client Error", "2xx/3xx OK"))
| timechart span=5m count by error_class
```

---

### 15. DDoS Detection — Spike in Requests Per IP

```spl
index=web_logs sourcetype=access_combined
| bucket _time span=1m
| stats count as req_count by _time, clientip
| where req_count > 100
| sort -req_count
```

---

### 16. Most Requested URLs

```spl
index=web_logs sourcetype=access_combined
| stats count by uri_path
| sort -count
| head 20
```

---

### 17. Slowest Response Times

```spl
index=web_logs sourcetype=access_combined
| stats avg(response_time) as avg_ms, max(response_time) as max_ms by uri_path
| sort -max_ms
| head 10
```

---

## General / Cross-Source Searches

### 18. All Events from a Specific Host

```spl
index=* host="rocky-client-01"
| stats count by sourcetype
```

---

### 19. Event Volume Over Time by Host

```spl
index=*
| timechart span=1h count by host
```

---

### 20. Detect Port Scanning (Many Connections from Single IP)

```spl
index=auth_logs OR index=web_logs
| rex field=_raw "from (?P<src_ip>\d+\.\d+\.\d+\.\d+)"
| stats dc(index) as sources_hit, count as total_events by src_ip
| where sources_hit > 1 AND total_events > 50
| sort -total_events
```

---

## Tips for Writing SPL Queries

- Use `earliest=-24h latest=now` to scope time ranges.
- Use `| head 100` to limit results during development.
- Use `| rex` for extracting fields from raw text.
- Use `| eval` to create computed/conditional fields.
- Use `| timechart` for time-series visualizations in dashboards.
- Pin frequently used searches as **Saved Searches** in Splunk for reuse in dashboards.

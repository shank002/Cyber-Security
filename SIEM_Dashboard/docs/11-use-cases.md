# 11 — Use Cases

## Overview

This section documents the real-world threat scenarios this SIEM setup can detect and respond to.

---

## Use Case 1 — SSH Brute-Force Attack

**Scenario:** An attacker repeatedly attempts to log in via SSH using automated tools (e.g., Hydra, Medusa) trying common username/password combinations.

**How Detected:**
- Splunk monitors `/var/log/auth.log` (Debian/Ubuntu) and `/var/log/secure` (Rocky Linux)
- The SSH brute-force alert fires when >10 failed logins originate from the same IP within 5 minutes
- The dashboard shows a spike in "Failed password" events

**SPL Query Used:**
```spl
index=auth_logs sourcetype=linux_secure "Failed password"
| rex field=_raw "from (?P<src_ip>\d+\.\d+\.\d+\.\d+)"
| bucket _time span=5m
| stats count as attempts by _time, src_ip
| where attempts > 10
```

**Response Actions:**
- Alert email sent immediately
- Analyst identifies the attacking IP
- IP blocked via `ufw deny from <ip>` or added to `/etc/hosts.deny`

---

## Use Case 2 — DDoS Attack on Web Server

**Scenario:** A bot or attacker floods the web server with HTTP requests, causing slow responses or downtime.

**How Detected:**
- HTTP access logs from Apache/Nginx are forwarded to Splunk
- The DDoS alert fires when a single IP exceeds 200 requests per minute
- The dashboard shows an unusual spike in the request volume timechart

**SPL Query Used:**
```spl
index=web_logs sourcetype=access_combined
| bucket _time span=1m
| stats count as req_count by _time, clientip
| where req_count > 200
```

**Response Actions:**
- Alert email sent immediately
- Block IP at the web server level:
  ```bash
  sudo ufw deny from <attacker-ip>
  # or in Apache:
  echo "Deny from <attacker-ip>" >> /etc/apache2/.htaccess
  ```

---

## Use Case 3 — Unauthorized SSH Login from Unknown IP

**Scenario:** A legitimate-looking login succeeds, but from an IP address that has never connected before — potentially indicating a compromised credential.

**How Detected:**
- Splunk tracks all successful SSH logins
- New/first-time IPs are flagged for review

**SPL Query Used:**
```spl
index=auth_logs sourcetype=linux_secure "Accepted"
| rex field=_raw "from (?P<src_ip>\d+\.\d+\.\d+\.\d+)"
| stats earliest(_time) as first_seen, count by src_ip
| where count = 1
```

---

## Use Case 4 — Privilege Escalation via Sudo

**Scenario:** A non-privileged user attempts to run sudo commands they are not authorized for, potentially indicating an insider threat or compromised account.

**How Detected:**
- Auth logs capture `sudo: authentication failure` events
- Multiple failures from the same user are flagged

**SPL Query Used:**
```spl
index=auth_logs sourcetype=linux_secure "sudo" "authentication failure"
| rex field=_raw "sudo: +(?P<user>\S+)"
| stats count as failures by user, host
| where failures > 3
```

---

## Use Case 5 — SSH Login After Business Hours

**Scenario:** A successful SSH login occurs outside of normal business hours (e.g., 2 AM), which may indicate unauthorized access.

**How Detected:**
```spl
index=auth_logs sourcetype=linux_secure "Accepted password"
| eval hour=strftime(_time, "%H")
| where hour < 8 OR hour > 18
| rex field=_raw "for (?P<user>\S+) from (?P<src_ip>\S+)"
| table _time, host, user, src_ip, hour
```

---

## Use Case 6 — High Volume of HTTP 404 Errors (Scanner Detection)

**Scenario:** An attacker or automated scanner is probing the web server for vulnerable paths (e.g., `/admin`, `/wp-login.php`, `/etc/passwd`).

**How Detected:**
```spl
index=web_logs sourcetype=access_combined status=404
| stats count by clientip, uri_path
| sort -count
| head 20
```

---

## Summary Table

| Use Case | Log Source | Alert? | SPL Technique |
|---|---|---|---|
| SSH Brute-Force | auth.log / secure | ✅ Yes | `stats count`, `bucket` |
| DDoS Web Attack | apache/nginx access | ✅ Yes | `bucket`, `stats count` |
| Unknown IP Login | auth.log / secure | ✅ Yes | `stats earliest` |
| Sudo Escalation | auth.log / secure | ✅ Yes | `stats count` |
| After-Hours Login | auth.log / secure | Optional | `eval hour` |
| 404 Scan Detection | web access log | Optional | `stats count by uri_path` |

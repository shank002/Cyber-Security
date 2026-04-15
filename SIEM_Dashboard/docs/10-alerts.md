# 10 — Alerts: SSH Brute-Force & DDoS Detection

## Overview

Splunk Alerts continuously run saved SPL searches on a schedule and trigger actions when conditions are met. Two critical alerts are configured in this project:

1. **SSH Brute-Force Alert** — fires when a single IP has >10 failed SSH logins within 5 minutes
2. **DDoS Alert** — fires when a single IP sends >200 HTTP requests within 1 minute

---

## Alert 1 — SSH Brute-Force Detection

### SPL Search Query

```spl
index=auth_logs sourcetype=linux_secure "Failed password"
| rex field=_raw "from (?P<src_ip>\d+\.\d+\.\d+\.\d+)"
| bucket _time span=5m
| stats count as failed_attempts by _time, src_ip, host
| where failed_attempts > 10
```

### Configuration Steps

1. Run the above search in Splunk Web
2. Click **Save As → Alert**
3. Fill in the alert settings:

| Field | Value |
|---|---|
| **Title** | SSH Brute-Force Detected |
| **Description** | Fires when >10 SSH failures occur from a single IP within 5 minutes |
| **Alert Type** | Scheduled |
| **Schedule** | Run every 5 minutes (`*/5 * * * *`) |
| **Trigger Condition** | Number of Results > 0 |
| **Trigger** | Once per result (to alert per IP) |

4. Add **Actions**:
   - ✅ Add to Triggered Alerts (visible in Splunk Activity)
   - ✅ Send Email (configure SMTP settings in Splunk)
   - ✅ Run a Script (optional: call webhook / Slack notification)

---

### savedsearches.conf (Manual Configuration)

File: `/opt/splunk/etc/apps/search/local/savedsearches.conf`

```ini
[SSH Brute-Force Detected]
search = index=auth_logs sourcetype=linux_secure "Failed password" \
  | rex field=_raw "from (?P<src_ip>\d+\.\d+\.\d+\.\d+)" \
  | bucket _time span=5m \
  | stats count as failed_attempts by _time, src_ip, host \
  | where failed_attempts > 10
alert.condition = search
alert.suppress = 0
alert.track = 1
alert.severity = 3
counttype = number of events
quantity = 0
relation = greater than
schedule = */5 * * * *
enableSched = 1
cron_schedule = */5 * * * *
dispatch.earliest_time = -5m
dispatch.latest_time = now
alert.email.to = your-email@example.com
alert.email.subject = [SPLUNK ALERT] SSH Brute-Force Detected
alert.actions = email
action.email = 1
action.email.sendresults = 1
action.email.format = table
```

---

## Alert 2 — DDoS Attack on Web Server

### SPL Search Query

```spl
index=web_logs sourcetype=access_combined
| bucket _time span=1m
| stats count as req_count by _time, clientip, host
| where req_count > 200
| sort -req_count
```

### Configuration Steps

1. Run the above search in Splunk Web
2. Click **Save As → Alert**
3. Fill in the alert settings:

| Field | Value |
|---|---|
| **Title** | DDoS Attack Detected — High Request Volume |
| **Description** | Fires when a single IP exceeds 200 requests/minute to the web server |
| **Alert Type** | Scheduled |
| **Schedule** | Run every 1 minute (`* * * * *`) |
| **Trigger Condition** | Number of Results > 0 |
| **Severity** | Critical |

---

### savedsearches.conf (Manual Configuration)

```ini
[DDoS Attack Detected - High Request Volume]
search = index=web_logs sourcetype=access_combined \
  | bucket _time span=1m \
  | stats count as req_count by _time, clientip, host \
  | where req_count > 200 \
  | sort -req_count
alert.condition = search
alert.suppress = 0
alert.track = 1
alert.severity = 5
counttype = number of events
quantity = 0
relation = greater than
schedule = * * * * *
enableSched = 1
cron_schedule = * * * * *
dispatch.earliest_time = -1m
dispatch.latest_time = now
alert.email.to = your-email@example.com
alert.email.subject = [CRITICAL] DDoS Attack Detected on Web Server
alert.actions = email
action.email = 1
action.email.sendresults = 1
action.email.format = table
```

---

## Alert 3 — SSH Login from Unknown IP (Bonus)

Detect successful logins from IPs that have never logged in before:

```spl
index=auth_logs sourcetype=linux_secure "Accepted password" OR "Accepted publickey"
| rex field=_raw "from (?P<src_ip>\d+\.\d+\.\d+\.\d+)"
| stats earliest(_time) as first_seen, count by src_ip
| where count = 1
| eval first_seen=strftime(first_seen, "%Y-%m-%d %H:%M:%S")
| table src_ip, first_seen
```

---

## Alert 4 — Multiple Failed Sudo Attempts (Privilege Escalation)

```spl
index=auth_logs sourcetype=linux_secure "sudo" "authentication failure"
| rex field=_raw "sudo: +(?P<user>\S+)"
| bucket _time span=10m
| stats count as sudo_failures by _time, user, host
| where sudo_failures > 3
```

---

## Viewing Triggered Alerts

1. Go to **Activity → Triggered Alerts** in Splunk Web
2. Or search: `index=_audit action=alert`

---

## Alert Suppression (Avoid Alert Fatigue)

To prevent repeated alerts for the same IP during an ongoing attack:

In the Alert settings, enable **Throttle** and set:
- Suppress results containing field: `src_ip`
- Suppress triggering for: `60 minutes`

This ensures you get one alert per attacking IP per hour, not one per search cycle.

---

## Summary

| Alert | Trigger | Schedule | Severity |
|---|---|---|---|
| SSH Brute-Force | >10 failed logins from 1 IP in 5 min | Every 5 min | High |
| DDoS Web Server | >200 requests from 1 IP in 1 min | Every 1 min | Critical |
| Unknown IP Login | Successful login from new IP | Every 15 min | Medium |
| Sudo Escalation | >3 sudo failures in 10 min | Every 10 min | High |

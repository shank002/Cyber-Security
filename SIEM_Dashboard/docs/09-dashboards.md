# 09 — Splunk Dashboard Setup

## Overview

Two primary dashboards are configured in this project:
1. **SSH Monitoring Dashboard** — tracks login attempts, failures, and source IPs
2. **Auth Logs Dashboard** — tracks sudo usage, account events, and authentication activity

---

## Creating a Dashboard — Step by Step

1. Log in to Splunk Web at `http://<server-ip>:8000`
2. Navigate to **Search & Reporting** → **Dashboards**
3. Click **Create New Dashboard**
4. Enter a title and choose **Classic Dashboards** (or Dashboard Studio)
5. Add panels using the searches below

---

## SSH Monitoring Dashboard

### Panel 1: SSH Login Attempts Over Time

```spl
index=auth_logs sourcetype=linux_secure ("Failed password" OR "Accepted password")
| rex field=_raw "(?P<action>Failed|Accepted) password"
| timechart span=10m count by action
```
*Visualization: Line Chart*

---

### Panel 2: Top Attacking IPs (Failed Logins)

```spl
index=auth_logs sourcetype=linux_secure "Failed password"
| rex field=_raw "from (?P<src_ip>\d+\.\d+\.\d+\.\d+)"
| stats count as failed_logins by src_ip
| sort -failed_logins
| head 10
```
*Visualization: Bar Chart*

---

### Panel 3: Successful vs Failed Login Count (Single Value)

```spl
index=auth_logs sourcetype=linux_secure ("Failed password" OR "Accepted password")
| rex field=_raw "(?P<action>Failed|Accepted) password"
| stats count by action
```
*Visualization: Single Value / Radial Gauge*

---

### Panel 4: Login Activity Table

```spl
index=auth_logs sourcetype=linux_secure ("Failed password" OR "Accepted password")
| rex field=_raw "(?P<action>Failed|Accepted) (?P<method>\w+) for (?P<user>\S+) from (?P<src_ip>\S+)"
| table _time, host, action, user, src_ip
| sort -_time
| head 50
```
*Visualization: Table*

---

### Panel 5: Custom SSH Autologin Events

```spl
index=ssh_logs sourcetype=_json
| spath output=status path=status
| spath output=target_host path=target_host
| spath output=username path=username
| timechart span=1h count by status
```
*Visualization: Column Chart*

---

## Auth Logs Dashboard

### Panel 1: Sudo Commands by User

```spl
index=auth_logs sourcetype=linux_secure "sudo"
| rex field=_raw "sudo: +(?P<user>\S+) : .+COMMAND=(?P<cmd>.+)"
| stats count by user, cmd
| sort -count
```
*Visualization: Table*

---

### Panel 2: Authentication Failures by Host

```spl
index=auth_logs sourcetype=linux_secure "authentication failure"
| stats count as failures by host
| sort -failures
```
*Visualization: Bar Chart*

---

### Panel 3: Invalid User Attempts

```spl
index=auth_logs sourcetype=linux_secure "Invalid user"
| rex field=_raw "Invalid user (?P<user>\S+) from (?P<ip>\S+)"
| stats count by user, ip
| sort -count
| head 20
```
*Visualization: Table*

---

### Panel 4: Auth Events Timeline by Host

```spl
index=auth_logs
| timechart span=1h count by host
```
*Visualization: Area Chart*

---

## HTTP / Web Dashboard

### Panel 1: Request Volume Per Minute

```spl
index=web_logs sourcetype=access_combined
| timechart span=1m count
```
*Visualization: Line Chart*

---

### Panel 2: HTTP Status Code Distribution

```spl
index=web_logs sourcetype=access_combined
| stats count by status
| sort -count
```
*Visualization: Pie Chart*

---

### Panel 3: Top Client IPs

```spl
index=web_logs sourcetype=access_combined
| stats count by clientip
| sort -count
| head 10
```
*Visualization: Bar Chart*

---

### Panel 4: Error Spike Detection

```spl
index=web_logs sourcetype=access_combined status>=400
| timechart span=5m count by status
```
*Visualization: Column Chart*

---

## Dashboard XML Export

To share or back up your dashboard, go to:
**Dashboard → Edit → Source (XML)** → Copy the XML

Store the XML in the `dashboards/` folder of this project for version control.

---

## Tips

- Set the **time range picker** to "Last 24 hours" or "Real-time 5 minutes" for live monitoring.
- Use **input tokens** (dropdown filters) to filter by `host` across all panels.
- Schedule a **PDF report** from any dashboard: Dashboard → Schedule PDF Delivery.

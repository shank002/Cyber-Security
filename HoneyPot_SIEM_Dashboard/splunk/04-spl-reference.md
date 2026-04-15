# Splunk · SPL Query Reference

A complete reference of all useful SPL queries for the honeypot project. Save these as Splunk Saved Searches for reuse in dashboards and reports.

---

## Connection & Session Queries

### Total connections in time range
```
index=cowrie eventid="cowrie.session.connect"
| stats count AS total_connections
```

### Unique attacking IPs
```
index=cowrie
| stats dc(src_ip) AS unique_ips
```

### Sessions over time (hourly)
```
index=cowrie eventid="cowrie.session.connect"
| timechart span=1h count AS connections
```

### Longest sessions
```
index=cowrie eventid="cowrie.session.closed"
| where isnotnull(duration)
| stats max(duration) AS max_sec, avg(duration) AS avg_sec by src_ip
| eval max_min = round(max_sec/60,2)
| sort -max_sec
| head 20
```

---

## Login & Credential Queries

### Login failure count by IP
```
index=cowrie eventid="cowrie.login.failed"
| stats count AS attempts by src_ip
| sort -attempts
| head 20
```

### Top username/password combos
```
index=cowrie eventid="cowrie.login.failed"
| stats count by username, password
| sort -count
| head 30
```

### Most targeted usernames
```
index=cowrie eventid="cowrie.login.failed"
| stats count by username
| sort -count
| head 20
```

### Most tried passwords
```
index=cowrie eventid="cowrie.login.failed"
| stats count by password
| sort -count
| head 20
```

### All successful logins
```
index=cowrie eventid="cowrie.login.success"
| table _time, src_ip, username, password, session
| sort -_time
```

### Success rate by IP (attackers who eventually got in)
```
index=cowrie (eventid="cowrie.login.failed" OR eventid="cowrie.login.success")
| stats count(eval(eventid="cowrie.login.failed")) AS failures,
        count(eval(eventid="cowrie.login.success")) AS successes
  by src_ip
| where successes > 0
| eval success_rate = round((successes/(failures+successes))*100,1)
| sort -successes
```

---

## Command Execution Queries

### All commands run
```
index=cowrie eventid="cowrie.command.input"
| stats count by input
| sort -count
| head 50
```

### Commands per session (most active sessions)
```
index=cowrie eventid="cowrie.command.input"
| stats count AS commands, values(input) AS cmd_list by session
| sort -commands
| head 20
```

### Download attempts (wget / curl)
```
index=cowrie eventid="cowrie.command.input"
| where like(input, "%wget%") OR like(input, "%curl%")
| table _time, src_ip, session, input
| sort -_time
```

### Reconnaissance commands
```
index=cowrie eventid="cowrie.command.input"
| where like(input, "%uname%") OR like(input, "%whoami%") OR
         like(input, "%id%") OR like(input, "%cat /etc/passwd%") OR
         like(input, "%ifconfig%") OR like(input, "%ip addr%")
| stats count by input
| sort -count
```

---

## GeoIP & Geographic Queries

### Attacks by country
```
index=cowrie eventid="cowrie.login.failed"
| iplocation src_ip
| stats count by Country
| sort -count
| head 20
```

### Attacks by country with city breakdown
```
index=cowrie eventid="cowrie.login.failed"
| iplocation src_ip
| stats count by Country, City
| sort -count
| head 30
```

### World map data
```
index=cowrie eventid="cowrie.login.failed"
| stats count by src_ip
| iplocation src_ip
| geostats latfield=lat longfield=lon count
```

### New countries seen today vs yesterday
```
index=cowrie eventid="cowrie.login.failed" earliest=-1d@d latest=now
| iplocation src_ip
| stats count by Country
| appendcols
    [search index=cowrie eventid="cowrie.login.failed" earliest=-2d@d latest=-1d@d
     | iplocation src_ip
     | stats count AS yesterday_count by Country]
| eval change = if(isnull(yesterday_count), "NEW", tostring(count - yesterday_count))
| table Country, count, yesterday_count, change
| sort -count
```

---

## File Transfer Queries

### All file download attempts
```
index=cowrie eventid="cowrie.session.file_download"
| table _time, src_ip, session, url, outfile
| sort -_time
```

### Most-targeted download URLs
```
index=cowrie eventid="cowrie.session.file_download"
| stats count by url
| sort -count
```

### File uploads (SCP/SFTP)
```
index=cowrie eventid="cowrie.session.file_upload"
| table _time, src_ip, session, filename
| sort -_time
```

---

## Time-Based Analysis Queries

### Attack volume by hour of day (all time)
```
index=cowrie eventid="cowrie.login.failed"
| eval hour = strftime(_time, "%H")
| stats count by hour
| sort hour
```

### Attack volume by day of week
```
index=cowrie eventid="cowrie.login.failed"
| eval dow = strftime(_time, "%A")
| stats count by dow
```

### Daily totals
```
index=cowrie eventid="cowrie.login.failed"
| timechart span=1d count
```

### Peak attack hours (busiest 5)
```
index=cowrie eventid="cowrie.login.failed"
| eval hour = strftime(_time, "%H:00")
| stats count by hour
| sort -count
| head 5
```

---

## Threat Hunting Queries

### IPs that appear in multiple event types (persistent attackers)
```
index=cowrie
| stats dc(eventid) AS event_types, count AS total_events by src_ip
| where event_types >= 3
| sort -total_events
| head 20
```

### Sessions with both login success and command execution
```
index=cowrie (eventid="cowrie.login.success" OR eventid="cowrie.command.input")
| stats count by session, eventid
| xyseries session, eventid, count
| where isnotnull('cowrie.login.success') AND isnotnull('cowrie.command.input')
| join type=left session
    [search index=cowrie eventid="cowrie.login.success" | table session, src_ip]
| table session, src_ip, "cowrie.command.input"
| rename "cowrie.command.input" AS commands_run
| sort -commands_run
```

### IPs with only 1 attempt (likely scanners, not targeted attacks)
```
index=cowrie eventid="cowrie.login.failed"
| stats count by src_ip
| where count = 1
| stats count AS single_attempt_ips
```

### Detect credential spraying (many usernames, same password)
```
index=cowrie eventid="cowrie.login.failed"
| stats dc(username) AS unique_usernames, count by src_ip, password
| where unique_usernames > 10
| sort -unique_usernames
| head 20
```

---

## Reporting Queries

### Daily summary for report
```
index=cowrie earliest=-1d@d latest=@d
| stats count(eval(eventid="cowrie.session.connect")) AS connections,
        count(eval(eventid="cowrie.login.failed")) AS login_failures,
        count(eval(eventid="cowrie.login.success")) AS successful_logins,
        count(eval(eventid="cowrie.command.input")) AS commands_run,
        dc(src_ip) AS unique_ips
| transpose
| rename column AS "Metric", "row 1" AS "Count (last 24h)"
```

### Top 10 everything (executive summary)
```
index=cowrie
| stats count by eventid
| sort -count
```

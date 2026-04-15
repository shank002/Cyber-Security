# Splunk · Alerts & Rules

## Overview

Four alert rules are configured to cover the most critical honeypot events. All alerts use Splunk's scheduled search mechanism and can deliver notifications via email or webhook (Slack, PagerDuty, etc.).

**How to create an alert in Splunk:**
1. Run the SPL query in Search & Reporting
2. Click **Save As → Alert**
3. Configure the schedule, trigger condition, and action
4. Save

---

## Alert 1 — Brute-Force Spike

**Purpose:** Detect when a single IP is making an unusually high number of login attempts in a short window. Indicates an active automated scanner or targeted attack.

**Severity:** Medium

**Schedule:** Every 5 minutes

**SPL:**
```
index=cowrie eventid="cowrie.login.failed" earliest=-5m
| stats count AS attempts by src_ip
| where attempts > 50
| iplocation src_ip
| table src_ip, Country, attempts
| sort -attempts
```

**Trigger condition:**
- Trigger when: Number of Results is greater than 0

**Alert settings in Splunk:**
| Setting | Value |
|---|---|
| Alert name | `Honeypot - Brute Force Spike` |
| Schedule | Cron: `*/5 * * * *` (every 5 minutes) |
| Time range | Last 5 minutes |
| Trigger | Number of Results > 0 |
| Throttle | 15 minutes (suppress duplicate alerts) |

**Notification:** Email or webhook with results table showing IP, country, and attempt count.

---

## Alert 2 — Successful Login

**Purpose:** A `cowrie.login.success` event means an attacker has been handed a shell inside Cowrie. This is the highest-priority event — it means an attacker is actively exploring and may attempt payload delivery.

**Severity:** High

**Schedule:** Every 1 minute

**SPL:**
```
index=cowrie eventid="cowrie.login.success" earliest=-1m
| iplocation src_ip
| table _time, src_ip, Country, username, password, session
```

**Trigger condition:**
- Trigger when: Number of Results is greater than 0

**Alert settings in Splunk:**
| Setting | Value |
|---|---|
| Alert name | `Honeypot - Successful Login` |
| Schedule | Cron: `* * * * *` (every minute) |
| Time range | Last 1 minute |
| Trigger | Number of Results > 0 |
| Throttle | 5 minutes per session |
| Priority | High |

**Notification:** Immediate email with attacker IP, country, and credentials used.

---

## Alert 3 — New Country Source

**Purpose:** Detect when login attempts originate from a country not seen in the previous 7 days. This can indicate a new scanning campaign or botnet cluster coming online.

**Severity:** Low / Informational

**Schedule:** Every 6 hours

**SPL:**
```
index=cowrie eventid="cowrie.login.failed"
| iplocation src_ip
| stats earliest(_time) AS first_seen by Country
| eval days_ago = round((now() - first_seen) / 86400, 1)
| where days_ago < 0.25
| eval first_seen_readable = strftime(first_seen, "%Y-%m-%d %H:%M:%S")
| table Country, first_seen_readable, days_ago
```

**Alternative approach (compare 7-day window vs. prior 7 days):**
```
index=cowrie eventid="cowrie.login.failed" earliest=-1d@d
| iplocation src_ip
| stats count by Country
| appendcols
    [search index=cowrie eventid="cowrie.login.failed" earliest=-8d@d latest=-1d@d
     | iplocation src_ip
     | stats count AS prior_count by Country]
| where isnull(prior_count)
| table Country, count
```

**Alert settings in Splunk:**
| Setting | Value |
|---|---|
| Alert name | `Honeypot - New Country Source` |
| Schedule | Cron: `0 */6 * * *` (every 6 hours) |
| Time range | Last 1 day |
| Trigger | Number of Results > 0 |
| Throttle | 24 hours per country |

---

## Alert 4 — Command Execution Burst

**Purpose:** Detect sessions where an attacker ran more than 10 commands. A high command count indicates a human-operated session or an automated post-exploitation script executing a playbook. These sessions contain the most valuable intelligence.

**Severity:** High

**Schedule:** Every 5 minutes

**SPL:**
```
index=cowrie eventid="cowrie.command.input" earliest=-5m
| stats count AS cmd_count, values(input) AS commands by session
| where cmd_count > 10
| eval commands = mvjoin(commands, " | ")
| join type=left session
    [search index=cowrie eventid="cowrie.login.success"
     | table session, src_ip, username]
| iplocation src_ip
| table session, src_ip, Country, username, cmd_count, commands
```

**Alert settings in Splunk:**
| Setting | Value |
|---|---|
| Alert name | `Honeypot - Command Burst` |
| Schedule | Cron: `*/5 * * * *` (every 5 minutes) |
| Time range | Last 5 minutes |
| Trigger | Number of Results > 0 |
| Throttle | 30 minutes per session |
| Priority | High |

**Notification:** Email with session details, IP, country, and list of commands run.

---

## Alert Summary Table

| Alert | Schedule | Threshold | Priority |
|---|---|---|---|
| Brute-Force Spike | Every 5 min | >50 attempts from 1 IP in 5 min | Medium |
| Successful Login | Every 1 min | Any `cowrie.login.success` event | High |
| New Country Source | Every 6 hours | Country not seen in last 7 days | Low |
| Command Execution Burst | Every 5 min | >10 commands in a single session | High |

---

## Configuring Email Notifications

Before alerts can send email, configure Splunk's mail server:

1. Go to **Settings → Server Settings → Email Settings**
2. Enter your SMTP server details:
   - Mail host: `smtp.yourprovider.com`
   - Port: `587`
   - Security: `TLS`
   - Username / password for your SMTP account
3. Send a test email to verify

Then when creating an alert, under **Add Actions** → **Send email**:
- Set recipients
- Use token `$result.src_ip$` in the subject for dynamic attacker IP inclusion
- Example subject: `[HONEYPOT ALERT] Brute force from $result.src_ip$ ($result.Country$)`

---

## Configuring Webhook Notifications (Slack)

1. Create a Slack Incoming Webhook URL in your Slack workspace
2. In Splunk: **Settings → Alert actions → Webhook**
3. When creating an alert, add action **Webhook**
4. URL: your Slack webhook URL
5. Payload example:
```json
{
  "text": "Honeypot Alert: Brute-force spike detected from $result.src_ip$ ($result.Country$) — $result.attempts$ attempts in 5 minutes"
}
```

---

## Testing Alerts

To test an alert without waiting for the schedule, run the SPL query manually in Search and verify it returns results. Then:

1. Open the saved alert: **Settings → Searches, Reports, and Alerts**
2. Click **Run** next to the alert name
3. Verify the notification is delivered

For brute-force testing specifically, you can generate test events with:

```bash
# From another machine — triggers login.failed events
for i in $(seq 1 60); do
  ssh -o StrictHostKeyChecking=no -o ConnectTimeout=3 \
    root@HONEYPOT_IP -p 22 2>/dev/null || true
done
```

This generates 60 failed login attempts, which should trigger Alert 1.

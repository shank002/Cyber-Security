# Splunk · Dashboard Setup

## Dashboard Overview

The honeypot dashboard gives a live operational picture of all attack activity. It contains 6 panels, auto-refreshes every 60 seconds, and covers the full time range of your choosing (default: last 24 hours).

**Dashboard name:** `Honeypot Attack Monitor`
**Index:** `cowrie`
**Refresh interval:** 60 seconds

---

## Creating the Dashboard

In Splunk Web:

1. Go to **Search & Reporting → Dashboards**
2. Click **Create New Dashboard**
3. Name: `Honeypot Attack Monitor`
4. Choose **Classic Dashboard** (for full panel control)
5. Save, then add panels as described below

---

## Panel 1 — Attack Volume Over Time

**Purpose:** Shows events per hour split by type. Reveals attack waves and scanning campaigns.

**Visualization:** Line chart / Column chart

**SPL:**
```
index=cowrie
| timechart span=1h count by eventid
| rename cowrie.login.failed AS "Login failures",
         cowrie.login.success AS "Successful logins",
         cowrie.command.input AS "Commands run",
         cowrie.session.connect AS "Connections"
```

**Panel settings:**
- Time range: Last 24 hours
- Chart type: Line
- Stack mode: Stacked

---

## Panel 2 — Attacker Origin World Map

**Purpose:** Geographic heatmap of where attacks originate.

**Visualization:** Cluster Map

**SPL:**
```
index=cowrie eventid="cowrie.login.failed" OR eventid="cowrie.session.connect"
| stats count by src_ip
| iplocation src_ip
| geostats latfield=lat longfield=lon count
```

**Panel settings:**
- Visualization: Maps → Cluster Map
- Time range: Last 24 hours

> Note: Requires `iplocation` results to have `lat` and `lon` fields. If the map is blank, verify `iplocation` is resolving IPs correctly with: `| eval test=iplocation(src_ip)` on a sample event.

---

## Panel 3 — Top Attacking IPs

**Purpose:** Ranks IP addresses by number of attempts. Identifies persistent scanners.

**Visualization:** Bar chart or Table

**SPL:**
```
index=cowrie eventid="cowrie.login.failed"
| stats count AS attempts by src_ip
| iplocation src_ip
| table src_ip, Country, City, attempts
| sort -attempts
| head 20
```

**Panel settings:**
- Visualization: Table
- Time range: Last 24 hours

---

## Panel 4 — Most-Tried Credentials

**Purpose:** Surfaces the most common username/password combinations attempted.

**Visualization:** Table

**SPL:**
```
index=cowrie eventid="cowrie.login.failed"
| stats count AS attempts by username, password
| sort -attempts
| head 25
| rename username AS "Username", password AS "Password", attempts AS "Attempts"
```

**Panel settings:**
- Visualization: Table
- Time range: Last 24 hours

---

## Panel 5 — Commands Run by Attackers

**Purpose:** Shows what attackers do once inside the fake shell. Reveals toolkits and intentions.

**Visualization:** Table

**SPL:**
```
index=cowrie eventid="cowrie.command.input"
| stats count AS frequency by input
| sort -frequency
| head 30
| rename input AS "Command", frequency AS "Times run"
```

**Panel settings:**
- Visualization: Table
- Time range: Last 24 hours

---

## Panel 6 — Active Sessions (Live Count)

**Purpose:** Single-value panel showing how many attacker sessions are currently open.

**Visualization:** Single Value

**SPL:**
```
index=cowrie
| stats dc(session) AS open_sessions by eventid
| where eventid="cowrie.session.connect"
| stats sum(open_sessions) AS "Active Sessions"
```

A simpler approximation using session open/close events:

```
index=cowrie earliest=-5m
| stats count(eval(eventid="cowrie.session.connect")) AS opened,
        count(eval(eventid="cowrie.session.closed")) AS closed
| eval active = opened - closed
| table active
```

**Panel settings:**
- Visualization: Single Value
- Time range: Last 5 minutes
- Refresh: 30 seconds

---

## Adding All Panels via Dashboard XML

You can import the complete dashboard by pasting this XML in **Edit → Source**:

```xml
<dashboard refresh="60">
  <label>Honeypot Attack Monitor</label>
  <description>Live SSH honeypot attack dashboard — Cowrie + Splunk</description>

  <row>
    <panel>
      <title>Attack volume over time</title>
      <chart>
        <search>
          <query>index=cowrie | timechart span=1h count by eventid</query>
          <earliest>-24h@h</earliest>
          <latest>now</latest>
        </search>
        <option name="charting.chart">line</option>
        <option name="charting.chart.stackMode">stacked</option>
      </chart>
    </panel>
    <panel>
      <title>Active sessions (last 5 min)</title>
      <single>
        <search>
          <query>index=cowrie earliest=-5m | stats dc(session) AS "Active Sessions"</query>
          <earliest>-5m</earliest>
          <latest>now</latest>
        </search>
      </single>
    </panel>
  </row>

  <row>
    <panel>
      <title>Attacker origin map</title>
      <map>
        <search>
          <query>index=cowrie eventid="cowrie.login.failed" | stats count by src_ip | iplocation src_ip | geostats latfield=lat longfield=lon count</query>
          <earliest>-24h@h</earliest>
          <latest>now</latest>
        </search>
        <option name="mapping.type">marker</option>
        <option name="mapping.markerLayer.markerOpacity">0.8</option>
      </map>
    </panel>
  </row>

  <row>
    <panel>
      <title>Top attacking IPs</title>
      <table>
        <search>
          <query>index=cowrie eventid="cowrie.login.failed" | stats count AS attempts by src_ip | iplocation src_ip | table src_ip, Country, attempts | sort -attempts | head 20</query>
          <earliest>-24h@h</earliest>
          <latest>now</latest>
        </search>
      </table>
    </panel>
    <panel>
      <title>Most-tried credentials</title>
      <table>
        <search>
          <query>index=cowrie eventid="cowrie.login.failed" | stats count AS attempts by username, password | sort -attempts | head 20</query>
          <earliest>-24h@h</earliest>
          <latest>now</latest>
        </search>
      </table>
    </panel>
  </row>

  <row>
    <panel>
      <title>Commands run by attackers</title>
      <table>
        <search>
          <query>index=cowrie eventid="cowrie.command.input" | stats count AS frequency by input | sort -frequency | head 30</query>
          <earliest>-24h@h</earliest>
          <latest>now</latest>
        </search>
      </table>
    </panel>
  </row>
</dashboard>
```

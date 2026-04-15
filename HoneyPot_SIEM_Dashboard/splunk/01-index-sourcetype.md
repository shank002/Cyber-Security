# Splunk · Index & Sourcetype Configuration

## Overview

Before dashboard panels and alerts work correctly, Splunk needs to know how to parse Cowrie's JSON events. This is done through two config files on the Splunk server:

- `props.conf` — tells Splunk how to parse the `cowrie_json` sourcetype
- `transforms.conf` — (optional) field aliases and extractions

---

## Step 1 — Create the `cowrie` Index

If you haven't already done this during UF setup:

**Via Splunk Web:**
1. Settings → Indexes → New Index
2. Index Name: `cowrie`
3. Max raw data size: `5000` MB (5 GB)
4. Frozen data retention: `90` days
5. Save

**Via CLI:**

```bash
$SPLUNK_HOME/bin/splunk add index cowrie -maxTotalDataSizeMB 5000
```

---

## Step 2 — Configure Parsing with `props.conf`

Edit (or create) on your **Splunk server**:

```
$SPLUNK_HOME/etc/system/local/props.conf
```

Add the following stanza:

```ini
[cowrie_json]
# Parse the entire line as JSON — all fields become indexed key-value pairs
KV_MODE = json

# Each line is a complete JSON object — do not merge lines
SHOULD_LINEMERGE = false

# Tell Splunk where to find the timestamp in the JSON
TIME_PREFIX = "timestamp":"
TIME_FORMAT = %Y-%m-%dT%H:%M:%S.%f
MAX_TIMESTAMP_LOOKAHEAD = 32

# Ensure Splunk doesn't truncate long events (long command outputs)
TRUNCATE = 10000

# Character encoding
CHARSET = UTF-8
```

Restart Splunk after saving:

```bash
sudo $SPLUNK_HOME/bin/splunk restart
```

---

## Step 3 — Verify Parsing

In Splunk Web → Search & Reporting, run:

```
index=cowrie | head 5
```

Click on any event and expand it. You should see individual parsed fields:

| Field | Example Value |
|---|---|
| `eventid` | `cowrie.login.failed` |
| `src_ip` | `185.220.101.47` |
| `username` | `root` |
| `password` | `admin123` |
| `session` | `a4f2b1c3` |
| `timestamp` | `2024-11-14T03:22:11.482Z` |

If fields are not parsed (you only see the raw JSON string), check:
- `sourcetype` in inputs.conf matches the stanza name in props.conf exactly: `cowrie_json`
- Splunk has been restarted after props.conf changes

---

## Step 4 — Optional Field Aliases

Some Cowrie fields use names that differ from Splunk's Common Information Model (CIM). Add these aliases in `props.conf` to improve CIM compatibility:

```ini
[cowrie_json]
# ... (existing settings above) ...

# CIM field alignment
FIELDALIAS-src = src_ip AS src
FIELDALIAS-dest = dst_ip AS dest
FIELDALIAS-user = username AS user
FIELDALIAS-action_login = eventid AS action

# Extract session duration when available
EVAL-duration_seconds = if(isnotnull(duration), duration, null())
```

---

## Step 5 — Optional: `transforms.conf` for Event Type Lookup

Create a lookup table that maps Cowrie event IDs to human-readable descriptions:

**Create file:** `$SPLUNK_HOME/etc/system/local/transforms.conf`

```ini
[cowrie_eventid_lookup]
filename = cowrie_eventids.csv
```

**Create the CSV:** `$SPLUNK_HOME/etc/system/lookups/cowrie_eventids.csv`

```csv
eventid,description,severity
cowrie.session.connect,New connection established,low
cowrie.login.failed,Login attempt failed,low
cowrie.login.success,Login accepted by honeypot,high
cowrie.command.input,Command executed by attacker,medium
cowrie.session.file_download,File download attempted,high
cowrie.session.file_upload,File upload attempted,high
cowrie.session.closed,Session disconnected,info
cowrie.client.version,SSH client version fingerprinted,low
```

Use in searches:

```
index=cowrie
| lookup cowrie_eventid_lookup eventid OUTPUT description severity
| table _time, src_ip, eventid, description, severity
```

---

## Verify Everything is Working

Run this diagnostic search:

```
index=cowrie
| stats count by eventid
| sort -count
```

You should see counts for each Cowrie event type. If this returns results, your index, sourcetype, and parsing are all working correctly.

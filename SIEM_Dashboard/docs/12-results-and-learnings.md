# 12 — Results, Outputs & Key Learnings

## Results & Outputs

### What Was Built

| Deliverable | Status | Description |
|---|---|---|
| Central Splunk Server | ✅ Complete | Indexer + Web UI running on Ubuntu |
| Universal Forwarder (Ubuntu) | ✅ Complete | Auth + HTTP logs forwarded |
| Universal Forwarder (Debian) | ✅ Complete | Auth + syslog forwarded |
| Universal Forwarder (Rocky Linux) | ✅ Complete | `/var/log/secure` + httpd logs |
| SSH Monitoring Dashboard | ✅ Complete | Login attempts, IPs, timechart |
| Auth Logs Dashboard | ✅ Complete | Sudo usage, failures, timelines |
| HTTP Traffic Dashboard | ✅ Complete | Request volume, status codes, top IPs |
| SSH Brute-Force Alert | ✅ Complete | Triggers on >10 failures in 5 min |
| DDoS Alert | ✅ Complete | Triggers on >200 req/min per IP |
| Custom SSH Autologin Logger | ✅ Complete | Python script generating JSON logs |
| Firewall Rules | ✅ Complete | `ufw` (Debian/Ubuntu), `firewalld` (Rocky) |

---

### Log Volume (Sample)

| Source | Events/Hour (Approx.) | Index |
|---|---|---|
| SSH auth events | 50–500 | auth_logs |
| HTTP access logs | 100–10,000 | web_logs |
| Syslog events | 200–1,000 | os_logs |
| Custom SSH JSON logs | 10–100 | ssh_logs |

---

### Alerts Observed

During testing, the following alert types were triggered:

- **SSH Brute-Force**: Simulated with `hydra` targeting SSH — alert fired within one 5-minute window, correctly identifying the attacking IP.
- **DDoS Simulation**: Used `ab` (Apache Benchmark) to flood the web server with 500 requests/minute — alert fired immediately on the first check.

---

## Key Learnings

### 1. Firewall Rules Are Critical on RHEL Systems

Rocky Linux (RHEL-based) uses `firewalld` rather than `ufw`. The default `firewalld` configuration blocks port 9997, silently preventing forwarders from connecting. This was the most common issue during setup and requires explicit `--permanent` rules followed by `--reload`.

**Lesson:** Always verify port connectivity with `nc -zv <indexer-ip> 9997` from each forwarder after configuration.

---

### 2. Log File Paths Differ Across Distros

Debian/Ubuntu uses `/var/log/auth.log` while Rocky Linux uses `/var/log/secure`. Similarly, Apache log paths differ (`/var/log/apache2/` vs `/var/log/httpd/`). Each `inputs.conf` must be tailored per distro.

**Lesson:** Maintain a separate `inputs.conf` per OS family rather than a one-size-fits-all config.

---

### 3. JSON Sourcetype Enables Rich Field Extraction

Using `sourcetype = _json` for the custom SSH autologin log allowed Splunk to automatically parse all JSON fields (`status`, `target_host`, `username`, etc.) without writing any `transforms.conf`. This dramatically simplified dashboard building.

**Lesson:** Structured (JSON) logging is far easier to work with in Splunk than unstructured plain text.

---

### 4. SPL `rex` is Powerful but Regex-Intensive

Extracting fields from raw auth.log lines requires regex using `| rex`. While powerful, regex is fragile and log formats can vary. For production use, `EXTRACT` rules in `props.conf` + `transforms.conf` are more robust.

**Lesson:** For one-off searches, `| rex` is fine. For dashboards and alerts that run constantly, define field extractions in props/transforms.

---

### 5. Alert Throttling Prevents Alert Fatigue

Without throttling, a 60-minute brute-force attack would trigger 12 alerts (one every 5 minutes). Enabling suppression by `src_ip` for 60 minutes keeps the alert meaningful without flooding the inbox.

**Lesson:** Always configure alert suppression in production SIEM environments.

---

### 6. Symlinks and Hard Links Work for Log Monitoring

Splunk Universal Forwarder can follow both symlinks and hard links. Hard links are more robust for log-rotated files since the file's inode persists even if the original filename changes. Symlinks are more flexible for cross-filesystem linking.

**Lesson:** Prefer hard links for log files in active rotation; symlinks for organizing paths across directories.

---

### 7. Universal Forwarder Has Minimal Resource Overhead

The UF used less than 50MB RAM and <1% CPU on all test machines, even when forwarding high-volume HTTP logs. It is well-suited for production servers where resource usage must be minimal.

---

## Skills Demonstrated

- **Splunk Administration**: Installation, configuration, indexing, dashboards, alerts
- **Log Management**: Centralized log collection from heterogeneous Linux environments
- **SPL (Search Processing Language)**: Anomaly detection queries, field extraction, time-based aggregation
- **Linux System Administration**: Multi-distro (Debian, Ubuntu, Rocky Linux) configuration
- **Firewall Management**: `ufw` and `firewalld` rules for secure log forwarding
- **Python Scripting**: Custom SSH autologin tool with structured JSON logging
- **Cybersecurity Concepts**: Brute-force detection, DDoS identification, privilege escalation monitoring, threat hunting

---

## Future Improvements

- Enable **TLS encryption** on the forwarder-to-indexer connection (port 9997)
- Add **GeoIP lookup** to map attacking IPs to geographic locations on dashboards
- Integrate with **Slack or PagerDuty** for real-time alert notifications
- Set up a **Splunk Deployment Server** to centrally manage all forwarder configs
- Add **Windows Event Log** collection to broaden coverage
- Implement **Splunk Enterprise Security (ES)** for advanced correlation rules

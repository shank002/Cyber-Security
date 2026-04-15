# 07 — Log Collection & Inputs Configuration

## Overview

Log collection is configured via `inputs.conf` on each Universal Forwarder. This file tells the forwarder which files to monitor, what sourcetype to assign, and which index to store events in.

---

## Splunk Indexes Used

| Index | Purpose |
|---|---|
| `main` | Default index — all logs |
| `os_logs` | OS-level logs (syslog, messages) |
| `auth_logs` | Authentication events |
| `web_logs` | HTTP access/error logs |
| `ssh_logs` | SSH-specific events |

> You can create custom indexes in Splunk Web: **Settings → Indexes → New Index**

---

## inputs.conf — Full Configuration

### Ubuntu / Debian Client

File path: `/opt/splunkforwarder/etc/system/local/inputs.conf`

```ini
# ── Authentication & SSH Logs ─────────────────────────────────
[monitor:///var/log/auth.log]
disabled = false
index = auth_logs
sourcetype = linux_secure
host = ubuntu-client-01
crcSalt = <SOURCE>

# ── System Logs ───────────────────────────────────────────────
[monitor:///var/log/syslog]
disabled = false
index = os_logs
sourcetype = syslog
host = ubuntu-client-01

# ── Apache HTTP Access Log ───────────────────────────────────
[monitor:///var/log/apache2/access.log]
disabled = false
index = web_logs
sourcetype = access_combined
host = ubuntu-client-01

# ── Apache HTTP Error Log ─────────────────────────────────────
[monitor:///var/log/apache2/error.log]
disabled = false
index = web_logs
sourcetype = apache_error
host = ubuntu-client-01

# ── Nginx Access Log ─────────────────────────────────────────
[monitor:///var/log/nginx/access.log]
disabled = false
index = web_logs
sourcetype = nginx_access
host = ubuntu-client-01

# ── Custom SSH Autologin JSON Log ────────────────────────────
[monitor:///home/user/ssh_autologin.log]
disabled = false
index = ssh_logs
sourcetype = _json
host = ubuntu-client-01
```

---

### Rocky Linux Client

File path: `/opt/splunkforwarder/etc/system/local/inputs.conf`

```ini
# ── Authentication & SSH Logs (RHEL uses /var/log/secure) ────
[monitor:///var/log/secure]
disabled = false
index = auth_logs
sourcetype = linux_secure
host = rocky-client-01
crcSalt = <SOURCE>

# ── System Logs (RHEL uses /var/log/messages) ────────────────
[monitor:///var/log/messages]
disabled = false
index = os_logs
sourcetype = syslog
host = rocky-client-01

# ── Apache HTTP Logs (RHEL path) ─────────────────────────────
[monitor:///var/log/httpd/access_log]
disabled = false
index = web_logs
sourcetype = access_combined
host = rocky-client-01

[monitor:///var/log/httpd/error_log]
disabled = false
index = web_logs
sourcetype = apache_error
host = rocky-client-01

# ── Custom SSH Autologin JSON Log ────────────────────────────
[monitor:///home/user/ssh_autologin.log]
disabled = false
index = ssh_logs
sourcetype = _json
host = rocky-client-01
```

---

## outputs.conf

File path: `/opt/splunkforwarder/etc/system/local/outputs.conf`

```ini
[tcpout]
defaultGroup = central-indexer
sendCookedData = true

[tcpout:central-indexer]
server = CENTRAL_SERVER_IP:9997
compressed = true
# Optional: enable SSL/TLS
# sslCertPath = $SPLUNK_HOME/etc/certs/client.pem
# sslRootCAPath = $SPLUNK_HOME/etc/certs/cacert.pem
# sslVerifyServerCert = true
```

---

## Log File Reference by Distro

| Log File | Debian/Ubuntu | Rocky Linux | Content |
|---|---|---|---|
| SSH/Auth | `/var/log/auth.log` | `/var/log/secure` | SSH logins, sudo, PAM |
| System | `/var/log/syslog` | `/var/log/messages` | General system events |
| Apache | `/var/log/apache2/access.log` | `/var/log/httpd/access_log` | HTTP requests |
| Apache Error | `/var/log/apache2/error.log` | `/var/log/httpd/error_log` | HTTP errors |
| Nginx | `/var/log/nginx/access.log` | `/var/log/nginx/access.log` | Nginx requests |
| SSH JSON | `/home/user/ssh_autologin.log` | `/home/user/ssh_autologin.log` | Custom JSON logs |

---

## Apply Changes

After editing any `.conf` file:

```bash
# Restart the Universal Forwarder
sudo /opt/splunkforwarder/bin/splunk restart

# Verify monitored inputs
sudo /opt/splunkforwarder/bin/splunk list monitor -auth admin:password
```

---

## Verify Data in Splunk

Search the Web UI for:

```spl
index=auth_logs | head 20
index=web_logs  | head 20
index=ssh_logs  | head 20
```

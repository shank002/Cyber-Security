# 06 — Firewall Configuration

Splunk Universal Forwarders send log data to the central indexer over **TCP port 9997**. Firewall rules must allow this traffic — both on the central server (inbound 9997) and on RHEL-based clients (outbound 9997).

> ⚠️ **Rocky Linux uses `firewalld` by default.** This is the most common point of failure in Splunk UF setups on RHEL-based systems.

---

## Central Server — Allow Inbound Port 9997

### Ubuntu / Debian (using `ufw`)

```bash
# Allow Splunk forwarder traffic inbound
sudo ufw allow 9997/tcp

# Allow Splunk Web UI
sudo ufw allow 8000/tcp

# Allow Splunk management port
sudo ufw allow 8089/tcp

# Enable ufw if not already active
sudo ufw enable

# Verify rules
sudo ufw status verbose
```

Expected output:
```
To                         Action      From
--                         ------      ----
9997/tcp                   ALLOW IN    Anywhere
8000/tcp                   ALLOW IN    Anywhere
8089/tcp                   ALLOW IN    Anywhere
```

### Rocky Linux (using `firewalld`)

```bash
# Add Splunk ports to the firewall permanently
sudo firewall-cmd --permanent --add-port=9997/tcp
sudo firewall-cmd --permanent --add-port=8000/tcp
sudo firewall-cmd --permanent --add-port=8089/tcp

# Reload firewalld to apply changes
sudo firewall-cmd --reload

# Verify
sudo firewall-cmd --list-ports
```

---

## Client Machines — Allow Outbound Port 9997

On Debian/Ubuntu clients, outbound traffic is typically allowed by default. On **Rocky Linux clients**, you may need to explicitly allow outbound:

### Rocky Linux Client

```bash
# Allow outbound to Splunk indexer on port 9997
sudo firewall-cmd --permanent --add-rich-rule='
  rule family="ipv4"
  destination address="CENTRAL_SERVER_IP/32"
  port protocol="tcp" port="9997"
  accept'

# Reload
sudo firewall-cmd --reload

# Verify rich rules
sudo firewall-cmd --list-rich-rules
```

---

## Restrict Inbound to Specific Forwarder IPs (Recommended)

For better security, restrict port 9997 to only your known forwarder IPs:

### Ubuntu / Debian (ufw)

```bash
# Allow port 9997 only from specific forwarder IPs
sudo ufw allow from 192.168.1.101 to any port 9997
sudo ufw allow from 192.168.1.102 to any port 9997
sudo ufw allow from 192.168.1.103 to any port 9997

# Deny all other traffic to 9997
sudo ufw deny 9997/tcp
```

### Rocky Linux (firewalld)

```bash
# Create a zone for Splunk forwarders
sudo firewall-cmd --permanent --new-zone=splunk-forwarders
sudo firewall-cmd --permanent --zone=splunk-forwarders --add-source=192.168.1.101
sudo firewall-cmd --permanent --zone=splunk-forwarders --add-source=192.168.1.102
sudo firewall-cmd --permanent --zone=splunk-forwarders --add-port=9997/tcp
sudo firewall-cmd --reload
```

---

## SELinux Considerations (Rocky Linux / RHEL)

If SELinux is enforcing, it may block Splunk from binding to port 9997:

```bash
# Check SELinux status
sestatus

# Check if SELinux is blocking Splunk
sudo ausearch -m avc -ts recent | grep splunk

# If blocked, add SELinux port label for Splunk
sudo semanage port -a -t syslogd_port_t -p tcp 9997

# Or set Splunk home context
sudo chcon -R -t bin_t /opt/splunkforwarder/bin/

# Alternatively (less secure), set SELinux to permissive
sudo setenforce 0  # Temporary
# To make permanent:
sudo sed -i 's/SELINUX=enforcing/SELINUX=permissive/' /etc/selinux/config
```

---

## Test Connectivity

From each **client machine**, test that port 9997 on the central server is reachable:

```bash
# Test TCP connection to Splunk indexer
nc -zv CENTRAL_SERVER_IP 9997
# Expected: Connection to CENTRAL_SERVER_IP 9997 port [tcp/*] succeeded!

# Alternative with curl
curl -v telnet://CENTRAL_SERVER_IP:9997

# Using nmap
nmap -p 9997 CENTRAL_SERVER_IP
```

---

## Summary Table

| Machine | OS | Tool | Command |
|---|---|---|---|
| Central Server | Ubuntu/Debian | `ufw` | `ufw allow 9997/tcp` |
| Central Server | Rocky Linux | `firewalld` | `firewall-cmd --permanent --add-port=9997/tcp` |
| Client | Ubuntu/Debian | `ufw` | Usually open by default |
| Client (RHEL) | Rocky Linux | `firewalld` | Add rich rule for outbound 9997 |

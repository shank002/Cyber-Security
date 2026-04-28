# 07 — MySQL / MariaDB Remote Access

This document covers how to check whether MariaDB is accepting remote connections, how to diagnose connectivity issues, and how to manage user access by host scope.

> For this project, MariaDB is intentionally kept localhost-only. This page documents the diagnostic process and explains how remote access works in case it is needed in future.

---

## Checking if MariaDB Accepts Remote Connections

### From a remote machine

```bash
# Using the MySQL client
mysql -h <server_ip> -u <username> -p -P 3306

# Using telnet (tests TCP port reachability)
telnet <server_ip> 3306

# Using netcat
nc -zv <server_ip> 3306

# Using nmap
nmap -p 3306 <server_ip>
```

### On the MariaDB server itself

Check what interface MariaDB is bound to:

```bash
ss -tlnp | grep 3306
# or
netstat -tlnp | grep 3306
```

| Output | Meaning |
|--------|---------|
| `127.0.0.1:3306` | Localhost only — no remote access |
| `0.0.0.0:3306` | All interfaces — remote access possible |

For this project, you should see `127.0.0.1:3306`.

---

## The bind-address Setting

MariaDB's bind-address controls which network interface it listens on.

Config file location on Rocky Linux:
```
/etc/my.cnf.d/mariadb-server.cnf
```

```ini
[mysqld]
# Localhost only (default, recommended for single-server setups)
bind-address = 127.0.0.1

# All interfaces (required for remote connections)
# bind-address = 0.0.0.0
```

After changing `bind-address`, restart MariaDB:
```bash
sudo systemctl restart mariadb
```

---

## Listing All Users and Their Host Scope

```bash
mysql -u root -p
```

```sql
-- Basic list
SELECT user, host FROM mysql.user;

-- Detailed view (includes lock status, expiry)
SELECT user, host, authentication_string, account_locked, password_expired
FROM mysql.user;
```

Sample output:
```
+------------------+-----------+
| user             | host      |
+------------------+-----------+
| root             | localhost |
| myapp_user       | localhost |
+------------------+-----------+
```

### Host value meanings

| Value | Access from |
|-------|------------|
| `localhost` | Local machine only |
| `127.0.0.1` | IPv4 loopback only |
| `%` | Any host (fully open) |
| `192.168.1.%` | Any IP in that subnet |
| `192.168.1.100` | That specific IP only |

---

## Show Privileges for a Specific User

```sql
SHOW GRANTS FOR 'myapp_user'@'localhost';
```

---

## Granting Remote Access (If Required)

If you ever need a user to connect from a remote host:

```sql
-- Create a user that can connect from anywhere
CREATE USER 'remote_user'@'%' IDENTIFIED BY 'StrongPassword!';
GRANT ALL PRIVILEGES ON myapp_db.* TO 'remote_user'@'%';
FLUSH PRIVILEGES;
```

Or for a specific IP:
```sql
CREATE USER 'remote_user'@'192.168.1.50' IDENTIFIED BY 'StrongPassword!';
GRANT SELECT ON myapp_db.* TO 'remote_user'@'192.168.1.50';
FLUSH PRIVILEGES;
```

Then open the firewall port:
```bash
sudo firewall-cmd --permanent --add-port=3306/tcp
sudo firewall-cmd --reload
```

And update `bind-address = 0.0.0.0` in the MariaDB config.

---

## Security Note

Exposing port 3306 publicly is a significant security risk. If remote DB access is needed:

- Grant access only to specific IPs, never `%` in production
- Use a VPN or SSH tunnel instead of direct port exposure where possible
- Keep a dedicated firewall rule and audit it regularly
- Never use the `root` user for application connections

---

## Next Step

→ [Troubleshooting common issues](08-troubleshooting.md)

# Phase 3 — Firewall Configuration

> Apply a default-deny firewall policy and whitelist only required ports using iptables (Debian) or firewalld (RHEL).

---

## 3.1 iptables — Debian / Ubuntu

Install persistence:

```bash
sudo apt install iptables-persistent -y
```

Apply rules (or run [`configs/firewall/iptables-rules.sh`](../configs/firewall/iptables-rules.sh)):

```bash
# Flush existing rules
sudo iptables -F

# Set default policies — drop all inbound and forwarded traffic
sudo iptables -P INPUT DROP
sudo iptables -P FORWARD DROP
sudo iptables -P OUTPUT ACCEPT

# Allow loopback interface
sudo iptables -A INPUT -i lo -j ACCEPT

# Allow established and related return traffic
sudo iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# Allow SSH (custom port), HTTP, HTTPS
sudo iptables -A INPUT -p tcp --dport 2222 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 80 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 443 -j ACCEPT

# Save rules to persist across reboots
sudo netfilter-persistent save
```

Verify:

```bash
sudo iptables -L -v -n
```

---

## 3.2 firewalld — RHEL / CentOS / Fedora

```bash
# Enable and start firewalld
sudo systemctl enable --now firewalld

# Set default zone to drop (deny all by default)
sudo firewall-cmd --set-default-zone=drop

# Allow only required ports/services
sudo firewall-cmd --permanent --add-port=2222/tcp
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --permanent --add-service=https

# Apply changes
sudo firewall-cmd --reload

# Verify
sudo firewall-cmd --list-all
```

---

## Rule Order Explanation

iptables processes rules **top to bottom** and stops at the first match. Order matters:

```
1. lo (loopback)          → ACCEPT  — always allow local traffic
2. ESTABLISHED,RELATED    → ACCEPT  — allow return traffic for outbound connections
3. Port-specific rules    → ACCEPT  — allow only what's needed
4. Default policy         → DROP    — everything else is silently dropped
```

If ESTABLISHED,RELATED is missing, your server cannot receive replies to its own outbound requests (e.g. apt update responses would be dropped).

---

## What This Mitigates

| Attack | Control Applied |
|---|---|
| Port scanning reveals many services | Only 3 ports visible |
| Direct exploitation of open services | All other ports dropped by default |
| SYN flood (partially) | Combined with sysctl tcp_syncookies in Phase 4 |

---

## Next Step

→ [Phase 4 — Kernel Hardening](04-kernel-hardening.md)

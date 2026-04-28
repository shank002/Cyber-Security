# 01 — Prerequisites

Before touching any packages, get the base system into a clean, known state.

---

## System Requirements

| Item | Requirement |
|------|------------|
| OS | Rocky Linux 8 or 9 |
| RAM | 1 GB minimum (2 GB recommended) |
| Disk | 10 GB free |
| CPU | 1 vCPU (2+ recommended for PM2 clustering) |
| Network | VM reachable from host machine (NAT or bridged) |
| User | A user with `sudo` access (do not run everything as root) |

---

## Step 1 — Update the system

```bash
sudo dnf update -y
sudo dnf install -y epel-release
```

EPEL (Extra Packages for Enterprise Linux) is needed for some tooling later.

---

## Step 2 — Set a hostname (optional but useful)

```bash
sudo hostnamectl set-hostname nexus-server
```

---

## Step 3 — Configure firewalld

Open only the ports the public needs. Node.js (3000) and MariaDB (3306) are intentionally not opened — they are internal only.

```bash
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --permanent --add-service=https
sudo firewall-cmd --reload
```

Verify:
```bash
sudo firewall-cmd --list-all
```

Expected output includes `services: cockpit dhcpv6-client http https`.

---

## Step 4 — Verify SELinux is enforcing

Rocky Linux ships with SELinux on. Leave it on. Do not run `setenforce 0`.

```bash
sestatus
```

Expected:
```
SELinux status:                 enabled
SELinuxfs mount:                /sys/fs/selinux
SELinux mount policy version:   33
Current mode:                   enforcing
Mode from config file:          enforcing
```

If it shows `permissive`, set it back:
```bash
sudo setenforce 1
# For permanent change, edit /etc/selinux/config and set SELINUX=enforcing
```

---

## Step 5 — Find your VM's IP

You'll need this to access the server from your host browser.

```bash
ip addr show
```

Look for `inet` under your active interface (`eth0`, `ens33`, `enp0s3`, etc.). Example: `192.168.1.105`.

---

## Next Step

→ [Install and configure Nginx](02-nginx-setup.md)

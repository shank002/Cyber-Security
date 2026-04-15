# Phase 4 — Kernel Hardening (sysctl)

> Apply kernel-level security parameters via sysctl to harden the network stack, memory layout, and system behaviour.

---

## Overview

`sysctl` controls kernel parameters at runtime. By creating a drop-in config file in `/etc/sysctl.d/`, the settings are applied automatically on every boot.

> Note: The file `/etc/sysctl.d/99-hardening.conf` does **not** need to exist beforehand — creating it with `nano` or `cp` is all that is needed.

---

## Apply the Config

Copy the config file from this repo:

```bash
sudo cp configs/kernel/99-hardening.conf /etc/sysctl.d/99-hardening.conf
```

Or create it manually:

```bash
sudo nano /etc/sysctl.d/99-hardening.conf
```

---

## Parameters Explained

```ini
# Disable IP forwarding — this is not a router
net.ipv4.ip_forward = 0
net.ipv6.conf.all.forwarding = 0

# SYN flood protection
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_max_syn_backlog = 2048

# Ignore ICMP redirects (prevent routing manipulation)
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv6.conf.all.accept_redirects = 0

# Ignore broadcast pings (Smurf attack mitigation)
net.ipv4.icmp_echo_ignore_broadcasts = 1

# TCP time-wait attack protection
net.ipv4.tcp_rfc1337 = 1

# Log packets with impossible source addresses (martians)
net.ipv4.conf.all.log_martians = 1

# Disable source routing
net.ipv4.conf.all.accept_source_route = 0

# Prevent SUID binaries from creating core dumps
fs.suid_dumpable = 0

# Enable full ASLR (Address Space Layout Randomization)
kernel.randomize_va_space = 2

# Hide kernel pointers from unprivileged users
kernel.kptr_restrict = 2

# Restrict dmesg access to root only
kernel.dmesg_restrict = 1
```

---

## Apply Without Reboot

```bash
sudo sysctl --system
```

---

## Verify Key Parameters

```bash
sysctl kernel.randomize_va_space
# Expected: kernel.randomize_va_space = 2

sysctl net.ipv4.tcp_syncookies
# Expected: net.ipv4.tcp_syncookies = 1

sysctl net.ipv4.ip_forward
# Expected: net.ipv4.ip_forward = 0
```

---

## What This Mitigates

| Parameter | Attack Mitigated |
|---|---|
| `tcp_syncookies = 1` | SYN flood DoS |
| `accept_redirects = 0` | ICMP redirect routing attacks |
| `randomize_va_space = 2` | Memory exploitation (buffer overflows) |
| `kptr_restrict = 2` | Kernel pointer leaks to unprivileged users |
| `log_martians = 1` | Detection of spoofed/forged source IPs |
| `suid_dumpable = 0` | SUID process core dump exploitation |

---

## Next Step

→ [Phase 5 — MAC Enforcement](05-mac-enforcement.md)

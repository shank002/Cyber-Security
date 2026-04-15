# Phase 5 — MAC Enforcement (AppArmor / SELinux)

> Enforce Mandatory Access Control to confine processes and limit what a compromised application can access, regardless of user permissions.

---

## What is MAC?

Mandatory Access Control (MAC) is a kernel-level security layer that **restricts what processes can access** — independently of Unix file permissions. Even if an attacker gains control of a process, MAC confines what that process can read, write, or execute.

- **AppArmor** (Debian/Ubuntu) — path-based profiles per application
- **SELinux** (RHEL/CentOS) — label-based policy across all system objects

---

## AppArmor — Debian / Ubuntu

```bash
# Install
sudo apt install apparmor apparmor-utils -y

# Enable and start
sudo systemctl enable --now apparmor

# Check status — shows enforced vs complain-mode profiles
sudo aa-status

# Set all loaded profiles to enforce mode
sudo aa-enforce /etc/apparmor.d/*
```

Check for denials:

```bash
sudo journalctl -xe | grep apparmor
```

---

## SELinux — RHEL / CentOS

```bash
# Check current mode
sestatus

# Set to enforcing permanently
sudo sed -i 's/^SELINUX=.*/SELINUX=enforcing/' /etc/selinux/config

# Apply immediately without reboot
sudo setenforce 1

# Verify
sestatus
# Expected: SELinux status: enabled / Current mode: enforcing

# Check for recent denials
sudo ausearch -m avc -ts recent
```

---

## AppArmor vs SELinux

| Aspect | AppArmor | SELinux |
|---|---|---|
| Model | Path-based profiles | Label-based policy |
| Default on | Debian / Ubuntu | RHEL / CentOS |
| Complexity | Lower | Higher |
| Granularity | Per-application | System-wide labels |
| Both enforce | Process confinement | Process confinement |

---

## What This Mitigates

| Threat | MAC Control |
|---|---|
| Compromised web server reads /etc/shadow | AppArmor/SELinux profile denies access |
| Exploited process spawns a shell | Confined process cannot exec outside profile |
| Lateral movement via process | Process cannot access resources outside its label/profile |

---

## Next Step

→ [Phase 6 — Service Minimization](06-service-minimization.md)

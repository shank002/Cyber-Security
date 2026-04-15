# Defensive Controls

> Each control below is mapped directly to an attack scenario from the simulation phase — showing exactly what each defense neutralizes.

---

## Controls Mapped to Attacks

| Attack Scenario | Defensive Control Applied |
|---|---|
| Nmap reveals many open ports | iptables default-deny — only ports 2222, 80, 443 visible |
| SSH brute force via Hydra | Key-only auth, port 2222, MaxAuthTries 3, root login disabled |
| linpeas finds SUID binaries | Packages removed, fs.suid_dumpable=0, AppArmor/SELinux confinement |
| /etc/shadow access attempted | MAC enforcement denies out-of-profile access, auditd records the attempt |
| Privilege escalation via sudo | auditd logs every sudo/su invocation, PAM enforces strong credentials |
| Kernel memory exploit (no ASLR) | kernel.randomize_va_space=2, kernel.kptr_restrict=2 |
| SYN flood / ICMP abuse | tcp_syncookies=1, icmp_echo_ignore_broadcasts=1, tcp_max_syn_backlog=2048 |
| No detection of attacker activity | auditd logs all privileged events, file writes, and login activity |

---

## Detection with auditd

Every simulated attack generates a traceable event in auditd logs.

### Detect Brute Force Attempts

```bash
# Failed login events
sudo ausearch -k session | grep "res=failed"

# Failed logins from btmp
sudo lastb | head -20

# Live auth log
sudo tail -f /var/log/auth.log
```

### Detect Privilege Escalation

```bash
# All sudo/su events
sudo ausearch -k privilege_escalation

# Authentication summary
sudo aureport --auth
```

### Detect Unauthorized File Access

```bash
# Writes/attribute changes to passwd and shadow
sudo ausearch -k identity

# Sudoers changes
sudo ausearch -k sudoers
```

### Full Audit Reports

```bash
sudo aureport --summary
sudo aureport --login
sudo aureport --failed
sudo aureport --file
```

---

## Defense-in-Depth Summary

```
Layer 1 — Perimeter
  iptables / firewalld → default-deny, 3 ports exposed

Layer 2 — Authentication
  SSH key-only, no root, MaxAuthTries 3, PAM password policy

Layer 3 — Host / Kernel
  ASLR, SYN cookies, ICMP limits, kernel pointer hiding

Layer 4 — Process
  AppArmor / SELinux in enforcing mode

Layer 5 — Monitoring
  auditd — full event trail for forensics and detection
```

**Principle:** A breach of any single layer does not result in full system compromise. Each layer independently reduces risk and slows an attacker down.

---

## Back to Main

→ [README](../README.md)

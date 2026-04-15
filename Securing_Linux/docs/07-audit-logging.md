# Phase 7 — Audit Logging (auditd)

> Deploy auditd with custom rules to establish a kernel-level forensic audit trail covering identity changes, privilege escalation, and session activity.

---

## How auditd Works

`auditd` operates at the **Linux kernel level** via the kernel's audit subsystem. It does not simply watch log files — it intercepts kernel events (syscalls, file writes, process executions) before they complete and records them to `/var/log/audit/audit.log`.

For login tracking specifically: when a user logs in, the OS writes to `wtmp`, `btmp`, and `lastlog`. auditd watches those file writes, which is how login events appear in the audit log.

---

## Install and Enable

```bash
# Debian / Ubuntu
sudo apt install auditd audispd-plugins -y

# RHEL / CentOS
sudo dnf install audit -y

# Enable and start
sudo systemctl enable --now auditd
```

---

## Apply Custom Rules

Copy the rules from this repo:

```bash
sudo cp configs/audit/hardening.rules /etc/audit/rules.d/hardening.rules
```

Or create manually:

```bash
sudo nano /etc/audit/rules.d/hardening.rules
```

Contents:

```
# Identity — track changes to user/password files
-w /etc/passwd -p wa -k identity
-w /etc/shadow -p wa -k identity
-w /etc/sudoers -p wa -k sudoers

# Privilege escalation — track sudo/su execution and setuid syscall
-a always,exit -F arch=b64 -S setuid -k privilege_escalation
-w /bin/su -p x -k privilege_escalation
-w /usr/bin/sudo -p x -k privilege_escalation

# SSH config changes
-w /etc/ssh/sshd_config -p wa -k sshd_config

# Session tracking — login/logout via utmp/wtmp/btmp
-w /var/run/utmp -p wa -k session
-w /var/log/wtmp -p wa -k session
-w /var/log/btmp -p wa -k session
```

Load the rules:

```bash
sudo augenrules --load
sudo systemctl restart auditd
```

---

## Querying Audit Logs

```bash
# All session (login/logout) events
sudo ausearch -k session

# All privilege escalation events
sudo ausearch -k privilege_escalation

# Changes to identity files
sudo ausearch -k identity

# Failed events only
sudo ausearch -k session | grep "res=failed"

# Summary reports
sudo aureport --summary
sudo aureport --login
sudo aureport --failed
sudo aureport --auth
```

---

## What auditd Logs vs Does Not Log

| Logged (with these rules) | Not Logged by Default |
|---|---|
| Writes to /etc/passwd, /etc/shadow | Read-only access to files (needs -p r, gets noisy) |
| Every sudo / su execution | Network connections (needs additional rules) |
| SSH config changes | Process spawning (needs -a exit,always -S execve) |
| Login/logout via wtmp/btmp/utmp | System calls not explicitly watched |

---

## What This Mitigates / Enables

| Scenario | auditd Response |
|---|---|
| Attacker adds a new user | Write to /etc/passwd logged with k=identity |
| Privilege escalation via sudo | Execution logged with k=privilege_escalation |
| SSH config tampered | Write to sshd_config logged with k=sshd_config |
| Login brute force | Failed writes to btmp logged with k=session |
| Post-breach forensics | Full timestamped event trail in audit.log |

---

## Next Step

→ [Attack Simulation](08-attack-simulation.md)

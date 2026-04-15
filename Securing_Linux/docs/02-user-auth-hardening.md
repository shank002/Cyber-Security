# Phase 2 — User & Authentication Hardening

> Disable root login, enforce SSH key-based authentication, and apply strong password policies via PAM.

---

## 2.1 Disable Root Login

```bash
sudo passwd -l root
```

This locks the root password so it cannot be used to log in directly.

---

## 2.2 SSH Hardening

Edit the SSH daemon configuration:

```bash
sudo nano /etc/ssh/sshd_config
```

Apply the following settings (or copy from [`configs/ssh/sshd_config`](../configs/ssh/sshd_config)):

```
Port 2222
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
MaxAuthTries 3
LoginGraceTime 30
AllowUsers yourusername
X11Forwarding no
PermitEmptyPasswords no
ClientAliveInterval 300
ClientAliveCountMax 2
Protocol 2
```

Restart SSH to apply:

```bash
sudo systemctl restart sshd
```

> ⚠️ **Warning:** Make sure your SSH public key is configured and tested before disabling `PasswordAuthentication`. If you lock yourself out, you will need console/out-of-band access to recover.

---

## 2.3 Password Policy (PAM + login.defs)

Install the pwquality PAM module:

```bash
# Debian / Ubuntu
sudo apt install libpam-pwquality -y

# RHEL / CentOS
sudo dnf install pam_pwquality -y
```

Edit `/etc/security/pwquality.conf` (or copy from [`configs/pam/pwquality.conf`](../configs/pam/pwquality.conf)):

```
minlen = 14
minclass = 4
maxrepeat = 3
dcredit = -1
ucredit = -1
ocredit = -1
lcredit = -1
```

Edit `/etc/login.defs` for password aging:

```
PASS_MAX_DAYS   90
PASS_MIN_DAYS   7
PASS_WARN_AGE   14
```

Apply aging to existing users:

```bash
sudo chage -M 90 -m 7 -W 14 yourusername
```

Verify aging settings:

```bash
sudo chage -l yourusername
```

---

## Verification

```bash
# Confirm root is locked
sudo passwd -S root
# Expected: root L ... (L = locked)

# Confirm SSH config is valid before restart
sudo sshd -t

# Test login with your key from another terminal before closing current session
ssh -p 2222 -i ~/.ssh/your_key yourusername@<server-ip>
```

---

## What This Mitigates

| Attack | Control Applied |
|---|---|
| SSH brute force via root | `PermitRootLogin no` |
| Credential stuffing | `PasswordAuthentication no` (key-only) |
| Repeated failed attempts | `MaxAuthTries 3` |
| Weak user passwords | PAM pwquality + login.defs aging |

---

## Next Step

→ [Phase 3 — Firewall Configuration](03-firewall.md)

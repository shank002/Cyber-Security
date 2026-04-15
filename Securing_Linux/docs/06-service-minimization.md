# Phase 6 — Service Minimization

> Disable and remove unnecessary services and packages to reduce the attack surface.

---

## Principle

Every running service is a potential entry point for an attacker. If a service is not needed, it should be **disabled and removed** — not just stopped.

---

## List Running Services

```bash
systemctl list-units --type=service --state=running
```

Review the output and identify any service not required for the server's purpose.

---

## Disable Common Unnecessary Services

```bash
# Printing service (almost never needed on a server)
sudo systemctl disable --now cups

# Avahi mDNS/DNS-SD (network discovery — not needed on a server)
sudo systemctl disable --now avahi-daemon

# Bluetooth (not applicable to servers)
sudo systemctl disable --now bluetooth

# RPC bind (only needed for NFS — disable if not in use)
sudo systemctl disable --now rpcbind
```

---

## Remove Insecure / Unneeded Packages

```bash
# Debian / Ubuntu
sudo apt purge telnet ftp rsh-client rsh-server -y
sudo apt autoremove -y

# RHEL / CentOS
sudo dnf remove telnet ftp rsh -y
```

---

## Check for Open Ports After Cleanup

```bash
sudo ss -tulnp
```

Compare this output with your Nmap scan from the attack simulation phase. Fewer open ports = smaller attack surface.

---

## What This Mitigates

| Unnecessary Service | Risk Removed |
|---|---|
| telnet / rsh | Plaintext credential transmission |
| cups | Network-exposed printing daemon exploit surface |
| avahi-daemon | mDNS information disclosure and attack surface |
| rpcbind | NFS-related exploitation vectors |

---

## Next Step

→ [Phase 7 — Audit Logging](07-audit-logging.md)

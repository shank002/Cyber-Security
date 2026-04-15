# 🛡️ Linux Hardening + CIS Benchmark

> **Engineer-level security project** — Turning a default Linux installation into a secure, production-ready server aligned with CIS Benchmark standards and NIST SP 800-53 controls.

![Platform](https://img.shields.io/badge/Platform-Debian%20%7C%20RHEL-blue)
![Standard](https://img.shields.io/badge/Standard-CIS%20Benchmark-orange)
![Lynis Score](https://img.shields.io/badge/Lynis%20Score-80%2B-brightgreen)
![License](https://img.shields.io/badge/License-MIT-lightgrey)

---

## 📋 Table of Contents

- [Project Overview](#-project-overview)
- [Objectives](#-objectives)
- [Architecture & Workflow](#-architecture--workflow)
- [Tech Stack](#-tech-stack)
- [Repository Structure](#-repository-structure)
- [Implementation Guides](#-implementation-guides)
- [Results & Outputs](#-results--outputs)
- [Use Cases](#-use-cases)
- [Key Learnings](#-key-learnings)
- [Quick Start](#-quick-start)

---

## 🔍 Project Overview

This project demonstrates the end-to-end process of hardening a default Linux system (Debian 12 / RHEL 9) into a **production-grade secure server**. It covers both the **offensive perspective** (understanding attack vectors) and the **defensive implementation** (layered controls).

| Attribute | Detail |
|---|---|
| Target OS | Debian 12 / RHEL 9 |
| Benchmark | CIS Linux Benchmark Level 1 & 2 |
| Frameworks | NIST SP 800-53, SOC 2 |
| Audit Tool | Lynis |
| Role Relevance | SOC Analyst · Security Engineer · Linux Admin |

---

## 🎯 Objectives

**Defensive**
- Harden authentication — SSH, root login, PAM password policies
- Enforce network perimeter via stateful firewall (iptables / firewalld)
- Apply kernel-level protections via sysctl (ASLR, SYN cookies, ICMP limits)
- Enforce Mandatory Access Control — AppArmor (Debian) / SELinux (RHEL)
- Deploy auditd for a full kernel-level forensic audit trail
- Achieve Lynis hardening index of **80+**

**Offensive**
- Model realistic attack scenarios against a default Linux system
- Simulate SSH brute-force, port enumeration, and privilege escalation
- Use offensive findings to directly prioritize defensive controls

---

## 🏗️ Architecture & Workflow

```
┌──────────────────────────────────────────────────────────────┐
│                     HARDENING PIPELINE                        │
│                                                              │
│  [Phase 1]     [Phase 2]     [Phase 3]     [Phase 4]         │
│  Baseline  ──► User/Auth ──► Firewall  ──► Kernel/OS    ──►  │
│  Scan          Hardening     Rules         Hardening          │
│                                                              │
│                                            [Phase 5]         │
│                                            Audit &           │
│                                            Validation        │
└──────────────────────────────────────────────────────────────┘

Defense-in-Depth Layers:
  Perimeter   →  iptables / firewalld  (default-deny)
  Auth        →  SSH hardening, PAM, disabled root
  Host        →  sysctl kernel parameters, ASLR
  Process     →  AppArmor / SELinux (MAC enforcement)
  Monitoring  →  auditd rules, Lynis audit reports
```

---

## 🛠️ Tech Stack

### Defensive Tools

| Tool | Purpose |
|---|---|
| Lynis | Security auditing — generates hardening index score |
| iptables | Stateful packet filtering (Debian) |
| firewalld | Dynamic zone-based firewall daemon (RHEL) |
| auditd | Kernel-level syscall and file event monitoring |
| PAM / libpam-pwquality | Password complexity and account lockout |
| AppArmor | MAC enforcement via path-based profiles (Debian) |
| SELinux | MAC enforcement via label-based policy (RHEL) |
| sysctl | Runtime kernel parameter hardening |
| OpenSSH | Hardened SSH daemon — key auth, no root login |

### Offensive Tools (Simulation)

| Tool | Purpose |
|---|---|
| Nmap | Port scanning and service enumeration |
| Hydra | SSH brute-force credential attacks |
| linpeas.sh | Local privilege escalation enumeration |
| Metasploit | Exploitation and post-exploitation simulation |

---

## 📁 Repository Structure

```
linux-hardening-cis-benchmark/
│
├── README.md                         ← You are here
│
├── docs/                             ← Step-by-step implementation guides
│   ├── 01-baseline-assessment.md
│   ├── 02-user-auth-hardening.md
│   ├── 03-firewall.md
│   ├── 04-kernel-hardening.md
│   ├── 05-mac-enforcement.md
│   ├── 06-service-minimization.md
│   ├── 07-audit-logging.md
│   ├── 08-attack-simulation.md
│   └── 09-defensive-controls.md
│
├── configs/                          ← Ready-to-use hardened config files
│   ├── ssh/
│   │   └── sshd_config               ← Hardened SSH daemon config
│   ├── firewall/
│   │   ├── iptables-rules.sh         ← iptables setup (Debian)
│   │   └── firewalld-rules.sh        ← firewalld setup (RHEL)
│   ├── kernel/
│   │   └── 99-hardening.conf         ← sysctl drop-in config
│   ├── pam/
│   │   └── pwquality.conf            ← PAM password quality config
│   └── audit/
│       └── hardening.rules           ← auditd custom rules
│
├── scripts/
│   ├── harden.sh                     ← Master hardening script (all phases)
│   ├── baseline-scan.sh              ← Lynis scan before hardening
│   └── final-audit.sh                ← Lynis final audit + report
│
└── ansible/                          ← (Coming soon) Automation playbooks
    └── README.md
```

---

## 📖 Implementation Guides

Each phase is documented separately for clarity and modularity:

| # | Guide | Description |
|---|---|---|
| 1 | [Baseline Assessment](docs/01-baseline-assessment.md) | Run Lynis before hardening to capture the default score |
| 2 | [User & Auth Hardening](docs/02-user-auth-hardening.md) | Disable root, harden SSH, enforce PAM password policies |
| 3 | [Firewall Configuration](docs/03-firewall.md) | iptables and firewalld — default-deny with port whitelist |
| 4 | [Kernel Hardening](docs/04-kernel-hardening.md) | sysctl parameters — ASLR, SYN cookies, ICMP, martians |
| 5 | [MAC Enforcement](docs/05-mac-enforcement.md) | AppArmor (Debian) and SELinux (RHEL) in enforcing mode |
| 6 | [Service Minimization](docs/06-service-minimization.md) | Disable and remove unnecessary services and packages |
| 7 | [Audit Logging](docs/07-audit-logging.md) | auditd rules for identity, sessions, and privilege events |
| 8 | [Attack Simulation](docs/08-attack-simulation.md) | Offensive scenarios — Nmap, Hydra, linpeas, file access |
| 9 | [Defensive Controls](docs/09-defensive-controls.md) | Controls mapped 1-to-1 against each attack scenario |

---

## 📊 Results & Outputs

| Metric | Before Hardening | After Hardening |
|---|---|---|
| Lynis Hardening Index | ~35 / 100 | **80+ / 100** |
| Open Ports | Multiple exposed | 3 only (2222, 80, 443) |
| Root Login | Enabled | Disabled |
| SSH Password Auth | Enabled | Disabled (key-only) |
| Firewall Policy | Default ACCEPT | Default DROP + whitelist |
| ASLR | Partial (value: 1) | Full (value: 2) |
| auditd Rules | None | 10 custom rules active |
| MAC Enforcement | Not enforced | Enforcing mode |
| Attack Surface | Default baseline | **Reduced ~60%** |

---

## 🔁 Use Cases

- **Production server deployment** — Baseline hardening before any server goes live
- **Cloud instance security** — AWS EC2 / GCP / Azure VM post-provisioning hardening
- **SOC analyst lab** — Monitored Linux environment feeding logs into a SIEM (Splunk, Wazuh, Elastic)
- **Compliance auditing** — Lynis reports as audit evidence for PCI-DSS, HIPAA, SOC 2
- **Incident response prep** — auditd trail enables forensic investigation post-breach
- **CTF / Penetration testing** — Full attack + defense understanding on the same system

---

## 💡 Key Learnings

- `auditd` is a **kernel-level event recorder** — it watches syscalls and file events at the kernel, not just log files
- `iptables` **rule order is critical** — ESTABLISHED/RELATED must come before port-specific ACCEPT rules
- `sysctl` changes are **not auto-persisted** — drop-in files under `/etc/sysctl.d/` are required for production
- **AppArmor vs SELinux** — same goal (MAC), different models: path-based (AppArmor) vs label-based (SELinux)
- **Attack before defending** — offensive enumeration directly prioritizes which controls matter most
- A default Linux install scores **~35 on Lynis** — 65% of common hardening controls are absent out of the box

---

## 🚀 Quick Start

```bash
# 1. Clone the repo
git clone https://github.com/yourusername/linux-hardening-cis-benchmark.git
cd linux-hardening-cis-benchmark

# 2. Run baseline scan BEFORE hardening (captures your starting score)
sudo bash scripts/baseline-scan.sh

# 3. Run the full hardening pipeline
sudo bash scripts/harden.sh

# 4. Run the final audit and compare scores
sudo bash scripts/final-audit.sh
```

> ⚠️ **Important:** Ensure your SSH public key is already configured before running `harden.sh` — password authentication will be disabled. Run `baseline-scan.sh` first to capture your pre-hardening Lynis score.

---

## 📄 License

MIT — free to use for learning, portfolio, and professional reference.

---

*Portfolio project targeting SOC Analyst and Security Engineer roles.*

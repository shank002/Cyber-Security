# Phase 1 — Baseline Assessment

> Run Lynis before any hardening to capture the system's default security posture. This score is your pre-hardening benchmark.

---

## Why This Matters

A default Linux installation has no meaningful hardening applied. Running Lynis first gives you a **measurable starting point** so you can prove improvement at the end. This is also exactly what a compliance auditor would do first.

---

## Install Lynis

```bash
# Debian / Ubuntu
sudo apt install lynis -y

# RHEL / CentOS / Fedora
sudo dnf install lynis -y
```

---

## Run the Baseline Scan

```bash
sudo lynis audit system
```

Or use the included script:

```bash
sudo bash scripts/baseline-scan.sh
```

---

## What to Record

After the scan completes, note:

```bash
# View your hardening index score
grep "hardening_index" /var/log/lynis-report.dat

# View full report
sudo cat /var/log/lynis.log

# Save a copy as your baseline
sudo cp /var/log/lynis-report.dat /tmp/lynis-baseline.dat
```

**Expected baseline score on a default Debian install: ~35 / 100**

---

## Understanding the Output

| Section | What to Look At |
|---|---|
| `Hardening index` | Your overall score — higher is better |
| `Warnings` | High-priority issues — must be addressed |
| `Suggestions` | Lower-priority improvements |
| `Tests performed` | Total number of checks run |

---

## Next Step

→ [Phase 2 — User & Auth Hardening](02-user-auth-hardening.md)

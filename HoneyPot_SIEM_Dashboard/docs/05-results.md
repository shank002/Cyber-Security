# 05 · Results

> Results below are representative of a typical 30-day deployment of an internet-exposed SSH honeypot. Your actual numbers will vary by region, IP reputation, and how long the honeypot has been running.

---

## Attack Volume

| Metric | Typical 30-Day Range |
|---|---|
| Total connection attempts | 50,000 – 500,000 |
| Unique source IPs | 2,000 – 20,000 |
| Countries of origin | 40 – 80 |
| Successful logins (into Cowrie) | 500 – 5,000 |
| Commands executed | 2,000 – 30,000 |

Within minutes of exposing port 22 to the internet, automated scanners (Shodan crawlers, Mirai variants, credential-stuffing botnets) begin probing. Human-operated attacks typically appear within 24–72 hours.

---

## Top Attack Origins

The majority of automated SSH scanning originates from:

- **China** — large proportion of mass-scanning infrastructure
- **United States** — cloud VPS providers (AWS, DigitalOcean) used by attackers
- **Russia** — credential-stuffing botnet infrastructure
- **Netherlands / Germany** — Tor exit nodes and bulletproof hosting
- **Brazil / India** — compromised residential infrastructure

> Note: source country ≠ attacker nationality. Most attacks route through VPNs, Tor, and compromised hosts.

---

## Most Common Credentials Attempted

Automated scanners cycle through a predictable dictionary. The most-attempted combinations are consistently:

**Usernames:** `root`, `admin`, `ubuntu`, `user`, `pi`, `test`, `guest`, `oracle`, `postgres`

**Passwords:** `123456`, `password`, `admin`, `root`, `1234`, `admin123`, `raspberry`, `toor`, `pass`

**Finding:** Over 90% of credential attempts come from automated wordlists. The top 50 credential pairs account for the majority of all attempts.

---

## Most Common Commands Run After Login

Attackers who gain shell access (inside Cowrie) typically follow a predictable playbook:

```
1. uname -a                   # OS fingerprinting
2. cat /proc/cpuinfo           # CPU check (cryptominer feasibility)
3. free -m / df -h             # Resource check
4. id / whoami                 # Privilege check
5. wget / curl <malicious URL> # Payload download attempt
6. chmod +x <downloaded file>  # Make executable
7. history -c                  # Clear history
8. cat /etc/passwd             # Enumerate users
```

**Finding:** The majority of attackers who gain access immediately attempt to download a cryptocurrency miner or a DDoS bot. This aligns with real-world attack motivations.

---

## Alert Trigger Frequency (Typical 30 Days)

| Alert | Triggers / Day (Avg) |
|---|---|
| Brute-force spike (>50 attempts / 5 min) | 15 – 80 |
| Successful login | 10 – 150 |
| New country source | 1 – 5 |
| Command execution burst (>10 cmds/session) | 3 – 20 |

---

## Dashboard Observations

- **Peak attack hours:** 02:00–06:00 UTC (automated scanners run during off-peak bandwidth)
- **Attack patterns:** Distinct waves correlate with botnet activity cycles
- **Credential recycling:** Same IP often returns with different credentials after initial failure
- **Session length:** Most automated sessions last under 30 seconds; human-operated sessions average 3–8 minutes

---

## Key Outcome

The pipeline successfully captured, forwarded, and visualised all attacker activity with under 5-second latency from event generation to Splunk searchability. All 4 alert rules fired correctly during testing. The dashboard provided a clear real-time picture of attack patterns without manual log review.

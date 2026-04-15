# 06 · Key Learnings

## Technical Learnings

### 1. Structured logging is non-negotiable for SIEM integration
Cowrie's JSON output meant zero custom parsing work in Splunk. The `KV_MODE = json` directive in `props.conf` handled everything. Projects that generate unstructured text logs require significant Splunk regex work before they become useful.

**Takeaway:** Always choose tools that emit structured, timestamped JSON if the destination is a SIEM.

---

### 2. Port redirection avoids the root privilege trap
Running any service on port 22 requires root. Running Cowrie as root is a security risk — if Cowrie were compromised, the attacker would have full system access. The iptables NAT redirect (22 → 2222) solved this cleanly: Cowrie runs as an unprivileged user on a high port, while attackers still connect to port 22.

**Takeaway:** Use iptables NAT for privilege-separated port binding. This pattern applies beyond honeypots.

---

### 3. Outbound firewall rules are as important as inbound
The instinct is to focus on what's coming in. But a honeypot that can make outbound connections is dangerous — a sufficiently sophisticated attacker could use it to pivot. Denying all outbound except the Splunk forwarding port eliminated this risk entirely.

**Takeaway:** `ufw default deny outgoing` should be the first rule set on any honeypot or intentionally-exposed system.

---

### 4. Index creation must happen before the forwarder starts
If the `cowrie` index doesn't exist in Splunk when the Universal Forwarder first connects and ships events, those events are silently dropped (or sent to the default index). Creating the index first is a step that is easy to miss and painful to debug.

**Takeaway:** Always pre-create Splunk indexes before starting forwarders that target them. Verify with `index=cowrie | head 1` immediately after setup.

---

### 5. GeoIP enrichment is free with Splunk's `iplocation`
No external API, no outbound calls from the honeypot, no third-party subscription needed. Splunk's bundled MaxMind GeoLite database resolves IPs at search time. The cluster map panel was built entirely on `iplocation src_ip` with no additional infrastructure.

**Takeaway:** Explore built-in Splunk commands before reaching for external enrichment. `iplocation`, `lookup`, and `eval` cover a surprising amount of common enrichment needs.

---

### 6. Automated scanners dominate; humans are rare but interesting
Over 95% of traffic was automated — botnets running wordlists, Shodan crawlers, Mirai variants. The interesting data came from the small percentage of human-operated sessions where attackers actually explored the fake environment and attempted payload delivery.

**Takeaway:** Build your dashboard to surface the rare human-operated sessions (long session duration, many commands, wget/curl usage) rather than just raw volume metrics.

---

### 7. Alert fatigue is real — thresholds matter
Initial alert thresholds that were too low (e.g., >5 attempts triggers an alert) generated hundreds of daily alerts and became meaningless noise. Tuning the brute-force threshold to >50 attempts in 5 minutes reduced noise by ~95% while still catching all meaningful events.

**Takeaway:** Start with conservative (high) thresholds and tune down based on observed baseline. Use `timechart` to understand normal traffic patterns before setting thresholds.

---

### 8. Cowrie's fake shell is more convincing than expected
Attackers frequently ran multiple reconnaissance commands inside the fake environment before attempting payload downloads — suggesting they genuinely believed they had shell access. Commands like `uname -a`, `cat /proc/cpuinfo`, and `free -m` all returned plausible fake output.

**Takeaway:** Medium-interaction honeypots are effective enough to capture realistic attacker behaviour without the complexity and risk of full high-interaction deployments.

---

## Operational Learnings

- **Log rotation matters:** Without rotation, `cowrie.json` grows quickly under heavy attack load. Set up `logrotate` early.
- **Snapshot the clean VM:** Having a clean snapshot meant recovering from any misconfiguration took 2 minutes rather than rebuilding from scratch.
- **Monitor disk on the Splunk side:** A busy honeypot can generate significant index volume. Set an index size cap in Splunk from day one.
- **Document your real SSH port:** It is very easy to lock yourself out by misconfiguring UFW. Always verify management access before enabling `ufw enable`.

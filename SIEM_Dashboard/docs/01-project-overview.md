# 01 — Project Overview & Objectives

## Project Title

**SIEM Dashboard: Centralized Log Collection & Threat Detection using Splunk**

---

## Project Overview

This project implements a Security Information and Event Management (SIEM) system using **Splunk** as the core platform. A dedicated central Linux server acts as the Splunk indexer and dashboard host, while 3–4 additional Linux machines (running Debian, Ubuntu, and Rocky Linux) act as log sources, each running the **Splunk Universal Forwarder (UF)**.

Logs collected include:
- **SSH logs** — tracking login attempts, failed authentications, and session activity
- **Auth logs** — system-level authentication events from `/var/log/auth.log` or `/var/log/secure`
- **HTTP logs** — web server access and error logs from Apache or Nginx

The collected data is visualized in real-time Splunk dashboards and monitored via automated alerts for threats such as SSH brute-force attacks and DDoS activity on web servers.

---

## Objectives

### Primary Objectives

1. **Centralize log management** across multiple Linux machines using Splunk and its Universal Forwarder.
2. **Monitor SSH activity** — detect unauthorized login attempts, repeated failures, and successful logins from unusual IPs.
3. **Monitor authentication events** — track `sudo` usage, user switches, PAM failures, and account lockouts.
4. **Monitor HTTP traffic** — detect abnormal request volumes, 4xx/5xx error spikes, and potential DDoS patterns.
5. **Build interactive dashboards** in Splunk for real-time visibility into system security.
6. **Set up automated alerts** that trigger on brute-force or DDoS attack signatures.

### Secondary Objectives

- Gain hands-on experience with Splunk installation, configuration, and SPL (Search Processing Language).
- Practice log forwarding across heterogeneous Linux environments (Debian, Ubuntu, Rocky Linux).
- Understand firewall configuration for secure log forwarding (especially on RHEL-based systems).
- Demonstrate practical SIEM skills for a cybersecurity portfolio.

---

## Scope

| In Scope | Out of Scope |
|---|---|
| SSH, Auth, HTTP log collection | Windows event logs |
| Splunk Free / Enterprise setup | Paid Splunk Cloud |
| 3–4 Linux client machines | Network device logs (routers/switches) |
| Brute-force & DDoS alerting | EDR / endpoint protection |
| Splunk dashboards | SOAR / automated remediation |

---

## Problem Statement

In real-world enterprise environments, logs are generated across dozens or hundreds of systems. Without centralized collection and correlation, detecting threats like brute-force attacks, privilege escalation, or DDoS attempts is extremely difficult. This project simulates that environment at a smaller scale — demonstrating how a SIEM platform bridges that gap.

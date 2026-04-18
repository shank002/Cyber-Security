# 🔐 Cybersecurity Portfolio

> A collection of hands-on cybersecurity projects, CTF write-ups, and practical implementations — built to demonstrate real-world security skills.

---

## 👤 About Me

I'm a cybersecurity enthusiast focused on offensive and defensive security. This repository documents my learning journey through Capture The Flag competitions, SIEM implementations, and security research.

---

## 📁 Repository Structure

```
cybersecurity-portfolio/
│
├── picoCTF/
│   ├── cryptography/
│   ├── reverse-engineering/
│   ├── binary-exploitation/
│   ├── forensics/
│   └── web-exploitation/
│
└── siem-splunk/
    ├── docs/
    ├── configs/
    ├── scripts/
    └── dashboards/
```

---

## 🏁 picoCTF Write-Ups

[picoCTF](https://picoctf.org/) is a beginner-friendly Capture The Flag competition by Carnegie Mellon University. Each write-up documents the challenge, my thought process, tools used, and the solution.

---

### 🔑 Cryptography

Challenges involving encryption, encoding, ciphers, and cryptographic protocols.

| Challenge | Difficulty | Topics | Status |
|---|---|---|---|
| *Coming soon* | — | Caesar cipher, XOR, RSA, Base64 | 🔄 |

**Tools & Techniques used:**
- CyberChef, Python, OpenSSL
- RSA factorization, frequency analysis
- XOR decryption, Base64/hex decoding

---

### ⚙️ Reverse Engineering

Challenges involving binary analysis, disassembly, and understanding compiled code.

| Challenge | Difficulty | Topics | Status |
|---|---|---|---|
| *Coming soon* | — | ELF binaries, disassembly, patching | 🔄 |

**Tools & Techniques used:**
- Ghidra, GDB, `strings`, `file`, `ltrace`, `strace`
- Static and dynamic analysis
- Assembly reading (x86/x64)

---

### 💥 Binary Exploitation

Challenges involving memory corruption, buffer overflows, and exploit development.

| Challenge | Difficulty | Topics | Status |
|---|---|---|---|
| *Coming soon* | — | Buffer overflow, ret2win, shellcode | 🔄 |

**Tools & Techniques used:**
- pwntools, GDB + pwndbg / peda
- Buffer overflow, stack smashing
- Return-oriented programming (ROP)
- ASLR, NX, stack canary bypass techniques

---

### 🔍 Forensics

Challenges involving file analysis, steganography, packet captures, and memory dumps.

| Challenge | Difficulty | Topics | Status |
|---|---|---|---|
| *Coming soon* | — | Wireshark, steganography, file carving | 🔄 |

**Tools & Techniques used:**
- Wireshark, Autopsy, Volatility
- `exiftool`, `binwalk`, `foremost`, `xxd`
- Steganography (LSB, image metadata)
- PCAP analysis, disk image forensics

---

### 🌐 Web Exploitation

Challenges involving web application vulnerabilities and server-side attacks.

| Challenge | Difficulty | Topics | Status |
|---|---|---|---|
| *Coming soon* | — | SQLi, XSS, IDOR, path traversal | 🔄 |

**Tools & Techniques used:**
- Burp Suite, curl, browser DevTools
- SQL injection, XSS, CSRF
- Cookie manipulation, JWT attacks
- Directory traversal, IDOR, SSRF

---

## 🛡️ SIEM Dashboard — Splunk

A full SIEM implementation using Splunk for centralized log collection, monitoring, and threat detection across multiple Linux systems.

**Highlights:**
- Centralized log ingestion from Ubuntu, Debian, and Rocky Linux via Splunk Universal Forwarder
- Real-time dashboards for SSH login attempts, auth events, and HTTP traffic
- Automated alerts for SSH brute-force attacks and DDoS activity
- Firewall configuration for `ufw` (Debian/Ubuntu) and `firewalld` (RHEL/Rocky)
- Custom Python SSH auto-login tool with structured JSON logging

📂 See [`siem-splunk/`](./siem-splunk/) for full documentation, configs, scripts, and dashboards.

---

## 🧰 Tools & Technologies

| Category | Tools |
|---|---|
| **CTF & Exploitation** | pwntools, GDB, pwndbg, Ghidra, Burp Suite |
| **Forensics** | Wireshark, Volatility, Autopsy, binwalk, exiftool |
| **Cryptography** | CyberChef, Python, OpenSSL, hashcat |
| **SIEM / Logging** | Splunk Enterprise, Universal Forwarder, SPL |
| **Scripting** | Python 3, Bash |
| **OS / Platforms** | Ubuntu, Debian, Rocky Linux, Kali Linux |

---

## 📊 Skills Demonstrated

- 🔓 Offensive security — exploitation, reverse engineering, web attacks
- 🔎 Digital forensics — artifact analysis, PCAP inspection, steganography
- 🛡️ Defensive security — SIEM, log monitoring, alerting
- 🐧 Linux administration — multi-distro, firewall, service management
- 🐍 Scripting — Python automation, Bash scripting
- 📡 Networking — TCP/IP, HTTP, packet analysis

---

## 📌 Notes

- All challenges solved are from legal, authorized platforms (picoCTF, etc.)
- Write-ups are for educational purposes only
- No real systems were targeted without authorization

---

*Continuously updated as new challenges are solved and projects are completed.*

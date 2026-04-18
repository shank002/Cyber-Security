# bytemancy 1 — picoCTF 2026

## Challenge Info

| Field | Details |
|-------|---------|
| **Category** | General Skills |
| **Difficulty** | Easy |
| **Points** | 100 |
| **Solves** | 4,560 |
| **Author** | picoCTF |

## Description

> The byte conjuring continues! Can you handle multiple rounds?
> Connect to the program with netcat: `nc <host> <port>`

**Hint:**
1. Build on your solution from bytemancy 0.
2. A Python script using `pwntools` or pipes can automate multi-round input.

---

## Objective

Connect to a remote service that presents multiple sequential rounds — each round asks you to send specific ASCII decimal values as their character equivalents. Unlike bytemancy 0 (single static input), bytemancy 1 requires **dynamic responses** across multiple rounds, making automation essential.

---

## Tools Used

- `netcat (nc)` — connect to the challenge
- **Python** with `pwntools` — automate multi-round interaction
- ASCII encoding knowledge

---

## Understanding the Challenge

The server sends prompts like:

```
Send me ASCII DECIMAL 72, 101, 108, side-by-side, no space.
```

Each round the decimal values change. You must:
1. Parse the three decimal values from the prompt.
2. Convert each to its ASCII character (`chr()` in Python).
3. Send the result back before the timeout.

Repeat for all rounds to receive the flag.

---

## Solution

### Manual approach (for understanding)

For a prompt like `Send me ASCII DECIMAL 72, 101, 108`:
- 72 → `H`
- 101 → `e`
- 108 → `l`
- Answer: `Hel`

### Automated Python script (recommended)

```python
from pwn import *

# Replace with actual host and port
conn = remote('<host>', <port>)

while True:
    line = conn.recvline().decode()
    print(line, end='')

    if 'Send me ASCII DECIMAL' in line:
        # Extract the three decimal numbers
        import re
        nums = re.findall(r'\d+', line)
        # Convert each to its ASCII character
        response = ''.join(chr(int(n)) for n in nums)
        print(f"Sending: {response}")
        conn.sendline(response.encode())

    if 'picoCTF' in line:
        print("FLAG:", line)
        break

conn.close()
```

### Run the script

```bash
python3 solve.py
```

Output:
```
Sending: Hel
Sending: lo!
...
picoCTF{...}
```

> **Screenshot:** See `screenshots/python-solve.png`

---

## Key Takeaways

- **Scripted interaction** with network services is a core CTF and real-world pentesting skill. Tools like `pwntools` make it much easier to send/receive data programmatically.
- **`chr()` and `ord()`** in Python allow fast conversion between ASCII integers and characters — essential for encoding/decoding challenges.
- **Regular expressions (`re`)** are useful for parsing structured text responses from servers.
- This challenge is a stepping stone toward binary exploitation where `pwntools` is used to interact with vulnerable programs precisely and automatically.
- Automation becomes necessary when challenges have timeouts, randomised inputs, or hundreds of rounds.

---

## References

- [pwntools documentation](https://docs.pwntools.com/)
- [Python `chr()` function](https://docs.python.org/3/library/functions.html#chr)
- [Python `re` module](https://docs.python.org/3/library/re.html)
- [ASCII Table](https://www.asciitable.com/)

---

*[← Back to index](../../README.md)*

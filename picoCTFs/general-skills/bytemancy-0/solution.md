# bytemancy 0 — picoCTF 2026

## Challenge Info

| Field | Details |
|-------|---------|
| **Category** | General Skills |
| **Difficulty** | Easy |
| **Points** | 50 |
| **Solves** | 5,242 |
| **Author** | picoCTF |

## Description

> Can you conjure the right bytes?
> The program's source code can be downloaded.
> Connect to the program with netcat: `nc <host> <port>`

**Hint:**
1. Solving this with a one-liner will help with the next challenge in this series.

---

## Objective

Connect to a remote service that asks you to send specific ASCII decimal values as their character equivalents, and retrieve the flag.

---

## Tools Used

- `netcat (nc)` — connect to the challenge
- Knowledge of ASCII encoding
- (Optional) Python for a one-liner solution

---

## Understanding the Source Code

```python
while(True):
    try:
        print('⊹──────[ BYTEMANCY-0 ]──────⊹')
        print("☍⟐☉⟊☽☈⟁⧋⟡☍⟐☉⟊☽☈⟁⧋⟡☍⟐☉⟊☽☈⟁⧋⟡☍⟐")
        print()
        print('Send me ASCII DECIMAL 101, 101, 101, side-by-side, no space.')
        print()
        print("☍⟐☉⟊☽☈⟁⧋⟡☍⟐☉⟊☽☈⟁⧋⟡☍⟐☉⟊☽☈⟁⧋⟡☍⟐")
        print('⊹─────────────⟡─────────────⊹')
        user_input = input('==> ')
        if user_input == "\x65\x65\x65":
            print(open("./flag.txt", "r").read())
            break
        ...
```

The program expects the **characters** corresponding to ASCII decimal `101, 101, 101`.
- ASCII 101 = `e`
- So we need to send: `eee`

The check `"\x65\x65\x65"` confirms this — `0x65` in hex is `101` in decimal, which is the character `e`.

---

## Solution

### Method 1 — Manual input

```bash
nc <host> <port>
```

When prompted, type:
```
eee
```

```
==> eee
picoCTF{...}
```

### Method 2 — Python one-liner (recommended for bytemancy 1)

```bash
python3 -c "print('eee')" | nc <host> <port>
```

> **Screenshot:** See `screenshots/terminal-solution.png`

---

## Key Takeaways

- **ASCII encoding** is foundational in cybersecurity. Every character has a decimal, hex, and binary representation. Knowing the ASCII table (or how to convert quickly) is an essential skill.
- Decimal `101` → Hex `0x65` → Character `e`. The program checks `\x65\x65\x65`, confirming the equivalence.
- The hint about using a "one-liner" is a nudge toward using Python piped into netcat — a technique essential for the harder `bytemancy 1` challenge.
- This is an introduction to **byte-level thinking**, which becomes critical in binary exploitation and cryptography challenges.

---

## References

- [ASCII Table](https://www.asciitable.com/)
- [Python `chr()` function](https://docs.python.org/3/library/functions.html#chr)
- [netcat usage guide](https://linux.die.net/man/1/nc)

---

*[← Back to index](../../README.md)*

# MultiCode — picoCTF 2026

## Challenge Info

| Field | Details |
|-------|---------|
| **Category** | General Skills |
| **Difficulty** | Easy |
| **Points** | 200 |
| **Solves** | 3,936 |
| **Author** | picoCTF |

## Description

> Can you decode this? The flag has been encoded multiple times using different schemes. Figure out each encoding layer and peel them back to reveal the original flag.

**File provided:** Encoded string / file download

---

## Objective

Identify multiple layers of encoding applied to the flag (e.g., base64, hex, binary, URL encoding, etc.) and decode each layer in the correct order to reveal the original `picoCTF{...}` flag.

---

## Tools Used

- **CyberChef** — browser-based multi-step decoding tool
- **Python** — for scripted decoding
- Knowledge of common encodings: base64, hex, binary, URL encoding, ROT13

---

## Identifying the Encodings

When faced with an unknown encoded string, look for these clues:

| Pattern | Likely Encoding |
|---------|----------------|
| Only `A-Z`, `a-z`, `0-9`, `+`, `/`, `=` | Base64 |
| Only `0-9`, `a-f`, `A-F` with even length | Hex |
| Only `0` and `1` | Binary |
| `%XX` patterns | URL encoding |
| Only `A-Za-z` shifts by 13 | ROT13 |
| `&#XX;` patterns | HTML entities |

---

## Solution

### Step 1 — Examine the encoded string

Download the file or copy the encoded string from the challenge. Example:

```
NTY2OTYzNmY0MzU0NDYzYTZlMzM3NzMwNzI2YjVmNzc...
```

### Step 2 — Use CyberChef's "Magic" operation

1. Go to [CyberChef](https://gchq.github.io/CyberChef/)
2. Paste your encoded string in the **Input** box
3. Search for **"Magic"** in the operations panel and drag it in
4. Enable **"Intensive mode"** — CyberChef will auto-detect encoding layers

CyberChef's Magic mode often identifies multi-layer encodings automatically.

### Step 3 — Manual decode approach (Python)

If you prefer scripting, identify and peel each layer:

```python
import base64
import binascii

encoded = "NTY2OTYzNmY0MzU0NDYzYTZlMzM3NzMwNzI2YjVmNzc..."

# Layer 1: Base64 decode
layer1 = base64.b64decode(encoded).decode()
print("Layer 1:", layer1)

# Layer 2: Hex decode
layer2 = bytes.fromhex(layer1).decode()
print("Layer 2:", layer2)

# Layer 3: Binary decode (if applicable)
layer3 = ''.join(chr(int(layer2[i:i+8], 2)) for i in range(0, len(layer2), 8))
print("Layer 3:", layer3)
```

Adjust layers based on what you discover at each step. Stop when you see `picoCTF{`.

### Step 4 — Retrieve the flag

After fully decoding all layers:

```
picoCTF{...}
```

> **Screenshot:** See `screenshots/cyberchef-decode.png`

---

## Example decode chain

```
Base64 → "5669634f54467b6e33..." (looks like hex)
Hex    → "VicOTF{n3..." (looks like base64)  
Base64 → "picoCTF{m...}" ✅
```

---

## Key Takeaways

- **Multi-layer encoding** is extremely common in CTFs and real-world obfuscation (malware often uses nested encoding to hide payloads from antivirus).
- **CyberChef** is the go-to tool for encoding/decoding puzzles — bookmark it. Its "Magic" feature can auto-identify many encoding schemes.
- Recognising encoding signatures (character sets, padding, length patterns) is a skill that improves with practice.
- In incident response, understanding how attackers encode C2 traffic and payloads is essential — this challenge builds that exact muscle.
- **Never confuse encoding with encryption** — base64/hex/binary are reversible without a key. Encryption requires a key to reverse.

---

## References

- [CyberChef](https://gchq.github.io/CyberChef/)
- [Base64 explained](https://en.wikipedia.org/wiki/Base64)
- [Python `base64` module](https://docs.python.org/3/library/base64.html)
- [Python `binascii` module](https://docs.python.org/3/library/binascii.html)
- [Encoding vs Encryption](https://danielmiessler.com/study/encoding-encryption-hashing-obfuscation/)

---

*[← Back to index](../../README.md)*

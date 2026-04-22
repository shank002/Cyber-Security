# shared-secret — picoCTF 2026

## Challenge Info

| Field | Details |
|-------|---------|
| **Category** | Cryptography |
| **Difficulty** | Easy |
| **Points** | 100 |
| **Author** | picoCTF |

## Description

> Someone encrypted a message using AES, but they weren't very careful with their key. Turns out the key is derived from something as simple as the current time! Can you uncover the key and decrypt the flag?
>
> Files provided: `message` (ciphertext), `code` (encryption script)

---

## Objective

Analyse the encryption script to understand how the AES key was derived (SHA-256 of a Unix timestamp), then brute-force timestamps within a small window around the provided hint timestamp to recover the key and decrypt the flag.

---

## Background — The Vulnerability

The encryption script works like this:

```python
from hashlib import sha256
from Crypto.Cipher import AES
from Crypto.Util.Padding import pad
import time

def encrypt(plaintext, timestamp):
    key = sha256(str(timestamp).encode()).digest()[:16]  # AES-128 key from timestamp
    cipher = AES.new(key, AES.MODE_ECB)
    padded = pad(plaintext.encode(), AES.block_size)
    return cipher.encrypt(padded).hex()
```

The key is: **`SHA-256(unix_timestamp)[:16]`**

This is a critically weak key derivation because:
- Unix timestamps are integers with ~1 billion possible values total
- If the encryption time is known (even approximately), the search space collapses to just a few thousand candidates
- The script even hints at the timestamp in its output!

---

## Tools Used

- **Python 3** — write the brute-force decryption script
- **pycryptodome** — AES decryption (`AES.MODE_ECB`)
- `hashlib` — SHA-256 key derivation

---

## Solution

### Step 1 — Read the provided files

The `message` file contains the hex ciphertext and a hint:
```
Hint: The encryption was done around 1770242615 UTC
Ciphertext (hex): 24823b2b2d104b36ad2078cafc8d98f22488e78df83b29f507d9b910ad51a464
```

### Step 2 — Understand the key space

The key is `sha256(str(timestamp))[:16]`. Since the hint gives us a timestamp, we only need to check a window of ±1000 seconds around it — 2001 possible keys, which runs in milliseconds.

### Step 3 — Write the brute-force script

```python
import hashlib
from Crypto.Cipher import AES
from Crypto.Util.Padding import unpad

# Values from provided files
ciphertext = bytes.fromhex("24823b2b2d104b36ad2078cafc8d98f22488e78df83b29f507d9b910ad51a464")
base_timestamp = 1770242615

print("[*] Starting brute force...")

for offset in range(-1000, 1001):
    ts = base_timestamp + offset

    # Derive key exactly as the encryption script does
    key = hashlib.sha256(str(ts).encode()).digest()[:16]
    cipher = AES.new(key, AES.MODE_ECB)

    decrypted_padded = cipher.decrypt(ciphertext)

    # Look for the picoCTF flag signature
    if b"picoCTF{" in decrypted_padded:
        try:
            plaintext = unpad(decrypted_padded, AES.block_size).decode()
            print(f"\n[+] Found at timestamp offset {offset:+d} (ts={ts})")
            print(f"[+] Flag: {plaintext}")
            break
        except Exception:
            pass
```

### Step 4 — Run the script

```bash
pip install pycryptodome
python3 solve.py
```

Output:
```
[*] Starting brute force...
[+] Found at timestamp offset +3 (ts=1770242618)
[+] Flag: picoCTF{...}
```

> **Screenshot:** See `screenshots/brute-force-output.png`

---

## Key Takeaways

- **Never use time as a cryptographic key source.** Unix timestamps are predictable, low-entropy values. A proper key should come from a cryptographically secure random number generator (CSPRNG), such as `os.urandom()` in Python or `/dev/urandom` on Linux.
- **AES-ECB mode is deterministic** — identical plaintext blocks always produce identical ciphertext blocks, making it vulnerable to pattern analysis. Prefer **AES-CBC** or **AES-GCM** for real encryption.
- **Key derivation must use entropy, not predictable values.** Proper key derivation uses KDFs (Key Derivation Functions) like PBKDF2, scrypt, or Argon2 combined with a random salt.
- This vulnerability class is related to **IV/nonce reuse** and **time-based seed attacks**, which have been exploited in real-world systems — most famously in the Debian OpenSSL vulnerability (2008) where a code change accidentally limited randomness to just 32,768 possible values.
- **Diffie-Hellman** context: the challenge name "shared-secret" refers to the Diffie-Hellman key exchange, where two parties derive a shared secret over an insecure channel. This challenge demonstrates that even when a shared secret exists, how it's used as a key matters enormously.

---

## References

- [AES documentation (PyCryptodome)](https://pycryptodome.readthedocs.io/en/latest/src/cipher/AES.html)
- [hashlib — SHA-256](https://docs.python.org/3/library/hashlib.html)
- [NIST — Key Derivation Functions](https://csrc.nist.gov/Projects/Key-Derivation)
- [Debian OpenSSL vulnerability (2008)](https://www.schneier.com/blog/archives/2008/05/random_number_b.html)
- [AES-ECB mode weakness explained](https://crypto.stackexchange.com/questions/20941/why-shouldnt-i-use-ecb-encryption)
- [Diffie-Hellman Key Exchange explained](https://en.wikipedia.org/wiki/Diffie%E2%80%93Hellman_key_exchange)

---

*[← Back to Cryptography index](../README.md)*

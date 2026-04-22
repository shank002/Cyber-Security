# rsa_can_be_broken — picoCTF 2025

## Challenge Info

| Field | Details |
|-------|---------|
| **Category** | Cryptography |
| **Difficulty** | Easy |
| **Points** | 100 |
| **Author** | picoCTF |

## Description

> This service provides you an encrypted flag. Can you decrypt it with just N and e?
>
> Connect: `nc <host> <port>`

---

## Objective

Connect to a service that provides RSA parameters `N`, `e`, and a ciphertext. Exploit a critical flaw in the key generation — the modulus `N` is **even**, meaning one prime factor is `2` — to trivially factor `N`, recover the private key, and decrypt the flag.

---

## Background — RSA Basics

RSA encryption works as follows:

1. Choose two large distinct **odd** primes `p` and `q`
2. Compute modulus: `N = p * q`
3. Compute Euler's totient: `φ(N) = (p-1) * (q-1)`
4. Choose public exponent `e` (commonly `65537`)
5. Compute private exponent: `d ≡ e⁻¹ (mod φ(N))`
6. **Encrypt:** `c = m^e mod N`
7. **Decrypt:** `m = c^d mod N`

RSA's security relies entirely on the difficulty of factoring `N`. Since both `p` and `q` are **odd** primes, `N` must always be **odd**. An even `N` immediately reveals that one factor is `2`.

---

## Tools Used

- `netcat (nc)` — connect to the service
- **Python 3** — write the decryption script
- **pycryptodome** — `long_to_bytes` conversion
- `math.gcd` / `pow()` — built-in Python functions

---

## Solution

### Step 1 — Connect and collect parameters

```bash
nc <host> <port>
```

Output:
```
N: 24404956027156134476143231215895846582239521206409319184284390135039587462032227991822287341092496750794957271366437699913654087559242283610254440132139442
e: 65537
cyphertext: 2214364248004673246638538960542510810518776565519600085199989457265979994903880...
```

### Step 2 — Spot the vulnerability

Check if `N` is even:
```python
N % 2 == 0  # True!
```

Since **2 is the only even prime**, if `N` is even then `p = 2` and `q = N // 2`.

### Step 3 — Write the decryption script

```python
from Crypto.Util.number import long_to_bytes

# Values from the server (replace with your actual values)
N = 24404956027156134476143231215895846582239521206409319184284390135039587462032227991822287341092496750794957271366437699913654087559242283610254440132139442
e = 65537
c = 2214364248004673246638538960542510810518776565519600085199989457265979994903880...

# Step 1: Factor N (trivial since N is even)
p = 2
q = N // p

# Step 2: Compute Euler's totient
phi = (p - 1) * (q - 1)

# Step 3: Compute private key d
d = pow(e, -1, phi)  # Python 3.8+ supports modular inverse directly

# Step 4: Decrypt
m = pow(c, d, N)

# Step 5: Convert integer to readable bytes
print(long_to_bytes(m).decode())
```

### Step 4 — Run the script

```bash
pip install pycryptodome
python3 solve.py
```

Output:
```
picoCTF{...}
```

> **Screenshot:** See `screenshots/script-output.png`

---

## Key Takeaways

- **RSA's security is entirely dependent on the difficulty of factoring N**. If `N` can be factored — even trivially as in this case — the encryption is completely broken.
- **2 is the only even prime.** Every properly generated RSA key will have an odd `N` because both `p` and `q` are large odd primes. Checking `N % 2 == 0` is the first thing to test when given an unknown RSA modulus.
- This is an example of **weak key generation** — a real-world class of vulnerability. In 2012, researchers found that millions of RSA public keys on the internet shared prime factors due to poor entropy during key generation, allowing mass decryption.
- **Never roll your own RSA implementation.** Use well-tested libraries like OpenSSL, PyCryptodome, or Python's `cryptography` package which use cryptographically secure prime generation (Miller-Rabin primality tests, OS-level entropy sources).
- **Textbook RSA** (no padding) is deterministic and vulnerable to multiple attacks beyond just weak primes. In real systems, RSA should always be used with **OAEP padding**.
- Tools like **FactorDB** and **RsaCtfTool** can automate many common RSA attacks in CTF settings.

---

## References

- [RsaCtfTool — automated RSA attacks](https://github.com/RsaCtfTool/RsaCtfTool)
- [FactorDB — precomputed factorizations](http://factordb.com/)
- [pycryptodome — long_to_bytes](https://pycryptodome.readthedocs.io/)
- [RSA key generation vulnerability (2012 paper)](https://factorable.net/)
- [OWASP — RSA Best Practices](https://cheatsheetseries.owasp.org/cheatsheets/Cryptographic_Storage_Cheat_Sheet.html)

---

*[← Back to Cryptography index](../README.md)*

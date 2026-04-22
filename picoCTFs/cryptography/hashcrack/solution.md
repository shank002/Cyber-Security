# hashcrack — picoCTF 2025

## Challenge Info

| Field | Details |
|-------|---------|
| **Category** | Cryptography |
| **Difficulty** | Easy |
| **Points** | 50 |
| **Author** | picoCTF |

## Description

> A company stored a secret message on a server which got breached due to the admin using weakly hashed passwords. Can you gain access to the secret stored within the server?
>
> Connect: `nc <host> <port>`

---

## Objective

Connect to a remote service that presents three sequential password hashes (MD5 → SHA-1 → SHA-256). Crack each one using online lookup tools or offline cracking tools to retrieve the flag revealed after the final hash.

---

## Tools Used

- `netcat (nc)` — connect to the service
- **CrackStation** (`crackstation.net`) — online hash lookup (rainbow tables)
- **hashcat** — offline GPU-accelerated cracker (alternative)
- **hashid** / **hash-identifier** — identify hash type from length

---

## Identifying Hash Types by Length

| Hash Length (hex chars) | Algorithm |
|------------------------|-----------|
| 32 | MD5 |
| 40 | SHA-1 |
| 64 | SHA-256 |
| 128 | SHA-512 |

---

## Solution

### Step 1 — Connect to the service

```bash
nc <host> <port>
```

Output:
```
Welcome!! Looking For the Secret?
We have identified a hash: 482c811da5d5b4bc6d497ffa98491e38
Enter the password for identified hash:
```

### Step 2 — Identify and crack the MD5 hash

The 32-character hex string is **MD5**.

Go to [CrackStation](https://crackstation.net), paste the hash, and click **Crack Hashes**.

Result: `482c811da5d5b4bc6d497ffa98491e38` → **`password123`**

Submit it to the server:
```
Enter the password for identified hash: password123
Correct! You've cracked the MD5 hash with no secret found!
Flag is yet to be revealed!!
```

### Step 3 — Crack the SHA-1 hash

Next hash presented (40 chars = **SHA-1**):
```
Crack this hash: b7a875fc1ea228b9061041b7cec4bd3c52ab3ce3
```

Paste into CrackStation → **`letmein`**

```
Enter the password for the identified hash: letmein
Correct! You've cracked the SHA-1 hash with no secret found!
Almost there!!
```

### Step 4 — Crack the SHA-256 hash

Final hash (64 chars = **SHA-256**):
```
Crack this hash: 916e8c4f79b25028c9e467f1eb8eee6d6bbdff965f9928310ad30a8d88697745
```

Paste into CrackStation → **`qwerty098`**

```
Enter the password for the identified hash: qwerty098
Correct! You've cracked the SHA-256 hash with a secret found.
The flag is: picoCTF{...}
```

> **Screenshot:** See `screenshots/crackstation-md5.png` and `screenshots/flag.png`

---

### Alternative — Offline with hashcat

```bash
# MD5
hashcat -m 0 482c811da5d5b4bc6d497ffa98491e38 /usr/share/wordlists/rockyou.txt

# SHA-1
hashcat -m 100 b7a875fc1ea228b9061041b7cec4bd3c52ab3ce3 /usr/share/wordlists/rockyou.txt

# SHA-256
hashcat -m 1400 916e8c4f79b25028c9e467f1eb8eee6d6bbdff965f9928310ad30a8d88697745 /usr/share/wordlists/rockyou.txt
```

---

## Key Takeaways

- **MD5 and SHA-1 are broken** for password storage — not because they can be mathematically reversed, but because they are fast to compute, enabling billions of guesses per second on modern GPUs. Entire databases of pre-computed hashes (rainbow tables) exist online.
- **CrackStation** works by maintaining a massive database of precomputed hashes of common passwords. If the password was ever in a wordlist, it's likely already in their database.
- **Hashcat** with `rockyou.txt` is the offline workhorse — it tests millions of password candidates per second against any hash format.
- This challenge directly simulates a **credential breach scenario**: an attacker gains access to a hashed password database and uses lookup tables to recover plaintext passwords.
- Modern password storage should use **bcrypt**, **scrypt**, or **Argon2** — these are slow-by-design algorithms that make brute-force attacks computationally expensive even with GPUs.
- Recognising hash types by length is a fundamental skill in forensics, incident response, and penetration testing.

---

## References

- [CrackStation](https://crackstation.net/)
- [Hashcat documentation](https://hashcat.net/wiki/)
- [hash-identifier tool](https://github.com/blackploit/hash-identifier)
- [OWASP — Password Storage Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Password_Storage_Cheat_Sheet.html)
- [Why MD5 is broken for passwords](https://security.stackexchange.com/questions/19906/is-md5-considered-insecure)

---

*[← Back to Cryptography index](../README.md)*

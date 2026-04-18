# Password Profiler — picoCTF 2026

## Challenge Info

| Field | Details |
|-------|---------|
| **Category** | General Skills |
| **Difficulty** | Easy |
| **Points** | 100 |
| **Solves** | 3,307 |
| **Author** | picoCTF |

## Description

> We intercepted a suspicious file from a system, but instead of the password itself, it only contains its SHA-1 hash. Using OSINT techniques, you are provided with personal details about the target. Your task is to leverage this information to generate a custom password list and recover the original password by matching its hash.

**Files provided:**
- `userinfo` — Personal details about the target
- `hash` — SHA-1 hash of the password
- `check_password` — Script to test passwords against the hash

**Hint:**
1. [CUPP](https://github.com/Mebus/cupp) is a Python tool for generating custom wordlists from personal data.

---

## Objective

Use OSINT-style personal information to generate a targeted wordlist with CUPP, then crack the SHA-1 hash to recover the password.

---

## Tools Used

- **CUPP** (Common User Passwords Profiler) — generate targeted wordlist
- **Python** — run scripts
- **SHA-1 hash comparison** — via the provided `check_password` script
- `grep` / bash — search wordlist

---

## Solution

### Step 1 — Examine provided files

**userinfo:**
```
First Name: Alice
Surname: Johnson
Nickname: AJ
Birthdate: 15-07-1990
Partner's Name: Bob
Child's Name: Charlie
```

**hash:**
```
968c2349040273dd57dc4be7e238c5ac200ceac5
```

### Step 2 — Install and run CUPP

```bash
git clone https://github.com/Mebus/cupp.git
cd cupp
python3 cupp.py -i
```

Fill in the fields using the information from `userinfo`:

```
> First Name: Alice
> Surname: Johnson
> Nickname: AJ
> Birthdate (DDMMYYYY): 15071990
> Partners) name: Bob
> Partners) nickname: [Enter]
> Partners) birthdate: [Enter]
> Child's name: Charlie
> Child's nickname: [Enter]
> Child's birthdate: [Enter]
> Pet's name: [Enter]
> Company name: [Enter]
> Do you want to add some keywords about the victim? [Enter]
> Do you want to add special chars? [y/n]: y
> Do you want to add random numbers? [y/n]: y
> Leet mode? [y/n]: y
```

CUPP generates `alice.txt` containing hundreds of candidate passwords derived from the personal information.

### Step 3 — Use check_password to find the match

```bash
python3 check_password alice.txt
```

Or manually check with the provided script — it compares SHA-1 hashes until a match is found:

```bash
while IFS= read -r pw; do
  hash=$(echo -n "$pw" | sha1sum | awk '{print $1}')
  if [ "$hash" = "968c2349040273dd57dc4be7e238c5ac200ceac5" ]; then
    echo "FOUND: $pw"
    break
  fi
done < alice.txt
```

### Step 4 — Retrieve the flag

Once the matching password is found and submitted to the challenge, the flag is returned:

```
picoCTF{...}
```

> **Screenshot:** See `screenshots/cupp-wordlist.png` and `screenshots/hash-match.png`

---

## Key Takeaways

- **CUPP** automates the creation of targeted wordlists using personal information — a key OSINT technique used in real-world password auditing.
- **SHA-1** is a cryptographic hash function — it's one-way (you can't reverse it), but with a targeted wordlist you can find the original by hashing candidates and comparing.
- This technique is widely used in penetration testing when you have a hash and personal information about a target. Tools like `hashcat` and `John the Ripper` can accelerate this at scale.
- This challenge demonstrates why **generic dictionary attacks fail** against targeted passwords — and why **custom wordlists based on OSINT** are far more effective.
- In the real world, CUPP-style profiling is part of pre-attack reconnaissance in social engineering and credential attacks.

---

## References

- [CUPP GitHub](https://github.com/Mebus/cupp)
- [SHA-1 explained](https://en.wikipedia.org/wiki/SHA-1)
- [Hashcat — password recovery tool](https://hashcat.net/hashcat/)
- [OWASP - Password Cracking](https://owasp.org/www-community/attacks/Password_Cracking)

---

*[← Back to index](../../README.md)*

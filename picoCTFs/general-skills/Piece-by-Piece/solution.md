# Piece by Piece — picoCTF 2026

## Challenge Info

| Field | Details |
|-------|---------|
| **Category** | General Skills |
| **Difficulty** | Easy |
| **Points** | 50 |
| **Solves** | 5,847 |
| **Author** | picoCTF |

## Description

> After logging in, you will find multiple file parts in your home directory. These parts need to be combined and extracted to reveal the flag.
> SSH to `<host>:<port>` and login as `ctf-player` with the provided password.

---

## Objective

SSH into the server, find split archive files, combine them into one zip, extract it with the given password, and read the flag from the resulting text file.

---

## Tools Used

- `ssh` — connect to the remote server
- `cat` with wildcard — concatenate file parts
- `unzip` — extract a password-protected zip
- Standard Linux commands: `ls`, `cat`

---

## Solution

### Step 1 — Connect via SSH

```bash
ssh ctf-player@<host> -p <port>
```

### Step 2 — List the files

```bash
ctf-player@pico-chall:~$ ls
instructions.txt  part_aa  part_ab  part_ac  part_ad  part_ae
```

### Step 3 — Read the instructions

```bash
ctf-player@pico-chall:~$ cat instructions.txt
Hint:
- The flag is split into multiple parts as a zipped file.
- Use Linux commands to combine the parts into one file.
- The zip file is password protected. Use this "supersecret" password to extract the zip file.
- After unzipping, check the extracted text file for the flag.
```

### Step 4 — Combine the parts

The wildcard `*` expands alphabetically, so `part_a*` covers `part_aa`, `part_ab`, `part_ac`, etc. in correct order.

```bash
cat part_a* > part.zip
```

### Step 5 — Unzip with the password

```bash
unzip part.zip
```

When prompted for a password, enter `supersecret`:

```
Archive:  part.zip
[part.zip] flag.txt password:
  extracting: flag.txt
```

### Step 6 — Read the flag

```bash
cat flag.txt
picoCTF{...}
```

> **Screenshot:** See `screenshots/terminal-solution.png`

---

## Key Takeaways

- **Split archives** are commonly used when files are too large for a single transfer. The `cat` command can reassemble them reliably in order when using wildcards.
- **Password-protected zips** are a common way to secure files — but the password must be communicated securely. Here the hint gave it away directly.
- Understanding **file naming conventions** (e.g., `part_aa`, `part_ab`) is important — tools like `split` produce these automatically and `cat part_a*` reassembles them.
- This challenge mirrors real-world forensics scenarios where data is found split across multiple files.

---

## References

- [Linux `cat` command](https://linux.die.net/man/1/cat)
- [Linux `unzip` command](https://linux.die.net/man/1/unzip)
- [Linux `split` command](https://linux.die.net/man/1/split) (used to create such files)

---

*[← Back to index](../../README.md)*

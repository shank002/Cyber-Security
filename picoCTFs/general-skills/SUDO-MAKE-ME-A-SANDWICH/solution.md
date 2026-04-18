# SUDO MAKE ME A SANDWICH — picoCTF 2026

## Challenge Info

| Field | Details |
|-------|---------|
| **Category** | General Skills |
| **Difficulty** | Easy |
| **Points** | 50 |
| **Solves** | 6,395 |
| **Author** | picoCTF |

## Description

> Can you read the flag? I think you can!
> `ssh -p <port> ctf-player@<host>` using password `<provided>`

**Hints:**
1. What is sudo?
2. How do you know what permissions you have?

---

## Objective

Connect via SSH to a remote machine, discover that `flag.txt` is only readable by root, and find a way to read it using `sudo`.

---

## Tools Used

- `ssh` — connect to the remote server
- `sudo` — run commands with elevated privileges
- `emacs` — text editor that can be launched with sudo

---

## Solution

### Step 1 — Connect via SSH

```bash
ssh -p <port> ctf-player@<host>
```
Enter the provided password when prompted.

### Step 2 — Check the directory

```bash
ctf-player@challenge:~$ ls -l
total 4
-r--r----- 1 root root 31 Mar  9 21:32 flag.txt
```

The flag file exists but is owned by `root` with permissions `r--r-----` — only root can read it. Trying `cat flag.txt` gives a permission denied error.

### Step 3 — Check sudo privileges

```bash
ctf-player@challenge:~$ sudo -l
```

Output:
```
User ctf-player may run the following commands on challenge:
    (ALL) NOPASSWD: /bin/emacs
```

We can run `emacs` as root with no password!

### Step 4 — Open the flag with sudo emacs

```bash
sudo /bin/emacs flag.txt
```

The flag is displayed inside emacs:

```
picoCTF{...}
```

> **Screenshot:** See `screenshots/emacs-flag.png`

---

## Key Takeaways

- **`sudo -l`** is one of the first commands to run when doing privilege escalation — it shows what commands you can run as root.
- **NOPASSWD sudo misconfigurations** are a common real-world vulnerability. If a user can run a file editor or interpreter with sudo, they can often read or modify privileged files.
- This is a simplified version of a classic Linux privilege escalation path — in penetration testing, `sudo -l` is a key enumeration step.
- See [GTFOBins](https://gtfobins.github.io/) for a list of binaries that can be abused if granted sudo permissions.

---

## References

- [sudo man page](https://linux.die.net/man/8/sudo)
- [GTFOBins — emacs](https://gtfobins.github.io/gtfobins/emacs/)
- [Linux privilege escalation guide](https://book.hacktricks.xyz/linux-hardening/privilege-escalation)

---

*[← Back to index](../../README.md)*

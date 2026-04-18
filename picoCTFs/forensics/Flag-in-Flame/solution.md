# Flag in Flame — picoCTF 2026

## Challenge Info

| Field | Details |
|-------|---------|
| **Category** | Forensics |
| **Difficulty** | Easy |
| **Points** | 100 |
| **Solves** | 20,988 |
| **Author** | picoCTF |

## Description

> The SOC team discovered a suspiciously large log file after a recent breach. When they opened it, they found an enormous block of encoded text instead of typical logs. Could there be something hidden within? Your mission is to inspect the resulting file and reveal the real purpose of it.

**File provided:** `logs.txt` — a large text file containing what appears to be encoded data

---

## Objective

Download the suspicious log file, identify its encoding (Base64), decode it to reveal a binary file (PNG image), and read the flag from the image.

---

## Tools Used

- **`file`** — identify file type
- **`base64 -d`** — decode Base64 data
- **`xxd -r -p`** — reverse hex to binary (if needed)
- **`strings`** — extract readable text
- **CyberChef** — (optional) visual decoding
- Image viewer — open the resulting PNG

---

## Solution

### Step 1 — Download and inspect the file

```bash
wget <challenge_file_url> -O logs.txt
file logs.txt
wc -c logs.txt    # Check file size
head -c 200 logs.txt
```

Opening the file shows a massive, continuous block of text — clearly not normal server logs. The character set (only `A–Z`, `a–z`, `0–9`, `+`, `/`, `=`) is the signature of **Base64 encoding**.

### Step 2 — Decode the Base64 data

```bash
base64 -d logs.txt > output.bin
file output.bin
```

Output:
```
output.bin: PNG image data, 896 x 1152, 8-bit/color RGB, non-interlaced
```

The decoded content is a PNG image!

### Step 3 — Open the image

```bash
xdg-open output.bin
# or rename it first
mv output.bin flag_image.png
xdg-open flag_image.png
```

The image displays the flag visually.

```
picoCTF{...}
```

> **Screenshot:** See `screenshots/decoded-image.png`

### Alternative — If the output is hex-encoded

Some instances of this challenge use hex encoding instead of or after Base64:

```bash
# If the decoded content looks like hex (only 0-9, a-f)
xxd -r -p logs.txt > output.bin
file output.bin
```

Or with CyberChef:
1. Paste content into CyberChef input
2. Add **"From Base64"** operation
3. Click the **image icon** to render the output as an image

---

## Key Takeaways

- **Log files are high-value targets** in real-world incident response — attackers often manipulate, clear, or forge log files to hide their activity. Conversely, defenders rely on logs to reconstruct what happened during a breach.
- This challenge simulates a scenario where an attacker **exfiltrated data disguised as log entries** — a common data-exfiltration technique to bypass DLP (Data Loss Prevention) tools.
- **Base64** is frequently used to encode binary data (like images or executables) for transmission over text-based channels. Recognising it and decoding it quickly is a fundamental forensics skill.
- The `file` command is essential — always run it before assuming a file's type. A file named `.txt` or `.log` may actually be an image, executable, or archive in disguise.
- In real SOC (Security Operations Center) work, analysts routinely decode suspicious log entries, email attachments, and network payloads to determine if they contain malware or exfiltrated data.

---

## References

- [base64 man page](https://linux.die.net/man/1/base64)
- [file man page](https://linux.die.net/man/1/file)
- [xxd man page](https://linux.die.net/man/1/xxd)
- [CyberChef](https://gchq.github.io/CyberChef/)
- [OWASP — Data Exfiltration](https://owasp.org/www-community/attacks/Data_Exfiltration)
- [SOC analyst log analysis guide](https://www.sans.org/blog/log-analysis-for-incident-response/)

---

*[← Back to Forensics index](../README.md)*

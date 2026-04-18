# Log Hunt — picoCTF 2026

## Challenge Info

| Field | Details |
|-------|---------|
| **Category** | General Skills |
| **Difficulty** | Easy |
| **Points** | 100 |
| **Solves** | 40,799 |
| **Author** | picoCTF |

## Description

> Our server seems to be leaking pieces of a secret flag in its logs. The parts are scattered and sometimes repeated. Can you reconstruct the original flag? Download the logs and figure out the full flag from the fragments.

**File provided:** `log` file (download from challenge page)

---

## Objective

Download a log file, search through it to find all fragments of the picoCTF flag, deduplicate them, and reconstruct the complete flag string.

---

## Tools Used

- `wget` / browser — download the log file
- `grep` — search for flag fragments
- `sort` / `uniq` — remove duplicates
- Basic bash piping

---

## Solution

### Step 1 — Download the log file

```bash
wget <log_file_url> -O server.log
```

Or download via the challenge page.

### Step 2 — Inspect the file

```bash
ls -lh server.log
cat server.log | head -50
```

The file contains many lines of server log output. Scanning manually is impractical.

### Step 3 — Search for flag fragments with grep

```bash
grep -o 'picoCTF{[^}]*}' server.log
```

This uses `grep -o` to print only the matching portion (not the whole line), and the regex `picoCTF{[^}]*}` matches any complete flag pattern.

If the flag is split across log lines as fragments:

```bash
grep 'pico' server.log
```

### Step 4 — Remove duplicates and reconstruct

```bash
grep 'picoCTF' server.log | sort | uniq
```

If only partial fragments appear (e.g., the flag is split):

```bash
grep -oP 'picoCTF\{[^}]+\}' server.log | sort -u
```

### Step 5 — Read the flag

After filtering and deduplication, the complete flag is visible:

```
picoCTF{...}
```

> **Screenshot:** See `screenshots/grep-output.png`

---

## Alternative — Using grep -r for directories

If logs are spread across multiple files in a directory:

```bash
grep -r 'picoCTF' ./logs/
```

---

## Key Takeaways

- **`grep`** is one of the most powerful and frequently used tools in a security professional's toolkit — it's essential for log analysis, incident response, and forensics.
- **`grep -o`** extracts only the matching text (not the whole line), making it ideal for pulling structured data like flags, IPs, or emails from large log files.
- **`sort | uniq`** is a classic Unix pipeline for deduplication — essential when logs repeat entries.
- In real-world incident response, analysts regularly grep through server logs to find attacker activity, leaked data, or suspicious patterns. This challenge simulates exactly that workflow.
- Tools like `ELK Stack` (Elasticsearch, Logstash, Kibana) scale this process to millions of log entries in production environments.

---

## References

- [grep man page](https://linux.die.net/man/1/grep)
- [Linux log analysis guide](https://www.loggly.com/ultimate-guide/analyzing-linux-logs/)
- [Regular expressions for grep](https://www.gnu.org/software/grep/manual/grep.html#Regular-Expressions)

---

*[← Back to index](../../README.md)*

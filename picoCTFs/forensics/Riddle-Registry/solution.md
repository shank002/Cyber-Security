# Riddle Registry — picoCTF 2026

## Challenge Info

| Field | Details |
|-------|---------|
| **Category** | Forensics |
| **Difficulty** | Easy |
| **Points** | 50 |
| **Solves** | 39,388 |
| **Author** | picoCTF |

## Description

> We are given a mysterious PDF file that seems to contain nothing but garbled text. Uncover the flag within the metadata.

**File provided:** `confidential.pdf`

**Hint:** Look beyond what's visible on the page — the answer lies in the metadata.

---

## Objective

Download the PDF file, inspect its metadata using forensic tools, find a Base64-encoded string hidden in a metadata field (such as the `Author` field), decode it, and retrieve the flag.

---

## Tools Used

- **`exiftool`** — read all metadata fields from a file
- **`pdfinfo`** — alternative PDF metadata viewer
- **`base64 -d`** — decode Base64 strings
- **`strings`** — extract printable strings from a file

---

## Solution

### Step 1 — Download and open the file

```bash
wget <challenge_file_url> -O confidential.pdf
```

Opening the PDF shows a page full of garbled/nonsense characters — clearly a decoy. Nothing useful is visible on the page itself.

### Step 2 — Inspect the PDF metadata with exiftool

```bash
exiftool confidential.pdf
```

Scan the output carefully. The `Author` field contains something suspicious:

```
Author: cGljb0NURntwdXp6bDNkX20zdGFkYXRhX2YwdW5kIV8zNTc4NzM5YX0=
```

That trailing `=` is a dead giveaway — this is **Base64 encoded** data.

### Step 3 — Decode the Base64 string

```bash
echo "cGljb0NURntwdXp6bDNkX20zdGFkYXRhX2YwdW5kIV8zNTc4NzM5YX0=" | base64 -d
```

Output:
```
picoCTF{...}
```

> **Screenshot:** See `screenshots/exiftool-metadata.png` and `screenshots/base64-decode.png`

### Alternative — pdfinfo

```bash
pdfinfo confidential.pdf
```

This also reveals the Author field with the encoded flag.

### Alternative — strings

```bash
strings confidential.pdf | grep -i "author\|picoCTF\|="
```

---

## Key Takeaways

- **File metadata** is one of the most overlooked areas in security and forensics. Documents, images, and PDFs carry embedded metadata — author name, software used, GPS coordinates, timestamps — that can reveal sensitive information.
- In the real world, metadata leakage has exposed whistleblowers, outed document authors, and revealed hidden tracking data. Many organisations implement **metadata stripping** tools (e.g., `mat2`) before publishing documents.
- **`exiftool`** is one of the most powerful and versatile forensic tools available — it reads metadata from virtually every file format. It's a standard tool in digital forensics and OSINT investigations.
- Base64 encoding has a recognisable signature: it uses only `A–Z`, `a–z`, `0–9`, `+`, `/`, and is often padded with `=`. Spotting it in unexpected places is a valuable pattern-recognition skill.
- This challenge demonstrates why **security audits of documents** must include metadata inspection, not just content review.

---

## References

- [ExifTool documentation](https://exiftool.org/)
- [pdfinfo man page](https://linux.die.net/man/1/pdfinfo)
- [Base64 encoding explained](https://en.wikipedia.org/wiki/Base64)
- [mat2 — metadata anonymisation toolkit](https://0xacab.org/jvoisin/mat2)
- [OSINT via document metadata](https://www.sans.org/blog/document-metadata-osint/)

---

*[← Back to Forensics index](../README.md)*

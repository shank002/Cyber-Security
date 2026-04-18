# Hidden in Plainsight — picoCTF 2026

## Challenge Info

| Field | Details |
|-------|---------|
| **Category** | Forensics |
| **Difficulty** | Easy |
| **Points** | 50 |
| **Solves** | 28,427 |
| **Author** | Yahaya Meddy |

## Description

> Something is tucked away out of sight inside the file. Can you find it?

**File provided:** `img.jpg` — a seemingly normal JPEG image

---

## Objective

Extract a flag hidden inside a JPEG image using a **multi-layer approach**: inspect EXIF metadata → decode nested Base64 → use the revealed password with `steghide` to extract a hidden file.

---

## Tools Used

- **`exiftool`** — read image metadata/EXIF data
- **`base64 -d`** — decode Base64 strings (two layers)
- **`steghide`** — extract data hidden inside images
- **`file`** — verify file type
- **`cat`** — read extracted flag

---

## Solution

### Step 1 — Download and verify the file

```bash
wget <challenge_file_url> -O img.jpg
file img.jpg
```

Output confirms it's a standard JPEG image. Opening it shows a normal-looking picture with nothing obviously suspicious.

### Step 2 — Inspect metadata with exiftool

```bash
exiftool img.jpg
```

In the output, the **Comment** field stands out:

```
Comment: c3RlZ2hpZGU6Y0VGNmVuZHZjbVE9
```

The `=` padding at the end is a classic Base64 indicator.

### Step 3 — Decode the first Base64 layer

```bash
echo "c3RlZ2hpZGU6Y0VGNmVuZHZjbVE9" | base64 -d
```

Output:
```
steghide:cEF6endvcmQ=
```

This tells us two things:
1. The tool to use is **`steghide`**
2. The password is another Base64 string: `cEF6endvcmQ=`

### Step 4 — Decode the second Base64 layer (the password)

```bash
echo "cEF6endvcmQ=" | base64 -d
```

Output:
```
pAzzword
```

### Step 5 — Extract the hidden file with steghide

```bash
steghide extract -sf img.jpg -p pAzzword
```

If steghide is not installed:
```bash
sudo apt install steghide -y
```

Output:
```
wrote extracted data to "flag.txt".
```

### Step 6 — Read the flag

```bash
cat flag.txt
picoCTF{...}
```

> **Screenshot:** See `screenshots/exiftool-comment.png` and `screenshots/steghide-extract.png`

---

## Full command summary

```bash
# 1. Download the image
wget <url> -O img.jpg

# 2. Read metadata
exiftool img.jpg

# 3. Decode first layer (reveals: steghide:<base64_password>)
echo "c3RlZ2hpZGU6Y0VGNmVuZHZjbVE9" | base64 -d

# 4. Decode second layer (reveals: pAzzword)
echo "cEF6endvcmQ=" | base64 -d

# 5. Extract hidden content
steghide extract -sf img.jpg -p pAzzword

# 6. Read flag
cat flag.txt
```

---

## Key Takeaways

- **Steganography** is the practice of hiding data inside other files — images, audio, video — in a way that is invisible to the naked eye. It's used in CTFs, covert communication, and sometimes real-world malware (e.g., malware C2 commands hidden in images).
- **`steghide`** supports JPEG and WAV files and requires a passphrase to extract hidden data — making it a two-step attack: find the passphrase, then extract.
- **Nested encoding** (Base64 inside Base64) is a common obfuscation trick. Always decode until you reach plaintext or a recognisable tool/format name.
- **`exiftool`** is the go-to tool for metadata analysis across virtually all file types. In OSINT and forensic investigations, it regularly surfaces hidden information that would otherwise go unnoticed.
- In the real world, steganography is used to **smuggle data past security controls** — a file that looks like a normal image may contain sensitive documents or malware configuration.

---

## References

- [steghide documentation](http://steghide.sourceforge.net/documentation.php)
- [ExifTool documentation](https://exiftool.org/)
- [Steganography explained](https://en.wikipedia.org/wiki/Steganography)
- [Base64 encoding](https://en.wikipedia.org/wiki/Base64)
- [Digital forensics — image analysis](https://www.sans.org/blog/how-to-tackle-image-based-forensics/)

---

*[← Back to Forensics index](../README.md)*

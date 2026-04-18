# MY GIT — picoCTF 2026

## Challenge Info

| Field | Details |
|-------|---------|
| **Category** | General Skills |
| **Difficulty** | Easy |
| **Points** | 50 |
| **Solves** | 5,431 |
| **Author** | picoCTF |

## Description

> I have built my own Git server with my own rules!
> You can clone the challenge repo using the command below:
> `git clone ssh://git@<host>:<port>/git/challenge.git`
> Here's the password: `<provided>`
> Check the README to get your flag!

**Hint:**
1. How do you specify your Git username and email?

---

## Objective

Clone a custom Git repository, read the README for instructions, configure your Git identity to match the expected user, push a `flag.txt` file, and receive the flag as a response from the server.

---

## Tools Used

- `git` — clone, configure, commit, push
- `ssh` — underlying transport for git
- Terminal / bash

---

## Solution

### Step 1 — Clone the repository

```bash
git clone ssh://git@<host>:<port>/git/challenge.git
```

Enter the provided password when prompted.

### Step 2 — Read the README

```bash
cd challenge/
cat README.md
```

Output:
```
# MyGit

### If you want the flag, make sure to push the flag!

Only flag.txt pushed by `root:root@picoctf` will be updated with the flag.

GOOD LUCK!
```

The server will only give us the flag if the commit comes from `root` with email `root@picoctf`.

### Step 3 — Configure Git identity

```bash
git config user.name "root"
git config user.email "root@picoctf"
```

### Step 4 — Create and push flag.txt

```bash
echo "give me the flag" > flag.txt
git add flag.txt
git commit -m "Add flag.txt"
git push
```

### Step 5 — Read the flag from server response

During the push, the server's `post-receive` hook runs and returns the flag:

```
remote: Here's your flag: picoCTF{...}
```

> **Screenshot:** See `screenshots/git-push-flag.png`

---

## Key Takeaways

- **Git server hooks** (like `post-receive`) are scripts that run automatically on the server when commits are pushed. This is how CI/CD systems, deployment triggers, and in this case, CTF flag checks work.
- **Git identity configuration** (`user.name` and `user.email`) is not authenticated by default — it's just metadata. This challenge shows that servers can use this metadata to gate access or trigger actions.
- In real security audits, **custom Git servers** can expose sensitive hooks, credentials in commit history, or misconfigured access controls.
- Understanding git workflows (clone → commit → push) is an essential DevOps/security skill.

---

## References

- [Git Hooks documentation](https://git-scm.com/book/en/v2/Customizing-Git-Git-Hooks)
- [git config documentation](https://git-scm.com/docs/git-config)
- [Securing Git repositories](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure)

---

*[← Back to index](../../README.md)*

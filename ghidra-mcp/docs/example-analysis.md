# Example Analysis — Reversing a CTF Crackme with Codex + GhidraMCP

This page walks through a real reverse engineering session on `app`, a CTF-style crackme binary, using only Codex prompts and GhidraMCP. No manual decompiler navigation. No Ghidra GUI clicks after setup.

---

## The Target: `app`

The binary presents a token prompt:

```
=== Nebula Gate v2 ===
Enter access token:
```

It validates the input through several layers and either prints `Access granted. Flag accepted.` or `Access denied. Invalid token.`

The goal: understand what the binary checks, and figure out what a valid token looks like.

---

## Step 1 — Load the Binary in Ghidra

Open `app` in Ghidra CodeBrowser. Let auto-analysis run. Start the GhidraMCP server (**Tools → GhidraMCP → Start Server**, confirm **UDS: Running**).

Then launch Codex in your terminal:

```bash
codex
```

Confirm GhidraMCP tools are available at `/mcp`.

![Ghidra with app binary loaded in CodeBrowser](../assets/screenshots/ghidra_interface.png)

---

## Step 2 — Initial Triage Prompt

**The prompt sent to Codex:**

![Codex prompt for reverse engineering the crackme](../assets/screenshots/codex_prompt_reverse_engineering.png)

The prompt:

```
Use ghidra to analyze this binary. Get program info, list the entry points,
identify the main validation logic, decompile the key functions, and give me
a complete breakdown of what checks the binary performs on the input.
```

**What Codex does automatically:**

1. `get_current_program_info` → 64-bit ELF, x86-64, entry at `0x401080`
2. `list_entry_points` → finds `main`, `_start`
3. `list_functions` → identifies `validateFlag`, `vmCheck`, `mixBlock`, `fnv1a`
4. `decompile_function` on each of those four functions
5. Synthesizes a structured breakdown

---

## Step 3 — Codex Analysis Output

**The full Codex response:**

![Codex output after analyzing the crackme binary](../assets/screenshots/codex_output_after_reverse_engineering.png)

### What Codex Found

Codex correctly identified all five validation layers the binary uses:

---

#### Check 1 — Format and Length Gate

The token must be exactly **37 characters**, formatted as:

```
CTF{<32 hex characters>}
```

The 32 hex characters decode to exactly **16 raw bytes**. If the length is wrong, hex decoding fails, or anything else is malformed, the binary exits immediately.

---

#### Check 2 — Entropy Gate

The 16 decoded bytes must contain **at least 10 unique byte values**. This rules out trivially repeated or low-entropy inputs.

```cpp
// At least 10 distinct bytes required
if (unique < 10) return false;
```

---

#### Check 3 — Register VM (`vmCheck`)

The binary runs a **tiny register VM** over the input. The VM has 8 registers and executes 25 instructions using 6 operations:

| Opcode | Operation |
|--------|-----------|
| `1` | XOR two registers |
| `2` | ADD two registers |
| `3` | Rotate left (ROTL32) |
| `4` | Multiply register by constant |
| `5` | Load input byte into register |
| `6` | Compare register against hardcoded target |

The VM runs two independent register chains and checks each against a target value:

```
Target 1: 0xA47F2291
Target 2: 0x6E8C42D0
```

Both must match. This constrains specific bytes of the input (bytes at positions 0, 5, 10, 15, 2, 7, 12, 1).

---

#### Check 4 — 8-Round SPN (`mixBlock`)

The 16 input bytes are run through a custom **substitution-permutation network**:

- **8 rounds** of processing
- Each round: byte-wise XOR with a round/position constant → split nibbles → run both through a 4-bit S-box → recombine
- Then: a permutation step mixes bytes across positions with a round-dependent offset

After all 8 rounds, the resulting 16-byte block is compared against a hardcoded expected value:

```
Expected: 6A 1C DE B0 87 95 A4 52 10 EE 36 44 C1 73 29 9F
```

---

#### Check 5 — FNV-1a Hash Gate

Finally, the original 16 raw bytes are hashed with **FNV-1a (32-bit)**:

```
FNV offset basis: 0x811C9DC5
FNV prime:        0x01000193
Required output:  0x58A61FAA
```

All five checks must pass simultaneously for the token to be accepted.

---

## What This Demonstrates

This session shows how GhidraMCP + Codex handles a multi-layer validation binary:

- **No manual decompiler navigation** — Codex identified and decompiled all four key functions from a single prompt
- **Structured output** — the analysis came back as labeled, organized findings rather than raw pseudocode
- **Correct VM interpretation** — Codex correctly decoded the opcode table and traced register state through the VM
- **Time saved** — what would be 30–60 minutes of manual function-by-function analysis took a single multi-sentence prompt

---

## Follow-Up Prompts You Could Run

After the initial triage, you can dig deeper:

```
"Trace exactly which input bytes the VM reads in each chain and what transformations
they go through. What constraints does this place on the input?"
```

```
"Can you work backwards through the mixBlock SPN to determine what input
would produce the expected output 6A1CDEB08795A45210EE3644C17329 9F?"
```

```
"List all hardcoded constants in this binary — targets, S-box, expected hash, expected block."
```

```
"Rename validateFlag, vmCheck, mixBlock, and fnv1a to descriptive names in Ghidra."
```

Each of these would chain additional GhidraMCP tool calls automatically.

# Usage Guide — Prompts and Workflows

> Ensure setup is complete and `/mcp` shows 150+ tools before starting.

---

## How to Think About Prompting

Codex understands intent and chains GhidraMCP calls automatically. Describe what you want to know — don't name specific tools unless you want precision.

Both of these work:

```
"Find functions related to network activity and decompile the most interesting one."
```

```
"Use list_functions, then decompile_function on anything that calls send() or recv()."
```

---

## Starter Prompts

### General Triage (start here for any unknown binary)

```
Use ghidra to get the current program info, list entry points, identify
the likely main function, decompile it, and summarize the overall behavior.
```

### String Hunting

```
Use ghidra to list strings related to: HTTP and URLs, command-line arguments,
file paths, registry keys, and error or debug messages.
```

### Network Behavior

```
Use ghidra to find all functions involved in network activity — socket creation,
connect, send, recv, read, write, close. Decompile the most interesting one.
```

### Malware Detection

```
Use ghidra to detect malware behaviors in this binary. Flag any anti-debug tricks,
process injection, persistence mechanisms, or privilege escalation patterns.
```

### IOC Extraction

```
Use ghidra to extract all IOCs with surrounding code context — IP addresses,
domains, file paths, registry keys, mutex names, and any hardcoded credentials.
```

### Crackme / Validation Logic

```
Use ghidra to find the main validation function, decompile it and all functions
it calls, and give me a complete breakdown of what checks the binary performs.
```

### AI-Assisted Renaming

```
Decompile all functions with auto-generated names (FUN_xxxxx), infer a meaningful
name from each one's behavior, and rename them in Ghidra.
```

---

## Multi-Turn Workflow Example

Codex holds context across the session — use that:

```
You:    Identify the main function and decompile it.
Codex:  [decompiles main, explains it's a dropper]

You:    What functions does it call?
Codex:  [lists callees from get_callees]

You:    Focus on the one that looks like it decrypts something.
Codex:  [decompiles decrypt routine, explains XOR loop]

You:    Is the key hardcoded? What is it?
Codex:  [searches data segment, finds key at offset 0x403020]

You:    Rename the function to decrypt_payload and the key variable to xor_key.
Codex:  [calls rename_function and rename_variable]
```

---

## Tips

- **Be specific about addresses** when you know them — faster than having Codex search
- **Chain requests in one prompt**: `"Get program info, list imports, find crypto functions"` saves round trips
- **Ask for formatted output**: `"Give me the IOC list as a table"` or `"Format that as bullet points"`
- **Ask for confidence levels**: `"How confident are you this is a network function?"` gets useful hedging
- **Use follow-ups freely** — Codex remembers the conversation

---

## Reference: Key GhidraMCP Tools

| Tool | What it does |
|------|-------------|
| `get_current_program_info` | Binary name, arch, base address |
| `list_entry_points` | Entry points including `main` |
| `list_functions` | All functions in the binary |
| `decompile_function` | Decompile by address or name |
| `get_callers` / `get_callees` | Call graph traversal |
| `list_strings` | All strings in binary |
| `search_strings` | Filter strings by pattern |
| `list_imports` / `list_exports` | Symbol table |
| `get_xrefs_to` / `get_xrefs_from` | Cross-references |
| `rename_function` | Rename in the Ghidra project |
| `rename_variable` | Rename local variables |
| `detect_malware_behaviors` | Behavioral pattern detection |
| `extract_iocs_with_context` | IOCs with surrounding code |
| `analyze_control_flow` | Control flow graph summary |
| `get_bytes_at_address` | Raw memory read |
| `list_memory_segments` | Segment map |

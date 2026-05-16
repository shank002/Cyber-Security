# Troubleshooting — GhidraMCP + Codex CLI

---

## `/mcp` shows only a few base tools (or none)

Codex is connecting to the bridge, but the bridge isn't reaching Ghidra.

Work through this checklist in order:

1. **Is Ghidra open with a binary loaded in CodeBrowser?**
   GhidraMCP only exposes tools when CodeBrowser has an active project and binary.

2. **Is the GhidraMCP server running?**
   In CodeBrowser: **Tools → GhidraMCP → Start Server**
   Status panel must show **UDS: Running**.

3. **Test the bridge in isolation:**
   ```bash
   cd ~/malware_lab/ghidra-mcp
   source .venv/bin/activate
   python bridge_mcp_ghidra.py
   ```
   Should print `Registered 152 tools`. If it errors here, Ghidra isn't exposing the socket.

4. **Is `start_bridge.sh` executable?**
   ```bash
   ls -la ~/malware_lab/ghidra-mcp/start_bridge.sh
   ```
   Permissions must include `x`. Fix: `chmod +x start_bridge.sh`

5. **Do the paths in `start_bridge.sh` match your system?**
   Open the script and confirm `XDG_RUNTIME_DIR`, `HOME`, `cd` path, and the `exec` path all match your actual username and directory.

6. **Re-register in Codex:**
   ```bash
   codex mcp remove ghidra
   codex mcp add ghidra -- /home/kali/malware_lab/ghidra-mcp/start_bridge.sh
   ```

7. Restart Codex and check `/mcp` again.

---

## Bridge works manually but fails when Codex launches it

Codex isn't inheriting the shell environment when it spawns the bridge as a subprocess.

**Fix:** Ensure `start_bridge.sh` explicitly exports:
- `XDG_RUNTIME_DIR="/run/user/$(id -u)"`
- `HOME="/home/kali"`

And that the `exec` line uses the **venv Python**, not the system Python:

```bash
# Wrong
exec python bridge_mcp_ghidra.py

# Right
exec /home/kali/malware_lab/ghidra-mcp/.venv/bin/python bridge_mcp_ghidra.py
```

---

## `codex --version` not found after install

The global npm binary path isn't in `$PATH`.

```bash
export PATH="$PATH:$(npm bin -g)"
# Make it permanent:
echo 'export PATH="$PATH:$(npm bin -g)"' >> ~/.bashrc
source ~/.bashrc
```

---

## `pip install -r requirements.txt` fails

```bash
source .venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt
```

If a specific package fails on missing system libs:
```bash
sudo apt install -y python3-dev build-essential
```

---

## GhidraMCP plugin not appearing under File → Configure

The extension wasn't installed correctly, or Ghidra wasn't restarted after install.

1. **File → Install Extensions** — confirm GhidraMCP is listed and checked
2. **Fully close and reopen Ghidra** (not just the project)
3. Reopen your binary in CodeBrowser
4. Try **File → Configure → Utility** again

---

## Bridge prints `Connection refused` or socket error

GhidraMCP server inside Ghidra isn't running.

- In CodeBrowser: **Tools → GhidraMCP → Start Server**
- If the menu is greyed out, the plugin isn't enabled — re-do step 3.4 in [`setup.md`](setup.md)

---

## Codex responds but says it can't access Ghidra tools mid-session

Ghidra was closed or the server stopped while Codex was running.

1. Reopen the binary in Ghidra CodeBrowser
2. Restart the GhidraMCP server (**Tools → GhidraMCP → Start Server**)
3. Restart Codex

---

## Full Verification Chain

Run through this top to bottom when nothing else works:

```bash
# 1. Visual check: Ghidra open, binary loaded, UDS: Running in status panel

# 2. Bridge in isolation
cd ~/malware_lab/ghidra-mcp
source .venv/bin/activate
python bridge_mcp_ghidra.py
# Must print: Registered 152 tools

# 3. Wrapper script in isolation
~/malware_lab/ghidra-mcp/start_bridge.sh
# Must behave identically to step 2

# 4. Re-register
codex mcp remove ghidra
codex mcp add ghidra -- /home/kali/malware_lab/ghidra-mcp/start_bridge.sh

# 5. Launch Codex and type /mcp
codex
```

**Diagnosis:**
- Step 2 works, step 3 doesn't → paths in wrapper script are wrong
- Step 3 works, `/mcp` still shows few tools → registration is pointing at wrong script or Ghidra server stopped

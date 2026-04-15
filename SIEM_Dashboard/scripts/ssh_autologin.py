#!/usr/bin/env python3
"""
SSH Auto-Login CLI with Splunk-ready logging.
Logs login attempts (success/fail), timestamps, and hostnames in JSON format.

Dependencies:
    pip install paramiko
"""

import argparse
import json
import logging
import os
import socket
import sys
from datetime import datetime, timezone

try:
    import paramiko
except ImportError:
    print("[ERROR] paramiko is not installed. Run: pip install paramiko")
    sys.exit(1)


# ── Logging Setup ─────────────────────────────────────────────────────────────

LOG_FILE = os.path.join(os.path.dirname(__file__), "ssh_autologin.log")

logger = logging.getLogger("ssh_autologin")
logger.setLevel(logging.DEBUG)

# File handler — JSON lines (Splunk-friendly)
file_handler = logging.FileHandler(LOG_FILE)
file_handler.setLevel(logging.DEBUG)

# Console handler — human-readable
console_handler = logging.StreamHandler(sys.stdout)
console_handler.setLevel(logging.INFO)
console_handler.setFormatter(logging.Formatter("%(message)s"))

logger.addHandler(file_handler)
logger.addHandler(console_handler)


def splunk_log(event: str, status: str, host: str, port: int,
               username: str, extra: dict = None):
    """Emit a Splunk-ready JSON log line."""
    record = {
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "event": event,
        "status": status,
        "source_host": socket.gethostname(),
        "target_host": host,
        "target_port": port,
        "username": username,
    }
    if extra:
        record.update(extra)

    json_line = json.dumps(record)
    file_handler.stream.write(json_line + "\n")
    file_handler.stream.flush()
    return record


# ── SSH Connect ───────────────────────────────────────────────────────────────

def ssh_connect(host: str, port: int, username: str,
                password: str = None, key_path: str = None,
                timeout: int = 10) -> paramiko.SSHClient:
    """
    Attempt SSH connection using password or private key.
    Returns a connected SSHClient on success, raises on failure.
    """
    client = paramiko.SSHClient()
    client.set_missing_host_key_policy(paramiko.AutoAddPolicy())

    connect_kwargs = dict(
        hostname=host,
        port=port,
        username=username,
        timeout=timeout,
        allow_agent=False,
        look_for_keys=False,
    )

    if key_path:
        connect_kwargs["key_filename"] = os.path.expanduser(key_path)
    elif password:
        connect_kwargs["password"] = password
    else:
        raise ValueError("Provide either --password or --key-path for authentication.")

    client.connect(**connect_kwargs)
    return client


def run_commands(client: paramiko.SSHClient, commands: list[str]) -> list[dict]:
    """Run a list of commands and return their outputs."""
    results = []
    for cmd in commands:
        stdin, stdout, stderr = client.exec_command(cmd)
        out = stdout.read().decode().strip()
        err = stderr.read().decode().strip()
        results.append({"command": cmd, "stdout": out, "stderr": err})
        print(f"  $ {cmd}")
        if out:
            print(f"    {out}")
        if err:
            print(f"    [stderr] {err}")
    return results


# ── Main ──────────────────────────────────────────────────────────────────────

def parse_args():
    parser = argparse.ArgumentParser(
        description="SSH Auto-Login CLI with Splunk-ready JSON logging",
        formatter_class=argparse.RawTextHelpFormatter,
    )
    parser.add_argument("host", help="Target SSH hostname or IP")
    parser.add_argument("-u", "--username", required=True, help="SSH username")
    parser.add_argument("-p", "--password", default=None, help="SSH password")
    parser.add_argument("-k", "--key-path", default=None,
                        help="Path to private key file (e.g. ~/.ssh/id_rsa)")
    parser.add_argument("--port", type=int, default=22, help="SSH port (default: 22)")
    parser.add_argument("--timeout", type=int, default=10,
                        help="Connection timeout in seconds (default: 10)")
    parser.add_argument("--commands", nargs="*", default=["whoami", "hostname", "uptime"],
                        help="Commands to run after login (default: whoami hostname uptime)")
    parser.add_argument("--log-file", default=LOG_FILE,
                        help=f"Log file path (default: {LOG_FILE})")
    return parser.parse_args()


def main():
    args = parse_args()

    # Redirect log file if user specified a custom path
    if args.log_file != LOG_FILE:
        file_handler.baseFilename = args.log_file
        file_handler.stream = open(args.log_file, "a", encoding="utf-8")

    print(f"\n{'─'*55}")
    print(f"  SSH Auto-Login")
    print(f"  Target : {args.username}@{args.host}:{args.port}")
    print(f"  Log    : {args.log_file}")
    print(f"{'─'*55}\n")

    # ── Attempt connection ────────────────────────────────────────────────────
    print(f"[*] Connecting to {args.host}:{args.port} ...")
    try:
        client = ssh_connect(
            host=args.host,
            port=args.port,
            username=args.username,
            password=args.password,
            key_path=args.key_path,
            timeout=args.timeout,
        )
    except paramiko.AuthenticationException as e:
        splunk_log("ssh_login", "failure", args.host, args.port, args.username,
                   extra={"reason": "authentication_failed", "detail": str(e)})
        print(f"[FAIL] Authentication failed: {e}")
        sys.exit(1)
    except (paramiko.SSHException, socket.error, OSError) as e:
        splunk_log("ssh_login", "failure", args.host, args.port, args.username,
                   extra={"reason": "connection_error", "detail": str(e)})
        print(f"[FAIL] Connection error: {e}")
        sys.exit(1)

    # ── Login success ─────────────────────────────────────────────────────────
    record = splunk_log("ssh_login", "success", args.host, args.port, args.username)
    print(f"[OK]   Login successful — logged at {record['timestamp']}\n")

    # ── Run commands ──────────────────────────────────────────────────────────
    if args.commands:
        print(f"[*] Running {len(args.commands)} command(s):\n")
        run_commands(client, args.commands)

    client.close()
    print(f"\n[*] Session closed. Logs written to: {args.log_file}\n")


if __name__ == "__main__":
    main()

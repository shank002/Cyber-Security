# Cowrie · Configuration Reference

## Config File Location

```
/home/cowrie/cowrie/etc/cowrie.cfg
```

Copy from the template before editing:

```bash
cp /home/cowrie/cowrie/etc/cowrie.cfg.dist /home/cowrie/cowrie/etc/cowrie.cfg
```

---

## Full Recommended Configuration

```ini
[honeypot]

# Hostname shown in the fake shell prompt
hostname = prod-webserver-01

# Cowrie listens on these ports (high ports, redirected from 22/23 via iptables)
listen_endpoints = tcp:2222:interface=0.0.0.0

# Enable Telnet honeypot as well
telnet_enabled = true
listen_endpoints_telnet = tcp:2223:interface=0.0.0.0

# Fake OS/kernel reported by uname -a
kernel_version = 5.15.0-76-generic
kernel_build_string = #83-Ubuntu SMP Thu Jun 15 19:16:32 UTC 2023

# Fake hardware info
hardware_platform = x86_64
operating_system = GNU/Linux

# Number of login failures before Cowrie accepts credentials
# Set to 3-5 to simulate a real server resisting brute-force
auth_class = UserDB
auth_none_enabled = false

# Delay responses slightly — makes Cowrie seem more realistic
# and slows down automated scanners
interactive_timeout = 180
authentication_timeout = 120

# Directory for fake filesystem pickle (pre-built fake Linux FS)
share_path = share/cowrie

# Directory where uploaded files are saved
download_path = var/lib/cowrie/downloads

# TTY log directory (full session replay)
ttylog = true
ttylog_path = var/lib/cowrie/tty

[output_jsonlog]
# Main output — this is what Splunk reads
enabled = true
logfile = var/log/cowrie/cowrie.json

[output_textlog]
# Human-readable log (useful for debugging)
enabled = true
logfile = var/log/cowrie/cowrie.log
```

---

## Key Settings Explained

### `hostname`
This is what attackers see at the shell prompt:

```
root@prod-webserver-01:~#
```

Make it convincing — something that sounds like a real production machine.

---

### `listen_endpoints`
Cowrie binds to this port. It must match your iptables redirect target (2222).

```ini
listen_endpoints = tcp:2222:interface=0.0.0.0
```

`0.0.0.0` means listen on all interfaces.

---

### `auth_class = UserDB`
Controls which usernames/passwords Cowrie accepts. With `UserDB`, you define accepted credentials in `etc/userdb.txt`. Example:

```
# etc/userdb.txt
# Format: username:UID:password
root:0:*           # accept any password for root
admin:0:admin      # accept only 'admin' password for admin
```

The `*` wildcard accepts any password — which maximises attacker engagement.

---

### `interactive_timeout`
Time in seconds before an idle session is disconnected. 180 seconds is a good balance between keeping sessions open long enough to log behaviour vs. not consuming resources on idle connections.

---

### `ttylog = true`
Records full TTY sessions as binary files. These can be replayed later with:

```bash
source cowrie-env/bin/activate
bin/playlog var/lib/cowrie/tty/SESSIONFILE.log
```

Very useful for reviewing exactly what an attacker did step by step.

---

## Fake Filesystem

Cowrie ships with a pre-built fake filesystem. You can customise it to add fake files that make the server look more realistic:

```bash
# Enter the fake filesystem directory
ls share/cowrie/fs.pickle
```

To add a fake `/etc/passwd` or other files, edit the pickle using Cowrie's `createfs.py` tool:

```bash
source cowrie-env/bin/activate
python bin/createfs -l /path/to/real/linux/root -o share/cowrie/fs.pickle
```

Alternatively, edit text files in `honeyfs/` — Cowrie overlays this directory on top of the pickle:

```
honeyfs/
├── etc/
│   ├── passwd      ← Fake user list
│   ├── hostname    ← Should match your hostname setting
│   └── issue.net   ← SSH banner (pre-login)
└── proc/
    └── version     ← Shown by uname -a
```

---

## Reloading Configuration

Cowrie must be restarted to pick up config changes:

```bash
sudo systemctl restart cowrie
# or
bin/cowrie restart
```

Verify the new config took effect:

```bash
tail -f var/log/cowrie/cowrie.log | grep -i "starting"
```

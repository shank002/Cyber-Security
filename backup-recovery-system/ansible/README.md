# Ansible Backup System — Rocky Linux

## Project Structure

```
ansible_backup/
├── ansible.cfg                         # Ansible configuration
├── inventory.ini                       # Your server list
├── site.yml                            # Master playbook (entry point)
└── roles/
    └── backup/
        ├── defaults/
        │   └── main.yml                # All configurable variables
        ├── tasks/
        │   ├── main.yml                # Orchestrates task files
        │   ├── packages.yml            # Install rsync, cronie
        │   ├── directories.yml         # Create /backup structure
        │   ├── scripts.yml             # Deploy backup scripts
        │   ├── cron.yml                # Schedule cron jobs
        │   ├── selinux.yml             # Rocky Linux SELinux config
        │   └── verify.yml              # Post-deploy smoke tests
        ├── templates/                  # Jinja2 script templates
        │   ├── full_backup.sh.j2
        │   ├── incremental_backup.sh.j2
        │   ├── restore.sh.j2
        │   └── backup_monitor.sh.j2
        └── handlers/
            └── main.yml                # Runs after script changes
```

---

## 1. Install Ansible on Rocky Linux (Control Node)

```bash
sudo dnf install epel-release -y
sudo dnf install ansible -y
ansible --version
```

---

## 2. Configure SSH Key Access

Ansible connects to servers via SSH. Set up key-based auth first:

```bash
# Generate a key if you don't have one
ssh-keygen -t ed25519 -C "ansible"

# Copy your key to each managed server
ssh-copy-id root@192.168.1.10
ssh-copy-id root@192.168.1.11
ssh-copy-id root@192.168.1.20

# Test connectivity
ansible all -i inventory.ini -m ping
```

You should see "pong" from each server.

---

## 3. Edit Your Inventory

Open inventory.ini and replace the example IPs with your servers:

```ini
[backup_servers]
web-01    ansible_host=YOUR_SERVER_IP
```

---

## 4. Customize Variables (Optional)

To override defaults for all servers, create:

```bash
mkdir -p group_vars
cat > group_vars/backup_servers.yml <<EOF
backup_alert_email: "you@example.com"
backup_retention_weeks: 8
backup_source_dirs:
  - /etc
  - /home
  - /var/www
EOF
```

To override for a single server only:

```bash
mkdir -p host_vars
cat > host_vars/db-01.yml <<EOF
backup_source_dirs:
  - /etc
  - /var/lib/mysql
EOF
```

---

## 5. Run the Playbook

```bash
cd ansible_backup/

# Dry run first — see what would change, nothing applied yet
ansible-playbook site.yml --check

# Apply to all servers
ansible-playbook site.yml

# Apply to one server only
ansible-playbook site.yml --limit web-01

# Verbose output (shows every task detail)
ansible-playbook site.yml -v
```

---

## 6. Verify Deployment

After running, Ansible's verify.yml tasks automatically confirm:
- All 4 scripts are deployed and executable
- All backup directories exist with correct permissions
- All 3 cron jobs are registered
- A deployment summary is printed for each server

You can also manually check any server:

```bash
# Check scripts are there
ansible backup_servers -m command -a "ls -la /usr/local/bin/full_backup.sh"

# Check cron jobs
ansible backup_servers -m command -a "crontab -l -u root"

# Run the monitor across all servers at once
ansible backup_servers -m command -a "/usr/local/bin/backup_monitor.sh"
```

---

## Key Ansible Concepts Demonstrated in This Project

**Idempotency** — Run the playbook 10 times, the result is the same as
running it once. Safe to re-run anytime. No duplicates, no side effects.

**Templates** — Jinja2 .j2 files let variables flow from your inventory
and vars files into the deployed scripts automatically. Change a variable,
re-run the playbook — all servers get the updated script.

**Roles** — Instead of one giant playbook, tasks are split by concern
(packages, directories, scripts, cron, selinux). Each file does one thing.

**Handlers** — The script validation only runs when a script actually
changed. If nothing changed, Ansible skips it. Efficient.

**Variables with precedence** — defaults/main.yml sets sensible defaults.
group_vars/ overrides per group. host_vars/ overrides per server.
The most specific wins.

---

## Interview Talking Points

- "I used Ansible to deploy the backup system to multiple servers
  with a single command — no manual SSH, no configuration drift."

- "The playbook is idempotent — I can run it again after adding a new
  server to the inventory and it only touches what's needed."

- "Templates let me inject per-server variables — the scripts on each
  server are configured correctly without any manual editing."

- "SELinux is handled automatically — the selinux.yml task sets the
  rsync_full_access boolean persistently, so it survives reboots."

- "The verify.yml tasks act as an automated smoke test after every deploy."

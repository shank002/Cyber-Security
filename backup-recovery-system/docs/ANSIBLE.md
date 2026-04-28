# Ansible Automation

This document covers the Ansible role that deploys and configures the backup system across multiple Rocky Linux servers from a single control node.

---

## What Ansible Does Here

Without Ansible, deploying this backup system to a new server means: SSH in, install packages, create directories, copy scripts, set permissions, configure cron, fix SELinux, verify everything worked — manually, every time, for every server.

With Ansible, you add the server to `inventory.ini` and run one command. Ansible SSHes in, executes every step in order, and prints a verified summary. The whole thing takes under 2 minutes. Run it again on the same server and nothing changes — it is idempotent.

---

## Prerequisites

### On the control node (your machine)

```bash
# Install Ansible
sudo dnf install epel-release -y
sudo dnf install ansible -y

# Verify
ansible --version
```

### On each managed server

- Rocky Linux 8.x or 9.x
- Python 3.6+ (present by default on Rocky Linux)
- SSH accessible from the control node
- Root or sudo access

### SSH key setup

Ansible connects via SSH. Set up key-based authentication before running any playbook:

```bash
# Generate a key if needed
ssh-keygen -t ed25519 -C "ansible-backup"

# Copy to each server
ssh-copy-id root@192.168.1.10
ssh-copy-id root@192.168.1.11

# Confirm Ansible can reach all servers
ansible all -i ansible/inventory.ini -m ping
```

Expected output:
```
web-01 | SUCCESS => { "ping": "pong" }
web-02 | SUCCESS => { "ping": "pong" }
```

---

## File Structure

```
ansible/
├── ansible.cfg          # Connection settings, output format, SSH options
├── inventory.ini        # Server list and groups
├── site.yml             # Master playbook — entry point
└── roles/
    └── backup/
        ├── defaults/
        │   └── main.yml             # All variables with defaults
        ├── tasks/
        │   ├── main.yml             # Includes all task files in order
        │   ├── packages.yml         # Install rsync, cronie
        │   ├── directories.yml      # Create /backup structure
        │   ├── scripts.yml          # Deploy scripts from templates
        │   ├── cron.yml             # Register cron jobs
        │   ├── selinux.yml          # SELinux boolean + restorecon
        │   └── verify.yml           # Smoke tests + deployment summary
        ├── templates/
        │   ├── full_backup.sh.j2
        │   ├── incremental_backup.sh.j2
        │   ├── restore.sh.j2
        │   └── backup_monitor.sh.j2
        └── handlers/
            └── main.yml             # Script syntax validation
```

---

## Inventory

Edit `ansible/inventory.ini` to list your servers:

```ini
[backup_servers]
web-01    ansible_host=192.168.1.10
web-02    ansible_host=192.168.1.11
db-01     ansible_host=192.168.1.20

[backup_servers:vars]
ansible_user=root
ansible_ssh_private_key_file=~/.ssh/id_rsa
ansible_python_interpreter=/usr/bin/python3
```

You can create sub-groups with different configurations:

```ini
[db_servers]
db-01     ansible_host=192.168.1.20

[db_servers:vars]
ansible_user=root
```

---

## Variables

All configurable values live in `roles/backup/defaults/main.yml`. These are the lowest-priority defaults — override them at any level below.

### Override for all servers in a group

Create `ansible/group_vars/backup_servers.yml`:

```yaml
backup_alert_email: "ops@example.com"
backup_retention_weeks: 8
backup_source_dirs:
  - /etc
  - /home
  - /var/www
  - /opt
```

### Override for a single server

Create `ansible/host_vars/db-01.yml`:

```yaml
# db-01 only backs up database and config — not /home or /var/www
backup_source_dirs:
  - /etc
  - /var/lib/mysql
backup_retention_weeks: 12
```

### Variable precedence (lowest to highest)

```
defaults/main.yml
  ↓ group_vars/all.yml
    ↓ group_vars/backup_servers.yml
      ↓ host_vars/web-01.yml
        ↓ command-line --extra-vars
```

---

## Running the Playbook

### Standard deployment

```bash
cd ansible/

# Check syntax without connecting to any server
ansible-playbook site.yml --syntax-check

# Dry run — connects to servers and shows what would change, nothing applied
ansible-playbook -i inventory.ini site.yml --check

# Full deploy to all servers
ansible-playbook -i inventory.ini site.yml
```

### Targeted deployment

```bash
# Deploy to one server only
ansible-playbook -i inventory.ini site.yml --limit web-01

# Deploy to a group
ansible-playbook -i inventory.ini site.yml --limit db_servers

# Deploy with verbose output (shows every task value)
ansible-playbook -i inventory.ini site.yml -v

# Override a variable at run time
ansible-playbook -i inventory.ini site.yml \
  --extra-vars "backup_alert_email=you@example.com"
```

### Run only specific tasks using tags

Add tags to tasks for selective execution:

```bash
# Run only the cron setup tasks
ansible-playbook -i inventory.ini site.yml --tags cron

# Skip SELinux tasks
ansible-playbook -i inventory.ini site.yml --skip-tags selinux
```

---

## How Each Task File Works

### packages.yml

Uses `ansible.builtin.dnf` with `state: present` — installs `rsync` and `cronie` only if they are not already installed. Running this on a server that already has both packages results in two "ok" lines and no changes.

```yaml
- name: Install rsync
  ansible.builtin.dnf:
    name: rsync
    state: present
```

### directories.yml

Uses `ansible.builtin.file` with `state: directory`. If the directory already exists with the correct owner and mode, Ansible reports "ok" and moves on. Permissions are enforced on every run — if someone manually `chmod 777`'d the backup directory, the next playbook run corrects it.

### scripts.yml

Uses `ansible.builtin.template` to render the Jinja2 `.j2` files from `templates/`. Every `{{ variable }}` in the template is replaced with the value from your variables before the file is written to the server.

This is what makes the system configurable across servers: the same template produces a script with `/backup` on one server and `/mnt/nfs/backup` on another — driven entirely by variables, no manual editing.

When a script changes (its content on disk differs from the rendered template), the task reports "changed" and notifies the `Validate backup scripts` handler.

### cron.yml

Uses `ansible.builtin.cron`, which writes cron entries identified by the `name:` field. Ansible uses this name as a unique key — running the task twice produces exactly one cron entry. Changing the schedule and re-running updates the existing entry.

```yaml
- name: Schedule weekly full backup (Sunday 2am)
  ansible.builtin.cron:
    name: "backup-full"
    minute: "0"
    hour: "2"
    weekday: "0"
    user: root
    job: "/usr/local/bin/full_backup.sh >> /var/log/backup/cron.log 2>&1"
```

### selinux.yml

Rocky Linux-specific. Checks whether SELinux is enabled and in enforcing mode using `getenforce`, then sets the `rsync_full_access` boolean persistently. The `persistent: true` flag writes to `/etc/selinux/` so the setting survives reboots.

```yaml
- name: Allow rsync to read all files
  ansible.posix.seboolean:
    name: rsync_full_access
    state: true
    persistent: true
```

### verify.yml

Post-deployment smoke tests. Uses `ansible.builtin.stat` to check each script exists and is executable, `ansible.builtin.assert` to fail with a clear message if anything is wrong, and `ansible.builtin.debug` to print a deployment summary. These run on every playbook execution — they serve as regression tests if you ever change the role.

### handlers/main.yml

Handlers only run when notified by another task and only run once per play, regardless of how many tasks notify them. Here, deploying any of the 4 scripts notifies `Validate backup scripts`. After all 4 deploys, the handler runs `bash -n` on each script — a syntax check with no side effects.

---

## Jinja2 Templates

The `.j2` template files in `templates/` are shell scripts with Ansible variable placeholders:

```bash
# In the template:
BACKUP_ROOT="{{ backup_root }}"
RETENTION_WEEKS={{ backup_retention_weeks }}
SOURCE_DIRS=(
{% for dir in backup_source_dirs %}
    "{{ dir }}"
{% endfor %}
)
```

After rendering with default values, the deployed script contains:

```bash
BACKUP_ROOT="/backup"
RETENTION_WEEKS=4
SOURCE_DIRS=(
    "/etc"
    "/home"
    "/root"
    "/var/www"
    "/opt"
)
```

Templates also inject a header warning operators not to edit the file directly:

```bash
# Generated by Ansible on web-01
# Managed by: ansible-playbook site.yml
# Do NOT edit this file directly — edit the template and re-run the playbook.
```

This is a standard Ansible pattern — it prevents configuration drift where someone edits a deployed file manually and the change gets overwritten on the next playbook run.

---

## Verifying After Deployment

The `verify.yml` tasks print a summary automatically. You can also check any server ad-hoc:

```bash
# Check all scripts are present and executable
ansible backup_servers -i inventory.ini \
  -m command -a "ls -la /usr/local/bin/full_backup.sh"

# View cron jobs on all servers at once
ansible backup_servers -i inventory.ini \
  -m command -a "crontab -l -u root"

# Run the backup monitor across the entire fleet
ansible backup_servers -i inventory.ini \
  -m command -a "/usr/local/bin/backup_monitor.sh"

# Trigger a manual full backup on one server
ansible web-01 -i inventory.ini \
  -m command -a "/usr/local/bin/full_backup.sh"
```

---

## Adding a New Server

1. Add it to `inventory.ini`
2. Copy your SSH key: `ssh-copy-id root@NEW_SERVER_IP`
3. Run the playbook: `ansible-playbook -i inventory.ini site.yml --limit NEW_SERVER`

The new server is fully provisioned and running backups in under 2 minutes.

---

## Troubleshooting

**"UNREACHABLE" error**

SSH connectivity issue. Check:
```bash
ssh root@SERVER_IP          # can you connect manually?
ansible SERVER -m ping      # does Ansible reach it?
```

**"Missing sudo password" error**

Set `become_method: sudo` and supply a password, or configure passwordless sudo on the target:
```bash
# On the managed server
echo "ansible_user ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers.d/ansible
```

**SELinux task fails**

The `ansible.posix` collection may not be installed:
```bash
ansible-galaxy collection install ansible.posix
```

**Template renders with empty variable**

Check variable precedence. A typo in `host_vars/` can silently produce an empty value. Run with `-v` to see resolved variable values during the play.

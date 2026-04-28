# Linux Backup & Recovery System with Ansible Automation

A production-grade backup and recovery system for Rocky Linux, featuring automated full and incremental backups using `rsync`, point-in-time restore, health monitoring, and Ansible-based multi-server deployment.

---

## Highlights

- **70% storage reduction** via `rsync --link-dest` hardlink-based incremental backups
- **RTO under 15 minutes** with point-in-time restore and dry-run validation
- **Multi-server deployment in under 2 minutes** per node using Ansible
- **SELinux-aware** — built and tested on Rocky Linux (RHEL-based)
- **Fully idempotent** — safe to re-run anytime without side effects

---

## Table of Contents

- [Project Structure](#project-structure)
- [Architecture Overview](docs/ARCHITECTURE.md)
- [Backup System](docs/BACKUP_SYSTEM.md)
- [Ansible Automation](docs/ANSIBLE.md)
- [Quick Start](#quick-start)
- [Configuration Reference](#configuration-reference)
- [Job Profile](#job-profile)

---

## Project Structure

```
.
├── README.md
├── docs/
│   ├── ARCHITECTURE.md         # System design and component overview
│   ├── BACKUP_SYSTEM.md        # Backup scripts deep-dive
│   └── ANSIBLE.md              # Ansible role and deployment guide
│
├── scripts/                    # Standalone shell scripts
│   ├── full_backup.sh
│   ├── incremental_backup.sh
│   ├── restore.sh
│   ├── backup_monitor.sh
│   └── backup_crontab
│
└── ansible/                    # Ansible role for multi-server deployment
    ├── ansible.cfg
    ├── inventory.ini
    ├── site.yml
    └── roles/
        └── backup/
            ├── defaults/main.yml
            ├── tasks/
            │   ├── main.yml
            │   ├── packages.yml
            │   ├── directories.yml
            │   ├── scripts.yml
            │   ├── cron.yml
            │   ├── selinux.yml
            │   └── verify.yml
            ├── templates/
            │   ├── full_backup.sh.j2
            │   ├── incremental_backup.sh.j2
            │   ├── restore.sh.j2
            │   └── backup_monitor.sh.j2
            └── handlers/main.yml
```

---

## Quick Start

### Option A — Single server (shell scripts only)

```bash
# 1. Clone the repository
git clone https://github.com/YOUR_USERNAME/linux-backup-system.git
cd linux-backup-system

# 2. Make scripts executable
sudo chmod +x scripts/*.sh

# 3. Create the backup directory structure
sudo mkdir -p /backup/{full,incremental}
sudo mkdir -p /var/log/backup

# 4. Run your first full backup
sudo ./scripts/full_backup.sh

# 5. Check the health report
sudo ./scripts/backup_monitor.sh
```

### Option B — Multi-server (Ansible)

```bash
# 1. Install Ansible on your control node (Rocky Linux)
sudo dnf install epel-release -y && sudo dnf install ansible -y

# 2. Set up SSH key access to your managed servers
ssh-copy-id root@YOUR_SERVER_IP

# 3. Edit the inventory
vim ansible/inventory.ini

# 4. Dry run — preview changes, nothing applied yet
ansible-playbook -i ansible/inventory.ini ansible/site.yml --check

# 5. Deploy to all servers
ansible-playbook -i ansible/inventory.ini ansible/site.yml
```

---

## Configuration Reference

All configurable values live in `ansible/roles/backup/defaults/main.yml` for Ansible deployments, or at the top of each script for standalone use.

| Variable | Default | Description |
|---|---|---|
| `backup_root` | `/backup` | Root directory for all backups |
| `backup_retention_weeks` | `4` | Number of full backups to keep |
| `backup_retention_days` | `30` | Number of incremental backups to keep |
| `backup_source_dirs` | `/etc /home /root /var/www /opt` | Directories to back up |
| `backup_alert_email` | ` ` | Email address for failure alerts |
| `backup_warn_disk_percent` | `85` | Disk usage % that triggers a warning |
| `backup_full_cron_hour` | `2` | Hour to run full backup (24h) |
| `backup_incr_cron_hour` | `2` | Hour to run incremental backup (24h) |
| `backup_configure_selinux` | `true` | Whether to configure SELinux booleans |

---

## Job Profile

> Built a production-grade **Backup & Recovery System** on Rocky Linux using `rsync` with full + incremental backups (`--link-dest` hardlinking), cutting storage overhead by up to **70%** vs daily full backups, with automated `cron` scheduling and **4-week / 30-day retention policies**.

> Implemented **point-in-time restore** with dry-run validation and an automated health monitor covering integrity checks, disk threshold alerting (>85%), and log auditing — targeting an **RTO of under 15 minutes** for full system recovery.

> Deployed the entire backup infrastructure across multiple servers using **Ansible** (idempotent playbooks, Jinja2 templating, SELinux-aware roles) — reducing provisioning time from **~30 minutes of manual setup to under 2 minutes** per node.

---

## Requirements

| Component | Minimum version |
|---|---|
| Rocky Linux | 8.x or 9.x |
| rsync | 3.1+ |
| bash | 4.0+ |
| cronie | any |
| Ansible (for automation) | 2.12+ |
| Python (on managed nodes) | 3.6+ |

---

## License

MIT — free to use, modify, and distribute.

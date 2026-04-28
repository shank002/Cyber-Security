# Architecture Overview

## Design Philosophy

This project is built around three principles:

**Reliability first.** Every script uses `set -euo pipefail` — meaning any unhandled error, unset variable, or failed pipe causes an immediate exit rather than silently continuing with bad state. Lock files prevent concurrent runs. Every operation is logged with timestamps.

**Storage efficiency over simplicity.** Rather than storing a fresh copy of every file every day (the naive approach), incremental backups use `rsync --link-dest` to hardlink unchanged files from the previous backup. The result: each daily backup *appears* complete on disk (you can browse it like a full backup) but only stores what actually changed. A typical setup sees **60–70% less disk usage** vs daily full copies.

**Infrastructure as code.** The Ansible layer means the backup system itself is a version-controlled, reproducible artifact. Any new Rocky Linux server can be provisioned identically in under 2 minutes — no manual steps, no configuration drift between servers.

---

## System Architecture

```
┌─────────────────────────────────────────────────────┐
│                   Control Node                       │
│                                                      │
│   ┌──────────────┐      ┌──────────────────────┐    │
│   │   Inventory  │      │   Ansible Playbook   │    │
│   │  (servers)   │─────▶│   (site.yml + role)  │    │
│   └──────────────┘      └──────────┬───────────┘    │
│                                    │ SSH             │
└────────────────────────────────────┼────────────────┘
                                     │
              ┌──────────────────────┼──────────────────────┐
              │                      │                       │
              ▼                      ▼                       ▼
   ┌──────────────────┐  ┌──────────────────┐  ┌──────────────────┐
   │    Server 1      │  │    Server 2      │  │    Server 3      │
   │                  │  │                  │  │                  │
   │  /usr/local/bin/ │  │  /usr/local/bin/ │  │  /usr/local/bin/ │
   │  full_backup.sh  │  │  full_backup.sh  │  │  full_backup.sh  │
   │  incr_backup.sh  │  │  incr_backup.sh  │  │  incr_backup.sh  │
   │  restore.sh      │  │  restore.sh      │  │  restore.sh      │
   │  backup_monitor  │  │  backup_monitor  │  │  backup_monitor  │
   │                  │  │                  │  │                  │
   │  /backup/        │  │  /backup/        │  │  /backup/        │
   │  /var/log/backup │  │  /var/log/backup │  │  /var/log/backup │
   │                  │  │                  │  │                  │
   │  cron (root)     │  │  cron (root)     │  │  cron (root)     │
   └──────────────────┘  └──────────────────┘  └──────────────────┘
```

---

## Component Breakdown

### Shell Scripts Layer

The core logic lives in four bash scripts. Each one is self-contained and can be used without Ansible on a single server.

| Script | Responsibility |
|---|---|
| `full_backup.sh` | Weekly full backup of all source directories |
| `incremental_backup.sh` | Daily incremental backup using hardlinks |
| `restore.sh` | Point-in-time restore with dry-run and path filtering |
| `backup_monitor.sh` | Health check: age, disk usage, log error scan |

### Cron Scheduling Layer

Three cron jobs run as root, orchestrated by `cronie`:

```
Sunday    02:00  →  full_backup.sh       (weekly full)
Mon–Sat   02:00  →  incremental_backup.sh  (daily incremental)
Daily     08:00  →  backup_monitor.sh    (morning health report)
```

### Ansible Automation Layer

The Ansible role wraps all of the above. It is structured as a set of focused task files, each handling one concern:

```
tasks/
├── main.yml         orchestrates the include order
├── packages.yml     dnf install rsync, cronie
├── directories.yml  mkdir /backup/full, /backup/incremental, /var/log/backup
├── scripts.yml      template → deploy 4 scripts to /usr/local/bin/
├── cron.yml         register 3 cron jobs via ansible.builtin.cron
├── selinux.yml      rsync_full_access boolean + restorecon
└── verify.yml       smoke test: files exist, cron registered, summary printed
```

---

## Backup Storage Layout

After the system has been running for a week, `/backup` looks like this:

```
/backup/
├── full/
│   └── 2025-03-23/              ← this week's full backup (real files)
│       ├── etc/
│       ├── home/
│       ├── root/
│       ├── var/
│       ├── opt/
│       └── .backup_meta         ← metadata: hostname, timestamp, sources
│
└── incremental/
    ├── 2025-03-24_020001/       ← Monday (only changed files stored)
    ├── 2025-03-25_020001/       ← Tuesday
    ├── 2025-03-26_020001/       ← Wednesday
    │   ├── etc/                 ← looks complete...
    │   ├── home/                ← ...but unchanged files are hardlinks
    │   └── .backup_meta
    └── 2025-03-27_020001/
```

Each incremental directory appears to be a complete snapshot when you browse it — but unchanged files are just hardlinks pointing to the same inode as the reference backup. Only genuinely changed files consume new disk space.

---

## How `--link-dest` Works

This is the key efficiency mechanism. Without it, a daily backup of 50GB of files would consume 350GB per week. With `--link-dest`:

```
rsync --link-dest=/backup/full/2025-03-23/ \
      /etc /home \
      /backup/incremental/2025-03-24_020001/
```

rsync compares each file in the source against the reference backup (`--link-dest`). If the file is identical (same size, modification time, checksum), rsync creates a hardlink in the destination instead of copying the file. A hardlink is just a second directory entry pointing to the same data on disk — it costs almost nothing.

The end result:
- `du -sh /backup/incremental/2025-03-24_020001/` → shows ~50GB (apparent size)
- `du -sh --apparent-size=false /backup/incremental/2025-03-24_020001/` → shows only the delta (e.g. 200MB)

---

## Data Flow: Full Backup

```
cron (Sunday 2am)
    │
    ▼
full_backup.sh
    │
    ├── acquire lock file (/var/run/full_backup.lock)
    ├── check disk space (abort if < 5GB free)
    ├── for each SOURCE_DIR:
    │       rsync -aAXHz --delete \
    │             --exclude=... \
    │             /etc /home ... \
    │             /backup/full/YYYY-MM-DD/
    ├── write .backup_meta
    ├── rotate old full backups (keep last N weeks)
    ├── release lock file
    └── log result → /var/log/backup/full_backup.log
```

## Data Flow: Incremental Backup

```
cron (Mon–Sat 2am)
    │
    ▼
incremental_backup.sh
    │
    ├── acquire lock file
    ├── find LINK_DEST:
    │       latest incremental → if exists, use it
    │       else latest full   → use it
    │       else               → abort (no base to compare against)
    ├── for each SOURCE_DIR:
    │       rsync -aAXHz --delete \
    │             --link-dest=LINK_DEST \
    │             /etc /home ... \
    │             /backup/incremental/YYYY-MM-DD_HHMMSS/
    ├── write .backup_meta (records link_dest used)
    ├── rotate incrementals older than RETENTION_DAYS
    ├── release lock file
    └── log result → /var/log/backup/incremental_backup.log
```

## Data Flow: Restore

```
operator runs: restore.sh --date 2025-03-26 [--source /etc] [--dry-run]
    │
    ├── search incremental/ for date match → found
    │       (falls back to full/ if no incremental matches)
    ├── [dry-run]: rsync --dry-run → print what would change, exit
    ├── [live]:    confirm prompt → operator types "yes"
    └── rsync -aAXHz --delete \
              /backup/incremental/2025-03-26_020001/etc/ \
              /etc/
```

---

## Security Considerations

- All scripts run as `root`. Backup directories are `chmod 0750` (root-only read/write).
- SSH key-based auth is required for Ansible — password auth is not used.
- SELinux remains in **Enforcing** mode. The `rsync_full_access` boolean grants rsync read access without weakening SELinux globally.
- Lock files prevent concurrent backup processes from corrupting the destination.
- The `.backup_meta` file records the hostname that created the backup — useful for detecting accidental cross-server restores.

---

## Rocky Linux Specifics

Rocky Linux is RHEL-compatible and runs **SELinux in Enforcing mode** by default. Two SELinux-specific steps are required and handled automatically by the Ansible role:

```bash
# Grants rsync permission to read all file types
setsebool -P rsync_full_access 1

# Restores correct SELinux file contexts on the backup directory
restorecon -Rv /backup
```

Without `rsync_full_access`, rsync will be silently denied access to directories like `/var/lib/mysql` or certain `/etc` subdirectories and the backup will be incomplete — with no obvious error message. The `selinux.yml` task prevents this.

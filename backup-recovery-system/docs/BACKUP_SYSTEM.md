# Backup System

This document covers the four shell scripts that form the core of the backup system, how to configure them, and how to use them on a single Rocky Linux server without Ansible.

---

## Scripts Overview

| Script | Trigger | Location after install |
|---|---|---|
| `full_backup.sh` | Cron / manual | `/usr/local/bin/full_backup.sh` |
| `incremental_backup.sh` | Cron / manual | `/usr/local/bin/incremental_backup.sh` |
| `restore.sh` | Manual only | `/usr/local/bin/restore.sh` |
| `backup_monitor.sh` | Cron / manual | `/usr/local/bin/backup_monitor.sh` |

---

## Installation (Single Server)

```bash
# Copy scripts to system bin
sudo cp scripts/full_backup.sh \
        scripts/incremental_backup.sh \
        scripts/restore.sh \
        scripts/backup_monitor.sh \
        /usr/local/bin/

# Make executable
sudo chmod +x /usr/local/bin/full_backup.sh \
              /usr/local/bin/incremental_backup.sh \
              /usr/local/bin/restore.sh \
              /usr/local/bin/backup_monitor.sh

# Create directory structure
sudo mkdir -p /backup/{full,incremental}
sudo mkdir -p /var/log/backup

# Install dependencies
sudo dnf install rsync cronie -y
sudo systemctl enable --now crond
```

---

## full_backup.sh

Performs a complete backup of all configured source directories to `/backup/full/YYYY-MM-DD/`.

### What it does step by step

1. Checks it is running as root
2. Acquires a lock file at `/var/run/full_backup.lock` — prevents two full backups from running simultaneously
3. Checks available disk space on the backup volume — aborts if less than 5GB free
4. Skips if today's full backup already exists (safe to call multiple times)
5. For each source directory, runs rsync with `-aAXHz --delete` and the configured excludes
6. Writes a `.backup_meta` file recording the hostname, timestamp, and sources
7. Rotates old full backups — deletes the oldest if count exceeds `RETENTION_WEEKS`
8. Releases the lock file
9. Logs result with timestamps to `/var/log/backup/full_backup.log`
10. Sends an alert email on failure if `ALERT_EMAIL` is configured

### rsync flags used

| Flag | Meaning |
|---|---|
| `-a` | Archive mode: preserves permissions, timestamps, symlinks, owner, group |
| `-A` | Preserve ACLs (Access Control Lists) |
| `-X` | Preserve extended attributes |
| `-H` | Preserve hardlinks |
| `-z` | Compress data during transfer (useful for remote backups) |
| `--delete` | Remove files from destination that no longer exist in source |
| `--stats` | Print transfer statistics to the log |

### Configuration

Edit the `CONFIGURATION` block at the top of the script:

```bash
BACKUP_ROOT="/backup"
RETENTION_WEEKS=4
ALERT_EMAIL=""          # leave empty to disable
SOURCE_DIRS=(
    "/etc"
    "/home"
    "/root"
    "/var/www"
    "/opt"
)
EXCLUDES=(
    "--exclude=/proc"
    "--exclude=/tmp"
    "--exclude=*.cache"
)
```

### Manual run

```bash
sudo /usr/local/bin/full_backup.sh

# Watch the log in real time
tail -f /var/log/backup/full_backup.log
```

---

## incremental_backup.sh

Backs up only files that have changed since the last reference point, using `rsync --link-dest` to hardlink unchanged files. Each incremental backup appears complete but stores only the delta.

### What it does step by step

1. Acquires a lock file
2. Finds the **link-dest reference**: checks for the most recent incremental backup first — if none exists, falls back to the most recent full backup. If neither exists, aborts with a clear error.
3. For each source directory, runs rsync with `--link-dest=REFERENCE` — unchanged files are hardlinked, changed files are copied
4. Writes `.backup_meta` recording which backup was used as the link-dest
5. Rotates incrementals older than `RETENTION_DAYS`
6. Logs result

### Why chain incrementals instead of always linking to the full backup?

Chaining to the most recent incremental (rather than always the full backup) means each incremental only needs to store the delta since *yesterday*, not since last Sunday. For actively changing systems this keeps individual incremental sizes smaller. The trade-off is a slightly longer chain to follow during restore — but the restore script handles this automatically.

### Manual run

```bash
# Run a full backup first if no full backup exists yet
sudo /usr/local/bin/full_backup.sh

# Then run incremental
sudo /usr/local/bin/incremental_backup.sh
```

---

## restore.sh

Restores from any available full or incremental backup. Supports targeting a specific directory, restoring to a staging path, and dry-run mode for safe previewing.

### Usage

```bash
# List all available backup points
sudo restore.sh --list

# Preview what would be restored (no changes made)
sudo restore.sh --date 2025-03-26 --dry-run

# Full system restore from a specific date
sudo restore.sh --date 2025-03-26

# Restore only /etc from that backup
sudo restore.sh --date 2025-03-26 --source /etc

# Restore /home to a staging directory for inspection
sudo restore.sh --date 2025-03-26 --source /home --target /mnt/staging

# Restore from a specific incremental (timestamp format)
sudo restore.sh --date 2025-03-26_020001
```

### Options reference

| Option | Description |
|---|---|
| `--list` | Print all available full and incremental backups with sizes |
| `--date DATE` | Backup date to restore from. Format: `YYYY-MM-DD` for full, `YYYY-MM-DD_HHMMSS` for incremental |
| `--source PATH` | Restore only a specific directory (e.g. `/etc`) |
| `--target PATH` | Where to restore (default: `/` for in-place). Use `/mnt/staging` to inspect safely first |
| `--dry-run` | Show what rsync would do — no files changed |

### Safe restore workflow

Always follow this sequence in production:

```bash
# 1. List what's available
sudo restore.sh --list

# 2. Dry run to see what would change
sudo restore.sh --date 2025-03-26 --source /etc --dry-run

# 3. Restore to a staging path and verify contents
sudo restore.sh --date 2025-03-26 --source /etc --target /mnt/staging
ls -la /mnt/staging/etc/

# 4. Only then restore in-place
sudo restore.sh --date 2025-03-26 --source /etc
```

### How the date search works

The script first searches `/backup/incremental/` for a directory matching your `--date` pattern. If nothing matches, it falls back to `/backup/full/`. This means you can pass a partial date like `2025-03-26` and it will find `2025-03-26_020001` automatically.

---

## backup_monitor.sh

Runs a health check on the backup system and prints a colour-coded report. Can be scheduled to run every morning and send email alerts on problems.

### Checks performed

| Check | Pass condition | Warn condition |
|---|---|---|
| Full backup age | Newest full backup < 8 days old | ≥ 8 days old |
| Incremental age | Newest incremental < 26 hours old | ≥ 26 hours old |
| Disk usage | Backup volume < 85% full | ≥ 85% full |
| Log errors | No `[ERROR]` lines in backup logs | Any errors found |
| Backup integrity | Expected directories present in latest full backup | Missing directories |

### Sample output

```
====================================
 Backup Monitor — web-01
 2025-03-27 08:00:01
====================================

=== Full Backup ===
  [INFO]  Latest: 2025-03-23 | Age: 4 day(s) | Size: 12G
  [OK]    Full backup current

=== Incremental Backup ===
  [INFO]  Latest: 2025-03-26_020001 | Age: 6h | Size: 340M
  [OK]    Incremental current

=== Disk Space ===
  [INFO]  Usage: 62% | Free: 76G
  [OK]    Disk usage acceptable

=== Log Errors ===
  [OK]    full_backup.log: clean
  [OK]    incremental_backup.log: clean

=== Summary ===
  All checks passed.
```

### Manual run

```bash
sudo /usr/local/bin/backup_monitor.sh
```

---

## Cron Schedule

Install the cron schedule by dropping the provided file into `/etc/cron.d/`:

```bash
sudo cp scripts/backup_crontab /etc/cron.d/backup_system
sudo chmod 644 /etc/cron.d/backup_system
```

Or add to root's crontab manually:

```bash
sudo crontab -e
```

```cron
# Full backup — every Sunday at 2:00 AM
0 2 * * 0 root /usr/local/bin/full_backup.sh >> /var/log/backup/cron.log 2>&1

# Incremental backup — Monday through Saturday at 2:00 AM
0 2 * * 1-6 root /usr/local/bin/incremental_backup.sh >> /var/log/backup/cron.log 2>&1

# Health check — every day at 8:00 AM
0 8 * * * root /usr/local/bin/backup_monitor.sh >> /var/log/backup/monitor.log 2>&1
```

---

## Logging

Every script appends timestamped entries to its own log file:

| Log file | Written by |
|---|---|
| `/var/log/backup/full_backup.log` | `full_backup.sh` |
| `/var/log/backup/incremental_backup.log` | `incremental_backup.sh` |
| `/var/log/backup/restore.log` | `restore.sh` |
| `/var/log/backup/monitor.log` | `backup_monitor.sh` |
| `/var/log/backup/cron.log` | All scripts via cron redirect |

### Log format

```
[2025-03-26 02:00:01] [INFO ] Starting FULL backup on web-01
[2025-03-26 02:00:01] [INFO ] Target: /backup/full/2025-03-26
[2025-03-26 02:00:04] [OK   ] Completed: /etc
[2025-03-26 02:00:31] [OK   ] Completed: /home
[2025-03-26 02:01:02] [OK   ] Full backup COMPLETED SUCCESSFULLY in 61s.
```

### Checking logs

```bash
# Live tail during a backup
tail -f /var/log/backup/full_backup.log

# Show only errors
grep '\[ERROR\]' /var/log/backup/full_backup.log

# Show last successful run
grep 'COMPLETED SUCCESSFULLY' /var/log/backup/full_backup.log | tail -1
```

---

## Troubleshooting

**Backup fails with "Permission denied" on certain directories**

SELinux is likely blocking rsync. Check for AVC denials:
```bash
sudo ausearch -m avc -ts today | grep rsync
sudo setsebool -P rsync_full_access 1
```

**Lock file prevents backup from starting**

A previous run may have crashed without cleaning up. Check if the process is still running:
```bash
cat /var/run/full_backup.lock    # shows PID
ps aux | grep full_backup        # check if that PID exists
sudo rm /var/run/full_backup.lock  # safe to remove if process is gone
```

**Incremental fails with "No full backup found"**

Run a full backup first:
```bash
sudo /usr/local/bin/full_backup.sh
```

**Disk space warning from monitor**

Check what's consuming space and consider reducing retention:
```bash
du -sh /backup/full/* /backup/incremental/*
# Then edit RETENTION_WEEKS / RETENTION_DAYS in the scripts
```

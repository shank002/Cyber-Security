#!/bin/bash
# =============================================================================
# incremental_backup.sh - Production Incremental Backup Script for Rocky Linux
# =============================================================================
# Purpose  : Backs up only changed files since last full backup using hardlinks
#            Each incremental backup appears complete but only stores diffs.
# Schedule : Run daily Mon-Sat (e.g., at 2:00 AM via cron)
# Usage    : sudo ./incremental_backup.sh
# =============================================================================

set -euo pipefail

# -----------------------------------------------------------------------------
# CONFIGURATION — keep in sync with full_backup.sh
# -----------------------------------------------------------------------------
BACKUP_ROOT="/backup"
FULL_BACKUP_DIR="${BACKUP_ROOT}/full"
INCR_BACKUP_DIR="${BACKUP_ROOT}/incremental"
LOG_DIR="/var/log/backup"
LOG_FILE="${LOG_DIR}/incremental_backup.log"
LOCK_FILE="/var/run/incremental_backup.lock"
RETENTION_DAYS=30                          # How many daily incrementals to keep
ALERT_EMAIL=""                             # Set to email address for failure alerts

SOURCE_DIRS=(
    "/etc"
    "/home"
    "/root"
    "/var/www"
    "/var/lib/mysql"
    "/opt"
)

EXCLUDES=(
    "--exclude=/proc"
    "--exclude=/sys"
    "--exclude=/dev"
    "--exclude=/run"
    "--exclude=/tmp"
    "--exclude=/var/tmp"
    "--exclude=*.tmp"
    "--exclude=*.cache"
    "--exclude=/var/lib/mysql/*.sock"
)

# -----------------------------------------------------------------------------
# FUNCTIONS
# -----------------------------------------------------------------------------

log() {
    local level="$1"
    shift
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $*" | tee -a "${LOG_FILE}"
}

info()    { log "INFO " "$@"; }
success() { log "OK   " "$@"; }
warn()    { log "WARN " "$@"; }
error()   { log "ERROR" "$@"; }

send_alert() {
    local subject="$1"
    local message="$2"
    if [[ -n "${ALERT_EMAIL}" ]] && command -v mailx &>/dev/null; then
        echo "${message}" | mailx -s "${subject}" "${ALERT_EMAIL}"
    fi
}

check_root() {
    if [[ "${EUID}" -ne 0 ]]; then
        echo "ERROR: This script must be run as root." >&2
        exit 1
    fi
}

acquire_lock() {
    if [[ -f "${LOCK_FILE}" ]]; then
        local pid
        pid=$(cat "${LOCK_FILE}")
        if kill -0 "${pid}" 2>/dev/null; then
            error "Another backup is running (PID: ${pid}). Exiting."
            exit 1
        else
            warn "Stale lock file found. Removing."
            rm -f "${LOCK_FILE}"
        fi
    fi
    echo $$ > "${LOCK_FILE}"
}

release_lock() {
    rm -f "${LOCK_FILE}"
}

find_latest_full_backup() {
    # Returns the path of the most recent full backup directory
    find "${FULL_BACKUP_DIR}" -maxdepth 1 -type d -name "????-??-??" \
        | sort -r | head -n 1
}

find_latest_incremental() {
    # Returns the most recent incremental backup (to chain --link-dest)
    find "${INCR_BACKUP_DIR}" -maxdepth 1 -type d -name "????-??-??_*" \
        | sort -r | head -n 1
}

check_disk_space() {
    local available_kb
    available_kb=$(df -k "${BACKUP_ROOT}" | awk 'NR==2 {print $4}')
    local available_gb=$(( available_kb / 1024 / 1024 ))

    if [[ "${available_gb}" -lt 2 ]]; then
        error "Low disk space: ${available_gb}GB available. Aborting."
        send_alert "[BACKUP FAILED] Low disk space on $(hostname)" \
            "Incremental backup aborted. Only ${available_gb}GB free."
        exit 1
    fi
    info "Disk space check passed: ${available_gb}GB available."
}

rotate_old_incrementals() {
    info "Rotating incremental backups older than ${RETENTION_DAYS} days..."
    find "${INCR_BACKUP_DIR}" -maxdepth 1 -type d -name "????-??-??_*" \
        -mtime +${RETENTION_DAYS} \
        | while read -r old_dir; do
            warn "Removing old incremental: ${old_dir}"
            rm -rf "${old_dir}"
        done
}

# -----------------------------------------------------------------------------
# MAIN
# -----------------------------------------------------------------------------

TIMESTAMP=$(date '+%Y-%m-%d_%H%M%S')
TARGET_DIR="${INCR_BACKUP_DIR}/${TIMESTAMP}"
START_TIME=$(date +%s)

# Setup
check_root
mkdir -p "${LOG_DIR}" "${INCR_BACKUP_DIR}"
acquire_lock
trap 'release_lock' EXIT

info "========================================================"
info "Starting INCREMENTAL backup on $(hostname)"
info "Timestamp : ${TIMESTAMP}"
info "Target    : ${TARGET_DIR}"
info "========================================================"

check_disk_space

# Find the reference point for --link-dest
# Prefer the latest incremental for chained hardlinks; fall back to latest full
LINK_DEST=""
LATEST_INCR=$(find_latest_incremental)
LATEST_FULL=$(find_latest_full_backup)

if [[ -n "${LATEST_INCR}" ]]; then
    LINK_DEST="${LATEST_INCR}"
    info "Using latest incremental as link-dest: ${LINK_DEST}"
elif [[ -n "${LATEST_FULL}" ]]; then
    LINK_DEST="${LATEST_FULL}"
    info "No prior incremental found. Using latest full backup as link-dest: ${LINK_DEST}"
else
    error "No full backup found in ${FULL_BACKUP_DIR}."
    error "Please run full_backup.sh first before running incremental backups."
    send_alert "[BACKUP FAILED] $(hostname) - no base backup found" \
        "Incremental backup failed: no full backup exists to reference."
    exit 1
fi

mkdir -p "${TARGET_DIR}"

# Run rsync for each source
FAILED_SOURCES=()
for src in "${SOURCE_DIRS[@]}"; do
    if [[ ! -d "${src}" ]]; then
        warn "Source not found, skipping: ${src}"
        continue
    fi

    info "Incrementally backing up: ${src}"

    # --link-dest hardlinks unchanged files from the reference backup
    # so each incremental appears full but only stores what changed
    if rsync -aAXHz --delete --stats \
        "${EXCLUDES[@]}" \
        --link-dest="${LINK_DEST}/" \
        "${src}" \
        "${TARGET_DIR}/" \
        >> "${LOG_FILE}" 2>&1; then
        success "Completed: ${src}"
    else
        error "rsync failed for: ${src}"
        FAILED_SOURCES+=("${src}")
    fi
done

# Write metadata
cat > "${TARGET_DIR}/.backup_meta" <<EOF
backup_type=incremental
hostname=$(hostname)
timestamp=${TIMESTAMP}
link_dest=${LINK_DEST}
start_time=${START_TIME}
end_time=$(date +%s)
sources=${SOURCE_DIRS[*]}
EOF

# Rotate old incrementals
rotate_old_incrementals

END_TIME=$(date +%s)
DURATION=$(( END_TIME - START_TIME ))

if [[ ${#FAILED_SOURCES[@]} -gt 0 ]]; then
    error "Incremental backup COMPLETED WITH ERRORS in ${DURATION}s."
    error "Failed sources: ${FAILED_SOURCES[*]}"
    send_alert "[BACKUP WARNING] $(hostname) - partial failure" \
        "Incremental backup completed with errors.\nFailed: ${FAILED_SOURCES[*]}\nCheck: ${LOG_FILE}"
    exit 1
else
    success "Incremental backup COMPLETED SUCCESSFULLY in ${DURATION}s."
    success "Location: ${TARGET_DIR}"
    info "========================================================"
fi

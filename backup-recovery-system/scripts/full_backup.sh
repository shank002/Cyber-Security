#!/bin/bash
# =============================================================================
# full_backup.sh - Production Full Backup Script for Rocky Linux
# =============================================================================
# Purpose  : Performs a complete backup of specified source directories
# Schedule : Run weekly (e.g., every Sunday at 2:00 AM via cron)
# Usage    : sudo ./full_backup.sh
# =============================================================================

set -euo pipefail

# -----------------------------------------------------------------------------
# CONFIGURATION — edit these to match your environment
# -----------------------------------------------------------------------------
BACKUP_ROOT="/backup"
FULL_BACKUP_DIR="${BACKUP_ROOT}/full"
LOG_DIR="/var/log/backup"
LOG_FILE="${LOG_DIR}/full_backup.log"
LOCK_FILE="/var/run/full_backup.lock"
RETENTION_WEEKS=4                          # How many full backups to keep
ALERT_EMAIL=""                             # Set to email address for failure alerts (requires mailx)

# Directories to back up (space-separated)
SOURCE_DIRS=(
    "/etc"
    "/home"
    "/root"
    "/var/www"
    "/var/lib/mysql"     # Remove if not using MySQL
    "/opt"
)

# Directories/patterns to exclude
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
        info "Alert sent to ${ALERT_EMAIL}"
    fi
}

check_root() {
    if [[ "${EUID}" -ne 0 ]]; then
        echo "ERROR: This script must be run as root." >&2
        exit 1
    fi
}

check_dependencies() {
    local deps=("rsync" "df" "date" "tee")
    for dep in "${deps[@]}"; do
        if ! command -v "${dep}" &>/dev/null; then
            error "Required command not found: ${dep}"
            exit 1
        fi
    done
}

acquire_lock() {
    if [[ -f "${LOCK_FILE}" ]]; then
        local pid
        pid=$(cat "${LOCK_FILE}")
        if kill -0 "${pid}" 2>/dev/null; then
            error "Another backup is already running (PID: ${pid}). Exiting."
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

check_disk_space() {
    local target_dir="$1"
    local available_kb
    available_kb=$(df -k "${BACKUP_ROOT}" | awk 'NR==2 {print $4}')
    local available_gb=$(( available_kb / 1024 / 1024 ))

    if [[ "${available_gb}" -lt 5 ]]; then
        error "Low disk space on backup volume: ${available_gb}GB available."
        send_alert "[BACKUP FAILED] Low disk space on $(hostname)" \
            "Full backup aborted. Only ${available_gb}GB free on ${BACKUP_ROOT}."
        exit 1
    fi
    info "Disk space check passed: ${available_gb}GB available."
}

rotate_old_backups() {
    info "Rotating old full backups (keeping last ${RETENTION_WEEKS})..."
    local backup_count
    backup_count=$(find "${FULL_BACKUP_DIR}" -maxdepth 1 -type d -name "????-??-??" | wc -l)

    if [[ "${backup_count}" -gt "${RETENTION_WEEKS}" ]]; then
        local to_delete=$(( backup_count - RETENTION_WEEKS ))
        find "${FULL_BACKUP_DIR}" -maxdepth 1 -type d -name "????-??-??" \
            | sort | head -n "${to_delete}" \
            | while read -r old_backup; do
                warn "Removing old backup: ${old_backup}"
                rm -rf "${old_backup}"
            done
    else
        info "No rotation needed (${backup_count} full backup(s) on disk)."
    fi
}

# -----------------------------------------------------------------------------
# MAIN
# -----------------------------------------------------------------------------

TIMESTAMP=$(date '+%Y-%m-%d')
TARGET_DIR="${FULL_BACKUP_DIR}/${TIMESTAMP}"
START_TIME=$(date +%s)

# Setup
check_root
check_dependencies
mkdir -p "${LOG_DIR}" "${FULL_BACKUP_DIR}"
acquire_lock
trap 'release_lock' EXIT

info "========================================================"
info "Starting FULL backup on $(hostname)"
info "Timestamp : ${TIMESTAMP}"
info "Target    : ${TARGET_DIR}"
info "========================================================"

check_disk_space "${BACKUP_ROOT}"

# Skip if today's full backup already exists
if [[ -d "${TARGET_DIR}" ]]; then
    warn "Full backup for today already exists at ${TARGET_DIR}. Skipping."
    exit 0
fi

mkdir -p "${TARGET_DIR}"

# Run rsync for each source directory
FAILED_SOURCES=()
for src in "${SOURCE_DIRS[@]}"; do
    if [[ ! -d "${src}" ]]; then
        warn "Source directory not found, skipping: ${src}"
        continue
    fi

    info "Backing up: ${src}"
    if rsync -aAXHz --delete --stats \
        "${EXCLUDES[@]}" \
        "${src}" \
        "${TARGET_DIR}/" \
        >> "${LOG_FILE}" 2>&1; then
        success "Completed: ${src}"
    else
        error "rsync failed for: ${src}"
        FAILED_SOURCES+=("${src}")
    fi
done

# Write metadata file
cat > "${TARGET_DIR}/.backup_meta" <<EOF
backup_type=full
hostname=$(hostname)
timestamp=${TIMESTAMP}
start_time=${START_TIME}
end_time=$(date +%s)
sources=${SOURCE_DIRS[*]}
EOF

# Rotate old backups
rotate_old_backups

# Calculate duration
END_TIME=$(date +%s)
DURATION=$(( END_TIME - START_TIME ))

# Report result
if [[ ${#FAILED_SOURCES[@]} -gt 0 ]]; then
    error "Full backup COMPLETED WITH ERRORS in ${DURATION}s."
    error "Failed sources: ${FAILED_SOURCES[*]}"
    send_alert "[BACKUP WARNING] $(hostname) - partial failure" \
        "Full backup completed with errors.\nFailed: ${FAILED_SOURCES[*]}\nCheck: ${LOG_FILE}"
    exit 1
else
    success "Full backup COMPLETED SUCCESSFULLY in ${DURATION}s."
    success "Location: ${TARGET_DIR}"
    info "========================================================"
fi

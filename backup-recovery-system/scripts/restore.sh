#!/bin/bash
# =============================================================================
# restore.sh - Production Restore Script for Rocky Linux
# =============================================================================
# Purpose  : Safely restore from any full or incremental backup point.
#            Supports full system restore, single-directory restore, and
#            dry-run mode for safe previewing before committing changes.
#
# Usage    : sudo ./restore.sh [OPTIONS]
#
# Examples :
#   List available backups:
#     sudo ./restore.sh --list
#
#   Dry run (preview what would be restored, no changes made):
#     sudo ./restore.sh --date 2025-03-20 --dry-run
#
#   Restore everything from a specific date:
#     sudo ./restore.sh --date 2025-03-20
#
#   Restore only /etc from a specific incremental:
#     sudo ./restore.sh --date 2025-03-20_020001 --source /etc --target /etc
#
#   Restore /home to a staging directory for inspection:
#     sudo ./restore.sh --date 2025-03-20 --source /home --target /mnt/staging
# =============================================================================

set -euo pipefail

# -----------------------------------------------------------------------------
# CONFIGURATION
# -----------------------------------------------------------------------------
BACKUP_ROOT="/backup"
FULL_BACKUP_DIR="${BACKUP_ROOT}/full"
INCR_BACKUP_DIR="${BACKUP_ROOT}/incremental"
LOG_DIR="/var/log/backup"
LOG_FILE="${LOG_DIR}/restore.log"

# -----------------------------------------------------------------------------
# DEFAULTS
# -----------------------------------------------------------------------------
RESTORE_DATE=""
SOURCE_PATH=""          # Empty = restore all source dirs
TARGET_PATH="/"         # Default: restore in-place
DRY_RUN=false
LIST_MODE=false
BACKUP_TYPE="auto"      # auto | full | incremental

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

usage() {
    cat <<EOF

Usage: sudo $0 [OPTIONS]

Options:
  --list                  List all available backup points
  --date DATE             Backup date to restore from
                          Full backup format : YYYY-MM-DD  (e.g. 2025-03-20)
                          Incremental format : YYYY-MM-DD_HHMMSS
  --source PATH           Specific directory to restore (e.g. /etc)
                          Default: restore all backed-up directories
  --target PATH           Where to restore to (default: / for in-place restore)
                          Use a staging path like /mnt/restore for safe preview
  --type TYPE             Force backup type: full | incremental | auto (default: auto)
  --dry-run               Show what would be restored without making changes
  -h, --help              Show this help message

Examples:
  $0 --list
  $0 --date 2025-03-20 --dry-run
  $0 --date 2025-03-20
  $0 --date 2025-03-20_020001 --source /home --target /mnt/staging

EOF
    exit 0
}

check_root() {
    if [[ "${EUID}" -ne 0 ]]; then
        echo "ERROR: This script must be run as root." >&2
        exit 1
    fi
}

list_backups() {
    echo ""
    echo "========================================"
    echo " Available Full Backups"
    echo "========================================"
    if find "${FULL_BACKUP_DIR}" -maxdepth 1 -type d -name "????-??-??" | sort | grep -q .; then
        find "${FULL_BACKUP_DIR}" -maxdepth 1 -type d -name "????-??-??" | sort | while read -r d; do
            local date_str
            date_str=$(basename "${d}")
            local size
            size=$(du -sh "${d}" 2>/dev/null | cut -f1)
            local meta="${d}/.backup_meta"
            printf "  %-20s  size: %-8s" "${date_str}" "${size}"
            if [[ -f "${meta}" ]]; then
                local host
                host=$(grep '^hostname=' "${meta}" | cut -d= -f2)
                printf "  host: %s" "${host}"
            fi
            echo ""
        done
    else
        echo "  (no full backups found)"
    fi

    echo ""
    echo "========================================"
    echo " Available Incremental Backups"
    echo "========================================"
    if find "${INCR_BACKUP_DIR}" -maxdepth 1 -type d -name "????-??-??_*" | sort | grep -q .; then
        find "${INCR_BACKUP_DIR}" -maxdepth 1 -type d -name "????-??-??_*" | sort | while read -r d; do
            local date_str
            date_str=$(basename "${d}")
            local size
            size=$(du -sh "${d}" 2>/dev/null | cut -f1)
            local meta="${d}/.backup_meta"
            printf "  %-26s  size: %-8s" "${date_str}" "${size}"
            if [[ -f "${meta}" ]]; then
                local link
                link=$(grep '^link_dest=' "${meta}" | cut -d= -f2-)
                printf "  based on: %s" "$(basename "${link}")"
            fi
            echo ""
        done
    else
        echo "  (no incremental backups found)"
    fi
    echo ""
}

find_backup_dir() {
    local date="$1"

    # Try incremental first (longer format match)
    local incr_match
    incr_match=$(find "${INCR_BACKUP_DIR}" -maxdepth 1 -type d -name "${date}*" | sort -r | head -n 1)
    if [[ -n "${incr_match}" ]]; then
        echo "${incr_match}"
        return
    fi

    # Try full backup
    local full_match
    full_match=$(find "${FULL_BACKUP_DIR}" -maxdepth 1 -type d -name "${date}*" | sort -r | head -n 1)
    if [[ -n "${full_match}" ]]; then
        echo "${full_match}"
        return
    fi

    echo ""
}

confirm_restore() {
    local backup_dir="$1"
    local target="$2"

    echo ""
    echo "========================================"
    echo " RESTORE CONFIRMATION"
    echo "========================================"
    echo " Backup source : ${backup_dir}"
    echo " Restore target: ${target}"
    if [[ -n "${SOURCE_PATH}" ]]; then
        echo " Limiting to   : ${SOURCE_PATH}"
    fi
    echo ""

    if [[ "${target}" == "/" ]]; then
        echo " !! WARNING: This will overwrite files on your LIVE system !!"
        echo " !! Make sure no critical services depend on the paths being restored !!"
    fi
    echo ""

    read -r -p "Type 'yes' to proceed with the restore: " confirm
    if [[ "${confirm}" != "yes" ]]; then
        echo "Restore cancelled."
        exit 0
    fi
    echo ""
}

# -----------------------------------------------------------------------------
# ARGUMENT PARSING
# -----------------------------------------------------------------------------

while [[ $# -gt 0 ]]; do
    case "$1" in
        --list)           LIST_MODE=true; shift ;;
        --date)           RESTORE_DATE="$2"; shift 2 ;;
        --source)         SOURCE_PATH="$2"; shift 2 ;;
        --target)         TARGET_PATH="$2"; shift 2 ;;
        --type)           BACKUP_TYPE="$2"; shift 2 ;;
        --dry-run)        DRY_RUN=true; shift ;;
        -h|--help)        usage ;;
        *)                echo "Unknown option: $1"; usage ;;
    esac
done

# -----------------------------------------------------------------------------
# MAIN
# -----------------------------------------------------------------------------

check_root
mkdir -p "${LOG_DIR}"

if ${LIST_MODE}; then
    list_backups
    exit 0
fi

if [[ -z "${RESTORE_DATE}" ]]; then
    error "No --date specified. Use --list to see available backups."
    usage
fi

info "========================================================"
info "Starting RESTORE on $(hostname)"
info "Requested date : ${RESTORE_DATE}"
info "Target         : ${TARGET_PATH}"
[[ -n "${SOURCE_PATH}" ]] && info "Limiting to    : ${SOURCE_PATH}"
${DRY_RUN} && info "Mode           : DRY RUN (no changes will be made)"
info "========================================================"

# Locate the backup
BACKUP_DIR=$(find_backup_dir "${RESTORE_DATE}")

if [[ -z "${BACKUP_DIR}" ]]; then
    error "No backup found for date: ${RESTORE_DATE}"
    error "Use --list to see available backups."
    exit 1
fi

info "Found backup: ${BACKUP_DIR}"

# Read metadata if present
META_FILE="${BACKUP_DIR}/.backup_meta"
if [[ -f "${META_FILE}" ]]; then
    BACKUP_TYPE_ACTUAL=$(grep '^backup_type=' "${META_FILE}" | cut -d= -f2)
    BACKUP_HOST=$(grep '^hostname=' "${META_FILE}" | cut -d= -f2)
    info "Backup type    : ${BACKUP_TYPE_ACTUAL}"
    info "Backed up from : ${BACKUP_HOST}"
fi

# Ensure target exists
mkdir -p "${TARGET_PATH}"

# Build rsync options
RSYNC_OPTS=(-aAXHz --delete --stats)
${DRY_RUN} && RSYNC_OPTS+=(--dry-run)

# Determine what to restore
if [[ -n "${SOURCE_PATH}" ]]; then
    # Restore specific path
    # Strip leading slash for rsync relative path matching
    RELATIVE_PATH="${SOURCE_PATH#/}"
    RSYNC_SRC="${BACKUP_DIR}/${RELATIVE_PATH}/"

    if [[ ! -d "${RSYNC_SRC}" ]]; then
        error "Path not found in backup: ${RSYNC_SRC}"
        exit 1
    fi

    if ! ${DRY_RUN}; then
        confirm_restore "${RSYNC_SRC}" "${TARGET_PATH}/${RELATIVE_PATH}"
    fi

    info "Restoring ${SOURCE_PATH} -> ${TARGET_PATH}/${RELATIVE_PATH} ..."
    mkdir -p "${TARGET_PATH}/${RELATIVE_PATH}"

    if rsync "${RSYNC_OPTS[@]}" \
        "${RSYNC_SRC}" \
        "${TARGET_PATH}/${RELATIVE_PATH}/" \
        | tee -a "${LOG_FILE}"; then
        success "Restore of ${SOURCE_PATH} completed."
    else
        error "rsync failed during restore of ${SOURCE_PATH}."
        exit 1
    fi
else
    # Restore everything from backup
    if ! ${DRY_RUN}; then
        confirm_restore "${BACKUP_DIR}" "${TARGET_PATH}"
    fi

    FAILED=()
    for subdir in "${BACKUP_DIR}"/*/; do
        [[ -d "${subdir}" ]] || continue
        local_name=$(basename "${subdir}")
        info "Restoring /${local_name} -> ${TARGET_PATH}/${local_name} ..."
        mkdir -p "${TARGET_PATH}/${local_name}"

        if rsync "${RSYNC_OPTS[@]}" \
            "${subdir}" \
            "${TARGET_PATH}/${local_name}/" \
            >> "${LOG_FILE}" 2>&1; then
            success "Restored: /${local_name}"
        else
            error "Failed to restore: /${local_name}"
            FAILED+=("/${local_name}")
        fi
    done

    if [[ ${#FAILED[@]} -gt 0 ]]; then
        error "Restore completed with errors. Failed: ${FAILED[*]}"
        exit 1
    fi
fi

END_MSG="Restore COMPLETED SUCCESSFULLY"
${DRY_RUN} && END_MSG="Dry run COMPLETED (no changes made)"
success "${END_MSG}"
info "Log: ${LOG_FILE}"
info "========================================================"

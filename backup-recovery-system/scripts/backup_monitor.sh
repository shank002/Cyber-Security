#!/bin/bash
# =============================================================================
# backup_monitor.sh - Backup Health Check & Status Report
# =============================================================================
# Purpose  : Verifies backup integrity, checks for missed backups, reports
#            storage usage, and prints a status summary. Run anytime manually
#            or schedule via cron for a daily health check.
#
# Usage    : sudo ./backup_monitor.sh
# Schedule : 0 8 * * * /usr/local/bin/backup_monitor.sh   (daily at 8am)
# =============================================================================

set -euo pipefail

BACKUP_ROOT="/backup"
FULL_BACKUP_DIR="${BACKUP_ROOT}/full"
INCR_BACKUP_DIR="${BACKUP_ROOT}/incremental"
LOG_DIR="/var/log/backup"
ALERT_EMAIL=""          # Set for email alerts on problems found

WARN_FULL_AGE_DAYS=8    # Alert if newest full backup is older than this
WARN_INCR_AGE_HOURS=26  # Alert if newest incremental is older than this
WARN_DISK_PERCENT=85    # Alert if disk usage exceeds this %

# -----------------------------------------------------------------------------

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color
BOLD='\033[1m'

ISSUES=()

section() { echo -e "\n${BOLD}${BLUE}=== $* ===${NC}"; }
ok()      { echo -e "  ${GREEN}[OK]${NC}    $*"; }
warn()    { echo -e "  ${YELLOW}[WARN]${NC}  $*"; ISSUES+=("WARN: $*"); }
fail()    { echo -e "  ${RED}[FAIL]${NC}  $*"; ISSUES+=("FAIL: $*"); }
info()    { echo -e "  ${BLUE}[INFO]${NC}  $*"; }

# -----------------------------------------------------------------------------

check_last_full_backup() {
    section "Full Backup Status"

    local latest
    latest=$(find "${FULL_BACKUP_DIR}" -maxdepth 1 -type d -name "????-??-??" 2>/dev/null | sort -r | head -n 1)

    if [[ -z "${latest}" ]]; then
        fail "No full backup found in ${FULL_BACKUP_DIR}"
        return
    fi

    local date_str
    date_str=$(basename "${latest}")
    local size
    size=$(du -sh "${latest}" 2>/dev/null | cut -f1)

    # Calculate age in days
    local backup_epoch
    backup_epoch=$(date -d "${date_str}" +%s 2>/dev/null || date -j -f "%Y-%m-%d" "${date_str}" +%s 2>/dev/null)
    local now_epoch
    now_epoch=$(date +%s)
    local age_days=$(( (now_epoch - backup_epoch) / 86400 ))

    info "Latest full backup : ${date_str} (${size})"
    info "Age                : ${age_days} day(s)"

    if [[ ${age_days} -gt ${WARN_FULL_AGE_DAYS} ]]; then
        warn "Full backup is ${age_days} days old (threshold: ${WARN_FULL_AGE_DAYS} days)"
    else
        ok "Full backup is current"
    fi

    # Count total full backups
    local count
    count=$(find "${FULL_BACKUP_DIR}" -maxdepth 1 -type d -name "????-??-??" | wc -l)
    info "Total full backups on disk: ${count}"
}

check_last_incremental() {
    section "Incremental Backup Status"

    local latest
    latest=$(find "${INCR_BACKUP_DIR}" -maxdepth 1 -type d -name "????-??-??_*" 2>/dev/null | sort -r | head -n 1)

    if [[ -z "${latest}" ]]; then
        warn "No incremental backups found in ${INCR_BACKUP_DIR}"
        return
    fi

    local dir_name
    dir_name=$(basename "${latest}")
    local size
    size=$(du -sh "${latest}" 2>/dev/null | cut -f1)

    # Age in hours
    local mod_time
    mod_time=$(stat -c %Y "${latest}")
    local now_epoch
    now_epoch=$(date +%s)
    local age_hours=$(( (now_epoch - mod_time) / 3600 ))

    info "Latest incremental : ${dir_name} (${size})"
    info "Age                : ${age_hours} hour(s)"

    if [[ ${age_hours} -gt ${WARN_INCR_AGE_HOURS} ]]; then
        warn "Incremental backup is ${age_hours}h old (threshold: ${WARN_INCR_AGE_HOURS}h)"
    else
        ok "Incremental backup is current"
    fi

    local count
    count=$(find "${INCR_BACKUP_DIR}" -maxdepth 1 -type d -name "????-??-??_*" | wc -l)
    info "Total incrementals on disk: ${count}"
}

check_disk_space() {
    section "Disk Space"

    local df_output
    df_output=$(df -h "${BACKUP_ROOT}" | awk 'NR==2')
    local used_pct
    used_pct=$(echo "${df_output}" | awk '{print $5}' | tr -d '%')
    local avail
    avail=$(echo "${df_output}" | awk '{print $4}')
    local total
    total=$(echo "${df_output}" | awk '{print $2}')

    info "Backup volume  : ${BACKUP_ROOT}"
    info "Total / Free   : ${total} / ${avail}"
    info "Used           : ${used_pct}%"

    if [[ ${used_pct} -ge ${WARN_DISK_PERCENT} ]]; then
        warn "Disk usage is at ${used_pct}% (threshold: ${WARN_DISK_PERCENT}%)"
    else
        ok "Disk usage acceptable (${used_pct}%)"
    fi

    echo ""
    info "Breakdown by backup type:"
    for dir in "${FULL_BACKUP_DIR}" "${INCR_BACKUP_DIR}"; do
        if [[ -d "${dir}" ]]; then
            local s
            s=$(du -sh "${dir}" | cut -f1)
            info "  $(basename "${dir}"): ${s}"
        fi
    done
}

check_log_for_errors() {
    section "Recent Log Activity"

    local logs=("${LOG_DIR}/full_backup.log" "${LOG_DIR}/incremental_backup.log")
    for log in "${logs[@]}"; do
        if [[ ! -f "${log}" ]]; then
            warn "Log file not found: ${log}"
            continue
        fi

        local log_name
        log_name=$(basename "${log}")
        local error_count
        error_count=$(grep -c '\[ERROR\]' "${log}" 2>/dev/null || echo 0)
        local last_ok
        last_ok=$(grep '\[OK   \].*COMPLETED SUCCESSFULLY' "${log}" 2>/dev/null | tail -n 1 || echo "none")

        info "Log: ${log_name}"
        if [[ ${error_count} -gt 0 ]]; then
            warn "  ${error_count} error(s) found in ${log_name}"
            info "  Last 3 errors:"
            grep '\[ERROR\]' "${log}" | tail -n 3 | while read -r line; do
                echo "    ${line}"
            done
        else
            ok "  No errors in ${log_name}"
        fi
        info "  Last success: ${last_ok}"
    done
}

check_backup_contents() {
    section "Backup Integrity Spot Check"

    local latest_full
    latest_full=$(find "${FULL_BACKUP_DIR}" -maxdepth 1 -type d -name "????-??-??" 2>/dev/null | sort -r | head -n 1)

    if [[ -z "${latest_full}" ]]; then
        fail "No full backup to check"
        return
    fi

    # Check that expected top-level dirs are present
    local expected_dirs=("etc" "home")
    for d in "${expected_dirs[@]}"; do
        if [[ -d "${latest_full}/${d}" ]]; then
            local file_count
            file_count=$(find "${latest_full}/${d}" -type f | wc -l)
            ok "/${d} present in full backup (${file_count} files)"
        else
            warn "/${d} missing from full backup at ${latest_full}"
        fi
    done

    # Verify metadata file
    if [[ -f "${latest_full}/.backup_meta" ]]; then
        ok "Metadata file present"
    else
        warn "Metadata file missing from ${latest_full}"
    fi
}

print_summary() {
    section "Summary"

    if [[ ${#ISSUES[@]} -eq 0 ]]; then
        echo -e "  ${GREEN}${BOLD}All checks passed. Backup system is healthy.${NC}"
    else
        echo -e "  ${YELLOW}${BOLD}${#ISSUES[@]} issue(s) found:${NC}"
        for issue in "${ISSUES[@]}"; do
            echo -e "    ${YELLOW}• ${issue}${NC}"
        done

        if [[ -n "${ALERT_EMAIL}" ]] && command -v mailx &>/dev/null; then
            local body
            body="Backup monitor report for $(hostname) at $(date)\n\nIssues found:\n"
            for issue in "${ISSUES[@]}"; do
                body+="  - ${issue}\n"
            done
            echo -e "${body}" | mailx -s "[BACKUP ALERT] $(hostname) - ${#ISSUES[@]} issue(s)" "${ALERT_EMAIL}"
            echo ""
            info "Alert sent to ${ALERT_EMAIL}"
        fi
    fi
    echo ""
}

# -----------------------------------------------------------------------------
# MAIN
# -----------------------------------------------------------------------------

echo -e "${BOLD}"
echo "========================================================"
echo " Backup Monitor Report"
echo " Host    : $(hostname)"
echo " Date    : $(date '+%Y-%m-%d %H:%M:%S')"
echo "========================================================"
echo -e "${NC}"

check_last_full_backup
check_last_incremental
check_disk_space
check_log_for_errors
check_backup_contents
print_summary

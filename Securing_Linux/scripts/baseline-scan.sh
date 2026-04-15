#!/usr/bin/env bash
# Baseline Lynis Security Scan
# Project: Linux Hardening + CIS Benchmark
# Usage: sudo bash baseline-scan.sh
# Run this BEFORE harden.sh to capture your starting score.

set -euo pipefail

REPORT_DIR="/var/log/hardening-project"
BASELINE_REPORT="$REPORT_DIR/lynis-baseline.dat"
BASELINE_LOG="$REPORT_DIR/lynis-baseline.log"

echo "============================================="
echo "  Linux Hardening — Baseline Assessment"
echo "============================================="
echo ""

# Create report directory
mkdir -p "$REPORT_DIR"

# Install Lynis if not present
if ! command -v lynis &>/dev/null; then
  echo "[*] Lynis not found. Installing..."
  if command -v apt &>/dev/null; then
    apt install lynis -y
  elif command -v dnf &>/dev/null; then
    dnf install lynis -y
  else
    echo "[!] Cannot install Lynis automatically. Please install it manually."
    exit 1
  fi
fi

echo "[*] Running Lynis baseline audit..."
lynis audit system \
  --report-file "$BASELINE_REPORT" \
  --logfile "$BASELINE_LOG" \
  --quiet

echo ""
echo "[+] Baseline scan complete."
echo ""

# Extract and display score
SCORE=$(grep "hardening_index" "$BASELINE_REPORT" | cut -d'=' -f2)
echo "============================================="
echo "  BASELINE HARDENING INDEX: $SCORE / 100"
echo "============================================="
echo ""
echo "Reports saved to:"
echo "  Log:    $BASELINE_LOG"
echo "  Report: $BASELINE_REPORT"
echo ""
echo "Next step: sudo bash scripts/harden.sh"

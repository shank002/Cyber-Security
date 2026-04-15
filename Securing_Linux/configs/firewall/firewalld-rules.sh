#!/usr/bin/env bash
# firewalld Hardening Rules — RHEL / CentOS / Fedora
# Project: Linux Hardening + CIS Benchmark
# Usage: sudo bash firewalld-rules.sh

set -euo pipefail

echo "[*] Enabling and starting firewalld..."
systemctl enable --now firewalld

echo "[*] Setting default zone to drop..."
firewall-cmd --set-default-zone=drop

echo "[*] Adding SSH on custom port 2222..."
firewall-cmd --permanent --add-port=2222/tcp

echo "[*] Adding HTTP and HTTPS..."
firewall-cmd --permanent --add-service=http
firewall-cmd --permanent --add-service=https

echo "[*] Reloading firewalld..."
firewall-cmd --reload

echo ""
echo "[+] firewalld rules applied."
echo "[+] Current configuration:"
firewall-cmd --list-all

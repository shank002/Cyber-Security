#!/usr/bin/env bash
# iptables Hardening Rules — Debian / Ubuntu
# Project: Linux Hardening + CIS Benchmark
# Usage: sudo bash iptables-rules.sh

set -euo pipefail

echo "[*] Flushing existing iptables rules..."
iptables -F
iptables -X
iptables -Z

echo "[*] Setting default DROP policies..."
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT

echo "[*] Allowing loopback interface..."
iptables -A INPUT -i lo -j ACCEPT

echo "[*] Allowing established and related traffic..."
iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

echo "[*] Allowing SSH (port 2222)..."
iptables -A INPUT -p tcp --dport 2222 -m conntrack --ctstate NEW -j ACCEPT

echo "[*] Allowing HTTP and HTTPS..."
iptables -A INPUT -p tcp --dport 80 -m conntrack --ctstate NEW -j ACCEPT
iptables -A INPUT -p tcp --dport 443 -m conntrack --ctstate NEW -j ACCEPT

echo "[*] Logging dropped packets (optional)..."
iptables -A INPUT -m limit --limit 5/min -j LOG --log-prefix "[iptables-DROP] " --log-level 7

echo "[*] Saving rules with netfilter-persistent..."
netfilter-persistent save

echo ""
echo "[+] iptables rules applied and saved."
echo "[+] Current ruleset:"
iptables -L -v -n

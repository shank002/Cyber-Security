#!/usr/bin/env bash
# check-mysql-connectivity.sh
# ─────────────────────────────────────────────────────────────────────────────
# Diagnoses whether a MariaDB/MySQL server is reachable and what network
# interfaces it is listening on. Useful for auditing remote access configuration.
#
# Usage (run on the DB server):
#   chmod +x check-mysql-connectivity.sh
#   ./check-mysql-connectivity.sh
#
# Usage (check remote server from another machine):
#   ./check-mysql-connectivity.sh <server_ip>
# ─────────────────────────────────────────────────────────────────────────────

set -euo pipefail

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

TARGET="${1:-127.0.0.1}"
PORT=3306

echo ""
echo -e "${BLUE}═══════════════════════════════════════════════${NC}"
echo -e "${BLUE}   MySQL / MariaDB Connectivity Check${NC}"
echo -e "${BLUE}   Target: ${TARGET}:${PORT}${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════${NC}"
echo ""

# ── 1. Is MariaDB service running? (local only) ───────────────────────────────
if [[ "$TARGET" == "127.0.0.1" || "$TARGET" == "localhost" ]]; then
    echo -e "${YELLOW}[1] MariaDB service status:${NC}"
    if systemctl is-active --quiet mariadb 2>/dev/null; then
        echo -e "    ${GREEN}✔ mariadb.service is active (running)${NC}"
    elif systemctl is-active --quiet mysqld 2>/dev/null; then
        echo -e "    ${GREEN}✔ mysqld.service is active (running)${NC}"
    else
        echo -e "    ${RED}✘ MariaDB / MySQL does not appear to be running${NC}"
        echo -e "      Fix: sudo systemctl start mariadb"
    fi
    echo ""

    # ── 2. What interface is MariaDB listening on? ────────────────────────────
    echo -e "${YELLOW}[2] Listening interfaces (ss -tlnp | grep $PORT):${NC}"
    LISTEN=$(ss -tlnp 2>/dev/null | grep ":${PORT}" || true)
    if [[ -z "$LISTEN" ]]; then
        echo -e "    ${RED}✘ No process listening on port $PORT${NC}"
    else
        echo "$LISTEN" | while read -r line; do
            if echo "$line" | grep -q "0.0.0.0"; then
                echo -e "    ${YELLOW}⚠ Listening on 0.0.0.0:$PORT — remote access is OPEN${NC}"
            elif echo "$line" | grep -q "127.0.0.1"; then
                echo -e "    ${GREEN}✔ Listening on 127.0.0.1:$PORT — localhost only (secure)${NC}"
            else
                echo -e "    ${YELLOW}⚠ $line${NC}"
            fi
        done
    fi
    echo ""

    # ── 3. bind-address from config ──────────────────────────────────────────
    echo -e "${YELLOW}[3] bind-address in MariaDB config:${NC}"
    BIND=$(grep -r "bind.address" /etc/my.cnf /etc/my.cnf.d/ 2>/dev/null | grep -v "^#" | head -1 || true)
    if [[ -z "$BIND" ]]; then
        echo -e "    ${GREEN}✔ bind-address not explicitly set — defaults to 127.0.0.1${NC}"
    else
        echo -e "    Found: $BIND"
    fi
    echo ""

    # ── 4. List DB users ──────────────────────────────────────────────────────
    echo -e "${YELLOW}[4] Database users and host scope:${NC}"
    echo -e "    Run this SQL to view user access:"
    echo -e "    ${BLUE}mysql -u root -p -e \"SELECT user, host FROM mysql.user;\"${NC}"
    echo ""
fi

# ── 5. TCP port reachability test ────────────────────────────────────────────
echo -e "${YELLOW}[5] TCP port reachability test (nc -zv $TARGET $PORT):${NC}"
if command -v nc &>/dev/null; then
    if nc -zv "$TARGET" "$PORT" 2>&1 | grep -q "succeeded\|open\|Connected"; then
        echo -e "    ${GREEN}✔ Port $PORT is reachable on $TARGET${NC}"
    else
        echo -e "    ${RED}✘ Port $PORT is NOT reachable on $TARGET${NC}"
        echo -e "      Possible causes:"
        echo -e "        - MariaDB not running"
        echo -e "        - bind-address = 127.0.0.1 (if testing remotely)"
        echo -e "        - firewall blocking port $PORT"
    fi
else
    echo -e "    ${YELLOW}⚠ nc (netcat) not installed. Install with: sudo dnf install nmap-ncat -y${NC}"
fi
echo ""

# ── 6. Firewall check ────────────────────────────────────────────────────────
echo -e "${YELLOW}[6] Firewall — port $PORT status:${NC}"
if command -v firewall-cmd &>/dev/null; then
    if firewall-cmd --list-ports 2>/dev/null | grep -q "${PORT}/tcp"; then
        echo -e "    ${YELLOW}⚠ Port $PORT/tcp is OPEN in firewalld${NC}"
        echo -e "      (Only needed if remote DB access is intentional)"
    else
        echo -e "    ${GREEN}✔ Port $PORT/tcp is NOT open in firewalld (localhost only — correct)${NC}"
    fi
else
    echo -e "    ${YELLOW}⚠ firewall-cmd not found — check firewall manually${NC}"
fi
echo ""

echo -e "${BLUE}═══════════════════════════════════════════════${NC}"
echo -e "${BLUE}   Check complete.${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════${NC}"
echo ""

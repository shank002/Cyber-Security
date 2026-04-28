#!/usr/bin/env bash
# install-stack.sh
# ─────────────────────────────────────────────────────────────────────────────
# Full automated install of the Nexus stack on Rocky Linux.
# Installs: Nginx, Node.js v22, MariaDB, PM2.
# Configures: firewalld, SELinux boolean, Nginx reverse proxy.
#
# Usage:
#   chmod +x install-stack.sh
#   sudo ./install-stack.sh
#
# Prerequisites:
#   - Rocky Linux 8 or 9
#   - A non-root sudo user running the script
#   - Internet access
# ─────────────────────────────────────────────────────────────────────────────

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log()  { echo -e "${GREEN}[✔]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }
fail() { echo -e "${RED}[✘]${NC} $1"; exit 1; }

# ── Guard: must be run as root or with sudo ───────────────────────────────────
[[ "$EUID" -ne 0 ]] && fail "Please run with sudo."

echo ""
echo "═══════════════════════════════════════════════════"
echo "   Nexus Stack Installer — Rocky Linux"
echo "═══════════════════════════════════════════════════"
echo ""

# ── 1. System update ─────────────────────────────────────────────────────────
log "Updating system packages..."
dnf update -y -q
dnf install -y -q epel-release

# ── 2. Nginx ─────────────────────────────────────────────────────────────────
log "Installing Nginx..."
dnf install -y -q nginx
systemctl enable --now nginx
log "Nginx installed and started."

# ── 3. Firewall ──────────────────────────────────────────────────────────────
log "Configuring firewalld (HTTP + HTTPS only)..."
firewall-cmd --permanent --add-service=http  -q
firewall-cmd --permanent --add-service=https -q
firewall-cmd --reload -q
log "Firewall configured."

# ── 4. SELinux boolean ───────────────────────────────────────────────────────
log "Installing SELinux management tools..."
dnf install -y -q policycoreutils-python-utils

log "Enabling httpd_can_network_connect (required for Nginx → Node.js proxy)..."
setsebool -P httpd_can_network_connect 1
log "SELinux boolean set."

# ── 5. MariaDB ───────────────────────────────────────────────────────────────
log "Installing MariaDB..."
dnf install -y -q mariadb-server
systemctl enable --now mariadb
log "MariaDB installed and started."
warn "Run 'sudo mysql_secure_installation' manually to harden MariaDB."
warn "Then create your database and user (see docs/04-mariadb-setup.md)."

# ── 6. Node.js ───────────────────────────────────────────────────────────────
log "Adding NodeSource repository (Node.js v22 LTS)..."
curl -fsSL https://rpm.nodesource.com/setup_22.x | bash - >/dev/null 2>&1
dnf install -y -q nodejs
log "Node.js $(node -v) installed."

# ── 7. PM2 ───────────────────────────────────────────────────────────────────
log "Installing PM2..."
npm install -g pm2 -q
log "PM2 installed."

# ── 8. Nginx config ───────────────────────────────────────────────────────────
log "Deploying Nginx reverse proxy config..."
cat > /etc/nginx/conf.d/myapp.conf <<'NGINXCONF'
server {
    listen 80;
    server_name _;

    location /css/ {
        root    /var/www/myapp/public;
        expires 7d;
    }

    location / {
        proxy_pass          http://127.0.0.1:3000;
        proxy_http_version  1.1;
        proxy_set_header    Host              $host;
        proxy_set_header    X-Real-IP         $remote_addr;
        proxy_set_header    X-Forwarded-For   $proxy_add_x_forwarded_for;
        proxy_set_header    X-Forwarded-Proto $scheme;
        proxy_set_header    Upgrade           $http_upgrade;
        proxy_set_header    Connection        'upgrade';
        proxy_cache_bypass  $http_upgrade;
    }
}
NGINXCONF

nginx -t && systemctl reload nginx
log "Nginx reverse proxy configured."

# ── 9. App directory ─────────────────────────────────────────────────────────
log "Creating app directory at /var/www/myapp..."
mkdir -p /var/www/myapp/public/css
mkdir -p /var/www/myapp/views/partials

# Set ownership to the invoking user
REAL_USER="${SUDO_USER:-$USER}"
chown -R "$REAL_USER":"$REAL_USER" /var/www/myapp
log "App directory created, owned by $REAL_USER."

# ── Done ─────────────────────────────────────────────────────────────────────
echo ""
echo "═══════════════════════════════════════════════════"
echo "   Installation complete!"
echo "═══════════════════════════════════════════════════"
echo ""
echo "Next steps:"
echo "  1. Run: sudo mysql_secure_installation"
echo "  2. Create DB and user: see docs/04-mariadb-setup.md"
echo "  3. Deploy your app to /var/www/myapp/"
echo "  4. cd /var/www/myapp && npm install"
echo "  5. pm2 start index.js --name myapp"
echo "  6. pm2 startup systemd && pm2 save"
echo ""
echo "  VM IP: $(ip -4 addr show | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | grep -v 127 | head -1)"
echo ""

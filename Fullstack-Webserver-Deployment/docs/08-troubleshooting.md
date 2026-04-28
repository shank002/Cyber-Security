# 08 — Troubleshooting

A reference for every error encountered during this project, with the root cause and exact fix.

---

## 502 Bad Gateway

**Symptom:** Nginx returns `502 Bad Gateway` when accessing the site.

**Diagnosis:**

```bash
# Step 1: Is Node.js actually running?
pm2 list
curl http://127.0.0.1:3000/

# Step 2: Is Nginx config valid?
sudo nginx -t

# Step 3: Check Nginx error log
sudo tail -20 /var/log/nginx/error.log
```

**If `curl http://127.0.0.1:3000/` works but `curl http://127.0.0.1/` gives 502:**

SELinux is blocking Nginx from connecting to Node.js. This is the most common cause on Rocky Linux.

```bash
sudo dnf install policycoreutils-python-utils -y
sudo setsebool -P httpd_can_network_connect 1
sudo systemctl reload nginx
```

See [SELinux Configuration](06-selinux-configuration.md) for full details.

---

## `setsebool: command not found`

**Symptom:** Running `setsebool` returns `command not found`.

**Cause:** `policycoreutils-python-utils` is not installed.

**Fix:**
```bash
sudo dnf install policycoreutils-python-utils -y
```

---

## `Cannot find module 'ejs'` (or any other module)

**Symptom:** Starting the app with `node index.js` or `pm2 start` fails with a module not found error.

**Cause:** `node_modules/` was not installed. This happens when app files are copied to the server manually without running `npm install`.

**Fix:**
```bash
cd /var/www/myapp
npm install
```

If the error persists for a specific package:
```bash
npm install ejs express mysql2 bcrypt express-session
```

---

## Node.js App Not Starting After Reboot

**Symptom:** The app was running before reboot but is not running after.

**Cause:** PM2's startup hook was not configured.

**Fix:**
```bash
pm2 startup systemd
# Run the command PM2 outputs
pm2 save
```

This registers PM2 as a systemd service so it launches on boot and restores all saved processes.

---

## MariaDB Connection Refused from Node.js

**Symptom:** Node.js logs show `Error: connect ECONNREFUSED 127.0.0.1:3306`.

**Diagnosis:**
```bash
sudo systemctl status mariadb
```

**Fix — if MariaDB is stopped:**
```bash
sudo systemctl start mariadb
sudo systemctl enable mariadb
```

**Fix — if MariaDB is running but Node.js credentials are wrong:**
```bash
mysql -u myapp_user -p myapp_db
```

If this fails, the username, password, or database name in `.env` doesn't match what's in MariaDB. Verify with:
```sql
SELECT user, host FROM mysql.user;
SHOW DATABASES;
```

---

## Nginx Config Syntax Error

**Symptom:** `sudo nginx -t` returns an error; Nginx fails to reload.

**Common mistakes:**

| Mistake | Fix |
|---------|-----|
| Missing semicolon at end of directive | Add `;` |
| Wrong `proxy_pass` URL (typo in port) | Check it matches Node.js port (`3000`) |
| Missing closing `}` brace | Count your braces |

Always run `sudo nginx -t` before `sudo systemctl reload nginx`. Never reload without testing first.

---

## `proxy_pass` Not Highlighted in Editor

**Symptom:** `proxy_pass` appears in plain text (no syntax highlighting) in VS Code while other Nginx directives highlight correctly.

**Cause:** Missing Nginx syntax extension.

**Fix:** Install the VS Code extension:

- Name: **NGINX Configuration**
- Publisher: William Tjørnelund
- Extension ID: `william-tjornelund.vscode-nginx-conf`

Search "nginx" in the VS Code Extensions panel and install the top result.

---

## Firewall Blocking Web Traffic

**Symptom:** Can reach the server locally (`curl http://127.0.0.1/`) but not from host browser.

**Diagnosis:**
```bash
sudo firewall-cmd --list-all
```

**Fix:**
```bash
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --permanent --add-service=https
sudo firewall-cmd --reload
```

---

## Port 3000 Accessible from Outside (Security Issue)

**Symptom:** You can reach `http://<server-ip>:3000` directly from a browser, bypassing Nginx.

**Fix:** Do not add port 3000 to firewalld. Node.js should only be reachable through Nginx:

```bash
# Confirm port 3000 is NOT open
sudo firewall-cmd --list-ports
# Should not show 3000/tcp
```

If 3000 was accidentally opened:
```bash
sudo firewall-cmd --permanent --remove-port=3000/tcp
sudo firewall-cmd --reload
```

---

## General Debugging Workflow

When something is broken, work through the chain from the bottom up:

```bash
# 1. Is MariaDB healthy?
sudo systemctl status mariadb
mysql -u myapp_user -p myapp_db -e "SELECT 1;"

# 2. Is Node.js healthy?
pm2 list
pm2 logs myapp --lines 30
curl http://127.0.0.1:3000/

# 3. Is Nginx healthy?
sudo nginx -t
sudo systemctl status nginx
curl http://127.0.0.1/
sudo tail -20 /var/log/nginx/error.log

# 4. Is SELinux interfering?
sudo ausearch -m avc -ts recent   # Recent SELinux denials
getsebool httpd_can_network_connect

# 5. Is the firewall correct?
sudo firewall-cmd --list-all
```

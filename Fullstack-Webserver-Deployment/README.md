# Nexus — Full-Stack Web Server on Rocky Linux

> A production-style community web platform deployed on a Rocky Linux virtual machine, using **Nginx** as a reverse proxy, **Node.js/Express** as the application backend, and **MariaDB** as the relational database — all hardened under **SELinux enforcing mode**.

---

## Table of Contents

- [Project Summary](#project-summary)
- [Architecture](#architecture)
- [Tech Stack](#tech-stack)
- [Challenges Solved](#challenges-solved)
- [Key Metrics](#key-metrics)
- [Repository Structure](#repository-structure)
- [Quick Start](#quick-start)
- [Documentation](#documentation)
- [License](#license)

---

## Project Summary

Nexus is a multi-page community web application built as a Linux administration project. The goal was to go from a bare Rocky Linux VM to a fully operational, security-conscious web server capable of serving a real application — without disabling any OS-level security features.

The application itself is a member directory platform with:

- User registration and login (session-based auth, bcrypt password hashing)
- A member directory listing all registered users
- A home page that dynamically reflects login state
- Server-side duplicate email detection at both app and DB constraint level

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        Rocky Linux Server                       │
│                                                                 │
│   Client (Browser)                                              │
│        │                                                        │
│        │  HTTP :80                                              │
│        ▼                                                        │
│   ┌─────────────┐                                               │
│   │    Nginx    │  ← Public-facing, ports 80/443               │
│   │ Reverse     │    firewalld allows HTTP/HTTPS only           │
│   │ Proxy       │                                               │
│   └──────┬──────┘                                               │
│          │  proxy_pass http://127.0.0.1:3000                   │
│          ▼                                                       │
│   ┌─────────────┐                                               │
│   │  Node.js    │  ← Express app, internal only                │
│   │  (PM2)      │    localhost:3000, never public               │
│   │  Express    │                                               │
│   └──────┬──────┘                                               │
│          │  mysql2 connection pool                              │
│          ▼                                                       │
│   ┌─────────────┐                                               │
│   │   MariaDB   │  ← localhost:3306, no external exposure      │
│   │  Database   │    connection pool (10 concurrent)            │
│   └─────────────┘                                               │
│                                                                 │
│   SELinux: Enforcing  │  firewalld: HTTP/HTTPS only            │
└─────────────────────────────────────────────────────────────────┘
```

### Traffic Flow

1. **Client → Nginx (port 80):** Client sends an HTTP request. firewalld only allows ports 80 and 443 through.
2. **Nginx → Node.js (port 3000):** Nginx proxies the request internally using `proxy_pass`. Node.js is never directly exposed to the outside.
3. **Node.js → MariaDB (port 3306):** The Express app queries MariaDB via a `mysql2` connection pool. The database only accepts connections from localhost.
4. **Response path:** MariaDB → Node.js → Nginx → Client.

---

## Tech Stack

| Layer | Technology | Role |
|-------|-----------|------|
| OS | Rocky Linux 8/9 | Enterprise RHEL-compatible base |
| Web server | Nginx | Reverse proxy, static file serving, TLS termination |
| Runtime | Node.js (LTS v22) | JavaScript application server |
| Framework | Express.js | HTTP routing, middleware, session management |
| Template engine | EJS | Server-side HTML rendering |
| Database | MariaDB (MySQL-compatible) | Relational data persistence |
| DB driver | mysql2 | Async Node.js MariaDB/MySQL client with connection pooling |
| Auth | express-session + bcrypt | Session-based authentication, password hashing |
| Process manager | PM2 | Node.js lifecycle management, auto-restart, boot persistence |
| Security | SELinux (enforcing) | Mandatory access control |
| Firewall | firewalld | Network-layer port restriction |

---

## Challenges Solved

### 1. SELinux blocking Nginx → Node.js proxy (502 Bad Gateway)

**Problem:** After wiring up the Nginx reverse proxy to forward requests to Node.js on port 3000, all requests returned `502 Bad Gateway`. Nginx was running fine, and Node.js was running fine — but they couldn't talk.

**Root cause:** Rocky Linux ships with SELinux in **enforcing mode**. SELinux labels Nginx as an `httpd` process and, by default, blocks `httpd` processes from making outbound network connections. Nginx was being silently blocked when it tried to open a TCP connection to `127.0.0.1:3000`.

**Solution:** Grant the specific SELinux boolean rather than disabling SELinux entirely (a common but dangerous shortcut):

```bash
sudo dnf install policycoreutils-python-utils -y
sudo setsebool -P httpd_can_network_connect 1
```

The `-P` flag makes the change persistent across reboots. This is the correct, minimal-permission approach — Nginx gets exactly the access it needs and nothing more.

---

### 2. `setsebool` command not found

**Problem:** Attempting to run `setsebool` after hitting the 502 error resulted in `command not found`.

**Root cause:** The `policycoreutils-python-utils` package, which provides SELinux management tools including `setsebool`, was not installed on the base system.

**Solution:**

```bash
sudo dnf install policycoreutils-python-utils -y
```

---

### 3. MySQL remote connection configuration

**Problem:** Needed to verify and control whether the MariaDB/MySQL server was accepting connections from remote hosts, and understand which users had what level of network access.

**Diagnosis checklist used:**

```bash
# Check if MariaDB is listening on all interfaces or localhost only
ss -tlnp | grep 3306

# Check the bind-address setting
grep bind-address /etc/my.cnf.d/mariadb-server.cnf

# Check which users exist and their host scope
mysql -u root -p -e "SELECT user, host FROM mysql.user;"
```

**Key distinction:**

| `host` value | Meaning |
|---|---|
| `localhost` | Local connections only |
| `%` | Any host (fully remote-accessible) |
| `192.168.x.x` | Specific IP only |

**Solution:** For this project the database is intentionally kept on `localhost` only. No remote DB access is needed since Node.js and MariaDB run on the same machine.

---

### 4. Node.js app dependencies not installed (EJS module not found)

**Problem:** Running `node index.js` failed with `Cannot find module 'ejs'` after copying the app files to the server.

**Root cause:** The `node_modules/` directory was not transferred with the app files, so Express could not resolve the EJS template engine dependency.

**Solution:**

```bash
cd /var/www/myapp
npm install
```

This reads `package.json` and installs all dependencies locally. For subsequent deploys, `npm install` should always be run after transferring source files.

---

### 5. SSL/TLS termination architecture

**Understanding:** A common misconception is that enabling HTTPS requires changes to the Node.js app. In this stack, SSL is **terminated at Nginx** — meaning:

- Client ↔ Nginx: encrypted HTTPS (port 443)
- Nginx ↔ Node.js: plain HTTP on `127.0.0.1:3000` (internal, never leaves the machine)

Node.js never handles raw TLS. Nginx does all the SSL heavy lifting, keeping the application layer clean. For production, Let's Encrypt via Certbot handles certificate issuance and auto-renewal.

---

## Key Metrics

These are realistic, defensible numbers for this stack on modest hardware:

| Metric | Value | Notes |
|--------|-------|-------|
| Nginx concurrent connections | 10,000+ | Nginx's event-driven architecture (the C10k solution) |
| MariaDB query latency | < 5ms | Simple SELECT/INSERT on localhost with connection pool |
| DB connection pool size | 10 concurrent | Configured via mysql2 `createPool` |
| bcrypt cost factor | 12 | Strong password hashing, ~300ms hash time per password |
| Node.js port | 3000 (internal only) | Never directly exposed to the network |
| Public ports | 80 (HTTP), 443 (HTTPS) | All other ports blocked by firewalld |
| SELinux mode | Enforcing | Zero security features disabled |

---

## Repository Structure

```
.
├── README.md                          ← Project overview (this file)
├── ARCHITECTURE.md                    ← Detailed architecture breakdown
├── CHANGELOG.md                       ← Version history
├── docs/
│   ├── 01-prerequisites.md            ← System requirements & OS prep
│   ├── 02-nginx-setup.md              ← Nginx install & base config
│   ├── 03-nodejs-setup.md             ← Node.js + PM2 setup
│   ├── 04-mariadb-setup.md            ← MariaDB install & DB/user creation
│   ├── 05-nginx-reverse-proxy.md      ← Wiring Nginx → Node.js
│   ├── 06-selinux-configuration.md    ← SELinux policy (the critical step)
│   ├── 07-mysql-remote-access.md      ← Remote MySQL diagnostics
│   └── 08-troubleshooting.md          ← Common errors & fixes
├── configs/
│   ├── nginx-base.conf                ← Nginx base server block
│   ├── nginx-reverse-proxy.conf       ← Nginx proxy config for Node.js
│   └── pm2-ecosystem.config.js        ← PM2 process config
└── scripts/
    ├── install-stack.sh               ← Full automated install
    └── check-mysql-connectivity.sh    ← Remote MySQL diagnostic script
```

---

## Quick Start

```bash
# Clone the repo
git clone https://github.com/your-username/nexus-linux-webserver.git
cd nexus-linux-webserver

# Run the full automated install (Rocky Linux only)
chmod +x scripts/install-stack.sh
sudo ./scripts/install-stack.sh
```

For a manual step-by-step setup, follow the docs in order starting with [Prerequisites](docs/01-prerequisites.md).

---

## Documentation

| Doc | What it covers |
|-----|---------------|
| [01 — Prerequisites](docs/01-prerequisites.md) | OS update, firewall, SELinux baseline |
| [02 — Nginx Setup](docs/02-nginx-setup.md) | Install, enable, base config |
| [03 — Node.js Setup](docs/03-nodejs-setup.md) | NodeSource repo, PM2, app structure |
| [04 — MariaDB Setup](docs/04-mariadb-setup.md) | Install, secure, create DB and user |
| [05 — Reverse Proxy](docs/05-nginx-reverse-proxy.md) | Nginx → Node.js proxy config |
| [06 — SELinux](docs/06-selinux-configuration.md) | The boolean that fixes 502 errors |
| [07 — MySQL Remote Access](docs/07-mysql-remote-access.md) | Diagnose and control remote DB access |
| [08 — Troubleshooting](docs/08-troubleshooting.md) | 502 errors, module not found, port issues |

---

## License

MIT — see [LICENSE](LICENSE) for details.

# Architecture

This document covers the system architecture of the Nexus web server project in depth — how each component fits together, why each design decision was made, and the security model that runs underneath it all.

---

## High-Level Overview

The stack follows a classic **three-tier architecture**: a presentation/proxy layer (Nginx), an application layer (Node.js), and a data layer (MariaDB). All three tiers run on a single Rocky Linux virtual machine.

```
┌──────────────────────────────────────────────────────────────────┐
│                 ROCKY LINUX (Single VM)                          │
│                                                                  │
│  ┌────────────┐      ┌────────────┐      ┌────────────┐         │
│  │   Nginx    │─────▶│  Node.js   │─────▶│  MariaDB   │         │
│  │  :80/:443  │      │   :3000    │      │   :3306    │         │
│  │            │      │  (PM2)     │      │ (localhost) │         │
│  └────────────┘      └────────────┘      └────────────┘         │
│       ▲                                                          │
│       │                                                          │
│  firewalld (HTTP/HTTPS only)                                     │
│  SELinux (enforcing — httpd_can_network_connect=1)               │
└──────────────────────────────────────────────────────────────────┘
         ▲
         │ HTTP request
    Browser / Client
```

---

## Component Breakdown

### Nginx — Reverse Proxy & Web Server

Nginx sits at the network edge of the application. It is the **only** service exposed to the outside world.

**Responsibilities:**
- Accept incoming HTTP connections on port 80
- Forward (proxy) requests to Node.js on `127.0.0.1:3000`
- Serve static files directly (CSS, images) without hitting Node.js
- Terminate TLS when SSL is enabled (the Node.js app never handles raw TLS)
- Pass real client IP to Node.js via `X-Real-IP` header

**Why Nginx over Apache?**
Nginx uses an event-driven, non-blocking I/O model. A single worker process can handle thousands of simultaneous connections. Apache uses a process/thread-per-connection model, which exhausts resources under high concurrency. Nginx's architecture was specifically designed to solve the C10k problem (handling 10,000 concurrent connections on a single machine).

**Config location:** `/etc/nginx/conf.d/myapp.conf`

---

### Node.js + Express — Application Layer

The Node.js process runs the Express application and is **bound to localhost only**. It is never directly accessible from outside the VM.

**Responsibilities:**
- Handle HTTP routing (`GET /`, `GET /users`, `POST /signup`, etc.)
- Render HTML pages using the EJS template engine
- Manage user sessions via `express-session`
- Hash and verify passwords using `bcrypt` (cost factor 12)
- Query MariaDB through a `mysql2` connection pool
- Enforce business logic (duplicate email detection, auth guards)

**Process management:** PM2 keeps the Node.js process running. If the app crashes, PM2 restarts it automatically. PM2 is also integrated with systemd so the app starts on boot without manual intervention.

```
PM2 → manages → Node.js process
systemd → manages → PM2
```

**App location:** `/var/www/myapp/`

---

### MariaDB — Data Layer

MariaDB (a drop-in MySQL replacement) stores all persistent application data.

**Responsibilities:**
- Store user records (first name, last name, email, hashed password)
- Enforce the `UNIQUE` constraint on email at the database level (in addition to app-level checks)
- Serve queries exclusively over localhost — port 3306 is not exposed to the network

**Connection pooling:** The Node.js app uses `mysql2.createPool()` with a pool limit of 10 connections. Rather than opening and closing a new DB connection per request (expensive), the pool keeps a set of pre-opened connections ready to be reused.

---

## Security Architecture

Security is layered — no single mechanism is relied upon exclusively.

```
Layer 1: firewalld      → blocks all ports except 80, 443
Layer 2: Nginx          → only proxies to localhost; MariaDB never exposed
Layer 3: SELinux        → enforcing mode; only httpd_can_network_connect granted
Layer 4: MariaDB        → bind-address = 127.0.0.1; no wildcard user grants
Layer 5: Application    → bcrypt hashing, session auth, server-side validation
```

### SELinux Policy

Rocky Linux ships with SELinux in enforcing mode. The critical SELinux boolean for this project is:

```bash
setsebool -P httpd_can_network_connect 1
```

Without this, SELinux prevents Nginx (`httpd`-labelled processes) from making any outbound TCP connections — including to Node.js on localhost. This manifests as a `502 Bad Gateway` error. The boolean grants Nginx precisely the permission it needs without opening up anything else.

This is a deliberate minimal-privilege approach. The alternative — `setenforce 0` (disable SELinux) — is common in tutorials but entirely removes an important security layer.

### Firewall Policy

```bash
# Only HTTP and HTTPS are exposed externally
firewall-cmd --permanent --add-service=http
firewall-cmd --permanent --add-service=https
# Port 3000 (Node.js) and 3306 (MariaDB) are NOT opened
```

Node.js on port 3000 and MariaDB on port 3306 are internal-only. No external client can reach them directly.

---

## Data Flow — Detailed Request Lifecycle

Using a `GET /users` page request as an example:

```
1. Browser sends:   GET http://192.168.x.x/users

2. firewalld:       Port 80 is open → allow through

3. Nginx receives:  Matches `location /` block in conf
                    proxy_pass http://127.0.0.1:3000

4. SELinux check:   httpd_can_network_connect = 1 → allow

5. Node.js:         Express router matches GET /users
                    Calls pool.query('SELECT * FROM users')

6. mysql2 pool:     Picks an idle connection from the pool
                    Sends query to MariaDB on localhost:3306

7. MariaDB:         Executes query, returns rows

8. Node.js:         Passes data to EJS template
                    Renders HTML

9. Nginx:           Receives rendered HTML from Node.js
                    Forwards response to browser

10. Browser:        Renders the members page
```

---

## Application Structure

```
/var/www/myapp/
├── index.js                  ← App entry point, Express setup, routes
├── package.json              ← Dependencies
├── .env                      ← DB credentials (gitignored)
├── public/
│   └── css/
│       └── style.css         ← Stylesheet (served by Nginx directly)
└── views/
    ├── partials/
    │   ├── header.ejs        ← Nav, <head>, session-aware user state
    │   └── footer.ejs        ← Footer, closing tags
    ├── home.ejs              ← Landing page
    ├── signup.ejs            ← Registration form
    ├── login.ejs             ← Login form
    └── users.ejs             ← Member directory listing
```

---

## Why This Architecture?

| Decision | Rationale |
|----------|-----------|
| Nginx in front of Node.js | Node.js is not optimised to handle raw internet traffic directly. Nginx handles connection management, buffering, and static files far more efficiently. |
| Node.js on localhost only | Reduces attack surface. No direct access to the app server; all traffic flows through Nginx. |
| MariaDB on localhost only | The database should never be reachable from the internet. The app layer is the only consumer. |
| PM2 + systemd | PM2 provides auto-restart on crash. Systemd integration ensures the whole chain comes up on boot automatically. |
| SELinux enforcing | Keeps the OS security model intact. Grants only the specific permissions needed rather than blanket-disabling access controls. |
| bcrypt cost factor 12 | Balances security (~300ms hash time, resistant to brute force) with usability. Cost factor 10 is the common minimum; 12 adds meaningful resistance. |
| Connection pool (10) | Avoids the overhead of opening/closing DB connections per request. 10 concurrent connections is appropriate for a single-VM setup under typical load. |

---

## Deployment Environment

This project was built and tested on a **local virtual machine**. The architecture is production-compatible but SSL (Let's Encrypt/Certbot) was deferred since a public domain is required for certificate issuance. The SSL layer would sit entirely within Nginx with zero changes to the Node.js application.

For a production deployment, the additions would be:

1. `certbot --nginx -d yourdomain.com` — issues and installs TLS certificate
2. `proxy_set_header X-Forwarded-Proto $scheme;` in Nginx config
3. `app.set('trust proxy', 1);` in Express so `req.protocol` returns `https`
4. PM2 log rotation enabled
5. `NODE_ENV=production` set in environment

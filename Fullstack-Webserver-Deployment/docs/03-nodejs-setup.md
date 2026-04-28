# 03 — Node.js Setup

Node.js runs the Express application on `localhost:3000`. It is never directly exposed to the network — Nginx proxies all traffic to it internally.

---

## Install Node.js (LTS v22 via NodeSource)

Rocky Linux's default repos ship an outdated Node.js version. Use NodeSource for the current LTS:

```bash
curl -fsSL https://rpm.nodesource.com/setup_22.x | sudo bash -
sudo dnf install nodejs -y
```

Verify:
```bash
node -v   # e.g. v22.x.x
npm -v    # e.g. 10.x.x
```

---

## Create the App Directory

```bash
sudo mkdir -p /var/www/myapp
sudo chown $USER:$USER /var/www/myapp
cd /var/www/myapp
npm init -y
```

---

## Install Dependencies

```bash
npm install express ejs mysql2 bcrypt express-session
```

| Package | Purpose |
|---------|---------|
| `express` | HTTP framework, routing, middleware |
| `ejs` | Server-side HTML templating |
| `mysql2` | Async MariaDB/MySQL driver with connection pool support |
| `bcrypt` | Password hashing (cost factor 12) |
| `express-session` | Session-based authentication |

For environment variable management in production, also add:
```bash
npm install dotenv
```

---

## Environment Variables

Store database credentials in a `.env` file — never hardcode them:

```bash
nano /var/www/myapp/.env
```

```env
DB_HOST=localhost
DB_USER=myapp_user
DB_PASSWORD=StrongPassword123!
DB_NAME=myapp_db
SESSION_SECRET=replace-this-with-a-random-string
PORT=3000
```

Add `.env` to your `.gitignore`:
```bash
echo ".env" >> /var/www/myapp/.gitignore
echo "node_modules/" >> /var/www/myapp/.gitignore
```

---

## Install PM2 (Process Manager)

PM2 keeps the app running and restarts it automatically on crash.

```bash
sudo npm install -g pm2
```

Start the app:
```bash
cd /var/www/myapp
pm2 start index.js --name myapp
```

Set PM2 to launch on boot:
```bash
pm2 startup systemd
# Run the command that PM2 prints
pm2 save
```

---

## PM2 Commands

```bash
pm2 list                    # Show all managed processes
pm2 status                  # Short status view
pm2 logs myapp              # Live log stream
pm2 logs myapp --lines 50   # Last 50 log lines
pm2 restart myapp           # Restart the app
pm2 stop myapp              # Stop the app
pm2 delete myapp            # Remove from PM2
```

---

## Verify the App is Running

Check Node.js is responding on port 3000 (locally):
```bash
curl http://127.0.0.1:3000/
```

If you get a JSON response or HTML back, Node.js is working. Then check that Nginx is forwarding correctly:
```bash
curl http://127.0.0.1/
```

If this also works, the full Nginx → Node.js chain is functional.

---

## App Structure

```
/var/www/myapp/
├── index.js              ← Entry point: Express app, routes, DB pool
├── package.json          ← Dependencies and scripts
├── .env                  ← Secrets (gitignored)
├── .gitignore
├── public/
│   └── css/
│       └── style.css     ← Served as static asset by Nginx
└── views/
    ├── partials/
    │   ├── header.ejs    ← Nav, <head>, session-aware
    │   └── footer.ejs    ← Closing footer and tags
    ├── home.ejs          ← Landing page
    ├── signup.ejs        ← Registration form
    ├── login.ejs         ← Login form
    └── users.ejs         ← Member directory
```

---

## Next Step

→ [Install and configure MariaDB](04-mariadb-setup.md)

# 02 — Nginx Setup

Nginx is the public-facing component of the stack. It accepts all incoming HTTP traffic and proxies it to Node.js. It also serves static assets (CSS, images) directly without touching Node.js.

---

## Install Nginx

```bash
sudo dnf install nginx -y
```

---

## Enable and Start

```bash
sudo systemctl enable --now nginx
```

Verify:
```bash
sudo systemctl status nginx
```

Look for `Active: active (running)`.

---

## Test the Default Page

```bash
curl http://127.0.0.1/
```

You should see the Nginx default HTML welcome page. If you can also hit it from your host browser at `http://<VM-IP>/`, the firewall is open correctly.

---

## Directory Layout

| Path | Purpose |
|------|---------|
| `/etc/nginx/nginx.conf` | Main Nginx config (leave mostly as-is) |
| `/etc/nginx/conf.d/` | Drop per-site config files here |
| `/usr/share/nginx/html/` | Default web root |
| `/var/log/nginx/access.log` | Access logs |
| `/var/log/nginx/error.log` | Error logs (check here first when debugging) |

---

## Base Site Config

Create your application's server block:

```bash
sudo nano /etc/nginx/conf.d/myapp.conf
```

Paste the following (replace `server_name` when you have a domain — for a VM, `_` accepts any host/IP):

```nginx
server {
    listen 80;
    server_name _;

    # Proxy all requests to Node.js
    location / {
        proxy_pass         http://127.0.0.1:3000;
        proxy_http_version 1.1;
        proxy_set_header   Host              $host;
        proxy_set_header   X-Real-IP         $remote_addr;
        proxy_set_header   X-Forwarded-For   $proxy_add_x_forwarded_for;
    }
}
```

> **Note:** `proxy_pass` not highlighting in your editor is cosmetic — it is a valid Nginx directive. Install the "NGINX Configuration" extension in VS Code (publisher: william-tjornelund) for proper syntax highlighting.

---

## Validate and Reload

Always test the config before reloading:

```bash
sudo nginx -t
```

Expected:
```
nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
nginx: configuration file /etc/nginx/nginx.conf test is successful
```

Then reload:
```bash
sudo systemctl reload nginx
```

---

## Common Commands

```bash
sudo systemctl start nginx      # Start
sudo systemctl stop nginx       # Stop
sudo systemctl reload nginx     # Reload config (no downtime)
sudo systemctl restart nginx    # Full restart
sudo nginx -t                   # Test config syntax
sudo tail -f /var/log/nginx/error.log   # Watch error log live
```

---

## Next Step

→ [Install Node.js and set up the application](03-nodejs-setup.md)

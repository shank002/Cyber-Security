# 05 — Nginx Reverse Proxy

This is where Nginx is wired to forward traffic to the Node.js application. After this step, requests hitting port 80 will be transparently proxied to Node.js on `localhost:3000`.

---

## How the Proxy Works

```
Client request → Nginx :80 → proxy_pass → Node.js :3000
                                              ↓
Client response ← Nginx ← rendered HTML ← Node.js
```

Nginx acts as a middleman. The client never communicates with Node.js directly.

---

## Config File

Create or edit the site config:

```bash
sudo nano /etc/nginx/conf.d/myapp.conf
```

```nginx
server {
    listen 80;
    server_name _;          # accepts any hostname or IP — good for VM use

    # Proxy all dynamic requests to Node.js
    location / {
        proxy_pass          http://127.0.0.1:3000;
        proxy_http_version  1.1;

        # Pass real client info to Node.js
        proxy_set_header    Host              $host;
        proxy_set_header    X-Real-IP         $remote_addr;
        proxy_set_header    X-Forwarded-For   $proxy_add_x_forwarded_for;

        # Required for WebSocket support (optional, good practice)
        proxy_set_header    Upgrade           $http_upgrade;
        proxy_set_header    Connection        'upgrade';

        proxy_cache_bypass  $http_upgrade;
    }
}
```

### What each directive does

| Directive | Purpose |
|-----------|---------|
| `proxy_pass` | Forwards the request to Node.js on port 3000 |
| `proxy_http_version 1.1` | Enables keepalive connections to Node.js |
| `proxy_set_header Host` | Tells Node.js the original hostname requested |
| `proxy_set_header X-Real-IP` | Passes the real client IP (otherwise Node.js would see Nginx's `127.0.0.1`) |
| `proxy_set_header X-Forwarded-For` | Standard proxy identification chain |
| `Upgrade` / `Connection` | Enables WebSocket proxying if needed |

---

## Validate and Reload

```bash
sudo nginx -t && sudo systemctl reload nginx
```

---

## Test the Full Chain

Check that Nginx correctly forwards to Node.js:

```bash
# Direct to Node.js (bypass Nginx)
curl http://127.0.0.1:3000/

# Through Nginx (full proxy chain)
curl http://127.0.0.1/
```

Both should return the same response. If the first works but the second gives a `502`, proceed to [SELinux Configuration](06-selinux-configuration.md) — that is almost certainly the cause.

---

## Serving Static Files Directly

For better performance, Nginx can serve static files (CSS, images) directly without proxying to Node.js. Add a `location` block before the proxy block:

```nginx
server {
    listen 80;
    server_name _;

    # Serve static files directly from disk
    location /css/ {
        root /var/www/myapp/public;
        expires 7d;
        add_header Cache-Control "public";
    }

    # Proxy everything else to Node.js
    location / {
        proxy_pass         http://127.0.0.1:3000;
        proxy_http_version 1.1;
        proxy_set_header   Host            $host;
        proxy_set_header   X-Real-IP       $remote_addr;
        proxy_set_header   X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
```

---

## SSL — Adding HTTPS Later

When you have a public domain, adding HTTPS requires no changes to Node.js. Certbot handles everything at the Nginx level:

```bash
sudo dnf install certbot python3-certbot-nginx -y
sudo certbot --nginx -d yourdomain.com -d www.yourdomain.com
```

Certbot auto-edits your Nginx config to add port 443 and sets up automatic certificate renewal. The traffic flow becomes:

```
Client → Nginx :443 (HTTPS) → proxy_pass → Node.js :3000 (HTTP, internal)
```

Node.js continues to run plain HTTP on localhost. Nginx terminates TLS. Nothing in the app changes.

---

## Next Step

→ [Configure SELinux to allow the proxy connection](06-selinux-configuration.md)

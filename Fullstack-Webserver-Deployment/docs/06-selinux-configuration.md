# 06 — SELinux Configuration

This is the most commonly missed step when setting up Nginx as a reverse proxy on Rocky Linux. If you're getting `502 Bad Gateway` after configuring the proxy, SELinux is almost certainly the reason.

---

## What SELinux Does

Rocky Linux ships with SELinux in **enforcing mode** — meaning everything not explicitly permitted is blocked. SELinux labels each process with a security context. Nginx is labelled as an `httpd` process.

By default, SELinux's policy for `httpd` processes is:

> Nginx can accept incoming connections. It cannot make outbound connections.

This means Nginx can receive your browser's request, but the moment it tries to open a TCP connection to `127.0.0.1:3000` (Node.js), SELinux silently drops it. Nginx then returns `502 Bad Gateway`.

The fix is a single boolean that grants exactly the permission needed — nothing more.

---

## Step 1 — Install SELinux Management Tools

The `setsebool` command requires `policycoreutils-python-utils`, which is not always present on base Rocky Linux installs:

```bash
sudo dnf install policycoreutils-python-utils -y
```

Without this, running `setsebool` will return `command not found`.

---

## Step 2 — Enable the Boolean

```bash
sudo setsebool -P httpd_can_network_connect 1
```

### What this command means

| Part | Meaning |
|------|---------|
| `setsebool` | Set a SELinux boolean (an on/off policy switch) |
| `-P` | **Persistent** — the setting survives reboots |
| `httpd_can_network_connect` | The boolean — controls whether `httpd`-labelled processes (Nginx) can make outbound TCP connections |
| `1` | Turn it **on** |

Without `-P`, the boolean resets to off on the next reboot and your `502` comes back.

---

## Step 3 — Reload Nginx and Test

```bash
sudo systemctl reload nginx
curl http://127.0.0.1/
```

You should now get a valid response from Node.js through Nginx.

---

## Why Not Just Disable SELinux?

Many tutorials suggest:
```bash
sudo setenforce 0           # Temporary disable
# or
sudo sed -i 's/SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config  # Permanent
```

**Do not do this.** Disabling SELinux removes a mandatory access control layer that protects the entire system. If any service on the machine is compromised, SELinux limits the blast radius. Disabling it for the convenience of skipping one `setsebool` command is not a worthwhile trade-off.

The correct approach is always to grant the specific permission your application needs.

---

## Check Current SELinux Status

```bash
sestatus
```

```
SELinux status:                 enabled
Current mode:                   enforcing
```

Check the value of the boolean:
```bash
getsebool httpd_can_network_connect
```

Expected after applying the fix:
```
httpd_can_network_connect --> on
```

---

## Other Useful SELinux Booleans for Web Servers

| Boolean | When to use it |
|---------|----------------|
| `httpd_can_network_connect` | Nginx/Apache proxying to a backend on localhost |
| `httpd_can_network_connect_db` | Nginx connecting directly to a remote database |
| `httpd_can_sendmail` | Allow web server to send email |
| `httpd_read_user_content` | Allow Nginx to serve files from user home directories |

---

## Setting SELinux File Contexts

If you move your web root to a non-default location (e.g., `/var/www/myapp`), Nginx may not be able to read files from it. Fix with:

```bash
sudo semanage fcontext -a -t httpd_sys_content_t "/var/www/myapp(/.*)?"
sudo restorecon -Rv /var/www/myapp
```

This labels all files in `/var/www/myapp` with the correct SELinux type so Nginx can read them.

---

## Next Step

→ [Understanding and managing MySQL remote access](07-mysql-remote-access.md)

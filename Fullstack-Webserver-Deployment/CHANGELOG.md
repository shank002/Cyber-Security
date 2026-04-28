# Changelog

All notable changes to this project are documented here.

---

## [1.0.0] — Initial Release

### Added
- Rocky Linux base setup with `dnf update` and EPEL repo
- Nginx installation and base configuration
- firewalld rules restricting public access to ports 80 and 443
- MariaDB installation, `mysql_secure_installation` hardening
- `myapp_db` database and `myapp_user` created with scoped privileges
- Node.js v22 LTS via NodeSource RPM repository
- Express.js app with EJS template engine
- `mysql2` connection pool (10 connections) wired to MariaDB
- Session-based authentication via `express-session`
- bcrypt password hashing at cost factor 12
- Duplicate email detection at both app and DB constraint level
- PM2 process manager with systemd startup integration
- Nginx reverse proxy config (`proxy_pass` to `localhost:3000`)
- SELinux `httpd_can_network_connect` boolean enabled (fixes 502)
- `policycoreutils-python-utils` installed for `setsebool` access
- Multi-page EJS views: home, signup, login, users (member directory)
- Responsive CSS stylesheet served via Nginx as static asset

### Architecture decisions documented
- Why Nginx sits in front of Node.js
- Why MariaDB is localhost-only
- SELinux minimal-privilege approach vs disabling enforcement
- TLS termination at Nginx (Node.js unchanged for SSL)

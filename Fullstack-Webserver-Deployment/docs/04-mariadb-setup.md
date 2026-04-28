# 04 — MariaDB Setup

MariaDB is the relational database backend. It runs exclusively on localhost — port 3306 is never exposed to the network.

---

## Install MariaDB

```bash
sudo dnf install mariadb-server -y
```

---

## Enable and Start

```bash
sudo systemctl enable --now mariadb
```

Verify:
```bash
sudo systemctl status mariadb
```

---

## Secure the Installation

Run the security wizard immediately after installation:

```bash
sudo mysql_secure_installation
```

When prompted, answer as follows:

| Prompt | Recommended answer |
|--------|--------------------|
| Set root password? | Yes — choose a strong password |
| Remove anonymous users? | Yes |
| Disallow root login remotely? | Yes |
| Remove test database? | Yes |
| Reload privilege tables? | Yes |

---

## Create the Application Database and User

Log in as root:
```bash
sudo mysql -u root -p
```

Run these SQL commands:

```sql
-- Create the database
CREATE DATABASE myapp_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- Create a dedicated app user (localhost only)
CREATE USER 'myapp_user'@'localhost' IDENTIFIED BY 'StrongPassword123!';

-- Grant privileges only on the app database
GRANT ALL PRIVILEGES ON myapp_db.* TO 'myapp_user'@'localhost';

-- Apply changes
FLUSH PRIVILEGES;

EXIT;
```

> Use a strong, unique password. Store it in your `.env` file, not in code.

---

## Create the Users Table

Connect with the app user and create the schema:

```bash
mysql -u myapp_user -p myapp_db
```

```sql
CREATE TABLE users (
    id            INT AUTO_INCREMENT PRIMARY KEY,
    first_name    VARCHAR(100)  NOT NULL,
    last_name     VARCHAR(100)  NOT NULL,
    email         VARCHAR(255)  NOT NULL UNIQUE,   -- DB-level duplicate guard
    password_hash VARCHAR(255)  NOT NULL,
    created_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

The `UNIQUE` constraint on `email` provides a second line of defence against duplicate accounts (the app also checks, but the DB constraint is the safety net).

---

## Verify the Setup

```bash
mysql -u myapp_user -p myapp_db -e "DESCRIBE users;"
```

Expected:
```
+---------------+--------------+------+-----+-------------------+...
| Field         | Type         | Null | Key | Default           |
+---------------+--------------+------+-----+-------------------+
| id            | int(11)      | NO   | PRI | NULL              |
| first_name    | varchar(100) | NO   |     | NULL              |
| last_name     | varchar(100) | NO   |     | NULL              |
| email         | varchar(255) | NO   | UNI | NULL              |
| password_hash | varchar(255) | NO   |     | NULL              |
| created_at    | timestamp    | NO   |     | CURRENT_TIMESTAMP |
+---------------+--------------+------+-----+-------------------+
```

---

## List All Users (Admin Task)

To inspect who exists in the database:

```sql
-- All users and their host scope
SELECT user, host FROM mysql.user;
```

Sample output:
```
+------------------+-----------+
| user             | host      |
+------------------+-----------+
| root             | localhost |
| myapp_user       | localhost |
+------------------+-----------+
```

- `localhost` = local connections only (correct for this project)
- `%` = any host (avoid unless specifically required)
- Specific IP = only from that IP

---

## Useful MariaDB Commands

```bash
# Connect as root
sudo mysql -u root -p

# Connect as app user to specific DB
mysql -u myapp_user -p myapp_db
```

```sql
SHOW DATABASES;                          -- List databases
USE myapp_db;                            -- Switch to database
SHOW TABLES;                             -- List tables
DESCRIBE users;                          -- Show table schema
SELECT user, host FROM mysql.user;       -- List DB users and access scope
SHOW GRANTS FOR 'myapp_user'@'localhost'; -- Show user privileges
```

---

## Next Step

→ [Configure Nginx as a reverse proxy to Node.js](05-nginx-reverse-proxy.md)

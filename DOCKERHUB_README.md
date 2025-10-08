# MySQL Backup with Rclone

Automated MySQL database backup to Google Drive using Rclone. Production-ready Docker container with secure credential handling, health checks, and Docker Swarm support.

## 🚀 Quick Start

### 1. Configure Rclone

```bash
# Create rclone configuration volume
docker volume create rclone_config

# Configure rclone
docker run --rm -it --entrypoint bash -v rclone_config:/root/.config/rclone alian87/mysql-backup-rclone:latest

# Inside the container, run: rclone config
# ⚠️ For Google Drive authentication, you'll need rclone installed locally.
# The container will show a command like:
#   rclone authorize "drive" "eyJzY29wZSI6ImRyaXZlIn0"
# Copy the EXACT command from your terminal (each config has unique code!)
# Run the copied command on your LOCAL machine, then paste the token back.
# Install rclone locally: https://rclone.org/downloads/
```

### 2. Run Backup Container

```bash
docker run -d \
  --name mysql-backup \
  -e MYSQL_HOST=mysql-server \
  -e MYSQL_USER=root \
  -e MYSQL_PASSWORD=your_password \
  -e MYSQL_DATABASES=db1,db2,db3 \
  -e RCLONE_REMOTE=gdrive:backups/mysql \
  -v rclone_config:/root/.config/rclone \
  alian87/mysql-backup-rclone:latest
```

## ✨ Features

- 🔒 **Secure**: Temporary credentials file prevents password exposure
- 🚀 **Automated**: Configurable cron scheduling
- 📊 **Multi-database**: Backup multiple databases in a single run
- ☁️ **Cloud Storage**: Direct upload to Google Drive via Rclone
- 🧹 **Auto-cleanup**: Configurable retention of local backups
- 📝 **Structured Logging**: Multiple log levels with timestamps
- 🔔 **Notifications**: Webhook support for Slack/Discord/Teams
- 🏥 **Health Checks**: Built-in container health monitoring
- 🐳 **Docker Swarm Ready**: Production deployment support

## 📋 Environment Variables

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `MYSQL_HOST` | MySQL server hostname | `localhost` | Yes |
| `MYSQL_PORT` | MySQL server port | `3306` | No |
| `MYSQL_USER` | MySQL username | `root` | Yes |
| `MYSQL_PASSWORD` | MySQL password | - | Yes |
| `MYSQL_DATABASES` | Comma-separated database names | - | Yes |
| `RCLONE_REMOTE` | Rclone remote path | `gdrive:backups` | Yes |
| `CRON_SCHEDULE` | Cron expression for scheduling | `0 3 * * *` | No |
| `BACKUP_RETENTION` | Number of local backups to keep | `5` | No |
| `TZ` | Timezone | `America/Sao_Paulo` | No |
| `LOG_LEVEL` | Logging level | `INFO` | No |
| `WEBHOOK_URL` | Webhook URL for notifications | - | No |

## 🐳 Docker Compose

```yaml
version: '3.8'

services:
  mysql-backup:
    image: alian87/mysql-backup-rclone:latest
    restart: unless-stopped
    environment:
      MYSQL_HOST: "mysql"
      MYSQL_PORT: 3306
      MYSQL_USER: "root"
      MYSQL_PASSWORD: "your_password"
      MYSQL_DATABASES: "db1,db2,db3"
      RCLONE_REMOTE: "gdrive:backups/mysql"
      CRON_SCHEDULE: "0 2 * * *"
      BACKUP_RETENTION: 7
      TZ: "America/Sao_Paulo"
    volumes:
      - rclone_config:/root/.config/rclone
      - backup_data:/backup
    healthcheck:
      test: ["CMD-SHELL", "test -f /var/log/cron.log && pgrep cron > /dev/null"]
      interval: 1m
      timeout: 10s
      retries: 3

volumes:
  rclone_config:
  backup_data:
```

## 🔧 Usage Examples

### Basic Backup
```bash
docker run -d \
  -e MYSQL_HOST=mysql-server \
  -e MYSQL_DATABASES=mydb \
  -e MYSQL_PASSWORD=password \
  -v rclone_config:/root/.config/rclone \
  alian87/mysql-backup-rclone:latest
```

### With Notifications
```bash
docker run -d \
  -e MYSQL_HOST=mysql-server \
  -e MYSQL_DATABASES=mydb \
  -e WEBHOOK_URL=https://hooks.slack.com/services/YOUR/WEBHOOK/URL \
  -v rclone_config:/root/.config/rclone \
  alian87/mysql-backup-rclone:latest
```

### Manual Backup
```bash
docker exec mysql-backup /scripts/backup.sh
```

## 📊 Cron Schedule Examples

```bash
# Daily at 2 AM
CRON_SCHEDULE="0 2 * * *"

# Every 6 hours
CRON_SCHEDULE="0 */6 * * *"

# Weekly on Sunday at 3 AM
CRON_SCHEDULE="0 3 * * 0"

# Monthly on the 1st at midnight
CRON_SCHEDULE="0 0 1 * *"
```

## 🏥 Health Check

The container includes built-in health checks:

```bash
# Check container health
docker ps

# View health check logs
docker inspect mysql-backup | jq '.[0].State.Health'
```

## 🔒 Security Best Practices

1. Use Docker Secrets for passwords in production
2. Create dedicated backup user with minimal privileges
3. Regularly rotate Google Drive API credentials
4. Monitor backup logs for suspicious activity

```sql
-- Create dedicated backup user
CREATE USER 'backup_user'@'%' IDENTIFIED BY 'secure_password';
GRANT SELECT, LOCK TABLES, SHOW VIEW, EVENT, TRIGGER ON *.* TO 'backup_user'@'%';
FLUSH PRIVILEGES;
```

## 📚 Documentation

- **GitHub**: [github.com/alian87/mysql-backup-rclone](https://github.com/alian87/mysql-backup-rclone)
- **Full Documentation**: [README.md](https://github.com/alian87/mysql-backup-rclone/blob/main/README.md)
- **Portuguese Docs**: [README-pt.md](https://github.com/alian87/mysql-backup-rclone/blob/main/README-pt.md)
- **Troubleshooting**: [TROUBLESHOOTING.md](https://github.com/alian87/mysql-backup-rclone/blob/main/docs/TROUBLESHOOTING.md)

## 🐛 Issues & Support

- Report issues: [GitHub Issues](https://github.com/alian87/mysql-backup-rclone/issues)
- Discussions: [GitHub Discussions](https://github.com/alian87/mysql-backup-rclone/discussions)

## 📄 License

MIT License - see [LICENSE](https://github.com/alian87/mysql-backup-rclone/blob/main/LICENSE)

## 🏷️ Tags

- `latest` - Latest stable version
- `1.0.0` - Specific version
- `stable` - Production-ready stable version

---

**⭐ If this project helps you, please give it a star on [GitHub](https://github.com/alian87/mysql-backup-rclone)!**

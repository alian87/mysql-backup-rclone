# 🗄️ MySQL Backup with Rclone

[![Docker](https://img.shields.io/badge/docker-%230db7ed.svg?style=for-the-badge&logo=docker&logoColor=white)](https://www.docker.com/)
[![MySQL](https://img.shields.io/badge/mysql-%2300f.svg?style=for-the-badge&logo=mysql&logoColor=white)](https://www.mysql.com/)
[![Google Drive](https://img.shields.io/badge/Google%20Drive-4285F4?style=for-the-badge&logo=googledrive&logoColor=white)](https://drive.google.com/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge)](https://opensource.org/licenses/MIT)

A robust, production-ready Docker container for automated MySQL database backups to Google Drive using Rclone. Features secure credential handling, comprehensive error handling, health checks, and flexible scheduling.

## ✨ Features

- 🔒 **Secure**: Temporary credentials file prevents password exposure
- 🚀 **Automated**: Configurable cron scheduling for hands-off operation
- 📊 **Multi-database**: Backup multiple databases in a single run
- ☁️ **Cloud Storage**: Direct upload to Google Drive via Rclone
- 🧹 **Auto-cleanup**: Configurable retention of local backups
- 📝 **Structured Logging**: Multiple log levels with timestamps
- 🔔 **Notifications**: Webhook support for Slack/Discord/Teams
- 🏥 **Health Checks**: Built-in container health monitoring
- 🌍 **Timezone Support**: Proper timezone configuration
- 🐳 **Docker Swarm Ready**: Production deployment with Docker Swarm
- 🧪 **Tested**: Comprehensive test suite included

## 🚀 Quick Start

### Prerequisites

- Docker installed
- Google Drive account
- MySQL server accessible from container

### 1. Configure Rclone

```bash
# Create rclone configuration volume
docker volume create rclone_config

# Configure rclone (follow the interactive setup)
docker run --rm -it -v rclone_config:/root/.config/rclone rclone/rclone:latest config
```

### 2. Run with Docker Compose

```bash
# Clone the repository
git clone https://github.com/alian87/mysql-backup-rclone.git
cd mysql-backup-rclone

# Copy and customize the example
cp examples/docker-compose.example.yml docker-compose.yml
# Edit docker-compose.yml with your settings

# Start the backup service
docker-compose up -d
```

### 3. Deploy with Docker Swarm

```bash
# Copy and customize the stack file
cp examples/stack.example.yml stack.yml
# Edit stack.yml with your settings

# Deploy the stack
docker stack deploy -c stack.yml mysql-backup
```

## 📋 Configuration

### Environment Variables

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
| `LOG_LEVEL` | Logging level (DEBUG/INFO/WARN/ERROR) | `INFO` | No |
| `WEBHOOK_URL` | Webhook URL for notifications | - | No |

### Cron Schedule Examples

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

## 🏗️ Architecture

```
┌─────────────┐     ┌──────────────┐     ┌─────────────┐
│   Cron Job  │ --> │  backup.sh   │ --> │ Google Drive│
│ (scheduled) │     │ (mysqldump)  │     │  (rclone)   │
└─────────────┘     └──────────────┘     └─────────────┘
       │                     │                     │
       v                     v                     v
┌─────────────┐     ┌──────────────┐     ┌───────────────┐
│   Logging   │     │   Cleanup    │     │ Notifications │
│ (structured)│     │ (retention)  │     │  (webhook)    │
└─────────────┘     └──────────────┘     └───────────────┘
```

## 📁 Project Structure

```
mysql-backup-rclone/
├── Dockerfile                 # Container definition
├── docker-compose.yml         # Development setup
├── stack.yml                  # Production deployment
├── src/
│   ├── backup.sh             # Main backup script
│   └── entrypoint.sh         # Container initialization
├── examples/
│   ├── docker-compose.example.yml
│   ├── stack.example.yml
│   ├── rclone-setup.md
│   └── mysql-init/
├── tests/
│   ├── test-backup.sh        # Test suite
│   └── README.md
├── docs/
└── README.md
```

## 🔧 Usage Examples

### Basic Usage

```bash
docker run -d \
  --name mysql-backup \
  -e MYSQL_HOST=mysql-server \
  -e MYSQL_USER=backup_user \
  -e MYSQL_PASSWORD=secure_password \
  -e MYSQL_DATABASES=db1,db2,db3 \
  -e RCLONE_REMOTE=gdrive:backups/mysql \
  -v rclone_config:/root/.config/rclone \
  alian87/mysql-backup-rclone:latest
```

### With Notifications

```bash
docker run -d \
  --name mysql-backup \
  -e MYSQL_HOST=mysql-server \
  -e MYSQL_USER=backup_user \
  -e MYSQL_PASSWORD=secure_password \
  -e MYSQL_DATABASES=production_db \
  -e RCLONE_REMOTE=gdrive:backups/mysql \
  -e WEBHOOK_URL=https://hooks.slack.com/services/YOUR/WEBHOOK/URL \
  -e CRON_SCHEDULE="0 2 * * *" \
  -v rclone_config:/root/.config/rclone \
  alian87/mysql-backup-rclone:latest
```

### Manual Backup

```bash
# Execute backup manually
docker exec mysql-backup /scripts/backup.sh

# View logs
docker logs mysql-backup

# Follow logs in real-time
docker logs -f mysql-backup
```

## 🧪 Testing

### Run Test Suite

```bash
# Run comprehensive tests
./tests/test-backup.sh --build --cleanup

# Run tests with verbose output
./tests/test-backup.sh --verbose

# Run tests and keep containers for inspection
./tests/test-backup.sh --build
```

### Manual Testing

```bash
# Build the image
docker build -t mysql-backup-rclone .

# Test with sample MySQL container
docker-compose up -d mysql
sleep 30
docker-compose up backup
```

## 📊 Monitoring

### Health Checks

The container includes built-in health checks:

```bash
# Check container health
docker ps

# View health check logs
docker inspect mysql-backup | jq '.[0].State.Health'
```

### Logging

Structured logging with multiple levels:

```bash
# View all logs
docker logs mysql-backup

# View only error logs
docker logs mysql-backup 2>&1 | grep ERROR

# View backup summaries
docker logs mysql-backup 2>&1 | grep "Backup Summary"
```

### Metrics

The container provides basic metrics through logs:

- Backup success/failure rates
- Database sizes
- Upload times
- Cleanup statistics

## 🔒 Security

### Best Practices

1. **Use Docker Secrets** for sensitive data in production
2. **Restrict network access** to MySQL server
3. **Use dedicated backup user** with minimal privileges
4. **Regularly rotate** Google Drive API credentials
5. **Monitor backup logs** for suspicious activity

### Docker Secrets Example

```yaml
# docker-compose.yml
version: '3.8'
services:
  mysql-backup:
    image: alian87/mysql-backup-rclone:latest
    secrets:
      - mysql_password
    environment:
      MYSQL_PASSWORD_FILE: /run/secrets/mysql_password

secrets:
  mysql_password:
    external: true
```

### Backup User Permissions

```sql
-- Create dedicated backup user
CREATE USER 'backup_user'@'%' IDENTIFIED BY 'secure_password';

-- Grant minimal required permissions
GRANT SELECT, LOCK TABLES, SHOW VIEW, EVENT, TRIGGER ON *.* TO 'backup_user'@'%';
FLUSH PRIVILEGES;
```

## 🚨 Troubleshooting

### Common Issues

#### Container won't start
```bash
# Check logs
docker logs mysql-backup

# Common causes:
# - Missing rclone configuration
# - Invalid environment variables
# - Network connectivity issues
```

#### Backup failures
```bash
# Check MySQL connectivity
docker exec mysql-backup mysql -h mysql-server -u user -p -e "SELECT 1"

# Check rclone configuration
docker exec mysql-backup rclone lsd gdrive:

# Enable debug logging
docker run -e LOG_LEVEL=DEBUG ... mysql-backup-rclone
```

#### Upload failures
```bash
# Test rclone connection
docker exec mysql-backup rclone about gdrive:

# Check Google Drive quota
docker exec mysql-backup rclone about gdrive: | grep Used
```

### Debug Mode

Enable debug logging for detailed troubleshooting:

```bash
docker run -e LOG_LEVEL=DEBUG ... mysql-backup-rclone
```

## 📈 Performance

### Optimization Tips

1. **Use `--single-transaction`** for InnoDB tables (already included)
2. **Adjust `--quick`** for large tables (already included)
3. **Optimize rclone settings** for large uploads
4. **Use SSD storage** for backup directory
5. **Monitor resource usage** during backups

### Resource Requirements

| Component | CPU | RAM | Disk |
|-----------|-----|-----|------|
| Container | 0.25-0.5 cores | 256-512MB | 50MB |
| Backup Local | - | - | 5x database size |
| Google Drive | - | - | Unlimited* |

*Depends on Google Workspace plan

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Development Setup

```bash
# Clone the repository
git clone https://github.com/alian87/mysql-backup-rclone.git
cd mysql-backup-rclone

# Build the image
docker build -t mysql-backup-rclone .

# Run tests
./tests/test-backup.sh --build --cleanup
```

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- [Rclone](https://rclone.org/) for cloud storage synchronization
- [MySQL](https://www.mysql.com/) for the database system
- [Docker](https://www.docker.com/) for containerization
- [Google Drive](https://drive.google.com/) for cloud storage

## 📞 Support

- 📖 [Documentation](docs/)
- 🐛 [Issue Tracker](https://github.com/alian87/mysql-backup-rclone/issues)
- 💬 [Discussions](https://github.com/alian87/mysql-backup-rclone/discussions)
- 📧 [Email](mailto:alian.v.p.87@gmail.com)

---

**⭐ If this project helps you, please give it a star!**

# 🔧 Troubleshooting Guide

This guide helps you diagnose and resolve common issues with the MySQL Backup Rclone container.

## 🚨 Common Issues

### Container Won't Start

#### Symptoms
- Container exits immediately
- No logs or empty logs
- Docker shows "Exited" status

#### Diagnosis
```bash
# Check container logs
docker logs mysql-backup

# Check container status
docker ps -a | grep mysql-backup

# Check Docker events
docker events --since 1h | grep mysql-backup
```

#### Common Causes & Solutions

**1. Missing Rclone Configuration**
```
Error: Rclone configuration not found at /root/.config/rclone/rclone.conf
```
**Solution:**
```bash
# Create and configure rclone volume
docker volume create rclone_config
docker run --rm -it -v rclone_config:/root/.config/rclone rclone/rclone:latest config
```

**2. Invalid Environment Variables**
```
Error: MYSQL_DATABASES is not set
```
**Solution:**
```bash
# Check environment variables
docker exec mysql-backup env | grep MYSQL

# Set required variables
docker run -e MYSQL_DATABASES="db1,db2" ... mysql-backup-rclone
```

**3. Network Connectivity Issues**
```
Error: Cannot connect to MySQL
```
**Solution:**
```bash
# Test MySQL connectivity
docker exec mysql-backup mysql -h mysql-host -u user -p -e "SELECT 1"

# Check network configuration
docker network ls
docker network inspect network_name
```

### Backup Failures

#### Symptoms
- Backup process starts but fails
- Error messages in logs
- No backup files created

#### Diagnosis
```bash
# Check backup logs
docker logs mysql-backup | grep -i error

# Check cron logs
docker exec mysql-backup cat /var/log/cron.log

# Enable debug logging
docker run -e LOG_LEVEL=DEBUG ... mysql-backup-rclone
```

#### Common Causes & Solutions

**1. MySQL Connection Issues**
```
Error: Cannot connect to MySQL
Host: mysql:3306 | User: root
```
**Solution:**
```bash
# Test MySQL connection manually
docker exec mysql-backup mysql -h mysql-host -P 3306 -u root -p'password' -e "SELECT 1"

# Check MySQL server status
docker ps | grep mysql
docker logs mysql-server

# Verify network connectivity
docker exec mysql-backup ping mysql-host
```

**2. Database Not Found**
```
Error: Unknown database 'database_name'
```
**Solution:**
```bash
# List available databases
docker exec mysql-backup mysql -h mysql-host -u user -p -e "SHOW DATABASES"

# Update MYSQL_DATABASES environment variable
docker run -e MYSQL_DATABASES="correct_db1,correct_db2" ... mysql-backup-rclone
```

**3. Permission Denied**
```
Error: Access denied for user 'backup_user'@'%'
```
**Solution:**
```sql
-- Grant necessary permissions
GRANT SELECT, LOCK TABLES, SHOW VIEW, EVENT, TRIGGER ON *.* TO 'backup_user'@'%';
FLUSH PRIVILEGES;
```

### Upload Failures

#### Symptoms
- Backup files created locally but not uploaded
- Rclone errors in logs
- Google Drive shows no new files

#### Diagnosis
```bash
# Test rclone configuration
docker exec mysql-backup rclone lsd gdrive:

# Check rclone about
docker exec mysql-backup rclone about gdrive:

# Test upload manually
docker exec mysql-backup rclone copy /backup/test gdrive:test-backup
```

#### Common Causes & Solutions

**1. Rclone Configuration Issues**
```
Error: Failed to create file system for "gdrive:": didn't find section in config file
```
**Solution:**
```bash
# Reconfigure rclone
docker run --rm -it -v rclone_config:/root/.config/rclone rclone/rclone:latest config

# Test configuration
docker run --rm -v rclone_config:/root/.config/rclone rclone/rclone:latest lsd gdrive:
```

**2. Google Drive API Issues**
```
Error: failed to get drive: googleapi: Error 403: Access Not Configured
```
**Solution:**
- Enable Google Drive API in Google Cloud Console
- Check API quotas and limits
- Verify OAuth2 credentials

**3. Insufficient Storage**
```
Error: googleapi: Error 403: The user's Drive storage quota has been exceeded
```
**Solution:**
```bash
# Check Google Drive usage
docker exec mysql-backup rclone about gdrive:

# Clean up old backups
docker exec mysql-backup rclone delete gdrive:backups/old-backup-folder
```

### Cron Job Issues

#### Symptoms
- Backup container runs but no scheduled backups
- Cron logs are empty
- Manual backup works but scheduled doesn't

#### Diagnosis
```bash
# Check cron status
docker exec mysql-backup pgrep cron

# Check cron configuration
docker exec mysql-backup crontab -l

# Check cron logs
docker exec mysql-backup cat /var/log/cron.log
```

#### Common Causes & Solutions

**1. Cron Not Running**
```
Error: No cron process found
```
**Solution:**
```bash
# Restart container
docker restart mysql-backup

# Check cron service
docker exec mysql-backup service cron status
```

**2. Invalid Cron Schedule**
```
Error: Invalid cron expression
```
**Solution:**
```bash
# Use valid cron expression
# Examples:
# "0 2 * * *" - Daily at 2 AM
# "0 */6 * * *" - Every 6 hours
# "0 0 1 * *" - Monthly on 1st

# Test cron expression
docker run --rm alpine sh -c 'echo "0 2 * * *" | crontab -'
```

**3. Permission Issues**
```
Error: Permission denied
```
**Solution:**
```bash
# Check file permissions
docker exec mysql-backup ls -la /scripts/
docker exec mysql-backup ls -la /var/log/cron.log

# Fix permissions if needed
docker exec mysql-backup chmod +x /scripts/backup.sh
```

## 🔍 Debugging Techniques

### Enable Debug Logging

```bash
# Run with debug logging
docker run -e LOG_LEVEL=DEBUG ... mysql-backup-rclone

# Or update existing container
docker run -e LOG_LEVEL=DEBUG --rm mysql-backup-rclone /scripts/backup.sh
```

### Manual Testing

```bash
# Test MySQL connection
docker exec mysql-backup mysql -h mysql-host -u user -p -e "SELECT 1"

# Test rclone connection
docker exec mysql-backup rclone lsd gdrive:

# Test backup script manually
docker exec mysql-backup /scripts/backup.sh

# Test cron job manually
docker exec mysql-backup bash -c "echo 'test' | crontab -"
```

### Network Diagnostics

```bash
# Check network connectivity
docker exec mysql-backup ping mysql-host
docker exec mysql-backup nslookup mysql-host

# Check port connectivity
docker exec mysql-backup nc -zv mysql-host 3306

# Check DNS resolution
docker exec mysql-backup nslookup google.com
```

### Resource Monitoring

```bash
# Check container resources
docker stats mysql-backup

# Check disk usage
docker exec mysql-backup df -h
docker exec mysql-backup du -sh /backup/*

# Check memory usage
docker exec mysql-backup free -h
```

## 📊 Performance Issues

### Slow Backups

#### Symptoms
- Backup takes too long to complete
- High CPU usage during backup
- Timeout errors

#### Solutions

**1. Optimize MySQL Dump**
```bash
# Already included in backup.sh:
# --single-transaction (for InnoDB)
# --quick (for large tables)
# --routines --triggers --events (for complete backup)
```

**2. Optimize Rclone Upload**
```bash
# Add to rclone command in backup.sh:
rclone copy ... --transfers=4 --checkers=8 --drive-chunk-size=64M
```

**3. Use SSD Storage**
```bash
# Mount SSD volume for backup directory
docker run -v /ssd/backups:/backup ... mysql-backup-rclone
```

### High Memory Usage

#### Symptoms
- Container uses excessive memory
- Out of memory errors
- System slowdown

#### Solutions

**1. Limit Container Resources**
```yaml
# docker-compose.yml
services:
  mysql-backup:
    deploy:
      resources:
        limits:
          memory: 512M
        reservations:
          memory: 256M
```

**2. Optimize Backup Process**
```bash
# Use streaming backup for large databases
mysqldump ... | gzip | rclone rcat gdrive:backup.sql.gz
```

## 🔧 Maintenance

### Regular Maintenance Tasks

```bash
# Check backup status
docker logs mysql-backup | grep "Backup Summary"

# Verify Google Drive uploads
docker exec mysql-backup rclone ls gdrive:backups

# Clean up old local backups
docker exec mysql-backup ls -la /backup/

# Check container health
docker ps | grep mysql-backup
```

### Monitoring Script

```bash
#!/bin/bash
# backup-monitor.sh

CONTAINER_NAME="mysql-backup"
LOG_FILE="/var/log/backup-monitor.log"

# Check if container is running
if ! docker ps | grep -q $CONTAINER_NAME; then
    echo "$(date): Container $CONTAINER_NAME is not running" >> $LOG_FILE
    # Send alert
fi

# Check last backup
LAST_BACKUP=$(docker logs $CONTAINER_NAME 2>&1 | grep "Backup completed" | tail -1)
if [ -z "$LAST_BACKUP" ]; then
    echo "$(date): No recent backup found" >> $LOG_FILE
    # Send alert
fi

# Check disk usage
DISK_USAGE=$(docker exec $CONTAINER_NAME df -h /backup | awk 'NR==2{print $5}' | sed 's/%//')
if [ $DISK_USAGE -gt 80 ]; then
    echo "$(date): High disk usage: ${DISK_USAGE}%" >> $LOG_FILE
    # Send alert
fi
```

## 📞 Getting Help

### Before Asking for Help

1. **Check the logs**: `docker logs mysql-backup`
2. **Enable debug logging**: `LOG_LEVEL=DEBUG`
3. **Test connectivity**: Manual MySQL and rclone tests
4. **Check configuration**: Verify all environment variables
5. **Review this guide**: Look for similar issues

### Information to Provide

When asking for help, include:

- Docker version: `docker --version`
- Container logs: `docker logs mysql-backup`
- Configuration: Environment variables (without passwords)
- Error messages: Exact error text
- Steps to reproduce: What you did before the error

### Support Channels

- 📖 [Documentation](README.md)
- 🐛 [GitHub Issues](https://github.com/yourusername/mysql-backup-rclone/issues)
- 💬 [GitHub Discussions](https://github.com/yourusername/mysql-backup-rclone/discussions)
- 📧 [Email Support](mailto:your.email@example.com)

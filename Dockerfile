# MySQL Backup with Rclone - Docker Image
# Automated MySQL database backup to Google Drive using Rclone
# 
# Build: docker build -t mysql-backup-rclone:latest .
# Run: docker run -d --name mysql-backup mysql-backup-rclone:latest

FROM debian:bookworm-slim

# Metadata
LABEL maintainer="Your Name <your.email@example.com>"
LABEL description="Automated MySQL backup to Google Drive using Rclone"
LABEL version="1.0.0"
LABEL org.opencontainers.image.source="https://github.com/yourusername/mysql-backup-rclone"

# Environment variables with defaults
ENV TZ=America/Sao_Paulo \
    BACKUP_DIR=/backup \
    BACKUP_RETENTION=5 \
    RCLONE_REMOTE=gdrive:backups \
    MYSQL_HOST=localhost \
    MYSQL_PORT=3306 \
    MYSQL_USER=root \
    MYSQL_PASSWORD= \
    MYSQL_DATABASES= \
    CRON_SCHEDULE="0 3 * * *" \
    WEBHOOK_URL= \
    LOG_LEVEL=INFO

# Configure timezone properly
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && \
    echo $TZ > /etc/timezone

# Install dependencies
RUN apt-get update && apt-get install -y \
    cron \
    curl \
    mysql-client \
    unzip \
    ca-certificates \
    jq \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# Install rclone
RUN curl https://rclone.org/install.sh | bash

# Create necessary directories
RUN mkdir -p $BACKUP_DIR /scripts /var/log

# Set working directory
WORKDIR /scripts

# Copy scripts
COPY src/backup.sh /scripts/backup.sh
COPY src/entrypoint.sh /scripts/entrypoint.sh

# Make scripts executable
RUN chmod +x /scripts/backup.sh /scripts/entrypoint.sh

# Create non-root user for security (optional)
RUN useradd -r -s /bin/false -d /scripts backupuser && \
    chown -R backupuser:backupuser /scripts /backup

# Health check
HEALTHCHECK --interval=1m --timeout=10s --start-period=30s --retries=3 \
    CMD test -f /var/log/cron.log && pgrep cron > /dev/null || exit 1

# Expose volume for backups (optional)
VOLUME ["/backup"]

# Entry point
ENTRYPOINT ["/scripts/entrypoint.sh"]

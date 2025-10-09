# MySQL Backup with Rclone - Docker Image
# Automated MySQL database backup to Google Drive using Rclone
# 
# Build: docker build -t mysql-backup-rclone:latest .
# Run: docker run -d --name mysql-backup mysql-backup-rclone:latest

FROM ubuntu:18.04

# Metadata
LABEL maintainer="Alian <alian.v.p.87@gmail.com>"
LABEL description="Automated MySQL backup to Google Drive using Rclone"
LABEL version="2.1.1"
LABEL org.opencontainers.image.source="https://github.com/alian87/mysql-backup-rclone"

# Environment variables with defaults
ENV DEBIAN_FRONTEND=noninteractive \
    TZ=America/Sao_Paulo \
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

# Install dependencies
RUN apt-get update && apt-get install -y \
    cron \
    curl \
    mariadb-client \
    unzip \
    ca-certificates \
    jq \
    dos2unix \
    procps \
    bc \
    tzdata \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# Configure timezone properly (after tzdata is installed)
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && \
    echo $TZ > /etc/timezone && \
    dpkg-reconfigure -f noninteractive tzdata

# Install rclone
RUN curl https://rclone.org/install.sh | bash

# Create necessary directories
RUN mkdir -p $BACKUP_DIR /scripts /var/log

# Set working directory
WORKDIR /scripts

# Copy scripts
COPY src/ /scripts/

# Fix line endings and make scripts executable
RUN dos2unix /scripts/*.sh && \
    chmod +x /scripts/*.sh && \
    ls -la /scripts/ && \
    echo "=== Checking entrypoint.sh ===" && \
    file /scripts/entrypoint.sh && \
    head -1 /scripts/entrypoint.sh && \
    which bash && \
    test -x /scripts/entrypoint.sh && echo "entrypoint.sh is executable" || echo "entrypoint.sh is NOT executable"

# Create non-root user for security (optional)
# Note: Commenting out for now to avoid permission issues
# RUN useradd -r -s /bin/false -d /scripts backupuser && \
#     chown -R backupuser:backupuser /scripts /backup

# Health check
HEALTHCHECK --interval=1m --timeout=10s --start-period=30s --retries=3 \
    CMD test -f /var/log/cron.log && pgrep cron > /dev/null || exit 1

# Expose volume for backups (optional)
VOLUME ["/backup"]

# Entry point
ENTRYPOINT ["/scripts/entrypoint.sh"]

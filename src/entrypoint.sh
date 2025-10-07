#!/bin/bash
# MySQL Backup Container Entrypoint
# Initializes the backup container and starts the cron service
# 
# Author: Your Name
# Version: 1.0.0
# License: MIT

set -euo pipefail

# Logging function
log() {
    local level=$1
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $message"
}

# Validation function
validate_environment() {
    local errors=0
    
    log "INFO" "🔍 Validating environment configuration..."
    
    # Check required variables
    if [ -z "${MYSQL_DATABASES:-}" ]; then
        log "ERROR" "MYSQL_DATABASES is not set"
        errors=$((errors + 1))
    fi
    
    if [ -z "${RCLONE_REMOTE:-}" ]; then
        log "ERROR" "RCLONE_REMOTE is not set"
        errors=$((errors + 1))
    fi
    
    if [ -z "${MYSQL_PASSWORD:-}" ]; then
        log "WARN" "MYSQL_PASSWORD is empty (using empty password)"
    fi
    
    # Check rclone configuration
    if [ ! -f /root/.config/rclone/rclone.conf ]; then
        log "ERROR" "Rclone configuration not found at /root/.config/rclone/rclone.conf"
        log "ERROR" "Please mount the rclone config file or volume"
        errors=$((errors + 1))
    else
        log "INFO" "✅ Rclone configuration found"
    fi
    
    # Check backup directory
    if [ ! -d "$BACKUP_DIR" ]; then
        log "INFO" "Creating backup directory: $BACKUP_DIR"
        mkdir -p "$BACKUP_DIR"
    fi
    
    if [ $errors -gt 0 ]; then
        log "ERROR" "Configuration validation failed with $errors error(s)"
        exit 1
    fi
    
    log "INFO" "✅ Environment validation passed"
}

# Display configuration
show_configuration() {
    log "INFO" ""
    log "INFO" "📋 Configuration:"
    log "INFO" "   MySQL Host: ${MYSQL_HOST:-localhost}:${MYSQL_PORT:-3306}"
    log "INFO" "   MySQL User: ${MYSQL_USER:-root}"
    log "INFO" "   Databases: ${MYSQL_DATABASES:-}"
    log "INFO" "   Remote: ${RCLONE_REMOTE:-}"
    log "INFO" "   Schedule: ${CRON_SCHEDULE:-}"
    log "INFO" "   Timezone: ${TZ:-}"
    log "INFO" "   Retention: ${BACKUP_RETENTION:-5} backups"
    log "INFO" "   Log Level: ${LOG_LEVEL:-INFO}"
    if [ -n "${WEBHOOK_URL:-}" ]; then
        log "INFO" "   Webhook: Configured"
    else
        log "INFO" "   Webhook: Not configured"
    fi
    log "INFO" ""
}

# Setup cron
setup_cron() {
    log "INFO" "⏰ Setting up cron job..."
    
    # Create log file
    touch /var/log/cron.log
    chmod 644 /var/log/cron.log
    
    # Create cron job
    local cron_job="$CRON_SCHEDULE root /scripts/backup.sh >> /var/log/cron.log 2>&1"
    echo "$cron_job" > /etc/cron.d/backup
    chmod 0644 /etc/cron.d/backup
    
    # Install cron job
    crontab /etc/cron.d/backup
    
    log "INFO" "✅ Cron job configured: $CRON_SCHEDULE"
}

# Test connectivity
test_connectivity() {
    log "INFO" "🔗 Testing connectivity..."
    
    # Test MySQL connection
    if [ -n "${MYSQL_HOST:-}" ] && [ -n "${MYSQL_USER:-}" ]; then
        log "INFO" "Testing MySQL connection..."
        if timeout 10 mysql -h "${MYSQL_HOST:-localhost}" \
            -P "${MYSQL_PORT:-3306}" \
            -u "${MYSQL_USER:-root}" \
            -p"${MYSQL_PASSWORD:-}" \
            -e "SELECT 1" > /dev/null 2>&1; then
            log "INFO" "✅ MySQL connection test passed"
        else
            log "WARN" "⚠️ MySQL connection test failed (will retry during backup)"
        fi
    fi
    
    # Test rclone connection
    log "INFO" "Testing rclone connection..."
    if timeout 30 rclone lsd "${RCLONE_REMOTE:-}" > /dev/null 2>&1; then
        log "INFO" "✅ Rclone connection test passed"
    else
        log "WARN" "⚠️ Rclone connection test failed (will retry during backup)"
    fi
}

# Main initialization
main() {
    log "INFO" "════════════════════════════════════════════"
    log "INFO" "🐳 Initializing MySQL Backup Container"
    log "INFO" "════════════════════════════════════════════"
    
    # Validate environment
    validate_environment
    
    # Show configuration
    show_configuration
    
    # Test connectivity
    test_connectivity
    
    # Setup cron
    setup_cron
    
    log "INFO" "════════════════════════════════════════════"
    log "INFO" "🚀 Container ready!"
    log "INFO" "════════════════════════════════════════════"
    
    # Show next scheduled backup
    local next_run=$(crontab -l | head -n1 | awk '{print $1, $2, $3, $4, $5}')
    log "INFO" "⏰ Next backup scheduled: $next_run"
    log "INFO" ""
    
    # Start cron daemon
    log "INFO" "Starting cron daemon..."
    cron
    
    # Follow logs
    log "INFO" "Following logs (Ctrl+C to stop)..."
    tail -f /var/log/cron.log
}

# Handle signals
trap 'log "INFO" "Received shutdown signal, stopping..."; exit 0' TERM INT

# Run main function
main "$@"

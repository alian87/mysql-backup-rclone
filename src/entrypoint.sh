#!/bin/bash
# MySQL Backup Container Entrypoint
# Initializes the backup container and starts the cron service
# 
# Author: Alian
# Version: 2.1.0
# License: MIT

set -euo pipefail

# Logging function
log() {
    local level=$1
    shift
    local message="$*"
    local timestamp=$(TZ="${TZ:-UTC}" date '+%Y-%m-%d %H:%M:%S')
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
    
    # Export environment variables to a file that will be sourced by the cron job
    cat > /etc/environment_backup << EOF
export MYSQL_HOST="${MYSQL_HOST:-localhost}"
export MYSQL_PORT="${MYSQL_PORT:-3306}"
export MYSQL_USER="${MYSQL_USER:-root}"
export MYSQL_PASSWORD="${MYSQL_PASSWORD:-}"
export MYSQL_DATABASES="${MYSQL_DATABASES:-}"
export RCLONE_REMOTE="${RCLONE_REMOTE:-}"
export BACKUP_DIR="${BACKUP_DIR:-/backup}"
export BACKUP_RETENTION="${BACKUP_RETENTION:-5}"
export TZ="${TZ:-UTC}"
export LOG_LEVEL="${LOG_LEVEL:-INFO}"
export WEBHOOK_URL="${WEBHOOK_URL:-}"
export PATH="/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin"
EOF
    
    chmod 644 /etc/environment_backup
    
    # Create wrapper script that sources environment and runs backup
    cat > /scripts/backup_wrapper.sh << 'EOF'
#!/bin/bash
# Source environment variables
source /etc/environment_backup
# Run backup script
/scripts/backup.sh >> /var/log/cron.log 2>&1
EOF
    
    chmod +x /scripts/backup_wrapper.sh
    
    # Install crontab for root user (more reliable in containers than /etc/cron.d/)
    echo "${CRON_SCHEDULE} /scripts/backup_wrapper.sh" | crontab -
    
    # Verify crontab was installed
    log "DEBUG" "Crontab contents:"
    crontab -l | while read line; do log "DEBUG" "  $line"; done
    
    log "INFO" "✅ Cron job configured: $CRON_SCHEDULE"
}

# Test connectivity
test_connectivity() {
    # Skip if SKIP_CONNECTIVITY_TEST is set
    if [ "${SKIP_CONNECTIVITY_TEST:-false}" = "true" ]; then
        log "INFO" "⏭️ Skipping connectivity tests (SKIP_CONNECTIVITY_TEST=true)"
        return 0
    fi
    
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
    
    # Keep container alive by monitoring cron process
    log "INFO" "Container is running. Monitoring cron daemon..."
    log "INFO" "Use 'docker service logs -f <service-name>' to see backup logs"
    log "INFO" ""
    
    # Keep container alive - check cron every minute
    while true; do
        if ! pgrep -x cron > /dev/null 2>&1; then
            log "WARN" "Cron daemon not running! Starting..."
            cron
        fi
        sleep 60
    done
}

# Handle signals
trap 'log "INFO" "Received shutdown signal, stopping..."; exit 0' TERM INT

# Run main function
main "$@"

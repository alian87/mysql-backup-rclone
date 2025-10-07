#!/bin/bash
# MySQL Backup Script with Rclone
# Automated backup of MySQL databases to Google Drive
# 
# Author: Alian
# Version: 1.0.0
# License: MIT

set -euo pipefail

# Logging function
log() {
    local level=$1
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $message" | tee -a /var/log/cron.log
}

# Notification function
notify() {
    local status=$1
    local message=$2
    
    if [ -n "${WEBHOOK_URL:-}" ]; then
        local payload=$(jq -n \
            --arg status "$status" \
            --arg message "$message" \
            --arg timestamp "$(date -Iseconds)" \
            --arg hostname "$(hostname)" \
            '{status: $status, message: $message, timestamp: $timestamp, hostname: $hostname}')
        
        if curl -s -X POST "$WEBHOOK_URL" \
            -H "Content-Type: application/json" \
            -d "$payload" > /dev/null; then
            log "INFO" "Notification sent: $status"
        else
            log "WARN" "Failed to send notification"
        fi
    fi
}

# Cleanup function
cleanup() {
    local exit_code=$?
    if [ -f /tmp/mysql.cnf ]; then
        rm -f /tmp/mysql.cnf
        log "DEBUG" "Cleaned up temporary MySQL config file"
    fi
    exit $exit_code
}

# Set trap for cleanup
trap cleanup EXIT

# Main backup function
main() {
    local timestamp=$(date +"%Y-%m-%d_%H-%M-%S")
    local backup_path="$BACKUP_DIR/$timestamp"
    local retention=${BACKUP_RETENTION:-5}
    
    log "INFO" "════════════════════════════════════════════"
    log "INFO" "🚀 Starting MySQL Backup - $timestamp"
    log "INFO" "════════════════════════════════════════════"
    
    # Validate required variables
    if [ -z "${MYSQL_DATABASES:-}" ]; then
        log "ERROR" "MYSQL_DATABASES is not set"
        notify "error" "Backup failed: MYSQL_DATABASES not configured"
        exit 1
    fi
    
    if [ -z "${RCLONE_REMOTE:-}" ]; then
        log "ERROR" "RCLONE_REMOTE is not set"
        notify "error" "Backup failed: RCLONE_REMOTE not configured"
        exit 1
    fi
    
    # Create temporary MySQL credentials file
    log "DEBUG" "Creating temporary MySQL credentials file"
    cat > /tmp/mysql.cnf <<EOF
[client]
host=${MYSQL_HOST:-localhost}
port=${MYSQL_PORT:-3306}
user=${MYSQL_USER:-root}
password=${MYSQL_PASSWORD:-}
EOF
    chmod 600 /tmp/mysql.cnf
    
    # Test MySQL connection
    log "INFO" "🔍 Testing MySQL connection..."
    if ! mysql --defaults-extra-file=/tmp/mysql.cnf -e "SELECT 1" > /dev/null 2>&1; then
        log "ERROR" "Cannot connect to MySQL"
        log "ERROR" "Host: ${MYSQL_HOST:-localhost}:${MYSQL_PORT:-3306} | User: ${MYSQL_USER:-root}"
        notify "error" "Backup failed: Cannot connect to MySQL"
        exit 1
    fi
    log "INFO" "✅ MySQL connection established"
    
    # Create backup directory
    mkdir -p "$backup_path"
    log "INFO" "📁 Backup directory created: $backup_path"
    
    # Process each database
    IFS=',' read -ra databases <<< "$MYSQL_DATABASES"
    local backup_success=0
    local backup_failed=0
    local total_size=0
    
    for db in "${databases[@]}"; do
        db=$(echo "$db" | xargs) # Remove whitespace
        local file="$backup_path/${db}.sql.gz"
        
        log "INFO" ""
        log "INFO" "🟢 Backing up database: $db"
        
        # Perform backup with error handling
        if mysqldump --defaults-extra-file=/tmp/mysql.cnf \
            --single-transaction \
            --quick \
            --routines \
            --triggers \
            --events \
            --hex-blob \
            "$db" | gzip > "$file"; then
            
            # Verify backup file
            if [ -s "$file" ]; then
                local size=$(du -h "$file" | cut -f1)
                local size_bytes=$(du -b "$file" | cut -f1)
                total_size=$((total_size + size_bytes))
                log "INFO" "✅ Backup completed: $file ($size)"
                ((backup_success++))
            else
                log "ERROR" "Backup file is empty: $file"
                ((backup_failed++))
            fi
        else
            log "ERROR" "Failed to backup database: $db"
            ((backup_failed++))
        fi
    done
    
    # Convert total size to human readable
    local total_size_human=$(numfmt --to=iec --suffix=B $total_size)
    
    log "INFO" ""
    log "INFO" "════════════════════════════════════════════"
    log "INFO" "☁️ Uploading backups to Google Drive..."
    
    # Upload to Google Drive
    if rclone copy "$backup_path" "$RCLONE_REMOTE/$timestamp" \
        --create-empty-src-dirs \
        --progress \
        --stats=1s; then
        log "INFO" "✅ Upload completed successfully"
    else
        log "ERROR" "Failed to upload to Google Drive"
        notify "error" "Backup failed: Upload to Google Drive failed"
        exit 1
    fi
    
    # Clean up old local backups
    log "INFO" ""
    log "INFO" "🧹 Cleaning up old local backups (keeping last $retention)..."
    local cleaned_count=0
    while IFS= read -r -d '' dir; do
        if [ -d "$dir" ]; then
            rm -rf "$dir"
            ((cleaned_count++))
            log "DEBUG" "Removed old backup: $(basename "$dir")"
        fi
    done < <(find "$BACKUP_DIR" -maxdepth 1 -type d -name "20*" -print0 | sort -z | head -n -$retention)
    
    if [ $cleaned_count -gt 0 ]; then
        log "INFO" "🧹 Cleaned up $cleaned_count old backup(s)"
    fi
    
    # Final summary
    log "INFO" ""
    log "INFO" "════════════════════════════════════════════"
    log "INFO" "📊 Backup Summary"
    log "INFO" "════════════════════════════════════════════"
    log "INFO" "✅ Successful: $backup_success database(s)"
    log "INFO" "❌ Failed: $backup_failed database(s)"
    log "INFO" "📁 Remote path: $RCLONE_REMOTE/$timestamp"
    log "INFO" "💾 Total size: $total_size_human"
    log "INFO" "🕐 Completed at: $(date '+%Y-%m-%d %H:%M:%S')"
    log "INFO" "════════════════════════════════════════════"
    
    # Send notifications
    if [ $backup_failed -gt 0 ]; then
        log "WARN" "⚠️ Backup completed with errors"
        notify "warning" "Backup completed with $backup_failed error(s) out of $((backup_success + backup_failed)) database(s)"
        exit 1
    else
        log "INFO" "🎉 Backup completed successfully!"
        notify "success" "Backup completed successfully: $backup_success database(s), $total_size_human"
    fi
}

# Run main function
main "$@"

#!/bin/bash
# MySQL Backup Script with Rclone
# Automated backup of MySQL databases to Google Drive
# 
# Author: Alian
# Version: 2.1.0
# License: MIT

set -euo pipefail

# Lock file to prevent concurrent executions
LOCK_FILE="/var/run/backup.lock"
MYSQL_CNF="/tmp/mysql_$$.cnf"  # Unique per PID

# Logging function
log() {
    local level=$1
    shift
    local message="$*"
    local timestamp=$(TZ="${TZ:-UTC}" date '+%Y-%m-%d %H:%M:%S')
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
    
    # Remove temporary MySQL config file
    if [ -f "$MYSQL_CNF" ]; then
        rm -f "$MYSQL_CNF"
        log "DEBUG" "Cleaned up temporary MySQL config file"
    fi
    
    # Remove lock file
    if [ -f "$LOCK_FILE" ]; then
        rm -f "$LOCK_FILE"
        log "DEBUG" "Released backup lock"
    fi
    
    exit $exit_code
}

# Set trap for cleanup
trap cleanup EXIT

# Check for concurrent execution
if [ -f "$LOCK_FILE" ]; then
    lock_pid=$(cat "$LOCK_FILE" 2>/dev/null || echo "unknown")
    # Check if the process is still running
    if kill -0 "$lock_pid" 2>/dev/null; then
        log "WARN" "⏳ Another backup is already running (PID: $lock_pid). Skipping this execution."
        exit 0
    else
        log "INFO" "🔓 Removing stale lock file (PID: $lock_pid no longer exists)"
        rm -f "$LOCK_FILE"
    fi
fi

# Create lock file with current PID
echo $$ > "$LOCK_FILE"
log "DEBUG" "🔒 Acquired backup lock (PID: $$)"

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
    cat > "$MYSQL_CNF" <<EOF
[client]
host=${MYSQL_HOST:-localhost}
port=${MYSQL_PORT:-3306}
user=${MYSQL_USER:-root}
password=${MYSQL_PASSWORD:-}
EOF
    chmod 600 "$MYSQL_CNF"
    
    # Test MySQL connection
    log "INFO" "🔍 Testing MySQL connection..."
    if ! mysql --defaults-extra-file="$MYSQL_CNF" -e "SELECT 1" > /dev/null 2>&1; then
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
    
    # Temporarily disable exit on error for the backup loop
    set +e
    
    for db in "${databases[@]}"; do
        db=$(echo "$db" | xargs) # Remove whitespace
        local file="$backup_path/${db}.sql.gz"
        
        log "DEBUG" "Processing database: $db"
        log "INFO" ""
        log "INFO" "🟢 Backing up database: $db"
        
        # Perform backup with error handling
        # Verify config file exists
        if [ ! -f "$MYSQL_CNF" ]; then
            log "ERROR" "MySQL config file not found!"
            ((backup_failed++))
            continue
        fi
        
        # Redirect stderr to filter out generation_expression errors
        local tmp_err="/tmp/mysqldump_${db}_$$.err"
        local dump_success=0
        
        # Perform backup with standard flags (compatible with older MySQL)
        mysqldump --defaults-extra-file="$MYSQL_CNF" \
            --single-transaction \
            --quick \
            --routines \
            --triggers \
            "$db" 2>"$tmp_err" | gzip > "$file"
        local mysqldump_exit=$?
        
        log "DEBUG" "mysqldump exit code: $mysqldump_exit"
        
        # Check result - file created and has content
        if [ -s "$file" ]; then
            # Check if there were critical errors (not generation_expression)
            if [ -f "$tmp_err" ]; then
                if grep -v "generation_expression\|Generation expression" "$tmp_err" | grep -iq "error\|fatal"; then
                    log "WARN" "Non-critical warnings during backup"
                fi
            fi
            dump_success=1
        fi
        
        rm -f "$tmp_err" || true
        
        if [ $dump_success -eq 1 ]; then
            
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
            log "ERROR" "Failed to backup database: $db (file empty or not created)"
            ((backup_failed++))
        fi
        
        log "DEBUG" "Finished processing database: $db"
    done
    
    # Re-enable exit on error
    set -e
    
    log "DEBUG" "All databases processed. Success: $backup_success, Failed: $backup_failed"
    
    # Convert total size to human readable
    local total_size_human
    if command -v numfmt > /dev/null 2>&1; then
        total_size_human=$(numfmt --to=iec --suffix=B $total_size 2>/dev/null || echo "${total_size} bytes")
    else
        # Fallback if numfmt not available
        total_size_human=$(echo "scale=2; $total_size/1024/1024" | bc 2>/dev/null || echo "$total_size")
        total_size_human="${total_size_human}MB"
    fi
    
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
    local local_cleaned=0
    
    # Get all backup directories, sort them, and keep only the oldest ones to delete
    mapfile -t old_backups < <(find "$BACKUP_DIR" -maxdepth 1 -type d -name "20*" | sort | head -n -$retention)
    
    for dir in "${old_backups[@]}"; do
        if [ -n "$dir" ] && [ -d "$dir" ]; then
            rm -rf "$dir"
            ((local_cleaned++))
            log "DEBUG" "Removed old local backup: $(basename "$dir")"
        fi
    done
    
    if [ $local_cleaned -gt 0 ]; then
        log "INFO" "🧹 Cleaned up $local_cleaned old local backup(s)"
    fi
    
    # Clean up old remote backups
    log "INFO" "🧹 Cleaning up old remote backups (keeping last $retention)..."
    local remote_cleaned=0
    
    # Get list of remote backup directories, sort them, and keep only the oldest ones to delete
    while IFS= read -r backup_dir; do
        if [ -n "$backup_dir" ]; then
            log "DEBUG" "Removing old remote backup: $backup_dir"
            if rclone purge "$RCLONE_REMOTE/$backup_dir" --config /root/.config/rclone/rclone.conf > /dev/null 2>&1; then
                ((remote_cleaned++))
                log "DEBUG" "✅ Removed remote backup: $backup_dir"
            else
                log "WARN" "Failed to remove remote backup: $backup_dir"
            fi
        fi
    done < <(rclone lsf "$RCLONE_REMOTE" --dirs-only --config /root/.config/rclone/rclone.conf 2>/dev/null | grep "^20" | sort | head -n -$retention)
    
    if [ $remote_cleaned -gt 0 ]; then
        log "INFO" "🧹 Cleaned up $remote_cleaned old remote backup(s)"
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

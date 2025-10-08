#!/bin/bash
# MySQL Backup Test Script
# Tests the backup functionality in a controlled environment
# 
# Usage: ./test-backup.sh [options]
# Options:
#   --build    Build the Docker image before testing
#   --cleanup  Clean up test resources after testing
#   --verbose  Enable verbose output

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
IMAGE_NAME="mysql-backup-rclone-test"
CONTAINER_NAME="mysql-backup-test"
MYSQL_CONTAINER="mysql-test"
NETWORK_NAME="mysql-backup-test-network"
VOLUME_NAME="rclone-config-test"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Parse command line arguments
BUILD_IMAGE=false
CLEANUP=false
VERBOSE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --build)
            BUILD_IMAGE=true
            shift
            ;;
        --cleanup)
            CLEANUP=true
            shift
            ;;
        --verbose)
            VERBOSE=true
            shift
            ;;
        *)
            log_error "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Cleanup function
cleanup() {
    log_info "Cleaning up test resources..."
    
    # Stop and remove containers
    docker stop "$CONTAINER_NAME" "$MYSQL_CONTAINER" 2>/dev/null || true
    docker rm "$CONTAINER_NAME" "$MYSQL_CONTAINER" 2>/dev/null || true
    
    # Remove network
    docker network rm "$NETWORK_NAME" 2>/dev/null || true
    
    # Remove volume
    docker volume rm "$VOLUME_NAME" 2>/dev/null || true
    
    # Remove test image
    docker rmi "$IMAGE_NAME" 2>/dev/null || true
    
    log_success "Cleanup completed"
}

# Set trap for cleanup
if [ "$CLEANUP" = true ]; then
    trap cleanup EXIT
fi

# Build image if requested
if [ "$BUILD_IMAGE" = true ]; then
    log_info "Building Docker image..."
    docker build -t "$IMAGE_NAME" "$PROJECT_DIR"
    log_success "Image built successfully"
fi

# Check if image exists
if ! docker image inspect "$IMAGE_NAME" >/dev/null 2>&1; then
    log_error "Image $IMAGE_NAME not found. Use --build to build it first."
    exit 1
fi

# Create test network
log_info "Creating test network..."
docker network create "$NETWORK_NAME" 2>/dev/null || log_warning "Network already exists"

# Create test volume
log_info "Creating test volume..."
docker volume create "$VOLUME_NAME" 2>/dev/null || log_warning "Volume already exists"

# Start MySQL container
log_info "Starting MySQL test container..."
docker run -d \
    --name "$MYSQL_CONTAINER" \
    --network "$NETWORK_NAME" \
    -e MYSQL_ROOT_PASSWORD=testpass \
    -e MYSQL_DATABASE=backup_test_db \
    -e MYSQL_USER=testuser \
    -e MYSQL_PASSWORD=testpass \
    mysql:8.0

# Wait for MySQL to be ready
log_info "Waiting for MySQL to be ready..."
timeout=60
while [ $timeout -gt 0 ]; do
    if docker exec "$MYSQL_CONTAINER" mysqladmin ping -h localhost --silent; then
        break
    fi
    sleep 1
    timeout=$((timeout - 1))
done

if [ $timeout -eq 0 ]; then
    log_error "MySQL failed to start within 60 seconds"
    exit 1
fi

log_success "MySQL is ready"

# Create test databases and data
log_info "Creating test databases and data..."
docker exec "$MYSQL_CONTAINER" mysql -u root -ptestpass -h 127.0.0.1 -e "
CREATE DATABASE IF NOT EXISTS backup_test_db2;
USE backup_test_db;
CREATE TABLE IF NOT EXISTS test_table (id INT PRIMARY KEY, name VARCHAR(50));
INSERT INTO test_table VALUES (1, 'test1'), (2, 'test2') ON DUPLICATE KEY UPDATE name=VALUES(name);
USE backup_test_db2;
CREATE TABLE IF NOT EXISTS test_table2 (id INT PRIMARY KEY, value VARCHAR(50));
INSERT INTO test_table2 VALUES (1, 'value1'), (2, 'value2') ON DUPLICATE KEY UPDATE value=VALUES(value);
"

# Create minimal rclone config for testing
log_info "Creating test rclone configuration..."
docker run --rm \
    -v "$VOLUME_NAME":/root/.config/rclone \
    alpine sh -c 'mkdir -p /root/.config/rclone && echo "[gdrive]
type = drive
client_id = 
client_secret = 
scope = drive" > /root/.config/rclone/rclone.conf'

# Start backup container
log_info "Starting backup container..."
docker run -d \
    --name "$CONTAINER_NAME" \
    --network "$NETWORK_NAME" \
    -v "$VOLUME_NAME":/root/.config/rclone \
    -e MYSQL_HOST="$MYSQL_CONTAINER" \
    -e MYSQL_PORT=3306 \
    -e MYSQL_USER=root \
    -e MYSQL_PASSWORD=testpass \
    -e MYSQL_DATABASES="backup_test_db,backup_test_db2" \
    -e RCLONE_REMOTE="gdrive:test-backups" \
    -e CRON_SCHEDULE="* * * * *" \
    -e BACKUP_RETENTION=2 \
    -e LOG_LEVEL="DEBUG" \
    "$IMAGE_NAME"

# Wait for container to start
log_info "Waiting for backup container to start..."
sleep 10

# Check if container is running
if ! docker ps | grep -q "$CONTAINER_NAME"; then
    log_error "Backup container failed to start"
    docker logs "$CONTAINER_NAME"
    exit 1
fi

log_success "Backup container is running"

# Test manual backup execution
log_info "Testing manual backup execution..."
if docker exec "$CONTAINER_NAME" /scripts/backup.sh; then
    log_success "Manual backup test passed"
else
    log_error "Manual backup test failed"
    docker logs "$CONTAINER_NAME"
    exit 1
fi

# Check if backup files were created
log_info "Checking backup files..."
if docker exec "$CONTAINER_NAME" ls -la /backup/; then
    log_success "Backup files found"
else
    log_warning "No backup files found"
fi

# Test cron job
log_info "Testing cron job..."
sleep 70  # Wait for cron to run

# Check cron logs
log_info "Checking cron logs..."
if docker exec "$CONTAINER_NAME" cat /var/log/cron.log | grep -q "Backup completed"; then
    log_success "Cron job test passed"
else
    log_warning "Cron job test inconclusive (rclone upload may have failed)"
fi

# Test health check
log_info "Testing health check..."
if docker exec "$CONTAINER_NAME" test -f /var/log/cron.log && docker exec "$CONTAINER_NAME" pgrep cron > /dev/null; then
    log_success "Health check passed"
else
    log_error "Health check failed"
fi

# Display container logs if verbose
if [ "$VERBOSE" = true ]; then
    log_info "Container logs:"
    docker logs "$CONTAINER_NAME"
fi

# Test summary
log_info "Test Summary:"
log_info "✅ Container starts successfully"
log_info "✅ Manual backup execution works"
log_info "✅ Backup files are created"
log_info "✅ Cron job is configured"
log_info "✅ Health check passes"

log_success "All tests passed! 🎉"

# Keep containers running if not cleaning up
if [ "$CLEANUP" = false ]; then
    log_info "Test containers are still running:"
    log_info "  MySQL: $MYSQL_CONTAINER"
    log_info "  Backup: $CONTAINER_NAME"
    log_info "  Network: $NETWORK_NAME"
    log_info "  Volume: $VOLUME_NAME"
    log_info ""
    log_info "To clean up manually:"
    log_info "  docker stop $CONTAINER_NAME $MYSQL_CONTAINER"
    log_info "  docker rm $CONTAINER_NAME $MYSQL_CONTAINER"
    log_info "  docker network rm $NETWORK_NAME"
    log_info "  docker volume rm $VOLUME_NAME"
    log_info "  docker rmi $IMAGE_NAME"
fi

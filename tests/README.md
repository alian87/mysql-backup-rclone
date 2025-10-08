# Test Suite

This directory contains tests for the MySQL Backup Rclone project.

## Test Scripts

### test-backup.sh

Comprehensive test script that validates the backup functionality in a controlled environment.

#### Usage

```bash
# Run tests with image build
./test-backup.sh --build --cleanup

# Run tests with verbose output
./test-backup.sh --verbose

# Run tests and keep containers for inspection
./test-backup.sh --build
```

#### Options

- `--build`: Build the Docker image before testing
- `--cleanup`: Clean up test resources after testing
- `--verbose`: Enable verbose output

#### What it tests

1. **Container startup**: Verifies the container starts successfully
2. **MySQL connectivity**: Tests connection to MySQL server
3. **Manual backup**: Executes backup script manually
4. **Backup file creation**: Verifies backup files are created
5. **Cron job**: Tests scheduled backup execution
6. **Health check**: Validates health check functionality
7. **Logging**: Checks log file creation and content

#### Prerequisites

- Docker installed and running
- Internet connection (for pulling base images)
- Sufficient disk space for test containers

#### Test Environment

The test script creates:
- A test MySQL container with sample data
- A test backup container
- A test Docker network
- A test Docker volume for rclone config

#### Sample Output

```
[INFO] Building Docker image...
[SUCCESS] Image built successfully
[INFO] Creating test network...
[INFO] Creating test volume...
[INFO] Starting MySQL test container...
[INFO] Waiting for MySQL to be ready...
[SUCCESS] MySQL is ready
[INFO] Creating test databases and data...
[INFO] Creating test rclone configuration...
[INFO] Starting backup container...
[INFO] Waiting for backup container to start...
[SUCCESS] Backup container is running
[INFO] Testing manual backup execution...
[SUCCESS] Manual backup test passed
[INFO] Checking backup files...
[SUCCESS] Backup files found
[INFO] Testing cron job...
[INFO] Checking cron logs...
[SUCCESS] Cron job test passed
[INFO] Testing health check...
[SUCCESS] Health check passed
[SUCCESS] All tests passed! 🎉
```

## Manual Testing

### Quick Test

```bash
# Build the image
docker build -t mysql-backup-rclone .

# Run a quick test
docker run --rm \
  -e MYSQL_HOST=your-mysql-host \
  -e MYSQL_USER=your-user \
  -e MYSQL_PASSWORD=your-password \
  -e MYSQL_DATABASES=backup_test_db \
  -e RCLONE_REMOTE=gdrive:test \
  -v rclone_config:/root/.config/rclone \
  mysql-backup-rclone /scripts/backup.sh
```

### Integration Test

```bash
# Start MySQL container
docker run -d --name mysql-test \
  -e MYSQL_ROOT_PASSWORD=testpass \
  -e MYSQL_DATABASE=backup_test_db \
  mysql:8.0

# Wait for MySQL to start
sleep 30

# Run backup container
docker run --rm --link mysql-test:mysql \
  -e MYSQL_HOST=mysql \
  -e MYSQL_USER=root \
  -e MYSQL_PASSWORD=testpass \
  -e MYSQL_DATABASES=backup_test_db \
  -e RCLONE_REMOTE=gdrive:test \
  -v rclone_config:/root/.config/rclone \
  mysql-backup-rclone /scripts/backup.sh

# Cleanup
docker stop mysql-test
docker rm mysql-test
```

## Troubleshooting

### Common Issues

1. **MySQL connection failed**: Check MySQL container is running and accessible
2. **Rclone config not found**: Ensure rclone volume is properly mounted
3. **Permission denied**: Check file permissions on scripts
4. **Network issues**: Verify Docker network connectivity

### Debug Mode

Enable debug logging by setting `LOG_LEVEL=DEBUG`:

```bash
docker run -e LOG_LEVEL=DEBUG ... mysql-backup-rclone
```

### View Logs

```bash
# View container logs
docker logs container-name

# Follow logs in real-time
docker logs -f container-name

# View cron logs inside container
docker exec container-name cat /var/log/cron.log
```

## Continuous Integration

For CI/CD pipelines, use the test script with cleanup:

```bash
./test-backup.sh --build --cleanup --verbose
```

This ensures a clean test environment and proper cleanup after tests.

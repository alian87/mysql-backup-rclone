# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [2.1.3] - 2025-10-09

### Fixed
- **CRITICAL**: Removed `local` keyword from cleanup variables causing script hang
- **CRITICAL**: Fixed `((variable++))` syntax causing script to hang
- Script now completes all cleanup phases without hanging
- Fixed conflict between `local` keyword and function scope in cleanup section
- Webhooks now working correctly after all fixes

### Technical Details
- Removed `local` from `local_cleaned` and `remote_cleaned` variables
- Changed `((local_cleaned++))` to `local_cleaned=$((local_cleaned + 1))`
- Changed `((remote_cleaned++))` to `remote_cleaned=$((remote_cleaned + 1))`
- The `(())` syntax was causing the script to hang in the Docker container's Bash version
- Script now executes cleanly through all phases and sends webhook notifications

## [2.1.2] - 2025-10-09

### Fixed
- **CRITICAL**: Fixed script execution completing successfully with webhooks working
- Disabled `set -euo pipefail` which was causing premature script termination
- Removed `trap cleanup EXIT` in favor of manual cleanup calls
- Added `old_backups=()` declaration before `mapfile` to prevent unbound variable errors
- Added manual `cleanup()` calls before all exit points

### Changed
- Script now completes all phases: backup → upload → local cleanup → remote cleanup → summary → notifications
- More robust error handling without premature exits
- Webhooks now properly delivered on both success and failure

## [2.1.1] - 2025-10-09

### Fixed
- **CRITICAL**: Fixed webhook notifications not being sent
- **CRITICAL**: Fixed script terminating prematurely before completing backup summary
- Removed `exit` call from `cleanup()` function that was causing early termination
- Backup now properly completes all steps: local cleanup, remote cleanup, summary, and notifications

### Changed
- Cleanup function no longer forces script exit, allowing natural termination
- Script now completes all phases including notification delivery

## [2.1.0] - 2025-10-09

### Fixed
- **Critical**: Fixed local backup cleanup not working (command failure with `head -z`)
- Replaced broken `find | sort -z | head -n -N` pipeline with `mapfile` array approach
- Local backups are now properly cleaned up according to `BACKUP_RETENTION` setting

### Changed
- Improved local backup cleanup logic for better reliability
- More robust handling of backup directory cleanup

## [2.0.9] - 2025-10-08

### Fixed
- **Critical**: Fixed cron job not executing automatically in containers
- Changed from `/etc/cron.d/` to `crontab` for better container compatibility
- Added wrapper script to properly load environment variables in cron context
- Added debug logging to show installed crontab contents

### Changed
- Improved cron reliability in Docker containers
- Better environment variable handling for scheduled tasks

## [2.0.8] - 2025-10-08

### Added
- **Automatic cleanup of remote backups** on Google Drive
- Now removes old backups from remote storage (not just local)
- Respects `BACKUP_RETENTION` setting for both local and remote cleanup

### Changed
- Full rebuild without cache to ensure clean build
- Separated local and remote backup cleanup in logs

## [2.0.7] - 2025-10-08

### Fixed
- **Timezone display in logs** now correctly shows local time instead of UTC
- Log timestamps now respect `TZ` environment variable

### Changed
- Modified `log()` function to explicitly use configured timezone

## [2.0.6] - 2025-10-08

### Fixed
- **Timezone configuration** now works correctly
- Added `tzdata` package and proper timezone setup
- Added `dpkg-reconfigure` for timezone configuration

### Changed
- Moved timezone configuration to after package installation
- Added `DEBIAN_FRONTEND=noninteractive` to prevent prompts

## [2.0.5] - 2025-10-08

### Fixed
- Race condition when multiple backup jobs run simultaneously
- MySQL config file conflicts between concurrent executions

### Added
- **Lock file mechanism** (`/var/run/backup.lock`) to prevent concurrent backups
- Unique temporary MySQL config files per process (`/tmp/mysql_$$.cnf`)
- Stale lock detection and cleanup
- Lock acquisition and release logging

### Security
- Improved concurrent execution safety
- Better cleanup of temporary files

## [2.0.0] - 2025-10-08

### Changed
- **BREAKING**: Changed base image from `debian:bookworm-slim` to `ubuntu:18.04`
- This change provides better compatibility with older MySQL servers (5.5+)
- MariaDB client version downgraded to 10.1 for compatibility

### Fixed
- Fixed `generation_expression` errors with older MySQL 5.5 servers
- Improved mysqldump compatibility across different MySQL versions
- Better error handling for mysqldump failures

### Added
- Added `bc` package for numeric calculations
- Enhanced logging with DEBUG level messages
- Better tracking of database backup processing

### Technical
- Simplified mysqldump flags for better compatibility
- Removed `set -e` during backup loop to handle non-critical errors
- Added fallback for `numfmt` when not available

## [1.0.0] - 2025-01-07

### Added
- Initial release of MySQL Backup with Rclone
- Automated MySQL database backup to Google Drive
- Support for multiple databases
- Configurable cron scheduling
- Automatic cleanup of old backups
- Health checks for container monitoring
- Structured logging with different levels
- Webhook notifications support
- Docker Compose and Docker Swarm support
- Comprehensive error handling and validation
- Security improvements (temporary credentials file)
- Timezone configuration support
- Resource limits and constraints
- Comprehensive documentation and examples

### Security
- Fixed password exposure in process list
- Implemented temporary MySQL credentials file
- Added proper file permissions (600) for sensitive files
- Improved error handling to prevent information leakage

### Features
- Support for multiple MySQL databases
- Configurable backup retention
- Progress reporting during uploads
- Detailed backup summaries
- Connection testing before backup
- Graceful error handling and recovery
- Support for MySQL 5.7 and 8.0
- Compatible with Docker Swarm and Docker Compose

### Documentation
- Complete README with usage examples
- Troubleshooting guide
- Configuration reference
- Deployment instructions
- Security best practices
- Performance optimization tips

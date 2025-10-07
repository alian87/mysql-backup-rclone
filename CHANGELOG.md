# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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

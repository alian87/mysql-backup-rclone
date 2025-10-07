# Contributing to MySQL Backup Rclone

Thank you for your interest in contributing to MySQL Backup Rclone! This document provides guidelines and information for contributors.

## 🚀 Getting Started

### Prerequisites

- Docker installed and running
- Git configured with your credentials
- Basic knowledge of shell scripting
- Understanding of MySQL and Docker concepts

### Development Setup

1. **Fork the repository**
   ```bash
   # Fork on GitHub, then clone your fork
   git clone https://github.com/alian87/mysql-backup-rclone.git
   cd mysql-backup-rclone
   ```

2. **Set up development environment**
   ```bash
   # Build the development image
   docker build -t mysql-backup-rclone:dev .
   
   # Run tests to ensure everything works
   ./tests/test-backup.sh --build --cleanup
   ```

3. **Create a feature branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

## 📋 Contribution Guidelines

### Code Style

- **Shell Scripts**: Follow [Google Shell Style Guide](https://google.github.io/styleguide/shellguide.html)
- **Comments**: Use clear, descriptive comments
- **Functions**: Keep functions small and focused
- **Error Handling**: Always use `set -euo pipefail`
- **Logging**: Use structured logging with timestamps

### Commit Messages

Follow [Conventional Commits](https://www.conventionalcommits.org/) format:

```
type(scope): description

[optional body]

[optional footer]
```

Examples:
```
feat(backup): add support for PostgreSQL databases
fix(entrypoint): resolve timezone configuration issue
docs(readme): update installation instructions
test(backup): add integration tests for large databases
```

### Pull Request Process

1. **Update documentation** for any new features
2. **Add tests** for new functionality
3. **Ensure all tests pass**
4. **Update CHANGELOG.md** with your changes
5. **Create a descriptive PR** with:
   - Clear title and description
   - Link to related issues
   - Screenshots (if applicable)
   - Testing instructions

## 🧪 Testing

### Running Tests

```bash
# Run full test suite
./tests/test-backup.sh --build --cleanup

# Run tests with verbose output
./tests/test-backup.sh --verbose

# Run tests without cleanup (for debugging)
./tests/test-backup.sh --build
```

### Writing Tests

When adding new features, include tests in `tests/test-backup.sh`:

```bash
# Add test function
test_new_feature() {
    log_info "Testing new feature..."
    
    # Test implementation
    if docker exec "$CONTAINER_NAME" test_new_feature_command; then
        log_success "New feature test passed"
    else
        log_error "New feature test failed"
        return 1
    fi
}

# Call test in main function
test_new_feature
```

### Manual Testing

```bash
# Test with different configurations
docker run --rm -e MYSQL_DATABASES="testdb" ... mysql-backup-rclone:dev

# Test error conditions
docker run --rm -e MYSQL_HOST="invalid" ... mysql-backup-rclone:dev
```

## 🏗️ Architecture Guidelines

### Adding New Features

1. **Environment Variables**: Add to Dockerfile and document in README
2. **Configuration**: Use environment variables, not config files
3. **Logging**: Use the existing logging functions
4. **Error Handling**: Follow existing patterns
5. **Security**: Never expose sensitive data in logs

### Script Structure

```bash
#!/bin/bash
set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Logging function
log() {
    local level=$1
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $message" | tee -a /var/log/cron.log
}

# Main function
main() {
    log "INFO" "Starting feature..."
    
    # Implementation
    
    log "INFO" "Feature completed"
}

# Run main function
main "$@"
```

## 📚 Documentation

### Updating Documentation

- **README.md**: Update for new features, configuration options
- **CHANGELOG.md**: Add entries for all changes
- **TROUBLESHOOTING.md**: Add common issues and solutions
- **Examples**: Update example files with new options

### Documentation Standards

- Use clear, concise language
- Include code examples
- Provide troubleshooting information
- Keep examples up-to-date with latest features

## 🐛 Bug Reports

### Before Reporting

1. **Check existing issues** to avoid duplicates
2. **Update to latest version** to ensure bug isn't fixed
3. **Enable debug logging** to gather more information
4. **Test with minimal configuration** to isolate the issue

### Bug Report Template

```markdown
**Describe the bug**
A clear description of what the bug is.

**To Reproduce**
Steps to reproduce the behavior:
1. Set environment variables to '...'
2. Run command '...'
3. See error

**Expected behavior**
What you expected to happen.

**Actual behavior**
What actually happened.

**Environment:**
- Docker version: [e.g. 20.10.12]
- Image version: [e.g. 1.0.0]
- MySQL version: [e.g. 8.0.28]
- OS: [e.g. Ubuntu 20.04]

**Configuration:**
```yaml
# docker-compose.yml or environment variables
```

**Logs:**
```
# Relevant log output
```

**Additional context**
Any other context about the problem.
```

## 💡 Feature Requests

### Before Requesting

1. **Check existing issues** for similar requests
2. **Consider the scope** - is it within project goals?
3. **Think about implementation** - is it feasible?
4. **Consider alternatives** - can existing features be extended?

### Feature Request Template

```markdown
**Is your feature request related to a problem?**
A clear description of what the problem is.

**Describe the solution you'd like**
A clear description of what you want to happen.

**Describe alternatives you've considered**
A clear description of any alternative solutions.

**Use case**
Why is this feature needed? What problem does it solve?

**Implementation ideas**
Any ideas on how this could be implemented?
```

## 🔒 Security

### Security Guidelines

- **Never commit secrets** (passwords, API keys, etc.)
- **Use environment variables** for configuration
- **Validate input** to prevent injection attacks
- **Follow principle of least privilege**
- **Report security issues** privately

### Reporting Security Issues

Email security issues to: alian.v.p.87@gmail.com

Do not create public issues for security vulnerabilities.

## 📊 Performance

### Performance Considerations

- **Minimize container size** by using multi-stage builds
- **Optimize backup scripts** for large databases
- **Use efficient algorithms** for cleanup operations
- **Monitor resource usage** during development

### Benchmarking

```bash
# Test backup performance
time docker exec mysql-backup /scripts/backup.sh

# Monitor resource usage
docker stats mysql-backup

# Test with large databases
docker run -e MYSQL_DATABASES="large_db" ... mysql-backup-rclone
```

## 🎯 Project Goals

### Current Focus Areas

1. **Reliability**: Improve error handling and recovery
2. **Performance**: Optimize for large databases
3. **Security**: Enhance credential handling
4. **Monitoring**: Add better observability
5. **Documentation**: Improve user experience

### Future Considerations

- Support for other databases (PostgreSQL, MongoDB)
- Backup encryption
- Incremental backups
- Multi-cloud support
- Kubernetes deployment

## 📞 Getting Help

### Communication Channels

- **GitHub Issues**: Bug reports and feature requests
- **GitHub Discussions**: Questions and general discussion
- **Email**: Direct contact for sensitive issues

### Code Review Process

1. **Automated checks** must pass
2. **At least one reviewer** required
3. **All feedback addressed** before merge
4. **Tests must pass** on all platforms
5. **Documentation updated** as needed

## 🙏 Recognition

Contributors will be recognized in:
- **README.md** contributors section
- **CHANGELOG.md** for significant contributions
- **Release notes** for major features

Thank you for contributing to MySQL Backup Rclone! 🎉

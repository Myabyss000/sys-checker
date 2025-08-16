# Security Policy

## Supported Versions

We release patches for security vulnerabilities in the following versions:

| Version | Supported          |
| ------- | ------------------ |
| 1.0.x   | :white_check_mark: |

## Reporting a Vulnerability

The System Checker team takes security bugs seriously. We appreciate your efforts to responsibly disclose your findings, and will make every effort to acknowledge your contributions.

### How to Report a Security Vulnerability

**Please do not report security vulnerabilities through public GitHub issues.**

Instead, please report them via one of the following methods:

1. **GitHub Security Advisory**: Use GitHub's private vulnerability reporting feature (Preferred)
   - Go to: https://github.com/Myabyss000/sys-checker/security/advisories/new
2. **Private Issue**: Create a private issue if your GitHub account has access
3. **Email**: Contact the repository owner through GitHub profile

### What to Include

Please include the following information in your report:

- Type of issue (e.g., buffer overflow, SQL injection, cross-site scripting, etc.)
- Full paths of source file(s) related to the manifestation of the issue
- The location of the affected source code (tag/branch/commit or direct URL)
- Any special configuration required to reproduce the issue
- Step-by-step instructions to reproduce the issue
- Proof-of-concept or exploit code (if possible)
- Impact of the issue, including how an attacker might exploit the issue

### Response Timeline

- **Initial Response**: Within 48 hours
- **Confirmation**: Within 7 days
- **Fix Development**: Within 30 days (depending on complexity)
- **Public Disclosure**: After fix is released and deployed

## Security Considerations

### System Permissions

- System Checker requires root/sudo access for package management
- Installation script needs elevated privileges
- Log files are created with appropriate permissions
- Configuration files should be protected from unauthorized access

### Auto-Update Risks

- Auto-update is **disabled by default** for security
- When enabled, only updates existing packages (no new installs/removals)
- Always test auto-update in development environments first
- Monitor logs for any unexpected behavior

### Network Security

- Script communicates with package repositories over HTTPS
- No external data collection or telemetry
- All network operations use system package manager tools
- Timeouts are implemented to prevent hanging

### File System Security

- Logs are rotated to prevent disk space exhaustion
- Temporary files are cleaned up properly
- Path traversal vulnerabilities are prevented
- Input validation on all file operations

### Best Practices

When using System Checker:

1. **Review Configuration**: Always review `config.conf` before first use
2. **Test Updates**: Test auto-updates in non-production environments
3. **Monitor Logs**: Regularly check log files for anomalies
4. **Limit Access**: Restrict access to configuration and log files
5. **Regular Updates**: Keep the System Checker itself updated
6. **Backup Strategy**: Ensure system backups before enabling auto-updates

## Disclosure Policy

When we receive a security bug report, we will:

1. Confirm the problem and determine the affected versions
2. Audit code to find any potential similar problems
3. Prepare fixes for all supported versions
4. Release new versions as quickly as possible
5. Provide security advisory with details after fix deployment

## Comments on This Policy

If you have suggestions on how this process could be improved, please submit a pull request or create an issue to discuss.

---

**Note**: This security policy is based on best practices for open source projects. Adjust contact information and procedures according to your specific project needs.

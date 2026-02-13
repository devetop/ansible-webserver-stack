# Quick Deployment Guide

## Prerequisites

```bash
# Ensure Ansible is installed (minimum version 2.10)
ansible --version

# Ensure you have SSH access to target servers
ssh root@your-server-ip
```

## Step-by-Step Deployment

### 1. Clone or Download Project

```bash
cd /path/to/your/workspace
# If from Git
git clone <repository-url> ansible-webserver-stack
cd ansible-webserver-stack
```

### 2. Install Ansible Requirements

```bash
# Install required Ansible collections
ansible-galaxy collection install -r requirements.yml

# Or using Makefile
make install
```

### 3. Configure Inventory

Edit `inventory.ini` with your server details:

```bash
vim inventory.ini
```

```ini
[webservers]
web1.example.com ansible_host=YOUR_SERVER_IP

[webservers:vars]
ansible_user=root
ansible_port=22
```

### 4. Customize Variables

Edit `group_vars/webservers.yml` to customize PHP and Apache settings:

```bash
vim group_vars/webservers.yml
```

Key settings to review:
```yaml
php_date_timezone: "UTC"              # Your timezone
php_memory_limit: "256M"              # Adjust as needed
php_max_execution_time: "300"         # Adjust as needed
php_upload_max_filesize: "64M"        # Adjust as needed
php_display_errors: "Off"             # "On" for dev, "Off" for production
```

### 5. Test Connectivity

```bash
# Test SSH connection to all hosts
ansible webservers -m ping

# Or using Makefile
make test
```

### 6. Dry Run (Recommended)

```bash
# Run in check mode to see what would change
ansible-playbook site.yml --check --diff

# Or using Makefile
make check
```

### 7. Deploy

```bash
# Full deployment
ansible-playbook site.yml

# Or using Makefile
make deploy
```

### 8. Verify Deployment

```bash
# Manual verification
ansible webservers -a "systemctl status httpd"
ansible webservers -a "php -v"
ansible webservers -a "composer --version"

# Or using Makefile
make verify

# Test in browser
http://YOUR_SERVER_IP
```

## Advanced Deployment Options

### Deploy Specific Roles Only

```bash
# Only install/configure Apache
ansible-playbook site.yml --tags httpd

# Only install/configure PHP
ansible-playbook site.yml --tags php

# Install common packages only
ansible-playbook site.yml --tags common

# Multiple tags
ansible-playbook site.yml --tags "httpd,php"

# Using Makefile
make deploy TAGS=php
```

### Deploy to Specific Hosts

```bash
# Deploy to single host
ansible-playbook site.yml --limit web1.example.com

# Deploy to multiple hosts
ansible-playbook site.yml --limit web1.example.com,web2.example.com

# Using Makefile
make deploy LIMIT=web1.example.com
```

### Override Variables at Runtime

```bash
# Override PHP memory limit
ansible-playbook site.yml -e "php_memory_limit=512M"

# Override multiple variables
ansible-playbook site.yml -e "php_memory_limit=512M php_display_errors=On"
```

### Verbose Output

```bash
# Standard verbose
ansible-playbook site.yml -v

# More verbose (shows task results)
ansible-playbook site.yml -vv

# Very verbose (shows connection info)
ansible-playbook site.yml -vvv

# Debug level
ansible-playbook site.yml -vvvv
```

## Post-Deployment Tasks

### 1. Create a Test PHP File

```bash
ssh root@your-server
echo "<?php phpinfo(); ?>" > /var/www/html/info.php
```

Access: `http://YOUR_SERVER_IP/info.php`

### 2. Configure Firewall (if needed)

```bash
# Already handled by playbook, but for reference:
firewall-cmd --list-all
```

### 3. Check SELinux Status

```bash
sestatus
# Should show: Current mode: enforcing
```

### 4. Review Logs

```bash
# Apache logs
tail -f /var/log/httpd/error_log
tail -f /var/log/httpd/access_log

# PHP logs
tail -f /var/log/php/php_errors.log

# PHP-FPM logs
journalctl -u php-fpm -f
```

## Troubleshooting

### Connection Failed

```bash
# Verify SSH access
ssh -vvv root@your-server-ip

# Check inventory syntax
ansible-inventory --list

# Test with explicit user
ansible webservers -m ping -u root
```

### SELinux Denials

```bash
# Check for denials
ausearch -m avc -ts recent

# Set proper contexts
restorecon -Rv /var/www/html
```

### Apache Not Starting

```bash
# Check configuration
httpd -t

# Check logs
journalctl -u httpd -n 50

# SELinux issues
setsebool -P httpd_can_network_connect 1
```

### PHP Not Working

```bash
# Verify PHP installation
php -v

# Check PHP-FPM status
systemctl status php-fpm

# Test PHP-FPM socket
ls -la /run/php-fpm/www.sock

# Restart services
systemctl restart php-fpm httpd
```

### Firewall Issues

```bash
# Check if firewalld is running
systemctl status firewalld

# List open ports
firewall-cmd --list-all

# Manually open ports if needed
firewall-cmd --permanent --add-service=http
firewall-cmd --permanent --add-service=https
firewall-cmd --reload
```

## Common Makefile Commands

```bash
make help        # Show all available commands
make install     # Install Ansible dependencies
make test        # Test connectivity
make check       # Dry run
make deploy      # Full deployment
make verify      # Verify installation
make tags        # Show available tags
make clean       # Clean temporary files
```

## Updating Existing Installation

```bash
# Re-run to update configuration only
ansible-playbook site.yml --tags config

# Update PHP settings
ansible-playbook site.yml --tags php

# Update and restart services
ansible-playbook site.yml
```

## Backing Out Changes

```bash
# Configuration files are automatically backed up with .backup extension
# Example:
ls /etc/php.ini*
# Output: /etc/php.ini  /etc/php.ini.backup.1707735600

# Restore from backup
cp /etc/php.ini.backup.1707735600 /etc/php.ini
systemctl restart php-fpm
```

## Security Hardening (Post-Deployment)

### 1. Disable Root Login (Recommended)

```bash
# Create sudo user first
ansible-playbook site.yml --tags common

# Update inventory to use sudo user
vim inventory.ini
# Change ansible_user=root to ansible_user=your_sudo_user
```

### 2. Configure SSL/TLS

```bash
# Install certificates
# Update httpd configuration for SSL
# Enable mod_ssl
```

### 3. Configure ModSecurity (Optional)

```bash
yum install mod_security
systemctl restart httpd
```

## Next Steps

1. Configure your application
2. Set up database if needed
3. Configure backups
4. Set up monitoring
5. Configure log rotation
6. Implement CI/CD pipeline

## Support

- Check `README.md` for detailed documentation
- Review `PROJECT_STRUCTURE.md` for file organization
- Check Ansible logs in `./ansible.log`
- Review role-specific defaults in `roles/*/defaults/main.yml`

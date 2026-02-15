# Ansible Role: VirtualHosts

A production-ready Ansible role for managing Apache VirtualHosts with multi-PHP version support, user directory configurations, and PHP-FPM integration.

## Features

- ✅ **Multi-PHP Version Support** - Run different PHP versions (7.4, 8.0, 8.1, 8.2, 8.3) per VirtualHost
- ✅ **User Directory Configuration** - DocumentRoot at `/home/username/public_html`
- ✅ **PHP-FPM Integration** - Uses `proxy_fcgi` for optimal performance
- ✅ **Dynamic VirtualHost Management** - Create and remove VirtualHosts via variables
- ✅ **SELinux Compatible** - Proper contexts for all directories and sockets
- ✅ **Idempotent Operations** - Safe to run multiple times
- ✅ **Security Hardened** - Security headers, proper permissions, restricted access
- ✅ **Automatic Backup** - Option to archive removed VirtualHosts

## Requirements

- **Ansible**: 2.10 or higher
- **Target OS**: Rocky Linux 9 / RHEL 9
- **Apache HTTP Server**: Must be installed (httpd)
- **PHP-FPM**: Must be installed with desired PHP versions
- **SELinux**: Enforcing mode supported
- **Firewalld**: Port 80/443 must be open

## Role Variables

### Required Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `vhosts_list` | List of VirtualHost configurations | See below |

### VirtualHost Configuration Structure

```yaml
vhosts_list:
  - domain: "example.com"              # Primary domain name
    username: "example"                 # System user (must exist)
    php_version: "8.2"                  # PHP version (7.4, 8.0, 8.1, 8.2, 8.3)
    state: "present"                    # present or absent
    server_admin: "admin@example.com"   # Optional: Admin email
    server_alias: "www.example.com"     # Optional: Alias domains
    log_level: "warn"                   # Optional: Log level
    ssl_enabled: false                  # Optional: Enable SSL
    archive_on_remove: true             # Optional: Backup on removal
```

### Optional Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `vhosts_apache_config_dir` | `/etc/httpd/conf.d` | Apache config directory |
| `vhosts_userdir_enabled` | `true` | Enable mod_userdir |
| `vhosts_public_html_dir` | `public_html` | User directory name |
| `vhosts_userdir_permissions` | `0755` | Directory permissions |
| `vhosts_ssl_enabled` | `false` | Global SSL support |
| `vhosts_log_dir` | `/var/log/httpd` | Log file directory |

## Dependencies

This role works best with:
- `httpd` role (for Apache installation)
- `php` role (for PHP-FPM installation)

## Example Playbook

### Basic Usage

```yaml
- hosts: webservers
  become: true
  roles:
    - role: vhosts
      vars:
        vhosts_list:
          - domain: "example.com"
            username: "example"
            php_version: "8.2"
            state: "present"
```

### Complete Example

```yaml
- hosts: webservers
  become: true
  vars:
    vhosts_list:
      # Production site
      - domain: "mysite.com"
        username: "mysite"
        php_version: "8.2"
        state: "present"
        server_admin: "admin@mysite.com"
        server_alias: "www.mysite.com"
      
      # Development site with different PHP
      - domain: "dev.mysite.com"
        username: "devuser"
        php_version: "8.1"
        state: "present"
        log_level: "debug"
      
      # Legacy application
      - domain: "old.mysite.com"
        username: "legacy"
        php_version: "7.4"
        state: "present"
      
      # Removed site (will be deleted)
      - domain: "removed.com"
        username: "olduser"
        php_version: "8.0"
        state: "absent"
        archive_on_remove: true
  
  pre_tasks:
    # Ensure users exist
    - name: Create VirtualHost users
      user:
        name: "{{ item.username }}"
        state: "{{ 'present' if item.state == 'present' else 'absent' }}"
        create_home: true
      loop: "{{ vhosts_list }}"
  
  roles:
    - vhosts
```

## Usage Examples

### Deploy New VirtualHost

1. **Add to vhosts_list**:
```yaml
vhosts_list:
  - domain: "newsite.com"
    username: "newsite"
    php_version: "8.2"
    state: "present"
```

2. **Create user**:
```bash
useradd -m -s /bin/bash newsite
```

3. **Run playbook**:
```bash
ansible-playbook playbook.yml
```

4. **Upload website**:
```bash
scp -r mysite/* newsite@server:/home/newsite/public_html/
```

### Remove VirtualHost

1. **Change state to absent**:
```yaml
vhosts_list:
  - domain: "oldsite.com"
    username: "oldsite"
    php_version: "8.2"
    state: "absent"
    archive_on_remove: true  # Optional: create backup
```

2. **Run playbook**:
```bash
ansible-playbook playbook.yml
```

### Change PHP Version

1. **Update php_version**:
```yaml
vhosts_list:
  - domain: "mysite.com"
    username: "mysite"
    php_version: "8.3"  # Changed from 8.2
    state: "present"
```

2. **Run playbook**:
```bash
ansible-playbook playbook.yml
```

## Directory Structure Created

```
/home/username/
├── public_html/              # DocumentRoot
│   ├── index.html           # Auto-generated welcome page
│   └── info.php             # PHP info page
└── public_html_backup_*.tar.gz  # Backup (if removed with archive)

/etc/httpd/
├── sites-available/
│   └── domain.com.conf      # VirtualHost configuration
└── sites-enabled/
    └── domain.com.conf      # Symlink to enabled VirtualHost

/run/php-fpm/
└── username-phpX.X-fpm.sock  # PHP-FPM socket per user

/etc/php-fpm.d/
└── username.conf            # PHP-FPM pool configuration

/var/log/httpd/
├── domain.com-access.log    # Access logs
└── domain.com-error.log     # Error logs
```

## PHP-FPM Integration

Each VirtualHost gets its own PHP-FPM pool:

- **Socket**: `/run/php-fpm/username-phpX.X-fpm.sock`
- **Pool Config**: `/etc/php-fpm.d/username.conf`
- **User Isolation**: Each pool runs as the VirtualHost user
- **Security**: `open_basedir` restriction to user's directory

## SELinux Configuration

The role automatically configures:

- `httpd_user_content_t` context for `public_html` directories
- `httpd_var_run_t` context for PHP-FPM sockets
- `httpd_can_network_connect` boolean for proxy connections
- Proper file contexts for all managed resources

## Security Features

- ✅ Security headers (X-Frame-Options, X-XSS-Protection, etc.)
- ✅ `open_basedir` restriction per VirtualHost
- ✅ Disabled directory listing
- ✅ User isolation via PHP-FPM pools
- ✅ Proper file permissions (0755 for dirs, 0644 for files)
- ✅ SELinux enforcing mode supported

## Testing

### Test VirtualHost

```bash
# Test configuration syntax
ansible-playbook playbook.yml --check

# View VirtualHost dump
httpd -t -D DUMP_VHOSTS

# Test in browser
curl http://example.com
curl http://example.com/info.php

# Check logs
tail -f /var/log/httpd/example.com-error.log
```

### Verify PHP Version

```bash
curl http://example.com/info.php | grep "PHP Version"
```

### Verify PHP-FPM Socket

```bash
ls -la /run/php-fpm/username-php8.2-fpm.sock
```

## Troubleshooting

### VirtualHost Not Working

1. **Check Apache configuration**:
```bash
httpd -t
httpd -t -D DUMP_VHOSTS
```

2. **Check VirtualHost file**:
```bash
cat /etc/httpd/sites-available/domain.com.conf
```

3. **Verify symlink exists**:
```bash
ls -la /etc/httpd/sites-enabled/
```

### PHP-FPM Socket Error

1. **Check PHP-FPM status**:
```bash
systemctl status php-fpm
journalctl -u php-fpm -n 50
```

2. **Verify socket exists**:
```bash
ls -la /run/php-fpm/
```

3. **Check pool configuration**:
```bash
cat /etc/php-fpm.d/username.conf
```

### Permission Denied

1. **Check home directory permissions**:
```bash
ls -ld /home/username
chmod 711 /home/username
```

2. **Check SELinux context**:
```bash
ls -Z /home/username/public_html
restorecon -Rv /home/username/public_html
```

3. **Check SELinux denials**:
```bash
ausearch -m avc -ts recent
```

## Advanced Configuration

### Custom PHP Settings Per VirtualHost

Edit `/etc/php-fpm.d/username.conf`:

```ini
php_admin_value[memory_limit] = 512M
php_admin_value[max_execution_time] = 300
php_admin_value[upload_max_filesize] = 100M
```

### SSL Support

```yaml
vhosts_list:
  - domain: "secure.example.com"
    username: "secure"
    php_version: "8.2"
    state: "present"
    ssl_enabled: true
    ssl_cert_file: "/etc/pki/tls/certs/example.crt"
    ssl_key_file: "/etc/pki/tls/private/example.key"
```

### Custom Apache Configuration

```yaml
vhosts_list:
  - domain: "custom.example.com"
    username: "custom"
    php_version: "8.2"
    state: "present"
    additional_config: |
      # Custom configuration
      RewriteEngine On
      RewriteCond %{HTTPS} off
      RewriteRule ^(.*)$ https://%{HTTP_HOST}$1 [R=301,L]
```

## Tags

Run specific parts of the role:

```bash
# Only configure mod_userdir
ansible-playbook playbook.yml --tags userdir

# Only manage VirtualHosts
ansible-playbook playbook.yml --tags vhosts

# Only PHP-FPM configuration
ansible-playbook playbook.yml --tags php-fpm
```

## License

MIT

## Author

DevOps Team

## Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Create a Pull Request

## Changelog

### Version 1.0.0
- Initial release
- Multi-PHP version support (7.4, 8.0, 8.1, 8.2, 8.3)
- User directory configuration
- PHP-FPM integration
- SELinux support
- Dynamic VirtualHost management
- Security hardening

# Ansible Web Server Stack - Production Ready

A comprehensive, production-ready Ansible project for provisioning and configuring a Web Server stack on Rocky Linux 9.

## 🚀 Features

- **Apache HTTP Server** (httpd) with security hardening
- **PHP 8.2** from Remi Repository
- **Composer** (latest version) installed globally
- **Fully configurable** PHP settings via variables
- **SELinux** compatible configurations
- **Firewalld** integration
- **Idempotent** operations
- **Production-ready** defaults with security best practices

## 📋 Requirements

- **Ansible**: 2.10 or higher
- **Target OS**: Rocky Linux 9
- **SSH Access**: Root or sudo-enabled user
- **Python 3**: Installed on target hosts

## 🏗️ Project Structure

```
ansible-webserver-stack/
├── ansible.cfg                     # Ansible configuration
├── inventory.ini                   # Inventory file
├── site.yml                        # Main playbook
├── .gitignore                      # Git ignore rules
├── README.md                       # This file
├── group_vars/
│   └── webservers.yml             # Variables for webservers group
├── host_vars/                     # Host-specific variables (optional)
└── roles/
    ├── common/                    # Base system configuration
    │   ├── defaults/
    │   │   └── main.yml
    │   ├── handlers/
    │   │   └── main.yml
    │   ├── meta/
    │   │   └── main.yml
    │   └── tasks/
    │       └── main.yml
    ├── httpd/                     # Apache web server
    │   ├── defaults/
    │   │   └── main.yml
    │   ├── handlers/
    │   │   └── main.yml
    │   ├── meta/
    │   │   └── main.yml
    │   ├── tasks/
    │   │   └── main.yml
    │   └── templates/
    │       ├── httpd.conf.j2
    │       └── security.conf.j2
    └── php/                       # PHP and Composer
        ├── defaults/
        │   └── main.yml
        ├── handlers/
        │   └── main.yml
        ├── meta/
        │   └── main.yml
        ├── tasks/
        │   ├── main.yml
        │   ├── install_remi.yml
        │   ├── install_php.yml
        │   ├── configure_php.yml
        │   ├── configure_php_fpm.yml
        │   └── install_composer.yml
        └── templates/
            └── php.ini.j2
```

## ⚙️ Configuration

### PHP Configuration Variables

All PHP settings are configurable via `group_vars/webservers.yml`:

```yaml
# Timezone
php_date_timezone: "UTC"

# Error Handling
php_display_errors: "Off"           # Set to "On" for development
php_error_reporting: "E_ALL & ~E_DEPRECATED & ~E_STRICT"

# Memory and Execution
php_memory_limit: "256M"
php_max_execution_time: "300"

# Upload Limits
php_post_max_size: "64M"
php_upload_max_filesize: "64M"
```

### Inventory Configuration

Edit `inventory.ini` to define your target hosts:

```ini
[webservers]
web1.example.com ansible_host=192.168.1.10
web2.example.com ansible_host=192.168.1.11

[webservers:vars]
ansible_user=root
ansible_port=22
```

## 🚀 Quick Start

### 1. Clone the Repository

```bash
git clone <repository-url>
cd ansible-webserver-stack
```

### 2. Configure Inventory

Edit `inventory.ini` with your target hosts:

```bash
vim inventory.ini
```

### 3. Customize Variables

Edit `group_vars/webservers.yml` to customize PHP and other settings:

```bash
vim group_vars/webservers.yml
```

### 4. Test Connection

```bash
ansible webservers -m ping
```

### 5. Run the Playbook

```bash
# Full deployment
ansible-playbook site.yml

# Check mode (dry run)
ansible-playbook site.yml --check

# With verbose output
ansible-playbook site.yml -v
```

## 🏷️ Using Tags

Run specific parts of the playbook:

```bash
# Only install common packages
ansible-playbook site.yml --tags common

# Only configure Apache
ansible-playbook site.yml --tags httpd

# Only install/configure PHP
ansible-playbook site.yml --tags php

# Install Composer only
ansible-playbook site.yml --tags composer

# Multiple tags
ansible-playbook site.yml --tags "httpd,php"
```

## 🔐 Security Features

- **SELinux**: Enforcing mode with proper contexts
- **Firewalld**: Configured with minimal required ports
- **Apache Security Headers**: XSS, Clickjacking, MIME-sniffing protection
- **PHP Security**: Disabled dangerous functions, secure session handling
- **Server Tokens**: Minimal information disclosure

## 📊 Verification

After deployment, verify the installation:

```bash
# Check Apache status
ansible webservers -a "systemctl status httpd"

# Check PHP version
ansible webservers -a "php -v"

# Check Composer version
ansible webservers -a "composer --version"

# Test web server
curl http://web1.example.com
```

## 🎯 Advanced Usage

### Running on Specific Hosts

```bash
ansible-playbook site.yml --limit web1.example.com
```

### Using Different Inventory

```bash
ansible-playbook site.yml -i production.ini
```

### Overriding Variables

```bash
ansible-playbook site.yml -e "php_memory_limit=512M"
```

### Skip Specific Roles

```bash
ansible-playbook site.yml --skip-tags composer
```

## 🛠️ Customization

### Adding More PHP Extensions

Edit `roles/php/defaults/main.yml`:

```yaml
php_packages:
  - php
  - php-cli
  - php-mysqlnd
  - php-redis      # Add this
  - php-memcached  # Add this
```

### Changing Apache Listen Port

Edit `group_vars/webservers.yml`:

```yaml
httpd_listen_port: 8080
```

### Adjusting PHP-FPM Pool Settings

Edit `group_vars/webservers.yml`:

```yaml
php_fpm_pm_max_children: 100
php_fpm_pm_start_servers: 10
```

## 📝 Best Practices

1. **Version Control**: Always commit your changes
2. **Variable Overrides**: Use host_vars for host-specific settings
3. **Testing**: Run with `--check` flag before applying
4. **Backups**: Playbook automatically backs up config files
5. **Documentation**: Update this README when adding features

## 🐛 Troubleshooting

### Connection Issues

```bash
# Test SSH connectivity
ansible webservers -m ping -vvv

# Check inventory
ansible-inventory --list
```

### SELinux Denials

```bash
# Check audit log
ansible webservers -a "grep denied /var/log/audit/audit.log"
```

### PHP Configuration Not Applied

```bash
# Verify PHP configuration
ansible webservers -a "php -i | grep memory_limit"

# Check PHP-FPM status
ansible webservers -a "systemctl status php-fpm"
```

## 📚 Additional Resources

- [Ansible Documentation](https://docs.ansible.com/)
- [Rocky Linux 9 Documentation](https://docs.rockylinux.org/)
- [PHP Documentation](https://www.php.net/manual/en/)
- [Apache HTTP Server Documentation](https://httpd.apache.org/docs/)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## 📄 License

This project is licensed under the MIT License.

## ✨ Author

DevOps Team

## 🔄 Changelog

### Version 1.0.0
- Initial release
- Apache HTTP Server installation
- PHP 8.2 from Remi repository
- Composer installation
- Full variable-based PHP configuration
- SELinux and Firewalld integration

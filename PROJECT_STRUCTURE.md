# Ansible Web Server Stack - Directory Structure

```
ansible-webserver-stack/
│
├── ansible.cfg                              # Ansible configuration file
├── inventory.ini                            # Inventory file with host definitions
├── site.yml                                 # Main playbook
├── requirements.yml                         # Ansible Galaxy dependencies
├── Makefile                                 # Automation shortcuts
├── README.md                                # Project documentation
├── .gitignore                               # Git ignore rules
│
├── group_vars/                              # Group variables directory
│   └── webservers.yml                       # Variables for webservers group
│
├── host_vars/                               # Host-specific variables
│   └── web1.example.com.yml.example        # Example host variables
│
└── roles/                                   # Ansible roles directory
    │
    ├── common/                              # Common system configuration role
    │   ├── defaults/
    │   │   └── main.yml                     # Default variables
    │   ├── meta/
    │   │   └── main.yml                     # Role metadata
    │   └── tasks/
    │       └── main.yml                     # Common setup tasks
    │
    ├── httpd/                               # Apache HTTP Server role
    │   ├── defaults/
    │   │   └── main.yml                     # Default Apache variables
    │   ├── handlers/
    │   │   └── main.yml                     # Service handlers
    │   ├── meta/
    │   │   └── main.yml                     # Role metadata
    │   ├── tasks/
    │   │   └── main.yml                     # Apache installation tasks
    │   └── templates/
    │       ├── httpd.conf.j2                # Apache main config template
    │       └── security.conf.j2             # Apache security config
    │
    └── php/                                 # PHP and Composer role
        ├── defaults/
        │   └── main.yml                     # Default PHP variables
        ├── handlers/
        │   └── main.yml                     # PHP service handlers
        ├── meta/
        │   └── main.yml                     # Role metadata
        ├── tasks/
        │   ├── main.yml                     # Main task orchestration
        │   ├── install_remi.yml             # Remi repository setup
        │   ├── install_php.yml              # PHP installation
        │   ├── configure_php.yml            # PHP configuration
        │   ├── configure_php_fpm.yml        # PHP-FPM setup
        │   └── install_composer.yml         # Composer installation
        └── templates/
            └── php.ini.j2                   # PHP configuration template
```

## File Descriptions

### Root Level Files

| File | Purpose |
|------|---------|
| `ansible.cfg` | Ansible behavior configuration, logging, performance tuning |
| `inventory.ini` | Defines target hosts and groups |
| `site.yml` | Main playbook that orchestrates all roles |
| `requirements.yml` | Ansible Galaxy collection dependencies |
| `Makefile` | Helper commands for common operations |
| `README.md` | Comprehensive project documentation |
| `.gitignore` | Git exclusion patterns for sensitive/temporary files |

### Variables

| File | Purpose |
|------|---------|
| `group_vars/webservers.yml` | PHP configuration, Apache settings for all webservers |
| `host_vars/*.yml` | Host-specific overrides (optional) |

### Common Role

| Component | Purpose |
|-----------|---------|
| `defaults/main.yml` | Base system packages, NTP, firewall, SELinux settings |
| `tasks/main.yml` | System updates, package installation, service configuration |
| `meta/main.yml` | Role metadata and dependencies |

### HTTPD Role

| Component | Purpose |
|-----------|---------|
| `defaults/main.yml` | Apache packages, ports, security settings |
| `tasks/main.yml` | Apache installation, configuration, firewall rules |
| `handlers/main.yml` | Service restart/reload handlers |
| `templates/httpd.conf.j2` | Main Apache configuration |
| `templates/security.conf.j2` | Security headers and hardening |
| `meta/main.yml` | Role metadata |

### PHP Role

| Component | Purpose |
|-----------|---------|
| `defaults/main.yml` | PHP version, packages, all configuration defaults |
| `tasks/main.yml` | Task orchestration |
| `tasks/install_remi.yml` | Remi repository installation |
| `tasks/install_php.yml` | PHP 8.2 installation |
| `tasks/configure_php.yml` | PHP.ini configuration |
| `tasks/configure_php_fpm.yml` | PHP-FPM pool configuration |
| `tasks/install_composer.yml` | Composer global installation |
| `handlers/main.yml` | PHP-FPM and httpd restart handlers |
| `templates/php.ini.j2` | Complete PHP configuration template |
| `meta/main.yml` | Role metadata |

## Key Features by Component

### Common Role Features
- ✅ System package updates
- ✅ Essential tools installation
- ✅ NTP/timezone configuration
- ✅ Firewalld setup
- ✅ SELinux configuration
- ✅ System limits tuning

### HTTPD Role Features
- ✅ Apache HTTP Server installation
- ✅ SSL module support
- ✅ Security headers (XSS, Clickjacking protection)
- ✅ Firewall rules (HTTP/HTTPS)
- ✅ SELinux contexts
- ✅ Custom virtual host support

### PHP Role Features
- ✅ PHP 8.2 from Remi repository
- ✅ PHP-FPM with Apache integration
- ✅ All PHP.ini settings via variables
- ✅ Composer installed globally
- ✅ OPcache configuration
- ✅ Session management
- ✅ Upload/POST limits configuration

## Workflow

1. **Inventory Definition** → Define hosts in `inventory.ini`
2. **Variable Configuration** → Set PHP/Apache settings in `group_vars/webservers.yml`
3. **Execution** → Run `site.yml` playbook
4. **Role Execution Order**:
   - Common → Base system setup
   - HTTPD → Apache installation
   - PHP → PHP 8.2 + Composer installation
5. **Verification** → Post-tasks verify all services are running

## Customization Points

| What to Customize | Where |
|-------------------|-------|
| Target hosts | `inventory.ini` |
| PHP settings | `group_vars/webservers.yml` |
| Apache settings | `group_vars/webservers.yml` or `roles/httpd/defaults/main.yml` |
| PHP packages | `roles/php/defaults/main.yml` |
| System packages | `roles/common/defaults/main.yml` |
| Host-specific settings | `host_vars/hostname.yml` |

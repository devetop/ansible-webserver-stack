# Complete Directory Structure

```
ansible-webserver-stack/
│
├── 📄 ansible.cfg                           # Ansible configuration (performance, logging, SSH)
├── 📄 inventory.ini                         # Host inventory (define target servers)
├── 📄 site.yml                              # Main playbook (orchestrates all roles)
├── 📄 requirements.yml                      # Ansible Galaxy dependencies
├── 📄 Makefile                              # Automation shortcuts (install, deploy, test)
├── 📄 .gitignore                            # Git exclusions (secrets, temp files)
│
├── 📚 README.md                             # Complete documentation
├── 📚 DEPLOYMENT_GUIDE.md                   # Step-by-step deployment instructions
├── 📚 PROJECT_STRUCTURE.md                  # Detailed architecture documentation
├── 📚 PROJECT_SUMMARY.md                    # Quick overview and reference
│
├── 📁 group_vars/
│   └── 📄 webservers.yml                    # ⚙️ PHP & Apache configuration variables
│
├── 📁 host_vars/
│   └── 📄 web1.example.com.yml.example      # Example host-specific variables
│
└── 📁 roles/                                # Ansible roles directory
    │
    ├── 📁 common/                           # 🔧 Base system configuration
    │   ├── 📁 defaults/
    │   │   └── 📄 main.yml                  # Default variables (packages, NTP, firewall)
    │   ├── 📁 files/                        # (empty - for static files)
    │   ├── 📁 handlers/                     # (empty - no handlers needed)
    │   ├── 📁 meta/
    │   │   └── 📄 main.yml                  # Role metadata (author, license, platforms)
    │   ├── 📁 tasks/
    │   │   └── 📄 main.yml                  # Tasks (updates, packages, services)
    │   ├── 📁 templates/                    # (empty - no templates needed)
    │   └── 📁 vars/                         # (empty - use defaults instead)
    │
    ├── 📁 httpd/                            # 🌐 Apache HTTP Server
    │   ├── 📁 defaults/
    │   │   └── 📄 main.yml                  # Apache variables (ports, security, modules)
    │   ├── 📁 files/                        # (empty - using templates)
    │   ├── 📁 handlers/
    │   │   └── 📄 main.yml                  # Service handlers (restart, reload)
    │   ├── 📁 meta/
    │   │   └── 📄 main.yml                  # Role metadata
    │   ├── 📁 tasks/
    │   │   └── 📄 main.yml                  # Tasks (install, configure, secure)
    │   ├── 📁 templates/
    │   │   ├── 📄 httpd.conf.j2             # Main Apache configuration template
    │   │   └── 📄 security.conf.j2          # Security headers configuration
    │   └── 📁 vars/                         # (empty - use defaults)
    │
    └── 📁 php/                              # 🐘 PHP 8.2 & Composer
        ├── 📁 defaults/
        │   └── 📄 main.yml                  # PHP variables (all configuration options)
        ├── 📁 files/                        # (empty - using templates)
        ├── 📁 handlers/
        │   └── 📄 main.yml                  # Service handlers (PHP-FPM, httpd)
        ├── 📁 meta/
        │   └── 📄 main.yml                  # Role metadata
        ├── 📁 tasks/
        │   ├── 📄 main.yml                  # Main task orchestration
        │   ├── 📄 install_remi.yml          # Remi repository installation
        │   ├── 📄 install_php.yml           # PHP 8.2 installation
        │   ├── 📄 configure_php.yml         # PHP.ini configuration
        │   ├── 📄 configure_php_fpm.yml     # PHP-FPM pool configuration
        │   └── 📄 install_composer.yml      # Composer global installation
        ├── 📁 templates/
        │   └── 📄 php.ini.j2                # PHP configuration template (all settings)
        └── 📁 vars/                         # (empty - use defaults)

```

## Legend

📄 File  
📁 Directory  
📚 Documentation  
🔧 System Configuration  
🌐 Web Server  
🐘 PHP  
⚙️ Configuration Variables  

## File Count by Type

| Type | Count | Description |
|------|-------|-------------|
| Playbooks | 1 | Main site.yml orchestration |
| Configuration | 4 | ansible.cfg, inventory.ini, requirements.yml, .gitignore |
| Documentation | 4 | README, guides, structure docs |
| Role Defaults | 3 | Variable definitions (common, httpd, php) |
| Role Tasks | 7 | Task execution files |
| Role Meta | 3 | Role metadata |
| Role Handlers | 2 | Service management |
| Templates | 3 | Configuration file templates |
| Group Variables | 1 | Shared webserver configuration |
| Helper Tools | 1 | Makefile |

**Total: 30+ files**

## Key Files Explained

### Root Level
- **ansible.cfg**: Controls Ansible behavior, logging, performance tuning
- **inventory.ini**: Defines which servers to manage
- **site.yml**: Orchestrates all roles in correct order
- **requirements.yml**: Lists Ansible Galaxy collections needed
- **Makefile**: Provides convenient shortcuts for common commands

### Variables
- **group_vars/webservers.yml**: THE KEY FILE - All PHP & Apache settings
- **host_vars/*.yml**: Override settings for specific servers

### Common Role
- **tasks/main.yml**: System updates, essential packages, NTP, firewall, SELinux

### HTTPD Role  
- **tasks/main.yml**: Install Apache, configure, secure, enable firewall
- **templates/httpd.conf.j2**: Main Apache configuration
- **templates/security.conf.j2**: Security headers (XSS, clickjacking protection)

### PHP Role
- **tasks/install_remi.yml**: Set up Remi repository for PHP 8.2
- **tasks/install_php.yml**: Install PHP and all extensions
- **tasks/configure_php.yml**: Apply php.ini configuration
- **tasks/configure_php_fpm.yml**: Set up PHP-FPM pools
- **tasks/install_composer.yml**: Install Composer globally
- **templates/php.ini.j2**: Complete PHP configuration (40+ settings)

## Execution Flow

```
1. site.yml (main playbook)
   │
   ├─→ Pre-tasks
   │   ├─ Verify OS (Rocky Linux 9)
   │   └─ Update package cache
   │
   ├─→ Role: common
   │   ├─ System updates
   │   ├─ Install essential packages
   │   ├─ Configure NTP/timezone
   │   ├─ Set up firewall
   │   └─ Configure SELinux
   │
   ├─→ Role: httpd
   │   ├─ Install Apache packages
   │   ├─ Deploy configuration
   │   ├─ Set up security headers
   │   ├─ Configure firewall rules
   │   └─ Start Apache service
   │
   ├─→ Role: php
   │   ├─ Install Remi repository
   │   ├─ Install PHP 8.2
   │   ├─ Configure PHP settings
   │   ├─ Set up PHP-FPM
   │   └─ Install Composer
   │
   └─→ Post-tasks
       ├─ Verify Apache is running
       ├─ Verify PHP version
       ├─ Verify Composer version
       └─ Display summary
```

## Variable Precedence

```
Highest Priority
    ↓
1. Extra vars (-e from command line)
2. Task vars
3. Block vars
4. Role vars
5. Host vars (host_vars/*.yml)
6. Group vars (group_vars/*.yml)
7. Role defaults (roles/*/defaults/main.yml)
    ↓
Lowest Priority
```

**Pro Tip**: Put common settings in group_vars, host-specific in host_vars!

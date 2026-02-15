# VirtualHosts Role - Visual Workflow

## System Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        ANSIBLE CONTROL NODE                              │
│                                                                           │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                      playbook_vhosts.yml                         │   │
│  │  ┌────────────────────────────────────────────────────────┐     │   │
│  │  │  vhosts_list:                                           │     │   │
│  │  │    - domain: "site1.com" | php: "8.2" | state: present│     │   │
│  │  │    - domain: "site2.com" | php: "8.1" | state: present│     │   │
│  │  │    - domain: "site3.com" | php: "7.4" | state: present│     │   │
│  │  └────────────────────────────────────────────────────────┘     │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                    │                                     │
│                                    │ ansible-playbook                    │
│                                    ▼                                     │
└─────────────────────────────────────────────────────────────────────────┘
                                     │
                                     │ SSH
                                     ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                         TARGET WEB SERVER                                │
│                                                                           │
│  ┌──────────────────────────────────────────────────────────────────┐  │
│  │                      ROLE: vhosts                                 │  │
│  │                                                                    │  │
│  │  ┌────────────────┐  ┌────────────────┐  ┌──────────────────┐  │  │
│  │  │ setup_userdir  │  │ setup_php_fpm  │  │ manage_vhosts    │  │  │
│  │  │                │  │                │  │                  │  │  │
│  │  │ • mod_userdir  │  │ • Create pools │  │ • Generate .conf │  │  │
│  │  │ • Create dirs  │  │ • Sockets      │  │ • Enable vhosts  │  │  │
│  │  │ • SELinux      │  │ • SELinux      │  │ • Remove old     │  │  │
│  │  │ • Permissions  │  │ • Verify       │  │ • Validate       │  │  │
│  │  └────────────────┘  └────────────────┘  └──────────────────┘  │  │
│  └──────────────────────────────────────────────────────────────────┘  │
│                                    │                                     │
│                                    ▼                                     │
│  ┌──────────────────────────────────────────────────────────────────┐  │
│  │                    CREATED INFRASTRUCTURE                         │  │
│  │                                                                    │  │
│  │  /home/                                                            │  │
│  │  ├── site1/                                                        │  │
│  │  │   └── public_html/  ← DocumentRoot (site1.com)                │  │
│  │  ├── site2/                                                        │  │
│  │  │   └── public_html/  ← DocumentRoot (site2.com)                │  │
│  │  └── site3/                                                        │  │
│  │      └── public_html/  ← DocumentRoot (site3.com)                │  │
│  │                                                                    │  │
│  │  /etc/httpd/                                                       │  │
│  │  ├── sites-available/                                             │  │
│  │  │   ├── site1.com.conf  ← VirtualHost config                    │  │
│  │  │   ├── site2.com.conf                                           │  │
│  │  │   └── site3.com.conf                                           │  │
│  │  └── sites-enabled/                                               │  │
│  │      ├── site1.com.conf  → symlink to sites-available            │  │
│  │      ├── site2.com.conf                                           │  │
│  │      └── site3.com.conf                                           │  │
│  │                                                                    │  │
│  │  /run/php-fpm/                                                     │  │
│  │  ├── site1-php8.2-fpm.sock  ← PHP-FPM socket                     │  │
│  │  ├── site2-php8.1-fpm.sock                                        │  │
│  │  └── site3-php7.4-fpm.sock                                        │  │
│  │                                                                    │  │
│  │  /etc/php-fpm.d/                                                   │  │
│  │  ├── site1.conf  ← PHP-FPM pool config                           │  │
│  │  ├── site2.conf                                                    │  │
│  │  └── site3.conf                                                    │  │
│  └──────────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────────┘

```

## Request Flow

```
┌──────────────┐
│   Browser    │
│              │
│ site1.com    │
└──────┬───────┘
       │ HTTP Request
       │
       ▼
┌─────────────────────────────────────────────────────────────┐
│                    Apache httpd                              │
│  ┌────────────────────────────────────────────────────┐     │
│  │  VirtualHost site1.com:80                          │     │
│  │  ServerName site1.com                              │     │
│  │  DocumentRoot /home/site1/public_html              │     │
│  │  <FilesMatch \.php$>                               │     │
│  │    SetHandler proxy:unix:/run/php-fpm/             │     │
│  │               site1-php8.2-fpm.sock                │     │
│  │  </FilesMatch>                                     │     │
│  └────────────────────────────────────────────────────┘     │
└─────────────────────┬───────────────────────────────────────┘
                      │
         ┌────────────┴────────────┐
         │                         │
         │ .html, .css, .js       │ .php files
         │                         │
         ▼                         ▼
    ┌─────────────┐         ┌───────────────────────────┐
    │ Static File │         │    PHP-FPM Pool (site1)   │
    │             │         │ ┌───────────────────────┐ │
    │ Serve       │         │ │  • User: site1        │ │
    │ directly    │         │ │  • PHP 8.2            │ │
    │             │         │ │  • open_basedir:      │ │
    └─────────────┘         │ │    /home/site1/...    │ │
                            │ │  • Memory: 256M       │ │
                            │ └───────────────────────┘ │
                            │           │               │
                            │           ▼               │
                            │    Process PHP Script     │
                            │           │               │
                            │           ▼               │
                            │    Return Response        │
                            └───────────────────────────┘
                                       │
                                       ▼
                            ┌─────────────────────┐
                            │  HTTP Response      │
                            │  (HTML/JSON/etc)    │
                            └─────────────────────┘
                                       │
                                       ▼
                            ┌─────────────────────┐
                            │     Browser         │
                            └─────────────────────┘
```

## Multi-PHP Version Isolation

```
┌─────────────────────────────────────────────────────────────┐
│              Single Apache Server                            │
│                                                               │
│  VirtualHost: site1.com                                      │
│  ├─ PHP Version: 8.2                                         │
│  ├─ Socket: /run/php-fpm/site1-php8.2-fpm.sock             │
│  ├─ Pool: site1                                             │
│  └─ User: site1                                             │
│      └─ open_basedir: /home/site1/public_html              │
│                                                               │
│  VirtualHost: site2.com                                      │
│  ├─ PHP Version: 8.1                                         │
│  ├─ Socket: /run/php-fpm/site2-php8.1-fpm.sock             │
│  ├─ Pool: site2                                             │
│  └─ User: site2                                             │
│      └─ open_basedir: /home/site2/public_html              │
│                                                               │
│  VirtualHost: site3.com                                      │
│  ├─ PHP Version: 7.4 (Legacy)                               │
│  ├─ Socket: /run/php-fpm/site3-php7.4-fpm.sock             │
│  ├─ Pool: site3                                             │
│  └─ User: site3                                             │
│      └─ open_basedir: /home/site3/public_html              │
└─────────────────────────────────────────────────────────────┘

BENEFITS:
✅ Different PHP versions per site
✅ Complete user isolation
✅ Independent resource limits
✅ Security via open_basedir
✅ No interference between sites
```

## Security Layers

```
┌─────────────────────────────────────────────────────────────┐
│                     SECURITY STACK                           │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  Layer 1: Apache Security Headers                           │
│  ├─ X-Frame-Options: SAMEORIGIN                             │
│  ├─ X-XSS-Protection: 1; mode=block                         │
│  ├─ X-Content-Type-Options: nosniff                         │
│  ├─ Referrer-Policy: strict-origin-when-cross-origin        │
│  └─ Strict-Transport-Security (if SSL)                      │
│                                                               │
│  Layer 2: Apache Configuration                              │
│  ├─ Options -Indexes (no directory listing)                 │
│  ├─ ServerTokens Prod (minimal info)                        │
│  ├─ ServerSignature Off                                     │
│  └─ AllowOverride control                                   │
│                                                               │
│  Layer 3: PHP-FPM Pool Isolation                            │
│  ├─ Per-user process isolation                              │
│  ├─ open_basedir restrictions                               │
│  ├─ Separate pools                                          │
│  └─ Resource limits                                         │
│                                                               │
│  Layer 4: File System Permissions                           │
│  ├─ public_html: 0755                                       │
│  ├─ Home directory: 0711                                    │
│  ├─ Files: 0644                                             │
│  └─ Ownership: user:user                                    │
│                                                               │
│  Layer 5: SELinux Contexts                                  │
│  ├─ public_html: httpd_user_content_t                       │
│  ├─ PHP-FPM sockets: httpd_var_run_t                        │
│  ├─ Boolean: httpd_can_network_connect                      │
│  └─ Automatic context restoration                           │
│                                                               │
└─────────────────────────────────────────────────────────────┘
```

## Deployment Timeline

```
Time: 0s
│
├─ [0-10s] Validation
│   ├─ Verify vhosts_list
│   ├─ Check Apache modules
│   └─ Validate requirements
│
├─ [10-30s] User Directory Setup
│   ├─ Configure mod_userdir
│   ├─ Create public_html directories
│   ├─ Set permissions
│   ├─ Apply SELinux contexts
│   └─ Generate default pages
│
├─ [30-60s] PHP-FPM Configuration
│   ├─ Create PHP-FPM pools
│   ├─ Configure sockets
│   ├─ Set security policies
│   ├─ Apply SELinux contexts
│   └─ Start/restart PHP-FPM
│
├─ [60-90s] VirtualHost Management
│   ├─ Generate VirtualHost configs
│   ├─ Create symlinks
│   ├─ Include in Apache config
│   ├─ Remove absent VirtualHosts
│   └─ Validate configuration
│
├─ [90-120s] Service Management
│   ├─ Validate Apache config
│   ├─ Reload Apache
│   ├─ Verify sockets
│   └─ Test connections
│
└─ [120s] Complete ✅
    └─ All VirtualHosts active and tested
```

## File Generation Flow

```
Input: vhosts_list variable
   │
   ├─────────────────────────────────┬───────────────────────────────┐
   │                                 │                               │
   ▼                                 ▼                               ▼
templates/                      tasks/                          files/
vhost.conf.j2                   manage_vhosts.yml               (created)
   │                                 │                               │
   │ Jinja2 Processing              │ Task Execution                │
   │                                 │                               │
   ▼                                 ▼                               ▼
Generated                       Directories                     Content
Configuration                   Created                         Generated
   │                                 │                               │
   ├─────────────────────────────────┴───────────────────────────────┤
   │                                                                   │
   ▼                                                                   ▼
/etc/httpd/sites-available/domain.conf              /home/user/public_html/
   │                                                    ├─ index.html
   │                                                    └─ info.php
   ▼
Symlink created
   │
   ▼
/etc/httpd/sites-enabled/domain.conf
   │
   ▼
Apache reload
   │
   ▼
VirtualHost Active ✅
```

---

## Component Interactions

```
┌─────────────────────────────────────────────────────────────┐
│                    defaults/main.yml                         │
│  • vhosts_list                                              │
│  • PHP version mappings                                     │
│  • Directory configurations                                 │
└─────────────┬───────────────────────────────────────────────┘
              │
              ▼
┌─────────────────────────────────────────────────────────────┐
│                     tasks/main.yml                           │
│  Orchestrates:                                              │
│  ├─ Validation                                              │
│  ├─ setup_userdir.yml                                       │
│  ├─ setup_php_fpm.yml                                       │
│  └─ manage_vhosts.yml                                       │
└─────────────┬───────────────────────────────────────────────┘
              │
              ├──────────────┬──────────────┬─────────────────┐
              │              │              │                 │
              ▼              ▼              ▼                 ▼
      ┌─────────────┐ ┌────────────┐ ┌──────────────┐ ┌───────────┐
      │  User Dirs  │ │  PHP-FPM   │ │ VirtualHosts │ │ Handlers  │
      │  Created    │ │  Configured│ │  Deployed    │ │ Triggered │
      └─────────────┘ └────────────┘ └──────────────┘ └───────────┘
              │              │              │                 │
              └──────────────┴──────────────┴─────────────────┘
                                    │
                                    ▼
                          ┌──────────────────┐
                          │  Apache Reload   │
                          └──────────────────┘
                                    │
                                    ▼
                          ┌──────────────────┐
                          │  System Ready ✅ │
                          └──────────────────┘
```

---

**Visual diagrams help understand the complete system architecture!**

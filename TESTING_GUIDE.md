###############################################################################
# VirtualHosts Role - Quick Start & Testing Guide
###############################################################################

## QUICK START GUIDE

### 1. Prerequisites Check
```bash
# Verify Apache is installed
httpd -v

# Verify PHP-FPM is installed
php-fpm -v

# Check SELinux status
sestatus

# Verify firewall
firewall-cmd --list-all
```

### 2. Prepare Your Environment

#### Create System Users
```bash
# Create users for each VirtualHost
useradd -m -s /bin/bash mysite
useradd -m -s /bin/bash devsite
useradd -m -s /bin/bash legacy

# Verify users
id mysite
```

#### Set User Passwords (Optional)
```bash
passwd mysite
```

### 3. Configure Your Playbook

Create `vhosts_deploy.yml`:

```yaml
---
- hosts: webservers
  become: true
  vars:
    vhosts_list:
      - domain: "mysite.com"
        username: "mysite"
        php_version: "8.2"
        state: "present"
  roles:
    - vhosts
```

### 4. Deploy VirtualHosts
```bash
# Test in check mode first
ansible-playbook vhosts_deploy.yml --check

# Deploy
ansible-playbook vhosts_deploy.yml

# Deploy with verbose output
ansible-playbook vhosts_deploy.yml -v
```

### 5. Verify Deployment
```bash
# Check Apache VirtualHosts
httpd -t -D DUMP_VHOSTS

# Check configuration files
ls -la /etc/httpd/sites-enabled/

# Check PHP-FPM pools
ls -la /etc/php-fpm.d/

# Check PHP-FPM sockets
ls -la /run/php-fpm/

# Test Apache
systemctl status httpd
curl http://mysite.com
```

### 6. Upload Your Website
```bash
# Using SCP
scp -r /path/to/website/* mysite@server:/home/mysite/public_html/

# Using rsync
rsync -avz /path/to/website/ mysite@server:/home/mysite/public_html/

# Using Git
ssh mysite@server
cd ~/public_html
git clone https://github.com/user/website.git .
```

---

## TESTING GUIDE

### Test 1: Basic VirtualHost Functionality

#### Deploy Test VirtualHost
```yaml
vhosts_list:
  - domain: "test.local"
    username: "testuser"
    php_version: "8.2"
    state: "present"
```

#### Test Steps
```bash
# 1. Add to /etc/hosts
echo "127.0.0.1 test.local" >> /etc/hosts

# 2. Test HTTP
curl http://test.local

# 3. Test PHP
curl http://test.local/info.php

# 4. Expected: See PHP info page
```

---

### Test 2: Multi-PHP Version Support

#### Deploy Multiple PHP Versions
```yaml
vhosts_list:
  - domain: "php74.test"
    username: "php74"
    php_version: "7.4"
    state: "present"
  
  - domain: "php82.test"
    username: "php82"
    php_version: "8.2"
    state: "present"
```

#### Test Steps
```bash
# 1. Add to /etc/hosts
echo "127.0.0.1 php74.test php82.test" >> /etc/hosts

# 2. Test PHP 7.4
curl http://php74.test/info.php | grep "PHP Version"
# Expected: PHP Version 7.4.x

# 3. Test PHP 8.2
curl http://php82.test/info.php | grep "PHP Version"
# Expected: PHP Version 8.2.x

# 4. Verify PHP-FPM sockets
ls -la /run/php-fpm/ | grep -E "(php74|php82)"
```

---

### Test 3: User Directory Isolation

#### Test User Permissions
```bash
# 1. Create test file as user
sudo -u testuser bash -c "echo 'Test Content' > /home/testuser/public_html/test.txt"

# 2. Test access
curl http://test.local/test.txt
# Expected: Test Content

# 3. Try accessing another user's directory
curl http://test.local/../php74/public_html/test.txt
# Expected: 403 Forbidden (security working)

# 4. Verify PHP open_basedir
curl http://test.local/info.php | grep open_basedir
# Expected: /home/testuser/public_html
```

---

### Test 4: VirtualHost Removal

#### Remove VirtualHost
```yaml
vhosts_list:
  - domain: "test.local"
    username: "testuser"
    php_version: "8.2"
    state: "absent"
    archive_on_remove: true
```

#### Test Steps
```bash
# 1. Deploy removal
ansible-playbook vhosts_deploy.yml

# 2. Verify configuration removed
ls -la /etc/httpd/sites-enabled/test.local.conf
# Expected: No such file

# 3. Verify backup created
ls -la /home/testuser/public_html_backup_*.tar.gz
# Expected: Backup file exists

# 4. Test HTTP (should fail)
curl http://test.local
# Expected: Connection refused or 404
```

---

### Test 5: SELinux Context

#### Verify SELinux Contexts
```bash
# 1. Check public_html context
ls -Z /home/testuser/public_html
# Expected: httpd_user_content_t

# 2. Check PHP-FPM socket context
ls -Z /run/php-fpm/testuser-php8.2-fpm.sock
# Expected: httpd_var_run_t

# 3. Test SELinux denials
ausearch -m avc -ts recent
# Expected: No denials related to httpd

# 4. Verify SELinux booleans
getsebool httpd_can_network_connect
# Expected: on
```

---

### Test 6: PHP-FPM Pool Configuration

#### Verify PHP-FPM Pools
```bash
# 1. Check pool configuration
cat /etc/php-fpm.d/testuser.conf

# 2. Verify pool is running
systemctl status php-fpm

# 3. Check PHP-FPM processes
ps aux | grep php-fpm | grep testuser

# 4. Verify socket connection
echo "<?php phpinfo(); ?>" > /home/testuser/public_html/test.php
curl http://test.local/test.php | grep "Server API"
# Expected: FPM/FastCGI
```

---

### Test 7: Apache Modules

#### Verify Required Modules
```bash
# 1. Check loaded modules
httpd -M | grep -E "(proxy|userdir|rewrite|fcgi)"

# Expected output:
#  proxy_module (shared)
#  proxy_fcgi_module (shared)
#  userdir_module (shared)
#  rewrite_module (shared)

# 2. Test mod_rewrite
echo "RewriteEngine On" > /home/testuser/public_html/.htaccess
curl http://test.local
# Expected: No errors
```

---

### Test 8: Performance Testing

#### Load Testing
```bash
# Install apache bench
yum install httpd-tools

# Run load test
ab -n 1000 -c 10 http://test.local/

# Expected: 
# - 0% failed requests
# - Reasonable requests per second
# - No timeout errors

# Monitor during test
watch -n 1 'ps aux | grep php-fpm | wc -l'
```

---

### Test 9: Log Files

#### Verify Logging
```bash
# 1. Check log files exist
ls -la /var/log/httpd/ | grep test.local

# 2. Generate traffic
curl http://test.local

# 3. Check access log
tail /var/log/httpd/test.local-access.log
# Expected: See access entries

# 4. Generate error
curl http://test.local/nonexistent.php

# 5. Check error log
tail /var/log/httpd/test.local-error.log
# Expected: See 404 error
```

---

### Test 10: Security Headers

#### Verify Security Headers
```bash
# 1. Check headers
curl -I http://test.local

# Expected headers:
#  X-Frame-Options: SAMEORIGIN
#  X-Content-Type-Options: nosniff
#  X-XSS-Protection: 1; mode=block
#  Referrer-Policy: strict-origin-when-cross-origin

# 2. Test with verbose curl
curl -v http://test.local 2>&1 | grep -i "x-frame"
```

---

## TROUBLESHOOTING CHECKLIST

### Issue: VirtualHost Not Responding

```bash
# 1. Check Apache configuration
httpd -t

# 2. Check VirtualHost enabled
ls -la /etc/httpd/sites-enabled/

# 3. Restart Apache
systemctl restart httpd

# 4. Check Apache status
systemctl status httpd

# 5. Check Apache error log
tail -f /var/log/httpd/error_log
```

### Issue: PHP Not Working

```bash
# 1. Check PHP-FPM status
systemctl status php-fpm

# 2. Check socket exists
ls -la /run/php-fpm/

# 3. Restart PHP-FPM
systemctl restart php-fpm

# 4. Check pool configuration
cat /etc/php-fpm.d/username.conf

# 5. Check PHP-FPM error log
journalctl -u php-fpm -n 50
```

### Issue: Permission Denied

```bash
# 1. Check directory permissions
ls -ld /home/username/public_html

# 2. Check file ownership
ls -la /home/username/public_html/

# 3. Fix permissions
chmod 755 /home/username/public_html
chown -R username:username /home/username/public_html

# 4. Check SELinux context
ls -Z /home/username/public_html

# 5. Restore SELinux context
restorecon -Rv /home/username/public_html
```

---

## AUTOMATED TEST SCRIPT

Create `test_vhosts.sh`:

```bash
#!/bin/bash

echo "=== VirtualHosts Testing Script ==="

# Test 1: Apache Configuration
echo "[1/5] Testing Apache configuration..."
if httpd -t; then
    echo "✅ Apache configuration valid"
else
    echo "❌ Apache configuration invalid"
    exit 1
fi

# Test 2: PHP-FPM Service
echo "[2/5] Testing PHP-FPM service..."
if systemctl is-active --quiet php-fpm; then
    echo "✅ PHP-FPM is running"
else
    echo "❌ PHP-FPM is not running"
    exit 1
fi

# Test 3: VirtualHost Files
echo "[3/5] Checking VirtualHost files..."
VHOST_COUNT=$(ls /etc/httpd/sites-enabled/*.conf 2>/dev/null | wc -l)
echo "✅ Found $VHOST_COUNT VirtualHost(s)"

# Test 4: PHP-FPM Sockets
echo "[4/5] Checking PHP-FPM sockets..."
SOCKET_COUNT=$(ls /run/php-fpm/*.sock 2>/dev/null | wc -l)
echo "✅ Found $SOCKET_COUNT PHP-FPM socket(s)"

# Test 5: HTTP Response
echo "[5/5] Testing HTTP responses..."
for conf in /etc/httpd/sites-enabled/*.conf; do
    DOMAIN=$(grep "ServerName" $conf | awk '{print $2}')
    if [ ! -z "$DOMAIN" ]; then
        HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://$DOMAIN 2>/dev/null)
        if [ "$HTTP_CODE" -eq 200 ]; then
            echo "✅ $DOMAIN responding (HTTP $HTTP_CODE)"
        else
            echo "⚠️  $DOMAIN not responding properly (HTTP $HTTP_CODE)"
        fi
    fi
done

echo ""
echo "=== Testing Complete ==="
```

Run with:
```bash
chmod +x test_vhosts.sh
./test_vhosts.sh
```

---

## MONITORING COMMANDS

```bash
# Real-time Apache access log
tail -f /var/log/httpd/*-access.log

# Real-time PHP-FPM errors
journalctl -u php-fpm -f

# PHP-FPM process count
watch -n 1 'ps aux | grep php-fpm | wc -l'

# Apache worker processes
watch -n 1 'ps aux | grep httpd | wc -l'

# Check all VirtualHosts
httpd -t -D DUMP_VHOSTS

# PHP-FPM status page (if configured)
curl http://localhost/fpm-status
```

---

## CLEANUP COMMANDS

```bash
# Remove test VirtualHosts
ansible-playbook vhosts_deploy.yml -e "state=absent"

# Remove test users
userdel -r testuser

# Remove test entries from /etc/hosts
sed -i '/test.local/d' /etc/hosts

# Clean logs
truncate -s 0 /var/log/httpd/*.log

# Restart services
systemctl restart httpd php-fpm
```

---

## SUCCESS CRITERIA

✅ All VirtualHosts responding on HTTP
✅ PHP version correct for each VirtualHost
✅ PHP-FPM sockets exist and working
✅ No SELinux denials
✅ Proper file permissions
✅ Apache configuration valid
✅ Logs being written correctly
✅ Security headers present

---

For additional help, refer to README_VHOSTS.md

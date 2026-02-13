.PHONY: help install check deploy test verify clean tags

# Default target
help:
	@echo "Ansible Web Server Stack - Makefile"
	@echo "===================================="
	@echo ""
	@echo "Available targets:"
	@echo "  install    - Install Ansible Galaxy requirements"
	@echo "  check      - Run playbook in check mode (dry-run)"
	@echo "  deploy     - Deploy the web server stack"
	@echo "  test       - Test connectivity to hosts"
	@echo "  verify     - Verify deployment"
	@echo "  tags       - Show available tags"
	@echo "  clean      - Clean temporary files"
	@echo ""
	@echo "Examples:"
	@echo "  make install              # Install dependencies"
	@echo "  make check                # Test without changes"
	@echo "  make deploy               # Full deployment"
	@echo "  make deploy TAGS=php      # Deploy only PHP role"
	@echo "  make deploy LIMIT=web1    # Deploy to specific host"

# Install Ansible Galaxy requirements
install:
	@echo "Installing Ansible Galaxy requirements..."
	ansible-galaxy collection install -r requirements.yml

# Test connectivity
test:
	@echo "Testing connectivity to webservers..."
	ansible webservers -m ping

# Run in check mode (dry-run)
check:
	@echo "Running playbook in check mode..."
	ansible-playbook site.yml --check --diff

# Deploy the stack
deploy:
ifdef TAGS
	@echo "Deploying with tags: $(TAGS)"
	ansible-playbook site.yml --tags "$(TAGS)"
else ifdef LIMIT
	@echo "Deploying to host: $(LIMIT)"
	ansible-playbook site.yml --limit "$(LIMIT)"
else
	@echo "Deploying full web server stack..."
	ansible-playbook site.yml
endif

# Verify deployment
verify:
	@echo "Verifying Apache..."
	ansible webservers -a "systemctl status httpd" --one-line
	@echo ""
	@echo "Verifying PHP..."
	ansible webservers -a "php -v" --one-line
	@echo ""
	@echo "Verifying Composer..."
	ansible webservers -a "composer --version" --one-line

# Show available tags
tags:
	@echo "Available tags:"
	@ansible-playbook site.yml --list-tags

# Clean temporary files
clean:
	@echo "Cleaning temporary files..."
	find . -name "*.retry" -delete
	find . -name "*.pyc" -delete
	find . -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null || true
	rm -f ansible.log
	@echo "Clean complete!"

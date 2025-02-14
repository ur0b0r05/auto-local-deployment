# Default values
SSH_PORT ?= 2222
DEPLOY_USER ?= deploy
REACT_NAME ?= XXX
SSH_KEY = ~/.ssh/react_deploy

.PHONY: setup deploy clean logs url debug-ssh

setup: ## Initial setup of the deployment environment
	@echo "Starting setup..."
	# Backup existing Docker config if it exists
	@if [ -f "$$HOME/.docker/config.json" ]; then \
		cp "$$HOME/.docker/config.json" "$$HOME/.docker/config.json.backup"; \
	fi

	# Create temporary Docker config for this setup
	@mkdir -p "$$HOME/.docker"
	@echo '{"credsStore":"","credHelpers":{}}' > "$$HOME/.docker/config.json"

	# Generate SSH key without prompt (overwrite if exists)
	@echo "Generating new SSH key..."
	@rm -f $(SSH_KEY) $(SSH_KEY).pub
	@ssh-keygen -t rsa -b 4096 -f $(SSH_KEY) -N "" -C "react-deploy"
	
	# Create .env if it doesn't exist
	@if [ ! -f .env ]; then \
		echo "Creating .env file..."; \
		echo "DOCKER_SSH_PORT=$(SSH_PORT)" > .env; \
		echo "DEPLOY_USER=$(DEPLOY_USER)" >> .env; \
		echo "REACT_APP_NAME=$(REACT_NAME)" >> .env; \
	fi
	
	# Start containers
	@docker-compose up -d --build
	
	# Restore original Docker config if backup exists
	@if [ -f "$$HOME/.docker/config.json.backup" ]; then \
		mv "$$HOME/.docker/config.json.backup" "$$HOME/.docker/config.json"; \
	fi
	
	# Wait for SSH to be ready
	@echo "Waiting for SSH service..."
	@for i in $$(seq 1 30); do \
		if command -v nc >/dev/null 2>&1; then \
			nc -z localhost $(SSH_PORT) >/dev/null 2>&1 && break; \
		else \
			(echo > /dev/tcp/localhost/$(SSH_PORT)) >/dev/null 2>&1 && break; \
		fi; \
		[ $$i -eq 30 ] && echo "Timeout waiting for SSH" && exit 1; \
		echo "Attempting to connect... ($$i/30)"; \
		sleep 1; \
	done
	
	# Configure SSH
	@echo "Configuring SSH..."
	@docker-compose exec -T frontend bash -c "mkdir -p /home/$(DEPLOY_USER)/.ssh && \
		touch /home/$(DEPLOY_USER)/.ssh/authorized_keys && \
		chmod 700 /home/$(DEPLOY_USER)/.ssh && \
		chmod 600 /home/$(DEPLOY_USER)/.ssh/authorized_keys && \
		chown -R $(DEPLOY_USER):$(DEPLOY_USER) /home/$(DEPLOY_USER)/.ssh && \
		chmod 755 /home/$(DEPLOY_USER)"
	
	# Add SSH key to container
	@echo "Installing SSH key..."
	@cat $(SSH_KEY).pub | docker-compose exec -T frontend bash -c "cat > /home/$(DEPLOY_USER)/.ssh/authorized_keys"
	
	# Test SSH connection
	@echo "Testing SSH connection..."
	@ssh -o StrictHostKeyChecking=no -i $(SSH_KEY) -p $(SSH_PORT) $(DEPLOY_USER)@localhost "echo SSH connection successful" || (echo "SSH connection failed"; exit 1)
	
	# Setup Git repository
	@echo "Setting up Git..."
	@if [ ! -d ".git" ]; then \
		echo "Initializing new Git repository..."; \
		git init; \
	fi
	
	@if [ -z "$$(git branch --show-current)" ] || [ -z "$$(git log -1 2>/dev/null)" ]; then \
		echo "Creating initial commit..."; \
		git checkout -b main 2>/dev/null || git checkout main 2>/dev/null || true; \
		git add .; \
		git commit -m "Initial commit" || true; \
	fi


	@echo "Initializing bare repository in container..."
	@docker-compose exec -T frontend bash -c "if [ ! -d /home/$(DEPLOY_USER)/app.git ]; then \
		git init --bare /home/$(DEPLOY_USER)/app.git && \
		chown -R $(DEPLOY_USER):$(DEPLOY_USER) /home/$(DEPLOY_USER)/app.git; \
	fi"

	# Setup Git remote
	@echo "Setting up Git remote..."
	@if git remote | grep -q "docker"; then \
		git remote remove docker; \
	fi
	@git remote add docker ssh://$(DEPLOY_USER)@localhost:$(SSH_PORT)/home/$(DEPLOY_USER)/app.git
	
	# Push code
	@echo "Pushing initial code..."
	@GIT_SSH_COMMAND="ssh -i $(SSH_KEY) -o StrictHostKeyChecking=no" git push -u docker main --force
	
	@echo "Setup complete!"
	@echo "Waiting for tunnel URL (this may take up to 30 seconds)..."
	@sleep 10
	@$(MAKE) url

debug-ssh: ## Debug SSH connection issues
	@echo "SSH Key Status:"
	@ls -l $(SSH_KEY)*
	@echo "\nTesting SSH Connection:"
	@ssh -v -i $(SSH_KEY) -p $(SSH_PORT) $(DEPLOY_USER)@localhost "ls -la /home/$(DEPLOY_USER)"
	@echo "\nContainer SSH Setup:"
	@docker-compose exec frontend ls -la /home/$(DEPLOY_USER)/.ssh
	@docker-compose exec frontend cat /home/$(DEPLOY_USER)/.ssh/authorized_keys

url: ## Get the tunnel URL
	@for i in $$(seq 1 30); do \
		URL=$$(docker-compose logs cloudflare-tunnel 2>&1 | grep -o 'https://.*[.]trycloudflare.com' | tail -n 1); \
		if [ ! -z "$$URL" ]; then \
			echo "Your application is available at: $$URL"; \
			break; \
		fi; \
		if [ $$i -eq 30 ]; then \
			echo "Timeout waiting for tunnel URL. You can run 'make url' to try again."; \
			break; \
		fi; \
		sleep 1; \
	done


deploy: ## Deploy the application
	@if [ ! -d ".git" ]; then \
		echo "Error: Not in a git repository"; \
		exit 1; \
	fi
	@if ! git remote | grep -q "docker"; then \
		echo "Error: Docker remote not found. Run 'make setup' first"; \
		exit 1; \
	fi

	@echo "Pushing code..."
	@GIT_SSH_COMMAND="ssh -i $(SSH_KEY) -o StrictHostKeyChecking=no" git push docker $$(git rev-parse --abbrev-ref HEAD):main
	@echo "Deployment complete!"
	@$(MAKE) url



clean: ## Remove all containers and volumes
	@docker-compose down -v
	@echo "Cleaned up all containers and volumes"

logs: ## View application logs
	@docker-compose logs -f

help: ## Display this help message
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

.DEFAULT_GOAL := help
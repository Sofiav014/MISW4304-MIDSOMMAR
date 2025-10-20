# Makefile for Blacklist Microservice
# Universidad de los Andes - MISW4304

.PHONY: help install test test-newman test-python start stop clean setup

# Configuration
PYTHON = python3
VENV = venv
API_DIR = api
COLLECTION_FILE = Blacklist_Microservice_With_Tests.postman_collection.json
REPORT_DIR = newman_reports

# Colors
GREEN = \033[0;32m
YELLOW = \033[1;33m
BLUE = \033[0;34m
RED = \033[0;31m
NC = \033[0m # No Color

help: ## Show this help message
	@echo "$(BLUE)Blacklist Microservice - Available Commands$(NC)"
	@echo "=============================================="
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "$(GREEN)%-20s$(NC) %s\n", $$1, $$2}'

setup: ## Set up the development environment
	@echo "$(BLUE)🚀 Setting up development environment...$(NC)"
	@$(PYTHON) -m venv $(VENV)
	@$(VENV)/bin/pip install --upgrade pip
	@$(VENV)/bin/pip install -r $(API_DIR)/requirements.txt
	@echo "$(GREEN)✅ Environment setup complete$(NC)"

install: ## Install dependencies
	@echo "$(BLUE)📦 Installing dependencies...$(NC)"
	@$(VENV)/bin/pip install -r $(API_DIR)/requirements.txt
	@echo "$(GREEN)✅ Dependencies installed$(NC)"

start: ## Start the Flask application
	@echo "$(BLUE)🚀 Starting Flask application...$(NC)"
	@cd $(API_DIR) && ../$(VENV)/bin/python src/app.py

start-background: ## Start the Flask application in background
	@echo "$(BLUE)🚀 Starting Flask application in background...$(NC)"
	@cd $(API_DIR) && nohup ../$(VENV)/bin/python src/app.py > ../app.log 2>&1 &
	@echo "$(GREEN)✅ Application started in background (PID: $$!)$(NC)"
	@echo "$(YELLOW)📝 Logs: app.log$(NC)"

stop: ## Stop the Flask application
	@echo "$(BLUE)🛑 Stopping Flask application...$(NC)"
	@pkill -f "python src/app.py" || true
	@echo "$(GREEN)✅ Application stopped$(NC)"

test: test-python ## Run all tests (Python tests by default)

test-python: ## Run Python-based tests
	@echo "$(BLUE)🧪 Running Python tests...$(NC)"
	@$(VENV)/bin/python run_tests.py

test-newman: ## Run Newman tests
	@echo "$(BLUE)🧪 Running Newman tests...$(NC)"
	@./run_newman_tests.sh

test-all: test-python test-newman ## Run both Python and Newman tests

test-quick: ## Run quick health check test
	@echo "$(BLUE)🔍 Running quick health check...$(NC)"
	@curl -s http://localhost:3000/blacklists/ping || echo "$(RED)❌ Server not running$(NC)"

clean: ## Clean up generated files
	@echo "$(BLUE)🧹 Cleaning up...$(NC)"
	@rm -rf $(REPORT_DIR)
	@rm -f app.log
	@rm -f *.pyc
	@rm -rf __pycache__
	@find . -name "*.pyc" -delete
	@find . -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null || true
	@echo "$(GREEN)✅ Cleanup complete$(NC)"

clean-all: clean ## Clean everything including virtual environment
	@echo "$(BLUE)🧹 Cleaning everything...$(NC)"
	@rm -rf $(VENV)
	@echo "$(GREEN)✅ Complete cleanup done$(NC)"

check-deps: ## Check if all dependencies are installed
	@echo "$(BLUE)🔍 Checking dependencies...$(NC)"
	@$(VENV)/bin/python -c "import flask, flask_sqlalchemy, flask_restful, flask_marshmallow, flask_jwt_extended; print('$(GREEN)✅ All dependencies installed$(NC)')" || echo "$(RED)❌ Missing dependencies$(NC)"

docker-build: ## Build Docker image
	@echo "$(BLUE)🐳 Building Docker image...$(NC)"
	@cd $(API_DIR) && docker build -t blacklist-microservice .
	@echo "$(GREEN)✅ Docker image built$(NC)"

docker-run: ## Run Docker container
	@echo "$(BLUE)🐳 Running Docker container...$(NC)"
	@cd $(API_DIR) && docker run -p 3000:3000 --env-file ../.env blacklist-microservice

deploy-package: ## Create deployment package for AWS Beanstalk
	@echo "$(BLUE)📦 Creating deployment package...$(NC)"
	@./create_deployment_package.sh

deploy-check: ## Check deployment package
	@echo "$(BLUE)🔍 Checking deployment package...$(NC)"
	@if [ -f "blacklist-microservice-deployment.zip" ]; then \
		echo "$(GREEN)✅ Deployment package exists$(NC)"; \
		ls -lh blacklist-microservice-deployment.zip; \
	else \
		echo "$(RED)❌ Deployment package not found$(NC)"; \
		echo "$(YELLOW)💡 Run 'make deploy-package' first$(NC)"; \
	fi

test-production: ## Test production deployment (requires URL as argument)
	@echo "$(BLUE)🧪 Testing production deployment...$(NC)"
	@if [ -z "$(URL)" ]; then \
		echo "$(RED)❌ Error: URL is required$(NC)"; \
		echo "$(YELLOW)💡 Usage: make test-production URL=https://your-app.elasticbeanstalk.com$(NC)"; \
	else \
		./test_production.sh $(URL); \
	fi

tutorial-help: ## Show tutorial steps
	@echo "$(BLUE)📋 AWS Beanstalk Tutorial Steps$(NC)"
	@echo "=================================="
	@echo "$(GREEN)1. Create IAM Role for EC2 Instance Profile$(NC)"
	@echo "$(GREEN)2. Create Elastic Beanstalk Application$(NC)"
	@echo "$(GREEN)3. Deploy Flask Application$(NC)"
	@echo ""
	@echo "$(YELLOW)📖 See TUTORIAL_STEPS.md for detailed instructions$(NC)"
	@echo "$(YELLOW)🔧 See ENVIRONMENT_VARIABLES.md for environment setup$(NC)"

lint: ## Run code linting
	@echo "$(BLUE)🔍 Running code linting...$(NC)"
	@$(VENV)/bin/flake8 $(API_DIR)/src/ || echo "$(YELLOW)⚠️  Linting issues found$(NC)"

format: ## Format code
	@echo "$(BLUE)🎨 Formatting code...$(NC)"
	@$(VENV)/bin/black $(API_DIR)/src/ || echo "$(YELLOW)⚠️  Black not installed$(NC)"

status: ## Show application status
	@echo "$(BLUE)📊 Application Status$(NC)"
	@echo "=================="
	@curl -s http://localhost:3000/blacklists/ping > /dev/null && echo "$(GREEN)✅ Server is running$(NC)" || echo "$(RED)❌ Server is not running$(NC)"
	@ps aux | grep "python src/app.py" | grep -v grep > /dev/null && echo "$(GREEN)✅ Process is running$(NC)" || echo "$(RED)❌ Process not found$(NC)"

logs: ## Show application logs
	@echo "$(BLUE)📝 Application logs:$(NC)"
	@tail -f app.log 2>/dev/null || echo "$(YELLOW)⚠️  No log file found$(NC)"

# Default target
.DEFAULT_GOAL := help

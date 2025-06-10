# Internet Public Library (IPL) Project Makefile
# Controls all aspects of the project workflow

# Configuration
RUBY_VERSION := 3.2.2
JEKYLL_ENV ?= development
PORT ?= 4000
HOST ?= 0.0.0.0
BASE_BRANCH ?= main
BRANCH_NAME ?= $(shell date +"%Y%m%d-%H%M%S")-changes

# Default target
.PHONY: default
default: help

# Help information
.PHONY: help
help:
	@echo "Internet Public Library (IPL) Project Makefile"
	@echo "=============================================="
	@echo ""
	@echo "Development:"
	@echo "  make setup         - Set up development environment"
	@echo "  make serve         - Run Jekyll server for development"
	@echo "  make build         - Build the site"
	@echo "  make clean         - Clean generated files"
	@echo ""
	@echo "Git Operations:"
	@echo "  make branch        - Create a new branch"
	@echo "  make commit        - Commit changes (MSG='commit message')"
	@echo "  make merge         - Merge current branch to $(BASE_BRANCH)"
	@echo "  make push          - Push changes to remote"
	@echo "  make pull          - Pull latest changes"
	@echo ""
	@echo "Submodule Operations:"
	@echo "  make update-subs   - Update all submodules"
	@echo "  make enus-commit     - Commit changes to 'en-US' submodule (MSG='commit message')"
	@echo "  make ptbr-commit   - Commit changes to 'pt-BR' submodule (MSG='commit message')"
	@echo ""
	@echo "Configuration:"
	@echo "  PORT=$(PORT) (override with PORT=8080 make serve)"
	@echo "  JEKYLL_ENV=$(JEKYLL_ENV) (override with JEKYLL_ENV=production make build)"
	@echo "  BRANCH_NAME - Auto-generated with timestamp unless specified"
	@echo ""

# Setup development environment
.PHONY: setup
setup:
	@echo "Setting up development environment..."
	@command -v rvm >/dev/null 2>&1 || { echo "RVM is not installed. Install from https://rvm.io"; exit 1; }
	@echo "Setting Ruby version to $(RUBY_VERSION)..."
	@rvm use $(RUBY_VERSION) || { echo "Ruby $(RUBY_VERSION) not found. Install using 'rvm install $(RUBY_VERSION)'"; exit 1; }
	@echo "Installing dependencies..."
	@bundle install
	@echo "Setup complete!"

# Jekyll operations
.PHONY: serve
serve: generate-pages
	@echo "Starting Jekyll server ($(JEKYLL_ENV))..."
	@rvm use $(RUBY_VERSION) do bundle exec jekyll serve --host=$(HOST) --port=$(PORT) --$(JEKYLL_ENV)

.PHONY: build
build: generate-pages
	@echo "Building site ($(JEKYLL_ENV))..."
	@rvm use $(RUBY_VERSION) do JEKYLL_ENV=$(JEKYLL_ENV) bundle exec jekyll build

.PHONY: clean
clean:
	@echo "Cleaning generated files..."
	@rvm use $(RUBY_VERSION) do bundle exec jekyll clean
	@rm -rf .sass-cache
	@rm -rf _site
	@find en-US -name "index.html" -type f -delete
	@find pt-BR -name "index.html" -type f -delete
	@echo "Cleaned!"

# Git operations
.PHONY: branch
branch:
	@echo "Creating new branch: $(BRANCH_NAME)"
	@git checkout -b $(BRANCH_NAME)
	@echo "Switched to branch '$(BRANCH_NAME)'"

.PHONY: commit
commit:
	@if [ -z "$(MSG)" ]; then \
		echo "Error: Commit message is required. Use MSG='your message'"; \
		exit 1; \
	fi
	@echo "Committing changes with message: $(MSG)"
	@git add .
	@git commit -m "$(MSG)"
	@echo "Changes committed!"

.PHONY: merge
merge:
	@echo "Merging current branch to $(BASE_BRANCH)..."
	@CURRENT_BRANCH=$$(git rev-parse --abbrev-ref HEAD) && \
	git checkout $(BASE_BRANCH) && \
	git pull && \
	git merge $$CURRENT_BRANCH && \
	echo "Merged $$CURRENT_BRANCH into $(BASE_BRANCH)"

.PHONY: push
push:
	@echo "Pushing changes to remote..."
	@CURRENT_BRANCH=$$(git rev-parse --abbrev-ref HEAD) && \
	git push origin $$CURRENT_BRANCH
	@echo "Changes pushed!"

.PHONY: pull
pull:
	@echo "Pulling latest changes..."
	@git pull
	@echo "Latest changes pulled!"

# Submodule operations
.PHONY: update-subs
update-subs:
	@echo "Updating all submodules..."
	@git submodule update --init --recursive
	@git submodule foreach git pull origin main
	@echo "Submodules updated!"

.PHONY: enus-commit
enus-commit:
	@if [ -z "$(MSG)" ]; then \
		echo "Error: Commit message is required. Use MSG='your message'"; \
		exit 1; \
	fi
	@echo "Committing changes to 'en-US' submodule..."
	@cd en-US && \
	git add . && \
	git commit -m "$(MSG)" && \
	if git symbolic-ref -q HEAD >/dev/null; then \
		BRANCH=$$(git symbolic-ref --short HEAD) && \
		git push origin $$BRANCH; \
	else \
		echo "Detached HEAD state detected. Checking out main branch..." && \
		git checkout main 2>/dev/null || git checkout master 2>/dev/null || git checkout -b main && \
		git push origin HEAD; \
	fi
	@echo "Changes committed and pushed to 'en-US' submodule"
	@git add en-US
	@git commit -m "Update 'en-US' submodule: $(MSG)"
	@echo "Main repository updated with submodule changes"

.PHONY: ptbr-commit
ptbr-commit:
	@if [ -z "$(MSG)" ]; then \
		echo "Error: Commit message is required. Use MSG='your message'"; \
		exit 1; \
	fi
	@echo "Committing changes to 'pt-BR' submodule..."
	@cd pt-BR && \
	git add . && \
	git commit -m "$(MSG)" && \
	if git symbolic-ref -q HEAD >/dev/null; then \
		BRANCH=$$(git symbolic-ref --short HEAD) && \
		git push origin $$BRANCH; \
	else \
		echo "Detached HEAD state detected. Checking out main branch..." && \
		git checkout main 2>/dev/null || git checkout master 2>/dev/null || git checkout -b main && \
		git push origin HEAD; \
	fi
	@echo "Changes committed and pushed to 'pt-BR' submodule"
	@git add pt-BR
	@git commit -m "Update 'pt-BR' submodule: $(MSG)"
	@echo "Main repository updated with submodule changes"

# Production-specific targets
.PHONY: deploy
deploy: 
	@echo "Deploying to production..."
	@$(MAKE) JEKYLL_ENV=production build
	@echo "Site built for production!"
	# Add deployment commands here (rsync, AWS S3, etc.)
	@echo "Deployed!"

# Utilities
.PHONY: check-status
check-status:
	@echo "Checking Git status..."
	@git status
	@echo "Checking submodule status..."
	@git submodule status

# Generate sitemap
.PHONY: sitemap
sitemap: build
	@echo "Generating sitemap..."
	@rvm use $(RUBY_VERSION) do bundle exec jekyll sitemap
	@echo "Sitemap generated!"

# Full site check (build, test links, etc.)
.PHONY: check-site
check-site: build
	@echo "Running site checks..."
	@rvm use $(RUBY_VERSION) do bundle exec htmlproofer ./_site --disable-external
	@echo "Site checks completed!"

# Add a rule to run the generate_pages.rb script before building
generate-pages:
	@echo "Generating pages from menu data..."
	@mkdir -p scripts
	@ruby scripts/generate_pages.rb 
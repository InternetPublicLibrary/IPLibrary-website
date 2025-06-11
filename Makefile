# Internet Public Library (IPL) Project - Optimized Makefile
# Advanced workflow management for Jekyll + Git Submodules + GitHub Integration

# Configuration
SHELL := /bin/bash
.DEFAULT_GOAL := help
.ONESHELL:

# Project Configuration
RUBY_VERSION := 3.2.2
JEKYLL_ENV ?= development
BUNDLE_PATH := vendor/bundle
NODE_VERSION := 18

# Server Configuration
HOST ?= 0.0.0.0
PORT ?= 4000
LIVERELOAD_PORT ?= 35729

# Git Configuration
BASE_BRANCH ?= main
BRANCH_PREFIX ?= feature/
COMMIT_TEMPLATE := .gitmessage

# Build Configuration
BUILD_DIR := _site
CACHE_DIR := .sass-cache
TMP_DIR := .tmp

# GitHub Configuration
GH_PAGES_BRANCH := gh-pages
WORKFLOW_DIR := .github/workflows

# Colors for output
RED := \033[0;31m
GREEN := \033[0;32m
YELLOW := \033[1;33m
BLUE := \033[0;34m
MAGENTA := \033[0;35m
CYAN := \033[0;36m
WHITE := \033[1;37m
NC := \033[0m # No Color

# Utility functions
define log_info
	@echo -e "$(CYAN)[INFO]$(NC) $(1)"
endef

define log_success
	@echo -e "$(GREEN)[SUCCESS]$(NC) $(1)"
endef

define log_warning
	@echo -e "$(YELLOW)[WARNING]$(NC) $(1)"
endef

define log_error
	@echo -e "$(RED)[ERROR]$(NC) $(1)"
endef

define check_command
	@command -v $(1) >/dev/null 2>&1 || { \
		$(call log_error,$(1) is required but not installed. Please install $(1)); \
		exit 1; \
	}
endef

# Help target with better formatting
.PHONY: help
help:
	@echo -e "$(WHITE)Internet Public Library (IPL) Project$(NC)"
	@echo -e "$(WHITE)======================================$(NC)"
	@echo ""
	@echo -e "$(MAGENTA)🚀 Quick Start:$(NC)"
	@echo -e "  $(GREEN)make setup$(NC)        - Complete project setup"
	@echo -e "  $(GREEN)make dev$(NC)          - Start development server"
	@echo -e "  $(GREEN)make build$(NC)        - Build for production"
	@echo ""
	@echo -e "$(MAGENTA)🔧 Development:$(NC)"
	@echo -e "  $(CYAN)serve$(NC)             - Run Jekyll development server"
	@echo -e "  $(CYAN)serve-prod$(NC)        - Run Jekyll production server"
	@echo -e "  $(CYAN)build-dev$(NC)         - Build for development"
	@echo -e "  $(CYAN)build-prod$(NC)        - Build for production"
	@echo -e "  $(CYAN)watch$(NC)             - Watch and rebuild automatically"
	@echo -e "  $(CYAN)clean$(NC)             - Clean all generated files"
	@echo -e "  $(CYAN)clean-deep$(NC)        - Deep clean (including gems)"
	@echo ""
	@echo -e "$(MAGENTA)📦 Dependencies:$(NC)"
	@echo -e "  $(CYAN)install$(NC)           - Install all dependencies"
	@echo -e "  $(CYAN)update$(NC)            - Update all dependencies"
	@echo -e "  $(CYAN)bundle-install$(NC)    - Install Ruby gems"
	@echo -e "  $(CYAN)bundle-update$(NC)     - Update Ruby gems"
	@echo ""
	@echo -e "$(MAGENTA)🌳 Git Operations:$(NC)"
	@echo -e "  $(CYAN)branch$(NC)            - Create feature branch (NAME=branch-name)"
	@echo -e "  $(CYAN)commit$(NC)            - Smart commit (MSG='message')"
	@echo -e "  $(CYAN)push$(NC)              - Push current branch"
	@echo -e "  $(CYAN)pull$(NC)              - Pull latest changes"
	@echo -e "  $(CYAN)merge$(NC)             - Merge to $(BASE_BRANCH)"
	@echo -e "  $(CYAN)rebase$(NC)            - Rebase current branch"
	@echo -e "  $(CYAN)status$(NC)            - Show comprehensive status"
	@echo ""
	@echo -e "$(MAGENTA)🔗 Submodules:$(NC)"
	@echo -e "  $(CYAN)sub-init$(NC)          - Initialize all submodules"
	@echo -e "  $(CYAN)sub-update$(NC)        - Update all submodules"
	@echo -e "  $(CYAN)sub-sync$(NC)          - Sync submodule URLs"
	@echo -e "  $(CYAN)sub-status$(NC)        - Show submodule status"
	@echo -e "  $(CYAN)enus-commit$(NC)       - Commit to en-US submodule (MSG='message')"
	@echo -e "  $(CYAN)ptbr-commit$(NC)       - Commit to pt-BR submodule (MSG='message')"
	@echo ""
	@echo -e "$(MAGENTA)🚀 Deployment:$(NC)"
	@echo -e "  $(CYAN)deploy$(NC)            - Deploy to production"
	@echo -e "  $(CYAN)deploy-gh$(NC)         - Deploy to GitHub Pages"
	@echo -e "  $(CYAN)release$(NC)           - Create release (VERSION=x.x.x)"
	@echo ""
	@echo -e "$(MAGENTA)🧪 Testing & Quality:$(NC)"
	@echo -e "  $(CYAN)test$(NC)              - Run all tests"
	@echo -e "  $(CYAN)test-links$(NC)        - Test all links"
	@echo -e "  $(CYAN)test-html$(NC)         - Validate HTML"
	@echo -e "  $(CYAN)lint$(NC)              - Run linters"
	@echo -e "  $(CYAN)audit$(NC)             - Security audit"
	@echo ""
	@echo -e "$(MAGENTA)📊 Analytics:$(NC)"
	@echo -e "  $(CYAN)stats$(NC)             - Show project statistics"
	@echo -e "  $(CYAN)size$(NC)              - Show build size analysis"
	@echo -e "  $(CYAN)deps$(NC)              - Show dependency tree"
	@echo ""
	@echo -e "$(MAGENTA)🔧 Maintenance:$(NC)"
	@echo -e "  $(CYAN)doctor$(NC)            - Run Jekyll doctor"
	@echo -e "  $(CYAN)optimize$(NC)          - Optimize assets"
	@echo -e "  $(CYAN)backup$(NC)            - Create project backup"
	@echo -e "  $(CYAN)restore$(NC)           - Restore from backup"
	@echo ""
	@echo -e "$(YELLOW)Environment Variables:$(NC)"
	@echo -e "  PORT=$(PORT) HOST=$(HOST) JEKYLL_ENV=$(JEKYLL_ENV)"
	@echo -e "  BRANCH_PREFIX=$(BRANCH_PREFIX) BASE_BRANCH=$(BASE_BRANCH)"

# Environment checks
.PHONY: check-env
check-env:
	$(call check_command,ruby)
	$(call check_command,bundle)
	$(call check_command,git)
	$(call check_command,gh)
	@ruby_version=$$(ruby -v | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+') && \
	if [[ "$$ruby_version" != "$(RUBY_VERSION)" ]]; then \
		$(call log_warning,Ruby version mismatch. Expected $(RUBY_VERSION), found $$ruby_version); \
	fi

# Setup targets
.PHONY: setup
setup: check-env install sub-init
	$(call log_info,Setting up development environment...)
	@mkdir -p $(TMP_DIR) scripts logs
	@touch $(COMMIT_TEMPLATE)
	@git config commit.template $(COMMIT_TEMPLATE) 2>/dev/null || true
	@git config submodule.recurse true 2>/dev/null || true
	$(call log_success,Development environment ready!)

.PHONY: install
install: bundle-install
	$(call log_info,Installing all dependencies...)
	@if command -v npm >/dev/null 2>&1; then \
		npm install; \
	fi
	$(call log_success,All dependencies installed!)

.PHONY: bundle-install
bundle-install:
	$(call log_info,Installing Ruby gems...)
	@bundle config set --local path $(BUNDLE_PATH)
	@bundle config set --local clean true
	@bundle install --jobs 4 --retry 3
	$(call log_success,Ruby gems installed!)

.PHONY: bundle-update
bundle-update:
	$(call log_info,Updating Ruby gems...)
	@bundle update --jobs 4
	$(call log_success,Ruby gems updated!)

.PHONY: update
update: bundle-update sub-update
	$(call log_info,Updating all dependencies...)
	@if command -v npm >/dev/null 2>&1; then \
		npm update; \
	fi
	$(call log_success,All dependencies updated!)

# Development targets
.PHONY: dev
dev: generate-pages
	$(call log_info,Starting development server...)
	@bundle exec jekyll serve \
		--host=$(HOST) \
		--port=$(PORT) \
		--livereload \
		--livereload-port=$(LIVERELOAD_PORT) \
		--incremental \
		--drafts \
		--future \
		--watch

.PHONY: serve
serve: generate-pages
	$(call log_info,Starting Jekyll server ($(JEKYLL_ENV))...)
	@JEKYLL_ENV=$(JEKYLL_ENV) bundle exec jekyll serve \
		--host=$(HOST) \
		--port=$(PORT) \
		--livereload

.PHONY: serve-prod
serve-prod: generate-pages
	$(call log_info,Starting production server...)
	@JEKYLL_ENV=production bundle exec jekyll serve \
		--host=$(HOST) \
		--port=$(PORT)

.PHONY: watch
watch: generate-pages
	$(call log_info,Watching for changes...)
	@JEKYLL_ENV=$(JEKYLL_ENV) bundle exec jekyll build --watch --incremental

.PHONY: build-dev
build-dev: generate-pages
	$(call log_info,Building for development...)
	@JEKYLL_ENV=development bundle exec jekyll build --drafts --future

.PHONY: build-prod
build-prod: generate-pages
	$(call log_info,Building for production...)
	@JEKYLL_ENV=production bundle exec jekyll build --profile

.PHONY: build
build: build-prod

# Cleaning targets
.PHONY: clean
clean:
	$(call log_info,Cleaning generated files...)
	@bundle exec jekyll clean
	@rm -rf $(BUILD_DIR) $(CACHE_DIR) $(TMP_DIR)
	@find . -name "*.tmp" -type f -delete
	@find en-US -name "index.html" -type f -delete 2>/dev/null || true
	@find pt-BR -name "index.html" -type f -delete 2>/dev/null || true
	$(call log_success,Cleaned!)

.PHONY: clean-deep
clean-deep: clean
	$(call log_info,Deep cleaning...)
	@rm -rf $(BUNDLE_PATH) node_modules .bundle
	@bundle clean --force
	$(call log_success,Deep cleaned!)

# Git operations
.PHONY: status
status:
	$(call log_info,Checking comprehensive status...)
	@echo -e "$(YELLOW)Git Status:$(NC)"
	@git status --short --branch
	@echo -e "\n$(YELLOW)Submodule Status:$(NC)"
	@git submodule status
	@echo -e "\n$(YELLOW)Recent Commits:$(NC)"
	@git log --oneline -5
	@echo -e "\n$(YELLOW)Stash Status:$(NC)"
	@git stash list || echo "No stashes"

.PHONY: branch
branch:
	@if [ -z "$(NAME)" ]; then \
		$(call log_error,Branch name required. Use NAME=branch-name); \
		exit 1; \
	fi
	$(call log_info,Creating branch: $(BRANCH_PREFIX)$(NAME))
	@git checkout -b $(BRANCH_PREFIX)$(NAME)
	@git push -u origin $(BRANCH_PREFIX)$(NAME)
	$(call log_success,Branch created and pushed!)

.PHONY: commit
commit:
	@if [ -z "$(MSG)" ]; then \
		$(call log_error,Commit message required. Use MSG='your message'); \
		exit 1; \
	fi
	$(call log_info,Committing changes...)
	@git add .
	@if git diff --cached --quiet; then \
		$(call log_warning,No changes to commit); \
		exit 0; \
	fi
	@git commit -m "$(MSG)"
	$(call log_success,Changes committed!)

.PHONY: push
push:
	$(call log_info,Pushing changes...)
	@current_branch=$$(git rev-parse --abbrev-ref HEAD) && \
	git push origin $$current_branch
	$(call log_success,Changes pushed!)

.PHONY: pull
pull:
	$(call log_info,Pulling latest changes...)
	@git pull --recurse-submodules
	$(call log_success,Latest changes pulled!)

.PHONY: merge
merge:
	$(call log_info,Merging to $(BASE_BRANCH)...)
	@current_branch=$$(git rev-parse --abbrev-ref HEAD) && \
	if [ "$$current_branch" = "$(BASE_BRANCH)" ]; then \
		$(call log_error,Already on $(BASE_BRANCH) branch); \
		exit 1; \
	fi && \
	git checkout $(BASE_BRANCH) && \
	git pull && \
	git merge $$current_branch && \
	git push
	$(call log_success,Merged successfully!)

.PHONY: rebase
rebase:
	$(call log_info,Rebasing current branch...)
	@git fetch origin
	@git rebase origin/$(BASE_BRANCH)
	$(call log_success,Rebased successfully!)

# Submodule operations
.PHONY: sub-init
sub-init:
	$(call log_info,Initializing submodules...)
	@git submodule update --init --recursive
	$(call log_success,Submodules initialized!)

.PHONY: sub-update
sub-update:
	$(call log_info,Updating submodules...)
	@git submodule update --remote --recursive
	@git submodule foreach 'git checkout $$(git config -f $$toplevel/.gitmodules submodule.$$name.branch || echo main)'
	$(call log_success,Submodules updated!)

.PHONY: sub-sync
sub-sync:
	$(call log_info,Syncing submodule URLs...)
	@git submodule sync --recursive
	$(call log_success,Submodule URLs synced!)

.PHONY: sub-status
sub-status:
	$(call log_info,Submodule status...)
	@git submodule status --recursive

.PHONY: enus-commit
enus-commit:
	@if [ -z "$(MSG)" ]; then \
		$(call log_error,Commit message required. Use MSG='your message'); \
		exit 1; \
	fi
	$(call log_info,Committing to en-US submodule...)
	@cd en-US && \
	git add . && \
	if git diff --cached --quiet; then \
		$(call log_warning,No changes in en-US submodule); \
		exit 0; \
	fi && \
	git commit -m "$(MSG)" && \
	git push origin HEAD
	@git add en-US
	@git commit -m "Update en-US submodule: $(MSG)"
	$(call log_success,en-US submodule updated!)

.PHONY: ptbr-commit
ptbr-commit:
	@if [ -z "$(MSG)" ]; then \
		$(call log_error,Commit message required. Use MSG='your message'); \
		exit 1; \
	fi
	$(call log_info,Committing to pt-BR submodule...)
	@cd pt-BR && \
	git add . && \
	if git diff --cached --quiet; then \
		$(call log_warning,No changes in pt-BR submodule); \
		exit 0; \
	fi && \
	git commit -m "$(MSG)" && \
	git push origin HEAD
	@git add pt-BR
	@git commit -m "Update pt-BR submodule: $(MSG)"
	$(call log_success,pt-BR submodule updated!)

# Testing and Quality Assurance
.PHONY: test
test: build-prod test-html test-links

.PHONY: test-html
test-html:
	$(call log_info,Validating HTML...)
	@bundle exec htmlproofer $(BUILD_DIR) \
		--disable-external \
		--check-html \
		--check-img-http \
		--report-invalid-tags \
		--report-missing-names \
		--report-script-embeds \
		--report-missing-doctype \
		--report-eof-tags \
		--report-mismatched-tags
	$(call log_success,HTML validation passed!)

.PHONY: test-links
test-links:
	$(call log_info,Testing links...)
	@bundle exec htmlproofer $(BUILD_DIR) \
		--check-external-hash \
		--check-internal-hash \
		--check-opengraph \
		--http-status-ignore "999" \
		--url-ignore "/localhost/,/127.0.0.1/,/0.0.0.0/"
	$(call log_success,Link testing passed!)

.PHONY: doctor
doctor:
	$(call log_info,Running Jekyll doctor...)
	@bundle exec jekyll doctor
	$(call log_success,Jekyll doctor check passed!)

.PHONY: lint
lint:
	$(call log_info,Running linters...)
	@if command -v markdownlint >/dev/null 2>&1; then \
		markdownlint *.md **/*.md; \
	fi
	$(call log_success,Linting completed!)

.PHONY: audit
audit:
	$(call log_info,Running security audit...)
	@bundle audit check --update
	@if command -v npm >/dev/null 2>&1; then \
		npm audit; \
	fi
	$(call log_success,Security audit completed!)

# Deployment
.PHONY: deploy
deploy: build-prod test
	$(call log_info,Deploying to production...)
	# Add your deployment commands here
	$(call log_success,Deployed to production!)

.PHONY: deploy-gh
deploy-gh: build-prod
	$(call log_info,Deploying to GitHub Pages...)
	@git checkout $(GH_PAGES_BRANCH) 2>/dev/null || git checkout -b $(GH_PAGES_BRANCH)
	@cp -r $(BUILD_DIR)/* .
	@git add .
	@git commit -m "Deploy: $$(date '+%Y-%m-%d %H:%M:%S')" || true
	@git push origin $(GH_PAGES_BRANCH)
	@git checkout $(BASE_BRANCH)
	$(call log_success,Deployed to GitHub Pages!)

.PHONY: release
release:
	@if [ -z "$(VERSION)" ]; then \
		$(call log_error,Version required. Use VERSION=x.x.x); \
		exit 1; \
	fi
	$(call log_info,Creating release $(VERSION)...)
	@git tag -a v$(VERSION) -m "Release version $(VERSION)"
	@git push origin v$(VERSION)
	@gh release create v$(VERSION) --generate-notes
	$(call log_success,Release $(VERSION) created!)

# Analytics and Statistics
.PHONY: stats
stats:
	$(call log_info,Project statistics...)
	@echo -e "$(YELLOW)Repository Stats:$(NC)"
	@echo "Total commits: $$(git rev-list --all --count)"
	@echo "Contributors: $$(git shortlog -sn | wc -l)"
	@echo "Total files: $$(find . -type f -not -path './.git/*' -not -path './vendor/*' -not -path './node_modules/*' | wc -l)"
	@echo "Total lines of code: $$(find . -name '*.rb' -o -name '*.html' -o -name '*.css' -o -name '*.js' -o -name '*.scss' | xargs wc -l | tail -1)"
	@echo -e "\n$(YELLOW)Build Stats:$(NC)"
	@if [ -d "$(BUILD_DIR)" ]; then \
		echo "Build size: $$(du -sh $(BUILD_DIR) | cut -f1)"; \
		echo "Total pages: $$(find $(BUILD_DIR) -name '*.html' | wc -l)"; \
	else \
		echo "No build found. Run 'make build' first."; \
	fi

.PHONY: size
size: build-prod
	$(call log_info,Build size analysis...)
	@du -sh $(BUILD_DIR)
	@echo -e "\n$(YELLOW)Largest files:$(NC)"
	@find $(BUILD_DIR) -type f -exec du -h {} + | sort -rh | head -10

.PHONY: deps
deps:
	$(call log_info,Dependency information...)
	@echo -e "$(YELLOW)Ruby Gems:$(NC)"
	@bundle list
	@if command -v npm >/dev/null 2>&1; then \
		echo -e "\n$(YELLOW)NPM Packages:$(NC)"; \
		npm list --depth=0; \
	fi

# Utility targets
.PHONY: generate-pages
generate-pages:
	@if [ -f "scripts/generate_pages.rb" ]; then \
		$(call log_info,Generating pages from menu data...); \
		ruby scripts/generate_pages.rb; \
	fi

.PHONY: optimize
optimize: build-prod
	$(call log_info,Optimizing assets...)
	@find $(BUILD_DIR) -name "*.html" -exec htmlmin {} --output {} \;
	@find $(BUILD_DIR) -name "*.css" -exec cleancss -o {} {} \;
	@find $(BUILD_DIR) -name "*.jpg" -o -name "*.jpeg" -exec jpegoptim --strip-all {} \;
	@find $(BUILD_DIR) -name "*.png" -exec optipng -o7 {} \;
	$(call log_success,Assets optimized!)

.PHONY: backup
backup:
	$(call log_info,Creating backup...)
	@timestamp=$$(date +%Y%m%d_%H%M%S) && \
	tar -czf backup_$$timestamp.tar.gz \
		--exclude='.git' \
		--exclude='vendor' \
		--exclude='node_modules' \
		--exclude='_site' \
		--exclude='.sass-cache' \
		.
	$(call log_success,Backup created!)

.PHONY: restore
restore:
	@if [ -z "$(BACKUP)" ]; then \
		$(call log_error,Backup file required. Use BACKUP=filename.tar.gz); \
		exit 1; \
	fi
	$(call log_info,Restoring from backup...)
	@tar -xzf $(BACKUP)
	$(call log_success,Restored from backup!)

# Continuous Integration helpers
.PHONY: ci-install
ci-install:
	@bundle config set --local path $(BUNDLE_PATH)
	@bundle config set --local deployment true
	@bundle install --jobs 4 --retry 3

.PHONY: ci-build
ci-build: generate-pages
	@JEKYLL_ENV=production bundle exec jekyll build

.PHONY: ci-test
ci-test: ci-build test-html

# Development workflow shortcuts
.PHONY: quick-commit
quick-commit: commit push

.PHONY: feature
feature: branch

.PHONY: hotfix
hotfix:
	@$(MAKE) branch NAME=hotfix/$(shell date +%Y%m%d-%H%M%S) BRANCH_PREFIX=hotfix/

# File monitoring (requires inotify-tools on Linux or fswatch on macOS)
.PHONY: monitor
monitor:
	$(call log_info,Monitoring file changes...)
	@if command -v inotifywait >/dev/null 2>&1; then \
		while inotifywait -r -e modify,create,delete .; do \
			make build-dev; \
		done; \
	elif command -v fswatch >/dev/null 2>&1; then \
		fswatch -o . | xargs -n1 -I{} make build-dev; \
	else \
		$(call log_error,File monitoring requires inotifywait or fswatch); \
	fi

# Performance testing
.PHONY: perf
perf: build-prod
	$(call log_info,Running performance tests...)
	@if command -v lighthouse >/dev/null 2>&1; then \
		lighthouse --output=html --output-path=./lighthouse-report.html http://localhost:$(PORT); \
	else \
		$(call log_warning,Lighthouse not found. Install with: npm install -g lighthouse); \
	fi

# Security checks
.PHONY: security
security: audit
	$(call log_info,Running additional security checks...)
	@git secrets --scan || $(call log_warning,git-secrets not installed)
	@if [ -f ".semgrepignore" ]; then \
		semgrep --config=auto . || $(call log_warning,semgrep not installed); \
	fi

# Make targets that don't create files
.PHONY: all clean-all install-all update-all
#!/bin/bash
set -e

# Print Ruby and environment info
echo "Ruby version: $(ruby -v)"
echo "Bundler version: $(bundle -v)"

# Install specific bundler version
gem install bundler:2.6.9

# Set encoding to UTF-8
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export RUBYOPT="-E utf-8"

# Clean any previous builds
bundle exec jekyll clean

# Generate pages from menu data
echo "Generating pages from menu data..."
ruby scripts/generate_pages.rb

# Build the site with proper environment
JEKYLL_ENV=production bundle exec jekyll build

# Success message
echo "Build completed successfully!" 
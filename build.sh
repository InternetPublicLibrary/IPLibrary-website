#!/bin/bash
set -e

echo "Starting IPLibrary website build process..."

# Check for Ruby and required gems
command -v ruby >/dev/null 2>&1 || { echo "Ruby is required but not installed. Aborting."; exit 1; }
command -v bundle >/dev/null 2>&1 || { echo "Bundler is required but not installed. Aborting."; exit 1; }

# Install dependencies if needed
echo "Installing dependencies..."
bundle install

# Clean any previous build artifacts
echo "Cleaning previous build..."
bundle exec jekyll clean

# Build the Jekyll site with our custom plugins
echo "Building Jekyll site with plugins for page generation..."
JEKYLL_ENV=production bundle exec jekyll build

echo "Build completed successfully!"
echo "The site is available in the _site directory." 

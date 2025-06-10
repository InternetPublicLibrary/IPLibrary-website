#!/usr/bin/env ruby
require 'yaml'
require 'fileutils'

# Script to generate dynamic pages from menu.yaml
# Run this before building Jekyll: ruby scripts/generate_pages.rb

puts "Starting page generation script..."

# Define root directory
ROOT_DIR = File.expand_path('..', __dir__)

# Load the menu data from YAML files
def load_menu_data(lang)
  menu_file = File.join(ROOT_DIR, '_data', lang, 'menu.yaml')
  if File.exist?(menu_file)
    YAML.load_file(menu_file)
  else
    puts "Warning: Menu file not found for language #{lang}"
    []
  end
end

# Helper to ensure directory exists
def ensure_directory_exists(dir)
  FileUtils.mkdir_p(dir) unless Dir.exist?(dir)
end

# Load template content
def load_template(template_name)
  template_path = File.join(ROOT_DIR, '_includes', 'templates', "#{template_name}.md")
  if File.exist?(template_path)
    File.read(template_path)
  else
    puts "Warning: Template file #{template_name}.md not found"
    ""
  end
end

# Generate a page with frontmatter and content
def generate_page(path, frontmatter, content)
  # Normalize path to create index.html if needed
  if path.end_with?('/')
    dir = path
    filename = 'index.html'
  else
    dir = File.dirname(path)
    filename = File.basename(path)
    dir = dir == '.' ? '' : dir
  end
  
  # Remove leading slash if present
  dir = dir.sub(/^\//, '')
  
  # Ensure directory exists
  full_dir = File.join(ROOT_DIR, dir)
  ensure_directory_exists(full_dir)
  
  # Create the file
  full_path = File.join(full_dir, filename)
  
  # Convert frontmatter to YAML
  frontmatter_yaml = frontmatter.to_yaml
  
  # Write the file with frontmatter and content
  File.open(full_path, 'w') do |file|
    file.puts "---"
    file.puts frontmatter_yaml.sub(/---\n/, '')
    file.puts "---"
    file.puts
    file.puts content
  end
  
  puts "Generated page: #{full_path}"
end

# Process a language
def process_language(lang)
  puts "Processing language: #{lang}"
  menu_data = load_menu_data(lang)
  
  # Load templates
  category_template = load_template('category-content')
  subcategory_template = load_template('subcategory-content')
  section_template = load_template('section-content')
  
  # Process categories
  menu_data.each do |category|
    # Generate category page
    frontmatter = {
      'layout' => 'category',
      'title' => category['title'],
      'lang' => lang,
      'description' => "Explore resources related to #{category['title']}",
      'last_updated' => Time.now.strftime("%Y-%m-%d")
    }
    generate_page(category['path'], frontmatter, category_template)
    
    # Process subcategories
    if category['children']
      category['children'].each do |subcategory|
        # Generate subcategory page
        frontmatter = {
          'layout' => 'subcategory',
          'title' => subcategory['title'],
          'lang' => lang,
          'parent_category' => category['title'],
          'description' => "Resources on #{subcategory['title']} within #{category['title']}",
          'last_updated' => Time.now.strftime("%Y-%m-%d")
        }
        generate_page(subcategory['path'], frontmatter, subcategory_template)
        
        # Process sections
        if subcategory['children']
          subcategory['children'].each do |section|
            # Generate section page
            frontmatter = {
              'layout' => 'section',
              'title' => section['title'],
              'lang' => lang,
              'parent_category' => category['title'],
              'parent_subcategory' => subcategory['title'],
              'description' => "Specialized resources on #{section['title']} in #{subcategory['title']}",
              'last_updated' => Time.now.strftime("%Y-%m-%d"),
              'resources' => []
            }
            generate_page(section['path'], frontmatter, section_template)
          end
        end
      end
    end
  end
end

# Process both languages
process_language('en-US')
process_language('pt-BR')

puts "Page generation completed!" 
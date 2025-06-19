require 'yaml'
require 'fileutils'
require 'json'
require 'date'

# Load caching system
require_relative 'scripts/build-cache'
require_relative 'scripts/cached-page-generator'

namespace :iplibrary do
  desc "Generate all static pages for IPLibrary website"
  task :generate_all => [:categories, :subcategories, :sections, :resources, :index_pages, :help_pages]

  desc "Generate category pages"
  task :categories do
    puts "Generating category pages..."
    ['en-US', 'pt-BR'].each do |lang|
      process_language_categories(lang)
    end
  end

  desc "Generate subcategory pages"
  task :subcategories do
    puts "Generating subcategory pages..."
    ['en-US', 'pt-BR'].each do |lang|
      process_language_subcategories(lang)
    end
  end

  desc "Generate section pages"
  task :sections do
    puts "Generating section pages..."
    ['en-US', 'pt-BR'].each do |lang|
      process_language_sections(lang)
    end
  end

  desc "Generate resource listing pages"
  task :resources do
    puts "Generating resource pages..."
    ['en-US', 'pt-BR'].each do |lang|
      process_language_resources(lang)
    end
  end

  desc "Generate index pages"
  task :index_pages do
    puts "Generating index pages..."
    generate_categories_index('en-US')
    generate_categories_index('pt-BR')
  end

  desc "Generate help pages"
  task :help_pages do
    puts "Generating help pages..."
    generate_help_page('en-US')
    generate_help_page('pt-BR')
  end

  desc "Clean generated pages"
  task :clean do
    puts "Cleaning generated pages..."
    # Delete generated pages, but keep template files
    # This could be more granular if needed
  end
end

# Helper methods

# Safe YAML loading with permitted classes
def safe_load_yaml(file_path)
  YAML.safe_load(File.read(file_path), permitted_classes: [Date, Time])
end

def process_language_categories(lang)
  # Load menu data
  menu_file = File.join('_data', lang, 'menu.yaml')
  return unless File.exist?(menu_file)
  
  menu_data = safe_load_yaml(menu_file)
  
  # Process each category
  menu_data.each do |category|
    generate_category_page(lang, category)
  end
end

def process_language_subcategories(lang)
  menu_file = File.join('_data', lang, 'menu.yaml')
  return unless File.exist?(menu_file)
  
  menu_data = safe_load_yaml(menu_file)
  
  menu_data.each do |category|
    next unless category['children']
    
    category['children'].each do |subcategory|
      generate_subcategory_page(lang, category, subcategory)
    end
  end
end

def process_language_sections(lang)
  menu_file = File.join('_data', lang, 'menu.yaml')
  return unless File.exist?(menu_file)
  
  menu_data = safe_load_yaml(menu_file)
  
  menu_data.each do |category|
    next unless category['children']
    
    category['children'].each do |subcategory|
      next unless subcategory['children']
      
      subcategory['children'].each do |section|
        generate_section_page(lang, category, subcategory, section)
      end
    end
  end
end

def process_language_resources(lang)
  # Find all resource files in the data directory
  Dir.glob(File.join('_data', lang, '*', '*.yaml')).each do |resource_file|
    next if resource_file.include?('menu.yaml')
    
    category_path = File.dirname(resource_file).split('/').last
    resource_type = File.basename(resource_file, '.yaml')
    
    # Load resource data
    resources = safe_load_yaml(resource_file)
    
    # Generate resource listing page
    generate_resources_page(lang, category_path, resource_type, resources)
    
    # Generate individual resource pages
    resources.each do |resource|
      generate_resource_page(lang, category_path, resource_type, resource)
    end
  end
end

# Get the target directory (Jekyll _site directory)
def site_dir
  # Default to _site if not specified
  ENV['JEKYLL_DEST'] || '_site'
end

def generate_category_page(lang, category)
  path = category['path']
  # Remove leading and trailing slashes
  path = path.sub(/^\//, '').chomp('/')
  
  # Create directory in the _site folder
  target_path = File.join(site_dir, path)
  FileUtils.mkdir_p(target_path) unless Dir.exist?(target_path)
  
  # Get template content
  template_path = File.join('_includes', 'templates', 'category-content.md')
  template_content = File.exist?(template_path) ? File.read(template_path) : ""
  
  # Create front matter
  front_matter = {
    'layout' => 'category',
    'title' => category['title'],
    'lang' => lang,
    'description' => "Explore resources related to #{category['title']}",
    'last_updated' => Time.now.strftime("%Y-%m-%d")
  }
  
  # Write the file
  File.open(File.join(target_path, 'index.html'), 'w') do |file|
    file.puts "---"
    front_matter.each do |key, value|
      file.puts "#{key}: #{value.to_s}"
    end
    file.puts "---"
    file.puts
    file.puts template_content
  end
  
  puts "Generated category page: #{path}/index.html"
end

def generate_subcategory_page(lang, parent_category, subcategory)
  path = subcategory['path']
  # Remove leading and trailing slashes
  path = path.sub(/^\//, '').chomp('/')
  
  # Create directory in the _site folder
  target_path = File.join(site_dir, path)
  FileUtils.mkdir_p(target_path) unless Dir.exist?(target_path)
  
  # Get template content
  template_path = File.join('_includes', 'templates', 'subcategory-content.md')
  template_content = File.exist?(template_path) ? File.read(template_path) : ""
  
  # Create front matter
  front_matter = {
    'layout' => 'subcategory',
    'title' => subcategory['title'],
    'lang' => lang,
    'parent_category' => parent_category['title'],
    'description' => "Resources on #{subcategory['title']} within #{parent_category['title']}",
    'last_updated' => Time.now.strftime("%Y-%m-%d")
  }
  
  # Write the file
  File.open(File.join(target_path, 'index.html'), 'w') do |file|
    file.puts "---"
    front_matter.each do |key, value|
      file.puts "#{key}: #{value.to_s}"
    end
    file.puts "---"
    file.puts
    file.puts template_content
  end
  
  puts "Generated subcategory page: #{path}/index.html"
end

def generate_section_page(lang, parent_category, parent_subcategory, section)
  path = section['path']
  # Remove leading and trailing slashes
  path = path.sub(/^\//, '').chomp('/')
  
  # Create directory in the _site folder
  target_path = File.join(site_dir, path)
  FileUtils.mkdir_p(target_path) unless Dir.exist?(target_path)
  
  # Get template content
  template_path = File.join('_includes', 'templates', 'section-content.md')
  template_content = File.exist?(template_path) ? File.read(template_path) : ""
  
  # Create front matter
  front_matter = {
    'layout' => 'section',
    'title' => section['title'],
    'lang' => lang,
    'parent_category' => parent_category['title'],
    'parent_subcategory' => parent_subcategory['title'],
    'description' => "Specialized resources on #{section['title']} in #{parent_subcategory['title']}",
    'last_updated' => Time.now.strftime("%Y-%m-%d")
  }
  
  # Write the file
  File.open(File.join(target_path, 'index.html'), 'w') do |file|
    file.puts "---"
    front_matter.each do |key, value|
      file.puts "#{key}: #{value.to_s}"
    end
    file.puts "---"
    file.puts
    file.puts template_content
  end
  
  puts "Generated section page: #{path}/index.html"
end

def generate_resources_page(lang, category_path, resource_type, resources)
  # Determine the path based on category and resource type
  path = File.join(lang, category_path, resource_type)
  
  # Create directory in the _site folder
  target_path = File.join(site_dir, path)
  FileUtils.mkdir_p(target_path) unless Dir.exist?(target_path)
  
  # Create front matter
  front_matter = {
    'layout' => 'resources',
    'title' => "#{resource_type.capitalize} in #{category_path.capitalize}",
    'lang' => lang,
    'category' => category_path,
    'resource_type' => resource_type,
    'description' => "Browse #{resource_type} resources for #{category_path}",
    'last_updated' => Time.now.strftime("%Y-%m-%d")
  }
  
  # Write the file
  File.open(File.join(target_path, 'index.html'), 'w') do |file|
    file.puts "---"
    front_matter.each do |key, value|
      file.puts "#{key}: #{value.to_s}"
    end
    file.puts "---"
    
    # Inject resources data as JSON for client-side rendering if needed
    file.puts "<script>"
    file.puts "window.resourcesData = #{resources.to_json};"
    file.puts "</script>"
  end
  
  puts "Generated resources page: #{path}/index.html"
end

def generate_resource_page(lang, category_path, resource_type, resource)
  return unless resource['title'] # Skip if no title
  
  # Create a slug from the title
  slug = resource['title'].downcase.gsub(/[^a-z0-9]+/, '-').gsub(/-+$/, '')
  
  # Determine the path
  path = File.join(lang, category_path, resource_type, slug)
  
  # Create directory in the _site folder
  target_path = File.join(site_dir, path)
  FileUtils.mkdir_p(target_path) unless Dir.exist?(target_path)
  
  # Get template content
  template_path = File.join('_includes', 'templates', 'resource-content.md')
  template_content = File.exist?(template_path) ? File.read(template_path) : ""
  
  # Create front matter
  front_matter = {
    'layout' => 'resource',
    'title' => resource['title'],
    'lang' => lang,
    'category' => category_path,
    'resource_type' => resource_type,
    'url' => resource['url'],
    'description' => resource['description'],
    'tags' => resource['tags'],
    'access' => resource['access'],
    'last_updated' => resource['last_updated'] || Time.now.strftime("%Y-%m-%d")
  }
  
  # Write the file
  File.open(File.join(target_path, 'index.html'), 'w') do |file|
    file.puts "---"
    front_matter.each do |key, value|
      if value.is_a?(Array)
        file.puts "#{key}:"
        value.each do |item|
          file.puts "  - #{item}"
        end
      else
        file.puts "#{key}: #{value.to_s}"
      end
    end
    file.puts "---"
    file.puts
    file.puts template_content
  end
  
  puts "Generated resource page: #{path}/index.html"
end

def generate_categories_index(lang)
  # Create the categories index page
  path = File.join(lang, 'categories')
  
  # Create directory in the _site folder
  target_path = File.join(site_dir, path)
  FileUtils.mkdir_p(target_path) unless Dir.exist?(target_path)
  
  # Get template content
  template_path = File.join('_includes', 'templates', 'categories-content.md')
  template_content = File.exist?(template_path) ? File.read(template_path) : ""
  
  # Create front matter
  front_matter = {
    'layout' => 'categories',
    'title' => 'All Categories',
    'lang' => lang,
    'description' => 'Browse all resource categories',
    'last_updated' => Time.now.strftime("%Y-%m-%d")
  }
  
  # Write the file
  File.open(File.join(target_path, 'index.html'), 'w') do |file|
    file.puts "---"
    front_matter.each do |key, value|
      file.puts "#{key}: #{value.to_s}"
    end
    file.puts "---"
    file.puts
    file.puts template_content
  end
  
  puts "Generated categories index page: #{path}/index.html"
end

def generate_help_page(lang)
  # Create the help page
  path = File.join(lang, 'help')
  
  # Create directory in the _site folder
  target_path = File.join(site_dir, path)
  FileUtils.mkdir_p(target_path) unless Dir.exist?(target_path)
  
  # Create front matter
  front_matter = {
    'layout' => 'default',
    'title' => 'Help',
    'lang' => lang,
    'description' => 'Get help using the Internet Public Library',
    'last_updated' => Time.now.strftime("%Y-%m-%d")
  }
  
  # Write the file
  File.open(File.join(target_path, 'index.html'), 'w') do |file|
    file.puts "---"
    front_matter.each do |key, value|
      file.puts "#{key}: #{value.to_s}"
    end
    file.puts "---"
    
    # Basic content for help page
    file.puts "<div class='container mx-auto px-4 py-8'>"
    file.puts "  <h1 class='text-3xl font-bold text-gray-800 mb-6'>Help</h1>"
    file.puts "  <div class='prose max-w-none'>"
    file.puts "    <p>This page provides help for using the Internet Public Library.</p>"
    file.puts "    <!-- Help content would go here -->"
    file.puts "  </div>"
    file.puts "</div>"
  end
  
  puts "Generated help page: #{path}/index.html"
end 

#!/usr/bin/env ruby
# Cached Page Generator for IPLibrary Website
# Optimized page generation with intelligent caching

require_relative 'build-cache'
require 'yaml'
require 'fileutils'
require 'erb'

class IPLibraryCachedGenerator
  def initialize
    @cache_generator = CachedPageGenerator.new
    @templates = {}
    load_templates
  end
  
  def load_templates
    template_dir = '_includes/templates'
    return unless Dir.exist?(template_dir)
    
    Dir.glob(File.join(template_dir, '*.md')).each do |template_file|
      template_name = File.basename(template_file, '.md')
      @templates[template_name] = @cache_generator.get_template_with_cache(template_file)
    end
    
    puts "Loaded #{@templates.keys.size} templates into cache"
  end
  
  def safe_load_yaml(file_path)
    return {} unless File.exist?(file_path)
    
    begin
      YAML.safe_load(
        File.read(file_path), 
        permitted_classes: [Date, Time, Symbol], 
        permitted_symbols: [], 
        aliases: true
      ) || {}
    rescue => e
      puts "Error loading YAML from #{file_path}: #{e.message}"
      {}
    end
  end
  
  def generate_category_pages_cached(lang)
    return unless @cache_generator.should_process_language?(lang)
    
    menu_file = "_data/#{lang}/menu.yaml"
    menu_data = safe_load_yaml(menu_file)
    
    dependencies = [menu_file, '_includes/templates/categories-content.md', '_layouts/category.html']
    
    menu_data.each do |category|
      category_slug = safe_slug(category['title'])
      category_path = "#{lang}/#{category_slug}/index.html"
      
      @cache_generator.generate_with_cache(category_path, dependencies) do
        generate_category_content(lang, category)
      end
    end
  end
  
  def generate_category_content(lang, category)
    template = @templates['categories-content'] || "# #{category['title']}\n\nCategory page content"
    
    # Process ERB template with category data
    erb = ERB.new(template)
    erb.result(binding)
  end
  
  def safe_slug(text)
    text.downcase.gsub(/[^a-z0-9\s-]/, '').gsub(/\s+/, '-').gsub(/-+/, '-').gsub(/^-|-$/, '')
  end
  
  def generate_subcategory_pages_cached(lang)
    return unless @cache_generator.should_process_language?(lang)
    
    menu_file = "_data/#{lang}/menu.yaml"
    menu_data = safe_load_yaml(menu_file)
    
    dependencies = [menu_file, '_includes/templates/categories-content.md', '_layouts/subcategory.html']
    
    menu_data.each do |category|
      next unless category['children']
      
      category['children'].each do |subcategory|
        category_slug = safe_slug(category['title'])
        subcategory_slug = safe_slug(subcategory['title'])
        subcategory_path = "#{lang}/#{category_slug}/#{subcategory_slug}/index.html"
        
        @cache_generator.generate_with_cache(subcategory_path, dependencies) do
          generate_subcategory_content(lang, category, subcategory)
        end
      end
    end
  end
  
  def generate_subcategory_content(lang, category, subcategory)
    template = @templates['categories-content'] || "# #{subcategory['title']}\n\nSubcategory page content"
    
    # Process ERB template with subcategory data
    erb = ERB.new(template)
    erb.result(binding)
  end
  
  def generate_section_pages_cached(lang)
    return unless @cache_generator.should_process_language?(lang)
    
    menu_file = "_data/#{lang}/menu.yaml"
    menu_data = safe_load_yaml(menu_file)
    
    dependencies = [menu_file, '_includes/templates/categories-content.md', '_layouts/section.html']
    
    menu_data.each do |category|
      next unless category['children']
      
      category['children'].each do |subcategory|
        next unless subcategory['children']
        
        subcategory['children'].each do |section|
          section_path = "#{lang}/#{category['title'].downcase.gsub(' ', '-')}/#{subcategory['title'].downcase.gsub(' ', '-')}/#{section['title'].downcase.gsub(' ', '-')}/index.html"
          
          @cache_generator.generate_with_cache(section_path, dependencies) do
            generate_section_content(lang, category, subcategory, section)
          end
        end
      end
    end
  end
  
  def generate_section_content(lang, category, subcategory, section)
    template = @templates['categories-content'] || "# #{section['title']}\n\nSection page content"
    
    # Process ERB template with section data
    erb = ERB.new(template)
    erb.result(binding)
  end
  
  def generate_resource_pages_cached(lang)
    return unless @cache_generator.should_process_language?(lang)
    
    resource_dirs = Dir.glob("_data/#{lang}/*").select { |f| File.directory?(f) }
    
    resource_dirs.each do |resource_dir|
      category_name = File.basename(resource_dir)
      
      Dir.glob(File.join(resource_dir, '*.yaml')).each do |resource_file|
        subcategory_name = File.basename(resource_file, '.yaml')
        dependencies = [resource_file, '_includes/templates/resource-content.md', '_layouts/resources.html']
        
        # Generate resources index page
        resources_path = "#{lang}/#{category_name}/#{subcategory_name}/index.html"
        
        @cache_generator.generate_with_cache(resources_path, dependencies) do
          generate_resources_content(lang, category_name, subcategory_name, resource_file)
        end
        
        # Generate individual resource pages
        resources_data = safe_load_yaml(resource_file)
        resources_data.each do |resource|
          next unless resource['title']
          
          resource_slug = resource['title'].downcase.gsub(/[^a-z0-9\s-]/, '').gsub(/\s+/, '-')
          resource_path = "#{lang}/#{category_name}/#{subcategory_name}/#{resource_slug}/index.html"
          
          @cache_generator.generate_with_cache(resource_path, dependencies) do
            generate_resource_content(lang, category_name, subcategory_name, resource)
          end
        end
      end
    end
  end
  
  def generate_resources_content(lang, category_name, subcategory_name, resource_file)
    template = @templates['resource-content'] || "# Resources\n\nResource listing page"
    resources_data = safe_load_yaml(resource_file)
    
    erb = ERB.new(template)
    erb.result(binding)
  end
  
  def generate_resource_content(lang, category_name, subcategory_name, resource)
    template = @templates['resource-content'] || "# #{resource['title']}\n\nResource page content"
    
    erb = ERB.new(template)
    erb.result(binding)
  end
  
  def generate_index_pages_cached
    ['en-US', 'pt-BR'].each do |lang|
      next unless @cache_generator.should_process_language?(lang)
      
      dependencies = ["_data/#{lang}/menu.yaml", '_layouts/categories.html']
      index_path = "#{lang}/categories/index.html"
      
      @cache_generator.generate_with_cache(index_path, dependencies) do
        generate_categories_index_content(lang)
      end
    end
  end
  
  def generate_categories_index_content(lang)
    menu_file = "_data/#{lang}/menu.yaml"
    menu_data = safe_load_yaml(menu_file)
    
    content = "---\nlayout: categories\nlang: #{lang}\n---\n\n"
    content += "# Categories\n\n"
    
    menu_data.each do |category|
      content += "- [#{category['title']}](#{category['path']})\n"
    end
    
    content
  end
  
  def generate_help_pages_cached
    ['en-US', 'pt-BR'].each do |lang|
      next unless @cache_generator.should_process_language?(lang)
      
      dependencies = ['_layouts/wiki.html']
      help_path = "#{lang}/help/index.html"
      
      @cache_generator.generate_with_cache(help_path, dependencies) do
        generate_help_content(lang)
      end
    end
  end
  
  def generate_help_content(lang)
    "---\nlayout: wiki\nlang: #{lang}\n---\n\n# Help\n\nHelp page content for #{lang}"
  end
  
  def generate_all_cached
    puts "Starting cached page generation..."
    start_time = Time.now
    
    ['en-US', 'pt-BR'].each do |lang|
      puts "Processing language: #{lang}"
      
      generate_category_pages_cached(lang)
      generate_subcategory_pages_cached(lang)
      generate_section_pages_cached(lang)
      generate_resource_pages_cached(lang)
    end
    
    generate_index_pages_cached
    generate_help_pages_cached
    
    end_time = Time.now
    duration = (end_time - start_time).round(2)
    puts "Cached generation completed in #{duration} seconds"
    
    @cache_generator.finalize
  end
  
  def clear_cache
    @cache_generator.clear_cache
  end
end

# Make generator available globally
$cached_generator = IPLibraryCachedGenerator.new

# New cached rake tasks
namespace :cached do
  desc "Generate all pages with caching"
  task :generate_all do
    $cached_generator.generate_all_cached
  end
  
  desc "Generate category pages with caching"
  task :categories do
    puts "Generating category pages with cache..."
    ['en-US', 'pt-BR'].each do |lang|
      $cached_generator.generate_category_pages_cached(lang)
    end
  end
  
  desc "Generate subcategory pages with caching"
  task :subcategories do
    puts "Generating subcategory pages with cache..."
    ['en-US', 'pt-BR'].each do |lang|
      $cached_generator.generate_subcategory_pages_cached(lang)
    end
  end
  
  desc "Generate section pages with caching"
  task :sections do
    puts "Generating section pages with cache..."
    ['en-US', 'pt-BR'].each do |lang|
      $cached_generator.generate_section_pages_cached(lang)
    end
  end
  
  desc "Generate resource pages with caching"
  task :resources do
    puts "Generating resource pages with cache..."
    ['en-US', 'pt-BR'].each do |lang|
      $cached_generator.generate_resource_pages_cached(lang)
    end
  end
  
  desc "Clear all caches"
  task :clear do
    $cached_generator.clear_cache
  end
end

puts "Cached page generator loaded successfully"
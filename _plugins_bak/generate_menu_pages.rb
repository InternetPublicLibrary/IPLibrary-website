require 'fileutils'
require 'date'
require 'set'

module Jekyll
  class MenuPagesGenerator < Generator
    safe true
    priority :high  # Run before other generators
    
    def generate(site)
      # Check the unified page generation configuration
      page_gen_config = site.config['page_generation'] || {}
      strategy = page_gen_config['strategy'] || 'jekyll'
      skip_plugins = page_gen_config['skip_jekyll_plugins'] || false
      
      # Skip if strategy is 'rake' or plugins are explicitly disabled
      if strategy == 'rake' || skip_plugins
        puts "Skipping MenuPagesGenerator - page generation handled by Rake (strategy: #{strategy})"
        return
      end
      
      # Skip if in safe mode (GitHub Pages) and not explicitly enabled
      if site.safe && !site.config['enable_menu_pages']
        puts "Skipping MenuPagesGenerator because we're in safe mode (GitHub Pages)"
        return
      end
      
      # Legacy check - Skip if disabled in config
      unless site.config['enable_menu_pages'] || strategy == 'jekyll' || strategy == 'hybrid'
        puts "MenuPagesGenerator is disabled in _config.yml"
        return
      end
      
      # Register with the central registry if available
      if defined?(Jekyll::PageRegistry) && site.config['page_registry']
        Jekyll::PageRegistry.instance.register_plugin('MenuPagesGenerator')
      end
      
      # Add debug output
      puts "Starting MenuPagesGenerator..."
      
      # Store site in instance variable to access it in helper methods
      @site = site
      
      # Process each language
      site.data.each do |lang_code, lang_data|
        next unless lang_data.has_key?('menu') # Skip if no menu data
        puts "Processing language: #{lang_code}"

        # Generate language index page
        generate_language_index(lang_code)

        # Process top-level categories
        lang_data['menu'].each do |category|
          generate_category_page(lang_code, category)
          
          # Process subcategories
          if category.has_key?('children')
            category['children'].each do |subcategory|
              generate_subcategory_page(lang_code, category, subcategory)
              
              # Process sections
              if subcategory.has_key?('children')
                subcategory['children'].each do |section|
                  generate_section_page(lang_code, category, subcategory, section)
                end
              end
            end
          end
        end
      end
      
      puts "MenuPagesGenerator finished."
    end
    
    private
    
    def ensure_directory_exists(dir)
      # Create the directory if it doesn't exist
      FileUtils.mkdir_p(dir) unless Dir.exist?(dir)
    end
    
    def already_generated?(path)
      if defined?(Jekyll::PageRegistry) && @site.config['page_registry']
        Jekyll::PageRegistry.instance.registered?(path)
      else
        false
      end
    end
    
    def mark_as_generated(path)
      if defined?(Jekyll::PageRegistry) && @site.config['page_registry']
        Jekyll::PageRegistry.instance.register(path, 'MenuPagesGenerator')
      end
    end
    
    def generate_language_index(lang_code)
      page_path = "#{lang_code}/index.html"
      
      # Skip if already generated
      if already_generated?(page_path)
        puts "Skipping already generated page: #{page_path}"
        return
      end
      
      # Create a page
      page = Jekyll::PageWithoutAFile.new(@site, @site.source, "", page_path)
      page.content = ""
      page.data = {
        'layout' => 'language_index',
        'title' => @site.config['languages'].find { |l| l['code'] == lang_code }&.dig('name') || lang_code,
        'lang' => lang_code,
        'description' => "Welcome to the #{lang_code} version of Internet Public Library",
        'last_updated' => Time.now.strftime("%Y-%m-%d")
      }
      
      # Add the page to Jekyll's pages
      @site.pages << page
      
      # Mark as generated
      mark_as_generated(page_path)
      
      puts "Generated language index page: #{page_path}"
    rescue => e
      puts "Error generating language index page #{page_path}: #{e.message}"
      puts e.backtrace.join("\n")
    end
    
    def generate_category_page(lang_code, category)
      path = category['path']
      # Remove trailing slash if present
      path = path.chomp('/') if path.end_with?('/')
      
      # Ensure path is relative to source
      if path.start_with?('/')
        path = path[1..-1]  # Remove leading slash
      end
      
      page_path = "#{path}/index.html"
      
      # Skip if already generated
      if already_generated?(page_path)
        puts "Skipping already generated page: #{page_path}"
        return
      end
      
      # Read template content
      template_path = File.join(@site.source, '_includes', 'templates', 'category-content.md')
      template_content = File.exist?(template_path) ? File.read(template_path) : ""
      
      # Create a page
      page = Jekyll::PageWithoutAFile.new(@site, @site.source, "", page_path)
      page.content = template_content
      page.data = {
        'layout' => 'category',
        'title' => category['title'],
        'lang' => lang_code,
        'description' => "Explore resources related to #{category['title']}",
        'last_updated' => Time.now.strftime("%Y-%m-%d"),
        'show_discussion' => true  # Add discussion flag
      }
      
      # Add the page to Jekyll's pages
      @site.pages << page
      
      # Mark as generated
      mark_as_generated(page_path)
      
      puts "Generated category page: #{page_path}"
    rescue => e
      puts "Error generating category page #{path}: #{e.message}"
      puts e.backtrace.join("\n")
    end
    
    def generate_subcategory_page(lang_code, parent_category, subcategory)
      path = subcategory['path']
      # Remove trailing slash if present
      path = path.chomp('/') if path.end_with?('/')
      
      # Ensure path is relative to source
      if path.start_with?('/')
        path = path[1..-1]  # Remove leading slash
      end
      
      page_path = "#{path}/index.html"
      
      # Skip if already generated
      if already_generated?(page_path)
        puts "Skipping already generated page: #{page_path}"
        return
      end
      
      # Read template content
      template_path = File.join(@site.source, '_includes', 'templates', 'subcategory-content.md')
      template_content = File.exist?(template_path) ? File.read(template_path) : ""
      
      # Create a page
      page = Jekyll::PageWithoutAFile.new(@site, @site.source, "", page_path)
      page.content = template_content
      page.data = {
        'layout' => 'subcategory',
        'title' => subcategory['title'],
        'lang' => lang_code,
        'parent_category' => parent_category['title'],
        'parent_category_path' => parent_category['path'],
        'description' => "Resources on #{subcategory['title']} within #{parent_category['title']}",
        'last_updated' => Time.now.strftime("%Y-%m-%d"),
        'show_discussion' => true  # Add discussion flag
      }
      
      # Add the page to Jekyll's pages
      @site.pages << page
      
      # Mark as generated
      mark_as_generated(page_path)
      
      puts "Generated subcategory page: #{page_path}"
    rescue => e
      puts "Error generating subcategory page #{path}: #{e.message}"
      puts e.backtrace.join("\n")
    end
    
    def generate_section_page(lang_code, parent_category, parent_subcategory, section)
      path = section['path']
      # Remove trailing slash if present
      path = path.chomp('/') if path.end_with?('/')
      
      # Ensure path is relative to source
      if path.start_with?('/')
        path = path[1..-1]  # Remove leading slash
      end
      
      page_path = "#{path}/index.html"
      
      # Skip if already generated
      if already_generated?(page_path)
        puts "Skipping already generated page: #{page_path}"
        return
      end
      
      # Read template content
      template_path = File.join(@site.source, '_includes', 'templates', 'section-content.md')
      template_content = File.exist?(template_path) ? File.read(template_path) : ""
      
      # Create a page
      page = Jekyll::PageWithoutAFile.new(@site, @site.source, "", page_path)
      page.content = template_content
      page.data = {
        'layout' => 'section',
        'title' => section['title'],
        'lang' => lang_code,
        'parent_category' => parent_category['title'],
        'parent_category_path' => parent_category['path'],
        'parent_subcategory' => parent_subcategory['title'],
        'parent_subcategory_path' => parent_subcategory['path'],
        'description' => "Specialized resources on #{section['title']} in #{parent_subcategory['title']}",
        'last_updated' => Time.now.strftime("%Y-%m-%d"),
        'resources' => [],  # Empty array for resources, to be filled later
        'show_discussion' => true  # Add discussion flag
      }
      
      # Add the page to Jekyll's pages
      @site.pages << page
      
      # Mark as generated
      mark_as_generated(page_path)
      
      puts "Generated section page: #{page_path}"
    rescue => e
      puts "Error generating section page #{path}: #{e.message}"
      puts e.backtrace.join("\n")
    end
  end
end 

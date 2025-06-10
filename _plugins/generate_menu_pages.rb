require 'fileutils'

module Jekyll
  class MenuPagesGenerator < Generator
    safe true
    
    def generate(site)
      # Skip if in safe mode (GitHub Pages) and not explicitly enabled
      if site.safe && !site.config['enable_dynamic_pages']
        puts "Skipping MenuPagesGenerator because we're in safe mode (GitHub Pages)"
        return
      end
      
      # Add debug output
      puts "Starting MenuPagesGenerator..."
      
      # Process each language
      site.data.each do |lang_code, lang_data|
        next unless lang_data.has_key?('menu') # Skip if no menu data
        puts "Processing language: #{lang_code}"

        # Process top-level categories
        lang_data['menu'].each do |category|
          generate_category_page(site, lang_code, category)
          
          # Process subcategories
          if category.has_key?('children')
            category['children'].each do |subcategory|
              generate_subcategory_page(site, lang_code, category, subcategory)
              
              # Process sections
              if subcategory.has_key?('children')
                subcategory['children'].each do |section|
                  generate_section_page(site, lang_code, category, subcategory, section)
                end
              end
            end
          end
        end
      end
      
      puts "MenuPagesGenerator finished."
    end
    
    private
    
    def ensure_directory_exists(site, dir)
      # Create the directory if it doesn't exist
      full_dir = File.join(site.source, dir)
      FileUtils.mkdir_p(full_dir) unless Dir.exist?(full_dir)
    end
    
    def generate_category_page(site, lang_code, category)
      path = category['path']
      # Remove trailing slash if present
      path = path.chomp('/') if path.end_with?('/')
      
      # Ensure path is relative to source
      if path.start_with?('/')
        path = path[1..-1]  # Remove leading slash
      end
      
      # Handle index files
      if File.extname(path).empty?
        dir = path
        name = "index.html"
      else
        dir = File.dirname(path)
        name = File.basename(path)
      end
      
      # Ensure directory exists
      ensure_directory_exists(site, dir)
      
      puts "Generating category page: #{path} (dir: #{dir}, name: #{name})"
      
      # Read template content
      template_path = File.join(site.source, '_includes', 'templates', 'category-content.md')
      template_content = File.exist?(template_path) ? File.read(template_path) : ""
      
      # Create the page directly into the destination
      content_path = File.join(dir, name)
      page = Jekyll::Page.new(site, site.source, dir, name)
      page.content = template_content
      page.data = {
        'layout' => 'category',
        'title' => category['title'],
        'lang' => lang_code,
        'description' => "Explore resources related to #{category['title']}",
        'last_updated' => Time.now.strftime("%Y-%m-%d")
      }
      
      site.pages << page
    rescue => e
      puts "Error generating category page #{path}: #{e.message}"
      puts e.backtrace.join("\n")
    end
    
    def generate_subcategory_page(site, lang_code, parent_category, subcategory)
      path = subcategory['path']
      # Remove trailing slash if present
      path = path.chomp('/') if path.end_with?('/')
      
      # Ensure path is relative to source
      if path.start_with?('/')
        path = path[1..-1]  # Remove leading slash
      end
      
      # Handle index files
      if File.extname(path).empty?
        dir = path
        name = "index.html"
      else
        dir = File.dirname(path)
        name = File.basename(path)
      end
      
      # Ensure directory exists
      ensure_directory_exists(site, dir)
      
      puts "Generating subcategory page: #{path} (dir: #{dir}, name: #{name})"
      
      # Read template content
      template_path = File.join(site.source, '_includes', 'templates', 'subcategory-content.md')
      template_content = File.exist?(template_path) ? File.read(template_path) : ""
      
      page = Jekyll::Page.new(site, site.source, dir, name)
      page.content = template_content
      page.data = {
        'layout' => 'subcategory',
        'title' => subcategory['title'],
        'lang' => lang_code,
        'parent_category' => parent_category['title'],
        'description' => "Resources on #{subcategory['title']} within #{parent_category['title']}",
        'last_updated' => Time.now.strftime("%Y-%m-%d")
      }
      
      site.pages << page
    rescue => e
      puts "Error generating subcategory page #{path}: #{e.message}"
      puts e.backtrace.join("\n")
    end
    
    def generate_section_page(site, lang_code, parent_category, parent_subcategory, section)
      path = section['path']
      # Remove trailing slash if present
      path = path.chomp('/') if path.end_with?('/')
      
      # Ensure path is relative to source
      if path.start_with?('/')
        path = path[1..-1]  # Remove leading slash
      end
      
      # Handle index files
      if File.extname(path).empty?
        dir = path
        name = "index.html"
      else
        dir = File.dirname(path)
        name = File.basename(path)
      end
      
      # Ensure directory exists
      ensure_directory_exists(site, dir)
      
      puts "Generating section page: #{path} (dir: #{dir}, name: #{name})"
      
      # Read template content
      template_path = File.join(site.source, '_includes', 'templates', 'section-content.md')
      template_content = File.exist?(template_path) ? File.read(template_path) : ""
      
      page = Jekyll::Page.new(site, site.source, dir, name)
      page.content = template_content
      page.data = {
        'layout' => 'section',
        'title' => section['title'],
        'lang' => lang_code,
        'parent_category' => parent_category['title'],
        'parent_subcategory' => parent_subcategory['title'],
        'description' => "Specialized resources on #{section['title']} in #{parent_subcategory['title']}",
        'last_updated' => Time.now.strftime("%Y-%m-%d"),
        'resources' => []  # Empty array for resources, to be filled later
      }
      
      site.pages << page
    rescue => e
      puts "Error generating section page #{path}: #{e.message}"
      puts e.backtrace.join("\n")
    end
  end
end 
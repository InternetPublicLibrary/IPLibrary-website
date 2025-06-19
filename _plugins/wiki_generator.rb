require 'fileutils'
require 'date'
require 'set'

module Jekyll
  class WikiPagesGenerator < Generator
    safe true
    priority :normal  # Run after menu pages generator
    
    def generate(site)
      # Skip if in safe mode (GitHub Pages) and not explicitly enabled
      if site.safe && !site.config['enable_wiki_pages']
        puts "Skipping WikiPagesGenerator because we're in safe mode (GitHub Pages)"
        return
      end
      
      # Skip if disabled in config
      unless site.config['enable_wiki_pages']
        puts "WikiPagesGenerator is disabled in _config.yml"
        return
      end
      
      # Register with the central registry if available
      if defined?(Jekyll::PageRegistry) && site.config['page_registry']
        Jekyll::PageRegistry.instance.register_plugin('WikiPagesGenerator')
      end
      
      # Add debug output
      puts "Starting WikiPagesGenerator..."
      
      # Store site in instance variable to access it in helper methods
      @site = site
      
      # Generate wiki pages for all sections
      generate_wiki_pages_for_sections(site)
      
      # Generate language indexes
      generate_language_indexes
      
      puts "WikiPagesGenerator finished."
    end
    
    private
    
    def already_generated?(path)
      if defined?(Jekyll::PageRegistry) && @site.config['page_registry']
        Jekyll::PageRegistry.instance.registered?(path)
      else
        false
      end
    end
    
    def mark_as_generated(path)
      if defined?(Jekyll::PageRegistry) && @site.config['page_registry']
        Jekyll::PageRegistry.instance.register(path, 'WikiPagesGenerator')
      end
    end
    
    def generate_wiki_pages_for_sections(site)
      # Process each language
      site.data.each do |lang_code, lang_data|
        next unless lang_data.has_key?('menu') # Skip if no menu data
        puts "Processing wiki pages for language: #{lang_code}"

        # Find all sections in the menu hierarchy
        lang_data['menu'].each do |category|
          next unless category.has_key?('children')
          
          category['children'].each do |subcategory|
            next unless subcategory.has_key?('children')
            
            subcategory['children'].each do |section|
              generate_wiki_page(lang_code, category, subcategory, section)
            end
          end
        end
      end
    end
    
    def generate_wiki_page(lang_code, category, subcategory, section)
      # Create wiki path by adding /wiki to the section path
      section_path = section['path']
      section_path = section_path.chomp('/') if section_path.end_with?('/')
      
      # Ensure path is relative to source
      if section_path.start_with?('/')
        section_path = section_path[1..-1]  # Remove leading slash
      end
      
      wiki_path = "#{section_path}/wiki"
      page_path = "#{wiki_path}/index.html"
      
      # Skip if already generated
      if already_generated?(page_path)
        puts "Skipping already generated wiki page: #{page_path}"
        return
      end
      
      # Create the wiki page
      page = Jekyll::PageWithoutAFile.new(@site, @site.source, "", page_path)
      page.content = generate_wiki_content(category, subcategory, section)
      page.data = {
        'layout' => 'wiki',
        'title' => "Wiki: #{section['title']}",
        'section_title' => section['title'],
        'lang' => lang_code,
        'parent_category' => category['title'],
        'parent_category_path' => category['path'],
        'parent_subcategory' => subcategory['title'],
        'parent_subcategory_path' => subcategory['path'],
        'parent_section' => section['title'],
        'parent_section_path' => section_path,
        'description' => "Community wiki for #{section['title']}",
        'last_updated' => Time.now.strftime("%Y-%m-%d"),
        'editable' => true,
        'show_discussion' => true
      }
      
      # Add the page to Jekyll's pages
      @site.pages << page
      
      # Mark as generated
      mark_as_generated(page_path)
      
      puts "Generated wiki page: #{page_path}"
    rescue => e
      puts "Error generating wiki page for section #{section['title']}: #{e.message}"
      puts e.backtrace.join("\n")
    end
    
    def generate_wiki_content(category, subcategory, section)
      <<~CONTENT
        # #{section['title']} Wiki
        
        This is the community-maintained wiki page for #{section['title']} in the #{category['title']} > #{subcategory['title']} category.
        
        ## Overview
        
        Add an overview of #{section['title']} here.
        
        ## Key Concepts
        
        * Concept 1
        * Concept 2
        * Concept 3
        
        ## Resources
        
        * Resource 1
        * Resource 2
        * Resource 3
        
        ## Related Topics
        
        * Topic 1
        * Topic 2
        * Topic 3
        
        ---
        
        This wiki is maintained by the Internet Public Library community. You can contribute by clicking the "Edit Wiki" button.
      CONTENT
    end
    
    def generate_language_indexes
      @generated_pages = []
      
      # Create index pages for each language
      @site.config['languages'].each do |lang|
        lang_code = lang['code']
        
        # Generate language root index.html (direct in language folder)
        create_language_root_index(lang_code)
        
        # Also generate in the /index subfolder for backward compatibility
        # This can be removed later if not needed
        create_language_index_in_subfolder(lang_code)
      end
    end
    
    def create_language_root_index(lang_code)
      page_path = "#{lang_code}/index.html"
      
      # Skip if already generated
      if @generated_pages.include?(page_path)
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
      @generated_pages << page_path
      
      puts "Generated language root index page: #{page_path}"
    rescue => e
      puts "Error generating language root index page #{page_path}: #{e.message}"
      puts e.backtrace.join("\n")
    end
    
    def create_language_index_in_subfolder(lang_code)
      page_path = "#{lang_code}/index/index.html"
      
      # Skip if already generated
      if @generated_pages.include?(page_path)
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
      @generated_pages << page_path
      
      puts "Generated language index page in subfolder: #{page_path}"
    rescue => e
      puts "Error generating language index page in subfolder #{page_path}: #{e.message}"
      puts e.backtrace.join("\n")
    end
  end
end 

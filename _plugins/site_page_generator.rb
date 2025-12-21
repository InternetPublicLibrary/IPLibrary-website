require 'fileutils'
require 'date'
require 'set'
require 'concurrent-ruby'
require 'benchmark'

module Jekyll
  class OptimizedMenuPagesGenerator < Generator
    safe true
    priority :high  # Run before other generators
    
    def initialize(config = {})
      super
      @template_cache = Concurrent::Map.new
      @performance_stats = Concurrent::Map.new
      @generated_pages = Concurrent::Set.new  # Track generated pages locally
      @thread_pool = nil
      @mutex = Mutex.new
    end
    
    def generate(site)
      start_time = Time.now
      
      # Skip if in safe mode (GitHub Pages) and not explicitly enabled
      if site.safe && !site.config['enable_menu_pages']
        log_info "Skipping OptimizedMenuPagesGenerator because we're in safe mode (GitHub Pages)"
        return
      end
      
      # Skip if disabled in config
      unless site.config['enable_menu_pages']
        log_info "SitePageGenerator is disabled in _config.yml"
        return
      end
      
      # Register with the central registry if available
      if defined?(Jekyll::PageRegistry) && site.config['page_registry']
        Jekyll::PageRegistry.instance.register_plugin('SitePageGenerator')
      end
      
      log_info "Starting SitePageGenerator with parallel processing..."
      
      # Store site in instance variable to access it in helper methods
      @site = site
      
      # Initialize thread pool based on CPU cores
      cpu_count = Concurrent.processor_count
      @thread_pool = Concurrent::ThreadPoolExecutor.new(
        min_threads: 2,
        max_threads: [cpu_count, 8].min, # Cap at 8 threads to avoid resource exhaustion
        max_queue: cpu_count * 4,
        fallback_policy: :caller_runs
      )
      
      begin
        # Pre-load all templates to avoid redundant I/O
        preload_templates
        
        # Generate pages in parallel
        generate_pages_parallel
        
        # Wait for all tasks to complete
        @thread_pool.shutdown
        @thread_pool.wait_for_termination(60) # 60 second timeout
        
      rescue => e
        log_error "Error in OptimizedMenuPagesGenerator: #{e.message}"
        log_error e.backtrace.join("\n")
      ensure
        @thread_pool&.kill if @thread_pool&.running?
      end
      
      end_time = Time.now
      total_time = end_time - start_time
      
      log_performance_stats(total_time)
      log_info "OptimizedMenuPagesGenerator finished in #{total_time.round(2)}s"
    end
    
    private
    
    def preload_templates
      template_files = [
        'category-content.md',
        'subcategory-content.md', 
        'section-content.md'
      ]
      
      template_files.each do |filename|
        template_path = File.join(@site.source, '_includes', 'templates', filename)
        if File.exist?(template_path)
          @template_cache[filename] = File.read(template_path)
          log_debug "Cached template: #{filename}"
        else
          @template_cache[filename] = ""
          log_debug "Template not found, using empty content: #{filename}"
        end
      end
    end
    
    def generate_pages_parallel
      # Collect all page generation tasks
      tasks = []
      
      @site.data.each do |lang_code, lang_data|
        next unless lang_data.has_key?('menu') # Skip if no menu data
        log_info "Processing language: #{lang_code}"

        # Generate language index page
        tasks << create_task(:language_index, lang_code)

        # Process menu hierarchy
        lang_data['menu'].each do |category|
          tasks << create_task(:category, lang_code, category)
          
          # Process subcategories
          if category.has_key?('children')
            category['children'].each do |subcategory|
              tasks << create_task(:subcategory, lang_code, category, subcategory)
              
              # Process sections
              if subcategory.has_key?('children')
                subcategory['children'].each do |section|
                  tasks << create_task(:section, lang_code, category, subcategory, section)
                end
              end
            end
          end
        end
      end
      
      # Execute all tasks in parallel with batching to avoid overwhelming the system
      batch_size = [@thread_pool.max_length, 20].min
      tasks.each_slice(batch_size) do |batch|
        batch.each { |task| @thread_pool.post(&task) }
      end
    end
    
    def create_task(type, *args)
      proc do
        begin
          case type
          when :language_index
            generate_language_index_safe(args[0])
          when :category
            generate_category_page_safe(args[0], args[1])
          when :subcategory
            generate_subcategory_page_safe(args[0], args[1], args[2])
          when :section
            generate_section_page_safe(args[0], args[1], args[2], args[3])
          end
        rescue => e
          log_error "Error in #{type} task: #{e.message}"
          log_error e.backtrace.join("\n")
        end
      end
    end
    
    def generate_language_index_safe(lang_code)
      page_path = "#{lang_code}/index.html"
      
      # Thread-safe check for already generated pages
      return if already_generated?(page_path)
      
      # Create page data
      page_data = {
        'layout' => 'language_index',
        'title' => @site.config['languages'].find { |l| l['code'] == lang_code }&.dig('name') || lang_code,
        'lang' => lang_code,
        'description' => "Welcome to the #{lang_code} version of Internet Public Library",
        'last_updated' => Time.now.strftime("%Y-%m-%d")
      }
      
      # Thread-safe page creation
      create_page_safely(page_path, "", page_data)
      
      increment_counter(:language_pages)
      log_debug "Generated language index page: #{page_path}"
    end
    
    def generate_category_page_safe(lang_code, category)
      path = normalize_path(category['path'])
      page_path = "#{path}/index.html"
      
      return if already_generated?(page_path)
      
      template_content = @template_cache['category-content.md']
      
      page_data = {
        'layout' => 'category',
        'title' => category['title'],
        'lang' => lang_code,
        'description' => "Explore resources related to #{category['title']}",
        'last_updated' => Time.now.strftime("%Y-%m-%d"),
        'show_discussion' => true,
        'children' => category['children'], # Pass subcategories
        'data_folder' => category['data_folder'] # Pass data folder mapping
      }
      
      create_page_safely(page_path, template_content, page_data)
      
      increment_counter(:category_pages)
      log_debug "Generated category page: #{page_path}"
    end
    
    def generate_subcategory_page_safe(lang_code, parent_category, subcategory)
      path = normalize_path(subcategory['path'])
      page_path = "#{path}/index.html"
      
      return if already_generated?(page_path)
      
      template_content = @template_cache['subcategory-content.md']
      
      page_data = {
        'layout' => 'subcategory',
        'title' => subcategory['title'],
        'lang' => lang_code,
        'parent_category' => parent_category['title'],
        'parent_category_path' => parent_category['path'],
        'description' => "Resources on #{subcategory['title']} within #{parent_category['title']}",
        'last_updated' => Time.now.strftime("%Y-%m-%d"),
        'show_discussion' => true,
        'children' => subcategory['children'], # Pass sections
        'data_folder' => subcategory['data_folder'] # Pass data folder mapping
      }
      
      create_page_safely(page_path, template_content, page_data)
      
      increment_counter(:subcategory_pages)
      log_debug "Generated subcategory page: #{page_path}"
    end
    
    def generate_section_page_safe(lang_code, parent_category, parent_subcategory, section)
      path = normalize_path(section['path'])
      page_path = "#{path}/index.html"
      
      return if already_generated?(page_path)
      
      template_content = @template_cache['section-content.md']
      
      page_data = {
        'layout' => 'section',
        'title' => section['title'],
        'lang' => lang_code,
        'parent_category' => parent_category['title'],
        'parent_category_path' => parent_category['path'],
        'parent_subcategory' => parent_subcategory['title'],
        'parent_subcategory_path' => parent_subcategory['path'],
        'description' => "Specialized resources on #{section['title']} in #{parent_subcategory['title']}",
        'last_updated' => Time.now.strftime("%Y-%m-%d"),
        'resources' => [],
        'show_discussion' => true
      }
      
      create_page_safely(page_path, template_content, page_data)
      
      increment_counter(:section_pages)
      log_debug "Generated section page: #{page_path}"
    end
    
    def create_page_safely(page_path, content, data)
      # Check if physical file exists (outside mutex to reduce contention)
      if physical_page_exists?(page_path)
        log_debug "Skipping physical page: #{page_path}"
        return
      end

      @mutex.synchronize do
        # Double-check pattern to avoid race conditions
        return if already_generated?(page_path)
        
        page = Jekyll::PageWithoutAFile.new(@site, @site.source, "", page_path)
        page.content = content
        page.data = data
        
        @site.pages << page
        mark_as_generated(page_path)
      end
    end

    def physical_page_exists?(page_path)
      # Check standard HTML path
      abs_path = File.join(@site.source, page_path)
      
      # Debug logging for conflict resolution
      puts "[SitePageGenerator] Checking existence of: #{abs_path}"
      
      return true if File.exist?(abs_path)
      
      # Check Markdown versions (index.md in the directory)
      md_path = abs_path.sub(/\.html$/, '.md')
      return true if File.exist?(md_path)

      # Also check if it's an index page, if the directory contains index.md
      if page_path.end_with?('/index.html')
        dir_path = File.dirname(abs_path)
        index_md = File.join(dir_path, 'index.md')
        return true if File.exist?(index_md)
      end
      
      false
    end
    
    def normalize_path(path)
      # Remove trailing slash if present
      path = path.chomp('/') if path.end_with?('/')
      
      # Ensure path is relative to source
      if path.start_with?('/')
        path = path[1..-1]  # Remove leading slash
      end
      
      path
    end
    
    def already_generated?(path)
      if defined?(Jekyll::PageRegistry) && @site.config['page_registry']
        Jekyll::PageRegistry.instance.registered?(path)
      else
        @generated_pages.include?(path)
      end
    end
    
    def mark_as_generated(path)
      if defined?(Jekyll::PageRegistry) && @site.config['page_registry']
        Jekyll::PageRegistry.instance.register(path, 'OptimizedMenuPagesGenerator')
      else
        @generated_pages.add(path)
      end
    end
    
    def increment_counter(counter_name)
      @performance_stats.compute(counter_name) { |k, v| (v || 0) + 1 }
    end
    
    def log_performance_stats(execution_time)
      puts "[SitePageGenerator] === Performance Statistics ==="
      puts "[SitePageGenerator] Total execution time: #{execution_time.round(2)}s"
      puts "[SitePageGenerator] Language pages: #{@performance_stats[:language_pages] || 0}"
      puts "[SitePageGenerator] Category pages: #{@performance_stats[:category_pages] || 0}"
      puts "[SitePageGenerator] Subcategory pages: #{@performance_stats[:subcategory_pages] || 0}"
      puts "[SitePageGenerator] Section pages: #{@performance_stats[:section_pages] || 0}"
      puts "[SitePageGenerator] Thread pool max threads: #{@thread_pool.max_length}"
      puts "[SitePageGenerator] ================================="
      puts "[SitePageGenerator] SitePageGenerator finished in #{execution_time.round(2)}s"
    end
    
    def log_info(message)
      puts "[SitePageGenerator] #{message}"
    end
    
    def log_debug(message)
      puts "[SitePageGenerator] DEBUG: #{message}" if @site.config['debug']
    end
    
    def log_error(message)
      puts "[SitePageGenerator] ERROR: #{message}"
    end
  end
end

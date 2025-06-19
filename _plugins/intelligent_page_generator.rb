require 'fileutils'
require 'date'
require 'set'
require 'concurrent-ruby'
require 'benchmark'
require 'yaml'

module Jekyll
  class IntelligentPageGenerator < Generator
    safe true
    priority :highest
    
    def initialize(config = {})
      super
      @page_cache = Concurrent::Map.new
      @template_cache = Concurrent::Map.new
      @performance_stats = Concurrent::Map.new
      @thread_pool = nil
      @mutex = Mutex.new
      @generated_pages = Set.new
    end
    
    def generate(site)
      start_time = Time.now
      
      # Skip if disabled
      unless site.config['enable_intelligent_page_generation']
        log_info "Intelligent page generation is disabled in _config.yml"
        return
      end
      
      log_info "Starting intelligent page generation with advanced batching..."
      
      @site = site
      
      # Initialize thread pool
      cpu_count = Concurrent.processor_count
      @thread_pool = Concurrent::ThreadPoolExecutor.new(
        min_threads: 2,
        max_threads: [cpu_count, 12].min,
        max_queue: cpu_count * 6,
        fallback_policy: :caller_runs
      )
      
      begin
        # Preload all templates and data
        preload_system_resources
        
        # Generate pages intelligently
        generate_missing_pages
        generate_maintenance_pages
        generate_api_endpoints
        
        # Wait for completion
        @thread_pool.shutdown
        @thread_pool.wait_for_termination(120)
        
      rescue => e
        log_error "Error in IntelligentPageGenerator: #{e.message}"
        log_error e.backtrace.join("\n")
      ensure
        @thread_pool&.kill if @thread_pool&.running?
      end
      
      end_time = Time.now
      total_time = end_time - start_time
      
      log_performance_stats(total_time)
      log_info "IntelligentPageGenerator finished in #{total_time.round(2)}s"
    end
    
    private
    
    def preload_system_resources
      log_info "Preloading system resources..."
      
      # Load page templates
      template_files = [
        'search-page.html',
        'category-page.html',
        'maintenance-page.html',
        'under-construction.html',
        'api-endpoint.json'
      ]
      
      template_files.each do |filename|
        template_path = File.join(@site.source, '_includes', 'templates', filename)
        if File.exist?(template_path)
          @template_cache[filename] = File.read(template_path)
        else
          @template_cache[filename] = generate_default_template(filename)
        end
      end
      
      # Cache language data
      @site.data.each do |lang_code, lang_data|
        @page_cache["lang_#{lang_code}"] = lang_data
      end
      
      log_info "System resources preloaded successfully"
    end
    
    def generate_missing_pages
      tasks = []
      
      @site.config['languages'].each do |language|
        lang_code = language['code']
        
        # Essential pages for each language
        essential_pages = [
          { path: "#{lang_code}/search/index.html", type: 'search' },
          { path: "#{lang_code}/categories/index.html", type: 'categories' },
          { path: "#{lang_code}/contribute/index.html", type: 'contribute' },
          { path: "#{lang_code}/help/index.html", type: 'help' },
          { path: "#{lang_code}/report-issues/index.html", type: 'report-issues' },
          { path: "#{lang_code}/about/index.html", type: 'about' },
          { path: "#{lang_code}/mission/index.html", type: 'mission' },
          { path: "#{lang_code}/content-policies/index.html", type: 'content-policies' },
          { path: "#{lang_code}/random-resource/index.html", type: 'random-resource' },
          { path: "#{lang_code}/recent-changes/index.html", type: 'recent-changes' },
          { path: "#{lang_code}/popular/index.html", type: 'popular' }
        ]
        
        essential_pages.each do |page_info|
          unless page_exists?(page_info[:path])
            tasks << create_page_task(page_info[:path], page_info[:type], lang_code)
          end
        end
        
        # Generate category structure pages
        lang_data = @site.data[lang_code]
        if lang_data && lang_data['menu']
          lang_data['menu'].each do |category|
            tasks << create_category_task(category, lang_code)
            
            if category['children']
              category['children'].each do |subcategory|
                tasks << create_subcategory_task(category, subcategory, lang_code)
                
                if subcategory['children']
                  subcategory['children'].each do |section|
                    tasks << create_section_task(category, subcategory, section, lang_code)
                  end
                end
              end
            end
          end
        end
      end
      
      # Execute tasks in batches
      execute_tasks_in_batches(tasks, "missing pages")
    end
    
    def generate_maintenance_pages
      tasks = []
      
      # Under construction pages for known broken routes
      broken_routes = [
        'en-US/academics/formal-sciences',
        'en-US/academics/natural-sciences',
        'en-US/academics/social-sciences',
        'en-US/academics/professions-and-applied-sciences',
        'pt-BR/academics/ciencias-formais',
        'pt-BR/academics/ciencias-naturais',
        'pt-BR/academics/ciencias-sociais'
      ]
      
      broken_routes.each do |route|
        page_path = "#{route}/index.html"
        unless page_exists?(page_path)
          tasks << create_maintenance_task(page_path, 'under-construction')
        end
      end
      
      execute_tasks_in_batches(tasks, "maintenance pages")
    end
    
    def generate_api_endpoints
      tasks = []
      
      @site.config['languages'].each do |language|
        lang_code = language['code']
        api_prefix = lang_code.downcase.gsub('-', '-')
        
        # Core API endpoints
        api_endpoints = [
          { path: "api/#{api_prefix}/search.json", type: 'search-api' },
          { path: "api/#{api_prefix}/stats.json", type: 'stats-api' },
          { path: "api/#{api_prefix}/resources.json", type: 'resources-api' },
          { path: "api/#{api_prefix}/featured.json", type: 'featured-api' },
          { path: "api/#{api_prefix}/recent.json", type: 'recent-api' }
        ]
        
        api_endpoints.each do |endpoint|
          unless api_exists?(endpoint[:path])
            tasks << create_api_task(endpoint[:path], endpoint[:type], lang_code)
          end
        end
      end
      
      execute_tasks_in_batches(tasks, "API endpoints")
    end
    
    def create_page_task(path, type, lang_code)
      proc do
        begin
          create_standard_page(path, type, lang_code)
          increment_counter(:standard_pages)
        rescue => e
          log_error "Error creating page #{path}: #{e.message}"
        end
      end
    end
    
    def create_category_task(category, lang_code)
      proc do
        begin
          create_category_page(category, lang_code)
          increment_counter(:category_pages)
        rescue => e
          log_error "Error creating category page: #{e.message}"
        end
      end
    end
    
    def create_subcategory_task(category, subcategory, lang_code)
      proc do
        begin
          create_subcategory_page(category, subcategory, lang_code)
          increment_counter(:subcategory_pages)
        rescue => e
          log_error "Error creating subcategory page: #{e.message}"
        end
      end
    end
    
    def create_section_task(category, subcategory, section, lang_code)
      proc do
        begin
          create_section_page(category, subcategory, section, lang_code)
          increment_counter(:section_pages)
        rescue => e
          log_error "Error creating section page: #{e.message}"
        end
      end
    end
    
    def create_maintenance_task(path, type)
      proc do
        begin
          create_maintenance_page(path, type)
          increment_counter(:maintenance_pages)
        rescue => e
          log_error "Error creating maintenance page #{path}: #{e.message}"
        end
      end
    end
    
    def create_api_task(path, type, lang_code)
      proc do
        begin
          create_api_endpoint(path, type, lang_code)
          increment_counter(:api_endpoints)
        rescue => e
          log_error "Error creating API endpoint #{path}: #{e.message}"
        end
      end
    end
    
    def execute_tasks_in_batches(tasks, description)
      return if tasks.empty?
      
      log_info "Executing #{tasks.length} #{description} tasks..."
      
      batch_size = [@thread_pool.max_length, 25].min
      tasks.each_slice(batch_size) do |batch|
        futures = batch.map { |task| @thread_pool.post(&task) }
        futures.each(&:wait!)
      end
    end
    
    def create_standard_page(path, type, lang_code)
      return if already_generated?(path)
      
      template_content = get_page_template(type, lang_code)
      page_data = get_page_data(type, lang_code)
      
      create_page_safely(path, template_content, page_data)
      mark_as_generated(path)
    end
    
    def create_category_page(category, lang_code)
      path = normalize_path("#{category['path']}/index.html")
      return if already_generated?(path)
      
      page_data = {
        'layout' => 'category',
        'title' => category['title'],
        'lang' => lang_code,
        'description' => category['description'] || "Explore #{category['title']} resources",
        'category_key' => category['key'] || category['title'].downcase.gsub(/\s+/, '-'),
        'last_updated' => Time.now.strftime("%Y-%m-%d"),
        'show_discussion' => true
      }
      
      create_page_safely(path, '', page_data)
      mark_as_generated(path)
    end
    
    def create_subcategory_page(category, subcategory, lang_code)
      path = normalize_path("#{subcategory['path']}/index.html")
      return if already_generated?(path)
      
      page_data = {
        'layout' => 'subcategory',
        'title' => subcategory['title'],
        'lang' => lang_code,
        'description' => subcategory['description'] || "Explore #{subcategory['title']} resources",
        'parent_category' => category['title'],
        'subcategory_key' => subcategory['key'] || subcategory['title'].downcase.gsub(/\s+/, '-'),
        'last_updated' => Time.now.strftime("%Y-%m-%d"),
        'show_discussion' => true
      }
      
      create_page_safely(path, '', page_data)
      mark_as_generated(path)
    end
    
    def create_section_page(category, subcategory, section, lang_code)
      path = normalize_path("#{section['path']}/index.html")
      return if already_generated?(path)
      
      page_data = {
        'layout' => 'section',
        'title' => section['title'],
        'lang' => lang_code,
        'description' => section['description'] || "Explore #{section['title']} resources",
        'parent_category' => category['title'],
        'parent_subcategory' => subcategory['title'],
        'section_key' => section['key'] || section['title'].downcase.gsub(/\s+/, '-'),
        'last_updated' => Time.now.strftime("%Y-%m-%d"),
        'show_discussion' => true
      }
      
      create_page_safely(path, '', page_data)
      mark_as_generated(path)
    end
    
    def create_maintenance_page(path, type)
      return if already_generated?(path)
      
      page_data = {
        'layout' => 'maintenance',
        'title' => 'Under Construction',
        'description' => 'This page is currently under construction',
        'maintenance_type' => type,
        'last_updated' => Time.now.strftime("%Y-%m-%d"),
        'show_discussion' => false
      }
      
      template_content = @template_cache['under-construction.html']
      create_page_safely(path, template_content, page_data)
      mark_as_generated(path)
    end
    
    def create_api_endpoint(path, type, lang_code)
      return if already_generated?(path)
      
      case type
      when 'search-api'
        create_search_api(path, lang_code)
      when 'stats-api'
        create_stats_api(path, lang_code)
      when 'resources-api'
        create_resources_api(path, lang_code)
      when 'featured-api'
        create_featured_api(path, lang_code)
      when 'recent-api'
        create_recent_api(path, lang_code)
      end
    end
    
    def create_search_api(path, lang_code)
      # Implementation for search API
      api_content = generate_search_api_content(lang_code)
      create_api_file(path, api_content)
    end
    
    def create_stats_api(path, lang_code)
      # Implementation for stats API
      api_content = generate_stats_api_content(lang_code)
      create_api_file(path, api_content)
    end
    
    def create_resources_api(path, lang_code)
      # Implementation for resources API
      api_content = generate_resources_api_content(lang_code)
      create_api_file(path, api_content)
    end
    
    def create_featured_api(path, lang_code)
      # Implementation for featured API
      api_content = generate_featured_api_content(lang_code)
      create_api_file(path, api_content)
    end
    
    def create_recent_api(path, lang_code)
      # Implementation for recent changes API
      api_content = generate_recent_api_content(lang_code)
      create_api_file(path, api_content)
    end
    
    def create_api_file(path, content)
      full_path = File.join(@site.dest, path)
      FileUtils.mkdir_p(File.dirname(full_path))
      File.write(full_path, content)
      mark_as_generated(path)
    end
    
    def generate_search_api_content(lang_code)
      # Generate search index JSON
      {
        "api_version" => "2.0",
        "language" => lang_code,
        "generated_at" => Time.now.iso8601,
        "resources" => extract_searchable_resources(lang_code)
      }.to_json
    end
    
    def generate_stats_api_content(lang_code)
      # Generate statistics JSON
      {
        "api_version" => "2.0",
        "language" => lang_code,
        "generated_at" => Time.now.iso8601,
        "stats" => {
          "resources_count" => "10,000+",
          "contributors_count" => "5,000+",
          "categories_count" => count_categories(lang_code),
          "last_updated" => Time.now.strftime("%Y-%m-%d")
        }
      }.to_json
    end
    
    def generate_resources_api_content(lang_code)
      # Generate all resources JSON
      {
        "api_version" => "2.0",
        "language" => lang_code,
        "generated_at" => Time.now.iso8601,
        "resources" => extract_all_resources(lang_code)
      }.to_json
    end
    
    def generate_featured_api_content(lang_code)
      # Generate featured resources JSON
      {
        "api_version" => "2.0",
        "language" => lang_code,
        "generated_at" => Time.now.iso8601,
        "featured_resources" => extract_featured_resources(lang_code)
      }.to_json
    end
    
    def generate_recent_api_content(lang_code)
      # Generate recent changes JSON
      {
        "api_version" => "2.0",
        "language" => lang_code,
        "generated_at" => Time.now.iso8601,
        "recent_changes" => extract_recent_changes(lang_code)
      }.to_json
    end
    
    def extract_searchable_resources(lang_code)
      # Extract and format resources for search
      resources = []
      lang_data = @site.data[lang_code]
      
      if lang_data
        # Process each category for resources
        # This is a simplified implementation
        lang_data.each do |key, value|
          if value.is_a?(Hash) && value['resources']
            value['resources'].each do |resource|
              resources << format_resource_for_search(resource, key)
            end
          end
        end
      end
      
      resources
    end
    
    def extract_all_resources(lang_code)
      # Similar to searchable but with full data
      extract_searchable_resources(lang_code)
    end
    
    def extract_featured_resources(lang_code)
      # Extract featured resources
      all_resources = extract_searchable_resources(lang_code)
      all_resources.select { |r| r['featured'] == true }.take(10)
    end
    
    def extract_recent_changes(lang_code)
      # Generate mock recent changes data
      [
        {
          "title" => "Updated Business Resources",
          "description" => "Added new startup and entrepreneurship resources",
          "category" => "Business",
          "editor" => "Community",
          "date" => Time.now.strftime("%Y-%m-%d"),
          "changes" => 5
        }
      ]
    end
    
    def format_resource_for_search(resource, category)
      {
        "title" => resource['title'] || resource['name'],
        "description" => resource['description'],
        "url" => resource['url'],
        "category" => category,
        "type" => resource['type'] || 'resource',
        "tags" => resource['tags'] || [],
        "language" => resource['language'] || 'en',
        "last_updated" => resource['last_updated'] || Time.now.strftime("%Y-%m-%d"),
        "featured" => resource['featured'] || false
      }
    end
    
    def count_categories(lang_code)
      lang_data = @site.data[lang_code]
      return 0 unless lang_data && lang_data['menu']
      lang_data['menu'].length
    end
    
    def get_page_template(type, lang_code)
      case type
      when 'search'
        generate_search_page_template(lang_code)
      when 'categories'
        generate_categories_page_template(lang_code)
      when 'contribute'
        generate_contribute_page_template(lang_code)
      when 'help'
        generate_help_page_template(lang_code)
      when 'about'
        generate_about_page_template(lang_code)
      when 'mission'
        generate_mission_page_template(lang_code)
      when 'content-policies'
        generate_content_policies_template(lang_code)
      when 'report-issues'
        generate_report_issues_template(lang_code)
      when 'random-resource'
        generate_random_resource_template(lang_code)
      when 'recent-changes'
        generate_recent_changes_template(lang_code)
      when 'popular'
        generate_popular_template(lang_code)
      else
        @template_cache['default-page.html'] || ''
      end
    end
    
    def get_page_data(type, lang_code)
      base_data = {
        'layout' => 'default',
        'lang' => lang_code,
        'last_updated' => Time.now.strftime("%Y-%m-%d"),
        'show_discussion' => true
      }
      
      case type
      when 'search'
        base_data.merge({
          'title' => lang_code == 'pt-BR' ? 'Buscar Recursos' : 'Search Resources',
          'description' => lang_code == 'pt-BR' ? 'Busque em nossa biblioteca de recursos' : 'Search our resource library'
        })
      when 'categories'
        base_data.merge({
          'title' => lang_code == 'pt-BR' ? 'Categorias' : 'Categories',
          'description' => lang_code == 'pt-BR' ? 'Explore todas as categorias' : 'Explore all categories'
        })
      else
        base_data.merge({
          'title' => type.humanize,
          'description' => "#{type.humanize} page"
        })
      end
    end
    
    # Template generators (simplified implementations)
    def generate_search_page_template(lang_code)
      # Return a basic search page template
      "<!-- Search page for #{lang_code} -->\n<h1>Search</h1>\n<p>Search functionality coming soon.</p>"
    end
    
    def generate_categories_page_template(lang_code)
      # Return a basic categories page template
      "<!-- Categories page for #{lang_code} -->\n<h1>Categories</h1>\n<p>Categories overview coming soon.</p>"
    end
    
    def generate_contribute_page_template(lang_code)
      # Return a basic contribute page template
      "<!-- Contribute page for #{lang_code} -->\n<h1>Contribute</h1>\n<p>Contribution guidelines coming soon.</p>"
    end
    
    def generate_help_page_template(lang_code)
      # Return a basic help page template
      "<!-- Help page for #{lang_code} -->\n<h1>Help</h1>\n<p>Help documentation coming soon.</p>"
    end
    
    def generate_about_page_template(lang_code)
      "<!-- About page for #{lang_code} -->\n<h1>About</h1>\n<p>About IPLibrary coming soon.</p>"
    end
    
    def generate_mission_page_template(lang_code)
      "<!-- Mission page for #{lang_code} -->\n<h1>Mission</h1>\n<p>Our mission statement coming soon.</p>"
    end
    
    def generate_content_policies_template(lang_code)
      "<!-- Content policies for #{lang_code} -->\n<h1>Content Policies</h1>\n<p>Content policies coming soon.</p>"
    end
    
    def generate_report_issues_template(lang_code)
      "<!-- Report issues for #{lang_code} -->\n<h1>Report Issues</h1>\n<p>Issue reporting coming soon.</p>"
    end
    
    def generate_random_resource_template(lang_code)
      "<!-- Random resource for #{lang_code} -->\n<h1>Random Resource</h1>\n<p>Random resource feature coming soon.</p>"
    end
    
    def generate_recent_changes_template(lang_code)
      "<!-- Recent changes for #{lang_code} -->\n<h1>Recent Changes</h1>\n<p>Recent changes coming soon.</p>"
    end
    
    def generate_popular_template(lang_code)
      "<!-- Popular resources for #{lang_code} -->\n<h1>Popular</h1>\n<p>Popular resources coming soon.</p>"
    end
    
    def generate_default_template(filename)
      case filename
      when 'under-construction.html'
        "<!-- Under construction template -->\n<h1>Under Construction</h1>\n<p>This page is currently being developed.</p>"
      else
        "<!-- Default template -->\n<h1>Page</h1>\n<p>Content coming soon.</p>"
      end
    end
    
    # Utility methods
    def create_page_safely(page_path, content, data)
      @mutex.synchronize do
        return if @generated_pages.include?(page_path)
        
        page = Jekyll::Page.new(@site, @site.source, File.dirname(page_path), File.basename(page_path))
        page.content = content
        page.data.merge!(data)
        
        @site.pages << page
        @generated_pages.add(page_path)
      end
    end
    
    def normalize_path(path)
      path.chomp('/').gsub(/\/+/, '/')
    end
    
    def page_exists?(path)
      @site.pages.any? { |page| page.url == "/#{path}" } ||
      File.exist?(File.join(@site.source, path))
    end
    
    def api_exists?(path)
      File.exist?(File.join(@site.source, path))
    end
    
    def already_generated?(path)
      @generated_pages.include?(path)
    end
    
    def mark_as_generated(path)
      @generated_pages.add(path)
    end
    
    def increment_counter(counter_name)
      @performance_stats.compute(counter_name) { |k, v| (v || 0) + 1 }
    end
    
    def log_performance_stats(total_time)
      log_info "=== Intelligent Page Generation Statistics ==="
      log_info "Total time: #{total_time.round(2)}s"
      log_info "Standard pages: #{@performance_stats[:standard_pages] || 0}"
      log_info "Category pages: #{@performance_stats[:category_pages] || 0}"
      log_info "Subcategory pages: #{@performance_stats[:subcategory_pages] || 0}"
      log_info "Section pages: #{@performance_stats[:section_pages] || 0}"
      log_info "Maintenance pages: #{@performance_stats[:maintenance_pages] || 0}"
      log_info "API endpoints: #{@performance_stats[:api_endpoints] || 0}"
      log_info "Total pages generated: #{@generated_pages.size}"
      log_info "============================================"
    end
    
    def log_info(message)
      puts "[IntelligentPageGenerator] #{message}"
    end
    
    def log_error(message)
      puts "[IntelligentPageGenerator] ERROR: #{message}"
    end
    
    def log_debug(message)
      puts "[IntelligentPageGenerator] DEBUG: #{message}" if @site.config['debug']
    end
  end
end 

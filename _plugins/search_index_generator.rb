require 'json'
require 'digest'
require 'fileutils'

module Jekyll
  class SearchIndexGenerator < Generator
    safe true
    priority :low  # Run after all other generators
    
    def generate(site)
      puts "Starting SearchIndexGenerator..."
      @site = site
      
      # Generate search indexes for each language
      @site.config['languages'].each do |lang|
        lang_code = lang['code']
        generate_search_index(lang_code)
        generate_analytics_data(lang_code)
      end
      
      # Generate global search data
      generate_global_search_data
      
      puts "SearchIndexGenerator finished."
    end
    
    private
    
    def generate_search_index(lang_code)
      puts "Generating search index for #{lang_code}..."
      
      search_data = {
        'language' => lang_code,
        'generated_at' => Time.now.iso8601,
        'version' => '1.0',
        'total_entries' => 0,
        'categories' => [],
        'sections' => [],
        'resources' => [],
        'full_text_index' => {}
      }
      
      # Get language menu data
      lang_data = @site.data[lang_code]
      return unless lang_data && lang_data['menu']
      
      # Process menu structure
      lang_data['menu'].each do |category|
        category_data = extract_category_data(lang_code, category)
        search_data['categories'] << category_data
        
        # Process subcategories and sections
        if category['children']
          category['children'].each do |subcategory|
            if subcategory['children']
              subcategory['children'].each do |section|
                section_data = extract_section_data(lang_code, category, subcategory, section)
                search_data['sections'] << section_data
                
                # Add to full-text index
                add_to_full_text_index(search_data['full_text_index'], section_data)
              end
            end
          end
        end
      end
      
      # Add resources from data files
      add_resources_to_index(lang_code, search_data)
      
      # Calculate total entries
      search_data['total_entries'] = search_data['categories'].size + 
                                    search_data['sections'].size + 
                                    search_data['resources'].size
      
      # Optimize index for search performance
      optimize_search_index(search_data)
      
      # Write search index to API directory
      output_path = File.join(@site.dest, 'api', 'search', "#{lang_code}.json")
      FileUtils.mkdir_p(File.dirname(output_path))
      File.write(output_path, JSON.generate(search_data))
      
      puts "Generated search index for #{lang_code}: #{search_data['total_entries']} entries"
    end
    
    def extract_category_data(lang_code, category)
      {
        'id' => generate_id(category['path']),
        'type' => 'category',
        'title' => category['title'],
        'path' => category['path'],
        'url' => category['path'],
        'language' => lang_code,
        'description' => "Explore resources in #{category['title']}",
        'keywords' => generate_keywords(category['title']),
        'search_weight' => 10,
        'subcategories_count' => category['children'] ? category['children'].size : 0,
        'last_updated' => Time.now.strftime("%Y-%m-%d")
      }
    end
    
    def extract_section_data(lang_code, category, subcategory, section)
      {
        'id' => generate_id(section['path']),
        'type' => 'section',
        'title' => section['title'],
        'path' => section['path'],
        'url' => section['path'],
        'language' => lang_code,
        'description' => "Learn about #{section['title']} in #{subcategory['title']}",
        'keywords' => generate_keywords([section['title'], subcategory['title'], category['title']]),
        'search_weight' => 8,
        'category' => {
          'title' => category['title'],
          'path' => category['path']
        },
        'subcategory' => {
          'title' => subcategory['title'],
          'path' => subcategory['path']
        },
        'breadcrumb' => "#{category['title']} > #{subcategory['title']} > #{section['title']}",
        'last_updated' => Time.now.strftime("%Y-%m-%d")
      }
    end
    
    def add_resources_to_index(lang_code, search_data)
      # Look for resource data files
      resource_dirs = Dir.glob(File.join(@site.source, '_data', lang_code, '*'))
      
      resource_dirs.each do |dir|
        next unless File.directory?(dir)
        
        category_name = File.basename(dir)
        resource_files = Dir.glob(File.join(dir, '*.yaml')) + Dir.glob(File.join(dir, '*.yml'))
        
        resource_files.each do |file|
          begin
            resources = YAML.load_file(file)
            next unless resources.is_a?(Array)
            
            resources.each do |resource|
              next unless resource.is_a?(Hash) && resource['title']
              
              resource_data = {
                'id' => generate_id("#{category_name}/#{resource['title']}"),
                'type' => 'resource',
                'title' => resource['title'],
                'url' => resource['url'] || resource['link'],
                'description' => resource['description'] || "Resource in #{category_name}",
                'category' => category_name,
                'tags' => resource['tags'] || [],
                'keywords' => generate_keywords([resource['title'], category_name]),
                'search_weight' => 5,
                'language' => lang_code,
                'last_updated' => resource['updated'] || Time.now.strftime("%Y-%m-%d")
              }
              
              search_data['resources'] << resource_data
              add_to_full_text_index(search_data['full_text_index'], resource_data)
            end
          rescue => e
            puts "Warning: Could not process resource file #{file}: #{e.message}"
          end
        end
      end
    end
    
    def add_to_full_text_index(index, item)
      # Create searchable text from item
      searchable_text = [
        item['title'],
        item['description'],
        item['keywords'],
        item['breadcrumb']
      ].compact.join(' ').downcase
      
      # Extract words and create index
      words = searchable_text.gsub(/[^\w\s]/, '').split(/\s+/).uniq
      
      words.each do |word|
        next if word.length < 2 || is_stopword?(word)
        
        index[word] ||= []
        index[word] << {
          'id' => item['id'],
          'type' => item['type'],
          'weight' => item['search_weight']
        }
      end
    end
    
    def optimize_search_index(search_data)
      # Sort items by search weight and relevance
      search_data['categories'].sort_by! { |c| -c['search_weight'] }
      search_data['sections'].sort_by! { |s| -s['search_weight'] }
      search_data['resources'].sort_by! { |r| -r['search_weight'] }
      
      # Limit full-text index entries to prevent bloat
      search_data['full_text_index'].each do |word, entries|
        if entries.size > 100
          # Keep only the highest weighted entries
          search_data['full_text_index'][word] = entries
            .sort_by { |e| -e['weight'] }
            .first(100)
        end
      end
    end
    
    def generate_analytics_data(lang_code)
      analytics_data = {
        'language' => lang_code,
        'generated_at' => Time.now.iso8601,
        'popular_searches' => [],
        'trending_categories' => [],
        'recent_updates' => [],
        'search_suggestions' => generate_search_suggestions(lang_code)
      }
      
      # Write analytics data
      output_path = File.join(@site.dest, 'api', 'analytics', "#{lang_code}.json")
      FileUtils.mkdir_p(File.dirname(output_path))
      File.write(output_path, JSON.generate(analytics_data))
    end
    
    def generate_global_search_data
      global_data = {
        'generated_at' => Time.now.iso8601,
        'available_languages' => @site.config['languages'].map { |l| l['code'] },
        'search_endpoints' => {
          'index' => '/api/search/{lang}.json',
          'analytics' => '/api/analytics/{lang}.json',
          'suggestions' => '/api/search/suggestions/{lang}.json'
        },
        'search_config' => {
          'min_query_length' => 2,
          'max_results' => 50,
          'debounce_delay' => 300,
          'highlight_matches' => true
        }
      }
      
      output_path = File.join(@site.dest, 'api', 'search', 'config.json')
      FileUtils.mkdir_p(File.dirname(output_path))
      File.write(output_path, JSON.generate(global_data))
    end
    
    def generate_search_suggestions(lang_code)
      suggestions = []
      
      # Get common category and section names
      lang_data = @site.data[lang_code]
      return suggestions unless lang_data && lang_data['menu']
      
      lang_data['menu'].each do |category|
        suggestions << {
          'text' => category['title'],
          'type' => 'category',
          'frequency' => 10
        }
        
        if category['children']
          category['children'].each do |subcategory|
            suggestions << {
              'text' => subcategory['title'],
              'type' => 'subcategory',
              'frequency' => 8
            }
            
            if subcategory['children']
              subcategory['children'].each do |section|
                suggestions << {
                  'text' => section['title'],
                  'type' => 'section',
                  'frequency' => 6
                }
              end
            end
          end
        end
      end
      
      # Sort by frequency and limit
      suggestions.sort_by { |s| -s['frequency'] }.first(100)
    end
    
    def generate_keywords(text)
      return [] unless text
      
      words = text.is_a?(Array) ? text.join(' ') : text.to_s
      keywords = words.downcase
        .gsub(/[^\w\s]/, '')
        .split(/\s+/)
        .uniq
        .reject { |w| w.length < 3 || is_stopword?(w) }
      
      # Add common variations and synonyms
      enhanced_keywords = keywords.dup
      keywords.each do |keyword|
        enhanced_keywords.concat(generate_synonyms(keyword))
      end
      
      enhanced_keywords.uniq.sort
    end
    
    def generate_synonyms(word)
      synonyms = {
        'development' => ['programming', 'coding', 'software'],
        'business' => ['commerce', 'enterprise', 'corporate'],
        'design' => ['visual', 'creative', 'artistic'],
        'marketing' => ['advertising', 'promotion', 'branding'],
        'computing' => ['technology', 'computer', 'digital'],
        'photography' => ['photo', 'image', 'visual']
      }
      
      synonyms[word] || []
    end
    
    def generate_id(text)
      Digest::MD5.hexdigest(text.to_s)[0, 8]
    end
    
    def is_stopword?(word)
      stopwords = %w[
        the and or but in on at to for of with by from up about into over after
        a an as be is was are were been being have has had do does did will would
        could should may might must can i you he she it we they them their there
        this that these those all any some many much more most other such very
        only just also even still yet however therefore thus hence whereas while
      ]
      stopwords.include?(word.downcase)
    end
  end
end
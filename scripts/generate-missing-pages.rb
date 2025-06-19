#!/usr/bin/env ruby

require 'yaml'
require 'fileutils'
require 'date'

class PageGenerator
  def initialize
    @languages = ['en-US', 'pt-BR']
    @created_pages = []
    @updated_pages = []
  end
  
  def run
    puts "🚀 Starting IPLibrary Page Generator..."
    
    @languages.each do |lang|
      generate_pages_for_language(lang)
      generate_essential_pages(lang)
    end
    
    generate_api_endpoints
    
    report_results
  end
  
  private
  
  def extract_key_from_path(path)
    # Extract key from path like "/en-US/business/" -> "business"
    path.split('/').reject(&:empty?).last
  end
  
  def generate_pages_for_language(lang)
    puts "\n📚 Generating pages for #{lang}..."
    
    menu_file = "_data/#{lang}/menu.yaml"
    unless File.exist?(menu_file)
      puts "⚠️  Menu file not found: #{menu_file}"
      return
    end
    
    menu_data = YAML.load_file(menu_file)
    
    menu_data.each do |category|
      # Extract key from path
      category['key'] = extract_key_from_path(category['path'])
      
      generate_category_page(lang, category)
      
      if category['children']
        category['children'].each do |subcategory|
          subcategory['key'] = extract_key_from_path(subcategory['path'])
          generate_subcategory_page(lang, category, subcategory)
          
          if subcategory['children']
            subcategory['children'].each do |section|
              section['key'] = extract_key_from_path(section['path'])
              generate_section_page(lang, category, subcategory, section)
            end
          end
        end
      end
    end
  end
  
  def generate_essential_pages(lang)
    puts "\n🏗️  Generating essential pages for #{lang}..."
    
    essential_pages = [
      'community-portal',
      'content-policies', 
      'about',
      'mission',
      'report-issues',
      'add-language',
      'popular'
    ]
    
    essential_pages.each do |page_key|
      page_path = "#{lang}/#{page_key}/index.html"
      
      next if File.exist?(page_path)
      
      FileUtils.mkdir_p(File.dirname(page_path))
      
      content = essential_page_template(lang, page_key)
      File.write(page_path, content)
      @created_pages << page_path
      
      puts "✅ Created essential page: #{page_path}"
    end
  end
  
  def generate_category_page(lang, category)
    page_path = "#{lang}/#{category['key']}/index.html"
    
    return if File.exist?(page_path)
    
    FileUtils.mkdir_p(File.dirname(page_path))
    
    content = category_page_template(lang, category)
    File.write(page_path, content)
    @created_pages << page_path
    
    puts "✅ Created category page: #{page_path}"
  end
  
  def generate_subcategory_page(lang, category, subcategory)
    page_path = "#{lang}/#{category['key']}/#{subcategory['key']}/index.html"
    
    return if File.exist?(page_path)
    
    FileUtils.mkdir_p(File.dirname(page_path))
    
    content = subcategory_page_template(lang, category, subcategory)
    File.write(page_path, content)
    @created_pages << page_path
    
    puts "✅ Created subcategory page: #{page_path}"
  end
  
  def generate_section_page(lang, category, subcategory, section)
    page_path = "#{lang}/#{category['key']}/#{subcategory['key']}/#{section['key']}.html"
    
    return if File.exist?(page_path)
    
    FileUtils.mkdir_p(File.dirname(page_path))
    
    content = section_page_template(lang, category, subcategory, section)
    File.write(page_path, content)
    @created_pages << page_path
    
    puts "✅ Created section page: #{page_path}"
  end
  
  def category_page_template(lang, category)
    title_pt = lang == 'pt-BR' ? category['title'] : category['title']
    desc_pt = lang == 'pt-BR' ? "Explore recursos de #{category['title'].downcase}" : "Explore #{category['title'].downcase} resources"
    
    <<~CONTENT
      ---
      layout: category
      title: #{title_pt}
      lang: #{lang}
      description: #{desc_pt}
      category_key: #{category['key']}
      category_color: #{category['color'] || 'blue'}
      permalink: /#{lang}/#{category['key']}/
      subcategories:
      #{category['children'] ? category['children'].map { |sub| "  - title: #{sub['title']}\n    key: #{sub['key']}\n    path: /#{lang}/#{category['key']}/#{sub['key']}/\n    icon: #{sub['icon'] || 'folder'}\n    description: #{sub['description'] || 'Explore resources in this subcategory'}\n    resource_types: [\"Blogs & Sites\", \"Courses\", \"Companies\", \"Publications\"]" }.join("\n") : ""}
      featured_resources:
        - title: "Featured Resource 1"
          description: "A great resource in this category"
          url: "https://example.com"
          type: "Website"
          type_color: "blue"
          last_updated: "#{Date.today}"
        - title: "Featured Resource 2"
          description: "Another excellent resource"
          url: "https://example.com"
          type: "Course"
          type_color: "green"
          last_updated: "#{Date.today}"
      related_categories:
        - title: "Related Category"
          path: "/#{lang}/related/"
          icon: "folder"
      resource_count: "100+"
      total_resources: "150+"
      last_updated: "#{Date.today}"
      ---
      
      <!-- Additional content will be loaded via HTMX and components -->
    CONTENT
  end
  
  def subcategory_page_template(lang, category, subcategory)
    title_pt = lang == 'pt-BR' ? subcategory['title'] : subcategory['title']
    desc_pt = lang == 'pt-BR' ? "Recursos de #{subcategory['title'].downcase} em #{category['title'].downcase}" : "#{subcategory['title']} resources in #{category['title'].downcase}"
    
    <<~CONTENT
      ---
      layout: category
      title: #{title_pt}
      lang: #{lang}
      description: #{desc_pt}
      category_key: #{category['key']}
      subcategory_key: #{subcategory['key']}
      category_title: #{category['title']}
      category_path: /#{lang}/#{category['key']}/
      category_color: #{category['color'] || 'blue'}
      permalink: /#{lang}/#{category['key']}/#{subcategory['key']}/
      subcategories:
      #{subcategory['children'] ? subcategory['children'].map { |section| "  - title: #{section['title']}\n    key: #{section['key']}\n    path: /#{lang}/#{category['key']}/#{subcategory['key']}/#{section['key']}.html\n    icon: #{section['icon'] || 'file'}\n    description: #{section['description'] || 'Resource section'}\n    resource_types: [\"#{section['title']}\"]" }.join("\n") : ""}
      featured_resources:
        - title: "Featured #{subcategory['title']} Resource"
          description: "Top resource in #{subcategory['title']}"
          url: "https://example.com"
          type: "Website"
          type_color: "blue"
          last_updated: "#{Date.today}"
      related_categories:
        - title: #{category['title']}
          path: /#{lang}/#{category['key']}/
          icon: "#{category['icon'] || 'folder'}"
      resource_count: "50+"
      total_resources: "75+"
      last_updated: "#{Date.today}"
      ---
      
      <!-- Subcategory content will be loaded via HTMX and components -->
    CONTENT
  end
  
  def section_page_template(lang, category, subcategory, section)
    title_pt = lang == 'pt-BR' ? section['title'] : section['title']
    desc_pt = lang == 'pt-BR' ? "Lista curada de #{section['title'].downcase}" : "Curated list of #{section['title'].downcase}"
    
    <<~CONTENT
      ---
      layout: resource
      title: #{title_pt}
      lang: #{lang}
      description: #{desc_pt}
      category_key: #{category['key']}
      subcategory_key: #{subcategory['key']}
      resource_type: #{section['key']}
      resource_type_title: #{section['title']}
      resource_type_icon: #{section['icon'] || 'file'}
      category_title: #{category['title']}
      category_path: /#{lang}/#{category['key']}/
      subcategory_title: #{subcategory['title']}
      subcategory_path: /#{lang}/#{category['key']}/#{subcategory['key']}/
      category_color: #{category['color'] || 'blue'}
      permalink: /#{lang}/#{category['key']}/#{subcategory['key']}/#{section['key']}.html
      content_type: data_file
      sibling_resource_types:
      #{subcategory['children'] ? subcategory['children'].map { |s| "  - title: #{s['title']}\n    path: /#{lang}/#{category['key']}/#{subcategory['key']}/#{s['key']}.html\n    icon: #{s['icon'] || 'file'}\n    count: \"25+\"" }.join("\n") : ""}
      resource_count: "25+"
      verified_count: "20+"
      pending_count: "5+"
      last_updated: "#{Date.today}"
      edit_url: "https://github.com/your-repo/edit/main/_data/#{lang}/#{category['key']}/#{section['key']}.yaml"
      contribute_url: "/#{lang}/contribute/"
      issue_url: "https://github.com/your-repo/issues/new"
      ---
      
      <!-- Resource data will be loaded from YAML files via HTMX -->
    CONTENT
  end
  
  def essential_page_template(lang, page_key)
    titles = {
      'en-US' => {
        'community-portal' => 'Community Portal',
        'content-policies' => 'Content Policies',
        'about' => 'About IPLibrary',
        'mission' => 'Our Mission',
        'report-issues' => 'Report Issues',
        'add-language' => 'Add Language',
        'popular' => 'Popular Resources'
      },
      'pt-BR' => {
        'community-portal' => 'Portal da Comunidade',
        'content-policies' => 'Políticas de Conteúdo',
        'about' => 'Sobre a IPLibrary',
        'mission' => 'Nossa Missão',
        'report-issues' => 'Reportar Problemas',
        'add-language' => 'Adicionar Idioma',
        'popular' => 'Recursos Populares'
      }
    }
    
    descriptions = {
      'en-US' => {
        'community-portal' => 'Connect with the IPLibrary community',
        'content-policies' => 'Guidelines for contributing content',
        'about' => 'Learn about the IPLibrary project',
        'mission' => 'Our mission and values',
        'report-issues' => 'Report problems or broken links',
        'add-language' => 'Help translate IPLibrary',
        'popular' => 'Most popular and trending resources'
      },
      'pt-BR' => {
        'community-portal' => 'Conecte-se com a comunidade IPLibrary',
        'content-policies' => 'Diretrizes para contribuir com conteúdo',
        'about' => 'Saiba mais sobre o projeto IPLibrary',
        'mission' => 'Nossa missão e valores',
        'report-issues' => 'Relate problemas ou links quebrados',
        'add-language' => 'Ajude a traduzir a IPLibrary',
        'popular' => 'Recursos mais populares e em destaque'
      }
    }
    
    title = titles[lang][page_key]
    description = descriptions[lang][page_key]
    
    content_body = case page_key
    when 'popular'
      <<~BODY
        <!-- Popular Resources Content -->
        <div class="container mx-auto px-4 py-8">
          <h1 class="text-3xl font-bold mb-6">#{title}</h1>
          <p class="text-gray-600 mb-8">#{description}</p>
          
          <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            <!-- Popular resources will be loaded via HTMX -->
            <div class="bg-white rounded-lg shadow-sm border p-6">
              <h3 class="text-lg font-semibold mb-2">Loading popular resources...</h3>
              <p class="text-gray-600">Please wait while we fetch the most popular resources.</p>
            </div>
          </div>
        </div>
      BODY
    when 'about'
      <<~BODY
        <!-- About Content -->
        <div class="container mx-auto px-4 py-8">
          <h1 class="text-3xl font-bold mb-6">#{title}</h1>
          <div class="prose max-w-none">
            <p>#{description}</p>
            <p>#{lang == 'pt-BR' ? 'A IPLibrary é uma enciclopédia gratuita de recursos da internet curados pela comunidade.' : 'IPLibrary is a free encyclopedia of internet resources curated by the community.'}</p>
          </div>
        </div>
      BODY
    else
      <<~BODY
        <!-- #{title} Content -->
        <div class="container mx-auto px-4 py-8">
          <h1 class="text-3xl font-bold mb-6">#{title}</h1>
          <p class="text-gray-600 mb-8">#{description}</p>
          
          <div class="bg-white rounded-lg shadow-sm border p-8">
            <p>#{lang == 'pt-BR' ? 'Esta página está em desenvolvimento. Em breve teremos mais conteúdo aqui!' : 'This page is under development. More content coming soon!'}</p>
          </div>
        </div>
      BODY
    end
    
    <<~CONTENT
      ---
      layout: default
      title: #{title}
      description: #{description}
      lang: #{lang}
      permalink: /#{lang}/#{page_key}/
      ---
      
      #{content_body}
    CONTENT
  end
  
  def generate_api_endpoints
    puts "\n🔌 Generating API endpoints..."
    
    # Create API structure
    api_dir = "api"
    FileUtils.mkdir_p(api_dir)
    
    # API endpoints to create
    api_endpoints = [
      'featured-resources',
      'latest-edits', 
      'new-resources',
      'community-news',
      'active-contributors'
    ]
    
    api_endpoints.each do |endpoint|
      endpoint_dir = "#{api_dir}/#{endpoint}"
      FileUtils.mkdir_p(endpoint_dir)
      
      content = api_endpoint_template(endpoint)
      endpoint_file = "#{endpoint_dir}/index.json"
      
      unless File.exist?(endpoint_file)
        File.write(endpoint_file, content)
        @created_pages << endpoint_file
        puts "✅ Created API endpoint: #{endpoint_file}"
      end
    end
    
    # Fixed random resource API with error handling
    random_api_content = <<~CONTENT
      ---
      layout: null
      ---
      {% assign all_resources = '' | split: '' %}
      {% for lang_data in site.data %}
        {% if lang_data[0] == page.lang %}
          {% for category_data in lang_data[1] %}
            {% unless category_data[0] == 'menu' %}
              {% for resource in category_data[1] %}
                {% assign all_resources = all_resources | push: resource %}
              {% endfor %}
            {% endunless %}
          {% endfor %}
        {% endif %}
      {% endfor %}
      
      {% if all_resources.size > 0 %}
        {% assign random_index = 'now' | date: '%s' | modulo: all_resources.size %}
        {% assign random_resource = all_resources[random_index] %}
      {% else %}
        {% assign random_resource = false %}
      {% endif %}
      
      {
        {% if random_resource %}
        "resource": {
          "title": "{{ random_resource.title | escape }}",
          "description": "{{ random_resource.description | escape }}",
          "url": "{{ random_resource.url }}",
          "category": "{{ random_resource.category | default: 'General' }}",
          "type": "{{ random_resource.type | default: 'Resource' }}",
          "added_date": "{{ random_resource.last_updated | default: 'Recently' }}"
        }
        {% else %}
        "resource": {
          "title": "Welcome to IPLibrary",
          "description": "Start exploring our curated collection of internet resources.",
          "url": "/{{ page.lang | default: 'en-US' }}/",
          "category": "General",
          "type": "Page",
          "added_date": "2024-06-18"
        }
        {% endif %}
      }
    CONTENT
    
    unless File.exist?("#{api_dir}/random-resource.json")
      File.write("#{api_dir}/random-resource.json", random_api_content)
      @created_pages << "#{api_dir}/random-resource.json"
      puts "✅ Created API endpoint: #{api_dir}/random-resource.json"
    end
  end
  
  def api_endpoint_template(endpoint)
    case endpoint
    when 'featured-resources'
      <<~CONTENT
        ---
        layout: null
        ---
        {
          "featured_resources": [
            {
              "title": "Stack Overflow",
              "description": "Programming Q&A community",
              "url": "https://stackoverflow.com",
              "category": "Development",
              "type": "Community",
              "featured_reason": "Most popular programming community"
            },
            {
              "title": "GitHub",
              "description": "Code hosting and collaboration platform",
              "url": "https://github.com",
              "category": "Development", 
              "type": "Platform",
              "featured_reason": "Essential tool for developers"
            }
          ],
          "last_updated": "{{ site.time | date: '%Y-%m-%d' }}"
        }
      CONTENT
    when 'latest-edits'
      <<~CONTENT
        ---
        layout: null
        ---
        {
          "latest_edits": [
            {
              "title": "Updated Business Resources",
              "description": "Added new startup and entrepreneurship resources",
              "category": "Business",
              "editor": "Community",
              "date": "{{ site.time | date: '%Y-%m-%d' }}",
              "changes": 5
            }
          ],
          "total_recent_changes": 22,
          "last_updated": "{{ site.time | date: '%Y-%m-%d' }}"
        }
      CONTENT
    when 'new-resources'
      <<~CONTENT
        ---
        layout: null
        ---
        {
          "new_resources": [
            {
              "title": "ChatGPT",
              "description": "AI-powered conversational assistant",
              "url": "https://chat.openai.com",
              "category": "Computing",
              "type": "AI Tool",
              "added_date": "{{ site.time | date: '%Y-%m-%d' }}",
              "status": "new"
            }
          ],
          "total_new_this_week": 15,
          "last_updated": "{{ site.time | date: '%Y-%m-%d' }}"
        }
      CONTENT
    when 'community-news'
      <<~CONTENT
        ---
        layout: null
        ---
        {
          "community_news": [
            {
              "title": "IPLibrary Community Milestone",
              "content": "We've reached 10,000+ curated resources!",
              "type": "milestone",
              "date": "{{ site.time | date: '%Y-%m-%d' }}",
              "author": "IPLibrary Team"
            }
          ],
          "total_posts": 127,
          "last_updated": "{{ site.time | date: '%Y-%m-%d' }}"
        }
      CONTENT
    when 'active-contributors'
      <<~CONTENT
        ---
        layout: null
        ---
        {
          "active_contributors": [
            {
              "name": "Alex Developer",
              "avatar": "/images/avatar/small/alex.jpg",
              "contributions": 45,
              "specialties": ["Development", "Computing"],
              "last_active": "{{ site.time | date: '%Y-%m-%d' }}",
              "role": "Maintainer"
            }
          ],
          "total_contributors": 156,
          "last_updated": "{{ site.time | date: '%Y-%m-%d' }}"
        }
      CONTENT
    else
      '{"error": "Unknown endpoint"}'
    end
  end
  
  def report_results
    puts "\n" + "="*50
    puts "📋 PAGE GENERATION COMPLETE!"
    puts "="*50
    
    puts "\n✅ Created #{@created_pages.length} new pages:"
    @created_pages.each { |page| puts "   • #{page}" }
    
    if @updated_pages.any?
      puts "\n🔄 Updated #{@updated_pages.length} existing pages:"
      @updated_pages.each { |page| puts "   • #{page}" }
    end
    
    puts "\n🎯 Next steps:"
    puts "   1. Run 'bundle exec jekyll build' to generate the site"
    puts "   2. Review the created pages and customize as needed"
    puts "   3. Add real content to the YAML data files"
    puts "   4. Test the site with 'bundle exec jekyll serve'"
    
    puts "\n🚀 IPLibrary website structure is now complete!"
  end
end

# Run the generator
generator = PageGenerator.new
generator.run 

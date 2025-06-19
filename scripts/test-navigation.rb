#!/usr/bin/env ruby

require 'yaml'
require 'fileutils'

class NavigationTester
  def initialize
    @site_root = "_site"
    @errors = []
    @warnings = []
    @checks = 0
  end
  
  def run_all_tests
    puts "🔍 Starting Navigation Tests..."
    
    test_main_pages
    test_category_pages  
    test_api_endpoints
    test_language_pages
    
    report_results
  end
  
  private
  
  def test_main_pages
    puts "\n📋 Testing Main Pages..."
    
    main_pages = [
      "_site/index.html",
      "_site/en-US/index.html", 
      "_site/pt-BR/index.html",
      "_site/en-US/categories/index.html",
      "_site/pt-BR/categories/index.html"
    ]
    
    main_pages.each do |page|
      check_file_exists(page, "Main page")
    end
  end
  
  def test_category_pages
    puts "\n📁 Testing Category Pages..."
    
    ['en-US', 'pt-BR'].each do |lang|
      menu_file = "_data/#{lang}/menu.yaml"
      next unless File.exist?(menu_file)
      
      menu_data = YAML.load_file(menu_file)
      menu_data.each do |category|
        path = category['path']
        next unless path
        
        # Remove leading slash and add _site prefix
        site_path = "_site#{path}index.html"
        check_file_exists(site_path, "Category: #{category['title']}")
        
        # Check subcategories if they exist
        if category['children']
          category['children'].each do |subcategory|
            sub_path = "_site#{subcategory['path']}index.html"
            check_file_exists(sub_path, "Subcategory: #{subcategory['title']}")
            
            # Check sections if they exist
            if subcategory['children']
              subcategory['children'].each do |section|
                section_path = "_site#{section['path']}index.html"
                check_file_exists(section_path, "Section: #{section['title']}")
              end
            end
          end
        end
      end
    end
  end
  
  def test_api_endpoints
    puts "\n🔌 Testing API Endpoints..."
    
    api_endpoints = [
      "_site/api/categories.json",
      "_site/api/categories/en-US.json", 
      "_site/api/categories/pt-BR.json",
      "_site/api/categories/render.html",
      "_site/api/business/index.json",
      "_site/api/computing/index.json"
    ]
    
    api_endpoints.each do |endpoint|
      check_file_exists(endpoint, "API endpoint")
    end
  end
  
  def test_language_pages
    puts "\n🌍 Testing Language Pages..."
    
    # Test language switching functionality
    languages = ['en-US', 'pt-BR']
    languages.each do |lang|
      lang_index = "_site/#{lang}/index.html"
      check_file_exists(lang_index, "Language index: #{lang}")
    end
  end
  
  def check_file_exists(file_path, description)
    @checks += 1
    
    if File.exist?(file_path)
      puts "  ✅ #{description}: #{file_path}"
    else
      @errors << "❌ Missing: #{description} (#{file_path})"
      puts "  ❌ #{description}: #{file_path}"
    end
  end
  
  def report_results
    puts "\n" + "="*60
    puts "📊 TEST RESULTS"
    puts "="*60
    
    puts "Total checks: #{@checks}"
    puts "Errors: #{@errors.length}"
    puts "Warnings: #{@warnings.length}"
    
    if @errors.any?
      puts "\n❌ ERRORS FOUND:"
      @errors.each { |error| puts "  #{error}" }
    end
    
    if @warnings.any?
      puts "\n⚠️  WARNINGS:"
      @warnings.each { |warning| puts "  #{warning}" }
    end
    
    if @errors.empty?
      puts "\n🎉 ALL TESTS PASSED!"
    else
      puts "\n💥 #{@errors.length} issues need to be fixed"
      exit 1
    end
  end
end

# Run the tests
NavigationTester.new.run_all_tests 

#!/usr/bin/env ruby
# Build Cache System for IPLibrary Website
# Implements file-based caching for generated pages and templates

require 'yaml'
require 'fileutils'
require 'json'
require 'digest'
require 'date'

class BuildCache
  CACHE_DIR = '.build-cache'
  PAGES_CACHE_DIR = '.pages-cache'
  TEMPLATE_CACHE_DIR = '.template-cache'
  DATA_CACHE_DIR = '.data-cache'
  
  def initialize
    setup_cache_directories
    @cache_manifest = load_cache_manifest
  end
  
  def setup_cache_directories
    [CACHE_DIR, PAGES_CACHE_DIR, TEMPLATE_CACHE_DIR, DATA_CACHE_DIR].each do |dir|
      FileUtils.mkdir_p(dir) unless Dir.exist?(dir)
    end
  end
  
  def load_cache_manifest
    manifest_file = File.join(CACHE_DIR, 'manifest.json')
    if File.exist?(manifest_file)
      JSON.parse(File.read(manifest_file))
    else
      {
        'version' => '1.0.0',
        'last_build' => nil,
        'data_hashes' => {},
        'template_hashes' => {},
        'page_hashes' => {},
        'stats' => {
          'total_builds' => 0,
          'cache_hits' => 0,
          'cache_misses' => 0
        }
      }
    end
  end
  
  def save_cache_manifest
    setup_cache_directories
    manifest_file = File.join(CACHE_DIR, 'manifest.json')
    @cache_manifest['last_build'] = Time.now.strftime('%Y-%m-%dT%H:%M:%S%z')
    File.write(manifest_file, JSON.pretty_generate(@cache_manifest))
  end
  
  def file_hash(file_path)
    return nil unless File.exist?(file_path)
    Digest::SHA256.hexdigest(File.read(file_path))
  end
  
  def directory_hash(dir_path)
    return nil unless Dir.exist?(dir_path)
    files = Dir.glob(File.join(dir_path, '**', '*')).select { |f| File.file?(f) }
    content = files.sort.map { |f| "#{f}:#{file_hash(f)}" }.join
    Digest::SHA256.hexdigest(content)
  end
  
  def data_changed?(lang)
    data_dir = "_data/#{lang}"
    current_hash = directory_hash(data_dir)
    cached_hash = @cache_manifest['data_hashes'][lang]
    
    if current_hash != cached_hash
      @cache_manifest['data_hashes'][lang] = current_hash
      @cache_manifest['stats']['cache_misses'] += 1
      puts "Data changed for #{lang} (cache miss)"
      return true
    else
      @cache_manifest['stats']['cache_hits'] += 1
      puts "Data unchanged for #{lang} (cache hit)"
      return false
    end
  end
  
  def template_changed?(template_path)
    current_hash = file_hash(template_path)
    cached_hash = @cache_manifest['template_hashes'][template_path]
    
    if current_hash != cached_hash
      @cache_manifest['template_hashes'][template_path] = current_hash
      @cache_manifest['stats']['cache_misses'] += 1
      return true
    else
      @cache_manifest['stats']['cache_hits'] += 1
      return false
    end
  end
  
  def page_cached?(page_path, dependencies = [])
    cache_file = File.join(PAGES_CACHE_DIR, page_path.gsub('/', '_'))
    return false unless File.exist?(cache_file)
    
    # Check if any dependencies have changed
    dependencies.each do |dep|
      if template_changed?(dep)
        puts "Dependency changed: #{dep} -> invalidating #{page_path}"
        return false
      end
    end
    
    @cache_manifest['stats']['cache_hits'] += 1
    puts "Page cached: #{page_path}"
    true
  end
  
  def cache_page(page_path, content)
    cache_file = File.join(PAGES_CACHE_DIR, page_path.gsub('/', '_'))
    File.write(cache_file, content)
    
    page_hash = Digest::SHA256.hexdigest(content)
    @cache_manifest['page_hashes'][page_path] = page_hash
    @cache_manifest['stats']['cache_misses'] += 1
    puts "Page cached: #{page_path}"
  end
  
  def ensure_directory_exists(file_path)
    dir = File.dirname(file_path)
    FileUtils.mkdir_p(dir) unless Dir.exist?(dir)
  end
  
  def restore_cached_page(page_path)
    cache_file = File.join(PAGES_CACHE_DIR, page_path.gsub('/', '_'))
    return nil unless File.exist?(cache_file)
    
    File.read(cache_file)
  end
  
  def should_generate_pages?(lang)
    # Always generate if no cache exists
    return true if @cache_manifest['last_build'].nil?
    
    # Check if data files have changed
    data_changed?(lang)
  end
  
  def clear_cache
    puts "Clearing build cache..."
    [CACHE_DIR, PAGES_CACHE_DIR, TEMPLATE_CACHE_DIR, DATA_CACHE_DIR].each do |dir|
      FileUtils.rm_rf(dir) if Dir.exist?(dir)
    end
    puts "Cache cleared successfully"
  end
  
  def cache_stats
    stats = @cache_manifest['stats']
    total_operations = stats['cache_hits'] + stats['cache_misses']
    hit_rate = total_operations > 0 ? (stats['cache_hits'].to_f / total_operations * 100).round(2) : 0
    
    puts "\n=== BUILD CACHE STATISTICS ==="
    puts "Total builds: #{stats['total_builds']}"
    puts "Cache hits: #{stats['cache_hits']}"
    puts "Cache misses: #{stats['cache_misses']}"
    puts "Hit rate: #{hit_rate}%"
    puts "Last build: #{@cache_manifest['last_build']}"
    puts "============================="
  end
  
  def increment_build_count
    @cache_manifest['stats']['total_builds'] += 1
  end
  
  def get_cached_template(template_path)
    cache_file = File.join(TEMPLATE_CACHE_DIR, File.basename(template_path))
    
    if File.exist?(cache_file) && !template_changed?(template_path)
      puts "Using cached template: #{template_path}"
      return File.read(cache_file)
    else
      puts "Template cache miss: #{template_path}"
      return nil
    end
  end
  
  def cache_template(template_path, content)
    cache_file = File.join(TEMPLATE_CACHE_DIR, File.basename(template_path))
    File.write(cache_file, content)
    puts "Template cached: #{template_path}"
  end
end

# Cached page generation functions
class CachedPageGenerator
  def initialize
    @cache = BuildCache.new
  end
  
  def generate_with_cache(page_path, dependencies = [], &block)
    # Check if page is already cached and dependencies haven't changed
    if @cache.page_cached?(page_path, dependencies)
      cached_content = @cache.restore_cached_page(page_path)
      if cached_content
        @cache.ensure_directory_exists(page_path)
        File.write(page_path, cached_content)
        return true
      end
    end
    
    # Generate page using provided block
    content = block.call
    if content
      @cache.ensure_directory_exists(page_path)
      File.write(page_path, content)
      @cache.cache_page(page_path, content)
      return true
    end
    
    false
  end
  
  def get_template_with_cache(template_path)
    cached = @cache.get_cached_template(template_path)
    return cached if cached
    
    if File.exist?(template_path)
      content = File.read(template_path)
      @cache.cache_template(template_path, content)
      return content
    end
    
    nil
  end
  
  def should_process_language?(lang)
    @cache.should_generate_pages?(lang)
  end
  
  def finalize
    @cache.increment_build_count
    @cache.save_cache_manifest
    @cache.cache_stats
  end
  
  def clear_cache
    @cache.clear_cache
  end
end

# Global cache instance for use in Rakefile
$build_cache = CachedPageGenerator.new

# Rake task integration
namespace :cache do
  desc "Clear build cache"
  task :clear do
    $build_cache.clear_cache
  end
  
  desc "Show cache statistics"
  task :stats do
    cache = BuildCache.new
    cache.cache_stats
  end
  
  desc "Warm up cache by generating all pages"
  task :warmup => ['iplibrary:generate_all'] do
    puts "Cache warmed up successfully"
  end
end

# Add cache finalization to main tasks
at_exit do
  $build_cache.finalize if defined?($build_cache)
end

puts "Build cache system loaded successfully"
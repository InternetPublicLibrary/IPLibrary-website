#!/usr/bin/env ruby
# Build Performance Monitoring System for IPLibrary Website
# Comprehensive performance tracking, regression detection, and optimization analysis

require 'json'
require 'fileutils'
require 'digest'
require 'benchmark'
require 'yaml'
require 'erb'
require 'time'
require 'psych'

class BuildPerformanceMonitor
  PERF_DIR = '.build-performance'
  REPORTS_DIR = File.join(PERF_DIR, 'reports')
  BASELINES_DIR = File.join(PERF_DIR, 'baselines')
  TRENDS_DIR = File.join(PERF_DIR, 'trends')
  
  # Performance thresholds
  THRESHOLDS = {
    build_time_seconds: 300,        # 5 minutes max build time
    memory_usage_mb: 1024,          # 1GB max memory usage
    page_generation_ms: 5000,       # 5 seconds per page max
    cache_hit_rate: 80,             # 80% minimum cache hit rate
    regression_threshold: 20        # 20% performance regression threshold
  }.freeze
  
  attr_reader :start_time, :metrics, :stage_metrics, :warnings, :errors
  
  def initialize
    @start_time = Time.now
    @stage_start_times = {}
    @metrics = {
      build: {},
      stages: {},
      pages: {},
      memory: {},
      cache: {},
      size: {}
    }
    @stage_metrics = {}
    @warnings = []
    @errors = []
    @current_stage = nil
    
    setup_performance_directories
    @baseline = load_baseline
    @previous_build = load_previous_build
  end
  
  def setup_performance_directories
    [PERF_DIR, REPORTS_DIR, BASELINES_DIR, TRENDS_DIR].each do |dir|
      FileUtils.mkdir_p(dir) unless Dir.exist?(dir)
    end
  end
  
  # === Build Stage Tracking ===
  
  def start_stage(stage_name, description = nil)
    @current_stage = stage_name
    @stage_start_times[stage_name] = Time.now
    
    log_info("Starting stage: #{stage_name}")
    log_info("Description: #{description}") if description
    track_memory_usage("#{stage_name}_start")
  end
  
  def end_stage(stage_name = nil)
    stage_name ||= @current_stage
    return unless @stage_start_times[stage_name]
    
    duration = Time.now - @stage_start_times[stage_name]
    
    @stage_metrics[stage_name] = {
      duration_seconds: duration,
      start_time: @stage_start_times[stage_name],
      end_time: Time.now,
      memory_start: @metrics[:memory]["#{stage_name}_start"],
      memory_end: track_memory_usage("#{stage_name}_end")
    }
    
    log_info("Completed stage: #{stage_name} in #{duration.round(2)}s")
    @current_stage = nil
  end
  
  def track_page_generation(page_path, &block)
    start_time = Time.now
    memory_before = get_memory_usage
    
    result = block.call if block_given?
    
    duration = Time.now - start_time
    memory_after = get_memory_usage
    
    @metrics[:pages][page_path] = {
      duration_ms: (duration * 1000).round(2),
      memory_delta_mb: memory_after - memory_before,
      timestamp: start_time,
      success: result != false
    }
    
    # Check for performance issues
    if duration > (THRESHOLDS[:page_generation_ms] / 1000.0)
      add_warning("Slow page generation: #{page_path} took #{duration.round(2)}s")
    end
    
    result
  end
  
  def track_memory_usage(checkpoint = nil)
    memory_mb = get_memory_usage
    checkpoint ||= "checkpoint_#{Time.now.to_i}"
    
    @metrics[:memory][checkpoint] = {
      memory_mb: memory_mb,
      timestamp: Time.now
    }
    
    if memory_mb > THRESHOLDS[:memory_usage_mb]
      add_warning("High memory usage: #{memory_mb}MB at #{checkpoint}")
    end
    
    memory_mb
  end
  
  def track_cache_metrics(cache_stats)
    total_operations = cache_stats['cache_hits'] + cache_stats['cache_misses']
    hit_rate = total_operations > 0 ? (cache_stats['cache_hits'].to_f / total_operations * 100) : 0
    
    @metrics[:cache] = {
      hits: cache_stats['cache_hits'],
      misses: cache_stats['cache_misses'],
      hit_rate: hit_rate.round(2),
      total_operations: total_operations
    }
    
    if hit_rate < THRESHOLDS[:cache_hit_rate]
      add_warning("Low cache hit rate: #{hit_rate.round(2)}% (threshold: #{THRESHOLDS[:cache_hit_rate]}%)")
    end
  end
  
  def track_build_size(site_dir = '_site')
    return unless Dir.exist?(site_dir)
    
    size_info = calculate_directory_size(site_dir)
    
    @metrics[:size] = {
      total_mb: size_info[:total_mb],
      file_count: size_info[:file_count],
      largest_files: size_info[:largest_files],
      by_extension: size_info[:by_extension]
    }
    
    log_info("Build size: #{size_info[:total_mb]}MB (#{size_info[:file_count]} files)")
  end
  
  # === Performance Analysis ===
  
  def analyze_performance
    total_duration = Time.now - @start_time
    
    @metrics[:build] = {
      total_duration_seconds: total_duration,
      start_time: @start_time,
      end_time: Time.now,
      stages: @stage_metrics,
      peak_memory_mb: @metrics[:memory].values.map { |m| m[:memory_mb] }.max || 0
    }
    
    detect_regressions
    identify_bottlenecks
    generate_recommendations
  end
  
  def detect_regressions
    return unless @baseline && @previous_build
    
    # Check build time regression
    current_time = @metrics[:build][:total_duration_seconds]
    baseline_time = @baseline.dig('build', 'total_duration_seconds')
    previous_time = @previous_build.dig('build', 'total_duration_seconds')
    
    if baseline_time && current_time > baseline_time * (1 + THRESHOLDS[:regression_threshold] / 100.0)
      regression_percent = ((current_time - baseline_time) / baseline_time * 100).round(2)
      add_error("Build time regression detected: #{regression_percent}% slower than baseline")
    end
    
    if previous_time && current_time > previous_time * 1.1  # 10% slower than previous
      regression_percent = ((current_time - previous_time) / previous_time * 100).round(2)
      add_warning("Build time increased by #{regression_percent}% from previous build")
    end
    
    # Check memory regression
    current_memory = @metrics[:build][:peak_memory_mb]
    baseline_memory = @baseline.dig('build', 'peak_memory_mb')
    
    if baseline_memory && current_memory > baseline_memory * 1.2  # 20% more memory
      regression_percent = ((current_memory - baseline_memory) / baseline_memory * 100).round(2)
      add_warning("Memory usage increased by #{regression_percent}% from baseline")
    end
  end
  
  def identify_bottlenecks
    # Identify slowest stages
    slowest_stages = @stage_metrics.sort_by { |_, data| -data[:duration_seconds] }.first(3)
    
    slowest_stages.each do |stage, data|
      if data[:duration_seconds] > 30  # More than 30 seconds
        add_warning("Slow build stage: #{stage} took #{data[:duration_seconds].round(2)}s")
      end
    end
    
    # Identify slowest pages
    slowest_pages = @metrics[:pages].sort_by { |_, data| -data[:duration_ms] }.first(5)
    
    slowest_pages.each do |page, data|
      if data[:duration_ms] > 1000  # More than 1 second
        add_warning("Slow page generation: #{page} took #{data[:duration_ms]}ms")
      end
    end
  end
  
  def generate_recommendations
    recommendations = []
    
    # Cache optimization
    if @metrics[:cache][:hit_rate] < 70
      recommendations << "Consider optimizing cache strategy - current hit rate: #{@metrics[:cache][:hit_rate]}%"
    end
    
    # Memory optimization
    if @metrics[:build][:peak_memory_mb] > 512
      recommendations << "Consider optimizing memory usage - peak usage: #{@metrics[:build][:peak_memory_mb]}MB"
    end
    
    # Build size optimization
    if @metrics[:size][:total_mb] > 100
      recommendations << "Consider optimizing build size - current size: #{@metrics[:size][:total_mb]}MB"
    end
    
    # Stage optimization
    @stage_metrics.each do |stage, data|
      if data[:duration_seconds] > 60
        recommendations << "Optimize #{stage} stage - taking #{data[:duration_seconds].round(2)}s"
      end
    end
    
    @metrics[:recommendations] = recommendations
  end
  
  # === Reporting ===
  
  def generate_report(format = :json)
    case format
    when :json
      generate_json_report
    when :html
      generate_html_report
    when :console
      generate_console_report
    else
      generate_json_report
    end
  end
  
  def generate_json_report
    report_data = {
      timestamp: Time.now.iso8601,
      build_id: generate_build_id,
      metrics: @metrics,
      warnings: @warnings,
      errors: @errors,
      thresholds: THRESHOLDS,
      environment: collect_environment_info
    }
    
    report_file = File.join(REPORTS_DIR, "build-#{generate_build_id}.json")
    File.write(report_file, JSON.pretty_generate(report_data))
    
    # Also save as latest
    latest_file = File.join(REPORTS_DIR, "latest.json")
    File.write(latest_file, JSON.pretty_generate(report_data))
    
    log_info("Performance report saved: #{report_file}")
    report_file
  end
  
  def generate_html_report
    template_path = File.join(__dir__, 'templates', 'performance-report.html.erb')
    
    # Use embedded template if external doesn't exist
    template_content = if File.exist?(template_path)
      File.read(template_path)
    else
      get_embedded_html_template
    end
    
    erb = ERB.new(template_content)
    html_content = erb.result(binding)
    
    report_file = File.join(REPORTS_DIR, "build-#{generate_build_id}.html")
    File.write(report_file, html_content)
    
    # Also save as latest
    latest_file = File.join(REPORTS_DIR, "latest.html")
    File.write(latest_file, html_content)
    
    log_info("HTML performance report saved: #{report_file}")
    report_file
  end
  
  def generate_console_report
    puts "\n" + "="*80
    puts "BUILD PERFORMANCE REPORT"
    puts "="*80
    
    # Build summary
    puts "\nBuild Summary:"
    puts "  Duration: #{@metrics[:build][:total_duration_seconds].round(2)}s"
    puts "  Peak Memory: #{@metrics[:build][:peak_memory_mb]}MB"
    puts "  Pages Generated: #{@metrics[:pages].size}"
    puts "  Build Size: #{@metrics[:size][:total_mb]}MB (#{@metrics[:size][:file_count]} files)"
    
    # Cache performance
    if @metrics[:cache][:total_operations] > 0
      puts "\nCache Performance:"
      puts "  Hit Rate: #{@metrics[:cache][:hit_rate]}%"
      puts "  Hits: #{@metrics[:cache][:hits]}"
      puts "  Misses: #{@metrics[:cache][:misses]}"
    end
    
    # Stage breakdown
    puts "\nStage Performance:"
    @stage_metrics.each do |stage, data|
      duration = data[:duration_seconds].round(2)
      percentage = (@metrics[:build][:total_duration_seconds] > 0 ? 
                   (data[:duration_seconds] / @metrics[:build][:total_duration_seconds] * 100).round(1) : 0)
      puts "  #{stage}: #{duration}s (#{percentage}%)"
    end
    
    # Warnings and errors
    if @warnings.any?
      puts "\nWarnings:"
      @warnings.each { |warning| puts "  ⚠️  #{warning}" }
    end
    
    if @errors.any?
      puts "\nErrors:"
      @errors.each { |error| puts "  ❌ #{error}" }
    end
    
    # Recommendations
    if @metrics[:recommendations]&.any?
      puts "\nRecommendations:"
      @metrics[:recommendations].each { |rec| puts "  💡 #{rec}" }
    end
    
    puts "\n" + "="*80
  end
  
  # === Baseline Management ===
  
  def set_baseline
    baseline_data = {
      timestamp: Time.now.iso8601,
      build: @metrics[:build],
      environment: collect_environment_info
    }
    
    baseline_file = File.join(BASELINES_DIR, "baseline.json")
    File.write(baseline_file, JSON.pretty_generate(baseline_data))
    
    log_info("Performance baseline saved: #{baseline_file}")
  end
  
  def load_baseline
    baseline_file = File.join(BASELINES_DIR, "baseline.json")
    return nil unless File.exist?(baseline_file)
    
    JSON.parse(File.read(baseline_file))
  rescue JSON::ParserError => e
    log_error("Failed to load baseline: #{e.message}")
    nil
  end
  
  def load_previous_build
    latest_file = File.join(REPORTS_DIR, "latest.json")
    return nil unless File.exist?(latest_file)
    
    JSON.parse(File.read(latest_file))
  rescue JSON::ParserError => e
    log_error("Failed to load previous build data: #{e.message}")
    nil
  end
  
  def save_trend_data
    trend_file = File.join(TRENDS_DIR, "#{Date.today.strftime('%Y-%m')}.json")
    
    trend_data = if File.exist?(trend_file)
      JSON.parse(File.read(trend_file))
    else
      { builds: [] }
    end
    
    build_summary = {
      timestamp: Time.now.iso8601,
      build_id: generate_build_id,
      duration: @metrics[:build][:total_duration_seconds],
      memory: @metrics[:build][:peak_memory_mb],
      cache_hit_rate: @metrics[:cache][:hit_rate],
      build_size_mb: @metrics[:size][:total_mb],
      page_count: @metrics[:pages].size
    }
    
    trend_data[:builds] << build_summary
    
    # Keep only last 100 builds
    trend_data[:builds] = trend_data[:builds].last(100)
    
    File.write(trend_file, JSON.pretty_generate(trend_data))
    log_info("Trend data saved: #{trend_file}")
  end
  
  # === CI/CD Integration ===
  
  def check_ci_thresholds
    failures = []
    
    # Check build time
    if @metrics[:build][:total_duration_seconds] > THRESHOLDS[:build_time_seconds]
      failures << "Build time exceeded threshold: #{@metrics[:build][:total_duration_seconds]}s > #{THRESHOLDS[:build_time_seconds]}s"
    end
    
    # Check memory usage
    if @metrics[:build][:peak_memory_mb] > THRESHOLDS[:memory_usage_mb]
      failures << "Memory usage exceeded threshold: #{@metrics[:build][:peak_memory_mb]}MB > #{THRESHOLDS[:memory_usage_mb]}MB"
    end
    
    # Check cache hit rate
    if @metrics[:cache][:hit_rate] < THRESHOLDS[:cache_hit_rate]
      failures << "Cache hit rate below threshold: #{@metrics[:cache][:hit_rate]}% < #{THRESHOLDS[:cache_hit_rate]}%"
    end
    
    failures
  end
  
  def exit_on_failure?
    ENV['PERF_FAIL_ON_THRESHOLD'] == 'true'
  end
  
  # === Utility Methods ===
  
  private
  
  def get_memory_usage
    # Try different methods to get memory usage
    if RUBY_PLATFORM =~ /linux/
      get_memory_linux
    elsif RUBY_PLATFORM =~ /darwin/
      get_memory_macos
    else
      get_memory_generic
    end
  end
  
  def get_memory_linux
    status_file = "/proc/#{Process.pid}/status"
    return 0 unless File.exist?(status_file)
    
    File.readlines(status_file).each do |line|
      if line.start_with?('VmRSS:')
        kb = line.split[1].to_i
        return (kb / 1024.0).round(2)  # Convert to MB
      end
    end
    0
  end
  
  def get_memory_macos
    ps_output = `ps -o rss= -p #{Process.pid}`.strip
    kb = ps_output.to_i
    (kb / 1024.0).round(2)  # Convert to MB
  rescue
    0
  end
  
  def get_memory_generic
    # Fallback using ObjectSpace (less accurate but portable)
    ObjectSpace.count_objects[:TOTAL] / 1000000.0  # Rough approximation
  end
  
  def calculate_directory_size(dir)
    total_size = 0
    file_count = 0
    files_by_size = []
    extensions = Hash.new(0)
    
    Dir.glob(File.join(dir, '**', '*')).each do |file|
      next unless File.file?(file)
      
      size = File.size(file)
      total_size += size
      file_count += 1
      
      files_by_size << { path: file.sub("#{dir}/", ''), size_mb: (size / 1024.0 / 1024.0).round(3) }
      
      ext = File.extname(file).downcase
      extensions[ext.empty? ? '(no extension)' : ext] += size
    end
    
    {
      total_mb: (total_size / 1024.0 / 1024.0).round(2),
      file_count: file_count,
      largest_files: files_by_size.sort_by { |f| -f[:size_mb] }.first(10),
      by_extension: extensions.transform_values { |size| (size / 1024.0 / 1024.0).round(2) }
                              .sort_by { |_, size| -size }.first(10).to_h
    }
  end
  
  def generate_build_id
    @build_id ||= Time.now.strftime('%Y%m%d-%H%M%S')
  end
  
  def collect_environment_info
    {
      ruby_version: RUBY_VERSION,
      platform: RUBY_PLATFORM,
      jekyll_env: ENV['JEKYLL_ENV'] || 'development',
      pwd: Dir.pwd,
      user: ENV['USER'] || ENV['USERNAME'],
      hostname: ENV['HOSTNAME'] || `hostname`.strip,
      ci: !!(ENV['CI'] || ENV['CONTINUOUS_INTEGRATION'])
    }
  end
  
  def add_warning(message)
    @warnings << message
    log_warning(message)
  end
  
  def add_error(message)
    @errors << message
    log_error(message)
  end
  
  def log_info(message)
    puts "[PERF] #{Time.now.strftime('%H:%M:%S')} INFO: #{message}"
  end
  
  def log_warning(message)
    puts "[PERF] #{Time.now.strftime('%H:%M:%S')} WARN: #{message}"
  end
  
  def log_error(message)
    puts "[PERF] #{Time.now.strftime('%H:%M:%S')} ERROR: #{message}"
  end
  
  def get_embedded_html_template
    <<~HTML
      <!DOCTYPE html>
      <html lang="en">
      <head>
          <meta charset="UTF-8">
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
          <title>Build Performance Report</title>
          <style>
              body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Arial, sans-serif; margin: 0; padding: 20px; background: #f5f5f5; }
              .container { max-width: 1200px; margin: 0 auto; background: white; padding: 30px; border-radius: 8px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
              h1 { color: #2c3e50; border-bottom: 3px solid #3498db; padding-bottom: 10px; }
              h2 { color: #34495e; margin-top: 30px; }
              .metric-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(250px, 1fr)); gap: 20px; margin: 20px 0; }
              .metric-card { background: #f8f9fa; padding: 20px; border-radius: 6px; border-left: 4px solid #3498db; }
              .metric-value { font-size: 2em; font-weight: bold; color: #2c3e50; }
              .metric-label { color: #7f8c8d; font-size: 0.9em; margin-top: 5px; }
              .warning { background: #fff3cd; border-left-color: #ffc107; color: #856404; }
              .error { background: #f8d7da; border-left-color: #dc3545; color: #721c24; }
              .success { background: #d4edda; border-left-color: #28a745; color: #155724; }
              .stage-list { list-style: none; padding: 0; }
              .stage-item { background: #f8f9fa; margin: 10px 0; padding: 15px; border-radius: 4px; display: flex; justify-content: space-between; align-items: center; }
              .stage-name { font-weight: 600; }
              .stage-duration { color: #6c757d; }
              .recommendations { background: #e7f3ff; border: 1px solid #b8daff; border-radius: 4px; padding: 15px; margin: 20px 0; }
              table { width: 100%; border-collapse: collapse; margin: 20px 0; }
              th, td { text-align: left; padding: 12px; border-bottom: 1px solid #dee2e6; }
              th { background: #f8f9fa; font-weight: 600; }
              .timestamp { color: #6c757d; font-size: 0.9em; }
          </style>
      </head>
      <body>
          <div class="container">
              <h1>Build Performance Report</h1>
              <div class="timestamp">Generated: <%= Time.now.strftime('%Y-%m-%d %H:%M:%S %Z') %></div>
              
              <div class="metric-grid">
                  <div class="metric-card">
                      <div class="metric-value"><%= @metrics[:build][:total_duration_seconds].round(2) %>s</div>
                      <div class="metric-label">Total Build Time</div>
                  </div>
                  <div class="metric-card">
                      <div class="metric-value"><%= @metrics[:build][:peak_memory_mb] %>MB</div>
                      <div class="metric-label">Peak Memory Usage</div>
                  </div>
                  <div class="metric-card">
                      <div class="metric-value"><%= @metrics[:pages].size %></div>
                      <div class="metric-label">Pages Generated</div>
                  </div>
                  <div class="metric-card">
                      <div class="metric-value"><%= @metrics[:cache][:hit_rate] %>%</div>
                      <div class="metric-label">Cache Hit Rate</div>
                  </div>
              </div>
      
              <h2>Stage Performance</h2>
              <ul class="stage-list">
                  <% @stage_metrics.each do |stage, data| %>
                  <li class="stage-item">
                      <span class="stage-name"><%= stage %></span>
                      <span class="stage-duration"><%= data[:duration_seconds].round(2) %>s</span>
                  </li>
                  <% end %>
              </ul>
      
              <% if @warnings.any? %>
              <h2>Warnings</h2>
              <% @warnings.each do |warning| %>
              <div class="metric-card warning">⚠️ <%= warning %></div>
              <% end %>
              <% end %>
      
              <% if @errors.any? %>
              <h2>Errors</h2>
              <% @errors.each do |error| %>
              <div class="metric-card error">❌ <%= error %></div>
              <% end %>
              <% end %>
      
              <% if @metrics[:recommendations]&.any? %>
              <div class="recommendations">
                  <h3>Recommendations</h3>
                  <ul>
                      <% @metrics[:recommendations].each do |rec| %>
                      <li>💡 <%= rec %></li>
                      <% end %>
                  </ul>
              </div>
              <% end %>
      
              <h2>Build Details</h2>
              <table>
                  <tr><th>Build ID</th><td><%= generate_build_id %></td></tr>
                  <tr><th>Start Time</th><td><%= @start_time.strftime('%Y-%m-%d %H:%M:%S %Z') %></td></tr>
                  <tr><th>End Time</th><td><%= Time.now.strftime('%Y-%m-%d %H:%M:%S %Z') %></td></tr>
                  <tr><th>Ruby Version</th><td><%= RUBY_VERSION %></td></tr>
                  <tr><th>Platform</th><td><%= RUBY_PLATFORM %></td></tr>
                  <tr><th>Jekyll Environment</th><td><%= ENV['JEKYLL_ENV'] || 'development' %></td></tr>
              </table>
          </div>
      </body>
      </html>
    HTML
  end
end

# Global performance monitor instance
$performance_monitor = BuildPerformanceMonitor.new

puts "Build Performance Monitor loaded successfully"
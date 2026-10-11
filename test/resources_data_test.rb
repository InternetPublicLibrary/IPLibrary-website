require 'minitest/autorun'
require 'yaml'
require 'uri'

# Spec 002: every resource file holds real, well-formed entries (no generated placeholders).
class ResourcesDataTest < Minitest::Test
  ROOT = File.expand_path('..', __dir__)
  FILES = Dir.glob(File.join(ROOT, '_data/{en-US,pt-BR}/*/*/*.yaml')).sort.freeze
  REQUIRED = %w[name url description].freeze

  def test_resource_files_exist
    refute_empty FILES
  end

  # Reserved example domains (RFC 2606), compared on the parsed host so a real URL that merely mentions one in its
  # path or query is not flagged, and lookalike hosts such as example.com.evil.test are.
  PLACEHOLDER_HOST = /\A(?:.+\.)?example\.(?:com|org|net)\z/i

  def test_no_placeholder_resources_remain
    placeholders = FILES.select do |file|
      entries = YAML.safe_load(File.read(file)) || []
      entries.is_a?(Array) && entries.any? { |entry| entry.is_a?(Hash) && placeholder_url?(entry['url']) }
    end
    assert_empty placeholders, "#{placeholders.size} files still hold placeholders, e.g. #{relative(placeholders.first)}"
  end

  def test_placeholder_detection_uses_the_host
    assert placeholder_url?('https://example.com/resource')
    assert placeholder_url?('https://docs.example.org/')
    refute placeholder_url?('https://real.site/?ref=example.com')
    refute placeholder_url?('https://example.com.evil.test/')
  end

  def test_entries_are_well_formed
    problems = []
    FILES.each do |file|
      entries = YAML.safe_load(File.read(file)) || []
      problems << "#{relative(file)}: not a list" and next unless entries.is_a?(Array)

      entries.each_with_index do |entry, index|
        missing = REQUIRED.reject { |key| entry.is_a?(Hash) && entry[key].to_s.strip != '' }
        problems << "#{relative(file)}[#{index}]: missing #{missing.join(', ')}" unless missing.empty?
        url = entry.is_a?(Hash) ? entry['url'].to_s : ''
        problems << "#{relative(file)}[#{index}]: not an https URL #{url}" unless url.empty? || url.start_with?('https://')
      end
      urls = entries.select { |entry| entry.is_a?(Hash) }.map { |entry| entry['url'] }.compact
      duplicates = urls.select { |url| urls.count(url) > 1 }.uniq
      problems << "#{relative(file)}: duplicate #{duplicates.join(', ')}" unless duplicates.empty?
    end
    assert_empty problems, problems.first(20).join("\n")
  end

  private

  def placeholder_url?(url)
    PLACEHOLDER_HOST.match?(URI.parse(url.to_s).host.to_s)
  rescue URI::InvalidURIError
    false
  end

  def relative(file)
    file.to_s.delete_prefix("#{ROOT}/")
  end
end

require_relative 'test_helper'
require 'uri'

class InternalLinksTest < Minitest::Test
  EXTERNAL = %r{\A([a-z][a-z0-9+.-]*:|//|#|\{\{|\{%|')|\$\{}i

  def test_every_internal_href_resolves_to_a_built_file
    dest = SiteBuild.site.dest
    broken = Hash.new { |hash, key| hash[key] = [] }

    Dir.glob(File.join(dest, '**/*.html')).each do |file|
      page_dir = File.dirname(file)
      File.read(file).scan(/\shref="([^"]*)"/).flatten.uniq.each do |href|
        next if href.empty? || href.match?(EXTERNAL)

        path = URI.decode_www_form_component(href.split(/[?#]/).first.to_s)
        next if path.empty?

        target = path.start_with?('/') ? File.join(dest, path) : File.expand_path(path, page_dir)
        broken[href] << file.delete_prefix("#{dest}/") unless served?(target)
      end
    end

    report = broken.sort_by { |_, pages| -pages.size }.first(40).map do |href, pages|
      "#{href} (#{pages.size} pages, e.g. #{pages.first})"
    end
    assert_empty broken, "Broken internal links:\n#{report.join("\n")}"
  end

  private

  def served?(target)
    File.file?(target) ||
      File.file?("#{target}.html") ||
      File.file?(File.join(target, 'index.html'))
  end
end

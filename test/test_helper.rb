require 'minitest/autorun'
require 'tmpdir'
require 'jekyll'

# Builds the real site once per test run into a temporary destination,
# so every test asserts on what visitors would actually be served.
module SiteBuild
  ROOT = File.expand_path('..', __dir__)

  def self.site
    @site ||= begin
      destination = Dir.mktmpdir('iplibrary-test-site')
      Minitest.after_run { FileUtils.remove_entry(destination) }
      config = Jekyll.configuration(
        'source' => ROOT,
        'destination' => destination,
        'incremental' => false,
        'quiet' => true
      )
      site = Jekyll::Site.new(config)
      site.process
      site
    end
  end

  def self.output(relative_path)
    File.read(File.join(site.dest, relative_path))
  end
end

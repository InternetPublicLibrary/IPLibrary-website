require_relative 'test_helper'

# Spec 005 AC1/AC2: every third-party script or stylesheet is pinned to an exact version and
# protected by Subresource Integrity, and no page ships Google Analytics.
class ThirdPartyAssetsTest < Minitest::Test
  EXTERNAL_TAG = %r{<(?:script\b[^>]*\bsrc|link\b[^>]*\bhref)="(?:https?:)?//[^"]+"[^>]*>}i
  EXACT_VERSION = %r{[@/]v?\d+\.\d+\.\d+(?:[/"?#]|\z)}
  ANALYTICS = /google-analytics\.com|googletagmanager\.com|\bgtag\(|\bga\(\s*'create'/

  def built_pages
    Dir.glob(File.join(SiteBuild.site.dest, '**', '*.html'))
  end

  def test_third_party_assets_are_pinned_with_integrity
    offenders = Hash.new { |hash, key| hash[key] = [] }

    built_pages.each do |file|
      File.read(file).scan(EXTERNAL_TAG) do
        tag = Regexp.last_match(0)
        next if tag.start_with?('<link') && tag !~ /rel="(stylesheet|modulepreload)"/i

        url = tag[/(?:src|href)="([^"]+)"/i, 1]
        problem = if url !~ EXACT_VERSION then 'no exact version'
                  elsif tag !~ /\bintegrity="sha(256|384|512)-/ then 'no integrity'
                  end
        offenders["#{url} (#{problem})"] << file.delete_prefix(SiteBuild.site.dest) if problem
      end
    end

    assert_empty offenders.keys, offenders.map { |asset, pages| "#{asset}: #{pages.size} pages, e.g. #{pages.first}" }.join("\n")
  end

  def test_no_google_analytics_in_templates_or_pages
    sources = Dir.glob(File.join(SiteBuild::ROOT, '{_layouts,_includes}', '**', '*.html'))
    offenders = (sources + built_pages).select { |file| File.read(file).match?(ANALYTICS) }

    assert_empty offenders.map { |file| file.delete_prefix(SiteBuild::ROOT).delete_prefix(SiteBuild.site.dest) }
  end
end

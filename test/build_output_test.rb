require_relative 'test_helper'

class BuildOutputTest < Minitest::Test
  def test_keywords_cloud_falls_back_to_title_words
    html = SiteBuild.output('en-US/academics/computer-science-theory/index.html')

    assert_includes html, 'id="keywords-cloud"'
    assert_includes html, '/en-US/search/?q=Computer'
  end

  def test_generated_page_templates_are_rendered_as_markdown
    html = SiteBuild.output('en-US/academics/computer-science-theory/index.html')

    refute html.include?('## Overview'), 'raw Markdown heading leaked into the output'
    assert_match(%r{<h2[^>]*>Overview</h2>}, html)
  end

  def test_pages_use_the_ipl_brand_favicons
    html = SiteBuild.output('en-US/academics/computer-science-theory/index.html')

    assert_includes html, '<link rel="icon" href="/images/favicon.svg" type="image/svg+xml">'
    assert_includes html, '<link rel="apple-touch-icon" href="/images/apple-touch-icon.png">'
    # Browsers request /favicon.ico on their own, regardless of <link> tags
    assert File.file?(File.join(SiteBuild.site.dest, 'favicon.ico'))
  end

  # The submodule LICENSE files collide with /<lang>/license/ on
  # case-insensitive filesystems (macOS), which breaks the build there.
  def test_submodule_license_files_are_not_published
    published = SiteBuild.site.static_files.map(&:relative_path)

    refute_includes published, '/en-US/LICENSE'
    refute_includes published, '/pt-BR/LICENSE'
  end
end

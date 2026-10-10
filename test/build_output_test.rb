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

  # Spec 001 AC3: an encyclopedia must not show invented numbers, placeholder
  # knowledge, dead actions or the build time presented as an edit date.
  FABRICATED = [
    /5,000\+/, /Edits Today/i, /Edições Hoje/i,
    /\b(Topic|Concept|Resource|Tópico|Conceito|Recurso) [123]\b/,
    /action="#"/,
  ].freeze

  def test_built_pages_contain_no_fabricated_content
    build_day = Time.now.strftime('%Y-%m-%d')
    offenders = Hash.new { |hash, key| hash[key] = [] }

    v1_pages.each do |file|
      html = File.read(file)
      text = html.gsub(/<script.*?<\/script>/m, ' ').gsub(/<[^>]+>/, ' ').squeeze(' ')
      FABRICATED.each { |pattern| offenders[pattern.source] << file if html.match?(pattern) }
      if text.match?(/(Last updated|Última atualização|Atualizado em):?\s*#{build_day}/i)
        offenders['build date shown as last updated'] << file
      end
    end

    report = offenders.map { |rule, files| "#{rule}: #{files.size} pages, e.g. #{files.first.delete_prefix(SiteBuild.site.dest)}" }
    assert_empty offenders, "Fabricated content:\n#{report.join("\n")}"
  end

  # The submodule LICENSE files collide with /<lang>/license/ on
  # case-insensitive filesystems (macOS), which breaks the build there.
  def test_submodule_license_files_are_not_published
    published = SiteBuild.site.static_files.map(&:relative_path)

    refute_includes published, '/en-US/LICENSE'
    refute_includes published, '/pt-BR/LICENSE'
  end

  private

  V1_LAYOUTS = %w[language_index categories category subcategory section wiki].freeze

  # Pages rendered by v1 layouts or generators. Static content pages from the
  # en-US/pt-BR submodules are out of scope for spec 001 (migrated later).
  def v1_pages
    site = SiteBuild.site
    site.pages
        .select { |page| page.is_a?(Jekyll::PageWithoutAFile) || V1_LAYOUTS.include?(page.data['layout']) || %w[index.html 404.html].include?(page.path) }
        .map { |page| page.destination(site.dest) }
        .select { |file| file.end_with?('.html') && File.file?(file) }
  end
end

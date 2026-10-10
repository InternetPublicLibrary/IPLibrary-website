require_relative 'test_helper'

class PageGenerationTest < Minitest::Test
  def site
    SiteBuild.site
  end

  def pages_at(url)
    site.pages.select { |page| page.url == url }
  end

  def test_generated_subcategory_page_is_served_at_its_directory_url
    assert_equal 1, pages_at('/en-US/academics/computer-science-theory/').size
    assert File.file?(File.join(site.dest, 'en-US/academics/computer-science-theory/index.html'))
  end

  def test_generated_wiki_page_is_served_at_its_directory_url
    assert_equal 1, pages_at('/en-US/academics/computer-science-theory/cryptography-theory/wiki/').size
  end

  def test_no_page_is_published_under_an_index_directory
    assert_empty site.pages.map(&:url).grep(%r{/index/\z})
  end

  def test_language_home_is_not_shadowed_by_a_generated_page
    %w[/en-US/ /pt-BR/].each do |url|
      homes = pages_at(url)

      assert_equal 1, homes.size, "expected a single page at #{url}"
      refute_kind_of Jekyll::PageWithoutAFile, homes.first
    end
  end
end

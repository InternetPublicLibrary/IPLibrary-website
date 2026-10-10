require_relative 'test_helper'
require_relative '../_plugins/search_index_generator'

# The search pages render index fields with innerHTML, so the index must hold inert text and safe URLs.
class SearchIndexSafetyTest < Minitest::Test
  def test_text_fields_are_html_escaped
    entry = Jekyll::SearchIndexGenerator.safe_entry(
      'title' => '<img src=x onerror=alert(1)>', 'description' => 'a & "b"', 'category' => '<b>c</b>',
      'url' => 'https://example.org/', 'type' => 'resource'
    )

    assert_equal '&lt;img src=x onerror=alert(1)&gt;', entry['title']
    assert_equal 'a &amp; &quot;b&quot;', entry['description']
    assert_equal '&lt;b&gt;c&lt;/b&gt;', entry['category']
  end

  def test_unsafe_url_schemes_are_rejected
    %w[javascript:alert(1) data:text/html,x //evil.example].each do |url|
      assert_nil Jekyll::SearchIndexGenerator.safe_entry('title' => 't', 'url' => url), url
    end
    refute_nil Jekyll::SearchIndexGenerator.safe_entry('title' => 't', 'url' => '/en-US/computing/')
  end
end

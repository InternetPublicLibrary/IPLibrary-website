require 'minitest/autorun'
require 'yaml'

# Spec 006: learning paths are IPL's own, cite only IPL curated resources and exist in both languages.
class LearningPathsTest < Minitest::Test
  ROOT = File.expand_path('..', __dir__)
  LANGS = %w[en-US pt-BR].freeze
  LEVELS = %w[beginner intermediate advanced].freeze

  def paths(lang)
    Dir[File.join(ROOT, "_data/#{lang}/learning-paths/*.yaml")].to_h { |f| [File.basename(f, '.yaml'), YAML.safe_load(File.read(f))] }
  end

  def curated_urls(lang)
    Dir[File.join(ROOT, "_data/#{lang}/*/*/*.yaml")].flat_map { |f| Array(YAML.safe_load(File.read(f))) }
                                                  .filter_map { |e| e['url'] if e.is_a?(Hash) }
                                                  .to_set { |u| normalize(u) }
  end

  def normalize(url) = url.to_s.strip.downcase.sub(%r{\Ahttps?://(www\.)?}, '').sub(%r{/+\z}, '')

  def test_both_languages_have_the_same_paths
    assert_equal paths('en-US').keys.sort, paths('pt-BR').keys.sort
  end

  def test_paths_are_well_formed_and_original
    LANGS.each do |lang|
      subcategories = Dir[File.join(ROOT, "_data/#{lang}/*/*/")].map { |d| d.delete_prefix(File.join(ROOT, "_data/#{lang}/")).chomp('/') }
      paths(lang).each do |slug, path|
        where = "#{lang}/#{slug}"
        %w[title summary subcategory level stages].each { |key| refute_nil path[key], "#{where}: missing #{key}" }
        assert_equal 'ipl', path['source'], "#{where}: source must be ipl"
        assert_includes LEVELS, path['level'], where
        assert_includes subcategories, path['subcategory'], "#{where}: unknown subcategory"
        steps = path['stages'].flat_map { |stage| stage['steps'] }
        assert_operator steps.size, :>=, 6, "#{where}: too few steps"
        steps.each { |step| assert step['title'] && step['summary'], "#{where}: step without title or summary" }
      end
    end
  end

  def test_step_resources_are_ipl_curated_resources
    LANGS.each do |lang|
      known = curated_urls(lang)
      paths(lang).each do |slug, path|
        path['stages'].flat_map { |stage| stage['steps'] }.each do |step|
          resources = Array(step['resources'])
          assert_operator resources.size, :>=, 1, "#{lang}/#{slug}: step '#{step['title']}' has no resources"
          resources.each { |url| assert_includes known, normalize(url), "#{lang}/#{slug}: #{url} is not curated" }
        end
      end
    end
  end
end

# Library totals (spec 002): unique curated resources per language, computed once per build instead of walking
# every data file from the footer of each page. Placeholders (example.com hosts) are not counted, and a resource
# listed in several subcategories counts once (by name, as components/atoms/real-resources.html does).
module IPL
  class ResourceStats < Jekyll::Generator
    priority :high
    PLACEHOLDER = %r{\Ahttps?://(?:[^/]+\.)?example\.(?:com|org|net)(?:[/:?#]|\z)}i

    def generate(site)
      site.data['resource_stats'] = site.config.fetch('languages', []).to_h do |language|
        code = language['code']
        [code, { 'resources' => names(site.data[code]).uniq.size }]
      end
    end

    private

    # Resource names anywhere under a language's data: lists of entries, files and subcategory folders.
    def names(node)
      case node
      when Array then node.flat_map { |item| resource?(item) ? [item['name']] : names(item) }
      when Hash then resource?(node) ? [node['name']] : node.except('menu', 'translations').values.flat_map { |value| names(value) }
      else []
      end
    end

    def resource?(item)
      item.is_a?(Hash) && item['url'].is_a?(String) && item['name'] && !item['url'].match?(PLACEHOLDER)
    end
  end
end

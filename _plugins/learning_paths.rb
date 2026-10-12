# Interactive learning paths (spec 006). Each _data/<lang>/learning-paths/<slug>.yaml becomes
# /<lang>/learning-paths/<slug>/, plus an index per language. Step resources are URLs of IPL's own curated entries;
# they are resolved to those entries here, and an unknown URL fails the build outside production.
module IPL
  class LearningPaths < Jekyll::Generator
    priority :normal
    safe true

    def generate(site)
      by_subcategory = {}
      site.config.fetch('languages', []).each do |language|
        lang = language['code']
        paths = (site.data.dig(lang, 'learning-paths') || {}).sort.map { |slug, path| [slug, path] }
        next if paths.empty?

        index = resource_index(site.data[lang])
        missing = []
        listed = paths.map do |slug, path|
          stages = Array(path['stages']).map do |stage|
            steps = Array(stage['steps']).map do |step|
              resources = Array(step['resources']).filter_map do |url|
                entry = index[normalize(url)]
                missing << "#{lang}/#{slug}: #{url}" unless entry
                entry
              end
              step.merge('resources' => resources)
            end
            stage.merge('steps' => steps)
          end
          step_count = stages.sum { |stage| stage['steps'].size }
          url = "/#{lang}/learning-paths/#{slug}/"
          data = path.merge('layout' => 'learning-path', 'lang' => lang, 'slug' => slug, 'stages' => stages,
                            'step_count' => step_count, 'description' => path['summary'],
                            'additional_js' => ['/javascript/learning-path.js'])
          add_page(site, "#{lang}/learning-paths/#{slug}", data)
          summary = { 'title' => path['title'], 'summary' => path['summary'], 'level' => path['level'],
                      'url' => url, 'step_count' => step_count, 'subcategory' => path['subcategory'] }
          (by_subcategory[lang] ||= {})[path['subcategory']] = (by_subcategory.dig(lang, path['subcategory']) || []) + [summary]
          summary
        end

        pt = lang == 'pt-BR'
        add_page(site, "#{lang}/learning-paths", {
          'layout' => 'learning-paths', 'lang' => lang, 'paths' => listed,
          'title' => pt ? 'Trilhas de aprendizado' : 'Learning paths',
          'description' => pt ? 'Caminhos de estudo em etapas, montados com os recursos curados da IPL.' : 'Step-by-step study paths built from IPL’s curated resources.'
        })
        report(site, missing)
      end
      site.data['learning_paths_by_subcategory'] = by_subcategory
    end

    private

    def add_page(site, dir, data)
      page = Jekyll::PageWithoutAFile.new(site, site.source, dir, 'index.html')
      page.content = ''
      page.data = data
      site.pages << page
    end

    # Curated entries of one language by URL (lists, files and subcategory folders).
    def resource_index(node, index = {})
      case node
      when Array then node.each { |item| item.is_a?(Hash) && item['url'] && item['name'] ? (index[normalize(item['url'])] ||= item) : resource_index(item, index) }
      when Hash then node.each { |key, value| resource_index(value, index) unless %w[menu translations learning-paths].include?(key) }
      end
      index
    end

    def normalize(url)
      url.to_s.strip.downcase.sub(%r{\Ahttps?://(www\.)?}, '').sub(%r{/+\z}, '')
    end

    def report(site, missing)
      return if missing.empty?

      message = "Learning paths cite URLs that are not IPL curated resources:\n  #{missing.join("\n  ")}"
      raise Jekyll::Errors::FatalException, message unless Jekyll.env == 'production'

      Jekyll.logger.warn 'LearningPaths:', message
    end
  end
end

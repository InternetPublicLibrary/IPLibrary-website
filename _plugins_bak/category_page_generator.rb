module Jekyll
  class CategoryPageGenerator < Generator
    safe true
    priority :normal

    def generate(site)
      # Processar cada idioma
      ['en-US', 'pt-BR'].each do |lang|
        lang_data = site.data[lang]
        next unless lang_data && lang_data['menu']

        # Gerar páginas para cada categoria principal
        lang_data['menu'].each do |category|
          create_category_page(site, lang, category)
          
          # Gerar páginas para subcategorias se existirem
          if category['children']
            category['children'].each do |subcategory|
              create_subcategory_page(site, lang, category, subcategory)
            end
          end
        end
      end
    end

    private

    def create_category_page(site, lang, category)
      # Preparar dados da categoria
      category_data = {
        'layout' => 'category',
        'title' => "#{category['title']} - Internet Public Library",
        'lang' => lang,
        'description' => category['description'] || "Explore #{category['title']} resources in the Internet Public Library.",
        'category' => category['path']&.split('/')&.last || category['title'].downcase.gsub(/\s+/, '-'),
        'category_data' => category,
        'permalink' => category['path'] || "/#{lang}/#{category['title'].downcase.gsub(/\s+/, '-')}/"
      }

      # Criar conteúdo dinâmico
      content = generate_category_content(lang, category)

      # Criar página com path específico
      page = CategoryPage.new(site, site.source, category['path'], category_data, content)
      site.pages << page
      
      puts "Generated category page: #{category['path']} (#{lang})"
    end

    def create_subcategory_page(site, lang, parent_category, subcategory)
      # Preparar dados da subcategoria
      subcategory_data = {
        'layout' => 'subcategory',
        'title' => "#{subcategory['title']} - #{parent_category['title']} - Internet Public Library",
        'lang' => lang,
        'description' => subcategory['description'] || "Explore #{subcategory['title']} resources in #{parent_category['title']}.",
        'category' => parent_category['path']&.split('/')&.last || parent_category['title'].downcase.gsub(/\s+/, '-'),
        'subcategory' => subcategory['path']&.split('/')&.last || subcategory['title'].downcase.gsub(/\s+/, '-'),
        'parent_category' => parent_category,
        'subcategory_data' => subcategory,
        'permalink' => subcategory['path'] || "/#{lang}/#{parent_category['title'].downcase.gsub(/\s+/, '-')}/#{subcategory['title'].downcase.gsub(/\s+/, '-')}/"
      }

      # Criar conteúdo dinâmico
      content = generate_subcategory_content(lang, parent_category, subcategory)

      # Criar página
      page = CategoryPage.new(site, site.source, subcategory['path'], subcategory_data, content)
      site.pages << page
      
      puts "Generated subcategory page: #{subcategory['path']} (#{lang})"
    end

    def generate_category_content(lang, category)
      # Conteúdo dinâmico baseado no idioma
      translations = {
        'en-US' => {
          'explore' => 'Explore',
          'subcategories' => 'Subcategories',
          'resources' => 'Resources',
          'featured' => 'Featured Resources',
          'description' => 'Discover comprehensive resources in',
          'subcategories_title' => 'Subcategories',
          'featured_description' => 'Handpicked resources selected by our expert curators.',
          'view_featured' => 'View Featured Resources'
        },
        'pt-BR' => {
          'explore' => 'Explorar',
          'subcategories' => 'Subcategorias',
          'resources' => 'Recursos',
          'featured' => 'Recursos em Destaque',
          'description' => 'Descubra recursos abrangentes em',
          'subcategories_title' => 'Subcategorias',
          'featured_description' => 'Recursos selecionados pelos nossos curadores especialistas.',
          'view_featured' => 'Ver Recursos em Destaque'
        }
      }

      t = translations[lang] || translations['en-US']
      icon = get_category_icon(category['title'])
      
      <<~HTML
        <div class="min-h-screen bg-gradient-to-br from-slate-50 via-blue-50 to-indigo-50">
          <!-- Category Header -->
          <div class="relative bg-white border-b border-slate-200 shadow-sm">
            <div class="absolute inset-0 bg-gradient-to-r from-blue-600/5 to-purple-600/5"></div>
            <div class="relative max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
              <div class="text-center">
                <div class="flex items-center justify-center mb-4">
                  <div class="p-3 bg-gradient-to-br from-blue-600 to-purple-600 rounded-2xl shadow-lg">
                    <i class="fas fa-#{icon} text-white text-2xl"></i>
                  </div>
                </div>
                <h1 class="text-4xl md:text-5xl font-bold bg-gradient-to-r from-slate-900 via-blue-900 to-purple-900 bg-clip-text text-transparent mb-4">
                  #{category['title']} #{t['resources']}
                </h1>
                <p class="text-xl text-slate-700 max-w-3xl mx-auto leading-relaxed">
                  #{t['description']} #{category['title'].downcase}#{category['description'] ? '. ' + category['description'] : '.'}
                </p>
              </div>
            </div>
          </div>

          <!-- Main Content -->
          <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
            <!-- Quick Stats -->
            <div class="grid grid-cols-2 md:grid-cols-4 gap-4 mb-12">
              <div class="bg-white rounded-xl p-6 shadow-sm border border-slate-200 text-center">
                <div class="text-2xl font-bold text-blue-600 mb-1">#{category['children']&.size || 0}</div>
                <div class="text-sm text-slate-600">#{t['subcategories']}</div>
              </div>
              <div class="bg-white rounded-xl p-6 shadow-sm border border-slate-200 text-center">
                <div class="text-2xl font-bold text-green-600 mb-1">#{rand(50..300)}+</div>
                <div class="text-sm text-slate-600">#{t['resources']}</div>
              </div>
              <div class="bg-white rounded-xl p-6 shadow-sm border border-slate-200 text-center">
                <div class="text-2xl font-bold text-purple-600 mb-1">#{lang == 'en-US' ? 'Weekly' : 'Semanal'}</div>
                <div class="text-sm text-slate-600">#{lang == 'en-US' ? 'Updates' : 'Atualizações'}</div>
              </div>
              <div class="bg-white rounded-xl p-6 shadow-sm border border-slate-200 text-center">
                <div class="text-2xl font-bold text-orange-600 mb-1">#{lang == 'en-US' ? 'Expert' : 'Expert'}</div>
                <div class="text-sm text-slate-600">#{lang == 'en-US' ? 'Curated' : 'Curado'}</div>
              </div>
            </div>

            #{generate_subcategories_grid(lang, category, t) if category['children']}

            <!-- Featured Resources -->
            <div class="bg-slate-900 rounded-2xl p-8 text-center">
              <h3 class="text-2xl font-bold text-white mb-4">#{t['featured']} #{category['title']}</h3>
              <p class="text-slate-300 mb-6 max-w-2xl mx-auto">
                #{t['featured_description']}
              </p>
              <a href="#{category['path']}/featured/" class="inline-flex items-center px-6 py-3 bg-blue-600 text-white font-semibold rounded-xl hover:bg-blue-700 transition-colors duration-200">
                <i class="fas fa-star mr-2"></i>
                #{t['view_featured']}
              </a>
            </div>
          </div>
        </div>
      HTML
    end

    def generate_subcategories_grid(lang, category, t)
      return '' unless category['children']
      
      subcategories_html = category['children'].map do |subcategory|
        icon = get_subcategory_icon(subcategory['title'])
        <<~HTML
          <div class="group bg-white rounded-2xl p-6 shadow-sm border border-slate-200 hover:shadow-xl hover:border-blue-300 transition-all duration-300">
            <div class="flex items-center mb-4">
              <div class="p-3 bg-blue-100 rounded-xl">
                <i class="fas fa-#{icon} text-blue-600 text-xl"></i>
              </div>
              <h3 class="ml-4 text-xl font-semibold text-slate-900">#{subcategory['title']}</h3>
            </div>
            <p class="text-slate-600 mb-4">#{subcategory['description'] || "#{t['explore']} #{subcategory['title'].downcase} resources and tools."}</p>
            <a href="#{subcategory['path']}" class="inline-flex items-center text-blue-600 hover:text-blue-800 font-medium group-hover:translate-x-1 transition-all duration-200">
              #{t['explore']} #{subcategory['title']}
              <i class="fas fa-arrow-right ml-2"></i>
            </a>
          </div>
        HTML
      end.join("\n")

      <<~HTML
        <!-- Subcategories Grid -->
        <div class="mb-12">
          <h2 class="text-3xl font-bold text-slate-900 mb-8">#{category['title']} #{t['subcategories_title']}</h2>
          <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            #{subcategories_html}
          </div>
        </div>
      HTML
    end

    def generate_subcategory_content(lang, parent_category, subcategory)
      # Implementação para subcategorias (similar à categoria principal)
      generate_category_content(lang, subcategory.merge('title' => "#{subcategory['title']} - #{parent_category['title']}"))
    end

    def get_category_icon(title)
      icons = {
        'Business' => 'briefcase',
        'Computing' => 'microchip',
        'Design' => 'paint-brush',
        'Development' => 'code',
        'Marketing' => 'bullhorn',
        'Personal Development' => 'user-graduate',
        'Photography' => 'camera',
        'Academics' => 'graduation-cap'
      }
      icons[title] || 'folder'
    end

    def get_subcategory_icon(title)
      icons = {
        'Finance' => 'dollar-sign',
        'Entrepreneurship' => 'rocket',
        'Management' => 'users',
        'Human Resources' => 'user-friends',
        'Sales' => 'chart-line',
        'Strategy' => 'chess',
        'Computer Science' => 'atom',
        'Data Science' => 'chart-bar',
        'Cybersecurity' => 'shield-alt',
        'Operating Systems' => 'desktop',
        'Hardware' => 'memory',
        'Networking' => 'network-wired'
      }
      icons[title] || 'cog'
    end
  end

  class CategoryPage < Page
    def initialize(site, base, dir_path, data, content)
      @site = site
      @base = base
      @dir = dir_path.gsub(/^\//, '').gsub(/\/$/, '')  # Remove leading/trailing slashes
      @name = 'index.html'

      self.process(@name)
      self.data = data
      self.content = content
    end
  end
end 

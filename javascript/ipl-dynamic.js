/**
 * IPL Dynamic Features
 * - Random featured article based on day of month
 * - GitHub recent changes from 3 repos
 * - ORCID article search
 * - Meetup events search
 */

const IPL = {
    // GitHub repos to fetch commits from
    GITHUB_REPOS: [
        'InternetPublicLibrary/IPLibrary-website',
        'InternetPublicLibrary/en-US',
        'InternetPublicLibrary/pt-BR'
    ],

    // Categories for random featured article
    FEATURED_TOPICS: {
        'en-US': [
            { title: 'Artificial Intelligence and Machine Learning', category: 'computing', path: '/en-US/computing/artificial-intelligence/' },
            { title: 'Web Development Fundamentals', category: 'development', path: '/en-US/development/frontend-development/' },
            { title: 'Data Science and Analytics', category: 'computing', path: '/en-US/computing/data-science/' },
            { title: 'Digital Marketing Strategies', category: 'marketing', path: '/en-US/marketing/digital-marketing/' },
            { title: 'UX Design Principles', category: 'design', path: '/en-US/design/user-experience/' },
            { title: 'Cybersecurity Essentials', category: 'computing', path: '/en-US/computing/cyber-security/' },
            { title: 'Business Finance Basics', category: 'business', path: '/en-US/business/finance/' },
            { title: 'Photography Techniques', category: 'photography', path: '/en-US/photography/photography-fundamentals/' },
            { title: 'Leadership and Management', category: 'personal-development', path: '/en-US/personal-development/leadership/' },
            { title: 'Mathematics for Programmers', category: 'academics', path: '/en-US/academics/formal-sciences/' },
            { title: 'Backend Development with Node.js', category: 'development', path: '/en-US/development/backend-development/' },
            { title: 'SEO Best Practices', category: 'marketing', path: '/en-US/marketing/seo/' },
            { title: 'Graphic Design Fundamentals', category: 'design', path: '/en-US/design/graphic-design/' },
            { title: 'Entrepreneurship Guide', category: 'business', path: '/en-US/business/entrepreneurship/' },
            { title: 'Psychology and Behavior', category: 'academics', path: '/en-US/academics/social-sciences/' },
            { title: 'Cloud Computing Basics', category: 'computing', path: '/en-US/computing/distributed-computing/' },
            { title: 'Mobile App Development', category: 'development', path: '/en-US/development/plataforms/' },
            { title: 'Content Marketing Strategies', category: 'marketing', path: '/en-US/marketing/content-marketing/' },
            { title: 'Personal Productivity Tips', category: 'personal-development', path: '/en-US/personal-development/productivity/' },
            { title: 'Statistics and Data Analysis', category: 'academics', path: '/en-US/academics/formal-sciences/' },
            { title: 'Game Development Basics', category: 'development', path: '/en-US/development/game-development/' },
            { title: 'Project Management', category: 'business', path: '/en-US/business/project-management/' },
            { title: 'Natural Language Processing', category: 'computing', path: '/en-US/computing/natural-language-processing/' },
            { title: 'Interior Design Concepts', category: 'design', path: '/en-US/design/interior-design/' },
            { title: 'History and Humanities', category: 'academics', path: '/en-US/academics/humanities/' },
            { title: 'Database Management', category: 'development', path: '/en-US/development/databases/' },
            { title: 'Travel Photography Tips', category: 'photography', path: '/en-US/photography/travel-photography/' },
            { title: 'Social Media Marketing', category: 'marketing', path: '/en-US/marketing/social-media/' },
            { title: 'Career Development', category: 'personal-development', path: '/en-US/personal-development/career-development/' },
            { title: 'Physics and Natural Sciences', category: 'academics', path: '/en-US/academics/natural-sciences/' },
            { title: 'Software Testing Practices', category: 'development', path: '/en-US/development/software-testing/' }
        ],
        'pt-BR': [
            { title: 'Inteligência Artificial e Machine Learning', category: 'computing', path: '/pt-BR/computacao/' },
            { title: 'Fundamentos de Desenvolvimento Web', category: 'development', path: '/pt-BR/desenvolvimento/' },
            { title: 'Ciência de Dados e Análise', category: 'computing', path: '/pt-BR/computacao/' },
            { title: 'Estratégias de Marketing Digital', category: 'marketing', path: '/pt-BR/marketing/' },
            { title: 'Princípios de Design UX', category: 'design', path: '/pt-BR/design/' },
            { title: 'Fundamentos de Cibersegurança', category: 'computing', path: '/pt-BR/computacao/' },
            { title: 'Conceitos de Finanças Empresariais', category: 'business', path: '/pt-BR/negocios/' },
            { title: 'Técnicas de Fotografia', category: 'photography', path: '/pt-BR/fotografia/' },
            { title: 'Liderança e Gestão', category: 'personal-development', path: '/pt-BR/desenvolvimento-pessoal/' },
            { title: 'Matemática para Programadores', category: 'academics', path: '/pt-BR/academicos/' },
            { title: 'Desenvolvimento Backend com Node.js', category: 'development', path: '/pt-BR/desenvolvimento/' },
            { title: 'Melhores Práticas de SEO', category: 'marketing', path: '/pt-BR/marketing/' },
            { title: 'Fundamentos de Design Gráfico', category: 'design', path: '/pt-BR/design/' },
            { title: 'Guia de Empreendedorismo', category: 'business', path: '/pt-BR/negocios/' },
            { title: 'Psicologia e Comportamento', category: 'academics', path: '/pt-BR/academicos/' },
            { title: 'Conceitos de Computação em Nuvem', category: 'computing', path: '/pt-BR/computacao/' },
            { title: 'Desenvolvimento de Apps Mobile', category: 'development', path: '/pt-BR/desenvolvimento/' },
            { title: 'Estratégias de Marketing de Conteúdo', category: 'marketing', path: '/pt-BR/marketing/' },
            { title: 'Dicas de Produtividade Pessoal', category: 'personal-development', path: '/pt-BR/desenvolvimento-pessoal/' },
            { title: 'Estatística e Análise de Dados', category: 'academics', path: '/pt-BR/academicos/' },
            { title: 'Fundamentos de Desenvolvimento de Jogos', category: 'development', path: '/pt-BR/desenvolvimento/' },
            { title: 'Gerenciamento de Projetos', category: 'business', path: '/pt-BR/negocios/' },
            { title: 'Processamento de Linguagem Natural', category: 'computing', path: '/pt-BR/computacao/' },
            { title: 'Conceitos de Design de Interiores', category: 'design', path: '/pt-BR/design/' },
            { title: 'História e Humanidades', category: 'academics', path: '/pt-BR/academicos/' },
            { title: 'Gerenciamento de Banco de Dados', category: 'development', path: '/pt-BR/desenvolvimento/' },
            { title: 'Dicas de Fotografia de Viagem', category: 'photography', path: '/pt-BR/fotografia/' },
            { title: 'Marketing em Redes Sociais', category: 'marketing', path: '/pt-BR/marketing/' },
            { title: 'Desenvolvimento de Carreira', category: 'personal-development', path: '/pt-BR/desenvolvimento-pessoal/' },
            { title: 'Física e Ciências Naturais', category: 'academics', path: '/pt-BR/academicos/' },
            { title: 'Práticas de Teste de Software', category: 'development', path: '/pt-BR/desenvolvimento/' }
        ]
    },

    /**
     * Get featured article based on day of month
     */
    getFeaturedArticle(lang = 'en-US') {
        const day = new Date().getDate(); // 1-31
        const topics = this.FEATURED_TOPICS[lang] || this.FEATURED_TOPICS['en-US'];
        const index = (day - 1) % topics.length;
        return topics[index];
    },

    /**
     * Render featured article in the DOM
     */
    renderFeaturedArticle(containerId, lang = 'en-US') {
        const container = document.getElementById(containerId);
        if (!container) return;

        const article = this.getFeaturedArticle(lang);
        const isPortuguese = lang === 'pt-BR';

        container.innerHTML = `
      <h3 class="text-xl font-semibold text-slate-900 mb-3">${article.title}</h3>
      <p class="text-slate-600 mb-4 leading-relaxed">
        ${isPortuguese ? 'Explore recursos selecionados sobre este tema em nossa biblioteca.' : 'Explore curated resources on this topic in our library.'}
      </p>
      <div class="flex items-center justify-between">
        <div class="flex items-center text-sm text-slate-500">
          <i class="fas fa-calendar mr-2"></i>
          ${new Date().toLocaleDateString(lang === 'pt-BR' ? 'pt-BR' : 'en-US', { month: 'long', day: 'numeric', year: 'numeric' })}
        </div>
        <a href="${article.path}" class="inline-flex items-center text-blue-600 hover:text-blue-800 font-medium">
          ${isPortuguese ? 'Explorar' : 'Explore'} <i class="fas fa-arrow-right ml-2"></i>
        </a>
      </div>
    `;
    },

    /**
     * Fetch recent commits from GitHub repos
     */
    async fetchGitHubCommits(limit = 5) {
        const commits = [];

        for (const repo of this.GITHUB_REPOS) {
            try {
                const response = await fetch(`https://api.github.com/repos/${repo}/commits?per_page=${limit}`);
                if (response.ok) {
                    const data = await response.json();
                    commits.push(...data.map(commit => ({
                        repo: repo.split('/')[1],
                        message: commit.commit.message.split('\n')[0],
                        author: commit.commit.author.name,
                        date: new Date(commit.commit.author.date),
                        url: commit.html_url
                    })));
                }
            } catch (error) {
                console.error(`Error fetching commits from ${repo}:`, error);
            }
        }

        // Sort by date and limit
        return commits.sort((a, b) => b.date - a.date).slice(0, limit);
    },

    /**
     * Render recent GitHub activity
     */
    async renderRecentChanges(containerId, lang = 'en-US') {
        const container = document.getElementById(containerId);
        if (!container) return;

        const isPortuguese = lang === 'pt-BR';
        container.innerHTML = `<div class="animate-pulse text-slate-500">${isPortuguese ? 'Carregando...' : 'Loading...'}</div>`;

        try {
            const commits = await this.fetchGitHubCommits(5);

            if (commits.length === 0) {
                container.innerHTML = `<p class="text-slate-500">${isPortuguese ? 'Sem alterações recentes' : 'No recent changes'}</p>`;
                return;
            }

            container.innerHTML = commits.map(commit => `
        <div class="flex items-start gap-2 text-sm py-2 border-b border-slate-100 last:border-0">
          <i class="fas fa-code-commit text-green-500 mt-1"></i>
          <div class="flex-1 min-w-0">
            <a href="${commit.url}" target="_blank" class="text-slate-700 hover:text-blue-600 line-clamp-1">${commit.message}</a>
            <div class="text-xs text-slate-500">
              <span class="bg-slate-100 px-1 rounded">${commit.repo}</span>
              · ${this.timeAgo(commit.date, lang)}
            </div>
          </div>
        </div>
      `).join('');
        } catch (error) {
            container.innerHTML = `<p class="text-red-500">${isPortuguese ? 'Erro ao carregar' : 'Error loading'}</p>`;
        }
    },

    /**
     * Search ORCID for academic articles
     */
    async searchOrcidArticles(query, limit = 5) {
        try {
            // ORCID public API search
            const response = await fetch(`https://pub.orcid.org/v3.0/search/?q=${encodeURIComponent(query)}&rows=${limit}`, {
                headers: { 'Accept': 'application/json' }
            });

            if (response.ok) {
                const data = await response.json();
                return data.result || [];
            }
        } catch (error) {
            console.error('ORCID search error:', error);
        }
        return [];
    },

    /**
     * Search Meetup for events (using public API)
     */
    async searchMeetupEvents(topic, limit = 5) {
        // Note: Meetup requires OAuth for full API access
        // This is a placeholder for integration
        // In production, you'd use a backend proxy with API credentials
        console.log('Meetup search for:', topic);
        return [];
    },

    /**
     * Time ago helper
     */
    timeAgo(date, lang = 'en-US') {
        const seconds = Math.floor((new Date() - date) / 1000);
        const isPortuguese = lang === 'pt-BR';

        const intervals = [
            { label: isPortuguese ? ['ano', 'anos'] : ['year', 'years'], seconds: 31536000 },
            { label: isPortuguese ? ['mês', 'meses'] : ['month', 'months'], seconds: 2592000 },
            { label: isPortuguese ? ['dia', 'dias'] : ['day', 'days'], seconds: 86400 },
            { label: isPortuguese ? ['hora', 'horas'] : ['hour', 'hours'], seconds: 3600 },
            { label: isPortuguese ? ['minuto', 'minutos'] : ['minute', 'minutes'], seconds: 60 }
        ];

        for (const interval of intervals) {
            const count = Math.floor(seconds / interval.seconds);
            if (count >= 1) {
                const label = count === 1 ? interval.label[0] : interval.label[1];
                return isPortuguese ? `há ${count} ${label}` : `${count} ${label} ago`;
            }
        }

        return isPortuguese ? 'agora' : 'just now';
    },

    /**
     * Initialize all dynamic features
     */
    init(lang = 'en-US') {
        // Random featured article
        this.renderFeaturedArticle('featured-article-content', lang);

        // Recent GitHub changes
        this.renderRecentChanges('recent-changes-content', lang);
    }
};

// Auto-initialize when DOM is ready
document.addEventListener('DOMContentLoaded', () => {
    const lang = document.documentElement.lang || 'en-US';
    IPL.init(lang);
});

// Export for module usage
if (typeof module !== 'undefined' && module.exports) {
    module.exports = IPL;
}

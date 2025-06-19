# 🤖 IPLibrary Development Agents Guide

## 🎯 Mission
Build the world's most comprehensive, community-driven, multilingual digital library with cutting-edge technology and exceptional user experience.

## 🏗️ Architecture Principles

### 1. Component-Driven Development
```
_includes/components/
├── atoms/          # Basic UI elements (buttons, inputs, badges)
├── molecules/      # Composite components (forms, cards, navigation)
└── organisms/      # Complex sections (headers, footers, sidebars)
```

### 2. Design System
- **Framework**: TailwindCSS with custom design tokens
- **Style**: Futuristic, clean, elegant, Wikipedia-inspired
- **Responsive**: Mobile-first approach
- **Accessibility**: WCAG 2.1 AA compliance
- **Performance**: Optimized for speed and efficiency

### 3. Multilingual Architecture
```
Structure:
/en-US/     # English (US) content
/pt-BR/     # Portuguese (Brazil) content
/api/en-us/ # English API endpoints
/api/pt-br/ # Portuguese API endpoints
```

## 🛠️ Development Guidelines

### Code Quality Standards
1. **DRY Principle**: Avoid code duplication through reusable components
2. **KISS Principle**: Keep implementations simple and maintainable
3. **Performance First**: Optimize for speed and efficiency
4. **Security Conscious**: Implement secure coding practices
5. **Documentation**: Document all components and functions

### File Organization
```
Components Hierarchy:
- Atoms: Single-purpose, reusable elements
- Molecules: Combinations of atoms serving specific functions
- Organisms: Complex components combining molecules and atoms
- Templates: Page-level layouts using organisms
- Pages: Specific instances of templates with real content
```

### Naming Conventions
- **Files**: kebab-case (search-form.html)
- **CSS Classes**: Tailwind utility classes
- **Variables**: snake_case for Liquid, camelCase for JavaScript
- **IDs**: kebab-case with semantic meaning

## 🚀 Build System

### Jekyll Plugins Strategy
1. **Page Generation**: Intelligent batch page creation
2. **Performance Monitoring**: Build time optimization
3. **Cache Management**: Template and data caching
4. **Quality Assurance**: Automated link checking and validation

### Performance Targets
- Build time: < 5 seconds
- First Contentful Paint: < 1 second
- Time to Interactive: < 2 seconds
- Lighthouse Score: > 90

## 🌐 Internationalization

### Language Support
- **Primary**: English (en-US)
- **Secondary**: Portuguese (pt-BR)
- **Future**: Spanish, French, German, Chinese, Japanese

### Content Strategy
1. **Structure Consistency**: Maintain identical navigation across languages
2. **Cultural Adaptation**: Adapt content for local contexts
3. **Translation Workflow**: Streamlined contributor process
4. **Quality Control**: Native speaker review process

## 🔧 Technical Implementation

### Required Components

#### Atoms (Basic Elements)
- `button.html`: Standardized button styles
- `input.html`: Form input elements
- `badge.html`: Status and category badges
- `avatar.html`: User profile images
- `card.html`: Basic card container
- `loading-spinner.html`: Loading indicators

#### Molecules (Composite Components)
- `search-form.html`: Search functionality
- `resource-card.html`: Resource display cards
- `category-card.html`: Category navigation cards
- `breadcrumb.html`: Navigation breadcrumbs
- `language-switcher.html`: Language selection
- `pagination.html`: Content pagination

#### Organisms (Complex Sections)
- `header.html`: Site navigation header
- `footer.html`: Site footer with links
- `sidebar.html`: Category navigation sidebar
- `hero-section.html`: Homepage hero area
- `category-grid.html`: Category overview grid
- `resource-grid.html`: Resource listing grid

### API Architecture
```yaml
Endpoints:
  /api/en-us/categories.json      # Category list
  /api/en-us/resources.json       # All resources
  /api/en-us/search.json          # Search index
  /api/pt-br/categories.json      # Portuguese categories
  /api/pt-br/resources.json       # Portuguese resources
  /api/pt-br/search.json          # Portuguese search
```

## 📝 Content Management

### Wiki System
- **WYSIWYG Editor**: Inline editing capabilities
- **Version Control**: Git-based versioning
- **Collaboration**: Multi-user editing support
- **Preview System**: Live preview before publishing

### Resource Curation
```yaml
Resource Schema:
  title: string
  description: string
  url: string
  category: string
  subcategory: string
  type: enum[blog, course, tool, publication, event]
  tags: array
  language: string
  last_verified: date
  quality_score: number
  contributor: string
```

### Quality Standards
1. **Link Verification**: Automated broken link detection
2. **Content Review**: Community moderation system
3. **Duplicate Detection**: Prevent duplicate entries
4. **Quality Scoring**: Automated quality assessment

## 🎨 Design Specifications

### Color Palette
```css
:root {
  --primary-50: #eff6ff;
  --primary-500: #3b82f6;
  --primary-900: #1e3a8a;
  --accent-500: #8b5cf6;
  --neutral-50: #f8fafc;
  --neutral-900: #0f172a;
  --success-500: #10b981;
  --warning-500: #f59e0b;
  --error-500: #ef4444;
}
```

### Typography
- **Primary Font**: Inter (system font fallback)
- **Monospace**: JetBrains Mono (code blocks)
- **Scale**: Tailwind's default typography scale
- **Line Height**: Optimized for readability

### Spacing & Layout
- **Grid**: 12-column responsive grid
- **Breakpoints**: Tailwind's default breakpoints
- **Container**: Max-width with responsive padding
- **Vertical Rhythm**: Consistent spacing scale

## 🤝 Community Features

### Discussion System
- **Engine**: Giscus (GitHub Discussions)
- **Integration**: Per-page discussions
- **Moderation**: Community-driven moderation
- **Languages**: Separate discussions per language

### Contribution Workflow
1. **GitHub Integration**: Staticman for form submissions
2. **Pull Request System**: Automated PR creation
3. **Review Process**: Community review and approval
4. **Recognition System**: Contributor profiles and stats

## 🔍 Search & Discovery

### Search Implementation
- **Engine**: Client-side search with Lunr.js
- **Features**: Fuzzy search, autocomplete, filters
- **Performance**: Indexed JSON for fast results
- **Multilingual**: Language-specific search indexes

### Navigation Features
- **Faceted Browsing**: Filter by category, type, language
- **Random Discovery**: Random resource feature
- **Recent Changes**: Activity feed
- **Popular Resources**: Trending content

## 📊 Analytics & Monitoring

### Performance Monitoring
- **Build Performance**: Track generation times
- **User Analytics**: Privacy-respecting analytics
- **Error Tracking**: Automated error reporting
- **Content Performance**: Popular content tracking

### Quality Metrics
- **Link Health**: Broken link monitoring
- **Content Freshness**: Update frequency tracking
- **User Engagement**: Interaction metrics
- **Contribution Activity**: Community health metrics

## 🚨 Error Handling & Maintenance

### Error Pages
- **404 Page**: Helpful navigation and search
- **Maintenance Mode**: Scheduled maintenance page
- **Error Recovery**: Graceful degradation strategies

### Monitoring & Alerts
- **Build Failures**: Automated notifications
- **Performance Degradation**: Performance alerts
- **Security Issues**: Security monitoring
- **Content Issues**: Quality alerts

## 🔄 Deployment & CI/CD

### Build Process
1. **Content Validation**: YAML and Markdown validation
2. **Link Checking**: Automated link verification
3. **Performance Testing**: Lighthouse CI
4. **Security Scanning**: Automated security checks

### Deployment Strategy
- **Platform**: GitHub Pages (Jekyll)
- **CDN**: GitHub's global CDN
- **SSL**: Automatic HTTPS
- **Backup**: Git-based version control

## 📚 Documentation Standards

### Code Documentation
- **Components**: Document props and usage
- **Functions**: JSDoc-style documentation
- **APIs**: OpenAPI specification
- **Guides**: Step-by-step implementation guides

### User Documentation
- **Contributing Guide**: How to contribute content
- **Style Guide**: Content formatting standards
- **API Documentation**: Developer resources
- **FAQ**: Common questions and answers

---

**Remember**: Every change should improve user experience, maintain performance, and enhance community collaboration. When in doubt, prioritize simplicity, accessibility, and performance.

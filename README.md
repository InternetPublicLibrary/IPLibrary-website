IPLibrary

## Build System

The IPLibrary website uses a static page generation system that creates all pages during the build process. This approach improves performance and simplifies deployment.

### How it Works

1. Data is stored in YAML files within the `_data/[language]` directories
2. During build time, a Rake-based generator processes this data and creates static pages
3. The Jekyll build process then processes these pages and produces the final site

### Build Process

To build the site:

```bash
# Full build process
./build.sh

# Or run individual steps
bundle exec rake iplibrary:generate_all   # Generate all pages
bundle exec jekyll build                  # Build the Jekyll site
```

### Page Types

The generator creates several types of pages:
- Category pages - Lists of subcategories
- Subcategory pages - Lists of sections
- Section pages - Lists of resources
- Resource pages - Individual resource details
- Index pages - Home and category listing pages

### Data Structure

- `_data/[language]/menu.yaml` - Contains the category hierarchy
- `_data/[language]/[category]/*.yaml` - Contains resource data for specific categories

### Templates

Page templates are stored in `_includes/templates/` and define the content structure for each page type.

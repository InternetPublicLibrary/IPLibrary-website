# Dynamic Pages System

This document explains how the Internet Public Library uses Jekyll to dynamically generate pages based on the menu structure defined in YAML files.

## Overview

The website automatically generates all category, subcategory, and section pages based on the structure defined in `_data/[language]/menu.yaml` files. This approach ensures that:

1. The navigation structure and page hierarchy are maintained in a single source of truth
2. Pages are generated consistently with proper templates
3. Navigation between related pages is automatic
4. New sections can be added by simply updating the menu YAML files

## How It Works

### 1. Menu Structure (YAML)

All menu structures are defined in YAML files at:
- `_data/en-US/menu.yaml` (for English)
- `_data/pt-BR/menu.yaml` (for Portuguese)

The YAML structure follows this pattern:

```yaml
- title: Category Name
  path: /en-US/category-name/
  children:
    - title: Subcategory Name
      path: /en-US/category-name/subcategory-name/
      children:
        - title: Section Name
          path: /en-US/category-name/subcategory-name/section-name/
```

### 2. Page Generation

During the Jekyll build process, a custom generator plugin (`_plugins/generate_menu_pages.rb`) reads the menu structure and creates pages for each entry. It:

1. Creates category pages with the `category` layout
2. Creates subcategory pages with the `subcategory` layout
3. Creates section pages with the `section` layout

### 3. Page Templates

The content for each page is sourced from template files:
- `_includes/templates/category-content.md`
- `_includes/templates/subcategory-content.md`
- `_includes/templates/section-content.md`

These templates provide default content that is processed with Liquid tags to customize it for each specific page.

### 4. Layouts

The visual structure and navigation for each page is controlled by layout files:
- `_layouts/category.html`
- `_layouts/subcategory.html`
- `_layouts/section.html`

These layouts provide consistent page structure, navigation sidebars, breadcrumbs, and content display.

## Adding New Content

### To add a new category, subcategory, or section:

1. Edit the appropriate `menu.yaml` file
2. Add the new entry with a title and path
3. If it has children, add them as nested entries
4. Run Jekyll to build the site

The system will automatically generate all necessary pages.

### To customize content for a specific page:

Create a Markdown file at the path specified in the menu.yaml with the same frontmatter as the generated page. Jekyll will use your custom content instead of the template content.

For example, to customize a category page:

```markdown
---
layout: category
title: Your Category
lang: en-US
---

Your custom content goes here.
```

## Technical Details

The page generation happens in the `_plugins/generate_menu_pages.rb` file, which:

1. Reads all menu.yaml files
2. Creates Jekyll `Page` objects for each entry
3. Applies the appropriate layout
4. Sets metadata like title, language, parent categories, etc.
5. Adds default content from templates

## Troubleshooting

If pages aren't generating correctly:

1. Check the YAML structure for syntax errors
2. Ensure paths in the menu.yaml file are consistent
3. Verify that the layouts and templates exist and are properly formatted

## Further Customization

The system can be extended to:
- Add more metadata to pages
- Create additional page types
- Generate index pages for collections of resources
- Add custom taxonomies or tags 
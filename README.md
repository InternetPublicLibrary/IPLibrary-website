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

## Running Locally

Content lives in the `en-US` and `pt-BR` git submodules, so initialize them first:

```bash
git submodule update --init --recursive
```

The site requires Ruby 3.2.2 (see `Gemfile`). With a matching Ruby:

```bash
bundle install
bundle exec jekyll serve      # http://localhost:4000
```

Without Ruby 3.2.2 installed, run the same server in Docker:

```bash
docker run -d --name iplibrary-dev -p 4000:4000 \
  -v "$PWD":/srv/site -v iplibrary-gems:/usr/local/bundle -w /srv/site \
  -e BUNDLE_PATH=/usr/local/bundle ruby:3.2.2 \
  bash -c "bundle install && bundle exec jekyll serve --host 0.0.0.0 --port 4000"
```

Restart the server after editing anything in `_plugins/` or `_config.yml`; Jekyll only picks those up on startup.

## Testing

| Suite | Command | What it checks |
| --- | --- | --- |
| Build (Minitest) | `yarn test:unit` | Builds the whole site into a temp dir and checks page generation, rendered components and that every internal link resolves. |
| End-to-end (Playwright) | `yarn test:e2e` | Drives a real browser (desktop and mobile) against the running server: language redirect, category/section/wiki navigation, language switcher, pt-BR header links, no uncaught script errors. |
| HTML / links | `yarn test:html` | `htmlproofer` over `_site`. |

- Minitest lives in `test/` and runs through `rake test`. With Docker: `docker exec iplibrary-dev bundle exec rake test`.
- Playwright lives in `e2e/`, a separate Yarn project with `nodeLinker: node-modules`, because Playwright does not run under the root Plug'n'Play install. The first time, run `yarn test:e2e:install` to download Chromium. Tests reuse a server already on port 4000; point them elsewhere with `E2E_BASE_URL`.

<p align="center">
  <img src="docs/assets/logo.png" alt="Internet Public Library logo" width="128" height="128">
</p>

<h1 align="center">Internet Public Library</h1>

<p align="center">
  A free, community-curated, Wikipedia-style library of internet resources — in English and Portuguese.<br>
  <a href="https://ipl.better-web.org">ipl.better-web.org</a> ·
  <a href="https://github.com/InternetPublicLibrary">GitHub organization</a> ·
  a project of the <a href="https://better-web.org">Better Web Initiative</a>
</p>

---

This repository is the website: Jekyll layouts, plugins, design system, YAML data and the build that generates
every category, subcategory, section and wiki page. Page content for each language lives in its own repository,
included here as a git submodule.

## What you get

- **A library tree** — 8 categories, 106 subcategories and 42 sections per language, generated from
  `_data/<lang>/menu.yaml`, each with an article page, a community wiki page and a discussion.
- **Curated resources** — sites, tools, databases, courses, publications and events per topic
  (`_data/<lang>/<category>/<subcategory>/<type>.yaml`, see spec 002).
- **Wikipedia-style reading** — main-page portal, article layout with infobox, contents and Article/Talk/Edit tabs,
  random resource, research panel with live external sources (Wikipedia, OpenAlex, arXiv, ORCID, …).
- **Honest contributions** — every "Edit" and "Suggest a resource" opens a reviewed change on GitHub; no accounts.
- **Accessible by default** — WCAG 2.2 AA checked with axe on every reference page, light theme by default and an
  optional dark mode, keyboard support throughout.

## Repositories

| Repository | Role |
| --- | --- |
| **IPLibrary-website** (this) | Site, design system, data and build |
| [en-US](https://github.com/InternetPublicLibrary/en-US) | English pages (submodule `en-US/`) |
| [pt-BR](https://github.com/InternetPublicLibrary/pt-BR) | Portuguese pages (submodule `pt-BR/`) |
| [contribute](https://github.com/InternetPublicLibrary/contribute) | Service: signed-in edits and suggestions as reviewed pull requests (fork of Staticman) |
| [discuss](https://github.com/InternetPublicLibrary/discuss) | Service: comments with GitHub or ORCID sign-in (fork of giscus) |

## Project structure

```
_data/<lang>/          menu.yaml (the library tree), translations.yaml, curated resources
_layouts/              language_index (home), topic (category/subcategory), section, wiki, info, random …
_includes/components/  atoms, molecules, organisms, templates (research panel)
_plugins/              page and wiki generators, search index (flat /api/<lang>/search-index.json)
assets/css/            design tokens, Tailwind palette remap, page styles
docs/specs/            specs (ROADMAP.md lists them) · docs/adr/ decisions
test/  e2e/            Minitest build suite · Playwright end-to-end and accessibility suites
```

Design decisions: [spec 001](docs/specs/001-design-system-v1/spec.md),
[ADR 0002](docs/adr/0002-keep-tailwind-remap-palette.md). Roadmap: [docs/specs/ROADMAP.md](docs/specs/ROADMAP.md).

## Contributing

Suggest resources, fix pages, translate or improve the code — see the
[contribution guide](https://ipl.better-web.org/en-US/contribute/) and the org's
[CONTRIBUTING.md](https://github.com/InternetPublicLibrary/.github/blob/main/CONTRIBUTING.md). Issues and pull
requests use templates with an ELI5 summary and an AI-use disclosure. Code owners review every change.

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
| Accessibility (axe) | `yarn test:e2e` | WCAG 2.2 AA (no serious/critical issues) on every reference page, light and dark. |
| HTML / links | `yarn test:html` | `htmlproofer` over `_site`. |

- Minitest lives in `test/` and runs through `rake test`. With Docker: `docker exec iplibrary-dev bundle exec rake test`.
- Playwright lives in `e2e/`, a separate Yarn project with `nodeLinker: node-modules`, because Playwright does not run under the root Plug'n'Play install. The first time, run `yarn test:e2e:install` to download Chromium. Tests reuse a server already on port 4000; point them elsewhere with `E2E_BASE_URL`.

## Credits

Curated entries link to and credit their publishers in the `organization` field; IPL writes its own names and
descriptions and does not copy their content. Developer roadmaps are linked from [roadmap.sh](https://roadmap.sh),
whose roadmaps remain theirs (their licence allows sharing links, not republishing the content).

## License

Code and content are released under the terms in [LICENSE](LICENSE). The Source Sans 3 and Source Serif 4 fonts in
`assets/fonts/` are under the SIL Open Font License (license files alongside them).

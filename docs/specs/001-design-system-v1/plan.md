# 001 — Design System v1.0 · Plan

Spec: [spec.md](spec.md) · ADR: [0001](../../adr/0001-own-css-tokens.md) · Tasks: [tasks.md](tasks.md)

## Architecture

```
_includes/components/atoms/head.html   ← loads, in order:
  assets/css/tokens.css        custom properties, light + dark + forced-colors
  assets/css/base.css          @layer ipl-base: element defaults (body, a, headings, focus) + font-face
  assets/css/primitives.css    .ipl-button, .ipl-link, .ipl-input, .ipl-badge, .ipl-card, .ipl-stack…
  assets/css/shell.css         .ipl-skip, .ipl-header, .ipl-nav, .ipl-search, .ipl-footer, .ipl-appearance
  assets/css/discovery.css     home, categories, category, subcategory, 404, resource rows
  assets/css/article.css       .ipl-article, .ipl-prose, .ipl-infobox, .ipl-tabs, .ipl-contents
  assets/css/interactions.css  search results, disclosure/tabs, discussion states, research panel
  (Tailwind runtime script — legacy shim, after the v1 links; see ADR 0001)
assets/fonts/                  Source Serif 4 + Source Sans 3 WOFF2 (latin, latin-ext) + OFL.txt
javascript/ipl-theme.js        inline-critical part in <head> (no flash) + appearance control
javascript/ipl-shell.js        menu / language / search disclosures (aria-expanded, Esc, focus return)
javascript/ipl-article.js      contents highlighting, tabs (progressive enhancement only)
```

### Cascade contract (why layers)

Tailwind v4 (runtime shim) emits `@layer theme, base, components, utilities`. Layer order is fixed by first
declaration, and unlayered rules beat every layer.

- `base.css` starts with `@layer ipl-base;` and is linked **before** the Tailwind script, so `ipl-base` is the
  lowest layer: legacy pages keep their Tailwind utility look, v1 element defaults never override them.
- Everything v1 relies on is a **class selector outside any layer** (`.ipl-prose h2`, `.ipl-header a`…), so it
  wins over Tailwind preflight on v1 pages. Never style v1 components with bare element selectors.
- Tokens are custom properties on `:root`; dark mode via `:root[data-theme="dark"]` and
  `@media (prefers-color-scheme: dark) { :root:not([data-theme="light"]) { … } }`.

### Naming and component contracts

- Prefix `ipl-`, BEM-ish modifiers: `.ipl-button--primary`, `.ipl-card__title`.
- Primitives are Liquid includes with a documented parameter list at the top of the file (already the
  convention in `_includes/components/atoms/`). A primitive ignores no parameter silently: unknown → comment.
- Icons: one inline SVG sprite (`_includes/components/atoms/icon.html`, 20 px box, 1.75 px stroke); decorative
  icons `aria-hidden="true"`; icon-only buttons get `aria-label`. Font Awesome stays loaded only for legacy pages.
- Language names are native ("English", "Português"); no flags.

### Content contracts frozen after slice 1

| Contract | Shape | Producer |
| --- | --- | --- |
| Page front matter (generated) | `title, lang, description, parent_category(_path), parent_subcategory(_path), children, data_folder`; `last_updated` **removed** from generated pages | `_plugins/site_page_generator.rb`, `_plugins/wiki_generator.rb` (slice 4) |
| Resource item (YAML) | as today in `_data/<lang>/**.yaml`; v1 reads `title, url, description, type, language, source, access` when present, never invents missing ones | data (unchanged) |
| Search | `GET` to `/en-US/search/?q=` or `/pt-BR/busca/?q=`; those pages (submodules) fetch `/api/<lang>/search-index.json`, which the generator must publish as a Jekyll page — today it is written straight into `_site` and deleted by Jekyll's cleanup, so both indexes 404 | slice 5 (`_plugins/search_index_generator.rb`) |
| GitHub actions | Edit: `https://github.com/InternetPublicLibrary/<lang>/edit/master/<path>` when the page has a source file, else a new-issue URL with `title` and `body` prefilled (page URL) | slice 2 (helper include) |

## Decisions

- Direction "Meridian Archive"; tokens exactly as in `research/codex-audit.md` (all pairs computed).
- Attribution "by Better Web" everywhere (header, footer, `head.html` structured data).
- Own CSS, no build step (ADR 0001).
- Broken flows hidden or redirected to GitHub; backends are separate specs/issues (#2–#7).
- Home "featured article" and "today's resource" widgets: replaced by a deterministic "Explore a topic" list
  from `menu.yaml` (no fake editorial claim).
- External research dashboard: collapsed `<details>` "Research elsewhere" with provenance label, loaded on open.

## Ownership (two agents, no shared file edits)

Claude works in the main checkout on `feat/design-v1`. Codex works in a git worktree
`../IPLibrary-website-codex` on `feat/design-v1-codex`, rebased on `feat/design-v1` at each hand-off; Claude
merges, builds (Docker, Ruby 3.2.2) and runs the suites, because Codex's sandbox cannot run the server.

| Slice | Owner | Exclusive files | Depends on |
| --- | --- | --- | --- |
| S1 Foundations | Claude | `assets/css/tokens.css`, `base.css`, `primitives.css`, `assets/fonts/**`, `_includes/components/atoms/**` (incl. `head.html`), `_includes/head.html`, `javascript/ipl-theme.js` | — |
| S2 Shell | Codex | `_layouts/default.html`, `_includes/header.html`, `_includes/footer.html`, `_includes/components/organisms/{header,footer,sidebar-navigation}.html`, `_includes/lang-switch-url.html`, `_includes/components/molecules/{language-switcher,language-selector,breadcrumb}.html`, new `_includes/github-action-url.html`, `assets/css/shell.css`, `javascript/ipl-shell.js` | S1 |
| S3 Discovery | Claude | `_layouts/{language_index,categories,category,subcategory,resource,resources}.html`, `index.html`, `404.html`, `_includes/resource-grid.html`, `_includes/category-sidebar.html`, molecules `{card,resource-card,category-card,featured-article,keywords-cloud}.html`, organisms `{categories-section,categories-tree-section,hero-section,category-sidebar,resource-grid,featured-resources-section,search-section}.html`, `javascript/ipl-dynamic.js`, `assets/css/discovery.css` | S1 (S2 for final look) |
| S4 Article | Codex | `_layouts/{section,wiki,page}.html`, `_includes/templates/*.md`, `_includes/components/wiki_preview.html`, `_plugins/wiki_generator.rb`, `_plugins/site_page_generator.rb`, `assets/css/article.css`, `javascript/ipl-article.js` | S1, S2 |
| S5 Interactions | Claude | `_plugins/search_index_generator.rb`, `_includes/components/discussion.html`, molecules `{search-form,search-bar,search-panel,result-card,tab-nav,tree-list,wiki-edit-form,wiki-create-form,issue-form,wiki-summary-box,dashboard-sidebar}.html`, `_includes/components/templates/academic-dashboard.html`, organisms `search-*.html`, `_includes/components/htmx/**`, `assets/css/interactions.css` | S1 |
| S6 Integration | Claude (Codex reviews) | `e2e/**`, `test/**`, `docs/specs/001-design-system-v1/**`, `_config.yml`, `package.json` | S2–S5 |

Files outside this table are read-only for both; a needed change is requested from the owner. Submodule pages
(`en-US/**`, `pt-BR/**`) are not edited in this spec.

## Test strategy

- RED first: `e2e/tests/accessibility.spec.mjs` (AC1) fails today; new `e2e/tests/design-v1.spec.mjs` encodes
  AC2–AC9 and is written in S6's first task, before S2–S5 land, so each slice turns parts of it green.
- `test/build_output_test.rb` gains the AC3 "no fabricated content" scan over the built site.
- Every slice ends with `yarn test:unit` + `yarn test:e2e` green except the AC tests owned by later slices.
- Visual review: desktop 1440 / mobile Pixel 7 screenshots of the 9 reference pages, light and dark, compared
  by both agents at the end of S6.

## Risks

- Tailwind preflight vs v1 element styles → mitigated by the cascade contract above; verified by AC4 test.
- Font payload → only 400/600 (+ 400 italic serif), latin + latin-ext subsets, `font-display: swap`.
- Codex cannot run the site → every Codex hand-off is built and tested by Claude before merge.

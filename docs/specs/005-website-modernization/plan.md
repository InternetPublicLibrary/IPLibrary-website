# 005 — Plan

Spec: [spec.md](spec.md). Base branch: `chore/modernize` (stacked on `feat/design-v1`, which is not merged yet).

## Approach
Each phase is a PR, tests green at every step; deletions are listed and approved by the maintainer before running.

| Phase | Changes | Verification |
| --- | --- | --- |
| 1 Safety | Pin `@tailwindcss/browser@4.3.3` and Font Awesome 6.4.0 with SRI (`crossorigin="anonymous"`); remove GA snippets from both head includes; `.github/dependabot.yml`, CodeQL workflow; delete approved dead files; untrack `vendor/bundle` | New build tests for AC1/AC2; full suites |
| 2 Toolchain | Ruby 3.4 (`.ruby-version`, `Gemfile`, Docker/CI); `bundle update` gated by suites; consolidate scripts in `package.json`; port remaining Rake generation into plugins; CI workflow running Minitest + Playwright/axe; remove Rake/Make/`build.sh`/`deploy.yml` | Suites on CI; page-count parity before/after |
| 3 Front-end | Tailwind CLI v4 build step (`@theme` from `tailwind-theme.css`, content globs over templates and submodules) emitting `assets/css/site.css`; remove the runtime script; icon atom replaces Font Awesome per component | Screenshot diff of reference pages; axe |
| 4 Performance | Liquid profiling; move per-page menu/resource loops into plugin-generated data | Build time < 10 s |
| 5 Workers | `wrangler.toml` with `[assets] directory = "_site"`, `not_found_handling = "404-page"`; deploy job with PR previews | Smoke + E2E against the preview URL |

## Risks
- Tailwind compilation must scan submodule pages too, or legacy classes disappear (content globs include `en-US/**`, `pt-BR/**`).
- Removing Rake must not drop pages: parity test counts generated pages per language before/after.

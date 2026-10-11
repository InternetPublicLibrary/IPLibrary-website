# 005 — Tasks

## Phase 1 — Safety and hygiene
- [x] T1 Tests: third-party assets pinned with SRI (AC1); no Google Analytics in built pages (AC2) — RED first.
- [x] T2 Pin Tailwind browser 4.3.3 and Font Awesome 6.4.0 with integrity hashes; remove GA snippets.
- [x] T3 Dependabot (bundler, npm for root and `e2e/`, GitHub Actions) and CodeQL (JavaScript, Ruby).
- [ ] T4 Deletion list (vendor/bundle, debug files, unused JS/images, legacy includes) → maintainer approval → remove.
  - [x] vendor/bundle untracked (approved).
  - [ ] Debug files, legacy root includes, unused Semantic UI JS/images, unused components — awaiting approval.
  - History rewrite declined: the clone keeps the existing pack; AC3's size target applies to the working tree.
## Phase 2 — Toolchain
- [ ] T5 Ruby 3.4; bundle update; suites green.
- [ ] T6 CI workflow (Minitest, Playwright + axe); remove npm-based workflows.
- [ ] T7 Single script set; Rake/Make/build.sh retired with page-count parity test.
## Phase 3 — Front-end
- [ ] T8 Tailwind CLI build; runtime script removed; visual check.
- [ ] T9 Icon atom replaces Font Awesome.
## Phase 4 — Performance
- [ ] T10 Build < 10 s.
## Phase 5 — Workers
- [ ] T11 wrangler.toml, deploy and preview jobs; remove GitHub Pages workflow and `.cloudflare/pages.toml`.

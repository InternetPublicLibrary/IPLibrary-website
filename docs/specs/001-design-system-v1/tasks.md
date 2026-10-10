# 001 — Design System v1.0 · Tasks

Spec: [spec.md](spec.md) · Plan: [plan.md](plan.md). Each task ends with the stated check passing.

## S6a — Acceptance tests first (Claude)
- [ ] T1 `e2e/tests/accessibility.spec.mjs` runs light and dark (AC1). Check: fails on current site (RED).
- [ ] T2 `e2e/tests/design-v1.spec.mjs` for AC2, AC4–AC9. Check: fails on current site (RED).
- [ ] T3 `test/build_output_test.rb`: fabricated-content scan (AC3). Check: fails on current site (RED).

## S1 — Foundations (Claude)
- [ ] T4 `assets/css/tokens.css` (light, dark, forced-colors) with the audited values.
- [ ] T5 Self-host Source Serif 4 + Source Sans 3 (WOFF2, latin + latin-ext, OFL) in `assets/fonts/`.
- [ ] T6 `assets/css/base.css` (`@layer ipl-base`, font-face, focus ring, reduced motion) and
      `primitives.css` (button, link, input, badge, card, stack, visually-hidden).
- [ ] T7 `head.html`: link order per plan, inline no-flash theme snippet, `javascript/ipl-theme.js`.
- [ ] T8 Atoms: `icon.html` SVG sprite, `button.html` contract. Check: `yarn test:unit` green.
- [ ] T9 Hand-off: commit, create Codex worktree, brief S2.

## S2 — Shell (Codex)
- [ ] T10 One header: globe mark, name, "by Better Web", skip link, nav, labeled GET search (all viewports),
      language disclosure (native names), appearance control. Retire `_includes/header.html` duplicate.
- [ ] T11 Footer: concise, real links only, "by Better Web", license link; fix footer category data source.
- [ ] T12 `github-action-url.html` helper (edit / suggest / report) per plan contract.
- [ ] T13 `ipl-shell.js`: disclosures with `aria-expanded`, Esc, focus return. Check (Claude): AC2, AC6 header
      part, AC7, AC9 green.

## S3 — Discovery (Claude, parallel with S2)
- [ ] T14 Home: compact masthead, search, "Explore a topic" from menu, categories list; remove counters,
      featured-article/today's-resource fakes.
- [ ] T15 Categories / category / subcategory: content-first title + lead + children list with full names and
      real counts; keyword cloud removed; research dashboard moved into "Research elsewhere" disclosure.
- [ ] T16 404: concise recovery (search + categories). Check: AC1 for these pages, AC3, AC5.

## S4 — Article (Codex, after S2)
- [ ] T17 `section.html` / `wiki.html`: breadcrumb, single H1, Article/Talk/Edit tabs, lead, contents,
      `.ipl-prose` body ≤ 75 ch, infobox, resource list, honest empty state; local nav after article on mobile.
- [ ] T18 Generators: drop build-time `last_updated`, remove placeholder knowledge from wiki boilerplate.
- [ ] T19 `article.css`, `ipl-article.js`. Check (Claude): AC4, AC5, AC3 for articles.

## S5 — Interactions (Claude, parallel with S4)
- [ ] T20 Publish `/api/<lang>/search-index.json` as Jekyll pages (currently deleted by cleanup → 404); search
      page reads `q` from the URL, shows count/status/empty/error; home/header forms feed it (AC6).
- [ ] T21 Discussion: tabs with roving focus, loading/unavailable/retry, theme sync; contribution routed to
      GitHub; no `form.submit()` bypass.
- [ ] T22 Research-elsewhere providers load on open, with provenance labels and error/retry.

## S6b — Integration (Claude; Codex reviews)
- [ ] T23 Merge, full suites green (AC1–AC11), screenshots light/dark of the 9 reference pages.
- [ ] T24 Codex review pass of the integrated branch; fix findings.
- [ ] T25 Update README design section; open follow-up issues (legacy content migration, Tailwind shim removal).

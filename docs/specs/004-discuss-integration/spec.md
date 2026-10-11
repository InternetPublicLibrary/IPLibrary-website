# 004 — Discuss integration

Status: draft · Contract: `InternetPublicLibrary/discuss` → `docs/specs/004-ipl-widget/spec.md` (embed) and
`002-sign-in`, `003-orcid-comments`. This spec only consumes them.

## Why
Comments today use the public giscus app, GitHub sign-in only. `discuss` adds ORCID sign-in, IPL theme and
languages, hosted by IPL.

## What
1. `_includes/components/discussion.html` loads `discuss` with the embed contract (`data-lang`, `data-theme`,
   `data-providers="github,orcid"`), per language repository.
2. The dark-mode toggle sends `setConfig.theme` to the widget (`ipl-light` / `ipl-dark`).
3. Loading, unavailable (timeout/`discuss:error`) and retry states; the "Talk" tab and article contents link to it.
4. Migration: existing discussions stay in the same repositories/categories (no data move).

## Acceptance criteria
- [ ] A page shows existing comments; GitHub and ORCID sign-in work from the page on staging.
- [ ] Theme follows the site toggle without reload; `pt-BR` pages show Portuguese UI.
- [ ] Unavailable service shows a clear message with a link to the discussion on GitHub.
- [ ] axe clean; E2E with the widget mocked.

## Out of scope
The service itself; comment moderation tools.

# 001 — Design System v1.0 ("Meridian Archive")

Status: approved direction, in implementation · Owner: maintainer (Matheus Breguêz) · Implementers: Claude + Codex
Research: [`research/claude-audit.md`](research/claude-audit.md), [`research/codex-audit.md`](research/codex-audit.md)
Decision records: [ADR 0002 — keep Tailwind, remap the palette](../../adr/0002-keep-tailwind-remap-palette.md) (supersedes [0001](../../adr/0001-own-css-tokens.md))

> **Revision 2026-10-10 (maintainer review).** The first implementation (own CSS, serif headings, rebuilt
> pages) was rejected as too custom, retro and content-losing. Binding direction from now on:
> **evolve the existing Tailwind layout**, keep every section and its content, **high content density**,
> **Wikipedia-style** structure (main page portal boxes; article pages with tabs, infobox, contents),
> **light by default** with an optional dark mode, **Source Sans 3 without serif**. Requirements 1–3 below are
> read through ADR 0002; AC10 is dropped.

## Why

IPL wants to be a Wikipedia-like library of curated internet resources. Today the site looks like a generic
Tailwind template and, worse, undermines its own credibility:

- **Trust:** the home shows invented numbers ("5,000+ contributors"; "Edits Today" is the day of the month),
  placeholder knowledge ("Topic 1/2/3"), and build time presented as "last updated".
- **Accessibility:** 18/18 page×viewport runs fail axe WCAG 2.2 AA (109 contrast failures, 13 undersized
  targets, unnamed buttons); focus, labels and ARIA state are inconsistent.
- **Reading:** article headings and lists render as flat text; no line-length limit; on mobile the local
  navigation comes before the article.
- **Consistency:** 113 color/opacity identities, 13 text sizes, 8 radii, parallel headers/footers/cards; the
  IPL globe logo appears nowhere; header says "by Better Web", footer says "Open Digital Brasil".
- **Broken promises:** wiki "save", resource submission and login forms go nowhere; home search calls a
  non-existent endpoint.

## What (requirements)

1. **Identity.** The IPL globe (`images/favicon.svg`) is the only product mark, with the name "Internet Public
   Library" and the attribution **"by Better Web"** used identically in header, footer and metadata.
   Visual language "Meridian Archive": white reading canvas on pale cool paper, deep-ocean links, serif article
   headings (Source Serif 4), humanist UI/body (Source Sans 3), thin dividers, one restrained meridian motif in
   the masthead.
2. **Tokens.** One set of design tokens (color, type, space, radius, elevation, motion, focus) as CSS custom
   properties, light and dark, with every text pair at ≥ 4.5:1 (≥ 3:1 for large text and UI boundaries).
   Token values: `research/codex-audit.md` § "Color tokens and computed pairs".
3. **Own CSS.** v1 layouts and components are styled by local CSS built on the tokens, without depending on
   the Tailwind runtime (see ADR 0001). Fonts are self-hosted WOFF2 under SIL OFL with Latin-extended
   coverage for Portuguese.
4. **One shell.** A single header/footer: globe mark, skip link, primary navigation, a labeled search form
   that works on every viewport, language switch with native language names (no flags), appearance control
   (System / Light / Dark, persisted, no flash on load).
5. **Article reading surface.** Section and wiki pages read like an encyclopedia article: breadcrumb, one H1,
   Article / Talk / Edit tabs, lead, contents, body with ≤ 75 ch measure and real heading hierarchy, a compact
   topic infobox (parent, sub-topics, languages), resource list with source metadata.
6. **Discovery pages.** Home, categories, category and subcategory pages are content-first: real topic names
   and counts, no fabricated statistics, no decorative hero gradients, no random keyword clouds; external
   research services (Wikipedia/OpenAlex/arXiv/…) are an optional, clearly labeled "Research elsewhere"
   disclosure, never presented as curated IPL resources.
7. **Truthful states.** No placeholder knowledge, no build time shown as an edit date, explicit
   loading / empty / unavailable states with retry for remote widgets (discussion, provider searches).
8. **Honest actions.** Every visible control does what it says:
   - "Edit" and "Suggest a resource" open the GitHub repository (edit / new issue form) with page context;
   - login, sign-up, wiki "save", history, print and filter controls without a backend are hidden;
   - home and header search submit `GET` to the language's search page (`/en-US/search/?q=`,
     `/pt-BR/busca/?q=`), which reads the existing JSON index.
9. **Accessible by default.** WCAG 2.2 AA: contrast, visible 3 px focus, keyboard paths for every menu and
   disclosure with correct ARIA state, labeled inputs, 24 px minimum targets (44 px for primary controls),
   reflow at 320 px without horizontal scroll, `prefers-reduced-motion`, forced-colors fallback, correct
   `lang` per page.
10. **Both languages.** Every changed template renders correctly in en-US and pt-BR with localized labels.

## Acceptance criteria

- [ ] AC1 — `e2e/tests/accessibility.spec.mjs`: zero `serious`/`critical` axe violations on its 9 pages ×
      desktop and mobile, in light and dark appearance.
- [ ] AC2 — Header and footer of every page show the globe mark, "Internet Public Library" and "by Better Web";
      `site.author`/structured data agree. No "IP" tile, no "Open Digital Brasil" credit in the shell.
- [ ] AC3 — HTML rendered by v1 layouts and generators (not submodule content pages) contains none of: "5,000+", "Edits Today", "Topic 1", "Concept 1", "Resource 1",
      `action="#"`, `href="#"` on primary actions; no "Last updated" value equal to the build date.
- [ ] AC4 — Section and wiki pages: exactly one `<h1>`; content `h2` rendered in the serif family; article body
      max width ≤ 75ch; body text 18 px at ≥ 1024 px viewport.
- [ ] AC5 — At 390 × 844, the page H1 is inside the first viewport on section, wiki, category and subcategory
      pages; local navigation follows the article in DOM order.
- [ ] AC6 — Header search is a `<form method="get">` with a labeled `q` field on desktop and mobile; submitting
      "crypto" from the home lands on the search page with results from the JSON index.
- [ ] AC7 — "Edit" and "Suggest a resource" links point to `github.com/InternetPublicLibrary/...` URLs that
      include the page path/title; no login/sign-up links in the shell.
- [ ] AC8 — Appearance control: System/Light/Dark, persisted across reloads, no flash of the wrong theme,
      keyboard operable; discussion widget follows the theme.
- [ ] AC9 — No horizontal scroll at 320 px; skip link is the first focusable element; all menus expose
      `aria-expanded`; animations disabled under `prefers-reduced-motion`.
- [ ] AC10 — v1 layouts load no `@tailwindcss/browser` dependency for their own styling (legacy content pages
      may keep it until migrated — see Out of scope).
- [ ] AC11 — Existing suites stay green: `yarn test:unit` (incl. internal links) and `yarn test:e2e`.

## Out of scope (own specs / issues)

- Wiki editing backend, revision history and persistence (#2, #3).
- Resource submission pipeline and moderation (#4, #5); accounts and profiles (#7).
- Search features beyond wiring existing search to the existing index: filters, fuzzy matching (#11, #12).
- Stable translation IDs for cross-language page mapping (#13). v1 keeps the "same path or language home"
  fallback.
- Migrating static content pages that live in the `en-US`/`pt-BR` submodules (about, help, policies…) off
  Tailwind classes; they inherit the new shell and tokens, their bodies are migrated later.
- Content license reconciliation (GPL vs CC BY-SA vs MIT) — maintainer decision; the footer keeps linking the
  existing license page.

# Design audit — Claude (automated a11y scan + visual review)

Date: 2026-10-10. Branch: `feat/design-v1` (base: `fix/build-links-tests`).
Companion to `codex-audit.md` (independent review by Codex); both feed `../spec.md`.

## 1. Automated accessibility scan (axe-core, WCAG 2.0/2.1/2.2 A+AA tags)

Harness: `e2e/tests/accessibility.spec.mjs` (Playwright + `@axe-core/playwright`), 9 representative
pages × desktop (1280) and mobile (Pixel 7) = 18 runs. Gate: no `serious` or `critical` violations.

**Baseline: 18 / 18 runs fail.**

| Impact | Rule | Nodes | Runs | Cause |
| --- | --- | --- | --- | --- |
| critical | `button-name` | 4 | 4 | Global search icon button with no accessible name (`<button onclick="performGlobalSearch()">`) |
| serious | `color-contrast` | 109 | 18 | see pairs below |
| serious | `target-size` (2.5.8) | 13 | 11 | Icon buttons absolutely positioned inside the search inputs |

Failing contrast pairs (foreground / background → ratio, AA needs 4.5:1 for body text):

| Pair | Ratio | Nodes | Tailwind class |
| --- | --- | --- | --- |
| `#99a1af` / `#ffffff` | 2.6 | 69 | `text-gray-400` used for secondary text |
| `#00a63e` / `#ffffff` | 3.21 | 30 | `text-green-600` links/labels |
| `#ffffff` / `#fb2c36` | 3.8 | 4 | white on `bg-red-500` |
| `#00a63e` / `#f0fdf4` | 3.07 | 2 | green on green-50 tile |
| `#d08700` / `#fefce8` | 2.84 | 2 | yellow-600 on yellow-50 tile |
| `#ffffff` / `#00a63e` | 3.21 | 2 | white on green-600 button |

axe cannot compute contrast over gradients/images (reported as *incomplete*), so text on the hero
gradients needs manual checking (see Codex audit).

## 2. Visual review (screenshots in session scratchpad, 1440px and Pixel 7)

| # | Finding | Heuristic / principle | Severity (0–4) |
| --- | --- | --- | --- |
| 1 | The IPL globe logo appears nowhere; header uses a generic blue "IP" tile, home hero a purple book icon. Footer says "Open Digital Brasil", header subtitle "by Better Web". | Consistency & standards; identity | 3 |
| 2 | Home shows contradictory hard-coded stats: "8+ Resources", "5,000+ Contributors", "10 Edits Today". Reads as fabricated — fatal for an encyclopedia's credibility. | Match with real world; trust | 4 |
| 3 | Raw locale code "en-US" printed under the home title. | Match with real world | 2 |
| 4 | Article content headings (Introduction, Why It's Important…) render as unstyled text; no article typography (measure, rhythm, heading scale). | Aesthetic & minimalist; readability | 3 |
| 5 | Placeholder copy in production: wiki preview "Key Topics: Topic 1, Topic 2, Topic 3"; featured article image is an empty gradient. | Aesthetic & minimalist; trust | 3 |
| 6 | Mobile: sidebar blocks (Other Sections, On This Page, Information, Wiki Tools, Related Pages) render **before** the article; content starts after several screens. Breadcrumb comes after the sidebar and wraps to 3 lines. | Flexibility & efficiency; recognition | 4 |
| 7 | Redundant navigation on section pages: "Jump to" chips + four pastel tiles (Resources/Wiki/Edit Wiki/Discussion) + "On This Page" box all link to the same anchors. | Aesthetic & minimalist | 2 |
| 8 | Stats and tiles use blue/green/purple/orange/yellow with no semantic meaning; pastel tile colors fail contrast. | Consistency; WCAG 1.4.3 | 3 |
| 9 | Discussion widget shows an indefinite "Loading discussions…" with no timeout/fallback when Giscus is unavailable. | Visibility of system status; error recovery | 2 |
| 10 | Two header systems (`_includes/header.html`, `_includes/components/organisms/header.html`); language menu shows "English" twice (top bar + options). | Consistency | 2 |
| 11 | Empty states ("No Resources Yet") dominate section pages because most sections have no data; the call to action is good but the empty state is visually heavier than content. | Aesthetic & minimalist | 2 |
| 12 | Wikipedia affordances are partially present (breadcrumbs, last updated, edit, history, discussion, printable) but scattered across cards; no consistent "article tools" area. | Recognition over recall | 2 |

## 3. Brand inputs

- Logo: blue globe, white lowercase "ipl". Sampled gradient: highlight `#00BDFD` → body `#0088F0`/`#0079E0`.
- New favicon set (`images/favicon.svg`, `/favicon.ico`, `images/apple-touch-icon.png`) already draws the
  globe with geometric "ipl" letterforms — reuse it as the header mark.
- Computed WCAG contrast on white: `#00BDFD` 2.17, `#0088F0` 3.63, `#0079E0` 4.36, `#006BC7` 5.35,
  `#005FB8` 6.31, `#0057A8` 7.17, `#004C94` 8.53, `#003D78` 10.83. So `#0088F0` works for large
  text/UI shapes (≥3:1) but **not** body links; `#006BC7` is the lightest same-hue shade that passes
  4.5:1 on white (5.07 on `#F7F9FB`).

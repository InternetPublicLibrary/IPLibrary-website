# 0002 — Keep Tailwind templates; change identity through the palette

Date: 2026-10-10 · Status: Accepted · Supersedes: [0001](0001-own-css-tokens.md) · Spec: [001](../specs/001-design-system-v1/spec.md)

## Context

ADR 0001 replaced Tailwind with hand-written CSS and rebuilt the pages. The maintainer reviewed the result
and rejected it: too many customizations, a "retro" look, and content lost. The existing Tailwind layout
"is on the right track" and should evolve, with higher content density.

## Decision

Keep the existing templates and their Tailwind classes. Change identity and accessibility underneath:
`assets/css/tailwind-theme.css` redefines Tailwind v4 color variables (globe blue for blue/indigo, globe
highlight for purple/violet, darker text tones for AA) and a dark theme that inverts the scales under
`[data-theme='dark']`. Light is the default; dark only by explicit choice. Font: Source Sans 3 everywhere.
Pages are improved in place (Wikipedia-style structure, real data, more content), not rewritten.
`tokens.css`/`primitives.css` stay for the few non-Tailwind pieces (skip link, brand mark, root page).

## Consequences

- Small diffs per template; existing sections and look are preserved.
- Tailwind runtime remains a dependency (runtime compilation cost stays).
- Any new color must come from the remapped scales; arbitrary hex classes are not allowed in templates.

# 0001 — Own CSS with design tokens instead of the Tailwind runtime

Date: 2026-10-10 · Status: Superseded by [0002](0002-keep-tailwind-remap-palette.md) · Spec: [001 Design System v1.0](../specs/001-design-system-v1/spec.md)

## Context

The site is styled by Tailwind loaded at runtime from a CDN (`@tailwindcss/browser`) plus utility classes
written directly in Jekyll templates. The design audits counted 113 color/opacity identities, 13 text sizes
and 8 radii across templates; the same component exists in several class-soup variants. Runtime compilation
means styling depends on a third-party script executing in every visitor's browser, adds work before first
render, and prevents an enforceable token contract (any template can pick any palette color, which is how the
contrast failures appeared). The `prose` classes used for articles have no effect because the typography
plugin is not loaded.

## Decision

v1 layouts and components are styled by local, hand-written CSS files built on CSS custom properties
(`assets/css/tokens.css`, `base.css`, `primitives.css`, then one file per area: `shell.css`, `discovery.css`,
`article.css`, `interactions.css`), loaded with plain `<link>` tags. Components use semantic class names
(e.g. `.ipl-header`, `.ipl-article`, `.ipl-button--primary`); colors, sizes and spacing come only from tokens.
Fonts are self-hosted WOFF2.

The Tailwind runtime script stays in the `<head>` only as a compatibility shim for legacy content pages
(mostly in the `en-US`/`pt-BR` submodules) until they are migrated; v1 templates must not rely on it. Tailwind
v4 places its rules in cascade layers, so the unlayered v1 CSS takes precedence where both apply.

## Consequences

- One enforceable source of truth for color, type and spacing; contrast is checked once per token pair.
- No runtime CSS compilation for v1 pages; styling works without third-party scripts.
- Templates touched by v1 lose their Tailwind utility classes, so the diff per template is large.
- Two styling systems coexist until content pages are migrated; the shim is removed in a follow-up once no
  page uses Tailwind classes.
- No new build step: plain CSS files are served by Jekyll as static assets.

# 0003 — Deploy the site on Cloudflare Workers (static assets)

Date: 2026-10-11 · Status: Accepted · Spec: [005](../specs/005-website-modernization/spec.md)

## Context

The site is served through Cloudflare, configured outside the repository (`.cloudflare/pages.toml` is not a format
Cloudflare Pages reads), while `.github/workflows/deploy.yml` targets GitHub Pages. The `contribute` and `discuss`
services will run on Cloudflare Workers, and their sign-in sessions should be first-party cookies on the IPL domain.

## Decision

Build the Jekyll site in CI and deploy `_site` as **Workers static assets** with Wrangler (`wrangler.toml` in the
repository), keeping `_headers`, `_redirects` and the 404 page. The site Worker owns `ipl.better-web.org` and later
routes `/contribute/*` and `/discuss/*` to the services through service bindings. Preview deployments per pull request.
The migration happens **after** the modernization (spec 005), which removes the parallel build systems first.

## Consequences

- One platform and toolchain (Wrangler) for site and services; versioned, reviewable deploy configuration.
- First-party sessions for GitHub/ORCID sign-in; no cross-site cookies or wildcard CORS.
- The build moves to GitHub Actions; the GitHub Pages workflow and the Pages configuration are removed.

# 005 — Website modernization

Status: in progress · Tracking issue: [#27](https://github.com/InternetPublicLibrary/IPLibrary-website/issues/27) ·
ADR: [0003](../../adr/0003-deploy-on-cloudflare-workers.md)

## Why
The site builds and runs, but on an end-of-life Ruby, with 87 MB of vendored gems in git, three overlapping build
systems, a CI that does not run what developers run, unpinned third-party scripts and dead code. Moving to
Cloudflare Workers (ADR 0003) is only safe once the build is single, reproducible and tested.

## What
1. **Safety and hygiene:** third-party scripts pinned to exact versions with SRI; the dead Universal Analytics
   snippet removed; `vendor/bundle` and debug/unused files out of git; Dependabot and CodeQL.
2. **One toolchain:** Ruby 3.4+; one set of `package.json` scripts calling Jekyll directly; Rake/Make/`build.sh`
   retired after parity; CI runs `rake test`, Playwright + axe and internal link checks on every PR.
3. **Compiled front-end:** Tailwind compiled at build time from the IPL palette; no runtime CSS compiler; Font
   Awesome replaced by the local icon atom.
4. **Performance:** full build under 10 s; Lighthouse budget on the reference pages.
5. **Deploy:** Workers static assets via Wrangler with PR previews (ADR 0003); GitHub Pages workflow removed.

## Acceptance criteria
- [ ] AC1 — No third-party `<script>`/`<link>` without an exact version and an `integrity` attribute (test).
- [ ] AC2 — No Google Analytics code in built pages (test).
- [ ] AC3 — git tracks no `vendor/bundle`, `node_modules`, `_site` or debug files; clone under 15 MB.
- [ ] AC4 — CI on every PR runs unit, E2E and accessibility suites and blocks merging on failure.
- [ ] AC5 — One documented command each for dev, build, test and deploy; Rakefile/Makefile/`build.sh` removed.
- [ ] AC6 — Built pages load no runtime CSS compiler; styles equal before/after (visual check on reference pages).
- [ ] AC7 — Full build < 10 s on CI hardware.
- [ ] AC8 — Production served by a Worker with static assets; PR previews available.

## Out of scope
Design changes (spec 001), content curation (spec 002), the contribute/discuss integrations (specs 003/004).

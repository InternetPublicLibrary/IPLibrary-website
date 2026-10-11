# 003 — Contribute integration

Status: draft · Contract: `InternetPublicLibrary/contribute` → `docs/specs/003-edits-and-suggestions/spec.md`
(API) and `002-sign-in/spec.md` (session). This spec only consumes them.

## Why
Today "Edit" and "Suggest a resource" open GitHub issues, which requires a GitHub account and leaves the work to
maintainers. With `contribute`, readers signed in with GitHub or ORCID edit and suggest directly, as reviewed PRs.

## What
1. "Sign in" control in the header (GitHub / ORCID) using the `contribute` session; shows the signed-in name.
2. Article "Edit" tab: in-page editor (Markdown, preview) for pages whose source `contribute` can resolve
   (`GET /v1/source`); submit → `POST /v1/edits` → link to the PR. Generated pages keep the GitHub issue fallback.
3. "Suggest a resource" form (topic, type, name, URL, description, access) → `POST /v1/suggestions` → link to the PR.
4. "My contributions" panel (`GET /v1/contributions`).
5. Without a session or if the service is unavailable, the current GitHub-issue fallback stays.

## Acceptance criteria
- [ ] Sign-in round trip with both providers on staging; header reflects the identity.
- [ ] An edit and a suggestion each produce a PR with the author credited; the UI shows the PR link.
- [ ] Conflict (409) shows the current content and lets the user retry.
- [ ] Keyboard and screen-reader accessible (axe clean); both languages.
- [ ] E2E tests with the API mocked (Playwright route interception).

## Out of scope
The service itself; moderation tooling; auto-merge.

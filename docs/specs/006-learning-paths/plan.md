# 006 — Plan

## Data
`_data/<lang>/learning-paths/<slug>.yaml`:
```yaml
title: Frontend development
summary: From HTML and CSS to a component framework and testing.
subcategory: development/frontend-development
level: beginner
source: ipl
stages:
  - title: Foundations
    steps:
      - title: How the web works
        summary: Requests, responses, browsers and URLs.
        resources: [https://developer.mozilla.org/...]
see_also:
  - name: Frontend Developer Roadmap (roadmap.sh)
    url: https://roadmap.sh/frontend
```

## Generation
`_plugins/learning_paths.rb` (a Jekyll Generator) creates one page per path and one index page per language, using
`_layouts/learning-path.html`. It resolves each step URL to its curated entry (name, description, access); an unknown
URL fails the build in development and test.

## Interaction
`assets/js/learning-path.js` (vanilla, no dependencies), loaded only on path pages:
- `<details>` per step, so it works without JS;
- checkboxes stored under `ipl:path:<lang>:<slug>`, with a progress bar that has `aria-valuenow`;
- a polite live region that announces progress.

## Authoring
Paths are drafted by agents from IPL's own data: the subcategory's sections and its curated resources. The prompt
forbids consulting external roadmaps. Claude reviews order, wording and resources, and native-language drafts are
written for pt-BR.

## Tests
- `test/learning_paths_test.rb`: schema, the resource URLs exist, `source: ipl`, both languages present.
- Build test: the pages render and the subcategory page lists its paths.
- e2e: progress persists across reloads; axe passes.

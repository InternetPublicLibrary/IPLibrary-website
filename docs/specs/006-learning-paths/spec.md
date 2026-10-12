# 006 — Interactive learning paths

Status: draft · Depends on: 002 (curated resources)

## Why
Readers ask "where do I start, and what comes next?". IPL already has thousands of curated resources per topic but no
order through them. A learning path turns a topic into ordered steps, each backed by IPL's own resources, and lets
readers mark progress.

## What
1. **Paths as data.** One file per path: `_data/<lang>/learning-paths/<slug>.yaml` with `title`, `summary`,
   `subcategory` (where it is listed), `level` (beginner, intermediate or advanced), `steps`, and optional `see_also`.
2. **Steps.** Each step has a `title`, a short `summary` written for IPL, 2–5 `resources` (URLs that already exist in
   IPL's curated data), and optional `optional: true`. Steps may group into `stages`.
3. **Pages.** `/<lang>/learning-paths/` lists every path. `/<lang>/learning-paths/<slug>/` shows one path:
   - stages and steps in order, expandable;
   - the resources of each step, linking to IPL's entries;
   - a progress checkbox per step and a progress bar, kept in the reader's browser (localStorage, no account);
   - links to related paths and to external roadmaps listed under `see_also`.
4. **Discoverability.** Subcategory pages show their paths above the curated resources. Search indexes path and step
   titles.
5. **Languages.** en-US and pt-BR, with steps written natively in each language.

## Original content and credit
Paths are authored for IPL from IPL's taxonomy and curated resources. They are not copied, translated or adapted
from roadmap.sh or any other roadmap: that content is licensed for personal use only. External roadmaps appear only
as links under `see_also`, credited by name.

## Acceptance criteria
- [ ] At least 12 paths per language at launch, covering the most visited development and computing subcategories.
- [ ] Every step resource URL exists in IPL's curated data (test).
- [ ] Without JavaScript, the path is a readable ordered list. With JavaScript, steps expand and progress persists
      across reloads.
- [ ] Keyboard and screen-reader accessible: checkboxes are labelled and progress is announced. axe reports no
      serious or critical issues.
- [ ] No content copied from external roadmaps. Each path records its authorship in `source: ipl`.

## Out of scope
Accounts, server-side progress, quizzes, certificates, graphical node maps.

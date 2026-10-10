# 002 — Curated resources for every topic

Status: in progress · Owner: maintainer · Curation agent: agy (Antigravity CLI), reviewed by Claude
Related: spec 001 (pages that display these resources), issue #4 (contribution workflow)

## Why

`_data/<lang>/<category>/<subcategory>/*.yaml` holds the resources shown on IPL pages. 1,272 of these files
(106 subcategories × 6 resource types × 2 languages) contain only a generated placeholder
(`Example Resource`, `https://example.com`). Real curated resources: 16 (en-US) and 61 (pt-BR). A library with
placeholder shelves is not credible, and the design cannot show density without real content.

## What

1. Every resource file lists **3–8 real resources** relevant to its subcategory and type:
   `tools`, `databases`, `learn` (courses, tutorials, textbooks), `publications` (journals, papers, books,
   reference works), `blogs-and-sites`, `events-and-conferences`.
2. Each entry: `name`, `url` (https, canonical, reachable), `description` (one or two factual sentences in the
   file's language, no marketing), optional `type`, `language` (BCP 47 of the resource itself), `access`
   (`free` | `freemium` | `paid`), `organization`.
3. Quality: reputable and stable sources (universities, standards bodies, public institutions, established
   publishers, well-known open-source projects, recognized communities); free/open preferred; no affiliate or
   tracking parameters; no link shorteners; no duplicate URL within a file; events must be recurring.
4. pt-BR files prefer resources in Portuguese or with Portuguese versions; if none exist, international
   resources with a description in Portuguese.
5. Every URL is verified by an HTTP request at curation time (2xx after redirects); unverifiable → not added.
6. A file may keep fewer than 3 entries only when the type genuinely does not apply; then it holds `[]`
   and a YAML comment explaining why — never a placeholder.

## Acceptance criteria

- [ ] `test/resources_data_test.rb` passes: all files parse, no `example.com`, required fields, https URLs,
      no duplicate URL per file, descriptions non-empty.
- [ ] `scripts/check_resource_links.rb` reports no unreachable URL (run with network).
- [ ] Spot review by Claude of ≥ 10% of files per category for relevance and factual descriptions.

## Out of scope

Editorial review workflow and user submissions (#4, #5); per-resource ratings; translating resources.

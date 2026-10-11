# IPLibrary-website — Roadmap

| Spec | Domain | Status | Depends on |
| --- | --- | --- | --- |
| [001 Design system v1.0](001-design-system-v1/spec.md) | site design | in progress | — |
| 002 Curated resources — `docs/specs/002-curated-resources/spec.md` on branch `content/curated-resources` | content data | in progress | — |
| [003 Contribute integration](003-contribute-integration/spec.md) | edits and suggestions UI | draft | `contribute` specs 002, 003 |
| [004 Discuss integration](004-discuss-integration/spec.md) | comments embed | draft | `discuss` specs 002–004 |
| [005 Website modernization](005-website-modernization/spec.md) | build, CI, assets, deploy on Workers | in progress | — (precedes the Workers deploy) |

Services (separate repositories, own specs): `InternetPublicLibrary/contribute` (hard fork of Staticman) and
`InternetPublicLibrary/discuss` (hard fork of giscus). Their API/embed contracts are defined in their repositories;
the specs here only consume them.

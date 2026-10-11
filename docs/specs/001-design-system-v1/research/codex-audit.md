# IPL Design v1.0 — independent design audit

Audit date: 2026-10-10. Author: Codex. Phase: research only.

## Scope, evidence and limits

Read `AGENTS.md`, `CLAUDE.md` and `docs/AGENTS.md`; their implementation and compliance claims are not evidence. Reviewed the current working-tree templates, includes, localized HTML, relevant generators, inline scripts and `javascript/ipl-dynamic.js`. Existing uncommitted changes belong to the ongoing Claude/maintainer work. Line references below refer to the source as inspected, not to a clean release. No site files were edited, no build was run, no submission was sent and no commits were made.

Visual evidence is the eight supplied page captures: `home-desktop.png`, `category-desktop.png`, `subcategory-desktop.png`, `section-desktop.png`, `wiki-desktop.png`, `notfound-desktop.png`, `home-mobile.png`, `subcategory-mobile.png`. These are referenced by filename; their source directory is the supplied scratchpad `design/`. Desktop captures were supplied as 1440 CSS px and mobile as Pixel 7. I have not equated raster screenshot pixels with CSS pixels. The screenshots can predate concurrent edits: for example, current footer source includes an X icon absent from the supplied footer capture.

Read `images/favicon.svg:1–23` and visually inspected `images/favicon.png`. The new mark correctly restores the globe silhouette and lowercase lettering, with gradient stops `#00BDFD`, `#0096F2`, `#0079E0`. It simplifies the photographic globe reference; the visible shell still substitutes an unrelated square “IP” badge.

Local HTTP reads returned `Operation not permitted`; the browser tool also refused access under the session's approval policy. Existing `_site/` HTML was inspected without regenerating it. Consequently, keyboard, computed CSS, 320 px overflow, zoom, target rectangles and actual provider availability are **not live-tested**. This is an independent source/visual audit, not a WCAG conformance certification or a replacement for Claude's axe report. Findings distinguish confirmed markup/logic defects, calculated reference-color models and runtime risks.

Reference frameworks: [Nielsen's ten heuristics](https://www.nngroup.com/articles/ten-usability-heuristics/) and [WCAG 2.2](https://www.w3.org/TR/WCAG22/). Severity: 0 = no usability problem; 1 = cosmetic; 2 = minor; 3 = major; 4 = catastrophic. No finding here warrants calling the entire site unusable, so no severity 4 is assigned.

## Executive summary

- **Trust is undermined by invented activity.** “5,000+ contributors” is literal text; “Edits Today” is the day of the month; “Resources” counts menu-derived items rather than curated resources. Remove these until their definitions and data are verifiable (`_layouts/language_index.html:31–52`).
- **Core contribution actions cannot fulfil their promises.** The active wiki form has neither a submission endpoint nor save/cancel handlers; dedicated resource submission and login forms post to `#`. Route to a working reviewed contribution mechanism or remove the unsupported affordance (`_layouts/wiki.html:139–163`; `en-US/submit-resource.html:26`; `en-US/login.html:19`).
- **Home search has a mismatched contract.** It requests `/api/search`, supplies no input `name`, and swaps a response into HTML, while the checked-in API is static JSON at `api/search.json`. Dedicated search uses a different language-specific index (`_layouts/language_index.html:66–75`; `en-US/search.html:140–148`).
- **Article formatting is effectively missing in the supplied captures.** Headings, bullets and paragraphs collapse into uniform text despite `prose` classes. No typography stylesheet/plugin is supplied by the active head. Restore explicit article CSS before adding decoration (`_includes/components/atoms/head.html:120–132`; `section-desktop.png`; `wiki-desktop.png`).
- **Accessibility problems are concrete, not just aesthetic.** Search fields lack labels; mobile menu expansion never updates ARIA state; its outline is removed; submission via `form.submit()` bypasses native validation; multiple wiki H1s occur in generated HTML.
- **Pale text and semantic colors need replacement.** A reference model gives breadcrumb blue on the bright gradient endpoint 3.69:1, gray metadata on white 2.60:1, and yellow helper text on pale yellow 2.84:1. Actual runtime colors still need sampling; white text on both dark gradient endpoints passes the reference model.
- **Readers pay a large navigation/decorative tax.** Mobile captures show headers and heroes dominating the initial screen; category/subcategory pages stack eight external research services below thin boilerplate. Put real resource titles and a short introduction first; make external research optional.
- **The component library is not a consistent contract.** There are parallel headers, heads, footers, resource grids and cards; some callers pass props the receiving atom ignores. The broad source inventory contains 113 color/opacity identities, 13 size utilities and eight radius utilities.
- **Keep the useful structure.** Category → subcategory → section, sibling navigation, breadcrumbs, wiki/talk concepts and resource metadata are the right foundation. Their links, semantics, labels and content provenance need tightening.
- **Recommend “Meridian Archive.”** Use the actual globe, deep ocean links, pale paper surfaces, Source Serif 4 article headings and Source Sans 3 UI; reserve a faint meridian motif for the masthead. Establish tokens and component contracts before parallel page work.

## Nielsen heuristics

| Heuristic | Finding | Evidence | Severity | Fix |
|---|---|---|---:|---|
| 1. Visibility of system status | Persistent discussion loaders have no application-level timeout/error/retry; commit-fetch errors can become “No recent changes,” conflating failure and an empty feed. | `_includes/components/discussion.html:78–90,308–329`; `javascript/ipl-dynamic.js:127–166`; `wiki-desktop.png`; `subcategory-desktop.png` | 3 | Distinguish loading, ready, empty and unavailable; announce changes; offer retry and a direct discussion link. Never fabricate an empty activity state after failed fetches. |
| 2. Match between system and real world | “Resources” means menu-derived structure, “Edits Today” means calendar day, and “Wiki” on category pages means an external Wikipedia extract whereas section “Wiki” means IPL community content. | `_layouts/language_index.html:34–51`; `_layouts/category.html:87–89,114–115`; `_includes/components/wiki_preview.html:8,44–55`; `_layouts/section.html:177–201` | 3 | Name real quantities precisely, remove unsupported totals, distinguish “Wikipedia overview” from “IPL community article.” Use familiar resource types and verified metadata. |
| 3. User control and freedom | Opening the wiki editor repopulates it from rendered HTML and can discard an unsaved draft on reopening. Cancel has no handler. Most section fragment links are intercepted even when no target exists. | `_layouts/wiki.html:158–161,217–234`; `_layouts/section.html:261–273` | 3 | Edit original Markdown, retain draft state, implement cancel/return focus and protect unsaved work. Keep native fragment/history behavior. Do not expose publishing until there is a real destination. |
| 4. Consistency and standards | The brand is a square “IP,” the favicon a globe “ipl.” Parallel card/button APIs disagree; language controls range from accordion to flags to home redirects. | `images/favicon.svg:5–21`; `_includes/components/organisms/header.html:68`; `_includes/header.html:1–80`; `_includes/components/molecules/resource-card.html:147–155`; `_includes/components/atoms/button.html:1–5` | 3 | One shell and one documented primitive API; apply the globe consistently; use native language names, one switching policy and localized labels. |
| 5. Error prevention | Contribution anchor calls `form.submit()`, bypassing constraint validation and its own submit listener. The dedicated suggestion form lacks a real action. Wiki claims a save action without persistence. | `_includes/components/discussion.html:126–163,198–201,294–304`; `en-US/submit-resource.html:26,97–100`; `_layouts/wiki.html:143–163` | 3 | Native submit button or `requestSubmit()`, persistent field errors, a review/receipt step and accurate submission outcome. Use one confirmed contribution channel. |
| 6. Recognition rather than recall | Long child names are clamped to one line; generic Explore labels and identical resource descriptions obscure topic differences. Section/mobile DOM places extensive sibling/TOC tools before its title. | `_layouts/category.html:150–160`; `_layouts/subcategory.html:134–146`; `_layouts/language_index.html:175–177`; `_layouts/section.html:13–110`; `category-desktop.png` | 2 | Link the complete topic title, retain useful summaries and show full labels on touch and keyboard. Put title/lead before collapsible local tools on small screens. |
| 7. Flexibility and efficiency of use | Desktop search submits to the search page, mobile search has no equivalent handler/form, and home uses an unrelated HTMX endpoint. Wiki edit fragments do not auto-open the hidden editor on load. | `_includes/components/organisms/header.html:82–90,145–152,230–245`; `_layouts/language_index.html:66–70`; `_layouts/wiki.html:140,217–238` | 3 | A shared GET search contract on every viewport; deep-linkable article/edit/talk states; query preserved in history; optional discoverable shortcut outside text entry. |
| 8. Aesthetic and minimalist design | Oversized gradient heroes, colored statistic counters, repeated icons, many nested elevated cards, keyword clouds and an eight-provider dashboard overwhelm sparse curated content. | `_layouts/language_index.html:5–54,112–127`; `_layouts/category.html:8–14,266–284`; `_includes/components/templates/academic-dashboard.html:55–164`; mobile and category captures | 2 | Compact masthead/lead, flat article canvas, resource lists and optional research disclosure. Remove unsourced keyword clouds and decorative cards; retain meaningful status color only. |
| 9. Help users recognize, diagnose and recover from errors | Filter, History, Printable Version and “Today's Resource” appear actionable but have placeholder/missing destinations. Empty section CTA points to nonexistent `#contribute`. | `_layouts/section.html:158–171`; `_layouts/wiki.html:43–54,116–118`; `_layouts/language_index.html:203–205`; `404.html:24–58` | 3 | Audit every destination, provide real suggestions/report links with context, and hide unsupported tools. Keep 404 search/category recovery but reduce its decorative height. |
| 10. Help and documentation | Real contribution requirements differ between dedicated forms and discussion forms; article-source/citation guidance is absent from the active editor, while boilerplate asks readers to add an overview. | `en-US/submit-resource.html:90–94`; `_includes/components/discussion.html:102–107,249–253`; `_layouts/wiki.html:145–161`; `_plugins/wiki_generator.rb:137–161` | 2 | Short guidance near the action: accepted resources, required metadata, review process, GitHub requirements, citation and licensing rules. Link fuller contributor help consistently. |

## WCAG 2.2 AA findings

“Confirmed” below means the defect is visible in source/generated markup; a criterion failure that depends on rendering or assistive technology remains a risk until tested. Not all design shortcomings are WCAG failures. A missing arrow-key handler alone does not prove 2.1.1 failure when buttons remain operable with Tab/Enter.

| Criterion | Finding and confidence | Evidence | Fix / verification |
|---|---|---|---|
| 1.1.1 Non-text Content; 4.1.2 Name, Role, Value | **Confirmed naming omission:** mobile and academic icon-only search buttons lack accessible names. Decorative icons/SVGs are inconsistently hidden. Existing ORCID images have `alt="ORCID"`; no blanket missing-alt claim is warranted. | `_includes/components/organisms/header.html:149–150`; `_includes/components/templates/academic-dashboard.html:35–38,117`; `_includes/components/atoms/icon.html:1–2` | Name each control in the page language. Hide adjacent decorative icons with `aria-hidden="true"`; informative illustrations need meaningful alternatives. A linked logo needs one “IPL home” name without duplicated adjacent text. |
| 1.3.1 Info and Relationships; 2.4.6 Headings and Labels | **Confirmed article hierarchy defect:** layout H1 plus generated Markdown H1. 404 title is a styled `div`; home description is an H2 rather than a paragraph. Sidebar headings before the article are a navigation-order concern, not automatically a failure. | `_layouts/wiki.html:125–128`; `_plugins/wiki_generator.rb:133`; `_site/en-US/academics/computer-science-theory/cryptography-theory/wiki/index.html` has two H1s; `404.html:18–20`; `_layouts/language_index.html:27–29` | One page H1, actual H2/H3 sections, explicit paragraph/list styles; assign lower levels to local tools. Make 404 title an H1. Check heading outline in both locales. |
| 1.3.1; 2.4.1 Bypass Blocks | **Confirmed omission, partial support:** default has a `main`, header and footer, but no skip link; desktop main navigation is built from `div`s. Major breadcrumbs/TOCs use anonymous containers despite an existing semantic breadcrumb molecule. | `_layouts/default.html:22–32`; `_includes/components/organisms/header.html:104–140`; `_layouts/wiki.html:24–29,88–100`; `_layouts/section.html:60–65,98–106`; `_includes/components/molecules/breadcrumb.html:10–30` | Skip link to an identified main; labeled primary/local/breadcrumb nav; current-page semantics; an article landmark and labeled aside. Existing main is useful but does not excuse inefficient keyboard traversal. |
| 1.4.3 Contrast (Minimum) | **Calculated reference-model failures:** pale breadcrumb text near bright gradient end, gray-400 metadata and green/yellow small helper text. White on dark gradient stops passes the same model. | See contrast table below; `_layouts/category.html:18,38,57`; `_layouts/subcategory.html:18,52`; `_includes/components/organisms/footer.html:76,158`; `_layouts/section.html:132,147` | Replace pairs with tested semantic tokens. Sample actual computed colors and the lightest backdrop behind text, including overlays. Do not assume all gradient text fails. |
| 1.4.1 Use of Color | **Risk:** current category/navigation selection relies on color/background or font weight without `aria-current`; inline article links may rely solely on blue. Badge labels and tab ARIA selection are positive. | `_includes/components/organisms/header.html:109–124`; `_layouts/section.html:42`; `_includes/components/discussion.html:52,57,62`; `_includes/components/atoms/badge.html:40–41` | Persistent underline for prose links, current-page text/ARIA and a selection indicator independent of hue. Keep text labels for statuses. |
| 1.4.11 Non-text Contrast; 2.4.7 Focus Visible | **Confirmed source risk:** mobile toggle removes outline without replacement. Input rings vary between opaque blue and 20% blue; pale borders alone cannot establish control boundaries reliably. Generic native focus may remain on other elements, so do not claim all focus is invisible. | `_includes/components/organisms/header.html:96`; `_layouts/language_index.html:68`; `_includes/components/discussion.html:127–172`; `_layouts/wiki.html:147,153` | Global `:focus-visible` outline with solid, contrast-tested token and offset; darker input borders. Verify keyboard and forced-colors modes; use the [focus-visible guidance](https://www.w3.org/WAI/WCAG22/Understanding/focus-visible.html). |
| 2.4.11 Focus Not Obscured (Minimum); 2.4.3 Focus Order | **Runtime risk:** sticky header `top-0`, sidebar `top-4` or `top-24`, and hard-coded 80 px scrolling can hide target/focus positions. Scroll into editor does not transfer focus. | `_includes/components/organisms/header.html:7`; `_layouts/wiki.html:9,233`; `_layouts/section.html:14,269–271`; `_layouts/category.html:298` | Derive sticky offsets from shell height, use `scroll-margin-block-start`, move focus deliberately on revealed forms and return it on close. Verify at zoom and when language/menu panels expand. |
| 2.1.1 Keyboard; 4.1.2 Name, Role, Value | **Confirmed state defect:** mobile toggle declares `aria-expanded="false"` but only toggles the CSS class. Language disclosure updates ARIA and native buttons support Enter/Space, but lacks Escape handling. | `_includes/components/organisms/header.html:95,199–204,213–227` | Synchronize expansion, localized accessible name and panel visibility. Disclosure links can stay native links; Escape closes and returns focus. Avoid imposing menu roles on simple navigation lists. |
| 2.5.3 Label in Name | **Confirmed mismatch:** language button visibly says “English” or “Português,” but `aria-label="Select language"` replaces that text in its accessible name. Speech users cannot reliably invoke the visible label. | `_includes/components/organisms/header.html:15–21` | Use a localized name that includes the visible language, e.g. “Language: English”; preserve the visible words in the accessible name. |
| 4.1.2; 2.4.3; 2.1.1 | **Confirmed incomplete tab pattern:** discussion tabs have roles/selected state but no tablist label, roving tabindex or arrow/Home/End handling. They are all native buttons, so Tab/Enter is possible. Panel navigation/state needs screen-reader testing. | `_includes/components/discussion.html:49–70,265–287`; `_includes/components/molecules/tab-nav.html:2–7` | Use a complete accessible tab contract or ordinary navigation links. Scope listeners to each instance; make active panel reachable and retain consistent focus. Article/Talk/Edit/History can be genuine page links instead of simulated tabs. |
| 2.4.4 Link Purpose (In Context); 2.4.6 | **Confirmed misleading links:** “Edit Wiki” overview tile opens the wiki article, unlike bottom edit link. History has no target; license and Filter link to `#`. Repeated Explore labels have surrounding context, so are not automatically failures, but standalone link lists are poor. | `_layouts/section.html:135–140,158,210`; `_layouts/wiki.html:43,53,116,135`; `_layouts/language_index.html:175–177,205` | Match labels to real destinations. Link descriptive topic/resource titles; use “Explore [category]” accessible text if a generic CTA remains. Use the actual license URL once the maintainer selects its version. |
| 2.5.8 Target Size (Minimum) | **Unmeasured risk:** top-bar actions have `text-xs` with no per-control vertical padding; footer social links are icon-sized; tree expanders use `w-4`. These are likely undersized but may meet spacing/equivalent/inline exceptions. | `_includes/components/organisms/header.html:11–15,28–35`; `_includes/components/organisms/footer.html:19–36`; `_includes/components/molecules/tree-list.html:8`; mobile captures | Measure bounding rectangles at 320/390 px, including the spacing-circle exception. Prefer 44 px main touch controls and at least 24 px discrete compact controls. Do not inflate prose inline links. Follow [W3C's precise exceptions](https://www.w3.org/WAI/WCAG22/Understanding/target-size-minimum.html). |
| 1.4.10 Reflow; 1.4.4 Resize Text; 1.4.12 Text Spacing | **Unmeasured risk:** section/wiki breadcrumb flex rows do not wrap; long topic labels and discussion tab padding can overflow narrow widths; mobile search/button overlays can overlap text. Cards clip names/descriptions. Existing single-column breakpoints are positive. | `_layouts/wiki.html:88–100`; `_layouts/section.html:98–105`; `_includes/components/discussion.html:49–62`; `en-US/search.html:19–25`; `_layouts/category.html:151,155` | Allow wrapping/min-width:0, keep article first, stack wide controls and avoid essential text clipping. Test 320 px, 200% text size, 400% browser zoom at a suitable desktop viewport and text-spacing overrides. The supplied Pixel capture does not establish 320 px compliance. |
| 2.2.2 Pause, Stop, Hide | **Likely failure pending runtime duration check:** 404 pulses continuously; indefinite pulse/ping loaders coexist with content. Header brand animation ends quickly, so duration alone does not establish this failure. | `404.html:15`; `_includes/components/discussion.html:82–84`; `_layouts/language_index.html:131,218`; `_includes/components/organisms/header.html:256–279` | Remove decorative pulsing; use static status text for long waits. For qualifying long animation, provide pause/stop/hide or eliminate it. Do not assume every essential loading indicator fails; see [W3C guidance](https://www.w3.org/WAI/WCAG22/Understanding/pause-stop-hide.html). |
| Motion preference — additional design requirement | **Confirmed omission:** universal transitions and smooth scrolling do not check reduced-motion preference. Respecting `prefers-reduced-motion` is required by this design proposal; 2.3.3 is AAA, so its absence alone is not an AA failure. | `_includes/components/atoms/head.html:193–196`; `_layouts/section.html:271`; `_layouts/wiki.html:233`; `index.html:89` | Remove timed brand morph; limit transitions to controls, suppress nonessential animation and use instant scrolling when reduced motion is requested. |
| 3.1.1 Language of Page; 3.1.2 Language of Parts | **Partial pass plus confirmed locale omissions:** generated English/Portuguese home HTML correctly has `lang="en-US"` / `lang="pt-BR"`. Default fallback contains a leading space before `en`. Wiki/section tools, long helper text and some provider errors remain English on pt-BR pages without language markup. | `_layouts/default.html:2`; `_site/pt-BR/index.html`; `_layouts/wiki.html:16,22,34,134–154`; `_layouts/section.html:59–74,124–147`; `_includes/components/organisms/search-openalex.html:24,59` | Clean fallback; translate UI through the locale data; use `lang`/`hreflang` for actual language alternatives and `lang` for untranslated excerpts. Proper names alone do not require marking as another language. Verify all generated pt-BR routes, not only home. |
| 3.3.2 Labels or Instructions; 4.1.2 | **Confirmed omitted field names:** header/mobile/home/academic and 404 inputs use placeholders without a label/ARIA name. Some buttons are labeled; that does not label the input. Wiki and contribution fields do have associated labels. | `_includes/components/organisms/header.html:83–85,147–148`; `_layouts/language_index.html:66–70`; `_includes/components/templates/academic-dashboard.html:31–34`; `404.html:31–36`; `en-US/search.html:19` | Visible label where useful, otherwise persistent visually hidden label; `type="search"`, `name="q"`, native form. Explicit required/optional instructions. |
| 3.3.1 Error Identification; 3.3.3 Error Suggestion | **Confirmed validation-path flaw, backend unverified:** `form.submit()` skips native required/type validation and submit listeners. There is no designed per-field/server-error receipt in that path. Dedicated forms with native required fields are better but lack working actions. | `_includes/components/discussion.html:198,294–304`; `en-US/submit-resource.html:26–101` | Native validated submission; preserve user entries, bind inline errors with `aria-describedby`/`aria-invalid`, focus error summary and give actionable correction/retry. Ensure success represents a reviewed submission receipt, not publication. |
| 1.3.5 Identify Input Purpose; 3.3.8 Accessible Authentication | **Confirmed missing autocomplete metadata; authentication availability unverified:** name/email/password fields lack explicit purpose tokens. Login posts to `#`, so no successful authentication path was assessed. | `_includes/components/discussion.html:126,135`; `en-US/login.html:19–28`; `en-US/signup.html` | Add appropriate autocomplete tokens. Remove unsupported account UI or link to the real service. If authentication remains, test password-manager/paste support and the complete process; CAPTCHA accessibility cannot be assessed from its conditional embed alone. |
| 4.1.3 Status Messages | **Confirmed omission:** result counts, loading/error inserts and recent activity replacements have no live-status region; Giscus loader is left in its container. | `en-US/search.html:35,135–178`; `_layouts/language_index.html:75`; `javascript/ipl-dynamic.js:160–166`; `_includes/components/discussion.html:78–90,329` | A scoped polite status region for counts/loading, assertive errors only when appropriate, `aria-busy` on results; no focus jump for ordinary search completion. Remove/update loaders upon iframe readiness or a timeout. |

### Contrast calculations: current reference pairs

Calculated using sRGB relative luminance and `(Llighter + 0.05)/(Ldarker + 0.05)`, rounded to two decimals. For current utilities, fetched the [upstream Tailwind v4 theme](https://raw.githubusercontent.com/tailwindlabs/tailwindcss/main/packages/tailwindcss/theme.css), converted its OKLCH stops to sRGB with channel clipping and quantized to eight-bit hex. These are **reference-model calculations, not sampled runtime measurements**: the CDN is unpinned within major version 4, browser gamut mapping and gradient interpolation may differ. Exact proposed hex-token calculations later are independent of Tailwind.

| Foreground / background, as calculated | Ratio | Application and conclusion |
|---|---:|---|
| blue-200 `#BEDBFF` / blue-600 `#155DFC` | 3.69:1 | Category/subcategory 14 px breadcrumbs and tiny counters: fails normal-text reference threshold. |
| blue-200 `#BEDBFF` / indigo-700 `#432DD7` | 5.69:1 | Same gradient's dark endpoint passes; evaluate the whole actual backdrop. |
| blue-100 `#DBEAFE` / blue-600 `#155DFC` | 4.30:1 | Category 20 px regular description is below the normal-text threshold; it is not large text merely because it has `text-xl`. |
| blue-100 `#DBEAFE` / indigo-700 `#432DD7` | 6.63:1 | Dark endpoint passes. The white pattern/translucent surfaces lighten parts of the gradient further. |
| white `#FFFFFF` / blue-600 `#155DFC` | 5.25:1 | White text passes at this endpoint. |
| white `#FFFFFF` / indigo-700 `#432DD7` | 8.09:1 | White text passes at this endpoint. |
| gray-400 `#99A1AF` / white `#FFFFFF` | 2.60:1 | Header “by Better Web,” footer small copyright/ownership text, ORCID metadata: fails reference normal-text contrast. |
| green-600 `#00A63E` / green-50 `#F0FDF4` | 3.08:1 | Section “Community knowledge” at 14 px: fails reference normal-text contrast. |
| yellow-600 `#D08700` / yellow-50 `#FEFCE8` | 2.84:1 | Section “Join the conversation” at 14 px: fails reference normal-text contrast. |
| white `#FFFFFF` / brand `#00BDFD`, `#0088F0`, `#0079E0` | 2.17:1 / 3.63:1 / 4.36:1 | Logo lettering has the logotype exception; these hues must not become ordinary white-text button backgrounds. |

The [contrast criterion](https://www.w3.org/WAI/WCAG22/Understanding/contrast-minimum.html) distinguishes normal text from sufficiently large/bold text. For implementation, keep ordinary text pairs above 4.5:1, with additional margin where possible; do not make the minimum a visual target. No screenshot pixel sampling or live contrast measurement is claimed here.

## Visual consistency inventory

### Method and scope

Two lexical inventories were calculated with Python regular expressions after stripping HTML comments and Liquid `{% comment %}` blocks. Counts merge responsive/hover/focus modifiers into the underlying literal token. They include utility literals in class attributes, inline JS HTML/class strings and Liquid alternatives; they are **source occurrences, not DOM element counts, unique rendered styles or proof that every alternative is reachable**. Dynamic values are separately flagged. External Tailwind/Font Awesome internals and `_site/` are excluded.

- **Core scope:** `_layouts/*.html`, `_includes/**/*.html`, `404.html`, `javascript/ipl-dynamic.js`: 81 files; 107 color/opacity identities; 13 size utilities; seven suffixed radius utilities; five named shadows; 105 nonnegative spacing utilities across 18 values including `auto`.
- **Broad scope used in the tables:** core plus root `index.html` and all `en-US/**/*.html`, `pt-BR/**/*.html`: **513 files**, including **431 localized HTML files** already present (both authored and generated). **113 color/opacity identities, 102 base color identities, 3,539 color utility occurrences; 13 sizes; eight radius utilities; five shadows; 109 nonnegative spacing utilities, 18 underlying values including `auto`**. Generated pages can repeat structures and are not independent design decisions.
- Searched `javascript/`; many files are legacy UI/demo code. `default.html:35` only loads `ipl-dynamic.js` globally. Page/include inline scripts remain a major styling and behavior source. No `assets/` directory or repository Tailwind configuration/CSS source was found by the file search. `docs-css.html` references legacy `/stylesheets/docs.css` and `/stylesheets/rtl.css`; their mere references do not establish that they are used by the active shell.

### Every matched color/opacity identity

Notation: `shade:count`, with opacity retained, e.g. `500/20:8`. Counts aggregate `bg`, `text`, `border`, gradient stops, ring, fill and stroke. Transparent is included even though it is not a physical color. These symbolic values resolve through the referenced Tailwind theme; do not silently substitute v3 hex values.

| Family | Distinct identities | Occurrences | All shade/opacity values with counts |
|---|---:|---:|---|
| Blue | 14 | 911 | 50:82; 100:66; 200:23; 300:9; 400:2; 400/20:2; 500:166; 500/10:2; 500/20:8; 600:432; 600/5:2; 700:61; 800:48; 900:8 |
| Cyan | 7 | 19 | 50:2; 100:4; 200:3; 600:6; 700:2; 800:1; 900:1 |
| Emerald | 3 | 9 | 50:1; 100:1; 600:7 |
| Gray | 10 | 1,273 | 50:97; 100:79; 200:148; 300:101; 400:40; 500:134; 600:230; 700:177; 800:108; 900:159 |
| Green | 11 | 164 | 50:8; 100:24; 200:8; 300:1; 400:1; 400/20:1; 500:39; 600:65; 700:9; 800:7; 900:1 |
| Indigo | 8 | 60 | 50:17; 100:7; 200:1; 400:3; 600:11; 700:12; 800:3; 900:6 |
| Orange | 7 | 32 | 50:1; 100:9; 200:1; 600:17; 700:2; 800:1; 900:1 |
| Pink | 6 | 42 | 50:10; 100:3; 200:1; 300:1; 500:18; 600:9 |
| Purple | 11 | 85 | 50:2; 100:20; 200:2; 300:1; 400/20:1; 500/10:2; 600:50; 600/5:2; 700:1; 800:3; 900:1 |
| Red | 8 | 45 | 50:3; 100:5; 200:3; 500:14; 600:11; 700:3; 800:4; 900:2 |
| Slate | 10 | 348 | 50:21; 100:6; 200:48; 300:29; 400:4; 500:21; 600:84; 700:38; 800:5; 900:92 |
| Teal | 4 | 20 | 100:4; 500:2; 600:12; 700:2 |
| Yellow | 7 | 39 | 50:6; 100:5; 200:6; 500:3; 600:13; 700:3; 800:3 |
| White | 6 | 479 | solid:430; /10:17; /20:28; /60:2; /80:1; /90:1 |
| Transparent | 1 | 13 | 13 |

| Other literal colors | Source/count | Conflict / treatment |
|---|---|---|
| `#2563eb` | Broad scope: 4; theme-color in head and root redirect styling | v3-style literal alongside runtime v4 `blue-600`; unify theme-color with chosen brand/UI token. |
| `#f1f1f1`, `#c1c1c1`, `#a8a8a8` | 1 each; `_includes/components/atoms/head.html:179–189` | Separate scrollbar gray family; prefer system scrollbar or semantic neutral tokens. |
| `#fff` | 1; `404.html:10` mask | Mask stop, not text; document it as an effect, not an extra semantic color. |
| `#f8f9fa`, `#4b5563`, `#1d4ed8` | 1 each; `index.html:40,62,81` | Root redirect page has its own palette and system font. |
| `rgba(0,0,0,0.1)` | `index.html:55,84` | Shadow/spinner opacity; additional literal effect value. |
| `rgba(255,255,255,0.6)`, `rgba(255,255,255,0.1)`, `rgba(255,255,255,0.5)` | `404.html:10` | Masks, not UI colors. `bg-grid-slate-*` has no matching authored CSS found in scope. |
| `#00BDFD`, `#0096F2`, `#0079E0`, `#fff` | Outside utility scope; `images/favicon.svg:6–13` | Preserve as logo-only stops/lettering. User's photographic brand reference also supplies `#0088F0`. |

There are 46 `bg-gradient-to-r` and 37 `bg-gradient-to-br` source occurrences in the broad scope. Representative competing pairs: blue-600 → indigo-700 (category/subcategory); blue-600 → purple-600 (home book tile); slate-50 → blue-50 (discussion/404); green-600 → emerald-600 (suggestion page); purple-600 → pink-600 (random resource). Gradient-clipped headings add slate-900 → blue-900 → purple-900. These roles have no common meaning.

### Typography

Sizes below are default utility values assuming a 16 px root; they are specifications inferred from utility names, not measured pixels in the captures. Font loading may alter actual metrics.

| Utility | Default size | Broad occurrences | Use/problem |
|---|---:|---:|---|
| `text-[10px]` | 10 px | 2 | Language check icon; do not apply to important labels. |
| `text-xs` | 12 px | 129 | Metadata, badges, top bar; many insufficient-contrast pairs. |
| `text-sm` | 14 px | 421 | Dominant UI size. |
| `text-base` | 16 px | 14 | Explicit body size is rare; article bodies often inherit/reset. |
| `text-lg` | 18 px | 75 | Resource titles and inputs. |
| `text-xl` | 20 px | 144 | Lead, titles and icons; overloaded role. |
| `text-2xl` | 24 px | 153 | Sections, stats, service icons. |
| `text-3xl` | 30 px | 57 | Article/page title and discussion heading compete. |
| `text-4xl` | 36 px | 35 | Hero heading and empty-state icon. |
| `text-5xl` | 48 px | 9 | Desktop category heading. |
| `text-6xl` | 60 px | 3 | Home heading/empty-search icon. |
| `text-8xl` | 96 px | 1 | 404 numeral. |
| `text-9xl` | 128 px | 1 | 404 numeral at larger breakpoint. |

| Family/weight/rhythm | Count/evidence | Conflict |
|---|---|---|
| Inter, sans-serif | Two head definitions/imports: atomic head `:128–132`, legacy head `:14–16` | Google-hosted; 300–700 fetched, most UI uses 400–700. No separate article family. |
| Root system stack | `index.html:39` | Same product, different loading/fallback appearance. |
| `font-serif`, `font-mono` | 1 / 4 | Serif only on Wikipedia-preview title (`wiki_preview.html:20`); mono relies on generic stack rather than promised JetBrains Mono. |
| `font-medium`, `font-semibold`, `font-bold` | 243 / 182 / 290 | No agreed hierarchy; headings, stats, navigation compete. Normal 400 mostly implicit. |
| `leading-relaxed` | 45 | Select paragraphs, not a systematic article rhythm. Root page additionally declares `line-height:1.5`. |
| `tracking-tight`, `tracking-wide`, `tracking-wider` | 2 / 1 / 8 | Tight heroes versus small uppercase sidebar labels. |
| `prose`, `prose-lg`, `max-w-none` | Article usages at section `:112`, wiki `:127`, category `:121`; `max-w-none`: 23 broad occurrences | No authored prose rules found; head does not load typography plugin. Captures show heading/list normalization. Define actual article CSS and a readable measure. |

### Radius, elevation and spacing

| Radius utility | Broad count | Default radius / conflict |
|---|---:|---|
| `rounded` | 117 | Generic default utility; source literals also include parameter values. Resolve explicitly when migrating. |
| `rounded-md` | 43 | 6 px, mostly forms/badges. |
| `rounded-lg` | 285 | 8 px, section/wiki/card/shell. |
| `rounded-xl` | 182 | 12 px, category and provider cards. |
| `rounded-2xl` | 46 | 16 px, home feature and overview/sidebar cards. |
| `rounded-3xl` | 3 | 24 px, dashboard wrapper and card branch. |
| `rounded-full` | 106 | Pills, loaders and circles. |
| `rounded-t-lg` | 4 | Only top corners of wiki tabs. |
| Literal `4px`, `8px`, `50%`, `10px` | Root redirect `:54,76,85`; head scrollbars `:180,185` | Additional CSS radius declarations. |

| Elevation | Broad count | Role conflict |
|---|---:|---|
| `shadow-sm` | 167 | Shell, compact card, provider, overview all share elevation. |
| `shadow-md` | 66 | Article panels and hover state both use this. |
| `shadow-lg` | 54 | Main actions, ordinary inputs/wrappers and elevated card branch. |
| `shadow-xl` | 10 | Hover actions/cards. |
| `shadow-2xl` | 2 | Atom's elevated variant hover; excessive for reference content. |
| `0 2px 10px rgba(0,0,0,.1)` | `index.html:55` | Sixth explicit shadow expression outside utilities. |

The 109 nonnegative spacing utilities combine 17 numeric steps plus `auto`. Counts below aggregate all padding, margin, gap and space-x/y axes; one source token can be responsive/state-specific. The default scale is 0.25 rem per unit. `-mb-px` occurs twice separately. Root redirect additionally uses literal 20/30 px padding, 10/20/30 px margins; the atomic head sets container side padding to 1/1.5/2 rem in media queries. Those CSS declarations are additional sources, not utility counts.

| Step | Default distance | Broad occurrences |
|---|---:|---:|
| 0 | 0 | 6 |
| 0.5 | 2 px | 26 |
| 1 | 4 px | 242 |
| 1.5 | 6 px | 14 |
| 2 | 8 px | 577 |
| 2.5 | 10 px | 17 |
| 3 | 12 px | 406 |
| 4 | 16 px | 786 |
| 5 | 20 px | 28 |
| 6 | 24 px | 341 |
| 8 | 32 px | 308 |
| 10 | 40 px | 13 |
| 11 | 44 px | 2 |
| 12 | 48 px | 107 |
| 16 | 64 px | 6 |
| 24 | 96 px | 1 |
| 32 | 128 px | 1 |
| auto | Automatic margin | 182 |

Common card padding ranges from `p-4` through `p-8`; hero vertical padding runs from `py-8` to `py-32`. The atom maps padding “sm” to p-4, default/md to p-6, lg to p-8, and an undocumented xl to p-10 (`atoms/card.html:42–51`). Its radius “sm” maps to rounded-lg, “md” to rounded-xl, “lg” to rounded-2xl, and “2xl” to rounded-3xl (`:54–65`): size names cannot be interpreted consistently across components.

Broad max-width tokens: `none:23`, `2xl:30`, `3xl:8`, `4xl:34`, `7xl:3`, `md:12`, `xl:2`. The atomic head also caps `.container` at 1280 px (`:156–160`). Home uses max-w-7xl while other layouts use `.container`; article bodies then remove their own measure limit. Narrow article text explicitly rather than relying on the shell width.

Motion literals: `duration-150:3`, `duration-200:118`, `duration-300:14`, `duration-500:2`; plus global 150 ms transition, root 0.2 s hover/1 s spinner, header JS timing and discussion 0.5 s animation delay. Animations: `animate-spin:8`, `animate-pulse:15`, `animate-ping:4`. No reduced-motion rule was found in reviewed source.

### Component variants and contract conflicts

| Component family | Implementations/variants actually present | Evidence / consequence |
|---|---|---|
| Shell | 2 headers, 2 heads, 2 footers; default uses atomic head and organism shell, legacy data layout uses older include path | `_layouts/default.html:6,24,32`; `_includes/header.html`; `_includes/head.html`; `_includes/footer.html`; `_layouts/data.html:5–8,23`. Duplicate presence is confirmed; legacy header reachability is not established for the supplied pages. Do not redesign both as independent systems. |
| Cards | 4 atom branches: default/elevated/glass/gradient; separate molecule card; category and home cards inline; section/wiki shadow-md panels; provider result cards reconstructed in JS | `_includes/components/atoms/card.html:23–32`; `molecules/card.html:18`; `_layouts/language_index.html:112,152`; `_layouts/category.html:144`; `_layouts/section.html:109`; `search-openalex.html:38–52`. At least eight implementation families, not eight exhaustive CSS combinations. |
| Resource cards/grids | Atom-backed molecule has 3 variants: default/featured/compact; separate legacy resource grid uses gray/indigo cards; organism grid calls molecule with obsolete individual props | `molecules/resource-card.html:27–41`; `_includes/resource-grid.html:3–14`; `organisms/resource-grid.html:13`. The current molecule expects `include.resource`; caller passes title/url/etc. Normalize data contract before styling. |
| Buttons | Atom implements **one** blue solid button only; callers request `content`, `href`, `url`, `variant`, size and icon props it ignores. Inline solid blue/green/indigo/red, outline, white inverse, ghost, pill, icon, gradient and anchor-submit families coexist | `atoms/button.html:1–5`; `molecules/resource-card.html:147–155`; `organisms/resource-grid.html:22`; `_layouts/section.html:170,207,211`; `discussion.html:198–201,243–246`; `404.html:48,54`. Result can be an empty button that does not navigate. |
| Badges | 6 explicit colors plus fallback; 2 effective sizes; caller also requests outline, xs and `content` instead of `text` | `atoms/badge.html:16–41`; `molecules/resource-card.html:69–72,99–102`. Unsupported props silently fall back and text can be empty. |
| Inputs/search | At least 6 paths: header, mobile, home HTMX, dedicated search, academic search, molecule search; rounded/md/lg/xl/2xl; focus widths 2/4 and opacity variations | `header.html:83,147`; `language_index.html:66`; `en-US/search.html:19`; `academic-dashboard.html:31`; `molecules/search-form.html:7`. `atoms/search-input.html:6` defaults to `rounded-l`, which rounds only the left corners rather than applying the intended all-corner scale. |
| Language controls | Header accordion + emoji flags; footer text; 2 molecules use flags and home redirects; new helper preserves only mirrored slugs | `organisms/header.html:44–56`; `molecules/language-switcher.html:7–26`; `molecules/language-selector.html:7–26`; `_includes/lang-switch-url.html:7–14`. Same topic can be lost across different localized slugs. |
| Icons | Font Awesome solid/brands, hand-authored inline SVG, emoji flags and provider raster/SVG images | Head `:124`; `atoms/icon.html:1`; header `:49,55`; academic `:117`. Pick one UI family; logos stay provider marks. `fa-x-twitter` in footer `:25` should be checked against the loaded FA 6.4.0 set before keeping it. |
| Tabs/TOCs | Wiki fragment links, discussion ARIA tabs, generic onclick tab molecule; TOCs inline versus JS-generated; breadcrumb molecule unused by the main section/wiki breadcrumb markup | `_layouts/wiki.html:103–119,178–213`; `discussion.html:49–70`; `molecules/tab-nav.html:2–7`; `molecules/breadcrumb.html:10–30`. Visually similar controls have different behavior and semantics. |

Dynamic classes such as `rounded-{{ rounded }}`, `grid-cols-{{ include.columns }}`, `bg-{{ include.color }}` cannot be fully enumerated from literal-token counts. Inspect call sites/rendered output and define explicit allowed variant maps. A future compiled Tailwind build must include/safelist those finite classes; raw interpolation is not a dependable production style contract.

### Reproducing the main counts

This read-only snippet prints the broad inventory; it does not write files. It intentionally counts lexical utility literals, including dormant alternatives.

```python
from pathlib import Path
from collections import Counter
import re

paths = (list(Path('_layouts').glob('*.html'))
         + list(Path('_includes').rglob('*.html'))
         + [Path('404.html'), Path('index.html'), Path('javascript/ipl-dynamic.js')]
         + list(Path('en-US').rglob('*.html'))
         + list(Path('pt-BR').rglob('*.html')))
source = '\n'.join(p.read_text() for p in paths)
source = re.sub(r'{%\s*comment\s*%}.*?{%\s*endcomment\s*%}|<!--.*?-->',
                '', source, flags=re.S)
patterns = {
    'color': r'(?<![\w-])(?:bg|text|border|from|via|to|ring|fill|stroke)-'
             r'((?:slate|gray|blue|indigo|purple|green|emerald|cyan|yellow|orange|red|pink|teal)'
             r'-\d+|white|black|transparent|current)(/\d+)?(?![\w-])',
    'size': r'(?<![\w-])text-(?:xs|sm|base|lg|xl|[2-9]xl|\[\d+px\])(?![\w-])',
    'radius': r'(?<![\w-])rounded(?:-(?:sm|md|lg|xl|2xl|3xl|full|t-lg))?(?![\w-])',
    'shadow': r'(?<![\w-])shadow-(?:sm|md|lg|xl|2xl)(?![\w-])',
    'spacing': r'(?<![\w-])(?:p[xytrbl]?|m[xytrbl]?|gap(?:-[xy])?|space-[xy])-'
               r'(?:\d+(?:\.\d+)?|auto)(?![\w/.-])',
}
print('files', len(paths))
for category, pattern in patterns.items():
    counts = Counter(re.findall(pattern, source))
    print(category, len(counts), dict(sorted(counts.items())))
```

## Information architecture and Wikipedia-likeness

### Preserve the hierarchy, reduce the distance to content

Category → subcategory → section is understandable and already echoed in menus, breadcrumbs and related sections. Keep stable paths. Add a prominent complete topic title, concise scope note, direct children and real resource counts. Titles should link directly; a tiny Explore footer should not be the only route. Category truncation hides the distinction between “Computer Science Theory” and other branches (`category.html:151`), while generic repeated descriptions add little information.

On mobile, place title and lead before collapsible contents/sibling navigation. Section/wiki currently put the whole sidebar first in DOM order (`section.html:13–96`; `wiki.html:8–86`). Use one visible local “Contents” disclosure with real anchors, not multiple navigation cards. Keep global search available outside the mobile menu: readers should not need to discover a hamburger before looking for a topic.

### Rebuild the reading surface

The section/wiki captures show long lines, repeated rounded/shadowed panels and flat text inside `prose`. An article needs an uninterrupted reading column, visible hierarchy, paragraph spacing, lists, source links, readable code/tables and sensible image captions. Target a **proposed** 65–75 ch measure, 18 px body/1.65 line height on larger screens and 16–18 px on narrow screens. These are design targets, not measured current character counts. Article H1 should use a serif; body may stay humanist sans for screen legibility and multilingual consistency.

Current `max-w-none` and a roughly three-quarter-width desktop main column provide no textual measure limit (`section.html:96,112`; `wiki.html:86,127`). Cap article text independently from the shell; allow tables/media to scroll locally when truly necessary. Do not rely on absent `prose` styling. Provider search results should remain compact lists, not adopt the article heading scale.

### Make encyclopedic content credible

- Remove `Concept 1/2/3`, `Resource 1/2/3`, `Topic 1/2/3` and “Add an overview …” from reader-facing articles (`_plugins/wiki_generator.rb:137–157`; `_layouts/section.html:196–200`). An honest empty article state should offer a real contribution link without presenting placeholders as knowledge.
- Generated `last_updated` is build time (`_plugins/wiki_generator.rb:114`; `_plugins/site_page_generator.rb:171,194,221,250`), not editorial revision time. Display a meaningful content revision when known; otherwise omit the “last edited” claim. Do not label today's featured rotation date as an article revision (`javascript/ipl-dynamic.js:113–115`).
- “Featured Article” is a day-indexed topic link with a generic description, not a selected authored article (`javascript/ipl-dynamic.js:18–50,90–120`). Feature an actual resource/section with an editorial reason and true destination; or call it “Explore a topic.”
- Add compact infobox-like topic metadata: parent category, scope, resource types/languages available, content/source revision and contribution route. No promotional score or artificial popularity.
- Resource records should show title, canonical source/publisher, author when available, type, language, date, access/cost, concise editorial description and last link verification when genuinely recorded. The legacy grid has `source` but truncates descriptions at 120 characters; the newer card supports verification dates/quality score but has caller/API mismatches (`_includes/resource-grid.html:6–14`; `molecules/resource-card.html:113–139`). A bare five-point score without rubric should be cut.
- Keep curated resources distinct from third-party live discovery. The eight-provider dashboard is search output, not vetted IPL inventory. Scholar, ORCID people, Meetup events and generic course/video searches are different information types (`academic-dashboard.html:57–164`). Label provenance explicitly and show an optional “Research elsewhere” panel, preferably on demand. In the supplied category capture this dominates almost the entire page below the navigation grid.
- Wikipedia extract is not the IPL wiki. Current category “Wiki” jump reveals a remote Wikipedia summary only if an API match exists (`wiki_preview.html:1,61–83`). Call it “Wikipedia overview,” disclose source/link/license as appropriate and render its navigation entry only when there is content. Avoid two Wikipedia summary requests/boxes for the same topic (preview plus dashboard summary).

### Article, talk, edit and history must be genuine destinations

Retain the familiar reading/talk/edit separation. Implement article and discussion as dependable paths or native anchored sections; expose edit/history only when backed by the actual workflow. “Edit Wiki” tile currently goes to the article, while a later CTA appends `#edit-wiki` (`section.html:135,210`). Wiki only opens the editor after a click; arriving with that hash does not reveal it. History/print links have no implementation, and current editor input is rendered HTML rather than source Markdown (`wiki.html:43–54,116–118,229–230`). This is a workflow issue that visual polish cannot solve.

Choose a documented GitHub edit/proposal route for v1 if there is no persistence service. State that it creates a proposed change for review, preserve page context and return path, and provide a genuine receipt. A new editing backend, authentication system or revision-store architecture belongs in its own feature specification, outside this design-system implementation.

### Search, localization and navigation integrity

Home has a visible search affordance but its HTMX contract does not match the checked-in JSON API; the field lacks `name`, and `/api/search` is not the same static output path as `/api/search.json`. JSON swapping alone is not a result UI. Dedicated search already fetches a locale index and has useful error/category fallback (`en-US/search.html:134–179`); make all entry points use that contract, with query URL/history, a proper form and clearly labeled results. Do not advertise autocomplete without implementing its keyboard/result behavior. Preserve native navigation where possible.

Current language helper checks the same suffix under another locale and falls back home (`lang-switch-url.html:7–14`). This avoids a dead URL but loses a topic when localized slugs differ. Use a stable topic/translation ID map, show when the translation is unavailable and give a choice to stay/read the existing language. Native language names should replace national flags; flags encode a country rather than a language. Existing generated pt-BR home `lang` is correct, but article/tool English is still pervasive.

Footer category iteration uses `site.data.en.menu.en` instead of the same locale menu shape used elsewhere (`organisms/footer.html:45`; `language_index.html:147–150`), explaining the empty category column in the supplied capture. Fix the data contract or reduce the footer to useful links. Branding/ownership names also conflict: header says Better Web (`header.html:74–76`), footer says Open Digital Brasil (`footer.html:145–155`), structured metadata names Better Web (`head.html:72–75`). Resolve with the maintainer rather than inventing an institutional relationship.

### Cut or defer

Cut fabricated counters, topic placeholders, timed brand shrink, gradient book tiles, hover-only action labels, unsupported Filter/Favorite/History/Print controls and random-size keyword clouds (`keywords-cloud.html:44–55`, with derived boilerplate words at `:13–31`). Defer full account surfaces until authentication exists. Keep purposeful empty states, real citations/source links, current contribution channels and restrained community links. The 404 recovery choices are useful; the animated numeral and tall decorative hero are not needed to help someone recover.

## Proposed design direction

### Recommendation and two alternatives

**Recommended — Meridian Archive.** A calm reference library: actual blue globe in a compact masthead, deep ocean links, white reading canvas on pale cool paper, serif article titles, humanist UI and thin dividers. A single subtle latitude/meridian line motif can connect the visual identity to worldwide knowledge. It should resemble a credible public collection through its reading behavior, not through copied Wikipedia branding.

**Alternative 1 — Open Atlas.** Cooler, more diagrammatic: ocean/teal pairs, Source Sans 3 headings and UI, fine geographic rules and compact topic indexes. Strong for discovery and educational tools; less book-like in long-form reading. Keep the same accessible deep-blue interaction tokens.

**Alternative 2 — Community Reading Room.** Warmer neutral paper, Source Serif 4 section titles and more visible editorial annotations/source notes. Friendly for community curation, but needs care to avoid a literary magazine feel and excessive ornament. Keep the globe and ocean links rather than adding a second brand palette.

Recommend Meridian Archive because it reconciles the actual logo with trustworthy article reading and leaves room for both resource directories and community knowledge. Dark mode is a token mapping of the same design, not a second visual language.

### Color tokens and computed pairs

All ratios in this table are computed from the exact listed hex pairs, not estimates. `on-primary` is white in light mode and dark ink in dark mode. Soft surfaces are optional grouping aids, never mandatory colored cards. Decorative dividers have no required text role; input boundaries use the stronger token. Do not place normal text in the bright logo hues.

| Token / role | Light value | Allowed light pair and ratio | Dark value | Allowed dark pair and ratio |
|---|---|---|---|---|
| `--color-page` | `#F7F9FA` | text `#202B33`: 13.67:1 | `#151C22` | text `#E6EDF2`: 14.54:1 |
| `--color-surface` | `#FFFFFF` | text `#202B33`: 14.44:1 | `#1E2932` | text `#E6EDF2`: 12.52:1 |
| `--color-text` | `#202B33` | white surface: 14.44:1 | `#E6EDF2` | dark page: 14.54:1 |
| `--color-muted` | `#52616B` | white / page: 6.40 / 6.06:1 | `#AEBCC6` | dark surface / page: 7.62 / 8.85:1 |
| `--color-primary` / link / focus | `#0064A8` | white / soft-blue: 6.20 / 5.60:1 | `#7CCBFF` | dark surface / page: 8.35 / 9.70:1 |
| `--color-primary-hover` | `#004B80` | white: 9.06:1 | `#A6DCFF` | dark page: 11.71:1 |
| `--color-on-primary` | `#FFFFFF` | on primary `#0064A8`: 6.20:1 | `#151C22` | on primary `#7CCBFF`: 9.70:1 |
| `--color-primary-soft` | `#EAF5FC` | primary: 5.60:1 | `#1E2932` | primary: 8.35:1 |
| `--color-secondary` | `#005F68` | secondary-soft `#EAF7F5`: 6.74:1 | `#97C7CC` | dark surface: 8.01:1 |
| `--color-secondary-soft` | `#EAF7F5` | secondary: 6.74:1 | `#1E2932` | secondary: 8.01:1 |
| `--color-visited` | `#674C83` | white: 7.15:1 | `#C6A5E9` | dark surface: 7.02:1 |
| `--color-success` | `#177448` | success-soft `#EAF6EE`: 5.21:1 | `#69CD99` | dark surface: 7.61:1 |
| `--color-success-soft` | `#EAF6EE` | success: 5.21:1 | `#1E2932` | success: 7.61:1 |
| `--color-warning` | `#805500` | warning-soft `#FFF5DA`: 6.01:1 | `#F1CC78` | dark surface: 9.62:1 |
| `--color-warning-soft` | `#FFF5DA` | warning: 6.01:1 | `#1E2932` | warning: 9.62:1 |
| `--color-danger` | `#B3261E` | danger-soft `#FFF0EE`: 5.90:1 | `#FFAAA4` | dark surface: 8.13:1 |
| `--color-danger-soft` | `#FFF0EE` | danger: 5.90:1 | `#1E2932` | danger: 8.13:1 |
| `--color-control-border` | `#7B8B96` | white / page: 3.51 / 3.33:1, boundary use only | `#7B8B96` | dark surface: 4.21:1, boundary use only |
| `--color-divider` | `#CCD7DF` | Decorative separation; do not use as sole input boundary | `#3D4D59` | Decorative separation; do not use as text |
| Logo-only highlight/mid/base | `#00BDFD` / `#0096F2` / `#0079E0` | Actual SVG stops; exempt logo, not a UI text pair | Same | Preserve logo; use a quiet surface around it |

### Proposed CSS custom properties

This is a design contract for the subsequent spec/implementation, not code installed by this audit. Use semantic component selectors consuming these values; document allowed pairs. Normal article links are underlined; primary buttons have solid fill, secondary buttons a neutral surface/border, tertiary actions are links. The primary token doubles as focus color only on backgrounds where its tested contrast holds.

```css
:root {
  color-scheme: light;
  --color-page: #F7F9FA;
  --color-surface: #FFFFFF;
  --color-text: #202B33;
  --color-muted: #52616B;
  --color-primary: #0064A8;
  --color-primary-hover: #004B80;
  --color-on-primary: #FFFFFF;
  --color-primary-soft: #EAF5FC;
  --color-secondary: #005F68;
  --color-secondary-soft: #EAF7F5;
  --color-visited: #674C83;
  --color-success: #177448;
  --color-success-soft: #EAF6EE;
  --color-warning: #805500;
  --color-warning-soft: #FFF5DA;
  --color-danger: #B3261E;
  --color-danger-soft: #FFF0EE;
  --color-control-border: #7B8B96;
  --color-divider: #CCD7DF;
  --brand-globe-highlight: #00BDFD;
  --brand-globe-mid: #0096F2;
  --brand-globe-base: #0079E0;
  --font-ui: 'Source Sans 3', system-ui, sans-serif;
  --font-heading: 'Source Serif 4', Georgia, serif;
  --font-code: ui-monospace, SFMono-Regular, Consolas, monospace;
  --space-1: .25rem;
  --space-2: .5rem;
  --space-3: .75rem;
  --space-4: 1rem;
  --space-6: 1.5rem;
  --space-8: 2rem;
  --space-12: 3rem;
  --radius-control: .25rem;
  --radius-panel: .5rem;
  --radius-pill: 999px;
  --shadow-overlay: 0 4px 16px rgb(0 40 64 / 12%);
  --measure-article: 70ch;
  --measure-shell: 80rem;
  --focus-width: 3px;
  --focus-offset: 2px;
  --duration-control: 120ms;
}

/* Explicit choice wins over the system default; JS persists the choice. */
:root[data-theme='dark'] {
  color-scheme: dark;
  --color-page: #151C22;
  --color-surface: #1E2932;
  --color-text: #E6EDF2;
  --color-muted: #AEBCC6;
  --color-primary: #7CCBFF;
  --color-primary-hover: #A6DCFF;
  --color-on-primary: #151C22;
  --color-primary-soft: #1E2932;
  --color-secondary: #97C7CC;
  --color-secondary-soft: #1E2932;
  --color-visited: #C6A5E9;
  --color-success: #69CD99;
  --color-success-soft: #1E2932;
  --color-warning: #F1CC78;
  --color-warning-soft: #1E2932;
  --color-danger: #FFAAA4;
  --color-danger-soft: #1E2932;
  --color-divider: #3D4D59;
  --shadow-overlay: 0 4px 16px rgb(0 0 0 / 32%);
}
```

Default follows system light/dark preference when no explicit setting exists; offer System/Light/Dark in a labeled appearance control. Resolve preference before first paint, preserve keyboard/native form styling and synchronize third-party discussion theme (`discussion.html:75` currently fixes light). The excerpt above intentionally shows only tokens and explicit override; the implementation needs a system-preference resolver, focus rules, component CSS, forced-colors fallback and reduced-motion rules. Avoid filters that invert resource/provider images.

### Type, spacing, elevation and icon rules

Use **Source Serif 4** for article/page headings and **Source Sans 3**, a humanist sans, for UI and body. Adobe provides both families under SIL OFL 1.1: [Source Serif repository](https://github.com/adobe-fonts/source-serif), [license](https://raw.githubusercontent.com/adobe-fonts/source-serif/release/LICENSE.md); [Source Sans repository](https://github.com/adobe-fonts/source-sans), [license](https://raw.githubusercontent.com/adobe-fonts/source-sans/release/LICENSE.md). Self-host WOFF2 with license files, Latin/Latin-extended coverage for Portuguese, only needed weights and `font-display:swap`; verify accent metrics, fallback wrapping and font payload. System mono is sufficient for v1 code excerpts.

| Role | Proposed size / line height | Family / weight | Rule |
|---|---|---|---|
| Article/page H1 | 32 px mobile, 40 px desktop / 1.15 | Serif 600 | Wrap complete titles; no gradient clipping. |
| Article H2 | 26 px / 1.25 | Serif 600 | Separate real article sections with whitespace/thin rule. |
| Article H3 | 21 px / 1.35 | Sans 600 | No oversized provider-card headings. |
| Article body | 18 px / 1.65; narrow minimum 16 px | Sans 400 | 70 ch maximum, no fixed height; 1 em paragraph separation. |
| Lead | 18–20 px / 1.55 | Sans 400 | Short summary, not a second heading. |
| UI/control | 16 px / 1.5 | Sans 400/600 | 44 px primary touch height; complete labels. |
| Compact UI / metadata | 14 px / 1.5 | Sans 400 | Muted tested token; no important 10/12 px text. |
| Code | 14–16 px / 1.5 | System mono 400 | Horizontal scroll within code block only when necessary. |

Spacing scale: 4, 8, 12, 16, 24, 32, 48 px. Use 8 px icon/text gap, 12–16 px list-row separation, 16–24 px panel padding and 32 px major-section spacing. Mobile shell gutters 16 px, desktop 24–32 px; tune breakpoints to available content width, not device names. The 44 px touch height is a control target, not a new general spacing step.

Radii: 4 px controls, 8 px optional panels, full only for true status chips/avatar circles/globe. Reading canvas and resource rows can have no radius. Elevation: no shadow for ordinary article/list cards; one subtle overlay shadow for menus/dialogs. Use borders/whitespace for grouping. Motion: 120 ms color/border transition on actionable controls, no blanket `*` transitions, no card translation/glow, no autonomous animation. Reduced motion disables nonessential transitions and smooth scrolling.

Iconography: one local SVG UI set with consistent 20 px box and approximately 1.75 px stroke; 16 px compact variant. Keep the actual globe SVG as the product mark and provider marks only when identifying a source. Use text labels for essential navigation, hide decorative icons and provide names for icon-only buttons. Do not mix national flags, emoji, solid Font Awesome and outline SVG for the same role. A restrained meridian arc may sit behind the masthead at low visual weight, `aria-hidden`, without text over it; no full-page waves or repetitive globes in cards.

### v1.0 component priorities

| Priority | Components / contract | Acceptance emphasis |
|---|---|---|
| P0 | Tokens, font loading, article typography, focus/motion rules | All normal-text pairs tested, readable heading/list output, no absent prose dependency, both themes. |
| P0 | One shell: globe brand, skip link, primary nav, language/appearance disclosures, responsive search | Complete keyboard path, stable layout, no timed shrinking, consistent locale and real destinations. |
| P0 | Search form, result list, count/status, empty/error fallback | One GET/query/index contract; named field; mobile parity; actual result titles. |
| P0 | Resource row/card, metadata, citation/source link, empty state | One data schema; working URL; provenance; descriptive purpose; truthful dates. |
| P0 | Article layout, breadcrumb, contents, article/talk/edit tools | Single H1, readable measure, valid anchors, source-backed edit/history states. |
| P0 | Contribution form or GitHub proposal link, labeled controls, errors/receipt | No dead submission; native validation; preserve entered content and page context. |
| P1 | Category index/children list, topic summary/infobox, related topics | Full names, actual counts, no boilerplate clouds, content first. |
| P1 | Discussion disclosure/tab pattern, loader/error/retry, external research disclosure | Correct keyboard/state model; source distinction; no indefinite fake success/loading. |
| P1 | Footer, 404, buttons, badges, print styling | Useful links, real license, concise recovery, finite supported variants, readable print. |
| P2 | Optional meridian motif and genuine curated feature | Only after P0 works; decoration never delays access to reading. |

## Implementation slicing proposal

This is a proposed division of **one design-domain implementation**, not six specifications/plans. Claude should merge this research and axe evidence into `docs/specs/001-design-system-v1/spec.md`, one `plan.md` and one `tasks.md` before implementation. Backend authentication, wiki storage/revision history and cross-repository publishing contracts need separate domain-owned specs if required; do not bundle them into the design plan. For v1 design, expose only the working flows already selected by the maintainer.

Ownership below prevents two agents editing the same files. New stylesheet names are proposed, not existing artifacts. No parallel agent was spawned for this audit.

| Slice / owner | Exclusive files | Deliverable and dependency |
|---|---|---|
| 1. Foundations and primitive contracts — Agent A | `_includes/components/atoms/head.html`, `_includes/head.html`; all `_includes/components/atoms/*.html` except immutable existing brand assets; new `assets/css/tokens.css`, `base.css`, `primitives.css`, `assets/fonts/*` | **First.** Agree finite button/link/badge/input/card APIs; establish fonts, theme/focus/motion, measure/type rules and stylesheet loading. Predeclare slice-specific CSS imports/links so other owners need not edit head. Preserve Jekyll/Liquid contracts; decide static CSS versus pinned compiled Tailwind in the plan. |
| 2. Canonical shell and navigation — Agent B | `_layouts/default.html`, `_layouts/data.html`; `_includes/header.html`, `_includes/footer.html`; `_includes/components/organisms/header.html`, `footer.html`, `sidebar-navigation.html`; `_includes/lang-switch-url.html`; molecules `language-switcher.html`, `language-selector.html`, `breadcrumb.html`; new `assets/css/shell.css`, `javascript/ipl-shell.js` | After 1 contracts are stable. One logo/shell, responsive named search form, nav/skip link, disclosures and locale mapping, appearance preference, concise footer. Legacy includes become wrappers or are retired after reachability audit. Token definitions remain owned by A. |
| 3. Discovery pages and resource presentation — Agent A | `_layouts/language_index.html`, `categories.html`, `category.html`, `subcategory.html`, `resource.html`, `resources.html`, `index.html`; root `index.html`, `404.html`; `_includes/resource-grid.html`, `_includes/category-sidebar.html`; molecules `card.html`, `resource-card.html`, `category-card.html`, `featured-article.html`, `keywords-cloud.html`; organisms `categories-section.html`, `categories-tree-section.html`, `hero-section.html`, `category-sidebar.html`, `resource-grid.html`, `featured-resources-section.html`, `search-section.html`; `javascript/ipl-dynamic.js`; new `assets/css/discovery.css` | After 1; can run alongside 2. Content-first home/category/404, complete labels, one resource contract, no fake totals/placeholders, proper feature/feed status. Does not edit article generators, discussion, provider scripts or dedicated search pages. |
| 4. Article/section/wiki reading — Agent B | `_layouts/section.html`, `_layouts/wiki.html`, `_layouts/page.html`; `_includes/templates/*.md`; `_includes/components/wiki_preview.html`; `_plugins/wiki_generator.rb`, `_plugins/site_page_generator.rb`; new `assets/css/article.css`, `javascript/ipl-article.js` | After B completes 2; runs alongside 3. Reading layout, single H1, real contents, source/related metadata, honest empty state, true revision labels and working article/talk/edit destinations. Owns generators so A must consume their agreed output contract without editing them. No new wiki backend. |
| 5. Search, contribution and research interactions — Agent A | `_includes/components/discussion.html`; molecules `search-form.html`, `search-bar.html`, `search-panel.html`, `result-card.html`, `tab-nav.html`, `tree-list.html`, `wiki-edit-form.html`, `wiki-create-form.html`, `issue-form.html`, `wiki-summary-box.html`, `dashboard-sidebar.html`; templates `academic-dashboard.html`; organisms `search-wikipedia.html`, `search-openalex.html`, `search-arxiv.html`, `search-orcid.html`, `search-scholar.html`, `search-coursera.html`, `search-youtube.html`, `search-meetup.html`; `_includes/components/htmx/*.html`; `en-US/search.html`, `pt-BR/busca.html`, `en-US/submit-resource.html`, `pt-BR/enviar-recurso.html`, `en-US/login.html`, `pt-BR/login.html`, `en-US/signup.html`; `api/search.json`; new `assets/css/interactions.css`, `javascript/ipl-interactions.js` | After A completes 3; can run alongside B's 4 using frozen search/edit/discussion contracts. Real query/results/fallback, keyboard tabs/disclosures, validated contribution channel and truthful receipt. Optional provider loading with error/retry. Account/new-backend functionality remains out of scope; links are gated to real services. |
| 6. Integration and evidence — Agent B, both review | New `e2e/design-v1.spec.*` and focused fixture/validation files agreed with existing test owner; design spec acceptance/task records; any test-config/package changes assigned explicitly to this owner | After 2–5 are integrated. Render both languages/themes, navigate home→category→subcategory→section→wiki and contribution return path; check links, source semantics, keyboard, 320/390/768/1440 px, zoom, text spacing, reduced motion, forced colors and provider failure. Merge axe findings with manual evidence and mark remaining limitations accurately. |

Schedule with two agents: **1 → (2 ∥ 3) → (4 ∥ 5) → 6**. Freeze component props and resource/search/locale payload contracts at the end of 1. During parallel work, shared files stay read-only to the nonowner; request changes from their owner. CSS files are distinct per slice and selectors must be scoped so page styling does not override token/primitive contracts. Any `_config.yml`, build-tool or data-schema changes must receive one named owner in the plan rather than both agents opportunistically editing them.

Validation is behavioral, not only screenshot matching: verify search query and result destination, fragment/history navigation, unsaved-edit preservation, native invalid-form blocking, exact submitted-versus-published wording, discussion fallback, translation fallback and meaningful revision metadata. An axe pass does not establish target-size spacing exceptions, keyboard usability, content truthfulness or the editorial quality of citations. Do not run live submission tests against community systems; use local mocks/fixtures.

## Open questions for the maintainer

1. Is the SVG globe approved as the canonical header/footer brand, and should the accessible/full name always remain “Internet Public Library” rather than “BPI” in Portuguese? What is the exact Better Web / Open Digital Brasil relationship to show consistently?
2. Which contribution path actually works today: GitHub edits/Issues, a configured Staticman endpoint, or another reviewed submission service? Should v1 remove account login/signup until authentication exists?
3. Does “wiki” mean a maintained IPL article per section, or should the section itself be the article with resource and talk tabs? Should category/subcategory Wikipedia extracts remain optional external context?
4. Where is the authoritative curated resource schema and revision history? Which timestamps represent editorial change versus link verification, and are any current quality/popularity statistics defensible?
5. Can categories/sections gain stable translation IDs so language switching preserves meaning across localized slugs and missing translations? What should a reader see when the target language has no equivalent?
6. Which resource types and access rules belong in v1 filters: sites, articles, books, courses; language; free/paid; difficulty? What minimum source/publisher/citation information is required before a resource is called curated?
7. Should external research services be retained as a collapsed optional tool, moved to a dedicated research page, or cut for v1? Their live results should not be described as curated IPL resources.
8. Is Meridian Archive approved, including self-hosted Source Serif 4 / Source Sans 3 and System/Light/Dark appearance? Is preserving Tailwind runtime a requirement, or may the plan move to static/compiled local CSS?
9. Which exact content license/version and contributor attribution policy should the genuine license links and article metadata expose? Do not infer this from placeholder `#` links.
10. Which representative populated English/Portuguese articles and resource lists should serve as acceptance fixtures, alongside empty/error states? Existing placeholder-only pages cannot establish a successful reading experience.

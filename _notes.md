# Maintenance notes

Working notes for the site. The leading underscore means **Quarto ignores this file** —
it is never rendered and never published. Notes used to live as `<!-- -->` comments
inside the `.qmd` files, but those pass straight through into the published HTML and
were readable in view-source, so they live here instead.

Rule of thumb: `#` comments inside a YAML header are safe (never rendered).
`<!-- -->` comments in the body of a page are **not** — they ship.

---

## Rendering: one writer at a time

`.claude/launch.json` runs a plain static server (`python3 -m http.server`) against
`_site/`, **not** `quarto preview`. This is deliberate.

`quarto preview` is not a passive server: it renders the site itself and serves its own
in-memory copy. That gives two failure modes, both of which bit during setup:

- **default** — it re-renders on file change and writes into `_site`, silently
  overwriting whatever `quarto render` just produced;
- **`--no-watch-inputs`** — it stops overwriting, but then serves permanently stale
  HTML, because it never refreshes its in-memory copy. Verified by appending a marker
  directly to `_site/research.html`: the response did not change by a byte.

So: **render explicitly, then reload the browser.** If an edit ever appears and then
vanishes, two things are rendering at once. Stop the preview, then:

    rm -rf _site .quarto && quarto render

Quarto lives at `/Applications/RStudio.app/Contents/Resources/app/quarto/bin/quarto`
(it is not on `PATH`). RStudio's Render button is fine as long as nothing else renders
at the same time.

---

## Publication lists (research.qmd)

Written out by hand on purpose. No `bibliography:`, no CSL, no Chicago or Harvard.

Why it cannot be generated: pandoc renders exactly one bibliography per page, sorted by
the citation style. Verified — a second `::: {#refs-second}` div renders zero entries.
So "under review" and "conference papers" as two separately ordered sections is
impossible via citeproc. This is independent of BibTeX vs BibLaTeX; Quarto never runs
`bibtex` or `biblatex` for HTML output.

**Two sources feed the page:**

- `_sources/stef-biblatex.bib` — Zotero export, current work
- `_sources/SS_Academic_CV_Sep_2025.zip` → `main.tex` — older items not in the bib
  (the two NIG conference papers came from here)

To refresh: export Zotero over `_sources/stef-biblatex.bib`, then ask Claude to re-read both and
rewrite the sections.

**House style**, so re-runs stay consistent:

- Title in italics on the first line, sentence case, proper nouns capitalised.
- Full author list in bib order underneath, own name in **bold**.
- `Venue · City, Month Year · link`
- Link text says what it is: "Paper details" for a page, "Paper (PDF)" for a direct
  download.
- Methods training uses a different shape (bold school · institution, city · date, then
  the modules) because it is not a publication.
- Newest first throughout.

**BibLaTeX gotcha:** a `pages` field on an `@inproceedings` entry *suppresses*
`eventtitle` under Chicago CSL — the conference name silently vanishes. Those values
were page counts anyway; use `pagetotal`. Only matters if the bib is ever rendered
directly, but it also corrupts CV output.

---

## Things to fix in the source documents

**In Zotero** (otherwise the next export reinstates them) — both were fixed in
August 2026, listed here in case they recur:

- the EUSA entry's `url` held pasted text rather than a URL;
- `pages = {35}` / `{34}` were page counts, not page ranges.

**In the CV** (`_sources/SS_Academic_CV_Sep_2025.zip` → `main.tex`):

- research team is written "Politics, Policy, and Society"; the correct name is
  **"Policy, Politics and Society"**, as on the EUR and Pure profiles;
- the 2023 NIG title reads "does the RRF **alters** the patterns of **CSRs**
  compliance" — corrected on the website to "alter" / "CSR compliance";
- "Univeristy of Amsterdam" → "University";
- "European Union **Study** Association" → "Studies".

---

## Page-specific

**index.qmd** — the photo `images/profile.jpg` was cropped and resized from a
5909×5075 portrait by **M. Muus** (2023-10-23), archived in `_sources/originals/` (underscore prefix,
so not published). Credit the photographer if EUR's terms require it.

The email uses Quarto's `about: links:`, but `styles.css` strips the button chrome so
the address reads as plain text. That override is scoped to
`div.quarto-about-trestles`, which is why the same mechanism on **contacts.qmd**
(template `jolla`) still renders as buttons.

**Deliberately not on the site:** phone number (spam magnet) and education history.

**teaching.qmd** — the CV records only thesis supervision. If courses, tutorials,
seminars, or guest lectures get added, use this shape:

    ## Courses

    ### [Course title]
    **[Course code]** · [Level] · Erasmus University Rotterdam · [Terms taught]
    [Two sentences on what the course covers and who it is for.]

**outreach.qmd** — still entirely placeholder; nothing in the CV fills it. Consider
hiding it from the navbar until there is real content.

**cv.qmd** — the CV, rendered twice from one file: the site page and `cv.pdf`
(Typst, bundled with Quarto; nothing to install, CI needs nothing extra). Prose is
plain markdown, so it is phone-editable like every other page. Conventions:

- Dated entries are **definition lists** (`2023–present` on one line, `:   entry` on
  the next). Pandoc makes `<dl>` for the page (laid out as a date column by
  `styles.scss`) and `terms` for Typst (a two-column grid in `_cv/typst-template.typ`).
  A second entry in the same year uses `&nbsp;` as its term so the year prints once.
- The page head is: title (name + "Curriculum vitae" in one line), the PDF button, the
  "Last updated" line, a rule, then the CV. Quarto's own date block under the title is
  switched off by the empty partial `_cv/title-metadata.html`, so the date can sit
  under the button instead. `pagetitle:` keeps the browser tab short.
- `date:` in the YAML is the "Last updated" stamp, on the page and in the PDF footer,
  **and the PDF's file name**: the post-render script `_cv/name-pdf.sh` copies
  `_site/cv.pdf` to `_site/yy-mm-dd-scibilia-cv.pdf` and points the button at it, so
  whoever saves it gets that name. `cv.pdf` stays as a stable alias. The application
  render is renamed the same way inside `_application/`.
- The `cv:` keys (name, position, affiliation, address, email, website, orcid) feed
  the PDF header through `_cv/typst-show.typ`; the page's header block reads the same
  keys with `{{< meta cv.… >}}`, so there is one place to change them.
- `include-in-header` sits under `format: html:` on purpose: at the top level Quarto
  pastes it into the Typst source too, where `<meta` reads as an unclosed label.
- Quarto shifts heading levels down by one for Typst, so `##` is level 1 and `###`
  level 2 in the template's show rules.
- Quarto's `definitions.typ` styles `terms.item`; only a later rule on the **same**
  element overrides it (a rule on the parent `terms` never fires). Verified.
- Fonts for the PDF are the TTF twins of the site's woff2 in `fonts/` (converted with
  fontTools; XeTeX and Typst cannot read woff2). `font-paths: fonts` in the YAML.
- The "Open PDF version" button is a plain link in the HTML-only header block, not
  Quarto's `format-links`: those live in the side column, which phones do not show.

**The application CV** (phone number + referees) comes from the gitignored profile
`_quarto-application.yml`:

    quarto render cv.qmd --profile application --to typst

writes `_application/Scibilia_CV.pdf` (folder gitignored; Quarto also drops a few
site stubs in there, harmless). The site render never sees the profile, so `cv.pdf`
and `cv.html` carry neither. The old LaTeX version is archived in `_sources/cv/`.

**teaching.qmd** — the CV records only thesis supervision. If courses, tutorials,
seminars, or guest lectures get added, use this shape:

    ## Courses

    ### [Course title]
    **[Course code]** · [Level] · Erasmus University Rotterdam · [Terms taught]
    [Two sentences on what the course covers and who it is for.]

**outreach.qmd** — still entirely placeholder; nothing in the CV fills it. Consider
hiding it from the navbar until there is real content.

**cv.qmd** — **hidden from the site since 6 October 2026** while Stefano updates the CV:
`_quarto.yml` excludes it from `render:` and has the resource line and the navbar entry
commented out; the files stay in the repo. Re-enabling is those three lines.
It embeds `cv.pdf` (project root, listed under `project: resources:`) with
`<object>` and offers a download link above it. `styles.scss` hides the embed below
768px because phones do not render inline PDFs (iOS Safari shows one unscrollable page,
Android Chrome nothing), so there the link is the whole page. `cv.pdf` is the *website
copy* that `_sources/cv/build.sh` builds from `cv-web.tex`: no phone number, no
referees. Never copy `Scibilia_CV.pdf` there. To update the site's CV: edit `cv.tex`,
run `build.sh`, commit and push `cv.pdf`.

---

## The LaTeX CV (`_sources/cv/`, gitignored) — archived

The first version of the CV (6 October 2026) was LaTeX, compiled with tectonic, with the
same design. It was superseded the same day by `cv.qmd` (see above) so that the CV is
edited like any other page and the PDF rebuilds on every render. The folder stays as a
reference; `build.sh` still compiles it. Facts verified then and carried over: PhD
start 15 January 2023; referees' titles and emails from their EUR profile pages;
memberships ECPR, NIG, SISEC; no awards; grades deliberately left out; phone is the EUR
office line; "Policy, Politics, and Society" is EUR's order for the team name.

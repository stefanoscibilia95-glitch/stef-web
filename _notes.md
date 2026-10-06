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

## The application CV (`_sources/cv/`, gitignored)

Built 6 October 2026 from the website, the September 2025 CV archive and a LinkedIn
export. LaTeX (`cv.tex`), compiled with XeLaTeX — locally through tectonic
(`./build.sh`), or on Overleaf. European academic-CV practice with US practice as the
tiebreaker: A4, languages, referees with contacts, no photo, no date of birth, and no
nationality line (Stefano's call). `build.sh` makes two PDFs from the one source:
`Scibilia_CV.pdf` for applications and `../../cv.pdf` for the website, the latter via
`cv-web.tex`, which sets `\webversion` so the phone number and the References section
drop out. `README.md` in the folder has the Overleaf steps and the house rules.
A copy of the source for Overleaf was zipped to `~/Desktop/Scibilia_CV_latex.zip`.

- **Fonts** are the website's: `fonts/*.woff2` converted to TTF with fontTools
  (`TTFont(...).flavor = None`). If the site fonts ever change, reconvert; XeTeX cannot
  read woff2.
- **Facts verified on 6 Oct 2026:** PhD start 15 January 2023 (Stefano; the 2025 CV
  said February); referees' titles and emails from their EUR profile pages
  (Haverland full professor, Zhelyazkova associate professor). Memberships ECPR, NIG,
  SISEC (Stefano). No awards; grades deliberately left out (Stefano).
- **Phone** is the EUR office line from the 2025 CV, not a mobile.
- **Internship** (Bosch Rexroth, 2020–2021) is included because it fills the gap
  between the Durham and Amsterdam degrees; it is the first thing to cut if space is
  ever short again.
- Three pages, by Stefano's decision (a two-page cut was built first and rejected).
- Structure, by Stefano's decision: *Academic appointments* before *Education*, with
  the PhD only under appointments (an employed position, with completion date,
  project and supervisors as sub-points) and not repeated under education.
  "Academic service and societal outreach" is his wording for the service section.
- The team is written **Policy, Politics, and Society** everywhere (EUR's order; he
  typed it the other way round once). It sits in the header, the PhD entry and both
  referees' affiliations: it is the de-facto department within ESSB.

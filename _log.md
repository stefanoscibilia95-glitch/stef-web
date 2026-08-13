# Build log

Chronological record of work on the site. Underscore prefix ⇒ Quarto never publishes
this. For *how the site works*, read `CLAUDE.md`; for maintenance detail, `_notes.md`.
This file is the "why we ended up here" record — append a new dated section per session.

---

## 2026-08-13 — initial build and launch

**Outcome: live at <https://stefanoscibilia.com>** with HTTPS, automated publishing,
and a health-check script.

### What was built

Five pages — landing (`about: trestles`), Research, Teaching, Outreach, Contacts —
plus a 404. Light/dark themes (cosmo/darkly) with a custom SCSS layer. Self-hosted
Jost for the name; photo cropped and downscaled from the original portrait.

### Decisions worth remembering

- **Publication lists are hand-written.** Pandoc renders one bibliography per page,
  so "under review" and "conference papers" as two separately ordered sections is
  impossible via citeproc. Confirmed a second `#refs` div renders zero entries. The
  `.bib` stays as the data source; house style for regenerating is in `_notes.md`.
- **Affiliation reads narrow → broad** (group, department, university) with the
  Oxford comma, matching EUR and Pure. Stefano is a political scientist in a public
  administration department; the department is stated factually in the affiliation
  line and "political scientist" is claimed in bio prose.
- **Jost over Futura.** Futura was the original request, but it ships only on
  macOS/iOS and its licence forbids self-hosting, so non-Apple visitors would have
  seen a fallback. Jost is SIL OFL, self-hosted (10 KB, Bold Latin subset only),
  identical everywhere. Not loaded from Google Fonts — no third-party requests,
  which also avoids the GDPR issue with embedding Google Fonts on EU sites.
- **Cloudflare proxy deliberately OFF** (grey cloud). The site is already on a CDN
  via GitHub/Fastly; proxying would add a cert-renewal failure mode, and Bot Fight
  Mode is known to break link-preview fetchers — which would silently kill the
  social cards. Cloudflare's security toggles are inert while unproxied.
- **Phone number and education history are deliberately absent** from the site.
  The CV archive lives in `_sources/` and is gitignored, because free GitHub Pages
  requires a public repo and `main.tex` contains the phone number.

### Problems hit, and the fixes

Each of these cost real time; all are documented in `CLAUDE.md` so they don't recur.

- **Render race.** `quarto preview` is not a passive server — it renders and serves
  its own in-memory copy, so it silently overwrote `quarto render` output. Symptom:
  an edit appears, then vanishes. `--no-watch-inputs` was a trap: it stops the
  overwriting but then serves permanently stale HTML. Fixed by serving `_site`
  statically instead (`.claude/serve.py`), leaving exactly one writer.
- **Stale CSS.** `css: styles.css` has a fixed filename, so browsers served a
  cached copy after edits — for us during development and for returning visitors
  after any restyle. Fixed by moving it into the theme pipeline as `styles.scss`,
  which Quarto emits under a content-hashed filename.
- **Authoring comments were published.** `<!-- -->` in a `.qmd` body passes into the
  output HTML and is readable in view-source. Moved to `_notes.md`. Only `#`
  comments inside a YAML header are stripped.
- **Mangled social-card text.** Quarto derived `og:description` from the subtitle and
  stripped the `<br>` tags without inserting spaces, giving "PhD CandidatePolicy,
  Politics, and Society…". Fixed with explicit metadata; note that a plain
  `description:` key would also print visibly on the page, so descriptions are
  injected as raw tags via `include-in-header`.
- **`pages` suppressed `eventtitle`.** In the BibLaTeX export, a `pages` field on an
  `@inproceedings` entry makes Chicago CSL drop the conference name entirely.
  Those values were page counts; `pagetotal` is correct.
- **`url()` in SCSS resolves from the project root**, not from the compiled
  stylesheet's location — `../../fonts/…` failed the build by resolving to
  `/Users/fonts/`.
- **`CLAUDE.md` would have been published** as a page at `/CLAUDE.html`, since Quarto
  treats every `.md` as an input. Fixed with `project: render: ["*.qmd"]`.
- **Quarto specificity.** Its own rules carry element qualifiers
  (`div.quarto-about-trestles .about-entity`); a classes-only override loses.
- **Navbar height mismatch between themes** came from one variable: cosmo sets
  `$navbar-padding-y: 0.5rem`, darkly `1rem`. Pinned in the shared defaults layer.
  The same fix corrected the footer, which derives from the same variable.

### Infrastructure

- GitHub Pages from `gh-pages`; sources on `main`. Repo is public.
- Cloudflare DNS, four GitHub apex A records + `www` CNAME, all DNS-only.
- Let's Encrypt cert issued 2026-08-13, auto-renewing.
- **Auth: SSH** (ed25519, `~/.ssh/config` entry, keychain). Replaced a PAT that
  would have expired 2026-09-12.
- **CI publishing** via `.github/workflows/publish.yml` — push to `main` renders and
  deploys. Works from any machine or GitHub's web editor. Do not also publish
  locally; that reintroduces the two-writer problem.
- `./check-site.sh` verifies DNS, cert expiry, all pages, and every outbound link.

### Open items

- **Google indexing**: Search Console not yet set up; submit `sitemap.xml` there.
  The EUR staff page now links to the site, which is the strongest signal available.
- **Outreach page** holds a single OSE event under a `2026` heading, phrased
  "currently organizing" — will date quickly.
- **CV corrections** still outstanding in `main.tex` (see `_notes.md`): wrong research
  team name, two typos, and the 2023 NIG title.
- Optional: turn off Cloudflare Bot Fight Mode so it cannot bite if the proxy is
  ever switched on.

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

---

## 2026-08-21 — editing routes across desktop, web, and phone

Deleted `claude/website-repo-setup-check-la7yir`, an empty branch left behind by a
read-only Claude Code web session. It pointed at the same commit as `main` — that
session had verified the repo and changed nothing, so there was nothing to merge and
nothing to deploy, which is why it looked like it had failed. Worth recognising the
pattern: an empty `claude/…` branch is a completed read-only session, not a broken one.

Documented the five editing routes in `CLAUDE.md`. Two beliefs held during that
session were wrong and are corrected there:

- **The GitHub iOS app can edit files** — Browse code → Edit File → Commit, shipped
  November 2022. The web session guessed otherwise because its sandbox blocked
  `docs.github.com`; it did flag the guess as unverified.
- **No SSH key is needed on the phone.** SSH authenticates git from a command line
  only. The app, mobile Safari, and cloud sessions all ride the logged-in GitHub
  account. The Mac's key is the only one in play.

---

## 2026-08-21 (cont.) — the one-renderer rule, now enforced

Refined the rule in `CLAUDE.md`. "Never run `quarto preview`" was over-broad.
RStudio's Render button launches `quarto preview --no-watch-inputs`, and that is
the standard, correct Quarto workflow when it is the *only* renderer — it
refreshes itself on each Render. The bug was never preview; it was two renderers.
Stefano working alone in RStudio should simply click Render. The render-plus-
static-server arrangement is Claude's workflow, not his, and asking him to carry
it was the wrong call.

Added `.claude/guard-renderer.sh`, a PreToolUse hook on Bash (wired up in
`.claude/settings.json`) that refuses `quarto render` and `quarto publish` while a
Quarto preview is listening. The collision is now impossible rather than something
either of us has to remember.

Detection is by **listening `deno` process**, not by command-line text. That
matters twice: `serve.py` is Python so it can never be mistaken for a preview, and
a shell that merely *mentions* "quarto preview" in its text does not trip it. The
guard fails open on unexpected input — a broken guard should not wedge the
session, and a missed check only costs a stale preview.

Verified end to end, five cases: allows unrelated commands; allows a render with
nothing serving; ignores malformed input; blocks a real render against a live
preview on :4399 with an actionable message; allows again once the preview stops.

---

## 2026-08-26 — palette discipline, typography, and removing search

A pass to reduce the number of things in play rather than add any.

### The palette is now three colours

Red `#CC0000`, yellow `#FFD700`, green `#D3DCBF`, plus warm neutrals. Getting
there needed two fixes that were not obvious:

- **Bootstrap invents colours.** It derives the active-nav tint from
  `$link-color` and was rendering `#8B0000` — a red nobody picked. Both mode
  files now pin the active text explicitly.
- **A red that failed.** Brand red on the sage band measures 4.14, under the AA
  floor, which had forced a second darker red (`#A80000`) into the design. Fixed
  by changing the mechanism, not the colour: the current page is marked by a 3px
  underline rather than a colour change. An underline is a *graphical* element
  needing 3:1, not the 4.5:1 text requires. The underline then took the nav text
  colour via `currentColor` — red and yellow are for links and the email address,
  not navigation — so it costs no colour at all, and satisfies WCAG 1.4.1 into
  the bargain.

### Typography

Body is self-hosted Source Serif 4 (four faces, latin subset, ~92 KB), headings
Jost. Two typefaces, no others.

Auditing that turned up a live privacy leak: **both Bootswatch themes `@import`
their own font from Google** — cosmo pulls Source Sans Pro, darkly pulls Lato —
regardless of whether the stacks are overridden. Two render-blocking requests per
page for fonts nobody sees, and every visitor's IP handed to Google, which is the
exact GDPR reason Jost was self-hosted in the first place. `$web-font-path: false`
removes it. Re-check with `grep -rl fonts.googleapis _site` after any theme change.

Dark-mode text moved off pure white. `#FFFFFF` on `#222` is 15.9:1, more than
double AAA, and that much contrast makes light type bleed into the dark ground —
halation, worse for anyone with astigmatism. `#F2EEE4` gives 13.7:1: still past
AAA, visibly softer, and warm enough to echo light mode rather than add a colour.

### Search removed

`search: false`. It shipped ~145 KB of JavaScript plus an index — more than every
font combined, more than the profile photo — to search five pages that are all one
navbar click away. It also derived its colours from `$primary` rather than
`$link-color`, so the results panel stayed cosmo blue and, once retinted,
generated a lightened red of its own. Setting `$primary` does work if it is ever
wanted back; the objection was that it did not earn its weight.

Quarto still emits `search.json` and two empty container divs. Both are inert with
the JavaScript gone.

### Favicon

Ink `S` on a brand-green circle, replacing white-on-red. Honest trade: the sage
disc reads well on a dark tab but nearly disappears on a light one, leaving a
floating dark `S`. Still legible, less present. Chosen to match the light theme.

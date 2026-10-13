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

---

## 2026-08-26 (cont.) — the design system, closed out

The rest of the styling pass. Everything below was about removing choices rather
than adding them.

### Which face goes where

Jost for the name, the navbar and every heading; Source Serif 4 for body,
citations and the TOC. The rule is **scan versus read** — if you navigate by it,
it is Jost. The navbar had been in the body serif, which made it read as a
sentence rather than a set of destinations.

The rejected alternative was Jost for the name only, everything else serif. It
loses on two counts: headings and body collapse into one voice, so hierarchy
comes only from size; and it means self-hosting a whole typeface for one string.
A pairing should do work.

### Hovers, and three accepted contrast shortfalls

Light mode already had a red hover nobody designed: Bootstrap shades `$link-color`
to `#8B0000` at 80% opacity. It looked good and measured 5.38 — but it was a
fourth red. Dark mode meanwhile had darkly's near-white at 80%, measuring **4.00**
— already under AA, and barely legible as a state change at all.

Both are now the brand colour outright: `#CC0000` on green at 4.14, `#FFD700` on
red at 4.20. Both under the 4.5 floor, both accepted on the same reasoning as the
footer link: transient states sitting over resting colours of 9.21 and 5.08, and
the alternative in each case was a colour outside the palette. The dark one is an
improvement on what it replaced regardless.

Ordering matters: the `:hover` rule must come **before** `.nav-link.active` in
each mode file. Same specificity, so the later rule wins, and that is what keeps
the current page from shifting colour when the pointer crosses it.

### Smaller things

- Footer "Quarto" link back to brand red on the green band (4.14, accepted). The
  band stays; moving the footer to the page colour would have fixed the ratio but
  changed the layout.
- Theme toggle enlarged to 30×28 with a `currentColor` pill border, so it reads
  as a control. It was a bare 16px glyph, easy to miss entirely.

### Where the palette actually landed

Three brand colours, no derived shades left in the rendered output. Getting there
meant overriding Bootstrap three separate times — it generates its own active
tint, its own hover shade, and its own search accent, none of which follow
`$link-color`. **Assume it will invent a colour anywhere you have not pinned one.**

---

## 2026-10-13 — Radix Gold: tone-on-tone bands, two accents, one neutral scale

**Outcome:** both modes rebuilt on one neutral scale, Radix Gold, with the same
step numbers in each. The green light-mode band and the red dark-mode navbar are
gone; brand green is retired.

### Why

Stefano asked for a tone-on-tone mood — page and menu as two tones of one hue —
with brand red as the only accent in light mode and brand yellow as the only
accent in dark mode, built from palettes that were designed for both modes. Eight
candidates were mocked on the real pages (Flexoki, Gruvbox, Solarized, Selenized,
Everforest, Radix Gold, Rosé Pine, Catppuccin). Radix Gold won: warm but near
neutral, the strongest ink of the warm set, the dark ground closest to the old
`#222` only warmed, and a documented twelve-step scale in which the same step
plays the same role in light and dark.

### The mapping

| Role | Step | Light | Dark |
|---|---|---|---|
| Page | gold-2 | `#FAF9F2` | `#1B1A17` |
| Navbar and footer | gold-4 | `#EAE6DB` | `#2D2B26` |
| Rules and borders | gold-6 | `#D8D0BF` | `#444039` |
| Muted text | gold-11 | `#71624B` | `#CBB99F` |
| Ink | gold-12 | `#3B352B` | `#E8E2D9` |
| Accent | brand | red `#CC0000` | yellow `#FFD700` |

Gold's own solid steps (9 and 10) are never used; the brand colours take that
role, which is the Radix pattern of a neutral scale plus a separate accent.

### The band's depth, decided from four symmetrical mockups

Page-to-band difference in OKLCH lightness, light / dark, same steps in each:

- no band, hairline only: 0 / 0 — the calmest, and common on academic sites
- one step (gold-3) plus a hairline: 2.7 / 3.8 — needs the rule to register
- **two steps (gold-4): 5.6 / 7.2 — chosen.** Reads as a band without a rule
- three steps (gold-5): 8.6 / 11.2 — a contrasting band again; red hover 4.3

For scale: Bootstrap's default white page under its light navbar is 1.8, the old
green band was 9.4, the old red dark navbar 27.9. Under about 3 the step can
vanish on a dim screen and then looks like a fault; above about 9 it stops being
tone on tone.

### What it fixed

The three accepted contrast shortfalls (red hover on green 4.14, yellow hover on
red 4.20, footer link 4.14) are gone: red on gold-4 is 4.72, yellow on gold-4 is
10.1. The ink barely moved — 11.5:1 light, 13.5:1 dark, against 12.2 and 13.7
before — so the text reads as it did; only the grounds changed.

### Mechanics

Eight variables per mode file: `$body-bg`, `$body-color`, `$navbar-bg`,
`$footer-bg`, `$navbar-fg`, `$border-color`, `$body-secondary-color` (with
`$text-muted`), `$link-color`. No page body changed. The CV PDF is untouched
(black on white) and the favicon too: the red Satt S reads on both grounds.

The mockups were made outside the repo: the built `_site` pages rendered through
headless Chrome with an override stylesheet injected, then composed into contact
sheets. Nothing from them is committed.

### Same day — the nav underline goes back to the accent

Stefano asked for the current-page rule in brand red (light) and brand yellow
(dark) rather than the ink. First attempt was one rule in `styles.scss`,
`border-bottom-color: var(--bs-link-color)` — and it rendered **blue**: Quarto
gives the navbar `data-bs-theme="dark"` in both modes, and Bootstrap's dark block
redefines `--bs-link-color` to a tinted blue inside it. So the colour is a literal
in each mode file, beside the hover rule; the item's text stays ink. As a graphical element it needs 3:1: 4.72 and 10.1 on the
gold-4 band. It had been `currentColor` since August, when the brand colours were
reserved for links; on the tone-on-tone band there is room for one accent.

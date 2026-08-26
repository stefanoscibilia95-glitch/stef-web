# stef-web — Stefano Scibilia's academic website

Quarto website, live at **https://stefanoscibilia.com** (GitHub Pages, custom domain
via Cloudflare DNS). Owner is a PhD candidate in political science at Erasmus
University Rotterdam.

## The Quarto binary

Quarto is not installed system-wide; the copy in use ships inside RStudio. Stefano
added it to `~/.zshrc`, so plain `quarto` works in RStudio's Terminal pane and in
any login shell. The full path still works and is what scripts here use:

```bash
/Applications/RStudio.app/Contents/Resources/app/quarto/bin/quarto   # 1.9.38
```

That version matches the pin in `.github/workflows/publish.yml`, so local output
and CI output agree.

**On the Mac only.** A cloud session (Claude Code on the web) has no RStudio and no
Quarto — do not try to render or preview there. Edit the `.qmd` files and let CI
render on merge.

## Rendering: ONE renderer at a time

The rule is **one renderer at a time** — not "never preview". `quarto preview` is
not a passive server: it renders the site itself and serves its own in-memory
copy. That is fine when it is the only thing rendering, and broken the moment
anything else writes `_site` underneath it.

Two failure modes, both hit during the first build:

- **default** — re-renders on file change and writes into `_site/`, silently
  overwriting whatever `quarto render` just produced. Symptom: an edit appears,
  then vanishes; the `.qmd` is correct but `_site` holds older HTML.
- **`--no-watch-inputs`** — stops overwriting, but then ignores external writes to
  `_site` entirely. Verified by appending a marker directly to
  `_site/research.html`: the response did not change by a byte.

So there are two valid setups, and mixing them is the only real mistake:

| Who is working | How |
|---|---|
| **Stefano alone in RStudio** | Click **Render**. This is the normal Quarto workflow and it is correct here. RStudio runs `quarto preview --no-watch-inputs` and refreshes it on each Render, so it stays self-consistent. |
| **Claude, from the command line** | `quarto render` plus the static server in `.claude/launch.json` (`.claude/serve.py`, port 4321), which reads from disk on every request and sends `Cache-Control: no-store`. |
| **Both at once** | Never. This is the bug. |

**Enforced, not remembered.** `.claude/guard-renderer.sh` runs as a PreToolUse
hook (wired up in `.claude/settings.json`) and refuses any `quarto render` or
`quarto publish` while a Quarto preview is listening. It identifies the preview by
its listening `deno` process, so `serve.py` (Python) never trips it, and it fails
open on unexpected input rather than wedging the session. To clear the block, stop
the preview with the red square in RStudio's Render / Background Jobs pane.

Claude's loop: **edit → `quarto render` → reload the browser.** If a change refuses
to appear, stop the server and `rm -rf _site .quarto && quarto render`.

## Publishing — push to `main`, CI does the rest

```bash
git add -A && git commit -m "..." && git push
```

`.github/workflows/publish.yml` renders on every push to `main` and deploys to
`gh-pages`. Nothing else is needed, and it works from any machine or from GitHub's
web editor — Quarto does not have to be installed.

**Do not also run `quarto publish gh-pages` locally.** That would make two writers
for `gh-pages`, the same class of bug as running `quarto preview` alongside
`quarto render`. Locally, `quarto render` is for previewing only.

If a run fails with a permissions error, set repo → Settings → Actions → General →
Workflow permissions to **Read and write**. Quarto is pinned to 1.9.38 in the
workflow so CI output matches local; bump it deliberately.

`CNAME` is committed and listed under `project: resources:` so the custom domain
survives every deploy.

## Editing from anywhere — five routes

None of these needs an SSH key except the Mac. SSH authenticates git from a command
line; the phone app, mobile Safari, and cloud sessions all ride the logged-in GitHub
account. There is nothing to set up on a new phone or browser beyond signing in.

| Route | Needs | Lands on | Goes live |
|---|---|---|---|
| Claude Code on the Mac | nothing | `main` | on push |
| RStudio by hand | Quarto | `main` | on push |
| Claude Code on the web | nothing | a `claude/…` branch | **after you merge** |
| github.com in any browser | nothing | `main` | on commit |
| GitHub iOS app — Browse code → Edit File → Commit | nothing | `main` | on commit |

**`git pull` before starting local work.** Every time. With several writers on one
repo a stale clone is the failure mode that will actually happen — the same class of
bug as two renderers, one level up.

**Web sessions are the odd one out.** Claude Code on the web opens a PR instead of
committing to `main`, so the change waits on a branch. That is the review step, not
a malfunction — but a change made there never reaches the live site on its own. Note
the trap: a *read-only* web session leaves behind a `claude/…` branch sitting at the
same commit as `main`, which looks exactly like a failed session. Compare the SHAs
before assuming something broke:

```bash
git ls-remote origin 'refs/heads/claude/*'
```

**The phone is the designated second route**, and it is deliberately kept working.
`.qmd` bodies are plain markdown, so the GitHub iOS app — Browse code → Edit File →
Commit — is enough to fix a typo, add a publication, or correct a date from
anywhere. It commits straight to `main` and CI publishes. Keep the `.qmd` bodies
free of anything that needs tooling to edit safely, so this stays true.

**Editing blind is safe enough.** Phone and browser edits skip the local render, so
they publish unseen. But `publish.yml` renders *and* deploys in one step: if the
render fails the deploy never runs and the live site keeps serving the last good
build. A bad commit gets a red X in Actions, not a broken website. So prose in `.qmd`
bodies is fine from anywhere; leave `styles.scss`, `dark.scss`, and `_quarto.yml` for
the Mac, where the result is visible before it ships.

## Working with Claude — snippets, not silent edits

**Default: Claude hands over the text, Stefano pastes it.** For anything in a
`.qmd` body, Claude says which file, what to find, and what to replace it with.
Stefano makes the edit, saves, clicks Render, and pushes. This is deliberate — he
is learning the workflow, and changes made for him teach nothing and leave him
unable to work alone.

Claude may do without asking: read any file, inspect git state, run diagnostics,
check the live site. All read-only, and they make the answers better.

Claude should ask first before: editing `.qmd` files directly, rendering while
RStudio may be open, or committing anything Stefano did not ask to have committed.
**Check `git status` before `git add -A`.** A blanket add once swept Stefano's
in-progress RStudio edits into an unrelated commit and published them early —
nothing was lost, but the timing was his call, not Claude's.

Infrastructure is different. `CLAUDE.md`, `_log.md`, `_notes.md`, `.claude/`,
`_quarto.yml`, `styles.scss`, `dark.scss`, and the workflow files are Claude's to
edit directly when asked.

## Page metadata

Every page carries a `<meta name="description">` plus `open-graph`/`twitter-card`
descriptions, injected as raw tags via `include-in-header`. **Do not replace these
with a plain `description:` key** — that key also prints on the page as a visible
subtitle under the title, which is why it was removed in the first place.
`index.qmd` additionally carries JSON-LD `Person` structured data.

## Layout

| Path | What |
|---|---|
| `index.qmd` | Landing page (Quarto `about: trestles`) |
| `research.qmd` `teaching.qmd` `outreach.qmd` `contacts.qmd` | Content pages |
| `404.qmd` | Not-found page; **links must stay absolute** (`/research.html`) because it is served from any depth |
| `styles.scss` | All custom CSS (theme layer, both light and dark) |
| `dark.scss` | Dark-mode SCSS variables only |
| `light.scss` | Light-mode SCSS variables only — the mirror of `dark.scss` |
| `_quarto.yml` | Site config, navbar, theme, Open Graph |
| `_notes.md` | Maintenance notes — **read this before non-trivial changes** |
| `_sources/` | Zotero `.bib`, CV LaTeX archive, full-resolution photo. Underscore prefix ⇒ Quarto never publishes it |
| `fonts/` | Self-hosted Jost + its OFL licence |
| `.claude/` | `serve.py` static preview server, `launch.json`, and `guard-renderer.sh` + `settings.json` (the one-renderer hook) |
| `images/` | `profile.jpg` (800×800, web-sized), `favicon.png` |

## Things that will bite you

**Body comments publish.** `<!-- ... -->` in a `.qmd` body passes straight into the
output HTML and is readable in view-source. Only `#` comments inside a YAML header
are stripped. Put working notes in `_notes.md`, never in page bodies.

**Only `.qmd` renders.** `project: render: ["*.qmd"]` exists so stray `.md` files
(this one included) do not become public pages.

**CSS must go in `styles.scss`, not a plain `css:` link.** Going through the theme
pipeline gives the output a content-hashed filename, so an edit always changes the
URL and can never be served from a stale browser cache — for you or for returning
visitors. A plain `css: styles.css` caused exactly that bug.

**Bootswatch themes phone home for fonts.** cosmo `@import`s Source Sans Pro from
Google and darkly imports Lato, whether or not you use them — two render-blocking
requests per page and every visitor's IP handed to Google, which is the GDPR
problem that made Jost self-hosted to begin with. Overriding the font stacks does
*not* stop it. `$web-font-path: false;` in `styles.scss` does. Re-check with
`grep -rl fonts.googleapis _site` after any theme change.

**Quarto specificity.** Quarto's own rules often carry an element qualifier
(`div.quarto-about-trestles .about-entity`). A classes-only override silently loses.
Match the qualifier.

**`url()` in SCSS is a build dependency.** Quarto resolves it from the *project
root*, not from the compiled stylesheet's location, and copies the file next to the
CSS. Use `url("fonts/x.woff2")`. A path like `../../fonts/...` fails the build.

**Publication lists are hand-written on purpose.** No `bibliography:`, no CSL. See
`_notes.md` for why (pandoc renders one bibliography per page, so grouped and
ordered sections are impossible) and for the house style used when regenerating
them from `_sources/stef-biblatex.bib`.

## Design decisions

- **Three brand colours, and no others.** Red `#CC0000`, yellow `#FFD700`, green
  `#D3DCBF`, plus warm neutrals for ground and ink. Do not introduce a fourth.
  Bootstrap will try to: it derives its own active-nav tint from `$link-color`
  (it produced `#8B0000` here), so both mode files pin that back explicitly.
- **Dark mode**: navbar `#CC0000`, links `#FFD700`, text `#F2EEE4`.
- **Dark-mode text is not pure white.** `#FFFFFF` on `#222` measures 15.9:1 —
  more than double AAA — and that much contrast makes light type appear to bleed
  into the dark ground (halation), which is worse for anyone with astigmatism.
  `#F2EEE4` gives 13.7:1, still well past AAA, visibly softer, and warm enough to
  echo the sepia of light mode instead of adding a colour. It clears the red
  navbar at 5.08:1.
- **Name on the landing page**: Jost Bold, all caps, self-hosted (SIL OFL). Sized
  1.8rem so it fits the column on one line with headroom.
- **Light mode is warm, not white.** cosmo ships `#FFFFFF` under a `#F8F9FA`
  navbar, which glares. `light.scss` sets the page to a `#FDF6E3` sepia and
  darkens the ink to `#34302A`. A warm ground carries darker text without
  harshness, so contrast *improved*: 12.2:1 against the white theme's 11.5:1.
- **The band is brand green `#D3DCBF`.** A pale near-grey band read as dull.
- **The current page is marked by a 3px underline in the nav text colour.** Not
  red, not yellow — those are reserved for links and the email address, and using
  them for navigation muddied what an accent means. The rule inherits the item's
  own colour via `currentColor`, so it costs no colour at all. It also satisfies
  WCAG 1.4.1: state is not signalled by colour alone. Inactive items carry a
  transparent border of the same width so nothing shifts. Note Bootstrap derives
  its own active tint from `$link-color` (it produced `#8B0000` here), so both
  mode files pin the active text back explicitly.
- **The navbar is 600, not the body weight**, which read thin beside Jost
  headings and the heavier band. That face is already self-hosted, so it is free.
- **Which face goes where: Jost for wayfinding, Source Serif for reading.** The
  name, the navbar and every heading are Jost; body text, citations and the TOC
  are the serif. The test is whether you *scan* it or *read* it. This is also why
  the navbar is not the body face — a nav row set in the reading serif reads as a
  sentence rather than a set of destinations.
- **Three accepted contrast shortfalls, all deliberate.** Both navbar hovers
  (brand red on green, 4.14; brand yellow on red, 4.20) and the footer's "Quarto"
  link (4.14) sit under the 4.5 floor. Each was a choice between the exact brand
  colour and a derived shade nobody picked — Bootstrap wanted `#8B0000` for the
  light hover and near-white for the dark one. The colour won because these are
  transient or incidental: hovers sit over resting colours of 9.21 and 5.08, and
  the footer is one 12px courtesy link. The dark hover also *improves* on
  darkly's default, which measured 4.00. **Never reuse these ratios for content.**
- **Two typefaces, both self-hosted, and no others.** Jost for headings and the
  name, Source Serif 4 for everything else. `bootstrap-icons` and `anchorjs-icons`
  are also loaded, but they are symbol sets for the search, theme toggle, contact
  buttons and heading anchors — not typography.
- **Body is self-hosted Source Serif 4, headings are Jost.** Four faces (400,
  400i, 600, 600i), latin subset only, ~83 KB total. Geometric sans display
  against a rational screen serif gives real hierarchy; a serif also carries the
  dense citation lists better than cosmo's sans did. Both SIL OFL licences are
  listed under `project: resources:` — serving the `.woff2` counts as
  redistribution.
- **One font stack in both modes.** cosmo asks for Source Sans Pro and darkly for
  Lato, and neither ships with the theme, so each mode fell back independently —
  measured on the author's Mac, light rendered Source Sans Pro and dark fell
  through to San Francisco, ~8% wider for the same string. `$font-family-sans-serif`
  is pinned in `styles.scss`, which is in both theme lists.
- **Favicon**: white Jost Bold `S` on a `#CC0000` rounded square, 256×256 with
  transparent corners. Chosen on 16px legibility, which is the only size that
  matters in a tab: a solid red block reads on both light and dark tab bars. The
  alternatives failed there — a black letter with no background is invisible on a
  dark tab, and white-background variants dissolve into a light one. The previous
  yellow-on-black went muddy as the strokes thinned.
- **Affiliation order** is narrow → broad, with the Oxford comma:
  PhD Candidate / Policy, Politics, and Society / Dept. of Public Administration and
  Sociology / Erasmus University Rotterdam. This matches EUR and Pure; the CV's
  "Politics, Policy, and Society" is wrong.

## Privacy

- **Never put the phone number on the site.** It is in the CV archive under
  `_sources/`, which is gitignored — the GitHub repo is public.
- Education history is deliberately not on the site.
- The photo is by **M. Muus** (2023); credit if EUR's terms require it.

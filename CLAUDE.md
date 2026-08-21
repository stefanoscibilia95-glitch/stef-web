# stef-web — Stefano Scibilia's academic website

Quarto website, live at **https://stefanoscibilia.com** (GitHub Pages, custom domain
via Cloudflare DNS). Owner is a PhD candidate in political science at Erasmus
University Rotterdam.

## Quarto is not on PATH

Use the RStudio-bundled binary:

```bash
/Applications/RStudio.app/Contents/Resources/app/quarto/bin/quarto
```

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

**Editing blind is safe enough.** Phone and browser edits skip the local render, so
they publish unseen. But `publish.yml` renders *and* deploys in one step: if the
render fails the deploy never runs and the live site keeps serving the last good
build. A bad commit gets a red X in Actions, not a broken website. So prose in `.qmd`
bodies is fine from anywhere; leave `styles.scss`, `dark.scss`, and `_quarto.yml` for
the Mac, where the result is visible before it ships.

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

- **Dark mode**: navbar `#CC0000`, links `#FFD700`, navbar text pure white (darkly's
  default `#DEE2E6` scores 4.52 on the red, barely passing WCAG AA; white gives 5.89).
- **Name on the landing page**: Jost Bold, all caps, self-hosted (SIL OFL). Sized
  1.8rem so it fits the column on one line with headroom.
- **Affiliation order** is narrow → broad, with the Oxford comma:
  PhD Candidate / Policy, Politics, and Society / Dept. of Public Administration and
  Sociology / Erasmus University Rotterdam. This matches EUR and Pure; the CV's
  "Politics, Policy, and Society" is wrong.

## Privacy

- **Never put the phone number on the site.** It is in the CV archive under
  `_sources/`, which is gitignored — the GitHub repo is public.
- Education history is deliberately not on the site.
- The photo is by **M. Muus** (2023); credit if EUR's terms require it.

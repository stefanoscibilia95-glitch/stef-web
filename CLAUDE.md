# stef-web — Stefano Scibilia's academic website

Quarto website, live at **https://stefanoscibilia.com** (GitHub Pages, custom domain
via Cloudflare DNS). Owner is a PhD candidate in political science at Erasmus
University Rotterdam.

## Quarto is not on PATH

Use the RStudio-bundled binary:

```bash
/Applications/RStudio.app/Contents/Resources/app/quarto/bin/quarto
```

## Rendering: ONE renderer at a time

**Never run `quarto preview`.** It is not a passive server: it renders the site
itself and serves its own in-memory copy. Two failure modes, both hit during
development:

- **default** — re-renders on file change and writes into `_site/`, silently
  overwriting whatever `quarto render` just produced. Symptom: an edit appears,
  then vanishes; the `.qmd` is correct but `_site` holds older HTML.
- **`--no-watch-inputs`** — stops overwriting, but then serves permanently stale
  HTML because it never refreshes its in-memory copy. Verified by appending a
  marker directly to `_site/research.html`: the response did not change by a byte.

To preview, use the static server in `.claude/launch.json` (`.claude/serve.py`,
port 4321). It reads from disk on every request and sends `Cache-Control: no-store`,
so there is exactly one writer (`quarto render`) and one reader.

Workflow: **edit → `quarto render` → reload the browser.** If a change refuses to
appear, stop the server and `rm -rf _site .quarto && quarto render`.

## Publishing

```bash
quarto publish gh-pages     # updates what visitors see (gh-pages branch)
git add . && git commit -m "..." && git push   # saves the sources (main branch)
```

Both are needed; they do different things. `CNAME` is committed and listed under
`project: resources:` so the custom domain survives every republish.

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

// CV layout for the Typst (PDF) output of cv.qmd. Same faces as the site: Apfel
// Grotezk Fett for the name (mixed case) and Mittel for the section titles (caps,
// letterspaced), Ronzino for the text; a 2.7cm date column, ragged right.
//
// typst-show.typ calls `cv` with the document metadata; `doc` is everything that
// follows the YAML in cv.qmd. Page size and margins come from Quarto's own page.typ,
// so they are set in the YAML (papersize, margin), not here.

#let cv(
  name: none,
  position: none,
  affiliation: none,
  address: none,
  email: none,
  website: none,
  orcid: none,
  phone: none,      // only present when built with the application profile
  referees: none,   // idem
  updated: none,
  font: ("Ronzino",),
  fontsize: 11pt,
  doc,
) = {
  set document(title: content-to-string(name) + " — Curriculum vitae",
               author: content-to-string(name))
  set text(font: font, size: fontsize, hyphenate: auto)
  // One vertical scale, built on the 6pt leading (0.55em at 11pt): entries and
  // paragraphs 9pt apart (1.5×), sub-headings 12pt above / 6pt below (2× / 1×),
  // section titles 21pt above / 9pt below (3.5× / 1.5×). `spacing` is the gap
  // between paragraphs and between consecutive entries (pandoc writes every entry
  // as its own one-item list), so it doubles as the entry spacing.
  set par(justify: false, leading: 0.55em, spacing: 9pt)
  show link: set text(fill: rgb("#1F3A5F"))

  // Quarto shifts heading levels down by one for Typst, so ## in cv.qmd arrives as
  // level 1 and ### as level 2.
  // Section titles (## in cv.qmd): Jost caps, letterspaced, over a hairline.
  show heading.where(level: 1): it => {
    v(21pt, weak: true)
    block(breakable: false, below: 9pt, stack(dir: ttb, spacing: 4pt,
      // Typst registers the Mittel OTF as its own family, "Apfel Grotezk Mittel"
      // (quarto typst fonts --font-path fonts), while Fett sits under "Apfel Grotezk".
      text(font: "Apfel Grotezk Mittel", weight: 500, size: 9.5pt, tracking: 0.06em, upper(it.body)),
      line(length: 100%, stroke: 0.5pt)))
  }
  // Sub-headings (### in cv.qmd): bold, never separated from what follows.
  show heading.where(level: 2): it => {
    v(12pt, weak: true)
    block(breakable: false, below: 6pt, text(weight: 700, size: fontsize, it.body))
  }
  // Dated entries. In cv.qmd each entry is a definition list: the date is the term,
  // the entry the definition. Each item becomes a two-column row, and no entry is
  // ever split across pages. The rule must target terms.item, not terms: Quarto's
  // definitions.typ styles terms.item, and only a later rule on the same element
  // replaces it (a rule on the parent terms never gets the chance).
  show terms.item: it => grid(
    columns: (2.7cm, 1fr), column-gutter: 0.2cm,
    it.term, block(breakable: false, it.description)
  )
  set terms(spacing: 3.5pt)
  // Sub-points: `spacing` is the full baseline-to-baseline gap between items, so it
  // must exceed the leading or the items overlap.
  set list(marker: [–], indent: 0.3em, body-indent: 0.45em, spacing: 7.5pt)

  set page(footer: context [
    #set text(size: 8pt)
    #name · Curriculum vitae#if updated != none [ · Last updated #updated]
    #h(1fr)
    Page #counter(page).display("1 of 1", both: true)
  ])

  // ---- Header
  text(font: "Apfel Grotezk", weight: 700, size: 30pt, tracking: 0.01em, name)
  v(8pt)
  if position != none { text(size: 12pt, style: "italic", position); v(9pt) }
  if affiliation != none { affiliation; linebreak() }
  if address != none { address; linebreak() }
  let parts = ()
  if email != none { parts.push(link("mailto:" + content-to-string(email), email)) }
  if phone != none { parts.push(phone) }
  if website != none { parts.push(link("https://" + content-to-string(website), website)) }
  if orcid != none { parts.push([ORCID #link("https://orcid.org/" + content-to-string(orcid), orcid)]) }
  parts.join([ · ])

  doc

  // ---- References: application build only (see _quarto-application.yml).
  if referees != none {
    heading(level: 1)[References]
    grid(columns: (1fr, 1fr), column-gutter: 0.8cm, ..referees.map(r => block(breakable: false)[
      #strong(r.name) \
      #r.role \
      #r.affiliation \
      #link("mailto:" + content-to-string(r.email), r.email)
    ]))
  }
}

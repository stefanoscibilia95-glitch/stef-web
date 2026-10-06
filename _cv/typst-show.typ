// Hands the metadata of cv.qmd (and, when rendering with the application profile,
// of _quarto-application.yml) to the `cv` function in typst-template.typ.
#show: doc => cv(
  name: [$cv.name$],
  position: [$cv.position$],
  affiliation: [$cv.affiliation$],
  address: [$cv.address$],
  email: [$cv.email$],
  website: [$cv.website$],
  orcid: [$cv.orcid$],
$if(cv-phone)$
  phone: [$cv-phone$],
$endif$
$if(cv-referees)$
  referees: (
$for(cv-referees)$
    (name: [$it.name$], role: [$it.role$], affiliation: [$it.affiliation$], email: [$it.email$]),
$endfor$
  ),
$endif$
$if(date)$
  updated: [$date$],
$endif$
$if(mainfont)$
  font: ("$mainfont$",),
$endif$
$if(fontsize)$
  fontsize: $fontsize$,
$endif$
  doc,
)

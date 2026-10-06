#!/bin/sh
# Quarto post-render step (wired up in _quarto.yml). Names the CV PDF after the
# `date:` in cv.qmd, so a visitor who saves it gets yy-mm-dd-scibilia-cv.pdf:
#
#   site render          _site/cv.pdf  -> copied to _site/26-10-06-scibilia-cv.pdf,
#                        and the page's button is pointed at it. cv.pdf stays as a
#                        stable alias for links elsewhere (email signature, etc.).
#   application profile  _application/Scibilia_CV.pdf -> renamed the same way.
#
# One place to edit, then: the `date:` line in cv.qmd. POSIX sh only, so it runs
# unchanged on the Mac and on the GitHub Actions runner.
set -e
out="${QUARTO_PROJECT_OUTPUT_DIR:-_site}"
d=$(sed -n 's/^date:[[:space:]]*"\{0,1\}\([0-9][0-9][0-9][0-9]\)-\([0-9][0-9]\)-\([0-9][0-9]\).*/\1-\2-\3/p' cv.qmd | head -1)
if [ -z "$d" ]; then
  echo "name-pdf: no YYYY-MM-DD date in cv.qmd, leaving the PDF name alone"
  exit 0
fi
name="$(echo "$d" | cut -c3-4)-$(echo "$d" | cut -c6-7)-$(echo "$d" | cut -c9-10)-scibilia-cv.pdf"
if [ -f "$out/cv.pdf" ]; then
  cp "$out/cv.pdf" "$out/$name"
  if [ -f "$out/cv.html" ]; then
    sed "s|href=\"cv.pdf\"|href=\"$name\"|g" "$out/cv.html" > "$out/cv.html.tmp" && mv "$out/cv.html.tmp" "$out/cv.html"
  fi
  echo "name-pdf: $out/$name (website copy; cv.pdf kept as alias)"
elif [ -f "$out/Scibilia_CV.pdf" ]; then
  mv "$out/Scibilia_CV.pdf" "$out/$name"
  echo "name-pdf: $out/$name (application copy)"
fi

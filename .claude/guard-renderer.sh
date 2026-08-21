#!/usr/bin/env bash
#
# Refuse to run `quarto render` while a Quarto *preview* is already serving.
#
# Why this exists
# ---------------
# RStudio's Render button does not just render — it launches `quarto preview`,
# which keeps its own copy of the site in memory and serves that. If something
# else writes _site underneath it, the preview never notices: the source is
# correct, the browser shows the old page, and the edit appears to vanish.
#
# That is the bug that cost most of the first build session. It only happens
# when two things render at once, so the rule is simply: one renderer at a time.
# Stefano works in RStudio; Claude works from the command line. This guard makes
# the collision impossible rather than something either of us has to remember.
#
# Wired up as a PreToolUse hook on Bash in .claude/settings.json.
# Exit 0 = allow the command. Exit 2 = block it and show stderr to Claude.

set -uo pipefail

# The hook receives the tool call as JSON on stdin. Anything that is not an
# attempt to render is none of this script's business.
payload=$(cat 2>/dev/null || true)
cmd=$(printf '%s' "$payload" | jq -r '.tool_input.command // ""' 2>/dev/null || true)

case "$cmd" in
  *"quarto render"*|*"quarto publish"*) ;;
  *) exit 0 ;;
esac

# A Quarto preview always serves over TCP, and always from Quarto's bundled deno
# binary. The static preview server (.claude/serve.py) is Python, so it cannot be
# mistaken for one — checking the listener rather than the command line also
# avoids matching a shell that merely *mentions* "quarto preview" in its text.
serving=$(lsof -nP -iTCP -sTCP:LISTEN 2>/dev/null \
          | awk '$1 ~ /^(deno|quarto)$/ {print "  " $1 "  pid " $2 "  " $9}')

if [ -n "$serving" ]; then
  cat >&2 <<EOF
BLOCKED — a Quarto preview is already serving the site:

$serving

Rendering now would overwrite _site underneath it. The preview would keep
showing the old pages, and the change would look like it had vanished.

Ask Stefano to stop it first: in RStudio, the red square in the Render /
Background Jobs pane. Then this will run normally.
EOF
  exit 2
fi

exit 0

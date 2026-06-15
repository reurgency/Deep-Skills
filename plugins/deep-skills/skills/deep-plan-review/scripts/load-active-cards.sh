#!/usr/bin/env bash
# load-active-cards.sh — print the active Deep-Learn directive cards for a phase.
#
# Self-locating: it finds the shared directives registry RELATIVE TO ITS OWN
# location, so it works no matter where the plugin is installed and no matter
# what the caller's working directory is. (Bash always knows its own path.)
#
# This file is copied byte-identically into each deep-* skill's scripts/ dir
# (the "standalone rule" — skills self-contain; only the shared registry is shared).
#
# Usage:  load-active-cards.sh <phase>     e.g. load-active-cards.sh deep-plan
set -euo pipefail

phase="${1:-}"
if [ -z "$phase" ]; then
  echo "usage: load-active-cards.sh <phase>   (e.g. deep-plan)" >&2
  exit 2
fi

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# skills/<name>/scripts/ -> up 3 -> plugin root -> directives/cards/active
active="$here/../../../directives/cards/active"

if [ ! -d "$active" ]; then
  echo "[deep-learn] registry not found at $active — proceeding with no cards." >&2
  exit 0
fi

found=0
for card in "$active"/*.md; do
  [ -e "$card" ] || continue
  # pull the bracketed list out of the `owner_phases: [a, b, c]` frontmatter line
  phases_line="$(awk -F'[][]' '/^owner_phases:/{print $2; exit}' "$card")"
  # exact-token match so `deep-plan` does NOT match `deep-plan-review`
  match=0
  IFS=',' read -ra toks <<< "$phases_line"
  for t in "${toks[@]}"; do
    tok="$(printf '%s' "$t" | tr -d '[:space:]')"
    [ "$tok" = "$phase" ] && match=1
  done
  if [ "$match" = "1" ]; then
    echo "===== BEGIN DIRECTIVE CARD: $(basename "$card") ====="
    cat "$card"
    echo "===== END DIRECTIVE CARD: $(basename "$card") ====="
    echo
    found=1
  fi
done

[ "$found" = "0" ] && echo "[deep-learn] no active directive cards for phase: $phase"
exit 0

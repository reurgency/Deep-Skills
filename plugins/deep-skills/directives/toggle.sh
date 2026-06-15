#!/usr/bin/env bash
# toggle.sh — turn a Deep-Learn directive card on (active) or off (disabled).
#
# This is the one-command on/off switch. It moves the card file between
# cards/active/ and cards/disabled/ AND updates its `status:` field so the
# directory and the field never disagree.
#
# Usage:
#   ./toggle.sh DLC-001 off     # stop applying it (move to disabled/)
#   ./toggle.sh DLC-001 on      # apply it again  (move to active/)
#   ./toggle.sh                 # list every card and its current state
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cards="$here/cards"

# no args -> list current state
if [ "$#" -eq 0 ]; then
  for state in active shadow candidate disabled; do
    for c in "$cards/$state"/*.md; do
      [ -e "$c" ] || continue
      printf '%-10s %s\n' "$state" "$(basename "$c" .md)"
    done
  done
  exit 0
fi

id="${1:-}"
action="${2:-}"
if [ -z "$id" ] || { [ "$action" != "on" ] && [ "$action" != "off" ]; }; then
  echo "usage: toggle.sh <CARD-ID> <on|off>   e.g. toggle.sh DLC-001 off" >&2
  echo "       toggle.sh                       (list all cards)" >&2
  exit 2
fi

if [ "$action" = "off" ]; then
  src="$cards/active/$id.md";   dst="$cards/disabled/$id.md"; newstatus="disabled"
else
  src="$cards/disabled/$id.md"; dst="$cards/active/$id.md";   newstatus="active"
fi

if [ ! -f "$src" ]; then
  echo "card not found: $src" >&2
  echo "(is $id already '$action'? run ./toggle.sh with no args to list states.)" >&2
  exit 1
fi

# move — prefer git mv for clean history, but only if the file is actually
# tracked (a brand-new, uncommitted card isn't); otherwise plain mv.
if git -C "$here" ls-files --error-unmatch "$src" >/dev/null 2>&1; then
  git -C "$here" mv "$src" "$dst"
else
  mv "$src" "$dst"
fi

# keep the status: field in sync with the directory (portable BSD/GNU sed)
sed -i.bak -E "s/^status:[[:space:]].*/status: $newstatus/" "$dst" && rm -f "$dst.bak"

echo "$id -> $newstatus"
echo "  $dst"

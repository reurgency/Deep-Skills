#!/usr/bin/env bash
# check-shared.sh - maintainers only; NOT shipped (no plugin manifest references it).
#
# Enforces the series-shared-file rule: every shared reference/script is
# byte-identical across the six deep-skills skills and deep-goal (7 copies),
# validates the model map (shipped + optional repo override), and finds stale
# model/tier wording left in docs.
#
# Usage: scripts/check-shared.sh [--shared | --sync | --stale | --all]
#   --shared  (default) compare every expected copy with the canonical copy
#             (deep-code-review's); missing or differing copy -> FAIL. Never fixes.
#             Also validates model-map.json (canonical + .deep-skills/model-map.json).
#   --sync    copy canonical over every expected copy (creating missing ones),
#             then run --shared.
#   --stale   grep the repo for stale tier words / model ids (see STALE_PATTERNS).
#   --all     --shared + --stale.
# Exit 0 only if every requested check passes.

set -u

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT" || exit 2

CANON_DIR="plugins/deep-skills/skills/deep-code-review"
SKILL_DIRS=(
  plugins/deep-skills/skills/deep-bugfix
  plugins/deep-skills/skills/deep-code-review
  plugins/deep-skills/skills/deep-docs
  plugins/deep-skills/skills/deep-implement
  plugins/deep-skills/skills/deep-plan
  plugins/deep-skills/skills/deep-plan-review
  plugins/deep-goal/skills/deep-goal
)
SHARED_FILES=(
  references/model-map.json
  references/model-map.md
  references/host-affordances.md
  references/artifact-structure.md
  scripts/load-active-cards.sh
)
OVERRIDE=".deep-skills/model-map.json"

FAILS=0
pass() { printf 'PASS  %s\n' "$*"; }
fail() { printf 'FAIL  %s\n' "$*"; FAILS=$((FAILS + 1)); }

# ---------------------------------------------------------------- --shared
check_shared() {
  local f d canon copy
  for f in "${SHARED_FILES[@]}"; do
    canon="$CANON_DIR/$f"
    if [[ ! -f "$canon" ]]; then
      fail "canonical missing: $canon"
      continue
    fi
    local ok=1
    for d in "${SKILL_DIRS[@]}"; do
      copy="$d/$f"
      [[ "$copy" == "$canon" ]] && continue
      if [[ ! -f "$copy" ]]; then
        fail "missing copy: $copy"
        ok=0
      elif ! cmp -s "$canon" "$copy"; then
        fail "differs from canonical: $copy"
        diff -u "$canon" "$copy"
        ok=0
      fi
    done
    [[ $ok -eq 1 ]] && pass "$f - ${#SKILL_DIRS[@]} copies identical"
  done
  validate_model_map
}

# ---------------------------------------------------------------- model-map validation
validate_model_map() {
  local canon="$CANON_DIR/references/model-map.json"
  [[ -f "$canon" ]] || return 0   # already reported as missing
  if ! command -v python3 >/dev/null 2>&1; then
    fail "python3 not found - cannot validate model-map.json"
    return
  fi
  local out rc
  out="$(python3 -I - "$canon" "$OVERRIDE" <<'PY'
import json, re, sys, os

canon_path, override_path = sys.argv[1], sys.argv[2]
TIERS = ["smartest", "smarter", "smart"]          # strongest first
RANK = {t: i for i, t in enumerate(TIERS)}        # lower = stronger
STAGES = ["plan", "plan-review", "implement", "code-review", "bugfix", "docs"]
TOP = {"map_version", "ladder", "stages"}
SMALL = re.compile(r"(?i)haiku|(?<![a-z])(mini|nano)(?![a-z])")
errors = []

def err(path, key, msg):
    errors.append(f"{path}: key '{key}': {msg}")

def load(path):
    try:
        with open(path, encoding="utf-8") as fh:
            return json.load(fh)
    except (OSError, ValueError) as e:
        errors.append(f"{path}: does not parse as JSON ({e})")
        return None

def real(d):
    return {k: v for k, v in d.items() if not k.startswith("_")} if isinstance(d, dict) else d

def check(doc, path, utility, complete):
    if not isinstance(doc, dict):
        errors.append(f"{path}: top level must be a JSON object")
        return
    for k in real(doc):
        if k not in TOP:
            err(path, k, "unknown key (per-agent fleet tables are not overridable); valid: " + ", ".join(sorted(TOP)))
    if complete and doc.get("map_version") != 2:
        err(path, "map_version", "must be 2")
    if complete and not isinstance(doc.get("_shared"), str):
        err(path, "_shared", "series-shared header missing")
    ladder = real(doc.get("ladder", {}))
    if not isinstance(ladder, dict):
        err(path, "ladder", "must be an object")
        ladder = {}
    for tier, fams in ladder.items():
        if tier not in RANK:
            err(path, f"ladder.{tier}", "unknown tier; valid: " + ", ".join(TIERS))
            continue
        fams = real(fams)
        if not isinstance(fams, dict):
            err(path, f"ladder.{tier}", "must be an object of family -> list of model ids")
            continue
        for fam, ids in fams.items():
            key = f"ladder.{tier}.{fam}"
            if not isinstance(ids, list) or not ids:
                err(path, key, "must be a non-empty list of model ids (current first, then previous)")
                continue
            for mid in ids:
                if not isinstance(mid, str) or not mid.strip():
                    err(path, key, "model ids must be non-empty strings")
                elif SMALL.search(mid) or mid in utility:
                    err(path, key, f"'{mid}' is a small/utility model - never allowed on the ladder")
    if complete:
        for tier in TIERS:
            fams = real(ladder.get(tier, {})) or {}
            for fam in ("claude", "gpt"):
                if fam not in fams:
                    err(path, f"ladder.{tier}.{fam}", "missing in canonical map")
    stages = real(doc.get("stages", {}))
    if not isinstance(stages, dict):
        err(path, "stages", "must be an object")
        stages = {}
    for mx, row in stages.items():
        if mx not in RANK:
            err(path, f"stages.{mx}", "unknown max level; valid: " + ", ".join(TIERS))
            continue
        row = real(row)
        if not isinstance(row, dict):
            err(path, f"stages.{mx}", "must be an object of stage -> tier")
            continue
        for st, t in row.items():
            key = f"stages.{mx}.{st}"
            if st not in STAGES:
                err(path, key, "unknown stage; valid: " + ", ".join(STAGES))
            elif t not in RANK:
                err(path, key, f"'{t}' is not a tier; valid: " + ", ".join(TIERS))
            elif RANK[t] < RANK[mx]:
                err(path, key, f"'{t}' exceeds its max '{mx}'; valid: " + ", ".join(TIERS[RANK[mx]:]))
        if complete:
            for st in STAGES:
                if st not in row:
                    err(path, f"stages.{mx}.{st}", "missing in canonical map")
    if complete:
        for mx in TIERS:
            if mx not in stages:
                err(path, f"stages.{mx}", "missing in canonical map")

def unique_ids(ladder, path):
    seen = {}
    for tier, fams in real(ladder).items():
        if tier not in RANK or not isinstance(real(fams), dict):
            continue
        for fam, ids in real(fams).items():
            for mid in ids if isinstance(ids, list) else []:
                if isinstance(mid, str):
                    k = mid.strip().lower()
                    if k in seen and seen[k] != tier:
                        err(path, f"ladder.{tier}.{fam}", f"'{mid}' is also listed under '{seen[k]}' - an id may appear in only one tier")
                    seen.setdefault(k, tier)

canon = load(canon_path)
utility = set()
if isinstance(canon, dict):
    u = real(canon.get("_utility_unused", {}))
    utility = set(u.values()) if isinstance(u, dict) else set()
    check(canon, canon_path, utility, complete=True)
    unique_ids(canon.get("ladder", {}), canon_path)
checked = [canon_path]

if os.path.exists(override_path):
    ov = load(override_path)
    if ov is not None:
        check(ov, override_path, utility, complete=False)
        if isinstance(canon, dict) and isinstance(ov, dict) and not errors:
            merged = json.loads(json.dumps(real(canon.get("ladder", {}))))
            for tier, fams in real(ov.get("ladder", {})).items():
                for fam, ids in real(fams).items():
                    merged.setdefault(tier, {})[fam] = ids
            unique_ids(merged, override_path + " (merged with shipped ladder)")
    checked.append(override_path)

for e in errors:
    print(e)
print("checked: " + ", ".join(checked))
sys.exit(1 if errors else 0)
PY
)"
  rc=$?
  if [[ $rc -eq 0 ]]; then
    pass "model-map.json valid (${out#checked: })"
  else
    while IFS= read -r line; do
      [[ "$line" == checked:* ]] && continue
      fail "model-map: $line"
    done <<<"$out"
  fi
}

# ---------------------------------------------------------------- --sync
do_sync() {
  local f d canon copy
  for f in "${SHARED_FILES[@]}"; do
    canon="$CANON_DIR/$f"
    if [[ ! -f "$canon" ]]; then
      fail "canonical missing, cannot sync: $canon"
      continue
    fi
    for d in "${SKILL_DIRS[@]}"; do
      copy="$d/$f"
      [[ "$copy" == "$canon" ]] && continue
      if [[ ! -f "$copy" ]] || ! cmp -s "$canon" "$copy"; then
        mkdir -p "$(dirname "$copy")"
        cp -p "$canon" "$copy" && printf 'SYNC  %s\n' "$copy"
      fi
    done
  done
}

# ---------------------------------------------------------------- --stale
STALE_PATTERNS=(
  '\b(main|mid|cheap)[ -]tier'
  'tier `?(main|mid|cheap)'
  'Sonnet[ -]4[.-]6'
  'sonnet-4-6'
  '[Oo]pus[ -]4[.-]8'
  'GPT-5\.[45]\b'
  '"tier-[012]"'
  'tier-[012]:'
  'templates/model-map\.json'
  '--mix\b'
  'ignores the (session|model you)'
)
TIER_WORD_PATTERNS='"tier-[012]"|tier-[012]:'

check_stale() {
  local combined p
  combined="$(IFS='|'; echo "${STALE_PATTERNS[*]}")"
  # Non-tier patterns, for the deep-docs documentation-tier allowlist.
  local non_tier=""
  for p in "${STALE_PATTERNS[@]}"; do
    case "$p" in *tier-*) ;; *) non_tier="${non_tier:+$non_tier|}$p" ;; esac
  done
  # Previous-generation ladder ids (allowlisted), read from the canonical JSON.
  local prev_re=""
  if command -v python3 >/dev/null 2>&1 && [[ -f "$CANON_DIR/references/model-map.json" ]]; then
    prev_re="$(python3 -I - "$CANON_DIR/references/model-map.json" <<'PY'
import json, re, sys
d = json.load(open(sys.argv[1], encoding="utf-8"))
ids = set()
for tier, fams in d.get("ladder", {}).items():
    if tier.startswith("_") or not isinstance(fams, dict):
        continue
    for fam, lst in fams.items():
        if not fam.startswith("_") and isinstance(lst, list):
            ids.update(lst[1:])
# ERE-escape; require the id not to continue with -digit / .digit (so a current id
# like claude-fable-5-2 does not count as its previous-generation prefix).
esc = lambda s: re.sub(r'([.^$*+?()\[\]{}|\\])', r'\\\1', s)
print("|".join("(" + esc(i) + ")([^-.0-9]|$)" for i in sorted(ids)))
PY
)" || prev_re=""
  fi

  local hits=0 bad=0 path rest lineno text
  while IFS= read -r hit; do
    path="${hit%%:*}"; rest="${hit#*:}"; lineno="${rest%%:*}"; text="${rest#*:}"
    case "$path" in
      ./docs/benchmarks/*|./docs/ai-map/*|./docs/Retrospectives/*|./docs/Skill-Review/*|./docs/roadmap/*|./.deep-skills/*|./.git/*|./scripts/check-shared.sh) continue ;;
    esac
    hits=$((hits + 1))
    # Allowlist: the alias story.
    if printf '%s\n' "$text" | grep -qE 'alias'; then continue; fi
    # Allowlist: previous-generation ladder column.
    if [[ -n "$prev_re" ]] && printf '%s\n' "$text" | grep -qE "$prev_re"; then continue; fi
    # Allowlist: deep-docs documentation tiers (tier-0/1/2 only, no other stale hit).
    case "$path" in
      *deep-docs*|./docs/Training/*deep-docs*|./docs/Training/html/roadmap.html|./docs/Training/README.md)
        if printf '%s\n' "$text" | grep -qE "$TIER_WORD_PATTERNS" \
           && ! printf '%s\n' "$text" | grep -qE -- "$non_tier"; then
          continue
        fi ;;
    esac
    bad=$((bad + 1))
    printf '%s:%s: %s\n' "${path#./}" "$lineno" "$text"
  done < <(grep -rnIE --exclude-dir=.git --exclude-dir=node_modules -- "$combined" . 2>/dev/null)

  if [[ $bad -eq 0 ]]; then
    pass "stale scan - no stale tier words or model ids ($hits allowlisted hit(s) ignored)"
  else
    fail "stale scan - $bad stale hit(s) above"
  fi
}

# ---------------------------------------------------------------- main
mode="${1:---shared}"
case "$mode" in
  --shared) check_shared ;;
  --sync)   do_sync; check_shared ;;
  --stale)  check_stale ;;
  --all)    check_shared; check_stale ;;
  -h|--help) sed -n '2,17p' "$0"; exit 0 ;;
  *) echo "unknown mode: $mode (use --shared | --sync | --stale | --all)" >&2; exit 2 ;;
esac

if [[ $FAILS -eq 0 ]]; then
  echo "RESULT: PASS"
  exit 0
fi
echo "RESULT: FAIL ($FAILS failure(s))"
exit 1

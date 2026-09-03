#!/usr/bin/env bash
# cAIrn CI check — fail if code changed without updating AI_HANDOFF.md.
# Reads newline-separated changed paths from args or stdin. Mirrors the
# classification in .githooks/pre-commit so local and CI verdicts agree.
set -euo pipefail

LEDGER="AI_HANDOFF.md"
files="$*"
[ -z "$files" ] && files="$(cat || true)"
if [ -z "$files" ]; then echo "cairn: no changed files — pass."; exit 0; fi

# CI runs against the PR's checked-out index. A changed-path list can include
# AI_HANDOFF.md even when the PR deletes or replaces it, so verify the actual
# tree object rather than treating its name as evidence that the ledger exists.
ledger_mode="$(git ls-files -s -- "$LEDGER" | awk 'NR == 1 { print $1; exit }')"
case "$ledger_mode" in
  100644|100755) ;;
  *)
  echo "::error::cairn: AI_HANDOFF.md must remain a regular tracked file." >&2
  echo "Restore the append-only ledger before merging this PR." >&2
  exit 1
  ;;
esac

ledger=0; code=0
while IFS= read -r f; do
  [ -z "$f" ] && continue
  case "$f" in
    "$LEDGER")                    ledger=1 ;;
    *.md|*.markdown|*.txt|*.rst)  : ;;            # docs are exempt
    *)                            code=1 ;;
  esac
done <<< "$files"

if [ "$code" -eq 1 ] || [ "$ledger" -eq 1 ]; then
  if ! git show ":$LEDGER" | awk '
    /^## Active Work[[:space:]]*$/ { active++ }
    /^## Log/ { log_section++ }
    END { exit !(active >= 1 && log_section >= 1) }'; then
    echo "::error::cairn: AI_HANDOFF.md is missing its required Active Work or Log section." >&2
    echo "Restore the append-only ledger structure before merging code." >&2
    exit 1
  fi
fi

if [ "$code" -eq 1 ] && [ "$ledger" -eq 0 ]; then
  echo "::error::cairn: code changed but AI_HANDOFF.md was not updated in this PR." >&2
  echo "Add a Log entry to AI_HANDOFF.md. Docs-only changes already pass without a bypass." >&2
  exit 1
fi
echo "cairn: ledger check passed."

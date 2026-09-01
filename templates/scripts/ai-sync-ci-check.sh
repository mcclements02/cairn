#!/usr/bin/env bash
# AI-SYNC CI check — fail if code changed without updating AI_HANDOFF.md.
# Reads newline-separated changed paths from args or stdin. Mirrors the
# classification in .githooks/pre-commit so local and CI verdicts agree.
set -euo pipefail

LEDGER="AI_HANDOFF.md"
files="$*"
[ -z "$files" ] && files="$(cat || true)"
if [ -z "$files" ]; then echo "ai-sync: no changed files — pass."; exit 0; fi

ledger=0; code=0
while IFS= read -r f; do
  [ -z "$f" ] && continue
  case "$f" in
    "$LEDGER")                    ledger=1 ;;
    *.md|*.markdown|*.txt|*.rst)  : ;;            # docs are exempt
    *)                            code=1 ;;
  esac
done <<< "$files"

if [ "$code" -eq 1 ] && [ "$ledger" -eq 0 ]; then
  echo "::error::ai-sync: code changed but AI_HANDOFF.md was not updated in this PR." >&2
  echo "Add a Log entry to AI_HANDOFF.md, or apply the 'skip-ledger' label for a docs-only PR." >&2
  exit 1
fi
echo "ai-sync: ledger check passed."

#!/usr/bin/env bash
# cairn-hooks —  enable the versioned pre-commit hook for this clone.
# Run once per clone. core.hooksPath is shared by all linked worktrees.
set -euo pipefail

ROOT="$(git rev-parse --show-toplevel)"
cd "$ROOT"

existing="$(git config --get core.hooksPath || true)"
if [ -n "$existing" ] && [ "$existing" != ".githooks" ]; then
  echo "WARN: core.hooksPath is already '$existing' (e.g. husky)."
  echo "      Not overriding automatically. To chain, call .githooks/pre-commit"
  echo "      from your existing hook, or force with:  CAIRN_FORCE=1 $0"
  [ "${CAIRN_FORCE:-${AISYNC_FORCE:-0}}" = "1" ] || exit 0
fi

if [ -L .githooks ] || [ ! -d .githooks ]; then
  echo "WARN: .githooks is missing or not a real directory; run 'cairn init' before enabling hooks."
  exit 0
fi

if [ ! -f .githooks/pre-commit ] || [ -L .githooks/pre-commit ]; then
  echo "WARN: .githooks/pre-commit is missing; run 'cairn init' before enabling hooks."
  exit 0
fi

is_cairn_hook() {
  awk '
    { line=$0; sub(/\r$/, "", line) }
    line == "# CAIRN-HOOK:BEGIN" {
      begins++
      if (NR != 5 || begins > 1) invalid=1
    }
    line == "# CAIRN-HOOK:END" {
      ends++
      if (ends > 1) invalid=1
      end_line=NR
    }
    END { exit !(begins == 1 && ends == 1 && end_line == NR && !invalid) }' .githooks/pre-commit
}

if ! is_cairn_hook; then
  echo "WARN: .githooks/pre-commit is an existing user hook; cAIrn preserved it."
  echo "      Local ledger enforcement is not enabled automatically. Chain cAIrn's"
  echo "      hook deliberately, or run 'cairn init --force' to replace it."
  exit 0
fi

chmod +x .githooks/* __SCRIPTS_DIR__/cairn-*.sh 2>/dev/null || true
git config core.hooksPath .githooks

echo "cAIrn installed for $(basename "$ROOT"):"
echo "  core.hooksPath = $(git config --get core.hooksPath)"
echo "  hook           = .githooks/pre-commit"
echo "Applies to all linked worktrees. Re-run in each fresh clone."

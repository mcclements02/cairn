#!/usr/bin/env bash
# AI-SYNC install — enable the versioned pre-commit hook for this clone.
# Run once per clone. core.hooksPath is shared by all linked worktrees.
set -euo pipefail

ROOT="$(git rev-parse --show-toplevel)"
cd "$ROOT"

existing="$(git config --get core.hooksPath || true)"
if [ -n "$existing" ] && [ "$existing" != ".githooks" ]; then
  echo "WARN: core.hooksPath is already '$existing' (e.g. husky)."
  echo "      Not overriding automatically. To chain, call .githooks/pre-commit"
  echo "      from your existing hook, or force with:  AISYNC_FORCE=1 $0"
  [ "${AISYNC_FORCE:-0}" = "1" ] || exit 0
fi

chmod +x .githooks/* __SCRIPTS_DIR__/ai-sync-*.sh 2>/dev/null || true
git config core.hooksPath .githooks

echo "AI-SYNC installed for $(basename "$ROOT"):"
echo "  core.hooksPath = $(git config --get core.hooksPath)"
echo "  hook           = .githooks/pre-commit"
echo "Applies to all linked worktrees. Re-run in each fresh clone."

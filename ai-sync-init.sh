#!/usr/bin/env bash
# ai-sync-init — install (or re-sync) the AI-SYNC cross-agent protocol in a repo.
#
# Idempotent. Managed files are rewritten from templates/ every run, so a repo
# that has drifted comes back to canonical. Content files (AGENTS.md,
# AI_HANDOFF.md) are seeded once and never clobbered — in an existing AGENTS.md
# only the marked ledger block is replaced.
#
#   ai-sync-init.sh [--check] [--force] [--scripts-dir DIR] [TARGET_REPO]
#
#   --check            report drift and exit non-zero; write nothing
#   --force            re-seed AGENTS.md / AI_HANDOFF.md from templates (destructive)
#   --scripts-dir DIR  override script-dir detection (default: scripts/, or an
#                      existing Scripts/ — Xcode-style repos keep their casing)
set -euo pipefail

SELF="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATES="$SELF/templates"

CHECK=0; FORCE=0; SCRIPTS_DIR=""; TARGET=""
while [ $# -gt 0 ]; do
  case "$1" in
    --check)       CHECK=1; shift ;;
    --force)       FORCE=1; shift ;;
    --scripts-dir) SCRIPTS_DIR="${2:?--scripts-dir needs a value}"; shift 2 ;;
    -h|--help)     sed -n '2,14p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    -*)            echo "unknown flag: $1" >&2; exit 2 ;;
    *)             TARGET="$1"; shift ;;
  esac
done

[ -d "$TEMPLATES" ] || { echo "x  templates/ not found next to $0" >&2; exit 1; }

cd "${TARGET:-.}"
ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || {
  echo "x  not a git repository: $(pwd)" >&2; exit 1; }
cd "$ROOT"

# --- context -----------------------------------------------------------------
PROJECT_NAME="$(basename "$ROOT")"
if [ -z "$SCRIPTS_DIR" ]; then
  # A case-insensitive filesystem makes scripts/ and Scripts/ the same inode,
  # so `[ -d Scripts ]` is true even when the real dirent is `scripts`. Ask git
  # what casing it tracks, then fall back to find, which string-compares the
  # actual dirent name. Never test with `-d`.
  SCRIPTS_DIR="$(git ls-files | sed -n 's|^\([Ss]cripts\)/.*|\1|p' | head -1)"
  if [ -z "$SCRIPTS_DIR" ]; then
    SCRIPTS_DIR="$(find . -maxdepth 1 -type d \( -name scripts -o -name Scripts \) \
                   -exec basename {} \; 2>/dev/null | head -1)"
  fi
  [ -z "$SCRIPTS_DIR" ] && SCRIPTS_DIR="scripts"
fi
BRANCH="$(git branch --show-current 2>/dev/null)"; [ -z "$BRANCH" ] && BRANCH="main"
DATE="$(date +%Y-%m-%d)"

render() { # render <template> -> stdout
  sed -e "s|__SCRIPTS_DIR__|$SCRIPTS_DIR|g" \
      -e "s|__PROJECT_NAME__|$PROJECT_NAME|g" \
      -e "s|__BRANCH__|$BRANCH|g" \
      -e "s|__DATE__|$DATE|g" "$1"
}

CREATED=(); UPDATED=(); SKIPPED=(); DRIFT=()

sync_file() { # sync_file <template> <dest> [executable]
  local tpl="$1" dest="$2" exec_bit="${3:-}" tmp
  tmp="$(mktemp)"; render "$tpl" > "$tmp"
  if [ ! -f "$dest" ]; then
    if [ "$CHECK" = "1" ]; then DRIFT+=("$dest (missing)"); rm -f "$tmp"; return; fi
    mkdir -p "$(dirname "$dest")"; mv "$tmp" "$dest"
    [ -n "$exec_bit" ] && chmod +x "$dest"; CREATED+=("$dest"); return
  fi
  if cmp -s "$tmp" "$dest"; then rm -f "$tmp"; return; fi
  if [ "$CHECK" = "1" ]; then DRIFT+=("$dest (differs)"); rm -f "$tmp"; return; fi
  mv "$tmp" "$dest"; [ -n "$exec_bit" ] && chmod +x "$dest"; UPDATED+=("$dest")
}

seed_file() { # seed_file <template> <dest> — content files: seed once
  local tpl="$1" dest="$2"
  if [ -f "$dest" ] && [ "$FORCE" != "1" ]; then SKIPPED+=("$dest (exists)"); return; fi
  if [ "$CHECK" = "1" ]; then [ -f "$dest" ] || DRIFT+=("$dest (missing)"); return; fi
  render "$tpl" > "$dest"
  CREATED+=("$dest")
}

# --- managed files (always canonical) ----------------------------------------
sync_file "$TEMPLATES/githooks/pre-commit"           ".githooks/pre-commit"            x
sync_file "$TEMPLATES/scripts/ai-sync-install.sh"    "$SCRIPTS_DIR/ai-sync-install.sh" x
sync_file "$TEMPLATES/scripts/ai-sync-status.sh"     "$SCRIPTS_DIR/ai-sync-status.sh"  x
sync_file "$TEMPLATES/scripts/ai-sync-ci-check.sh"   "$SCRIPTS_DIR/ai-sync-ci-check.sh" x
sync_file "$TEMPLATES/workflows/ai-sync.yml"         ".github/workflows/ai-sync.yml"
sync_file "$TEMPLATES/AI_WORKSPACE.md"               "AI_WORKSPACE.md"
sync_file "$TEMPLATES/CLAUDE.md"                     "CLAUDE.md"
sync_file "$TEMPLATES/GEMINI.md"                     "GEMINI.md"
sync_file "$TEMPLATES/CHATGPT.md"                    "CHATGPT.md"

# --- content files (seeded once) ---------------------------------------------
seed_file "$TEMPLATES/AI_HANDOFF.md" "AI_HANDOFF.md"

# AGENTS.md: full skeleton when absent; otherwise only the marked block is
# replaced, so hand-written architecture and command sections survive a re-sync.
BEGIN_MARK="<!-- AI-SYNC-LEDGER:BEGIN"
END_MARK="<!-- AI-SYNC-LEDGER:END -->"
if [ ! -f AGENTS.md ]; then
  seed_file "$TEMPLATES/AGENTS.skeleton.md" "AGENTS.md"
else
  block="$(mktemp)"; render "$TEMPLATES/AGENTS.ledger-block.md" > "$block"
  if grep -qF "$BEGIN_MARK" AGENTS.md; then
    current="$(mktemp)"
    awk -v b="$BEGIN_MARK" -v e="$END_MARK" \
        'index($0,b){f=1} f{print} index($0,e){f=0}' AGENTS.md > "$current"
    if cmp -s "$block" "$current"; then :
    elif [ "$CHECK" = "1" ]; then DRIFT+=("AGENTS.md (ledger block differs)")
    else
      out="$(mktemp)"
      awk -v b="$BEGIN_MARK" -v e="$END_MARK" -v repl="$block" '
        index($0,b){ while ((getline l < repl) > 0) print l; close(repl); f=1; next }
        f && index($0,e){ f=0; next }
        !f { print }' AGENTS.md > "$out"
      mv "$out" AGENTS.md; UPDATED+=("AGENTS.md (ledger block)")
    fi
    rm -f "$current"
  elif [ "$CHECK" = "1" ]; then DRIFT+=("AGENTS.md (no ledger block)")
  else
    printf '\n' >> AGENTS.md; cat "$block" >> AGENTS.md
    UPDATED+=("AGENTS.md (ledger block appended)")
  fi
  rm -f "$block"
fi

# --- report ------------------------------------------------------------------
echo "== ai-sync-init: $PROJECT_NAME =="
echo "   root        $ROOT"
echo "   branch      $BRANCH"
echo "   scripts dir $SCRIPTS_DIR/"
echo

if [ "$CHECK" = "1" ]; then
  if [ ${#DRIFT[@]} -eq 0 ]; then echo "   in sync — no drift."; exit 0; fi
  echo "   DRIFT (${#DRIFT[@]}):"; printf '     - %s\n' "${DRIFT[@]}"; exit 1
fi

[ ${#CREATED[@]} -gt 0 ] && { echo "   created (${#CREATED[@]}):"; printf '     + %s\n' "${CREATED[@]}"; }
[ ${#UPDATED[@]} -gt 0 ] && { echo "   updated (${#UPDATED[@]}):"; printf '     ~ %s\n' "${UPDATED[@]}"; }
[ ${#SKIPPED[@]} -gt 0 ] && { echo "   kept (${#SKIPPED[@]}):";    printf '     = %s\n' "${SKIPPED[@]}"; }
[ $(( ${#CREATED[@]} + ${#UPDATED[@]} )) -eq 0 ] && echo "   already in sync — nothing written."

echo
bash "$SCRIPTS_DIR/ai-sync-install.sh"
echo
echo "Next:"
n=1
# Only nag about TODOs when this run actually seeded the skeleton.
if printf '%s\n' "${CREATED[@]:-}" | grep -qx "AGENTS.md"; then
  echo "  $n. Fill the TODO sections in AGENTS.md (boundary / commands / architecture / validation)."
  n=$((n+1))
fi
echo "  $n. Commit these files together."; n=$((n+1))
echo "  $n. Make \"AI-SYNC ledger check\" a required status check in branch protection."

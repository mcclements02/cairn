#!/usr/bin/env bash
# Lightweight integration coverage for Cairn's installer and generic entry files.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CAIRN="$ROOT/cairn"
TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/cairn-smoke.XXXXXX")"

cleanup() { local status=$?; rm -rf "$TMP_ROOT"; exit "$status"; }
trap cleanup EXIT

fail() { echo "not ok - $*" >&2; exit 1; }
contains() { grep -qF "$2" "$1" || fail "expected '$2' in $1"; }
does_not_contain() {
  if grep -qF "$2" "$1"; then fail "did not expect '$2' in $1"; fi
}

new_repo() {
  local repo="$1"
  mkdir -p "$repo"
  git init -q "$repo"
  git -C "$repo" config user.email cairn-test@example.invalid
  git -C "$repo" config user.name Cairn-Test
}

# A path owned by any runtime/model can be registered and stays in sync.
generic_repo="$TMP_ROOT/generic"
new_repo "$generic_repo"
"$CAIRN" init --entry-file .agents/qwen-instructions.md "$generic_repo" >/dev/null
contains "$generic_repo/.cairn/entry-files" ".agents/qwen-instructions.md"
contains "$generic_repo/.agents/qwen-instructions.md" "CAIRN-ENTRY:BEGIN"
contains "$generic_repo/.agents/qwen-instructions.md" "every agent, runtime, model"
contains "$generic_repo/AI_HANDOFF.md" "Actor / runtime / model"
does_not_contain "$generic_repo/AI_HANDOFF.md" "claude · gemini · chatgpt · copilot"
"$CAIRN" check "$generic_repo" >/dev/null
perl -pi -e 's/\n/\r\n/g' "$generic_repo/.cairn/entry-files"
"$CAIRN" init --entry-file .agents/qwen-instructions.md "$generic_repo" >/dev/null
registered_count="$(tr -d '\r' < "$generic_repo/.cairn/entry-files" | grep -Fxc '.agents/qwen-instructions.md')"
[ "$registered_count" = "1" ] || fail "CRLF registry duplicated an entry"
perl -pi -e 's/\n/\r\n/g' "$generic_repo/.agents/qwen-instructions.md"
"$CAIRN" check "$generic_repo" >/dev/null
mv "$generic_repo/.agents/qwen-instructions.md" "$generic_repo/.agents/qwen-instructions.md.saved"
if "$CAIRN" check "$generic_repo" >/dev/null 2>&1; then
  fail "check accepted a missing registered entry file"
fi
mv "$generic_repo/.agents/qwen-instructions.md.saved" "$generic_repo/.agents/qwen-instructions.md"
"$CAIRN" check "$generic_repo" >/dev/null

# A changed managed block is detected, then restored without touching the rest.
chmod 755 "$generic_repo/.agents/qwen-instructions.md"
perl -pi -e 's/## Cairn coordination/## Changed heading/' "$generic_repo/.agents/qwen-instructions.md"
if "$CAIRN" check "$generic_repo" >/dev/null 2>&1; then
  fail "check accepted a changed agent entry block"
fi
"$CAIRN" init "$generic_repo" >/dev/null
contains "$generic_repo/.agents/qwen-instructions.md" "## Cairn coordination"
[ -x "$generic_repo/.agents/qwen-instructions.md" ] || fail "entry-file mode was not preserved"
"$CAIRN" check "$generic_repo" >/dev/null

# Multiple or malformed managed blocks are drift, never silently ignored.
cp "$generic_repo/.agents/qwen-instructions.md" "$TMP_ROOT/entry-copy"
cat "$TMP_ROOT/entry-copy" >> "$generic_repo/.agents/qwen-instructions.md"
if "$CAIRN" check "$generic_repo" >/dev/null 2>&1; then
  fail "check accepted duplicate Cairn entry blocks"
fi
if "$CAIRN" init "$generic_repo" >/dev/null 2>&1; then
  fail "init overwrote duplicate Cairn entry blocks"
fi
cp "$TMP_ROOT/entry-copy" "$generic_repo/.agents/qwen-instructions.md"
"$CAIRN" check "$generic_repo" >/dev/null

# A writable directory can repair a read-only entry while keeping its mode.
readonly_repo="$TMP_ROOT/readonly"
new_repo "$readonly_repo"
"$CAIRN" init --entry-file .agents/local.md "$readonly_repo" >/dev/null
perl -pi -e 's/## Cairn coordination/## Old heading/' "$readonly_repo/.agents/local.md"
chmod 444 "$readonly_repo/.agents/local.md"
"$CAIRN" init "$readonly_repo" >/dev/null
contains "$readonly_repo/.agents/local.md" "## Cairn coordination"
readonly_mode="$(LC_ALL=C ls -ld "$readonly_repo/.agents/local.md" | awk '{print $1}')"
case "$readonly_mode" in -r--r--r--*) ;; *) fail "entry-file read-only mode was not preserved" ;; esac

# Existing agent instructions are never overwritten without explicit adoption.
adopt_repo="$TMP_ROOT/adopt"
new_repo "$adopt_repo"
mkdir -p "$adopt_repo/.agents"
printf '%s\n' 'Keep this local runtime instruction.' > "$adopt_repo/.agents/llama.md"
if "$CAIRN" init --entry-file .agents/llama.md "$adopt_repo" >/dev/null 2>&1; then
  fail "init overwrote an unmarked entry file"
fi
"$CAIRN" init --adopt-entry-file .agents/llama.md "$adopt_repo" >/dev/null
contains "$adopt_repo/.agents/llama.md" "Keep this local runtime instruction."
contains "$adopt_repo/.agents/llama.md" "CAIRN-ENTRY:BEGIN"
"$CAIRN" check "$adopt_repo" >/dev/null

# Adoption uses the same safe replacement path for a read-only existing file.
readonly_adopt_repo="$TMP_ROOT/readonly-adopt"
new_repo "$readonly_adopt_repo"
mkdir -p "$readonly_adopt_repo/.agents"
printf '%s\n' 'Keep this read-only instruction.' > "$readonly_adopt_repo/.agents/local.md"
chmod 444 "$readonly_adopt_repo/.agents/local.md"
"$CAIRN" init --adopt-entry-file .agents/local.md "$readonly_adopt_repo" >/dev/null
contains "$readonly_adopt_repo/.agents/local.md" "Keep this read-only instruction."
contains "$readonly_adopt_repo/.agents/local.md" "CAIRN-ENTRY:BEGIN"
readonly_adopt_mode="$(LC_ALL=C ls -ld "$readonly_adopt_repo/.agents/local.md" | awk '{print $1}')"
case "$readonly_adopt_mode" in -r--r--r--*) ;; *) fail "adopted entry read-only mode was not preserved" ;; esac
"$CAIRN" check "$readonly_adopt_repo" >/dev/null

# Unsafe paths cannot escape the repository.
if "$CAIRN" init --entry-file ../outside.md "$generic_repo" >/dev/null 2>&1; then
  fail "init accepted a parent-directory entry path"
fi

# Invalid entry targets fail before any installation files are written.
invalid_repo="$TMP_ROOT/invalid"
new_repo "$invalid_repo"
mkdir -p "$invalid_repo/.agents"
if "$CAIRN" init --adopt-entry-file .agents "$invalid_repo" >/dev/null 2>&1; then
  fail "init accepted a directory as an entry file"
fi
if [ -e "$invalid_repo/.cairn/entry-files" ] || [ -e "$invalid_repo/AGENTS.md" ]; then
  fail "invalid directory entry left a partial installation"
fi
if "$CAIRN" init --entry-file -qwen.md "$invalid_repo" >/dev/null 2>&1; then
  fail "init accepted an option-like entry path"
fi
if [ -e "$invalid_repo/.cairn/entry-files" ] || [ -e "$invalid_repo/AGENTS.md" ]; then
  fail "invalid option-like entry left a partial installation"
fi
if "$CAIRN" init --entry-file '#qwen.md' "$invalid_repo" >/dev/null 2>&1; then
  fail "init accepted a comment-like entry path"
fi
if [ -e "$invalid_repo/.cairn/entry-files" ] || [ -e "$invalid_repo/AGENTS.md" ]; then
  fail "invalid comment-like entry left a partial installation"
fi
if "$CAIRN" init --entry-file '..\outside.md' "$invalid_repo" >/dev/null 2>&1; then
  fail "init accepted a Windows parent-directory entry path"
fi
if "$CAIRN" init --entry-file 'C:\outside.md' "$invalid_repo" >/dev/null 2>&1; then
  fail "init accepted a Windows drive entry path"
fi
if "$CAIRN" init --entry-file agents.md "$invalid_repo" >/dev/null 2>&1; then
  fail "init accepted a case-insensitive collision with AGENTS.md"
fi
if [ -e "$invalid_repo/.cairn/entry-files" ] || [ -e "$invalid_repo/AGENTS.md" ]; then
  fail "invalid Windows path left a partial installation"
fi
if "$CAIRN" init --entry-file AgentConfig.md --entry-file agentconfig.md "$invalid_repo" >/dev/null 2>&1; then
  fail "init accepted a case-insensitive duplicate entry path"
fi
if [ -e "$invalid_repo/.cairn/entry-files" ] || [ -e "$invalid_repo/AGENTS.md" ]; then
  fail "case-insensitive duplicate left a partial installation"
fi

# A repository's unrelated .cairn file is left alone until entry-file support
# is explicitly requested.
incidental_cairn_repo="$TMP_ROOT/incidental-cairn"
new_repo "$incidental_cairn_repo"
touch "$incidental_cairn_repo/.cairn"
"$CAIRN" init "$incidental_cairn_repo" >/dev/null
"$CAIRN" check "$incidental_cairn_repo" >/dev/null

non_directory_parent_repo="$TMP_ROOT/non-directory-parent"
new_repo "$non_directory_parent_repo"
touch "$non_directory_parent_repo/.agents"
if "$CAIRN" init --entry-file .agents/qwen.md "$non_directory_parent_repo" >/dev/null 2>&1; then
  fail "init accepted a non-directory entry-file parent"
fi
if [ -e "$non_directory_parent_repo/.cairn/entry-files" ] || [ -e "$non_directory_parent_repo/AGENTS.md" ]; then
  fail "non-directory entry parent left a partial installation"
fi

# The registry cannot escape through a symlinked .cairn component or file.
symlink_repo="$TMP_ROOT/registry-symlink"
new_repo "$symlink_repo"
mkdir -p "$symlink_repo/.cairn"
ln -s "$TMP_ROOT/registry-outside" "$symlink_repo/.cairn/entry-files"
if "$CAIRN" init --entry-file .agents/qwen.md "$symlink_repo" >/dev/null 2>&1; then
  fail "init accepted a symlinked entry-file registry"
fi
if [ -e "$TMP_ROOT/registry-outside" ] || [ -e "$symlink_repo/AGENTS.md" ]; then
  fail "symlinked registry caused an external or partial write"
fi

# Markers embedded in surrounding text are refused before replacement can erase it.
malformed_repo="$TMP_ROOT/malformed"
new_repo "$malformed_repo"
mkdir -p "$malformed_repo/.agents"
printf '%s\n' 'before' 'prefix <!-- CAIRN-ENTRY:BEGIN -->' 'old block' '<!-- CAIRN-ENTRY:END --> suffix' 'after-must-survive' > "$malformed_repo/.agents/bad.md"
if "$CAIRN" init --adopt-entry-file .agents/bad.md "$malformed_repo" >/dev/null 2>&1; then
  fail "init accepted embedded Cairn markers"
fi
contains "$malformed_repo/.agents/bad.md" "after-must-survive"
if [ -e "$malformed_repo/.cairn/entry-files" ] || [ -e "$malformed_repo/AGENTS.md" ]; then
  fail "malformed marker entry left a partial installation"
fi

# A deliberate local override is not inspected or reported as drift.
ignored_repo="$TMP_ROOT/ignored"
new_repo "$ignored_repo"
"$CAIRN" init --entry-file .agents/local.md "$ignored_repo" >/dev/null
printf '%s\n' '.agents/local.md' > "$ignored_repo/.cairnignore"
mv "$ignored_repo/.agents/local.md" "$ignored_repo/.agents/local.md.saved"
ln -s "$TMP_ROOT/ignored-outside" "$ignored_repo/.agents/local.md"
"$CAIRN" check "$ignored_repo" >/dev/null

# Runtime registration is covered by the same ledger requirement as any other
# project change; Cairn does not invent the handoff's factual details.
handoff_repo="$TMP_ROOT/handoff"
new_repo "$handoff_repo"
"$CAIRN" init "$handoff_repo" >/dev/null
git -C "$handoff_repo" add .
git -C "$handoff_repo" commit -qm 'Install Cairn'
"$CAIRN" init --entry-file .agents/qwen.md "$handoff_repo" >/dev/null
git -C "$handoff_repo" add .cairn .agents
if git -C "$handoff_repo" commit -qm 'Register Qwen runtime' >/dev/null 2>&1; then
  fail "hook accepted a runtime registration without a ledger update"
fi
printf '%s\n' '' '### 2026-09-02 · main · qwen' '- **Changed:** Registered runtime entry point.' '- **Validation:** smoke test.' '- **Status:** done.' '- **Next:** none.' >> "$handoff_repo/AI_HANDOFF.md"
git -C "$handoff_repo" add AI_HANDOFF.md
git -C "$handoff_repo" commit -qm 'Record runtime registration'

# Older headers are made neutral without changing append-only log history.
migrate_repo="$TMP_ROOT/migrate"
new_repo "$migrate_repo"
"$CAIRN" init "$migrate_repo" >/dev/null
perl -pi -e 's/AI agent, runtime, model, and human collaborator\*\*/AI agent** (claude · gemini · chatgpt · copilot)/' "$migrate_repo/AI_HANDOFF.md"
sed -n '/^## Log/,$p' "$migrate_repo/AI_HANDOFF.md" > "$TMP_ROOT/log-before"
"$CAIRN" init "$migrate_repo" >/dev/null
contains "$migrate_repo/AI_HANDOFF.md" "AI agent, runtime, model, and human collaborator**"
contains "$migrate_repo/AI_HANDOFF.md" "| Branch | Worktree | Actor / runtime / model | Status | Summary | Updated |"
cmp -s "$TMP_ROOT/log-before" <(sed -n '/^## Log/,$p' "$migrate_repo/AI_HANDOFF.md") || fail "header migration rewrote the Log"

echo "ok - cairn smoke tests"

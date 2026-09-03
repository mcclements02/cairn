#!/usr/bin/env bash
# Lightweight integration coverage for cAIrn's installer and generic entry files.
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
"$CAIRN" init --entry-file .agents/tool-instructions.md "$generic_repo" >/dev/null
contains "$generic_repo/.cairn/entry-files" ".agents/tool-instructions.md"
contains "$generic_repo/.agents/tool-instructions.md" "CAIRN-ENTRY:BEGIN"
contains "$generic_repo/.agents/tool-instructions.md" "every agent, runtime, model"
contains "$generic_repo/AI_HANDOFF.md" "Actor / runtime / model"
does_not_contain "$generic_repo/AI_HANDOFF.md" "claude · gemini · chatgpt · copilot"
"$CAIRN" check "$generic_repo" >/dev/null
perl -pi -e 's/\n/\r\n/g' "$generic_repo/.cairn/entry-files"
"$CAIRN" init --entry-file .agents/tool-instructions.md "$generic_repo" >/dev/null
registered_count="$(tr -d '\r' < "$generic_repo/.cairn/entry-files" | grep -Fxc '.agents/tool-instructions.md')"
[ "$registered_count" = "1" ] || fail "CRLF registry duplicated an entry"
perl -pi -e 's/\n/\r\n/g' "$generic_repo/.agents/tool-instructions.md"
"$CAIRN" check "$generic_repo" >/dev/null
mv "$generic_repo/.agents/tool-instructions.md" "$generic_repo/.agents/tool-instructions.md.saved"
if "$CAIRN" check "$generic_repo" >/dev/null 2>&1; then
  fail "check accepted a missing registered entry file"
fi
mv "$generic_repo/.agents/tool-instructions.md.saved" "$generic_repo/.agents/tool-instructions.md"
"$CAIRN" check "$generic_repo" >/dev/null

# A changed managed block is detected, then restored without touching the rest.
chmod 755 "$generic_repo/.agents/tool-instructions.md"
perl -pi -e 's/## cAIrn coordination/## Changed heading/' "$generic_repo/.agents/tool-instructions.md"
if "$CAIRN" check "$generic_repo" >/dev/null 2>&1; then
  fail "check accepted a changed agent entry block"
fi
"$CAIRN" init "$generic_repo" >/dev/null
contains "$generic_repo/.agents/tool-instructions.md" "## cAIrn coordination"
[ -x "$generic_repo/.agents/tool-instructions.md" ] || fail "entry-file mode was not preserved"
"$CAIRN" check "$generic_repo" >/dev/null

# Multiple or malformed managed blocks are drift, never silently ignored.
cp "$generic_repo/.agents/tool-instructions.md" "$TMP_ROOT/entry-copy"
cat "$TMP_ROOT/entry-copy" >> "$generic_repo/.agents/tool-instructions.md"
if "$CAIRN" check "$generic_repo" >/dev/null 2>&1; then
  fail "check accepted duplicate cAIrn entry blocks"
fi
if "$CAIRN" init "$generic_repo" >/dev/null 2>&1; then
  fail "init overwrote duplicate cAIrn entry blocks"
fi
cp "$TMP_ROOT/entry-copy" "$generic_repo/.agents/tool-instructions.md"
"$CAIRN" check "$generic_repo" >/dev/null

# A writable directory can repair a read-only entry while keeping its mode.
readonly_repo="$TMP_ROOT/readonly"
new_repo "$readonly_repo"
"$CAIRN" init --entry-file .agents/local.md "$readonly_repo" >/dev/null
perl -pi -e 's/## cAIrn coordination/## Old heading/' "$readonly_repo/.agents/local.md"
chmod 444 "$readonly_repo/.agents/local.md"
"$CAIRN" init "$readonly_repo" >/dev/null
contains "$readonly_repo/.agents/local.md" "## cAIrn coordination"
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

# A registered path cannot also become another registered path's parent.
entry_tree_collision_repo="$TMP_ROOT/entry-tree-collision"
new_repo "$entry_tree_collision_repo"
if "$CAIRN" init --entry-file .agents/qwen --entry-file .agents/qwen/instructions.md "$entry_tree_collision_repo" >/dev/null 2>&1; then
  fail "init accepted an entry-file parent/child collision"
fi
if [ -e "$entry_tree_collision_repo/.cairn/entry-files" ] || [ -e "$entry_tree_collision_repo/AGENTS.md" ]; then
  fail "entry-file parent/child collision left a partial installation"
fi

# A custom scripts directory is constrained to a real repo-relative directory.
scripts_dir_repo="$TMP_ROOT/scripts-dir"
new_repo "$scripts_dir_repo"
"$CAIRN" init --scripts-dir tooling/cairn "$scripts_dir_repo" >/dev/null
[ -x "$scripts_dir_repo/tooling/cairn/cairn-resources.sh" ] || fail "resources script was not installed in custom scripts dir"
contains "$scripts_dir_repo/.gitattributes" "tooling/cairn/cairn-*.sh text eol=lf"
"$CAIRN" check --scripts-dir tooling/cairn "$scripts_dir_repo" >/dev/null
outside_scripts="$TMP_ROOT/outside-scripts"
unsafe_scripts_repo="$TMP_ROOT/unsafe-scripts-dir"
new_repo "$unsafe_scripts_repo"
if "$CAIRN" init --scripts-dir "$outside_scripts" "$unsafe_scripts_repo" >/dev/null 2>&1; then
  fail "init accepted an absolute scripts directory"
fi
if [ -e "$outside_scripts" ] || [ -e "$unsafe_scripts_repo/AGENTS.md" ]; then
  fail "unsafe scripts directory caused an external or partial write"
fi
core_collision_scripts_repo="$TMP_ROOT/core-collision-scripts-dir"
new_repo "$core_collision_scripts_repo"
if "$CAIRN" init --scripts-dir AI_HANDOFF.md "$core_collision_scripts_repo" >/dev/null 2>&1; then
  fail "init accepted a scripts directory that collides with the ledger"
fi
if [ -e "$core_collision_scripts_repo/AI_HANDOFF.md" ] || [ -e "$core_collision_scripts_repo/AGENTS.md" ]; then
  fail "core-collision scripts directory left a partial installation"
fi

# The documented PATH symlink resolves templates from the real cAIrn install.
symlink_bin="$TMP_ROOT/bin"
mkdir -p "$symlink_bin"
ln -s "$CAIRN" "$symlink_bin/cairn"
symlink_install_repo="$TMP_ROOT/symlink-install"
new_repo "$symlink_install_repo"
"$symlink_bin/cairn" init "$symlink_install_repo" >/dev/null
[ -f "$symlink_install_repo/AI_HANDOFF.md" ] || fail "PATH symlink install did not find templates"

# Existing runtime instructions and pre-commit hooks are user-owned by default.
native_repo="$TMP_ROOT/native"
new_repo "$native_repo"
mkdir -p "$native_repo/.githooks"
printf '%s\n' 'Keep this native instruction.' > "$native_repo/CLAUDE.md"
printf '%s\n' '#!/usr/bin/env bash' 'echo existing-hook' > "$native_repo/.githooks/pre-commit"
"$CAIRN" init "$native_repo" >/dev/null
contains "$native_repo/CLAUDE.md" "Keep this native instruction."
contains "$native_repo/.githooks/pre-commit" "existing-hook"
"$CAIRN" init --adopt-entry-file CLAUDE.md "$native_repo" >/dev/null
contains "$native_repo/CLAUDE.md" "Keep this native instruction."
contains "$native_repo/CLAUDE.md" "CAIRN-ENTRY:BEGIN"

# An old exact cAIrn hook upgrades once, while arbitrary hooks above are left alone.
legacy_hook_repo="$TMP_ROOT/legacy-hook"
new_repo "$legacy_hook_repo"
"$CAIRN" init "$legacy_hook_repo" >/dev/null
sed 's|__SCRIPTS_DIR__|scripts|g' "$ROOT/templates/githooks/pre-commit.legacy" > "$legacy_hook_repo/.githooks/pre-commit"
"$CAIRN" init "$legacy_hook_repo" >/dev/null
contains "$legacy_hook_repo/.githooks/pre-commit" "CAIRN-HOOK:BEGIN"

# cAIrn merges its LF rules rather than replacing a project's .gitattributes.
attrs_repo="$TMP_ROOT/attrs"
new_repo "$attrs_repo"
printf '%s\n' '*.snap binary' > "$attrs_repo/.gitattributes"
"$CAIRN" init "$attrs_repo" >/dev/null
contains "$attrs_repo/.gitattributes" "*.snap binary"
contains "$attrs_repo/.gitattributes" "CAIRN-GITATTRIBUTES:BEGIN"
contains "$attrs_repo/.gitattributes" ".cairn/entry-files text eol=lf"
perl -pi -e 's/\n/\r\n/g' "$attrs_repo/.gitattributes"
"$CAIRN" check "$attrs_repo" >/dev/null

# A malformed AGENTS block refuses before any install writes can occur.
bad_agents_repo="$TMP_ROOT/bad-agents"
new_repo "$bad_agents_repo"
printf '%s\n' 'before' '<!-- CAIRN-LEDGER:BEGIN (managed) -->' 'after-must-survive' > "$bad_agents_repo/AGENTS.md"
if "$CAIRN" init "$bad_agents_repo" >/dev/null 2>&1; then
  fail "init accepted a malformed AGENTS ledger block"
fi
contains "$bad_agents_repo/AGENTS.md" "after-must-survive"
if [ -e "$bad_agents_repo/AI_HANDOFF.md" ] || [ -e "$bad_agents_repo/.gitattributes" ]; then
  fail "malformed AGENTS block left partial installation files"
fi

# --force never erases append-only ledger history.
force_repo="$TMP_ROOT/force"
new_repo "$force_repo"
"$CAIRN" init "$force_repo" >/dev/null
printf '%s\n' '### preserved-force-sentinel' '- **Changed:** must remain.' >> "$force_repo/AI_HANDOFF.md"
"$CAIRN" init --force "$force_repo" >/dev/null
contains "$force_repo/AI_HANDOFF.md" "preserved-force-sentinel"

# resources is an opt-in snapshot and has no repository side effects.
resources_before="$(git -C "$generic_repo" status --porcelain)"
"$CAIRN" resources "$generic_repo" > "$TMP_ROOT/resources"
contains "$TMP_ROOT/resources" "host-local snapshot only"
contains "$TMP_ROOT/resources" "top visible processes by resident memory"
resources_after="$(git -C "$generic_repo" status --porcelain)"
[ "$resources_before" = "$resources_after" ] || fail "resources changed repository state"
resource_trust_repo="$TMP_ROOT/resource-trust"
new_repo "$resource_trust_repo"
"$CAIRN" init "$resource_trust_repo" >/dev/null
printf '%s\n' 'echo UNTRUSTED-RESOURCE-SCRIPT-RAN' >> "$resource_trust_repo/scripts/cairn-resources.sh"
"$CAIRN" resources "$resource_trust_repo" > "$TMP_ROOT/resources-trust"
does_not_contain "$TMP_ROOT/resources-trust" "UNTRUSTED-RESOURCE-SCRIPT-RAN"

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

# Legacy migration is preflighted too: it may never follow a symlinked parent
# or mutate files outside the repository.
legacy_symlink_repo="$TMP_ROOT/legacy-symlink"
legacy_outside="$TMP_ROOT/legacy-outside"
new_repo "$legacy_symlink_repo"
mkdir -p "$legacy_outside/workflows"
printf '%s\n' 'legacy workflow must survive' > "$legacy_outside/workflows/ai-sync.yml"
ln -s "$legacy_outside" "$legacy_symlink_repo/.github"
if "$CAIRN" init "$legacy_symlink_repo" >/dev/null 2>&1; then
  fail "init followed a symlinked legacy workflow parent"
fi
[ -f "$legacy_outside/workflows/ai-sync.yml" ] || fail "legacy migration moved an external file"
[ ! -e "$legacy_outside/workflows/cairn.yml" ] || fail "legacy migration wrote an external destination"
[ ! -e "$legacy_symlink_repo/AGENTS.md" ] || fail "unsafe legacy migration left partial installation"

# A symlinked sync destination is rejected before any independent managed file
# is created, even when there is no legacy source to migrate.
sync_symlink_repo="$TMP_ROOT/sync-symlink"
sync_outside="$TMP_ROOT/sync-outside"
new_repo "$sync_symlink_repo"
mkdir -p "$sync_outside"
ln -s "$sync_outside" "$sync_symlink_repo/.github"
if "$CAIRN" init "$sync_symlink_repo" >/dev/null 2>&1; then
  fail "init accepted a symlinked workflow destination"
fi
for path in .gitattributes .githooks scripts AI_HANDOFF.md AGENTS.md; do
  [ ! -e "$sync_symlink_repo/$path" ] || fail "unsafe sync destination left partial install path: $path"
done

ledger_symlink_repo="$TMP_ROOT/ledger-symlink"
ledger_outside="$TMP_ROOT/ledger-outside.md"
new_repo "$ledger_symlink_repo"
printf '%s\n' 'ai-sync-status.sh outside ledger must survive' > "$ledger_outside"
ln -s "$ledger_outside" "$ledger_symlink_repo/AI_HANDOFF.md"
if "$CAIRN" init "$ledger_symlink_repo" >/dev/null 2>&1; then
  fail "init accepted a symlinked ledger"
fi
[ -L "$ledger_symlink_repo/AI_HANDOFF.md" ] || fail "init replaced a symlinked ledger"
contains "$ledger_outside" "outside ledger must survive"
[ ! -e "$ledger_symlink_repo/AGENTS.md" ] || fail "unsafe ledger left partial installation"

# Markers embedded in surrounding text are refused before replacement can erase it.
malformed_repo="$TMP_ROOT/malformed"
new_repo "$malformed_repo"
mkdir -p "$malformed_repo/.agents"
printf '%s\n' 'before' 'prefix <!-- CAIRN-ENTRY:BEGIN -->' 'old block' '<!-- CAIRN-ENTRY:END --> suffix' 'after-must-survive' > "$malformed_repo/.agents/bad.md"
if "$CAIRN" init --adopt-entry-file .agents/bad.md "$malformed_repo" >/dev/null 2>&1; then
  fail "init accepted embedded cAIrn markers"
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
# project change; cAIrn does not invent the handoff's factual details.
handoff_repo="$TMP_ROOT/handoff"
new_repo "$handoff_repo"
"$CAIRN" init "$handoff_repo" >/dev/null
git -C "$handoff_repo" add .
git -C "$handoff_repo" commit -qm 'Install cAIrn'
"$CAIRN" init --entry-file .agents/qwen.md "$handoff_repo" >/dev/null
git -C "$handoff_repo" add .cairn .agents
if git -C "$handoff_repo" commit -qm 'Register Qwen runtime' >/dev/null 2>&1; then
  fail "hook accepted a runtime registration without a ledger update"
fi
printf '%s\n' '' '### 2026-09-02 · main · qwen' '- **Changed:** Registered runtime entry point.' '- **Validation:** smoke test.' '- **Status:** done.' '- **Next:** none.' >> "$handoff_repo/AI_HANDOFF.md"
git -C "$handoff_repo" add AI_HANDOFF.md
git -C "$handoff_repo" commit -qm 'Record runtime registration'

# A code deletion needs a ledger update locally, just like a code addition.
printf '%s\n' 'console.log("tracked");' > "$handoff_repo/tracked.js"
printf '%s\n' '' '### 2026-09-02 · main · qwen' '- **Changed:** Added tracked fixture.' '- **Validation:** smoke test.' '- **Status:** done.' '- **Next:** none.' >> "$handoff_repo/AI_HANDOFF.md"
git -C "$handoff_repo" add tracked.js AI_HANDOFF.md
git -C "$handoff_repo" commit -qm 'Add tracked fixture'
rm "$handoff_repo/tracked.js"
git -C "$handoff_repo" add -u
if git -C "$handoff_repo" commit -qm 'Delete tracked fixture without ledger' >/dev/null 2>&1; then
  fail "hook accepted a code deletion without a ledger update"
fi

# A deleted or type-changed ledger cannot pass the local hook or CI classifier.
deleted_ledger_repo="$TMP_ROOT/deleted-ledger"
new_repo "$deleted_ledger_repo"
"$CAIRN" init "$deleted_ledger_repo" >/dev/null
git -C "$deleted_ledger_repo" add .
git -C "$deleted_ledger_repo" commit -qm 'Install cAIrn'
git -C "$deleted_ledger_repo" rm -q AI_HANDOFF.md
if git -C "$deleted_ledger_repo" commit -qm 'Delete ledger' >/dev/null 2>&1; then
  fail "hook accepted a deleted ledger"
fi
if printf '%s\n' 'AI_HANDOFF.md' | (cd "$deleted_ledger_repo" && bash scripts/cairn-check.sh) >/dev/null 2>&1; then
  fail "CI classifier accepted a deleted staged ledger"
fi

type_changed_ledger_repo="$TMP_ROOT/type-changed-ledger"
new_repo "$type_changed_ledger_repo"
"$CAIRN" init "$type_changed_ledger_repo" >/dev/null
git -C "$type_changed_ledger_repo" add .
git -C "$type_changed_ledger_repo" commit -qm 'Install cAIrn'
rm "$type_changed_ledger_repo/AI_HANDOFF.md"
ln -s "$TMP_ROOT/not-a-ledger" "$type_changed_ledger_repo/AI_HANDOFF.md"
git -C "$type_changed_ledger_repo" add -A
if git -C "$type_changed_ledger_repo" commit -qm 'Replace ledger with symlink' >/dev/null 2>&1; then
  fail "hook accepted a symlinked ledger"
fi

# A regular file is not enough: an empty handoff is drift and cannot accompany code.
empty_ledger_repo="$TMP_ROOT/empty-ledger"
new_repo "$empty_ledger_repo"
"$CAIRN" init "$empty_ledger_repo" >/dev/null
git -C "$empty_ledger_repo" add .
git -C "$empty_ledger_repo" commit -qm 'Install cAIrn'
: > "$empty_ledger_repo/AI_HANDOFF.md"
printf '%s\n' 'console.log("requires handoff");' > "$empty_ledger_repo/requires-handoff.js"
if "$CAIRN" check "$empty_ledger_repo" >/dev/null 2>&1; then
  fail "check accepted an empty handoff"
fi
git -C "$empty_ledger_repo" add AI_HANDOFF.md requires-handoff.js
if git -C "$empty_ledger_repo" commit -qm 'Empty handoff with code' >/dev/null 2>&1; then
  fail "hook accepted an empty handoff with code"
fi
if printf '%s\n' AI_HANDOFF.md requires-handoff.js | (cd "$empty_ledger_repo" && bash scripts/cairn-check.sh) >/dev/null 2>&1; then
  fail "CI classifier accepted an empty handoff with code"
fi

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

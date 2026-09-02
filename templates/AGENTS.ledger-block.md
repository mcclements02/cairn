<!-- CAIRN-LEDGER:BEGIN (managed section; edit the template + re-run rollout) -->
## Project State Ledger (Cross-Agent Sync)

`AI_HANDOFF.md` is the shared project ledger for in-flight work across every
worktree, branch, agent/runtime/model, and human collaborator. It holds
**state**; this file holds **rules**. The ledger's actor/runtime/model value is
free text, never a supported-agent list.

- Before starting any code task, read `AI_HANDOFF.md` to see what other branches
  and worktrees are doing. Do not duplicate, overwrite, or strand their work.
- Whenever a change touches code, update `AI_HANDOFF.md` in the **same change**:
  append a Log entry (date · branch · actor/runtime/model · files · validation ·
  status · next) and refresh your branch's row in Active Work.
- Stage and commit `AI_HANDOFF.md` **together with** the code, so the state flows
  through the branch and survives merges. A merge conflict in the Log means two
  agents diverged — resolve by keeping both entries, never by dropping one.
- Never delete or rewrite past Log entries. When a branch is merged or abandoned,
  note it in the Log and remove its Active Work row.
- Run `bash __SCRIPTS_DIR__/cairn-status.sh` to see live cross-worktree state and spot
  stranded (unmerged / uncommitted) work. Run `bash __SCRIPTS_DIR__/cairn-hooks.sh`
  once per clone to enable the pre-commit reminder.

Enforcement is layered:

- **Local:** `.githooks/pre-commit` blocks a commit that stages code without
  staging `AI_HANDOFF.md`. Bypass a docs-only commit with `git commit --no-verify`.
- **CI:** `.github/workflows/cairn.yml` runs the same check on every pull
  request and fails if code changed without a ledger update. For a legitimate
  docs-only PR, apply the **`skip-ledger`** label (auditable) instead of bypassing.
<!-- CAIRN-LEDGER:END -->

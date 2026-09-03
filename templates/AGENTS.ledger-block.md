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
- For a host-local troubleshooting snapshot, run `bash __SCRIPTS_DIR__/cairn-resources.sh`.
  It reports memory/process state only; never copy sensitive process arguments into
  a handoff and never treat RSS alone as proof of a leak.

Enforcement is layered:

- **Local:** `.githooks/pre-commit` blocks a commit that stages code without
  staging `AI_HANDOFF.md`, or that deletes, replaces, or empties the ledger's
  required sections. Bypass a docs-only commit with `git commit --no-verify` only
  when you have a documented reason.
- **CI:** `.github/workflows/cairn.yml` runs the same check on every pull
  request and fails if code changed without a valid ledger update. Docs-only PRs
  pass naturally; do not add a label-based bypass for code changes.
<!-- CAIRN-LEDGER:END -->

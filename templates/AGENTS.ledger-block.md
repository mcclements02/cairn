<!-- CAIRN-LEDGER:BEGIN (managed section; edit the template + re-run rollout) -->
## Project State Ledger (Cross-Agent Sync)

`AI_HANDOFF.md` is the shared project ledger for in-flight work across every
worktree, branch, agent/runtime/model, and human collaborator. It holds
**state**; this file holds **rules**. The ledger's actor/runtime/model value is
free text, never a supported-agent list.

### Start or resume a session (every agent)

This protocol applies to any coding agent, editor assistant, hosted worker,
local model, automation, or human. No account integration, model detection,
special agent name, or memory from an earlier chat is required.

1. Read the repository-root `AGENTS.md`, then `AI_HANDOFF.md`: review Active
   Work, the newest Log entries, and any older entry relevant to the task.
   Follow the repository's scoped instructions for the files you will edit.
2. Run the Required preflight above and
   `bash __SCRIPTS_DIR__/cairn-status.sh`. Compare live Git state with the ledger;
   a historical entry is context, not proof that a branch is merged or clean.
3. Identify the current task, branch/worktree, and overlapping work. Preserve
   other writers' files and rows. If ownership or overlapping intent is unclear,
   coordinate before editing. Resume useful existing work rather than duplicating it.
4. Before changing code, add or refresh your Active Work row with the branch,
   worktree, actor, status, summary, and date. Use an attributable free-text actor
   (tool name, session/worker identifier, human name, or any combination); do not
   guess an unavailable model name. Separate writers need separate owned rows
   and worktrees under the ownership rules above.

### Keep the next participant informed

- Whenever a change touches code, update `AI_HANDOFF.md` in the **same change**.
  Add a new Log entry immediately below the Log heading and its introductory
  text, above earlier entries: date · branch · actor/runtime/model · changed files
  and purpose · validation commands/results · status · next action.
- Refresh your Active Work row at meaningful checkpoints and before pausing,
  ending a session, or handing work to another participant. Record unfinished
  work, blockers, failed or unrun checks, and the concrete next step. A partial
  task needs a handoff too; do not wait for a commit to record it.
- Bump the ledger Version and Last updated metadata on every edit. Re-read the
  ledger before updating it so recent contributions survive. Edit only your
  owned Active Work row and add your new Log entry; keep other rows and entries.
- When a commit is authorized, stage and commit `AI_HANDOFF.md` **together with**
  the code. Updating the ledger does not authorize Git or remote operations.
  If work remains uncommitted, record that fact instead of claiming it landed.
  Resolve Log merge conflicts by keeping both entries, never by dropping one.
- Never delete or rewrite active Log entries during routine work. When a branch is merged
  or abandoned, note it in the Log and remove its Active Work row.
- Compact the ledger periodically: To prevent unbounded log growth and keep LLM context
  focused, periodically archive older resolved entries into `AI_HANDOFF_ARCHIVE.md` (or run
  `cairn compact`). Always preserve in-flight rows in Active Work and recent handoff entries.
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

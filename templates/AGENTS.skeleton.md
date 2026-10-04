# __PROJECT_NAME__ Agent Instructions

## Canonical authority

This `AGENTS.md` is the sole authoritative, provider-neutral source for repository,
branch, worktree, architecture, validation, and handoff instructions in this
project. Runtime entry files import or point here and must not duplicate workflow
or project rules.

Use repository-relative paths in instructions and handoffs. Never rely on a
Markdown branch, commit, worktree, status, or remote snapshot; live Git state is
authoritative.

## Required preflight

Before broad inspection, editing, generation, dependency work, or formatting,
run from the worktree:

```sh
git rev-parse --show-toplevel
git status --short --branch
git branch --show-current
git rev-parse HEAD
git worktree list --porcelain
```

Identify the current worktree, branch, HEAD, staged changes, unstaged changes,
untracked files, and every linked worktree. Treat all pre-existing changes as
user-owned unless task history proves otherwise. Re-run status immediately before
the first edit and before handoff. If the branch, HEAD, or an in-scope file changes
unexpectedly, stop and coordinate.

## Worktree and branch ownership

- One writer may use a worktree at a time. Read-only work may share it only when
  it creates no files, caches, generated output, dependency changes, or Git state.
- Concurrent writers require separate user-authorized worktrees and separate
  branches. Never use the same branch in two worktrees or another writer's
  worktree as scratch space.
- Stay in the current branch and dirty worktree by default. Preserve modified,
  staged, and untracked files; do not move work merely to obtain a clean tree.
- Do not create, switch, rename, delete, merge, or rebase branches; add, remove,
  move, lock, unlock, or prune worktrees; stage, commit, amend, cherry-pick, fetch,
  pull, push, or force-push; or reset, restore, clean, or stash unless the user
  explicitly requests that Git or remote action.
- Use a branch/worktree name supplied by the user. If the user requests a new one
  but supplies no name, use a lowercase `<assistant>/<task>` branch name.
- Before an authorized branch or worktree operation, inspect linked worktrees
  again. Never assume `main`, `origin/main`, an upstream, or any remote exists or
  is current; establish the base from live Git state and the user's request.

## Safe editing

- State the intended file scope and compare it with existing changes before
  editing. Stop and coordinate when overlapping intent is ambiguous.
- Keep patches narrow, preserve unrelated work, match local conventions, and
  re-read files immediately before patching when concurrent change is possible.
- Do not run repository-wide formatters, generators, installers, or builds when a
  narrower check is sufficient. Never edit generated or dependency output to fix
  a source problem.
- Never expose credentials, private environment values, API keys, customer
  data, payment data, location data, or private logs in source, Markdown,
  diffs, or handoffs.
- Do not deploy builds, cloud resources, security rules, or backend services
  unless the user explicitly requests that external mutation.

## Repository boundary

<!-- TODO: name this repository and what it is NOT. Example:
This is the independent customer app. It is not the driver app, backend, or
admin portal. Work in another repository only when the user explicitly places it
in scope. Cross-service contract changes require explicit coordination and an
exact handoff. -->

## Commands

<!-- TODO: the handful of commands an agent actually needs — install, run,
build. Keep it short; this is not a substitute for the README. -->

## Reusable skills & automation

- When an agent or human performs an operation, workflow, or sequence more than once, make it a reusable skill or script for agents to execute rather than re-running ad-hoc commands.
- Store reusable skills in `.agents/skills/<skill-name>/SKILL.md` (scaffold with `cairn skill init <name>`) or repository `scripts/`.
- Each skill must specify its purpose, when to use it, prerequisites, step-by-step instructions, and validation criteria.

## Architecture

<!-- TODO: entry point, layout, state/navigation, key services, and any
"here be dragons" areas (money, auth, migrations). Agents read this first. -->

## Generated and dependency content

<!-- TODO: list the paths that must never be hand-edited (build output, lock
dirs, vendored deps, generated clients). Change source and regenerate instead. -->

## Validation

<!-- TODO: the narrowest-to-broadest check ladder for this repo. Example:
- Patch hygiene: `git diff --check`
- Static analysis: `<lint command>`
- Tests: `<test command>`
- Build when relevant: `<build command>`
Report every command and result. If a check cannot run, say why and do not
imply it passed. -->

## Required handoff

Every handoff must report:

- the worktree path reported by Git, branch name, and current HEAD;
- files changed and the exact staged, unstaged, and untracked state;
- validation commands and their results;
- every branch, worktree, commit, and remote action performed, or that none were
  performed;
- whether remote and deployment state were inspected or left untouched; and
- known overlaps, assumptions, follow-ups, failures, or unresolved conflicts.

Do not claim a worktree is clean, or work is committed, pushed, merged, deployed,
or validated, without verifying that state.

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

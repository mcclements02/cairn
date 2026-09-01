# __PROJECT_NAME__ Agent Instructions

## Canonical authority

This `AGENTS.md` is the sole authoritative, provider-neutral source for repository,
branch, worktree, architecture, validation, and handoff instructions in this
project. Provider entry files import or point here and must not duplicate workflow
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

<!-- AI-SYNC-LEDGER:BEGIN (managed section; edit the template + re-run rollout) -->
## Project State Ledger (Cross-Agent Sync)

`AI_HANDOFF.md` is the shared project ledger for in-flight work across every
worktree, branch, and agent (claude · gemini · chatgpt · copilot). It holds
**state**; this file holds **rules**.

- Before starting any code task, read `AI_HANDOFF.md` to see what other branches
  and worktrees are doing. Do not duplicate, overwrite, or strand their work.
- Whenever a change touches code, update `AI_HANDOFF.md` in the **same change**:
  append a Log entry (date · branch · agent · files · validation · status ·
  next) and refresh your branch's row in Active Work.
- Stage and commit `AI_HANDOFF.md` **together with** the code, so the state flows
  through the branch and survives merges. A merge conflict in the Log means two
  agents diverged — resolve by keeping both entries, never by dropping one.
- Never delete or rewrite past Log entries. When a branch is merged or abandoned,
  note it in the Log and remove its Active Work row.
- Run `bash __SCRIPTS_DIR__/ai-sync-status.sh` to see live cross-worktree state and spot
  stranded (unmerged / uncommitted) work. Run `bash __SCRIPTS_DIR__/ai-sync-install.sh`
  once per clone to enable the pre-commit reminder.

Enforcement is layered:

- **Local:** `.githooks/pre-commit` blocks a commit that stages code without
  staging `AI_HANDOFF.md`. Bypass a docs-only commit with `git commit --no-verify`.
- **CI:** `.github/workflows/ai-sync.yml` runs the same check on every pull
  request and fails if code changed without a ledger update. For a legitimate
  docs-only PR, apply the **`skip-ledger`** label (auditable) instead of bypassing.
<!-- AI-SYNC-LEDGER:END -->

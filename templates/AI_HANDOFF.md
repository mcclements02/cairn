# AI Handoff Ledger — Project State

<!-- Version control: bump Version and Last updated on every edit to this file. -->
**Version:** 3 · **Last updated:** __DATE__ · **Updated by:** cairn

Single source of truth for **in-flight work across every worktree, branch, and
AI agent, runtime, model, and human collaborator**. The `Actor / runtime /
model` value is free text, not an allowlist. How to use this file is defined in
[AGENTS.md](AGENTS.md) → "Project State Ledger (Cross-Agent Sync)". This file
holds **state, not rules**.

New or returning participant: read the repository-root [AGENTS.md](AGENTS.md)
and this ledger at the start of every session. The startup and handoff workflow
is in AGENTS.md's "Project State Ledger (Cross-Agent Sync)" section. Use Active
Work and recent Log entries to resume work and leave the next participant a
current handoff, even when the task is unfinished or no commit is authorized.

> Update this ledger in the **same change** as any code edit and commit them
> together, so every branch and worktree carries the current picture and no work
> is stranded. Run `bash __SCRIPTS_DIR__/cairn-status.sh` for the live view.

## Active Work

One row per in-flight branch/worktree. Different branches own different rows, so
this table merges cleanly. Remove a row once its branch is merged or abandoned
(record that in the Log first).

| Branch | Worktree | Actor / runtime / model | Status | Summary | Updated |
|--------|----------|-------------------------|--------|---------|---------|
| __BRANCH__ | . | — | idle | baseline | __DATE__ |

## Log (append newest on top)

Append-only during active work. One entry per handoff. Never rewrite active entries.
Compact periodically (or run `cairn compact`) by archiving older resolved entries into
[AI_HANDOFF_ARCHIVE.md](AI_HANDOFF_ARCHIVE.md) while retaining recent entries and active work.
A merge conflict here means two agents diverged — keep **both** entries.

### __DATE__ · __BRANCH__ · cairn
- **Changed:** Initialized the cAIrn protocol — `AGENTS.md` ledger section,
  `AI_HANDOFF.md`, `AI_WORKSPACE.md`, runtime entry points,
  `.githooks/pre-commit`, `__SCRIPTS_DIR__/cairn-*`, and
  `.github/workflows/cairn.yml`.
- **Validation:** scaffolding only — no code paths touched.
- **Status:** done.
- **Next:** run `bash __SCRIPTS_DIR__/cairn-hooks.sh` once per clone to enable
  the pre-commit reminder if init reported it could not safely do so, and make
  "cAIrn ledger check" a required status check in branch protection.
<!-- entry:cairn-init -->

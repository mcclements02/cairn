# AI Handoff Ledger — Project State

<!-- Version control: bump Version and Last updated on every edit to this file. -->
**Version:** 2 · **Last updated:** __DATE__ · **Updated by:** cairn

Single source of truth for **in-flight work across every worktree, branch, and
AI agent, runtime, model, and human collaborator**. The `Actor / runtime /
model` value is free text, not an allowlist. How to use this file is defined in
[AGENTS.md](AGENTS.md) → "Project State Ledger (Cross-Agent Sync)". This file
holds **state, not rules**.

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

Append-only. One entry per handoff. Never rewrite or delete past entries. A merge
conflict here means two agents diverged — keep **both** entries.

### __DATE__ · __BRANCH__ · cairn
- **Changed:** Initialized the Cairn protocol — `AGENTS.md` ledger section,
  `AI_HANDOFF.md`, `AI_WORKSPACE.md`, runtime entry points,
  `.githooks/pre-commit`, `__SCRIPTS_DIR__/cairn-*`, and
  `.github/workflows/cairn.yml`.
- **Validation:** scaffolding only — no code paths touched.
- **Status:** done.
- **Next:** run `bash __SCRIPTS_DIR__/cairn-hooks.sh` once per clone to enable
  the pre-commit reminder, and make "Cairn ledger check" a required status
  check in branch protection.
<!-- entry:cairn-init -->

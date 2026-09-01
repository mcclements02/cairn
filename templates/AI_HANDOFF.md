# AI Handoff Ledger — Project State

<!-- Version control: bump Version and Last updated on every edit to this file. -->
**Version:** 1 · **Last updated:** __DATE__ · **Updated by:** ai-sync-init

Single source of truth for **in-flight work across every worktree, branch, and
AI agent** (claude · gemini · chatgpt · copilot). How to use it is defined in
[AGENTS.md](AGENTS.md) → "Project State Ledger (Cross-Agent Sync)". This file
holds **state, not rules**.

> Update this ledger in the **same change** as any code edit and commit them
> together, so every branch and worktree carries the current picture and no work
> is stranded. Run `bash __SCRIPTS_DIR__/ai-sync-status.sh` for the live view.

## Active Work

One row per in-flight branch/worktree. Different branches own different rows, so
this table merges cleanly. Remove a row once its branch is merged or abandoned
(record that in the Log first).

| Branch | Worktree | Agent | Status | Summary | Updated |
|--------|----------|-------|--------|---------|---------|
| __BRANCH__ | . | — | idle | baseline | __DATE__ |

## Log (append newest on top)

Append-only. One entry per handoff. Never rewrite or delete past entries. A merge
conflict here means two agents diverged — keep **both** entries.

### __DATE__ · __BRANCH__ · ai-sync-init
- **Changed:** Initialized the AI-SYNC protocol — `AGENTS.md` ledger section,
  `AI_HANDOFF.md`, `AI_WORKSPACE.md`, provider pointers, `.githooks/pre-commit`,
  `__SCRIPTS_DIR__/ai-sync-*`, and `.github/workflows/ai-sync.yml`.
- **Validation:** scaffolding only — no code paths touched.
- **Status:** done.
- **Next:** run `bash __SCRIPTS_DIR__/ai-sync-install.sh` once per clone to enable
  the pre-commit reminder, and make "AI-SYNC ledger check" a required status
  check in branch protection.
<!-- entry:ai-sync-init -->

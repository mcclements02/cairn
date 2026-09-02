# AI Workspace Protocol

<!-- Version control: bump Version and Last updated on every edit to this file. -->
**Version:** 2 · **Last updated:** 2026-09-02 · **Updated by:** cairn

This file is a pointer, not a source of rules. It exists so any agent or human
looking for a "workspace protocol" lands on the real, in-repo sources instead of
a stale or out-of-repo snapshot.

- **Rules** — repository, branch, worktree, validation, and handoff guidance:
  [AGENTS.md](AGENTS.md) is the sole canonical authority. Optional
  runtime-adapter files only point there; so does this file.
- **State** — in-flight work across every worktree, branch, and actor/runtime/model:
  [AI_HANDOFF.md](AI_HANDOFF.md) is the shared ledger. Read it before starting a
  task and update it in the same change as any code edit.

If a runtime does not automatically read `AGENTS.md`, configure its native
instruction entry point to load this file. For a plain-text entry point, register
it with `cairn init --entry-file path/to/instructions.md`; use
`--adopt-entry-file` instead to preserve an existing instruction file and append
only cAIrn's marked routing block.

Registering or adopting an entry point changes project configuration. Add the
corresponding `AI_HANDOFF.md` Log entry before committing it; cAIrn never
invents an actor, summary, or validation result.

Do not add workflow rules here; update AGENTS.md instead. Live Git state and the
latest user instruction override any historical snapshot — always run the preflight
described in AGENTS.md before acting.

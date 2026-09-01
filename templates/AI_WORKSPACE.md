# AI Workspace Protocol

<!-- Version control: bump Version and Last updated on every edit to this file. -->
**Version:** 1 · **Last updated:** 2026-07-14 10:46 PDT · **Updated by:** claude

This file is a pointer, not a source of rules. It exists so any agent or human
looking for a "workspace protocol" lands on the real, in-repo sources instead of
a stale or out-of-repo snapshot.

- **Rules** — repository, branch, worktree, validation, and handoff guidance:
  [AGENTS.md](AGENTS.md) is the sole canonical authority. The provider files
  (CLAUDE.md, CHATGPT.md, GEMINI.md) only point there; so does this file.
- **State** — in-flight work across every worktree, branch, and agent:
  [AI_HANDOFF.md](AI_HANDOFF.md) is the shared ledger. Read it before starting a
  task and update it in the same change as any code edit.

Do not add workflow rules here; update AGENTS.md instead. Live Git state and the
latest user instruction override any historical snapshot — always run the preflight
described in AGENTS.md before acting.

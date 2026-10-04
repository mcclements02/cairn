# Changelog

## 0.1.0

- Provide agent-neutral startup and handoff instructions for new and resumed
  sessions, including unfinished work, validation, blockers, and next steps.
- Register or adopt arbitrary agent instruction files without replacing native
  content; preserve project instructions when upgrading the shared workflow.
- Add ledger compaction and reusable-skill scaffolding.
- Protect compaction and skill creation from traversal, symlink writes, and
  ledger/archive aliases. Preserve unresolved entries and active branch history.
- Add compaction previews with `--dry-run`.
- Correct CI checker argument handling so documentation cannot hide code changes.
- Package the executable and templates for Homebrew and run integration tests
  on macOS and Linux.

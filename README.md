# AI-SYNC

A cross-agent coordination protocol for repositories worked by more than one AI
coding agent — and a one-command installer that adds it to any repo.

When Claude, Codex, Gemini and Copilot all have write access to the same
project, the failure mode isn't bad code. It's **stranded work**: an agent
finishes something on a branch nobody else knows about, a second agent
re-implements it, a third rewrites the first one's fix. Chat context doesn't
survive the session, and no agent can read another's.

AI-SYNC fixes that with a single rule, enforced mechanically:

> **Every commit that touches code must also update the shared ledger.**

State lives in the repo, on the branch, in the diff — so it merges, survives
handoffs, and is readable by whichever agent shows up next.

## Install

```sh
git clone https://github.com/<you>/ai-sync.git
cd /path/to/your/repo && /path/to/ai-sync/ai-sync-init.sh
```

```
ai-sync-init.sh [--check] [--force] [--scripts-dir DIR] [TARGET_REPO]

  --check            report drift and exit non-zero; write nothing (use in CI)
  --force            re-seed AGENTS.md / AI_HANDOFF.md from templates (destructive)
  --scripts-dir DIR  override script-dir detection
```

Re-running is safe and is how you re-sync a drifted repo.

## The two-file split

The protocol's whole design rests on one separation:

| File | Holds | Lifecycle |
|------|-------|-----------|
| `AGENTS.md` | **Rules** — branch ownership, safe editing, validation ladder, handoff requirements | Edited deliberately; mostly stable |
| `AI_HANDOFF.md` | **State** — what is in flight, on which branch, by which agent, validated how | Updated with *every* code change |

Mixing the two is why "just put it in the prompt file" fails: rules get buried
under status, status goes stale, and agents stop trusting either.

Everything else routes to those two. `CLAUDE.md`, `GEMINI.md`, `CHATGPT.md` and
`AI_WORKSPACE.md` are **pointers only** — each is 2–5 lines that say "read
AGENTS.md". Provider-specific instruction files are where drift breeds; keeping
them empty of rules means there is exactly one authority per repo.

## The ledger

`AI_HANDOFF.md` has two sections, shaped by how git merges them:

**Active Work** — one row per in-flight branch/worktree. Different branches own
different rows, so concurrent edits merge cleanly instead of conflicting.

**Log** — append-only, newest on top. Each entry records date · branch · agent ·
files · validation · status · next.

> A merge conflict in the Log means two agents diverged. Resolve it by keeping
> **both** entries — never by dropping one. The conflict *is* the signal.

## Enforcement

A convention no one enforces is a convention no one follows. Three layers:

**Local** — `.githooks/pre-commit` rejects a commit that stages code without
staging `AI_HANDOFF.md`. Markdown and text are exempt, so docs work is
unblocked. Bypass with `git commit --no-verify`.

**CI** — `.github/workflows/ai-sync.yml` runs the same classification on every
PR. The local bypass is invisible to reviewers; the CI bypass is the
**`skip-ledger`** label — deliberate, attributable, and visible in the PR
timeline.

**Visibility** — `ai-sync-status.sh` reports every worktree, its dirty count,
every local branch not merged into the base, and the three newest ledger
entries. It performs no git mutations. Run it before starting work to see whose
toes you're about to step on.

## What gets installed

```
AGENTS.md                        rules      seeded once; only the marked ledger block is re-synced
AI_HANDOFF.md                    state      seeded once; never overwritten
AI_WORKSPACE.md                  pointer
CLAUDE.md / GEMINI.md / CHATGPT.md  pointers
.githooks/pre-commit             local enforcement
scripts/ai-sync-install.sh       enable hooks (once per clone)
scripts/ai-sync-status.sh        cross-worktree stranded-work view
scripts/ai-sync-ci-check.sh      CI mirror of the hook's classification
.github/workflows/ai-sync.yml    PR enforcement
```

**Managed files** are rewritten from `templates/` on every run — that's what
makes re-running a repair. **Content files** (`AGENTS.md`, `AI_HANDOFF.md`) are
seeded once and never clobbered. In an existing `AGENTS.md`, only the region
between `<!-- AI-SYNC-LEDGER:BEGIN -->` and `<!-- AI-SYNC-LEDGER:END -->` is
replaced, so hand-written architecture and command sections survive upgrades.

## Notes from the field

**Script directory casing.** Xcode projects conventionally use `Scripts/`;
everything else uses `scripts/`. The installer detects which by asking git what
casing it *tracks*, then falling back to `find`, which string-compares the real
directory entry. It never tests with `[ -d Scripts ]` — on macOS's
case-insensitive APFS that is true even when the real directory is `scripts/`,
which makes detection flip-flop and rewrite files on every run.

**`ai-sync-install.sh` is per-clone, not per-repo.** It sets
`core.hooksPath=.githooks`, which is local git config — it does not travel with
a clone. Every fresh clone needs it run once. It is shared across all linked
worktrees, and it refuses to stomp an existing `core.hooksPath` (husky, etc.)
unless you pass `AISYNC_FORCE=1`.

**The hook is a reminder, not a gate.** `--no-verify` exists and agents will
find it. The CI check is the real boundary; the hook just moves the correction
from review time to commit time.

## License

MIT

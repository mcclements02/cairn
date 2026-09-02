# Cairn

> A cairn is a stack of stones left by earlier travelers to mark the trail for
> whoever comes next. You add one stone. You don't rearrange the others.

A cross-agent coordination protocol for repositories worked by more than one AI
coding agent — and a one-command installer that adds it to any repo.

When Claude, Codex, Gemini and Copilot all have write access to the same
project, the failure mode isn't bad code. It's **stranded work**: an agent
finishes something on a branch nobody else knows about, a second agent
re-implements it, a third rewrites the first one's fix. Chat context doesn't
survive the session, and no agent can read another's.

Cairn fixes that with a single rule, enforced mechanically:

> **Every commit that touches code must also update the shared ledger.**

State lives in the repo, on the branch, in the diff — so it merges, survives
handoffs, and is readable by whichever agent shows up next.

## Install

```sh
git clone https://github.com/<you>/cairn.git ~/.cairn
cd /path/to/your/repo && ~/.cairn/cairn init
```

```
cairn init   [--force] [--scripts-dir DIR] [PATH]   install or re-sync a repo
cairn check  [PATH]                                 report drift; exit 1 if any
cairn status [PATH]                                 cross-worktree stranded work
cairn hooks  [PATH]                                 enable hooks in this clone
cairn help
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

**CI** — `.github/workflows/cairn.yml` runs the same classification on every
PR. The local bypass is invisible to reviewers; the CI bypass is the
**`skip-ledger`** label — deliberate, attributable, and visible in the PR
timeline.

**Visibility** — `cairn-status.sh` reports every worktree, its dirty count,
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
scripts/cairn-hooks.sh       enable hooks (once per clone)
scripts/cairn-status.sh        cross-worktree stranded-work view
scripts/cairn-check.sh      CI mirror of the hook's classification
.github/workflows/cairn.yml    PR enforcement
.cairnignore                  optional; paths this repo customizes on purpose
```

**Managed files** are rewritten from `templates/` on every run — that's what
makes re-running a repair. **Content files** (`AGENTS.md`, `AI_HANDOFF.md`) are
seeded once and never clobbered. In an existing `AGENTS.md`, only the region
between `<!-- Cairn-LEDGER:BEGIN -->` and `<!-- Cairn-LEDGER:END -->` is
replaced, so hand-written architecture and command sections survive upgrades.

## Protecting a deliberate local change

Some repos customize a managed file on purpose. A project that commits runtime
artifacts — model outputs, captured fixtures, evidence checkpoints — may need
the hook to stop counting those as code, because such a commit carries no ledger
entry by design. Without the exemption the operator learns to reach for
`--no-verify`, which is how a guard stops guarding.

Overwriting a considered change like that is worse than leaving it drifted. List
the path in `.cairnignore` at the repo root:

```
# deliberately customized — runtime-state exemption, mirrored in ci-check
.githooks/pre-commit
scripts/cairn-check.sh
```

Ignored paths are neither rewritten nor reported as drift.

## Platforms

macOS, Linux, and Windows under **Git Bash** (ships with Git for Windows) or
**WSL**. It needs bash plus the coreutils that come with git — no runtime, no
package manager, nothing to install.

It does not run in `cmd.exe` or PowerShell directly. The git hook it installs is
invoked by git itself, which uses its bundled `sh` on Windows, so hooks work
regardless of which shell you drive git from.

Line endings are pinned to LF via `.gitattributes`, and the installer strips
`\r` from templates on the way out. Without both, a default Windows checkout
(`core.autocrlf=true`) rewrites the scripts to CRLF and bash dies on the stray
carriage return with `set: pipefail: invalid option name`.

## Migrating from a pre-rename install

`cairn init` detects the old `ai-sync-*` layout and moves it — with `git mv`
where the files are tracked, so history follows:

```
scripts/ai-sync-install.sh   -> scripts/cairn-hooks.sh
scripts/ai-sync-status.sh    -> scripts/cairn-status.sh
scripts/ai-sync-ci-check.sh  -> scripts/cairn-check.sh
.github/workflows/ai-sync.yml -> .github/workflows/cairn.yml
.ai-sync-ignore              -> .cairnignore
```

`AGENTS.md`'s `AI-SYNC-LEDGER` markers are rewritten to `CAIRN-LEDGER` in place,
so the block is upgraded rather than duplicated.

In `AI_HANDOFF.md`, **only the header is retargeted.** Everything from `## Log`
down is append-only history and is left byte-for-byte alone — a stale script
path inside a 2026-07 entry is *correct*, because that is what the command was
called when the entry was written. A tool that enforces append-only has no
business rewriting the past.

If you have a required status check named "AI-SYNC ledger check" in branch
protection, rename it to "Cairn ledger check" after the first PR lands.

## Notes from the field

**Script directory casing.** Xcode projects conventionally use `Scripts/`;
everything else uses `scripts/`. The installer detects which by asking git what
casing it *tracks*, then falling back to `find`, which string-compares the real
directory entry. It never tests with `[ -d Scripts ]` — on macOS's
case-insensitive APFS that is true even when the real directory is `scripts/`,
which makes detection flip-flop and rewrite files on every run.

**`cairn-hooks.sh` is per-clone, not per-repo.** It sets
`core.hooksPath=.githooks`, which is local git config — it does not travel with
a clone. Every fresh clone needs it run once. It is shared across all linked
worktrees, and it refuses to stomp an existing `core.hooksPath` (husky, etc.)
unless you pass `AISYNC_FORCE=1`.

**The hook is a reminder, not a gate.** `--no-verify` exists and agents will
find it. The CI check is the real boundary; the hook just moves the correction
from review time to commit time.

## License

MIT

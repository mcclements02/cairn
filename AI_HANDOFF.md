# cAIrn Project Handoff

**Version:** 5 · **Last updated:** 2026-10-04 · **Updated by:** Codex

Repository state for contributors to cAIrn itself. The installable ledger template
is `templates/AI_HANDOFF.md`; this file records work on the installer.

## Active Work

| Branch | Worktree | Actor / runtime / model | Status | Summary | Updated |
|--------|----------|-------------------------|--------|---------|---------|
| main | . | Codex | blocked | Core submission awaits eligibility, local checks, and human review; stable release and tap package complete | 2026-10-04 |

## Log (append newest on top)

### 2026-10-04 · main · Codex
- **Changed:** Completed stable release/tap preparation and saved the honest
  Homebrew PR draft in docs/homebrew-submission.txt. Created the preparation fork
  mcclements02/homebrew-core and local branch codex/cairn-0.1.0 with the formula
  at /private/tmp/cairn-homebrew-core/Formula/c/cairn.rb; it is uncommitted and
  unpushed under core's requirement that local checks pass before submission.
- **Validation:** v0.1.0 source integration tests passed on macOS/Linux (run
  37219780464). Homebrew source install, package test, style, and strict audit
  passed on both clean runners (run 37220527793). Local brew style passed after
  repairs. Homebrew's SharedAudits.github self-submission check returned:
  "Self-submitted GitHub repository not notable enough (<90 forks, <90 watchers
  and <225 stars)". Local install/new-audit still require updated Command Line
  Tools. No official-catalog acceptance or full new-formula audit pass is claimed.
- **Status:** stable release and custom tap published; core submission blocked.
- **Next:** Establish public-interest eligibility or a documented exception;
  update the local macOS developer tools and complete core's local checks; have
  the human contributor review the generated formula/PR text before requesting
  Homebrew maintainer review. The human must handle subsequent review responses
  without AI. Unrelated local .agents/ and skylar project/ content is untouched.

### 2026-10-04 · main · Codex
- **Changed:** Corrected Homebrew's drift fixture to use Ruby File.write; the
  Homebrew Pathname.write helper intentionally refuses an existing file.
  Created mcclements02/homebrew-core as a preparation fork; no core PR opened.
- **Validation:** Clean macOS Homebrew installation succeeded in run
  37220308479. Its package test reached init and check before the fixture-write
  error above; revised package checks remain pending. Linux job is still running.
- **Status:** formula test repair in progress; source release remains unchanged.
- **Next:** Run the corrected Homebrew package checks and prepare an accurate
  submission checklist with unresolved eligibility and local CLT requirements.

### 2026-10-04 · main · Codex
- **Changed:** Added clean-runner Homebrew package validation on macOS and Linux,
  and adopted the Homebrew formula path helper required by its style checker.
- **Validation:** Local Homebrew fetched and verified the stable archive, but
  installation and audit stopped because the host Command Line Tools are older
  than Homebrew requires. Style identified the path helper correction above;
  its recheck and clean-runner install/test/style/audit are pending.
- **Status:** package validation in progress; v0.1.0 source tests passed.
- **Next:** Follow the Homebrew workflow results, fix concrete formula failures,
  and record the remaining catalog eligibility and human review requirements.

### 2026-10-04 · main · Codex
- **Changed:** Published stable GitHub release v0.1.0 from commit fff29f4.
  Added its archive URL and SHA-256 to Formula/cairn.rb and documented stable
  custom-tap installation without --HEAD. Trusted only the cAIrn formula locally
  for Homebrew package testing.
- **Validation:** Final local smoke tests passed. GitHub Actions run 37219780464
  passed shell syntax and integration tests on macos-latest and ubuntu-latest.
  Downloaded the tagged source archive and verified that it excludes unrelated
  local files; SHA-256 is recorded in the formula. Full brew install/test/audit
  remains pending.
- **Status:** stable source released; package validation in progress.
- **Next:** Validate the stable formula with Homebrew, prepare the official PR
  material, and report the eligibility gap without claiming catalog acceptance.

### 2026-10-04 · main · Codex
- **Changed:** Agent-neutral onboarding in README and templates; compaction and
  skill scaffolding with guarded paths; resolved-entry retention and preview;
  CI classifier argument handling; VERSION, CHANGELOG, Homebrew formula, and
  macOS/Linux integration workflow. Includes the pre-existing, uncommitted
  installer feature work requested for release. Unrelated local `.agents/` and
  `skylar project/` content remains outside the release.
- **Validation:** macOS smoke tests passed after the compaction/checker fixes;
  Bash and Ruby syntax checks and `git diff --check` passed. Final version test,
  GitHub macOS/Linux jobs, and full Homebrew install/audit are still pending.
- **Status:** release preparation in progress; no release published yet.
- **Next:** Validate the final source, publish tested 0.1.0, and finish stable
  formula validation. Homebrew owner-submission eligibility is not met: GitHub
  metadata checked on 2026-10-04 reports 0 stars, 0 forks, and 0 watchers.
  Official review requires the human contributor to review generated material
  and personally handle maintainer questions under Homebrew's contribution rules.

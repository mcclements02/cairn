# cAIrn Project Handoff

**Version:** 3 · **Last updated:** 2026-10-04 · **Updated by:** Codex

Repository state for contributors to cAIrn itself. The installable ledger template
is `templates/AI_HANDOFF.md`; this file records work on the installer.

## Active Work

| Branch | Worktree | Actor / runtime / model | Status | Summary | Updated |
|--------|----------|-------------------------|--------|---------|---------|
| main | . | Codex | in progress | Prepare 0.1.0 release and Homebrew distribution | 2026-10-04 |

## Log (append newest on top)

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

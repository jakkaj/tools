# Fix Tasks — Plan Domain System (Simple Mode)

Apply in order. Re-run manual verification after each block.

## 1) CRITICAL blockers

### FT-001 — Restore extract-domain command identity
- **Severity**: CRITICAL
- **Files**:
  - `/home/jak/github/tools/agents/v2-commands/plan-v2-extract-domain.md`
  - `/home/jak/github/tools/agents/v2-commands/README.md`
  - `/home/jak/github/tools/src/jk_tools/agents/v2-commands/*`
- **Issue**: Source file name conflicts with plan/spec expectations (`extract-domain.md`).
- **Fix**:
  1. Rename `plan-v2-extract-domain.md` → `extract-domain.md`.
  2. Update README command table and references.
  3. Re-sync dist so source and `src/jk_tools` match exactly.
- **Patch hint**:
  ```diff
  - | `plan-v2-extract-domain` | *(new)* | ...
  + | `extract-domain` | *(new)* | ...
  - See `plan-v2-extract-domain.md` ...
  + See `extract-domain.md` ...
  ```
- **Manual verification**:
  - `ls agents/v2-commands` contains `extract-domain.md` and not `plan-v2-extract-domain.md`.
  - `ls src/jk_tools/agents/v2-commands` mirrors the same filename set.

### FT-002 — Rebuild graph traceability artifacts for this phase
- **Severity**: CRITICAL
- **Files**:
  - `/home/jak/github/tools/docs/plans/015-plan-domain-system/plan-domain-system-plan.md`
- **Issue**: No task footnote tags and no Change Footnotes Ledger, so graph-integrity gate fails.
- **Fix**:
  1. Add `[^N]` references to completed task rows in Notes.
  2. Add a `Change Footnotes Ledger` section with sequential `[^1..]`.
  3. Add per-footnote node/file references for all diff-touched files.
- **Manual verification**:
  - Completed tasks contain `[^N]`.
  - Ledger exists, sequential numbering has no gaps/duplicates.

## 2) HIGH-priority fixes

### FT-003 — Remove Footnote concept from v2 progress command
- **Severity**: HIGH
- **File**: `/home/jak/github/tools/agents/v2-commands/plan-6a-v2-update-progress.md`
- **Issue**: AC8/Q2 contradiction.
- **Fix**: Delete footnote-ledger instructions and keep domain/task progress updates only.

### FT-004 — Remove residual PlanPak references from v2 command text
- **Severity**: HIGH
- **Files**:
  - `/home/jak/github/tools/agents/v2-commands/plan-2-v2-clarify.md`
  - `/home/jak/github/tools/agents/v2-commands/README.md`
- **Issue**: AC9 contradiction.
- **Fix**: Replace PlanPak wording with domain-only phrasing.

### FT-005 — Fix v2-aware idempotency accounting in installer
- **Severity**: HIGH
- **Files**:
  - `/home/jak/github/tools/install/agents.sh`
  - `/home/jak/github/tools/src/jk_tools/install/agents.sh`
- **Issue**: Copilot prompt count compares against v1-only baseline.
- **Fix**:
  1. Compute `total_expected = file_count + v2_count`.
  2. Use both `SOURCE_DIR` and `V2_SOURCE_DIR` in extra-file checks.

### FT-006 — Add hard failure handling to v2 Copilot CLI generation
- **Severity**: HIGH
- **Files**:
  - `/home/jak/github/tools/install/agents.sh`
  - `/home/jak/github/tools/src/jk_tools/install/agents.sh`
- **Issue**: Python heredoc failure can be silently masked.
- **Fix**: Wrap block in `if ! $PYTHON_CMD ...; then print_error ...; exit 1; fi`.

### FT-007 — Reconcile execution-log AC claims with artifact reality
- **Severity**: HIGH
- **File**: `/home/jak/github/tools/docs/plans/015-plan-domain-system/execution.log.md`
- **Issue**: AC8/AC9 marked ✅ while artifacts still violate both.
- **Fix**: Re-run verification after fixes and update AC lines with objective evidence.

## 3) MEDIUM / LOW follow-ups

### FT-008 — Remove v1 comparative wording inside v2 command body
- **Severity**: MEDIUM
- **File**: `/home/jak/github/tools/agents/v2-commands/plan-5-v2-phase-tasks-and-brief.md`
- **Fix**: Rephrase introduction without referencing v1.

### FT-009 — Include v2 commands in local Copilot CLI generation path
- **Severity**: MEDIUM
- **Files**:
  - `/home/jak/github/tools/install/agents.sh`
  - `/home/jak/github/tools/src/jk_tools/install/agents.sh`
- **Fix**: In `--commands-local copilot-cli`, generate agents from both v1 and v2 dirs.

### FT-010 — Capture durable manual evidence artifacts for AC checks
- **Severity**: MEDIUM
- **Files**:
  - `/home/jak/github/tools/docs/plans/015-plan-domain-system/execution.log.md`
  - `/home/jak/github/tools/docs/plans/015-plan-domain-system/reviews/` (evidence references)
- **Fix**:
  1. Capture exact command outputs for sync/install verification.
  2. Record resulting file listings for each target path.
  3. Link evidence per AC to raise confidence above 75%.

### FT-011 — Minor installer hygiene cleanup
- **Severity**: LOW
- **Files**:
  - `/home/jak/github/tools/install/agents.sh`
  - `/home/jak/github/tools/src/jk_tools/install/agents.sh`
- **Fixes**:
  - Parenthesize `find ... -name ... -o -name ...` expressions.
  - Optionally sanitize echoed filenames in logs.

## 4) Re-review gate checklist (Manual approach)

- [ ] `extract-domain.md` naming is canonical and synchronized source↔dist
- [ ] No Footnote concept in v2 command set
- [ ] No PlanPak references in v2 command set
- [ ] Installer idempotency and failure behavior fixed for v2 paths
- [ ] Execution log AC statuses reflect actual artifacts
- [ ] Footnote/ledger graph gate satisfied for plan review artifacts
- [ ] Re-run `/plan-7-v2-code-review` and achieve zero HIGH/CRITICAL findings

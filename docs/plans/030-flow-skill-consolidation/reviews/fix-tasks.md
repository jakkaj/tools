# Fix Tasks: Simple Mode

Apply in order. Re-run review after fixes.

## Critical / High Fixes

### FT-001: Move plan-complete ownership back to merge
- **Severity**: HIGH
- **File(s)**: /Users/jordanknight/github/tools/skills/SDD/the-flow/references/stages/61-implement-companion.md
- **Issue**: Stage 61 fires `/eng-harness-flow --event plan-complete --json` after the companion debrief and only routes to the next phase. The consolidated routing contract says plan-complete fires inside stage 80 after merge execution.
- **Fix**: Remove the plan-complete seam from stage 61. After a final companion-reviewed phase, route to `/the-flow 8 --plan "<PLAN_DIR>"`. Keep `/the-flow 5 --phase "<Phase N+1>" --plan "<PLAN_PATH>"` only when another phase remains.
- **Patch hint**:
  ```diff
  - If this was the final phase of the plan, follow with `/eng-harness-flow --event plan-complete --json`
  - after the debrief -- the router owns the long-horizon reflection.
  + If this was the final phase of the plan, the next step is merge analysis:
  + `/the-flow 8 --plan "<PLAN_DIR>"`. Stage 80 owns the plan-complete harness seam
  + after merge execution.
  ```

### FT-002: Branch architect READY next step by Mode
- **Severity**: HIGH
- **File(s)**: /Users/jordanknight/github/tools/skills/SDD/the-flow/references/stages/30-architect.md
- **Issue**: Stage 30 always tells READY users to run `/the-flow 5`, but Simple Mode plans have inline tasks and should go directly to `/the-flow 6`.
- **Fix**: In both terminal output and trailing next-step text, branch on detected mode/status: Simple READY -> `/the-flow 6 --plan "<PLAN_PATH>"`; Full READY -> `/the-flow 5 --phase "<first phase>" --plan "<PLAN_PATH>"`; DRAFT stays as re-run `/the-flow 3` after fixes.
- **Patch hint**:
  ```diff
  - [If READY]
  - Next: /the-flow 5 <same flags> (module references/stages/50-phase-tasks.md)
  + [If READY + Simple Mode]
  + Next: /the-flow 6 --plan "<PLAN_PATH>" (module references/stages/60-implement.md)
  +
  + [If READY + Full Mode]
  + Next: /the-flow 5 --phase "<Phase 1: ...>" --plan "<PLAN_PATH>" (module references/stages/50-phase-tasks.md)
  ```

## Medium / Low Fixes

### FT-003: Remove live retired command references
- **Severity**: MEDIUM
- **File(s)**:
  - /Users/jordanknight/github/tools/README.md
  - /Users/jordanknight/github/tools/INSTALL.md
  - /Users/jordanknight/github/tools/skills/SDD/plan-2b-v2-prep-issue/SKILL.md
  - /Users/jordanknight/github/tools/skills/SDD/code-concept-search-v2/SKILL.md
  - /Users/jordanknight/github/tools/skills/SDD/plan-0-v2-constitution/SKILL.md
- **Issue**: Active docs/utilities still reference deleted `/plan-*` commands or stale SDD skill counts.
- **Fix**: Rewrite active guidance to `/the-flow <id|name>` and update `INSTALL.md` to 13 SDD skills (1 main flow + 12 utilities). Historical notes are acceptable only when clearly labelled historical.
- **Patch hint**:
  ```diff
  - Run /plan-1b-v2-specify first.
  + Run /the-flow 1b first.

  - the plan is consumable by /plan-5
  + Full Mode plans continue to /the-flow 5; Simple Mode plans continue to /the-flow 6
  ```

### FT-004: Expand the Domain Manifest to match changed files
- **Severity**: MEDIUM
- **File(s)**: /Users/jordanknight/github/tools/docs/plans/030-flow-skill-consolidation/flow-skill-consolidation-plan.md
- **Issue**: The manifest omits changed non-plan files such as README.md, INSTALL.md, `scripts/sync-to-dist.sh`, and utility SKILL.md reference updates.
- **Fix**: Add rows under `sdd-pipeline-skills` for every changed non-plan implementation/doc file, or revert out-of-manifest edits.
- **Patch hint**:
  ```diff
  + | `README.md`, `INSTALL.md` | sdd-pipeline-skills | internal | Catalog/reference wording updated to the consolidated `/the-flow` surface |
  + | `scripts/sync-to-dist.sh` | sdd-pipeline-skills | internal | Sync no longer handles the removed `.vscode/` mirror |
  + | `skills/SDD/{code-concept-search-v2,plan-0-v2-constitution,plan-2b-v2-prep-issue,util-0-v2-handover}/SKILL.md` | sdd-pipeline-skills | internal | Utility cross-reference wording updated to current stage names |
  ```

### FT-005: Add concrete behavioural evidence to the execution log
- **Severity**: MEDIUM
- **File(s)**: /Users/jordanknight/github/tools/docs/plans/030-flow-skill-consolidation/execution.log.md
- **Issue**: Some validation entries are summarized rather than reproducible, especially direct/guided module-load checks, grep/parity checks, and deploy/orphan/doctor outputs.
- **Fix**: Paste exact commands and key stdout/counts for T011-T013. The current review can then cite command evidence instead of prose assertions.
- **Patch hint**:
  ```diff
  + Command: <exact command>
  + Output:
  + ```text
  + <key lines proving module-load set / grep count / orphan state>
  + ```
  ```

## Re-Review Checklist

- [ ] All critical/high fixes applied
- [ ] Active retired `/plan-*` command references removed or explicitly marked historical
- [ ] Domain Manifest covers every changed non-plan implementation/doc file
- [ ] Execution log includes concrete behavioural evidence
- [ ] Re-run `/the-flow 7` and achieve zero HIGH/CRITICAL findings

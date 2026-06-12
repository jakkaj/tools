# Fix Tasks: Simple Mode

Apply in order. Re-run review after fixes.

## Critical / High Fixes

### FT-001: Make the flow-architecture lint catch forbidden next-step forms
- **Severity**: HIGH
- **File(s)**: /Users/jordanknight/github/tools/scripts/check-flow-architecture.sh
- **Issue**: L1 reports green while sub-skills contain `## Next Steps`; the pattern only matches singular/case-sensitive `Next step` forms.
- **Fix**: Make next-step detection case-insensitive and plural/bold-label aware. Add a negative self-test fixture for `## Next Steps`.
- **Patch hint**:
  ```diff
  - \*\*Next routing\*\*|^## Next routing|^Next step|^## Next step
  + \*\*Next routing\*\*|^## Next routing|\*\*Next steps?\*\*|^## Next steps?|^Next steps?
  ```

### FT-002: Remove or reframe remaining sub-skill `Next Steps` sections
- **Severity**: HIGH
- **File(s)**:
  - /Users/jordanknight/github/tools/skills/SDD/the-flow/references/stages/10-explore.md
  - /Users/jordanknight/github/tools/skills/SDD/the-flow/references/stages/80-merge.md
- **Issue**: `10-explore.md` says specification comes next; `80-merge.md` uses a forbidden next-step marker even though the PROCEED/ABORT gate itself is valid.
- **Fix**: In explore, replace with neutral artifact handoff/consumer notes. In merge, rename/split to gate-specific wording such as `## PROCEED/ABORT execution gate` and `## Recovery commands`, preserving the required PROCEED/ABORT wording.
- **Patch hint**:
  ```diff
  - ## Next Steps
  + ## Artifact Handoff
  ...
  - - Pre-Plan: specification comes next (the specify verb consumes this dossier)
  + - Pre-Plan: this dossier is ready for whichever consumer the parent flow selects.
  ```

## Medium / Low Fixes

### FT-003: Tighten L3 rendered-command conformance
- **Severity**: MEDIUM
- **File(s)**: /Users/jordanknight/github/tools/scripts/check-flow-architecture.sh
- **Issue**: L3 accepts `/the-flow 6` in bannered views and ignores `/the-flow implement`.
- **Fix**: Detect both id-led and verb-led command literals. For bannered views, require both id and verb and validate the pair against the Registry. Add negative self-tests for id-only and verb-only rendered commands.
- **Patch hint**:
  ```diff
  - if [[ -z "${row_verb}" ]]; then
  + if [[ -z "${cverb}" ]]; then
  +     l3_violation "${rel}:${ln} view literal \`${cmd}\` is missing the Registry verb"
  + elif [[ -z "${row_verb}" ]]; then
  ```

### FT-004: Clean stale routing, seam, and deleted-stage prose
- **Severity**: MEDIUM
- **File(s)**:
  - /Users/jordanknight/github/tools/skills/SDD/the-flow/references/stages/60-implement.md
  - /Users/jordanknight/github/tools/skills/SDD/the-flow/references/stages/20-specify.md
  - /Users/jordanknight/github/tools/skills/SDD/the-flow/references/stages/62-progress.md
  - /Users/jordanknight/github/tools/skills/SDD/the-flow/references/coach.md
- **Issue**: The implementation still says "Suggest next step", assigns post-spec to "Next steps", names deleted `61-implement-companion.md`, and says "Stage 60/61".
- **Fix**: Reword these to Graph-owned routing and current implement/merge seam ownership.
- **Patch hint**:
  ```diff
  - STOP: Report phase complete. Suggest next step.
  + STOP: Report phase complete. Routing is the flow's job.
  ```

### FT-005: Reconcile AC7/AC13 wording with actual literal census
- **Severity**: MEDIUM
- **File(s)**:
  - /Users/jordanknight/github/tools/docs/plans/031-skills-flow-architecture/skills-flow-architecture-plan.md
  - /Users/jordanknight/github/tools/docs/plans/031-skills-flow-architecture/skills-flow-architecture-spec.md
- **Issue**: The checklist says literals exist only in grammar + bannered views, while the execution log authorizes a marker-exempt State-write quotation and flight-plan JSON/schema durable-state data.
- **Fix**: Either update AC7/AC13 to explicitly include these authorized classes, or remove/slot the literals so the original wording becomes true.
- **Patch hint**:
  ```diff
  - literals only in (a) the Grammar definition and (b) banner-marked rendered views
  + literals only in authorized classes recorded by the census: Grammar definition,
  + banner-marked rendered views, marker-exempt frozen quotations, and durable-state examples
  ```

## Re-Review Checklist

- [x] All critical/high fixes applied
- [x] `just check-flow` fails before removing planted negative-test leaks and passes after removal
- [x] `grep -rnE '^## Next Steps|\\*\\*Next steps?\\*\\*|Stage 60/61|61-implement-companion' skills/SDD/the-flow` has no stale or unauthorized hits
- [x] AC7/AC13 wording matches the actual literal census
- [ ] Re-run this review verb and achieve zero HIGH/CRITICAL findings

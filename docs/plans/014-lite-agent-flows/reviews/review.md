# Review Report — 014-lite-agent-flows

## A) Verdict
**REQUEST_CHANGES**

- Mode/artifact conflict: plan declares `Mode: Full`, but review invocation omitted `--phase` and repository contains no `tasks/<phase>/tasks.md` dossier structure.
- High/Critical findings exist across graph integrity, semantic spec compliance, security, and regression checks.
- Strict mode not provided; verdict is blocking even in non-strict mode due CRITICAL/HIGH findings.

## B) Summary
1. Canonical diff reviewed: `HEAD^..HEAD` (`/home/jak/github/tools/scratch/014-lite-agent-flows.diff`).
2. Graph integrity is **BROKEN** (missing phase dossiers, missing task↔log backlinks/anchors, missing subtask registry).
3. Cross-phase regression guard failed: 2/7 rerun checks failed (AC6 and AC15 grep gates).
4. Semantic compliance failed on core spec contract (directory path mismatch vs spec AC1/G1).
5. Scope creep detected: `AGENTS.md` and `CLAUDE.md` changed without plan task-level classification.
6. Safety analysis score: **-364/100** (CRITICAL:1 HIGH:6 MEDIUM:6 LOW:2).
7. Testing approach detected: **Lightweight**; mock policy not explicitly selected (governance gap).
8. Fix list created: `reviews/fix-tasks.md`.

## C) Checklist
**Testing Approach: Lightweight**

- [x] Core validation checks executed (grep/file-count/full-pipeline-diff)
- [ ] Critical paths fully covered (AC6, AC10, AC14, AC15 fail/partial)
- [ ] Mock usage policy explicit and enforceable (not selected)
- [x] Key verification points documented (`execution.log.md` + rerun evidence)

**Universal**
- [ ] BridgeContext/explicitness patterns followed (relative-path example and placeholder absolute paths remain)
- [ ] Only in-scope files changed (`AGENTS.md`, `CLAUDE.md` are out-of-scope)
- [x] Project-native checks run (plan-defined grep checks rerun)
- [ ] Full/phase traceability artifacts intact (missing Full-mode dossiers and backlinks)

## D) Findings Table
| ID | Severity | File:Lines | Summary | Recommendation |
|----|----------|------------|---------|----------------|
| F001 | CRITICAL | `scratch/014-lite-agent-flows.diff:41-4744` | Lite files delivered to `agents/commands-lite/` not spec path `agents/commands/lite/` | Move/rename tree or rebaseline spec+plan to the delivered path |
| F002 | CRITICAL | `lite-agent-flows-plan.md` + `execution.log.md` | Full-mode traceability graph missing (no phase dossiers; no bidirectional metadata links) | Create phase dossiers + add task/log backlinks or switch plan metadata to Simple and align validators |
| F003 | HIGH | `agents/commands-lite/plan-6-implement-phase.md:~281` | AC6 regression: excluded-command grep matches `/TAD` token | Remove slash token shape (`TDD, TAD, Lightweight`) and rerun AC6 |
| F004 | HIGH | `agents/commands-lite/plan-3-architect.md:1005`, `plan-5-phase-tasks-and-brief.md` | AC15 regression: grep matches literal `[^` regex snippets | Rewrite examples or narrow AC15 regex to actual footnote syntax |
| F005 | HIGH | `agents/commands-lite/plan-3-architect.md:44-47` | Lite plan-3 still defaults/supports Full Mode | Force Simple Mode only for lite pipeline |
| F006 | HIGH | `agents/commands-lite/plan-5-phase-tasks-and-brief.md:274,289,705` | Lite plan-5 still writes/reads `PLAN_DIR/tasks/...` | Normalize to simple sibling layout per AC14 |
| F007 | HIGH | `agents/commands-lite/plan-7-code-review.md` | Review command still carries non-lite TAD/Hybrid/phase assumptions | Strip non-lite branches and keep lightweight-only rubric |
| F008 | HIGH | `AGENTS.md`, `CLAUDE.md` | Out-of-scope cross-plan edits not declared in manifest/tasks | Revert or explicitly classify as cross-cutting in plan artifacts |
| F009 | HIGH | `agents/commands-lite/plan-1a-explore.md:117-123` | Path resolution accepts broad slash inputs without confinement | Canonicalize and enforce subpath under `docs/plans` |
| F010 | HIGH | `agents/commands-lite/plan-6-implement-phase.md:77-82,306-309` | Blocked-task path can miss execution-log evidence | Require `[!]` tasks to write log anchor + failure log entry |
| F011 | HIGH | `agents/commands-lite/plan-5-phase-tasks-and-brief.md` | O(N²) prior-phase review fan-out risks scale failures | Cap concurrency and summarize older phases |
| F012 | HIGH | `agents/commands-lite/plan-7-code-review.md` | 3-5 validators + 5 reviewers always parallelized on same diff | Add staged triage and global concurrency cap |
| F013 | MEDIUM | `lite-agent-flows-plan.md:11,320-329` | Status remains DRAFT despite 4/4 phases complete | Reconcile status, AC checkboxes, and next-step guidance |
| F014 | MEDIUM | `lite-agent-flows-plan.md:295-296` | Mock policy options present but no selected policy | Choose explicit policy and enforce in review |
| F015 | MEDIUM | `GETTING-STARTED.md:19-22,88,125,134` | Mixed command naming (`/plan-6`, `/plan-7`) may break discoverability | Use canonical command names consistently |

## E) Detailed Findings

### E.0 Cross-Phase Regression Analysis
- Prior phases discovered: 1→4 in plan.
- Tests rerun: **7** (5 grep gates + file count + full-pipeline diff)
- Failures: **2** (AC6, AC15)
- Contracts broken: **2** (contamination gates no longer clean)
- Verdict: **FAIL**

| ID | Severity | Prior Phase | Issue | Evidence | Fix |
|----|----------|-------------|-------|----------|-----|
| REG-001 | HIGH | Phase 1/4 verification | AC6 now matches `/TAD` in plan-6-lite | `checks.txt` line 8 | Remove `/tad` token shape or tighten AC6 regex |
| REG-002 | HIGH | Phase 1/4 verification | AC15 now matches `[^` regex examples | `checks.txt` lines 11-12 | Rewrite examples or narrow AC15 regex |

### E.1 Doctrine & Testing Compliance

**Graph Integrity (Step 3a): ❌ BROKEN**
- Task↔Log: completed tasks missing `log#anchor`; execution log missing `Plan Task`/`Dossier Task` backlinks.
- Task↔Footnote: no footnote tags/ledger entries for modified-file tasks under full-rubric expectations.
- Plan↔Dossier: no `tasks/<phase>/tasks.md` dossiers found.
- Parent↔Subtask: no subtasks registry or parent/subtask backlink structure.

| ID | Severity | Link Type | Issue | Expected | Fix | Impact |
|----|----------|-----------|-------|----------|-----|--------|
| V1 | CRITICAL | Plan↔Dossier | No phase dossier files | `PLAN_DIR/tasks/<phase>/tasks.md` exists | Generate phase dossiers and sync statuses | Progress graph untestable |
| V2 | CRITICAL | Task↔Log | Log entries missing plan/dossier backlinks | `Plan Task` + `Dossier Task` metadata in each log task | Add bidirectional metadata links | No reverse traversal |
| V3 | HIGH | Task↔Log | Completed task rows missing `log#anchor` notes | Per-task notes include resolvable log anchors | Add anchors for all `[x]` rows | No forward traversal |
| V4 | HIGH | Task↔Footnote | No footnote ledger/stubs under full-rubric expectations | `[^N]` references resolve to ledger | Add ledger or formally switch to lite-simple rubric | Provenance gap |
| V5 | CRITICAL | Parent↔Subtask | Missing Subtasks Registry + links | Registry and parent/subtask backlinks | Add registry and links if subtasks used | Incomplete graph |

**Authority Conflicts (Step 3c):** No direct ledger conflicts detected (no footnote ledger exists); treated as structural gap handled in V4.

**Approach Validators (Step 4 + 5):**
- Mock policy unspecified (MEDIUM governance gap).
- Plan compliance failures: AC6/AC15 regressions, AC14/simple-mode inconsistencies, out-of-scope edits.
- PlanPak compliance failures: plan-scoped placement and cross-plan classification mismatches.

### E.2 Semantic Analysis
| Severity | File:Lines | Finding | Spec Requirement |
|----------|------------|---------|------------------|
| CRITICAL | Diff-wide | Output path mismatch (`commands-lite` vs `commands/lite`) | Spec G1 + AC1 |
| HIGH | `plan-3-architect.md:44-47` | Full Mode retained/defaulted | Spec NG8, G10 |
| HIGH | `plan-5-phase-tasks-and-brief.md` | `tasks/` subdir contract retained | Spec AC14, NG8 |
| HIGH | `plan-6-implement-phase.md` | Non-lite testing/path branches retained | Spec G5, AC14 |
| HIGH | `plan-7-code-review.md` | Non-lite review branches retained | Plan Phase-2 AC (`no TAD/PlanPak validators`) |
| MEDIUM | `plan-3-architect.md`, `plan-5...md` | AC15 false-positive surface left in docs | Spec AC15 |

### E.3 Quality & Safety Analysis
**Safety Score: -364/100** (CRITICAL: 1, HIGH: 6, MEDIUM: 6, LOW: 2)  
**Verdict: REQUEST_CHANGES**

**Correctness**
- HIGH: blocked tasks can skip execution-log evidence (`plan-6-implement-phase.md`).
- MEDIUM: timestamp format not normalized; metrics block not machine-readable.

**Security**
- HIGH: unconfined plan path handling in `plan-1a-explore.md`.
- MEDIUM: similar path-normalization risk in `plan-2c-workshop.md`.

**Performance**
- HIGH: unbounded parallel reviewer fan-out in `plan-7-code-review.md`.
- HIGH: O(N²) prior-phase validation pattern in `plan-5-phase-tasks-and-brief.md`.

**Observability**
- CRITICAL: per-phase contract ambiguity in plan-6 reviewable state model.
- HIGH: plan-7 forced single-phase assumptions in per-phase flow.
- MEDIUM: command-name mismatch in quick-start reduces operability.

### E.4 Doctrine Evolution Recommendations (Advisory)

| Category | New | Updates | Priority HIGH |
|----------|-----|---------|---------------|
| ADRs | 3 | 0 | 2 |
| Rules | 4 | 0 | 2 |
| Idioms | 4 | 0 | 2 |
| Architecture | 4 | 0 | 3 |

Top recommendations:
1. Add ADR for Full-vs-Lite dual-pipeline governance and divergence policy.
2. Add ADR/rule for lite isolation boundary (not synced/installed/distributed).
3. Add CI contamination checks for AC3/4/5/6/15 as mandatory.
4. Add doctrine baseline files (`docs/project-rules/rules.md`, `idioms.md`, `architecture.md`).

## F) Coverage Map (Acceptance Criteria ↔ Evidence)
| AC | Evidence Source | Confidence | Result | Notes |
|----|-----------------|------------|--------|-------|
| AC1 | `checks.txt` file count = 12 | 100% | PASS | Explicit command rerun |
| AC2 | `checks.txt` full pipeline diff lines = 0 | 100% | PASS | Explicit command rerun |
| AC3 | `checks.txt` AC3 grep | 100% | PASS | Zero matches |
| AC4 | `checks.txt` AC4 grep | 100% | PASS | Zero matches |
| AC5 | `checks.txt` AC5 grep | 100% | PASS | Zero matches |
| AC6 | `checks.txt` AC6 grep | 100% | **FAIL** | Match in `plan-6-implement-phase.md` |
| AC7 | Execution log T036 | 25% | PARTIAL | Not rerun directly; narrative evidence |
| AC8 | Diff + semantic review | 25% | PARTIAL | Inline tracking exists; non-lite branches remain |
| AC9 | Diff/grep evidence | 75% | PASS | No `/flowspace-research` found |
| AC10 | Plan compliance finding PLAN-004 | 25% | **FAIL** | plan-4 reference remains |
| AC11 | README inspection | 50% | PARTIAL | Present; not fully node-count validated |
| AC12 | GETTING-STARTED inspection | 50% | PARTIAL | Exists; command naming inconsistencies |
| AC13 | Execution log T039 | 50% | PARTIAL | Narrative-only evidence |
| AC14 | Semantic/plan compliance + `tasks/` refs | 100% | **FAIL** | Simple-layout contract violated in lite commands |
| AC15 | `checks.txt` AC15 grep | 100% | **FAIL** | `[^` regex examples trigger gate |

**Overall coverage confidence:** **73%** (MEDIUM).  
**Narrative evidence flags:** AC7, AC11, AC12, AC13 rely on narrative/manual confirmation.

## G) Commands Executed
```bash
git --no-pager status --short
git --no-pager log --oneline -n 20 -- docs/plans/014-lite-agent-flows agents/commands-lite
git --no-pager diff --unified=3 --no-color HEAD^..HEAD > scratch/014-lite-agent-flows.diff
git --no-pager show --name-status --format='' HEAD > scratch/014-lite-agent-flows.files

grep -riE 'flowspace|FlowSpace|fs2|flow_squared|flowspace-tree|flowspace-search|flowspace-get_node|flowspace-research' agents/commands-lite/*.md
grep -riE 'planpak|plan-pack|PlanPak|features/<' agents/commands-lite/*.md
grep -riE 'plan-ordinal|jk-po' agents/commands-lite/*.md
grep -riE '/plan-0-constitution|/plan-2-clarify|/plan-2b-prep-issue|/plan-3a-adr|/plan-4-complete-the-plan|/plan-5c-requirements-flow|/plan-6a-update-progress|/plan-6b-worked-example|/plan-8-merge|/planpak|/tad|/util-0-handover|/code-concept-search|/flowspace-research' agents/commands-lite/*.md
grep -riE 'footnote|Footnote|\[\^|Change Footnotes Ledger' agents/commands-lite/*.md
ls agents/commands-lite/*.md | wc -l
git --no-pager diff -- agents/commands/*.md | wc -l
```

## H) Decision & Next Steps
- **Decision owner:** plan author/maintainer for `014-lite-agent-flows`.
- **Required before approval:** resolve all CRITICAL/HIGH items in `reviews/fix-tasks.md`, rerun AC3/4/5/6/15 checks, and rerun `/plan-7-code-review`.
- **After fixes:** if zero HIGH/CRITICAL remain, mark APPROVE and proceed to next planned work.

## I) Footnotes Audit
No plan footnote ledger is present; no `[^N]` tags are associated with diff-touched files.

| Diff-Touched Path | Footnote Tag(s) in Plan | Node-ID Link(s) in Ledger |
|-------------------|-------------------------|----------------------------|
| AGENTS.md | none | none |
| CLAUDE.md | none | none |
| agents/commands-lite/GETTING-STARTED.md | none | none |
| agents/commands-lite/README.md | none | none |
| agents/commands-lite/deepresearch.md | none | none |
| agents/commands-lite/didyouknow.md | none | none |
| agents/commands-lite/plan-1a-explore.md | none | none |
| agents/commands-lite/plan-1b-specify.md | none | none |
| agents/commands-lite/plan-2c-workshop.md | none | none |
| agents/commands-lite/plan-3-architect.md | none | none |
| agents/commands-lite/plan-5-phase-tasks-and-brief.md | none | none |
| agents/commands-lite/plan-5b-flightplan.md | none | none |
| agents/commands-lite/plan-6-implement-phase.md | none | none |
| agents/commands-lite/plan-7-code-review.md | none | none |
| docs/plans/014-lite-agent-flows/execution.log.md | none | none |
| docs/plans/014-lite-agent-flows/lite-agent-flows-plan.md | none | none |
| docs/plans/014-lite-agent-flows/lite-agent-flows-spec.md | none | none |
| docs/plans/014-lite-agent-flows/research-dossier.md | none | none |
| docs/plans/014-lite-agent-flows/workshops/lite-pipeline-flow-architecture.md | none | none |
| docs/plans/014-lite-agent-flows/workshops/plan-3-research-subagent-rewrite.md | none | none |
| docs/plans/014-lite-agent-flows/workshops/plan-6-inline-progress-tracking.md | none | none |

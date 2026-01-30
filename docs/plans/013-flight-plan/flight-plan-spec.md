# Flight Plan: Pre-Implementation File Audit for plan-5 and plan-5a

**Mode**: Simple

## Research Context

- **Components affected**: `agents/commands/plan-5-phase-tasks-and-brief.md`, `agents/commands/plan-5a-subtask-tasks-and-brief.md`
- **Critical dependencies**: FlowSpace MCP (optional, enhances discovery), existing execution logs and plan task tables
- **Modification risks**: Low — additive sections to existing commands; no existing behavior changes
- **Link**: See `research-dossier.md` for full analysis

## Summary

Add a **Flight Plan** section to the output of `/plan-5` (tasks.md) and `/plan-5a` (subtask dossier). The Flight Plan is a pre-implementation audit that lists every file the phase will create or modify, verifies provenance (which plan created it, which plans modified it), checks for duplication (does a similar concept already exist in the codebase?), validates compliance with ADRs/rules/idioms/architecture, and provides actionable recommendations — all before a single line of code is written.

**Why**: Agents frequently re-create functionality that already exists, touch files without understanding their history, or make changes that violate project conventions. The Flight Plan is the "measure twice, cut once" gate — it calls every shot ahead of time and double-checks facts in the codebase before committing.

## Goals

- Agents declare every file they will touch before implementation begins
- Each file entry includes provenance: which plan created it, which plans subsequently modified it
- New files are checked against the codebase for similar concepts, methods, and classes to prevent duplication
- Planned changes are validated against ADRs, project rules, idioms, and architectural conventions as a final compliance gate
- Recommendations are surfaced (reuse existing, extract to shared, cross-plan edit, etc.) before plan-6 starts
- Works with both PlanPak (enhanced — folder names self-document origin) and Legacy file management
- Uses FlowSpace subagents when available, falls back to Explore subagents, falls back to inline Grep/Read

## Non-Goals

- Does not replace plan-7 code review (plan-7 validates what was actually written; Flight Plan validates what is planned)
- Does not modify how plan-6 implements tasks (plan-6 reads the Flight Plan for context but its execution rules are unchanged)
- Does not add new command files — this modifies two existing commands only
- Does not change the task table format or any other existing section of tasks.md
- Does not require FlowSpace to be installed — graceful degradation at every tier

## Complexity

- **Score**: CS-2 (small)
- **Breakdown**: S=1, I=0, D=0, N=1, F=0, T=0
  - S=1: Two files modified with parallel section additions
  - I=0: Internal to agent commands, no external service dependencies
  - D=0: No data/state changes
  - N=1: Some design judgment in subagent prompt wording and compliance check scope
  - F=0: Standard agent command conventions
  - T=0: Manual verification (run setup.sh, inspect output)
- **Confidence**: 0.85
- **Assumptions**:
  - Execution logs and plan task tables are the reliable sources of file provenance
  - FlowSpace detection pattern from flowspace-research.md is reusable
  - ADRs live in docs/adr/ and rules/idioms in docs/project-rules/ (when they exist)
- **Dependencies**: None (FlowSpace is optional enhancement)
- **Risks**: Subagent prompt may need iteration to produce concise, factual output
- **Phases**: Single phase — add Flight Plan section to both commands, run setup.sh

## Acceptance Criteria

1. **AC1**: `/plan-5` output (tasks.md) contains a `## Flight Plan` section between `## Objectives & Scope` and `## Architecture Map`
2. **AC2**: `/plan-5a` output (subtask dossier) contains the same `## Flight Plan` section in the equivalent position
3. **AC3**: The Flight Plan section contains a summary table with columns: File, Action, Origin Plan, Modified By, Recommendation
4. **AC4**: For each file marked as "Create", the Flight Plan includes a duplication check subsection reporting similar concepts found (or "None")
5. **AC5**: For each file marked as "Modify", the Flight Plan includes provenance: which plan created it and which plans subsequently modified it
6. **AC6**: The Flight Plan includes a `### Compliance Check` subsection that validates planned changes against ADRs (if docs/adr/ exists), project rules (if docs/project-rules/ exists), and architectural conventions
7. **AC7**: Compliance violations are reported as warnings with severity (HIGH/MEDIUM/LOW) and the specific rule/ADR violated
8. **AC8**: A subagent is launched to gather provenance, duplication, and compliance data — using FlowSpace when available, Explore subagent as fallback, inline Grep/Read as final fallback
9. **AC9**: PlanPak-aware: when PlanPak is active, provenance leverages `features/<ordinal>-<slug>/` folder names; when Legacy, falls back to execution log scanning
10. **AC10**: `./setup.sh` deploys successfully after changes (10/10)
11. **AC11**: Existing plan-5 and plan-5a behavior is unchanged when Flight Plan subagent returns no findings (empty Flight Plan section with "No findings" note)

## Risks & Assumptions

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Subagent returns verbose/noisy output | Medium | Low | Constrain output format in prompt; enforce "factual, not verbose" instruction |
| FlowSpace detection adds latency when unavailable | Low | Low | Fast fail with try/catch on tree() call; same pattern as flowspace-research.md |
| Execution logs use inconsistent path formats | Medium | Medium | Search for both absolute and relative paths; account for backtick wrapping (PL-02) |
| No ADRs or rules files exist in project | High | None | Each compliance check is conditional — skip gracefully if docs/adr/ or docs/project-rules/ absent |
| Flight Plan section makes tasks.md too long | Low | Medium | Keep table concise; per-file detail only when findings warrant it |

**Assumptions**:
- Execution logs exist for prior plans (at least some — empty history is a valid result)
- The agent running plan-5 has access to Task tool for launching subagents
- ADRs follow the convention of living in docs/adr/
- Rules and idioms follow the convention of docs/project-rules/rules.md and docs/project-rules/idioms.md

## Open Questions

- None — requirements are well-defined from the research dossier and user discussion.

## ADR Seeds (Optional)

None — this is an additive section to existing commands with no architectural choices to make.

## Workshop Opportunities

None — the design is straightforward (a new section with a subagent) and does not warrant detailed design exploration.

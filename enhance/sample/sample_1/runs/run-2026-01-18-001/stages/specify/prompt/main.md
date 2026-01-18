# specify Stage: Feature Specification

## Stage Context

You are executing a workflow stage. Before proceeding:

1. **Read stage configuration**: `../stage-config.yaml`
   - Understand declared inputs and expected outputs
   - Note any parameters passed from the prior stage (explore)
   - Review output_parameters you must publish

2. **Read your inputs**: Check `../inputs/` directory
   - `research-dossier.md` - Research report from explore stage
   - `findings.json` - Structured findings from explore stage
   - `params.json` - Resolved parameters (total_findings, critical_count, etc.)
   - `user-description.md` (if present) - Additional user context

3. **Your outputs go to**:
   - `../run/output-files/spec.md` - Feature specification document
   - `../run/output-data/spec-metadata.json` - Structured metadata
   - `../run/output-data/wf-result.json` - Stage completion status
   - `../run/runtime-inputs/read-files.json` - Files you read during execution

---

## Purpose

Create a feature specification from the research findings provided in your inputs.

## Your Inputs

Read these files from `../inputs/`:
- `research-dossier.md` - Comprehensive research with findings, dependencies, patterns
- `findings.json` - Structured findings data
- `user-description.md` (if present) - Additional user context

## Your Outputs

Write these files:
- `../run/output-files/spec.md` - The feature specification document
- `../run/output-data/spec-metadata.json` - Structured metadata (see schema)
- `../run/output-data/wf-result.json` - Stage completion status
- `../run/runtime-inputs/read-files.json` - Files you read during execution

## Specification Structure

Create `spec.md` with these sections (in order):

### 1. Title and Mode
```markdown
# <Feature Title>

**Mode**: Simple
```

### 2. Research Context
Summarize key findings from `research-dossier.md`:
- Components affected
- Critical dependencies
- Modification risks
- Link to research dossier

### 3. Summary
Short WHAT/WHY overview (2-3 sentences)

### 4. Goals
Bullet list of desired outcomes and user value. Informed by research findings.

### 5. Non-Goals
Explicitly out-of-scope behavior. Informed by research boundaries.

### 6. Complexity
Use the CS 1-5 scoring system:

| Dimension | Score 0-2 | Description |
|-----------|-----------|-------------|
| S (Surface) | Files touched | 0=one, 1=multiple, 2=cross-cutting |
| I (Integration) | External deps | 0=internal, 1=one external, 2=multiple |
| D (Data/State) | Schema changes | 0=none, 1=minor, 2=non-trivial |
| N (Novelty) | Clarity | 0=well-specified, 1=some ambiguity, 2=discovery |
| F (Non-Functional) | Perf/security | 0=standard, 1=moderate, 2=strict |
| T (Testing) | Test depth | 0=unit only, 1=integration, 2=staged rollout |

Total = S+I+D+N+F+T → CS mapping: 0-2=CS-1, 3-4=CS-2, 5-7=CS-3, 8-9=CS-4, 10-12=CS-5

Include:
- **Score**: CS-{1-5}
- **Total**: Sum of all dimension scores (0-12)
- **Breakdown**: S=X, I=X, D=X, N=X, F=X, T=X
- **Confidence**: 0.00-1.00
- **Assumptions**: List assumptions made
- **Dependencies**: External blockers
- **Risks**: Complexity-related risks
- **Phases** (CS-4+ only): Suggested implementation phases with feature flags and rollback plan

### 7. Acceptance Criteria
Numbered, testable scenarios:
```markdown
1. **AC-01**: [Observable outcome that can be tested]
2. **AC-02**: [Another testable scenario]
```

### 8. Risks & Assumptions

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|

### 9. Open Questions
List any unresolved questions as `[NEEDS CLARIFICATION: ...]` markers.

### 10. ADR Seeds (Optional)
If architectural decisions are implied:
- Decision Drivers
- Candidate Alternatives (A, B, C)
- Stakeholders

### 11. External Research (if applicable)
If `research-dossier.md` references external research that was incorporated:
- **Incorporated**: List external research sources used (from research-dossier.md)
- **Key Findings**: Summary of external insights that informed this spec
- **Applied To**: Which spec sections benefited

### 12. Unresolved Research (if applicable)
If `research-dossier.md` identified external research opportunities that weren't addressed:
- **Topics**: List unresolved opportunities from research-dossier.md
- **Impact**: How this uncertainty affects the spec
- **Recommendation**: "Consider addressing before architecture phase"

⚠️ If unresolved research exists, add a warning banner after the title:
```markdown
⚠️ **Unresolved Research Opportunities**
The following external research topics were identified but not addressed:
- [Topic 1]: [Brief description]
Consider running external research before finalizing architecture.
```

### 13. Phases (for CS-4+ only)
If complexity score is CS-4 or CS-5, include:
- **Suggested Phases**: High-level breakdown of implementation phases
- **Feature Flags**: Required feature flags for staged rollout
- **Rollback Plan**: How to safely rollback if issues arise

## Structured Output

Also write `spec-metadata.json` with the structured data. See `../schemas/spec-metadata.schema.json` for the required format.

Example:
```json
{
  "feature_name": "Workflow Composer CLI",
  "slug": "first-wf-build",
  "mode": "simple",
  "complexity": {
    "score": "CS-3",
    "total": 5,
    "breakdown": {"S": 1, "I": 1, "D": 1, "N": 1, "F": 0, "T": 1},
    "confidence": 0.85,
    "phases": null
  },
  "goals": ["Create compose command", "Create prepare-wf-stage command"],
  "acceptance_criteria": [
    {"id": "AC-01", "description": "compose creates run folder", "testable": true}
  ],
  "research": {
    "findings_incorporated": 15,
    "external_research_used": ["API best practices 2024"],
    "unresolved_topics": [],
    "unresolved_count": 0
  }
}
```

## Quality Gates

Before completing:
- [ ] All mandatory sections present in spec.md
- [ ] Acceptance criteria are testable (observable outcomes)
- [ ] Complexity score justified with breakdown
- [ ] Research findings referenced where applicable
- [ ] spec-metadata.json validates against schema
- [ ] No implementation details (no stack/framework choices)

## Completion

Write `wf-result.json`:
```json
{
  "status": "success",
  "completed_at": "2026-01-18T14:30:00Z",
  "stage_id": "specify",
  "error": null,
  "metrics": {
    "goals_count": 4,
    "acceptance_criteria_count": 7,
    "open_questions_count": 0,
    "research_findings_incorporated": 15
  }
}
```

Ensure `read-files.json` is complete (you've been writing to it as you read files).

# Workshop: Validate ↔ DidYouKnow Cross-Pollination

**Type**: Integration Pattern
**Plan**: 020-v2-command-cross-pollination
**Created**: 2026-04-12T05:55:00Z
**Status**: Draft

**Related Documents**:
- `agents/v2-commands/validate-v2.md`
- `agents/v2-commands/didyouknow-v2.md`

---

## Purpose

Design concrete improvements to validate-v2 by adopting proven patterns from didyouknow-v2. Both are post-action analysis tools examining artifacts through multiple lenses — validate focuses on *correctness*, DYK on *understanding*. Their lens frameworks and interaction patterns have complementary strengths.

## Key Questions Addressed

- Which DYK patterns would make validate more thorough without changing its character?
- How should validate's agent prompts be structured to ensure lens coverage?
- Should validate adopt DYK's conversational interaction model for any issue class?

---

## Current State Comparison

### What They Share

```
                    ┌─────────────────────────────────────────┐
                    │         Post-Action Analysis            │
                    │                                         │
                    │  • Auto-detect context from session     │
                    │  • Multiple analysis perspectives       │
                    │  • Produce actionable findings          │
                    │  • Work on any artifact type            │
                    └──────────────┬──────────────────────────┘
                                   │
                    ┌──────────────┴──────────────┐
                    │                             │
              ┌─────┴─────┐               ┌──────┴──────┐
              │  validate  │               │     DYK     │
              │            │               │             │
              │ "What's    │               │ "What don't │
              │  wrong?"   │               │  we see?"   │
              └────────────┘               └─────────────┘
```

### Key Differences

| Dimension | validate-v2 | didyouknow-v2 |
|-----------|------------|---------------|
| **Goal** | Verify correctness | Build understanding |
| **Mechanism** | Parallel subagents (GPT-5.4) | Single-agent deep thinking |
| **Interaction** | Batch report → auto-fix | 1-at-a-time → discuss each |
| **Output** | Severity-ranked issues | 5 insights for conversation |
| **Timing** | After action (verify) | Before/after (understand) |
| **Lenses** | Ad-hoc per category | 11 named, reusable lenses |
| **Persistence** | None (console only) | Appends record to analyzed doc |

---

## Opportunity 1: DYK's 11 Lenses as Validate's Coverage Checklist

### The Gap

Validate designs agents ad-hoc per artifact category. Each category has 3 hardcoded agent templates (e.g., "Source Truth Agent", "Cross-Reference Agent", "Completeness Agent" for tasks dossiers). This means:

- Agent lens design is reinvented each time
- Coverage gaps are invisible — no checklist to verify against
- Some DYK lenses are completely absent from validate (Hidden Assumptions, Concept Documentation, Deployment/Ops)

### DYK's 11 Lenses

```
┌──────────────────────────────────────────────────────────────────┐
│  DYK Analysis Lenses (from didyouknow-v2.md)                    │
│                                                                  │
│  1. User Experience         — what changes for users?            │
│  2. System Behavior         — new constraints, assumptions?      │
│  3. Technical Constraints   — platform limits, won't-work-if?    │
│  4. Integration & Ripple    — what else does this touch?         │
│  5. Hidden Assumptions      — what are we betting on?            │
│  6. Edge Cases & Failures   — unusual conditions, cascading?     │
│  7. Performance & Scale     — bottlenecks at scale?              │
│  8. Security & Privacy      — exposed data, auth gaps?           │
│  9. Deployment & Operations — coordination, rollback risks?      │
│ 10. Domain Boundaries       — right domain? crossing boundaries? │
│ 11. Concept Documentation   — discoverable? stale? reusable?     │
└──────────────────────────────────────────────────────────────────┘
```

### Current Validate Agent Coverage vs DYK Lenses

| DYK Lens | Tasks Dossier Agents | Code Change Agents | Plan Agents |
|----------|---------------------|-------------------|-------------|
| User Experience | ❌ | ❌ | ❌ |
| System Behavior | ❌ | ✅ Correctness Agent | ✅ Coherence Agent |
| Technical Constraints | ❌ | ✅ Correctness Agent | ❌ |
| Integration & Ripple | ✅ Cross-Reference | ✅ Regression Agent | ❌ |
| Hidden Assumptions | ❌ | ❌ | ❌ |
| Edge Cases & Failures | ✅ Completeness | ✅ Correctness Agent | ❌ |
| Performance & Scale | ❌ | ❌ | ❌ |
| Security & Privacy | ❌ | ❌ | ❌ |
| Deployment & Ops | ❌ | ❌ | ❌ |
| Domain Boundaries | ❌ | ✅ Domain Compliance | ✅ Completeness |
| Concept Documentation | ❌ | ❌ | ❌ |

**5 of 11 lenses have zero coverage across all agent categories.** These blind spots are systematic.

### Proposed Change

Add a lens coverage step to validate's Step 2 (Design Validation Agents):

```markdown
### Step 2.5: Verify Lens Coverage

Before launching agents, verify coverage against DYK's analysis lenses.
Each agent should map to ≥2 lenses. At least 7 of these 11 lenses should
be covered across all agents combined:

  UX · System Behavior · Technical Constraints · Integration/Ripple ·
  Hidden Assumptions · Edge Cases · Performance · Security ·
  Deployment/Ops · Domain Boundaries · Concept Documentation

If <7 covered, adjust agent prompts to fill gaps. Priority fill order:
Hidden Assumptions > Security > Edge Cases > Deployment/Ops > Performance

Example agent-to-lens mapping:
  Correctness Agent  → System Behavior, Technical Constraints, Edge Cases
  Regression Agent   → Integration/Ripple, Hidden Assumptions, Performance
  Domain Agent       → Domain Boundaries, Concept Documentation, Security
```

**Token cost**: ~80 tokens added to the prompt.
**Impact**: Eliminates systematic blind spots. Agents become more thorough without adding more agents.

---

## Opportunity 2: CS-Score Challenging for Plan Validation

### The Gap

DYK explicitly challenges complexity scores:

```
When CS scores exist (plans/tasks), challenge them:
  CS-1/2: What could make this NOT trivial?
  CS-3: How do we prove this works?
  CS-4/5: What's the rollback plan? Need subtask decomposition?
```

Validate's Plan Agents don't check CS scores at all. A plan could claim CS-2 for something genuinely complex and validate wouldn't catch it.

### Proposed Change

Add to Plan Agents' Completeness Agent prompt:

```markdown
- Challenge CS scores: For each task, ask "What could make this harder
  than the CS score suggests?" Flag tasks where the CS seems
  underestimated based on the code they touch.
```

**Token cost**: ~25 tokens.
**Impact**: Catches optimistic complexity estimates before they become schedule risk.

---

## Opportunity 3: Validation Record Persistence

### The Gap

DYK appends a compact record to the analyzed document after all insights are discussed:

```markdown
## Critical Insights ([date])

| # | Insight | Decision |
|---|---------|----------|
| 1 | [One-sentence insight] | [What was decided] |
```

Validate produces a console report and applies fixes, but **persists nothing**. If you run validate, fix issues, then later wonder "what did validation find?", the information is gone (only in chat history).

### Proposed Change

After Step 6 (Summary), validate should append a compact validation record to the artifact:

```markdown
---

## Validation Record ([ISO-8601 date])

| Agent | Lens | Issues | Verdict |
|-------|------|--------|---------|
| Correctness | System/Edge/Technical | 0 | ✅ |
| Regression | Integration/Assumptions | 2 MEDIUM fixed | ⚠️ |
| Domain | Boundaries/Concepts | 1 HIGH fixed | ⚠️ |

Overall: ⚠️ VALIDATED WITH FIXES — 3 issues found, 3 fixed
```

**Token cost**: ~30 tokens in prompt, ~60 tokens in output.
**Impact**: Creates audit trail. Future agents can see what was already validated.

---

## Opportunity 4: DYK's Enhance Mode as Validate's Optional Enhancement Pass

### Analysis

DYK's enhance mode surfaces *scoped improvements* — UX polish, missing conveniences, robustness ideas. This is fundamentally different from validate's correctness focus.

### Decision: Do NOT adopt

Validate should stay focused on correctness. If the user wants enhancement ideas, they run `/didyouknow --enhance` separately. Mixing "what's wrong" with "what could be better" dilutes both.

**Why this matters**: Adding enhancement suggestions to a validation report trains users to treat validation findings as optional ("those are just suggestions"). Keeping validate purely about correctness maintains its authority — when validate reports an issue, it's a real problem.

---

## Summary of Recommended Changes

| # | Change | Where in validate-v2 | Tokens | Priority |
|---|--------|---------------------|--------|----------|
| 1 | DYK lens coverage checklist | New Step 2.5 | +80 | **HIGH** |
| 2 | CS-score challenging | Plan Agents template | +25 | **MEDIUM** |
| 3 | Validation record persistence | New Step 6.5 | +90 | **MEDIUM** |
| 4 | Enhance mode adoption | N/A | 0 | **SKIP** |

Total prompt growth: ~195 tokens. All additive — no existing behavior changes.

---

## Open Questions

### Q1: Should the lens coverage checklist be mandatory or advisory?

**Recommendation: Advisory.** The agent designing step should *check* coverage but not rigidly require 7/11. Some artifacts genuinely don't need all lenses (e.g., a spec doesn't need Performance/Scale analysis). The checklist surfaces blind spots; the operator decides whether to fill them.

### Q2: Should validation records be appended to the artifact or saved separately?

**Recommendation: Append to artifact** (like DYK does). This keeps the validation visible alongside the artifact it validates, rather than creating yet another file to track.

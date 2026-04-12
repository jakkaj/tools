# Workshop: Validate ↔ Research Commands Cross-Pollination

**Type**: Integration Pattern
**Plan**: 020-v2-command-cross-pollination
**Created**: 2026-04-12T05:55:00Z
**Status**: Draft

**Related Documents**:
- `agents/v2-commands/validate-v2.md`
- `agents/v2-commands/deepresearch-v2.md`
- `agents/v2-commands/flowspace-research-v2.md`
- `agents/v2-commands/plan-1a-v2-explore.md`

---

## Purpose

Design concrete improvements to validate-v2 by adopting proven patterns from the three research commands. Validate and plan-1a-explore share nearly identical architecture (parallel subagent orchestration) but serve opposite intents — validate verifies, explore discovers. The research commands have mature patterns for prompt structure, output schemas, and tool integration that validate can adopt.

## Key Questions Addressed

- Which research command patterns would make validate's agents more effective?
- How should validate agent prompts be structured for consistent, reliable output?
- Should validate adopt FlowSpace integration or stay tool-agnostic?

---

## The Research Command Family

```
┌─────────────────────────────────────────────────────────────────────┐
│                    Research Commands                                 │
│                                                                     │
│  ┌─────────────────┐  ┌──────────────────┐  ┌───────────────────┐  │
│  │  deepresearch    │  │ flowspace-research│  │  plan-1a-explore  │  │
│  │                  │  │                   │  │                   │  │
│  │  Crafts prompts  │  │  IS a subagent    │  │  Orchestrates     │  │
│  │  for external    │  │  (FlowSpace-first │  │  parallel explore │  │
│  │  research agents │  │   code explorer)  │  │  subagents        │  │
│  │                  │  │                   │  │                   │  │
│  │  Single-agent    │  │  Single worker    │  │  Parent + N kids  │  │
│  │  prompt gen      │  │  structured out   │  │  synthesize       │  │
│  └────────┬─────────┘  └────────┬──────────┘  └────────┬──────────┘  │
│           │                     │                       │            │
│     7-section            structured              parallel           │
│     template             findings               orchestration       │
│                          format                                     │
└─────────────────────────────────────────────────────────────────────┘
                                   │
                          ┌────────┴────────┐
                          │   validate-v2   │
                          │                 │
                          │  Orchestrates   │
                          │  parallel       │
                          │  verify agents  │
                          │                 │
                          │  Same arch as   │
                          │  plan-1a but    │
                          │  opposite intent│
                          └─────────────────┘
```

---

## Opportunity 1: Deepresearch's 7-Section Prompt Template for Agent Prompts

### The Gap

Deepresearch has a battle-tested 7-section prompt structure:

```
1. Clear Problem Definition    — what exactly are we investigating?
2. Contextual Information      — tech stack, versions, recent changes
3. Key Research Questions      — specific questions to answer
4. Recommended Tools/Resources — what to look at
5. Practical Examples          — concrete code examples expected
6. Pitfalls and Mitigation     — common mistakes to watch for
7. Integration Considerations  — CI/CD, cross-domain, deployment
```

Validate's agent prompts are currently ad-hoc: "Here's the file, check for X." This produces inconsistent agent output quality.

### Current vs Proposed Agent Prompt Structure

**Current** (validate agent prompt, reconstructed):
```
You are a Correctness Agent. Read these files:
- src/auth/service.py
- tests/test_auth.py

Check for: logic errors, edge cases, null safety, exception handling.
Verify changes match the tasks dossier specification.

Output: numbered list of issues with severity and recommended fix.
```

**Proposed** (adopting deepresearch structure):
```
## 1. Validation Focus
You are verifying correctness of code changes to the auth service.
Artifact: src/auth/service.py (modified lines 45-120)
Specification: docs/plans/015/tasks/phase-2/tasks.md

## 2. Context
- Stack: Python 3.12, FastAPI, SQLAlchemy
- Recent changes: Added token refresh endpoint, modified session handling
- Domain: auth (owns login, token lifecycle, session management)

## 3. Verification Questions
- Does the token refresh handle expired tokens correctly?
- Are all error paths covered with appropriate HTTP status codes?
- Does the session modification maintain backward compatibility?

## 4. Files to Read
- src/auth/service.py (primary — focus on lines 45-120)
- src/auth/models.py (referenced types)
- tests/test_auth.py (test coverage check)

## 5. Known Pitfalls
- Token refresh race conditions when multiple tabs are open
- SQLAlchemy session not committed before returning response
- Missing Content-Type header on error responses

## 6. Output Format
For each issue found:
  SEVERITY: CRITICAL | HIGH | MEDIUM | LOW
  LOCATION: <file>:<line>
  ISSUE: <one-sentence description>
  EVIDENCE: <code snippet or observation>
  FIX: <recommended change>

Only report genuine problems. Not style preferences, not suggestions.
```

### Impact

The structured prompt gives agents:
- **Focus** (section 1) — they know exactly what to verify
- **Context** (section 2) — they understand the tech stack and domain
- **Direction** (section 3) — specific questions prevent aimless exploration
- **Pitfall awareness** (section 5) — they check for known problem patterns
- **Consistent output** (section 6) — parent synthesis becomes reliable

### Proposed Change

Add to validate-v2 Step 3 (Launch Agents):

```markdown
Structure each agent prompt using this template:

1. **Validation Focus**: What artifact, what aspect, what specification to verify against
2. **Context**: Tech stack, recent changes, domain ownership
3. **Verification Questions**: 3-5 specific questions this agent must answer
4. **Files to Read**: Ordered list with focus guidance (primary file, supporting files)
5. **Known Pitfalls**: Common failure patterns for this artifact type
6. **Output Format**: Structured issue format (severity, location, issue, evidence, fix)
```

**Token cost**: ~60 tokens in the prompt instruction. Agent prompts grow ~40% but produce dramatically more focused output.

---

## Opportunity 2: Flowspace-Research's Structured Output Schema

### The Gap

Flowspace-research returns findings in a consistent structured format designed for parent synthesis:

```
## Findings

### Finding 1: [Title]
- **Source**: [file:line or tool:query]
- **Relevance**: [HIGH/MEDIUM/LOW]
- **Detail**: [What was found]
- **Implications**: [What this means for the research question]
```

Validate agents return free-form prose. The parent must parse natural language to extract issues, which is unreliable — issues get missed when buried in paragraphs.

### Proposed Change

Mandate a structured output format in all validate agent prompts (incorporated into section 6 of the prompt template above):

```markdown
## Output Format (mandatory)

Return findings as a structured list. Each issue:

```
### ISSUE-[N]
- **SEVERITY**: CRITICAL | HIGH | MEDIUM | LOW
- **LOCATION**: <absolute-file-path>:<line-number>
- **LENS**: <which DYK lens this falls under>
- **ISSUE**: <one-sentence description>
- **EVIDENCE**: <code snippet, quote, or concrete observation>
- **FIX**: <specific recommended change>
```

If no issues found for your lens, output:
```
### NO ISSUES
All checks passed for: <lens list>
```
```

**Token cost**: Already included in the prompt template (Opportunity 1).
**Impact**: Parent synthesis goes from "parse prose" to "scan structured blocks." Issue extraction becomes deterministic.

---

## Opportunity 3: Deepresearch's "Integration Considerations" Lens

### The Gap

Deepresearch's section 7 asks:

```
- Will the solution require changes to domain contracts?
- New cross-domain dependencies?
- Impact on CI/CD pipelines?
- Does new infrastructure belong in _platform or feature domain?
```

Validate's Code Change agents don't check for deployment/integration impacts. A code change could silently break CI, introduce a new cross-domain dependency, or require a migration — and validate wouldn't catch it.

### Proposed Change

Add an "Integration & Deployment" focus to one of the existing Code Change agents (the Regression Agent is the natural fit):

```markdown
**Regression Agent** (updated scope):
- Check if changes break existing patterns or tests
- Verify test coverage for new code paths
- **Check for deployment impacts**: new env vars, config changes,
  migration requirements, CI pipeline changes needed
- **Check for cross-domain impacts**: new imports from other domains,
  contract changes, shared type modifications
```

**Token cost**: ~30 tokens added to the Regression Agent template.
**Impact**: Catches "works locally but breaks in CI" and "works in isolation but breaks downstream" issues.

---

## Opportunity 4: FlowSpace Integration for Validate Agents

### Analysis

Plan-1a-explore uses FlowSpace MCP tools (tree, search, get_node) for code exploration. Should validate agents use FlowSpace too?

```
                    ┌──────────────────────────────┐
                    │     FlowSpace Integration     │
                    │                                │
                    │  PROs:                          │
                    │  • Semantic search for related  │
                    │    patterns ("find all callers")│
                    │  • Tree view for structure      │
                    │    verification                 │
                    │  • Richer code understanding     │
                    │                                │
                    │  CONs:                          │
                    │  • Adds setup dependency        │
                    │  • Agents must be explore type   │
                    │    (FlowSpace needs MCP access) │
                    │  • Slower — more tool calls      │
                    │  • Validate should be fast        │
                    └──────────────────────────────────┘
```

### Decision: Do NOT adopt (for now)

Validate agents use `agent_type: "explore"` which already has grep/glob/view. FlowSpace would add power but also:
- **Dependency**: Not all projects have FlowSpace set up
- **Speed**: Validate should be fast. FlowSpace adds tool call overhead
- **Complexity**: Agent prompts would need FlowSpace fallback logic (like flowspace-research has)

**Revisit when**: FlowSpace becomes standard infrastructure in most projects. Then adding it to validate agents would be a net win.

---

## Opportunity 5: Plan-1a-Explore's Parallel Architecture Alignment

### Current State

Both validate and plan-1a-explore orchestrate parallel subagents, but their implementations diverge:

| Aspect | plan-1a-explore | validate |
|--------|----------------|----------|
| Agent type | `explore` | `explore` |
| Model | default (Haiku) | `gpt-5.4` |
| Mode | `background` | `background` |
| Agent count | 3-7 (dynamic) | 2-4 (by category) |
| Output | Research dossier file | Console report |
| Persistence | `research-dossier.md` | None |

### Insight: Validate Could Be Faster with Default Model

Validate hardcodes `model: "gpt-5.4"` for all agents. For simple artifact types (spec validation, general validation), Haiku-class models would be sufficient and 5-10x faster.

### Proposed Change

Add model selection guidance to validate:

```markdown
### Model Selection

Choose model based on artifact complexity:
- **Code changes**: gpt-5.4 (needs strong reasoning for logic verification)
- **Plans/Specs**: default model (structural checks, less reasoning needed)
- **Tasks dossiers**: gpt-5.4 (needs to verify code references)
- **General**: default model

Use --scope narrow to force default model (faster, cheaper).
```

**Token cost**: ~40 tokens.
**Impact**: Spec/plan validation runs 5-10x faster. Code validation keeps high-quality reasoning.

---

## Summary of Recommended Changes

| # | Change | Source | Where in validate-v2 | Tokens | Priority |
|---|--------|--------|---------------------|--------|----------|
| 1 | 6-section agent prompt template | deepresearch | Step 3 | +60 | **HIGH** |
| 2 | Structured output schema | flowspace-research | Step 3 (section 6) | included in #1 | **HIGH** |
| 3 | Integration/deployment lens | deepresearch §7 | Regression Agent | +30 | **MEDIUM** |
| 4 | FlowSpace integration | flowspace-research | N/A | 0 | **SKIP** |
| 5 | Model selection guidance | plan-1a-explore | Step 3 | +40 | **LOW** |

Total prompt growth: ~130 tokens. Changes 1-3 are additive. Change 4 is deferred. Change 5 is optional.

---

## Combined Impact (with DYK Workshop)

When combined with the DYK crossover workshop findings:

```
Validate-v2 improvements (both workshops combined):

FROM DYK:
  ✅ 11-lens coverage checklist          (+80 tokens)
  ✅ CS-score challenging for plans      (+25 tokens)
  ✅ Validation record persistence       (+90 tokens)
  ❌ Enhance mode adoption              (skip)

FROM RESEARCH:
  ✅ 6-section agent prompt template     (+60 tokens)
  ✅ Structured output schema            (included above)
  ✅ Integration/deployment lens         (+30 tokens)
  ❌ FlowSpace integration              (skip/defer)
  ⚠️ Model selection guidance           (+40 tokens, low priority)

TOTAL: ~285 tokens prompt growth (if all adopted)
       ~325 tokens with model selection
```

All changes are additive — no existing behavior removed. The validate command becomes more thorough, more consistent, and produces auditable output.

---

## Open Questions

### Q1: Should we implement all changes at once or incrementally?

**Recommendation: All at once.** The changes are small, non-conflicting, and the prompt template (Opportunity 1) naturally incorporates the structured output (Opportunity 2) and lens checklist (DYK Opportunity 1). Implementing them separately would require multiple editing passes over the same sections.

### Q2: Should the 6-section prompt template be shared across validate and plan-1a-explore?

**OPEN.** Plan-1a-explore currently designs research prompts ad-hoc too. Both could benefit from a shared "agent prompt template" convention. But standardizing across commands is a larger effort — address after validate proves the pattern works.

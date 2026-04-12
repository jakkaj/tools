---
description: Launch parallel subagents to validate whatever was just produced with structured lens coverage — tasks dossier, code changes, plan, spec, or any artifact. Universal post-action validation.
---

Please deep think / ultrathink as this is a complex task.

# validate-v2

**Universal post-action validation** — launches parallel GPT-5.4 subagents to cross-check whatever artifact was just produced. Works on any output: tasks dossier, code changes, plan, spec, workshop, or any structured document.

## Philosophy

> "Every artifact deserves a second pair of eyes before the human sees it."

This skill is the automated equivalent of asking 3 senior engineers to review your work in parallel. Each agent has a different lens. They run on GPT-5.4 for high reasoning quality. Results are synthesized and actionable fixes applied immediately.

---

```md
User input:

$ARGUMENTS
# No flags required — auto-detects what to validate from context.
# Optional: --artifact <path> to specify a file to validate
# Optional: --scope <narrow|broad> to control agent count and model (default: broad = 3 agents)
#   narrow: fewer agents, default model (faster for specs/plans)
#   broad: full agents, gpt-5.4 (thorough for code/tasks)
```

## How It Works

### Step 1: Detect What Was Just Done

Examine the conversation context to determine what artifact was just produced. Categories:

| Category | Detection Signal | Agent Focus |
|----------|-----------------|-------------|
| **Tasks Dossier** | Recent plan-5 skill invocation, tasks.md file created/modified | Line numbers, code snippets, cross-references, dependency chain |
| **Code Changes** | Recent plan-6 skill invocation, source files edited | Correctness, edge cases, missing error handling, contract compliance |
| **Plan** | Recent plan-3 skill invocation, plan.md created | Phase coherence, risk coverage, domain alignment, missing tasks |
| **Spec** | Recent plan-1b skill invocation, spec.md created | Ambiguities, missing acceptance criteria, scope gaps |
| **Workshop** | Recent plan-2c skill invocation, workshop file created | Factual accuracy, code examples vs actual source, decision coverage |
| **General** | Anything else | Correctness, completeness, consistency |

### Step 2: Design Validation Agents

Based on the detected category, design 2-4 parallel agents. Each agent gets:

1. **A specific validation lens** (not overlapping with other agents)
2. **The artifact content** (file paths to read)
3. **Source-of-truth files** to cross-reference against
4. **Explicit output format**: issues found, severity, recommended fix

#### Agent Templates by Category

**Tasks Dossier Agents** (3 agents):
- **Source Truth Agent**: Read the actual source files referenced in tasks. Verify line numbers, method signatures, class hierarchies, import statements. Flag anything that doesn't match.
- **Cross-Reference Agent**: Verify plan↔dossier alignment (task count, key finding references), workshop↔dossier code alignment, dependency chain correctness.
- **Completeness Agent**: Check for missing error handling, missing null checks, missing test coverage mentions, pre-implementation check completeness.

**Code Change Agents** (3 agents):
- **Correctness Agent**: Read modified files. Check logic, edge cases, null safety, exception handling. Verify changes match the tasks dossier specification.
- **Regression Agent**: Check if changes break existing patterns. Verify test coverage. Look for unintended side effects on other consumers. Check for deployment impacts: new env vars, config changes, migration requirements, CI pipeline changes. Check for cross-domain impacts: new imports from other domains, contract changes, shared type modifications.
- **Domain Compliance Agent**: Verify changes are in the right location. Check import/dependency direction. Flag contract changes.

**Plan Agents** (3 agents):
- **Coherence Agent**: Verify phases are properly ordered, dependencies are correct, no circular dependencies, each phase has clear deliverables.
- **Risk Agent**: Cross-reference risks with key findings. Verify mitigations are actionable. Check for unaddressed risks from research.
- **Completeness Agent**: Verify acceptance criteria are testable, all touched areas are accounted for. Challenge CS scores: for each task, ask "What could make this harder than the CS score suggests?" Flag tasks where CS seems underestimated based on the code they touch.

**General Agents** (2 agents):
- **Accuracy Agent**: Fact-check claims against source code and documentation.
- **Consistency Agent**: Check for internal contradictions, terminology consistency, cross-reference accuracy.

### Step 2.5: Verify Lens Coverage

Before launching, verify agents collectively cover at least 7 of these 11 analysis lenses:

| Lens | What it catches |
|------|----------------|
| User Experience | Surprising behavior changes, UX regressions |
| System Behavior | New constraints, assumption violations |
| Technical Constraints | Platform limits, API restrictions |
| Integration & Ripple | Downstream impacts, broken consumers |
| Hidden Assumptions | Implicit bets that could fail |
| Edge Cases & Failures | Unusual conditions, cascading failures |
| Performance & Scale | Bottlenecks, resource concerns at scale |
| Security & Privacy | Exposed data, auth gaps, vulnerabilities |
| Deployment & Ops | CI/CD impacts, env vars, migrations, rollback |
| Domain Boundaries | Wrong domain, crossing boundaries, missing contracts |
| Concept Documentation | Stale docs, missing concepts, reuse opportunities |

Map each agent to its covered lenses. If <7 covered, adjust agent prompts to fill gaps.
Priority fill order: Hidden Assumptions > Security > Edge Cases > Deployment/Ops > Performance.

For **Plan** validation, also challenge CS (complexity) scores:
- CS-1/2: What could make this NOT trivial?
- CS-3: How do we prove this works?
- CS-4/5: What’s the rollback plan? Need subtask decomposition?

### Step 3: Launch Agents

Launch all agents in parallel using the `task` tool with:
- `agent_type: "explore"` (read-only validation)
- `model: "gpt-5.4"` for code/tasks validation, default model for specs/plans (or when `--scope narrow`)
- `mode: "background"` (parallel execution)

Structure each agent prompt using this 6-section template:

**Section 1 — Validation Focus**: What artifact, what aspect, what specification to verify against. Which lenses (from the 11-lens checklist) this agent covers.

**Section 2 — Context**: Tech stack, recent changes, domain ownership, relevant constraints.

**Section 3 — Verification Questions**: 3-5 specific questions this agent must answer. Be concrete (e.g., "Does token refresh handle expired tokens?" not "Check for bugs").

**Section 4 — Files to Read**: Ordered list with focus guidance — primary file with line range, then supporting files.

**Section 5 — Known Pitfalls**: Common failure patterns for this artifact type (e.g., race conditions in async handlers, stale line numbers in dossiers, missing Content-Type on error responses).

**Section 6 — Output Format** (mandatory for every agent):

For each issue found, output this exact structure:
- **SEVERITY**: CRITICAL | HIGH | MEDIUM | LOW
- **LOCATION**: absolute-file-path:line-number
- **LENS**: which analysis lens from the checklist
- **ISSUE**: one-sentence description
- **EVIDENCE**: code snippet or concrete observation
- **FIX**: specific recommended change

If no issues found: "NO ISSUES — All checks passed for: [lens list]"

Only report genuine problems — not style preferences, not suggestions.

### Step 4: Collect Results

Wait for all agents to complete. For each agent:
1. Read the results via `read_agent`
2. Extract issues found
3. Categorize by severity

### Step 5: Synthesize and Act

Present findings to the user conversationally:

```
## Validation Results

**3 agents completed** — [X issues found]

### Critical Issues (fix now)
- [issue]: [what's wrong] → [fix]

### High Issues (should fix)
- [issue]: [what's wrong] → [fix]

### Medium/Low Issues (consider)
- [issue]: [what's wrong] → [fix]

### Clean Areas
- [agent 1 lens]: ✅ No issues
```

**Then immediately apply fixes** for CRITICAL and HIGH issues:
- Edit the artifact files directly
- Show what changed
- Re-verify if needed

For MEDIUM/LOW issues: present them but ask the user before fixing.

### Step 6: Summary

End with a one-line verdict:

- ✅ **VALIDATED** — no issues found (or only LOW)
- ⚠️ **VALIDATED WITH FIXES** — issues found and fixed
- ❌ **NEEDS ATTENTION** — issues found that need user decision

### Step 6.5: Persist Validation Record

Append a compact validation record to the validated artifact (if it is a file):

```markdown
---

## Validation Record (ISO-8601 date)

| Agent | Lenses Covered | Issues | Verdict |
|-------|---------------|--------|---------||
| Agent Name | lens, lens | count severity fixed/open | verdict |

Overall: VALIDATED | VALIDATED WITH FIXES | NEEDS ATTENTION
```

This creates an audit trail — future agents can see what was already validated.
Skip persistence for console-only artifacts or non-markdown files.

---

## Key Principles

1. **Agents validate, parent synthesizes** — agents report raw findings, the parent decides what to fix
2. **Source code is truth** — when a dossier says "line 131" and the file says otherwise, the file wins
3. **Fix what you find** — don't just report issues, apply the fixes immediately
4. **No false positives** — every issue must be real and actionable. Agent prompts emphasize: "only report genuine problems, not style preferences"
5. **Gift to future selves** — if validation catches a recurring issue type, consider whether the upstream skill should be improved to prevent it

---

## Example Invocations

```bash
# After generating a tasks dossier
/validate

# After implementing a phase
/validate

# After creating a plan
/validate

# Validate a specific file
/validate --artifact docs/plans/my-feature/tasks/phase-2/tasks.md
```

The skill auto-detects what to validate. You almost never need flags.

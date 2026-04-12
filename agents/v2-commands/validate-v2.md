---
description: Launch parallel GPT-5.4 subagents to validate whatever was just produced — tasks dossier, code changes, plan, spec, or any artifact. Universal post-action validation.
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
# Optional: --scope <narrow|broad> to control agent count (default: broad = 3 agents)
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
- **Regression Agent**: Check if changes break existing patterns. Verify test coverage. Look for unintended side effects on other consumers.
- **Domain Compliance Agent**: Verify changes are in the right location. Check import/dependency direction. Flag contract changes.

**Plan Agents** (3 agents):
- **Coherence Agent**: Verify phases are properly ordered, dependencies are correct, no circular dependencies, each phase has clear deliverables.
- **Risk Agent**: Cross-reference risks with key findings. Verify mitigations are actionable. Check for unaddressed risks from research.
- **Completeness Agent**: Verify acceptance criteria are testable, complexity scores are justified, all touched areas are accounted for.

**General Agents** (2 agents):
- **Accuracy Agent**: Fact-check claims against source code and documentation.
- **Consistency Agent**: Check for internal contradictions, terminology consistency, cross-reference accuracy.

### Step 3: Launch Agents

Launch all agents in parallel using the `task` tool with:
- `agent_type: "explore"` (read-only validation)
- `model: "gpt-5.4"` (high reasoning quality)
- `mode: "background"` (parallel execution)

Each agent prompt MUST include:
1. Complete context about what was produced
2. Specific file paths to read (absolute paths)
3. What to check (the validation lens)
4. Output format: numbered list of issues with severity (CRITICAL/HIGH/MEDIUM/LOW) and recommended fix

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

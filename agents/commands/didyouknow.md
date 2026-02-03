---
description: Universal clarity utility - deep think 5 critical insights and discuss conversationally to build shared understanding. Run after any spec/plan/tasks/code.
---

Please deep think / ultrathink as this is a complex task.

# didyouknow

**Universal clarity builder** - analyze any context (spec, plan, tasks, subtask, code) and surface 5 critical "Did you know?" insights through natural conversation.

````md
User input:

$ARGUMENTS

Expected usage patterns:
```bash
/didyouknow --spec <path>      # Analyze a feature specification
/didyouknow --plan <path>      # Analyze an implementation plan
/didyouknow --tasks <path>     # Analyze phase tasks
/didyouknow --subtask <path>   # Analyze a subtask
/didyouknow --code <path>      # Analyze code file(s)
/didyouknow                    # Auto-detect most recent context
```

## Purpose

Build shared understanding between human and AI by surfacing non-obvious implications, gotchas, and critical insights. This is a **clarity tool** — run it whenever you need to step back and really understand what's about to happen.

## Flow

### 1) Context Loading

- Parse flags to determine context type (spec/plan/tasks/subtask/code)
- If auto-detect mode (no flags): search `docs/plans/` for most recent plan or spec
- Read the primary context document completely
- Load related documents for full picture:
  * If analyzing plan → also read the spec
  * If analyzing tasks → also read the plan and spec
  * If analyzing code → read relevant docs if they exist

### 2) ULTRA-DEEP THINKING (Most Critical Step)

**Spend significant thinking time here.** Analyze from all these lenses:

- **User Experience** — what changes for users? What's surprising?
- **System Behavior** — new constraints, assumptions, data flow changes?
- **Technical Constraints** — platform limits, API restrictions, won't-work-if?
- **Integration & Ripple Effects** — what else does this touch? Downstream impact?
- **Hidden Assumptions** — what are we betting on that could fail?
- **Edge Cases & Failure Modes** — unusual conditions, cascading failures?
- **Performance & Scale** — bottlenecks, resource concerns at scale?
- **Security & Privacy** — exposed data, auth gaps, vulnerabilities?
- **Deployment & Operations** — coordination needed, rollback risks?

**When CS scores exist** (plans/tasks), challenge them:
- CS-1/2: What could make this NOT trivial?
- CS-3: How do we prove this works?
- CS-4/5: What's the rollback plan? Need subtask decomposition?

**Select the 5 most impactful insights** — non-obvious, actionable, ordered by impact, spanning different perspectives.

### 3) CONVERSATIONAL PRESENTATION (One at a Time)

**CRITICAL: Present insights concisely. The human can ask to expand.**

For each insight, present it like this:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

**#N: [Short Title]**

Did you know [one-sentence insight]?

This matters because [one sentence on why it's important].

**Recommendation**: [one-line recommendation]

What do you think?
```

That's it. Short. Punchy. The human will do one of:
- **Agree** → capture decision, move on
- **Disagree/discuss** → engage naturally, reach alignment
- **"Tell me more"** → expand with implications, examples, deeper analysis
- **"Give me options/alternatives"** → present 2-4 concrete options with pros, cons, complexity (CS), and your recommendation. Include enough detail per option that the human can choose confidently.

**Do NOT front-load** the deep dive, options matrix, numbered consequences, or examples. Only expand when asked. Match the depth to what the human asks for.

**Rules:**
- One insight at a time — WAIT for response before the next
- Use "we/our/us" — collaborative language
- Ask real questions, not rhetorical ones
- Start with the insight, no preamble ("Can we talk about..." — NO)

### 4) After Each Insight

Once a decision is reached:

```
✓ [What was decided] — [one-line rationale]
```

If the decision requires doc updates, make them immediately. Confirm briefly:
```
Updated [file]: [what changed]
```

Do NOT defer updates to the end.

### 5) Session Summary

After all 5 insights, output a brief summary:

```
**Did You Know — Complete**

1. [Title] → [Decision]
2. [Title] → [Decision]
3. [Title] → [Decision]
4. [Title] → [Decision]
5. [Title] → [Decision]

[Count] decisions made, [count] files updated.
Next: [suggested next action]
```

Then append a compact record to the source document:

```markdown
---

## Critical Insights ([date])

| # | Insight | Decision |
|---|---------|----------|
| 1 | [One-sentence insight] | [What was decided] |
| 2 | [One-sentence insight] | [What was decided] |
| 3 | [One-sentence insight] | [What was decided] |
| 4 | [One-sentence insight] | [What was decided] |
| 5 | [One-sentence insight] | [What was decided] |

Action items: [list any, or "None"]
```

No new files created — insights are appended to the analyzed document.

## Validation

- Exactly 5 insights, one at a time
- Human responds to each before proceeding
- Each insight is 3-5 lines on first presentation (not a wall of text)
- Deep dives only happen when the human asks
- Updates applied immediately after each decision
- Insights span multiple perspectives
- Ordered by impact (highest first)

## Anti-Patterns

- Dumping all 5 at once
- Front-loading deep dives, options matrices, and examples
- Not waiting for human responses
- Stating obvious facts from the docs
- Being overly formal or academic
- Deferring document updates to the end

## Integration

Standalone utility — invoke whenever needed. No other commands depend on it.

Common moments to run it:
- After `/plan-1b` (spec) — surface implications of what we're building
- After `/plan-3` (plan) — discuss what we're about to implement
- Before `/plan-6` (implement) — clarify task interactions
- After implementation — understand what changed
````

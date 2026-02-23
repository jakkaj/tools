---
description: Universal clarity utility - deep think 5 critical insights and discuss conversationally to build shared understanding. Run after any spec/plan/tasks/code. Domain-aware v2.
---

Please deep think / ultrathink as this is a complex task.

# didyouknow

**Universal clarity builder** - analyze any context (spec, plan, tasks, subtask, code) and surface critical "Did you know?" insights through natural conversation. Supports two modes: **default** (risks, gotchas, hidden assumptions) and **enhance** (scoped improvement ideas).

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
/didyouknow --enhance          # Enhancement mode (5 ideas, scoped to feature)
/didyouknow --enhance 3        # Enhancement mode with custom count
/didyouknow --enhance --spec <path>  # Enhance mode on a specific spec
```

## Modes

### Default Mode (clarity)
Surface risks, gotchas, hidden assumptions, and non-obvious implications in what already exists. Always 5 insights.

### Enhance Mode (`--enhance [N]`)
Surface scoped improvement ideas — UX polish, missing quality-of-life features, enhancements to the existing feature. Does NOT suggest tangential or out-of-scope ideas. Defaults to 5 ideas; the user may specify a custom count (e.g. `--enhance 3`, `--enhance 10`).

## Purpose

Build shared understanding between human and AI. In **default mode**, surface non-obvious implications, gotchas, and critical insights. In **enhance mode**, surface improvement ideas scoped to the feature being analyzed. This is a **clarity and ideation tool** — run it whenever you need to step back and really understand or improve what's being built.

## Flow

### 1) Context Loading

- Parse flags to determine context type (spec/plan/tasks/subtask/code)
- Detect mode: if `--enhance` is present, activate enhance mode. Parse optional count (default 5).
- If auto-detect mode (no flags): search `docs/plans/` for most recent plan or spec
- Read the primary context document completely
- Load related documents for full picture:
  * If analyzing plan → also read the spec
  * If analyzing tasks → also read the plan and spec
  * If analyzing code → read relevant docs if they exist
- **Domain awareness**: If `docs/domains/registry.md` exists, scan relevant domain.md files for context. Note which domains the current artifact targets (from spec `## Target Domains` if present). This is background context — domain insights surface naturally alongside other lenses, not as a forced category.

### 2) ULTRA-DEEP THINKING (Most Critical Step)

**Spend significant thinking time here.**

#### Default Mode Lenses

- **User Experience** — what changes for users? What's surprising?
- **System Behavior** — new constraints, assumptions, data flow changes?
- **Technical Constraints** — platform limits, API restrictions, won't-work-if?
- **Integration & Ripple Effects** — what else does this touch? Downstream impact?
- **Hidden Assumptions** — what are we betting on that could fail?
- **Edge Cases & Failure Modes** — unusual conditions, cascading failures?
- **Performance & Scale** — bottlenecks, resource concerns at scale?
- **Security & Privacy** — exposed data, auth gaps, vulnerabilities?
- **Deployment & Operations** — coordination needed, rollback risks?
- **Domain Boundaries** — are concepts in the right domain? Reaching into another domain's internals? Missing contract? Duplicating something in another domain? Wrong dependency direction?

**Domain insights are not mandatory.** They surface when genuinely relevant. If domains are clean, they may not make the top 5. That's fine.

**When CS scores exist** (plans/tasks), challenge them:
- CS-1/2: What could make this NOT trivial?
- CS-3: How do we prove this works?
- CS-4/5: What's the rollback plan? Need subtask decomposition?

**Select the 5 most impactful insights** — non-obvious, actionable, ordered by impact, spanning different perspectives.

#### Enhance Mode Lenses

- **UX Polish** — what would make this smoother, more intuitive, more delightful?
- **Missing Conveniences** — quality-of-life features users would expect but aren't specified?
- **Robustness** — error messages, fallbacks, graceful degradation that would improve trust?
- **Consistency** — does this align with patterns elsewhere in the codebase/product?
- **Developer Experience** — logging, debugging hooks, configurability that would help future maintainers?
- **Domain Health** — would a contract make this more composable? Reuse opportunity across domains?

**Stay scoped to the feature being analyzed.** Do NOT suggest tangential features or out-of-scope additions. Every idea must directly enhance what's already planned.

**Select the N most valuable ideas** (default 5, or user-specified count) — ordered by value, practical, and scoped to the existing feature.

### 3) CONVERSATIONAL PRESENTATION (One at a Time)

**⚠️ CRITICAL — HARD RULE: Present ONLY ONE insight per message. Output ONE insight, then STOP and WAIT for the human to respond before presenting the next. Do NOT present insight #2 until the human has replied to #1. This is the most important rule in this entire prompt.**

For each insight/idea, present it like this:

**Default mode:**
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

**#N: [Short Title]**

Did you know [one-sentence insight]?

This matters because [one sentence on why it's important].

**Recommendation**: [one-line recommendation]

What do you think?
```

**Enhance mode:**
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

**#N/N: [Short Title]**

What if we [one-sentence enhancement idea]?

This would improve [one sentence on the benefit].

**Recommendation**: [one-line suggestion]

Worth adding?
```

That's it. Short. Punchy. The human will do one of:
- **Agree** → capture decision, move on
- **Disagree/discuss** → engage naturally, reach alignment
- **"Tell me more"** → expand with implications, examples, deeper analysis
- **"Give me options/alternatives"** → present 2-4 concrete options with pros, cons, complexity (CS), and your recommendation. Include enough detail per option that the human can choose confidently.

**Do NOT front-load** the deep dive, options matrix, numbered consequences, or examples. Only expand when asked. Match the depth to what the human asks for.

**Rules:**
- **ONE insight per message. STOP after each. WAIT for the human to reply.** Never present two or more insights in the same message. This is non-negotiable.
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

After all insights/ideas are complete, output a brief summary:

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

- Default mode: exactly 5 insights. Enhance mode: N ideas (default 5, or user-specified count). Always one at a time.
- Human responds to each before proceeding
- Each insight is 3-5 lines on first presentation (not a wall of text)
- Deep dives only happen when the human asks
- Updates applied immediately after each decision
- Insights span multiple perspectives
- Ordered by impact (highest first)

## Anti-Patterns

- **Dumping all 5 at once or presenting more than one insight per message (MOST COMMON FAILURE — never do this)**
- Front-loading deep dives, options matrices, and examples
- Not waiting for human responses — you MUST stop and wait after each insight
- Stating obvious facts from the docs
- Being overly formal or academic
- Deferring document updates to the end
- In enhance mode: suggesting out-of-scope or tangential features
- **Forcing domain insights when there's nothing interesting to say about domains**

## Integration

Standalone utility — invoke whenever needed. No other commands depend on it.

Common moments to run it:
- After `/plan-1b` (spec) — surface implications of what we're building
- After `/plan-3` (plan) — discuss what we're about to implement
- Before `/plan-6` (implement) — clarify task interactions
- After implementation — understand what changed
````

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

Build shared understanding between human and AI by surfacing non-obvious implications, gotchas, and critical insights through natural water-cooler conversation.

This is a **clarity tool** - run it whenever you need to step back and really understand what's about to happen, what just happened, or what something means.

## Flow

### 1) Context Loading & Preparation

**Input Detection:**
- Parse flags to determine context type (spec/plan/tasks/subtask/code)
- If auto-detect mode (no flags): search `docs/plans/` for most recent plan or spec
- Read the primary context document completely
- Load related documents for full picture:
  * If analyzing plan → also read the spec
  * If analyzing tasks → also read the plan and spec
  * If analyzing code → read relevant docs if they exist

**Initial Analysis:**
- Understand what's being analyzed
- Identify the scope and boundaries
- Note the current state vs intended state
- Recognize key stakeholders affected

### 2) ULTRA-DEEP THINKING (Most Critical Step)

**This is where the magic happens - spend significant time here.**

Analyze from multiple perspectives:

**User Experience Lens:**
- "Users will now [experience/see/do] ..."
- "This changes how users [interact/understand/work] ..."
- "Users might not realize that ..."
- "When users [action], they'll encounter ..."

**System Behavior Lens:**
- "The system will now [behave/respond/process] differently by ..."
- "This introduces a new [constraint/requirement/dependency] ..."
- "The system assumes [assumption] which could break if ..."
- "Data now flows [differently/through new paths] ..."

**Technical Constraints Lens:**
- "This requires [technology/approach/infrastructure] ..."
- "We're limited by [API/framework/platform] because ..."
- "This won't work if [condition] ..."
- "The [component] can only handle [limitation] ..."

**Integration & Ripple Effects Lens:**
- "This impacts [other-system/component/team] ..."
- "Changing this means we also have to [change/update/notify] ..."
- "Downstream systems will need to [adapt/update/handle] ..."
- "This creates a dependency on [external-thing] ..."

**Hidden Assumptions Lens:**
- "We're assuming [assumption] but what if ..."
- "This only works if [condition] remains true ..."
- "The plan depends on [thing] being available/working ..."
- "We're betting that [assumption] which could fail ..."

**Edge Cases & Failure Modes Lens:**
- "What happens when [unusual-condition] ..."
- "If [component] fails, then [cascade-effect] ..."
- "Users could exploit [loophole/weakness] ..."
- "Concurrent [action] could cause [problem] ..."

**Performance & Scale Lens:**
- "This could slow down when [condition] ..."
- "At scale, this [operation] becomes [bottleneck] ..."
- "Memory/CPU/network usage increases [how/when] ..."
- "This doesn't account for [scaling-concern] ..."

**Security & Privacy Lens:**
- "This exposes [data/endpoint/vulnerability] ..."
- "Authentication/authorization could be bypassed via ..."
- "Sensitive data flows through [unsecured-path] ..."
- "This introduces [security-risk] because ..."

**Deployment & Operations Lens:**
- "Teams must [action] before/during/after deployment ..."
- "This requires [coordination/downtime/migration] ..."
- "Rollback becomes [harder/impossible/risky] because ..."
- "Monitoring/alerting needs to [change/expand] ..."

**Selection Criteria - Choose the 5 most impactful insights that are:**
1. **Truly impactful** - Not trivial observations, but things that matter
2. **Non-obvious** - Not explicitly stated in the docs, requires deep analysis
3. **Actionable** - Leads to decisions, changes, or important acknowledgments
4. **Discussion-worthy** - Promotes meaningful conversation and alignment
5. **Prioritized** - Ordered by impact (most critical first)

**Quality Bar:**
- Each insight should make the human go "Wow, I didn't think of that"
- Each insight should change how we think about the work
- Each insight should prevent a future problem or improve the outcome
- Insights should span different perspectives (not all technical, not all UX)

### 3) CONVERSATIONAL PRESENTATION (One at a Time - CRITICAL!)

**For EACH of the 5 insights, follow this exact structure:**

#### a) Natural Introduction
Start casually, like a teammate bringing up something interesting:
- "Hey, so I was thinking about [aspect of context]..."
- "You know what I just realized about this [feature/plan/code]?"
- "Can we talk about something I noticed while looking at [section]?"
- "I want to bring up something that could be important..."

#### b) The Core Insight (Clear "Did you know" statement)
State it directly and clearly:
- "Did you know that when we [action], [consequence]?"
- "Did you know this means [implication]?"
- "Did you know users will experience [change]?"
- "Did you know the system will now [behavior]?"

Make it specific and concrete, not vague.

#### c) Deep Dive (Explain the implications)
Break down what this means:

```markdown
Here's what happens:
1. [First consequence/step]
2. [Second consequence/step]
3. [Third consequence/step]

This means:
- [Implication 1]
- [Implication 2]
- [Implication 3]

For example:
[Concrete scenario that illustrates the insight]
```

Use:
- Bullet points for clarity
- Numbered lists for sequences
- Specific examples and scenarios
- Data/numbers when relevant
- Visual aids (tables, simple diagrams) if helpful

#### d) Conversation Starter (Open-ended question)
Invite discussion and decision-making:
- "What do you think about [approach/tradeoff]?"
- "Should we [option-A] or [option-B]?"
- "Does this change how we should [plan/implement/test]?"
- "Are you comfortable with [risk/assumption]?"
- "How do you want to handle [challenge]?"

Make it a REAL question that requires thought and input.

#### e) **WAIT for Human Response**
**This is absolutely critical - DO NOT rush through all 5 insights!**

- Stop and wait for human to respond
- Read their response carefully
- Engage in back-and-forth conversation naturally
- Ask follow-up questions if needed:
  * "Can you say more about [their-point]?"
  * "So you're thinking [interpretation] - is that right?"
  * "What about [related-concern]?"
- Clarify any misunderstandings
- Explore alternative viewpoints
- Challenge assumptions (gently) if needed
- Work toward alignment and decision

**Continue the conversation until:**
- A clear decision is made, OR
- The human acknowledges understanding, OR
- The team agrees to defer/investigate further

#### f) Capture Decision (After discussion concludes)
Summarize what was decided:
```markdown
✓ Decision: [What was decided]
✓ Rationale: [Why this decision makes sense]
✓ Action items: [Any follow-up tasks if applicable]
✓ Affects: [Which parts of spec/plan/tasks this impacts]
```

Only then move to the next insight:
```markdown
Great, moving to insight #2...
```

**Style Guidelines for Conversation:**
- Use "we", "our", "us" (collaborative language)
- Be friendly but professional
- Show genuine interest and concern
- Ask real questions, not rhetorical ones
- Listen to responses and adapt
- Acknowledge good points
- Respectfully challenge when needed
- Celebrate good decisions
- Surface risks without being alarmist

### 4) DOCUMENTATION

After all 5 insights have been discussed, append to the **SOURCE DOCUMENT** (the file that was analyzed):

```markdown
---

## Critical Insights Discussion

**Session**: {{TODAY}} {{TIME}}
**Context**: [Description of what was analyzed - e.g., "OAuth Integration Implementation Plan v1.0"]
**Analyst**: AI Clarity Agent
**Reviewer**: [Human name if provided, else "Development Team"]
**Format**: Water Cooler Conversation (5 Critical Insights)

### Insight 1: [Compelling, Specific Title]

**Did you know**: [The core insight in one clear sentence]

**Implications**:
- [Consequence/implication 1]
- [Consequence/implication 2]
- [Consequence/implication 3]

**Discussion Summary**:
[2-3 sentences capturing the key points of the conversation]

**Decision**: [What the team decided to do about this]

**Action Items**:
- [ ] [Action item 1, if any]
- [ ] [Action item 2, if any]

**Affects**: [Which sections/phases/components this impacts]

---

### Insight 2: [Title]

**Did you know**: [Core insight]

**Implications**:
- [Point 1]
- [Point 2]
- [Point 3]

**Discussion Summary**: [Conversation recap]

**Decision**: [What was decided]

**Action Items**:
- [ ] [Any follow-ups]

**Affects**: [Impact areas]

---

[... Continue for Insights 3, 4, and 5 ...]

---

## Session Summary

**Insights Surfaced**: 5 critical insights identified and discussed
**Decisions Made**: [Count] decisions reached through collaborative discussion
**Action Items Created**: [Count] follow-up tasks identified
**Areas Requiring Updates**:
- [List any sections of spec/plan/tasks that should be updated based on insights]

**Shared Understanding Achieved**: ✓

**Confidence Level**: [High/Medium/Low] - How confident are we about proceeding?

**Next Steps**:
[What should happen next - e.g., "Update Phase 2 tasks to include migration strategy" or "Proceed to implementation with documented understanding"]

**Notes**:
[Any additional context, concerns, or observations from the session]
```

### 5) Console Summary (Output to User)

After documentation is complete, provide a concise summary:

```markdown
✅ "Did You Know" Clarity Session Complete

📊 Session Results:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📝 Analyzed: [File path/context]
💡 Insights: 5 critical discoveries
✓ Decisions: [count] made
📋 Actions: [count] follow-up items
📍 Updates needed: [count] sections

🎯 Top Insights:
1. [Insight 1 title] → [Key decision]
2. [Insight 2 title] → [Key decision]
3. [Insight 3 title] → [Key decision]
4. [Insight 4 title] → [Key decision]
5. [Insight 5 title] → [Key decision]

📄 Documentation:
Updated: [source-file-path]
Section: "Critical Insights Discussion"

🚀 Recommended Next Action:
[Suggest what to do next, e.g., "/plan-5-phase-tasks-and-brief" or "Review and update affected sections"]

💭 Confidence: [High/Medium/Low]
We have [high/medium/low] confidence in proceeding based on this clarity session.
```

## Validation Rules

**Hard Requirements (Must Pass):**
- [ ] Exactly 5 insights presented (no more, no less)
- [ ] Each insight discussed one-at-a-time (no batching!)
- [ ] Human input received for each insight before proceeding
- [ ] Conversational tone throughout (not formal documentation)
- [ ] Each insight reveals something non-obvious
- [ ] Each insight leads to actionable discussion
- [ ] All discussion outcomes documented
- [ ] Source document updated with insights section
- [ ] Session summary provided

**Quality Requirements:**
- [ ] Insights span multiple perspectives (UX, tech, ops, etc.)
- [ ] Insights ordered by impact (highest first)
- [ ] Natural conversation flow (not robotic)
- [ ] Real questions asked (not rhetorical)
- [ ] Decisions captured clearly
- [ ] Action items are specific and assignable

**Anti-Patterns to Avoid:**
- ❌ Dumping all 5 insights at once
- ❌ Not waiting for human responses
- ❌ Stating obvious facts from the docs
- ❌ Being overly formal or academic
- ❌ Asking yes/no questions only
- ❌ Not engaging with human responses
- ❌ Skipping documentation

## Example Session (Abbreviated)

```markdown
📄 Analyzing: docs/plans/002-oauth-integration/oauth-plan.md
🎯 Goal: Surface 5 critical insights before implementation

Let me take a deep look at this OAuth integration plan...
[thinking deeply about implications...]

Alright, I've identified 5 things I think we should talk about.
These aren't obvious from reading the plan, but they're important.
Let's go through them one at a time, and please jump in with thoughts.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

💡 Insight #1: Session Invalidation Cascade

Hey, so I was looking at Phase 2 where we're switching from JWT to OAuth...

Did you know that when we deploy this change, every single user who's
currently logged into the system gets forcibly kicked out? Not gracefully
logged out - hard disconnect, session gone, right now.

Here's what happens:
1. We deploy the new OAuth-based auth code
2. All existing JWT tokens become unrecognized by the new system
3. Next API call from ANY active user → 401 Unauthorized
4. User sees "Session expired, please log in again"
5. If 500 users are active → 500 simultaneous re-login attempts
6. OAuth provider rate limits could kick in
7. Support gets flooded with "I got logged out!" tickets

This means:
- Potential OAuth provider rate limiting if everyone hits it at once
- Support team needs warning and documentation
- Users could lose unsaved work (shopping carts, draft posts, etc.)
- Really bad UX if we deploy during peak hours
- Could look like a security breach to users (mass logout)

For example, imagine we deploy at 2pm on a Tuesday (peak usage).
500 active users suddenly see auth errors. They try to log back in all at
once. OAuth provider's rate limit is 100 req/min. Now we have 400 users
locked out for 4 minutes, getting angrier by the second.

What do you think about this? Should we:
A) Add a migration phase where both JWT and OAuth work for 24 hours?
B) Schedule deployment for 3am Sunday when usage is low?
C) Build a session migration tool that converts tokens on-the-fly?
D) Accept the hard cutover and just notify users via banner?

[WAIT FOR HUMAN RESPONSE]

[Human]: Let's go with option B - 3am Sunday deployment. Adding migration
logic feels like complexity we'll have to maintain. Can we add a maintenance
banner 1 hour before?

Great call - keeping it simple. A maintenance banner makes total sense.

✓ Decision: Scheduled maintenance deployment Sunday 3am EST
✓ Rationale: Minimizes user impact, avoids complex migration code
✓ Action items:
  - [ ] Add maintenance banner feature (1 hour warning)
  - [ ] Update deployment docs with timing requirement
  - [ ] Brief support team on expected Monday questions
✓ Affects: Phase 5 (Deployment), Phase 1 (need banner component)

Perfect. Moving to insight #2...

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

💡 Insight #2: OAuth Scope Creep Risk

[Continue similarly for insights 2-5...]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[After all 5 insights discussed...]

✅ "Did You Know" Clarity Session Complete

📊 Session Results:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📝 Analyzed: OAuth Integration Implementation Plan v1.0
💡 Insights: 5 critical discoveries
✓ Decisions: 7 made
📋 Actions: 12 follow-up items
📍 Updates needed: 3 phases

🎯 Top Insights:
1. Session Invalidation Cascade → Sunday 3am deployment + banner
2. OAuth Scope Creep Risk → Lock to email/profile only
3. Token Refresh Edge Cases → Add 5min grace period
4. Mobile App Token Storage → Use platform secure storage
5. Audit Log Gap → Add OAuth event logging to Phase 3

📄 Documentation:
Updated: docs/plans/002-oauth-integration/oauth-plan.md
Section: "Critical Insights Discussion" (appended at end)

🚀 Recommended Next Action:
Update Phase 1 tasks to include maintenance banner component, then
proceed with /plan-5-phase-tasks-and-brief --phase "Phase 1: Setup"

💭 Confidence: High
We have high confidence in proceeding. Key risks identified and mitigated.
```

## Integration with Workflow

**This is a standalone clarity utility - invoke whenever needed:**

✨ **Common Usage Patterns:**

After creating a spec:
```bash
/didyouknow --spec docs/plans/002-feature/feature-spec.md
# Surfaces implications of what we're building
```

After generating a plan:
```bash
/didyouknow --plan docs/plans/002-feature/feature-plan.md
# Discusses what we're about to implement
```

Before starting a complex phase:
```bash
/didyouknow --tasks docs/plans/002-feature/tasks/phase-3/tasks.md
# Clarifies task interactions and dependencies
```

After implementing something:
```bash
/didyouknow --code src/auth/oauth-handler.ts
# Understands what changed and implications
```

When feeling uncertain:
```bash
/didyouknow
# Auto-detects context and builds clarity
```

**No other commands reference this - it's optional and on-demand.**

## Output Files

1. **Updated Source Document**: Original file + "Critical Insights Discussion" section
2. **Console Summary**: Session recap with decisions and next steps

No new files created - insights are documented inline with the artifact being analyzed.

## Why This Works

✅ **Universal** - Works on any artifact at any stage
✅ **Natural** - Feels like talking to a smart, thoughtful teammate
✅ **Actionable** - Leads to real decisions and improvements
✅ **Documented** - Creates permanent record of insights
✅ **Non-blocking** - Optional clarity tool, doesn't delay workflow
✅ **Depth-first** - One insight at a time = deeper understanding
✅ **Collaborative** - True conversation, not information dump
✅ **Preventive** - Catches problems before they become expensive

This is your water-cooler conversation engine - use it whenever you need to step back and really understand what's happening.
````

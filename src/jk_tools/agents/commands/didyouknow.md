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

**Complexity-Aware Analysis (When Analyzing Plans/Tasks):**

If analyzing a plan or tasks document that includes CS (Complexity Score) ratings:

- **CS-1 (Trivial)**: Focus on "what could make this NOT trivial?" - hidden assumptions, edge cases
- **CS-2 (Small)**: Focus on integration points - "what else does this touch?"
- **CS-3 (Medium)**: Focus on testing strategy - "how do we prove this works?"
- **CS-4 (Large)**: Focus on rollout safety - "what's the rollback plan?"
- **CS-5 (Epic)**: Focus on phasing - "how do we break this down further?"

**Complexity Insights to Consider:**
- **Scope underestimation**: "This task is marked CS-2, but did you know it touches 5 external systems?" → Recommend re-scoring to CS-4
- **Testing gap**: "These CS-4 tasks have no staged rollout plan" → Recommend adding feature flags + monitoring
- **Risk mismatch**: "CS-5 task has no subtask breakdown" → Recommend /plan-5 --subtask for decomposition
- **Breadth discovery**: "Surface Area factor is underestimated" → Discuss actual file count vs estimate

**Selection Criteria - Choose the 5 most impactful insights that are:**
1. **Truly impactful** - Not trivial observations, but things that matter
2. **Non-obvious** - Not explicitly stated in the docs, requires deep analysis
3. **Actionable** - Leads to decisions, changes, or important acknowledgments
4. **Discussion-worthy** - Promotes meaningful conversation and alignment
5. **Prioritized** - Ordered by impact (most critical first)
6. **Complexity-conscious** - When CS scores exist, validate them and surface mismatches

**Quality Bar:**
- Each insight should make the human go "Wow, I didn't think of that"
- Each insight should change how we think about the work
- Each insight should prevent a future problem or improve the outcome
- Insights should span different perspectives (not all technical, not all UX)
- When analyzing scored work, challenge CS ratings that seem misaligned with actual scope/risk

### 3) CONVERSATIONAL PRESENTATION (One at a Time - CRITICAL!)

**For EACH of the 5 insights, follow this exact structure:**

**IMPORTANT**: Start directly with the "Did you know" statement. No conversational preamble like "Can we talk about..." or "Hey, so I was thinking...". Get straight to the insight.

#### a) The Core Insight (Clear "Did you know" statement - START HERE)
State it directly and clearly - no preamble needed:
- "Did you know that when we [action], [consequence]?"
- "Did you know this means [implication]?"
- "Did you know users will experience [change]?"
- "Did you know the system will now [behavior]?"

Make it specific and concrete, not vague.

#### b) Deep Dive (Explain the implications)
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

#### c) Options & Recommendation (Actionable Paths Forward)
Present 2-4 concrete options for addressing the insight:

```markdown
Here are our options:

**Option A: [Approach Name]**
- [What this involves]
- Pros: [Benefits]
- Cons: [Tradeoffs/risks]
- Complexity: CS-[1-5] ([trivial/small/medium/large/epic])

**Option B: [Approach Name]**
- [What this involves]
- Pros: [Benefits]
- Cons: [Tradeoffs/risks]
- Complexity: CS-[1-5] ([trivial/small/medium/large/epic])

**Option C: [Approach Name]**
- [What this involves]
- Pros: [Benefits]
- Cons: [Tradeoffs/risks]
- Complexity: CS-[1-5] ([trivial/small/medium/large/epic])

**My Recommendation: Option [X]**

Here's why I think [Option X] is the best path:
1. [Primary reason - addresses the core concern]
2. [Secondary reason - practical/feasible]
3. [Tertiary reason - fits project constraints]

However, [acknowledge valid aspects of other options or when they might be better].
```

Then invite discussion:
- "What do you think about this recommendation?"
- "Does [Option X] align with your priorities, or would you prefer [Option Y] because of [reason]?"
- "Are there constraints I'm not seeing that would favor a different option?"
- "Should we adjust any of these options to better fit our situation?"

Make it a REAL question that acknowledges uncertainty and invites challenge to your recommendation.

#### d) **WAIT for Human Response**
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

#### e) Capture Decision (After discussion concludes)
Summarize what was decided:
```markdown
✓ Decision: [What was decided]
✓ Rationale: [Why this decision makes sense]
✓ Action items: [Any follow-up tasks if applicable]
✓ Affects: [Which parts of spec/plan/tasks this impacts]
```

#### f) **IMMEDIATE UPDATES (Critical - Don't Wait!)**
**Before moving to the next insight, immediately update affected documents.**

If the decision requires changes to spec/plan/tasks/code:
1. **Identify affected files** from the "Affects" section
2. **Read the current content** of those files if needed
3. **Make the updates** using appropriate editing tools
4. **Confirm the updates** to the human:
   ```markdown
   ✅ Updated [file-path]:
   - [Change 1]
   - [Change 2]
   ```

**Examples of immediate updates:**
- Decision adds new task → Update tasks.md with the new task
- Decision changes deployment strategy → Update deployment section in plan
- Decision requires new component → Add to Phase requirements
- Decision adds constraint → Update spec with new constraint
- Decision creates action item → Add to appropriate task list

**Do NOT:**
- ❌ Wait until all 5 insights are done
- ❌ Just note that updates are needed
- ❌ Skip updates because you'll "do them later"

**The updates must happen NOW, while the discussion is fresh.**

After updates are complete, then move to the next insight:
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

**Important**: Affected documents are updated IMMEDIATELY after each insight (step 3f above). This section is about the final session summary.

After all 5 insights have been discussed and their updates applied, append to the **SOURCE DOCUMENT** (the file that was analyzed):

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

**Options Considered**:
- Option A: [Name] - [Brief description]
- Option B: [Name] - [Brief description]
- Option C: [Name] - [Brief description]

**AI Recommendation**: [Option X - Name]
- Reasoning: [1-2 sentences explaining why this was recommended]

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

**Options Considered**:
- Option A: [Name] - [Brief description]
- Option B: [Name] - [Brief description]
- Option C: [Name] - [Brief description]

**AI Recommendation**: [Option X - Name]
- Reasoning: [1-2 sentences explaining why this was recommended]

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
✅ Updates applied: [count] files updated throughout session

🎯 Top Insights & Recommendations:
1. [Insight 1 title]
   💡 Recommended: [Option name] → [Key decision made]
2. [Insight 2 title]
   💡 Recommended: [Option name] → [Key decision made]
3. [Insight 3 title]
   💡 Recommended: [Option name] → [Key decision made]
4. [Insight 4 title]
   💡 Recommended: [Option name] → [Key decision made]
5. [Insight 5 title]
   💡 Recommended: [Option name] → [Key decision made]

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
- [ ] **Updates applied IMMEDIATELY after each insight** (not deferred to end)
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
- ❌ Deferring updates until the end instead of doing them immediately
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

Did you know that when we deploy this change from JWT to OAuth, every single
user who's currently logged into the system gets forcibly kicked out? Not
gracefully logged out - hard disconnect, session gone, right now.

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

Here are our options:

**Option A: Dual-Auth Migration Period (24 hours)**
- Support both JWT and OAuth simultaneously for 24 hours
- Pros: Zero disruption, graceful transition, users can finish sessions
- Cons: Complex code, temporary technical debt, security risk window
- Complexity: CS-4 (large - requires dual auth logic + cleanup later)

**Option B: Off-Peak Deployment Window**
- Schedule deployment for 3am Sunday EST (lowest usage)
- Pros: Simple, minimal user impact (~10-20 active users)
- Cons: Requires weekend deployment, still disrupts some users
- Complexity: CS-2 (small - just timing + maintenance banner)

**Option C: On-the-Fly Token Migration**
- Build migration tool that converts JWT→OAuth tokens automatically
- Pros: Zero user disruption, can deploy anytime
- Cons: Very complex, risky token conversion logic, potential security issues
- Complexity: CS-5 (epic - complex migration logic with security concerns)

**Option D: Hard Cutover with Warning Banner**
- Deploy during business hours, show 1-hour warning banner
- Pros: Simple, transparent to users
- Cons: Disrupts all active users, potential rate limiting chaos
- Complexity: CS-2 (small - just add banner)

**My Recommendation: Option B (Off-Peak Deployment)**

Here's why I think Option B is the best path:
1. **Minimizes disruption** - Only 10-20 users affected vs 500
2. **Keeps it simple** - No complex migration code to maintain/debug
3. **Reduces risk** - Fewer concurrent logins = no rate limit issues
4. **Reasonable effort** - Just add a maintenance banner (needed anyway)

However, if weekend deployments are a hard constraint for your team,
Option A becomes worth considering despite the complexity.

What do you think about this recommendation? Does weekend deployment
work for your team, or should we explore Option A instead?

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

Let me update those sections right now...

[Updates Phase 5 deployment section with timing requirement]
[Updates Phase 1 to add maintenance banner component]

✅ Updated docs/plans/002-oauth-integration/oauth-plan.md:
- Phase 5: Added deployment window requirement (Sunday 3am EST)
- Phase 5: Added pre-deployment banner requirement (1hr warning)
- Phase 1: Added maintenance banner component to deliverables

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
✅ Updates applied: 1 file updated (3 phases modified throughout session)

🎯 Top Insights & Recommendations:
1. Session Invalidation Cascade
   💡 Recommended: Off-Peak Deployment → Sunday 3am deployment + banner
2. OAuth Scope Creep Risk
   💡 Recommended: Minimal Scope Strategy → Lock to email/profile only
3. Token Refresh Edge Cases
   💡 Recommended: Grace Period Approach → Add 5min grace period
4. Mobile App Token Storage
   💡 Recommended: Platform Keychain → Use platform secure storage
5. Audit Log Gap
   💡 Recommended: Event Logging Extension → Add OAuth event logging to Phase 3

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

1. **Affected Documents**: Updated throughout the session as each insight is discussed (specs, plans, tasks, etc.)
2. **Updated Source Document**: Original file + "Critical Insights Discussion" section appended at end
3. **Console Summary**: Session recap with decisions and next steps

No new files created - insights and updates are applied to existing documents as the conversation progresses.

## Why This Works

✅ **Universal** - Works on any artifact at any stage
✅ **Natural** - Feels like talking to a smart, thoughtful teammate
✅ **Actionable** - Leads to real decisions and improvements
✅ **Immediate** - Updates applied right away, not deferred to end
✅ **Documented** - Creates permanent record of insights
✅ **Non-blocking** - Optional clarity tool, doesn't delay workflow
✅ **Depth-first** - One insight at a time = deeper understanding
✅ **Collaborative** - True conversation, not information dump
✅ **Preventive** - Catches problems before they become expensive

This is your water-cooler conversation engine - use it whenever you need to step back and really understand what's happening.
````

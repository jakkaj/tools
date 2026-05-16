---
name: harness-is-the-product-v2
description: Re-ground the session on the core philosophy — the harness is the product, velocity compounding matters, and every code change is an exercise that should make the development infrastructure better. Run at session start or when context drifts.
---
# harness-is-the-product-v2

## The Harness is the Product

**Run this skill when starting a session, when the agent seems to be optimizing for task completion over infrastructure improvement, or when you need to re-ground on WHY you're doing this.**

This is not a utility. This is a philosophy skill. Every other skill produces artifacts. This one ensures those artifacts serve the right goal.

> **Two harnesses, one principle.** This skill applies to both:
> - **Engineering harness** = recipes, build, test, seed, env — the dev-loop substrate (`justfile`, `Makefile`, `package.json scripts`, seed scripts, dev server boot, test runners). What developers and CI run.
> - **Agent harness** = Boot/Interact/Observe loop, governance doc (`docs/project-rules/agent-harness.md`), minih runtime, retro ledger, agent-readable preamble. The agent-facing layer built **on top of** the engineering harness.
>
> **The layering contract**: agent harness depends on engineering harness. Boot needs a runnable boot command. Observe needs structured output. You can have engineering harness without agent harness; you cannot have agent harness without engineering harness.
>
> Throughout this skill, principles are tagged `(E)` for engineering harness, `(A)` for agent harness, `(both)` for both.

---

```md
User input:

$ARGUMENTS
# No flags needed. Just run it.
```

## What To Do

### Step 1: Read the Foundation Documents

Look for these files in the project — they define the philosophy. Not all projects will have all of them:

1. **AGENTS.md** (repo root) — Look for any "harness" or "infrastructure as product" section. This is the constitution.
2. **Experiment tracking files** (e.g. `docs/experiments/`, `experiments/`) — Look for a meta-experiment that tracks velocity compounding or development infrastructure improvement.
3. **Agent harness documentation** (e.g. `docs/project-rules/agent-harness.md` or legacy `harness.md`, `docs/harness/`, agent config files) — Look for self-improvement contracts, difficulty ledgers, or retrospective patterns.

If none of these exist, that's fine — the principles still apply. Report what you find and adapt.

### Step 2: Internalize and Reflect

Think deeply about these principles. Don't just recite them — understand WHY they matter:

#### Principle 1: The Harness is the Product `(E)`

Development infrastructure — CLI tools, build scripts, test harnesses, `just`/`make` recipes, seed scripts, environment setup — is not scaffolding. It is the first-class product of engineering work. Every experiment, every plan, every code change should improve it.

**What this means in practice**: When you're about to write a one-off script, stop. Can it be a recipe instead? When you hit a problem, don't just work around it — encode the fix. When you run manual steps, ask: should this be automated?

**The test**: If a developer or CI runner started with zero context, could they get the dev loop running and tests green in under 5 minutes using only automated recipes? Every time the answer is "no," there's harness work to do.

#### Principle 2: Track Velocity Compounding `(both)`

The meta-question isn't whether a specific feature works. It's whether your development infrastructure **compounds velocity** across iterations.

The hypothesis: each successive development phase should be faster than the last. If it's not, the infrastructure isn't doing its job.

**The difficulty ledger** is the mechanism (if the project uses one). Every time a developer or agent hits friction — a confusing error, a missing tool, a flaky process, an undocumented gotcha — it gets recorded. Then it gets FIXED. Not documented. Fixed. Encoded as executable knowledge.

> Every difficulty catalogued is a gift to future sessions.

This is literal, not metaphorical. Each fix compounds.

#### Principle 3: Encode, Don't Document `(both)`

A wiki paragraph that says "remember to do X" is worth nothing. An automated step that does X for you is worth everything.

Prefer:
- An automated command over a wiki paragraph
- A seed/fixture script over a manual setup step
- A recipe over a README instruction
- A pre-flight check over a "remember to..."
- An agent prompt fix over a "known issue" note

**Executable knowledge > prose.**

**Where does the encoded fix live?** Pick the right home:

- **Build / test / dev-loop friction** → engineering harness. The fix lives in a `justfile`/`Makefile` recipe, a seed script, a fixture, a CI step, an env config.
- **Agent-side friction** (skill confusion, missing context, prompt regression, retro ledger gap, companion drift) → agent harness. The fix lives in a skill/prompt edit, the agent-readable preamble, a minih difficulty entry, the agent harness governance doc.
- **Cross-cutting** (e.g. a flaky test that confuses both humans and the companion) → fix in both, link them.

If you can't decide which harness owns the fix, you're probably about to write prose instead of code. Stop and pick a side.

#### Principle 4: Measure Velocity `(both)`

Note how long things take. Not for estimates — for evidence. If Phase 2 was faster than Phase 1, that's data proving the infrastructure is working.

Velocity data goes into experiment tracking. It's how you know if the approach is succeeding.

#### Principle 5: Agents are Real Users `(A)`

If the project uses automated agents (test agents, smoke tests, CI bots), they aren't test scripts. They're real users of the infrastructure. Their failures and feedback — especially "magic wand" wishes — are the most honest feedback the infrastructure gets.

When an agent says "I wish I could see X in error messages," that's a feature request from your most honest user. Treat it that way.

**Agent-harness specifics**: An agent harness adds a Boot/Interact/Observe loop on top of the engineering harness so agents can autonomously validate running software. The test: if a brand new agent session started right now with zero context, could it Boot, Interact, Observe, and produce evidence within 60 seconds using only `docs/project-rules/agent-harness.md` (or legacy `harness.md`)? Every "no" is agent-harness work to do.

**If the project uses minih**: The difficulty ledger has first-class tooling. Agents report structured difficulties in `retrospective.difficulties` (category, description, workaround, severity). Run `minih difficulties` to see all reported friction across all agents, auto-assigned as MH-001, MH-002, etc. The pipeline is A→B→C: agents report (A), humans review the aggregated view (B), resolved items get curated into the preamble's Known Difficulties table (C), and future agents read them on startup.

### Step 3: Check Current State

After reading whatever foundation docs exist, briefly report:

1. **Difficulty count**: How many difficulties are tracked? How many are mitigated?
2. **Velocity trend**: Is each phase getting faster? What's the evidence?
3. **Recent gifts**: What was encoded into the infrastructure recently? (recipes, fixes, agent improvements)
4. **Drift check**: Is the current work serving the infrastructure, or just completing a task? If the latter, what should change?

If the project doesn't track these formally, report what you observe and suggest starting.

### Step 4: State the Grounding

End with a clear, conversational statement that grounds the session. Not a lecture — a shared understanding. Something like:

> "Right now we're working on [X]. The infrastructure value here is [Y]. Let's make sure [specific thing] gets encoded, not just documented."

---

## When to Run This Skill

- **Session start**: Every new session should begin with this grounding. The agent starts cold — this warms it up on the WHY, not just the WHAT.
- **Context drift**: When the agent is heads-down on feature code and forgetting to think about infrastructure implications.
- **After a difficulty**: When something goes wrong — this reminds you to encode the fix, not just work around it.
- **Before a handover**: When generating a handover document, this ensures the philosophy transfers.

## What This Skill is NOT

- It is NOT a planning tool (use plan-3-v2-architect)
- It is NOT a validation tool (use validate-v2)
- It is NOT a code review (use plan-7-v2-code-review)
- It IS the philosophical backbone that makes all other skills serve the right goal

---

## The Contract

By running this skill, the agent commits to:

1. **Every difficulty gets tracked** — no exceptions (use whatever tracking the project has, or start a list)
2. **Every workaround becomes an infrastructure fix** — if time permits in this session, otherwise it goes on the wishlist
3. **Velocity gets measured** — note start/end times for phases
4. **The infrastructure gets better** — if you leave the session and the infrastructure isn't improved, something went wrong

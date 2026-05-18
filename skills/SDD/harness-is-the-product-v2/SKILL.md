---
name: harness-is-the-product-v2
description: Re-ground the session on the core philosophy — the engineering harness IS the product, every captured friction entry compounds value, and every code change is an exercise that should make the development infrastructure better. Run at session start or when context drifts.
---
# harness-is-the-product-v2

## The Harness is the Product

**Run this skill when starting a session, when the agent seems to be optimizing for task completion over infrastructure improvement, or when you need to re-ground on WHY you're doing this.**

This is not a utility. This is a philosophy skill. Every other skill produces artifacts. This one ensures those artifacts serve the right goal.

> **The engineering harness is the umbrella.** It covers both layers:
> - **Substrate** — recipes, build, test, seed, env (`justfile`, `Makefile`, `package.json scripts`, seed scripts, dev server boot, test runners). What developers and CI run directly.
> - **Agent-facing overlay** — the Boot → Interact → Observe loop, governance doc (`docs/project-rules/engineering-harness.md`), minih runtime, retro ledger, agent-readable preamble. The layer that lets agents iterate on running software in 30-60 second cycles.
>
> Treat them as one cohesive thing with two layers. The overlay depends on the substrate (Boot needs a runnable boot command; Observe needs structured output), but governance, friction tracking, and the "encode-don't-document" principle apply to both equally. Principle bodies below call out substrate-specific or agent-facing-specific guidance inline only when the distinction is load-bearing.

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
3. **Engineering harness documentation** (e.g. `docs/project-rules/engineering-harness.md`, legacy `agent-harness.md` / `harness.md`, `docs/harness/`, agent config files) — Look for self-improvement contracts, difficulty ledgers, or retrospective patterns.

If none of these exist, that's fine — the principles still apply. Report what you find and adapt.

### Step 2: Internalize and Reflect

Think deeply about these principles. Don't just recite them — understand WHY they matter:

#### Principle 1: The Harness is the Product

Development infrastructure — CLI tools, build scripts, test harnesses, `just`/`make` recipes, seed scripts, environment setup, plus the agent-facing Boot/Interact/Observe loop on top — is not scaffolding. It is the first-class product of engineering work. Every experiment, every plan, every code change should improve it.

**What this means in practice**: When you're about to write a one-off script, stop. Can it be a recipe instead? When you hit a problem, don't just work around it — encode the fix. When you run manual steps, ask: should this be automated?

**The test**: If a developer or CI runner started with zero context, could they get the dev loop running and tests green in under 5 minutes using only automated recipes? Every time the answer is "no," there's harness work to do.

#### Principle 2: Track Compounding Value

The meta-question isn't whether a specific feature works. It's whether your development infrastructure **compounds value** across iterations — each captured friction entry making the next session cheaper, safer, clearer, or more repeatable. Minih frames the same idea as the "compound velocity hypothesis" — same shape, different vocabulary. Both are about the same trajectory: each successive development phase should be smoother than the last because the previous session encoded what it learned.

If it's not, the infrastructure isn't doing its job.

**The compound ledger** is the mechanism (`docs/compound/`, scaffolded by `compound-0-setup`). Every time a developer or agent hits friction — a confusing error, a missing tool, a flaky process, an undocumented gotcha — `compound-1-track` logs it silently. `compound-2-bubble` surfaces accumulated entries at session-end with a soft prompt. `compound-3-harvest` curates them at long-horizon reflection moments. Then it gets ENCODED. Not documented. Encoded — into a justfile recipe, a skill edit, a plan, or a staged diff.

> Every difficulty catalogued is a gift to your future self.

This is literal, not metaphorical. Each encoded fix compounds.

#### Principle 3: Encode, Don't Document

A wiki paragraph that says "remember to do X" is worth nothing. An automated step that does X for you is worth everything.

Prefer:
- An automated command over a wiki paragraph
- A seed/fixture script over a manual setup step
- A recipe over a README instruction
- A pre-flight check over a "remember to..."
- An agent prompt fix over a "known issue" note

**Executable knowledge > prose.**

**Where does the encoded fix live?** Pick the right home:

- **Build / test / dev-loop friction** → substrate layer. The fix lives in a `justfile`/`Makefile` recipe, a seed script, a fixture, a CI step, an env config.
- **Agent-side friction** (skill confusion, missing context, prompt regression, retro ledger gap, companion drift) → agent-facing overlay. The fix lives in a skill/prompt edit, the agent-readable preamble, a compound entry (logged silently by `compound-1-track`, surfaced at session end by `compound-2-bubble`, encoded as a diff in `scratch/`), or the engineering harness governance doc's auto-seeded `## Known Difficulties` section.
- **Cross-cutting** (e.g. a flaky test that confuses both humans and the companion) → fix in both layers, link them.

If you can't decide which layer owns the fix, you're probably about to write prose instead of code. Stop and pick.

#### Principle 4: Measure Compounding Value

Note what each session encodes. Not for estimates — for evidence. If Session N+1 starts with a `## Known Difficulties` table that already knows about the friction Session N hit, that's data proving the loop is closing.

`compound-3-harvest`'s terminal view is the dashboard. Run it periodically; check the trajectory — encoded entries growing while open entries cluster around real (not vague) friction.

#### Principle 5: Agents are Real Users

If the project uses automated agents (test agents, smoke tests, CI bots, plan-6 companions), they aren't test scripts. They're real users of the infrastructure. Their failures and feedback — especially "magic wand" wishes — are the most honest feedback the infrastructure gets.

When an agent says "I wish I could see X in error messages," that's a feature request from your most honest user. Treat it that way.

**Agent-facing overlay specifics**: The Boot/Interact/Observe loop on top of the substrate lets agents autonomously validate running software. The test: if a brand new agent session started right now with zero context, could it Boot, Interact, Observe, and produce evidence within 60 seconds using only `docs/project-rules/engineering-harness.md` (or legacy `agent-harness.md` / `harness.md`)? Every "no" is overlay work to do.

**If the project uses minih or compound**: friction surfaces via the universal `.retro.md` contract. Minih emits a retrospective at each run; `compound-1-track` logs entries silently during work; both land in `docs/compound/agents/<slug>/<date>/`. Run `compound-3-harvest [--plan <slug>] [--kind <kind>]` to see clustered friction. The pipeline is: agents observe (silent log) → user triages at session end (`compound-2-bubble` soft prompt) → resolved items mutate `system.compound.status` and surface in the engineering harness governance doc's `## Known Difficulties` table at next boot read.

### Step 3: Check Current State

After reading whatever foundation docs exist, briefly report:

1. **Ledger state**: How many entries are tracked in `docs/compound/` (or legacy `docs/retros/`)? How many are `encoded` vs `open` vs `suggested`?
2. **Compounding trend**: Are recent sessions cheaper because earlier sessions encoded what they learned? What's the evidence (entries marked `encoded` with `resolved_by` set; `## Known Difficulties` showing real recurring issues)?
3. **Recent gifts**: What was encoded into the infrastructure recently? (recipes, fixes, agent improvements — staged diffs in `scratch/encode-*.diff` or merged commits)
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

1. **Every difficulty gets tracked** — silently logged via `compound-1-track` (or whatever tracking the project has; start a list if none)
2. **Every workaround becomes an infrastructure fix** — if time permits in this session, encoded as a diff in `scratch/`; otherwise it bubbles up via `compound-2-bubble` for the user to triage at session end
3. **Compounding value gets measured** — the ledger trajectory (encoded vs open vs stale) is the evidence; `compound-3-harvest` is the dashboard
4. **The infrastructure gets better** — if you leave the session and the infrastructure isn't improved (even by one entry encoded), something went wrong

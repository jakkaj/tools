Yes — that’s the right extension.

The useful move is:

> **Ponytail-for-code becomes elegance-for-work.**
> Not “write less” everywhere, but “produce the smallest artifact that can safely move the build forward.”

For the-flow, elegance should shape **plans, workshops, task dossiers, implementation behavior, execution logs, reviews, and merge plans**, not only the seam narration.

# Addendum: Elegance Across the-flow Artifacts

## Core principle

```md
Elegance is the shortest complete path from intent to confident action.

For code, that means the smallest boring implementation that works.
For plans, that means the smallest artifact that makes the next build safe.
For workshops, that means the smallest proof that resolves the decision.
For tasks, that means the smallest task row a competent implementer can execute.
For implementation, that means the smallest change that satisfies the plan without losing evidence.
```

This fits the-flow because stage `1b plan` already writes one canonical document containing both the business specification and implementation plan in one atomic pass; workshops are authoritative design decisions; tasks produce a phase dossier; and implementation consumes the approved phase while keeping progress and logs current.    

---

# The artifact ladder

Add this as a shared doctrine used by all stage modules:

```md
## Artifact Elegance Ladder

Before adding content, climb this ladder and stop at the first rung that safely works:

1. Can this be omitted because it does not change a decision, implementation, test, or risk?
2. Can this be represented as a table row, checklist item, example, command, diff, or schema instead of prose?
3. Can this be captured once and referenced, instead of repeated across sections?
4. Can this be deferred to a workshop, ADR, or clarification round because the main plan does not need the depth yet?
5. Can this be marked as an unresolved gap instead of padded with guesswork?
6. Only then write prose — and make it decision-bearing.
```

This adapts Ponytail’s “minimal working code” idea into **minimal working artifacts**.

---

# Stage-specific rules

## 1. Plan elegance

The plan is not a thesis. It is a build contract.

Current `plan` already has the right structure: one document, business half first, implementation half second, gates G1–G7, single status, gap markers, and validation at the end.  

Add this:

```md
## Elegance Rules for Plans

A plan should contain only content that changes one of:
- what is being built,
- why it matters,
- where it belongs,
- how it will be implemented,
- how it will be tested,
- what can go wrong,
- what decision remains unresolved.

Prefer:
- concrete acceptance criteria over explanatory goals,
- domain tables over domain essays,
- phase boundaries over long implementation narratives,
- explicit gaps over speculative filler,
- one recommended mode over ceremony by default.

Default to Simple unless the work structurally earns Full.
Unfamiliarity is not complexity; use research or workshop for uncertainty.
```

The current file already says Simple is the recommended default and Full should be reserved for genuinely complex or structurally demanding work.  That is exactly where Ponytail-style elegance belongs.

### Plan example

Verbose:

```md
This feature will introduce a new API endpoint that allows callers to create widgets. The implementation should follow existing service conventions and will need validation, persistence, tests, and documentation. Because this endpoint has implications for user input, storage, and possible downstream rendering, we should be careful to ensure the schema is robust and that the response shape is consistent.
```

Elegant:

```md
### Acceptance Criteria

| ID | Criterion | Verification |
|---|---|---|
| AC-01 | `POST /api/widgets` creates a widget with `name` and `color`. | API test returns `201` with persisted widget ID. |
| AC-02 | Invalid color returns `400` with field error. | API test covers unsupported color. |

### Target Domains

| Domain | Status | Role |
|---|---|---|
| widgets | existing | Owns widget validation and persistence. |
```

The second version is shorter, but more buildable.

---

## 2. Workshop elegance

A workshop should not be a “deep dive” by default. It should be a **decision reducer**.

The current workshop skill already frames workshops as working reference documents that reduce ambiguity, risk, review burden, and coordination cost; it also emphasizes concrete examples, proof levels, value axes, and the fresh entrant test.  

Add this:

```md
## Elegance Rules for Workshops

A workshop earns its length only through proof.

Every workshop must make at least one future loop cheaper:
- implementation,
- review,
- testing,
- migration,
- onboarding,
- coordination,
- agent handoff.

Do not expand every possible angle.
Pick the smallest set of representations that proves the topic:
- one diagram when structure matters,
- one table when comparison matters,
- one schema when contract matters,
- one command transcript when operator behavior matters,
- one state machine when transitions matter.

A workshop is done when it resolves the decision or names the exact remaining open question.
```

### Workshop example

Verbose:

```md
## Options Considered

There are several ways we might model widget colors. One option is to use a free-form string, which would be flexible but could create inconsistency. Another option is to use a normalized enum, which would make validation simpler but might require migrations later. Another possibility is to use a separate colors table, which could support future extensibility but might be too much for the current scope.
```

Elegant:

````md
## Decision

Use a fixed enum for `WidgetColor`.

| Option | Keep? | Why |
|---|---:|---|
| Free-form string | No | Too easy to create invalid UI states. |
| Enum | Yes | Smallest contract that supports validation and tests. |
| Colors table | No | Future extensibility not needed for current ACs. |

## Contract

```ts
type WidgetColor = "red" | "blue" | "green";
````

````

This gives the implementer the decision, the rejected alternatives, and the contract without decorative reasoning.

---

## 3. Task elegance

Tasks should not become miniature plans. They should be executable units.

The task stage produces a task table and context brief for exactly one phase, then stops before code changes. :contentReference[oaicite:9]{index=9}

Add this:

```md
## Elegance Rules for Task Dossiers

A task row should answer:
- what to change,
- where to change it,
- what domain owns it,
- how to know it is done.

Avoid:
- multi-paragraph task descriptions,
- motivational text,
- repeating acceptance criteria already in the plan,
- vague Done-When values,
- tasks that mix unrelated domains,
- tasks that cannot be tested or observed.

One task should usually produce one coherent code change.
If a task needs several unrelated files, split it unless the files form one contract.
````

### Task example

Verbose:

```md
T001: Add widget creation support. This includes adding the route, making sure the controller accepts the right fields, validating user input, calling the widget service, persisting the widget, and returning an appropriate response. Make sure this follows existing conventions and is tested.
```

Elegant:

```md
| Status | ID | Task | Domain | Path(s) | Done When |
|---|---|---|---|---|---|
| [ ] | T001 | Add widget create route. | widgets | `src/routes/widgets.ts` | `POST /api/widgets` returns `201` for valid payload and `400` for invalid color. |
| [ ] | T002 | Add persistence call. | widgets | `src/domain/widgets/service.ts` | Created widget is saved and returned with ID. |
| [ ] | T003 | Add route tests. | widgets | `tests/widgets/create.test.ts` | AC-01 and AC-02 pass. |
```

---

## 4. Implementation elegance

Implementation should inherit Ponytail most directly, but still respect the-flow’s artifact discipline.

The current implement stage says to implement exactly one approved phase or subtask, follow the testing approach from the plan, update domain files, keep task progress live, and log discoveries.  

Add this:

```md
## Elegance Rules for Implementation

Implement the smallest change that satisfies the current approved phase.

Prefer:
- existing code paths over new abstractions,
- extending a nearby convention over inventing a pattern,
- one local helper over a framework,
- concrete tests over broad speculative coverage,
- updating existing domain docs over creating new docs.

Do not:
- generalize for imagined future phases,
- refactor unrelated code,
- introduce new libraries unless the plan explicitly requires them,
- widen the domain boundary without updating the domain artifacts,
- hide discoveries in chat instead of the execution log.

When a better simplification appears during implementation, use it only if it still satisfies the plan and acceptance criteria. Otherwise log it as a discovery or follow-up.
```

### Implementation example

Bad:

```md
Create a generic WidgetCommandProcessor abstraction so future widget commands can share behavior.
```

Better:

```md
Add `createWidget(input)` beside the existing widget service functions.
```

Best, when existing behavior already exists:

```md
Reuse `upsertWidget()` with a create-only guard; add validation at the route boundary.
```

That is Ponytail’s ladder translated into implementation behavior.

---

## 5. Execution-log elegance

The execution log should preserve evidence, not narrate the agent’s inner monologue.

Current implementation requires discoveries to be captured in `execution.log.md` and the structured discoveries table. 

Add this:

```md
## Elegance Rules for Execution Logs

Log facts that future agents need.

Good log entries:
- task started/completed,
- files changed,
- tests run and result,
- discovery that changed implementation,
- debt intentionally accepted,
- deviation from plan,
- domain artifact updated.

Do not log:
- routine thinking,
- obvious steps,
- restatements of the task,
- apologies,
- long explanations of commands unless the command failed.
```

### Execution log example

Verbose:

```md
I started by looking at the existing route structure. I noticed there are several route files and I spent some time understanding how they work. Then I decided to add a new widget route using the same style.
```

Elegant:

```md
### T001 — Create widget route

- Changed: `src/routes/widgets.ts`
- Pattern reused: existing `POST /api/projects` handler shape.
- Tests: `tests/widgets/create.test.ts` passing.
- Discovery: route validators live at boundary, not service layer.
```

---

# Cross-artifact rule: prose is the fallback

This is the most important rule to weave throughout the-flow:

```md
Prefer proof-shaped content over explanatory prose.

Use:
- tables for comparisons,
- schemas for contracts,
- examples for behavior,
- commands for operations,
- checklists for completion,
- diffs for fixes,
- diagrams for structure,
- short notes only where judgment is required.
```

Workshops already say “show don’t tell” and prefer real examples, actual outputs, diagrams, tables, code, quick references, and evidence trails.  This should become a general the-flow writing principle, not only a workshop principle.

---

# A small shared section to add today

I’d add this to a shared conventions area or copy it into the top of the main stage modules:

```md
## Elegance Doctrine

Every artifact is a work surface, not a report.

Write the smallest artifact that lets the next actor proceed safely:
- planner,
- workshopper,
- implementer,
- reviewer,
- merger,
- future agent.

A line earns its place only if it:
- changes a decision,
- constrains implementation,
- proves behavior,
- exposes risk,
- records evidence,
- preserves user intent,
- or enables the next action.

Prefer examples, tables, schemas, commands, checklists, and diffs over prose.
Prefer explicit gaps over speculative filler.
Prefer Simple mode unless Full is structurally earned.
Prefer local, boring implementation over generalized machinery.
```

---

# Concrete edits I’d make now

## `20-plan.md`

Add:

```md
### Plan Elegance

The plan is a build contract, not a thesis.

Keep only content that changes the build:
- user value,
- acceptance criteria,
- target domains,
- constraints,
- phase boundaries,
- testing strategy,
- risks,
- unresolved gaps.

Default to Simple unless the work structurally earns Full.
When in doubt, reduce ceremony; use research or workshop for uncertainty.
```

## `25-workshop.md`

Add:

```md
### Workshop Elegance

A workshop earns depth through proof, not length.

Before adding a section, ask what downstream loop it makes cheaper:
implementation, review, testing, migration, onboarding, coordination, or agent handoff.

Use the fewest representations that resolve the decision.
End with the selected option, rejected alternatives, implementation contract, and remaining open questions.
```

## `50-phase-tasks.md`

Add:

```md
### Task Elegance

A task row is executable if a competent implementer can start without rereading the full plan.

Each task needs:
- action,
- domain,
- path,
- Done When.

Split tasks that mix unrelated domains, unrelated files, or unrelated acceptance criteria.
Do not duplicate plan prose in task notes.
```

## `60-implement.md`

Add:

```md
### Implementation Elegance

Build the smallest approved change.

Reuse existing patterns before adding abstractions.
Do not generalize for future phases unless the current plan requires it.
Do not refactor unrelated code.
Log discoveries as evidence, not narration.
When simplification conflicts with the plan, stop and record the gap rather than silently changing scope.
```

---

# Revised guiding phrase

I’d make this the memorable phrase for the-flow:

> **Elegant flow means less ceremony, more evidence.**

Or, more operationally:

> **The shortest artifact that safely moves the build forward wins.**


# Report: Elegance Rules for the-flow Skill Writing

## Executive summary

Ponytail’s best idea is not “be terse.” It is **stop at the first rung that works**: question whether something needs to exist, prefer the already-available tool, and only add complexity after simpler options fail. It also has a useful output doctrine: give the result first, then a tiny note on what was skipped and when to add it; avoid essays, tours, and defensive explanations. ([GitHub][1])

For `the-flow`, I would translate that into:

> **Every line must either orient, warn, decide, or enable the next action. Everything else is atmospheric debt.**

This should be woven through the-flow as an **elegance layer**, not imported as Ponytail. the-flow still needs to be a guide, and it still needs to preserve safety, grounding, command visibility, and user control. But the current outputs are over-serving: they often explain the system, justify the seam, and advertise optional paths when the user mainly needs to know **where we are, what matters, and what to do next**.

Flow mechanics such as `the-flow.json`, spine rendering, cursor position, deterministic state, and state ownership are intentionally out of scope here.

---

## What to borrow from Ponytail

Ponytail’s ladder is valuable because it is a **decision reflex**, not a verbosity style. It says to stop at the first working rung, skip speculative work, use existing primitives before inventing new ones, and choose the minimum implementation that works. ([GitHub][1])

For the-flow prose, the equivalent ladder is:

1. **Can the rail alone orient the user?**
   Then do not restate position in prose.

2. **Can one artifact-backed fact carry the seam?**
   Then do not summarize the artifact.

3. **Is there exactly one recommended next step?**
   Then do not list every possible branch.

4. **Is an optional path irrelevant unless the user is blocked or unsure?**
   Then suppress it until summoned.

5. **Is this explanation defending the flow rather than helping the user act?**
   Cut it.

6. **Only then add prose, and only the minimum needed to preserve agency.**

Ponytail also says “deletion over addition,” “boring over clever,” and “shortest working diff wins.” For the-flow, that becomes: **shortest safe seam wins**. ([GitHub][1])

---

## Current the-flow tension

the-flow already has the right raw ingredients. The coach file says each seam should use a short Seam Digest, contextual facets, one sentence per item, no padding, and “when in doubt, cut a line rather than add one.” 

But the templates also ask the guide to narrate why stages matter, point out insights, surface optional branches, suggest compaction, make harness behavior legible, print commands, and offer to run them.  That makes the assistant try to satisfy every teaching goal every time.

The result is predictable: the output becomes correct but bloated.

The fix is not to remove the guide. It is to add **priority and suppression rules** so the guide knows what not to say.

---

## Proposed doctrine: “Elegant Flow”

Add a small doctrine section near the coach voice rules:

```md
## Elegant Flow

the-flow is a guide, not a tour guide.

Every seam output must answer only:
1. Where are we?
2. What changed?
3. What matters?
4. What should I do next?

Prefer the shortest safe seam. The rail carries position. The digest carries substance. The command carries action. Do not add a second explanation of any of those.

A line earns its place only if it:
- orients the user,
- surfaces a decision-relevant warning,
- carries one artifact-backed insight,
- distinguishes a real branch,
- or enables the next action.

If a line does none of those, cut it.
```

This aligns with the existing Seam Digest rules, but makes them enforceable as a thinking model rather than a formatting preference. 

---

## Rules to weave through the-flow skills

### 1. Result before rationale

Use the Ponytail pattern “result first, then skipped/when-to-add” as a general prose pattern. Ponytail’s output section says to put code first, then at most a few short lines about what was skipped and when to add it; the transferable idea is **artifact/action first, explanation second**. ([GitHub][1])

For the-flow:

```md
Artifact first. Then one insight. Then the next command.
```

Avoid:

```md
This stage matters because...
As a reminder...
The flow is designed to...
```

Prefer:

```md
Plan written: `docs/plans/042-auth/auth-plan.md`.
Watch-out: G3 failed on domain boundary.
Next: fix the gap, then re-run plan.
```

---

### 2. One seam, one default

At each seam, the user should see one recommended action. Optional branches should appear only when they are live, useful, and materially different.

Current the-flow already says one accepted step per turn and print-then-offer are invariants.  Extend that:

```md
At a seam, recommend exactly one default.
Show alternatives only when:
- the Graph genuinely forks,
- an artifact raised a warning,
- the user asked for options,
- or skipping the option would hide risk.
```

This reduces “menu fatigue.”

---

### 3. Rail does position; digest does substance

the-flow requires the host rail first on guided turns.  The Seam Digest rules already warn not to restate rail `now`/`next` as prose.  Make this a hard style rule:

```md
Never explain the rail immediately after showing the rail.
Never repeat the same now/next fact in both rail and digest.
```

Bad:

```md
[rail]
Where we are: plan is done and we are moving to tasks.
Just did:
1. Plan is done.
Next up:
1. Tasks are next.
```

Better:

```md
[rail]
Just did:
1. `auth-plan.md` is READY; CS-3, Full.
2. Key risk: token refresh touches `billing` and `identity`.

Next:
1. Write Phase 1 tasks.
```

---

### 4. One insight means one insight

the-flow explicitly wants one concrete insight from the artifact.  Make “one” literal.

```md
Insight budget: exactly one.
If there are multiple interesting things, choose the one that changes the next action.
```

Bad:

```md
Did you notice the phase boundary, the workshop opportunities, the gate status, and the validation results?
```

Better:

```md
Insight: Phase 1 is only schema + validation, so the first build can stay small.
```

---

### 5. Warnings are quoted, capped, and silent when clean

The current Flag beat already says lift warnings from structured fields, cap them, stay silent when clean, and never gate.  Keep that, but remove “nothing flagged — clean” unless the user needs reassurance.

```md
No warning line when clean.
One warning line when dirty.
Max three quoted warnings.
```

Bad:

```md
Watch-outs:
1. Nothing flagged — clean.
```

Better: omit the section.

---

### 6. Optional branches are pull-based by default

the-flow currently surfaces optional branches such as workshops, ADRs, deep research, handover docs, domains, fix loops, and harness seams.  These are useful, but they should not all be advertised repeatedly.

```md
Optional branches are silent unless:
- the artifact explicitly recommends them,
- the user is at the exact seam where the branch pays off,
- or the user asks “what else?” / “options” / “recap”.
```

A compact default could be:

```md
Optional: 2 workshop opportunities exist. Say `options` to inspect them.
```

Do not expand the whole option tree unless asked.

---

### 7. “Why this matters” must be earned

The current coach voice includes “why the stage matters.”  That is useful for new users but noisy for repeated use.

Add:

```md
Explain why a stage matters only:
- the first time in a flow,
- after adoption/resume ambiguity,
- when the user asks,
- or when the next step is non-obvious.
```

This preserves teaching without turning every seam into onboarding.

---

### 8. No defensive architecture prose

Ponytail warns that paragraphs defending a simplification smuggle complexity back in as prose. ([GitHub][2]) the-flow has a similar problem: it sometimes defends the existence of seams, harness behavior, compaction, or atomic planning.

Rule:

```md
Do not justify the flow unless the user is choosing between flow paths.
```

Bad:

```md
The backpressure survey is advisory output that informs the re-plan but does not auto-read coverage, because the plan verb...
```

Better:

```md
Optional: run backpressure, then re-plan with its findings.
```

---

### 9. Preserve safety exceptions

Ponytail explicitly says not to simplify away validation, data-loss prevention, security, accessibility, or anything explicitly requested. ([GitHub][1]) the-flow should mirror that.

Do not compress away:

```md
- merge confirmation requirements,
- unresolved gaps,
- failed gates,
- security or data-loss risks,
- user control over irreversible actions,
- artifact paths needed for copy/paste,
- exact commands.
```

Elegance is not silence where the user needs a warning.

---

### 10. Use “show less, reveal on demand”

The existing Seam Digest has a `recap` summon that reprints current state without advancing.  Extend that pattern:

```md
Supported summons:
- `recap` — current digest
- `options` — optional branches
- `why` — why this step matters
- `details` — expand artifact summary
- `warnings` — show all flagged fields
```

This lets default output stay elegant without hiding depth.

---

## Proposed compact seam template

Use this as the default shape for guided outputs:

````md
[rail block]

**Just did**
1. <artifact + status>.
2. <one insight that affects the next move>.

**Watch-out**
1. <only if flagged; quote the artifact>.

**Next**
1. <recommended action in plain words>.

```bash
/the-flow <id> <verb> ...
````

Run it? `yes` or copy it yourself.

````

If there is no warning, no optional branch, and no real fork, the output should be this small.

---

## Examples of changes to make today

### Example 1: After research

Current spirit:

```md
Research is done. Did you notice X? Optional go deeper with deep-research. Then a seam: compact. Then plan. Your move: deep-research, compact, or straight to plan.
````

Suggested:

````md
[the-flow] ◆─◇─◇─◇  research · [plan] · build · merge

**Just did**
1. `research-dossier.md` is ready.
2. Key finding: auth middleware already validates tenant scope, so the plan should reuse it.

**Next**
1. Write the plan.

```bash
/the-flow 1b plan "add tenant-scoped API keys"
````

Run it? `yes` or copy it yourself.

````

Only mention `/compact` if the dossier is large or the user is heading into implementation.

---

### Example 2: After plan, READY, Full mode

Current version risks becoming a menu of workshops, backpressure, compact, ADR, tasks, and validation notes.

Suggested:

```md
[the-flow] ◆─◆─◇─◇─◇  research · plan · [tasks] · build · merge

**Just did**
1. `api-keys-plan.md` is READY; CS-3, Full.
2. Phase 1 is deliberately narrow: schema, validation, and tests only.

**Next**
1. Write Phase 1 tasks.

```bash
/the-flow 5 tasks --phase "Phase 1: Schema & Validation" --plan "docs/plans/042-api-keys/api-keys-plan.md"
````

Run it? `yes` or copy it yourself.

````

If the plan has workshop opportunities:

```md
**Optional**
1. 2 workshop opportunities exist; say `options` to inspect them before tasks.
````

Do not expand them by default.

---

### Example 3: After plan, DRAFT

Here, verbosity is allowed because the user must see the blocker. But still keep it tight.

````md
[the-flow] ◆─◆─◇─◇  research · [plan] · build · merge

**Watch-out**
1. `G3 Architecture` failed: `identity` would import from `billing`.
2. `AC-04` still has `[NEEDS CLARIFICATION]`.

**Next**
1. Fix the gaps, then re-run plan.

```bash
/the-flow 1b plan "add tenant-scoped API keys"
````

Run it? `yes` or say `show gaps`.

````

This follows the current non-gating rule while keeping attention on the decision-relevant fields. :contentReference[oaicite:17]{index=17}

---

### Example 4: Harness seam

The attached docs already emphasize one harness door and print-then-offer. :contentReference[oaicite:18]{index=18} The verbose failure mode is explaining the harness loop every time.

Suggested first-time line:

```md
Optional harness check: prove the repo is healthy before coding.
````

Command:

```bash
/eng-harness-flow --hook pre-flight --json
```

Offer:

```md
Run it? `yes`, or say `skip`.
```

Later seams:

```md
Optional: harness pre-flight.
```

That is enough unless the envelope reports a problem.

---

## Concrete edits I would make in the skill files

### 1. Add an “Elegant Flow” section to `coach.md`

Place it before “The Seam Digest”:

```md
## Elegant Flow

the-flow is a guide, not a tour.

Default seam output answers only:
1. where we are,
2. what changed,
3. what matters,
4. what to do next.

The rail carries position. The digest carries substance. The command carries action.
Do not restate one in another.

A line earns its place only if it orients, warns, reveals one artifact-backed insight,
distinguishes a real branch, or enables the next action. Otherwise cut it.

Optional branches are pull-based by default. Mention them only when the artifact
raises them, the seam genuinely forks, or the user asks for options.

Explain why a stage matters only on first exposure, adoption/resume ambiguity,
non-obvious next steps, or user request.
```

---

### 2. Tighten the Seam Digest rules

Current rule says the digest is “as short as possible” and every line earns its place.  Add hard budgets:

```md
Default budget:
- Just did: 1-2 lines
- Watch-outs: 0-3 lines
- Next: 1 line unless there is a real fork
- Optional: 0-1 line, preferably summon-based

No section appears just to preserve symmetry.
No “nothing flagged” line unless reassurance is useful.
```

---

### 3. Replace “surface optional branches” with “surface live optional branches”

Current coach voice says to surface optional branches the terse pipeline under-advertises.  Change that to:

```md
Surface live optional branches only: branches that are relevant at this seam,
raised by the artifact, or requested by the user.
```

---

### 4. Add a “verbosity smell” checklist

```md
Before sending a seam response, delete any line that:
- repeats the rail,
- restates the command in prose,
- explains a stage the user has already used,
- advertises an optional branch with no current trigger,
- defends the flow design,
- says “clean” when silence would mean clean,
- summarizes an artifact beyond the one insight,
- teaches mechanics not needed for the next action.
```

---

### 5. Add summon commands to keep depth available

```md
At any seam:
- `recap` reprints the digest.
- `options` expands optional branches.
- `why` explains the recommended next step.
- `details` expands the artifact summary.
- `warnings` prints all structured flags.
```

This gives the assistant permission to be short without losing functionality.

---

## The guiding principle

Ponytail’s final line is “the shortest path to done is the right path.” ([GitHub][2])

For the-flow, I would make the adapted principle:

> **The shortest path to confident next action is the right output.**

Not the shortest output. Not the most complete explanation. The shortest output that leaves the user oriented, safe, and able to move.

[1]: https://github.com/DietrichGebert/ponytail/blob/main/skills/ponytail/SKILL.md "ponytail/skills/ponytail/SKILL.md at main · DietrichGebert/ponytail · GitHub"
[2]: https://github.com/DietrichGebert/ponytail/raw/refs/heads/main/skills/ponytail/SKILL.md "raw.githubusercontent.com"

---

# Evidence addendum — what reliably reduces LLM *output* verbosity

**Source**: Perplexity Sonar deep-research, 2026-06-18 (this session). **Why it's here**: the elegance layer's success hinges on which lever actually changes emitted output. Soft "be terse / every line earns its place" rules already exist in `coach.md` and don't work — this is *why*, and *what to use instead*. The plan stage MUST design the narration changes around this ranking, not around adding more imperatives.

**Constraint that frames everything**: input/prompt tokens are cheap; only emitted **output** tokens are dear. So we may spend freely on prompt-side structure (schemas, examples, default-omit rules) to buy lean output. Shrinking the flow's own on-disk size is a *separate later pass* (out of scope).

**Ranked levers (reliability for cutting output, highest first):**

| Tier | Lever | Mechanism (evidence) | How it lands in the-flow |
|---|---|---|---|
| **1 — rely on these** | **Default-omit framing + pull-based / progressive disclosure** | Concision becomes a series of *binary gates* ("don't emit X unless Y") instead of a global style preference — models follow gates far more reliably. Detail is opt-in. [LaunchDarkly; SLOT arxiv 2505.04016; MindStudio progressive-disclosure] | Summon commands (`recap` exists; add `options`/`why`/`details`/`warnings`) move depth to on-request; "drop a Seam-Digest facet when empty"; **no "nothing flagged — clean" line** (silence = clean); **gated "why this matters"** (first-exposure / resume-ambiguity / on request) |
| **2 — rely on these** | **Few-shot lean exemplars as the dominant pattern** | "Models treat prompts as *patterns to continue*, not rules to obey." 2+ hand-written, structurally-consistent examples; put the ideal (lean) one **last** (recency weighting); convert observed verbose failures into corrected examples. [Min et al. 2022 via promptingguide; Armstrong "Few-Shot Done Properly"] | One worked **lean-vs-verbose Seam Digest** pair + one lean plan/task-table exemplar, lean one last. Input is cheap, so afford the examples |
| **3 — secondary** | **Coarse length budgets in human units** | "max 2 steps", "1 sentence per item", "≤3 bullets" are followed *approximately*; exact token caps are not (models don't count tokens). Dynamic mid-gen feedback helps but can dent quality. [arxiv 2601.01768] | Per-facet budgets (Just-did 1–2, Watch-out 0–3, Next 1, Optional 0–1) — reinforcement, not the guardrail |
| **4 — do NOT add more** | **Imperative "be terse"** | *Weakest.* RLHF verbosity bias (reward models prefer longer answers — GPT-4 included [arxiv 2310.10076]) + instruction-overload decay in long prompts (soft stylistic rules are sacrificed first under load [arxiv 2507.11538]) bury global brevity pleas. Concision is a second-order preference behind correctness/safety/helpfulness. | Keep the existing imperatives only as *local* clarifiers next to the field they govern; **adding more is the failure mode the dossier itself commits** |

**Design takeaways for the plan:**
1. **Lead with tiers 1–2.** The narration win is structural (default-omit + summons) + exemplars — *not* new prose rules.
2. **The existing soft rules are tier 4** — that's the diagnosis for why output is still verbose. Don't pile on more.
3. **Never omit safety content** (gates, `PROCEED`, file paths, failed-gate/gap callouts) — default-omit applies to decorative prose, never to must-see fields. (Matches Ponytail's "never simplify away validation/safety".)
4. Same logic governs **artifact** output (plans/tasks/logs): tight tables/schemas as the contract + lean exemplars > prose instructions to "be concise".

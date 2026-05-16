# Workshop: Self-Improvement Vibe

**Type**: Other (UX / philosophy / interaction-pattern)
**Plan**: 023-difficulty-ledger-skill
**Spec**: Not yet written — this workshop precedes spec. See [research-dossier.md](../research-dossier.md) for the gap diagnosis and proposed shape.
**Created**: 2026-05-16
**Status**: Draft

**Value Thesis**: This workshop reduces the time and human attention required to lock the *feel* of the self-improvement loop before the schema, CLI flow, and AGENTS.md voice get designed. If the vibe is right, every downstream design decision inherits the right constraints and reaches Contract Ready faster. If the vibe is wrong, those workshops re-litigate the same UX questions repeatedly. The downstream loop made cheaper is **specification + design** — by the end of this workshop a fresh agent or human should be able to evaluate proposed designs against an explicit set of "yes / no" criteria rather than reasoning from first principles every time.

**Target Proof Level**: Preferred Direction
**Current Proof Level**: Preferred Direction (reached by this document)

**Selected Value Axes**:
- **Operator Usability** *(primary)*: If the loop doesn't feel good in real sessions, no other axis matters — users will turn it off (literally or by ignoring it).
- **Cost / Attention Reduction**: The skill must cost less attention than the friction it captures, otherwise it is net-negative.
- **Onboarding / Accessibility**: A fresh agent or fresh human must understand the entire loop in under 60 seconds from the AGENTS.md section alone.
- **Learning Compounding**: Each entry must credibly make the next session faster, not just create a paper trail.
- **Strategic Value**: The vibe must stay loyal to `harness-is-the-product-v2`'s "every difficulty catalogued is a gift to future sessions" rather than drifting into bureaucratic process.

**Related Documents**:
- [research-dossier.md](../research-dossier.md) — gap diagnosis, schema sketch, prior learnings
- [`harness-is-the-product-v2`](../../../../skills/SDD/harness-is-the-product-v2/SKILL.md) — philosophical parent
- [`plan-6a-v2-update-progress`](../../../../skills/SDD/plan-6a-v2-update-progress/SKILL.md) — existing producer this skill complements
- [Minih AGENTS_README § The Difficulty Ledger](https://github.com/AI-Substrate/minih/blob/main/AGENTS_README.md) — canonical operating contract this skill mirrors

**Domain Context**: Not applicable — this repo does not use the formal `docs/domains/` system. Final placement of the new skill (`skills/SDD/` vs `skills/general/`) deferred to spec.

---

## Purpose

Lock the *feel* of the self-improvement loop — silent during work, soft voice at the end, suggestions not mandates — before the schema, CLI-flow, and AGENTS.md-voice workshops design specifics on top. The user's explicit directive: "workshop the vibe of what I'm asking for here. So the whole self improving concept, how we make it easy to do, bubble things up to the user to make decisions, always looking out for ways to improve our environment in the future."

## Fresh Entrant Outcome

A fresh human or agent should be able to use this workshop to reach **Preferred Direction** with no additional context.

They should be able to:

- Explain in one paragraph why this skill exists and what it feels like to use it.
- Recognise an anti-vibe in a proposed design and reject it with a specific argument ("this triggers anti-vibe N" / "this violates D-N").
- Pick the right answer to each of the eight decision points (or articulate why a different option fits their context better).
- Describe what success looks like at one week and one month post-install, and identify the four signals that would indicate the vibe was wrong.
- Tell whether a proposed downstream design (schema field, CLI prompt, AGENTS.md text) is loyal to the vibe.

## Key Questions Addressed

- What does success feel like in a single session — and across a week, and across a month?
- What are the failure modes — what does it feel like if the vibe is wrong?
- How do we keep the loop from becoming the friction it's supposed to capture?
- Who is this skill primarily for — the agent or the user?
- What is the absolute minimum viable vibe?
- How does the bubble-up actually drive escalation rather than becoming a journal nobody acts on?
- What design decisions need to be locked now to unblock the schema and CLI-flow workshops?

---

## Value Frame

| Field | Selection | Why It Matters |
|-------|-----------|----------------|
| Target Proof Level | Preferred Direction | Schema and CLI-flow workshops need a clear preferred vibe to anchor against. Contract-ready specifics are not yet needed and would over-constrain those downstream workshops. |
| Primary Value Axis | Operator Usability | Users disable skills that don't feel good. Every other quality measure is downstream of "does it feel good in a real session?" |
| Supporting Value Axes | Cost/Attention Reduction · Onboarding/Accessibility · Learning Compounding · Strategic Value | The skill must cost less attention than the friction it captures (Cost); a fresh entrant must grok it in 60s (Onboarding); each entry must credibly compound (Compounding); the framing must stay loyal to harness-is-the-product (Strategic). |
| Downstream Loop Improved | Specification + design (next workshops, then `/plan-1b-v2-specify`, then `/plan-3-v2-architect`) | Every subsequent design decision can be checked against the locked vibe. Schema-shape, CLI-prompt copy, AGENTS.md voice, file layout — all inherit the constraints from this document. |

---

## Evidence Ledger

| Evidence | Location | Supports | Status |
|----------|----------|----------|--------|
| One-paragraph vibe statement with six load-bearing words | § "The Vibe" | Single artefact future contributors check designs against | Ready |
| Three imagined-session walkthroughs (active difficulty / magic-wand / no-op) | § "The Three Imagined Sessions" | Validates that the vibe survives three concrete cases the skill must handle | Ready |
| Seven explicit anti-vibes with rejection reasoning | § "Anti-Vibes" | Gives downstream workshops + reviewers explicit "no" criteria | Ready |
| § "How the Agent Watches Itself" — defines the agent-source signal, the magic-wand check, trigger heuristics, and concrete examples of agent-observed friction the user would never surface | § "How the Agent Watches Itself" | Anchors the load-bearing reframe (agent is its own user study); informs schema (`source: agent-self` field), CLI flow (no surfacing of self-prompts to user), and AGENTS.md voice (mention agent self-introspection explicitly) | Ready |
| Decision Space table — 29 options across 8 questions plus 2 open Q-rows, each marked Selected/Rejected/Open with rationale | § "Decision Space" | Anchors the eight UX decisions downstream workshops depend on | Ready |
| Decision Summary cheatsheet | § "Decision Summary" | Quick-reference for spec-time and review-time | Ready |
| Compounding Test — 4 measurable signals at one week post-install | § "The Compounding Test" | Validation method for "the vibe was right" | Ready |
| Open questions with RESOLVED/OPEN status | § "Open Questions" | Tracks what still needs resolving and what is locked | Ready |
| Schema sketch (YAML field shape) | (deferred to schema workshop) | Schema design | Missing — out of scope for this workshop |
| Concrete bubble-up render with formatting (ANSI/markdown/plain) | (deferred to CLI-flow workshop) | CLI flow design | Missing — out of scope |
| Draft AGENTS.md text | (deferred to AGENTS.md voice workshop) | AGENTS.md insertion | Missing — out of scope |

---

## The Vibe

> The skill is a **silent observer with a soft voice at the end**. The "observer" is twofold — the agent watches the user for soft mutterings ("ugh, the test runner doesn't print line numbers") **and watches itself for the same kind of friction**: when a tool call took 90 seconds, when it had to grep three files to find a config, when it retried a command twice, when it backtracked. At natural pauses the agent asks itself, internally, "if I had a magic wand right now, what would I change?" — and writes the answer to the buffer. Both sources land in the same place. None of it is visible to the user mid-flow. When the session winds down, the skill taps the user on the shoulder once with a short, scannable summary: "Three things came up. Want to save them as journal entries, draft a fix-task, draft a full plan, or convert any into encoded knowledge?" Five-second answer. Never asks twice. Never blocks. Never moralises. Treats every entry as a possible **gift to your future self** and asks, lightly, whether you want to wrap it.

The load-bearing words: **silent (to user) · soft voice at the end · agent watches itself · magic-wand check at natural pauses · scannable · five seconds · never asks twice · never blocks · never moralises · possible gift · asks lightly**.

If a future design decision pulls against any of those, it's the wrong direction.

---

## How the Agent Watches Itself

The agent is its own user study. This is the load-bearing reframe: minih's `AGENTS_README` is explicit that "every agent that uses your tools is a user study you didn't have to schedule" because **agents don't adapt the way humans do**. A human encountering an awkward tool learns the workaround and stops noticing the awkwardness. An agent encountering the same awkwardness reports it every time, fresh. The friction is most honestly captured at the agent's vantage point — not the user's.

This means the skill's `log` mode has **two sources**, not one:

1. **User-source signal** — the user said something out loud or typed it ("this is annoying", "ugh", "I wish X existed"). Agent recognises the pattern and logs an entry attributed to the user.
2. **Agent-source signal** — the agent itself notices its own friction, awkwardness, or workaround. The agent logs an entry attributed to itself.

### The magic-wand check (agent self-prompt)

At natural pauses, the agent silently asks itself a single question:

> *"If I had a magic wand right now, what would I change about this environment?"*

If the answer is non-trivial, the agent logs it as a `type: magic-wand` entry with `source: agent-self`. If the answer is trivial or empty, the agent does nothing.

**When does "natural pause" trigger?** Concrete heuristics, not vibes:

- After a tool call that took longer than ~30s (the agent has nothing to do but wait — perfect moment to introspect).
- After a search/grep that returned zero matches (was the search awkward? Should the answer have been findable?).
- After retrying a command for the 2nd or 3rd time (encoded knowledge missing).
- After backtracking from a wrong assumption (was a hint missing from AGENTS.md?).
- After a test or build failure that required guesswork to diagnose (better error message wanted?).
- At task boundaries — when an agent finishes a discrete task and the buffer is empty for that task, a single self-prompt ("did anything notable happen here?") is fair game.

**When NOT to introspect**: continuously (anti-vibe 7 below); after every tool call (low signal-to-noise); when the agent is mid-stream on a fast-flowing task (interruption to its own reasoning).

### Examples of agent-source friction

These are the kinds of self-observations the agent should be catching that no user would ever surface:

- *"I just spent four turns figuring out which `agents.md` is canonical when the project has both an `AGENTS.md` and a `CLAUDE.md`. There should be a single statement of which is the source of truth."* → DL-N, type: difficulty, source: agent-self, target: docs.
- *"I had to read three files to learn that this project's tests live under `tests/`, not `test/` or `__tests__/`. A `just test` recipe would have answered this without my having to grep."* → DL-N, type: magic-wand, source: agent-self, target: engineering-harness.
- *"The error message from the test runner just said `assertion failed` with no file or line. I had to re-run with `--verbose` to find anything useful."* → DL-N, type: difficulty, source: agent-self, target: engineering-harness.
- *"I wrote a one-liner shell script three times in this session for the same task (counting matched lines in changed files). This should be a `just count-matches` recipe."* → DL-N, type: gift, source: agent-self, target: engineering-harness — and **the encoded form is obvious enough that the agent can sketch the recipe inline**.

The last example is the highest-value pattern: when the agent notices itself doing the same workaround multiple times, the encoded form is often obvious enough that the suggested-encoding field is non-trivial out of the box. Those are the entries most likely to drive `[e]ncode` actions at bubble-up time.

### Why this matters for the vibe

Without agent self-introspection, the skill is just a transcription tool — it captures what the user noticed. With it, the skill captures **what the user didn't notice but should have**. That's the difference between a journal and a self-improvement loop. The agent is the canary: silent in the moment, but the entries it leaves are the most actionable signal the harness ever gets.

This also tightens the silence contract: "silent during work" means **silent to the user**. The agent's internal monologue and self-prompts are fine — they're part of the agent's own reasoning, not interruptions of the user's. As long as nothing surfaces to the user until bubble-up, the silence holds.

---

## The Three Imagined Sessions

These walkthroughs make the vibe arguable. If any feels wrong to a fresh reader, the vibe is wrong.

### Session A — Code-review session, two difficulties surface

**Setup**: User asks Claude Code to review a PR. Reviewing takes 20 minutes. During the review, the agent hits two annoyances.

**During the session** (silent — no user-visible output from the skill; agent self-introspecting throughout):

```
[Minute 4]  Agent reads the PR description, opens 6 files. The test output
            doesn't show line numbers in stack traces — agent had to re-run
            with --verbose to find the failing assertion.
            → Agent-source signal (workaround used twice).
            → Logs DL-001 to buffer (type: difficulty, source: agent-self,
              target: engineering-harness).

[Minute 11] Agent kicks off the test suite locally. 90s wait.
            → Magic-wand check fires (tool call > 30s pause heuristic).
            → Agent self-prompt: "If I had a magic wand right now, what
              would I change?"
            → Answer: "A `just test:changed` recipe that runs only the
              tests touching files in the diff."
            → Logs DL-002 to buffer (type: magic-wand, source: agent-self,
              target: engineering-harness, suggested-encoding: justfile recipe).

[Minute 18] Agent finishes the review, posts findings.
```

**At session end** (single soft prompt):

```
─────────────────────────────────────────────────────────
🎁 Session retro — 2 entries logged

  DL-001 [difficulty]  Test runner doesn't show line numbers in stack traces
                       Suggested fix: justfile recipe `test:verbose`
                       (or: pytest --tb=long as default flag)

  DL-002 [magic-wand]  No way to run just the tests in the diff
                       Suggested fix: justfile recipe `test:changed`
                       (sketched)

  [s] save both to docs/retros/sessions/2026-05-16-pr-review.md
  [t] save + draft a fix-task for one (which?)
  [p] save + draft a full plan
  [e] save + show the encoded justfile patch
  [d] dismiss all
  [a] all-save (default if you press enter)

  Choice: _
─────────────────────────────────────────────────────────
```

**Vibe check**: ✅ Quick, concrete, real options, respects that the user might just want to dismiss everything because it's late.

### Session B — Planning session, one magic-wand mid-research

**Setup**: User runs `/plan-1a-v2-explore` to research how the auth subsystem works. Exploration takes 8 minutes. Agent reads 23 files.

**During the session**:

```
[Minute 3] Agent grepping for auth patterns. After the third grep with no
           hits in expected locations, backtracking heuristic fires.
           → Magic-wand check: "If I had a magic wand right now?"
           → Answer: "An auth domain.md would have saved me three greps.
             I keep re-discovering this boundary across plans."
           → Logs DL-001 (type: magic-wand, source: agent-self,
             target: docs, suggested-encoding: extract domain).

[Minute 8] At task boundary (research dossier just written), agent runs
           one final magic-wand check. Buffer already has DL-001. Nothing
           new to add. No second entry logged.
           Agent reports back.
```

**At session end**:

```
─────────────────────────────────────────────────────────
🎁 Session retro — 1 entry logged

  DL-001 [magic-wand]  Auth boundary keeps getting re-discovered across plans
                       Suggested fix: extract domain — `/plan-v2-extract-domain auth`
                       Target: docs

  [s] save  [t] task  [p] plan  [e] encode  [d] dismiss  [a] all-save (enter)

  Choice: _
─────────────────────────────────────────────────────────
```

**Vibe check**: ✅ This is the case the skill exists for. Without it, this insight evaporates. With it, the user types `p`, gets a draft `/plan-v2-extract-domain auth` invocation seeded from the entry, and either runs it now or backlogs it.

### Session C — Quick fix session, nothing to log

**Setup**: User asks Claude Code to fix a typo in a docstring. Takes 30 seconds.

**During the session**: nothing happens. No friction, no magic-wands, no surprises.

**At session end**:

```
(no prompt — buffer is empty, skill stays silent)
```

**Vibe check**: ✅ Critical. The skill MUST be silent when it has nothing to say. Any prompt at session end when there's nothing to bubble up is nag-ware.

---

## Anti-Vibes

If a future design decision drifts toward any of these, push back.

### Anti-vibe 1 — Nag-ware

```
[Every minute or two during work]
🔔 Just checking — anything to log?
🔔 You said "ugh" three times. Want to log a difficulty?
🔔 You're 15 minutes in. Have you found anything frustrating yet?
```

**Why this fails**: Interruption disguised as helpfulness. The whole point of "bubble at end, never block mid-flow" is to keep the skill out of the way. The user explicitly pre-empted this failure mode.

### Anti-vibe 2 — Bureaucratic ceremony

```
📋 Before you go, please complete the session retrospective:
   1. Rate your experience this session: [1-5]
   2. Did you encounter any blockers? [Y/N]
   3. Would you recommend this workflow to a colleague? [Y/N]
   4. Free-form feedback (min 50 chars): _____
```

**Why this fails**: Performance theatre. Treats the user as a study subject. The skill should feel like a colleague handing you a sticky note, not an HR exit interview.

### Anti-vibe 3 — Silent journal nobody reads

```
[Skill writes 47 entries over the course of a month]
[No skill ever reads docs/retros/]
[No entries ever get encoded into the engineering harness]
[The compounding promise of harness-is-the-product is broken]
```

**Why this fails**: This is the *current* state for plan-6a's writes — we cannot replicate it. The bubble-up MUST drive at least some entries to `[t]/[p]/[e]` rather than only `[s]/[a]`. If after one week the only action ever chosen is `[a]ll-save`, the bubble-up is broken.

### Anti-vibe 4 — Lecture mode

```
[At session end]
📖 SELF-IMPROVEMENT LOOP — A REMINDER

   Per the principle of "encode, don't document," every difficulty you
   encounter is an opportunity to make your engineering harness better.
   The compounding velocity hypothesis...
[300 more words of philosophy before any actual entries]
```

**Why this fails**: Philosophy belongs in `harness-is-the-product-v2`. The bubble-up is not the place to re-litigate it. Be terse. Trust the user.

### Anti-vibe 5 — Auto-magic the user didn't ask for

```
[At session end, no prompt]
✅ I've automatically:
   - Created docs/plans/024-test-runner-improvements/
   - Drafted spec, plan, and Phase 1 task table
   - Updated AGENTS.md with a new "Test Runner" section
   - Committed everything to a new branch
```

**Why this fails**: User's explicit constraint: "However, it's just suggestions. We make suggestions in the difficulty ledger and then bubble them up to the user at the end... And then the user can choose if they want to do a fixed task or a plan or something to implement said efficiency gain." Every escalation requires user assent.

### Anti-vibe 6 — Schema-driven UX

```
[At session end]
✅ Session retro complete.

  Wrote to docs/retros/_session-buffer.md:
    {"id": "DL-001", "ts": "2026-05-16T14:32Z", "type": "difficulty",
     "source": {"skill": "code-review", "task": null, "plan": null},
     "category": "test", "severity": "medium", "target": null,
     "description": "Test runner doesn't show line numbers...",
     "workaround": "Re-ran with --verbose", ...}
```

**Why this fails**: The schema is for machines and downstream readers. The bubble-up is for humans. Showing JSON at decision time taxes attention without informing choice. Pretty-print, summarise, hide structure.

### Anti-vibe 7 — Agent over-introspects

```
[Every 30 seconds during a 20-minute task]
[Internal] Magic-wand check: "If I had a magic wand right now?"
[Internal] Magic-wand check: "If I had a magic wand right now?"
[Internal] Magic-wand check: "If I had a magic wand right now?"
[Internal] Magic-wand check: "If I had a magic wand right now?"
... 40 times ...

[At session end]
🎁 Session retro — 47 entries logged
   DL-001 [magic-wand]  I wish for slightly faster grep
   DL-002 [magic-wand]  I wish for slightly faster grep (again)
   DL-003 [magic-wand]  This file is a bit long
   ... [44 more low-quality entries] ...
```

**Why this fails**: Self-introspection is silent to the user, but it's not free for the *agent* — every check costs reasoning tokens and clutters the buffer with low-quality entries that drown the high-quality ones. If the bubble-up summary is 47 entries long, the user dismisses everything and the loop fails. The trigger heuristics in § "How the Agent Watches Itself" are deliberately *moments of friction*, not *time intervals*. If the agent's introspection rate exceeds roughly **one check per 5 minutes of work** in a typical session, the heuristics are misfiring and need to be tightened.

---

## Decision Space

Each row is one option. Multiple options per decision question (D1 has 4, D2 has 4, …, D8 has 5). The "Decision" column is **Selected** / **Rejected** / **Open** for each option individually. Q-rows below the D-rows are open meta-questions presented in the same format.

| Option | Description | Pros | Cons | Decision |
|--------|-------------|------|------|----------|
| **D1a** — Auto-fired | Host CLI fires `bubble` on session end via hook | Zero cognitive load on agent or user | Cross-CLI hook support is shaky; not portable | Rejected |
| **D1b** — User-invoked only | User types `/gifts-v2 bubble` when ready | Explicit, predictable, no CLI dependencies | Will be forgotten in ~80% of sessions; defeats compounding | Rejected |
| **D1c** — Agent-self-invoked | Skill instructs the agent to call `bubble` before handing back control | Reliable across CLIs; matches "soft voice at end" | Requires agent compliance; a forgetful agent skips it | Selected (combined with D1d as escape hatch) |
| **D1d** — Hybrid (D1c default + manual escape) | Agent-self-invoked by default; `/gifts-v2 bubble` available manually | Best of both; portable across CLIs; manual recovery path | Slightly more surface to teach | **Selected** |
| **D2a** — Default `[s]ave` (per entry) | Enter saves the current entry being prompted on | Preserves info | Requires per-entry prompting → violates "single soft prompt" | Rejected |
| **D2b** — Default `[a]ll-save` (batch) | Enter saves all entries in one keystroke | One keystroke; preserves everything; matches "five seconds" | User might save things they meant to discuss inline | **Selected** |
| **D2c** — Default `[d]ismiss all` | Enter drops everything | Zero ledger noise | Destroys gifts; defeats the entire purpose | Rejected |
| **D2d** — Mixed defaults per type | Save difficulties; dismiss magic-wands | Tunable | Two defaults to remember; no clear win | Rejected |
| **D3a** — Print encoding to terminal | User copy-pastes manually | Zero file artifacts | Loses the diff after the terminal scrolls | Rejected |
| **D3b** — Apply encoding immediately | Skill writes to justfile/AGENTS.md directly | Fastest path to encoded fix | Violates suggest-don't-mandate (anti-vibe 5) | Rejected |
| **D3c** — Stage diff in `scratch/` | Write `scratch/encode-DL-001-justfile.diff`; tell user `git apply` | Concrete artifact; respects suggest-don't-mandate; reviewable | One extra command for user | **Selected** |
| **D3d** — Open file at line + clipboard | IDE-style positioning + copy-to-clipboard | Slick UX | Cross-CLI inconsistency; clipboard side-effects; not all CLIs support | Rejected |
| **D4a** — Always sessions/ | All entries land in `docs/retros/sessions/<date>-<branch>.md` | Simple; one rule | Plan-active sessions split from plan-6a writes — readers see two streams | Rejected |
| **D4b** — Plan-aware destination | Active plan → `docs/retros/<plan-slug>.md`; else `docs/retros/sessions/<date>-<branch>.md` | Convergence with plan-6a writes; readers see one ledger per plan | Detection logic must be reliable | **Selected** |
| **D4c** — Ask the user every time | Prompt for destination at bubble | Maximum control | Friction; defeats single-soft-prompt rule | Rejected |
| **D5a** — Ultra-terse | ID, type, one-line description, menu only | Fastest to read | No basis for `[t]/[p]/[e]` choice → forces `[a]ll-save` → anti-vibe 3 | Rejected |
| **D5b** — Terse + one-line encoding hint | Adds one-line encoding sketch per entry | Choice has substance; still scannable | Slightly more vertical space | **Selected** |
| **D5c** — Full structured entry | All schema fields visible at decision time | Maximum information | Triggers anti-vibe 6 (schema-driven UX) | Rejected |
| **D6a** — Producer + bubble (basic actions only) | `[s]/[d]/[a]` only; no `[t]/[p]/[e]` | Smallest scope | Doesn't prove the escalation pattern that's the whole point | Rejected |
| **D6b** — Producer + bubble + escalations | Adds `[t]/[p]/[e]` | Proves escalation UX | Read-side gap remains; new writes still go unread | Rejected |
| **D6c** — Full bundle (producer + bubble + escalations + reader updates) | Plus updates to `plan-1a` Subagent 7 (and optionally `plan-3`, `plan-7`, `agent-harness-v2`) to read `docs/retros/` | Closes the compounding loop end-to-end | Larger scope; more files touched | **Selected** |
| **D7a** — As a tool | "Run this skill to log a difficulty" | Operational; minimal | Doesn't convey the loop's purpose | Rejected |
| **D7b** — As a contract | "This repo treats every session as a chance to improve infra. Here's how the loop works." | Operational; sets norms; correct register for AGENTS.md | Slightly more text | **Selected** |
| **D7c** — As a story | Long philosophical narrative | Compelling read | Wrong place — philosophy lives in `harness-is-the-product-v2`; AGENTS.md should be operational | Rejected |
| **D8a** — Continuous self-introspection (after every tool call) | Agent runs the magic-wand check after every tool call | Maximum coverage of friction moments | Triggers anti-vibe 7 (over-introspects); buffer drowns | Rejected |
| **D8b** — At task boundaries only | Single self-prompt when a discrete task completes | Predictable cadence; low overhead | Misses mid-task friction (the 90s test wait) | Rejected |
| **D8c** — At natural pauses (heuristic triggers) | Trigger on: tool call > 30s, zero-result search, 2nd retry of same command, backtrack from wrong assumption, test/build failure requiring guesswork; plus one optional check at task boundary | Catches friction at the moment of friction; honest signal; matches "moments of friction not time intervals" | Heuristics need calibration over time | **Selected** |
| **D8d** — Only on failure | Self-introspect only when something fails | Minimal overhead | Misses "this works but it's awkward" — exactly the magic-wand class | Rejected |
| **D8e** — User-source only (no self-introspection) | Agent only logs what the user explicitly mutters | Minimal cognitive cost | Loses the "agent is its own user study" leverage entirely; reduces skill to a transcription tool | Rejected |
| **Q1** — Should `bubble` also offer "anything else you noticed but I didn't log?" prompt? | At bubble-up time, after presenting buffer, prompt for user-added entries the agent missed | Catches meta-magic-wands; user contributions | Drifts toward bureaucratic ceremony (anti-vibe 2) | Open — recommendation: NO in v1; revisit after 1 month |
| **Q3** — Project-level "do not log" sentinel | `docs/retros/.disabled` file makes `log` a no-op | Some projects want privacy; respects user autonomy | One more concept to teach | Open — recommendation: support, but minimal docs |

### Decision Summary (cheatsheet)

| ID | Question | Selected |
|----|----------|----------|
| D1 | Who triggers `bubble`? | **Hybrid: agent-self-invoked default + manual escape hatch** |
| D2 | Default action when user presses enter? | **`[a]ll-save`** |
| D3 | What does `[e]ncode` do? | **Stage candidate diff in `scratch/`; user runs `git apply`** |
| D4 | Where does `[s]ave` write to? | **Plan-aware: active plan's ledger if a plan is detected, else `docs/retros/sessions/<date>-<branch>.md`** |
| D5 | How verbose is the bubble-up summary? | **Terse + one-line encoding hint per entry** |
| D6 | What's in v1 scope? | **Full bundle — producer + bubble + `[t]/[p]/[e]` escalations + reader updates to existing skills** |
| D7 | How does AGENTS.md describe this? | **As an operational contract, not a story or a tool reference** |
| D8 | When does the agent self-introspect? | **At natural pauses (heuristic triggers): tool call > 30s, zero-result search, 2nd retry, backtrack, failure requiring guesswork, optional task-boundary check** |
| Q1 | Add "anything else?" prompt at bubble? | Open — likely NO for v1 |
| Q3 | Support `.disabled` sentinel? | Open — likely YES, minimal docs |

---

## Attention Reduction

| Future Loop | Before Workshop | After Workshop |
|-------------|-----------------|----------------|
| Schema design (next workshop) | "What fields go in an entry?" was an open question. Schema would be designed in isolation and then re-evaluated against UX. | Schema must support the bubble-up format from Session A; minih round-trip required; **no fields shown to user at decision time** (anti-vibe 6); agent compliance with `log` mode must be cheap. |
| CLI-flow design (next workshop) | "How does the bubble actually render?" was a blank page. Multiple competing UX directions plausible. | Single-prompt menu; terse + encoding hint per entry (D5); default `[a]ll-save` (D2); `[e]ncode` writes to `scratch/` (D3); silent when buffer empty (Session C). |
| AGENTS.md authoring (next workshop) | "What voice do we use?" Tutorial vs contract vs story all defensible. | Operational contract voice with one-sentence story preamble (D7); no philosophy lectures (anti-vibe 4); ~10–15 lines max in AGENTS.md proper. |
| Spec scoping (`/plan-1b-v2-specify`) | "What's in v1?" Range from minimal producer to full ecosystem. | Full bundle including reader-side updates (D6); auto-magic explicitly out-of-scope (anti-vibe 5); `gifts-v2 import-minih` deferred to follow-up plan. |
| Review of any proposed design | Vibes-based judgment — "does this feel right?" Hard to argue precisely. | Check against the six anti-vibes and the seven decisions; rejection or acceptance can be argued by reference ("triggers anti-vibe 4" / "violates D5"). |
| First-week post-install validation | "How do we know if the skill works?" Open. | Compounding Test — 4 measurable signals (escalation usage, encoding closure, reader trigger, opt-out rate). |

---

## The Compounding Test

At one week post-install, ask:

1. **Did anyone choose `[t]`, `[p]`, or `[e]`?** If yes — the loop is producing escalations. If no — the bubble-up isn't compelling enough; iterate on D5 (verbosity / encoding hints).
2. **Did any entry get marked `status: encoded` in a permanent ledger file?** If yes — the loop is closing. If no — `[e]ncode` flow is broken (D3 needs revisiting).
3. **Did any subsequent session start by reading the ledger?** If yes — readers are wired. If no — reader-side updates from D6 didn't ship or didn't work.
4. **Did the user ever turn off the skill?** If yes — anti-vibe leakage. Find which one and fix it.

These four signals are the v1 acceptance criteria for "the vibe was right."

### What success feels like

- **After one session**: a colleague handing you a sticky note. Quick, useful, gone.
- **After one week**: the dev environment got a tiny bit better five times in a row, and you barely noticed it happening.
- **After one month**: the maturity curve, in motion. The harness is, in fact, the product.

### What failure feels like (one-month signs)

- The buffer is full of stale entries; `[a]ll-save` is the only action ever chosen.
- The user has added `gifts-v2` to a personal "skills I always disable" list.
- The justfile is unchanged; AGENTS.md is unchanged; nothing was ever encoded.
- A new agent reads the ledger and finds 47 unresolved difficulties — which is more demoralising than helpful.

If *any* of those signals appear at the one-week mark, the vibe was wrong and the skill needs a pivot.

---

## Open Questions

### Q1: Should the skill also offer to log entries the agent didn't catch automatically?

**OPEN.** I.e., at bubble-up time, after presenting the buffer, should there be an extra prompt: "Anything else you noticed but I didn't log?" This would let the user contribute entries the skill missed. Risk: drifts toward bureaucratic ceremony (anti-vibe 2). Benefit: catches the meta-magic-wands ("I wish this skill noticed X").

**Recommendation, soft**: NO in v1. Add only if the Compounding Test shows the agent is missing too much friction. Re-litigate after one month.

### Q2: How does the skill behave when there's no `docs/retros/` directory yet?

**RESOLVED.** First-run: the `init` mode (or the first `log` invocation, if `init` isn't run separately) detects the missing directory and writes a minimal scaffold (`docs/retros/`, `docs/retros/README.md`, `docs/retros/_session-buffer.md`). Logs the *act of scaffolding* as DL-001 of the session ("type: gift; description: bootstrapped the difficulty ledger"). The bubble-up at session end then offers to commit the scaffold.

### Q3: Does the skill respect a project-level "do not log" preference?

**OPEN.** Some projects might want to track difficulties privately (e.g., `.gitignore` the retros) or not at all.

**Recommendation, soft**: support a `docs/retros/.disabled` sentinel file that, if present, makes `log` a no-op and `bubble` print "logging disabled in this project (remove `.disabled` to re-enable)." Workshop topic if anyone disagrees.

### Q4: Does this skill interact with `harness-is-the-product-v2`?

**RESOLVED.** Yes — `gifts-v2` is the *operational* counterpart to the *philosophical* `harness-is-the-product-v2`. The two should cross-reference each other:
- `harness-is-the-product-v2` Principle 2 ("Track Velocity Compounding") gets a `→ See gifts-v2 for the mechanism` link.
- `gifts-v2` § Purpose gets a `→ See harness-is-the-product-v2 for the philosophy` link.

Neither one duplicates the other.

### Q5: What's the working name?

**OPEN.** Candidates from the dossier: `gifts-v2`, `difficulty-ledger-v2`, `encode-difficulties-v2`, `self-improve-v2`, `retro-buffer-v2`, `magic-wand-v2`. The user's vibe ("gifts to future self") favours `gifts-v2`. Final naming should be polled at spec time. Workshop holds: don't block on naming.

---

## Validation / Acceptance

This workshop reaches its target proof level (**Preferred Direction**) when:

1. The vibe statement (one paragraph) is read by a fresh entrant who can describe the skill's intended feel back to the workshop author without contradicting any of the six load-bearing words.
2. A proposed design decision can be plausibly evaluated against the eight decision points in the Decision Space table and the seven anti-vibes — i.e., a future contributor can argue "this proposal violates D5 / triggers anti-vibe 4" and the workshop's text supports the argument.
3. The three imagined-session walkthroughs feel right to the user (the human who originally requested the skill). If any of the three feels wrong, the vibe is wrong and this workshop needs revision before downstream design.
4. The Decision Summary cheatsheet is short enough (≤ 1 screen) that the user can hold it in working memory while reviewing the schema and CLI-flow workshops.

The acceptance test for **this workshop specifically** (not the skill itself): the user reads the imagined sessions, the anti-vibes, and the Decision Space table, and either (a) approves them as-is, or (b) flags specific Selected/Rejected calls that should flip — without invalidating the vibe statement.

---

## Quick Reference

**Vibe in one paragraph**: silent (to user) observer, agent watches itself for friction, magic-wand check at natural pauses, soft voice at the end, scannable, five seconds, never asks twice, never blocks, never moralises, possible gift, asks lightly.

**Eight Selected decisions**:
- D1: Hybrid trigger (agent-self-invoked default + manual escape)
- D2: Default `[a]ll-save`
- D3: `[e]ncode` stages diff in `scratch/`
- D4: Plan-aware save destination
- D5: Terse + one-line encoding hint
- D6: Full bundle in v1 (producer + bubble + escalations + reader updates)
- D7: AGENTS.md operational-contract voice
- D8: Agent self-introspects at natural pauses via heuristic triggers (long tool call, zero-result search, retry, backtrack, failure-with-guesswork)

**Seven anti-vibes** (reject if any triggered):
1. Nag-ware
2. Bureaucratic ceremony
3. Silent journal nobody reads
4. Lecture mode
5. Auto-magic the user didn't ask for
6. Schema-driven UX
7. Agent over-introspects (self-prompts more than ~once per 5 minutes; buffer drowns)

**Compounding Test** (4 signals at 1 week post-install):
1. Anyone chose `[t]/[p]/[e]`?
2. Any entry marked `status: encoded`?
3. Any session started by reading the ledger?
4. Did the user turn the skill off?

---

## Next Steps

- **User reviews**: vibe statement, three imagined sessions, Decision Space table, anti-vibes.
- **If approved**: run additional workshops as needed before `/plan-1b-v2-specify`:
  - `/plan-2c-v2-workshop 023-difficulty-ledger-skill "Difficulty ledger schema (YAML field shape, minih round-trip)"` — Type: Data Model
  - `/plan-2c-v2-workshop 023-difficulty-ledger-skill "Bubble-up CLI flow (prompt rendering, key-stroke handling)"` — Type: CLI Flow
  - `/plan-2c-v2-workshop 023-difficulty-ledger-skill "AGENTS.md / CLAUDE.md voice and placement"` — Type: Other
- **If revisions needed**: iterate this workshop, then proceed.
- **Skip path**: if the downstream workshops feel obvious from this one, go straight to `/plan-1b-v2-specify` (Full Mode, given D6's "full bundle" scope).

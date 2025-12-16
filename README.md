# JK Tools

Centralized setup and utility scripts for developer tooling across macOS, Linux, and Windows (WSL/Git Bash).

## Quick Start

### Modern Approach (uvx - Recommended)

Run directly from GitHub without cloning:

```bash
uvx --from git+https://github.com/jakkaj/tools jk-tools-setup
```

Or from a local clone:

```bash
./setup.sh
```

If you have `uvx` installed, it will automatically use the modern execution mode.

### Traditional Approach (pip)

```bash
git clone https://github.com/jakkaj/tools.git
cd tools
./setup.sh
```

## What It Does

- Installs and configures developer tools (Rust, Just, code2prompt, Claude Code, Codex, OpenCode, etc.)
- Sets up agent commands and MCP server configurations for AI assistants
- Creates convenient aliases for scripts
- Manages PATH and shell configuration

## Features

- **Automatic tool installation**: Rust, cargo tools, AI CLI clients
- **Agent command sync**: Deploys slash commands to Claude, OpenCode, Codex, and VS Code
- **MCP server configuration**: Automatically configures Model Context Protocol servers
- **Cross-platform**: Works on macOS, Linux, and Windows (WSL/Git Bash)
- **Idempotent**: Safe to run multiple times
- **Update mode**: `jk-tools-setup --update` to update existing tools
- **Local command installation**: Install commands to project directories for version control

## Installing Commands Locally

Install AI CLI commands to your project directory without full setup:

```bash
# Install GitHub Copilot commands from GitHub
uvx --from git+https://github.com/jakkaj/tools jk-tools-setup --commands-local ghcp

# Install Claude commands
uvx --from git+https://github.com/jakkaj/tools jk-tools-setup --commands-local claude

# Install multiple CLI commands at once
uvx --from git+https://github.com/jakkaj/tools jk-tools-setup --commands-local claude,ghcp,opencode

# Install to specific directory
uvx --from git+https://github.com/jakkaj/tools jk-tools-setup --commands-local ghcp --local-dir ~/my-project

# Force reinstall to get latest version
uvx --force-reinstall --from git+https://github.com/jakkaj/tools jk-tools-setup --commands-local ghcp
```

**What gets installed:**
- ✅ Command/prompt files ONLY
- ❌ NO MCP server configuration
- ❌ NO global setup
- ❌ NO other tools installation

**Supported CLIs:**
- `claude` → `.claude/commands/` (auto-discovered by Claude Code)
- `opencode` → `.opencode/command/` (auto-discovered by OpenCode)
- `ghcp` → `.github/prompts/*.prompt.md` (attach manually in IDE)
- `codex` → Not supported (use global installation only)

See [CLAUDE.md](CLAUDE.md) for full documentation.

## Development

```bash
# Install in editable mode
uv venv
source .venv/bin/activate
uv pip install -e .

# Run the CLI
jk-tools-setup --dev-mode .
```


## The flow

## The planning journey, told as a story (decoupled from the commands)

A spec-driven workflow is, at its core, a disciplined way to separate **what/why** from **how**, avoiding "solutioneering" into the wrong outcome. A good flow makes that separation explicit: research and specification first, clarification next, architecture and phased planning after, then implementation with traceability, and finally review gates.

Below is the story told stage-by-stage, referring to the command names only as "an example implementation" of the underlying concept.

---

## Chapter 0: The Constitution (system-level constraints)

Before any work can start, **system-level constraints** must be established. Not because it's bureaucratic, but because an agent will otherwise "helpfully" fill gaps with invention. The most expensive failure mode is when it confidently reintroduces patterns already rejected, violates architecture boundaries, or rebuilds something the system already has.

So the workflow begins with a constitution: a set of **rules of engagement** that is always "in the room" for every feature and every plan. In this implementation, `/plan-0-constitution` creates the canonical doctrine files—guiding principles, enforceable rules, idioms/patterns, and architecture boundaries—under `docs/project-rules/`.

The important conceptual move here is not the file creation; it's the **synchronization**: doctrine must be explicitly enforced "downstream" across planning, tasks, implementation, and review. In this flow, that's stated directly: doctrine must be enforced across Constitution → Rules & Idioms → Plan/Tasks/Implementation.

Being precise about what doctrine actually means in practice is critical. The constitution isn't vague values; it's operational constraints like:

* how quality is proven (tests, manual checks, monitors),
* repeatable tooling and environments,
* coding and review standards,
* architecture guardrails and anti-patterns,
* and change governance (who can change doctrine, what evidence is required). 

A subtle but powerful element baked into this design: the constitution is **re-entrant** and preserves user customizations when updated (using explicit user-content markers). That matters because doctrine is living—teams learn—and a good system doesn't punish learning by overwriting hard-won local context.

**Why this chapter matters in SDD:**
This is where "agent drift" is prevented. These are the invariant constraints that make every later artifact more trustworthy.

---

## Chapter 1a: Explore (the "fidelity upgrade" before specification)

The discipline here is resisting the urge to write the spec immediately.

Instead, step 1a brings the **raw idea and core requirements** and asks the agent to do the work that humans often skip under pressure: understand what already exists, what must be respected, and what the real problem edges look like.

In this implementation, `/plan-1a-explore` is explicitly "research before specification," producing a research dossier (or console output) and using parallelism to cover the landscape. 

Conceptually, this stage exists to create a **research dossier** that turns a vague intention into high-fidelity context:

* how similar parts of the codebase work,
* which dependencies and integration points matter,
* what tests and interfaces already exist,
* what conventions and idioms must not be violated,
* and what documentation already tells (or fails to tell).

This flow also goes further than "read the code": the explore stage can detect where internal research hits a wall and external research is warranted (e.g., best practices, security/compliance expectations, library changes). In the FlowSpace-enabled path, the system checks for tool availability and then launches parallel specialized subagents for comprehensive exploration.  

**Why this chapter matters in SDD:**
Because the spec is only as good as its context. Step 1a is where guessing stops and grounding begins. It's also where the two classic failures are prevented:

1. building something that already exists, and
2. writing a spec that ignores real constraints and therefore “looks right” but is unbuildable without surprise scope.

---

## Chapter 1b: Specify (WHAT and WHY, without HOW)

Only after the research dossier exists should the spec be written.

This is the moment where the workflow becomes explicitly **technology-free**: it forces stating what the user needs and why it matters, before deciding how to implement it. This implementation calls this out directly: create the spec from natural language, focusing on user value (WHAT/WHY) with "no tech choices."

In this system, `/plan-1b-specify` produces the spec document in a feature folder and uses a canonical structure that includes goals, non-goals, acceptance criteria, risks/assumptions, open questions, and placeholders for testing and documentation strategy.

Here's the key story beat: **1a feeds 1b**. The spec step explicitly checks for an existing research dossier and external research results, reads them, and incorporates them into the spec (including informing complexity scoring and calling out what was incorporated).

The flow also enforces a crucial "honesty mechanism": unknowns aren't glossed over—they're marked with `[NEEDS CLARIFICATION: ...]` so ambiguity is visible and can be deliberately resolved later.

Finally, an important move that aligns with the "don't measure with story points/LoC" stance: the spec includes **complexity scoring** based on a rubric (surface area, integration, data/state, novelty, non-functional needs, testing/rollout), mapped into CS-1 through CS-5. 

**Why this chapter matters in SDD:**
The spec is the contract that protects outcomes from implementation bias. If 1b is polluted with "how," the ability to evaluate whether the right thing is being built is lost.

---

## Chapter 2: Clarify (turn ambiguity into a deliberate choice)

A spec that hasn't been clarified is a trap: it looks complete until it hits implementation reality.

So Chapter 2 does something disciplined: ask **a small number of high-impact questions**, one at a time, and immediately update the spec with the answers. This implementation is explicit: ask ≤8 questions, prioritize only those "truly needed," and after each answer write into `## Clarifications` (dated sessions) and update the relevant spec sections immediately.

The first question is non-negotiable: the workflow mode—Simple or Full—must be decided, because the rest of the workflow changes materially based on complexity.

If Simple mode is chosen (best for CS-1/CS-2), the flow tightens: testing defaults to lightweight, the plan becomes single-phase with inline tasks, and plan-4/plan-5 become optional (effectively moving faster into implementation).
If Full mode is chosen (CS-3+), there's a commitment to multi-phase planning and stronger gates.

**Why this chapter matters in SDD:**
This is where "spec as aspiration" becomes "spec as executable intent." The ambiguity surface area shrinks early, when it's cheap.

---

## Interlude: Prep the Issue (optional external signpost)

Sometimes the work needs to be represented in Jira/Azure DevOps/GitHub Issues. But a good workflow is explicit about a key idea: the issue is **not** the spec; it's a signpost.

So there's an optional step to generate structured issue text from the spec/plan artifacts for external tracking (`/plan-2b-prep-issue`), keeping acceptance criteria, goals, non-goals, and complexity visible without collapsing the whole world into an issue tracker description.

**Why this matters:**
It prevents the common "Jira becomes the spec" failure, while still meeting organizational tracking needs.

---

## Chapter 3: Architect (make the blueprint before touching code)

Now the story shifts: once the team knows what's being built and has resolved ambiguity, "how" finally enters the room.

In this system, `/plan-3-architect` explicitly states "never skip—this is the implementation blueprint."

The blueprint isn't just a checklist. It's a structured plan document that includes:

* technical context,
* 15–20+ critical research findings produced by parallel subagents,
* a testing philosophy,
* implementation phases with acceptance criteria per phase,
* cross-cutting concerns,
* complexity tracking,
* progress tracking (task tables),
* and a change footnotes ledger to anchor traceability.

This stage is also where the "constitution" stops being philosophy and becomes governance: the architect step applies gates for clarification completeness, constitution alignment, architecture boundaries, and ADR awareness.

An efficiency pattern baked into this design matters a lot in agentic workflows: if a research dossier already exists, the architect step can reduce redundant exploration and shift to "implementation-specific discovery," rather than re-learning the same facts each time.

**Why this chapter matters in SDD:**
This is where a clarified spec converts into an executable, phased strategy that protects delivery and quality. Without it, "spec-driven" becomes "spec-adjacent."

---

## Chapter 3a: ADR (optional, but critical when decisions are irreversible)

Sometimes a feature requires decisions that outlive the feature itself (e.g., introducing a new datastore, changing a boundary, adopting a pattern that becomes precedent). In those moments, the flow offers an ADR stage: generate an Architectural Decision Record from the spec and clarifications and cross-link it into the plan so future work inherits constraints rather than rediscovering them.

The ADR tooling is notable because it treats ADRs as a *system* (scan existing ADRs; map doctrine constraints; extract decision context) and enforces quality signals (alternatives, positive/negative codes, etc.).

**Why this chapter matters in SDD:**
It prevents "local optimum" decisions from being repeated as accidental architecture across time.

---

## Chapter 4: Validate readiness (optional, but the "quality gate before spend")

Now there's a plan. The temptation is to start coding. Instead, an optional readiness validation pass runs.

The `/plan-4-complete-the-plan` stage runs parallel validators across structure, testing, completeness, doctrine alignment, and ADR awareness, and produces a READY vs NOT READY outcome (with an explicit override option).

Conceptually, this is a **pre-spend gate**: plan deficiencies are caught before the most expensive activity (implementation) begins.

**Why this chapter matters in SDD:**
Because the cost curve is real: mistakes found in plan are cheaper than mistakes found in code review, and dramatically cheaper than mistakes found in production.

---

## Chapter 5: Phase tasks and the alignment brief (turn the blueprint into executable slices)

At this point, the focus stops being "the whole feature" and starts being **one phase at a time**.

The `/plan-5-phase-tasks-and-brief` command generates a phase dossier including:

* a 9-column task table (with explicit Validation criteria per task),
* an alignment brief (objectives, non-goals, critical findings, ADR constraints, test plan),
* phase footnote stubs and evidence artifacts,
* and a GO/NO-GO ready check.

Importantly, if it's not Phase 1, the system does a prior phase review via subagents to carry forward lessons, dependencies, and discoveries.

**Why this chapter matters in SDD:**
This is how large work becomes measurable without story points: each phase becomes a coherent unit with explicit validations, evidence, and constraints.

---

## Chapter 5a: Subtasks (optional mid-phase detours without losing the thread)

Real work never follows the plan perfectly. When unexpected complexity appears mid-phase, the flow offers a controlled detour: generate a subtask dossier that stays within the phase scope, uses its own task IDs, and updates the parent task and plan registries so traceability remains intact.

**Why this chapter matters in SDD:**
It's the antidote to "scope creep by stealth." Surprises can be absorbed without corrupting the plan's integrity.

---

## Side scene: "Did you know?" (recommended shared understanding engine)

Between tasks and implementation, this flow recommends a deliberate pause to build shared understanding.

`/didyouknow` analyzes the current artifacts from multiple perspectives, presents one insight at a time, and immediately updates the docs as it's discussed—creating a durable record in the artifacts themselves rather than leaving insight trapped in chat history.

**Why this matters:**
This is where teams and agents catch conceptual misalignment before it becomes code churn.

---

## Chapter 6: Implement (earning the right to write code)

Only now does implementation begin.

The `/plan-6-implement-phase` stage is explicit: this is where coding happens, and it follows the chosen testing approach (Full TDD, TAD, Lightweight, Manual, or Hybrid). It creates an execution log and captures evidence, commands run, and outputs.

Crucially, it automatically calls the progress updater after *each* task.

**Why this chapter matters in SDD:**
This is where SDD can go wrong if it isn't instrumented: without evidence, "implementation" becomes un-auditable agent output. This flow explicitly prevents that.

---

## Chapter 6a: Update progress atomically (traceability as a first-class deliverable)

This is one of the most distinctive parts of this design: progress tracking is not "tick a checkbox." It's an atomic synchronization across the plan, the phase dossier, and the footnote ledgers.

The `/plan-6a-update-progress` stage updates all three locations, validates link integrity and status consistency, and declares the execution incomplete if any location isn't updated.

The system also defines a stable identity scheme ("FlowSpace Node IDs") for linking tasks/logs to concrete code entities (file/class/method/function).

The conceptual payoff is visible in the scenarios this enables: questions like "which tasks modified this file?" or "why was this function added?" can be answered by traversing the bidirectional graph between tasks, logs, footnotes, and files.

**Why this chapter matters in SDD:**
This is how shallow "activity metrics" (LoC, commits) shift to evidence-based traceability, without needing humans to maintain it manually.

---

## Chapter 7: Review (quality and doctrine gates before shipping)

Finally, review.

The `/plan-7-code-review` stage is explicitly comprehensive: it checks bidirectional link integrity (task↔log, task↔footnote, plan↔dossier, parent↔subtask), validates doctrine gates (testing approach, mock usage), and runs quality/safety reviews (correctness, security, performance, observability).

It produces a review report and, when needed, a fix-task artifact, and returns a clear verdict: APPROVE vs REQUEST_CHANGES.

If approved, the work proceeds to merge and either starts the next phase or finishes the feature; if changes are requested, it loops back into implementation and re-runs the gates.

**Why this chapter matters in SDD:**
It prevents "spec-driven" from devolving into "agent-driven." Review gates make quality and doctrine compliance an explicit outcome, not an assumption.

---

## How the stages work together to produce outcomes (the through-line)

This flow is effectively a conveyor belt of increasingly concrete artifacts, with governance and traceability layered in:

* The **constitution** defines invariants the system must not violate.
* **Research (1a)** raises fidelity and prevents reinvention.
* **Spec (1b)** defines outcomes (WHAT/WHY) and makes unknowns explicit.
* **Clarify (2)** converts ambiguity into deliberate choices (including workflow mode).
* **Architect (3)** turns intent into a phased blueprint with explicit gates.
* **Validate (4)** ensures implementation effort isn't spent on a broken plan.
* **Phase tasks (5)** create executable slices with validations and briefs.
* **Implement (6)** generates code plus evidence, not just code.
* **Atomic tracking (6a)** keeps the whole system auditable and navigable.
* **Review (7)** enforces doctrine, quality, and traceability before ship.

That's the core story. It's not "a bunch of prompts," it's a mechanism for producing: clarity → plan → evidence → quality gates, with explicit control over ambiguity and drift.

A natural next step would be adding the missing layer: **how to measure success of the spec** (and each stage) using ideas drawn from SPACE, ESSP, and Accelerate—without falling into the "story points / LoC" trap.


## License

MIT

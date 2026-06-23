---
name: validate-v2
description: Launch parallel subagents to validate whatever was just produced with structured lens coverage, thesis alignment, and VPO forward-compatibility — tasks dossier, code changes, plan, spec, workshop, or any artifact. Universal post-action validation.
---
Please deep think / ultrathink as this is a complex task.

# validate-v2

**Universal post-action validation** — launches parallel subagents using the current session model to cross-check whatever artifact was just produced. Works on any output: tasks dossier, code changes, plan, spec, workshop, or any structured document.

This version is **thesis-aware**: validation must understand the artifact's raison d'être, the value claim it is supposed to advance, the proof level it is expected to reach, and the evidence required to make that claim credible.

## Philosophy

> "Every artifact deserves a second pair of eyes before the human sees it."

This skill is the automated equivalent of asking 3 senior engineers to review your work in parallel. Each agent has a different lens. They use whatever model is currently powering the session so validation quality tracks the active environment. Results are synthesized and actionable fixes applied immediately.

Validation is not only a correctness check. It is a thesis check.

The validator must understand the reason the artifact exists, the value it is supposed to create, the proof level it is expected to reach, and the evidence required to make that claim credible.

An artifact can be syntactically correct, internally consistent, and still fail validation if it does not advance the thesis it was created to serve.

---

```md
User input:

$ARGUMENTS
# No flags required — auto-detects what to validate from context.
# Optional: --artifact <path> to specify a file to validate
# Optional: --scope <narrow|broad> to control agent count (default: broad = 3–4 agents)
#   narrow: fewer agents using the current session model (faster for specs/plans)
#   broad: full agents using the current session model (thorough for code/tasks)
```

## How It Works

### Step 1: Detect What Was Just Done

Examine the conversation context to determine what artifact was just produced. Categories:

| Category | Detection Signal | Agent Focus |
|----------|-----------------|-------------|
| **Tasks Dossier** | Tasks dossier just produced (phase-tasks stage), tasks.md file created/modified | Line numbers, code snippets, cross-references, dependency chain |
| **Code Changes** | Phase implementation just ran (implement stage), source files edited | Correctness, edge cases, missing error handling, contract compliance |
| **Plan** | Implementation plan just produced (architect stage), plan.md created | Phase coherence, risk coverage, domain alignment, missing tasks |
| **Spec** | Feature spec just produced (specify stage), spec.md created | Ambiguities, missing acceptance criteria, scope gaps |
| **Workshop** | Workshop document just produced (workshop stage), workshop file created | Factual accuracy, code examples vs actual source, decision coverage, proof-level fit |
| **General** | Anything else | Correctness, completeness, consistency |

### Step 1.25: Establish the Validation Thesis (mandatory)

Before designing agents, establish the thesis of the artifact being validated.

The validation thesis is the artifact's reason for existing: what it is trying to make true, what value it is supposed to create, and what evidence would prove that it has done so.

This is not a slogan and not a restatement of the artifact title. It must be grounded in upstream sources such as the spec, plan, workshop, tasks dossier, user request, ADR, code contract, or product requirement.

All validators must use this thesis when judging correctness. An artifact can be locally correct and still fail validation if it does not advance the thesis it was produced to serve.

Gather evidence before writing the thesis. Quote or reference the source that establishes the artifact's purpose. If the thesis must be inferred, mark it `INFERRED` and explain the evidence used. If the thesis cannot be established from upstream evidence, validation must surface this as a HIGH issue: the artifact's purpose is under-specified.

**VALIDATION THESIS**

- **Raison d'être**: Why was this artifact created? What problem, ambiguity, risk, coordination cost, or delivery bottleneck is it meant to reduce?
- **Value claim**: What should become cheaper, safer, clearer, faster, more repeatable, more accessible, or more knowable because this artifact exists?
- **Artifact promise**: What specific promise does this artifact make to future humans, agents, code, reviewers, or downstream phases?
- **Intended beneficiaries**: Who or what is supposed to benefit? Examples: implementation agents, reviewers, product users, operators, downstream phases, future maintainers.
- **Proof target**: What level of proof is appropriate here?
  - **Orientation** — helps a fresh entrant understand the topic and why it matters
  - **Decision** — resolves or narrows a decision space
  - **Contract** — specifies interfaces, schemas, states, commands, invariants, or handoffs
  - **Implementation** — gives enough detail to build or modify the system with minimal clarification
  - **Integration** — proves the artifact composes with named consumers, contracts, and runtime behavior
  - **Validated Evidence** — backs the claim with tests, traces, command output, source-code match, deployment evidence, or comparable verification
- **Evidence standard**: What evidence would make the value claim credible? Examples: source-code match, tests, schemas, traces, examples, diagrams, command output, downstream compatibility, reviewability.
- **Critical assumptions**: What must be true for this artifact to deliver its value?
- **Non-goals**: What is this artifact explicitly not trying to prove or solve?
- **Failure consequence**: What goes wrong if this artifact is accepted but the thesis is false?
- **Source of thesis**: Quote or reference the upstream source used to derive the thesis. If inferred, mark `INFERRED` and explain why.

### Step 1.5: Establish the VPO Triple (mandatory)

After establishing the Validation Thesis, establish where the artifact sits in the arc of work. The Validation Thesis answers **why** the artifact exists. The VPO Triple answers **where** it sits in the chain of work and **who** must be able to consume it.

Gather **evidence** before writing — no vibes, no prose placeholders. The VPO Triple is **Vector, Position, Outcome**. It feeds every agent's Context section and anchors the Forward-Compatibility lens.

All three fields are required. There is **no per-field skip**. The only valid skip is the entire Forward-Compatibility lens, and that requires the three-condition policy in *Engagement Policy* below.

**VECTOR** (the chain, named)
- Upstream artifact: `<file path>` — or `ORIGIN` if this starts the chain
- Upstream's promise we inherit: `<specific requirement quoted from upstream>`
- Downstream consumers (enumerate by identifier — no vibes):
  - `<phase/file/contract id>` — needs: `<specific requirement from us>`
  - `<phase/file/contract id>` — needs: `<specific requirement from us>`
- If no concrete downstream exists in the plan tree, search committed ADRs/specs/workshops for references to this artifact and list hits. Mark provisional `STANDALONE` only if all hits are empty **and** the Engagement Policy's three-condition check passes.

**POSITION** (the outgoing contract)
- Public contract (enumerate): types, functions, files, invariants downstream can depend on
- Intentionally private: what's inside the box and should stay there
- Accidental exposure risks: things consumers might depend on that aren't contract

**OUTCOME** (the North Star)
- Quote (verbatim) the user/product value from the spec's "why this matters" section: `"<quote>"`
- If no spec exists, quote the nearest available source of user/product value and mark the source type. If no source exists, mark `MISSING` and raise a HIGH thesis issue.
- One sentence on how this artifact advances that value

**Engagement Policy (three-condition skip)**

Default is **engage**. Forward-Compatibility may be skipped only when *all three* hold with evidence:
1. No downstream phase exists in the plan tree (directory listing proof)
2. No external contract in committed files names this artifact (grep across `docs/adr/`, `docs/specs/`, `docs/plans/*/workshops/`, committed RFC-style files). **Open GitHub issues are not part of the automated check** — validators are read-only and lack `gh` CLI; escalate to the user for manual confirmation if an open issue might apply.
3. No user-value chain segment depends on this artifact's shape (assert with reasoning grounded in the spec's "why this matters")

Skipping = explicit `STANDALONE` verdict with each of the three conditions' evidence listed. "Looks standalone to me" is not valid.

**Plan-Tree Traversal (next-phase canonical rule)**

If the artifact lives under `docs/plans/<plan>/phase-<N>/` or `docs/plans/<plan>/phase-<N>-<slug>/`, resolve the "next phase" in this strict order:

1. **Exact match**: if `phase-<N+1>/` exists, read `phase-<N+1>/tasks.md`.
2. **Slugged match**: if `phase-<N+1>-<slug>/` exists, read its `tasks.md`. If multiple slugged variants exist, pick the **alphabetically first** by slug (predictable, not vibes-based).
3. **Fallback within the next-phase folder**: if the chosen folder has no `tasks.md`, try `phase.md`, then fall back to the plan's root `plan.md` phase table.
4. **Stop at N+1**: do not traverse to `phase-<N+2>` or beyond — the check is immediate-next-phase only by design (cost containment).
5. **No numbered structure**: read `plan.md` and extract the phase table if present.
6. **Nothing downstream**: proceed to the Engagement Policy check.

Verify each listed input/prerequisite in the target file is satisfied by the current artifact's Position. Unsatisfied inputs surface as Forward-Compatibility Matrix rows.

### Step 2: Design Validation Agents

Based on the detected category, design 2–4 parallel agents. Each agent gets:

1. **A specific validation lens** (not overlapping with other agents)
2. **The artifact content** (file paths to read)
3. **Source-of-truth files** to cross-reference against
4. **The Validation Thesis from Step 1.25 verbatim**
5. **The VPO Triple from Step 1.5 verbatim**
6. **Explicit output format**: issues found, severity, recommended fix

Every validation run must cover **Thesis Alignment**. Every broad-scope run should include a dedicated Thesis Alignment Agent unless the artifact is tiny and the lens can be safely merged into the most relevant category agent. If merged, the agent prompt must still include the thesis verdict requirements from the Thesis Alignment Agent template.

Every broad-scope run includes a **Forward-Compatibility Agent** alongside the category-specific agents, unless the artifact is a valid `STANDALONE` under the Engagement Policy.

#### Agent Templates by Category

**Tasks Dossier Agents** (3–4 agents):
- **Source Truth Agent**: Read the actual source files referenced in tasks. Verify line numbers, method signatures, class hierarchies, import statements. Flag anything that doesn't match.
- **Cross-Reference Agent**: Verify plan↔dossier alignment (task count, key finding references), workshop↔dossier code alignment, dependency chain correctness.
- **Completeness Agent**: Check for missing error handling, missing null checks, missing test coverage mentions, pre-implementation check completeness.
- **Thesis Alignment Agent**: Verify the dossier's tasks actually advance the Validation Thesis, preserve the artifact promise, and provide evidence at the target proof level.
- **Forward-Compatibility Agent** (see template below). If a 4-agent cap is required, merge Cross-Reference + Completeness or merge Thesis Alignment into Cross-Reference, but do not drop thesis coverage.

**Code Change Agents** (3–4 agents):
- **Correctness Agent**: Read modified files. Check logic, edge cases, null safety, exception handling. Verify changes match the tasks dossier specification.
- **Regression Agent**: Check if changes break existing patterns. Verify test coverage. Look for unintended side effects on other consumers. Check for deployment impacts: new env vars, config changes, migration requirements, CI pipeline changes. Check for cross-domain impacts: new imports from other domains, contract changes, shared type modifications.
- **Domain Compliance Agent**: Verify changes are in the right location. Check import/dependency direction. Flag contract changes.
- **Thesis Alignment Agent**: Verify the code change delivers the value claim it was meant to deliver, not merely a locally plausible implementation.
- **Forward-Compatibility Agent** (see template below). If a 4-agent cap is required, merge Regression + Domain Compliance, but do not drop thesis coverage.

**Plan Agents** (3–4 agents):
- **Coherence Agent**: Verify phases are properly ordered, dependencies are correct, no circular dependencies, each phase has clear deliverables.
- **Risk Agent**: Cross-reference risks with key findings. Verify mitigations are actionable. Check for unaddressed risks from research.
- **Completeness Agent**: Verify acceptance criteria are testable, all touched areas are accounted for. Challenge CS scores: for each task, ask "What could make this harder than the CS score suggests?" Flag tasks where CS seems underestimated based on the code they touch.
- **Thesis Alignment Agent**: Verify the plan phases, deliverables, and acceptance criteria preserve the reason for the work and produce the evidence required by the Validation Thesis.
- **Forward-Compatibility Agent** (see template below). If a 4-agent cap is required, merge Risk + Completeness, but do not drop thesis coverage.

> **Phase decomposition is out of scope for every Plan Agent.** Validate *within* the plan's chosen phases, and treat `**Mode**: Simple` as a deliberate single-phase decision — never flag "should be multi-phase" or recommend splitting/adding phases as a fix. A finding like "this single phase is too thin to be implementation-ready" is reframed as *"strengthen the existing phase — add the missing acceptance criteria / Done-When / concrete files"*, **not** "split it into more phases." If decomposition genuinely looks wrong, report it as one advisory line for the human (it is never auto-applied; phase count is the human's call at planning time).

**Spec Agents** (3–4 agents):
- **Clarity Agent**: Check whether user value, scope, acceptance criteria, constraints, and non-goals are explicit enough to guide downstream planning.
- **Completeness Agent**: Look for missing user journeys, edge cases, domain boundaries, operational constraints, and measurable outcomes.
- **Thesis Alignment Agent**: Verify the spec has a clear value thesis, beneficiaries, proof target, and evidence standard sufficient for downstream artifacts.
- **Forward-Compatibility Agent** (see template below), unless the spec is the origin of the chain and qualifies as valid `STANDALONE`.

**Workshop Agents** (3–4 agents):
- **Accuracy Agent**: Fact-check claims, examples, schemas, commands, and diagrams against source code, docs, specs, and related workshops.
- **Decision Coverage Agent**: Verify the workshop answers the key questions that prompted it, records rejected alternatives, and captures unresolved questions clearly.
- **Evidence & Proof Agent**: Check whether the workshop reaches its target proof level with concrete examples, contracts, validation paths, and evidence.
- **Thesis Alignment Agent**: Verify the workshop's selected value axes and evidence actually support its raison d'être.
- **Forward-Compatibility Agent** (see template below). If a 4-agent cap is required, merge Evidence & Proof with Thesis Alignment.

**General Agents** (2–4 agents):
- **Accuracy Agent**: Fact-check claims against source code and documentation.
- **Consistency Agent**: Check for internal contradictions, terminology consistency, cross-reference accuracy.
- **Thesis Alignment Agent**: Verify the artifact serves the stated or inferred reason for existing.
- **Forward-Compatibility Agent** (see template below), unless valid `STANDALONE`.

**Thesis Alignment Agent** (mandatory lens; dedicated when possible):
Verifies that the artifact actually advances the Validation Thesis. Checks for thesis drift, proxy optimization, unsupported value claims, missing proof, mismatched proof level, and work that is correct in isolation but does not serve the stated reason for doing it.

Use these named thesis failure modes:

| Mode | Question | Example |
|------|----------|---------|
| **Thesis drift** | Does the artifact solve a different problem than the one it was created to solve? | Spec asks for safer migrations; plan focuses only on new feature delivery. |
| **Proxy optimization** | Is the artifact optimizing an easy proxy instead of the real value? | Workshop is long and detailed but does not reduce implementation ambiguity. |
| **Proof mismatch** | Is the claimed proof level higher than the evidence supports? | Marked implementation-ready, but no schemas, examples, edge cases, or validation commands exist. |
| **Unsupported value claim** | Does the artifact claim value without evidence? | Says "reduces review burden" but provides no review checklist, acceptance criteria, or expected outputs. |
| **Raison d'être loss** | Has the original reason for the work disappeared from the artifact? | User asked for onboarding clarity; artifact becomes an internal architecture debate. |
| **Wrong beneficiary** | Does the artifact help the wrong consumer? | Optimized for platform maintainers but downstream agents need command examples. |
| **Non-goal creep** | Is the artifact expanding into work that the thesis explicitly excluded? | Validation of a narrow bug fix turns into a redesign proposal. |
| **Evidence gap** | Is the required evidence standard missing or too weak? | Integration safety is claimed but no compatibility examples, error cases, or tests are provided. |
| **Assumption leakage** | Does the artifact rely on unstated assumptions that must be true for the thesis to hold? | Plan assumes an API supports batch reads but never verifies the API contract. |

The Thesis Alignment Agent output must include a **Thesis Verdict**:

```markdown
### Thesis Verdict

- **Thesis understood?** Yes | No | Inferred | Under-specified
- **Thesis source**: <file/user request/ADR/spec/workshop/etc.>
- **Value claim advanced?** Yes | Partially | No
- **Proof level**: Target = <level>; Actual = <level>
- **Evidence quality**: Strong | Adequate | Weak | Missing
- **Main thesis risk**: <one sentence>
```

**Forward-Compatibility Agent** (required unless valid STANDALONE):
Verifies that the artifact's Position satisfies every named consumer in the Vector (from Step 1.5). Uses the **five named failure modes**:

| Mode | Question | Example |
|------|----------|---------|
| **Encapsulation lockout** | Is anything private that a named downstream needs public? | Phase 1 keeps the Tiptap `editor` as a private field; Phase 3 toolbar needs to receive it. |
| **Shape mismatch** | Does the exported type include every field a downstream will destructure? | Exports `{ value, onChange }`; downstream destructures `{ value, onChange, selection }`. |
| **Lifecycle ownership** | Can a downstream sibling compose without fighting for resource ownership? | Parent owns editor lifecycle; sibling toolbar must nest rather than compose beside. |
| **Contract drift** | Does the deliverable satisfy the outside contract (ADR/RFC/workshop/spec)? | ADR-012 says debounce 200ms; implementation uses 100ms. |
| **Test boundary** | Can this artifact's testing approach be extended to cover downstream integration? | Heavy component mocks; downstream phase can't assert real integration. |

Agent output includes a **Forward-Compatibility Matrix** — one row per named consumer in the Vector — with columns `Consumer | Requirement | Mode | Verdict | Evidence`. Plus an **Outcome alignment** sentence quoting the VPO's Outcome and stating whether the artifact, as shipped, advances it.

> **Outcome-alignment ownership (authoritative rule)**: the Forward-Compatibility Agent produces the Outcome alignment sentence **exactly once**, as the final line of its output. The synthesizer (Step 6) echoes it verbatim into the final verdict and the Validation Record (Step 6.5) — it is **never reworded or regenerated**. If the agent omits it, Step 4.5 triggers a re-run; the synthesizer does not fabricate one.

### Step 2.25: Select Thesis-Relevant Validation Axes

After establishing the Validation Thesis and VPO Triple, select the validation axes that best test whether the artifact serves its reason for existing.

The validator should select 3–6 thesis-relevant axes. These are not fixed roles. They are lenses for testing the artifact's value claim.

Suggested axes include:

- Thesis Alignment
- Evidence Sufficiency
- Proof-Level Fit
- User/Product Value Preservation
- Downstream Usefulness
- Review Compression
- Safety to Change
- Implementation Readiness
- Agent Readiness
- Operational Reliability
- Migration Safety
- Contract Integrity
- Learning Compounding
- Attention Reduction
- Accessibility / Knowability
- Cross-Domain Coordination
- User Experience

The selected axes must be included in the agent coverage map. If an axis is central to the thesis, at least one agent must explicitly test it.

Do not fill every axis mechanically. The goal is to select the axes that explain how this artifact should make future work cheaper, safer, clearer, or more repeatable — then validate whether the artifact provides credible evidence for those axes.

### Step 2.5: Verify Lens Coverage

Before launching, verify agents collectively cover at least **9 of these 15** analysis lenses (hard floor). **Thesis Alignment** is mandatory. **Forward-Compatibility** is mandatory unless valid `STANDALONE`.

| Lens | What it catches |
|------|----------------|
| **Thesis Alignment** | Whether the artifact advances the reason it was created |
| **Evidence Sufficiency** | Unsupported claims, missing proof, weak validation paths |
| **Proof-Level Fit** | Claimed proof level exceeds the artifact's evidence |
| User Experience | Surprising behavior changes, UX regressions |
| System Behavior | New constraints, assumption violations |
| Technical Constraints | Platform limits, API restrictions |
| Integration & Ripple | Downstream impacts, broken consumers |
| Hidden Assumptions | Implicit bets that could fail |
| Edge Cases & Failures | Unusual conditions, cascading failures |
| Performance & Scale | Bottlenecks, resource concerns at scale |
| Security & Privacy | Exposed data, auth gaps, vulnerabilities |
| Deployment & Ops | CI/CD impacts, env vars, migrations, rollback |
| Domain Boundaries | Wrong domain, crossing boundaries, missing contracts |
| Concept Documentation | Stale docs, missing concepts, reuse opportunities |
| **Forward-Compatibility** | Does this artifact's shape satisfy each named downstream consumer? Five modes: encapsulation lockout, shape mismatch, lifecycle ownership, contract drift, test boundary. **Mandatory unless valid STANDALONE.** |

Map each agent to its covered lenses and selected thesis axes. If <9 covered, adjust agent prompts to fill gaps.

Priority fill order: Thesis Alignment > Forward-Compatibility > Evidence Sufficiency > Proof-Level Fit > Hidden Assumptions > Security > Edge Cases > Deployment/Ops > Performance.

For **Plan** validation, also challenge CS (complexity) scores:
- CS-1/2: What could make this NOT trivial?
- CS-3: How do we prove this works?
- CS-4/5: What's the rollback plan? Need subtask decomposition?

### Step 3: Launch Agents

Launch all agents in parallel using the `task` tool with:
- `agent_type: "explore"` (read-only validation)
- current session model; do not hard-code a model override. If the task tool inherits the active model by omitting `model`, omit the `model` field.
- `mode: "background"` (parallel execution)

Structure each agent prompt using this 6-section template:

**Section 1 — Validation Focus**: What artifact, what aspect, what specification to verify against. Which lenses from the checklist this agent covers. Which selected thesis axes this agent is responsible for testing.

**Section 2 — Context**: Tech stack, recent changes, domain ownership, relevant constraints, **the Validation Thesis from Step 1.25 verbatim**, and **the VPO Triple from Step 1.5 verbatim**.

Agents must judge findings against both:
1. the artifact's local correctness, and
2. whether the artifact advances its stated thesis.

A finding is valid when the artifact is incorrect, incomplete, inconsistent, risky, weakly evidenced, or materially misaligned relative to the thesis it was created to serve.

**Section 3 — Verification Questions**: 3-5 specific questions this agent must answer. Be concrete (e.g., "Does token refresh handle expired tokens?" not "Check for bugs"). At least one question should connect the agent's lens back to the Validation Thesis.

**Section 4 — Files to Read**: Ordered list with focus guidance — primary file with line range, then supporting files.

**Section 5 — Known Pitfalls**: Common failure patterns for this artifact type (e.g., race conditions in async handlers, stale line numbers in dossiers, missing Content-Type on error responses, proof mismatch, thesis drift).

**Section 6 — Output Format** (mandatory for every agent):

For each issue found, output this exact structure:
- **SEVERITY**: CRITICAL | HIGH | MEDIUM | LOW
- **LOCATION**: absolute-file-path:line-number
- **LENS**: which analysis lens from the checklist
- **ISSUE**: one-sentence description
- **EVIDENCE**: code snippet or concrete observation
- **FIX**: specific recommended change

If no issues found: "NO ISSUES — All checks passed for: [lens list]"

Only report genuine problems — not style preferences, not suggestions.

If this agent owns Thesis Alignment, include the Thesis Verdict block exactly as specified in the Thesis Alignment Agent template.

If this agent owns Forward-Compatibility, include the Forward-Compatibility Matrix and Outcome alignment sentence exactly as specified in the Forward-Compatibility Agent template.

### Step 4: Collect Results

Wait for all agents to complete. For each agent:
1. Read the results via `read_agent`
2. Extract issues found
3. Categorize by severity
4. Capture any Thesis Verdict block verbatim
5. Capture the Forward-Compatibility Agent output verbatim for Step 4.5

### Step 4.5: Completeness Guard (Forward-Compatibility)

**Capture the Forward-Compatibility Agent's full output verbatim from Step 4** (not just the extracted issues list — the whole block, including the Matrix heading, every row, and the final Outcome alignment line). The guard operates on this captured text.

Verify the captured output is structurally complete:
- A `Forward-Compatibility Matrix` heading exists
- The matrix has at least one row per named consumer in the VPO Vector — **or** a `STANDALONE` verdict with evidence for each of the three Engagement Policy conditions
- An `Outcome alignment` sentence is present and non-empty (not "seems fine", not "improves UX" — must reference the VPO Outcome)

If any check fails, re-launch the Forward-Compatibility agent once with this corrective prompt:

> Your prior run was incomplete: [specific miss — e.g., "the Matrix had no row for Phase 3 toolbar consumer"]. Re-run with the full Forward-Compatibility Matrix (one row per Vector consumer) and an Outcome-alignment sentence referencing the VPO Outcome verbatim. Do not skip rows. If you believe a consumer is irrelevant, say so explicitly in the Evidence column.

If the second run is still incomplete, escalate to the user — do not silently proceed.

### Step 4.6: Completeness Guard (Thesis Alignment)

Capture the Thesis Alignment output verbatim from Step 4. This may come from a dedicated Thesis Alignment Agent or from a merged agent that explicitly owns the Thesis Alignment lens.

Verify the captured output is structurally complete:
- A `Thesis Verdict` heading exists
- `Thesis understood?` is present and non-empty
- `Thesis source` is present and grounded in an upstream source or explicitly marked `INFERRED`
- `Value claim advanced?` is present and says `Yes`, `Partially`, or `No`
- `Proof level` includes both target and actual
- `Evidence quality` is present and says `Strong`, `Adequate`, `Weak`, or `Missing`
- `Main thesis risk` is present and non-empty

If any check fails, re-launch the Thesis Alignment agent once with this corrective prompt:

> Your prior run was incomplete: [specific miss — e.g., "no actual proof level was stated"]. Re-run with the full Thesis Verdict. Judge the artifact against the Validation Thesis verbatim. Do not replace thesis analysis with general correctness commentary.

If the second run is still incomplete, escalate to the user — do not silently proceed.

### Step 5: Synthesize and Act

Present findings to the user conversationally:

```markdown
## Validation Results

**3–4 agents completed** — [X issues found]

### Thesis Verdict

- Thesis understood?: [Yes/No/Inferred/Under-specified]
- Value claim advanced?: [Yes/Partially/No]
- Proof level: Target = [level]; Actual = [level]
- Evidence quality: [Strong/Adequate/Weak/Missing]
- Main thesis risk: [one sentence]

### Critical Issues (fix now)
- [issue]: [what's wrong] → [fix]

### High Issues (should fix)
- [issue]: [what's wrong] → [fix]

### Medium/Low Issues (consider)
- [issue]: [what's wrong] → [fix]

### Clean Areas
- [agent 1 lens]: ✅ No issues
```

**Then immediately apply fixes** for CRITICAL and HIGH issues when the fix is mechanical and grounded in source evidence:
- Edit the artifact files directly
- Show what changed
- Re-verify if needed

> **Never restructure a plan's phase decomposition as an auto-fix.** Phase count — splitting one phase into several, adding or removing phases, merging them, or flipping a Simple-mode (single-phase) plan to Full — is a **human-gated planning decision**, not a mechanical fix. Validation checks the plan *at the decomposition the human chose*; it never edits the plan to expand or collapse phases. If an agent genuinely believes the decomposition is wrong, surface it as a single advisory line under a **Human-gated (not applied)** heading and mark the artifact **NEEDS ATTENTION** so the human decides — leaving every phase, task table, and the `**Mode**` header exactly as written. A Simple-mode plan is single-phase *by deliberate choice*; "should be multi-phase" is never, by itself, a validation issue. When a phase looks under-specified, the in-scope fix is to strengthen the existing phase (add acceptance criteria, Done-When, concrete files/paths) — **not** to break it into more phases.

Do **not** invent product intent or source truth to fix an under-specified thesis. If a CRITICAL/HIGH issue requires a product decision, missing upstream source, or user judgment, present the decision needed and mark the artifact **NEEDS ATTENTION**.

For MEDIUM/LOW issues: present them but ask the user before fixing.

### Step 6: Summary

End with a one-line verdict **plus** the Outcome-alignment sentence (echoed verbatim from the Forward-Compatibility Agent, not regenerated) and the Thesis Verdict summary (echoed from the Thesis Alignment output, not regenerated):

- ✅ **VALIDATED** — no issues found (or only LOW), thesis advanced at the target proof level, and Forward-Compatibility passed or validly skipped
- ⚠️ **VALIDATED WITH FIXES** — issues found and fixed; thesis now advanced enough for the target proof level; any remaining issues are LOW or explicitly accepted
- ❌ **NEEDS ATTENTION** — unresolved CRITICAL/HIGH issues, under-specified thesis, thesis not advanced, proof mismatch, downstream consumers blocked, or user decision required

Then:

`**Thesis alignment**: <one sentence from the Thesis Verdict: value claim advanced + proof level + main thesis risk>`

`**Outcome alignment**: <one sentence from the Forward-Compatibility agent>`

If the Thesis Verdict is generic or hand-wavy ("seems useful", "looks aligned", "probably helps"), escalate the verdict to **NEEDS ATTENTION** and flag the drift — a vague thesis echo is itself a signal the work has lost its raison d'être.

If the Forward-Compatibility Agent's outcome sentence is generic or hand-wavy ("improves UX", "looks fine forward"), escalate the verdict to **NEEDS ATTENTION** and flag the drift — a vague outcome echo is itself a signal the arc has lost the plot.

### Step 6.5: Persist Validation Record

Append a compact validation record to the validated artifact (if it is a file):

```markdown
---

## Validation Record (ISO-8601 date)

### Validation Thesis

**Raison d'être**: [Why this artifact exists]

**Value claim**: [What should become cheaper, safer, clearer, faster, more repeatable, more accessible, or more knowable]

**Artifact promise**: [What future humans, agents, code, reviewers, or phases can rely on]

**Intended beneficiaries**: [Who or what benefits]

**Proof target**: [Orientation | Decision | Contract | Implementation | Integration | Validated Evidence]

**Evidence standard**: [What evidence was required]

**Thesis source**: [Spec / plan / workshop / user request / ADR / inferred]

**Thesis verdict**: Advanced | Partially advanced | Not advanced | Under-specified

**Main thesis risk**: [one sentence]

---

| Agent | Lenses Covered | Thesis Axes Covered | Issues | Verdict |
|-------|---------------|---------------------|--------|---------|
| Agent Name | lens, lens | axis, axis | count severity fixed/open | verdict |

### Forward-Compatibility Matrix (required unless STANDALONE)

| Consumer | Requirement | Failure Mode | Verdict | Evidence |
|----------|-------------|--------------|---------|----------|
| <downstream id> | <specific need> | <one of 5 modes> | ✅ / ❌ | <file:line or reasoning> |

**Thesis alignment**: <sentence from the Thesis Verdict: value claim advanced + proof level + main thesis risk>

**Outcome alignment**: <sentence from the Forward-Compatibility agent, quoting the VPO Outcome>

**Standalone?**: No — or — Yes, with evidence: (1) no downstream phase (directory listing), (2) no external contract (grep hits empty), (3) no user-value chain dependency (spec reasoning).

Overall: VALIDATED | VALIDATED WITH FIXES | NEEDS ATTENTION
```

This creates an audit trail — future agents can see what was already validated and what it was validated **for**.

Skip persistence for console-only artifacts or non-markdown files.

---

## Key Principles

1. **Thesis before tactics** — understand why the artifact exists before judging whether it is good
2. **Correctness is not enough** — an artifact can be locally correct and still fail if it does not advance its thesis
3. **Agents validate, parent synthesizes** — agents report raw findings, the parent decides what to fix
4. **Source code is truth** — when a dossier says "line 131" and the file says otherwise, the file wins
5. **Evidence over assertion** — value claims need concrete support: tests, schemas, examples, traces, source match, contracts, or comparable proof
6. **Fix what you find — except plan structure** — apply mechanical, source-grounded fixes immediately; but **phase decomposition (count, splitting, merging, Simple↔Full) is human-gated** — surface it as advisory, never auto-apply it. Strengthen the phase the human chose; never silently expand it into more phases.
7. **No false positives** — every issue must be real and actionable. Agent prompts emphasize: "only report genuine problems, not style preferences"
8. **Gift to future selves** — if validation catches a recurring issue type, consider whether the upstream skill should be improved to prevent it

---

## Worked Example — Thesis + Forward-Awareness in Practice

*Illustrative — based on a real validation pattern from a separate substrate. Paths are representative, not repo-verifiable.*

**Artifact**: Phase 1 ships `MarkdownEditor` — a React component wrapping Tiptap with the Tiptap `editor` instance held as a private field.

**Bad check** (what a shallow 3-agent sweep might do):

> Source Truth: file exists, types match. ✅
> Cross-Reference: plan says "ship MarkdownEditor"; dossier matches. ✅
> Completeness: tests cover render, onChange, disabled state. ✅
> **Verdict**: ✅ VALIDATED.

Each individual check passed. Nothing asked whether the artifact served the reason for doing the work, or whether Phase 2's planned toolbar could consume the Phase 1 output. The miss landed as rework.

**Good check** (with Validation Thesis + VPO + Forward-Compatibility):

**VALIDATION THESIS**
- **Raison d'être**: Ship a markdown editor primitive that makes inline authoring possible without forcing users to leave the viewer.
- **Value claim**: Authoring becomes faster and less context-switch-heavy because formatting and linking happen inline.
- **Artifact promise**: Downstream toolbar and viewer phases can compose with the editor primitive without refactoring its lifecycle.
- **Proof target**: Integration
- **Evidence standard**: Public editor access or equivalent composition mechanism; tests that can extend to toolbar/editor integration; contract alignment with planned phases.

**VPO**
- **VECTOR** — Upstream: `083-md-editor-spec.md` — promises "A markdown editor primitive Phases 2–5 compose with." Downstream: Phase 2 `tasks.md` (needs public `editor`), Phase 5 workshop §15.3 (needs composable editor).
- **POSITION** — Public contract: `{ value, onChange }` prop API. Intentionally private: internal selection state. Accidental exposure: none identified.
- **OUTCOME** — Quoted from spec: *"Authors can edit, format, and link markdown inline without leaving the viewer."*

**Thesis Verdict**:
- **Thesis understood?** Yes
- **Thesis source**: `083-md-editor-spec.md`
- **Value claim advanced?** Partially
- **Proof level**: Target = Integration; Actual = Implementation
- **Evidence quality**: Weak for integration
- **Main thesis risk**: The editor implementation is locally usable but not yet composable enough to support the inline authoring workflow promised downstream.

**Forward-Compatibility Matrix**:

| Consumer | Requirement | Mode | Verdict | Evidence |
|----------|-------------|------|---------|----------|
| Phase 2 toolbar | public `editor` instance | encapsulation lockout | ❌ BLOCKED | `MarkdownEditor.tsx:12` — `editor` closed over, not exported via ref/prop/context |
| Phase 5 FileViewerPanel | composable editor | lifecycle ownership | ❌ BLOCKED | editor lifecycle tied to `MarkdownEditor` mount; sibling can't share instance |

**Outcome alignment**: Not yet — Phase 1 ships a primitive that will require refactor before Phase 2/5 can consume it; inline editing is not on the current trajectory without an API change.

**Verdict**: ❌ NEEDS ATTENTION. Fix: expose `editor` via `forwardRef` (smallest API surface change), or via an `editor` context, or hoist editor state to a parent hook.

### Mini-examples for the remaining three Forward-Compatibility modes

**Shape mismatch** — Phase 1 ships `useDocumentState(): { value, onChange }`; Phase 3 autosave hook destructures `{ value, onChange, selection, isDirty }` per workshop §4.2. Matrix row: *Phase 3 autosave → needs `selection, isDirty` → **shape mismatch** → ❌ → fix: extend hook's return type, update tests, re-export.*

**Contract drift** — ADR-012 mandates 200ms debounce on save; implementation ships `debounce(100)` because of local typing-feel tuning. Matrix row: *ADR-012 → requires 200ms → **contract drift** → ❌ → fix: set `DEBOUNCE_MS = 200` with a comment linking the ADR.*

**Test boundary** — Phase 1's tests mock the Tiptap editor via `createMockEditor()`; Phase 3 needs real toolbar-editor integration assertions. Matrix row: *Phase 3 integration tests → need real editor wiring → **test boundary** → ❌ → fix: split utilities into `unit-mocks.ts` and `integration-real.tsx`, document the boundary.*

### Mini-examples for Thesis failure modes

**Proxy optimization** — A workshop is extremely detailed but never produces the state table, examples, or proof artifacts that would reduce implementation ambiguity. Thesis row: *Value claim = implementation readiness → **proxy optimization** → ❌ → fix: add contract-ready evidence, not more prose.*

**Wrong beneficiary** — A tasks dossier optimizes for the implementer but omits reviewer-facing acceptance criteria, even though the Validation Thesis says the work should compress review. Thesis row: *Beneficiary = reviewers → **wrong beneficiary** → ⚠️ → fix: add validation commands, expected outputs, and review checkpoints.*

**Proof mismatch** — A plan is labeled implementation-ready but only contains phase names and vague deliverables. Thesis row: *Proof target = Implementation → Actual = Decision → ❌ → fix: add acceptance criteria, concrete files, dependencies, and validation evidence.*

---

## Example Invocations

```bash
# After generating a tasks dossier
/validate

# After implementing a phase
/validate

# After creating a plan
/validate

# After creating a workshop
/validate

# Validate a specific file
/validate --artifact docs/plans/my-feature/tasks/phase-2/tasks.md
```

The skill auto-detects what to validate. You almost never need flags.

---

## Historical Validation Record (2026-04-18)

**Bootstrap run from the source prompt** — retained as historical context. This record validated the forward-awareness version of `validate-v2` before the thesis-aware additions in this file. If this regenerated prompt is installed as the active command, run `/validate --artifact <this-file>` to create a fresh thesis-aware Validation Record.

| Agent | Lenses Covered | Issues | Verdict |
|-------|---------------|--------|---------|
| Accuracy | Factual Accuracy, Concept Documentation, Hidden Assumptions | 1 HIGH fixed, 0 open | ⚠️ → ✅ |
| Consistency | Integration & Ripple, Hidden Assumptions, Edge Cases | 0 | ✅ |
| Forward-Compatibility | Forward-Compatibility, Technical Constraints, Deployment & Ops | 2 MEDIUM open, 1 LOW open | ⚠️ |

**Lens coverage**: 9/12 in the historical run. Forward-Compatibility engaged (not STANDALONE — downstream consumers existed).

### Historical Forward-Compatibility Matrix

| Consumer | Requirement | Failure Mode | Verdict | Evidence |
|----------|-------------|--------------|---------|----------|
| Future `/validate-v2` runs | VPO block fillable, agent instantiable, matrix emittable | encapsulation lockout | ✅ | Step 1.5 fields; Forward-Compat agent template; Matrix template |
| Future `/validate-v2` runs | Lifecycle clarity for Outcome sentence (who produces, who echoes) | lifecycle ownership | ⚠️ | Three sections described it without single source of truth — FC1 open |
| Future `/validate-v2` runs | Re-run mechanism architecturally wired | test boundary | ⚠️ | Step 4.5 described guard + re-launch, but Step 4 output-capture path was implicit — FC2 open |
| Issue #3 touch points | Step 1.5 position established | contract drift | ✅ | Full VPO triple delivered |
| Issue #3 touch points | Section 2 references arc position | contract drift | ✅ | Step 3 Section 2 carried VPO verbatim |
| Issue #3 touch points | Integration & Ripple forward clause | contract drift | ✅ | Superseded: promoted to Forward-Compatibility as its own lens |
| Synced copies | Source ↔ dist identity | shape mismatch | ✅ | `diff` clean after `./setup.sh` |
| Legacy `.vscode/validate-v2.md` | Removed or marked legacy | encapsulation lockout | ❌ LOW | File stale (~10KB vs 21KB source); no warning header — FC3 open |

**Historical Outcome alignment**: The artifact made forward-awareness structurally harder to skip via mandatory output slots, evidence requirements, checklists, and worked examples. Outcome was substantially advanced; two minor ambiguities (FC1 outcome-echo ownership, FC2 re-run orchestration) did not undermine the core achievement.

**Historical Overall**: ⚠️ VALIDATED WITH FIXES — ready for dogfooding at the time; open items were tightening passes, not blockers.

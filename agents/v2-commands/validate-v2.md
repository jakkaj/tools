---
description: Launch parallel subagents to validate whatever was just produced with structured lens coverage — tasks dossier, code changes, plan, spec, or any artifact. Universal post-action validation.
---

Please deep think / ultrathink as this is a complex task.

# validate-v2

**Universal post-action validation** — launches parallel GPT-5.4 subagents to cross-check whatever artifact was just produced. Works on any output: tasks dossier, code changes, plan, spec, workshop, or any structured document.

## Philosophy

> "Every artifact deserves a second pair of eyes before the human sees it."

This skill is the automated equivalent of asking 3 senior engineers to review your work in parallel. Each agent has a different lens. They run on GPT-5.4 for high reasoning quality. Results are synthesized and actionable fixes applied immediately.

---

```md
User input:

$ARGUMENTS
# No flags required — auto-detects what to validate from context.
# Optional: --artifact <path> to specify a file to validate
# Optional: --scope <narrow|broad> to control agent count and model (default: broad = 3 agents)
#   narrow: fewer agents, default model (faster for specs/plans)
#   broad: full agents, gpt-5.4 (thorough for code/tasks)
```

## How It Works

### Step 1: Detect What Was Just Done

Examine the conversation context to determine what artifact was just produced. Categories:

| Category | Detection Signal | Agent Focus |
|----------|-----------------|-------------|
| **Tasks Dossier** | Recent plan-5 skill invocation, tasks.md file created/modified | Line numbers, code snippets, cross-references, dependency chain |
| **Code Changes** | Recent plan-6 skill invocation, source files edited | Correctness, edge cases, missing error handling, contract compliance |
| **Plan** | Recent plan-3 skill invocation, plan.md created | Phase coherence, risk coverage, domain alignment, missing tasks |
| **Spec** | Recent plan-1b skill invocation, spec.md created | Ambiguities, missing acceptance criteria, scope gaps |
| **Workshop** | Recent plan-2c skill invocation, workshop file created | Factual accuracy, code examples vs actual source, decision coverage |
| **General** | Anything else | Correctness, completeness, consistency |

### Step 1.5: Establish the VPO Triple (mandatory)

Before designing agents, establish where the artifact sits in the arc of work. Gather **evidence** before writing — no vibes, no prose placeholders. The VPO Triple is **Vector, Position, Outcome**. It feeds every agent's Context section and anchors the Forward-Compatibility lens.

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

Based on the detected category, design 2-4 parallel agents. Each agent gets:

1. **A specific validation lens** (not overlapping with other agents)
2. **The artifact content** (file paths to read)
3. **Source-of-truth files** to cross-reference against
4. **Explicit output format**: issues found, severity, recommended fix

#### Agent Templates by Category

Every broad-scope run includes a **Forward-Compatibility Agent** alongside the category-specific agents, unless the artifact is a valid `STANDALONE` under the Engagement Policy.

**Tasks Dossier Agents** (3–4 agents):
- **Source Truth Agent**: Read the actual source files referenced in tasks. Verify line numbers, method signatures, class hierarchies, import statements. Flag anything that doesn't match.
- **Cross-Reference Agent**: Verify plan↔dossier alignment (task count, key finding references), workshop↔dossier code alignment, dependency chain correctness.
- **Completeness Agent**: Check for missing error handling, missing null checks, missing test coverage mentions, pre-implementation check completeness.
- **Forward-Compatibility Agent** (see template below).

**Code Change Agents** (3–4 agents):
- **Correctness Agent**: Read modified files. Check logic, edge cases, null safety, exception handling. Verify changes match the tasks dossier specification.
- **Regression Agent**: Check if changes break existing patterns. Verify test coverage. Look for unintended side effects on other consumers. Check for deployment impacts: new env vars, config changes, migration requirements, CI pipeline changes. Check for cross-domain impacts: new imports from other domains, contract changes, shared type modifications.
- **Domain Compliance Agent**: Verify changes are in the right location. Check import/dependency direction. Flag contract changes.
- **Forward-Compatibility Agent** (see template below).

**Plan Agents** (3–4 agents):
- **Coherence Agent**: Verify phases are properly ordered, dependencies are correct, no circular dependencies, each phase has clear deliverables.
- **Risk Agent**: Cross-reference risks with key findings. Verify mitigations are actionable. Check for unaddressed risks from research.
- **Completeness Agent**: Verify acceptance criteria are testable, all touched areas are accounted for. Challenge CS scores: for each task, ask "What could make this harder than the CS score suggests?" Flag tasks where CS seems underestimated based on the code they touch.
- **Forward-Compatibility Agent** (see template below).

**General Agents** (2–3 agents):
- **Accuracy Agent**: Fact-check claims against source code and documentation.
- **Consistency Agent**: Check for internal contradictions, terminology consistency, cross-reference accuracy.
- **Forward-Compatibility Agent** (see template below).

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

### Step 2.5: Verify Lens Coverage

Before launching, verify agents collectively cover at least **8 of these 12** analysis lenses (hard floor):

| Lens | What it catches |
|------|----------------|
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

Map each agent to its covered lenses. If <8 covered, adjust agent prompts to fill gaps.
Priority fill order: Forward-Compatibility > Hidden Assumptions > Security > Edge Cases > Deployment/Ops > Performance.

For **Plan** validation, also challenge CS (complexity) scores:
- CS-1/2: What could make this NOT trivial?
- CS-3: How do we prove this works?
- CS-4/5: What’s the rollback plan? Need subtask decomposition?

### Step 3: Launch Agents

Launch all agents in parallel using the `task` tool with:
- `agent_type: "explore"` (read-only validation)
- `model: "gpt-5.4"` for code/tasks validation, default model for specs/plans (or when `--scope narrow`)
- `mode: "background"` (parallel execution)

Structure each agent prompt using this 6-section template:

**Section 1 — Validation Focus**: What artifact, what aspect, what specification to verify against. Which lenses (from the 11-lens checklist) this agent covers.

**Section 2 — Context**: Tech stack, recent changes, domain ownership, relevant constraints, **and the VPO Triple from Step 1.5 verbatim**. Agents must reference the VPO when judging — the Forward-Compatibility agent most heavily, but every agent is expected to connect its findings back to the artifact's position in the arc.

**Section 3 — Verification Questions**: 3-5 specific questions this agent must answer. Be concrete (e.g., "Does token refresh handle expired tokens?" not "Check for bugs").

**Section 4 — Files to Read**: Ordered list with focus guidance — primary file with line range, then supporting files.

**Section 5 — Known Pitfalls**: Common failure patterns for this artifact type (e.g., race conditions in async handlers, stale line numbers in dossiers, missing Content-Type on error responses).

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

### Step 4: Collect Results

Wait for all agents to complete. For each agent:
1. Read the results via `read_agent`
2. Extract issues found
3. Categorize by severity

### Step 4.5: Completeness Guard (Forward-Compatibility)

**Capture the Forward-Compatibility Agent's full output verbatim from Step 4** (not just the extracted issues list — the whole block, including the Matrix heading, every row, and the final Outcome alignment line). The guard operates on this captured text.

Verify the captured output is structurally complete:
- A `Forward-Compatibility Matrix` heading exists
- The matrix has at least one row per named consumer in the VPO Vector — **or** a `STANDALONE` verdict with evidence for each of the three Engagement Policy conditions
- An `Outcome alignment` sentence is present and non-empty (not "seems fine", not "improves UX" — must reference the VPO Outcome)

If any check fails, re-launch the Forward-Compatibility agent once with this corrective prompt:

> Your prior run was incomplete: [specific miss — e.g., "the Matrix had no row for Phase 3 toolbar consumer"]. Re-run with the full Forward-Compatibility Matrix (one row per Vector consumer) and an Outcome-alignment sentence referencing the VPO Outcome verbatim. Do not skip rows. If you believe a consumer is irrelevant, say so explicitly in the Evidence column.

If the second run is still incomplete, escalate to the user — do not silently proceed.

### Step 5: Synthesize and Act

Present findings to the user conversationally:

```
## Validation Results

**3 agents completed** — [X issues found]

### Critical Issues (fix now)
- [issue]: [what's wrong] → [fix]

### High Issues (should fix)
- [issue]: [what's wrong] → [fix]

### Medium/Low Issues (consider)
- [issue]: [what's wrong] → [fix]

### Clean Areas
- [agent 1 lens]: ✅ No issues
```

**Then immediately apply fixes** for CRITICAL and HIGH issues:
- Edit the artifact files directly
- Show what changed
- Re-verify if needed

For MEDIUM/LOW issues: present them but ask the user before fixing.

### Step 6: Summary

End with a one-line verdict **plus** the Outcome-alignment sentence (echoed verbatim from the Forward-Compatibility Agent, not regenerated):

- ✅ **VALIDATED** — no issues found (or only LOW)
- ⚠️ **VALIDATED WITH FIXES** — issues found and fixed
- ❌ **NEEDS ATTENTION** — issues found that need user decision

Then: `**Outcome alignment**: <one sentence from the Forward-Compatibility agent>`.

If the agent's outcome sentence is generic or hand-wavy ("improves UX", "looks fine forward"), escalate the verdict to **NEEDS ATTENTION** and flag the drift — a vague outcome echo is itself a signal the arc has lost the plot.

### Step 6.5: Persist Validation Record

Append a compact validation record to the validated artifact (if it is a file):

```markdown
---

## Validation Record (ISO-8601 date)

| Agent | Lenses Covered | Issues | Verdict |
|-------|---------------|--------|---------|
| Agent Name | lens, lens | count severity fixed/open | verdict |

### Forward-Compatibility Matrix (required unless STANDALONE)

| Consumer | Requirement | Failure Mode | Verdict | Evidence |
|----------|-------------|--------------|---------|----------|
| <downstream id> | <specific need> | <one of 5 modes> | ✅ / ❌ | <file:line or reasoning> |

**Outcome alignment**: <sentence from the Forward-Compatibility agent, quoting the VPO Outcome>

**Standalone?**: No — or — Yes, with evidence: (1) no downstream phase (directory listing), (2) no external contract (grep hits empty), (3) no user-value chain dependency (spec reasoning).

Overall: VALIDATED | VALIDATED WITH FIXES | NEEDS ATTENTION
```

This creates an audit trail — future agents can see what was already validated.
Skip persistence for console-only artifacts or non-markdown files.

---

## Key Principles

1. **Agents validate, parent synthesizes** — agents report raw findings, the parent decides what to fix
2. **Source code is truth** — when a dossier says "line 131" and the file says otherwise, the file wins
3. **Fix what you find** — don't just report issues, apply the fixes immediately
4. **No false positives** — every issue must be real and actionable. Agent prompts emphasize: "only report genuine problems, not style preferences"
5. **Gift to future selves** — if validation catches a recurring issue type, consider whether the upstream skill should be improved to prevent it

---

## Worked Example — Forward-Awareness in Practice

*Illustrative — based on a real validation run (Plan 083-md-editor) from a separate substrate. Paths are representative, not repo-verifiable.*

**Artifact**: Phase 1 ships `MarkdownEditor` — a React component wrapping Tiptap with the Tiptap `editor` instance held as a private field.

**Bad check** (what the old 3-agent sweep did):

> Source Truth: file exists, types match. ✅
> Cross-Reference: plan says "ship MarkdownEditor"; dossier matches. ✅
> Completeness: tests cover render, onChange, disabled state. ✅
> **Verdict**: ✅ VALIDATED.

Each individual check passed. Nothing asked whether Phase 2's planned toolbar could actually consume the Phase 1 output. The miss landed as rework.

**Good check** (with VPO + Forward-Compatibility):

- **VECTOR** — Upstream: `083-md-editor-spec.md` — promises "A markdown editor primitive Phases 2–5 compose with." Downstream: Phase 2 `tasks.md` (needs public `editor`), Phase 5 workshop §15.3 (needs composable editor).
- **POSITION** — Public contract: `{ value, onChange }` prop API. Intentionally private: internal selection state. Accidental exposure: none identified.
- **OUTCOME** — Quoted from spec: *"Authors can edit, format, and link markdown inline without leaving the viewer."*

**Forward-Compatibility Matrix**:

| Consumer | Requirement | Mode | Verdict | Evidence |
|----------|-------------|------|---------|----------|
| Phase 2 toolbar | public `editor` instance | encapsulation lockout | ❌ BLOCKED | `MarkdownEditor.tsx:12` — `editor` closed over, not exported via ref/prop/context |
| Phase 5 FileViewerPanel | composable editor | lifecycle ownership | ❌ BLOCKED | editor lifecycle tied to `MarkdownEditor` mount; sibling can't share instance |

**Outcome alignment**: Not yet — Phase 1 ships a primitive that will require refactor before Phase 2/5 can consume it; inline editing is not on the current trajectory without an API change.

**Verdict**: ❌ NEEDS ATTENTION. Fix: expose `editor` via `forwardRef` (smallest API surface change), or via an `editor` context, or hoist editor state to a parent hook.

### Mini-examples for the remaining three modes

**Shape mismatch** — Phase 1 ships `useDocumentState(): { value, onChange }`; Phase 3 autosave hook destructures `{ value, onChange, selection, isDirty }` per workshop §4.2. Matrix row: *Phase 3 autosave → needs `selection, isDirty` → **shape mismatch** → ❌ → fix: extend hook's return type, update tests, re-export.*

**Contract drift** — ADR-012 mandates 200ms debounce on save; implementation ships `debounce(100)` because of local typing-feel tuning. Matrix row: *ADR-012 → requires 200ms → **contract drift** → ❌ → fix: set `DEBOUNCE_MS = 200` with a comment linking the ADR.*

**Test boundary** — Phase 1's tests mock the Tiptap editor via `createMockEditor()`; Phase 3 needs real toolbar-editor integration assertions. Matrix row: *Phase 3 integration tests → need real editor wiring → **test boundary** → ❌ → fix: split utilities into `unit-mocks.ts` and `integration-real.tsx`, document the boundary.*

---

## Example Invocations

```bash
# After generating a tasks dossier
/validate

# After implementing a phase
/validate

# After creating a plan
/validate

# Validate a specific file
/validate --artifact docs/plans/my-feature/tasks/phase-2/tasks.md
```

The skill auto-detects what to validate. You almost never need flags.

---

## Validation Record (2026-04-18)

**Bootstrap run** — validate-v2 (as edited) validated against itself using the new protocol. Upstream: `docs/plans/021-validate-v2-arc-awareness/workshops/001-forward-awareness-prompting.md`. Issue: jakkaj/tools#3.

| Agent | Lenses Covered | Issues | Verdict |
|-------|---------------|--------|---------|
| Accuracy | Factual Accuracy, Concept Documentation, Hidden Assumptions | 1 HIGH fixed, 0 open | ⚠️ → ✅ |
| Consistency | Integration & Ripple, Hidden Assumptions, Edge Cases | 0 | ✅ |
| Forward-Compatibility | Forward-Compatibility, Technical Constraints, Deployment & Ops | 2 MEDIUM open, 1 LOW open | ⚠️ |

**Lens coverage**: 9/12 (above the 8-floor). Forward-Compatibility engaged (not STANDALONE — downstream consumers exist).

### Forward-Compatibility Matrix

| Consumer | Requirement | Failure Mode | Verdict | Evidence |
|----------|-------------|--------------|---------|----------|
| Future `/validate-v2` runs | VPO block fillable, agent instantiable, matrix emittable | encapsulation lockout | ✅ | Step 1.5 fields at lines 45–67; Forward-Compat agent template lines 117–128; Matrix template lines 264–272 |
| Future `/validate-v2` runs | Lifecycle clarity for Outcome sentence (who produces, who echoes) | lifecycle ownership | ⚠️ | Three sections describe it without single source of truth (lines 128, 241–248, 270) — FC1 open |
| Future `/validate-v2` runs | Re-run mechanism architecturally wired | test boundary | ⚠️ | Step 4.5 describes guard + re-launch, but Step 4 output-capture path is implicit — FC2 open |
| Issue #3 touch points | Step 1.5 position established | contract drift | ✅ | Full VPO triple delivered (stronger than issue's one-sentence proposal) |
| Issue #3 touch points | Section 2 references arc position | contract drift | ✅ | Step 3 Section 2 carries VPO verbatim (line 168) |
| Issue #3 touch points | Integration & Ripple forward clause | contract drift | ✅ | Superseded: promoted to Forward-Compatibility as its own lens (row 12, line 147) |
| Synced copies | Source ↔ dist identity | shape mismatch | ✅ | `diff` clean after `./setup.sh` |
| Legacy `.vscode/validate-v2.md` | Removed or marked legacy | encapsulation lockout | ❌ LOW | File stale (~10KB vs 21KB source); no warning header — FC3 open |

**Outcome alignment**: The artifact makes forward-awareness structurally harder to skip via mandatory output slots, evidence requirements, checklists, and worked examples. Outcome is substantially advanced; two minor ambiguities (FC1 outcome-echo ownership, FC2 re-run orchestration) do not undermine the core achievement.

**Standalone?**: No — three downstream consumers named with concrete needs.

**Fixes applied (HIGH)**:
- A1: Plan-tree traversal canonical rule made explicit with 6-step strict resolution order (alphabetically-first tiebreak, cost-contained to N+1 only).

**Open (MEDIUM/LOW — user decision)**:
- FC1 (MEDIUM) — Outcome-echo ownership: single authoritative line needed.
- FC2 (MEDIUM) — Re-run orchestration: make data flow from Step 4 into 4.5 explicit.
- FC3 (LOW) — Legacy `.vscode/validate-v2.md`: delete or header-mark.

**Overall**: ⚠️ VALIDATED WITH FIXES — ready for dogfooding; open items are tightening passes, not blockers.


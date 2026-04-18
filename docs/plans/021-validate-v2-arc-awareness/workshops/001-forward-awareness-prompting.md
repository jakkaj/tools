# Workshop: Prompting validate-v2 for Forward-Awareness

**Type**: Prompt Pattern Design (Integration Pattern)
**Plan**: 021-validate-v2-arc-awareness
**Issue**: [#3 — validate-v2: add 'position in the arc' context step](https://github.com/jakkaj/tools/issues/3)
**Artifact under design**: `agents/v2-commands/validate-v2.md`
**Created**: 2026-04-18
**Status**: Draft

**Related Documents**:
- Current validator: `agents/v2-commands/validate-v2.md`
- Originating miss: Plan 083-md-editor Phase 2 dossier — Tiptap `editor` encapsulation lockout surfaced by a didyouknow-v2 pass. **Note: this plan lives in a separate substrate, not in this repo's `docs/plans/`. It is cited illustratively; paths and line numbers in the worked example (§7) are representative, not verifiable against this repo.**

---

## Purpose

Workshop the **prompting approach** for issue #3 before we implement it. The issue proposes three light-touch edits to validate-v2 (a one-sentence Step 1.5, a Section 2 mention, a lens-row clause). This workshop argues that light-touch is too weak for the failure mode the issue is trying to catch, and designs a stronger structure that makes forward-awareness **structurally unskippable** rather than a soft instruction the LLM can rubber-stamp.

The user's four framing concerns are the scaffolding for the design:
1. **Vector** — direction of travel (upstream → this → downstream → outcome)
2. **Position** — where this specific artifact sits, concretely, in that vector
3. **Final outcomes** — the product/user value the whole chain serves
4. **How we ensure it** — mechanisms that make the validator actually *do* forward-awareness, not just acknowledge it

## Key Questions Addressed

- Why does a soft "consider forward impact" instruction fail to catch misses like Phase 1's `editor` lockout?
- How do we structure the prompt so forward-awareness is evidence-grounded, not vibes-based?
- Where should forward-awareness live in the lens taxonomy — a modified row, a new lens, or a new agent?
- What output format makes omission visible rather than silent?
- How do we keep the skill **general** (spec / plan / tasks / code / workshop) while hardening this one angle?
- What mechanisms (beyond prompt text) ensure the validator behaves correctly during a real run?

---

## 1. Diagnosis — why the issue's current proposal is too weak

The issue's three touch points are directionally right but insufficient against three well-known prompt-engineering failure patterns:

### 1.1 Soft meta-instructions get acknowledged and ignored

When you tell an LLM "MUST include forward-looking checks", the default behaviour is: mention forward-looking considerations in the reasoning, produce a perfunctory "forward-compatible" sentence, and emit normal output. This is **surface compliance with meta-instructions** — well-documented in the prompt-engineering literature and visible in our own agent transcripts.

A single-sentence "position in the arc" fed into Section 2 is precisely the shape of instruction that triggers surface compliance. The validator will say "Phase 1 enables Phase 2" without investigating whether it actually does.

### 1.2 No output structure → no audit trail

The existing validator's output format (Section 6) has no forward-awareness block. If the agent skips the forward check, nothing downstream flags it. Compare: the Validation Record *does* enforce a lens-coverage table, and as a result lens coverage is reliably filled in.

**Rule of thumb**: if you want an LLM to do a thing, give it a required output slot for that thing. A missing slot is visible; a skipped instruction is not.

### 1.3 The "standalone" off-ramp is too wide

The issue says "skip forward-awareness for standalone artifacts". The LLM will discover that almost every artifact could be framed as standalone if squinted at. Whatever default we pick, the validator will bias toward — so the default must be *engage*, and the skip must require explicit evidence.

---

## 2. Core model: the VPO triple

The user's framing collapses neatly into three named components. Every artifact under validation has a **Vector–Position–Outcome triple**, and the validator's first job is to establish it concretely before running any lens.

### 2.1 Vector (the chain, by name)

The chain of artifacts this one is part of — *named*, not metaphorical.

```
Upstream artifact  →  THIS artifact  →  Downstream consumers  →  Final outcome
     (file)                                 (file / phase / contract)     (user value)
```

Vector establishment is **evidence-gathered**, not narrative. Writing "Phase 1 enables Phase 2's toolbar" is too loose. The required form names the upstream file, the downstream consumer by identifier, and the *specific* need each consumer has from this artifact.

### 2.2 Position (the outgoing contract)

What *this* artifact exports to the future. Split explicitly into:
- **Public contract** — types, functions, files, invariants downstream work can depend on
- **Intentionally private** — what's inside the box and should stay there
- **Accidental position** — things exposed as a side effect that consumers might depend on (risk surface)

This forces the validator to articulate the *frontier* between "this artifact" and "the future", which is exactly the surface forward-checks operate on.

### 2.3 Outcome (the North Star)

The final product/user value the chain serves — pulled verbatim from the spec's "why this matters" section (or equivalent). Quoted, not paraphrased.

The outcome matters because an artifact can satisfy its immediate downstream consumer but still **drift from the product goal** if the whole chain has wandered. Without the outcome echo, the validator optimises for local correctness and misses scope drift.

### 2.4 Why this framing works

VPO gives the prompt three concrete, unambiguous things to establish before judging:
- Vector is auditable (file paths / phase IDs / consumer names)
- Position is enumerable (list exports, list privates)
- Outcome is quotable (string lifted from spec)

None of the three can be satisfied with vibes. A validator that tries to rubber-stamp VPO will fail the evidence requirements visibly.

---

## 3. The prompt pattern — four structural moves

Four concrete changes to `validate-v2.md` that together make forward-awareness unskippable.

### 3.1 Move 1 — Replace "Step 1.5 one sentence" with an evidence-gathered VPO block

**Before** (issue's proposal, paraphrased):

> Write one sentence capturing this position — it feeds every agent's Context section.

**After**:

> **Step 1.5 — Establish the VPO Triple (mandatory before agent design)**
>
> Gather evidence before writing. Fill every field, or mark with a typed skip reason.
>
> **VECTOR**
> - Upstream artifact: `<file path>` — or `ORIGIN` if this starts the chain
> - Upstream's promise we inherit: `<specific requirement quoted from upstream>`
> - Downstream consumers (enumerate by identifier, not vibes):
>   - `<phase/file/contract id>` — needs: `<specific requirement from us>`
>   - `<phase/file/contract id>` — needs: `<specific requirement from us>`
> - If no concrete downstream exists in the plan tree:
>   - Search committed ADRs/specs/workshops for references to this artifact. List hits.
>   - If and only if no hits: provisionally mark vector as `STANDALONE` with evidence of the search.
>   - A provisional `STANDALONE` on the Vector is **necessary but not sufficient** to skip the Forward-Compatibility lens — §5 governs the full three-condition skip policy (downstream phase, external contract, user-value chain). All three must hold with evidence.
>
> **POSITION**
> - Public contract (enumerate): `<types, functions, files, invariants>`
> - Intentionally private: `<list>`
> - Accidental exposure risks: `<things consumers might depend on that aren't contract>`
>
> **OUTCOME**
> - Quote (verbatim) the user/product value from spec: `"<quote>"`
> - One sentence on how this artifact advances that value

**Why evidence-gathered**: "One sentence" is confabulable. "Upstream file path + downstream consumer IDs + quoted spec line" cannot be satisfied without actually reading the relevant files.

### 3.2 Move 2 — Promote forward-awareness to its own lens

Adding a forward-looking clause to the Integration & Ripple lens row dilutes it. Ripple covers many things; the forward check gets watered down.

**Add a new row** to the 11-lens table in Step 2.5:

| Lens | What it catches |
|------|----------------|
| **Forward-Compatibility** | Does this artifact's exported shape satisfy the concrete needs of each named downstream consumer? Checks against five named failure modes (see §3.3). Engaged by default; narrow skip when `STANDALONE` is proven. |

Consequences:
- It becomes part of the 7-of-12 lens coverage floor (update the threshold).
- An agent is explicitly responsible for it — it can't be silently dropped into a general "integration" bucket.
- The Validation Record's lens-coverage table will flag runs that omit it.

### 3.3 Move 3 — Replace "vibes" with a 5-mode failure-mode checklist

Forward-awareness is hand-wavy unless it names what it's looking for. Five failure modes, derived from the Phase 1/Phase 2 miss and generalised:

| Mode | Question | Worked failure |
|------|----------|----------------|
| **Encapsulation lockout** | Is anything private that a named downstream needs public? | Phase 1 keeps the Tiptap `editor` as a private field; Phase 3 toolbar needs to receive it as a prop. |
| **Shape mismatch** | Does the exported type include every field a downstream will destructure? | Exports `{ value, onChange }`; downstream phase destructures `{ value, onChange, selection }`. |
| **Lifecycle ownership** | Can a downstream sibling compose without fighting this artifact for resource ownership? | Parent owns editor lifecycle; sibling toolbar must be nested inside rather than composed beside. |
| **Contract drift** | Does the deliverable satisfy the outside contract (ADR/RFC/workshop/spec) it was meant to implement? | ADR-012 says "debounce 200ms"; implementation uses 100ms. |
| **Test boundary** | Can this artifact's testing approach be extended to cover downstream integration, or does it lock mocks/fixtures in a way that makes integration testing hard later? | Phase 1 ships heavy component mocks; Phase 3 can't assert toolbar–editor integration. |

The Forward-Compatibility agent must produce a verdict **per mode** per named consumer. "Vibes" ("looks fine going forward") is not a valid verdict.

**Why a checklist beats open-ended prompting**: checklists convert judgement into enumeration. An LLM can skip a vague instruction; it has a much harder time skipping a named row in a matrix it's required to fill in.

### 3.4 Move 4 — Required Forward-Compatibility Matrix in the output

The Validation Record (Step 6.5) gets a mandatory block. If the block is missing or has empty rows, the synthesizer must re-run the agent.

```markdown
### Forward-Compatibility Matrix (required)

| Consumer | Requirement | Failure Mode | Verdict | Evidence |
|----------|-------------|--------------|---------|----------|
| Phase 3 toolbar | public editor instance | encapsulation lockout | ❌ blocked | `MarkdownEditor.tsx:42` — `editor` kept as private field |
| Phase 5 FileViewerPanel | composable editor | lifecycle ownership | ❌ blocked | editor lifecycle tied to `MarkdownEditor` mount |
| ADR-012 | debounce 200ms | contract drift | ✅ | `saver.ts:18` — `debounce(200)` |

**Outcome alignment**: <one sentence — does this artifact, as shipped, advance the outcome quoted in VPO? If not, what's the drift?>

**Standalone?**: <Yes/No; if Yes, list the three skip-conditions with evidence>
```

The synthesizer guard (see §4.3) verifies this block's structure before emitting the final verdict.

---

## 4. Ensuring mechanisms — "how we ensure it"

Prompt structure alone isn't enough. Four execution-time mechanisms keep the validator honest.

### 4.1 E1 — Worked example in the validator's own prompt

LLMs pattern-match to examples in the prompt far more reliably than to abstract instructions. Paste the Phase 1/Phase 2 `editor` miss into `validate-v2.md` as a canonical "what good and bad forward-awareness look like" block. Keep it tight (<200 words) so it fits in context without crowding other guidance.

Minimum content:
- The artifact as shipped (offending lines)
- The downstream need (Phase 2 consumer, specific requirement)
- A **bad** check ("ship looks fine, tests pass ✅") — labelled as the historical miss
- A **good** check (VPO block filled in, Forward-Compatibility Matrix with verdict, specific fix)

One vivid example beats a thousand "MUST" statements.

### 4.2 E2 — Plan-tree traversal (grounded forward-check)

If the validated artifact lives inside a plan folder with numbered phases, the Forward-Compatibility agent **reads the next phase's tasks dossier** (if present) and verifies each "inputs" requirement against this phase's Position block.

This is the strongest possible forward-check because it's grounded in *real downstream work*, not speculation. It also short-circuits the "downstream consumers" field of VPO — if the next phase exists, its tasks dossier *is* the consumer list.

Scope limits (keep it cheap):
- Look at next phase only (not the whole tree)
- Read the dossier's inputs/prerequisites sections, not the full thing
- If next-phase dossier doesn't exist yet, fall back to spec's Workshop Opportunities / Phase Sketch

### 4.3 E3 — Synthesizer completeness guard

Before the parent emits the final Validation Record, it runs a simple structural check:
- Does the Record contain a `Forward-Compatibility Matrix` heading?
- Does the matrix have at least one row per named consumer in VPO, *or* a `STANDALONE` justification with evidence?
- Is the `Outcome alignment` sentence present and non-empty?

If any check fails: re-run the Forward-Compatibility agent with an explicit "your previous run omitted X" corrective. This is one extra agent call per run at worst, often zero.

### 4.4 E4 — Outcome echo as drift detector

Every run ends with the Outcome-alignment sentence. If the validator cannot produce one without hand-waving (generic phrases like "improves the user experience"), that signals either (a) the spec's outcome is too vague or (b) the artifact has drifted. Either way the verdict escalates to `NEEDS ATTENTION` with an explicit note to the user.

This catches the class of failure where every phase is locally correct but the chain has lost the plot — which the issue's original framing doesn't address directly.

---

## 5. Engagement policy — closing the "standalone" off-ramp

Default is **engage**. Skipping forward-awareness requires *all three* conditions with evidence:

1. No downstream phase exists in the plan tree (checked via directory listing)
2. No external contract in committed files names this artifact (checked via grep across `docs/adr/`, `docs/specs/`, `docs/plans/*/workshops/`, and any committed RFC-style files). **Open GitHub issues are NOT part of the automated check** — validators are read-only and lack `gh` CLI. If an open issue might apply, escalate to the user for manual confirmation rather than rubber-stamping a skip.
3. No user-value chain segment depends on this artifact's shape (asserted by the validator with reasoning grounded in the spec's "why this matters" section)

If any is false: forward-awareness is mandatory.

Standalone verdicts **must include the evidence of each of the three checks**. "It looks standalone to me" is not a valid skip.

---

## 6. Revising the three issue touch points

Issue #3's three touch points remain the right scaffolding. The workshop replaces their contents.

| Issue's proposal | Workshop's revision |
|------------------|---------------------|
| **1. Step 1.5 — one sentence position** | **Step 1.5 — full VPO triple with evidence fields (§3.1).** Named upstream file, named downstream consumers with specific requirements, quoted outcome from spec. |
| **2. Section 2 — reference arc position** | **Section 2 — carry the full VPO block verbatim.** Each agent reads it; each agent must reference the relevant VPO component in its output (Forward-Compat agent most heavily). |
| **3. Integration & Ripple — add forward clause** | **Promote to new lens: Forward-Compatibility (§3.2).** Separate row in the 11-lens table; separate agent slot; 5 named failure modes (§3.3); required output matrix (§3.4). |

Plus the three additions the issue didn't include:
- **Worked example** in the validator prompt (§4.1)
- **Plan-tree traversal** mechanism (§4.2)
- **Synthesizer completeness guard** (§4.3)
- **Outcome echo** as final-verdict line (§4.4)
- **Narrow engagement policy** (§5)

---

## 7. Worked example — Phase 1 `editor` encapsulation

This is the example that should land in `validate-v2.md` itself (§4.1).

**Artifact under review**: Plan 083-md-editor, Phase 1 `MarkdownEditor` component.

> *Illustrative example — Plan 083 lives outside this repo. Code and line references below are representative of the real miss, not repo-verifiable.*

**As shipped** (abbreviated):
```tsx
// MarkdownEditor.tsx
export function MarkdownEditor({ value, onChange }: Props) {
  const editor = useEditor({ /* Tiptap config */ });  // PRIVATE — closed over
  return <EditorContent editor={editor} />;
}
```

### Bad check (what the original 3 validators produced)

> Source Truth: file exists, imports resolve, types match spec. ✅
> Cross-Reference: Plan Phase 1 says "ship MarkdownEditor"; dossier matches. ✅
> Completeness: tests cover render, onChange, disabled state. ✅
>
> Verdict: ✅ VALIDATED.

Nothing is wrong with any individual check. The problem is the shape of what was *not* asked.

### Good check (VPO + Forward-Compatibility Matrix)

**VPO**
- Vector upstream: `083-md-editor-spec.md` — promise: "A markdown editor primitive Phases 2–5 compose with."
- Vector downstream:
  - Phase 2 tasks dossier `tasks.md` — needs: public `editor` instance to wire toolbar
  - Phase 5 workshop `§15.3` — needs: composable editor for FileViewerPanel
- Vector outcome (from spec): *"Authors can edit, format, and link markdown inline without leaving the viewer."*
- Position — public contract: `{ value, onChange }` prop interface; `<MarkdownEditor>` component export.
- Position — intentionally private: internal selection state.
- Position — accidental exposure: none identified.

**Forward-Compatibility Matrix**

| Consumer | Requirement | Mode | Verdict | Evidence |
|----------|-------------|------|---------|----------|
| Phase 2 toolbar | public `editor` instance | encapsulation lockout | ❌ BLOCKED | `MarkdownEditor.tsx:12` — `editor` closed over, not exported via ref, prop, or context |
| Phase 5 FileViewerPanel | composable editor | lifecycle ownership | ❌ BLOCKED | editor lifecycle tied to MarkdownEditor mount; sibling can't share instance |

**Outcome alignment**: Not yet — Phase 1 ships a primitive that will require refactor before Phase 2/5 can consume it, so the outcome ("inline editing") is not advanced on the current trajectory.

**Verdict**: ❌ NEEDS ATTENTION. Phase 1 is locally correct but blocks Phase 2 and 5. Fix: expose editor via `forwardRef` OR via an `editor` context OR hoist editor state to a parent hook that Phase 2/5 can also consume. Recommend the `forwardRef` route — smallest API surface change.

### 7.1 Mini-examples for the remaining three modes

The §7 walkthrough above exercises **encapsulation lockout** and **lifecycle ownership**. The remaining three failure modes deserve their own vivid anchors so the LLM has a pattern for each. Keep these short; they ship in the validator prompt alongside the main example.

**Shape mismatch** — illustrative

> Phase 1 ships `useDocumentState(): { value, onChange }`. Phase 3's autosave hook destructures `{ value, onChange, selection, isDirty }` per the workshop § 4.2 contract. The matrix row: *Phase 3 autosave → needs `selection, isDirty` → **shape mismatch** → ❌ → fix: extend the hook's return type, update Phase 1 tests, re-export from the public index.*

**Contract drift** — illustrative

> ADR-012 mandates 200ms debounce on save. Phase 1 ships `debounce(100)` because a developer measured typing feel locally. The matrix row: *ADR-012 → requires 200ms → **contract drift** → ❌ → fix: set `DEBOUNCE_MS = 200` from the ADR, add a link in the source file back to the ADR.*

**Test boundary** — illustrative

> Phase 1's tests mock the Tiptap editor wholesale with a `createMockEditor()` double. Phase 3 wants to assert toolbar-editor integration end-to-end. The matrix row: *Phase 3 integration tests → need real editor wiring → **test boundary** → ❌ → fix: split test utilities into `unit-mocks.ts` (kept) and `integration-real.tsx` (new), and document the boundary in `TESTING.md`.*

The point is not that any particular Phase 1/2/3 is correct — it's that the validator's prompt carries one vivid anchor per mode so pattern-matching happens uniformly.

---

## 8. Open questions

### Q1: Which agent owns Forward-Compatibility?

**OPEN** — three options:
- (a) **New 4th agent** dedicated to Forward-Compatibility. Strongest isolation; costs one extra agent per run.
- (b) **Attach to Cross-Reference agent**. Natural fit (both do "does X match Y?"). Risks diluting the lens.
- (c) **Attach to Completeness agent**. Natural fit if framed as "are we complete with respect to downstream needs?". Also dilution risk.

**Recommendation** (draft): (a) for broad scope, (b) for narrow scope. Decide during ADR.

### Q2: How aggressive is plan-tree traversal?

**OPEN** — trade-off between depth and cost.
- Next-phase only: cheap, catches the immediate miss (recommended default)
- Next-two-phases: catches transitive misses; doubles IO
- Full downstream tree: thorough, potentially slow on large plans

**Recommendation** (draft): next-phase only by default; `--deep` flag to escalate.

### Q3: Does this apply uniformly across artifact categories?

**OPEN** — the five failure modes fit tasks-dossier and code-change validation cleanly. Spec-level validation may need a different mode set (e.g., "does this spec answer the questions the plan will ask?"). Workshop validation may need another.

**Recommendation** (draft): keep the five modes as a baseline; allow per-category extensions in a future workshop.

### Q4: Backport to validate-v1 lite?

**OPEN** — v1 lite has a different lens taxonomy. Probably skip initially; revisit after dogfooding v2.

---

## 9. Acceptance criteria (for the implementation phase that follows this workshop)

- [ ] `agents/v2-commands/validate-v2.md` Step 1.5 replaced with the full VPO block (§3.1)
- [ ] 11-lens table expanded to 12 with Forward-Compatibility as its own row (§3.2)
- [ ] Coverage threshold updated from 7-of-11 to 8-of-12 (or equivalent fraction)
- [ ] 5 failure modes documented as an agent-facing checklist (§3.3)
- [ ] Validation Record template includes required Forward-Compatibility Matrix (§3.4)
- [ ] Outcome-alignment sentence required in the final verdict (§4.4)
- [ ] Worked example (Phase 1 `editor` miss) included in the prompt (§4.1)
- [ ] Plan-tree traversal described in Step 3 execution guidance (§4.2)
- [ ] Synthesizer completeness guard documented in Step 5 (§4.3)
- [ ] Engagement policy with three-condition skip documented (§5)
- [ ] Single source of truth edited: `agents/v2-commands/validate-v2.md` — no other copies touched directly
- [ ] `./setup.sh` runs cleanly, mirroring to `src/jk_tools/agents/v2-commands/validate-v2.md` and reinstalling to `~/.claude/commands/validate-v2.md` (and the OpenCode/Codex/GHCP equivalents)
- [ ] Installed copy diff matches edits after rerun
- [ ] Legacy `.vscode/validate-v2.md` (not part of the sync-to-dist pipeline) either removed or left with an explicit "legacy, do not edit" note — do not sync it from source
- [ ] Dogfooded against a real artifact (ideally re-run on the original Phase 1/Phase 2 miss) — the matrix catches the encapsulation lockout

---

## 10. Quick reference — the prompt shape at a glance

```
Step 1  — Detect What Was Just Done
Step 1.5 — Establish VPO Triple
              Vector (upstream, downstream consumers with named needs)
              Position (public contract, private, accidental)
              Outcome (quoted from spec)
Step 2  — Design Agents (includes Forward-Compatibility agent / lens owner)
Step 2.5 — Lens Coverage ≥ 8-of-12; Forward-Compatibility is one of the 12
Step 3  — Launch agents in parallel; Forward-Compat agent traverses plan tree
Step 4  — Collect results
Step 5  — Synthesize; synthesizer completeness guard re-runs if Matrix missing
Step 6  — Verdict includes Outcome-alignment sentence
Step 6.5 — Validation Record includes Forward-Compatibility Matrix
```

**The core discipline** — evidence over vibes, output slots over instructions, engagement by default, outcome echo as drift detector.

---

## Validation Record (2026-04-18)

Validated via `/validate-v2` on draft. Meta note: run against the *old* validator, intentionally — if the old validator rubber-stamps a workshop arguing it rubber-stamps things, that's itself corroborating evidence. In practice it caught several real issues.

| Agent | Lenses Covered | Issues | Verdict |
|-------|---------------|--------|---------|
| Factual Accuracy | Factual Accuracy, Hidden Assumptions, Concept Documentation | 1 CRITICAL fixed | ✅ |
| Design Coherence | UX, Integration & Ripple, Hidden Assumptions, Edge Cases | 2 HIGH fixed, 4 MEDIUM/LOW open | ⚠️ |
| Implementability | Technical Constraints, Edge Cases, Deployment & Ops | 2 HIGH fixed, 2 MEDIUM open | ⚠️ |

**Lens coverage**: 8/11 (above the 7-floor).

**Fixes applied (CRITICAL + HIGH)**:
- Plan 083 honestly framed as external-substrate / illustrative (header + §7)
- §3.1 cross-references §5's three-condition skip policy
- §5 drops "open issues" from automated check; escalates to manual review instead
- §7.1 adds mini-examples for the three failure modes not exercised by the main worked example
- §9 AC rewritten around the actual sync pipeline; legacy `.vscode/` copy handled

**Open issues (MEDIUM/LOW — decide before implementing)**:
- DC3 — outcome-echo sequencing across §3.1/§3.4/§4.4 (produced once and echoed, or twice?)
- DC4 — two "skip" concepts (field-level vs lens-level) not cleanly distinguished
- DC5 — §3.4 and §4.3 describe the same re-run mechanism redundantly
- I3 — §4.3 re-run mechanism has no architectural path in current validate-v2 Steps 4–5; needs an explicit re-run flow before implementing
- I4 — §4.2 plan-tree traversal needs a canonical folder-convention rule for "next phase"
- DC6 — "8-of-12 or equivalent fraction" should be a hard floor

**Overall**: ⚠️ VALIDATED WITH FIXES — ready for clarification pass before implementation.


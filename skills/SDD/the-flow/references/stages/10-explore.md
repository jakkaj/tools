# explore

> Sub-skill — part of a verb library. Knows nothing about any flow:
> no stage ids, no successor/predecessor names, no flow commands.
> Composition is the bundling flow's job.

**Verb**: explore
**Purpose**: Answer *how existing functionality works* and produce evidence suitable for planning — a compact, history-aware research dossier (or console-only report). **Minimum-sufficient by design**: start cheap, climb only when evidence demands it.
**Consumes**: a research query. No prior artifacts required — auto-detects plan context (ordinal branch / cwd / conversation) or creates a new plan folder; `--console` creates nothing. Optional context: an existing `docs/plans/<ordinal>-<slug>/`, institutional memory (prior plans, tasks, execution logs, workshops, ADRs, reviews, retros), `docs/domains/registry.md`, FlowSpace MCP when available.
**Flags**: `"research query"` · `--plan <name>` (explicit plan folder) · `--console` (console-only output)
**Produces**: `docs/plans/<ordinal>-<slug>/research-dossier.md` — a **decision packet** (§ Dossier contract), not a transcript — or a console-only report with `--console`. Read-only; STOPs and waits after output.
**Side effects**: none (read-only research; STOPs and waits after output)

---

## Governing rule

> **Always search institutional memory cheaply. Read it deeply only when relevance, risk, contradiction, or unresolved uncertainty earns the cost.**

Every token, worker, file read, finding, and dossier line must earn its place — change a decision, constrain an implementation, prove a behaviour, expose a risk, record evidence, preserve intent, or enable the next action — else cut it (the seven-function line test + doctrine: `references/00-routing.md` § Shared conventions). The dossier is **output**: research broadly *internally*; emit only decision-relevant findings as tables with evidence links — link, don't restate. **No finding quotas, no fixed worker roster** — fan-out follows the independent questions left after a cheap scout, never a standing count.

**Authority**: live code is authoritative for *current behaviour*. Historical artifacts are authoritative for *recorded decisions* only when the repo designates them so (an applicable ADR, an authoritative workshop); other prior plans and retros explain intent, friction, rejected approaches, proven workarounds, and risks — they never silently override current code.

```md
$ARGUMENTS
# Argument forms (flags are this verb's own — the flow renders the full command):
#   "research query"                 → auto-detect plan context, or create one
#   --plan <name> "research query"   → explicit plan folder
#   --console "research query"        → console only, no files
# e.g.  "how does the search service work?"   ·   --console "quick error-handling question"
```

## Minimum-sufficient research ladder

Begin at the lowest rung; climb only when evidence requires it. Workers are *added for independent questions*, never to hit a number.

| Rung | Work | Normal workers | Stop when |
|---|---|---:|---|
| 0 | Decide whether repo research is needed at all | 0 | The query is already answerable from supplied context |
| 1 | Targeted symbol/path/text search + direct reads | 0 | The question has a supported answer |
| 2 | Trace one execution path + its contracts/tests | 0–1 | Current behaviour and the change surface are clear |
| 3 | Add institutional-memory / risk analysis | 1–2 total | Relevant prior friction and hazards are understood |
| 4 | Add one independent boundary / history / verification investigation | 2–3 total | Cross-cutting uncertainty is resolved |
| 5 | Broad audit | evidence-driven | Only for an explicit comprehensive/audit/deep request or substantial exposed uncertainty |

No new public depth flag. Treat explicit query wording (`comprehensive`, `audit`, `deep`, `migration`, `security`, `cross-cutting architecture`) as a signal to *consider* the broad rung — even then, follow the questions, not a roster.

---

## Algorithm

### 1) Resolve input + output (a contract, not pseudo-code)

- Parse the query and `--plan` / `--console`.
- **Reuse an existing plan folder before minting one**: explicit `--plan` (path, `NNN-slug`, or bare slug → match existing `docs/plans/*-<slug>/` first) → ordinal git branch (`NNN-…`) → cwd inside `docs/plans/NNN-*/` → a plan named recently in conversation → else create one.
- New folder: next ordinal via `plan-ordinal` (alias `jk-po`); fall back honestly to a local `docs/plans/` scan, noting the collision risk.
- `--console`: create nothing — no folder, no file.
- Fail clearly on: missing query; an explicit `--plan` that names a non-existent `NNN-` folder; an irreducibly ambiguous target.
- No routine detection chatter unless it changes user action.

### 2) Probe tools once

One cheap FlowSpace availability call. If present, use its core operations (`tree`, `search` text/regex/semantic, `get_node`) as appropriate; if absent or it fails mid-run, fall back to standard search/glob/read and note the degradation **only if it affects confidence**. Describe **one** research protocol — tool choice is an implementation detail inside each investigation; do **not** duplicate worker prompts per tool, probe every API with min/max arguments, enumerate hypothetical capabilities, or print install/setup marketing on a successful standard run.

### 3) Cheap dual-lane scout (the lead does both, before deciding on workers)

**Live-code lane** — discover only enough to *frame* the question: repo shape relevant to the query; query terms / named symbols / paths / APIs / events / commands / schemas / config; likely entry points; one likely execution path; nearby tests and contracts; touched domains or boundaries (load domain context per `references/00-routing.md` § Domain context loading when relevant). Prefer deterministic search + direct reads — don't read broadly just to fill categories.

**Institutional-memory lane** — always run a *cheap* historical lookup; these repos deliberately retain implementation memory. Candidate sources:

- `docs/plans/*/*-plan.md` · `docs/plans/*/tasks/*/tasks.md` · `docs/plans/*/tasks/*/execution.log.md`
- `docs/plans/**/reviews/*.md` · `docs/plans/*/workshops/*.md` · `docs/adr/*.md`
- `docs/harness/agents/**/*.retro.md` · `docs/retros/*.md` *(read-only frozen history — never a live loop this verb drives or writes)*

Build the history query from the original intent **plus** terms discovered in live code (exact symbols/paths, domain/contract names, libraries/protocols/storage/services, failure modes, the plan id when known). Rank candidates: ① exact symbol/path overlap → ② same contract/domain/API/schema/failure-mode → ③ same technology+operation → ④ strong topic similarity → ⑤ unresolved/encoded/proven learning status → ⑥ recency as a tie-breaker only (**no** hard 30-day cutoff — old evidence about the same contract beats recent unrelated evidence).

Read **at most the three strongest** historical artifacts initially. Expand only when: an important claim lacks support; current code conflicts with a prior decision/workaround; a high-risk issue is still unresolved; a candidate points to another source needed to understand the resolution; or the query explicitly asks for historical evolution. Classify each retained item — **Direct** (same active symbol/path/contract/failure-mode) · **Partial** (rationale still useful, implementation evolved) · **Superseded** (history, not a current requirement) · **Unclear** (needs verification). A no-match result is valid: `no_material_historical_evidence` — do **not** manufacture a history section or report scan trivia.

### 4) Classify scope

Name the smallest set of unanswered **material** questions (e.g. current execution path? constraining contracts/consumers? what proves the behaviour? which prior friction still applies? which boundary is crossed? is an apparent contradiction real?). Pick effort: **Quick** (lead only) · **Standard** (1–2 workers) · **Deep** (2–3 workers) · **Audit** (broad, evidence-driven). Record the chosen effort in the dossier — the label *describes* what was done; it is never a quota.

### 5) Add workers only for independent uncertainty

Default responsibilities (use only those a real unanswered question needs):

- **A · System Trace** — what currently happens and what constrains it: entry point + execution flow, key data/state transforms, dependencies + consumers, interfaces/contracts, tests + quality evidence, applicable domain boundaries.
- **B · Institutional Memory & Risk** — what was learned before and what could break: relevant plans, execution discoveries, retros, ADRs, workshops, reviews, selective git history; prior failures, workarounds, decisions, rejected paths, unresolved debt; applicability to current code; modification hazards and contradictions.
- **C · Independent Verification / Boundary** — add **only** when the scout exposes a genuinely separate question (a cross-domain boundary, a security-sensitive contract, migration history, a disputed interpretation).

Run workers in parallel **only** when their questions are independent — never just to cut wall-clock if they'd reread the same files. Give each a focused packet: the exact question; candidate symbols/paths; domain context; selected historical candidates; the questions it owns; exclusions to prevent overlap — never a transcript of everything discovered.

**Worker return contract** — each worker returns **no more than five material findings** (a ceiling, never a target):

```text
claim
kind:        current | contract | test | historical | risk | boundary
source:      exact path:line, symbol/node, or artifact#section
implication: why this changes understanding or planning
confidence:  high | medium | low
open_question: optional
```

Rules: no intro/summary, no repeated repo context, no code excerpt unless the exact code *is* the evidence, no external-research brainstorming unless the assigned question proves the repo can't answer something material. No material finding → `no_material_findings` and stop. Worker failure → a targeted retry of that gap or an explicit unknown, **never** a raw-output dump.

### 6) Sufficiency gate (after every round)

Stop when **all** hold: ① the user's actual question has a clear answer; ② every material claim has exact evidence; ③ relevant current contracts/consumers/tests are checked to the degree the question requires; ④ the cheap history lookup ran and any materially relevant history was assessed for current applicability; ⑤ contradictions, change hazards, and confidence limits are explicit; ⑥ remaining unknowns are named; ⑦ another search is unlikely to change a planning or risk decision. **Never** stop on agent count, files read, elapsed work, or a finding target.

### 7) Detect external research once, during synthesis

Emit an external-research opportunity only when repo evidence cannot answer a material question, the answer depends on current standards / regulations / security guidance / library behaviour / comparative technology, and resolving it could change the plan. Normally zero to three; each needs the unanswered question, why repo evidence is insufficient, the code/history that exposed it, the planning impact, and a focused ready-to-use prompt. No generic "best practices" prompts; do not repeat this detection per worker.

---

## Dossier contract

A decision packet — not a transcript or a repo inventory. **Required**: header, Answer, Evidence, Planning Handoff. Every other section is **conditional — omit it entirely when empty** (no "none found" filler, no empty headings).

```markdown
# Research Dossier: <topic>

**Generated**: <ISO timestamp>
**Query**: "<verbatim query>"
**Effort**: Quick | Standard | Deep | Audit
**Tools**: FlowSpace | Standard | Mixed
**Evidence**: <N current sources> · <N historical sources>

## Answer

<The fewest statements that explain current behaviour and what it implies for the ask — usually 3–7. Only what's needed.>

## Evidence

| ID | Finding | Evidence | Planning implication | Confidence |
|----|---------|----------|----------------------|------------|
| F-01 | <claim> | `<path:line>` | <why it matters> | High |

## Historical Evidence
_Omit when no material history was found._

| ID | Prior friction / decision | Source | Applicability now | Implication |
|----|---------------------------|--------|-------------------|-------------|
| H-01 | <learning> | `<artifact#section>` | Direct / Partial / Superseded / Unclear | <action or caution> |

## Risks and Unknowns
_Omit when empty._

| Item | Evidence | Why it matters | Resolution / next evidence |
|------|----------|----------------|----------------------------|

## Domain Impact
_Omit when the query has no material domain consequence._

| Domain / boundary | Relationship | Contract or constraint | Evidence |
|-------------------|--------------|------------------------|----------|

## Planning Handoff

- **Preserve**: <current contracts, invariants, or proven patterns>
- **Change carefully**: <hazardous areas and why>
- **Likely files/symbols**: <only the implementation surface supported by evidence>
- **Decisions still required**: <only unresolved choices>

## External Research
_Omit when none is material._

| Question | Why repo evidence is insufficient | Planning impact | Prompt |
|----------|-----------------------------------|-----------------|--------|
```

**Dossier rules**:

- One evidence table — a finding appears **once** (F-NN); other sections reference its ID, never restate it.
- Every material claim cites an exact source (`path:line`, symbol/node, or `artifact#section`). Link to detail; don't reproduce it.
- No routine "business purpose" unless directly evidenced and needed to answer the query.
- Don't claim test percentages unless measured; don't infer High/Medium/Low complexity without an explicit useful basis.
- **Preserve all Critical/High risks and unresolved contradictions without compression** — the safety floor is never default-omitted.
- A full dossier normally runs ~5–12 material evidence rows — an *observation*, never a target or cap. Correctness sets the length.

### Output

- **`--console`**: print the same compact contract to the console; create no folder and no file.
- **File mode**: write `research-dossier.md` to the resolved plan folder, then print only an output-contract summary:

  ```text
  ✅ <path>/research-dossier.md — <N> findings, <H> material historical learnings, <R> high risks, <U> open questions
  ```

  Add one short degradation line only if a tool failure materially reduced confidence. Do **not** re-summarize the dossier in the terminal.

---

## STOP — read-only

This verb is read-only. After output: no code changes, no further files, no implementation, no next-step naming. The research is done — **STOP and wait** for the user.

## Consumer (via the artifact — the wire protocol)

The **plan** verb reads `research-dossier.md` fully when present: its Answer, Evidence, Historical Evidence, Risks, Domain Impact, and Planning Handoff inform complexity, domains, constraints, and question framing. Unresolved External Research rows travel with the dossier. The dossier is the whole interface — no other coupling.

## Exit

Print the output-contract summary (the `✅` line: what was produced, where, key counts). Then STOP. Do not name a next stage. If invoked standalone, end with exactly: "Routing is the flow's job — run the parent flow bare to continue."

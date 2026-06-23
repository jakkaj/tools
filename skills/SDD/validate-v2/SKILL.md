---
name: validate-v2
description: Adaptive, high-signal post-action validation for whatever was just produced — unified plan, tasks, code change, workshop, legacy spec, or any artifact. Proves the claims that matter, reports only findings likely to change action, and adds independent critics only when risk or uncertainty earns them. Thesis- and consumer-aware; read-only through adjudication; compact verdict.
---

# validate-v2

**Adaptive, high-signal validation** of whatever was just produced — a unified plan, tasks dossier, code change, workshop, legacy spec, or any artifact.

> **Prove the claims that matter, report only findings likely to change action, and spend extra review agents only when risk or uncertainty earns them.**

Optimise for precision and trust first; raise recall without turning every artifact into a four-agent audit. The validator judges whether the artifact **serves its reason for existing** — locally correct work that does not advance its purpose still fails. It is **read-only through adjudication**; only mechanical, evidence-pinned document repair may follow.

```md
User input:

$ARGUMENTS
# No flags → ADAPTIVE: lead + deterministic proof, one independent critic only for nontrivial work.
# --artifact <path>   validate this file/diff (overrides conversational inference)
# --scope narrow      lead + deterministic checks; at most one critic
# --scope broad       lead + up to three independent critics, one per DISTINCT risk
```

The **lead** (you) owns target detection, contract derivation, commands, history ranking, routing, adjudication, repair authorization, the verdict, and persistence. Workers only *propose* findings — their formatting never establishes truth.

## Pipeline

```text
resolve target + revision → one compact Validation Contract → deterministic proof + cheap history
→ risk-triggered lenses → lead review + critic(s) when useful → verify & disprove every finding
→ +1 specialist only for an unresolved independent risk → compact verdict
→ safe doc repair + targeted re-check (when eligible) → compact sidecar record (when appropriate)
```

Load a reference **only when the target needs it**:
- `references/artifact-checks.md` — per-type deterministic checks (unified plan, legacy spec, tasks, code, workshop, general).
- `references/contract-and-forward-compatibility.md` — proof levels, authority order, history labels, the five compatibility modes, next-phase traversal.
- `references/record-template.md` — sidecar placement + template.
- `references/examples.md` — worked thesis / forward-compatibility examples.

## 1 — Resolve target + boundary

Pick the target in this order: explicit `--artifact` → unambiguous last-produced artifact → current plan/phase output → current git diff (code) → **ask only when no safe target can be inferred**.

- **Code**: establish a concrete `base..head` range or the staged/unstaged boundary.
- **Documents**: identify the target and its nearest authoritative upstream artifacts.

Classify from **content and path**, never from a stage name. The unified planning doc is one `<slug>-plan.md` carrying `## Business Specification` + `## Implementation Plan`; recognise a legacy split `*-spec.md` / `*-plan.md` only as a compatibility case. Per-type checks: `references/artifact-checks.md`.

## 2 — Build one Validation Contract

Derive this **once**, from the user ask and nearest authoritative sources, before any broad search. Roughly 8–12 evidence-bearing lines. Mark inference once; allow `N/A` for fields that genuinely don't apply. Pass each worker only the fields its question needs — **never copy the whole contract into every prompt**.

### Validation Contract
- **Purpose / outcome**: <why this exists + the quoted user/product value>
- **Promise**: <what this artifact must make true for its beneficiary>
- **Proof target**: Orientation | Decision | Contract | Implementation | Integration | Validated Evidence
- **Proof required**: <tests, source match, schemas, examples, traces, commands>
- **Upstream**: <path/id + inherited requirement, or ORIGIN>
- **Consumers**: <named downstream ids + exact needs, or none found>
- **Position**: <public contract/invariants this artifact exposes>
- **Constraints / non-goals**: <only material boundaries>
- **Sources**: <paths/sections used to derive this>

Missing **Purpose/Promise** that prevents judgment is **one HIGH finding** — never invent intent to fill it. This carries thesis + Vector/Position/Outcome semantics without repeated essays. (Proof-level definitions + authority order: `references/contract-and-forward-compatibility.md`.)

## 3 — Gather proof before critique

Select deterministic checks **from the artifact's own claims** — not a ceremonial fixed suite.

- **Docs/plans**: paths, symbols, line refs, requirement/task/AC ids resolve; counts and dependency edges match their sources; required status/gate structures are valid; schemas/examples/commands/contracts match current source; **consume existing G1–G7 results — don't reimplement them**.
- **Code**: read the full diff + relevant unchanged dependencies; run targeted tests / typecheck / lint / build / schema-validation / repro commands when available and **read exit status + material output yourself**; inspect named consumers and changed public contracts; repo-wide search only when the change surface warrants it.

A linter passing does not prove tests pass. **A worker saying a command passed is not proof** unless the lead read the fresh output.

## 4 — Institutional memory (cheap lane)

On every nontrivial repository validation, run **one targeted** history lookup keyed on: target path + plan id; changed symbols/contracts/domains/files; requirement/AC ids; technologies/migrations/failure-modes/operations; named consumers.

Search likely dossiers, plans, tasks, execution logs, workshops, ADRs, reviews, retros, and relevant git history. **Read only the strongest candidates first**; deepen only when history can change the expected contract, expose a known failure, preserve a constraint, explain an odd design, or show a proposed fix failed before.

Label retained history **Authoritative / Applicable / Partial / Superseded / Unclear** (definitions: `references/contract-and-forward-compatibility.md`). `no_material_historical_evidence` is a valid result — never manufacture a history section. Fresh proof and current code outrank historical prose for present behaviour; superseded history explains, it never silently overrides.

## 5 — Risk-triggered lenses (no quotas)

Every run answers exactly three base questions:
1. Does the artifact fulfil its **Promise / Purpose**?
2. Is the **claimed proof level** supported by fresh evidence?
3. Does its **Position** satisfy named consumers and current contracts?

Add a lens **only on evidence in the target**:

| Trigger in the target | Lens | Question |
|---|---|---|
| auth, permissions, secrets, untrusted input | Security & Privacy | Can this expose or bypass a protected boundary? |
| schema, persistence, migration, destructive write | Data & Migration | Is state compatible, recoverable, rollback-safe? |
| async, shared state, locks, retries, hot path | Concurrency & Performance | Can ordering / scale / retry / ownership break the claim? |
| env vars, CI, deployment, config, flags | Operations | Can it deploy, observe, and roll back under the contract? |
| shared types, public API, imports, domain registry | Contract & Domain | Are consumers and dependency direction preserved? |
| user journey, accessibility, interaction/state | User Experience | Does observed behaviour advance the outcome without regression? |
| plans, tasks, workshops, knowledge artifacts | Readiness & Knowability | Can the beneficiary act and verify success with minimal clarification? |

No lens / axis / finding / worker minimum exists. A lens with no trigger does not run.

## 6 — Adaptive reviewer topology

`--scope` sets the ceiling; **no-flag is adaptive**, not broad.

| Mode | Normal topology |
|---|---|
| `--scope narrow` | lead + deterministic checks; **at most one** critic |
| no flag | lead + **one** independent critic for nontrivial work |
| `--scope broad` | lead + **up to three** independent critics, one per distinct risk |

**Zero workers is valid** when direct proof settles a tiny target. Responsibilities (use only these three):
- **Primary Critic** — local truth, Promise alignment, proof sufficiency, assumptions, material edge cases.
- **Contract/Compatibility Specialist** — only for nontrivial consumers, public shape, lifecycle, or cross-phase handoffs.
- **Risk Specialist** — only for one separate high-risk domain (security / migration / concurrency / operations / domain architecture).

**Parallel work requires independent questions** — never send several reviewers over the same files under different names. Launch workers read-only, on the current session model (omit any model override). Worker packet: exact target/revision · one owned question · only the relevant Contract fields · ordered files + commands · selected history · explicit exclusions. **No full conversation transcript.**

## 7 — Worker output + adjudication

Each worker returns **at most five** material findings (a ceiling, not a target):

```text
severity: CRITICAL | HIGH | MEDIUM
confidence: high | medium
location: path:line | command | requirement-id
claim: one sentence
proof: exact evidence
impact: what breaks / which promise fails
smallest_fix: grounded correction or decision needed
contract_ref: affected contract field or consumer
```

No intros, strengths, clean-area lists, LOW/style noise, or separate thesis/compatibility prose. CRITICAL/HIGH needs direct proof or a reproducible failure. Nothing found → `no_material_findings`.

Treat every worker result as a **hypothesis**. The lead must: (1) open the cited source/output; (2) check it against current truth + the Contract; (3) **try to disprove it** or find an intended exception; (4) merge duplicates by root cause; (5) assign final severity/confidence; (6) drop unsupported findings. For security / data-loss / migration / public-contract CRITICAL/HIGH where deterministic evidence isn't decisive, take **one** second targeted proof step — do **not** rerun a panel.

| Severity | Meaning |
|---|---|
| CRITICAL | credible security / data-loss / irreversible failure, or unsafe acceptance |
| HIGH | likely functional failure, false readiness claim, or a blocked named consumer |
| MEDIUM | bounded defect / risk worth correcting |
| LOW | **omit unless explicitly requested** |

**No format-only completeness guards** — a missing heading never justifies relaunching an agent. Style preferences are not defects.

## 8 — Sufficiency + forward-compatibility

Stop when: target/revision is clear · the Contract exists (or its absence is a finding) · appropriate fresh proof ran · material history was assessed · risk-triggered questions are answered · named consumers were checked · every finding survived verify/disprove · unknowns are explicit · another search or worker is unlikely to change the verdict or fix.

Engage **forward-compatibility** when an upstream source names a consumer, or the target exposes/changes a public shape, invariant, lifecycle, schema, command, or handoff. Cheap consumer discovery: immediate next phase → explicit plan/spec/ADR/workshop references → exact-search the symbol/type/command/schema/id → stop when named requirements are covered. The five modes (encapsulation lockout, shape mismatch, lifecycle ownership, contract drift, test boundary) and the next-phase traversal rule live in `references/contract-and-forward-compatibility.md`.

A standalone artifact needs **no exhaustive absence proof** — a compact line suffices:

```text
STANDALONE — no exported shape; no named consumer in plan/ADR/workshop search; no next-phase prerequisite.
```

Mention an unavailable issue tracker only when a source names a relevant issue.

## 9 — Validation is read-only; repair is narrow

Validation never mutates through adjudication. **Automatic repair is allowed only when ALL hold**: target is a document (not source code) · the correction is mechanical and uniquely determined by cited evidence · the edit stays inside the target · it invents no product intent, architecture, API shape, tasks, ACs, or phase decomposition · the exact change can be shown. Eligible: stale line number, unambiguous broken cross-reference, derivable count, malformed status, stale command alias. **Never auto-edit code, and never auto-fix MEDIUM findings.**

**Phase decomposition stays human-gated** — count, splitting, merging, Simple↔Full are planning decisions, never auto-fixes; a thin phase is *strengthened* (add ACs / Done-When / concrete files), never split. After a repair, rerun **only** the failed deterministic check or critic question; `VALIDATED WITH FIXES` requires that reverification to pass. Anything needing human / product judgment stays `NEEDS ATTENTION`; missing product intent is surfaced, never invented.

## 10 — Compact result + durable record

Never print worker counts or clean-area filler. A finding appears **once** — not in a thesis block *and* a matrix *and* a severity list *and* a summary.

Clean:
```markdown
✅ **VALIDATED** — no material issues.
- **Target**: `<path or diff>`
- **Proof**: `<fresh commands / source checks>`
- **Thesis**: `<purpose met; target proof = actual proof>`
- **Consumers**: `<N/N satisfied | STANDALONE | N/A>`
```

Findings:
```markdown
❌ **NEEDS ATTENTION** — <C> critical, <H> high, <M> medium.

| Severity | Finding | Evidence | Impact | Smallest fix |
|---|---|---|---|---|

**Thesis**: <advanced | partial | blocked; target proof → actual proof>
**Consumers**: <compact result>
**Open decision**: <only when human judgment is required>
```

**Durable record**: no live consumer reads an inline `## Validation Record`, so **stop appending records to targets**. For plan-associated work write **one sidecar per artifact**, overwritten on revalidation (git keeps prior versions):

```text
docs/plans/<plan>/validations/<artifact-stem>-validation.md
```

Outside a durable plan/review context, print the verdict and create nothing. Template + rules: `references/record-template.md`.

## Principles

1. **Thesis before tactics** — locally correct work that doesn't advance its purpose still fails.
2. **Fresh proof and current code outrank historical prose** for present behaviour; superseded history explains, never overrides.
3. **Workers propose, the lead proves** — every retained finding survived a disprove attempt.
4. **Spend only where risk earns it** — no quota of lenses, axes, findings, or workers.
5. **Validate, don't rewrite** — read-only through adjudication; repair is mechanical, in-target, and reverified.

# validate-v2 — contract semantics + forward-compatibility

Backs `SKILL.md` §2, §4, §8. Load when the target has named consumers, exposes a public shape, or you need the proof-level / history-label definitions.

## Proof levels (the Contract's "Proof target")

| Level | Means |
|---|---|
| **Orientation** | helps a fresh entrant understand the topic and why it matters |
| **Decision** | resolves or narrows a decision space |
| **Contract** | specifies interfaces, schemas, states, commands, invariants, or handoffs |
| **Implementation** | enough detail to build/modify the system with minimal clarification |
| **Integration** | proves it composes with named consumers, contracts, and runtime behaviour |
| **Validated Evidence** | backed by tests, traces, command output, source match, or deployment evidence |

Proof **mismatch** = the claimed level exceeds what the fresh evidence supports (e.g. "implementation-ready" but only phase names exist). That is a finding.

## Authority order (what wins when sources disagree)

1. fresh tests, builds, traces, command output;
2. current code, schemas, active interfaces;
3. active spec, ADR, authoritative workshop contracts;
4. plans, tasks, dossiers, logs, reviews, retros — as intent / risk evidence;
5. conversation assertions.

Superseded history **explains**; it never silently overrides current truth.

## History labels (§4)

| Label | Meaning |
|---|---|
| **Authoritative** | an active ADR / spec / workshop contract |
| **Applicable** | directly maps to current code or the present risk |
| **Partial** | useful warning, but the implementation has since changed |
| **Superseded** | explanatory only — newer truth has replaced it |
| **Unclear** | needs more evidence before it can be relied on |

`no_material_historical_evidence` is a valid result. Do not manufacture a history section to fill the slot.

## Forward-compatibility — the five failure modes

Engage when an upstream source names a consumer, or the target exposes/changes a public shape, invariant, lifecycle, schema, command, or handoff.

| Mode | Question | Example |
|---|---|---|
| **Encapsulation lockout** | Is anything private that a named downstream needs public? | Phase 1 keeps the editor instance a private field; Phase 3 toolbar needs it. |
| **Shape mismatch** | Does the exported type include every field a downstream destructures? | Exports `{ value, onChange }`; downstream wants `{ value, onChange, selection }`. |
| **Lifecycle ownership** | Can a downstream sibling compose without fighting for resource ownership? | Parent owns the lifecycle; sibling must nest rather than compose beside. |
| **Contract drift** | Does the deliverable satisfy the outside contract (ADR/RFC/workshop/spec)? | ADR-012 says debounce 200ms; implementation ships 100ms. |
| **Test boundary** | Can the testing approach extend to cover downstream integration? | Heavy mocks; the downstream phase can't assert real integration. |

Report each engaged consumer as one line: `consumer → requirement → mode → ✅/❌ → evidence`. Worked examples: `references/examples.md`.

## Cheap consumer discovery + STANDALONE

1. inspect the **immediate next phase** for phased artifacts;
2. inspect explicit plan / spec / ADR / workshop references to this artifact;
3. exact-search the relevant symbol / type / command / schema / id;
4. stop when the named requirements are sufficient.

A standalone artifact needs **no exhaustive absence proof** — emit the compact line and move on:

```text
STANDALONE — no exported shape; no named consumer in plan/ADR/workshop search; no next-phase prerequisite.
```

Validators are read-only and lack a `gh` CLI — mention an unavailable issue tracker only when a source names a relevant issue, and escalate to the user rather than guessing.

### Next-phase traversal (phased artifacts)

For a target under `docs/plans/<plan>/phase-<N>/` (or `phase-<N>-<slug>/`), resolve "next phase" strictly:

1. exact `phase-<N+1>/tasks.md`;
2. else slugged `phase-<N+1>-<slug>/tasks.md` (alphabetically first slug if several);
3. else that folder's `phase.md`, then the plan root `plan.md` phase table;
4. **stop at N+1** — never traverse to N+2+ (cost containment);
5. no numbered structure → read `plan.md` and extract the phase table;
6. nothing downstream → STANDALONE check above.

Verify each prerequisite the next phase lists is satisfied by the current artifact's Position; unsatisfied ones are findings.

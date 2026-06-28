# validate-v2 — per-type deterministic checks

Load the block for the target type. These are the **deterministic** proofs the lead runs (§3 of `SKILL.md`) before any critic. Run only the checks the artifact's own claims justify — not all of them, every time.

## Unified planning doc (`<slug>-plan.md`)

The current planning artifact is **one document** with `## Business Specification` (WHAT/WHY) on top and `## Implementation Plan` (HOW) below, a single frozen top-metadata block, and a single `**Status**: READY | DRAFT — UNRESOLVED GAPS`.

- Both halves present; `## Planning Seam` record between them; headings in order, no skipped levels.
- Gate Matrix (G1–G7) present. **Consume those verdicts — do not re-run the gates through agents.** The inline gates already checked Clarify / Constitution / Architecture / ADR / Structure / Testing-Alignment / Domain-Completeness.
- `### Target Domains` (business half) is `SPEC_DOMAINS`; every domain there appears with status + relationship + role.
- `### Domain Manifest` covers every file named in any phase task table; classifications consistent (`contract` / `internal` / `cross-domain`).
- `### Acceptance Coverage Map` — every AC id resolves to ACs in the business half; cross-refs ("Per finding 01") resolve.
- Phase task tables have success criteria; CS score present; testing tasks ordered per the stated Testing Strategy.
- **Phase decomposition is the human's call** — never flag "should be multi-phase" or recommend splitting; `**Mode**: Simple` is a deliberate single-phase decision. A thin phase is *strengthened* (ACs / Done-When / files), never split (`SKILL.md` §9).

**`Status: DRAFT — UNRESOLVED GAPS`** → proportionate validation, not a swarm:
- Validate that each listed gap is **honest, grounded, and actionable** (the `## Unresolved Gaps` table points at a real violation site).
- Check thesis (Promise/Purpose) and any **named downstream contracts**.
- **Do not broadly re-prove the declared failures** — the plan already says they failed; confirm the diagnosis, don't re-derive it.
- Retain `NEEDS ATTENTION` (a DRAFT plan is, by its own header, not yet ready).

## Legacy split spec / plan (compatibility)

Older folders may carry a separate `*-spec.md` and `*-plan.md`. Recognise this as a **compatibility case** only — classify by content, not by retired `specify` / `architect` stage names.
- **Spec**: user value, scope, acceptance criteria, constraints, non-goals explicit enough to plan from.
- **Plan**: phase coherence + ordering, dependencies acyclic, risks cross-referenced to findings, domain alignment, ACs testable.

## Tasks dossier (`tasks.md`)

- Line numbers, method signatures, class hierarchies, imports referenced in tasks match the **current** source.
- Plan ↔ dossier alignment (task count, key-finding references); dependency chain correct.
- Task ids and AC ids resolve; pre-implementation checks present where the approach needs them.

## Code change (diff)

- Read the **full diff** plus relevant unchanged dependencies — not just changed lines.
- Run, when available and read the fresh output yourself: targeted tests, typecheck, lint, build, schema validation, repro commands. A linter passing is **not** a test pass.
- Inspect named consumers and any changed **public contract** (exported types, signatures, shared schemas).
- **Surface counts are solution-wide, never `src/`-only.** When a deterministic proof counts a rename / signature / ctor-change surface ("rename surface = N sites"), grep the **whole solution** — test projects and any sibling project referencing the changed assembly (via project references / `InternalsVisibleTo`), not just the source dir. A signature change *always* propagates to tests. Either count solution-wide, or state explicitly that the count excluded tests — a `src/`-scoped count reported as "surface complete" is a false clean bill.
- Domain placement + dependency direction preserved (business → infrastructure ok; infrastructure → business never; business → business via contracts only).
- Deployment/ops ripple: new env vars, config, migrations, CI changes.

## Workshop

- Fact-check claims, examples, schemas, commands, diagrams against current source, docs, specs, and sibling workshops.
- The workshop answers the questions that prompted it; records rejected alternatives and open questions.
- Proof-level fit: does it reach its target level with concrete examples / contracts / validation paths, or is it long prose that doesn't reduce ambiguity (proxy optimization)?

## General doc

- Claims fact-checked against source code and documentation.
- Internal consistency: no contradictions, terminology stable, cross-references accurate.

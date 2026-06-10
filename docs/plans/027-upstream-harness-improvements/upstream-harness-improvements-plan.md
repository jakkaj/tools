> **⚠️ Superseded by plan-029 (2026-06-10)** — including this plan's **ownership claim**: the statement that this repo owns the canonical harness loop skills is **explicitly reversed**. `AI-Substrate/harness-engineering` now owns the harness loop end-to-end (setup AND runtime); this repo consumes only the `/eng-harness-flow` router and keeps the retro-schema copy + frozen retro history. Do not "fix" ownership statements back toward this document — it is an unmodified point-in-time record. See [`docs/plans/029-eng-harness-switchover/`](../029-eng-harness-switchover/).

# Upstream Harness Improvements Implementation Plan

**Mode**: Simple  
**Plan Version**: 1.0.0  
**Created**: 2026-05-30  
**Spec**: [upstream-harness-improvements-spec.md](./upstream-harness-improvements-spec.md)  
**Status**: READY

## Gate Matrix

| Gate | Check | Status | Notes |
|------|-------|--------|-------|
| G1 | Clarify | PASS | Spec has no unresolved `[NEEDS CLARIFICATION]` markers; domain and harness readiness decisions are recorded. |
| G2 | Constitution | N/A | No `docs/project-rules/constitution.md` exists in tools. |
| G3 | Architecture | N/A | No `docs/project-rules/architecture.md` exists in tools. |
| G4 | ADR Compliance | N/A | No accepted ADRs found under `docs/adr/`. |
| G5 | Structure | PASS | Simple plan contains required sections, task table, success criteria, risks, and resolved references. |
| G6 | Testing Alignment | PASS | Hybrid testing is represented by fixture/schema validation, drift checks, and install/orphan checks. |
| G7 | Domain Completeness | PASS | Every spec domain appears in Target Domains and Domain Manifest; informal domains do not require `docs/domains/` setup. |

## Summary

This plan upstreams the stronger harness signal/back-pressure loop into tools' canonical runtime skills without moving setup/provisioning out of harness-engineering. The implementation updates `harness-1-boot`, `harness-2-observe`, and `harness-3-retro` to recognize signal readiness, inference gaps, and missing deterministic proof as improvement opportunities. It preserves the universal retro schema by encoding signal/sensor/back-pressure gaps through existing `kind` values plus targets and suggested encodings, then updates docs and validation fixtures so the split remains legible.

## Target Domains

| Domain | Status | Relationship | Role |
|--------|--------|--------------|------|
| harness-runtime | NEW | modify | Runtime Boot -> Observe -> Retro skills receiving the upstreamed wording and behavior. |
| compound-contract | NEW | consume | Universal retro schema and `.retro.md` contract that must remain compatible. |
| sdd-pipeline | NEW | consume | `plan-2d`, `plan-3`, and `the-flow` consume or narrate harness/back-pressure artifacts. |
| dev-tooling | NEW | modify | Validation and install-drift recipes/scripts. |
| external-harness-setup | NEW | consume | Cross-repo provisioning source that remains in harness-engineering. |

## Domain Manifest

| File | Domain | Classification | Rationale |
|------|--------|----------------|-----------|
| `skills/harness/harness-1-boot/SKILL.md` | harness-runtime | internal | Boot skill contract should report signal/back-pressure readiness without scaffolding setup. |
| `skills/harness/harness-2-observe/SKILL.md` | harness-runtime | internal | Observe skill should capture inference gaps and missing deterministic signals. |
| `skills/harness/harness-3-retro/SKILL.md` | harness-runtime | internal | Retro skill should surface ease and proof/back-pressure improvements during drain/harvest. |
| `skills/compound/schemas/fixtures/*.retro.md` | compound-contract | contract | Fixtures prove the chosen signal-gap encoding remains schema-valid. |
| `skills/compound/schemas/README.md` | compound-contract | contract | Documents schema-safe encoding examples and validation expectations. |
| `skills/compound/schemas/retro.schema.json` | compound-contract | contract | Consumed for validation only; no enum expansion is planned. |
| `skills/SDD/plan-2d-backpressure-survey/SKILL.md` | sdd-pipeline | cross-domain | Should remain advisory and may be referenced for conceptual alignment; avoid behavioral gating changes. |
| `skills/SDD/the-flow/SKILL.md` | sdd-pipeline | cross-domain | Should remain advisory and may be referenced for setup/runtime ownership wording if needed. |
| `README.md` | dev-tooling | cross-domain | Top-level ownership guidance for runtime skills vs setup. |
| `INSTALL.md` | dev-tooling | cross-domain | Install guidance should point setup to harness-engineering and runtime loop to tools. |
| `justfile` | dev-tooling | internal | Existing `skills-orphans` / `doctor-skills` validation should be used or lightly extended. |
| `scripts/compound-value.sh` | dev-tooling | internal | Harvest JSON consumer; do not break expected output shape. |
| `/Users/jordanknight/substrate/harness-engineering/skills/engineering-harness-setup/SKILL.md` | external-harness-setup | cross-domain | Source of setup/provisioning wording; referenced, not copied wholesale into tools. |

## Key Findings

| # | Impact | Finding | Action |
|---|--------|---------|--------|
| 01 | Critical | New retro `kind` values would break tools' current schema, which only allows seven enum values. | Encode signal/sensor/back-pressure gaps as `difficulty`, `improvement-suggestion`, or `magic-wand` with explicit `target` and `suggested_encoding`. |
| 02 | Critical | Plan 024 intentionally moved setup/scaffold/migration out of the tools runtime loop. | Keep tools changes runtime-only; reference harness-engineering for provisioning. |
| 03 | High | `harness-1-boot` already degrades gracefully with `UNAVAILABLE`, but its readiness report is behind setup's richer signal checklist. | Extend report wording/check extraction for signal readiness while preserving graceful fallback. |
| 04 | High | `harness-2-observe` already owns silent capture, but its trigger list does not explicitly include inference gaps or missing deterministic signals. | Add signal/back-pressure triggers and schema-safe encoding examples. |
| 05 | High | `harness-3-retro` already owns drain/harvest, but its prioritization language does not clearly distinguish ease improvements from back-pressure improvements. | Add drain prompt and harvest prioritization wording for missing proof/sensors, with no persisted indexes. |
| 06 | High | `npx skills add` leaves renamed/removed deployed skills behind. | Include `just skills-orphans` and `just doctor-skills` in validation/docs so old `boot-harness` and `compound-*` installs are discoverable. |
| 07 | High | `plan-2d` and `the-flow` explicitly forbid gates, scores, thresholds, and blocking. | Preserve advisory wording everywhere; do not turn back-pressure gaps into readiness gates. |
| 08 | High | Validation currently relies on lightweight checks and schema docs; the spec needs deterministic proof for sample retro encoding. | Add or update sample `.retro.md` fixture(s) and document validation commands using existing schema artifacts. |

## Implementation

**Objective**: Update tools so its canonical harness runtime loop reflects the signal-readiness and inference-gap improvements from harness-engineering while preserving setup/runtime boundaries and retro schema compatibility.

**Testing Approach**: Hybrid - use real skill files, real schema fixtures, and local drift/install checks; avoid mocks.

### Tasks

| Status | ID | Task | Domain | Path(s) | Done When | Notes |
|--------|----|------|--------|---------|-----------|-------|
| [x] | T001 | Define schema-safe signal-gap encoding examples | compound-contract | `skills/compound/schemas/fixtures/*.retro.md`, `skills/compound/schemas/README.md` | Fixture(s) represent inference/sensor/back-pressure gaps using existing `kind` values and their YAML frontmatter validates against the current schema via the documented `python3`/`jsonschema` or `ajv` command. | Per findings 01, 08. Validation must extract frontmatter, not merely parse the markdown file. |
| [x] | T002 | Update boot signal-readiness reporting contract | harness-runtime | `skills/harness/harness-1-boot/SKILL.md` | Boot skill documents runtime inspectability, smoke paths, architecture/static checks, security/dependency/schema checks, evidence paths, and back-pressure gaps while retaining `UNAVAILABLE` behavior. | Per findings 02, 03. |
| [x] | T003 | Update observe triggers and encoding guidance | harness-runtime | `skills/harness/harness-2-observe/SKILL.md` | Observe triggers include inference gaps and missing deterministic signals/sensors, and examples encode them with schema-valid kinds/targets. | Per findings 01, 04. |
| [x] | T004 | Update retro drain/harvest prioritization | harness-runtime | `skills/harness/harness-3-retro/SKILL.md` | Drain/harvest wording distinguishes ease improvements from proof/back-pressure improvements without adding gates, indexes, or enum values. | Per findings 01, 05, 07. |
| [x] | T005 | Clarify ownership and migration guidance | dev-tooling | `README.md`, `INSTALL.md`, `skills/compound/README.md` | Docs state runtime loop skills live in tools, setup/provisioning remains in harness-engineering, and old deployed slugs should be checked with orphan tooling. | Per findings 02, 06. |
| [x] | T006 | Run and document validation | dev-tooling | `justfile`, `scripts/compound-value.sh`, touched docs/skills | JSON/schema checks, retro-frontmatter schema validation, markdown drift checks, `just skills-orphans`, `just doctor-skills`, and grep checks for legacy source slugs pass or have documented baseline exceptions. | Per findings 06, 08. If orphan checks report existing deployed drift, capture the baseline in the implementation log; do not auto-delete user-installed skills. |

### Acceptance Criteria

- [x] `harness-1-boot` describes and reports signal/back-pressure readiness dimensions including runtime inspectability, smoke paths, architecture/static checks, security/dependency/schema checks, and evidence/back-pressure gaps.
- [x] `harness-1-boot` still treats missing governance docs as `UNAVAILABLE`, not a failure, and does not scaffold setup artifacts.
- [x] `harness-2-observe` includes triggers for inference gaps and missing deterministic signals/sensors.
- [x] `harness-2-observe` guidance maps those gaps into schema-valid retro entries.
- [x] `harness-3-retro --drain` prompts users to consider both ease/friction improvements and missing proof/signal/back-pressure improvements.
- [x] `harness-3-retro --harvest` prioritization or display guidance distinguishes ease improvements from back-pressure improvements without adding persisted indexes.
- [x] Tools documentation states that runtime harness loop skills live in tools and project setup/provisioning remains in harness-engineering.
- [x] Any sample retro entries validate against tools' existing retro schema without adding new `kind` enum values.
- [x] Existing advisory/back-pressure language in `plan-2d` and `the-flow` remains non-blocking and threshold-free.
- [x] Validation includes JSON parsing/schema checks, relevant skill drift checks, and install-orphan reporting.
- [x] Validation explicitly checks retro fixture YAML frontmatter against `skills/compound/schemas/retro.schema.json`.

### Risks

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Non-schema `kind` values slip into examples | Medium | High | Add fixture validation before changing observe/retro wording; do not edit the enum. |
| Setup behavior creeps into tools | Medium | High | Keep tasks scoped to consumption/reporting/docs; reference harness-engineering instead of scaffolding. |
| Back-pressure language reads as a gate | Medium | Medium | Use "advisory", "improvement candidate", and "best-effort"; avoid thresholds and scores. |
| Existing harvest consumers break | Low | High | Do not change harvest JSON shape or persisted index behavior. |
| Old installed slugs remain in user environments | High | Medium | Document and run `just skills-orphans` / `just doctor-skills`; never auto-delete. |
| Validation or install checks touch user environments unexpectedly | Low | Medium | Keep validation local, avoid network-dependent checks unless already part of existing repo commands, do not print secrets, and never delete deployed skills automatically. |

## Agent Harness Strategy

Agent Harness: Not applicable for this plan (user override: continue without a local project harness; validate through repo checks and the harness skills themselves).

## Discoveries & Learnings

| Task | Discovery | Impact |
|------|-----------|--------|
| T001 | No local `docs/project-rules/engineering-harness.md` (or legacy fallback) exists in tools. | Pre-phase harness validation is `UNAVAILABLE`; continue with repo-local schema and drift checks per the plan. |
| T001 | Signal/back-pressure examples fit the existing schema using `difficulty`, `improvement-suggestion`, and `magic-wand` plus explicit `target` and `suggested_encoding` values. | No retro enum migration is needed for this phase. |
| T002 | Boot can report missing signal-readiness dimensions without changing the core health verdict. | Missing proof remains an improvement signal, not a gate. |
| T003 | Observe entries can name the missing proof mechanism directly (`project-sensor`, `runtime-inspectability`, `architecture-fitness`) while staying schema-valid. | Harvest can distinguish these gaps by target/encoding hint instead of new enum values. |
| T004 | Retro can surface proof/back-pressure improvement candidates by display labels and prioritization hints. | No persisted index, enum expansion, or blocking gate is needed. |
| T005 | Top-level and install docs already distinguish skills from setup tooling; the missing piece was the cross-repo setup/runtime split. | Added explicit tools-runtime vs harness-engineering-setup ownership wording and read-only orphan-check guidance. |
| T006 | `just skills-orphans` reports `pack-code` as a hand-installed local-only skill in `~/.claude/skills`; `just doctor-skills` classifies it as harmless. | Baseline documented; no auto-delete was performed. |

---

## Validation Record (2026-05-30T05:38:20Z)

### Validation Thesis

**Raison d'être**: Turn the spec's migration goal into a buildable, schema-safe implementation path: upstream harness-engineering's signal-readiness, back-pressure, and inference-gap improvements into tools' runtime harness skills without moving setup/provisioning into tools.

**Value claim**: Future implementation agents and reviewers should have a clearer, safer, more repeatable path for making tools the canonical runtime-loop home while avoiding schema breaks and setup/runtime boundary drift.

**Artifact promise**: The plan provides concrete tasks, touched files, validation evidence, risks, and acceptance criteria sufficient for `/plan-6` to implement the migration without re-deciding scope.

**Intended beneficiaries**: Implementation agents, reviewers, tools maintainers, downstream users installing harness skills, and the later harness-engineering cleanup work.

**Proof target**: Implementation.

**Evidence standard**: Source-aligned task list; schema-compatible fixture plan; explicit touched files; validation commands/checks; non-goal boundaries; advisory/non-gating language preservation.

**Thesis source**: `upstream-harness-improvements-spec.md` summary, goals, non-goals, complexity assumptions, and acceptance criteria.

**Thesis verdict**: Advanced.

**Main thesis risk**: The implementation must still prove the sample retro frontmatter against the schema and avoid drifting from runtime guidance into setup scaffolding.

---

| Agent | Lenses Covered | Thesis Axes Covered | Issues | Verdict |
|-------|----------------|---------------------|--------|---------|
| Plan Coherence Validator | Domain Boundaries, Integration & Ripple, Hidden Assumptions, Technical Constraints, Edge Cases & Failures, Concept Documentation, Proof-Level Fit | Implementation Readiness, Migration Safety, Contract Integrity, Review Compression | 0 blockers | Passed |
| Risk & Evidence Validator | Evidence Sufficiency, Deployment & Ops, Security & Privacy, System Behavior, Edge Cases & Failures, Hidden Assumptions | Evidence Sufficiency, Operational Reliability, Safety to Change, Learning Compounding | 2 medium + 1 low tightening items fixed | Passed with fixes |
| Thesis & Forward Validator | Thesis Alignment, Forward-Compatibility, User/Product Value Preservation, Downstream Usefulness, Integration & Ripple, Contract Integrity | Thesis Alignment, Forward-Compatibility, Migration Safety | 0 blockers | Passed |

### Forward-Compatibility Matrix

| Consumer | Requirement | Failure Mode | Verdict | Evidence |
|----------|-------------|--------------|---------|----------|
| `/plan-6-v2-implement-phase` | Needs task IDs, paths, done-when criteria, validation expectations, and scope boundaries. | Test boundary | Passed | T001-T006 name paths, success criteria, validation expectations, and schema/setup boundaries. |
| `/plan-7-v2-code-review` | Needs acceptance criteria, risks, non-goals, and schema/advisory constraints to review against. | Contract drift | Passed | Acceptance criteria and risks explicitly cover schema enum compatibility, advisory back-pressure language, and no setup scaffolding. |
| Harness-engineering follow-up cleanup | Needs tools to own equivalent runtime behavior before duplicate runtime skills are retired there. | Lifecycle ownership | Passed | Plan tasks update tools' `harness-1/2/3` runtime skills while preserving `engineering-harness-setup` as the external setup owner. |

**Thesis alignment**: Value claim advanced: yes; proof level Target = Implementation, Actual = Implementation; main thesis risk is ensuring implementation validates retro frontmatter and does not drift into setup scaffolding.

**Outcome alignment**: The plan advances "Clarify in tools docs that operational harness loop skills live in tools, while setup/provisioning remains in harness-engineering" by assigning docs, runtime-skill, schema-fixture, and validation tasks that preserve the boundary.

**Standalone?**: No - downstream consumers are `/plan-6-v2-implement-phase`, `/plan-7-v2-code-review`, and the later harness-engineering cleanup.

Overall: VALIDATED WITH FIXES

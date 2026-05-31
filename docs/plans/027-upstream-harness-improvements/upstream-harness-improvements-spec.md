# Upstream Harness Improvements

**Mode**: Simple

## Research Context

📚 Specification incorporates findings from `research-dossier.md`.

The research found a clear ownership split: tools already owns the canonical runtime harness loop (`harness-1-boot`, `harness-2-observe`, `harness-3-retro`) while `AI-Substrate/harness-engineering` owns setup/provisioning (`engineering-harness-setup`, generated `engineering-harness.md`, generated `harness/cli/`, and setup templates). The missing upstream work is to make the runtime loop in tools reflect the signal-readiness, back-pressure, and inference-gap improvements recently added in harness-engineering without moving setup scaffolding into tools.

Key research findings:

1. `harness-1-boot` should understand richer signal readiness from setup-generated governance docs, but still report `UNAVAILABLE` gracefully when no governance doc exists.
2. `harness-2-observe` should capture inference/back-pressure gaps using tools' existing retro schema kinds, not by introducing incompatible `signal-gap`, `sensor-gap`, or `weak-back-pressure` enum values.
3. `harness-3-retro` should make ease improvements and back-pressure improvements visible during drain/harvest while preserving computed views and schema compatibility.
4. Tools documentation should point provisioning/setup work to harness-engineering and runtime loop work to tools.

## Summary

Upstream the harness back-pressure, signal-readiness, and retro/inference-gap improvements from harness-engineering into tools' canonical harness runtime skills. Keep `engineering-harness-setup` and all provisioning behavior in harness-engineering; tools should consume the generated project harness artifacts, not recreate them.

## Goals

- Make tools' `harness-1-boot` report signal/back-pressure readiness that aligns with setup-generated `engineering-harness.md` content.
- Make tools' `harness-2-observe` capture moments where an agent or reviewer had to infer behavior that a harness should have proved.
- Make tools' `harness-3-retro` surface missing signals/sensors/back-pressure as first-class improvement candidates during drain and harvest.
- Preserve the tools schema contract by mapping signal/sensor/back-pressure gaps into existing `kind` values plus target/encoding metadata.
- Clarify in tools docs that operational harness loop skills live in tools, while setup/provisioning remains in harness-engineering.
- Provide a safe validation path for skill prose, schema compatibility, sample retro artifacts, and install/orphan checks.

## Non-Goals

- Do not move `engineering-harness-setup` into tools.
- Do not recreate `compound-0-setup`, `boot-harness`, or `compound-*` legacy skill names in tools.
- Do not add mandatory gates, numeric thresholds, or blocking behavior to back-pressure survey or harness retro flows.
- Do not broaden the universal retro schema enum unless explicitly planned as a schema migration.
- Do not create a formal `docs/domains/` system as part of this migration.
- Do not implement product-specific sensors for downstream repositories; tools should describe/capture/report the pattern.

## Target Domains

No formal `docs/domains/registry.md` exists in tools. This spec uses domain-like boundaries discovered in research.

| Domain | Status | Relationship | Role in This Feature |
|--------|--------|--------------|----------------------|
| harness-runtime | **NEW** | **modify** | Runtime Boot -> Observe -> Retro skills that should receive the upstreamed wording and behavior. |
| compound-contract | **NEW** | **consume** | Universal retro schema and `.retro.md` contract that must remain compatible. |
| sdd-pipeline | **NEW** | **consume** | `plan-2d`, `plan-3`, and `the-flow` consume or narrate harness/back-pressure artifacts. |
| dev-tooling | **NEW** | **modify** | `just` recipes and scripts used to validate skill drift, schema compatibility, and installed orphan skills. |
| external-harness-setup | **NEW** | **consume** | Cross-repo provisioning source that remains in harness-engineering. |

### New Domain Sketches

#### harness-runtime [NEW]

- **Purpose**: Own the canonical operational loop skills in tools: Boot, Observe, Retro.
- **Boundary Owns**: Reading project harness governance, producing session-buffer observations, draining/harvesting retro entries, and narrating signal/back-pressure improvement opportunities.
- **Boundary Excludes**: Creating project governance docs, scaffolding `docs/compound/`, or generating `harness/cli/`; those remain setup responsibilities.

#### compound-contract [NEW]

- **Purpose**: Preserve the universal retro entry shape used by tools, minih-compatible harvesters, and downstream projects.
- **Boundary Owns**: Schema-valid `kind`, `target`, frontmatter envelope, and computed harvest expectations.
- **Boundary Excludes**: Feature-specific classification taxonomies that would require unplanned schema migrations.

#### sdd-pipeline [NEW]

- **Purpose**: Keep plan-stage back-pressure and harness cues coherent across `plan-2d`, `plan-3`, and `the-flow`.
- **Boundary Owns**: Advisory deterministic back-pressure survey, plan consumption of `backpressure-coverage.md`, and flow narration.
- **Boundary Excludes**: Enforcing gates, thresholds, or mandatory sensor coverage.

#### dev-tooling [NEW]

- **Purpose**: Provide safe local validation for skills, schemas, and install drift.
- **Boundary Owns**: `just` recipes, validation scripts, and copy-pasteable orphan cleanup reports.
- **Boundary Excludes**: Deleting user-installed skills automatically.

#### external-harness-setup [NEW]

- **Purpose**: Represent the external setup/provisioning owner in harness-engineering.
- **Boundary Owns**: Generated project rules, starter CLI, command maps, magic-wand prompt, and setup templates.
- **Boundary Excludes**: Runtime loop execution once setup artifacts are present.

## Testing Strategy

**Approach**: Hybrid - lightweight checks plus targeted tests/fixtures for schema and skill behavior.

**Rationale**: The migration is mostly skill/documentation behavior, but schema compatibility and sample retro encoding need deterministic checks so signal/back-pressure wording does not drift into invalid artifacts.

**Focus Areas**:

- Markdown/prose drift checks for updated skill files.
- JSON schema parsing for `skills/compound/schemas/retro.schema.json`.
- Sample `.retro.md` fixtures that encode inference/sensor/back-pressure gaps using existing schema kinds.
- `just skills-orphans` / `just doctor-skills` style checks for install drift.
- Grep-based checks that legacy slugs are not reintroduced as tools source skills.

**Excluded**:

- Full end-to-end install into every downstream deploy target.
- Product-specific boot/smoke/architecture/security sensor implementation.
- Network-dependent validation.

**Mock Usage**: Avoid mocks entirely. Use real skill files, schema fixtures, and sample retro artifacts.

## Documentation Strategy

**Location**: Hybrid README + skill docs.

**Rationale**: Users need quick ownership guidance at the top level and detailed operational behavior where agents actually read the skills. Update top-level/install guidance only where it prevents confusion; keep behavior-specific detail in `skills/harness/*` and adjacent README surfaces.

## Complexity

**Score**: CS-3 (medium)

**Breakdown**: S=2, I=2, D=1, N=1, F=1, T=1

**Confidence**: 0.82

**Assumptions**:

- The tools repo remains the canonical home for runtime harness skills.
- Harness-engineering remains the canonical home for setup/provisioning.
- Schema compatibility is preferred over new retro `kind` values.
- The user-selected Simple mode means this should be planned as one coherent migration phase unless architecture discovers a real split is necessary.
- The informal target-domain boundaries are sufficient for this migration; no formal `docs/domains/` registry is needed.
- Tools' own local project harness governance can remain unavailable for this work; validation should use repo checks and the harness skills themselves.

**Dependencies**:

- Current tools `skills/harness/*` skill bodies.
- Current tools `skills/compound/schemas/retro.schema.json`.
- Current tools `plan-2d`, `plan-3`, and `the-flow` wording.
- Harness-engineering setup templates and legacy boot/compound skill wording as source material.

**Risks**:

- Accidentally moving setup/scaffolding responsibility into tools.
- Creating invalid retro entries by using non-schema `kind` values.
- Making back-pressure sound mandatory rather than advisory.
- Leaving install docs advertising old harness-engineering runtime skills after tools is updated.

**Phases**:

- Phase 1: Upstream runtime-loop wording, schema-safe examples, validation, and ownership docs into tools.

## Acceptance Criteria

1. `harness-1-boot` describes and reports signal/back-pressure readiness dimensions including runtime inspectability, smoke paths, architecture/static checks, security/dependency/schema checks, and evidence/back-pressure gaps.
2. `harness-1-boot` still treats missing governance docs as `UNAVAILABLE`, not a failure, and does not scaffold setup artifacts.
3. `harness-2-observe` includes triggers for inference gaps and missing deterministic signals/sensors.
4. `harness-2-observe` guidance maps those gaps into schema-valid retro entries.
5. `harness-3-retro --drain` prompts users to consider both ease/friction improvements and missing proof/signal/back-pressure improvements.
6. `harness-3-retro --harvest` prioritization or display guidance distinguishes ease improvements from back-pressure improvements without adding persisted indexes.
7. Tools documentation states that runtime harness loop skills live in tools and project setup/provisioning remains in harness-engineering.
8. Any sample retro entries validate against tools' existing retro schema without adding new `kind` enum values.
9. Existing advisory/back-pressure language in `plan-2d` and `the-flow` remains non-blocking and threshold-free.
10. Validation includes JSON parsing/schema checks, relevant skill drift checks, and install-orphan reporting.

## Risks & Assumptions

- **Schema risk**: Directly porting `signal-gap`, `sensor-gap`, or `weak-back-pressure` as `kind` values would break tools' current schema.
- **Boundary risk**: Adding setup behavior to tools would contradict plan 024's consolidation.
- **Advisory-language risk**: Stronger back-pressure wording could accidentally read as a gate.
- **Install-drift risk**: Old deployed skills can linger because `npx skills add` does not prune removed slugs.

## Open Questions

- Should tools add a tiny schema-validation recipe for sample retro fixtures, or is documented validation enough for this phase?
- Should the top-level tools README mention harness-engineering setup directly, or should that live only in install/skill docs?

## Workshop Opportunities

| Topic | Type | Why Workshop | Key Questions |
|-------|------|--------------|---------------|
| Retro schema-safe encoding of signal gaps | Data Model | Direct enum port is unsafe; the plan needs a stable mapping. | Which existing `kind` should represent signal/sensor/back-pressure gaps? Which targets and metadata should be recommended? |

## Clarifications

### Session 2026-05-30

| Question | Answer |
|----------|--------|
| Workflow Mode | Simple - single-phase quick path. |
| Testing Strategy | Hybrid - lightweight checks plus targeted tests/fixtures for schema and skill behavior. |
| Mock Usage | Avoid mocks entirely - use real skill files, schema fixtures, and sample retro artifacts. |
| Documentation Strategy | Hybrid README + skill docs - update top-level/install guidance and relevant skill READMEs/SKILL.md. |
| Domain Review | Keep the informal boundaries: `harness-runtime`, `compound-contract`, `sdd-pipeline`, `dev-tooling`, and external `harness-setup`. |
| Agent Harness Readiness | Continue without a local project harness; validate through repo checks and the harness skills themselves. |

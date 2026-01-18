# Workflow Composer CLI

**Mode**: Simple

> **Resolved**: CLI framework decision made (typer). Existing validator to be reused.

---

## Research Context

This specification incorporates findings from `research-dossier.md` (75 findings across 7 research areas).

**Components Affected**:
- `enhance/src/` - New CLI module location
- `enhance/sample/` - Existing stage templates (01-explore)
- `enhance/run/` - Generated run directories
- `enhance/tools/` - Existing validation tooling

**Critical Dependencies**:
- `stage-config.json` schema - defines input/output contracts
- `validate_stage_outputs.py` - existing JSON Schema validation
- `create_run.py` - existing run creation logic (to be absorbed)
- `/plan-1b-specify.md` - source for 02-specify stage transformation

**Modification Risks**:
- Stage-config.json schema changes affect downstream validation
- Output folder structure is consumed by existing samples
- Prompt transformation requires careful removal of command infrastructure

**Link**: See `research-dossier.md` for full analysis (75 findings, 15 prior learnings)

---

## Summary

**WHAT**: Build a CLI tool that composes workflow run folders from workflow specification templates, enabling deterministic execution of multi-stage workflows by coding agents.

**WHY**: The current `/plan-*` command ecosystem operates as ad-hoc prompts. A structured workflow system with explicit inputs, outputs, and validation contracts enables:
1. Reproducible stage execution
2. Schema-validated outputs
3. Automated inter-stage dependency resolution
4. Clear separation between orchestration and execution

---

## Goals

1. **Create a `compose` command** that transforms a wf-spec folder into an executable run directory with all stages prepared
2. **Create a `prepare-wf-stage` command** that prepares a single stage by copying outputs from a prior stage as inputs
3. **Define a wf.yaml schema** that declares workflow stages, their order, and inter-stage dependencies
4. **Implement stage 02-specify** as a second sample stage to validate the multi-stage workflow pattern
5. **Create a `validate` command** that checks stage outputs with LLM-friendly, actionable error messages for missing files, empty files, and schema violations
6. **Maintain folder structure contracts** established in 01-explore (inputs/, prompt/, run/output-files/, run/output-data/, run/runtime-inputs/)

---

## Non-Goals

1. **Full workflow orchestrator runtime** - This builds the folder preparation tooling, not the execution engine
2. **Dynamic sub-workflow expansion** - Phase execution loops (from workflow-schema-simple.md) are out of scope
3. **Interactive user prompts during compose** - All inputs must be provided upfront or via prior stages
4. **GUI or web interface** - CLI only
5. **Automatic stage execution** - The CLI prepares folders; agents execute prompts manually
6. **Migration of all /plan-* commands** - Only 01-explore and 02-specify for this iteration

---

## Complexity

**Score**: CS-3 (medium)

**Breakdown**:
| Dimension | Score | Rationale |
|-----------|-------|-----------|
| Surface Area (S) | 1 | Multiple files: CLI module, schemas, 02-specify sample |
| Integration (I) | 1 | Two external: typer (CLI), jsonschema (validation) |
| Data/State (D) | 1 | Minor: wf.yaml schema, stage-config.json validation |
| Novelty (N) | 1 | Some ambiguity: wf.yaml schema not yet defined |
| Non-Functional (F) | 0 | Standard: no special perf/security requirements |
| Testing/Rollout (T) | 1 | Integration: need to test compose → stage execution flow |
| **Total** | **5** | Maps to CS-3 |

**Confidence**: 0.85 (research dossier provides clear patterns from existing code)

**Assumptions**:
- typer for CLI (user decision - modern, type-hint driven)
- YAML preferred over JSON for workflow definitions (human readability)
- Existing stage-config.json structure is stable
- /plan-1b-specify.md transformation follows same pattern as /plan-1a-explore.md
- Enhanced validate command builds on validate_stage_outputs.py patterns but adds LLM-friendly error formatting

**Dependencies**:
- typer for CLI framework
- PyYAML for wf.yaml parsing
- jsonschema for validation (already in use via validate_stage_outputs.py)
- Existing sample_1/stages/01-explore/ as reference

**Risks**:
- wf.yaml schema design may need iteration after initial use
- 02-specify stage transformation may reveal new patterns not seen in 01-explore

**Phases**:
1. Prepare wf-spec folder (wf.yaml, templates, schemas, specify stage)
2. Implement compose command
3. Implement prepare-wf-stage command
4. Implement validate command (enhanced with LLM-friendly errors)

---

## Acceptance Criteria

1. **AC-01**: Running `chainglass compose ./wf-spec --output ./enhance/run` creates a run folder with:
   - `wf-run.json` with run metadata
   - `stages/explore/` and `stages/specify/` with all required subdirectories
   - Shared templates copied to each stage (`wf.md`, `wf-result.schema.json`)
   - Empty `run/output-*` directories in each stage

2. **AC-02**: Running `chainglass prepare-wf-stage specify --run-dir ./enhance/run/003` copies files declared in specify's dependencies:
   - `explore/run/output-files/research-dossier.md` → `specify/inputs/research-dossier.md`
   - `explore/run/output-data/findings.json` → `specify/inputs/findings.json`
   - Supports `--dry-run` to validate dependencies without copying

3. **AC-03**: The wf-spec folder contains a `wf.yaml` that:
   - Declares stage order (explore, specify)
   - Each stage declares its own `dependencies` (self-contained, validatable as atomic unit)
   - Validates against a JSON Schema before compose

4. **AC-04**: Stage `specify` in wf-spec includes:
   - `stage-config.json` with inputs/outputs declaration
   - `prompt/main.md` (transformed from /plan-1b-specify.md)
   - Stage-specific schemas in `schemas/`

   After compose, the run folder also contains:
   - `prompt/wf.md` (copied from `wf-spec/templates/wf.md`)
   - `schemas/wf-result.schema.json` (copied from `wf-spec/schemas/`)

5. **AC-05**: Running `chainglass validate ./enhance/run/003/stages/explore` validates all declared outputs:
   - Checks all required output files exist
   - Checks output files are not empty (0 bytes)
   - Validates JSON outputs against their declared schemas

6. **AC-06**: All paths in stage-config.json and wf.yaml are relative to their containing directory; the CLI resolves them to absolute paths before operations

7. **AC-07**: Compose is idempotent - running twice on the same wf-spec produces identical output (modulo timestamps in wf-run.json)

8. **AC-08**: The `validate` command provides LLM-friendly, actionable error messages:
   - Missing file: `FAIL: Missing required output: {path}. Action: Write this file before completing the stage.`
   - Empty file: `FAIL: Output file is empty: {path}. Action: Write content to this file.`
   - Schema error: `FAIL: Schema validation failed for {path}. Error: {details}. Action: Fix the JSON structure per {schema_path}.`

---

## Risks & Assumptions

### Risks
| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| wf.yaml schema insufficient for future stages | Medium | Medium | Design extensibility, version the schema |
| 02-specify transformation reveals unexpected patterns | Low | Medium | Document differences, adapt transform pattern |
| compose command becomes too complex | Low | High | Keep it simple; defer dynamic expansion |
| Validation fails silently on new output types | Low | Medium | Require schema for all data outputs |

### Assumptions
1. The existing 01-explore stage structure is the canonical pattern
2. typer for CLI framework (user decision)
3. Reuse existing validate_stage_outputs.py for validation (user decision)
4. Users will run stages manually after compose (no auto-execution)
5. Stage order is strictly sequential (01 before 02) for this iteration
6. All stage outputs are files on disk (no in-memory passing)

---

## Open Questions

All questions resolved - see Clarifications section below.

---

## ADR Seeds (Optional)

### ADR Seed 1: Workflow Definition Format
**Decision Drivers**:
- Human readability for workflow authors
- Consistency with existing JSON configuration
- Tooling support for validation

**Candidate Alternatives**:
- A: YAML with JSON Schema validation
- B: JSON matching stage-config.json pattern
- C: Python dataclass with Pydantic validation

**Stakeholders**: Workflow authors, CLI maintainers

### ADR Seed 2: CLI Framework (DECIDED)
**Decision**: Use **typer** for the CLI framework.

**Rationale**:
- Modern, type-hint driven approach
- Better developer experience for subcommands
- Auto-generated help and shell completion
- Built on click but with cleaner API

**Rejected Alternatives**:
- argparse: Verbose, manual help text
- click: Good but typer provides better DX with type hints

---

## Resolved Decisions

1. **CLI Framework**: Use **typer** (user decision)
2. **Validation**: Enhanced `validate` command with LLM-friendly actionable errors
3. **Config Format**: YAML (`wf.yaml`) - human-readable for workflow authors
4. **CLI Name**: `chainglass` - workflow composition tool
5. **Stage IDs**: Slugs only (`explore`, `specify`) - order defined in wf.yaml

---

## Testing Strategy

**Approach**: Manual / Lightweight
**Rationale**: Quick KISS implementation to try things out and refine position; no TDD overhead.
**Focus Areas**: Manual verification that compose creates correct folder structure
**Excluded**: Unit tests, integration tests, TDD workflow
**Mock Usage**: N/A - real file operations only

---

## Documentation Strategy

**Location**: None (for now)
**Rationale**: Exploratory implementation; docs can be added once the approach is validated

---

## Clarifications

### Session 2026-01-18

| # | Question | Answer | Updated Section |
|---|----------|--------|-----------------|
| Q1 | Workflow mode? | Simple (pre-set in spec) | Header |
| Q2 | Testing approach? | Manual/Lightweight - no TDD, quick KISS | Testing Strategy |
| Q3 | Config format (YAML vs JSON)? | **YAML** - human-readable | Resolved Decisions |
| Q4 | CLI name? | **chainglass** | Resolved Decisions, ACs |
| Q5 | Stage ID format? | **Slugs only** (explore, specify) | Resolved Decisions, Appendix |

**Coverage Summary**:
- **Resolved**: Mode, Testing, Config format, CLI name, Stage IDs, Schema sharing
- **Deferred**: Documentation (add after validation)
- **Outstanding**: None

---

## Appendix: wf-spec Folder Structure (Proposed)

```
wf-spec/
├── wf.yaml                    # Workflow definition (declares stage order)
├── templates/
│   └── wf.md                  # Shared bootstrap prompt (copied to each stage during compose)
├── schemas/
│   ├── wf.schema.json         # Validates wf.yaml
│   └── wf-result.schema.json  # Shared result schema (copied to each stage)
└── stages/
    ├── explore/               # Stage ID = slug (order defined in wf.yaml)
    │   ├── stage-config.json
    │   ├── prompt/
    │   │   └── main.md        # Stage-specific instructions
    │   └── schemas/
    │       ├── findings.schema.json
    │       └── manifest.schema.json
    └── specify/
        ├── stage-config.json
        ├── prompt/
        │   └── main.md        # Stage-specific instructions
        └── schemas/
            └── spec-metadata.schema.json
```

**During compose**, the CLI:
1. Copies `templates/wf.md` → each stage's `prompt/wf.md`
2. Copies `schemas/wf-result.schema.json` → each stage's `schemas/wf-result.schema.json`
3. Copies stage-specific files as-is

---

**Specification Created**: 2026-01-18
**Research Source**: docs/plans/010-first-wf-build/research-dossier.md
**Next Step**: Run `/plan-3-architect` to generate the implementation plan

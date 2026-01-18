# Workflow Composer CLI Implementation Plan

**Mode**: Multi-Phase
**Plan Version**: 1.1.0
**Created**: 2026-01-18
**Spec**: [./first-wf-build-spec.md](./first-wf-build-spec.md)
**Status**: DRAFT

> **Doctrine Note**: No project doctrine files exist (rules.md, idioms.md, architecture.md, constitution.md). This plan proceeds with explicit acknowledgment that doctrine-based validation cannot be performed. Consider running `/plan-0-constitution` to establish project norms if this becomes a recurring pattern.

---

## Table of Contents
1. [Executive Summary](#executive-summary)
2. [Critical Research Findings](#critical-research-findings)
3. [Phase 1: Prepare wf-spec Folder](#phase-1-prepare-wf-spec-folder)
4. [Phase 2: Implement compose Command](#phase-2-implement-compose-command)
5. [Phase 3: Implement prepare-wf-stage Command](#phase-3-implement-prepare-wf-stage-command)
6. [Phase 4: Implement validate Command](#phase-4-implement-validate-command)
7. [Appendix A: Concrete Definitions](#appendix-a-concrete-definitions)
   - [A.1 wf-spec Folder Structure](#a1-wf-spec-folder-structure)
   - [A.2 wf.yaml - Workflow Definition](#a2-wfyaml---workflow-definition) ← **Single source of truth for all stages**
   - [A.3 wf.schema.json - Schema for wf.yaml](#a3-wfschemajson---schema-for-wfyaml-validation)
   - [A.4 wf.md - Shared Bootstrap Prompt](#a4-wfmd---shared-bootstrap-prompt-template)
   - [A.5 wf-result.schema.json - Shared Result Schema](#a5-wf-resultschemajson---shared-result-schema)
   - [A.5b read-files.schema.json - Runtime Read Tracking](#a5b-read-filesschemajson---runtime-read-tracking)
   - [A.5c explore-metrics.schema.json - Parameter Extraction Demo](#a5c-explore-metricsschemajson---nested-data-for-parameter-extraction)
   - [A.5d output-params.schema.json - Published Output Parameters](#a5d-output-paramsschemajson---published-output-parameters)
   - [A.6 spec-metadata.schema.json](#a6-spec-metadataschemajson---specify-output-schema)
   - [A.7 specify/prompt/main.md](#a7-specifypromptmainmd---transformed-stage-prompt)
   - [A.8 Run Folder Structure](#a8-run-folder-structure-compose-output)
   - [A.9 wf-run.json](#a9-wf-runjson---run-metadata)
   - [A.10 Compose Algorithm](#a10-compose-algorithm)
   - [A.11 prepare-wf-stage Algorithm](#a11-prepare-wf-stage-algorithm)
   - [A.12 Validate Algorithm](#a12-validate-algorithm)
   - [A.13 Test Fixtures for Phase 4](#a13-test-fixtures-for-phase-4)
8. [Change Footnotes Ledger](#change-footnotes-ledger)

---

## Executive Summary

**Problem**: The current `/plan-*` command ecosystem operates as ad-hoc prompts with no structured input/output contracts. This prevents reproducible stage execution, schema-validated outputs, and automated inter-stage dependency resolution.

**Solution**: Build `chainglass`, a CLI tool using typer that transforms workflow specification folders (wf-spec) into executable run directories. Two commands: `compose` (create full run) and `prepare-wf-stage` (copy outputs from prior stage as inputs). Create 02-specify stage sample by transforming /plan-1b-specify.md.

**Expected Outcome**: A working two-stage workflow (explore → specify) that coding agents can execute manually, with schema-validated outputs and clear separation between orchestration and execution.

---

## Critical Research Findings (Concise)

**Research Source**: [./research-dossier.md](./research-dossier.md) (75 findings, 15 prior learnings)

| # | Impact | Finding | Action |
|---|--------|---------|--------|
| 01 | Critical | **wf.yaml schema undefined** - Entry point for compose needs stage declarations | Design YAML schema with version, stages list, inputs with from_stage |
| 02 | Critical | **wf.yaml is the single source of truth** - All stage definitions inline; stage-config.yaml extracted during compose | Validate wf.yaml before compose; extract stage configs to run folder |
| 03 | Critical | **Three-tier output mandatory** - output-files/, output-data/, runtime-inputs/ have distinct semantics | Create all three directories per stage; validate all tiers post-execution |
| 04 | Critical | **Absolute paths required (PL-05)** - Relative paths fail across cwd changes | Use Path.resolve() everywhere; reject paths with ".." |
| 05 | High | **prepare-wf-stage for stage inputs** - Stage declares inputs with from_stage, self-contained | Read inputs with from_stage from wf.yaml; resolve parameters via output_parameter or query; support --dry-run |
| 06 | High | **02-specify transformation needed** - Must convert /plan-1b-specify.md command → stage prompt | Remove command infra (~400 lines), keep core logic, add stage context |
| 07 | High | **Shared templates: wf.md + wf-result.schema.json** - Copied to each stage during compose | Store in wf-spec/templates/ and wf-spec/schemas/; copy during compose |
| 08 | High | **validate_stage_outputs.py reuse** - Existing validator at enhance/tools/ | Create Python wrapper in CLI; avoid subprocess; use same output format |
| 09 | High | **Stage IDs are slugs** - Order defined in wf.yaml, not prefix numbers | Use "explore", "specify" as IDs; wf.yaml declares execution order |
| 10 | Medium | **Multiple outputs required (PL-12)** - wf-result.json + findings.json + read-files.json | Validate all declared outputs exist before marking stage complete |
| 11 | Medium | **Prompt transformation pattern (PL-03)** - Remove YAML frontmatter, argument parsing, STOP AND WAIT | Apply consistent pattern to 02-specify transformation |
| 12 | Medium | **Idempotent compose (AC-07)** - Running twice produces identical output | Use deterministic ordering; only timestamps may differ in wf-run.json |
| 13 | Medium | **typer for CLI (user decision)** - Overrides PL-01 argparse pattern | Use typer with type hints; auto-generated help |
| 14 | Low | **No dynamic expansion** - Phase loops are out of scope | Keep stage order strictly sequential for this iteration |
| 15 | Low | **Manual testing only** - No TDD overhead for this exploratory work | Focus on manual verification of folder structure and validation |

---

## Phase 1: Prepare wf-spec Folder

**Objective**: Create the complete wf-spec folder structure with all configuration files, schemas, templates, and stage prompts.

**Testing Approach**: Manual verification of file contents against Appendix definitions
**Dependencies**: None (foundational phase)

### Tasks

| Status | ID | Task | CS | Type | Dependencies | Path(s) | Validation | Notes |
|--------|-----|------|----|------|--------------|---------|------------|-------|
| [x] | 1.1 | Create wf-spec directory structure | 1 | Setup | -- | `enhance/sample/sample_1/wf-spec/` | All directories exist per A.1 | mkdir -p for all paths [^1] |
| [x] | 1.2 | Create wf.yaml workflow definition | 2 | Setup | 1.1 | `enhance/sample/sample_1/wf-spec/wf.yaml` | YAML parses; content matches A.2 exactly | **Single source of truth** [^2] |
| [x] | 1.3 | Create shared wf.md bootstrap template | 1 | Setup | 1.1 | `enhance/sample/sample_1/wf-spec/templates/wf.md` | Content matches A.4 exactly | Shared prompt [^3] |
| [x] | 1.4 | Create shared wf-result.schema.json | 1 | Setup | 1.1 | `enhance/sample/sample_1/wf-spec/schemas/wf-result.schema.json` | Valid JSON Schema; matches A.5 | Required output schema [^4] |
| [x] | 1.4b | Create wf.schema.json for wf.yaml validation | 1 | Setup | 1.1 | `enhance/sample/sample_1/wf-spec/schemas/wf.schema.json` | Valid JSON Schema; matches A.3 | Enables validation [^5] |
| [x] | 1.5 | Copy explore stage assets from existing 01-explore | 2 | Setup | 1.1 | Source: `enhance/sample/sample_1/runs/run-2024-01-18-001/stages/01-explore/` → Target: `enhance/sample/sample_1/wf-spec/stages/explore/` | prompt/main.md, schemas/ present | Copy + update refs [^6] |
| [x] | 1.6 | Create explore-metrics.schema.json | 2 | Setup | 1.5 | `enhance/sample/sample_1/wf-spec/stages/explore/schemas/explore-metrics.schema.json` | Valid JSON Schema; matches A.5c | Parameter extraction [^7] |
| [x] | 1.7 | Create specify spec-metadata.schema.json | 2 | Setup | 1.2 | `enhance/sample/sample_1/wf-spec/stages/specify/schemas/spec-metadata.schema.json` | Valid JSON Schema; matches A.6 | Output schema [^8] |
| [x] | 1.8 | Copy read-files.schema.json to specify | 1 | Setup | 1.5 | `enhance/sample/sample_1/wf-spec/stages/specify/schemas/read-files.schema.json` | Identical to explore's manifest schema | Runtime tracking [^9] |
| [x] | 1.9 | Transform /plan-1b-specify.md to main.md | 2 | Setup | 1.2 | Source: `agents/commands/plan-1b-specify.md` → Target: `enhance/sample/sample_1/wf-spec/stages/specify/prompt/main.md` | Content matches A.7; no $ARGUMENTS, no command refs; HAS sections: "External Research", "Unresolved Research", "Phases (for CS-4+" | Transform + Stage Context [^10] |
| [x] | 1.10 | Verify wf-spec completeness | 1 | Test | 1.1-1.9 | -- | All files exist; all JSON/YAML parses; structure matches A.1 | Manual verification [^11] |

### Phase 1 Acceptance Criteria

- [x] **P1-AC-01**: wf-spec folder structure matches Appendix A.1 exactly
- [x] **P1-AC-02**: wf.yaml content matches A.2; declares explore → specify with parameters
- [x] **P1-AC-03**: All schemas are valid JSON Schema (test with jsonschema library)
- [x] **P1-AC-03b**: wf.yaml validates against wf.schema.json (self-documenting wf-spec)
- [x] **P1-AC-04**: specify/prompt/main.md has no `$ARGUMENTS`, `--simple`, or `/plan-*` references
- [x] **P1-AC-05**: explore-metrics.schema.json matches A.5c with nested structure for parameter queries

---

## Phase 2: Implement compose Command

**Objective**: Create the chainglass CLI module with the `compose` command that transforms wf-spec into run folders.

**Testing Approach**: Manual verification of compose output
**Dependencies**: Phase 1 complete (wf-spec folder exists)

### Tasks

| Status | ID | Task | CS | Type | Dependencies | Path(s) | Validation | Notes |
|--------|-----|------|----|------|--------------|---------|------------|-------|
| [ ] | 2.1 | Create chainglass module structure | 1 | Setup | -- | `enhance/src/chainglass/__init__.py` | Can `import chainglass` | Empty init |
| [ ] | 2.2 | Create pyproject.toml with dependencies | 1 | Setup | 2.1 | `enhance/pyproject.toml` | `pip install -e .` succeeds | typer, PyYAML, jsonschema |
| [ ] | 2.3 | Define wf.schema.json in chainglass | 2 | Setup | 2.1 | `enhance/src/chainglass/schemas/wf.schema.json` | Schema matches A.3 exactly | For validating wf.yaml |
| [ ] | 2.4 | Implement YAML parser module | 2 | Core | 2.3 | `enhance/src/chainglass/parser.py` | Loads wf.yaml; validates against schema; returns dict | PyYAML + jsonschema |
| [ ] | 2.5 | Implement composer module | 3 | Core | 2.4 | `enhance/src/chainglass/composer.py` | Creates run folder per A.10 algorithm | Core compose logic |
| [ ] | 2.6 | Implement compose CLI command | 2 | Core | 2.1, 2.5 | `enhance/src/chainglass/cli.py` | `chainglass compose --help` works | typer command |
| [ ] | 2.7 | Implement idempotent compose | 1 | Core | 2.5 | `enhance/src/chainglass/composer.py` | Running twice produces identical output | Deterministic ordering |
| [ ] | 2.8 | Manual test: compose creates correct structure | 1 | Test | 2.6 | -- | Output matches A.8 exactly | Verify all dirs, files, copies |

### Phase 2 Acceptance Criteria

- [ ] **P2-AC-01**: `chainglass compose ./wf-spec --output ./run` creates run folder matching A.8
- [ ] **P2-AC-02**: wf-run.json created with content per A.9
- [ ] **P2-AC-03**: Shared templates (wf.md, wf-result.schema.json) copied to each stage
- [ ] **P2-AC-04**: Stage-specific files (stage-config.yaml extracted, main.md, schemas) copied correctly
- [ ] **P2-AC-05**: Empty output directories created (run/output-files/, run/output-data/, run/runtime-inputs/)
- [ ] **P2-AC-06**: Compose is idempotent (AC-07 from spec)

---

## Phase 3: Implement prepare-wf-stage Command

**Objective**: Create the `prepare-wf-stage` command that prepares a stage by:
1. Copying inputs that have `from_stage` set
2. Resolving parameters by querying prior stage JSON outputs
3. Writing resolved parameters to `inputs/params.json`

**Testing Approach**: Manual verification of file copying, parameter resolution, and --dry-run validation
**Dependencies**: Phase 2 complete (compose works)

### Tasks

| Status | ID | Task | CS | Type | Dependencies | Path(s) | Validation | Notes |
|--------|-----|------|----|------|--------------|---------|------------|-------|
| [ ] | 3.1 | Implement preparer module | 2 | Core | Phase 2 | `enhance/src/chainglass/preparer.py` | Copies files per A.11 algorithm | Handles inputs and parameters |
| [ ] | 3.2 | Implement prepare-wf-stage CLI command | 2 | Core | 3.1 | `enhance/src/chainglass/cli.py` | `chainglass prepare-wf-stage --help` works | typer command with --dry-run option |
| [ ] | 3.3 | Implement JSON query resolver | 2 | Core | 3.1 | `enhance/src/chainglass/preparer.py` | Resolves dot notation and array index queries | `summary.total` and `items[0].name` |
| [ ] | 3.4 | Implement parameter extraction | 2 | Core | 3.3 | `enhance/src/chainglass/preparer.py` | Queries prior stage JSON, writes params.json | Per A.11 algorithm |
| [ ] | 3.5 | Implement --dry-run validation | 1 | Core | 3.1 | `enhance/src/chainglass/preparer.py` | Validates inputs and parameters without writing | Stage readiness check |
| [ ] | 3.6 | Handle missing inputs/params | 1 | Core | 3.1 | `enhance/src/chainglass/preparer.py` | Actionable error with from_stage and expected path | "Complete stage 'explore' first" |
| [ ] | 3.7 | Manual test: prepare copies files and resolves params | 1 | Test | 3.2 | -- | Files copied, params.json written | Per A.2 and A.11 |
| [ ] | 3.8 | Manual test: --dry-run validates without writing | 1 | Test | 3.5 | -- | Returns "ready" status, nothing written | Validates stage readiness |

### Phase 3 Acceptance Criteria

- [ ] **P3-AC-01**: `chainglass prepare-wf-stage specify --run-dir ./run/001` copies inputs and resolves parameters
- [ ] **P3-AC-02**: Inputs with `from_stage` are copied to stage's inputs/ folder
- [ ] **P3-AC-03**: Parameters are resolved by querying prior stage JSON outputs
- [ ] **P3-AC-04**: Resolved parameters written to `inputs/params.json`
- [ ] **P3-AC-05**: Query syntax supports dot notation (`summary.total`) and array index (`items[0].name`)
- [ ] **P3-AC-06**: `--dry-run` validates all inputs and parameters without copying/writing
- [ ] **P3-AC-07**: Blocked status with actionable error if required input/parameter source missing

---

## Phase 4: Implement validate Command

**Objective**: Create an enhanced `validate` command that validates stage outputs with LLM-friendly, actionable error messages. This command is designed to be called by an LLM at the end of stage execution to verify completion.

**Testing Approach**: Manual verification with valid and invalid outputs
**Dependencies**: Phase 2 complete (compose creates stage structure)

### Tasks

| Status | ID | Task | CS | Type | Dependencies | Path(s) | Validation | Notes |
|--------|-----|------|----|------|--------------|---------|------------|-------|
| [ ] | 4.1 | Implement validator module | 3 | Core | Phase 2 | `enhance/src/chainglass/validator.py` | Validates per A.12 algorithm | Core validation logic |
| [ ] | 4.2 | Implement file presence check | 1 | Core | 4.1 | `enhance/src/chainglass/validator.py` | Detects missing required output files | Per stage-config.yaml outputs |
| [ ] | 4.3 | Implement empty file check | 1 | Core | 4.1 | `enhance/src/chainglass/validator.py` | Detects empty (0-byte) output files | Files must have content |
| [ ] | 4.4 | Implement schema validation | 2 | Core | 4.1 | `enhance/src/chainglass/validator.py` | Validates JSON outputs against declared schemas | jsonschema Draft202012 |
| [ ] | 4.5 | Implement output_parameter extraction | 2 | Core | 4.4 | `enhance/src/chainglass/validator.py` | Extracts output_parameters and writes output-params.json | Uses same query resolver as preparer |
| [ ] | 4.6 | Implement LLM-friendly error formatting | 2 | Core | 4.1-4.5 | `enhance/src/chainglass/validator.py` | Errors are actionable with fix instructions | See A.12 output format |
| [ ] | 4.7 | Implement validate CLI command | 2 | Core | 4.1 | `enhance/src/chainglass/cli.py` | `chainglass validate --help` works | typer command |
| [ ] | 4.8 | Manual test: validate passes on valid stage | 1 | Test | 4.7 | Test fixture: `enhance/sample/sample_1/runs/run-2024-01-18-001/stages/01-explore/` (existing valid stage) | Returns success with summary | Verify all outputs present |
| [ ] | 4.9 | Manual test: validate extracts output_parameters | 1 | Test | 4.7 | -- | output-params.json written with correct values | Verify parameter extraction |
| [ ] | 4.10 | Manual test: validate fails with actionable errors | 1 | Test | 4.7 | Test fixture: Create `enhance/sample/sample_1/test-fixtures/invalid-stage/` with missing/empty/invalid files | Returns failure with specific fix instructions | See A.13 for fixture structure |

### Phase 4 Acceptance Criteria

- [ ] **P4-AC-01**: `chainglass validate ./run/001/stages/explore` validates all declared outputs
- [ ] **P4-AC-02**: Detects and reports missing required files with message: `FAIL: Missing required output: {path}. Action: Write this file before completing the stage.`
- [ ] **P4-AC-03**: Detects and reports empty files with message: `FAIL: Output file is empty: {path}. Action: Write content to this file.`
- [ ] **P4-AC-04**: Detects and reports schema violations with message: `FAIL: Schema validation failed for {path}. Error: {jsonschema error}. Action: Fix the JSON structure per {schema_path}.`
- [ ] **P4-AC-05**: If `output_parameters` declared, extracts values and writes `run/output-data/output-params.json`
- [ ] **P4-AC-06**: Returns structured result: `{"status": "pass"|"fail", "stage_id": "...", "checks": [...], "output_params_written": bool, "errors": [...], "summary": "..."}`
- [ ] **P4-AC-07**: Exit code 0 on pass, 1 on fail

---

## Global Acceptance Criteria

Per spec, all ACs must be satisfied. Verify against Appendix definitions:

- [ ] **AC-01**: `chainglass compose ./wf-spec --output ./enhance/run` creates run folder matching A.8 structure
- [ ] **AC-02**: `chainglass prepare-wf-stage specify --run-dir ./run/003` copies inputs with `from_stage` per A.2
- [ ] **AC-03**: wf-spec/wf.yaml (A.2) validates against wf.schema.json (A.3)
- [ ] **AC-04**: Stage specify in wf-spec includes all required files per A.1, A.6, A.7, A.8
- [ ] **AC-05**: `chainglass validate ./run/003/stages/explore` validates outputs with actionable errors
- [ ] **AC-06**: All paths in wf.yaml are relative; CLI resolves to absolute
- [ ] **AC-07**: Compose is idempotent
- [ ] **AC-08**: validate command provides LLM-friendly, actionable error messages

---

## Phase Dependency Graph

```
Phase 1 (wf-spec folder)
    │
    ▼
Phase 2 (compose) ──────┬──> Phase 3 (prepare-wf-stage)
                        │
                        └──> Phase 4 (validate)
```

---

## Risks

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| wf.yaml schema insufficient for future stages | Medium | Medium | Design with version field; keep extensible |
| 02-specify transformation reveals unexpected patterns | Low | Medium | Document differences; adapt transform pattern |
| Path resolution fails in different working directories | Medium | High | Use Path.resolve() everywhere; test from multiple cwd |
| validate error messages not actionable enough | Medium | Medium | Test with actual LLM; iterate on message format |

---

## Appendix A: Concrete Definitions

This appendix defines the exact content for all configuration files, schemas, and templates. Implementers should use these as the source of truth.

### A.1 wf-spec Folder Structure

**Base Path**: `enhance/sample/sample_1/wf-spec/` (all paths below are relative to repository root)

**Key principle**: `wf.yaml` is the single source of truth for all stage definitions. The `stages/` folder contains only stage-specific assets (prompts, schemas) - no config files.

```
enhance/sample/sample_1/wf-spec/
├── wf.yaml                           # Workflow definition with ALL stage configs inline (A.2)
├── templates/
│   └── wf.md                         # Shared bootstrap prompt (A.4)
├── schemas/
│   ├── wf.schema.json                # Validates wf.yaml (A.3)
│   └── wf-result.schema.json         # Shared result schema (A.5)
└── stages/
    ├── explore/
    │   ├── prompt/
    │   │   └── main.md               # Stage-specific instructions
    │   └── schemas/
    │       ├── findings.schema.json        # Output schema
    │       ├── explore-metrics.schema.json # Nested data for parameter extraction (A.5c)
    │       └── read-files.schema.json        # Runtime tracking schema
    └── specify/
        ├── prompt/
        │   └── main.md               # Transformed from /plan-1b-specify.md (A.8)
        └── schemas/
            ├── spec-metadata.schema.json  # Output schema (A.7)
            └── read-files.schema.json       # Runtime tracking schema
```

**Note**: No `stage-config.json` in wf-spec - stage definitions live in `wf.yaml`. During compose, each stage's config is extracted to `stage-config.yaml` in the run folder.

### A.2 wf.yaml - Workflow Definition

**File**: `enhance/sample/sample_1/wf-spec/wf.yaml`

This is the **single source of truth** for the entire workflow. Each stage is fully defined inline with its inputs, outputs, and prompt references. Inputs can specify `from_stage` to indicate they come from another stage's output. During compose, each stage's definition is extracted to `stage-config.yaml` in the run folder.

```yaml
# Workflow Definition for explore-and-specify pipeline
# Schema: ./schemas/wf.schema.json

version: "1.0"

metadata:
  name: "explore-specify"
  description: "Two-stage workflow: research codebase, then create feature specification"
  author: "chainglass"

stages:
  # ============================================================
  # STAGE: explore
  # ============================================================
  - id: "explore"
    name: "Codebase Research"
    description: "Deep-dive research into existing codebase functionality"

    inputs:
      required:
        - name: "user-description.md"
          path: "inputs/user-description.md"
          description: "User-provided research query or feature description"
      optional: []

    outputs:
      files:
        - name: "research-dossier.md"
          path: "run/output-files/research-dossier.md"
          description: "Comprehensive research report"
      data:
        - name: "wf-result.json"
          path: "run/output-data/wf-result.json"
          schema: "schemas/wf-result.schema.json"
          description: "Stage execution status"
          required: true
        - name: "findings.json"
          path: "run/output-data/findings.json"
          schema: "schemas/findings.schema.json"
          description: "Structured findings for downstream consumption"
          required: true
        - name: "explore-metrics.json"
          path: "run/output-data/explore-metrics.json"
          schema: "schemas/explore-metrics.schema.json"
          description: "Nested metrics data for parameter extraction demo"
          required: true

    # Output parameters published by this stage for downstream consumption
    # Stage writes these to run/output-data/output-params.json at completion
    output_parameters:
      - name: "total_findings"
        description: "Total number of findings discovered"
        source: "run/output-data/explore-metrics.json"
        query: "summary.total_findings"
      - name: "critical_count"
        description: "Count of critical findings"
        source: "run/output-data/explore-metrics.json"
        query: "summary.by_impact.critical"
      - name: "top_component"
        description: "Most affected component name"
        source: "run/output-data/explore-metrics.json"
        query: "components[0].name"
      - name: "complexity_score"
        description: "Suggested complexity score"
        source: "run/output-data/explore-metrics.json"
        query: "recommendations.complexity.suggested_score"

    prompt:
      entry: "prompt/wf.md"
      main: "prompt/main.md"

  # ============================================================
  # STAGE: specify
  # ============================================================
  - id: "specify"
    name: "Feature Specification"
    description: "Create feature specification from research findings"

    inputs:
      required:
        - name: "research-dossier.md"
          path: "inputs/research-dossier.md"
          description: "Research report from explore stage"
          from_stage: "explore"
          source: "run/output-files/research-dossier.md"
        - name: "findings.json"
          path: "inputs/findings.json"
          description: "Structured findings from explore stage"
          from_stage: "explore"
          source: "run/output-data/findings.json"
      optional:
        - name: "user-description.md"
          path: "inputs/user-description.md"
          description: "Optional additional context from user"

    # Parameters from prior stage's published output_parameters
    # References by name - no need to know internal JSON structure
    parameters:
      - name: "total_findings"
        description: "Number of findings from explore stage"
        from_stage: "explore"
        output_parameter: "total_findings"
      - name: "critical_count"
        description: "Count of critical findings"
        from_stage: "explore"
        output_parameter: "critical_count"
      - name: "top_component"
        description: "Most affected component name"
        from_stage: "explore"
        output_parameter: "top_component"
      - name: "complexity_score"
        description: "Suggested complexity score"
        from_stage: "explore"
        output_parameter: "complexity_score"

    outputs:
      files:
        - name: "spec.md"
          path: "run/output-files/spec.md"
          description: "Feature specification document"
      data:
        - name: "wf-result.json"
          path: "run/output-data/wf-result.json"
          schema: "schemas/wf-result.schema.json"
          description: "Stage execution status"
          required: true
        - name: "spec-metadata.json"
          path: "run/output-data/spec-metadata.json"
          schema: "schemas/spec-metadata.schema.json"
          description: "Structured specification metadata"
          required: true

    # Output parameters published by this stage for downstream consumption
    output_parameters:
      - name: "complexity_score"
        description: "Final complexity score (CS-1 through CS-5)"
        source: "run/output-data/spec-metadata.json"
        query: "complexity.score"
      - name: "complexity_total"
        description: "Total complexity points (0-12)"
        source: "run/output-data/spec-metadata.json"
        query: "complexity.total"
      - name: "unresolved_research_count"
        description: "Number of unresolved research topics"
        source: "run/output-data/spec-metadata.json"
        query: "research.unresolved_count"
      - name: "goals_count"
        description: "Number of goals defined"
        source: "run/output-data/spec-metadata.json"
        query: "goals.length"
      - name: "phases"
        description: "Suggested phases for CS-4+ features (null if CS-1 to CS-3)"
        source: "run/output-data/spec-metadata.json"
        query: "complexity.phases"

    prompt:
      entry: "prompt/wf.md"
      main: "prompt/main.md"

# Shared resources copied to each stage during compose
shared_templates:
  - source: "templates/wf.md"
    target: "prompt/wf.md"
  - source: "schemas/wf-result.schema.json"
    target: "schemas/wf-result.schema.json"
```

### A.3 wf.schema.json - Schema for wf.yaml Validation

**File**: `enhance/src/chainglass/schemas/wf.schema.json` (installed with CLI package)

```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$id": "wf.schema.json",
  "title": "Workflow Definition Schema",
  "description": "Validates wf.yaml workflow definition files. Stages are self-contained.",
  "type": "object",
  "required": ["version", "metadata", "stages"],
  "definitions": {
    "input_item": {
      "type": "object",
      "required": ["name", "path"],
      "properties": {
        "name": {"type": "string", "description": "Input file name"},
        "path": {"type": "string", "pattern": "^inputs/", "description": "Path in inputs/"},
        "description": {"type": "string"},
        "from_stage": {
          "type": "string",
          "pattern": "^[a-z][a-z0-9-]*$",
          "description": "Source stage ID (if input comes from another stage)"
        },
        "source": {
          "type": "string",
          "pattern": "^run/(output-files|output-data)/",
          "description": "Path in source stage (required if from_stage set)"
        }
      }
    },
    "output_item": {
      "type": "object",
      "required": ["name", "path"],
      "properties": {
        "name": {"type": "string"},
        "path": {"type": "string"},
        "description": {"type": "string"},
        "schema": {"type": "string", "description": "Path to JSON Schema file"},
        "required": {"type": "boolean", "default": true}
      }
    },
    "parameter_item": {
      "type": "object",
      "required": ["name", "from_stage"],
      "description": "Reference a value from a prior stage - either via output_parameter name or direct query",
      "properties": {
        "name": {"type": "string", "description": "Parameter name (available to this stage)"},
        "description": {"type": "string"},
        "from_stage": {"type": "string", "pattern": "^[a-z][a-z0-9-]*$"},
        "output_parameter": {
          "type": "string",
          "description": "Name of published output_parameter from source stage (preferred)"
        },
        "source": {
          "type": "string",
          "pattern": "^run/output-data/.*\\.json$",
          "description": "Direct path to JSON file (use with query, alternative to output_parameter)"
        },
        "query": {
          "type": "string",
          "description": "JSONPath-style query when using source (e.g., 'summary.total')"
        }
      },
      "oneOf": [
        {"required": ["output_parameter"]},
        {"required": ["source", "query"]}
      ]
    },
    "output_parameter_item": {
      "type": "object",
      "required": ["name", "source", "query"],
      "description": "Declare a value this stage publishes for downstream consumption",
      "properties": {
        "name": {"type": "string", "description": "Published parameter name"},
        "description": {"type": "string", "description": "What this parameter represents"},
        "source": {
          "type": "string",
          "pattern": "^run/output-data/.*\\.json$",
          "description": "JSON file containing the value"
        },
        "query": {
          "type": "string",
          "description": "JSONPath-style query to extract the value"
        }
      }
    }
  },
  "properties": {
    "version": {
      "type": "string",
      "pattern": "^[0-9]+\\.[0-9]+$"
    },
    "metadata": {
      "type": "object",
      "required": ["name", "description"],
      "properties": {
        "name": {"type": "string", "pattern": "^[a-z][a-z0-9-]*$"},
        "description": {"type": "string", "minLength": 10},
        "author": {"type": "string"}
      }
    },
    "stages": {
      "type": "array",
      "minItems": 1,
      "items": {
        "type": "object",
        "required": ["id", "name", "inputs", "outputs", "prompt"],
        "properties": {
          "id": {"type": "string", "pattern": "^[a-z][a-z0-9-]*$"},
          "name": {"type": "string"},
          "description": {"type": "string"},
          "inputs": {
            "type": "object",
            "properties": {
              "required": {"type": "array", "items": {"$ref": "#/definitions/input_item"}},
              "optional": {"type": "array", "items": {"$ref": "#/definitions/input_item"}}
            }
          },
          "parameters": {
            "type": "array",
            "description": "Values from prior stages (via output_parameter name or direct query)",
            "items": {"$ref": "#/definitions/parameter_item"}
          },
          "output_parameters": {
            "type": "array",
            "description": "Values this stage publishes for downstream consumption",
            "items": {"$ref": "#/definitions/output_parameter_item"}
          },
          "outputs": {
            "type": "object",
            "properties": {
              "files": {"type": "array", "items": {"$ref": "#/definitions/output_item"}},
              "data": {"type": "array", "items": {"$ref": "#/definitions/output_item"}}
            }
          },
          "prompt": {
            "type": "object",
            "required": ["entry", "main"],
            "properties": {
              "entry": {"type": "string"},
              "main": {"type": "string"}
            }
          }
        }
      }
    },
    "shared_templates": {
      "type": "array",
      "items": {
        "type": "object",
        "required": ["source", "target"],
        "properties": {
          "source": {"type": "string"},
          "target": {"type": "string"}
        }
      }
    }
  }
}
```

### A.4 wf.md - Shared Bootstrap Prompt Template

**File**: `enhance/sample/sample_1/wf-spec/templates/wf.md`

```markdown
# Workflow Stage Execution

You are executing a **workflow stage**. This means you are operating within a structured workflow system that provides inputs and expects specific outputs.

## Before You Begin

1. **Read the stage configuration**: `../stage-config.yaml`
   - This defines what inputs are available to you
   - This defines what outputs you must produce
   - Note any stage-specific metadata

2. **Read your inputs**: Check the `../inputs/` directory
   - Read all files declared in stage-config.yaml inputs
   - These are your working materials for this stage

3. **Load your main instructions**: `main.md` (in this same directory)
   - This contains the detailed prompt for this stage's work
   - Follow its instructions completely

## Your Workflow

```
1. Read ../stage-config.yaml     → Understand the contract
2. Read ../inputs/*              → Get your inputs
3. Read ./main.md                → Get your instructions
4. Execute the stage work        → Follow main.md
5. Write outputs to ../run/      → Complete the contract
```

## Output Locations

All outputs go under `../run/`:

- **Documents**: `../run/output-files/`
  - Your primary deliverables (reports, analyses, documentation)

- **Structured Data**: `../run/output-data/`
  - `wf-result.json` - Stage completion status (REQUIRED)
  - Any other structured data outputs

- **Runtime Tracking**: `../run/runtime-inputs/`
  - Write `read-files.json` **as you work** (not just at the end)
  - Log every file you READ from the codebase or inputs
  - This creates an audit trail: "what inputs influenced this stage's outputs"
  - See `../schemas/read-files.schema.json` for the format
  - Example entry (append each time you read a file):
    ```json
    {"path": "/abs/path/to/file.py", "timestamp": "2026-01-18T10:02:00Z", "purpose": "Examine auth logic", "lines": "all"}
    ```

## Stage Completion

When your work is complete:

1. Ensure all declared outputs in `stage-config.yaml` are written
2. Write `wf-result.json` with completion status
3. Run `chainglass validate` on this stage
   - Validates all outputs exist and conform to schemas
   - If `output_parameters` are declared, extracts and writes `output-params.json`
   - These values become available to downstream stages by name
4. Stop and wait - the workflow system handles what comes next

## Output Schemas

Each output declared in `stage-config.yaml` has a corresponding JSON Schema in `../schemas/`. Read the schema files to understand the exact structure required for each output.

---

**Now**: Read `../stage-config.yaml`, then `../inputs/*`, then return here and proceed to `main.md`.
```

### A.5 wf-result.schema.json - Shared Result Schema

**File**: `enhance/sample/sample_1/wf-spec/schemas/wf-result.schema.json`

```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$id": "wf-result.schema.json",
  "title": "Workflow Stage Result",
  "description": "Stage execution status and metadata. Required output for all stages.",
  "type": "object",
  "required": ["status", "completed_at", "stage_id", "error", "metrics"],
  "properties": {
    "status": {
      "type": "string",
      "enum": ["success", "failure", "partial"],
      "description": "Stage completion status"
    },
    "completed_at": {
      "type": "string",
      "format": "date-time",
      "description": "ISO-8601 timestamp of completion"
    },
    "stage_id": {
      "type": "string",
      "description": "Stage identifier from wf.yaml"
    },
    "error": {
      "type": ["string", "null"],
      "description": "Error message if status != success, otherwise null"
    },
    "metrics": {
      "type": "object",
      "description": "Stage-specific metrics",
      "additionalProperties": true
    }
  }
}
```

### A.5b read-files.schema.json - Runtime Read Tracking

**File**: `enhance/sample/sample_1/wf-spec/stages/explore/schemas/read-files.schema.json` (copied to each stage)

Every stage must write a `read-files.json` that logs **what files the agent read** during execution. This creates an audit trail of "what inputs influenced this stage's outputs."

**Why reads only?** File writes, updates, and deletions are tracked by git. The value of read-files.json is knowing what the agent actually consumed—which codebase files, which inputs, which configs influenced the stage's reasoning.

**Write as you go**: Agents should append to read-files.json each time they read a file, not batch it at the end. This ensures the audit trail is preserved even if the stage fails mid-execution.

```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$id": "read-files.schema.json",
  "title": "Stage Runtime Read Log",
  "description": "Log of files read during stage execution - tracks what inputs influenced the stage's outputs",
  "type": "object",
  "required": ["stage_id", "reads"],
  "properties": {
    "stage_id": {
      "type": "string",
      "description": "Stage identifier"
    },
    "started_at": {
      "type": "string",
      "format": "date-time",
      "description": "When stage execution started"
    },
    "reads": {
      "type": "array",
      "description": "Files read in chronological order - append as you go",
      "items": {
        "type": "object",
        "required": ["path", "timestamp"],
        "properties": {
          "path": {
            "type": "string",
            "description": "Absolute path to the file read"
          },
          "timestamp": {
            "type": "string",
            "format": "date-time",
            "description": "When the file was read"
          },
          "purpose": {
            "type": "string",
            "description": "Why this file was read (brief context)"
          },
          "lines": {
            "type": "string",
            "description": "Line range if partial read (e.g., '1-50', 'all')"
          }
        }
      }
    },
    "total_reads": {
      "type": "integer",
      "minimum": 0,
      "description": "Total count of files read"
    }
  }
}
```

**Example read-files.json**:

```json
{
  "stage_id": "explore",
  "started_at": "2026-01-18T10:00:00Z",
  "reads": [
    {"path": "inputs/user-description.md", "timestamp": "2026-01-18T10:00:01Z", "purpose": "Load user query", "lines": "all"},
    {"path": "/Users/dev/project/src/auth/login.py", "timestamp": "2026-01-18T10:02:00Z", "purpose": "Examine auth implementation", "lines": "all"},
    {"path": "/Users/dev/project/src/auth/session.py", "timestamp": "2026-01-18T10:03:00Z", "purpose": "Examine session handling", "lines": "1-150"},
    {"path": "/Users/dev/project/src/auth/tokens.py", "timestamp": "2026-01-18T10:04:30Z", "purpose": "Understand token refresh logic", "lines": "45-120"},
    {"path": "/Users/dev/project/tests/test_auth.py", "timestamp": "2026-01-18T10:06:00Z", "purpose": "Check existing test patterns", "lines": "all"}
  ],
  "total_reads": 5
}
```

### A.5c explore-metrics.schema.json - Nested Data for Parameter Extraction

**File**: `enhance/sample/sample_1/wf-spec/stages/explore/schemas/explore-metrics.schema.json`

This output demonstrates nested JSON structure that downstream stages can query via `parameters`. The `specify` stage extracts values like `summary.total_findings` and `components[0].name`.

```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$id": "explore-metrics.schema.json",
  "title": "Explore Stage Metrics",
  "description": "Nested metrics data that downstream stages can query via parameters",
  "type": "object",
  "required": ["summary", "components", "recommendations"],
  "properties": {
    "summary": {
      "type": "object",
      "required": ["total_findings", "by_impact"],
      "properties": {
        "total_findings": {"type": "integer", "minimum": 0},
        "by_impact": {
          "type": "object",
          "properties": {
            "critical": {"type": "integer"},
            "high": {"type": "integer"},
            "medium": {"type": "integer"},
            "low": {"type": "integer"}
          }
        },
        "by_category": {
          "type": "object",
          "additionalProperties": {"type": "integer"}
        }
      }
    },
    "components": {
      "type": "array",
      "description": "Components examined, sorted by impact",
      "items": {
        "type": "object",
        "required": ["name", "findings_count"],
        "properties": {
          "name": {"type": "string"},
          "path": {"type": "string"},
          "findings_count": {"type": "integer"},
          "risk_level": {"type": "string", "enum": ["low", "medium", "high"]}
        }
      }
    },
    "recommendations": {
      "type": "object",
      "properties": {
        "complexity": {
          "type": "object",
          "properties": {
            "suggested_score": {"type": "string", "pattern": "^CS-[1-5]$"},
            "rationale": {"type": "string"}
          }
        },
        "next_steps": {
          "type": "array",
          "items": {"type": "string"}
        }
      }
    }
  }
}
```

**Example explore-metrics.json** (written by explore stage):

```json
{
  "summary": {
    "total_findings": 15,
    "by_impact": {
      "critical": 2,
      "high": 5,
      "medium": 6,
      "low": 2
    },
    "by_category": {
      "implementation": 8,
      "dependency": 3,
      "pattern": 4
    }
  },
  "components": [
    {
      "name": "auth/session.py",
      "path": "src/auth/session.py",
      "findings_count": 5,
      "risk_level": "high"
    },
    {
      "name": "api/handlers.py",
      "path": "src/api/handlers.py",
      "findings_count": 3,
      "risk_level": "medium"
    }
  ],
  "recommendations": {
    "complexity": {
      "suggested_score": "CS-3",
      "rationale": "Multiple components affected, some external dependencies"
    },
    "next_steps": [
      "Review session handling patterns",
      "Consider auth refactoring"
    ]
  }
}
```

**Output Parameters Published by explore stage**:

At stage completion, the explore stage (or chainglass validate) writes `run/output-data/output-params.json`:

```json
{
  "stage_id": "explore",
  "published_at": "2026-01-18T10:15:00Z",
  "parameters": {
    "total_findings": 15,
    "critical_count": 2,
    "top_component": "auth/session.py",
    "complexity_score": "CS-3"
  }
}
```

**Parameter consumption by specify stage**:

| Parameter | from_stage | output_parameter | Resolved Value |
|-----------|------------|------------------|----------------|
| `total_findings` | `explore` | `total_findings` | `15` |
| `critical_count` | `explore` | `critical_count` | `2` |
| `top_component` | `explore` | `top_component` | `"auth/session.py"` |
| `complexity_score` | `explore` | `complexity_score` | `"CS-3"` |

The downstream stage references by name - no need to know the internal JSON structure of explore-metrics.json.

### A.5d output-params.schema.json - Published Output Parameters

**File**: `enhance/src/chainglass/schemas/output-params.schema.json` (installed with CLI package)

Written by `chainglass validate` when a stage has `output_parameters` declared and validation passes.

```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$id": "output-params.schema.json",
  "title": "Stage Output Parameters",
  "description": "Published output parameters from a stage, available to downstream stages by name",
  "type": "object",
  "required": ["stage_id", "published_at", "parameters"],
  "properties": {
    "stage_id": {
      "type": "string",
      "description": "Stage that published these parameters"
    },
    "published_at": {
      "type": "string",
      "format": "date-time",
      "description": "When parameters were extracted"
    },
    "parameters": {
      "type": "object",
      "description": "Named parameters with their extracted values",
      "additionalProperties": true
    }
  }
}
```

### A.6 spec-metadata.schema.json - Specify Output Schema

**File**: `enhance/sample/sample_1/wf-spec/stages/specify/schemas/spec-metadata.schema.json`

**Note**: The specify stage definition is now inline in wf.yaml (A.2). This section defines only the output schema.

```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$id": "spec-metadata.schema.json",
  "title": "Feature Specification Metadata",
  "description": "Structured metadata from the specification stage",
  "type": "object",
  "required": ["feature_name", "slug", "complexity", "goals", "acceptance_criteria"],
  "properties": {
    "feature_name": {
      "type": "string",
      "minLength": 3,
      "description": "Human-readable feature title"
    },
    "slug": {
      "type": "string",
      "pattern": "^[a-z][a-z0-9-]*$",
      "description": "URL-safe feature identifier"
    },
    "mode": {
      "type": "string",
      "enum": ["simple", "full"],
      "description": "Workflow mode (simple = single phase, full = multi-phase)"
    },
    "complexity": {
      "type": "object",
      "required": ["score", "total", "breakdown"],
      "properties": {
        "score": {
          "type": "string",
          "pattern": "^CS-[1-5]$",
          "description": "Complexity score CS-1 through CS-5"
        },
        "total": {
          "type": "integer",
          "minimum": 0,
          "maximum": 12,
          "description": "Total complexity points (S+I+D+N+F+T)"
        },
        "breakdown": {
          "type": "object",
          "properties": {
            "S": {"type": "integer", "minimum": 0, "maximum": 2},
            "I": {"type": "integer", "minimum": 0, "maximum": 2},
            "D": {"type": "integer", "minimum": 0, "maximum": 2},
            "N": {"type": "integer", "minimum": 0, "maximum": 2},
            "F": {"type": "integer", "minimum": 0, "maximum": 2},
            "T": {"type": "integer", "minimum": 0, "maximum": 2}
          },
          "description": "Individual dimension scores"
        },
        "confidence": {
          "type": "number",
          "minimum": 0,
          "maximum": 1,
          "description": "Confidence in complexity assessment"
        },
        "phases": {
          "type": ["array", "null"],
          "items": {"type": "string"},
          "description": "Suggested phases for CS-4+ features (null if CS-1 to CS-3)"
        }
      }
    },
    "goals": {
      "type": "array",
      "minItems": 1,
      "items": {
        "type": "string",
        "minLength": 10
      },
      "description": "List of feature goals"
    },
    "non_goals": {
      "type": "array",
      "items": {
        "type": "string"
      },
      "description": "Explicitly out-of-scope items"
    },
    "acceptance_criteria": {
      "type": "array",
      "minItems": 1,
      "items": {
        "type": "object",
        "required": ["id", "description"],
        "properties": {
          "id": {
            "type": "string",
            "pattern": "^AC-[0-9]{2}$"
          },
          "description": {
            "type": "string"
          },
          "testable": {
            "type": "boolean",
            "default": true
          }
        }
      },
      "description": "Numbered acceptance criteria"
    },
    "risks": {
      "type": "array",
      "items": {
        "type": "object",
        "properties": {
          "description": {"type": "string"},
          "likelihood": {"type": "string", "enum": ["low", "medium", "high"]},
          "impact": {"type": "string", "enum": ["low", "medium", "high"]},
          "mitigation": {"type": "string"}
        }
      }
    },
    "assumptions": {
      "type": "array",
      "items": {"type": "string"}
    },
    "open_questions": {
      "type": "array",
      "items": {"type": "string"}
    },
    "research": {
      "type": "object",
      "required": ["findings_incorporated", "unresolved_count"],
      "properties": {
        "findings_incorporated": {
          "type": "integer",
          "minimum": 0,
          "description": "Number of findings from research-dossier.md incorporated"
        },
        "external_research_used": {
          "type": "array",
          "items": {"type": "string"},
          "description": "List of external research sources incorporated"
        },
        "unresolved_topics": {
          "type": "array",
          "items": {"type": "string"},
          "description": "Research opportunities identified but not addressed"
        },
        "unresolved_count": {
          "type": "integer",
          "minimum": 0,
          "description": "Count of unresolved research topics"
        }
      },
      "description": "Research incorporation tracking"
    }
  }
}
```

### A.7 specify/prompt/main.md - Transformed Stage Prompt

**File**: `enhance/sample/sample_1/wf-spec/stages/specify/prompt/main.md`

This is the transformation of `/plan-1b-specify.md`. Key changes:
- **REMOVED**: YAML frontmatter, `$ARGUMENTS`, `--simple` flag parsing
- **REMOVED**: Plan folder discovery logic (steps 1, 1a, 1b, 2)
- **REMOVED**: File path determination (PLAN_DIR, SPEC_FILE variables)
- **REMOVED**: References to other commands (`/plan-2-clarify`, `/plan-1a-explore`)
- **KEPT**: Core specification structure and content requirements
- **ADDED**: Stage-aware input/output references
- **RESTORED**: External Research section (tracks what external research was used)
- **RESTORED**: Unresolved Research section (flags gaps before architecture phase)
- **RESTORED**: Phases field for CS-4+ features (rollout/rollback planning)

```markdown
# Feature Specification Stage

Create a feature specification from the research findings provided in your inputs.

## Your Inputs

Read these files from `../inputs/`:
- `research-dossier.md` - Comprehensive research with findings, dependencies, patterns
- `findings.json` - Structured findings data
- `user-description.md` (if present) - Additional user context

## Your Outputs

Write these files:
- `../run/output-files/spec.md` - The feature specification document
- `../run/output-data/spec-metadata.json` - Structured metadata (see schema)
- `../run/output-data/wf-result.json` - Stage completion status
- `../run/runtime-inputs/read-files.json` - Files you read during execution

## Specification Structure

Create `spec.md` with these sections (in order):

### 1. Title and Mode
```markdown
# <Feature Title>

**Mode**: Simple
```

### 2. Research Context
Summarize key findings from `research-dossier.md`:
- Components affected
- Critical dependencies
- Modification risks
- Link to research dossier

### 3. Summary
Short WHAT/WHY overview (2-3 sentences)

### 4. Goals
Bullet list of desired outcomes and user value. Informed by research findings.

### 5. Non-Goals
Explicitly out-of-scope behavior. Informed by research boundaries.

### 6. Complexity
Use the CS 1-5 scoring system:

| Dimension | Score 0-2 | Description |
|-----------|-----------|-------------|
| S (Surface) | Files touched | 0=one, 1=multiple, 2=cross-cutting |
| I (Integration) | External deps | 0=internal, 1=one external, 2=multiple |
| D (Data/State) | Schema changes | 0=none, 1=minor, 2=non-trivial |
| N (Novelty) | Clarity | 0=well-specified, 1=some ambiguity, 2=discovery |
| F (Non-Functional) | Perf/security | 0=standard, 1=moderate, 2=strict |
| T (Testing) | Test depth | 0=unit only, 1=integration, 2=staged rollout |

Total = S+I+D+N+F+T → CS mapping: 0-2=CS-1, 3-4=CS-2, 5-7=CS-3, 8-9=CS-4, 10-12=CS-5

Include:
- **Score**: CS-{1-5}
- **Total**: Sum of all dimension scores (0-12)
- **Breakdown**: S=X, I=X, D=X, N=X, F=X, T=X
- **Confidence**: 0.00-1.00
- **Assumptions**: List assumptions made
- **Dependencies**: External blockers
- **Risks**: Complexity-related risks
- **Phases** (CS-4+ only): Suggested implementation phases with feature flags and rollback plan

### 7. Acceptance Criteria
Numbered, testable scenarios:
```markdown
1. **AC-01**: [Observable outcome that can be tested]
2. **AC-02**: [Another testable scenario]
```

### 8. Risks & Assumptions

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|

### 9. Open Questions
List any unresolved questions as `[NEEDS CLARIFICATION: ...]` markers.

### 10. ADR Seeds (Optional)
If architectural decisions are implied:
- Decision Drivers
- Candidate Alternatives (A, B, C)
- Stakeholders

### 11. External Research (if applicable)
If `research-dossier.md` references external research that was incorporated:
- **Incorporated**: List external research sources used (from research-dossier.md)
- **Key Findings**: Summary of external insights that informed this spec
- **Applied To**: Which spec sections benefited

### 12. Unresolved Research (if applicable)
If `research-dossier.md` identified external research opportunities that weren't addressed:
- **Topics**: List unresolved opportunities from research-dossier.md
- **Impact**: How this uncertainty affects the spec
- **Recommendation**: "Consider addressing before architecture phase"

⚠️ If unresolved research exists, add a warning banner after the title:
```markdown
⚠️ **Unresolved Research Opportunities**
The following external research topics were identified but not addressed:
- [Topic 1]: [Brief description]
Consider running external research before finalizing architecture.
```

### 13. Phases (for CS-4+ only)
If complexity score is CS-4 or CS-5, include:
- **Suggested Phases**: High-level breakdown of implementation phases
- **Feature Flags**: Required feature flags for staged rollout
- **Rollback Plan**: How to safely rollback if issues arise

## Structured Output

Also write `spec-metadata.json` with the structured data. See `../schemas/spec-metadata.schema.json` for the required format.

Example:
```json
{
  "feature_name": "Workflow Composer CLI",
  "slug": "first-wf-build",
  "mode": "simple",
  "complexity": {
    "score": "CS-3",
    "total": 5,
    "breakdown": {"S": 1, "I": 1, "D": 1, "N": 1, "F": 0, "T": 1},
    "confidence": 0.85,
    "phases": null
  },
  "goals": ["Create compose command", "Create prepare-wf-stage command"],
  "acceptance_criteria": [
    {"id": "AC-01", "description": "compose creates run folder", "testable": true}
  ],
  "research": {
    "findings_incorporated": 15,
    "external_research_used": ["API best practices 2024"],
    "unresolved_topics": [],
    "unresolved_count": 0
  }
}
```

## Quality Gates

Before completing:
- [ ] All mandatory sections present in spec.md
- [ ] Acceptance criteria are testable (observable outcomes)
- [ ] Complexity score justified with breakdown
- [ ] Research findings referenced where applicable
- [ ] spec-metadata.json validates against schema
- [ ] No implementation details (no stack/framework choices)

## Completion

Write `wf-result.json`:
```json
{
  "status": "success",
  "completed_at": "2026-01-18T14:30:00Z",
  "stage_id": "specify",
  "error": null,
  "metrics": {
    "goals_count": 4,
    "acceptance_criteria_count": 7,
    "open_questions_count": 0,
    "research_findings_incorporated": 15
  }
}
```

Ensure `read-files.json` is complete (you've been writing to it as you read files).
```

### A.8 Run Folder Structure (Compose Output)

When `chainglass compose ./wf-spec --output ./run` executes, it creates:

```
run/run-2026-01-18-001/
├── wf-run.json                       # Run metadata (A.9)
└── stages/
    ├── explore/
    │   ├── inputs/
    │   │   └── (empty - user provides user-description.md)
    │   ├── prompt/
    │   │   ├── wf.md                 # Copied from templates/
    │   │   └── main.md               # Copied from stages/explore/prompt/
    │   ├── run/
    │   │   ├── output-files/         # Empty, created
    │   │   ├── output-data/          # Empty, created; stage writes output-params.json here
    │   │   └── runtime-inputs/       # Empty, created
    │   ├── schemas/
    │   │   ├── wf-result.schema.json      # Copied from shared schemas/
    │   │   ├── findings.schema.json       # Copied from stages/explore/schemas/
    │   │   ├── explore-metrics.schema.json # Copied from stages/explore/schemas/
    │   │   └── read-files.schema.json       # Copied from stages/explore/schemas/
    │   └── stage-config.yaml         # EXTRACTED from wf.yaml during compose
    └── specify/
        ├── inputs/
        │   ├── (files copied by prepare-wf-stage)
        │   └── params.json           # Parameters resolved by prepare-wf-stage
        ├── prompt/
        │   ├── wf.md                 # Copied from templates/
        │   └── main.md               # Copied from stages/specify/prompt/
        ├── run/
        │   ├── output-files/         # Empty, created
        │   ├── output-data/          # Empty, created
        │   └── runtime-inputs/       # Empty, created
        ├── schemas/
        │   ├── wf-result.schema.json     # Copied from shared schemas/
        │   ├── spec-metadata.schema.json # Copied from stages/specify/schemas/
        │   └── read-files.schema.json      # Copied from stages/specify/schemas/
        └── stage-config.yaml         # EXTRACTED from wf.yaml during compose
```

**Note**: `stage-config.yaml` is extracted from the stage's definition in `wf.yaml` during compose. This gives each stage a self-contained config for the LLM to read during execution.

### A.9 wf-run.json - Run Metadata

**File**: Created at `{output}/run-{date}-{ordinal}/wf-run.json`

```json
{
  "run_id": "run-2026-01-18-001",
  "created_at": "2026-01-18T12:00:00Z",
  "workflow": {
    "name": "explore-specify",
    "version": "1.0",
    "source": "enhance/sample/sample_1/wf-spec"
  },
  "stages": [
    {
      "id": "explore",
      "status": "pending",
      "started_at": null,
      "completed_at": null
    },
    {
      "id": "specify",
      "status": "pending",
      "started_at": null,
      "completed_at": null
    }
  ]
}
```

### A.10 Compose Algorithm

```python
def compose(wf_spec_path: Path, output_path: Path) -> Path:
    """
    1. Load and validate wf.yaml against wf.schema.json
    2. Create run folder: output_path/run-{date}-{ordinal}/
    3. Write wf-run.json with initial metadata
    4. For each stage in wf.yaml.stages (in order):
       a. Create stage folder: stages/{stage.id}/
       b. Create subdirs: inputs/, prompt/, run/output-files/,
          run/output-data/, run/runtime-inputs/, schemas/
       c. EXTRACT stage config from wf.yaml and write to stage-config.yaml:
          - Extract: id, name, description, inputs, parameters, output_parameters, outputs, prompt
          - Write as YAML to stages/{stage.id}/stage-config.yaml
       d. Copy prompt/main.md from wf-spec/stages/{stage.id}/prompt/
       e. Copy stage-specific schemas from wf-spec/stages/{stage.id}/schemas/
       f. For each shared_template in wf.yaml:
          - Copy source to target location in stage
    5. Return path to created run folder
    """
```

**Stage config extraction example**:

Input (from wf.yaml):
```yaml
- id: "explore"
  name: "Codebase Research"
  description: "Deep-dive research..."
  inputs: {...}
  outputs: {...}
  prompt: {...}
```

Output (stages/explore/stage-config.yaml):
```yaml
# Extracted from wf.yaml during compose
# Source: enhance/sample/sample_1/wf-spec/wf.yaml
# Stage: explore

id: "explore"
name: "Codebase Research"
description: "Deep-dive research into existing codebase functionality"

inputs:
  required:
    - name: "user-description.md"
      path: "inputs/user-description.md"
      description: "User-provided research query or feature description"
  optional: []

outputs:
  files:
    - name: "research-dossier.md"
      path: "run/output-files/research-dossier.md"
      description: "Comprehensive research report"
  data:
    - name: "wf-result.json"
      path: "run/output-data/wf-result.json"
      schema: "schemas/wf-result.schema.json"
      description: "Stage execution status"
      required: true
    - name: "findings.json"
      path: "run/output-data/findings.json"
      schema: "schemas/findings.schema.json"
      description: "Structured findings for downstream consumption"
      required: true

prompt:
  entry: "prompt/wf.md"
  main: "prompt/main.md"
```

### A.11 prepare-wf-stage Algorithm

**CLI Signature**:
```
chainglass prepare-wf-stage <stage_id> --run-dir <path> [--dry-run]
```

**Options**:
- `--dry-run`: Validate that all inputs and parameters can be satisfied without copying/writing

```python
def prepare_wf_stage(
    stage_id: str,
    run_dir: Path,
    dry_run: bool = False
) -> PrepareResult:
    """
    Prepare a stage by:
    1. Copying inputs that come from other stages
    2. Resolving parameters by querying prior stage JSON outputs
    3. Writing resolved parameters to inputs/params.json

    Algorithm:
    1. Load wf-run.json from run_dir
    2. Load wf.yaml from wf-run.json.workflow.source
    3. Find stage by stage_id in wf.yaml.stages
    4. result = PrepareResult(status="ready", copied=[], parameters={}, errors=[])

    5. COPY INPUTS: For each input with from_stage:
       a. source_path = run_dir/stages/{input.from_stage}/{input.source}
       b. target_path = run_dir/stages/{stage_id}/{input.path}
       c. Check source exists (error if required and missing)
       d. If not dry_run: copy source_path to target_path
       e. result.copied.append(input.name)

    6. RESOLVE PARAMETERS: For each parameter in stage.parameters:
       a. If param.output_parameter is set (preferred):
          - Load run_dir/stages/{param.from_stage}/run/output-data/output-params.json
          - result.parameters[param.name] = output_params[param.output_parameter]
       b. Else if param.source + param.query set (direct query):
          - source_path = run_dir/stages/{param.from_stage}/{param.source}
          - Load JSON from source_path
          - Execute query (param.query) against JSON
            - Use dot notation: "summary.total_findings"
            - Support array indexing: "components[0].name"
          - result.parameters[param.name] = extracted_value
       c. Error if source/output-params.json missing or parameter not found

    7. WRITE PARAMS: If not dry_run and parameters exist:
       - Write result.parameters to stages/{stage_id}/inputs/params.json

    8. Return result
    """
```

**Resolution Methods**:

1. **output_parameter (preferred)**: Look up by name in source stage's `output-params.json`
   - Simple, decoupled - consumer doesn't know internal structure
   - Stage declares what it publishes; consumer references by name

2. **source + query (fallback)**: Direct JSON path query
   - Dot notation: `summary.total_findings` → `data["summary"]["total_findings"]`
   - Array index: `components[0].name` → `data["components"][0]["name"]`
   - Nested: `recommendations.complexity.suggested_score`

**Output Format**:

```json
{
  "status": "ready",
  "stage_id": "specify",
  "inputs_from_stages": [
    {"name": "research-dossier.md", "from_stage": "explore", "status": "OK"},
    {"name": "findings.json", "from_stage": "explore", "status": "OK"}
  ],
  "copied": ["research-dossier.md", "findings.json"],
  "parameters_resolved": [
    {"name": "total_findings", "from_stage": "explore", "via": "output_parameter", "value": 15},
    {"name": "critical_count", "from_stage": "explore", "via": "output_parameter", "value": 2},
    {"name": "top_component", "from_stage": "explore", "via": "output_parameter", "value": "auth/session.py"},
    {"name": "complexity_score", "from_stage": "explore", "via": "output_parameter", "value": "CS-3"}
  ],
  "parameters": {
    "total_findings": 15,
    "critical_count": 2,
    "top_component": "auth/session.py",
    "complexity_score": "CS-3"
  },
  "params_written_to": "inputs/params.json",
  "errors": [],
  "summary": "Stage 'specify' prepared: 2 inputs copied, 4 parameters resolved via output_parameter"
}
```

**Blocked Output Example** (when explore stage not complete):

```json
{
  "status": "blocked",
  "stage_id": "specify",
  "inputs_from_stages": [
    {"name": "research-dossier.md", "from_stage": "explore", "status": "MISSING"},
    {"name": "findings.json", "from_stage": "explore", "status": "MISSING"}
  ],
  "copied": [],
  "errors": [
    {
      "input": "research-dossier.md",
      "from_stage": "explore",
      "source": "run/output-files/research-dossier.md",
      "status": "FAIL",
      "message": "Required input not found: research-dossier.md",
      "action": "Complete stage 'explore' first. Expected output: run/output-files/research-dossier.md"
    },
    {
      "input": "findings.json",
      "from_stage": "explore",
      "source": "run/output-data/findings.json",
      "status": "FAIL",
      "message": "Required input not found: findings.json",
      "action": "Complete stage 'explore' first. Expected output: run/output-data/findings.json"
    }
  ],
  "summary": "Stage 'specify' blocked: 2 missing inputs from 'explore'"
}
```

**Dry-run Output**:

```json
{
  "status": "ready",
  "stage_id": "specify",
  "dry_run": true,
  "inputs_from_stages": [
    {"name": "research-dossier.md", "from_stage": "explore", "status": "OK"},
    {"name": "findings.json", "from_stage": "explore", "status": "OK"}
  ],
  "validated": ["research-dossier.md", "findings.json"],
  "copied": [],
  "summary": "Stage 'specify' ready: 2 inputs available (dry-run, nothing copied)"
}
```

### A.12 Validate Algorithm

**Purpose**: Validate that a stage has completed successfully with all required outputs present, non-empty, and schema-compliant. Designed to be called by an LLM at the end of stage execution.

```python
def validate_stage(stage_dir: Path) -> ValidationResult:
    """
    1. Load stage-config.yaml from stage_dir
    2. Initialize result = ValidationResult(status="pass", checks=[], errors=[])
    3. For each output category in ["files", "data", "runtime"]:
       a. For each output in stage_config.outputs[category]:
          i.   output_path = stage_dir / output["path"]
          ii.  Check 1: File exists
               - If missing and required:
                 error = {
                   "check": "file_exists",
                   "path": output["path"],
                   "status": "FAIL",
                   "message": f"Missing required output: {output['path']}",
                   "action": "Write this file before completing the stage."
                 }
                 result.errors.append(error)
                 result.status = "fail"
                 continue  # Skip other checks for this file
          iii. Check 2: File is not empty
               - If file.stat().st_size == 0:
                 error = {
                   "check": "file_not_empty",
                   "path": output["path"],
                   "status": "FAIL",
                   "message": f"Output file is empty: {output['path']}",
                   "action": "Write content to this file."
                 }
                 result.errors.append(error)
                 result.status = "fail"
                 continue
          iv.  Check 3: Schema validation (if schema declared)
               - If "schema" in output:
                 schema_path = stage_dir / output["schema"]
                 schema = json.load(schema_path)
                 data = json.load(output_path)
                 try:
                   jsonschema.validate(data, schema)
                   result.checks.append({
                     "check": "schema_valid",
                     "path": output["path"],
                     "schema": output["schema"],
                     "status": "PASS"
                   })
                 except ValidationError as e:
                   error = {
                     "check": "schema_valid",
                     "path": output["path"],
                     "schema": output["schema"],
                     "status": "FAIL",
                     "message": f"Schema validation failed: {e.message}",
                     "json_path": str(e.absolute_path),
                     "action": f"Fix the JSON structure. Error at '{e.absolute_path}': {e.message}. See {output['schema']} for required format."
                   }
                   result.errors.append(error)
                   result.status = "fail"
    4. EXTRACT OUTPUT PARAMETERS (if validation passed and output_parameters declared):
       a. If result.status == "pass" and stage_config.output_parameters exists:
          output_params = {"stage_id": stage_id, "published_at": now(), "parameters": {}}
          For each param in stage_config.output_parameters:
            - source_path = stage_dir / param.source
            - Load JSON from source_path
            - Execute query (param.query) against JSON
            - output_params["parameters"][param.name] = extracted_value
          Write output_params to stage_dir / "run/output-data/output-params.json"
          result.output_params_written = True

    5. Generate summary
       result.summary = f"Stage '{stage_id}': {len(result.checks)} checks passed, {len(result.errors)} errors"
    6. Return result
    """
```

**Output Format (JSON)**:

```json
{
  "status": "pass",
  "stage_id": "explore",
  "checks": [
    {"check": "file_exists", "path": "run/output-files/research-dossier.md", "status": "PASS"},
    {"check": "file_not_empty", "path": "run/output-files/research-dossier.md", "status": "PASS"},
    {"check": "file_exists", "path": "run/output-data/wf-result.json", "status": "PASS"},
    {"check": "file_not_empty", "path": "run/output-data/wf-result.json", "status": "PASS"},
    {"check": "schema_valid", "path": "run/output-data/wf-result.json", "schema": "schemas/wf-result.schema.json", "status": "PASS"},
    {"check": "file_exists", "path": "run/output-data/findings.json", "status": "PASS"},
    {"check": "file_not_empty", "path": "run/output-data/findings.json", "status": "PASS"},
    {"check": "schema_valid", "path": "run/output-data/findings.json", "schema": "schemas/findings.schema.json", "status": "PASS"},
    {"check": "file_exists", "path": "run/runtime-inputs/read-files.json", "status": "PASS"},
    {"check": "file_not_empty", "path": "run/runtime-inputs/read-files.json", "status": "PASS"},
    {"check": "schema_valid", "path": "run/runtime-inputs/read-files.json", "schema": "schemas/read-files.schema.json", "status": "PASS"}
  ],
  "output_params_written": true,
  "output_params": {
    "total_findings": 15,
    "critical_count": 2,
    "top_component": "auth/session.py",
    "complexity_score": "CS-3"
  },
  "errors": [],
  "summary": "Stage 'explore': 11 checks passed, 0 errors, 4 output_parameters published"
}
```

**Failure Output Example**:

```json
{
  "status": "fail",
  "stage_id": "explore",
  "checks": [
    {"check": "file_exists", "path": "run/output-files/research-dossier.md", "status": "PASS"},
    {"check": "file_not_empty", "path": "run/output-files/research-dossier.md", "status": "PASS"}
  ],
  "errors": [
    {
      "check": "file_exists",
      "path": "run/output-data/wf-result.json",
      "status": "FAIL",
      "message": "Missing required output: run/output-data/wf-result.json",
      "action": "Write this file before completing the stage."
    },
    {
      "check": "file_not_empty",
      "path": "run/output-data/findings.json",
      "status": "FAIL",
      "message": "Output file is empty: run/output-data/findings.json",
      "action": "Write content to this file."
    },
    {
      "check": "schema_valid",
      "path": "run/runtime-inputs/read-files.json",
      "schema": "schemas/read-files.schema.json",
      "status": "FAIL",
      "message": "Schema validation failed: 'files_read' is a required property",
      "json_path": "",
      "action": "Fix the JSON structure. Error at '': 'files_read' is a required property. See schemas/read-files.schema.json for required format."
    }
  ],
  "summary": "Stage 'explore': 2 checks passed, 3 errors"
}
```

**CLI Output (Human-Readable)**:

```
╭─ Stage Validation: explore ─────────────────────────────────╮
│                                                              │
│  ✓ run/output-files/research-dossier.md                     │
│  ✗ run/output-data/wf-result.json                           │
│    └─ MISSING: Write this file before completing the stage. │
│  ✗ run/output-data/findings.json                            │
│    └─ EMPTY: Write content to this file.                    │
│  ✗ run/runtime-inputs/read-files.json                         │
│    └─ SCHEMA: 'files_read' is a required property           │
│       Action: See schemas/read-files.schema.json              │
│                                                              │
│  Result: FAIL (2 passed, 3 errors)                          │
╰──────────────────────────────────────────────────────────────╯
```

### A.13 Test Fixtures for Phase 4

**Location**: `enhance/sample/sample_1/test-fixtures/`

These fixtures are created during Phase 4 implementation to test the validate command.

```
enhance/sample/sample_1/test-fixtures/
├── valid-stage/                  # Copy of 01-explore with all outputs present
│   ├── stage-config.yaml
│   ├── run/
│   │   ├── output-files/
│   │   │   └── research-dossier.md     # Valid content
│   │   ├── output-data/
│   │   │   ├── wf-result.json          # Valid, schema-compliant
│   │   │   └── findings.json           # Valid, schema-compliant
│   │   └── runtime-inputs/
│   │       └── read-files.json           # Valid, schema-compliant
│   └── schemas/
│       ├── wf-result.schema.json
│       ├── findings.schema.json
│       └── read-files.schema.json
│
└── invalid-stage/                # Deliberately broken stage
    ├── stage-config.yaml         # Same as valid-stage
    ├── run/
    │   ├── output-files/
    │   │   └── (empty - research-dossier.md missing)
    │   ├── output-data/
    │   │   ├── wf-result.json          # Empty file (0 bytes)
    │   │   └── findings.json           # Invalid JSON structure
    │   └── runtime-inputs/
    │       └── (empty - read-files.json missing)
    └── schemas/
        └── (same as valid-stage)
```

**Expected validate output for invalid-stage:**

```json
{
  "status": "fail",
  "stage_id": "invalid-stage",
  "checks": [],
  "errors": [
    {
      "check": "file_exists",
      "path": "run/output-files/research-dossier.md",
      "status": "FAIL",
      "message": "Missing required output: run/output-files/research-dossier.md",
      "action": "Write this file before completing the stage."
    },
    {
      "check": "file_not_empty",
      "path": "run/output-data/wf-result.json",
      "status": "FAIL",
      "message": "Output file is empty: run/output-data/wf-result.json",
      "action": "Write content to this file."
    },
    {
      "check": "schema_valid",
      "path": "run/output-data/findings.json",
      "schema": "schemas/findings.schema.json",
      "status": "FAIL",
      "message": "Schema validation failed: 'findings' is a required property",
      "action": "Fix the JSON structure. See schemas/findings.schema.json for required format."
    },
    {
      "check": "file_exists",
      "path": "run/runtime-inputs/read-files.json",
      "status": "FAIL",
      "message": "Missing required output: run/runtime-inputs/read-files.json",
      "action": "Write this file before completing the stage."
    }
  ],
  "summary": "Stage 'invalid-stage': 0 checks passed, 4 errors"
}
```

---

## Change Footnotes Ledger

[^1]: Phase 1 Task 1.1 - Created wf-spec directory structure
  - `file:enhance/sample/sample_1/wf-spec/`

[^2]: Phase 1 Task 1.2 - Created wf.yaml workflow definition
  - `file:enhance/sample/sample_1/wf-spec/wf.yaml`

[^3]: Phase 1 Task 1.3 - Created wf.md bootstrap template
  - `file:enhance/sample/sample_1/wf-spec/templates/wf.md`

[^4]: Phase 1 Task 1.4 - Created wf-result.schema.json
  - `file:enhance/sample/sample_1/wf-spec/schemas/wf-result.schema.json`

[^5]: Phase 1 Task 1.4b - Created wf.schema.json
  - `file:enhance/sample/sample_1/wf-spec/schemas/wf.schema.json`

[^6]: Phase 1 Task 1.5 - Copied explore stage assets
  - `file:enhance/sample/sample_1/wf-spec/stages/explore/prompt/main.md`
  - `file:enhance/sample/sample_1/wf-spec/stages/explore/schemas/findings.schema.json`
  - `file:enhance/sample/sample_1/wf-spec/stages/explore/schemas/read-files.schema.json`

[^7]: Phase 1 Task 1.6 - Created explore-metrics.schema.json
  - `file:enhance/sample/sample_1/wf-spec/stages/explore/schemas/explore-metrics.schema.json`

[^8]: Phase 1 Task 1.7 - Created spec-metadata.schema.json
  - `file:enhance/sample/sample_1/wf-spec/stages/specify/schemas/spec-metadata.schema.json`

[^9]: Phase 1 Task 1.8 - Copied read-files.schema.json to specify
  - `file:enhance/sample/sample_1/wf-spec/stages/specify/schemas/read-files.schema.json`

[^10]: Phase 1 Task 1.9 - Transformed specify main.md with Stage Context
  - `file:enhance/sample/sample_1/wf-spec/stages/specify/prompt/main.md`

[^11]: Phase 1 Task 1.10 - Verified wf-spec completeness
  - All files parse correctly (YAML, JSON)
  - wf.yaml validates against wf.schema.json

---

**Next steps:**
- **Validate plan**: `/plan-4-complete-the-plan` (recommended)
- **Start Phase 1**: `/plan-6-implement-phase --plan "docs/plans/010-first-wf-build/first-wf-build-plan.md" --phase 1`
- **Phase execution order**: Phase 1 → Phase 2 → Phase 3 → Phase 4

**Path Convention**: All paths in this plan are relative to the repository root (`/Users/jordanknight/github/tools/`). Use `$(git rev-parse --show-toplevel)` to resolve to absolute paths when executing commands.

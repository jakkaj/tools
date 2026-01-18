# Research Report: Workflow Composer CLI Design

**Generated**: 2026-01-18T12:30:00Z
**Research Query**: "Design a simple schema that defines a WF and two stages, with a CLI tool in enhance/src for composing run folders"
**Mode**: Pre-Plan Research
**Location**: docs/plans/010-first-wf-build/research-dossier.md
**FlowSpace**: Available
**Findings**: 75 total (across 7 subagents)

---

## Executive Summary

### What It Does
The workflow composer CLI will transform workflow specification folders (wf-spec) into executable run directories, enabling coding agents to process stages in a deterministic, schema-validated pipeline. The tool bridges the gap between static workflow definitions and dynamic stage execution.

### Business Purpose
Enable automated execution of the `/plan-*` command ecosystem as a structured workflow system where each stage (explore, specify, clarify, architect, etc.) has explicit inputs, outputs, and validation contracts.

### Key Insights
1. **The sample stage (01-explore) is a validated proof-of-concept** - the folder structure, stage-config.json contract, and prompt transformation pattern are production-ready
2. **Two CLI commands needed**: `compose` (create full run from wf-spec) and `prepare-wf-stage` (prepare single stage with inputs from prior stage)
3. **Three-tier output structure is mandatory**: output-files/ (markdown), output-data/ (JSON), runtime-inputs/ (manifest)

### Quick Stats
- **Reference Files**: 15 core documents analyzed
- **Existing Code**: create_run.py (196 lines), validate_stage_outputs.py (257 lines)
- **Test Coverage**: Unit tests exist for CodingToolsInstaller; integration tests in shell scripts
- **Complexity**: CS-3 (Medium) - 5-7 files, YAML parsing, JSON Schema validation
- **Prior Learnings**: 15 relevant discoveries from previous implementations

---

## How It Currently Works

### Entry Points
The current sample demonstrates a manual execution flow:

| Entry Point | Type | Location | Purpose |
|-------------|------|----------|---------|
| create_run.py | Script | enhance/sample/create_run.py | Create clean run from sample template |
| validate | Script | enhance/tools/validate | Validate stage outputs against schemas |
| wf.md | Prompt | stages/01-explore/prompt/wf.md | Bootstrap agent execution |

### Core Execution Flow

1. **Sample Creation** (create_run.py)
   - Copy sample_1 to enhance/run/{ordinal}
   - Strip output artifacts (OUTPUT_DIRS: run/output-files, run/output-data, run/runtime-inputs)
   - Update wf-run.json with run metadata

2. **Stage Execution** (manual agent)
   - Read wf.md entry point
   - Load stage-config.json to understand contract
   - Read inputs from inputs/ directory
   - Execute main.md instructions
   - Write outputs to run/ directories

3. **Validation** (validate_stage_outputs.py)
   - Find output/schema pairs from stage-config.json
   - Validate each output against its JSON Schema
   - Report success/failure with ANSI colors

### Data Flow
```mermaid
graph LR
    A[wf-spec/] -->|compose| B[run/{ordinal}/]
    B --> C[stages/01-explore/]
    C --> D[inputs/]
    C --> E[prompt/]
    C --> F[run/output-*/]
    F -->|prepare-wf-stage| G[stages/02-specify/inputs/]
```

### State Management
- **wf-run.json**: Run-level metadata (run_id, created_at, source_sample, status)
- **stage-config.json**: Per-stage contract (inputs, outputs, schemas, prompts)
- **wf-result.json**: Stage completion status (required for every stage)

---

## Architecture & Design

### Component Map

```
enhance/
├── sample/
│   ├── sample_1/              # Template for runs
│   │   └── runs/run-2024-01-18-001/
│   │       ├── wf-run.json
│   │       └── stages/01-explore/
│   └── create_run.py          # Current run creator
├── run/
│   ├── 001/                   # Created runs
│   ├── 002/
│   └── ...
├── tools/
│   ├── validate              # Bash wrapper
│   └── validate_stage_outputs.py
└── src/                       # NEW: CLI location
    └── wf_composer/           # Proposed module
        ├── __init__.py
        ├── cli.py             # Entry point
        ├── composer.py        # Compose logic
        └── preparer.py        # Stage preparation
```

### Design Patterns Identified

1. **Manager Class Pattern** (from setup_manager.py)
   - Complex operations organized as manager classes
   - @dataclass for result objects (InstallResult → StageResult)
   - Accumulate results, show summary at end

2. **Three-Category Input Model** (from workflow-schema-simple.md)
   - inputs/ - declared dependencies (pre-assembled)
   - runtime-inputs/ - audit log (written during execution)
   - outputs - deliverables (validated post-execution)

3. **Metadata-Driven Validation** (from validate_stage_outputs.py)
   - Read stage-config.json to discover contracts
   - Find output/schema pairs
   - Validate with jsonschema Draft202012Validator

4. **Path Placeholder System** (from dynamic sub-workflow spec)
   - `{subwf}/` prefix for intra-workflow references
   - No prefix for external references
   - Resolution happens at expansion time

### System Boundaries

- **Internal**: enhance/src/, enhance/sample/, enhance/run/
- **External**: Coding agents that execute prompts
- **Integration**: FlowSpace MCP for codebase exploration, validate_stage_outputs.py for validation

---

## Dependencies & Integration

### What This Depends On

#### Internal Dependencies
| Dependency | Type | Purpose | Risk if Changed |
|------------|------|---------|-----------------|
| sample_1 folder | Required | Template for 01-explore | Must update template |
| stage-config.json schema | Required | Contract definition | Breaking change |
| validate_stage_outputs.py | Required | Output validation | Must maintain compatibility |

#### External Dependencies
| Service/Library | Version | Purpose | Criticality |
|-----------------|---------|---------|-------------|
| PyYAML | 6.0+ | Parse wf.yaml definitions | High |
| jsonschema | 4.0+ | Draft202012Validator | High |
| pathlib | stdlib | Path operations | High |
| argparse | stdlib | CLI parsing | High |
| rich | 13.0+ | Console output (optional) | Medium |

### What Depends on This

#### Direct Consumers
- **Coding Agents**: Execute prompt/wf.md after compose
- **Validation Tool**: Runs post-execution to verify outputs
- **Future Orchestrator**: Will automate stage sequencing

---

## Quality & Testing

### Current Test Coverage
- **Unit Tests**: `tests/test_coding_tools_installer.py` (20+ tests)
- **Integration Tests**: Shell scripts in `tests/install/`
- **Validation Tests**: Manual runs of validate_stage_outputs.py
- **Gaps**: No automated tests for create_run.py or workflow structure

### Test Strategy for CLI
1. **Unit Tests**: Use pytest with `tmp_path` fixture for folder operations
2. **Integration Tests**: Execute CLI, verify folder structure, validate outputs
3. **Idempotency Tests**: Run compose twice, verify identical results

### Known Issues & Technical Debt
| Issue | Severity | Location | Impact |
|-------|----------|----------|--------|
| create_run.py not in CLI | Medium | enhance/sample/ | Standalone script, not integrated |
| No wf.yaml parser | High | Not implemented | Can't read workflow definitions |
| Only 01-explore sample | Medium | sample_1/ | Need 02-specify sample |

---

## Modification Considerations

### Safe to Modify
1. **enhance/src/** (new directory): Create fresh implementation
2. **enhance/tools/**: Add new CLI tools
3. **Sample prompts**: Adapt /plan-1b-specify to stage format

### Modify with Caution
1. **stage-config.json schema**: Changes affect validation
2. **Output folder structure**: Existing outputs depend on paths
3. **wf.md bootstrap prompt**: Agents parse this structure

### Extension Points
1. **New stages**: Follow 01-explore pattern for 02-specify, 03-clarify
2. **Additional schemas**: Add to schemas/ directory
3. **CLI subcommands**: Extend argparse with new commands

---

## Prior Learnings (From Previous Implementations)

**IMPORTANT**: These are discoveries from previous work in this codebase. They represent institutional knowledge - gotchas, unexpected behaviors, and insights that past implementations uncovered. **Pay attention to these.**

### PL-01: CLI Framework Choice - argparse Standard
**Source**: setup_manager.py, cli.py
**Type**: decision
**Learning**: The repository consistently uses Python's `argparse` module rather than `click` or `typer` for CLI tools. While argparse is verbose, it's the established standard in this codebase.
**Action**: Follow established pattern for CLI interface; use `RawDescriptionHelpFormatter` for help text.

---

### PL-02: Folder Structure as Declarative Config
**Source**: workflow-schema-simple.md
**Type**: insight
**Learning**: The workflow schema treats folder structure as declarative configuration, not runtime artifacts. Each stage has a rigid structure: `inputs/`, `prompt/`, `run/output-files/`, `run/output-data/`, `run/runtime-inputs/`. This enables pre-execution validation and clear contracts.
**Action**: Enforce structure strictly. Don't allow stages to write to arbitrary locations. Use absolute paths everywhere.

---

### PL-03: Prompt Transformation Pattern
**Source**: wf-stage-sample-plan.md (lines 44-134)
**Type**: workaround
**Learning**: Transforming `/plan-1a-explore.md` (830 lines) to `prompt/main.md` (~450 lines) required:
- **REMOVE**: YAML frontmatter, command argument parsing, plan folder management, output routing logic, "STOP AND WAIT" sections
- **KEEP**: Core research logic (FlowSpace detection, subagent definitions, synthesis phase, report template)
- **ADD**: Stage context at top (read stage-config.json, read inputs/, output locations)
**Action**: Apply same pattern to /plan-1b-specify transformation. Separate orchestration concerns from business logic.

---

### PL-04: JSON Schema as Input/Output Contracts
**Source**: stage-config.json, validate_stage_outputs.py
**Type**: insight
**Learning**: Stage-config.json declares both what inputs are expected and what outputs should be produced. This enables validation before execution and progress tracking.
**Action**: Validate stage config before execution. Use JSON Schema validation for all data outputs.

---

### PL-05: Absolute Paths Required Everywhere
**Source**: Plan documentation, execution logs
**Type**: gotcha
**Learning**: Relative paths cause issues with cwd changes between bash calls. Agent threads reset cwd between operations.
**Action**: Normalize all file paths to absolute using `Path.resolve()`. Never trust relative paths from user input.

---

### PL-06: Three-Tier Output Structure
**Source**: workflow-schema-simple.md (lines 75-102)
**Type**: insight
**Learning**: Stages produce outputs in three distinct locations with different semantics:
1. **output-files/**: Human-readable markdown/documentation
2. **output-data/**: Machine-readable JSON for downstream consumption
3. **runtime-inputs/**: Audit log of files actually read (manifest.json)
**Action**: Validate all three tiers, not just one. Don't treat them as interchangeable.

---

### PL-07: File Operations - Source/Distribution Paradigm
**Source**: CLAUDE.md, sync-to-dist.sh
**Type**: decision
**Learning**: The tools repository uses a "source/distribution paradigm" where:
- **Source of truth**: `agents/`, `scripts/`, `install/`
- **Auto-synced copy**: `src/jk_tools/` (never edit here)
**Action**: If building workflow file operations, establish clear source/generated separation. Implement idempotent syncing. Never assume generated files are canonical.

---

### PL-08: Manifest Tracking for Codebase Discovery
**Source**: Runtime inputs pattern, manifest.schema.json
**Type**: decision
**Learning**: The runtime-inputs/manifest.json pattern logs which files were discovered and read during execution. This enables reproducibility audit, drift detection, and performance tracking.
**Action**: Require manifest for every stage execution. This is critical for debugging and reproducibility.

---

### PL-09: Testing Strategy Drives Task Generation
**Source**: plan-2-clarify, plan-3-architect
**Type**: insight
**Learning**: The chosen testing strategy (TDD/TAD/Lightweight/Manual/Hybrid) directly impacts how tasks are generated.
**Action**: CLI must capture testing strategy early and propagate it through all downstream operations.

---

### PL-10: Dynamic Sub-Workflow Expansion
**Source**: workflow-schema-simple.md (lines 105-706)
**Type**: insight
**Learning**: Dynamic sub-workflows are expanded deterministically:
1. Seed stage produces `phases.json` with iteration count
2. Expansion logic (pure code, no LLM) creates all folders/configs
3. History accumulation pattern passes prior phase outputs forward
**Action**: If building iteration/loop support, separate expansion (pure code) from execution (LLM). Validate before running.

---

### PL-11: Input Type Taxonomy
**Source**: workflow-orchestrator-spec.md (lines 138-539)
**Type**: insight
**Learning**: The spec defines 28+ input types in 8 categories: Static, Dynamic, Interactive, External, Codebase, Memory, Sensitive, Meta. Each type needs different handling.
**Action**: Design input system to be type-aware. Validate based on type. Don't assume all inputs are just file paths.

---

### PL-12: Stage Completion Requires Multiple Outputs
**Source**: wf-stage-sample execution log
**Type**: gotcha
**Learning**: Stage completion requires THREE files:
1. **research-dossier.md** (human readable) - declares findings
2. **wf-result.json** (status metadata) - success/failure, timestamps, counts
3. **findings.json** (structured data) - array of finding objects
**Action**: Validate all output tiers after execution. Use strict schema validation.

---

### PL-13: Footnote System Enables Traceability
**Source**: Planning workflow documentation
**Type**: insight
**Learning**: The planning workflow uses footnotes [^1], [^2], etc. to link tasks → files → functions, creating a bidirectional audit trail.
**Action**: If tracking implementation changes, use footnote pattern. Collect FlowSpace node_ids during execution and link them back to tasks.

---

### PL-14: Empty vs. Sample Files
**Source**: wf-stage-sample implementation
**Type**: insight
**Learning**: The wf-stage-sample created sample output files (not empty placeholders) with realistic structures. Sample files aid understanding and catch schema mismatches early.
**Action**: Document expected output schemas with real examples. Empty `{}` placeholders are less useful than populated samples.

---

### PL-15: Error Handling - Remove "STOP AND WAIT"
**Source**: /plan-1a-explore transformation
**Type**: gotcha
**Learning**: The transformation removed a "CRITICAL: STOP AND WAIT" section. This was orchestration logic (appropriate for a command) but wrong for a stage prompt. Stages should NOT make decisions about workflow flow.
**Action**: Separate stage responsibility (produce outputs, report status) from orchestrator responsibility (validate outputs, decide next step).

---

### Prior Learnings Summary

| ID | Type | Key Insight | Action |
|----|------|-------------|--------|
| PL-01 | decision | Use argparse consistently | Follow CLI pattern |
| PL-02 | insight | Folder structure is config | Enforce strictly |
| PL-03 | workaround | Transform prompts carefully | Apply to 02-specify |
| PL-04 | insight | JSON Schema for contracts | Validate before/after |
| PL-05 | gotcha | Absolute paths required | Use Path.resolve() |
| PL-06 | insight | Three-tier outputs | Validate all tiers |
| PL-07 | decision | Source/dist separation | Implement sync rules |
| PL-08 | decision | Manifest tracking | Require for every stage |
| PL-09 | insight | Testing strategy matters | Propagate downstream |
| PL-10 | insight | Dynamic expansion | Separate from execution |
| PL-11 | insight | Input type taxonomy | Design type-aware system |
| PL-12 | gotcha | Multiple outputs required | Strict validation |
| PL-13 | insight | Footnote traceability | Use node_ids |
| PL-14 | insight | Sample files helpful | Provide real examples |
| PL-15 | gotcha | No STOP AND WAIT | Separate concerns |

---

## Critical Discoveries

### Critical Finding 01: wf.yaml Schema Design
**Impact**: Critical
**Source**: DC-01, IC-02
**What**: The wf.yaml must define stages, dependencies, and metadata
**Why It Matters**: This is the entry point for compose command
**Required Action**: Design and implement wf.yaml schema

### Critical Finding 02: Stage Config Contract
**Impact**: Critical
**Source**: IA-02, IC-04
**What**: stage-config.json is the single source of truth for each stage
**Why It Matters**: Validation, input assembly, output routing all depend on it
**Required Action**: Document schema, ensure consistency across stages

### Critical Finding 03: prepare-wf-stage for Inter-Stage Dependencies
**Impact**: High
**Source**: IA-05, IC-05, DC-02
**What**: Stage 02-specify inputs come from Stage 01-explore outputs
**Why It Matters**: Compose creates empty structure; prepare copies actual files
**Required Action**: Implement prepare-wf-stage command with --copy-inputs-from-stage

### Critical Finding 04: /plan-1b-specify Transformation Needed
**Impact**: High
**Source**: DE-03, DE-08
**What**: Must transform /plan-1b-specify.md into stages/02-specify/prompt/main.md
**Why It Matters**: Only 01-explore exists; need second stage for testing
**Required Action**: Apply same transformation pattern (remove ~400 lines of command infra)

---

## Recommendations

### If Modifying This System
1. Start with wf.yaml schema design - this drives everything else
2. Keep stage-config.json structure consistent with existing sample
3. Reuse validate_stage_outputs.py rather than reimplementing validation

### If Extending This System
1. Follow 01-explore folder structure exactly for new stages
2. Use JSON Schema for all data outputs
3. Include sample outputs in stage templates for developer understanding

### If Building the CLI
1. Use argparse with subcommands (compose, prepare-wf-stage, validate)
2. Follow rich console output pattern from setup_manager.py
3. Return structured results, show summary at end

---

## External Research Opportunities

During codebase exploration, the following knowledge gaps were identified that cannot be answered by reading more code. These require external research.

### Research Opportunity 1: Python CLI Framework Best Practices 2024+

**Why Needed**: Current codebase uses argparse, but typer/click may offer better UX
**Impact on Plan**: Could simplify CLI implementation with auto-docs and type hints
**Source Findings**: PS-02

**Ready-to-use prompt:**
```
/deepresearch "Compare argparse vs typer vs click for Python CLI tools in 2024. Focus on:
- Auto-generated help text quality
- Type hint integration
- Subcommand support
- Error message quality
- Migration path from argparse
Context: Building workflow composer CLI for LLM agent orchestration"
```

**Results location**: Save results to `docs/plans/010-first-wf-build/external-research/cli-frameworks.md`

### Research Opportunity 2: YAML Schema Validation Standards

**Why Needed**: Need to validate wf.yaml structure before compose
**Impact on Plan**: Choose between JSON Schema for YAML, Pydantic, or custom validation
**Source Findings**: DC-01, QT-03

**Ready-to-use prompt:**
```
/deepresearch "Best practices for YAML configuration schema validation in Python 2024. Compare:
- JSON Schema with PyYAML
- Pydantic v2 models
- Cerberus
- Custom validation
Focus on: error messages, complex nested structures, cross-field validation"
```

**Results location**: Save results to `docs/plans/010-first-wf-build/external-research/yaml-validation.md`

---

## Appendix: File Inventory

### Core Files
| File | Purpose | Lines |
|------|---------|-------|
| workflow-schema-simple.md | Folder structure spec | 706 |
| wf-stage-sample-plan.md | Implementation plan | 196 |
| stage-config.json | Stage contract sample | 55 |
| create_run.py | Run creation script | 196 |
| validate_stage_outputs.py | Validation tool | 257 |

### Schema Files
| File | Purpose |
|------|---------|
| wf-result.schema.json | Universal stage result |
| findings.schema.json | 01-explore findings |
| manifest.schema.json | Runtime input tracking |

### Prompt Files
| File | Lines | Purpose |
|------|-------|---------|
| wf.md | 67 | Stage bootstrap |
| main.md | 708 | 01-explore instructions |
| /plan-1b-specify.md | 117 | Source for 02-specify |

---

## Proposed Architecture

### CLI Module Structure
```
enhance/src/wf_composer/
├── __init__.py
├── cli.py                    # argparse entry point
├── composer.py               # compose command logic
│   ├── load_wf_spec()
│   ├── create_run_folder()
│   ├── copy_stage_assets()
│   └── initialize_empty_outputs()
├── preparer.py               # prepare-wf-stage logic
│   ├── copy_inputs_from_stage()
│   ├── validate_stage_ready()
│   └── update_stage_metadata()
├── validator.py              # reuse/wrap validate_stage_outputs.py
└── schemas/
    ├── wf.schema.json        # NEW: wf.yaml validation schema
    ├── stage-config.schema.json
    └── wf-result.schema.json
```

### CLI Interface Design
```bash
# Compose full workflow run from spec
wf-compose compose ./wf-spec --output ./enhance/run

# Prepare single stage (copy inputs from prior)
wf-compose prepare-wf-stage 02-specify \
  --wf-spec ./wf-spec \
  --run-dir ./enhance/run/003 \
  --copy-inputs-from-stage 01-explore

# Validate stage outputs
wf-compose validate ./enhance/run/003/stages/01-explore
```

---

## Next Steps

1. **Run `/plan-1b-specify`** to create formal specification from this research
2. **Consider `/deepresearch`** for CLI framework comparison (optional)
3. **Transform /plan-1b-specify.md** to create 02-specify stage sample

---

**Research Complete**: 2026-01-18T12:45:00Z
**Report Location**: docs/plans/010-first-wf-build/research-dossier.md
